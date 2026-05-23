#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
============================================================================
卡牌冒险 PVE模式 (Auto Chess) - 玩家数据对象
文档: docs/卡牌冒险PVE模式前端架构文档.md
============================================================================
'''

from __future__ import absolute_import

import random
import time

from framework import todayinclock5date2int
from framework.csv import csv
from framework.object import ObjectDBase, db_property
from framework.log import logger
from framework.helper import transform2list
from game import ClientError
from game.object import TargetDefs
from game.object.game.gain import ObjectGainAux


# ============================================================================
# CSV配置读取辅助函数
# 注意：CSV访问使用方括号直接访问，如 csv.auto_chess.base[1]，不用 .get()
# ============================================================================

def _get_auto_chess_base(baseID=1):
    """获取卡牌冒险基础配置"""
    if not hasattr(csv, 'auto_chess') or not hasattr(csv.auto_chess, 'base'):
        return None
    try:
        return csv.auto_chess.base[baseID]
    except KeyError:
        return None


def _expandCards(cardsDict):
    """将卡牌字典展开为数组
    
    CSV 格式: {cardID=数量}，如 {1001=2;1003=1}
    前端期望: [cardID, cardID, ...]
    
    例如: {1001: 2, 1003: 1} -> [1001, 1001, 1003]
    """
    if not cardsDict:
        return []
    result = []
    for cardID, count in cardsDict.items():
        # count 表示该卡牌的数量，需要重复添加
        for _ in range(max(1, int(count) if count else 1)):
            result.append(int(cardID))
    return result


def _get_trainer_csv(trainerID):
    """获取训练家配置"""
    if not hasattr(csv, 'auto_chess') or not hasattr(csv.auto_chess, 'trainer'):
        return None
    try:
        return csv.auto_chess.trainer[trainerID]
    except KeyError:
        return None


def _get_trainer_level_csv(level):
    """获取训练家等级配置"""
    if not hasattr(csv, 'auto_chess') or not hasattr(csv.auto_chess, 'trainer_level'):
        return None
    try:
        return csv.auto_chess.trainer_level[level]
    except KeyError:
        return None


def _get_achievement_task_csv(taskID):
    """获取成就任务配置"""
    if not hasattr(csv, 'auto_chess') or not hasattr(csv.auto_chess, 'achievement_task'):
        return None
    try:
        return csv.auto_chess.achievement_task[taskID]
    except KeyError:
        return None


def _get_achievement_level_csv(levelID):
    """获取成就等级配置"""
    if not hasattr(csv, 'auto_chess') or not hasattr(csv.auto_chess, 'achievement_level'):
        return None
    try:
        return csv.auto_chess.achievement_level[levelID]
    except KeyError:
        return None


def _get_shop_csv(shopID):
    """获取商城配置"""
    if not hasattr(csv, 'auto_chess') or not hasattr(csv.auto_chess, 'shop'):
        return None
    try:
        return csv.auto_chess.shop[shopID]
    except KeyError:
        return None


def _get_saodang_award_csv(awardID):
    """获取扫荡奖励配置"""
    if not hasattr(csv, 'auto_chess') or not hasattr(csv.auto_chess, 'saodang_award'):
        return None
    try:
        return csv.auto_chess.saodang_award[awardID]
    except KeyError:
        return None


def _get_card_csv(cardID):
    """获取卡牌配置"""
    if not hasattr(csv, 'auto_chess') or not hasattr(csv.auto_chess, 'cards'):
        return None
    try:
        return csv.auto_chess.cards[cardID]
    except KeyError:
        return None


def _get_handbook_award_csv(rarity):
    """获取图鉴奖励配置（通过品质ID）"""
    if not hasattr(csv, 'auto_chess') or not hasattr(csv.auto_chess, 'handbook_award'):
        return None
    try:
        return csv.auto_chess.handbook_award[rarity]
    except KeyError:
        return None


def _get_monster_csv(monsterID):
    """获取怪物配置
    
    字段说明:
    - rewardWin: 胜利道具奖励 {itemID: count}
    - rewardFail: 失败道具奖励 {itemID: count}
    - exp: 训练家经验 {win: 胜利经验, fail: 失败经验}
    """
    if not hasattr(csv, 'auto_chess') or not hasattr(csv.auto_chess, 'monster'):
        return None
    try:
        return csv.auto_chess.monster[monsterID]
    except KeyError:
        return None


# ============================================================================
# 成就类型定义
# ============================================================================

class AchievementCounterType(object):
    """成就计数器类型"""
    GAME_COUNT = 1          # 游戏场次
    WIN_COUNT = 2           # 胜利次数
    MAX_CHAPTER = 3         # 最大章节
    CARDS_USED = 4          # 使用卡牌数
    SHOP_RISE = 5           # 升星次数
    STORY_CHOOSE = 6        # 剧情选择
    SHOP_USE_HP = 7         # 商店使用血量
    SHOP_ENHANCE = 8        # 强化次数


# ============================================================================
# ObjectAutoChess - 玩家卡牌冒险数据
# ============================================================================

class ObjectAutoChess(ObjectDBase):
    """玩家卡牌冒险数据"""
    DBModel = 'AutoChess'
    ClientIgnores = set(['id'])

    # ========== 训练家系统 ==========
    trainer = db_property('trainer')
    trainers = db_property('trainers')
    rank_trainers = db_property('rank_trainers')

    # ========== 赛季状态 ==========
    round = db_property('round')
    end_date = db_property('end_date')
    csv_id = db_property('csv_id')
    servers = db_property('servers')

    # ========== 游戏次数 ==========
    times = db_property('times')
    free_times = db_property('free_times')
    last_date = db_property('last_date')

    # ========== 游戏状态 ==========
    in_game = db_property('in_game')
    game_type = db_property('game_type')

    # ========== 扫荡系统 ==========
    saodang_counter = db_property('saodang_counter')

    # ========== 新手引导 ==========
    newbie_guide = db_property('newbie_guide')

    # ========== 成就系统 ==========
    achievement_points = db_property('achievement_points')
    achievement_tasks = db_property('achievement_tasks')
    achievement_box_awards = db_property('achievement_box_awards')
    achievement_counter = db_property('achievement_counter')
    
    # ========== 排行榜积分（单次游戏最高分，上限5000）==========
    pve_best_score = db_property('pve_best_score')

    # ========== 图鉴系统 ==========
    handbook = db_property('handbook')
    handbook_award = db_property('handbook_award')

    # ========== 商城系统 ==========
    shop_buy_counter = db_property('shop_buy_counter')

    # ========== 历史记录 ==========
    normal_max_chapter = db_property('normal_max_chapter')
    normal_type_win_streak = db_property('normal_type_win_streak')
    normal_max_win_streak = db_property('normal_max_win_streak')
    total_games = db_property('total_games')
    total_wins = db_property('total_wins')

    # ========== 签到系统 ==========
    sign_in_days = db_property('sign_in_days')
    last_sign_in_date = db_property('last_sign_in_date')

    # ========== PVP系统（跨服在线对战） ==========
    pvp_info = db_property('pvp_info')                    # PVP段位积分信息
    pvp_grade_award = db_property('pvp_grade_award')      # 段位奖励领取记录
    pvp_history = db_property('pvp_history')              # PVP战斗历史
    pvp_season_infos = db_property('pvp_season_infos')    # 赛季信息
    pvp_season_tasks = db_property('pvp_season_tasks')    # 赛季任务
    pvp_achievement_tasks = db_property('pvp_achievement_tasks')  # 成就任务
    online = db_property('online')                        # 在线匹配状态

    inited = False

    @classmethod
    def classInit(cls):
        """类初始化 - 加载CSV配置"""
        pass

    @property
    def model(self):
        """返回给前端的数据 - 不使用 _db 包装
        
        重要：不能使用 {'_db': data} 格式！
        因为 auto_chess 在前端 REQUIRE_SYNC 列表中，
        前端 Base.syncFrom 在 new=true 时会尝试访问 new._db，
        但 new 是布尔值，导致报错。参考 town.py 的处理方式。
        """
        if not self._db:
            # 未初始化时返回默认结构
            return {
                # 数组字段
                'newbie_guide': [],
                'rank_trainers': [],
                'servers': [],
                'achievement_box_awards': [],
                # Map/Object字段
                'trainers': {},
                'achievement_tasks': {},
                'achievement_counter': {},
                'handbook': {},
                'handbook_award': {},
                'shop_buy_counter': {},
                # 基础字段
                'trainer': 1,
                'round': 'closed',
                'times': 0,
                'free_times': 0,
                'in_game': False,
                'saodang_counter': 0,
                'achievement_points': 0,
                'sign_in_days': 0,
                'normal_max_chapter': 0,
                'csv_id': 0,
                'end_date': 0,
            }
        
        # 直接返回数据的拷贝，不用 {'_db': ...} 包装
        result = dict(self._db)
        
        # 确保数组字段不为None
        if result.get('newbie_guide') is None:
            result['newbie_guide'] = []
        if result.get('rank_trainers') is None:
            result['rank_trainers'] = []
        if result.get('servers') is None:
            result['servers'] = []
        if result.get('achievement_box_awards') is None:
            result['achievement_box_awards'] = []
        # Map/Object字段
        # trainers: 前端通过 trainers[id] 是否存在判断解锁状态，只返回已解锁的训练家
        rawTrainers = result.get('trainers') or {}
        unlockedTrainers = {}
        for tid, tdata in rawTrainers.items():
            if tdata and tdata.get('unlocked', False):
                unlockedTrainers[tid] = tdata
        result['trainers'] = unlockedTrainers
        if result.get('achievement_tasks') is None:
            result['achievement_tasks'] = {}
        if result.get('achievement_counter') is None:
            result['achievement_counter'] = {}
        if result.get('handbook') is None:
            result['handbook'] = {}
        if result.get('handbook_award') is None:
            result['handbook_award'] = {}
        # 确保 handbook 中每个卡牌都有必要字段（前端红点系统需要）
        handbook = result.get('handbook') or {}
        handbook_award = result.get('handbook_award') or {}
        for cardID, cardData in handbook.items():
            # 确保 award 字段存在
            if 'award' not in cardData:
                cardData['award'] = {}
            # 确保 max_star 字段存在（前端红点比较需要）
            if 'max_star' not in cardData:
                cardData['max_star'] = cardData.get('star', 1)
            # 确保 star 字段存在
            if 'star' not in cardData:
                cardData['star'] = 1
            # 同步奖励领取状态
            if cardID in handbook_award:
                cardData['award'] = handbook_award[cardID]
        result['handbook'] = handbook
        if result.get('shop_buy_counter') is None:
            result['shop_buy_counter'] = {}
        
        return result

    def init(self):
        """实例初始化"""
        if self.db is None:
            return self
        ObjectDBase.init(self)
        self._ensureDefaults()
        self.inited = True
        return self

    def set(self, dic):
        """设置数据"""
        if dic is None:
            dic = {}
        ObjectDBase.set(self, dic)
        self._ensureDefaults()
        return self

    def _ensureDefaults(self):
        """确保默认值存在"""
        if self.db is None:
            return

        db = self.db
        base = _get_auto_chess_base()

        # 确保 id 字段存在
        if 'id' not in db:
            from bson.objectid import ObjectId
            dict.__setitem__(db, 'id', ObjectId())

        # ========== 训练家系统 ==========
        # Go 端默认值是 0，检查是否为有效训练家 ID
        if not self.trainer:
            # 从 CSV 获取默认训练家（unlockType == 0 的第一个）
            defaultTrainer = None
            if hasattr(csv, 'auto_chess') and hasattr(csv.auto_chess, 'trainer'):
                # 只找 unlockType == 0 的训练家（如 200001 夏伯）
                for tid in sorted(csv.auto_chess.trainer.keys()):
                    cfg = csv.auto_chess.trainer[tid]
                    unlockType = getattr(cfg, 'unlockType', 0)
                    if unlockType == 0:
                        defaultTrainer = tid
                        break
            
            # 如果没找到默认训练家，说明配置有问题
            if defaultTrainer is None:
                raise ClientError('No default trainer (unlockType=0) found in trainer.csv')
            
            self.trainer = defaultTrainer

        if self.trainers is None:
            self.trainers = {}

        if self.rank_trainers is None or len(self.rank_trainers) == 0:
            # 从 CSV 读取默认的排行榜训练家列表
            defaultTrainers = []
            if base:
                trainersRaw = getattr(base, 'trainers', None)
                if trainersRaw:
                    # trainers 格式: [200002, 200003] 或类似
                    if isinstance(trainersRaw, (list, tuple)):
                        defaultTrainers = list(trainersRaw)
                    elif isinstance(trainersRaw, dict):
                        defaultTrainers = list(trainersRaw.values())
            self.rank_trainers = defaultTrainers

        # 只初始化玩家可用的训练家（unlockType == 0 的默认训练家）
        # unlockType == 3 是 NPC（大木博士、野生宝可梦等），不初始化
        # unlockType == 1/2 需要玩家解锁，通过 unlockTrainer 接口添加
        if hasattr(csv, 'auto_chess') and hasattr(csv.auto_chess, 'trainer'):
            for tid in csv.auto_chess.trainer:
                cfg = csv.auto_chess.trainer[tid]
                unlockType = getattr(cfg, 'unlockType', 0)
                # 只初始化默认训练家（unlockType == 0）
                if unlockType == 0:
                    self._ensureTrainer(tid, unlocked=True)
        else:
            # CSV 不存在时，至少初始化当前训练家
            self._ensureTrainer(self.trainer, unlocked=True)

        # ========== 赛季状态 ==========
        if self.round is None:
            self.round = 'closed'
        if self.end_date is None:
            self.end_date = 0
        if self.csv_id is None:
            self.csv_id = 0
        if self.servers is None:
            self.servers = []

        # ========== 游戏次数 ==========
        timesLimit = getattr(base, 'timesLimit', 5) if base else 5
        timesLimit2 = getattr(base, 'timesLimit2', 10) if base else 10
        # Go 端创建新记录时默认值是 0，需要同时检查 None 和 0
        if self.times is None or self.times == 0:
            self.times = timesLimit
        if self.free_times is None or self.free_times == 0:
            self.free_times = timesLimit2
        if self.last_date is None or self.last_date == 0:
            self.last_date = todayinclock5date2int()
        
        # 计算时间恢复的次数
        self._recoverTimes(base, timesLimit, timesLimit2)

        # ========== 游戏状态 ==========
        if self.in_game is None:
            self.in_game = False
        if self.game_type is None:
            self.game_type = 0

        # ========== 扫荡系统 ==========
        if self.saodang_counter is None:
            self.saodang_counter = 0

        # ========== 新手引导 ==========
        if self.newbie_guide is None:
            self.newbie_guide = []

        # ========== 成就系统 ==========
        if 'achievement_points' not in self._db or self._db['achievement_points'] is None:
            self.achievement_points = 0
        if 'achievement_tasks' not in self._db or self._db['achievement_tasks'] is None:
            self.achievement_tasks = {}
        if 'achievement_box_awards' not in self._db or self._db['achievement_box_awards'] is None:
            self.achievement_box_awards = []
        # 排行榜积分（单次游戏最高分，上限5000）
        # 注意：新字段必须用 'key' not in self._db 检查，DictWatcher.get() 也会抛出 KeyError
        if 'pve_best_score' not in self._db or self._db['pve_best_score'] is None:
            self.pve_best_score = 0
        if 'achievement_counter' not in self._db or self._db['achievement_counter'] is None:
            self.achievement_counter = {}

        # ========== 图鉴系统 ==========
        if self.handbook is None:
            self.handbook = {}
        if self.handbook_award is None:
            self.handbook_award = {}

        # ========== 商城系统 ==========
        if self.shop_buy_counter is None:
            self.shop_buy_counter = {}

        # ========== 历史记录 ==========
        if self.normal_max_chapter is None:
            self.normal_max_chapter = 0
        if self.normal_type_win_streak is None:
            self.normal_type_win_streak = 0
        if self.normal_max_win_streak is None:
            self.normal_max_win_streak = 0
        if self.total_games is None:
            self.total_games = 0
        if self.total_wins is None:
            self.total_wins = 0

        # ========== 签到系统 ==========
        if self.sign_in_days is None:
            self.sign_in_days = 0
        if self.last_sign_in_date is None:
            self.last_sign_in_date = 0

        # ========== PVP系统（跨服在线对战） ==========
        if self.pvp_info is None:
            self.pvp_info = {
                'score': 1000,        # ELO积分（初始1000）
                'grade': 1,           # 段位
                'top_score': 1000,    # 历史最高分
                'win_count': 0,       # 胜场
                'lose_count': 0,      # 负场
                'win_streak': 0,      # 当前连胜
                'max_win_streak': 0,  # 最高连胜
                'season': 1,          # 当前赛季（默认1）
            }
        if self.pvp_grade_award is None:
            self.pvp_grade_award = {}  # 段位奖励领取记录 {gradeID: True}
        if self.pvp_history is None:
            self.pvp_history = []  # 最近20场战斗记录
        if self.pvp_season_infos is None:
            self.pvp_season_infos = {}  # 赛季信息 {seasonID: {...}}
        if self.pvp_season_tasks is None:
            self.pvp_season_tasks = {}  # 赛季任务 {date: {csvID: {counter, award}}}
        if self.pvp_achievement_tasks is None:
            self.pvp_achievement_tasks = {'counter': {}, 'award': {}}  # 成就任务
        if self.online is None:
            self.online = {
                'matching': 0,        # 匹配开始时间戳（毫秒），0=未匹配
                'room_id': '',        # 房间ID
                'room_address': '',   # 房间服务器地址
                'trainer_id': 0,      # 匹配使用的训练家ID
            }

        # 运行时临时数据 (不存数据库)
        if not hasattr(self, '_processed_battles'):
            self._processed_battles = set()
        if not hasattr(self, '_current_game_exp'):
            self._current_game_exp = 0
        if not hasattr(self, '_current_game_awards'):
            self._current_game_awards = {}

    def _ensureTrainer(self, trainerID, unlocked=False):
        """确保训练家数据存在
        
        如果训练家不存在，创建新记录
        如果训练家已存在且 unlocked=True，更新解锁状态（用于默认训练家的初始化）
        """
        trainers = self.trainers or {}
        # 使用整数 key（与 mimicry 等模块保持一致）
        if trainerID not in trainers:
            trainers[trainerID] = {
                'level': 1,
                'exp': 0,
                'unlocked': unlocked,
                'unlock_time': time.time() if unlocked else 0,
                'use_count': 0,
                'win_count': 0,
            }
            self.trainers = trainers
        elif unlocked and not trainers[trainerID].get('unlocked', False):
            # 默认训练家需要确保解锁状态
            trainers[trainerID]['unlocked'] = True
            trainers[trainerID]['unlock_time'] = time.time()
            self.trainers = trainers
        return trainers[trainerID]

    # ============================================================================
    # 次数恢复
    # ============================================================================

    def _recoverTimes(self, base, timesLimit, timesLimit2):
        """根据时间计算恢复的次数
        
        规则（来自 base.csv）：
        - refreshDay: 恢复周期（天），默认 1
        - resumeCount: 每次恢复的普通模式次数，默认 1
        - resumeCount2: 每次恢复的休闲模式次数，默认 5
        
        前端逻辑参考 (view.lua)：
        local nextResumeTime = time.getNumTimestamp(lastResumeTime, refreshHour) + resumeDay * 24 * 3600
        """
        import time as py_time
        
        # 已经满了，不需要恢复
        currentTimes = self.times or 0
        currentFreeTimes = self.free_times or 0
        if currentTimes >= timesLimit and currentFreeTimes >= timesLimit2:
            return
        
        # 获取恢复配置
        refreshDay = getattr(base, 'refreshDay', 1) if base else 1
        resumeCount = getattr(base, 'resumeCount', 1) if base else 1
        resumeCount2 = getattr(base, 'resumeCount2', 5) if base else 5
        
        # 上次恢复日期
        lastRecoverDate = self.last_date or 0
        if lastRecoverDate == 0:
            return
        
        # 把日期转换成凌晨5点的时间戳
        # last_date 格式：20260203
        year = lastRecoverDate // 10000
        month = (lastRecoverDate % 10000) // 100
        day = lastRecoverDate % 100
        
        import datetime
        try:
            lastRecoverDt = datetime.datetime(year, month, day, 5, 0, 0)  # 凌晨5点
            lastRecoverTime = py_time.mktime(lastRecoverDt.timetuple())
        except:
            return
        
        # 当前时间
        now = py_time.time()
        
        # 恢复周期（秒）
        recoverInterval = refreshDay * 24 * 3600
        
        # 计算经过了多少个恢复周期
        timePassed = now - lastRecoverTime
        recoverCount = int(timePassed / recoverInterval)
        
        if recoverCount <= 0:
            return
        
        # 恢复次数（不超过上限）
        newTimes = min(currentTimes + recoverCount * resumeCount, timesLimit)
        newFreeTimes = min(currentFreeTimes + recoverCount * resumeCount2, timesLimit2)
        
        if newTimes != currentTimes or newFreeTimes != currentFreeTimes:
            self.times = newTimes
            self.free_times = newFreeTimes
            # 更新上次恢复时间为当前日期
            self.last_date = todayinclock5date2int()
            logger.info('auto_chess: recovered times %s->%s, free_times %s->%s, recover_count=%s', 
                       currentTimes, newTimes, currentFreeTimes, newFreeTimes, recoverCount)

    # ============================================================================
    # 训练家系统
    # ============================================================================

    def getTrainerData(self, trainerID):
        """获取训练家数据"""
        trainers = self.trainers or {}
        return trainers.get(trainerID)

    def isTrainerUnlocked(self, trainerID):
        """检查训练家是否已解锁"""
        trainerData = self.getTrainerData(trainerID)
        if not trainerData:
            return False
        return trainerData.get('unlocked', False)

    def switchTrainer(self, trainerID):
        """切换训练家"""
        if not self.isTrainerUnlocked(trainerID):
            raise ClientError('trainer not unlocked')
        self.trainer = trainerID
        return True

    def getAchievementLevel(self):
        """计算成就等级
        
        与前端 autoChessTools.getAchievementLevel 逻辑一致：
        遍历 achievement_level.csv，累加消耗的积分直到不够为止
        """
        exp = self.achievement_points or 0
        level = 0
        
        if hasattr(csv, 'auto_chess') and hasattr(csv.auto_chess, 'achievement_level'):
            for levelID in sorted(csv.auto_chess.achievement_level.keys()):
                cfg = csv.auto_chess.achievement_level[levelID]
                pointRequired = getattr(cfg, 'point', 0)
                if exp >= pointRequired:
                    level += 1
                    exp -= pointRequired
                else:
                    break
        
        return level

    def checkTrainerUnlockCondition(self, trainerID, game):
        """检查训练家解锁条件
        
        CSV unlockType 定义：
        - 0: 默认训练家（已默认解锁）
        - 1: 成就等级解锁（需要成就等级 >= unlockArg）
        - 2: 测试用（dev服务器）
        - 3: NPC训练家（无法解锁）
        """
        trainerCfg = _get_trainer_csv(trainerID)
        if not trainerCfg:
            return False, 'trainer not found'

        unlockType = getattr(trainerCfg, 'unlockType', 0)
        unlockArg = getattr(trainerCfg, 'unlockArg', 0)

        if unlockType == 0:
            # 默认训练家，已解锁（一般不会走到这里）
            return True, ''
        elif unlockType == 1:
            # 需要成就等级达到 unlockArg
            achievementLevel = self.getAchievementLevel()
            if achievementLevel < unlockArg:
                return False, 'achievement level not enough'
        elif unlockType == 2:
            # 测试用训练家（前端已在 trainer_change.lua 中判断服务器类型，只在 dev 服显示）
            return True, ''
        elif unlockType == 3:
            # NPC训练家，无法解锁
            return False, 'cannot unlock'

        return True, ''

    def getTrainerUnlockCost(self, trainerID):
        """获取训练家解锁消耗"""
        trainerCfg = _get_trainer_csv(trainerID)
        if not trainerCfg:
            return {}
        return getattr(trainerCfg, 'unlockCost', {}) or {}

    def unlockTrainer(self, trainerID):
        """解锁训练家"""
        if self.isTrainerUnlocked(trainerID):
            raise ClientError('trainer already unlocked')

        trainers = self.trainers or {}
        if trainerID not in trainers:
            trainers[trainerID] = {
                'level': 1,
                'exp': 0,
                'unlocked': True,
                'unlock_time': time.time(),
                'use_count': 0,
                'win_count': 0,
            }
        else:
            trainers[trainerID]['unlocked'] = True
            trainers[trainerID]['unlock_time'] = time.time()

        self.trainers = trainers
        return True

    def addTrainerExp(self, trainerID, exp):
        """增加训练家经验并检查升级"""
        if not self.isTrainerUnlocked(trainerID):
            return False, 0

        trainers = self.trainers or {}
        if trainerID not in trainers:
            return False, 0

        trainerData = trainers[trainerID]
        trainerData['exp'] = trainerData.get('exp', 0) + exp

        levelUp = 0
        # 检查升级
        while True:
            level = trainerData.get('level', 1)
            levelCfg = _get_trainer_level_csv(level)
            if not levelCfg:
                break
            needExp = getattr(levelCfg, 'exp', 999)
            if needExp <= 0 or trainerData['exp'] < needExp:
                break
            trainerData['exp'] -= needExp
            trainerData['level'] = level + 1
            levelUp += 1

        self.trainers = trainers
        return True, levelUp

    def getTrainerHp(self, trainerID):
        """获取训练家当前生命值"""
        trainerCfg = _get_trainer_csv(trainerID)
        if not trainerCfg:
            return 30

        hpMap = getattr(trainerCfg, 'hp', {}) or {}
        trainerData = self.getTrainerData(trainerID)
        level = trainerData.get('level', 1) if trainerData else 1

        # 查找不超过当前等级的最高配置
        hp = 30
        for lvl in sorted(hpMap.keys()):
            if lvl <= level:
                hp = hpMap[lvl]
        return hp

    # ============================================================================
    # 游戏流程
    # ============================================================================

    def startGame(self, trainerID, gameType):
        """开始游戏"""
        if self.in_game:
            raise ClientError('already in game')

        # 检查次数
        if gameType == 1:  # 休闲模式
            if (self.free_times or 0) <= 0:
                raise ClientError('no free times')
        elif gameType == 2:  # 普通模式
            if (self.times or 0) <= 0:
                raise ClientError('no times')
        else:
            raise ClientError('invalid game type')

        # 检查训练家
        if not self.isTrainerUnlocked(trainerID):
            raise ClientError('trainer not unlocked')

        trainerData = self.getTrainerData(trainerID)
        trainerCfg = _get_trainer_csv(trainerID)

        # 获取初始数据
        initGold = getattr(trainerCfg, 'gold', 5) if trainerCfg else 5
        initHp = self.getTrainerHp(trainerID)
        initCards = getattr(trainerCfg, 'cards', {}) if trainerCfg else {}
        initSkills = getattr(trainerCfg, 'skills', {}) if trainerCfg else {}
        chapters = self._getTrainerChapters(trainerID)

        # 扣除次数
        if gameType == 1:
            self.free_times = (self.free_times or 0) - 1
        else:
            self.times = (self.times or 0) - 1

        # 更新状态
        self.in_game = True
        self.game_type = gameType
        self.total_games = (self.total_games or 0) + 1

        # 更新训练家使用次数
        trainers = self.trainers or {}
        if trainerID in trainers:
            trainers[trainerID]['use_count'] = trainers[trainerID].get('use_count', 0) + 1
            self.trainers = trainers

        # 更新成就计数
        self.addAchievementCounter(AchievementCounterType.GAME_COUNT, 1)

        # 检查失败/新手保护
        # fail_protect: 连败超过一定次数时启用
        # newbie_protect: 新手玩家前几局启用
        failProtect = False
        newbieProtect = False
        if self.total_games <= 3:  # 前3局启用新手保护
            newbieProtect = True
        if (self.normal_type_win_streak or 0) < -2:  # 连败超过2场启用失败保护
            failProtect = True

        # 生成战斗ID和随机种子
        battleID = int(time.time() * 1000) % 2147483647  # 32位整数
        randSeed = random.randint(1, 2147483647)
        
        # 获取基础配置ID
        baseID = self.csv_id or 1

        # 重置本局临时数据
        self._processed_battles = set()
        self._current_game_exp = 0
        self._current_game_awards = {}

        # 返回初始数据给客户端
        # 字段命名与前端 chess_play.lua 一致（下划线格式）
        # chess_play.getData() 会映射这些字段
        return {
            'id': battleID,           # -> battleID
            'rand_seed': randSeed,    # -> randSeed
            'trainer': trainerID,     # -> trainer
            'level': trainerData.get('level', 1) if trainerData else 1,  # -> level
            'type': gameType,         # -> typ (1=休闲, 2=普通)
            'cards': _expandCards(initCards),  # -> cards (数组格式：[cardID, cardID, ...])
            'skills': dict(initSkills) if initSkills else {},  # -> skills
            'state_set': "",          # -> stateSet (空字符串避免前端读取测试文件)
            'pvp_fights': None,       # -> pvpFights (PVP用)
            'base_id': baseID,        # -> baseID
            'fail_protect': failProtect,      # -> failProtect
            'newbie_protect': newbieProtect,  # -> newbieProtect
            'patch': None,            # -> patch
            # 额外数据（前端可能用到）
            'gold': initGold,
            'hp': initHp,
            'chapters': chapters,
        }

    def _getTrainerChapters(self, trainerID):
        """获取训练家的章节列表"""
        trainerCfg = _get_trainer_csv(trainerID)
        if not trainerCfg:
            return [11, 12, 13, 14, 15, 16, 17, 18]
        chapters = getattr(trainerCfg, 'chapters', []) or []
        return list(chapters) if chapters else [11, 12, 13, 14, 15, 16, 17, 18]

    def recoverGame(self):
        """恢复游戏 - 返回与 startGame 相同格式的数据
        
        PVE战斗由客户端维护，但需要返回完整的 chess_play 数据
        字段与 chess_play.lua getData() 对应
        """
        if not self.in_game:
            raise ClientError('not in game')
        
        trainerID = self.trainer
        trainerData = self.getTrainerData(trainerID)
        trainerCfg = _get_trainer_csv(trainerID)
        
        # 获取初始数据
        initCards = getattr(trainerCfg, 'cards', {}) if trainerCfg else {}
        initSkills = getattr(trainerCfg, 'skills', {}) if trainerCfg else {}
        
        # 生成战斗ID和随机种子
        battleID = int(time.time() * 1000) % 2147483647
        randSeed = random.randint(1, 2147483647)
        baseID = self.csv_id or 1
        
        return {
            'id': battleID,
            'rand_seed': randSeed,
            'trainer': trainerID,
            'level': trainerData.get('level', 1) if trainerData else 1,
            'type': self.game_type,
            'cards': _expandCards(initCards),  # 数组格式：[cardID, cardID, ...]
            'skills': dict(initSkills) if initSkills else {},
            'state_set': None,  # 断线重连时可能有保存的状态
            'pvp_fights': None,
            'base_id': baseID,
            'fail_protect': False,
            'newbie_protect': False,
            'patch': None,
        }

    def syncInput(self, inputs, checksum, randcnt, frame, giveup=False, stateset=None):
        """同步游戏操作 - PVE战斗由客户端维护
        
        stateset: 前端打包的游戏状态，包含战斗结果等数据
        """
        if not self.in_game:
            # raise ClientError('not in game') # 暂时允许非游戏状态同步，以便处理结算后的最后一次包
            pass

        # 尝试从 stateset 解析战斗结果并即时结算
        if stateset:
            self._last_stateset = stateset
            self._processBattles(stateset)

        if giveup:
            return self.endGame(win=False, chapter=0)

        return None

    def _processBattles(self, stateset):
        """处理战斗结算（即时发放奖励）
        
        【游戏规则】休闲模式无法解锁成就，不会获得任何奖励
        """
        battles = self._parseBattlesFromStateSet(stateset)
        logger.info('auto_chess: _processBattles found %d battles: %s', len(battles), battles)
        if not battles:
            return

        trainerID = self.trainer
        gameType = self.game_type
        
        # 【游戏规则】休闲模式不获得奖励
        if gameType == 1:
            logger.info('auto_chess: relax mode, skip awards')
            return
        
        # 确保集合初始化
        if not hasattr(self, '_processed_battles'):
            self._processed_battles = set()
        if not hasattr(self, '_current_game_exp'):
            self._current_game_exp = 0
        if not hasattr(self, '_current_game_awards'):
            self._current_game_awards = {}

        awards_to_gain = {}
        exp_to_gain = 0

        for battle in battles:
            battleID = battle.get('id')
            if not battleID or battleID in self._processed_battles:
                continue
            
            result = battle.get('result', 'fail')
            
            # 如果结果是 unkown，说明战斗尚未结算，暂不处理，等待前端更新状态
            if result == 'unkown':
                continue

            self._processed_battles.add(battleID)
            
            monsterID = battle.get('sid')
            if not monsterID:
                continue
            
            monsterCfg = _get_monster_csv(monsterID)
            if not monsterCfg:
                continue

            # 道具奖励 (rewardWin/rewardFail)
            rewardKey = 'rewardWin' if result == 'win' else 'rewardFail'
            rewards = getattr(monsterCfg, rewardKey, None) or {}
            for itemID, count in rewards.items():
                # 跳过特殊字段（libs, card, cards等），这些字段由 ObjectGainAux 处理
                if itemID in ('libs', 'card', 'cards', 'star_skill_points'):
                    # 特殊字段直接累积，不做数量处理
                    if itemID not in awards_to_gain:
                        awards_to_gain[itemID] = []
                        self._current_game_awards[itemID] = []
                    
                    # libs 是数组，需要展开
                    if isinstance(count, (list, tuple)):
                        awards_to_gain[itemID].extend(count)
                        self._current_game_awards[itemID].extend(count)
                    else:
                        awards_to_gain[itemID].append(count)
                        self._current_game_awards[itemID].append(count)
                    continue
                
                # 普通道具：处理数量范围
                if isinstance(count, (list, tuple)) and len(count) >= 2:
                    count = random.randint(count[0], count[1])
                
                if itemID and count > 0:
                    awards_to_gain[itemID] = awards_to_gain.get(itemID, 0) + count
                    self._current_game_awards[itemID] = self._current_game_awards.get(itemID, 0) + count
            
            # 训练家经验 (exp)
            expCfg = getattr(monsterCfg, 'exp', None) or {}
            expKey = 'win' if result == 'win' else 'fail'
            expGain = expCfg.get(expKey, 0)
            
            # 累积经验
            if expGain > 0:
                exp_to_gain += expGain
                self._current_game_exp += expGain
            
            logger.info('auto_chess: battle %s result=%s monster=%s expGain=%s totalExp=%s', 
                       battleID, result, monsterID, expGain, self._current_game_exp)

            # 更新统计 (每次战斗结算都更新吗？还是只在 endGame 更新？)
            # 这里暂不更新 win_streak 等，留给 endGame 统一处理，因为 endGame 有 win 参数
            # 但是可以更新 total_wins ? 不，前端可能把一次遭遇当做多场小战斗？
            # 根据 pack.lua, AutoChessEncounterBattle 是一个遭遇。
            # 通常 PVE 是通过多少个遭遇就算赢。这里只发放掉落奖励。

        # 注意：奖励不在这里发放，而是累积到 _current_game_awards
        # 由 endGame 统一返回给前端，再由 AutoChessEnd Handler 发放
        # 这样可以避免中途断线导致的奖励丢失，也符合项目规范
        logger.info('auto_chess: battle rewards accumulated: %s', awards_to_gain)
        
        # 注意：经验也不在这里发放，而是累积到 _current_game_exp
        # 由 endGame 返回给前端显示
        logger.info('auto_chess: trainer exp accumulated: %s', exp_to_gain)

    def endGame(self, win=False, chapter=0, endData=None):
        """结束游戏
        
        注意：可能被 syncInput(giveup=True) 或 /end 接口调用
        如果已经结束，返回当前状态而不报错
        """
        if not self.in_game:
            # 游戏已结束，返回当前状态
            return {
                'win': win,
                'chapter': chapter,
                'total_games': self.total_games or 0,
                'total_wins': self.total_wins or 0,
                'final_hp': 0,
                'final_gold': 0,
                'lose_count': 0,
                'trainer': self.trainer,
                'awards': getattr(self, '_current_game_awards', {}),
                'exp': getattr(self, '_current_game_exp', 0),
            }

        gameType = self.game_type
        trainerID = self.trainer

        # 从客户端结算数据获取
        finalHp = 0
        finalGold = 0
        loseCount = 0
        # battles = [] # 不再依赖 endData 里的 battles，改用即时结算
        if endData:
            finalHp = endData.get('hp', 0)
            finalGold = endData.get('gold', 0)
            loseCount = endData.get('lose_count', 0)
            win = endData.get('win', win)
            chapter = endData.get('chapter', chapter)
            trainerID = endData.get('trainer', trainerID)
        
        # 如果前端没有传 endData，尝试从 _last_stateset 获取训练家状态
        allChapterOver = False
        if hasattr(self, '_last_stateset') and self._last_stateset:
            trainerState = self._parseTrainerStateFromStateSet(self._last_stateset)
            if trainerState:
                if finalHp == 0:
                    finalHp = trainerState.get('hp', 0)
                if finalGold == 0:
                    finalGold = trainerState.get('gold', 0)
                allChapterOver = trainerState.get('all_chapter_over', False)
                logger.info('auto_chess: got state from stateset - hp=%s gold=%s allChapterOver=%s', 
                           finalHp, finalGold, allChapterOver)
        
        # 判断是否通关
        # 通关条件：打完所有章节（allChapterOver=True）且训练家还活着（hp > 0）
        # 注意：
        # - 血量 > 0 但没打完所有章节 = 放弃（不算通关）
        # - 血量 = 0 = 失败（不管打到哪里）
        if not win and finalHp > 0 and allChapterOver:
            win = True
            logger.info('auto_chess: endGame inferred win=True (allChapterOver and hp>0)')
        elif not win:
            logger.info('auto_chess: endGame win=False - hp=%s allChapterOver=%s', finalHp, allChapterOver)
            # battles = endData.get('battles', [])

        # 尝试最后一次解析 stateset (作为兜底)
        if hasattr(self, '_last_stateset') and self._last_stateset:
            self._processBattles(self._last_stateset)

        # 获取本局累计奖励和经验
        totalAwards = getattr(self, '_current_game_awards', {})
        totalExp = getattr(self, '_current_game_exp', 0)
        
        # 发放训练家经验
        if totalExp > 0 and trainerID:
            success, levelUp = self.addTrainerExp(trainerID, totalExp)
            if success and levelUp > 0:
                logger.info('auto_chess: trainer %s gained %s exp, level up %s times', 
                           trainerID, totalExp, levelUp)

        # 更新统计
        if win:
            self.total_wins = (self.total_wins or 0) + 1
            if gameType == 2:  # 普通模式
                self.normal_type_win_streak = (self.normal_type_win_streak or 0) + 1
                if self.normal_type_win_streak > (self.normal_max_win_streak or 0):
                    self.normal_max_win_streak = self.normal_type_win_streak

            # 更新训练家胜利次数
            if trainerID:
                trainers = self.trainers or {}
                if trainerID in trainers:
                    trainers[trainerID]['win_count'] = trainers[trainerID].get('win_count', 0) + 1
                    self.trainers = trainers

            # 更新成就计数（卡牌冒险自己的 achievement_counter）
            self.addAchievementCounter(AchievementCounterType.WIN_COUNT, 1)
            
            # 更新全局成就计数器 role.achievement_counter[105]
            # 前端用它判断扫荡解锁（虽然这个字段同时被符石抽奖使用）
            if hasattr(self, '_game') and self._game and hasattr(self._game, 'role'):
                counter = self._game.role.achievement_counter or {}
                counter[TargetDefs.DrawGem] = counter.get(TargetDefs.DrawGem, 0) + 1
                self._game.role.achievement_counter = counter
        else:
            if gameType == 2:
                self.normal_type_win_streak = 0

        # 更新最高章节
        if chapter > (self.normal_max_chapter or 0):
            self.normal_max_chapter = chapter
            self.addAchievementCounter(AchievementCounterType.MAX_CHAPTER, chapter)

        # 检查成就任务（通关和失败都可能有成就）
        if endData:
            gameResult = {
                'win': win,
                'chapter': chapter,
                'final_hp': finalHp,
                'final_gold': finalGold,
                'lose_count': loseCount,
                'trainer': trainerID,
                'units': endData.get('units', []),
                'skills': endData.get('skills', []),
                'shop_counters': endData.get('shop_counters', {}),
                'story_choices': endData.get('story_choices', []),
                'pvp_results': endData.get('pvp_results', {}),
            }
            self._checkAchievementTasks(gameResult)
            
            # 激活图鉴（只在正式挑战模式中）
            if gameType == 2:  # 正式挑战模式
                self._unlockHandbooksFromGame(endData)
        
        # 如果前端没有发送 endData，尝试从 stateset 中解析单位（用于图鉴激活）
        if gameType == 2 and hasattr(self, '_last_stateset') and self._last_stateset:
            if not endData or not endData.get('units'):
                logger.info('auto_chess: endData missing units, parsing from stateset')
                units = self._parseUnitsFromStateSet(self._last_stateset)
                if units:
                    logger.info('auto_chess: found %s units in stateset', len(units))
                    fallbackEndData = {'units': units}
                    self._unlockHandbooksFromGame(fallbackEndData)

        # 清理游戏状态
        self.in_game = False
        self.game_type = 0
        if hasattr(self, '_last_stateset'):
            delattr(self, '_last_stateset')
        # 临时数据保留给返回值使用，下次 startGame 会重置

        return {
            'win': win,
            'chapter': chapter,
            'total_games': self.total_games,
            'total_wins': self.total_wins,
            'final_hp': finalHp,
            'final_gold': finalGold,
            'lose_count': loseCount,
            'trainer': trainerID,
            'awards': totalAwards,
            'exp': totalExp,
        }
    
    def _checkAchievementTasks(self, gameResult):
        """检查并更新成就任务
        
        Args:
            gameResult: 游戏结果字典，包含以下字段：
                - win: 是否胜利
                - chapter: 通关章节
                - final_hp: 最终HP
                - final_gold: 最终金币
                - lose_count: 失败次数
                - trainer: 训练家ID
                - units: 场上精灵列表 [{unitID, star, equip_count}, ...]
                - skills: 使用的技能列表 [skillID, ...]
                - shop_counters: 商店使用计数 {shopRiseR, shopEnhanceR, shopUseHPR}
                - story_choices: 剧情选择 [{storyID, choiceID}, ...]
                - pvp_results: PVP结果 {win, lose, damage_dealt, damage_taken, trainer_alive}
        """
        win = gameResult.get('win', False)
        trainerID = gameResult.get('trainer', 0)
        finalHp = gameResult.get('final_hp', 0)
        finalGold = gameResult.get('final_gold', 0)
        loseCount = gameResult.get('lose_count', 0)
        units = gameResult.get('units', [])
        skills = gameResult.get('skills', [])
        shopCounters = gameResult.get('shop_counters', {})
        storyChoices = gameResult.get('story_choices', [])
        pvpResults = gameResult.get('pvp_results', {})
        
        # 遍历所有成就任务
        for taskID in csv.auto_chess.achievement_task:
            taskCfg = csv.auto_chess.achievement_task[taskID]
            
            # 跳过隐藏成就的检查（需要特殊条件触发）
            if getattr(taskCfg, 'isHidden', False):
                continue
            
            # 跳过已完成的成就
            currentProgress = self.achievement_tasks.get(taskID, 0)
            targetArg = getattr(taskCfg, 'targetArg', 1)
            if currentProgress >= targetArg:
                continue
            
            # 解析客户端任务参数
            clientTaskArg = getattr(taskCfg, 'clientTaskArg', {})
            
            # 检查成就条件
            matched = False
            increment = 1  # 默认增加1
            
            # 1. 默认成就（任意训练家通关） - 需要胜利
            if clientTaskArg.get('default') == 1 and win:
                matched = True
            
            # 2. 训练家相关成就
            if 'trainerID' in clientTaskArg:
                requiredTrainerID = clientTaskArg['trainerID']
                if trainerID != requiredTrainerID:
                    continue  # 训练家不匹配，跳过
                
                # 2.1 使用特定训练家通关
                if clientTaskArg.get('default') == 1 or len(clientTaskArg) == 1:
                    matched = True
                
                # 2.2 使用特定技能通关
                if 'skillID' in clientTaskArg:
                    requiredSkillID = clientTaskArg['skillID']
                    if requiredSkillID in skills:
                        matched = True
                
                # 2.3 使用特定精灵通关（支持多个精灵条件）
                unitIDR_keys = [k for k in clientTaskArg.keys() if k.startswith('unitIDR')]
                if unitIDR_keys:
                    allUnitsMatched = True
                    for key in unitIDR_keys:
                        unitIDRange = clientTaskArg[key]
                        if not isinstance(unitIDRange, (list, tuple)) or len(unitIDRange) < 3:
                            continue
                        minCount, maxCount, requiredUnitIDs = unitIDRange[0], unitIDRange[1], unitIDRange[2:]
                        
                        # 统计场上匹配的精灵数量
                        matchedCount = sum(1 for u in units if u.get('unitID') in requiredUnitIDs)
                        if not (minCount <= matchedCount <= maxCount):
                            allUnitsMatched = False
                            break
                    
                    if allUnitsMatched:
                        matched = True
            
            # 3. HP相关成就 - 需要胜利
            if 'hpR' in clientTaskArg and win:
                hpRange = clientTaskArg['hpR']
                if isinstance(hpRange, (list, tuple)) and len(hpRange) >= 2:
                    minHp, maxHp = hpRange[0], hpRange[1]
                    if minHp <= finalHp <= maxHp:
                        matched = True
            
            # 4. 金币相关成就 - 需要胜利
            if 'coinR' in clientTaskArg and win:
                coinRange = clientTaskArg['coinR']
                if isinstance(coinRange, (list, tuple)) and len(coinRange) >= 2:
                    minCoin, maxCoin = coinRange[0], coinRange[1]
                    if minCoin <= finalGold <= maxCoin:
                        matched = True
            
            # 5. 失败次数相关成就 - 需要胜利
            if 'loseR' in clientTaskArg and win:
                loseRange = clientTaskArg['loseR']
                if isinstance(loseRange, (list, tuple)) and len(loseRange) >= 2:
                    minLose, maxLose = loseRange[0], loseRange[1]
                    if minLose <= loseCount <= maxLose:
                        matched = True
            
            # 6. 全胜通关 - 需要胜利
            if 'allWin' in clientTaskArg and win:
                if clientTaskArg['allWin'] == 1 and loseCount == 0:
                    matched = True
            
            # 7. 精灵星级相关成就 - 需要胜利
            if 'starR' in clientTaskArg and win:
                starRange = clientTaskArg['starR']
                if isinstance(starRange, (list, tuple)) and len(starRange) >= 2:
                    minCount, maxCount = starRange[0], starRange[1]
                    requiredStar = starRange[2] if len(starRange) > 2 else None
                    
                    # 统计符合星级的精灵数量
                    if requiredStar:
                        matchedCount = sum(1 for u in units if u.get('star') == requiredStar)
                    else:
                        matchedCount = len(units)
                    
                    if minCount <= matchedCount <= maxCount:
                        matched = True
            
            # 8. 属性系别相关成就 - 需要胜利
            if 'natureR' in clientTaskArg and win:
                natureRange = clientTaskArg['natureR']
                if isinstance(natureRange, (list, tuple)) and len(natureRange) >= 3:
                    minCount, maxCount, requiredNature = natureRange[0], natureRange[1], natureRange[2]
                    
                    # 统计符合属性的精灵数量
                    matchedCount = 0
                    for u in units:
                        unitID = u.get('unitID')
                        if unitID and unitID in csv.auto_chess.cards:
                            cardCfg = csv.auto_chess.cards[unitID]
                            # cards.csv 属性字段是 nature1 和 nature2
                            cardNatures = []
                            if hasattr(cardCfg, 'nature1') and cardCfg.nature1:
                                cardNatures.append(cardCfg.nature1)
                            if hasattr(cardCfg, 'nature2') and cardCfg.nature2:
                                cardNatures.append(cardCfg.nature2)
                            if requiredNature in cardNatures:
                                matchedCount += 1
                    
                    if minCount <= matchedCount <= maxCount:
                        matched = True
            
            # 9. 装备相关成就 - 需要胜利
            if 'equipR' in clientTaskArg and win:
                equipRange = clientTaskArg['equipR']
                if isinstance(equipRange, (list, tuple)) and len(equipRange) >= 2:
                    minCount, maxCount = equipRange[0], equipRange[1]
                    requiredEquipCount = equipRange[2] if len(equipRange) > 2 else 1
                    
                    # 统计穿戴指定数量装备的精灵数量
                    matchedCount = sum(1 for u in units if u.get('equip_count', 0) >= requiredEquipCount)
                    
                    if minCount <= matchedCount <= maxCount:
                        matched = True
            
            # 10. 商店使用相关成就 - 需要胜利
            if 'shopRiseR' in clientTaskArg and win:
                shopRange = clientTaskArg['shopRiseR']
                if isinstance(shopRange, (list, tuple)) and len(shopRange) >= 2:
                    minUse, maxUse = shopRange[0], shopRange[1]
                    actualUse = shopCounters.get('shopRiseR', 0)
                    if minUse <= actualUse <= maxUse:
                        matched = True
            
            if 'shopEnhanceR' in clientTaskArg and win:
                shopRange = clientTaskArg['shopEnhanceR']
                if isinstance(shopRange, (list, tuple)) and len(shopRange) >= 2:
                    minUse, maxUse = shopRange[0], shopRange[1]
                    actualUse = shopCounters.get('shopEnhanceR', 0)
                    if minUse <= actualUse <= maxUse:
                        matched = True
            
            if 'shopUseHPR' in clientTaskArg and win:
                shopRange = clientTaskArg['shopUseHPR']
                if isinstance(shopRange, (list, tuple)) and len(shopRange) >= 2:
                    minUse, maxUse = shopRange[0], shopRange[1]
                    actualUse = shopCounters.get('shopUseHPR', 0)
                    if minUse <= actualUse <= maxUse:
                        matched = True
            
            # 11. 剧情选择相关成就 - 需要胜利
            if 'storyChooseR' in clientTaskArg and win:
                storyRange = clientTaskArg['storyChooseR']
                if isinstance(storyRange, (list, tuple)) and len(storyRange) >= 4:
                    minCount, maxCount, storyID, choiceID = storyRange[0], storyRange[1], storyRange[2], storyRange[3]
                    
                    # 检查是否做出了指定选择
                    matchedCount = sum(1 for choice in storyChoices 
                                      if choice.get('storyID') == storyID and choice.get('choiceID') == choiceID)
                    
                    if minCount <= matchedCount <= maxCount:
                        matched = True
            
            # 12. PVP相关成就
            if 'pvpLoseR' in clientTaskArg:
                pvpRange = clientTaskArg['pvpLoseR']
                if isinstance(pvpRange, (list, tuple)) and len(pvpRange) >= 2:
                    minLose, maxLose = pvpRange[0], pvpRange[1]
                    actualLose = pvpResults.get('lose', 0)
                    if minLose <= actualLose <= maxLose and pvpResults.get('trainer_alive', False):
                        matched = True
            
            if 'takeDmgAliveR' in clientTaskArg:
                dmgRange = clientTaskArg['takeDmgAliveR']
                if isinstance(dmgRange, (list, tuple)) and len(dmgRange) >= 2:
                    minDmg, maxDmg = dmgRange[0], dmgRange[1]
                    actualDmg = pvpResults.get('max_damage_taken', 0)
                    if minDmg <= actualDmg <= maxDmg:
                        matched = True
            
            if 'causeDmgR' in clientTaskArg:
                dmgRange = clientTaskArg['causeDmgR']
                if isinstance(dmgRange, (list, tuple)) and len(dmgRange) >= 2:
                    minDmg, maxDmg = dmgRange[0], dmgRange[1]
                    stageType = dmgRange[2] if len(dmgRange) > 2 else None
                    actualDmg = pvpResults.get('max_damage_dealt', 0)
                    
                    # 如果指定了阶段类型，检查是否在指定阶段
                    if stageType is None or pvpResults.get('stage_type') == stageType:
                        if minDmg <= actualDmg <= maxDmg:
                            matched = True
            
            # 如果匹配，更新成就进度
            if matched:
                self.updateAchievementTask(taskID, increment)
                logger.info('auto_chess: achievement task %s progress updated, current: %s/%s', 
                           taskID, self.achievement_tasks.get(taskID, 0), targetArg)
    
    def _parseUnitsFromStateSet(self, stateset):
        """从 stateset 解析场上单位（用于图鉴激活）
        
        Returns:
            list: [{unitID, star}, ...] 或 []
        """
        import msgpack
        
        try:
            # 解码 stateset
            if isinstance(stateset, unicode):
                stateset = stateset.encode('latin-1')
            
            data = msgpack.unpackb(stateset, raw=True)
            
            # 处理双重编码
            if isinstance(data, str):
                data = msgpack.unpackb(data, raw=True)
            
            if not isinstance(data, dict):
                return []
            
            refData = data.get('refData', {})
            if not isinstance(refData, dict):
                return []
            
            units = []
            
            logger.info('auto_chess: parsing units from stateset, refData has %s entries', len(refData))
            
            # 遍历 refData 查找 AutoChessObjectModel（场上精灵）
            # 只激活玩家方（team=1）的精灵图鉴，不包括敌方（team=2）和商店精灵
            for key, value in refData.items():
                if not isinstance(value, dict):
                    continue
                
                # 检查 __className 字段（注意：是 __className 不是 __name__）
                className = value.get('__className')
                if className == 'AutoChessObjectModel':
                    # 获取精灵ID和星级
                    # 注意：AutoChessObjectModel 有两个 ID 字段：
                    # - id: 对象实例ID（如 17，用于前端引用）
                    # - unitID: 卡牌配置ID（如 1001，对应 cards.csv）
                    objID = value.get('id', 0)
                    unitID = value.get('unitID', 0)
                    star = value.get('star', 1)
                    team = value.get('team', 0)
                    
                    logger.info('auto_chess: found AutoChessObjectModel - objID=%s unitID=%s star=%s team=%s', objID, unitID, star, team)
                    
                    # 只处理玩家方（team=1）的精灵
                    if team != 1:
                        logger.info('auto_chess: skip non-player unit (team=%s)', team)
                        continue
                    
                    # 验证 unitID 是否有效（必须在 cards.csv 中存在）
                    if unitID > 0:
                        cardCfg = _get_card_csv(unitID)
                        if cardCfg:
                            units.append({'unitID': unitID, 'star': star})
                            logger.info('auto_chess: valid unit added to handbook - unitID=%s star=%s', unitID, star)
                        else:
                            logger.warning('auto_chess: skip invalid unitID %s (not in cards.csv)', unitID)
                    else:
                        logger.warning('auto_chess: skip AutoChessObjectModel with objID=%s (no unitID)', objID)
            
            return units
            
        except Exception as e:
            logger.exception('auto_chess: failed to parse units from stateset: %s', e)
            return []
    
    def _parseDeploymentsFromStateSet(self, stateset):
        """从 stateset 解析阵容数据（用于排行榜查看功能）
        
        Returns:
            list: [{unitID, star, attrs: {attack, hpMax, defence}, equips: [equipID, ...]}, ...] 或 []
        """
        import msgpack
        
        try:
            # 解码 stateset
            if isinstance(stateset, unicode):
                stateset = stateset.encode('latin-1')
            
            data = msgpack.unpackb(stateset, raw=True)
            
            # 处理双重编码
            if isinstance(data, str):
                data = msgpack.unpackb(data, raw=True)
            
            if not isinstance(data, dict):
                return []
            
            refData = data.get('refData', {})
            if not isinstance(refData, dict):
                return []
            
            deployments = []
            
            # 遍历 refData 查找玩家方精灵
            for key, value in refData.items():
                if not isinstance(value, dict):
                    continue
                
                className = value.get('__className')
                if className == 'AutoChessObjectModel':
                    team = value.get('team', 0)
                    # 只处理玩家方（team=1）的精灵
                    if team != 1:
                        continue
                    
                    unitID = value.get('unitID', 0)
                    star = value.get('star', 1)
                    
                    if unitID <= 0:
                        continue
                    
                    # 解析属性
                    attrs = value.get('attrs', {})
                    if isinstance(attrs, dict):
                        attrsData = {
                            'attack': attrs.get('attack', 0),
                            'hpMax': attrs.get('hpMax', 0),
                            'defence': attrs.get('defence', 0),
                        }
                    else:
                        attrsData = {'attack': 0, 'hpMax': 0, 'defence': 0}
                    
                    # 解析装备
                    equipMents = value.get('equipMents', {})
                    equips = []
                    if isinstance(equipMents, dict):
                        for equipKey, equipValue in equipMents.items():
                            if isinstance(equipValue, dict):
                                equipID = equipValue.get('id', 0)
                                if equipID > 0:
                                    equips.append(equipID)
                    
                    deployments.append({
                        'unitID': unitID,
                        'star': star,
                        'attrs': attrsData,
                        'equips': equips,
                    })
            
            logger.info('auto_chess: parsed %s deployments from stateset', len(deployments))
            return deployments
            
        except Exception as e:
            logger.exception('auto_chess: failed to parse deployments from stateset: %s', e)
            return []
    
    def _parseTrainerStateFromStateSet(self, stateset):
        """从 stateset 解析训练家状态（血量、金币、章节进度等）
        
        Returns:
            dict: {'hp': int, 'gold': int, 'all_chapter_over': bool} 或 {}
        """
        import msgpack
        
        try:
            # 解码 stateset
            if isinstance(stateset, unicode):
                stateset = stateset.encode('latin-1')
            
            data = msgpack.unpackb(stateset, raw=True)
            
            # 处理双重编码
            if isinstance(data, str):
                data = msgpack.unpackb(data, raw=True)
            
            if not isinstance(data, dict):
                return {}
            
            refData = data.get('refData', {})
            if not isinstance(refData, dict):
                return {}
            
            result = {}
            
            # 遍历 refData 查找数据
            for key, value in refData.items():
                if not isinstance(value, dict):
                    continue
                
                className = value.get('__className')
                
                # 获取训练家状态
                if className == 'AutoChessTrainerModel':
                    team = value.get('team', 0)
                    # 只获取玩家方（team=1）训练家状态
                    if team == 1:
                        result['hp'] = value.get('_hp', 0)
                        result['gold'] = value.get('_gold', 0)
                        logger.info('auto_chess: found trainer state - hp=%s gold=%s', 
                                   result['hp'], result['gold'])
                
                # 获取章节进度
                if className == 'ChessEncounterDataModel':
                    chapterIdx = value.get('_chapterIdx', 1)
                    # _chapters 不在序列化列表中，需要从配置获取
                    # 当 chapterIdx 超过章节数量时，chapter() 返回 nil，表示通关
                    # 从 _queue 和 _encounters 判断：如果都为空，说明当前章节没有遭遇战
                    queue = value.get('_queue', [])
                    encounters = value.get('_encounters', {})
                    extraQueue = value.get('_extraQueue', {})
                    
                    # 如果所有遭遇战队列都为空，说明可能已经通关或正在章节结算
                    totalRemaining = len(queue) + len(encounters)
                    if extraQueue:
                        for eq in extraQueue.values():
                            if isinstance(eq, (list, tuple)):
                                totalRemaining += len(eq)
                    
                    logger.info('auto_chess: chapter state - chapterIdx=%s queue=%s encounters=%s extraQueue=%s totalRemaining=%s',
                               chapterIdx, len(queue), len(encounters), len(extraQueue), totalRemaining)
                    
                    # 如果 chapterIdx > 1 且所有队列为空，说明至少打过一些章节
                    # 更精确的判断：如果 queue 为空且 encounters 为空，说明当前章节完成
                    result['chapter_idx'] = chapterIdx
                    result['all_chapter_over'] = (totalRemaining == 0 and chapterIdx > 1)
            
            return result
            
        except Exception as e:
            logger.exception('auto_chess: failed to parse trainer state from stateset: %s', e)
            return {}
    
    def _parseBattlesFromStateSet(self, stateset):
        """从 stateset 解析战斗结果
        
        stateset 是前端 msgpack 编码的游戏状态
        前端数据结构: {refData: {...}, scene: "tableRef_1", ...}
        需要通过 refData 找到 encounter.data._completed 列表
        """
        import msgpack
        
        try:
            # 1. 尝试解码 stateset (处理 HTTP 传输可能的 unicode)
            if isinstance(stateset, unicode):
                stateset = stateset.encode('latin-1')
            
            # 2. 解码 (raw=True 保证二进制数据的原样性，避免 unicode 解码错误)
            data = msgpack.unpackb(stateset, raw=True)
            
            # 3. 处理双重编码 (如果解码后仍然是 byte string，说明是双重编码)
            if isinstance(data, str):
                data = msgpack.unpackb(data, raw=True)
            
            if not isinstance(data, dict):
                logger.warning('stateset is not dict: %s', type(data))
                return []
            
            # 前端打包格式：{refData: {...}, scene: "tableRef_1", ...}
            # refData 存储所有对象数据，scene 是引用字符串
            # 注意：由于使用了 raw=True，所有 key 都是 byte string
            refData = data.get('refData', {})
            sceneRef = data.get('scene', '')
            
            if not refData or not sceneRef:
                logger.warning('stateset missing refData or scene')
                return []
            
            # 通过引用链找到 _completed
            # 注意：前端 pack.lua 显示 ChessEncounterDataModel 没有 _completed 字段
            # 因此我们直接遍历 refData，寻找所有带有 result 和 sid 的战斗对象
            battles = []
            
            # Debug: 统计 refData 中的对象类型
            class_counts = {}
            
            for key, obj in refData.items():
                if not isinstance(obj, dict):
                    continue
                
                class_name = obj.get('__className')
                if class_name:
                    class_counts[class_name] = class_counts.get(class_name, 0) + 1

                # 检查是否为战斗对象
                # 方式1: 通过 __className (更准确)
                if class_name == 'AutoChessEncounterBattle':
                    sid = obj.get('sid')
                    result = obj.get('result')
                    logger.info('Found AutoChessEncounterBattle: id=%s sid=%s result=%s', obj.get('id'), sid, result)
                    
                    if sid:
                        battles.append({
                            'id': obj.get('id'),
                            'sid': sid,
                            'result': result,
                        })
                    continue

                # 方式2: 特征匹配 (回退方案)
                sid = obj.get('sid')
                result = obj.get('result')
                if sid and result:
                     # 避免重复添加 (虽然有 continue)
                    pass
            
            logger.info('Parsed %d battles from stateset refData. Class counts: %s', len(battles), class_counts)
            return battles
            
        except Exception as e:
            logger.warning('Failed to parse stateset: %s', e)
            import traceback
            logger.warning('Traceback: %s', traceback.format_exc())
            return []
    
    def _addTrainerExp(self, trainerID, exp):
        """增加训练家经验并处理升级"""
        trainers = self.trainers or {}
        if trainerID not in trainers:
            return
        
        trainer = trainers[trainerID]
        currentExp = trainer.get('exp', 0)
        currentLevel = trainer.get('level', 1)
        
        newExp = currentExp + exp
        newLevel = currentLevel
        
        # 检查升级
        while True:
            levelCfg = _get_trainer_level_csv(newLevel)
            if not levelCfg:
                break
            
            expNeeded = getattr(levelCfg, 'exp', 0)
            if expNeeded <= 0 or newExp < expNeeded:
                break
            
            # 升级
            newExp -= expNeeded
            newLevel += 1
        
        trainer['exp'] = newExp
        trainer['level'] = newLevel
        self.trainers = trainers

    # ============================================================================
    # 扫荡系统
    # ============================================================================

    def canSaodang(self):
        """检查是否可以扫荡
        
        解锁条件（满足任一）：
        1. 等级解锁（unlock.csv ID=432）
        2. role.achievement_counter[105] >= 10（与前端原版逻辑保持一致）
        
        注意：TargetDefs.DrawGem (105) 同时用于符石抽奖和卡牌冒险通关统计
        """
        # 检查次数
        if (self.times or 0) <= 0:
            return False, 'no times'
        
        # 检查功能解锁
        role_level = 0
        role_achievement_counter = {}
        if hasattr(self, '_game') and self._game and hasattr(self._game, 'role'):
            role_level = self._game.role.level or 0
            role_achievement_counter = self._game.role.achievement_counter or {}
        
        saodang_unlock_level = self._getUnlockLevel(432)  # unlock.csv autoChessSaodang
        
        # 条件1: 等级解锁
        if role_level >= saodang_unlock_level:
            return True, ''
        
        # 条件2: role.achievement_counter[105] 达标（与前端保持一致）
        pass_times = role_achievement_counter.get(TargetDefs.DrawGem, 0)
        pass_times_condition = self._getCommonConfigValue('autoChessSaodangPvePassTimes')  # common_config.csv: 10次
        
        if pass_times >= pass_times_condition:
            return True, ''
        
        return False, 'function not unlocked'
    
    def _getUnlockLevel(self, unlockID):
        """获取解锁功能所需等级
        
        Raises:
            ClientError: 配置不存在时抛出错误
        """
        if not hasattr(csv, 'unlock'):
            raise ClientError('unlock.csv not loaded')
        
        if unlockID not in csv.unlock:
            raise ClientError('unlock.csv missing unlockID: %s' % unlockID)
        
        unlock_cfg = csv.unlock[unlockID]
        if not hasattr(unlock_cfg, 'startLevel'):
            raise ClientError('unlock.csv[%s] missing startLevel field' % unlockID)
        
        return unlock_cfg.startLevel or 1
    
    def _getCommonConfigValue(self, key, default=None):
        """获取通用配置值
        
        Args:
            key: 配置key
            default: 默认值，如果为None且配置不存在则抛出错误
            
        Raises:
            ClientError: 配置不存在且未提供默认值时抛出错误
        """
        if not hasattr(csv, 'common_config'):
            if default is None:
                raise ClientError('common_config.csv not loaded')
            return default
        
        cfg = csv.common_config.get(key)
        if cfg and hasattr(cfg, 'value'):
            return cfg.value
        
        # 配置不存在
        if default is None:
            raise ClientError('common_config.csv missing key: %s' % key)
        return default

    def doSaodang(self):
        """执行扫荡
        
        返回格式 (前端 sweep_detail.lua 期望):
        {
            'csvID': 档次ID,
            'saodang_counter': 扫荡次数,
            'times': 剩余次数,
            'awards': {itemID: count, ...}
        }
        """
        can, reason = self.canSaodang()
        if not can:
            raise ClientError(reason)

        # 消耗次数
        self.times = (self.times or 0) - 1
        self.saodang_counter = (self.saodang_counter or 0) + 1
        self.total_games = (self.total_games or 0) + 1
        self.total_wins = (self.total_wins or 0) + 1

        # 计算扫荡奖励 (返回 csvID 和 awards)
        csvID, awards = self._calculateSaodangAwards()

        # 【游戏规则】快速扫荡不增加训练家精通，不会视为通关，但可计入挑战次数
        # 注意：不给训练家经验，不检查具体通关成就
        # total_games/total_wins 已在上面累加，可完成挑战次数相关的成就

        return {
            'csvID': csvID,
            'saodang_counter': self.saodang_counter,
            'times': self.times,
            'awards': awards,
        }

    def _calculateSaodangExp(self):
        """计算扫荡经验（从 monster.csv 统计平均经验）
        
        扫荡视为完成当前训练家的所有章节（通常为 8 个章节）
        
        返回: 平均经验值
        
        Raises:
            ClientError: monster.csv 配置缺失或无效
        """
        if not hasattr(csv, 'auto_chess') or not hasattr(csv.auto_chess, 'monster'):
            raise ClientError('monster.csv not loaded')
        
        totalExp = 0
        count = 0
        
        # 遍历所有怪物配置，统计胜利经验
        for monsterID in csv.auto_chess.monster:
            monsterCfg = csv.auto_chess.monster[monsterID]
            expCfg = getattr(monsterCfg, 'exp', {})
            if isinstance(expCfg, dict):
                winExp = expCfg.get('win', 0)
                if winExp > 0:
                    totalExp += winExp
                    count += 1
        
        # 如果没有有效的经验配置，报错
        if count == 0:
            raise ClientError('monster.csv has no valid exp config')
        
        avgExp = totalExp / count
        
        # 获取当前训练家的章节数量
        trainerID = self.trainer or 0
        if trainerID:
            chapters = self._getTrainerChapters(trainerID)
            chapterCount = len(chapters)
        else:
            # 如果没有训练家，默认使用 8 个章节
            chapterCount = 8
        
        # 扫荡经验 = 平均经验 × 章节数量
        return int(avgExp * chapterCount)
    
    def _calculateSaodangAwards(self):
        """计算扫荡奖励
        
        返回: (csvID, awards) 元组
        """
        if not hasattr(csv, 'auto_chess') or not hasattr(csv.auto_chess, 'saodang_award'):
            return (1, {})

        # 根据权重随机选择一个档次
        totalWeight = 0
        weightList = []
        for awardID in csv.auto_chess.saodang_award:
            cfg = csv.auto_chess.saodang_award[awardID]
            weight = getattr(cfg, 'weight', 0)
            totalWeight += weight
            weightList.append((awardID, weight))

        if totalWeight <= 0:
            return (1, {})

        # 随机选择
        randVal = random.randint(1, totalWeight)
        selectedID = weightList[0][0]
        cumWeight = 0
        for awardID, weight in weightList:
            cumWeight += weight
            if randVal <= cumWeight:
                selectedID = awardID
                break

        # 获取奖励配置
        cfg = csv.auto_chess.saodang_award[selectedID]
        generalAward = getattr(cfg, 'generalAward', {}) or {}
        libsAward = getattr(cfg, 'libsAward', {}) or {}

        # 计算实际奖励的辅助函数
        def _processAwardList(awardDict):
            """处理奖励列表
            
            支持两种格式:
            1. [[数量, 权重], [数量, 权重], ...] - 用于道具（如 7346）
            2. [最小值, 最大值] - 用于货币（如 coin19, gold）
            """
            result = {}
            for itemID, valueList in awardDict.items():
                if not isinstance(valueList, (list, tuple)) or len(valueList) == 0:
                    continue
                
                # 判断格式：检查第一个元素是否是列表/元组
                firstItem = valueList[0]
                
                # 格式1: [[数量, 权重], ...] - 嵌套列表
                if isinstance(firstItem, (list, tuple)):
                    # 计算总权重
                    totalWeight = 0
                    for item in valueList:
                        if isinstance(item, (list, tuple)) and len(item) >= 2:
                            totalWeight += int(item[1])  # item[1] 是权重
                    
                    if totalWeight <= 0:
                        continue
                    
                    # 根据权重随机选择一个数量
                    randVal = random.randint(1, totalWeight)
                    cumWeight = 0
                    amount = 0
                    for item in valueList:
                        if isinstance(item, (list, tuple)) and len(item) >= 2:
                            cumWeight += int(item[1])
                            if randVal <= cumWeight:
                                amount = int(item[0])  # item[0] 是数量
                                break
                    
                    if amount > 0:
                        result[itemID] = result.get(itemID, 0) + amount
                
                # 格式2: [最小值, 最大值] - 简单列表
                elif len(valueList) == 2:
                    minVal = int(valueList[0])
                    maxVal = int(valueList[1])
                    amount = random.randint(minVal, maxVal)
                    if amount > 0:
                        result[itemID] = result.get(itemID, 0) + amount
            
            return result

        # 处理通用奖励和库藏奖励
        awards = {}
        
        # generalAward 格式: {itemID: [[数量, 权重], [数量, 权重], ...]}
        # 例如: 7346=<<0;10>;<1;30>;<1;30>> 解析为 {7346: [[0, 10], [1, 30], [1, 30]]}
        generalResult = _processAwardList(generalAward)
        for itemID, count in generalResult.items():
            awards[itemID] = awards.get(itemID, 0) + count
        
        # libsAward 格式: {libID: [[数量, 权重], [数量, 权重], ...]}
        # libID 是 draw_items_lib.csv 的库ID，需要转换为 'libs' 字段
        libsResult = _processAwardList(libsAward)
        if libsResult:
            if 'libs' not in awards:
                awards['libs'] = []
            # libsResult 的 key 是库ID，value 是抽取次数
            for libID, count in libsResult.items():
                # 将库ID重复 count 次添加到 libs 列表
                for _ in xrange(count):
                    awards['libs'].append(libID)
        
        return (selectedID, awards)

    # ============================================================================
    # 新手引导
    # ============================================================================

    def completeGuide(self, guideID):
        """完成新手引导"""
        guides = list(self.newbie_guide or [])
        if guideID in guides:
            return False
        guides.append(guideID)
        self.newbie_guide = guides
        return True

    # ============================================================================
    # 成就系统
    # ============================================================================

    def updateAchievementTask(self, taskID, value):
        """更新成就任务进度"""
        tasks = dict(self.achievement_tasks or {})
        oldValue = tasks.get(taskID, 0)
        if value > oldValue:
            tasks[taskID] = value
            self.achievement_tasks = tasks

            # 检查是否完成成就
            taskCfg = _get_achievement_task_csv(taskID)
            if taskCfg:
                targetArg = getattr(taskCfg, 'targetArg', 9999)
                if value >= targetArg:
                    # 成就完成，增加积分
                    point = getattr(taskCfg, 'point', 0)
                    if point > 0:
                        self.achievement_points = (self.achievement_points or 0) + point

        return tasks.get(taskID, 0)

    def addAchievementCounter(self, counterType, value=1):
        """增加成就计数器"""
        counters = dict(self.achievement_counter or {})
        counters[counterType] = counters.get(counterType, 0) + value
        self.achievement_counter = counters
        return counters[counterType]

    def claimAchievementBoxAward(self, levelID):
        """领取成就宝箱奖励"""
        awards = list(self.achievement_box_awards or [])
        if levelID in awards:
            raise ClientError('already claimed')

        # 检查积分是否足够
        levelCfg = _get_achievement_level_csv(levelID)
        if not levelCfg:
            raise ClientError('level not found')

        needPoints = getattr(levelCfg, 'point', 9999)
        if (self.achievement_points or 0) < needPoints:
            raise ClientError('points not enough')

        awards.append(levelID)
        self.achievement_box_awards = awards

        # 返回奖励配置
        return getattr(levelCfg, 'awards', {}) or {}

    def getClaimableAchievementLevels(self):
        """获取可领取的成就等级列表"""
        if not hasattr(csv, 'auto_chess') or not hasattr(csv.auto_chess, 'achievement_level'):
            return []

        claimable = []
        points = self.achievement_points or 0
        claimed = self.achievement_box_awards or []

        for levelID in csv.auto_chess.achievement_level:
            if levelID in claimed:
                continue
            cfg = csv.auto_chess.achievement_level[levelID]
            needPoints = getattr(cfg, 'point', 9999)
            if points >= needPoints:
                claimable.append(levelID)

        return claimable

    # ============================================================================
    # 图鉴系统
    # ============================================================================

    def _unlockHandbooksFromGame(self, endData):
        """从游戏结束数据中激活图鉴
        
        根据前端说明：
        - 在正式挑战模式中从手牌打出到场上的卡牌会在本局结束后点亮图鉴
        - 打出4星精灵可以直接解锁1星和2星的点亮奖励
        
        Args:
            endData: 游戏结束数据，包含 units 字段 [{unitID, star, ...}, ...]
        """
        if not endData:
            logger.warning('auto_chess: _unlockHandbooksFromGame called with empty endData')
            return
        
        units = endData.get('units', [])
        if not units:
            logger.warning('auto_chess: _unlockHandbooksFromGame no units in endData: %s', endData.keys())
            return
        
        logger.info('auto_chess: _unlockHandbooksFromGame processing %s units', len(units))
        
        # 遍历本局打出的精灵，激活图鉴
        for unit in units:
            if isinstance(unit, dict):
                unitID = unit.get('unitID', 0)
                star = unit.get('star', 1)
            elif isinstance(unit, (list, tuple)) and len(unit) >= 2:
                # 支持 [unitID, star] 格式
                unitID = unit[0]
                star = unit[1]
            else:
                # 只有 unitID
                unitID = unit if isinstance(unit, int) else 0
                star = 1
            
            if unitID <= 0:
                logger.warning('auto_chess: skip invalid unitID: %s', unit)
                continue
            
            # 激活图鉴
            self.unlockHandbook(unitID, star)
            logger.info('auto_chess: unlock handbook cardID=%s star=%s', unitID, star)

    def unlockHandbook(self, cardID, star=1):
        """解锁图鉴"""
        handbook = dict(self.handbook or {})
        handbook_award = dict(self.handbook_award or {})
        
        if cardID not in handbook:
            handbook[cardID] = {
                'star': star,
                'count': 1,
                'first_time': time.time(),
                'award': {},  # 前端期望的奖励领取状态字段
                'max_star': star,  # 前端期望的最高星级字段
            }
        else:
            cardData = handbook[cardID]
            cardData['count'] = cardData.get('count', 0) + 1
            if star > cardData.get('star', 0):
                cardData['star'] = star
            if star > cardData.get('max_star', 0):
                cardData['max_star'] = star
            
            # 确保 award 字段存在
            if 'award' not in cardData:
                cardData['award'] = {}
        
        # 同步奖励领取状态到 handbook.award 字段（用于前端红点检查）
        if cardID in handbook_award:
            handbook[cardID]['award'] = handbook_award[cardID]
        
        self.handbook = handbook
        return True

    def claimHandbookAward(self, cardID, star):
        """领取图鉴奖励
        
        Args:
            cardID: 卡牌ID
            star: 星级（1, 2, 4）
            
        Returns:
            dict: 奖励 {itemID: count, ...}
        """
        # 检查图鉴是否解锁到该星级
        handbook = self.handbook or {}
        if cardID not in handbook:
            raise ClientError('card not unlocked')
        cardData = handbook[cardID]
        if cardData.get('star', 0) < star:
            raise ClientError('star not reached')

        # 检查是否已领取（嵌套map使用整数key）
        awards = dict(self.handbook_award or {})
        if cardID not in awards:
            awards[cardID] = {}
        if star in awards[cardID]:
            raise ClientError('already claimed')

        awards[cardID][star] = True
        self.handbook_award = awards
        
        # 同步到 handbook.award 字段（用于前端红点检查）
        handbook = dict(self.handbook or {})
        if cardID in handbook:
            handbook[cardID]['award'] = awards[cardID]
            self.handbook = handbook

        # 获取卡牌品质
        cardCfg = _get_card_csv(cardID)
        if not cardCfg:
            logger.warning('auto_chess: card %s not found in cards.csv', cardID)
            return {}
        
        rarity = getattr(cardCfg, 'rarity', 1)
        
        # 根据品质获取奖励配置
        awardCfg = _get_handbook_award_csv(rarity)
        if not awardCfg:
            logger.warning('auto_chess: handbook_award rarity %s not found', rarity)
            return {}
        
        # 根据星级返回对应的奖励字段
        if star == 1:
            return getattr(awardCfg, 'star1_award', {}) or {}
        elif star == 2:
            return getattr(awardCfg, 'star2_award', {}) or {}
        elif star == 4:
            return getattr(awardCfg, 'star4_award', {}) or {}
        else:
            logger.warning('auto_chess: invalid star %s for handbook award', star)
            return {}

    # ============================================================================
    # 商城系统
    # ============================================================================

    def buyShopItem(self, shopID, count=1):
        """购买商城道具"""
        shopCfg = _get_shop_csv(shopID)
        if not shopCfg:
            raise ClientError('shop item not found')

        # 检查限购
        limitTimes = getattr(shopCfg, 'limitTimes', 0)
        if limitTimes > 0:
            bought = self.getShopBuyCount(shopID)
            if bought + count > limitTimes:
                raise ClientError('buy limit exceeded')

        # 更新购买计数
        counters = dict(self.shop_buy_counter or {})
        counters[shopID] = counters.get(shopID, 0) + count
        self.shop_buy_counter = counters

        return counters[shopID]

    def getShopBuyCount(self, shopID):
        """获取商品购买次数"""
        counters = self.shop_buy_counter or {}
        return counters.get(shopID, 0)

    def getShopCost(self, shopID, count=1):
        """获取商品消耗"""
        shopCfg = _get_shop_csv(shopID)
        if not shopCfg:
            return {}
        costMap = getattr(shopCfg, 'costMap', {}) or {}
        # 乘以数量
        result = {}
        for itemID, amount in costMap.iteritems():
            result[itemID] = amount * count
        return result

    def getShopItems(self, shopID, count=1):
        """获取商品内容"""
        shopCfg = _get_shop_csv(shopID)
        if not shopCfg:
            return {}
        itemMap = getattr(shopCfg, 'itemMap', {}) or {}
        # 乘以数量
        result = {}
        for itemID, amount in itemMap.iteritems():
            result[itemID] = amount * count
        return result


# ============================================================================
# ObjectAutoChessShop - 商店数据（独立Collection）
# ============================================================================

class ObjectAutoChessShop(ObjectDBase):
    """卡牌冒险商店数据"""
    DBModel = 'AutoChessShop'
    ClientIgnores = set(['id'])

    buy_counter = db_property('buy_counter')
    refresh_date = db_property('refresh_date')
    limit_items = db_property('limit_items')

    inited = False

    @classmethod
    def classInit(cls):
        pass

    def init(self):
        if self.db is None:
            return self
        ObjectDBase.init(self)
        self._ensureDefaults()
        self.inited = True
        return self

    def set(self, dic):
        if dic is None:
            dic = {}
        ObjectDBase.set(self, dic)
        self._ensureDefaults()
        return self

    def _ensureDefaults(self):
        if self.db is None:
            return
        db = self.db

        if 'id' not in db:
            from bson.objectid import ObjectId
            dict.__setitem__(db, 'id', ObjectId())

        if self.buy_counter is None:
            self.buy_counter = {}
        if self.refresh_date is None:
            self.refresh_date = todayinclock5date2int()
        if self.limit_items is None:
            self.limit_items = {}

    def refreshDaily(self, today=None):
        """每日重置"""
        if today is None:
            today = todayinclock5date2int()

        if self.refresh_date == today:
            return False

        self.buy_counter = {}
        self.limit_items = {}
        self.refresh_date = today
        return True
