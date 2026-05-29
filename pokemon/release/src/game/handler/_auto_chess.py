#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
============================================================================
卡牌冒险 PVE模式 (Auto Chess) - HTTP 接口处理器
文档: docs/卡牌冒险PVE模式前端架构文档.md
============================================================================
'''

from __future__ import absolute_import

from tornado.gen import coroutine, Return

from framework import todayinclock5date2int
from framework.csv import csv, ErrDefs
from framework.helper import transform2list
from framework.log import logger
from game import ClientError, ServerError
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain, effectAutoCost
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from game.object.game.auto_chess import (
    _get_trainer_csv, _get_shop_csv,
    _get_achievement_level_csv, _get_handbook_award_csv
)


# ============================================================================
# 辅助函数
# ============================================================================

def _ensureAutoChessInited(game, handler):
    """确保AutoChess已初始化（供外部调用）"""
    return handler._ensureAutoChessInited()

def _getUnlockedTrainers(ac):
    """获取已解锁的训练家字典
    
    前端通过 trainers[id] 是否存在判断解锁状态，只返回已解锁的训练家
    """
    rawTrainers = ac.trainers or {}
    unlockedTrainers = {}
    for tid, tdata in rawTrainers.items():
        if tdata and tdata.get('unlocked', False):
            unlockedTrainers[tid] = tdata
    return unlockedTrainers


def _getHandbookWithAward(ac):
    """获取图鉴数据，确保每个卡牌都有必要字段
    
    前端红点系统会遍历 handbook 检查 award/max_star 字段，老数据可能没有这些字段
    """
    handbook = ac.handbook or {}
    handbook_award = ac.handbook_award or {}
    result = {}
    for cardID, cardData in handbook.items():
        cardInfo = dict(cardData)
        # 确保 award 字段存在
        if 'award' not in cardInfo:
            cardInfo['award'] = {}
        # 确保 max_star 字段存在（前端红点比较需要）
        if 'max_star' not in cardInfo:
            cardInfo['max_star'] = cardInfo.get('star', 1)
        # 确保 star 字段存在
        if 'star' not in cardInfo:
            cardInfo['star'] = 1
        # 同步奖励领取状态
        if cardID in handbook_award:
            cardInfo['award'] = handbook_award[cardID]
        result[cardID] = cardInfo
    return result


def _calculateEndPoints(ac, result, isPvp=False):
    """计算游戏结束积分
    
    【积分规则】（来自游戏规则文档）:
    1. 巅峰对决获胜场次 × 500分，上限1500分
    2. 巅峰对决对敌方训练家造成伤害 × 20分，上限1500分
    3. 野外冒险通关时剩余血量 × 20分，上限1000分
    4. 野外冒险通关时剩余金币 × 10分，上限1000分
    5. 总计积分上限5000分
    
    Returns:
        dict: {pvp_win_point, pvp_damage_point, pve_hp_point, pve_coin_point, special_point, total_point}
    """
    points = {
        'pvp_win_point': 0,
        'pvp_damage_point': 0,
        'pve_hp_point': 0,
        'pve_coin_point': 0,
        'special_point': 0,
        'total_point': 0,
    }
    
    win = result.get('win', False)
    if not win:
        return points  # 失败不给积分
    
    # 获取游戏数据
    finalHp = result.get('final_hp', 0)
    finalGold = result.get('final_gold', 0)
    pvpWinCount = result.get('pvp_win_count', 0)  # 巅峰对决获胜场次
    pvpDamage = result.get('pvp_damage', 0)       # 巅峰对决造成的总伤害
    
    # 1. 巅峰对决获胜场次 × 500分，上限1500分
    points['pvp_win_point'] = min(pvpWinCount * 500, 1500)
    
    # 2. 巅峰对决对敌方训练家造成伤害 × 20分，上限1500分
    points['pvp_damage_point'] = min(pvpDamage * 20, 1500)
    
    # 3. 野外冒险通关时剩余血量 × 20分，上限1000分
    points['pve_hp_point'] = min(finalHp * 20, 1000)
    
    # 4. 野外冒险通关时剩余金币 × 10分，上限1000分
    points['pve_coin_point'] = min(finalGold * 10, 1000)
    
    # 5. 总计积分上限5000分
    totalPoint = (points['pvp_win_point'] + points['pvp_damage_point'] + 
                  points['pve_hp_point'] + points['pve_coin_point'] + 
                  points['special_point'])
    points['total_point'] = min(totalPoint, 5000)
    
    return points


def _buildPvpInfo(ac, areaKey):
    """构建 PVP 信息，包含跨服赛季信息
    
    重要：必须写入 ac.pvp_info，让框架 sync 到前端
    """
    from game.object.game.cross_auto_chess import ObjectCrossAutoChessGameGlobal
    
    pvpInfo = dict(ac.pvp_info or {})
    
    # 确保默认值
    if 'score' not in pvpInfo:
        pvpInfo['score'] = 1000
    if 'grade' not in pvpInfo:
        pvpInfo['grade'] = 1
    if 'top_score' not in pvpInfo:
        pvpInfo['top_score'] = 1000
    if 'win_count' not in pvpInfo:
        pvpInfo['win_count'] = 0
    if 'lose_count' not in pvpInfo:
        pvpInfo['lose_count'] = 0
    if 'win_streak' not in pvpInfo:
        pvpInfo['win_streak'] = 0
    if 'max_win_streak' not in pvpInfo:
        pvpInfo['max_win_streak'] = 0
    
    # 添加赛季信息（从跨服服务获取，1, 2, 3... 格式）
    season = ObjectCrossAutoChessGameGlobal.getSeason(areaKey)
    pvpInfo['season'] = season if season > 0 else 1
    
    # 写入 ac.pvp_info，触发 sync 机制同步到前端
    ac.pvp_info = pvpInfo
    
    return pvpInfo


def _ensureAchievementTasksFormat(ac):
    """确保成就任务数据格式正确，并写入 ac 触发 sync
    
    前端期望格式: {counter: {csvID: progress}, award: {csvID: [status]}}
    """
    tasksData = ac.pvp_achievement_tasks
    
    # 确保格式正确
    if not tasksData or 'counter' not in tasksData:
        tasksData = {'counter': {}, 'award': {}}
    else:
        tasksData = {
            'counter': tasksData.get('counter') or {},
            'award': tasksData.get('award') or {},
        }
    
    # 写入 ac，触发 sync 机制同步到前端
    ac.pvp_achievement_tasks = tasksData
    
    return tasksData


def _ensureSeasonTasksFormat(ac):
    """确保赛季任务数据格式正确，并写入 ac 触发 sync
    
    前端期望格式: {date: {csvID: {counter: num, award: ...}}}
    """
    tasksData = ac.pvp_season_tasks
    
    # 确保格式正确（空字典或已有数据都可以）
    if tasksData is None:
        tasksData = {}
    
    # 写入 ac，触发 sync 机制同步到前端
    ac.pvp_season_tasks = tasksData
    
    return tasksData


def _ensureSeasonInfos(ac, currentSeason):
    """确保赛季信息有当前赛季的数据
    
    前端期望格式: {seasonIdx: {top1: 0, top3: 0, damage_max: 0, card_max: {...}}}
    seasonIdx 是整数 1, 2, 3...
    """
    seasonInfos = dict(ac.pvp_season_infos or {})
    
    # 确保当前赛季有数据
    if currentSeason not in seasonInfos:
        seasonInfos[currentSeason] = {
            'top1': 0,           # 夺冠次数
            'top3': 0,           # 三强次数
            'damage_max': 0,     # 最高伤害
            'card_max': {        # 最大精灵
                'attack': 0,
                'defence': 0,
                'hp': 0,
            },
        }
    
    # 写入 ac，触发 sync 机制同步到前端
    ac.pvp_season_infos = seasonInfos
    
    return seasonInfos


# ============================================================================
# 主界面
# ============================================================================

class AutoChessMain(RequestHandlerTask):
    """获取主界面数据"""
    url = r'/game/auto_chess/main'

    @coroutine
    def run(self):
        online = self.input.get('online', False)

        yield self._ensureAutoChessInited()

        ac = self.game.auto_chess
        role = self.game.role
        areaKey = role.areaKey

        # 检查并清除残留的匹配状态（服务器重启后 Go 队列清空但 DB 状态残留）
        if ac.online and ac.online.get('matching', 0) != 0:
            from game.object.game.cross_auto_chess import ObjectCrossAutoChessGameGlobal
            gameKey = role.areaKey
            is_matching = yield ObjectCrossAutoChessGameGlobal.isMatching(areaKey, gameKey, role.id)
            if not is_matching:
                logger.info('AutoChessMain: Clearing stale matching state for roleID=%s', role.id)
                onlineData = dict(ac.online or {})
                onlineData['matching'] = 0
                ac.online = onlineData
                ac.save_async()

        # 【游戏规则】检查赛季变更，赛季变化时重置 saodang_counter
        from game.object.game.cross_auto_chess import ObjectCrossAutoChessGameGlobal
        currentSeason = ObjectCrossAutoChessGameGlobal.getSeason(areaKey) or 1
        lastSeason = ac.csv_id or 0  # csv_id 存储上次的赛季ID
        if currentSeason != lastSeason:
            logger.info('auto_chess: season changed %s -> %s, resetting saodang_counter', lastSeason, currentSeason)
            ac.saodang_counter = 0
            ac.csv_id = currentSeason

        # 构建返回数据
        view = self._buildMainView()
        self.write({'view': view})

    @coroutine
    def _ensureAutoChessInited(self):
        """确保AutoChess数据已初始化
        
        与 Mimicry 相同模式：首次进入功能时才创建记录
        """
        ac = self.game.auto_chess
        role = self.game.role
        
        # 首次进入时创建 AutoChess 记录
        if getattr(role, 'auto_chess_db_id', None) is None:
            # 从CSV获取默认训练家
            defaultTrainer = self._getDefaultTrainer()
            recordData = yield self.dbcGame.call_async('DBCreate', 'AutoChess', {
                'role_db_id': role.id,
                'trainer': defaultTrainer,
                'newbie_guide': [],  # 新手教程进度（空=未完成）
                'round': 'closed',  # 活动状态由跨服服务控制
            })
            if not recordData['ret']:
                raise ServerError('db create auto_chess record error')
            role.auto_chess_db_id = recordData['model']['id']
            ac.set(recordData['model']).init()
        elif not ac.inited:
            # 已有记录但未加载，读取数据
            recordData = yield self.dbcGame.call_async('DBRead', 'AutoChess', role.auto_chess_db_id, False)
            if not recordData['ret']:
                raise ServerError('db read auto_chess record error')
            ac.set(recordData['model']).init()
        
        # 活动状态由 ObjectCrossAutoChessGameGlobal 控制
        # 游戏次数由 _ensureDefaults 根据 base.csv 初始化
    
    def _getDefaultTrainer(self):
        """从CSV获取默认训练家（unlockType == 0 的第一个）"""
        if hasattr(csv, 'auto_chess') and hasattr(csv.auto_chess, 'trainer'):
            for tid in sorted(csv.auto_chess.trainer.keys()):
                cfg = csv.auto_chess.trainer[tid]
                unlockType = getattr(cfg, 'unlockType', 0)
                if unlockType == 0:
                    return tid
        raise ServerError('no default trainer found in csv (unlockType == 0)')

    def _buildMainView(self):
        from game.object.game.cross_auto_chess import ObjectCrossAutoChessGameGlobal

        ac = self.game.auto_chess
        areaKey = self.game.role.areaKey

        # 获取跨服活动状态（参考 cross_arena / cross_fishing）
        pvpRound = ObjectCrossAutoChessGameGlobal.getRound(areaKey) or 'closed'
        pvpEndDate = ObjectCrossAutoChessGameGlobal.getEndDate(areaKey) or 0

        # 合并跨服状态到 online 字段（前端期望 online 包含 round 和 end_date）
        # 重要：必须写入 ac.online，让框架 sync 到前端，否则前端读取的是旧数据
        onlineData = dict(ac.online or {})
        onlineData['round'] = pvpRound
        onlineData['end_date'] = pvpEndDate
        # 确保其他字段有默认值
        if 'matching' not in onlineData:
            onlineData['matching'] = 0
        if 'room_id' not in onlineData:
            onlineData['room_id'] = ''
        if 'room_address' not in onlineData:
            onlineData['room_address'] = ''
        if 'trainer_id' not in onlineData:
            onlineData['trainer_id'] = 0
        # 写入 ac.online，触发 sync 机制同步到前端
        ac.online = onlineData

        # PVE 和 PVP 共用活动周期，从跨服全局状态获取
        pveRound = pvpRound  # 共用同一个活动状态
        pveEndDate = pvpEndDate  # 共用同一个结束时间

        # 同步跨服状态到玩家数据（前端通过 sync 机制读取）
        if ac.round != pveRound:
            ac.round = pveRound
        if ac.end_date != pveEndDate:
            ac.end_date = pveEndDate

        view = {
            # 训练家系统
            'trainer': ac.trainer,
            'trainers': _getUnlockedTrainers(ac),
            'rank_trainers': ac.rank_trainers or [],
            # 赛季状态（PVE）- 与 PVP 共用活动周期
            'round': pveRound,
            'csv_id': ac.csv_id or 0,
            'servers': ac.servers or [],
            'end_date': pveEndDate,
            # 游戏次数
            'times': ac.times or 0,
            'free_times': ac.free_times or 0,
            'last_date': ac.last_date or 0,
            # 游戏状态
            'in_game': ac.in_game or False,
            'game_type': ac.game_type or 0,
            # 扫荡
            'saodang_counter': ac.saodang_counter or 0,
            # 新手引导进度
            'newbie_guide': ac.newbie_guide or [],
            # 成就系统
            'achievement_points': ac.achievement_points or 0,
            'achievement_tasks': ac.achievement_tasks or {},
            'achievement_box_awards': ac.achievement_box_awards or [],
            'achievement_counter': ac.achievement_counter or {},
            # 图鉴（确保每个卡牌都有 award 字段，避免前端红点系统报错）
            'handbook': _getHandbookWithAward(ac),
            'handbook_award': ac.handbook_award or {},
            # 商城
            'shop_buy_counter': ac.shop_buy_counter or {},
            # 历史记录
            'normal_max_chapter': ac.normal_max_chapter or 0,
            'normal_type_win_streak': ac.normal_type_win_streak or 0,
            'normal_max_win_streak': ac.normal_max_win_streak or 0,
            'total_games': ac.total_games or 0,
            'total_wins': ac.total_wins or 0,
            # 签到
            'sign_in_days': ac.sign_in_days or 0,
            'last_sign_in_date': ac.last_sign_in_date or 0,
            # ========== PVP系统（跨服在线对战） ==========
            'pvp_info': _buildPvpInfo(ac, areaKey),
            'pvp_grade_award': ac.pvp_grade_award or {},
            'pvp_history': ac.pvp_history or [],
            # 前端期望 season 是简单整数 1, 2, 3...
            'pvp_season_infos': _ensureSeasonInfos(ac, ObjectCrossAutoChessGameGlobal.getSeason(areaKey) or 1),
            # pvp_season_tasks 格式: {date: {csvID: {counter: num, award: ...}}}
            'pvp_season_tasks': _ensureSeasonTasksFormat(ac),
            # pvp_achievement_tasks 格式: {counter: {csvID: progress}, award: {csvID: [status]}}
            'pvp_achievement_tasks': _ensureAchievementTasksFormat(ac),
            # online 包含匹配状态 + 跨服活动状态
            'online': onlineData,
            # battle 战斗房间状态
            'battle': {
                'address': onlineData.get('room_address', ''),
                'room_id': onlineData.get('room_id', ''),
            },
        }
        return view


# ============================================================================
# 游戏流程
# ============================================================================

class AutoChessStart(RequestHandlerTask):
    """开始新游戏"""
    url = r'/game/auto_chess/start'

    @coroutine
    def run(self):
        trainer = self.input.get('trainer', 1)
        typ = self.input.get('typ', 2)  # 1=休闲, 2=普通

        yield self._ensureAutoChessInited()
        ac = self.game.auto_chess

        # 开始游戏
        battle_data = ac.startGame(trainer, typ)

        # 前端通过 t.model.chess_play 初始化 gGameModel.battle
        # 参考 game.lua REQUIRE_BATTLE 列表，必须包装在 model 中
        self.write({
            'model': {
                'chess_play': battle_data,
            },
            'times': ac.times,
            'free_times': ac.free_times,
            'in_game': ac.in_game,
        })

    @coroutine
    def _ensureAutoChessInited(self):
        """确保AutoChess数据已初始化（必须先访问 main 接口创建记录）"""
        role = self.game.role
        if getattr(role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')
        
        ac = self.game.auto_chess
        if not ac.inited:
            recordData = yield self.dbcGame.call_async('DBRead', 'AutoChess', role.auto_chess_db_id, False)
            if not recordData['ret']:
                raise ServerError('db read auto_chess record error')
            ac.set(recordData['model']).init()


class AutoChessInput(RequestHandlerTask):
    """同步游戏操作（帧同步）
    
    注意：
    - 正常游戏中，只同步状态，不返回数据（return None）
    - 放弃游戏时（giveup=True），调用 endGame 并返回结算数据
    - 放弃时的奖励在这里发放，而不是等待 /end 接口
    """
    url = r'/game/auto_chess/input'

    @coroutine
    def run(self):
        if getattr(self.game.role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')

        inputs = self.input.get('inputs', [])
        checksum = self.input.get('checksum', 0)
        randcnt = self.input.get('randcnt', 0)
        frame = self.input.get('frame', 0)
        giveup = self.input.get('giveup', False)
        stateset = self.input.get('stateset')

        ac = self.game.auto_chess
        if not ac.in_game:
            raise ClientError('not in game')

        result = ac.syncInput(inputs, checksum, randcnt, frame, giveup, stateset)
        
        # 如果是放弃游戏，需要发放奖励
        if giveup and result:
            awards = result.get('awards', {})
            if awards:
                eff = ObjectGainAux(self.game, awards)
                yield effectAutoGain(eff, self.game, self.dbcGame, src='auto_chess_giveup')
                logger.info('auto_chess: giveup rewards gained: %s', awards)
        
        self.write(result)


class AutoChessRecover(RequestHandlerTask):
    """断线重连，恢复游戏"""
    url = r'/game/auto_chess/recover'

    @coroutine
    def run(self):
        if getattr(self.game.role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')

        ac = self.game.auto_chess
        if not ac.in_game:
            raise ClientError('not in game')

        result = ac.recoverGame()
        # 前端通过 t.model.chess_play 初始化 gGameModel.battle
        self.write({
            'model': {
                'chess_play': result,
            }
        })


class AutoChessEnd(RequestHandlerTask):
    """游戏结束结算
    
    PVE战斗完全在客户端进行，后端从 stateset 解析战斗结果并发放奖励。
    前端 end_accounts.lua 期望的字段:
    - pve_pass: 是否通关
    - exp: 经验值
    - pvp_win_point/pvp_damage_point: PVP积分
    - pve_hp_point/pve_coin_point: PVE积分
    - special_point: 特殊积分
    - awards: 奖励列表 {itemID: count, ...}
    - trainer: 训练家ID
    - monsters: [] (前端从 gGameModel.battle 获取)
    """
    url = r'/game/auto_chess/end'

    @coroutine
    def run(self):
        from framework.csv import MergeServ
        from game.object.game.cross_auto_chess import ObjectCrossAutoChessGameGlobal

        if getattr(self.game.role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')

        ac = self.game.auto_chess
        trainerID = ac.trainer
        
        # 从前端获取游戏结束数据（用于图鉴激活）
        endData = self.input.get('endData', {})
        win = self.input.get('win', False)
        chapter = self.input.get('chapter', 0)
        
        logger.info('auto_chess: end handler input - win=%s, chapter=%s, endData keys=%s', 
                   win, chapter, endData.keys() if endData else 'empty')
        
        # 结束游戏，从 stateset 解析战斗结果并发放奖励
        result = ac.endGame(win=win, chapter=chapter, endData=endData)
        
        # 普通模式连胜计数（用于勋章统计）
        if win:
            self.game.role.auto_chess_normal_type_win_streak = (self.game.role.auto_chess_normal_type_win_streak or 0) + 1
        else:
            self.game.role.auto_chess_normal_type_win_streak = 0  # 失败重置连胜
        
        # 发放奖励（ObjectGainAux 会处理 libs 等特殊字段）
        awards = result.get('awards', {})
        awardsList = []
        
        if awards:
            eff = ObjectGainAux(self.game, awards)
            yield effectAutoGain(eff, self.game, self.dbcGame, src='auto_chess_end')
            logger.info('auto_chess: end original awards: %s', awards)
            
            # 获取处理后的完整奖励（包括从 libs 抽取的道具）
            processedAwards = eff.result
            logger.info('auto_chess: end processed awards (after libs): %s', processedAwards)
            
            # 将奖励转换为前端期望的格式 {itemID: count} -> [{key: itemID, num: count}, ...]
            # 注意：跳过特殊字段和数据库ID字段
            for itemID, count in processedAwards.items():
                # 跳过特殊字段（libs, card, cards等）
                if itemID in ('libs', 'card', 'cards', 'star_skill_points'):
                    continue
                # 跳过数据库ID字段（这些是后端内部使用的）
                if itemID in ('carddbIDs', 'heldItemdbIDs', 'gemdbIDs', 'chipdbIDs', 'emeradbIDs', 'contractdbIDs', 'card2fragL', 'card2mailL', 'regainD'):
                    continue
                # 只返回普通道具和货币（值是整数的）
                if isinstance(count, int):
                    awardsList.append({'key': itemID, 'num': count})
            
            logger.info('auto_chess: end display awards: %s', awardsList)

        # 计算本次游戏结算积分
        points = _calculateEndPoints(ac, result, isPvp=False)
        totalPoint = points.get('total_point', 0)
        
        # 更新历史最高分（用于排行榜）
        if totalPoint > (ac.pve_best_score or 0):
            ac.pve_best_score = totalPoint
            logger.info('auto_chess: new best score %s', totalPoint)
        
        # 上报积分到跨服服务（如果活动开启且有积分）
        areaKey = self.game.role.areaKey
        # 只有积分 > 0 才上报（避免把积分为0的玩家放入排行榜）
        if ObjectCrossAutoChessGameGlobal.isOpen(areaKey) and (ac.pve_best_score or 0) > 0:
            role = self.game.role
            # 获取训练家等级和技能
            trainers = ac.trainers or {}
            trainerData = trainers.get(trainerID, {})
            trainerLevel = trainerData.get('level', 1)
            
            # 获取训练家第一个技能ID（从配置表）
            trainerSkillID = 0
            if hasattr(csv, 'auto_chess') and hasattr(csv.auto_chess, 'trainer'):
                if trainerID in csv.auto_chess.trainer:
                    trainerCfg = csv.auto_chess.trainer[trainerID]
                    skillsDict = getattr(trainerCfg, 'skills', {}) or {}
                    if skillsDict:
                        trainerSkillID = list(skillsDict.keys())[0]  # 取第一个技能
            
            roleInfo = {
                'role_id': role.id,
                'game_key': areaKey,  # 前端排行榜需要
                'role_info': {
                    'role_id': role.id,
                    'name': role.name,
                    'game_key': areaKey,  # 前端排行榜需要
                    'serv_id': self.server.servID,
                    'serv_name': self.server.servName,
                    'level': role.level,
                    'logo': role.logo,
                    'frame': role.frame,  # 前端字段名
                    'logo_frame': role.frame,  # 兼容旧字段名
                    'vip_level': role.vip_level,
                    'fight_value': role.battle_fighting_point,
                    'union_name': self.game.union.name if self.game.union else '',
                    'union_badge': self.game.union.badge if self.game.union else 0,
                    'card_skin_bag': [],
                },
                'achievement_points': ac.achievement_points or 0,  # 成就点数
                'pve_best_score': ac.pve_best_score or 0,  # 排行榜积分（单次游戏最高分）
                'max_floor': ac.normal_max_chapter or 0,
                # 排行榜查看功能需要的阵容数据
                'trainer': trainerID,
                'trainer_level': trainerLevel,
                'trainer_skill': trainerSkillID,
                'deployments': ac._parseDeploymentsFromStateSet(ac._last_stateset) if hasattr(ac, '_last_stateset') and ac._last_stateset else [],
            }
            yield ObjectCrossAutoChessGameGlobal.updatePveScore(areaKey, roleInfo)
        
        # 返回前端 end_accounts.lua 期望的数据结构
        self.write({
            'view': {
                'trainer': trainerID,
                'monsters': [],  # 前端从 gGameModel.battle 获取
                'pve_pass': result.get('win', False),
                'exp': result.get('exp', 0),
                'pvp_win_point': points['pvp_win_point'],
                'pvp_damage_point': points['pvp_damage_point'],
                'pve_hp_point': points['pve_hp_point'],
                'pve_coin_point': points['pve_coin_point'],
                'special_point': points['special_point'],
                'awards': awardsList,
                'trainers': _getUnlockedTrainers(ac),
                'total_games': ac.total_games,
                'total_wins': ac.total_wins,
                'normal_type_win_streak': ac.normal_type_win_streak,
                'normal_max_win_streak': ac.normal_max_win_streak,
                'normal_max_chapter': ac.normal_max_chapter,
                'in_game': ac.in_game,
            }
        })


# ============================================================================
# 扫荡
# ============================================================================

class AutoChessSaodang(RequestHandlerTask):
    """扫荡
    
    前端 sweep_detail.lua 期望返回:
    {view: {csvID: 档次ID, saodang_counter: ..., times: ..., awards: {...}}}
    
    【游戏规则】
    - 每次扫荡消耗钻石（从 cost.csv autochess_saodang_cost 获取）
    - 钻石消耗根据 saodang_counter 递增
    - 赛季结束时重置 saodang_counter
    """
    url = r'/game/auto_chess/saodang'

    @coroutine
    def run(self):
        if getattr(self.game.role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')

        ac = self.game.auto_chess

        # 检查扫荡条件
        can, reason = ac.canSaodang()
        if not can:
            raise ClientError(reason)

        # 计算钻石消耗（根据 saodang_counter 从 cost.csv 获取）
        saodangCounter = ac.saodang_counter or 0
        costList = []
        if hasattr(csv, 'cost') and 'autochess_saodang_cost' in csv.cost:
            costCfg = csv.cost['autochess_saodang_cost']
            # cost.csv 的 value 字段是列表
            costList = getattr(costCfg, 'value', []) or []
        
        # 根据 saodang_counter 获取消耗（索引从0开始，但前端用 counter+1）
        # 如果超出范围，使用最后一个值
        if costList:
            costIndex = min(saodangCounter, len(costList) - 1)
            rmbCost = costList[costIndex]
        else:
            rmbCost = 50  # 默认值
        
        logger.info('auto_chess saodang: counter=%s, rmbCost=%s', saodangCounter, rmbCost)
        
        # 检查钻石是否足够
        if self.game.role.rmb < rmbCost:
            raise ClientError('rmb not enough')
        
        # 扣除钻石
        self.game.role.rmb -= rmbCost
        logger.info('auto_chess saodang: deducted %s rmb, remaining=%s', rmbCost, self.game.role.rmb)

        # 执行扫荡
        result = ac.doSaodang()

        # 发放奖励（ObjectGainAux 会处理 libs 等特殊字段）
        awards = result.get('awards', {})
        awardsForDisplay = {}
        
        if awards:
            eff = ObjectGainAux(self.game, awards)
            yield effectAutoGain(eff, self.game, self.dbcGame, src='auto_chess_saodang')
            logger.info('auto_chess: saodang original awards: %s', awards)
            
            # 获取处理后的完整奖励（包括从 libs 抽取的道具）
            # eff.result 包含了 imOpenRandGift2item() 处理后的所有道具
            processedAwards = eff.result
            logger.info('auto_chess: saodang processed awards (after libs): %s', processedAwards)
            
            # 将奖励转换为前端期望的格式
            # 注意：跳过特殊字段和数据库ID字段
            for itemID, count in processedAwards.items():
                # 跳过特殊字段（libs, card, cards等）
                if itemID in ('libs', 'card', 'cards', 'star_skill_points'):
                    continue
                # 跳过数据库ID字段（这些是后端内部使用的）
                if itemID in ('carddbIDs', 'heldItemdbIDs', 'gemdbIDs', 'chipdbIDs', 'emeradbIDs', 'contractdbIDs', 'card2fragL', 'card2mailL', 'regainD'):
                    continue
                # 只返回普通道具和货币（值是整数的）
                if isinstance(count, int):
                    awardsForDisplay[itemID] = count
        
        logger.info('auto_chess: saodang display awards: %s', awardsForDisplay)

        # 返回格式包含 view 包装
        # sweep_detail.lua 使用 tb.view.csvID
        # sweep.lua 使用 tb.view.csvID 和 tb.view.result
        self.write({
            'view': {
                'csvID': result.get('csvID', 1),
                'saodang_counter': result.get('saodang_counter', 0),
                'times': result.get('times', 0),
                'result': awardsForDisplay,  # sweep.lua 期望 result 字段
            }
        })


# ============================================================================
# 新手引导
# ============================================================================

class AutoChessNewbieGuide(RequestHandlerTask):
    """完成新手引导步骤"""
    url = r'/game/auto_chess/guide/newbie'

    @coroutine
    def run(self):
        if getattr(self.game.role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')

        guideID = self.input.get('guideID')
        if guideID is None:
            raise ClientError('param miss')

        ac = self.game.auto_chess
        ac.completeGuide(guideID)

        self.write({
            'newbie_guide': ac.newbie_guide,
        })


# ============================================================================
# 训练家
# ============================================================================

class AutoChessTrainerSwitch(RequestHandlerTask):
    """切换训练家"""
    url = r'/game/auto_chess/trainer/switch'

    @coroutine
    def run(self):
        if getattr(self.game.role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')

        trainer = self.input.get('trainer')
        if trainer is None:
            raise ClientError('param miss')

        ac = self.game.auto_chess

        # 检查训练家是否解锁
        if not ac.isTrainerUnlocked(trainer):
            raise ClientError('trainer not unlocked')

        ac.switchTrainer(trainer)

        self.write({
            'trainer': ac.trainer,
        })


class AutoChessTrainerUnlock(RequestHandlerTask):
    """解锁训练家"""
    url = r'/game/auto_chess/trainer/unlock'

    @coroutine
    def run(self):
        if getattr(self.game.role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')

        trainer = self.input.get('trainer')
        if trainer is None:
            raise ClientError('param miss')

        ac = self.game.auto_chess

        # 检查是否已解锁
        if ac.isTrainerUnlocked(trainer):
            raise ClientError('trainer already unlocked')

        # 检查解锁条件
        can_unlock, reason = ac.checkTrainerUnlockCondition(trainer, self.game)
        if not can_unlock:
            raise ClientError(reason or 'unlock condition not met')

        # 检查解锁消耗
        cost = ac.getTrainerUnlockCost(trainer)
        if cost:
            costAux = ObjectCostAux(self.game, cost)
            if not costAux.isEnough():
                raise ClientError(ErrDefs.costNotEnough)
            yield effectAutoCost(costAux, self.game, self.dbcGame, src='auto_chess_trainer_unlock')

        # 解锁训练家
        ac.unlockTrainer(trainer)

        self.write({
            'trainers': _getUnlockedTrainers(ac),
        })


# ============================================================================
# 成就
# ============================================================================

class AutoChessAchievementAwardGet(RequestHandlerTask):
    """领取成就宝箱奖励（自动领取所有可领取的等级）"""
    url = r'/game/auto_chess/achievement/award/get'

    @coroutine
    def run(self):
        if getattr(self.game.role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')

        ac = self.game.auto_chess

        # 获取所有可领取的等级
        claimable = ac.getClaimableAchievementLevels()
        if not claimable:
            raise ClientError('no claimable awards')

        # 领取所有奖励
        totalAwards = {}
        for levelID in claimable:
            awards = ac.claimAchievementBoxAward(levelID)
            if awards:
                for itemID, amount in awards.items():
                    totalAwards[itemID] = totalAwards.get(itemID, 0) + amount

        # 发放奖励
        if totalAwards:
            eff = ObjectGainAux(self.game, totalAwards)
            yield effectAutoGain(eff, self.game, self.dbcGame, src='auto_chess_achievement')

        self.write({
            'achievement_box_awards': ac.achievement_box_awards,
            'awards': totalAwards,
        })


# ============================================================================
# 排行榜
# ============================================================================

class AutoChessRank(RequestHandlerTask):
    """获取PVE排行榜（本服）
    
    前端期望返回格式:
    tb.view.ranks = {
        -1: {ranking: [...], rank: 自己排名, point: 自己分数},  # 总榜
        200001: {ranking: [...], rank: 自己排名, point: 自己分数},  # 训练家1榜
        ...
    }
    
    注意：本服排行榜暂时返回空数据，等待实现跨服排行榜服务
    """
    url = r'/game/auto_chess/rank'

    @coroutine
    def run(self):
        from framework.csv import MergeServ
        from game.object.game.cross_auto_chess import ObjectCrossAutoChessGameGlobal

        if getattr(self.game.role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')

        ac = self.game.auto_chess
        role = self.game.role
        # 排行榜使用游戏积分（pve_best_score），不是成就点数
        myScore = ac.pve_best_score or 0
        areaKey = self.game.role.areaKey
        
        # 查询排行榜时也同步一次自己的积分（确保数据同步）
        isOpen = ObjectCrossAutoChessGameGlobal.isOpen(areaKey)
        logger.info('auto_chess rank: myScore=%s (pve_best_score), areaKey=%s, isOpen=%s', myScore, areaKey, isOpen)
        
        if myScore > 0 and isOpen:
            # 获取训练家等级和技能
            trainerID = ac.trainer
            trainers = ac.trainers or {}
            trainerData = trainers.get(trainerID, {})
            trainerLevel = trainerData.get('level', 1)
            
            # 获取训练家第一个技能ID（从配置表）
            trainerSkillID = 0
            if hasattr(csv, 'auto_chess') and hasattr(csv.auto_chess, 'trainer'):
                if trainerID in csv.auto_chess.trainer:
                    trainerCfg = csv.auto_chess.trainer[trainerID]
                    skillsDict = getattr(trainerCfg, 'skills', {}) or {}
                    if skillsDict:
                        trainerSkillID = list(skillsDict.keys())[0]  # 取第一个技能
            
            roleInfo = {
                'role_id': role.id,
                'game_key': areaKey,
                'role_info': {
                    'role_id': role.id,
                    'name': role.name,
                    'game_key': areaKey,
                    'serv_id': self.server.servID,
                    'serv_name': self.server.servName,
                    'level': role.level,
                    'logo': role.logo,
                    'frame': role.frame,
                    'logo_frame': role.frame,
                    'vip_level': role.vip_level,
                    'fight_value': role.battle_fighting_point,
                    'union_name': self.game.union.name if self.game.union else '',
                    'union_badge': self.game.union.badge if self.game.union else 0,
                    'card_skin_bag': [],
                },
                'achievement_points': ac.achievement_points or 0,  # 成就点数
                'pve_best_score': myScore,      # 排行榜积分（单次游戏最高分）
                'max_floor': ac.normal_max_chapter or 0,
                # 排行榜查看功能需要的阵容数据
                'trainer': trainerID,
                'trainer_level': trainerLevel,
                'trainer_skill': trainerSkillID,
                'deployments': [],   # 前端没有发送阵容数据
            }
            logger.info('auto_chess rank: uploading score, roleInfo=%s', roleInfo)
            uploadResult = yield ObjectCrossAutoChessGameGlobal.updatePveScore(areaKey, roleInfo)
            logger.info('auto_chess rank: upload result=%s', uploadResult)
        
        # 从跨服服务获取PVE排行榜
        result = yield ObjectCrossAutoChessGameGlobal.getCrossPveRankInfo(role.id, areaKey, 0, 50)
        logger.info('auto_chess rank: getCrossPveRankInfo result=%s', result)
        
        ranking = []
        myRank = 0
        if result:
            rawRanks = result.get('ranks', [])
            myRank = result.get('rank', 0)
            
            # 确保每个排行榜项都有前端需要的字段
            for item in rawRanks:
                rankItem = {
                    'name': item.get('name', ''),
                    'game_key': item.get('game_key') or item.get('serv_id') or areaKey,  # 兼容多种字段名
                    'points': item.get('pve_best_score') or item.get('points', 0),  # 排行榜积分
                    'logo': item.get('logo', 1),
                    'frame': item.get('frame') or item.get('logo_frame', 1),
                    'role_id': item.get('role_id', ''),
                    # 排行榜查看功能需要的阵容数据
                    'trainer': item.get('trainer', 0),
                    'trainer_level': item.get('trainer_level', 1),
                    'trainer_skill': item.get('trainer_skill', 0),
                    'deployments': item.get('deployments', []),
                }
                ranking.append(rankItem)
        
        # 构建返回数据
        ranks = {
            -1: {  # 总榜
                'ranking': ranking,
                'rank': myRank,
                'point': myScore,
            }
        }
        
        # 查询各训练家分榜数据
        rankTrainers = ac.rank_trainers or []
        for trainerID in rankTrainers:
            trainerRankData = {
                'ranking': [],
                'rank': 0,
                'point': 0,
            }
            
            # 如果活动开启，查询训练家分榜
            if isOpen:
                trainerResult = yield ObjectCrossAutoChessGameGlobal.getCrossTrainerRankInfo(
                    trainerID, role.id, areaKey, 0, 50
                )
                if trainerResult:
                    trainerRanking = []
                    for item in trainerResult.get('ranks', []):
                        trainerRankItem = {
                            'name': item.get('name', ''),
                            'game_key': item.get('game_key') or areaKey,
                            'points': item.get('pve_best_score') or item.get('score', 0),
                            'logo': item.get('logo', 1),
                            'frame': item.get('frame') or item.get('logo_frame', 1),
                            'role_id': item.get('role_id', ''),
                            'trainer': trainerID,
                            'trainer_level': item.get('trainer_level', 1),
                            'trainer_skill': item.get('trainer_skill', 0),
                            'deployments': item.get('deployments', []),
                        }
                        trainerRanking.append(trainerRankItem)
                    
                    trainerRankData['ranking'] = trainerRanking
                    trainerRankData['rank'] = trainerResult.get('rank', 0)
                    trainerRankData['point'] = trainerResult.get('score', 0)
            
            ranks[trainerID] = trainerRankData
        
        self.write({'view': {'ranks': ranks}})


# ============================================================================
# 战斗反馈
# ============================================================================

class AutoChessFeedbackBattle(RequestHandlerTask):
    """上报战斗反馈"""
    url = r'/game/auto_chess/feedback/battle'

    @coroutine
    def run(self):
        # TODO: 处理战斗反馈
        self.write({})


# ============================================================================
# 商城
# ============================================================================

class AutoChessShopBuy(RequestHandlerTask):
    """购买商城道具"""
    url = r'/game/auto_chess/shop/buy'

    @coroutine
    def run(self):
        if getattr(self.game.role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')

        csvID = self.input.get('csvID')
        count = self.input.get('count', 1)
        if csvID is None:
            raise ClientError('param miss')
        if count <= 0:
            raise ClientError('invalid count')

        # 使用 ObjectAutoChessPVPShop（存储在 role.auto_chess_shop）
        from game.object.game.shop import ObjectAutoChessPVPShop
        shop = ObjectAutoChessPVPShop(self.game)
        eff = yield shop.buyItem(csvID, count, src='auto_chess_shop_buy')
        yield effectAutoGain(eff, self.game, self.dbcGame, src='auto_chess_shop_buy')

        self.write({
            'auto_chess_shop': self.game.role.auto_chess_shop,
        })


# ============================================================================
# 图鉴
# ============================================================================

class AutoChessHandbookAwardGet(RequestHandlerTask):
    """领取图鉴奖励"""
    url = r'/game/auto_chess/handbook/award/get'

    @coroutine
    def run(self):
        if getattr(self.game.role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')

        csvID = self.input.get('csvID')
        star = self.input.get('star')
        if csvID is None or star is None:
            raise ClientError('param miss')

        ac = self.game.auto_chess
        if not ac.inited:
            raise ClientError('auto_chess not inited')

        awards = ac.claimHandbookAward(csvID, star)

        # 发放奖励
        if awards:
            eff = ObjectGainAux(self.game, awards)
            yield effectAutoGain(eff, self.game, self.dbcGame, src='auto_chess_handbook')

        self.write({
            'handbook_award': ac.handbook_award,
            'awards': awards,
        })


class AutoChessHandbookAwardGetOnekey(RequestHandlerTask):
    """一键领取所有图鉴奖励"""
    url = r'/game/auto_chess/handbook/award/get/onekey'

    @coroutine
    def run(self):
        if getattr(self.game.role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')

        ac = self.game.auto_chess

        handbook = ac.handbook or {}
        claimed = []
        totalAwards = {}

        for cardID, cardData in handbook.items():
            maxStar = cardData.get('star', 0)
            for s in range(1, maxStar + 1):
                try:
                    awards = ac.claimHandbookAward(cardID, s)
                    claimed.append({'cardID': cardID, 'star': s})
                    # 累加奖励
                    for itemID, amount in awards.items():
                        totalAwards[itemID] = totalAwards.get(itemID, 0) + amount
                except ClientError:
                    pass

        # 发放奖励
        if totalAwards:
            eff = ObjectGainAux(self.game, totalAwards)
            yield effectAutoGain(eff, self.game, self.dbcGame, src='auto_chess_handbook_onekey')

        self.write({
            'claimed': claimed,
            'handbook_award': ac.handbook_award,
            'awards': totalAwards,
        })


# ============================================================================
# 签到
# ============================================================================

class AutoChessSignIn(RequestHandlerTask):
    """每日签到"""
    url = r'/game/auto_chess/sign_in'

    @coroutine
    def run(self):
        if getattr(self.game.role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')

        ac = self.game.auto_chess

        today = todayinclock5date2int()

        # 检查是否已签到
        if ac.last_sign_in_date == today:
            raise ClientError('already signed in')

        # 更新签到
        ac.sign_in_days = (ac.sign_in_days or 0) + 1
        ac.last_sign_in_date = today
        
        # 累计签到天数（用于勋章统计）
        self.game.role.auto_chess_sign_in_days = (self.game.role.auto_chess_sign_in_days or 0) + 1

        # TODO: 根据签到天数发放奖励
        awards = {
            'gold': 10000 * ac.sign_in_days,
            'coin19': 100 * ac.sign_in_days,
        }

        if awards:
            eff = ObjectGainAux(self.game, awards)
            yield effectAutoGain(eff, self.game, self.dbcGame, src='auto_chess_sign_in')

        self.write({
            'sign_in_days': ac.sign_in_days,
            'last_sign_in_date': ac.last_sign_in_date,
            'awards': awards,
        })


# ============================================================================
# PVP在线对战接口（跨服卡牌对决）
# ============================================================================

class AutoChessOnlineMatchStart(RequestHandlerTask):
    """开始匹配
    
    前端参数: longtimeout
    """
    url = r'/game/auto_chess/online/match/start'

    @coroutine
    def run(self):
        from game.object.game.cross_auto_chess import ObjectCrossAutoChessGameGlobal
        import time

        yield self._ensureAutoChessInited()
        ac = self.game.auto_chess
        role = self.game.role
        areaKey = role.areaKey

        # 检查跨服活动是否开启
        if not ObjectCrossAutoChessGameGlobal.isOpen(areaKey):
            raise ClientError('online auto chess not open')

        longtimeout = self.input.get('longtimeout', False)
        timeout = 300 if longtimeout else 60  # 长匹配5分钟，普通1分钟

        # 构建玩家匹配信息
        pvpInfo = ac.pvp_info or {}
        pvpRecord = pvpInfo.get('record', {})
        winCount = pvpRecord.get('win_streak', 0)
        failCount = pvpRecord.get('fail_streak', 0)
        
        crossKey = ObjectCrossAutoChessGameGlobal.getCrossKey(areaKey)
        season = ObjectCrossAutoChessGameGlobal.getSeason(areaKey)
        
        player = {
            'id': str(role.id),
            'game_key': areaKey,
            'cross_key': crossKey,
            'name': role.name,
            'logo': role.logo,
            'frame': role.frame,
            'level': role.level,
            'score': pvpInfo.get('score', 0),
            'winstreak': winCount >= 3,
            'failstreak': failCount >= 3,
            'fighting_point': getattr(role, 'battle_fighting_point', 0),
            'time': int(time.time()),
            'timeout': timeout,
            'season': season,
        }

        # 调用Go端匹配RPC
        # Go 端返回 (bool, error)，Python 端只收到 bool 值
        success = yield ObjectCrossAutoChessGameGlobal.startMatch(areaKey, player)
        if not success:
            raise ClientError('match start failed')

        # 更新匹配状态（前端期望秒级时间戳）
        online = dict(ac.online or {})
        online['matching'] = int(time.time())  # 秒级时间戳
        ac.online = online

        self.write({
            'view': {
                'online': ac.online,
            }
        })

    @coroutine
    def _ensureAutoChessInited(self):
        role = self.game.role
        if getattr(role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')
        ac = self.game.auto_chess
        if not ac.inited:
            recordData = yield self.dbcGame.call_async('DBRead', 'AutoChess', role.auto_chess_db_id, False)
            if not recordData['ret']:
                raise ServerError('db read auto_chess record error')
            ac.set(recordData['model']).init()


class AutoChessOnlineMatchCancel(RequestHandlerTask):
    """取消匹配"""
    url = r'/game/auto_chess/online/match/cancel'

    @coroutine
    def run(self):
        from game.object.game.cross_auto_chess import ObjectCrossAutoChessGameGlobal

        yield self._ensureAutoChessInited()
        ac = self.game.auto_chess
        role = self.game.role
        areaKey = role.areaKey

        # 调用Go端取消匹配RPC
        yield ObjectCrossAutoChessGameGlobal.cancelMatch(areaKey, areaKey, str(role.id))

        # 清除匹配状态
        online = dict(ac.online or {})
        online['matching'] = 0
        online['room_id'] = ''
        online['room_address'] = ''
        ac.online = online

        self.write({
            'view': {
                'online': ac.online,
            }
        })

    @coroutine
    def _ensureAutoChessInited(self):
        role = self.game.role
        if getattr(role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')
        ac = self.game.auto_chess
        if not ac.inited:
            recordData = yield self.dbcGame.call_async('DBRead', 'AutoChess', role.auto_chess_db_id, False)
            if not recordData['ret']:
                raise ServerError('db read auto_chess record error')
            ac.set(recordData['model']).init()


class AutoChessOnlineBattleEnd(RequestHandlerTask):
    """PVP战斗结束"""
    url = r'/game/auto_chess/online/battle/end'

    @coroutine
    def run(self):
        yield self._ensureAutoChessInited()
        ac = self.game.auto_chess

        # 清除房间状态
        online = dict(ac.online or {})
        online['matching'] = 0
        online['room_id'] = ''
        online['room_address'] = ''
        ac.online = online

        # TODO: 调用Go端获取真实的战斗结果
        # 目前返回默认值，假设玩家获得第1名
        pvp_info = dict(ac.pvp_info or {})
        old_score = pvp_info.get('score', 1000)
        # 临时：假设第1名，加10分
        rank = 1
        score_diff = 10
        new_score = old_score + score_diff
        pvp_info['score'] = new_score
        ac.pvp_info = pvp_info

        self.write({
            'view': {
                'rank': rank,
                'score': new_score,
                'scoreDiff': score_diff,
            }
        })

    @coroutine
    def _ensureAutoChessInited(self):
        role = self.game.role
        if getattr(role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')
        ac = self.game.auto_chess
        if not ac.inited:
            recordData = yield self.dbcGame.call_async('DBRead', 'AutoChess', role.auto_chess_db_id, False)
            if not recordData['ret']:
                raise ServerError('db read auto_chess record error')
            ac.set(recordData['model']).init()


class AutoChessOnlineRank(RequestHandlerTask):
    """获取PVP排行榜
    
    前端参数: offset, size
    """
    url = r'/game/auto_chess/online/rank'

    @coroutine
    def run(self):
        from framework.csv import MergeServ
        from game.object.game.cross_auto_chess import ObjectCrossAutoChessGameGlobal

        yield self._ensureAutoChessInited()
        ac = self.game.auto_chess
        roleID = self.game.role.id
        areaKey = self.game.role.areaKey

        offset = self.input.get('offset', 0)
        size = self.input.get('size', 50)

        # 从跨服服务获取排行榜
        result = yield ObjectCrossAutoChessGameGlobal.getCrossRankInfo(roleID, areaKey, offset, size)
        
        ranks = []
        myRank = 0
        myScore = 0
        if result:
            ranks = result.get('ranks', []) or result.get('Ranks', []) or []
            myRank = result.get('rank', 0) or result.get('Rank', 0) or 0
            myScore = result.get('score', 0) or result.get('Score', 0) or 0

        # 前端期望: tb.view.ranks = {ranks: [...], myRank: number}
        self.write({
            'view': {
                'ranks': {
                    'ranks': ranks,
                    'myRank': myRank,
                },
            }
        })

    @coroutine
    def _ensureAutoChessInited(self):
        role = self.game.role
        if getattr(role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')
        ac = self.game.auto_chess
        if not ac.inited:
            recordData = yield self.dbcGame.call_async('DBRead', 'AutoChess', role.auto_chess_db_id, False)
            if not recordData['ret']:
                raise ServerError('db read auto_chess record error')
            ac.set(recordData['model']).init()


class AutoChessOnlineGradeAwardGet(RequestHandlerTask):
    """领取段位奖励
    
    前端参数: csvID
    """
    url = r'/game/auto_chess/online/grade/award/get'

    @coroutine
    def run(self):
        yield self._ensureAutoChessInited()
        ac = self.game.auto_chess

        csvID = self.input.get('csvID')
        if csvID is None:
            raise ClientError('param miss')

        # 检查是否已领取
        gradeAward = dict(ac.pvp_grade_award or {})
        if csvID in gradeAward:
            raise ClientError('already claimed')

        # 检查是否达到该段位
        pvpInfo = ac.pvp_info or {}
        currentGrade = pvpInfo.get('grade', 1)
        if csvID > currentGrade:
            raise ClientError('grade not reached')

        # 标记已领取
        gradeAward[csvID] = True
        ac.pvp_grade_award = gradeAward

        # 获取奖励配置
        awards = {}
        if hasattr(csv, 'cross') and hasattr(csv.cross, 'online_auto_chess') and hasattr(csv.cross.online_auto_chess, 'grade'):
            cfg = csv.cross.online_auto_chess.grade.get(csvID)
            if cfg:
                awards = getattr(cfg, 'award', {}) or {}

        # 发放奖励
        if awards:
            eff = ObjectGainAux(self.game, awards)
            yield effectAutoGain(eff, self.game, self.dbcGame, src='auto_chess_online_grade_award')

        self.write({
            'view': {
                'pvp_grade_award': ac.pvp_grade_award,
                'awards': awards,
            }
        })

    @coroutine
    def _ensureAutoChessInited(self):
        role = self.game.role
        if getattr(role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')
        ac = self.game.auto_chess
        if not ac.inited:
            recordData = yield self.dbcGame.call_async('DBRead', 'AutoChess', role.auto_chess_db_id, False)
            if not recordData['ret']:
                raise ServerError('db read auto_chess record error')
            ac.set(recordData['model']).init()


class AutoChessOnlinePlayRecordGet(RequestHandlerTask):
    """获取战报
    
    前端参数: crossKey, recordID
    """
    url = r'/game/auto_chess/online/play/record/get'

    @coroutine
    def run(self):
        from framework.csv import MergeServ
        from game.object.game.cross_auto_chess import ObjectCrossAutoChessGameGlobal

        crossKey = self.input.get('crossKey')
        recordID = self.input.get('recordID')
        if not recordID:
            raise ClientError('param miss')

        areaKey = self.game.role.areaKey

        # 从跨服服务获取战报
        result = yield ObjectCrossAutoChessGameGlobal.getPlayRecord(areaKey, recordID)
        
        data = None
        if result:
            data = result.get('data', None) or result.get('Data', None)

        self.write({
            'view': {
                'data': data,
            }
        })


class AutoChessOnlineShopBuy(RequestHandlerTask):
    """PVP商城购买
    
    前端参数: csvID, count
    """
    url = r'/game/auto_chess/online/shop/buy'

    @coroutine
    def run(self):
        yield self._ensureAutoChessInited()

        csvID = self.input.get('csvID')
        count = self.input.get('count', 1)
        if csvID is None:
            raise ClientError('param miss')

        # TODO: 实现PVP商城购买逻辑

        self.write({
            'view': {}
        })

    @coroutine
    def _ensureAutoChessInited(self):
        role = self.game.role
        if getattr(role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')
        ac = self.game.auto_chess
        if not ac.inited:
            recordData = yield self.dbcGame.call_async('DBRead', 'AutoChess', role.auto_chess_db_id, False)
            if not recordData['ret']:
                raise ServerError('db read auto_chess record error')
            ac.set(recordData['model']).init()


class AutoChessOnlineTaskAwardGet(RequestHandlerTask):
    """领取任务奖励
    
    前端参数: flag, csvID, date
    """
    url = r'/game/auto_chess/online/task/award/get'

    @coroutine
    def run(self):
        yield self._ensureAutoChessInited()
        ac = self.game.auto_chess

        flag = self.input.get('flag')  # 1=赛季任务, 2=成就任务
        csvID = self.input.get('csvID')
        date = self.input.get('date')

        if flag is None or csvID is None:
            raise ClientError('param miss')

        awards = {}
        if flag == 1:
            # 赛季任务
            tasks = dict(ac.pvp_season_tasks or {})
            # TODO: 检查任务完成度，发放奖励
            ac.pvp_season_tasks = tasks
        elif flag == 2:
            # 成就任务
            tasks = dict(ac.pvp_achievement_tasks or {})
            # TODO: 检查任务完成度，发放奖励
            ac.pvp_achievement_tasks = tasks

        # 发放奖励
        if awards:
            eff = ObjectGainAux(self.game, awards)
            yield effectAutoGain(eff, self.game, self.dbcGame, src='auto_chess_online_task_award')

        self.write({
            'view': {
                'pvp_season_tasks': ac.pvp_season_tasks,
                'pvp_achievement_tasks': ac.pvp_achievement_tasks,
                'awards': awards,
            }
        })

    @coroutine
    def _ensureAutoChessInited(self):
        role = self.game.role
        if getattr(role, 'auto_chess_db_id', None) is None:
            raise ClientError('auto_chess not unlocked')
        ac = self.game.auto_chess
        if not ac.inited:
            recordData = yield self.dbcGame.call_async('DBRead', 'AutoChess', role.auto_chess_db_id, False)
            if not recordData['ret']:
                raise ServerError('db read auto_chess record error')
            ac.set(recordData['model']).init()


class AutoChessOnlineRoleGet(RequestHandlerTask):
    """获取角色信息（查看其他玩家）
    
    前端参数: gameKey, recordID
    """
    url = r'/game/auto_chess/online/role/get'

    @coroutine
    def run(self):
        gameKey = self.input.get('gameKey')
        recordID = self.input.get('recordID')

        # TODO: 从跨服服务获取玩家信息

        self.write({
            'view': {}
        })
