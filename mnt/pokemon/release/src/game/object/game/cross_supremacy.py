#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

import bisect

from framework import nowtime_t, todayinclock5elapsedays
from framework.csv import csv, MergeServ
from framework.helper import objectid2string
from framework.log import logger
from framework.object import ObjectNoGCDBase, db_property
from game import globaldata
from game.globaldata import (
	CrossSupremacyRankAwardMailID,
	CrossSupremacyDivisionRankAwardMailID,
	CrossSupremacyResAwardMailID,
	CrossSupremacyGradeAwardMailID,
)
from game.object import TitleDefs
from game.object.game.servrecord import ObjectServerGlobalRecord
from tornado.gen import coroutine, Return


def _iter_csv_items(table):
	if not table:
		return []
	if isinstance(table, dict):
		return table.iteritems()
	if hasattr(table, 'keys'):
		return ((k, table[k]) for k in table.keys())
	return []


def _get_grade_by_score(score):
	grades = getattr(getattr(csv.cross, 'supremacy', None), 'grade', {}) or {}
	if not grades:
		return 1, None
	items = sorted(_iter_csv_items(grades), key=lambda kv: getattr(kv[1], 'score', 0) or 0, reverse=True)
	for grade_id, cfg in items:
		need = getattr(cfg, 'score', 0) or 0
		if score >= need:
			return grade_id, cfg
	return items[-1]


def _get_grade_cfg(grade_id):
	grades = getattr(getattr(csv.cross, 'supremacy', None), 'grade', {}) or {}
	if isinstance(grades, dict):
		return grades.get(grade_id)
	getter = getattr(grades, 'get', None)
	if callable(getter):
		return getter(grade_id, None)
	try:
		return grades[grade_id]
	except Exception:
		return None


def _get_csv_entry(table, key, default=None):
	if not table:
		return default
	if isinstance(table, dict):
		return table.get(key, default)
	getter = getattr(table, 'get', None)
	if callable(getter):
		return getter(key, default)
	try:
		return table[key]
	except Exception:
		return default


def _default_event_data():
	return {
		'event_id': 0,
		'event_time': 0,
		'buff': {},
		'triggered': {},
		'battle_times': 0,
		'win_times': 0,
		'enter_times': 0,
	}


def _normalize_role_id(role_id):
	from framework.helper import string2objectid
	if isinstance(role_id, basestring) and len(role_id) == 24:
		try:
			return string2objectid(role_id)
		except Exception:
			return role_id
	return role_id


def _get_map_value(data_map, role_id, default=None):
	if not data_map:
		return default
	if role_id in data_map:
		return data_map.get(role_id)
	if isinstance(role_id, basestring):
		role_obj = _normalize_role_id(role_id)
		if role_obj != role_id and role_obj in data_map:
			return data_map.get(role_obj)
	else:
		role_str = objectid2string(role_id)
		if role_str in data_map:
			return data_map.get(role_str)
	return default


