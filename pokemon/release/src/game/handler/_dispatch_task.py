#!/usr/bin/python
# -*- coding: utf-8 -*-

import time
from framework.log import logger
from game import ClientError
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object import FeatureDefs, TargetDefs, DispatchTaskDefs, AchievementDefs
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.yyhuodong import ObjectYYHuoDongFactory

from tornado.gen import coroutine

# 一键领取派遣任务奖励
class dispatchTaskAwardOneKey(RequestHandlerTask):
    url = r'/game/dispatch/task/award/onekey'

    @coroutine
    def run(self):
        if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.DispatchTask, self.game):
            raise ClientError('not open')

        # 使用游戏框架提供的时间获取方法
        current_time = int(time.time())
        
        # 获取所有可领取奖励的任务
        can_award_tasks = []
        for task_index, task in enumerate(self.game.role.dispatch_tasks):
            # 根据前端逻辑，可领取的任务是状态为3且已到期的任务
            if task.get('status') == 3:
                ending_time = task.get('ending_time', 0)
                # 检查任务是否已到期（当前时间大于等于结束时间）
                if ending_time > 0 and current_time >= ending_time:
                    can_award_tasks.append({
                        'index': task_index,
                        'task_data': task
                    })
        
        # 如果没有可领取的任务，返回空结果
        if not can_award_tasks:
            logger.info("No dispatch tasks available for one-key award")
            self.write({
                'view': {
                    'result': []
                }
            })
            return

        # 先检查遗迹祝福（在领取奖励前消耗）
        relicMul = 1
        if self.game.town:
            from game.object.game.town_lottery import ObjectTownRelicBuff
            # 对于一键领取，只消耗一次祝福但应用到所有任务
            buffCfg = ObjectTownRelicBuff.consumeBuff(self.game, 6)
            if buffCfg:
                param = getattr(buffCfg, 'param', 0)
                if param > 0:
                    relicMul = 1 + param  # param=1 表示翻倍
                    logger.info('[RelicBuff] dispatch onekey: type=6 triggered, param=%s relicMul=%s', param, relicMul)
            else:
                logger.info('[RelicBuff] dispatch onekey: type=6 no buff available')

        # 存储所有任务的奖励结果
        all_results = []

        # 遍历所有可领取任务，获取奖励并应用
        for task_info in can_award_tasks:
            task_index = task_info['index']
            task_data = task_info['task_data']
            
            try:
                # 领取单个任务奖励，使用flag=False表示正常领取
                eff, extra_eff, quality = self.game.role.getDispatchTaskAward(task_index, False)
                
                # 应用奖励效果（带遗迹祝福倍率）
                if eff:
                    yield effectAutoGain(eff, self.game, self.dbcGame, src='dispatchTask_award_onekey', mul=relicMul)
                if extra_eff:
                    yield effectAutoGain(extra_eff, self.game, self.dbcGame, src='dispatchTask_award_onekey_extra', mul=relicMul)
                
                # 记录单个任务的结果
                task_result = {
                    'csvID': task_data.get('csvID'),
                    'result': eff.result if eff else {},
                    'extra': extra_eff.result if extra_eff else {}
                }
                all_results.append(task_result)
                
                # 触发运营活动计数
                ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DispatchTaskDone, 1)
                ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DispatchTaskQualityDone, quality)
                
                # 触发成就计数
                if quality == DispatchTaskDefs.AQuality:
                    self.game.achievement.onCount(AchievementDefs.DispatchTaskACount, 1)
                elif quality == DispatchTaskDefs.BQuality:
                    self.game.achievement.onCount(AchievementDefs.DispatchTaskBCount, 1)
                elif quality == DispatchTaskDefs.CQuality:
                    self.game.achievement.onCount(AchievementDefs.DispatchTaskCCount, 1)
                elif quality == DispatchTaskDefs.SQuality:
                    self.game.achievement.onCount(AchievementDefs.DispatchTaskSCount, 1)
                elif quality == DispatchTaskDefs.S2Quality:
                    self.game.achievement.onCount(AchievementDefs.DispatchTaskS2Count, 1)
                    
            except Exception as e:
                logger.warning("One key award task failed: index={} error={}".format(task_index, str(e)))
                continue

        # 刷新任务列表
        self.game.role.refreshDispatchTasks()

        # 返回结果
        self.write({
            'view': {
                'result': all_results
            }
        })

