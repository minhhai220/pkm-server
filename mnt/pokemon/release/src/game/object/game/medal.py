#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

勋章墙系统
'''

from framework import nowtime_t
from framework.csv import csv
from framework.log import logger
from framework.object import ObjectBase
from game.object.game.calculator import zeros
from game.object import AttrDefs, YYHuoDongDefs

class ObjectMedal(ObjectBase):
	"""勋章墙对象"""
	
	@classmethod
	def classInit(cls):
		"""初始化勋章配置"""
		pass
	
	def set(self):
		"""初始化勋章对象"""
		self._medal = self.game.role.medal  # {medalID: activateTime}
		self._medalTask = self.game.role.medal_task  # {medalID: progress}
		self._medalShow = self.game.role.medal_show  # medalID (int) or None
		self._attrs_cache = None
		self._attrs_cache_dirty = True
		return ObjectBase.set(self)
	
	def init(self):
		"""登录时初始化"""
		# 初始化数据结构
		if self._medal is None:
			self.game.role.medal = {}
			self._medal = self.game.role.medal
		if self._medalTask is None:
			self.game.role.medal_task = {}
			self._medalTask = self.game.role.medal_task
		
		# 清理旧的进度值数据（只保留 0 和 1 状态）
		# medalTask 应该只存储：1=可领取, 0=已领取, 不存在=未达标
		if self._medalTask:
			toRemove = []
			for medalID, value in self._medalTask.iteritems():
				if value not in [0, 1]:
					toRemove.append(medalID)
			
			if toRemove:
				for medalID in toRemove:
					del self._medalTask[medalID]
				self.game.role.medal_task = self._medalTask
				logger.info('[Medal] 清理了 %d 个旧的进度值数据: %s', len(toRemove), toRemove)
		
		if self._medalShow is None:
			self.game.role.medal_show = 0
			self._medalShow = 0
		
		# 初始化勋章计数器
		self._medalCounter = self.game.role.medal_counter
		if self._medalCounter is None:
			self.game.role.medal_counter = {}
			self._medalCounter = self.game.role.medal_counter

		self._attrs_cache_dirty = True
		
		# 注意：不在这里调用 checkAllMedals()，会在登录处理器中延迟调用
		# 避免在数据同步期间修改数据导致前端同步错误
		
		return ObjectBase.init(self)
	
	def isMedalActive(self, medalID):
		"""判断勋章是否已激活"""
		return medalID in (self._medal or {})
	
	def getMedalProgress(self, medalID):
		"""获取勋章任务进度"""
		return (self._medalTask or {}).get(medalID, 0)
	
	def updateMedalProgress(self, medalID, progress):
		"""更新勋章任务进度"""
		if self._medalTask is None:
			self.game.role.medal_task = {}
			self._medalTask = self.game.role.medal_task
		
		# 获取配置
		if medalID not in csv.medal:
			return False
		
		cfg = csv.medal[medalID]
		targetArg = cfg.targetArg
		
		# 更新进度
		oldProgress = self._medalTask.get(medalID, 0)
		newProgress = max(oldProgress, progress)
		
		# 达到目标时标记为可领取（不自动激活）
		if newProgress >= targetArg and not self.isMedalActive(medalID):
			if self._medalTask.get(medalID) != 1:
				self._medalTask[medalID] = 1
				self.game.role.medal_task = self._medalTask
			return True
		
		# 未达标则不记录到 medalTask（前端会自己计算进度）
		# medalTask 只存储状态：1=可领取, 0=已领取, 不存在=未达标
		
		return False
	
	def activateMedal(self, medalID):
		"""激活勋章"""
		if self._medal is None:
			self.game.role.medal = {}
			self._medal = self.game.role.medal
		
		if medalID not in self._medal:
			self._medal[medalID] = nowtime_t()
			self.game.role.medal = self._medal
			self._attrs_cache_dirty = True
			logger.info('[Medal] 玩家%s激活勋章%d', self.game.role.id, medalID)
			return True
		
		return False
	
	def getMedalAttrs(self):
		"""获取所有已激活勋章的属性加成"""
		if self._attrs_cache is not None and not self._attrs_cache_dirty:
			return self._attrs_cache

		const = zeros()
		percent = zeros()
		
		if not self._medal:
			self._attrs_cache = (const, percent)
			self._attrs_cache_dirty = False
			return self._attrs_cache
		
		for medalID in self._medal.keys():
			if medalID not in csv.medal:
				continue
			
			cfg = csv.medal[medalID]
			
			# 读取属性加成
			for i in range(1, 4):  # attrType1-3, attrNum1-3
				attrTypeKey = 'attrType%d' % i
				attrNumKey = 'attrNum%d' % i
				
				if not hasattr(cfg, attrTypeKey) or not hasattr(cfg, attrNumKey):
					continue
				
				attrType = getattr(cfg, attrTypeKey)
				attrNum = getattr(cfg, attrNumKey)
				
				if attrType and attrNum:
					# attrType 就是属性枚举ID，直接使用
					attrID = attrType
					attrValue = attrNum

					# showShadow >= 1 表示固定值，< 1 表示百分比
					if cfg.showShadow >= 1:
						if isinstance(attrValue, str):
							attrValue = attrValue.strip()
							if not attrValue:
								continue
							attrValue = float(attrValue)
						const[attrID] += int(attrValue)
					else:
						# 百分比可能是 "3%"、0.03 或 300/420 等整型配置（按万分比）
						percentValue = None
						if isinstance(attrValue, str):
							attrValue = attrValue.strip()
							if not attrValue:
								continue
							if attrValue.endswith('%'):
								percentValue = float(attrValue[:-1]) / 100.0
							else:
								attrValue = float(attrValue)
						if percentValue is None:
							if attrValue > 1:
								percentValue = attrValue / 10000.0
							else:
								percentValue = attrValue
						percent[attrID] += percentValue
		
		self._attrs_cache = (const, percent)
		self._attrs_cache_dirty = False
		return self._attrs_cache
	
	def canGetAward(self, medalID):
		"""判断勋章奖励是否可领取"""
		# 勋章已激活且还没领取过奖励
		return self.isMedalActive(medalID)
	
	def getAward(self, medalID):
		"""领取勋章奖励
		返回: (success, award)
		"""
		if medalID not in csv.medal:
			return False, {}
		
		if not self.isMedalActive(medalID):
			return False, {}
		
		cfg = csv.medal[medalID]
		award = cfg.award or {}
		
		return True, award
	
	def setMedalShow(self, medalID):
		"""设置展示的勋章（单个）"""
		# 验证勋章已激活
		if medalID != 0 and not self.isMedalActive(medalID):
			return False
		
		self.game.role.medal_show = medalID
		self._medalShow = medalID
		return True
	
	def getMedalCurrent(self, medalID):
		"""获取勋章当前进度
		返回当前完成值（根据targetType计算）
		"""
		if medalID not in csv.medal:
			return 0
		
		cfg = csv.medal[medalID]
		targetType = cfg.targetType
		targetArg = cfg.targetArg
		
		# 如果已经在任务中记录且达标，返回目标值（保底）
		medalTask = self._medalTask or {}
		if medalID in medalTask and medalTask[medalID] >= targetArg:
			return targetArg
		
		# 根据 targetType 计算当前进度
		current = self._calculateMedalProgress(medalID, targetType, targetArg, cfg)
		
		return current
	
	def _calculateMedalProgress(self, medalID, targetType, targetArg, cfg):
		"""根据类型计算勋章进度"""
		role = self.game.role
		
		# 勋章类型映射（对应前端的 MedalMap）
		# 注意：这里只实现了部分常见类型，其他类型需要逐步添加
		
		# Type 1: 活力点宝箱领取天数 (LivePoint) - 手动计数
		if targetType == 1:
			return self._medalCounter.get(medalID, 0)
		
		# Type 2: 签到天数 (SignInDays)
		elif targetType == 2:
			return getattr(role, 'sign_in_count', 0) or 0
		
		# Type 3: 日常助手使用天数 (DailyAssistantCount)
		elif targetType == 3:
			return getattr(role, 'daily_assistant_in_days', 0) or 0
		
		# Type 4: 钻石抽卡次数 (DrawGemRMB)
		elif targetType == 4:
			lottery = self.game.lotteryRecord
			gem1 = lottery.gem_rmb_dc1_counter or 0
			gem10 = lottery.gem_rmb_dc10_counter or 0
			return gem1 + gem10 * 10
		
		# Type 5: 图腾抽卡次数 (DrawTotem)
		elif targetType == 5:
			lottery = self.game.lotteryRecord
			totem1 = lottery.totem_rmb_dc1_counter or 0
			totem6 = lottery.totem_rmb_dc6_counter or 0
			return totem1 + totem6 * 6
		
		# Type 6: 芯片抽卡次数 (DrawChipRMB)
		elif targetType == 6:
			lottery = self.game.lotteryRecord
			chip1 = lottery.chip_rmb_dc1_counter or 0
			chip10 = lottery.chip_rmb_dc10_counter or 0
			return chip1 + chip10 * 10
		
		# Type 7: 限定抽卡次数 (DrawDailyLimitCount)
		elif targetType == 7:
			lottery = self.game.lotteryRecord
			count = 0
			# 统计自选限定抽卡单抽
			for _, v in (lottery.draw_card_up1_counters or {}).iteritems():
				count += v
			# 统计自选限定抽卡10连抽
			for _, v in (lottery.draw_card_up10_counters or {}).iteritems():
				count += v * 10
			# 统计运营活动限定抽卡
			count += (lottery.yyhuodong_counters or {}).get(YYHuoDongDefs.TimeLimitUpDraw, 0)
			return count
		
		# Type 8: 背包容量 (BagCapacity)
		elif targetType == 8:
			return getattr(role, 'card_capacity', 0) or 0
		
		# Type 9: 捕获S级精灵数 (CaptureSSprite) - 手动计数
		elif targetType == 9:
			return self._medalCounter.get(medalID, 0)
		
		# Type 10: 以太乐园困难敌人胜利 (RandomTowerHardBeatCount)
		elif targetType == 10:
			return getattr(role, 'random_tower_hard_beat_count', 0) or 0
		
		# Type 11: 家园拜访次数 (TownSocietyHomeVisitCount) - 手动计数
		elif targetType == 11:
			return self._medalCounter.get(medalID, 0)
		
		# Type 12: 派对互动次数 (PartyQifenCount) - 手动计数
		elif targetType == 12:
			return self._medalCounter.get(medalID, 0)
		
		# Type 13: 公会许愿天数 (UnionWishingCount)
		elif targetType == 13:
			return getattr(role, 'frag_donate_start_count', 0) or 0
		
		# Type 14: 重聚活动绑定次数 (ReunionBind) - 手动计数
		elif targetType == 14:
			return self._medalCounter.get(medalID, 0)
		
		# Type 15: 公会技能等级达标数 (UnionSkillLevel)
		elif targetType == 15:
			targetArgSpecial = cfg.targetArgSpecial or {}
			requiredLevel = targetArgSpecial.get('skillLevel', 1)
			union_skills = role.union_skills or {}
			count = 0
			for _, level in union_skills.iteritems():
				if level >= requiredLevel:
					count += 1
			return count
		
		# Type 26: 跨服矿战祝福消耗 (CrossMineBuffCost)
		elif targetType == 26:
			return getattr(role, 'cross_mine_buff_feed_cost', 0) or 0
		
		# Type 27: 跨服实时对战连胜 (OnlineFightWinStreak)
		elif targetType == 27:
			return getattr(role, 'cross_online_fight_win_streak', 0) or 0
		
		# Type 30: 跨服矿战抢夺失败连续 (CrossMineRodLosingStreak)
		elif targetType == 30:
			return getattr(role, 'cross_mine_rob_fail_streak', 0) or 0
		
		# Type 32: 指定精灵拥有数 (CardMarkIdCount)
		elif targetType == 32:
			if not hasattr(self.game.cards, 'markIDMaxStar'):
				return 0
			targetArgSpecial = cfg.targetArgSpecial or {}
			cardMarkIDs = targetArgSpecial.get('cardMarkIDs', [])
			count = 0
			for cardID in cardMarkIDs:
				if cardID not in csv.cards:
					continue
				cardMarkID = csv.cards[cardID].cardMarkID
				if self.game.cards.markIDMaxStar.get(cardMarkID, 0) > 0:
					count += 1
			return count
		
		# Type 31: 羁绊完成数 (Fetters)
		elif targetType == 31:
			if not hasattr(self.game.cards, 'markIDMaxStar'):
				return 0
			targetArgSpecial = cfg.targetArgSpecial or {}
			cardMarkIDs = targetArgSpecial.get('cardMarkIDs', [])
			count = 0
			for csvCardID in cardMarkIDs:
				if csvCardID not in csv.cards:
					continue
				cardCfg = csv.cards[csvCardID]
				cardMarkID = cardCfg.cardMarkID
				fetterList = cardCfg.fetterList or []
				if not fetterList:
					continue
				# 检查所有羁绊是否完成
				allFetterDone = True
				for fetterID in fetterList:
					if fetterID not in csv.fetter:
						allFetterDone = False
						break
					fetterCfg = csv.fetter[fetterID]
					fetterCards = fetterCfg.cards or []
					# 检查羁绊需要的所有卡牌是否拥有
					for neededCardID in fetterCards:
						neededMarkID = csv.cards[neededCardID].cardMarkID if neededCardID in csv.cards else 0
						if not self.game.cards.markIDMaxStar.get(neededMarkID, 0):
							allFetterDone = False
							break
					if not allFetterDone:
						break
				if allFetterDone:
					count += 1
			return count
		
		# Type 33: 超进化精灵数量 (MegaCardsCount)
		elif targetType == 33:
			count = 0
			for _, card in self.game.cards._objs.iteritems():
				if csv.cards[card.card_id].megaIndex > 0:
					count += 1
			return count
		
		# Type 34: 称号数量 (TitleCount)
		elif targetType == 34:
			titles = role.titles or []
			return len(titles)
		
		# Type 28: 公平模式指定精灵胜利 (OnlineFightLimitedWin) - 手动计数
		elif targetType == 28:
			return self._medalCounter.get(medalID, 0)
		
		# Type 29: 跨服商业街抢到BOSS击杀 (CrossMineKillBossCount) - 手动计数
		elif targetType == 29:
			return self._medalCounter.get(medalID, 0)
		
		# Type 37: 困难副本指定精灵胜利 (AssignCardBattleWin) - 手动计数
		elif targetType == 37:
			return self._medalCounter.get(medalID, 0)
		
		# Type 40: 狩猎地带不损失通关 (HuntingPassUndead) - 手动计数
		elif targetType == 40:
			return self._medalCounter.get(medalID, 0)
		
		# Type 42: 狩猎地带特殊线路不损失通关 (HuntingSpecialRoutePassUndead) - 手动计数
		elif targetType == 42:
			return self._medalCounter.get(medalID, 0)
		
		# Type 43: 飞镖神准评价次数 (DartMaxEvaluateCount)
		elif targetType == 43:
			return getattr(role, 'town_home_party_dart_max_evaluate_counter', 0) or 0
		
		# Type 44: 自走棋连胜 (AutoChessNormalWinStreak)
		elif targetType == 44:
			return getattr(role, 'auto_chess_normal_type_win_streak', 0) or 0
		
		# Type 46: 自走棋签到天数 (AutoChessSignInDays)
		elif targetType == 46:
			return getattr(role, 'auto_chess_sign_in_days', 0) or 0
		
		# Type 47: 地狱以太乐园困难胜利 (HellRandomTowerHardBeatCount)
		elif targetType == 47:
			return getattr(role, 'hell_random_tower_hard_beat_count', 0) or 0
		
		# Type 58: 跨服自走棋赛季Top1连胜 (CrossOnlineAutoChessSeasonTop1WinStreak)
		elif targetType == 58:
			return getattr(role, 'cross_online_auto_chess_season_top1_win_streak', 0) or 0
		
		# Type 45: 卡牌冒险玩法排名 (AutoChessRankInTop) - 手动计数
		elif targetType == 45:
			return self._medalCounter.get(medalID, 0)
		
		# Type 57: 卡牌对决排名 (CrossOnlineAutoChessRankInTop) - 手动计数
		elif targetType == 57:
			return self._medalCounter.get(medalID, 0)
		
		# Type 59: 完好无损 (AutoChessWinWithHP) - 手动计数
		elif targetType == 59:
			return self._medalCounter.get(medalID, 0)
		
		# Type 60: 史前巨怪 (AutoChessAttrOver) - 未实现
		# 需要检查"单局内精灵的任一属性超过1000"，但精灵属性在前端战斗中计算，后端无此数据
		# medalID: 1681, 1682, 1683
		elif targetType == 60:
			return self._medalCounter.get(medalID, 0)
		
		# Type 19-25, 48-53: 排名类勋章 - 手动计数（排名结算时调用incrementMedalCounter）
		# Type 19: PVPRankInTop (公会精灵问答)
		elif targetType == 19:
			return self._medalCounter.get(medalID, 0)
		
		# Type 20: CrossArenaRankInTop (钓鱼大赛)
		elif targetType == 20:
			return self._medalCounter.get(medalID, 0)
		
		# Type 21: CrossMineRankInTop (跨服石英大会)
		elif targetType == 21:
			return self._medalCounter.get(medalID, 0)
		
		# Type 22: StarRoadRankInTop (对战竞技场)
		elif targetType == 22:
			return self._medalCounter.get(medalID, 0)
		
		# Type 23: YYHuoDongRankInTop (跨服商业街)
		elif targetType == 23:
			return self._medalCounter.get(medalID, 0)
		
		# Type 24: UnionRankInTop (世界锦标赛)
		elif targetType == 24:
			return self._medalCounter.get(medalID, 0)
		
		# Type 25: CrossMatchRankInTop (跨服竞技场王者段位)
		elif targetType == 25:
			return self._medalCounter.get(medalID, 0)
		
		# Type 48: HuntingRankInTop (拟态挑战)
		elif targetType == 48:
			return self._medalCounter.get(medalID, 0)
		
		# Type 49: 疾影驰斗公会排名 (未开发)
		elif targetType == 49:
			return self._medalCounter.get(medalID, 0)
		
		# Type 50: 疾影驰斗个人排名 (未开发)
		elif targetType == 50:
			return self._medalCounter.get(medalID, 0)
		
		# Type 51: 解锁准神瞬移飞船 (疾影驰斗功能，未开发)
		elif targetType == 51:
			return self._medalCounter.get(medalID, 0)
		
		# Type 52: OnlineFightRankInTop (帷幕马戏团)
		elif targetType == 52:
			return self._medalCounter.get(medalID, 0)
		
		# Type 53: CrossOnlineAutoChessRankInTop (跨服自走棋)
		elif targetType == 53:
			return self._medalCounter.get(medalID, 0)
		
		# Type 16: 建筑中心等级 (BuildingCenterLevel) - 需要特殊参数
		elif targetType == 16:
			targetArgSpecial = cfg.targetArgSpecial or {}
			buildingID = targetArgSpecial.get('buildingID', 0)
			buildingLevel = (role.town_building_level or {}).get(buildingID, 0)
			return buildingLevel
		
		# Type 17: 家园装饰度 (BuildingHomeDecorative)
		elif targetType == 17:
			return getattr(role, 'town_home_decorativeness', 0) or 0
		
		# Type 18: 好感度等级 (FeelLevel) - 统计达到指定好感度等级的精灵数量
		elif targetType == 18:
			targetArgSpecial = cfg.targetArgSpecial or {}
			requiredFeelLevel = targetArgSpecial.get('feelLevel', 500)  # 默认500
			card_feels = role.card_feels or {}
			count = 0
			for markID, feelData in card_feels.iteritems():
				level = feelData.get('level', 0)
				if level >= requiredFeelLevel:
					count += 1
			return count
		
		# Type 41: 星级 (StarLevel) - 需要特殊参数
		elif targetType == 41:
			if not hasattr(self.game.cards, 'markIDMaxStar'):
				return 0
			targetArgSpecial = cfg.targetArgSpecial or {}
			cardMarkIDs = targetArgSpecial.get('cardMarkIDs', [])
			targetStarLevel = targetArg
			count = 0
			for cardID in cardMarkIDs:
				if cardID not in csv.cards:
					continue
				cardMarkID = csv.cards[cardID].cardMarkID
				starLevel = self.game.cards.markIDMaxStar.get(cardMarkID, 0)
				if starLevel >= targetStarLevel:
					count += 1
			return count
		
		# Type 35: 人物形象数量 (FigureCount) - 拥有的人物形象总数
		elif targetType == 35:
			figures = role.figures or []
			return len(figures)
		
		# Type 36: 头像框数量 (FrameCount) - 拥有的头像框总数
		elif targetType == 36:
			frames = role.frames or []
			return len(frames)
		
		# Type 54: 纹章阶段达成数 (ArmsCount) - 统计达到指定阶段的纹章数量
		elif targetType == 54:
			targetArgSpecial = cfg.targetArgSpecial or {}
			requiredStage = targetArgSpecial.get('stage', 5)  # 默认阶段5
			arms_stage = role.arms_stage or {}
			count = 0
			for _, stage in arms_stage.iteritems():
				if stage >= requiredStage:
					count += 1
			return count
		
		# Type 55: 契约羁绊拥有数 (Contract) - 统计拥有指定羁绊组中契约的数量
		elif targetType == 55:
			targetArgSpecial = cfg.targetArgSpecial or {}
			requiredGroupID = targetArgSpecial.get('groupID', 0)
			if not requiredGroupID:
				return 0
			
			# 从 contract.group 获取该羁绊组需要的契约列表
			if not hasattr(csv.contract, 'group') or requiredGroupID not in csv.contract.group:
				return 0
			
			groupCfg = csv.contract.group[requiredGroupID]
			requiredContractIDs = set(groupCfg.items or [])  # 需要的契约 ID 列表
			if not requiredContractIDs:
				return 0
			
			# 获取玩家拥有的契约 ID 集合
			ownedContractIDs = set()
			contracts = role.contracts or []
			for contract_db_id in contracts:
				try:
					# 使用 game.contracts 获取契约对象（正确方式）
					contract = self.game.contracts.getContract(contract_db_id)
					if contract and contract.contract_id:
						ownedContractIDs.add(contract.contract_id)
				except (TypeError, AttributeError):
					# 跳过损坏的契约数据
					continue
			
			# 统计玩家拥有的羁绊组契约数量
			count = len(requiredContractIDs & ownedContractIDs)
			return count
		
		# Type 56: 家园扩建次数 (TownHomeExpandCount)
		elif targetType == 56:
			return getattr(role, 'town_home_expand_count', 0) or 0
		
		# 其他类型：从 medal_counter 读取
		else:
			return self._medalCounter.get(medalID, 0)
	
	def checkAndActivateMedal(self, medalID):
		"""检查并尝试激活勋章
		返回: 是否新激活
		"""
		if self.isMedalActive(medalID):
			return False
		
		if medalID not in csv.medal:
			return False
		
		cfg = csv.medal[medalID]
		current = self.getMedalCurrent(medalID)
		
		# 达标则标记为可领取（medalTask[k] = 1）
		if current >= cfg.targetArg:
			if self._medalTask is None:
				self.game.role.medal_task = {}
				self._medalTask = self.game.role.medal_task
			
			# 设置为1表示可领取
			if self._medalTask.get(medalID, -1) != 1:
				self._medalTask[medalID] = 1
				self.game.role.medal_task = self._medalTask
			return True
		
		# 未达标则更新任务进度
		if current > 0:
			self.updateMedalProgress(medalID, current)
		
		return False
	
	def incrementMedalCounter(self, medalID, count=1):
		"""增加勋章计数器
		用于需要手动计数的勋章类型
		"""
		if self._medalCounter is None:
			self.game.role.medal_counter = {}
			self._medalCounter = self.game.role.medal_counter
		
		oldCount = self._medalCounter.get(medalID, 0)
		newCount = oldCount + count
		self._medalCounter[medalID] = newCount
		self.game.role.medal_counter = self._medalCounter
		
		# 检查是否达标
		self.checkAndActivateMedal(medalID)
		
		return newCount
	
	def checkAllMedals(self):
		"""检查所有勋章的完成情况（登录时调用）"""
		newActivated = []
		
		for medalID in csv.medal:
			if self.isMedalActive(medalID):
				continue
			
			# 获取当前进度并记录日志
			cfg = csv.medal[medalID]
			current = self.getMedalCurrent(medalID)
			targetArg = cfg.targetArg
			
			if current >= targetArg:
				logger.info('[Medal] 玩家%s 勋章%d 已达标: current=%d, target=%d', 
						   self.game.role.id, medalID, current, targetArg)
			
			if self.checkAndActivateMedal(medalID):
				newActivated.append(medalID)
				logger.info('[Medal] 玩家%s 勋章%d 设置为可领取', self.game.role.id, medalID)
		
		if newActivated:
			logger.info('[Medal] 玩家%s 共有%d个勋章可领取: %s', 
					   self.game.role.id, len(newActivated), newActivated)
		
		return newActivated
