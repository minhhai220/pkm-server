#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

import framework
from framework.csv import csv, MergeServ
from framework.log import logger
from framework.helper import objectid2string, string2objectid
from framework.service.rpc_client import nsqrpc_coroutine as rpc_coroutine
from framework import todayinclock5elapsedays
from game import globaldata
from game.object.game.cross_union_fight import ObjectCrossUnionFightGameGlobal
from game.object.game.servrecord import ObjectServerGlobalRecord
from nsqrpc.server import notify
from game.object.game.cross_arena import ObjectCrossArenaGameGlobal
from game.object.game.cross_supremacy import ObjectCrossSupremacyGameGlobal
from game.object.game.gym import ObjectGymGameGlobal
from game.session import Session
from game.globaldata import GameServInternalPassword, CrossBraveChallengeRanking, CrossHorseRaceRanking
from game.object.game.gm import ObjectGMYYConfig
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.cross_craft import ObjectCrossCraftGameGlobal
from game.object.game.cross_online_fight import ObjectCrossOnlineFightGameGlobal
from game.object.game.cross_fishing import ObjectCrossFishingGameGlobal
from game.object.game.cross_mimicry import ObjectCrossMimicryGameGlobal  # [拟态对战]
from game.object.game.cross_town_party import ObjectCrossTownPartyGlobal  # [家园派对]
from game.object.game.cross_mine import ObjectCrossMineGameGlobal
from game.object.game.cross_auto_chess import ObjectCrossAutoChessGameGlobal  # [跨服卡牌对决]
from game.handler.robot import createRobots

from tornado.gen import Return, moment, sleep, coroutine

import binascii
import io
import gc
import pdb
import time
import random
from rpdb import Rpdb

NodeCallTimeout = 5
NodeCommitTimeout = 4*NodeCallTimeout # 防止组织者挂了，参与者一直阻塞死等

