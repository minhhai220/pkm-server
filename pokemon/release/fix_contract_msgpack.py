#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
契约数据修复脚本 - 简化版
直接连接 MongoDB 修复契约数据

使用方法：
1. 修改下面的 MongoDB 连接配置
2. 运行: python fix_contract_msgpack.py
"""

import pymongo
import msgpack
import sys

# ============================================
# MongoDB 连接配置 - 请根据实际情况修改
# ============================================
# 方式1: 使用连接字符串（推荐，支持密码）
MONGO_URI = 'mongodb://root:GpFkU9O24cjhnWco@127.0.0.1:27017'

# 方式2: 分开配置（如果不需要密码可以用这个）
MONGO_HOST = '127.0.0.1'
MONGO_PORT = 27017
MONGO_USER = 'root'
MONGO_PASS = 'GpFkU9O24cjhnWco'

# 数据库名
DB_NAME = 'game_cn_1'     # 数据库名，通常是 game_cn_1 或类似的

# ============================================


def fix_dict_keys(data, field_name):
	"""修复字典键，确保是整数类型"""
	# 如果是 None，返回空字典
	if data is None:
		return {}, True
	
	if not isinstance(data, dict):
		return {}, False
	
	fixed = {}
	changed = False
	for k, v in data.items():
		try:
			# 转换为整数
			key = int(k) if not isinstance(k, int) else k
			val = int(v) if not isinstance(v, int) else v
			fixed[key] = val
			
			# 检查是否有变化
			if type(k) != int or type(v) != int:
				changed = True
		except (ValueError, TypeError):
			print('Warning: Invalid %s entry: %s=%s, skipping' % (field_name, k, v))
			changed = True
	
	return fixed, changed


def main():
	"""修复所有契约数据"""
	
	print("=" * 60)
	print("契约数据修复脚本")
	print("=" * 60)
	print("连接配置: %s/%s" % (MONGO_URI.replace(MONGO_PASS, '***'), DB_NAME))
	print("")
	
	# 连接数据库
	try:
		# 使用 URI 连接（支持用户名密码）
		client = pymongo.MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
		# 测试连接
		client.server_info()
		db = client[DB_NAME]
		collection = db['RoleContract']
		print("[OK] 成功连接到 MongoDB")
	except Exception as e:
		print("[ERROR] 无法连接到 MongoDB: %s" % str(e))
		print("\n请检查:")
		print("1. MongoDB 是否正在运行")
		print("2. 连接配置是否正确 (MONGO_URI, DB_NAME)")
		print("3. 用户名密码是否正确")
		print("4. 是否有访问权限")
		return
	
	# 查找所有契约
	try:
		total = collection.count_documents({})
		print("[OK] 找到 %d 个契约" % total)
	except Exception as e:
		print("[ERROR] 无法查询契约: %s" % str(e))
		client.close()
		return
	
	if total == 0:
		print("[INFO] 数据库中没有契约数据")
		client.close()
		return
	
	fixed_count = 0
	error_count = 0
	skipped_count = 0
	
	print("\n开始处理...")
	print("-" * 60)
	
	for idx, contract in enumerate(collection.find(), 1):
		try:
			contract_id = contract['_id']
			changed = False
			update_fields = {}
			
			# 打印进度
			if idx % 10 == 0 or idx == 1:
				print("[%d/%d] 处理中..." % (idx, total))
			
			# 修复 advance_cost_contracts
			if 'advance_cost_contracts' in contract:
				original = contract['advance_cost_contracts']
				if isinstance(original, dict) and original:
					fixed, has_change = fix_dict_keys(original, 'advance_cost_contracts')
					if has_change:
						update_fields['advance_cost_contracts'] = fixed
						changed = True
						print("\n[FIX] 契约 %s" % contract_id)
						print("  字段: advance_cost_contracts")
						print("  修复前: %s" % original)
						print("  修复后: %s" % fixed)
			
			# 修复 cost_universal_items
			if 'cost_universal_items' in contract:
				original = contract['cost_universal_items']
				if isinstance(original, dict) and original:
					fixed, has_change = fix_dict_keys(original, 'cost_universal_items')
					if has_change:
						update_fields['cost_universal_items'] = fixed
						changed = True
						if not ('advance_cost_contracts' in update_fields):
							print("\n[FIX] 契约 %s" % contract_id)
						print("  字段: cost_universal_items")
						print("  修复前: %s" % original)
						print("  修复后: %s" % fixed)
			
			# 如果有修改，保存到数据库
			if changed:
				# 测试 msgpack 序列化
				try:
					if 'advance_cost_contracts' in update_fields:
						msgpack.packb(update_fields['advance_cost_contracts'])
					if 'cost_universal_items' in update_fields:
						msgpack.packb(update_fields['cost_universal_items'])
				except Exception as e:
					print("  [ERROR] msgpack 测试失败: %s" % str(e))
					error_count += 1
					continue
				
				# 更新数据库
				try:
					result = collection.update_one(
						{'_id': contract_id},
						{'$set': update_fields}
					)
					if result.modified_count > 0:
						fixed_count += 1
						print("  [SUCCESS] 已保存\n")
					else:
						print("  [WARNING] 未修改\n")
						skipped_count += 1
				except Exception as e:
					print("  [ERROR] 保存失败: %s\n" % str(e))
					error_count += 1
			else:
				skipped_count += 1
		
		except Exception as e:
			print("\n[ERROR] 处理契约 %s 失败: %s" % (contract.get('_id', 'unknown'), str(e)))
			error_count += 1
	
	# 输出统计
	print("=" * 60)
	print("修复完成！")
	print("=" * 60)
	print("总契约数:   %d" % total)
	print("已修复:     %d" % fixed_count)
	print("跳过:       %d" % skipped_count)
	print("错误:       %d" % error_count)
	print("=" * 60)
	
	if fixed_count > 0:
		print("\n[SUCCESS] 成功修复 %d 个契约的数据！" % fixed_count)
		print("现在可以重启游戏服务器，msgpack 错误应该已经解决。")
	elif skipped_count == total:
		print("\n[INFO] 所有契约数据都是正确的，无需修复。")
	else:
		print("\n[WARNING] 部分契约处理失败，请检查错误信息。")
	
	client.close()


if __name__ == '__main__':
	print("\n提示：请检查脚本顶部的 MongoDB 连接配置（MONGO_URI 和 DB_NAME）\n")
	
	try:
		main()
	except KeyboardInterrupt:
		print("\n\n[INFO] 用户中断")
		sys.exit(1)
	except Exception as e:
		print("\n\n[FATAL] 严重错误: %s" % str(e))
		import traceback
		traceback.print_exc()
		sys.exit(1)
