#!/usr/bin/python
# -*- coding: utf-8 -*-

'''
众神禁地 (Elite Challenge) HTTP接口
'''

from framework.csv import csv, ErrDefs
from framework.log import logger
from game import ClientError
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object.game.gain import ObjectCostAux
from game.object import YYHuoDongDefs
from game.object.game.yyhuodong import ObjectYYEliteChallenge, ObjectYYHuoDongFactory
from tornado.gen import coroutine


def getOpenYYID():
	'''获取当前开放的众神禁地活动ID'''
	for yyID in ObjectYYHuoDongFactory.OpenIDSet:
		if yyID not in csv.yunying.yyhuodong:
			continue
		cfg = csv.yunying.yyhuodong[yyID]
		if cfg.type == YYHuoDongDefs.EliteChallenge:
			yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
			if yyObj and yyObj.isOpen():
				return yyID
	return None


# 主界面
class EliteChallengeMain(RequestHandlerTask):
	url = r'/game/elite_challenge/main'

	@coroutine
	def run(self):
		yyID = getOpenYYID()
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)

		ObjectYYEliteChallenge.refreshRecord(yyID, self.game)
		view = ObjectYYEliteChallenge.getMainView(yyID, self.game)

		# 前端 model.init() 期望 {_mem: data}
		self.write({
			'model': {'elite_challenge': {'_mem': view}},
			'view': {}
		})


# 准备布阵
class EliteChallengePrepareDeploy(RequestHandlerTask):
	url = r'/game/elite_challenge/prepare_deploy'

	@coroutine
	def run(self):
		yyID = getOpenYYID()
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)

		# 前端 params(cardCsvIDs, prepareCardCsvIDs, skinIDs, extra)
		cardCsvIDs = self.input.get('cardCsvIDs', [])
		prepareCardCsvIDs = self.input.get('prepareCardCsvIDs', [])
		skinIDs = self.input.get('skinIDs', {})
		extra = self.input.get('extra', {})

		# cardCsvIDs 可以为空（前端可能只选了部分位置）
		if not cardCsvIDs and not prepareCardCsvIDs:
			raise ClientError('no cards selected')

		ret = ObjectYYEliteChallenge.prepareDeploy(yyID, self.game, cardCsvIDs, prepareCardCsvIDs, skinIDs, extra)
		if not ret:
			raise ClientError('prepare deploy failed')

		view = ObjectYYEliteChallenge.getMainView(yyID, self.game)
		
		logger.info('EliteChallenge prepareDeploy返回: round=%s floor=%d monsters=%d prepare_cards=%d', 
			view.get('round'), view.get('floor'), len(view.get('monsters', {})), len(view.get('prepare_cards', {})))
		logger.info('EliteChallenge prepareDeploy monsters keys: %s', view.get('monsters', {}).keys())
		
		# 使用 sync.upd 触发前端增量更新 gGameModel.elite_challenge
		self.write({
			'sync': {
				'upd': {
					'elite_challenge': {'_mem': view}
				}
			}
		})


# 布阵接口：/game/elite_challenge/deploy
# 前端参数：battleCardIDs (数组), extra
class EliteChallengeDeploy(RequestHandlerTask):
	url = r'/game/elite_challenge/deploy'

	@coroutine
	def run(self):
		yyID = getOpenYYID()
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)

		battleCardIDs = self.input.get('battleCardIDs', [])
		extra = self.input.get('extra', [])

		if not battleCardIDs:
			raise ClientError('no cards selected')

		ret = ObjectYYEliteChallenge.deploy(yyID, self.game, battleCardIDs, extra)
		if not ret:
			raise ClientError('deploy failed')

		view = ObjectYYEliteChallenge.getMainView(yyID, self.game)
		self.write({
			'sync': {
				'upd': {
					'elite_challenge': {'_mem': view}
				}
			}
		})


# 兼容旧接口


# 战斗开始
class EliteChallengeStart(RequestHandlerTask):
	url = r'/game/elite_challenge/battle/start'

	@coroutine
	def run(self):
		yyID = getOpenYYID()
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)

		# 前端参数: battleCardIDs, extra, sceneID
		sceneID = self.input.get('sceneID', 0)
		if not sceneID:
			raise ClientError('sceneID miss')

		battleModel = ObjectYYEliteChallenge.battleStart(yyID, self.game, sceneID)
		if not battleModel:
			raise ClientError('battle start failed')

		# 保存到 game.battle 供战斗系统使用
		self.game.battle = battleModel
		
		# 返回战斗数据
		self.write({
			'model': {'elite_challenge_battle': battleModel},
			'view': {}
		})


# 战斗结束
class EliteChallengeBattleEnd(RequestHandlerTask):
	url = r'/game/elite_challenge/battle/end'

	@coroutine
	def run(self):
		yyID = getOpenYYID()
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)

		# 前端参数: battleID, result, star, cardStates, enemyStates, battleRound
		battleID = self.input.get('battleID', '')
		battleResult = self.input.get('result', '')  # "win" or "fail"
		star = self.input.get('star', 0)
		cardStates = self.input.get('cardStates', {})
		# enemyStates = self.input.get('enemyStates', {})  # 暂不使用
		# battleRound = self.input.get('battleRound', 0)  # 暂不使用

		# sceneID 从 battleID 解析 (格式: yyID_roleID_sceneID) 或从 record 读取
		record = ObjectYYEliteChallenge.getRecord(yyID, self.game)
		sceneID = record['info'].get('scene_id_choose', 0)

		result = ObjectYYEliteChallenge.battleEnd(yyID, self.game, sceneID, star, cardStates)

		view = ObjectYYEliteChallenge.getMainView(yyID, self.game)
		# 前端 elite_challenge_gate.lua 读取 tb.result.view
		self.write({
			'sync': {'upd': {'elite_challenge': {'_mem': view}}},
			'result': {'view': result}
		})