class GameRPC(object):
	def __init__(self, game):
		self.game = game
		self._rpdb = None
		self._uids = {} # {uid: role.id}

		self.tscVotes = {} # {transaction: (key, time)}
		self.tscCommits = {}

		self._lastRefreshCSV = 0 # 上次配表刷新时间

	@property
	def dbcGame(self):
		return self.game.dbcGame

	@property
	def rpcArena(self):
		return self.game.rpcArena

	@property
	def rpcUnion(self):
		return self.game.rpcUnion

	@property
	def machineStatus(self):
		return self.game.machineStatus

	@coroutine
	def _uid2roleid(self, uid):
		roleid = self._uids.get(uid, None)
		if roleid:
			raise Return(roleid)
		roleData = yield self.dbcGame.call_async('DBReadBy', 'Role', {'uid': uid})
		if not roleData['ret'] or len(roleData['models']) == 0:
			raise Exception('unknown uid %d' % uid)
		roleid = roleData['models'][0]['id']
		self._uids[uid] = roleid
		raise Return(roleid)

	@coroutine
	def _prepareRoleID(self, roleID):
		uid = None
		if isinstance(roleID, str) and roleID.isdigit():
			uid = int(roleID)
		elif isinstance(roleID, int):
			uid = roleID
		if uid:
			roleID = yield self._uid2roleid(uid)
		if len(roleID) == 24:
			roleID = roleID.decode('hex')
		raise Return(roleID)

	def Hello(self, data):
		# print data, 'say hello to GameRPCServer'
		return 'GameRPCServer say hello'

	@rpc_coroutine
	def AccountLogin(self, inl_pwd, servID, accountID, accountName, channel, sessionPwd, isNewbie, sdkInfo, rmbReturn=None):
		if inl_pwd != GameServInternalPassword:
			raise Return(None)

		logger.info("%s%s %s from %s coming %d", 'new account ' if isNewbie else '', accountName, binascii.hexlify(accountID), channel, servID)
		if servID and accountID and sessionPwd:
			session = Session(servID, accountID, accountName, sessionPwd, sdkInfo, rmbReturn)
			Session.setSession(session)

			free = Session.idSessions.capacity - len(Session.idSessions)
			used = len(Session.idSessions)

			# 返回角色信息用于记录
			if session.gameLoad:
				role = session.game.role
				raise Return((used, {'id': role.id, 'name': role.name, 'level': role.level, 'logo': role.logo, 'vip': role.vip_level, 'frame': role.frame}))
			else:
				# copy from /game/login
				query = {'account_id': accountID}
				# 是否合服查询
				if self.game.application.servMerged:
					query['area'] = session.servID
				roleData = yield self.dbcGame.call_async('RoleGet', query)
				if roleData['ret']:
					roleData = roleData['model']
					raise Return((used, {'id': roleData["id"], 'name': roleData["name"], 'level': roleData["level"], 'logo': roleData["logo"], 'vip': roleData["vip_level"], 'frame': roleData['frame']}))
			raise Return((used, None))

		raise Return(None)

	def sessionSize(self, inl_pwd):
		if inl_pwd != GameServInternalPassword:
			return None

		return len(Session.idSessions)

	def sessionCapacity(self, inl_pwd):
		if inl_pwd != GameServInternalPassword:
			return None

		# 返回的是剩余空间
		return Session.idSessions.capacity - len(Session.idSessions)

	def isSessionFull(self, inl_pwd):
		if inl_pwd != GameServInternalPassword:
			return None

		return Session.idSessions.full()

	def sessionExisted(self, inl_pwd, sessionID):
		if inl_pwd != GameServInternalPassword:
			return None

		return sessionID in Session.idSessions

	def sessionExistedByAccountID(self, inl_pwd, accountID):
		if inl_pwd != GameServInternalPassword:
			return None

		return accountID in Session.accountIDSessions

	@rpc_coroutine
	def PayForRecharge(self, inl_pwd, channel, accountID, roleID, rechargeID, orderID, amount, extInfo=None, yyID=0, csvID=0):
		if inl_pwd != GameServInternalPassword:
			raise Return('no auth')

		from game.object.game import ObjectGame
		from game.object.game.role import ObjectRole

		accountID = accountID # Account.id
		roleID = roleID # Role.id
		rechargeID = int(rechargeID) # rechages.csv ID
		orderID = orderID # PayOrder.id
		amount = float(amount) # rmb

		if rechargeID not in csv.recharges:
			raise Return('recharge %d error, bad_flag' % rechargeID)
		cfg = csv.recharges[rechargeID]

		# 回调没有金额信息，就以配表为准，只是显示用
		if channel in ('apple', 'tc'):
			amount = float(cfg.rmbDisplay)

		# amount不再判定，线上没有发现异常，且多语言版本rmbDisplay只用来显示
		# else:
		# 	# 冲多了不管，哈哈
		# 	if amount + .001 < cfg.rmbDisplay:
		# 		raise Return('recharge %d amount %.2f less, bad_flag' % (rechargeID, amount))
		# 	elif amount - cfg.rmbDisplay >= 1:
		# 		logger.warning('recharge %d amount %.2f more %.2f' % (rechargeID, amount, amount - cfg.rmbDisplay))

		rechargeOK = False
		game, safeGuard = ObjectGame.getByRoleID(roleID)

		rePro = 0
		if extInfo:
			rePro = extInfo.get('rePro', 0) # 返利比例

		# QQ无需处理离线，login的时候会查询余额
		if framework.is_qq_channel(channel):
			if game:
				with safeGuard:
					# 更新QQ pfkey等信息
					if extInfo:
						game.sdkInfo = extInfo
					game.role.syncQQRecharge(rechargeID, orderID, yyID, csvID)

		elif game is None:
			# 不在线的放入Role.recharges_cache缓存
			ret = yield self.dbcGame.call_async('DBMultipleReadKeys', 'Role', [roleID], ['recharges_cache', 'recharges'])
			if not ret['ret']:
				raise Return(ret['err'])
			if len(ret['models']) != 1:
				raise Return('no such role %s, bad_flag' % objectid2string(roleID))
			role = ret['models'][0]
			rechargeOK = True
			if yyID > 0:
				# 校验 运营活动充值是否合法（月卡，周卡，回归活动，直购礼包，条件触发礼包，通行证）
				rechargeOK = ObjectYYHuoDongFactory.isRechargeOK(rechargeID, yyID, csvID)
			if rechargeOK:
				rechargeOK = ObjectRole.isRechargeOK(role['recharges'], rechargeID, orderID)
			if rechargeOK:
				recharges_cache = role['recharges_cache']
				recharges_cache.append((rechargeID, orderID, yyID, csvID, rePro))
				ret = yield self.dbcGame.call_async('DBUpdate', 'Role', roleID, {'recharges_cache': recharges_cache}, False)
				if not ret['ret']:
					raise Return(ret['err'])
			logger.info('offline role %s recharge %d order %s %.2f in cache %s' % (objectid2string(roleID), rechargeID, objectid2string(orderID), amount, rechargeOK))

		else:
			oldRMB = game.role.rmb
			rechargeOK = True
			if yyID > 0:
				# 校验 运营活动充值是否合法（月卡，周卡，回归活动，直购礼包，条件触发礼包，通行证）
				rechargeOK = ObjectYYHuoDongFactory.isRechargeOK(rechargeID, yyID, csvID)
			if rechargeOK:
				rechargeOK = game.role.buyRecharge(rechargeID, orderID, yyID, csvID, rePro=rePro, push=True, channel=channel)
			logger.info('online role %s recharge %d order %s %.2f %s, %d -> %d, %d' % (objectid2string(roleID), rechargeID, objectid2string(orderID), amount, rechargeOK, oldRMB, game.role.rmb, game.role.rmb - oldRMB))

		raise Return('ok')

	@rpc_coroutine
	def gmRefreshCSV(self):
		buf = io.BytesIO()
		st = time.time()

		# 开发期判断模块为py时自动生成csv
		# 打包后模块为pyc，不自动生成csv
		if hasattr(framework, '__dev__'):
			import subprocess

			delta = time.time() - self._lastRefreshCSV
			if 0 < delta < 60: # 避免内网重复刷表
				buf.write('距离上次刷表刚过去 %fs\n' % delta)
				buf.write('请稍等\n')
			else:
				csvPath = './config'
				if hasattr(framework, '__dev_config__'):
					csvPath = framework.__dev_config__

				buf.write('旧版本信息：\n')
				p = subprocess.Popen('svn info', shell=True, cwd=csvPath, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
				p.wait()
				buf.write(''.join(p.stdout.readlines()))
				buf.write('\n' + '='*50 + '\n')

				buf.write('版本更新：\n')
				p = subprocess.Popen('svn update', shell=True, cwd=csvPath, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
				p.wait()
				buf.write(''.join(p.stdout.readlines()[:5]))
				buf.write('\n(more)...\n' + '='*50 + '\n')

				buf.write('现版本信息：\n')
				p = subprocess.Popen('svn info', shell=True, cwd=csvPath, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
				p.wait()
				buf.write(''.join(p.stdout.readlines()))
				buf.write('\n' + '='*50 + '\n')

				csv.reload()
				buf.write('CSV更新完毕\n')
				self._lastRefreshCSV = time.time()

		else:
			# 随机等待一定时间，防止内存雪崩
			yield sleep(random.randint(1, 60))

			csv.reload()
			buf.write('CSV更新完毕\n')

		buf.write('耗时 %f\n' % (time.time() - st))
		st = time.time()

		import game.object.game
		game.object.game.ObjectGame.initAllClass()
		buf.write('ObjectGame更新完毕\n')

		buf.write('耗时 %f\n' % (time.time() - st))

		raise Return(('ok', buf.getvalue()))

	@rpc_coroutine
	def gmGetServerStatus(self):
		# self.machineStatus.get_cur_process_info()
		# raise Return(self.machineStatus.pid)
		raise Return({
			'size': len(Session.idSessions),
			'cap': Session.idSessions.capacity,
			'active_secs': Session.ActiveStageSecs,
			'active_stat': Session.ActiveStageStat,
		})

	@rpc_coroutine
	def gmGetMachineStatus(self):
		# self.machineStatus.get_status_info()
		# ret = self.machineStatus.as_dict()
		# raise Return(ret)
		raise Return({})

	@rpc_coroutine
	def gmGetAccountStatus(self):
		from tornado.ioloop import IOLoop
		from framework.object import GCObject
		from game.object.game import ObjectGame
		from game.object.game.card import ObjectCard
		from game.object.game.rank import ObjectRankGlobal
		from game.object.game.shop import ObjectPVPShop, ObjectYZShop, ObjectUnionShop

		ioloop = IOLoop.current()
		ret = {
			'tornado': {
				'impl': str(ioloop._impl),
				'handlers': len(ioloop._handlers),
				'events': len(ioloop._events),
				'callbacks': len(ioloop._callbacks),
				'timeouts': len(ioloop._timeouts),
				'cancellations': ioloop._cancellations,
			},
			'session': {
				'size': len(Session.idSessions),
				'cap': Session.idSessions.capacity,
				'active_secs': Session.ActiveStageSecs,
				'active_stat': Session.ActiveStageStat,
			},
			'game': {
				'ObjectGame': len(ObjectGame.ObjsMap),
				'ObjectCard': len(ObjectCard.CardsObjsMap),
				'ObjectShop Free': {
					# 'pvp': len(ObjectPVPShop.FreeList),
					'yz': len(ObjectYZShop.FreeList),
					'union': len(ObjectUnionShop.FreeList),
				},
				'MailJoinableQueue': self.game.mailQueue.qsize(),
				'DBJoinableQueue': self.game.dbQueue.qsize(),
				'SDKJoinableQueue': self.game.sdkQueue.qsize(),
			},
			'gc': {
				'enable': gc.isenabled(),
				'count': gc.get_count(),
				'threshold': gc.get_threshold(),
			},
			'gcobj': GCObject.objs_count_stat(),
			# 'objs': objgraph.most_common_types(limit=24),
		}
		raise Return(ret)

	@rpc_coroutine
	def gmGetYYComfig(self):
		raise Return({
			'db': ObjectGMYYConfig.Singleton.db,
			'csv': csv.yunying.to_dict(),
		})

	@rpc_coroutine
	def gmGC(self):
		st = time.time()
		ret = gc.collect()
		ct = time.time() - st
		raise Return('gc %s cost %s s' % (ret, ct))

	def gmSetSessionCapacity(self, capacity):
		Session.setSessionCapacity(capacity)

	@rpc_coroutine
	def gmSetYYComfig(self, db):
		if 'yyhuodong' in db:
			ObjectGMYYConfig.Singleton.yyhuodong = db['yyhuodong']
		if 'login_weal' in db:
			ObjectGMYYConfig.Singleton.login_weal = db['login_weal']
		if 'level_award' in db:
			ObjectGMYYConfig.Singleton.level_award = db['level_award']
		if 'recharge_gift' in db:
			ObjectGMYYConfig.Singleton.recharge_gift = db['recharge_gift']
		if 'placard' in db:
			ObjectGMYYConfig.Singleton.placard = db['placard']

		ObjectYYHuoDongFactory.classInit()

	@rpc_coroutine
	def gmGetOnlineRoles(self, offest, size):
		keys = list(Session.idSessions.iterkeys())
		allsize = len(keys)
		keys = keys[offest:offest+size]
		models = []
		for sessionID in keys:
			session = Session.idSessions.getByKey(sessionID)
			if session and session.gameLoad:
				models.append(session.game.role.db)
		raise Return({'view': {'ret': len(models), 'size': allsize}, 'models': models})

	@rpc_coroutine
	def gmGenRobots(self):
		ret = yield createRobots(self.rpcArena, self.dbcGame)
		raise Return(ret)

	@rpc_coroutine
	def gmGetMailCsv(self):
		raise Return(csv.mail.to_dict())

	@rpc_coroutine
	def gmGetRoleInfo(self, roleID):
		from game.object.game import ObjectGame
		roleID = yield self._prepareRoleID(roleID)
		obj = ObjectGame.getByRoleID(roleID, safe=False)
		if obj is None:
			roleData = yield self.dbcGame.call_async('DBRead', 'Role', roleID, False)
			if roleData['ret']:
				raise Return(roleData['model'])
			else:
				raise Return({})
		else:
			ret = dict(obj.role.db)
			ret['_online_'] = True
			raise Return(ret)

	@rpc_coroutine
	def gmGetRoleInfoByName(self, roleName):
		roleData = yield self.dbcGame.call_async('DBReadBy', 'Role', {'name': roleName})
		if roleData['ret'] and len(roleData['models']) > 0:
			raise Return(roleData['models'][0])
		else:
			raise Return({})

	@rpc_coroutine
	def gmGetRoleInfoByAccountID(self, accountID):
		roleData = yield self.dbcGame.call_async('DBReadBy', 'Role', {'account_id': accountID})
		if roleData['ret'] and len(roleData['models']) > 0:
			raise Return(roleData['models'][0])
		else:
			raise Return({})

	@rpc_coroutine
	def gmGetRoleInfoByVip(self, beginVip, endVip):
		roleData = yield self.dbcGame.call_async('DBReadRangeBy', 'Role', {'vip_level': (beginVip, endVip)}, 0)
		if roleData['ret'] and len(roleData['models']) > 0:
			raise Return(roleData['models'])
		else:
			raise Return({})

	@rpc_coroutine
	def gmGetRoleYYOpenList(self, level, createTime, vipLevel):
		from game.object.game.yyhuodong import ObjectYYHuoDongFactory
		ret = ObjectYYHuoDongFactory.getRoleOpenList(level, createTime, vipLevel)
		raise Return(ret)

	@rpc_coroutine
	def gmGetUnionInfo(self, unionID):
		from game.object.game.union import ObjectUnion

		obj = ObjectUnion.ObjsMap.get(unionID, None)
		if obj is None:
			raise Return({})
		else:
			raise Return(obj.to_dict())

	@rpc_coroutine
	def gmGetUnionInfoByName(self, unionName, limit=20):
		# 先精确匹配，再模糊匹配
		from framework.helper import objectid2string
		unionData = yield self.dbcGame.call_async('DBReadBy', 'Union', {'name': unionName})
		if unionData['ret'] and len(unionData['models']) > 0:
			for model in unionData['models']:
				if isinstance(model.get('id'), str):
					model['id'] = objectid2string(model['id'])
			raise Return(unionData['models'])

		try:
			limit = int(limit)
		except Exception:
			limit = 20
		models = yield self.dbcGame.call_async('DBReadByPattern', 'Union', {'name': {'pattern': unionName}}, limit)
		if models['ret']:
			for model in models['models']:
				if isinstance(model.get('id'), str):
					model['id'] = objectid2string(model['id'])
			raise Return(models['models'])
		raise Return([])

	@rpc_coroutine
	def gmAddUnionContrib(self, unionID, contrib):
		if unionID is None or contrib is None:
			raise Return({'ok': False, 'err': 'param miss'})
		try:
			from framework.helper import string2objectid
			uid = None
			if isinstance(unionID, (int, long)):
				uid = unionID
			elif isinstance(unionID, basestring):
				unionID = unionID.strip()
				if unionID.isdigit():
					uid = int(unionID)
				elif len(unionID) == 24:
					unionID = string2objectid(unionID)
			if uid is not None:
				unionData = yield self.dbcGame.call_async('DBReadBy', 'Union', {'uid': uid})
				if not unionData['ret'] or len(unionData['models']) == 0:
					raise Return({'ok': False, 'err': 'union not found'})
				unionID = unionData['models'][0]['id']
			yield self.rpcUnion.call_async('AddContribByCheat', unionID, contrib)
		except Exception, e:
			logger.exception('gmAddUnionContrib error')
			raise Return({'ok': False, 'err': str(e)})
		raise Return({'ok': True})

	@rpc_coroutine
	def gmSendMessage(self, type, arg, msg):
		from game.object.game import ObjectGame
		from game.object.game.union import ObjectUnion
		from game.object.game.message import ObjectMessageGlobal

		if type == 'world':
			ObjectMessageGlobal.worldMsg(msg)
		elif type == 'news':
			ObjectMessageGlobal.newsMsg(msg)
		elif type == 'union':
			union = ObjectUnion.ObjsMap.get(arg)
			if union:
				ObjectMessageGlobal.unionMsg(union, msg)
		elif type == 'society':
			pass
		elif type == 'role':
			game = ObjectGame.getByRoleID(arg, safe=False)
			if game:
				ObjectMessageGlobal.roleMsg(game.role, msg)
		raise Return(True)

	@rpc_coroutine
	def gmSendMail(self, roleID, mailType, sender, subject, content, attachs):
		roleID = yield self._prepareRoleID(roleID)
		from game.object.game import ObjectGame
		from game.object.game.role import ObjectRole
		from game.handler.inl_mail import sendMail

		mail = ObjectRole.makeMailModel(roleID, mailType, sender, subject, content, attachs)
		try:
			yield sendMail(mail, self.dbcGame, ObjectGame.getByRoleID(roleID, safe=False))
		except:
			logger.exception('gmSendMail error')
			raise Return(False)
		raise Return(True)

	@rpc_coroutine
	def gmSendGlobalMail(self, mailType, sender, subject, content, attachs):
		from game.handler.inl_mail import sendGlobalMail

		try:
			yield sendGlobalMail(self.dbcGame, mailType, sender, subject, content, attachs)
		except:
			logger.error('gmSendGlobalMail error')
			raise Return(False)
		raise Return(True)

	@rpc_coroutine
	def gmSendVipMail(self, beginVip, endVip, mailType, sender, subject, content, attachs):
		from game.handler.inl_mail import sendVipMail

		try:
			yield sendVipMail(self.dbcGame, beginVip, endVip, mailType, sender, subject, content, attachs)
		except Exception, e:
			logger.error(str(e))
			raise Return(False)
		raise Return(True)

	@rpc_coroutine
	def gmSendServerMail(self, mailType, sender, subject, content, attachs):
		from game.handler.inl_mail import sendServerMail

		try:
			yield sendServerMail(self.dbcGame, mailType, sender, subject, content, attachs)
		except:
			logger.exception('gmSendServerMail error')
			raise Return(False)
		raise Return(True)

	@rpc_coroutine
	def gmSendUnionMail(self, unionID, mailType, sender, subject, content, attachs):
		from game.handler.inl_mail import sendUnionMail

		try:
			yield sendUnionMail(self.dbcGame, unionID, mailType, sender, subject, content, attachs)
		except:
			logger.exception('gmSendUnionMail error')
			raise Return(False)
		raise Return(True)

	@rpc_coroutine
	def gmSendNewbieMail(self, accountName, mailType, sender, subject, content, attachs):
		from game.handler.inl_mail import sendNewbieMail

		try:
			yield sendNewbieMail(self.dbcGame, accountName, mailType, sender, subject, content, attachs)
		except:
			logger.exception('gmSendNewbieMail error')
			raise Return(False)
		raise Return(True)

	@rpc_coroutine
	def gmHandlerDisable(self, url, disable):
		from game.handler import handlers

		if url not in handlers:
			logger.exception('gmHandlerDisable error ' + url)
			raise Return(False)
		handlers[url].disabled = disable
		raise Return(True)

	@rpc_coroutine
	def gmOpenRPDB(self):
		if self._rpdb is None:
			try:
				self._rpdb = MyRpdb()
				logger.info('rpdb open ok')
				self._rpdb.set_trace()
				raise Return(True)

			except Return:
				raise

			except:
				logger.exception('rpdb open error')
				raise Return(False)

		else:
			raise Return(False)

	@rpc_coroutine
	def gmCloseRPDB(self):
		if self._rpdb:
			try:
				self._rpdb.shutdown()
			except:
				pass
			finally:
				self._rpdb = None
		raise Return(True)

	@rpc_coroutine
	def gmDBQueueJoin(self):
		servName = self.game.servName
		dbQueue = self.game.dbQueue
		yield dbQueue.join(closed=False)
		dbQueue._joined = False
		logger.info('%s DBJoinableQueue join over, left %d' % (servName, dbQueue.qsize()))

	@rpc_coroutine
	def gmMailQueueJoin(self):
		servName = self.game.servName
		mailQueue = self.game.mailQueue
		yield mailQueue.join(closed=False)
		mailQueue._joined = False
		logger.info('%s MailJoinableQueue join over, left %d' % (servName, mailQueue.qsize()))

	@rpc_coroutine
	def gmFlushDB(self):
		yield self.dbcGame.call_async('DBFlush', True, True)
		raise Return(True)

	@rpc_coroutine
	def gmCommitDB(self):
		yield self.dbcGame.call_async('DBCommit', True, True)
		raise Return(True)

	@rpc_coroutine
	def gmExecPy(self, src):
		if src.find(GameServInternalPassword) < 0:
			raise Return(None)

		ret = None
		try:
			exec(src)
			if 'exec_func' in locals():
				ret = exec_func(self)
			if 'exec_coroutine' in locals():
				ret = yield exec_coroutine(self)
		except Exception, e:
			logger.exception('gmExecPy Error')
			raise Return(str(e))
		raise Return(ret)

	@rpc_coroutine
	def gmReloadAuto(self):
		from framework.xreload_cache import xreload_auto

		try:
			logger.info('gmReloadAuto begin')
			ret = xreload_auto()
			for x in ret:
				logger.info('%s changed' % x)
			logger.info('gmReloadAuto end')

		except Exception, e:
			logger.exception('gmReloadAuto Error')
			raise Return(str(e))
		raise Return(None)

	@rpc_coroutine
	def gmReloadPyFiles(self, filenames):
		from framework.xreload_cache import xreload

		try:
			logger.info('gmReloadPyFiles begin')
			xreload(filenames)
			logger.info('gmReloadPyFiles end')

		except Exception, e:
			logger.exception('gmReloadPyFiles Error')
			raise Return(str(e))
		raise Return(None)

	@rpc_coroutine
	def gmGetGameRank(self, rtype):
		from game.object.game.rank import ObjectRankGlobal

		offest = 0
		size = 50

		if rtype == 'arena':
			ret = yield self.rpcArena.call_async('GetArenaTop50', offest, size)
			raise Return({'view': {
				'rank': ret,
				'offest': offest,
				'size': size,
			}})

		elif rtype == 'union':
			ret = yield self.rpcUnion.call_async('GetRankList', offest, size)
			raise Return({'view': {
				'rank': ret,
				'offest': offest,
				'size': len(ret), # all
			}})

		elif rtype in ('pokedex', 'fight', 'card1fight', 'star', 'yuanzheng', 'yybox', 'endless') or rtype.startswith('yybox_'):
			# 支持动态的 yybox_xxx 排行榜
			ret = yield ObjectRankGlobal.getRankList(rtype, offest, size)
			raise Return({'view': {
				'rank': ret,
				'offest': offest,
				'size': len(ret),
			}})

		elif rtype == 'world_boss':
			ret = yield ObjectRankGlobal.getRankList('boss',offest, size)
			raise Return({'view': {
				'rank': ret,
				'offest': offest,
				'size': len(ret), # 100
			}})

	@rpc_coroutine
	def gmRoleMemSilentDisable(self, roleID):
		from game.object.game import ObjectGame
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			game.role._lastchat = None # (msg, count)
			game.role._silent_time = 0 # 禁言开始时间
		raise Return(True)

	@rpc_coroutine
	def gmRoleAbandon(self, roleID, type, val):
		from game.object.game import ObjectGame
		from game.object.game.rank import ObjectRankGlobal
		from game.object.game.craft import ObjectCraftInfoGlobal
		from game.object.game.union_fight import ObjectUnionFightGlobal
		from game.object.game.message import ObjectMessageGlobal

		game = ObjectGame.getByRoleID(roleID, safe=False)
		if type == 'disable':
			if game:
				game.role.disable_flag = bool(val)
				if bool(val):
					Session.discardSessionByAccountKey(game.role.accountKey) # 踢下线
			else:
				yield self.dbcGame.call_async('DBUpdate', 'Role', roleID, {
					'disable_flag': bool(val),
				}, True)
			if bool(val):
				yield ObjectRankGlobal.onClearRoleRank(roleID)
				ObjectCraftInfoGlobal.AutoSignRoleMap.pop(roleID, None)
				ObjectUnionFightGlobal.AutoSignRoleMap.pop(roleID, None)


		elif type == 'silent':
			if game:
				game.role.silent_flag = bool(val)
			else:
				yield self.dbcGame.call_async('DBUpdate', 'Role', roleID, {
					'silent_flag': bool(val),
				}, True)
			if bool(val):
				ObjectMessageGlobal.removeWorldQueMsg(roleID) # 删除最近聊天记录

		raise Return(True)

	@rpc_coroutine
	def gmKickPlayer(self, roleID):
		'''
		踢玩家下线（会自动保存数据）
		:param roleID: 玩家角色ID（ObjectId 或 int uid）
		:return: dict {result: bool, message: str}
		'''
		from game.object.game import ObjectGame

		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			accountKey = game.role.accountKey
			uid = game.role.uid
			Session.discardSessionByAccountKey(accountKey)
			logger.info('[GM] Kicked player: uid=%s roleID=%s', uid, roleID)
			raise Return({'result': True, 'message': 'Player kicked: uid=%s' % uid})
		else:
			raise Return({'result': False, 'message': 'Player not online'})
	
	@rpc_coroutine
	def gmKickPlayerByAccountID(self, servID, accountID):
		'''
		通过 accountKey 踢玩家下线（用于转区后清除旧 session）
		:param servID: 服务器ID（区号）
		:param accountID: 账号ID（ObjectId）
		:return: dict {result: bool, message: str}
		'''
		accountKey = (servID, accountID)
		session = Session.idSessions.getByKey(accountKey)
		if session:
			Session.discardSessionByAccountKey(accountKey)
			logger.info('[GM] Kicked player by accountKey: servID=%s accountID=%s', servID, accountID)
			raise Return({'result': True, 'message': 'Player kicked'})
		else:
			logger.info('[GM] Player not online: servID=%s accountID=%s', servID, accountID)
			raise Return({'result': False, 'message': 'Player not online'})

	@rpc_coroutine
	def gmKickAllPlayers(self):
		'''
		踢所有在线玩家下线（会自动保存数据）
		:return: dict {result: bool, count: int}
		'''
		count = 0
		for accountKey, session in list(Session.idSessions.iteritems()):
			try:
				Session.discardSessionByAccountKey(accountKey)
				count += 1
			except Exception as e:
				logger.warning('[GM] Failed to kick %s: %s', accountKey, e)
		logger.info('[GM] Kicked all players, count=%d', count)
		raise Return({'result': True, 'count': count})

	@rpc_coroutine
	def gmRoleModify(self, roleID, key, val):
		from game.object.game import ObjectGame

		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			prop = getattr(game.role, key, None)
			if prop:
				prop.fset(val)

		else:
			yield self.dbcGame.call_async('DBUpdate', 'Role', roleID, {
				key: val,
			}, True)

		raise Return(True)

	@rpc_coroutine
	def gmRejudgePVPPlay(self, playID, forceAll):
		ret = yield self.rpcArena.call_async('rejudgePVPPlay', playID, forceAll)
		raise Return(ret)

	# ==================== 内存数据查看器 ====================

	@rpc_coroutine
	def gmGetPlayerMemoryData(self, roleID, modules=None):
		'''
		获取在线玩家的内存数据
		roleID: 支持 ObjectId 字符串 或 int 类型的 UID
		modules: 可选，指定要获取的模块列表，如 ['role', 'cards', 'contracts']
		         不指定则返回所有模块概览
		'''
		from game.object.game import ObjectGame
		from framework.helper import objectid2string, string2objectid
		
		game = None
		if isinstance(roleID, int):
			# 通过 UID 查找
			for g in ObjectGame.ObjsMap.itervalues():
				if g.role.uid == roleID:
					game = g
					roleID = g.role.id
					break
		else:
			# 字符串转换为 ObjectId
			if isinstance(roleID, basestring):
				roleID = string2objectid(roleID)
			game, guard = ObjectGame.getByRoleID(roleID)
		
		if not game:
			raise Return({'ret': False, 'err': 'player_not_online'})
		
		result = {
			'ret': True,
			'role_id': objectid2string(roleID),
			'role_name': game.role.name,
			'online': True,
			'modules': {}
		}
		
		# 定义可查看的模块
		all_modules = {
			'role': lambda: self._getMemoryRoleData(game),
			'cards': lambda: self._getMemoryCardsData(game),
			'contracts': lambda: self._getMemoryContractsData(game),
			'items': lambda: self._getMemoryItemsData(game),
			'gems': lambda: self._getMemoryGemsData(game),
			'chips': lambda: self._getMemoryChipsData(game),
			'daily_record': lambda: self._getMemoryDailyRecordData(game),
			'held_items': lambda: self._getMemoryHeldItemsData(game),
			'tasks': lambda: self._getMemoryTasksData(game),
			'shops': lambda: self._getMemoryShopsData(game),
			'embattle': lambda: self._getMemoryEmbattleData(game),
			# 容易出问题的模块
			'aid': lambda: self._getMemoryAidData(game),
			'currencies': lambda: self._getMemoryCurrenciesData(game),
			'guide': lambda: self._getMemoryGuideData(game),
			'gacha_record': lambda: self._getMemoryGachaRecordData(game),
		}
		
		if modules is None:
			# 返回所有模块的概览（只返回数量，不返回详细数据）
			result['modules'] = {
				'role': {'count': 1, 'has_data': True},
				'cards': {'count': len(game.role.cards), 'has_data': True},
				'contracts': {'count': len(game.role.contracts) if hasattr(game.role, 'contracts') else 0, 'has_data': True},
				'items': {'count': len(game.items._objs) if hasattr(game.items, '_objs') else 0, 'has_data': True},
				'gems': {'count': len(game.role.gems) if hasattr(game.role, 'gems') else 0, 'has_data': True},
				'chips': {'count': len(game.role.chips) if hasattr(game.role, 'chips') else 0, 'has_data': True},
				'daily_record': {'count': 1, 'has_data': True},
				'held_items': {'count': len(game.role.held_items) if hasattr(game.role, 'held_items') else 0, 'has_data': True},
				'tasks': {'count': len(game.tasks._tasks) if hasattr(game.tasks, '_tasks') else 0, 'has_data': True},
				'shops': {'count': 3, 'has_data': True},
				'embattle': {'count': len(game.role.card_embattle) if hasattr(game.role, 'card_embattle') else 0, 'has_data': True},
				# 容易出问题的模块
				'aid': {'count': len(game.role.active_aid) if hasattr(game.role, 'active_aid') and game.role.active_aid else 0, 'has_data': True},
				'currencies': {'count': 1, 'has_data': True},
				'guide': {'count': 1, 'has_data': True},
				'gacha_record': {'count': 1, 'has_data': True},  # 抽卡保底记录
			}
		else:
			# 返回指定模块的详细数据
			for mod in modules:
				if mod in all_modules:
					try:
						result['modules'][mod] = all_modules[mod]()
					except Exception as e:
						result['modules'][mod] = {'error': str(e)}
		
		raise Return(result)

	def _getMemoryRoleData(self, game):
		'''获取角色基础数据'''
		from framework.helper import objectid2string
		role = game.role
		return {
			'id': objectid2string(role.id),
			'name': role.name,
			'level': role.level,
			'vip_level': role.vip_level,
			'gold': role.gold,
			'rmb': role.rmb,
			'exp': role.exp,
			'stamina': role.stamina,
			'fighting_point': role.battle_fighting_point,  # 注意：role 用 battle_fighting_point
			'recharge_rmb': role.vipSum,  # 累计充值，用 vipSum
			'cards_count': len(role.cards),
			'contracts_count': len(role.contracts) if hasattr(role, 'contracts') else 0,
		}

	def _getMemoryCardsData(self, game):
		'''获取卡牌数据'''
		from framework.helper import objectid2string
		cards_data = []
		for card_id in game.role.cards:
			card = game.cards.getCard(card_id)
			if card:
				card_info = {
					'id': objectid2string(card.id),
					'card_id': card.card_id,
					'level': card.level,
					'advance': card.advance,
					'star': card.star,
					'fighting_point': card.fighting_point,
					'position': getattr(card, 'position', -1),
				}
				# 契约信息 - 需要转换 ObjectId
				if hasattr(card, 'contracts') and card.contracts:
					contracts_info = {}
					for pos, slot in card.contracts.items():
						slot_info = {'unlock': slot.get('unlock', False)}
						if slot.get('contract_db_id'):
							slot_info['contract_db_id'] = objectid2string(slot['contract_db_id'])
						contracts_info[pos] = slot_info
					card_info['contracts'] = contracts_info
				cards_data.append(card_info)
		return {'count': len(cards_data), 'data': cards_data}

	def _getMemoryContractsData(self, game):
		'''获取契约数据'''
		from framework.helper import objectid2string
		contracts_data = []
		if hasattr(game.role, 'contracts'):
			for contract_id in game.role.contracts:
				contract = game.role.getContract(contract_id)
				if contract:
					contracts_data.append({
						'id': objectid2string(contract.id),
						'contract_id': contract.contract_id,
						'level': contract.level,
						'advance': contract.advance,
						'position': contract.position,
						'card_db_id': objectid2string(contract.card_db_id) if contract.card_db_id else None,
					})
		return {'count': len(contracts_data), 'data': contracts_data}

	def _getMemoryItemsData(self, game):
		'''获取道具数据'''
		items_data = []
		if hasattr(game.items, '_objs'):
			for item_id, item in game.items._objs.iteritems():
				items_data.append({
					'item_id': item_id,
					'count': item.count,
				})
		return {'count': len(items_data), 'data': items_data[:100]}  # 限制返回数量

	def _getMemoryGemsData(self, game):
		'''获取宝石数据'''
		from framework.helper import objectid2string
		gems_data = []
		if hasattr(game.role, 'gems'):
			for gem_id in game.role.gems:
				gem = game.gems.getGem(gem_id)
				if gem:
					gems_data.append({
						'id': objectid2string(gem.id),
						'gem_id': gem.gem_id,
						'level': gem.level,
						'card_db_id': objectid2string(gem.card_db_id) if gem.card_db_id else None,
					})
		return {'count': len(gems_data), 'data': gems_data}

	def _getMemoryChipsData(self, game):
		'''获取芯片数据'''
		from framework.helper import objectid2string
		chips_data = []
		if hasattr(game.role, 'chips'):
			for chip_id in game.role.chips:
				chip = game.chips.getChip(chip_id)
				if chip:
					chips_data.append({
						'id': objectid2string(chip.id),
						'chip_id': chip.chip_id,
						'level': chip.level,
						'card_db_id': objectid2string(chip.card_db_id) if chip.card_db_id else None,
					})
		return {'count': len(chips_data), 'data': chips_data}

	def _getMemoryDailyRecordData(self, game):
		'''获取每日记录数据'''
		dr = game.dailyRecord
		return {
			'last_time': dr.last_time if hasattr(dr, 'last_time') else 0,
		}

	def _getMemoryHeldItemsData(self, game):
		'''获取携带道具数据'''
		from framework.helper import objectid2string
		held_items_data = []
		if hasattr(game.role, 'held_items'):
			for held_item_id in game.role.held_items:
				held_item = game.heldItems.getHeldItem(held_item_id)
				if held_item:
					held_items_data.append({
						'id': objectid2string(held_item.id),
						'held_item_id': held_item.held_item_id,
						'level': held_item.level,
						'card_db_id': objectid2string(held_item.card_db_id) if held_item.card_db_id else None,
					})
		return {'count': len(held_items_data), 'data': held_items_data}

	def _getMemoryTasksData(self, game):
		'''获取任务数据'''
		tasks_data = []
		if hasattr(game.tasks, '_tasks'):
			for task_id, task in game.tasks._tasks.iteritems():
				tasks_data.append({
					'task_id': task_id,
					'progress': task.get('progress', 0),
					'flag': task.get('flag', 0),
					'star': task.get('star', 0),
				})
		return {'count': len(tasks_data), 'data': tasks_data[:100]}  # 限制数量

	def _getMemoryShopsData(self, game):
		'''获取商店数据'''
		shops_data = {}
		
		# 固定商店
		if hasattr(game, 'fixShop') and game.fixShop:
			shops_data['fix_shop'] = {
				'items': game.fixShop.model.get('items', []) if game.fixShop.model else [],
				'refresh_time': game.fixShop.model.get('refresh_time', 0) if game.fixShop.model else 0,
			}
		
		# 公会商店
		if hasattr(game, 'unionShop') and game.unionShop:
			shops_data['union_shop'] = {
				'items': game.unionShop.model.get('items', []) if game.unionShop.model else [],
				'refresh_time': game.unionShop.model.get('refresh_time', 0) if game.unionShop.model else 0,
			}
		
		# 神秘商店
		if hasattr(game, 'mysteryShop') and game.mysteryShop:
			shops_data['mystery_shop'] = {
				'items': game.mysteryShop.model.get('items', []) if game.mysteryShop.model else [],
				'refresh_time': game.mysteryShop.model.get('refresh_time', 0) if game.mysteryShop.model else 0,
			}
		
		return {'count': len(shops_data), 'data': shops_data}

	def _getMemoryEmbattleData(self, game):
		'''获取布阵数据'''
		from framework.helper import objectid2string
		embattle_data = {}
		if hasattr(game.role, 'card_embattle') and game.role.card_embattle:
			for mode, data in game.role.card_embattle.iteritems():
				mode_data = {}
				for key, value in data.iteritems():
					# 处理 ObjectId 类型的值
					if isinstance(value, list):
						mode_data[key] = [objectid2string(v) if isinstance(v, bytes) and len(v) == 12 else v for v in value]
					elif isinstance(value, dict):
						mode_data[key] = {}
						for k, v in value.iteritems():
							if isinstance(v, list):
								mode_data[key][k] = [objectid2string(x) if isinstance(x, bytes) and len(x) == 12 else x for x in v]
							else:
								mode_data[key][k] = objectid2string(v) if isinstance(v, bytes) and len(v) == 12 else v
					else:
						mode_data[key] = objectid2string(value) if isinstance(value, bytes) and len(value) == 12 else value
				embattle_data[mode] = mode_data
		return {'count': len(embattle_data), 'data': embattle_data}

	def _getMemoryAidData(self, game):
		'''获取助战数据 - 容易出问题'''
		aid_data = {
			'aid': game.role.aid if hasattr(game.role, 'aid') and game.role.aid else {},
			'active_aid': game.role.active_aid if hasattr(game.role, 'active_aid') and game.role.active_aid else {},
			'aid_material': game.role.aid_material if hasattr(game.role, 'aid_material') and game.role.aid_material else {},
		}
		return {'count': len(aid_data.get('active_aid', {})), 'data': aid_data}

	def _getMemoryCurrenciesData(self, game):
		'''获取所有货币数据 - 关键数据'''
		role = game.role
		return {
			'gold': role.gold,
			'rmb': role.rmb,
			'exp': role.exp,
			'stamina': role.stamina,
			'vip_level': role.vip_level,
			'recharge_rmb': role.vipSum,  # 累计充值，用 vipSum
			'fighting_point': role.battle_fighting_point,  # 注意：role 用 battle_fighting_point
		}

	def _getMemoryGuideData(self, game):
		'''获取引导数据 - 容易出问题'''
		role = game.role
		return {
			'newbie_guide': role.newbie_guide if hasattr(role, 'newbie_guide') else {},
			'grow_guide': role.grow_guide if hasattr(role, 'grow_guide') else {},
			'level': role.level,
			'vip_level': role.vip_level,
		}

	def _getMemoryGachaRecordData(self, game):
		'''获取抽卡记录数据 - 重要保底数据'''
		lr = game.lotteryRecord
		return {
			# 卡牌抽取计数器
			'dc1_counter': lr.dc1_counter if hasattr(lr, 'dc1_counter') else 0,  # 钻石单抽
			'dc10_counter': lr.dc10_counter if hasattr(lr, 'dc10_counter') else 0,  # 钻石10连
			'dc1_gold_counter': lr.dc1_gold_counter if hasattr(lr, 'dc1_gold_counter') else 0,  # 金币单抽
			'dc10_gold_counter': lr.dc10_gold_counter if hasattr(lr, 'dc10_gold_counter') else 0,  # 金币10连
			'dc1_item_counter': lr.dc1_item_counter if hasattr(lr, 'dc1_item_counter') else 0,  # 道具单抽
			# 装备抽取计数器
			'eq_dc1_counter': lr.eq_dc1_counter if hasattr(lr, 'eq_dc1_counter') else 0,  # 装备钻石单抽
			'eq_dc10_counter': lr.eq_dc10_counter if hasattr(lr, 'eq_dc10_counter') else 0,  # 装备钻石10连
			# 宝石抽取计数器
			'gem_rmb_dc1_counter': lr.gem_rmb_dc1_counter if hasattr(lr, 'gem_rmb_dc1_counter') else 0,
			'gem_rmb_dc10_counter': lr.gem_rmb_dc10_counter if hasattr(lr, 'gem_rmb_dc10_counter') else 0,
			'gem_gold_dc1_counter': lr.gem_gold_dc1_counter if hasattr(lr, 'gem_gold_dc1_counter') else 0,
			'gem_gold_dc10_counter': lr.gem_gold_dc10_counter if hasattr(lr, 'gem_gold_dc10_counter') else 0,
			# 芯片抽取计数器
			'chip_rmb_dc1_counter': lr.chip_rmb_dc1_counter if hasattr(lr, 'chip_rmb_dc1_counter') else 0,
			'chip_rmb_dc10_counter': lr.chip_rmb_dc10_counter if hasattr(lr, 'chip_rmb_dc10_counter') else 0,
			'chip_item_dc1_counter': lr.chip_item_dc1_counter if hasattr(lr, 'chip_item_dc1_counter') else 0,
			'chip_item_dc10_counter': lr.chip_item_dc10_counter if hasattr(lr, 'chip_item_dc10_counter') else 0,
			# 图腾抽取计数器
			'totem_rmb_dc1_counter': lr.totem_rmb_dc1_counter if hasattr(lr, 'totem_rmb_dc1_counter') else 0,
			'totem_rmb_dc6_counter': lr.totem_rmb_dc6_counter if hasattr(lr, 'totem_rmb_dc6_counter') else 0,
			# 远征宝箱
			'yz_freeBox_counter': lr.yz_freeBox_counter if hasattr(lr, 'yz_freeBox_counter') else 0,
			# 道具抽取
			'item_dc1_counter': lr.item_dc1_counter if hasattr(lr, 'item_dc1_counter') else 0,
			# 活动计数器
			'yyhuodong_counters': lr.yyhuodong_counters if hasattr(lr, 'yyhuodong_counters') else {},
			# 权值和生效信息（用于保底机制）
			'weight_info': lr.weight_info if hasattr(lr, 'weight_info') else {},
			'effect_info': lr.effect_info if hasattr(lr, 'effect_info') else {},
		}

	@rpc_coroutine
	def gmGetPlayerDBData(self, roleID, modules=None):
		'''
		获取玩家数据库中的数据（直接从数据库读取，不经过内存）
		roleID: 支持 ObjectId 字符串 或 int 类型的 UID
		用于与内存数据对比
		'''
		from framework.helper import objectid2string, string2objectid
		
		# 如果是 UID，先从数据库查询获取 roleID
		if isinstance(roleID, int):
			try:
				role_data = yield self.dbcGame.call_async('DBReadBy', 'Role', {'uid': roleID})
				logger.info('[gmGetPlayerDBData] DBReadBy result for uid %s: %s', roleID, role_data)
				if role_data.get('ret') and len(role_data.get('models', [])) > 0:
					roleID = role_data['models'][0]['id']
				else:
					raise Return({'ret': False, 'err': 'player_not_found'})
			except Exception as e:
				logger.exception('[gmGetPlayerDBData] DBReadBy failed for uid %s', roleID)
				raise Return({'ret': False, 'err': str(e)})
		elif isinstance(roleID, basestring):
			roleID = string2objectid(roleID)
		
		result = {
			'ret': True,
			'role_id': objectid2string(roleID),
			'modules': {}
		}
		
		# 始终读取 Role 数据（cards 和 contracts 依赖它）
		role_data = yield self.dbcGame.call_async('DBRead', 'Role', roleID, False)
		cards_list = []
		contracts_list = []
		if role_data['ret'] and role_data['model']:
			model = role_data['model']
			# 转换 ObjectId 列表为字符串列表
			cards_list = [objectid2string(c) for c in model.get('cards', []) if c]
			contracts_list = [objectid2string(c) for c in model.get('contracts', []) if c]
			
			# 只有请求 role 模块时才返回详细信息
			if modules is None or 'role' in modules:
				result['modules']['role'] = {
					'id': objectid2string(model.get('id')),
					'name': model.get('name'),
					'level': model.get('level'),
					'vip_level': model.get('vip_level'),
					'gold': model.get('gold'),
					'rmb': model.get('rmb'),
					'exp': model.get('exp'),
					'stamina': model.get('stamina'),
					'fighting_point': model.get('battle_fighting_point'),  # 数据库字段是 battle_fighting_point
					'cards': cards_list,
					'contracts': contracts_list,
				}
		
		# 读取卡牌数据
		if modules is None or 'cards' in modules:
			cards_data = []
			for card_id_str in cards_list[:50]:  # 限制数量
				card_id = string2objectid(card_id_str)
				card_result = yield self.dbcGame.call_async('DBRead', 'RoleCard', card_id, False)
				if card_result['ret'] and card_result['model']:
					m = card_result['model']
					# 处理 contracts 字段中的 ObjectId
					contracts_info = m.get('contracts')
					if contracts_info and isinstance(contracts_info, dict):
						safe_contracts = {}
						for pos, slot in contracts_info.items():
							if isinstance(slot, dict):
								safe_slot = {'unlock': slot.get('unlock', False)}
								if slot.get('contract_db_id'):
									safe_slot['contract_db_id'] = objectid2string(slot['contract_db_id'])
								safe_contracts[pos] = safe_slot
						contracts_info = safe_contracts
					cards_data.append({
						'id': objectid2string(m.get('id')),
						'card_id': m.get('card_id'),
						'level': m.get('level'),
						'advance': m.get('advance'),
						'star': m.get('star'),
						'fighting_point': m.get('fighting_point'),
						'contracts': contracts_info,
					})
			result['modules']['cards'] = {'count': len(cards_list), 'data': cards_data}
		
		# 读取契约数据
		if modules is None or 'contracts' in modules:
			contracts_data = []
			for contract_id_str in contracts_list[:50]:
				contract_id = string2objectid(contract_id_str)
				contract_result = yield self.dbcGame.call_async('DBRead', 'RoleContract', contract_id, False)
				if contract_result['ret'] and contract_result['model']:
					m = contract_result['model']
					contracts_data.append({
						'id': objectid2string(m.get('id')),
						'contract_id': m.get('contract_id'),
						'level': m.get('level'),
						'advance': m.get('advance'),
						'position': m.get('position'),
						'card_db_id': objectid2string(m.get('card_db_id')) if m.get('card_db_id') else None,
					})
			result['modules']['contracts'] = {'count': len(contracts_list), 'data': contracts_data}
		
		# 读取携带道具数据
		if modules is None or 'held_items' in modules:
			held_items_list = [objectid2string(h) for h in model.get('held_items', []) if h]
			held_items_data = []
			for held_item_id_str in held_items_list[:50]:
				held_item_id = string2objectid(held_item_id_str)
				held_item_result = yield self.dbcGame.call_async('DBRead', 'RoleHeldItem', held_item_id, False)
				if held_item_result['ret'] and held_item_result['model']:
					m = held_item_result['model']
					held_items_data.append({
						'id': objectid2string(m.get('id')),
						'held_item_id': m.get('held_item_id'),
						'level': m.get('level'),
						'card_db_id': objectid2string(m.get('card_db_id')) if m.get('card_db_id') else None,
					})
			result['modules']['held_items'] = {'count': len(held_items_list), 'data': held_items_data}
		
		# 读取布阵数据（存在 Role 表中）
		if modules is None or 'embattle' in modules:
			embattle_data = model.get('card_embattle', {})
			# 处理 ObjectId
			safe_embattle = {}
			for mode, data in embattle_data.iteritems():
				mode_data = {}
				for key, value in data.iteritems():
					if isinstance(value, list):
						mode_data[key] = [objectid2string(v) if isinstance(v, bytes) and len(v) == 12 else v for v in value]
					elif isinstance(value, dict):
						mode_data[key] = {}
						for k, v in value.iteritems():
							if isinstance(v, list):
								mode_data[key][k] = [objectid2string(x) if isinstance(x, bytes) and len(x) == 12 else x for x in v]
							else:
								mode_data[key][k] = objectid2string(v) if isinstance(v, bytes) and len(v) == 12 else v
					else:
						mode_data[key] = objectid2string(value) if isinstance(value, bytes) and len(value) == 12 else value
				safe_embattle[mode] = mode_data
			result['modules']['embattle'] = {'count': len(safe_embattle), 'data': safe_embattle}
		
		# 读取助战数据（存在 Role 表中）
		if modules is None or 'aid' in modules:
			result['modules']['aid'] = {
				'aid': model.get('aid', {}),
				'active_aid': model.get('active_aid', {}),
				'aid_material': model.get('aid_material', {}),
			}
		
		# 读取货币数据（存在 Role 表中）
		if modules is None or 'currencies' in modules:
			result['modules']['currencies'] = {
				'gold': model.get('gold'),
				'rmb': model.get('rmb'),
				'sum_exp': model.get('sum_exp'),  # 数据库中是 sum_exp
				'stamina': model.get('stamina'),
				'vip_level': model.get('vip_level'),
				'fighting_point': model.get('battle_fighting_point'),  # 数据库字段是 battle_fighting_point
			}
		
		# 读取引导数据（存在 Role 表中）
		if modules is None or 'guide' in modules:
			result['modules']['guide'] = {
				'newbie_guide': model.get('newbie_guide', {}),
				'grow_guide': model.get('grow_guide', {}),
				'level': model.get('level'),
				'vip_level': model.get('vip_level'),
			}
		
		# 读取宝石数据（从 RoleGem 表）
		if modules is None or 'gems' in modules:
			gems_list = [objectid2string(g) for g in model.get('gems', []) if g]
			gems_data = []
			for gem_id_str in gems_list[:50]:
				gem_id = string2objectid(gem_id_str)
				gem_result = yield self.dbcGame.call_async('DBRead', 'RoleGem', gem_id, False)
				if gem_result['ret'] and gem_result['model']:
					m = gem_result['model']
					gems_data.append({
						'id': objectid2string(m.get('id')),
						'gem_id': m.get('gem_id'),
						'level': m.get('level'),
						'card_db_id': objectid2string(m.get('card_db_id')) if m.get('card_db_id') else None,
					})
			result['modules']['gems'] = {'count': len(gems_list), 'data': gems_data}
		
		# 读取芯片数据（从 RoleChip 表）
		if modules is None or 'chips' in modules:
			chips_list = [objectid2string(c) for c in model.get('chips', []) if c]
			chips_data = []
			for chip_id_str in chips_list[:50]:
				chip_id = string2objectid(chip_id_str)
				chip_result = yield self.dbcGame.call_async('DBRead', 'RoleChip', chip_id, False)
				if chip_result['ret'] and chip_result['model']:
					m = chip_result['model']
					chips_data.append({
						'id': objectid2string(m.get('id')),
						'chip_id': m.get('chip_id'),
						'level': m.get('level'),
						'card_db_id': objectid2string(m.get('card_db_id')) if m.get('card_db_id') else None,
					})
			result['modules']['chips'] = {'count': len(chips_list), 'data': chips_data}
		
		# 读取道具数据（存在 Role 表中）
		if modules is None or 'items' in modules:
			items_data = model.get('items', {})
			# items 格式: {item_id: count}
			result['modules']['items'] = {'count': len(items_data), 'data': items_data}
		
		# 读取每日记录数据（从 DailyRecord 表）
		if modules is None or 'daily_record' in modules:
			daily_record_db_id = model.get('daily_record_db_id')
			if daily_record_db_id:
				dr_result = yield self.dbcGame.call_async('DBRead', 'DailyRecord', daily_record_db_id, False)
				if dr_result['ret'] and dr_result['model']:
					dr = dr_result['model']
					result['modules']['daily_record'] = {
						'last_time': dr.get('last_time', 0),
						'draw_card': dr.get('draw_card', 0),
						'draw_equip': dr.get('draw_equip', 0),
						'draw_gem': dr.get('draw_gem', 0),
						'stamina_buy_count': dr.get('stamina_buy_count', 0),
						'arena_count': dr.get('arena_count', 0),
					}
				else:
					result['modules']['daily_record'] = {'error': 'daily_record_not_found'}
			else:
				result['modules']['daily_record'] = {'error': 'no_daily_record_db_id'}
		
		# 读取任务数据（存在 Role 表中）
		if modules is None or 'tasks' in modules:
			tasks_data = model.get('tasks', {})
			result['modules']['tasks'] = {'count': len(tasks_data), 'data': tasks_data}
		
		# 读取商店数据（从多个表读取）
		if modules is None or 'shops' in modules:
			shops_data = {}
			# 固定商店
			fix_shop_db_id = model.get('fix_shop_db_id')
			if fix_shop_db_id:
				fs_result = yield self.dbcGame.call_async('DBRead', 'FixShop', fix_shop_db_id, False)
				if fs_result['ret'] and fs_result['model']:
					shops_data['fix_shop'] = {
						'items': fs_result['model'].get('items', []),
						'refresh_time': fs_result['model'].get('refresh_time', 0),
					}
			# 神秘商店
			mystery_shop_db_id = model.get('mystery_shop_db_id')
			if mystery_shop_db_id:
				ms_result = yield self.dbcGame.call_async('DBRead', 'MysteryShop', mystery_shop_db_id, False)
				if ms_result['ret'] and ms_result['model']:
					shops_data['mystery_shop'] = {
						'items': ms_result['model'].get('items', []),
						'refresh_time': ms_result['model'].get('refresh_time', 0),
					}
			result['modules']['shops'] = {'count': len(shops_data), 'data': shops_data}
		
		# 读取抽卡记录数据（从 LotteryRecord 表）
		if modules is None or 'gacha_record' in modules:
			lottery_db_id = model.get('lottery_db_id')
			if lottery_db_id:
				lottery_result = yield self.dbcGame.call_async('DBRead', 'LotteryRecord', lottery_db_id, False)
				if lottery_result['ret'] and lottery_result['model']:
					lr = lottery_result['model']
					result['modules']['gacha_record'] = {
						# 卡牌抽取计数器
						'dc1_counter': lr.get('dc1_counter', 0),
						'dc10_counter': lr.get('dc10_counter', 0),
						'dc1_gold_counter': lr.get('dc1_gold_counter', 0),
						'dc10_gold_counter': lr.get('dc10_gold_counter', 0),
						'dc1_item_counter': lr.get('dc1_item_counter', 0),
						# 装备抽取计数器
						'eq_dc1_counter': lr.get('eq_dc1_counter', 0),
						'eq_dc10_counter': lr.get('eq_dc10_counter', 0),
						# 宝石抽取计数器
						'gem_rmb_dc1_counter': lr.get('gem_rmb_dc1_counter', 0),
						'gem_rmb_dc10_counter': lr.get('gem_rmb_dc10_counter', 0),
						'gem_gold_dc1_counter': lr.get('gem_gold_dc1_counter', 0),
						'gem_gold_dc10_counter': lr.get('gem_gold_dc10_counter', 0),
						# 芯片抽取计数器
						'chip_rmb_dc1_counter': lr.get('chip_rmb_dc1_counter', 0),
						'chip_rmb_dc10_counter': lr.get('chip_rmb_dc10_counter', 0),
						'chip_item_dc1_counter': lr.get('chip_item_dc1_counter', 0),
						'chip_item_dc10_counter': lr.get('chip_item_dc10_counter', 0),
						# 图腾抽取计数器
						'totem_rmb_dc1_counter': lr.get('totem_rmb_dc1_counter', 0),
						'totem_rmb_dc6_counter': lr.get('totem_rmb_dc6_counter', 0),
						# 远征宝箱
						'yz_freeBox_counter': lr.get('yz_freeBox_counter', 0),
						# 道具抽取
						'item_dc1_counter': lr.get('item_dc1_counter', 0),
						# 活动计数器
						'yyhuodong_counters': lr.get('yyhuodong_counters', {}),
						# 权值和生效信息（用于保底机制）
						'weight_info': lr.get('weight_info', {}),
						'effect_info': lr.get('effect_info', {}),
					}
				else:
					result['modules']['gacha_record'] = {'error': 'lottery_record_not_found'}
			else:
				result['modules']['gacha_record'] = {'error': 'no_lottery_db_id'}
		
		raise Return(result)

	@rpc_coroutine
	def gmComparePlayerData(self, roleID):
		'''
		对比玩家内存数据和数据库数据，返回差异
		roleID: 支持 ObjectId 字符串 或 int 类型的 UID
		'''
		from game.object.game import ObjectGame
		from framework.helper import objectid2string, string2objectid
		
		game = None
		if isinstance(roleID, int):
			# 通过 UID 查找
			for g in ObjectGame.ObjsMap.itervalues():
				if g.role.uid == roleID:
					game = g
					roleID = g.role.id  # 这里 roleID 变成 ObjectId (bytes)
					break
			if not game:
				raise Return({'ret': False, 'err': 'player_not_online'})
		else:
			# 字符串转换为 ObjectId
			if isinstance(roleID, basestring):
				roleID = string2objectid(roleID)
			game, guard = ObjectGame.getByRoleID(roleID)
			if not game:
				raise Return({'ret': False, 'err': 'player_not_online'})
		
		# 确保 roleID 是有效的 ObjectId
		if roleID is None:
			raise Return({'ret': False, 'err': 'invalid_role_id'})
		
		differences = []
		
		# 使用 game.role.id 确保是正确的 ObjectId
		db_role_id = game.role.id
		
		# 对比 Role 基础数据
		role_db = yield self.dbcGame.call_async('DBRead', 'Role', db_role_id, False)
		if role_db['ret'] and role_db['model']:
			db_model = role_db['model']
			mem_role = game.role
			
			# 检查关键字段 (内存属性名 -> 数据库字段名)
			# 注意：没有 coin 属性
			fields_to_check = [
				('level', 'level'),
				('gold', 'gold'),
				('rmb', 'rmb'),
				('exp', 'sum_exp'),  # exp 属性映射到 sum_exp 字段
				('stamina', 'stamina'),
				('vip_level', 'vip_level'),
			]
			for mem_field, db_field in fields_to_check:
				mem_val = getattr(mem_role, mem_field, None)
				db_val = db_model.get(db_field)
				if mem_val != db_val:
					differences.append({
						'module': 'role',
						'field': mem_field,
						'memory': mem_val,
						'database': db_val,
					})
		
		# 对比契约的 position 字段（常见回档问题）
		if hasattr(game.role, 'contracts'):
			for contract_id in game.role.contracts:
				contract = game.role.getContract(contract_id)
				if contract:
					contract_db = yield self.dbcGame.call_async('DBRead', 'RoleContract', contract_id, False)
					if contract_db['ret'] and contract_db['model']:
						db_model = contract_db['model']
						if contract.position != db_model.get('position'):
							differences.append({
								'module': 'contracts',
								'id': objectid2string(contract_id),
								'field': 'position',
								'memory': contract.position,
								'database': db_model.get('position'),
							})
						if str(contract.card_db_id) != str(db_model.get('card_db_id')):
							differences.append({
								'module': 'contracts',
								'id': objectid2string(contract_id),
								'field': 'card_db_id',
								'memory': objectid2string(contract.card_db_id) if contract.card_db_id else None,
								'database': objectid2string(db_model.get('card_db_id')) if db_model.get('card_db_id') else None,
							})
		
		raise Return({
			'ret': True,
			'role_id': objectid2string(db_role_id),
			'role_name': game.role.name,
			'differences': differences,
			'has_differences': len(differences) > 0,
		})

	@rpc_coroutine
	def gmForceSavePlayer(self, roleID, modules=None):
		'''
		强制保存玩家数据到数据库
		roleID: 支持 ObjectId 字符串 或 int 类型的 UID
		modules: 可选，指定要保存的模块，不指定则保存全部
		'''
		from game.object.game import ObjectGame
		from framework.helper import objectid2string, string2objectid
		
		game = None
		if isinstance(roleID, int):
			# 通过 UID 查找
			for g in ObjectGame.ObjsMap.itervalues():
				if g.role.uid == roleID:
					game = g
					roleID = g.role.id
					break
			if not game:
				raise Return({'ret': False, 'err': 'player_not_online'})
		else:
			# 字符串转换为 ObjectId
			if isinstance(roleID, basestring):
				roleID = string2objectid(roleID)
			game, guard = ObjectGame.getByRoleID(roleID)
			if not game:
				raise Return({'ret': False, 'err': 'player_not_online'})
		
		saved_modules = []
		
		try:
			# 保存 Role
			if modules is None or 'role' in modules:
				game.role.save_async()
				saved_modules.append('role')
			
			# 保存所有卡牌
			if modules is None or 'cards' in modules:
				for card_id in game.role.cards:
					card = game.cards.getCard(card_id)
					if card:
						card.save_async()
				saved_modules.append('cards')
			
			# 保存所有契约
			if modules is None or 'contracts' in modules:
				if hasattr(game.role, 'contracts'):
					for contract_id in game.role.contracts:
						contract = game.role.getContract(contract_id)
						if contract:
							contract.save_async()
				saved_modules.append('contracts')
			
			# 保存每日记录
			if modules is None or 'daily_record' in modules:
				game.dailyRecord.save_async()
				saved_modules.append('daily_record')
			
			logger.info('[GM] Force saved player %s, modules: %s', objectid2string(roleID), saved_modules)
			
		except Exception as e:
			logger.error('[GM] Force save player %s error: %s', objectid2string(roleID), e)
			raise Return({'ret': False, 'err': str(e)})
		
		raise Return({
			'ret': True,
			'role_id': objectid2string(roleID),
			'saved_modules': saved_modules,
		})

	@rpc_coroutine
	def gmScanDataAnomalies(self, scanType='all', limit=100):
		'''
		扫描在线玩家数据异常
		scanType: 扫描类型 - 'all'全部, 'memory_db_diff'内存数据库差异, 'value_abnormal'数值异常
		limit: 最大扫描玩家数
		返回异常列表
		'''
		from game.object.game import ObjectGame
		from framework.helper import objectid2string
		
		anomalies = []
		scanned_count = 0
		online_count = len(ObjectGame.ObjsMap)
		
		# 定义异常检测规则
		# 注意：没有 coin 属性，是 coin1-coin22
		CURRENCY_FIELDS = ['gold', 'rmb', 'stamina']
		MAX_CURRENCY = 999999999  # 最大货币值
		MAX_LEVEL = 500  # 最大等级
		MAX_VIP = 30  # 最大VIP等级
		
		for role_id, game in ObjectGame.ObjsMap.iteritems():
			if scanned_count >= limit:
				break
			scanned_count += 1
			
			try:
				role = game.role
				player_anomalies = []
				
				# 调试日志
				logger.info('[gmScanDataAnomalies] Scanning player %s (uid=%s), gold=%s, rmb=%s, stamina=%s', 
					role.name, role.uid, role.gold, role.rmb, role.stamina)
				
				# ========== 1. 数值异常检测 ==========
				if scanType in ['all', 'value_abnormal']:
					# 检测负数货币
					for field in CURRENCY_FIELDS:
						value = getattr(role, field, 0)
						logger.info('[gmScanDataAnomalies] Checking %s: value=%s, MAX=%s, is_over=%s', 
							field, value, MAX_CURRENCY, value > MAX_CURRENCY)
						if value < 0:
							player_anomalies.append({
								'type': 'negative_value',
								'field': field,
								'value': value,
								'severity': 'critical',
								'desc': u'%s为负数: %d' % (field, value),
							})
						elif value > MAX_CURRENCY:
							player_anomalies.append({
								'type': 'overflow_value',
								'field': field,
								'value': value,
								'severity': 'warning',
								'desc': u'%s超大值: %d' % (field, value),
							})
					
					# 检测等级异常
					if role.level < 1 or role.level > MAX_LEVEL:
						player_anomalies.append({
							'type': 'invalid_level',
							'field': 'level',
							'value': role.level,
							'severity': 'critical',
							'desc': u'等级异常: %d' % role.level,
						})
					
					# 检测VIP异常
					if role.vip_level < 0 or role.vip_level > MAX_VIP:
						player_anomalies.append({
							'type': 'invalid_vip',
							'field': 'vip_level',
							'value': role.vip_level,
							'severity': 'warning',
							'desc': u'VIP等级异常: %d' % role.vip_level,
						})
					
					# 检测战力异常（负数或超大）
					if role.battle_fighting_point < 0:
						player_anomalies.append({
							'type': 'negative_fighting_point',
							'field': 'battle_fighting_point',
							'value': role.battle_fighting_point,
							'severity': 'critical',
							'desc': u'战力为负数: %d' % role.battle_fighting_point,
						})
					
					# 检测经验异常
					if hasattr(role, 'exp') and role.exp < 0:
						player_anomalies.append({
							'type': 'negative_exp',
							'field': 'exp',
							'value': role.exp,
							'severity': 'warning',
							'desc': u'经验为负数: %d' % role.exp,
						})
				
				# ========== 2. 内存与数据库差异检测 ==========
				if scanType in ['all', 'memory_db_diff']:
					db_role_id = role.id
					role_db = yield self.dbcGame.call_async('DBRead', 'Role', db_role_id, False)
					if role_db['ret'] and role_db['model']:
						db_model = role_db['model']
						
						# 检测关键字段差异（注意：没有 coin/recharge_rmb 属性）
						critical_fields = [
							('gold', 'gold'),
							('rmb', 'rmb'),
							('level', 'level'),
							('vip_level', 'vip_level'),
						]
						
						for mem_field, db_field in critical_fields:
							mem_val = getattr(role, mem_field, 0)
							db_val = db_model.get(db_field, 0)
							if mem_val != db_val:
								# 计算差异百分比
								diff = abs(mem_val - db_val)
								max_val = max(abs(mem_val), abs(db_val), 1)
								diff_percent = (diff * 100.0) / max_val
								
								severity = 'info'
								if diff_percent > 50 or diff > 10000:
									severity = 'critical'
								elif diff_percent > 10 or diff > 1000:
									severity = 'warning'
								
								player_anomalies.append({
									'type': 'memory_db_diff',
									'field': mem_field,
									'memory_value': mem_val,
									'db_value': db_val,
									'diff': diff,
									'diff_percent': round(diff_percent, 2),
									'severity': severity,
									'desc': u'%s 内存:%s 数据库:%s 差异:%d(%.1f%%)' % (
										mem_field, mem_val, db_val, diff, diff_percent
									),
								})
				
				# ========== 3. 数据完整性检测 ==========
				if scanType in ['all', 'value_abnormal']:
					# 检测卡牌数量异常
					cards_count = len(role.cards) if hasattr(role, 'cards') and role.cards else 0
					if cards_count == 0:
						player_anomalies.append({
							'type': 'no_cards',
							'field': 'cards',
							'value': 0,
							'severity': 'warning',
							'desc': u'玩家没有卡牌',
						})
					elif cards_count > 500:
						player_anomalies.append({
							'type': 'too_many_cards',
							'field': 'cards',
							'value': cards_count,
							'severity': 'info',
							'desc': u'卡牌数量过多: %d' % cards_count,
						})
				
				# 如果有异常，添加到结果
				if player_anomalies:
					anomalies.append({
						'role_id': objectid2string(role.id),
						'uid': role.uid,
						'name': role.name,
						'level': role.level,
						'anomaly_count': len(player_anomalies),
						'anomalies': player_anomalies,
					})
					
			except Exception as e:
				logger.warning('[gmScanDataAnomalies] Error scanning player %s: %s', role_id, e)
				continue
		
		# 按异常严重程度排序
		def get_severity_score(player):
			score = 0
			for a in player['anomalies']:
				if a['severity'] == 'critical':
					score += 100
				elif a['severity'] == 'warning':
					score += 10
				else:
					score += 1
			return score
		
		anomalies.sort(key=get_severity_score, reverse=True)
		
		# 统计
		critical_count = sum(1 for p in anomalies for a in p['anomalies'] if a['severity'] == 'critical')
		warning_count = sum(1 for p in anomalies for a in p['anomalies'] if a['severity'] == 'warning')
		info_count = sum(1 for p in anomalies for a in p['anomalies'] if a['severity'] == 'info')
		
		raise Return({
			'ret': True,
			'scan_type': scanType,
			'online_count': online_count,
			'scanned_count': scanned_count,
			'anomaly_player_count': len(anomalies),
			'critical_count': critical_count,
			'warning_count': warning_count,
			'info_count': info_count,
			'anomalies': anomalies[:50],  # 限制返回数量
		})

	'''
	二阶段提交
	'''
	def VoteTransaction(self, key, transaction):
		if transaction in self.tscCommits:
			return self.tscCommits[transaction]
		if transaction not in self.tscVotes:
			self.tscVotes[transaction] = (key, time.time())
		else:
			if time.time() - self.tscVotes[transaction][1] > NodeCommitTimeout:
				self.tscVotes[transaction] = (key, time.time())
			elif key < self.tscVotes[transaction]:
				self.tscVotes[transaction] = (key, time.time())
		return self.tscVotes[transaction][0]

	@rpc_coroutine
	def CommitTransaction(self, key, transaction):
		if transaction in self.tscCommits:
			raise Return(self.tscCommits[transaction])
		if transaction not in self.tscVotes:
			raise Return('error')
		if key == self.tscVotes[transaction][0]:
			self.tscVotes.pop(transaction)
			# commited状态需要上层应用手动清理
			self.tscCommits[transaction] = key
			ret = yield self.onTransactionCommit(key, transaction)
			if ret is False:
				raise Return('refuse')
			raise Return(key)
		else:
			raise Return(self.tscVotes[transaction][0])

	def CommittedOver(self, key, transaction):
		if key == self.tscCommits.get(transaction, None):
			self.tscCommits.pop(transaction)
		return True

	@coroutine
	def onTransactionCommit(self, key, transaction):
		logger.info('onTransactionCommit %s %s', key, transaction)
		if transaction == 'crosscraft':
			ret = yield ObjectCrossCraftGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'crossarena':
			ret = yield ObjectCrossArenaGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'crosssupremacy':
			ret = yield ObjectCrossSupremacyGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'onlinefight':
			ret = yield ObjectCrossOnlineFightGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'crossfishing':
			ret = yield ObjectCrossFishingGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'crossgym':
			ret = yield ObjectGymGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'huodongboss':
			ret = yield ObjectServerGlobalRecord.onCrossCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'crossmine':
			ret = yield ObjectCrossMineGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		elif transaction == "crossunionqa":
			ret = yield ObjectServerGlobalRecord.onCrossUnionQACommit(key, transaction)
			raise Return(ret)
		elif transaction == 'crossredpacket':
			ret = yield ObjectServerGlobalRecord.onHuoDongCrossRedPacketCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'crosschat':
			ret = yield ObjectServerGlobalRecord.onCrossChatCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'skyscraper':
			ret = yield ObjectServerGlobalRecord.onHuoDongCrossSkyscraperCommit(key, transaction)
			raise Return(ret)
		elif transaction.startswith('crossranking'):
			transaction = '_'.join(transaction.split('_')[1:])
			ret = yield ObjectServerGlobalRecord.onCrossRankingCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'crosshorse':
			ret = yield ObjectServerGlobalRecord.onCrossHorseRaceCommit(key, transaction)
			raise Return(ret)
		elif transaction == 'crossunionfight':
			ret = yield ObjectCrossUnionFightGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		# [拟态对战] 跨服事务提交
		elif transaction == 'crossmimicry':
			ret = yield ObjectCrossMimicryGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		# [家园派对] 跨服事务提交
		elif transaction == 'crosstownparty':
			ret = yield ObjectCrossTownPartyGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		# [跨服卡牌对决] 跨服事务提交
		elif transaction == 'crossautochess':
			ret = yield ObjectCrossAutoChessGameGlobal.onCrossCommit(key, transaction)
			raise Return(ret)
		raise Return(False)

	######### 跨服石英大会
	@rpc_coroutine
	def CrossCraftEvent(self, event, key, data, sync):
		ret = yield ObjectCrossCraftGameGlobal.onCrossEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def CrossArenaEvent(self, event, key, data, sync):
		ret = yield ObjectCrossArenaGameGlobal.onCrossEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def CrossSupremacyEvent(self, event, key, data, sync):
		ret = yield ObjectCrossSupremacyGameGlobal.onCrossEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def CrossOnlineFightEvent(self, event, key, data, sync):
		ret = yield ObjectCrossOnlineFightGameGlobal.onCrossEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	@notify
	def CrossMatchServerCheck(self, crossKey, t):
		from framework import datetimefromtimestamp
		from game import globaldata

		openTime = globaldata.GameServOpenDatetime
		ndt = datetimefromtimestamp(t)

		dt = ndt.date() - openTime.date()
		days = dt.days
		if openTime.hour < 5 and ndt.hour >= 5:
			days += 1
		elif ndt.hour < 5 and openTime.hour >= 5:
			days -= 1
		days = max(days, 0)

		yield self.game.container.getserviceOrCreate(crossKey).call_async_timeout('ServiceCheckBack', 15, self.game.name, MergeServ.getSrcServKeys(self.game.name), days)
		raise Return('ok')

	@rpc_coroutine
	def CrossFishingEvent(self, event, key, data, sync):
		ret = yield ObjectCrossFishingGameGlobal.onCrossEvent(event, key, data, sync)
		raise Return(ret)

	# [拟态对战] 跨服事件处理
	@rpc_coroutine
	def CrossMimicryEvent(self, event, key, data, sync):
		ret = yield ObjectCrossMimicryGameGlobal.onCrossEvent(event, key, data, sync)
		raise Return(ret)

	# [跨服卡牌对决] 跨服事件处理
	@rpc_coroutine
	def CrossAutoChessEvent(self, event, key, data, sync):
		ret = yield ObjectCrossAutoChessGameGlobal.onCrossEvent(event, key, data, sync)
		raise Return(ret)

	# [家园派对] 跨服事件处理
	@rpc_coroutine
	def CrossTownPartyEvent(self, event, key, data, sync):
		ret = yield ObjectCrossTownPartyGlobal.onCrossEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def GymEvent(self, event, key, data, sync):
		ret = yield ObjectGymGameGlobal.onGymEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def HuoDongBossEvent(self, event, key, data, sync):
		ret = yield ObjectServerGlobalRecord.onHuoDongBossEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def CrossMineEvent(self, event, key, data, sync):
		ret = yield ObjectCrossMineGameGlobal.onCrossEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def CrossUnionQAEvent(self, event, key, data, sync):
		ret = yield ObjectServerGlobalRecord.onCrossUnionQAEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def HuoDongCrossRedPacketEvent(self, event, key, data, sync):
		ret = yield ObjectServerGlobalRecord.onHuoDongCrossRedPacketEvent(event, key, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def CrossChatEvent(self, event, key, data):
		ret = yield ObjectServerGlobalRecord.onCrossChatEvent(event, key, data, False)
		raise Return(ret)

	@rpc_coroutine
	def CrossChatMsgPush(self, msgData):
		ObjectServerGlobalRecord.onCrossChatMsgPush(msgData)
		yield moment
		raise Return(None)

	@rpc_coroutine
	def HuoDongCrossSkyscraperEvent(self, event, key):
		ret = yield ObjectServerGlobalRecord.onHuoDongCrossSkyscraperEvent(event, key)
		raise Return(ret)

	@rpc_coroutine
	def HuoDongCrossRankingEvent(self, gamePlay, event, key):
		ret = yield ObjectServerGlobalRecord.onCrossRankingEvent(gamePlay, event, key)
		raise Return(ret)

	@rpc_coroutine
	def GetOpenDays(self, key):
		days = todayinclock5elapsedays(globaldata.GameServOpenDatetime)
		logger.info('%s openDays %d', key, days)
		raise Return(int(days))

	def CrossGetRoleLastTime(self, roleID):
		from game.object.game import ObjectGame
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			return int(game.role.last_time)
		else:
			return 0

	@rpc_coroutine
	def CrossGetRoleInfo(self, roleID):
		'''跨服查询角色信息'''
		from framework.helper import string2objectid
		from game.object.game.cache import ObjectCacheGlobal
		from game.object.game.union import ObjectUnion

		ret = None
		try:
			roleID = string2objectid(roleID)
			ret = yield ObjectCacheGlobal.queryRole(roleID)
			if ret:
				ret['union_name'] = ObjectUnion.queryUnionName(roleID)
		except Exception as e:
			logger.warning('CrossGetRoleInfo error: %s', e)
		
		raise Return(ret)

	@rpc_coroutine
	def CrossGetCardInfo(self, cardID):
		'''跨服查询卡牌信息'''
		from framework.helper import string2objectid
		from game.object.game.cache import ObjectCacheGlobal

		ret = None
		try:
			cardID = string2objectid(cardID)
			ret = yield ObjectCacheGlobal.queryCard(cardID)
		except Exception as e:
			logger.warning('CrossGetCardInfo error: %s', e)
		
		raise Return(ret)

	@rpc_coroutine
	def CrossGetPlayRecord(self, recordID):
		'''跨服查询战报数据'''
		from framework.helper import string2objectid
		from game.server import Server

		ret = None
		try:
			recordID = string2objectid(recordID)
			container = Server.Singleton.container
			arenaKey = Server.Singleton.key.replace('game', 'arena')
			arenaClient = container.getserviceOrCreate(arenaKey)
			if arenaClient:
				ret = yield arenaClient.call_async('GetArenaPlayRecord', recordID)
		except Return:
			raise
		except Exception as e:
			logger.warning('CrossGetPlayRecord error: %s', e)
		
		raise Return(ret)

	@rpc_coroutine
	def CrossGetArenaRecordByRoleID(self, roleID):
		'''跨服通过 roleID 获取竞技场记录（用于跨服挑战）'''
		from framework.helper import string2objectid
		from game.server import Server

		ret = None
		try:
			roleID = string2objectid(roleID)
			# 调用本地 Arena 服务获取记录数据
			container = Server.Singleton.container
			arenaKey = Server.Singleton.key.replace('game', 'arena')
			arenaClient = container.getserviceOrCreate(arenaKey)
			if arenaClient:
				ret = yield arenaClient.call_async('GetArenaRecordDataByRoleID', roleID)
		except Return:
			raise
		except Exception as e:
			logger.warning('CrossGetArenaRecordByRoleID error: %s', e)
		
		raise Return(ret)

	@rpc_coroutine
	def CrossSupremacyGetRecord(self, recordID):
		'''跨服获取冠军赛战斗记录'''
		from framework.helper import string2objectid, objectid2string
		from game.object.game import ObjectGame

		ret = None
		try:
			if isinstance(recordID, dict):
				recordID = recordID.get('record_db_id', None) or recordID.get('role_db_id', None)
			if isinstance(recordID, basestring):
				roleID = string2objectid(recordID)
			else:
				roleID = recordID
			game = ObjectGame.getByRoleID(roleID, safe=False)
			if game and game.role:
				from game.handler._cross_supremacy import _ensure_supremacy_data, _build_record_view, _get_show_card_from_record
				data = _ensure_supremacy_data(game)
				record = _build_record_view(game, data.get('record', None))
				record['record_db_id'] = objectid2string(game.role.id)
				record['role_db_id'] = objectid2string(game.role.id)
				record['game_key'] = game.role.areaKey
				record['role_level'] = game.role.level
				record['name'] = game.role.name
				record['logo'] = game.role.logo
				record['frame'] = game.role.frame
				record['figure'] = getattr(game.role, 'figure', 0) or 1
				record['title'] = getattr(game.role, 'title_id', 0)
				record['score'] = data.get('score', 0)
				record['fighting_point'] = getattr(game.role, 'top12_fighting_point', 0)
				record['show_card'] = _get_show_card_from_record(record)
				ret = record
			else:
				from game.handler._cross_supremacy import (
					_build_offline_record_view,
					_build_record_base,
					_get_show_card_from_record,
					_record_has_battle_data,
				)
				role_ret = yield self.dbcGame.call_async('DBRead', 'Role', roleID, False)
				if role_ret and role_ret.get('ret') and role_ret.get('model'):
					role_db = role_ret['model']
					data = role_db.get('cross_supremacy_datas', {}) or {}
					record = dict(data.get('record', {}))
					if not _record_has_battle_data(record):
						record_view = yield _build_offline_record_view(self.dbcGame, role_db, record)
						if record_view:
							record = record_view
						else:
							empty_cards = [None] * 18
							record = _build_record_base(
								empty_cards,
								empty_cards,
								{},
								{},
								[],
								[],
								{'weather': 0, 'arms': []},
								{'weather': 0, 'arms': []},
							)
							record['card_attrs'] = {}
							record['card_attrs2'] = {}
							record['defence_card_attrs'] = {}
							record['defence_card_attrs2'] = {}
							record['passive_skills'] = {}
							record['defence_passive_skills'] = {}
					record['record_db_id'] = objectid2string(roleID)
					record['role_db_id'] = objectid2string(roleID)
					record['game_key'] = role_db.get('game_key', '')
					record['role_level'] = role_db.get('level', 1)
					record['name'] = role_db.get('name', '')
					record['logo'] = role_db.get('logo', 1)
					record['frame'] = role_db.get('frame', 1)
					record['figure'] = role_db.get('figure', 1) or 1
					record['title'] = role_db.get('title_id', 0)
					record['score'] = data.get('score', 0)
					record['fighting_point'] = role_db.get('top12_fighting_point', role_db.get('battle_fighting_point', 0))
					record['show_card'] = _get_show_card_from_record(record)
					ret = record
		except Exception as e:
			logger.warning('CrossSupremacyGetRecord error: %s', e)

		raise Return(ret)

	@rpc_coroutine
	def CrossUnionFightEvent(self, event, key, data, sync):
		ret = yield ObjectCrossUnionFightGameGlobal.onCrossEvent(event, key, data, sync)
		raise Return(ret)

	######### 石英大会
	@rpc_coroutine
	def CraftEvent(self, event, data, sync):
		from game.object.game.craft import ObjectCraftInfoGlobal
		ret = yield ObjectCraftInfoGlobal.onCraftEvent(event, data, sync)
		raise Return(ret)
	@rpc_coroutine
	def UnionFightEvent(self, event, data, sync):
		from game.object.game.union_fight import ObjectUnionFightGlobal
		ret = yield ObjectUnionFightGlobal.onUnionFightEvent(event, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def BraveChallengeEvent(self, event, data, sync):
		from game.object.game.yyhuodong import ObjectYYBraveChallenge
		ret = yield ObjectYYBraveChallenge.onBraveChallengeEvent(event, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def SummerChallengeEvent(self, event, data, sync):
		from game.object.game.yyhuodong import ObjectYYSummerChallenge
		ret = yield ObjectYYSummerChallenge.onSummerChallengeEvent(event, data, sync)
		raise Return(ret)

	@rpc_coroutine
	def GMGetRoleCards(self, roleID, cardIDs):
		from game.object.game import ObjectGame
		roleID = yield self._prepareRoleID(roleID)
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			if not cardIDs:
				cardIDs = game.role.cards
			cards = {}
			for cardID in cardIDs:
				card = game.cards.getCard(cardID)
				cards[cardID] = dict(card.db)
				cards[cardID]['name'] = card.name
			raise Return({
				'role': {
					'id': game.role.id,
					'name': game.role.name,
				},
				'cards': cards,
			})

	def GMEvalCardAttrs(self, roleID, cardID, disables):
		from game.object.game import ObjectGame
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			card = game.cards.getCard(cardID)
			attrs, display = card.calcFilterAttrs(disables=disables)
			return {'attrs': attrs, 'display': display}

	@coroutine
	def _fakeLogin(self, roleID):
		from game.object.game import ObjectGame
		servID = int(self.game.key.split('.')[-1])
		roleID = yield self._prepareRoleID(roleID)
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			raise Return('online')
		accountID = roleID

		from game.handler._game import GameLogin
		class FakeGameLogin(GameLogin):
			def __init__(self, application, session):
				self.application = application
				self.session = session
				self.accountID = None # 为了fix时用role_id查找
				# self.accountID = accountID
				self.roleID = roleID
				self.input = {}

			def write(self, view):
				pass

		session = Session(servID, accountID, str(accountID), accountID, {}, {})
		Session.setSession(session)
		handler = FakeGameLogin(self.game.application, session)
		yield handler.loading()
		raise Return('fake login')

	@coroutine
	def _discardFakeLogin(self, roleID):
		from game.object.game import ObjectGame
		servID = int(self.game.key.split('.')[-1])
		roleID = yield self._prepareRoleID(roleID)
		accountID = roleID
		game = ObjectGame.getByRoleID(roleID, safe=False)
		if game:
			ObjectGame.popByRoleID(roleID)
			Session.discardSessionByAccountKey((game.role.area, game.role.account_id)) # real accountKey, _syncLast
		Session.discardSessionByAccountKey((servID, accountID)) # fake accountKey, _syncLast

	@rpc_coroutine
	def GMRollbackRoleItem(self, roleID, items, award, costMap):
		roleID = yield self._prepareRoleID(roleID)
		from game.object.game import ObjectGame
		game = ObjectGame.ObjsMap.get(roleID, None)
		if game is None:
			yield self._fakeLogin(roleID)
			logger.info('role %s fake login', objectid2string(roleID))
		game, safeGuard = ObjectGame.getByRoleID(roleID)
		if not game:
			raise Return('not load')
		costResult = False
		gainResult = False
		with safeGuard:
			from game.object.game.gain import ObjectCostAux, ObjectGainAux
			from game.handler.inl import effectAutoGain
			from framework.helper import string2objectid

			cost = ObjectCostAux(game, items)
			# 卡牌
			if "cards" in costMap:
				costCards = []
				for cardID in costMap["cards"]:
					card = game.cards.getCard(string2objectid(cardID))
					costCards.append(card)
				cost.setCostCards(costCards)
			# 携带道具
			if "heldItems" in costMap:
				costHeldItems = []
				for heldItemID in costMap["heldItems"]:
					heldItem = game.heldItems.getHeldItem(string2objectid(heldItemID))
					costHeldItems.append(heldItem)
				for obj in costHeldItems:
					cardID = obj.card_db_id
					if cardID: # 如果已经装备了，脱下
						obj.card_db_id = None
						card = game.cards.getCard(cardID)
						card.held_item = None
				cost.setCostHeldItems(costHeldItems)
			# 宝石
			if "gems" in costMap:
				costGems = []
				for gemID in costMap["gems"]:
					gem = game.gems.getGem(string2objectid(gemID))
					costGems.append(gem)
				for obj in costGems:
					if obj.card_db_id:
						cardID = obj.card_db_id# 如果已经装备了，脱下
						pos = obj.getGemPos()
						# 卸下
						if pos is not None:
							card = game.cards.getCard(cardID)
							card.gems.pop(pos, None)
							obj.card_db_id = None
				cost.setCostGems(costGems)
			if cost.isEnough():
				cost.cost(src='gm_fix')
				costResult = True
				if award: # 一定先有扣除，再恢复，没扣除的就直接邮件发吧
					eff = ObjectGainAux(game, award)
					yield effectAutoGain(eff, game, self.dbcGame, src='gm_fix')
					gainResult = True
			else:
				costResult = False
		yield self._discardFakeLogin(roleID)
		raise Return((costResult, gainResult))

	@coroutine
	def _doWithLogin(self, roleID, f):
		from game.object.game import ObjectGame
		game = ObjectGame.ObjsMap.get(roleID, None)
		if game is None:
			yield self._fakeLogin(roleID)
			logger.info('role %s fake login', objectid2string(roleID))
		game, safeGuard = ObjectGame.getByRoleID(roleID)
		if not game:
			raise Return(False)
		try:
			with safeGuard:
				f(game)
		except Exception, e:
			logger.exception('_doWithLogin error', e)
		yield self._discardFakeLogin(roleID)
		raise Return(True)

	@rpc_coroutine
	def GMRecoverRoleCard(self, roleID, cardID):
		if len(cardID) == 24:
			cardID = string2objectid(cardID)
		yield self.dbcGame.call_async('RoleCardRecover', cardID)
		resp = yield self.dbcGame.call_async('DBRead', 'RoleCard', cardID, False)
		if not resp['ret']:
			raise Return('no this card')
		card = resp['model']
		roleID = yield self._prepareRoleID(roleID)
		if card['role_db_id'] != roleID:
			raise Return('not this role card')
		def do(game):
			game.role.cards.append(cardID)
			game.role.cards = list(set(game.role.cards))
			logger.info('role %s recover card %s, card_id %d, star %d', objectid2string(roleID), objectid2string(cardID), card['card_id'], card['star'])
		ok = yield self._doWithLogin(roleID, do)
		if ok:
			raise Return('success')
		else:
			raise Return('failed')

	@rpc_coroutine
	def GMRoleCardExpiredGet(self, roleID):
		roleID = yield self._prepareRoleID(roleID)
		resp = yield self.dbcGame.call_async('RoleCardExpiredGet', roleID)
		raise Return(resp)

	# GM 跑马灯消息
	def GMMarqueeBroadcast(self, msg, key):
		from game.object.game.message import ObjectMessageGlobal
		msg = ObjectMessageGlobal.marqueeMsg(msg, args={'key': key})
		data = {
			'msg': {'msgs': [msg]},
		}
		from game.session import Session
		Session.broadcast('/game/push', data)

class MyRpdb(Rpdb):
	def __init__(self, addr="", port=6161):
		Rpdb.__init__(self, addr, port)

	def do_continue(self, arg):
		"""Clean-up and do underlying continue."""
		try:
			return pdb.Pdb.do_continue(self, arg)
		finally:
			pass

	do_c = do_cont = do_continue
