# -*- coding: utf-8 -*-
from __future__ import absolute_import

from tornado.gen import coroutine
from tornado.web import HTTPError
from framework.helper import string2objectid
from framework import int2date, int2time, todaydate2int

from .base import AuthedHandler, BaseHandler
from gm.util import *
from gm.object.db import MongoDB

from game.object import AttrDefs

import re
import os
import json
import datetime
import binascii
import itertools
import copy
import subprocess
from collections import OrderedDict

# from fabric.api import local, run, env, hosts, sudo, cd, lcd, remote_tunnel, abort, execute
# from fabric.context_managers import settings
# from fabric.contrib.console import confirm


DBDataConvertMap = {
	'union_join_time': lambda d: str(datetime.datetime.fromtimestamp(d)),
	'union_quit_time': lambda d: str(datetime.datetime.fromtimestamp(d)),
	'union_last_time': lambda d: str(datetime.datetime.fromtimestamp(d)),
	'create_time': lambda d: str(datetime.datetime.fromtimestamp(d)),
	'created_time': lambda d: str(datetime.datetime.fromtimestamp(d)),
	'last_time': lambda d: str(datetime.datetime.fromtimestamp(d)),
	'time': lambda d: str(datetime.datetime.fromtimestamp(d)),
	'cards': lambda d: len(d),
	'items': lambda d: sum(d.values()),
	'frags': lambda d: sum(d.values()),
	'recharges': lambda d: sum([d[x]['cnt'] for x in d if x > 0 and 'cnt' in d[x]]),
	'gifts': lambda d: len(d) - len([x for x in d if isinstance(x, int) and x < 0]),
	'account_roles': lambda d: str(d),
	'heirlooms': lambda d: str(d),
	'talent_trees': lambda d: str(d),
	'skins': lambda d: str(d),
	'attachs': lambda d: str(d),
	'newbie_guide': lambda l: max(l) if l else [],
	'beginDate': lambda d: str(int2date(d)),
	'beginTime': lambda d: str(int2time(d)),
	'endDate': lambda d: str(int2date(d)),
	'endTime': lambda d: str(int2time(d)),
	'paramMap': lambda d: str(d),
	'clientParam': lambda d: str(d),
	'explain': lambda d: str(d),
	'metals': lambda d: len(d),
	'yh_equips': lambda d: len(d),
}

# 玩家活动
class RoleActivityHancler(AuthedHandler):
	url = '/role_activity'

	@coroutine
	def get(self):
		self.render_page("_role_activity.html")


# 发送邮件
class SenderMailHandler(AuthedHandler):
	url = "/sendmail"

	@coroutine
	def get(self):
		self.render_page("_send_mail.html")

	@coroutine
	def post(self):
		paramData = self.get_json_data()

		mailType = paramData['mailType']
		mailAddressee = paramData['receive'] or False
		mailSender = paramData['sender'] or False
		mailTitle = paramData['subject'] or False
		mailContent = paramData['content'] or False
		beginVip = paramData['beginVip'] or False
		endVip = paramData['endVip'] or False

		# 全服邮件发送邮件模板不能转，默认第一个模板。
		try:
			mailTemplate = int(paramData.get('mailTemp', False))
		except Exception as e:
			mailTemplate = 1

		# 附件
		mailAttach = json.loads(paramData.get('attachs'))
		for k, v in mailAttach.items():
			try:
				newk = int(k)
			except ValueError:
				pass
			else:
				mailAttach.pop(k, None)
				mailAttach[newk] = v

		if paramData['servName'] == "allservers":
			servName = "__@global@__"
		else:
			servName = paramData['servName']

		if mailType == "role":
			mailAddresseeList = mailAddressee.split(';')
			retS, retF = [], []
			for roleID in mailAddresseeList:
				r = yield self.userGMRPC.gmSendMail(self.session, servName, roleID, mailTemplate, mailSender, mailTitle, mailContent, mailAttach) # 发送个人邮件
				if r:
					retS.append(roleID)
				else:
					retF.append(roleID)
			self.write({'retF': retF, 'retS': retS})

		elif mailType == "server" or mailType == "allserver":
			ret = yield self.userGMRPC.gmSendServerMail(self.session, servName, mailTemplate, mailSender, mailTitle, mailContent, mailAttach) # 全服邮件
			self.write({'result': ret})

		elif mailType == "global" or mailType == "allglobal":
			ret = yield self.userGMRPC.gmSendGlobalMail(self.session, servName, mailTemplate, mailSender, mailTitle, mailContent, mailAttach) # 全局邮件
			self.write({'result': ret})

		elif mailType == "union":
			mailAddresseeList = mailAddressee.split(';')
			retS, retF = [], []
			for unionID in mailAddresseeList:
				r = yield self.userGMRPC.gmSendUnionMail(self.session, servName, int(unionID), mailTemplate, mailSender, mailTitle, mailContent, mailAttach) # 公会邮件
				if r:
					retS.append(unionID)
				else:
					retF.append(unionID)
			self.write({'retF': retF, 'retS': retS})

		elif mailType == "account":
			mailAddresseeList = mailAddressee.split(';')
			retS, retF = [], []
			for accountName in mailAddresseeList:
				r = yield self.userGMRPC.gmSendNewbieMail(self.session, servName, accountName, mailTemplate, mailSender, mailTitle, mailContent, mailAttach)
				if r:
					retS.append(accountName)
				else:
					retF.append(accountName)
			self.write({'retF': retF, 'retS': retS})

		elif mailType == "vip" or mailType == "allvip":
			beginVip, endVip = int(beginVip), int(endVip)
			ret = yield self.userGMRPC.gmSendVipMail(self.session, servName, beginVip, endVip, mailTemplate, mailSender, mailTitle, mailContent, mailAttach) # vip邮件
			self.write({"result": ret})

		else:
			raise HTTPError(404, reason="wrong mailtype")


# 获取邮件模板
class GetMailTemplateHandler(AuthedHandler):
	url = "/sendmail/mail_template"

	@coroutine
	def get(self):
		servName = self.get_argument("servName")
		result = yield self.userGMRPC.gmGetMailCsv(self.session, servName)
		self.write(result)


# 玩家详细信息
class RoleDetailHandler(AuthedHandler):
	url = r'/role_detail'

	@coroutine
	def get(self):
		servName = self.get_argument('servName', 'All')
		roleSearch = self.get_argument('roleSearch', None)

		if servName == "All":
			raise HTTPError(404, reason='servName error')

		roleID = None
		roleTuple = None

		if roleSearch.startswith('(') and roleSearch.endswith(')'):
			roleTuple = eval(roleSearch)

		elif len(roleSearch) == 24:
			roleID = string2objectid(roleSearch)

		else:
			try:
				roleID = int(roleSearch)
			except ValueError as e:
				pass

		columns = [
			{'field': 'account_name', 'title': '渠道账号'},
			{'field': 'account_id', 'title': '账号ID'},
			{'field': 'id', 'title': '角色ID'},
			{'field': 'uid', 'title': '角色UID'},
			{'field': 'area', 'title': '创角区服'},
			# {'field': 'area_role_db_id', 'title': '创角角色ID'},
			{'field': 'name', 'title': '角色名'},
			{'field': 'level', 'title': '等级'},
			{'field': 'vip_level', 'title': 'VIP'},
			{'field': 'disable_flag', 'title': '封号'},
			{'field': 'silent_flag', 'title': '禁言'},
			{'field': 'gold', 'title': '金币'},
			{'field': 'rmb', 'title': '钻石'},
			{'field': 'qq_rmb', 'title': 'QQ托管钻石'},
			{'field': 'qq_recharge', 'title': 'QQ充值总额'},
			{'field': 'recharges', 'title': '充值次数'},
			{'field': 'recharges_total', 'title': '充值总额'},
			{'field': 'rmb_consume', 'title': '钻石消耗'},
			{'field': 'coin1', 'title': '竞技场币'},
			{'field': 'coin2', 'title': '远征币'},
			{'field': 'coin3', 'title': '公会币'},
			{'field': 'coin4', 'title': '合金精华'},
			{'field': 'coin5', 'title': '探索币'},
			{'field': 'coin6', 'title': 'coin6币'},
			{'field': 'union_db_id', 'title': '公会ID'},
			{'field': 'tw_top_floor', 'title': '最高塔层'},
			{'field': 'battle_fighting_point', 'title': '卡牌战斗力'},
			{'field': 'top6_fighting_point', 'title': '历史最高前6卡牌战斗力'},
			{'field': 'top12_fighting_point', 'title': '历史最高前12卡牌战斗力'},
			{'field': 'cardNum_rank', 'title': '卡牌数排行'},
			{'field': 'fight_rank', 'title': '战力排行'},
			{'field': 'gate_star_rank', 'title': '星级排行'},
			{'field': 'card1fight_rank', 'title': '单卡战斗力排行'},
			{'field': 'pw_rank', 'title': '竞技场排行'},
			{'field': 'achieve_rank', 'title': '成就排行'},
			# {'field': 'galaxy_rank', 'title': '星座排行'},
			{'field': 'stamina', 'title': '体力'},
			{'field': 'created_time', 'title': '创建时间'},
			{'field': 'last_time', 'title': '最近操作时间'},
			{'field': '_online_', 'title': '在线'},
			{'field': 'account_roles', 'title': '所有区服'},
			{'field': 'talent_point', 'title': '天赋点'},
			{'field': 'skill_point', 'title': '技能点'},
			{'field': 'fightgo', 'title': '先手值'},
			{'field': 'achieve_fightgo', 'title': '成就先手值'},
			{'field': 'equip_awake_frag', 'title': '觉醒碎片'},
			{'field': 'cards', 'title': '卡牌数'},
			{'field': 'items', 'title': '道具数'},
			{'field': 'frags', 'title': '碎片数'},
			# {'field': 'metals', 'title': '合金数'},
			# {'field': 'yh_equips', 'title': '援护装备数'},
			{'field': 'skins', 'title': '皮肤'},
			{'field': 'card_advance_times', 'title': '卡牌进阶次数'},
			{'field': 'card_star_times', 'title': '卡牌升星次数'},
			{'field': 'gifts', 'title': '已领取礼包'},
			{'field': 'newbie_guide', 'title': '新手引导'},
			{'field': 'union_join_time', 'title': '加入公会时间'},
			{'field': 'union_quit_time', 'title': '退出公会时间'},
			{'field': 'union_last_time', 'title': '最近公会操作时间'},
			{'field': 'talent_trees', 'title': '天赋树'},
			# {'field': 'heirlooms', 'title': '神器'},
		]

		if roleID:
			ret = yield self.userGMRPC.gmGetRoleInfo(self.session, servName, roleID)
		elif roleTuple:
			ret = yield self.userGMRPC.gmGetRoleInfoByRoleKey(self.session, servName, roleTuple)
		else:
			ret = yield self.userGMRPC.gmGetRoleInfoByName(self.session, servName, roleSearch)

		if len(ret) == 0:
			raise HTTPError(404, reason='no such role')

		if 'account_name' in ret and ret['account_name'].find('shuguo_') >= 0:
			raise HTTPError(404, reason='no such role')

		result = {'_online_': False}
		for field in [x['field'] for x in columns]:
			if field in ret:
				result[field] = ret[field]
				if field in DBDataConvertMap:
					result[field] = DBDataConvertMap[field](ret[field])

		# recharges {csv_id:{cnt:0, date:20141206, orders:[PayOrder.id], reset:0 or yyid or -yyid}}
		from framework.csv import csv
		recharges = csv.recharges.to_dict()
		sumRecharges = 0
		for k, d in ret['recharges'].iteritems():
			if k > 0:
				for j in xrange(d.get('cnt', 0)):
					sumRecharges += recharges.get(k, {}).get('rmb', 0)
		result['recharges_total'] = sumRecharges

		# 转化12位objectid
		data = hexlifyDictField(result)

		columns = self.setLocalColumns(columns)
		self.write({
			'columns': columns,
			'data': [data],
		})


# 玩家封号、禁言
class BanPlayerHandler(AuthedHandler):
	url = r'/ban_player'

	@coroutine
	def get(self):
		banType = self.get_argument('banType')
		servName = self.get_argument('servName')
		if not is_key(servName):
			servName = servName2ServKey(servName)

		roleID = self.get_argument('roleID')
		try:
			roleID = int(roleID)
		except ValueError as e:
			roleID = string2objectid(roleID)

		val = self.get_argument('val')
		if val == 'true':
			val = True
		elif val == 'false':
			val = False
		else:
			raise HTTPError(404, 'val is incorrect')

		ret = yield self.userGMRPC.gmRoleAbandon(self.session, servName, roleID, banType, val)
		self.write({'val': val})


# 踢玩家下线页面
class KickPlayerPageHandler(AuthedHandler):
	url = r'/kick_player_page'

	@coroutine
	def get(self):
		self.render_page("_kick_player.html")


# 踢玩家下线API
class KickPlayerHandler(AuthedHandler):
	url = r'/kick_player'

	@coroutine
	def get(self):
		'''踢单个玩家下线'''
		servName = self.get_argument('servName')
		if not is_key(servName):
			servName = servName2ServKey(servName)

		roleID = self.get_argument('roleID')
		try:
			roleID = int(roleID)
		except ValueError as e:
			roleID = string2objectid(roleID)

		ret = yield self.userGMRPC.gmKickPlayer(self.session, servName, roleID)
		self.write(ret)

	@coroutine
	def post(self):
		'''批量踢玩家下线'''
		data = self.get_json_data()
		servName = data.get('servName', None)
		roleIDs = data.get('roleIDs', [])  # 玩家ID列表
		kickAll = data.get('kickAll', False)  # 是否踢所有人

		if not servName:
			raise HTTPError(400, reason='servName is required')

		if not is_key(servName):
			servName = servName2ServKey(servName)

		results = []
		if kickAll:
			# 踢所有在线玩家
			ret = yield self.userGMRPC.gmKickAllPlayers(self.session, servName)
			results.append(ret)
		else:
			# 批量踢指定玩家
			for roleID in roleIDs:
				try:
					if isinstance(roleID, (str, unicode)) and len(roleID) == 24:
						roleID = string2objectid(roleID)
					else:
						roleID = int(roleID)
					ret = yield self.userGMRPC.gmKickPlayer(self.session, servName, roleID)
					results.append({'roleID': str(roleID), 'result': ret})
				except Exception as e:
					results.append({'roleID': str(roleID), 'error': str(e)})

		self.write({'results': results})


# ==================== 内存数据查看器 ====================

# 内存数据查看页面
class MemoryViewerPageHandler(AuthedHandler):
	url = r'/memory_viewer_page'

	@coroutine
	def get(self):
		self.render_page("_memory_viewer.html")


# 获取玩家内存数据API
class MemoryDataHandler(AuthedHandler):
	url = r'/memory_data'

	@coroutine
	def get(self):
		servName = self.get_argument('servName', None)
		roleID = self.get_argument('roleID', None)
		modules = self.get_argument('modules', None)

		if not servName or not roleID:
			raise HTTPError(400, reason='servName and roleID are required')
		if not is_key(servName):
			servName = servName2ServKey(servName)

		# 尝试将 roleID 解析为 int（UID）或 ObjectId
		try:
			roleID = int(roleID)
		except ValueError:
			# 保持字符串，后端会转换为 ObjectId
			pass

		# 解析 modules 参数
		modules_list = None
		if modules:
			modules_list = [m.strip() for m in modules.split(',')]

		ret = yield self.userGMRPC.gmGetPlayerMemoryData(self.session, servName, roleID, modules_list)
		self.write(ret)


