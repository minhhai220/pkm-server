#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''

from framework.object import ObjectBase
from framework.lru import LRUCache
from framework.csv import csv

from game.object.game import ObjectGame
from game.object.game.card import ObjectCard

from weakref import WeakValueDictionary
from tornado.gen import Return, coroutine

#
# ObjectCacheGlobal
#
class ObjectCacheGlobal(ObjectBase):
	Singleton = None

	def __init__(self):
		self.roles = LRUCache(1000)
		self.cards = LRUCache(1000)
		self.dbc = None

		if ObjectCacheGlobal.Singleton is not None:
			raise ValueError('This is singleton object')
		ObjectCacheGlobal.Singleton = self

	def init(self, server):
		self.server = server
		self.dbc = server.dbcGame

	@classmethod
	@coroutine
	def queryRole(cls, roleID):
		self = cls.Singleton

		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game: # online role
			role = self.role2display(game.role)
			self.roles.set(roleID, role)
		else:
			role = self.roles.getByKey(roleID)
			if role is None:
				# query from storage
				role = yield self.dbc.call_async('GetSlimRole', roleID)
				# 转换离线玩家的 medal 数据：{csvID: time} → {medalID: time}
				if role and 'medal' in role:
					role['medal'] = self._convertMedal(role['medal'])
				self.roles.set(roleID, role)
		raise Return(role)

	@classmethod
	@coroutine
	def queryCard(cls, cardID):
		self = cls.Singleton

		card = ObjectCard.CardsObjsMap.get(cardID, None)
		if card: # online card
			card = self.card2display(card)
			self.cards.set(cardID, card)
		else:
			card = self.cards.getByKey(cardID)
			if card is None:
				# query from storage
				card = yield self.dbc.call_async('GetSlimCard', cardID)
				if not card['attrs']: # 删除卡牌是异步操作，可能取到已删除的卡牌，没有attrs数据
					from game.object.game.card import CardSlim
					cardTmp = CardSlim(card)
					attrs = ObjectCard.calcAttrs(cardTmp)
					card['attrs'] = attrs
					raise Return(card)
				self.cards.set(cardID, card)
		raise Return(card)

	@classmethod
	def popRole(cls, roleID):
		self = cls.Singleton
		self.roles.popByKey(roleID)

	@classmethod
	def popCard(cls, cardID):
		self = cls.Singleton
		self.cards.popByKey(cardID)

	@staticmethod
	def _convertMedal(role_medal):
		"""
		转换 medal 数据：从 {csvID: time} 转为 {medalID: time}
		从 csv.medal[csvID].medalID 读取正确的 medalID
		"""
		from framework.csv import csv
		
		medal_display = {}
		if not role_medal:
			return medal_display
		
		for csvID, activateTime in role_medal.iteritems():
			# 验证 csvID 有效性
			if not csvID or csvID <= 0:
				continue
			if csvID not in csv.medal:
				continue
			
			# 从 CSV 读取正确的 medalID
			medalID = csv.medal[csvID].medalID
			if not medalID or medalID <= 0:
				continue
			
			# 如果同一组有多个勋章激活，只保留最新的
			if medalID not in medal_display or activateTime > medal_display[medalID]:
				medal_display[medalID] = activateTime
		
		return medal_display
	
	@staticmethod
	def card2display(card):
		keys = ('id', 'name', 'card_id', 'advance', 'star', 'level', 'gender', 'character', 'nvalue', 'skills', 'fighting_point', 'skin_id', 'zawake_skills')
		display = {key: getattr(card, key) for key in keys}
		display['nvalue'] = card._getDisplayNvalue(display.get('nvalue', None))
		display['attrs'] = card.csvAttrs
		display['role_name'] = card.game.role.name
		if card.held_item:
			heldItem = card.game.heldItems.getHeldItem(card.held_item)
			display['held_item'] = {
				'held_item_id': heldItem.held_item_id,
				'level': heldItem.level,
				"advance": heldItem.advance
			}
		return display

	@staticmethod
	def role2display(role):
		keys = ('id', 'account_id', 'uid', 'name', 'personal_sign', 'last_time', 'logo', 'frame', 'figure', 'title_id', 'level', 'vip_level', 'battle_fighting_point', 'pvp_record_db_id', 'medal_show')
		rolecache = {key: getattr(role, key) for key in keys}
		rolecache['collect_num'] = len(role.pokedex)
		rolecache['contract_counter'] = getattr(role, 'contract_counter', None) or {}
		# 确保 explorer_core 有效（非空且 level >= 1）
		explorer_core = getattr(role, 'explorer_core', None)
		if not explorer_core or explorer_core.get('level', 0) < 1:
			explorer_core = {'level': 1, 'exp_sum': 0}
		rolecache['explorer_core'] = explorer_core
		# 前端 isLock 逻辑依赖 tech_tree[dotId] 是否存在
		# 为所有满足核心等级条件的天赋预设 level=0，使前端不显示锁定
		tech_tree = dict(getattr(role, 'explorer_tech_tree', None) or {})
		core_level = explorer_core.get('level', 1)
		if csv.explorer.tech_tree:
			for techID in csv.explorer.tech_tree:
				cfg = csv.explorer.tech_tree[techID]
				# 安全获取配置值（CSV可能是空字符串）
				need_core_level = cfg.needCoreLevel or 0
				pre_tech_id1 = cfg.preTechID1 or 0
				pre_tech_id2 = cfg.preTechID2 or 0
				pre_tech_level1 = cfg.preTechLevel1 or 0
				pre_tech_level2 = cfg.preTechLevel2 or 0
				# 检查核心等级条件（前端用 level >= needCoreLevel）
				if core_level >= need_core_level:
					# 检查前置天赋条件
					pre1_ok = pre_tech_id1 <= 0 or tech_tree.get(pre_tech_id1, 0) >= pre_tech_level1
					pre2_ok = pre_tech_id2 <= 0 or tech_tree.get(pre_tech_id2, 0) >= pre_tech_level2
					if pre1_ok and pre2_ok and techID not in tech_tree:
						tech_tree[techID] = 0
		rolecache['explorer_tech_tree'] = tech_tree
		if role.vip_hide:
			rolecache['vip_level'] = 0
		
		# 转换 medal 数据：从 {csvID: time} 转为 {medalID: time}
		role_medal = getattr(role, 'medal', None) or {}
		rolecache['medal'] = ObjectCacheGlobal._convertMedal(role_medal)
		cardscache = []
		cards = role.game.cards.getCards(role.battle_cards)
		for card in cards:
			cardscache.append({
				'id': card.id,
				'name': card.name,
				'card_id': card.card_id,
				'advance': card.advance,
				'star': card.star,
				'level': card.level,
				'skin_id': card.skin_id,
			})
		rolecache['cards'] = cardscache
		
		# 添加助战卡牌信息（字典格式）
		aid_cards_cache = {}
		aid_cards_dict = role.battle_aid_cards or {}
		# 兼容老数据（数组格式）
		if isinstance(aid_cards_dict, list):
			aid_cards_dict = {i+1: v for i, v in enumerate(aid_cards_dict) if v is not None}
		if aid_cards_dict:
			aid_cards_values = list(aid_cards_dict.values())
			aid_cards = role.game.cards.getCards(aid_cards_values)
			for slot, card_id in aid_cards_dict.iteritems():
				card = role.game.cards.getCard(card_id)
				if card:
					aid_cards_cache[slot] = {
						'id': card.id,
						'card_id': card.card_id,
						'skin_id': card.skin_id,
					}
		rolecache['aid_cards'] = aid_cards_cache
		
		return rolecache
