#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Totem Handlers
'''

from framework.csv import csv, ErrDefs
from game import ClientError
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object.game.gain import ObjectGainAux
from game.object import FeatureDefs
from game.object.game.levelcsv import ObjectFeatureUnlockCSV

from tornado.gen import coroutine, Return


# 获取图腾商店
class TotemShopGet(RequestHandlerTask):
	url = r'/game/totem/shop/get'
	
	@coroutine
	def run(self):
		"""
		获取图腾商店数据
		"""
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Totem, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		# 获取或创建商店数据
		yield getTotemShopModel(self.game, self.dbcGame)


@coroutine
def getTotemShopModel(game, dbc, refresh=False):
	"""
	获取或创建图腾商店模型（完全参考 getEquipShopModel）
	"""
	from game.object.game.shop import ObjectTotemShop
	from framework import nowtime_t
	
	if game.role.totem_shop_db_id:
		# 强制刷新 或 过期
		if refresh or game.totemShop.isPast():
			game.role.totem_shop_db_id = None
			ObjectTotemShop.addFreeObject(game.totemShop)
			game.totemShop = ObjectTotemShop(game, dbc)
	
	# 重新生成商店
	if not game.role.totem_shop_db_id:
		last_time = nowtime_t()
		roleID = game.role.id
		items = ObjectTotemShop.makeShopItems(game)
		model = ObjectTotemShop.getFreeModel(roleID, items, last_time)
		fromDB = False
		if model is None:
			ret = yield dbc.call_async('DBCreate', 'TotemShop', {
				'role_db_id': roleID,
				'items': items,
				'last_time': last_time,
			})
			model = ret['model']
			fromDB = True
		game.role.totem_shop_db_id = model['id']
		game.totemShop = ObjectTotemShop(game, dbc).dbset(model, fromDB).init()

	raise Return(game.totemShop)


# 镶嵌图腾
class TotemInset(RequestHandlerTask):
	url = r'/game/totem/inset'
	
	@coroutine
	def run(self):
		"""
		镶嵌图腾
		input: {'symbolGroup': {symbolId: [slotIndex1, slotIndex2, ...], ...}}
		"""
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Totem, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		# 获取镶嵌数据
		inset_data = self.input.get('symbolGroup', None)
		if not inset_data or not isinstance(inset_data, dict):
			raise ClientError('param error')
		
		# 转换键为整数
		inset_data_int = {}
		for symbol_id_str, slot_indices in inset_data.iteritems():
			try:
				symbol_id = int(symbol_id_str)
				if isinstance(slot_indices, list):
					slot_indices = [int(idx) for idx in slot_indices]
				else:
					raise ClientError('param error')
				inset_data_int[symbol_id] = slot_indices
			except (ValueError, TypeError):
				raise ClientError('param error')
		
		# 执行镶嵌
		activated_symbols = self.game.totem.inset(inset_data_int)
		
		# 实时更新所有卡牌属性和战力
		self.game.totem.updateAllCardsAttrs()
		
		self.write({
			'view': {
				'activeSymbol': activated_symbols
			}
		})


# 分解图腾
class TotemDecompose(RequestHandlerTask):
	url = r'/game/totem/decompose'
	
	@coroutine
	def run(self):
		"""
		分解图腾道具
		input: {'decomposeGroup': {itemCsvId: count, ...}}
		"""
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Totem, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		# 获取分解数据
		decompose_items = self.input.get('decomposeGroup', None)
		if not decompose_items or not isinstance(decompose_items, dict):
			raise ClientError('param error')
		
		# 转换键为整数
		decompose_items_int = {}
		for item_id_str, count in decompose_items.iteritems():
			try:
				item_id = int(item_id_str)
				count = int(count)
				if count <= 0:
					raise ClientError('param error')
				decompose_items_int[item_id] = count
			except (ValueError, TypeError):
				raise ClientError('param error')
		
		# 执行分解
		eff = self.game.totem.decompose(decompose_items_int)
		
		# 发放奖励
		yield effectAutoGain(eff, self.game, self.dbcGame, src='totem_decompose')
		
		self.write({
			'view': eff.result
		})


# 兑换商店购买
class TotemExchangeShopBuy(RequestHandlerTask):
	url = r'/game/totem/exchange/shop/buy'
	
	@coroutine
	def run(self):
		"""
		兑换商店购买
		"""
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Totem, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		from game.object.game.gain import ObjectCostAux
		
		# 兼容前端可能传csvId或csvID
		csv_id = self.input.get('csvID', self.input.get('csvId', None))
		count = self.input.get('count', 1)
		
		if not csv_id or csv_id not in csv.totem.exchange_shop:
			raise ClientError('csv error')
		
		if count <= 0:
			raise ClientError('param error')
		
		cfg = csv.totem.exchange_shop[csv_id]
		
		# 检查购买限制
		shop_limit = self.game.role.shop_limit.get('totem_exchange_shop', {})
		buy_record = shop_limit.get(csv_id, [0, 0])
		
		if cfg.limitType > 0:
			from framework import todaydate2int, weekinclock5date2int, monthinclock5date2int
			
			# 获取当前时间标记
			if cfg.limitType == 1:  # 每日
				current_date = todaydate2int()
			elif cfg.limitType == 2:  # 每周
				current_date = weekinclock5date2int()
			elif cfg.limitType == 3:  # 每月
				current_date = monthinclock5date2int()
			else:  # 永久
				current_date = buy_record[1]
			
			# 重置计数
			if buy_record[1] != current_date:
				buy_record = [0, current_date]
			
			# 检查限购
			if buy_record[0] + count > cfg.limitTimes:
				raise ClientError('buy limit exceed')
		
		# 消耗
		cost_map = {}
		for cost_id, cost_num in cfg.costMap.iteritems():
			cost_map[cost_id] = cost_num * count
		
		cost = ObjectCostAux(self.game, cost_map)
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='totem_exchange_shop')
		
		# 更新购买记录
		buy_record[0] += count
		shop_limit[csv_id] = buy_record
		if 'totem_exchange_shop' not in self.game.role.shop_limit:
			self.game.role.shop_limit['totem_exchange_shop'] = {}
		self.game.role.shop_limit['totem_exchange_shop'][csv_id] = buy_record
		self.game.role.shop_limit = self.game.role.shop_limit
		
		# 发放奖励
		gain_map = {}
		for item_id, item_num in cfg.itemMap.iteritems():
			gain_map[item_id] = item_num * count
		
		eff = ObjectGainAux(self.game, gain_map)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='totem_exchange_shop')
		
		self.write({
			'view': eff.result
		})


# 图腾商店购买
class TotemShopBuy(RequestHandlerTask):
	url = r'/game/totem/shop/buy'
	
	@coroutine
	def run(self):
		"""
		图腾商店购买
		"""
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Totem, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		idx = self.input.get('idx', None)
		shopID = self.input.get('shopID', None)
		itemID = self.input.get('itemID', None)
		count = self.input.get('count', 1)
		
		if not all([x is not None for x in [idx, shopID, itemID]]):
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')
		
		if not self.game.role.totem_shop_db_id:
			raise ClientError(ErrDefs.shopNotExisted)
		
		# 商店过期了
		oldID = self.game.totemShop.id
		totemShop = yield getTotemShopModel(self.game, self.dbcGame)
		if oldID != totemShop.id:
			raise ClientError(ErrDefs.shopRefresh)
		
		eff = self.game.totemShop.buyItem(idx, shopID, itemID, count, src='totem_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='totem_shop_buy')
		
		self.write({
			'view': eff.result
		})


# 图腾收集奖励领取
class TotemCollectionAwardGet(RequestHandlerTask):
	url = r'/game/symbol/collection/award/get'
	
	@coroutine
	def run(self):
		"""
		领取图腾收集奖励
		"""
		csvID = self.input.get('csvID', None)
		if csvID is None:
			raise ClientError('param miss')
		
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Totem, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		# 获取配置
		if csvID not in csv.totem.collection:
			raise ClientError('csv error')
		cfg = csv.totem.collection[csvID]
		
		# 检查是否已领取
		award_record = self.game.totem.award
		if csvID in award_record and award_record[csvID] == 0:
			raise ClientError(ErrDefs.hadGotAward)
		
		# 检查是否满足条件（激活的图腾符号数量）
		totem_insetted = self.game.totem.totem_insetted
		group_type = cfg.groupType
		activated_count = 0
		
		# 统计该组已激活的图腾符号数量
		# 使用 isSymbolActive 方法判断是否激活（包含 totem_star 存在的情况）
		for symbol_id in csv.totem.symbol:
			symbol_cfg = csv.totem.symbol[symbol_id]
			if symbol_cfg.symbolGroupType == group_type:
				if self.game.totem.isSymbolActive(symbol_id):
					activated_count += 1
		
		# 检查是否达到领取条件
		if activated_count < cfg.activeNum:
			raise ClientError(ErrDefs.taskNotFinish)
		
		# 发放奖励
		eff = ObjectGainAux(self.game, cfg.award)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='totem_collection_award')
		
		# 标记已领取
		self.game.totem.award[csvID] = 0
		
		# 返回奖励信息
		self.write({
			'view': {
				'award': eff.to_dict()
			}
		})

