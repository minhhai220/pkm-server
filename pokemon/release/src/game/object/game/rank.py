#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from __future__ import absolute_import

from framework import nowtime_t
from framework.csv import csv
from framework.log import logger
from framework.object import ObjectCSVRange, ReloadHooker, ObjectDBase, db_property
from framework.helper import copyKV, WeightRandomObject, upperBound
from game import ServerError
from game.object import FeatureDefs, TitleDefs
from game.object.game.gain import ObjectGainAux
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.globaldata import WorldBossRoleAwardMailID, WorldBossUnionAwardMailID, WorldBossServerAwardMailID
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.union import ObjectUnion

import copy
from collections import namedtuple, defaultdict
from tornado.gen import coroutine, Return
from game.helper import getPWAwardVersion, getRandomTowerAwardVersion

#
# ObjectPWAwardRange
#

class ObjectPWAwardRange(ObjectCSVRange):
	CSVName = 'pwaward'
	RangeL = []

	@classmethod
	def classInit(cls):
		version = cls.getRangeLVersion()
		cls.RangeL = []
		if isinstance(cls.CSVName, (tuple, list)):
			csvR = csv
			for part in cls.CSVName:
				csvR = csvR[part]
		else:
			csvR = getattr(csv, cls.CSVName)
		for idx in csvR:
			cfg = csvR[idx]
			if cfg.version != version:
				continue
			cls.RangeL.append(cls(cfg))
		cls.RangeL.sort(key=lambda o: o.start)

	def __init__(self, cfg):
		ObjectCSVRange.__init__(self, cfg)
		self._periodAward = cfg.periodAward

	@property
	def periodAward(self):
		return self._periodAward

	@classmethod
	def getRangeLVersion(cls):
		return getPWAwardVersion()

#
# ObjectPWAwardEffect
#

class ObjectPWAwardEffect(ObjectGainAux):
	def __init__(self, game, award):
		ObjectGainAux.__init__(self, game, award)

	def gain(self, **kwargs):
		ObjectGainAux.gain(self, **kwargs)

class ObjectArenaFlopAwardRandom(object):

	WinFlopWeight = None
	LoseFlopWeight = None

	WinGroups = set()
	LoseGroups = set()

	FlopShowWeights = {} # {group: WeightRandomObject}

	@classmethod
	def classInit(cls):
		cls.WinFlopWeight = None
		cls.LoseFlopWeight = None
		cls.WinGroups = set()
		cls.LoseGroups = set()
		cls.FlopShowWeights = {}

		winWeights = []
		loseWeights = []
		showWeights = defaultdict(list)

		for idx in csv.pwflop_award:
			cfg = csv.pwflop_award[idx]
			flag = cfg.group[0]
			if flag == 'W':
				cls.WinGroups.add(cfg.group)
				winWeights.append((idx, cfg.weight))
			elif flag == 'L':
				cls.LoseGroups.add(cfg.group)
				loseWeights.append((idx, cfg.weight))
			showWeights[cfg.group].append((idx, cfg.showWeight))
		cls.WinFlopWeight = WeightRandomObject(winWeights)
		cls.LoseFlopWeight = WeightRandomObject(loseWeights)
		for k, weights in showWeights.iteritems():
			cls.FlopShowWeights[k] = WeightRandomObject(weights)

	@classmethod
	def flop(cls, iswin):
		if iswin:
			weightObj = cls.WinFlopWeight
			groups = cls.WinGroups
		else:
			weightObj = cls.LoseFlopWeight
			groups = cls.LoseGroups
		idx, _ = weightObj.getRandom()
		others = groups - set([csv.pwflop_award[idx].group])
		others = [cls.FlopShowWeights[o].getRandom()[0] for o in others]
		return {
			'award': csv.pwflop_award[idx].award,
			'show': [csv.pwflop_award[i].award for i in others],
		}

#
# ObjectRandomTowerAwardRange
#

class ObjectRandomTowerAwardRange(ObjectPWAwardRange):
	CSVName = ('random_tower', 'rank_award')
	RangeL = []

	def __init__(self, cfg):
		ObjectCSVRange.__init__(self, cfg)
		self._periodAward = cfg.periodAward

	@property
	def periodAward(self):
		return self._periodAward

	@classmethod
	def getRangeLVersion(cls):
		return getRandomTowerAwardVersion()


