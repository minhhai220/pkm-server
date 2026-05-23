#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2017 TianJi Information Technology Inc.

【转区逻辑】GM后台管理 - 转区记录查询、手动执行、状态监控
'''
from __future__ import absolute_import

from .base import AuthedHandler
from tornado.gen import coroutine
import pymongo
from bson import ObjectId
import time
import logging

logger = logging.getLogger('gm.cn.1')


# 转区管理页面
class TransferManageHandler(AuthedHandler):
    url = r'/transfer'

    @coroutine
    def get(self):
        try:
            # 提取区号列表
            areas = []
            serv_list = getattr(self, 'servsList', [])
            
            for serv in serv_list:
                if '.' in serv:
                    area = serv.split('.')[-1]
                    try:
                        areas.append(int(area))
                    except:
                        pass
            
            if not areas:
                # 默认区号
                areas = [1, 2, 3, 4, 5, 6, 7, 8, 9]
            else:
                areas = sorted(set(areas))
            
            # 游戏数据库列表
            if serv_list:
                game_dbs = sorted(set(serv_list))
            else:
                # 默认数据库列表
                game_dbs = ['game.cn.1', 'game.cn.2', 'game.cn.3']
            
            # dashboard.html 需要的 overview 变量（4个元素）
            overview = [0, 0, 0, 0]  # [激活数, 签到数, 充值数, 充值额] - 转区页面不需要，传空值
            
            self.render_page("_transfer.html", areas=areas, game_dbs=game_dbs, overview=overview)
        except Exception as e:
            import traceback
            self.write('<h1>Error</h1><pre>%s</pre>' % traceback.format_exc())


# 查询转区记录列表
class TransferListHandler(AuthedHandler):
    url = r'/transfer/list'

    @coroutine
    def get(self):
        """
        查询转区记录
        
        参数：
            game_db: 游戏数据库key（如 game.cn.1）
            mongo_uri_tpl: MongoDB URI 模板（包含 {dbname} 占位符）
            status: 状态筛选（可选）
            source_area: 源区筛选（可选）
            target_area: 目标区筛选（可选）
        """
        game_db = self.get_argument("game_db", None)
        mongo_uri_tpl = self.get_argument("mongo_uri_tpl", None)
        status = self.get_argument("status", None)
        source_area = self.get_argument("source_area", None)
        target_area = self.get_argument("target_area", None)
        
        if not game_db:
            self.write({'success': False, 'error': '请选择游戏数据库', 'records': []})
            return
        
        if not mongo_uri_tpl:
            self.write({'success': False, 'error': '请配置 MongoDB URI 模板', 'records': []})
            return
        
        # 从模板生成 URI
        db_name = game_db.replace(".", "_")  # game.cn.1 -> game_cn_1
        game_db_uri = mongo_uri_tpl.replace("{dbname}", db_name)
        
        try:
            # 连接游戏数据库
            client = pymongo.MongoClient(game_db_uri, serverSelectionTimeoutMS=5000)
            collection = client[db_name]['TransferRecord']
            
            # 构建查询条件
            query = {}
            if status:
                query['status'] = status
            if source_area:
                query['source_area'] = int(source_area)
            if target_area:
                query['target_area'] = int(target_area)
            
            # 查询记录
            records = []
            cursor = collection.find(query).sort('apply_time', -1).limit(100)
            for doc in cursor:
                doc['_id'] = str(doc['_id'])
                if 'role_db_id' in doc:
                    doc['role_db_id'] = str(doc['role_db_id'])
                if 'target_role_db_id' in doc:
                    doc['target_role_db_id'] = str(doc['target_role_db_id'])
                if 'account_id' in doc:
                    doc['account_id'] = str(doc['account_id'])
                if 'invite_id' in doc and doc['invite_id']:
                    doc['invite_id'] = str(doc['invite_id'])
                # deleted_role_info 中的 role_db_id 也需要转换
                if 'deleted_role_info' in doc and doc['deleted_role_info']:
                    if 'role_db_id' in doc['deleted_role_info']:
                        doc['deleted_role_info']['role_db_id'] = str(doc['deleted_role_info']['role_db_id'])
                records.append(doc)
            
            # 统计
            stats = {
                'pending': collection.count_documents({'status': 'pending'}),
                'processing': collection.count_documents({'status': 'processing'}),
                'completed': collection.count_documents({'status': 'completed'}),
                'failed': collection.count_documents({'status': 'failed'})
            }
            
            client.close()
            
            self.write({'success': True, 'records': records, 'stats': stats})
            
        except Exception as e:
            self.write({'success': False, 'error': str(e), 'records': []})


# 退费操作
class TransferRefundHandler(AuthedHandler):
    url = r'/transfer/refund'

    @coroutine
    def post(self):
        """
        对失败的转区记录进行退费
        通过邮件发送退费物品给玩家
        """
        record_id = self.get_argument("record_id", None)
        game_db = self.get_argument("game_db", None)
        mongo_uri_tpl = self.get_argument("mongo_uri_tpl", None)
        
        if not record_id or not game_db or not mongo_uri_tpl:
            self.write({'success': False, 'error': '参数不完整'})
            return
        
        db_name = game_db.replace(".", "_")
        game_db_uri = mongo_uri_tpl.replace("{dbname}", db_name)
        
        logger.info('[Refund] 开始退费: record_id=%s, game_db=%s', record_id, game_db)
        
        try:
            client = pymongo.MongoClient(game_db_uri, serverSelectionTimeoutMS=5000)
            db = client[db_name]
            
            # 查询记录
            record = db.TransferRecord.find_one({'_id': ObjectId(record_id)})
            if not record:
                logger.warning('[Refund] 记录不存在: %s', record_id)
                self.write({'success': False, 'error': '记录不存在'})
                client.close()
                return
            
            logger.info('[Refund] 找到记录: uid=%s, role_name=%s, status=%s', 
                       record.get('uid'), record.get('role_name'), record.get('status'))
            
            if record.get('status') != 'failed':
                logger.warning('[Refund] 状态不是 failed: %s', record.get('status'))
                self.write({'success': False, 'error': '只能对失败的记录退费'})
                client.close()
                return
            
            if record.get('refunded'):
                logger.warning('[Refund] 已经退费过了')
                self.write({'success': False, 'error': '已经退费过了'})
                client.close()
                return
            
            cost_info = record.get('cost_info')
            if not cost_info:
                logger.warning('[Refund] 没有费用信息')
                self.write({'success': False, 'error': '没有费用信息'})
                client.close()
                return
            
            logger.info('[Refund] 费用信息: %s', cost_info)
            
            role_id = record.get('role_db_id')
            if not role_id:
                logger.warning('[Refund] 没有角色ID')
                self.write({'success': False, 'error': '没有角色ID'})
                client.close()
                return
            
            # 确保 role_id 是 ObjectId 类型
            if not isinstance(role_id, ObjectId):
                logger.info('[Refund] 转换 role_id: %s -> ObjectId', role_id)
                role_id = ObjectId(role_id)
            
            # 获取源区数据库（TransferRecord 存在源区）
            source_area = record.get('source_area')
            source_db_name = 'game_cn_%s' % source_area
            source_db_uri = mongo_uri_tpl.replace("{dbname}", source_db_name)
            
            logger.info('[Refund] 解封角色: source_area=%s, role_id=%s', source_area, role_id)
            
            # 1. 通过 RPC 解封源区角色（关键！这样会同步 Go 端缓存）
            # 注意：RPC 需要传 bytes 类型，不能传 ObjectId
            role_id_bytes = bytes(role_id.binary)
            source_serv_name = 'game.cn.%s' % source_area
            try:
                ret = yield self.userGMRPC.gmRoleAbandon(self.session, source_serv_name, role_id_bytes, 'disable', False)
                logger.info('[Refund] RPC 解封结果: %s', ret)
            except Exception as rpc_err:
                logger.error('[Refund] RPC 解封失败: %s, 尝试直接更新数据库', rpc_err)
                # 降级方案：直接更新数据库
                source_client = pymongo.MongoClient(source_db_uri, serverSelectionTimeoutMS=5000)
                source_db = source_client[source_db_name]
                source_db.Role.update_one(
                    {'_id': role_id},
                    {'$set': {'disable_flag': False}}
                )
                source_client.close()
            
            # 2. 通过 RPC 发送退费邮件（这样邮件会正确同步到玩家邮箱）
            logger.info('[Refund] 发送退费邮件: serv=%s, role_id=%s', source_serv_name, role_id)
            try:
                mail_ret = yield self.userGMRPC.gmSendMail(
                    self.session, 
                    source_serv_name,  # 'game.cn.3'
                    role_id_bytes,  # bytes 类型
                    1,  # mailType (CSV ID)
                    '系统',  # sender
                    '转区退费',  # subject
                    '您的转区申请失败，现退还转区费用。如有疑问请联系客服。',  # content
                    cost_info  # attachs
                )
                logger.info('[Refund] 邮件发送结果: %s', mail_ret)
            except Exception as mail_err:
                logger.error('[Refund] RPC 发送邮件失败: %s, 尝试直接插入数据库', mail_err)
                # 降级方案：直接插入数据库
                source_client = pymongo.MongoClient(source_db_uri, serverSelectionTimeoutMS=5000)
                source_db = source_client[source_db_name]
                mail_data = {
                    'role_db_id': role_id,
                    'type': 1,
                    'sender': '系统',
                    'subject': '转区退费',
                    'content': '您的转区申请失败，现退还转区费用。如有疑问请联系客服。',
                    'attachs': cost_info,
                    'time': time.time(),
                    'deleted_flag': False
                }
                source_db.Mail.insert_one(mail_data)
                source_client.close()
            
            # 3. 标记已退费（在 TransferRecord 所在的数据库）
            db.TransferRecord.update_one(
                {'_id': ObjectId(record_id)},
                {'$set': {'refunded': True, 'refund_time': int(time.time())}}
            )
            logger.info('[Refund] 标记已退费完成')
            
            client.close()
            logger.info('[Refund] 退费成功: record_id=%s', record_id)
            self.write({'success': True, 'message': '退费成功，角色已解封'})
            
        except Exception as e:
            logger.error('[Refund] 退费异常: %s', e, exc_info=True)
            self.write({'success': False, 'error': str(e)})


# 重试转区
class TransferRetryHandler(AuthedHandler):
    url = r'/transfer/retry'

    @coroutine
    def post(self):
        """
        重试失败的转区
        重置状态为 pending，让 daemon 重新执行
        """
        record_id = self.get_argument("record_id", None)
        game_db = self.get_argument("game_db", None)
        mongo_uri_tpl = self.get_argument("mongo_uri_tpl", None)
        
        if not record_id or not game_db or not mongo_uri_tpl:
            self.write({'success': False, 'error': '参数不完整'})
            return
        
        logger.info('[Retry] 开始重试: record_id=%s, game_db=%s', record_id, game_db)
        
        db_name = game_db.replace(".", "_")
        game_db_uri = mongo_uri_tpl.replace("{dbname}", db_name)
        
        try:
            client = pymongo.MongoClient(game_db_uri, serverSelectionTimeoutMS=5000)
            db = client[db_name]
            
            # 查询记录
            record = db.TransferRecord.find_one({'_id': ObjectId(record_id)})
            if not record:
                logger.warning('[Retry] 记录不存在: %s', record_id)
                self.write({'success': False, 'error': '记录不存在'})
                client.close()
                return
            
            logger.info('[Retry] 找到记录: uid=%s, role_name=%s, status=%s', 
                       record.get('uid'), record.get('role_name'), record.get('status'))
            
            if record.get('status') != 'failed':
                logger.warning('[Retry] 状态不是 failed: %s', record.get('status'))
                self.write({'success': False, 'error': '只能重试失败的记录'})
                client.close()
                return
            
            # 获取角色信息
            role_id = record.get('role_db_id')
            source_area = record.get('source_area')
            
            # 【重要】先封号（重新走转区流程）
            if role_id and source_area:
                # 确保 role_id 是 ObjectId 类型
                if not isinstance(role_id, ObjectId):
                    logger.info('[Retry] 转换 role_id: %s -> ObjectId', role_id)
                    role_id = ObjectId(role_id)
                
                # 注意：RPC 需要传 bytes 类型，不能传 ObjectId
                role_id_bytes = bytes(role_id.binary)
                source_serv_name = 'game.cn.%s' % source_area
                try:
                    # 封号：disable=True
                    ret = yield self.userGMRPC.gmRoleAbandon(self.session, source_serv_name, role_id_bytes, 'disable', True)
                    logger.info('[Retry] RPC 封号结果: %s', ret)
                except Exception as rpc_err:
                    logger.error('[Retry] RPC 封号失败: %s, 尝试直接更新数据库', rpc_err)
                    # 获取源区数据库
                    source_db_name = 'game_cn_%s' % source_area
                    source_db_uri = mongo_uri_tpl.replace("{dbname}", source_db_name)
                    source_client = pymongo.MongoClient(source_db_uri, serverSelectionTimeoutMS=5000)
                    source_db = source_client[source_db_name]
                    source_db.Role.update_one(
                        {'_id': role_id},
                        {'$set': {'disable_flag': True}}
                    )
                    source_client.close()
            
            # 重置状态（清除退费标记，重新执行）
            db.TransferRecord.update_one(
                {'_id': ObjectId(record_id)},
                {'$set': {
                    'status': 'pending',
                    'execute_time': int(time.time()) + 60,  # 1分钟后执行
                    'progress': 0,
                    'progress_msg': '等待重试',
                    'fail_reason': None,
                    'complete_time': None,
                    'start_time': None,
                    'refunded': False,  # 清除退费标记
                    'refund_time': None,
                    'auto_refunded': False  # 清除自动退费标记
                }}
            )
            logger.info('[Retry] 已重置状态为 pending，角色已封号')
            
            client.close()
            logger.info('[Retry] 重试设置成功: record_id=%s', record_id)
            self.write({'success': True, 'message': '已封号并重置为等待执行'})
            
        except Exception as e:
            logger.error('[Retry] 重试异常: %s', e, exc_info=True)
            self.write({'success': False, 'error': str(e)})


class TransferInviteListHandler(AuthedHandler):
    """邀请记录列表"""
    url = r'/transfer/invite/list'
    
    @coroutine
    def get(self):
        try:
            game_db = self.get_argument('game_db', '')
            mongo_uri_tpl = self.get_argument('mongo_uri_tpl', '')
            
            if not game_db or not mongo_uri_tpl:
                self.write({'success': False, 'error': '缺少参数'})
                return
            
            # 构建数据库名
            db_name = game_db.replace('.', '_')
            mongo_uri = mongo_uri_tpl.replace("{dbname}", db_name)
            
            # 连接数据库
            client = pymongo.MongoClient(mongo_uri, serverSelectionTimeoutMS=5000)
            db = client[db_name]
            
            # 查询邀请记录
            invites = []
            try:
                cursor = db.TransferInvite.find().sort('create_time', -1).limit(100)
                for doc in cursor:
                    invites.append({
                        '_id': str(doc.get('_id')),
                        'inviter_role_id': str(doc.get('inviter_role_id', '')),
                        'inviter_name': doc.get('inviter_name', ''),
                        'inviter_union_id': str(doc.get('inviter_union_id', '')),
                        'inviter_union_name': doc.get('inviter_union_name', ''),
                        'invitee_uid': doc.get('invitee_uid', 0),
                        'invitee_name': doc.get('invitee_name', ''),
                        'invitee_area': doc.get('invitee_area', 0),
                        'invitee_level': doc.get('invitee_level', 0),
                        'invitee_fighting_point': doc.get('invitee_fighting_point', 0),
                        'target_area': doc.get('target_area', 0),
                        'status': doc.get('status', ''),
                        'create_time': doc.get('create_time', 0),
                        'expire_time': doc.get('expire_time', 0),
                        'respond_time': doc.get('respond_time', 0),
                        'month': doc.get('month', 0),
                        'transfer_record_id': str(doc.get('transfer_record_id', '')) if doc.get('transfer_record_id') else '',
                    })
            except Exception as e:
                # TransferInvite 表可能不存在
                logger.warning('查询 TransferInvite 失败: %s', e)
            
            client.close()
            
            self.write({
                'success': True,
                'invites': invites
            })
            
        except Exception as e:
            logger.error('查询邀请记录异常: %s', e, exc_info=True)
            self.write({'success': False, 'error': str(e)})

