#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Lottery Handlers
'''

from framework.csv import csv, ErrDefs, ConstDefs
from game import ServerError, ClientError
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import DrawCardDefs, DrawItemDefs, AchievementDefs, CardDefs, MessageDefs, DrawGemDefs, DrawChipDefs
from game.object.game import ObjectCostCSV
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from game.object.game.message import ObjectMessageGlobal
from game.object.game.chip import ObjectChip
from game.thinkingdata import ta

from tornado.gen import coroutine


# 抽卡
class LotteryCardDraw(RequestHandlerTask):
	url = r'/game/lottery/card/draw'

	@coroutine
	def run(self):
		drawType = self.input.get('drawType', None)

		half = False
		if self.game.dailyRecord.draw_card_rmb1_half == 0 and self.game.trainer.firstRMBDrawCardHalf:
			half = True
		eff = self.game.lotteryRecord.drawCard(drawType, half=half)
		if not eff:
			raise ServerError('draw card eff was empty')

		yield effectAutoGain(eff, self.game, self.dbcGame, src='draw_card_%s' % drawType)
		if eff.getCardsObjD():
			for dbID, obj in eff.getCardsObjD().iteritems():
				ObjectMessageGlobal.newsCardMsg(self.game.role, obj, 'pub')
				ObjectMessageGlobal.marqueeBroadcast(self.game.role, MessageDefs.MqDrawCard, card=obj)

		result = eff.result
		itemID, itemCount = None, None
		if drawType == DrawCardDefs.RMB1:
			itemID, itemCount = 14, 1
		elif drawType == DrawCardDefs.RMB10:
			itemID, itemCount = 14, 10
			self.game.achievement.onCount(AchievementDefs.DrawCardRMB10, 1)
			# 钻石十连抽x次同时抽出2/3个S级精灵 成就计数
			raritySCount = 0
			for cardMsg in result.get('carddbIDs', []):
				card = self.game.cards.getCard(cardMsg[0])
				if card.rarity == CardDefs.rarityS:
					raritySCount += 1
			if raritySCount == 2:
				self.game.achievement.onCount(AchievementDefs.DrawSCard2, 1)
			elif raritySCount == 3:
				self.game.achievement.onCount(AchievementDefs.DrawSCard3, 1)
		elif drawType == DrawCardDefs.Free1:
			itemID, itemCount = 14, 1
		elif drawType == DrawCardDefs.Gold1:
			itemID, itemCount = 12, 1
		elif drawType == DrawCardDefs.Gold10:
			itemID, itemCount = 12, 10
			self.game.achievement.onCount(AchievementDefs.DrawCardGold10, 1)
		elif drawType == DrawCardDefs.FreeGold1:
			itemID, itemCount = 12, 1

		if itemID:
			eff = ObjectGainAux(self.game, {itemID: itemCount})
			yield effectAutoGain(eff, self.game, self.dbcGame, src='lottery_card_draw')
			result.update({'extra':[[itemID, itemCount]]})
		self.write({'view': {'result': result}})

# 抽装备
class LotteryEquipDraw(RequestHandlerTask):
	url = r'/game/lottery/equip/draw'

	@coroutine
	def run(self):
		drawType = self.input.get('drawType', None)

		eff = self.game.lotteryRecord.drawEquip(drawType)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='draw_equip_%s' % drawType)
		if eff and eff.getHeldItemsObjD():
			for dbID, obj in eff.getHeldItemsObjD().iteritems():
				ObjectMessageGlobal.newsHoldItemMsg(self.game.role, obj, 'draw')
				ObjectMessageGlobal.marqueeBroadcast(self.game.role, MessageDefs.MqDrawHoldItem, holdItem=obj)
		self.write({'view': {'result': eff.result if eff else {}}})

		
# 抽道具(探险寻宝)
class LotteryItemDraw(RequestHandlerTask):
	url = r'/game/lottery/item/draw'

	@coroutine
	def run(self):
		drawType = self.input.get('drawType', None)
		if drawType is None or drawType not in (DrawItemDefs.COIN4_1, DrawItemDefs.COIN4_5, DrawItemDefs.Free1):
			raise ClientError('param miss')

		half = False
		cost = ObjectCostAux(self.game, {})
		if drawType == DrawItemDefs.COIN4_5:
			count = 5
			drawType = DrawItemDefs.COIN4_1
			cost = ObjectCostAux(self.game, {DrawItemDefs.explorerKey: 5})
			if not cost.isEnough():
				cost = ObjectCostAux(self.game, {'rmb': ConstDefs.draw5ItemCostPrice})
				if not cost.isEnough():
					raise ClientError(ErrDefs.drawItemRMBNotEnough)
		else:
			count = 1
			if drawType == DrawItemDefs.COIN4_1:
				if self.game.dailyRecord.draw_item_rmb1_half == 0 and self.game.trainer.firstRMBDrawItemHalf:
					half = True

				if half:
					cost = ObjectCostAux(self.game, {'rmb': int(ConstDefs.drawItemCostPrice / 2)})
					if not cost.isEnough():
						raise ClientError(ErrDefs.drawItemRMBNotEnough)
				else:
					cost = ObjectCostAux(self.game, {DrawItemDefs.explorerKey: 1})
					if not cost.isEnough():
						cost = ObjectCostAux(self.game, {'rmb': ConstDefs.drawItemCostPrice})
						if not cost.isEnough():
							raise ClientError(ErrDefs.drawItemRMBNotEnough)

		# 剩余次数 判断
		if drawType != DrawItemDefs.Free1:
			if self.game.dailyRecord.draw_item + count > self.game.role.drawItemCountLimit:
				raise ClientError(ErrDefs.drawItemLimit)

		if half:
			self.game.dailyRecord.draw_item_rmb1_half += 1
		cost.cost(src='draw_item')
		if count == 5:
			self.game.achievement.onCount(AchievementDefs.DrawItem5, 1)
		result = {}
		for i in xrange(count):
			eff = self.game.lotteryRecord.drawItem(drawType)
			yield effectAutoGain(eff, self.game, self.dbcGame, src='draw_item_%s' % drawType)
			result[i+1] = eff.result['items']

		effExt = ObjectGainAux(self.game, {'coin4': count})
		yield effectAutoGain(effExt, self.game, self.dbcGame, src='extra_item_draw')
		result.update({'extra': [['coin4', count]]})

		self.write({'view': {'result': result}})

		
# 抽宝石
class LotteryGemDraw(RequestHandlerTask):
	url = r'/game/lottery/gem/draw'

	@coroutine
	def run(self):
		drawType = self.input.get('drawType', None)
		decompose = self.input.get('decompose', 0)  # 是否分解蓝色及蓝色以下品质符石

		if drawType is None or drawType not in (
				DrawGemDefs.RMB1, DrawGemDefs.RMB10, DrawGemDefs.Free1, DrawGemDefs.Gold1, DrawGemDefs.Gold10,
				DrawGemDefs.FreeGold1):
			raise ClientError('param miss')

		eff = self.game.lotteryRecord.drawGem(drawType)

		if decompose:
			eff.gem2item()

		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='draw_gem_%s' % drawType)

		self.write({
			'view': {'result': eff.result}
		})

		
# 抽芯片
class LotteryChipDraw(RequestHandlerTask):
	url = r'/game/lottery/chip/draw'

	@coroutine
	def run(self):
		drawType = self.input.get('drawType', None)
		up = self.input.get('up', [])  # up选择

		if drawType is None or drawType not in (DrawChipDefs.RMB1, DrawChipDefs.RMB10, DrawChipDefs.Free1, DrawChipDefs.Item1, DrawChipDefs.Item10, DrawChipDefs.FreeItem1):
			raise ClientError('param miss')

		if len(up) != len(set(up)):
			raise ClientError('duplicate up')
		if len(up) > ConstDefs.chipUpLimit:
			raise ClientError('up over limit')

		chooses = [ObjectChip.ChipSuitChipMap[suitID] for suitID in up]
		chooses = reduce(lambda a, b: a+b, chooses) if chooses else []
		eff = self.game.lotteryRecord.drawChip(drawType, chooses)

		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='draw_chip_%s' % drawType)

			self.write({
				'view': {'result': eff.result}
			})


# 自选限定抽卡
class LotteryCardUpDraw(RequestHandlerTask):
	url = r'/game/lottery/card/up/draw'

	@coroutine
	def run(self):
		drawType = self.input.get('drawType', None)
		choose = self.input.get('choose', None)  # up选择

		if drawType is None or choose is None:
			raise ClientError('param miss')
		if drawType not in (DrawCardDefs.GroupUpRMB1, DrawCardDefs.GroupUpRMB10):
			raise ClientError('drawType error')

		eff = self.game.lotteryRecord.drawCardGroupUp(drawType, choose)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='draw_card_%s' % drawType)
			if eff.getCardsObjD():
				for dbID, obj in eff.getCardsObjD().iteritems():
					ObjectMessageGlobal.newsCardMsg(self.game.role, obj, 'group_draw_up')
					ObjectMessageGlobal.marqueeBroadcast(self.game.role, MessageDefs.MqGroupDrawCardUp, card=obj)
			self.write({
				'view': {'result': eff.result}
			})


# 自选限定抽卡up选择
class LotteryCardUpDrawChoose(RequestHandlerTask):
	url = r'/game/lottery/card/up/choose'

	@coroutine
	def run(self):
		choose = self.input.get('choose', None)  # up选择

		if choose is None:
			raise ClientError('param miss')
		if choose not in csv.draw_card_up_group:
			raise ClientError('choose error')
		if self.game.lotteryRecord.draw_card_up_choose == choose:
			raise ClientError('same choose')

		count = self.game.dailyRecord.draw_card_up_change_times
		if count >= ConstDefs.drawCardUpChangeLimit:
			raise ClientError('draw card up change limit')
		costRMB = ObjectCostCSV.getDrawCardUpChangeCost(count)
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError('cost rmb no enough')
		cost.cost(src='draw_card_up_change')
		self.game.dailyRecord.draw_card_up_change_times += 1

		self.game.lotteryRecord.draw_card_up_choose = choose


# 许愿簿 - 设置自选卡牌
class LotteryDrawCustom(RequestHandlerTask):
	url = r'/game/lottery/draw/custom'

	@coroutine
	def run(self):
		"""
		许愿簿 - 设置自选卡牌
		drawType: "drawLimit" / "drawGroupUp" / "drawRmb"
		custom: 选择的数据
		  - drawLimit: [yyID, cardID]
		  - drawGroupUp: [libID, libID, ...]
		  - drawRmb: [libID, libID, ...]
		"""
		drawType = self.input.get('drawType', None)
		data = self.input.get('custom', None)

		if drawType is None or data is None:
			raise ClientError('param miss')

		lottery = self.game.lotteryRecord

		if drawType == 'drawLimit':
			# 限时自选 [yyID, cardID]
			if not isinstance(data, list) or len(data) != 2:
				raise ClientError('data format error')
			lottery.draw_limit_custom = data

		elif drawType == 'drawGroupUp':
			# UP池自选 [libID, ...]
			if not isinstance(data, list):
				raise ClientError('data format error')
			# 前端期望格式: {1: [libID, ...]}
			lottery.draw_group_up_custom = {1: data} if data else {}

		elif drawType == 'drawRmb':
			# 钻石池自选 [libID, ...]
			if not isinstance(data, list):
				raise ClientError('data format error')
			# 前端期望格式: {1: [libID, ...]}
			lottery.draw_rmb_custom = {1: data} if data else {}

		else:
			raise ClientError('drawType error')

		self.write({'view': {}})


# 自选抽卡 - 执行抽卡
class LotteryGroupUpCustomDraw(RequestHandlerTask):
	url = r'/game/lottery/group/up/custom/draw'

	@coroutine
	def run(self):
		"""
		自选抽卡 - 从选中的5张S级卡 + A/B级卡池中抽取
		drawType: "group_up_custom_rmb1" / "group_up_custom_rmb10"
		概率: 11% S级(选中的5张) + 36% A级 + 53% B级
		"""
		drawType = self.input.get('drawType', None)

		if drawType is None:
			raise ClientError('param miss')
		if drawType not in (DrawCardDefs.GroupUpCustomRMB1, DrawCardDefs.GroupUpCustomRMB10):
			raise ClientError('drawType error')

		eff = self.game.lotteryRecord.drawCardGroupUpCustom(drawType)
		if not eff:
			raise ServerError('draw card eff was empty')

		yield effectAutoGain(eff, self.game, self.dbcGame, src='draw_card_%s' % drawType)
		if eff.getCardsObjD():
			for dbID, obj in eff.getCardsObjD().iteritems():
				ObjectMessageGlobal.newsCardMsg(self.game.role, obj, 'group_up_custom_draw')
				ObjectMessageGlobal.marqueeBroadcast(self.game.role, MessageDefs.MqGroupDrawCardUp, card=obj)

		self.write({'view': {'result': eff.result}})


# 抽图腾
class LotteryTotemDraw(RequestHandlerTask):
	url = r'/game/lottery/totem/draw'
	
	@coroutine
	def run(self):
		"""
		图腾抽奖
		drawType: 'free1', 'rmb1', 'rmb6'
		"""
		from game.object import FeatureDefs
		from game.object.game.levelcsv import ObjectFeatureUnlockCSV
		
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Totem, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		drawType = self.input.get('drawType', self.input)
		
		if not drawType:
			raise ClientError('param miss')
		
		# 解析抽奖类型和次数
		if drawType == 'free1':
			count = 1
			is_free = True
		elif drawType == 'rmb1':
			count = 1
			is_free = False
		elif drawType == 'rmb6':
			count = 6
			is_free = False
		else:
			raise ClientError('invalid drawType')
		
		# 检查次数限制
		vip_limit = self.game.role.drawTotemCountLimit
		if self.game.dailyRecord.draw_totem + count > vip_limit:
			raise ClientError('draw totem limit exceed')
		
		# 处理消耗
		cost = None
		ticket_id = 541  # 召唤石板（图腾抽奖券）
		
		if is_free:
			# 免费抽奖
			if self.game.dailyRecord.totem_rmb_dc1_free_count > 0:
				raise ClientError('free draw already used')
		else:
			# 付费抽奖 - 优先使用召唤石板，不足时使用钻石
			if count == 1:
				# 单抽：优先用召唤石板，不足用钻石
				cost = ObjectCostAux(self.game, {ticket_id: 1})
				if not cost.isEnough():
					draw_cost = ConstDefs.drawTotemCostPrice
					cost = ObjectCostAux(self.game, {'rmb': draw_cost})
			else:  # count == 6
				# 6连抽：优先用召唤石板，不足用钻石
				cost = ObjectCostAux(self.game, {ticket_id: 6})
				if not cost.isEnough():
					draw_cost = ConstDefs.draw6TotemCostPrice
					cost = ObjectCostAux(self.game, {'rmb': draw_cost})
			
			if not cost.isEnough():
				raise ClientError('cost not enough')
		
		# 执行抽奖
		result_items = []
		total_coin18 = 0  # 秘境原木总数
		
		import random
		for i in xrange(count):
			# 每次抽奖有40%概率获得秘境原木，60%概率获得图腾符号
			if random.random() < 0.4:  # 40%概率获得秘境原木
				coin18_count = random.randint(30, 100)
				total_coin18 += coin18_count
				# 秘境原木作为特殊标记添加到items中（用字符串'coin18'标识）
				result_items.append(['coin18', coin18_count])
			else:  # 60%概率获得图腾符号
				eff = self.game.lotteryRecord.drawTotem()
				yield effectAutoGain(eff, self.game, self.dbcGame, src='totem_draw')
				# 将物品添加到结果列表（转换为 [[itemID, count], ...] 格式）
				for item_id, item_count in eff.result.iteritems():
					if isinstance(item_id, int):  # 只处理物品ID（跳过特殊键如carddbIDs等）
						result_items.append([item_id, item_count])
		
		# 发放秘境原木奖励
		if total_coin18 > 0:
			coin18_eff = ObjectGainAux(self.game, {'coin18': total_coin18})
			yield effectAutoGain(coin18_eff, self.game, self.dbcGame, src='totem_draw_coin18')
		
		# 扣除消耗
		if is_free:
			self.game.dailyRecord.totem_rmb_dc1_free_count += 1
		else:
			if cost:
				cost.cost(src='totem_draw')
		
		# 更新抽奖次数
		self.game.dailyRecord.draw_totem += count
		
		# 更新勋章计数器（用于勋章墙系统）
		if not is_free:
			lottery = self.game.lotteryRecord
			if count == 1:
				lottery.totem_rmb_dc1_counter = (lottery.totem_rmb_dc1_counter or 0) + 1
			elif count == 6:
				lottery.totem_rmb_dc6_counter = (lottery.totem_rmb_dc6_counter or 0) + 1
		
		self.write({
			'view': {
				'result': {
					'items': result_items  # items中包含图腾符号和秘境原木
				}
			}
		})