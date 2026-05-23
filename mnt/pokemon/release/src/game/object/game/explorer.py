#!/usr/bin/python
# coding=utf-8
import copy
from collections import defaultdict

from framework import str2num_t
from framework.csv import csv
from framework.log import logger
from framework.object import ObjectDBase, ObjectBase
from game import ClientError
from game.object import TargetDefs
from game.object.game.calculator import zeros
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.thinkingdata import ta


#
# ObjectExplorer
#
class ObjectExplorer(ObjectBase):

	ComponentExplorerMap = {}  # {componentCsvID: (explorerCsvID, maxLevel)}
	ComponentAddition = {} # {(component.id, level): (const, percent)}
	EffectAddition = {} # {(effect.id, advance): (const, percent)}
	EffectExplorerMap = {}  # {effectCsvID: (explorerCsvID, maxLevel)}
	CoreLevelSumExp = {}  # {level: sumExp} 核心等级累计经验表
	CoreLevelMax = 0  # 核心最大等级

	@classmethod
	def classInit(cls):
		# 组件位 => 探险器
		cls.ComponentExplorerMap = {}
		cls.EffectExplorerMap = {}
		for i in csv.explorer.explorer:
			cfg = csv.explorer.explorer[i]
			for cID in cfg.componentIDs:
				cls.ComponentExplorerMap[cID] = (i, cfg.levelMax)
			for eID in cfg.effect:
				cls.EffectExplorerMap[eID] = (i, cfg.levelMax)
			for eID in cfg.extraEff:
				cls.EffectExplorerMap[eID] = (i, cfg.levelMax)
		
		# 构建核心等级累计经验表
		# 内部等级从1开始，前端显示时会-1（显示Lv0）
		# CoreLevelSumExp[level] = 升到level级（内部）需要的累计经验
		# CSV[1].coreExp=从level1升到level2的经验
		cls.CoreLevelSumExp = {}
		cls.CoreLevelSumExp[1] = 0  # 初始等级1（显示Lv0），不需要经验
		sumExp = 0
		maxCsvLevel = 0  # CSV 中实际存在的最大等级
		if csv.explorer.explorer_core:
			for csvLevel in sorted(csv.explorer.explorer_core.keys()):
				cfg = csv.explorer.explorer_core[csvLevel]
				coreExp = cfg.coreExp or 0
				if coreExp <= 0:
					break  # 如果经验为空或0，停止构建（满级）
				sumExp += coreExp
				cls.CoreLevelSumExp[csvLevel + 1] = sumExp  # CSV[i]的经验是升到level(i+1)的累计经验
				maxCsvLevel = csvLevel
			# 最大等级 = 最后一个有效 CSV ID + 1（因为达到该经验后升到下一级）
			cls.CoreLevelMax = maxCsvLevel + 1

		cls.ComponentAddition = {}
		for componentCsvID in csv.explorer.component:
			if componentCsvID not in cls.ComponentExplorerMap:
				continue
			cfg = csv.explorer.component[componentCsvID]
			_, maxLevel = cls.ComponentExplorerMap.get(componentCsvID, (0, 0))
			for l in range(maxLevel):
				level = l+1
				key = (componentCsvID, level)
				c, p = zeros(), zeros()
				for i in xrange(1, 99):
					attrKey = "attrNumType%d" % i
					attrNumKey = "attrNum%d" % i
					if attrKey not in cfg or not cfg[attrKey]:
						break
					attr = cfg[attrKey]
					num = str2num_t(cfg[attrNumKey][level - 1])
					c[attr] += num[0]
					p[attr] += num[1]
				cls.ComponentAddition[key] = (c, p)

		cls.EffectAddition = {}
		for effectCsvID in csv.explorer.explorer_effect:
			if effectCsvID not in cls.EffectExplorerMap:
				continue
			cfg = csv.explorer.explorer_effect[effectCsvID]
			_, maxLevel = cls.EffectExplorerMap.get(effectCsvID, (0, 0))
			if cfg.effectType == 1:  # 1-属性；2-技能
				for l in range(maxLevel):
					advance = l + 1
					key = (effectCsvID, advance)
					c, p = zeros(), zeros()
					for i in xrange(1, 99):
						attrKey = "attrType%d" % i
						attrNumKey = "attrNum%d" % i
						if attrKey not in cfg or not cfg[attrKey]:
							break
						attr = cfg[attrKey]
						num = str2num_t(cfg[attrNumKey][advance - 1])
						c[attr] += num[0]
						p[attr] += num[1]
					cls.EffectAddition[key] = (c, p)

	def set(self):
		self._explorers = self.game.role.explorers
		self._attrs_dirty = True
		return ObjectBase.set(self)

	def init(self):
		self._passive_skills = None # 效果被动技能
		self._passive_skills_global = None # 全局效果被动技能
		self._effects = None # 探险器效果
		self._explorerAttrAddition = {} # {natureType: (const, percent)}
		self._componentAttrAddition = {} # {natureType: (const, percent)}
		self._attrs_dirty = True
		# 自动解锁满足条件的家园技能（修复老数据）
		self._autoUnlockTownSkills()
		return ObjectBase.init(self)
	
	def _autoUnlockTownSkills(self):
		"""
		自动解锁满足条件的家园技能
		当探险器等级 >= skill.needAdvance 时，自动设置 town_skill_level = 1
		"""
		if not self._explorers:
			return
		
		changed = False
		for explorerID, explorerData in self._explorers.iteritems():
			advance = explorerData.get('advance', 0)
			if advance <= 0:
				continue
			
			# 获取探险器配置
			if explorerID not in csv.explorer.explorer:
				continue
			explorerCfg = csv.explorer.explorer[explorerID]
			townSkillID = explorerCfg.townSkill
			if not townSkillID:
				continue
			
			# 检查当前技能等级
			currentSkillLevel = explorerData.get('town_skill_level', 0)
			if currentSkillLevel > 0:
				continue  # 已解锁，跳过
			
			# 查找1级技能配置，检查解锁条件
			for skillCfgId in csv.town.skill:
				skillCfg = csv.town.skill[skillCfgId]
				skill = skillCfg.skill
				level = skillCfg.level
				if skill == townSkillID and level == 1:
					needAdvance = skillCfg.needAdvance or 0
					if advance >= needAdvance:
						# 满足条件，解锁技能
						explorerData['town_skill_level'] = 1
						changed = True
						logger.info('AutoUnlockTownSkill: explorerID=%s advance=%s needAdvance=%s',
									explorerID, advance, needAdvance)
					break
		
		if changed:
			self.game.role.explorers = self._explorers
	
	def _checkUnlockTownSkill(self, explorerID, explorerData):
		"""
		检查并解锁家园技能（探险器升级时调用）
		"""
		advance = explorerData.get('advance', 0)
		currentSkillLevel = explorerData.get('town_skill_level', 0)
		
		if currentSkillLevel > 0:
			return  # 已解锁，跳过
		
		# 获取探险器配置
		if explorerID not in csv.explorer.explorer:
			return
		explorerCfg = csv.explorer.explorer[explorerID]
		townSkillID = explorerCfg.townSkill
		if not townSkillID:
			return
		
		# 查找1级技能配置，检查解锁条件
		for skillCfgId in csv.town.skill:
			skillCfg = csv.town.skill[skillCfgId]
			skill = skillCfg.skill
			level = skillCfg.level
			if skill == townSkillID and level == 1:
				needAdvance = skillCfg.needAdvance or 0
				if advance >= needAdvance:
					# 满足条件，解锁技能
					explorerData['town_skill_level'] = 1
					logger.info('UnlockTownSkill: explorerID=%s advance=%s needAdvance=%s',
								explorerID, advance, needAdvance)
				break

	def _fixCorrupted(self):
		# KDYG-4476 探险器-独角爬行器的进阶消耗修正 补偿邮件
		from datetime import datetime
		date = datetime(2020, 5, 1, 4, 30)
		# date = datetime(2020, 4, 29, 15, 13)
		from framework import datetimefromtimestamp
		if datetimefromtimestamp(self.game.role.last_time) < date:
			advance = self._explorers.get(5, {}).get('advance', 0)
			if advance > 0 and advance <= 15:
				countMap = {
					1: 300,
					2: 300,
					3: 300,
					4: 385,
					5: 605,
					6: 880,
					7: 1265,
					8: 1760,
					9: 2400,
					10: 3205,
					11: 4230,
					12: 5495,
					13: 7035,
					14: 8885,
					15: 11065,
				}
				attachs = {4000: countMap.get(advance, 0)}
				from game.mailqueue import MailJoinableQueue
				from game.object.game.role import ObjectRole
				mail = self.game.role.makeMyMailModel(120, attachs=attachs)
				MailJoinableQueue.send(mail)
		return

	def componentStrength(self, componentCsvID):
		'''
		组件激活或升级
		'''
		explorerCsvID, maxLevel = self.ComponentExplorerMap.get(componentCsvID, ())
		if not explorerCsvID:
			raise ClientError('csv error')
		cfg = csv.explorer.component[componentCsvID]

		explorer = self._explorers.setdefault(explorerCsvID, {'advance': 0, 'components': {}})
		components = explorer['components']

		# 判断组件位 等级是否已最高
		if components.get(componentCsvID, 0) >= maxLevel:
			raise ClientError('component is MaxLevel')
		# 激活判断是否有组件道具
		if components.get(componentCsvID, 0) == 0 and self.game.role.items.get(cfg.itemID, 0) < 1:
			raise ClientError('not have component')
		# 消耗
		strengthCostSeq = cfg.strengthCostSeq
		costItems = csv.explorer.component_level[components.get(componentCsvID, 0) + 1]['costItemMap%d' % strengthCostSeq]
		cost = ObjectCostAux(self.game, costItems)
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='explorer_component_strength')

		oldlevel = components.get(componentCsvID, 0)
		components[componentCsvID] = components.get(componentCsvID, 0) + 1
		if oldlevel > 0: # 升级
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.ExplorerComponentStrength, 1)
		self._componentAttrAddition = {}
		self._attrs_dirty = True

		ta.track(self.game, event='explorer_component_strength',explorer_id=explorerCsvID,explorer_component_id=componentCsvID,current_component_level=components[componentCsvID],explorer_advance=explorer['advance'])

	@classmethod
	def calcCompoentAttrs(cls, components):
		const, percent = zeros(), zeros()
		for componentCsvID, level in components.iteritems():
			key = (componentCsvID, level)
			v = cls.ComponentAddition.get(key, None)
			if v is not None:
				const += v[0]
				percent += v[1]
		return const, percent

	def getComponentStrengthAttrs(self, card):
		'''
		组件升级加成属性（包含天赋树的全组件加成）
		'''
		natureType = card.natureType
		v = self._componentAttrAddition.get(natureType, None)
		if v is not None:
			return v

		const, percent = zeros(), zeros()
		for _, explorer in self._explorers.iteritems():
			components = explorer["components"]
			for componentCsvID, level in components.iteritems():
				cfg = csv.explorer.component[componentCsvID]
				if not cfg.attrTarget or natureType in cfg.attrTarget:
					key = (componentCsvID, level)
					value = self.ComponentAddition.get(key, None)
					if value is not None:
						const += value[0]
						percent += value[1]
		
		# 添加天赋树的全组件属性百分比加成（addType=3）
		tree = self.game.role.explorer_tech_tree or {}
		for techID, techLevel in tree.iteritems():
			if techID not in csv.explorer.tech_tree:
				continue
			techCfg = csv.explorer.tech_tree[techID]
			if techCfg.addType == 3:  # 全组件属性提升
				# addAttrNum 是百分比字符串，如 "0.10%"
				if techCfg.addAttrNum:
					addNum = str2num_t(techCfg.addAttrNum)
					# 每级累加
					percent += addNum[1] * techLevel
		
		self._componentAttrAddition[natureType] = (const, percent)
		return const, percent

	def componentDecompose(self, componentItems):
		'''
		组件分解
		'''
		effAll = ObjectGainAux(self.game, {})
		for itemID, count in componentItems.iteritems():
			eff = ObjectGainAux(self.game, csv.items[itemID].specialArgsMap)
			eff *= count
			effAll += eff

		cost = ObjectCostAux(self.game, componentItems)
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='explorer_component_decompose')

		return effAll

	def explorerAdvance(self, explorerCsvID):
		'''
		探险器激活或升级
		'''
		explorer = self._explorers.get(explorerCsvID, {})
		if not explorer:
			raise ClientError('not exist this explorer')
		cfg = csv.explorer.explorer[explorerCsvID]
		# 判断是否满级
		if explorer['advance'] >= cfg.levelMax:
			raise ClientError('explorer is MaxLevel')
		# 判断是否满足条件
		components = explorer['components']
		for componentCsvID in cfg.componentIDs:
			if components.get(componentCsvID, 0) < explorer['advance'] + 1:
				raise ClientError('not reach conditions')
		# 消耗
		advanceCostSeq = cfg.advanceCostSeq
		costItems = csv.explorer.explorer_advance[explorer['advance'] + 1]['costItemMap%d' % advanceCostSeq]
		cost = ObjectCostAux(self.game, costItems)
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='explorer_advance')
		# 激活或升级
		old = explorer.get('advance', 0)
		explorer['advance'] = explorer.get('advance', 0) + 1
		self._passive_skills = None
		self._passive_skills_global = None
		self._effects = None
		self._explorerAttrAddition = {}
		self._attrs_dirty = True
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.ExplorerAdvance, 1)
		if old == 0: # 激活
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.Explorer, 0)
		
		# 检查是否可以解锁家园技能
		self._checkUnlockTownSkill(explorerCsvID, explorer)

		ta.track(self.game, event='explorer_advance',explorer_id=explorerCsvID,explorer_advance=explorer['advance'])

	@classmethod
	def calcEffects(cls, explorers):
		effects = []
		for csvID, explorer in explorers.iteritems():
			advance = explorer['advance']
			# 获取所有已被激活探险器
			if advance > 0:
				cfg = csv.explorer.explorer[csvID]
				# 主效果
				for effect in cfg.effect:
					effects.append((effect, advance))
				# 额外效果（技能或属性）
				for i, val in enumerate(cfg.extraEffCod):
					if val <= advance:
						effects.append((cfg.extraEff[i], advance))
		return effects

	@classmethod
	def calcEffectAttrs(cls, effects, natureType):
		const = zeros()
		percent = zeros()
		for effectid, advance in effects:
			cfg = csv.explorer.explorer_effect[effectid]
			# 需满足 目标和是属性1
			if (not cfg.target or natureType in cfg.target) and cfg.effectType == 1: # 1-属性；2-技能
				key = (effectid, advance)
				v = cls.EffectAddition.get(key, None)
				if v is not None:
					const += v[0]
					percent += v[1]
		return const, percent

	def getEffectAttrByCard(self, card):
		'''
		通过 card 获得 效果属性加成（包含天赋树加成和核心等级加成）
		'''
		natureType = card.natureType
		v = self._explorerAttrAddition.get(natureType, None)
		if v is not None:
			return v

		if self._effects is None:
			self._effects = self.calcEffects(self._explorers)

		const, percent = self.calcEffectAttrs(self._effects, natureType)
		
		# 添加核心等级属性加成（全局加成）
		core = self.game.role.explorer_core or {'level': 1, 'exp_sum': 0}
		coreLevel = core.get('level', 1)
		if coreLevel > 1 and csv.explorer.explorer_core:
			# 累加从1级到当前等级的所有属性
			for lvl in xrange(1, coreLevel + 1):
				if lvl not in csv.explorer.explorer_core:
					continue
				coreCfg = csv.explorer.explorer_core[lvl]
				for i in xrange(1, 7):  # attrNumType1-6
					attrTypeKey = 'attrNumType%d' % i
					attrNumKey = 'attrNum%d' % i
					attrType = getattr(coreCfg, attrTypeKey, 0) or 0
					attrNum = getattr(coreCfg, attrNumKey, '') or ''
					if attrType and attrNum:
						addNum = str2num_t(attrNum)
						const[attrType] += addNum[0]
						percent[attrType] += addNum[1]
		
		# 添加天赋树的精灵属性加成（addType=1或2）
		tree = self.game.role.explorer_tech_tree or {}
		for techID, techLevel in tree.iteritems():
			if techID not in csv.explorer.tech_tree:
				continue
			techCfg = csv.explorer.tech_tree[techID]
			# addType: 1-直接属性加成, 2-其他, 3-全组件加成(已在getComponentStrengthAttrs处理)
			if techCfg.addType in (1, 2):
				# attrNum1, attrType1
				if techCfg.attrNum1 and techCfg.attrType1:
					addNum = str2num_t(techCfg.attrNum1)
					const[techCfg.attrType1] += addNum[0] * techLevel
					percent[techCfg.attrType1] += addNum[1] * techLevel
				# attrNum2, attrType2
				if techCfg.attrNum2 and techCfg.attrType2:
					addNum = str2num_t(techCfg.attrNum2)
					const[techCfg.attrType2] += addNum[0] * techLevel
					percent[techCfg.attrType2] += addNum[1] * techLevel
		
		attrs = (const, percent)
		self._explorerAttrAddition[natureType] = attrs
		return attrs

	@classmethod
	def calcPassiveSkills(cls, effects):
		skills = {}
		for effectid, advance in effects:
			cfg = csv.explorer.explorer_effect[effectid]
			if cfg.effectType == 2: # 技能
				skills[cfg.skillID] = advance  # explorer advance is effect passive skill level
		return skills

	def getPassiveSkills(self, isGlobal=False):
		# 探险器技能是全局技能，isGlobal参数已废弃，统一处理
		if self._passive_skills is not None:
			return self._passive_skills

		if self._effects is None:
			self._effects = self.calcEffects(self._explorers)
		
		skills = self.calcPassiveSkills(self._effects)
		
		# 添加天赋树技能（addType=2）
		skills = self._applyTechTreeSkillBonus(skills)
		
		self._passive_skills = skills
		return skills

	def updateAllCardsAttrs(self):
		"""仅更新探险器相关加成并刷新战力"""
		try:
			if not getattr(self, '_attrs_dirty', True):
				return

			from game.object.game.card import ObjectCard
			for cardID in self.game.role.cards:
				card = self.game.cards.getCard(cardID)
				if not card:
					continue
				if getattr(card, '_attrs', None) is None or getattr(card, '_attrs2', None) is None:
					card.onUpdateAttrs()
					continue
				try:
					const, percent = self.getComponentStrengthAttrs(card)
					card.calc.const.set('explorer_component', const)
					card.calc.percent.set('explorer_component', percent)

					const, percent = self.getEffectAttrByCard(card)
					card.calc.const.set('explorer_effect', const)
					card.calc.percent.set('explorer_effect', percent)

					attrs = card.calc.evaluation()
					card._attrs, card._attrs2 = ObjectCard.splitAttrs(attrs)
					if getattr(card, '_display', False):
						card.db_attrs = card._attrs
					fighting_point = ObjectCard.calcFightingPoint(card, attrs)
					card._setFightingPoint(fighting_point)
				except Exception:
					card.onUpdateAttrs()
			self._attrs_dirty = False
		except Exception as e:
			logger.error('[Explorer updateAllCardsAttrs] 更新失败: %s', str(e))

	def updateComponentCardsAttrs(self, componentCsvID):
		"""仅更新组件影响的卡牌属性与战力（组件升级时使用）"""
		try:
			cfg = csv.explorer.component[componentCsvID] if componentCsvID in csv.explorer.component else None
			if not cfg:
				self.updateAllCardsAttrs()
				return

			target = getattr(cfg, 'attrTarget', None)
			if not target:
				self.updateAllCardsAttrs()
				return

			if isinstance(target, (list, tuple, set)):
				nature_types = set(target)
			else:
				nature_types = set([target])

			from game.object.game.card import ObjectCard
			for cardID in self.game.role.cards:
				card = self.game.cards.getCard(cardID)
				if not card:
					continue
				if card.natureType not in nature_types:
					continue
				if getattr(card, '_attrs', None) is None or getattr(card, '_attrs2', None) is None:
					card.onUpdateAttrs()
					continue
				try:
					const, percent = self.getComponentStrengthAttrs(card)
					card.calc.const.set('explorer_component', const)
					card.calc.percent.set('explorer_component', percent)
					attrs = card.calc.evaluation()
					card._attrs, card._attrs2 = ObjectCard.splitAttrs(attrs)
					if getattr(card, '_display', False):
						card.db_attrs = card._attrs
					fighting_point = ObjectCard.calcFightingPoint(card, attrs)
					card._setFightingPoint(fighting_point)
				except Exception:
					card.onUpdateAttrs()
		except Exception as e:
			logger.error('[Explorer updateComponentCardsAttrs] 更新失败: %s', str(e))

	def _applyTechTreeSkillBonus(self, skills):
		'''
		应用天赋树对探险器战斗技能的加成（addType=2）
		添加天赋树技能（techSkillID）到战斗中
		:param skills: 原始技能字典 {skillID: level}
		:return: 加成后的技能字典
		'''
		tree = self.game.role.explorer_tech_tree or {}
		if not tree:
			return skills
		
		# 构建探险器效果ID到探险器ID的映射
		effect_to_explorer = {}
		for effectid in csv.explorer.explorer_effect:
			explorerID, _ = self.EffectExplorerMap.get(effectid, (0, 0))
			if explorerID > 0:
				effect_to_explorer[effectid] = explorerID
		
		# 应用天赋树加成
		result_skills = dict(skills)
		applied_skills = set()  # 记录已添加的技能，避免重复
		
		for techID, techLevel in tree.iteritems():
			if techLevel <= 0:
				continue
			if techID not in csv.explorer.tech_tree:
				continue
			
			techCfg = csv.explorer.tech_tree[techID]
			
			# addType=2 表示探险器战斗技能效果提升
			if techCfg.addType == 2:
				explorerID = getattr(techCfg, 'explorerID', 0)
				if explorerID <= 0:
					continue
				
				# 检查探险器是否已激活
				explorer = self._explorers.get(explorerID, {})
				if explorer.get('advance', 0) <= 0:
					continue
				
				# 找到该探险器的所有效果，添加 techSkillID 到战斗技能（与原始技能并存）
				for effectid, eid in effect_to_explorer.iteritems():
					if eid == explorerID:
						effectCfg = csv.explorer.explorer_effect[effectid]
						if effectCfg.effectType == 2:  # 2-技能类型
							techSkillID = getattr(effectCfg, 'techSkillID', 0)
							if techSkillID and techSkillID > 0 and techSkillID not in applied_skills:
								# 天赋树技能等级 = 天赋树等级
								# 天赋树技能与原始技能同时生效（不替换）
								result_skills[techSkillID] = techLevel
								applied_skills.add(techSkillID)
		
		return result_skills

	def countActiveExplorers(self):
		count = 0
		for _, explorer in self._explorers.iteritems():
			if explorer['advance'] > 0:
				count += 1
		return count

	def coreStrength(self, componentCsvIDs):
		'''
		探险器核心强化：使用组件或通用道具提升核心等级
		:param componentCsvIDs: {csvID: count, ...} 组件ID或道具ID（4000为通用材料）
		'''
		# 兼容前端发送数组的情况
		if isinstance(componentCsvIDs, list):
			componentCsvIDs = {i + 1: val for i, val in enumerate(componentCsvIDs)}
		
		if not isinstance(componentCsvIDs, dict) or not componentCsvIDs:
			raise ClientError('param error')
		
		# 验证所有材料并计算经验
		totalExp = 0
		costItems = {}
		for csvID, count in componentCsvIDs.items():
			if not isinstance(count, int) or count <= 0:
				raise ClientError('param error')
			
			# 判断是通用道具还是组件
			if csvID == 4000:
				# 通用核心材料道具
				if 4000 not in csv.items:
					raise ClientError('item config error')
				itemCfg = csv.items[4000]
				if 'component_exp' not in itemCfg.specialArgsMap:
					raise ClientError('item config error')
				itemExp = itemCfg.specialArgsMap['component_exp']
				# 前端发送的 count 是 selectNum / 10，实际消耗数量需要 * 10
				# component_exp=0.2 表示每 10 个道具给 0.2*10=2 经验
				componentCostBase = csv.common_config[184].value  # componentCostBase = 10
				actualCount = count * componentCostBase
				# 检查道具数量
				if self.game.role.items.get(4000, 0) < actualCount:
					raise ClientError('not have item')
				costItems[4000] = costItems.get(4000, 0) + actualCount
				# 经验 = 0.2 * 10 * count = 2 * count（整数）
				totalExp += int(itemExp * actualCount)
			else:
				# 普通组件
				if csvID not in csv.explorer.component:
					raise ClientError('component not found')
				componentCfg = csv.explorer.component[csvID]
				itemID = componentCfg.itemID
				# 检查道具数量
				if self.game.role.items.get(itemID, 0) < count:
					raise ClientError('not have component')
				costItems[itemID] = costItems.get(itemID, 0) + count
				totalExp += componentCfg.componentExp * count
		
		# 扣除组件道具
		cost = ObjectCostAux(self.game, costItems)
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='explorer_core_strength')
		
		# 增加核心经验并计算等级
		core = self.game.role.explorer_core or {'level': 1, 'exp_sum': 0}
		oldLevel = core.get('level', 1)
		core['exp_sum'] = core.get('exp_sum', 0) + totalExp
		
		# 根据累计经验计算等级
		# CoreLevelSumExp[level] = 升到level级（内部）需要的累计经验
		# 0经验=level1(显示Lv0), 1440经验=level2(显示Lv1), 2990经验=level3(显示Lv2)
		newLevel = 1
		while newLevel < self.CoreLevelMax and core['exp_sum'] >= self.CoreLevelSumExp.get(newLevel + 1, float('inf')):
			newLevel += 1
		
		core['level'] = newLevel
		self.game.role.explorer_core = core
		
		# 清空缓存，触发重新计算
		if newLevel > oldLevel:
			self._componentAttrAddition = {}
			self._explorerAttrAddition = {}
			self._attrs_dirty = True
			# 更新天赋树解锁状态
			self.game.role._initExplorerTechTreeUnlock()
		
		ta.track(self.game, event='explorer_core_strength', 
				old_level=oldLevel, new_level=newLevel, 
				add_exp=totalExp, total_exp=core['exp_sum'])
		
		return {'old_level': oldLevel, 'new_level': newLevel}

	def techTreeLevelUp(self, techID):
		'''
		天赋树升级
		:param techID: 天赋ID
		'''
		if techID not in csv.explorer.tech_tree:
			raise ClientError('csv error')
		
		cfg = csv.explorer.tech_tree[techID]
		tree = self.game.role.explorer_tech_tree or {}
		core = self.game.role.explorer_core or {'level': 1, 'exp_sum': 0}
		
		currentLevel = tree.get(techID, 0)
		
		# 检查等级上限
		if currentLevel >= cfg.levelLimit:
			raise ClientError('tech tree level max')
		
		# 检查核心等级要求（前端用 level >= needCoreLevel）
		if core.get('level', 1) < cfg.needCoreLevel:
			raise ClientError('core level not enough')
		
		# 检查前置天赋要求
		if cfg.preTechID1 > 0 and tree.get(cfg.preTechID1, 0) < cfg.preTechLevel1:
			raise ClientError('pre tech1 not enough')
		if cfg.preTechID2 > 0 and tree.get(cfg.preTechID2, 0) < cfg.preTechLevel2:
			raise ClientError('pre tech2 not enough')
		
		# 计算可用天赋点（从CSV[1]开始，对应内部等级2，显示Lv1）
		# 内部等级1（显示Lv0）没有天赋点
		totalTechPoint = 0
		coreLevel = core.get('level', 1)
		for i in xrange(1, coreLevel):  # 从CSV[1]遍历到CSV[coreLevel-1]
			if i in csv.explorer.explorer_core:
				totalTechPoint += csv.explorer.explorer_core[i].techPoint
		
		usedTechPoint = sum(tree.values())
		if usedTechPoint >= totalTechPoint:
			raise ClientError('tech point not enough')
		
		# 消耗天赋点（每次升级消耗1点天赋点，已在上面检查）
		# 消耗金币：使用 costTech{costID} 字段
		costLevel = currentLevel
		if costLevel not in csv.explorer.tech_cost:
			raise ClientError('csv error')
		costCfg = csv.explorer.tech_cost[costLevel]
		
		costKey = 'costTech%d' % (cfg.costID or 1)
		costGold = getattr(costCfg, costKey, 0) or 0
		
		if costGold > 0:
			cost = ObjectCostAux(self.game, {'gold': costGold})
			if not cost.isEnough():
				raise ClientError('cost not enough')
			cost.cost(src='explorer_tech_tree_levelup')
		
		# 升级
		tree[techID] = currentLevel + 1
		self.game.role.explorer_tech_tree = tree
		
		# 清空缓存，触发重新计算
		self._componentAttrAddition = {}
		self._explorerAttrAddition = {}
		self._passive_skills = None  # 清空被动技能缓存，因为天赋树可能影响技能等级
		self._attrs_dirty = True
		
		# 检查是否有新天赋可解锁（前置条件满足）
		self.game.role._initExplorerTechTreeUnlock()
		
		ta.track(self.game, event='explorer_tech_tree_levelup',
				tech_id=techID, old_level=currentLevel, new_level=currentLevel + 1)
		
		return {'new_level': currentLevel + 1}

	def techTreeReset(self):
		'''
		天赋树重置
		'''
		tree = self.game.role.explorer_tech_tree or {}
		# 检查是否有升级过的天赋（level > 0）
		upgradedCount = sum(1 for level in tree.values() if level > 0)
		if upgradedCount == 0:
			raise ClientError('tech tree is empty')
		
		# 计算重置消耗（钻石）
		resetCostRmb = csv.common_config['treeResettingCost'] if 'treeResettingCost' in csv.common_config else 0
		if resetCostRmb and resetCostRmb > 0:
			cost = ObjectCostAux(self.game, {'rmb': resetCostRmb})
			if not cost.isEnough():
				raise ClientError('cost not enough')
			cost.cost(src='explorer_tech_tree_reset')
		
		# 重置天赋树
		self.game.role.explorer_tech_tree = {}
		
		# 重新初始化解锁状态（满足条件的天赋设为 level=0）
		self.game.role._initExplorerTechTreeUnlock()
		
		# 清空缓存，触发重新计算
		self._componentAttrAddition = {}
		self._explorerAttrAddition = {}
		self._passive_skills = None  # 清空被动技能缓存
		self._attrs_dirty = True
		
		ta.track(self.game, event='explorer_tech_tree_reset', reset_count=len(tree))
		
		return {'reset_count': len(tree)}
