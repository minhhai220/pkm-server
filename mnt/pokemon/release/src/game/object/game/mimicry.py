#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
============================================================================
拟态对战 (Mimicry Battle) - 玩家数据对象
文档: docs/拟态对战_Python服务端.md
============================================================================
'''

from __future__ import absolute_import

from framework.csv import csv
from framework.object import ObjectDBase, db_property
from framework.helper import transform2list
from framework.log import logger
from game import ClientError


def _get_mimicry_base():
	"""获取拟态基础配置"""
	base = getattr(csv, 'mimicry', None)
	if not base:
		return None
	baseTable = getattr(base, 'base', None)
	if not baseTable:
		return None
	try:
		return baseTable[1]
	except KeyError:
		return None


class ObjectMimicry(ObjectDBase):
	"""玩家拟态对战数据"""
	DBModel = 'Mimicry'
	ClientIgnores = set(['id'])  # id 字段不同步给客户端

	# 已解锁的Buff列表
	buffs = db_property('buffs')
	# 每个Boss选择的Buff {bossID: [buffID, ...]}
	buff_choice = db_property('buff_choice')
	# 每个Boss的Buff槽位数 {bossID: [q1Num, q2Num, q3Num, q4Num]}
	buff_field = db_property('buff_field')
	# 每个Boss的当前分数 {bossID: score}
	total_scores = db_property('total_scores')
	# 每个Boss的历史最高分 {bossID: score}
	history_scores = db_property('history_scores')
	# 成就进度 {taskID: value}
	achievement_value = db_property('achievement_value')
	# 成就状态 {taskID: 0=已领取/1=可领取/2=不可领取}（与前端一致）
	achievement_state = db_property('achievement_state')
	# 最高分的BossID
	best_boss_id = db_property('best_boss_id')
	# 最高分
	best_score = db_property('best_score')
	# 排名
	mimicry_rank = db_property('mimicry_rank')
	# 战斗卡牌 {bossID: {pos: cardInfo}}
	battle_cards = db_property('battle_cards')
	# 剩余战斗次数
	battle_times = db_property('battle_times')
	# 上次刷新战斗次数的日期
	battle_times_last_date = db_property('battle_times_last_date')
	# 累计挑战次数（用于 dropTriggerTimes 触发）
	total_battle_count = db_property('total_battle_count')
	# 已触发的掉落配置次数 {cfgID: count}
	drop_trigger_count = db_property('drop_trigger_count')
	# 上次活动周期的 end_date（用于检测活动周期变化）
	last_end_date = db_property('last_end_date')

	# 标记是否已初始化
	inited = False

	@classmethod
	def classInit(cls):
		pass

	def init(self):
		if self.db is None:
			return self
		ObjectDBase.init(self)
		self._ensureDefaults()
		self.inited = True
		return self

	def set(self, dic):
		if dic is None:
			dic = {}
		ObjectDBase.set(self, dic)
		self._ensureDefaults()
		return self

	def _ensureDefaults(self):
		"""确保默认值存在"""
		if self.db is None:
			return
		db = self.db
		base = _get_mimicry_base()

		# 确保 id 字段存在
		if 'id' not in db:
			from bson.objectid import ObjectId
			dict.__setitem__(db, 'id', ObjectId())

		# 获取有效的 buff ID 集合
		validBuffIDs = set()
		if hasattr(csv, 'mimicry') and hasattr(csv.mimicry, 'buffs'):
			for bid in csv.mimicry.buffs:
				validBuffIDs.add(bid)

		# 构建 dropID -> [buffID, ...] 映射表
		dropIDToBuffs = {}
		if hasattr(csv, 'mimicry') and hasattr(csv.mimicry, 'buffs'):
			for buffID in csv.mimicry.buffs:
				buffCfg = csv.mimicry.buffs[buffID]
				dropID = getattr(buffCfg, 'dropID', 0) or 0
				buffBossID = getattr(buffCfg, 'bossID', 0) or 0
				# 只添加通用 buff（bossID=0）作为初始可选
				if buffBossID == 0:
					if dropID not in dropIDToBuffs:
						dropIDToBuffs[dropID] = []
					dropIDToBuffs[dropID].append(buffID)

		# 初始化各字段默认值
		if self.buffs is None or len(self.buffs or []) == 0:
			# 初始Buff - initBuff 格式: {pos=dropID}，从 dropID 对应的 buff 池中随机选
			# 新周期开始或首次进入时分配初始buff
			import random
			initBuffs = []
			if base:
				initBuffCfg = getattr(base, 'initBuff', {}) or {}
				for dropID in initBuffCfg.itervalues():
					if dropID and isinstance(dropID, int):
						candidates = dropIDToBuffs.get(dropID, [])
						if candidates:
							buffID = random.choice(candidates)
							initBuffs.append(buffID)
			self.buffs = initBuffs
		else:
			# 清理已存在的无效 buff ID
			currentBuffs = self.buffs or []
			cleanedBuffs = [bid for bid in currentBuffs if bid in validBuffIDs]
			if len(cleanedBuffs) != len(currentBuffs):
				logger.info('mimicry: cleaned invalid buffs from %s to %s', currentBuffs, cleanedBuffs)
				self.buffs = cleanedBuffs

		if self.buff_choice is None:
			self.buff_choice = {}
		if self.buff_field is None:
			self.buff_field = {}
		if self.total_scores is None:
			self.total_scores = {}
		if self.history_scores is None:
			self.history_scores = {}
		if self.achievement_value is None:
			self.achievement_value = {}
		if self.achievement_state is None:
			self.achievement_state = {}
		if self.battle_cards is None:
			self.battle_cards = {}
		if self.battle_times is None:
			self.battle_times = base.initBattleTimes if base else 10
		if self.battle_times_last_date is None:
			self.battle_times_last_date = 0
		if self.best_boss_id is None:
			self.best_boss_id = 0
		if self.best_score is None:
			self.best_score = 0

	def ensureBossEntry(self, bossID):
		"""确保Boss相关数据存在"""
		bossID = int(bossID)
		base = _get_mimicry_base()

		# 初始化Buff槽位
		if bossID not in self.buff_field:
			if base:
				self.buff_field[bossID] = [
					getattr(base, 'quality{}BuffFieldNum'.format(quality), 0) or 0
					for quality in range(1, 5)
				]
			else:
				self.buff_field[bossID] = [8, 6, 3, 2]  # 默认槽位数

		# 初始化其他字段
		self.buff_choice.setdefault(bossID, [])
		self.total_scores.setdefault(bossID, 0)
		self.history_scores.setdefault(bossID, 0)
		self.battle_cards.setdefault(bossID, {})

	def deployBuff(self, bossID, buffIDs):
		"""部署Buff到指定Boss"""
		self.ensureBossEntry(bossID)
		buffIDs = [int(x) for x in transform2list(buffIDs) if x]

		# 检查Buff是否已解锁
		unlockedBuffs = set(self.buffs or [])
		for buffID in buffIDs:
			if buffID not in unlockedBuffs:
				raise ClientError('buff not unlocked')

		# 统计每个品质的数量
		counts = {}
		for buffID in buffIDs:
			try:
				cfg = csv.mimicry.buffs[buffID]
			except KeyError:
				raise ClientError('buff not exists')
			quality = cfg.quality
			counts[quality] = counts.get(quality, 0) + 1

		# 检查是否超出槽位限制
		for quality, num in counts.iteritems():
			limit = self.getBuffCapacity(bossID, quality)
			if num > limit:
				raise ClientError('buff quality limit')

		self.buff_choice[bossID] = buffIDs

	def getBuffCapacity(self, bossID, quality):
		"""获取指定品质的Buff槽位数"""
		self.ensureBossEntry(bossID)
		buffField = self.buff_field.get(bossID, [])
		if quality <= 0 or quality > len(buffField):
			return 0
		return buffField[quality - 1]

	def appendBuffs(self, newBuffs):
		"""添加新解锁的Buff
		
		返回: 实际新添加的 Buff ID 列表
		"""
		# 获取有效的 buff ID 集合
		validBuffIDs = set()
		if hasattr(csv, 'mimicry') and hasattr(csv.mimicry, 'buffs'):
			for bid in csv.mimicry.buffs:
				validBuffIDs.add(bid)

		buffSet = set(self.buffs or [])
		addedBuffs = []
		for buffID in newBuffs or []:
			# 验证 buff ID 有效且未拥有
			if buffID in validBuffIDs and buffID not in buffSet:
				buffs = list(self.buffs or [])
				buffs.append(buffID)
				self.buffs = buffs
				buffSet.add(buffID)
				addedBuffs.append(buffID)
		return addedBuffs

	def recordBattle(self, bossID, bossScore, buffScore):
		"""记录战斗结果"""
		self.ensureBossEntry(bossID)
		totalScore = bossScore + buffScore  # 本次得分

		# 累加累计分数
		currentTotal = self.total_scores.get(bossID, 0) + totalScore
		self.total_scores[bossID] = currentTotal

		# 更新历史最高分（单次最高）
		if totalScore > self.history_scores.get(bossID, 0):
			self.history_scores[bossID] = totalScore

		# 更新全局最高分（用于排行榜，使用累计分数）
		if currentTotal > (self.best_score or 0):
			self.best_score = currentTotal
			self.best_boss_id = bossID

	def setBattleCards(self, bossID, cardsByPos):
		"""保存战斗卡牌配置"""
		self.ensureBossEntry(bossID)
		self.battle_cards[bossID] = cardsByPos or {}

	def buildBattleCards(self, bossID, cardCsvIDs, skinIDs):
		"""根据CSV ID构建战斗卡牌
		
		拟态对战规则：可选用图鉴内已解锁的精灵
		验证：检查玩家图鉴是否解锁了对应的精灵（同markID+同megaIndex）
		使用配置表的固定属性，但如果玩家有同系列卡牌则用于属性计算
		"""
		self.ensureBossEntry(bossID)
		cardCsvIDs = cardCsvIDs or {}
		skinIDs = skinIDs or {}
		result = {}
		usedMarkIDMega = set()  # 防止同系列重复使用
		usedCardDBIDs = set()  # 防止同一张卡牌重复使用

		# 获取玩家图鉴数据
		pokedex = self.game.role.pokedex or {}

		for pos in range(1, 7):
			csvID = cardCsvIDs.get(pos)
			if not csvID:
				continue

			# 从拟态卡牌配置获取原始卡牌ID
			try:
				mimicryCardCfg = csv.mimicry.cards[int(csvID)]
			except KeyError:
				raise ClientError('mimicry card config error')

			cardID = mimicryCardCfg.cardID
			if cardID not in csv.cards:
				raise ClientError('card config error')

			cardCfg = csv.cards[cardID]
			markID = cardCfg.cardMarkID
			megaIndex = getattr(cardCfg, 'megaIndex', 0) or 0

			# 检查图鉴是否解锁了同系列同mega分支的精灵
			# 前端逻辑：遍历同markID下所有卡牌，检查是否有同megaIndex的卡牌在图鉴里解锁
			inPokedex = False
			for pokedexCardID in pokedex:
				if pokedexCardID not in csv.cards:
					continue
				pokedexCardCfg = csv.cards[pokedexCardID]
				pokedexMarkID = pokedexCardCfg.cardMarkID
				pokedexMegaIndex = getattr(pokedexCardCfg, 'megaIndex', 0) or 0
				if pokedexMarkID == markID and pokedexMegaIndex == megaIndex:
					inPokedex = True
					break

			if not inPokedex:
				logger.warning('mimicry buildBattleCards: pokedex not unlocked for cardID=%s markID=%s megaIndex=%s (mimicry csvID=%s)', 
							   cardID, markID, megaIndex, csvID)
				raise ClientError('pokedex not unlocked')

			# 防止同系列重复布阵
			markMegaKey = (markID, megaIndex)
			if markMegaKey in usedMarkIDMega:
				raise ClientError('duplicate card series')
			usedMarkIDMega.add(markMegaKey)

			# 尝试找玩家拥有的同系列卡牌（用于属性计算）
			# 规则：Z觉醒等级会读取同系列中战力最高的精灵
			cardDBID = None
			candidates = self.game.cards.getCardsByMarkID(markID)
			if candidates:
				# 过滤同 megaIndex 且未被使用的
				validCandidates = []
				for c in candidates:
					cMegaIndex = getattr(csv.cards[c.card_id], 'megaIndex', 0) or 0
					if cMegaIndex == megaIndex and c.id not in usedCardDBIDs:
						validCandidates.append(c)
				# 按战力排序，选最强的
				if validCandidates:
					validCandidates.sort(key=lambda x: x.fighting_point, reverse=True)
					cardDBID = validCandidates[0].id
					usedCardDBIDs.add(cardDBID)

			# 构建卡牌信息
			# skinIDs 格式是 {card_id: skin_id}，不是 {pos: skin_id}
			# 从配置表获取基础属性
			baseStar = getattr(mimicryCardCfg, 'star', 8) or 8  # 配置表基础星级（默认8星保底）
			advance = getattr(mimicryCardCfg, 'advance', 17) or 17
			level = getattr(mimicryCardCfg, 'level', 100) or 100
			
			# 计算战力和星级
			# 星级规则：低于8星按8星算，8星以上按玩家实际星级
			fightingPoint = 0
			star = baseStar
			if cardDBID:
				playerCard = self.game.cards.getCard(cardDBID)
				if playerCard:
					fightingPoint = playerCard.fighting_point
					star = max(playerCard.star, baseStar)  # 取玩家星级和基础星级的较大值
			if fightingPoint == 0:
				# 玩家没有实际卡牌时，使用假卡牌计算战力（与其他模式一致）
				from game.object.game.card import ObjectCard
				from game.object.game.robot import setRobotCard
				fakeCard = ObjectCard(None, None)
				fakeCard.new_deepcopy()
				skillLevels = getattr(mimicryCardCfg, 'skillLevels', None) or [100] * 10
				setRobotCard(fakeCard, cardID, advance, star, level, skillLevels=skillLevels)
				fakeModel = fakeCard.battleModel(False, False, None)
				fightingPoint = ObjectCard.calcFightingPoint(fakeCard, fakeModel.get('attrs', {}))
			
			result[pos] = {
				'card_id': cardID,
				'card_db_id': cardDBID,  # 可能为 None（玩家没有这张卡但图鉴解锁了）
				'skin_id': skinIDs.get(cardID, 0),
				'csv_id': int(csvID),
				'mark_id': markID,
				'mega_index': megaIndex,
				'star': star,
				'advance': advance,
				'level': level,
				'fighting_point': fightingPoint,
			}

		self.setBattleCards(bossID, result)
		return result

	def refreshBattleTimes(self, today):
		"""刷新每日战斗次数"""
		base = _get_mimicry_base()
		if not base:
			return

		limit = base.battleTimesLimit
		if self.battle_times_last_date != today:
			# 新的一天，增加战斗次数
			dailyAdd = base.battleTimesDailyAdd
			newTimes = min(limit, (self.battle_times or 0) + dailyAdd)
			self.battle_times = newTimes
			self.battle_times_last_date = today

	def consumeBattleTimes(self, times=1):
		"""消耗战斗次数"""
		if (self.battle_times or 0) < times:
			raise ClientError('mimicry battle times limit')
		self.battle_times = (self.battle_times or 0) - times


class ObjectMimicryGlobal(ObjectDBase):
	"""拟态对战全局数据（活动状态）"""
	DBModel = 'MimicryGlobal'

	version = db_property('version')
	round = db_property('round')  # 'start', 'closed', 'prepare'
	start_date = db_property('start_date')
	end_date = db_property('end_date')
	bosses = db_property('bosses')  # {bossID: limitID}

	def init(self):
		ObjectDBase.init(self)
		if self.bosses is None:
			self.bosses = {}
		return self

	def setRoundInfo(self, roundName, startDate=None, endDate=None, bosses=None):
		"""设置活动状态"""
		self.round = roundName
		if startDate is not None:
			self.start_date = startDate
		if endDate is not None:
			self.end_date = endDate
		if bosses is not None:
			self.bosses = bosses