# 获取玩家数据库数据API
class DBDataHandler(AuthedHandler):
	url = r'/db_data'

	@coroutine
	def get(self):
		servName = self.get_argument('servName', None)
		roleID = self.get_argument('roleID', None)
		modules = self.get_argument('modules', None)

		if not servName or not roleID:
			raise HTTPError(400, reason='servName and roleID are required')
		if not is_key(servName):
			servName = servName2ServKey(servName)

		# 尝试将 roleID 解析为 int（UID）或保持字符串
		try:
			roleID = int(roleID)
		except ValueError:
			pass

		modules_list = None
		if modules:
			modules_list = [m.strip() for m in modules.split(',')]

		ret = yield self.userGMRPC.gmGetPlayerDBData(self.session, servName, roleID, modules_list)
		self.write(ret)


# 对比玩家数据API
class CompareDataHandler(AuthedHandler):
	url = r'/compare_data'

	@coroutine
	def get(self):
		servName = self.get_argument('servName', None)
		roleID = self.get_argument('roleID', None)

		if not servName or not roleID:
			raise HTTPError(400, reason='servName and roleID are required')
		if not is_key(servName):
			servName = servName2ServKey(servName)

		# 尝试将 roleID 解析为 int（UID）或保持字符串
		try:
			roleID = int(roleID)
		except ValueError:
			pass

		ret = yield self.userGMRPC.gmComparePlayerData(self.session, servName, roleID)
		self.write(ret)


# 强制保存玩家数据API
class ForceSaveHandler(AuthedHandler):
	url = r'/force_save'

	@coroutine
	def post(self):
		data = self.get_json_data()
		servName = data.get('servName', None)
		roleID = data.get('roleID', None)
		modules = data.get('modules', None)

		if not servName or not roleID:
			raise HTTPError(400, reason='servName and roleID are required')
		if not is_key(servName):
			servName = servName2ServKey(servName)

		# 尝试将 roleID 解析为 int（UID）或保持字符串
		try:
			roleID = int(roleID)
		except ValueError:
			pass

		ret = yield self.userGMRPC.gmForceSavePlayer(self.session, servName, roleID, modules)
		self.write(ret)


# 数据异常扫描
class ScanAnomaliesHandler(AuthedHandler):
	url = r'/scan_anomalies'

	@coroutine
	def get(self):
		servName = self.get_argument('servName', None)
		scanType = self.get_argument('scanType', 'all')
		limit = self.get_argument('limit', '100')

		if not servName:
			raise HTTPError(400, reason='servName is required')
		if not is_key(servName):
			servName = servName2ServKey(servName)

		try:
			limit = int(limit)
		except ValueError:
			limit = 100

		ret = yield self.userGMRPC.gmScanDataAnomalies(self.session, servName, scanType, limit)
		self.write(ret)


# 数据异常检测页面
class AnomalyDetectionPageHandler(AuthedHandler):
	url = r'/anomaly_detection_page'

	def get(self):
		self.render_page('_anomaly_detection.html')


# 工会详细信息
class UnionDetailHandler(AuthedHandler):
	url = r'/union_detail'

	@coroutine
	def get(self):
		servName = self.get_argument('servName', 'All')
		unionID = self.get_argument('unionID', False)

		if servName == "All":
			raise HTTPError(404, reason='servName error')
		if not unionID:
			raise HTTPError(404, reason='args missed')
		unionID = int(unionID)

		# columns = [
		# 	{'field': 'id', 'title': '工会ID'},
		# 	{'field': 'name', 'title': '工会名'},
		# 	{'field': 'level', 'title': '工会等级'},
		# 	{'field': 'members', 'title': '工会人数'},
		# 	{'field': 'intro', 'title': '工会简介'},
		# 	{'field': 'contrib', 'title': '总贡献值'},
		# 	{'field': 'day_contrib', 'title': '当日贡献'},
		# 	{'field': 'join_type', 'title': '加入类型'},
		# 	{'field': 'join_level', 'title': '加入等级限制'},
		# ]
		ret = yield self.userGMRPC.gmGetUnionInfo(self.session, servName, unionID)

		if len(ret) == 0:
			raise HTTPError(404, reason='no such union')
		ret["members"] = len(ret["members"])

		# result = {'_online_': False}
		# for field in [x['field'] for x in columns]:
		# 	if field in ret:
		# 		result[field] = ret[field]
		# 		if field in DBDataConvertMap:
		# 			result[field] = DBDataConvertMap[field](ret[field])

		# columns = self.setLocalColumns(columns, self.get_cookie("user_locale"))
		self.write({'data': [ret]})


# 获取vip信息
class getVIPMailConfirmMsg(AuthedHandler):
	url = r'/vip_msg'

	@coroutine
	def run(self):
		servName = self.get_argument("servName", False)
		beginVip = self.get_argument("beginVip", False)
		endVip = self.get_argument("endVip", False)

		if not servName:
			raise HTTPError(404, reason="no this server")
		beginVip, endVip = int(beginVip), int(endVip)
		ret = yield self.userGMRPC.gmGetRoleInfoByVip(self.session, servName, beginVip, endVip)

		vipRoleIDList = [x['id'] for x in ret]
		if not vipRoleIDList:
			msg = '不存在VIP%d到VIP%d范围内的玩家' % (beginVip, endVip)
			self.write({"ret": False, "msg": msg})
		else:
			msg = "将要向以下VIP用户发送邮件:\n"
			vipCount = [0 for i in range(1, 20)]

			for x in ret:
				vipCount[x['vip_level']] = vipCount[x['vip_level']] + 1
			for i in range(beginVip, endVip + 1):
				msg = msg + "VIP%d:  %d人<br>" % (i, vipCount[i])
			self.write({"ret": True, "msg": msg})


# 在线玩家信息
class OnlineRoleHandler(AuthedHandler):
	url = '/online_role'

	@coroutine
	def get(self):
		servName = self.get_argument("servName", "All")
		offset = int(self.get_argument("offset", 0))
		limit = int(self.get_argument("limit", 0))

		if servName == "All":
			raise HTTPError(404, reason='servName error')

		total = 0
		result = []
		columns = [
				{'field': 'account_id', 'title': self.translate('账号ID')},
				{'field': 'id', 'title': self.translate('角色ID')},
				{'field': 'name', 'title': self.translate('角色名')},
				{'field': 'level', 'title': self.translate('等级')},
				{'field': 'vip_level', 'title': 'VIP'},
				{'field': 'gold', 'title': self.translate('金币')},
				{'field': 'rmb', 'title': self.translate('钻石')},
				{'field': 'recharges', 'title': self.translate('充值次数')},
				{'field': 'union_db_id', 'title': self.translate('公会ID')},
				{'field': 'stamina', 'title': self.translate('体力')},
				{'field': 'created_time', 'title': self.translate('创建时间')},
				{'field': 'last_time', 'title': self.translate('最近操作时间')},
			]

		if limit:
			ret = yield self.userGMRPC.gmGetGameOnlineRoles(self.session, servName, offset, limit)

			total = ret['view']['size']
			for d in ret['models']:
				dd = {}
				for field in [x['field'] for x in columns]:
					dd[field] = d[field]
					if field in DBDataConvertMap:
						dd[field] = DBDataConvertMap[field](d[field])
				result.append(dd)

			# result = result[offset: offset+limit]
			rows = hexlifyDictField(result)

			self.write({
				"rows": rows,
				"limit": limit,
				"offset": offset,
				"total": total,
				})
		else:
			self.write({'columns': columns,})


# 玩家邮件信息
class RoleMailHandler(AuthedHandler):
	url = r'/role_mail'

	@coroutine
	def get(self):
		servName = self.get_argument('servName', 'All')
		roleSearch = self.get_argument('roleSearch', None)

		if servName == "All":
			raise HTTPError(404, reason='servName error')

		# 邮件缩略数据 [{db_id:Mail.id, subject:Mail.subject, time:Mail.time, type=Mail.type, sender:Mail.sender, global:Mail.role_db_id==0}, ...]
		columns = [
			{'field': 'db_id', 'title': '邮件ID'},
			{'field': 'subject', 'title': '标题'},
			{'field': 'time', 'title': '发送时间', 'sortable': True},
			{'field': 'sender', 'title': '发件人'},
			{'field': 'content', 'title': '内容'},
			{'field': 'attachs', 'title': '附件'},
			{'field': 'deleted_flag', 'title': '是否已读'},
		]

		roleID = None
		try:
			roleID = int(roleSearch)
		except ValueError as e:
			roleID = string2objectid(roleSearch)

		if roleID:
			ret = yield self.userGMRPC.gmGetRoleInfo(self.session, servName, roleID)
		else:
			ret = yield self.userGMRPC.gmGetRoleInfoByName(self.session, servName, roleSearch)

		if len(ret) == 0:
			raise HTTPError(404, reason='no such role')

		# 存在机器人没有account_name
		account_name = ret.get('account_name', '')
		if account_name.find('shuguo_') >= 0 and self.isTCAccount():
			raise HTTPError(404, reason='no such role')

		result = []
		nUnReadMail = len(ret['mailbox'])
		for i, mailThumb in enumerate(itertools.chain(ret['mailbox'], ret['read_mailbox'])):
			d = {}
			if i >= nUnReadMail:
				mailThumb['db_id'] = mailThumb['id']

			for field in [x['field'] for x in columns]:
				if field in mailThumb:
					d[field] = mailThumb[field]
					if field in DBDataConvertMap:
						d[field] = DBDataConvertMap[field](mailThumb[field])
			d['deleted_flag'] = i < nUnReadMail
			result.append(d)

		columns = self.setLocalColumns(columns)
		data = hexlifyDictField(result)
		self.write({
			'columns': columns,
			'data': data,
		})


# 运营活动
class YYHandler(AuthedHandler):
	url = '/operate_activity'

	@coroutine
	def get(self):
		self.render_page("_operate_activity.html")

	@coroutine
	def post(self):
		servName = self.get_json_data().get("servName", "All")

		if servName == "All":
			raise HTTPError(404, "server error", reason='Servename cant be all.')

		columns = [
			{'field': 'id', 'title': 'ID', 'sortable': True},
			{'field': 'icon', 'title': '活动图标', 'editable': {'type': 'textarea',}},
			{'field': 'icon1', 'title': '活动按钮角标', 'editable': {'type': 'textarea',}},
			{'field': 'independent', 'title': '是否独立icon', 'editable': {'type': 'text',}},
			{'field': 'type', 'title': '活动分类', 'editable': {'type': 'text',}},
			{'field': 'name', 'title': '名称', 'editable': {'type': 'text',}},
			# {'field': 'name1', 'title': '名称2', 'editable': {'type': 'textarea',}},
			{'field': 'desc', 'title': '活动简介', 'editable': {'type': 'textarea',}},
			# {'field': 'desc_tw', 'title': '活动简介', 'editable': {'type': 'textarea',}},
			# {'field': 'desc_en', 'title': '活动简介', 'editable': {'type': 'textarea',}},
			# {'field': 'activityDesc', 'title': 'activityDesc活动右侧的说明', 'editable': {'type': 'textarea',}},
			{'field': 'rDesc', 'title': '活动右侧的说明', 'editable': {'type': 'textarea',}},
			# {'field': 'rDesc_tw', 'title': '活动右侧的说明', 'editable': {'type': 'textarea',}},
			# {'field': 'rDesc_en', 'title': '活动右侧的说明', 'editable': {'type': 'textarea',}},
			# {'field': 'rTitle', 'title': '活动右边子面板标题图', 'editable': {'type': 'text',}},
			# {'field': 'openTimeDesc', 'title': '活动开放日期简介', 'editable': {'type': 'text',}},
			# {'field': 'displayType', 'title': '显示类型', 'editable':{'type': 'text',}},
			{'field': 'paramMap', 'title': '客户端参数', 'editable': {'type': 'textarea'}},
			{'field': 'clientParam', 'title': '空白', 'editable': {'type': 'textarea'}},
			{'field': 'huodongID', 'title': '活动版本ID', 'editable': True},
			{'field': 'countType', 'title': '  计数类型  ', 'editable':{'type': 'text'}},

			{'field': 'openType', 'title': '  开放周期  ', 'editable': True},
			{'field': 'beginDate', 'title': '开始日期', 'editable': {'type': 'text'}},
			{'field': 'beginTime', 'title': '开始时间', 'editable': {'type': 'text'}},
			{'field': 'endDate', 'title': '截止日期', 'editable': {'type': 'text'}},
			{'field': 'endTime', 'title': '截止时间', 'editable': {'type': 'text'}},
			# {'field': 'openWeekDay', 'title': '周期开启序列', 'editable': { 'type': 'text',}},
			# {'field': 'openWeekDay', 'title': '周期开启序列', 'editable': { 'type': 'checklist', 'source': [
			# 	{'value': '1', 'text': '星期一'},
			# 	{'value': '2', 'text': '星期二'},
			# 	{'value': '3', 'text': '星期三'},
			# 	{'value': '4', 'text': '星期四'},
			# 	{'value': '5', 'text': '星期五'},
			# 	{'value': '6', 'text': '星期六'},
			# 	{'value': '7', 'text': '星期日'},
			# ]}},
			{'field': 'openDuration', 'title': '持续小时', 'editable': {'type': 'text',}},
			{'field': 'relativeDayRange', 'title': '持续的相对天数', 'editable': {'type': 'text',}},
			{'field': 'leastLevel', 'title': '最低等级限制', 'editable': {'type': 'text',}},
			{'field': 'leastVipLevel', 'title': '最低VIP限制', 'editable': {'type': 'text',}},
			{'field': 'validServerOpenDateRange', 'title': '生效的开服时间区间', 'editable': {'type': 'text',}},
			{'field': 'serverDayRange', 'title': '开服时间限制', 'editable': {'type': 'text',}},
			{'field': 'roleDayRange', 'title': '创角时间限制', 'editable': {'type': 'text',}},
			{'field': 'servers', 'title': '服务器', 'editable': {'type': 'text'}},
			{'field': 'languages', 'title': '语言区域', 'editable': {'type': 'text'}},

			{'field': 'active', 'title': '是否激活', 'editable': True},
			# {'field': 'explain', 'title': '说明', 'editable': {'type': 'textarea'}},
			{'field': 'sortWeight', 'title': '排序值', 'editable': {'type': 'text'}},
			{'field': 'redpoint', 'title': '提示性红点', 'editable': True},
		]

		configCache = yield self.userGMRPC.gmGetGameYYComfig(self.session, servName)
		yyhdCache = copy.deepcopy(configCache["csv"]["yyhuodong"])

		for rowID, item in configCache['db']['yyhuodong'].items():
			rowID = int(rowID)
			if rowID not in yyhdCache:
				continue
			for k, v in item.items():
				yyhdCache[rowID][k] = copy.deepcopy(v)

		result = []
		for rowID in sorted(yyhdCache.keys()):
			yyhdCache[rowID]['id'] = rowID

			# 处理yy配表字段内容
			for k, v in yyhdCache[rowID].items():
				if k == "paramMap" and not v:
					yyhdCache[rowID][k] = ''
				else:
					yyhdCache[rowID][k] = self.py2csv(v)
			result.append(yyhdCache[rowID])

		# 公告
		placardCache = copy.deepcopy(configCache['csv']['placard'])
		if 1 in configCache['db']['placard']:
			placardCache = configCache['db']['placard']

		columns = self.setLocalColumns(columns)
		self.write({
			'columns': columns,
			'data': result,
			'placard': placardCache,
			'language': self.language
		})

	@staticmethod
	def py2csv(ob):
		if ob is None:
			return ''

		if isinstance(ob, (str, unicode)):
			return ob

		s = str(ob).replace("'", "").replace(" ", "")
		if isinstance(ob, list):
			s = s.replace('[', '<').replace(',', ';').replace(']', '>')
		elif isinstance(ob, dict):
			s = s.replace(':', '=').replace(',', ';')
		return s

	@staticmethod
	def csv2py(s):
		if s == '':
			return None

		if not (s.startswith('<') or s.startswith('{')):
			try:
				s = int(s)
			except ValueError:
				pass
			return s

		ob = ""
		s = s.replace('<', '[').replace('>', ']')
		for i in s:
			if i == '[' or i == '{':
				ob = ob + i + '"'
			elif i == '=':
				ob += '":"'
			elif i == ';':
				ob += '","'
			elif i == ']' or i == '}':
				ob = ob + '"' + i
			else:
				ob += i

		ob = eval(ob)
		if isinstance(ob, list):
			for k, v in enumerate(ob):
				try:
					ob[k] = int(v)
				except ValueError:
					pass
		elif isinstance(ob, dict):
			for k, v in ob.items():
				try:
					ob[k] = int(v)
				except ValueError:
					pass
		return ob


