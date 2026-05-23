#!/usr/bin/python
# coding=utf-8
"""
异域琉石系统接口处理器
"""

from framework.csv import csv, ErrDefs, ConstDefs
from framework.log import logger
from game import ClientError
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import DrawEmeraDefs, EmeraDefs, TargetDefs
from game.object.game.card import ObjectCard
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from game.object.game.emera import ObjectEmera
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.thinkingdata import ta
from tornado.gen import coroutine


# ==================== 抽取琉石 ====================

class EmeraDrawHandler(RequestHandlerTask):
	"""抽取琉石 /game/lottery/emera/draw"""
	url = r'/game/lottery/emera/draw'

	@coroutine
	def run(self):
		drawType = self.input.get('drawType', DrawEmeraDefs.RMB1)

		# 解析抽取类型
		if drawType == DrawEmeraDefs.Free1:
			count = 1
			is_free = True
		elif drawType == DrawEmeraDefs.RMB1:
			count = 1
			is_free = False
		elif drawType == DrawEmeraDefs.RMB5:
			count = 5
			is_free = False
		else:
			raise ClientError('param error')

		# 检查免费次数
		if is_free:
			free_count = self.game.dailyRecord.emera_rmb_dc1_free_count or 0
			if free_count >= 1:
				raise ClientError('free count used')
		else:
			# 检查抽取次数限制
			draw_count = self.game.dailyRecord.draw_emera_rmb or 0
			vip_limit = getattr(csv.vip[self.game.role.vip_level], 'rmbDrawEmeraCountLimit', 999999) or 999999
			if draw_count + count > vip_limit:
				raise ClientError('draw limit')

			# 检查消耗
			# 优先使用抽取券（星月金符 ID=545）
			emeraTicket = DrawEmeraDefs.RMBDrawItem
			ticket_count = self.game.role.items.get(emeraTicket, 0)
			if ticket_count >= count:
				# 消耗抽取券
				cost = ObjectCostAux(self.game, {emeraTicket: count})
				if not cost.isEnough():
					raise ClientError('cost not enough')
				cost.cost(src='emera_draw_ticket')
			else:
				# 消耗钻石
				if count == 1:
					costPrice = getattr(ConstDefs, 'drawEmeraCostPrice', 198) or 198
				else:
					costPrice = getattr(ConstDefs, 'draw5EmeraCostPrice', 980) or 980
				cost = ObjectCostAux(self.game, {'rmb': costPrice})
				if not cost.isEnough():
					raise ClientError('rmb not enough')
				cost.cost(src='emera_draw_rmb')

		# 执行抽取
		emeradbIDs = []
		for _ in xrange(count):
			emera = yield _drawOneEmera(self.game, self.dbcGame)
			emeradbIDs.append(emera.id)

		# 更新抽取记录
		if is_free:
			self.game.dailyRecord.emera_rmb_dc1_free_count = 1
			# 免费抽也算单抽计数器（用于保底）
			self.game.lotteryRecord.emera_rmb_dc1_counter = (self.game.lotteryRecord.emera_rmb_dc1_counter or 0) + 1
		else:
			self.game.dailyRecord.draw_emera_rmb = (self.game.dailyRecord.draw_emera_rmb or 0) + count
			# 更新抽取计数器（用于保底，存在 lotteryRecord 中）
			if count == 1:
				self.game.lotteryRecord.emera_rmb_dc1_counter = (self.game.lotteryRecord.emera_rmb_dc1_counter or 0) + 1
			elif count == 5:
				self.game.lotteryRecord.emera_rmb_dc5_counter = (self.game.lotteryRecord.emera_rmb_dc5_counter or 0) + 1
			# 任务统计
			ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawEmeraRMB, count)

		# 任务统计（总抽取次数）
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DrawEmera, count)

		self.write({
			'view': {'result': {'emeradbIDs': emeradbIDs}}
		})

