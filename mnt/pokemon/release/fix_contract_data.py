#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
契约数据一致性修复脚本
修复因为之前 0-based/1-based 混乱导致的数据不一致
"""

import pymongo
import msgpack
from bson import ObjectId

# ==================== 配置区域 ====================
MONGO_URI = 'mongodb://root:oQTkIlUI5wrOUQEl@127.0.0.1:27017'
MONGO_DB = 'game_cn_1'
# ==================================================

def unpack_data(data):
    """解包 msgpack 数据"""
    if data is None:
        return None
    try:
        return msgpack.unpackb(data, raw=False, strict_map_key=False)
    except:
        return data

def pack_data(data):
    """打包 msgpack 数据"""
    if data is None:
        return None
    try:
        return msgpack.packb(data, use_bin_type=True)
    except:
        return data

def fix_contract_data():
    """修复所有玩家的契约数据一致性"""
    
    print("=" * 60)
    print("开始修复契约数据...")
    print("=" * 60)
    
    # 连接 MongoDB
    client = pymongo.MongoClient(MONGO_URI)
    db = client[MONGO_DB]
    
    fixed_count = 0
    total_roles = 0
    total_fixed_contracts = 0
    
    # 遍历所有玩家
    for role_doc in db.role.find({}):
        total_roles += 1
        role_id = role_doc['id']
        
        print("\n处理玩家 %s..." % role_id)
        
        try:
            # 解包玩家的契约列表
            contracts_data = unpack_data(role_doc.get('contracts'))
            if not contracts_data:
                print("  玩家没有契约")
                continue
            
            # 1. 收集所有卡牌的契约引用
            card_contract_refs = {}  # {contract_db_id: (card_id, position)}
            
            # 查询玩家的所有卡牌
            card_ids = unpack_data(role_doc.get('cards', []))
            if not card_ids:
                print("  玩家没有卡牌")
                continue
            
            for card_id in card_ids:
                card_doc = db.role_card.find_one({'_id': ObjectId(card_id)})
                if not card_doc:
                    continue
                
                # 解包卡牌的契约槽位数据
                card_contracts = unpack_data(card_doc.get('contracts'))
                if not card_contracts:
                    continue
                
                card_db_id = card_doc.get('card_id')
                print("  卡牌 card_id=%s 的契约槽位:" % card_db_id)
                
                # card_contracts 是 {position: {contract_db_id: xxx, unlock: xxx}}
                for pos, slot_info in card_contracts.items():
                    # pos 可能是字符串或整数
                    try:
                        pos_int = int(pos)
                    except:
                        pos_int = pos
                    
                    contract_db_id = slot_info.get('contract_db_id')
                    unlock = slot_info.get('unlock', False)
                    print("    槽位 %s: unlock=%s, contract_db_id=%s" % (pos_int, unlock, contract_db_id))
                    
                    if contract_db_id:
                        # 转换为 ObjectId 字符串形式
                        if isinstance(contract_db_id, ObjectId):
                            contract_db_id_str = str(contract_db_id)
                        else:
                            contract_db_id_str = contract_db_id
                        card_contract_refs[contract_db_id_str] = (str(card_id), pos_int)
            
            # 2. 检查并修复所有契约对象
            role_fixed = False
            
            for contract_db_id in contracts_data:
                # 查询契约文档
                try:
                    if isinstance(contract_db_id, str):
                        contract_oid = ObjectId(contract_db_id)
                    else:
                        contract_oid = contract_db_id
                except:
                    continue
                
                contract_doc = db.role_contract.find_one({'_id': contract_oid})
                if not contract_doc:
                    continue
                
                contract_id = contract_doc.get('contract_id')
                card_db_id = unpack_data(contract_doc.get('card_db_id'))
                position = contract_doc.get('position', -1)
                
                print("  契约 contract_id=%s (db_id=%s):" % (contract_id, str(contract_oid)))
                print("    存储状态: card_db_id=%s, position=%s" % (card_db_id, position))
                
                # 转换为统一格式
                contract_db_id_str = str(contract_oid)
                
                # 检查实际引用
                if contract_db_id_str in card_contract_refs:
                    actual_card_id, actual_pos = card_contract_refs[contract_db_id_str]
                    print("    实际引用: card_id=%s, position=%s" % (actual_card_id, actual_pos))
                    
                    # 检查是否一致
                    need_fix = False
                    
                    if card_db_id is None or str(card_db_id) != actual_card_id:
                        need_fix = True
                    if position != actual_pos:
                        need_fix = True
                    
                    if need_fix:
                        print("    ⚠️ 数据不一致！修复中...")
                        
                        # 更新契约文档
                        db.role_contract.update_one(
                            {'_id': contract_oid},
                            {'$set': {
                                'card_db_id': pack_data(ObjectId(actual_card_id)),
                                'position': actual_pos
                            }}
                        )
                        
                        total_fixed_contracts += 1
                        role_fixed = True
                        print("    ✅ 已修复")
                else:
                    # 卡牌中没有引用这个契约，但契约对象认为自己被装备了
                    if card_db_id is not None:
                        print("    ⚠️ 契约认为自己装备在 %s，但卡牌中没有引用！修复中..." % card_db_id)
                        
                        # 清空契约的装备状态
                        db.role_contract.update_one(
                            {'_id': contract_oid},
                            {'$set': {
                                'card_db_id': pack_data(None),
                                'position': -1
                            }}
                        )
                        
                        total_fixed_contracts += 1
                        role_fixed = True
                        print("    ✅ 已修复")
                    else:
                        print("    ✅ 状态正确（未装备）")
            
            if role_fixed:
                fixed_count += 1
            
        except Exception as e:
            print("处理玩家 %s 时出错: %s" % (role_id, str(e)))
            import traceback
            traceback.print_exc()
            continue
    
    print("\n" + "=" * 60)
    print("修复完成！")
    print("  总玩家数: %s" % total_roles)
    print("  修复玩家数: %s" % fixed_count)
    print("  修复契约数: %s" % total_fixed_contracts)
    print("=" * 60)
    
    client.close()

if __name__ == '__main__':
    try:
        fix_contract_data()
    except Exception as e:
        print("修复脚本执行失败: %s" % str(e))
        import traceback
        traceback.print_exc()
        import sys
        sys.exit(1)