# 刷新任务列表
class dispatchTaskRefresh(RequestHandlerTask):
    url = r'/game/dispatch/task/refresh'

    @coroutine
    def run(self):
        if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.DispatchTask, self.game):
            raise ClientError('not open')

        flag = self.input.get('flag', None)
        if flag is None:
            raise ClientError('param miss')
        self.game.role.refreshDispatchTasks(flag)

# 开始任务派遣
class dispatchTaskBegin(RequestHandlerTask):
    url = r'/game/dispatch/task/begin'

    @coroutine
    def run(self):
        if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.DispatchTask, self.game):
            raise ClientError('not open')

        cardIDs = self.input.get('cardIDs', None)
        taskIndex = self.input.get('taskIndex', None)
        if cardIDs is None or taskIndex is None:
            raise ClientError('param miss')
        if len(self.game.role.dispatch_tasks) - 1 < taskIndex:
            raise ClientError('taskIndex error')

        cards = self.game.cards.getCards(cardIDs)
        if len(cards) != len(cardIDs):
            raise ClientError('card error')

        self.game.role.beginDispatchTask(taskIndex, cards)
        ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DispatchTask, 1)
        self.game.role.refreshDispatchTasks()

# 领取奖励
class dispatchTaskGetAward(RequestHandlerTask):
    url = r'/game/dispatch/task/award'

    @coroutine
    def run(self):
        if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.DispatchTask, self.game):
            raise ClientError('not open')

        flag = self.input.get('flag', None)
        taskIndex = self.input.get('taskIndex', None)
        if taskIndex is None or flag is None:
            raise ClientError('param miss')
        if len(self.game.role.dispatch_tasks) - 1 < taskIndex:
            raise ClientError('taskIndex error')

        eff, extraEff, quality = self.game.role.getDispatchTaskAward(taskIndex, flag)
        
        # 遗迹祝福 - 派遣任务奖励翻倍 (type=6)
        relicMul = 1
        if self.game.town:
            from game.object.game.town_lottery import ObjectTownRelicBuff
            buffCfg = ObjectTownRelicBuff.consumeBuff(self.game, 6)
            if buffCfg:
                param = getattr(buffCfg, 'param', 0)
                if param > 0:
                    relicMul = 1 + param  # param=1 表示翻倍
                    logger.info('[RelicBuff] dispatch award: type=6 triggered, param=%s relicMul=%s', param, relicMul)
            else:
                logger.info('[RelicBuff] dispatch award: type=6 no buff available')
        
        if eff:
            yield effectAutoGain(eff, self.game, self.dbcGame, src='dispatchTask_award', mul=relicMul)
        if extraEff:
            yield effectAutoGain(extraEff, self.game, self.dbcGame, src='dispatchTask_award_extra', mul=relicMul)
        ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DispatchTaskDone, 1)
        ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DispatchTaskQualityDone, quality)
        if quality == DispatchTaskDefs.AQuality:
            self.game.achievement.onCount(AchievementDefs.DispatchTaskACount, 1)
        elif quality == DispatchTaskDefs.BQuality:
            self.game.achievement.onCount(AchievementDefs.DispatchTaskBCount, 1)
        elif quality == DispatchTaskDefs.CQuality:
            self.game.achievement.onCount(AchievementDefs.DispatchTaskCCount, 1)
        elif quality == DispatchTaskDefs.SQuality:
            self.game.achievement.onCount(AchievementDefs.DispatchTaskSCount, 1)
        elif quality == DispatchTaskDefs.S2Quality:
            self.game.achievement.onCount(AchievementDefs.DispatchTaskS2Count, 1)
        self.game.role.refreshDispatchTasks()

        self.write({
            'view': {
                'result': eff.result,
                'extra': extraEff.result if extraEff else None,
            }
        })