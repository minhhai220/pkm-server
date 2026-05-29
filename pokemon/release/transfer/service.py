#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

【转区逻辑】核心服务 - 执行数据迁移（角色、精灵、宝石、芯片等）
'''

import time
import copy
import logging

logger = logging.getLogger(__name__)


class TransferService(object):
    """转区服务 - 使用 pymongo 直接操作数据库"""
    
    def __init__(self, source_db, target_db, account_db=None):
        """
        Args:
            source_db: pymongo 源区数据库对象 (db.game_cn_1)
            target_db: pymongo 目标区数据库对象 (db.game_cn_2)
            account_db: pymongo account 数据库对象 (db.account)
        """
        self.source_db = source_db
        self.target_db = target_db
        self.account_db = account_db
        
        # ID映射表
        self.card_id_map = {}       # {旧CardDbId: 新CardDbId}
        self.gem_id_map = {}        # {旧GemDbId: 新GemDbId}
        self.chip_id_map = {}       # {旧ChipDbId: 新ChipDbId}
        self.contract_id_map = {}   # {旧ContractDbId: 新ContractDbId}
        self.held_item_id_map = {}  # {旧HeldItemDbId: 新HeldItemDbId}
        self.emera_id_map = {}      # {旧EmeraDbId: 新EmeraDbId}
        
        # 结果
        self.new_role_id = None
        self.new_uid = 0
        self.new_name = ''
        self.error_msg = ''
        
        # 源角色信息（用于更新 Account）
        self.source_level = 1
        self.source_logo = 1
        self.source_vip = 0
        self.source_frame = 1
    
    def execute(self, source_role_id, target_area, record_id=None, progress_cb=None):
        """执行转区（同步方法，直接操作 MongoDB）
        
        Args:
            source_role_id: 源角色ID (ObjectId)
            target_area: 目标区号 (int)
            record_id: 转区记录ID
            progress_cb: 进度回调 (progress, msg)
        """
        try:
            logger.info('[Transfer] ========== START ==========')
            logger.info('[Transfer] source_role=%s, target_area=%s', 
                       source_role_id, target_area)
            
            # 1. 读取源区数据
            if progress_cb: progress_cb(5, 'Reading source data...')
            source_role = self.source_db.Role.find_one({'_id': source_role_id})
            if not source_role:
                self.error_msg = 'Source role not found'
                return False
            
            account_id = source_role.get('account_id')
            logger.info('[Transfer] Source: UID=%s, Name=%s, Level=%s, AccountID=%s',
                       source_role.get('uid'), source_role.get('name'), 
                       source_role.get('level'), account_id)
            
            # 保存源角色信息（用于 RPC 更新 Account）
            self.source_level = source_role.get('level', 1)
            self.source_logo = source_role.get('logo', 1)
            self.source_vip = source_role.get('vip_level', 0)
            self.source_frame = source_role.get('frame', 1)
            
            # 读取所有关联数据
            source_cards = list(self.source_db.RoleCard.find({'role_db_id': source_role_id}))
            source_gems = list(self.source_db.RoleGem.find({'role_db_id': source_role_id}))
            source_chips = list(self.source_db.RoleChip.find({'role_db_id': source_role_id}))
            source_contracts = list(self.source_db.RoleContract.find({'role_db_id': source_role_id}))
            source_held_items = list(self.source_db.RoleHeldItem.find({'role_db_id': source_role_id}))
            source_emeras = list(self.source_db.RoleEmera.find({'role_db_id': source_role_id, 'exist_flag': True}))
            source_totem = self.source_db.Totem.find_one({'role_db_id': source_role_id})
            source_town = self.source_db.Town.find_one({'role_db_id': source_role_id})
            source_lottery = self.source_db.LotteryRecord.find_one({'role_db_id': source_role_id})
            source_fishing = self.source_db.Fishing.find_one({'role_db_id': source_role_id})
            source_random_tower = self.source_db.RandomTower.find_one({'role_db_id': source_role_id})
            source_capture = self.source_db.Capture.find_one({'role_db_id': source_role_id})
            source_hell_tower = self.source_db.HellRandomTower.find_one({'role_db_id': source_role_id})
            
            logger.info('[Transfer] Source data: cards=%d, gems=%d, chips=%d, contracts=%d, held_items=%d, emeras=%d',
                       len(source_cards), len(source_gems), len(source_chips),
                       len(source_contracts), len(source_held_items), len(source_emeras))
            
            # 2. 检查并处理目标区
            if progress_cb: progress_cb(10, 'Checking target area...')
            
            # 记录目标区旧角色ID（用于后续孤儿化处理）
            orphan_role_id = None
            
            if self.account_db and account_id:
                target_key = 'game.cn.%s' % target_area
                account = self.account_db.Account.find_one({'_id': account_id})
                if account:
                    role_infos = account.get('role_infos') or {}
                    existing = role_infos.get(target_key)
                    if existing:
                        # 检查是否是真正创建的角色（不是只进入游戏但没创建角色的空记录）
                        existing_id = existing.get('id')
                        existing_name = existing.get('name', '') or ''
                        existing_level = existing.get('level', 0)
                        has_real_role = bool(existing_id) and (existing_name or existing_level > 0)
                        
                        if has_real_role:
                            # 有真正的角色，记录ID，后续会孤儿化它的account_id
                            orphan_role_id = existing_id
                            logger.info('[Transfer] Target area has existing role「%s」(lv%d), will be orphaned', 
                                       existing_name, existing_level)
                        else:
                            # 只是进入过游戏但没创建角色的空记录，清理 Account.role_infos
                            logger.info('[Transfer] Target area has empty role_info (no real role), cleaning up')
                            self.account_db.Account.update_one(
                                {'_id': account_id},
                                {'$unset': {'role_infos.%s' % target_key: ''}}
                            )
                            # 【重要】即使是空记录，也要检查 Role 表是否有残留角色
                            if existing_id:
                                orphan_role_id = existing_id
                                logger.info('[Transfer] Empty role_info but has role_id=%s, will also orphan it', existing_id)
            
            # 【额外检查】直接查询目标区 Role 表，确保没有遗漏
            # 有些情况可能 Account.role_infos 没有记录，但 Role 表里有角色
            if account_id and not orphan_role_id:
                existing_role = self.target_db.Role.find_one({
                    'account_id': account_id,
                    'area': target_area
                })
                if existing_role:
                    orphan_role_id = existing_role.get('_id')
                    logger.info('[Transfer] Found orphan role in target DB (not in Account.role_infos): %s「%s」', 
                               orphan_role_id, existing_role.get('name', ''))
            
            # 3. 分配新UID
            if progress_cb: progress_cb(15, 'Creating target role...')
            new_uid = self._allocate_uid()
            new_name = self._generate_name(source_role.get('name', ''), source_role.get('area', 0))
            
            # 4. 创建目标区角色
            new_role_data = self._build_new_role(source_role, target_area, new_uid, new_name)
            result = self.target_db.Role.insert_one(new_role_data)
            new_role_id = result.inserted_id
            
            self.new_role_id = new_role_id
            self.new_uid = new_uid
            self.new_name = new_name
            logger.info('[Transfer] Role created: id=%s, uid=%s, name=%s', new_role_id, new_uid, new_name)
            
            # 5. 复制卡牌
            if progress_cb: progress_cb(25, 'Copying cards...')
            self._copy_cards(source_cards, new_role_id)
            logger.info('[Transfer] Cards copied: %d', len(self.card_id_map))
            
            # 6. 复制宝石
            if progress_cb: progress_cb(35, 'Copying gems...')
            self._copy_gems(source_gems, new_role_id)
            
            # 7. 复制芯片
            if progress_cb: progress_cb(40, 'Copying chips...')
            self._copy_chips(source_chips, new_role_id)
            
            # 8. 复制契约
            if progress_cb: progress_cb(45, 'Copying contracts...')
            self._copy_contracts(source_contracts, new_role_id)
            
            # 9. 复制携带物
            if progress_cb: progress_cb(50, 'Copying held items...')
            self._copy_held_items(source_held_items, new_role_id)
            
            # 9.5. 复制琉石
            if progress_cb: progress_cb(52, 'Copying emeras...')
            self._copy_emeras(source_emeras, new_role_id)
            logger.info('[Transfer] Emeras copied: %d', len(self.emera_id_map))
            
            # 10. 更新卡牌关联
            if progress_cb: progress_cb(55, 'Updating card references...')
            self._update_card_refs(source_cards)
            
            # 11. 复制图腾
            if source_totem:
                if progress_cb: progress_cb(60, 'Copying totem...')
                self._copy_totem(source_totem, new_role_id)
            
            # 12. 复制城镇
            if source_town:
                if progress_cb: progress_cb(70, 'Copying town...')
                self._copy_town(source_town, new_role_id)
            
            # 13. 复制抽奖记录（保底数据！）
            if source_lottery:
                if progress_cb: progress_cb(75, 'Copying lottery record...')
                self._copy_lottery(source_lottery, new_role_id)
            
            # 14. 复制钓鱼数据
            if source_fishing:
                if progress_cb: progress_cb(75, 'Copying fishing data...')
                self._copy_fishing(source_fishing, new_role_id)
            
            # 15. 复制试炼塔数据
            if source_random_tower:
                if progress_cb: progress_cb(78, 'Copying random tower...')
                self._copy_random_tower(source_random_tower, new_role_id)
            
            # 16. 复制捕捉数据
            if source_capture:
                if progress_cb: progress_cb(80, 'Copying capture...')
                self._copy_capture(source_capture, new_role_id)
            
            # 17. 复制地狱塔数据
            if source_hell_tower:
                if progress_cb: progress_cb(82, 'Copying hell tower...')
                self._copy_hell_tower(source_hell_tower, new_role_id)
            
            # 18. 更新Role所有CardDbId引用
            if progress_cb: progress_cb(88, 'Updating role references...')
            self._update_role_refs(new_role_id, source_role)
            
            # 19. 封禁源区角色
            if progress_cb: progress_cb(92, 'Disabling source role...')
            self._disable_source(source_role_id)
            
            # 19.5 孤儿化目标区旧角色（修改其account_id，让它不会被查询到）
            if orphan_role_id:
                if progress_cb: progress_cb(93, 'Orphaning old target role...')
                self._orphan_old_role(orphan_role_id, account_id)
            
            # 20. 更新Account（最后执行！）
            if self.account_db:
                if progress_cb: progress_cb(95, 'Updating account...')
                self._update_account(source_role, new_role_id, target_area)
            
            if progress_cb: progress_cb(100, 'Transfer complete')
            logger.info('[Transfer] ========== COMPLETE ==========')
            return True
            
        except Exception as e:
            logger.error('[Transfer] FAILED: %s', e)
            import traceback
            logger.error(traceback.format_exc())
            if not self.error_msg:
                self.error_msg = str(e)
            return False
    
    # ==================== 辅助方法 ====================
    
    def _allocate_uid(self):
        """分配新UID（确保不与现有角色冲突）
        
        使用原子操作确保并发安全：
        1. 用 $max 确保 Counter 不会小于当前最大 UID（原子操作）
        2. 用 $inc 原子递增获取新 UID
        """
        logger.info('[Transfer] Allocating UID, db=%s', self.target_db.name)
        
        # 1. 查询目标区当前最大 UID
        max_role = self.target_db.Role.find_one(
            {},
            {'uid': 1},
            sort=[('uid', -1)]
        )
        max_uid = max_role.get('uid', 0) if max_role else 0
        logger.info('[Transfer] Current max UID in target: %d', max_uid)
        
        # 2. 使用 $max 原子操作确保 Counter >= max_uid
        # 这样即使有并发，Counter 也只会增加不会减少
        self.target_db.Counter.update_one(
            {'_id': 'Role'},
            {'$max': {'id': max_uid}},
            upsert=True
        )
        
        # 3. 原子递增获取新 UID
        # find_one_and_update + $inc 是原子的，不会产生重复 UID
        result = self.target_db.Counter.find_one_and_update(
            {'_id': 'Role'},
            {'$inc': {'id': 1}},
            return_document=True,
            upsert=True
        )
        new_uid = result.get('id', 1)
        logger.info('[Transfer] Allocated UID: %d', new_uid)
        return new_uid
    
    def _generate_name(self, original_name, source_area):
        """生成不冲突的角色名"""
        # 先尝试原名
        if not self.target_db.Role.find_one({'name': original_name}):
            return original_name
        
        # 添加源区后缀
        new_name = '%s.s%d' % (original_name, source_area)
        if not self.target_db.Role.find_one({'name': new_name}):
            return new_name
        
        # 添加时间戳
        new_name = '%s.%d' % (original_name, int(time.time()))
        return new_name
    
    def _orphan_old_role(self, role_id, original_account_id):
        """孤儿化旧角色 - 修改其 account_id 让它不会被查询到
        
        不删除数据，只是把 account_id 改成带 'orphan_' 前缀的值
        这样 RoleGet 按 account_id 查询时不会找到这个角色
        
        同时删除 storage 缓存中的这个 Role，避免缓存返回旧数据
        """
        from bson import ObjectId
        
        # 生成孤儿 account_id（字符串格式，不是 ObjectId）
        # 格式: orphan_原account_id_时间戳
        orphan_account_id = 'orphan_%s_%d' % (str(original_account_id), int(time.time()))
        
        result = self.target_db.Role.update_one(
            {'_id': role_id},
            {'$set': {
                'account_id': orphan_account_id,
                'orphaned_at': time.time(),
                'original_account_id': original_account_id  # 保留原 account_id 以备恢复
            }}
        )
        
        if result.modified_count > 0:
            logger.info('[Transfer] Old role orphaned: %s, new account_id=%s', role_id, orphan_account_id)
            # 记录需要清除缓存的角色ID（在 daemon 中通过 RPC 清除）
            self.orphaned_role_id = role_id
        else:
            logger.warning('[Transfer] Failed to orphan old role: %s', role_id)
    
    def _delete_target_role(self, role_id, account_id, target_key):
        """删除目标区角色及所有关联数据，返回被删除角色的备份信息"""
        logger.info('[Transfer] Deleting target role and related data...')
        
        # 备份被删除角色的关键信息
        deleted_role_info = None
        target_role = self.target_db.Role.find_one({'_id': role_id})
        if target_role:
            deleted_role_info = {
                'role_db_id': role_id,
                'uid': target_role.get('uid', 0),
                'name': target_role.get('name', ''),
                'level': target_role.get('level', 0),
                'vip_level': target_role.get('vip_level', 0),
                'gold': target_role.get('gold', 0),
                'rmb': target_role.get('rmb', 0),
                'delete_time': time.time()
            }
            logger.info('[Transfer] Backup deleted role info: uid=%d, name=%s, level=%d',
                       deleted_role_info['uid'], deleted_role_info['name'], deleted_role_info['level'])
        
        # 删除关联数据
        self.target_db.RoleCard.delete_many({'role_db_id': role_id})
        self.target_db.RoleGem.delete_many({'role_db_id': role_id})
        self.target_db.RoleChip.delete_many({'role_db_id': role_id})
        self.target_db.RoleContract.delete_many({'role_db_id': role_id})
        self.target_db.RoleHeldItem.delete_many({'role_db_id': role_id})
        self.target_db.RoleEmera.delete_many({'role_db_id': role_id})
        self.target_db.Totem.delete_many({'role_db_id': role_id})
        self.target_db.Town.delete_many({'role_db_id': role_id})
        self.target_db.LotteryRecord.delete_many({'role_db_id': role_id})
        self.target_db.Fishing.delete_many({'role_db_id': role_id})
        self.target_db.RandomTower.delete_many({'role_db_id': role_id})
        self.target_db.Capture.delete_many({'role_db_id': role_id})
        self.target_db.HellRandomTower.delete_many({'role_db_id': role_id})
        
        # 删除角色
        self.target_db.Role.delete_one({'_id': role_id})
        
        # 从Account移除
        if self.account_db:
            self.account_db.Account.update_one(
                {'_id': account_id},
                {'$unset': {'role_infos.%s' % target_key: ''}}
            )
        
        logger.info('[Transfer] Target role deleted: %s', role_id)
        return deleted_role_info
    
    def _build_new_role(self, src, target_area, new_uid, new_name):
        """构建新角色数据"""
        now = time.time()
        source_area = src.get('area', 0)
        
        # 复制源角色数据
        new_role = copy.deepcopy(src)
        
        # 移除 _id（让 MongoDB 自动生成）
        new_role.pop('_id', None)
        
        # 设置新的基础信息
        new_role['uid'] = new_uid
        new_role['name'] = new_name
        new_role['area'] = target_area
        new_role['created_time'] = now
        new_role['last_time'] = now
        
        # 转区标记
        new_role['transfer_times'] = (src.get('transfer_times') or 0) + 1
        new_role['last_transfer_time'] = now
        new_role['transfer_from_area'] = source_area
        new_role['transfer_flag'] = False  # 新角色不是"已转走"
        new_role['disable_flag'] = False
        
        # 清空的字段（社交/跨服/需要重建引用的）
        clear_fields = [
            'union_db_id', 'union_join_que', 'society_db_id',
            'mailbox', 'read_mailbox', 'blacklist',
            'pvp_record_db_id', 'craft_record_db_id',
            'cross_arena_record_db_id', 'cross_craft_record_db_id',
            'cross_online_fight_record_db_id', 'cross_mine_record_db_id',
            'cross_union_fight_record_db_id', 'union_fight_record_db_id',
            'gym_record_db_id', 'hunting_record_db_id', 'mimicry_db_id',
            'brave_challenge_record_db_id', 'normal_brave_challenge_record_db_id',
            'random_tower_db_id',
            'endless_tower_db_id', 'hell_random_tower_db_id',
            'capture_db_id', 'fishing_db_id', 'cross_fishing_db_id',
            'cross_town_party_db_id', 'strange_meteor_db_id',
            'reunion_record_db_id', 'fix_shop_db_id', 'mystery_shop_db_id',
            'frag_shop_db_id', 'equip_shop_db_id', 'town_shop_db_id',
            'totem_shop_db_id', 'union_shop_db_id', 'fishing_shop_db_id',
            'random_tower_shop_db_id', 'explorer_shop_db_id',
            'daily_record_db_id', 'weekly_record_db_id', 'monthly_record_db_id',
            'lottery_db_id', 'clone_deploy_card_db_id',
            'recharges_cache', 'yy_endtime', 'yy_begintime', 'deployments_sync',
            # 元素挑战相关（参考合区脚本）
            'clone_room_db_id',
            # 以下字段会在复制时重新设置（如果源数据存在）
            'totem_db_id', 'town_db_id'
        ]
        for field in clear_fields:
            new_role[field] = None
        
        # 需要重置为 0 的整数字段（参考合区脚本）
        zero_fields = [
            'global_mail_idx',           # 全局邮件索引
            'clone_daily_be_kicked_num', # 元素挑战每日被踢次数
            'clone_room_create_time',    # 元素挑战房间创建时间
        ]
        for field in zero_fields:
            new_role[field] = 0
        
        # 空列表字段
        list_fields = ['union_join_que', 'mailbox', 'read_mailbox', 'blacklist', 'recharges_cache']
        for field in list_fields:
            new_role[field] = []
        
        # 空字典字段
        dict_fields = ['yy_endtime', 'yy_begintime', 'deployments_sync']
        for field in dict_fields:
            new_role[field] = {}
        
        # 清空重聚活动中的邀请记录（invite_time 的 key 是其他玩家的 RoleId）
        reunion = new_role.get('reunion')
        if reunion and isinstance(reunion, dict):
            reunion['invite_time'] = {}
        
        # 卡牌相关字段（先清空，后面更新）
        new_role['cards'] = []
        new_role['gems'] = []
        new_role['chips'] = []
        new_role['contracts'] = []
        new_role['held_items'] = []
        new_role['emeras'] = []
        
        # 布阵相关
        # 注意：Go 端是固定长度数组，必须保持正确长度
        # 只有 battle_cards 是必须转换的（芯片入口依赖），其他有容错处理
        new_role['battle_cards'] = [None] * 6           # [6]document.ID，后续转换更新（必须）
        new_role['battle_aid_cards'] = {}               # 清空，玩家重新配置
        new_role['huodong_cards'] = {}                  # 清空，回退到主布阵
        new_role['huodong_aid_cards'] = {}              # 清空，回退到主助战
        new_role['battle_cards_multi'] = {}             # 清空，玩家重新配置
        new_role['huodong_cards_multi'] = {}            # 清空
        new_role['ready_cards'] = {}                    # 清空，玩家重新配置
        new_role['card_embattle'] = {}                  # 游戏自动初始化
        new_role['top10_cards'] = [None] * 10           # [10]CardSpec，清空
        new_role['top12_cards'] = [None] * 12           # [12]CardSpec，清空
        new_role['top_cards'] = []                      # 清空
        new_role['follow_sprite'] = []                  # 清空，玩家重新设置
        # 陨石：保留等级和引用（引用稍后在 _update_role_refs 中转换）
        # 这里先 deepcopy 保留原始数据，后面更新引用
        new_role['meteorites'] = copy.deepcopy(src.get('meteorites') or {})
        new_role['chip_plans'] = {}
        
        # 星转援助席位（包含卡牌ID，清空让游戏自动初始化）
        new_role['card_star_swap_fields'] = []
        new_role['card_star_swap_times'] = {}
        new_role['card_star_swap_times_cd'] = {}
        new_role['card_star_swap_times_deliver_record'] = {}
        
        return new_role
    
    # ==================== 辅助转换方法 ====================
    
    def _to_object_id(self, val):
        """统一转换为 ObjectId 类型（处理 bytes/str/unicode/ObjectId）"""
        from bson import ObjectId
        
        if val is None:
            return None
        if isinstance(val, ObjectId):
            return val
        if isinstance(val, bytes):
            try:
                return ObjectId(val)
            except Exception as e:
                logger.warning('[Transfer] _to_object_id bytes failed: %s, err=%s', repr(val), e)
                return None
        # Python 2.7: basestring 同时匹配 str 和 unicode
        if isinstance(val, basestring):
            try:
                return ObjectId(val)
            except Exception as e:
                logger.warning('[Transfer] _to_object_id str/unicode failed: %s, err=%s', repr(val), e)
                return None
        # 未知类型
        logger.warning('[Transfer] _to_object_id unknown type: %s (type=%s)', repr(val), type(val).__name__)
        return val
    
    def _convert_card_ref(self, ref):
        """转换卡牌引用（可能是 ObjectId、bytes 或字典）"""
        if ref is None:
            return None
        
        if isinstance(ref, dict):
            # 如果是字典，提取 id 字段
            old_id = ref.get('id') or ref.get('_id')
            old_id = self._to_object_id(old_id)
            return self.card_id_map.get(old_id)
        
        # 直接是 ObjectId 或 bytes
        old_id = self._to_object_id(ref)
        return self.card_id_map.get(old_id)
    
    def _convert_gem_ref(self, ref):
        """转换宝石引用"""
        old_id = self._to_object_id(ref)
        return self.gem_id_map.get(old_id) if old_id else None
    
    def _convert_chip_ref(self, ref):
        """转换芯片引用"""
        old_id = self._to_object_id(ref)
        return self.chip_id_map.get(old_id) if old_id else None
    
    def _convert_held_item_ref(self, ref):
        """转换携带物引用"""
        old_id = self._to_object_id(ref)
        return self.held_item_id_map.get(old_id) if old_id else None
    
    def _convert_contract_ref(self, ref):
        """转换契约引用"""
        old_id = self._to_object_id(ref)
        return self.contract_id_map.get(old_id) if old_id else None
    
    # ==================== 复制数据 ====================
    
    def _copy_cards(self, cards, new_role_id):
        """复制卡牌，建立ID映射"""
        for c in cards:
            old_id = c.get('_id')
            new_card = copy.deepcopy(c)
            new_card.pop('_id', None)
            new_card['role_db_id'] = new_role_id
            # 清空关联引用（后面更新）
            new_card['gems'] = {}
            new_card['chip'] = {}
            new_card['held_item'] = None
            new_card['contracts'] = {}
            new_card['emeras'] = {}  # 琉石引用也需要清空
            # 注意：保留 meteorite_index，后面会更新陨石中的卡牌引用
            
            result = self.target_db.RoleCard.insert_one(new_card)
            self.card_id_map[old_id] = result.inserted_id
        
        # 调试：记录 card_id_map 的键类型
        if self.card_id_map:
            sample_key = next(iter(self.card_id_map.keys()))
            logger.info('[Transfer] card_id_map sample key: %s (type=%s), total=%d',
                       sample_key, type(sample_key).__name__, len(self.card_id_map))
    
    def _copy_gems(self, gems, new_role_id):
        """复制宝石"""
        for g in gems:
            old_id = g.get('_id')
            old_card_id = g.get('card_db_id')
            new_card_id = self._convert_card_ref(old_card_id) if old_card_id else None
            
            new_gem = copy.deepcopy(g)
            new_gem.pop('_id', None)
            new_gem['role_db_id'] = new_role_id
            # 卡牌引用：必须显式设置（None 或新ID），因为 deepcopy 会复制旧的无效ID
            new_gem['card_db_id'] = new_card_id  # 可能是 None，表示未装备
            
            result = self.target_db.RoleGem.insert_one(new_gem)
            self.gem_id_map[old_id] = result.inserted_id
    
    def _copy_chips(self, chips, new_role_id):
        """复制芯片"""
        unmapped_count = 0
        for c in chips:
            old_id = c.get('_id')
            old_card_id = c.get('card_db_id')
            new_card_id = self._convert_card_ref(old_card_id) if old_card_id else None
            
            # 调试：如果有 old_card_id 但转换后为 None，记录日志
            if old_card_id and new_card_id is None:
                unmapped_count += 1
                if unmapped_count <= 5:  # 只记录前5个
                    logger.warning('[Transfer] Chip %s: card_db_id=%s (type=%s) not found in card_id_map',
                                 old_id, old_card_id, type(old_card_id).__name__)
            
            new_chip = copy.deepcopy(c)
            new_chip.pop('_id', None)
            new_chip['role_db_id'] = new_role_id
            # 卡牌引用：必须显式设置（None 或新ID），因为 deepcopy 会复制旧的无效ID
            new_chip['card_db_id'] = new_card_id  # 可能是 None，表示未装备
            
            result = self.target_db.RoleChip.insert_one(new_chip)
            self.chip_id_map[old_id] = result.inserted_id
        
        if unmapped_count > 0:
            logger.warning('[Transfer] Total %d chips had card_db_id but card not found', unmapped_count)
    
    def _copy_contracts(self, contracts, new_role_id):
        """复制契约"""
        for c in contracts:
            old_id = c.get('_id')
            old_card_id = c.get('card_db_id')
            new_card_id = self._convert_card_ref(old_card_id) if old_card_id else None
            
            new_contract = copy.deepcopy(c)
            new_contract.pop('_id', None)
            new_contract['role_db_id'] = new_role_id
            # 卡牌引用：必须显式设置（None 或新ID），因为 deepcopy 会复制旧的无效ID
            new_contract['card_db_id'] = new_card_id  # 可能是 None，表示未装备
            
            result = self.target_db.RoleContract.insert_one(new_contract)
            self.contract_id_map[old_id] = result.inserted_id
    
    def _copy_held_items(self, items, new_role_id):
        """复制携带物"""
        for i in items:
            old_id = i.get('_id')
            old_card_id = i.get('card_db_id')
            new_card_id = self._convert_card_ref(old_card_id) if old_card_id else None
            
            new_item = copy.deepcopy(i)
            new_item.pop('_id', None)
            new_item['role_db_id'] = new_role_id
            # 卡牌引用：必须显式设置（None 或新ID），因为 deepcopy 会复制旧的无效ID
            new_item['card_db_id'] = new_card_id  # 可能是 None，表示未装备
            
            result = self.target_db.RoleHeldItem.insert_one(new_item)
            self.held_item_id_map[old_id] = result.inserted_id
    
    def _copy_emeras(self, emeras, new_role_id):
        """复制琉石"""
        for e in emeras:
            old_id = e.get('_id')
            old_card_id = e.get('card_db_id')
            new_card_id = self._convert_card_ref(old_card_id) if old_card_id else None
            
            new_emera = copy.deepcopy(e)
            new_emera.pop('_id', None)
            new_emera['role_db_id'] = new_role_id
            # 卡牌引用：必须显式设置（None 或新ID），因为 deepcopy 会复制旧的无效ID
            new_emera['card_db_id'] = new_card_id  # 可能是 None，表示未镶嵌
            
            result = self.target_db.RoleEmera.insert_one(new_emera)
            self.emera_id_map[old_id] = result.inserted_id
    
    def _convert_emera_ref(self, ref):
        """转换琉石引用"""
        old_id = self._to_object_id(ref)
        return self.emera_id_map.get(old_id) if old_id else None
    
    def _copy_totem(self, totem, new_role_id):
        """复制图腾"""
        new_totem = copy.deepcopy(totem)
        new_totem.pop('_id', None)
        new_totem['role_db_id'] = new_role_id
        result = self.target_db.Totem.insert_one(new_totem)
        
        # 更新Role的totem_db_id引用
        self.target_db.Role.update_one(
            {'_id': new_role_id},
            {'$set': {'totem_db_id': result.inserted_id}}
        )
    
    def _copy_town(self, town, new_role_id):
        """复制城镇（含CardDbId转换）"""
        new_town = copy.deepcopy(town)
        new_town.pop('_id', None)
        new_town['role_db_id'] = new_role_id
        
        # 清空派对相关数据（跨服数据，包含其他玩家的 RoleId 引用）
        new_town['party'] = None
        new_town['party_room'] = None
        
        # 清空家园访问记录（包含其他玩家的 RoleId 引用）
        home = new_town.get('home')
        if home and isinstance(home, dict):
            home['visit_history'] = []
        
        # 转换 ContinuousFactory 中的 CardIds (map[Integer]document.ID)
        continuous_factory = new_town.get('continuous_factory') or {}
        for bid, factory in continuous_factory.items():
            if factory and factory.get('card_ids'):
                old_card_ids = factory['card_ids']
                if isinstance(old_card_ids, dict):
                    new_card_ids = {}
                    for slot, cid in old_card_ids.items():
                        new_cid = self._convert_card_ref(cid)
                        if new_cid:
                            new_card_ids[slot] = new_cid
                    factory['card_ids'] = new_card_ids
                elif isinstance(old_card_ids, list):
                    converted = [self._convert_card_ref(cid) for cid in old_card_ids]
                    factory['card_ids'] = [cid for cid in converted if cid is not None]
        
        # 转换 OrderFactory 中的 CardIds (map[Integer]document.ID)
        order_factory = new_town.get('order_factory') or {}
        for bid, factory in order_factory.items():
            if factory and factory.get('card_ids'):
                old_card_ids = factory['card_ids']
                if isinstance(old_card_ids, dict):
                    new_card_ids = {}
                    for slot, cid in old_card_ids.items():
                        new_cid = self._convert_card_ref(cid)
                        if new_cid:
                            new_card_ids[slot] = new_cid
                    factory['card_ids'] = new_card_ids
                elif isinstance(old_card_ids, list):
                    converted = [self._convert_card_ref(cid) for cid in old_card_ids]
                    factory['card_ids'] = [cid for cid in converted if cid is not None]
        
        # 转换 Cards（key是CardDbId，MongoDB要求键必须是字符串）
        old_cards = new_town.get('cards') or {}
        new_cards = {}
        for old_cid, card_state in old_cards.items():
            new_cid = self._convert_card_ref(old_cid)
            if new_cid:
                # MongoDB 键必须是字符串
                new_cards[str(new_cid)] = card_state
        new_town['cards'] = new_cards
        
        # 转换 FactoryTeams 中的 cards {idx: TownFactoryTeam{cards: {slot: cardId}}}
        factory_teams = new_town.get('factory_teams') or {}
        if isinstance(factory_teams, dict):
            for idx, team in factory_teams.items():
                if team and team.get('cards'):
                    old_cards_map = team['cards']
                    if isinstance(old_cards_map, dict):
                        new_team_cards = {}
                        for slot, cid in old_cards_map.items():
                            new_cid = self._convert_card_ref(cid)
                            if new_cid:
                                new_team_cards[slot] = new_cid
                        team['cards'] = new_team_cards
                    elif isinstance(old_cards_map, list):
                        # 兼容旧格式
                        converted = [self._convert_card_ref(cid) for cid in old_cards_map]
                        team['cards'] = [cid for cid in converted if cid is not None]
        
        # 转换 Adventure.Missions 中的 CardDbIds ([]document.ID)
        adventure = new_town.get('adventure') or {}
        if adventure.get('missions'):
            for area_id, mission in adventure['missions'].items():
                if mission and mission.get('card_db_ids'):
                    old_db_ids = mission['card_db_ids']
                    if isinstance(old_db_ids, list):
                        converted = [self._convert_card_ref(cid) for cid in old_db_ids]
                        mission['card_db_ids'] = [cid for cid in converted if cid is not None]
        
        result = self.target_db.Town.insert_one(new_town)
        
        # 更新Role的town_db_id引用
        self.target_db.Role.update_one(
            {'_id': new_role_id},
            {'$set': {'town_db_id': result.inserted_id}}
        )
    
    def _copy_lottery(self, lottery, new_role_id):
        """复制抽奖记录（保底数据）"""
        new_lottery = copy.deepcopy(lottery)
        new_lottery.pop('_id', None)
        new_lottery['role_db_id'] = new_role_id
        result = self.target_db.LotteryRecord.insert_one(new_lottery)
        
        # 更新Role的lottery_db_id引用
        self.target_db.Role.update_one(
            {'_id': new_role_id},
            {'$set': {'lottery_db_id': result.inserted_id}}
        )
        logger.info('[Transfer] LotteryRecord copied')
    
    def _copy_fishing(self, fishing, new_role_id):
        """复制钓鱼数据"""
        new_fishing = copy.deepcopy(fishing)
        new_fishing.pop('_id', None)
        new_fishing['role_db_id'] = new_role_id
        # 清空跨服/每周相关数据
        new_fishing['last_play_date'] = 0
        new_fishing['point'] = 0
        new_fishing['special_fish_num'] = 0
        new_fishing['last_week'] = 0
        new_fishing['week_record'] = {}
        
        result = self.target_db.Fishing.insert_one(new_fishing)
        
        # 更新Role的fishing_db_id引用
        self.target_db.Role.update_one(
            {'_id': new_role_id},
            {'$set': {'fishing_db_id': result.inserted_id}}
        )
        logger.info('[Transfer] Fishing data copied')
    
    def _copy_random_tower(self, tower, new_role_id):
        """复制试炼塔数据（保留历史最高成绩）"""
        new_tower = copy.deepcopy(tower)
        new_tower.pop('_id', None)
        new_tower['role_db_id'] = new_role_id
        
        # 清空当前进行中的数据，保留历史成绩
        # room 初始值为 1（第一层），不能是 0！
        new_tower['room'] = 1
        new_tower['boards'] = {}
        new_tower['room_info'] = {'next_room_scope': [-1, 99999]}  # 初始范围
        new_tower['card_states'] = {}
        new_tower['enemy_states'] = {}
        new_tower['buffs'] = []
        new_tower['day_point'] = 0
        new_tower['day_rank'] = 0
        new_tower['buff_lib'] = []
        new_tower['buff_time'] = {}
        new_tower['event_time'] = {}
        new_tower['skill_used'] = {}
        new_tower['jump_info'] = {}
        new_tower['jump_step'] = 0
        new_tower['last_date'] = 0  # 重置日期，让游戏自动刷新
        # 保留: history_room, history_point, point_award, point_award_version, last_room
        
        result = self.target_db.RandomTower.insert_one(new_tower)
        
        # 更新Role引用
        self.target_db.Role.update_one(
            {'_id': new_role_id},
            {'$set': {'random_tower_db_id': result.inserted_id}}
        )
        logger.info('[Transfer] RandomTower copied (history_room=%s, history_point=%s)',
                   tower.get('history_room'), tower.get('history_point'))
    
    def _copy_capture(self, capture, new_role_id):
        """复制捕捉数据（捕捉等级、经验是核心养成）"""
        new_capture = copy.deepcopy(capture)
        new_capture.pop('_id', None)
        new_capture['role_db_id'] = new_role_id
        
        # 清空临时/限时数据
        new_capture['limit_sprites'] = []
        new_capture['cd_record'] = {}
        # 保留: level, exp, level_exp, success_sum, gate_sprites, gate_sprites_weight, active_sum
        
        result = self.target_db.Capture.insert_one(new_capture)
        
        # 更新Role引用
        self.target_db.Role.update_one(
            {'_id': new_role_id},
            {'$set': {'capture_db_id': result.inserted_id}}
        )
        logger.info('[Transfer] Capture copied (level=%s, exp=%s, success_sum=%s)',
                   capture.get('level'), capture.get('exp'), capture.get('success_sum'))
    
    def _copy_hell_tower(self, tower, new_role_id):
        """复制地狱塔数据（保留历史最高成绩）"""
        new_tower = copy.deepcopy(tower)
        new_tower.pop('_id', None)
        new_tower['role_db_id'] = new_role_id
        
        # 清空当前进行中的数据，保留历史成绩
        new_tower['room'] = 0
        new_tower['theme'] = 0
        new_tower['round'] = 'closed'
        new_tower['boards'] = {}
        new_tower['hidden_boards'] = []
        new_tower['room_info'] = {}
        new_tower['prepare_cards'] = []
        new_tower['battle_cards'] = []
        new_tower['battle_cards_multi'] = {}
        new_tower['battle_result_multi'] = {}
        new_tower['card_states'] = {}
        new_tower['enemy_states'] = {}
        new_tower['enemy_states_multi'] = {}
        new_tower['buffs'] = []
        new_tower['items'] = {}
        new_tower['point'] = 0
        new_tower['day_rank'] = 0
        new_tower['reset_times'] = 0
        new_tower['buff_lib'] = []
        new_tower['buff_time'] = {}
        new_tower['event_time'] = {}
        new_tower['skill_used'] = {}
        new_tower['jump_info'] = {}
        new_tower['jump_step'] = 0
        # 保留: history_room, history_point, point_award, last_room
        
        result = self.target_db.HellRandomTower.insert_one(new_tower)
        
        # 更新Role引用
        self.target_db.Role.update_one(
            {'_id': new_role_id},
            {'$set': {'hell_random_tower_db_id': result.inserted_id}}
        )
        logger.info('[Transfer] HellRandomTower copied (history_room=%s, history_point=%s)',
                   tower.get('history_room'), tower.get('history_point'))
    
    # ==================== 更新引用 ====================
    
    def _update_card_refs(self, source_cards):
        """更新卡牌的宝石/芯片/携带物/契约引用"""
        for c in source_cards:
            old_id = c.get('_id')
            # 使用类型转换查找
            old_id_converted = self._to_object_id(old_id)
            new_id = self.card_id_map.get(old_id_converted)
            if not new_id:
                continue
            
            update = {}
            
            # 宝石 {position: gem_db_id}
            if c.get('gems'):
                new_gems = {}
                for pos, old_gem_id in c['gems'].items():
                    new_gem_id = self._convert_gem_ref(old_gem_id)
                    if new_gem_id:
                        new_gems[pos] = new_gem_id
                if new_gems:
                    update['gems'] = new_gems
            
            # 芯片 {position: chip_db_id}
            if c.get('chip'):
                new_chips = {}
                for pos, old_chip_id in c['chip'].items():
                    new_chip_id = self._convert_chip_ref(old_chip_id)
                    if new_chip_id:
                        new_chips[pos] = new_chip_id
                if new_chips:
                    update['chip'] = new_chips
            
            # 携带物
            if c.get('held_item'):
                new_held = self._convert_held_item_ref(c['held_item'])
                if new_held:
                    update['held_item'] = new_held
            
            # 契约 {position: ContractSlot{contract_db_id, unlock}}
            if c.get('contracts'):
                new_contracts = {}
                for pos, slot in c['contracts'].items():
                    if slot and isinstance(slot, dict):
                        # ContractSlot 结构: {contract_db_id: ObjectId, unlock: bool}
                        old_contract_id = slot.get('contract_db_id')
                        new_contract_id = self._convert_contract_ref(old_contract_id)
                        if new_contract_id:
                            new_contracts[pos] = {
                                'contract_db_id': new_contract_id,
                                'unlock': slot.get('unlock', False)
                            }
                if new_contracts:
                    update['contracts'] = new_contracts
            
            # 琉石 {position: emera_db_id}
            if c.get('emeras'):
                new_emeras = {}
                for pos, old_emera_id in c['emeras'].items():
                    new_emera_id = self._convert_emera_ref(old_emera_id)
                    if new_emera_id:
                        new_emeras[pos] = new_emera_id
                if new_emeras:
                    update['emeras'] = new_emeras
            
            if update:
                self.target_db.RoleCard.update_one({'_id': new_id}, {'$set': update})
    
    def _update_role_refs(self, new_role_id, source):
        """更新Role的核心资产引用
        
        只复制核心资产数据，布阵/展示相关数据由游戏自动初始化
        """
        update = {
            # 基础资产列表
            'cards': list(self.card_id_map.values()),
            'gems': list(self.gem_id_map.values()),
            'chips': list(self.chip_id_map.values()),
            'contracts': list(self.contract_id_map.values()),
            'held_items': list(self.held_item_id_map.values()),
            'emeras': list(self.emera_id_map.values()),
        }
        
        # === 以下是需要复制的核心数据（卡牌附属功能）===
        
        # 1. card_merge 卡牌融合数据
        # 结构: {markID: CardMergeInfo{id: CardDbId, merge_cards: [cardDbId], ...}}
        old_merge = source.get('card_merge') or {}
        if old_merge:
            new_merge = {}
            for merge_id, merge_data in old_merge.items():
                if merge_data:
                    new_data = copy.deepcopy(merge_data)
                    
                    # 转换 id（合体卡主卡的 CardDbId）
                    if merge_data.get('id'):
                        new_main_id = self._convert_card_ref(merge_data['id'])
                        if new_main_id:
                            new_data['id'] = new_main_id
                        else:
                            # 主卡不存在，跳过整个融合记录
                            logger.warning('[Transfer] card_merge %s main card not found, skipping', merge_id)
                            continue
                    
                    # 转换 merge_cards（卡牌ID列表）
                    if merge_data.get('merge_cards'):
                        converted = [self._convert_card_ref(oid) for oid in merge_data['merge_cards']]
                        new_data['merge_cards'] = [cid for cid in converted if cid is not None]
                    
                    new_merge[merge_id] = new_data
            update['card_merge'] = new_merge
        
        # 2. badges 徽章数据
        # Go 结构: map[Integer]Badge，Badge = {awake, talents, guards: {pos: cardId}, positions}
        old_badges = source.get('badges') or {}
        if old_badges:
            new_badges = {}
            for badge_id, badge_data in old_badges.items():
                if badge_data and isinstance(badge_data, dict):
                    new_data = copy.deepcopy(badge_data)
                    
                    # 转换 guards（守护精灵）{position(整数): cardId(ObjectId)}
                    old_guards = badge_data.get('guards') or {}
                    if old_guards and isinstance(old_guards, dict):
                        new_guards = {}
                        for pos, old_card_id in old_guards.items():
                            if old_card_id:
                                new_cid = self._convert_card_ref(old_card_id)
                                if new_cid:
                                    new_guards[pos] = new_cid
                                # 如果转换失败，不保留该位置（卡牌可能已分解）
                        new_data['guards'] = new_guards
                    
                    new_badges[badge_id] = new_data
            update['badges'] = new_badges
        
        # 3. chip_plans 芯片方案数据
        # Go 结构: map[Integer]ChipPlan，ChipPlan = {created_time, chips: {pos: chipId}, name}
        old_plans = source.get('chip_plans') or {}
        if old_plans:
            new_plans = {}
            for plan_id, plan_data in old_plans.items():
                if plan_data and isinstance(plan_data, dict):
                    new_plan = copy.deepcopy(plan_data)
                    # 转换 chips 字段中的芯片ID（值，不是键）
                    old_chips = plan_data.get('chips') or {}
                    if old_chips and isinstance(old_chips, dict):
                        new_chips = {}
                        for pos, old_chip_id in old_chips.items():
                            new_chip_id = self._convert_chip_ref(old_chip_id)
                            if new_chip_id:
                                new_chips[pos] = new_chip_id
                        new_plan['chips'] = new_chips
                    new_plans[plan_id] = new_plan
            update['chip_plans'] = new_plans
        
        # 4. battle_cards 战斗布阵 【必须转换，芯片入口依赖此字段】
        # Go 结构: [6]document.ID
        old_battle_cards = source.get('battle_cards') or []
        if old_battle_cards:
            new_battle_cards = []
            for old_card_id in old_battle_cards:
                if old_card_id:
                    new_cid = self._convert_card_ref(old_card_id)
                    new_battle_cards.append(new_cid)  # 可能是 None
                else:
                    new_battle_cards.append(None)
            # 确保长度为 6
            while len(new_battle_cards) < 6:
                new_battle_cards.append(None)
            update['battle_cards'] = new_battle_cards[:6]
        
        # 5. meteorites 陨石数据（转换卡牌和携带物引用）
        # Go 结构: map[Integer]MeteoriteData，MeteoriteData = {level, card, helditems: {pos: heldItemId}, ...}
        old_meteorites = source.get('meteorites') or {}
        if old_meteorites:
            new_meteorites = {}
            for idx, data in old_meteorites.items():
                if data and isinstance(data, dict):
                    new_data = {
                        'level': data.get('level', 0),
                        'card': None,
                        'helditems': {},
                        'helditem_cd': data.get('helditem_cd') or {},
                        'card_cd': data.get('card_cd', 0),
                    }
                    # 转换卡牌引用
                    old_card = data.get('card')
                    if old_card:
                        new_card = self._convert_card_ref(old_card)
                        if new_card:
                            new_data['card'] = new_card
                    # 转换携带物引用 {位置: 携带物ID}
                    old_helditems = data.get('helditems') or {}
                    if old_helditems and isinstance(old_helditems, dict):
                        new_helditems = {}
                        for pos, old_held_id in old_helditems.items():
                            if old_held_id:
                                new_held_id = self._convert_held_item_ref(old_held_id)
                                if new_held_id:
                                    new_helditems[pos] = new_held_id
                        new_data['helditems'] = new_helditems
                    new_meteorites[idx] = new_data
            update['meteorites'] = new_meteorites
        
        # === 以下数据不复制，新区重新配置（有容错处理，不会报错）===
        # - battle_aid_cards (战斗助战，代码有 or {} 容错)
        # - huodong_cards, huodong_aid_cards (活动布阵，为空回退到主布阵)
        # - battle_cards_multi (多队布阵，为空需要重新配置)
        # - huodong_cards_multi (活动多队布阵)
        # - ready_cards (预设队伍，为空需要重新配置)
        # - top_cards, top10_cards, top12_cards (展示卡牌)
        # - follow_sprite (跟随精灵，为空主城不显示)
        # - card_embattle (布阵助战，游戏自动初始化)
        
        self.target_db.Role.update_one({'_id': new_role_id}, {'$set': update})
    
    # ==================== 源角色处理 ====================
    
    def _disable_source(self, role_id):
        """封禁源区角色"""
        self.source_db.Role.update_one(
            {'_id': role_id},
            {'$set': {
                'transfer_flag': True,
                'disable_flag': True
            }}
        )
    
    # ==================== Account更新 ====================
    
    def _update_account(self, source, new_role_id, target_area):
        """更新Account.role_infos（必须最后执行！）"""
        if not self.account_db:
            return
        
        account_id = source.get('account_id')
        if not account_id:
            return
        
        key = 'game.cn.%s' % target_area
        info = {
            'id': new_role_id,
            'name': self.new_name,
            'level': source.get('level', 1),
            'logo': source.get('logo', 1),
            'vip': source.get('vip_level', 0),
            'frame': source.get('frame', 1),
        }
        
        self.account_db.Account.update_one(
            {'_id': account_id},
            {'$set': {'role_infos.%s' % key: info}}
        )
        
        logger.info('[Transfer] Account updated: %s -> %s', account_id, key)
    
    # ==================== 数据验证 ====================
    
    def verify_transfer(self, source_role_id, new_role_id):
        """验证转区数据一致性
        
        对比源区和目标区的关键数据，返回验证结果
        
        Returns:
            dict: {
                'success': bool,      # 验证是否通过
                'errors': [],         # 错误列表（严重问题）
                'warnings': [],       # 警告列表（可接受的差异）
                'details': {}         # 详细对比数据
            }
        """
        result = {
            'success': True,
            'errors': [],
            'warnings': [],
            'details': {}
        }
        
        try:
            # 读取源区和目标区角色数据
            source_role = self.source_db.Role.find_one({'_id': source_role_id})
            target_role = self.target_db.Role.find_one({'_id': new_role_id})
            
            if not source_role:
                result['errors'].append('源区角色不存在')
                result['success'] = False
                return result
            
            if not target_role:
                result['errors'].append('目标区角色不存在')
                result['success'] = False
                return result
            
            # 1. 验证货币（必须完全一致）
            currency_fields = [
                'gold', 'rmb', 'stamina', 'skill_point', 'talent_point',
                'coin1', 'coin2', 'coin3', 'coin4', 'coin5',
                'coin6', 'coin7', 'coin8', 'coin9', 'coin10',
                'coin11', 'coin12', 'coin13', 'coin14', 'coin15',
                'coin16', 'coin17', 'coin18', 'coin19', 'coin20',
                'coin21', 'coin22'
            ]
            for field in currency_fields:
                src_val = source_role.get(field, 0) or 0
                tgt_val = target_role.get(field, 0) or 0
                if src_val != tgt_val:
                    result['errors'].append('%s 不一致: 源=%s, 目标=%s' % (field, src_val, tgt_val))
                    result['success'] = False
            
            # 2. 验证基础属性
            basic_fields = ['level', 'vip_level']
            for field in basic_fields:
                src_val = source_role.get(field, 0) or 0
                tgt_val = target_role.get(field, 0) or 0
                if src_val != tgt_val:
                    result['errors'].append('%s 不一致: 源=%s, 目标=%s' % (field, src_val, tgt_val))
                    result['success'] = False
            
            # 3. 验证资产数量
            # 卡牌数量
            source_cards = list(self.source_db.RoleCard.find({'role_db_id': source_role_id}))
            target_cards = list(self.target_db.RoleCard.find({'role_db_id': new_role_id}))
            result['details']['cards'] = {'source': len(source_cards), 'target': len(target_cards)}
            if len(source_cards) != len(target_cards):
                result['errors'].append('卡牌数量不一致: 源=%d, 目标=%d' % (len(source_cards), len(target_cards)))
                result['success'] = False
            
            # 宝石数量
            source_gems = list(self.source_db.RoleGem.find({'role_db_id': source_role_id}))
            target_gems = list(self.target_db.RoleGem.find({'role_db_id': new_role_id}))
            result['details']['gems'] = {'source': len(source_gems), 'target': len(target_gems)}
            if len(source_gems) != len(target_gems):
                result['errors'].append('宝石数量不一致: 源=%d, 目标=%d' % (len(source_gems), len(target_gems)))
                result['success'] = False
            
            # 芯片数量
            source_chips = list(self.source_db.RoleChip.find({'role_db_id': source_role_id}))
            target_chips = list(self.target_db.RoleChip.find({'role_db_id': new_role_id}))
            result['details']['chips'] = {'source': len(source_chips), 'target': len(target_chips)}
            if len(source_chips) != len(target_chips):
                result['errors'].append('芯片数量不一致: 源=%d, 目标=%d' % (len(source_chips), len(target_chips)))
                result['success'] = False
            
            # 契约数量
            source_contracts = list(self.source_db.RoleContract.find({'role_db_id': source_role_id}))
            target_contracts = list(self.target_db.RoleContract.find({'role_db_id': new_role_id}))
            result['details']['contracts'] = {'source': len(source_contracts), 'target': len(target_contracts)}
            if len(source_contracts) != len(target_contracts):
                result['errors'].append('契约数量不一致: 源=%d, 目标=%d' % (len(source_contracts), len(target_contracts)))
                result['success'] = False
            
            # 携带物数量
            source_held = list(self.source_db.RoleHeldItem.find({'role_db_id': source_role_id}))
            target_held = list(self.target_db.RoleHeldItem.find({'role_db_id': new_role_id}))
            result['details']['held_items'] = {'source': len(source_held), 'target': len(target_held)}
            if len(source_held) != len(target_held):
                result['errors'].append('携带物数量不一致: 源=%d, 目标=%d' % (len(source_held), len(target_held)))
                result['success'] = False
            
            # 琉石数量
            source_emeras = list(self.source_db.RoleEmera.find({'role_db_id': source_role_id, 'exist_flag': True}))
            target_emeras = list(self.target_db.RoleEmera.find({'role_db_id': new_role_id, 'exist_flag': True}))
            result['details']['emeras'] = {'source': len(source_emeras), 'target': len(target_emeras)}
            if len(source_emeras) != len(target_emeras):
                result['errors'].append('琉石数量不一致: 源=%d, 目标=%d' % (len(source_emeras), len(target_emeras)))
                result['success'] = False
            
            # 4. 验证道具总数（items 字典）
            src_items = source_role.get('items') or {}
            tgt_items = target_role.get('items') or {}
            src_items_sum = sum(src_items.values()) if src_items else 0
            tgt_items_sum = sum(tgt_items.values()) if tgt_items else 0
            result['details']['items_sum'] = {'source': src_items_sum, 'target': tgt_items_sum}
            if src_items_sum != tgt_items_sum:
                result['errors'].append('道具总数不一致: 源=%d, 目标=%d' % (src_items_sum, tgt_items_sum))
                result['success'] = False
            
            # 5. 验证碎片总数（frags 字典）
            src_frags = source_role.get('frags') or {}
            tgt_frags = target_role.get('frags') or {}
            src_frags_sum = sum(src_frags.values()) if src_frags else 0
            tgt_frags_sum = sum(tgt_frags.values()) if tgt_frags else 0
            result['details']['frags_sum'] = {'source': src_frags_sum, 'target': tgt_frags_sum}
            if src_frags_sum != tgt_frags_sum:
                result['errors'].append('碎片总数不一致: 源=%d, 目标=%d' % (src_frags_sum, tgt_frags_sum))
                result['success'] = False
            
            # 6. 验证充值记录（防止刷首充漏洞）
            src_recharges = source_role.get('recharges') or {}
            tgt_recharges = target_role.get('recharges') or {}
            if bool(src_recharges) != bool(tgt_recharges):
                result['errors'].append('充值记录状态不一致: 源有=%s, 目标有=%s' % (bool(src_recharges), bool(tgt_recharges)))
                result['success'] = False
            
            # 7. 验证关键进度数据（只警告，不阻止）
            progress_fields = ['world_open', 'map_open', 'trainer_level', 'trainer_sum_exp']
            for field in progress_fields:
                src_val = source_role.get(field)
                tgt_val = target_role.get(field)
                if src_val != tgt_val:
                    result['warnings'].append('%s 可能不一致' % field)
            
            # 记录验证摘要
            logger.info('[Transfer] 数据验证完成: success=%s, errors=%d, warnings=%d',
                       result['success'], len(result['errors']), len(result['warnings']))
            
            if result['errors']:
                for err in result['errors']:
                    logger.error('[Transfer] 验证错误: %s', err)
            
            if result['warnings']:
                for warn in result['warnings']:
                    logger.warning('[Transfer] 验证警告: %s', warn)
            
        except Exception as e:
            logger.error('[Transfer] 数据验证异常: %s', e)
            result['errors'].append('验证异常: %s' % str(e))
            result['success'] = False
        
        return result
