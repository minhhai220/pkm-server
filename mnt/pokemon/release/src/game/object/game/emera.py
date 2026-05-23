#!/usr/bin/python
# coding=utf-8
"""
异域琉石系统
"""
import weakref
import random

from framework import str2num_t
from framework.csv import csv
from framework.helper import objectid2string, WeightRandomObject
from framework.log import logger
from framework.object import ObjectDBase, db_property, ObjectDBaseMap, ObjectBase
from game import ClientError
from game.object import EmeraDefs, CardResetDefs
from game.object.game.calculator import zeros
from game.object.game.card import ObjectCard
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from tornado.gen import coroutine


#
# ObjectEmera 琉石对象
#
class ObjectEmera(ObjectDBase):
	DBModel = 'RoleEmera'

	EmeraObjsMap = weakref.WeakValueDictionary()
	EmeraLinkageMap = {}  # {libID: [libCfg]} - 用于随机生成印记
	EmeraLinkageSuitMap = {}  # {(linkageID, suitNum): cfg} - 匹配前端 gEmerasLinkageSuitAttrCsv[linkageID][suitNum]
	EmeraBaseAttrMap = {}  # {(seq, level): cfg} - 匹配前端 gEmerasBaseAttrCsv[seq][level]
	EmeraStrengthCostMax = None

	@classmethod
	def classInit(cls):
		"""刷新csv配置 - 匹配前端数据结构"""
		# 刷新现有对象
		for obj in cls.EmeraObjsMap.itervalues():
			obj.init()

		# 印记库 - 按 libID 分组（用于随机生成印记）
		# libs.csv: libID -> [libCfg]，libCfg 包含 linkageID 和 weight
		cls.EmeraLinkageMap = {}
		for i in csv.emera.libs:
			cfg = csv.emera.libs[i]
			libID = getattr(cfg, 'libID', 0) or 0
			cls.EmeraLinkageMap.setdefault(libID, []).append(cfg)

		# 印记套装效果 - 按 (linkageID, suitNum) 分组
		# 匹配前端: gEmerasLinkageSuitAttrCsv[linkageID][suitNum] = cfg
		cls.EmeraLinkageSuitMap = {}
		for i in csv.emera.linkage_suit_attr:
			cfg = csv.emera.linkage_suit_attr[i]
			linkageID = getattr(cfg, 'linkageID', 0) or 0
			suitNum = getattr(cfg, 'suitNum', 0) or 0
			if linkageID and suitNum:
				cls.EmeraLinkageSuitMap[(linkageID, suitNum)] = cfg

		# 基础属性 - 按 (seq, level) 分组
		# 匹配前端: gEmerasBaseAttrCsv[seq][level] = cfg
		cls.EmeraBaseAttrMap = {}
		for i in csv.emera.base_attr:
			cfg = csv.emera.base_attr[i]
			seq = getattr(cfg, 'seq', 0) or 0
			level = getattr(cfg, 'level', 0) or 0
			if seq and level:
				cls.EmeraBaseAttrMap[(seq, level)] = cfg

		# 强化消耗最大等级
		if csv.emera.strength_cost:
			cls.EmeraStrengthCostMax = max(csv.emera.strength_cost)

	def init(self):
		ObjectEmera.EmeraObjsMap[self.id] = self
		# 确保数组字段不为 None（根据 Go结构体定义规范 错误4）
		if self.db.get('linkages') is None:
			self.db['linkages'] = []
		if self.db.get('recast_linkages') is None:
			self.db['recast_linkages'] = []
		return ObjectDBase.init(self)

	# Role.id
	role_db_id = db_property('role_db_id')

	# RoleCard.id
	card_db_id = db_property('card_db_id')

	# 琉石对应 CSV ID
	emera_id = db_property('emera_id')

	# 强化等级
	level = db_property('level')

	# 锁定状态
	locked = db_property('locked')

	# 印记列表 [buffID1, buffID2, ...]
	linkages = db_property('linkages')

	# 洗练后的新印记（临时，未确认）
	recast_linkages = db_property('recast_linkages')

	# 是否存在（可能已经被拆解）
	exist_flag = db_property('exist_flag')

	@property
	def cfg(self):
		"""获取CSV配置"""
		return csv.emera.emera[self.emera_id]

	@property
	def quality(self):
		"""品质"""
		return self.cfg.quality

	@property
	def style(self):
		"""形状类型"""
		return self.cfg.style

	@property
	def emera_type(self):
		"""琉石类型 1=普通 2=核心"""
		return self.cfg.type

	@property
	def is_core(self):
		"""是否核心琉石"""
		return self.cfg.type == EmeraDefs.CoreType

	@property
	def is_dressed(self):
		"""是否已镶嵌"""
		return self.card_db_id is not None and self.card_db_id != ''

	def getAttrs(self):
		"""
		计算琉石自身属性加成
		匹配前端: gEmerasBaseAttrCsv[emeraCfg.baseAttr][level]
		"""
		const = zeros()
		percent = zeros()
		cfg = self.cfg

		# 基础属性 - 通过 (baseAttr, level) 查找
		baseAttr = getattr(cfg, 'baseAttr', 0) or 0
		if baseAttr:
			baseCfg = ObjectEmera.EmeraBaseAttrMap.get((baseAttr, self.level), None)
			if baseCfg:
				for i in xrange(1, 99):
					attrTypeKey = "attrType%d" % i
					attrType = getattr(baseCfg, attrTypeKey, None)
					if not attrType:
						break
					attrNum = getattr(baseCfg, "attrNum%d" % i, 0) or 0
					num = str2num_t(attrNum)
					const[attrType] += num[0]
					percent[attrType] += num[1]

		return const, percent

	def onAdd(self):
		"""琉石获得时初始化"""
		self.level = 1
		self.locked = False
		cfg = self.cfg
		# 生成印记
		linkageNum = getattr(cfg, 'linkageNum', 0) or 0
		if linkageNum > 0:
			self.randomLinkages(linkageNum)

	def randomLinkages(self, num):
		"""随机生成印记"""
		linkages = []
		cfg = self.cfg
		linkageLibID = getattr(cfg, 'linkageLib', 0) or 0
		linkage_lib = self.EmeraLinkageMap.get(linkageLibID, [])
		if linkage_lib:
			weights = [(libCfg.linkageID, libCfg.weight) for libCfg in linkage_lib]
			for _ in range(num):
				got = set(linkages)
				available = [(lid, w) for lid, w in weights if lid not in got]
				if available:
					linkageID, _ = WeightRandomObject.onceRandom(available)
					linkages.append(linkageID)
		self.linkages = linkages

	@staticmethod
	def getRecastWeight(libCfg, emeraLevel):
		"""
		根据琉石等级获取洗练权重
		recastWeight 格式: [[minLv, maxLv, weight], ...]
		例如: <<0;10;70>;<11;20;90>;<21;30;110>;<31;999999;130>>
		"""
		recastWeights = getattr(libCfg, 'recastWeight', None)
		if recastWeights:
			for item in recastWeights:
				if len(item) >= 3:
					minLv, maxLv, weight = item[0], item[1], item[2]
					if minLv <= emeraLevel <= maxLv:
						return weight
		# 兜底：使用原始固定权重
		return libCfg.weight

	def getEmeraPos(self):
		"""获取琉石在卡牌的镶嵌位置"""
		if not self.is_dressed:
			return None
		card = self.game.cards.getCard(self.card_db_id)
		if card is None:
			return None
		for pos, emeraID in (card.emeras or {}).iteritems():
			if emeraID == self.id:
				return pos
		return None