@coroutine
def _drawOneEmera(game, dbcGame):
	"""抽取一个琉石（模块级函数，供日常助手一键调用）"""
	import random
	from framework.helper import WeightRandomObject
	from game.handler.inl import createEmerasDB
	from tornado.gen import Return

	# 品质概率（匹配 draw_preview.csv type=15）
	# quality 2=绿50%, 3=蓝27%, 4=紫15%, 5=橙6.4%, 6=红1.6%, 7=钻彩不投放
	qualityWeights = [(2, 500), (3, 270), (4, 150), (5, 64), (6, 16)]

	# 按品质概率抽取
	targetQuality, _ = WeightRandomObject.onceRandom(qualityWeights)

	# 收集该品质的所有琉石
	qualityEmeras = []
	for cfgID in csv.emera.emera:
		cfg = csv.emera.emera[cfgID]
		if getattr(cfg, 'quality', 0) == targetQuality:
			qualityEmeras.append(cfgID)

	# 随机选择一个
	if qualityEmeras:
		emeraID = random.choice(qualityEmeras)
	else:
		# 兜底：从所有非钻彩琉石中随机
		allEmeras = []
		for cfgID in csv.emera.emera:
			cfg = csv.emera.emera[cfgID]
			quality = getattr(cfg, 'quality', 0) or 0
			if 2 <= quality <= 6:  # 排除 quality 7 (钻彩)
				allEmeras.append(cfgID)
		emeraID = random.choice(allEmeras) if allEmeras else list(csv.emera.emera.keys())[0]

	# 创建琉石数据库记录
	emeraDatas = yield createEmerasDB(emeraID, game.role.id, dbcGame)
	emerasDict = game.emeras.addEmeras(emeraDatas)

	raise Return(emerasDict.values()[0] if emerasDict else None)


# ==================== 镶嵌/卸下/更换琉石 ====================

class EmeraChangeHandler(RequestHandlerTask):
	"""镶嵌/卸下/更换琉石 /game/emera/change"""
	url = r'/game/emera/change'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		posEmeraIDs = self.input.get('posEmeraIDs', {})

		# 前端发 list 时转成 dict（Lua 连续整数 key 会序列化为 array）
		if isinstance(posEmeraIDs, list):
			posEmeraIDs = {i + 1: v for i, v in enumerate(posEmeraIDs)}

		if cardID is None:
			raise ClientError('param miss')

		# 获取卡牌
		card = self.game.cards.getCard(cardID)
		if card is None:
			raise ClientError('card not exist')

		# 获取卡牌的镶嵌方案
		cardCfg = csv.cards[card.card_id]
		emeraPlanID = getattr(cardCfg, 'emeraPlanID', None)
		if emeraPlanID and emeraPlanID in csv.emera.inset_plan:
			planCfg = csv.emera.inset_plan[emeraPlanID]
		else:
			planCfg = None

		oldFightingPoint = card.fighting_point
		currentEmeras = card.emeras or {}

		# 处理每个位置
		for posStr, emeraDbID in posEmeraIDs.iteritems():
			pos = int(posStr)

			if pos < 1 or pos > EmeraDefs.MaxSlots:
				raise ClientError('invalid pos')

			# 获取该位置允许的形状
			if pos == EmeraDefs.MainSlot:
				# 中心位置：只能核心琉石
				isCore = True
				allowedStyle = None
			else:
				# 普通位置：按方案配置
				isCore = False
				if planCfg:
					styleTemplate = getattr(planCfg, 'normalStyleTemplate', None)
					if styleTemplate and pos - 2 < len(styleTemplate):
						allowedStyle = styleTemplate[pos - 2]
					else:
						allowedStyle = None
				else:
					allowedStyle = None

			# 卸下当前位置的琉石
			if pos in currentEmeras:
				oldEmeraID = currentEmeras[pos]
				oldEmera = self.game.emeras.getEmera(oldEmeraID)
				if oldEmera:
					oldEmera.card_db_id = None

			if emeraDbID == -1 or emeraDbID == '-1' or emeraDbID is None:
				# 卸下操作
				if pos in currentEmeras:
					del currentEmeras[pos]
			else:
				# 镶嵌操作
				emera = self.game.emeras.getEmera(emeraDbID)
				if emera is None:
					raise ClientError('emera not exist')

				# 检查形状是否匹配
				if pos == EmeraDefs.MainSlot:
					# 中心位置只能镶嵌核心琉石
					if not emera.is_core:
						raise ClientError('only core emera')
				else:
					# 普通位置不能镶嵌核心琉石
					if emera.is_core:
						raise ClientError('core emera only in pos 1')
					# 检查形状匹配（如果有配置）
					if allowedStyle is not None and emera.style != allowedStyle:
						raise ClientError('style not match')

				# 如果琉石已镶嵌在其他卡牌上，先卸下
				if emera.is_dressed and emera.card_db_id != cardID:
					otherCard = self.game.cards.getCard(emera.card_db_id)
					if otherCard:
						otherEmeras = otherCard.emeras or {}
						for p, eid in list(otherEmeras.iteritems()):
							if eid == emeraDbID:
								del otherEmeras[p]
						otherCard.emeras = otherEmeras
						ObjectCard.calcAttrs(otherCard)
						otherCard.onUpdateAttrs()

				# 镶嵌
				emera.card_db_id = cardID
				currentEmeras[pos] = emeraDbID

		card.emeras = currentEmeras

		# 重算卡牌属性
		ObjectCard.calcAttrs(card)
		card.onUpdateAttrs()

		ta.card(card, event='card_emera', oldFightingPoint=oldFightingPoint, emera_change_type='change')


