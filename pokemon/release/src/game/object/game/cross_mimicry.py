#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
============================================================================
拟态对战 (Mimicry Battle) - 跨服状态管理
文档: docs/拟态对战_Python服务端.md
============================================================================
'''

from framework.log import logger
from framework.csv import csv, MergeServ
from framework.object import ObjectNoGCDBase, db_property
from game.globaldata import MimicryRankAwardMailID
from game.object.game.servrecord import ObjectServerGlobalRecord

from tornado.gen import coroutine, Return

import bisect


#
# ObjectCrossMimicryGameGlobal
#

class ObjectCrossMimicryGameGlobal(ObjectNoGCDBase):
	DBModel = 'CrossMimicryGameGlobal'

	Singleton = None

	CrossMimicryRankSize = 50

	GlobalObjsMap = {}  # {areakey: ObjectCrossMimicryGameGlobal}
	GlobalHalfPeriodObjsMap = {}  # {areakey: ObjectCrossMimicryGameGlobal}

	@classmethod
	def classInit(cls):
		pass

	@classmethod
	def getByAreaKey(cls, key):
		return cls.GlobalHalfPeriodObjsMap.get(key, cls.Singleton)

	def __init__(self, dbc):
		ObjectNoGCDBase.__init__(self, None, dbc)

	def set(self, dic):
		ObjectNoGCDBase.set(self, dic)
		self.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_mimicry', self.key)
		return self

	def init(self, server, crossData):
		self.server = server
		self._cross = {}
		self._roleRankMap = {}  # {roleID: (rank, score, bossID)}

		self.initCrossData(crossData)

		cls = ObjectCrossMimicryGameGlobal
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

	# 赛季状态
	round = db_property('round')

	# 开始日期
	date = db_property('date')

	# 结束日期
	end_date = db_property('end_date')

	# 上期排名
	last_ranks = db_property('last_ranks')

	# 上期匹配区服
	last_servers = db_property('last_servers')

	# 上次发奖日期（防重复发放）
	last_award_date = db_property('last_award_date')

	@property
	def servers(self):
		return self._cross.get('servers', [])

	@classmethod
	def isOpen(cls, areaKey):
		'''
		是否开启玩法
		'''
		self = cls.getByAreaKey(areaKey)
		if self is None or self.cross_key == '' or self.round == "closed":
			return False
		return True

	@classmethod
	def getRound(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		if self is None:
			return 'closed'
		return self.round

	@classmethod
	def getCrossKey(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		if self is None:
			return ''
		return self.cross_key

	@classmethod
	def getDate(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		if self is None:
			return 0
		return self._cross.get('date', 0)

	@classmethod
	def getEndDate(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		if self is None:
			return 0
		return self._cross.get('end_date', 0)

	@classmethod
	def getGameKey(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		if self is None:
			return ''
		return self.key

	@classmethod
	@coroutine
	def onCrossEvent(cls, event, key, data, sync):
		'''
		玩法流程
		'''
		logger.info('ObjectCrossMimicryGameGlobal.onCrossEvent %s %s', key, event)

		self = cls.getByAreaKey(key)
		if self is None:
			logger.warning('ObjectCrossMimicryGameGlobal.onCrossEvent self is None for key %s', key)
			raise Return({})

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
			self.onRankAward(data.get('allRanks', []))

		raise Return(ret)

	# 初始化
	def initCrossData(self, crossData):
		self._cross = crossData
		if crossData:
			self.cross_key = self._cross.get('cross_key', '')
			self.round = self._cross.get('round', 'closed')
			self.date = self._cross.get('date', 0)
			self.end_date = self._cross.get('end_date', 0)
			logger.info('Cross mimicry Init cross_key=%s date=%s end_date=%s round=%s', 
				self.cross_key, self.date, self.end_date, self.round)
		else:
			self.reset()

	# 赛季开始
	def onStart(self):
		logger.info('ObjectCrossMimicryGameGlobal.onStart')
		self.round = 'start'
		# 注意：last_ranks 和 last_servers 保留上期数据，不要清空
		# 只清空缓存
		self._roleRankMap = {}

	def onSaveRank(self, servers, allRanks):
		self.last_servers = servers
		self.last_ranks = allRanks

	# 赛季排名奖励
	def onRankAward(self, allRanks):
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		from game.object.game import ObjectGame
		from game.handler.inl_mail import updateMedalCounterForRank

		# 防重复发放检查：使用活动结束日期作为标识
		endDate = self.end_date or 0
		lastAwardDate = self.last_award_date or 0
		if endDate > 0 and lastAwardDate == endDate:
			logger.warning('ObjectCrossMimicryGameGlobal.onRankAward already awarded for endDate=%s, skip!', endDate)
			return
		
		# 记录发奖日期（先记录再发奖，防止中途崩溃后重复发放）
		if endDate > 0:
			self.last_award_date = endDate
			logger.info('ObjectCrossMimicryGameGlobal.onRankAward set last_award_date=%s (endDate)', endDate)

		ranks = {item['role_db_id']: item['rank'] for item in allRanks}

		logger.info('ObjectCrossMimicryGameGlobal.onRankAward sending %s mails', len(ranks))

		cfgs = []
		cfgRanks = []
		if hasattr(csv, 'mimicry') and hasattr(csv.mimicry, 'rank_award'):
			for idx in sorted(csv.mimicry.rank_award.keys()):
				cfg = csv.mimicry.rank_award[idx]
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
					award = getattr(cfg, 'award', {}) or {}
					if award:
						mail = ObjectRole.makeMailModel(roleID, MimicryRankAwardMailID, contentArgs=rank, attachs=award)
						MailJoinableQueue.send(mail)
						sentCount += 1
			
			# 勋章计数：拟态挑战排名 (Type 48, medalID 1511, 前3名)
			updateMedalCounterForRank(self._dbc, ObjectGame.getByRoleID, roleID, 1511, 3, rank)
		
		logger.info('ObjectCrossMimicryGameGlobal.onRankAward completed, sent %s mails', sentCount)

	def reset(self):
		self.round = 'closed'
		self.cross_key = ''
		self.date = 0
		self.end_date = 0
		return True

	@classmethod
	def cleanHalfPeriod(cls):
		for _, obj in cls.GlobalObjsMap.iteritems():
			if obj.isHalfPeriod:  # 清除半周期状态
				ObjectServerGlobalRecord.overHalfPeroid('cross_mimicry', obj.key)
				obj.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_mimicry', obj.key)

		cls.GlobalHalfPeriodObjsMap = {}

	@classmethod
	@coroutine
	def onCrossCommit(cls, key, transaction):
		'''
		跨服启动commit
		'''
		logger.info('ObjectCrossMimicryGameGlobal.onCrossCommit %s %s', key, transaction)

		# cross竞争资源成功
		self = cls.Singleton
		if self is None:
			logger.warning('ObjectCrossMimicryGameGlobal.onCrossCommit Singleton is None')
			raise Return(False)

		# 玩法已经被占用
		if self.cross_key != '' and self.cross_key != key:
			logger.warning('ObjectCrossMimicryGameGlobal.onCrossCommit occupied %s', self.cross_key)
			raise Return(False)

		cls.cleanHalfPeriod()
		# 直接重置
		self.reset()
		self.cross_key = key
		raise Return(True)

	@classmethod
	def cross_client(cls, areaKey, cross_key=None):
		self = cls.getByAreaKey(areaKey)
		if self is None:
			return None
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
		if self is None:
			return None

		if self.cross_key == '' or self.round == 'closed':
			if not self._roleRankMap:
				for item in self.last_ranks:
					itemGameKey = MergeServ.getMergeServKey(item['game_key'])  # 转为合服名
					if itemGameKey != self.key:
						continue
					self._roleRankMap[item['role_db_id']] = (item['rank'], item['score'], item['boss_id'])
			myInfo = self._roleRankMap.get(roleID, (0, 0, 0))
			return {
				'ranks': self.last_ranks if len(self.last_ranks) <= cls.CrossMimicryRankSize else self.last_ranks[:cls.CrossMimicryRankSize],
				'rank': myInfo[0],
				'score': myInfo[1],
				'boss_id': myInfo[2],
				'servers': self.last_servers,
			}
		return None

	@classmethod
	@coroutine
	def onClosed(cls, areaKey):
		logger.info("ObjectCrossMimicryGameGlobal.onClosed")

		self = cls.getByAreaKey(areaKey)
		if self is None:
			return

		self.round = 'closed'

		# 通知跨服服务活动结束
		rpc = cls.cross_client(areaKey)
		if rpc:
			yield rpc.call_async('CrossMimicryGameClosed', areaKey, [])

	@classmethod
	@coroutine
	def updateRankRole(cls, areaKey, roleInfo):
		'''
		更新玩家排行榜数据到跨服服务
		
		Args:
			areaKey: 区服key
			roleInfo: {
				'role_db_id': roleID,
				'game_key': gameKey,
				'name': name,
				'logo': logo,
				'frame': frame,
				'level': level,
				'score': score,
				'boss_id': bossID,
			}
		'''
		rpc = cls.cross_client(areaKey)
		if rpc is None:
			raise Return(None)

		result = yield rpc.call_async('CrossMimicryUpdate', areaKey, [roleInfo])
		raise Return(result)

	@classmethod
	@coroutine
	def getCrossRankInfo(cls, roleID, areaKey):
		'''
		获取跨服排行榜数据
		'''
		rpc = cls.cross_client(areaKey)
		if rpc is None:
			logger.warning('ObjectCrossMimicryGameGlobal.getCrossRankInfo rpc is None, areaKey=%s', areaKey)
			raise Return(None)

		result = yield rpc.call_async('CrossMimicryRankInfo', areaKey, roleID)
		raise Return(result)