#
# ObjectEmerasMap 琉石管理器
#
class ObjectEmerasMap(ObjectDBaseMap):

	def __init__(self, game):
		ObjectDBaseMap.__init__(self, game)
		self._passive_skills = {}  # 效果被动技能 {cardID: {skillID: level}}

	def _new(self, dic):
		emera = ObjectEmera(self.game, self.game._dbcGame)
		emera.set(dic)
		return (emera.id, emera)

	def init(self):
		ret = ObjectDBaseMap.init(self)
		# 清理 role.emeras 中不存在的 emera ID
		roleEmeras = self.game.role.emeras or []
		validEmeras = [emeraID for emeraID in roleEmeras if emeraID in self._objs and self._objs[emeraID].exist_flag]
		if len(validEmeras) != len(roleEmeras):
			invalidCount = len(roleEmeras) - len(validEmeras)
			logger.warning('role %s emeras list has %d invalid emera IDs, cleaned' % (objectid2string(self.game.role.id), invalidCount))
			self.game.role.emeras = validEmeras
		return ret

	def _fixCorrupted(self):
		"""修复数据不一致"""
		for _, emera in self._objs.iteritems():
			cardID = emera.card_db_id
			if cardID and not self.game.cards.getCard(emera.card_db_id):
				emera.card_db_id = None
				logger.warning('role %s emera %s %s card not exist!' % (
					objectid2string(self.game.role.id), emera.emera_id, objectid2string(emera.id)))

	def getEmera(self, emeraID):
		"""获取单个琉石对象"""
		ret = self._objs.get(emeraID, None)
		if ret and not ret.exist_flag:
			return None
		return ret

	def getEmeras(self, emeraIDs):
		"""获取多个琉石对象"""
		ret = []
		for eid in emeraIDs:
			if eid in self._objs:
				emera = self._objs[eid]
				if not emera.exist_flag:
					continue
				ret.append(emera)
		return ret

	def addEmeras(self, emerasL):
		"""添加多个琉石对象"""
		if len(emerasL) == 0:
			return {}

		def _new(dic):
			emera = ObjectEmera(self.game, self.game._dbcGame)
			emera.set(dic).init().startSync()
			emera.onAdd()
			return (emera.id, emera)

		objs = dict(map(_new, emerasL))
		self._objs.update(objs)
		self.game.role.emeras = map(lambda o: o.id, self._objs.itervalues())
		self._add(objs.keys())
		return objs

	def deleteEmeras(self, objs):
		"""删除琉石对象"""
		if not objs:
			return
		for obj in objs:
			# 如果琉石装备在卡牌上，先从卡牌中移除
			if obj.card_db_id:
				card = self.game.cards.getCard(obj.card_db_id)
				if card:
					for pos, emeraID in list((card.emeras or {}).iteritems()):
						if emeraID == obj.id:
							cardEmeras = card.emeras or {}
							cardEmeras.pop(pos, None)
							card.emeras = cardEmeras
							break
				obj.card_db_id = None
			obj.exist_flag = False
			del self._objs[obj.id]
			self._del([obj.id])
			ObjectEmera.EmeraObjsMap.pop(obj.id, None)
		self.game.role.emeras = map(lambda o: o.id, self._objs.itervalues())
		for obj in objs:
			obj.delete_async()

	def getCardEmeraLinkageNum(self, card):
		"""
		获取卡牌下琉石的印记数量统计
		:return: {linkageID: count}
		"""
		linkageMap = {}
		for pos, emeraID in (card.emeras or {}).iteritems():
			emera = self.getEmera(emeraID)
			if emera is None:
				continue
			for linkageID in (emera.linkages or []):
				linkageMap[linkageID] = linkageMap.get(linkageID, 0) + 1
		return linkageMap

	def getEmeraLinkageSuitAttrs(self, card):
		"""
		计算琉石印记套装属性加成
		印记达到 2/4/6 个激活对应效果
		匹配前端: gEmerasLinkageSuitAttrCsv[linkageID][suitNum]
		"""
		const = zeros()
		percent = zeros()
		skills = {}

		linkageMap = self.getCardEmeraLinkageNum(card)
		for linkageID, count in linkageMap.iteritems():
			# 根据数量激活套装（只取最高档）
			for suitNum in (6, 4, 2):
				if count >= suitNum:
					suitCfg = ObjectEmera.EmeraLinkageSuitMap.get((linkageID, suitNum), None)
					if suitCfg:
						# 属性加成
						for i in xrange(1, 99):
							attrTypeKey = "attrType%d" % i
							attrType = getattr(suitCfg, attrTypeKey, None)
							if not attrType:
								break
							attrNum = getattr(suitCfg, "attrNum%d" % i, 0) or 0
							num = str2num_t(attrNum)
							const[attrType] += num[0]
							percent[attrType] += num[1]

						# 技能
						skillID = getattr(suitCfg, 'skillID', None)
						if skillID:
							skills[skillID] = 1
					break  # 只取最高档

		self._passive_skills[card.id] = skills
		return const, percent

	def getEmeraExtraAttrs(self, card):
		"""
		计算琉石额外属性（镶嵌效果）
		根据品质、等级等条件激活
		匹配前端: 每个 type 只激活优先级最高的一个效果
		"""
		const = zeros()
		percent = zeros()

		emeras = card.emeras or {}
		if not emeras:
			return const, percent

		# 统计品质和等级
		qualityMap = {}  # {quality: count}
		levelMap = {}  # {level: count}

		for pos, emeraID in emeras.iteritems():
			emera = self.getEmera(emeraID)
			if emera is None:
				continue

			q = emera.quality
			qualityMap[q] = qualityMap.get(q, 0) + 1

			lv = emera.level
			levelMap[lv] = levelMap.get(lv, 0) + 1

		# 按 type 分组，按 priority 降序排序（匹配前端 gEmerasExtraAttrCsv 逻辑）
		typeGroups = {}  # {type: [(priority, cfg), ...]}
		for cfgID in csv.emera.extra_attr:
			cfg = csv.emera.extra_attr[cfgID]
			cfgType = getattr(cfg, 'type', 0) or 0
			priority = getattr(cfg, 'priority', 0) or 0
			if cfgType not in typeGroups:
				typeGroups[cfgType] = []
			typeGroups[cfgType].append((priority, cfg))

		# 每个 type 按 priority 降序排序
		for cfgType in typeGroups:
			typeGroups[cfgType].sort(key=lambda x: x[0], reverse=True)

		# 每个 type 只激活第一个满足条件的效果
		for cfgType in (1, 2):  # type 1: 品质条件, type 2: 等级条件
			if cfgType not in typeGroups:
				continue

			for priority, cfg in typeGroups[cfgType]:
				param = cfg.param or []
				if len(param) < 2:
					continue

				needCount, threshold = param[0], param[1]
				matched = False

				if cfgType == 1:
					# 品质条件
					count = sum(v for q, v in qualityMap.iteritems() if q >= threshold)
					matched = count >= needCount
				elif cfgType == 2:
					# 等级条件
					count = sum(v for lv, v in levelMap.iteritems() if lv >= threshold)
					matched = count >= needCount

				if matched:
					for i in range(1, 99):
						attrTypeKey = "attrType%d" % i
						attrType = getattr(cfg, attrTypeKey, None)
						if not attrType:
							break
						attrNum = getattr(cfg, "attrNum%d" % i, 0)
						num = str2num_t(attrNum)
						const[attrType] += num[0]
						percent[attrType] += num[1]
					break  # 只激活第一个满足条件的（优先级最高的）

		return const, percent

	def getPassiveSkills(self, cardID):
		"""获取琉石印记激活的被动技能"""
		return self._passive_skills.get(cardID, {})

	def strengthEmera(self, emeraID, targetLevel):
		"""
		琉石强化
		"""
		emera = self.getEmera(emeraID)
		if emera is None:
			raise ClientError('emera not exist')

		cfg = emera.cfg
		maxLevel = getattr(cfg, 'maxLevel', 50) or 50

		if targetLevel <= emera.level:
			raise ClientError('level invalid')
		if targetLevel > maxLevel:
			raise ClientError('level max')

		# 计算消耗
		strengthSeq = getattr(cfg, 'strengthSeq', 1) or 1
		costItemKey = 'costItemMap%d' % strengthSeq
		totalCost = {}

		for lv in xrange(emera.level, targetLevel):
			costLevel = min(lv, ObjectEmera.EmeraStrengthCostMax or lv)
			if costLevel in csv.emera.strength_cost:
				costCfg = csv.emera.strength_cost[costLevel]
				costMap = getattr(costCfg, costItemKey, {}) or {}
				for itemID, count in costMap.iteritems():
					totalCost[itemID] = totalCost.get(itemID, 0) + count

		# 检查并扣除消耗
		cost = ObjectCostAux(self.game, totalCost)
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='emera_strength')

		emera.level = targetLevel

		# 如果已镶嵌，重算卡牌属性
		if emera.is_dressed:
			card = self.game.cards.getCard(emera.card_db_id)
			if card:
				ObjectCard.calcAttrs(card)
				card.onUpdateAttrs()

	def recastEmera(self, emeraID, recastPos):
		"""
		琉石洗练印记
		:param emeraID: 琉石ID
		:param recastPos: 要洗练的印记位置列表
		注：locked 只限制拆解，不限制洗练（匹配前端逻辑）
		"""
		emera = self.getEmera(emeraID)
		if emera is None:
			raise ClientError('emera not exist')

		cfg = emera.cfg
		linkageNum = getattr(cfg, 'linkageNum', 0) or 0
		if linkageNum <= 0:
			raise ClientError('no linkage')

		oldLinkages = emera.linkages or []
		if not oldLinkages:
			raise ClientError('no linkage to recast')

		# 计算消耗（根据要洗练的数量和琉石洗练消耗序列）
		# 前端 getBuffLockNum() 返回的是要洗练的数量，用这个数量查表
		recastNum = len(recastPos)
		recastNum = max(1, min(recastNum, 3))

		if recastNum not in csv.emera.recast_cost:
			raise ClientError('config error')
		costCfg = csv.emera.recast_cost[recastNum]

		recastCostSeq = getattr(cfg, 'recastCostSeq', 1) or 1
		costItemKey = 'costItemMap%d' % recastCostSeq
		costMap = getattr(costCfg, costItemKey, {}) or {}
		cost = ObjectCostAux(self.game, costMap)
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='emera_recast')

		# 生成新印记
		newLinkages = list(oldLinkages)
		linkageLibID = getattr(cfg, 'linkageLib', 0) or 0
		linkage_lib = ObjectEmera.EmeraLinkageMap.get(linkageLibID, [])
		emeraLevel = emera.level or 1

		for pos in recastPos:
			# 前端发送的是 1-indexed（Lua数组从1开始），转为 0-indexed
			idx = pos - 1
			if 0 <= idx < len(newLinkages):
				got = set(newLinkages)
				# 使用动态权重：根据琉石等级调整洗练概率
				weights = [
					(libCfg.linkageID, ObjectEmera.getRecastWeight(libCfg, emeraLevel))
					for libCfg in linkage_lib
					if libCfg.linkageID not in got or libCfg.linkageID == newLinkages[idx]
				]
				if weights:
					newLinkageID, _ = WeightRandomObject.onceRandom(weights)
					newLinkages[idx] = newLinkageID

		# 保存新印记到临时字段
		emera.db['recast_linkages'] = list(newLinkages)

		return newLinkages

	def confirmRecast(self, emeraID, replace):
		"""
		确认洗练结果
		:param replace: True=替换, False=取消
		"""
		emera = self.getEmera(emeraID)
		if emera is None:
			raise ClientError('emera not exist')

		if replace:
			if emera.recast_linkages:
				emera.db['linkages'] = list(emera.recast_linkages)

		# 清除临时印记
		emera.db['recast_linkages'] = []

	def rebirthEmeras(self, emeraIDs):
		"""
		琉石重生（返还强化材料，需消耗钻石）
		"""
		from game.object.game.card import ObjectCardRebirthBase

		totalReturn = {}
		toRebirth = []

		# 第一遍：计算返还材料（用于计算钻石消耗）
		for emeraID in emeraIDs:
			emera = self.getEmera(emeraID)
			if emera is None:
				continue

			if emera.locked:
				raise ClientError('emera locked')

			if emera.level <= 1:
				continue

			# 计算返还材料
			cfg = emera.cfg
			strengthSeq = getattr(cfg, 'strengthSeq', 1) or 1
			costItemKey = 'costItemMap%d' % strengthSeq

			for lv in xrange(1, emera.level):
				costLevel = min(lv, ObjectEmera.EmeraStrengthCostMax or lv)
				if costLevel in csv.emera.strength_cost:
					costCfg = csv.emera.strength_cost[costLevel]
					costMap = getattr(costCfg, costItemKey, {}) or {}
					for itemID, count in costMap.iteritems():
						totalReturn[itemID] = totalReturn.get(itemID, 0) + count

			toRebirth.append(emera)

		# 计算并扣除钻石消耗（匹配前端 RebirthTools.computeCost(curData, 6)）
		if totalReturn:
			costRmb = ObjectCardRebirthBase.rebirthCost(totalReturn, CardResetDefs.emeraCostType)
			if costRmb > 0:
				cost = ObjectCostAux(self.game, {'rmb': costRmb})
				if not cost.isEnough():
					raise ClientError('rmb not enough')
				cost.cost(src='emera_rebirth')

		# 第二遍：执行重生
		for emera in toRebirth:
			# 重置等级
			emera.level = 1

			# 如果已镶嵌，重算卡牌属性
			if emera.is_dressed:
				card = self.game.cards.getCard(emera.card_db_id)
				if card:
					ObjectCard.calcAttrs(card)
					card.onUpdateAttrs()

		# 发放返还材料
		if totalReturn:
			gain = ObjectGainAux(self.game, totalReturn)
			gain.gain(src='emera_rebirth')

		return totalReturn

	def decomposeEmeras(self, emeraIDs):
		"""
		琉石拆解
		"""
		totalReturn = {}
		toDelete = []

		for emeraID in emeraIDs:
			emera = self.getEmera(emeraID)
			if emera is None:
				continue

			if emera.locked:
				raise ClientError('emera locked')

			cfg = emera.cfg
			# 红色及以上品质不可拆解
			if cfg.quality >= 6:
				raise ClientError('quality too high')

			# 获取拆解返还（基础返还）
			decomposeReturn = getattr(cfg, 'decomposeReturn', {}) or {}
			for itemID, count in decomposeReturn.iteritems():
				totalReturn[itemID] = totalReturn.get(itemID, 0) + count

			# 返还强化消耗的材料（匹配前端 decompose.lua 569-574）
			if emera.level > 1:
				strengthSeq = getattr(cfg, 'strengthSeq', 1) or 1
				costItemKey = 'costItemMap%d' % strengthSeq
				for lv in xrange(1, emera.level):
					costLevel = min(lv, ObjectEmera.EmeraStrengthCostMax or lv)
					if costLevel in csv.emera.strength_cost:
						costCfg = csv.emera.strength_cost[costLevel]
						costMap = getattr(costCfg, costItemKey, {}) or {}
						for itemID, count in costMap.iteritems():
							totalReturn[itemID] = totalReturn.get(itemID, 0) + count

			toDelete.append(emera)

		# 发放返还材料
		if totalReturn:
			gain = ObjectGainAux(self.game, totalReturn)
			gain.gain(src='emera_decompose')

		# 删除琉石
		self.deleteEmeras(toDelete)

		return totalReturn

	@coroutine
	def combEmeras(self, emeraIDs, dbc):
		"""
		琉石铸型（合成更高品质）
		"""
		from game.handler.inl import createEmerasDB
		from tornado.gen import Return

		if len(emeraIDs) < 3:
			raise ClientError('need 3 emeras')

		emeras = self.getEmeras(emeraIDs)
		if len(emeras) != len(emeraIDs):
			raise ClientError('emera not exist')

		# 检查琉石品质必须为红色(6)，且不能锁定/已穿戴
		firstEmera = emeras[0]
		for emera in emeras:
			if emera.quality != 6:
				raise ClientError('quality must be 6')
			if emera.locked:
				raise ClientError('emera locked')
			if emera.is_dressed:
				raise ClientError('emera dressed')

		# 查找合成目标
		targetQuality = firstEmera.quality + 1
		targetStyle = firstEmera.style
		targetEmeraID = None

		for cfgID in csv.emera.emera:
			cfg = csv.emera.emera[cfgID]
			if cfg.quality == targetQuality and cfg.style == targetStyle:
				targetEmeraID = cfgID
				break

		if targetEmeraID is None:
			raise ClientError('no target emera')

		# 消耗琉石
		self.deleteEmeras(emeras)

		# 创建新琉石数据库记录
		emeraDatas = yield createEmerasDB(targetEmeraID, self.game.role.id, dbc)
		# 添加到游戏对象
		newEmeras = self.game.emeras.addEmeras(emeraDatas)

		raise Return(newEmeras.values()[0] if newEmeras else None)
