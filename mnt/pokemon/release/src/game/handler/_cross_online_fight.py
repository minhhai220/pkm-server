#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Cross Realtime Handlers
'''

from framework.csv import ErrDefs, csv, ConstDefs
from framework.log import logger
from framework.helper import transform2list
from framework.service.helper import game2onlinefight
from game import ClientError
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.handler._pvp import _normalize_battle_extra
from game.object import FeatureDefs, SceneDefs
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.gain import ObjectGainAux
from game.object.game.shop import ObjectCrossOnlineFightShop
from game.object.game.cross_online_fight import ObjectCrossOnlineFightGameGlobal

from tornado.gen import coroutine, Return, with_timeout
import datetime

@coroutine
def refreshCardsToCrossOnlineFight(rpc, game, cards=None, extra=None, force=False):
	if not game.role.cross_online_fight_record_db_id:
		raise Return(None)

	deployment = game.cards.deploymentForCrossOnlineFight
	if not any([force, cards, deployment.isdirty(), extra is not None]):
		raise Return(None)

	embattle = {}
	if cards:
		embattle['cards'] = cards
	cards, dirty = deployment.refresh('cards', SceneDefs.CrossOnlineFight, cards)
	embattle['card_attrs'], embattle['card_attrs2'] = game.cards.makeBattleCardModel(cards, SceneDefs.CrossOnlineFight, dirty=dirty)
	embattle['passive_skills'] = game.cards.markBattlePassiveSkills(cards, SceneDefs.CrossOnlineFight)
	
	# 为助战卡牌生成属性，合并到 card_attrs 中
	role = game.role
	aid_cards_dict = {}
	aid_fighting_point = 0
	if role.card_embattle and 'cross_online_fight' in role.card_embattle:
		aid_cards_dict = role.card_embattle['cross_online_fight'].get('aid_cards', {})
		# 兼容老数据（数组格式）
		if isinstance(aid_cards_dict, list):
			aid_cards_dict = {i+1: v for i, v in enumerate(aid_cards_dict) if v is not None}
		aid_cards_values = list(aid_cards_dict.values()) if isinstance(aid_cards_dict, dict) else []
		if aid_cards_values and len(aid_cards_values) > 0:
			aid_attrs, aid_attrs2 = game.cards.makeBattleCardModel(aid_cards_values, SceneDefs.CrossOnlineFight, is_aid=True)
			embattle['card_attrs'].update(aid_attrs)
			embattle['card_attrs2'].update(aid_attrs2)
			for aid_attr in aid_attrs.values():
				aid_fighting_point += aid_attr.get('aid_fighting_point', 0)
	embattle['aid_cards'] = aid_cards_dict
	embattle['aid_fighting_point'] = aid_fighting_point
	
	# 天气/兵种扩展数据（从 card_embattle 读取）
	extra_data = _normalize_battle_extra({'weather': 0, 'arms': []})
	if role.card_embattle and 'cross_online_fight' in role.card_embattle:
		extra_raw = role.card_embattle['cross_online_fight'].get('extra', {'weather': 0, 'arms': []})
		# 兼容数组格式（新格式）和字典格式（老格式）
		if isinstance(extra_raw, (list, tuple)) and len(extra_raw) > 0:
			extra_raw = extra_raw[0]
		elif isinstance(extra_raw, dict) and extra_raw:
			# 自动修复：把老格式 dict 转成数组格式
			card_embattle = role.card_embattle or {}
			card_embattle['cross_online_fight']['extra'] = [extra_raw]
			role.card_embattle = card_embattle
		extra_data = _normalize_battle_extra(extra_raw)
	if extra is not None:
		extra_data = _normalize_battle_extra(extra)
	embattle['extra'] = extra_data

	deployment.resetdirty()
	yield rpc.call_async('CrossOnlineFightDeployCards', game.role.cross_online_fight_record_db_id, game.role.competitor, embattle)

@coroutine
def getViewAndModel(rpcPVP, game):
	role = game.role
	areaKey = game.role.areaKey
	if not ObjectCrossOnlineFightGameGlobal.isOpen(areaKey):
		model = ObjectCrossOnlineFightGameGlobal.getLastSlimModel(areaKey)
		model['unlimited_history_top'] =  ObjectCrossOnlineFightGameGlobal.getRankList(0, 7, role.id, 1, role.areaKey)
		model['limited_history_top'] = ObjectCrossOnlineFightGameGlobal.getRankList(0, 7, role.id, 2, role.areaKey)
		cache = ObjectCrossOnlineFightGameGlobal.getRoleCacheInfo(role)
		if cache:
			model.update(cache)
	else:
		if len(role.cross_online_fight_limited_cards) == 0:
			cards = ObjectCrossOnlineFightGameGlobal.makeLimitedBattleCards(game)
			if cards:
				role.cross_online_fight_limited_cards = cards

		rpc = ObjectCrossOnlineFightGameGlobal.cross_client(areaKey)
		resp = yield rpc.call_async('CrossOnlineFightMainGet', role.crossRole(role.cross_online_fight_record_db_id))
		model = resp.pop('model', {})

		if 'match_result' not in model: # 清理上次战斗结果 future
			ObjectCrossOnlineFightGameGlobal.popLastBattleResult(role)

		# TODO: 当前赛季第一次进入，历史数据清理
		ObjectCrossOnlineFightGameGlobal.refreshRoleCrossOnlineFightInfo(game)

	record = yield rpcPVP.call_async('GetCrossOnlineFightRecord', role.cross_online_fight_record_db_id)
	model.update(cards=record['cards'], unlimited_history=record['unlimited_history'], limited_history=record['limited_history'])

	raise Return((None, model))

# 实时对战进主界面
class CrossOnlineFightMain(RequestHandlerTask):
	url = r'/game/cross/online/main'

	@coroutine
	def run(self):
		if not ObjectCrossOnlineFightGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.levelLessNoOpened)

		role = self.game.role
		if len(role.top_cards) < 12:
			raise ClientError('not enough cards')

		if not role.cross_online_fight_record_db_id:
			cards = role.top_cards[:6]
			cardsD, cardsD2 = self.game.cards.makeBattleCardModel(cards, SceneDefs.CrossOnlineFight)
			passiveSkills = self.game.cards.markBattlePassiveSkills(cards, SceneDefs.CrossOnlineFight)
			embattle = {
				'cards': cards,
				'card_attrs': cardsD,
				'card_attrs2': cardsD2,
				'passive_skills': passiveSkills,
				'extra': {'weather': 0, 'arms': []},
			}
			role.cross_online_fight_record_db_id = yield self.rpcPVP.call_async('CreateCrossOnlineFightRecord', role.competitor, embattle)
			role.deployments_sync['cross_online_fight'] = True # 默认同步

			deployment = self.game.cards.deploymentForCrossOnlineFight
			deployment.deploy('cards', cards)
		else:
			yield refreshCardsToCrossOnlineFight(self.rpcPVP, self.game)

		view, model = yield getViewAndModel(self.rpcPVP, self.game)
		self.write({
			'model': {
				'cross_online_fight': model,
			},
			'view': view,
		})

# 实时对战开始匹配
class CrossOnlineFightMatching(RequestHandlerTask):
	url = r'/game/cross/online/matching'

	@coroutine
	def run(self):
		if not ObjectCrossOnlineFightGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError("not open")

		if not ObjectCrossOnlineFightGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.levelLessNoOpened)

		pattern = self.input.get('pattern', None)
		patch = self.input.get('patch', 0)
		if pattern not in (1, 2):
			raise ClientError('pattern error')
		longtimeout = self.input.get('longtimeout', False)

		if self.game.dailyRecord.cross_online_fight_times >= ObjectCrossOnlineFightGameGlobal.MatchTimeMax:
			raise ClientError('times not enough')

		if pattern == 2:
			if len(self.game.role.cross_online_fight_limited_cards) < ObjectCrossOnlineFightGameGlobal.LeastCardNum:
				raise ClientError(ErrDefs.onlineFightNotEnoughCards)
			if not ObjectCrossOnlineFightGameGlobal.checkLimitedBattleCards(self.game, self.game.role.cross_online_fight_limited_cards):
				raise ClientError(ErrDefs.onlineFightLimitedCardsUnqualified)

		if longtimeout:
			timeout = ObjectCrossOnlineFightGameGlobal.LongMatchTimeout
		else:
			timeout = ObjectCrossOnlineFightGameGlobal.NormalMatchTimeout
		rpc = ObjectCrossOnlineFightGameGlobal.cross_client(self.game.role.areaKey)
		resp = yield rpc.call_async('CrossOnlineFightMatchStart', self.game.role.id, pattern, self.game.role.cross_online_fight_limited_cards, patch, timeout)
		model = resp.pop('model', {})
		self.write({
			'model': {
				'cross_online_fight': model,
			},
		})

# 实时对战取消匹配
class CrossOnlineFightCancel(RequestHandlerTask):
	url = r'/game/cross/online/cancel'

	@coroutine
	def run(self):
		if not ObjectCrossOnlineFightGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError("not open")

		if not ObjectCrossOnlineFightGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.levelLessNoOpened)

		rpc = ObjectCrossOnlineFightGameGlobal.cross_client(self.game.role.areaKey)
		yield rpc.call_async('CrossOnlineFightMatchCancel', self.game.role.id)

		self.write({
			'model': {
				'cross_online_fight': {
					'match_result': {'matching': 0},
				},
			},
		})

# 实时对战获取战斗结果
class CrossOnlineFightBattleEnd(RequestHandlerTask):
	url = r'/game/cross/online/battle/end'

	@coroutine
	def run(self):
		future = ObjectCrossOnlineFightGameGlobal.getLastBattleResultFuture(self.game.role)
		if not future:
			raise ClientError('no battle result')
		view = yield with_timeout(datetime.timedelta(seconds=30), future)
		ObjectCrossOnlineFightGameGlobal.popLastBattleResult(self.game.role)
		_, model = yield getViewAndModel(self.rpcPVP, self.game)
		model['match_result'] = {'matching': 0}
		self.write({
			'model': {
				'cross_online_fight': model,
			},
			'view': view,
		})

# 实时对战部署
class CrossOnlineFightDeploy(RequestHandlerTask):
	url = r'/game/cross/online/deploy'

	@coroutine
	def run(self):
		cards = self.input.get('cards', None)
		if cards is None:
			raise ClientError('battleCardIDs is error')
		pattern = self.input.get('pattern', 1)
		aidCards = self.input.get('aidCards', None)
		extra = self.input.get('extra', None)
		extra_param = None
		force_refresh = False
		role = self.game.role

		if pattern == 1: # 无限制赛部署
			cards = transform2list(cards, least=6)
			cardsLen = len(filter(None, cards))
			if cardsLen < 1:
				raise ClientError('cards not enough')

			if self.game.cards.isDuplicateMarkID(cards):
				raise ClientError('cards have duplicates')
			if not ObjectCrossOnlineFightGameGlobal.checkUnlimitedBattleCards(self.game, cards):
				raise ClientError('card error1')
			
			# 保存助战卡牌到 card_embattle（字典格式）
			if aidCards is not None:
				if isinstance(aidCards, dict):
					aid_dict = {k: v for k, v in aidCards.iteritems() if v is not None}
				else:
					aid_dict = {i+1: v for i, v in enumerate(aidCards) if v is not None}
				card_embattle = self.game.role.card_embattle
				if card_embattle is None:
					card_embattle = {}
				if 'cross_online_fight' not in card_embattle:
					card_embattle['cross_online_fight'] = {}
				card_embattle['cross_online_fight']['aid_cards'] = aid_dict
				force_refresh = True
			if extra is not None:
				extra_param = _normalize_battle_extra(extra)
				card_embattle['cross_online_fight']['extra'] = [extra_param]  # Go 端期望数组 []*BattleExtra
				force_refresh = True
				self.game.role.card_embattle = card_embattle
			elif self.game.role.card_embattle and 'cross_online_fight' in self.game.role.card_embattle:
				extra_raw = self.game.role.card_embattle['cross_online_fight'].get('extra', None)
				# 兼容数组格式（新格式）和字典格式（老格式）
				if isinstance(extra_raw, (list, tuple)) and len(extra_raw) > 0:
					extra_param = extra_raw[0]
				else:
					extra_param = extra_raw

			self.game.role.deployments_sync['cross_online_fight'] = False
			yield refreshCardsToCrossOnlineFight(self.rpcPVP, self.game, cards=cards, extra=extra_param, force=force_refresh)

			# 回填最新助战/天气信息
			card_embattle = role.card_embattle or {}
			cof_embattle = card_embattle.get('cross_online_fight', {}) if isinstance(card_embattle, dict) else {}
			ret_extra_raw = cof_embattle.get('extra', {'weather': 0, 'arms': []})
			# 兼容数组格式（新格式）和字典格式（老格式）
			if isinstance(ret_extra_raw, (list, tuple)) and len(ret_extra_raw) > 0:
				ret_extra = ret_extra_raw[0]
			else:
				ret_extra = ret_extra_raw if isinstance(ret_extra_raw, dict) else {'weather': 0, 'arms': []}
			ret_aid_cards = cof_embattle.get('aid_cards', {})

			self.write({
				'model': {
					'cross_online_fight': {
						'cards': cards,
						'aid_cards': ret_aid_cards,
						'extra': ret_extra,
					},
				}
			})

		else: # 公平赛部署
			if not ObjectCrossOnlineFightGameGlobal.checkLimitedBattleCards(self.game, cards, least=0):
				raise ClientError('card error')
			self.game.role.cross_online_fight_limited_cards = cards

# 实时对战录像数据
class CrossOnlineFightPlayRecordGet(RequestHandlerTask):
	url = r'/game/cross/online/playrecord/get'

	@coroutine
	def run(self):
		from framework.helper import string2objectid

		recordID = self.input.get('recordID', None)
		crossKey = self.input.get('crossKey', None)
		if recordID is None or crossKey is None:
			raise ClientError('param miss')

		# 保存原始 recordID 用于返回
		originalRecordID = recordID

		# 如果是 24 字符的十六进制字符串，转换为 ObjectId
		# 如果是 12 字节的二进制字符串，它已经是 ObjectId 格式，无需转换
		if isinstance(recordID, basestring) and len(recordID) == 24:
			recordID = string2objectid(recordID)

		# crossKey 可能是 game.cn.1，需要转换为 onlinefight.cn.1
		onlineFightKey = game2onlinefight(crossKey)
		rpc = ObjectCrossOnlineFightGameGlobal.cross_client(self.game.role.areaKey, cross_key=onlineFightKey)
		if rpc is None:
			raise ClientError('not existed')
		model = yield rpc.call_async('GetCrossOnlineFightPlayRecord', recordID)
		if not model:
			raise ClientError('not existed')
		self.write({'model': {'cross_online_fight_playrecords': {originalRecordID: model}}})

# 实时对战排行榜
class CrossOnlineFightRank(RequestHandlerTask):
	url = r'/game/cross/online/rank'

	@coroutine
	def run(self):
		pattern = self.input.get('pattern', 1)
		offest = self.input.get('offest', 0)
		size = self.input.get('size', 64)

		areaKey = self.game.role.areaKey
		if ObjectCrossOnlineFightGameGlobal.isOpen(areaKey):
			rpc = ObjectCrossOnlineFightGameGlobal.cross_client(areaKey)
			ret =  yield rpc.call_async('CrossOnlineFightGetRank', self.game.role.id, pattern, offest, size)
			ranks = ret['view'].pop('ranks', [])
		else:
			ranks = ObjectCrossOnlineFightGameGlobal.getRankList(offest, size, self.game.role.id, pattern, areaKey)

		self.write({
			'view': {
				'rank': ranks,
			}
		})

# 实时对战每周目标奖励
class CrossOnlineFightWeeklyTargetAward(RequestHandlerTask):
	url = r'/game/cross/online/weekly/target'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		if not ObjectCrossOnlineFightGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError("not open")

		info = self.game.role.cross_online_fight_info
		info.setdefault('weekly_target', {})
		flag = info['weekly_target'].get(csvID, None)
		if flag == 0:
			raise ClientError('already get')
		if flag != 1:
			raise ClientError('cant not get')

		cfg = csv.cross.online_fight.weekly_target[csvID]
		info['weekly_target'][csvID] = 0
		eff = ObjectGainAux(self.game, cfg.award)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='online_fight_weekly_award')
		self.write({
			'view': eff.result,
		})

# 实时对战商店购买
class CrossOnlineFightShopBuy(RequestHandlerTask):
	url = r'/game/cross/online/shop/buy'

	@coroutine
	def run(self):
		if not ObjectCrossOnlineFightGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.levelLessNoOpened)

		csvID = self.input.get('csvID', None)
		count = self.input.get('count', 1)
		if csvID is None:
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')

		shop = ObjectCrossOnlineFightShop(self.game)
		eff = shop.buyItem(csvID, count, src='cross_online_fight_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_online_fight_shop_buy')
