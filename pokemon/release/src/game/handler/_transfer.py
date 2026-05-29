#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

【转区逻辑】玩家端协议处理 - 获取信息、申请转区、邀请管理
'''

import time
import datetime
import binascii
from bson import ObjectId

from framework import todayinclock5date2int, nowtime_t
from framework.csv import csv, ErrDefs
from framework.log import logger

from game import ServerError, ClientError
from game.handler.task import RequestHandlerTask
from game.object.game.gain import ObjectCostAux
from game.object import UnionDefs
from game.session import Session

from tornado.gen import coroutine, Return


def getCurrentMonth():
    """获取当前月份标识（如 202601）"""
    now = datetime.datetime.now()
    return now.year * 100 + now.month


def idToStr(id_value):
    """将 bytes 格式的 ID 转换为十六进制字符串"""
    if id_value is None:
        return ''
    if isinstance(id_value, bytes):
        return binascii.hexlify(id_value).decode('utf-8')
    return str(id_value)


def strToId(id_str):
    """将十六进制字符串转换为 bytes 格式的 ID"""
    if not id_str:
        return None
    try:
        return binascii.unhexlify(id_str)
    except Exception:
        return id_str  # 可能已经是 bytes 格式




def getTransferConfig():
    """获取当前有效的转区配置"""
    today = todayinclock5date2int()
    for cfgId in csv.transfer:
        cfg = csv.transfer[cfgId]
        startDate = getattr(cfg, 'startDate', 0) or 0
        endDate = getattr(cfg, 'endDate', 99999999) or 99999999
        if startDate <= today <= endDate:
            return cfg
    return None


def getConfigValue(cfg, key, default):
    """从配置中获取值，如果为空则返回默认值"""
    val = getattr(cfg, key, None)
    return val if val is not None else default


def calculateTransferCost(cfg, fightingPoint, isInvite=True):
    """计算转区费用
    
    Args:
        cfg: 转区配置
        fightingPoint: 战力
        isInvite: 是否邀请转区（False 为自由转区，需额外费用）
    
    Returns:
        dict: {itemID: count}
    """
    ticketId = getConfigValue(cfg, 'ticketItemId', 9800)
    extraCost = getConfigValue(cfg, 'freeExtraCost', 5)
    
    baseCost = fightingPoint // 1000000  # 每100w战力 = 1张
    
    logger.info('calculateTransferCost: fighting=%d, baseCost=%d, extraCost=%d, isInvite=%s',
                fightingPoint, baseCost, extraCost, isInvite)
    
    if isInvite:
        # 邀请转区：纯战力费用
        return {ticketId: baseCost} if baseCost > 0 else {}
    else:
        # 自由转区：战力费用 + 额外费用
        totalCost = baseCost + extraCost
        return {ticketId: totalCost}


def getInviteQuota(cfg):
    """获取邀请名额配置"""
    return getConfigValue(cfg, 'inviteQuota', 10)


def getFreeQuota(cfg):
    """获取自由转区名额配置"""
    return getConfigValue(cfg, 'freeQuota', 10)


def getInviteExpireSeconds(cfg):
    """获取邀请有效期（秒）"""
    days = getConfigValue(cfg, 'inviteExpireDays', 3)
    return days * 24 * 3600


# /game/transfer/info - 获取转区信息
class TransferInfo(RequestHandlerTask):
    url = r'/game/transfer/info'

    @coroutine
    def run(self):
        role = self.game.role
        cfg = getTransferConfig()
        
        if not cfg:
            self.write({'view': {
                'enabled': False,
                'reason': '转区功能未开放'
            }})
            return
        
        # 获取已有的转区次数和上次转区时间
        transferTimes = role.transfer_times or 0
        lastTransferTime = role.last_transfer_time or 0
        
        # 计算冷却剩余时间（注意：0 表示无冷却，不能用 or 30）
        cooldownDays = getattr(cfg, 'cooldownDays', None)
        if cooldownDays is None:
            cooldownDays = 30
        cooldownSeconds = cooldownDays * 86400
        cooldownRemain = 0
        if lastTransferTime > 0:
            elapsed = nowtime_t() - lastTransferTime
            if elapsed < cooldownSeconds:
                cooldownRemain = int(cooldownSeconds - elapsed)
        
        # 查询进行中的转区申请
        pendingTransfer = None
        try:
            ret = yield self.dbcGame.call_async('DBReadBy', 'TransferRecord', {
                'role_db_id': role.id,
                'status': {'$in': ['pending', 'processing']}
            })
            if ret['ret'] and ret.get('models'):
                record = ret['models'][0]
                pendingTransfer = {
                    'transferId': str(record['id']),
                    'targetArea': record.get('target_area'),
                    'status': record.get('status'),
                    'progress': record.get('progress', 0),
                    'applyTime': record.get('apply_time', 0)
                }
        except Exception as e:
            logger.warning('TransferInfo query pending error: %s', e)
        
        # 获取可转目标区列表
        targetAreas = list(getattr(cfg, 'targetAreas', []) or [])
        # 排除当前区
        if role.area in targetAreas:
            targetAreas.remove(role.area)
        
        # 动态计算费用（基于历史最高前6战力，防止玩家换低战力阵容降低费用）
        fightingPoint = role.top6_fighting_point or 0
        ticketCount = fightingPoint // 1000000  # 每100w战力=1张
        
        logger.info('TransferInfo: role=%s top6_fighting_point=%d, battle_fighting_point=%d, ticketCount=%d',
                   role.name, role.top6_fighting_point or 0, role.battle_fighting_point or 0, ticketCount)
        
        # 快速检查邀请权限（会长/副会长 + 第一公会）
        hasInvitePermission = False
        if role.union_db_id:
            isChairman = role.isUnionChairman()
            isViceChairman = role.isUnionViceChairman()
            if isChairman or isViceChairman:
                try:
                    unions = yield self.rpcUnion.call_async('GetRankList', 0, 1)
                    if unions and len(unions) > 0:
                        topUnionId = unions[0].get('id')
                        if role.union_db_id == topUnionId:
                            hasInvitePermission = True
                except Exception as e:
                    logger.warning('TransferInfo check invite permission error: %s', e)
        
        self.write({'view': {
            'enabled': True,
            'minLevel': getattr(cfg, 'minLevel', 30) or 30,
            'cost': calculateTransferCost(cfg, fightingPoint, isInvite=True),  # 邀请转区费用
            'freeCost': calculateTransferCost(cfg, fightingPoint, isInvite=False),  # 自由转区费用
            'fightingPoint': fightingPoint,
            'ticketCount': ticketCount,
            'cooldownDays': cooldownDays,
            'cooldownRemain': cooldownRemain,
            'maxTimes': getattr(cfg, 'maxTimes', 1) if getattr(cfg, 'maxTimes', None) is not None else 1,
            'usedTimes': transferTimes,
            'lastTransferTime': lastTransferTime,
            'targetAreas': targetAreas,
            'pendingTransfer': pendingTransfer,
            # 名额信息
            'inviteQuotaMax': getInviteQuota(cfg),
            'freeQuotaMax': getFreeQuota(cfg),
            # 邀请权限
            'hasInvitePermission': hasInvitePermission,
        }})


# /game/transfer/check - 检查转区条件
class TransferCheck(RequestHandlerTask):
    url = r'/game/transfer/check'

    @coroutine
    def run(self):
        role = self.game.role
        targetArea = self.input.get('targetArea', None)
        transferType = self.input.get('transferType', 'invite')  # 'invite' 或 'free'
        
        if targetArea is None:
            raise ClientError('param miss')
        targetArea = int(targetArea)
        isInviteTransfer = (transferType != 'free')  # 默认邀请转区
        
        cfg = getTransferConfig()
        if not cfg:
            self.write({'view': {
                'canTransfer': False,
                'errors': ['转区功能未开放']
            }})
            return
        
        errors = []
        warnings = []
        existingTargetRole = None
        
        # 1. 检查等级要求
        minLevel = getattr(cfg, 'minLevel', 30) or 30
        if role.level < minLevel:
            errors.append('等级不足，需要%d级' % minLevel)
        
        # 2. 检查公会
        if role.union_db_id:
            errors.append('请先退出公会')
        
        # 3. 检查转区次数（注意：maxTimes=0 表示无限制）
        maxTimes = getattr(cfg, 'maxTimes', None)
        if maxTimes is None:
            maxTimes = 1
        transferTimes = role.transfer_times or 0
        if maxTimes > 0 and transferTimes >= maxTimes:
            errors.append('转区次数已用完（最多%d次）' % maxTimes)
        
        # 4. 检查冷却期（注意：cooldownDays=0 表示无冷却）
        cooldownDays = getattr(cfg, 'cooldownDays', None)
        if cooldownDays is None:
            cooldownDays = 30
        lastTransferTime = role.last_transfer_time or 0
        if cooldownDays > 0 and lastTransferTime > 0:
            elapsed = nowtime_t() - lastTransferTime
            if elapsed < cooldownDays * 86400:
                remainDays = int((cooldownDays * 86400 - elapsed) / 86400) + 1
                errors.append('冷却中，还需%d天' % remainDays)
        
        # 5. 检查目标区是否在可选列表中
        targetAreas = list(getattr(cfg, 'targetAreas', []) or [])
        if targetArea not in targetAreas:
            errors.append('目标服务器不可用')
        
        # 6. 检查是否转到当前区
        if targetArea == role.area:
            errors.append('不能转区到当前服务器')
        
        # 7. 检查费用（动态计算，根据转区类型，使用历史最高前6战力）
        fightingPoint = role.top6_fighting_point or 0
        costMap = calculateTransferCost(cfg, fightingPoint, isInvite=isInviteTransfer)
        if costMap:
            cost = ObjectCostAux(self.game, costMap)
            if not cost.isEnough():
                errors.append('转区券不足')
        
        # 8. 检查是否有进行中的转区申请
        try:
            ret = yield self.dbcGame.call_async('DBReadBy', 'TransferRecord', {
                'role_db_id': role.id,
                'status': {'$in': ['pending', 'processing']}
            })
            if ret['ret'] and ret.get('models'):
                errors.append('已有进行中的转区申请')
        except Exception as e:
            logger.warning('TransferCheck query pending error: %s', e)
        
        # 9. 检查目标区是否已有该账号的角色（通过Account表的role_infos）
        targetServKey = 'game.cn.%d' % targetArea
        dbcAccount = self.dbcGift
        if dbcAccount:
            try:
                accountRet = yield dbcAccount.call_async('DBRead', 'Account', role.account_id, False)
                if accountRet['ret'] and accountRet.get('model'):
                    accountData = accountRet['model']
                    roleInfos = accountData.get('role_infos', {})
                    if targetServKey in roleInfos:
                        targetRoleInfo = roleInfos[targetServKey]
                        targetLevel = targetRoleInfo.get('level', 0)
                        targetName = targetRoleInfo.get('name', '') or ''
                        targetVip = targetRoleInfo.get('vip', 0)
                        targetId = targetRoleInfo.get('id')
                        
                        # 检查是否是真正创建的角色（不是只进入游戏但没创建角色的空记录）
                        # 空记录的特征：id为空、name为空、level为0
                        hasRealRole = bool(targetId) and (targetName or targetLevel > 0)
                        
                        if hasRealRole:
                            # 返回目标区角色信息
                            existingTargetRole = {
                                'name': targetName or '未知',
                                'level': targetLevel,
                                'vip': targetVip,
                                'servKey': targetServKey
                            }
                            
                            logger.info('TransferCheck: target area has role: %s (lv%d)', targetName, targetLevel)
                            
                            # 80级以上不允许覆盖
                            if targetLevel > 80:
                                errors.append('目标区已有%d级角色「%s」，等级过高(>80级)无法覆盖' % (targetLevel, targetName))
                            else:
                                # 80级及以下，警告用户可以覆盖
                                warnings.append('目标区已有%d级角色「%s」，转区后该角色将被覆盖' % (targetLevel, targetName))
                        else:
                            # 只是进入过游戏但没创建角色的空记录，自动清理
                            logger.info('TransferCheck: target area has empty role_info (no real role), auto cleaning...')
                            try:
                                yield dbcAccount.call_async('DBUpdate', 'Account', role.account_id, {
                                    '$unset': {'role_infos.%s' % targetServKey: ''}
                                }, False)
                                logger.info('TransferCheck: empty role_info cleaned for %s', targetServKey)
                                # 提示用户已清理空记录
                                warnings.append('已自动清理目标区的登录记录（无实际角色）')
                            except Exception as cleanErr:
                                logger.warning('TransferCheck: failed to clean empty role_info: %s', cleanErr)
            except Exception as e:
                logger.error('TransferCheck query Account error: %s', e)
                errors.append('检查目标区失败，请稍后重试')
        else:
            logger.error('TransferCheck: dbcGift not available')
            errors.append('系统繁忙，请稍后重试')
        
        # 10. 计算费用（动态显示给玩家，根据转区类型，使用历史最高前6战力）
        fightingPoint = role.top6_fighting_point or 0
        costMap = calculateTransferCost(cfg, fightingPoint, isInvite=isInviteTransfer)
        ticketId = getConfigValue(cfg, 'ticketItemId', 9800)
        ticketCount = costMap.get(ticketId, 0) if costMap else 0
        
        # 11. 警告信息
        warnings.append('转区后将立即下线，需等待30分钟完成')
        warnings.append('如角色名在目标区冲突，将自动改名为"原名.s%d"' % role.area)
        warnings.append('转区后好友、公会、邮件数据将清空')
        warnings.append('转区后跨服活动数据将清空')
        warnings.append('转区不可撤销')
        
        self.write({'view': {
            'canTransfer': len(errors) == 0,
            'errors': errors,
            'warnings': warnings,
            'existingTargetRole': existingTargetRole,
            'cost': costMap,  # 费用：{转区券ID: 数量}
            'fightingPoint': fightingPoint,  # 当前战力
            'ticketCount': ticketCount  # 需要的转区券数量
        }})


# /game/transfer/apply - 申请转区
class TransferApply(RequestHandlerTask):
    url = r'/game/transfer/apply'

    @coroutine
    def run(self):
        role = self.game.role
        targetArea = self.input.get('targetArea', None)
        
        if targetArea is None:
            raise ClientError('param miss')
        targetArea = int(targetArea)
        
        cfg = getTransferConfig()
        if not cfg:
            raise ClientError('转区功能未开放')
        
        # 再次检查所有条件
        minLevel = getattr(cfg, 'minLevel', 30) or 30
        if role.level < minLevel:
            raise ClientError('等级不足')
        
        if role.union_db_id:
            raise ClientError('请先退出公会')
        
        maxTimes = getattr(cfg, 'maxTimes', None)
        if maxTimes is None:
            maxTimes = 1
        transferTimes = role.transfer_times or 0
        if maxTimes > 0 and transferTimes >= maxTimes:
            raise ClientError('转区次数已用完')
        
        cooldownDays = getattr(cfg, 'cooldownDays', None)
        if cooldownDays is None:
            cooldownDays = 30
        lastTransferTime = role.last_transfer_time or 0
        if cooldownDays > 0 and lastTransferTime > 0:
            elapsed = nowtime_t() - lastTransferTime
            if elapsed < cooldownDays * 86400:
                raise ClientError('冷却期未结束')
        
        targetAreas = list(getattr(cfg, 'targetAreas', []) or [])
        if targetArea not in targetAreas or targetArea == role.area:
            raise ClientError('目标服务器不可用')
        
        # 检查是否有进行中的申请
        try:
            ret = yield self.dbcGame.call_async('DBReadBy', 'TransferRecord', {
                'role_db_id': role.id,
                'status': {'$in': ['pending', 'processing']}
            })
            if ret['ret'] and ret.get('models'):
                raise ClientError('已有进行中的转区申请')
        except ClientError:
            raise
        except Exception as e:
            logger.warning('TransferApply query pending error: %s', e)
        
        # 检查目标区角色情况（只阻止>80级，≤80级允许覆盖）
        targetServKey = 'game.cn.%d' % targetArea
        dbcAccount = self.dbcGift
        if not dbcAccount:
            logger.error('TransferApply: dbcGift not available, cannot check target area')
            raise ClientError('系统繁忙，请稍后重试')
        
        try:
            accountRet = yield dbcAccount.call_async('DBRead', 'Account', role.account_id, False)
            if not accountRet['ret']:
                logger.error('TransferApply: query Account failed: %s', accountRet)
                raise ClientError('系统繁忙，请稍后重试')
            
            accountData = accountRet.get('model')
            if accountData:
                roleInfos = accountData.get('role_infos', {})
                if targetServKey in roleInfos:
                    targetRoleInfo = roleInfos[targetServKey]
                    targetLevel = targetRoleInfo.get('level', 0)
                    targetName = targetRoleInfo.get('name', '') or ''
                    targetId = targetRoleInfo.get('id')
                    
                    # 检查是否是真正创建的角色
                    hasRealRole = bool(targetId) and (targetName or targetLevel > 0)
                    
                    if hasRealRole:
                        if targetLevel > 80:
                            # 高等级角色不允许覆盖
                            raise ClientError('目标区已有%d级角色「%s」，超过80级无法覆盖' % (targetLevel, targetName))
                        else:
                            # ≤80级允许覆盖，记录日志
                            logger.info('TransferApply: target area has role %s (lv%d), will be overwritten', 
                                       targetName, targetLevel)
                    else:
                        # 空记录，清理
                        logger.info('TransferApply: target area has empty role_info, clearing...')
                        yield dbcAccount.call_async('DBUpdate', 'Account', role.account_id, {
                            '$unset': {'role_infos.%s' % targetServKey: ''}
                        }, False)
        except ClientError:
            raise
        except Exception as e:
            logger.error('TransferApply query Account error: %s', e)
            raise ClientError('检查目标区失败，请稍后重试')
        
        # 计算费用：使用全局函数（基于历史最高前6战力，无保底）
        fightingPoint = role.top6_fighting_point or 0
        costMap = calculateTransferCost(cfg, fightingPoint, isInvite=True)  # 默认按邀请转区计算
        
        logger.info('TransferApply: role=%s fighting_point=%d, costMap=%s',
                   role.name, fightingPoint, costMap)
        
        # 扣除费用
        if costMap:
            cost = ObjectCostAux(self.game, costMap)
            if not cost.isEnough():
                raise ClientError(ErrDefs.costNotEnough)
            cost.cost(src='transfer_apply')
        
        # 创建转区记录
        applyTime = nowtime_t()
        recordData = {
            'role_db_id': role.id,
            'uid': role.uid,
            'role_name': role.name,
            'level': role.level,
            'vip_level': role.vip_level,
            'source_area': role.area,
            'target_area': targetArea,
            'account_id': role.account_id,
            'status': 'pending',
            'apply_time': applyTime,
            'execute_time': applyTime + 1800,  # 30分钟后执行
            'cost_info': costMap,
            'progress': 0,
            'progress_msg': '等待执行'
        }
        
        try:
            ret = yield self.dbcGame.call_async('DBCreate', 'TransferRecord', recordData)
            if not ret['ret']:
                # 创建失败，退还费用
                if costMap:
                    from game.object.game.gain import ObjectGainAux
                    from game.handler.inl import effectAutoGain
                    eff = ObjectGainAux(self.game, costMap)
                    yield effectAutoGain(eff, self.game, self.dbcGame, src='transfer_apply_refund')
                raise ServerError('创建转区记录失败')
            recordId = ret['model']['id']
        except Exception as e:
            logger.error('TransferApply create record error: %s', e)
            # 退还费用
            if costMap:
                from game.object.game.gain import ObjectGainAux
                from game.handler.inl import effectAutoGain
                eff = ObjectGainAux(self.game, costMap)
                yield effectAutoGain(eff, self.game, self.dbcGame, src='transfer_apply_refund')
            raise ServerError('创建转区记录失败')
        
        # 立即标记禁用（防止继续登录）
        try:
            yield self.dbcGame.call_async('DBUpdate', 'Role', role.id, {
                'disable_flag': True
            }, False)
            role.disable_flag = True
        except Exception as e:
            logger.error('TransferApply set disable_flag error: %s', e)
        
        # 强制踢下线（触发数据保存）
        try:
            Session.discardSessionByAccountKey((role.area, role.account_id))
        except Exception as e:
            logger.warning('TransferApply disconnect error: %s', e)
        
        logger.info('TransferApply: role=%s uid=%d area=%d -> targetArea=%d, recordId=%s',
                    role.name, role.uid, role.area, targetArea, recordId)
        
        self.write({'view': {
            'success': True,
            'transferId': str(recordId),
            'message': '申请成功，请30分钟后登录%d区' % targetArea
        }})


# /game/transfer/status - 查询转区状态
class TransferStatus(RequestHandlerTask):
    url = r'/game/transfer/status'

    @coroutine
    def run(self):
        role = self.game.role
        
        # 查询最近的转区记录
        try:
            ret = yield self.dbcGame.call_async('DBReadBy', 'TransferRecord', {
                'role_db_id': role.id
            })
            if not ret['ret'] or not ret.get('models'):
                self.write({'view': {
                    'status': 'none',
                    'message': '没有转区记录'
                }})
                return
            
            # 找最新的记录
            records = ret['models']
            records.sort(key=lambda x: x.get('apply_time', 0), reverse=True)
            record = records[0]
        except Exception as e:
            logger.warning('TransferStatus query error: %s', e)
            self.write({'view': {
                'status': 'error',
                'message': '查询失败'
            }})
            return
        
        status = record.get('status', 'unknown')
        progress = record.get('progress', 0)
        progressMsg = record.get('progress_msg', '')
        
        statusMessages = {
            'pending': '等待执行（请等待30分钟）',
            'processing': progressMsg or '正在执行...',
            'completed': '转区成功',
            'failed': '转区失败: ' + record.get('fail_reason', ''),
        }
        
        self.write({'view': {
            'status': status,
            'progress': progress,
            'message': statusMessages.get(status, '未知状态'),
            'targetArea': record.get('target_area'),
            'applyTime': record.get('apply_time'),
            'executeTime': record.get('execute_time'),
            'completeTime': record.get('complete_time')
        }})


# /game/transfer/delete_target - 删除目标区角色（转区前的准备步骤）
class TransferDeleteTarget(RequestHandlerTask):
    url = r'/game/transfer/delete_target'

    @coroutine
    def run(self):
        role = self.game.role
        targetArea = self.input.get('targetArea')
        
        if not targetArea:
            raise ClientError('缺少目标区参数')
        
        targetArea = int(targetArea)
        if targetArea == role.area:
            raise ClientError('不能删除当前区的角色')
        
        cfg = getTransferConfig()
        if not cfg:
            raise ClientError('转区功能未开放')
        
        # 检查目标区是否在可转区列表中
        targetAreas = getattr(cfg, 'targetAreas', []) or []
        if targetArea not in targetAreas:
            raise ClientError('目标区不可选')
        
        # 查询目标区是否有角色
        targetServKey = 'game.cn.%d' % targetArea
        dbcAccount = self.dbcGift
        
        if not dbcAccount:
            raise ClientError('系统繁忙，请稍后重试')
        
        try:
            accountRet = yield dbcAccount.call_async('DBRead', 'Account', role.account_id, False)
            if not accountRet['ret']:
                raise ClientError('查询账号失败')
            
            accountData = accountRet.get('model')
            if not accountData:
                raise ClientError('账号数据异常')
            
            roleInfos = accountData.get('role_infos', {})
            targetRoleInfo = roleInfos.get(targetServKey)
            
            if not targetRoleInfo:
                # 没有角色，不需要删除
                self.write({'view': {
                    'success': True,
                    'message': '目标区没有角色，无需删除',
                    'deleted': False
                }})
                return
            
            # 检查是否是真正的角色
            targetId = targetRoleInfo.get('id')
            targetName = targetRoleInfo.get('name', '') or ''
            targetLevel = targetRoleInfo.get('level', 0)
            
            hasRealRole = bool(targetId) and (targetName or targetLevel > 0)
            
            if not hasRealRole:
                # 只是空记录，清理即可
                yield dbcAccount.call_async('DBUpdate', 'Account', role.account_id, {
                    '$unset': {'role_infos.%s' % targetServKey: ''}
                }, False)
                self.write({'view': {
                    'success': True,
                    'message': '已清理空记录',
                    'deleted': False
                }})
                return
            
            # 检查等级限制
            if targetLevel > 80:
                raise ClientError('目标区角色「%s」等级%d级，超过80级无法自动删除，请手动删除' % (targetName, targetLevel))
            
            logger.info('TransferDeleteTarget: deleting role in %s, name=%s, level=%d', 
                       targetServKey, targetName, targetLevel)
            
            # 删除目标区角色数据（通过目标区的 storage 服务）
            # 注意：这里需要连接目标区的数据库，但当前 handler 只能访问本区
            # 所以我们只清理 Account.role_infos，实际角色数据由 daemon 在执行时删除
            
            # 清理 Account.role_infos
            yield dbcAccount.call_async('DBUpdate', 'Account', role.account_id, {
                '$unset': {'role_infos.%s' % targetServKey: ''}
            }, False)
            
            logger.info('TransferDeleteTarget: Account.role_infos cleared for %s', targetServKey)
            
            self.write({'view': {
                'success': True,
                'message': '已清理目标区角色记录，请等待5秒后重新检查',
                'deleted': True,
                'deletedRole': {
                    'name': targetName,
                    'level': targetLevel
                }
            }})
            
        except ClientError:
            raise
        except Exception as e:
            logger.error('TransferDeleteTarget error: %s', e)
            raise ClientError('删除失败: %s' % str(e))


# ==============================================================================
# 邀请转区接口（目标区会长/副会长调用）
# ==============================================================================

# /game/transfer/invite/info - 获取邀请权限和列表
class TransferInviteInfo(RequestHandlerTask):
    url = r'/game/transfer/invite/info'

    @coroutine
    def run(self):
        role = self.game.role
        
        # 检查公会
        if not role.union_db_id:
            self.write({'view': {
                'hasPermission': False,
                'reason': '您还没有加入公会'
            }})
            return
        
        # 检查职位
        isChairman = role.isUnionChairman()
        isViceChairman = role.isUnionViceChairman()
        if not isChairman and not isViceChairman:
            self.write({'view': {
                'hasPermission': False,
                'reason': '只有会长和副会长可以邀请玩家转区'
            }})
            return
        
        # 检查公会排名（是否第一名）
        try:
            unions = yield self.rpcUnion.call_async('GetRankList', 0, 1)
            if not unions or len(unions) == 0:
                self.write({'view': {
                    'hasPermission': False,
                    'reason': '公会排行榜数据异常'
                }})
                return
            
            topUnion = unions[0]
            topUnionId = topUnion.get('id')
            
            if role.union_db_id != topUnionId:
                self.write({'view': {
                    'hasPermission': False,
                    'reason': '只有排行榜第一公会的会长/副会长可以邀请',
                    'yourUnionRank': '非第一名'
                }})
                return
        except Exception as e:
            logger.error('TransferInviteInfo GetRankList error: %s', e)
            self.write({'view': {
                'hasPermission': False,
                'reason': '获取公会排名失败'
            }})
            return
        
        # 获取本月名额使用情况
        currentMonth = getCurrentMonth()
        try:
            ret = yield self.dbcGame.call_async('DBReadBy', 'TransferInvite', {
                'target_area': role.area,
                'month': currentMonth
            })
            invites = ret.get('models', []) if ret.get('ret') else []
            
            # 统计占用名额的邀请
            usedQuota = 0
            inviteList = []
            for inv in invites:
                status = inv.get('status', '')
                if status in ('pending', 'accepted', 'completed'):
                    usedQuota += 1
                inviteList.append({
                    'id': idToStr(inv.get('id', '')),
                    'invitee_uid': inv.get('invitee_uid'),
                    'invitee_name': inv.get('invitee_name', ''),
                    'invitee_area': inv.get('invitee_area'),
                    'invitee_level': inv.get('invitee_level', 0),
                    'invitee_fighting_point': inv.get('invitee_fighting_point', 0),
                    'status': status,
                    'create_time': inv.get('create_time', 0),
                    'expire_time': inv.get('expire_time', 0)
                })
        except Exception as e:
            logger.error('TransferInviteInfo query invites error: %s', e)
            invites = []
            usedQuota = 0
            inviteList = []
        
        cfg = getTransferConfig()
        inviteQuota = getInviteQuota(cfg) if cfg else 10
        
        unionName = self.game.union.name if self.game.union else ''
        position = '会长' if isChairman else '副会长'
        
        self.write({'view': {
            'hasPermission': True,
            'unionName': unionName,
            'unionRank': 1,
            'position': position,
            'monthQuota': inviteQuota,
            'usedQuota': usedQuota,
            'remainQuota': inviteQuota - usedQuota,
            'inviteList': inviteList
        }})


# /game/transfer/invite/send - 发送邀请
# /game/transfer/invite/query - 查询玩家信息（根据UID和区号）
class TransferInviteQuery(RequestHandlerTask):
    url = r'/game/transfer/invite/query'

    @coroutine
    def run(self):
        role = self.game.role
        queryUid = self.input.get('uid')
        queryArea = self.input.get('area')
        
        if queryUid is None or queryArea is None:
            raise ClientError('请输入UID和区号')
        
        queryUid = int(queryUid)
        queryArea = int(queryArea)
        
        if queryArea == role.area:
            raise ClientError('不能查询本区玩家')
        
        # 权限检查（只有会长/副会长才能查询）
        if not role.union_db_id:
            raise ClientError('您还没有加入公会')
        
        isChairman = role.isUnionChairman()
        isViceChairman = role.isUnionViceChairman()
        if not isChairman and not isViceChairman:
            raise ClientError('只有会长和副会长可以查询')
        
        # 跨区查询玩家信息
        playerInfo = None
        
        try:
            # 获取目标区的 storage 连接
            storageKey = 'storage.cn.%d' % queryArea
            dbcTarget = self.server.container.getserviceOrCreate(storageKey)
            
            ret = yield dbcTarget.call_async('DBReadBy', 'Role', {'uid': queryUid})
            if ret.get('ret') and ret.get('models') and len(ret['models']) > 0:
                targetRole = ret['models'][0]
                playerInfo = {
                    'uid': queryUid,
                    'area': queryArea,
                    'name': targetRole.get('name', ''),
                    'level': targetRole.get('level', 0),
                    'fighting_point': targetRole.get('battle_fighting_point', 0),
                    'found': True
                }
            else:
                playerInfo = {
                    'uid': queryUid,
                    'area': queryArea,
                    'found': False,
                    'message': '未找到该玩家'
                }
        except Exception as e:
            logger.error('TransferInviteQuery error: %s', e)
            playerInfo = {
                'uid': queryUid,
                'area': queryArea,
                'found': False,
                'message': '查询失败，请检查区号是否正确'
            }
        
        self.write({'view': {
            'player': playerInfo
        }})


class TransferInviteSend(RequestHandlerTask):
    url = r'/game/transfer/invite/send'

    @coroutine
    def run(self):
        role = self.game.role
        inviteeUid = self.input.get('invitee_uid')
        inviteeArea = self.input.get('invitee_area')
        
        logger.info('[InviteSend] 开始: uid=%s, area=%s, inviter=%s', inviteeUid, inviteeArea, role.name)
        
        if inviteeUid is None or inviteeArea is None:
            raise ClientError('参数不完整')
        
        inviteeUid = int(inviteeUid)
        inviteeArea = int(inviteeArea)
        
        # 不能邀请本区玩家
        if inviteeArea == role.area:
            raise ClientError('不能邀请本区玩家')
        
        # 权限检查
        if not role.union_db_id:
            raise ClientError('您还没有加入公会')
        
        isChairman = role.isUnionChairman()
        isViceChairman = role.isUnionViceChairman()
        logger.info('[InviteSend] 权限检查: isChairman=%s, isViceChairman=%s', isChairman, isViceChairman)
        if not isChairman and not isViceChairman:
            raise ClientError('只有会长和副会长可以邀请')
        
        # 检查公会排名
        try:
            unions = yield self.rpcUnion.call_async('GetRankList', 0, 1)
            logger.info('[InviteSend] 公会排名: unions=%s', unions)
            if not unions or len(unions) == 0:
                raise ClientError('公会排行榜数据异常')
            
            topUnionId = unions[0].get('id')
            logger.info('[InviteSend] 第一公会ID=%s, 我的公会ID=%s', topUnionId, role.union_db_id)
            if role.union_db_id != topUnionId:
                raise ClientError('只有排行榜第一公会才能邀请')
        except ClientError:
            raise
        except Exception as e:
            logger.error('TransferInviteSend GetRankList error: %s', e)
            raise ClientError('获取公会排名失败')
        
        # 检查名额
        currentMonth = getCurrentMonth()
        try:
            ret = yield self.dbcGame.call_async('DBReadBy', 'TransferInvite', {
                'target_area': role.area,
                'month': currentMonth
            })
            invites = ret.get('models', []) if ret.get('ret') else []
            
            usedQuota = 0
            for inv in invites:
                status = inv.get('status', '')
                if status in ('pending', 'accepted', 'completed'):
                    usedQuota += 1
                    # 检查是否已邀请过该玩家（pending 状态）
                    if status == 'pending' and inv.get('invitee_uid') == inviteeUid and inv.get('invitee_area') == inviteeArea:
                        raise ClientError('已邀请过该玩家，请等待对方响应')
            
            cfg = getTransferConfig()
            inviteQuota = getInviteQuota(cfg) if cfg else 10
            
            if usedQuota >= inviteQuota:
                raise ClientError('本月邀请名额已用完')
        except ClientError:
            raise
        except Exception as e:
            logger.error('TransferInviteSend check quota error: %s', e)
            raise ClientError('检查名额失败')
        
        # 跨区查询被邀请人信息
        inviteeName = '玩家%d' % inviteeUid
        inviteeLevel = 0
        inviteeFightingPoint = 0
        
        try:
            storageKey = 'storage.cn.%d' % inviteeArea
            dbcTarget = self.server.container.getserviceOrCreate(storageKey)
            
            ret = yield dbcTarget.call_async('DBReadBy', 'Role', {'uid': inviteeUid})
            if ret.get('ret') and ret.get('models') and len(ret['models']) > 0:
                targetRole = ret['models'][0]
                inviteeName = targetRole.get('name', '') or ('玩家%d' % inviteeUid)
                inviteeLevel = targetRole.get('level', 0)
                inviteeFightingPoint = targetRole.get('battle_fighting_point', 0)
            else:
                raise ClientError('未找到该玩家，请检查UID和区号')
        except ClientError:
            raise
        except Exception as e:
            logger.error('TransferInviteSend query invitee error: %s', e)
            raise ClientError('查询玩家信息失败，请检查区号是否正确')
        
        # 创建邀请记录
        cfg = getTransferConfig()
        expireSeconds = getInviteExpireSeconds(cfg) if cfg else 3 * 24 * 3600
        
        now = time.time()
        inviteData = {
            'inviter_role_id': role.id,
            'inviter_name': role.name,
            'inviter_union_id': role.union_db_id,
            'inviter_union_name': self.game.union.name if self.game.union else '',
            'target_area': role.area,
            'invitee_uid': inviteeUid,
            'invitee_name': inviteeName,
            'invitee_area': inviteeArea,
            'invitee_level': inviteeLevel,
            'invitee_fighting_point': inviteeFightingPoint,
            'status': 'pending',
            'create_time': now,
            'expire_time': now + expireSeconds,
            'month': currentMonth
        }
        
        logger.info('[InviteSend] 准备创建邀请记录: %s', inviteData)
        
        try:
            ret = yield self.dbcGame.call_async('DBCreate', 'TransferInvite', inviteData)
            logger.info('[InviteSend] DBCreate 结果: %s', ret)
            if not ret.get('ret'):
                raise ClientError('创建邀请记录失败: %s' % ret.get('err', ''))
            inviteId = ret['model']['id']
        except ClientError:
            raise
        except Exception as e:
            logger.error('TransferInviteSend create invite error: %s', e)
            import traceback
            logger.error(traceback.format_exc())
            raise ClientError('创建邀请失败')
        
        logger.info('TransferInviteSend: %s invited uid=%d area=%d, inviteId=%s',
                   role.name, inviteeUid, inviteeArea, inviteId)
        
        self.write({'view': {
            'success': True,
            'invitee_name': inviteeName,
            'invitee_level': inviteeLevel,
            'message': '邀请已发送'
        }})


# /game/transfer/invite/cancel - 撤销邀请
class TransferInviteCancel(RequestHandlerTask):
    url = r'/game/transfer/invite/cancel'

    @coroutine
    def run(self):
        role = self.game.role
        inviteId = self.input.get('invite_id')
        
        if not inviteId:
            raise ClientError('参数不完整')
        
        # 权限检查
        if not role.union_db_id:
            raise ClientError('您还没有加入公会')
        
        isChairman = role.isUnionChairman()
        isViceChairman = role.isUnionViceChairman()
        if not isChairman and not isViceChairman:
            raise ClientError('只有会长和副会长可以撤销邀请')
        
        # 查询邀请
        try:
            inviteOid = strToId(inviteId)
            if not inviteOid:
                raise ClientError('邀请ID无效')
            
            ret = yield self.dbcGame.call_async('DBRead', 'TransferInvite', inviteOid, False)
            if not ret.get('ret') or not ret.get('model'):
                raise ClientError('邀请不存在')
            
            invite = ret['model']
            
            # 检查是否本公会发出的邀请
            if invite.get('inviter_union_id') != role.union_db_id:
                raise ClientError('只能撤销本公会发出的邀请')
            
            # 检查状态
            if invite.get('status') != 'pending':
                raise ClientError('只能撤销等待中的邀请')
            
            # 更新状态
            yield self.dbcGame.call_async('DBUpdate', 'TransferInvite', inviteOid, {
                'status': 'cancelled',
                'respond_time': time.time()
            }, False)
            
        except ClientError:
            raise
        except Exception as e:
            logger.error('TransferInviteCancel error: %s', e)
            raise ClientError('撤销失败')
        
        logger.info('TransferInviteCancel: %s cancelled invite %s', role.name, inviteId)
        
        self.write({'view': {
            'success': True,
            'message': '邀请已撤销'
        }})


# ==============================================================================
# 邀请转区接口（源区玩家调用）
# ==============================================================================

# /game/transfer/invite/list - 查看收到的邀请
class TransferInviteList(RequestHandlerTask):
    url = r'/game/transfer/invite/list'

    @coroutine
    def run(self):
        role = self.game.role
        cfg = getTransferConfig()
        
        if not cfg:
            self.write({'view': {
                'invites': [],
                'reason': '转区功能未开放'
            }})
            return
        
        # 获取可转入的目标区列表
        targetAreas = list(getattr(cfg, 'targetAreas', []) or [])
        
        # 跨区查询所有目标区的邀请（邀请记录存储在目标区数据库）
        invites = []
        fightingPoint = role.top6_fighting_point or 0
        
        logger.info('[InviteList] 开始查询, uid=%d, area=%d, targetAreas=%s', role.uid, role.area, targetAreas)
        
        from tornado.gen import with_timeout
        from datetime import timedelta
        
        for targetArea in targetAreas:
            if targetArea == role.area:
                continue  # 跳过本区
            
            # 跨区查询目标区数据库（带超时）
            try:
                storageKey = 'storage.cn.%d' % targetArea
                dbcTarget = self.server.container.getserviceOrCreate(storageKey)
                
                # 设置 3 秒超时，避免查询不存在的区卡住
                ret = yield with_timeout(
                    timedelta(seconds=3),
                    dbcTarget.call_async('DBReadBy', 'TransferInvite', {
                        'invitee_uid': role.uid,
                        'invitee_area': role.area,
                        'status': 'pending'
                    })
                )
                logger.info('[InviteList] 查询 %d区 结果: ret=%s, count=%d', 
                           targetArea, ret.get('ret'), len(ret.get('models', [])))
                
                if ret.get('ret'):
                    for inv in ret.get('models', []):
                        # 检查是否过期
                        if inv.get('expire_time', 0) < time.time():
                            continue
                        
                        ticketCost = fightingPoint // 1000000
                        invites.append({
                            'id': idToStr(inv.get('id')),
                            'target_area': inv.get('target_area'),
                            'inviter_name': inv.get('inviter_name', ''),
                            'inviter_union_name': inv.get('inviter_union_name', ''),
                            'create_time': inv.get('create_time', 0),
                            'expire_time': inv.get('expire_time', 0),
                            'ticket_cost': ticketCost
                        })
            except Exception as e:
                # 超时或其他错误，跳过该区继续查询其他区
                logger.warning('[InviteList] 查询 %d区 跳过: %s', targetArea, e)
        
        self.write({'view': {
            'invites': invites,
            'fightingPoint': fightingPoint
        }})


# /game/transfer/invite/accept - 接受邀请
class TransferInviteAccept(RequestHandlerTask):
    url = r'/game/transfer/invite/accept'

    @coroutine
    def run(self):
        role = self.game.role
        inviteId = self.input.get('invite_id')
        targetArea = self.input.get('target_area')
        
        if not inviteId or targetArea is None:
            raise ClientError('参数不完整')
        
        targetArea = int(targetArea)
        
        cfg = getTransferConfig()
        if not cfg:
            raise ClientError('转区功能未开放')
        
        # 检查转区条件（复用现有逻辑）
        minLevel = getattr(cfg, 'minLevel', 30) or 30
        if role.level < minLevel:
            raise ClientError('等级不足%d级' % minLevel)
        
        if role.union_db_id:
            raise ClientError('请先退出公会')
        
        # 检查是否有进行中的转区
        try:
            ret = yield self.dbcGame.call_async('DBReadBy', 'TransferRecord', {
                'role_db_id': role.id
            })
            if ret.get('ret'):
                for rec in ret.get('models', []):
                    if rec.get('status') in ('pending', 'processing'):
                        raise ClientError('您已有进行中的转区申请')
        except ClientError:
            raise
        except Exception as e:
            logger.error('TransferInviteAccept check existing error: %s', e)
        
        # 查询邀请（跨区查询目标区数据库）
        try:
            inviteOid = strToId(inviteId)
            if not inviteOid:
                raise ClientError('邀请ID无效')
            
            # 去目标区查询邀请记录
            targetServKey = 'storage.cn.%d' % targetArea
            rpcStorage = self.server.container.getserviceOrCreate(targetServKey)
            if not rpcStorage:
                raise ClientError('目标区服务未启动')
            
            ret = yield rpcStorage.call_async('DBRead', 'TransferInvite', inviteOid, False)
            if not ret.get('ret') or not ret.get('model'):
                raise ClientError('邀请不存在')
            
            invite = ret['model']
            
            # 检查邀请
            if invite.get('status') != 'pending':
                raise ClientError('邀请已失效')
            
            if invite.get('expire_time', 0) < time.time():
                raise ClientError('邀请已过期')
            
            if invite.get('invitee_uid') != role.uid:
                raise ClientError('邀请不是发给您的')
            
        except ClientError:
            raise
        except Exception as e:
            logger.error('TransferInviteAccept query invite error: %s', e)
            raise ClientError('查询邀请失败')
        
        # 实时检查邀请名额是否已满（防止并发导致超额）
        try:
            currentMonth = getCurrentMonth()
            ret = yield rpcStorage.call_async('DBReadBy', 'TransferInvite', {
                'target_area': targetArea,
                'month': currentMonth
            })
            if ret.get('ret'):
                usedQuota = 0
                for inv in ret.get('models', []):
                    # pending/accepted/completed 都占用名额
                    if inv.get('status') in ('pending', 'accepted', 'completed'):
                        usedQuota += 1
                
                inviteQuota = getInviteQuota(cfg)
                if usedQuota > inviteQuota:
                    # 名额已满（当前邀请已占用一个 pending，所以用 > 而不是 >=）
                    raise ClientError('目标区本月邀请名额已满')
        except ClientError:
            raise
        except Exception as e:
            logger.error('TransferInviteAccept check quota error: %s', e)
        
        # 检查目标区是否已有角色（>80级不允许覆盖）
        targetServKey = 'game.cn.%d' % targetArea
        dbcAccount = self.dbcGift
        if dbcAccount:
            try:
                accountRet = yield dbcAccount.call_async('DBRead', 'Account', role.account_id, False)
                if accountRet['ret'] and accountRet.get('model'):
                    accountData = accountRet['model']
                    roleInfos = accountData.get('role_infos', {})
                    if targetServKey in roleInfos:
                        targetRoleInfo = roleInfos[targetServKey]
                        targetId = targetRoleInfo.get('id')
                        targetName = targetRoleInfo.get('name', '') or ''
                        targetLevel = targetRoleInfo.get('level', 0)
                        hasRealRole = bool(targetId) and (targetName or targetLevel > 0)
                        
                        if hasRealRole:
                            if targetLevel > 80:
                                raise ClientError('目标区已有%d级角色「%s」，超过80级无法覆盖' % (targetLevel, targetName))
                            else:
                                logger.info('TransferInviteAccept: target has role %s (lv%d), will be overwritten', 
                                           targetName, targetLevel)
                        else:
                            # 空记录，清理
                            yield dbcAccount.call_async('DBUpdate', 'Account', role.account_id, {
                                '$unset': {'role_infos.%s' % targetServKey: ''}
                            }, False)
            except ClientError:
                raise
            except Exception as e:
                logger.error('TransferInviteAccept check target role error: %s', e)
        
        # 计算费用（邀请转区，使用历史最高前6战力）
        fightingPoint = role.top6_fighting_point or 0
        costMap = calculateTransferCost(cfg, fightingPoint, isInvite=True)
        
        # 扣费
        if costMap:
            cost = ObjectCostAux(self.game, costMap)
            if not cost.isEnough():
                raise ClientError(ErrDefs.costNotEnough)
            cost.cost(src='transfer_invite_accept')
        
        # 更新邀请状态（跨区更新目标区数据库）
        try:
            yield rpcStorage.call_async('DBUpdate', 'TransferInvite', inviteOid, {
                'status': 'accepted',
                'respond_time': time.time()
            }, False)
        except Exception as e:
            logger.error('TransferInviteAccept update invite error: %s', e)
        
        # 创建转区记录
        currentMonth = getCurrentMonth()
        applyTime = nowtime_t()
        recordData = {
            'role_db_id': role.id,
            'uid': role.uid,
            'role_name': role.name,
            'level': role.level,
            'vip_level': role.vip_level,
            'source_area': role.area,
            'target_area': targetArea,
            'account_id': role.account_id,
            'status': 'pending',
            'apply_time': applyTime,
            'execute_time': applyTime + 1800,  # 30分钟后执行
            'cost_info': costMap,
            'progress': 0,
            'progress_msg': '等待执行',
            'transfer_type': 'invite',
            'month': currentMonth,
            'invite_id': inviteOid
        }
        
        try:
            ret = yield self.dbcGame.call_async('DBCreate', 'TransferRecord', recordData)
            if not ret.get('ret'):
                raise ClientError('创建转区记录失败')
            recordId = ret['model']['id']
        except ClientError:
            raise
        except Exception as e:
            logger.error('TransferInviteAccept create record error: %s', e)
            raise ClientError('创建转区记录失败')
        
        # 封禁角色
        try:
            yield self.dbcGame.call_async('DBUpdate', 'Role', role.id, {
                'disable_flag': True
            }, False)
            role.disable_flag = True
        except Exception as e:
            logger.error('TransferInviteAccept set disable_flag error: %s', e)
        
        # 踢下线
        try:
            Session.discardSessionByAccountKey((role.area, role.account_id))
        except Exception as e:
            logger.warning('TransferInviteAccept disconnect error: %s', e)
        
        logger.info('TransferInviteAccept: role=%s uid=%d accepted invite to area %d',
                   role.name, role.uid, targetArea)
        
        self.write({'view': {
            'success': True,
            'message': '已接受邀请，请等待转区完成'
        }})


# /game/transfer/invite/reject - 拒绝邀请
class TransferInviteReject(RequestHandlerTask):
    url = r'/game/transfer/invite/reject'

    @coroutine
    def run(self):
        role = self.game.role
        inviteId = self.input.get('invite_id')
        targetArea = self.input.get('target_area')
        
        if not inviteId or targetArea is None:
            raise ClientError('参数不完整')
        
        targetArea = int(targetArea)
        
        # 跨区查询并更新邀请
        try:
            inviteOid = strToId(inviteId)
            if not inviteOid:
                raise ClientError('邀请ID无效')
            
            # 去目标区查询邀请记录
            targetServKey = 'storage.cn.%d' % targetArea
            rpcStorage = self.server.container.getserviceOrCreate(targetServKey)
            if not rpcStorage:
                raise ClientError('目标区服务未启动')
            
            ret = yield rpcStorage.call_async('DBRead', 'TransferInvite', inviteOid, False)
            if not ret.get('ret') or not ret.get('model'):
                raise ClientError('邀请不存在')
            
            invite = ret['model']
            
            if invite.get('status') != 'pending':
                raise ClientError('邀请已处理')
            
            if invite.get('invitee_uid') != role.uid:
                raise ClientError('邀请不是发给您的')
            
            # 更新状态为拒绝（跨区更新目标区数据库）
            yield rpcStorage.call_async('DBUpdate', 'TransferInvite', inviteOid, {
                'status': 'rejected',
                'respond_time': time.time()
            }, False)
            
        except ClientError:
            raise
        except Exception as e:
            logger.error('TransferInviteReject error: %s', e)
            raise ClientError('拒绝失败')
        
        logger.info('TransferInviteReject: role=%s rejected invite %s', role.name, inviteId)
        
        self.write({'view': {
            'success': True,
            'message': '已拒绝邀请'
        }})


# ==============================================================================
# 自由转区接口
# ==============================================================================

# /game/transfer/free/info - 获取自由转区信息
class TransferFreeInfo(RequestHandlerTask):
    url = r'/game/transfer/free/info'

    @coroutine
    def run(self):
        role = self.game.role
        cfg = getTransferConfig()
        
        if not cfg:
            self.write({'view': {
                'enabled': False,
                'reason': '转区功能未开放'
            }})
            return
        
        # 获取可转入的目标区列表
        targetAreas = list(getattr(cfg, 'targetAreas', []) or [])
        currentMonth = getCurrentMonth()
        
        # 获取配置值
        freeQuota = getFreeQuota(cfg)
        extraCost = getConfigValue(cfg, 'freeExtraCost', 5)
        
        # 查询各目标区的自由名额使用情况
        # 注意：TransferRecord 存储在源区，需要遍历所有区查询 target_area=目标区 的记录
        quotaInfo = {}
        
        # 获取所有活动的存储服务（getservices 直接返回服务对象列表）
        allStorageServices = self.server.container.getservices('^storage')
        logger.info('[FreeInfo] 查询名额, 存储服务数量=%d, 当前月份=%d', len(allStorageServices), currentMonth)
        
        for targetArea in targetAreas:
            if targetArea == role.area:
                continue  # 跳过本区
            
            used = 0
            # 遍历所有区的存储服务，查询 target_area=目标区 的记录
            for rpcStorage in allStorageServices:
                try:
                    if rpcStorage:
                        queryCondition = {
                            'target_area': targetArea,
                            'transfer_type': 'free',
                            'month': currentMonth
                        }
                        ret = yield rpcStorage.call_async('DBReadBy', 'TransferRecord', queryCondition)
                        logger.info('[FreeInfo] 查询 target=%d, ret=%s, models_count=%d', 
                                    targetArea, ret.get('ret'), len(ret.get('models', [])))
                        if ret.get('ret'):
                            for rec in ret.get('models', []):
                                recStatus = rec.get('status')
                                recType = rec.get('transfer_type')
                                recMonth = rec.get('month')
                                logger.info('[FreeInfo] 记录: status=%s, type=%s, month=%s', recStatus, recType, recMonth)
                                if recStatus in ('pending', 'processing', 'completed'):
                                    used += 1
                except Exception as e:
                    logger.warning('[FreeInfo] 查询异常: %s', e)
            
            logger.info('[FreeInfo] 目标区=%d, 已使用名额=%d', targetArea, used)
            quotaInfo[str(targetArea)] = {
                'total': freeQuota,
                'used': used,
                'remain': max(0, freeQuota - used)
            }
        
        # 计算费用（使用历史最高前6战力）
        fightingPoint = role.top6_fighting_point or 0
        baseCost = fightingPoint // 1000000
        totalCost = baseCost + extraCost
        
        self.write({'view': {
            'enabled': True,
            'targetAreas': [a for a in targetAreas if a != role.area],
            'quotaInfo': quotaInfo,
            'cost': {
                'baseCost': extraCost,
                'fightingCost': baseCost,
                'totalCost': totalCost
            },
            'fightingPoint': fightingPoint
        }})


# /game/transfer/free/apply - 申请自由转区
class TransferFreeApply(RequestHandlerTask):
    url = r'/game/transfer/free/apply'

    @coroutine
    def run(self):
        role = self.game.role
        targetArea = self.input.get('target_area')
        
        if targetArea is None:
            raise ClientError('请选择目标区')
        
        targetArea = int(targetArea)
        
        cfg = getTransferConfig()
        if not cfg:
            raise ClientError('转区功能未开放')
        
        # 检查目标区是否可选
        targetAreas = list(getattr(cfg, 'targetAreas', []) or [])
        if targetArea not in targetAreas:
            raise ClientError('目标区不可用')
        
        if targetArea == role.area:
            raise ClientError('不能转到当前区')
        
        # 检查转区条件
        minLevel = getattr(cfg, 'minLevel', 30) or 30
        if role.level < minLevel:
            raise ClientError('等级不足%d级' % minLevel)
        
        if role.union_db_id:
            raise ClientError('请先退出公会')
        
        # 检查转区次数
        maxTimes = getattr(cfg, 'maxTimes', None)
        if maxTimes is None:
            maxTimes = 1
        transferTimes = role.transfer_times or 0
        if maxTimes > 0 and transferTimes >= maxTimes:
            raise ClientError('转区次数已用完')
        
        # 检查冷却期
        cooldownDays = getattr(cfg, 'cooldownDays', None)
        if cooldownDays is None:
            cooldownDays = 30
        lastTransferTime = role.last_transfer_time or 0
        if cooldownDays > 0 and lastTransferTime > 0:
            elapsed = nowtime_t() - lastTransferTime
            if elapsed < cooldownDays * 86400:
                remainDays = int((cooldownDays * 86400 - elapsed) / 86400) + 1
                raise ClientError('冷却中，还需%d天' % remainDays)
        
        # 检查是否有进行中的转区
        try:
            ret = yield self.dbcGame.call_async('DBReadBy', 'TransferRecord', {
                'role_db_id': role.id
            })
            if ret.get('ret'):
                for rec in ret.get('models', []):
                    if rec.get('status') in ('pending', 'processing'):
                        raise ClientError('您已有进行中的转区申请')
        except ClientError:
            raise
        except Exception as e:
            logger.error('TransferFreeApply check existing error: %s', e)
        
        # 检查目标区是否已有角色（>80级不允许覆盖）
        targetServKey = 'game.cn.%d' % targetArea
        dbcAccount = self.dbcGift
        if dbcAccount:
            try:
                accountRet = yield dbcAccount.call_async('DBRead', 'Account', role.account_id, False)
                if accountRet['ret'] and accountRet.get('model'):
                    accountData = accountRet['model']
                    roleInfos = accountData.get('role_infos', {})
                    if targetServKey in roleInfos:
                        targetRoleInfo = roleInfos[targetServKey]
                        targetId = targetRoleInfo.get('id')
                        targetName = targetRoleInfo.get('name', '') or ''
                        targetLevel = targetRoleInfo.get('level', 0)
                        hasRealRole = bool(targetId) and (targetName or targetLevel > 0)
                        
                        if hasRealRole:
                            if targetLevel > 80:
                                raise ClientError('目标区已有%d级角色「%s」，超过80级无法覆盖' % (targetLevel, targetName))
                            else:
                                logger.info('TransferFreeApply: target has role %s (lv%d), will be overwritten', 
                                           targetName, targetLevel)
                        else:
                            # 空记录，清理
                            yield dbcAccount.call_async('DBUpdate', 'Account', role.account_id, {
                                '$unset': {'role_infos.%s' % targetServKey: ''}
                            }, False)
            except ClientError:
                raise
            except Exception as e:
                logger.error('TransferFreeApply check target role error: %s', e)
        
        # 检查目标区自由名额
        # 注意：TransferRecord 存储在源区，需要遍历所有区查询 target_area=目标区 的记录
        currentMonth = getCurrentMonth()
        freeQuota = getFreeQuota(cfg)
        
        used = 0
        try:
            # 获取所有活动的存储服务（getservices 直接返回服务对象列表）
            allStorageServices = self.server.container.getservices('^storage')
            for rpcStorage in allStorageServices:
                try:
                    if rpcStorage:
                        ret = yield rpcStorage.call_async('DBReadBy', 'TransferRecord', {
                            'target_area': targetArea,
                            'transfer_type': 'free',
                            'month': currentMonth
                        })
                        if ret.get('ret'):
                            for rec in ret.get('models', []):
                                if rec.get('status') in ('pending', 'processing', 'completed'):
                                    used += 1
                except Exception:
                    pass  # 跳过查询失败的区
            
            if used >= freeQuota:
                raise ClientError('目标区本月自由名额已满')
        except ClientError:
            raise
        except Exception as e:
            logger.error('TransferFreeApply check quota error: %s', e)
        
        # 计算费用（自由转区，使用历史最高前6战力）
        fightingPoint = role.top6_fighting_point or 0
        costMap = calculateTransferCost(cfg, fightingPoint, isInvite=False)
        
        # 扣费
        if costMap:
            cost = ObjectCostAux(self.game, costMap)
            if not cost.isEnough():
                raise ClientError(ErrDefs.costNotEnough)
            cost.cost(src='transfer_free_apply')
        
        # 创建转区记录（currentMonth 已在前面检查名额时获取）
        applyTime = nowtime_t()
        recordData = {
            'role_db_id': role.id,
            'uid': role.uid,
            'role_name': role.name,
            'level': role.level,
            'vip_level': role.vip_level,
            'source_area': role.area,
            'target_area': targetArea,
            'account_id': role.account_id,
            'status': 'pending',
            'apply_time': applyTime,
            'execute_time': applyTime + 1800,  # 30分钟后执行
            'cost_info': costMap,
            'progress': 0,
            'progress_msg': '等待执行',
            'transfer_type': 'free',
            'month': currentMonth
        }
        logger.info('[FreeApply] 创建记录: target_area=%d, transfer_type=%s, month=%d, source_area=%d',
                    targetArea, 'free', currentMonth, role.area)
        
        try:
            ret = yield self.dbcGame.call_async('DBCreate', 'TransferRecord', recordData)
            if not ret.get('ret'):
                raise ClientError('创建转区记录失败')
            recordId = ret['model']['id']
        except ClientError:
            raise
        except Exception as e:
            logger.error('TransferFreeApply create record error: %s', e)
            raise ClientError('创建转区记录失败')
        
        # 封禁角色
        try:
            yield self.dbcGame.call_async('DBUpdate', 'Role', role.id, {
                'disable_flag': True
            }, False)
            role.disable_flag = True
        except Exception as e:
            logger.error('TransferFreeApply set disable_flag error: %s', e)
        
        # 踢下线
        try:
            Session.discardSessionByAccountKey((role.area, role.account_id))
        except Exception as e:
            logger.warning('TransferFreeApply disconnect error: %s', e)
        
        logger.info('TransferFreeApply: role=%s uid=%d area=%d -> targetArea=%d',
                   role.name, role.uid, role.area, targetArea)
        
        self.write({'view': {
            'success': True,
            'message': '申请成功，请等待转区完成'
        }})

