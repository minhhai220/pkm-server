#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

HellRandomTower (无尽随机塔) Handlers
'''
import copy

from framework import nowtime_t
from framework.csv import ErrDefs, csv, ConstDefs
from framework.helper import transform2list
from framework.log import logger
from game import ClientError, ServerError
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import RandomTowerDefs, TargetDefs, FeatureDefs
from game.object.game import ObjectFeatureUnlockCSV
from game.object.game.hellRandomTower import ObjectHellRandomTower
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.thinkingdata import ta

from tornado.gen import coroutine, Return


# 预备部署（选择预备卡牌）
class HellRandomTowerPrepareDeploy(RequestHandlerTask):
	url = r'/game/hell_random_tower/prepare_deploy'

	@coroutine
	def run(self):
		role = self.game.role
		if role.hell_random_tower_db_id is None:
			recordData = yield self.dbcGame.call_async('DBCreate', 'HellRandomTower', {
				'role_db_id': role.id,
			})
			if not recordData['ret']:
				raise ServerError('db create hellRandomTower record error')
			self.game.role.hell_random_tower_db_id = recordData['model']['id']
			self.game.hellRandomTower.set(recordData['model']).init()

		cardCsvIDs = self.input.get('cardCsvIDs', [])
		prepareCardCsvIDs = self.input.get('prepareCardCsvIDs', [])
		skinIDs = self.input.get('skinIDs', {})
		extra = self.input.get('extra', {})

		hellRandomTower = self.game.hellRandomTower
		
		# 设置预备卡牌
		hellRandomTower.prepare_cards = prepareCardCsvIDs
		hellRandomTower.battle_cards = cardCsvIDs
		hellRandomTower.round = 'prepare'
		
		# 初始化房间
		hellRandomTower.room = 1
		hellRandomTower.room_info = {'next_room_scope': (-1, 99999)}
		hellRandomTower.boards = {}
		hellRandomTower.card_states = {}
		hellRandomTower.enemy_states = {}
		hellRandomTower.enemy_states_multi = {}
		hellRandomTower.battle_result_multi = {}
		hellRandomTower.buffs = []
		hellRandomTower.buff_lib = []
		hellRandomTower.buff_time = {}
		hellRandomTower.event_time = {}
		hellRandomTower.skill_used = {}
		hellRandomTower.jump_info = {}
		hellRandomTower.jump_step = RandomTowerDefs.JumpBegin

		# 初始化前三房间
		for i in xrange(hellRandomTower.room, hellRandomTower.room + 3, 1):
			if i <= ObjectHellRandomTower.MaxRoom:
				hellRandomTower.setRoomBoards(i)
		
		hellRandomTower.round = 'start'

		self.write({
			'view': {}
		})


# 部署阵容（更新战斗卡牌）
class HellRandomTowerDeploy(RequestHandlerTask):
	url = r'/game/hell_random_tower/deploy'

	@coroutine
	def run(self):
		if self.game.role.hell_random_tower_db_id is None:
			raise ClientError('hellRandomTower need prepare')
		
		battleCardIDs = self.input.get('battleCardIDs', [])
		extra = self.input.get('extra', {})

		hellRandomTower = self.game.hellRandomTower
		hellRandomTower.battle_cards = battleCardIDs
		# TODO: 处理 extra（多队战斗的情况）

		self.write({
			'view': {}
		})


# 选择卡面（打怪不发这个）
class HellRandomTowerBoard(RequestHandlerTask):
	url = r'/game/hell_random_tower/board'

	@coroutine
	def run(self):
		if self.game.role.hell_random_tower_db_id is None:
			raise ClientError('hellRandomTower need prepare')
		boardID = self.input.get('boardID', None)

		hellRandomTower = self.game.hellRandomTower
		if hellRandomTower.room_info.get('board_id', None) and hellRandomTower.room_info.get('board_id', None) != boardID:
			raise ClientError('param boardID error1')
		if boardID:
			# 判断选择卡面对不对（符合线路）
			if not hellRandomTower.isRightChoose(boardID):
				raise ClientError('param boardID error3')
			# 设置下一个房间的选择范围
			if not hellRandomTower.room_info.get('board_id', None):
				hellRandomTower.room_info.setdefault('board_id', boardID)
				hellRandomTower.setNextRoomScope()
			cfg = csv.hell_random_tower.board[boardID]
			# 事件
			if cfg.type == RandomTowerDefs.EventType:
				events = hellRandomTower.room_info.get('event', None)
				eventCsvID = events.get(boardID, 0)
				cfgEvent = csv.hell_random_tower.event[eventCsvID]
				hellRandomTower.event_time[eventCsvID] = hellRandomTower.event_time.get(eventCsvID, 0) + 1
				# 如果事件只有一个就直接进入下一房间
				if not cfgEvent.choice1:
					effAward, buffList, points = hellRandomTower.getEventAward(cfgEvent)
					for buffCsvID in buffList:
						cfgBuff = csv.hell_random_tower.buffs[buffCsvID]
						if cfgBuff.buffType != RandomTowerDefs.BuffSupply:
							hellRandomTower.addBuffs(buffCsvID)
						else:
							hellRandomTower.buffSupply(buffCsvID)
						hellRandomTower.buff_time[buffCsvID] = hellRandomTower.buff_time.get(buffCsvID, 0) + 1
						if cfgBuff.changeLib != 0:
							hellRandomTower.buff_lib.append(cfgBuff.changeLib)
					hellRandomTower.point += points
					yield effectAutoGain(effAward, self.game, self.dbcGame, src='hell_random_tower_event_award')
					hellRandomTower.nextRoom()
			# Buff
			elif cfg.type == RandomTowerDefs.BuffType:
				buffs = hellRandomTower.room_info.get('buff', None)
				buffCsvID = buffs.get(boardID, 0)
				cfgBuff = csv.hell_random_tower.buffs[buffCsvID]
				if not hellRandomTower.isBuffCondition(buffCsvID):
					raise ClientError('buff condition not met')
				if cfgBuff.buffType != RandomTowerDefs.BuffSupply:
					hellRandomTower.addBuffs(buffCsvID)
				else:
					hellRandomTower.buffSupply(buffCsvID)
				hellRandomTower.buff_time[buffCsvID] = hellRandomTower.buff_time.get(buffCsvID, 0) + 1
				if cfgBuff.changeLib != 0:
					hellRandomTower.buff_lib.append(cfgBuff.changeLib)
				hellRandomTower.nextRoom()

		self.write({
			'view': {}
		})


# 选择事件选项
class HellRandomTowerEventChoose(RequestHandlerTask):
	url = r'/game/hell_random_tower/event/choose'

	@coroutine
	def run(self):
		if self.game.role.hell_random_tower_db_id is None:
			raise ClientError('hellRandomTower need prepare')
		choice = self.input.get('choice', 'choice1')

		hellRandomTower = self.game.hellRandomTower
		boardID = hellRandomTower.room_info.get('board_id', None)
		if not boardID:
			raise ClientError('no board selected')
		
		events = hellRandomTower.room_info.get('event', {})
		eventCsvID = events.get(boardID, 0)
		if not eventCsvID:
			raise ClientError('no event')
		
		cfgEvent = csv.hell_random_tower.event[eventCsvID]
		effAward, buffList, points = hellRandomTower.getEventAward(cfgEvent, choice)
		
		for buffCsvID in buffList:
			cfgBuff = csv.hell_random_tower.buffs[buffCsvID]
			if cfgBuff.buffType != RandomTowerDefs.BuffSupply:
				hellRandomTower.addBuffs(buffCsvID)
			else:
				hellRandomTower.buffSupply(buffCsvID)
			hellRandomTower.buff_time[buffCsvID] = hellRandomTower.buff_time.get(buffCsvID, 0) + 1
			if cfgBuff.changeLib != 0:
				hellRandomTower.buff_lib.append(cfgBuff.changeLib)
		
		hellRandomTower.point += points
		yield effectAutoGain(effAward, self.game, self.dbcGame, src='hell_random_tower_event_award')
		hellRandomTower.nextRoom()

		self.write({
			'view': {
				'result': effAward.result
			}
		})


# 开宝箱
class HellRandomTowerBoxOpen(RequestHandlerTask):
	url = r'/game/hell_random_tower/box/open'

	@coroutine
	def run(self):
		if self.game.role.hell_random_tower_db_id is None:
			raise ClientError('hellRandomTower need prepare')

		hellRandomTower = self.game.hellRandomTower
		boardID = hellRandomTower.room_info.get('board_id', None)
		if not boardID:
			raise ClientError('no board selected')
		
		eff = hellRandomTower.getBoxAwards(boardID)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='hell_random_tower_box_award')

		self.write({
			'view': eff.result
		})


# 进入下一房间
class HellRandomTowerNext(RequestHandlerTask):
	url = r'/game/hell_random_tower/next'

	@coroutine
	def run(self):
		if self.game.role.hell_random_tower_db_id is None:
			raise ClientError('hellRandomTower need prepare')

		hellRandomTower = self.game.hellRandomTower
		hellRandomTower.nextRoom()

		self.write({
			'view': {}
		})


# 碾压通关
class HellRandomTowerPass(RequestHandlerTask):
	url = r'/game/hell_random_tower/pass'

	@coroutine
	def run(self):
		if self.game.role.hell_random_tower_db_id is None:
			raise ClientError('hellRandomTower need prepare')
		boardID = self.input.get('boardID', None)

		hellRandomTower = self.game.hellRandomTower
		# TODO: 实现碾压逻辑
		# 1. 检查碾压条件
		# 2. 自动获得奖励
		# 3. 进入下一房间

		self.write({
			'view': {
				'award': {},
				'point': 0
			}
		})


# 使用 Buff（补给型）
class HellRandomTowerBuffUsed(RequestHandlerTask):
	url = r'/game/hell_random_tower/buff/used'

	@coroutine
	def run(self):
		if self.game.role.hell_random_tower_db_id is None:
			raise ClientError('hellRandomTower need prepare')
		cards = self.input.get('cards', [])

		hellRandomTower = self.game.hellRandomTower
		boardID = hellRandomTower.room_info.get('board_id', None)
		if not boardID:
			raise ClientError('no board selected')
		
		buffs = hellRandomTower.room_info.get('buff', {})
		buffCsvID = buffs.get(boardID, 0)
		if not buffCsvID:
			raise ClientError('no buff')
		
		hellRandomTower.buffSupply(buffCsvID, cards)

		self.write({
			'view': {}
		})


# 使用道具
class HellRandomTowerUseItem(RequestHandlerTask):
	url = r'/game/hell_random_tower/use/item'

	@coroutine
	def run(self):
		if self.game.role.hell_random_tower_db_id is None:
			raise ClientError('hellRandomTower need prepare')
		itemID = self.input.get('itemID', None)
		cards = self.input.get('cards', [])

		hellRandomTower = self.game.hellRandomTower
		# TODO: 实现道具使用逻辑
		# 从 hellRandomTower.items 中扣除道具
		# 根据道具效果处理

		self.write({
			'view': {}
		})


# 领取积分奖励
class HellRandomTowerPointAward(RequestHandlerTask):
	url = r'/game/hell_random_tower/point/award'

	@coroutine
	def run(self):
		if self.game.role.hell_random_tower_db_id is None:
			raise ClientError('hellRandomTower need prepare')
		csvID = self.input.get('csvID', None)

		hellRandomTower = self.game.hellRandomTower
		if csvID not in csv.hell_random_tower.point_award:
			raise ClientError('invalid csvID')
		
		if hellRandomTower.point_award.get(csvID) != 1:
			raise ClientError('cannot get award')
		
		cfg = csv.hell_random_tower.point_award[csvID]
		eff = ObjectGainAux(self.game, cfg.award)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='hell_random_tower_point_award')
		
		hellRandomTower.point_award[csvID] = 0

		self.write({
			'view': eff.result
		})


# 重置挑战
class HellRandomTowerReset(RequestHandlerTask):
	url = r'/game/hell_random_tower/reset'

	@coroutine
	def run(self):
		if self.game.role.hell_random_tower_db_id is None:
			raise ClientError('hellRandomTower need prepare')

		hellRandomTower = self.game.hellRandomTower
		theme = hellRandomTower.theme
		themeCfg = csv.hell_random_tower.theme[theme] if theme in csv.hell_random_tower.theme else None
		if not themeCfg:
			raise ClientError('invalid theme')
		
		# 检查重置次数
		if hellRandomTower.reset_times >= themeCfg.resetTimesLimit:
			raise ClientError('reset times limit')
		
		# 消耗钻石
		resetCost = ConstDefs.hellRandomTowerResetCost or 100
		cost = ObjectCostAux(self.game, {'rmb': resetCost})
		if not cost.isEnough():
			raise ClientError(ErrDefs.rmbNotEnough)
		cost.cost(src='hell_random_tower_reset')
		
		# 重置数据
		hellRandomTower.reset_times += 1
		hellRandomTower.round = 'closed'
		hellRandomTower.room = 0
		hellRandomTower.boards = {}
		hellRandomTower.room_info = {}
		hellRandomTower.prepare_cards = []
		hellRandomTower.battle_cards = []
		hellRandomTower.battle_cards_multi = {}
		hellRandomTower.battle_result_multi = {}
		hellRandomTower.card_states = {}
		hellRandomTower.enemy_states = {}
		hellRandomTower.enemy_states_multi = {}
		hellRandomTower.buffs = []
		hellRandomTower.buff_lib = []
		hellRandomTower.buff_time = {}
		hellRandomTower.event_time = {}
		hellRandomTower.skill_used = {}
		hellRandomTower.jump_info = {}
		hellRandomTower.jump_step = RandomTowerDefs.JumpBegin

		self.write({
			'view': {}
		})


# 跳关：下一步
class HellRandomTowerJumpNext(RequestHandlerTask):
	url = r'/game/hell_random_tower/jump/next'

	@coroutine
	def run(self):
		if self.game.role.hell_random_tower_db_id is None:
			raise ClientError('hellRandomTower need prepare')

		hellRandomTower = self.game.hellRandomTower
		# TODO: 实现跳关逻辑

		self.write({
			'view': {}
		})


# 跳关：选择 Buff
class HellRandomTowerJumpBuff(RequestHandlerTask):
	url = r'/game/hell_random_tower/jump/buff'

	@coroutine
	def run(self):
		if self.game.role.hell_random_tower_db_id is None:
			raise ClientError('hellRandomTower need prepare')
		boardID = self.input.get('boardID', 0)

		hellRandomTower = self.game.hellRandomTower
		# TODO: 实现跳关选择 Buff 逻辑

		self.write({
			'view': {}
		})


# 跳关：开宝箱
class HellRandomTowerJumpBoxOpen(RequestHandlerTask):
	url = r'/game/hell_random_tower/jump/box_open'

	@coroutine
	def run(self):
		if self.game.role.hell_random_tower_db_id is None:
			raise ClientError('hellRandomTower need prepare')
		boardID = self.input.get('boardID', 0)
		openType = self.input.get('openType', 'open1')

		hellRandomTower = self.game.hellRandomTower
		# TODO: 实现跳关开箱逻辑

		self.write({
			'view': {}
		})


# 跳关：事件选择
class HellRandomTowerJumpEvent(RequestHandlerTask):
	url = r'/game/hell_random_tower/jump/event'

	@coroutine
	def run(self):
		if self.game.role.hell_random_tower_db_id is None:
			raise ClientError('hellRandomTower need prepare')
		boardID = self.input.get('boardID', None)
		choice = self.input.get('choice', 'choice1')

		hellRandomTower = self.game.hellRandomTower
		# TODO: 实现跳关事件选择逻辑

		self.write({
			'view': {}
		})


# 开始战斗
class HellRandomTowerStart(RequestHandlerTask):
	url = r'/game/hell_random_tower/start'

	@coroutine
	def run(self):
		if self.game.role.hell_random_tower_db_id is None:
			raise ClientError('hellRandomTower need prepare')
		
		battleCardIDs = self.input.get('battleCardIDs', [])
		boardID = self.input.get('boardID', None)
		extra = self.input.get('extra', {})

		hellRandomTower = self.game.hellRandomTower
		# TODO: 实现战斗开始逻辑
		# 1. 创建 ObjectHellRandomTowerBattle 对象
		# 2. 返回战斗模型

		self.write({
			'view': {
				'battle_id': '00000000000000000000000000000000',
				'model': {}
			}
		})


# 结束战斗
class HellRandomTowerEnd(RequestHandlerTask):
	url = r'/game/hell_random_tower/end'

	@coroutine
	def run(self):
		if self.game.role.hell_random_tower_db_id is None:
			raise ClientError('hellRandomTower need prepare')
		
		battleID = self.input.get('battleID', None)
		result = self.input.get('result', None)
		star = self.input.get('star', None)
		cardStates = self.input.get('cardStates', {})
		enemyStates = self.input.get('enemyStates', {})
		battleRound = self.input.get('battleRound', 0)

		hellRandomTower = self.game.hellRandomTower
		# TODO: 实现战斗结束逻辑
		# 1. 验证战斗ID
		# 2. 记录卡牌状态
		# 3. 计算积分
		# 4. 进入下一房间
		
		# 勋章计数：地狱以太乐园困难敌人胜利
		if result == 'win':
			boardID = hellRandomTower.room_info.get('board_id', None)
			if boardID and boardID in csv.hell_random_tower.board:
				cfgBoard = csv.hell_random_tower.board[boardID]
				# type=1表示怪物战斗，monsterType=3表示困难敌人
				if cfgBoard.type == RandomTowerDefs.MonsterType and cfgBoard.monsterType == 3:
					self.game.role.hell_random_tower_hard_beat_count = (self.game.role.hell_random_tower_hard_beat_count or 0) + 1

		self.write({
			'view': {
				'point': 0
			}
		})