RankCache_Limit = 50
RankCardFight_Limit = 1000
#
# ObjectRankGlobal
#

class ObjectRankGlobal(ReloadHooker):

	Singleton = None

	Fields = {
		'fight': ('fighting_point', 'top6_cards'),
		'star': ('star', ),
		'pokedex': ('pokedex',),
		'endless': ('endless', 'fighting_point'),
		'abyss_endless': ('abyss_endless', 'fighting_point'),
		'craft': ('craft', ),
		'random_tower': ('random_tower', ),
		'yybox': ('box_point',),
		'achievement': ('achievement',),
		'snowball': ('snowball',),
		'mimicry': ('mimicry', 'score', 'boss_id', 'game_key', 'buff_ids', 'battle_cards'),
	}

	def __init__(self, dbc, rpcArena, serverAlias):
		self._dbc = dbc
		self._rpcArena = rpcArena
		self.serverAlias = serverAlias
		self._top50Info = {}
		self._top50Model = {} # top50 model [(id, model)]
		self._roleSlims = {} # {id: slim}
		self._inited = False

		if ObjectRankGlobal.Singleton is not None:
			raise ValueError('This is singleton object')
		ObjectRankGlobal.Singleton = self

	def _init_top50(self):
		for rankName in ('fight', 'star', 'pokedex', 'endless', 'abyss_endless', 'craft', 'random_tower', 'yybox', 'achievement', 'snowball', 'mimicry'):
			if rankName == 'yybox' and self.serverAlias:
				for gameKey in self.serverAlias:
					elements = self._dbc.call('DBGetRankSize', 'Rank_%s' % rankName, 1, RankCache_Limit, gameKey)
					self.setTopModel(rankName, elements, gameKey)
			else:
				elements = self._dbc.call('DBGetRankSize', 'Rank_%s' % rankName, 1, RankCache_Limit, '')
				self.setTopModel(rankName, elements)

	def setTopModel(self, rankName, elements, gameKey=''):
		iscardrank = rankName == 'card1fight'
		models = []
		# 获取字段列表，支持动态的 yybox_xxx 名称
		# Go 端已将动态字段映射为 box_point，所以这里统一使用 yybox 的字段定义
		fieldsKey = 'yybox' if rankName.startswith('yybox_') else rankName
		for element in elements:
			if iscardrank:
				models.append((element['id'], element))
			else:
				self._roleSlims[element['id']] = element['role']
				# 使用 get 处理老数据可能缺失的字段
				models.append((element['id'], {key: element.get(key) for key in self.Fields[fieldsKey]}))
		if gameKey:
			rankName = '%s_%s' % (rankName, gameKey.split('_')[-1])
		self._top50Model[rankName] = models

	def init(self):
		self._init_top50()
		self._refreshTop50('fight')
		self._refreshTop50('star')
		self._refreshTop50('pokedex')
		self._refreshTop50('endless')
		self._refreshTop50('abyss_endless')
		self._refreshTop50('craft')
		self._refreshTop50('random_tower')
		self._refreshTop50('achievement')
		self._refreshTop50('snowball')
		self._refreshTop50('mimicry')
		if self.serverAlias:
			for gameKey in self.serverAlias:
				self._refreshTop50('%s_%s' % ('yybox', gameKey.split('_')[-1]))
		else:
			self._refreshTop50('yybox')

		# init tiny rank
		names = ['huodong_1', 'huodong_2', 'huodong_3', 'huodong_4']
		self._tinys = {}
		for name in names:
			data = self._dbc.call('DBReadsert', 'TinyRank', {'name': name}, False)
			if not data['ret']:
				raise ServerError('db readsert TinyRank %s error' % name)
			rank = ObjectTinyRank(self._dbc)
			rank.set(data['model']).init()
			self._tinys[name] = rank

	def _refreshTop50(self, rankName):
		iscardrank = rankName == 'card1fight'
		top50 = []
		for roleID, model in self._top50Model[rankName]:
			if iscardrank:
				top50.append(model)
			else:
				slim = self._roleSlims[roleID]
				d = {
					'role': slim,
					'union_name': ObjectUnion.queryUnionName(roleID),
				}
				d.update(model)
				top50.append(d)
		self._top50Info[rankName] = top50

	@classmethod
	@coroutine
	def dayRefresh(cls):
		logger.info('rank dayRefresh')
		self = cls.Singleton

		# 活动副本小排行榜重置
		names = ['huodong_1', 'huodong_2', 'huodong_3', 'huodong_4']
		for name in names:
			self._tinys[name].clean()

		# 榜单保存，用于头衔
		from game.object.game.role import ObjectRole
		from game.object.game.servrecord import ObjectServerGlobalRecord
		maxRank = max(10, ObjectRole.getRankTitleMax(TitleDefs.Pokedex))
		ret = yield ObjectRankGlobal.getRankList('pokedex', 0, maxRank)
		ranks = {model['role']['id']: i for i, model in enumerate(ret, 1)}
		ObjectServerGlobalRecord.saveTitleRanks(TitleDefs.Pokedex, ranks)

		maxRank = max(10, ObjectRole.getRankTitleMax(TitleDefs.StarRank))
		ret = yield ObjectRankGlobal.getRankList('star', 0, maxRank)
		ranks = {model['role']['id']: i for i, model in enumerate(ret, 1)}
		ObjectServerGlobalRecord.saveTitleRanks(TitleDefs.StarRank, ranks)

		# 发试炼排行奖励
		from game.mailqueue import MailJoinableQueue
		from game.handler.inl_mail import getRankRandomTowerAwardMail

		ret = yield self._dbc.call_async('DBGetRankSize', 'Rank_random_tower', 1, 999999, '')
		randonTowerRanks = {model['role']['id']: i for i, model in enumerate(ret, 1)}
		for roleID, rank in randonTowerRanks.iteritems():
			mail = getRankRandomTowerAwardMail(roleID, rank)
			if mail:
				MailJoinableQueue.send(mail)

		self.rankClear('random_tower')

	@classmethod
	@coroutine
	def rankClear(cls, key):
		logger.info('rank:%s clear'%key)
		self = cls.Singleton
		self._top50Info[key] = []
		yield self._dbc.call_async('DBDrop','Rank_%s'%key) #清空

	@classmethod
	@coroutine
	def yyboxRefresh(cls, huodongID=None):
		"""清除限时神兽排行榜
		huodongID: 如果指定则只清除特定活动的排行榜(如 yybox_1012)，否则清除所有yybox排行榜
		"""
		self = cls.Singleton
		if huodongID:
			rankKey = 'yybox_%s' % huodongID
			logger.info('rank %s refresh', rankKey)
			for key in list(self._top50Info.keys()):
				if rankKey in key:
					self._top50Info[key] = []
			yield self._dbc.call_async('DBDrop', 'Rank_%s' % rankKey)
		else:
			logger.info('rank yybox refresh all')
			for key in list(self._top50Info.keys()):
				if 'yybox' in key:
					self._top50Info[key] = []
			# 清除所有yybox开头的排行榜
			yield self._dbc.call_async('DBDrop', 'Rank_yybox')

	@classmethod
	@coroutine
	def queryRank(cls, rankName, key, withInfo=False, tied=False, gameKey=''):
		# withInfo 原始数据信息
		# tied 并列排名
		self = cls.Singleton
		if rankName in self._tinys:
			ret = self._tinys[rankName].query(key)
		else:
			# 支持动态的 yybox_xxx 排行榜
			if rankName.startswith('yybox_') and self.serverAlias:
				gameKey = gameKey
			elif rankName == 'yybox' and self.serverAlias:
				gameKey = gameKey
			else:
				gameKey = ''
			ret = yield self._dbc.call_async('DBRank', 'Rank_%s'%rankName, key, tied, gameKey)
		if withInfo:
			raise Return(ret)
		raise Return(ret[0])

	@classmethod
	@coroutine
	def queryScore(cls, rankName, key):
		# TODO: check
		self = cls.Singleton
		ret = yield self._dbc.call_async('DBRedisZScore', 'Rank_%s'%rankName,key)
		raise Return(ret)

	@classmethod
	@coroutine
	def queryRankRoleInfo(cls, roleID):
		raise Exception('deprecated')

	@classmethod
	@coroutine
	def queryRankCardInfo(cls, cardID):
		self = cls.Singleton
		if cardID in self.card_models:
			raise Return(self.card_models[cardID])
		else:
			ret = yield self._dbc.call_async('DBReadSlimCards', [cardID])
			if not ret['ret']:
				raise Return(False)
			raise Return(ret['models'][0])

	@classmethod
	@coroutine
	def getRankList(cls, key, offest, size, gameKey=''):
		if offest + size > RankCardFight_Limit:
			raise Return([])

		self = cls.Singleton
		if key in self._tinys:
			raise Return(self._tinys[key].ranks[offest:offest + size])
		if offest + size <= RankCache_Limit:
			# 支持动态的 yybox_xxx 排行榜
			if key.startswith('yybox_') and self.serverAlias:
				cacheKey = '%s_%s' % (key, gameKey.split('_')[-1]) if gameKey else key
				if cacheKey in self._top50Info:
					raise Return(self._top50Info[cacheKey][offest:offest + size])
				else:
					raise Return([])
			elif key == 'yybox' and self.serverAlias:
				raise Return(self._top50Info['%s_%s' % ('yybox', gameKey.split('_')[-1])][offest:offest + size])
			elif key in self._top50Info:
				raise Return(self._top50Info[key][offest:offest + size])
			else:
				raise Return([])
		elif key == 'pvp':
			# 只能请求前50
			raise Return([])
		else:
			# 支持动态的 yybox_xxx 排行榜
			if key.startswith('yybox_') and self.serverAlias and gameKey:
				gameKey = gameKey
			elif key == 'yybox' and self.serverAlias and gameKey:
				gameKey = gameKey
			else:
				gameKey = ''
			ret = yield self._dbc.call_async('DBGetRankSize', 'Rank_' + key, offest + 1, offest + size, gameKey)
			if key != 'card1fight':
				for model in ret:
					model['union_name'] = ObjectUnion.queryUnionName(model['id'])
			raise Return(ret)

	@classmethod
	@coroutine
	def onClearRoleRank(cls, roleID):
		self = cls.Singleton
		keys = ['endless', 'pokedex', 'fight', 'star'] # endless, fight 要一起清理，endless会用到fight里的战力来显示
		yield self._dbc.call_async('DBRankClearRole', roleID, ['Rank_%s' % k for k in keys])
		for key in keys:
			elements = yield self._dbc.call_async('DBGetRankSize', 'Rank_%s' % key, 1, RankCache_Limit, '')
			self.setTopModel(key, elements)
			self._refreshTop50(key)

	@classmethod
	@coroutine
	def onKeyInfoChange(cls, game, key, args=None):
		self = cls.Singleton
		rank = None
		refresh = False # force refresh
		if key == 'pokedex':
			model = {
				'role': game.role.rankRoleModel,
				'pokedex': len(game.role.pokedex),
			}
			rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_pokedex', game.role.id, model, '')
			if rank != game.role.cardNum_rank:
				game.role.cardNum_rank = rank

		elif key == 'star':
			model = {
				'role': game.role.rankRoleModel,
				'star': game.role.gateStarSum,
			}
			rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_star', game.role.id, model, '')
			if rank != game.role.gate_star_rank:
				game.role.gate_star_rank = rank

		elif key == 'fight':
			top6 = []
			for cardID, card_id, skin_id in game.role.top12_cards[:6]:
				d = {'card_id': card_id, 'skin_id': skin_id, 'level': 0}
				if cardID:
					card = game.cards.getCard(cardID)
					d['level'] = card.level
				top6.append(d)
			model = {
				'role': game.role.rankRoleModel,
				'fighting_point': game.role.top6_fighting_point,
				'top6_cards': top6,
			}
			rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_fight', game.role.id, model, '')
			if rank != game.role.fight_rank:
				game.role.fight_rank = rank

		elif key.startswith('huodong_'): # 活动副本小排行榜
			self._tinys[key].update(game, args)

		elif key == 'endless':
			model = {
				'role': game.role.rankRoleModel,
				'endless': game.role.endless_tower_max_gate,
			}
			if game.role.endless_tower_max_gate > 0:
				rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_endless', game.role.id, model, '')
				if rank != game.role.endless_rank:
					game.role.endless_rank = rank

		elif key == 'abyss_endless':
			model = {
				'role': game.role.rankRoleModel,
				'abyss_endless': game.role.abyss_endless_tower_max_gate,
				'fighting_point': game.role.top6_fighting_point,
			}
			if game.role.abyss_endless_tower_max_gate > 0:
				rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_abyss_endless', game.role.id, model, '')
				if rank != game.role.abyss_endless_rank:
					game.role.abyss_endless_rank = rank

		elif key == 'mimicry':
			if game.mimicry and game.mimicry.db:
				bestScore = game.mimicry.best_score or 0
				bestBossID = game.mimicry.best_boss_id or 0
				
				# 获取该Boss的buff选择和战斗卡牌
				buffChoice = game.mimicry.buff_choice or {}
				buffIDs = buffChoice.get(bestBossID, []) or buffChoice.get(str(bestBossID), []) or []
				
				# 获取战斗阵容
				battleCards = game.mimicry.battle_cards or {}
				bossCards = battleCards.get(bestBossID, {}) or battleCards.get(str(bestBossID), {}) or {}
				
				# 转换为前端期望的格式 {"1": {card_csv_id, skin_id, star, fighting_point}, ...}
				# 注意：BSON的map键必须是字符串，前端Lua会自动转换
				battleCardsData = {}
				for pos, cardInfo in bossCards.iteritems():
					if cardInfo and isinstance(cardInfo, dict):
						battleCardsData[str(pos)] = {
							'card_csv_id': cardInfo.get('csv_id', 0),
							'skin_id': cardInfo.get('skin_id', 0),
							'star': cardInfo.get('star', 8),
							'fighting_point': cardInfo.get('fighting_point', 0),
						}
				
				# 获取该Boss的单次最高分
				historyScores = game.mimicry.history_scores or {}
				historyScore = historyScores.get(bestBossID, 0) or historyScores.get(str(bestBossID), 0) or 0
				
				model = {
					'role': game.role.rankRoleModel,
					'mimicry': bestScore,  # 累计最高分（用于排行榜排序）
					'score': historyScore,  # 单次最高分（前端显示"历史最高"）
					'boss_id': bestBossID,
					'game_key': game.role.areaKey,
					'buff_ids': list(buffIDs) if buffIDs else [],  # 选用的Buff
					'battle_cards': battleCardsData,  # 战斗阵容
				}
				if bestScore > 0:
					rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_mimicry', game.role.id, model, '')
					if rank != game.mimicry.mimicry_rank:
						game.mimicry.mimicry_rank = rank
					refresh = True  # 强制刷新缓存

		elif key == 'random_tower':
			model = {
				'role': game.role.rankRoleModel,
				'random_tower': {
					'day_point': game.randomTower.day_point,
					'room': game.randomTower.room,
				},
			}
			if game.randomTower.day_point > 0:
				rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_random_tower', game.role.id, model, '')

		elif key == 'achievement':
			model = {
				'role': game.role.rankRoleModel,
				'achievement': game.achievement.allAchievementPoints,
			}
			if game.achievement.allAchievementPoints > 0:
				rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_achievement', game.role.id, model, '')
				if rank != game.role.achievement_rank:
					game.role.achievement_rank = rank

		elif key == 'craft':
			models = {}
			for roleID, t in args.iteritems():
				round, win, point = t
				models[roleID] = {
					'craft': {
						'round': round,
						'win': win,
						'point': point,
					}
				}
			succeed = yield self._dbc.call_async('DBRankRoleAddBulk', 'Rank_craft', models)
			if len(models) != succeed:
				logger.warning('DBRankRoleAddBulk %s total %d succeed %d', 'Rank_craft', len(models), succeed)
			refresh = True

		elif key == 'card1fight':  # 需要优化，如果fightChangeCards数量多，会导致速度很慢
			maxrank = 199999999
			cards = list(game.cards.fightChangeCards) # may be changed during iteration
			game.cards.fightChangeCards.clear()
			# for card in cards:
			# 	rank = yield self._dbc.call_async('DBRankCardAdd', 'Rank_card1fight', card.id, card.rankModel)
			# 	if rank < maxrank: # 排名越小 即越大
			# 		maxrank = rank
			# rank = maxrank
			# if rank != game.role.card1fight_rank:
			# 	game.role.card1fight_rank = rank

		elif key.startswith('yybox_'):
			record = args
			huodongID = int(key.split('_')[1])
			model = {
				'role': game.role.rankRoleModel,
				'game_key': game.role.areaKey,
				'dynamic_box_point': {huodongID: record.get('box_point', 0)},
			}
			gameKey = game.role.areaKey if self.serverAlias else ''
			rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_%s' % key, game.role.id, model, gameKey)
			recordInfo = record.setdefault('info', {})
			if rank != recordInfo.get('rank', 0):
				recordInfo['rank'] = rank
			refresh = True
		elif key == 'snowball':
			info = args
			model = {
				'role': game.role.rankRoleModel,
				'snowball': {
					'point': info.get('top_point', 0),
					'time': info.get('top_time', 0),
					'role': info.get('top_role', 0),
				}
			}
			rank = yield self._dbc.call_async('DBRankRoleAdd', 'Rank_snowball', game.role.id, model, '')
			if rank != info.get('rank', 0):
				logger.info('role uid<%s> snow ball rank from %s to %s', game.role.uid, info.get('rank', 0), rank)
				info['rank'] = rank
			refresh = True

		if refresh or (rank and rank <= RankCache_Limit):
			# 支持动态的 yybox_xxx 排行榜
			if key.startswith('yybox_') and self.serverAlias:
				gameKey = game.role.areaKey
				elements = yield self._dbc.call_async('DBGetRankSize', 'Rank_%s' % key, 1, RankCache_Limit, gameKey)
				# 为动态排行榜创建缓存条目
				cacheKey = '%s_%s' % (key, gameKey.split('_')[-1])
				# 使用动态字段名：yybox_1012 -> box_point_1012
				if key.startswith('yybox_'):
					huodongID = key.split('_')[1]
					self.Fields[key] = ('box_point_%s' % huodongID,)
				elif key not in self.Fields:
					self.Fields[key] = ('box_point',)
				self.setTopModel(key, elements, gameKey)
				self._refreshTop50(cacheKey)
			else:
				elements = yield self._dbc.call_async('DBGetRankSize', 'Rank_%s' % key, 1, RankCache_Limit, '')
				self.setTopModel(key, elements, '')
				self._refreshTop50(key)