# 运营活动重置配置、单服保存、全服保存
class YYConfigHandler(AuthedHandler):
	url = r'/operation_config/(.+)'

	@coroutine
	def post(self, p): #p: yyhuodong, placard
		r = self.get_json_data()
		servName = r.get('servName', False)
		diffDB = r.get('diffDB', False)

		if p == 'reset':
			# 重置
			ret = yield self.userGMRPC.gmSetGameYYComfig(self.session, {'yyhuodong': {},
				'placard': {}}, servName)
			self.write({'result': ret})
			return

		if p == 'yyhuodong':
			diffDBTrans = {}
			for i, d in diffDB.items():
				id = int(i);

				vDictTemp = {}
				for k, v in d.items():
					if k == "paramMap" and v == '':
						vDictTemp[k] = {}
					else:
						vDictTemp[k] = YYHandler.csv2py(v)
				diffDBTrans[id] = vDictTemp
			data = {'yyhuodong': diffDBTrans}

		elif p == 'placard':
			content = diffDB[1]
			if "content" not in content:
				content["content"] = content.values()[0]
			data = {'placard': diffDB}

		if not servName:
			ret = yield self.userGMRPC.gmSetGameYYComfig(self.session, data)
		else:
			ret = yield self.userGMRPC.gmSetGameYYComfig(self.session, data, servName)

		self.write({'result': ret})


# 公告
class PlacardConfigHandler(AuthedHandler):
	url = r'/placard_config'
	ConfigPath = 'login/conf/notice.json'

	@coroutine
	def get(self):
		configPath = PlacardConfigHandler.ConfigPath
		print "os.getcwd", os.getcwd()
		if not os.path.exists(configPath):
			raise HTTPError(404, reason="wrong configPath")

		with open(configPath, 'r') as f:
			data = f.read()
		config = json.loads(data)
		self.write(config)

	@coroutine
	def post(self):
		placard = self.get_argument('config', None)

		try:
			config = json.loads(str(placard))
		except Exception as e:
			ret = {'result': False, 'msg': '不是标准json格式'}
		else:
			ret = self.configCheck(config)
			if ret['result']:
				strConfig = json.dumps(config, ensure_ascii=False, sort_keys=True, indent=2)
				configPath = PlacardConfigHandler.ConfigPath
				with open(configPath, 'w') as f:
					f.write(strConfig)

				# scp
				identity = "/mnt/server_tool/fabfile/ssh_key/key_kdjx_nsq"
				remotePath = "172.16.2.16:/mnt/release/login/conf/notice.json"
				cmd = "scp -i {0} {1} {2}".format(identity, configPath, remotePath)
				print "cmd", cmd
				if os.system(cmd) != 0:
					ret = {'result': False, 'msg': 'scp 执行失败'}

		self.write(ret)

	def configCheck(self, config):
		ks = set(["banner", "activity", "update"])
		updateks = set(["title", "content"])
		activityks = set(["id", "titlebar", "content"])
		ret = {'result': False, 'msg': ''}
		Flag = False

		if set(config.keys()) == ks:
			for k in ks:
				if k == "banner" and len(config[k]) == 0 and not isinstance(config[k], list):
					ret['msg'] = "banner 内容不能为空"
					break

				elif k == "update":
					for item in config[k]:
						if set(item.keys()) != updateks:
							ret['msg'] = "update 格式不正确"
							Flag = True
							break

				elif k == "activity" and len(config[k]) > 0:
					ids = []
					for item in config[k]:
						if set(item.keys()) == activityks:
							if item['id'] not in ids:
								ids.append(item['id'])
							else:
								ret['msg'] = "activity id 重复"
								Flag = True
								break

							for it in item['content']:
								if set(it.keys()) != updateks:
									ret['msg'] = "activity content 格式不正确"
									Flag = True
									break
							if Flag:
								break
						else:
							ret['msg'] = "activity 格式不正确"
							Flag = True
							break

				if Flag:
					break
		else:
			Flag = True
			ret['msg'] = "格式不正确"

		if not Flag:
			ret['result'] = True
		return ret


# 礼包生成
class GiftPacksGenerateHandler(AuthedHandler):
	url = r'/gift_packs'

	@coroutine
	def get(self):
		page = self.get_argument('page', None)
		if page:
			giftTemplates = yield self.userGMRPC.gmGetGiftCsv(self.session)
			self.write({'data': giftTemplates})
		else:
			self.render_page("_gift_packs.html")

	@coroutine
	def post(self):
		r = self.get_json_data()

		giftTemplates = r.get("giftTemplates", False) # int
		giftCounts = r.get("giftCounts", False) # int
		giftServers = r.get("giftServers", []) # []

		ret = yield self.userGMRPC.gmGenGift(self.session, giftTemplates, giftCounts, giftServers)

		self.write('\r\n'.join(ret))


# 黑名单
class BlackListHandler(AuthedHandler):
	url = r'/blacklist'

	@coroutine
	def get(self):
		# blackListTemplates = yield self.userGMRPC.gmGetGameBlackList(self.session)
		# print '-------------------'
		# print blackListTemplates
		self.render_page('_blacklist.html')

	@coroutine
	def post(self):

		datas = self.get_argument('data', False)
		if datas:
			datas = ast.literal_eval(datas)
		operator = self.get_argument('operator', False)
		if operator == 'add':
			ret = yield self.userGMRPC.gmAddGameBlackList(self.session, datas)
		if operator == 'del':
			datas = map(int, datas)
			ret = yield self.userGMRPC.gmDelGameBlackList(self.session, datas)
		if operator == 'push':
			ret = yield self.userGMRPC.gmPushGameBlackList(self.session)
		try:
			self.write({'result': ret})
		except NameError as identifier:
			self.write({'result': 'false'})


# 聊天监控
class ChatMonitorHandler(AuthedHandler):
	url = r'/chat_monitor'

	@coroutine
	def get(self):
		self.render_page("_chat_monitor.html")

	@coroutine
	def post(self):
		r = self.get_json_data()
		servName = r.get("servName", "All")
		chatType = r.get("chatType", "")  # 聊天类型筛选：world/cross/union/role
		offset = r.get("offset", 0)
		limit = r.get("limit", None)

		if not limit:
			columns = [
				{"field": 'gameName', 'title': '接收区服'},
				{'field': 'sourceGame', 'title': '来源区服'},
				{'field': 'roleID', 'title': '角色ID'},
				{'field': 'roleName', 'title': '角色名'},
				{'field': 'roleLevel', 'title': '等级'},
				{'field': 'roleVIP', 'title': 'VIP'},
				{'field': 'type', 'title': '类型'},
				{'field': 'msg', 'title': '聊天内容', 'width': '40%'},
				{'field': 'time', 'title': '时间'},
				{'field': 'ban', 'title': '封号、禁言'},
			]
			columns = self.setLocalColumns(columns)
			self.write({'columns': columns})
			return

		if servName == "All":
			result = list(self.messageMap["All"])
		else:
			result = []
			for d in self.messageMap["All"]:
				if d['gameName'] != servName:
					continue
				result.append(d)

		# 按聊天类型筛选
		if chatType:
			result = [d for d in result if d.get('type') == chatType]

		total = len(result)
		result = result[offset:offset+limit]

		for c in result:
			# 跨服聊天使用 sourceGame（发送者实际所在服务器），否则使用 gameName
			servName = c.get('sourceGame', c['gameName'])
			try:
				ret = yield self.userGMRPC.gmGetRoleInfo(self.session, servName, c['roleID'])
				c['ban'] = [ret.get('disable_flag', False), ret.get('silent_flag', False)]
			except Exception as e:
				# 如果获取失败（比如跨服玩家不在线），显示未知状态
				c['ban'] = [None, None]

		self.write({
			'data': {
				"total": total,
				"rows": result
			}
		})


# 账号迁移
class AccountMigrateHandler(AuthedHandler):
	url = r'/account_migrate'

	@coroutine
	def get(self):
		self.render_page('_account_migrate.html')

	@coroutine
	def post(self):
		data = self.get_json_data()

		cfg = self.application.cfg['account_mongo']
		mongo = MongoDB(cfg)
		Account = mongo.client.Account
		field = {'name': 1, 'channel': 1, 'language': 1, 'pass_md5': 1, 'create_time': 1, 'last_time': 1}

		failedList = []
		for d in data:
			ret = yield self.dbcAccount.call_async('AccountMigrate', d['old'], d['new'])
			if ret['ret'] != True:
				failedList.append(d)
		# 	account = Account.find_one({'name': d['old']}, field)
		# 	newacc = Account.find_one({'name': d['new']}, field)
		# 	newacc_id = newacc.pop('_id')

		# 	if account:
		# 		oldChannel = account['channel']
		# 		newChannel = d['new'].split('_')[0]

		# 		if newacc:
		# 			newChannel = newacc['channel']
		# 			newacc['name'] = d['old'] + '@'
		# 			newacc['channel'] = oldChannel
		# 			Account.update({"_id": newacc_id}, {'$set': newacc})

		# 		account['name'] = d['new']
		# 		account['channel'] = newChannel
		# 		Account.update({"_id": account.pop('_id')}, {'$set': account})

		# 		if newacc:
		# 			newacc['name'] = d['old']
		# 			Account.update({"_id": newacc_id}, {'$set': newacc})
		# 	else:
		# 		failedList.append(d)

		# mongo.close()
		self.write({'failed': failedList})


# 刷新配表
class RefreshCsvHandler(AuthedHandler):
	url = '/refreshcsv'

	@coroutine
	def get(self):
		self.render_page('_refreshcsv.html')

	@coroutine
	def post(self):
		r = self.get_json_data()
		servName = r.get('servName', None)
		if servName is None:
			ret = yield self.userGMRPC.gmRefreshCSV(self.session)
		else:
			ret = yield self.userGMRPC.gmRefreshCSV(self.session, servName)

		self.write({'ret': ret})

# gmExecPy
class ExecPyHandler(AuthedHandler):
	url = '/execpy'

	@coroutine
	def post(self):
		srcFile = self.request.files.get('src', None)
		if not srcFile:
			raise HTTPError(404, reason="wrong srcFile")
		src = srcFile[0].get('body', None)
		if not src:
			raise HTTPError(404, reason="wrong srcFile content")

		servName = self.get_argument('servName', None)
		if not servName:
			ret = yield self.userGMRPC.gmExecPy(self.session, src)
		else:
			ret = yield self.userGMRPC.gmExecPy(self.session, src, name=servName)

		self.write({'result': ret})

# gmGenRobots
class gmGenRobotsHandler(AuthedHandler):
	url = '/genrobots'

	@coroutine
	def post(self):
		r = self.get_json_data()
		servName = r.get('servName', None)
		if not servName:
			raise HTTPError(404, reason="no servName")

		ret = yield self.userGMRPC.gmGenRobots(self.session, servName)
		self.write({'result': ret})

# 属性计算
class CalculateCardAttrs(BaseHandler):
	url = '/calattrs'

	@coroutine
	def get(self):
		servName = self.get_argument('servName')
		roleUID = self.get_argument('role_uid')
		cardID = []
		ret = yield self.userGMRPC.gmGetRoleCards(servName, roleUID, cardID)
		cards = sorted(ret['cards'].values(), key=lambda x:x['fighting_point'], reverse=True)

		def _convert(d):
			if d.get('id', None):
				d['id'] = binascii.hexlify(d['id'])
			if d.get('held_item', None):
				d['held_item'] = binascii.hexlify(d['held_item'])
			if d.get('role_db_id', None):
				d['role_db_id'] = binascii.hexlify(d['role_db_id'])
			return d;

		map(_convert, cards)
		columns = [
			{'field': 'id', 'title': ''},
			{'field': 'name', 'title': '卡片名称'},
			{'field': 'fighting_point', 'title': '战斗力'},
		]
		self.write({'columns': columns,
			'data': cards, 'role': {'id': binascii.hexlify(ret['role']['id']), 'name': ret['role']['name']}})

	@coroutine
	def post(self):
		r = self.get_json_data()
		ret = yield self.userGMRPC.gmEvalCardAttrs(r['servName'], binascii.unhexlify(r['id']),
			binascii.unhexlify(r['cur_card_id']), r['disables'])
		attrs, dis = ret['attrs'], ret['display']

		attrsMap = {} # {int: attr}
		for i, v in enumerate(AttrDefs.attrsEnum[1:], start=1):
			attrsMap[i] = v

		sysMaps = {
			'base': '基础属性',
			'character': '性格',
			'nvalue': '个体值',
			'const': '养成固定值',
			'percent': '养成百分比',
		}
		tables = {}
		columns = {}
		for t in dis:
			tabName = sysMaps.get(t, 'NIL')
			tables[t] = []
			columns[t] = OrderedDict()
			for sl in dis[t]:
				if len(sl) < 2:
					continue
				con = {t: sl[0]}
				columns[t][t] = {'field': t, 'title': tabName}
				for i, v in enumerate(sl[1], start=1):
					attrName = attrsMap.get(i, 'nil')
					columns[t][i] = {'field': attrName, 'title': attrName}
					if type(v) == float:
						con[attrName] = round(v, 4)
					else:
						con[attrName] = v
				tables[t].append(con)
		for k, d in columns.iteritems():
			columns[k] = []
			for _, v in d.iteritems():
				columns[k].append(v)

		result = OrderedDict()
		for i, v in enumerate(AttrDefs.attrsEnum[1:], start=1):
			rv = attrs.get(v, None)
			if rv:
				result[str(i)+"="+v] = rv

		self.write({'ret': result, 'tables': tables, 'columns': columns})


# 日志查看
class LogInspectorHandler(AuthedHandler):
	url = r'/log_inspector'

	@coroutine
	def get(self):
		pass

	@coroutine
	def post(self):
		pass


