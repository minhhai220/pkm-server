#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Town (家园) Handlers
根据前端 URL 实现后端接口
'''
import random
import msgpack

from framework import nowtime_t, nowdatetime_t, todayinclock5date2int, weekinclock5date2int, monthinclock5date2int
from framework.csv import csv, ErrDefs, ConstDefs
from framework.log import logger

from game import ServerError, ClientError
from game.handler.task import RequestHandlerTask
from game.object.game.gain import ObjectGainAux, ObjectCostAux

from tornado.gen import coroutine


# ============================================================================
# 建筑类型常量
# ============================================================================
class TownBuildingType:
    CENTER = 1          # 市中心
    HOME = 2            # 我的小屋
    GOLDHOUSE = 3       # 炼金厂
    CUTTINGHOUSE = 4    # 伐木场
    DESSERTHOUSE = 5    # 甜品站
    BANKHOUSE = 6       # 金融银行 (订单工厂)
    EXPLORATION = 7     # 未知探险
    GOLDHOUSE1 = 8      # 炼金厂2
    CUTTINGHOUSE1 = 9   # 伐木场2
    SUPERSHOP = 10      # 超级市场
    TERMINAL = 11       # 拜访
    WISH = 12           # 许愿池
    PARTY = 13          # 派对
    DESERT_RELIC = 14   # 大漠遗迹
    MOUNTAINOUS_RELIC = 15  # 山城遗迹
    SNOW_RELIC = 16     # 苍雪遗迹
    LAVA_RELIC = 17     # 熔岩遗迹
    REST = 101          # 小憩花园


# 家园货币/物品类型
class TownCoinType:
    TIANDIAN = 8201     # 甜点
    MUCAI = 8202        # 木材
    GANGJIEGOU = 8203   # 钢结构


# 工厂类型
class FactoryType:
    NO_TYPE = 0         # 非工厂
    NORMAL = 1          # 连续生产工厂
    ORDER = 2           # 订单工厂


# 卡牌状态（与前端 game.TOWN_CARD_STATE 对应）
class TownCardState:
    NONE = -1           # 无
    IDLE = 0            # 空闲
    TOWN = 1            # 在家园
    REST = 2            # 休息中
    ALCHEMYFACTORY = 3  # 炼金厂工作
    PRODUCTION_THREE = 4  # 甜品站工作
    PRODUCTION_FOUR = 5  # 伐木场工作
    FINANCIAL_CENTER = 6  # 金融银行工作
    ADVENTURE = 7       # 冒险中
    ALCHEMYFACTORY1 = 8  # 炼金厂2工作
    PRODUCTION_THREE1 = 9  # 伐木场2工作


# 建筑ID到卡牌工作状态的映射
BUILDING_CARD_STATUS = {
    TownBuildingType.GOLDHOUSE: TownCardState.ALCHEMYFACTORY,
    TownBuildingType.GOLDHOUSE1: TownCardState.ALCHEMYFACTORY1,
    TownBuildingType.CUTTINGHOUSE: TownCardState.PRODUCTION_FOUR,
    TownBuildingType.CUTTINGHOUSE1: TownCardState.PRODUCTION_THREE1,
    TownBuildingType.DESSERTHOUSE: TownCardState.PRODUCTION_THREE,
    TownBuildingType.BANKHOUSE: TownCardState.FINANCIAL_CENTER,
    TownBuildingType.EXPLORATION: TownCardState.ADVENTURE,
}


# 建筑ID到类型的映射
BUILDING_FACTORY_TYPE = {
    TownBuildingType.GOLDHOUSE: FactoryType.NORMAL,
    TownBuildingType.GOLDHOUSE1: FactoryType.NORMAL,
    TownBuildingType.CUTTINGHOUSE: FactoryType.NORMAL,
    TownBuildingType.CUTTINGHOUSE1: FactoryType.NORMAL,
    TownBuildingType.DESSERTHOUSE: FactoryType.NORMAL,
    TownBuildingType.BANKHOUSE: FactoryType.ORDER,
}


# 技能效果类型（对应前端 game.TOWN_SKILL_EFFECT）
class TownSkillEffect:
    # 工厂生产效果 (A/B 前缀)
    A_SPEED_UP = 1           # 生产速度增加（连续生产）
    A_INVENTORY_ADD = 2      # 库存上限增加（连续生产）
    A_ENERGY_COST_SUB = 3    # 精力消耗减少（连续生产，全体）
    B_ENERGY_COST_SUB = 4    # 精力消耗减少（订单生产，自身）
    B_TIME_COST_SUB = 5      # 订单时间减少
    # 探险效果 (C 前缀)
    C_AWARD_ADD = 6          # 普通掉落数量增加
    C_TIME_SUB = 7           # 探索时间缩短
    C_ACTION_SUB = 8         # 甜点消耗减少
    C_ENERGY_SUB = 9         # 精灵精力消耗减少
    C_EXTRA_AWARD = 10       # 额外奖励掉落几率


# 技能类型（对应 skill.csv 的 type 字段）
class TownSkillType:
    GOLDHOUSE = 3           # 炼金厂
    CUTTINGHOUSE = 4        # 伐木场
    DESSERTHOUSE = 5        # 甜品站
    BANKHOUSE = 6           # 金融银行
    EXPLORATION = 7         # 探险


# 建筑ID到技能类型的映射
BUILDING_SKILL_TYPE = {
    TownBuildingType.GOLDHOUSE: TownSkillType.GOLDHOUSE,
    TownBuildingType.GOLDHOUSE1: TownSkillType.GOLDHOUSE,
    TownBuildingType.CUTTINGHOUSE: TownSkillType.CUTTINGHOUSE,
    TownBuildingType.CUTTINGHOUSE1: TownSkillType.CUTTINGHOUSE,
    TownBuildingType.DESSERTHOUSE: TownSkillType.DESSERTHOUSE,
    TownBuildingType.BANKHOUSE: TownSkillType.BANKHOUSE,
    TownBuildingType.EXPLORATION: TownSkillType.EXPLORATION,
}


# ============================================================================
# 工具函数
# ============================================================================
def getBuildingCsv(buildingID, level=None):
    """获取建筑配置"""
    if not hasattr(csv, 'town') or not hasattr(csv.town, 'building'):
        return None
    
    for csvId in csv.town.building:
        cfg = csv.town.building[csvId]
        if cfg.buildID == buildingID:
            if level is None or cfg.level == level:
                return cfg
    return None


def getBuildingCsvByLevel(buildingID, level):
    """根据建筑ID和等级获取配置"""
    if not hasattr(csv, 'town') or not hasattr(csv.town, 'building'):
        return None
    
    for csvId in csv.town.building:
        cfg = csv.town.building[csvId]
        if cfg.buildID == buildingID and cfg.level == level:
            return cfg
    return None


def getProductionCsv(buildingID, level):
    """获取工厂生产配置"""
    if not hasattr(csv, 'town') or not hasattr(csv.town, 'production_base'):
        return None
    
    for csvId in csv.town.production_base:
        cfg = csv.town.production_base[csvId]
        if cfg.baseID == buildingID and cfg.level == level:
            return cfg
    return None


def _refreshAllCardsAttrs(game):
    """刷新所有卡牌属性和战力（全局加成变化后调用）"""
    try:
        refreshedCount = 0
        for cardID in game.role.cards:
            card = game.cards.getCard(cardID)
            if card:
                if getattr(card, '_attrs', None) is None or getattr(card, '_attrs2', None) is None:
                    card.onUpdateAttrs()
                else:
                    try:
                        card.calcTownRelicAttrsAddition(card)
                        card.calcTownHomeCollectionAttrsAddition(card)
                        card.calcTownHomeFurnitureSeriesAttrsAddition(card)
                        card.refreshFromCalc()
                    except Exception:
                        card.onUpdateAttrs()
                # 调用 display() 将更新后的属性同步到前端
                card.display()
                refreshedCount += 1
        # 触发战力变更处理（更新 battle_fighting_point 等）
        game.cards.onFightingPointChange()
        logger.info('_refreshAllCardsAttrs: role=%s cards=%d refreshed', game.role.id, refreshedCount)
    except Exception as e:
        logger.error('_refreshAllCardsAttrs error: %s', e)


def _addCollectionExpAndCheckLevelUp(game, expGain):
    """增加收藏经验并检查升级
    
    Args:
        game: 游戏对象
        expGain: 增加的经验值
        
    前端经验显示逻辑：
        collection_exp 是累积总经验
        当前等级进度 = collection_exp - sum(needExp[1..currentLevel])
        升级所需 = needExp[currentLevel + 1]
    """
    if expGain <= 0:
        return
    
    townHome = game.role.town_home or {}
    oldLevel = townHome.get('collection_level', 1)
    currentExp = townHome.get('collection_exp', 0)
    
    # 增加累积经验
    currentExp += expGain
    
    # 构建等级配置映射 {level: needExp}
    levelConfigs = {}
    maxLevel = 1
    for cfgId in csv.town.home_collection:
        cfg = csv.town.home_collection[cfgId]
        levelConfigs[cfg.level] = cfg.needExp or 0
        if cfg.level > maxLevel:
            maxLevel = cfg.level
    
    # 计算每个等级的累积经验阈值
    # 升到 level N 需要的累积经验 = needExp[1] + needExp[2] + ... + needExp[N]
    levelThresholds = {}
    accumulatedExp = 0
    for level in range(1, maxLevel + 1):
        accumulatedExp += levelConfigs.get(level, 0)
        levelThresholds[level] = accumulatedExp
    
    # 根据累积经验确定等级
    # 如果累积经验 >= 升到 level N 的阈值，则等级为 N
    currentLevel = 1
    for level in range(1, maxLevel + 1):
        if currentExp >= levelThresholds[level]:
            currentLevel = level
        else:
            break
    
    # 保存更新后的数据
    townHome['collection_level'] = currentLevel
    townHome['collection_exp'] = currentExp
    game.role.town_home = townHome
    
    # 如果等级提升，刷新所有卡牌属性和战力
    if currentLevel > oldLevel:
        _refreshAllCardsAttrs(game)
        logger.info('Collection level up: role=%s oldLevel=%s newLevel=%s', 
                    game.role.id, oldLevel, currentLevel)
    
    logger.info('Collection exp added: role=%s expGain=%s level=%s totalExp=%s', 
                game.role.id, expGain, currentLevel, currentExp)


def _checkFurnitureSeriesCollection(game, furniture, affectedSeriesIDs):
    """检查套装收集情况
    
    当玩家获得家具时，检查是否集齐了套装，如果是则更新 furniture_series 字段。
    
    Args:
        game: 游戏对象
        furniture: 玩家拥有的家具 {家具ID: 数量}
        affectedSeriesIDs: 受影响的套装ID集合
    """
    if not game or not game.role:
        return
    
    # 构建套装 -> 家具列表的映射（只处理受影响的套装）
    seriesFurnitureMap = {}  # {seriesID: [furnitureID, ...]}
    for furID in csv.town.home_furniture:
        furCfg = csv.town.home_furniture[furID]
        seriesID = furCfg.series or 0
        if seriesID > 0 and seriesID in affectedSeriesIDs:
            if seriesID not in seriesFurnitureMap:
                seriesFurnitureMap[seriesID] = []
            seriesFurnitureMap[seriesID].append(furID)
    
    # 获取当前已收集的套装（字典格式 {seriesID: True}）
    townHome = game.role.town_home or {}
    furnitureSeries = townHome.get('furniture_series', {})
    if not isinstance(furnitureSeries, dict):
        furnitureSeries = {}
    
    # 检查每个受影响的套装
    newlyCollected = []
    for seriesID in affectedSeriesIDs:
        # 已经收集过的套装跳过
        if seriesID in furnitureSeries:
            continue
        
        # 检查该套装配置是否存在
        if seriesID not in csv.town.home_furniture_series:
            continue
        
        # 获取该套装包含的所有家具
        requiredFurniture = seriesFurnitureMap.get(seriesID, [])
        if not requiredFurniture:
            continue
        
        # 检查是否拥有所有家具
        hasAll = True
        for furID in requiredFurniture:
            if furniture.get(furID, 0) <= 0:
                hasAll = False
                break
        
        # 如果集齐，添加到已收集套装
        if hasAll:
            furnitureSeries[seriesID] = True
            newlyCollected.append(seriesID)
            
            # 获取套装经验加成
            seriesCfg = csv.town.home_furniture_series[seriesID]
            expAdd = seriesCfg.expAdd or 0
            if expAdd > 0:
                _addCollectionExpAndCheckLevelUp(game, expAdd)
            
            logger.info('Series collected: role=%s seriesID=%s seriesName=%s', 
                        game.role.id, seriesID, seriesCfg.name)
    
    # 保存更新后的数据
    if newlyCollected:
        townHome['furniture_series'] = furnitureSeries
        game.role.town_home = townHome
        # 刷新所有卡牌属性（套装属性加成变化）
        _refreshAllCardsAttrs(game)


def getCardMaxEnergy(game, cardDbId):
    """计算卡牌在家园的最大能量值
    
    公式: cardCsv.energy + (energyCfg.advanceAdd * advance + energyCfg.starAdd * star) * cardCsv.energyCorrection
    """
    try:
        # 获取卡牌数据（使用 getCard 方法而不是 get）
        card = game.cards.getCard(cardDbId)
        if card is None:
            return 100  # 默认值
        
        cardId = card.card_id
        advance = card.advance or 0
        star = card.star or 0
        
        # 获取卡牌配置
        if cardId not in csv.cards:
            return 100
        cardCfg = csv.cards[cardId]
        
        baseEnergy = getattr(cardCfg, 'energy', 100)
        energyCorrection = getattr(cardCfg, 'energyCorrection', 1)
        unitId = getattr(cardCfg, 'unitID', 0)
        
        # 获取单位配置
        if unitId and unitId in csv.unit:
            unitCfg = csv.unit[unitId]
            rarity = getattr(unitCfg, 'rarity', 1)
            
            # 获取能量配置
            if hasattr(csv, 'town') and hasattr(csv.town, 'energy'):
                for csvId in csv.town.energy:
                    energyCfg = csv.town.energy[csvId]
                    if getattr(energyCfg, 'rarity', 0) == rarity:
                        advanceAdd = getattr(energyCfg, 'advanceAdd', 0)
                        starAdd = getattr(energyCfg, 'starAdd', 0)
                        return int(baseEnergy + (advanceAdd * advance + starAdd * star) * energyCorrection)
        
        return int(baseEnergy)
    except Exception as e:
        logger.warning('getCardMaxEnergy error: %s', e)
        return 100  # 出错时返回默认值


def getCardSkillCfg(game, cardDbId):
    """获取卡牌的家园技能配置
    
    根据卡牌的 advance 和 star 返回当前激活的技能配置
    返回: (skillCfg, skillID) 或 (None, 0)
    """
    try:
        card = game.cards.getCard(cardDbId)
        if card is None:
            return None, 0
        
        cardId = card.card_id
        advance = card.advance or 0
        star = card.star or 0
        
        # 获取卡牌配置
        if cardId not in csv.cards:
            return None, 0
        cardCfg = csv.cards[cardId]
        
        skillId = getattr(cardCfg, 'townSkill', 0)
        if skillId == 0:
            return None, 0
        
        # 获取技能配置
        if not hasattr(csv, 'town') or not hasattr(csv.town, 'skill'):
            return None, skillId
        
        # 遍历技能配置，找到匹配 skill (技能编号) 的配置
        skillConfigs = []
        for csvId in csv.town.skill:
            cfg = csv.town.skill[csvId]
            if getattr(cfg, 'skill', 0) == skillId:
                skillConfigs.append(cfg)
        
        if not skillConfigs:
            return None, skillId
        
        # 按等级排序，从高到低检查条件
        skillConfigs.sort(key=lambda x: getattr(x, 'level', 1), reverse=True)
        
        for cfg in skillConfigs:
            needAdvance = getattr(cfg, 'needAdvance', 0)
            needStar = getattr(cfg, 'needStar', 0)
            if advance >= needAdvance and star >= needStar:
                return cfg, skillId
        
        return None, skillId
    except Exception as e:
        logger.warning('getCardSkillCfg error: %s', e)
        return None, 0


def parsePercentStr(val):
    """解析百分比字符串
    
    返回: (数值, 是否百分比)
    例如: "10%" -> (10.0, True), "5" -> (5.0, False)
    """
    if isinstance(val, (int, float)):
        return float(val), False
    
    valStr = str(val).strip()
    if valStr.endswith('%'):
        return float(valStr[:-1]), True
    return float(valStr), False


def getCardSkillEffect(game, cardDbId, buildingID, factoryType, energyCur=0, orderNum=1):
    """计算卡牌在工厂的技能效果
    
    Args:
        game: 游戏对象
        cardDbId: 卡牌数据库ID
        buildingID: 工厂建筑ID
        factoryType: 工厂类型 (1=连续生产, 2=订单生产)
        energyCur: 当前能量（订单生产用）
        orderNum: 订单数量（订单生产用）
    
    Returns:
        dict: {
            'productEffect': 生产速度加成,
            'inventoryEffect': 库存加成,
            'normalEnergyReduce': 精力消耗减少（连续生产，取最大值）,
            'orderEnergyCost': 精力消耗减少（订单生产）,
            'orderTimeReduce': 订单时间减少
        }
    """
    result = {
        'productEffect': 0,
        'inventoryEffect': 0,
        'normalEnergyReduce': 0,
        'orderEnergyCost': 0,
        'orderTimeReduce': 0,
    }
    
    try:
        skillCfg, skillId = getCardSkillCfg(game, cardDbId)
        if skillCfg is None:
            return result
        
        # 检查技能类型是否匹配当前建筑
        skillType = getattr(skillCfg, 'type', 0)
        buildingSkillType = BUILDING_SKILL_TYPE.get(buildingID, 0)
        if skillType != 0 and skillType != buildingSkillType:
            return result
        
        # 获取工厂生产配置
        buildings = game.town.buildings or {}
        buildData = buildings.get(buildingID, {})
        curLevel = buildData.get('level', 1)
        prodCfg = getProductionCsv(buildingID, curLevel)
        if prodCfg is None:
            return result
        
        efficient = getattr(prodCfg, 'efficient', 0)
        inventory = getattr(prodCfg, 'inventory', 100)
        energyExpend = getattr(prodCfg, 'energyExpend', 1)
        orderCostTime = getattr(prodCfg, 'orderCostTime', 180)
        
        # 收集技能效果
        effectMap = {}
        for i in range(1, 10):
            effect = getattr(skillCfg, 'effect%d' % i, 0)
            if effect and effect != 0:
                params = getattr(skillCfg, 'params%d' % i, None)
                effectMap[effect] = params
            else:
                break
        
        # 计算各种效果
        for skillEffect, params in effectMap.items():
            if not params:
                continue
            
            # 解析参数（取第一个值）
            paramVal = params[0] if isinstance(params, (list, tuple)) and len(params) > 0 else params
            
            if skillEffect == TownSkillEffect.A_SPEED_UP:
                # 生产速度增加
                n, isPercent = parsePercentStr(paramVal)
                if isPercent:
                    result['productEffect'] += efficient * n / 100.0
                else:
                    result['productEffect'] += n
            
            elif skillEffect == TownSkillEffect.A_INVENTORY_ADD:
                # 库存上限增加
                n, isPercent = parsePercentStr(paramVal)
                if isPercent:
                    result['inventoryEffect'] += inventory * n / 100.0
                else:
                    result['inventoryEffect'] += n
            
            elif skillEffect == TownSkillEffect.A_ENERGY_COST_SUB:
                # 精力消耗减少（连续生产，取最大值）
                n, isPercent = parsePercentStr(paramVal)
                if isPercent:
                    energy = energyExpend * n / 100.0
                else:
                    energy = n
                result['normalEnergyReduce'] = max(energy, result['normalEnergyReduce'])
            
            elif skillEffect == TownSkillEffect.B_ENERGY_COST_SUB and factoryType == 2:
                # 精力消耗减少（订单生产）
                n, isPercent = parsePercentStr(paramVal)
                if isPercent:
                    result['orderEnergyCost'] = energyExpend * n / 100.0
                else:
                    result['orderEnergyCost'] = n
            
            elif skillEffect == TownSkillEffect.B_TIME_COST_SUB and factoryType == 2:
                # 订单时间减少
                n, _ = parsePercentStr(paramVal)
                # 计算实际可工作时间
                effectiveEnergyExpend = energyExpend - result['orderEnergyCost']
                if effectiveEnergyExpend > 0:
                    canUpTime = energyCur / effectiveEnergyExpend * 3600
                    useTime = min(canUpTime, orderCostTime * orderNum)
                    result['orderTimeReduce'] += useTime * n / 100.0
        
        return result
    except Exception as e:
        logger.warning('getCardSkillEffect error: %s', e)
        return result


def calculateFactorySkillEffects(game, buildingID, factoryType, energyCur=0, orderNum=1):
    """计算工厂所有卡牌的总技能效果
    
    Args:
        game: 游戏对象
        buildingID: 工厂建筑ID
        factoryType: 工厂类型 (1=连续生产, 2=订单生产)
        energyCur: 当前能量（订单生产用）
        orderNum: 订单数量（订单生产用）
    
    Returns:
        dict: 汇总的技能效果
    """
    totalEffect = {
        'productEffect': 0,
        'inventoryEffect': 0,
        'normalEnergyReduce': 0,
        'orderEnergyCost': 0,
        'orderTimeReduce': 0,
    }
    
    # 获取工厂中的卡牌列表
    if factoryType == FactoryType.NORMAL:
        factory = game.town.continuous_factory or {}
    else:
        factory = game.town.order_factory or {}
    
    factoryData = factory.get(buildingID, {})
    cardIDs = factoryData.get('card_ids', {})
    # 兼容字典和列表格式
    if isinstance(cardIDs, dict):
        cardIDList = cardIDs.values()
    else:
        cardIDList = cardIDs if cardIDs else []
    
    for cardDbId in cardIDList:
        if not cardDbId:
            continue
        
        effect = getCardSkillEffect(game, cardDbId, buildingID, factoryType, energyCur, orderNum)
        
        totalEffect['productEffect'] += effect['productEffect']
        totalEffect['inventoryEffect'] += effect['inventoryEffect']
        # normalEnergyReduce 取最大值
        totalEffect['normalEnergyReduce'] = max(totalEffect['normalEnergyReduce'], effect['normalEnergyReduce'])
        totalEffect['orderEnergyCost'] += effect['orderEnergyCost']
        totalEffect['orderTimeReduce'] += effect['orderTimeReduce']
    
    return totalEffect


def getExplorerTownSkillCfg(game, explorerID):
    """获取探险器的家园技能配置
    
    Args:
        game: 游戏对象
        explorerID: 探险器ID
    
    Returns:
        (skillCfg, skillLevel) 或 (None, 0)
    """
    try:
        explorers = game.role.explorers or {}
        explorerData = explorers.get(explorerID, {})
        skillLevel = explorerData.get('town_skill_level', 0)
        
        if skillLevel <= 0:
            return None, 0
        
        # 获取探险器配置
        if explorerID not in csv.explorer.explorer:
            return None, 0
        explorerCfg = csv.explorer.explorer[explorerID]
        townSkillID = getattr(explorerCfg, 'townSkill', 0)
        if not townSkillID:
            return None, 0
        
        # 查找对应等级的技能配置
        for skillCfgId in csv.town.skill:
            skillCfg = csv.town.skill[skillCfgId]
            skill = getattr(skillCfg, 'skill', 0)
            level = getattr(skillCfg, 'level', 0)
            if skill == townSkillID and level == skillLevel:
                return skillCfg, skillLevel
        
        return None, skillLevel
    except Exception as e:
        logger.warning('getExplorerTownSkillCfg error: %s', e)
        return None, 0


def getCardExplorationSkillCfg(game, cardDbId):
    """获取卡牌的探险技能配置（type=7的技能）
    
    Args:
        game: 游戏对象
        cardDbId: 卡牌数据库ID
    
    Returns:
        (skillCfg, skillID) 或 (None, 0)
    """
    skillCfg, skillId = getCardSkillCfg(game, cardDbId)
    if skillCfg is None:
        return None, 0
    
    # 检查是否是探险类型技能（type=7）
    skillType = getattr(skillCfg, 'type', 0)
    if skillType != TownSkillType.EXPLORATION:
        return None, skillId
    
    return skillCfg, skillId


def calculateExplorationSkillEffects(game, cardDbIds, explorerID, areaID=0):
    """计算探险技能效果
    
    收集所有参与探险的精灵和探险器的家园技能效果
    
    Args:
        game: 游戏对象
        cardDbIds: 参与探险的卡牌ID列表
        explorerID: 使用的探险器ID
        areaID: 探险区域ID（用于判断区域特定技能）
    
    Returns:
        dict: {
            'timeReduce': 探索时间缩短百分比 (0-100),
            'dessertReduce': 甜点消耗减少数量,
            'energyReduce': 精灵精力消耗减少数量,
            'awardAdd': 普通掉落数量增加百分比 (0-100),
            'extraAwardChance': 额外奖励掉落几率百分比 (0-100),
        }
    """
    result = {
        'timeReduce': 0.0,        # 探索时间缩短 (取最大值)
        'dessertReduce': 0,       # 甜点消耗减少
        'energyReduce': 0,        # 精灵精力消耗减少
        'awardAdd': 0.0,          # 普通掉落增加
        'extraAwardChance': 0.0,  # 额外奖励几率
    }
    
    # 收集所有技能配置
    skillConfigs = []
    
    # 1. 收集探险器的家园技能
    if explorerID:
        explorerSkillCfg, _ = getExplorerTownSkillCfg(game, explorerID)
        if explorerSkillCfg:
            skillConfigs.append(explorerSkillCfg)
    
    # 2. 收集所有卡牌的探险技能
    for cardDbId in cardDbIds:
        if not cardDbId:
            continue
        cardSkillCfg, _ = getCardExplorationSkillCfg(game, cardDbId)
        if cardSkillCfg:
            skillConfigs.append(cardSkillCfg)
    
    # 3. 计算所有技能效果
    for skillCfg in skillConfigs:
        _applyExplorationSkillEffect(skillCfg, result, areaID)
    
    return result


def _applyExplorationSkillEffect(skillCfg, result, areaID=0):
    """应用单个探险技能的效果
    
    Args:
        skillCfg: 技能配置
        result: 效果结果字典（会被修改）
        areaID: 探险区域ID
    """
    # 遍历技能的所有效果
    for i in range(1, 10):
        effect = getattr(skillCfg, 'effect%d' % i, 0)
        if not effect or effect == 0:
            break
        
        params = getattr(skillCfg, 'params%d' % i, None)
        if not params:
            continue
        
        # 解析参数
        # params 格式可能是: <值> 或 <0%;区域ID;值%> 等
        if isinstance(params, (list, tuple)):
            if len(params) >= 3:
                # 格式: <baseValue; targetAreaID; areaValue>
                # 如果区域匹配，使用 areaValue，否则使用 baseValue
                baseVal = params[0]
                targetArea = params[1] if len(params) > 1 else 0
                areaVal = params[2] if len(params) > 2 else baseVal
                
                if areaID and targetArea and areaID == targetArea:
                    paramVal = areaVal
                else:
                    paramVal = baseVal
            else:
                paramVal = params[0]
        else:
            paramVal = params
        
        # 根据效果类型应用
        if effect == TownSkillEffect.C_TIME_SUB:
            # 探索时间缩短（取最大值）
            n, isPercent = parsePercentStr(paramVal)
            if isPercent or n > 1:  # 百分比或大于1的值视为百分比
                result['timeReduce'] = max(result['timeReduce'], n)
            else:
                result['timeReduce'] = max(result['timeReduce'], n * 100)
        
        elif effect == TownSkillEffect.C_ACTION_SUB:
            # 甜点消耗减少（累加）
            n, isPercent = parsePercentStr(paramVal)
            if isPercent:
                result['dessertReduce'] += n  # 这里按百分比处理
            else:
                result['dessertReduce'] += n
        
        elif effect == TownSkillEffect.C_ENERGY_SUB:
            # 精灵精力消耗减少（累加）
            n, _ = parsePercentStr(paramVal)
            result['energyReduce'] += int(n)
        
        elif effect == TownSkillEffect.C_AWARD_ADD:
            # 普通掉落数量增加（累加）
            n, isPercent = parsePercentStr(paramVal)
            if isPercent or n > 1:
                result['awardAdd'] += n
            else:
                result['awardAdd'] += n * 100
        
        elif effect == TownSkillEffect.C_EXTRA_AWARD:
            # 额外奖励掉落几率（累加）
            n, isPercent = parsePercentStr(paramVal)
            if isPercent or n > 1:
                result['extraAwardChance'] += n
            else:
                result['extraAwardChance'] += n * 100


def checkBuildingUnlock(game, cfg):
    """检查建筑解锁条件
    
    unlockType1/unlockType2: 解锁条件类型
    unlockParams1/unlockParams2: 解锁参数 <buildType;level>
    
    类型说明:
    1 = 建筑等级要求（参数格式：<buildType;level>，需根据buildType找到建筑）
    2 = 家园家具数量要求
    
    buildType 对应关系:
    - 8 = 大漠遗迹 (buildID=14)
    - 9 = 山城遗迹 (buildID=15)
    - 10 = 苍雪遗迹 (buildID=16)
    - 11 = 熔岩遗迹 (buildID=17)
    """
    buildings = game.town.buildings or {}
    
    # buildType 到 buildingID 的映射
    BUILD_TYPE_TO_ID = {
        1: 1,   # 市中心
        2: 2,   # 我的小屋
        3: 3,   # 炼金厂
        4: 4,   # 伐木场
        5: 5,   # 甜品站
        6: 6,   # 金融银行
        7: 7,   # 炼金厂2
        8: 14,  # 大漠遗迹
        9: 15,  # 山城遗迹
        10: 16, # 苍雪遗迹
        11: 17, # 熔岩遗迹
    }
    
    def checkCondition(unlockType, unlockParams):
        if unlockType == 0 or not unlockParams:
            return True, None
        
        # 类型1: 建筑等级要求
        if unlockType == 1:
            reqBuildType = unlockParams[0] if len(unlockParams) > 0 else 0
            reqLevel = unlockParams[1] if len(unlockParams) > 1 else 0
            # 根据 buildType 找到 buildingID
            reqBuildingID = BUILD_TYPE_TO_ID.get(reqBuildType, reqBuildType)
            buildData = buildings.get(reqBuildingID, {})
            curLevel = buildData.get('level', 0)
            if curLevel < reqLevel:
                return False, 'building level not enough'
        
        # 类型2: 家园家具数量要求
        elif unlockType == 2:
            reqCount = unlockParams[0] if len(unlockParams) > 0 else 0
            home = game.town.home or {}
            furniture_count = home.get('furniture_placed_num', 0)
            if not furniture_count:
                layout = game.town.home_apply_layout or {}
                for _, furnitureList in layout.items():
                    if isinstance(furnitureList, list):
                        for item in furnitureList:
                            if isinstance(item, list) and len(item) >= 2:
                                itemType = item[1]
                                if itemType not in (4, 5):
                                    furniture_count += 1
            if furniture_count < reqCount:
                return False, 'furniture count not enough'
        
        return True, None
    
    # 检查条件1
    unlockType1 = getattr(cfg, 'unlockType1', 0)
    unlockParams1 = getattr(cfg, 'unlockParams1', None)
    ok, reason = checkCondition(unlockType1, unlockParams1)
    if not ok:
        return False, reason
    
    # 检查条件2（苍雪/熔岩遗迹需要同时满足两个条件）
    unlockType2 = getattr(cfg, 'unlockType2', 0)
    unlockParams2 = getattr(cfg, 'unlockParams2', None)
    ok, reason = checkCondition(unlockType2, unlockParams2)
    if not ok:
        return False, reason
    
    return True, None


# ============================================================================
# 入口接口
# 前端 URL: /town/get
# ============================================================================
class TownGet(RequestHandlerTask):
    """获取家园数据（入口接口）
    前端调用: gGameApp:requestServer("/town/get", ...)
    """
    url = r'/town/get'
    
    @coroutine
    def run(self):
        from game.object.game.town_lottery import ObjectTownRelicBuff
        
        # 检查并刷新商店物品（修复老数据 itemID=0 的问题）
        if hasattr(self.game, 'townShop') and self.game.townShop:
            items = self.game.townShop.items or {}
            needRefresh = False
            for pos, itemData in items.items():
                if isinstance(itemData, list) and len(itemData) >= 2 and itemData[1] == 0:
                    needRefresh = True
                    break
            if needRefresh:
                self.game.townShop.makeShop()
        
        # 刷新过期的遗迹祝福
        ObjectTownRelicBuff.refreshExpiredBuffs(self.game)
        
        # 修复老玩家套装数据：检查并重新计算 furniture_series
        # 如果玩家有家具但套装数据为空，重新计算一次
        townHome = self.game.role.town_home or {}
        furnitureSeries = townHome.get('furniture_series', {})
        furniture = self.game.role._db.get('furniture', {})
        if furniture and not furnitureSeries:
            # 收集所有套装ID
            allSeriesIDs = set()
            for furID in csv.town.home_furniture:
                furCfg = csv.town.home_furniture[furID]
                seriesID = furCfg.series or 0
                if seriesID > 0:
                    allSeriesIDs.add(seriesID)
            # 重新计算套装收集情况
            if allSeriesIDs:
                _checkFurnitureSeriesCollection(self.game, furniture, allSeriesIDs)
                logger.info('TownGet: recalculated furniture_series for role=%s', self.game.role.id)
        
        # 检查每日首次进入家园，触发遗迹祝福抽取
        buffId = 0
        intoTownDaily = self.game.dailyRecord.into_town_daily
        logger.info('[RelicBuff] TownGet: into_town_daily=%s', intoTownDaily)
        if not intoTownDaily:
            # 标记今日已进入
            self.game.dailyRecord.into_town_daily = True
            logger.info('[RelicBuff] TownGet: first entry today, trying to draw buff...')
            # 尝试抽取遗迹祝福
            buffId = ObjectTownRelicBuff.tryDrawBuff(self.game)
            if buffId > 0:
                logger.info('TownGet: role=%s daily relic buff drawn: %d', 
                    self.game.role.id, buffId)
            else:
                logger.info('[RelicBuff] TownGet: no buff drawn (buffId=0)')
        else:
            logger.info('[RelicBuff] TownGet: already entered today, skip draw')
        
        # 调试日志：显示当前遗迹祝福状态
        relicBuff = self.game.town.relic_buff or {} if self.game.town else {}
        logger.info('[RelicBuff] TownGet: role=%s relic_buff=%s', self.game.role.id, relicBuff)
        
        # 从数据库刷新 home 数据（访问记录是其他玩家直接写入数据库的，需要重新读取）
        if self.game.town and self.game.role.town_db_id:
            ret = yield self.dbcGame.call_async('DBRead', 'Town', self.game.role.town_db_id, False)
            if ret['ret']:
                dbHome = ret['model'].get('home')
                if dbHome:
                    # 更新内存缓存
                    self.game.town.home = dbHome
                    logger.info('TownGet: refreshed home data, visit_history count=%d', 
                        len(dbHome.get('visit_history') or []))
        
        # 返回 town 和 town_shop 数据（使用 model 格式让前端框架自动同步）
        # 使用框架标准的 _db 包装格式
        townModel = self.game.town.model if self.game.town else {}
        townShopModel = self.game.townShop.model if hasattr(self.game, 'townShop') and self.game.townShop else {}
        
        # 调试日志：直接访问 town 对象属性
        wishData = self.game.town.wish if self.game.town else {}
        logger.info('TownGet: wish=%s', wishData)
        
        # 日志：显示 cards 数据
        cardsData = self.game.town.cards if self.game.town else {}
        logger.info('TownGet: role=%s, cards count=%d', self.game.role.id, len(cardsData) if cardsData else 0)
        
        # 调试日志：显示 continuous_factory 数据，帮助排查收取按钮不显示问题
        continuousFactory = self.game.town.continuous_factory if self.game.town else {}
        logger.info('TownGet: continuous_factory=%s', continuousFactory)
        
        # 注意：furniture 和 town_home 已在 role.init() 中初始化
        # 前端通过 gGameModel.role:getIdler("furniture") 获取，不需要在这里返回
        
        # 构造访客列表（不包含自己，前端会自动添加自己）
        friendList = []
        homeData = self.game.town.home if self.game.town else {}
        visitHistory = (homeData.get('visit_history') if homeData else None) or []
        seenRoleIds = set()  # 去重：同一个玩家只显示一次
        for record in visitHistory:
            roleId = record.get('role_id')
            if roleId and roleId not in seenRoleIds:
                seenRoleIds.add(roleId)
                friendList.append({
                    'figure': record.get('figure', 1),
                    'name': record.get('name', ''),
                    'role_id': roleId,
                    'game_key': record.get('game_key', ''),
                })
                if len(friendList) >= 10:  # 最多显示10个访客
                    break
        
        # 上传玩家信息到跨服（用于跨服推荐列表和跨服拜访）
        try:
            from game.object.game.cross_town_party import ObjectCrossTownPartyGlobal
            from game.server import Server
            
            if self.game.role.town_db_id and homeData:
                homeScore = homeData.get('score', 0) or homeData.get('fixed_score', 0)
                homeLiked = homeData.get('liked', 0)
                
                # 构造家园拜访数据（供跨服拜访使用）
                buildingsData = self.game.town.buildings if self.game.town else {}
                homeApplyLayout = self.game.town.home_apply_layout if self.game.town else {}
                
                # 序列化家园数据用于跨服拜访
                visitData = msgpack.packb({
                    'home': homeData,
                    'buildings': buildingsData,
                    'home_apply_layout': homeApplyLayout,
                }, use_bin_type=True)
                
                yield ObjectCrossTownPartyGlobal.visitUpdatePlayer(
                    Server.Singleton.key,
                    self.game.role.id,
                    self.game.role.name,
                    self.game.role.level,
                    self.game.role.vip_level,
                    self.game.role.logo,
                    self.game.role.frame,
                    self.game.role.figure,
                    self.game.role.town_db_id,
                    homeScore,
                    homeLiked,
                    visitData
                )
                
                # 拉取并处理跨服事件（访问/点赞/评价）
                events = yield ObjectCrossTownPartyGlobal.visitGetAndClearEvents(
                    Server.Singleton.key,
                    self.game.role.id
                )
                if events:
                    logger.info('TownGet: processing %d cross events', len(events))
                    townUpdates = {}
                    for event in events:
                        eventType = event.get('event_type', 0)
                        if eventType == 1:  # 访问事件
                            # 添加到访问历史
                            visitRecord = {
                                'timestamp': event.get('timestamp', 0),
                                'game_key': event.get('game_key', ''),
                                'name': event.get('name', ''),
                                'role_id': event.get('role_id'),
                                'town_db_id': event.get('town_db_id'),
                                'figure': event.get('figure', 1),
                                'like': False,
                            }
                            visitHistory = homeData.get('visit_history') or []
                            baseCfg = csv.town.home_like_base[1]
                            visitHistoryLimit = baseCfg.visitHistoryLimit
                            if len(visitHistory) >= visitHistoryLimit:
                                visitHistory = visitHistory[-(visitHistoryLimit - 1):]
                            visitHistory.append(visitRecord)
                            homeData['visit_history'] = visitHistory
                            townUpdates['home'] = homeData
                        elif eventType == 2:  # 点赞事件
                            # 增加被赞数
                            homeData['liked'] = homeData.get('liked', 0) + 1
                            townUpdates['home'] = homeData
                            # 更新访问历史中的点赞状态
                            visitorRoleId = event.get('role_id')
                            visitHistory = homeData.get('visit_history') or []
                            for record in visitHistory:
                                if record.get('role_id') == visitorRoleId:
                                    record['like'] = True
                                    break
                        elif eventType == 3:  # 评价事件
                            # 增加评分统计
                            scoreId = event.get('score_id', 0)
                            if scoreId > 0:
                                homeData['total_score'] = homeData.get('total_score', 0) + scoreId
                                homeData['score_num'] = homeData.get('score_num', 0) + 1
                                townUpdates['home'] = homeData
                    
                    # 保存更新到数据库
                    if townUpdates:
                        yield self.dbcGame.call_async('DBUpdate', 'Town', self.game.role.town_db_id, townUpdates, False)
                        # 更新内存缓存
                        if 'home' in townUpdates:
                            self.game.town.home = homeData
                        logger.info('TownGet: synced %d cross events', len(events))
        except Exception as e:
            logger.warning('TownGet: failed to update visit player info: %s', e)
        
        # 检查并更新点赞奖励状态（补全已达成但未标记的奖励）
        # 前端约定：1=可领取（发光），0=已领取（计入 count）
        weeklyLikes = self.game.weeklyRecord.town_home_likes or 0
        if weeklyLikes > 0:
            likeAward = self.game.weeklyRecord.town_home_like_award or {}
            updated = False
            for csvID in csv.town.home_like_award:
                cfg = csv.town.home_like_award[csvID]
                if csvID not in likeAward and weeklyLikes >= cfg.taskParam:
                    likeAward[csvID] = 1  # 可领取（前端 v==1 发光）
                    updated = True
            if updated:
                self.game.weeklyRecord.town_home_like_award = likeAward
        
        # 确保 weekly_record/daily_record 中家园社交相关字段有默认值
        # 前端 initOtherHome 会监听这些字段，如果是 nil 会报错
        # 注意：只设置后端数据，让框架自动同步，不要在响应中手动返回 daily_record/weekly_record
        # 因为返回会覆盖前端整个 model，导致其他字段丢失
        if self.game.weeklyRecord.town_home_score is None:
            self.game.weeklyRecord.town_home_score = {}
        if self.game.weeklyRecord.town_home_likes is None:
            self.game.weeklyRecord.town_home_likes = 0
        if self.game.weeklyRecord.town_home_like_award is None:
            self.game.weeklyRecord.town_home_like_award = {}
        if self.game.dailyRecord.town_home_role_liked is None:
            self.game.dailyRecord.town_home_role_liked = []
        
        self.write({
            'model': {
                'town': townModel,  # 使用框架标准 _db 包装格式
                'town_shop': townShopModel,
            },
            'view': {
                'friend': friendList,  # 访客列表（基于访问历史）
                'buff_id': buffId,  # 每日首次进入抽取的遗迹祝福ID
            }
        })


# ============================================================================
# 遗迹Buff接口
# ============================================================================
class TownRelicBuffRefresh(RequestHandlerTask):
    """遗迹buff刷新
    前端调用: gGameApp:requestServer("/town/relic/buff/refresh", ...)
    """
    url = r'/town/relic/buff/refresh'
    
    @coroutine
    def run(self):
        from game.object.game.town_lottery import ObjectTownRelicBuff
        
        # 刷新过期的遗迹祝福
        ObjectTownRelicBuff.refreshExpiredBuffs(self.game)
        
        # 获取当前遗迹buff数据
        relicBuff = self.game.town.relic_buff or {}
        
        # 直接返回当前数据（前端会自动同步）
        self.write({'view': {'relic_buff': relicBuff}})


# ============================================================================
# 遗迹升级奖励辅助函数
# ============================================================================
def grantRelicUpgradeAward(game, buildingID, level):
    """发放遗迹升级奖励
    
    Args:
        game: 游戏对象
        buildingID: 建筑ID (14-17 为遗迹)
        level: 升级后的等级
    
    Returns:
        dict: 奖励信息 {itemID: count} 或 None
    """
    # 遗迹建筑 ID: 14=大漠遗迹, 15=山城遗迹, 16=苍雪遗迹, 17=熔岩遗迹
    RELIC_BUILDING_IDS = [
        TownBuildingType.DESERT_RELIC,
        TownBuildingType.MOUNTAINOUS_RELIC,
        TownBuildingType.SNOW_RELIC,
        TownBuildingType.LAVA_RELIC,
    ]
    
    if buildingID not in RELIC_BUILDING_IDS:
        return None
    
    if level <= 0:
        return None
    
    # 从 relic_upgrade_award.csv 读取奖励配置
    award = None
    for cfgId in csv.town.relic_upgrade_award:
        cfg = csv.town.relic_upgrade_award[cfgId]
        if cfg.relicID == buildingID and cfg.level == level:
            award = cfg.award
            break
    
    if not award:
        return None
    
    # 发放奖励
    gain = ObjectGainAux(game, award)
    gain.gain(src='relic_upgrade_award')
    
    # 遗迹升级后刷新卡牌属性（遗迹属性加成变化）
    _refreshAllCardsAttrs(game)
    
    logger.info('grantRelicUpgradeAward: buildingID=%s level=%s award=%s', buildingID, level, award)
    
    return dict(award) if award else None


# ============================================================================
# 建筑基础接口
# 前端 URL: /town/building/xxx (不带 /game/ 前缀)
# ============================================================================
class TownBuildingRefresh(RequestHandlerTask):
    """建筑升级完成刷新
    前端调用: gGameApp:requestServer("/town/building/refresh", ...)
    """
    url = r'/town/building/refresh'
    
    @coroutine
    def run(self):
        buildingID = self.input.get('buildingID', None)
        if buildingID is None:
            raise ClientError('buildingID required')
        buildingID = int(buildingID)  # 确保是纯整数，兼容 Go 端 document.Integer
        
        buildings = self.game.town.buildings or {}
        buildData = buildings.get(buildingID, {})
        
        finishTime = buildData.get('finish_time', 0)
        
        # 如果没有在升级（finish_time == 0），报错打断
        # 原因：部分玩家前端缓存了旧的 finish_time，导致无限循环请求
        # 报错可以让前端停止倒计时循环
        if finishTime == 0:
            raise ClientError('已完成')
        
        now = nowtime_t()
        if now < finishTime:
            raise ClientError('upgrade not finished')
        
        # 升级完成
        upgrading_to = buildData.get('upgrading_to', 0)
        if upgrading_to > 0:
            # 更新等级（升级开始时记录的目标等级）
            buildData['level'] = upgrading_to
            buildData['upgrading_to'] = 0
        
        # 清除升级时间
        buildData['finish_time'] = 0
        buildings[buildingID] = buildData
        self.game.town.buildings = buildings
        
        # 如果是市中心或遗迹升级完成，检查并初始化新解锁的建筑
        # 市中心升级可能解锁大漠/山城遗迹
        # 大漠/山城遗迹升到5级可能解锁苍雪/熔岩遗迹
        RELIC_IDS = [14, 15, 16, 17]  # 大漠、山城、苍雪、熔岩遗迹
        if buildingID == 1 or buildingID in RELIC_IDS:
            self.game.town._initBuildings()
        
        # 发放遗迹升级奖励
        relicAward = grantRelicUpgradeAward(self.game, buildingID, buildData.get('level', 1))
        
        logger.info('TownBuildingRefresh: buildingID=%s level=%s relicAward=%s', 
                    buildingID, buildData.get('level', 1), relicAward)
        
        self.write({'view': {'gain': relicAward} if relicAward else {}})


class TownBuildingLevelUp(RequestHandlerTask):
    """建筑升级
    前端调用: gGameApp:requestServer("/town/building/level/up", ...)
    """
    url = r'/town/building/level/up'
    
    @coroutine
    def run(self):
        buildingID = self.input.get('buildingID', None)
        if buildingID is None:
            raise ClientError('buildingID required')
        buildingID = int(buildingID)  # 确保是纯整数，兼容 Go 端 document.Integer
        
        buildings = self.game.town.buildings or {}
        buildData = buildings.get(buildingID, {})
        
        curLevel = buildData.get('level', 1)
        finishTime = buildData.get('finish_time', 0)
        
        # 检查是否正在升级
        if finishTime > 0:
            raise ClientError('already upgrading')
        
        # 获取下一级配置
        nextLevel = curLevel + 1
        nextCfg = getBuildingCsvByLevel(buildingID, nextLevel)
        if nextCfg is None:
            raise ClientError('max level reached')
        
        # 检查解锁条件
        canUnlock, reason = checkBuildingUnlock(self.game, nextCfg)
        if not canUnlock:
            raise ClientError(reason)
        
        # 检查并扣除消耗
        levelUpCost = getattr(nextCfg, 'levelUpCost', {})
        if levelUpCost:
            cost = ObjectCostAux(self.game, levelUpCost)
            if not cost.isEnough():
                raise ClientError(ErrDefs.costNotEnough)
            cost.cost(src='town_building_level_up')
        
        # 计算升级完成时间
        levelUpCostTime = getattr(nextCfg, 'levelUpCostTime', 0)
        now = nowtime_t()
        
        # 更新建筑数据
        # 注意：level 不在这里更新，等升级完成（TownBuildingRefresh）时再更新
        # 前端期望升级期间 level 保持不变，用 level+1 获取目标等级配置
        buildData['upgrading_to'] = nextLevel  # 记录升级目标等级
        buildData['finish_time'] = now + levelUpCostTime if levelUpCostTime > 0 else 0
        buildData['idx'] = buildingID  # idx 就是建筑类型ID
        
        # 如果没有升级时间，直接完成升级
        relicAward = None
        if levelUpCostTime <= 0:
            buildData['level'] = nextLevel
            buildData['upgrading_to'] = 0
            # 立即发放遗迹升级奖励
            relicAward = grantRelicUpgradeAward(self.game, buildingID, nextLevel)
        
        buildings[buildingID] = buildData
        
        self.game.town.buildings = buildings
        
        # 立即检查是否有新建筑需要解锁（如市中心升到8级解锁许愿池）
        self.game.town._initBuildings()
        
        logger.info('TownBuildingLevelUp: buildingID=%s level=%s->%s finishTime=%s relicAward=%s', 
                    buildingID, curLevel, nextLevel, buildData['finish_time'], relicAward)
        
        # 如果有新建筑解锁（如许愿池），需要返回完整 town 数据避免前端报错
        wishKey = TownBuildingType.WISH
        
        response = {}
        if relicAward:
            response['view'] = {'gain': relicAward}
        
        # 如果许愿池刚解锁，返回完整 town model（包含 wish）
        if wishKey in self.game.town.buildings:
            response['model'] = {'town': self.game.town.model}
        
        self.write(response)


class TownBuildingFinishAtOnce(RequestHandlerTask):
    """建筑立即完成升级（消耗钻石或免费）
    前端调用: gGameApp:requestServer("/town/building/finish/atonce", ..., buildingID)
    """
    url = r'/town/building/finish/atonce'
    
    @coroutine
    def run(self):
        buildingID = self.input.get('buildingID', None)
        if buildingID is None:
            raise ClientError('buildingID required')
        buildingID = int(buildingID)  # 确保是纯整数，兼容 Go 端 document.Integer
        
        buildings = self.game.town.buildings or {}
        buildData = buildings.get(buildingID, {})
        
        finishTime = buildData.get('finish_time', 0)
        
        # 如果没有在升级，直接返回成功
        if finishTime == 0:
            self.write({'view': {}})
            return
        
        now = nowtime_t()
        remainTime = max(0, finishTime - now)
        
        # 计算钻石消耗
        # 每 buildingCompletionInterval 分钟需要 buildingCompletionCost 钻石
        if remainTime > 0:
            completionInterval = 60  # 默认60秒一个单位
            completionCost = 1  # 默认1钻石一个单位
            
            # 尝试从配置获取
            if hasattr(csv, 'common_config'):
                for cfgId in csv.common_config:
                    cfg = csv.common_config[cfgId]
                    if hasattr(cfg, 'buildingCompletionInterval'):
                        completionInterval = cfg.buildingCompletionInterval * 60  # 转换为秒
                    if hasattr(cfg, 'buildingCompletionCost'):
                        completionCost = cfg.buildingCompletionCost
                    break
            
            # 计算需要的钻石数量
            import math
            rmbCost = int(math.ceil(remainTime / completionInterval)) * completionCost
            
            if rmbCost > 0:
                # 检查并扣除钻石
                cost = ObjectCostAux(self.game, {'rmb': rmbCost})
                if not cost.isEnough():
                    raise ClientError(ErrDefs.costNotEnough)
                cost.cost(src='town_building_finish_atonce')
        
        # 立即完成升级
        upgrading_to = buildData.get('upgrading_to', 0)
        if upgrading_to > 0:
            # 更新等级（升级开始时记录的目标等级）
            buildData['level'] = upgrading_to
            buildData['upgrading_to'] = 0
        
        buildData['finish_time'] = 0
        buildings[buildingID] = buildData
        self.game.town.buildings = buildings
        
        # 如果是市中心升级完成，检查并初始化新解锁的建筑
        if buildingID == 1:  # CENTER
            self.game.town._initBuildings()
        
        # 发放遗迹升级奖励
        relicAward = grantRelicUpgradeAward(self.game, buildingID, buildData.get('level', 1))
        
        logger.info('TownBuildingFinishAtOnce: buildingID=%s level=%s relicAward=%s', 
                    buildingID, buildData.get('level', 1), relicAward)
        
        # 如果有新建筑解锁（如许愿池），需要返回完整 town 数据避免前端报错
        wishKey = TownBuildingType.WISH
        
        response = {}
        if relicAward:
            response['view'] = {'gain': relicAward}
        
        # 如果许愿池刚解锁，返回完整 town model（包含 wish）
        if wishKey in self.game.town.buildings:
            response['model'] = {'town': self.game.town.model}
        
        self.write(response)


# ============================================================================
# 工厂系统 - 连续生产
# 前端 URL: /town/continuous/xxx
# ============================================================================
class TownContinuousCardPlace(RequestHandlerTask):
    """连续生产 - 放置卡牌
    前端调用: gGameApp:requestServer("/town/continuous/card/place", ..., buildingID, idx, cardID)
    """
    url = r'/town/continuous/card/place'
    
    @coroutine
    def run(self):
        buildingID = self.input.get('buildingID', None)
        idx = self.input.get('idx', None)
        cardID = self.input.get('cardID', None)
        
        if buildingID is None:
            raise ClientError('buildingID required')
        buildingID = int(buildingID)  # 确保是纯整数，兼容 Go 端 document.Integer
        
        # 检查建筑类型
        factoryType = BUILDING_FACTORY_TYPE.get(buildingID, FactoryType.NO_TYPE)
        if factoryType != FactoryType.NORMAL:
            raise ClientError('not normal factory')
        
        # 获取建筑数据
        buildings = self.game.town.buildings or {}
        buildData = buildings.get(buildingID, {})
        curLevel = buildData.get('level', 1)
        
        # 获取生产配置
        prodCfg = getProductionCsv(buildingID, curLevel)
        if prodCfg is None:
            raise ClientError('production config not found')
        
        # 初始化工厂数据
        continuousFactory = self.game.town.continuous_factory or {}
        factoryData = continuousFactory.get(buildingID, {})
        
        now = nowtime_t()
        
        # 获取现有卡牌字典，格式: {slotIdx: cardDbId}
        cardIds = factoryData.get('card_ids')
        if not isinstance(cardIds, dict):
            cardIds = {}
        
        if idx is not None and cardID:
            # 检查卡牌是否已经在当前工厂的其他槽位
            for slotIdx, existingCardID in cardIds.items():
                if existingCardID == cardID and slotIdx != idx:
                    raise ClientError('card already placed in slot %s' % slotIdx)
            cardIds[idx] = cardID  # 直接使用 Lua 索引 (1,2,3)
        
        factoryData['card_ids'] = cardIds
        # 如果是第一次放入精灵（collection_time 不存在），初始化时间和 total
        if 'collection_time' not in factoryData:
            factoryData['collection_time'] = now
            factoryData['calc_time'] = now
            # total 初始化为 1，让前端能显示收取按钮（前端条件需要 total >= 1）
            # 实际收取时会根据时间差重新计算真实产量
            factoryData['total'] = 1
        else:
            # 已有数据，保持 total 至少为 1（确保前端能显示收取按钮）
            factoryData['total'] = max(factoryData.get('total', 0), 1)
        
        continuousFactory[buildingID] = factoryData
        self.game.town.continuous_factory = continuousFactory
        
        # 更新卡牌状态（使用建筑对应的工作状态）
        if cardID:
            workStatus = BUILDING_CARD_STATUS.get(buildingID, TownCardState.IDLE)
            self._updateCardStatus([cardID], workStatus)
        
        logger.info('TownContinuousCardPlace: buildingID=%s idx=%s cardID=%s pyIdx=%s', buildingID, idx, cardID, idx - 1 if idx else None)
        
        # 返回更新后的 town model
        self.write({'model': {'town': self.game.town.model}})
    
    def _updateCardStatus(self, cardIDs, status):
        """更新卡牌在家园的状态，并确保能量字段已初始化
        
        status: 数字状态值（TownCardState 常量）
        """
        now = nowtime_t()
        cards = self.game.town.cards or {}
        for cardDbId in cardIDs:
            if cardDbId:
                cardData = cards.get(cardDbId, {})
                oldStatus = cardData.get('status', TownCardState.IDLE)
                oldEnergy = cardData.get('energy')
                isNew = cardDbId not in cards or not cardData
                
                cardData['status'] = status
                
                # 确保能量字段已初始化（每次都重新计算 max_energy，确保正确）
                maxEnergy = getCardMaxEnergy(self.game, cardDbId)
                cardData['max_energy'] = maxEnergy
                
                # 如果是新卡牌（第一次进入家园），初始化为满精力
                if isNew or 'energy' not in cardData or cardData.get('energy') is None:
                    cardData['energy'] = maxEnergy
                    logger.info('_updateCardStatus: init card %s energy to %s (isNew=%s)', cardDbId, maxEnergy, isNew)
                else:
                    logger.info('_updateCardStatus: card %s keep energy %s/%s', cardDbId, oldEnergy, maxEnergy)
                
                # 当卡牌开始工作时（从空闲变为工作状态），设置开始时间
                if oldStatus == TownCardState.IDLE and status != TownCardState.IDLE:
                    cardData['energy_refresh_time'] = now
                elif 'energy_refresh_time' not in cardData:
                    cardData['energy_refresh_time'] = 0
                
                cards[cardDbId] = cardData
        self.game.town.cards = cards


class TownContinuousCardRemove(RequestHandlerTask):
    """连续生产 - 移除卡牌
    前端调用: gGameApp:requestServer("/town/continuous/card/remove", ...)
    """
    url = r'/town/continuous/card/remove'
    
    @coroutine
    def run(self):
        buildingID = self.input.get('buildingID', None)
        cardID = self.input.get('cardID', None)
        
        if buildingID is None:
            raise ClientError('buildingID required')
        buildingID = int(buildingID)  # 确保是纯整数，兼容 Go 端 document.Integer
        
        continuousFactory = self.game.town.continuous_factory or {}
        factoryData = continuousFactory.get(buildingID, {})
        
        # card_ids 是字典格式 {slotIdx: cardDbId}
        cardIDs = factoryData.get('card_ids', {})
        if not isinstance(cardIDs, dict):
            cardIDs = {}
        
        # 找到并移除卡牌
        slotToRemove = None
        for slot, cid in cardIDs.items():
            if cid == cardID:
                slotToRemove = slot
                break
        
        if slotToRemove is not None:
            del cardIDs[slotToRemove]
            factoryData['card_ids'] = cardIDs
            continuousFactory[buildingID] = factoryData
            self.game.town.continuous_factory = continuousFactory
            
            # 计算并消耗能量
            now = nowtime_t()
            cards = self.game.town.cards or {}
            if cardID in cards:
                cardData = cards[cardID]
                refreshTime = cardData.get('energy_refresh_time', 0)
                oldEnergy = cardData.get('energy', 0)
                consumed = 0
                if refreshTime > 0:
                    # 获取能量消耗配置
                    buildings = self.game.town.buildings or {}
                    buildData = buildings.get(buildingID, {})
                    curLevel = buildData.get('level', 1)
                    prodCfg = getProductionCsv(buildingID, curLevel)
                    energyExpend = getattr(prodCfg, 'energyExpend', 1) if prodCfg else 1
                    
                    # 计算技能减少的消耗
                    skillEffect = getCardSkillEffect(self.game, cardID, buildingID, FactoryType.NORMAL)
                    effectiveEnergyExpend = max(0, energyExpend - skillEffect['normalEnergyReduce'])
                    
                    # 计算消耗的能量
                    elapsedHours = (now - refreshTime) / 3600.0
                    consumed = effectiveEnergyExpend * elapsedHours
                    currentEnergy = cardData.get('energy', 0)
                    cardData['energy'] = max(0, int(currentEnergy - consumed))
                
                cardData['status'] = TownCardState.IDLE
                cardData['energy_refresh_time'] = now  # 设为当前时间，用于前端计算恢复量
                cards[cardID] = cardData
                self.game.town.cards = cards
                logger.info('TownContinuousCardRemove: card %s removed, energy %s -> %s (consumed %.2f)', 
                           cardID, oldEnergy, cardData['energy'], consumed)
            else:
                logger.warning('TownContinuousCardRemove: card %s not in cards dict!', cardID)
        
        logger.info('TownContinuousCardRemove: buildingID=%s cardID=%s', buildingID, cardID)
        
        # 返回更新后的 town model，让前端同步卡牌状态
        self.write({'model': {'town': self.game.town.model}})


class TownContinuousReceive(RequestHandlerTask):
    """连续生产 - 收取产出
    前端调用: gGameApp:requestServer("/town/continuous/receive", ...)
    """
    url = r'/town/continuous/receive'
    
    @coroutine
    def run(self):
        buildingID = self.input.get('buildingID', None)
        if buildingID is None:
            raise ClientError('buildingID required')
        buildingID = int(buildingID)  # 确保是纯整数，兼容 Go 端 document.Integer
        
        # 获取工厂数据
        continuousFactory = self.game.town.continuous_factory or {}
        factoryData = continuousFactory.get(buildingID, {})
        
        if not factoryData:
            raise ClientError('factory not started')
        
        # 获取建筑数据
        buildings = self.game.town.buildings or {}
        buildData = buildings.get(buildingID, {})
        curLevel = buildData.get('level', 1)
        
        # 获取生产配置
        prodCfg = getProductionCsv(buildingID, curLevel)
        if prodCfg is None:
            raise ClientError('production config not found')
        
        now = nowtime_t()
        collectionTime = factoryData.get('collection_time', now)
        totalStored = factoryData.get('total', 0)
        
        # 计算产出
        elapsedHours = (now - collectionTime) // 3600
        if elapsedHours < 1:
            raise ClientError('not enough time')
        
        # 效率 = efficient / 小时
        efficient = getattr(prodCfg, 'efficient', 0)
        inventory = getattr(prodCfg, 'inventory', 100)
        itemKey = getattr(prodCfg, 'item', None)
        # CSV 中 item 字段可能是字符串，转成整数
        if itemKey and isinstance(itemKey, str) and itemKey.isdigit():
            itemKey = int(itemKey)
        
        # 计算卡牌技能效果
        skillEffect = calculateFactorySkillEffects(self.game, buildingID, FactoryType.NORMAL)
        productBonus = skillEffect['productEffect']
        inventoryBonus = skillEffect['inventoryEffect']
        
        # 遗迹祝福 - 工厂生产速度增加 (type 10-12, 持续时间效果)
        # type 10: 伐木场(buildingID=3), type 11: 炼金厂(buildingID=4), type 12: 甜品站(buildingID=5)
        relicProductBonus = 0
        if self.game.town:
            from game.object.game.town_lottery import ObjectTownRelicBuff
            relicBuffType = {3: 10, 4: 11, 5: 12}.get(buildingID, 0)  # 建筑ID -> 祝福类型
            if relicBuffType > 0:
                relicParam = ObjectTownRelicBuff.getActiveBuffParam(self.game, relicBuffType)
                if relicParam > 0:
                    # param=0.1 表示增加10%，即每小时额外增加 efficient * param
                    relicProductBonus = int(efficient * relicParam)
                    logger.info('[RelicBuff] factory receive: type=%s active, param=%s bonus=%s', relicBuffType, relicParam, relicProductBonus)
                else:
                    logger.info('[RelicBuff] factory receive: type=%s no buff available', relicBuffType)
        
        # 应用技能效果
        effectiveEfficient = efficient + productBonus + relicProductBonus  # 实际生产效率
        effectiveInventory = inventory + inventoryBonus  # 实际库存上限
        
        # 计算产出数量
        produced = effectiveEfficient * elapsedHours
        totalStored += produced
        
        # 不能超过库存上限
        canCollect = min(totalStored, effectiveInventory)
        
        if canCollect <= 0:
            raise ClientError('nothing to collect')
        
        # 发放奖励
        gain = ObjectGainAux(self.game, {itemKey: int(canCollect)})
        gain.gain(src='town_continuous_receive')
        
        # 更新工厂数据（同时更新 collection_time 和 calc_time）
        factoryData['collection_time'] = now
        factoryData['calc_time'] = now
        # 保持 total >= 1，让前端能继续显示收取按钮（前端条件需要 total >= 1）
        factoryData['total'] = max(totalStored - canCollect, 1)
        continuousFactory[buildingID] = factoryData
        self.game.town.continuous_factory = continuousFactory
        
        logger.info('TownContinuousReceive: buildingID=%s collected=%s item=%s productBonus=%s inventoryBonus=%s', 
                    buildingID, canCollect, itemKey, productBonus, inventoryBonus)
        
        self.write({'view': {itemKey: int(canCollect)}})


# ============================================================================
# 工厂系统 - 订单生产
# 前端 URL: /town/order/xxx
# ============================================================================
class TownOrderPlace(RequestHandlerTask):
    """订单生产 - 开始订单
    前端调用: gGameApp:requestServer("/town/order/place", ..., buildingID, count)
    """
    url = r'/town/order/place'
    
    @coroutine
    def run(self):
        buildingID = self.input.get('buildingID', None)
        orderCount = self.input.get('count', 1)
        
        if buildingID is None:
            raise ClientError('buildingID required')
        buildingID = int(buildingID)  # 确保是纯整数，兼容 Go 端 document.Integer
        
        # 检查建筑类型
        factoryType = BUILDING_FACTORY_TYPE.get(buildingID, FactoryType.NO_TYPE)
        if factoryType != FactoryType.ORDER:
            raise ClientError('not order factory')
        
        # 获取建筑数据
        buildings = self.game.town.buildings or {}
        buildData = buildings.get(buildingID, {})
        curLevel = buildData.get('level', 1)
        
        # 获取生产配置
        prodCfg = getProductionCsv(buildingID, curLevel)
        if prodCfg is None:
            raise ClientError('production config not found')
        
        # 检查订单消耗
        orderCostItem = getattr(prodCfg, 'orderCostItem', {})
        orderCostTime = getattr(prodCfg, 'orderCostTime', 180)
        
        if orderCostItem:
            # 乘以订单数量
            totalCost = {k: v * orderCount for k, v in orderCostItem.items()}
            cost = ObjectCostAux(self.game, totalCost)
            if not cost.isEnough():
                raise ClientError(ErrDefs.costNotEnough)
            cost.cost(src='town_order_place')
        
        # 初始化订单工厂数据
        orderFactory = self.game.town.order_factory or {}
        factoryData = orderFactory.get(buildingID, {})
        
        now = nowtime_t()
        
        # 使用已放置的卡牌（从之前的 /town/order/card/place 设置）
        # card_ids 是字典格式 {slotIdx: cardDbId}
        cardIDs = factoryData.get('card_ids', {})
        if isinstance(cardIDs, dict):
            cardIDList = cardIDs.values()
        else:
            cardIDList = cardIDs if cardIDs else []
        
        # 计算卡牌技能效果
        # 获取卡牌当前能量（用于计算订单时间减少）
        totalEnergy = 0
        cards = self.game.town.cards or {}
        for cardDbId in cardIDList:
            if cardDbId:
                cardData = cards.get(cardDbId, {})
                totalEnergy += cardData.get('energy', 0)
        
        skillEffect = calculateFactorySkillEffects(self.game, buildingID, FactoryType.ORDER, totalEnergy, orderCount)
        timeReduce = skillEffect['orderTimeReduce']
        
        # 计算实际需要时间（应用时间减少效果）
        baseTime = orderCostTime * orderCount
        actualTime = max(1, baseTime - int(timeReduce))  # 至少需要1秒
        
        # 设置订单数据
        factoryData['start_time'] = now
        factoryData['needs_time'] = actualTime
        factoryData['base_needs_time'] = baseTime  # 保存原始时间用于前端显示
        factoryData['count'] = orderCount
        
        orderFactory[buildingID] = factoryData
        self.game.town.order_factory = orderFactory
        
        # 更新卡牌状态（使用建筑对应的工作状态）
        workStatus = BUILDING_CARD_STATUS.get(buildingID, TownCardState.IDLE)
        now = nowtime_t()
        for cardDbId in cardIDList:  # 使用转换后的 cardIDList，不是原始 dict
            if cardDbId:
                cardData = cards.get(cardDbId, {})
                oldStatus = cardData.get('status', TownCardState.IDLE)
                cardData['status'] = workStatus
                # 确保必要字段已初始化
                maxEnergy = getCardMaxEnergy(self.game, cardDbId)
                cardData['max_energy'] = maxEnergy
                if 'energy' not in cardData or cardData.get('energy') is None:
                    cardData['energy'] = maxEnergy
                # 当卡牌开始工作时设置开始时间
                if oldStatus == TownCardState.IDLE and workStatus != TownCardState.IDLE:
                    cardData['energy_refresh_time'] = now
                elif 'energy_refresh_time' not in cardData or cardData.get('energy_refresh_time') is None:
                    cardData['energy_refresh_time'] = 0
                cards[cardDbId] = cardData
        self.game.town.cards = cards
        
        logger.info('TownOrderPlace: buildingID=%s count=%s baseTime=%s actualTime=%s timeReduce=%s cardIDList=%s', 
                    buildingID, orderCount, baseTime, actualTime, timeReduce, cardIDList)
        
        self.write({'view': {}})


class TownOrderCardPlace(RequestHandlerTask):
    """订单生产 - 放置卡牌
    前端调用: gGameApp:requestServer("/town/order/card/place", ..., buildingID, idx, cardID)
    """
    url = r'/town/order/card/place'
    
    @coroutine
    def run(self):
        buildingID = self.input.get('buildingID', None)
        idx = self.input.get('idx', None)
        cardID = self.input.get('cardID', None)
        
        if buildingID is None:
            raise ClientError('buildingID required')
        buildingID = int(buildingID)  # 确保是纯整数，兼容 Go 端 document.Integer
        
        now = nowtime_t()
        
        # 更新订单工厂的卡牌，格式: {slotIdx: cardDbId}
        orderFactory = self.game.town.order_factory or {}
        factoryData = orderFactory.get(buildingID, {})
        cardIds = factoryData.get('card_ids')
        if not isinstance(cardIds, dict):
            cardIds = {}
        
        if idx is not None and cardID:
            # 检查卡牌是否已经在当前工厂的其他槽位
            for slotIdx, existingCardID in cardIds.items():
                if existingCardID == cardID and slotIdx != idx:
                    raise ClientError('card already placed in slot %s' % slotIdx)
            cardIds[idx] = cardID  # 直接使用 Lua 索引 (1,2,3)
        factoryData['card_ids'] = cardIds
        
        # 更新卡牌状态（使用建筑对应的工作状态）
        cards = self.game.town.cards or {}
        if cardID:
            workStatus = BUILDING_CARD_STATUS.get(buildingID, TownCardState.IDLE)
            isNew = cardID not in cards
            cardData = cards.get(cardID, {})
            oldStatus = cardData.get('status', TownCardState.IDLE)
            oldEnergy = cardData.get('energy')
            cardData['status'] = workStatus
            # 确保能量字段已初始化（每次都重新计算 max_energy）
            maxEnergy = getCardMaxEnergy(self.game, cardID)
            cardData['max_energy'] = maxEnergy
            # 如果是新卡牌，初始化为满精力
            if isNew or 'energy' not in cardData or cardData.get('energy') is None:
                cardData['energy'] = maxEnergy
                logger.info('TownOrderCardPlace: init card %s energy to %s (isNew=%s)', cardID, maxEnergy, isNew)
            else:
                logger.info('TownOrderCardPlace: card %s keep energy %s/%s', cardID, oldEnergy, maxEnergy)
            # 当卡牌开始工作时设置开始时间
            if oldStatus == TownCardState.IDLE and workStatus != TownCardState.IDLE:
                cardData['energy_refresh_time'] = now
            elif 'energy_refresh_time' not in cardData:
                cardData['energy_refresh_time'] = 0
            cards[cardID] = cardData
            self.game.town.cards = cards
        
        # 先保存 card_ids 更新，让 calculateFactorySkillEffects 能读取到新的卡牌列表
        orderFactory[buildingID] = factoryData
        self.game.town.order_factory = orderFactory
        
        # 如果订单正在进行中，重新计算 needs_time（技能时间加成实时生效）
        startTime = factoryData.get('start_time', 0)
        if startTime > 0:
            baseNeedsTime = factoryData.get('base_needs_time', 0)
            orderCount = factoryData.get('count', 0)
            
            if baseNeedsTime > 0 and orderCount > 0:
                # 获取所有卡牌的能量
                cardIDList = cardIds.values() if isinstance(cardIds, dict) else (cardIds or [])
                totalEnergy = 0
                for cid in cardIDList:
                    if cid:
                        cdata = cards.get(cid, {})
                        totalEnergy += cdata.get('energy', 0)
                
                # 重新计算技能效果
                skillEffect = calculateFactorySkillEffects(self.game, buildingID, FactoryType.ORDER, totalEnergy, orderCount)
                timeReduce = skillEffect['orderTimeReduce']
                
                # 新的需要时间 = 基础时间 - 技能减少时间
                newNeedsTime = max(1, baseNeedsTime - int(timeReduce))
                
                # 更新 needs_time（start_time 保持不变）
                factoryData['needs_time'] = newNeedsTime
                orderFactory[buildingID] = factoryData
                self.game.town.order_factory = orderFactory
                
                logger.info('TownOrderCardPlace: recalc needs_time, base=%s reduce=%s new=%s', 
                           baseNeedsTime, timeReduce, newNeedsTime)
        
        logger.info('TownOrderCardPlace: buildingID=%s idx=%s cardID=%s', buildingID, idx, cardID)
        
        # 返回更新后的 town model
        self.write({'model': {'town': self.game.town.model}})


class TownOrderCardRemove(RequestHandlerTask):
    """订单生产 - 移除卡牌
    前端调用: gGameApp:requestServer("/town/order/card/remove", ...)
    """
    url = r'/town/order/card/remove'
    
    @coroutine
    def run(self):
        buildingID = self.input.get('buildingID', None)
        cardID = self.input.get('cardID', None)
        
        if buildingID is None:
            raise ClientError('buildingID required')
        buildingID = int(buildingID)  # 确保是纯整数，兼容 Go 端 document.Integer
        
        now = nowtime_t()
        
        orderFactory = self.game.town.order_factory or {}
        factoryData = orderFactory.get(buildingID, {})
        
        # card_ids 是字典格式 {slotIdx: cardDbId}
        cardIDs = factoryData.get('card_ids', {})
        if not isinstance(cardIDs, dict):
            cardIDs = {}
        
        # 找到并移除卡牌
        slotToRemove = None
        for slot, cid in cardIDs.items():
            if cid == cardID:
                slotToRemove = slot
                break
        
        cards = self.game.town.cards or {}
        
        if slotToRemove is not None:
            del cardIDs[slotToRemove]
            factoryData['card_ids'] = cardIDs
            
            # 先保存 card_ids 更新，让 calculateFactorySkillEffects 能读取到新的卡牌列表
            orderFactory[buildingID] = factoryData
            self.game.town.order_factory = orderFactory
            
            # 计算并消耗被移除卡牌的能量
            if cardID in cards:
                cardData = cards[cardID]
                refreshTime = cardData.get('energy_refresh_time', 0)
                if refreshTime > 0:
                    # 获取能量消耗配置
                    buildings = self.game.town.buildings or {}
                    buildData = buildings.get(buildingID, {})
                    curLevel = buildData.get('level', 1)
                    prodCfg = getProductionCsv(buildingID, curLevel)
                    energyExpend = getattr(prodCfg, 'energyExpend', 1) if prodCfg else 1
                    
                    # 计算技能减少的消耗（订单工厂使用 orderEnergyCost）
                    skillEffect = getCardSkillEffect(self.game, cardID, buildingID, FactoryType.ORDER)
                    effectiveEnergyExpend = max(0, energyExpend - skillEffect['orderEnergyCost'])
                    
                    # 计算消耗的能量
                    elapsedHours = (now - refreshTime) / 3600.0
                    consumed = effectiveEnergyExpend * elapsedHours
                    currentEnergy = cardData.get('energy', 0)
                    cardData['energy'] = max(0, int(currentEnergy - consumed))
                
                cardData['status'] = TownCardState.IDLE
                cardData['energy_refresh_time'] = now  # 设为当前时间，用于前端计算恢复量
                cards[cardID] = cardData
                self.game.town.cards = cards
            
            # 如果订单正在进行中，重新计算 needs_time（技能时间加成实时生效）
            startTime = factoryData.get('start_time', 0)
            if startTime > 0:
                baseNeedsTime = factoryData.get('base_needs_time', 0)
                orderCount = factoryData.get('count', 0)
                
                if baseNeedsTime > 0 and orderCount > 0:
                    # 获取剩余卡牌的能量（被移除的卡牌已经从 cardIDs 中删除）
                    cardIDList = cardIDs.values() if isinstance(cardIDs, dict) else (cardIDs or [])
                    totalEnergy = 0
                    for cid in cardIDList:
                        if cid:
                            cdata = cards.get(cid, {})
                            totalEnergy += cdata.get('energy', 0)
                    
                    # 重新计算技能效果（基于剩余卡牌）
                    skillEffect = calculateFactorySkillEffects(self.game, buildingID, FactoryType.ORDER, totalEnergy, orderCount)
                    timeReduce = skillEffect['orderTimeReduce']
                    
                    # 新的需要时间 = 基础时间 - 技能减少时间
                    newNeedsTime = max(1, baseNeedsTime - int(timeReduce))
                    
                    # 更新 needs_time（start_time 保持不变，已过去的时间不会返回）
                    factoryData['needs_time'] = newNeedsTime
                    orderFactory[buildingID] = factoryData
                    self.game.town.order_factory = orderFactory
                    
                    logger.info('TownOrderCardRemove: recalc needs_time, base=%s reduce=%s new=%s', 
                               baseNeedsTime, timeReduce, newNeedsTime)
        
        logger.info('TownOrderCardRemove: buildingID=%s cardID=%s', buildingID, cardID)
        
        # 返回更新后的 town model，让前端同步卡牌状态
        self.write({'model': {'town': self.game.town.model}})


class TownOrderReceive(RequestHandlerTask):
    """订单生产 - 收取产出
    前端调用: gGameApp:requestServer("/town/order/receive", ...)
    """
    url = r'/town/order/receive'
    
    @coroutine
    def run(self):
        buildingID = self.input.get('buildingID', None)
        if buildingID is None:
            raise ClientError('buildingID required')
        buildingID = int(buildingID)  # 确保是纯整数，兼容 Go 端 document.Integer
        
        # 获取订单工厂数据
        orderFactory = self.game.town.order_factory or {}
        factoryData = orderFactory.get(buildingID, {})
        
        if not factoryData:
            raise ClientError('no order')
        
        startTime = factoryData.get('start_time', 0)
        needsTime = factoryData.get('needs_time', 0)
        orderCount = factoryData.get('count', 0)
        
        if startTime == 0:
            raise ClientError('order not started')
        
        now = nowtime_t()
        if now < startTime + needsTime:
            raise ClientError('order not finished')
        
        # 获取建筑数据
        buildings = self.game.town.buildings or {}
        buildData = buildings.get(buildingID, {})
        curLevel = buildData.get('level', 1)
        
        # 获取生产配置
        prodCfg = getProductionCsv(buildingID, curLevel)
        if prodCfg is None:
            raise ClientError('production config not found')
        
        # 计算产出
        efficient = getattr(prodCfg, 'efficient', 20)
        itemKey = getattr(prodCfg, 'item', 'coin16')
        # CSV 中 item 字段可能是字符串，转成整数
        if itemKey and isinstance(itemKey, str) and itemKey.isdigit():
            itemKey = int(itemKey)
        
        # 计算卡牌技能效果（订单生产的产出加成）
        skillEffect = calculateFactorySkillEffects(self.game, buildingID, FactoryType.ORDER)
        productBonus = skillEffect['productEffect']
        
        # 产出 = (基础效率 + 技能加成) * 订单数
        effectiveEfficient = efficient + productBonus
        totalOutput = int(effectiveEfficient * orderCount)
        
        # 发放奖励
        gain = ObjectGainAux(self.game, {itemKey: totalOutput})
        gain.gain(src='town_order_receive')
        
        # 重置订单数据
        factoryData['start_time'] = 0
        factoryData['needs_time'] = 0
        factoryData['count'] = 0
        orderFactory[buildingID] = factoryData
        self.game.town.order_factory = orderFactory
        
        # 更新卡牌状态为待命，并计算能量消耗
        # card_ids 是字典格式 {slotIdx: cardDbId}
        cardIDs = factoryData.get('card_ids', {})
        if isinstance(cardIDs, dict):
            cardIDList = cardIDs.values()
        else:
            cardIDList = cardIDs if cardIDs else []
        cards = self.game.town.cards or {}
        energyExpend = getattr(prodCfg, 'energyExpend', 1)
        
        for cardDbId in cardIDList:
            if cardDbId:
                cardData = cards.get(cardDbId, {})
                refreshTime = cardData.get('energy_refresh_time', 0)
                if refreshTime > 0:
                    # 计算技能减少的消耗
                    cardSkillEffect = getCardSkillEffect(self.game, cardDbId, buildingID, FactoryType.ORDER)
                    effectiveEnergyExpend = max(0, energyExpend - cardSkillEffect['orderEnergyCost'])
                    
                    # 计算消耗的能量
                    elapsedHours = (now - refreshTime) / 3600.0
                    consumed = effectiveEnergyExpend * elapsedHours
                    currentEnergy = cardData.get('energy', 0)
                    cardData['energy'] = max(0, int(currentEnergy - consumed))
                
                cardData['status'] = TownCardState.IDLE
                cardData['energy_refresh_time'] = now  # 设为当前时间，用于前端计算恢复量
                cards[cardDbId] = cardData
        self.game.town.cards = cards
        
        logger.info('TownOrderReceive: buildingID=%s output=%s item=%s productBonus=%s', 
                    buildingID, totalOutput, itemKey, productBonus)
        
        self.write({'view': {itemKey: totalOutput}})


class TownOrderCancel(RequestHandlerTask):
    """订单生产 - 取消订单（提前结束）
    前端调用: gGameApp:requestServer("/town/order/cancel", ...)
    提前结束时按已完成时间比例发放部分奖励
    """
    url = r'/town/order/cancel'
    
    @coroutine
    def run(self):
        buildingID = self.input.get('buildingID', None)
        if buildingID is None:
            raise ClientError('buildingID required')
        buildingID = int(buildingID)  # 确保是纯整数，兼容 Go 端 document.Integer
        
        # 获取订单工厂数据
        orderFactory = self.game.town.order_factory or {}
        factoryData = orderFactory.get(buildingID, {})
        
        if not factoryData:
            raise ClientError('no order')
        
        startTime = factoryData.get('start_time', 0)
        needsTime = factoryData.get('needs_time', 0)
        orderCount = factoryData.get('count', 0)
        
        # 获取生产配置
        buildings = self.game.town.buildings or {}
        buildData = buildings.get(buildingID, {})
        curLevel = buildData.get('level', 1)
        prodCfg = getProductionCsv(buildingID, curLevel)
        energyExpend = getattr(prodCfg, 'energyExpend', 1) if prodCfg else 1
        
        now = nowtime_t()
        partialOutput = 0
        itemKey = None
        
        # 如果订单已开始，计算部分完成的奖励
        if startTime > 0 and needsTime > 0 and orderCount > 0 and prodCfg:
            # 计算已完成时间比例
            elapsedTime = now - startTime
            completionRatio = min(1.0, float(elapsedTime) / float(needsTime))
            
            # 获取产出配置
            efficient = getattr(prodCfg, 'efficient', 20)
            itemKey = getattr(prodCfg, 'item', 'coin16')
            if itemKey and isinstance(itemKey, str) and itemKey.isdigit():
                itemKey = int(itemKey)
            
            # 计算卡牌技能效果（订单生产的产出加成）
            skillEffect = calculateFactorySkillEffects(self.game, buildingID, FactoryType.ORDER)
            productBonus = skillEffect['productEffect']
            
            # 部分产出 = (基础效率 + 技能加成) * 订单数 * 完成比例
            effectiveEfficient = efficient + productBonus
            fullOutput = effectiveEfficient * orderCount
            partialOutput = int(fullOutput * completionRatio)
            
            # 发放部分奖励
            if partialOutput > 0 and itemKey:
                gain = ObjectGainAux(self.game, {itemKey: partialOutput})
                gain.gain(src='town_order_cancel')
                logger.info('TownOrderCancel: partial reward buildingID=%s item=%s output=%s ratio=%.2f', 
                            buildingID, itemKey, partialOutput, completionRatio)
        
        # 重置订单数据
        factoryData['start_time'] = 0
        factoryData['needs_time'] = 0
        factoryData['count'] = 0
        orderFactory[buildingID] = factoryData
        self.game.town.order_factory = orderFactory
        
        # 更新卡牌状态为待命，并计算能量消耗
        # card_ids 是字典格式 {slotIdx: cardDbId}
        cardIDs = factoryData.get('card_ids', {})
        if isinstance(cardIDs, dict):
            cardIDList = cardIDs.values()
        else:
            cardIDList = cardIDs if cardIDs else []
        cards = self.game.town.cards or {}
        for cardDbId in cardIDList:
            if cardDbId:
                cardData = cards.get(cardDbId, {})
                refreshTime = cardData.get('energy_refresh_time', 0)
                if refreshTime > 0:
                    # 计算技能减少的消耗
                    cardSkillEffect = getCardSkillEffect(self.game, cardDbId, buildingID, FactoryType.ORDER)
                    effectiveEnergyExpend = max(0, energyExpend - cardSkillEffect['orderEnergyCost'])
                    
                    # 计算消耗的能量
                    elapsedHours = (now - refreshTime) / 3600.0
                    consumed = effectiveEnergyExpend * elapsedHours
                    currentEnergy = cardData.get('energy', 0)
                    cardData['energy'] = max(0, int(currentEnergy - consumed))
                
                cardData['status'] = TownCardState.IDLE
                cardData['energy_refresh_time'] = now  # 设为当前时间，用于前端计算恢复量
                cards[cardDbId] = cardData
        self.game.town.cards = cards
        
        logger.info('TownOrderCancel: buildingID=%s partialOutput=%s item=%s', buildingID, partialOutput, itemKey)
        
        # 返回格式需要是 {itemKey: count}，前端 showGainDisplay 会直接使用
        if partialOutput > 0 and itemKey:
            self.write({'view': {itemKey: partialOutput}})
        else:
            self.write({'view': {}})


# ============================================================================
# 一键收取
# 前端 URL: /game/town/receive/onekey
# ============================================================================
class TownReceiveOnekey(RequestHandlerTask):
    """一键收取所有工厂产出
    前端调用: gGameApp:requestServer("/game/town/receive/onekey", ...)
    """
    url = r'/game/town/receive/onekey'
    
    @coroutine
    def run(self):
        buildingIDs = self.input.get('buildingIDs', [])
        
        totalGain = {}
        now = nowtime_t()
        
        buildings = self.game.town.buildings or {}
        continuousFactory = self.game.town.continuous_factory or {}
        orderFactory = self.game.town.order_factory or {}
        
        for buildingID in buildingIDs:
            factoryType = BUILDING_FACTORY_TYPE.get(buildingID, FactoryType.NO_TYPE)
            
            if factoryType == FactoryType.NORMAL:
                # 连续生产收取
                factoryData = continuousFactory.get(buildingID, {})
                if factoryData:
                    buildData = buildings.get(buildingID, {})
                    curLevel = buildData.get('level', 1)
                    prodCfg = getProductionCsv(buildingID, curLevel)
                    
                    if prodCfg:
                        collectionTime = factoryData.get('collection_time', now)
                        totalStored = factoryData.get('total', 0)
                        
                        elapsedHours = (now - collectionTime) // 3600
                        if elapsedHours >= 1:
                            efficient = getattr(prodCfg, 'efficient', 0)
                            inventory = getattr(prodCfg, 'inventory', 100)
                            itemKey = getattr(prodCfg, 'item', None)
                            # CSV 中 item 字段可能是字符串，转成整数
                            if itemKey and isinstance(itemKey, str) and itemKey.isdigit():
                                itemKey = int(itemKey)
                            
                            # 计算卡牌技能效果
                            skillEffect = calculateFactorySkillEffects(self.game, buildingID, FactoryType.NORMAL)
                            productBonus = skillEffect['productEffect']
                            inventoryBonus = skillEffect['inventoryEffect']
                            
                            # 应用技能效果
                            effectiveEfficient = efficient + productBonus
                            effectiveInventory = inventory + inventoryBonus
                            
                            produced = effectiveEfficient * elapsedHours
                            totalStored += produced
                            canCollect = min(totalStored, effectiveInventory)
                            
                            if canCollect > 0:
                                if itemKey not in totalGain:
                                    totalGain[itemKey] = 0
                                totalGain[itemKey] += int(canCollect)
                                
                                # 同时更新 collection_time 和 calc_time
                                factoryData['collection_time'] = now
                                factoryData['calc_time'] = now
                                # 保持 total >= 1，与单个收取逻辑一致
                                factoryData['total'] = max(totalStored - canCollect, 1)
                                continuousFactory[buildingID] = factoryData
            
            elif factoryType == FactoryType.ORDER:
                # 订单收取
                factoryData = orderFactory.get(buildingID, {})
                if factoryData:
                    startTime = factoryData.get('start_time', 0)
                    needsTime = factoryData.get('needs_time', 0)
                    orderCount = factoryData.get('count', 0)
                    
                    if startTime > 0 and now >= startTime + needsTime:
                        buildData = buildings.get(buildingID, {})
                        curLevel = buildData.get('level', 1)
                        prodCfg = getProductionCsv(buildingID, curLevel)
                        
                        if prodCfg:
                            efficient = getattr(prodCfg, 'efficient', 20)
                            itemKey = getattr(prodCfg, 'item', 'coin16')
                            # CSV 中 item 字段可能是字符串，转成整数
                            if itemKey and isinstance(itemKey, str) and itemKey.isdigit():
                                itemKey = int(itemKey)
                            
                            # 计算卡牌技能效果
                            skillEffect = calculateFactorySkillEffects(self.game, buildingID, FactoryType.ORDER)
                            productBonus = skillEffect['productEffect']
                            
                            # 应用技能效果
                            effectiveEfficient = efficient + productBonus
                            totalOutput = int(effectiveEfficient * orderCount)
                            
                            if itemKey not in totalGain:
                                totalGain[itemKey] = 0
                            totalGain[itemKey] += totalOutput
                            
                            # 重置卡牌状态，并计算能量消耗
                            energyExpend = getattr(prodCfg, 'energyExpend', 1)
                            cards = self.game.town.cards or {}
                            # card_ids 是字典格式 {slotIdx: cardDbId}
                            cardIDs = factoryData.get('card_ids', {})
                            if isinstance(cardIDs, dict):
                                cardIDList = cardIDs.values()
                            else:
                                cardIDList = cardIDs if cardIDs else []
                            for cardDbId in cardIDList:
                                if cardDbId:
                                    cardData = cards.get(cardDbId, {})
                                    refreshTime = cardData.get('energy_refresh_time', 0)
                                    if refreshTime > 0:
                                        # 计算技能减少的消耗
                                        cardSkillEffect = getCardSkillEffect(self.game, cardDbId, buildingID, FactoryType.ORDER)
                                        effectiveEnergyExpend = max(0, energyExpend - cardSkillEffect['orderEnergyCost'])
                                        # 计算消耗的能量
                                        elapsedHours = (now - refreshTime) / 3600.0
                                        consumed = effectiveEnergyExpend * elapsedHours
                                        currentEnergy = cardData.get('energy', 0)
                                        cardData['energy'] = max(0, int(currentEnergy - consumed))
                                    
                                    cardData['status'] = TownCardState.IDLE
                                    cardData['energy_refresh_time'] = now  # 设为当前时间，用于前端计算恢复量
                                    cards[cardDbId] = cardData
                            self.game.town.cards = cards
                            
                            factoryData['start_time'] = 0
                            factoryData['needs_time'] = 0
                            factoryData['count'] = 0
                            orderFactory[buildingID] = factoryData
        
        # 保存数据
        self.game.town.continuous_factory = continuousFactory
        self.game.town.order_factory = orderFactory
        
        # 发放奖励
        if totalGain:
            gain = ObjectGainAux(self.game, totalGain)
            gain.gain(src='town_receive_onekey')
        
        logger.info('TownReceiveOnekey: gain=%s', totalGain)
        
        # 前端期望嵌套格式: {1: {itemKey: num, ...}}
        self.write({'view': {1: totalGain} if totalGain else {}})


# ============================================================================
# 商店系统
# 前端 URL: /game/town/shop/xxx
# ============================================================================
class TownShopGet(RequestHandlerTask):
    """获取商店数据
    前端调用: gGameApp:requestServer("/game/town/shop/get", ...)
    """
    url = r'/game/town/shop/get'
    
    @coroutine
    def run(self):
        # 检查是否需要刷新
        if self.game.townShop.isPast():
            self.game.townShop.makeShop()
        
        self.write({'view': {}})


class TownShopRefresh(RequestHandlerTask):
    """刷新商店
    前端调用: gGameApp:requestServer("/game/town/shop/refresh", ..., itemRefresh)
    """
    url = r'/game/town/shop/refresh'
    
    @coroutine
    def run(self):
        itemRefresh = self.input.get('itemRefresh', False)
        
        if not itemRefresh:
            # 钻石刷新
            refreshTimes = self.game.dailyRecord.town_shop_refresh_times or 0
            
            # 获取VIP刷新次数上限
            maxTimes = getattr(self.game.role._currVIPCsv, 'townShopRefreshLimit', 2)
            if refreshTimes >= maxTimes:
                raise ClientError(ErrDefs.shopRefreshUp)
            
            # 从 cost.csv 读取刷新消耗配置 (ID=132: townshop_refresh_cost)
            from game.object.game.costcsv import ObjectCostCSV
            costRMB = ObjectCostCSV.getSeqCost(132, refreshTimes)
            
            cost = ObjectCostAux(self.game, {'rmb': costRMB})
            if not cost.isEnough():
                raise ClientError(ErrDefs.costNotEnough)
            cost.cost(src='town_shop_refresh')
            
            # 更新刷新次数
            self.game.dailyRecord.town_shop_refresh_times = refreshTimes + 1
        else:
            # 道具刷新（如果有的话）
            pass
        
        # 刷新商店
        self.game.townShop.makeShop()
        
        self.write({'view': {}})


class TownShopBuy(RequestHandlerTask):
    """购买商店物品
    前端调用: gGameApp:requestServer("/game/town/shop/buy", ...)
    """
    url = r'/game/town/shop/buy'
    
    @coroutine
    def run(self):
        idx = self.input.get('idx', None)
        if idx is None:
            raise ClientError('idx required')
        count = self.input.get('count', 1)
        if count <= 0:
            raise ClientError('count error')
        
        # 检查是否可以购买
        can, reason = self.game.townShop.canBuy(idx)
        if not can:
            raise ClientError(reason)
        
        # 获取商品信息
        items = self.game.townShop.items or {}
        if idx not in items:
            raise ClientError('item not exist')
        
        csvID, itemID = items[idx]
        
        # 获取商品配置
        if not hasattr(csv, 'town') or not hasattr(csv.town, 'supermarket'):
            raise ClientError('config not found')
        
        if csvID not in csv.town.supermarket:
            raise ClientError('item config not found')
        cfg = csv.town.supermarket[csvID]

        # 限购次数（按天/周/月/永久）
        if cfg.limitTimes and cfg.limitTimes > 0:
            shopLimit = self.game.role.shop_limit.setdefault('town_shop', {})
            buyTimes, lastDate = shopLimit.get(idx, (0, 0))
            if cfg.limitType == 1:
                nowDate = todayinclock5date2int()
            elif cfg.limitType == 2:
                nowDate = weekinclock5date2int()
            elif cfg.limitType == 3:
                nowDate = monthinclock5date2int()
            elif cfg.limitType == 4:
                nowDate = lastDate or todayinclock5date2int()
            else:
                nowDate = lastDate

            if cfg.limitType in (1, 2, 3) and lastDate != nowDate:
                buyTimes = 0

            if buyTimes + count > cfg.limitTimes:
                raise ClientError(ErrDefs.buyShopTimesLimit)

        # 扣除消耗
        costMap = getattr(cfg, 'costMap', {}) or {}
        
        if costMap:
            totalCost = {}
            for costKey, costNum in costMap.iteritems():
                totalCost[costKey] = costNum * count
            cost = ObjectCostAux(self.game, totalCost)
            if not cost.isEnough():
                raise ClientError(ErrDefs.costNotEnough)
            cost.cost(src='town_shop_buy')
        
        # 发放奖励 - itemID 是从 items[idx][1] 获取的物品ID，数量是 itemCount
        itemCount = getattr(cfg, 'itemCount', 1) or 1
        award = {itemID: itemCount * count}
        
        if award:
            gain = ObjectGainAux(self.game, award)
            gain.gain(src='town_shop_buy')

        # 更新购买次数
        if cfg.limitTimes and cfg.limitTimes > 0:
            # 有限购的商品，按限购类型更新购买次数
            shopLimit = self.game.role.shop_limit.setdefault('town_shop', {})
            buyTimes, lastDate = shopLimit.get(idx, (0, 0))
            if cfg.limitType == 1:
                nowDate = todayinclock5date2int()
            elif cfg.limitType == 2:
                nowDate = weekinclock5date2int()
            elif cfg.limitType == 3:
                nowDate = monthinclock5date2int()
            elif cfg.limitType == 4:
                nowDate = lastDate or todayinclock5date2int()
            else:
                nowDate = lastDate

            if cfg.limitType in (1, 2, 3) and lastDate != nowDate:
                buyTimes = 0
            buyTimes += count
            shopLimit[idx] = (buyTimes, nowDate)

            if buyTimes >= cfg.limitTimes:
                buy = self.game.townShop.buy or {}
                buy[idx] = True
                self.game.townShop.buy = buy
        else:
            # 没有限购的商品，购买一次后标记为已购买（每日刷新后重置）
            buy = self.game.townShop.buy or {}
            buy[idx] = True
            self.game.townShop.buy = buy

        # 保留购买行为校验
        self.game.townShop.buyItem(idx)
        
        logger.info('TownShopBuy: idx=%s csvID=%s itemID=%s count=%s', idx, csvID, itemID, itemCount)
        
        self.write({'view': award})


# ============================================================================
# 家园商店
# 前端 URL: /town/home/shop/xxx
# ============================================================================
class TownHomeShopBuy(RequestHandlerTask):
    """家园商店购买
    前端调用: gGameApp:requestServer("/town/home/shop/buy", ...)
    """
    url = r'/town/home/shop/buy'
    
    @coroutine
    def run(self):
        csvID = self.input.get('csvID', None)
        count = self.input.get('count', 1)
        if csvID is None:
            raise ClientError('csvID required')
        
        # 获取配置
        if csvID not in csv.town.home_shop:
            raise ClientError('config not found')
        cfg = csv.town.home_shop[csvID]

        # 限购次数（按天/周/月/永久）
        if cfg.limitTimes and cfg.limitTimes > 0:
            if not self.game.role.canShopBuy('town_home_shop', csvID, count, cfg.limitType, cfg.limitTimes):
                raise ClientError(ErrDefs.buyShopTimesLimit)

        # 兑换次数限制（带恢复间隔）
        if cfg.exchangeLimit != -1:
            if cfg.exchangeLimit < count:
                raise ClientError(ErrDefs.csvShopTimeNotEnough)
            townHome = self.game.role.town_home or {}
            exchangeRecord = townHome.setdefault('home_shop_exchange', {})
            now = nowtime_t()
            if csvID in exchangeRecord:
                buyTimes, lastRecoverTime = exchangeRecord[csvID]
                if cfg.regainHour:
                    point = int(now - lastRecoverTime) / (cfg.regainHour * 3600)
                    if point >= 1:
                        buyTimes -= point
                        lastRecoverTime += point * (cfg.regainHour * 3600)
                        exchangeRecord[csvID] = (buyTimes, lastRecoverTime)
                if buyTimes >= cfg.exchangeLimit or cfg.exchangeLimit - buyTimes < count:
                    raise ClientError(ErrDefs.csvShopTimeNotEnough)
                if buyTimes <= 0:
                    exchangeRecord.pop(csvID, None)
            self.game.role.town_home = townHome
        
        # 检查消耗
        costMap = getattr(cfg, 'costMap', {}) or {}
        totalCost = {}
        for costKey, costNum in costMap.iteritems():
            totalCost[costKey] = costNum * count
        
        # 扣除消耗
        cost = ObjectCostAux(self.game, totalCost)
        if not cost.isEnough():
            raise ClientError('cost not enough')
        cost.cost(src='town_home_shop_buy')
        
        # 获得物品（家具存到 furniture 中）
        itemMap = getattr(cfg, 'itemMap', {}) or {}
        furniture = self.game.role._db.get('furniture', {})
        gainItems = {}  # 使用字典格式 {itemID: count}
        totalExpGain = 0  # 收藏经验增加
        affectedSeriesIDs = set()  # 受影响的套装ID
        
        for itemID, itemNum in itemMap.iteritems():
            totalNum = itemNum * count
            oldNum = furniture.get(itemID, 0)
            furniture[itemID] = oldNum + totalNum
            gainItems[itemID] = gainItems.get(itemID, 0) + totalNum
            
            # 计算收藏经验
            if itemID in csv.town.home_furniture:
                furCfg = csv.town.home_furniture[itemID]
                expAdd = furCfg.expAdd or 0
                repeatExpAdd = furCfg.repeatExpAdd or 0
                
                if oldNum == 0:
                    # 首次获得：第一个给 expAdd，后续给 repeatExpAdd
                    totalExpGain += expAdd
                    if totalNum > 1:
                        totalExpGain += repeatExpAdd * (totalNum - 1)
                else:
                    # 重复获得：全部给 repeatExpAdd
                    totalExpGain += repeatExpAdd * totalNum
                
                # 记录受影响的套装ID
                seriesID = furCfg.series or 0
                if seriesID > 0:
                    affectedSeriesIDs.add(seriesID)
        
        self.game.role.furniture = furniture
        
        # 检查套装收集情况
        if affectedSeriesIDs:
            _checkFurnitureSeriesCollection(self.game, furniture, affectedSeriesIDs)

        # 更新购买次数
        if cfg.limitTimes and cfg.limitTimes > 0:
            self.game.role.addShopBuy('town_home_shop', csvID, count, cfg.limitType)
        if cfg.exchangeLimit != -1:
            townHome = self.game.role.town_home or {}
            exchangeRecord = townHome.setdefault('home_shop_exchange', {})
            if csvID in exchangeRecord:
                buyTimes, lastRecoverTime = exchangeRecord[csvID]
                exchangeRecord[csvID] = (buyTimes + count, lastRecoverTime)
            else:
                exchangeRecord[csvID] = (count, nowtime_t())
            self.game.role.town_home = townHome
        
        # 增加收藏经验并检查升级
        if totalExpGain > 0:
            _addCollectionExpAndCheckLevelUp(self.game, totalExpGain)
        
        logger.info('TownHomeShopBuy: csvID=%s count=%s cost=%s items=%s expGain=%s', 
                    csvID, count, totalCost, itemMap, totalExpGain)
        
        # 返回获得的物品，格式: {itemID: count, ...} 供 showGainDisplay 显示
        self.write({'view': gainItems})


# ============================================================================
# 小屋改名
# ============================================================================
class TownHomeRename(RequestHandlerTask):
    """小屋改名
    前端调用: gGameApp:requestServer("/town/home/rename", ..., name)
    """
    url = r'/town/home/rename'
    
    @coroutine
    def run(self):
        name = self.input.get('name', '')
        if not name:
            raise ClientError('name required')
        
        # 检查名称长度
        if len(name) > 20:
            raise ClientError('name too long')
        
        # 扣除重命名费用（从配置获取）
        renameCost = 100  # 默认值
        if hasattr(csv, 'common_config'):
            for cfgId in csv.common_config:
                cfg = csv.common_config[cfgId]
                if hasattr(cfg, 'buildingHomeRenameCost'):
                    renameCost = cfg.buildingHomeRenameCost
                    break
        
        if renameCost > 0:
            cost = ObjectCostAux(self.game, {'rmb': renameCost})
            if not cost.isEnough():
                raise ClientError(ErrDefs.costNotEnough)
            cost.cost(src='town_home_rename')
        
        # 更新小屋名称（存储在 town.home.name 中，前端从这里读取）
        home = self.game.town.home or {}
        home['name'] = name
        self.game.town.home = home
        
        logger.info('TownHomeRename: name=%s cost=%s', name, renameCost)
        
        self.write({'view': {}})


# ============================================================================
# 卡牌休息
# 前端 URL: /town/home/card/xxx
# ============================================================================
class TownHomeCardRest(RequestHandlerTask):
    """卡牌休息
    前端调用: gGameApp:requestServer("/town/home/card/rest", ...)
    """
    url = r'/town/home/card/rest'
    
    @coroutine
    def run(self):
        # 支持单个 cardID 或多个 cardIDs
        cardID = self.input.get('cardID', None)
        cardIDs = self.input.get('cardIDs', None)
        
        if cardIDs:
            # Lua table 可能被序列化为 dict {1: dbid, 2: dbid}，需要取 values
            if isinstance(cardIDs, dict):
                rawList = list(cardIDs.values())
            elif isinstance(cardIDs, list):
                rawList = cardIDs
            else:
                rawList = [cardIDs]
            # 过滤无效的 cardID（只保留字符串类型的 ObjectId）
            cardList = [cid for cid in rawList if isinstance(cid, basestring)]
        elif cardID:
            cardList = [cardID]
        else:
            raise ClientError('cardID or cardIDs required')
        
        now = nowtime_t()
        cards = self.game.town.cards or {}
        
        for cid in cardList:
            if cid:
                cardData = cards.get(cid, {})
                cardData['status'] = TownCardState.REST
                cardData['energy_refresh_time'] = now
                # 确保能量字段已初始化
                if 'energy' not in cardData:
                    maxEnergy = getCardMaxEnergy(self.game, cid)
                    cardData['max_energy'] = maxEnergy
                    cardData['energy'] = maxEnergy
                cards[cid] = cardData
        
        self.game.town.cards = cards
        
        logger.info('TownHomeCardRest: cardIDs=%s', cardList)
        
        self.write({'model': {'town': self.game.town.model}})


class TownHomeCardRemove(RequestHandlerTask):
    """卡牌移除休息
    前端调用: gGameApp:requestServer("/town/home/card/remove", ...)
    """
    url = r'/town/home/card/remove'
    
    @coroutine
    def run(self):
        # 支持单个 cardID 或多个 cardIDs
        cardID = self.input.get('cardID', None)
        cardIDs = self.input.get('cardIDs', None)
        
        if cardIDs:
            # Lua table 可能被序列化为 dict {1: dbid, 2: dbid}，需要取 values
            if isinstance(cardIDs, dict):
                rawList = list(cardIDs.values())
            elif isinstance(cardIDs, list):
                rawList = cardIDs
            else:
                rawList = [cardIDs]
            # 过滤无效的 cardID（只过滤非字符串）
            cardList = [cid for cid in rawList if isinstance(cid, basestring)]
        elif cardID:
            cardList = [cardID]
        else:
            raise ClientError('cardID or cardIDs required')
        
        now = nowtime_t()
        cards = self.game.town.cards or {}
        
        for cid in cardList:
            if cid:
                cardData = cards.get(cid, {})
                cardData['status'] = TownCardState.IDLE
                cardData['energy_refresh_time'] = now  # 从现在开始计算恢复
                cards[cid] = cardData
        
        self.game.town.cards = cards
        
        logger.info('TownHomeCardRemove: cardIDs=%s', cardList)
        
        self.write({'model': {'town': self.game.town.model}})


# ============================================================================
# 家园布局
# 前端 URL: /town/home/layout/xxx
# ============================================================================
class TownHomeLayoutApply(RequestHandlerTask):
    """应用家园布局
    前端调用: gGameApp:requestServer("/town/home/layout/apply", ..., layoutData, levelData)
    layoutData: {楼层索引: [[家具ID, 类型, x, y, flip], ...]}
    levelData: {楼层索引: 等级}
    """
    url = r'/town/home/layout/apply'
    
    @coroutine
    def run(self):
        # 前端传的参数: {layouts: {...}, levels: [...]}
        layoutData = self.input.get('layouts', {})
        levelData = self.input.get('levels', {})
        
        # 获取现有布局数据，进行合并而不是覆盖
        existingLayout = dict(self.game.town.home_apply_layout or {})
        
        # 确保每个值都是数组格式，移除 None 值（Go 端要求 [][]int，不能是 nil）
        # 并确保所有数值都是整数类型（避免 float 导致 msgpack 解码失败）
        for floorIdx, furnitureList in layoutData.iteritems():
            if furnitureList is not None and isinstance(furnitureList, list):
                # 确保内部每个数组的每个元素都是整数
                cleanedFurniture = []
                for item in furnitureList:
                    if isinstance(item, list):
                        cleanedFurniture.append([int(v) for v in item])
                existingLayout[int(floorIdx)] = cleanedFurniture
        self.game.town.home_apply_layout = existingLayout
        
        # 计算已布置的家具数量（不包括墙壁和地板类型）
        # 类型: 1=家具, 2=地毯, 3=墙面装饰, 4=地板, 5=墙壁
        furniture_count = 0
        for floorIdx, furnitureList in existingLayout.items():
            if isinstance(furnitureList, list):
                for item in furnitureList:
                    if isinstance(item, list) and len(item) >= 2:
                        itemType = item[1] if len(item) > 1 else 1
                        # 排除地板(4)和墙壁(5)类型
                        if itemType not in (4, 5):
                            furniture_count += 1
        
        # 更新 home.furniture_placed_num
        home = self.game.town.home or {}
        home['furniture_placed_num'] = furniture_count
        self.game.town.home = home
        
        # 更新布局版本号（前端根据此值判断是否显示角色）
        currentVersion = self.game.role.town_home_layout_version or 0
        self.game.role.town_home_layout_version = currentVersion + 1
        
        logger.info('TownHomeLayoutApply: layoutData=%s levelData=%s furniture_count=%s version=%s', 
                    existingLayout, levelData, furniture_count, self.game.role.town_home_layout_version)
        
        # 不手动返回 model，框架会自动通过 sync 同步脏数据
        # 之前返回 model.role 格式不正确（缺少 _db 包装），会导致前端崩溃
        self.write({'view': {}})


class TownHomeLayoutSave(RequestHandlerTask):
    """保存家园布局方案
    前端调用: gGameApp:requestServer("/town/home/layout/save", planType, layout)
    planType: 0=庭院, 1=室内 (MAP_TYPE.YARD=0, MAP_TYPE.HOME=1)
    layout: 单层家具数据 [[家具ID, 类型, x, y, flip], ...]
    """
    url = r'/town/home/layout/save'
    
    @coroutine
    def run(self):
        # 前端参数: planType (0=庭院, 1=室内), layout
        planType = self.input.get('planType', None) or self.input.get('planID', None)
        layout = self.input.get('layout', {}) or self.input.get('layoutData', {})
        
        if planType is None:
            raise ClientError('planType required')
        
        planType = int(planType)
        
        # planType 同时作为楼层索引 (0=庭院, 1=室内)
        floorIdx = planType
        
        # 确保 layout 数据格式正确（所有数值转为整数）
        cleanedLayout = []
        if isinstance(layout, list):
            for item in layout:
                if isinstance(item, list):
                    cleanedLayout.append([int(v) for v in item])
        
        plans = self.game.town.home_layout_plan or {}
        # 查找下一个可用的 planID
        existingIDs = [k for k in plans.keys() if isinstance(k, int)]
        newPlanID = max(existingIDs) + 1 if existingIDs else 1
        
        # Go 端期望 TownHomeLayoutPlanItem 结构: {name: string, layouts: {floorIdx: [[int,...]]}}
        plans[newPlanID] = {
            'name': '', 
            'layouts': {floorIdx: cleanedLayout},
            'type': planType  # 0=庭院, 1=室内
        }
        self.game.town.home_layout_plan = plans
        
        logger.info('TownHomeLayoutSave: newPlanID=%s planType=%s', newPlanID, planType)
        
        self.write({'view': {}})


class TownHomeLayoutUpdate(RequestHandlerTask):
    """更新家园布局方案
    前端调用: gGameApp:requestServer("/town/home/layout/update", layoutId, layout)
    layoutId: 方案ID
    layout: 单层家具数据 [[家具ID, 类型, x, y, flip], ...]
    """
    url = r'/town/home/layout/update'
    
    @coroutine
    def run(self):
        # 前端参数: layoutId, layout
        planID = self.input.get('layoutId', None) or self.input.get('planID', None)
        layout = self.input.get('layout', {}) or self.input.get('layoutData', {})
        
        if planID is None:
            raise ClientError('layoutId required')
        
        plans = self.game.town.home_layout_plan or {}
        if planID not in plans:
            raise ClientError('plan not exist')
        
        existingPlan = plans[planID]
        existingName = existingPlan.get('name', '') if isinstance(existingPlan, dict) else ''
        
        # 从现有方案获取类型，确定楼层索引
        # type: 0=庭院, 1=室内 (MAP_TYPE.YARD=0, MAP_TYPE.HOME=1)
        planType = existingPlan.get('type', 1) if isinstance(existingPlan, dict) else 1
        floorIdx = int(planType)  # 楼层索引 = 类型值
        
        # 确保 layout 数据格式正确（所有数值转为整数）
        cleanedLayout = []
        if isinstance(layout, list):
            for item in layout:
                if isinstance(item, list):
                    cleanedLayout.append([int(v) for v in item])
        
        # Go 端期望 TownHomeLayoutPlanItem 结构: {name: string, layouts: {floorIdx: [[int,...]]}}
        plans[planID] = {
            'name': existingName, 
            'layouts': {floorIdx: cleanedLayout},
            'type': planType
        }
        self.game.town.home_layout_plan = plans
        
        logger.info('TownHomeLayoutUpdate: planID=%s floorIdx=%s', planID, floorIdx)
        
        self.write({'view': {}})


class TownHomeLayoutDelete(RequestHandlerTask):
    """删除家园布局方案
    前端调用: gGameApp:requestServer("/town/home/layout/delete", layoutId)
    """
    url = r'/town/home/layout/delete'
    
    @coroutine
    def run(self):
        # 前端参数: layoutId (或兼容 planID)
        planID = self.input.get('layoutId', None) or self.input.get('planID', None)
        
        if planID is None:
            raise ClientError('layoutId required')
        
        plans = self.game.town.home_layout_plan or {}
        if planID in plans:
            del plans[planID]
            self.game.town.home_layout_plan = plans
        
        logger.info('TownHomeLayoutDelete: planID=%s', planID)
        
        self.write({'view': {}})


class TownHomeLayoutRename(RequestHandlerTask):
    """布局方案改名
    前端调用: gGameApp:requestServer("/town/home/layout/rename", ..., layoutId, name)
    """
    url = r'/town/home/layout/rename'
    
    @coroutine
    def run(self):
        layoutId = self.input.get('layoutId', None)
        name = self.input.get('name', '')
        
        if layoutId is None:
            raise ClientError('layoutId required')
        if not name:
            raise ClientError('name required')
        
        # 检查名称长度
        if len(name) > 20:
            raise ClientError('name too long')
        
        plans = self.game.town.home_layout_plan or {}
        if layoutId not in plans:
            raise ClientError('layout not found')
        
        # 更新方案名称 (确保 plan 是正确结构)
        plan = plans[layoutId]
        if isinstance(plan, dict) and 'layouts' in plan:
            plan['name'] = name
        else:
            # 兼容旧数据格式
            plans[layoutId] = {'name': name, 'layouts': plan}
        self.game.town.home_layout_plan = plans
        
        logger.info('TownHomeLayoutRename: layoutId=%s name=%s', layoutId, name)
        
        self.write({'view': {}})


# ============================================================================
# 家园扩展
# 前端 URL: /game/town/home/expand
# ============================================================================
class TownHomeExpand(RequestHandlerTask):
    """家园扩展
    前端调用: gGameApp:requestServer("/game/town/home/expand", ...)
    """
    url = r'/game/town/home/expand'
    
    @coroutine
    def run(self):
        level = self.input.get('level', None)
        if level is None:
            raise ClientError('level required')
        
        home = self.game.town.home or {}
        curLevel = home.get('expand_level', 0)
        
        if level != curLevel + 1:
            raise ClientError('invalid level')
        
        # 获取扩展配置
        if not hasattr(csv, 'town') or not hasattr(csv.town, 'home_expand'):
            raise ClientError('config not found')
        
        if level not in csv.town.home_expand:
            raise ClientError('expand config not found')
        cfg = csv.town.home_expand[level]
        
        # 检查消耗
        cost_data = getattr(cfg, 'cost', {})
        if cost_data:
            cost = ObjectCostAux(self.game, cost_data)
            if not cost.isEnough():
                raise ClientError(ErrDefs.costNotEnough)
            cost.cost(src='town_home_expand')
        
        # 设置扩展时间
        expandCostTime = getattr(cfg, 'expandCostTime', 0)
        now = nowtime_t()
        
        home['expand_level'] = level
        home['expand_finish_time'] = now + expandCostTime if expandCostTime > 0 else 0
        self.game.town.home = home
        
        # 累计扩建次数（用于勋章统计）
        self.game.role.town_home_expand_count = (self.game.role.town_home_expand_count or 0) + 1
        
        logger.info('TownHomeExpand: level=%s', level)
        
        self.write({'view': {}})


class TownHomeExpandFinishAtOnce(RequestHandlerTask):
    """家园扩展立即完成
    前端调用: gGameApp:requestServer("/game/town/home/expand/finish/atonce", ...)
    """
    url = r'/game/town/home/expand/finish/atonce'
    
    @coroutine
    def run(self):
        home = self.game.town.home or {}
        finishTime = home.get('expand_finish_time', 0)
        
        if finishTime == 0:
            raise ClientError('not expanding')
        
        now = nowtime_t()
        if now >= finishTime:
            raise ClientError('already finished')
        
        # 计算加速费用（与前端保持一致）
        # 每 buildingCompletionInterval 分钟需要 buildingCompletionCost 钻石
        remainTime = max(0, finishTime - now)
        completionInterval = 60  # 默认60秒一个单位
        completionCost = 1  # 默认1钻石一个单位
        
        # 从配置获取
        if hasattr(csv, 'common_config'):
            for cfgId in csv.common_config:
                cfg = csv.common_config[cfgId]
                if hasattr(cfg, 'buildingCompletionInterval'):
                    completionInterval = cfg.buildingCompletionInterval * 60  # 转换为秒
                if hasattr(cfg, 'buildingCompletionCost'):
                    completionCost = cfg.buildingCompletionCost
                break
        
        # 计算需要的钻石数量
        import math
        speedUpCost = int(math.ceil(remainTime / completionInterval)) * completionCost
        
        # 扣除钻石
        if speedUpCost > 0:
            cost = ObjectCostAux(self.game, {'rmb': speedUpCost})
            if not cost.isEnough():
                raise ClientError(ErrDefs.costNotEnough)
            cost.cost(src='town_home_expand_speed')
        
        # 立即完成
        home['expand_finish_time'] = 0
        self.game.town.home = home
        
        logger.info('TownHomeExpandFinishAtOnce: cost=%s', speedUpCost)
        
        self.write({'view': {}})


# ============================================================================
# 待命卡牌系统
# 前端 URL: /game/town/ready/card/xxx
# ============================================================================
class TownReadyCardUnlock(RequestHandlerTask):
    """解锁待命卡牌槽位
    前端调用: gGameApp:requestServer("/game/town/ready/card/unlock", idx)
    
    解锁消耗配置: cost.csv ID=143 (town_ready_card_unlock_cost)
    """
    url = r'/game/town/ready/card/unlock'
    
    @coroutine
    def run(self):
        idx = self.input.get('idx', None)
        if idx is None:
            raise ClientError('idx required')
        
        # 获取当前解锁数量
        currentUnlockNum = self.game.town.ready_card_unlock_num or 0
        
        # 获取解锁消耗（使用项目标准方式：ObjectCostCSV.getSeqCost）
        # cost.csv ID=143: town_ready_card_unlock_cost, seqParam=<100;200;200;400;400;800;800>
        from game.object.game.costcsv import ObjectCostCSV
        unlockCost = ObjectCostCSV.getSeqCost(143, currentUnlockNum)
        
        if unlockCost:
            cost = ObjectCostAux(self.game, {'rmb': unlockCost})
            if not cost.isEnough():
                raise ClientError(ErrDefs.costNotEnough)
            cost.cost(src='town_ready_card_unlock')
        
        # 增加解锁数量
        self.game.town.ready_card_unlock_num = currentUnlockNum + 1
        
        logger.info('TownReadyCardUnlock: idx=%s unlockNum=%s->%s', idx, currentUnlockNum, currentUnlockNum + 1)
        
        self.write({'view': {}})


class TownReadyCardDeploy(RequestHandlerTask):
    """部署待命卡牌
    前端调用: gGameApp:requestServer("/game/town/ready/card/deploy", ...)
    """
    url = r'/game/town/ready/card/deploy'
    
    @coroutine
    def run(self):
        idx = self.input.get('idx', None)
        cardIDs = self.input.get('cardIDs', [])
        
        if idx is None:
            raise ClientError('idx required')
        
        # 前端可能传数组或字典格式，统一转换为字典格式 {位置: cardID}
        # 数组格式: [cardID1, cardID2, cardID3] -> {1: cardID1, 2: cardID2, 3: cardID3}
        # 字典格式: {1: cardID1, 2: cardID2} -> 直接使用
        if isinstance(cardIDs, list):
            # 数组转字典，只保留有效值
            cardIDsDict = {}
            for i, cardID in enumerate(cardIDs):
                if cardID:
                    cardIDsDict[i + 1] = cardID  # 位置从1开始
            cardIDs = cardIDsDict
        elif isinstance(cardIDs, dict):
            # 字典格式，过滤 None 值
            cardIDs = {k: v for k, v in cardIDs.items() if v}
        else:
            cardIDs = {}
        
        # 前端期望格式: {idx: {cards: {...}, name: ""}}
        # 使用 factory_teams 而不是 ready_cards，避免和 role.ready_cards 的数据库验证冲突
        factoryTeams = self.game.town.factory_teams
        if not factoryTeams:
            factoryTeams = {}
        else:
            factoryTeams = dict(factoryTeams)  # 转为普通 dict 操作
        
        # idx 为整数 key
        if idx in factoryTeams and isinstance(factoryTeams[idx], dict):
            teamData = dict(factoryTeams[idx])
        else:
            teamData = {}
        
        teamData['cards'] = cardIDs
        if 'name' not in teamData:
            teamData['name'] = ''
        factoryTeams[idx] = teamData
        self.game.town.factory_teams = factoryTeams
        
        logger.info('TownReadyCardDeploy: idx=%s cardIDs=%s', idx, cardIDs)
        
        # 返回更新后的数据，让前端同步
        self.write({'model': {'town': self.game.town.model}})


class TownReadyCardPlace(RequestHandlerTask):
    """放置待命卡牌到建筑
    前端调用: gGameApp:requestServer("/game/town/ready/card/place", ...)
    """
    url = r'/game/town/ready/card/place'
    
    @coroutine
    def run(self):
        buildingID = self.input.get('buildingID', None)
        idx = self.input.get('idx', None)
        cardIDs = self.input.get('cardIDs', {})
        
        if buildingID is None:
            raise ClientError('buildingID required')
        buildingID = int(buildingID)
        
        # Lua table 可能被 msgpack 编码为 array 或 map，统一转为 dict
        if isinstance(cardIDs, list):
            cardIdsMap = {}
            for i, cid in enumerate(cardIDs):
                if cid:
                    cardIdsMap[i + 1] = cid
        elif isinstance(cardIDs, dict):
            cardIdsMap = {k: v for k, v in cardIDs.items() if v}
        else:
            cardIdsMap = {}
        
        # 放置卡牌到对应工厂
        factoryType = BUILDING_FACTORY_TYPE.get(buildingID, FactoryType.NO_TYPE)
        
        if factoryType == FactoryType.NORMAL:
            continuousFactory = self.game.town.continuous_factory or {}
            factoryData = continuousFactory.get(buildingID, {})
            factoryData['card_ids'] = cardIdsMap
            now = nowtime_t()
            factoryData['collection_time'] = factoryData.get('collection_time', now)
            factoryData['calc_time'] = factoryData.get('calc_time', now)
            factoryData['total'] = factoryData.get('total', 0)
            continuousFactory[buildingID] = factoryData
            self.game.town.continuous_factory = continuousFactory
            
        elif factoryType == FactoryType.ORDER:
            orderFactory = self.game.town.order_factory or {}
            factoryData = orderFactory.get(buildingID, {})
            factoryData['card_ids'] = cardIdsMap
            orderFactory[buildingID] = factoryData
            self.game.town.order_factory = orderFactory
        
        # 更新卡牌状态（使用建筑对应的工作状态）
        workStatus = BUILDING_CARD_STATUS.get(buildingID, TownCardState.IDLE)
        now = nowtime_t()
        cards = self.game.town.cards or {}
        # 使用 cardIdsMap.values() 获取实际的 cardDbId，而不是遍历原始 cardIDs
        for cardDbId in cardIdsMap.values():
            if cardDbId:
                isNew = cardDbId not in cards
                cardData = cards.get(cardDbId, {})
                oldStatus = cardData.get('status', TownCardState.IDLE)
                oldEnergy = cardData.get('energy')
                cardData['status'] = workStatus
                # 确保能量字段已初始化（每次都重新计算 max_energy）
                maxEnergy = getCardMaxEnergy(self.game, cardDbId)
                cardData['max_energy'] = maxEnergy
                # 如果是新卡牌，初始化为满精力
                if isNew or 'energy' not in cardData or cardData.get('energy') is None:
                    cardData['energy'] = maxEnergy
                    logger.info('TownReadyCardPlace: init card %s energy to %s (isNew=%s)', cardDbId, maxEnergy, isNew)
                else:
                    logger.info('TownReadyCardPlace: card %s keep energy %s/%s', cardDbId, oldEnergy, maxEnergy)
                # 当卡牌开始工作时设置开始时间
                if oldStatus == TownCardState.IDLE and workStatus != TownCardState.IDLE:
                    cardData['energy_refresh_time'] = now
                elif 'energy_refresh_time' not in cardData:
                    cardData['energy_refresh_time'] = 0
                cards[cardDbId] = cardData
        self.game.town.cards = cards
        
        logger.info('TownReadyCardPlace: buildingID=%s idx=%s cardIDs=%s', buildingID, idx, cardIDs)
        
        # 返回更新后的 town model
        self.write({'model': {'town': self.game.town.model}})


class TownReadyCardRename(RequestHandlerTask):
    """重命名待命卡牌队伍
    前端调用: gGameApp:requestServer("/game/town/ready/card/rename", ...)
    """
    url = r'/game/town/ready/card/rename'
    
    @coroutine
    def run(self):
        idx = self.input.get('idx', None)
        name = self.input.get('name', '')
        
        if idx is None:
            raise ClientError('idx required')
        
        # 保存队伍名称
        factoryTeams = self.game.town.factory_teams
        if not factoryTeams:
            factoryTeams = {}
        else:
            factoryTeams = dict(factoryTeams)
        
        # idx 为整数 key
        if idx in factoryTeams and isinstance(factoryTeams[idx], dict):
            teamData = dict(factoryTeams[idx])
        else:
            teamData = {}
        
        teamData['name'] = name
        if 'cards' not in teamData:
            teamData['cards'] = {}
        factoryTeams[idx] = teamData
        self.game.town.factory_teams = factoryTeams
        
        logger.info('TownReadyCardRename: idx=%s name=%s', idx, name)
        
        self.write({'model': {'town': self.game.town.model}})


# ============================================================================
# 探险系统
# 前端 URL: /town/adventure/xxx
# ============================================================================
class TownAdventureSetout(RequestHandlerTask):
    """探险出发
    前端调用: gGameApp:requestServer("/town/adventure/setout", areaID, planID, cardIDs, explorerID)
    
    Args:
        areaID: 探险区域ID (1=火山小道, 2=青海波市, 3=名胜区, 4=大浪海滩)
        planID: 方案ID (1/2/3 对应不同时长和消耗)
        cardIDs: 卡牌ID列表
        explorerID: 探险器ID
    """
    url = r'/town/adventure/setout'
    
    @coroutine
    def run(self):
        areaID = self.input.get('areaID', None)
        planID = self.input.get('planID', 1)
        cardIDs = self.input.get('cardIDs', [])
        explorerID = self.input.get('explorerID', 0)
        
        # Lua table 可能被序列化为 dict {1: dbid, 2: dbid}，需要取 values
        if isinstance(cardIDs, dict):
            cardIDs = list(cardIDs.values())
        
        if areaID is None:
            raise ClientError('areaID required')
        
        # 获取探险配置 (csv.town.adventure)
        if not hasattr(csv, 'town') or not hasattr(csv.town, 'adventure'):
            raise ClientError('adventure config not found')
        
        # 查找对应区域的探险配置
        adventureCfg = None
        for cfgId in csv.town.adventure:
            cfg = csv.town.adventure[cfgId]
            if getattr(cfg, 'areaType', 0) == areaID:
                adventureCfg = cfg
                break
        
        if adventureCfg is None:
            raise ClientError('area config not found')
        
        # 获取方案配置
        planIdx = max(1, min(3, planID))  # 限制 1-3
        timeCost = getattr(adventureCfg, 'timeCost%d' % planIdx, 3600)
        actionCost = getattr(adventureCfg, 'actionCost%d' % planIdx, 10)  # 甜点消耗
        energyCost = getattr(adventureCfg, 'energyCost%d' % planIdx, 5)   # 精力消耗
        
        # 计算技能效果（用于减免消耗）
        skillEffects = calculateExplorationSkillEffects(self.game, cardIDs, explorerID, areaID)
        
        # 应用时间缩短效果
        timeReduce = skillEffects.get('timeReduce', 0)
        if timeReduce > 0:
            timeCost = int(timeCost * (100 - timeReduce) / 100)
        
        # 应用甜点消耗减少效果
        dessertReduce = skillEffects.get('dessertReduce', 0)
        if dessertReduce > 0:
            actionCost = max(0, actionCost - int(dessertReduce))
        
        # 遗迹祝福 - 探险消耗甜点减少 (type=9)
        if self.game.town:
            from game.object.game.town_lottery import ObjectTownRelicBuff
            buffCfg = ObjectTownRelicBuff.consumeBuff(self.game, 9)
            if buffCfg:
                param = getattr(buffCfg, 'param', 0)
                if param > 0:
                    # param=0.1 表示减少10%
                    baseCost = getattr(adventureCfg, 'actionCost%d' % planIdx, 10)
                    relicReduce = int(baseCost * param)
                    oldCost = actionCost
                    actionCost = max(0, actionCost - relicReduce)
                    logger.info('[RelicBuff] adventure setout: type=9 triggered, param=%s reduce=%s cost=%s->%s', param, relicReduce, oldCost, actionCost)
            else:
                logger.info('[RelicBuff] adventure setout: type=9 no buff available')
        
        # 应用精灵精力消耗减少效果
        energyReduceSkill = skillEffects.get('energyReduce', 0)
        if energyReduceSkill > 0:
            energyCost = max(0, energyCost - energyReduceSkill)
        
        # 扣除甜点消耗
        if actionCost > 0:
            cost = ObjectCostAux(self.game, {TownCoinType.TIANDIAN: actionCost})
            if not cost.isEnough():
                raise ClientError(ErrDefs.costNotEnough)
            cost.cost(src='town_adventure_setout')
        
        # 扣除精灵精力，并转换卡牌ID为 unit CSV ID
        townCards = self.game.town.cards or {}
        unitCsvIDs = []  # 前端显示用的 unit CSV ID
        cardDbIDs = []   # 数据库ID，用于后续恢复卡牌状态
        
        now = nowtime_t()
        for cardDbId in cardIDs:
            if not cardDbId:
                continue
            cardData = townCards.get(cardDbId, {})
            curEnergy = cardData.get('energy', 100)
            newEnergy = max(0, curEnergy - energyCost)
            cardData['energy'] = newEnergy
            cardData['status'] = TownCardState.ADVENTURE
            # 确保必要字段存在
            maxEnergy = getCardMaxEnergy(self.game, cardDbId)
            cardData['max_energy'] = maxEnergy
            if cardData.get('energy_refresh_time') is None:
                cardData['energy_refresh_time'] = now
            townCards[cardDbId] = cardData
            
            # 获取 card 的 unit CSV ID（用于前端显示）
            card = self.game.cards.getCard(cardDbId)
            if card:
                cardCsvId = card.card_id
                cardCfg = csv.cards[cardCsvId]
                unitCsvIDs.append(cardCfg.unitID)
            cardDbIDs.append(cardDbId)
        
        self.game.town.cards = townCards
        
        now = nowtime_t()
        
        # 初始化探险数据
        adventure = dict(self.game.town.adventure or {})
        areas = adventure.get('areas', {})
        missions = adventure.get('missions', {})
        
        if areaID not in areas:
            areas[areaID] = {'stage': 1, 'points': 0}
        
        # 获取配置ID（用于前端显示奖励）
        cfgId = 0
        areaStage = areas.get(areaID, {}).get('stage', 1)
        for cid in csv.town.adventure:
            cfg = csv.town.adventure[cid]
            if getattr(cfg, 'areaType', 0) == areaID:
                # 检查阶段是否匹配
                stageRange = getattr(cfg, 'stage', [0, 999])
                if stageRange[0] <= areaStage < stageRange[1]:
                    cfgId = cid
                    break
        
        if cfgId == 0:
            logger.warning('TownAdventureSetout: no matching adventure config for areaID=%s stage=%s', areaID, areaStage)
        
        # 创建任务数据（前端期望的结构）
        # 注意：normal_rewards、explore_value 等字段前端从 CSV 读取，无需存储
        # 确保数组字段不为 None（Go 端要求数组类型）
        missionData = {
            'area_id': int(areaID),
            'plan_id': int(planID),
            'cfg_id': int(cfgId),  # 0 表示未找到配置
            'card_ids': unitCsvIDs if unitCsvIDs else [],      # unit CSV ID，前端显示用
            'card_db_ids': cardDbIDs if cardDbIDs else [],    # 数据库ID，后端恢复卡牌状态用
            'explorer_id': int(explorerID) if explorerID else 0,
            'start_time': float(now),
            'end_time': float(now + timeCost),
        }
        
        logger.info('TownAdventureSetout: missionData=%s', missionData)
        
        # 存储任务到 missions[areaID]（前端从这里读取）
        missions[areaID] = missionData
        
        adventure['areas'] = areas
        adventure['missions'] = missions
        self.game.town.adventure = adventure
        
        # 验证数据（调试用）
        self.game.town.validateAdventureData()
        
        logger.info('TownAdventureSetout: areaID=%s planID=%s cardIDs=%s explorerID=%s timeCost=%s skillEffects=%s', 
                    areaID, planID, cardIDs, explorerID, timeCost, skillEffects)
        
        self.write({'view': {}})


class TownAdventureDone(RequestHandlerTask):
    """探险完成
    前端调用: gGameApp:requestServer("/town/adventure/done", areaIDs)
    
    Args:
        areaIDs: 要完成的区域ID列表
    """
    url = r'/town/adventure/done'
    
    @coroutine
    def run(self):
        areaIDs = self.input.get('areaIDs', [])
        
        if not areaIDs:
            raise ClientError('areaIDs required')
        
        adventure = dict(self.game.town.adventure or {})
        areas = adventure.get('areas', {})
        missions = adventure.get('missions', {})
        
        now = nowtime_t()
        totalAward = {}  # 所有区域奖励合计，用于实际发放
        awardByArea = {}  # 按区域分开的基础奖励，用于前端展示
        extraAwardByArea = {}  # 按区域分开的额外奖励（来自CSV extraNormalRewards）
        randomAwardByArea = {}  # 按区域分开的随机奖励
        completedAreas = []
        completedAreaTypes = []  # 记录完成的区域类型，用于更新任务
        
        for areaID in areaIDs:
            # 检查任务是否存在
            if areaID not in missions:
                continue
            
            missionData = missions[areaID]
            endTime = missionData.get('end_time', 0)
            
            # 检查任务是否完成
            if now < endTime:
                continue
            
            # 任务已完成，从 CSV 获取奖励配置
            cfgId = missionData.get('cfg_id')
            planId = missionData.get('plan_id', 1)
            
            # 使用项目标准方式读取 CSV（不能用 .get()）
            adventureCfg = None
            if cfgId and cfgId in csv.town.adventure:
                adventureCfg = csv.town.adventure[cfgId]
            
            if adventureCfg:
                # 从 CSV 获取奖励和探索值
                normalRewards = getattr(adventureCfg, 'normalRewards%d' % planId, {}) or {}
                extraNormalRewards = getattr(adventureCfg, 'extraNormalRewards%d' % planId, {}) or {}
                exploreValue = getattr(adventureCfg, 'exploreValue%d' % planId, 0)
                
                # 计算技能效果（用于增加掉落数量）
                cardDbIDs = missionData.get('card_db_ids', [])
                explorerId = missionData.get('explorer_id', 0)
                skillEffects = calculateExplorationSkillEffects(self.game, cardDbIDs, explorerId, areaID)
                awardAdd = skillEffects.get('awardAdd', 0)
                
                # 计算普通奖励（应用技能加成）
                # awardAdd 是整数百分比，如 20 表示 20%
                awardMultiplier = 1 + awardAdd / 100.0 if awardAdd > 0 else 1
                
                areaAward = {}
                for itemKey, count in normalRewards.items():
                    finalCount = int(count * awardMultiplier)
                    totalAward[itemKey] = totalAward.get(itemKey, 0) + finalCount
                    areaAward[itemKey] = areaAward.get(itemKey, 0) + finalCount
                
                # 额外奖励直接从 CSV 读取（extraNormalRewards）
                areaExtraAward = {}
                for itemKey, count in extraNormalRewards.items():
                    finalCount = int(count * awardMultiplier)
                    totalAward[itemKey] = totalAward.get(itemKey, 0) + finalCount
                    areaExtraAward[itemKey] = areaExtraAward.get(itemKey, 0) + finalCount
                
                # 随机奖励（randomRewards）
                areaRandomAward = {}
                randomRewards = getattr(adventureCfg, 'randomRewards%d' % planId, {}) or {}
                currentPoints = areas.get(areaID, {}).get('points', 0) + exploreValue
                for belongId, drawCount in randomRewards.items():
                    randomItems = self._rollRandomAward(int(belongId), currentPoints, int(drawCount))
                    for itemKey, count in randomItems.items():
                        finalCount = int(count * awardMultiplier)
                        totalAward[itemKey] = totalAward.get(itemKey, 0) + finalCount
                        areaRandomAward[itemKey] = areaRandomAward.get(itemKey, 0) + finalCount
                
                # 记录区域类型
                areaType = getattr(adventureCfg, 'areaType', 0)
                
                # 特殊掉落（adventure_award_drop.csv 保底奖励，不受技能加成）
                if areaType:
                    dropAward = self._checkSpecialDrop(areaType)
                    for itemKey, dropCount in dropAward.items():
                        totalAward[itemKey] = totalAward.get(itemKey, 0) + dropCount
                        areaRandomAward[itemKey] = areaRandomAward.get(itemKey, 0) + dropCount
                
                awardByArea[areaID] = areaAward
                extraAwardByArea[areaID] = areaExtraAward
                randomAwardByArea[areaID] = areaRandomAward
                
                if areaType:
                    completedAreaTypes.append(areaType)
            else:
                exploreValue = 0
                awardByArea[areaID] = {}
                extraAwardByArea[areaID] = {}
                randomAwardByArea[areaID] = {}
            
            # 增加探索值并检查阶段升级
            if areaID not in areas:
                areas[areaID] = {'stage': 1, 'points': 0}
            areaData = areas[areaID]
            areaData['points'] = areaData.get('points', 0) + exploreValue
            
            # 检查是否可以升级阶段
            self._checkStageUp(areaData)
            
            areas[areaID] = areaData
            
            # 更新卡牌状态为空闲（使用 card_db_ids）
            missionCardDbIDs = missionData.get('card_db_ids', [])
            townCards = dict(self.game.town.cards or {})
            for cardDbId in missionCardDbIDs:
                if cardDbId and cardDbId in townCards:
                    cardData = dict(townCards[cardDbId])
                    cardData['status'] = TownCardState.IDLE
                    cardData['energy_refresh_time'] = now
                    townCards[cardDbId] = cardData
            self.game.town.cards = townCards
            
            completedAreas.append(areaID)
            # 移除已完成的任务
            del missions[areaID]
        
        adventure['areas'] = areas
        adventure['missions'] = missions
        self.game.town.adventure = adventure
        
        # 更新探险任务进度
        if completedAreaTypes:
            self._updateAdventureTaskProgress(completedAreaTypes, areas)
        
        # 发放奖励
        if totalAward:
            gain = ObjectGainAux(self.game, totalAward)
            gain.gain(src='town_adventure_done')
        
        logger.info('TownAdventureDone: areaIDs=%s completedAreas=%s totalAward=%s', 
                    areaIDs, completedAreas, totalAward)
        
        # 前端期望格式: view.award[areaId], view.extra_award[areaId]
        # 合并 extraAward 和 randomAward 到 extra_award
        mergedExtraAward = {}
        for areaID in completedAreas:
            mergedExtraAward[areaID] = {}
            for itemKey, count in extraAwardByArea.get(areaID, {}).items():
                mergedExtraAward[areaID][itemKey] = mergedExtraAward[areaID].get(itemKey, 0) + count
            for itemKey, count in randomAwardByArea.get(areaID, {}).items():
                mergedExtraAward[areaID][itemKey] = mergedExtraAward[areaID].get(itemKey, 0) + count
        
        self.write({'view': {'award': awardByArea, 'extra_award': mergedExtraAward}})
    
    def _checkStageUp(self, areaData):
        """检查并升级探索阶段"""
        currentStage = areaData.get('stage', 1)
        currentPoints = areaData.get('points', 0)
        
        # 从 adventure_stage.csv 获取下一阶段需要的探索值
        if hasattr(csv, 'town') and hasattr(csv.town, 'adventure_stage'):
            for stageId in csv.town.adventure_stage:
                stageCfg = csv.town.adventure_stage[stageId]
                if getattr(stageCfg, 'stage', 0) == currentStage + 1:
                    needPoints = getattr(stageCfg, 'explorationPoint', 0)
                    if currentPoints >= needPoints:
                        areaData['stage'] = currentStage + 1
                        # 递归检查是否可以继续升级
                        self._checkStageUp(areaData)
                    break
    
    def _rollRandomAward(self, belongId, currentPoints, drawCount):
        """根据 randomBelongID 抽取随机奖励
        
        使用 ObjectTownAdventureAward 类（参考 ObjectDrawRandomItem 模式）
        
        Args:
            belongId: adventure_award.csv 中的 randomBelongID
            currentPoints: 当前探索点数，用于判断是否满足 needExplorationPoint
            drawCount: 抽取次数
        
        Returns:
            dict: {itemKey: count}
        """
        from game.object.game.town_lottery import ObjectTownAdventureAward
        return ObjectTownAdventureAward.getRandomItems(self.game, belongId, currentPoints, drawCount)
    
    def _checkSpecialDrop(self, areaType):
        """检查特殊掉落（adventure_award_drop.csv 保底机制）
        
        使用 ObjectTownAdventureAwardDrop 类（参考 ObjectDrawCardRandom 模式）
        
        Args:
            areaType: 区域类型 (1-4)
        
        Returns:
            dict: {itemKey: count}
        """
        from game.object.game.town_lottery import ObjectTownAdventureAwardDrop
        
        # 获取当前探险次数
        adventure = self.game.town.adventure or {}
        # 注意：get() 在 key 存在但值为 None 时会返回 None，需要用 or {} 处理
        dropInfo = adventure.get('drop_info') or {}
        drawTimes = dropInfo.get('count', 0) + 1
        
        # 更新探险次数
        adventure = dict(adventure)
        # 确保 drop_info 是字典（处理 None 值）
        adventure['drop_info'] = dict(adventure.get('drop_info') or {})
        adventure['drop_info']['count'] = drawTimes
        self.game.town.adventure = adventure
        
        # 使用标准抽奖类
        result = ObjectTownAdventureAwardDrop.getRandomItems(
            self.game, 'town_adventure1', drawTimes, areaType
        )
        
        if result:
            logger.info('TownSpecialDrop: drawTimes=%s areaType=%s awards=%s', drawTimes, areaType, result)
        
        return result or {}
    
    def _updateAdventureTaskProgress(self, completedAreaTypes, areas):
        """更新探险任务进度
        
        Args:
            completedAreaTypes: 完成的区域类型列表
            areas: 区域数据 {areaID: {stage, points}}
        """
        tasks = dict(self.game.town.tasks or {})
        areaTaskValue = tasks.get('area_task_value', {})
        stamp = tasks.get('stamp', {})
        
        # 统计每个区域类型的完成次数
        for areaType in completedAreaTypes:
            if areaType not in areaTaskValue:
                areaTaskValue[areaType] = {}
            # taskType=1 表示探险次数
            areaTaskValue[areaType][1] = areaTaskValue[areaType].get(1, 0) + 1
        
        # 更新区域阶段（taskType=2）
        for areaID, areaData in areas.items():
            # 根据 areaID 找到对应的 areaType
            if hasattr(csv, 'town') and hasattr(csv.town, 'adventure_area'):
                if areaID in csv.town.adventure_area:
                    areaCfg = csv.town.adventure_area[areaID]
                    areaType = getattr(areaCfg, 'areaType', 0)
                    if areaType:
                        if areaType not in areaTaskValue:
                            areaTaskValue[areaType] = {}
                        currentStage = areaData.get('stage', 1)
                        # taskType=2 记录当前阶段
                        areaTaskValue[areaType][2] = max(areaTaskValue[areaType].get(2, 0), currentStage)
        
        # 检查任务完成状态并更新 stamp
        if hasattr(csv, 'town') and hasattr(csv.town, 'adventure_task'):
            for taskId in csv.town.adventure_task:
                taskCfg = csv.town.adventure_task[taskId]
                areaType = getattr(taskCfg, 'areaType', 0)
                taskType = getattr(taskCfg, 'taskType', 0)
                targetArg = getattr(taskCfg, 'targetArg', 0)
                
                if not areaType or not taskType:
                    continue
                
                # 已领取的任务不再检查
                if stamp.get(taskId, 2) == 0:
                    continue
                
                currentValue = areaTaskValue.get(areaType, {}).get(taskType, 0)
                if currentValue >= targetArg:
                    stamp[taskId] = 1  # 可领取
        
        tasks['area_task_value'] = areaTaskValue
        tasks['stamp'] = stamp
        self.game.town.tasks = tasks


class TownAdventureRecall(RequestHandlerTask):
    """召回探险
    前端调用: gGameApp:requestServer("/town/adventure/recall", areaID)
    """
    url = r'/town/adventure/recall'
    
    @coroutine
    def run(self):
        areaID = self.input.get('areaID', None)
        
        if areaID is None:
            raise ClientError('areaID required')
        
        now = nowtime_t()
        
        adventure = dict(self.game.town.adventure or {})
        missions = adventure.get('missions', {})
        
        missionData = missions.get(areaID, {})
        if not missionData:
            raise ClientError('no mission in this area')
        
        # 更新卡牌状态为空闲（使用 card_db_ids）
        cardDbIDs = missionData.get('card_db_ids', [])
        cards = dict(self.game.town.cards or {})
        for cardDbId in cardDbIDs:
            if cardDbId and cardDbId in cards:
                cardData = dict(cards[cardDbId])
                cardData['status'] = TownCardState.IDLE
                cardData['energy_refresh_time'] = now
                cards[cardDbId] = cardData
        self.game.town.cards = cards
        
        # 删除任务
        del missions[areaID]
        adventure['missions'] = missions
        self.game.town.adventure = adventure
        
        logger.info('TownAdventureRecall: areaID=%s', areaID)
        
        self.write({'view': {}})


class TownAdventureTaskAward(RequestHandlerTask):
    """领取探险任务奖励
    前端调用: gGameApp:requestServer("/town/adventure/task/award", ...)
    
    任务类型:
        taskBelong=1: 探险次数任务（taskType=1 探险次数）
        taskBelong=2: 阶段达成任务（taskType=2 达到阶段）
    """
    url = r'/town/adventure/task/award'
    
    @coroutine
    def run(self):
        csvID = self.input.get('csvID', None)
        
        if csvID is None:
            raise ClientError('csvID required')
        
        # 获取任务配置
        if not hasattr(csv, 'town') or not hasattr(csv.town, 'adventure_task'):
            raise ClientError('config not found')
        
        if csvID not in csv.town.adventure_task:
            raise ClientError('task not found')
        
        taskCfg = csv.town.adventure_task[csvID]
        areaType = getattr(taskCfg, 'areaType', 0)
        taskType = getattr(taskCfg, 'taskType', 0)
        targetArg = getattr(taskCfg, 'targetArg', 0)
        awards = getattr(taskCfg, 'awards', {}) or {}
        
        # 获取任务进度数据
        tasks = dict(self.game.town.tasks or {})
        areaTaskValue = tasks.get('area_task_value', {})
        stamp = tasks.get('stamp', {})
        
        # 检查任务是否可领取
        if stamp.get(csvID, 2) == 0:
            raise ClientError('task already claimed')
        
        if stamp.get(csvID, 2) != 1:
            # 检查是否完成
            currentValue = areaTaskValue.get(areaType, {}).get(taskType, 0)
            if currentValue < targetArg:
                raise ClientError('task not completed')
        
        # 发放奖励
        if awards:
            gain = ObjectGainAux(self.game, awards)
            gain.gain(src='town_adventure_task_award')
        
        # 标记已领取
        stamp[csvID] = 0
        tasks['stamp'] = stamp
        self.game.town.tasks = tasks
        
        logger.info('TownAdventureTaskAward: csvID=%s awards=%s', csvID, awards)
        
        # 返回奖励给前端展示
        self.write({'view': {'award': awards}})


class TownExplorerSkillUpgrade(RequestHandlerTask):
    """探险器家园技能升级
    前端调用: gGameApp:requestServer("/town/explorer/skill/upgrade", ..., explorerID)
    
    探险器技能解锁条件：探险器等级(advance) >= skill.needAdvance
    技能等级存储在 role.explorers[id].town_skill_level
    """
    url = r'/town/explorer/skill/upgrade'
    
    @coroutine
    def run(self):
        explorerID = self.input.get('explorerID', None)
        
        if explorerID is None:
            raise ClientError('explorerID required')
        
        # 获取探险器配置
        if not hasattr(csv, 'explorer') or not hasattr(csv.explorer, 'explorer'):
            raise ClientError('config not found')
        
        if explorerID not in csv.explorer.explorer:
            raise ClientError('explorer config not found')
        explorerCfg = csv.explorer.explorer[explorerID]
        
        # 获取探险器的家园技能ID
        townSkillID = getattr(explorerCfg, 'townSkill', 0)
        if not townSkillID:
            raise ClientError('explorer has no town skill')
        
        # 获取玩家的探险器数据
        explorers = self.game.role.explorers or {}
        explorerData = explorers.get(explorerID, {})
        
        # 获取探险器当前等级（advance）
        explorerAdvance = explorerData.get('advance', 0)
        
        # 获取当前技能等级
        currentSkillLevel = explorerData.get('town_skill_level', 0)
        
        # 查找技能配置
        if not hasattr(csv, 'town') or not hasattr(csv.town, 'skill'):
            raise ClientError('skill config not found')
        
        # 查找当前等级和下一等级的技能配置
        currentSkillCfg = None
        nextSkillCfg = None
        
        for skillCfgId in csv.town.skill:
            skillCfg = csv.town.skill[skillCfgId]
            skill = getattr(skillCfg, 'skill', 0)
            level = getattr(skillCfg, 'level', 0)
            
            if skill == townSkillID:
                if level == currentSkillLevel:
                    currentSkillCfg = skillCfg
                elif level == currentSkillLevel + 1:
                    nextSkillCfg = skillCfg
        
        # 检查是否可以升级
        if currentSkillLevel == 0:
            # 技能未解锁，查找1级技能配置
            for skillCfgId in csv.town.skill:
                skillCfg = csv.town.skill[skillCfgId]
                skill = getattr(skillCfg, 'skill', 0)
                level = getattr(skillCfg, 'level', 0)
                if skill == townSkillID and level == 1:
                    nextSkillCfg = skillCfg
                    break
            
            if not nextSkillCfg:
                raise ClientError('skill config not found')
            
            # 检查解锁条件
            needAdvance = getattr(nextSkillCfg, 'needAdvance', 0)
            if explorerAdvance < needAdvance:
                raise ClientError('explorer advance not enough, need %d' % needAdvance)
        else:
            # 技能已解锁，升级到下一级
            if not nextSkillCfg:
                raise ClientError('already max level')
        
        # 扣除消耗
        cost = getattr(nextSkillCfg, 'cost', {})
        if cost:
            costAux = ObjectCostAux(self.game, cost)
            if not costAux.isEnough():
                raise ClientError(ErrDefs.costNotEnough)
            costAux.cost(src='town_explorer_skill_upgrade')
        
        # 升级技能
        newSkillLevel = currentSkillLevel + 1
        explorerData['town_skill_level'] = newSkillLevel
        explorers[explorerID] = explorerData
        self.game.role.explorers = explorers
        
        logger.info('TownExplorerSkillUpgrade: explorerID=%s skillLevel=%s->%s', 
                    explorerID, currentSkillLevel, newSkillLevel)
        
        self.write({'view': {}})


# ============================================================================
# 许愿池系统
# 前端 URL: /game/town/wish/xxx
# ============================================================================
class TownWishChoose(RequestHandlerTask):
    """选择许愿池
    前端调用: gGameApp:requestServer("/game/town/wish/choose", ...)
    """
    url = r'/game/town/wish/choose'
    
    @coroutine
    def run(self):
        wishID = self.input.get('wishID', None)
        
        if wishID is None:
            raise ClientError('wishID required')
        
        wish = dict(self.game.town.wish or {})  # 创建副本，确保赋值时触发脏标记
        wish['wish_id'] = wishID
        self.game.town.wish = wish
        
        logger.info('TownWishChoose: wishID=%s', wishID)
        
        # 依赖框架自动同步 town 数据（已通过 dict 副本触发脏标记）
        self.write({'view': {}})


class TownWishMake(RequestHandlerTask):
    """许愿
    前端调用: gGameApp:requestServerCustom("/game/town/wish/make"):params(id):wait(showOver):onResponse(...)
    """
    url = r'/game/town/wish/make'
    
    @coroutine
    def run(self):
        wishID = self.input.get('wishID')
        
        if wishID is None:
            raise ClientError('wishID required')
        
        # 获取许愿配置
        if not hasattr(csv, 'town') or not hasattr(csv.town, 'wish_box'):
            raise ClientError('config not found')
        
        if wishID not in csv.town.wish_box:
            raise ClientError('wish config not found')
        cfg = csv.town.wish_box[wishID]
        
        wish = dict(self.game.town.wish or {})  # 创建副本，确保赋值时触发脏标记
        wish_times = wish.get('wish_times', 0)
        current_wish_id = wish.get('wish_id', 0)
        days = getattr(cfg, 'days', 1)
        
        # 检查是否选择了这个愿望
        if current_wish_id != wishID:
            raise ClientError('wish not selected')
        
        # 检查是否已完成许愿
        if wish_times >= days:
            raise ClientError('wish already completed')
        
        # 检查今天是否已许愿（每天只能许愿一次）
        daily_wish_times = self.game.dailyRecord.town_wish_times or 0
        if daily_wish_times > 0:
            raise ClientError('already wished today')
        
        # 检查消耗
        cost_data = getattr(cfg, 'cost', {})
        if cost_data:
            cost = ObjectCostAux(self.game, cost_data)
            if not cost.isEnough():
                raise ClientError(ErrDefs.costNotEnough)
            cost.cost(src='town_wish_make')
        
        # 发放每次许愿的随机奖励 (wishAward 包含 libs)
        wish_award = getattr(cfg, 'wishAward', {})
        if wish_award:
            gain = ObjectGainAux(self.game, wish_award)
            gain.gain(src='town_wish_make')
        
        # 更新许愿次数（当前愿望进度）
        wish_times += 1
        wish['wish_times'] = wish_times
        
        # 更新累计总许愿天数（用于建筑升级解锁条件）
        total = wish.get('total', 0) + 1
        wish['total'] = total
        
        # 更新今日许愿次数
        self.game.dailyRecord.town_wish_times = daily_wish_times + 1
        
        # 随机触发惊喜小事件
        event = 0  # 0表示无事件
        event_award = {}
        
        if hasattr(csv.town, 'wish_event'):
            # 筛选可用事件（lotterType 1-3 是许愿时触发的事件）
            available_events = []
            for event_id in csv.town.wish_event:
                event_cfg = csv.town.wish_event[event_id]
                lotter_type = getattr(event_cfg, 'lotterType', 0)
                if lotter_type in (1, 2, 3):
                    weight = getattr(event_cfg, 'weight', 0)
                    if weight > 0:
                        available_events.append((event_id, event_cfg, weight))
            
            # 按权重随机选择（有一定概率不触发）
            if available_events:
                total_weight = sum(e[2] for e in available_events)
                # 50%概率触发事件
                if random.randint(1, 100) <= 50:
                    rnd = random.randint(1, total_weight)
                    for event_id, event_cfg, weight in available_events:
                        rnd -= weight
                        if rnd <= 0:
                            event = event_id
                            # 获取事件奖励
                            param1 = getattr(event_cfg, 'param1', {})
                            if param1:
                                event_award = dict(param1)
                                gain = ObjectGainAux(self.game, param1)
                                gain.gain(src='town_wish_event')
                            
                            # eventType 3: 进度加成，额外增加 wish_times 和 total
                            event_type = getattr(event_cfg, 'eventType', 0)
                            if event_type == 3:
                                bonus = random.randint(1, 2)  # 额外1-2天进度
                                wish_times += bonus
                                wish['wish_times'] = wish_times
                                # 累计天数也要加
                                wish['total'] = wish.get('total', 0) + bonus
                            break
        
        # 检查是否完成许愿（达到days天数）
        final_award = event_award
        
        self.game.town.wish = wish
        
        logger.info('TownWishMake: wishID=%s wish_times=%s total=%s event=%s', wishID, wish_times, wish.get('total', 0), event)
        
        # 依赖框架自动同步 town 数据（已通过 dict 副本触发脏标记）
        self.write({'view': {'event': event, 'award': final_award}})


class TownWishAward(RequestHandlerTask):
    """领取许愿奖励
    前端调用: gGameApp:requestServerCustom("/game/town/wish/award"):params(id):doit(...)
    """
    url = r'/game/town/wish/award'
    
    @coroutine
    def run(self):
        wishID = self.input.get('wishID')
        
        if wishID is None:
            raise ClientError('wishID required')
        
        # 获取许愿配置
        if not hasattr(csv, 'town') or not hasattr(csv.town, 'wish_box'):
            raise ClientError('config not found')
        
        if wishID not in csv.town.wish_box:
            raise ClientError('wish config not found')
        cfg = csv.town.wish_box[wishID]
        
        wish = dict(self.game.town.wish or {})  # 创建副本，确保赋值时触发脏标记
        wish_times = wish.get('wish_times', 0)
        current_wish_id = wish.get('wish_id', 0)
        days = getattr(cfg, 'days', 1)
        
        # 检查是否是当前许愿
        if current_wish_id != wishID:
            raise ClientError('wish not match')
        
        # 检查是否完成许愿
        if wish_times < days:
            raise ClientError('wish not completed')
        
        # 发放固定奖励
        awards = getattr(cfg, 'awards', {})
        if awards:
            gain = ObjectGainAux(self.game, awards)
            gain.gain(src='town_wish_award')
        
        # 随机触发愿望奖券（lotterType 21 是领取时触发的）
        lucky_event = 0
        if hasattr(csv.town, 'wish_event'):
            available_events = []
            for event_id in csv.town.wish_event:
                event_cfg = csv.town.wish_event[event_id]
                lotter_type = getattr(event_cfg, 'lotterType', 0)
                if lotter_type == 21:
                    weight = getattr(event_cfg, 'weight', 0)
                    if weight > 0:
                        available_events.append((event_id, event_cfg, weight))
            
            # 30%概率触发愿望奖券
            if available_events and random.randint(1, 100) <= 30:
                total_weight = sum(e[2] for e in available_events)
                rnd = random.randint(1, total_weight)
                for event_id, event_cfg, weight in available_events:
                    rnd -= weight
                    if rnd <= 0:
                        lucky_event = event_id
                        break
        
        # 设置愿望奖券到 role.town
        role_town = self.game.role.town or {}
        role_town['wish_lucky_event'] = lucky_event
        self.game.role.town = role_town
        
        # 重置许愿状态
        wish['wish_id'] = 0
        wish['wish_times'] = 0
        self.game.town.wish = wish
        
        # 设置延迟（部分愿望领取后有准备时间）
        delay = getattr(cfg, 'delay', 0)
        if delay > 0:
            wish_delay = wish.get('wish_delay', {})
            wish_delay[wishID] = nowtime_t() + delay * 3600  # 整数 key
            wish['wish_delay'] = wish_delay
            self.game.town.wish = wish
        
        logger.info('TownWishAward: wishID=%s awards=%s lucky_event=%s', wishID, awards, lucky_event)
        
        # 返回奖励数据给前端显示
        # 注意：前端 gGameUI:showGainDisplay(tb, ...) 期望直接的奖励数据
        # model 同步通过框架的 sync 机制自动处理
        self.write(dict(awards) if awards else {})


class TownWishLuckyAward(RequestHandlerTask):
    """领取愿望奖券奖励
    前端调用: gGameApp:requestServer("/game/town/wish/lucky/award", ...)
    """
    url = r'/game/town/wish/lucky/award'
    
    @coroutine
    def run(self):
        role_town = self.game.role.town or {}
        lucky_event = role_town.get('wish_lucky_event', 0)
        
        if not lucky_event:
            raise ClientError('no lucky event')
        
        # 获取事件配置
        if not hasattr(csv.town, 'wish_event') or lucky_event not in csv.town.wish_event:
            raise ClientError('event config not found')
        
        event_cfg = csv.town.wish_event[lucky_event]
        
        # 发放奖励
        param1 = getattr(event_cfg, 'param1', {})
        if param1:
            gain = ObjectGainAux(self.game, param1)
            gain.gain(src='town_wish_lucky_award')
        
        # 清除愿望奖券
        role_town['wish_lucky_event'] = 0
        self.game.role.town = role_town
        
        logger.info('TownWishLuckyAward: event=%s award=%s', lucky_event, param1)
        
        # 返回奖励数据（前端读取 tb.view）
        self.write({'view': dict(param1) if param1 else {}})


# ============================================================================
# 派对系统（跨服模式）
# 前端 URL: /game/town/party/xxx
# ============================================================================

from game.object.game.cross_town_party import ObjectCrossTownPartyGlobal

def _get_role_party_info(role):
    """获取角色的派对信息（用于加入房间时存储）"""
    from game.server import Server
    return {
        'name': role.name,
        'figure': role.figure,
        'logo': getattr(role, 'logo', 0),
        'frame': getattr(role, 'frame', 0),
        'level': role.level,
        'game_key': Server.Singleton.key,  # 服务器key（跨服显示用）
    }






class TownPartyGet(RequestHandlerTask):
    """获取派对信息
    前端调用: gGameApp:requestServer("/game/town/party/get", ...)
    返回当前开放的派对房间列表
    注意：party.role_info.rooms 只存储玩家自己加入的房间，不是所有开放的房间！
    """
    url = r'/game/town/party/get'
    
    @coroutine
    def run(self):
        # 获取派对活动状态（由 match 服务分配）
        partyRound = ObjectCrossTownPartyGlobal.getRound()
        self.game.role.cross_town_party_round = partyRound
        
        # 获取现有的 party 数据（保持玩家自己加入的房间）
        party = dict(self.game.town.party or {})
        role_info = party.get('role_info') or {'rooms': [], 'invites': {}}
        
        # 确保 role_info 结构正确
        if 'rooms' not in role_info:
            role_info['rooms'] = []
        if 'invites' not in role_info:
            role_info['invites'] = {}
        
        # 如果活动开启，清理过期的房间
        if ObjectCrossTownPartyGlobal.isOpen():
            now = nowtime_t()
            valid_rooms = []
            for room in role_info.get('rooms') or []:
                party_id = room.get('party_id')
                create_time = room.get('create_time', 0)
                
                # 检查房间是否过期
                if party_id and party_id in csv.town.party:
                    party_time = csv.town.party[party_id].time * 60
                    if now - create_time <= party_time:
                        valid_rooms.append(room)
                        logger.info('TownPartyGet: valid room uid=%s', room.get('room_uid'))
                    else:
                        logger.info('TownPartyGet: expired room uid=%s', room.get('room_uid'))
            role_info['rooms'] = valid_rooms
        else:
            # 活动未开启，清空房间列表
            role_info['rooms'] = []
        
        # 更新 town.party
        party['role_info'] = role_info
        self.game.town.party = party
        
        logger.info('TownPartyGet: round=%s my_rooms=%d', partyRound, len(role_info['rooms']))
        
        self.write({'view': {}})


class TownPartyRoomCreate(RequestHandlerTask):
    """创建派对房间
    前端调用: gGameApp:requestServer("/game/town/party/room/create", ...)
    """
    url = r'/game/town/party/room/create'
    
    @coroutine
    def run(self):
        # 检查活动是否开启
        if not ObjectCrossTownPartyGlobal.isOpen():
            raise ClientError('party not open')
        
        partyCsvID = self.input.get('partyCsvID', None)
        partyName = self.input.get('partyName', '')
        
        if partyCsvID is None:
            raise ClientError('partyCsvID required')
        
        # 检查派对配置
        if partyCsvID not in csv.town.party:
            raise ClientError('invalid partyCsvID')
        party_cfg = csv.town.party[partyCsvID]
        
        # 检查创建次数限制（先检查是否需要每日重置）
        base_cfg = csv.town.party_base[1]
        town_home = self.game.role.town_home or {}
        create_count = town_home.get('party_create_count', 0)
        if base_cfg and create_count >= base_cfg.createCount:
            raise ClientError('party create limit reached')
        
        # 检查消耗
        cost = party_cfg.cost
        if cost:
            costAux = ObjectCostAux(self.game, cost)
            if not costAux.isEnough():
                raise ClientError('party cost not enough')
            costAux.cost(src='town_party_create')
        
        # 获取角色信息
        role_id = str(self.game.role.id)
        
        # 创建房间（跨服模式）
        from game.server import Server
        room = yield ObjectCrossTownPartyGlobal.createRoom(
            self.game.role.id,
            Server.Singleton.key,
            self.game.role.name,
            partyCsvID,
            partyName,
            self.game.role.figure,
            self.game.role.logo,
            self.game.role.frame,
            self.game.role.level,
            self.game.role.vip_level
        )
        if room is None:
            raise ClientError('cross server error')
        
        # 更新创建次数
        town_home['party_create_count'] = create_count + 1
        town_home['party_last_join_time'] = nowtime_t()
        self.game.role.town_home = town_home
        
        # 发放准备奖励
        prepareAwards = party_cfg.prepareAwards
        if prepareAwards:
            gain = ObjectGainAux(self.game, prepareAwards)
            gain.gain(src='town_party_prepare')
        
        # 构建奖励数据给前端显示（使用 showPrepareAwards）
        showAwards = getattr(party_cfg, 'showPrepareAwards', None) or prepareAwards or {}
        awardList = []
        if showAwards:
            for key, num in showAwards.iteritems():
                awardList.append({'key': key, 'num': num})
        
        # 更新 town.party_room（设置当前房间）
        self.game.town.party_room = room
        
        # 更新 town.party.role_info.rooms（加入新创建的房间，让前端知道有房间可进）
        room_uid = room.get('room_uid') or room.get('RoomUid')
        room_id = room.get('room_id') or room.get('RoomId')
        create_time = room.get('create_time') or room.get('CreateTime', 0)
        party_role_num = room.get('party_role_num') or room.get('PartyRoleNum') or 1
        
        party = self.game.town.party or {}
        role_info = party.get('role_info') or {'rooms': [], 'invites': {}}
        rooms = role_info.get('rooms') or []
        # 添加新房间到列表
        rooms.append({
            'room_uid': room_uid,
            'room_id': room_id,
            'party_id': partyCsvID,
            'party_name': partyName,
            'party_role_num': party_role_num,
            'create_time': create_time,
        })
        role_info['rooms'] = rooms
        party['role_info'] = role_info
        self.game.town.party = party
        
        logger.info('TownPartyRoomCreate: room_uid=%s room_id=%s partyCsvID=%s', 
                    room_uid, room_id, partyCsvID)
        
        self.write({'view': {'room_id': room_id, 'room_uid': room_uid, 'award': awardList}})


class TownPartyRoomJoin(RequestHandlerTask):
    """加入派对房间
    前端调用: gGameApp:requestServer("/game/town/party/room/join", ...)
    """
    url = r'/game/town/party/room/join'
    
    @coroutine
    def run(self):
        # 检查活动是否开启
        if not ObjectCrossTownPartyGlobal.isOpen():
            raise ClientError('party not open')
        
        # 支持 room_id（6位房间号）或 roomUID
        roomID = self.input.get('roomID', None)
        roomUID = self.input.get('roomUID', None)
        
        if roomID is None and roomUID is None:
            raise ClientError('roomID or roomUID required')
        
        # 从跨服查找房间
        if roomUID is not None:
            room = yield ObjectCrossTownPartyGlobal.getRoom(roomUID)
        else:
            room = yield ObjectCrossTownPartyGlobal.findRoomByRoomId(str(roomID))
        
        if not room:
            raise ClientError(ErrDefs.partyRoomNotExist)
        
        # 获取房间信息（兼容不同字段名）
        room_uid = room.get('room_uid') or room.get('RoomUid')
        party_id = room.get('party_id') or room.get('PartyId')
        party_roles = room.get('party_roles') or room.get('PartyRoles') or {}
        create_time = room.get('create_time') or room.get('CreateTime', 0)
        
        # 检查派对配置
        if party_id not in csv.town.party:
            raise ClientError(ErrDefs.partyRoomNotExist)
        party_cfg = csv.town.party[party_id]
        
        # 检查派对是否过期
        party_time = party_cfg.time * 60
        if nowtime_t() - create_time > party_time:
            raise ClientError(ErrDefs.partyRoomFinish)
        
        # 检查是否是房主或之前已加入过的房间（不扣次数）
        owner_id = room.get('owner_id') or room.get('OwnerID')
        recover_history = room.get('recover_history') or room.get('RecoverHistory') or {}
        my_role_id = self.game.role.id
        is_owner = (owner_id == my_role_id)
        is_rejoining = (my_role_id in recover_history)  # RecoverHistory 有记录说明之前加入过
        is_already_in_room = (my_role_id in party_roles)  # 已在房间中
        
        # 只有新加入的非房主玩家才检查次数和扣次数
        need_count_check = not (is_owner or is_rejoining or is_already_in_room)
        
        # 检查人数限制（已在房间中的不检查）
        if not is_already_in_room and len(party_roles) >= party_cfg.number:
            raise ClientError(ErrDefs.partyRoomNotJoin)
        
        # 检查加入次数限制（房主返回、重新加入、已在房间的不检查）
        base_cfg = csv.town.party_base[1]
        town_home = self.game.role.town_home or {}       
        join_count = town_home.get('party_join_count', 0)
        if need_count_check and base_cfg and join_count >= base_cfg.joinCount:
            raise ClientError('party join limit reached')
        
        # 检查加入 CD（房主返回、重新加入、已在房间的不检查）
        last_join_time = town_home.get('party_last_join_time', 0)
        if need_count_check and base_cfg and nowtime_t() - last_join_time < base_cfg.joinCD * 60:
            raise ClientError('party join cd not finished')
        
        # 加入房间（跨服模式）
        from game.server import Server
        room = yield ObjectCrossTownPartyGlobal.joinRoom(
            room_uid,
            self.game.role.id,
            self.game.role.name,
            Server.Singleton.key,
            self.game.role.figure,
            self.game.role.logo,
            self.game.role.frame,
            self.game.role.level,
            self.game.role.vip_level
        )
        if room is None:
            raise ClientError(ErrDefs.partyRoomNotJoin)
        
        # 只有新加入的非房主玩家才扣次数和发奖励
        if need_count_check:
            # 更新加入次数
            town_home['party_join_count'] = join_count + 1
            town_home['party_last_join_time'] = nowtime_t()
            self.game.role.town_home = town_home
        
        # 发放参与奖励（只有新加入的非房主玩家才发）
        joinAwards = party_cfg.joinAwards if need_count_check else None
        if joinAwards:
            gain = ObjectGainAux(self.game, joinAwards)
            gain.gain(src='town_party_join')
        
        # 修正当前玩家的 recover_used（Go端不知道配额，需要Python端计算）
        # recover_used 为0/1语义：0=未用完配额，1=已用完配额
        join_party_roles = room.get('party_roles') or room.get('PartyRoles') or {}
        my_role_id = self.game.role.id
        if my_role_id in join_party_roles:
            my_role_info = join_party_roles[my_role_id]
            my_recover_cards = my_role_info.get('recover_cards') or my_role_info.get('RecoverCards') or []
            max_pokemon = getattr(party_cfg, 'pokemon', 4)
            is_quota_full = 1 if len(my_recover_cards) >= max_pokemon else 0
            my_role_info['recover_used'] = is_quota_full
        
        # 更新 town.party_room
        self.game.town.party_room = room
        
        # 更新 town.party.role_info.rooms（让前端知道玩家已在房间中）
        new_room_uid = room.get('room_uid') or room.get('RoomUid')
        new_room_id = room.get('room_id') or room.get('RoomId')
        new_create_time = room.get('create_time') or room.get('CreateTime', 0)
        new_party_role_num = room.get('party_role_num') or room.get('PartyRoleNum') or 1
        new_party_name = room.get('party_name') or room.get('PartyName', '')
        
        party = self.game.town.party or {}
        role_info = party.get('role_info') or {'rooms': [], 'invites': {}}
        rooms = role_info.get('rooms') or []
        # 检查房间是否已在列表中，如果在则更新，否则添加
        found = False
        for r in rooms:
            if r.get('room_uid') == new_room_uid:
                r['party_role_num'] = new_party_role_num
                found = True
                break
        if not found:
            rooms.append({
                'room_uid': new_room_uid,
                'room_id': new_room_id,
                'party_id': party_id,
                'party_name': new_party_name,
                'party_role_num': new_party_role_num,
                'create_time': new_create_time,
            })
        role_info['rooms'] = rooms
        party['role_info'] = role_info
        self.game.town.party = party
        
        # 构建奖励数据给前端显示（直接使用 joinAwards）
        awardList = []
        if joinAwards:
            for key, num in joinAwards.iteritems():
                awardList.append({'key': key, 'num': num})
        
        logger.info('TownPartyRoomJoin: room_uid=%s role_id=%s', 
                    new_room_uid, str(self.game.role.id))
        
        # 前端需要 room_uid 和 award
        self.write({'view': {
            'room_uid': new_room_uid,
            'award': awardList,
        }})


class TownPartyRoomList(RequestHandlerTask):
    """获取派对房间列表
    前端调用: gGameApp:requestServer("/game/town/party/room/list", ...)
    """
    url = r'/game/town/party/room/list'
    
    @coroutine
    def run(self):
        # 检查活动是否开启
        if not ObjectCrossTownPartyGlobal.isOpen():
            self.write({'view': []})
            return
        
        size = self.input.get('size', 20)
        
        # 跨服模式
        crossRooms = yield ObjectCrossTownPartyGlobal.listRooms(size)
        rooms = []
        for room in (crossRooms or []):
            # 使用 Go 端计算好的 party_role_num
            party_role_num = room.get('party_role_num') or room.get('PartyRoleNum') or 0
            rooms.append({
                'room_uid': room.get('room_uid') or room.get('RoomUid'),
                'room_id': room.get('room_id') or room.get('RoomId'),
                'party_id': room.get('party_id') or room.get('PartyId'),
                'party_name': room.get('party_name') or room.get('PartyName'),
                'party_role_num': party_role_num,
                'create_time': room.get('create_time') or room.get('CreateTime', 0),
            })
        
        logger.info('TownPartyRoomList: size=%s count=%d', size, len(rooms))
        
        # 前端直接使用 tb.view 作为房间列表
        self.write({'view': rooms})


class TownPartyRoomFind(RequestHandlerTask):
    """查找派对房间
    前端调用: gGameApp:requestServer("/game/town/party/room/find", ...)
    根据房间号查找并加入房间
    """
    url = r'/game/town/party/room/find'
    
    @coroutine
    def run(self):
        # 检查活动是否开启
        if not ObjectCrossTownPartyGlobal.isOpen():
            raise ClientError('party not open')
        
        # 前端传 roomUID（实际是6位房间号字符串）
        roomUID = self.input.get('roomUID', None)
        
        if not roomUID:
            raise ClientError('roomUID required')
        
        # 从跨服查找房间
        room = yield ObjectCrossTownPartyGlobal.findRoomByRoomId(str(roomUID))
        if not room:
            raise ClientError(ErrDefs.partyRoomNotExist)
        
        # 获取房间信息（兼容不同字段名）
        room_uid = room.get('room_uid') or room.get('RoomUid')
        room_id = room.get('room_id') or room.get('RoomId')
        party_id = room.get('party_id') or room.get('PartyId')
        party_name = room.get('party_name') or room.get('PartyName')
        party_role_num = room.get('party_role_num') or room.get('PartyRoleNum') or 0
        create_time = room.get('create_time') or room.get('CreateTime', 0)
        
        # 检查派对配置
        if party_id not in csv.town.party:
            raise ClientError(ErrDefs.partyRoomNotExist)
        party_cfg = csv.town.party[party_id]
        
        # 检查派对是否过期
        party_time = party_cfg.time * 60
        if nowtime_t() - create_time > party_time:
            raise ClientError(ErrDefs.partyRoomFinish)
        
        # 返回房间列表格式（前端 tb.view 作为列表展示）
        result = [{
            'room_uid': room_uid,
            'room_id': room_id,
            'party_id': party_id,
            'party_name': party_name,
            'create_time': create_time,
            'party_role_num': party_role_num,
        }]
        
        logger.info('TownPartyRoomFind: roomUID=%s found room_uid=%s', roomUID, room_uid)
        
        self.write({'view': result})


class TownPartyRoomGet(RequestHandlerTask):
    """获取派对房间信息
    前端调用: gGameApp:requestServer("/game/town/party/room/get", ...)
    获取房间的完整数据（party_roles, danmus等）
    """
    url = r'/game/town/party/room/get'
    
    @coroutine
    def run(self):
        # 检查活动是否开启
        if not ObjectCrossTownPartyGlobal.isOpen():
            # 不更新 party_room，避免触发前端 listener 报错
            self.write({'view': {}, 'closed': True})
            return
        
        roomID = self.input.get('roomID', None)  # room_id 字符串
        
        if roomID is None:
            raise ClientError('roomID required')
        
        # 跨服模式：通过6位房间号查找
        room = yield ObjectCrossTownPartyGlobal.findRoomByRoomId(str(roomID))
        if room is None:
            # 不更新 party_room，避免触发前端 listener 报错
            logger.info('TownPartyRoomGet: roomID=%s not found', roomID)
            raise ClientError('partyRoomNotExist')
        
        # 获取房间信息（兼容不同字段名）
        party_id = room.get('party_id') or room.get('PartyId')
        create_time = room.get('create_time') or room.get('CreateTime', 0)
        party_roles = room.get('party_roles') or room.get('PartyRoles') or {}
        danmus = room.get('danmus') or room.get('Danmus') or []
        
        # 检查派对配置
        if party_id not in csv.town.party:
            raise ClientError('partyRoomNotExist')
        party_cfg = csv.town.party[party_id]
        party_time = party_cfg.time * 60
        if nowtime_t() - create_time > party_time:
            # 派对已过期
            logger.info('TownPartyRoomGet: roomID=%s expired', roomID)
            raise ClientError('partyRoomFinish')
        
        # 检查当前玩家是否在房间中
        my_role_id = self.game.role.id
        logger.info('TownPartyRoomGet: my_role_id=%r in_room=%s', 
                    my_role_id, my_role_id in party_roles)
        
        # 如果玩家不在房间中，自动重新加入房间（而不是返回 not_in_room）
        # 场景：玩家创建/加入房间后临时离开，现在想重新进入
        if my_role_id not in party_roles:
            logger.info('TownPartyRoomGet: player not in room, auto rejoining')
            from game.server import Server
            room_uid = room.get('room_uid') or room.get('RoomUid')
            
            # 自动重新加入房间
            rejoined_room = yield ObjectCrossTownPartyGlobal.joinRoom(
                room_uid,
                self.game.role.id,
                self.game.role.name,
                Server.Singleton.key,
                self.game.role.figure,
                self.game.role.logo,
                self.game.role.frame,
                self.game.role.level,
                self.game.role.vip_level
            )
            
            if rejoined_room is None:
                # 重新加入失败（房间已满等原因）
                logger.info('TownPartyRoomGet: auto rejoin failed')
                # 清理前端的房间数据
                party = dict(self.game.town.party or {})
                role_info = party.get('role_info') or {'rooms': [], 'invites': {}}
                rooms = list(role_info.get('rooms') or [])
                new_rooms = [r for r in rooms if str(r.get('room_id')) != str(roomID)]
                if len(new_rooms) != len(rooms):
                    role_info['rooms'] = new_rooms
                    party['role_info'] = role_info
                    self.game.town.party = party
                self.write({'view': {'not_in_room': True}})
                return
            
            # 重新加入成功，使用新的房间数据
            room = rejoined_room
            party_roles = room.get('party_roles') or room.get('PartyRoles') or {}
            danmus = room.get('danmus') or room.get('Danmus') or []
            logger.info('TownPartyRoomGet: auto rejoin success')
        
        # 修正当前玩家的 recover_used（Go端不知道配额，需要Python端计算）
        # recover_used 为0/1语义：0=未用完配额，1=已用完配额
        if my_role_id in party_roles:
            my_role_info = party_roles[my_role_id]
            my_recover_cards = my_role_info.get('recover_cards') or my_role_info.get('RecoverCards') or []
            max_pokemon = getattr(party_cfg, 'pokemon', 4)
            is_quota_full = 1 if len(my_recover_cards) >= max_pokemon else 0
            my_role_info['recover_used'] = is_quota_full
            logger.info('TownPartyRoomGet: fixed recover_used for my_role, cards=%d max=%d full=%d',
                        len(my_recover_cards), max_pokemon, is_quota_full)
        
        # 更新 town.party_room（触发前端同步）
        self.game.town.party_room = room
        
        logger.info('TownPartyRoomGet: roomID=%s players=%d danmus=%d', 
                    roomID, len(party_roles), len(danmus))
        
        self.write({'view': {}})


class TownPartyRoomQifen(RequestHandlerTask):
    """派对气氛互动
    前端调用: gGameApp:requestServer("/game/town/party/room/qifen", ...)
    发送气氛特效、表情或弹幕
    """
    url = r'/game/town/party/room/qifen'
    
    @coroutine
    def run(self):
        # 检查活动是否开启
        if not ObjectCrossTownPartyGlobal.isOpen():
            raise ClientError('party not open')
        
        roomID = self.input.get('roomID', None)  # room_id 字符串
        qifenID = self.input.get('qifenID', None)  # 气氛ID（对应 party_play.csv）
        content = self.input.get('content', '')  # 弹幕内容（type=3时使用）
        
        if roomID is None:
            raise ClientError('roomID required')
        if qifenID is None:
            raise ClientError('qifenID required')
        
        # 检查气氛配置
        play_cfg = csv.town.party_play[qifenID] if qifenID in csv.town.party_play else None
        if not play_cfg:
            raise ClientError('invalid qifenID')
        
        role_id = str(self.game.role.id)
        
        # 跨服模式
        # 获取当前房间的 room_uid
        party_room = self.game.town.party_room
        if not party_room:
            raise ClientError(ErrDefs.partyRoomNotExist)
        room_uid = party_room['room_uid'] if 'room_uid' in party_room else (party_room['RoomUid'] if 'RoomUid' in party_room else None)
        if not room_uid:
            raise ClientError(ErrDefs.partyRoomNotExist)
        
        # 发送气氛到跨服
        yield ObjectCrossTownPartyGlobal.sendQifen(
            room_uid,
            self.game.role.id,
            self.game.role.name,
            qifenID,
            content
        )
        
        logger.info('TownPartyRoomQifen: roomID=%s role=%s qifenID=%s', 
                    roomID, role_id, qifenID)
        
        # 勋章计数：派对互动次数 (targetType=12, medalID=1091)
        self.game.medal.incrementMedalCounter(1091)
        
        self.write({'view': {}})


class TownPartyRoomChange(RequestHandlerTask):
    """更换/离开派对房间
    前端调用: gGameApp:requestServer("/game/town/party/room/change", ...)
    """
    url = r'/game/town/party/room/change'
    
    @coroutine
    def run(self):
        from game.server import Server
        # 活动关闭时也允许离开房间
        oldRoomID = self.input.get('oldRoomID', None)  # room_id 字符串
        newRoomID = self.input.get('newRoomID', None)  # 新房间 room_id（可选，用于切换房间）
        
        role_id = str(self.game.role.id)
        
        # 如果有旧房间，先离开（跨服模式）
        if oldRoomID:
            party_room = self.game.town.party_room
            if party_room:
                room_id = party_room['room_id'] if 'room_id' in party_room else (party_room['RoomId'] if 'RoomId' in party_room else None)
                if room_id == oldRoomID:
                    room_uid = party_room['room_uid'] if 'room_uid' in party_room else (party_room['RoomUid'] if 'RoomUid' in party_room else None)
                    if room_uid:
                        yield ObjectCrossTownPartyGlobal.leaveRoom(room_uid, self.game.role.id)
        
        logger.info('TownPartyRoomChange: role=%s left room=%s', role_id, oldRoomID)
        
        # 如果指定了新房间，自动加入
        if newRoomID:
            # 先查找房间
            room = yield ObjectCrossTownPartyGlobal.findRoom(newRoomID)
            if room:
                room_uid = room.get('room_uid') or room.get('RoomUid')
                # 加入房间
                new_room = yield ObjectCrossTownPartyGlobal.joinRoom(
                    room_uid, 
                    self.game.role.id,
                    self.game.role.name,
                    Server.Singleton.key,
                    self.game.role.figure,
                    self.game.role.logo,
                    self.game.role.frame,
                    self.game.role.level,
                    self.game.role.vip_level
                )
                if new_room:
                    # 规范化字段名
                    normalized = {
                        'room_uid': new_room.get('room_uid') or new_room.get('RoomUid'),
                        'room_id': new_room.get('room_id') or new_room.get('RoomId'),
                        'party_id': new_room.get('party_id') or new_room.get('PartyId'),
                        'party_name': new_room.get('party_name') or new_room.get('PartyName'),
                        'party_roles': new_room.get('party_roles') or new_room.get('PartyRoles') or {},
                        'party_role_num': new_room.get('party_role_num') or new_room.get('PartyRoleNum') or 0,
                        'danmus': new_room.get('danmus') or new_room.get('Danmus') or [],
                        'danmu_index': new_room.get('danmu_index') or new_room.get('DanmuIndex', 0),
                        'create_time': new_room.get('create_time') or new_room.get('CreateTime', 0),
                        'status': new_room.get('status') or new_room.get('Status', 0),
                        'owner_id': new_room.get('owner_id') or new_room.get('OwnerId'),
                        'owner_key': new_room.get('owner_key') or new_room.get('OwnerKey'),
                    }
                    self.game.town.party_room = normalized
                    logger.info('TownPartyRoomChange: role=%s joined room=%s party_role_num=%d', 
                                role_id, newRoomID, normalized['party_role_num'])
                    self.write({'view': {'left': True, 'joined': True, 'room': normalized}})
                    return
        
        self.write({'view': {'left': True}})


class TownPartyRoomInvite(RequestHandlerTask):
    """邀请好友参加派对
    前端调用: gGameApp:requestServer("/game/town/party/room/invite", ...)
    """
    url = r'/game/town/party/room/invite'
    
    @coroutine
    def run(self):
        from game.object.game import ObjectGame
        from game.object.game.message import ObjectMessageGlobal
        
        # 检查活动是否开启
        if not ObjectCrossTownPartyGlobal.isOpen():
            raise ClientError('party not open')
        
        roomID = self.input.get('roomID', None)  # room_id 字符串
        inviteRoleIDs = self.input.get('inviteRoleIDs', [])
        
        if roomID is None:
            raise ClientError('roomID required')
        
        # Lua table 可能被序列化为 dict，需要取 values
        if isinstance(inviteRoleIDs, dict):
            inviteRoleIDs = list(inviteRoleIDs.values())
        
        # 从跨服查找房间
        room = yield ObjectCrossTownPartyGlobal.findRoomByRoomId(str(roomID))
        if not room:
            raise ClientError(ErrDefs.partyRoomNotExist)
        
        # 获取房间信息
        room_uid = room.get('room_uid') or room.get('RoomUid', 0)
        if isinstance(room_uid, str):
            room_uid = int(room_uid) if room_uid.isdigit() else 0
        party_id = room.get('party_id') or room.get('PartyCsvId', 0)
        room_create_time = room.get('create_time') or room.get('CreateTime', 0)
        inviter_id = self.game.role.id  # ObjectId 类型
        invite_time = nowtime_t()
        
        # 构造邀请房间数据（符合 Go TownPartyInviteRoom 结构）
        inviteRoomData = {
            'room_uid': int(room_uid),
            'room_id': str(roomID),
            'party_id': int(party_id),
            'invite_time': float(invite_time),
            'room_create_time': float(room_create_time),
        }
        
        # 获取邀请者的 server key (使用 role.areaKey)
        inviter_game_key = self.game.role.areaKey or ''
        
        # 向每个被邀请的玩家推送邀请消息
        invitedCount = 0
        for toRoleID in inviteRoleIDs:
            if not toRoleID:
                continue
            
            # 检查玩家是否在线
            targetGame = ObjectGame.getByRoleID(toRoleID, safe=False)
            if targetGame:
                # 在线玩家：更新其 town.party.role_info.invites 并推送消息
                try:
                    party = dict(targetGame.town.party or {})
                    role_info = party.get('role_info') or {'rooms': [], 'invites': {}}
                    invites = dict(role_info.get('invites') or {})
                    
                    # 使用邀请者 role_id 作为 key（符合前端数据结构）
                    if inviter_id in invites:
                        # 已有该邀请者的邀请，添加新房间
                        inviterData = dict(invites[inviter_id])
                        inviteRooms = list(inviterData.get('invite_rooms') or [])
                        # 检查是否已邀请过该房间
                        roomExists = any(r.get('room_uid') == room_uid for r in inviteRooms)
                        if not roomExists:
                            inviteRooms.append(inviteRoomData)
                            inviterData['invite_rooms'] = inviteRooms
                            invites[inviter_id] = inviterData
                    else:
                        # 新邀请者 - 添加前端期望的所有字段
                        invites[inviter_id] = {
                            'invite_name': self.game.role.name,
                            'invite_level': self.game.role.level,
                            'invite_logo': self.game.role.logo,
                            'invite_frame': self.game.role.frame,
                            'invite_figure': self.game.role.figure,
                            'invite_game_key': inviter_game_key,
                            'invite_rooms': [inviteRoomData],
                        }
                    
                    role_info['invites'] = invites
                    party['role_info'] = role_info
                    targetGame.town.party = party
                    
                    # 使用 sync 推送增量更新，让前端 gGameModel.town 自动同步
                    self.pushToRole('/game/push', {
                        'sync': {
                            'upd': {
                                'town': {
                                    'party': party
                                }
                            }
                        }
                    }, toRoleID)
                    
                    invitedCount += 1
                    logger.info('TownPartyRoomInvite: sent invite to online role %s', toRoleID)
                except Exception as e:
                    logger.warning('TownPartyRoomInvite: failed to invite online role %s: %s', toRoleID, e)
            else:
                # 离线玩家：通过数据库更新其 town.party.role_info.invites
                try:
                    # 先读取玩家的 Town 数据
                    roleRet = yield self.dbcGame.call_async('DBRead', 'Role', toRoleID, False)
                    if roleRet['ret']:
                        townDbId = roleRet['model'].get('town_db_id')
                        if townDbId:
                            townRet = yield self.dbcGame.call_async('DBRead', 'Town', townDbId, False)
                            if townRet['ret']:
                                townData = townRet['model']
                                party = townData.get('party') or {}
                                role_info = party.get('role_info') or {'rooms': [], 'invites': {}}
                                invites = role_info.get('invites') or {}
                                
                                # 使用邀请者 role_id 作为 key
                                # 注意: 数据库中 key 可能是 ObjectId 或字符串，需要兼容处理
                                inviter_key = inviter_id
                                if inviter_key not in invites:
                                    inviter_key = str(inviter_id)  # 尝试字符串形式
                                
                                if inviter_key in invites:
                                    inviterData = invites[inviter_key]
                                    inviteRooms = inviterData.get('invite_rooms') or []
                                    roomExists = any(r.get('room_uid') == room_uid for r in inviteRooms)
                                    if not roomExists:
                                        inviteRooms.append(inviteRoomData)
                                        inviterData['invite_rooms'] = inviteRooms
                                else:
                                    # 新邀请者 - 添加前端期望的所有字段
                                    invites[inviter_id] = {
                                        'invite_name': self.game.role.name,
                                        'invite_level': self.game.role.level,
                                        'invite_logo': self.game.role.logo,
                                        'invite_frame': self.game.role.frame,
                                        'invite_figure': self.game.role.figure,
                                        'invite_game_key': inviter_game_key,
                                        'invite_rooms': [inviteRoomData],
                                    }
                                
                                role_info['invites'] = invites
                                party['role_info'] = role_info
                                
                                # 更新数据库
                                yield self.dbcGame.call_async('DBUpdate', 'Town', townDbId, {'party': party}, False)
                                invitedCount += 1
                                logger.info('TownPartyRoomInvite: sent invite to offline role %s', toRoleID)
                except Exception as e:
                    logger.warning('TownPartyRoomInvite: failed to invite offline role %s: %s', toRoleID, e)
        
        logger.info('TownPartyRoomInvite: roomID=%s inviteRoleIDs=%s invitedCount=%d', 
                    roomID, inviteRoleIDs, invitedCount)
        
        self.write({'view': {'invited': invitedCount}})


class TownPartyRoomFriendList(RequestHandlerTask):
    """获取可邀请的好友列表
    前端调用: gGameApp:requestServer("/game/town/party/room/friend/list", ...)
    listType: 1=好友, 2=最近联系, 3=公会成员
    """
    url = r'/game/town/party/room/friend/list'
    
    @coroutine
    def run(self):
        from game.object.game.society import ObjectSocietyGlobal
        from game.object.game.union import ObjectUnion
        
        listType = self.input.get('listType', 0)
        
        friends = []
        myRoleId = self.game.role.id
        
        if listType == 1:
            # 好友列表
            friend_ids = self.game.society.friends or []
            for friend_id in friend_ids:
                if friend_id == myRoleId:  # 排除自己
                    continue
                friend_data = ObjectSocietyGlobal.RoleCache.getValue(friend_id)
                if friend_data:
                    friends.append({
                        'role_id': friend_id,
                        'name': friend_data.get('name', ''),
                        'level': friend_data.get('level', 1),
                        'figure': friend_data.get('figure', 1),
                        'logo': friend_data.get('logo', 0),
                        'frame': friend_data.get('frame', 0),
                    })
        elif listType == 2:
            # 最近联系 - 从聊天记录中获取最近联系的玩家
            # 简化实现：返回好友列表中最近登录的
            friend_ids = self.game.society.friends or []
            for friend_id in friend_ids[:20]:  # 最多20个
                if friend_id == myRoleId:
                    continue
                friend_data = ObjectSocietyGlobal.RoleCache.getValue(friend_id)
                if friend_data:
                    friends.append({
                        'role_id': friend_id,
                        'name': friend_data.get('name', ''),
                        'level': friend_data.get('level', 1),
                        'figure': friend_data.get('figure', 1),
                        'logo': friend_data.get('logo', 0),
                        'frame': friend_data.get('frame', 0),
                    })
        elif listType == 3:
            # 公会成员列表
            union_db_id = self.game.role.union_db_id
            if union_db_id:
                union = ObjectUnion.getUnionByUnionID(union_db_id)
                if union and hasattr(union, 'members') and union.members:
                    # union.members 是字典 {roleID: {'name': ..., ...}}
                    for member_id, member_info in union.members.iteritems():
                        if member_id == myRoleId:  # 排除自己
                            continue
                        # member_info 可能是字典或简单值，需要兼容处理
                        if isinstance(member_info, dict):
                            friends.append({
                                'role_id': member_id,
                                'name': member_info.get('name', ''),
                                'level': member_info.get('level', 1),
                                'figure': member_info.get('figure', 1),
                                'logo': member_info.get('logo', 0),
                                'frame': member_info.get('frame', 0),
                            })
                        else:
                            # 如果 member_info 不是字典，尝试从 RoleCache 获取
                            member_data = ObjectSocietyGlobal.RoleCache.getValue(member_id)
                            if member_data:
                                friends.append({
                                    'role_id': member_id,
                                    'name': member_data.get('name', ''),
                                    'level': member_data.get('level', 1),
                                    'figure': member_data.get('figure', 1),
                                    'logo': member_data.get('logo', 0),
                                    'frame': member_data.get('frame', 0),
                                })
        
        logger.info('TownPartyRoomFriendList: listType=%s count=%d', listType, len(friends))
        
        # 前端期望 tb.view.roles
        self.write({'view': {'roles': friends}})


class TownPartyCardRecover(RequestHandlerTask):
    """派对卡牌能量恢复
    前端调用: gGameApp:requestServer("/game/town/party/card_recover", ...)
    根据派对品质恢复卡牌能量
    """
    url = r'/game/town/party/card_recover'
    
    @coroutine
    def run(self):
        # 检查活动是否开启
        if not ObjectCrossTownPartyGlobal.isOpen():
            raise ClientError('party not open')
        
        roomID = self.input.get('roomID', None)  # room_id 字符串
        cardIDs = self.input.get('cardIDs', [])  # 要恢复能量的卡牌ID列表
        
        if roomID is None:
            raise ClientError('roomID required')
        if not cardIDs:
            raise ClientError('cardIDs required')
        
        # 从跨服查找房间
        room = yield ObjectCrossTownPartyGlobal.findRoomByRoomId(str(roomID))
        if not room:
            raise ClientError(ErrDefs.partyRoomNotExist)
        
        role_id = self.game.role.id  # 使用原始 ObjectId，与 Go 端 document.ID key 匹配
        
        # 获取房间角色信息（兼容字段名）
        party_roles = room.get('party_roles') or room.get('PartyRoles') or {}
        
        # 检查玩家是否在房间中
        if role_id not in party_roles:
            raise ClientError(ErrDefs.partyRoomRoleNotExist)
        
        # 获取派对配置
        party_id = room.get('party_id') or room.get('PartyId')
        if party_id not in csv.town.party:
            raise ClientError(ErrDefs.partyRoomNotExist)
        party_cfg = csv.town.party[party_id]
        
        # 获取已恢复的卡牌列表
        role_party_info = party_roles[role_id]
        existing_recover_cards = role_party_info.get('recover_cards') or role_party_info.get('RecoverCards') or []
        
        # 计算剩余配额：pokemon 是最大可恢复卡牌数
        max_pokemon = getattr(party_cfg, 'pokemon', 4)
        remaining_quota = max_pokemon - len(existing_recover_cards)
        
        # 检查是否超出配额
        if remaining_quota <= 0:
            raise ClientError(ErrDefs.partyRecoverUsed)
        
        if len(cardIDs) > remaining_quota:
            raise ClientError(ErrDefs.partyRecoverUsed)
        
        # 检查卡牌是否已经恢复过
        existing_set = set(str(c) for c in existing_recover_cards)
        for card_id in cardIDs:
            if str(card_id) in existing_set:
                raise ClientError(ErrDefs.partyRecoverUsed)
        
        # 解析能量恢复值
        energy_recover = party_cfg.energyRecover
        recover_value = 0
        is_percent = False
        if isinstance(energy_recover, str) and energy_recover.endswith('%'):
            recover_value = int(energy_recover[:-1])
            is_percent = True
        else:
            recover_value = int(energy_recover) if energy_recover else 20
        
        # 恢复卡牌能量
        cards = self.game.town.cards or {}
        for card_id in cardIDs:
            card_key = str(card_id)
            if card_key in cards:
                card_data = cards[card_key]
                max_energy = card_data.get('max_energy', 100)
                current_energy = card_data.get('energy', 0)
                if is_percent:
                    add_energy = int(max_energy * recover_value / 100)
                else:
                    add_energy = recover_value
                card_data['energy'] = min(current_energy + add_energy, max_energy)
        self.game.town.cards = cards
        
        # 追加新恢复的卡牌到列表
        new_recover_cards = list(existing_recover_cards) + list(cardIDs)
        # recover_used 保持0/1语义：0=未用完配额，1=已用完配额（前端依赖此判断隐藏按钮）
        is_quota_full = 1 if len(new_recover_cards) >= max_pokemon else 0
        role_party_info['recover_used'] = is_quota_full
        role_party_info['recover_cards'] = new_recover_cards
        
        # 持久化到跨服数据库
        room_uid = room.get('room_uid') or room.get('RoomUid')
        yield ObjectCrossTownPartyGlobal.updateRecoverUsed(room_uid, role_id, is_quota_full, new_recover_cards)
        
        # 更新本地 party_room 数据，让前端能读取到最新的 recover_cards
        local_party_room = self.game.town.party_room
        if local_party_room:
            local_party_roles = local_party_room.get('party_roles') or local_party_room.get('PartyRoles') or {}
            if role_id in local_party_roles:
                local_party_roles[role_id]['recover_used'] = is_quota_full
                local_party_roles[role_id]['recover_cards'] = new_recover_cards
                self.game.town.party_room = local_party_room
        
        logger.info('TownPartyCardRecover: roomID=%s role=%s cards=%s recover=%s remaining=%s quota_full=%s', 
                    roomID, role_id, cardIDs, energy_recover, max_pokemon - len(new_recover_cards), is_quota_full)
        
        self.write({'view': {}})


class TownPartyDartEnd(RequestHandlerTask):
    """派对飞镖游戏结束
    前端调用: gGameApp:requestServerCustom("/game/town/party/dart/end"):params(roomID, scoreTab):delay(delay):doit(...)
    提交飞镖游戏得分并获取奖励
    """
    url = r'/game/town/party/dart/end'
    
    @coroutine
    def run(self):
        # 检查活动是否开启
        if not ObjectCrossTownPartyGlobal.isOpen():
            raise ClientError('party not open')
        
        roomID = self.input.get('roomID', None)  # room_id 字符串
        score = self.input.get('score', [])  # 飞镖得分数组（每轮得分）
        
        if roomID is None:
            raise ClientError('roomID required')
        
        # 从跨服查找房间
        room = yield ObjectCrossTownPartyGlobal.findRoomByRoomId(str(roomID))
        if not room:
            raise ClientError(ErrDefs.partyRoomNotExist)
        
        role_id = self.game.role.id  # 使用原始 ObjectId，与 Go 端 document.ID key 匹配
        
        # 获取房间角色信息（兼容字段名）
        party_roles = room.get('party_roles') or room.get('PartyRoles') or {}
        
        # 检查玩家是否在房间中
        if role_id not in party_roles:
            raise ClientError(ErrDefs.partyRoomRoleNotExist)
        
        role_party_info = party_roles[role_id]
        dart_info = role_party_info.get('dart', {})
        
        # 检查飞镖游戏次数限制
        base_cfg = csv.town.party_base[1]
        if base_cfg:
            max_game_count = base_cfg.dartGameCount
            if dart_info.get('game_count', 0) >= max_game_count:
                raise ClientError('party dart limit reached')
        
        # 计算总分（score 是数组，每个元素是一轮的得分）
        total_score = sum(score) if isinstance(score, list) else score
        
        # 根据得分计算评价（与目标分数的偏差）
        target_score = base_cfg.dartTarget if base_cfg else 100
        off_score = abs(target_score - total_score)  # 与目标分数的偏差
        
        # 查找对应的评价等级
        evaluate = 0
        reward = {}
        for dart_id in csv.town.party_dart:
            dart_cfg = csv.town.party_dart[dart_id]
            grade = dart_cfg.grade  # [min, max]
            if grade and len(grade) >= 2:
                if grade[0] <= off_score < grade[1]:
                    evaluate = dart_id
                    reward = dart_cfg.reward or {}
                    break
        
        # 计算新的飞镖数据
        new_dart_use_num = dart_info.get('dart_use_num', 0) + 1
        new_game_count = dart_info.get('game_count', 0) + 1
        
        # 获取房间 UID
        room_uid = room.get('room_uid') or room.get('RoomUid')
        
        # 调用跨服更新飞镖数据
        yield ObjectCrossTownPartyGlobal.endDart(
            room_uid, role_id, new_dart_use_num, new_game_count, total_score, evaluate
        )
        
        # 更新本地 party_room 数据，让前端能读取到最新的飞镖数据
        local_party_room = self.game.town.party_room
        if local_party_room:
            local_party_roles = local_party_room.get('party_roles') or local_party_room.get('PartyRoles') or {}
            if role_id in local_party_roles:
                local_dart = local_party_roles[role_id].get('dart') or {}
                local_dart['dart_use_num'] = new_dart_use_num
                local_dart['game_count'] = new_game_count
                local_dart['score'] = total_score
                local_dart['last_time'] = nowtime_t()
                # 只更新更高的评价
                if evaluate > local_dart.get('evaluate', 0):
                    local_dart['evaluate'] = evaluate
                local_party_roles[role_id]['dart'] = local_dart
                self.game.town.party_room = local_party_room
        
        # 发放奖励
        if reward:
            gain = ObjectGainAux(self.game, reward)
            gain.gain(src='town_party_dart')
        
        # 更新角色飞镖记录（使用独立字段，与Go端/前端一致）
        topEvaluate = self.game.role.town_home_party_dart_top_evaluate or 0
        if evaluate > topEvaluate:
            self.game.role.town_home_party_dart_top_evaluate = evaluate
        # 勋章计数：每次获得"神准"评价(evaluate=8)都计数
        if evaluate == 8:
            self.game.role.town_home_party_dart_max_evaluate_counter = (self.game.role.town_home_party_dart_max_evaluate_counter or 0) + 1
        
        logger.info('TownPartyDartEnd: roomID=%s role=%s total_score=%s evaluate=%s dart_use_num=%s game_count=%s', 
                    roomID, role_id, total_score, evaluate, new_dart_use_num, new_game_count)
        
        # 前端期望 view 直接是奖励数据，用于 createItemsToList 显示
        # csvID/evaluate 前端根据本地分数计算
        self.write({'view': reward})


# ============================================================================
# 社交/拜访系统
# 前端 URL: /game/town/society/xxx
# ============================================================================
class TownSocietyHomeVisit(RequestHandlerTask):
    """拜访家园
    前端调用: gGameApp:requestServer("/game/town/society/home/visit", ...)
    """
    url = r'/game/town/society/home/visit'
    
    @coroutine
    def run(self):
        from game.server import Server
        from framework.csv import csv
        
        serverKey = self.input.get('serverKey', None)
        townDBID = self.input.get('townDBID', None)
        
        if townDBID is None:
            raise ClientError('townDBID required')  # 目标玩家可能没有开通家园
        
        # 如果没有传 serverKey，使用本服
        if serverKey is None:
            serverKey = Server.Singleton.key
        
        # 访问冷却检查：同一家园在 visitDelay 秒内只能访问一次（记录访问历史）
        baseCfg = csv.town.home_like_base[1]
        visitDelay = baseCfg.visitDelay  # 默认300秒
        
        # 获取上次访问记录 {townDBID: timestamp}
        visitTimes = self.game.dailyRecord.town_home_visit_times or {}
        lastVisitTime = visitTimes.get(townDBID, 0)
        now = nowtime_t()
        
        inCooldown = False
        if lastVisitTime > 0 and now - lastVisitTime < visitDelay:
            remaining = visitDelay - (now - lastVisitTime)
            logger.info('TownSocietyHomeVisit: visit cooldown, remaining=%ds', remaining)
            # 不阻止访问，但不记录访问历史（只是查看，不算正式访问）
            inCooldown = True
        else:
            # 更新访问时间
            visitTimes[townDBID] = now
            self.game.dailyRecord.town_home_visit_times = visitTimes
            
            # 勋章计数：家园拜访次数 (targetType=11, medalID=1081)
            self.game.medal.incrementMedalCounter(1081)
        
        # 本服拜访：直接从数据库读取家园数据
        if serverKey == Server.Singleton.key:
            ret = yield self.dbcGame.call_async('DBRead', 'Town', townDBID, False)
            if not ret['ret']:
                raise ClientError('town not found')
            
            townData = ret['model']
            
            # home 数据 - 确保所有必要字段有默认值
            homeData = townData.get('home') or {}
            homeData.setdefault('name', '')
            homeData.setdefault('liked', 0)
            homeData.setdefault('expand_level', 0)
            homeData.setdefault('expand_finish_time', 0)
            homeData.setdefault('awards', 0)
            homeData.setdefault('score', 0)
            homeData.setdefault('fixed_score', 0)
            homeData.setdefault('like_count', 0)
            homeData.setdefault('visit_history', [])
            
            # 记录访问历史（添加到被访问者的家园中）
            # 只有在冷却时间外才记录，防止重复刷访问
            if not inCooldown:
                visitRecord = {
                    'timestamp': nowtime_t(),
                    'game_key': self.game.role.areaKey,
                    'name': self.game.role.name,
                    'role_id': self.game.role.id,
                    'town_db_id': self.game.role.town_db_id,
                    'figure': self.game.role.figure,  # 玩家形象，用于显示
                    'like': False,  # 访问时还没点赞
                }
                visitHistory = homeData.get('visit_history') or []
                # 限制历史记录数量
                visitHistoryLimit = baseCfg.visitHistoryLimit
                if len(visitHistory) >= visitHistoryLimit:
                    visitHistory = visitHistory[-(visitHistoryLimit - 1):]
                visitHistory.append(visitRecord)
                homeData['visit_history'] = visitHistory
                
                # 更新被访问者的家园数据（记录访问历史）
                yield self.dbcGame.call_async('DBUpdate', 'Town', townDBID, {'home': homeData}, False)
            
            # buildings 数据 - 确保 HOME(2) 建筑存在
            buildingsData = townData.get('buildings') or {}
            if 2 not in buildingsData:
                buildingsData[2] = {'level': 1, 'finish_time': 0, 'idx': 2}
            
            # home_apply_layout 数据
            homeApplyLayout = townData.get('home_apply_layout') or {}
            
            # 构造访客列表（基于最近访问记录，简化实现）
            # 正式服应该是实时在线状态，这里用历史记录模拟
            friendList = []
            visitHistory = homeData.get('visit_history') or []
            for record in visitHistory[:10]:  # 最多显示10个
                friendList.append({
                    'figure': record.get('figure', 1),  # 默认形象
                    'name': record.get('name', ''),
                    'role_id': record.get('role_id'),
                    'game_key': record.get('game_key', ''),
                })
            
            logger.info('TownSocietyHomeVisit: local serverKey=%s townDBID=%s friends=%d', 
                        serverKey, townDBID, len(friendList))
            
            self.write({'view': {
                'home': homeData,
                'buildings': buildingsData,
                'home_apply_layout': homeApplyLayout,
                'friend': friendList,  # 访客列表
            }})
        else:
            # 跨服拜访家园 - 从跨服缓存获取家园数据
            from game.object.game.cross_town_party import ObjectCrossTownPartyGlobal
            
            result = yield ObjectCrossTownPartyGlobal.visitHomeByTownDbId(serverKey, townDBID)
            if not result:
                logger.warning('TownSocietyHomeVisit: cross visit data not found, serverKey=%s townDBID=%s', serverKey, townDBID)
                raise ClientError('crossVisitDataNotFound')
            
            # 解析 msgpack 序列化的家园数据
            visitData = result.get('visit_data')
            if not visitData:
                logger.warning('TownSocietyHomeVisit: visit_data is empty, serverKey=%s townDBID=%s', serverKey, townDBID)
                raise ClientError('crossVisitDataEmpty')
            
            try:
                townData = msgpack.unpackb(visitData, raw=False)
            except Exception as e:
                logger.error('TownSocietyHomeVisit: failed to unpack visit_data: %s', e)
                raise ClientError('crossVisitDataInvalid')
            
            homeData = townData.get('home') or {}
            buildingsData = townData.get('buildings') or {}
            homeApplyLayout = townData.get('home_apply_layout') or {}
            
            # 确保 HOME(2) 建筑存在
            if 2 not in buildingsData:
                buildingsData[2] = {'level': 1, 'finish_time': 0, 'idx': 2}
            
            # 确保 home 数据有默认值
            homeData.setdefault('name', '')
            homeData.setdefault('liked', result.get('home_liked', 0))
            homeData.setdefault('expand_level', 0)
            homeData.setdefault('expand_finish_time', 0)
            homeData.setdefault('awards', 0)
            homeData.setdefault('score', result.get('home_score', 0))
            homeData.setdefault('fixed_score', 0)
            homeData.setdefault('like_count', 0)
            homeData.setdefault('visit_history', [])
            
            # 添加跨服访问事件（异步同步到被访问者服务器）
            # 只有在冷却时间外才记录访问事件
            targetRoleId = result.get('role_id')
            if targetRoleId and not inCooldown:
                yield ObjectCrossTownPartyGlobal.visitAddEvent(
                    serverKey,                      # 被访问者服务器
                    targetRoleId,                   # 被访问者角色ID
                    1,                              # 事件类型：访问
                    nowtime_t(),                    # 时间戳
                    Server.Singleton.key,           # 访问者服务器
                    self.game.role.id,              # 访问者角色ID
                    self.game.role.name,            # 访问者名字
                    self.game.role.figure,          # 访问者形象
                    self.game.role.town_db_id or b'',  # 访问者家园ID
                    0                               # 评价ID（访问事件不需要）
                )
            
            # 构造空的访客列表（被访问者的访客列表不在这里显示）
            friendList = []
            
            logger.info('TownSocietyHomeVisit: cross visit serverKey=%s townDBID=%s roleId=%s name=%s', 
                        serverKey, townDBID, result.get('role_id'), result.get('name'))
            
            self.write({'view': {
                'home': homeData,
                'buildings': buildingsData,
                'home_apply_layout': homeApplyLayout,
                'friend': friendList,
            }})


class TownSocietyHomeLike(RequestHandlerTask):
    """点赞家园
    前端调用: gGameApp:requestServer("/game/town/society/home/like", ...)
    """
    url = r'/game/town/society/home/like'
    
    @coroutine
    def run(self):
        from game.server import Server
        
        serverKey = self.input.get('serverKey', None)
        roleID = self.input.get('roleID', None)
        townDBID = self.input.get('townDBID', None)
        
        if townDBID is None:
            raise ClientError('params required')
        
        # 如果没有传 serverKey，使用本服
        if serverKey is None:
            serverKey = Server.Singleton.key
        
        # 本服点赞
        if serverKey == Server.Singleton.key:
            # 检查今日是否已点赞过该玩家
            roleLiked = self.game.dailyRecord.town_home_role_liked or []
            if roleID in roleLiked:
                raise ClientError('already liked today')
            
            # 检查每周点赞次数限制
            weeklyLikes = self.game.weeklyRecord.town_home_likes or 0
            baseCfg = csv.town.home_like_base[1]
            weeklyLikeLimit = baseCfg.weeklyLikeLimit
            if weeklyLikes >= weeklyLikeLimit:
                raise ClientError('weekly like limit reached')
            
            # 读取目标家园数据
            ret = yield self.dbcGame.call_async('DBRead', 'Town', townDBID, False)
            if not ret['ret']:
                raise ClientError('town not found')
            
            townData = ret['model']
            homeData = townData.get('home') or {}
            
            # 增加点赞数
            homeData['liked'] = homeData.get('liked', 0) + 1
            homeData.setdefault('name', '')
            homeData.setdefault('expand_level', 0)
            homeData.setdefault('expand_finish_time', 0)
            homeData.setdefault('awards', 0)
            
            # 更新访问记录中的点赞标记
            visitHistory = homeData.get('visit_history') or []
            for record in visitHistory:
                if record.get('role_id') == self.game.role.id:
                    record['like'] = True
            homeData['visit_history'] = visitHistory
            
            # 更新目标家园
            yield self.dbcGame.call_async('DBUpdate', 'Town', townDBID, {'home': homeData}, False)
            
            # 记录今日已点赞
            roleLiked.append(roleID)
            self.game.dailyRecord.town_home_role_liked = roleLiked
            
            # 增加本周点赞次数
            newWeeklyLikes = weeklyLikes + 1
            self.game.weeklyRecord.town_home_likes = newWeeklyLikes
            
            # 检查是否达到新的奖励档位，标记为可领取 (1=可领取, 0=已领取)
            likeAward = self.game.weeklyRecord.town_home_like_award or {}
            for csvID in csv.town.home_like_award:
                cfg = csv.town.home_like_award[csvID]
                if csvID not in likeAward and newWeeklyLikes >= cfg.taskParam:
                    likeAward[csvID] = 1  # 可领取（前端 v==1 发光）
            self.game.weeklyRecord.town_home_like_award = likeAward
            
            logger.info('TownSocietyHomeLike: local serverKey=%s roleID=%s townDBID=%s liked=%s weeklyLikes=%s likeAward=%s', 
                        serverKey, roleID, townDBID, homeData['liked'], newWeeklyLikes, likeAward)
            
            # 不要手动返回 model.weekly_record，会覆盖前端其他字段
            # 框架会自动同步 self.game.weeklyRecord 的变化
            self.write({'view': {
                'home': homeData,
            }})
        else:
            # 跨服点赞
            from game.object.game.cross_town_party import ObjectCrossTownPartyGlobal
            
            # 检查今日是否已点赞过该玩家
            roleLiked = self.game.dailyRecord.town_home_role_liked or []
            if roleID in roleLiked:
                raise ClientError('already liked today')
            
            # 检查每周点赞次数限制
            weeklyLikes = self.game.weeklyRecord.town_home_likes or 0
            baseCfg = csv.town.home_like_base[1]
            weeklyLikeLimit = baseCfg.weeklyLikeLimit
            if weeklyLikes >= weeklyLikeLimit:
                raise ClientError('weekly like limit reached')
            
            # 从跨服缓存获取被点赞者的家园数据
            result = yield ObjectCrossTownPartyGlobal.visitHomeByTownDbId(serverKey, townDBID)
            if not result:
                raise ClientError('crossVisitDataNotFound')
            
            visitData = result.get('visit_data')
            if not visitData:
                raise ClientError('crossVisitDataEmpty')
            
            try:
                townData = msgpack.unpackb(visitData, raw=False)
            except Exception as e:
                logger.error('TownSocietyHomeLike: failed to unpack visit_data: %s', e)
                raise ClientError('crossVisitDataInvalid')
            
            homeData = townData.get('home') or {}
            # 乐观更新点赞数（实际更新会在被访问者下次进入家园时同步）
            homeData['liked'] = homeData.get('liked', 0) + 1
            
            # 添加跨服点赞事件（异步同步到被访问者服务器）
            yield ObjectCrossTownPartyGlobal.visitAddEvent(
                serverKey,                      # 被访问者服务器
                roleID,                         # 被访问者角色ID
                2,                              # 事件类型：点赞
                nowtime_t(),                    # 时间戳
                Server.Singleton.key,           # 访问者服务器
                self.game.role.id,              # 访问者角色ID
                self.game.role.name,            # 访问者名字
                self.game.role.figure,          # 访问者形象
                self.game.role.town_db_id or b'',  # 访问者家园ID
                0                               # 评价ID（点赞事件不需要）
            )
            
            # 记录今日已点赞
            roleLiked.append(roleID)
            self.game.dailyRecord.town_home_role_liked = roleLiked
            
            # 增加本周点赞次数
            newWeeklyLikes = weeklyLikes + 1
            self.game.weeklyRecord.town_home_likes = newWeeklyLikes
            
            # 检查是否达到新的奖励档位，标记为可领取 (1=可领取, 0=已领取)
            likeAward = self.game.weeklyRecord.town_home_like_award or {}
            for csvID in csv.town.home_like_award:
                cfg = csv.town.home_like_award[csvID]
                if csvID not in likeAward and newWeeklyLikes >= cfg.taskParam:
                    likeAward[csvID] = 1  # 可领取（前端 v==1 发光）
            self.game.weeklyRecord.town_home_like_award = likeAward
            
            logger.info('TownSocietyHomeLike: cross serverKey=%s roleID=%s townDBID=%s liked=%s weeklyLikes=%s likeAward=%s', 
                        serverKey, roleID, townDBID, homeData['liked'], newWeeklyLikes, likeAward)
            
            # 不要手动返回 model.weekly_record，会覆盖前端其他字段
            # 框架会自动同步 self.game.weeklyRecord 的变化
            self.write({'view': {
                'home': homeData,
            }})


class TownSocietyHomeAward(RequestHandlerTask):
    """领取家园社交奖励
    前端调用: gGameApp:requestServer("/game/town/society/home/award", ...)
    
    Args:
        awardType: 0=点赞奖励(我给别人点赞), 1=被点赞奖励(别人给我点赞)
        csvID: 点赞奖励的配置ID (awardType=0时需要)
    """
    url = r'/game/town/society/home/award'
    
    @coroutine
    def run(self):
        from game.object.game.gain import ObjectGainAux
        from framework.csv import csv
        
        awardType = self.input.get('awardType', 0)
        csvID = self.input.get('csvID', None)
        
        eff = None
        
        if awardType == 0:
            # 点赞奖励（我给别人点赞达到一定次数后领取）
            if csvID is None or csvID not in csv.town.home_like_award:
                raise ClientError('invalid csvID')
            
            cfg = csv.town.home_like_award[csvID]
            weeklyLikes = self.game.weeklyRecord.town_home_likes or 0
            
            # 检查是否达到领取条件
            if weeklyLikes < cfg.taskParam:
                raise ClientError('not enough likes')
            
            # 检查是否已领取 (1=可领取, 0=已领取)
            likeAward = self.game.weeklyRecord.town_home_like_award or {}
            if likeAward.get(csvID) == 0:
                raise ClientError('already awarded')
            
            # 发放奖励
            eff = ObjectGainAux(self.game, cfg.award)
            eff.gain(src='town_home_like_award')
            
            # 标记已领取 {csvID: 0}
            likeAward[csvID] = 0
            self.game.weeklyRecord.town_home_like_award = likeAward
            
            logger.info('TownSocietyHomeAward: awardType=0 csvID=%s weeklyLikes=%s award=%s', 
                        csvID, weeklyLikes, cfg.award)
        
        elif awardType == 1:
            # 被点赞奖励（别人给我点赞达到阈值后领取）
            # 前端逻辑：needLikedNum(累计需要) <= liked(累计被点赞数)
            # liked 是累计值，不扣除；awards 是已领取次数
            baseCfg = csv.town.home_like_base[1]
            likedAward = baseCfg.likedAward  # 奖励
            likedAwardRange = baseCfg.likedAwardRange  # 递进配置 <<10;100>;<20;50>;<30;30>;<50;20>>
            likedAwardLimit = baseCfg.likedAwardLimit  # 点赞奖励上限 (100)
            
            # 获取当前数据
            home = self.game.town.home or {}
            liked = home.get('liked', 0)  # 累计被点赞数
            awards = home.get('awards', 0)  # 已领取奖励次数
            
            # 检查是否达到奖励领取上限
            if likedAwardLimit > 0 and awards >= likedAwardLimit:
                raise ClientError('award limit reached')
            
            # 根据 awards 和 likedAwardRange 计算领取 (awards+1) 次需要的累计点赞数
            # likedAwardRange 格式: [[10, 100], [20, 50], [30, 30], [50, 20]]
            # 表示: 前100次每10点赞领一次, 第101-150次每20点赞领一次...
            # 例: awards=0 -> needLikedNum=10; awards=99 -> needLikedNum=1000; awards=100 -> needLikedNum=1020
            remainingAwards = awards
            needLikedNum = 0
            canClaim = False
            
            for item in likedAwardRange:
                likePerAward = item[0]  # 每次领取需要的点赞数
                maxCount = item[1]      # 这个阶段最多领取次数
                
                if remainingAwards >= maxCount:
                    # 已经领完这个阶段的所有奖励
                    remainingAwards -= maxCount
                    needLikedNum += likePerAward * maxCount
                else:
                    # 当前阶段，计算领取下一次需要的累计点赞数
                    needLikedNum += likePerAward * (remainingAwards + 1)
                    canClaim = True
                    break
            
            # 检查是否还能领取（已领完所有阶段）
            if not canClaim:
                raise ClientError('award limit reached')
            
            # 检查累计被点赞数是否足够
            if liked < needLikedNum:
                raise ClientError('not enough liked')
            
            # 发放奖励
            eff = ObjectGainAux(self.game, likedAward)
            eff.gain(src='town_home_liked_award')
            
            # 更新数据：只增加已领取次数，liked 是累计值不扣除
            home['awards'] = awards + 1
            self.game.town.home = home
            
            logger.info('TownSocietyHomeAward: awardType=1 liked=%s awards=%s->%s needLiked=%s', 
                        liked, awards, home['awards'], needLikedNum)
        
        # 返回奖励信息
        result = eff.result if eff else {}
        self.write({'view': {'award': result}})


class TownSocietyHomeScore(RequestHandlerTask):
    """评分家园
    前端调用: gGameApp:requestServer("/game/town/society/home/score", ...)
    
    Args:
        serverKey: 目标服务器key
        roleID: 目标玩家ID
        townDBID: 目标家园ID
        score: 评分 (1-5)
    """
    url = r'/game/town/society/home/score'
    
    @coroutine
    def run(self):
        from game.server import Server
        from framework.csv import csv
        
        serverKey = self.input.get('serverKey', None)
        roleID = self.input.get('roleID', None)
        townDBID = self.input.get('townDBID', None)
        score = self.input.get('score', 0)
        
        if townDBID is None or score <= 0:
            raise ClientError('params required')
        
        # 如果没有传 serverKey，使用本服
        if serverKey is None:
            serverKey = Server.Singleton.key
        
        # 检查评分范围 (1-5)
        score = max(1, min(5, score))
        
        # 获取配置
        baseCfg = csv.town.home_score_base[1]
        weeklyScoreTimes = baseCfg.weeklyScoreTimes  # 每周评分次数限制
        
        # 检查是否已评分过该家园
        townHomeScore = self.game.weeklyRecord.town_home_score or {}
        if townDBID in townHomeScore:
            raise ClientError('already scored this home')
        
        # 检查每周评分次数
        if len(townHomeScore) >= weeklyScoreTimes:
            raise ClientError('weekly score limit reached')
        
        # 本服评分
        if serverKey == Server.Singleton.key:
            # 读取目标家园数据
            ret = yield self.dbcGame.call_async('DBRead', 'Town', townDBID, False)
            if not ret['ret']:
                raise ClientError('town not found')
            
            townData = ret['model']
            homeData = townData.get('home') or {}
            
            # 更新评分统计
            homeData['total_score'] = homeData.get('total_score', 0) + score
            homeData['score_num'] = homeData.get('score_num', 0) + 1
            homeData.setdefault('name', '')
            homeData.setdefault('liked', 0)
            homeData.setdefault('expand_level', 0)
            homeData.setdefault('expand_finish_time', 0)
            homeData.setdefault('awards', 0)
            homeData.setdefault('score', 0)
            homeData.setdefault('fixed_score', 0)
            homeData.setdefault('like_count', 0)
            homeData.setdefault('visit_history', [])
            
            # 更新目标家园
            yield self.dbcGame.call_async('DBUpdate', 'Town', townDBID, {'home': homeData}, False)
            
            # 记录本周已评分
            townHomeScore[townDBID] = score
            self.game.weeklyRecord.town_home_score = townHomeScore
            
            logger.info('TownSocietyHomeScore: local serverKey=%s townDBID=%s score=%s total_score=%s score_num=%s', 
                        serverKey, townDBID, score, homeData['total_score'], homeData['score_num'])
        else:
            # 跨服评分
            from game.object.game.cross_town_party import ObjectCrossTownPartyGlobal
            
            # 添加跨服评价事件（异步同步到被访问者服务器）
            yield ObjectCrossTownPartyGlobal.visitAddEvent(
                serverKey,                      # 被访问者服务器
                roleID,                         # 被访问者角色ID
                3,                              # 事件类型：评价
                nowtime_t(),                    # 时间戳
                Server.Singleton.key,           # 访问者服务器
                self.game.role.id,              # 访问者角色ID
                self.game.role.name,            # 访问者名字
                self.game.role.figure,          # 访问者形象
                self.game.role.town_db_id or b'',  # 访问者家园ID
                score                           # 评价分数
            )
            
            # 记录本周已评分
            townHomeScore[townDBID] = score
            self.game.weeklyRecord.town_home_score = townHomeScore
            
            logger.info('TownSocietyHomeScore: cross serverKey=%s roleID=%s townDBID=%s score=%s', 
                        serverKey, roleID, townDBID, score)
        
        self.write({'view': {}})


class TownSocietyPlayerList(RequestHandlerTask):
    """获取玩家列表
    前端调用: gGameApp:requestServer("/game/town/society/player/list", ...)
    
    Args:
        typ: 1=好友列表, 2=推荐列表
    """
    url = r'/game/town/society/player/list'
    
    @coroutine
    def run(self):
        typ = self.input.get('typ', 1)
        
        roles = []
        
        # 前端 showTab 映射:
        # showTab=1 (本服推荐) -> typ=1
        # showTab=2 (跨服推荐) -> typ=2
        # showTab=3 (好友) -> 前端调用 /game/society/friend/search，不走这个接口
        
        if typ == 1:
            # 跨服推荐 - 调用跨服服务获取其他服务器玩家（第一个标签"跨服访问"）
            from game.object.game.cross_town_party import ObjectCrossTownPartyGlobal
            from game.server import Server
            
            crossRoles = yield ObjectCrossTownPartyGlobal.visitGetPlayerList(Server.Singleton.key, typ, 20)
            logger.info('TownSocietyPlayerList: crossRoles=%s', crossRoles)
            if crossRoles:
                for crossRole in crossRoles:
                    # 跨服返回的数据格式：{'role': {...}, 'town_home': {...}}
                    role = crossRole.get('role') or crossRole.get('Role') or {}
                    townHome = crossRole.get('town_home') or crossRole.get('TownHome') or {}
                    roles.append({
                        'id': role.get('id'),
                        'role': {
                            'id': role.get('id'),
                            'name': role.get('name', ''),
                            'level': role.get('level', 1),
                            'vip_level': role.get('vip_level', 0),
                            'logo': role.get('logo', 0),
                            'frame': role.get('frame', 0),
                            'game_key': role.get('game_key', ''),
                        },
                        'town_home': {
                            'town_db_id': townHome.get('town_db_id'),
                            'fixed': 0,
                            'score': 0,
                            'liked': 0,
                        },
                        'town_home_visit': townHome.get('town_db_id'),
                    })
            
            # 如果跨服没有返回结果，fallback 到本服玩家
            if not roles:
                from game.object.game.society import ObjectSocietyGlobal
                randomRoles = ObjectSocietyGlobal.getRandomFriends(self.game)
                for roleData in randomRoles[:40]:
                    if roleData and roleData.get('town_db_id'):
                        roles.append(self._buildRoleInfo(roleData))
                        if len(roles) >= 20:
                            break
        elif typ == 2:
            # 本服推荐 - 随机本服玩家（第二个标签"本服访问"）
            from game.object.game.society import ObjectSocietyGlobal
            randomRoles = ObjectSocietyGlobal.getRandomFriends(self.game)
            for roleData in randomRoles[:40]:  # 多取一些，因为要过滤没有家园的玩家
                if roleData and roleData.get('town_db_id'):  # 只返回有家园的玩家
                    roles.append(self._buildRoleInfo(roleData))
                    if len(roles) >= 20:
                        break
        
        logger.info('TownSocietyPlayerList: typ=%s count=%s', typ, len(roles))
        
        # 前端期望 tb.view.roles
        self.write({'view': {'roles': roles}})
    
    @coroutine
    def _getRoleInfoAsync(self, roleId):
        """异步获取玩家信息"""
        from tornado.gen import Return
        from framework.service.helper import service_key2domains, service_key, gamemerge2game
        from game.server import Server
        
        # 从数据库读取角色信息
        ret = yield self.dbcGame.call_async('DBRead', 'Role', roleId, False)
        if not ret['ret']:
            raise Return(None)
        
        roleData = ret['model']
        
        # 根据 area 计算 game_key (数据库里不存储 game_key，需要动态计算)
        area = roleData.get('area', 1)
        service, language, _ = service_key2domains(Server.Singleton.key)
        gameKey = gamemerge2game(service_key(service, area, language))
        
        # 获取家园数据库ID（用于拜访入口判断）
        townDbId = roleData.get('town_db_id', None)
        
        # 构造前端期望的数据结构
        raise Return({
            'id': roleId,
            'role': {
                'id': roleId,
                'name': roleData.get('name', ''),
                'level': roleData.get('level', 1),
                'vip_level': roleData.get('vip_level', 0),
                'logo': roleData.get('logo', 0),
                'frame': roleData.get('frame', 0),
                'game_key': gameKey,
            },
            'town_home': {
                'town_db_id': townDbId,  # 家园数据库ID，拜访入口需要
                'fixed': 0,    # 装饰分数
                'score': 0,    # 评分
                'liked': 0,    # 点赞数
            },
            'town_home_visit': townDbId,  # 兼容好友界面拜访入口判断
        })
    
    def _buildRoleInfo(self, roleData):
        """从缓存数据构造前端期望的数据结构"""
        from framework.service.helper import service_key2domains, service_key, gamemerge2game
        from game.server import Server
        
        roleId = roleData.get('id')
        townDbId = roleData.get('town_db_id', None)
        
        # RoleCache 中可能没有 area，使用默认值
        # game_key 可能已经在缓存中（如果有的话）
        gameKey = roleData.get('game_key', '')
        if not gameKey:
            area = roleData.get('area', 1)
            service, language, _ = service_key2domains(Server.Singleton.key)
            gameKey = gamemerge2game(service_key(service, area, language))
        
        return {
            'id': roleId,
            'role': {
                'id': roleId,
                'name': roleData.get('name', ''),
                'level': roleData.get('level', 1),
                'vip_level': roleData.get('vip_level', 0),
                'logo': roleData.get('logo', 0),
                'frame': roleData.get('frame', 0),
                'game_key': gameKey,
            },
            'town_home': {
                'town_db_id': townDbId,
                'fixed': 0,
                'score': 0,
                'liked': 0,
            },
            'town_home_visit': townDbId,
        }


class TownSocietyFriendSearch(RequestHandlerTask):
    """搜索好友/玩家
    前端调用: gGameApp:requestServer("/game/town/society/friend/search", ...)
    
    Args:
        friend: 是否只搜索好友
        roleName: 按名字搜索
        uid: 按UID搜索
    """
    url = r'/game/town/society/friend/search'
    
    @coroutine
    def run(self):
        from tornado.gen import Return
        
        friend = self.input.get('friend', None)
        roleName = self.input.get('roleName', None)
        uid = self.input.get('uid', None)
        
        roles = []
        
        # 如果是搜索好友列表
        if friend:
            friends = self.game.society.friends or []
            for friendId in friends:
                try:
                    roleInfo = yield self._getRoleInfoAsync(friendId)
                    # 只返回有家园的好友
                    if roleInfo and roleInfo.get('town_home', {}).get('town_db_id'):
                        roles.append(roleInfo)
                except Exception as e:
                    logger.warning('TownSocietyFriendSearch: get friend %s failed: %s', friendId, e)
        # 按UID搜索
        elif uid:
            try:
                searchUid = int(uid)
                # UID 不是 MongoDB _id，需要用 DBReadBy 查询
                ret = yield self.dbcGame.call_async('DBReadBy', 'Role', {'uid': searchUid})
                if ret['ret'] and ret['models']:
                    roleData = ret['models'][0]
                    # 只返回有家园的玩家
                    if roleData.get('town_db_id'):
                        roleId = roleData.get('id')
                        roles.append(self._buildRoleInfo(roleId, roleData))
            except (ValueError, TypeError):
                pass
        # 按名字搜索
        elif roleName:
            # 从数据库按名字搜索
            ret = yield self.dbcGame.call_async('DBReadBy', 'Role', {'name': roleName})
            if ret['ret'] and ret['models']:
                for roleData in ret['models'][:10]:  # 最多10个
                    # 只返回有家园的玩家
                    if roleData.get('town_db_id'):
                        roleId = roleData.get('id')
                        roles.append(self._buildRoleInfo(roleId, roleData))
        
        logger.info('TownSocietyFriendSearch: friend=%s roleName=%s uid=%s count=%s', 
                    friend, roleName, uid, len(roles))
        
        # 前端期望 tb.view.roles
        self.write({'view': {'roles': roles}})
    
    @coroutine
    def _getRoleInfoAsync(self, roleId):
        """异步获取玩家信息"""
        from tornado.gen import Return
        
        ret = yield self.dbcGame.call_async('DBRead', 'Role', roleId, False)
        if not ret['ret']:
            raise Return(None)
        
        roleData = ret['model']
        raise Return(self._buildRoleInfo(roleId, roleData))
    
    def _buildRoleInfo(self, roleId, roleData):
        """构造前端期望的数据结构"""
        from framework.service.helper import service_key2domains, service_key, gamemerge2game
        from game.server import Server
        
        # 根据 area 计算 game_key
        area = roleData.get('area', 1)
        service, language, _ = service_key2domains(Server.Singleton.key)
        gameKey = gamemerge2game(service_key(service, area, language))
        
        # 获取家园数据库ID
        townDbId = roleData.get('town_db_id', None)
        
        return {
            'id': roleId,
            'role': {
                'id': roleId,
                'name': roleData.get('name', ''),
                'level': roleData.get('level', 1),
                'vip_level': roleData.get('vip_level', 0),
                'logo': roleData.get('logo', 0),
                'frame': roleData.get('frame', 0),
                'game_key': gameKey,
            },
            'town_home': {
                'town_db_id': townDbId,  # 家园数据库ID
                'fixed': 0,    # 装饰分数
                'score': 0,    # 评分
                'liked': 0,    # 点赞数
            },
            'town_home_visit': townDbId,  # 兼容好友界面拜访入口
        }


class TownSocietyHomeRank(RequestHandlerTask):
    """家园排行榜
    前端调用: gGameApp:requestServer("/game/town/society/home/rank", ...)
    
    Args:
        rankType: 1=装饰排行, 2=点赞排行
        offset: 偏移量
        size: 每页数量
    """
    url = r'/game/town/society/home/rank'
    
    @coroutine
    def run(self):
        rankType = self.input.get('rankType', 1)
        offset = self.input.get('offset', 0)
        size = self.input.get('size', 10)
        
        # 简化实现：返回空排行榜（跨服排行榜需要 Go 服务支持）
        # TODO: 跨服获取排行榜 - 需要调用 cross_client('crosstown').call_async('HomeRank', ...)
        ranking = []  # 排行榜列表
        rank = 0      # 自己的排名
        
        logger.info('TownSocietyHomeRank: rankType=%s offset=%s size=%s', 
                    rankType, offset, size)
        
        # 前端期望 tb.view.ranking 和 tb.view.rank
        self.write({'view': {'ranking': ranking, 'rank': rank}})
