#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

奇异陨石系统对象
'''

from framework import nowtime_t
from framework.csv import csv
from framework.log import logger
from framework.object import ObjectBase
from game.object.game.calculator import zeros

class ObjectMeteorite(ObjectBase):
	"""奇异陨石对象"""
	
	@classmethod
	def classInit(cls):
		"""初始化陨石配置"""
		pass
	
	def set(self):
		"""初始化陨石对象"""
		# 确保 meteorites 字段存在
		if not hasattr(self.game.role, 'meteorites') or self.game.role.meteorites is None:
			self.game.role.meteorites = {}
		
		self._meteorites = self.game.role.meteorites  # {index: {card, helditems, level, card_cd, helditem_cd}}
		self._attrs_dirty = True
		self._attrs_cache_dirty = True
		return ObjectBase.set(self)
	
	def init(self):
		"""登录时初始化"""
		# 初始化数据结构
		if self._meteorites is None:
			self.game.role.meteorites = {}
			self._meteorites = self.game.role.meteorites
		
		# 修复老数据：确保所有陨石数据都有必需的字段
		modified = False
		for index, data in self._meteorites.items():
			if 'helditem_cd' not in data:
				data['helditem_cd'] = {}
				modified = True
			if 'card_cd' not in data:
				data['card_cd'] = 0
				modified = True
			if 'helditems' not in data:
				data['helditems'] = {}
				modified = True
			if 'card' not in data:
				data['card'] = None
				modified = True
			if 'level' not in data:
				data['level'] = 0
				modified = True
		
		if modified:
			# 强制触发保存（自己赋值给自己）
			self.game.role.meteorites = self.game.role.meteorites
			self._attrs_dirty = True
			self._attrs_cache_dirty = True
		
		# 验证 helditems 和 card 的数据一致性（反向检查）
		self._validateHeldItems()
		self._validateCards()
		
		return ObjectBase.init(self)
	
	def _validateHeldItems(self):
		"""验证陨石中 helditems 的数据一致性（反向检查）"""
		if not self._meteorites:
			return
		
		fixed = False
		
		for index, meteor_data in self._meteorites.items():
			helditems = meteor_data.get('helditems', {})
			
			# ⚠️ 不要跳过空的helditems，因为可能是已经被held_item清理过的损坏数据
			# 需要检查并确保数据结构完整
			
			# 重建有效的 helditems 字典（清理所有无效键，统一使用整数键）
			valid_helditems = {}
			has_invalid = False
			
			# 如果helditems为空或None，标记为需要修复
			if not helditems:
				meteor_data['helditems'] = {}
				fixed = True
				logger.info('[Meteorite] meteorite %d helditems empty, reset to {}', index)
				continue
			
			for pos in list(helditems.keys()):
				# 判断键类型并转换为整数
				pos_int = None
				
				# 情况1：整数键（标准格式）
				if isinstance(pos, int):
					if pos > 0:
						pos_int = pos
					else:
						logger.warning('[Meteorite] meteorite %d pos %d invalid (<=0), skipping', index, pos)
						has_invalid = True
						continue
				
				# 情况2：字符串键（旧数据，需要转换为整数）
				elif isinstance(pos, (str, unicode)):
					try:
						pos_int = int(pos)
						if pos_int > 0:
							has_invalid = True  # 需要转换
						else:
							logger.warning('[Meteorite] meteorite %d pos "%s" invalid (<=0), skipping', index, pos)
							has_invalid = True
							continue
					except (ValueError, TypeError):
						logger.warning('[Meteorite] meteorite %d pos "%s" not numeric, skipping', index, pos)
						has_invalid = True
						continue
				
				# 情况3：其他类型（损坏的数据，如 <interface {} Value>）
				else:
					logger.warning('[Meteorite] meteorite %d pos type=%s repr=%s invalid, skipping', 
								 index, type(pos).__name__, repr(pos)[:50])
					has_invalid = True
					continue
				
				# 获取携带物ID
				helditem_id = helditems.get(pos)
				if not helditem_id:
					logger.warning('[Meteorite] meteorite %d pos %d empty held_item_id, skipping', index, pos_int)
					has_invalid = True
					continue
				
				# ✅ 验证携带物对象是否真实存在（关键修复）
				helditem_obj = self.game.heldItems.getHeldItem(helditem_id)
				if not helditem_obj:
					logger.warning('[Meteorite] meteorite %d pos %d held_item %s not exist (deleted/exist_flag=False), removing', 
								 index, pos_int, helditem_id)
					has_invalid = True
					continue
				
				# 保存到新字典（使用整数键，前端Lua期望整数索引）
				valid_helditems[pos_int] = helditem_id
			
			# 如果有无效数据或需要转换，替换整个字典
			if has_invalid or len(valid_helditems) != len(helditems):
				meteor_data['helditems'] = valid_helditems
				fixed = True
				logger.info('[Meteorite] meteorite %d helditems rebuilt: %d -> %d items', 
						   index, len(helditems), len(valid_helditems))
		
		# 如果修复了数据，触发保存
		if fixed:
			self.game.role.meteorites = self.game.role.meteorites
			self._attrs_dirty = True
			self._attrs_cache_dirty = True
			logger.info('[Meteorite] helditems data validated and fixed')
	
	def _validateCards(self):
		"""验证陨石中 card 的数据一致性（基础检查）"""
		if not self._meteorites:
			return
		
		fixed = False
		
		for index, meteor_data in self._meteorites.items():
			card_id = meteor_data.get('card')
			
			# 只检查明显的错误数据（空ID、无效ObjectId等）
			# 卡牌对象的一致性由 card._fixCorrupted() 在加载时检查
			# 这里不依赖 cards 对象，因为可能还没加载
			
			# 检查是否是有效的 ObjectId 格式（如果不是 None）
			if card_id is not None:
				try:
					# 尝试转换为字符串，如果是 ObjectId 应该能成功
					str(card_id)
				except Exception:
					logger.warning('[Meteorite] card %s in meteorite %d invalid ObjectId, removing', card_id, index)
					meteor_data['card'] = None
					fixed = True
		
		# 如果修复了数据，触发保存
		if fixed:
			self.game.role.meteorites = self.game.role.meteorites
			self._attrs_dirty = True
			self._attrs_cache_dirty = True
			logger.info('[Meteorite] cards data validated and fixed')

	def _markDirty(self):
		self._attrs_dirty = True
		self._attrs_cache_dirty = True
	
	def _getMeteorData(self, index):
		"""获取陨石数据"""
		# 确保 _meteorites 已初始化
		if not hasattr(self, '_meteorites') or self._meteorites is None:
			if not hasattr(self.game.role, 'meteorites') or self.game.role.meteorites is None:
				self.game.role.meteorites = {}
			self._meteorites = self.game.role.meteorites
		
		if index not in self._meteorites:
			self._meteorites[index] = {
				'card': None,  # 卡牌ID
				'helditems': {},  # 持有物 {pos: heldItemID} - 字典格式
				'level': 0,  # 陨石等级
				'card_cd': 0,  # 卡牌CD结束时间
				'helditem_cd': {}  # 持有物CD {pos: cd_end_time} - 字典格式
			}
			# 强制触发保存
			self.game.role.meteorites = self.game.role.meteorites
		return self._meteorites[index]
	
	def getMeteorData(self, index):
		"""公开方法：获取陨石数据（不初始化）"""
		return self._meteorites.get(index) if self._meteorites else None
	
	def getCard(self, index):
		"""获取陨石守护的卡牌"""
		data = self._getMeteorData(index)
		cardID = data.get('card')
		if cardID:
			return self.game.cards.getCard(cardID)
		return None
	
	def setCard(self, index, cardID):
		"""设置陨石守护卡牌"""
		data = self._getMeteorData(index)
		
		# 如果之前有卡牌，先卸下
		oldCardID = data.get('card')
		if oldCardID:
			oldCard = self.game.cards.getCard(oldCardID)
			if oldCard:
				oldCard.meteorite_index = 0
		
		# 设置新卡牌
		data['card'] = cardID
		
		# 设置卡牌的陨石索引
		card = self.game.cards.getCard(cardID)
		if card:
			card.meteorite_index = index
		
		# 设置CD
		meteorCfg = csv.meteorite.base[index]
		data['card_cd'] = nowtime_t() + meteorCfg.cardCD
		
		# 强制触发保存
		self.game.role.meteorites = self.game.role.meteorites
		
		logger.info('[Meteorite] 玩家%s 设置陨石%d守护卡牌 %s', self.game.role.id, index, cardID)
		
		# 陨石变化，标记刷新（退出界面统一处理）
		self._markDirty()
	
	def unsetCard(self, index):
		"""卸下陨石守护卡牌"""
		data = self._getMeteorData(index)
		cardID = data.get('card')
		
		if cardID:
			card = self.game.cards.getCard(cardID)
			if card:
				card.meteorite_index = 0
			
			data['card'] = None
			
			# 强制触发保存
			self.game.role.meteorites = self.game.role.meteorites
			
			logger.info('[Meteorite] 玩家%s 卸下陨石%d守护卡牌', self.game.role.id, index)
			
			# 陨石变化，标记刷新（退出界面统一处理）
			self._markDirty()
	
	def canSetCard(self, index):
		"""检查是否可以设置卡牌（CD是否结束）"""
		data = self._getMeteorData(index)
		cardCD = data.get('card_cd', 0)
		return nowtime_t() >= cardCD
	
	def getHeldItem(self, index, pos):
		"""获取陨石上的持有物"""
		data = self._getMeteorData(index)
		helditems = data.get('helditems', {})
		pos = int(pos)
		
		# 支持整数和字符串两种键类型（MongoDB可能存储为字符串）
		if pos in helditems:
			heldItemID = helditems[pos]
		elif str(pos) in helditems:
			heldItemID = helditems[str(pos)]
		else:
			return None
		
		if heldItemID:
			return self.game.heldItems.getHeldItem(heldItemID)
		return None
	
	def setHeldItem(self, index, pos, heldItemID):
		"""设置陨石上的持有物"""
		data = self._getMeteorData(index)
		pos = int(pos)  # 转为整数
		
		# 如果之前有持有物，先卸下
		helditems = data.get('helditems', {})
		
		# 支持整数和字符串两种键类型读取（兼容旧数据）
		oldHeldItemID = None
		if pos in helditems:
			oldHeldItemID = helditems[pos]
		elif str(pos) in helditems:
			oldHeldItemID = helditems[str(pos)]
			del helditems[str(pos)]  # 删除字符串键
		
		if oldHeldItemID:
			oldHeldItem = self.game.heldItems.getHeldItem(oldHeldItemID)
			if oldHeldItem:
				oldHeldItem.meteorite_index = 0
				oldHeldItem.meteorite_pos = 0
		
		# 设置新持有物（使用整数键，前端Lua期望整数索引）
		helditems[pos] = heldItemID
		data['helditems'] = helditems
		
		# 设置持有物的陨石位置
		heldItem = self.game.heldItems.getHeldItem(heldItemID)
		if heldItem:
			heldItem.meteorite_index = index
			heldItem.meteorite_pos = pos
		
		# 设置CD（使用整数键，前端Lua期望整数索引）
		meteorCfg = csv.meteorite.base[index]
		helditemCDs = meteorCfg.helditemCDs
		if helditemCDs and pos in helditemCDs:
			helditem_cd = data.get('helditem_cd', {})
			helditem_cd[pos] = nowtime_t() + helditemCDs[pos]
			data['helditem_cd'] = helditem_cd
		
		# 强制触发保存
		self.game.role.meteorites = self.game.role.meteorites
		
		logger.info('[Meteorite] 玩家%s 设置陨石%d位置%d持有物 %s', self.game.role.id, index, pos, heldItemID)
		
		# 陨石变化，标记刷新（退出界面统一处理）
		self._markDirty()
	
	def unsetHeldItem(self, index, pos):
		"""卸下陨石上的持有物"""
		data = self._getMeteorData(index)
		helditems = data.get('helditems', {})
		pos = int(pos)  # 转为整数
		
		# 支持整数和字符串两种键类型读取（兼容旧数据）
		heldItemID = None
		if pos in helditems:
			heldItemID = helditems.pop(pos, None)
		elif str(pos) in helditems:
			heldItemID = helditems.pop(str(pos), None)
		
		if heldItemID:
			heldItem = self.game.heldItems.getHeldItem(heldItemID)
			if heldItem:
				heldItem.meteorite_index = 0
				heldItem.meteorite_pos = 0
				logger.info('[Meteorite] 玩家%s 卸下陨石%d位置%d持有物 %s，清理meteorite_index', 
						   self.game.role.id, index, pos, heldItemID)
			
			data['helditems'] = helditems
			
			# 强制触发保存
			self.game.role.meteorites = self.game.role.meteorites
			
			logger.info('[Meteorite] 玩家%s 卸下陨石%d位置%d持有物', self.game.role.id, index, pos)
			
			# 陨石变化，标记刷新（退出界面统一处理）
			self._markDirty()
	
	def canSetHeldItem(self, index, pos):
		"""检查是否可以设置持有物（CD是否结束）"""
		data = self._getMeteorData(index)
		helditem_cd = data.get('helditem_cd', {})
		pos = int(pos)
		
		# 先尝试整数键（标准方式）
		if pos in helditem_cd:
			return nowtime_t() >= helditem_cd[pos]
		# 兼容旧数据的字符串键
		elif str(pos) in helditem_cd:
			return nowtime_t() >= helditem_cd[str(pos)]
		return True
	
	def getLevel(self, index):
		"""获取陨石等级"""
		data = self._getMeteorData(index)
		return data.get('level', 0)
	
	def addLevel(self, index, count):
		"""增加陨石等级"""
		data = self._getMeteorData(index)
		oldLevel = data.get('level', 0)
		newLevel = oldLevel + count
		
		# 检查最大等级（从csv.meteorite.level数组获取）
		maxLevel = len(csv.meteorite.level) - 1
		if newLevel > maxLevel:
			newLevel = maxLevel
		
		data['level'] = newLevel
		
		# 强制触发保存
		self.game.role.meteorites = self.game.role.meteorites
		
		logger.info('[Meteorite] 玩家%s 陨石%d 等级 %d -> %d', self.game.role.id, index, oldLevel, newLevel)
		
		# 注意：战力更新延迟到 MeteoriteEnd 接口，避免连续强化时卡顿
		# self._updateAllCardsAttrs()
		self._markDirty()
		
		return newLevel
	
	def refreshAll(self):
		"""刷新所有陨石的CD状态"""
		# 这个方法在玩家关闭陨石界面时调用
		# 主要用于清理过期的CD数据
		nowTime = nowtime_t()
		
		for index, data in (self._meteorites or {}).items():
			# 清理过期的卡牌CD
			if data.get('card_cd', 0) > 0 and data['card_cd'] <= nowTime:
				data['card_cd'] = 0
			
			# 清理过期的持有物CD
			helditem_cd = data.get('helditem_cd', {})
			expiredPos = [pos for pos, cd in helditem_cd.items() if cd <= nowTime]
			for pos in expiredPos:
				helditem_cd.pop(pos, None)
			
			if expiredPos:
				data['helditem_cd'] = helditem_cd
		
		# 强制触发保存
		if self._meteorites:
			self.game.role.meteorites = self.game.role.meteorites
	
	def getMeteoriteAttrs(self):
		"""获取所有陨石提供的属性加成
		
		Returns:
			tuple: (const_attrs, percent_attrs) - 常量属性和百分比属性
		"""
		return self._getCachedMeteoriteAttrs()

	def _getCachedMeteoriteAttrs(self):
		if not self._meteorites:
			return zeros(), zeros()

		if getattr(self, '_attrs_cache_dirty', True) or not hasattr(self, '_attrs_cache'):
			const_attrs = zeros()
			percent_attrs = zeros()
			for index, meteor_data in self._meteorites.items():
				try:
					single_const, single_percent = self._getSingleMeteoriteAttrs(index, meteor_data)
					const_attrs += single_const
					percent_attrs += single_percent
				except Exception as e:
					logger.warning('Failed to calculate meteorite %d attributes: %s', index, e)
					continue
			self._attrs_cache = (const_attrs, percent_attrs)
			self._attrs_cache_dirty = False

		return self._attrs_cache
	
	def _getSingleMeteoriteAttrs(self, index, meteor_data):
		"""计算单个陨石的属性加成
		
		Args:
			index: 陨石索引
			meteor_data: 陨石数据
		
		Returns:
			tuple: (const_attrs, percent_attrs)
		"""
		const_attrs = zeros()
		percent_attrs = zeros()
		
		# 获取陨石等级
		level = meteor_data.get('level', 0)
		if level <= 0:
			return const_attrs, percent_attrs
		
		# 获取陨石配置
		if index not in csv.meteorite.base:
			return const_attrs, percent_attrs
		
		meteor_cfg = csv.meteorite.base[index]
		level_seq_id = meteor_cfg.levelSeqID
		
		# 获取等级对应的基础属性
		if level >= len(csv.meteorite.level):
			level = len(csv.meteorite.level) - 1
		
		level_cfg = csv.meteorite.level[level]
		level_attr_key = 'attr%d' % level_seq_id
		base_attrs = getattr(level_cfg, level_attr_key, {})
		
		if not base_attrs:
			return const_attrs, percent_attrs
		
		# 计算守护精灵的加成系数
		sprite_bonus = self._getSpriteBonusPercent(index, meteor_data)
		
		# 计算守护携带物的加成系数
		helditem_bonus = self._getHeldItemBonusPercent(index, meteor_data)
		
		# 总加成系数 = 1 + 精灵加成% + 携带物加成%
		total_bonus = 1.0 + sprite_bonus + helditem_bonus
		
		# 应用加成到基础属性
		for attr_id, attr_value in base_attrs.items():
			if attr_id == '__size':
				continue
			try:
				attr_id = int(attr_id)
				attr_value = float(attr_value)
				final_value = attr_value * total_bonus
				const_attrs[attr_id] += final_value
			except (ValueError, TypeError, KeyError):
				continue
		
		logger.debug('[Meteorite] index=%d, level=%d, sprite_bonus=%.2f%%, helditem_bonus=%.2f%%, total_bonus=%.2f%%',
					 index, level, sprite_bonus*100, helditem_bonus*100, total_bonus*100)
		
		return const_attrs, percent_attrs
	
	def _getSpriteBonusPercent(self, index, meteor_data):
		"""计算守护精灵的加成百分比
		
		Args:
			index: 陨石索引
			meteor_data: 陨石数据
		
		Returns:
			float: 加成百分比（如0.15表示15%）
		"""
		card_id = meteor_data.get('card')
		if not card_id:
			return 0.0
		
		card = self.game.cards.getCard(card_id)
		if not card:
			return 0.0
		
		try:
			# 获取卡牌信息
			card_csv_id = card.card_id
			advance = card.advance
			star = card.star
			
			if card_csv_id not in csv.cards:
				return 0.0
			
			card_csv = csv.cards[card_csv_id]
			unit_id = card_csv.unitID
			
			if unit_id not in csv.unit:
				return 0.0
			
			unit_csv = csv.unit[unit_id]
			rarity = unit_csv.rarity
			
			# 获取加成配置
			if rarity not in csv.meteorite.guard_effect:
				return 0.0
			
			guard_cfg = csv.meteorite.guard_effect[rarity]
			
			# 基础稀有度加成
			rarity_bonus = self._parsePercent(getattr(guard_cfg, 'rarityAttr', '0%'))
			
			# 星级加成（数组访问）
			star_attrs = getattr(guard_cfg, 'starAttrs', {})
			if star in star_attrs:
				star_bonus = self._parsePercent(star_attrs[star])
			else:
				star_bonus = 0.0
			
			# 突破加成（数组访问）
			advance_attrs = getattr(guard_cfg, 'advanceAttrs', {})
			if advance in advance_attrs:
				advance_bonus = self._parsePercent(advance_attrs[advance])
			else:
				advance_bonus = 0.0
			
			# 觉醒加成（数组访问）
			zawake_bonus = 0.0
			if hasattr(card, 'zawake_level') and card.zawake_level > 0:
				zawake_attrs = getattr(guard_cfg, 'zawakeAttrs', {})
				if card.zawake_level in zawake_attrs:
					zawake_bonus = self._parsePercent(zawake_attrs[card.zawake_level])
			
			total = rarity_bonus + star_bonus + advance_bonus + zawake_bonus
			
			logger.debug('[Meteorite] Sprite bonus: rarity=%.2f%%, star=%.2f%%, advance=%.2f%%, zawake=%.2f%%',
						 rarity_bonus*100, star_bonus*100, advance_bonus*100, zawake_bonus*100)
			
			return total
			
		except Exception as e:
			logger.warning('Failed to calculate sprite bonus for meteorite %d: %s', index, e)
			return 0.0
	
	def _getHeldItemBonusPercent(self, index, meteor_data):
		"""计算守护携带物的加成百分比
		
		Args:
			index: 陨石索引
			meteor_data: 陨石数据
		
		Returns:
			float: 加成百分比（如0.10表示10%）
		"""
		helditems = meteor_data.get('helditems', {})
		if not helditems:
			return 0.0
		
		total_bonus = 0.0
		
		# 遍历所有携带物槽位
		for pos in [1, 2]:
			# 支持整数和字符串两种键类型（MongoDB可能存储为字符串）
			if pos in helditems:
				helditem_id = helditems[pos]
			elif str(pos) in helditems:
				helditem_id = helditems[str(pos)]
			else:
				continue
			
			if not helditem_id:
				continue
			
			helditem = self.game.heldItems.getHeldItem(helditem_id)
			if not helditem:
				continue
			
			try:
				# 获取携带物信息
				held_item_csv_id = helditem.held_item_id
				level = helditem.level
				advance = helditem.advance
				
				if held_item_csv_id not in csv.held_item.items:
					continue
				
				helditem_csv = csv.held_item.items[held_item_csv_id]
				quality = helditem_csv.quality
				
				# 获取加成配置
				if quality not in csv.meteorite.helditem_effect:
					continue
				
				effect_cfg = csv.meteorite.helditem_effect[quality]
				
				# 品质加成
				rarity_bonus = self._parsePercent(getattr(effect_cfg, 'rarityAttr', '0%'))
				
				# 等级加成（阶梯式）
				level_bonus = 0.0
				level_attrs = getattr(effect_cfg, 'levelAttrs', [])
				for level_cfg in level_attrs:
					if isinstance(level_cfg, (list, tuple)) and len(level_cfg) >= 2:
						required_level = level_cfg[0]
						bonus_str = level_cfg[1]
						if level >= required_level:
							level_bonus = self._parsePercent(bonus_str)
				
				# 突破加成（数组访问）
				advance_attrs = getattr(effect_cfg, 'advanceAttrs', {})
				if advance in advance_attrs:
					advance_bonus = self._parsePercent(advance_attrs[advance])
				else:
					advance_bonus = 0.0
				
				pos_bonus = rarity_bonus + level_bonus + advance_bonus
				total_bonus += pos_bonus
				
				logger.debug('[Meteorite] HeldItem pos=%d bonus: rarity=%.2f%%, level=%.2f%%, advance=%.2f%%',
							 pos, rarity_bonus*100, level_bonus*100, advance_bonus*100)
				
			except Exception as e:
				logger.warning('Failed to calculate helditem bonus for meteorite %d pos %d: %s', index, pos, e)
				continue
		
		return total_bonus
	
	def _parsePercent(self, percent_str):
		"""解析百分比字符串（如"15%"）为浮点数（如0.15）
		
		Args:
			percent_str: 百分比字符串
		
		Returns:
			float: 百分比数值
		"""
		if not percent_str or percent_str == '0%':
			return 0.0
		
		try:
			if isinstance(percent_str, str) and percent_str.endswith('%'):
				return float(percent_str[:-1]) / 100.0
			return float(percent_str) / 100.0
		except (ValueError, TypeError):
			return 0.0
	
	def _updateAllCardsAttrs(self):
		"""陨石变化后，强制更新所有卡牌的属性和战力（参考助战系统）"""
		try:
			if not getattr(self, '_attrs_dirty', True):
				return

			self._getCachedMeteoriteAttrs()
			# 遍历所有卡牌ID
			for cardID in self.game.role.cards:
				card = self.game.cards.getCard(cardID)
				if card:
					# 触发属性更新（会重新计算属性和战力，并调用onFightingPointChange）
					card.onUpdateAttrs()
			
			self._attrs_dirty = False
			logger.info('[Meteorite] Updated all cards attributes and fighting points')
			
		except Exception as e:
			logger.error('Failed to update all cards attrs: %s', e)
