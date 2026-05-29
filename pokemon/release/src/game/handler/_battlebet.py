#!/usr/bin/python
# -*- coding: utf-8 -*-

'''
战斗竞猜 (Battle Bet) - 跨服战斗竞猜活动
API接口处理

前端返回格式规范：
- model: 更新 gGameModel.role.yyhuodongs 数据
- view: 视图数据
'''

from framework.csv import csv, ErrDefs
from framework.log import logger

from game import ClientError
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import YYHuoDongDefs
from game.object.game.yyhuodong import ObjectYYBattleBet, ObjectYYContestBet, ObjectYYHuoDongFactory
from tornado.gen import coroutine


def getOpenYYID(activityType=YYHuoDongDefs.BattleBet):
	'''获取当前开放的竞猜活动ID'''
	for yyID in ObjectYYHuoDongFactory.OpenIDSet:
		if yyID not in csv.yunying.yyhuodong:
			continue
		cfg = csv.yunying.yyhuodong[yyID]
		if cfg.type == activityType:
			yyObj = ObjectYYHuoDongFactory.getConfig(yyID)
			if yyObj and yyObj.isOpen():
				return yyID
	return None


def getActivityClass(activityType):
	'''根据活动类型获取活动类'''
	if activityType == YYHuoDongDefs.ContestBet:
		return ObjectYYContestBet
	return ObjectYYBattleBet


# 战斗竞猜 主界面
class BattleBetMain(RequestHandlerTask):
	url = r'/game/yy/battlebet/main'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		if yyID is None:
			yyID = getOpenYYID(YYHuoDongDefs.BattleBet)
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)

		cfg = csv.yunying.yyhuodong[yyID]
		ActivityClass = getActivityClass(cfg.type)

		ActivityClass.refreshRecord(yyID, self.game)
		view = ActivityClass.getMainView(yyID, self.game)

		self.write({
			'view': view
		})


# 比赛竞猜 主界面
class ContestBetMain(RequestHandlerTask):
	url = r'/game/yy/contestbet/main'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		if yyID is None:
			yyID = getOpenYYID(YYHuoDongDefs.ContestBet)
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)

		ObjectYYContestBet.refreshRecord(yyID, self.game)
		view = ObjectYYContestBet.getMainView(yyID, self.game)

		self.write({
			'view': view
		})


# 战斗竞猜 比赛详情
class BattleBetContest(RequestHandlerTask):
	url = r'/game/yy/battlebet/contest'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		contestID = self.input.get('contestID', 0)
		onlyDanmu = self.input.get('onlyDanmu', False)

		if yyID is None:
			yyID = getOpenYYID(YYHuoDongDefs.BattleBet)
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)
		if not contestID:
			raise ClientError('contestID miss')

		cfg = csv.yunying.yyhuodong[yyID]
		ActivityClass = getActivityClass(cfg.type)

		view = ActivityClass.getContestView(yyID, self.game, contestID, onlyDanmu)
		if not view:
			raise ClientError('contest not found')

		self.write({
			'view': view
		})


# 战斗竞猜 下注
class BattleBetBet(RequestHandlerTask):
	url = r'/game/yy/battlebet/bet'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		contestID = self.input.get('contestID', 0)
		teamID = self.input.get('teamID', 0)
		num = self.input.get('num', 0)

		if yyID is None:
			yyID = getOpenYYID(YYHuoDongDefs.BattleBet)
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)
		if not contestID or not teamID or not num:
			raise ClientError('param miss')

		cfg = csv.yunying.yyhuodong[yyID]
		ActivityClass = getActivityClass(cfg.type)

		result = ActivityClass.bet(yyID, self.game, contestID, teamID, num)
		if not result:
			raise ClientError('bet failed')

		self.write({
			'view': result
		})


# 战斗竞猜 领取奖励
# 前端: showGainDisplay(tb)
class BattleBetAward(RequestHandlerTask):
	url = r'/game/yy/battlebet/award'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		awardType = self.input.get('awardType', 1)  # 1=下注奖励, 2=任务奖励
		csvID = self.input.get('csvID', 0)  # contestID 或 taskCsvID

		if yyID is None:
			yyID = getOpenYYID(YYHuoDongDefs.BattleBet)
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)

		cfg = csv.yunying.yyhuodong[yyID]
		ActivityClass = getActivityClass(cfg.type)

		if awardType == 1:
			# 下注奖励
			eff = ActivityClass.getBetAward(yyID, self.game, csvID)
		else:
			# 任务奖励
			eff = ActivityClass.getTaskAward(yyID, self.game, csvID)

		if not eff:
			raise ClientError('get award failed')

		yield effectAutoGain(eff, self.game, self.dbcGame, src='battlebet_award')

		self.write(eff.result)


# 战斗竞猜 发送弹幕
class BattleBetSend(RequestHandlerTask):
	url = r'/game/yy/battlebet/send'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		contestID = self.input.get('contestID', 0)
		content = self.input.get('content', '')

		if yyID is None:
			yyID = getOpenYYID(YYHuoDongDefs.BattleBet)
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)
		if not contestID or not content:
			raise ClientError('param miss')

		cfg = csv.yunying.yyhuodong[yyID]
		ActivityClass = getActivityClass(cfg.type)

		result = ActivityClass.sendDanmu(yyID, self.game, contestID, content)
		if not result:
			raise ClientError('send failed')

		self.write({
			'view': result
		})


# 战斗竞猜 战斗回放
class BattleBetPlayback(RequestHandlerTask):
	url = r'/game/yy/battlebet/playback'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		contestID = self.input.get('contestID', 0)

		if yyID is None:
			yyID = getOpenYYID(YYHuoDongDefs.BattleBet)
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)
		if not contestID:
			raise ClientError('contestID miss')

		# TODO: 实现战斗回放
		# 从跨服获取战斗记录
		self.write({
			'view': {
				'battle_id': None,
				'record': None,
			}
		})


# 战斗竞猜 购买代币
class BattleBetBuy(RequestHandlerTask):
	url = r'/game/yy/battlebet/buy'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		buyType = self.input.get('buyType', 'gold')  # gold 或 rmb
		num = self.input.get('num', 1)

		if yyID is None:
			yyID = getOpenYYID(YYHuoDongDefs.BattleBet)
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)

		cfg = csv.yunying.yyhuodong[yyID]
		ActivityClass = getActivityClass(cfg.type)

		eff = ActivityClass.buyToken(yyID, self.game, buyType, num)
		if not eff:
			raise ClientError('buy failed')

		yield effectAutoGain(eff, self.game, self.dbcGame, src='battlebet_buy')

		self.write({
			'view': {}
		})


# 战斗竞猜 排行榜
class BattleBetRank(RequestHandlerTask):
	url = r'/game/yy/battlebet/rank'

	@coroutine
	def run(self):
		yyID = self.input.get('yyID', None)
		offset = self.input.get('offset', 0)
		size = self.input.get('size', 50)

		if yyID is None:
			yyID = getOpenYYID(YYHuoDongDefs.BattleBet)
		if not yyID:
			raise ClientError(ErrDefs.huodongNoOpen)

		cfg = csv.yunying.yyhuodong[yyID]
		ActivityClass = getActivityClass(cfg.type)

		ranks, myRank = ActivityClass.getRankList(yyID, self.game, offset, size)

		self.write({
			'view': {
				'ranks': ranks,
				'myRank': myRank,
				'offset': offset,
				'size': size,
			}
		})
