#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

server config defines
'''

from nsq_defines import *


ServerDefs = {
	'gm.cn.1': {
		'key': 'gm.cn.1',
		'game_key_prefix': ['game.cn.', 'gamemerge.cn.'],
		'statistic_scope': ['tc',],
		'nsq': CNNSQDefs,
		'http_port': 38088,
		'dependent': 	[
			'accountdb.cn.1',
			'giftdb.cn.1',
			'card_comment.cn.1',
			# 跨服竞技场 (1-10)
			'crossarena.cn.1',
			'crossarena.cn.2',
			'crossarena.cn.3',
			'crossarena.cn.4',
			'crossarena.cn.5',
			'crossarena.cn.6',
			'crossarena.cn.7',
			'crossarena.cn.8',
			'crossarena.cn.9',
			'crossarena.cn.10',
			# 跨服石英大会 (1-10)
			'crosscraft.cn.1',
			'crosscraft.cn.2',
			'crosscraft.cn.3',
			'crosscraft.cn.4',
			'crosscraft.cn.5',
			'crosscraft.cn.6',
			'crosscraft.cn.7',
			'crosscraft.cn.8',
			'crosscraft.cn.9',
			'crosscraft.cn.10',
			# 跨服道馆 (1-10)
			'crossgym.cn.1',
			'crossgym.cn.2',
			'crossgym.cn.3',
			'crossgym.cn.4',
			'crossgym.cn.5',
			'crossgym.cn.6',
			'crossgym.cn.7',
			'crossgym.cn.8',
			'crossgym.cn.9',
			'crossgym.cn.10',
			# 跨服资源战 (1-10)
			'crossmine.cn.1',
			'crossmine.cn.2',
			'crossmine.cn.3',
			'crossmine.cn.4',
			'crossmine.cn.5',
			'crossmine.cn.6',
			'crossmine.cn.7',
			'crossmine.cn.8',
			'crossmine.cn.9',
			'crossmine.cn.10',
			# 跨服实时对战 (1-10)
			'onlinefight.cn.1',
			'onlinefight.cn.2',
			'onlinefight.cn.3',
			'onlinefight.cn.4',
			'onlinefight.cn.5',
			'onlinefight.cn.6',
			'onlinefight.cn.7',
			'onlinefight.cn.8',
			'onlinefight.cn.9',
			'onlinefight.cn.10',
			# 跨服部屋 (1-10)
			'crossunionfight.cn.1',
			'crossunionfight.cn.2',
			'crossunionfight.cn.3',
			'crossunionfight.cn.4',
			'crossunionfight.cn.5',
			'crossunionfight.cn.6',
			'crossunionfight.cn.7',
			'crossunionfight.cn.8',
			'crossunionfight.cn.9',
			'crossunionfight.cn.10',
			# 跨服匹配（拟态对战也通过 crossmatch 触发）
			'crossmatch.cn.1',
			# 跨服聊天 (1-10)
			'crosschat.cn.1',
			'crosschat.cn.2',
			'crosschat.cn.3',
			'crosschat.cn.4',
			'crosschat.cn.5',
			'crosschat.cn.6',
			'crosschat.cn.7',
			'crosschat.cn.8',
			'crosschat.cn.9',
			'crosschat.cn.10',
		],
		'mongo': {
			'host': 'mongodb://root:GpFkU9O24cjhnWco@127.0.0.1:27017',
			'port': 27017,
			'dbname': 'gm_web'
		},
		'account_mongo': {
			'host': 'mongodb://root:GpFkU9O24cjhnWco@127.0.0.1:27017',
			'port': 27017,
			'dbname': 'account'
		},
		'payorder_mongo': {
			'host': 'mongodb://root:GpFkU9O24cjhnWco@127.0.0.1:27017',
			'port': 27017,
			'dbname': 'payorder'
		},
		'gift_mongo': {
			'host': 'mongodb://root:GpFkU9O24cjhnWco@127.0.0.1:27017',
			'port': 27017,
			'dbname': 'gift'
		},
		'gm_stat': 'http://127.0.0.1:9991',
		'login_log_path': '/mnt/deploy_dev/childlog',
		'debug': False,
	}
}

