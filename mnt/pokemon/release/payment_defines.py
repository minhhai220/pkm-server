#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

server config defines
'''

from nsq_defines import *

PayNotifyHost = 'http://122.51.27.223:28081'

ServerDefs = {
	################
	# 'payment.cn.1': {
	# 	'key': 'payment.cn.1',
	# 	'port': 28081,
	# 	'nsq': CNNSQDefs,
	# 	'game_key_prefix' : ['game.cn.', "game.cn_qd.", "game.cn_ly1."],
	# 	'dependent': [
	# 		'paymentdb.cn.1',
	# 		'giftdb.cn.1',
	# 		'game.cn.1',
	# 	],
	# },

	'payment.cn.1': {
		'key': 'payment.cn.1',
		'port': 28081,
		'nsq': CNNSQDefs,
		'game_key_prefix' : ['game.cn.'],
		'dependent': [
			'paymentdb.cn.1',
			'giftdb.cn.1'
            'game.cn.1',
            'game.cn.2',
		],
	}
}

