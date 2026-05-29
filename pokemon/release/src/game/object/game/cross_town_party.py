#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
============================================================================
家园派对 (Town Party) - 跨服状态管理
============================================================================
'''

from framework.log import logger
from framework.csv import csv, MergeServ
from framework.object import ObjectNoGCDBase, db_property

from tornado.gen import coroutine, Return


class ObjectCrossTownPartyGlobal(ObjectNoGCDBase):
    '''
    家园派对跨服全局管理
    负责管理派对活动的跨服状态和 RPC 调用
    '''
    DBModel = 'CrossTownPartyGlobal'

    Singleton = None

    GlobalObjsMap = {}  # {areakey: ObjectCrossTownPartyGlobal}

    @classmethod
    def classInit(cls):
        pass

    @classmethod
    def getByAreaKey(cls, key):
        return cls.GlobalObjsMap.get(key, cls.Singleton)

    def __init__(self, dbc):
        ObjectNoGCDBase.__init__(self, None, dbc)

    def set(self, dic):
        ObjectNoGCDBase.set(self, dic)
        return self

    def init(self, server, crossData):
        self.server = server
        self._cross = {}

        self.initCrossData(crossData)

        cls = ObjectCrossTownPartyGlobal
        cls.GlobalObjsMap[self.key] = self
        # global对象 key与当前服key对应
        if self.key == self.server.key:
            cls.Singleton = self

        return self

    def initCrossData(self, crossData):
        '''初始化跨服数据'''
        if crossData:
            self._cross = crossData
            self.cross_key = crossData.get('cross_key', '')
            self.round = crossData.get('round', 'closed')
            self.date = crossData.get('date', 0)
            self.end_date = crossData.get('end_date', 0)
            logger.info('ObjectCrossTownPartyGlobal.initCrossData key=%s cross_key=%s round=%s',
                       self.key, self.cross_key, self.round)

    # key
    key = db_property('key')

    # 跨服server key
    cross_key = db_property('cross_key')

    # 赛季状态
    round = db_property('round')

    # 开始日期
    date = db_property('date')

    # 结束日期
    end_date = db_property('end_date')

    @classmethod
    def isOpen(cls, areaKey=None):
        '''
        是否开启派对玩法
        '''
        if areaKey:
            self = cls.getByAreaKey(areaKey)
        else:
            self = cls.Singleton
        if self is None or self.cross_key == '' or self.round == "closed":
            return False
        return True

    @classmethod
    def getRound(cls, areaKey=None):
        if areaKey:
            self = cls.getByAreaKey(areaKey)
        else:
            self = cls.Singleton
        if self is None:
            return 'closed'
        return self.round

    @classmethod
    def getCrossKey(cls, areaKey=None):
        if areaKey:
            self = cls.getByAreaKey(areaKey)
        else:
            self = cls.Singleton
        if self is None:
            return ''
        return self.cross_key

    @classmethod
    def getCrossClient(cls, areaKey=None):
        '''获取跨服服务客户端
        注意：活动关闭时 cross_key 会被保留，跨服访问功能仍可使用
        '''
        cross_key = cls.getCrossKey(areaKey)
        logger.info('ObjectCrossTownPartyGlobal.getCrossClient: cross_key=%s, Singleton=%s', 
                   cross_key, cls.Singleton)
        if not cross_key:
            # 没有配置 cross_key，说明 match 服务还没有分配跨服（首次启动时可能发生）
            logger.warning('ObjectCrossTownPartyGlobal.getCrossClient: cross_key is empty')
            return None
        from game.server import Server
        container = Server.Singleton.container
        client = container.getserviceOrCreate(cross_key)
        logger.info('ObjectCrossTownPartyGlobal.getCrossClient: got client for %s', cross_key)
        return client

    # ============================================================================
    # 跨服 RPC 调用
    # ============================================================================

    @classmethod
    @coroutine
    def createRoom(cls, ownerID, ownerKey, ownerName, partyCsvID, partyName, figure, logo, frame, level, vip):
        '''创建派对房间'''
        client = cls.getCrossClient()
        if not client:
            logger.warning('ObjectCrossTownPartyGlobal.createRoom: no cross client')
            raise Return(None)

        try:
            result = yield client.call_async('PartyRoomCreate', ownerID, ownerKey, ownerName, partyCsvID, partyName, figure, logo, frame, level, vip)
            logger.info('ObjectCrossTownPartyGlobal.createRoom: result=%s', result)
        except Exception as e:
            logger.error('ObjectCrossTownPartyGlobal.createRoom error: %s', e)
            raise Return(None)
        raise Return(result)

    @classmethod
    @coroutine
    def joinRoom(cls, roomUid, roleID, roleName, serverKey, figure, logo, frame, level, vip):
        '''加入派对房间'''
        client = cls.getCrossClient()
        if not client:
            logger.warning('ObjectCrossTownPartyGlobal.joinRoom: no cross client')
            raise Return(None)

        try:
            result = yield client.call_async('PartyRoomJoin', roomUid, roleID, roleName, serverKey, figure, logo, frame, level, vip)
            logger.info('ObjectCrossTownPartyGlobal.joinRoom: roomUid=%s result=%s', roomUid, result)
        except Exception as e:
            logger.error('ObjectCrossTownPartyGlobal.joinRoom error: %s', e)
            raise Return(None)
        raise Return(result)

    @classmethod
    @coroutine
    def leaveRoom(cls, roomUid, roleID):
        '''离开派对房间'''
        client = cls.getCrossClient()
        if not client:
            return

        try:
            yield client.call_async('PartyRoomLeave', roomUid, roleID)
            logger.info('ObjectCrossTownPartyGlobal.leaveRoom: roomUid=%s roleID=%s', roomUid, roleID)
        except Exception as e:
            logger.error('ObjectCrossTownPartyGlobal.leaveRoom error: %s', e)

    @classmethod
    @coroutine
    def getRoom(cls, roomUid):
        '''获取派对房间信息'''
        client = cls.getCrossClient()
        if not client:
            raise Return(None)

        try:
            result = yield client.call_async('PartyRoomGet', roomUid)
        except Exception as e:
            logger.error('ObjectCrossTownPartyGlobal.getRoom error: %s', e)
            raise Return(None)
        raise Return(result)

    @classmethod
    @coroutine
    def listRooms(cls, size=20):
        '''获取派对房间列表'''
        client = cls.getCrossClient()
        if not client:
            raise Return([])

        try:
            result = yield client.call_async('PartyRoomList', size)
        except Exception as e:
            logger.error('ObjectCrossTownPartyGlobal.listRooms error: %s', e)
            raise Return([])
        raise Return(result or [])

    @classmethod
    @coroutine
    def findRoom(cls, roomUid, partyCsvID=0):
        '''查找派对房间'''
        client = cls.getCrossClient()
        if not client:
            raise Return(None)

        try:
            result = yield client.call_async('PartyRoomFind', roomUid, partyCsvID)
        except Exception as e:
            logger.error('ObjectCrossTownPartyGlobal.findRoom error: %s', e)
            raise Return(None)
        raise Return(result)

    @classmethod
    @coroutine
    def findRoomByRoomId(cls, roomId):
        '''通过6位房间号查找派对房间'''
        client = cls.getCrossClient()
        if not client:
            raise Return(None)

        try:
            result = yield client.call_async('PartyRoomFindByRoomId', roomId)
        except Exception as e:
            logger.error('ObjectCrossTownPartyGlobal.findRoomByRoomId error: %s', e)
            raise Return(None)
        raise Return(result)

    @classmethod
    @coroutine
    def sendQifen(cls, roomUid, senderID, senderName, qifenID, content=''):
        '''发送气氛互动'''
        client = cls.getCrossClient()
        if not client:
            return

        try:
            yield client.call_async('PartyRoomQifen', roomUid, senderID, senderName, qifenID, content)
            logger.info('ObjectCrossTownPartyGlobal.sendQifen: roomUid=%s qifenID=%s', roomUid, qifenID)
        except Exception as e:
            logger.error('ObjectCrossTownPartyGlobal.sendQifen error: %s', e)

    @classmethod
    @coroutine
    def updateRecoverUsed(cls, roomUid, roleID, recoverUsed, recoverCards):
        '''更新玩家的恢复使用状态'''
        client = cls.getCrossClient()
        if not client:
            logger.warning('ObjectCrossTownPartyGlobal.updateRecoverUsed: no cross client')
            raise Return(False)

        try:
            result = yield client.call_async('PartyUpdateRecoverUsed', roomUid, roleID, recoverUsed, recoverCards)
            logger.info('ObjectCrossTownPartyGlobal.updateRecoverUsed: roomUid=%s roleID=%s recoverUsed=%s result=%s', 
                        roomUid, roleID, recoverUsed, result)
        except Exception as e:
            logger.error('ObjectCrossTownPartyGlobal.updateRecoverUsed error: %s', e)
            raise Return(False)
        raise Return(result)

    @classmethod
    @coroutine
    def endDart(cls, roomUid, roleID, dartUseNum, gameCount, score, evaluate):
        '''飞镖游戏结束，更新飞镖数据'''
        client = cls.getCrossClient()
        if not client:
            logger.warning('ObjectCrossTownPartyGlobal.endDart: no cross client')
            raise Return(False)

        try:
            result = yield client.call_async('DartEnd', roomUid, roleID, dartUseNum, gameCount, score, evaluate)
            logger.info('ObjectCrossTownPartyGlobal.endDart: roomUid=%s roleID=%s result=%s', roomUid, roleID, result)
        except Exception as e:
            logger.error('ObjectCrossTownPartyGlobal.endDart error: %s', e)
            raise Return(False)
        raise Return(result)

    # ============================================================================
    # 跨服事件处理
    # ============================================================================

    @classmethod
    @coroutine
    def onCrossEvent(cls, event, key, data, sync):
        '''
        跨服事件处理
        '''
        logger.info('ObjectCrossTownPartyGlobal.onCrossEvent event=%s key=%s', event, key)

        self = cls.getByAreaKey(key)
        if self is None:
            logger.warning('ObjectCrossTownPartyGlobal.onCrossEvent: no global obj for key=%s', key)
            raise Return({})

        if event == 'start':
            # 活动开始
            self.round = 'start'
            self._cross = data
            self.cross_key = data.get('cross_key', '')
            logger.info('ObjectCrossTownPartyGlobal: party started, cross_key=%s', self.cross_key)

        elif event == 'closed':
            # 活动结束 - 保留 cross_key 供跨服访问功能使用
            self.round = 'closed'
            # 不清空 cross_key，跨服访问功能需要用它
            # self.cross_key = ''
            logger.info('ObjectCrossTownPartyGlobal: party closed, keeping cross_key=%s for visit', self.cross_key)

        raise Return({})

    @classmethod
    @coroutine
    def onCrossCommit(cls, key, transaction):
        '''
        跨服事务提交 - 设置 cross_key 启用跨服派对
        '''
        logger.info('ObjectCrossTownPartyGlobal.onCrossCommit key=%s transaction=%s', key, transaction)

        self = cls.Singleton
        if self is None:
            logger.warning('ObjectCrossTownPartyGlobal.onCrossCommit: Singleton is None')
            raise Return(False)

        # 检查是否已被其他跨服服务占用
        if self.cross_key != '' and self.cross_key != key:
            logger.warning('ObjectCrossTownPartyGlobal.onCrossCommit: already occupied by %s', self.cross_key)
            raise Return(False)

        # 设置跨服服务 key，启用跨服功能
        self.cross_key = key
        self.round = 'start'
        
        # 同步到 servrecord，让前端知道活动已开启
        from game.object.game.servrecord import ObjectServerGlobalRecord
        from framework import nowtime_t
        ObjectServerGlobalRecord.town_party_round = 'start'
        # 更新 last_time 触发前端同步
        ObjectServerGlobalRecord.Singleton.last_time = nowtime_t()
        
        logger.info('ObjectCrossTownPartyGlobal.onCrossCommit: cross_key set to %s, round=%s, synced to servrecord', key, self.round)
        raise Return(True)

    # ============================================================================
    # 跨服拜访系统
    # ============================================================================

    @classmethod
    @coroutine
    def visitUpdatePlayer(cls, gameKey, roleID, name, level, vipLevel, logo, frame, figure, townDbId, homeScore, homeLiked, visitData=None):
        '''更新玩家的家园信息（用于跨服推荐列表和跨服拜访）'''
        client = cls.getCrossClient()
        if not client:
            logger.warning('ObjectCrossTownPartyGlobal.visitUpdatePlayer: no cross client')
            raise Return(False)

        try:
            # visitData 是 msgpack 序列化的家园布局数据
            result = yield client.call_async('VisitUpdatePlayer', gameKey, roleID, name, level, vipLevel, logo, frame, figure, townDbId, homeScore, homeLiked, visitData or b'')
            logger.info('ObjectCrossTownPartyGlobal.visitUpdatePlayer: gameKey=%s roleID=%s visitDataLen=%s result=%s', 
                        gameKey, roleID, len(visitData) if visitData else 0, result)
        except Exception as e:
            logger.error('ObjectCrossTownPartyGlobal.visitUpdatePlayer error: %s', e)
            raise Return(False)
        raise Return(result)

    @classmethod
    @coroutine
    def visitGetPlayerList(cls, requestGameKey, typ, size):
        '''获取跨服玩家列表（用于推荐）'''
        client = cls.getCrossClient()
        if not client:
            logger.warning('ObjectCrossTownPartyGlobal.visitGetPlayerList: no cross client')
            raise Return([])

        try:
            result = yield client.call_async('VisitGetPlayerList', requestGameKey, typ, size)
            logger.info('ObjectCrossTownPartyGlobal.visitGetPlayerList: requestGameKey=%s typ=%s size=%s result_count=%s', 
                        requestGameKey, typ, size, len(result) if result else 0)
        except Exception as e:
            logger.error('ObjectCrossTownPartyGlobal.visitGetPlayerList error: %s', e)
            raise Return([])
        raise Return(result or [])

    @classmethod
    @coroutine
    def visitRemovePlayer(cls, gameKey, roleID):
        '''移除玩家的家园信息'''
        client = cls.getCrossClient()
        if not client:
            logger.warning('ObjectCrossTownPartyGlobal.visitRemovePlayer: no cross client')
            raise Return(False)

        try:
            result = yield client.call_async('VisitRemovePlayer', gameKey, roleID)
            logger.info('ObjectCrossTownPartyGlobal.visitRemovePlayer: gameKey=%s roleID=%s result=%s', gameKey, roleID, result)
        except Exception as e:
            logger.error('ObjectCrossTownPartyGlobal.visitRemovePlayer error: %s', e)
            raise Return(False)
        raise Return(result)

    @classmethod
    @coroutine
    def visitHome(cls, targetGameKey, targetRoleID):
        '''获取玩家的家园拜访数据（用于跨服拜访，按 roleID 查找）'''
        client = cls.getCrossClient()
        if not client:
            logger.warning('ObjectCrossTownPartyGlobal.visitHome: no cross client')
            raise Return(None)

        try:
            result = yield client.call_async('VisitHome', targetGameKey, targetRoleID)
            logger.info('ObjectCrossTownPartyGlobal.visitHome: targetGameKey=%s targetRoleID=%s resultLen=%s', 
                        targetGameKey, targetRoleID, len(result) if result else 0)
        except Exception as e:
            logger.error('ObjectCrossTownPartyGlobal.visitHome error: %s', e)
            raise Return(None)
        raise Return(result)

    @classmethod
    @coroutine
    def visitHomeByTownDbId(cls, targetGameKey, townDbId):
        '''获取玩家的家园拜访数据（用于跨服拜访，按 townDbId 查找）'''
        client = cls.getCrossClient()
        if not client:
            logger.warning('ObjectCrossTownPartyGlobal.visitHomeByTownDbId: no cross client')
            raise Return(None)

        try:
            result = yield client.call_async('VisitHomeByTownDbId', targetGameKey, townDbId)
            logger.info('ObjectCrossTownPartyGlobal.visitHomeByTownDbId: targetGameKey=%s townDbId=%s hasResult=%s', 
                        targetGameKey, townDbId, result is not None)
        except Exception as e:
            logger.error('ObjectCrossTownPartyGlobal.visitHomeByTownDbId error: %s', e)
            raise Return(None)
        raise Return(result)

    @classmethod
    @coroutine
    def visitAddEvent(cls, targetGameKey, targetRoleID, eventType, timestamp, visitorGameKey, visitorRoleID, visitorName, visitorFigure, visitorTownDbId, scoreId=0):
        '''添加跨服拜访事件（访问/点赞/评价）
        eventType: 1=访问 2=点赞 3=评价
        '''
        client = cls.getCrossClient()
        if not client:
            logger.warning('ObjectCrossTownPartyGlobal.visitAddEvent: no cross client')
            raise Return(False)

        try:
            result = yield client.call_async('VisitAddEvent', targetGameKey, targetRoleID, eventType, timestamp, 
                                             visitorGameKey, visitorRoleID, visitorName, visitorFigure, visitorTownDbId, scoreId)
            logger.info('ObjectCrossTownPartyGlobal.visitAddEvent: targetGameKey=%s targetRoleID=%s eventType=%s result=%s', 
                        targetGameKey, targetRoleID, eventType, result)
        except Exception as e:
            logger.error('ObjectCrossTownPartyGlobal.visitAddEvent error: %s', e)
            raise Return(False)
        raise Return(result)

    @classmethod
    @coroutine
    def visitGetAndClearEvents(cls, targetGameKey, targetRoleID):
        '''获取并清除某玩家的待同步事件'''
        client = cls.getCrossClient()
        if not client:
            logger.warning('ObjectCrossTownPartyGlobal.visitGetAndClearEvents: no cross client')
            raise Return([])

        try:
            result = yield client.call_async('VisitGetAndClearEvents', targetGameKey, targetRoleID)
            logger.info('ObjectCrossTownPartyGlobal.visitGetAndClearEvents: targetGameKey=%s targetRoleID=%s eventCount=%s', 
                        targetGameKey, targetRoleID, len(result) if result else 0)
        except Exception as e:
            # 活动未开启时会返回 "no active play"，这是正常情况
            if 'no active play' in str(e):
                logger.debug('ObjectCrossTownPartyGlobal.visitGetAndClearEvents: activity not open')
            else:
                logger.warning('ObjectCrossTownPartyGlobal.visitGetAndClearEvents error: %s', e)
            raise Return([])
        raise Return(result or [])
