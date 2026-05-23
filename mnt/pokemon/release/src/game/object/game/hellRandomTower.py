#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

无尽随机塔（Hell Random Tower）- 以太乐园无尽模式
'''
import copy
import random
from collections import defaultdict

from framework import todayinclock5date2int, int2date, OneDay, date2int, str2num_t, nowdatetime_t
from framework.csv import csv, ConstDefs, MergeServ
from framework.helper import WeightRandomObject
from framework.distributed.helper import node_key2domains
from framework.log import logger
from framework.object import ObjectDBase, ObjectNoGCDBase, db_property
from game import ClientError
from game.session import Session
from game.object import RandomTowerDefs, AttrDefs, TargetDefs, YYHuoDongDefs, SceneDefs
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.card import CardSlim, ObjectCard
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from game.object.game.yyhuodong import ObjectYYHuoDongFactory


#
# ObjectHellRandomTowerGlobal
#
class ObjectHellRandomTowerGlobal(ObjectNoGCDBase):
	'''
	无尽随机塔全局管理对象（控制开启状态和主题轮换）
	'''
	DBModel = 'ServerGlobalRecord'
	Singleton = None

	def __init__(self, dbc):
		ObjectDBase.__init__(self, None, dbc)
		if ObjectHellRandomTowerGlobal.Singleton is not None:
			raise ValueError('This is singleton object')
		ObjectHellRandomTowerGlobal.Singleton = self

	def init(self):
		return ObjectDBase.init(self)

	@classmethod
	def isOpen(cls):
		"""
		判断无尽随机塔是否开启
		根据 cross/crontab.lua 的 service = "crosshellrandomtower" 配置
		"""
		# 获取服务器key
		key = MergeServ.getSrcServKeys(Session.server.key)[0]
		domains = node_key2domains(key)
		serverKey, serverIdx = domains[1], int(domains[2])
		fullKey = '%s.%s.%d' % (domains[0], serverKey, serverIdx)
		logger.info('[HellRandomTower] Checking isOpen: fullKey=%s, serverKey=%s', fullKey, serverKey)
		
		# 查找匹配的 crontab 配置
		today = todayinclock5date2int()
		for cronID in csv.cross.crontab:
			cfg = csv.cross.crontab[cronID]
			if cfg.service != 'crosshellrandomtower':
				continue
			
			# 检查服务器
			servers = getattr(cfg, 'servers', None)
			cross = getattr(cfg, 'cross', None)
			if servers:
				if fullKey not in servers:
					logger.debug('[HellRandomTower] cronID %d: servers not match, fullKey=%s, servers=%s', cronID, fullKey, servers)
					continue
			else:
				# 没有配置 servers，检查 cross
				if cross and cross != serverKey:
					logger.debug('[HellRandomTower] cronID %d: cross not match, serverKey=%s, cross=%s', cronID, serverKey, cross)
					continue
			
			# 检查日期范围
			startDate = cfg.date  # 开始日期，如 20241108
			if hasattr(cfg, 'endDate') and cfg.endDate:
				endDate = cfg.endDate  # 如果配置了 endDate，直接使用
			elif hasattr(cfg, 'durationDay') and cfg.durationDay:
				# 否则用 startDate + durationDay 天计算结束日期
				import datetime
				startDateObj = int2date(startDate)
				endDateObj = startDateObj + datetime.timedelta(days=cfg.durationDay)
				endDate = date2int(endDateObj)
			else:
				endDate = startDate  # 没有配置，默认只有1天
			
			logger.info('[HellRandomTower] cronID %d matched: startDate=%d, endDate=%d, today=%d, version=%s', 
						cronID, startDate, endDate, today, getattr(cfg, 'version', 1))
			
			if startDate <= today <= endDate:
				return True
		
		return False

	@classmethod
	def getCurrentTheme(cls):
		"""
		获取当前主题ID（从 crontab.version 读取）
		"""
		# 获取服务器key
		key = MergeServ.getSrcServKeys(Session.server.key)[0]
		domains = node_key2domains(key)
		serverKey, serverIdx = domains[1], int(domains[2])
		fullKey = '%s.%s.%d' % (domains[0], serverKey, serverIdx)
		
		# 查找匹配的 crontab 配置
		today = todayinclock5date2int()
		for cronID in csv.cross.crontab:
			cfg = csv.cross.crontab[cronID]
			if cfg.service != 'crosshellrandomtower':
				continue
			
			# 检查服务器
			if hasattr(cfg, 'servers') and cfg.servers:
				if fullKey not in cfg.servers:
					continue
			else:
				# 没有配置 servers，检查 cross
				if hasattr(cfg, 'cross') and cfg.cross != serverKey:
					continue
			
			# 检查日期范围
			startDate = cfg.date  # 开始日期
			if hasattr(cfg, 'endDate') and cfg.endDate:
				endDate = cfg.endDate
			elif hasattr(cfg, 'durationDay') and cfg.durationDay:
				import datetime
				startDateObj = int2date(startDate)
				endDateObj = startDateObj + datetime.timedelta(days=cfg.durationDay)
				endDate = date2int(endDateObj)
			else:
				endDate = startDate
			
			if startDate <= today <= endDate:
				# version 字段对应 theme
				return getattr(cfg, 'version', 1)
		
		return 1  # 默认主题1


#
# ObjectHellRandomTower
#
class ObjectHellRandomTower(ObjectDBase):
	DBModel = 'HellRandomTower'

	HellRandomTowerBoardMap = {}  # {roomID: [csvIDs]}
	HellRandomTowerMonstersMap = {}  # {group: [cfg]}
	HellRandomTowerEventMap = {}  # {group: [cfg]}
	HellRandomTowerBuffMap = {}  # {group: [cfg]}
	MaxRoom = 0

	@classmethod
	def classInit(cls):
		"""初始化配置数据"""
		cls.MaxRoom = max(csv.hell_random_tower.tower.keys()) if csv.hell_random_tower.tower else 0

		# 卡面分组
		cls.HellRandomTowerBoardMap = {}
		for idx in csv.hell_random_tower.board:
			cfg = csv.hell_random_tower.board[idx]
			csvIDs = cls.HellRandomTowerBoardMap.get(cfg.room, [])
			csvIDs.append(idx)
			cls.HellRandomTowerBoardMap[cfg.room] = csvIDs

		# 怪物分组
		cls.HellRandomTowerMonstersMap = {}
		for i in csv.hell_random_tower.monsters:
			cfg = csv.hell_random_tower.monsters[i]
			csvIDs = cls.HellRandomTowerMonstersMap.get(cfg.group, [])
			csvIDs.append(i)
			cls.HellRandomTowerMonstersMap[cfg.group] = csvIDs

		# 事件分组
		cls.HellRandomTowerEventMap = {}
		for i in csv.hell_random_tower.event:
			cfg = csv.hell_random_tower.event[i]
			csvIDs = cls.HellRandomTowerEventMap.get(cfg.group, [])
			csvIDs.append(i)
			cls.HellRandomTowerEventMap[cfg.group] = csvIDs

		# Buff分组
		cls.HellRandomTowerBuffMap = {}
		for i in csv.hell_random_tower.buffs:
			cfg = csv.hell_random_tower.buffs[i]
			csvIDs = cls.HellRandomTowerBuffMap.get(cfg.group, [])
			csvIDs.append(i)
			cls.HellRandomTowerBuffMap[cfg.group] = csvIDs

	def set(self, dic):
		# 如果没有记录ID，创建一个临时的 db 字典供 ObjectDBase.set() 使用
		if not self.game.role.hell_random_tower_db_id:
			# 从全局管理对象获取当前主题
			logger.info('[HellRandomTower.set] Getting current theme for role %s', self.game.role.id)
			currentTheme = ObjectHellRandomTowerGlobal.getCurrentTheme()
			logger.info('[HellRandomTower.set] Current theme = %d', currentTheme)
			# 创建临时字典（不包含 id，因为不是从数据库加载）
			tempDic = {
				'round': 'closed',
				'theme': currentTheme,
				'date': 0,
				'room': 0,
				'point': 0,
				'reset_times': 0,
				'history_point': 0,
				'day_rank': 0,
				'last_room': {},
				'history_room': {},
				'prepare_cards': [],
				'battle_cards': [],
				'battle_cards_multi': {},
				'battle_result_multi': {},
				'card_states': {},
				'enemy_states': {},
				'enemy_states_multi': {},
				'buffs': [],
				'items': {},
				'boards': {},
				'hidden_boards': [],
				'room_info': {},
				'buff_time': {},
				'event_time': {},
				'skill_used': {},
				'point_award': {},
				'jump_info': {},
				'jump_step': 0,
				'buff_lib': [],
			}
			# 调用父类 set，但传入临时字典
			ObjectDBase.set(self, tempDic)
			return self
		
		# 有记录ID，正常 set
		ObjectDBase.set(self, dic)
		# 初始化默认字段
		if not self.theme or self.theme == 0:
			self.theme = ObjectHellRandomTowerGlobal.getCurrentTheme()
		if not self.point_award:
			self.point_award = {}
		if not self.last_room:
			self.last_room = {}
		if not self.history_room:
			self.history_room = {}
		if not self.battle_cards_multi:
			self.battle_cards_multi = {}
		if not self.battle_result_multi:
			self.battle_result_multi = {}
		if not self.enemy_states_multi:
			self.enemy_states_multi = {}
		if not self.items:
			self.items = {}
		if not self.buffs:
			self.buffs = []
		if not self.buff_time:
			self.buff_time = {}
		if not self.event_time:
			self.event_time = {}
		if not self.skill_used:
			self.skill_used = {}
		if not self.card_states:
			self.card_states = {}
		if not self.enemy_states:
			self.enemy_states = {}
		if not self.boards:
			self.boards = {}
		if not self.room_info:
			self.room_info = {}
		if not self.jump_info:
			self.jump_info = {}
		if not self.prepare_cards:
			self.prepare_cards = []
		if not self.hidden_boards:
			self.hidden_boards = []
		if not self.buff_lib:
			self.buff_lib = []
		return self

	def init(self):
		"""登录时初始化"""
		# 如果没有记录ID，已在 set() 中初始化 db 字典，直接返回
		if not self.game.role.hell_random_tower_db_id:
			return ObjectDBase.init(self)
		
		# 已有记录，正常初始化
		if not self.round:
			self.round = 'closed'
		if not self.theme or self.theme == 0:
			self.theme = ObjectHellRandomTowerGlobal.getCurrentTheme()
		
		# 检查活动是否开启中，根据状态自动设置 round
		logger.info('[HellRandomTower.init] Checking if activity is open for role %s', self.game.role.id)
		activityIsOpen = ObjectHellRandomTowerGlobal.isOpen()
		logger.info('[HellRandomTower.init] Activity isOpen = %s, current round = %s', activityIsOpen, self.round)
		if activityIsOpen:
			# 活动开启中
			if self.round == 'closed':
				# 如果当前是 closed（从未参与过），设置为 prepare（可以参与）
				# 这样前端会认为活动期间，显示剩余时间而不是"XX天后"
				self.round = 'prepare'
				logger.info('[HellRandomTower] Activity is open, set round to prepare')
			elif self.round == 'end':
				# 如果之前结束了，但活动还在，重置为 prepare
				self.round = 'prepare'
		else:
			# 活动未开启，强制结束
			if self.round in ('start', 'prepare'):
				self.round = 'end'
				logger.info('[HellRandomTower] Activity is not open, set round to end')
		
		# 每日刷新检查
		today = todayinclock5date2int()
		if self.date != today:
			self._dailyRefresh(today)
		
		return ObjectDBase.init(self)

	def _dailyRefresh(self, today):
		"""每日刷新"""
		logger.info('[HellRandomTower] Daily refresh for role %s, date %d -> %d', 
					self.game.role.id, self.date, today)
		
		# 结算昨日数据
		if self.date and self.round == 'start':
			# 记录昨日房间和历史最高
			passRoom = self.room - 1
			if self.room_info.get('pass', 0):
				passRoom += 1
			
			theme = self.theme
			if theme:
				# 更新当前主题的昨日房间
				self.last_room[theme] = passRoom
				# 更新当前主题的历史最高
				self.history_room[theme] = max(passRoom, self.history_room.get(theme, 0))
		
		# 重置每日数据
		self.date = today
		self.round = 'closed'
		self.room = 0
		self.boards = {}
		self.hidden_boards = []
		self.room_info = {}
		self.prepare_cards = []
		self.battle_cards = []
		self.battle_cards_multi = {}
		self.battle_result_multi = {}
		self.card_states = {}
		self.enemy_states = {}
		self.enemy_states_multi = {}
		self.buffs = []
		self.items = {}
		self.point = 0
		self.day_rank = 0
		self.reset_times = 0
		self.buff_lib = []
		self.buff_time = {}
		self.event_time = {}
		self.skill_used = {}
		self.jump_info = {}
		self.jump_step = RandomTowerDefs.JumpBegin

	# 基础字段定义
	date = db_property('date')
	theme = db_property('theme')
	round = db_property('round')
	last_room = db_property('last_room')  # {theme: roomID}
	history_room = db_property('history_room')  # {theme: roomID}
	
	# 当前房间ID
	def room():
		dbkey = 'room'
		def fset(self, value):
			old = self.db.get(dbkey, 0)
			self.db[dbkey] = value
			if value > old:
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HellRandomTowerTimes, value - old)
		return locals()
	room = db_property(**room())
	
	boards = db_property('boards')
	hidden_boards = db_property('hidden_boards')
	room_info = db_property('room_info')
	prepare_cards = db_property('prepare_cards')
	battle_cards = db_property('battle_cards')
	battle_cards_multi = db_property('battle_cards_multi')
	battle_result_multi = db_property('battle_result_multi')
	card_states = db_property('card_states')
	enemy_states = db_property('enemy_states')
	enemy_states_multi = db_property('enemy_states_multi')
	buffs = db_property('buffs')
	items = db_property('items')
	
	# 积分
	def point():
		dbkey = 'point'
		def fset(self, value):
			old = self.db.get(dbkey, 0)
			self.db[dbkey] = value
			if value > old:
				self.calPointAward()
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HellRandomTowerPoint, value - old)
		return locals()
	point = db_property(**point())
	
	history_point = db_property('history_point')
	day_rank = db_property('day_rank')
	reset_times = db_property('reset_times')
	buff_lib = db_property('buff_lib')
	buff_time = db_property('buff_time')
	event_time = db_property('event_time')
	skill_used = db_property('skill_used')
	point_award = db_property('point_award')
	jump_info = db_property('jump_info')
	jump_step = db_property('jump_step')

	def setRoomBoards(self, roomID):
		'''设置房间的所有卡面'''
		cfg = csv.hell_random_tower.tower[roomID] if roomID in csv.hell_random_tower.tower else None
		if not cfg:
			return
		
		boards = []
		if cfg.boards:
			groupList = [cfg.limit1, cfg.limit2, cfg.limit3]
			csvBoard = csv.hell_random_tower.board

			# 随卡面的个数
			randobj = WeightRandomObject(cfg.boards)
			boardNum, _ = randobj.getRandom()
			# {roomID: [csvIDs]}
			boardCsvIDs = copy.copy(self.HellRandomTowerBoardMap.get(roomID, []))
			# 先处理必选的情况（权值为 -1）
			for csvID in self.HellRandomTowerBoardMap.get(roomID, []):
				if boardNum < 1:
					break
				if csvBoard[csvID]['weight'] == -1:
					boardCsvIDs.remove(csvID)
					group = csvBoard[csvID]['group']
					if groupList[group-1] >= 1:
						boards.append(csvID)
						boardNum -= 1
						groupList[group-1] -= 1
			if boardNum:
				# 根据权值随机
				weights = {}
				for boardCsvID in boardCsvIDs:
					if csvBoard[boardCsvID]['weight'] != -1 and groupList[csvBoard[boardCsvID]['group']-1] >= 1:
						weights[boardCsvID] = csvBoard[boardCsvID]['weight']
				for i in xrange(boardNum):
					if weights:
						randobj = WeightRandomObject(weights)
						boardCsvID, _ = randobj.getRandom()
						boards.append(boardCsvID)
						weights.pop(boardCsvID)
						group = csvBoard[boardCsvID]['group']
						groupList[group - 1] -= 1
						if groupList[group - 1] <= 0:
							weightsCopy = copy.copy(weights)
							for csvID in weightsCopy:
								if csvBoard[csvID]['group'] == group:
									weights.pop(csvID)
		self.boards.setdefault(roomID, boards)

	def isRightChoose(self, boardID):
		'''选择卡面是否正确'''
		curRoomBoards = self.boards.get(self.room, [])
		if boardID not in curRoomBoards:
			return False
		idx = curRoomBoards.index(boardID) + 1
		low, high = self.room_info.get('next_room_scope', (-1, 99999))
		if low <= idx <= high:
			return True
		return False

	def setNextRoomScope(self):
		'''设置房间可选择卡面范围'''
		curRoomBoards = self.boards.get(self.room, [])
		nextRoomBoards = self.boards.get(self.room + 1, [])
		if len(curRoomBoards) <= 1 or len(nextRoomBoards) <= 1:
			self.room_info['next_room_scope'] = (-1, 99999)
		else:
			boardID = self.room_info.get('board_id', 0)
			st = (len(nextRoomBoards) - len(curRoomBoards))/float(2)
			self.room_info['next_room_scope'] = (curRoomBoards.index(boardID)+st, curRoomBoards.index(boardID)+st+2)

	def nextRoom(self):
		'''进入下个房间'''
		passfloor = csv.hell_random_tower.tower[self.room].floor
		if self.room == ObjectHellRandomTower.MaxRoom:
			self.room_info.setdefault('pass', 1)
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HellRandomTowerFloorTimes, 1)
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HellRandomTowerFloorSum, passfloor)
		else:
			# 删除当前房间
			self.boards.pop(self.room, None)
			# 清空上房间的数据
			self.enemy_states = {}
			self.room_info = {'next_room_scope': list(self.room_info.get('next_room_scope', (-1, 99999)))}
			self.room += 1
			# 下个房间塞怪物和事件
			self.setEnermyToRoom()
			self.setEventToRoom()
			self.setBuffToRoom()
			if self.room + 2 <= ObjectHellRandomTower.MaxRoom:
				# 添加下一间
				self.setRoomBoards(self.room + 2)
			floor = csv.hell_random_tower.tower[self.room].floor
			if passfloor != floor:
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HellRandomTowerFloorTimes, 1)
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HellRandomTowerFloorSum, passfloor)

	def randomEnemyCards(self, boardID):
		'''随机怪物卡牌'''
		cfgBoard = csv.hell_random_tower.board[boardID]
		csvLevel = csv.hell_random_tower.monster_level
		csvMonsters = csv.hell_random_tower.monsters
		cfgTower = csv.hell_random_tower.tower[cfgBoard.room]
		historyFight = self.game.role.top6_fighting_point
		index = cfgBoard.monsterType-1
		baseFight = int(max(cfgTower['lowestFight'][index], historyFight) * cfgTower['fightC'][index] * cfgBoard.fightC)
		
		# 确定等级
		cfgLevel = None
		for i in csvLevel:
			cfg = csvLevel[i]
			if cfg['fightStart'] <= baseFight <= cfg['fightEnd']:
				cfgLevel = cfg
				break
		
		if not cfgLevel:
			# 如果没找到，使用最高等级配置
			cfgLevel = csvLevel[max(csvLevel.keys())]
		
		# 随机怪物序列
		weights = {}
		monstersCsvIDs = self.HellRandomTowerMonstersMap.get(cfgBoard['monster'], [])
		for i in monstersCsvIDs:
			cfg = csvMonsters[i]
			if cfg['levelStart'] <= cfgLevel['level'] <= cfg['levelEnd']:
				weights.setdefault(i, cfg['weight'])
		
		if not weights:
			raise ClientError('no monsters available')
		
		randobj = WeightRandomObject(weights)
		monstersCsvID, _ = randobj.getRandom()
		
		# 返回怪物卡牌
		ret = {'fighting_point': baseFight, 'id': monstersCsvID, 'skill_level': cfgLevel['skillLevel']}
		ret['monsters'] = []
		for index, card_id in enumerate(csvMonsters[monstersCsvID]['monsters']):
			if card_id == 0:
				ret['monsters'].append(None)
			else:
				skills = defaultdict(dict)
				for skillID in csv.cards[card_id].skillList:
					skills[skillID] = cfgLevel['skillLevel']
				ret['monsters'].append({
					'id': index+1,
					'unit_id': csv.cards[card_id].unitID,
					'card_id': card_id,
					'level': cfgLevel['level'],
					'advance': random.randint(cfgLevel['advanceStart'], cfgLevel['advanceEnd']),
					'star': random.randint(cfgLevel['starStart'], cfgLevel['starEnd']),
					'skills': skills,
					'skin_id': 0
				})
		# 计算怪物属性
		self.updateEnemyAttrs(ret)
		return ret

	def updateEnemyAttrs(self, enemy):
		'''更新怪物卡牌属性'''
		cardNum = 0
		fightPoint = 0
		for k, monster in enumerate(enemy['monsters']):
			if monster and 'attrs' not in monster:
				card = CardSlim(monster)
				attrs = ObjectCard.calcAttrs(card)
				fightingPoint = ObjectCard.calcFightingPoint(card, attrs)
				fightPoint += fightingPoint
				monster['fighting_point'] = fightingPoint
				monster['attrs'] = attrs
				cardNum += 1

		# 战力差 = 基准战力 - 实际总战力
		subFight = enemy['fighting_point'] - fightPoint
		if subFight <= 0:
			return

		hpWeight = 9.6
		attackWeight = 1.2
		defenceWeight = 1
		attackSpecialWeight = 1.2
		defenceSpecialWeight = 1
		speedWeight = 0.1
		# 根据战力差 修正属性
		cfgFight = csv.fighting_weight[1]
		l_fight = hpWeight*cfgFight.hp + attackWeight*cfgFight.damage + defenceWeight*cfgFight.defence + attackSpecialWeight*cfgFight.specialDamage + defenceSpecialWeight*cfgFight.specialDefence + speedWeight*cfgFight.speed
		once_rate = subFight*1.0 / l_fight / cardNum
		realFightingPoint = 0
		for k, monster in enumerate(enemy['monsters']):
			if monster:
				attrs = enemy['monsters'][k]['attrs']
				attrs['hp'] += once_rate*hpWeight
				attrs['damage'] += once_rate*attackWeight
				attrs['defence'] += once_rate*defenceWeight
				attrs['speed'] += once_rate * speedWeight
				attrs['specialDamage'] += once_rate * attackSpecialWeight
				attrs['specialDefence'] += once_rate * defenceSpecialWeight
				card = CardSlim(monster)
				realFightingPoint += ObjectCard.calcFightingPoint(card, attrs)
		enemy['fighting_point'] = realFightingPoint

	def setEnermyToRoom(self):
		'''将怪物塞入当前房间'''
		curRoomBoards = self.boards.get(self.room, [])
		monsterCards = {}
		for boardID in curRoomBoards:
			if csv.hell_random_tower.board[boardID]['type'] == RandomTowerDefs.MonsterType:
				monsterCards[boardID] = self.randomEnemyCards(boardID)
		self.room_info['enemy'] = monsterCards

	def isCardDead(self, cardID):
		'''判断卡牌是否死亡'''
		if cardID in self.card_states and self.card_states[cardID][0] <= 0:
			return True
		return False

	def hasDeadCard(self, battleCardIDs):
		'''判断阵容中是否有死亡'''
		for v in battleCardIDs:
			if v and self.isCardDead(v):
				return True
		return False

	def statesHasDeadCard(self):
		'''判断以太卡牌是否有死亡'''
		for cardID, v in self.card_states.iteritems():
			hp, mp = v
			card = self.game.cards.getCard(cardID)
			if card and card.level >= 10:
				if hp <= 0:
					return True
		return False

	def setEnemyState(self, cardID, rawT):
		'''更新怪物卡牌生命怒气'''
		hp, mp = rawT
		cardID = str(cardID)
		self.enemy_states[cardID] = (min(hp, 1), min(mp, 1))

	def setCardState(self, cardID, rawT):
		'''更新自身卡牌生命怒气'''
		hp, mp = rawT
		self.card_states[cardID] = (min(hp, 1), min(mp, 1))

	def randomEvent(self, boardID):
		'''随机事件'''
		cfgBoard = csv.hell_random_tower.board[boardID]
		weights = cfgBoard.event
		randobj = WeightRandomObject(weights)
		eventGroup, _ = randobj.getRandom()
		
		eventCsvIDs = copy.copy(self.HellRandomTowerEventMap.get(eventGroup, []))
		for csvID in self.HellRandomTowerEventMap.get(eventGroup, []):
			cfg = csv.hell_random_tower.event[csvID]
			if cfg.onlyOne:
				if self.event_time.get(csvID, 0):
					eventCsvIDs.remove(csvID)
			else:
				if self.event_time.get(csvID, 0) + 1 > cfg.limit:
					eventCsvIDs.remove(csvID)

		if not eventCsvIDs:
			return 0
		eventCsvID = random.choice(eventCsvIDs)
		return eventCsvID

	def setEventToRoom(self):
		'''将事件塞入当前房间'''
		curRoomBoards = self.boards.get(self.room, [])
		events = {}
		for boardID in curRoomBoards:
			if csv.hell_random_tower.board[boardID]['type'] == RandomTowerDefs.EventType:
				events[boardID] = self.randomEvent(boardID)
		self.room_info['event'] = events

	def getEventAward(self, cfgEvent, choice='choice1'):
		'''获得随机事件奖励'''
		effAward = ObjectGainAux(self.game, {})
		buffList = []
		points = 0
		num = choice[6:]
		result = cfgEvent.get('result'+num, {})
		for k, v in result.iteritems():
			if k == 'items':
				effAward += ObjectGainAux(self.game, v)
			elif k == 'buff':
				buffList.extend(v)
			elif k == 'points':
				points += v
		return effAward, buffList, points

	def randomBuff(self, boardID):
		'''随机buff'''
		cfgBoard = csv.hell_random_tower.board[boardID]
		weights = cfgBoard.buff
		randobj = WeightRandomObject(weights)
		buffGroup, _ = randobj.getRandom()
		
		buffCsvIDs = copy.copy(self.HellRandomTowerBuffMap.get(buffGroup, []))
		for csvID in self.HellRandomTowerBuffMap.get(buffGroup, []):
			cfg = csv.hell_random_tower.buffs[csvID]
			if cfg.onlyOne:
				if self.buff_time.get(csvID, 0):
					buffCsvIDs.remove(csvID)
			else:
				if self.buff_time.get(csvID, 0) + 1 > cfg.limit:
					buffCsvIDs.remove(csvID)
			if cfg.belongLib != 0 and cfg.belongLib not in self.buff_lib:
				buffCsvIDs.remove(csvID)
		
		if not buffCsvIDs:
			return 0
		
		weights = {}
		for csvID in buffCsvIDs:
			weights[csvID] = csv.hell_random_tower.buffs[csvID]['weight']
		buffRandobj = WeightRandomObject(weights)
		buffCsvID, _ = buffRandobj.getRandom()
		return buffCsvID

	def setBuffToRoom(self):
		'''将buff塞入当前房间'''
		curRoomBoards = self.boards.get(self.room, [])
		buffs = {}
		for boardID in curRoomBoards:
			if csv.hell_random_tower.board[boardID]['type'] == RandomTowerDefs.BuffType:
				buffs[boardID] = self.randomBuff(boardID)
		self.room_info['buff'] = buffs

	def addBuffs(self, buffCsvID):
		'''添加buff'''
		cfg = csv.hell_random_tower.buffs[buffCsvID]
		if cfg.buffType == RandomTowerDefs.BuffSkill and buffCsvID in self.buffs:
			if self.skill_used.get(buffCsvID, 0):
				self.skill_used.pop(buffCsvID)
		else:
			self.buffs.append(buffCsvID)

	def updateSkillUsed(self):
		'''更新被动技能使用次数'''
		buffs = []
		for buffID in self.buffs:
			if csv.hell_random_tower.buffs[buffID]['buffType'] == RandomTowerDefs.BuffSkill:
				self.skill_used[buffID] = self.skill_used.get(buffID, 0) + 1
				if csv.hell_random_tower.buffs[buffID].effectTimes == 0 or self.skill_used.get(buffID, 0) < csv.hell_random_tower.buffs[buffID].effectTimes:
					buffs.append(buffID)
				else:
					self.skill_used.pop(buffID)
			else:
				buffs.append(buffID)
		self.buffs = buffs

	def buffSupply(self, buffID, cards=None):
		'''buff 补给使用'''
		cfg = csv.hell_random_tower.buffs[buffID]
		supplyType = cfg.supplyType
		supplyTarget = cfg.supplyTarget
		supplyNum = cfg.supplyNum

		supplyCards = []
		if supplyTarget == RandomTowerDefs.SupplyTargetOne:
			if not cards:
				if supplyType == RandomTowerDefs.SupplyHp and self.hasHpNotEnoughCard():
					raise ClientError('SupplyHp, cards is None')
				elif supplyType == RandomTowerDefs.SupplyMp and self.hasMpNotEnoughCard():
					raise ClientError('SupplyMp, cards is None')
				elif supplyType == RandomTowerDefs.SupplyRevive and self.statesHasDeadCard():
					raise ClientError('SupplyRevive, cards is None')
			else:
				supplyCards = cards if isinstance(cards, list) else [cards]
			for cardID in supplyCards:
				card = self.game.cards.getCard(cardID)
				if card and card.level < 10:
					raise ClientError('card level error')
		elif supplyTarget == RandomTowerDefs.SupplyTargetBattle:
			supplyCards = self.battle_cards or []
		else:
			for card in self.game.cards.getAllCards().values():
				if card.level >= 10:
					supplyCards.append(card.id)

		for cardID in supplyCards:
			if cardID:
				if not self.isCardDead(cardID) and supplyType != RandomTowerDefs.SupplyRevive:
					hp, mp = self.card_states.get(cardID, (1, 0))
					if supplyType == RandomTowerDefs.SupplyHp:
						self.card_states[cardID] = (min(hp+supplyNum/float(100), 1), mp)
					elif supplyType == RandomTowerDefs.SupplyMp:
						self.card_states[cardID] = (hp, min(mp+supplyNum/float(100), 1))
					elif supplyType == RandomTowerDefs.SupplyCutHp:
						self.card_states[cardID] = (hp-hp*(supplyNum/float(100)), mp)
					elif supplyType == RandomTowerDefs.SupplyCutMp:
						self.card_states[cardID] = (hp, max(mp-supplyNum/float(100), 0))
				if self.isCardDead(cardID) and supplyType == RandomTowerDefs.SupplyRevive:
					_, mp = self.card_states.get(cardID, (1, 0))
					self.card_states[cardID] = (1, mp)

	def isBuffCondition(self, buffID):
		'''是否符合buff前置条件'''
		cfg = csv.hell_random_tower.buffs[buffID]
		if not cfg.condition:
			return True
		if cfg.condition == RandomTowerDefs.BuffCardDead:
			return self.statesHasDeadCard()
		elif cfg.condition == RandomTowerDefs.BuffCardHp:
			return self.hasHpNotEnoughCard()
		elif cfg.condition == RandomTowerDefs.BuffCardMp:
			return self.hasMpNotEnoughCard()
		return False

	def hasHpNotEnoughCard(self):
		'''是否有血量不满的卡牌'''
		for cardID, state in self.card_states.iteritems():
			card = self.game.cards.getCard(cardID)
			if card and card.level >= 10:
				if 0 < state[0] < 1:
					return True
		return False

	def hasMpNotEnoughCard(self):
		'''是否有怒气不满的卡牌'''
		if not self.card_states:
			return True
		for cardID, state in self.card_states.iteritems():
			card = self.game.cards.getCard(cardID)
			if card and card.level >= 10:
				if state[0] > 0 and state[1] < 1:
					return True
		return False

	def passResumeMp(self, monfloors):
		'''碾压：战力前10 获得200怒气'''
		allCards = self.game.cards.getAllCards()
		points = allCards.values()
		points.sort(key=lambda o: o.fighting_point, reverse=True)
		count = 0
		for card in points:
			if card.level < 10:
				continue
			if not self.isCardDead(card.id):
				if card.id not in self.card_states:
					self.card_states[card.id] = (1, min(1, monfloors * 200.0 / card.csvAttrs['mp1']))
				else:
					states = self.card_states[card.id]
					self.card_states[card.id] = (states[0], min(1, states[1] + monfloors * 200.0 / card.csvAttrs['mp1']))
				count += 1
				if count >= 10:
					break

	def getBoxAwards(self, boardID):
		'''领取宝箱奖励'''
		cfg = csv.hell_random_tower.board[boardID]
		eff = ObjectGainAux(self.game, {})
		count = self.room_info.get('count', 0)
		if count == 0:
			eff += self.getFirstBoxAwards(boardID)
		else:
			if cfg.boxType == RandomTowerDefs.CommonType:
				costRMB = ObjectCostCSV.getRandomTowerBoxCost1(count)
			else:
				costRMB = ObjectCostCSV.getRandomTowerBoxCost2(count)
			cost = ObjectCostAux(self.game, {'rmb': costRMB})
			if not cost.isEnough():
				raise ClientError('cost rmb no enough')
			cost.cost(src='hell_random_tower_box_award')
			eff += ObjectGainAux(self.game, cfg['randomLibs2'])

		self.room_info['count'] = count + 1
		return eff

	def getFirstBoxAwards(self, boardID):
		'''打开首次宝箱'''
		cfg = csv.hell_random_tower.board[boardID]
		eff = ObjectGainAux(self.game, {})
		eff += ObjectGainAux(self.game, {'gold': cfg.gold, 'coin2': cfg.coin})
		eff += ObjectGainAux(self.game, cfg['randomLibs'])
		return eff

	def calPointAward(self):
		'''计算积分奖励'''
		theme = self.theme
		if not theme or theme not in csv.hell_random_tower.theme:
			return
		
		themeCfg = csv.hell_random_tower.theme[theme]
		pointAwardCfg = themeCfg.pointAward
		if not pointAwardCfg:
			return
		
		for awardID in pointAwardCfg:
			if awardID not in csv.hell_random_tower.point_award:
				continue
			cfg = csv.hell_random_tower.point_award[awardID]
			if self.point >= cfg.needPoint:
				if self.point_award.get(awardID, -1) == -1:
					self.point_award[awardID] = 1

	def getCardsAttr(self, cardIDs):
		'''获取卡牌的属性（加成后）'''
		attrsD = {}  # {attr: (const, percent)}
		for buffID in self.buffs:
			cfg = csv.hell_random_tower.buffs[buffID]
			if cfg.buffType == RandomTowerDefs.BuffAttrAdd:
				for i in xrange(1, 99):
					attrType = "attrType%d" % i
					if attrType not in cfg or not cfg[attrType]:
						break
					attrNum = "attrNum%d" % i
					num = str2num_t(cfg[attrNum])
					const, percent = attrsD.get(AttrDefs.attrsEnum[cfg[attrType]], (0.0, 0.0))
					const += num[0]
					percent += num[1]
					attrsD[AttrDefs.attrsEnum[cfg[attrType]]] = (const, percent)

		cardsAttr, cardsAttr2 = self.game.cards.makeBattleCardModel(cardIDs, SceneDefs.HellRandomTower)
		for cardID, cardAttr in cardsAttr.iteritems():
			card = self.game.cards.getCard(cardID)
			attrs = cardAttr.setdefault('attrs', {})
			for attr, value in attrsD.iteritems():
				const, percent = value
				attrValue = attrs.get(attr, 0.0)
				if const:
					attrValue += const
				if percent:
					attrValue = attrValue * (1 + percent)
				attrs[attr] = attrValue
			cardAttr['fighting_point'] = ObjectCard.calcFightingPoint(card, attrs)

		for cardID, cardAttr in cardsAttr2.iteritems():
			card = self.game.cards.getCard(cardID)
			attrs = cardAttr.setdefault('attrs', {})
			for attr, value in attrsD.iteritems():
				const, percent = value
				attrValue = attrs.get(attr, 0.0)
				if const:
					attrValue += const
				if percent:
					attrValue = attrValue * (1 + percent)
				attrs[attr] = attrValue
			cardAttr['fighting_point'] = ObjectCard.calcFightingPoint(card, attrs)

		return cardsAttr, cardsAttr2

	def getBuffPointAdd(self, battleRound, aliveCount):
		'''打怪获取积分加成'''
		point = 0
		for buffID in self.buffs:
			cfg = csv.hell_random_tower.buffs[buffID]
			if cfg.buffType == RandomTowerDefs.BuffPointAdd:
				if cfg.pointType == RandomTowerDefs.PointRoundType:
					point = (10 - battleRound) * cfg.pointValue
				elif cfg.pointType == RandomTowerDefs.PointAliveType:
					point = aliveCount * cfg.pointValue
				elif cfg.pointType == RandomTowerDefs.PointFloorType:
					floor = csv.hell_random_tower.tower[self.room].floor
					point = floor * cfg.pointValue
		return point

	# TODO: 其他业务方法根据前端接口需求继续添加
	# - 预备阶段相关
	# - 开始挑战
	# - 跳关相关
	# - 道具使用
	# - 重置功能
	# 等等...
