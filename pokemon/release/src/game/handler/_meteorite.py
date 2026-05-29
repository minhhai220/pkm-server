#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

奇异陨石系统
'''

from framework import nowtime_t
from framework.csv import csv, ErrDefs, ConstDefs
from framework.helper import WeightRandomObject, string2objectid
from framework.log import logger

from game import ClientError, ServerError
from game.handler.inl import effectAutoGain
from game.object import TargetDefs, FeatureDefs
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.handler import RequestHandlerTask
from game.object.game.yyhuodong import ObjectYYHuoDongFactory

from tornado.gen import coroutine


#
# 陨石刷新（退出界面时调用）
#
class MeteoriteRefresh(RequestHandlerTask):
	url = r'/game/meteorite/refresh'
	
	@coroutine
	def run(self):
		"""刷新陨石数据
		
		说明：
		- 前端退出陨石界面时调用此接口
		- 刷新所有陨石的CD状态
		- 批量更新所有卡牌战力（陨石强化时延迟更新，此处统一处理）
		"""
		# 刷新所有陨石的CD状态
		self.game.meteorite.refreshAll()
		
		# 批量更新所有卡牌战力（陨石强化延迟更新，退出界面时统一处理）
		if getattr(self.game.meteorite, '_attrs_dirty', False):
			self.game.meteorite._updateAllCardsAttrs()
		
		self.write({
			'view': {}
		})


#
# 陨石守护设置（设置卡牌或持有物）
#
class MeteoriteGuardSetup(RequestHandlerTask):
	url = r'/game/meteorite/guard/setup'
	
	@coroutine
	def run(self):
		"""设置陨石的守护卡牌或持有物
		
		参数（命名参数）:
		- meteoriteID: 陨石索引 (1-7)
		- typ: 类型 (1=设置卡牌, 2=设置持有物)
		- position: 位置（持有物位置, 1-2）
		- dbid: 卡牌或持有物的数据库ID (-1表示卸下)
		"""
		meteoriteID = self.input.get('meteoriteID', None)
		typ = self.input.get('typ', None)
		pos = self.input.get('position', None)
		dbid = self.input.get('dbid', None)
		
		if meteoriteID is None or typ is None:
			raise ClientError('meteoriteParamError')
		
		index = int(meteoriteID)
		setupType = int(typ)
		
		# 检查陨石索引有效性
		if index not in csv.meteorite.base:
			raise ClientError('invalid meteorite index')
		
		meteorCfg = csv.meteorite.base[index]
		
		# 等级要求检查
		if self.game.role.level < meteorCfg.unlockLevel:
			raise ClientError('role level not enough')
		
		# 前置陨石检查
		if meteorCfg.preID > 0:
			preMeteorData = self.game.meteorite.getMeteorData(meteorCfg.preID)
			if not preMeteorData or preMeteorData.get('level', 0) < meteorCfg.preLevel:
				raise ClientError('pre meteorite level not enough')
		
		if setupType == 1:
			# 设置守护卡牌
			if dbid is None or dbid == -1 or (isinstance(dbid, int) and dbid < 0):
				# 卸下卡牌（前端传-1表示卸下）
				self.game.meteorite.unsetCard(index)
			else:
				# dbid 已经是正确的 ObjectID 格式，无需转换
				card = self.game.cards.getCard(dbid)
				if card is None:
					raise ClientError('card not exist')
				
				# 检查卡牌是否被锁定
				if card.locked:
					raise ClientError('卡牌被加锁，请先解锁后操作')
				
				# 检查卡牌是否已被其他陨石占用（显示"在陨石X中"）
				if hasattr(card, 'meteorite_index') and card.meteorite_index and card.meteorite_index != index:
					raise ClientError('card in use by other meteorite')
				
				# 检查卡牌CD
				oldCard = self.game.meteorite.getCard(index)
				if oldCard and oldCard.id == card.id:
					# 如果是同一张卡牌，不需要CD检查
					pass
				else:
					# 检查是否在CD中
					if not self.game.meteorite.canSetCard(index):
						raise ClientError('card cd not ready')
				
				# 设置卡牌
				self.game.meteorite.setCard(index, card.id)
		
		elif setupType == 2:
			# 设置持有物
			if pos is None:
				raise ClientError('meteoriteParamError')
			
			pos = int(pos)
			
			# 检查位置有效性
			if pos < 1 or pos > len(meteorCfg.helditemCDs):
				raise ClientError('invalid held item position')
			
			if dbid is None or dbid == -1 or (isinstance(dbid, int) and dbid < 0):
				# 卸下持有物（前端传-1表示卸下）
				self.game.meteorite.unsetHeldItem(index, pos)
			else:
				# dbid 已经是正确的 ObjectID 格式，无需转换
				heldItem = self.game.heldItems.getHeldItem(dbid)
				if heldItem is None:
					raise ClientError('held item not exist')
				
				# 检查持有物是否被其他卡牌装备
				if heldItem.card_db_id:
					raise ClientError('held item in use by card')
				
				# 检查持有物是否已被其他陨石占用（显示"在陨石X中"）
				if hasattr(heldItem, 'meteorite_index') and heldItem.meteorite_index and heldItem.meteorite_index != index:
					raise ClientError('held item in use by other meteorite')
				
				# 检查持有物CD
				oldHeldItem = self.game.meteorite.getHeldItem(index, pos)
				if oldHeldItem and oldHeldItem.id == heldItem.id:
					# 如果是同一个持有物，不需要CD检查
					pass
				else:
					# 检查是否在CD中
					if not self.game.meteorite.canSetHeldItem(index, pos):
						raise ClientError('held item cd not ready')
				
				# 设置持有物
				self.game.meteorite.setHeldItem(index, pos, heldItem.id)
		else:
			raise ClientError('invalid setup type')
		
		# 返回空 view，让系统自动同步 role.meteorites
		# meteorites 现在统一使用整数键，与前端 Lua 兼容
		self.write({
			'view': {}
		})


#
# 陨石强化
#
class MeteoriteStrength(RequestHandlerTask):
	url = r'/game/meteorite/strength'
	
	@coroutine
	def run(self):
		"""强化陨石
		
		参数（命名参数）:
		- meteoriteID: 陨石索引 (1-7)
		- count: 强化次数
		"""
		meteoriteID = self.input.get('meteoriteID', None)
		count = self.input.get('count', 1)
		
		if meteoriteID is None:
			raise ClientError('meteoriteParamError')
		
		index = int(meteoriteID)
		count = int(count)
		
		if count <= 0:
			raise ClientError('meteoriteParamError')
		
		# 检查陨石索引有效性
		if index not in csv.meteorite.base:
			raise ClientError('invalid meteorite index')
		
		meteorCfg = csv.meteorite.base[index]
		
		# 等级要求检查
		if self.game.role.level < meteorCfg.unlockLevel:
			raise ClientError('role level not enough')
		
		# 前置陨石检查
		if meteorCfg.preID > 0:
			preMeteorData = self.game.meteorite.getMeteorData(meteorCfg.preID)
			if not preMeteorData or preMeteorData.get('level', 0) < meteorCfg.preLevel:
				raise ClientError('pre meteorite level not enough')
		
		# 获取当前等级
		currentLevel = self.game.meteorite.getLevel(index)
		
		# 获取等级表，检查最大等级（csv.meteorite.level是数组，从0开始）
		maxLevel = len(csv.meteorite.level) - 1
		
		# 检查是否已满级
		if currentLevel >= maxLevel:
			raise ClientError('meteorite max level')
		
		# 计算实际可强化次数（不能超过最大等级）
		actualCount = min(count, maxLevel - currentLevel)
		
		# 计算消耗（从csv.meteorite.cost获取）
		totalCost = {}
		for i in range(actualCount):
			targetLevel = currentLevel + i
			# csv.meteorite.cost是数组，索引是等级
			if targetLevel not in csv.meteorite.cost:
				raise ClientError('meteorite cost config not found for level %d' % targetLevel)
			
			costLevelCfg = csv.meteorite.cost[targetLevel]
			# 获取cost字段名（cost1, cost2等，根据costSeqID）
			costKey = 'cost%d' % meteorCfg.costSeqID
			costData = getattr(costLevelCfg, costKey, None)
			if not costData:
				raise ClientError('meteorite cost seq config not found: %s' % costKey)
			
			# 累加消耗
			for itemID, itemCount in costData.items():
				if itemID != '__size':
					totalCost[itemID] = totalCost.get(itemID, 0) + itemCount
		
		# 扣除消耗
		cost = ObjectCostAux(self.game, totalCost)
		if not cost.isEnough():
			raise ClientError('cost not enough')
		cost.cost(src='meteorite_strength')
		
		# 强化陨石
		newLevel = self.game.meteorite.addLevel(index, actualCount)
		
		# TODO: 任务统计 - 需要先在TargetDefs中添加MeteoriteStrength常量
		# ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.MeteoriteStrength, actualCount)
		
		self.write({
			'view': {
				'level': newLevel
			}
		})