# 碾压通关
class EliteChallengeBattlePass(RequestHandlerTask):
	url = r'/game/elite_challenge/battle/pass'

	@coroutine
	def run(self):
		yyID = getOpenYYID()
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)

		# 前端参数名是 sceneID
		sceneID = self.input.get('sceneID', 0)
		if not sceneID:
			raise ClientError('sceneID miss')

		ret = ObjectYYEliteChallenge.battlePass(yyID, self.game, sceneID)
		if not ret:
			raise ClientError('battle pass failed')

		view = ObjectYYEliteChallenge.getMainView(yyID, self.game)
		self.write({
			'sync': {'upd': {'elite_challenge': {'_mem': view}}},
			'view': ret
		})


# 选择Buff
class EliteChallengeBuffChoose(RequestHandlerTask):
	url = r'/game/elite_challenge/buff/choose'

	@coroutine
	def run(self):
		yyID = getOpenYYID()
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)

		# 前端参数名是 choose (索引 1,2,3)
		idx = self.input.get('choose', 0)
		if not idx:
			raise ClientError('choose miss')

		ret = ObjectYYEliteChallenge.buffChoose(yyID, self.game, idx)
		if not ret:
			raise ClientError('buff choose failed')

		view = ObjectYYEliteChallenge.getMainView(yyID, self.game)
		self.write({
			'sync': {'upd': {'elite_challenge': {'_mem': view}}},
			'view': {}
		})


# 结束本轮挑战
class EliteChallengeRoundEnd(RequestHandlerTask):
	url = r'/game/elite_challenge/end'

	@coroutine
	def run(self):
		yyID = getOpenYYID()
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)

		awards = ObjectYYEliteChallenge.endRound(yyID, self.game)

		view = ObjectYYEliteChallenge.getMainView(yyID, self.game)
		self.write({
			'sync': {'upd': {'elite_challenge': {'_mem': view}}},
			'view': awards  # 返回结算奖励
		})


# 购买挑战次数
class EliteChallengeTimesBuy(RequestHandlerTask):
	url = r'/game/elite_challenge/times/buy'

	@coroutine
	def run(self):
		yyID = getOpenYYID()
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)

		record = ObjectYYEliteChallenge.getRecord(yyID, self.game)
		info = record['info']
		themeID = info.get('theme', 1)
		themeCfg = ObjectYYEliteChallenge.ThemeMap.get(themeID)

		if not themeCfg:
			raise ClientError('theme config not found')

		buyTimes = info.get('buy_challenge_times', 0)
		buyTimesCost = getattr(themeCfg, 'buyTimesCost', [])

		if buyTimes >= len(buyTimesCost):
			raise ClientError('no more times to buy')

		cost = buyTimesCost[buyTimes]
		
		logger.info('EliteChallenge times/buy: before buyTimes=%d, cost=%d', buyTimes, cost)
		
		# 扣除钻石
		costAux = ObjectCostAux(self.game, {'rmb': cost})
		if not costAux.isEnough():
			raise ClientError(ErrDefs.rmbNotEnough)
		costAux.cost(src='elite_challenge_buy_times')

		info['buy_challenge_times'] = buyTimes + 1
		
		logger.info('EliteChallenge times/buy: after buyTimes=%d', info['buy_challenge_times'])
		
		# 触发脏标记
		ObjectYYEliteChallenge.setRecord(yyID, self.game, record)

		view = ObjectYYEliteChallenge.getMainView(yyID, self.game)
		self.write({
			'sync': {'upd': {'elite_challenge': {'_mem': view}}},
			'view': {}
		})


# 跨服排行榜（简化版）
class EliteChallengeRank(RequestHandlerTask):
	url = r'/game/cross/elite_challenge/rank'

	@coroutine
	def run(self):
		# 前端传 offset, size
		offset = self.input.get('offset', 0)
		size = self.input.get('size', 50)
		
		# 简化返回空数据（实际需要从跨服服务获取）
		self.write({
			'view': {
				'ranks': [],  # 注意是 ranks 不是 rank
				'rank': 0,    # 我的排名（数字）
				'score': 0    # 我的积分（数字）
			}
		})


# 领取积分奖励
class EliteChallengePointAward(RequestHandlerTask):
	url = r'/game/elite_challenge/point/award'

	@coroutine
	def run(self):
		yyID = getOpenYYID()
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)

		# 前端参数名是 csvID (或 -1 表示一键领取)
		csvID = self.input.get('csvID', 0)
		if not csvID:
			raise ClientError('csvID miss')

		ret = ObjectYYEliteChallenge.pointAward(yyID, self.game, csvID)
		if not ret:
			raise ClientError('point award failed')

		view = ObjectYYEliteChallenge.getMainView(yyID, self.game)
		self.write({
			'sync': {'upd': {'elite_challenge': {'_mem': view}}},
			'view': ret
		})
