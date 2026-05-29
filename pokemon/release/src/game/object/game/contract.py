#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import absolute_import

from framework import nowtime_t
from framework.object import ObjectDBase, ObjectDBaseMap, db_property
from framework.csv import csv
from framework.log import logger
from framework.helper import objectid2string
from game.object.game.calculator import zeros
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from game.thinkingdata import ta
from game import ClientError

import copy
import math
import random
import weakref


class ObjectContract(ObjectDBase):
    """
    契约对象 - 参考携带道具和芯片系统的实现
    """
    
    DBModel = 'RoleContract'
    
    # 全局对象映射 - 参考芯片系统
    ContractObjsMap = weakref.WeakValueDictionary()
    
    @classmethod
    def classInit(cls):
        # 刷新csv配置 - 参考芯片系统
        for obj in cls.ContractObjsMap.itervalues():
            obj.init()
    
    def init(self):
        # 注册到全局映射 - 参考芯片和携带道具系统
        ObjectContract.ContractObjsMap[self.id] = self
        
        # 安全地获取CSV配置 - 修复 'NoneType' object is not callable 错误
        try:
            if (hasattr(csv, 'contract') and csv.contract and 
                hasattr(csv.contract, 'contract') and csv.contract.contract and
                self.contract_id in csv.contract.contract):
                self._csvContract = csv.contract.contract[self.contract_id]
            else:
                logger.warning('Contract CSV not found for contract_id: %s', self.contract_id)
                self._csvContract = None
        except Exception as e:
            logger.error('Error accessing contract CSV for contract_id %s: %s', self.contract_id, str(e))
            self._csvContract = None
            
        return ObjectDBase.init(self)
        
    def _fixCorrupted(self):
        # 数据修复逻辑 - 参考携带道具系统
        # 安全地初始化position字段
        # 注意：只在确实没有 position 字段时初始化为 -1
        # 如果 position 存在（即使是 0 或负数），也应该保留，避免重启后丢失装备状态
        if 'position' not in self.db:
            self.position = -1
        # 如果 position 是 None，且没有装备到卡牌，才设置为 -1
        elif self.db.get('position') is None and not self.db.get('card_db_id'):
            self.position = -1
        
        # 初始化 advance_cost_contracts 字段（前端需要）
        # 防御性检查：确保是有效的字典类型，且键是整数
        # 特别注意：db 可能直接存储了 None，必须强制转换
        raw_advance_cost = self.db.get('advance_cost_contracts', None)
        if raw_advance_cost is None:
            # 如果是 None，直接设为空字典（这会触发 setter）
            self.advance_cost_contracts = {}
            logger.debug('Contract %s: advance_cost_contracts was None, initialized to {}', self.id)
        elif not isinstance(raw_advance_cost, dict):
            logger.warning('Contract %s: advance_cost_contracts is not dict, resetting', self.id)
            self.advance_cost_contracts = {}
        else:
            # 修复旧数据：确保所有键都是整数
            fixed_dict = {}
            for k, v in raw_advance_cost.items():
                try:
                    key = int(k)
                    val = int(v)
                    fixed_dict[key] = val
                except (ValueError, TypeError):
                    logger.warning('Contract %s: invalid advance_cost_contracts entry: %s=%s, skipping', 
                                 self.id, k, v)
            self.advance_cost_contracts = fixed_dict
        
        # 初始化 cost_universal_items 字段
        # 防御性检查：确保是有效的字典类型，且键是整数
        # 特别注意：db 可能直接存储了 None，必须强制转换
        raw_cost_universal = self.db.get('cost_universal_items', None)
        if raw_cost_universal is None:
            # 如果是 None，直接设为空字典（这会触发 setter）
            self.cost_universal_items = {}
            logger.debug('Contract %s: cost_universal_items was None, initialized to {}', self.id)
        elif not isinstance(raw_cost_universal, dict):
            logger.warning('Contract %s: cost_universal_items is not dict, resetting', self.id)
            self.cost_universal_items = {}
        else:
            # 修复旧数据：确保所有键都是整数
            fixed_dict = {}
            for k, v in raw_cost_universal.items():
                try:
                    key = int(k)
                    val = int(v)
                    fixed_dict[key] = val
                except (ValueError, TypeError):
                    logger.warning('Contract %s: invalid cost_universal_items entry: %s=%s, skipping', 
                                 self.id, k, v)
            self.cost_universal_items = fixed_dict
            
        if self.card_db_id:
            card = self.game.cards.getCard(self.card_db_id)
            if not card:
                # 卡牌对象不存在 - 这通常是正常的数据加载时序问题（卡牌还没加载）
                # 为了避免误判，我们不立即清理状态，保留 card_db_id 和 position
                # 让后续的业务逻辑来处理这种情况
                # 使用 debug 级别记录，因为这是正常现象
                logger.debug('Contract %s: card_db_id %s not found during init (loading order). Keeping contract state intact.', 
                            objectid2string(self.id), objectid2string(self.card_db_id))
                # 不清理状态，保留 card_db_id 和 position
            else:
                # 卡牌存在，验证契约装备状态
                position = getattr(self, 'position', -1)
                
                # 检查卡牌的 contracts 字典是否已初始化
                if not hasattr(card, 'contracts') or not card.contracts:
                    logger.info('Contract %s: card %s contracts not initialized yet. Skipping validation.', 
                               objectid2string(self.id), objectid2string(self.card_db_id))
                    return  # 卡牌的契约槽位还没初始化，跳过验证
                
                # 验证position的有效性
                if position <= 0:
                    # position 无效（-1 或 0），尝试从卡牌的contracts中查找这个契约
                    logger.warning('Contract %s: position is %s, searching in card.contracts...', 
                                 objectid2string(self.id), position)
                    found_position = None
                    for pos, slot_info in card.contracts.items():
                        if slot_info and slot_info.get('contract_db_id') == self.id:
                            found_position = pos
                            break
                    
                    if found_position:
                        # 找到了，修正position
                        logger.info('Contract %s: position corrected from %s to %s based on card.contracts', 
                                   objectid2string(self.id), position, found_position)
                        self.position = found_position
                    else:
                        # 找不到，但不清理状态，因为可能是数据还没完全加载
                        logger.warning('Contract %s: thinks equipped to card %s but position is %s and not found in card.contracts. Data may be corrupted or still loading.', 
                                     objectid2string(self.id), objectid2string(self.card_db_id), position)
                elif position not in card.contracts:
                    # position 值看起来有效（>0），但槽位不存在
                    logger.warning('Contract %s: position %s not in card.contracts (available slots: %s)', 
                                 objectid2string(self.id), position, card.contracts.keys())
                    # 尝试查找
                    found_position = None
                    for pos, slot_info in card.contracts.items():
                        if slot_info and slot_info.get('contract_db_id') == self.id:
                            found_position = pos
                            break
                    if found_position:
                        logger.info('Contract %s: corrected position from %s to %s', 
                                   objectid2string(self.id), position, found_position)
                        self.position = found_position
                else:
                    # position有效且槽位存在，验证槽位中的contract_db_id是否匹配
                    slot_info = card.contracts[position]
                    if not slot_info:
                        logger.warning('Contract %s: slot_info at position %s is None/empty', 
                                     objectid2string(self.id), position)
                        # 槽位信息为空，尝试修复
                        card.contracts[position] = {'unlock': True, 'contract_db_id': self.id}
                        card.contracts = card.contracts  # 触发保存
                        logger.info('Contract %s: created slot_info and fixed slot reference at position %s', 
                                   objectid2string(self.id), position)
                    else:
                        slot_contract_id = slot_info.get('contract_db_id')
                        if slot_contract_id != self.id:
                            # 槽位被其他契约占用或为空
                            if slot_contract_id:
                                logger.error('Contract %s: position %s occupied by %s. Data corruption detected!', 
                                           objectid2string(self.id), position, objectid2string(slot_contract_id))
                                # 这是真正的数据冲突，清理当前契约的状态
                                self.card_db_id = None
                                self.position = -1
                            else:
                                # 槽位为空，尝试修复
                                logger.warning('Contract %s: slot at position %s is empty. Fixing...', 
                                             objectid2string(self.id), position)
                                card.contracts[position]['contract_db_id'] = self.id
                                card.contracts = card.contracts  # 触发保存
                                logger.info('Contract %s: fixed slot reference at position %s', 
                                           objectid2string(self.id), position)
    
    # Role.id
    role_db_id = db_property('role_db_id')

    # RoleCard.id
    card_db_id = db_property('card_db_id')

    # 契约 CSV ID
    contract_id = db_property('contract_id')

    # 强化等级
    level = db_property('level')

    # 突破等级
    advance = db_property('advance')

    # 当前获得的总经验
    sum_exp = db_property('sum_exp')

    # 是否存在（可能已经被分解）
    exist_flag = db_property('exist_flag')

    # 是否锁定
    locked = db_property('locked')
    
    # 突破消耗的万能道具数量 - 参考携带道具系统
    # 自定义 getter/setter 确保永远不是 None
    def _get_cost_universal_items(self):
        value = self._db.get('cost_universal_items', {})
        return value if value is not None else {}
    
    def _set_cost_universal_items(self, value):
        if value is None:
            value = {}
        self._db['cost_universal_items'] = value
    
    cost_universal_items = db_property('cost_universal_items', 
                                       fget=_get_cost_universal_items, 
                                       fset=_set_cost_universal_items)
    
    # 突破消耗的契约记录 - 用于重生返还显示（前端需要）
    # 自定义 getter/setter 确保永远不是 None
    def _get_advance_cost_contracts(self):
        value = self._db.get('advance_cost_contracts', {})
        return value if value is not None else {}
    
    def _set_advance_cost_contracts(self, value):
        if value is None:
            value = {}
        self._db['advance_cost_contracts'] = value
    
    advance_cost_contracts = db_property('advance_cost_contracts',
                                        fget=_get_advance_cost_contracts,
                                        fset=_set_advance_cost_contracts)
    
    # 装备位置
    position = db_property('position')

    @property
    def csv(self):
        """获取契约配置 - 修复 'NoneType' object is not callable 错误"""
        try:
            # 首先检查是否有缓存的CSV配置
            if hasattr(self, '_csvContract') and self._csvContract:
                return self._csvContract
            
            # 检查CSV配置是否存在
            if not hasattr(csv, 'contract') or not csv.contract:
                logger.warning('csv.contract not found')
                return None
                
            if not hasattr(csv.contract, 'contract') or not csv.contract.contract:
                logger.warning('csv.contract.contract not found')
                return None
                
            # 检查contract_id是否有效
            if not self.contract_id:
                logger.warning('contract_id is None or empty')
                return None
                
            # 安全地获取配置
            contract_cfg = csv.contract.contract[self.contract_id] if self.contract_id in csv.contract.contract else None
            if not contract_cfg:
                logger.warning('Contract config not found for contract_id: %s', self.contract_id)
                return None
                
            # 缓存配置
            self._csvContract = contract_cfg
            return contract_cfg
            
        except Exception as e:
            logger.error('Error getting contract CSV for contract_id %s: %s', self.contract_id, str(e))
            return None
        
    def getPassiveSkills(self):
        """获取契约提供的被动技能 - 用于战斗系统
        
        逻辑：
        1. 从契约配置本身（csv.contract.contract[contract_id]）读取 skillID
        2. 技能等级 = 突破等级 + 1
        3. 返回技能字典 {skillID: skill_level}
        
        注意：csv.contract.group.items 是羁绊效果（需要装备多个契约才触发），
             而这里是契约本身的技能
        """
        skills = {}
        
        # 检查契约配置是否存在
        if not self.csv:
            return skills
        
        try:
            # 从契约配置本身获取 skillID
            skillID = 0
            if hasattr(self.csv, 'skillID'):
                skillID = self.csv.skillID
            elif isinstance(self.csv, dict):
                skillID = self.csv.get('skillID', 0)
            
            # 如果有技能ID，且技能存在
            if skillID and skillID > 0:
                # 技能等级 = 突破等级 + 1（与前端逻辑一致）
                skill_level = self.advance + 1
                skills[skillID] = skill_level
                logger.info('Contract %s (contract_id=%s) provides skill %d at level %d', 
                           self.id, self.contract_id, skillID, skill_level)
                
        except Exception as e:
            logger.error('Error getting passive skills for contract %s: %s', self.contract_id, str(e))
        
        return skills
    
    def getAttrs(self):
        """获取契约提供的属性加成 - 基于正确的CSV结构实现"""
        logger.debug('=== CONTRACT getAttrs START for contract_id %s ===', self.contract_id)
        
        const = zeros()
        percent = zeros()
        
        if not self.csv:
            logger.warning('Contract %s has no CSV config', self.contract_id)
            return const, percent
            
        try:
            logger.debug('Contract %s details: level=%d, advance=%d, quality=%s', 
                        self.contract_id, self.level, self.advance, 
                        getattr(self.csv, 'quality', 'unknown'))
            
            # 获取契约的品质和强化序列ID
            quality = getattr(self.csv, 'quality', 1)
            strength_seq_id = getattr(self.csv, 'strengthExpSeqID', quality)
            
            # 获取属性修正因子 strengthAttrFixs
            strength_attr_fixs = getattr(self.csv, 'strengthAttrFixs', {})
            logger.debug('Contract %s strengthAttrFixs: %s', self.contract_id, strength_attr_fixs)
            
            if strength_attr_fixs:
                # 直接基于strengthAttrFixs计算属性，避免复杂的CSV查找
                try:
                    logger.debug('Contract %s strengthAttrFixs: %s', self.contract_id, strength_attr_fixs)
                    
                    # 获取基础属性值
                    base_attrs = self._getBaseAttrs(None)  # 不需要key了
                    level_attrs = self._getLevelAttrs(None)  # 不需要key了
                    
                    # 计算每个配置的属性
                    for attr_index, fix_rate in strength_attr_fixs.items():
                        try:
                            attr_index = int(attr_index)
                            fix_rate = float(fix_rate)
                            
                            # 从base_attr和level_attr获取基础值
                            base_value = base_attrs.get(attr_index, 0)
                            level_value = level_attrs.get(attr_index, 0)
                            
                            # 计算最终属性值：基础值 + 等级值，再乘以修正因子
                            final_value = (base_value + level_value) * fix_rate
                            
                            if final_value > 0:
                                const[attr_index] += final_value
                                logger.debug('Added attr index %d: %d (base=%d, level=%d, fix=%f)', 
                                           attr_index, final_value, base_value, level_value, fix_rate)
                            
                        except (ValueError, TypeError) as e:
                            logger.warning('Invalid attr config: index=%s, rate=%s, error=%s', 
                                         attr_index, fix_rate, str(e))
                        
                except Exception as e:
                    logger.error('Error calculating contract attributes for contract %s: %s', self.contract_id, str(e))
                    # 使用备用方案
                    self._applyFallbackAttrs(const, strength_attr_fixs)
            else:
                logger.warning('Contract %s has no strengthAttrFixs, using fallback', self.contract_id)
                # 使用默认属性生成
                default_attrs = self._getDefaultContractAttrs()
                if default_attrs:
                    from game.object.game.calculator import dict2attrs
                    default_const = dict2attrs(default_attrs)
                    const += default_const
                    logger.debug('Applied default attributes: %s', default_attrs)
            
            # 突破加成（基于advance_attr.csv）
            # 使用 advanceAttrFixs 作为突破属性修正因子（与前端一致）
            advance_attr_fixs = getattr(self.csv, 'advanceAttrFixs', {})
            if self.advance > 0 and advance_attr_fixs:
                advance_attrs = self._getAdvanceAttrs(quality, self.advance)
                if advance_attrs:
                    for attr_index, fix_rate in advance_attr_fixs.items():
                        try:
                            attr_index = int(attr_index)
                            fix_rate = float(fix_rate)
                            advance_value = advance_attrs.get(attr_index, 0)
                            
                            if advance_value > 0:
                                advance_bonus = advance_value * fix_rate
                                const[attr_index] += advance_bonus
                                logger.debug('Added advance bonus attr %d: %d (advance=%d, fix=%f)', 
                                           attr_index, advance_bonus, advance_value, fix_rate)
                                
                        except (ValueError, TypeError):
                            continue
                
        except Exception as e:
            logger.error('Error calculating contract attributes for contract_id %s: %s', self.contract_id, str(e))
            const = zeros()
            percent = zeros()
        
        # 计算总和用于调试
        try:
            total_const = sum(const) if len(const) > 0 else 0
            total_percent = sum(percent) if len(percent) > 0 else 0
        except (TypeError, AttributeError):
            total_const = 0
            total_percent = 0
        
        logger.debug('Contract %s final attributes: const_total=%d, percent_total=%d', 
                   self.contract_id, total_const, total_percent)
        logger.debug('=== CONTRACT getAttrs END ===')
                    
        return const, percent
    
    # 这两个方法不再需要，因为我们直接从strengthAttrFixs计算属性
    # def _getBaseAttrKey(self, quality, level):
    # def _getLevelAttrKey(self, quality, level):
    
    def _getBaseAttrs(self, key):
        """从base_attr.csv获取基础属性 - 暂时返回空，所有属性从level_attr获取"""
        try:
            # 基础属性现在由level_attr.csv提供，这里返回空
            return {}
        except Exception as e:
            logger.error('Error getting base_attr for key %s: %s', key, str(e))
            return {}
    
    def _getLevelAttrs(self, key):
        """从level_attr.csv获取等级属性"""
        try:
            # 详细的调试信息
            logger.debug('=== _getLevelAttrs DEBUG START ===')
            logger.debug('csv object exists: %s', csv is not None)
            logger.debug('csv.contract exists: %s', hasattr(csv, 'contract') and csv.contract is not None)
            
            if hasattr(csv, 'contract') and csv.contract:
                logger.debug('csv.contract.level_attr exists: %s', hasattr(csv.contract, 'level_attr') and csv.contract.level_attr is not None)
                
                if hasattr(csv.contract, 'level_attr') and csv.contract.level_attr:
                    quality = getattr(self.csv, 'quality', 6)
                    level = self.level
                    logger.debug('Looking for quality=%d, level=%d', quality, level)
                    
                    # 直接遍历CSV，仿照held_item模式
                    level_attr_cfg = None
                    try:
                        # 遍历所有level_attr配置，寻找匹配的quality和level
                        for cfg_id in csv.contract.level_attr:
                            cfg = csv.contract.level_attr[cfg_id]
                            if hasattr(cfg, 'quality') and hasattr(cfg, 'level'):
                                if cfg.quality == quality and cfg.level == level:
                                    level_attr_cfg = cfg
                                    logger.debug('Found level_attr config: cfg_id=%s, quality=%d, level=%d', cfg_id, quality, level)
                                    break
                    except Exception as iter_e:
                        logger.error('Error iterating through level_attr: %s', str(iter_e))
                    
                    if level_attr_cfg:
                        # 从CSV配置中读取所有属性值
                        attrs = {}
                        # 完整属性索引映射（包含所有可能的属性）
                        attr_mappings = {
                            1: 'hp',
                            7: 'damage', 
                            8: 'specialDamage',
                            9: 'defence',
                            10: 'specialDefence',
                            11: 'defenceIgnore',
                            12: 'specialDefenceIgnore',
                            13: 'speed',
                            14: 'strike',
                            15: 'strikeDamage',
                            16: 'strikeResistance',
                            17: 'block',
                            18: 'breakBlock',
                            19: 'blockPower',
                            20: 'dodge',
                            21: 'hit',
                            22: 'damageAdd',
                            23: 'damageSub',
                            24: 'ultimateAdd',
                            25: 'ultimateSub',
                            26: 'suckBlood',
                            27: 'rebound',
                            28: 'cure',
                            29: 'natureRestraint',
                            30: 'damageDeepen',
                            31: 'damageReduce',
                            90: 'controlPer',
                            91: 'immuneControl',
                            92: 'pvpDamageAdd',
                            93: 'pvpDamageSub',
                            94: 'damageHit',
                            95: 'damageDodge',
                            96: 'finalDamageAdd',
                            97: 'finalDamageSub',
                            98: 'finalDamageDeepen',
                            99: 'finalDamageReduce',
                        }
                        
                        for attr_index, attr_name in attr_mappings.items():
                            if hasattr(level_attr_cfg, attr_name):
                                attr_value = getattr(level_attr_cfg, attr_name, 0)
                                if attr_value > 0:
                                    attrs[attr_index] = attr_value
                        
                        logger.debug('Level attrs from CSV for contract %s: %s', self.contract_id, attrs)
                        return attrs
                    else:
                        logger.warning('No level_attr config found for quality=%d, level=%d', quality, level)
            
            # 备用：使用合理的默认值（基于quality=6, level=1）
            logger.warning('Using fallback level_attr defaults for contract %s', self.contract_id)
            return {
                1: 6000,   # hp  
                7: 1140,   # damage
                8: 1140,   # specialDamage
                9: 480,    # defence
                10: 480,   # specialDefence
                13: 50,    # speed
                24: 120,   # damageAdd
                26: 120,   # specialDamageAdd
            }
        except Exception as e:
            logger.error('Error getting level_attr for key %s: %s', key, str(e))
            # 确保总是返回一些合理的默认值
            return {
                1: 6000,   # hp  
                7: 1140,   # damage
                8: 1140,   # specialDamage
                9: 480,    # defence
                10: 480,   # specialDefence
                13: 50,    # speed
                24: 120,   # damageAdd
                26: 120,   # specialDamageAdd
            }
    
    def _getAdvanceAttrs(self, quality, advance):
        """从advance_attr.csv获取突破属性"""
        try:
            if advance <= 0:
                logger.debug('No advance needed for contract %s (advance=%d)', self.contract_id, advance)
                return {}
                
            logger.debug('Getting advance attrs for contract %s (quality=%d, advance=%d)', self.contract_id, quality, advance)
            
            # 从真实的CSV获取数据（使用与level_attr相同的安全访问方式）
            if hasattr(csv, 'contract') and csv.contract and hasattr(csv.contract, 'advance_attr') and csv.contract.advance_attr:
                # 直接遍历CSV，仿照held_item模式
                advance_attr_cfg = None
                try:
                    # 遍历所有advance_attr配置，寻找匹配的quality和advance
                    for cfg_id in csv.contract.advance_attr:
                        cfg = csv.contract.advance_attr[cfg_id]
                        if hasattr(cfg, 'quality') and hasattr(cfg, 'advance'):
                            if cfg.quality == quality and cfg.advance == advance:
                                advance_attr_cfg = cfg
                                logger.debug('Found advance_attr config: cfg_id=%s, quality=%d, advance=%d', cfg_id, quality, advance)
                                break
                except Exception as iter_e:
                    logger.error('Error iterating through advance_attr: %s', str(iter_e))
                
                if advance_attr_cfg:
                    # 从CSV配置中读取所有属性值
                    attrs = {}
                    # 完整属性索引映射（包含所有可能的属性）
                    attr_mappings = {
                        1: 'hp',
                        7: 'damage', 
                        8: 'specialDamage',
                        9: 'defence',
                        10: 'specialDefence',
                        11: 'defenceIgnore',
                        12: 'specialDefenceIgnore',
                        13: 'speed',
                        14: 'strike',
                        15: 'strikeDamage',
                        16: 'strikeResistance',
                        17: 'block',
                        18: 'breakBlock',
                        19: 'blockPower',
                        20: 'dodge',
                        21: 'hit',
                        22: 'damageAdd',
                        23: 'damageSub',
                        24: 'ultimateAdd',
                        25: 'ultimateSub',
                        26: 'suckBlood',
                        27: 'rebound',
                        28: 'cure',
                        29: 'natureRestraint',
                        30: 'damageDeepen',
                        31: 'damageReduce',
                        90: 'controlPer',
                        91: 'immuneControl',
                        92: 'pvpDamageAdd',
                        93: 'pvpDamageSub',
                        94: 'damageHit',
                        95: 'damageDodge',
                        96: 'finalDamageAdd',
                        97: 'finalDamageSub',
                        98: 'finalDamageDeepen',
                        99: 'finalDamageReduce',
                    }
                    
                    for attr_index, attr_name in attr_mappings.items():
                        if hasattr(advance_attr_cfg, attr_name):
                            attr_value = getattr(advance_attr_cfg, attr_name, 0)
                            if attr_value > 0:
                                attrs[attr_index] = attr_value
                    
                    logger.debug('Advance attrs from CSV for contract %s: %s', self.contract_id, attrs)
                    return attrs
                else:
                    logger.debug('No advance_attr config found for quality=%d, advance=%d', quality, advance)
            
            # 备用：使用合理的默认值（基于进阶加成）
            logger.debug('Using fallback advance_attr for contract %s (advance=%d)', self.contract_id, advance)
            base_advance_bonus = {
                1: 600,   # hp per advance
                7: 114,   # damage per advance
                8: 114,   # specialDamage per advance
                9: 48,    # defence per advance
                10: 48,   # specialDefence per advance
                13: 5,    # speed per advance
                24: 12,   # damageAdd per advance
                26: 12,   # specialDamageAdd per advance
            }
            
            attrs = {}
            for attr_index, base_value in base_advance_bonus.items():
                attrs[attr_index] = base_value * advance
                
            return attrs
        except Exception as e:
            logger.error('Error getting advance_attr for advance %d: %s', advance, str(e))
            return {}
    
    def _applyFallbackAttrs(self, const, strength_attr_fixs):
        """应用备用属性计算"""
        try:
            logger.debug('Applying fallback attribute calculation for contract %s', self.contract_id)
            
            # 根据属性类型设置不同的基础值
            base_values = {
                1: 2000,    # hp
                7: 300,     # damage
                8: 300,     # specialDamage
                9: 150,     # defence
                10: 150,    # specialDefence
                13: 20,     # speed
                24: 30,     # damageAdd
                26: 30,     # specialDamageAdd
            }
            
            for attr_index, fix_rate in strength_attr_fixs.items():
                try:
                    attr_index = int(attr_index)
                    fix_rate = float(fix_rate)
                    
                    # 获取基础值
                    base_value = base_values.get(attr_index, 100)
                    
                    # 计算等级加成
                    level_bonus = base_value * 0.1 * (self.level - 1)  # 每级增加10%
                    
                    # 应用修正因子
                    fallback_value = (base_value + level_bonus) * fix_rate
                    
                    if fallback_value > 0:
                        const[attr_index] += fallback_value
                        logger.debug('Applied fallback attr %d: %d (base=%d, level_bonus=%d, fix=%f)', 
                                   attr_index, fallback_value, base_value, level_bonus, fix_rate)
                    
                except (ValueError, TypeError):
                    continue
                    
        except Exception as e:
            logger.error('Error in fallback attr calculation: %s', str(e))
    
    def _getDefaultContractAttrs(self):
        """获取默认的契约属性 - 当CSV配置不完整时使用"""
        try:
            # 根据契约类型和等级计算基础属性
            base_power = 50 + (self.level - 1) * 10  # 基础值随等级增长
            
            # 根据契约ID的模式分配不同的属性类型
            contract_type = self.contract_id % 10
            
            default_attrs = {}
            
            if contract_type == 1:  # 攻击型契约
                default_attrs['damage'] = base_power
            elif contract_type == 2:  # 特攻型契约
                default_attrs['specialDamage'] = base_power
            elif contract_type == 3:  # 防御型契约
                default_attrs['defence'] = base_power
            elif contract_type == 4:  # 特防型契约
                default_attrs['specialDefence'] = base_power
            elif contract_type == 5:  # 速度型契约
                default_attrs['speed'] = base_power
            elif contract_type == 6:  # HP型契约
                default_attrs['hp'] = base_power * 5  # HP值通常更高
            elif contract_type == 7:  # 暴击型契约
                default_attrs['strike'] = base_power // 5  # 暴击率通常较小
            elif contract_type == 8:  # 命中型契约
                default_attrs['hit'] = base_power // 2
            else:  # 综合型契约
                # 分配到多个属性
                half_power = base_power // 2
                default_attrs['damage'] = half_power
                default_attrs['defence'] = half_power
            
            logger.info('Generated default attributes for contract %s (type=%d, level=%d): %s', 
                       self.contract_id, contract_type, self.level, default_attrs)
            
            return default_attrs
            
        except Exception as e:
            logger.error('Error generating default attributes for contract %s: %s', self.contract_id, str(e))
            return {}
        
    def _calculateLevelFromExp(self, total_exp):
        """根据总经验计算等级 - 与前端逻辑一致"""
        try:
            logger.info('_calculateLevelFromExp called: contract_id=%s, total_exp=%d, current_advance=%d', 
                       self.contract_id, total_exp, self.advance)
            
            if not self.csv:
                logger.warning('Contract %s has no CSV config', self.contract_id)
                return 1
            
            # 获取等级上限（与前端逻辑一致）
            level_max = getattr(self.csv, 'levelMax', 30)
            logger.info('Default level_max from CSV: %d', level_max)
            
            # 如果有突破等级限制，使用突破后的等级上限
            # 前端Lua: maxLevel = advanceRange[advance + 1] or levelMax (Lua数组从1开始)
            # Python: advanceRange通常是dict或list，需要正确映射
            if hasattr(self.csv, 'advanceRange') and self.csv.advanceRange:
                try:
                    # CSV系统通常将Lua的1-based数组转为Python的dict {1: val, 2: val, ...}
                    if isinstance(self.csv.advanceRange, dict):
                        # 字典形式，键可能是1, 2, 3...（保持Lua的1-based）
                        advance_level_max = self.csv.advanceRange.get(self.advance + 1, None)
                        logger.debug('Contract advanceRange (dict): %s, advance=%d, key=%d, limit=%s', 
                                   self.csv.advanceRange, self.advance, self.advance + 1, advance_level_max)
                    else:
                        # 列表形式（0-based），但CSV可能在索引0放了占位符
                        # 安全获取
                        advance_level_max = None
                        if len(self.csv.advanceRange) > self.advance:
                            advance_level_max = self.csv.advanceRange[self.advance]
                        logger.debug('Contract advanceRange (list): %s, advance=%d, index=%d, limit=%s', 
                                   self.csv.advanceRange, self.advance, self.advance, advance_level_max)
                    
                    if advance_level_max is not None and advance_level_max > 0:
                        level_max = advance_level_max
                        logger.info('Contract advance=%d, using level_max=%d from advanceRange', 
                                   self.advance, level_max)
                    else:
                        logger.info('Contract advance=%d, no valid advanceRange limit, using levelMax=%d', 
                                   self.advance, level_max)
                except (KeyError, IndexError, TypeError) as e:
                    logger.warning('Failed to get advanceRange for advance=%d: %s, using levelMax=%d', 
                                 self.advance, str(e), level_max)
            
            # 获取强化经验序列ID
            strength_exp_seq_id = getattr(self.csv, 'strengthExpSeqID', 1)
            level_exp_field = 'levelExp%d' % strength_exp_seq_id
            
            logger.debug('Calculating level: total_exp=%d, level_max=%d, seq_id=%d', 
                        total_exp, level_max, strength_exp_seq_id)
            
            # 从 contract.level CSV 表逐级计算
            if (hasattr(csv, 'contract') and csv.contract and 
                hasattr(csv.contract, 'level') and csv.contract.level):
                
                now_level = 1
                remaining_exp = total_exp
                
                # 按等级顺序遍历
                for level_id in sorted(csv.contract.level.keys()):
                    if now_level >= level_max:
                        break
                    
                    level_cfg = csv.contract.level[level_id]
                    
                    # 获取该等级所需经验
                    need_exp = 0
                    if hasattr(level_cfg, level_exp_field):
                        need_exp = getattr(level_cfg, level_exp_field, 0)
                    elif isinstance(level_cfg, dict):
                        need_exp = level_cfg.get(level_exp_field, 0)
                    
                    # 检查是否有足够经验升级
                    if need_exp > 0 and remaining_exp >= need_exp:
                        now_level += 1
                        remaining_exp -= need_exp
                        logger.debug('Level up to %d, consumed %d exp, remaining %d', 
                                   now_level, need_exp, remaining_exp)
                    else:
                        break
                
                logger.info('Final calculated level: %d (from exp %d, remaining %d, level_max=%d)', 
                           now_level, total_exp, remaining_exp, level_max)
                return now_level
            
            # 备用方案：简单线性计算
            logger.warning('Using fallback level calculation for contract %s', self.contract_id)
            exp_per_level = getattr(self.csv, 'expPerLevel', 100)
            fallback_level = min(1 + total_exp // exp_per_level, level_max)
            logger.info('Fallback calculated level: %d (exp_per_level=%d, level_max=%d)', 
                       fallback_level, exp_per_level, level_max)
            return fallback_level
            
        except Exception as e:
            logger.error('Error calculating level from exp for contract %s: %s', self.contract_id, str(e))
            import traceback
            traceback.print_exc()
            return self.level  # 保持当前等级
    
    def can_advance(self):
        """检查是否可以突破 - 参考携带道具系统"""
        logger.info('Checking can_advance: contract_id=%s, current_advance=%d, level=%d', 
                   self.contract_id, self.advance, self.level)
        
        if not self.csv:
            logger.warning('Contract %s has no CSV config', self.contract_id)
            return False
            
        try:
            # 检查是否已达到最大突破等级
            if hasattr(self.csv, 'advanceRange') and self.csv.advanceRange:
                max_advance = max(self.csv.advanceRange) if self.csv.advanceRange else 0
                logger.info('Contract %s max_advance=%d, current_advance=%d', 
                          self.contract_id, max_advance, self.advance)
                if self.advance >= max_advance:
                    logger.info('Contract %s already at max advance level', self.contract_id)
                    return False
            
            # 检查是否有突破配置
            if (hasattr(csv, 'contract') and csv.contract and 
                hasattr(csv.contract, 'advance_cost') and csv.contract.advance_cost):
                # 获取突破序列ID
                advance_cost_seq_id = getattr(self.csv, 'advanceCostSeqID', None)
                logger.info('Contract %s advanceCostSeqID=%s', self.contract_id, advance_cost_seq_id)
                
                if advance_cost_seq_id is None:
                    logger.warning('Contract %s has no advanceCostSeqID', self.contract_id)
                    return False
                
                # 遍历所有突破配置，查找匹配的 seq 和 advance
                for cfg_id in csv.contract.advance_cost:
                    cfg = csv.contract.advance_cost[cfg_id]
                    if hasattr(cfg, 'seq') and hasattr(cfg, 'advance'):
                        if cfg.seq == advance_cost_seq_id and cfg.advance == self.advance + 1:
                            logger.info('Found advance config for contract %s: cfg_id=%s', 
                                      self.contract_id, cfg_id)
                            return True
                
                logger.warning('No advance config found for contract %s, seq=%s, advance=%d', 
                             self.contract_id, advance_cost_seq_id, self.advance + 1)
                
        except Exception as e:
            logger.error('Error checking contract advance for contract_id %s: %s', self.contract_id, str(e))
            import traceback
            traceback.print_exc()
            
        return False
        
    def can_upgrade(self):
        """检查是否可以强化 - 参考携带道具系统"""
        try:
            # 检查CSV配置是否存在
            if not self.csv:
                logger.warning('Contract CSV config not found for contract_id: %s', self.contract_id)
                return False
            
            # 检查是否已达到最大等级
            level_max = getattr(self.csv, 'levelMax', None)
            if level_max and self.level >= level_max:
                logger.debug('Contract %s already at max level %s/%s', self.contract_id, self.level, level_max)
                return False
            
            # 简化升级条件检查 - 暂时允许所有未达到最大等级的契约升级
            # TODO: 添加更复杂的升级条件检查
            return True
                
        except Exception as e:
            logger.error('Error checking contract upgrade for contract_id %s: %s', self.contract_id, str(e))
            import traceback
            traceback.print_exc()
            
        return False
        
    def upgrade(self, cost_items, cost_contracts):
        """强化契约 - 参考携带道具系统"""
        if not self.can_upgrade():
            raise ClientError('contract can not upgrade')
            
        try:
            logger.info('Contract upgrade: contract_id=%s, level=%s, current_exp=%s', 
                       self.contract_id, self.level, self.sum_exp)
            logger.info('Cost items: %s', cost_items)
            logger.info('Cost contracts: %s', cost_contracts)
            
            # 计算道具提供的经验
            item_exp = 0
            for item_id, count in cost_items.items():
                try:
                    item_id_int = int(item_id)
                    # 首先尝试从契约配置获取经验值
                    if (hasattr(csv, 'contract') and csv.contract and 
                        hasattr(csv.contract, 'contract') and csv.contract.contract and
                        item_id_int in csv.contract.contract):
                        contract_cfg = csv.contract.contract[item_id_int]
                        if hasattr(contract_cfg, 'exp') and contract_cfg.exp:
                            item_exp += contract_cfg.exp * count
                            logger.info('Item %s provides %s exp (contract type)', item_id, contract_cfg.exp * count)
                            continue
                    
                    # 如果不是契约类型，尝试从items配置获取经验值
                    if (hasattr(csv, 'items') and csv.items and item_id_int in csv.items):
                        item_cfg = csv.items[item_id_int]
                        if hasattr(item_cfg, 'specialArgsMap') and item_cfg.specialArgsMap:
                            contract_exp = item_cfg.specialArgsMap.get('contractExp', 0)
                            if contract_exp > 0:
                                item_exp += contract_exp * count
                                logger.info('Item %s provides %s exp (item type)', item_id, contract_exp * count)
                                
                except Exception as e:
                    logger.warning('Error processing cost item %s: %s', item_id, str(e))
                
            # 计算契约提供的经验
            contract_exp = 0
            for contract_id, count in cost_contracts.items():
                try:
                    contract_id_int = int(contract_id)
                    if (hasattr(csv, 'contract') and csv.contract and 
                        hasattr(csv.contract, 'contract') and csv.contract.contract and
                        contract_id_int in csv.contract.contract):
                        contract_cfg = csv.contract.contract[contract_id_int]
                        if hasattr(contract_cfg, 'exp') and contract_cfg.exp:
                            contract_exp += contract_cfg.exp * count
                            logger.info('Contract %s provides %s exp', contract_id, contract_cfg.exp * count)
                except Exception as e:
                    logger.warning('Error processing cost contract %s: %s', contract_id, str(e))
            
            # 计算总经验增益
            total_gain_exp = item_exp + contract_exp
            logger.info('Total exp gain: %s (item: %s, contract: %s)', 
                       total_gain_exp, item_exp, contract_exp)
            
            if total_gain_exp <= 0:
                raise ClientError('no exp provided')
            
            # 增加经验
            self.sum_exp += total_gain_exp
            
            # 根据 CSV 表计算新等级（与前端逻辑一致）
            old_level = self.level
            new_level = self._calculateLevelFromExp(self.sum_exp)
            
            # 双重保险：确保不超过最大等级
            level_max = 30 # 默认上限
            if self.csv:
                level_max = getattr(self.csv, 'levelMax', 30)
                # 如果有突破等级限制，使用突破后的等级上限
                if hasattr(self.csv, 'advanceRange') and self.csv.advanceRange:
                    try:
                        if isinstance(self.csv.advanceRange, dict):
                            advance_level_max = self.csv.advanceRange.get(self.advance + 1, None)
                        else:
                            advance_level_max = None
                            if len(self.csv.advanceRange) > self.advance:
                                advance_level_max = self.csv.advanceRange[self.advance]
                        
                        if advance_level_max is not None and advance_level_max > 0:
                            level_max = advance_level_max
                    except (KeyError, IndexError, TypeError):
                        pass

            # 确保不超过上限
            new_level = min(new_level, level_max)
        
            # logger.info('Contract upgrade calculation: contract_id=%s, advance=%d, old_level=%d, new_level=%d, total_exp=%d', 
            #            self.contract_id, self.advance, old_level, new_level, self.sum_exp)
            
            if new_level > old_level:
                self.level = new_level
                # logger.info('Contract level up: contract_id=%s, %d -> %d, total_exp=%d', 
                #            self.contract_id, old_level, self.level, self.sum_exp)
            else:
                pass
                # logger.info('Contract exp increased: contract_id=%s, level=%d, total_exp=%d', 
                #            self.contract_id, self.level, self.sum_exp)
            
            return True
                           
        except Exception as e:
            logger.error('Error upgrading contract %s: %s', self.contract_id, str(e))
            import traceback
            traceback.print_exc()
            raise
        
    def advance_up(self, cost_items, cost_contracts):
        """突破契约 - 参考携带道具系统"""
        # logger.info('Contract advance_up called: contract_id=%s, current_advance=%d, level=%d', 
        #            self.contract_id, self.advance, self.level)
        # logger.info('Cost items: %s', cost_items)
        # logger.info('Cost contracts: %s', cost_contracts)
        
        if not self.can_advance():
            logger.error('Contract cannot advance: contract_id=%s, advance=%d', 
                        self.contract_id, self.advance)
            raise ClientError('cannot advance')
            
        try:
            # 获取突破配置
            advance_cost_cfg = None
            if (hasattr(csv, 'contract') and csv.contract and 
                hasattr(csv.contract, 'advance_cost') and csv.contract.advance_cost):
                advance_cost_seq_id = getattr(self.csv, 'advanceCostSeqID', None)
                # logger.info('Looking for advance config: seq=%s, advance=%d', 
                #           advance_cost_seq_id, self.advance + 1)
                
                # 遍历所有突破配置，查找匹配的 seq 和 advance
                for cfg_id in csv.contract.advance_cost:
                    cfg = csv.contract.advance_cost[cfg_id]
                    if hasattr(cfg, 'seq') and hasattr(cfg, 'advance'):
                        if cfg.seq == advance_cost_seq_id and cfg.advance == self.advance + 1:
                            advance_cost_cfg = cfg
                            # logger.info('Found advance config: cfg_id=%s', cfg_id)
                            break
                
                if not advance_cost_cfg:
                    logger.error('Contract advance config not found: contract_id=%s, seq=%s, advance=%d', 
                               self.contract_id, advance_cost_seq_id, self.advance + 1)
                    raise ClientError('contract advance config not found')
                
                # 验证道具消耗（注意：cost_items 应该已经在 handler 中验证和扣除）
                # 这里只做防御性检查，确保数据类型正确
                if cost_items and not isinstance(cost_items, dict):
                    logger.error('Invalid cost_items type: %s', type(cost_items))
                    raise ClientError('invalid cost items')
                
                # 验证契约消耗（注意：cost_contracts 应该已经在 handler 中验证和扣除）
                # 这里确保数据格式正确：键必须是契约 CSV ID（整数），值必须是数量（正整数）
                if cost_contracts:
                    if not isinstance(cost_contracts, dict):
                        logger.error('Invalid cost_contracts type: %s', type(cost_contracts))
                        raise ClientError('invalid cost contracts')
                    
                    for k, v in cost_contracts.items():
                        try:
                            contract_csv_id = int(k)
                            count = int(v)
                            if contract_csv_id <= 0 or count <= 0:
                                logger.error('Invalid contract cost: csv_id=%s, count=%s', k, v)
                                raise ClientError('invalid contract cost')
                        except (ValueError, TypeError) as e:
                            logger.error('Cannot parse contract cost: csv_id=%s, count=%s, error=%s', k, v, e)
                            raise ClientError('invalid contract cost')
                
                # 初始化 advance_cost_contracts 如果不存在
                if not hasattr(self, 'advance_cost_contracts') or self.advance_cost_contracts is None:
                    self.advance_cost_contracts = {}
                
                # 记录突破消耗的契约（用于重生返还）
                # 注意：键必须是整数类型（契约CSV ID），参考 held_item 的 cost_universal_items
                for contract_id, count in cost_contracts.items():
                    # 确保键是整数（契约 CSV ID）
                    try:
                        key = int(contract_id)
                        val = int(count)
                        
                        # 验证有效性：CSV ID 和数量必须为正数
                        if key <= 0:
                            logger.warning('Invalid contract CSV ID: %s, skipping', key)
                            continue
                        if val <= 0:
                            logger.warning('Invalid contract count: %s for csv_id %s, skipping', val, key)
                            continue
                        
                        # 记录消耗
                        if key not in self.advance_cost_contracts:
                            self.advance_cost_contracts[key] = 0
                        self.advance_cost_contracts[key] += val
                        logger.debug('Recorded advance cost: contract_csv_id=%s, count=%s', key, val)
                        
                    except (ValueError, TypeError) as e:
                        logger.warning('Invalid contract cost entry: contract_id=%s, count=%s, error=%s, skipping', 
                                     contract_id, count, str(e))
                        continue
                
                # 突破
                self.advance += 1
                
                # logger.info('Contract advanced: contract_id=%s, advance=%d, cost_contracts=%s', 
                #            self.contract_id, self.advance, self.advance_cost_contracts)
                           
        except Exception as e:
            logger.error('Error advancing contract %s: %s', self.contract_id, str(e))
            raise ClientError('contract advance failed')
        
    def dress_on(self, card, position):
        """装备契约到卡牌 - 参考携带道具系统"""
        if not card:
            raise ClientError('card not found')
            
        try:
            # 检查位置是否有效（1-based 字典）
            if position not in card.contracts:
                raise ClientError('invalid position')
            
            # 检查位置是否已解锁
            if not card.contracts[position].get('unlock', False):
                raise ClientError('position not unlocked')
                
            # 检查位置是否已被占用
            existing_contract_id = card.contracts[position].get('contract_db_id', None)
            if existing_contract_id:
                logger.error('Position %d already occupied by contract %s for card %s', 
                           position, existing_contract_id, card.id)
                
                # 尝试获取占用槽位的契约对象
                existing_contract = self.game.contracts.getContract(existing_contract_id)
                if existing_contract:
                    logger.error('Existing contract details: card_db_id=%s, position=%d', 
                               existing_contract.card_db_id, existing_contract.position)
                    
                    # 检查是否是数据不同步（契约对象显示未装备，但槽位显示已装备）
                    if not existing_contract.card_db_id:
                        logger.warning('Data sync issue detected: contract %s shows unequipped but slot shows occupied', 
                                     existing_contract_id)
                        logger.warning('Auto-cleaning stale slot reference...')
                        card.contracts[position]['contract_db_id'] = None
                        # 立即触发保存，避免数据丢失
                        card.contracts = card.contracts
                        # 重新检查是否还被占用
                        if not card.contracts[position].get('contract_db_id', None):
                            logger.info('Slot cleaned successfully, proceeding with equip')
                        else:
                            raise ClientError('position already occupied')
                    else:
                        raise ClientError('position already occupied')
                else:
                    logger.warning('Slot references non-existent contract %s, cleaning...', existing_contract_id)
                    card.contracts[position]['contract_db_id'] = None
                    # 立即触发保存
                    card.contracts = card.contracts
                
            # 装备
            self.card_db_id = card.id
            self.position = position
            card.contracts[position]['contract_db_id'] = self.id
            
            # 强制触发保存（修改嵌套字典不会自动触发db_property保存）
            card.contracts = card.contracts
            
            # 重新计算契约属性加成
            from game.object.game.card import ObjectCard
            ObjectCard.calcContractAttrsAddition(card)
            card.onUpdateAttrs()
                       
            return True
                       
        except Exception as e:
            logger.error('Error equipping contract %s: %s', self.contract_id, str(e))
            raise ClientError('contract equip failed')
        
    def dress_off(self):
        """卸下契约 - 参考携带道具系统"""
        try:
            card_to_update = None
            
            # 方案1：基于存储的 card_db_id（和 position，如果有效）
            if self.card_db_id:
                card = self.game.cards.getCard(self.card_db_id)
                
                if card:
                    # 尝试从 card.contracts 反向查找 position（因为 self.position 可能是 -1）
                    actual_position = None
                    if self.position > 0 and self.position in card.contracts:
                        # 优先使用 self.position
                        if card.contracts[self.position].get('contract_db_id') == self.id:
                            actual_position = self.position
                    
                    # 如果 self.position 无效，全局搜索
                    if actual_position is None:
                        for pos, slot_info in card.contracts.items():
                            if slot_info.get('contract_db_id') == self.id:
                                actual_position = pos
                                break
                    
                    # 清空槽位
                    if actual_position:
                        card.contracts[actual_position]['contract_db_id'] = None
                        # 强制触发保存
                        card.contracts = card.contracts
                        card_to_update = card
                
                # 清空契约对象的装备状态
                self.card_db_id = None
                self.position = -1
            else:
                # 方案2：如果存储的引用无效，尝试全局搜索清理
                for card_id, card in self.game.cards._objs.items():
                    if not card or not hasattr(card, 'contracts'):
                        continue
                        
                    for pos, pos_info in card.contracts.items():
                        if pos_info.get('contract_db_id') == self.id:
                            card.contracts[pos]['contract_db_id'] = None
                            # 强制触发保存
                            card.contracts = card.contracts
                            card_to_update = card
                            break
                    
                # 清空契约对象状态
                self.card_db_id = None
                self.position = -1
            
            # 重新计算属性（如果有宠物需要更新）
            if card_to_update:
                from game.object.game.card import ObjectCard
                ObjectCard.calcContractAttrsAddition(card_to_update)
                card_to_update.onUpdateAttrs()
            
            return True
             
        except Exception as e:
            logger.error('Error unequipping contract %s: %s', self.contract_id, str(e))
            return False
        
    def get_fetter_state(self):
        """获取契约羁绊状态 - 参考芯片系统"""
        if not self.card_db_id:
            return None
            
        try:
            card = self.game.cards.getCard(self.card_db_id)
            if not card:
                return None
                
            # 检查羁绊配置
            if (hasattr(csv, 'contract') and csv.contract and 
                hasattr(csv.contract, 'group') and csv.contract.group and
                hasattr(self.csv, 'groupID') and self.csv.groupID):
                
                # 安全地访问 group 配置
                group_cfg = None
                try:
                    # 尝试字典访问
                    if hasattr(csv.contract.group, '__getitem__'):
                        group_cfg = csv.contract.group[self.csv.groupID]
                    # 尝试 get 方法
                    elif hasattr(csv.contract.group, 'get'):
                        group_cfg = csv.contract.group.get(self.csv.groupID, None)
                except (KeyError, AttributeError, TypeError):
                    pass
                
                if group_cfg:
                    # 计算羁绊状态（简化处理）
                    return {
                        'group_id': self.csv.groupID,
                        'active': True  # 简化处理，实际需要更复杂的逻辑
                    }
                    
        except Exception as e:
            logger.error('Error getting contract fetter state %s: %s', self.contract_id, str(e))
            
        return None
        
    def getContractInfo(self):
        """获取契约的详细信息用于调试"""
        info = {
            'contract_id': self.contract_id,
            'level': self.level,
            'advance': self.advance,
            'position': self.position,
            'card_db_id': self.card_db_id,
        }
        
        if self.csv:
            info['groupID'] = getattr(self.csv, 'groupID', 'N/A')
            info['quality'] = getattr(self.csv, 'quality', 'N/A')
            info['name'] = getattr(self.csv, 'name', 'N/A')
        
        return info
    
    def to_dict(self):
        """转换为字典格式 - 参考携带道具系统"""
        try:
            # 安全地获取字段值，避免unhashable type错误
            def safe_get(attr_name, default=None):
                try:
                    value = getattr(self, attr_name, default)
                    # 确保复杂对象被正确序列化
                    if isinstance(value, dict):
                        # 创建字典的副本，并确保键值都是可序列化的类型
                        # 对于 advance_cost_contracts 和 cost_universal_items，键必须是整数
                        result = {}
                        for k, v in value.items():
                            # 确保键是整数（对于道具/契约ID字典）
                            try:
                                key = int(k)
                            except (ValueError, TypeError):
                                # 如果不能转换为整数，保持原类型
                                key = k if isinstance(k, (int, str)) else str(k)
                            
                            # 确保值是基本类型
                            if isinstance(v, (int, float)):
                                val = int(v)
                            elif isinstance(v, bool):
                                val = v
                            elif isinstance(v, str):
                                val = v
                            else:
                                # 尝试转换为整数，失败则保持原值
                                try:
                                    val = int(v)
                                except:
                                    val = v
                            result[key] = val
                        return result
                    elif hasattr(value, '__dict__'):
                        return str(value)  # 复杂对象转为字符串
                    return value
                except Exception as e:
                    logger.warning('Error getting attribute %s: %s', attr_name, str(e))
                    return default
            
            # 获取并清理 advance_cost_contracts，确保数据完整性
            advance_cost = safe_get('advance_cost_contracts', {})
            # 过滤掉无效的键值对，防止前端出现 nil 索引错误
            clean_advance_cost = {}
            if advance_cost and isinstance(advance_cost, dict):
                for k, v in advance_cost.items():
                    try:
                        # 确保键是有效的正整数（契约CSV ID）
                        key = int(k)
                        # 确保值是有效的正整数（数量）
                        val = int(v)
                        # 只保留有效的数据（键和值都大于0）
                        if key > 0 and val > 0:
                            clean_advance_cost[key] = val
                    except (ValueError, TypeError):
                        # 跳过无效的条目
                        logger.warning('Contract %s: invalid advance_cost_contracts entry: %s=%s, skipping', 
                                     self.id, k, v)
                        continue
            
            # 同样清理 cost_universal_items
            universal_items = safe_get('cost_universal_items', {})
            clean_universal_items = {}
            if universal_items and isinstance(universal_items, dict):
                for k, v in universal_items.items():
                    try:
                        key = int(k)
                        val = int(v)
                        if key > 0 and val > 0:
                            clean_universal_items[key] = val
                    except (ValueError, TypeError):
                        logger.warning('Contract %s: invalid cost_universal_items entry: %s=%s, skipping', 
                                     self.id, k, v)
                        continue
            
            return {
                'id': str(self.id) if self.id else None,
                'role_db_id': str(self.role_db_id) if self.role_db_id else None,
                'card_db_id': str(self.card_db_id) if self.card_db_id else None,
                'contract_id': safe_get('contract_id', 0),
                'level': safe_get('level', 1),
                'advance': safe_get('advance', 0),
                'sum_exp': safe_get('sum_exp', 0),
                'exist_flag': safe_get('exist_flag', True),
                'locked': safe_get('locked', False),
                'position': safe_get('position', -1),
                'cost_universal_items': clean_universal_items,
                'advance_cost_contracts': clean_advance_cost,
            }
        except Exception as e:
            logger.error('Error in contract.to_dict(): %s', str(e))
            # 返回最基本的数据
            return {
                'id': str(self.id) if hasattr(self, 'id') and self.id else None,
                'contract_id': 0,
                'level': 1,
                'advance': 0,
                'sum_exp': 0,
                'exist_flag': True,
                'locked': False,
                'position': -1,
                'cost_universal_items': {},
                'advance_cost_contracts': {},
            }


#
# ObjectContractsMap - 参考携带道具和芯片系统的管理器
#
class ObjectContractsMap(ObjectDBaseMap):
    
    def _new(self, dic):
        contract = ObjectContract(self.game, self.game._dbcGame)
        contract.set(dic).init().startSync()
        return (contract.id, contract)

    def getContract(self, contractID):
        """获取单个契约对象 - 参考携带道具系统"""
        ret = self._objs.get(contractID, None)
        if ret and not ret.exist_flag:
            return None
        return ret

    def getContracts(self, contractIDs):
        """获取多个契约对象 - 参考芯片系统"""
        ret = []
        for contract_id in contractIDs:
            if contract_id in self._objs:
                contract = self._objs[contract_id]
                if contract.exist_flag:
                    ret.append(contract)
        return ret

    def addContracts(self, contractsL):
        """添加多个契约对象 - 参考芯片系统"""
        if len(contractsL) == 0:
            return {}
            
        def _new(dic):
            contract = ObjectContract(self.game, self.game._dbcGame)
            contract.set(dic).init().startSync()
            return (contract.id, contract)
            
        objs = dict(map(_new, contractsL))
        self._objs.update(objs)
        
        # 更新角色的契约列表
        self.game.role.contracts = [o.id for o in self._objs.itervalues() if o.exist_flag]
        self._add(objs.keys())
        return objs

    def deleteContracts(self, objs):
        """删除多个契约对象 - 参考芯片系统"""
        if len(objs) == 0:
            return
            
        for obj in objs:
            if obj.id in self._objs:
                # 先卸下契约
                obj.dress_off()
                # 标记为不存在
                obj.exist_flag = False
            
        # 更新角色的契约列表
        self.game.role.contracts = [o.id for o in self._objs.itervalues() if o.exist_flag]
        self._del([obj.id for obj in objs])

    def getContractFetterAttrs(self, card):
        """获取契约羁绊属性加成 - 参考芯片系统"""
        if not card or not hasattr(card, 'contracts') or not card.contracts:
            return zeros(), zeros()
            
        const = zeros()
        percent = zeros()
        
        try:
            # 收集已装备的契约
            equipped_contracts = []
            for pos, slot in card.contracts.items():
                if slot.get('contract_db_id', None):
                    contract = self.getContract(slot['contract_db_id'])
                    if contract:
                        equipped_contracts.append(contract)
                        
            # 计算羁绊效果（简化处理）
            for contract in equipped_contracts:
                fetter_state = contract.get_fetter_state()
                if fetter_state and fetter_state.get('active', False):
                    # 添加羁绊属性（这里需要根据具体的羁绊配置来实现）
                    pass
                    
        except Exception as e:
            logger.error('Error calculating contract fetter attrs for card %s: %s', card.id, str(e))
                        
        return const, percent 