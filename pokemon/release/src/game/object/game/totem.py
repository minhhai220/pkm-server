#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Totem System
'''

from framework.object import ObjectDBase, db_property
from framework.csv import csv
from framework.log import logger
from framework import str2num_t
from game import ClientError
from game.object.game.calculator import zeros


class ObjectTotem(ObjectDBase):
	"""图腾对象"""
	
	DBModel = 'Totem'
	
	# 数据库字段定义
	role_db_id = db_property('role_db_id')
	totem_insetted = db_property('totem_insetted')  # {symbolId: {slotIndex: itemCsvId}}
	totem_star = db_property('totem_star')  # {symbolId: starLevel}
	award = db_property('award')  # {key: value} 集合奖励等
	
	@classmethod
	def classInit(cls):
		"""类初始化"""
		pass
	
	def __init__(self, game, dbc):
		ObjectDBase.__init__(self, game, dbc)
		self._passive_attrs = None  # 缓存的属性加成
		self._nature_attrs = None  # 缓存按自然属性的加成
	
	def set(self, dic):
		"""设置数据"""
		if dic is None:
			dic = {}
		# 确保基础字段存在
		if 'totem_insetted' not in dic:
			dic['totem_insetted'] = {}
		if 'totem_star' not in dic:
			dic['totem_star'] = {}
		if 'award' not in dic:
			dic['award'] = {}
		ObjectDBase.set(self, dic)
		return self
	
	def init(self):
		"""初始化"""
		ObjectDBase.init(self)
		
		# 确保所有字段都有默认值（兼容老数据和空数据）
		if not self._db:
			return self
		
		if 'totem_insetted' not in self._db:
			self._db['totem_insetted'] = {}
		if 'totem_star' not in self._db:
			self._db['totem_star'] = {}
		if 'award' not in self._db:
			self._db['award'] = {}
		
		# 确保已激活秘符的 totem_star 被正确初始化（能量>=850时）
		self._ensureTotemStarInitialized()
		
		return self
	
	def isSymbolActive(self, symbol_id, totem_insetted=None, totem_star=None):
		"""
		检查秘符是否已激活
		
		激活条件（满足其一）：
		1. 所有槽位都镶嵌满了
		2. 已在 totem_star 中（激活后会存入 totem_star）
		
		Args:
			symbol_id: 秘符ID (csv.totem.symbol)
			totem_insetted: 可选的镶嵌数据（用于计算时传入临时数据）
			totem_star: 可选的星级数据（用于计算时传入临时数据）
		
		Returns:
			bool: 是否已激活
		"""
		if not (hasattr(csv, 'totem') and csv.totem and 
				hasattr(csv.totem, 'symbol') and csv.totem.symbol):
			return False
		
		if symbol_id not in csv.totem.symbol:
			return False
		
		# 使用传入的数据或默认的属性
		star = totem_star if totem_star is not None else self.totem_star
		insetted_data = totem_insetted if totem_insetted is not None else self.totem_insetted
		
		# 检查是否在 totem_star 中（激活后就会在里面）
		# totem_star[symbol_id] = 0 表示首次激活但未升星
		# totem_star[symbol_id] = 1-5 表示已升星（对应 CSV starLevel=1-5）
		star_dict = star or {}
		if symbol_id in star_dict:
			return True
		
		# 检查镶嵌是否完整
		cfg = csv.totem.symbol[symbol_id]
		insetted = (insetted_data or {}).get(symbol_id, {})
		totem_group = getattr(cfg, 'totemGroup1', [])
		
		# 检查所有槽位是否都已镶嵌
		for slot_idx in range(len(totem_group)):
			slot_key = slot_idx + 1  # 槽位从1开始
			if slot_key not in insetted:
				return False
		
		return True
	
	def _isSymbolFullyInsetted(self, symbol_id):
		"""
		检查秘符的所有槽位是否都已镶嵌（不检查 totem_star）
		
		Args:
			symbol_id: 秘符ID
		
		Returns:
			bool: 是否全部镶嵌
		"""
		if symbol_id not in csv.totem.symbol:
			return False
		
		cfg = csv.totem.symbol[symbol_id]
		insetted = (self.totem_insetted or {}).get(symbol_id, {})
		totem_group = getattr(cfg, 'totemGroup1', [])
		
		for slot_idx in range(len(totem_group)):
			slot_key = slot_idx + 1
			if slot_key not in insetted:
				return False
		
		return True
	
	def _ensureTotemStarInitialized(self):
		"""
		确保所有已激活的秘符在 totem_star 中有记录（兼容老数据）
		
		升星条件：总能量 >= 850 (totemStarUnlockNeedEnergy)
		
		前端 totem_star 值范围：
		- nil/不存在：未激活
		- 0：已激活但未升星
		- 1-N：已升星
		"""
		# 检查能量是否达到升星解锁条件
		unlock_energy = 850
		if hasattr(csv, 'common_config') and csv.common_config and 196 in csv.common_config:
			unlock_energy = getattr(csv.common_config[196], 'value', 850)
		
		total_energy = self.getTotalEnergy()
		if total_energy < unlock_energy:
			return
		
		# 遍历所有镶嵌过的秘符
		totem_insetted = self._db.get('totem_insetted') or {}
		totem_star = self._db.get('totem_star') or {}
		
		symbols_to_init = []
		for symbol_id in list(totem_insetted.keys()):
			# 只处理不在 totem_star 中的秘符
			if symbol_id not in totem_star:
				# 检查是否槽位填满
				if self._isSymbolFullyInsetted(symbol_id):
					symbols_to_init.append(symbol_id)
		
		# 有需要初始化的秘符
		if symbols_to_init:
			# 逐个更新 key，而不是一次性替换整个字典
			# 确保每个 key 的变化都被正确同步
			totem_star_db = self._db['totem_star']
			totem_insetted_db = self._db['totem_insetted']
			
			for symbol_id in symbols_to_init:
				# 设置 totem_star = 0（已激活但未升星）
				totem_star_db[symbol_id] = 0
				# 清空镶嵌数据，让玩家可以重新镶嵌来升星
				totem_insetted_db[symbol_id] = {}
	
	def _getStarSeqId(self, cfg):
		"""
		获取秘符的星级序列ID
		框架已处理默认值（None时用默认值），但空字符串需要额外处理
		"""
		star_seq_id = getattr(cfg, 'starSeqID', 101)
		# 空字符串或0时用默认值101
		if not star_seq_id:
			return 101
		return int(star_seq_id)
	
	def _getStarConfig(self, star_seq_id, star_level):
		"""
		根据 starSeqID 和 starLevel 获取对应的 star 配置
		csv.totem.star 结构是 {ID: cfg}，需要按字段筛选
		"""
		if not hasattr(csv.totem, 'star') or not csv.totem.star:
			return None
		
		# CSV 对象不支持 .iteritems()，需要先遍历 key 再取值
		for star_id in csv.totem.star:
			star_cfg = csv.totem.star[star_id]
			cfg_star_seq_id = getattr(star_cfg, 'starSeqID', 101)
			if not cfg_star_seq_id:
				cfg_star_seq_id = 101
			
			cfg_star_level = getattr(star_cfg, 'starLevel', 1)
			if not cfg_star_level:
				cfg_star_level = 1
			
			if int(cfg_star_seq_id) == star_seq_id and int(cfg_star_level) == star_level:
				return star_cfg
		
		return None
	
	def getActivatedSymbols(self, totem_insetted=None, totem_star=None):
		"""
		获取所有已激活的秘符列表
		
		Args:
			totem_insetted: 可选的镶嵌数据（用于计算时传入临时数据）
			totem_star: 可选的星级数据（用于计算时传入临时数据）
		
		Returns:
			list: 已激活的秘符ID列表
		"""
		activated = []
		
		# 使用传入的数据或默认的属性
		insetted = totem_insetted if totem_insetted is not None else self.totem_insetted
		star = totem_star if totem_star is not None else self.totem_star
		
		# 收集所有可能激活的秘符ID（镶嵌过的 + 升星过的）
		all_symbol_ids = set()
		if insetted:
			all_symbol_ids.update(insetted.keys())
		if star:
			all_symbol_ids.update(star.keys())
		
		for symbol_id in all_symbol_ids:
			if self.isSymbolActive(symbol_id, totem_insetted=insetted, totem_star=star):
				activated.append(symbol_id)
		
		return activated
	
	def getTotalEnergy(self, totem_insetted=None, totem_star=None):
		"""
		计算已激活图腾的总能量值
		
		Args:
			totem_insetted: 可选的镶嵌数据（用于计算时传入临时数据）
			totem_star: 可选的星级数据（用于计算时传入临时数据）
		
		Returns:
			int: 总能量值
		"""
		if not (hasattr(csv, 'totem') and csv.totem and 
				hasattr(csv.totem, 'symbol') and csv.totem.symbol):
			return 0
		
		# 使用传入的数据或默认的属性
		star = totem_star if totem_star is not None else self.totem_star
		
		total_energy = 0
		activated_symbols = self.getActivatedSymbols(totem_insetted=totem_insetted, totem_star=totem_star)
		
		for symbol_id in activated_symbols:
			if symbol_id not in csv.totem.symbol:
				continue
			
			cfg = csv.totem.symbol[symbol_id]
			base_power = getattr(cfg, 'power', 0)
			# totem_star: 0=未升星, 1-5=已升星
			star_level = (star or {}).get(symbol_id, 0)
			
			# 计算星级加成（star_level > 0 时才有加成，与前端逻辑一致）
			energy_percent = 0
			if star_level > 0:
				star_seq_id = self._getStarSeqId(cfg)
				star_cfg = self._getStarConfig(star_seq_id, star_level)
				if star_cfg:
					energy_percent_str = getattr(star_cfg, 'energyPercent', '0%') or '0%'
					# 解析百分比字符串 "30%" -> 0.3，安全处理空值
					try:
						energy_percent = float(str(energy_percent_str).strip('%')) / 100.0
					except (ValueError, AttributeError):
						energy_percent = 0
			
			symbol_energy = int(base_power * (1 + energy_percent))
			total_energy += symbol_energy
		
		return total_energy
	
	def getAttrs(self, card=None, force_update=False, inFront=False, inBack=False):
		"""
		获取图腾提供的属性加成
		
		Args:
			card: 卡牌对象，用于判断自然属性加成。如果为None，返回全局加成
			force_update: 是否强制重新计算
			inFront: 是否在前排（战斗中用）
			inBack: 是否在后排（战斗中用）
		
		Returns:
			tuple: (const, percent) - 固定值加成和百分比加成数组
		"""
		# 战斗中的前排/后排加成不使用缓存
		in_battle = inFront or inBack
		
		# 如果没有传入卡牌，返回缓存的全局属性
		if card is None and not in_battle:
			if self._passive_attrs is not None and not force_update:
				return self._passive_attrs
		elif card is not None and not in_battle:
			card_nature = getattr(card, 'natureType', None)
			if (card_nature is not None and self._nature_attrs is not None and
					card_nature in self._nature_attrs and not force_update):
				return self._nature_attrs[card_nature]
		
		if not (hasattr(csv, 'totem') and csv.totem and 
				hasattr(csv.totem, 'symbol') and csv.totem.symbol):
			return zeros(), zeros()
		
		const = zeros()
		percent = zeros()
		activated_symbols = self.getActivatedSymbols()
		
		# 获取卡牌的第一自然属性（如果传入了卡牌）
		card_nature = None
		if card and hasattr(card, 'natureType'):
			card_nature = card.natureType
		
		for symbol_id in activated_symbols:
			if symbol_id not in csv.totem.symbol:
				continue
			
			cfg = csv.totem.symbol[symbol_id]
			# totem_star: 0=未升星, 1-5=已升星
			star_level = (self.totem_star or {}).get(symbol_id, 0)
			
			# 计算星级加成百分比（star_level > 0 时才有加成，与前端逻辑一致）
			attr_percent_1 = 0
			attr_percent_2 = 0
			if star_level > 0:
				star_seq_id = self._getStarSeqId(cfg)
				star_cfg = self._getStarConfig(star_seq_id, star_level)
				if star_cfg:
					# 解析 "40%" -> 0.4，安全处理空值或非字符串
					ap1_str = getattr(star_cfg, 'attrPercent', '0%') or '0%'
					ap2_str = getattr(star_cfg, 'attrPercent2', '0%') or '0%'
					try:
						attr_percent_1 = float(str(ap1_str).strip('%')) / 100.0
						attr_percent_2 = float(str(ap2_str).strip('%')) / 100.0
					except (ValueError, AttributeError):
						attr_percent_1 = 0
						attr_percent_2 = 0
			
			# 属性1（全局加成）
			attr_type_1 = getattr(cfg, 'attrType1', 0)
			if attr_type_1 > 0:
				attr_num_1 = getattr(cfg, 'attrNum1', 0)
				if attr_num_1:
					# 使用 str2num_t 处理数值（返回 (固定值, 百分比)）
					c, p = str2num_t(attr_num_1)
					# 应用星级加成（与前端一致：固定值用attrPercent，百分比用attrPercent2）
					if star_level > 0:
						c = c * (1 + attr_percent_1)  # 固定值用 attrPercent
						p = p * (1 + attr_percent_2)  # 百分比用 attrPercent2
					const[attr_type_1] += c
					percent[attr_type_1] += p
			
			# 属性2（全局加成）
			attr_type_2 = getattr(cfg, 'attrType2', 0)
			if attr_type_2 > 0:
				attr_num_2 = getattr(cfg, 'attrNum2', 0)
				if attr_num_2:
					# 使用 str2num_t 处理数值（返回 (固定值, 百分比)）
					c, p = str2num_t(attr_num_2)
					# 应用星级加成（与前端一致：固定值用attrPercent，百分比用attrPercent2）
					if star_level > 0:
						c = c * (1 + attr_percent_1)  # 固定值用 attrPercent
						p = p * (1 + attr_percent_2)  # 百分比用 attrPercent2
					const[attr_type_2] += c
					percent[attr_type_2] += p
			
			# 额外属性1和2（需要判断自然属性匹配）
			symbol_nature = getattr(cfg, 'nature', None)
			
			# 如果符号有自然属性要求，需要卡牌的第一自然属性匹配
			if symbol_nature and card and card_nature:
				# symbol_nature可能是单个数字或列表
				if isinstance(symbol_nature, (list, tuple)):
					nature_match = card_nature in symbol_nature
				else:
					nature_match = (card_nature == symbol_nature)
				
				# 检查卡牌的第一自然属性是否匹配
				if nature_match:
					# 额外属性1
					extra_attr_type_1 = getattr(cfg, 'extraAttrsType1', 0)
					if extra_attr_type_1 > 0:
						extra_attr_num_1 = getattr(cfg, 'extraAttrNum1', 0)
						if extra_attr_num_1:
							c, p = str2num_t(extra_attr_num_1)
							const[extra_attr_type_1] += c
							percent[extra_attr_type_1] += p
					
					# 额外属性2
					extra_attr_type_2 = getattr(cfg, 'extraAttrsType2', 0)
					if extra_attr_type_2 > 0:
						extra_attr_num_2 = getattr(cfg, 'extraAttrNum2', 0)
						if extra_attr_num_2:
							c, p = str2num_t(extra_attr_num_2)
							const[extra_attr_type_2] += c
							percent[extra_attr_type_2] += p
			elif not symbol_nature:
				# 如果符号没有自然属性要求，额外属性对所有精灵生效
				# 额外属性1
				extra_attr_type_1 = getattr(cfg, 'extraAttrsType1', 0)
				if extra_attr_type_1 > 0:
					extra_attr_num_1 = getattr(cfg, 'extraAttrNum1', 0)
					if extra_attr_num_1:
						c, p = str2num_t(extra_attr_num_1)
						const[extra_attr_type_1] += c
						percent[extra_attr_type_1] += p
				
				# 额外属性2
				extra_attr_type_2 = getattr(cfg, 'extraAttrsType2', 0)
				if extra_attr_type_2 > 0:
					extra_attr_num_2 = getattr(cfg, 'extraAttrNum2', 0)
					if extra_attr_num_2:
						c, p = str2num_t(extra_attr_num_2)
						const[extra_attr_type_2] += c
						percent[extra_attr_type_2] += p
		
		# 添加能量阶段加成
		energy_const, energy_percent = self.getEnergyAttrs(card, inFront, inBack)
		const += energy_const
		percent += energy_percent
		
		# 只有不在战斗中时才缓存（战斗中的前排/后排加成不缓存）
		if not in_battle:
			if card is None:
				self._passive_attrs = (const, percent)
			elif card_nature is not None:
				if self._nature_attrs is None:
					self._nature_attrs = {}
				self._nature_attrs[card_nature] = (const, percent)
		
		return const, percent
	
	def _getGroupEnergy(self, group_type):
		"""
		计算指定组的激活能量
		
		Args:
			group_type: 组类型（symbolGroupType）
		
		Returns:
			float: 该组的激活能量
		"""
		if not hasattr(csv.totem, 'symbol') or not csv.totem.symbol:
			return 0
		
		group_energy = 0
		activated_symbols = self.getActivatedSymbols()
		
		for symbol_id in activated_symbols:
			if symbol_id not in csv.totem.symbol:
				continue
			cfg = csv.totem.symbol[symbol_id]
			# 只计算属于该组的秘符
			if getattr(cfg, 'symbolGroupType', 0) != group_type:
				continue
			
			base_power = getattr(cfg, 'power', 0)
			# 计算星级能量加成
			star_level = (self.totem_star or {}).get(symbol_id, 0)
			energy_percent = 0
			if star_level > 0:
				star_seq_id = self._getStarSeqId(cfg)
				star_cfg = self._getStarConfig(star_seq_id, star_level)
				if star_cfg:
					energy_percent_str = getattr(star_cfg, 'energyPercent', '0%') or '0%'
					try:
						energy_percent = float(str(energy_percent_str).strip('%')) / 100.0
					except (ValueError, AttributeError):
						energy_percent = 0
			
			group_energy += base_power * (1 + energy_percent)
		
		return group_energy
	
	def getEnergyAttrs(self, card=None, inFront=False, inBack=False):
		"""
		获取能量阶段提供的属性加成
		
		与前端逻辑一致：按组分别计算能量，每组能量只与该组的能量阶段配置比较
		
		Args:
			card: 卡牌对象，用于判断加成类型
			inFront: 是否在前排（战斗中用）
			inBack: 是否在后排（战斗中用）
		
		Returns:
			tuple: (const, percent) - 固定值加成和百分比加成数组
		"""
		# 检查 CSV 是否存在
		if not hasattr(csv, 'totem'):
			return zeros(), zeros()
		if not csv.totem:
			return zeros(), zeros()
		if not hasattr(csv.totem, 'energy'):
			return zeros(), zeros()
		if not csv.totem.energy:
			return zeros(), zeros()
		
		const = zeros()
		percent = zeros()
		
		try:
			energy_csv = csv.totem.energy
			if not energy_csv or not hasattr(energy_csv, '__iter__'):
				return zeros(), zeros()
			
			# 收集所有组类型
			group_types = set()
			for energy_id in energy_csv:
				energy_cfg = energy_csv[energy_id]
				if energy_cfg:
					group_type = getattr(energy_cfg, 'symbolGroupType', 0)
					if group_type > 0:
						group_types.add(group_type)
			
			# 计算每个组的能量
			group_energies = {}
			for group_type in group_types:
				group_energies[group_type] = self._getGroupEnergy(group_type)
			
			# 遍历所有能量阶段配置，按组匹配
			for energy_id in energy_csv:
				energy_cfg = energy_csv[energy_id]
				if not energy_cfg:
					continue
				
				# 获取该配置属于哪个组
				group_type = getattr(energy_cfg, 'symbolGroupType', 0)
				if group_type <= 0:
					continue
				
				# 获取该组的能量
				group_energy = group_energies.get(group_type, 0)
				
				# 检查该组能量是否达到要求
				power_num = getattr(energy_cfg, 'powerNum', 0)
				if group_energy < power_num:
					continue
				
				# 检查是否是战斗中加成（addType）
				# addType: 1=战前加成（前排）, 2=战中加成（后排）, 3=全局加成
				add_type_1 = getattr(energy_cfg, 'addType1', 0)
				add_type_2 = getattr(energy_cfg, 'addType2', 0)
				
				# 属性1：根据 addType 判断是否应用
				attr_type_1 = getattr(energy_cfg, 'attrType1', 0)
				if attr_type_1 > 0:
					should_apply_1 = False
					if add_type_1 == 3:  # 全局加成
						should_apply_1 = True
					elif add_type_1 == 1 and inFront:  # 前排加成
						should_apply_1 = True
					elif add_type_1 == 2 and inBack:  # 后排加成
						should_apply_1 = True
					
					if should_apply_1:
						attr_num_1 = getattr(energy_cfg, 'attrNum1', 0)
						if attr_num_1:
							c, p = str2num_t(attr_num_1)
							const[attr_type_1] += c
							percent[attr_type_1] += p
				
				# 属性2：根据 addType 判断是否应用
				attr_type_2 = getattr(energy_cfg, 'attrType2', 0)
				if attr_type_2 > 0:
					should_apply_2 = False
					if add_type_2 == 3:  # 全局加成
						should_apply_2 = True
					elif add_type_2 == 1 and inFront:  # 前排加成
						should_apply_2 = True
					elif add_type_2 == 2 and inBack:  # 后排加成
						should_apply_2 = True
					
					if should_apply_2:
						attr_num_2 = getattr(energy_cfg, 'attrNum2', 0)
						if attr_num_2:
							c, p = str2num_t(attr_num_2)
							const[attr_type_2] += c
							percent[attr_type_2] += p
		except Exception as e:
			# 如果出错，返回空数组，不影响其他属性计算
			return zeros(), zeros()
		
		return const, percent
	
	def clearAttrsCache(self):
		"""清除属性缓存"""
		self._passive_attrs = None
		self._nature_attrs = None
	
	def updateAllCardsAttrs(self):
		"""更新所有卡牌属性（图腾镶嵌变化后调用）"""
		try:
			# 清除图腾属性缓存
			self.clearAttrsCache()
			
			# 更新所有卡牌属性和战力
			from game.object.game.card import ObjectCard
			for cardID in self.game.role.cards:
				card = self.game.cards.getCard(cardID)
				if card:
					if getattr(card, '_attrs', None) is None or getattr(card, '_attrs2', None) is None:
						card.onUpdateAttrs()
						continue
					try:
						const, percent = self.getAttrs(card, force_update=False)
						card.calc.const.set('totem', const)
						card.calc.percent.set('totem', percent)
						attrs = card.calc.evaluation()
						card._attrs, card._attrs2 = ObjectCard.splitAttrs(attrs)
						if getattr(card, '_display', False):
							card.db_attrs = card._attrs
						fighting_point = ObjectCard.calcFightingPoint(card, attrs)
						card._setFightingPoint(fighting_point)
					except Exception:
						card.onUpdateAttrs()
		except Exception as e:
			from framework.log import logger
			logger.error('[Totem updateAllCardsAttrs] 更新失败: %s', str(e))
	
	def getMaxStarLevel(self, symbol_id):
		"""
		获取秘符的最大星级
		
		Args:
			symbol_id: 秘符ID
		
		Returns:
			int: 最大星级，如果没有升星配置则返回0
		"""
		if symbol_id not in csv.totem.symbol:
			return 0
		
		cfg = csv.totem.symbol[symbol_id]
		star_seq_id = self._getStarSeqId(cfg)
		
		# csv.totem.star 结构是 {ID: cfg}，需要按 starSeqID 筛选并找最大 starLevel
		# CSV 对象不支持 .iteritems()，需要先遍历 key 再取值
		max_level = 0
		if hasattr(csv.totem, 'star') and csv.totem.star:
			for star_id in csv.totem.star:
				star_cfg = csv.totem.star[star_id]
				cfg_star_seq_id = getattr(star_cfg, 'starSeqID', 101)
				if not cfg_star_seq_id:
					cfg_star_seq_id = 101
				
				if int(cfg_star_seq_id) == star_seq_id:
					cfg_star_level = getattr(star_cfg, 'starLevel', 1)
					if not cfg_star_level:
						cfg_star_level = 1
					cfg_star_level = int(cfg_star_level)
					if cfg_star_level > max_level:
						max_level = cfg_star_level
		
		return max_level
	
	def canUpgradeStar(self, symbol_id):
		"""
		检查秘符是否可以升星
		
		升星条件：总能量 >= 850 (totemStarUnlockNeedEnergy)
		
		Args:
			symbol_id: 秘符ID
		
		Returns:
			bool: 是否可以升星
		"""
		if symbol_id not in csv.totem.symbol:
			return False
		
		# 检查能量是否达到升星解锁条件（850）
		unlock_energy = 850
		if hasattr(csv, 'common_config') and csv.common_config and 196 in csv.common_config:
			unlock_energy = getattr(csv.common_config[196], 'value', 850)
		
		total_energy = self.getTotalEnergy()
		if total_energy < unlock_energy:
			return False
		
		# 检查是否已激活
		if not self.isSymbolActive(symbol_id):
			return False
		
		# 获取当前星级（0=未升星，1-5=已升星）
		current_star = (self.totem_star or {}).get(symbol_id, 0)
		
		# 获取最大星级（CSV 中最大的 starLevel，通常是 5）
		max_star = self.getMaxStarLevel(symbol_id)
		
		# 如果没有升星配置或已达最大星级
		if max_star <= 0 or current_star >= max_star:
			return False
		
		return True
	
	def upgradeStar(self, symbol_id):
		"""
		升星秘符（清空旧镶嵌，星级+1）
		
		totem_star 值范围：
		- 升星前：totem_star[symbol_id] = 0（未升星）或 1-4
		- 升星后：totem_star[symbol_id] = 1-5
		
		Args:
			symbol_id: 秘符ID
		
		Returns:
			int: 新的星级（1-5，对应 CSV starLevel）
		"""
		if not self.canUpgradeStar(symbol_id):
			raise ClientError('cannot upgrade star')
		
		# 获取当前星级
		totem_star_db = self._db['totem_star']
		totem_insetted_db = self._db['totem_insetted']
		current_star = totem_star_db.get(symbol_id, 0)
		
		# 星级+1（0→1, 1→2, ..., 4→5）
		new_star = current_star + 1
		max_star = self.getMaxStarLevel(symbol_id)
		
		# 逐个更新 key（避免同步问题）
		totem_star_db[symbol_id] = new_star
		
		# 如果未满星，清空镶嵌让玩家继续升星
		if new_star < max_star:
			totem_insetted_db[symbol_id] = {}
		
		# 清除属性缓存
		self.clearAttrsCache()
		
		return new_star
	
	def inset(self, inset_data):
		"""
		镶嵌图腾（支持升星）
		
		前端期望的 totem_star 值：
		- nil/不存在：未激活
		- 0：已激活但未升星（第一次镶嵌满，能量>=850时设置）
		- 1-N：已升星（N = CSV 中该 starSeqID 的最大 starLevel，通常是 5）
		
		升星流程：
		1. 首次镶嵌满 + 能量>=850：totem_star=0，清空镶嵌（可重新镶嵌来升星）
		2. 重新镶嵌满：totem_star+1，若未满星则清空镶嵌
		3. 升到满星：totem_star=maxStar，不清空镶嵌（不可再镶嵌）
		
		Args:
			inset_data: {symbolId: [slotIndex1, slotIndex2, ...], ...}
		
		Returns:
			list: 激活的秘符ID列表
		"""
		from game.object.game.gain import ObjectCostAux
		
		if not (hasattr(csv, 'totem') and csv.totem and 
				hasattr(csv.totem, 'symbol') and csv.totem.symbol):
			raise ClientError('totem csv not loaded')
		
		activated_symbols = []
		cost_items = {}
		
		# 确保数据已初始化
		if not self._db.get('totem_insetted'):
			self._db['totem_insetted'] = {}
		if not self._db.get('totem_star'):
			self._db['totem_star'] = {}
		
		# 验证并收集消耗
		for symbol_id, slot_indices in inset_data.iteritems():
			if symbol_id not in csv.totem.symbol:
				raise ClientError('invalid symbol_id')
			
			cfg = csv.totem.symbol[symbol_id]
			totem_group = cfg.totemGroup1
			max_star = self.getMaxStarLevel(symbol_id)
			
			# 获取当前星级状态
			totem_star_dict = self._db.get('totem_star') or {}
			current_star = totem_star_dict.get(symbol_id, None)  # None=未激活, 0-N=已激活
			
			# 检查是否已满星（满星后不能再镶嵌）
			if current_star is not None and current_star >= max_star:
				raise ClientError('symbol already max star')
			
			# 获取当前镶嵌状态
			insetted = self._db['totem_insetted'].get(symbol_id, {})
			
			for slot_idx in slot_indices:
				if slot_idx < 1 or slot_idx > len(totem_group):
					raise ClientError('invalid slot index')
				if slot_idx in insetted:
					raise ClientError('slot already insetted')
				item_csv_id = totem_group[slot_idx - 1]
				cost_items[item_csv_id] = cost_items.get(item_csv_id, 0) + 1
		
		# 扣除道具
		if cost_items:
			cost = ObjectCostAux(self.game, cost_items)
			if not cost.isEnough():
				raise ClientError('cost not enough')
			cost.cost(src='totem_inset')
		
		# 准备更新的数据（统一处理，最后一次性赋值触发数据库同步）
		new_totem_insetted = dict(self._db.get('totem_insetted') or {})
		new_totem_star = dict(self._db.get('totem_star') or {})
		
		# 第一步：先执行所有秘符的镶嵌操作，收集所有填满槽位的秘符
		fully_insetted_symbols = []  # 记录本次填满的秘符
		for symbol_id, slot_indices in inset_data.iteritems():
			cfg = csv.totem.symbol[symbol_id]
			totem_group = cfg.totemGroup1
			
			# 确保该秘符有镶嵌数据结构
			if symbol_id not in new_totem_insetted:
				new_totem_insetted[symbol_id] = {}
			
			# 执行镶嵌
			for slot_idx in slot_indices:
				item_csv_id = totem_group[slot_idx - 1]
				new_totem_insetted[symbol_id][slot_idx] = item_csv_id
			
			# 检查是否填满槽位
			is_fully_insetted = True
			for i in range(len(totem_group)):
				if (i + 1) not in new_totem_insetted.get(symbol_id, {}):
					is_fully_insetted = False
					break
			
			if is_fully_insetted:
				activated_symbols.append(symbol_id)
				fully_insetted_symbols.append(symbol_id)
		
		# 第二步：所有镶嵌完成后，处理升星
		# 升星条件：总能量 >= 850 (totemStarUnlockNeedEnergy)
		if fully_insetted_symbols:
			# 计算镶嵌后的总能量（使用临时数据）
			total_energy = self.getTotalEnergy(totem_insetted=new_totem_insetted, totem_star=new_totem_star)
			
			# 获取升星解锁能量（默认 850）
			unlock_energy = 850
			if hasattr(csv, 'common_config') and csv.common_config and 196 in csv.common_config:
				unlock_energy = getattr(csv.common_config[196], 'value', 850)
			
			# 只有能量 >= 850 才能升星
			if total_energy >= unlock_energy:
				# 处理本次镶嵌满的秘符
				for symbol_id in fully_insetted_symbols:
					max_star = self.getMaxStarLevel(symbol_id)
					current_star = new_totem_star.get(symbol_id, None)  # None=未激活
					
					if current_star is None:
						# 首次激活：设置 totem_star = 0
						new_totem_star[symbol_id] = 0
						# 清空镶嵌数据，让玩家可以重新镶嵌来升星
						new_totem_insetted[symbol_id] = {}
					elif current_star < max_star:
						# 升星：星级+1
						new_star = current_star + 1
						new_totem_star[symbol_id] = new_star
						# 如果未满星，清空镶嵌让玩家继续升星
						if new_star < max_star:
							new_totem_insetted[symbol_id] = {}
						# 满星则保留镶嵌数据（前端会显示完整图案）
				
				# 重点修复：检查所有已镶嵌满但还没有 totem_star 的秘符（之前能量不足时镶嵌的）
				for symbol_id in list(new_totem_insetted.keys()):
					# 跳过已经处理过的秘符
					if symbol_id in fully_insetted_symbols:
						continue
					# 只处理没有 totem_star 的秘符
					if symbol_id in new_totem_star:
						continue
					# 检查是否镶嵌满
					if symbol_id not in csv.totem.symbol:
						continue
					cfg = csv.totem.symbol[symbol_id]
					totem_group = cfg.totemGroup1
					insetted = new_totem_insetted.get(symbol_id, {})
					is_fully_insetted = True
					for i in range(len(totem_group)):
						if (i + 1) not in insetted:
							is_fully_insetted = False
							break
					
					if is_fully_insetted:
						# 首次激活：设置 totem_star = 0
						new_totem_star[symbol_id] = 0
						# 清空镶嵌数据，让玩家可以重新镶嵌来升星
						new_totem_insetted[symbol_id] = {}
		
		# 逐个更新 key，而不是一次性替换整个字典
		# 这样确保每个 key 的变化都被标记为"更新"（_setS）而不是"新创建"（_newS）
		# 避免同步数据格式与前端期望不一致
		totem_insetted_db = self._db['totem_insetted']
		totem_star_db = self._db['totem_star']
		
		# 更新 totem_insetted
		for symbol_id, insetted_data in new_totem_insetted.iteritems():
			totem_insetted_db[symbol_id] = insetted_data
		
		# 更新 totem_star
		for symbol_id, star_level in new_totem_star.iteritems():
			totem_star_db[symbol_id] = star_level
		
		self.clearAttrsCache()
		
		return activated_symbols
	
	def decompose(self, decompose_items):
		"""
		分解图腾道具
		
		Args:
			decompose_items: {itemCsvId: count, ...}
		
		Returns:
			ObjectGainAux: 返还的资源
		"""
		from game.object.game.gain import ObjectCostAux, ObjectGainAux
		
		# 验证道具
		for item_id in decompose_items.keys():
			if item_id not in csv.items:
				raise ClientError('invalid item')
			item_cfg = csv.items[item_id]
			# 检查是否有分解返还配置
			if not hasattr(item_cfg, 'specialArgsMap') or not item_cfg.specialArgsMap:
				raise ClientError('item cannot be decomposed')
			if 'decomposeReturn' not in item_cfg.specialArgsMap:
				raise ClientError('item cannot be decomposed')
		
		# 扣除道具
		cost = ObjectCostAux(self.game, decompose_items)
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='totem_decompose')
		
		# 计算返还
		eff = ObjectGainAux(self.game, {})
		for item_id, count in decompose_items.iteritems():
			item_cfg = csv.items[item_id]
			decompose_return = item_cfg.specialArgsMap.get('decomposeReturn', {})
			for ret_item_id, ret_count in decompose_return.iteritems():
				eff += ObjectGainAux(self.game, {ret_item_id: ret_count * count})
		
		return eff
