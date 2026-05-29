#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
============================================================================
跨服卡牌对决 (Cross Auto Chess) - 跨服状态管理
============================================================================

参考: cross_arena.py, cross_fishing.py
PVP玩家数据存储在 AutoChess 文档中（auto_chess.py），本文件只管理跨服全局状态。
'''

import binascii

from framework.log import logger
from framework.csv import csv, MergeServ
from framework.object import ObjectNoGCDBase, db_property
from game.object.game.servrecord import ObjectServerGlobalRecord

from tornado.gen import coroutine, Return


#
# ObjectCrossAutoChessGameGlobal - 跨服全局状态管理
#
class ObjectCrossAutoChessGameGlobal(ObjectNoGCDBase):
	DBModel = 'CrossAutoChessGameGlobal'

	Singleton = None

	GlobalObjsMap = {}  # {areakey: ObjectCrossAutoChessGameGlobal}
	GlobalHalfPeriodObjsMap = {}  # {areakey: ObjectCrossAutoChessGameGlobal}

	@classmethod
	def classInit(cls):
		pass

	@classmethod
	def getByAreaKey(cls, key):
		# 参考 cross_arena.py / cross_fishing.py
		return cls.GlobalHalfPeriodObjsMap.get(key, cls.Singleton)

	def __init__(self, dbc):
		ObjectNoGCDBase.__init__(self, None, dbc)

	def set(self, dic):
		ObjectNoGCDBase.set(self, dic)
		self.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_auto_chess', self.key)
		return self

	def init(self, server, crossData):
		self.server = server
		self._cross = {}

		self.initCrossData(crossData)

		cls = ObjectCrossAutoChessGameGlobal
		cls.GlobalObjsMap[self.key] = self
		# global对象 key与当前服key对应
		if self.key == self.server.key:
			cls.Singleton = self

		# 是在半周期的话
		if self.isHalfPeriod:
			srcServs = MergeServ.getSrcServKeys(self.key)
			for srcServ in srcServs:
				cls.GlobalHalfPeriodObjsMap[srcServ] = self

		return self

	# key
	key = db_property('key')

	# 跨服server key
	cross_key = db_property('cross_key')

	# 赛季状态 (start/closed)
	round = db_property('round')

	# 上期排名
	last_ranks = db_property('last_ranks')

	# 上期匹配区服
	last_servers = db_property('last_servers')

	@property
	def servers(self):
		return self._cross.get('servers', [])

	@property
	def date(self):
		return self._cross.get('date', 0)

	@property
	def end_date(self):
		return self._cross.get('end_date', 0)

	@property
	def season(self):
		return self._cross.get('season', 1)

	@classmethod
	def isOpen(cls, areaKey):
		'''
		是否开启玩法
		'''
		self = cls.getByAreaKey(areaKey)
		if self.cross_key == '' or self.round == "closed":
			return False
		return True

	@classmethod
	def getRound(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.round

	@classmethod
	def getCrossKey(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.cross_key

	@classmethod
	def getDate(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.date

	@classmethod
	def getEndDate(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.end_date

	@classmethod
	def getGameKey(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.key

	@classmethod
	def getSeason(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		return self.season

	@classmethod
	def isRoleInBattle(cls, role):
		'''
		检查玩家是否在在线自走棋战斗中
		通过检查 auto_chess.online.room_address 是否有值判断
		'''
		try:
			auto_chess = role.game.auto_chess
			if auto_chess is None:
				return False
			online = auto_chess.online
			if online is None:
				return False
			room_address = online.get('room_address', '')
			return bool(room_address)
		except Exception:
			return False

	@classmethod
	@coroutine
	def onCrossEvent(cls, event, key, data, sync):
		'''
		玩法流程
		'''
		logger.info('ObjectCrossAutoChessGameGlobal.onCrossEvent %s %s', key, event)

		self = cls.getByAreaKey(key)
		if sync:
			self.round = sync['round']

		ret = {}
		if event == 'start':
			self.initCrossData(data.get('model', {}))
			self.onStart()

		elif event == 'closed':
			self.onClosed(key)

		elif event == 'save_rank':
			# onClosed 合服后存在重入情况延后一步调用 reset 清理 cross_key
			self.reset()
			self.onSaveRank(data.get('servers', []), data.get('allRanks', []))

		elif event == 'rank_award':
			# 赛季排行榜奖励
			pveRanks = data.get('pve_ranks', [])
			trainerRanks = data.get('trainer_ranks', {})
			self.onPveRankAward(pveRanks)
			self.onTrainerRankAward(trainerRanks)
			# Type 45 勋章需要同时判断总榜和分榜
			self.onAutoChessRankMedal(pveRanks, trainerRanks)

		elif event == 'match_discard':
			# 匹配超时，清除玩家匹配状态
			discards = data.get('discards', [])
			yield cls.onMatchDiscard(discards)

		elif event == 'match_complete':
			# 匹配成功，通知玩家进入房间
			yield cls.onMatchComplete(data)

		elif event == 'game_end':
			# 对局结束，更新玩家 Type 58 连胜字段
			yield cls.onGameEnd(data)

		raise Return(ret)

	# 初始化
	def initCrossData(self, crossData):
		# 参考 cross_arena.py / cross_fishing.py
		# cross_key 在 onCrossCommit 中设置，这里只设置 round
		self._cross = crossData
		if crossData:
			self.round = self._cross.get('round', 'closed')
			logger.info('Cross auto_chess Init %s %s %s', self.cross_key, self.date, self.round)
		else:
			self.reset()

	# 赛季开始
	def onStart(self):
		logger.info('ObjectCrossAutoChessGameGlobal.onStart')
		self.round = 'start'
		self.last_ranks = []

	def onSaveRank(self, servers, allRanks):
		self.last_servers = servers
		self.last_ranks = allRanks

	# 赛季PVE排行榜奖励（参考拟态实现）
	def onPveRankAward(self, pveRanks):
		import bisect
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		from game.object.game import ObjectGame
		from game.globaldata import AutoChessRankAwardMailID
		from game.handler.inl_mail import updateMedalCounterForRank

		# 防重复发放检查：使用活动结束日期作为标识
		endDate = getattr(self, 'end_date', 0) or 0
		lastAwardDate = getattr(self, 'last_pve_award_date', 0) or 0
		if endDate > 0 and lastAwardDate == endDate:
			logger.warning('ObjectCrossAutoChessGameGlobal.onPveRankAward already awarded for endDate=%s, skip!', endDate)
			return
		
		# 记录发奖日期（先记录再发奖，防止中途崩溃后重复发放）
		if endDate > 0:
			self.last_pve_award_date = endDate
			logger.info('ObjectCrossAutoChessGameGlobal.onPveRankAward set last_pve_award_date=%s', endDate)

		ranks = {item['role_id']: item['rank'] for item in pveRanks if item.get('role_id') and item.get('rank', 0) > 0}
		
		# 勋章计数：卡牌对决排名 (Type 57, medalID 1651, 前50名)
		for roleID, rank in ranks.iteritems():
			updateMedalCounterForRank(self._dbc, ObjectGame.getByRoleID, roleID, 1651, 50, rank)

		logger.info('ObjectCrossAutoChessGameGlobal.onPveRankAward sending %s mails', len(ranks))

		# 构建配置表查询：type=0 或空 表示总榜
		cfgs = []
		cfgRanks = []
		if hasattr(csv, 'auto_chess') and hasattr(csv.auto_chess, 'rank_award'):
			for idx in sorted(csv.auto_chess.rank_award.keys()):
				cfg = csv.auto_chess.rank_award[idx]
				awardType = getattr(cfg, 'type', 0) or 0
				if awardType == 0:  # 总榜奖励
					cfgs.append(cfg)
					cfgRanks.append(cfg.rankMax)

		sentCount = 0
		for roleID, rank in ranks.iteritems():
			if not cfgRanks:
				break
			idx = bisect.bisect_left(cfgRanks, rank)
			if idx < len(cfgs):
				cfg = cfgs[idx]
				if rank <= cfg.rankMax:
					award = getattr(cfg, 'award', {}) or getattr(cfg, 'awards', {}) or {}
					if award:
						mail = ObjectRole.makeMailModel(roleID, AutoChessRankAwardMailID, contentArgs=rank, attachs=award)
						MailJoinableQueue.send(mail)
						sentCount += 1
		
		logger.info('ObjectCrossAutoChessGameGlobal.onPveRankAward completed, sent %s mails', sentCount)

	# 训练家分榜奖励（参考拟态实现，与总榜共用邮件ID）
	def onTrainerRankAward(self, trainerRanks):
		import bisect
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		from game.globaldata import AutoChessRankAwardMailID

		if not trainerRanks:
			logger.info('ObjectCrossAutoChessGameGlobal.onTrainerRankAward: no trainer ranks')
			return

		# 防重复发放检查：使用活动结束日期作为标识
		endDate = getattr(self, 'end_date', 0) or 0
		lastAwardDate = getattr(self, 'last_trainer_award_date', 0) or 0
		if endDate > 0 and lastAwardDate == endDate:
			logger.warning('ObjectCrossAutoChessGameGlobal.onTrainerRankAward already awarded for endDate=%s, skip!', endDate)
			return
		
		# 记录发奖日期（先记录再发奖，防止中途崩溃后重复发放）
		if endDate > 0:
			self.last_trainer_award_date = endDate
			logger.info('ObjectCrossAutoChessGameGlobal.onTrainerRankAward set last_trainer_award_date=%s', endDate)

		totalCount = sum(len(ranks) for ranks in trainerRanks.values())
		logger.info('ObjectCrossAutoChessGameGlobal.onTrainerRankAward sending awards for %s trainers, %s total ranks', 
				   len(trainerRanks), totalCount)

		# 构建配置表查询：type=1 表示训练家分榜
		cfgs = []
		cfgRanks = []
		if hasattr(csv, 'auto_chess') and hasattr(csv.auto_chess, 'rank_award'):
			for idx in sorted(csv.auto_chess.rank_award.keys()):
				cfg = csv.auto_chess.rank_award[idx]
				awardType = getattr(cfg, 'type', 0) or 0
				if awardType == 1:  # 训练家分榜奖励
					cfgs.append(cfg)
					cfgRanks.append(cfg.rankMax)

		sentCount = 0
		# 遍历每个训练家的排行榜发放奖励
		for trainerID, ranks in trainerRanks.items():
			trainerRanksDict = {item['role_id']: item['rank'] for item in ranks if item.get('role_id') and item.get('rank', 0) > 0}
			
			for roleID, rank in trainerRanksDict.iteritems():
				if not cfgRanks:
					break
				idx = bisect.bisect_left(cfgRanks, rank)
				if idx < len(cfgs):
					cfg = cfgs[idx]
					if rank <= cfg.rankMax:
						award = getattr(cfg, 'award', {}) or getattr(cfg, 'awards', {}) or {}
						if award:
							mail = ObjectRole.makeMailModel(roleID, AutoChessRankAwardMailID, contentArgs=rank, attachs=award)
							MailJoinableQueue.send(mail)
							sentCount += 1
		
		logger.info('ObjectCrossAutoChessGameGlobal.onTrainerRankAward completed, sent %s mails', sentCount)

	# Type 45 勋章：同时获得所有排行榜的前10名
	def onAutoChessRankMedal(self, pveRanks, trainerRanks):
		"""
		Type 45 (medalID 1391): 在卡牌冒险玩法赛季结算时，同时获得所有排行榜的前10名
		需要同时满足：总榜前10 + 所有参与的训练家分榜都前10
		"""
		from game.object.game import ObjectGame
		from game.handler.inl_mail import updateMedalCounterForRank
		
		# 1. 构建总榜前10的玩家集合
		pveTop10 = {}  # {roleID: rank}
		for item in pveRanks:
			roleID = item.get('role_id')
			rank = item.get('rank', 0)
			if roleID and 0 < rank <= 10:
				pveTop10[roleID] = rank
		
		if not pveTop10:
			logger.info('onAutoChessRankMedal: no players in pve top 10')
			return
		
		# 2. 构建每个玩家在各训练家分榜的排名
		# playerTrainerRanks[roleID] = {trainerID: rank}
		playerTrainerRanks = {}
		for trainerID, ranks in (trainerRanks or {}).items():
			for item in ranks:
				roleID = item.get('role_id')
				rank = item.get('rank', 0)
				if roleID and rank > 0:
					if roleID not in playerTrainerRanks:
						playerTrainerRanks[roleID] = {}
					playerTrainerRanks[roleID][trainerID] = rank
		
		# 3. 检查每个总榜前10的玩家，是否在所有参与的分榜都是前10
		qualifiedPlayers = []
		for roleID in pveTop10:
			trainerRanksForPlayer = playerTrainerRanks.get(roleID, {})
			if not trainerRanksForPlayer:
				# 没有分榜数据，可能没有参与任何训练家榜，跳过
				continue
			
			# 检查是否所有分榜都是前10
			allTop10 = all(rank <= 10 for rank in trainerRanksForPlayer.values())
			if allTop10:
				qualifiedPlayers.append(roleID)
				logger.info('onAutoChessRankMedal: roleID=%s qualified, pveRank=%s, trainerRanks=%s',
					binascii.hexlify(roleID), pveTop10[roleID], trainerRanksForPlayer)
		
		# 4. 为符合条件的玩家更新勋章
		for roleID in qualifiedPlayers:
			updateMedalCounterForRank(self._dbc, ObjectGame.getByRoleID, roleID, 1391, 10, 1)
		
		logger.info('onAutoChessRankMedal: %s players qualified for Type 45 medal', len(qualifiedPlayers))

	# 赛季结束
	@coroutine
	def onClosed(self, areaKey):
		logger.info("ObjectCrossAutoChessGameGlobal.onClosed")
		self.round = 'closed'

		rpc = self.cross_client(areaKey)
		if rpc:
			yield rpc.call_async('CrossAutoChessGameClosed', areaKey, [])

	def reset(self):
		self.round = 'closed'
		self.cross_key = ''
		return True

	@classmethod
	def cleanHalfPeriod(cls):
		for _, obj in cls.GlobalObjsMap.iteritems():
			if obj.isHalfPeriod:  # 清除半周期状态
				ObjectServerGlobalRecord.overHalfPeroid('cross_auto_chess', obj.key)
				obj.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_auto_chess', obj.key)

		cls.GlobalHalfPeriodObjsMap = {}

	@classmethod
	@coroutine
	def onCrossCommit(cls, key, transaction):
		'''
		跨服启动commit
		'''
		logger.info('ObjectCrossAutoChessGameGlobal.onCrossCommit %s %s', key, transaction)

		# cross竞争资源成功
		self = cls.Singleton
		# 玩法已经被占用
		if self.cross_key != '' and self.cross_key != key:
			logger.warning('ObjectCrossAutoChessGameGlobal.onCrossCommit %s', self.cross_key)
			raise Return(False)

		cls.cleanHalfPeriod()
		# 直接重置
		self.reset()
		self.cross_key = key
		raise Return(True)

	@classmethod
	def cross_client(cls, areaKey, cross_key=None):
		'''
		获取cross rpc
		'''
		self = cls.getByAreaKey(areaKey)
		if cross_key is None:
			cross_key = self.cross_key
		if cross_key == '':
			return None
		container = self.server.container
		client = container.getserviceOrCreate(cross_key)
		return client

	@classmethod
	def getRankInfo(cls, roleID, areaKey):
		'''
		结束后的排行榜
		'''
		self = cls.getByAreaKey(areaKey)
		if self.cross_key == '' or self.round == 'closed':
			return {
				'ranks': self.last_ranks[:50] if self.last_ranks else [],
				'rank': 0,
				'score': 0,
				'servers': self.last_servers or [],
			}
		return None

	@classmethod
	@coroutine
	def getCrossRankInfo(cls, roleID, areaKey, offset=0, limit=50):
		'''
		获取跨服排行榜数据
		'''
		rpc = cls.cross_client(areaKey)
		if rpc is None:
			logger.warning('ObjectCrossAutoChessGameGlobal.getCrossRankInfo rpc is None, areaKey=%s', areaKey)
			raise Return(None)

		self = cls.getByAreaKey(areaKey)
		result = yield rpc.call_async('CrossAutoChessGetRankList', self.key, roleID, offset, limit)
		raise Return(result)

	@classmethod
	@coroutine
	def updateScore(cls, areaKey, roleInfo):
		'''
		更新玩家积分到跨服服务
		'''
		rpc = cls.cross_client(areaKey)
		if rpc is None:
			raise Return(None)

		self = cls.getByAreaKey(areaKey)
		result = yield rpc.call_async('CrossAutoChessUpdateScore', self.key, roleInfo)
		raise Return(result)

	# ========================================================================
	# PVE 排行榜相关方法
	# ========================================================================

	@classmethod
	@coroutine
	def getCrossPveRankInfo(cls, roleID, areaKey, offset=0, limit=50):
		'''
		获取PVE跨服排行榜数据
		'''
		rpc = cls.cross_client(areaKey)
		if rpc is None:
			logger.warning('ObjectCrossAutoChessGameGlobal.getCrossPveRankInfo rpc is None, areaKey=%s', areaKey)
			raise Return(None)

		self = cls.getByAreaKey(areaKey)
		result = yield rpc.call_async('CrossAutoChessGetPveRankList', self.key, roleID, offset, limit)
		raise Return(result)

	@classmethod
	@coroutine
	def updatePveScore(cls, areaKey, roleInfo):
		'''
		更新PVE成就点数到跨服服务
		'''
		rpc = cls.cross_client(areaKey)
		if rpc is None:
			raise Return(None)

		self = cls.getByAreaKey(areaKey)
		result = yield rpc.call_async('CrossAutoChessUpdatePveScore', self.key, roleInfo)
		raise Return(result)

	@classmethod
	@coroutine
	def getCrossTrainerRankInfo(cls, trainerID, roleID, areaKey, offset=0, limit=50):
		'''
		获取训练家分榜数据
		'''
		rpc = cls.cross_client(areaKey)
		if rpc is None:
			logger.warning('ObjectCrossAutoChessGameGlobal.getCrossTrainerRankInfo rpc is None, areaKey=%s', areaKey)
			raise Return(None)

		self = cls.getByAreaKey(areaKey)
		result = yield rpc.call_async('CrossAutoChessGetTrainerRankList', self.key, trainerID, roleID, offset, limit)
		raise Return(result)

	@classmethod
	@coroutine
	def savePlayRecord(cls, areaKey, data):
		'''
		保存战报到跨服服务
		'''
		rpc = cls.cross_client(areaKey)
		if rpc is None:
			raise Return(None)

		self = cls.getByAreaKey(areaKey)
		result = yield rpc.call_async('CrossAutoChessSavePlayRecord', self.key, data)
		raise Return(result)

	@classmethod
	@coroutine
	def getPlayRecord(cls, areaKey, recordID):
		'''
		获取战报
		'''
		rpc = cls.cross_client(areaKey)
		if rpc is None:
			raise Return(None)

		result = yield rpc.call_async('CrossAutoChessGetPlayRecord', recordID)
		raise Return(result)

	# ========================================================================
	# PVP 匹配相关方法
	# ========================================================================

	@classmethod
	def lobby_client(cls, areaKey):
		'''
		获取 autochess_lobby 服务的 RPC 客户端
		'''
		self = cls.getByAreaKey(areaKey)
		if self is None:
			logger.warning('lobby_client: self is None for areaKey=%s', areaKey)
			return None
		# lobby 服务名格式: autochess_lobby.{channel}.{id}
		# 从 cross_key 推导: crossautochess.cn.1 -> autochess_lobby.cn.1
		cross_key = self.cross_key
		if not cross_key:
			logger.warning('lobby_client: cross_key is empty for areaKey=%s', areaKey)
			return None
		parts = cross_key.split('.')
		if len(parts) < 3:
			logger.warning('lobby_client: cross_key format invalid: %s', cross_key)
			return None
		lobby_key = 'autochess_lobby.%s.%s' % (parts[1], parts[2])
		logger.info('lobby_client: connecting to %s', lobby_key)
		container = self.server.container
		client = container.getserviceOrCreate(lobby_key)
		return client

	@classmethod
	@coroutine
	def startMatch(cls, areaKey, player):
		'''
		开始匹配
		player: {
			'id': document.ID,
			'game_key': str,
			'cross_key': str,
			'name': str,
			'logo': int,
			'frame': int,
			'level': int,
			'score': int,
			'winstreak': bool,
			'failstreak': bool,
			'fighting_point': int,
			'time': int (秒级时间戳),
			'timeout': int (秒),
			'season': int,
		}
		返回: bool (成功/失败)
		'''
		rpc = cls.lobby_client(areaKey)
		if rpc is None:
			logger.warning('ObjectCrossAutoChessGameGlobal.startMatch rpc is None, areaKey=%s', areaKey)
			raise Return(False)

		try:
			logger.info('startMatch: calling CrossAutoChessLobbyMatchStart with player=%s', player.get('id'))
			result = yield rpc.call_async('CrossAutoChessLobbyMatchStart', player)
			logger.info('startMatch: result=%s', result)
		except Exception as e:
			logger.warning('ObjectCrossAutoChessGameGlobal.startMatch error: %s', e)
			raise Return(False)
		raise Return(result)

	@classmethod
	@coroutine
	def cancelMatch(cls, areaKey, gameKey, roleID):
		'''
		取消匹配
		返回: bool (成功/失败)
		'''
		rpc = cls.lobby_client(areaKey)
		if rpc is None:
			logger.warning('ObjectCrossAutoChessGameGlobal.cancelMatch rpc is None, areaKey=%s', areaKey)
			raise Return(False)

		try:
			result = yield rpc.call_async('CrossAutoChessLobbyMatchCancel', gameKey, roleID)
		except Exception as e:
			logger.warning('ObjectCrossAutoChessGameGlobal.cancelMatch error: %s', e)
			raise Return(False)
		raise Return(result)

	@classmethod
	@coroutine
	def isMatching(cls, areaKey, gameKey, roleID):
		'''
		查询玩家是否在匹配中
		返回: bool
		'''
		rpc = cls.lobby_client(areaKey)
		if rpc is None:
			# 如果连不上匹配服务，视为不在匹配中
			raise Return(False)

		try:
			result = yield rpc.call_async('CrossAutoChessLobbyIsMatching', gameKey, roleID)
		except Exception as e:
			logger.warning('ObjectCrossAutoChessGameGlobal.isMatching error: %s', e)
			raise Return(False)
		raise Return(result)

	# 匹配超时处理
	@classmethod
	@coroutine
	def onMatchDiscard(cls, discards):
		'''
		匹配超时，通知玩家清除匹配状态
		discards: [roleID, ...]
		'''
		from game.session import Session
		# 推送格式需要匹配 sync 数据结构
		data = {
			'sync': {
				'upd': {
					'auto_chess': {
						'_db': {
							'online': {'matching': 0}
						}
					}
				}
			}
		}
		Session.broadcast('/game/push', data, roles=discards)
		logger.info('ObjectCrossAutoChessGameGlobal.onMatchDiscard: discards=%s', discards)
		raise Return(True)

	# 匹配成功处理
	@classmethod
	@coroutine
	def onMatchComplete(cls, data):
		'''
		匹配成功，通知玩家进入房间
		data: {
			'room_id': roomID,
			'room_key': roomKey,
			'address': address,
			'players': [player info list]
		}
		'''
		from framework.helper import objectid2string
		from game.session import Session
		roomID = data.get('room_id')
		roomKey = data.get('room_key')
		address = data.get('address')
		players = data.get('players', [])

		logger.info('ObjectCrossAutoChessGameGlobal.onMatchComplete: data=%s', data)

		# 提取本服玩家 roleID
		# ObjsMap 的键是二进制字符串，直接使用 Go 传过来的 id
		roleIDs = []
		for p in players:
			pid = p.get('id')
			if pid:
				roleIDs.append(pid)
				logger.info('onMatchComplete: player id=%s, type=%s', pid, type(pid))

		if not roleIDs:
			logger.warning('ObjectCrossAutoChessGameGlobal.onMatchComplete: no roleIDs found')
			raise Return(False)

		# 前端监听 auto_chess.battle，当 address 有值时进入房间
		# 推送格式需要匹配 sync 数据结构，更新 battle 字段（触发前端连接）
		pushData = {
			'sync': {
				'upd': {
					'auto_chess': {
						'_db': {
							'battle': {
								'address': address,  # 房间地址（前端用这个连接 RUDP）
								'roomID': objectid2string(roomID) if roomID else '',
							},
							'online': {
								'matching': 0,  # 清除匹配状态
								'room_id': objectid2string(roomID) if roomID else '',
								'room_address': address,
							}
						}
					}
				}
			}
		}
		logger.info('ObjectCrossAutoChessGameGlobal.onMatchComplete: broadcasting to roleIDs=%s', roleIDs)
		
		# 调试：检查每个 roleID 的 session 状态
		from game.object.game import ObjectGame
		# 打印 ObjsMap 中的所有键
		logger.info('onMatchComplete DEBUG: ObjsMap keys=%s', list(ObjectGame.ObjsMap.keys())[:5])
		for rid in roleIDs:
			logger.info('onMatchComplete DEBUG: looking for rid=%s, type=%s, hex=%s', rid, type(rid), rid.binary.encode('hex') if hasattr(rid, 'binary') else 'N/A')
			game = ObjectGame.getByRoleID(rid, safe=False)
			if game:
				from game.session import Session as Sess
				session = Sess.idSessions.getByKey(game.role.accountKey)
				logger.info('onMatchComplete DEBUG: roleID=%s, game=%s, accountKey=%s, session=%s', 
					rid, game is not None, game.role.accountKey if game else None, session is not None)
			else:
				logger.warning('onMatchComplete DEBUG: roleID=%s, game NOT FOUND in ObjsMap', rid)
		
		Session.broadcast('/game/push', data=pushData, roles=roleIDs)
		logger.info('ObjectCrossAutoChessGameGlobal.onMatchComplete: roomID=%s, address=%s, players=%d', roomID, address, len(players))
		raise Return(True)

	# 对局结束处理
	@classmethod
	@coroutine
	def onGameEnd(cls, data):
		'''
		对局结束，更新玩家勋章相关字段
		data: {
			'results': [
				{'role_id': roleID, 'rank': 排名, 'is_robot': bool, 'hp': 血量},
				...
			]
		}
		'''
		from game.object.game import ObjectGame
		
		results = data.get('results', [])
		if not results:
			logger.warning('ObjectCrossAutoChessGameGlobal.onGameEnd: no results')
			raise Return(False)
		
		logger.info('ObjectCrossAutoChessGameGlobal.onGameEnd: results=%s', len(results))
		
		for result in results:
			roleID = result.get('role_id')
			rank = result.get('rank', 0)
			hp = result.get('hp', 0)
			isRobot = result.get('is_robot', False)
			
			# 跳过机器人
			if isRobot or not roleID:
				continue
			
			game, safeGuard = ObjectGame.getByRoleID(roleID)
			with safeGuard:
				if game:
					# Type 58: 一个赛季内连续获得对局第一名次数
					if rank == 1:
						# 第一名，连胜次数+1
						game.role.cross_online_auto_chess_season_top1_win_streak = (game.role.cross_online_auto_chess_season_top1_win_streak or 0) + 1
						logger.info('onGameEnd: roleID=%s rank=1, streak=%s', 
							roleID, game.role.cross_online_auto_chess_season_top1_win_streak)
						
						# Type 59: 完好无损 - 在训练家至少有30血的情况下获得第1名
						# medalID: 1671 (1次), 1672 (5次), 1673 (10次)
						if hp >= 30:
							game.medal.incrementMedalCounter(1671)
							game.medal.incrementMedalCounter(1672)
							game.medal.incrementMedalCounter(1673)
							logger.info('onGameEnd: roleID=%s Type59 完好无损, hp=%s', roleID, hp)
					else:
						# 非第一名，重置连胜
						game.role.cross_online_auto_chess_season_top1_win_streak = 0
						logger.info('onGameEnd: roleID=%s rank=%s, streak reset', roleID, rank)
				else:
					# 离线玩家，非第一名需要重置连胜
					if rank != 1:
						from tornado.ioloop import IOLoop
						IOLoop.current().spawn_callback(
							cls._resetOfflinePlayerStreak, roleID
						)
					logger.warning('onGameEnd: roleID=%s game not found (offline), rank=%s', roleID, rank)
		
		raise Return(True)
	
	@classmethod
	@coroutine
	def _resetOfflinePlayerStreak(cls, roleID):
		"""重置离线玩家的连胜"""
		self = cls.Singleton
		if not self or not self._dbc:
			return
		try:
			yield self._dbc.call_async('DBUpdate', 'Role', roleID, 
				{'cross_online_auto_chess_season_top1_win_streak': 0}, False)
			logger.info('_resetOfflinePlayerStreak: roleID=%s reset to 0', roleID)
		except Exception as e:
			logger.exception('_resetOfflinePlayerStreak error: %s', e)
