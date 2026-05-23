#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

转区服务守护进程 - 自动扫描并执行转区

运行方式：
    python transfer_daemon.py

说明：
- 每分钟扫描所有游戏服务器的 TransferRecord 表
- 查找 status=pending 且 execute_time 已到的记录
- 自动执行转区
- 更新进度和状态
'''

import sys
import os

# 添加项目路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

import time
import logging
from tornado.ioloop import IOLoop
from tornado.gen import coroutine
from framework.service.rpc_client import Client
from framework.service.container import Container
from game.service.transfer_service import TransferService

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler('transfer_daemon.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# 游戏服务器配置（需要根据实际情况修改）
GAME_SERVERS = [
    'game.cn.1',
    'game.cn.2',
    'game.cn.3',
    'game.cn.4',
    'game.cn.5',
    'game.cn.6',
    'game.cn.7',
    'game.cn.8',
    'game.cn.9',
]

# NSQ 配置（从 nsq_defines 或配置文件读取）
NSQ_READER = ['127.0.0.1:4150']
NSQ_WRITER = ['127.0.0.1:4150']

# Account 服务key
ACCOUNT_SERVICE = 'accountdb.cn.1'


class TransferDaemon(object):
    """转区守护进程"""
    
    def __init__(self):
        self.container = Container('transfer_daemon', NSQ_READER, NSQ_WRITER)
        self.services = {}  # {server_key: rpc_client}
        self.account_dbc = None
    
    def init(self):
        """初始化服务连接"""
        logger.info('初始化转区服务...')
        
        # 连接所有游戏服务器
        for server_key in GAME_SERVERS:
            storage_key = server_key.replace('game', 'storage')
            client = Client(storage_key, self.container.nsqclient)
            self.container.addservice(client)
            self.services[server_key] = client
            logger.info('连接服务器: %s -> %s', server_key, storage_key)
        
        # 连接 Account 服务
        account_client = Client(ACCOUNT_SERVICE, self.container.nsqclient)
        self.container.addservice(account_client)
        self.account_dbc = account_client
        logger.info('连接 Account 服务: %s', ACCOUNT_SERVICE)
        
        self.container.init()
        logger.info('转区服务初始化完成')
    
    @coroutine
    def scan_and_execute(self):
        """扫描并执行转区"""
        now = time.time()
        logger.info('========== 开始扫描转区申请 ==========')
        
        for server_key in GAME_SERVERS:
            try:
                dbc = self.services.get(server_key)
                if not dbc:
                    continue
                
                # 查询待处理的转区记录
                ret = yield dbc.call_async('DBReadBy', 'TransferRecord', {
                    'status': 'pending',
                    'execute_time': {'$lte': now}
                })
                
                if not ret['ret'] or not ret.get('models'):
                    continue
                
                records = ret['models']
                logger.info('[%s] 发现 %d 条待处理转区', server_key, len(records))
                
                # 限流：每次最多处理 10 条
                for record in records[:10]:
                    try:
                        yield self._execute_one_transfer(server_key, record, dbc)
                    except Exception as e:
                        logger.error('[%s] 转区执行失败: %s', server_key, e)
            
            except Exception as e:
                logger.error('[%s] 扫描失败: %s', server_key, e)
        
        logger.info('========== 扫描完成 ==========')
    
    @coroutine
    def _execute_one_transfer(self, source_server_key, record, source_dbc):
        """执行单个转区"""
        record_id = record['id']
        source_role_id = record['role_db_id']
        target_area = record['target_area']
        
        logger.info('[Transfer] 开始执行: record_id=%s, uid=%s, %s -> area:%s',
                   record_id, record.get('uid'), source_server_key, target_area)
        
        # 更新状态为 processing
        yield source_dbc.call_async('DBUpdate', 'TransferRecord', record_id, {
            'status': 'processing',
            'start_time': time.time(),
            'progress': 0,
            'progress_msg': '开始执行...'
        })
        
        # 获取目标区服务
        target_server_key = 'game.cn.%s' % target_area
        target_dbc = self.services.get(target_server_key)
        
        if not target_dbc:
            error_msg = '目标区服务未连接: %s' % target_server_key
            logger.error('[Transfer] %s', error_msg)
            yield source_dbc.call_async('DBUpdate', 'TransferRecord', record_id, {
                'status': 'failed',
                'fail_reason': error_msg,
                'complete_time': time.time()
            })
            return
        
        # 创建转区服务实例
        service = TransferService(source_dbc, target_dbc, self.account_dbc)
        
        # 执行转区
        try:
            success = yield service.execute(source_role_id, target_area, record_id)
            
            if success:
                # 成功
                logger.info('[Transfer] 转区成功: uid=%s, new_uid=%s', 
                           record.get('uid'), service.new_uid)
                yield source_dbc.call_async('DBUpdate', 'TransferRecord', record_id, {
                    'status': 'completed',
                    'complete_time': time.time(),
                    'target_role_db_id': service.new_role_id,
                    'target_uid': service.new_uid,
                    'target_name': service.new_name,
                    'progress': 100,
                    'progress_msg': '转区完成'
                })
            else:
                # 失败
                logger.error('[Transfer] 转区失败: %s', service.error_msg)
                yield source_dbc.call_async('DBUpdate', 'TransferRecord', record_id, {
                    'status': 'failed',
                    'fail_reason': service.error_msg or '未知错误',
                    'complete_time': time.time()
                })
                
                # 失败时解除源区禁用（允许重新登录）
                yield source_dbc.call_async('DBUpdate', 'Role', source_role_id, {
                    'disable_flag': False
                })
        
        except Exception as e:
            logger.error('[Transfer] 执行异常: %s', e)
            import traceback
            logger.error('[Transfer] %s', traceback.format_exc())
            
            yield source_dbc.call_async('DBUpdate', 'TransferRecord', record_id, {
                'status': 'failed',
                'fail_reason': str(e),
                'complete_time': time.time()
            })
            
            # 失败时解除源区禁用
            yield source_dbc.call_async('DBUpdate', 'Role', source_role_id, {
                'disable_flag': False
            })
    
    def start(self):
        """启动转区服务"""
        logger.info('转区服务启动...')
        
        # 定时扫描（每分钟）
        from tornado.ioloop import PeriodicCallback
        timer = PeriodicCallback(
            lambda: IOLoop.current().add_callback(self.scan_and_execute),
            60 * 1000  # 60秒
        )
        timer.start()
        
        logger.info('转区服务已启动，每60秒扫描一次')
        
        # 启动 IOLoop
        IOLoop.current().start()


def main():
    """主函数"""
    daemon = TransferDaemon()
    daemon.init()
    daemon.start()


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        logger.info('转区服务停止')
    except Exception as e:
        logger.error('转区服务异常退出: %s', e)
        import traceback
        logger.error(traceback.format_exc())

