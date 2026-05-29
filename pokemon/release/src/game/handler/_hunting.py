#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Hunting Handlers
'''
from framework.csv import csv, ErrDefs
from framework.helper import transform2list
from framework.log import logger
from game import ClientError
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import FeatureDefs, HuntingDefs, AchievementDefs, TargetDefs, SceneDefs
from game.object.game import ObjectCostCSV, ObjectYYHuoDongFactory
from game.object.game.battle import ObjectHuntingBattle
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.shop import ObjectHuntingShop
from game.thinkingdata import ta
from msgpackrpc.error import CallError
from tornado.gen import coroutine


# main请求 （同步model客户端)
class HuntingMain(RequestHandlerTask):
	url = r'/game/hunting/main'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")

		role = self.game.role
		# 新建 HuntingRecord
		specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
		if role.hunting_record_db_id is None:
			record = yield self.rpcHunting.call_async('CreateHuntingRecord', role.id, specialOpen)
			role.hunting_record_db_id = record['id']
		else:
			# 含刷新重置次数，在线玩家 客户端倒计时结束 主动请求。
			specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
			record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)

		role.huntingSync = 1  # 标志已同步过
		
		# 补充助战和天气数据到返回的 model 中
		# 确保所有线路都有 aid_cards 和 extra 字段，避免前端报错
		if 'hunting_route' not in record:
			record['hunting_route'] = {}
		
		# DEBUG: 打印 card_embattle 的所有键
		logger.info('[HuntingMain] card_embattle所有键: %s', role.card_embattle.keys() if role.card_embattle else None)
		
		for route in [1, 2]:
			route_key = 'hunting_route_%d' % route
			# 确保线路数据存在
			if route not in record['hunting_route']:
				record['hunting_route'][route] = {}
			
			# 从 card_embattle 读取助战和天气
			if role.card_embattle and route_key in role.card_embattle:
				route_data = role.card_embattle[route_key]
				# DEBUG: 打印route_data的完整内容
				logger.info('[HuntingMain] 线路%d的route_data: %s', route, route_data)
				
				aid_cards_dict = route_data.get('aid_cards', {})
				# 兼容老数据（数组格式）
				if isinstance(aid_cards_dict, list):
					aid_cards_dict = {i+1: v for i, v in enumerate(aid_cards_dict) if v is not None}
				extra_raw = route_data.get('extra', {})
				# 兼容数组格式（新格式）和字典格式（老格式）
				if isinstance(extra_raw, (list, tuple)) and len(extra_raw) > 0:
					extra_data = extra_raw[0] if isinstance(extra_raw[0], dict) else {}
				elif isinstance(extra_raw, dict):
					extra_data = extra_raw
					# 自动修复：把老格式 dict 转成数组格式
					if extra_raw:
						card_embattle = role.card_embattle or {}
						if route_key in card_embattle:
							card_embattle[route_key]['extra'] = [extra_raw]
							role.card_embattle = card_embattle
							logger.info('[HuntingMain] 自动修复线路%d的extra格式: dict -> [dict]', route)
				else:
					extra_data = {}
				
				# 检查 Go 的数据是否为空，card_embattle 有数据 → 需要同步
				go_aid_cards = record['hunting_route'][route].get('aid_cards')
				go_has_data = go_aid_cards and (len(go_aid_cards) > 0 if isinstance(go_aid_cards, dict) else len(filter(None, go_aid_cards)) > 0)
				local_has_data = aid_cards_dict and len(aid_cards_dict) > 0
				
				if not go_has_data and local_has_data:
					# Go 数据为空但 card_embattle 有数据，自动同步到 Go
					logger.info('[HuntingMain] 线路%d数据不一致(Go空,本地有)，同步到Go', route)
					current_cards = record['hunting_route'][route].get('cards', [])
					if current_cards and len(filter(None, current_cards)) > 0:
						extra_to_save = {'weather': extra_data.get('weather', 0), 'arms': extra_data.get('arms', [])} if extra_data else None
						try:
							# 同步数据到 Go（发送字典格式）
							updated_record = yield self.rpcHunting.call_async('DeployHuntingCards', role.hunting_record_db_id, route, current_cards, aid_cards_dict, extra_to_save)
							# 更新本地 record 数据为 Go 返回的最新数据
							record = updated_record
							logger.info('[HuntingMain] 线路%d同步成功，助战数: %d', route, len(aid_cards_dict))
						except Exception as e:
							logger.warning('[HuntingMain] 线路%d同步失败: %s', route, str(e))
				
				record['hunting_route'][route]['aid_cards'] = aid_cards_dict
				record['hunting_route'][route]['extra'] = extra_data
				logger.info('[HuntingMain] 最终返回线路%d助战: %s', route, aid_cards_dict)
			else:
				# 如果没有保存过，返回空数据
				record['hunting_route'][route]['aid_cards'] = {}
				record['hunting_route'][route]['extra'] = {}
				logger.info('[HuntingMain] 线路%d没有助战数据，card_embattle=%s', route, role.card_embattle is not None)
		
		self.write({
			'model': {
				'hunting': record
			}
		})


# 选择线路开始
class HuntingRouteBegin(RequestHandlerTask):
	url = r'/game/hunting/route/begin'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		if not all([x is not None for x in [route]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")

		role = self.game.role
		battleCards = []
		# 上阵卡牌不能低于10级
		for cardID in role.battle_cards:
			if cardID:
				card = self.game.cards.getCard(cardID)
				if not card or (card and card.level < 10):
					battleCards.append(None)
				else:
					battleCards.append(cardID)
			else:
				battleCards.append(None)
		if len(filter(None, battleCards)) == 0:
			battleCards = []
		try:
			model = yield self.rpcHunting.call_async('HuntingRouteBegin', role.hunting_record_db_id, route, battleCards)
		except CallError, e:
			raise ClientError(e.msg)

		ta.track(self.game, event='hunting_begin',route=route)

		self.write({
			'model': {
				'hunting': model
			}
		})


# 手动结束线路
class HuntingRouteEnd(RequestHandlerTask):
	url = r'/game/hunting/route/end'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		if not all([x is not None for x in [route]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")

		role = self.game.role
		try:
			model = yield self.rpcHunting.call_async('HuntingRouteEnd', role.hunting_record_db_id, route)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		self.write({
			'model': {
				'hunting': model
			}
		})


# 战斗关查看详情
class HuntingBattleInfo(RequestHandlerTask):
	url = r'/game/hunting/battle/info'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		node = self.input.get('node', None)
		gateID = self.input.get('gateID', None)
		if not all([x is not None for x in [route, node, gateID]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")
		nodeType = csv.cross.hunting.route[node].type
		if nodeType != HuntingDefs.BattleType and nodeType != HuntingDefs.MultiType:
			raise ClientError("node is not battle")

		role = self.game.role
		fixAllFp = 0
		# top_cards: [Card.id, ...]
		for topCard in role.top_cards[:6]:
			card = self.game.cards.getCard(topCard)
			if card:
				fixAllFp += card.calcFightingPoint2()
		fixAllFp = int(fixAllFp * csv.cross.hunting.gate[gateID].fightingPointC)

		try:
			resp = yield self.rpcHunting.call_async('GetHuntingBattleInfo', role.hunting_record_db_id, route, node, gateID, fixAllFp)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		model = resp['record']
		self.write({
			'model': {
				'hunting': model
			},
			'view': {
				'defence_role_info': resp['defence_role_info']
			}
		})


# 战斗关手动布阵
class HuntingBattleDeploy(RequestHandlerTask):
	url = r'/game/hunting/battle/deploy'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		node = self.input.get('node', None)
		cardIDs = self.input.get('cardIDs', None)
		aidCardIDs = self.input.get('aidCardIDs', None)
		extra = self.input.get('extra', None)
		if not all([x is not None for x in [route, node, cardIDs]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")
		nodeType = csv.cross.hunting.route[node].type
		if nodeType != HuntingDefs.BattleType and nodeType != HuntingDefs.MultiType:
			raise ClientError("node is not battle")

		cardIDs = transform2list(cardIDs)
		if len(cardIDs) != 6:
			raise ClientError(ErrDefs.battleCardCountLimit)
		if self.game.cards.isDuplicateMarkID(cardIDs):
			raise ClientError(ErrDefs.battleCardMarkIDError)
		
		# 保存助战和天气到 hunting 的线路数据
		# 注意：远征的助战/天气是按线路(route)存储的，不同线路独立
		if aidCardIDs is not None or extra is not None:
			from copy import deepcopy
			# 深拷贝整个 card_embattle，创建全新对象
			card_embattle = deepcopy(self.game.role.card_embattle) if self.game.role.card_embattle else {}
			route_key = 'hunting_route_%d' % route
			
			# 确保 route_key 存在
			if route_key not in card_embattle:
				card_embattle[route_key] = {}
			
			if aidCardIDs is not None:
				if isinstance(aidCardIDs, dict):
					aid_dict = {k: v for k, v in aidCardIDs.iteritems() if v is not None}
				else:
					aid_dict = {i+1: v for i, v in enumerate(aidCardIDs) if v is not None}
				card_embattle[route_key]['aid_cards'] = aid_dict
				logger.info('[HuntingBattleDeploy] 保存助战到 %s: %s', route_key, aid_dict)
			if extra is not None:
				card_embattle[route_key]['extra'] = [extra]  # Go 端期望数组 []*BattleExtra
			
			# 重新赋值整个 card_embattle（全新对象，确保触发保存）
			self.game.role.card_embattle = card_embattle
			
			# 立即检查是否保存成功
			logger.info('[HuntingBattleDeploy] 保存后立即读取: %s', self.game.role.card_embattle.get(route_key, {}))

		battleCards = []
		# 上阵卡牌不能低于10级
		for cardID in cardIDs:
			if cardID:
				card = self.game.cards.getCard(cardID)
				if not card or (card and card.level < 10):
					battleCards.append(None)
				else:
					battleCards.append(cardID)
			else:
				battleCards.append(None)
		# 全None的保护
		if len(filter(None, battleCards)) == 0:
			raise ClientError("cardIDs error")

		role = self.game.role
		
		# 准备助战和天气数据（字典格式）
		aid_cards_dict = {}
		extra_to_save = None
		route_key = 'hunting_route_%d' % route
		if role.card_embattle and route_key in role.card_embattle:
			route_data = role.card_embattle[route_key]
			aid_cards_dict = route_data.get('aid_cards', {})
			# 兼容老数据（数组格式）
			if isinstance(aid_cards_dict, list):
				aid_cards_dict = {i+1: v for i, v in enumerate(aid_cards_dict) if v is not None}
			extra_data = route_data.get('extra', {})
			# 兼容数组格式（新格式）和字典格式（老格式）
			if isinstance(extra_data, (list, tuple)) and len(extra_data) > 0:
				extra_dict = extra_data[0]
			elif isinstance(extra_data, dict):
				extra_dict = extra_data
				# 自动修复：把老格式 dict 转成数组格式
				if extra_data:
					card_embattle = role.card_embattle or {}
					if route_key in card_embattle:
						card_embattle[route_key]['extra'] = [extra_data]
						role.card_embattle = card_embattle
						logger.info('[HuntingBattleDeploy] 自动修复线路%d的extra格式: dict -> [dict]', route)
			else:
				extra_dict = {}
			if extra_dict:
				# 转换为BattleExtra格式
				extra_to_save = {
					'weather': extra_dict.get('weather', 0) if isinstance(extra_dict, dict) else 0,
					'arms': extra_dict.get('arms', []) if isinstance(extra_dict, dict) else []
				}
		
		try:
			model = yield self.rpcHunting.call_async('DeployHuntingCards', role.hunting_record_db_id, route, battleCards, aid_cards_dict, extra_to_save)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)
		
		# 补充助战和天气数据到返回的 model 中
		route_key = 'hunting_route_%d' % route
		
		# 确保 hunting_route 结构存在
		if 'hunting_route' not in model:
			model['hunting_route'] = {}
		if route not in model['hunting_route']:
			model['hunting_route'][route] = {}
		
		# 从 card_embattle 读取并补充助战和天气
		if role.card_embattle and route_key in role.card_embattle:
			route_data = role.card_embattle[route_key]
			aid_cards = route_data.get('aid_cards', {})
			if isinstance(aid_cards, list):
				aid_cards = {i+1: v for i, v in enumerate(aid_cards) if v is not None}
			model['hunting_route'][route]['aid_cards'] = aid_cards
			model['hunting_route'][route]['extra'] = route_data.get('extra', {})
			logger.info('[HuntingBattleDeploy] 返回线路%d助战: %s', route, aid_cards)
		else:
			# 如果没有保存过，返回空数据
			model['hunting_route'][route]['aid_cards'] = {}
			model['hunting_route'][route]['extra'] = {}
			logger.info('[HuntingBattleDeploy] 线路%d没有保存过助战', route)

		self.write({
			'model': {
				'hunting': model,
			}
		})


# 战斗关开始挑战
class HuntingBattleStart(RequestHandlerTask):
	url = r'/game/hunting/battle/start'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		node = self.input.get('node', None)
		gateID = self.input.get('gateID', None)
		cardIDs = self.input.get('cardIDs', None)
		aidCardIDs = self.input.get('aidCardIDs', None)
		extra = self.input.get('extra', None)
		
		if not all([x is not None for x in [route, node, gateID, cardIDs]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")
		nodeType = csv.cross.hunting.route[node].type
		if nodeType != HuntingDefs.BattleType and nodeType != HuntingDefs.MultiType:
			raise ClientError("node is not battle")
		
		# 保存前端发送的助战和天气到 card_embattle（确保数据一致性）
		role = self.game.role
		route_key = 'hunting_route_%d' % route
		
		if aidCardIDs is not None or extra is not None:
			from copy import deepcopy
			# 深拷贝整个 card_embattle，创建全新对象
			card_embattle = deepcopy(role.card_embattle) if role.card_embattle else {}
			
			# 确保 route_key 存在
			if route_key not in card_embattle:
				card_embattle[route_key] = {}
			
			if aidCardIDs is not None:
				if isinstance(aidCardIDs, dict):
					aid_dict = {k: v for k, v in aidCardIDs.iteritems() if v is not None}
				else:
					aid_dict = {i+1: v for i, v in enumerate(aidCardIDs) if v is not None}
				card_embattle[route_key]['aid_cards'] = aid_dict
			if extra is not None:
				card_embattle[route_key]['extra'] = [extra]  # Go 端期望数组 []*BattleExtra
			
			# 重新赋值整个 card_embattle（全新对象，确保触发保存）
			role.card_embattle = card_embattle
		
		# 获取天气数据：优先使用请求中的 extra，否则从 card_embattle 读取已保存的
		weather_extra = extra
		if weather_extra is None and role.card_embattle and route_key in role.card_embattle:
			saved_extra = role.card_embattle[route_key].get('extra', [])
			if saved_extra and len(saved_extra) > 0:
				weather_extra = saved_extra[0]
		
		# 保存天气数据到 role.battle_extra
		if weather_extra:
			weather = weather_extra.get('weather', 0)
			arms = weather_extra.get('arms', []) or []
			role.deployBattleExtra(weather, arms)

		cardIDs = transform2list(cardIDs)
		if len(cardIDs) != 6:
			raise ClientError(ErrDefs.battleCardCountLimit)
		if self.game.cards.isDuplicateMarkID(cardIDs):
			raise ClientError(ErrDefs.battleCardMarkIDError)

		battleCards = []
		# 上阵卡牌不能低于10级
		for cardID in cardIDs:
			if cardID:
				card = self.game.cards.getCard(cardID)
				if not card or (card and card.level < 10):
					battleCards.append(None)
				else:
					battleCards.append(cardID)
			else:
				battleCards.append(None)
		# 全None的保护
		if len(filter(None, battleCards)) == 0:
			raise ClientError("cardIDs error")

		self.game.battle = ObjectHuntingBattle(self.game)
		battleModel = self.game.battle.begin(route, gateID, battleCards)

		role = self.game.role
		try:
			resp = yield self.rpcHunting.call_async('HuntingBattleStart', role.hunting_record_db_id, route, node, battleModel)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		respBattleModel = resp['battle_model']
		self.game.battle.id = respBattleModel['id']
		self.game.battle.cardIDs = respBattleModel['cards']
		self.game.battle.enemyCardIDs = respBattleModel['defence_cards']
		self.game.battle.node = node
		
		# 补充助战和天气数据到返回的 record 中
		route_key = 'hunting_route_%d' % route
		record_data = resp['record']
		
		# 确保 hunting_route 结构存在
		if 'hunting_route' not in record_data:
			record_data['hunting_route'] = {}
		if route not in record_data['hunting_route']:
			record_data['hunting_route'][route] = {}
		
		# 补充助战和天气数据（字典格式）
		if role.card_embattle and route_key in role.card_embattle:
			route_data = role.card_embattle[route_key]
			if 'aid_cards' in route_data:
				aid_cards = route_data['aid_cards']
				# 兼容老数据（数组格式）
				if isinstance(aid_cards, list):
					aid_cards = {i+1: v for i, v in enumerate(aid_cards) if v is not None}
				record_data['hunting_route'][route]['aid_cards'] = aid_cards
			else:
				record_data['hunting_route'][route]['aid_cards'] = {}
			if 'extra' in route_data:
				record_data['hunting_route'][route]['extra'] = route_data['extra']
			else:
				record_data['hunting_route'][route]['extra'] = {}
		else:
			# 如果没有保存过助战，返回空数据避免前端报错
			record_data['hunting_route'][route]['aid_cards'] = {}
			record_data['hunting_route'][route]['extra'] = {}
		
		# 将route_info直接添加到battle_model中，供前端战斗模型使用
		battle_model_data = resp['battle_model']
		battle_model_data['route_info'] = record_data['hunting_route'][route]
		
		# 补充天气数据到 battle_model（从 Python 生成的 battleModel 中获取）
		if 'extra' in battleModel:
			battle_model_data['extra'] = battleModel['extra']
		
		# 为我方助战卡牌生成属性，合并到 battle_model 的 card_attrs 中
		aid_cards_dict = record_data['hunting_route'][route].get('aid_cards', {})
		aid_cards_values = list(aid_cards_dict.values()) if isinstance(aid_cards_dict, dict) else []
		aid_fighting_point = 0
		if aid_cards_values and len(aid_cards_values) > 0:
			aid_attrs, aid_attrs2 = self.game.cards.makeBattleCardModel(aid_cards_values, SceneDefs.Hunting, is_aid=True)
			# 合并到 battle_model 的 card_attrs 中
			if 'card_attrs' not in battle_model_data:
				battle_model_data['card_attrs'] = {}
			if 'card_attrs2' not in battle_model_data:
				battle_model_data['card_attrs2'] = {}
			battle_model_data['card_attrs'].update(aid_attrs)
			battle_model_data['card_attrs2'].update(aid_attrs2)
			# 计算助战总战力
			for aid_attr in aid_attrs.values():
				aid_fighting_point += aid_attr.get('aid_fighting_point', 0)
		
		# 添加助战战力到battle_model
		battle_model_data['aid_fighting_point'] = aid_fighting_point
		
		# DEBUG: 打印战斗数据
		from framework.log import logger
		logger.info('[HuntingBattleStart] 我方助战数: %d, 敌方助战数: %d, 敌方是玩家: %s, 我方天气: %s', 
			len(aid_cards_values) if aid_cards_values else 0,
			len(battle_model_data.get('defence_aid_cards', {})),
			battle_model_data.get('battle_role_key') is not None,
			battle_model_data.get('extra'))

		self.write({
			'model': {
				'hunting': record_data,
				'hunting_battle': battle_model_data
			}
		})


# 战斗关结束挑战
class HuntingBattleEnd(RequestHandlerTask):
	url = r'/game/hunting/battle/end'

	@coroutine
	def run(self):
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		battleID = self.input.get('battleID', None)
		result = self.input.get('result', None)
		cardStates = self.input.get('cardStates', None)
		enemyStates = self.input.get('enemyStates', None)
		damage = self.input.get('damage', None)
		actions = self.input.get('actions', None)

		if not all([x is not None for x in [battleID, result, cardStates, enemyStates, damage]]):
			raise ClientError('param miss')
		if battleID != self.game.battle.id:
			raise ClientError('battleID error')
		if damage < 0:
			raise ClientError('damage error')
		damage = int(damage)
		# 伤害保护
		if damage > self.game.battle.maxDamage():
			logger.warning("role %d hunting battle damage %d cheat can max %d", self.game.role.uid, damage, self.game.battle.maxDamage())
			raise ClientError(ErrDefs.rankCheat)

		battle = self.game.battle
		battle.resultStatesOK(cardStates, enemyStates)
		# 保存原始卡牌列表（用于勋章检查）
		originalCardIDs = list(battle.cardIDs)
		# 死亡卡牌 下阵
		for i, cardID in enumerate(battle.cardIDs):
			if cardID and cardStates[cardID][0] <= 0:
				battle.cardIDs[i] = None

		role = self.game.role
		req = {
			"record_id": role.hunting_record_db_id,
			"result": result,
			"route": battle.route,
			"gate_id": battle.gateID,
			"card_ids": battle.cardIDs,
			"card_states": cardStates,
			"enemy_states": enemyStates,
			"damage": float(damage),
			"max_damage": float(self.game.battle.maxDamage()),
			"actions": actions,
		}

		try:
			resp = yield self.rpcHunting.call_async('HuntingBattleEnd', req)
			record = resp['record']
			if resp['is_pass']:
				if battle.route == HuntingDefs.RouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingPass, 1)
					# 勋章计数：普通线路不损失通关 (targetType=40, medalID=1351)
					# 检查是否没有精灵死亡（使用原始卡牌列表，因为battle.cardIDs已被修改）
					noDeathPass = all(cardStates[cid][0] > 0 for cid in originalCardIDs if cid)
					if noDeathPass:
						self.game.medal.incrementMedalCounter(1351)
				elif battle.route == HuntingDefs.SpecialRouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingSpecialPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingSpecialPass, 1)
					# 勋章计数：进阶线路不损失通关 (targetType=42, medalID=1361)
					noDeathPass = all(cardStates[cid][0] > 0 for cid in originalCardIDs if cid)
					if noDeathPass:
						self.game.medal.incrementMedalCounter(1361)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		# 战斗结算
		drop = None
		if result == 'win':
			cfg = csv.cross.hunting.gate[battle.gateID]
			drop = cfg.drops
		view = {'result': result}
		if drop:
			eff = ObjectGainAux(self.game, drop)
			yield effectAutoGain(eff, self.game, self.dbcGame, src='hunting_battle_award')
			view['drop'] = eff.result
		self.game.battle = None

		if result == 'win':
			ta.track(self.game, event='hunting_battle_win',route=battle.route, gate_id=battle.gateID, node=battle.node)

		self.write({
			'model': {
				'hunting': record
			},
			'view': view
		})


# 战斗关碾压
class HuntingBattlePass(RequestHandlerTask):
	url = r'/game/hunting/battle/pass'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.HuntingPass, self.game):
			raise ClientError("hunting pass on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		node = self.input.get('node', None)
		gateID = self.input.get('gateID', None)
		if not all([x is not None for x in [route, node, gateID]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHuntingPass, self.game):
				raise ClientError("special hunting pass on open")
		nodeType = csv.cross.hunting.route[node].type
		if nodeType != HuntingDefs.BattleType and nodeType != HuntingDefs.MultiType:
			raise ClientError("node is not battle")

		role = self.game.role
		specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
		record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
		routeInfo = record['hunting_route'][route]
		cardStates = routeInfo["card_states"]

		# 存活中的战力前10位
		allCards = self.game.cards.getAllCards()
		cards = allCards.values()
		cards.sort(key=lambda o: o.fighting_point, reverse=True)
		top10Cards = []
		for card in cards:
			if len(top10Cards) >= 10:
				break
			if card.level < 10:
				continue
			hp, mp = cardStates.get(card.id, (1.0, 0.0))
			if hp > 0:
				top10Cards.append(card.id)

		try:
			resp = yield self.rpcHunting.call_async('HuntingBattlePass', role.hunting_record_db_id, route, node, gateID, top10Cards)
			record = resp['record']
			if resp['is_pass']:
				if route == HuntingDefs.RouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingPass, 1)
				elif route == HuntingDefs.SpecialRouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingSpecialPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingSpecialPass, 1)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		# 碾压结算
		cfg = csv.cross.hunting.gate[gateID]
		eff = ObjectGainAux(self.game, cfg.drops)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='hunting_battle_award')

		self.write({
			'model': {
				'hunting': record
			},
			'view': {
				'result': 'win',
				'drop': eff.result
			}
		})


# 战斗关选择buff（三选一）
class HuntingBattleChoose(RequestHandlerTask):
	url = r'/game/hunting/battle/choose'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		node = self.input.get('node', None)
		boardID = self.input.get('boardID', None)
		if not all([x is not None for x in [route, node, boardID]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if boardID <= 0 or boardID > 3:
			raise ClientError('boardID error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")
		nodeType = csv.cross.hunting.route[node].type
		if nodeType != HuntingDefs.BattleType and nodeType != HuntingDefs.MultiType:
			raise ClientError("node is not battle")

		role = self.game.role
		try:
			resp = yield self.rpcHunting.call_async('HuntingBattleChoose', role.hunting_record_db_id, route, node, boardID)
			model = resp['record']
			if resp['is_pass']:
				if route == HuntingDefs.RouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingPass, 1)
				elif route == HuntingDefs.SpecialRouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingSpecialPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingSpecialPass, 1)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		self.write({
			'model': {
				'hunting': model
			}
		})


# 宝箱关打开宝箱
class HuntingBoxOpen(RequestHandlerTask):
	url = r'/game/hunting/box/open'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		node = self.input.get('node', None)
		if not all([x is not None for x in [route, node]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")
		nodeType = csv.cross.hunting.route[node].type
		if nodeType != HuntingDefs.BoxType and nodeType != HuntingDefs.MultiType:
			raise ClientError("node is not box")
		role = self.game.role
		specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
		record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
		routeInfo = record['hunting_route'][route]
		if routeInfo.get('node', 0) != node:
			raise ClientError("node error")
		if routeInfo['status'] != "starting":
			raise ClientError("status error")
		cfgBase = csv.cross.hunting.base[route]
		if routeInfo.get('box_open_count', 0) >= cfgBase.boxOpenLimit:
			raise ClientError("box open is limit")

		cfg = csv.cross.hunting.route[node]
		eff = ObjectGainAux(self.game, {})
		# 首次
		count = routeInfo.get('box_open_count', 0)
		if count == 0:
			eff += ObjectGainAux(self.game, cfg['boxDropLibs'])
		else:
			costRMB = ObjectCostCSV.getHuntingBoxCost(count-1)
			cost = ObjectCostAux(self.game, {'rmb': costRMB})
			if not cost.isEnough():
				raise ClientError('cost rmb no enough')
			eff += ObjectGainAux(self.game, cfg['boxDropLibs2'])
			cost.cost(src='hunting_box_award')

		try:
			resp = yield self.rpcHunting.call_async('HuntingOpenBox', role.hunting_record_db_id, route, node)
			model = resp['record']
			if resp['is_pass']:
				if route == HuntingDefs.RouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingPass, 1)
				elif route == HuntingDefs.SpecialRouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingSpecialPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingSpecialPass, 1)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='hunting_box_award')

		self.write({
			'model': {
				'hunting': model
			},
			'view': eff.result
		})


# 手动往下一节点走（提供宝箱使用）
class HuntingNext(RequestHandlerTask):
	url = r'/game/hunting/next'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		if not all([x is not None for x in [route]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")

		role = self.game.role
		try:
			resp = yield self.rpcHunting.call_async('HuntingNextNode', role.hunting_record_db_id, route)
			model = resp['record']
			if resp['is_pass']:
				if route == HuntingDefs.RouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingPass, 1)
				elif route == HuntingDefs.SpecialRouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingSpecialPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingSpecialPass, 1)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		self.write({
			'model': {
				'hunting': model
			}
		})


# 救援关补给
class HuntingSupply(RequestHandlerTask):
	url = r'/game/hunting/supply'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		node = self.input.get('node', None)
		csvID = self.input.get('csvID', None)  # 补给csvID
		cardID = self.input.get('cardID', None)  # 全体恢复不传
		if not all([x is not None for x in [route, node, csvID]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")
		nodeType = csv.cross.hunting.route[node].type
		if nodeType != HuntingDefs.SupplyType and nodeType != HuntingDefs.MultiType:
			raise ClientError("node is not supply")

		if cardID:
			card = self.game.cards.getCard(cardID)
			if not card:
				raise ClientError("card is not exist")
			if card.level < 10:
				raise ClientError("card level less than 10")

		role = self.game.role
		try:
			resp = yield self.rpcHunting.call_async('HuntingSupply', role.hunting_record_db_id, route, node, csvID, cardID)
			model = resp['record']
			if resp['is_pass']:
				if route == HuntingDefs.RouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingPass, 1)
				elif route == HuntingDefs.SpecialRouteType:
					self.game.achievement.onCount(AchievementDefs.HuntingSpecialPass, 1)
					ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.HuntingSpecialPass, 1)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		self.write({
			'model': {
				'hunting': model
			}
		})


# 组合关选择
class HuntingBoardChoose(RequestHandlerTask):
	url = r'/game/hunting/board/choose'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")
		if self.game.role.hunting_record_db_id is None:
			raise ClientError('hunting need prepare')
		route = self.input.get('route', None)
		node = self.input.get('node', None)
		boardID = self.input.get('boardID', None)  # 1=宝箱;2=补给;100101=战斗
		if not all([x is not None for x in [route, node, boardID]]):
			raise ClientError('param miss')
		if route not in [HuntingDefs.RouteType, HuntingDefs.SpecialRouteType]:
			raise ClientError('route error')
		if route == HuntingDefs.SpecialRouteType:
			if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game):
				raise ClientError("special hunting on open")
		if csv.cross.hunting.route[node].type != HuntingDefs.MultiType:
			raise ClientError("node is not multi")
		if boardID == 1:
			if not csv.cross.hunting.route[node].boxDropLibs:
				raise ClientError("boardID error ")
		elif boardID == 2:
			if not csv.cross.hunting.route[node].supplyGroup:
				raise ClientError("boardID error ")
		else:
			if boardID not in csv.cross.hunting.route[node].gateIDs:
				raise ClientError("boardID error ")

		role = self.game.role
		try:
			model = yield self.rpcHunting.call_async('HuntingBoardChoose', role.hunting_record_db_id, route, node, boardID)
		except ClientError, e:
			mes = e.log_message
			if mes in (ErrDefs.huntingClosed):
				specialOpen = ObjectFeatureUnlockCSV.isOpen(FeatureDefs.SpecialHunting, self.game)
				record = yield self.rpcHunting.call_async('GetHuntingRecord', role.hunting_record_db_id, specialOpen)
				self.write({'model': {'hunting': record}})
				raise ClientError(mes, model=record)
			raise ClientError(mes)

		self.write({
			'model': {
				'hunting': model
			}
		})


# 远征商店
class HuntingShop(RequestHandlerTask):
	url = r'/game/hunting/shop'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Hunting, self.game):
			raise ClientError("hunting on open")

		csvID = self.input.get('csvID', None)
		count = self.input.get('count', 1)
		if csvID is None:
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')

		shop = ObjectHuntingShop(self.game)
		eff = yield shop.buyItem(csvID, count, src='hunting_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='hunting_shop_buy')

