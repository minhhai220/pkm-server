#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Town Adventure Lottery - 探险抽奖系统
参考 lottery.py 的 ObjectDrawCardRandom 和 ObjectDrawRandomItem 实现
'''

from framework.object import ReloadHooker
from framework.csv import csv
from framework.log import logger
from framework import nowtime_t
from game.object import DrawDefs
from collections import defaultdict
import random


class ObjectTownAdventureAwardDrop(ReloadHooker):
	"""探险特殊掉落抽奖
	
	参考 ObjectDrawCardRandom 实现，使用 adventure.drop_info 存储玩家抽取记录
	CSV: town.adventure_award_drop
	"""
	
	CsvFile = 'town.adventure_award_drop'
	TriggerMap = {}  # {drawType: [drawTriggerType: [obj, ...], ...], ...}
	
	@classmethod
	def classInit(cls):
		"""初始化配置缓存"""
		if not hasattr(csv, 'town') or not hasattr(csv.town, 'adventure_award_drop'):
			cls.TriggerMap = {}
			return
		
		csvFile = csv.town.adventure_award_drop
		cls.TriggerMap = defaultdict(lambda: [[] for _ in xrange(DrawDefs.TriggerTotal)])
		
		for idx in csvFile:
			cfg = csvFile[idx]
			obj = cls(cfg)
			drawType = getattr(cfg, 'drawType', '')
			triggerType = getattr(cfg, 'drawTriggerType', 0)
			if drawType:
				cls.TriggerMap[drawType][triggerType].append(obj)
		
		# 按 drawTriggerTimes 从大到小排序
		for draws in cls.TriggerMap.itervalues():
			for triggers in draws:
				triggers.sort(key=lambda x: getattr(x.cfg, 'drawTriggerTimes', 0), reverse=True)
	
	@classmethod
	def getRandomItems(cls, game, drawType, drawTimes, areaType):
		"""抽取特殊掉落
		
		Args:
			game: 游戏对象
			drawType: 抽取类型 (如 'town_adventure1')
			drawTimes: 当前抽取次数
			areaType: 区域类型 (1-4)
		
		Returns:
			dict: {itemKey: count} 或 None
		"""
		if drawType not in cls.TriggerMap:
			return None
		
		triggers = cls.TriggerMap[drawType]
		dropInfo = cls._getDropInfo(game)
		
		# 先加权重（TriggerWeight 类型）
		for i in xrange(DrawDefs.TriggerTotal - 1, -1, -1):
			for obj in triggers[i]:
				if obj.cfg.drawTriggerType == DrawDefs.TriggerWeight:
					if not obj.isCountLimit(dropInfo, drawTimes):
						obj.addWeight(dropInfo)
		
		# 按优先级扫描触发
		for i in xrange(DrawDefs.TriggerTotal - 1, -1, -1):
			for obj in triggers[i]:
				if obj.isCountLimit(dropInfo, drawTimes):
					continue
				if obj.isActive(dropInfo, drawTimes):
					obj.activeProcess(dropInfo)
					# 获取对应区域的奖励
					awards = obj.getAwardByArea(areaType)
					if awards:
						cls._saveDropInfo(game, dropInfo)
						return awards
		
		cls._saveDropInfo(game, dropInfo)
		return None
	
	@classmethod
	def _getDropInfo(cls, game):
		"""获取玩家的掉落记录"""
		adventure = game.town.adventure or {}
		dropInfo = adventure.get('drop_info', {})
		return {
			'count': dropInfo.get('count', 0),
			'weight': dict(dropInfo.get('weight', {})),
			'effect': dict(dropInfo.get('effect', {})),
		}
	
	@classmethod
	def _saveDropInfo(cls, game, dropInfo):
		"""保存玩家的掉落记录"""
		adventure = dict(game.town.adventure or {})
		adventure['drop_info'] = {
			'count': dropInfo['count'],
			'weight': dropInfo['weight'],
			'effect': dropInfo['effect'],
		}
		game.town.adventure = adventure
	
	def __init__(self, cfg):
		self._csvID = cfg.id
		self.cfg = cfg
	
	def isCountLimit(self, dropInfo, times):
		"""检查是否达到生效限制"""
		startCount = getattr(self.cfg, 'startCount', 0)
		if times < startCount:
			return True
		
		effectLimit = getattr(self.cfg, 'effectLimit', 0)
		if effectLimit > 0:
			effectCount = dropInfo['effect'].get(self._csvID, 0)
			if effectCount >= effectLimit:
				return True
		return False
	
	def addWeight(self, dropInfo):
		"""累加权重（TriggerWeight 类型）"""
		if self.cfg.drawTriggerType == DrawDefs.TriggerWeight:
			weightStart = getattr(self.cfg, 'weightStart', 0)
			weightEnd = getattr(self.cfg, 'weightEnd', 0)
			weight = random.uniform(weightStart, weightEnd)
			dropInfo['weight'][self._csvID] = dropInfo['weight'].get(self._csvID, 0) + weight
	
	def activeProcess(self, dropInfo):
		"""触发后处理"""
		if self.cfg.drawTriggerType == DrawDefs.TriggerWeight:
			dropInfo['weight'][self._csvID] = dropInfo['weight'].get(self._csvID, 0) - 1
		
		effectLimit = getattr(self.cfg, 'effectLimit', 0)
		if effectLimit > 0 or self.cfg.drawTriggerType == DrawDefs.TriggerProb:
			dropInfo['effect'][self._csvID] = dropInfo['effect'].get(self._csvID, 0) + 1
	
	def isActive(self, dropInfo, times):
		"""判断是否触发"""
		startCount = getattr(self.cfg, 'startCount', 0)
		count = times - startCount
		triggerType = getattr(self.cfg, 'drawTriggerType', 0)
		
		if triggerType == DrawDefs.TriggerStart:
			# 从X次开始
			triggerTimes = getattr(self.cfg, 'drawTriggerTimes', 0)
			return count >= triggerTimes
		
		elif triggerType == DrawDefs.TriggerWeight:
			# 权值累加
			return dropInfo['weight'].get(self._csvID, 0) >= 1
		
		elif triggerType == DrawDefs.TriggerProb:
			# 概率触发
			probEffectInterval = getattr(self.cfg, 'probEffectInterval', 50)
			probMiniTimes = getattr(self.cfg, 'probMiniTimes', 30)
			
			# 1. 判断生效间隔内是否已经生效
			process = dropInfo['effect'].get(self._csvID, 0)
			if probEffectInterval > 0 and process >= (count - 1) / probEffectInterval + 1:
				return False
			
			# 2. 保底次数激活
			if probEffectInterval > 0 and (count - 1) % probEffectInterval + 1 >= probMiniTimes:
				return True
			
			# 3. 概率激活
			probInit = getattr(self.cfg, 'probInit', 0)
			probStep = getattr(self.cfg, 'probStep', 0.01)
			probLimit = getattr(self.cfg, 'probLimit', 0.2)
			
			prob = probInit + probStep * ((count - 1) % probEffectInterval if probEffectInterval > 0 else 0)
			prob = min(prob, probLimit)
			return random.random() <= prob
		
		elif triggerType == DrawDefs.TriggerEvery:
			# 每X次
			triggerTimes = getattr(self.cfg, 'drawTriggerTimes', 0)
			return triggerTimes > 0 and count >= triggerTimes and count % triggerTimes == 0
		
		elif triggerType == DrawDefs.TriggerOnce:
			# 第X次
			triggerTimes = getattr(self.cfg, 'drawTriggerTimes', 0)
			return count == triggerTimes
		
		return False
	
	def getAwardByArea(self, areaType):
		"""获取对应区域的奖励"""
		awardField = 'awardArea%d' % areaType
		awards = getattr(self.cfg, awardField, {})
		if awards:
			return dict(awards)
		return None


class ObjectTownRelicBuff(ReloadHooker):
	"""遗迹祝福抽取
	
	参考 ObjectDrawCardRandom 实现
	CSV: town.relic_draw_buff, town.relic_buff
	
	触发类型 (drawTriggerType):
	- 2: TriggerProb 概率触发（概率递增）
	- 4: TriggerOnce 第X次必触发（保底）
	
	抽奖类型 (lotteryType):
	- 10: 空抽（无祝福）
	- 11: 日常副本类祝福 (type 1-4)
	- 12: 冒险/派遣/体力/聚宝类祝福 (type 5-8)
	- 13: 家园类祝福 (type 9-12)
	- 14: 直接奖励类祝福 (type 13+, award 字段)
	"""
	
	CsvFile = 'town.relic_draw_buff'
	TriggerMap = {}  # {drawType: [[obj, ...], ...]}  按 drawTriggerType 分组
	BuffLib = {}  # {lotteryType: [cfg, ...]}  祝福配置库
	
	# 遗迹祝福配置（从 relic_base.csv 读取，classInit 中初始化）
	UNLOCK_LEVEL = 5  # 解锁等级阈值
	DAILY_DRAW_TIMES = 1  # 每日抽取次数
	BUFF_QUEUE_MAX = 20  # Buff队列最大长度
	# 遗迹建筑 ID
	RELIC_BUILDING_IDS = [14, 15, 16, 17]  # 大漠、山城、苍雪、熔岩
	
	@classmethod
	def classInit(cls):
		"""初始化配置缓存"""
		logger.info('[RelicBuff] classInit: starting...')
		cls.TriggerMap = defaultdict(lambda: [[] for _ in xrange(DrawDefs.TriggerTotal)])
		cls.BuffLib = defaultdict(list)
		
		# 从 relic_base.csv 读取全局配置
		if hasattr(csv, 'town') and hasattr(csv.town, 'relic_base'):
			for idx in csv.town.relic_base:
				baseCfg = csv.town.relic_base[idx]
				cls.UNLOCK_LEVEL = getattr(baseCfg, 'levelThreshold', 5)
				cls.DAILY_DRAW_TIMES = getattr(baseCfg, 'dailyDrawBuffTimes', 1)
				cls.BUFF_QUEUE_MAX = getattr(baseCfg, 'buffQueueMaxLength', 20)
				logger.info('[RelicBuff] classInit: loaded relic_base config - UNLOCK_LEVEL=%s DAILY_DRAW_TIMES=%s BUFF_QUEUE_MAX=%s',
					cls.UNLOCK_LEVEL, cls.DAILY_DRAW_TIMES, cls.BUFF_QUEUE_MAX)
				break  # 只取第一条配置
		
		# 加载 relic_draw_buff.csv
		hasDrawBuff = hasattr(csv, 'town') and hasattr(csv.town, 'relic_draw_buff')
		logger.info('[RelicBuff] classInit: csv.town.relic_draw_buff exists=%s', hasDrawBuff)
		if hasDrawBuff:
			count = 0
			for idx in csv.town.relic_draw_buff:
				cfg = csv.town.relic_draw_buff[idx]
				# 检查 cfg 的实际属性
				drawType = cfg.drawType  # 直接访问属性，不用 getattr
				triggerType = cfg.drawTriggerType
				logger.info('[RelicBuff] classInit: idx=%s drawType=%s triggerType=%s', idx, drawType, triggerType)
				obj = cls(cfg)
				if drawType:
					cls.TriggerMap[drawType][triggerType].append(obj)
					count += 1
			logger.info('[RelicBuff] classInit: loaded %d draw configs, TriggerMap keys=%s', count, list(cls.TriggerMap.keys()))
			
			# 按 drawTriggerTimes 从大到小排序
			for draws in cls.TriggerMap.itervalues():
				for triggers in draws:
					triggers.sort(key=lambda x: getattr(x.cfg, 'drawTriggerTimes', 0), reverse=True)
		
		# 加载 relic_buff.csv，按 lotteryType 分组
		hasRelicBuff = hasattr(csv, 'town') and hasattr(csv.town, 'relic_buff')
		logger.info('[RelicBuff] classInit: csv.town.relic_buff exists=%s', hasRelicBuff)
		if hasRelicBuff:
			count = 0
			for idx in csv.town.relic_buff:
				cfg = csv.town.relic_buff[idx]
				lotteryType = getattr(cfg, 'lotteryType', 0)
				if lotteryType > 0:
					cls.BuffLib[lotteryType].append(cfg)
					count += 1
			logger.info('[RelicBuff] classInit: loaded %d buff configs, BuffLib keys=%s', count, list(cls.BuffLib.keys()))
	
	@classmethod
	def isUnlocked(cls, game):
		"""检查遗迹祝福是否解锁（4个遗迹都达到5级）"""
		if not game or not game.town:
			logger.info('[RelicBuff] isUnlocked: no town data')
			return False
		
		buildings = game.town.buildings or {}
		relicLevels = {}
		for relicId in cls.RELIC_BUILDING_IDS:
			buildData = buildings.get(relicId, {})
			level = buildData.get('level', 0)
			relicLevels[relicId] = level
			if level < cls.UNLOCK_LEVEL:
				logger.info('[RelicBuff] isUnlocked: relic %s level=%s < required=%s (all levels: %s)', 
					relicId, level, cls.UNLOCK_LEVEL, relicLevels)
				return False
		logger.info('[RelicBuff] isUnlocked: TRUE (all relics >= %s: %s)', cls.UNLOCK_LEVEL, relicLevels)
		return True
	
	@classmethod
	def tryDrawBuff(cls, game, drawType='town_relic1'):
		"""尝试抽取遗迹祝福
		
		Args:
			game: 游戏对象
			drawType: 抽取类型
		
		Returns:
			int: 抽中的 buff_id，0 表示未抽中
		"""
		# 延迟初始化检查：如果 TriggerMap 为空，尝试重新加载
		if not cls.TriggerMap:
			logger.info('[RelicBuff] tryDrawBuff: TriggerMap is empty, calling classInit...')
			cls.classInit()
		
		if not cls.isUnlocked(game):
			logger.info('[RelicBuff] tryDrawBuff: not unlocked, skip')
			return 0
		
		if drawType not in cls.TriggerMap:
			logger.info('[RelicBuff] tryDrawBuff: drawType=%s not in TriggerMap (keys=%s)', drawType, list(cls.TriggerMap.keys()))
			return 0
		
		logger.info('[RelicBuff] tryDrawBuff: starting draw for type=%s', drawType)
		
		triggers = cls.TriggerMap[drawType]
		drawRecord = cls._getDrawRecord(game)
		drawTimes = drawRecord.get('draw_times', 0) + 1
		
		# 先加权重（TriggerWeight 类型）
		for i in xrange(DrawDefs.TriggerTotal - 1, -1, -1):
			for obj in triggers[i]:
				triggerType = getattr(obj.cfg, 'drawTriggerType', 0)
				if triggerType == DrawDefs.TriggerWeight:
					if not obj.isCountLimit(drawRecord, drawTimes):
						obj.addWeight(drawRecord)
		
		# 按优先级扫描触发
		buffId = 0
		for i in xrange(DrawDefs.TriggerTotal - 1, -1, -1):
			for obj in triggers[i]:
				if obj.isCountLimit(drawRecord, drawTimes):
					continue
				if obj.isActive(drawRecord, drawTimes):
					obj.activeProcess(drawRecord)
					# 根据权重抽取 lotteryType
					lotteryType = obj.rollLotteryType()
					if lotteryType > 0:
						# 从对应的 BuffLib 中抽取具体祝福
						buffId = cls._rollBuffFromLib(game, lotteryType)
						if buffId > 0:
							cls._addBuff(game, buffId)
							break
			if buffId > 0:
				break
		
		# 更新抽取次数
		drawRecord['draw_times'] = drawTimes
		cls._saveDrawRecord(game, drawRecord)
		
		return buffId
	
	@classmethod
	def _getDrawRecord(cls, game):
		"""获取玩家的抽取记录"""
		drawRecord = game.town.relic_buff_draw_record or {}
		return {
			'draw_times': drawRecord.get('draw_times', 0),
			'weight': dict(drawRecord.get('weight', {})),
			'effect': dict(drawRecord.get('effect', {})),
		}
	
	@classmethod
	def _saveDrawRecord(cls, game, drawRecord):
		"""保存玩家的抽取记录"""
		game.town.relic_buff_draw_record = {
			'draw_times': drawRecord['draw_times'],
			'weight': drawRecord['weight'],
			'effect': drawRecord['effect'],
		}
	
	@classmethod
	def _rollBuffFromLib(cls, game, lotteryType):
		"""从祝福库中抽取具体祝福"""
		if lotteryType not in cls.BuffLib:
			return 0
		
		buildings = game.town.buildings or {}
		validBuffs = []
		totalWeight = 0
		
		for cfg in cls.BuffLib[lotteryType]:
			# 检查遗迹等级限制
			relicLimit = getattr(cfg, 'relicLevelLimit', {})
			if relicLimit:
				valid = True
				for relicId, levelRange in relicLimit.iteritems():
					relicId = int(relicId)
					buildData = buildings.get(relicId, {})
					level = buildData.get('level', 0)
					minLevel = levelRange[0] if len(levelRange) > 0 else 0
					maxLevel = levelRange[1] if len(levelRange) > 1 else 999
					if level < minLevel or level > maxLevel:
						valid = False
						break
				if not valid:
					continue
			
			weight = getattr(cfg, 'weight', 0)
			if weight > 0:
				validBuffs.append((cfg.id, weight))
				totalWeight += weight
		
		if not validBuffs or totalWeight <= 0:
			return 0
		
		# 权重抽取
		roll = random.randint(1, totalWeight)
		cumWeight = 0
		for buffId, weight in validBuffs:
			cumWeight += weight
			if roll <= cumWeight:
				return buffId
		
		return 0
	
	@classmethod
	def _addBuff(cls, game, buffId):
		"""添加祝福到玩家数据，或直接发放奖励道具"""
		if not hasattr(csv, 'town') or not hasattr(csv.town, 'relic_buff'):
			return
		
		if buffId not in csv.town.relic_buff:
			return
		cfg = csv.town.relic_buff[buffId]
		
		buffType = getattr(cfg, 'type', 0)
		award = getattr(cfg, 'award', None)
		
		# 如果有 award 字段且 type=0，直接发放奖励道具
		if buffType <= 0:
			if award:
				from game.object.game.gain import ObjectGainAux
				eff = ObjectGainAux(game, award)
				eff.gain(src='town_relic_buff_award')
				logger.info('ObjectTownRelicBuff._addBuff: role=%s buffId=%s direct award=%s', 
					game.role.id, buffId, award)
			return
		
		relicBuff = dict(game.town.relic_buff or {})
		
		# 确保 buffType 对应的列表存在
		if buffType not in relicBuff or not isinstance(relicBuff.get(buffType), list):
			relicBuff[buffType] = []
		
		# 创建祝福数据
		now = nowtime_t()
		duration = getattr(cfg, 'duration', 0)  # 小时
		effectiveTimes = getattr(cfg, 'effectiveTimes', 0)
		
		buffData = {
			'buff_id': buffId,
			'used_times': 0,
			'effect_time': now + duration * 3600 if duration > 0 else 0,
			'gotten_time': now,  # 前端需要的获取时间
		}
		
		# 同类型祝福只保留一个
		relicBuff[buffType] = [buffData]
		game.town.relic_buff = relicBuff
		
		logger.info('ObjectTownRelicBuff._addBuff: role=%s buffId=%s type=%s', 
			game.role.id, buffId, buffType)
	
	@classmethod
	def refreshExpiredBuffs(cls, game):
		"""刷新过期的祝福"""
		if not game or not game.town:
			return
		
		relicBuff = game.town.relic_buff or {}
		if not relicBuff:
			return
		
		now = nowtime_t()
		changed = False
		newRelicBuff = {}
		
		for key, value in relicBuff.iteritems():
			if not isinstance(value, list):
				continue
			
			# 确保 key 是整数类型
			try:
				buffType = int(key)
			except (TypeError, ValueError):
				continue
			
			validBuffs = []
			for buffData in value:
				if not isinstance(buffData, dict):
					continue
				
				buffId = buffData.get('buff_id', 0)
				if not buffId:
					continue
				
				if not hasattr(csv.town, 'relic_buff') or buffId not in csv.town.relic_buff:
					continue
				cfg = csv.town.relic_buff[buffId]
				
				# 检查时间限制
				effectTime = buffData.get('effect_time', 0)
				if effectTime > 0 and now >= effectTime:
					changed = True
					continue
				
				# 检查次数限制
				effectiveTimes = getattr(cfg, 'effectiveTimes', 0)
				usedTimes = buffData.get('used_times', 0)
				if effectiveTimes > 0 and usedTimes >= effectiveTimes:
					changed = True
					continue
				
				validBuffs.append(buffData)
			
			if validBuffs:
				newRelicBuff[buffType] = validBuffs
			else:
				changed = True
		
		if changed:
			game.town.relic_buff = newRelicBuff
	
	@classmethod
	def consumeBuff(cls, game, buffType):
		"""消耗一次祝福（增加使用次数）
		
		Args:
			game: 游戏对象
			buffType: 祝福类型
		
		Returns:
			dict: 祝福配置，None 表示无可用祝福
		"""
		if not game or not game.town:
			logger.info('[RelicBuff] consumeBuff type=%s: no town data', buffType)
			return None
		
		relicBuff = game.town.relic_buff or {}
		buffList = relicBuff.get(buffType, [])
		if not buffList or not isinstance(buffList, list):
			logger.info('[RelicBuff] consumeBuff type=%s: no buff in relic_buff (keys=%s)', buffType, list(relicBuff.keys()))
			return None
		
		for buffData in buffList:
			if not isinstance(buffData, dict):
				continue
			
			buffId = buffData.get('buff_id', 0)
			if not buffId:
				continue
			
			if not hasattr(csv.town, 'relic_buff') or buffId not in csv.town.relic_buff:
				continue
			cfg = csv.town.relic_buff[buffId]
			
			effectiveTimes = getattr(cfg, 'effectiveTimes', 0)
			usedTimes = buffData.get('used_times', 0)
			
			# 有次数限制的，增加使用次数
			if effectiveTimes > 0:
				if usedTimes >= effectiveTimes:
					logger.info('[RelicBuff] consumeBuff type=%s buffId=%s: used up (%s/%s)', buffType, buffId, usedTimes, effectiveTimes)
					continue
				buffData['used_times'] = usedTimes + 1
				# 触发脏标记
				newRelicBuff = dict(relicBuff)
				newRelicBuff[buffType] = list(buffList)
				game.town.relic_buff = newRelicBuff
				logger.info('[RelicBuff] consumeBuff type=%s buffId=%s: consumed (%s/%s)', buffType, buffId, usedTimes + 1, effectiveTimes)
			else:
				logger.info('[RelicBuff] consumeBuff type=%s buffId=%s: no times limit, always active', buffType, buffId)
			
			return cfg
		
		logger.info('[RelicBuff] consumeBuff type=%s: no valid buff found in list (len=%s)', buffType, len(buffList))
		return None
	
	@classmethod
	def getActiveBuffParam(cls, game, buffType):
		"""获取持续时间类型祝福的参数值（不消耗次数）
		
		用于 type 5（冒险之路概率增加）、type 10-12（工厂生产速度增加）等持续时间效果
		
		Args:
			game: 游戏对象
			buffType: 祝福类型
		
		Returns:
			float: param 值，0 表示无激活的祝福
		"""
		if not game or not game.town:
			return 0
		
		relicBuff = game.town.relic_buff or {}
		buffList = relicBuff.get(buffType, [])
		if not buffList or not isinstance(buffList, list):
			return 0
		
		now = nowtime_t()
		
		for buffData in buffList:
			if not isinstance(buffData, dict):
				continue
			
			buffId = buffData.get('buff_id', 0)
			if not buffId:
				continue
			
			if not hasattr(csv.town, 'relic_buff') or buffId not in csv.town.relic_buff:
				continue
			cfg = csv.town.relic_buff[buffId]
			
			# 检查持续时间是否有效
			duration = getattr(cfg, 'duration', 0)
			if duration > 0:
				effectTime = buffData.get('effect_time', 0)
				if effectTime > 0 and now >= effectTime:
					continue  # 已过期
			
			# 检查次数限制
			effectiveTimes = getattr(cfg, 'effectiveTimes', 0)
			if effectiveTimes > 0:
				usedTimes = buffData.get('used_times', 0)
				if usedTimes >= effectiveTimes:
					continue  # 次数用完
			
			param = getattr(cfg, 'param', 0)
			return param
		
		return 0
	
	def __init__(self, cfg):
		self._csvID = cfg.id
		self.cfg = cfg
		
		# 解析 lotteryType 和 lotteryWeight
		self._lotteryTypes = []
		self._lotteryWeights = []
		self._totalWeight = 0
		
		for i in xrange(1, 6):
			lotteryType = getattr(cfg, 'lotteryType%d' % i, 0)
			lotteryWeight = getattr(cfg, 'lotteryWeight%d' % i, 0)
			if lotteryType > 0 and lotteryWeight > 0:
				self._lotteryTypes.append(lotteryType)
				self._lotteryWeights.append(lotteryWeight)
				self._totalWeight += lotteryWeight
	
	def isCountLimit(self, drawRecord, times):
		"""检查是否达到生效限制"""
		startCount = getattr(self.cfg, 'startCount', 0)
		if times < startCount:
			return True
		
		effectLimit = getattr(self.cfg, 'effectLimit', 0)
		if effectLimit > 0:
			effectCount = drawRecord['effect'].get(self._csvID, 0)
			if effectCount >= effectLimit:
				return True
		return False
	
	def addWeight(self, drawRecord):
		"""累加权重（TriggerWeight 类型）"""
		triggerType = getattr(self.cfg, 'drawTriggerType', 0)
		if triggerType == DrawDefs.TriggerWeight:
			weightStart = getattr(self.cfg, 'weightStart', 0)
			weightEnd = getattr(self.cfg, 'weightEnd', 0)
			weight = random.uniform(weightStart, weightEnd)
			drawRecord['weight'][self._csvID] = drawRecord['weight'].get(self._csvID, 0) + weight
	
	def activeProcess(self, drawRecord):
		"""触发后处理"""
		triggerType = getattr(self.cfg, 'drawTriggerType', 0)
		if triggerType == DrawDefs.TriggerWeight:
			drawRecord['weight'][self._csvID] = drawRecord['weight'].get(self._csvID, 0) - 1
		
		effectLimit = getattr(self.cfg, 'effectLimit', 0)
		if effectLimit > 0 or triggerType == DrawDefs.TriggerProb:
			drawRecord['effect'][self._csvID] = drawRecord['effect'].get(self._csvID, 0) + 1
	
	def isActive(self, drawRecord, times):
		"""判断是否触发"""
		startCount = getattr(self.cfg, 'startCount', 0)
		count = times - startCount
		triggerType = getattr(self.cfg, 'drawTriggerType', 0)
		
		# count <= 0 表示未达到起始次数，不触发
		if count <= 0:
			return False
		
		if triggerType == DrawDefs.TriggerStart:
			triggerTimes = getattr(self.cfg, 'drawTriggerTimes', 0)
			return count >= triggerTimes
		
		elif triggerType == DrawDefs.TriggerWeight:
			return drawRecord['weight'].get(self._csvID, 0) >= 1
		
		elif triggerType == DrawDefs.TriggerProb:
			probEffectInterval = getattr(self.cfg, 'probEffectInterval', 50)
			probMiniTimes = getattr(self.cfg, 'probMiniTimes', 30)
			
			process = drawRecord['effect'].get(self._csvID, 0)
			if probEffectInterval > 0 and process >= (count - 1) / probEffectInterval + 1:
				return False
			
			if probEffectInterval > 0 and (count - 1) % probEffectInterval + 1 >= probMiniTimes:
				return True
			
			probInit = getattr(self.cfg, 'probInit', 0)
			probStep = getattr(self.cfg, 'probStep', 0.01)
			probLimit = getattr(self.cfg, 'probLimit', 0.2)
			
			prob = probInit + probStep * ((count - 1) % probEffectInterval if probEffectInterval > 0 else 0)
			prob = min(prob, probLimit)
			return random.random() <= prob
		
		elif triggerType == DrawDefs.TriggerEvery:
			triggerTimes = getattr(self.cfg, 'drawTriggerTimes', 0)
			return triggerTimes > 0 and count >= triggerTimes and count % triggerTimes == 0
		
		elif triggerType == DrawDefs.TriggerOnce:
			triggerTimes = getattr(self.cfg, 'drawTriggerTimes', 0)
			return count == triggerTimes
		
		return False
	
	def rollLotteryType(self):
		"""根据权重抽取 lotteryType"""
		if self._totalWeight <= 0 or not self._lotteryTypes:
			return 0
		
		roll = random.randint(1, self._totalWeight)
		cumWeight = 0
		for i, weight in enumerate(self._lotteryWeights):
			cumWeight += weight
			if roll <= cumWeight:
				return self._lotteryTypes[i]
		
		return 0


class ObjectTownAdventureAward(ReloadHooker):
	"""探险随机奖励抽取
	
	参考 ObjectDrawRandomItem 实现
	CSV: town.adventure_award
	"""
	
	Lib = {}  # {randomBelongID: [ObjectTownAdventureAward, ...]}
	
	@classmethod
	def classInit(cls):
		"""初始化配置缓存"""
		cls.Lib = defaultdict(list)
		if not hasattr(csv, 'town') or not hasattr(csv.town, 'adventure_award'):
			return
		
		for idx in csv.town.adventure_award:
			cfg = csv.town.adventure_award[idx]
			belongId = getattr(cfg, 'randomBelongID', 0)
			if belongId:
				cls.Lib[belongId].append(cls(cfg))
	
	@classmethod
	def getRandomItems(cls, game, belongId, currentPoints, drawCount):
		"""抽取随机奖励
		
		Args:
			game: 游戏对象
			belongId: 归属ID (adventure_award.randomBelongID)
			currentPoints: 当前探索点数
			drawCount: 抽取次数
		
		Returns:
			dict: {itemKey: count}
		"""
		result = {}
		if belongId not in cls.Lib:
			return result
		
		# 筛选符合条件的配置
		validConfigs = []
		totalWeight = 0
		for obj in cls.Lib[belongId]:
			needPoints = getattr(obj.cfg, 'needExplorationPoint', 0)
			if needPoints and currentPoints < needPoints:
				continue
			weight = getattr(obj.cfg, 'weight', 0)
			if weight <= 0:
				continue
			validConfigs.append((obj, weight))
			totalWeight += weight
		
		if not validConfigs or totalWeight <= 0:
			return result
		
		# 抽取
		for _ in xrange(drawCount):
			roll = random.randint(1, totalWeight)
			cumWeight = 0
			for obj, weight in validConfigs:
				cumWeight += weight
				if roll <= cumWeight:
					# 从 awards 中抽取具体物品
					item = obj.getRandomItem(game)
					if item:
						itemKey, itemCount = item
						if itemKey and itemKey != 'none':
							result[itemKey] = result.get(itemKey, 0) + itemCount
					break
		
		return result
	
	def __init__(self, cfg):
		self._csvID = cfg.id
		self.cfg = cfg
		self._sum = 0
		self._lst = []
		
		# 解析 awards: <<itemId;weight;count>;...>
		awards = getattr(cfg, 'awards', [])
		if awards:
			for item in awards:
				if len(item) >= 3:
					itemId, weight, count = item[0], item[1], item[2]
					if weight > 0:
						self._sum += weight
						self._lst.append((itemId, count, weight))
	
	def getRandomItem(self, game=None):
		"""抽取单个物品"""
		if self._sum <= 0 or not self._lst:
			return None
		
		# 只有一个直接返回
		if len(self._lst) == 1:
			itemId, count, _ = self._lst[0]
			return (itemId, count)
		
		roll = random.randint(1, self._sum)
		for itemId, count, weight in self._lst:
			roll -= weight
			if roll <= 0:
				return (itemId, count)
		
		return None

