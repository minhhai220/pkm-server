#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

PVP Handlers
'''

import datetime
import time as time_module
from framework import nowtime_t, int2date
from framework.csv import csv, ErrDefs
from framework.log import logger
from framework.helper import transform2list
from framework.service.helper import game2pvp, game2crossmine

from game import ClientError
from game.globaldata import CrossMineBossHuodongID
from game.handler import RequestHandlerTask

# 跨服商业街每队助战位置数（需与 csv.aid.scene[23].aidUnlockLevel 长度一致）
CROSS_MINE_AID_NUM_MAX = 2
from game.handler.inl import effectAutoGain, effectAutoCost
from game.handler._pvp import _normalize_battle_extra
from game.object import SceneDefs
from game.object.game import ObjectGame, ObjectCostCSV
from game.object.game.cross_mine import ObjectCrossMineGameGlobal
from game.object.game.shop import ObjectCrossMineShop
from game.object.game.gain import ObjectCostAux, ObjectGainAux

from tornado.gen import coroutine, Return


def hhmm_to_seconds(hhmm):
	"""
	将HHMM格式转换为相对于当天0点的秒数
	例如: 1000 -> 10:00 -> 36000秒
	"""
	hhmm = int(hhmm)
	hours = hhmm // 100
	minutes = hhmm % 100
	return hours * 3600 + minutes * 60


def calcBlackjackOpenTime(crossMineDateInt):
	"""
	根据跨服资源战开始日期计算21点游戏开放时间
	crossMineDateInt: 日期整数格式，如 20241207
	返回 [[start1, end1], [start2, end2], [start3, end3]] 对应3天的开放时间戳
	"""
	if 1 not in csv.cross.mine.blackjack_base:
		return []
	blackjack_cfg = csv.cross.mine.blackjack_base[1]

	# openTime 格式: [[1000, 2000], [1200, 2200]] - HHMM格式，如1000=10:00，2000=20:00
	open_time_cfg = getattr(blackjack_cfg, 'openTime', None) or []
	if not open_time_cfg:
		return []

	# 将日期整数转换为当天0点的时间戳（与前端 time.getNumTimestamp(date) 一致）
	base_date = int2date(crossMineDateInt)
	base_datetime = datetime.datetime.combine(base_date, datetime.time(hour=0, minute=0, second=0))
	base_timestamp = int(time_module.mktime(base_datetime.timetuple()))

	result = []
	day_seconds = 86400  # 一天的秒数

	for day_idx in range(3):  # 3天
		day_start = base_timestamp + day_idx * day_seconds
		if day_idx < len(open_time_cfg):
			time_range = open_time_cfg[day_idx]
			if isinstance(time_range, (list, tuple)) and len(time_range) >= 2:
				start_offset = hhmm_to_seconds(time_range[0])
				end_offset = hhmm_to_seconds(time_range[1])
				result.append([day_start + start_offset, day_start + end_offset])
			else:
				result.append([])
		else:
			# 如果配置不足3天，使用最后一个配置
			if open_time_cfg:
				last_cfg = open_time_cfg[-1]
				if isinstance(last_cfg, (list, tuple)) and len(last_cfg) >= 2:
					start_offset = hhmm_to_seconds(last_cfg[0])
					end_offset = hhmm_to_seconds(last_cfg[1])
					result.append([day_start + start_offset, day_start + end_offset])
				else:
					result.append([])
			else:
				result.append([])

	return result


def _normalize_cross_mine_extra_list(raw, team_count=3):
	"""
	兼容数组/单个字典，返回长度 team_count 的列表，每个元素为规范化的 battle_extra
	"""
	if isinstance(raw, (list, tuple)):
		out = []
		for idx in range(team_count):
			out.append(_normalize_battle_extra(raw[idx] if idx < len(raw) else None))
		return out
	return [_normalize_battle_extra(raw) for _ in range(team_count)]


def _fill_cross_mine_extra(record, role=None):
	if not isinstance(record, dict):
		return
	# 优先从 card_embattle 还原数组（可保存三队不同配置）
	if role and role.card_embattle and 'cross_mine' in role.card_embattle:
		embattle_extra = role.card_embattle['cross_mine'].get('extra', None)
		embattle_defence_extra = role.card_embattle['cross_mine'].get('defence_extra', None)
		if embattle_extra is not None:
			record['extra'] = _normalize_cross_mine_extra_list(embattle_extra)
		if embattle_defence_extra is not None:
			record['defence_extra'] = _normalize_cross_mine_extra_list(embattle_defence_extra)

	extra_in = record.get('extra', None)
	defence_in = record.get('defence_extra', None)
	record['extra'] = _normalize_cross_mine_extra_list(extra_in)
	record['defence_extra'] = _normalize_cross_mine_extra_list(defence_in)


@coroutine
def makeCrossMineModel(game, rpc, refresh, rpcPVP):
	role = game.role
	if not role.cross_mine_record_db_id:
		raise Return({'cross_mine': {}})

	model = {}

	record = yield rpcPVP.call_async('GetCrossMineRecord', role.cross_mine_record_db_id)
	model['record'] = record
	_fill_cross_mine_extra(model['record'], role=role)
	if ObjectCrossMineGameGlobal.isOpen(role.areaKey):
		# 阵容有为空特殊情况处理
		cards = model['record']['cards']
		defenceCards = model['record']['defence_cards']
		cardsNeedRefresh = any(v == 0 or v > 4 for v in [len(filter(None, cards[i])) for i in range(1, 3 + 1)])
		defenceCardsNeedRefresh = any(v == 0 or v > 4 for v in [len(filter(None, defenceCards[i])) for i in range(1, 3 + 1)])
		if cardsNeedRefresh or defenceCardsNeedRefresh:
			cardsMap, _ = ObjectCrossMineGameGlobal.getCrossMineCards(role)
			newCards = None
			newDefenceCards = None
			if cardsNeedRefresh:
				newCards = list(cardsMap[1])  # 使用 list() 复制，避免引用问题
				newCards.extend(cardsMap[2])
				newCards.extend(cardsMap[3])
			if defenceCardsNeedRefresh:
				newDefenceCards = list(cardsMap[1])  # 使用 list() 复制，避免引用问题
				newDefenceCards.extend(cardsMap[2])
				newDefenceCards.extend(cardsMap[3])
			yield refreshCardsToCrossMine(rpcPVP, game, cards=newCards, defence_cards=newDefenceCards)
			record = yield rpcPVP.call_async('GetCrossMineRecord', role.cross_mine_record_db_id)
			model['record'] = record

		crossMineRoleInfo = game.role.crossRole(game.role.cross_mine_record_db_id)
		crossMineRoleInfo['fighting_point'] = game.role.top12_fighting_point
		resp = yield rpc.call_async('CrossMineGetModel', role.id, crossMineRoleInfo, refresh)
		yield ObjectCrossMineGameGlobal.SyncCoin13(game)
		model.update(resp)

		if resp['isNew']:
			yield rpcPVP.call_async('CleanCrossMineHistory', role.cross_mine_record_db_id)
			model['record']['history'] = []
	else:
		model.update(ObjectCrossMineGameGlobal.getLastSlimModel(role.areaKey))

	model.update(ObjectCrossMineGameGlobal.getCrossGameModel(role.areaKey))

	# 计算21点开放时间
	crossMineDate = model.get('date', 0)
	if crossMineDate:
		blackjack_open_time = calcBlackjackOpenTime(crossMineDate)
		role.cross_mine_blackjack_open_time = blackjack_open_time

	raise Return({
		'cross_mine': model,
	})


@coroutine
def refreshCardsToCrossMine(rpc, game, cards=None, defence_cards=None, extra=None, defence_extra=None, force=False):
	if not game.role.cross_mine_record_db_id:
		raise Return(None)
	deployment = game.cards.deploymentForCrossMine
	# 卡牌没发生改变
	if not any([force, cards, defence_cards, deployment.isdirty(), extra is not None, defence_extra is not None]):
		raise Return(None)

	embattle = {}

	# 进攻阵容
	if cards:
		cardsMap = {}  # {1:[card.id], 2:[card.id]}
		cardsMap[1] = transform2list(cards[:6])
		cardsMap[2] = transform2list(cards[6:12])
		cardsMap[3] = transform2list(cards[12:18])
		embattle['cards'] = cardsMap
	cards, dirty = deployment.refresh('cards', SceneDefs.CrossMine, cards)
	cardAttrs, cardAttrs12 = game.cards.makeBattleCardModel(cards[:6], SceneDefs.CrossMine, dirty=dirty[:6] if dirty else None)
	cardAttrs2, cardAttrs22 = game.cards.makeBattleCardModel(cards[6:12], SceneDefs.CrossMine, dirty=dirty[6:12] if dirty else None)
	cardAttrs3, cardAttrs32 = game.cards.makeBattleCardModel(cards[12:18], SceneDefs.CrossMine, dirty=dirty[12:18] if dirty else None)
	cardAttrs.update(cardAttrs2)
	cardAttrs.update(cardAttrs3)
	cardAttrs12.update(cardAttrs22)
	cardAttrs12.update(cardAttrs32)
	embattle['card_attrs'] = cardAttrs
	embattle['card_attrs2'] = cardAttrs12
	embattle['passive_skills'] = game.cards.markBattlePassiveSkills(cards, SceneDefs.CrossMine)

	# 防守阵容
	if defence_cards:
		defenceCardsMap = {}
		defenceCardsMap[1] = transform2list(defence_cards[:6])
		defenceCardsMap[2] = transform2list(defence_cards[6:12])
		defenceCardsMap[3] = transform2list(defence_cards[12:18])
		embattle['defence_cards'] = defenceCardsMap
	defence_cards, defence_dirty = deployment.refresh('defence_cards', SceneDefs.CrossMine, defence_cards)
	defenceCardAttrs, defenceCardAttrs12 = game.cards.makeBattleCardModel(defence_cards[:6], SceneDefs.CrossMine, dirty=defence_dirty[:6] if defence_dirty else None)
	defenceCardAttrs2, defenceCardAttrs22 = game.cards.makeBattleCardModel(defence_cards[6:12], SceneDefs.CrossMine, dirty=defence_dirty[6:12] if defence_dirty else None)
	defenceCardAttrs3, defenceCardAttrs32 = game.cards.makeBattleCardModel(defence_cards[12:18], SceneDefs.CrossMine, dirty=defence_dirty[12:18] if defence_dirty else None)
	defenceCardAttrs.update(defenceCardAttrs2)
	defenceCardAttrs.update(defenceCardAttrs3)
	defenceCardAttrs12.update(defenceCardAttrs22)
	defenceCardAttrs12.update(defenceCardAttrs32)
	embattle['defence_card_attrs'] = defenceCardAttrs
	embattle['defence_card_attrs2'] = defenceCardAttrs12
	embattle['defence_passive_skills'] = game.cards.markBattlePassiveSkills(defence_cards, SceneDefs.CrossMine)
	
	# 助战卡牌数据 - 总是发送，和天气逻辑保持一致
	role = game.role
	aid_cards = {}
	defence_aid_cards = {}
	aid_fighting_point = 0
	defence_aid_fighting_point = 0
	if role.card_embattle and 'cross_mine' in role.card_embattle:
		aid_cards = role.card_embattle['cross_mine'].get('aid_cards', {})
		defence_aid_cards = role.card_embattle['cross_mine'].get('defence_aid_cards', {})
		
		# 从字典中提取有效的卡牌ID列表（用于生成属性）
		aid_card_ids = [v for v in aid_cards.values() if v] if isinstance(aid_cards, dict) else filter(None, aid_cards)
		defence_aid_card_ids = [v for v in defence_aid_cards.values() if v] if isinstance(defence_aid_cards, dict) else filter(None, defence_aid_cards)
		
		# 为助战卡牌生成属性，合并到 card_attrs 中，并计算总战力
		if aid_card_ids:
			aid_attrs, aid_attrs2 = game.cards.makeBattleCardModel(aid_card_ids, SceneDefs.CrossMine, is_aid=True)
			embattle['card_attrs'].update(aid_attrs)
			embattle['card_attrs2'].update(aid_attrs2)
			for aid_attr in aid_attrs.values():
				aid_fighting_point += aid_attr.get('aid_fighting_point', 0)
		if defence_aid_card_ids:
			aid_attrs, aid_attrs2 = game.cards.makeBattleCardModel(defence_aid_card_ids, SceneDefs.CrossMine, is_aid=True)
			embattle['defence_card_attrs'].update(aid_attrs)
			embattle['defence_card_attrs2'].update(aid_attrs2)
			for aid_attr in aid_attrs.values():
				defence_aid_fighting_point += aid_attr.get('aid_fighting_point', 0)
	
	# 使用模块级别的函数转换助战数据格式
	embattle['aid_cards'] = _convertAidCardsToNested(aid_cards)
	embattle['defence_aid_cards'] = _convertAidCardsToNested(defence_aid_cards)
	embattle['aid_fighting_point'] = aid_fighting_point
	embattle['defence_aid_fighting_point'] = defence_aid_fighting_point
	
	# 天气/兵种扩展数据（从 card_embattle 读取）- 跨服商业街有3个队伍
	default_extra = _normalize_cross_mine_extra_list({'weather': 0, 'arms': []})
	extra_data = default_extra
	defence_extra_data = default_extra
	need_fix = False
	if role.card_embattle and 'cross_mine' in role.card_embattle:
		extra_raw = role.card_embattle['cross_mine'].get('extra', {'weather': 0, 'arms': []})
		defence_extra_raw = role.card_embattle['cross_mine'].get('defence_extra', {'weather': 0, 'arms': []})
		# 兼容老格式（dict）和不完整数组
		if not isinstance(extra_raw, (list, tuple)) or len(extra_raw) != 3:
			need_fix = True
		if not isinstance(defence_extra_raw, (list, tuple)) or len(defence_extra_raw) != 3:
			need_fix = True
		extra_data = _normalize_cross_mine_extra_list(extra_raw)
		defence_extra_data = _normalize_cross_mine_extra_list(defence_extra_raw)
		# 自动修复老格式
		if need_fix:
			card_embattle = role.card_embattle or {}
			card_embattle['cross_mine']['extra'] = extra_data
			card_embattle['cross_mine']['defence_extra'] = defence_extra_data
			role.card_embattle = card_embattle
	# 如果传入新配置，用新值覆盖
	if extra is not None:
		extra_data = _normalize_cross_mine_extra_list(extra)
	if defence_extra is not None:
		defence_extra_data = _normalize_cross_mine_extra_list(defence_extra)
	embattle['extra'] = extra_data
	embattle['defence_extra'] = defence_extra_data

	deployment.resetdirty()
	yield rpc.call_async('CrossMineDeployCards', game.role.cross_mine_record_db_id, game.role.competitor, embattle)

	if ObjectCrossMineGameGlobal.isOpen(game.role.areaKey):
		crossRpc = ObjectCrossMineGameGlobal.cross_client(game.role.areaKey)
		yield crossRpc.call_async('CrossMineUpdateRoleInfo', game.role.crossRole(game.role.cross_mine_record_db_id), game.role.top12_fighting_point)


# 跨服资源战主界面
class CrossMineMain(RequestHandlerTask):
	url = r'/game/cross/mine/main'

	@coroutine
	def run(self):
		role = self.game.role
		if not ObjectCrossMineGameGlobal.isRoleOpen(role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		refresh = self.input.get('refresh', False)

		if role.cross_mine_record_db_id is None:
			cardsMap, cards = ObjectCrossMineGameGlobal.getCrossMineCards(role)
			passiveSkills = self.game.cards.markBattlePassiveSkills(cards, SceneDefs.CrossMine)

			cardAttrs, cardAttrs12 = self.game.cards.makeBattleCardModel(cardsMap[1], SceneDefs.CrossMine)
			cardAttrs2, cardAttrs22 = self.game.cards.makeBattleCardModel(cardsMap[2], SceneDefs.CrossMine)
			cardAttrs3, cardAttrs32 = self.game.cards.makeBattleCardModel(cardsMap[3], SceneDefs.CrossMine)
			cardAttrs.update(cardAttrs2)
			cardAttrs.update(cardAttrs3)
			cardAttrs12.update(cardAttrs22)
			cardAttrs12.update(cardAttrs32)

			embattle = {
				'cards': cardsMap,
				'card_attrs': cardAttrs,
				'card_attrs2': cardAttrs12,
				'passive_skills': passiveSkills,
				'defence_cards': cardsMap,
				'defence_card_attrs': cardAttrs,
				'defence_card_attrs2': cardAttrs12,
				'defence_passive_skills': passiveSkills,
			}
			role.cross_mine_record_db_id = yield self.rpcPVP.call_async('CreateCrossMineRecord', role.competitor, embattle)

			deployment = self.game.cards.deploymentForCrossMine
			deployment.deploy('cards', transform2list(cards, 18))
			deployment.deploy('defence_cards', transform2list(cards, 18))
		else:
			if refresh:
				coin13Cost = ObjectCostCSV.getCrossMineEnemyFreshCost(self.game.dailyRecord.cross_mine_enemy_refresh_times)
				cost = ObjectCostAux(self.game, {'coin13': coin13Cost})
				yield effectAutoCost(cost, self.game, src='cross_mine_enemy_refresh', errDef=ErrDefs.costNotEnough)
				self.game.dailyRecord.cross_mine_enemy_refresh_times += 1
			yield refreshCardsToCrossMine(self.rpcPVP, self.game)

		rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
		model = yield makeCrossMineModel(self.game, rpc, refresh, self.rpcPVP)
		_fillAidCardsToModel(model, role)
		self.write({'model': model})


# 将扁平化的助战数组转换成嵌套结构（3个队伍）
# 前端发送格式：{1: cardId, 7: cardId, ...} 或 [cardId1, cardId2, ...]
# 后端需要格式：{1: [cardId1, cardId2], 2: [...], 3: [...]}
def _convertAidCardsToNested(flat_aids, aidNumMax=2):
	"""
	将扁平化的助战数组转换成嵌套字典结构（3个队伍）
	Go端期望格式: {1: {1: cardID, 2: cardID}, 2: {...}, 3: {...}}
	跨服商业街每队2个助战位置，aidNumMax=2
	"""
	result = {1: {}, 2: {}, 3: {}}
	if not flat_aids:
		return result
	for team in [1, 2, 3]:
		base = (team - 1) * aidNumMax
		for j in range(1, aidNumMax + 1):
			idx = base + j
			if isinstance(flat_aids, dict):
				card_id = flat_aids.get(idx, None)
			else:
				card_id = flat_aids[idx - 1] if idx - 1 < len(flat_aids) else None
			if card_id is not None:
				result[team][j] = card_id  # 只保存非None的值
	return result


# 填充助战数据到 model（总是从 card_embattle 读取，保留位置信息）
# Go 返回的数据丢失了位置信息，所以必须从 card_embattle 读取原始数据进行转换
def _fillAidCardsToModel(model, role):
	aidNumMax = CROSS_MINE_AID_NUM_MAX
	if 'cross_mine' in model and 'record' in model['cross_mine']:
		record = model['cross_mine']['record']
		if role.card_embattle and 'cross_mine' in role.card_embattle:
			flat_aids = role.card_embattle['cross_mine'].get('aid_cards', {})
			flat_defence_aids = role.card_embattle['cross_mine'].get('defence_aid_cards', {})
			record['aid_cards'] = _convertAidCardsToNested(flat_aids, aidNumMax)
			record['defence_aid_cards'] = _convertAidCardsToNested(flat_defence_aids, aidNumMax)
		else:
			record['aid_cards'] = {1: {}, 2: {}, 3: {}}
			record['defence_aid_cards'] = {1: {}, 2: {}, 3: {}}


# 布阵卡牌检测
def checkDeployCards(game, cards):
	if not cards:
		return cards

	cards = transform2list(cards, 18)
	if game.cards.isDuplicateMarkID(cards):
		raise ClientError('cards have duplicates')

	# 检查每个队伍的卡牌数量：0-4张都可以（允许队伍为空），但至少要有一个队伍有卡牌
	team_counts = [len(filter(None, cards[:6])), len(filter(None, cards[6:12])), len(filter(None, cards[12:18]))]
	if any(v > 4 for v in team_counts) or all(v == 0 for v in team_counts):
		raise ClientError('have cards num error')

	return cards


# 跨服资源战布阵
class CrossMineBattleDeploy(RequestHandlerTask):
	url = r'/game/cross/mine/battle/deploy'

	@coroutine
	def run(self):
		if self.game.role.cross_mine_record_db_id is None:
			raise ClientError('cross mine not opened')

		if not ObjectCrossMineGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		cards = checkDeployCards(self.game, self.input.get('cards', None))
		defenceCards = checkDeployCards(self.game, self.input.get('defenceCards', None))
		aidCards = self.input.get('aidCards', None)
		defenceAidCards = self.input.get('defenceAidCards', None)
		extra = self.input.get('extra', None)  # 天气/兵种数据 {'weather': X, 'arms': [...]}
		defenceExtra = self.input.get('defenceExtra', None)  # 防守天气/兵种数据
		extra_param = None
		defence_extra_param = None

		# 保存助战卡牌和天气数据到 card_embattle
		if aidCards is not None or defenceAidCards is not None or extra is not None or defenceExtra is not None:
			card_embattle = self.game.role.card_embattle
			if card_embattle is None:
				card_embattle = {}
			if 'cross_mine' not in card_embattle:
				card_embattle['cross_mine'] = {}
			if aidCards is not None:
				# 跨服商业街有3队，改用字典格式
				if isinstance(aidCards, dict):
					card_embattle['cross_mine']['aid_cards'] = {k: v for k, v in aidCards.iteritems() if v is not None}
				else:
					card_embattle['cross_mine']['aid_cards'] = {i+1: v for i, v in enumerate(aidCards) if v is not None}
			if defenceAidCards is not None:
				if isinstance(defenceAidCards, dict):
					card_embattle['cross_mine']['defence_aid_cards'] = {k: v for k, v in defenceAidCards.iteritems() if v is not None}
				else:
					card_embattle['cross_mine']['defence_aid_cards'] = {i+1: v for i, v in enumerate(defenceAidCards) if v is not None}
			# 保存天气数据 - 三队数组结构
			if extra is not None:
				extra_param = _normalize_cross_mine_extra_list(extra)
				card_embattle['cross_mine']['extra'] = extra_param
			if defenceExtra is not None:
				defence_extra_param = _normalize_cross_mine_extra_list(defenceExtra)
				card_embattle['cross_mine']['defence_extra'] = defence_extra_param
			self.game.role.card_embattle = card_embattle

		yield refreshCardsToCrossMine(
			self.rpcPVP,
			self.game,
			cards=cards,
			defence_cards=defenceCards,
			extra=extra_param,
			defence_extra=defence_extra_param
		)
		rpc = ObjectCrossMineGameGlobal.cross_client(self.game.role.areaKey)
		model = yield makeCrossMineModel(self.game, rpc, False, self.rpcPVP)
		_fillAidCardsToModel(model, self.game.role)
		self.write({'model': model})


# 跨服资源战战斗开始
class CrossMineBattleStart(RequestHandlerTask):
	url = r'/game/cross/mine/battle/start'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_mine_record_db_id is None:
			raise ClientError('cross mine not opened')

		if not ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossMineNoOpen)
		if not ObjectCrossMineGameGlobal.isRoleOpen(role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		# rob 抢夺
		# revenge 复仇
		flag = self.input.get('flag', None)
		myRank = self.input.get('myRank', None)
		enemyRank = self.input.get('enemyRank', None)
		enemyRoleID = self.input.get('enemyRoleID', None)
		enemyRecordID = self.input.get('enemyRecordID', None)
		patch = self.input.get('patch', 0)

		if not all([x is not None for x in [flag, myRank, enemyRank, enemyRoleID, enemyRecordID]]):
			raise ClientError('param miss')

		if flag == 'rob' and ObjectCrossMineGameGlobal.isRobTimesLimit(self.game):
			raise ClientError(ErrDefs.crossMineRobTimesLimit)
		if flag == 'revenge' and ObjectCrossMineGameGlobal.isRevengeTimesLimit(self.game):
			raise ClientError(ErrDefs.crossMineRevengeTimesLimit)

		if role.id == enemyRoleID or (flag == 'rob' and myRank == enemyRank):
			raise ClientError(ErrDefs.crossMineRobSelf)

		rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
		try:
			model = yield rpc.call_async('CrossMineBattleStart', flag, myRank, enemyRank, role.id, enemyRoleID, role.cross_mine_record_db_id, enemyRecordID, patch)
		except ClientError, e:
			if e.log_message in (ErrDefs.rankEnemyBattling, ErrDefs.rankEnemyChanged):
				model = yield makeCrossMineModel(self.game, rpc, True, self.rpcPVP)
				raise ClientError(e.log_message, model=model)
			raise ClientError(e.log_message)

		# 天气数据直接使用 Go 端返回的原始格式 [{'weather': 16}, {'weather': 22}, ...]
		# 测试端 gate.lua:initWeatherDatas 期望遍历数组，每个元素有 .weather 属性
		# 不需要转换格式！
		
		if flag == 'rob':
			self.game.dailyRecord.cross_mine_rob_times += 1
		elif flag == 'revenge':
			self.game.dailyRecord.cross_mine_revenge_times += 1

		self.write({
			'model': {
				'cross_mine_battle': model,
			}
		})


# 跨服资源战战斗结束
class CrossMineRobEnd(RequestHandlerTask):
	url = r'/game/cross/mine/battle/end'

	@coroutine
	def run(self):
		role = self.game.role
		if not ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossMineNoOpen)
		result = self.input.get('result', None)
		stats = self.input.get('stats', None)  # {1: 'win', 2: "fail"}
		isTopBattle = self.input.get('isTopBattle', None)  # 是否精彩战报
		if not all([x is not None for x in [result, stats, isTopBattle]]):
			raise ClientError('param miss')

		if isinstance(stats, list):
			stats = {idx + 1: v for idx, v in enumerate(stats)}

		rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
		ret = yield rpc.call_async('CrossMineBattleEnd', role.id, role.cross_mine_record_db_id, result, stats, isTopBattle)

		view = ret.pop('view', {})
		view['result'] = result
		
		# 抢夺失败连续次数（用于勋章统计）
		if result == 'fail':
			role.cross_mine_rob_fail_streak = (role.cross_mine_rob_fail_streak or 0) + 1
		else:
			role.cross_mine_rob_fail_streak = 0  # 胜利重置连续失败次数

		# 刷新货币
		ObjectCrossMineGameGlobal.SyncCoin13(self.game)
		game = ObjectGame.getByRoleID(ret.get('enemyRoleID', None), safe=False)
		if game:
			ObjectCrossMineGameGlobal.SyncCoin13(self.game)

		model = yield makeCrossMineModel(self.game, rpc, False, self.rpcPVP)
		self.write({
			'view': view,
			'model': model
		})


# 跨服资源战 Boss 战斗开始
class CrossMineBossBattleStart(RequestHandlerTask):
	url = r'/game/cross/mine/boss/battle/start'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_mine_record_db_id is None:
			raise ClientError('cross mine not opened')
		if not ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossMineNoOpen)
		if not ObjectCrossMineGameGlobal.isRoleOpen(role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		bossID = self.input.get('bossID', None)

		if ObjectCrossMineGameGlobal.isBossTimesLimit(self.game, bossID):
			raise ClientError(ErrDefs.crossMineBossFreeTimesLimit)

		cards = self.game.role.huodong_cards.get(CrossMineBossHuodongID, self.game.role.battle_cards)
		if cards is None:
			raise ClientError('cards error')

		cardAttrs, cardAttrs2 = self.game.cards.makeBattleCardModel(cards, SceneDefs.CrossMineBoss)
		
		# 为助战卡牌生成属性，合并到 cardAttrs 中（字典格式）
		aid_cards_dict = {}
		if self.game.role.huodong_aid_cards and CrossMineBossHuodongID in self.game.role.huodong_aid_cards:
			aid_cards_dict = self.game.role.huodong_aid_cards[CrossMineBossHuodongID]
			# 兼容老数据（数组格式）
			if isinstance(aid_cards_dict, list):
				aid_cards_dict = {i+1: v for i, v in enumerate(aid_cards_dict) if v is not None}
		aid_cards_values = list(aid_cards_dict.values()) if isinstance(aid_cards_dict, dict) else []
		if aid_cards_values and len(aid_cards_values) > 0:
			aid_attrs, aid_attrs2 = self.game.cards.makeBattleCardModel(aid_cards_values, SceneDefs.CrossMineBoss, is_aid=True)
			cardAttrs.update(aid_attrs)
			cardAttrs2.update(aid_attrs2)
		
		battleCardInfo = {
			'cards': cards,
			'card_attrs': cardAttrs,
			'card_attrs2': cardAttrs2,
			'passive_skills': self.game.cards.markBattlePassiveSkills(cards, SceneDefs.CrossMineBoss),
			'aid_cards': aid_cards_dict,
		}

		rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
		try:
			model = yield rpc.call_async('CrossMineBossStart', role.id, bossID, battleCardInfo)
		except ClientError, e:
			if e.log_message in (ErrDefs.crossMineBossHasKilled):
				model = yield makeCrossMineModel(self.game, rpc, False, self.rpcPVP)
				raise ClientError(e.log_message, model=model)
			else:
				raise ClientError(e.log_message)

		self.write({
			"model": {
				'cross_mine_boss_battle': model
			}
		})


# 跨服资源战 Boss 战斗结束
class CrossMinebossBattleEnd(RequestHandlerTask):
	url = r'/game/cross/mine/boss/battle/end'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_mine_record_db_id is None:
			raise ClientError('cross mine not opened')
		if not ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossMineNoOpen)
		if not ObjectCrossMineGameGlobal.isRoleOpen(role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		battleID = self.input.get('battleID', None)
		damages = self.input.get('damages', None)
		actions = self.input.get('actions', None)
		if isinstance(actions, list):
			actions = {idx + 1: v for idx, v in enumerate(actions)}

		rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
		try:
			resp = yield rpc.call_async('CrossMineBossEnd', role.id, battleID, damages, actions)
		except ClientError, e:
			if e.log_message in (ErrDefs.crossMineBossHasKilled):
				model = yield makeCrossMineModel(self.game, rpc, False, self.rpcPVP)
				raise ClientError(e.log_message, model=model)
			else:
				raise ClientError(e.log_message)

		bossID = resp['bossID']
		self.game.dailyRecord.cross_mine_boss_times[bossID] = self.game.dailyRecord.cross_mine_boss_times.get(bossID, 0) + 1

		csvID = resp['csvID']
		bossCfg = csv.cross.mine.boss[csvID]

		eff = ObjectGainAux(self.game, bossCfg.battleAward)
		if resp['isKill']:
			eff += ObjectGainAux(self.game, bossCfg.killAward)
			# 勋章计数：跨服矿战Boss击杀次数 (targetType=29, medalID=1271)
			self.game.medal.incrementMedalCounter(1271)

		yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_mine_boss_end')

		model = yield makeCrossMineModel(self.game, rpc, False, self.rpcPVP)
		self.write({
			'view': {
				'award': eff.result,
				'score': resp['score']
			},
			'model': model
		})


# 跨服资源战购买次数
class CrossMineTimesBuy(RequestHandlerTask):
	url = r'/cross/mine/times/buy'

	@coroutine
	def run(self):
		role = self.game.role
		if not ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossMineNoOpen)
		if not ObjectCrossMineGameGlobal.isRoleOpen(role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		flag = self.input.get('flag', None)
		if flag is None:
			raise ClientError('param miss')

		if flag not in ['rob', 'revenge']:
			raise ClientError('flag error')

		dailyRecordKey = 'cross_mine_%s_buy_times' % flag
		dailyRecordTimes = getattr(self.game.dailyRecord, dailyRecordKey)
		if dailyRecordTimes >= getattr(role, 'crossMine%sBuyLimit' % flag.capitalize()):
			raise ClientError(getattr(ErrDefs, 'crossMine%sBuyLimit' % flag.capitalize()))

		costRMB = getattr(ObjectCostCSV, 'getCrossMine%sBuyCost' % flag.capitalize())(dailyRecordTimes)
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='cross_mine_%s_buy' % flag)

		setattr(self.game.dailyRecord, dailyRecordKey, dailyRecordTimes + 1)


# 跨服资源战购买 Boss 挑战次数
class CrossMineBossTimesBuy(RequestHandlerTask):
	url = r'/cross/mine/boss/times/buy'

	@coroutine
	def run(self):
		role = self.game.role
		if not ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossMineNoOpen)
		if not ObjectCrossMineGameGlobal.isRoleOpen(role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		bossID = self.input.get('bossID', None)
		if bossID is None:
			raise ClientError('param miss')

		if not ObjectCrossMineGameGlobal.canBuyBossTimes(self.game, bossID):
			raise ClientError('boss times limit')

		costRMB = ObjectCostCSV.getCrossMineBossBuyCost(self.game.dailyRecord.cross_mine_boss_buy_times.get(bossID, 0))
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='cross_mine_boss_buy')

		self.game.dailyRecord.cross_mine_boss_buy_times[bossID] = self.game.dailyRecord.cross_mine_boss_buy_times.get(bossID, 0) + 1


# 跨服资源战 buff 喂养
class CrossMineBuffFeed(RequestHandlerTask):
	url = r'/cross/mine/buff/feed'

	@coroutine
	def run(self):
		role = self.game.role
		if not ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossMineNoOpen)
		if not ObjectCrossMineGameGlobal.isRoleOpen(role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		flag = self.input.get('flag', None)
		csvID = self.input.get('csvID', None)
		if flag is None or csvID is None:
			raise ClientError('param miss')
		if flag not in ['server', 'role']:
			raise ClientError('flag error')
		if csvID not in csv.cross.mine.buff_feed:
			raise ClientError('csvID error')

		cfg = csv.cross.mine.buff_feed[csvID]

		if role.vip_level < cfg.feedVip:
			raise ClientError('csvID vip enough')

		dailyFeed = self.game.dailyRecord.cross_mine_buff_feed
		if flag in dailyFeed and dailyFeed[flag].get(csvID, 0) >= cfg.dayFeedTimesLimit:
			raise ClientError(ErrDefs.crossMineBuffFeedLimit)

		cost = ObjectCostAux(self.game, {'coin13': cfg.costCoin13})
		yield effectAutoCost(cost, self.game, src='cross_mine_%s_buff_feed' % flag, errDef=ErrDefs.costNotEnough)
		
		# 累计祝福消耗（用于勋章统计）
		role.cross_mine_buff_feed_cost = (role.cross_mine_buff_feed_cost or 0) + cfg.costCoin13

		rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
		yield rpc.call_async('CrossMineBuffFeed', flag, csvID, role.id, role.areaKey)

		if flag not in dailyFeed:
			dailyFeed[flag] = {csvID: 1}
		elif csvID not in dailyFeed[flag]:
			dailyFeed[flag][csvID] = 1
		else:
			dailyFeed[flag][csvID] += 1

		eff = ObjectGainAux(self.game, getattr(cfg, '%sFeedAward' % flag))
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_mine_%s_buff_feed' % flag)

		model = yield makeCrossMineModel(self.game, rpc, False, self.rpcPVP)
		self.write({
			'view': eff.result if eff else {},
			'model': model
		})


# 跨服资源战排行榜
class CrossMineRank(RequestHandlerTask):
	url = r'/game/cross/mine/rank'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_mine_record_db_id is None:
			raise ClientError('cross mine not opened')

		flag = self.input.get('flag', None)
		if flag is None or flag not in ['role', 'feed']:
			raise ClientError('param miss')

		offset = self.input.get('offset', 0)
		size = self.input.get('size', 50)

		# 结束后，直接在game拿
		ret = ObjectCrossMineGameGlobal.getRankList(role.areaKey, flag, offset, size, self.game.role.id)
		if ret is None:
			rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
			ret = yield rpc.call_async('CrossMineGetRanks', flag, offset, size, self.game.role.id)

		self.write({
			'view': {
				'rank': ret,
				'offset': offset,
				'size': size
			},
		})


# 跨服资源战 boss 排行榜
class CrossMineBossRank(RequestHandlerTask):
	url = r'/game/cross/mine/boss/rank'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_mine_record_db_id is None:
			raise ClientError('cross mine not opened')
		if not ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossMineNoOpen)
		if not ObjectCrossMineGameGlobal.isRoleOpen(role.level):
			raise ClientError(ErrDefs.crossMineRoleLevelLimit)

		bossID = self.input.get('bossID', None)
		if bossID is None:
			raise ClientError('param miss')
		offset = self.input.get('offset', 0)
		size = self.input.get('size', 50)

		# 结束后，直接在game拿
		rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
		ret = yield rpc.call_async('CrossMineGetBossRanks', self.game.role.id, bossID, offset, size)

		model = yield makeCrossMineModel(self.game, rpc, False, self.rpcPVP)
		self.write({
			'view': {
				'rank': ret,
				'offset': offset,
				'size': size
			},
			'model': model
		})


# 跨服资源战战斗回放
class CrossMinePlayRecordGet(RequestHandlerTask):
	url = r'/game/cross/mine/playrecord/get'

	@coroutine
	def run(self):
		from framework.helper import string2objectid

		crossKey = self.input.get('crossKey', None)
		recordID = self.input.get('recordID', None)  # playRecord.id
		if recordID is None or crossKey is None:
			raise ClientError('param miss')

		# 保存原始 recordID 用于返回
		originalRecordID = recordID

		# 如果是 24 字符的十六进制字符串，转换为 ObjectId
		# 如果是 12 字节的二进制字符串，它已经是 ObjectId 格式，无需转换
		if isinstance(recordID, basestring) and len(recordID) == 24:
			recordID = string2objectid(recordID)

		# crossKey 可能是 game.cn.1，需要转换为 crossmine.cn.1
		crossMineKey = game2crossmine(crossKey)
		rpc = ObjectCrossMineGameGlobal.cross_client(self.game.role.areaKey, cross_key=crossMineKey)
		if rpc is None:
			raise ClientError('Cross Mine Play Not Existed')
		model = yield rpc.call_async('CrossMineGetPlayRecord', recordID)
		if not model:
			raise ClientError('Cross Mine Play Not Existed')
		self.write({
			'model': {
				'cross_mine_playrecords': {
					originalRecordID: model,
				}
			}
		})


# 查看玩家详情
class CrossMineRoleInfo(RequestHandlerTask):
	url = r'/game/cross/mine/role/info'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_mine_record_db_id is None:
			raise ClientError('cross mine not opened')

		flag = self.input.get('flag', "")
		recordID = self.input.get('recordID', None)
		gameKey = self.input.get('gameKey', None)
		rank = self.input.get('rank', None)

		if not all([x is not None for x in [recordID, gameKey, rank]]):
			raise ClientError('param miss')

		client = self.server.container.getserviceOrCreate(game2pvp(gameKey))
		view = yield client.call_async('GetCrossMineRecord', recordID)
		view["game_key"] = gameKey
		# 确保天气字段为数组结构（前端需要访问 [i]）
		_fill_cross_mine_extra(view)
		if view.get('aid_cards') is None:
			view['aid_cards'] = {}
		if view.get('defence_aid_cards') is None:
			view['defence_aid_cards'] = {}

		info = {}
		if ObjectCrossMineGameGlobal.isOpen(role.areaKey):
			rpc = ObjectCrossMineGameGlobal.cross_client(role.areaKey)
			info = yield rpc.call_async('CrossMineGetEnemyInfo', flag, self.game.role.id, view['role_db_id'])

		view['rank'] = info.get('rank', rank)
		view['speed'] = info.get('speed', 0)
		view['coin13_origin'] = info.get('coin13_origin', 0)
		view['coin13_diff'] = info.get('coin13_diff', 0)
		view['canRobNum'] = info.get('canRobNum', 0)
		view['role_be_roded'] = info['role_be_roded'] if info.get('role_be_roded', None) else {}
		view['role_be_revenged'] = info['role_be_revenged'] if info.get('role_be_revenged', None) else {}
		view['killBoss'] = info['killBoss'] if info.get('killBoss', None) else {}

		self.write({
			'view': view,
		})


# 跨服资源战21点游戏结果
class CrossMineBlackjackResult(RequestHandlerTask):
	url = r'/game/cross/mine/blackjack/result'

	@coroutine
	def run(self):
		if not ObjectCrossMineGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError('cross mine blackjack not opened')

		# 获取前端传来的游戏结果 [["win", blackJ, double], ["lose", ...], ...]
		game_result = self.input.get('state', [])
		if not isinstance(game_result, (list, tuple)):
			raise ClientError('param error')

		# 检查21点配置
		if 1 not in csv.cross.mine.blackjack_base:
			raise ClientError('blackjack config not found')
		blackjack_cfg = csv.cross.mine.blackjack_base[1]

		# 检查每日次数
		play_times = self.game.dailyRecord.cross_mine_blackjack_play_times
		max_times = blackjack_cfg.playTimes or 5
		if play_times >= max_times:
			raise ClientError(ErrDefs.crossMineBlackjackTimesNotEnough)

		# 计算积分和奖励
		points = blackjack_cfg.points or 20
		great_points = blackjack_cfg.greatPoints or 40
		rewards_cfg = blackjack_cfg.rewards or {}
		great_rewards_cfg = blackjack_cfg.greatRewards or {}

		total_score = 0
		has_win = False
		for result in game_result:
			if not isinstance(result, (list, tuple)) or len(result) < 1:
				continue
			win_type = result[0] if len(result) > 0 else None
			is_blackj = result[1] if len(result) > 1 else False
			is_double = result[2] if len(result) > 2 else False

			if win_type == 'win':
				has_win = True
				double_mult = 2 if is_double else 1
				if is_blackj:
					total_score += great_points
				else:
					total_score += points * double_mult

		# 根据是否获胜选择奖励配置
		if has_win:
			# 使用blackjack奖励或普通奖励
			any_blackj = any(r[1] if len(r) > 1 else False for r in game_result if isinstance(r, (list, tuple)) and len(r) > 0 and r[0] == 'win')
			if any_blackj:
				final_rewards = dict(great_rewards_cfg)
			else:
				final_rewards = dict(rewards_cfg)
		else:
			# 输了没有奖励
			final_rewards = {}

		# 发放奖励
		eff = ObjectGainAux(self.game, final_rewards)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_mine_blackjack')

		# 增加游戏次数
		self.game.dailyRecord.cross_mine_blackjack_play_times = play_times + 1

		self.write({
			'view': eff.result,
		})


# 跨服资源战商店
class CrossMineShop(RequestHandlerTask):
	url = r'/game/cross/mine/shop'

	@coroutine
	def run(self):
		if not ObjectCrossMineGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError('cross mine shop not opened')

		csvID = self.input.get('csvID', None)
		count = self.input.get('count', 1)
		if csvID is None:
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')

		shop = ObjectCrossMineShop(self.game)
		eff = yield shop.buyItem(csvID, count, src='cross_mine_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_mine_shop_buy')
