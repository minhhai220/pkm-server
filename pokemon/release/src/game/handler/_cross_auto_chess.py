#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
============================================================================
卡牌对决 跨服PVP (Cross Auto Chess) - HTTP 接口处理器
跨服服务名: crossautochess
============================================================================
'''

from __future__ import absolute_import

from tornado.gen import coroutine, Return

from framework.csv import csv, ErrDefs
from framework.log import logger
from game import ClientError, ServerError
from game.handler.task import RequestHandlerTask
from game.object.game.cross_auto_chess import ObjectCrossAutoChessGameGlobal

# ============================================================================
# 跨服 PVP 匹配
# ============================================================================

class CrossAutoChessPvpMatch(RequestHandlerTask):
	"""开始跨服PVP匹配"""
	url = r'/game/auto_chess/pvp/match'

	@coroutine
	def run(self):
		if getattr(self.game.role, 'auto_chess_db_id', None) is None:
			raise ClientError('auto_chess not unlocked')

		trainerID = self.input.get('trainer', 0)
		if not trainerID:
			raise ClientError('param miss: trainer')

		ac = self.game.auto_chess
		if not ac.inited:
			yield ac.init()

		# 自动获取跨服服务名（与拟态、竞技场逻辑一致）
		cross_key = ObjectCrossAutoChessGameGlobal.getCrossKey(self.game.role.areaKey)
		if not cross_key:
			raise ClientError('cross service not available')
		
		timeout = self.input.get('timeout', 60)  # 默认60秒超时
		
		result = yield self.rpc.call_async(cross_key, 'Match', {
			'role_id': str(self.game.role.id),
			'game_key': self.game.role.areaKey,
			'name': self.game.role.name,
			'level': self.game.role.level,
			'logo': self.game.role.logo,
			'frame': self.game.role.frame,
			'score': ac.pvp_info.get('score', 1000),
			'grade': ac.pvp_info.get('grade', 1),
			'trainer_id': trainerID,
			'timeout': timeout,
		})
		
		# 更新本地状态
		if result and result.get('model'):
			model = result['model']
			if model.get('online'):
				ac.online.update(model['online'])
		
		self.write({
			'view': result
		})

class CrossAutoChessPvpCancelMatch(RequestHandlerTask):
	"""取消跨服PVP匹配"""
	url = r'/game/auto_chess/pvp/cancel_match'

	@coroutine
	def run(self):
		if getattr(self.game.role, 'auto_chess_db_id', None) is None:
			raise ClientError('auto_chess not unlocked')

		ac = self.game.auto_chess
		if not ac.inited:
			yield ac.init()

		# 自动获取跨服服务名
		cross_key = ObjectCrossAutoChessGameGlobal.getCrossKey(self.game.role.areaKey)
		if not cross_key:
			raise ClientError('cross service not available')
		
		result = yield self.rpc.call_async(cross_key, 'CancelMatch', {
			'role_id': str(self.game.role.id),
		})
		
		# 更新本地状态
		if result and result.get('model'):
			model = result['model']
			if model.get('online'):
				ac.online.update(model['online'])
		
		self.write({
			'view': result
		})

class CrossAutoChessPvpSync(RequestHandlerTask):
	"""同步跨服PVP数据（匹配状态、段位信息等）"""
	url = r'/game/auto_chess/pvp/sync'

	@coroutine
	def run(self):
		if getattr(self.game.role, 'auto_chess_db_id', None) is None:
			raise ClientError('auto_chess not unlocked')

		ac = self.game.auto_chess
		if not ac.inited:
			yield ac.init()

		# 自动获取跨服服务名
		cross_key = ObjectCrossAutoChessGameGlobal.getCrossKey(self.game.role.areaKey)
		if not cross_key:
			raise ClientError('cross service not available')
		
		result = yield self.rpc.call_async(cross_key, 'Sync', {
			'role_id': str(self.game.role.id),
		})
		
		# 更新本地数据
		if result and result.get('model'):
			model = result['model']
			if model.get('pvp_info'):
				ac.pvp_info.update(model['pvp_info'])
			if model.get('online'):
				ac.online.update(model['online'])
		
		self.write({
			'view': result
		})

class CrossAutoChessPvpRank(RequestHandlerTask):
	"""获取跨服PVP排行榜"""
	url = r'/game/auto_chess/pvp/rank'

	@coroutine
	def run(self):
		if getattr(self.game.role, 'auto_chess_db_id', None) is None:
			raise ClientError('auto_chess not unlocked')

		ac = self.game.auto_chess
		if not ac.inited:
			yield ac.init()

		rank_type = self.input.get('type', -1)  # -1=总榜，其他=训练家ID

		# 自动获取跨服服务名
		cross_key = ObjectCrossAutoChessGameGlobal.getCrossKey(self.game.role.areaKey)
		if not cross_key:
			raise ClientError('cross service not available')
		
		result = yield self.rpc.call_async(cross_key, 'GetRank', {
			'role_id': str(self.game.role.id),
			'type': rank_type,
		})
		
		self.write({
			'view': result
		})

class CrossAutoChessPvpSettle(RequestHandlerTask):
	"""跨服PVP战斗结算"""
	url = r'/game/auto_chess/pvp/settle'

	@coroutine
	def run(self):
		if getattr(self.game.role, 'auto_chess_db_id', None) is None:
			raise ClientError('auto_chess not unlocked')

		ac = self.game.auto_chess
		if not ac.inited:
			yield ac.init()

		# 获取战斗结果
		result = self.input.get('result', 0)  # 1=胜利, 0=失败
		if result not in (0, 1):
			raise ClientError('invalid result')

		# 自动获取跨服服务名
		cross_key = ObjectCrossAutoChessGameGlobal.getCrossKey(self.game.role.areaKey)
		if not cross_key:
			raise ClientError('cross service not available')
		
		settle_result = yield self.rpc.call_async(cross_key, 'Settle', {
			'role_id': str(self.game.role.id),
			'result': result,
		})
		
		# 更新本地数据
		if settle_result and settle_result.get('model'):
			model = settle_result['model']
			if model.get('pvp_info'):
				ac.pvp_info.update(model['pvp_info'])
			if model.get('pvp_history'):
				# 添加最新的历史记录
				if not ac.pvp_history:
					ac.pvp_history = []
				ac.pvp_history.insert(0, model['pvp_history'])
				# 只保留最近20条
				if len(ac.pvp_history) > 20:
					ac.pvp_history = ac.pvp_history[:20]
		
		self.write({
			'view': settle_result
		})

class CrossAutoChessPvpClaimGradeAward(RequestHandlerTask):
	"""领取跨服PVP段位奖励"""
	url = r'/game/auto_chess/pvp/claim_grade_award'

	@coroutine
	def run(self):
		if getattr(self.game.role, 'auto_chess_db_id', None) is None:
			raise ClientError('auto_chess not unlocked')

		ac = self.game.auto_chess
		if not ac.inited:
			yield ac.init()

		grade = self.input.get('grade', 0)
		if grade <= 0:
			raise ClientError('param miss: grade')

		# 检查是否已领取
		if not ac.pvp_grade_award:
			ac.pvp_grade_award = []
		if grade in ac.pvp_grade_award:
			raise ClientError('award already claimed')

		# 检查段位是否达到
		pvp_info = ac.pvp_info or {}
		current_grade = pvp_info.get('grade', 0)
		max_grade = pvp_info.get('max_grade', 0)
		if max_grade < grade:
			raise ClientError('grade not reached')

		# 获取奖励配置
		grade_cfg = csv.cross.online_auto_chess.grade.get(grade)
		if not grade_cfg or not grade_cfg.award:
			raise ClientError('invalid grade config')

		# 发放奖励
		from game.object.game.gain import ObjectGainAux
		gain = ObjectGainAux(self.game, grade_cfg.award)
		yield gain.doGain()

		# 标记已领取
		ac.pvp_grade_award.append(grade)

		self.write({
			'view': {
				'awards': gain.result
			}
		})
