#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Copyright (c) 2014 YouMi Information Technology Inc.

game server config defines
"""

from datetime import datetime

from nsq_defines import *

ServerDefs = {
    'game.cn.1': {
        'ip': '122.51.27.223',
        'port': 29001,
        'nsq': CNNSQDefs,
        'shushu': True,
        'open_date': datetime(2025, 7, 11, 10),
        'dependent': [
            'anticheat',
            'chat_monitor',
            "giftdb.cn.1",
            "card_comment.cn.1",
            "card_score.cn.1",
        ],
    },
    'game.cn.2': {
        'ip': '122.51.27.223',
        'port': 29002,
        'nsq': CNNSQDefs,
        'shushu': True,
        'open_date': datetime(2025, 7, 11, 10),
        'dependent': [
            'anticheat',
            'chat_monitor',
            "giftdb.cn.1",
            "card_comment.cn.1",
            "card_score.cn.1",
        ],
    },
	'gamemerge.cn.1': {
		'ip': '122.51.27.223',
		'port': 28876,
		'debug': True,
		'shushu': True,
		'nsq': CNNSQDefs,
		'open_date': datetime(2020, 1, 1, 10),
		'merged': True,
		'alias': ['game.cn.1', 'game.cn.2'],
		'dependent': [
			'anticheat',
			'chat_monitor',
			'giftdb.cn.1',
			'commentdb.cn.1',
			'crossdb.cn.1',
		],
	},
}


if __name__ == "__main__":
    import json
    servers = []
    for key in sorted(ServerDefs.keys()):
        cfg = ServerDefs[key]
        if 'alias' in cfg:
            for k in cfg['alias']:
                servers.append({
                    'key': k,
                    'addr': '%s:%d' % (cfg['ip'], cfg['port']),
                    'open_date': cfg['open_date'].strftime('%%Y-%%m-%%d %%H:%%M:%%S'),
                })
        else:
            servers.append({
                'key': key,
                'addr': '%s:%d' % (cfg['ip'], cfg['port']),
                'open_date': cfg['open_date'].strftime('%%Y-%%m-%%d %%H:%%M:%%S'),
            })
    servers = sorted(servers, key=lambda x:x['key'])
    with open('./login/conf/game.json', 'w') as fp:
        json.dump(servers, fp, sort_keys=True, indent=2)