# ==================== 强化琉石 ====================

class EmeraStrengthHandler(RequestHandlerTask):
	"""强化琉石 /game/emera/strength"""
	url = r'/game/emera/strength'

	@coroutine
	def run(self):
		emeraID = self.input.get('emeraID', None)
		targetLevel = self.input.get('level', None)

		if emeraID is None or targetLevel is None:
			raise ClientError('param miss')

		oldLevel = None
		emera = self.game.emeras.getEmera(emeraID)
		if emera:
			oldLevel = emera.level

		self.game.emeras.strengthEmera(emeraID, targetLevel)

		# 任务统计（强化次数 = 升级的等级数）
		if emera and oldLevel:
			levelUp = emera.level - oldLevel
			if levelUp > 0:
				ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.EmeraStrength, levelUp)


# ==================== 洗练印记 ====================

class EmeraRecastHandler(RequestHandlerTask):
	"""洗练印记 /game/emera/recast"""
	url = r'/game/emera/recast'

	@coroutine
	def run(self):
		emeraID = self.input.get('emeraID', None)
		recastPos = self.input.get('recastPos', [])

		if emeraID is None:
			raise ClientError('param miss')

		newLinkages = self.game.emeras.recastEmera(emeraID, recastPos)

		# 任务统计
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.EmeraRecast, 1)

		self.write({
			'view': {'recast_linkages': newLinkages}
		})


# ==================== 确认洗练 ====================

class EmeraConfirmHandler(RequestHandlerTask):
	"""确认洗练结果 /game/emera/confirm"""
	url = r'/game/emera/confirm'

	@coroutine
	def run(self):
		emeraID = self.input.get('emeraID', None)
		replace = self.input.get('replace', False)

		if emeraID is None:
			raise ClientError('param miss')

		self.game.emeras.confirmRecast(emeraID, replace)


# ==================== 锁定/解锁琉石 ====================

class EmeraLockedSwitchHandler(RequestHandlerTask):
	"""锁定/解锁琉石 /game/emera/locked/switch"""
	url = r'/game/emera/locked/switch'

	@coroutine
	def run(self):
		emeraID = self.input.get('emeraID', None)

		if emeraID is None:
			raise ClientError('param miss')

		emera = self.game.emeras.getEmera(emeraID)
		if emera is None:
			raise ClientError('emera not exist')

		emera.locked = not emera.locked

		self.write({
			'view': {'locked': emera.locked}
		})


# ==================== 重生琉石 ====================

class EmeraRebirthHandler(RequestHandlerTask):
	"""重生琉石 /game/emera/rebirth"""
	url = r'/game/emera/rebirth'

	@coroutine
	def run(self):
		emeraIDs = self.input.get('emeraIDs', [])

		if not emeraIDs:
			raise ClientError('param miss')

		result = self.game.emeras.rebirthEmeras(emeraIDs)

		self.write({
			'view': {'result': result}
		})


# ==================== 拆解琉石 ====================

class EmeraDecomposeHandler(RequestHandlerTask):
	"""拆解琉石 /game/emera/decompose"""
	url = r'/game/emera/decompose'

	@coroutine
	def run(self):
		emeraIDs = self.input.get('emeraIDs', [])

		if not emeraIDs:
			raise ClientError('param miss')

		result = self.game.emeras.decomposeEmeras(emeraIDs)

		self.write({
			'view': {'result': result}
		})


# ==================== 琉石铸型 ====================

class EmeraCombHandler(RequestHandlerTask):
	"""琉石铸型（合成更高品质） /game/emera/comb"""
	url = r'/game/emera/comb'

	@coroutine
	def run(self):
		emeraIDs = self.input.get('emeraIDs', [])

		if len(emeraIDs) < 3:
			raise ClientError('need 3 emeras')

		# 检查铸型次数
		vipLevel = self.game.role.vip_level or 0
		if vipLevel in csv.vip:
			vipCfg = csv.vip[vipLevel]
			maxTimes = getattr(vipCfg, 'combEmeraCountLimit', 0) or 0
			curTimes = self.game.dailyRecord.comb_emera or 0
			if curTimes >= maxTimes:
				raise ClientError('comb times limit')

		newEmera = yield self.game.emeras.combEmeras(emeraIDs, self.dbcGame)

		if newEmera:
			# 更新铸型次数
			self.game.dailyRecord.comb_emera = (self.game.dailyRecord.comb_emera or 0) + 1

			self.write({
				'view': {
					'emeradbIDs': [newEmera.id]
				}
			})
		else:
			raise ClientError('comb failed')
