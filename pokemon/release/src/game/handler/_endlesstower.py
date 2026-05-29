#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Endless Tower Handlers
'''
import copy
import random

from framework import todayinclock5elapsedays, datetimefromtimestamp
from framework.csv import csv, ErrDefs
from framework.helper import transform2list
from framework.log import logger
from game import ClientError, ServerError
from game.globaldata import EndlessTowerHuodongID, AbyssEndlessTowerHuodongID
from game.handler.inl import effectAutoGain
from game.handler.task import RequestHandlerTask

from game.object import EndlessTowerDefs, FeatureDefs, YYHuoDongDefs, MessageDefs, ReunionDefs
from game.object.game import ObjectFeatureUnlockCSV, ObjectYYHuoDongFactory
from game.object.game.battle import ObjectEndlessTowerBattle, ObjectEndlessTowerSaoDang, ObjectAbyssEndlessTowerBattle
from game.object.game.gain import ObjectGainAux
from game.object.game.endlesstower import ObjectEndlessTowerGlobal
from game.object.game.message import ObjectMessageGlobal
from game.object.game.rank import ObjectRankGlobal
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.gain import ObjectCostAux
from game.thinkingdata import ta
from tornado.gen import coroutine

# 无限塔关卡战斗开始
class EndlessTowerBattleStart(RequestHandlerTask):
	url = r'/game/endless/battle/start'

	@coroutine
	def run(self):
		gateID = self.input.get('gateID', None)
		cardIDs = self.input.get('cardIDs', None)
		extra = self.input.get('extra', None)

		# 深渊模式判断 (gateID >= 200001)
		isAbyss = gateID and gateID >= 200001

		if isAbyss:
			# 深渊模式
			huodongID = AbyssEndlessTowerHuodongID
			if not cardIDs:
				cardIDs = self.game.role.huodong_cards.get(huodongID, copy.deepcopy(self.game.role.battle_cards))
			else:
				self.game.role.deployHuodongCards(huodongID, cardIDs)
				cardIDs = transform2list(cardIDs)

			if any([x is None for x in [gateID, cardIDs]]):
				raise ClientError('param miss')

			# 保存天气数据
			if extra:
				# 深渊模式支持多队天气 (extra 是数组)
				if isinstance(extra, list):
					# 获取或创建活动数据
					huodong_cards_multi = self.game.role.huodong_cards_multi or {}
					huodong_data = huodong_cards_multi.get(huodongID, {})
					teamCount = len(extra)  # 2 或 3
					# 将平铺的 cardIDs 转换为字典格式 {1: [team1], 2: [team2]}
					nestedCards = {}
					nestedExtra = {}
					for i in xrange(teamCount):
						nestedCards[i + 1] = cardIDs[i*6:(i+1)*6]
						nestedExtra[i + 1] = extra[i] if i < len(extra) else {'weather': 0, 'arms': []}
					huodong_data[teamCount] = {
						'cards': nestedCards,
						'aidCards': [],
						'extra': nestedExtra
					}
					huodong_cards_multi[huodongID] = huodong_data
					# 显式赋值回去触发保存
					self.game.role.huodong_cards_multi = huodong_cards_multi
				else:
					weather = extra.get('weather', 0)
					arms = extra.get('arms', []) or []
					self.game.role.deployBattleExtra(weather, arms)

			self.game.battle = ObjectAbyssEndlessTowerBattle(self.game)
			ret = self.game.battle.begin(gateID, cardIDs)
			self.write({
				'model': ret
			})
		else:
			# 普通无限塔
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.EndlessTower, self.game):
				raise ClientError('locked')
			if ObjectEndlessTowerGlobal.maybeCheatRole(self.game.role.id):
				raise ClientError(ErrDefs.cheatError)

			if not cardIDs:
				cardIDs = self.game.role.huodong_cards.get(EndlessTowerHuodongID, copy.deepcopy(self.game.role.battle_cards))
			else:
				self.game.role.deployHuodongCards(EndlessTowerHuodongID, cardIDs)
				cardIDs = transform2list(cardIDs)

			if any([x is None for x in [gateID, cardIDs]]):
				raise ClientError('param miss')

			# 保存天气数据到 role.battle_extra
			if extra:
				weather = extra.get('weather', 0)
				arms = extra.get('arms', []) or []
				self.game.role.deployBattleExtra(weather, arms)

			self.game.battle = ObjectEndlessTowerBattle(self.game)
			ret = self.game.battle.begin(gateID, cardIDs)
			self.write({
				'model': ret
			})


# 无限塔关卡战斗结束
class EndlessTowerBattleEnd(RequestHandlerTask):
	url = r'/game/endless/battle/end'

	@coroutine
	def run(self):
		battleID = self.input.get('battleID', None)
		gateID = self.input.get('gateID', None)
		result = self.input.get('result', None)
		round = self.input.get('round', None)
		actions = self.input.get('actions', None)

		# 深渊模式判断
		isAbyss = isinstance(self.game.battle, ObjectAbyssEndlessTowerBattle)

		if isAbyss:
			# 深渊模式战斗结束
			if any([x is None for x in [gateID, battleID, result]]):
				raise ClientError('param miss')
			if gateID != self.game.battle.gateID:
				raise ClientError('gateID error')
			if battleID != self.game.battle.id:
				raise ClientError('battleID error')

			if isinstance(actions, list):
				actions = {idx + 1: v for idx, v in enumerate(actions)}

			if result == 'win':
				cfg = csv.abyss_endless_tower.scene[gateID]
				if self.game.role.top6_fighting_point < cfg.lowestFightingPoint:
					raise ClientError(ErrDefs.lowestFightingPointLimit)

			role = self.game.role
			self.game.battle.combine(result, round, actions)

			# 战斗结算
			eff = self.game.battle.result(result, round, actions)
			if eff:
				yield effectAutoGain(eff, self.game, self.dbcGame, src='abyss_endless_drop_%d' % gateID)

			# 战斗结算完毕
			ret = self.game.battle.end()
			ret['view']['drop'] = eff.result if eff else {}

			if self.game.battle.isUpdRank:
				yield ObjectRankGlobal.onKeyInfoChange(self.game, 'abyss_endless')

			self.write(ret)

			# 记录首通战报
			if result == 'win':
				if round is not None and actions is not None:
					first = True if role.abyss_endless_tower_current > role.abyss_endless_tower_max_gate else False
					if first:
						yield ObjectEndlessTowerGlobal.recordAbyssPlay(self.game.battle.battle_model, role)

			self.game.battle = None
		else:
			# 普通无限塔战斗结束
			if not isinstance(self.game.battle, ObjectEndlessTowerBattle):
				raise ServerError('endlessTower battle miss')

			if any([x is None for x in [gateID, battleID, result]]):
				raise ClientError('param miss')
			if gateID != self.game.battle.gateID:
				raise ClientError('gateID error')
			if battleID != self.game.battle.id:
				raise ClientError('battleID error')

			# lua的msgpack会把顺序数值下标的table认为是list
			if isinstance(actions, list):
				actions = {idx + 1: v for idx, v in enumerate(actions)}

			if result == 'win':
				cfg = csv.endless_tower_scene[gateID]
				if self.game.role.top6_fighting_point < cfg.lowestFightingPoint:
					raise ClientError(ErrDefs.lowestFightingPointLimit)

			role = self.game.role
			self.game.battle.combine(result, round, actions)
			if self.rpcAnti and result == 'win':
				ObjectEndlessTowerGlobal.sendToAntiCheatCheck(role.uid, role.id, role.name, self.game.battle.battle_model, result, self.rpcAnti)

			# 运营活动 双倍掉落
			yyTimes = 1
			if role.endless_tower_current <= role.endless_tower_max_gate:
				yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleEndlessSaodang)
				if yyID:
					yyTimes = 2
			# 战斗结算
			eff = self.game.battle.result(result, round, actions)
			if eff:
				yield effectAutoGain(eff, self.game, self.dbcGame, src='endlessTower_drop_%d' % gateID, mul=yyTimes)

			# 战斗结算完毕
			ret = self.game.battle.end()
			ret['view']['drop'] = eff.result
			if self.game.battle.isUpdRank:
				yield ObjectRankGlobal.onKeyInfoChange(self.game, 'endless')
			self.write(ret)

			if result == 'win':
				self.game.dailyRecord.endless_challenge += 1
				if round is not None and actions is not None:
					first = True if self.game.role.endless_tower_current > self.game.role.endless_tower_max_gate else False
					if first:  # 记录首通的战报
						ObjectEndlessTowerGlobal.recordPlay(self.game.battle.battle_model, self.game.role)
						ObjectMessageGlobal.marqueeBroadcast(self.game.role, MessageDefs.MqEndlessTowerPass, num=role.endless_tower_current-1)
						ObjectMessageGlobal.newsEndlessTowerPassMsg(self.game.role, role.endless_tower_current-1)
			self.game.battle = None


# 无限塔 扫荡
class EndlessTowerSaodang(RequestHandlerTask):
	url = r'/game/endless/saodang'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.EndlessTower, self.game):
			raise ClientError('locked')

		# 扫荡指定到关卡ID
		gateID = self.input.get('gateID', None)

		battle = ObjectEndlessTowerSaoDang(self.game)
		# 战斗数据
		battle.begin(gateID)

		# gateID 不传: 一键扫荡，否则: 关卡扫荡
		if gateID:
			self.game.dailyRecord.endless_challenge += 1
		else:
			count = self.game.role.endless_tower_max_gate - self.game.role.endless_tower_current + 1
			self.game.dailyRecord.endless_challenge += count

		# 战斗结算
		result = []
		# 运营活动 双倍掉落
		yyTimes = 1
		yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleEndlessSaodang)
		if yyID:
			yyTimes = 2

		# 重聚进度赶超 扫荡翻倍
		cfg = ObjectYYHuoDongFactory.getReunionCatchUpCfg(self.game.role, ReunionDefs.EndlessSaodang)
		if cfg and self.game.role.canReunionCatchUp(cfg):
			self.game.role.addReunionCatchUpRecord(cfg.id)
			yyTimes = 2

		# 遗迹祝福 - 冒险之路扫荡概率增加 (type=5, 持续时间效果)
		# 效果：增加概率掉落库(libs)的额外抽取概率
		relicProbAdd = 0
		if self.game.town:
			from game.object.game.town_lottery import ObjectTownRelicBuff
			relicProbAdd = ObjectTownRelicBuff.getActiveBuffParam(self.game, 5)
			if relicProbAdd > 0:
				logger.info('[RelicBuff] endless saodang: type=5 active, param=%s', relicProbAdd)

		effAll = battle.result()
		for eff in effAll:
			if eff:
				# 应用遗迹祝福：对 libs 概率掉落有额外抽取机会
				if relicProbAdd > 0 and hasattr(eff, '_draw_libs') and eff._draw_libs:
					from game.object.game.lottery import ObjectDrawRandomItem
					extraItems = {}
					for libID in eff._draw_libs:
						# 每个掉落库有 relicProbAdd 的概率额外抽一次
						if random.random() < relicProbAdd:
							obj = ObjectDrawRandomItem.getObject(libID)
							if obj:
								itemT = obj.getRandomItem(self.game)
								ObjectDrawRandomItem.packToDict(itemT, extraItems)
					if extraItems:
						extraEff = ObjectGainAux(self.game, extraItems)
						eff += extraEff
						logger.info('[RelicBuff] endless saodang: extra drop from libs: %s', extraItems)
				yield effectAutoGain(eff, self.game, self.dbcGame, src='endlessTower_saodang_drop', mul=yyTimes)
			result.append(eff.result)

		# 战斗结算完毕
		ret = battle.end()

		ret['view']['result'] = result

		self.write(ret)
		ta.track(self.game, event='endless_mopping_up',mopping_up_number=self.game.dailyRecord.endless_challenge)


# 无限塔 重置
class EndlessTowerReset(RequestHandlerTask):
	url = r'/game/endless/reset'

	@coroutine
	def run(self):
		resetTimes = self.game.dailyRecord.endless_tower_reset_times
		if self.game.role.endless_tower_current == ObjectEndlessTowerGlobal.MinGate:
			raise ClientError('can not reset')
		if resetTimes >= self.game.role.endlessTowerResetTimes:
			raise ClientError('endlessTower resetTimes has run out')
		else:
			cost = ObjectCostAux(self.game, {'rmb': ObjectCostCSV.getEndlessTowerResetTimesCost(resetTimes)})
			if not cost.isEnough():
				raise ClientError(ErrDefs.buyRMBNotEnough)
			cost.cost(src="endless_reset_times")
			resetTimes = resetTimes + 1
		self.game.role.endless_tower_current = ObjectEndlessTowerGlobal.MinGate
		self.game.dailyRecord.endless_tower_reset_times = resetTimes

		ta.track(self.game, event='endless_level_reset',current_reset_number=resetTimes)

# 无限塔 战报列表
class EndlessTowerPlays(RequestHandlerTask):
	url = r'/game/endless/plays/list'

	@coroutine
	def run(self):
		gateID = self.input.get('gateID', None)
		if not gateID:
			raise ClientError('param miss')

		# 根据gateID判断是深渊模式还是普通模式
		if gateID >= 200001:
			latesPlays = ObjectEndlessTowerGlobal.getAbyssLatestPlays(gateID)
		else:
			latesPlays = ObjectEndlessTowerGlobal.getLatestPlays(gateID)

		self.write({
			'view': {
				'latesPlays': latesPlays,
			}
		})


# 无限塔 战报详情
class EndlessTowerLowerPlayDetail(RequestHandlerTask):
	url = r'/game/endless/play/detail'

	@coroutine
	def run(self):
		playID = self.input.get('playID', None)
		if not playID:
			raise ClientError('param miss')

		playRecordData = yield self.dbcGame.call_async('DBRead', 'PVEBattlePlayRecord', playID, False)
		if not playRecordData['ret']:
			raise ClientError(ErrDefs.playRecordNotFound)
		else:
			model = playRecordData['model']

		self.write({
			'model': {
				'endless_playrecords': {
					playID: model
				}
			}
		})


# =============================================
# 深渊无限塔 (Abyss Endless Tower)
# =============================================

# 深渊无限塔关卡战斗开始
class AbyssEndlessTowerBattleStart(RequestHandlerTask):
	url = r'/game/abyss/endless/battle/start'

	@coroutine
	def run(self):
		gateID = self.input.get('gateID', None)
		cardIDs = self.input.get('cardIDs', None)
		extra = self.input.get('extra', None)

		if not cardIDs:
			cardIDs = self.game.role.huodong_cards.get(AbyssEndlessTowerHuodongID, copy.deepcopy(self.game.role.battle_cards))
		else:
			self.game.role.deployHuodongCards(AbyssEndlessTowerHuodongID, cardIDs)
			cardIDs = transform2list(cardIDs)

		if any([x is None for x in [gateID, cardIDs]]):
			raise ClientError('param miss')

		# 保存天气数据到 role.battle_extra
		if extra:
			weather = extra.get('weather', 0)
			arms = extra.get('arms', []) or []
			self.game.role.deployBattleExtra(weather, arms)

		self.game.battle = ObjectAbyssEndlessTowerBattle(self.game)
		ret = self.game.battle.begin(gateID, cardIDs)
		self.write({
			'model': ret
		})


# 深渊无限塔关卡战斗结束
class AbyssEndlessTowerBattleEnd(RequestHandlerTask):
	url = r'/game/abyss/endless/battle/end'

	@coroutine
	def run(self):
		if not isinstance(self.game.battle, ObjectAbyssEndlessTowerBattle):
			raise ServerError('abyss endlessTower battle miss')

		battleID = self.input.get('battleID', None)
		gateID = self.input.get('gateID', None)
		result = self.input.get('result', None)
		round = self.input.get('round', None)
		actions = self.input.get('actions', None)

		if any([x is None for x in [gateID, battleID, result]]):
			raise ClientError('param miss')
		if gateID != self.game.battle.gateID:
			raise ClientError('gateID error')
		if battleID != self.game.battle.id:
			raise ClientError('battleID error')

		# lua的msgpack会把顺序数值下标的table认为是list
		if isinstance(actions, list):
			actions = {idx + 1: v for idx, v in enumerate(actions)}

		if result == 'win':
			cfg = csv.abyss_endless_tower.scene[gateID]
			if self.game.role.top6_fighting_point < cfg.lowestFightingPoint:
				raise ClientError(ErrDefs.lowestFightingPointLimit)

		role = self.game.role
		self.game.battle.combine(result, round, actions)

		# 战斗结算
		eff = self.game.battle.result(result, round, actions)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='abyss_endless_drop_%d' % gateID)

		# 战斗结算完毕
		ret = self.game.battle.end()
		ret['view']['drop'] = eff.result if eff else {}

		if self.game.battle.isUpdRank:
			yield ObjectRankGlobal.onKeyInfoChange(self.game, 'abyss_endless')

		self.write(ret)

		if result == 'win':
			if round is not None and actions is not None:
				first = True if role.abyss_endless_tower_current > role.abyss_endless_tower_max_gate else False
				if first:  # 记录首通的战报
					yield ObjectEndlessTowerGlobal.recordAbyssPlay(self.game.battle.battle_model, role)

		self.game.battle = None


# 深渊无限塔任务奖励领取
class AbyssEndlessTowerTaskAward(RequestHandlerTask):
	url = r'/game/abyss/endless/task/award'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)

		role = self.game.role
		stamps = role.abyss_endless_tower_stamps or {}

		# csvID 为空时一键领取
		if csvID is None:
			eff = ObjectGainAux(self.game, {})
			for taskID in csv.abyss_endless_tower.task:
				if stamps.get(taskID, 0) != 1:
					continue
				cfg = csv.abyss_endless_tower.task[taskID]
				eff += ObjectGainAux(self.game, cfg.award)
				stamps[taskID] = 0  # 0=已领取（前端期望）
			role.abyss_endless_tower_stamps = stamps
			yield effectAutoGain(eff, self.game, self.dbcGame, src='abyss_endless_task_award')
			self.write({
				'view': eff.result
			})
		else:
			if csvID not in csv.abyss_endless_tower.task:
				raise ClientError('csvID error')
			if stamps.get(csvID, 0) != 1:
				raise ClientError('can not get award')

			cfg = csv.abyss_endless_tower.task[csvID]
			eff = ObjectGainAux(self.game, cfg.award)
			stamps[csvID] = 0  # 0=已领取（前端期望）
			role.abyss_endless_tower_stamps = stamps
			yield effectAutoGain(eff, self.game, self.dbcGame, src='abyss_endless_task_award_%d' % csvID)
			self.write({
				'view': eff.result
			})


# 深渊无限塔战报详情
class AbyssEndlessTowerPlayDetail(RequestHandlerTask):
	url = r'/game/abyss/endless/play/detail'

	@coroutine
	def run(self):
		playID = self.input.get('playID', None)
		if not playID:
			raise ClientError('param miss')

		# 使用深渊专用的数据库模型
		playRecordData = yield self.dbcGame.call_async('DBRead', 'AbyssPVEBattlePlayRecord', playID, False)
		if not playRecordData['ret']:
			raise ClientError(ErrDefs.playRecordNotFound)
		else:
			model = playRecordData['model']

		self.write({
			'model': {
				'abyss_endless_playrecords': {
					playID: model
				}
			}
		})
