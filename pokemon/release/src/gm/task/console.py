#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework.log import logger
from gm.task import RPCTaskFactory, GMTaskError, gmrpc_coroutine, gmrpc_log_coroutine

from game.globaldata import GameServInternalPassword

from tornado.gen import Return, coroutine
from tornado.ioloop import PeriodicCallback, IOLoop

import datetime
import json

GMServerVersion = 6
GlobalServerKey = '__@global@__'


class TConsoleFactory(RPCTaskFactory):
	PeriodicMessage = None

	# 不提供服务了
	# def _hello(self, data):
	# 	return GMTaskReturn('GMServer say hello')

	# @rpc_coroutine
	# def gmLogin(self, inl_pwd, name, passMD5):
	# 	if inl_pwd != GameServInternalPassword:
	# 		raise Return(GMTaskError('auth_error'))

	# 	ret = yield self.dbcGM.call_async('GMLogin', name, passMD5)
	# 	if not ret['ret']:
	# 		raise Return(GMTaskError(ret['err']))
	# 	model = ret['model']
	# 	# print model

	# 	sessionID = self.server.login(name, model['permission_level'])
	# 	logger.info('`%s` login, %s, %d' % (name, sessionID, model['permission_level']))
	# 	raise Return(GMTaskReturn((sessionID, model['permission_level'], GMServerVersion)))

	@gmrpc_coroutine
	def gmGetGameServers(self):
		ret = []
		for name, rpc in self.gameAllRPCs.iteritems():
			ret.append((name, ('111.111.111.111', 1111), not rpc.isLost()))
		raise Return(ret)

	@gmrpc_coroutine
	def gmGetGameServerStatus(self, name=None):
		raise Return(GMTaskReturn({}))

		if name is None:
			ret = {}
			for name, rpc in self.gameAllRPCs.iteritems():
				if not rpc.ackOK:
					continue
				ret[name] = rpc.call_async('gmGetServerStatus')

			for key, fu in ret.iteritems():
				try:
					ret2 = yield fu
				except Exception, e:
					ret2 = str(e)
				ret[key] = ret2

			raise Return(ret)
		else:
			if name not in self.gameAllRPCs:
				raise GMTaskError('no this server name')
			else:
				ret = yield self.gameAllRPCs[name].call_async('gmGetServerStatus')
				raise Return(ret)

	@gmrpc_coroutine
	def gmGetGameMachineStatus(self, name=None):
		if name is None:
			ret = {}
			for name, rpc in self.gameAllRPCs.iteritems():
				if not rpc.ackOK:
					continue
				try:
					ret[name] = rpc.call_async('gmGetMachineStatus')
				except:
					pass

			for key, fu in ret.iteritems():
				try:
					ret2 = yield fu
				except Exception, e:
					ret2 = str(e)
				ret[key] = ret2

			raise Return(ret)
		else:
			if name not in self.gameAllRPCs:
				raise GMTaskError('no this server name')
			else:
				ret = yield self.gameAllRPCs[name].call_async('gmGetMachineStatus')
				raise Return(ret)

	@gmrpc_coroutine
	def gmGetGameAccountStatus(self, name=None):
		if name is None:
			ret = {}
			for name, rpc in self.gameAllRPCs.iteritems():
				try:
					ret[name] = rpc.call_async('gmGetAccountStatus')
				except:
					pass

			for key, fu in ret.iteritems():
				try:
					ret2 = yield fu
				except Exception, e:
					ret2 = str(e)
				ret[key] = ret2

			raise Return(ret)
		else:
			if name not in self.gameAllRPCs:
				raise GMTaskError('no this server name')
			else:
				ret = yield self.gameAllRPCs[name].call_async('gmGetAccountStatus')
				raise Return(ret)

	@gmrpc_log_coroutine
	def gmGC(self, name):
		if name not in self.gameAllRPCs:
			ret = []
			for name, rpc in self.gameAllRPCs.iteritems():
				try:
					fu = self.gameAllRPCs[name].call_async('gmGC')
					ret.append((name, fu))
				except:
					pass

			for i, t in enumerate(ret):
				name, fu = t
				try:
					ret2 = yield fu
				except Exception, e:
					ret2 = str(e)
				ret[i] = (name, ret2)

			raise Return(ret)
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGC')
			raise Return(ret)

	@gmrpc_coroutine
	def gmGetGameYYComfig(self, name=None):
		if name is None:
			ret = {}
			for name, rpc in self.gameAllRPCs.iteritems():
				try:
					ret[name] = yield rpc.call_async('gmGetYYComfig')
				except:
					pass
			raise Return(ret)
		else:
			if name not in self.gameAllRPCs:
				raise GMTaskError('no this server name')
			else:
				ret = yield self.gameAllRPCs[name].call_async('gmGetYYComfig')
				raise Return(ret)

	@gmrpc_log_coroutine
	def gmSetGameYYComfig(self, db, name=None):
		if name is None:
			ret = {}
			for name, rpc in self.gameAllRPCs.iteritems():
				try:
					ret[name] = yield rpc.call_async('gmSetYYComfig', db)
				except:
					pass
			raise Return(ret)
		else:
			if name not in self.gameAllRPCs:
				raise GMTaskError('no this server name')
			else:
				ret = yield self.gameAllRPCs[name].call_async('gmSetYYComfig', db)
				raise Return(ret)

	@gmrpc_coroutine
	def gmGetGameOnlineRoles(self, name, offest=0, size=100):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetOnlineRoles', offest, size)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmRefreshCSV(self, name=GlobalServerKey):
		ret = []
		if name == GlobalServerKey:
			fus = []
			for name, rpc in self.gameRPCs.iteritems():
				try:
					fus.append((name, rpc.call_async('gmRefreshCSV')))
					logger.info('server `%s` refresh csv' % (name))
				except Exception, e:
					logger.exception('server `%s` refresh csv exception' % (name))

			for name, fu in fus:
				try:
					one = yield fu
					ret.append((name, one[1]))
				except Exception, e:
					ret.append((name, str(e)))
		else:
			try:
				one = yield self.gameAllRPCs[name].call_async('gmRefreshCSV')
				ret.append((name, one[1]))
			except:
				pass
			logger.info('server `%s` refresh csv' % (name))

		raise Return(ret)

	@gmrpc_coroutine
	def gmGenRobots(self, name):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGenRobots')
			raise Return(ret)

	@gmrpc_coroutine
	def gmGetMailCsv(self, name):
		if name not in self.gameAllRPCs:
			from framework.csv import csv
			csv.reload()
			raise Return(csv.mail.to_dict())
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetMailCsv')
			raise Return(ret)

	@gmrpc_coroutine
	def gmGetRoleInfo(self, name, roleID):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetRoleInfo', roleID)
			if 'account_id' in ret:
				ret2 = yield self.dbcAccount.call_async('AccountQuery', ret['account_id'])
				if ret2['ret']:
					ret['account_name'] = ret2['model']['name']
					ret['account_roles'] = ret2['model']['role_infos']
			raise Return(ret)

	@gmrpc_coroutine
	def gmGetRoleInfoByName(self, name, roleName):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetRoleInfoByName', roleName)
			if 'account_id' in ret:
				ret2 = yield self.dbcAccount.call_async('AccountQuery', ret['account_id'])
				if ret2['ret']:
					ret['account_name'] = ret2['model']['name']
					ret['account_roles'] = ret2['model']['role_infos']

			elif roleName.find('_') > 0:
				# 用渠道id查询
				ret2 = yield self.dbcAccount.call_async('AccountQueryByName', roleName)
				if ret2['ret']:
					ret = yield self.gameAllRPCs[name].call_async('gmGetRoleInfoByAccountID', ret2['model']['id'])
					if 'account_id' in ret:
						ret['account_name'] = ret2['model']['name']
						ret['account_roles'] = ret2['model']['role_infos']


			raise Return(ret)

	@gmrpc_coroutine
	def gmGetRoleInfoByVip(self, name, vipBegin, vipEnd):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetRoleInfoByVip', vipBegin, vipEnd)
			simpleRet = [  {'account_id':x['account_id'],
							'name':x['name'],
							'vip_level':x['vip_level'],
							'rmb_consume':x['rmb_consume'],
							'id':x['id'],
							} for x in ret]
			raise Return(simpleRet)

	@gmrpc_coroutine
	def gmGetUnionInfo(self, name, roleID):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetUnionInfo', roleID)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmSendMessage(self, name, type, arg, msg, ptime):
		if self.PeriodicMessage:
			self.PeriodicMessage.stop()
			self.PeriodicMessage = None

		@coroutine
		def send(name, type, arg, msg):
			if name not in self.gameAllRPCs:
				ret = []
				for name, rpc in self.gameAllRPCs.iteritems():
					try:
						ret2 = yield self.gameAllRPCs[name].call_async('gmSendMessage', type, arg, msg)
						ret.append((name, ret2))
					except Exception, e:
						ret.append((name, str(e)))
				raise Return(ret)
			else:
				ret = yield self.gameAllRPCs[name].call_async('gmSendMessage', type, arg, msg)
				raise Return(ret)

		if ptime > 0:
			import functools
			self.PeriodicMessage = PeriodicCallback(functools.partial(send, name, type, arg, msg), ptime * 1000 * 3600)
			self.PeriodicMessage.start()

		ret = yield send(name, type, arg, msg)
		raise Return(ret)

	@gmrpc_log_coroutine
	def gmSendMail(self, name, roleID, mailType, sender, subject, content, attachs):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmSendMail', roleID, mailType, sender, subject, content, attachs)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmSendGlobalMail(self, name, mailType, sender, subject, content, attachs):
		if name == GlobalServerKey:
			ret = []
			for name, rpc in self.gameRPCs.iteritems():
				try:
					ret2 = yield self.gameRPCs[name].call_async('gmSendGlobalMail', mailType, sender, subject, content, attachs)
					logger.info('gmSendGlobalMail %s', name)
					ret.append((name, ret2))
				except Exception, e:
					ret.append((name, str(e)))
			raise Return(ret)
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmSendGlobalMail', mailType, sender, subject, content, attachs)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmSendServerMail(self, name, mailType, sender, subject, content, attachs):
		if name == GlobalServerKey:
			ret = []
			for name, rpc in self.gameRPCs.iteritems():
				try:
					ret2 = yield self.gameRPCs[name].call_async('gmSendServerMail', mailType, sender, subject, content, attachs)
					logger.info('gmSendServerMail %s', name)
					ret.append((name, ret2))
				except Exception, e:
					ret.append((name, str(e)))
			raise Return(ret)
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmSendServerMail', mailType, sender, subject, content, attachs)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmSendVipMail(self, name, beginVip, endVip, mailType, sender, subject, content, attachs):
		if name == GlobalServerKey:
			ret = []
			for name, rpc in self.gameRPCs.iteritems():
				try:
					ret2 = yield self.gameRPCs[name].call_async('gmSendVipMail', beginVip, endVip, mailType, sender, subject, content, attachs)
					logger.info('gmSendVipMail %s', name)
					ret.append((name, ret2))
				except Exception, e:
					ret.append((name, str(e)))
			raise Return(ret)
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmSendVipMail', beginVip, endVip, mailType, sender, subject, content, attachs)
			raise Return(ret)

	# # 根据用户ID集合，发送邮件
	# @gmrpc_log_coroutine
	# def gmSendMailByGroup(self, name, roleIDs, mailType, sender, subject, content, attachs):
	# 	if name not in self.gameAllRPCs:
	# 		raise Return(GMTaskError('no this server name'))
	# 	else:
	# 		for roleID in roleIDs:
	# 			roleID = int(roleID)
	# 			ret = yield self.gameAllRPCs[name].call_async('gmSendMail', roleID, mailType, sender, subject, content, attachs)
	# 		raise Return(GMTaskReturn(ret))

	@gmrpc_log_coroutine
	def gmSendUnionMail(self, name, unionID, mailType, sender, subject, content, attachs):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmSendUnionMail', unionID, mailType, sender, subject, content, attachs)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmSendNewbieMail(self, name, accountName, mailType, sender, subject, content, attachs):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmSendNewbieMail', accountName, mailType, sender, subject, content, attachs)
			raise Return(ret)

	testGiftCsv = None
	@gmrpc_coroutine
	def gmGetGiftCsv(self):
		if not self.testGiftCsv:
			from framework.csv import csv
			csv.reload()
			self.testGiftCsv = csv.gift.to_dict()
		raise Return(self.testGiftCsv)

	@gmrpc_coroutine
	def gmGenGift(self, giftID, size, opts=[]):
		ret = yield self.dbcGift.call_async('GiftGen', giftID, size, opts)
		raise Return(ret)

	@gmrpc_coroutine
	def gmOpenRPDB(self, name):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmOpenRPDB')
			raise Return(ret)

	@gmrpc_coroutine
	def gmCloseRPDB(self, name):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmCloseRPDB')
			raise Return(ret)

	@gmrpc_coroutine
	def gmFlushDB(self, name):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmFlushDB')
			raise Return(ret)

	@gmrpc_coroutine
	def gmCommitDB(self, name):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmCommitDB')
			raise Return(ret)

	@gmrpc_coroutine
	def gmExecPy(self, src, name=GlobalServerKey):
		ret = []
		if name == GlobalServerKey:
			fus = []
			for name, rpc in self.gameRPCs.iteritems():
				try:
					fus.append((name, rpc.call_async('gmExecPy', src)))
				except Exception, e:
					logger.exception('server `%s` execpy %s exception' % ret[-1])
				logger.info('server `%s` execpy' % name)

			for name, fu in fus:
				try:
					ret2 = yield fu
					ret.append((name, ret2))
				except Exception, e:
					ret.append((name, str(e)))

		else:
			ret = yield self.gameAllRPCs[name].call_async('gmExecPy', src)
			ret = [(name, ret)]
			logger.info('server `%s` execpy' % name)

		raise Return(ret)

	@gmrpc_coroutine
	def gmReloadAuto(self, name):
		ret = []
		if name == GlobalServerKey:
			fus = []
			for name, rpc in self.gameRPCs.iteritems():
				try:
					fus.append((name, rpc.call_async('gmReloadAuto')))
				except Exception, e:
					logger.exception('server `%s` reload %s exception' % ret[-1])
				logger.info('server `%s` reload py' % name)

			for name, fu in fus:
				try:
					ret2 = yield fu
					ret.append((name, ret2))
				except Exception, e:
					ret.append((name, str(e)))

		else:
			ret = yield self.gameAllRPCs[name].call_async('gmReloadAuto')
			ret = [(name, ret)]
			logger.info('server `%s` reload' % name)

		raise Return(ret)

	@gmrpc_coroutine
	def gmReloadPyFiles(self, name, srcs):
		ret = []
		if name == GlobalServerKey:
			fus = []
			for name, rpc in self.gameRPCs.iteritems():
				try:
					fus.append((name, rpc.call_async('gmReloadPyFiles', srcs)))
				except Exception, e:
					logger.exception('server `%s` reload %s exception' % ret[-1])
				logger.info('server `%s` reload py' % name)

			for name, fu in fus:
				try:
					ret2 = yield fu
					ret.append((name, ret2))
				except Exception, e:
					ret.append((name, str(e)))

		else:
			ret = yield self.gameAllRPCs[name].call_async('gmReloadPyFiles', srcs)
			ret = [ret]
			logger.info('server `%s` reload' % name)

		raise Return(ret)

	@gmrpc_coroutine
	def gmGetGameRank(self, name, rtype):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetGameRank', rtype)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmSetSessionCapacity(self, name, capacity):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmSetSessionCapacity', capacity)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmRoleAbandon(self, name, roleID, type, val):
		# 这个接口的roleID目前只能是24位的id，没有支持uid，需要加
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmRoleAbandon', roleID, type, val)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmKickPlayer(self, name, roleID):
		'''踢单个玩家下线'''
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmKickPlayer', roleID)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmKickAllPlayers(self, name):
		'''踢所有在线玩家下线'''
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmKickAllPlayers')
			raise Return(ret)

	# ==================== 内存数据查看器 ====================

	@gmrpc_coroutine
	def gmGetPlayerMemoryData(self, name, roleID, modules=None):
		'''获取玩家内存数据'''
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		ret = yield self.gameAllRPCs[name].call_async('gmGetPlayerMemoryData', roleID, modules)
		raise Return(ret)

	@gmrpc_coroutine
	def gmGetPlayerDBData(self, name, roleID, modules=None):
		'''获取玩家数据库数据'''
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		ret = yield self.gameAllRPCs[name].call_async('gmGetPlayerDBData', roleID, modules)
		raise Return(ret)

	@gmrpc_coroutine
	def gmComparePlayerData(self, name, roleID):
		'''对比玩家内存和数据库数据'''
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		ret = yield self.gameAllRPCs[name].call_async('gmComparePlayerData', roleID)
		raise Return(ret)

	@gmrpc_log_coroutine
	def gmForceSavePlayer(self, name, roleID, modules=None):
		'''强制保存玩家数据'''
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		ret = yield self.gameAllRPCs[name].call_async('gmForceSavePlayer', roleID, modules)
		raise Return(ret)

	@gmrpc_log_coroutine
	def gmScanDataAnomalies(self, name, scanType='all', limit=100):
		'''扫描在线玩家数据异常'''
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		ret = yield self.gameAllRPCs[name].call_async('gmScanDataAnomalies', scanType, limit)
		raise Return(ret)

	@gmrpc_log_coroutine
	def gmRoleModify(self, name, roleID, key, val):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmRoleModify', roleID, key, val)
			raise Return(ret)

	@gmrpc_coroutine
	def gmRejudgePVPPlay(self, name, playID, forceAll=False):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmRejudgePVPPlay', playID, forceAll)
			raise Return(ret)

	@coroutine
	def gmGetRoleCards(self, name, roleID, cardIDs):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('GMGetRoleCards', roleID, cardIDs)
			raise Return(ret)

	@coroutine
	def gmEvalCardAttrs(self, name, roleID, cardID, disables):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('GMEvalCardAttrs', roleID, cardID, disables)
			raise Return(ret)

	@gmrpc_coroutine
	def gmGetGameBlackList(self):
		ret = self.server.blackListMap.getIP()
		raise Return(ret)

	@gmrpc_log_coroutine
	def gmAddGameBlackList(self, ipL):
		yield self.server.blackListMap.addIP(ipL)
		ret = yield self.server.blackListMap.push()
		ret.update(self.server.blackListMap.getIP())
		raise Return(GMTaskReturn(ret))

	@gmrpc_log_coroutine
	def gmDelGameBlackList(self, idL):
		yield self.server.blackListMap.deleteIP(idL)
		ret = yield self.server.blackListMap.push()
		ret.update(self.server.blackListMap.getIP())
		raise Return(GMTaskReturn(ret))

	@gmrpc_log_coroutine
	# 手动刷新
	def gmPushGameBlackList(self):
		ret = yield self.server.blackListMap.push()
		ret.update(self.server.blackListMap.getIP())
		raise Return(GMTaskReturn(ret))

	@gmrpc_coroutine
	def gmGetMailCsv(self, name):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetMailCsv')
			raise Return(ret)

	@gmrpc_coroutine
	def gmGetUnionInfo(self, name, unionID):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetUnionInfo', unionID)
			raise Return(ret)

	@gmrpc_coroutine
	def gmGetRoleInfoByVip(self, name, beginVip, endVip):
		if name not in self.gameAllRPCs:
			raise GMTaskError('no this server name')
		else:
			ret = yield self.gameAllRPCs[name].call_async('gmGetRoleInfoByVip', beginVip, endVip)
			raise Return(ret)

	@gmrpc_log_coroutine
	def gmStartCrossService(self, serviceKey):
		'''手动触发指定跨服服务（强制模式，跳过日期检查）'''
		crossServices = self.server.crossServices
		
		# [拟态对战] 拟态对战通过 crossmatch 触发
		if serviceKey.startswith('crossmimicry'):
			# 从 serviceKey 提取 channel，如 crossmimicry.cn.1 -> cn
			parts = serviceKey.split('.')
			channel = parts[1] if len(parts) > 1 else 'cn'
			crossmatchKey = 'crossmatch.%s.1' % channel
			
			if crossmatchKey not in crossServices:
				raise GMTaskError('%s 未连接！请确认 crossmatch 服务已启动。' % crossmatchKey)
			
			service = crossServices[crossmatchKey]
			try:
				ret = yield service.call_async_timeout('GMForceCrossMimicry', 30)
				logger.info('gmStartCrossService %s (via %s) result: %s', serviceKey, crossmatchKey, ret)
			except Exception, e:
				logger.warning('gmStartCrossService %s failed: %s', serviceKey, str(e))
				raise GMTaskError('拟态对战触发失败：%s' % str(e))
			
			if ret:
				raise Return({'result': True, 'message': '拟态对战触发成功！跨服匹配已启动。'})
			else:
				raise Return({'result': False, 'message': '拟态对战触发失败：当前轮次尚未结束或无有效服务器。'})

		# [跨服冠军赛] 通过 crossmatch 触发
		if serviceKey.startswith('crosssupremacy'):
			parts = serviceKey.split('.')
			channel = parts[1] if len(parts) > 1 else 'cn'
			crossmatchKey = 'crossmatch.%s.1' % channel

			if crossmatchKey not in crossServices:
				raise GMTaskError('%s 未连接！请确认 crossmatch 服务已启动。' % crossmatchKey)

			service = crossServices[crossmatchKey]
			try:
				ret = yield service.call_async_timeout('GMForceCrossSupremacy', 30, channel)
				logger.info('gmStartCrossService %s (via %s) result: %s', serviceKey, crossmatchKey, ret)
			except Exception, e:
				logger.warning('gmStartCrossService %s failed: %s', serviceKey, str(e))
				raise GMTaskError('跨服冠军赛触发失败：%s' % str(e))

			if ret:
				raise Return({'result': True, 'message': '跨服冠军赛触发成功！跨服匹配已启动。'})
			else:
				raise Return({'result': False, 'message': '跨服冠军赛触发失败：当前轮次尚未结束或无有效服务器。'})
		
		# 其他跨服服务
		if serviceKey not in crossServices:
			raise GMTaskError('%s 未连接！请确认跨服服务已启动，并检查 gm_defines.py 中的 dependent 配置。' % serviceKey)
		
		service = crossServices[serviceKey]
		try:
			# 使用 GMForceServiceCheck，跳过日期检查，立即返回
			ret = yield service.call_async_timeout('GMForceServiceCheck', 30)
			logger.info('gmStartCrossService %s result: %s', serviceKey, ret)
		except Exception, e:
			logger.warning('gmStartCrossService %s failed: %s', serviceKey, str(e))
			errMsg = str(e)
			if 'timed out' in errMsg.lower() or 'timeout' in errMsg.lower():
				raise GMTaskError('%s 请求超时！可能原因：1) 跨服服务未启动 2) 跨服服务正在处理其他请求 3) 网络问题。请检查跨服服务日志。' % serviceKey)
			elif 'not connected' in errMsg.lower():
				raise GMTaskError('%s 连接失败！跨服服务可能已断开，请检查跨服服务是否正常运行。' % serviceKey)
			else:
				raise GMTaskError('%s 触发失败：%s' % (serviceKey, errMsg))
		
		# Go 返回 bool
		if ret:
			raise Return({'result': True, 'message': '%s 触发成功！跨服匹配已启动。' % serviceKey})
		else:
			raise Return({
				'result': False, 
				'message': '%s 触发失败：当前跨服轮次尚未结束，无法启动新的一轮。请等待当前轮次结束后再试，或联系技术人员强制结束当前轮次。' % serviceKey
			})

	@gmrpc_coroutine
	def gmGetCrossServices(self):
		'''获取已连接的跨服服务列表'''
		services = []
		for key, svc in self.server.crossServices.iteritems():
			services.append({
				'key': key,
				'connected': not svc.isLost() if hasattr(svc, 'isLost') else True
			})
		raise Return(services)
