#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

PVP Handlers
'''
from framework.csv import ErrDefs, csv, ConstDefs
from framework.helper import transform2list
from framework.log import logger
from framework.service.helper import game2pvp, game2crossarena
from game import ClientError
from game.globaldata import PVPSkinIDStart
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.handler._pvp import _normalize_battle_extra
from game.object import SceneDefs, FeatureDefs, CrossArenaDefs, MessageDefs
from game.object.game import ObjectCostCSV, ObjectMessageGlobal
from game.object.game.cross_arena import ObjectCrossArenaGameGlobal
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from game.object.game.shop import ObjectCrossArenaShop
from game.thinkingdata import ta
from msgpackrpc.error import CallError
from tornado.gen import coroutine, Return


def _normalize_extra_list(raw):
	"""
	兼容数组/单个字典，返回长度 2 的列表，每个元素为规范化的 battle_extra
	"""
	if isinstance(raw, (list, tuple)):
		first = _normalize_battle_extra(raw[0] if len(raw) > 0 else None)
		second = _normalize_battle_extra(raw[1] if len(raw) > 1 else None)
		return [first, second]
	norm = _normalize_battle_extra(raw)
	return [norm, norm]


# 跨服竞技场每队助战位置数（需与 csv.aid.scene[17].aidUnlockLevel 长度一致）
CROSS_ARENA_AID_NUM_MAX = 2


def _convertAidCardsToNested(flat_aids, aidNumMax=CROSS_ARENA_AID_NUM_MAX):
	"""
	将扁平化的助战数组转换成嵌套字典结构（2个队伍）
	Go端期望格式: {1: {1: cardID, 2: cardID}, 2: {...}}
	跨服竞技场每队2个助战位置，aidNumMax=2
	"""
	result = {1: {}, 2: {}}
	if not flat_aids:
		return result
	for team in [1, 2]:
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


def _fill_client_extra(record, role=None):
	if not isinstance(record, dict):
		return
	# 优先从 card_embattle 还原数组（可保存两个队伍不同配置）
	if role and role.card_embattle and 'cross_arena' in role.card_embattle:
		embattle_extra = role.card_embattle['cross_arena'].get('extra', None)
		embattle_defence_extra = role.card_embattle['cross_arena'].get('defence_extra', None)
		if isinstance(embattle_extra, (list, tuple)):
			record['extra'] = _normalize_extra_list(embattle_extra)
		if isinstance(embattle_defence_extra, (list, tuple)):
			record['defence_extra'] = _normalize_extra_list(embattle_defence_extra)

	extra_in = record.get('extra', None)
	defence_in = record.get('defence_extra', None)

	extra_list = _normalize_extra_list(extra_in if extra_in is not None else {'weather': 0, 'arms': []})
	defence_list = _normalize_extra_list(defence_in if defence_in is not None else {'weather': 0, 'arms': []})

	# 客户端需要下标 1/2 访问天气选择
	record['extra'] = extra_list
	# 防守也按数组返回
	record['defence_extra'] = defence_list
	# 保留独立字段（便于旧逻辑）
	record['attack_extra'] = extra_list[0]


@coroutine
def makeBattleModel(game, rpc, refresh, rpcPVP):
	role = game.role
	if not role.cross_arena_record_db_id:
		raise Return({'cross_arena': {}, })

	# {enemys; role; record}
	model = {}
	record = yield rpcPVP.call_async('GetCrossArenaRecord', role.cross_arena_record_db_id)
	model['record'] = record
	if ObjectCrossArenaGameGlobal.isOpen(role.areaKey):
		# 防守阵容有为空特殊情况处理
		defenceCards = model['record']['defence_cards']
		if len(filter(None, defenceCards[1])) == 0 or len(filter(None, defenceCards[2])) == 0:
			cardsMap, _ = ObjectCrossArenaGameGlobal.getCrossArenaCards(role)
			dfCards = cardsMap[1]
			dfCards.extend(cardsMap[2])
			yield refreshCardsToCrossArena(rpcPVP, game, defence_cards=dfCards)
			record = yield rpcPVP.call_async('GetCrossArenaRecord', game.role.cross_arena_record_db_id)
			model['record'] = record

		defenceCardAttrs = model['record']['defence_card_attrs']
		crossArenaRoleInfo = ObjectCrossArenaGameGlobal.markCrossArenaRoleInfo(game.role, defenceCardAttrs)
		enemys, roleData, flag = yield rpc.call_async('GetCrossArenaModel', role.id, crossArenaRoleInfo, refresh)
		model['enemys'] = enemys
		model['role'] = roleData
		if flag:
			# 重置上赛季数据
			ObjectCrossArenaGameGlobal.resetCrossAreanDatas(role)
			# 清除上赛季历史战报
			yield rpcPVP.call_async('CleanCrossArenaHistory', role.cross_arena_record_db_id)
			model['record']['history'] = []
			# 初始化 段位奖励
			role.setCrossAreanStageAwards(roleData["rank"])
		model['topBattleHistory'] = yield rpc.call_async('GetCrossArenaTopBattleHistory')
	else:
		model['topBattleHistory'] = ObjectCrossArenaGameGlobal.getTopBattleHistory(role.areaKey)

	_fill_client_extra(model.get('record'), role=role)
	
	# 转换助战卡牌格式：从 card_embattle 读取原始数据（保留位置信息），转换成前端期望的嵌套结构 {1: [...], 2: [...]}
	# Go 返回的数据丢失了位置信息，所以必须从 card_embattle 读取
	aidNumMax = CROSS_ARENA_AID_NUM_MAX
	record = model.get('record')
	if record:
		if role.card_embattle and 'cross_arena' in role.card_embattle:
			aid_cards_raw = role.card_embattle['cross_arena'].get('aid_cards', {})
			defence_aid_cards_raw = role.card_embattle['cross_arena'].get('defence_aid_cards', {})
			record['aid_cards'] = _convertAidCardsToNested(aid_cards_raw, aidNumMax)
			record['defence_aid_cards'] = _convertAidCardsToNested(defence_aid_cards_raw, aidNumMax)
		else:
			record['aid_cards'] = {1: {}, 2: {}}
			record['defence_aid_cards'] = {1: {}, 2: {}}
	
	model.update(ObjectCrossArenaGameGlobal.getCrossGameModel(role.areaKey))
	raise Return({
		'cross_arena': model,
	})

@coroutine
def refreshCardsToCrossArena(rpc, game, cards=None, defence_cards=None, extra=None, defence_extra=None, force=False):
	if not game.role.cross_arena_record_db_id:
		raise Return(None)
	deployment = game.cards.deploymentForCrossArena
	# 卡牌没发生改变
	if not any([force, cards, defence_cards, deployment.isdirty(), extra is not None, defence_extra is not None]):
		raise Return(None)

	embattle = {}

	# 进攻阵容
	if cards:
		cardsMap = {}  # {1:[card.id], 2:[card.id]}
		cardsMap[1] = transform2list(cards[:6])
		cardsMap[2] = transform2list(cards[6:12])
		embattle['cards'] = cardsMap
	cards, dirty = deployment.refresh('cards', SceneDefs.CrossArena, cards)
	cardAttrs, cardAttrs12 = game.cards.makeBattleCardModel(cards[:6], SceneDefs.CrossArena, dirty=dirty[:6] if dirty else None)
	cardAttrs2, cardAttrs22 = game.cards.makeBattleCardModel(cards[6:12], SceneDefs.CrossArena, dirty=dirty[6:12] if dirty else None)
	cardAttrs.update(cardAttrs2)
	cardAttrs12.update(cardAttrs22)
	embattle['card_attrs'] = cardAttrs
	embattle['card_attrs2'] = cardAttrs12
	embattle['passive_skills'] = game.cards.markBattlePassiveSkills(cards, SceneDefs.CrossArena)

	# 防守阵容
	if defence_cards:
		defenceCardsMap = {}
		defenceCardsMap[1] = transform2list(defence_cards[:6])
		defenceCardsMap[2] = transform2list(defence_cards[6:12])
		embattle['defence_cards'] = defenceCardsMap
	defence_cards, defence_dirty = deployment.refresh('defence_cards', SceneDefs.CrossArena, defence_cards)
	defenceCardAttrs, defenceCardAttrs12 = game.cards.makeBattleCardModel(defence_cards[:6], SceneDefs.CrossArena, dirty=defence_dirty[:6] if defence_dirty else None)
	defenceCardAttrs2, defenceCardAttrs22 = game.cards.makeBattleCardModel(defence_cards[6:12], SceneDefs.CrossArena, dirty=defence_dirty[6:12] if defence_dirty else None)
	defenceCardAttrs.update(defenceCardAttrs2)
	defenceCardAttrs12.update(defenceCardAttrs22)
	embattle['defence_card_attrs'] = defenceCardAttrs
	embattle['defence_card_attrs2'] = defenceCardAttrs12
	embattle['defence_passive_skills'] = game.cards.markBattlePassiveSkills(defence_cards, SceneDefs.CrossArena)
	
	# 助战卡牌数据 - 总是发送字典格式
	role = game.role
	aid_cards_dict = {}
	defence_aid_cards_dict = {}
	aid_fighting_point = 0
	defence_aid_fighting_point = 0
	if role.card_embattle and 'cross_arena' in role.card_embattle:
		aid_cards_dict = role.card_embattle['cross_arena'].get('aid_cards', {})
		defence_aid_cards_dict = role.card_embattle['cross_arena'].get('defence_aid_cards', {})
		# 兼容老数据（数组格式）
		if isinstance(aid_cards_dict, list):
			aid_cards_dict = {i+1: v for i, v in enumerate(aid_cards_dict) if v is not None}
		if isinstance(defence_aid_cards_dict, list):
			defence_aid_cards_dict = {i+1: v for i, v in enumerate(defence_aid_cards_dict) if v is not None}
		
		# 为助战卡牌生成属性，合并到 card_attrs 中，并计算总战力
		aid_cards_values = aid_cards_dict.values() if isinstance(aid_cards_dict, dict) else []
		if aid_cards_values and len(list(aid_cards_values)) > 0:
			aid_attrs, aid_attrs2 = game.cards.makeBattleCardModel(list(aid_cards_values), SceneDefs.CrossArena, is_aid=True)
			embattle['card_attrs'].update(aid_attrs)
			embattle['card_attrs2'].update(aid_attrs2)
			for aid_attr in aid_attrs.values():
				aid_fighting_point += aid_attr.get('aid_fighting_point', 0)
		defence_aid_cards_values = defence_aid_cards_dict.values() if isinstance(defence_aid_cards_dict, dict) else []
		if defence_aid_cards_values and len(list(defence_aid_cards_values)) > 0:
			aid_attrs, aid_attrs2 = game.cards.makeBattleCardModel(list(defence_aid_cards_values), SceneDefs.CrossArena, is_aid=True)
			embattle['defence_card_attrs'].update(aid_attrs)
			embattle['defence_card_attrs2'].update(aid_attrs2)
			for aid_attr in aid_attrs.values():
				defence_aid_fighting_point += aid_attr.get('aid_fighting_point', 0)
	
	# 发送给 Go 时使用字典格式
	embattle['aid_cards'] = aid_cards_dict
	embattle['defence_aid_cards'] = defence_aid_cards_dict
	embattle['aid_fighting_point'] = aid_fighting_point
	embattle['defence_aid_fighting_point'] = defence_aid_fighting_point
	
	# 天气/兵种扩展数据（从 card_embattle 读取）
	# 总是发送，即使为空（用于清空）
	extra_data_list = _normalize_extra_list({'weather': 0, 'arms': []})
	defence_extra_list = _normalize_extra_list({'weather': 0, 'arms': []})
	need_fix = False
	if role.card_embattle and 'cross_arena' in role.card_embattle:
		extra_raw = role.card_embattle['cross_arena'].get('extra', {'weather': 0, 'arms': []})
		defence_extra_raw = role.card_embattle['cross_arena'].get('defence_extra', {'weather': 0, 'arms': []})
		# 检测老格式（dict）并自动修复为数组格式
		if isinstance(extra_raw, dict):
			need_fix = True
		if isinstance(defence_extra_raw, dict):
			need_fix = True
		extra_data_list = _normalize_extra_list(extra_raw)
		defence_extra_list = _normalize_extra_list(defence_extra_raw)
		# 自动修复老格式
		if need_fix:
			card_embattle = role.card_embattle or {}
			card_embattle['cross_arena']['extra'] = extra_data_list
			card_embattle['cross_arena']['defence_extra'] = defence_extra_list
			role.card_embattle = card_embattle
	# 如果传入新配置，用新值覆盖
	if extra is not None:
		extra_data_list = _normalize_extra_list(extra)
	if defence_extra is not None:
		defence_extra_list = _normalize_extra_list(defence_extra)
	# Go 端只支持单份 BattleExtra，取第 1 队配置入库，数组形式存到 card_embattle 供客户端取用
	embattle['extra'] = extra_data_list[0]
	embattle['defence_extra'] = defence_extra_list[0]

	deployment.resetdirty()
	yield rpc.call_async('CrossArenaDeployCards', game.role.cross_arena_record_db_id, game.role.competitor, embattle)


# 进入主界面 先请求该接口 （同步model客户端)
class CrossArenaBattleMain(RequestHandlerTask):
	url = r'/game/cross/arena/battle/main'

	@coroutine
	def run(self):
		if not ObjectCrossArenaGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError(ErrDefs.levelLessNoOpened)

		needRefresh = self.input.get('needRefresh', 0)

		role = self.game.role
		# 新建CrossArenaRecord
		if role.cross_arena_record_db_id is None:
			cardsMap, cards = ObjectCrossArenaGameGlobal.getCrossArenaCards(role)
			passiveSkills = self.game.cards.markBattlePassiveSkills(cards, SceneDefs.CrossArena)

			cardAttrs, cardAttrs12 = self.game.cards.makeBattleCardModel(cardsMap[1], SceneDefs.CrossArena)
			cardAttrs2, cardAttrs22 = self.game.cards.makeBattleCardModel(cardsMap[2], SceneDefs.CrossArena)
			cardAttrs.update(cardAttrs2)
			cardAttrs12.update(cardAttrs22)

			embattle = {
				'cards': cardsMap,
				'extra': {'weather': 0, 'arms': []},
				'card_attrs': cardAttrs,
				'card_attrs2': cardAttrs12,
				'passive_skills': passiveSkills,
				'defence_cards': cardsMap,
				'defence_card_attrs': cardAttrs,
				'defence_card_attrs2': cardAttrs22,
				'defence_passive_skills': passiveSkills,
				'defence_extra': {'weather': 0, 'arms': []},
			}
			role.cross_arena_record_db_id = yield self.rpcPVP.call_async('CreateCrossArenaRecord', role.competitor, embattle, False)

			deployment = self.game.cards.deploymentForCrossArena
			deployment.deploy('cards', transform2list(cards, 12))
			deployment.deploy('defence_cards', transform2list(cards, 12))

		# 保存玩家最新卡牌数据
		else:
			if needRefresh == 1:
				costGold = ObjectCostCSV.getCrossArenaFreshCost(self.game.dailyRecord.cross_arena_refresh_times)
				cost = ObjectCostAux(self.game, {'gold': costGold})
				if not cost.isEnough():
					raise ClientError(ErrDefs.costNotEnough)
				cost.cost(src='cross_arena_battle_refresh')
				self.game.dailyRecord.cross_arena_refresh_times += 1
			yield refreshCardsToCrossArena(self.rpcPVP, self.game)

		rpc = ObjectCrossArenaGameGlobal.cross_client(role.areaKey)
		model = yield makeBattleModel(self.game, rpc, True if needRefresh == 1 else False, self.rpcPVP)
		
		# makeBattleModel 已经处理了助战卡牌格式转换，这里不需要额外处理
		
		self.write({'model': model})


# 队伍布阵（两个队伍）包含防守
class CrossArenaBattleDeploy(RequestHandlerTask):
	url = r'/game/cross/arena/battle/deploy'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_arena_record_db_id is None:
			raise ClientError('cross arena not opened')

		cards = self.input.get('cards', None)
		defenceCards = self.input.get('defenceCards', None)
		aidCards = self.input.get('aidCards', None)
		defenceAidCards = self.input.get('defenceAidCards', None)
		extra = self.input.get('extra', None)
		defenceExtra = self.input.get('defenceExtra', None)
		extra_param = None
		defence_extra_param = None
		force_refresh = False

		if cards:
			cards = transform2list(cards, 12)
			if self.game.cards.isDuplicateMarkID(cards):
				raise ClientError('cards have duplicates')
			cards1 = cards[:6]
			cards2 = cards[6:12]
			if len(filter(None, cards1)) == 0 or len(filter(None, cards2)) == 0:
				raise ClientError('have one cards all None')

		if defenceCards:
			defenceCards = transform2list(defenceCards, 12)
			if self.game.cards.isDuplicateMarkID(defenceCards):
				raise ClientError('cards have duplicates')
			defenceCards1 = defenceCards[:6]
			defenceCards2 = defenceCards[6:12]
			if len(filter(None, defenceCards1)) == 0 or len(filter(None, defenceCards2)) == 0:
				raise ClientError('have one defenceCards all None')

		# 保存助战卡牌/天气/兵种到 card_embattle
		if aidCards is not None or defenceAidCards is not None or extra is not None or defenceExtra is not None:
			card_embattle = role.card_embattle
			if card_embattle is None:
				card_embattle = {}
			if 'cross_arena' not in card_embattle:
				card_embattle['cross_arena'] = {}
			card_embattle_cross = card_embattle['cross_arena']
			if aidCards is not None:
				if isinstance(aidCards, dict):
					card_embattle_cross['aid_cards'] = {k: v for k, v in aidCards.iteritems() if v is not None}
				else:
					card_embattle_cross['aid_cards'] = {i+1: v for i, v in enumerate(aidCards) if v is not None}
				force_refresh = True
			if defenceAidCards is not None:
				if isinstance(defenceAidCards, dict):
					card_embattle_cross['defence_aid_cards'] = {k: v for k, v in defenceAidCards.iteritems() if v is not None}
				else:
					card_embattle_cross['defence_aid_cards'] = {i+1: v for i, v in enumerate(defenceAidCards) if v is not None}
				force_refresh = True
			if extra is not None:
				extra_param = _normalize_extra_list(extra)
				card_embattle_cross['extra'] = extra_param
			if defenceExtra is not None:
				defence_extra_param = _normalize_extra_list(defenceExtra)
				card_embattle_cross['defence_extra'] = defence_extra_param
			role.card_embattle = card_embattle

		yield refreshCardsToCrossArena(
			self.rpcPVP,
			self.game,
			cards=cards,
			defence_cards=defenceCards,
			extra=extra_param,
			defence_extra=defence_extra_param,
			force=force_refresh
		)
		rpc = ObjectCrossArenaGameGlobal.cross_client(role.areaKey)
		model = yield makeBattleModel(self.game, rpc, False, self.rpcPVP)
		
		# makeBattleModel 已经处理了助战卡牌格式转换
		
		self.write({'model': model})


# 开始战斗
class CrossArenaBattleStart(RequestHandlerTask):
	url = r'/game/cross/arena/battle/start'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_arena_record_db_id is None:
			raise ClientError('cross arena not opened')
		# 只有赛季中才可战斗
		if not ObjectCrossArenaGameGlobal.isOpen(role.areaKey):
			raise ClientError(ErrDefs.crossArenaNotOpen)

		myRank = self.input.get('myRank', None)
		battleRank = self.input.get('battleRank', None)
		enemyRoleID = self.input.get('enemyRoleID', None)
		enemyRecordID = self.input.get('enemyRecordID', None)
		patch = self.input.get('patch', 0)

		if not all([x is not None for x in [myRank, battleRank, enemyRoleID, enemyRecordID]]):
			raise ClientError('param miss')
		if enemyRoleID == role.id:
			raise ClientError(ErrDefs.pvpSelfErr)

		dailyRecord = self.game.dailyRecord
		if dailyRecord.cross_arena_pw_times >= role.crossArenaFreePWTimes + dailyRecord.cross_arena_buy_times:
			raise ClientError("pw times no enough")

		rpc = ObjectCrossArenaGameGlobal.cross_client(role.areaKey)
		try:
			model = yield rpc.call_async('CrossArenaBattleStart', myRank, battleRank, role.id, enemyRoleID, role.cross_arena_record_db_id, enemyRecordID, patch)
		except CallError, e:
			# 刷新挑战对手列表
			if e.msg in (ErrDefs.rankEnemyBattling, ErrDefs.rankEnemyChanged):
				modelBattle = yield makeBattleModel(self.game, rpc, True, self.rpcPVP)
				raise ClientError(e.msg, model=modelBattle)
			raise ClientError(e.msg)

		# 添加助战卡牌数据并生成属性（从 card_embattle 读取）
		if role.card_embattle and 'cross_arena' in role.card_embattle:
			aid_cards_dict = role.card_embattle['cross_arena'].get('aid_cards', {})
			# 兼容老数据（数组格式）
			if isinstance(aid_cards_dict, list):
				aid_cards_dict = {i+1: v for i, v in enumerate(aid_cards_dict) if v is not None}
			if aid_cards_dict:
				# 转换成嵌套格式（前端期望 {group: {slot: card_id}}）
				model['aid_cards'] = _convertAidCardsToNested(aid_cards_dict)
				# 为助战卡牌生成属性，合并到 card_attrs 中
				aid_cards_values = list(aid_cards_dict.values())
				if aid_cards_values:
					aid_attrs, aid_attrs2 = self.game.cards.makeBattleCardModel(aid_cards_values, SceneDefs.CrossArena, is_aid=True)
					if 'card_attrs' not in model:
						model['card_attrs'] = {}
					if 'card_attrs2' not in model:
						model['card_attrs2'] = {}
					model['card_attrs'].update(aid_attrs)
					model['card_attrs2'].update(aid_attrs2)
		_fill_client_extra(model, role=role)

		dailyRecord.cross_arena_pw_times += 1

		# 每日次数奖励
		for csvID in sorted(csv.cross.arena.daily_award):
			cfg = csv.cross.arena.daily_award[csvID]
			if dailyRecord.cross_arena_pw_times >= cfg.pwTime and csvID not in dailyRecord.cross_arena_point_award:
					dailyRecord.cross_arena_point_award[csvID] = CrossArenaDefs.DailyAwardOpenFlag

		self.write({
			'model': {
				'cross_arena_battle': model,
			}
		})


# 结束战斗
class CrossArenaBattleEnd(RequestHandlerTask):
	url = r'/game/cross/arena/battle/end'

	@coroutine
	def run(self):
		if not ObjectCrossArenaGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError(ErrDefs.crossArenaNotOpen)
		rank = self.input.get('rank', None)  # 用作检验
		result = self.input.get('result', None)
		isTopBattle = self.input.get('isTopBattle', None)  # 是否精彩战报
		if not all([x is not None for x in [rank, result, isTopBattle]]):
			raise ClientError('param miss')

		role = self.game.role
		try:
			rpc = ObjectCrossArenaGameGlobal.cross_client(role.areaKey)
			ret = yield rpc.call_async('CrossArenaBattleEnd', rank, role.id, role.cross_arena_record_db_id, result, isTopBattle)
		except CallError, e:
			# 可能作弊了
			raise ClientError(e.msg)
		except:
			raise

		ret['result'] = result
		if result == 'win':
			# 段位奖励
			newRank = ret["rank"]
			role.setCrossAreanStageAwards(newRank)
			# 跑马灯
			if newRank == 1:
				ObjectMessageGlobal.marqueeBroadcast(role, MessageDefs.MqCrossArenaTopRank)
				ObjectMessageGlobal.newsCrossArenaTopRankMsg(role)

		rpc = ObjectCrossArenaGameGlobal.cross_client(role.areaKey)
		modelBattle = yield makeBattleModel(self.game, rpc, False, self.rpcPVP)

		result = {
			'view': ret,
			'model': modelBattle,
		}
		self.write(result)

		ta.track(self.game, event='end_cross_arena',result=result)


# 跨服竞技场 5次碾压
class CrossArenaBattlePass(RequestHandlerTask):
	url = r'/game/cross/arena/battle/pass'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.CrossArenaPass, self.game):
			raise ClientError('cross_arena_pass not open')
		if not ObjectCrossArenaGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError(ErrDefs.crossArenaNotOpen)
		role = self.game.role
		battleRank = self.input.get('battleRank', None)
		if not battleRank:
			raise ClientError('param miss')

		dailyRecord = self.game.dailyRecord
		# 剩余可用挑战次数
		canPwTimes = role.crossArenaFreePWTimes + dailyRecord.cross_arena_buy_times - dailyRecord.cross_arena_pw_times

		if canPwTimes >= 5:
			needBuyTimes = 0
		else:
			needBuyTimes = 5 - canPwTimes

		# 消耗RMB = 购买次数的消耗RMB + 固定消耗
		costRMB = 0
		for i in xrange(0, needBuyTimes):
			costRMB += ObjectCostCSV.getCrossArenaPWBuyCost(self.game.dailyRecord.cross_arena_buy_times + i)
		costRMB += ConstDefs.crossArenaPassCostRmb
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError('cost rmb not enough')
		cost.cost(src='cross_arena_pass5')

		# 挑战次数+5
		dailyRecord.cross_arena_pw_times += 5
		# 购买次数加上
		dailyRecord.cross_arena_buy_times += needBuyTimes

		# 每日次数奖励
		for csvID in sorted(csv.cross.arena.daily_award):
			cfg = csv.cross.arena.daily_award[csvID]
			if dailyRecord.cross_arena_pw_times >= cfg.pwTime and csvID not in dailyRecord.cross_arena_point_award:
				dailyRecord.cross_arena_point_award[csvID] = CrossArenaDefs.DailyAwardOpenFlag


# 对战情报录像回放
class CrossArenaPlayRecordGet(RequestHandlerTask):
	url = r'/game/cross/arena/playrecord/get'

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

		# crossKey 可能是 game.cn.1，需要转换为 crossarena.cn.1
		crossArenaKey = game2crossarena(crossKey)
		rpc = ObjectCrossArenaGameGlobal.cross_client(self.game.role.areaKey, cross_key=crossArenaKey)
		if rpc is None:
			raise ClientError('Cross Arena Play Not Existed')
		model = yield rpc.call_async('GetCrossArenaPlayRecord', recordID)
		if not model:
			raise ClientError('Cross Arena Play Not Existed')
		_fill_client_extra(model, role=self.game.role)
		self.write({
			'model': {
				'cross_arena_playrecords': {
					originalRecordID: model,
				}
			}
		})


# 领取每日次数奖励
class CrossArenaDailyAward(RequestHandlerTask):
	url = r'/game/cross/arena/daily/award'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_arena_record_db_id is None:
			raise ClientError('cross arena not opened')

		csvID = self.input.get('csvID', None)

		eff = ObjectGainAux(self.game, {})
		if not csvID:  # 一键领取
			for awardID, flag in self.game.dailyRecord.cross_arena_point_award.iteritems():
				if flag == CrossArenaDefs.DailyAwardOpenFlag:
					cfg = csv.cross.arena.daily_award[awardID]
					eff += ObjectGainAux(self.game, cfg.award)
					self.game.dailyRecord.cross_arena_point_award[awardID] = CrossArenaDefs.DailyAwardCloseFlag
		else:
			if csvID not in csv.cross.arena.daily_award:
				raise ClientError('csvID error')
			flag = self.game.dailyRecord.cross_arena_point_award.get(csvID, -1)
			if flag == CrossArenaDefs.DailyAwardCloseFlag:
				raise ClientError('daily award get again')
			elif flag == CrossArenaDefs.DailyAwardNoneFlag:
				raise ClientError('daily award not finish')

			cfg = csv.cross.arena.daily_award[csvID]
			eff += ObjectGainAux(self.game, cfg.award)
			self.game.dailyRecord.cross_arena_point_award[csvID] = CrossArenaDefs.DailyAwardCloseFlag

		ret = {}
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_arena_daily_award')
			ret = eff.result

		self.write({
			'view': ret,
		})


# 领取段位奖励
class CrossArenaStageAward(RequestHandlerTask):
	url = r'/game/cross/arena/stage/award'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_arena_record_db_id is None:
			raise ClientError('cross arena not opened')

		csvID = self.input.get('csvID', None)  # csvID

		stageAwards = role.cross_arena_datas.setdefault("stage_awards", {})
		eff = ObjectGainAux(self.game, {})
		if not csvID:  # 一键领取
			for awardID, flag in stageAwards.iteritems():
				if flag == CrossArenaDefs.StageAwardOpenFlag:
					cfg = csv.cross.arena.stage[awardID]
					eff += ObjectGainAux(self.game, cfg.award)
					stageAwards[awardID] = CrossArenaDefs.StageAwardCloseFlag
		else:
			if csvID not in csv.cross.arena.stage:
				raise ClientError('csvID error')
			flag = stageAwards.get(csvID, -1)
			if flag == CrossArenaDefs.StageAwardCloseFlag:
				raise ClientError('stage award get again')
			elif flag == CrossArenaDefs.StageAwardNoneFlag:
				raise ClientError('stage award not finish')

			cfg = csv.cross.arena.stage[csvID]
			eff += ObjectGainAux(self.game, cfg.award)
			stageAwards[csvID] = CrossArenaDefs.StageAwardCloseFlag

		ret = {}
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_arena_stage_award')
			ret = eff.result

		self.write({
			'view': ret,
		})


# 获取排行榜
class CrossArenaRank(RequestHandlerTask):
	url = r'/game/cross/arena/rank'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_arena_record_db_id is None:
			raise ClientError('cross arena not opened')
		offest = self.input.get('offest', 0)
		size = self.input.get('size', 50)

		# 结束后，直接在game拿
		ret = ObjectCrossArenaGameGlobal.getRankList(role.areaKey, offest, size, self.game.role.id)
		if ret is None:
			rpc = ObjectCrossArenaGameGlobal.cross_client(role.areaKey)
			ret = yield rpc.call_async('GetCrossArenaTopRanks', offest, size, self.game.role.id)
		self.write({
			'view': {
				'rank': ret,
				'offest': offest,
				'size': size,
			},
		})


# 购买挑战次数
class CrossArenaBattleBuy(RequestHandlerTask):
	url = r'/game/cross/arena/battle/buy'

	@coroutine
	def run(self):
		if not ObjectCrossArenaGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError(ErrDefs.crossArenaNotOpen)
		role = self.game.role
		if role.cross_arena_record_db_id is None:
			raise ClientError('cross arena not opened')

		if self.game.dailyRecord.cross_arena_buy_times >= self.game.role.crossArenaBuyPWMaxTimes:
			raise ClientError(ErrDefs.pwBuyMax)

		costRMB = ObjectCostCSV.getCrossArenaPWBuyCost(self.game.dailyRecord.cross_arena_buy_times)

		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='cross_arena_pw_buy')

		self.game.dailyRecord.cross_arena_buy_times += 1


# 查看玩家详情
class CrossArenaRoleInfo(RequestHandlerTask):
	url = r'/game/cross/arena/role/info'

	@coroutine
	def run(self):
		role = self.game.role
		if role.cross_arena_record_db_id is None:
			raise ClientError('cross arena not opened')

		recordID = self.input.get('recordID', None)
		gameKey = self.input.get('gameKey', None)
		rank = self.input.get('rank', None)
		if not all([x is not None for x in [recordID, gameKey, rank]]):
			raise ClientError('param miss')

		client = self.server.container.getserviceOrCreate(game2pvp(gameKey))
		view = yield client.call_async('GetCrossArenaRecord', recordID)
		view["game_key"] = gameKey
		view["rank"] = rank
		_fill_client_extra(view, role=role)
		self.write({
			'view': view,
		})


# 更换展示卡牌
class CrossArenaDisplay(RequestHandlerTask):
	url = r'/game/cross/arena/display'

	@coroutine
	def run(self):
		if not ObjectCrossArenaGameGlobal.isOpen(self.game.role.areaKey):
			raise ClientError(ErrDefs.crossArenaNotOpen)
		role = self.game.role
		if role.cross_arena_record_db_id == 0:
			raise ClientError('cross arena not opened')
		cardID = self.input.get('cardID', None)  # csv_id
		if cardID is None:
			raise ClientError('cardID miss')
		if cardID not in role.pokedex and (cardID % PVPSkinIDStart) not in role.skins:
			raise ClientError('cardID error')

		self.game.role.cross_arena_datas['last_display'] = cardID
		rpc = ObjectCrossArenaGameGlobal.cross_client(role.areaKey)
		yield rpc.call_async('UpdateCrossArenaDisplay', role.id, cardID)

		self.write({
			'sync': {
				'upd': {
					'cross_arena': {
						'role': {'display': cardID},
					}
				}
			}
		})


# 商店兑换
class CrossArenaShopBuy(RequestHandlerTask):
	url = r'/game/cross/arena/shop/buy'

	@coroutine
	def run(self):
		if not ObjectCrossArenaGameGlobal.isRoleOpen(self.game.role.level):
			raise ClientError('cross arena shop not opened')

		csvID = self.input.get('csvID', None)
		count = self.input.get('count', 1)
		if csvID is None:
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')

		crossArenaShop = ObjectCrossArenaShop(self.game)
		eff = crossArenaShop.buyItem(csvID, count, src='cross_arena_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_arena_shop_buy')


# 跨服阵容推荐
class CrossRecommendGet(RequestHandlerTask):
	url = r'/game/cross/recommend/get'

	@coroutine
	def run(self):
		# 获取场景类型
		sceneType = self.input.get('sceneType', 1)
		
		# 检查CSV配置是否存在
		if not hasattr(csv, 'cross') or not hasattr(csv.cross, 'recommend'):
			raise ClientError('cross recommend config not found')
		
		if not hasattr(csv.cross.recommend, 'scene') or sceneType not in csv.cross.recommend.scene:
			raise ClientError('invalid sceneType')
		
		# 获取场景配置 - CSV对象用 [] 不用 .get()
		sceneCfg = csv.cross.recommend.scene[sceneType]
		
		# TODO: 这里需要从跨服服务器获取推荐数据
		# 目前先返回默认值
		result = {
			'sceneType': sceneType,
			'hasGroup': getattr(sceneCfg, 'hasGroup', 0),
			'pushTop': getattr(sceneCfg, 'pushTop', 5),
			'showTop': getattr(sceneCfg, 'showTop', 20),
			'recommends': []  # 推荐阵容列表，暂时返回空
		}
		
		self.write({
			'view': result
		})