class DataExportHandler(AuthedHandler):
	url = r'/data_export'

	@coroutine
	def get(self):
		# 需要导出的collection
		export_collection = 'Archive'
		p = subprocess.Popen('mongodump --version', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		out, err = p.communicate()
		if err:
			print 'err: ', err
			self.write({'ret': False})
			return

		filename = '%s.%d.json'% (export_collection, todaydate2int())
		path = 'src/gm/statics/' + filename
		mongoConfig = self.cfg['mongo']
		mongoHost = mongoConfig.get('host', '127.0.0.1')
		port, db = mongoConfig['port'], mongoConfig['dbname']
		user, pwd = mongoConfig.get('username'), mongoConfig.get('password')

		# export
		if user and pwd:
			cmd = "mongodump --uri=mongodb://{0}:{1}@{2}:{3}/{4}?authSource=admin -c {5} -o {6}".format(
				user, pwd, mongoHost, port, db, export_collection, path)
		else:
			cmd = 'mongodump -h {0}:{1} -d {2} -c {3} -o {4}'.format(mongoHost, port,
				db, export_collection, path)

		p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
		out, err = p.communicate()
		if re.search(r'done dumping', out):
			# 压缩
			cmd = 'tar -czf {0} {1} && rm -rf {1}'.format(filename+'.tar.gz', filename)
			p = subprocess.Popen(cmd, cwd='src/gm/statics/', shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
			p.communicate()
			self.write({'ret': True, 'data': filename+'.tar.gz'})
		else:
			self.write({'ret': False})

	@coroutine
	def post(self):
		# 需要导入的collection
		import_collection = 'Archive'

		recordCount = self.mongo_client[import_collection].find({}).count()
		if recordCount != 0:
			self.write({'ret': False, 'msg': '当前%s中已存在数据'% import_collection})
			return

		p = subprocess.Popen('mongorestore --version', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		out, err = p.communicate()
		if err:
			print 'err: ', err
			self.write({'ret': False, 'msg': '缺少 mongorestore 工具'})
			return

		importFile = self.request.files['importFile'][0]
		with open('/tmp/%s'% importFile['filename'], 'wb') as f:
			f.write(importFile['body'])

		p = subprocess.Popen('tar -xzf %s'% importFile['filename'], cwd='/tmp', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		out, err = p.communicate()
		if err:
			print 'err: ', err
			self.write({'ret': False, 'msg': '解压失败'})
			return

		host = self.cfg['mongo'].get('host', '127.0.0.1') + ":" + str(self.cfg['mongo']['port'])
		db = self.cfg['mongo']['dbname']
		cmd = 'mongorestore -h {0} -d {1} ./{3}/{1}'.format(host, db, import_collection, importFile['filename'][:-7])
		p = subprocess.Popen(cmd, cwd='/tmp', shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
		out, err = p.communicate()
		if re.search(r'done', out):
			self.write({'ret': True})
		else:
			self.write({'ret': False, 'msg': '导入数据'})


# 暂不使用
def initEnv():
	env.use_ssh_config = True
	env.forward_agent = True
	env.user = 'root'
	env.ssh_config_path = './shuma/gmweb2/handler/ssh_config'
	env.password = 'youmi1024'
	env.passwords = passwords
	env.parallel = True

def svn_up_remote_config_json():
	def _config_json_csv_svn_up():
		with remote_tunnel(3690, local_host='192.168.1.125'):
			with settings(warn_only=True):
				run('svn cleanup')
				run('svn revert ./config_json.py')
				ret = run('svn up ./config_json.py')
				return not ret.failed

	with cd('/mnt/server'):
		try:
			return _config_json_csv_svn_up()
		except Exception, e:
			if str(e).find('TCP forwarding request denied') >= 0:
				ret = run('netstat -nap|grep :3690|awk \'{print substr($7, 0, index($7, "/")-1)}\'')
				if len(ret.split()) > 1:
					ret = ret.split()[0]
				run('kill -9 %d' % int(ret))
				return _config_json_csv_svn_up()

def svn_up_local_config_json():
	with lcd('./config_json'):
		local('svn cleanup')
		local('svn revert yunying')
		local('svn up')

class ConfigJsonHandler(AuthedHandler):
	url = r'/config_json/(.+)'

	@coroutine
	def get(self, p):
		print p
		pass

	def post(self, p):
		print p
		pass


# 获取已连接的跨服服务列表
class CrossServicesListHandler(AuthedHandler):
	url = '/cross/services/list'

	@coroutine
	def get(self):
		try:
			ret = yield self.userGMRPC.gmGetCrossServices(self.session)
			self.write({'result': True, 'services': ret})
		except Exception as e:
			self.write({'result': False, 'message': str(e)})


# 手动触发指定跨服服务
class CrossServiceStartHandler(AuthedHandler):
	url = '/cross/service/start'

	@coroutine
	def post(self):
		try:
			data = self.get_json_data()
			serviceKey = data.get('serviceKey', '')
			if not serviceKey:
				self.write({'result': False, 'message': 'serviceKey is required'})
				return
			ret = yield self.userGMRPC.gmStartCrossService(self.session, serviceKey)
			self.write(ret)
		except Exception as e:
			self.write({'result': False, 'message': str(e)})


# ==================== 合服管理 ====================

import threading
import logging
import uuid
import signal
try:
	import pymongo
	HAS_PYMONGO = True
except ImportError:
	HAS_PYMONGO = False

# 合服数据备份目录
MERGE_DUMP_PATH = '/tmp/merge_dump'

# 不需要备份的集合
MERGE_EXCLUDE_COLLECTIONS = [
	'ArenaPlayRecord',
	'CraftPlayRecord',
	'HorseRaceGlobal',
	'TinyRank',
	'GMYYConfig',
	'MailGlobal',
	'MessageGlobal',
	'ArenaGlobalHistory',
	'CloneGlobal',
	'CloneRoom'
]

# 合服任务状态存储
_merge_tasks = {}
_merge_tasks_lock = threading.Lock()


def _split_mongo_name(uri):
	"""从 URI 中提取数据库名"""
	uri = uri.split('?')[0]
	return uri.split('/')[-1]


def _comb_role_name(name, area):
	"""构建合服后的角色名"""
	suffix = '.s%d' % area
	if name.endswith(suffix):
		return name
	return name + suffix


class ServerMergePageHandler(AuthedHandler):
	"""合服管理页面"""
	url = '/server_merge_page'

	def get(self):
		self.render_page('_server_merge.html')


class ServerMergeConfigHandler(AuthedHandler):
	"""合服配置管理 - 支持 CSV + MongoDB 双来源"""
	url = '/server_merge/config'

	COLLECTION = 'MergeConfig'  # MongoDB 集合名

	@coroutine
	def get(self):
		"""获取合服配置列表（CSV + MongoDB）"""
		try:
			configs = []
			config_ids = set()

			# 1. 读取 merge.csv 配置
			try:
				from framework.csv import csv
				if hasattr(csv, 'server') and hasattr(csv.server, 'merge'):
					for idx in sorted(csv.server.merge.keys()):
						cfg = csv.server.merge[idx]
						configs.append({
							'id': idx,
							'destServer': cfg.destServer,
							'servers': list(cfg.servers) if cfg.servers else [],
							'serverID': cfg.serverID,
							'pwAwardVer': getattr(cfg, 'pwAwardVer', 0),
							'randomTowerAwardVer': getattr(cfg, 'randomTowerAwardVer', 0),
							'craftAwardVer': getattr(cfg, 'craftAwardVer', 0),
							'realityMerge': cfg.realityMerge,
							'source': 'csv',  # 标记来源
						})
						config_ids.add(idx)
			except Exception as e:
				logging.warning('Failed to load CSV merge config: %s', e)

			# 2. 读取 MongoDB 自定义配置
			try:
				collection = self.mongo_client[self.COLLECTION]
				for doc in collection.find():
					cfg_id = doc.get('id', 0)
					# 如果 ID 冲突，MongoDB 配置覆盖 CSV
					if cfg_id in config_ids:
						# 找到并替换
						for i, c in enumerate(configs):
							if c['id'] == cfg_id:
								configs[i] = {
									'id': cfg_id,
									'destServer': doc.get('destServer', ''),
									'servers': doc.get('servers', []),
									'serverID': doc.get('serverID', 0),
									'pwAwardVer': doc.get('pwAwardVer', 0),
									'randomTowerAwardVer': doc.get('randomTowerAwardVer', 0),
									'craftAwardVer': doc.get('craftAwardVer', 0),
									'realityMerge': doc.get('realityMerge', 0),
									'mongoConfig': doc.get('mongoConfig', {}),
									'source': 'mongodb',
								}
								break
					else:
						configs.append({
							'id': cfg_id,
							'destServer': doc.get('destServer', ''),
							'servers': doc.get('servers', []),
							'serverID': doc.get('serverID', 0),
							'pwAwardVer': doc.get('pwAwardVer', 0),
							'randomTowerAwardVer': doc.get('randomTowerAwardVer', 0),
							'craftAwardVer': doc.get('craftAwardVer', 0),
							'realityMerge': doc.get('realityMerge', 0),
							'mongoConfig': doc.get('mongoConfig', {}),
							'source': 'mongodb',
						})
			except Exception as e:
				logging.warning('Failed to load MongoDB merge config: %s', e)

			# 按 ID 排序
			configs.sort(key=lambda x: x['id'])
			self.write({'ret': True, 'configs': configs})
		except Exception as e:
			logging.exception('ServerMergeConfigHandler.get error')
			self.write({'ret': False, 'err': str(e)})

	@coroutine
	def post(self):
		"""添加/更新合服配置到 MongoDB"""
		try:
			data = self.get_json_data()
			
			cfg_id = data.get('id')
			if not cfg_id:
				self.write({'ret': False, 'err': '缺少配置ID'})
				return

			dest_server = data.get('destServer', '').strip()
			if not dest_server:
				self.write({'ret': False, 'err': '缺少目标服务器'})
				return

			servers = data.get('servers', [])
			if not servers:
				self.write({'ret': False, 'err': '缺少源服务器列表'})
				return

			# 构建文档
			doc = {
				'id': int(cfg_id),
				'destServer': dest_server,
				'servers': servers,
				'serverID': int(data.get('serverID', 0)),
				'pwAwardVer': int(data.get('pwAwardVer', 0)),
				'randomTowerAwardVer': int(data.get('randomTowerAwardVer', 0)),
				'craftAwardVer': int(data.get('craftAwardVer', 0)),
				'realityMerge': int(data.get('realityMerge', 0)),
				'mongoConfig': data.get('mongoConfig', {}),
				'updateTime': datetime.datetime.now(),
			}

			# 保存到 MongoDB（upsert）
			collection = self.mongo_client[self.COLLECTION]
			collection.update_one(
				{'id': int(cfg_id)},
				{'$set': doc},
				upsert=True
			)

			self.write({'ret': True, 'message': '配置已保存'})
		except Exception as e:
			logging.exception('ServerMergeConfigHandler.post error')
			self.write({'ret': False, 'err': str(e)})

	@coroutine
	def delete(self):
		"""删除 MongoDB 中的合服配置"""
		try:
			config_id = self.get_argument('id', None)
			if not config_id:
				self.write({'ret': False, 'err': '缺少配置ID'})
				return

			collection = self.mongo_client[self.COLLECTION]
			result = collection.delete_one({'id': int(config_id)})

			if result.deleted_count > 0:
				self.write({'ret': True, 'message': '配置已删除'})
			else:
				self.write({'ret': False, 'err': '配置不存在或为CSV配置（CSV配置无法删除）'})
		except Exception as e:
			logging.exception('ServerMergeConfigHandler.delete error')
			self.write({'ret': False, 'err': str(e)})


class ServerMergeTestMongoHandler(AuthedHandler):
	"""测试MongoDB连接"""
	url = '/server_merge/test_mongo'

	@coroutine
	def post(self):
		if not HAS_PYMONGO:
			self.write({'ret': False, 'err': 'pymongo not installed'})
			return

		try:
			mongo_config = self.get_json_data()
			errors = []
			
			for server_key, uri in mongo_config.items():
				try:
					client = pymongo.MongoClient(uri, serverSelectionTimeoutMS=5000)
					# 测试连接
					client.server_info()
					client.close()
				except Exception as e:
					errors.append('%s: %s' % (server_key, str(e)))

			if errors:
				self.write({'ret': False, 'err': '\n'.join(errors)})
			else:
				self.write({'ret': True})
		except Exception as e:
			logging.exception('ServerMergeTestMongoHandler error')
			self.write({'ret': False, 'err': str(e)})


class ServerMergeExecuteHandler(AuthedHandler):
	"""执行合服 - 完全集成版本"""
	url = '/server_merge/execute'

	@coroutine
	def post(self):
		if not HAS_PYMONGO:
			self.write({'ret': False, 'err': 'pymongo 未安装，请先安装: pip install pymongo'})
			return

		try:
			data = self.get_json_data()
			target = data.get('target')
			mongo_config = data.get('mongoConfig')

			if not target:
				self.write({'ret': False, 'err': '请选择合服目标'})
				return

			# 获取源服务器列表和 MongoDB 配置
			src_servers = []
			saved_mongo_config = {}

			# 1. 先从 MongoDB 查找自定义配置
			try:
				collection = self.mongo_client['MergeConfig']
				doc = collection.find_one({'destServer': target})
				if doc:
					src_servers = doc.get('servers', [])
					saved_mongo_config = doc.get('mongoConfig', {})
			except Exception as e:
				logging.warning('Failed to load MongoDB merge config: %s', e)

			# 2. 如果 MongoDB 没有，从 CSV 读取
			if not src_servers:
				try:
					from framework.csv import csv
					for idx in csv.server.merge.keys():
						cfg = csv.server.merge[idx]
						if cfg.destServer == target:
							src_servers = list(cfg.servers) if cfg.servers else []
							break
				except Exception as e:
					logging.warning('Failed to load CSV merge config: %s', e)

			if not src_servers:
				self.write({'ret': False, 'err': '未找到合服配置: %s' % target})
				return

			# 合并 MongoDB 配置（传入的覆盖保存的）
			if saved_mongo_config and not mongo_config:
				mongo_config = saved_mongo_config
			elif saved_mongo_config and mongo_config:
				# 合并，传入的优先
				merged = dict(saved_mongo_config)
				merged.update(mongo_config)
				mongo_config = merged

			if not mongo_config:
				self.write({'ret': False, 'err': '请配置 MongoDB 连接'})
				return

			# 验证 MongoDB 配置
			if target not in mongo_config:
				self.write({'ret': False, 'err': '缺少目标数据库配置: %s' % target})
				return
			for server in src_servers:
				if server not in mongo_config:
					self.write({'ret': False, 'err': '缺少源数据库配置: %s' % server})
					return

			# 检查是否有正在运行的同目标任务
			with _merge_tasks_lock:
				for existing_id, existing_task in _merge_tasks.items():
					if existing_task.get('target') == target and existing_task.get('status') == 'running':
						self.write({'ret': False, 'err': '目标 %s 已有正在运行的合服任务: %s' % (target, existing_id)})
						return
				
				# 清理超过1小时的已完成任务（避免内存泄漏）
				now = datetime.datetime.now()
				to_delete = []
				for task_id, task in _merge_tasks.items():
					if task.get('status') in ('done', 'error', 'stopped'):
						start_time = task.get('startTime')
						if start_time and (now - start_time).total_seconds() > 3600:
							to_delete.append(task_id)
				for task_id in to_delete:
					del _merge_tasks[task_id]

			# 创建任务ID
			timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
			task_id = '%s_%s' % (target.replace('.', '_'), timestamp)

			# 初始化任务状态
			with _merge_tasks_lock:
				_merge_tasks[task_id] = {
					'status': 'running',
					'progress': 0,
					'currentStep': 1,
					'target': target,
					'srcServers': src_servers,
					'logs': [],
					'startTime': datetime.datetime.now(),
					'error': None,
					'stopped': False
				}

			# 在后台线程执行合服
			thread = threading.Thread(
				target=self._run_merge,
				args=(task_id, target, src_servers, mongo_config)
			)
			thread.daemon = True
			thread.start()

			self.write({'ret': True, 'taskId': task_id})
		except Exception as e:
			logging.exception('ServerMergeExecuteHandler error')
			self.write({'ret': False, 'err': str(e)})

	def _add_log(self, task_id, level, message):
		"""添加日志"""
		with _merge_tasks_lock:
			if task_id in _merge_tasks:
				_merge_tasks[task_id]['logs'].append({
					'level': level,
					'message': message,
					'time': datetime.datetime.now().strftime('%H:%M:%S')
				})
				logging.info('[Merge %s] %s', task_id, message)

	def _update_progress(self, task_id, step, progress):
		"""更新进度"""
		with _merge_tasks_lock:
			if task_id in _merge_tasks:
				_merge_tasks[task_id]['currentStep'] = step
				_merge_tasks[task_id]['progress'] = progress

	def _is_stopped(self, task_id):
		"""检查是否被停止"""
		with _merge_tasks_lock:
			if task_id in _merge_tasks:
				return _merge_tasks[task_id].get('stopped', False)
		return True

	def _save_merge_history(self, task_id, target, src_servers, status, error):
		"""保存合服记录到 MongoDB"""
		try:
			with _merge_tasks_lock:
				task = _merge_tasks.get(task_id, {})
				start_time = task.get('startTime', datetime.datetime.now())
				duration = task.get('duration', 0)
				logs = task.get('logs', [])

			# 保存到 MongoDB
			collection = self.mongo_client['MergeHistory']
			doc = {
				'taskId': task_id,
				'target': target,
				'srcServers': src_servers,
				'status': status,
				'error': error,
				'startTime': start_time,
				'duration': duration,
				'logCount': len(logs),
				'createTime': datetime.datetime.now()
			}
			collection.insert_one(doc)
			logging.info('Saved merge history: %s', task_id)
		except Exception as e:
			logging.exception('Failed to save merge history: %s', e)

	def _run_merge(self, task_id, target, src_servers, mongo_config):
		"""执行合服主逻辑"""
		import random
		import shutil

		def add_log(level, msg):
			self._add_log(task_id, level, msg)

		def update_progress(step, progress):
			self._update_progress(task_id, step, progress)

		try:
			add_log('info', '=' * 50)
			add_log('info', '开始合服: %s <- %s' % (target, ', '.join(src_servers)))
			add_log('info', '=' * 50)

			# ========== 步骤1: 备份源数据库 ==========
			update_progress(1, 5)
			add_log('info', '步骤1: 备份源数据库...')

			# 清空并创建备份目录
			if os.path.exists(MERGE_DUMP_PATH):
				shutil.rmtree(MERGE_DUMP_PATH)
			os.makedirs(MERGE_DUMP_PATH)

			for i, server in enumerate(src_servers):
				if self._is_stopped(task_id):
					raise Exception('用户停止了任务')

				uri = mongo_config[server]
				# 使用列表参数避免命令注入
				cmd_args = ['mongodump', '--uri', uri, '--gzip', '-o', MERGE_DUMP_PATH]
				cmd_args.extend(['--excludeCollection=' + x for x in MERGE_EXCLUDE_COLLECTIONS])
				add_log('info', '  备份 %s ...' % server)
				
				try:
					result = subprocess.call(cmd_args)
					if result != 0:
						raise Exception('mongodump 失败，返回码: %d' % result)
				except Exception as e:
					add_log('error', '  备份失败: %s' % str(e))
					raise

				progress = 5 + int((i + 1) * 10 / len(src_servers))
				update_progress(1, progress)

			add_log('success', '步骤1完成: 备份成功')

			# ========== 步骤2: 清空目标数据库 ==========
			if self._is_stopped(task_id):
				raise Exception('用户停止了任务')

			update_progress(2, 20)
			add_log('info', '步骤2: 清空目标数据库...')

			dest_uri = mongo_config[target]
			dest_db_name = _split_mongo_name(dest_uri)

			client = pymongo.MongoClient(dest_uri)
			db = client[dest_db_name]
			for col in db.list_collection_names():
				db.drop_collection(col)
				add_log('info', '  删除集合: %s' % col)
			client.close()

			add_log('success', '步骤2完成: 目标数据库已清空')

			# ========== 步骤3: 恢复数据到目标库 ==========
			if self._is_stopped(task_id):
				raise Exception('用户停止了任务')

			update_progress(3, 25)
			add_log('info', '步骤3: 恢复数据到目标库...')

			for i, server in enumerate(src_servers):
				if self._is_stopped(task_id):
					raise Exception('用户停止了任务')

				src_db_name = _split_mongo_name(mongo_config[server])
				dump_path = os.path.join(MERGE_DUMP_PATH, src_db_name)
				
				# 使用列表参数避免命令注入
				cmd_args = ['mongorestore', '--noIndexRestore', '--uri', dest_uri, 
							'--gzip', '-d', dest_db_name, dump_path]
				add_log('info', '  恢复 %s -> %s ...' % (server, target))

				try:
					result = subprocess.call(cmd_args)
					if result != 0:
						raise Exception('mongorestore 失败，返回码: %d' % result)
				except Exception as e:
					add_log('error', '  恢复失败: %s' % str(e))
					raise

				progress = 25 + int((i + 1) * 15 / len(src_servers))
				update_progress(3, progress)

			add_log('success', '步骤3完成: 数据恢复成功')

			# ========== 步骤4: 修改角色数据 ==========
			if self._is_stopped(task_id):
				raise Exception('用户停止了任务')

			update_progress(4, 45)
			add_log('info', '步骤4: 修改角色数据（加后缀.sX）...')

			client = pymongo.MongoClient(dest_uri)
			db = client[dest_db_name]

			uid = 10001
			collection = db['Role']
			roles = list(collection.find({}, {'_id': 1, 'uid': 1, 'name': 1, 'area': 1}))
			total = len(roles)
			add_log('info', '  共 %d 个角色需要处理' % total)

			for i, role in enumerate(roles):
				if self._is_stopped(task_id):
					client.close()
					raise Exception('用户停止了任务')

				collection.update_one({'_id': role['_id']}, {'$set': {
					'uid': uid,
					'name': _comb_role_name(role['name'], role['area']),
					'clone_room_db_id': '',
					'clone_deploy_card_db_id': '',
					'clone_daily_be_kicked_num': 0,
					'clone_room_create_time': 0,
					'global_mail_idx': 0,
				}})
				uid += 1

				if (i + 1) % 1000 == 0:
					add_log('info', '  已处理 %d/%d 角色' % (i + 1, total))
					progress = 45 + int((i + 1) * 10 / total)
					update_progress(4, progress)

			db['IncID'].find_one_and_update({'_id': 'Role'}, {"$set": {'id': uid - 1}}, upsert=True)
			add_log('success', '步骤4完成: 角色数据修改成功')

			# ========== 步骤5: 修改公会数据 ==========
			if self._is_stopped(task_id):
				client.close()
				raise Exception('用户停止了任务')

			update_progress(5, 60)
			add_log('info', '步骤5: 修改公会数据...')

			uid = 1
			collection = db['Union']
			unions = list(collection.find({}, {'_id': 1, 'uid': 1, 'name': 1, 'area': 1}))
			total = len(unions)
			add_log('info', '  共 %d 个公会需要处理' % total)

			names = set()
			for union in unions:
				name = union['name']
				if name in names:
					name = _comb_role_name(name, union['area'])
				collection.update_one({'_id': union['_id']}, {'$set': {'uid': uid, 'name': name}})
				names.add(name)
				uid += 1

			db['IncID'].find_one_and_update({'_id': 'Union'}, {"$set": {'id': uid - 1}}, upsert=True)
			add_log('success', '步骤5完成: 公会数据修改成功')

			# ========== 步骤6: 重建全局数据 ==========
			if self._is_stopped(task_id):
				client.close()
				raise Exception('用户停止了任务')

			update_progress(6, 70)
			add_log('info', '步骤6: 重建全局数据...')

			# 6.1 冒险之路
			add_log('info', '  处理冒险之路...')
			try:
				collection = db['EndlessTowerGlobal']
				latest_plays = {}
				lower_fighting_plays = {}
				for data_global in collection.find():
					for key, val in data_global.get('latest_plays', {}).items():
						latest_plays.setdefault(key, []).extend(val)
					for key, val in data_global.get('lower_fighting_plays', {}).items():
						lower_fighting_plays.setdefault(key, []).extend(val)

				for key in latest_plays:
					random.shuffle(latest_plays[key])
					latest_plays[key] = latest_plays[key][:3]
				for key in lower_fighting_plays:
					random.shuffle(lower_fighting_plays[key])
					lower_fighting_plays[key] = lower_fighting_plays[key][:3]

				db.drop_collection('EndlessTowerGlobal')
				collection.insert_one({
					'key': target,
					'latest_plays': latest_plays,
					'lower_fighting_plays': lower_fighting_plays,
				})
			except Exception as e:
				add_log('warn', '  冒险之路处理异常: %s' % str(e))

			# 6.2 世界BOSS
			add_log('info', '  处理世界BOSS...')
			try:
				collection = db['WorldBossGlobal']
				data = {'key': target, 'unions': {}, 'roles': {}, 'last_level': 0}
				for v in collection.find():
					data['unions'].update(v.get('unions', {}))
					data['roles'].update(v.get('roles', {}))
					if v.get('last_level', 0) > data['last_level']:
						data['last_level'] = v['last_level']
				db.drop_collection('WorldBossGlobal')
				collection.insert_one(data)
			except Exception as e:
				add_log('warn', '  世界BOSS处理异常: %s' % str(e))

			# 6.3 石英联赛
			add_log('info', '  处理石英联赛...')
			try:
				db.drop_collection('CraftGlobal')
				db['CraftGlobal'].insert_one({'key': target, 'bet': {}})

				collection = db['CraftGameGlobal']
				data = collection.find_one({}, {'_id': 0})
				if data:
					data['key'] = target
					data['yesterday_top8_plays'] = {}
					data['yesterday_refresh_time'] = {}
					signup = {}
					for data_global in collection.find():
						signup.update(data_global.get('signup', {}))
					data['signup'] = signup
					db.drop_collection('CraftGameGlobal')
					collection.insert_one(data)
			except Exception as e:
				add_log('warn', '  石英联赛处理异常: %s' % str(e))

			# 6.4 服务器全局记录
			add_log('info', '  处理服务器全局记录...')
			try:
				collection = db['ServerGlobalRecord']
				data = {
					'key': target,
					'half_period_keys': {},
					'title_roles': {},
					'title_roles_info': {},
					'equip_shop_refresh': 0,
					'union_roles': {},
					'play_ranking_cross_keys': {},
					'normal_brave_challenge': {},
				}
				for key in src_servers:
					data['half_period_keys'].setdefault('cross_craft', []).append(key)
					data['half_period_keys'].setdefault('cross_arena', []).append(key)
					data['half_period_keys'].setdefault('cross_fishing', []).append(key)
					data['half_period_keys'].setdefault('cross_online_fight', []).append(key)
					data['half_period_keys'].setdefault('cross_mine', []).append(key)
					data['half_period_keys'].setdefault('cross_gym', []).append(key)

				for v in collection.find():
					if v.get('equip_shop_refresh', 0) > data['equip_shop_refresh']:
						data['equip_shop_refresh'] = v['equip_shop_refresh']
					if v.get('title_roles_info'):
						for titleID, roleInfo in v['title_roles_info'].items():
							data['title_roles_info'].setdefault(titleID, {}).update(roleInfo)

				db.drop_collection('ServerGlobalRecord')
				collection.insert_one(data)
			except Exception as e:
				add_log('warn', '  服务器全局记录处理异常: %s' % str(e))

			# 6.5 卡牌战力排名
			add_log('info', '  处理卡牌战力排名...')
			try:
				collection = db['CardFightGlobal']
				data = collection.find_one({}, {'_id': 0})
				if data:
					data['key'] = target
					data['cards'] = {}
					data['has_init_data'] = False
					db.drop_collection('CardFightGlobal')
					collection.insert_one(data)
			except Exception as e:
				add_log('warn', '  卡牌战力排名处理异常: %s' % str(e))

			# 6.6 道馆
			add_log('info', '  处理道馆...')
			try:
				collection = db['GymGlobal']
				data = {
					'key': target.replace('game', 'gym'),
					'round': 'start',
					'leader_roles': {},
					'pass_nums': {},
				}
				for v in collection.find():
					data['pass_nums'].update(v.get('pass_nums', {}))
				db.drop_collection('GymGlobal')
				collection.insert_one(data)
			except Exception as e:
				add_log('warn', '  道馆处理异常: %s' % str(e))

			update_progress(6, 80)
			add_log('success', '步骤6完成: 全局数据重建成功')

			# ========== 步骤7: 处理竞技场数据 ==========
			if self._is_stopped(task_id):
				client.close()
				raise Exception('用户停止了任务')

			update_progress(7, 85)
			add_log('info', '步骤7: 处理竞技场数据...')

			# 读取各服务器的竞技场排名
			ranks = {}
			for server in src_servers:
				try:
					src_client = pymongo.MongoClient(mongo_config[server])
					src_db_name = _split_mongo_name(mongo_config[server])
					src_db = src_client[src_db_name]
					arena_data = src_db['ArenaGlobal'].find_one()
					if arena_data:
						ranks[server] = arena_data.get('ranks', {})
					src_client.close()
				except Exception as e:
					add_log('warn', '  读取 %s 竞技场数据失败: %s' % (server, str(e)))
					ranks[server] = {}

			# 删除竞技场机器人
			add_log('info', '  删除竞技场机器人...')
			collection = db['ArenaRecord']
			robot_records = list(collection.find({'robot': {'$exists': True}}, {'_id': 1, 'role_db_id': 1}))
			role_ids = [r['role_db_id'] for r in robot_records]
			record_ids = set([r['_id'] for r in robot_records])

			db['Role'].delete_many({'_id': {'$in': role_ids}})
			db['RoleCard'].delete_many({'role_db_id': {'$in': role_ids}})
			db['ArenaRecord'].delete_many({'robot': {'$exists': True}})
			add_log('info', '  删除了 %d 个机器人' % len(robot_records))

			# 清除战斗历史
			db['ArenaRecord'].update_many({}, {'$set': {'history': []}})
			db['CraftRecord'].update_many({}, {'$set': {'history': []}})
			db['UnionFightRoleRecord'].update_many({}, {'$set': {'history': []}})

			# 重建竞技场排名
			add_log('info', '  重建竞技场排名...')
			new_ranks = {}
			rank_start = 1
			max_length = max([len(v) for v in ranks.values()]) if ranks else 0

			keys = sorted(ranks.keys())
			for i in range(max_length):
				for key in keys:
					rank_data = ranks[key].get(str(i))
					if not rank_data:
						continue
					role_id, record_id = rank_data
					if record_id in record_ids:
						continue

					record = collection.find_one({'_id': record_id}, {'rank_top': 1})
					if not record:
						continue

					rank_top = min(rank_start, record.get('rank_top', rank_start))
					collection.update_one({'_id': record_id}, {'$set': {'rank': rank_start, 'rank_top': rank_top}})
					new_ranks[str(rank_start)] = rank_data
					rank_start += 1

			db.drop_collection('ArenaGlobal')
			db['ArenaGlobal'].insert_one({
				'key': target,
				'ranks': new_ranks,
				'rank_max': len(new_ranks),
			})

			client.close()
			update_progress(7, 100)
			add_log('success', '步骤7完成: 竞技场数据处理成功')

			# ========== 完成 ==========
			add_log('info', '=' * 50)
			add_log('success', '合服完成！')
			add_log('info', '=' * 50)

			with _merge_tasks_lock:
				if task_id in _merge_tasks:
					_merge_tasks[task_id]['status'] = 'done'
					_merge_tasks[task_id]['duration'] = (
						datetime.datetime.now() - _merge_tasks[task_id]['startTime']
					).seconds

			# 保存合服记录到 MongoDB
			self._save_merge_history(task_id, target, src_servers, 'done', None)

		except Exception as e:
			logging.exception('Merge task %s failed' % task_id)
			error_msg = str(e)

			# 判断是用户停止还是真正的错误
			is_stopped = self._is_stopped(task_id)
			if is_stopped or '停止' in error_msg:
				status = 'stopped'
				error_msg = '用户手动停止'
			else:
				status = 'error'

			self._add_log(task_id, 'error', '合服失败: %s' % error_msg)
			with _merge_tasks_lock:
				if task_id in _merge_tasks:
					_merge_tasks[task_id]['status'] = status
					_merge_tasks[task_id]['error'] = error_msg

			# 保存失败/停止记录到 MongoDB
			self._save_merge_history(task_id, target, src_servers, status, error_msg)


class ServerMergeStopHandler(AuthedHandler):
	"""停止合服任务"""
	url = '/server_merge/stop'

	def post(self):
		try:
			data = self.get_json_data()
			task_id = data.get('taskId')

			if not task_id:
				self.write({'ret': False, 'err': '缺少taskId'})
				return

			with _merge_tasks_lock:
				if task_id not in _merge_tasks:
					self.write({'ret': False, 'err': '任务不存在'})
					return

				task = _merge_tasks[task_id]
				task['stopped'] = True
				task['status'] = 'stopped'
				task['error'] = '用户手动停止'

			self.write({'ret': True, 'message': '已发送停止信号'})
		except Exception as e:
			self.write({'ret': False, 'err': str(e)})


class ServerMergeStatusHandler(AuthedHandler):
	"""获取合服任务状态"""
	url = '/server_merge/status'

	def get(self):
		task_id = self.get_argument('taskId', None)
		if not task_id:
			self.write({'ret': False, 'err': '缺少taskId'})
			return

		with _merge_tasks_lock:
			if task_id not in _merge_tasks:
				self.write({'ret': False, 'err': '任务不存在'})
				return

			task = _merge_tasks[task_id]
			
			# 获取新日志并清空
			new_logs = task.get('logs', [])
			task['logs'] = []

			result = {
				'ret': True,
				'status': task['status'],
				'progress': task.get('progress', 0),
				'currentStep': task.get('currentStep', 1),
				'newLogs': new_logs,
				'error': task.get('error'),
				'duration': task.get('duration', 0)
			}

		self.write(result)


class ServerMergeHistoryHandler(AuthedHandler):
	"""获取合服历史记录 - 支持内存 + MongoDB"""
	url = '/server_merge/history'

	COLLECTION = 'MergeHistory'

	def get(self):
		try:
			history = []
			seen_task_ids = set()

			# 1. 从内存中获取当前运行的任务
			with _merge_tasks_lock:
				for task_id, task in _merge_tasks.items():
					seen_task_ids.add(task_id)
					history.append({
						'taskId': task_id,
						'target': task.get('target', ''),
						'srcServers': task.get('srcServers', []),
						'status': task.get('status', ''),
						'startTime': task.get('startTime', datetime.datetime.now()).strftime('%Y-%m-%d %H:%M:%S'),
						'duration': task.get('duration', 0),
						'error': task.get('error'),
						'source': 'memory'
					})

			# 2. 从 MongoDB 获取历史记录
			try:
				collection = self.mongo_client[self.COLLECTION]
				for doc in collection.find().sort('startTime', -1).limit(50):
					task_id = doc.get('taskId', '')
					if task_id in seen_task_ids:
						continue  # 跳过内存中已有的

					start_time = doc.get('startTime')
					if isinstance(start_time, datetime.datetime):
						start_time_str = start_time.strftime('%Y-%m-%d %H:%M:%S')
					else:
						start_time_str = str(start_time)

					history.append({
						'taskId': task_id,
						'target': doc.get('target', ''),
						'srcServers': doc.get('srcServers', []),
						'status': doc.get('status', ''),
						'startTime': start_time_str,
						'duration': doc.get('duration', 0),
						'error': doc.get('error'),
						'source': 'mongodb'
					})
			except Exception as e:
				logging.warning('Failed to load merge history from MongoDB: %s', e)

			# 按时间倒序
			history.sort(key=lambda x: x['startTime'], reverse=True)
			self.write({'ret': True, 'history': history[:30]})
		except Exception as e:
			logging.exception('ServerMergeHistoryHandler error')
			self.write({'ret': False, 'err': str(e)})


class ServerMergeDeployConfigHandler(AuthedHandler):
	"""部署合服配置文件到服务器 - 增量合并模式"""
	url = '/server_merge/deploy_config'

	# 默认部署路径
	DEFAULT_DEPLOY_PATH = '/mnt/pokemon/release'
	# 允许的部署路径前缀（安全白名单）
	ALLOWED_DEPLOY_PREFIXES = ['/mnt/pokemon/', '/home/pokemon/', '/opt/pokemon/']

	@coroutine
	def post(self):
		try:
			data = self.get_json_data()
			target = data.get('target')
			deploy_path = data.get('deployPath', self.DEFAULT_DEPLOY_PATH)
			server_configs = data.get('serverConfigs', {})

			if not target:
				self.write({'ret': False, 'err': '缺少合服目标'})
				return

			if not server_configs:
				self.write({'ret': False, 'err': '缺少配置内容，请先生成配置'})
				return

			# 规范化路径并验证安全性
			deploy_path = os.path.normpath(deploy_path)
			# 防止目录遍历攻击
			if '..' in deploy_path:
				self.write({'ret': False, 'err': '部署路径不允许包含 ..'})
				return
			# 验证是否在允许的路径前缀内
			is_allowed = any(deploy_path.startswith(prefix) for prefix in self.ALLOWED_DEPLOY_PREFIXES)
			if not is_allowed:
				self.write({'ret': False, 'err': '部署路径不在允许范围内。允许的路径前缀: %s' % ', '.join(self.ALLOWED_DEPLOY_PREFIXES)})
				return

			# 验证部署路径存在
			if not os.path.exists(deploy_path):
				self.write({'ret': False, 'err': '部署路径不存在: %s' % deploy_path})
				return

			deployed_files = []
			errors = []

			# 1. 合并 game_defines.py (追加 ServerDefs 条目)
			if server_configs.get('gameDefines'):
				try:
					result = self._merge_game_defines(deploy_path, server_configs['gameDefines'], target)
					deployed_files.append('game_defines.py (%s)' % result)
				except Exception as e:
					errors.append('game_defines.py: %s' % str(e))

			# 2. 合并 login/conf/game.json (追加服务器)
			if server_configs.get('gameJson'):
				try:
					result = self._merge_game_json(deploy_path, server_configs['gameJson'], target)
					deployed_files.append('login/conf/game.json (%s)' % result)
				except Exception as e:
					errors.append('login/conf/game.json: %s' % str(e))

			# 3. 合并 pvp/defines_merge.json
			if server_configs.get('pvpJson'):
				try:
					result = self._merge_json_config(deploy_path, 'pvp', server_configs['pvpJson'])
					deployed_files.append('pvp/defines_merge.json (%s)' % result)
				except Exception as e:
					errors.append('pvp/defines_merge.json: %s' % str(e))

			# 4. 合并 storage/defines_merge.json
			if server_configs.get('storageJson'):
				try:
					result = self._merge_json_config(deploy_path, 'storage', server_configs['storageJson'])
					deployed_files.append('storage/defines_merge.json (%s)' % result)
				except Exception as e:
					errors.append('storage/defines_merge.json: %s' % str(e))

			# 5. 部署 supervisor ini 文件
			supervisor_path = data.get('supervisorPath', '/mnt/pokemon/deploy_dev/supervisord.dir')
			# 验证 supervisor 路径安全性
			supervisor_path = os.path.normpath(supervisor_path)
			if '..' in supervisor_path:
				errors.append('supervisor ini: 路径不允许包含 ..')
			elif not any(supervisor_path.startswith(prefix) for prefix in self.ALLOWED_DEPLOY_PREFIXES):
				errors.append('supervisor ini: 路径不在允许范围内')
			elif server_configs.get('supervisorIni'):
				try:
					ini_files = self._deploy_supervisor_ini(supervisor_path, server_configs['supervisorIni'], target)
					for ini_file in ini_files:
						deployed_files.append('%s/%s' % (supervisor_path.split('/')[-1], ini_file))
				except Exception as e:
					errors.append('supervisor ini: %s' % str(e))

			if errors:
				self.write({
					'ret': False,
					'err': '部分文件部署失败',
					'deployed': deployed_files,
					'errors': errors
				})
			else:
				self.write({
					'ret': True,
					'message': '配置部署成功（增量合并）',
					'deployed': deployed_files,
					'deployPath': deploy_path,
					'supervisorPath': supervisor_path
				})

		except Exception as e:
			logging.exception('ServerMergeDeployConfigHandler error')
			self.write({'ret': False, 'err': str(e)})

	def _merge_game_defines(self, deploy_path, new_content, target):
		"""合并 game_defines.py - 在 ServerDefs 中追加新服务器配置"""
		import re
		file_path = os.path.join(deploy_path, 'game_defines.py')

		# 从新内容中提取要添加的服务器配置块
		# 匹配 'gamemerge.xxx': { ... }, 的部分（包含内部嵌套）
		pattern = r"(\t'%s':\s*\{[\s\S]*?\n\t\},)" % re.escape(target)
		match = re.search(pattern, new_content)
		if not match:
			# 尝试匹配不带缩进的格式
			pattern = r"('%s':\s*\{[\s\S]*?\n\},)" % re.escape(target)
			match = re.search(pattern, new_content)

		if not match:
			raise Exception('无法从生成的配置中提取服务器定义')

		new_server_block = match.group(1)

		# 读取现有文件
		if os.path.exists(file_path):
			with open(file_path, 'r') as f:
				existing_content = f.read()

			# 检查是否已存在该服务器配置
			if ("'%s'" % target) in existing_content:
				return '已存在，跳过'

			# 找到 ServerDefs 字典的结束位置
			# 策略：找到最后一个 }, 或 } 后跟 } 的位置
			
			# 方法1：找 ServerDefs = { 开始，然后匹配到对应的 }
			# 简化处理：找到 "}\n}" 或 "},\n}" 模式，在倒数第二个 } 后插入
			
			# 查找 ServerDefs 字典的内容
			server_defs_match = re.search(r'ServerDefs\s*=\s*\{', existing_content)
			if not server_defs_match:
				raise Exception('未找到 ServerDefs 定义')

			# 从 ServerDefs 开始，找到字典结束的 }
			start_pos = server_defs_match.end()
			brace_count = 1
			end_pos = start_pos
			
			while brace_count > 0 and end_pos < len(existing_content):
				char = existing_content[end_pos]
				if char == '{':
					brace_count += 1
				elif char == '}':
					brace_count -= 1
				end_pos += 1

			if brace_count != 0:
				raise Exception('ServerDefs 字典格式错误')

			# end_pos 现在指向 ServerDefs 结束 } 之后
			# 我们需要在 } 之前插入新配置
			insert_pos = end_pos - 1

			# 检查 } 之前是否有内容，确保添加逗号
			# 向前查找最后一个非空白字符
			check_pos = insert_pos - 1
			while check_pos >= start_pos and existing_content[check_pos] in ' \t\n\r':
				check_pos -= 1

			# 如果最后一个字符不是逗号，需要添加逗号
			needs_comma = check_pos >= start_pos and existing_content[check_pos] not in ',{'
			
			# 构建新内容
			before = existing_content[:insert_pos]
			after = existing_content[insert_pos:]
			
			# 确保前面有换行，添加新服务器块
			if needs_comma:
				# 在最后一个 } 或 ] 后添加逗号
				# 向前找到最后一个 } 或 ]
				comma_pos = check_pos + 1
				new_file_content = existing_content[:comma_pos] + ',' + existing_content[comma_pos:insert_pos] + '\n\n' + new_server_block + '\n' + after
			else:
				new_file_content = before.rstrip() + '\n\n' + new_server_block + '\n' + after

			with open(file_path, 'w') as f:
				f.write(new_file_content)
			return '已追加'
		else:
			# 文件不存在，直接写入
			with open(file_path, 'w') as f:
				f.write(new_content)
			return '新建'

	def _merge_game_json(self, deploy_path, new_content, target):
		"""合并 game.json - 追加新服务器/更新源服务器端口"""
		import json

		dir_path = os.path.join(deploy_path, 'login', 'conf')
		if not os.path.exists(dir_path):
			os.makedirs(dir_path)
		file_path = os.path.join(dir_path, 'game.json')

		# 解析新配置
		new_servers = json.loads(new_content)

		# 读取现有配置
		if os.path.exists(file_path):
			with open(file_path, 'r') as f:
				existing_servers = json.load(f)

			# 构建已存在服务器的索引 {key: index}
			existing_index = {}
			for i, s in enumerate(existing_servers):
				key = s.get('key', '')
				if key:
					existing_index[key] = i

			added = 0
			updated = 0
			for server in new_servers:
				server_key = server.get('key')
				if not server_key:
					continue

				if server_key in existing_index:
					# 已存在 - 检查是否需要更新端口
					idx = existing_index[server_key]
					old_addr = existing_servers[idx].get('addr', '')
					new_addr = server.get('addr', '')
					
					# 如果是源服务器（有 merged_to 标记）或端口不同，则更新
					if server.get('merged_to') or old_addr != new_addr:
						existing_servers[idx]['addr'] = new_addr
						# 如果有 merged_to 标记，也保存下来
						if server.get('merged_to'):
							existing_servers[idx]['merged_to'] = server['merged_to']
						updated += 1
				else:
					# 不存在 - 追加
					existing_servers.append(server)
					added += 1

			# 写回文件
			with open(file_path, 'w') as f:
				json.dump(existing_servers, f, indent=2, ensure_ascii=False)

			result_parts = []
			if added > 0:
				result_parts.append('新增 %d' % added)
			if updated > 0:
				result_parts.append('端口更新 %d' % updated)
			return ', '.join(result_parts) if result_parts else '无变化'
		else:
			# 文件不存在，直接写入
			with open(file_path, 'w') as f:
				f.write(new_content)
			return '新建'

	def _merge_json_config(self, deploy_path, subdir, new_content):
		"""合并 JSON 配置文件 - 合并顶级 key"""
		import json

		dir_path = os.path.join(deploy_path, subdir)
		if not os.path.exists(dir_path):
			os.makedirs(dir_path)
		file_path = os.path.join(dir_path, 'defines_merge.json')

		# 解析新配置
		new_config = json.loads(new_content)

		# 读取现有配置
		if os.path.exists(file_path):
			with open(file_path, 'r') as f:
				existing_config = json.load(f)

			# 合并顶级 key（新配置覆盖已存在的同名 key）
			added = 0
			updated = 0
			for key, value in new_config.items():
				if key in existing_config:
					existing_config[key] = value
					updated += 1
				else:
					existing_config[key] = value
					added += 1

			# 写回文件
			with open(file_path, 'w') as f:
				json.dump(existing_config, f, indent=2, ensure_ascii=False)

			result_parts = []
			if added > 0:
				result_parts.append('新增 %d' % added)
			if updated > 0:
				result_parts.append('更新 %d' % updated)
			return ', '.join(result_parts) if result_parts else '无变化'
		else:
			# 文件不存在，直接写入
			with open(file_path, 'w') as f:
				f.write(new_content)
			return '新建'

	def _deploy_supervisor_ini(self, supervisor_path, ini_content, target):
		"""部署 supervisor ini 文件"""
		if not os.path.exists(supervisor_path):
			os.makedirs(supervisor_path)

		# 提取服务器编号
		parts = target.split('.')
		serv_num = parts[-1]

		# 解析 ini 内容，分割成 3 个文件
		deployed = []
		current_file = None
		current_lines = []

		for line in ini_content.split('\n'):
			if line.startswith('=== ') and line.endswith(' ==='):
				# 保存前一个文件
				if current_file and current_lines:
					file_path = os.path.join(supervisor_path, current_file)
					with open(file_path, 'w') as f:
						f.write('\n'.join(current_lines))
					deployed.append(current_file)
				# 开始新文件
				current_file = line[4:-4]  # 去掉 === 和 ===
				current_lines = []
			elif current_file:
				current_lines.append(line)

		# 保存最后一个文件
		if current_file and current_lines:
			file_path = os.path.join(supervisor_path, current_file)
			with open(file_path, 'w') as f:
				f.write('\n'.join(current_lines))
			deployed.append(current_file)

		return deployed


class ServerMergePreCheckHandler(AuthedHandler):
	"""合服前检查"""
	url = '/server_merge/pre_check'

	@coroutine
	def post(self):
		if not HAS_PYMONGO:
			self.write({'ret': False, 'err': 'pymongo not installed'})
			return

		try:
			data = self.get_json_data()
			target = data.get('target')
			mongo_config = data.get('mongoConfig', {})

			if not target:
				self.write({'ret': False, 'err': '请指定合服目标'})
				return

			# 获取源服务器和 MongoDB 配置
			src_servers = []
			saved_mongo_config = {}

			# 1. 先从 MongoDB 查找自定义配置
			try:
				collection = self.mongo_client['MergeConfig']
				doc = collection.find_one({'destServer': target})
				if doc:
					src_servers = doc.get('servers', [])
					saved_mongo_config = doc.get('mongoConfig', {})
			except Exception as e:
				logging.warning('Failed to load MongoDB merge config: %s', e)

			# 2. 如果 MongoDB 没有，从 CSV 读取
			if not src_servers:
				try:
					from framework.csv import csv
					for idx in csv.server.merge.keys():
						cfg = csv.server.merge[idx]
						if cfg.destServer == target:
							src_servers = list(cfg.servers) if cfg.servers else []
							break
				except Exception as e:
					logging.warning('Failed to load CSV merge config: %s', e)

			if not src_servers:
				self.write({'ret': False, 'err': '未找到合服配置'})
				return

			# 合并 MongoDB 配置
			if saved_mongo_config and not mongo_config:
				mongo_config = saved_mongo_config
			elif saved_mongo_config and mongo_config:
				merged = dict(saved_mongo_config)
				merged.update(mongo_config)
				mongo_config = merged

			# 如果有 MongoDB 配置，执行真实检查
			if mongo_config:
				result = self._do_real_check(target, src_servers, mongo_config)
			else:
				# 返回模拟的检查结果
				result = {
					'playerStats': [
						{'server': s, 'total': '?', 'active': '?'}
						for s in src_servers
					],
					'duplicateNames': [],
					'unionCount': '?',
					'duplicateUnions': [],
					'warning': '未配置MongoDB连接，无法执行真实检查'
				}

			self.write({'ret': True, 'result': result})
		except Exception as e:
			logging.exception('ServerMergePreCheckHandler error')
			self.write({'ret': False, 'err': str(e)})

	def _do_real_check(self, target, src_servers, mongo_config):
		"""执行真实的合服前检查"""
		from contextlib import contextmanager

		@contextmanager
		def open_mongo(uri):
			client = pymongo.MongoClient(uri)
			try:
				yield client
			finally:
				client.close()

		def split_name(uri):
			return uri.rsplit('/', 1)[-1].split('?')[0]

		result = {
			'playerStats': [],
			'duplicateNames': [],
			'unionCount': 0,
			'duplicateUnions': []
		}

		all_names = {}  # name -> [servers]
		all_union_names = {}  # name -> [servers]

		for server in src_servers:
			if server not in mongo_config:
				result['playerStats'].append({
					'server': server,
					'total': '未配置',
					'active': '未配置'
				})
				continue

			try:
				with open_mongo(mongo_config[server]) as client:
					db = client[split_name(mongo_config[server])]

					# 玩家统计
					total = db['Role'].count()
					# 最近30天活跃（假设有 last_time 字段）
					import time
					thirty_days_ago = int(time.time()) - 30 * 24 * 3600
					active = db['Role'].find({'last_time': {'$gte': thirty_days_ago}}).count()

					result['playerStats'].append({
						'server': server,
						'total': total,
						'active': active
					})

					# 收集玩家名
					for role in db['Role'].find({}, {'name': 1}):
						name = role.get('name', '')
						if name:
							if name not in all_names:
								all_names[name] = []
							all_names[name].append(server)

					# 收集公会名和数量
					union_count = db['Union'].count() if 'Union' in db.list_collection_names() else 0
					result['unionCount'] += union_count

					if 'Union' in db.list_collection_names():
						for union in db['Union'].find({}, {'name': 1}):
							name = union.get('name', '')
							if name:
								if name not in all_union_names:
									all_union_names[name] = []
								all_union_names[name].append(server)

			except Exception as e:
				logging.warning('Check server %s failed: %s', server, e)
				result['playerStats'].append({
					'server': server,
					'total': '错误',
					'active': str(e)[:50]
				})

		# 找出重名
		result['duplicateNames'] = [name for name, servers in all_names.items() if len(servers) > 1][:20]
		result['duplicateUnions'] = [name for name, servers in all_union_names.items() if len(servers) > 1][:10]

		return result


# ============================================================
# 大区管理
# ============================================================

class ServerAreaPageHandler(AuthedHandler):
	"""大区管理页面"""
	url = '/server_area_page'

	def get(self):
		self.render_page('_server_area.html')


class ServerAreaConfigHandler(AuthedHandler):
	"""大区配置管理 - 读取/修改 game.json"""
	url = '/server_area/config'

	# 默认配置文件路径
	DEFAULT_CONFIG_PATH = '/mnt/pokemon/release/login/conf/game.json'
	# 允许的路径前缀（安全白名单）
	ALLOWED_PATH_PREFIXES = ['/mnt/pokemon/', '/home/pokemon/', '/opt/pokemon/']

	def get(self):
		"""读取 game.json 配置"""
		try:
			config_path = self.get_argument('path', self.DEFAULT_CONFIG_PATH)

			# 安全检查
			config_path = os.path.normpath(config_path)
			if '..' in config_path:
				self.write({'ret': False, 'err': '路径不允许包含 ..'})
				return

			if not os.path.exists(config_path):
				self.write({'ret': False, 'err': '配置文件不存在: %s' % config_path})
				return

			import json
			with open(config_path, 'r') as f:
				servers = json.load(f)

			# 解析服务器信息
			server_list = []
			for s in servers:
				addr = s.get('addr', '')
				ip, port = '', ''
				if ':' in addr:
					ip, port = addr.rsplit(':', 1)

				server_list.append({
					'key': s.get('key', ''),
					'addr': addr,
					'ip': ip,
					'port': port,
					'open_date': s.get('open_date', ''),
					'merged_to': s.get('merged_to', ''),
				})

			# 按 key 排序
			server_list.sort(key=lambda x: x['key'])

			self.write({
				'ret': True,
				'servers': server_list,
				'configPath': config_path
			})
		except Exception as e:
			logging.exception('ServerAreaConfigHandler.get error')
			self.write({'ret': False, 'err': str(e)})

	def post(self):
		"""更新单个服务器配置"""
		try:
			data = self.get_json_data()
			config_path = data.get('configPath', self.DEFAULT_CONFIG_PATH)
			server_key = data.get('key')
			new_addr = data.get('addr')
			new_open_date = data.get('open_date')

			if not server_key:
				self.write({'ret': False, 'err': '缺少服务器 key'})
				return

			# 安全检查
			config_path = os.path.normpath(config_path)
			if '..' in config_path:
				self.write({'ret': False, 'err': '路径不允许包含 ..'})
				return
			if not any(config_path.startswith(prefix) for prefix in self.ALLOWED_PATH_PREFIXES):
				self.write({'ret': False, 'err': '路径不在允许范围内'})
				return

			if not os.path.exists(config_path):
				self.write({'ret': False, 'err': '配置文件不存在'})
				return

			import json
			# 读取现有配置
			with open(config_path, 'r') as f:
				servers = json.load(f)

			# 查找并更新
			updated = False
			for s in servers:
				if s.get('key') == server_key:
					if new_addr:
						s['addr'] = new_addr
					if new_open_date:
						s['open_date'] = new_open_date
					updated = True
					break

			if not updated:
				self.write({'ret': False, 'err': '未找到服务器: %s' % server_key})
				return

			# 备份原文件
			backup_path = config_path + '.bak'
			import shutil
			shutil.copy2(config_path, backup_path)

			# 写入新配置
			with open(config_path, 'w') as f:
				json.dump(servers, f, indent=2, ensure_ascii=False)

			logging.info('Updated server area config: %s in %s', server_key, config_path)
			self.write({'ret': True, 'message': '配置已更新，已备份原文件到 %s' % backup_path})
		except Exception as e:
			logging.exception('ServerAreaConfigHandler.post error')
			self.write({'ret': False, 'err': str(e)})

	def delete(self):
		"""删除服务器配置"""
		try:
			config_path = self.get_argument('configPath', self.DEFAULT_CONFIG_PATH)
			server_key = self.get_argument('key')

			if not server_key:
				self.write({'ret': False, 'err': '缺少服务器 key'})
				return

			# 安全检查
			config_path = os.path.normpath(config_path)
			if '..' in config_path:
				self.write({'ret': False, 'err': '路径不允许包含 ..'})
				return
			if not any(config_path.startswith(prefix) for prefix in self.ALLOWED_PATH_PREFIXES):
				self.write({'ret': False, 'err': '路径不在允许范围内'})
				return

			if not os.path.exists(config_path):
				self.write({'ret': False, 'err': '配置文件不存在'})
				return

			import json
			# 读取现有配置
			with open(config_path, 'r') as f:
				servers = json.load(f)

			# 查找并删除
			original_len = len(servers)
			servers = [s for s in servers if s.get('key') != server_key]

			if len(servers) == original_len:
				self.write({'ret': False, 'err': '未找到服务器: %s' % server_key})
				return

			# 备份原文件
			backup_path = config_path + '.bak'
			import shutil
			shutil.copy2(config_path, backup_path)

			# 写入新配置
			with open(config_path, 'w') as f:
				json.dump(servers, f, indent=2, ensure_ascii=False)

			logging.info('Deleted server area config: %s from %s', server_key, config_path)
			self.write({'ret': True, 'message': '服务器已删除'})
		except Exception as e:
			logging.exception('ServerAreaConfigHandler.delete error')
			self.write({'ret': False, 'err': str(e)})


class ServerAreaAddHandler(AuthedHandler):
	"""添加新服务器"""
	url = '/server_area/add'

	ALLOWED_PATH_PREFIXES = ['/mnt/pokemon/', '/home/pokemon/', '/opt/pokemon/']

	def post(self):
		"""添加新服务器配置"""
		try:
			data = self.get_json_data()
			config_path = data.get('configPath', '/mnt/pokemon/release/login/conf/game.json')
			server_key = data.get('key', '').strip()
			addr = data.get('addr', '').strip()
			open_date = data.get('open_date', '').strip()

			if not server_key:
				self.write({'ret': False, 'err': '缺少服务器 key'})
				return
			if not addr:
				self.write({'ret': False, 'err': '缺少服务器地址'})
				return
			if not open_date:
				self.write({'ret': False, 'err': '缺少开服时间'})
				return

			# 安全检查
			config_path = os.path.normpath(config_path)
			if '..' in config_path:
				self.write({'ret': False, 'err': '路径不允许包含 ..'})
				return
			if not any(config_path.startswith(prefix) for prefix in self.ALLOWED_PATH_PREFIXES):
				self.write({'ret': False, 'err': '路径不在允许范围内'})
				return

			import json
			# 读取现有配置（如果存在）
			servers = []
			if os.path.exists(config_path):
				with open(config_path, 'r') as f:
					servers = json.load(f)

			# 检查是否已存在
			for s in servers:
				if s.get('key') == server_key:
					self.write({'ret': False, 'err': '服务器 %s 已存在' % server_key})
					return

			# 添加新服务器
			new_server = {
				'key': server_key,
				'addr': addr,
				'open_date': open_date
			}
			servers.append(new_server)

			# 备份原文件（如果存在）
			if os.path.exists(config_path):
				backup_path = config_path + '.bak'
				import shutil
				shutil.copy2(config_path, backup_path)

			# 确保目录存在
			dir_path = os.path.dirname(config_path)
			if not os.path.exists(dir_path):
				os.makedirs(dir_path)

			# 写入配置
			with open(config_path, 'w') as f:
				json.dump(servers, f, indent=2, ensure_ascii=False)

			logging.info('Added server area: %s to %s', server_key, config_path)
			self.write({'ret': True, 'message': '服务器已添加'})
		except Exception as e:
			logging.exception('ServerAreaAddHandler.post error')
			self.write({'ret': False, 'err': str(e)})


class ServerNewPageHandler(AuthedHandler):
	"""新区管理页面"""
	url = '/server_new_page'

	def get(self):
		self.render_page('_server_new.html')


class ServerNewDeployHandler(AuthedHandler):
	"""新区配置部署"""
	url = '/server_new_deploy'

	ALLOWED_PREFIXES = ['/mnt/pokemon/', '/home/pokemon/', '/opt/pokemon/']

	def _check_path(self, path):
		path = os.path.normpath(path)
		if '..' in path:
			return False
		return any(path.startswith(p) for p in self.ALLOWED_PREFIXES)

	def _merge_json(self, path, new_data, is_array=False, key_field='key'):
		"""合并JSON文件，存在则删除再添加"""
		dir_path = os.path.dirname(path)
		if not os.path.exists(dir_path):
			os.makedirs(dir_path)

		data = [] if is_array else {}
		if os.path.exists(path):
			try:
				with open(path, 'r') as f:
					content = f.read().strip()
					if content:
						data = json.loads(content)
			except:
				data = [] if is_array else {}

		status = '新增'
		if is_array:
			# game.json是数组，先删除已存在的，再添加
			new_key = new_data.get(key_field)
			old_len = len(data)
			data = [x for x in data if x.get(key_field) != new_key]
			if len(data) < old_len:
				status = '已更新(原有)'
			data.append(new_data)
			with open(path, 'w') as f:
				json.dump(data, f, indent=2, sort_keys=True)
		else:
			# pvp/storage是对象，先删除已存在的key，再添加
			replaced = []
			for k, v in new_data.items():
				if k in data:
					replaced.append(k)
				data[k] = v
			with open(path, 'w') as f:
				json.dump(data, f, indent=2, sort_keys=True)
			status = '已更新: ' + ','.join(replaced) if replaced else '新增'
		return status

	def _merge_game_defines(self, path, server_key, new_block):
		"""合并 game_defines.py，存在则删除再添加"""
		if not os.path.exists(path):
			return '文件不存在'

		with open(path, 'r') as f:
			lines = f.readlines()

		# 查找并删除已存在的服务器配置块
		key_pattern = "'%s':" % server_key
		key_pattern2 = '"%s":' % server_key
		new_lines = []
		skip_block = False
		brace_count = 0
		status = '新增'

		for line in lines:
			if not skip_block:
				# 检查是否是目标服务器的开始行
				if key_pattern in line or key_pattern2 in line:
					skip_block = True
					brace_count = 0
					status = '已更新(原有)'
					# 统计这行的大括号
					brace_count += line.count('{') - line.count('}')
					continue
				new_lines.append(line)
			else:
				# 正在跳过块，统计大括号
				brace_count += line.count('{') - line.count('}')
				if brace_count <= 0:
					# 块结束，跳过这行（包含 }, 或 }）
					skip_block = False
					continue

		# 找到 ServerDefs 的结束位置（最后一个独立的 }）
		insert_idx = -1
		for i in range(len(new_lines) - 1, -1, -1):
			if new_lines[i].strip() == '}':
				insert_idx = i
				break

		if insert_idx > 0:
			# 确保前一行有逗号
			prev = new_lines[insert_idx - 1].rstrip('\n\r')
			if prev and not prev.rstrip().endswith(',') and not prev.rstrip().endswith('{'):
				new_lines[insert_idx - 1] = prev.rstrip() + ',\n'
			
			# 处理新块，确保只有一个逗号
			new_block = new_block.rstrip()
			if new_block.endswith(','):
				new_block = new_block[:-1]  # 移除末尾逗号
			new_lines.insert(insert_idx, new_block + ',\n')

			with open(path, 'w') as f:
				f.writelines(new_lines)
			return status
		return '解析失败'

	def _write_ini(self, path, content):
		dir_path = os.path.dirname(path)
		if not os.path.exists(dir_path):
			os.makedirs(dir_path)
		with open(path, 'w') as f:
			f.write(content)

	def post(self):
		try:
			data = self.get_json_data()
			deploy_path = data.get('deployPath', '/mnt/pokemon/release')
			supervisor_path = data.get('supervisorPath', '/mnt/pokemon/deploy_dev/supervisord.dir')

			if not self._check_path(deploy_path) or not self._check_path(supervisor_path):
				self.write({'ret': False, 'err': '路径不允许'})
				return

			details = {}

			# 1. game_defines.py
			game_defines = data.get('gameDefines')
			server_key = data.get('serverKey')
			if game_defines and server_key:
				path = os.path.join(deploy_path, 'game_defines.py')
				details['game_defines.py'] = self._merge_game_defines(path, server_key, game_defines)

			# 2. game.json
			game_json = data.get('gameJson')
			if game_json:
				path = os.path.join(deploy_path, 'login', 'conf', 'game.json')
				details['game.json'] = self._merge_json(path, game_json, is_array=True)

			# 3. pvp/defines.json
			pvp_config = data.get('pvpConfig')
			if pvp_config:
				path = os.path.join(deploy_path, 'pvp', 'defines.json')
				details['pvp/defines.json'] = self._merge_json(path, pvp_config, is_array=False)

			# 4. storage/defines.json
			storage_config = data.get('storageConfig')
			if storage_config:
				path = os.path.join(deploy_path, 'storage', 'defines.json')
				details['storage/defines.json'] = self._merge_json(path, storage_config, is_array=False)

			# 5. supervisor ini
			num = data.get('num', '')
			if num:
				# 安全检查：num只能是数字和下划线
				import re
				if not re.match(r'^[\d_]+$', str(num)):
					self.write({'ret': False, 'err': 'num参数非法'})
					return
				if data.get('iniGame'):
					ini_path = os.path.join(supervisor_path, '%s_game_server.ini' % num)
					exists = os.path.exists(ini_path)
					self._write_ini(ini_path, data['iniGame'])
					details['game_server.ini'] = '已更新' if exists else '已创建'
				if data.get('iniPvp'):
					ini_path = os.path.join(supervisor_path, '%s_pvp_server.ini' % num)
					exists = os.path.exists(ini_path)
					self._write_ini(ini_path, data['iniPvp'])
					details['pvp_server.ini'] = '已更新' if exists else '已创建'
				if data.get('iniStorage'):
					ini_path = os.path.join(supervisor_path, '%s_storage_server.ini' % num)
					exists = os.path.exists(ini_path)
					self._write_ini(ini_path, data['iniStorage'])
					details['storage_server.ini'] = '已更新' if exists else '已创建'

			logging.info('ServerNewDeploy: %s', details)
			self.write({'ret': True, 'details': details})
		except Exception as e:
			logging.exception('ServerNewDeployHandler error')
			self.write({'ret': False, 'err': str(e)})


class ServerConfigListHandler(AuthedHandler):
	"""列出所有配置"""
	url = '/server_config_list'

	ALLOWED_PREFIXES = ['/mnt/pokemon/', '/home/pokemon/', '/opt/pokemon/']

	def _check_path(self, path):
		path = os.path.normpath(path)
		if '..' in path:
			return False
		return any(path.startswith(p) for p in self.ALLOWED_PREFIXES)

	def post(self):
		try:
			data = self.get_json_data()
			deploy_path = data.get('deployPath', '/mnt/pokemon/release')
			supervisor_path = data.get('supervisorPath', '/mnt/pokemon/deploy_dev/supervisord.dir')

			if not self._check_path(deploy_path) or not self._check_path(supervisor_path):
				self.write({'ret': False, 'err': '路径不允许'})
				return

			result = {'ret': True}

			# game.json
			game_json_path = os.path.join(deploy_path, 'login', 'conf', 'game.json')
			if os.path.exists(game_json_path):
				with open(game_json_path, 'r') as f:
					result['gameJson'] = json.load(f)
			else:
				result['gameJson'] = []

			# pvp/defines.json
			pvp_path = os.path.join(deploy_path, 'pvp', 'defines.json')
			if os.path.exists(pvp_path):
				with open(pvp_path, 'r') as f:
					result['pvpJson'] = json.load(f)
			else:
				result['pvpJson'] = {}

			# storage/defines.json
			storage_path = os.path.join(deploy_path, 'storage', 'defines.json')
			if os.path.exists(storage_path):
				with open(storage_path, 'r') as f:
					result['storageJson'] = json.load(f)
			else:
				result['storageJson'] = {}

			# supervisor ini files
			ini_files = []
			if os.path.exists(supervisor_path):
				for f in os.listdir(supervisor_path):
					if f.endswith('.ini'):
						ini_files.append({'name': f})
			result['iniFiles'] = ini_files

			self.write(result)
		except Exception as e:
			logging.exception('ServerConfigListHandler error')
			self.write({'ret': False, 'err': str(e)})


class ServerConfigGetHandler(AuthedHandler):
	"""获取单个配置"""
	url = '/server_config_get'

	ALLOWED_PREFIXES = ['/mnt/pokemon/', '/home/pokemon/', '/opt/pokemon/']

	def _check_path(self, path):
		path = os.path.normpath(path)
		if '..' in path:
			return False
		return any(path.startswith(p) for p in self.ALLOWED_PREFIXES)

	def _check_filename(self, filename):
		"""检查文件名是否安全，防止路径遍历"""
		if not filename:
			return False
		# 不允许包含路径分隔符和..
		if '/' in filename or '\\' in filename or '..' in filename:
			return False
		# 只允许字母、数字、下划线、点、横线
		import re
		if not re.match(r'^[\w\.\-]+$', filename):
			return False
		return True

	def post(self):
		try:
			data = self.get_json_data()
			deploy_path = data.get('deployPath', '/mnt/pokemon/release')
			supervisor_path = data.get('supervisorPath', '/mnt/pokemon/deploy_dev/supervisord.dir')
			config_type = data.get('type')
			key = data.get('key')

			if not self._check_path(deploy_path) or not self._check_path(supervisor_path):
				self.write({'ret': False, 'err': '路径不允许'})
				return

			if config_type == 'gameJson':
				path = os.path.join(deploy_path, 'login', 'conf', 'game.json')
				with open(path, 'r') as f:
					items = json.load(f)
				for item in items:
					if item.get('key') == key:
						self.write({'ret': True, 'data': item})
						return
				self.write({'ret': False, 'err': '未找到'})

			elif config_type == 'pvpJson':
				path = os.path.join(deploy_path, 'pvp', 'defines.json')
				with open(path, 'r') as f:
					config = json.load(f)
				if key in config:
					self.write({'ret': True, 'data': config[key]})
				else:
					self.write({'ret': False, 'err': '未找到'})

			elif config_type == 'storageJson':
				path = os.path.join(deploy_path, 'storage', 'defines.json')
				with open(path, 'r') as f:
					config = json.load(f)
				if key in config:
					self.write({'ret': True, 'data': config[key]})
				else:
					self.write({'ret': False, 'err': '未找到'})

			elif config_type == 'ini':
				# 安全检查：防止路径遍历
				if not self._check_filename(key):
					self.write({'ret': False, 'err': '非法文件名'})
					return
				path = os.path.join(supervisor_path, key)
				if os.path.exists(path):
					with open(path, 'r') as f:
						self.write({'ret': True, 'data': f.read()})
				else:
					self.write({'ret': False, 'err': '文件不存在'})
			else:
				self.write({'ret': False, 'err': '未知类型'})

		except Exception as e:
			logging.exception('ServerConfigGetHandler error')
			self.write({'ret': False, 'err': str(e)})


class ServerConfigSaveHandler(AuthedHandler):
	"""保存配置"""
	url = '/server_config_save'

	ALLOWED_PREFIXES = ['/mnt/pokemon/', '/home/pokemon/', '/opt/pokemon/']

	def _check_path(self, path):
		path = os.path.normpath(path)
		if '..' in path:
			return False
		return any(path.startswith(p) for p in self.ALLOWED_PREFIXES)

	def _check_filename(self, filename):
		"""检查文件名是否安全，防止路径遍历"""
		if not filename:
			return False
		if '/' in filename or '\\' in filename or '..' in filename:
			return False
		import re
		if not re.match(r'^[\w\.\-]+$', filename):
			return False
		return True

	def post(self):
		try:
			data = self.get_json_data()
			deploy_path = data.get('deployPath', '/mnt/pokemon/release')
			supervisor_path = data.get('supervisorPath', '/mnt/pokemon/deploy_dev/supervisord.dir')
			config_type = data.get('type')
			key = data.get('key')
			content = data.get('content')

			if not self._check_path(deploy_path) or not self._check_path(supervisor_path):
				self.write({'ret': False, 'err': '路径不允许'})
				return

			if config_type == 'gameJson':
				path = os.path.join(deploy_path, 'login', 'conf', 'game.json')
				with open(path, 'r') as f:
					items = json.load(f)
				new_data = json.loads(content)
				for i, item in enumerate(items):
					if item.get('key') == key:
						items[i] = new_data
						break
				with open(path, 'w') as f:
					json.dump(items, f, indent=2, sort_keys=True)

			elif config_type == 'pvpJson':
				path = os.path.join(deploy_path, 'pvp', 'defines.json')
				with open(path, 'r') as f:
					config = json.load(f)
				config[key] = json.loads(content)
				with open(path, 'w') as f:
					json.dump(config, f, indent=2, sort_keys=True)

			elif config_type == 'storageJson':
				path = os.path.join(deploy_path, 'storage', 'defines.json')
				with open(path, 'r') as f:
					config = json.load(f)
				config[key] = json.loads(content)
				with open(path, 'w') as f:
					json.dump(config, f, indent=2, sort_keys=True)

			elif config_type == 'ini':
				# 安全检查：防止路径遍历
				if not self._check_filename(key):
					self.write({'ret': False, 'err': '非法文件名'})
					return
				path = os.path.join(supervisor_path, key)
				with open(path, 'w') as f:
					f.write(content)
			else:
				self.write({'ret': False, 'err': '未知类型'})
				return

			self.write({'ret': True})
		except Exception as e:
			logging.exception('ServerConfigSaveHandler error')
			self.write({'ret': False, 'err': str(e)})


class ServerConfigDeleteHandler(AuthedHandler):
	"""删除配置"""
	url = '/server_config_delete'

	ALLOWED_PREFIXES = ['/mnt/pokemon/', '/home/pokemon/', '/opt/pokemon/']

	def _check_path(self, path):
		path = os.path.normpath(path)
		if '..' in path:
			return False
		return any(path.startswith(p) for p in self.ALLOWED_PREFIXES)

	def _check_filename(self, filename):
		"""检查文件名是否安全，防止路径遍历"""
		if not filename:
			return False
		if '/' in filename or '\\' in filename or '..' in filename:
			return False
		import re
		if not re.match(r'^[\w\.\-]+$', filename):
			return False
		return True

	def post(self):
		try:
			data = self.get_json_data()
			deploy_path = data.get('deployPath', '/mnt/pokemon/release')
			supervisor_path = data.get('supervisorPath', '/mnt/pokemon/deploy_dev/supervisord.dir')
			config_type = data.get('type')
			key = data.get('key')

			if not self._check_path(deploy_path) or not self._check_path(supervisor_path):
				self.write({'ret': False, 'err': '路径不允许'})
				return

			if config_type == 'gameJson':
				path = os.path.join(deploy_path, 'login', 'conf', 'game.json')
				with open(path, 'r') as f:
					items = json.load(f)
				items = [x for x in items if x.get('key') != key]
				with open(path, 'w') as f:
					json.dump(items, f, indent=2, sort_keys=True)

			elif config_type == 'pvpJson':
				path = os.path.join(deploy_path, 'pvp', 'defines.json')
				with open(path, 'r') as f:
					config = json.load(f)
				if key in config:
					del config[key]
				with open(path, 'w') as f:
					json.dump(config, f, indent=2, sort_keys=True)

			elif config_type == 'storageJson':
				path = os.path.join(deploy_path, 'storage', 'defines.json')
				with open(path, 'r') as f:
					config = json.load(f)
				if key in config:
					del config[key]
				with open(path, 'w') as f:
					json.dump(config, f, indent=2, sort_keys=True)

			elif config_type == 'ini':
				# 安全检查：防止路径遍历
				if not self._check_filename(key):
					self.write({'ret': False, 'err': '非法文件名'})
					return
				path = os.path.join(supervisor_path, key)
				if os.path.exists(path):
					os.remove(path)
			else:
				self.write({'ret': False, 'err': '未知类型'})
				return

			self.write({'ret': True})
		except Exception as e:
			logging.exception('ServerConfigDeleteHandler error')
			self.write({'ret': False, 'err': str(e)})