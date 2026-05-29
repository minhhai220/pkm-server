#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

The WSGIApplication Handlers

HTTP Method 与 CURD 数据处理操作对应
HTTP方法 	数据处理 	说明
POST 		Create 		新增一个没有id的资源
GET 		Read 		取得一个资源
PUT 		Update 		更新一个资源。或新增一个含 id 资源(如果 id 不存在)
DELETE 		Delete 		删除一个资源
现在不采用CURD方式
'''
from __future__ import absolute_import

from game.handler.task import RequestHandlerTask

import game.handler._account
import game.handler._game
import game.handler._role
import game.handler._card
import game.handler._equip
import game.handler._pvp
import game.handler._lottery
import game.handler._huodong
import game.handler._yyhuodong
import game.handler._union
import game.handler._society
import game.handler._chat
import game.handler._clone
import game.handler._craft
import game.handler._union_fight
import game.handler._cross_craft
import game.handler._endlesstower
import game.handler._trainer
import game.handler._helditem
import game.handler._dispatch_task
import game.handler._explorer
import game.handler._randomTower
import game.handler._hellRandomTower
import game.handler._mimicry
import game.handler._totem
import game.handler._gem
import game.handler._cross_arena
import game.handler._fishing
import game.handler._develop_mega
import game.handler._cross_online_fight
import game.handler._gym
import game.handler._badge
import game.handler._cross_mine
import game.handler._daily_assistant
import game.handler._hunting
import game.handler._chip
import game.handler._emera
import game.handler._brave_challenge
import game.handler._cross_union_fight
import game.handler._cross_union_adventure
import game.handler._contract
import game.handler._aid
import game.handler._meteorite
import game.handler._cross_supremacy
import game.handler._town
import game.handler._transfer
import game.handler._auto_chess
import sys
modules = [
	sys.modules['game.handler._account'],
	sys.modules['game.handler._game'],
	sys.modules['game.handler._role'],
	sys.modules['game.handler._card'],
	sys.modules['game.handler._equip'],
	sys.modules['game.handler._pvp'],
	sys.modules['game.handler._lottery'],
	sys.modules['game.handler._huodong'],
	sys.modules['game.handler._yyhuodong'],
	sys.modules['game.handler._union'],
	sys.modules['game.handler._society'],
	sys.modules['game.handler._chat'],
	sys.modules['game.handler._clone'],
	sys.modules['game.handler._craft'],
	sys.modules['game.handler._union_fight'],
	sys.modules['game.handler._cross_craft'],
	sys.modules['game.handler._endlesstower'],
	sys.modules['game.handler._trainer'],
	sys.modules['game.handler._helditem'],
	sys.modules['game.handler._dispatch_task'],
	sys.modules['game.handler._explorer'],
	sys.modules['game.handler._randomTower'],
	sys.modules['game.handler._hellRandomTower'],
	sys.modules['game.handler._mimicry'],
	sys.modules['game.handler._totem'],
	sys.modules['game.handler._gem'],
	sys.modules['game.handler._cross_arena'],
	sys.modules['game.handler._fishing'],
	sys.modules['game.handler._develop_mega'],
	sys.modules['game.handler._cross_online_fight'],
	sys.modules['game.handler._gym'],
	sys.modules['game.handler._badge'],
	sys.modules['game.handler._cross_mine'],
	sys.modules['game.handler._daily_assistant'],
	sys.modules['game.handler._hunting'],
	sys.modules['game.handler._chip'],
	sys.modules['game.handler._emera'],
	sys.modules['game.handler._brave_challenge'],
	sys.modules['game.handler._cross_union_fight'],
	sys.modules['game.handler._cross_union_adventure'],
	sys.modules['game.handler._contract'],
	sys.modules['game.handler._aid'],
	sys.modules['game.handler._meteorite'],
	sys.modules['game.handler._cross_supremacy'],
	sys.modules['game.handler._town'],
	sys.modules['game.handler._transfer'],
	sys.modules['game.handler._auto_chess'],
]

handlers = {}

from framework.log import logger
import re
pattern = re.compile(ur'^/game/[0-9a-z_/]+$')

def _makeUrlHandlersMap():
	for m in modules:
		for x in dir(m):
			cls = getattr(m, x)
			if type(cls) == type and issubclass(cls, RequestHandlerTask) and hasattr(cls, 'url'):
				if cls.url and not pattern.search(str(cls.url)):
					logger.warning('url %s nonstandard', cls.url)
				handlers[cls.url] = cls

_makeUrlHandlersMap()

def loadExtraHandlers():
	import game.handler._game2
	import game.handler._cross_auto_chess

	dynamic_modules = [
		sys.modules['game.handler._game2'],
		sys.modules['game.handler._cross_auto_chess'],
	]

	for m in dynamic_modules:
		for x in dir(m):
			cls = getattr(m, x)
			if type(cls) == type and issubclass(cls, RequestHandlerTask) and hasattr(cls, 'url'):
				if cls.url and not pattern.search(str(cls.url)):
					logger.warning('url %s nonstandard', cls.url)
				handlers[cls.url] = cls