#
# ObjectCrossSupremacyGameGlobal
#
class ObjectCrossSupremacyGameGlobal(ObjectNoGCDBase):
	DBModel = 'CrossSupremacyGameGlobal'

	Singleton = None

	OpenDays = 0

	GlobalObjsMap = {}  # {areakey: ObjectCrossSupremacyGameGlobal}
	GlobalHalfPeriodObjsMap = {}  # {areakey: ObjectCrossSupremacyGameGlobal}

	@classmethod
	def classInit(cls):
		base_table = getattr(getattr(csv.cross, 'supremacy', None), 'base', None)
		cfg = _get_csv_entry(base_table, 1, None)
		cls.OpenDays = getattr(cfg, 'servOpenDays', 0) or 0

	@classmethod
	def getByAreaKey(cls, key):
		return cls.GlobalHalfPeriodObjsMap.get(key, cls.Singleton)

	def __init__(self, dbc):
		ObjectNoGCDBase.__init__(self, None, dbc)

	def set(self, dic):
		ObjectNoGCDBase.set(self, dic)
		self.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_supremacy', self.key)
		return self

	def init(self, server, crossData):
		self.server = server
		self._cross = {}
		self.initCrossData(crossData)

		cls = ObjectCrossSupremacyGameGlobal
		cls.GlobalObjsMap[self.key] = self
		if self.key == self.server.key:
			cls.Singleton = self

		if self.isHalfPeriod:
			srcServs = MergeServ.getSrcServKeys(self.key)
			for srcServ in srcServs:
				cls.GlobalHalfPeriodObjsMap[srcServ] = self

		return self

	@classmethod
	def cleanHalfPeriod(cls):
		for _, obj in cls.GlobalObjsMap.iteritems():
			if obj.isHalfPeriod:
				ObjectServerGlobalRecord.overHalfPeroid('cross_supremacy', obj.key)
				obj.isHalfPeriod = ObjectServerGlobalRecord.isHalfPeriod('cross_supremacy', obj.key)
				obj.last_ranks = []
				obj.top_battle_history = []
		cls.GlobalHalfPeriodObjsMap = {}

	# server_key
	key = db_property('key')

	# 跨服server key
	cross_key = db_property('cross_key')

	# 上期排行榜
	last_ranks = db_property('last_ranks')

	# 赛季状态
	round = db_property('round')

	# 跨服csv_id
	csv_id = db_property('csv_id')

	# 跨服日期
	date = db_property('date')

	# 精彩战报
	top_battle_history = db_property('top_battle_history')

	@property
	def servers(self):
		return self._cross.get('servers', [])

	@classmethod
	def isOpen(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		if self is None:
			return False
		if self.cross_key == '' or self.round == "closed":
			return False
		return True

	@classmethod
	def isRoleOpen(cls):
		if cls.OpenDays <= 0:
			return True
		return todayinclock5elapsedays(globaldata.GameServOpenDatetime) >= cls.OpenDays

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
		return self.date

	@classmethod
	def getCsvID(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		if self is None:
			return 0
		return self.csv_id

	@classmethod
	def getTopBattleHistory(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		if self is None:
			return []
		return self.top_battle_history

	# 初始化 init
	def initCrossData(self, crossData):
		self._cross = crossData or {}
		if self._cross:
			self.round = self._cross.get('round', 'closed')
			self.csv_id = self._cross.get('csv_id', 0)
			self.date = self._cross.get('date', 0)
			logger.info('Cross Supremacy Init %s %s %s, csv_id %d', self.cross_key, self.date, self.round, self.csv_id)
		else:
			self.reset()

	def reset(self):
		self._cross = {}
		self.round = 'closed'
		self.csv_id = 0
		self.date = 0
		self.last_ranks = []
		self.top_battle_history = []

	def onStart(self):
		logger.info('ObjectCrossSupremacyGameGlobal.onStart')
		self.round = 'start'
		self.last_ranks = []
		self.top_battle_history = []

	def onPrepare(self, key):
		from game.object.game import ObjectGame

		games, guard = ObjectGame.getAll()
		role_infos = []
		with guard:
			for game in games:
				role = getattr(game, 'role', None)
				if not role or role.areaKey != key:
					continue
				data = role.cross_supremacy_datas or {}
				if not data:
					continue
				record_id = role.cross_supremacy_record_db_id or role.id
				if role.cross_supremacy_record_db_id is None:
					role.cross_supremacy_record_db_id = record_id
				role_infos.append({
					'record_db_id': record_id,
					'role_db_id': role.id,
					'game_key': role.areaKey,
					'name': role.name,
					'level': role.level,
					'score': data.get('score', 0),
					'fighting_point': getattr(role, 'top12_fighting_point', 0),
					'logo': role.logo,
					'frame': role.frame,
					'figure': getattr(role, 'figure', 0) or 1,
					'title': getattr(role, 'title_id', 0),
				})
		return role_infos

	def onClosed(self, lastRanks, topBattleHistory):
		logger.info('ObjectCrossSupremacyGameGlobal.onClosed')
		self.round = 'closed'
		self.cross_key = ''
		self.last_ranks = lastRanks
		self.top_battle_history = topBattleHistory

	@coroutine
	def onFinishAward(self, roleRanks, roleScores, divisionRanks):
		from game.mailqueue import MailJoinableQueue
		from game.object.game.role import ObjectRole
		from game.object.game import ObjectGame
		from game.handler.inl_mail import updateMedalCounterForRank

		if not roleRanks:
			raise Return(None)

		version = 0
		service_cfg = getattr(getattr(csv, 'cross', None), 'service', None)
		cfg = _get_csv_entry(service_cfg, self.csv_id, None) if service_cfg else None
		version = getattr(cfg, 'version', 0) if cfg else 0

		rank_cfgs_global = []
		rank_ranges_global = []
		rank_cfgs_div = []
		rank_ranges_div = []
		rank_table = getattr(getattr(csv.cross, 'supremacy', None), 'rank', {}) or {}
		for _, rcfg in sorted(_iter_csv_items(rank_table), key=lambda kv: getattr(kv[1], 'range', 0) or 0):
			cfg_version = getattr(rcfg, 'version', 0) or 0
			if cfg_version not in (0, version):
				continue
			flag = getattr(rcfg, 'flag', 1)
			if flag == 0:
				rank_cfgs_div.append(rcfg)
				rank_ranges_div.append(getattr(rcfg, 'range', 0) or 0)
			else:
				rank_cfgs_global.append(rcfg)
				rank_ranges_global.append(getattr(rcfg, 'range', 0) or 0)

		for roleID, rank in roleRanks.iteritems():
			if not isinstance(rank, (int, long)) or rank <= 0:
				continue
			role_db_id = _normalize_role_id(roleID)

			if rank_cfgs_global:
				idx = bisect.bisect_left(rank_ranges_global, rank)
				if idx < len(rank_cfgs_global):
					cfg = rank_cfgs_global[idx]
					award = getattr(cfg, 'award', None) or {}
					if award:
						mail = ObjectRole.makeMailModel(role_db_id, CrossSupremacyRankAwardMailID, contentArgs=(rank,), attachs=award)
						MailJoinableQueue.send(mail)
			
			# 勋章计数：世界锦标赛排名 (Type 24, medalID 1191, 前12名)
			updateMedalCounterForRank(self._dbc, ObjectGame.getByRoleID, role_db_id, 1191, 12, rank)

			div_rank = 0
			if divisionRanks:
				div_rank = _get_map_value(divisionRanks, role_db_id, 0) or 0
			if div_rank > 0 and rank_cfgs_div:
				idx = bisect.bisect_left(rank_ranges_div, div_rank)
				if idx < len(rank_cfgs_div):
					cfg = rank_cfgs_div[idx]
					award = getattr(cfg, 'award', None) or {}
					if award:
						mail = ObjectRole.makeMailModel(role_db_id, CrossSupremacyDivisionRankAwardMailID, contentArgs=(div_rank,), attachs=award)
						MailJoinableQueue.send(mail)

			score = _get_map_value(roleScores, role_db_id, None) if roleScores else None
			if score is None:
				continue
			grade_id, grade_cfg = _get_grade_by_score(score)
			if not grade_cfg:
				continue
			season_award = getattr(grade_cfg, 'seasonAward', None) or {}
			if season_award:
				stage_name = getattr(grade_cfg, 'stageName', '')
				mail = ObjectRole.makeMailModel(role_db_id, CrossSupremacyGradeAwardMailID, contentArgs=(stage_name,), attachs=season_award)
				MailJoinableQueue.send(mail)

			game = ObjectGame.getByRoleID(role_db_id, safe=False)
			data = None
			if game and game.role:
				data = game.role.cross_supremacy_datas or {}
			else:
				ret = yield self.server.dbcGame.call_async('DBRead', 'Role', role_db_id, False)
				if ret and ret.get('ret') and ret.get('model'):
					data = ret['model'].get('cross_supremacy_datas', {}) or {}

			if data is None:
				continue

			res = data.get('res', {}) or {}
			if res:
				mail = ObjectRole.makeMailModel(role_db_id, CrossSupremacyResAwardMailID, attachs=res)
				MailJoinableQueue.send(mail)

			next_grade = getattr(grade_cfg, 'nextSeasonGrade', 0) or grade_id or 1
			next_cfg = _get_grade_cfg(next_grade)
			next_score = getattr(next_cfg, 'score', 0) if next_cfg else 0

			data['grade'] = next_grade
			data['score'] = next_score
			data['res'] = {}
			data['last_product_time'] = nowtime_t()
			data['event'] = _default_event_data()
			data['enemies'] = []
			data['enemy_records'] = {}
			data['history'] = []
			data['top_battle_history'] = []
			data['history_num'] = (data.get('history_num', 0) or 0) + 1
			data['last_rank'] = []
			data['play_records'] = {}
			data.pop('battle_cache', None)

			if game and game.role:
				game.role.cross_supremacy_datas = data
			else:
				yield self.server.dbcGame.call_async('DBUpdate', 'Role', role_db_id, {'cross_supremacy_datas': data}, False)

		ObjectServerGlobalRecord.saveTitleRanks(TitleDefs.CrossSupremacy, roleRanks)
		raise Return(None)

	@classmethod
	@coroutine
	def onCrossCommit(cls, key, transaction):
		logger.info('ObjectCrossSupremacyGameGlobal.onCrossCommit %s %s', key, transaction)
		self = cls.Singleton
		if self is None:
			logger.warning('ObjectCrossSupremacyGameGlobal.onCrossCommit Singleton is None')
			raise Return(False)
		if self.cross_key != '' and self.cross_key != key:
			logger.warning('ObjectCrossSupremacyGameGlobal.onCrossCommit %s', self.cross_key)
			raise Return(False)
		cls.cleanHalfPeriod()
		self.cross_key = key
		raise Return(True)

	@classmethod
	def cross_client(cls, areaKey, cross_key=None):
		self = cls.getByAreaKey(areaKey)
		if cross_key is None:
			cross_key = self.cross_key
		if cross_key == '':
			return None
		container = self.server.container
		client = container.getserviceOrCreate(cross_key)
		return client

	@classmethod
	@coroutine
	def onCrossEvent(cls, event, key, data, sync):
		logger.info('ObjectCrossSupremacyGameGlobal.onCrossEvent %s %s', key, event)
		self = cls.getByAreaKey(key)
		if sync:
			self.round = sync['round']

		ret = {}
		if event == 'init':
			self.initCrossData(data.get('model', {}))
		elif event == 'prepare':
			ret['role_infos'] = self.onPrepare(key)
		elif event == 'start':
			self.initCrossData(data.get('model', {}))
			self.onStart()
		elif event == 'closed':
			self.onClosed(data.get('last_ranks', []), data.get('top_battle_history', []))
		elif event == 'finishAward':
			yield self.onFinishAward(data.get('role_ranks', {}), data.get('role_scores', {}), data.get('division_role_ranks', {}))

		raise Return(ret)

	@classmethod
	def getCrossGameModel(cls, areaKey):
		self = cls.getByAreaKey(areaKey)
		if self is None:
			return {
				'date': 0,
				'round': 'closed',
				'csvID': 0,
				'servers': [],
				'lastRanks': [],
			}
		servers = []
		if self._cross:
			servers = self.servers
		return {
			'date': self.date,
			'round': self.round,
			'csvID': self.csv_id,
			'servers': servers,
			'lastRanks': (self.last_ranks or [])[:10],
		}
