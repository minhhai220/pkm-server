#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Aid Handlers - 助战系统接口处理器
'''

from framework import todayinclock5date2int, nowtime_t
from framework.csv import csv, ErrDefs, ConstDefs
from framework.log import logger

from game import ServerError, ClientError
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import FeatureDefs
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.aid import AidHelper

from tornado.gen import coroutine


# /game/card/aid/active - 激活助战
class AidActive(RequestHandlerTask):
	url = r'/game/card/aid/active'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Aid, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		# 前端传的是字典参数：aidID, type
		aidID = self.input.get('aidID', None)
		operation = self.input.get('type', 'active')  # 'active' or 'awake'
		
		if aidID is None:
			raise ClientError('param miss')

		aidID = int(aidID)
		if aidID not in csv.aid.aid:
			raise ClientError('invalid aidID')

		# 调用 AidHelper 的激活方法
		eff = AidHelper.aidActive(self.game, aidID, operation)

		self.write({
			'view': eff.result
		})


# /game/card/aid/enhance - 强化助战（升级、进阶、觉醒）
class AidEnhance(RequestHandlerTask):
	url = r'/game/card/aid/enhance'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Aid, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		# 前端传的是字典参数：aidID, level, stage, awake
		aidID = self.input.get('aidID', None)
		level = self.input.get('level', None)
		stage = self.input.get('stage', None)
		awake = self.input.get('awake', None)

		if aidID is None:
			raise ClientError('param miss')

		aidID = int(aidID)
		if aidID not in csv.aid.aid:
			raise ClientError('invalid aidID')

		# 转换参数类型
		if level is not None:
			level = int(level)
		if stage is not None:
			stage = int(stage)
		if awake is not None:
			awake = int(awake)

		# 调用 AidHelper 的强化方法
		AidHelper.aidEnhance(self.game, aidID, level, stage, awake)

		self.write({
			'view': {}
		})


# /game/card/aid/reset - 重置助战
class AidReset(RequestHandlerTask):
	url = r'/game/card/aid/reset'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Aid, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		# 前端传的是字典参数：aidID
		aidID = self.input.get('aidID', None)

		if aidID is None:
			raise ClientError('param miss')

		aidID = int(aidID)
		if aidID not in csv.aid.aid:
			raise ClientError('invalid aidID')

		# 调用 AidHelper 的重置方法
		eff = AidHelper.aidReset(self.game, aidID)

		self.write({
			'view': eff.result
		})


# /game/card/aid/quit - 退出助战界面
class AidQuit(RequestHandlerTask):
	url = r'/game/card/aid/quit'

	@coroutine
	def run(self):
		# 退出助战界面时批量更新所有卡牌战力
		# 助战强化时延迟更新，此处统一处理，避免连续升级时卡顿
		if getattr(self.game, '_aid_attrs_dirty', False):
			AidHelper.updateAllCardsAttrs(self.game)
		
		self.write({
			'view': {}
		})


# /game/card/aid/material/switch - 材料兑换
class AidMaterialSwitch(RequestHandlerTask):
	url = r'/game/card/aid/material/switch'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Aid, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)

		# 前端传的是字典参数：materialID, count
		materialID = self.input.get('materialID', None)
		count = self.input.get('count', 1)

		if materialID is None:
			raise ClientError('param miss')

		targetItemID = int(materialID)
		num = int(count)

		if num <= 0:
			raise ClientError('invalid num')

		# 调用 AidHelper 的材料兑换方法
		eff = AidHelper.aidMaterialSwitch(self.game, targetItemID, num)

		# 发放奖励
		yield effectAutoGain(eff, self.game, self.dbcGame, src='aid_material_switch')

		self.write({'view': eff.result})
