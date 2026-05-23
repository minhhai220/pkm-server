#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Society Handlers
'''

from framework.csv import ErrDefs, ConstDefs
from framework.log import logger
from framework.distributed.helper import multi_future
from game import ServerError, ClientError
from game.handler.task import RequestHandlerTask
from game.globaldata import FriendListMax, FriendsMax
from game.object.game import ObjectGame
from game.object.game.yyhuodong import ObjectYYHuoDongFactory
from game.object.game.society import ObjectSociety, ObjectSocietyGlobal
from game.object import SceneDefs, AchievementDefs, TargetDefs

from tornado.gen import coroutine, Return


@coroutine
def getFriendSociety(dbc, roleID):
	game = ObjectGame.getByRoleID(roleID, safe=False)
	# 在线玩家
	if game:
		raise Return(game.society)

	# 非在线玩家
	societyDatas = yield dbc.call_async('DBReadBy', 'Society', {'role_db_id': roleID})
	if not societyDatas['ret']:
		raise ServerError('db read society error')
	societyData = societyDatas['models'][0]
	society = ObjectSociety(None, dbc).set(societyData).init()
	raise Return(society)


# 申请好友请求
class SocietyFriendAskfor(RequestHandlerTask):
	url = r'/game/society/friend/askfor'

	@coroutine
	def run(self):
		roleIDs = self.input.get('roleIDs', None)

		if roleIDs is None:
			raise ClientError('roleIDs is miss')

		only = len(roleIDs) == 1
		for roleID in roleIDs:
			try:
				# 是否已经是好友
				if self.game.society.isFriend(roleID):
					raise ClientError(ErrDefs.friendAlready)
				# 是否是自己
				if self.game.role.id == roleID:
					raise ClientError(ErrDefs.friendAskforSelf)

				friendSociety = yield getFriendSociety(self.dbcGame, roleID)
				self.game.society.askforFriend(friendSociety)

			except:
				if only:
					raise


# 接受好友请求
class SocietyFriendAccept(RequestHandlerTask):
	url = r'/game/society/friend/accept'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		auto = self.input.get('auto', None)

		if roleID is None and auto is None:
			raise ClientError('param is miss')

		bindRole = self.game.role.reunionBindRole
		needRefresh = False

		if roleID:
			friendSociety = yield getFriendSociety(self.dbcGame, roleID)
			self.game.society.acceptFriend(roleID, friendSociety)
			if bindRole == roleID:
				needRefresh = True

		elif auto:
			roleIDs = self.game.society.acceptFriendAutoBegin()
			friendSocietysL = []
			for roleID in roleIDs:
				friendSociety = yield getFriendSociety(self.dbcGame, roleID)
				friendSocietysL.append(friendSociety)
				if bindRole == roleID:
					needRefresh = True
			self.game.society.acceptFriendAutoEnd(friendSocietysL)

			refuseFlag = False
			if self.game.society.friend_reqs:
				refuseFlag = True
				# 剩下的 全部拒绝掉
				self.game.society.rejectFriendAuto()

			self.write({'view': {
				'refuseFlag': refuseFlag,
			}})

		if needRefresh:
			from game.handler._yyhuodong import getReunion
			reunion = yield getReunion(self.dbcGame, self.game.role.reunion['info']['role_id'])
			ObjectYYHuoDongFactory.refreshReunionRecord(self.game, reunion, TargetDefs.ReunionFriend, 0)


# 拒绝好友请求
class SocietyFriendReject(RequestHandlerTask):
	url = r'/game/society/friend/reject'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		auto = self.input.get('auto', None)

		if roleID is None and auto is None:
			raise ClientError('param is miss')

		if roleID:
			self.game.society.rejectFriend(roleID)

		elif auto:
			self.game.society.rejectFriendAuto()


# 删除好友
class SocietyFriendDelete(RequestHandlerTask):
	url = r'/game/society/friend/delete'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)

		if roleID is None:
			raise ClientError('roleID is miss')

		# 是否已经是好友
		if not self.game.society.isFriend(roleID):
			raise ClientError(ErrDefs.friendNone)

		friendSociety = yield getFriendSociety(self.dbcGame, roleID)
		self.game.society.deleteFriend(roleID, friendSociety)


# 赠送好友体力
class SocietyFriendSendStamina(RequestHandlerTask):
	url = r'/game/society/friend/stamina/send'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		auto = self.input.get('auto', None)

		if roleID is None and auto is None:
			raise ClientError('param is miss')

		send = 0
		if roleID:
			# 是否已经是好友
			if not self.game.society.isFriend(roleID):
				raise ClientError(ErrDefs.friendNone)

			friendSociety = yield getFriendSociety(self.dbcGame, roleID)
			send = self.game.society.sendStamina(roleID, friendSociety)
			if send > 0:
				self.game.achievement.onCount(AchievementDefs.FriendStaminaSend, 1)

		elif auto:
			roleIDs = self.game.society.sendStaminaAutoBegin()
			allFriendSociety = yield multi_future({roleID:getFriendSociety(self.dbcGame, roleID) for roleID in roleIDs})
			send = self.game.society.sendStaminaAutoEnd(allFriendSociety.values())
			if send > 0:
				self.game.achievement.onCount(AchievementDefs.FriendStaminaSend, len(roleIDs))
		self.write({'view':{'send':send}})

# 领取好友体力
class SocietyFriendRecvStamina(RequestHandlerTask):
	url = r'/game/society/friend/stamina/recv'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		auto = self.input.get('auto', None)

		if roleID is None and auto is None:
			raise ClientError('param is miss')

		recv = 0
		if roleID:
			# 是否已经是好友
			if not self.game.society.isFriend(roleID):
				raise ClientError(ErrDefs.friendNone)

			recv = self.game.society.recvStamina(roleID)

		elif auto:
			recv = self.game.society.recvStaminaAuto()
		logger.info('role %d %s recv stamina %d', self.game.role.uid, self.game.role.pid, recv)

		self.write({'view':{'recv':recv}})

# 换一批申请列表
class SocietyFriendList(RequestHandlerTask):
	url = r'/game/society/friend/list'

	@coroutine
	def run(self):
		ret = ObjectSocietyGlobal.getRandomFriends(self.game)

		self.write({'view': {
			'roles': ret,
			'size': len(ret),
		}})

# 在线好友列表
class SocietyFriendOnlineList(RequestHandlerTask):
	url = r'/game/society/friend/online/list'

	@coroutine
	def run(self):
		ret = ObjectSocietyGlobal.getOnlineFriends(self.game)

		self.write({'view': {
			'roles': ret,
			'size': len(ret),
		}})

@coroutine
def getSocietyRole(dbc, roleID=None, roleName=None, uid=None):
	if roleID:
		ret = ObjectSocietyGlobal.RoleCache.getByKey(roleID)
		if ret:
			raise Return([ret])

		model = yield dbc.call_async('DBRead', 'Role', roleID, True)
		if not model['ret'] or 'robot' in model['model']['account_id']:
			raise ClientError(ErrDefs.friendSearchNoSuchRole)

		ret = ObjectSocietyGlobal.onRoleInfoByModel(model['model'])
		raise Return([ret])

	roles = []
	if uid:
		ret = ObjectSocietyGlobal.getFriendByUID(uid)
		if ret:
			roles.append(ret)
		else:
			model = yield dbc.call_async('DBReadBy', 'Role', {'uid': uid})
			if model['ret'] and len(model['models']) > 0:
				role = model['models'][0]
				if 'robot' not in role['account_id']:
					ret = ObjectSocietyGlobal.onRoleInfoByModel(role)
					roles.append(ret)

	if roleName:
		ret = ObjectSocietyGlobal.getFriendsByName(roleName)
		if ret:
			ret = filter(lambda x: x['uid'] != uid, ret)
			roles.extend(ret)
		else:
			models = yield dbc.call_async('DBReadByPattern', 'Role', {'name': {'pattern': roleName}}, FriendListMax)
			if models['ret']:
				ret = [ObjectSocietyGlobal.onRoleInfoByModel(model) for model in models['models'] if 'robot' not in model['account_id']]
				ret = filter(lambda x: x['uid'] != uid, ret)
				roles.extend(ret)

	if not roles:
		raise ClientError(ErrDefs.friendSearchNoSuchRole)
	raise Return(roles)

# 搜索申请好友
class SocietyFriendSearch(RequestHandlerTask):
	url = r'/game/society/friend/search'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		roleName = self.input.get('roleName', None)
		roleIDs = self.input.get('roleIDs', None)
		uid = self.input.get('uid', None)

		if roleID is None and roleName is None and roleIDs is None and uid is None:
			raise ClientError('param is miss')

		if roleIDs:
			roles = []
			for roleID in roleIDs:
				if roleID == self.game.role.id:
					continue

				role = yield getSocietyRole(self.dbcGame, roleID=roleID)
				roles += role

			self.write({'view': {
				'roles': roles,
				'size': len(roles),
			}})

		else:
			if roleID and roleID == self.game.role.id:
				raise ClientError(ErrDefs.friendSearchMyself)

			if roleName and roleName == self.game.role.name:
				raise ClientError(ErrDefs.friendSearchMyself)

			if uid and uid == self.game.role.uid:
				raise ClientError(ErrDefs.friendSearchMyself)

			roles = yield getSocietyRole(self.dbcGame, roleID, str(roleName), uid)
			self.write({'view': {
				'roles': roles,
				'size': len(roles),
			}})

# 好友挑战
class SocietyFriendFight(RequestHandlerTask):
	url = r'/game/society/friend/fight'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		recordID = self.input.get('recordID', None)
		gameKey = self.input.get('gameKey', None)  # 跨服挑战时传递目标服务器
		if roleID is None:
			raise ClientError('roleID is miss')
		
		# 跨服挑战不要求 recordID，本服挑战需要 recordID
		from game.server import Server
		myKey = Server.Singleton.key if Server.Singleton else None
		isCross = gameKey and gameKey != myKey
		
		if not isCross and recordID is None:
			raise ClientError('friend not in arena')
		
		# 检查非好友挑战次数（默认5次/天）
		isFriend = roleID in self.game.society.friends
		if not isFriend:
			maxTimes = getattr(ConstDefs, 'notFriendFightLimit', 5)
			if self.game.dailyRecord.not_friend_fight_times >= maxTimes:
				raise ClientError('not_friend_fight_times_limit')

		cards = self.game.role.battle_cards
		cardsD, cardsD2 = self.game.cards.makeBattleCardModel(cards, SceneDefs.Arena)
		embattle = {
			'cards': cards,
			'card_attrs': cardsD,
			'card_attrs2': cardsD2,
		}
		
		# 为助战卡牌生成属性，合并到 card_attrs 中
		role = self.game.role
		aid_cards_dict = self.game.role.battle_aid_cards or {}
		aid_cards_list = aid_cards_dict.values() if isinstance(aid_cards_dict, dict) else aid_cards_dict
		if aid_cards_list and len(filter(None, aid_cards_list)) > 0:
			aid_attrs, aid_attrs2 = self.game.cards.makeBattleCardModel(aid_cards_list, SceneDefs.Arena, is_aid=True)
			embattle['card_attrs'].update(aid_attrs)
			embattle['card_attrs2'].update(aid_attrs2)
		embattle['aid_cards'] = aid_cards_dict
		
		# 添加天气数据
		battle_extra = self.game.role.battle_extra or {}
		embattle['extra'] = {'weather': battle_extra.get('weather', 0), 'arms': battle_extra.get('arms', [])}

		if isCross:
			# 跨服挑战：用 roleID 直接获取对方的竞技场记录（优化版）
			model = yield self._crossFriendFight(gameKey, role, embattle, roleID)
		else:
			# 本服挑战
			model = yield self.rpcArena.call_async('FriendFight', role.competitor, embattle, roleID, recordID, myKey)
		
		if not model:
			raise ClientError('cross_fight_error')
		
		# 增加非好友挑战次数
		if not isFriend:
			self.game.dailyRecord.not_friend_fight_times += 1
		
		self.write({
			'model': {
				'qiecuo': model,
			}
		})

	@coroutine
	def _crossFriendFight(self, gameKey, role, embattle, enemyRoleID):
		'''跨服好友挑战（优化版：直接用 roleID 获取竞技场记录）'''
		from game.server import Server
		from framework.helper import objectid2string
		from framework.log import logger

		model = None
		try:
			container = Server.Singleton.container
			myGameKey = Server.Singleton.key  # 我方服务器标识
			
			# 1. 从目标服务器用 roleID 获取竞技场记录
			targetClient = container.getserviceOrCreate(gameKey)
			if not targetClient:
				logger.warning('_crossFriendFight: target client is None for gameKey=%s', gameKey)
				raise Return(None)
			
			enemyRecord = yield targetClient.call_async('CrossGetArenaRecordByRoleID', objectid2string(enemyRoleID))
			if not enemyRecord:
				logger.warning('_crossFriendFight: enemyRecord is None for roleID=%s on gameKey=%s', enemyRoleID, gameKey)
				raise Return(None)
			
			# 2. 使用跨服数据进行战斗，传递双方的 gameKey
			model = yield self.rpcArena.call_async('FriendFightWithData', role.competitor, embattle, enemyRecord, myGameKey, gameKey)
		except Return:
			raise
		except Exception as e:
			logger.warning('_crossFriendFight error: %s', e)
		
		raise Return(model)

# 加入黑名单
class SocietyAddBlackList(RequestHandlerTask):
	url = r'/game/society/blacklist/add'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)

		if roleID is None:
			raise ClientError('roleID is miss')

		if roleID == self.game.role.id:
			raise ClientError('cant add self')

		if roleID in self.game.society.black_list:
			raise ClientError(ErrDefs.societyBlackListHasAdd)

		self.game.society.black_list.append(roleID)

# 从黑名单中移除
class SocietyRemoveBlackList(RequestHandlerTask):
	url = r'/game/society/blacklist/remove'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)

		if roleID is None:
			raise ClientError('roleID is miss')

		if roleID not in self.game.society.black_list:
			raise ClientError(ErrDefs.societyBlackListNoThis)

		self.game.society.black_list.remove(roleID)


# 获取跨服黑名单角色信息
class SocietyCrossBlackList(RequestHandlerTask):
	url = r'/game/society/cross/blacklist'

	@coroutine
	def run(self):
		from game.server import Server
		from framework.helper import objectid2string
		from game.object.game.cache import ObjectCacheGlobal
		from game.object.game.union import ObjectUnion
		from nsqrpc.error import CallError

		cross_black_list = self.game.society.cross_black_list or []
		roles = []
		myKey = Server.Singleton.key if Server.Singleton else None

		for item in cross_black_list:
			if len(item) >= 2:
				gameKey = item[0]
				roleID = item[1]
				try:
					roleInfo = None
					if gameKey == myKey:
						# 本服查询：直接从本地缓存获取
						roleInfo = yield ObjectCacheGlobal.queryRole(roleID)
						if roleInfo:
							roleInfo['union_name'] = ObjectUnion.queryUnionName(roleID)
					else:
						# 跨服获取角色信息（roleID 需要转换为字符串）
						container = Server.Singleton.container
						client = container.getserviceOrCreate(gameKey)
						if client:
							roleIDStr = objectid2string(roleID) if hasattr(roleID, '__str__') else str(roleID)
							roleInfo = yield client.call_async('CrossGetRoleInfo', roleIDStr)
					
					if roleInfo:
						roleInfo['isCrossRole'] = True
						roleInfo['game_key'] = gameKey
						roles.append(roleInfo)
				except CallError as e:
					logger.warning('SocietyCrossBlackList RPC error: %s', e)
				except Exception as e:
					logger.warning('SocietyCrossBlackList get role info error: %s', e)

		self.write({
			'view': {
				'roles': roles,
			}
		})


# 加入跨服黑名单
class SocietyCrossAddBlackList(RequestHandlerTask):
	url = r'/game/society/cross/blacklist/add'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)
		gameKey = self.input.get('gameKey', None)

		if roleID is None:
			raise ClientError('roleID is miss')
		if gameKey is None:
			raise ClientError('gameKey is miss')

		if roleID == self.game.role.id:
			raise ClientError('cant add self')

		# 检查是否已在跨服黑名单中
		cross_black_list = self.game.society.cross_black_list or []
		for item in cross_black_list:
			if len(item) >= 2 and item[1] == roleID:
				raise ClientError(ErrDefs.societyBlackListHasAdd)

		cross_black_list.append([gameKey, roleID])
		self.game.society.cross_black_list = cross_black_list


# 从跨服黑名单中移除
class SocietyCrossRemoveBlackList(RequestHandlerTask):
	url = r'/game/society/cross/blacklist/remove'

	@coroutine
	def run(self):
		roleID = self.input.get('roleID', None)

		if roleID is None:
			raise ClientError('roleID is miss')

		cross_black_list = self.game.society.cross_black_list or []
		found = False
		for item in cross_black_list:
			if len(item) >= 2 and item[1] == roleID:
				cross_black_list.remove(item)
				found = True
				break

		if not found:
			raise ClientError(ErrDefs.societyBlackListNoThis)

		self.game.society.cross_black_list = cross_black_list