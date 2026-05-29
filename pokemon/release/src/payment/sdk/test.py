#!/usr/bin/python
# -*- coding: utf-8 -*-

from framework.log import logger
from framework.helper import toUTF8Dict, objectid2string
from tornado.gen import coroutine, Return
from payment.sdk.base import SDKBase

import json
import time
import hashlib
import urlparse

class SDKTest(SDKBase):
	Channel = 'test'
	ReturnOK = 'success'
	ReturnErr = 'fail'

	@classmethod
	def parseData(cls, cfg, data):
		d = dict(urlparse.parse_qsl(data))
		logger.info('channel `{channel}` ch_account `{user_id}` status `{pay_status}` order `{out_trade_no}` {price} coming'.format(channel=cls.Channel, **d))
		
		# 签名验证
		validSign = '{game_order}{out_trade_no}{pay_extra}{pay_status}{price}{user_id}{secret}'.format(
			secret=cfg.get('appsecret', ''),
			**d
		)
		validSign = hashlib.md5(validSign).hexdigest()
		
		if validSign != d.get('sign', ''):
			logger.error('%s sign error, expected %s, got %s, data: %s', cls.Channel, validSign, d.get('sign', ''), data)
			raise Exception('sign error')
		
		return d

	@classmethod
	def getOrderID(cls, d):
		return d['out_trade_no']

	@classmethod
	def getOrderResult(cls, d):
		return True if int(d["pay_status"]) == 1 else False

	@classmethod
	def getClientInfo(cls, d):
		# game_order 格式: ["uid","rid","skey",pid,yyid,csvid]_timestamp
		# 需要去掉时间戳后缀
		game_order = d['game_order']
		if '_' in game_order:
			game_order = game_order.rsplit('_', 1)[0]
		return game_order

	@classmethod
	def getOrderAmount(cls, d):
		return d['price']

	@classmethod
	def getOrderErrMsg(cls, d):
		return ""

	@classmethod
	@coroutine
	def fetchChannelOrderID(cls, cfg, d, myOrderID):
		raise Exception('not implemented')

	@classmethod
	def makeReturnDict(cls, myOrderID, d):
		raise Exception('not implemented')
