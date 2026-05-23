#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.

nsq default config defines
'''

CNNSQDefs = {
	'reader': {
		'max_in_flight': 10000,
		'nsqd_tcp_addresses': ['127.0.0.1:4150'],
		'output_buffer_size': 16 * 1024, # default 16kb
		'output_buffer_timeout': 25, # default 250ms
	},
	'writer': {
		'reconnect_interval': 5.0,
		'nsqd_tcp_addresses': ['127.0.0.1:4150'],
	},
}