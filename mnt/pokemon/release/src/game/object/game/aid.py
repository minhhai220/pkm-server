#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

助战系统逻辑
'''

from framework import todayinclock5date2int, nowtime_t
from framework.csv import csv, ErrDefs, ConstDefs
from framework.log import logger

from game import ClientError
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from game.object.game.calculator import zeros


class AidHelper:
	"""助战系统辅助类"""

	@staticmethod
	def _markAidDirty(game):
		if not game:
			return
		game._aid_attrs_dirty = True
		game._aid_attrs_cache_dirty = True

	@staticmethod
	def getGlobalAidAttrs(game):
		"""获取助战全局属性缓存，避免每张卡重复计算"""
		if not game or not hasattr(game, 'role'):
			return zeros(), zeros()

		if getattr(game, '_aid_attrs_cache_dirty', True) or not hasattr(game, '_aid_attrs_cache'):
			const = zeros()
			percent = zeros()
			active_aid = game.role.active_aid or {}
			for aidID, aidData in active_aid.iteritems():
				aid_const, aid_percent = AidHelper.getAidAttrs(aidID, aidData)
				for attrID, value in aid_const.iteritems():
					const[attrID] += value
				for attrID, value in aid_percent.iteritems():
					percent[attrID] += value
			game._aid_attrs_cache = (const, percent)
			game._aid_attrs_cache_dirty = False

		return game._aid_attrs_cache
	
	@staticmethod
	def _parsePercent(value):
		"""解析百分比值，如 "10%" -> 0.10"""
		if not value:
			return 0.0
		try:
			if isinstance(value, (int, float)):
				return float(value) / 100.0
			s = str(value).strip()
			if s.endswith('%'):
				return float(s[:-1]) / 100.0
			return float(s) / 100.0
		except:
			return 0.0
	
	@staticmethod
	def getAidAttrs(aidID, aidData):
		"""
		计算助战提供的属性加成
		:param aidID: 助战ID
		:param aidData: 助战数据 {level, stage, awake}
		:return: (常量属性字典, 百分比属性字典)
		"""
		if not aidData:
			return {}, {}
		
		level = max(1, aidData.get('level', 1))
		stage = max(1, aidData.get('stage', 1))
		awake = aidData.get('awake', 0)
		
		if aidID not in csv.aid.aid:
			logger.warning('[AidHelper] 助战配置不存在: aidID=%s', aidID)
			return {}, {}
		
		cfg = csv.aid.aid[aidID]
		
		const_attrs = {}
		percent_attrs = {}
		base_attrs = {}  # 基础属性（等级）
		
		# 1. 等级属性（作为基础值）
		levelSequenceID = cfg.levelSequenceID
		if levelSequenceID and level >= 1:
			if level in csv.aid.level:
				levelCfg = csv.aid.level[level]
				attrMapKey = 'attrMap%d' % levelSequenceID
				if hasattr(levelCfg, attrMapKey):
					levelAttrMap = getattr(levelCfg, attrMapKey) or {}
					for attrID, value in levelAttrMap.iteritems():
						base_attrs[attrID] = base_attrs.get(attrID, 0) + value
		
		# 2. 阶段属性（固定值加成和百分比加成）
		stageSequenceID = cfg.stageSequenceID
		stage_const = {}
		stage_percent = {}
		if stageSequenceID and stage > 0:
			stageCsvId = (stageSequenceID - 1) * 100 + stage
			if stageCsvId in csv.aid.stage:
				stageCfg = csv.aid.stage[stageCsvId]
				# 阶段固定值加成
				attrMap = stageCfg.attrMap or {}
				for attrID, value in attrMap.iteritems():
					stage_const[attrID] = stage_const.get(attrID, 0) + value
				# 阶段百分比加成
				stageAttrFactor = stageCfg.stageAttrFactor or {}
				for attrID, value in stageAttrFactor.iteritems():
					pct = AidHelper._parsePercent(value)
					if pct > 0:
						stage_percent[attrID] = stage_percent.get(attrID, 0) + pct
		
		# 3. 觉醒属性（固定值加成和百分比加成）
		awake_const = {}
		awake_percent = {}
		awakeSequenceID = getattr(cfg, 'awakeSequenceID', 0)
		if awakeSequenceID and awake > 0:
			awakeCsvId = (awakeSequenceID - 1) * 100 + awake
			if awakeCsvId in csv.aid.awake:
				awakeCfg = csv.aid.awake[awakeCsvId]
				# 觉醒固定值加成
				awakeAttrMap = getattr(awakeCfg, 'attrMap', None) or {}
				for attrID, value in awakeAttrMap.iteritems():
					awake_const[attrID] = awake_const.get(attrID, 0) + value
				# 觉醒百分比加成
				awakeAttrFactor = getattr(awakeCfg, 'awakeAttrFactor', None) or {}
				for attrID, value in awakeAttrFactor.iteritems():
					pct = AidHelper._parsePercent(value)
					if pct > 0:
						awake_percent[attrID] = awake_percent.get(attrID, 0) + pct
		
		# 4. 计算最终属性：(等级属性 + 阶段固定 + 觉醒固定) * (1 + 阶段% + 觉醒%)
		all_attr_ids = set(base_attrs.keys()) | set(stage_const.keys()) | set(awake_const.keys())
		for attrID in all_attr_ids:
			base_val = base_attrs.get(attrID, 0)
			stage_val = stage_const.get(attrID, 0)
			awake_val = awake_const.get(attrID, 0)
			stage_pct = stage_percent.get(attrID, 0)
			awake_pct = awake_percent.get(attrID, 0)
			# 最终 = (基础 + 阶段固定 + 觉醒固定) * (1 + 阶段% + 觉醒%)
			final_val = int((base_val + stage_val + awake_val) * (1 + stage_pct + awake_pct))
			if final_val > 0:
				const_attrs[attrID] = final_val
		
		return const_attrs, percent_attrs
	
	@staticmethod
	def getAidFightingPoint(aidID, aidData):
		"""
		计算助战的战斗力
		:param aidID: 助战ID
		:param aidData: 助战数据 {level, stage, awake}
		:return: 战斗力值
		"""
		if not aidData:
			return 0
		
		level = aidData.get('level', 1)
		stage = aidData.get('stage', 1)
		awake = aidData.get('awake', 0)
		
		if aidID not in csv.aid.aid:
			logger.warning('[AidHelper] 助战配置不存在: aidID=%s', aidID)
			return 0
		
		cfg = csv.aid.aid[aidID]
		
		# 从 level.csv 获取等级战力
		levelFightPoint = 0
		levelSequenceID = cfg.levelSequenceID
		if levelSequenceID and level >= 1:
			if level in csv.aid.level:
				levelCfg = csv.aid.level[level]
				fightPointKey = 'aidFightPoint%d' % levelSequenceID
				if hasattr(levelCfg, fightPointKey):
					levelFightPoint = getattr(levelCfg, fightPointKey) or 0
		
		# 从 stage.csv 获取阶段战力
		stageFightPoint = 0
		stageSequenceID = cfg.stageSequenceID
		if stageSequenceID and stage > 0:
			stageCsvId = (stageSequenceID - 1) * 100 + stage
			if stageCsvId in csv.aid.stage:
				stageCfg = csv.aid.stage[stageCsvId]
				stageFightPoint = stageCfg.stageFightPoint or 0
		
		# 从 awake.csv 获取觉醒战力
		awakeFightPoint = 0
		awakeSequenceID = getattr(cfg, 'awakeSequenceID', 0)
		if awakeSequenceID and awake > 0:
			awakeCsvId = (awakeSequenceID - 1) * 100 + awake
			if awakeCsvId in csv.aid.awake:
				awakeCfg = csv.aid.awake[awakeCsvId]
				awakeFightPoint = getattr(awakeCfg, 'awakeFightPoint', 0) or 0
		
		# 总战斗力 = 等级战力 + 阶段战力 + 觉醒战力
		totalFightPoint = int(levelFightPoint + stageFightPoint + awakeFightPoint)
		return totalFightPoint
	
	@staticmethod
	def getAidPassiveSkills(aidID, aidData):
		"""
		获取助战的被动技能（3个独立技能）
		:param aidID: 助战ID
		:param aidData: 助战数据 {level, stage, awake}
		:return: 技能字典 {技能ID: 技能等级}
		
		助战有3个独立的被动技能：
		1. 基础技能 (skillID) - 来自CSV配置
		2. 进阶技能 (79101) - 固定ID，等级 = stage
		3. 觉醒技能 (79102) - 固定ID，等级 = awake
		"""
		if not aidData:
			return {}
		
		awake = aidData.get('awake', 0)
		level = aidData.get('level', 1)
		stage = aidData.get('stage', 1)
		
		# 从 aid_skill.csv 获取助战的技能
		if aidID not in csv.aid.aid_skill:
			logger.warning('[getAidPassiveSkills] 助战技能配置不存在: aidID=%s', aidID)
			return {}
		
		skillCfg = csv.aid.aid_skill[aidID]
		skills = {}
		
		# 1. 基础技能（CSV配置的 skillID）
		if hasattr(skillCfg, 'skillID') and skillCfg.skillID:
			# 技能等级：优先觉醒等级，否则用助战等级
			skillLevel = awake if awake > 0 else max(1, level)
			skills[skillCfg.skillID] = skillLevel
		
		# 2. 进阶技能（固定ID 79101，等级 = stage）
		AidStageSkillID = 79101
		if stage > 0:
			skills[AidStageSkillID] = stage
		
		# 3. 觉醒技能（固定ID 79102，等级 = awake）
		AidAwakeSkillID = 79102
		if awake > 0:
			skills[AidAwakeSkillID] = awake
		
		return skills

	@staticmethod
	def _updateCardsAidFightingPoint(game, aidID):
		"""更新所有对应助战ID的卡牌的助战战力"""
		try:
			# 找到所有对应这个助战的卡牌
			for cardID in game.role.cards:
				card = game.cards.getCard(cardID)
				if not card or card.card_id not in csv.cards:
					continue
				cardCfg = csv.cards[card.card_id]
				if hasattr(cardCfg, 'aidID') and cardCfg.aidID == aidID:
					card.updateAidFightingPoint()
		except Exception as e:
			logger.error('[_updateCardsAidFightingPoint] 更新失败: %s', str(e))
	
	@staticmethod
	def updateAllCardsAttrs(game):
		"""更新所有卡牌属性（助战变化后调用，类似图鉴机制）"""
		try:
			if not getattr(game, '_aid_attrs_dirty', True):
				return

			const, percent = AidHelper.getGlobalAidAttrs(game)
			from game.object.game.card import ObjectCard
			for cardID in game.role.cards:
				card = game.cards.getCard(cardID)
				if card:
					if getattr(card, '_attrs', None) is None or getattr(card, '_attrs2', None) is None:
						card.onUpdateAttrs()
						continue
					try:
						card.calc.const.set('aid', const)
						card.calc.percent.set('aid', percent)
						attrs = card.calc.evaluation()
						card._attrs, card._attrs2 = ObjectCard.splitAttrs(attrs)
						if getattr(card, '_display', False):
							card.db_attrs = card._attrs
						fighting_point = ObjectCard.calcFightingPoint(card, attrs)
						card._setFightingPoint(fighting_point)
					except Exception:
						card.onUpdateAttrs()
			game._aid_attrs_dirty = False
		except Exception as e:
			logger.error('[updateAllCardsAttrs] 更新失败: %s', str(e))
	
	@staticmethod
	def aidActive(game, aidID, operation='active'):
		"""
		激活助战
		:param game: 游戏对象
		:param aidID: 助战ID
		:param operation: 'active' 激活 或 'awake' 觉醒激活
		:return: ObjectGainEffect 包含返还材料
		"""
		role = game.role
		cfg = csv.aid.aid[aidID]

		# 检查是否已经激活
		active_aid = role.active_aid or {}
		if aidID in active_aid:
			# 如果是 awake 操作且当前 awake=0，允许进行首次觉醒
			if operation == 'awake' and active_aid[aidID]['awake'] == 0:
				# 消耗觉醒激活材料
				cost = ObjectCostAux(game, cfg.awakeCost)
				if not cost.isEnough():
					raise ClientError(ErrDefs.costNotEnough)
				cost.cost(src='aid_awake_active')
				
				# 设置觉醒等级为1
				active_aid[aidID]['awake'] = 1
				role.active_aid = active_aid
				
				# 更新卡牌助战战力和全局属性（觉醒激活是一次性操作，立即更新）
				AidHelper._updateCardsAidFightingPoint(game, aidID)
				AidHelper._markAidDirty(game)
				AidHelper.updateAllCardsAttrs(game)
				
				# 返回空效果
				eff = ObjectGainAux(game, {})
				return eff
			else:
				raise ClientError('aid already active')

		# 检查激活条件
		cards = game.role.cards
		hasQualifiedCard = False
		for cardDbId in cards:
			card = game.cards.getCard(cardDbId)
			if not card:
				continue
			cardCfg = csv.cards[card.card_id]
			if cardCfg.aidID == aidID:
				# 检查星级、进阶、等级条件
				if (card.star >= cfg.activeDemandStar and
					card.advance >= cfg.activeDemandAdvance and
					card.level >= cfg.activeDemandLevel):
					hasQualifiedCard = True
					break

		if not hasQualifiedCard:
			raise ClientError('aid active condition not met')

		# 消耗材料
		if operation == 'active':
			# 普通激活消耗
			cost = ObjectCostAux(game, cfg.activeCost)
			if not cost.isEnough():
				raise ClientError(ErrDefs.costNotEnough)
			cost.cost(src='aid_active')
		else:
			# 觉醒激活消耗
			cost = ObjectCostAux(game, cfg.awakeCost)
			if not cost.isEnough():
				raise ClientError(ErrDefs.costNotEnough)
			cost.cost(src='aid_awake_active')

		# 初始化助战数据（嵌套字典修改后必须重新赋值触发同步）
		active_aid = role.active_aid or {}
		active_aid[aidID] = {
			'level': 1,
			'stage': 1,
			'awake': 0
		}
		role.active_aid = active_aid
		
		# 更新对应卡牌的助战战力
		AidHelper._updateCardsAidFightingPoint(game, aidID)
		
		# 更新所有卡牌属性和战力（全局加成）
		AidHelper._markAidDirty(game)
		AidHelper.updateAllCardsAttrs(game)

		# 返回空效果
		eff = ObjectGainAux(game, {})
		return eff

	@staticmethod
	def aidEnhance(game, aidID, targetLevel=None, targetStage=None, targetAwake=None):
		"""
		强化助战（升级、进阶、觉醒）
		:param game: 游戏对象
		:param aidID: 助战ID
		:param targetLevel: 目标等级（None表示不升级）
		:param targetStage: 目标阶段（None表示不进阶）
		:param targetAwake: 目标觉醒（None表示不觉醒）
		"""
		role = game.role
		cfg = csv.aid.aid[aidID]

		# 检查是否已激活
		active_aid = role.active_aid or {}
		if aidID not in active_aid:
			raise ClientError('aid not active')

		aidData = active_aid[aidID]
		currentLevel = aidData['level']
		currentStage = aidData['stage']
		currentAwake = aidData['awake']

		# 获取序列ID
		levelSequenceID = cfg.levelSequenceID
		stageSequenceID = cfg.stageSequenceID
		awakeSequenceID = cfg.awakeSequenceID

		# 先处理进阶，再处理升级（因为升级可能需要阶段要求）
		# 处理进阶（支持连续升阶）
		if targetStage is not None:
			targetStage = int(targetStage)
			
			if targetStage <= currentStage:
				raise ClientError('invalid target stage')
			
			# 连续升阶，读取 [currentStage] 到 [targetStage-1] 的材料
			# stage[N] 的 costMap 存储的是：从 stage N 升到 stage N+1 的材料
			totalCost = {}
			for stage in range(currentStage, targetStage):
				# CSV ID 计算：ID = (sequenceID - 1) * 100 + stage
				stageCsvId = (stageSequenceID - 1) * 100 + stage
				if stageCsvId not in csv.aid.stage:
					raise ClientError('invalid target stage')
				
				stageCfg = csv.aid.stage[stageCsvId]
				
				# 累积材料消耗
				costItems = stageCfg.costMap or {}
				for itemID, count in costItems.iteritems():
					totalCost[itemID] = totalCost.get(itemID, 0) + count
				
				# 累积专属材料消耗
				stageMaterialID = cfg.stageMaterialID
				materialCostNum = stageCfg.materialCostNum
				if stageMaterialID and materialCostNum > 0:
					totalCost[stageMaterialID] = totalCost.get(stageMaterialID, 0) + materialCostNum
			
			# 一次性消耗所有材料
			if totalCost:
				cost = ObjectCostAux(game, totalCost)
				if not cost.isEnough():
					raise ClientError(ErrDefs.costNotEnough)
				cost.cost(src='aid_stage_up')
			
			aidData['stage'] = targetStage
			currentStage = targetStage  # 更新当前阶段，用于后续等级检查

		# 处理升级
		if targetLevel is not None:
			targetLevel = int(targetLevel)
			if targetLevel <= currentLevel:
				raise ClientError('invalid target level')

			# 检查目标等级是否存在
			if targetLevel not in csv.aid.level:
				raise ClientError('invalid target level')
			
			# 检查目标等级需要的阶段要求
			targetLevelCfg = csv.aid.level[targetLevel]
			demandStageKey = 'demandStage%d' % levelSequenceID
			if hasattr(targetLevelCfg, demandStageKey):
				demandStage = getattr(targetLevelCfg, demandStageKey)
				if currentStage < demandStage:
					raise ClientError('stage requirement not met')

			# 消耗材料和金币
			totalCost = {}
			for level in range(currentLevel, targetLevel):
				if level not in csv.aid.level:
					raise ClientError('invalid level config')
				levelCfg = csv.aid.level[level]
				costMapKey = 'costMap%d' % levelSequenceID
				if not hasattr(levelCfg, costMapKey):
					raise ClientError('cost config not found')
				costMap = getattr(levelCfg, costMapKey)
				for itemID, count in costMap.iteritems():
					totalCost[itemID] = totalCost.get(itemID, 0) + count

			if totalCost:
				cost = ObjectCostAux(game, totalCost)
				if not cost.isEnough():
					raise ClientError(ErrDefs.costNotEnough)
				cost.cost(src='aid_level_up')

			aidData['level'] = targetLevel

		# 处理觉醒（支持连续觉醒）
		if targetAwake is not None:
			targetAwake = int(targetAwake)
			if awakeSequenceID == 0:
				raise ClientError('awake not available')
			
			if targetAwake <= currentAwake:
				raise ClientError('invalid target awake')
			
			# 检查基础条件（只需检查一次）
			if currentLevel < cfg.awakeDemandAidLevel:
				raise ClientError('awake level requirement not met')
			if currentStage < cfg.awakeDemandAidStage:
				raise ClientError('awake stage requirement not met')
			
			# 连续觉醒，读取 [currentAwake] 到 [targetAwake-1] 的材料
			# awake[N] 的 costMap 存储的是：从 awake N 升到 awake N+1 的材料
			totalCost = {}
			for awake in range(currentAwake, targetAwake):
				# CSV ID 计算：ID = (sequenceID - 1) * 100 + awake
				awakeCsvId = (awakeSequenceID - 1) * 100 + awake
				if awakeCsvId not in csv.aid.awake:
					raise ClientError('invalid target awake')
				
				awakeCfg = csv.aid.awake[awakeCsvId]
				
				# 累积材料消耗
				costItems = awakeCfg.costMap or {}
				for itemID, count in costItems.iteritems():
					totalCost[itemID] = totalCost.get(itemID, 0) + count
				
				# 累积专属材料消耗
				awakeMaterialID = cfg.awakeMaterialID
				materialCostNum = awakeCfg.materialCostNum
				if awakeMaterialID and materialCostNum > 0:
					totalCost[awakeMaterialID] = totalCost.get(awakeMaterialID, 0) + materialCostNum
			
			# 一次性消耗所有材料
			if totalCost:
				cost = ObjectCostAux(game, totalCost)
				if not cost.isEnough():
					raise ClientError(ErrDefs.costNotEnough)
				cost.cost(src='aid_awake')
			
			aidData['awake'] = targetAwake

		# 触发更新以保存到数据库
		role.active_aid = active_aid
		
		# 更新对应卡牌的助战战力
		AidHelper._updateCardsAidFightingPoint(game, aidID)
		AidHelper._markAidDirty(game)
		
		# 注意：战力更新延迟到 AidQuit 接口，避免连续升级时卡顿
		# AidHelper.updateAllCardsAttrs(game)

	@staticmethod
	def aidReset(game, aidID, auto=False):
		"""
		重置助战，返还部分材料
		:param game: 游戏对象
		:param aidID: 助战ID
		:param auto: 是否自动重置（超进化时使用，不消耗钻石）
		:return: ObjectGainEffect 包含返还材料
		"""
		role = game.role
		cfg = csv.aid.aid[aidID]

		# 检查是否已激活
		active_aid = role.active_aid or {}
		if aidID not in active_aid:
			if auto:
				return None  # 自动重置时，未激活直接返回
			raise ClientError('aid not active')

		# 非自动重置时消耗钻石
		if not auto:
			resetCost = ConstDefs.aidResetCost
			if role.rmb < resetCost:
				raise ClientError(ErrDefs.rmbNotEnough)

			cost = ObjectCostAux(game, {'rmb': resetCost})
			cost.cost(src='aid_reset')

		# 计算返还材料
		aidData = active_aid[aidID]
		currentLevel = aidData['level']
		currentStage = aidData['stage']
		currentAwake = aidData['awake']

		returnItems = {}

		# 返还激活消耗（根据配置比例，默认100%）
		returnProportion = getattr(ConstDefs, 'aidResetReturnProportion', 1.0)
		
		# 返还激活消耗
		for itemID, count in cfg.activeCost.iteritems():
			returnCount = int(count * returnProportion)
			if returnCount > 0:
				returnItems[itemID] = returnItems.get(itemID, 0) + returnCount
		
		# 返还觉醒激活消耗（如果曾经激活过觉醒，即 currentAwake > 0）
		if currentAwake > 0 and hasattr(cfg, 'awakeCost') and cfg.awakeCost:
			for itemID, count in cfg.awakeCost.iteritems():
				returnCount = int(count * returnProportion)
				if returnCount > 0:
					returnItems[itemID] = returnItems.get(itemID, 0) + returnCount

		# 返还升级消耗（从 level 1 升到 currentLevel 消耗的材料）
		# level=1 是初始等级，level[1] 存储的是：从 level 1 升到 level 2 的材料
		levelSequenceID = cfg.levelSequenceID
		for level in range(1, currentLevel):
			if level not in csv.aid.level:
				continue
			levelCfg = csv.aid.level[level]
			costMapKey = 'costMap%d' % levelSequenceID
			if not hasattr(levelCfg, costMapKey):
				continue
			costMap = getattr(levelCfg, costMapKey)
			for itemID, count in costMap.iteritems():
				returnCount = int(count * returnProportion)
				if returnCount > 0:
					returnItems[itemID] = returnItems.get(itemID, 0) + returnCount

		# 返还进阶消耗（从 stage 0 升到 currentStage 消耗的材料）
		stageSequenceID = cfg.stageSequenceID
		for stage in range(1, currentStage):
			# CSV ID 计算：ID = (sequenceID - 1) * 100 + stage
			# stage[N] 的 costMap 存储的是：从 stage N 升到 stage N+1 的材料
			stageCsvId = (stageSequenceID - 1) * 100 + stage
			if stageCsvId not in csv.aid.stage:
				continue
			stageCfg = csv.aid.stage[stageCsvId]
			costItems = stageCfg.costMap or {}
			for itemID, count in costItems.iteritems():
				returnCount = int(count * returnProportion)
				if returnCount > 0:
					returnItems[itemID] = returnItems.get(itemID, 0) + returnCount
			
			stageMaterialID = cfg.stageMaterialID
			materialCostNum = stageCfg.materialCostNum
			if stageMaterialID and materialCostNum > 0:
				returnCount = int(materialCostNum * returnProportion)
				if returnCount > 0:
					returnItems[stageMaterialID] = returnItems.get(stageMaterialID, 0) + returnCount

		# 返还觉醒升级消耗（从 awake 1 升到 currentAwake 消耗的材料）
		# awake[1] 存储的是：从 awake 1 升到 awake 2 的材料
		# 0→1 的材料已在上面通过 cfg.awakeCost 返还
		awakeSequenceID = cfg.awakeSequenceID
		if awakeSequenceID > 0 and currentAwake > 1:
			for awake in range(1, currentAwake):
				# CSV ID 计算：ID = (sequenceID - 1) * 100 + awake
				# awake[N] 的 costMap 存储的是：从 awake N 升到 awake N+1 的材料
				awakeCsvId = (awakeSequenceID - 1) * 100 + awake
				if awakeCsvId not in csv.aid.awake:
					continue
				awakeCfg = csv.aid.awake[awakeCsvId]
				costItems = awakeCfg.costMap or {}
				for itemID, count in costItems.iteritems():
					returnCount = int(count * returnProportion)
					if returnCount > 0:
						returnItems[itemID] = returnItems.get(itemID, 0) + returnCount
				
				awakeMaterialID = cfg.awakeMaterialID
				materialCostNum = awakeCfg.materialCostNum
				if awakeMaterialID and materialCostNum > 0:
					returnCount = int(materialCostNum * returnProportion)
					if returnCount > 0:
						returnItems[awakeMaterialID] = returnItems.get(awakeMaterialID, 0) + returnCount

		# 重置助战数据
		del active_aid[aidID]
		role.active_aid = active_aid

		# 返还材料
		eff = ObjectGainAux(game, returnItems)
		# 自动重置时不内部调用 gain()，与 zawake.reset 保持一致，由外部调用 effectAutoGain
		if not auto:
			eff.gain(src='aid_reset')
		
		# 更新对应卡牌的助战战力（重置后为0）
		AidHelper._updateCardsAidFightingPoint(game, aidID)
		
		# 更新所有卡牌属性和战力（全局加成）
		AidHelper._markAidDirty(game)
		AidHelper.updateAllCardsAttrs(game)
		
		return eff

	@staticmethod
	def aidMaterialSwitch(game, targetItemID, num):
		"""
		材料兑换
		:param game: 游戏对象
		:param targetItemID: 目标材料ID（前端传入的 materialID）
		:param num: 兑换数量
		:return: ObjectGainEffect 包含兑换的材料
		"""
		# 直接用目标材料ID查找配置
		if targetItemID not in csv.aid.material:
			raise ClientError('material config not found')

		cfg = csv.aid.material[targetItemID]

		# 获取需要消耗的源材料ID
		sourceItemID = cfg.switchNeedItemID
		if not sourceItemID:
			raise ClientError('switchNeedItemID not found')

		# 消耗源材料（1:1 兑换）
		cost = ObjectCostAux(game, {sourceItemID: num})
		if not cost.isEnough():
			raise ClientError(ErrDefs.costNotEnough)
		cost.cost(src='aid_material_switch')

		# 获得目标材料
		gainItems = {targetItemID: num}
		eff = ObjectGainAux(game, gainItems)

		return eff

	@staticmethod
	def removeAidCardsByMarkID(game, markID):
		"""
		从助战位移除指定 markID 系列的精灵（超进化时调用）
		:param game: 游戏对象
		:param markID: 精灵系列ID（cardMarkID）
		:return: 被移除的卡牌 dbID 列表
		"""
		role = game.role
		removed = []
		
		# 辅助函数：从助战字典中移除指定 markID 的卡牌
		def filterAidCards(aid_cards):
			if not aid_cards or not isinstance(aid_cards, dict):
				return aid_cards, False
			new_aid = {}
			changed = False
			for slot, cardID in aid_cards.iteritems():
				if cardID is None:
					continue
				card = game.cards.getCard(cardID)
				if card and card.markID == markID:
					removed.append(cardID)
					changed = True
				else:
					new_aid[slot] = cardID
			return new_aid, changed
		
		# 1. 检查普通关卡助战 battle_aid_cards
		battle_aid_cards = role.battle_aid_cards or {}
		new_battle_aid, changed = filterAidCards(battle_aid_cards)
		if changed:
			role.battle_aid_cards = new_battle_aid
		
		# 2. 检查预设队伍 ready_cards
		ready_cards = role.ready_cards or {}
		ready_changed = False
		for idx, team in ready_cards.iteritems():
			if not team:
				continue
			aid_cards = team.get('aid_cards', {})
			new_aid_cards, changed = filterAidCards(aid_cards)
			if changed:
				team['aid_cards'] = new_aid_cards
				ready_changed = True
		if ready_changed:
			role.ready_cards = ready_cards
		
		# 3. 检查活动副本助战 huodong_aid_cards
		huodong_aid_cards = role.huodong_aid_cards or {}
		huodong_changed = False
		for huodongID, aid_cards in huodong_aid_cards.iteritems():
			new_aid_cards, changed = filterAidCards(aid_cards)
			if changed:
				huodong_aid_cards[huodongID] = new_aid_cards
				huodong_changed = True
		if huodong_changed:
			role.huodong_aid_cards = huodong_aid_cards
		
		# 4. 检查 card_embattle 中各模式的助战
		# 包括: arena, cross_arena, cross_mine, gym, craft, cross_online_fight, hunting_route_* 等
		card_embattle = role.card_embattle or {}
		embattle_changed = False
		aid_fields = ['aid_cards', 'defence_aid_cards', 'cross_aid_cards', 'elite_aid_cards']
		for mode, mode_data in card_embattle.iteritems():
			if not isinstance(mode_data, dict):
				continue
			for field in aid_fields:
				if field not in mode_data:
					continue
				aid_cards = mode_data[field]
				new_aid_cards, changed = filterAidCards(aid_cards)
				if changed:
					mode_data[field] = new_aid_cards
					embattle_changed = True
		if embattle_changed:
			role.card_embattle = card_embattle
		
		return removed
