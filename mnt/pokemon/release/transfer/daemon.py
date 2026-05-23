#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
【转区逻辑】守护进程 - 定时扫描并执行转区任务
'''

import sys
import os
import json
import time
import logging

# 添加项目路径
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(BASE_DIR, 'src'))

import pymongo
import tornado.ioloop
from tornado.gen import coroutine, Return
from service import TransferService

# NSQ RPC 客户端
from framework.service.container import Container
from framework.service.rpc_client import Client as RPCClient

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler(os.path.join(BASE_DIR, 'transfer_daemon.log')),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# 从 storage/defines.json 读取配置
DEFINES_PATH = os.path.join(BASE_DIR, 'storage', 'defines.json')


def load_config():
    """加载配置"""
    with open(DEFINES_PATH, 'r') as f:
        defines = json.load(f)
    
    # 提取 storage 服务
    storages = [k for k in defines.keys() if k.startswith('storage.')]
    logger.info('发现 storage 服务: %s', storages)
    
    return defines, storages


class TransferDaemon(object):
    """转区守护进程"""
    
    def __init__(self):
        self.defines, self.storages = load_config()
        self.mongo_client = None
        self.account_db = None
        self.game_dbs = {}  # {game_key: db}
        self.ioloop = None
        self.container = None
        self.rpc_account = None  # RPC client for accountdb
    
    def init(self):
        """初始化数据库连接"""
        logger.info('初始化转区服务...')
        
        # 获取 MongoDB 连接配置（从第一个 storage 服务提取）
        first_storage = self.storages[0] if self.storages else None
        if not first_storage:
            raise Exception('No storage service found')
        
        storage_cfg = self.defines.get(first_storage, {})
        services = storage_cfg.get('services', [])
        if not services:
            raise Exception('No services found in storage config')
        
        # 从 mongodb URI 提取认证信息
        sample_uri = services[0].get('mongodb', '')
        # mongodb://root:oQTkIlUI5wrOUQEl@127.0.0.1:27017/game_cn_1?authMechanism=SCRAM-SHA-1&authSource=admin
        # 提取基础 URI（不包含数据库名）
        if '@' in sample_uri:
            # 有认证信息
            base_uri = sample_uri.split('?')[0].rsplit('/', 1)[0]  # mongodb://root:pwd@127.0.0.1:27017
            auth_params = sample_uri.split('?')[1] if '?' in sample_uri else ''
        else:
            base_uri = 'mongodb://127.0.0.1:27017'
            auth_params = ''
        
        logger.info('MongoDB Base URI: %s', base_uri.split('@')[-1] if '@' in base_uri else base_uri)
        
        # 连接 MongoDB
        self.mongo_client = pymongo.MongoClient(base_uri)
        
        # 连接 Account 数据库（需要认证）
        account_cfg = self.defines.get('account.cn.1', {})
        account_services = account_cfg.get('services', [])
        if account_services:
            account_uri = account_services[0].get('mongodb', '')
            self.account_client = pymongo.MongoClient(account_uri)
            self.account_db = self.account_client['account']
        else:
            self.account_db = self.mongo_client['account']
        logger.info('连接: account 数据库')
        
        # 连接各个游戏区数据库
        for storage_key in self.storages:
            storage_cfg = self.defines.get(storage_key, {})
            services = storage_cfg.get('services', [])
            if services:
                mongo_uri = services[0].get('mongodb', '')
                db_name = services[0].get('dbname', '')
                game_key = storage_key.replace('storage', 'game')
                
                # 为每个数据库创建独立连接（带认证）
                client = pymongo.MongoClient(mongo_uri)
                self.game_dbs[game_key] = client[db_name]
                logger.info('连接: %s -> %s', game_key, db_name)
        
        logger.info('初始化完成，共 %d 个游戏区', len(self.game_dbs))
        
        # 初始化 NSQ RPC 客户端（用于更新 Account）
        self._init_rpc()
    
    def _init_rpc(self):
        """初始化 RPC 客户端"""
        logger.info('初始化 RPC 客户端...')
        
        # 获取 NSQ 配置
        account_cfg = self.defines.get('account.cn.1', {})
        nsqd = account_cfg.get('nsqd_tcp_addresses', ['127.0.0.1:4150'])
        nsqlookupd = account_cfg.get('nsqlookupd', 'http://127.0.0.1:4161/')
        
        readerdefs = {
            'nsqd_tcp_addresses': nsqd,
            'lookupd_http_addresses': [nsqlookupd.replace('http://', '').rstrip('/')]
        }
        writerdefs = {
            'nsqd_tcp_addresses': nsqd
        }
        
        # 创建 IOLoop 和 Container
        self.ioloop = tornado.ioloop.IOLoop.current()
        self.container = Container('transfer_daemon', readerdefs, writerdefs, self.ioloop)
        
        # 获取 accountdb RPC 客户端
        self.rpc_account = self.container.getserviceOrCreate('accountdb.cn.1')
        
        # 获取各区 game 服务 RPC 客户端（用于清除 session）
        self.rpc_games = {}
        for storage_key in self.storages:
            game_key = storage_key.replace('storage', 'game')
            self.rpc_games[game_key] = self.container.getserviceOrCreate(game_key)
            logger.info('已连接 game 服务: %s', game_key)
        
        # 启动 container
        self.container.start()
        self.container.init()
        
        logger.info('RPC 客户端初始化完成')
    
    def _kick_target_session(self, target_area, account_id):
        """踢掉目标区的旧 session（清除 Python 端 Session 缓存）"""
        from bson import ObjectId
        
        game_key = 'game.cn.%s' % target_area
        rpc_game = self.rpc_games.get(game_key)
        if not rpc_game:
            logger.warning('[Transfer] 未找到 %s 的 RPC 客户端', game_key)
            return False
        
        # 转换 account_id 为 bytes
        def to_bytes(oid):
            if isinstance(oid, ObjectId):
                return bytes(oid.binary)
            elif isinstance(oid, bytes):
                return oid
            elif oid is None:
                return None
            else:
                return bytes(ObjectId(oid).binary)
        
        account_id_bytes = to_bytes(account_id)
        
        @coroutine
        def do_kick():
            try:
                # 调用 game 服务清除 session
                # gmKickPlayerByAccountID 需要 (servID, accountID) 作为 accountKey
                serv_id = int(target_area)
                ret = yield rpc_game.call_async(
                    'gmKickPlayerByAccountID',
                    serv_id,
                    account_id_bytes
                )
                logger.info('[Transfer] Kick target session: area=%s, ret=%s', target_area, ret)
                raise Return(True)
            except Return:
                raise
            except Exception as e:
                logger.warning('[Transfer] Kick target session failed: %s', e)
                raise Return(False)
        
        return self.ioloop.run_sync(do_kick)
    
    def _update_account_rpc(self, account_id, target_area, role_info):
        """通过 RPC 更新 Account.role_infos（同步 Go 端缓存）"""
        from bson import ObjectId
        
        target_key = 'game.cn.%s' % target_area
        
        # 转换 ObjectId 为 bytes（Go 端的 document.ID）
        def to_bytes(oid):
            if isinstance(oid, ObjectId):
                return bytes(oid.binary)
            elif isinstance(oid, bytes):
                return oid
            elif oid is None:
                return None
            else:
                return bytes(ObjectId(oid).binary)
        
        # 转换 account_id 和 role_info['id']
        account_id_bytes = to_bytes(account_id)
        role_info_converted = {
            'id': to_bytes(role_info.get('id')),
            'name': role_info.get('name', ''),
            'level': role_info.get('level', 1),
            'logo': role_info.get('logo', 1),
            'vip': role_info.get('vip', 0),
            'frame': role_info.get('frame', 1),
        }
        
        @coroutine
        def do_update():
            try:
                # 调用 AccountRoleCheckIn 更新 role_infos
                ret = yield self.rpc_account.call_async(
                    'AccountRoleCheckIn',
                    account_id_bytes,
                    target_key,
                    role_info_converted
                )
                logger.info('[Transfer] Account RPC update: %s -> %s, ret=%s', 
                           repr(account_id), target_key, ret.get('ret') if ret else None)
                raise Return(True)
            except Return:
                # Return 是协程返回值，重新抛出
                raise
            except Exception as e:
                logger.error('[Transfer] Account RPC update failed: %s', e)
                raise Return(False)
        
        return self.ioloop.run_sync(do_update)
    
    def _unlock_role_rpc(self, source_area, role_id):
        """通过 RPC 解封角色（同步 Go 端缓存）"""
        from bson import ObjectId
        
        logger.info('[Transfer] 开始 RPC 解封: area=%s, role=%s', source_area, repr(role_id))
        
        game_key = 'game.cn.%s' % source_area
        rpc_game = self.rpc_games.get(game_key)
        if not rpc_game:
            logger.warning('[Transfer] 未找到 %s 的 RPC 客户端', game_key)
            return False
        
        # 转换为 bytes
        def to_bytes(oid):
            if isinstance(oid, ObjectId):
                return bytes(oid.binary)
            elif isinstance(oid, bytes):
                return oid
            elif oid is None:
                return None
            else:
                return bytes(ObjectId(oid).binary)
        
        role_id_bytes = to_bytes(role_id)
        logger.info('[Transfer] RPC 解封参数: game_key=%s, role_id_bytes=%s', game_key, repr(role_id_bytes))
        
        @coroutine
        def do_unlock():
            try:
                # gmRoleAbandon(roleID, type, val) - 直接调用 game 服务，不需要 servName
                logger.info('[Transfer] 调用 gmRoleAbandon...')
                ret = yield rpc_game.call_async(
                    'gmRoleAbandon',
                    role_id_bytes, # roleID (bytes)
                    'disable',     # type
                    False          # val: False = 解封
                )
                logger.info('[Transfer] gmRoleAbandon 返回: %s', ret)
                raise Return(ret)
            except Return:
                raise
            except Exception as e:
                logger.error('[Transfer] RPC 解封异常: %s', e)
                raise Return(False)
        
        result = self.ioloop.run_sync(do_unlock)
        logger.info('[Transfer] RPC 解封最终结果: %s', result)
        return result
    
    def _send_refund_mail_rpc(self, source_area, role_id, cost_info):
        """通过 RPC 发送退费邮件（同步 Go 端缓存）"""
        from bson import ObjectId
        
        logger.info('[Transfer] 开始 RPC 退费邮件: area=%s, role=%s, cost_info=%s', 
                   source_area, repr(role_id), cost_info)
        
        if not cost_info:
            logger.info('[Transfer] 无费用信息，跳过退费邮件')
            return True
        
        game_key = 'game.cn.%s' % source_area
        rpc_game = self.rpc_games.get(game_key)
        if not rpc_game:
            logger.warning('[Transfer] 未找到 %s 的 RPC 客户端', game_key)
            return False
        
        # 转换为 bytes
        def to_bytes(oid):
            if isinstance(oid, ObjectId):
                return bytes(oid.binary)
            elif isinstance(oid, bytes):
                return oid
            elif oid is None:
                return None
            else:
                return bytes(ObjectId(oid).binary)
        
        role_id_bytes = to_bytes(role_id)
        logger.info('[Transfer] RPC 退费邮件参数: game_key=%s, role_id_bytes=%s', game_key, repr(role_id_bytes))
        
        @coroutine
        def do_send():
            try:
                # gmSendMail(roleID, mailType, sender, subject, content, attachs) - 直接调用 game 服务
                logger.info('[Transfer] 调用 gmSendMail...')
                ret = yield rpc_game.call_async(
                    'gmSendMail',
                    role_id_bytes, # roleID (bytes)
                    1,             # mailType (CSV ID)
                    '系统',        # sender
                    '转区退费',    # subject
                    '您的转区申请失败，现退还转区费用。如有疑问请联系客服。',  # content
                    cost_info      # attachs {rmb: 1000}
                )
                logger.info('[Transfer] gmSendMail 返回: %s', ret)
                raise Return(ret)
            except Return:
                raise
            except Exception as e:
                logger.error('[Transfer] RPC 退费邮件异常: %s', e)
                raise Return(False)
        
        result = self.ioloop.run_sync(do_send)
        logger.info('[Transfer] RPC 退费邮件最终结果: %s', result)
        return result
    
    def scan(self):
        """扫描并执行转区"""
        now = time.time()
        logger.info('========== Scan transfer records (now=%d) ==========', int(now))
        
        for game_key, db in self.game_dbs.items():
            try:
                # 1. 清理过期邀请
                self._clean_expired_invites(game_key, db, now)
                # 2. 扫描转区记录
                self._scan_game(game_key, db, now)
            except Exception as e:
                logger.error('[%s] Scan error: %s', game_key, e)
                import traceback
                logger.error(traceback.format_exc())
        
        logger.info('========== Scan complete ==========')
    
    def _clean_expired_invites(self, game_key, db, now):
        """清理过期邀请"""
        try:
            # 查找过期但状态仍为 pending 的邀请
            result = db.TransferInvite.update_many(
                {
                    'status': 'pending',
                    'expire_time': {'$lt': now}
                },
                {
                    '$set': {'status': 'expired'}
                }
            )
            if result.modified_count > 0:
                logger.info('[%s] 清理过期邀请: %d 条', game_key, result.modified_count)
        except Exception as e:
            # TransferInvite 表可能不存在，忽略错误
            pass
    
    def _scan_game(self, game_key, db, now):
        """扫描单个游戏区"""
        logger.info('[%s] Querying TransferRecord...', game_key)
        
        # 查询待处理的转区记录
        records = list(db.TransferRecord.find({
            'status': 'pending'
        }).limit(10))
        
        logger.info('[%s] Query result: count=%d', game_key, len(records))
        
        # 筛选已到执行时间的记录
        ready_records = []
        for record in records:
            record_id = record.get('_id')
            execute_time = record.get('execute_time', 0)
            ready = execute_time <= now
            logger.info('[%s] Record %s: execute_time=%.2f, now=%.2f, ready=%s',
                       game_key, repr(record_id), execute_time, now, ready)
            if ready:
                ready_records.append(record)
        
        logger.info('[%s] Found %d pending (%d ready to execute)',
                   game_key, len(records), len(ready_records))
        
        # 执行转区
        for record in ready_records:
            self._execute(game_key, record, db)
    
    def _execute(self, game_key, record, source_db):
        """执行单个转区"""
        record_id = record.get('_id')
        role_id = record.get('role_db_id')
        target_area = record.get('target_area')
        
        logger.info('[Transfer] 开始: record=%s, role=%s -> area:%s',
                   repr(record_id), repr(role_id), target_area)
        
        try:
            # 乐观锁：尝试更新状态
            result = source_db.TransferRecord.update_one(
                {'_id': record_id, 'status': 'pending'},
                {'$set': {
                    'status': 'processing',
                    'start_time': time.time()
                }}
            )
            
            if result.modified_count == 0:
                logger.warning('[Transfer] 记录已被其他进程处理，跳过')
                return
            
            # 获取目标区数据库
            target_key = 'game.cn.%s' % target_area
            target_db = self.game_dbs.get(target_key)
            if not target_db:
                raise Exception('Target database not found: %s' % target_key)
            
            # 【检查目标区角色】只检查等级限制，不删除（直接覆盖引用）
            account_id = record.get('account_id')
            
            # 检查 Account.role_infos 中是否有高等级角色
            if account_id and self.account_db:
                account = self.account_db.Account.find_one({'_id': account_id})
                if account:
                    role_infos = account.get('role_infos') or {}
                    existing = role_infos.get(target_key)
                    if existing:
                        existing_name = existing.get('name', '') or ''
                        existing_level = existing.get('level', 0)
                        existing_id = existing.get('id')
                        has_real_role = bool(existing_id) and (existing_name or existing_level > 0)
                        
                        if has_real_role and existing_level > 80:
                            # 高等级角色不允许覆盖
                            raise Exception('目标区有角色「%s」(lv%d)，等级过高无法覆盖' % (existing_name, existing_level))
                        elif has_real_role:
                            logger.info('[Transfer] 目标区有角色「%s」(lv%d)，将被覆盖（不删除，只更换引用）', existing_name, existing_level)
            
            # 检查 Role 表中是否有高等级角色
            existing_role = target_db.Role.find_one({
                'account_id': account_id,
                'area': int(target_area)
            })
            if existing_role:
                existing_name = existing_role.get('name', '')
                existing_level = existing_role.get('level', 0)
                
                if existing_level > 80:
                    raise Exception('目标区有角色「%s」(lv%d)，等级过高无法覆盖' % (existing_name, existing_level))
                else:
                    logger.info('[Transfer] 目标区 Role 表有角色「%s」(lv%d)，将成为孤儿数据', existing_name, existing_level)
            
            logger.info('[Transfer] 目标区检查通过，开始转区')
            
            # 执行转区（同步方法）
            service = TransferService(source_db, target_db, self.account_db)
            
            def progress_cb(progress, msg):
                source_db.TransferRecord.update_one(
                    {'_id': record_id},
                    {'$set': {
                        'progress': progress,
                        'progress_msg': msg
                    }}
                )
                logger.info('[Transfer] Progress: %d%% - %s', progress, msg)
            
            # 执行转区（覆盖模式：目标区已有角色会变成孤儿数据）
            success = service.execute(
                source_role_id=role_id,
                target_area=target_area,
                record_id=record_id,
                progress_cb=progress_cb
            )
            
            if success:
                # 【数据验证】转区成功后验证数据一致性
                verify_result = service.verify_transfer(role_id, service.new_role_id)
                if not verify_result['success']:
                    logger.error('[Transfer] 数据验证失败: %s', verify_result['errors'])
                    # 记录验证失败但不阻止转区（数据已迁移）
                    # 后续可以通过 GM 后台查看验证结果
                
                account_id = record.get('account_id')
                target_key = 'game.cn.%s' % target_area
                role_info = {
                    'id': service.new_role_id,
                    'name': service.new_name,
                    'level': service.source_level,
                    'logo': service.source_logo,
                    'vip': service.source_vip,
                    'frame': service.source_frame,
                }
                
                # 【重要】先用 pymongo 直接更新 Account.role_infos（确保数据库正确）
                if account_id and self.account_db:
                    try:
                        self.account_db.Account.update_one(
                            {'_id': account_id},
                            {'$set': {'role_infos.%s' % target_key: role_info}}
                        )
                        logger.info('[Transfer] Account.role_infos 已通过 pymongo 更新: %s -> %s', 
                                   repr(account_id), target_key)
                    except Exception as e:
                        logger.error('[Transfer] pymongo 更新 Account 失败: %s', e)
                
                # 再通过 RPC 尝试更新 Go 端缓存（如果失败，玩家重新登录会从数据库加载）
                if account_id and self.rpc_account:
                    # 多次重试 RPC 更新
                    rpc_ok = False
                    for retry in range(3):
                        rpc_ok = self._update_account_rpc(account_id, target_area, role_info)
                        if rpc_ok:
                            break
                        logger.warning('[Transfer] Account RPC 更新失败，重试 %d/3', retry + 1)
                        time.sleep(1)
                
                # 【关键】踢掉目标区的旧 session（清除 Python 端缓存）
                # 这样玩家下次登录会重新从数据库加载角色
                if account_id:
                    try:
                        self._kick_target_session(target_area, account_id)
                    except Exception as e:
                        logger.warning('[Transfer] 踢掉目标区 session 失败: %s', e)
                    
                    if not rpc_ok:
                        logger.warning('[Transfer] RPC 更新缓存失败，但数据库已更新')
                
                # 成功
                update_data = {
                    'status': 'completed',
                    'complete_time': time.time(),
                    'target_role_db_id': service.new_role_id,
                    'target_uid': service.new_uid,
                    'target_name': service.new_name,
                    'progress': 100,
                    'progress_msg': 'Transfer completed'
                }
                
                # 保存验证结果
                if verify_result:
                    update_data['verify_success'] = verify_result['success']
                    update_data['verify_errors'] = verify_result.get('errors', [])
                    update_data['verify_warnings'] = verify_result.get('warnings', [])
                    update_data['verify_details'] = verify_result.get('details', {})
                
                source_db.TransferRecord.update_one(
                    {'_id': record_id},
                    {'$set': update_data}
                )
                
                # 如果是邀请转区，更新邀请状态为 completed
                invite_id = record.get('invite_id')
                if invite_id:
                    try:
                        target_db = self.game_dbs.get(target_key)
                        if target_db:
                            target_db.TransferInvite.update_one(
                                {'_id': invite_id},
                                {'$set': {'status': 'completed'}}
                            )
                            logger.info('[Transfer] 邀请状态已更新为 completed: %s', invite_id)
                    except Exception as e:
                        logger.warning('[Transfer] 更新邀请状态失败: %s', e)
                
                logger.info('[Transfer] 成功: new_role=%s, new_uid=%s, new_name=%s',
                           service.new_role_id, service.new_uid, service.new_name)
            else:
                # 失败 - 解封源区角色 + 自动退费
                source_db.TransferRecord.update_one(
                    {'_id': record_id},
                    {'$set': {
                        'status': 'failed',
                        'complete_time': time.time(),
                        'fail_reason': service.error_msg
                    }}
                )
                logger.error('[Transfer] 失败: %s', service.error_msg)
                
                # 获取源区信息
                source_area = record.get('source_area')
                cost_info = record.get('cost_info')
                
                # 【重要】通过 RPC 解封源区角色（同步 Go 端缓存）
                unlock_ok = self._unlock_role_rpc(source_area, role_id)
                if unlock_ok:
                    logger.info('[Transfer] RPC 解封成功: %s', repr(role_id))
                else:
                    # 降级：直接更新数据库
                    source_db.Role.update_one(
                        {'_id': role_id},
                        {'$set': {'disable_flag': False}}
                    )
                    logger.warning('[Transfer] RPC 解封失败，已降级直接更新数据库: %s', repr(role_id))
                
                # 【自动退费】通过 RPC 发送退费邮件
                if cost_info:
                    refund_ok = self._send_refund_mail_rpc(source_area, role_id, cost_info)
                    if refund_ok:
                        # 标记已退费（自动）
                        source_db.TransferRecord.update_one(
                            {'_id': record_id},
                            {'$set': {
                                'refunded': True,
                                'refund_time': time.time(),
                                'auto_refunded': True  # 标记为自动退费
                            }}
                        )
                        logger.info('[Transfer] 自动退费成功: %s', repr(role_id))
                    else:
                        logger.error('[Transfer] 自动退费失败，需手动处理: %s', repr(role_id))
                
        except Exception as e:
            logger.error('[Transfer] 异常: %s', e)
            import traceback
            logger.error(traceback.format_exc())
            
            # 标记失败
            source_db.TransferRecord.update_one(
                {'_id': record_id},
                {'$set': {
                    'status': 'failed',
                    'complete_time': time.time(),
                    'fail_reason': str(e)
                }}
            )
            
            # 获取源区信息
            source_area = record.get('source_area')
            cost_info = record.get('cost_info')
            
            # 【重要】通过 RPC 解封源区角色（同步 Go 端缓存）
            try:
                unlock_ok = self._unlock_role_rpc(source_area, role_id)
                if unlock_ok:
                    logger.info('[Transfer] 异常后 RPC 解封成功: %s', repr(role_id))
                else:
                    # 降级：直接更新数据库
                    source_db.Role.update_one(
                        {'_id': role_id},
                        {'$set': {'disable_flag': False}}
                    )
                    logger.warning('[Transfer] RPC 解封失败，已降级直接更新数据库: %s', repr(role_id))
            except Exception as unlock_err:
                logger.error('[Transfer] 解封源区角色失败: %s', unlock_err)
            
            # 【自动退费】通过 RPC 发送退费邮件
            try:
                if cost_info:
                    refund_ok = self._send_refund_mail_rpc(source_area, role_id, cost_info)
                    if refund_ok:
                        # 标记已退费（自动）
                        source_db.TransferRecord.update_one(
                            {'_id': record_id},
                            {'$set': {
                                'refunded': True,
                                'refund_time': time.time(),
                                'auto_refunded': True  # 标记为自动退费
                            }}
                        )
                        logger.info('[Transfer] 异常后自动退费成功: %s', repr(role_id))
                    else:
                        logger.error('[Transfer] 异常后自动退费失败，需手动处理: %s', repr(role_id))
            except Exception as refund_err:
                logger.error('[Transfer] 自动退费异常: %s', refund_err)
    
    def start(self):
        """启动服务（入口方法）"""
        self.run()
    
    def run(self):
        """运行主循环"""
        logger.info('启动转区服务...')
        logger.info('转区服务已启动，每10秒扫描一次')
        
        while True:
            try:
                self.scan()
            except Exception as e:
                logger.error('Scan error: %s', e)
                import traceback
                logger.error(traceback.format_exc())
            
            time.sleep(10)


def main():
    daemon = TransferDaemon()
    daemon.init()
    daemon.run()


if __name__ == '__main__':
    main()
