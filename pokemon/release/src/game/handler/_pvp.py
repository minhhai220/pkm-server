#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

PVP Handlers
'''

from framework import period2date, date2int, nowtime_t, nowtime2period
from framework.csv import ErrDefs, csv, ConstDefs
from framework.helper import transform2list
from framework.log import logger
from game import ServerError, ClientError
from game.object import TargetDefs, SceneDefs, FeatureDefs, AchievementDefs, MessageDefs
from game.globaldata import ShopRefreshTime, ShopRefreshPeriods, PVPBattleItemID, PVPSkinIDStart
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object.game import ObjectGame, ObjectUnionContribTask
from game.object.game.rank import ObjectPWAwardEffect, ObjectArenaFlopAwardRandom
from game.object.game.shop import ObjectPVPShop
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.society import ObjectSocietyGlobal
from game.object.game.message import ObjectMessageGlobal
from game.object.game.gain import ObjectCostAux, ObjectGainEffect, ObjectGainAux
from game.object.game.union import ObjectUnion
from game.thinkingdata import ta
from tornado.gen import coroutine, Return
from nsqrpc.error import CallError

@coroutine
def makeBattleModel(game, rpc, dbc, refresh):
	model = yield rpc.call_async('GetAreaModel', game.role.id, game.role.pvp_record_db_id, refresh)
	# game_server rank缓存
	game.role.pw_rank = model['record']['rank']
	raise Return({
		'arena': model,
	})

@coroutine
def refreshCardsToPVP(rpc, game, cards=None, defence_cards=None, extra=None, defence_extra=None, force=False):
	if not game.role.pvp_record_db_id:
		raise Return(None)
	deployment = game.cards.deploymentForArena
	# 卡牌没发生改变
	if not any([force, cards, defence_cards, deployment.isdirty(), game.role.displayDirty, extra, defence_extra]):
		raise Return(None)
	game.role.displayDirty = True

	embattle = {}

	# 进攻阵容
	if cards:
		embattle['cards'] = cards
	cards, dirty = deployment.refresh('cards', SceneDefs.Arena, cards)
	
	# 获取进攻助战字典 {槽位: cardID}
	role = game.role
	aid_cards_dict = {}
	if role.card_embattle and 'arena' in role.card_embattle:
		aid_cards_dict = role.card_embattle['arena'].get('aid_cards', {})
		# 兼容老数据（数组格式）
		if isinstance(aid_cards_dict, list):
			aid_cards_dict = {i+1: v for i, v in enumerate(aid_cards_dict) if v is not None}
	aid_cards_values = aid_cards_dict.values() if isinstance(aid_cards_dict, dict) else filter(None, aid_cards_dict)
	
	# 生成主战卡牌属性
	embattle['card_attrs'], embattle['card_attrs2'] = game.cards.makeBattleCardModel(
		cards, SceneDefs.Arena, dirty=dirty)
	embattle['passive_skills'] = game.cards.markBattlePassiveSkills(cards, SceneDefs.Arena)
	
	# 为进攻助战卡牌生成属性，合并到 card_attrs 中，并计算总战力
	aid_fighting_point = 0
	if aid_cards_values and len(list(aid_cards_values)) > 0:
		aid_cards_values = aid_cards_dict.values() if isinstance(aid_cards_dict, dict) else filter(None, aid_cards_dict)
		aid_attrs, aid_attrs2 = game.cards.makeBattleCardModel(list(aid_cards_values), SceneDefs.Arena, is_aid=True)
		# 合并助战卡牌属性到card_attrs
		embattle['card_attrs'].update(aid_attrs)
		embattle['card_attrs2'].update(aid_attrs2)
		# 累加助战战斗力
		for aid_attr in aid_attrs.values():
			aid_fighting_point += aid_attr.get('aid_fighting_point', 0)
	embattle['aid_fighting_point'] = aid_fighting_point

	# 防守阵容
	if defence_cards:
		embattle['defence_cards'] = defence_cards
	defence_cards, defence_dirty = deployment.refresh('defence_cards', SceneDefs.Arena, defence_cards)
	
	# 获取防守助战字典 {槽位: cardID}
	defence_aid_cards_dict = {}
	if role.card_embattle and 'arena' in role.card_embattle:
		defence_aid_cards_dict = role.card_embattle['arena'].get('defence_aid_cards', {})
		# 兼容老数据（数组格式）
		if isinstance(defence_aid_cards_dict, list):
			defence_aid_cards_dict = {i+1: v for i, v in enumerate(defence_aid_cards_dict) if v is not None}
	defence_aid_cards_values = defence_aid_cards_dict.values() if isinstance(defence_aid_cards_dict, dict) else filter(None, defence_aid_cards_dict)
	
	# 生成防守卡牌属性
	embattle['defence_card_attrs'], embattle['defence_card_attrs2'] = game.cards.makeBattleCardModel(
		defence_cards, SceneDefs.Arena, dirty=defence_dirty)
	embattle['defence_passive_skills'] = game.cards.markBattlePassiveSkills(defence_cards, SceneDefs.Arena)
	
	# 为防守助战卡牌生成属性，合并到 defence_card_attrs 中，并计算总战力
	defence_aid_fighting_point = 0
	if defence_aid_cards_values and len(list(defence_aid_cards_values)) > 0:
		defence_aid_cards_values = defence_aid_cards_dict.values() if isinstance(defence_aid_cards_dict, dict) else filter(None, defence_aid_cards_dict)
		aid_attrs, aid_attrs2 = game.cards.makeBattleCardModel(list(defence_aid_cards_values), SceneDefs.Arena, is_aid=True)
		# 合并助战卡牌属性到defence_card_attrs
		embattle['defence_card_attrs'].update(aid_attrs)
		embattle['defence_card_attrs2'].update(aid_attrs2)
		# 累加助战战斗力
		for aid_attr in aid_attrs.values():
			defence_aid_fighting_point += aid_attr.get('aid_fighting_point', 0)
	embattle['defence_aid_fighting_point'] = defence_aid_fighting_point

	# 额外战斗数据 比如天气
	if extra is not None:
		embattle['extra'] = _normalize_battle_extra(extra)
	if defence_extra is not None:
		embattle['defence_extra'] = _normalize_battle_extra(defence_extra)
	
	# 助战卡牌数据 - 总是发送字典格式
	embattle['aid_cards'] = aid_cards_dict
	embattle['defence_aid_cards'] = defence_aid_cards_dict

	deployment.resetdirty()
	yield rpc.call_async('Deploy', game.role.pvp_record_db_id, game.role.competitor, embattle)

# 排位赛获取战斗信息
class PWBattleGet(RequestHandlerTask):
	url = r'/game/pw/battle/get'

	@coroutine
	def run(self):
		# 判断是否具备开启条件
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.PVP, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		# 新建PVPRecord
		if self.game.role.pvp_record_db_id is None:
			cards = self.game.role.battle_cards
			cardsD, cardsD2 = self.game.cards.makeBattleCardModel(cards, SceneDefs.Arena)
			passiveSkills = self.game.cards.markBattlePassiveSkills(cards, SceneDefs.Arena)

			dbID = max(cardsD, key=lambda x: cardsD[x]['fighting_point'])
			display = cardsD[dbID]['skin_id']
			if not display:
				display = cardsD[dbID]['card_id']

			fightingPoint = 0
			for _, model in cardsD.iteritems():
				fightingPoint += model['fighting_point']

			embattle = {
				'cards': cards,
				'defence_cards': cards,
				'passive_skills': passiveSkills,
				'card_attrs': cardsD,
				'card_attrs2': cardsD2,
				'extra': _normalize_battle_extra(None),           # => {'weather':0,'arms':[]}
				'defence_card_attrs': cardsD,
				'defence_card_attrs2': cardsD2,
				'defence_passive_skills': passiveSkills,
				'defence_extra': _normalize_battle_extra(None),
				'aid_cards': {},                                  # 空字典格式
				'defence_aid_cards': {},                          # 空字典格式
			}

			role = self.game.role
			role.pvp_record_db_id = yield self.rpcArena.call_async('CreateArenaRecord', role.competitor, embattle, fightingPoint, display, False)

			deployment = self.game.cards.deploymentForArena
			deployment.deploy('cards', self.game.role.battle_cards)
			deployment.deploy('defence_cards', self.game.role.battle_cards)
			role.deployments_sync['arena_defence_cards'] = True # 默认同步
		else:
			yield refreshCardsToPVP(self.rpcArena, self.game)

		needRefresh = self.input.get('needRefresh', 0)
		if needRefresh == 1:
			costRMB = ObjectCostCSV.getPvpEnermysFreshCost(self.game.dailyRecord.pvp_enermys_refresh_times)

			cost = ObjectCostAux(self.game, {'rmb': costRMB})
			if not cost.isEnough():
				raise ClientError(ErrDefs.buyRMBNotEnough)
			cost.cost(src='pw_battle_refresh')

			self.game.dailyRecord.pvp_enermys_refresh_times += 1

		model = yield makeBattleModel(self.game, self.rpcArena, self.dbcGame, True if needRefresh == 1 else False)
		
		# 添加助战卡牌数据到返回的 model 中
		# 优先使用Go返回的数据，如果Go没有返回则从role.card_embattle补充
		role = self.game.role
		if 'record' in model:
			# DEBUG: 打印Go返回的record
			logger.info('[PWBattleGet] Go返回aid_cards: %s, defence_aid_cards: %s', 
				model['record'].get('aid_cards'), model['record'].get('defence_aid_cards'))
			
			# 如果Go的Record中没有助战数据，从card_embattle补充
			if 'aid_cards' not in model['record'] and role.card_embattle and 'arena' in role.card_embattle:
				aid_cards = role.card_embattle['arena'].get('aid_cards', {})
				model['record']['aid_cards'] = aid_cards
				logger.info('[PWBattleGet] 从card_embattle补充aid_cards: %s', aid_cards)
			if 'defence_aid_cards' not in model['record'] and role.card_embattle and 'arena' in role.card_embattle:
				defence_aid_cards = role.card_embattle['arena'].get('defence_aid_cards', {})
				model['record']['defence_aid_cards'] = defence_aid_cards
				logger.info('[PWBattleGet] 从card_embattle补充defence_aid_cards: %s', defence_aid_cards)
		
		self.write({'model': model})


def _normalize_battle_extra(data):
	"""
	输入可为 None 或 dict，返回 {'weather': int, 'arms': List[List[int]]}
	"""
	if not isinstance(data, dict):
		return {'weather': 0, 'arms': []}

	# weather
	w = data.get('weather', 0)
	try:
		w = int(w) if w is not None else 0
	except Exception:
		w = 0

	# arms -> list[list[int]]
	arms_in = data.get('arms', [])
	arms_out = []
	if isinstance(arms_in, (list, tuple)):
		for grp in arms_in:
			if isinstance(grp, (list, tuple)):
				grp_norm = []
				for x in grp:
					# 允许 str/float/int，能转 int 就收
					try:
						grp_norm.append(int(x))
					except Exception:
						pass
				arms_out.append(grp_norm)

	return {'weather': w, 'arms': arms_out}


# 竞技场布阵
class PWBattleDeploy(RequestHandlerTask):
	url = r'/game/pw/battle/deploy'

	@coroutine
	def run(self):
		from copy import deepcopy
		role = self.game.role
		if role.pvp_record_db_id is None:
			raise ClientError('pvp not opened')

		cards = self.input.get('cards', None)
		defenceCards = self.input.get('defenceCards', None)
		aidCards = self.input.get('aidCards', None)
		defenceAidCards = self.input.get('defenceAidCards', None)

		if cards:
			cards = transform2list(cards)
			if self.game.cards.isDuplicateMarkID(cards):
				raise ClientError('cards have duplicates')
		if defenceCards:
			defenceCards = transform2list(defenceCards)
			if self.game.cards.isDuplicateMarkID(defenceCards):
				raise ClientError('cards have duplicates')
			self.game.role.deployments_sync['arena_defence_cards'] = False

		# 保存助战卡牌到 card_embattle
		if aidCards is not None or defenceAidCards is not None:
			card_embattle = role.card_embattle
			if card_embattle is None:
				card_embattle = {}
			if 'arena' not in card_embattle:
				card_embattle['arena'] = {}
			if aidCards is not None:
				if isinstance(aidCards, dict):
					card_embattle['arena']['aid_cards'] = {k: v for k, v in aidCards.iteritems() if v is not None}
				else:
					card_embattle['arena']['aid_cards'] = {i+1: v for i, v in enumerate(aidCards) if v is not None}
			if defenceAidCards is not None:
				if isinstance(defenceAidCards, dict):
					card_embattle['arena']['defence_aid_cards'] = {k: v for k, v in defenceAidCards.iteritems() if v is not None}
				else:
					card_embattle['arena']['defence_aid_cards'] = {i+1: v for i, v in enumerate(defenceAidCards) if v is not None}
			role.card_embattle = card_embattle

		# NEW: 天气/兵种
		extra = self.input.get('extra', None)                 # 期望 {'weather':15,'arms':[[1],[2]]}
		defence_extra = self.input.get('defenceExtra', None)  # 同上

		yield refreshCardsToPVP(
			self.rpcArena,
			self.game,
			cards=cards,
			defence_cards=defenceCards,
			extra=extra,
			defence_extra=defence_extra
		)
		model = yield makeBattleModel(self.game, self.rpcArena, self.dbcGame, False)
		
		# 添加助战卡牌数据到返回的 model 中
		# 优先使用Go返回的数据，如果Go没有返回则从role.card_embattle补充
		if 'record' in model:
			if 'aid_cards' not in model['record'] and role.card_embattle and 'arena' in role.card_embattle:
				model['record']['aid_cards'] = role.card_embattle['arena'].get('aid_cards', {})
			if 'defence_aid_cards' not in model['record'] and role.card_embattle and 'arena' in role.card_embattle:
				model['record']['defence_aid_cards'] = role.card_embattle['arena'].get('defence_aid_cards', {})
		
		self.write({'model': model})

class PWBattleStart(RequestHandlerTask):
	url = r'/game/pw/battle/start'

	@coroutine
	def run(self):
		role = self.game.role
		if role.pvp_record_db_id is None:
			raise ClientError('pvp not opened')
		dailyRecord = self.game.dailyRecord

		myRank = self.input.get('myRank', None)
		battleRank = self.input.get('battleRank', None)
		if battleRank <= 10 and myRank > 20:
			raise ClientError(ErrDefs.pvpRank10Limit)

		enemyRoleID = self.input.get('enemyRoleID', None)
		enemyRecordID = self.input.get('enemyRecordID', None)

		if not all([x is not None for x in [myRank, battleRank, enemyRoleID, enemyRecordID]]):
			raise ClientError('param miss')
		if enemyRoleID == role.id:
			raise ClientError(ErrDefs.pvpSelfErr)

		# 次数 / CD 判定
		if dailyRecord.pvp_pw_times >= role.freePWTimes + dailyRecord.buy_pw_times + dailyRecord.item_pw_times:
			cost = ObjectCostAux(self.game, {PVPBattleItemID: 1})
			if not cost.isEnough():
				raise ClientError(ErrDefs.todayChanllengeToMuch)
			cost.cost(src='pw_battle_itemUse')
			dailyRecord.item_pw_times += 1
			self.game.dailyRecord.pvp_pw_last_time = 0
		else:
			if not self.game.privilege.pwNoCD:
				delta = nowtime_t() - dailyRecord.pvp_pw_last_time
				if delta < role.PWcoldTime:
					raise ClientError(ErrDefs.rankTimerNoCD)

		try:
			# 开战
			model = yield self.rpcArena.call_async(
				'BattleStart', myRank, battleRank, role.id, role.pvp_record_db_id, enemyRoleID, enemyRecordID
			)
		except CallError, e:
			if e.msg in (ErrDefs.rankEnemyBattling, ErrDefs.rankEnemyChanged):
				modelBattle = yield makeBattleModel(self.game, self.rpcArena, self.dbcGame, True)
				raise ClientError(e.msg, model=modelBattle)
			raise ClientError(e.msg)

		# ====== 新增：把 ArenaRecord 上的 extra/defence_extra/aid_cards 取出并附加到返回 ======
		try:
				areaModel = yield self.rpcArena.call_async('GetAreaModel', role.id, role.pvp_record_db_id, False)
				rec = (areaModel or {}).get('record', {}) or {}
				attack_extra = _normalize_battle_extra(rec.get('extra'))
				model['extra'] = attack_extra          # 我方天气/兵种
				# 添加我方助战卡牌字典
				aid_cards = rec.get('aid_cards', {})
				if aid_cards:
					model['aid_cards'] = aid_cards
		except Exception:
				# 不影响开战流程，取失败就忽略
				pass

		try:
				enemyRecord = yield self.rpcArena.call_async('GetArenaRoleInfo', enemyRecordID)
				defence_extra = _normalize_battle_extra((enemyRecord or {}).get('defence_extra'))
				model['defence_extra'] = defence_extra # 敌方（对手的防守配置）
				# 添加敌方助战卡牌字典
				defence_aid_cards = (enemyRecord or {}).get('defence_aid_cards', {})
				if defence_aid_cards:
					model['defence_aid_cards'] = defence_aid_cards
		except Exception:
				# 不影响开战流程，取失败就忽略
				pass
		# ====== 新增结束 ======

		# 计次/积分
		dailyRecord.pvp_pw_times += 1
		if role.PWpointActive == 1 or role.level >= 45:
			dailyRecord.pvp_result_point += 2
		else:
			dailyRecord.pvp_result_point += 1
		dailyRecord.pvp_pw_last_time = nowtime_t()
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.ArenaBattle, 1)
		self.game.achievement.onCount(AchievementDefs.ArenaBattle, 1)

		self.write({
			'model': {
				'arena_battle': model,
			}
		})


# 排位赛结束战斗
class PWBattleEnd(RequestHandlerTask):
	url = r'/game/pw/battle/end'

	@coroutine
	def run(self):
		rank = self.input.get('rank', None)
		result = self.input.get('result', None)
		if not all([x is not None for x in [rank, result]]):
			raise ClientError('param miss')

		myRole = self.game.role
		try:
			ret = yield self.rpcArena.call_async('BattleEnd', rank, myRole.id, myRole.pvp_record_db_id, result)
		except CallError, e:
			# 可能作弊了
			raise ClientError(e.msg)
		except:
			raise

		rank = ret['rank']
		# game_server rank缓存
		self.game.role.pw_rank = rank
		if ret['rank_move'] != 0 and rank == 1:
			ObjectMessageGlobal.newsPVPTopRankMsg(self.game.role)
			ObjectMessageGlobal.marqueeBroadcast(self.game.role, MessageDefs.MqPvpTopRank)

		# 刷新排名奖励
		if rank > 0:
			for idx in csv.pwrank_award:
				cfg = csv.pwrank_award[idx]
				award = self.game.role.pw_rank_award.get(idx,None)
				if award is None and rank <= cfg.needRank:
					self.game.role.pw_rank_award[idx] = 1

		# 翻牌
		flopResult = ObjectArenaFlopAwardRandom.flop(True if result == 'win' else False)
		eff = ObjectGainEffect(self.game, flopResult['award'], None)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='arena_flop_award')

		if result == 'win':
			if myRole.PWpointActive != 1 and myRole.level < 45:
				self.game.dailyRecord.pvp_result_point += 1 # 非VIP的begin已经加过1
			modelBattle = yield makeBattleModel(self.game, self.rpcArena, self.dbcGame, True)
			ObjectUnionContribTask.onCount(self.game, TargetDefs.ArenaBattleWin, 1)
		else:
			modelBattle = yield makeBattleModel(self.game, self.rpcArena, self.dbcGame, False)

		view = ret
		view['result'] = result
		view.update(flopResult)
		result = {
			'view': view,
			'model': modelBattle,
		}

		self.write(result)


		ta.track(self.game, event='end_arena',result=result)

# 排位赛 5次碾压
class PWBattlePass(RequestHandlerTask):
	url = r'/game/pw/battle/pass'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.PvpPass, self.game):
			raise ClientError('pvp_pass not open')
		role = self.game.role
		if role.pvp_record_db_id is None:
			raise ClientError('pvp not opened')

		battleRank = self.input.get('battleRank', None)
		if not battleRank:
			raise ClientError('param miss')
		if role.pw_rank >= battleRank:
			raise ClientError("battleRole rank error")

		dailyRecord = self.game.dailyRecord
		# 剩余可用挑战次数
		canPwTimes = role.freePWTimes + dailyRecord.buy_pw_times + dailyRecord.item_pw_times - dailyRecord.pvp_pw_times
		# 券的数量
		pwItemsCount = self.game.items.getItemCount(PVPBattleItemID)

		if canPwTimes >= 5:
			costPwItemsCount = 0
			needBuyTimes = 0
		else:
			# 需用券或再购买 优先用券
			if 0 < canPwTimes < 5:
				needTimes = 5 - canPwTimes
			else:
				needTimes = 5
			if pwItemsCount >= needTimes:  # 券足够
				costPwItemsCount = needTimes
				needBuyTimes = 0
			else:
				costPwItemsCount = pwItemsCount
				needBuyTimes = needTimes - costPwItemsCount

		# 购买次数限制
		if dailyRecord.buy_pw_times + needBuyTimes >= role.buyPWMaxTimes:
			raise ClientError(ErrDefs.pwBuyMax)

		# 消耗RMB = 购买次数的消耗RMB + 固定消耗
		costRMB = 0
		for i in xrange(0, needBuyTimes):
			costRMB += ObjectCostCSV.getPWBuyCost(self.game.dailyRecord.buy_pw_times + i)
		costRMB += ConstDefs.pvpPassCostRmb
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		# 消耗券
		if costPwItemsCount:
			cost += ObjectCostAux(self.game, {PVPBattleItemID: costPwItemsCount})
		if not cost.isEnough():
			raise ClientError('cost rmb not enough')
		cost.cost(src='pvp_pass5')

		# 重置挑战时间
		dailyRecord.pvp_pw_last_time = 0
		# 挑战次数+5
		dailyRecord.pvp_pw_times += 5
		# 购买次数加上
		dailyRecord.buy_pw_times += needBuyTimes
		# 券增加次数记录
		dailyRecord.item_pw_times += costPwItemsCount

		# 积分加 2*5
		dailyRecord.pvp_result_point += 2 * 5

		# 翻5次
		ret = []
		for i in xrange(5):
			# 翻牌
			flopResult = ObjectArenaFlopAwardRandom.flop(True)
			effOne = ObjectGainAux(self.game, flopResult['award'])
			yield effectAutoGain(effOne, self.game, self.dbcGame, src='pvp_pass5_award')
			ret.append(effOne.result)

		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.ArenaBattle, 5)
		self.game.achievement.onCount(AchievementDefs.ArenaBattle, 5)
		ObjectUnionContribTask.onCount(self.game, TargetDefs.ArenaBattleWin, 5)

		self.write({'view': ret})


# 购买排位赛次数
class PWBattleBuy(RequestHandlerTask):
	url = r'/game/pw/battle/buy'

	@coroutine
	def run(self):
		if self.game.dailyRecord.buy_pw_times >= self.game.role.buyPWMaxTimes:
			raise ClientError(ErrDefs.pwBuyMax)

		costRMB = ObjectCostCSV.getPWBuyCost(self.game.dailyRecord.buy_pw_times)

		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='pw_battle_buy')

		self.game.dailyRecord.buy_pw_times += 1
		# 重置挑战时间
		self.game.dailyRecord.pvp_pw_last_time = 0


# 获取排位赛录像数据
class PWPlayRecordGet(RequestHandlerTask):
	url = r'/game/pw/playrecord/get'

	@coroutine
	def run(self):
		from framework.helper import string2objectid, objectid2string
		from game.server import Server

		recordID = self.input.get('recordID', None)
		gameKey = self.input.get('gameKey', None)  # 跨服查看时传递目标服务器
		if recordID is None:
			raise ClientError('param miss')

		# 保存原始 recordID 用于返回（前端需要用这个 key 查找）
		originalRecordID = recordID

		# 如果是字符串格式，转换为 ObjectId
		if isinstance(recordID, basestring):
			# 24字符是十六进制格式，12字节是二进制格式
			if len(recordID) == 24:
				recordID = string2objectid(recordID)
			# 12字节二进制格式，直接使用（已经是 ObjectId 的二进制表示）

		# 判断是否跨服查看
		myKey = Server.Singleton.key if Server.Singleton else None
		isCross = (gameKey and gameKey != myKey)

		if isCross:
			# 跨服查看：通过RPC调用目标服务器
			model = yield self._queryCrossPlayRecord(gameKey, recordID)
		else:
			model = yield self.rpcArena.call_async('GetArenaPlayRecord', recordID)

		if not model:
			raise ClientError('record not found')

		self.write({
			'model': {
				'arena_playrecords': {
					originalRecordID: model,  # 使用原始 recordID 作为 key
				}
			}
		})

	@coroutine
	def _queryCrossPlayRecord(self, gameKey, recordID):
		'''跨服查询战报'''
		from game.server import Server
		from framework.helper import objectid2string
		from framework.log import logger
		from tornado.gen import Return
		from nsqrpc.error import CallError

		model = None
		try:
			container = Server.Singleton.container
			client = container.getserviceOrCreate(gameKey)
			if not client:
				logger.warning('_queryCrossPlayRecord: client is None for gameKey=%s', gameKey)
				raise Return(None)

			model = yield client.call_async('CrossGetPlayRecord', objectid2string(recordID))
		except Return:
			raise
		except CallError as e:
			logger.warning('_queryCrossPlayRecord RPC error: %s', e)
		except Exception as e:
			logger.warning('_queryCrossPlayRecord error: %s', e)

		raise Return(model)


# 竞技场积分商店购买
class PWShopBuy(RequestHandlerTask):
	url = r'/game/pw/shop/buy'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		count = self.input.get('count', 1)
		if csvID is None:
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')

		pvpShop = ObjectPVPShop(self.game)
		eff = pvpShop.buyItem(csvID, count, src='pvp_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='pvp_shop_buy')



# 购买排位赛冷却时间
class PWBattleCDBuy(RequestHandlerTask):
	url = r'/game/pw/battle/cd/buy'

	@coroutine
	def run(self):
		costRMB = ObjectCostCSV.getPWCDBuyCost(self.game.dailyRecord.buy_pw_cd_times)

		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='pw_battle_cd_buy')

		# 重置挑战时间
		self.game.dailyRecord.pvp_pw_last_time = 0
		self.game.dailyRecord.buy_pw_cd_times += 1


# 领取排位赛排名奖励
class PWBattleRankAward(RequestHandlerTask):
	url = r'/game/pw/battle/rank/award'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		if csvID is None or csvID not in csv.pwrank_award:
			raise ClientError('csvID err')

		flag = self.game.role.pw_rank_award.get(csvID,-1)
		if flag == -1:
			raise ClientError(ErrDefs.pwRankAwardLimit)
		if flag == 0:
			raise ClientError(ErrDefs.pwAwardAreadyHas)

		cfg = csv.pwrank_award[csvID]
		if cfg.cost:
			cost = ObjectCostAux(self.game, cfg.cost)
			if not cost.isEnough():
				raise ClientError('not enough')
			cost.cost(src='pw_rank_award')
		eff = ObjectPWAwardEffect(self.game, cfg.award)
		self.game.role.pw_rank_award[csvID] = 0
		yield effectAutoGain(eff, self.game, self.dbcGame, src='pw_rank_award')

# 领取排位赛积分奖励
class PWBattlePointAward(RequestHandlerTask):
	url = r'/game/pw/battle/point/award'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		if csvID is None:
			raise ClientError('csvID miss')
		retEff = None
		if csvID == -1: # 一键领取
			for csvID, flag in self.game.dailyRecord.result_point_award.iteritems():
				if flag == 1:
					cfg = csv.pwpoint_award[csvID]
					eff = ObjectPWAwardEffect(self.game, cfg.award)
					if retEff is None:
						retEff = eff
					elif eff:
						retEff += eff
					self.game.dailyRecord.result_point_award[csvID] = 0
		else:
			if csvID not in csv.pwpoint_award:
				raise ClientError('csvID err')
			flag = self.game.dailyRecord.result_point_award.get(csvID,-1)
			if flag == -1:
				raise ClientError(ErrDefs.pwPointAwardLimit)
			if flag == 0:
				raise ClientError(ErrDefs.pwAwardAreadyHas)

			cfg = csv.pwpoint_award[csvID]
			retEff = ObjectPWAwardEffect(self.game, cfg.award)
			self.game.dailyRecord.result_point_award[csvID] = 0
		ret = {}
		if retEff:
			yield effectAutoGain(retEff, self.game, self.dbcGame, src='pw_point_award')
			ret = retEff.result

		self.write({
			'view': ret,
		})

# 道具增加排位赛次数
class PWBattleItemUse(RequestHandlerTask):
	url = r'/game/pw/battle/item/use'

	@coroutine
	def run(self):
		cost = ObjectCostAux(self.game, {PVPBattleItemID: 1})
		if not cost.isEnough():
			raise ClientError(ErrDefs.pwBattleItemLimit)
		cost.cost(src='pw_battle_itemUse')

		self.game.dailyRecord.item_pw_times += 1
		# 重置挑战时间
		self.game.dailyRecord.pvp_pw_last_time = 0

# 竞技场选择展示卡牌
class PWBattleDisplay(RequestHandlerTask):
	url = r'/game/pw/display'

	@coroutine
	def run(self):
		role = self.game.role
		if role.pvp_record_db_id == 0:
			raise ClientError('pvp not opened')
		card_id = self.input.get('card_id', None)
		if card_id is None:
			raise ClientError('card_id miss')
		# 精灵图鉴 或 皮肤
		if card_id not in role.pokedex and (card_id % PVPSkinIDStart) not in role.skins:
			raise ClientError('card_id error')

		self.rpcArena.call_async('UpdateDisplay', role.pvp_record_db_id, card_id)

		self.write({
			'sync': {
				'arena': {
					'record': {'display': card_id},
				}
			}
		})

# 竞技场查看玩家信息
class PWBattleRoleInfo(RequestHandlerTask):
	url = r'/game/pw/role/info'

	@coroutine
	def run(self):
		recordID = self.input.get('recordID', None)
		if recordID is None:
			raise ClientError('recordID miss')

		view = yield self.rpcArena.call_async('GetArenaRoleInfo', recordID)
		view['union_name'] = ObjectUnion.queryUnionName(view['role_db_id'])
		
		# DEBUG: 打印返回的助战数据
		logger.info('[PWRoleInfo] 返回aid_cards: %s, defence_aid_cards: %s', 
			view.get('aid_cards'), view.get('defence_aid_cards'))
		
		self.write({
			'view': view,
		})

# 竞技场排名查看
class PWBattleRank(RequestHandlerTask):
	url = r'/game/pw/rank'

	@coroutine
	def run(self):
		offest = self.input.get('offest', 0)
		size = self.input.get('size', 50)

		ret = yield self.rpcArena.call_async('GetArenaTop50', offest, size)
		self.write({
			'view': {
				'rank': ret,
				'offest': offest,
				'size': size,
			},
		})