TinyRankLimit = 100

class ObjectTinyRank(ObjectDBase):
	DBModel = 'TinyRank'

	def __init__(self, dbc):
		ObjectDBase.__init__(self, None, dbc)

		self._existed = set()

	def init(self):
		if self.ranks:
			self._existed = {v['id'] for v in self.ranks}

	def update(self, game, score=0):
		role = game.role.rankRoleModel
		role['score'] = score
		role['lasttime'] = int(nowtime_t())

		if role['id'] in self._existed:
			for v in self.ranks:
				if v['id'] == role['id']:
					if role['score'] < v['score']:
						return
					v.update(role)
					break
			self.ranks.sort(key=lambda x: (x['score'], x['lasttime']), reverse=True)
		else:
			self.ranks.append(role)
			self._existed.add(role['id'])
			self.ranks.sort(key=lambda x: (x['score'], x['lasttime']), reverse=True)
			if len(self.ranks) > TinyRankLimit:
				self.ranks = self.ranks[:TinyRankLimit]
		# 强制触发数据库变更检测
		self.onDBModify('ranks')

	def query(self, roleID):
		if roleID in self._existed:
			for i, role in enumerate(self.ranks, 1):
				if role['id'] == roleID:
					return i, role['score']
		return 0, 0

	def clean(self):
		self.ranks = []
		self._existed = set()

	# 排行榜名字
	name = db_property('name')
	# 排行榜
	ranks = db_property('ranks')
