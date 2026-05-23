#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
Copyright (c) 2016 TianJi Information Technology Inc.
'''
import binascii

from framework.service.rpc_client import nsqrpc_coroutine as rpc_coroutine
from nsqrpc.server import notify


class GMWebRPC(object):
	def __init__(self, server):
		self._server = server

	@property
	def server(self):
		return self._server

	@property
	def messageMap(self):
		return self._server.messageMap

	@notify
	def chatMessage(self, gameName, type, msg):
		# print gameName, type, msg
		# game\object\game\message.py
		# Msg = namedtuple('Msg', ('id', 't', 'msg', 'type', 'role', 'args'))
		t = msg[1]
		role = msg[4]
		
		# 跨服聊天时，使用 role['game_key'] 作为玩家实际所在服务器
		# 非跨服聊天时，使用接收消息的服务器 gameName
		actualGameName = role.get('game_key', gameName) if isinstance(role, dict) else gameName
		
		# 处理 role['id'] 可能为 None 或已经是字符串的情况
		roleID = role.get('id') if isinstance(role, dict) else role['id']
		if roleID is None:
			roleIDHex = ''
		elif isinstance(roleID, str):
			roleIDHex = binascii.hexlify(roleID) if len(roleID) == 12 else roleID
		else:
			roleIDHex = binascii.hexlify(roleID)
		
		data = {
			'gameName': gameName,  # 接收消息的服务器
			'sourceGame': actualGameName,  # 发送者实际所在服务器（跨服聊天用）
			'type': type,
			'time': t,
			'msg': msg[2],
			'roleID': roleIDHex,
			'roleName': role.get('name', '') if isinstance(role, dict) else role['name'],
			'roleLevel': role.get('level', 0) if isinstance(role, dict) else role['level'],
			'roleVIP': role.get('vip', 0) if isinstance(role, dict) else role['vip'],
		}

		que = self.messageMap['All']
		que.appendleft(data)
		while len(que) > 0:
			if t - que[-1]['time'] > 24*3600:
				que.pop()
			else:
				break


