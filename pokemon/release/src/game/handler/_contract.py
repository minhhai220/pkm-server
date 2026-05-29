#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import absolute_import

from framework.csv import ConstDefs, csv, ErrDefs
from framework.csv import csv as csvData
from framework.log import logger
from game import ClientError, ServerError
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object.game.gain import ObjectCostAux, ObjectGainAux
from game.object.game.contract import ObjectContract
from game.object.game.card import ObjectCard
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object import ContractDefs, FeatureDefs
from tornado.gen import coroutine, Return
import math
import re


def cleanDbid(dbid):
	"""清理损坏的dbid，只保留字母和数字"""
	if not dbid:
		return dbid
	return re.sub(r'[^a-zA-Z0-9]', '', dbid)


def findContractByCleanDbid(contracts_manager, target_dbid):
	"""通过清理后的dbid查找契约"""
	try:
		clean_target = cleanDbid(target_dbid)
		# logger.info("findContractByCleanDbid: searching for clean_target=%s (from raw=%s)", 
		# 		   clean_target, repr(target_dbid))
		
		# 安全地遍历contracts，避免unhashable type错误
		if not hasattr(contracts_manager, '_objs') or not contracts_manager._objs:
			# logger.warning("findContractByCleanDbid: contracts_manager._objs is empty or None")
			return None
		
		total_contracts = len(contracts_manager._objs)
		exist_count = 0
		# logger.info("findContractByCleanDbid: searching through %d total contracts", total_contracts)
	
		for contract_id, contract in contracts_manager._objs.items():
			try:
				# 确保contract_id是字符串类型
				contract_id_str = str(contract_id) if contract_id is not None else ""
				
				if contract and hasattr(contract, 'exist_flag'):
					if contract.exist_flag:
						exist_count += 1
						clean_contract_id = cleanDbid(contract_id_str)
						# logger.debug("findContractByCleanDbid: [%d] comparing clean=%s with target=%s", 
						# 		   exist_count, clean_contract_id, clean_target)
						if clean_contract_id == clean_target:
							# logger.info("findContractByCleanDbid: ✓ found match for %s (csv_id=%s)", 
							# 		  target_dbid, contract.contract_id)
							return contract
			except Exception as e:
				# logger.warning("findContractByCleanDbid: error processing contract_id=%s: %s", 
				# 			 contract_id, str(e))
				continue
		
		# logger.warning("findContractByCleanDbid: ✗ no match found for %s among %d existing contracts", 
		# 			 target_dbid, exist_count)
		
		# 尝试查找已删除的契约
		for contract_id, contract in contracts_manager._objs.items():
			try:
				contract_id_str = str(contract_id) if contract_id is not None else ""
				if contract and hasattr(contract, 'exist_flag') and not contract.exist_flag:
					clean_contract_id = cleanDbid(contract_id_str)
					if clean_contract_id == clean_target:
						logger.error("findContractByCleanDbid: found DELETED contract matching %s (exist_flag=False)", 
								   target_dbid)
						return None
			except Exception as e:
				continue
				
		return None
	except Exception as e:
		logger.error("findContractByCleanDbid: unexpected error: %s", str(e))
		import traceback
		traceback.print_exc()
	return None


# 获取契约列表 - 参考携带道具系统
class ContractGet(RequestHandlerTask):
	url = r'/game/contract/get'
	
	@coroutine
	def run(self):
		"""获取玩家所有契约数据 - 参考携带道具和芯片系统的数据获取逻辑"""
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Contract, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		try:
			contracts = {}
			
			# 添加详细的调试信息
			logger.info("=== ContractGet DEBUG START ===")
			logger.info("Game object exists: %s", hasattr(self, 'game'))
			logger.info("Contracts manager exists: %s", hasattr(self.game, 'contracts') if hasattr(self, 'game') else False)
			logger.info("Role exists: %s", hasattr(self.game, 'role') if hasattr(self, 'game') else False)
			
			if hasattr(self.game, 'role') and self.game.role:
				role_contracts = getattr(self.game.role, 'contracts', [])
				logger.info("Role.contracts field: %s", role_contracts)
				logger.info("Role.contracts count: %d", len(role_contracts) if role_contracts else 0)
			
			# 强制从数据库重新加载契约数据（绕过缓存问题）
			if hasattr(self.game, 'role') and self.game.role and hasattr(self.game.role, 'contracts') and self.game.role.contracts:
				logger.info("Force reload contracts from database")
				contractsData = yield self.dbcGame.call_async('DBMultipleRead', 'RoleContract', self.game.role.contracts)
				
				logger.info("Database query result: ret=%s, models_count=%d", 
						   contractsData.get('ret', False), 
						   len(contractsData.get('models', [])))
				
				if contractsData['ret'] and contractsData['models']:
					# 直接处理数据库返回的数据，不依赖contracts管理器
					for model in contractsData['models']:
						if model.get('exist_flag', True):
							# 安全地获取契约ID
							contract_id = str(model.get('_id', model.get('id', '')))
							if not contract_id:
								logger.warning("Contract model missing both '_id' and 'id' fields: %s", model)
								continue
								
							contract_data = {
								'id': contract_id,
								'contract_id': model.get('contract_id'),
								'level': model.get('level', 1),
								'advance': model.get('advance', 0),
								'sum_exp': model.get('sum_exp', 0),
								'exist_flag': model.get('exist_flag', True),
								'locked': model.get('locked', False),
								'card_db_id': model.get('card_db_id'),
								'role_db_id': model.get('role_db_id')
							}
							contracts[contract_id] = contract_data
							logger.info("Processed contract: %s (game_id=%s, card_db_id=%s)", 
									   contract_id, model.get('contract_id'), model.get('card_db_id'))
				
				# 同时尝试更新契约管理器（如果存在）
				if hasattr(self.game, 'contracts') and self.game.contracts:
					try:
						self.game.contracts.set(contractsData['models'])
						logger.info("Contracts manager updated successfully")
					except Exception as e:
						logger.error("Failed to update contracts manager: %s", str(e))
			
			# 如果仍然没有契约，检查contracts管理器
			if not contracts:
				logger.info("No contracts from database reload, checking contracts manager")
				if hasattr(self.game, 'contracts') and self.game.contracts and hasattr(self.game.contracts, '_objs'):
					logger.info("Contracts manager _objs count: %d", len(self.game.contracts._objs))
					# 遍历所有契约对象
					for contractID, contract in self.game.contracts._objs.items():
						if contract and getattr(contract, 'exist_flag', True):
							contracts[str(contractID)] = contract.to_dict()
							logger.info("Found contract in manager: %s", contractID)
			
			logger.info("ContractGet returning %d contracts", len(contracts))
			# 打印所有契约的dbid
			for dbid in contracts.keys():
				logger.info("ContractGet: returning contract dbid=%s", dbid)
			
			# 返回数据结构参考携带道具系统
			ret = {
					'contracts': contracts,
				'total_count': len(contracts)
			}
			
			self.write({'view': ret})
			
		except Exception as e:
			logger.error("ContractGet error: %s", str(e))
			import traceback
			traceback.print_exc()
			# 返回空数据而不是错误，避免客户端崩溃
			self.write({'view': {'contracts': {}, 'total_count': 0}})


# 契约装备 - 参考携带道具装备逻辑
class ContractDress(RequestHandlerTask):
	url = r'/game/contract/equip'

	@coroutine
	def run(self):
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Contract, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		contractDBID = self.input.get('contractID', self.input.get('contractDBID', None))
		cardDBID = self.input.get('cardID', self.input.get('cardDBID', None))
		position = self.input.get('pos', self.input.get('position', None))
		
		if contractDBID is None or cardDBID is None or position is None:
			raise ClientError('param miss')
		
		card = self.game.cards.getCard(cardDBID)
		if card is None:
			raise ClientError('cardID error')
		
		contract = self.game.contracts.getContract(contractDBID)
		if contract is None or not contract.exist_flag:
			contract = findContractByCleanDbid(self.game.contracts, contractDBID)
		
		if contract is None or not contract.exist_flag:
			raise ClientError('contractID error')
		
		# 检查位置是否有效（1-based 字典）
		if position not in card.contracts:
			raise ClientError('invalid position')
		
		if not card.contracts[position].get('unlock', False):
			raise ClientError('position not unlocked')
		
		old_contract_id = card.contracts[position].get('contract_db_id')
		if old_contract_id:
			oldContract = self.game.contracts.getContract(old_contract_id)
			if oldContract:
				oldContract.dress_off()
		
		oldCard = None
		if contract.card_db_id is not None:
			oldCard = self.game.cards.getCard(contract.card_db_id)
			if oldCard:
				for pos, pos_info in oldCard.contracts.items():
					if pos_info.get('contract_db_id') == contractDBID:
						oldCard.contracts[pos]['contract_db_id'] = None
						break
				# 强制触发保存
				oldCard.contracts = oldCard.contracts
				ObjectCard.calcContractAttrsAddition(oldCard)
				oldCard.onUpdateAttrs()
		
		success = contract.dress_on(card, position)
		if success:
			ObjectCard.calcContractAttrsAddition(card)
			card.onUpdateAttrs()
			
			ret = {
				'ret': True,
				'cards': {
					str(cardDBID): {
						'id': card.id,
						'fighting_point': card.fighting_point,
						'attrs': card._attrs,
						'contracts': card.contracts,
					}
				}
			}
			
			# 如果契约从旧卡牌卸下，也返回旧卡牌的数据
			if oldCard and oldCard.id != card.id:
				ret['cards'][str(oldCard.id)] = {
					'id': oldCard.id,
					'fighting_point': oldCard.fighting_point,
					'attrs': oldCard._attrs,
					'contracts': oldCard.contracts,
				}
			
			self.write(ret)
		else:
			raise ClientError('dress failed')


# 契约卸下 - 参考携带道具卸下逻辑
class ContractUndress(RequestHandlerTask):
	url = r'/game/contract/unload'

	@coroutine
	def run(self):
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Contract, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		# 兼容前端参数命名: contractID
		contractDBID = self.input.get('contractID', self.input.get('contractDBID', None))
		if contractDBID is None:
			raise ClientError('param miss')
			
		# 获取契约对象 - 首先尝试直接查找
		contract = self.game.contracts.getContract(contractDBID)
		if contract is None or not contract.exist_flag:
			# 如果直接查找失败，尝试通过清理后的dbid查找
			logger.info("ContractUndress: Direct lookup failed, trying cleaned dbid lookup...")
			contract = findContractByCleanDbid(self.game.contracts, contractDBID)
			
		if contract is None or not contract.exist_flag:
			logger.warning("ContractUndress: Contract not found. contractDBID=%s", contractDBID)
			raise ClientError('contractID error')

		cardDBID = contract.card_db_id
		# 契约没有被装备
		if cardDBID is None:
			raise ClientError('contract is not equipped')
			
		card = self.game.cards.getCard(cardDBID)
		if card is None:
			raise ClientError('card not found')

		# 额外验证：检查卡牌的contracts字典中是否真的有这个契约
		is_really_equipped = False
		if hasattr(card, 'contracts') and card.contracts:
			for pos, slot_info in card.contracts.items():
				if slot_info and slot_info.get('contract_db_id') == contractDBID:
					is_really_equipped = True
					break
		
		if not is_really_equipped:
			# 契约对象认为已装备，但卡牌上找不到引用，数据不一致
			# 强制清理契约对象的状态，避免后续错误
			logger.warning("ContractUndress: Contract %s thinks it's equipped to card %s, but card has no reference. Cleaning contract state.", contractDBID, cardDBID)
			contract.card_db_id = None
			contract.position = -1
			raise ClientError('contract is not equipped')

		# 卸下契约
		success = contract.dress_off()
		if success:
			ObjectCard.calcContractAttrsAddition(card)
			card.onUpdateAttrs()
			
			# 返回成功响应和更新的卡牌数据
			ret = {
				'ret': True,
				'cards': {
					str(cardDBID): {
						'id': card.id,
						'fighting_point': card.fighting_point,
						'attrs': card._attrs,  # 更新的属性
						'contracts': card.contracts,  # 更新的契约信息
					}
				}
			}
			
			logger.info('ContractUndress: Returning updated card data: fighting_point=%d', card.fighting_point)
			self.write(ret)
		else:
			raise ClientError('undress failed')


# 契约强化 - 参考携带道具强化逻辑
class ContractStrengthen(RequestHandlerTask):
	url = r'/game/contract/strength'

	@coroutine
	def run(self):
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Contract, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		# 添加原始参数调试
		logger.info("ContractStrengthen: Raw input data: %s", self.input)
		logger.info("ContractStrengthen: Input keys: %s", list(self.input.keys()) if hasattr(self.input, 'keys') else 'No keys method')
		
		# 兼容前端参数命名: contractID, costContractIDs, itemIDs
		contractDBID = self.input.get('contractID', self.input.get('contractDBID', None))
		costItems = self.input.get('itemIDs', self.input.get('costItems', {}))
		costContracts = self.input.get('costContractIDs', self.input.get('costContracts', []))
		
		# 前端使用命名参数，不需要位置参数逻辑
		# 确保类型正确
		if costItems is None:
			costItems = {}
		if costContracts is None:
			costContracts = []
		
		# 添加参数日志和类型检查
		# logger.info("ContractStrengthen: contractDBID=%s (type=%s)", contractDBID, type(contractDBID))
		# logger.info("ContractStrengthen: costItems=%s (type=%s)", costItems, type(costItems))
		# logger.info("ContractStrengthen: costContracts=%s (type=%s)", costContracts, type(costContracts))
		
		# 处理参数类型 - itemIDs应该是{itemID: count}格式
		if isinstance(costItems, list):
			# 如果是空列表则转为空字典
			if len(costItems) == 0:
				costItems = {}
			else:
				logger.warning("ContractStrengthen: costItems is non-empty list: %s", costItems)
		
		# 保存原始的 dbid 列表用于消耗
		costContractDBIDs = []
		if isinstance(costContracts, list):
			# costContractIDs是dbid数组，需要转换为{contract_csv_id: count}格式
			# logger.info("ContractStrengthen: Converting costContracts list to dict, list=%s", costContracts)
			costContractDBIDs = costContracts  # 保存原始列表
			contract_id_counts = {}
			for contract_dbid in costContracts:
				contract_obj = self.game.contracts.getContract(contract_dbid)
				if contract_obj and contract_obj.exist_flag:
					contract_csv_id = contract_obj.contract_id
					if contract_csv_id not in contract_id_counts:
						contract_id_counts[contract_csv_id] = 0
					contract_id_counts[contract_csv_id] += 1
					# logger.info("ContractStrengthen: Found contract dbid=%s, csv_id=%s", contract_dbid, contract_csv_id)
				else:
					logger.warning("ContractStrengthen: Contract not found for dbid=%s", contract_dbid)
			costContracts = contract_id_counts
			# logger.info("ContractStrengthen: Converted to contract_id_counts=%s", costContracts)
		
		if contractDBID is None:
			raise ClientError('param miss')
			
		# 获取契约对象 - 首先尝试直接查找
		contract = self.game.contracts.getContract(contractDBID)
		if contract is None or not contract.exist_flag:
			# 如果直接查找失败，尝试通过清理后的dbid查找
			contract = findContractByCleanDbid(self.game.contracts, contractDBID)
			
		if contract is None or not contract.exist_flag:
			raise ClientError('contractID error')
			
		# 注意：锁定的契约可以强化，锁定只是防止被当作材料消耗
		# 所以这里不检查 contract.locked

		# 检查是否可以强化
		if not contract.can_upgrade():
			raise ClientError('cannot upgrade')

		# 分离契约道具和普通道具（注意：key可能已经是int，也可能是str）
		contract_items_to_cost = {}
		regular_items_to_cost = {}
		
		for item_id_key, count in costItems.items():
			try:
				# 确保item_id是整数
				item_id = int(item_id_key) if not isinstance(item_id_key, int) else item_id_key
				
				# 契约道具通常在特定范围内（根据实际配置调整）
				if 81000 <= item_id <= 90000:  # 契约道具范围
					contract_items_to_cost[item_id] = count
					# logger.info("ContractStrengthen: Contract item to cost: %s x%s", item_id, count)
				else:
					# 其他道具（包括经验道具如131, 133）
					regular_items_to_cost[item_id] = count
					# logger.info("ContractStrengthen: Regular item to cost: %s x%s", item_id, count)
			except (ValueError, TypeError) as e:
				logger.warning("ContractStrengthen: Invalid item_id: %s, error: %s", item_id_key, e)

		# 检查普通道具消耗
		if regular_items_to_cost:
			cost_aux = ObjectCostAux(self.game, regular_items_to_cost)
			if not cost_aux.isEnough():
				raise ClientError(cost_aux.getErrorCode(), cost_aux.getErrorMsg())
		
		# 检查契约道具是否足够
		for item_id, count in contract_items_to_cost.items():
			current_count = self.game.items.getItemCount(item_id)
			# logger.info("ContractStrengthen: Contract item %s: need %s, have %s", item_id, count, current_count)
			if current_count < count:
				raise ClientError('not enough contract items')

		# 检查契约实例消耗 - 如果前端提供了dbid列表，直接使用；否则查找
		contract_objs = []
		if costContractDBIDs:
			# 前端提供了具体的dbid列表，直接使用这些契约
			# logger.info("ContractStrengthen: Using frontend-provided contract dbids: %s", costContractDBIDs)
			
			# 容错处理：跳过不存在的契约，收集可用的
			# 同时统计实际找到的契约的 CSV ID 数量（用于 upgrade 记录）
			actual_cost_contracts = {}
			skipped_count = 0
			
			for idx, contract_dbid in enumerate(costContractDBIDs):
				contract_obj = self.game.contracts.getContract(contract_dbid)
				if contract_obj is None or not contract_obj.exist_flag:
					contract_obj = findContractByCleanDbid(self.game.contracts, contract_dbid)
				
				if contract_obj is None:
					logger.warning("ContractStrengthen: [%d/%d] ⚠ Contract not found, skipping: %s", 
								 idx + 1, len(costContractDBIDs), contract_dbid)
					skipped_count += 1
					continue
				
				if not contract_obj.exist_flag:
					logger.warning("ContractStrengthen: [%d/%d] ⚠ Contract exist_flag=False, skipping: %s", 
								 idx + 1, len(costContractDBIDs), contract_dbid)
					skipped_count += 1
					continue
				
				if contract_obj.id == contractDBID:
					logger.error("ContractStrengthen: Cannot consume the same contract being upgraded")
					raise ClientError('cannot consume same contract')
				
				if contract_obj.locked:
					logger.warning("ContractStrengthen: [%d/%d] ⚠ Contract is locked, skipping: %s", 
								 idx + 1, len(costContractDBIDs), contract_dbid)
					skipped_count += 1
					continue
				
				if contract_obj.card_db_id:
					logger.warning("ContractStrengthen: [%d/%d] ⚠ Contract is equipped, skipping: %s", 
								 idx + 1, len(costContractDBIDs), contract_dbid)
					skipped_count += 1
					continue
				
				# 收集有效契约并统计 CSV ID
				contract_objs.append(contract_obj)
				contract_csv_id = contract_obj.contract_id
				if contract_csv_id not in actual_cost_contracts:
					actual_cost_contracts[contract_csv_id] = 0
				actual_cost_contracts[contract_csv_id] += 1
				
				# logger.info("ContractStrengthen: [%d/%d] ✓ Will consume contract: %s (csv_id=%s)", 
				# 		   idx + 1, len(costContractDBIDs), contract_dbid, contract_csv_id)
			
			if skipped_count > 0:
				logger.warning("ContractStrengthen: Skipped %d invalid contracts, using %d valid contracts", 
							 skipped_count, len(contract_objs))
			
			# 使用实际找到的契约统计，而不是前端提供的
			if actual_cost_contracts:
				costContracts = actual_cost_contracts
				# logger.info("ContractStrengthen: Actual cost contracts by CSV ID: %s", costContracts)
			
			# 注意：强化可以没有契约消耗（只用道具），所以不强制要求有契约
		else:
			# 备用方案：从costContracts字典查找可用契约
			for contract_id_str, count in costContracts.items():
				try:
					contract_id = int(contract_id_str)
				except (ValueError, TypeError):
					logger.warning("ContractStrengthen: Invalid contract_id: %s", contract_id_str)
					continue
					
				# logger.info("ContractStrengthen: Looking for %d contracts with contract_id %s", count, contract_id)
				
				available_contracts = []
				for cid, c in self.game.contracts._objs.items():
					if c.contract_id == contract_id and c.id != contractDBID and not c.locked and not c.card_db_id and c.exist_flag:
						available_contracts.append(c)
						
				if len(available_contracts) < count:
					logger.error("ContractStrengthen: Not enough contracts - need %d, have %d available", count, len(available_contracts))
					raise ClientError('not enough contracts')
					
				for i in range(count):
					contract_objs.append(available_contracts[i])
					# logger.info("ContractStrengthen: Selected contract for consumption: %s", available_contracts[i].id)

		# 执行消耗 - 先消耗普通道具
		if regular_items_to_cost:
			regular_cost_aux = ObjectCostAux(self.game, regular_items_to_cost)
			if regular_cost_aux.isEnough():
				regular_cost_aux.cost(src='contract_strengthen')
			else:
				raise ClientError('not enough regular items')
		
		# 手动消耗契约道具
		for item_id, count in contract_items_to_cost.items():
			success = self.game.items.costItems({item_id: count})
			if success:
				pass
				# logger.info("ContractStrengthen: Successfully consumed contract item %s x%s", item_id, count)
			else:
				logger.error("ContractStrengthen: Failed to consume contract item %s x%s", item_id, count)
				raise ClientError('failed to consume contract items')
		
		# 消耗契约实例 - 使用 deleteContracts 方法，确保从数据库中删除
		if contract_objs:
			# for obj in contract_objs:
			# 	logger.info("ContractStrengthen: Consuming contract instance %s (contract_id: %s)", obj.id, obj.contract_id)
			self.game.contracts.deleteContracts(contract_objs)

		# 执行强化
		old_level = contract.level
		success = contract.upgrade(costItems, costContracts)
		
		if success:
			# 更新战斗力
			if contract.card_db_id:
				card = self.game.cards.getCard(contract.card_db_id)
				if card:
					ObjectCard.calcContractAttrsAddition(card)
					card.onUpdateAttrs()


# 契约突破 - 参考携带道具突破逻辑
class ContractAdvance(RequestHandlerTask):
	url = r'/game/contract/advance'

	@coroutine
	def run(self):
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Contract, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		# 兼容前端参数命名: contractID (第1个参数), costContractIDs (第2个参数)
		contractDBID = self.input.get('contractID', self.input.get('contractDBID', None))
		costItems = self.input.get('costItems', {})
		costContracts = self.input.get('costContractIDs', self.input.get('costContracts', {}))
		
		# 处理参数类型 - 前端发送的costContractIDs是dbid数组
		costContractDBIDs = []
		if isinstance(costContracts, list):
			logger.info("ContractAdvance: Converting costContracts list to dict, list=%s", costContracts)
			costContractDBIDs = costContracts  # 保存原始列表
			contract_id_counts = {}
			for contract_dbid in costContracts:
				contract_obj = self.game.contracts.getContract(contract_dbid)
				if contract_obj and contract_obj.exist_flag:
					contract_csv_id = contract_obj.contract_id
					if contract_csv_id not in contract_id_counts:
						contract_id_counts[contract_csv_id] = 0
					contract_id_counts[contract_csv_id] += 1
				else:
					logger.warning("ContractAdvance: Contract not found for dbid=%s", contract_dbid)
			costContracts = contract_id_counts
			logger.info("ContractAdvance: Converted to contract_id_counts=%s", costContracts)
		
		if contractDBID is None:
			raise ClientError('param miss')
			
		# 获取契约对象 - 首先尝试直接查找
		contract = self.game.contracts.getContract(contractDBID)
		if contract is None or not contract.exist_flag:
			# 如果直接查找失败，尝试通过清理后的dbid查找
			contract = findContractByCleanDbid(self.game.contracts, contractDBID)
			
		if contract is None or not contract.exist_flag:
			raise ClientError('contractID error')
			
		# 注意：锁定的契约可以进阶，锁定只是防止被当作材料消耗
		# 所以这里不检查 contract.locked

		# 检查是否可以突破
		if not contract.can_advance():
			raise ClientError('cannot advance')

		# 消耗检查和处理逻辑参考携带道具系统
		cost_aux = ObjectCostAux(self.game, costItems)
		if not cost_aux.isEnough():
			raise ClientError(cost_aux.getErrorCode(), cost_aux.getErrorMsg())

		# 检查契约消耗 - 如果前端提供了dbid列表，直接使用；否则查找
		contract_objs = []
		if costContractDBIDs:
			# 前端提供了具体的dbid列表
			logger.info("ContractAdvance: Using frontend-provided contract dbids: %s", costContractDBIDs)
			
			# 容错处理：跳过不存在的契约，收集可用的
			# 同时统计实际找到的契约的 CSV ID 数量（用于 advance_up 记录）
			actual_cost_contracts = {}
			skipped_count = 0
			
			for idx, contract_dbid in enumerate(costContractDBIDs):
				logger.info("ContractAdvance: [%d/%d] Checking contract: %s", 
						   idx + 1, len(costContractDBIDs), contract_dbid)
				
				contract_obj = self.game.contracts.getContract(contract_dbid)
				if contract_obj is None:
					logger.warning("ContractAdvance: [%d/%d] getContract returned None, trying findContractByCleanDbid", 
								 idx + 1, len(costContractDBIDs))
					contract_obj = findContractByCleanDbid(self.game.contracts, contract_dbid)
				
				if contract_obj is None:
					logger.warning("ContractAdvance: [%d/%d] ⚠ Contract not found, skipping: %s", 
							   idx + 1, len(costContractDBIDs), contract_dbid)
					skipped_count += 1
					continue
				
				if not contract_obj.exist_flag:
					logger.warning("ContractAdvance: [%d/%d] ⚠ Contract exist_flag=False, skipping: %s", 
							   idx + 1, len(costContractDBIDs), contract_dbid)
					skipped_count += 1
					continue
				
				if contract_obj.id == contractDBID:
					logger.error("ContractAdvance: [%d/%d] Cannot consume the same contract being advanced", 
							   idx + 1, len(costContractDBIDs))
					raise ClientError('cannot consume same contract')
				
				if contract_obj.locked:
					logger.warning("ContractAdvance: [%d/%d] ⚠ Contract is locked, skipping: %s", 
							   idx + 1, len(costContractDBIDs), contract_dbid)
					skipped_count += 1
					continue
				
				if contract_obj.card_db_id:
					logger.warning("ContractAdvance: [%d/%d] ⚠ Contract is equipped, skipping: %s", 
							   idx + 1, len(costContractDBIDs), contract_dbid)
					skipped_count += 1
					continue
				
				# 收集有效契约并统计 CSV ID
				contract_objs.append(contract_obj)
				contract_csv_id = contract_obj.contract_id
				if contract_csv_id not in actual_cost_contracts:
					actual_cost_contracts[contract_csv_id] = 0
				actual_cost_contracts[contract_csv_id] += 1
				
				logger.info("ContractAdvance: [%d/%d] ✓ Valid contract: %s (csv_id=%s, quality=%s)", 
						   idx + 1, len(costContractDBIDs), contract_dbid, 
						   contract_csv_id, getattr(contract_obj.csv, 'quality', 'unknown'))
			
			if skipped_count > 0:
				logger.warning("ContractAdvance: Skipped %d invalid contracts, using %d valid contracts", 
							 skipped_count, len(contract_objs))
			
			# 检查是否有足够的契约
			if len(contract_objs) == 0:
				logger.error("ContractAdvance: No valid contracts found after filtering (all %d contracts are invalid)", 
						   len(costContractDBIDs))
				# 提供更友好的错误信息，让前端知道需要重新选择
				raise ClientError('no valid contracts, please reselect')
			
			# 使用实际找到的契约统计，而不是前端提供的
			costContracts = actual_cost_contracts
			logger.info("ContractAdvance: Actual cost contracts by CSV ID: %s", costContracts)
		else:
			# 备用方案：从costContracts字典查找可用契约
			for contract_id, count in costContracts.items():
				available_contracts = []
				for cid, c in self.game.contracts._objs.items():
					if (c.contract_id == contract_id and 
						c.exist_flag and 
						not c.locked and 
						not c.card_db_id and 
						c.id != contractDBID):
						available_contracts.append(c)
						
				if len(available_contracts) < count:
					raise ClientError('not enough contracts')
					
				for i in range(count):
					contract_objs.append(available_contracts[i])

		# 执行消耗
		cost_aux.cost(src='contract_advance')
		
		# 消耗契约 - 使用 deleteContracts 方法，确保从数据库中删除
		if contract_objs:
			# for obj in contract_objs:
			# 	logger.info("ContractAdvance: Consuming contract: %s", obj.id)
			self.game.contracts.deleteContracts(contract_objs)

		# 执行突破
		old_advance = contract.advance
		success = contract.advance_up(costItems, costContracts)
		
		if success:
			# 更新战斗力
			if contract.card_db_id:
				card = self.game.cards.getCard(contract.card_db_id)
				if card:
					ObjectCard.calcContractAttrsAddition(card)
					card.onUpdateAttrs()


# 契约锁定/解锁 - 参考芯片系统
class ContractLock(RequestHandlerTask):
	url = r'/game/contract/locked'

	@coroutine
	def run(self):
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Contract, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		try:
			# 兼容前端参数命名: contractID，自动切换锁定状态
			contractDBID = self.input.get('contractID', self.input.get('contractDBID', None))
			lock = self.input.get('lock', None)  # 如果不提供，则自动切换
			
			logger.info("ContractLock: input params - contractDBID=%s (type=%s), lock=%s (type=%s)", 
					   contractDBID, type(contractDBID), lock, type(lock))
			logger.info("ContractLock: full input data: %s", self.input)
		
			if contractDBID is None:
				logger.error("ContractLock: contractDBID is None")
				raise ClientError('param miss')
				
			# 检查contracts manager是否存在
			if not hasattr(self.game, 'contracts') or not self.game.contracts:
				logger.error("ContractLock: game.contracts manager not found")
				raise ServerError('contracts manager not available')
			
			# 获取契约对象 - 首先尝试直接查找
			logger.info("ContractLock: attempting direct contract lookup")
			contract = self.game.contracts.getContract(contractDBID)
			
			if contract is None or not getattr(contract, 'exist_flag', True):
				logger.info("ContractLock: direct lookup failed, trying clean dbid lookup")
				# 如果直接查找失败，尝试通过清理后的dbid查找
				contract = findContractByCleanDbid(self.game.contracts, contractDBID)
			
			if contract is None:
				logger.error("ContractLock: contract not found for contractDBID=%s", contractDBID)
				raise ClientError('contract not found')
				
			if not getattr(contract, 'exist_flag', True):
				logger.error("ContractLock: contract exists but exist_flag is False for contractDBID=%s", contractDBID)
				raise ClientError('contract not available')

			# 设置锁定状态 - 如果未提供lock参数，则自动切换
			old_locked = getattr(contract, 'locked', False)
			if lock is None:
				contract.locked = not old_locked  # 自动切换
			else:
				contract.locked = bool(lock)
			
			logger.info("ContractLock: Successfully changed lock state for contract %s from %s to %s", 
					   contractDBID, old_locked, contract.locked)
			logger.info("ContractLock: Data will be automatically saved by framework DBJoinableQueue")
			
			# 返回结果 - 避免复杂对象序列化问题
			ret = {
				'success': True,
				'contract_id': str(contract.id) if hasattr(contract, 'id') and contract.id else contractDBID,
				'locked': bool(contract.locked),
				'old_locked': bool(old_locked)
			}
			
			self.write({'view': ret})
			
		except Exception as e:
			logger.error("ContractLock: unexpected error: %s", str(e))
			import traceback
			traceback.print_exc()
			raise


# 解锁契约格子 - 参考芯片系统的位置解锁
class ContractGridUnlock(RequestHandlerTask):
	url = r'/game/contract/pos/unlock'
	
	@coroutine
	def run(self):
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Contract, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		cardDBID = self.input.get('cardID', self.input.get('cardDBID', None))
		grid = self.input.get('pos', self.input.get('grid', None))
		
		if cardDBID is None or grid is None:
			raise ClientError('param miss')
		
		card = self.game.cards.getCard(cardDBID)
		if card is None:
			raise ClientError('cardID error')
		
		card._initContractSlots()
		
		if grid in card.contracts and card.contracts[grid].get('unlock', False):
			raise ClientError('grid already unlocked')
		
		try:
			card_cfg = csvData.cards[card.card_id]
		except (KeyError, TypeError):
			raise ClientError('card config not found')
		
		contract_plan = getattr(card_cfg, 'contractPlan', 2) if hasattr(card_cfg, 'contractPlan') else 2
		
		plan_configs = []
		try:
			for plan_id in csv.contract.plan:
				plan_cfg = csv.contract.plan[plan_id]
				plan_id_value = getattr(plan_cfg, 'planID', None) if hasattr(plan_cfg, 'planID') else (plan_cfg[4] if isinstance(plan_cfg, (tuple, list)) and len(plan_cfg) >= 5 else None)
				field_id_value = getattr(plan_cfg, 'fieldID', None) if hasattr(plan_cfg, 'fieldID') else (plan_cfg[2] if isinstance(plan_cfg, (tuple, list)) and len(plan_cfg) >= 3 else None)
				if plan_id_value == contract_plan:
					plan_configs.append((plan_id, plan_cfg, field_id_value))
		except:
			raise ServerError('Failed to access contract plan data')
		
		if not plan_configs:
			raise ClientError('No plan config found')
		
		plan_configs.sort(key=lambda x: (x[2] is not None, x[2] if x[2] is not None else 0))
		
		if grid < 1 or grid > len(plan_configs):
			raise ClientError('Invalid grid')
		
		slot_cfg = plan_configs[grid - 1][1]
		
		unlock_type = getattr(slot_cfg, 'unlockType', 0) if hasattr(slot_cfg, 'unlockType') else (slot_cfg[5] if isinstance(slot_cfg, (tuple, list)) and len(slot_cfg) >= 6 else 0)
		condition_arg = getattr(slot_cfg, 'conditionArg', 0) if hasattr(slot_cfg, 'conditionArg') else (slot_cfg[0] if isinstance(slot_cfg, (tuple, list)) else 0)
		
		if unlock_type == 1 and card.level < condition_arg:
			raise ClientError('level condition not met')
		elif unlock_type == 2 and card.star < condition_arg:
			raise ClientError('star condition not met')
		elif unlock_type == 3 and card.advance < condition_arg:
			raise ClientError('advance condition not met')
		elif unlock_type == 4:
			stage, level = condition_arg // 100, condition_arg % 100
			if self.game.role.zawake.get(card.zawakeID, {}).get(stage, 0) < level:
				raise ClientError('zawake condition not met')
		
		cost = getattr(slot_cfg, 'cost', {}) if hasattr(slot_cfg, 'cost') else (slot_cfg[1] if isinstance(slot_cfg, (tuple, list)) and len(slot_cfg) >= 2 else {})
		
		if cost and isinstance(cost, dict):
			costAux = ObjectCostAux(self.game, cost)
			if not costAux.isEnough():
				if costAux.lack == ObjectCostAux.LackGold:
					raise ClientError('gold not enough')
				elif costAux.lack == ObjectCostAux.LackRMB:
					raise ClientError('rmb not enough')
				else:
					raise ClientError('insufficient items')
			costAux.cost(src='contract_grid_unlock')
		
		if grid not in card.contracts:
			card.contracts[grid] = {'contract_db_id': None, 'unlock': True}
		else:
			card.contracts[grid]['unlock'] = True
		
		# 强制触发保存
		card.contracts = card.contracts
		
		self.write({
			'view': {
				'cardDBID': cardDBID,
				'grid': grid,
				'contracts': card.contracts
			}
		})




# 契约重生 - 参考携带道具重生逻辑
class ContractRebirth(RequestHandlerTask):
	url = r'/game/contract/rebirth'

	@coroutine
	def run(self):
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Contract, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		# 兼容前端参数命名: contractID
		contractDBID = self.input.get('contractID', self.input.get('contractDBID', None))
		
		if contractDBID is None:
			raise ClientError('param miss')
			
		# 获取契约对象 - 首先尝试直接查找
		contract = self.game.contracts.getContract(contractDBID)
		if contract is None or not contract.exist_flag:
			# 如果直接查找失败，尝试通过清理后的dbid查找
			contract = findContractByCleanDbid(self.game.contracts, contractDBID)
			
		if contract is None or not contract.exist_flag:
			raise ClientError('contractID error')
			
		# 注意：锁定的契约可以重生，锁定只是防止被当作材料消耗
		# 所以这里不检查 contract.locked

		# 如果已装备，先卸下
		if contract.card_db_id:
			card = self.game.cards.getCard(contract.card_db_id)
			contract.dress_off()
			if card:
				ObjectCard.calcContractAttrsAddition(card)
				card.onUpdateAttrs()

		# 计算返还资源 - 参考携带道具重生逻辑
		return_items = {}
		
		# 返还强化消耗 - 参考携带道具系统
		if contract.level > 1:
			# 返还金币
			return_items['gold'] = contract.sum_exp * ConstDefs.contractExpNeedGold
			
			# 返还经验道具 - 按道具价值从高到低返还
			exp = contract.sum_exp
			exp_items = [133, 132, 131]  # 契约经验道具ID，从高到低
			for itemID in exp_items:
				if itemID in csvData.items:
					cfg = csvData.items[itemID]
					if 'contractExp' in cfg.specialArgsMap:
						texp = cfg.specialArgsMap['contractExp']
						count = int(exp / texp)
						if count > 0:
							exp -= count * texp
							return_items[itemID] = count
			
		# 返还突破消耗 - 使用 advance_cost_contracts 记录（前端需要的字段）
		if contract.advance > 0:
			advance_cost = {}
			
			# 优先使用 advance_cost_contracts 记录
			if hasattr(contract, 'advance_cost_contracts') and contract.advance_cost_contracts:
				for contract_id, count in contract.advance_cost_contracts.items():
					if count > 0:
						advance_cost[contract_id] = advance_cost.get(contract_id, 0) + count
			else:
				# 备用方案：从CSV配置计算
				use_universal = sum(contract.cost_universal_items.values()) if contract.cost_universal_items else 0
				
				# 遍历每个突破等级的消耗
				for i in range(0, contract.advance):
					if hasattr(contract.csv, 'advanceSeq'):
						cost_cfg = csvData.contract.advance_cost.get(i, {})
						cost_items = cost_cfg.get('costItemMap%d' % contract.csv.advanceSeq, {})
						
						for csvID, count in cost_items.items():
							# 如果是契约材料且使用了万能道具
							if ContractDefs.isContractID(csvID) and use_universal > 0:
								least = min(use_universal, count)
								count -= least
								use_universal -= least
							
							if count > 0:
								advance_cost[csvID] = advance_cost.get(csvID, 0) + count
			
			# 合并突破消耗到返还物品
			for itemID, count in advance_cost.items():
				return_items[itemID] = return_items.get(itemID, 0) + count
		
		# 应用返还比例 - 参考携带道具系统
		# 注意：配置名称是 Retrun 不是 Return（历史原因）
		for itemID in return_items.keys():
			return_items[itemID] = int(math.ceil(ConstDefs.contractRebirthRetrunProportion * return_items[itemID]))
		
		# 返还突破使用的万能材料
		# 万能道具使用相同的返还比例（如果以后需要独立配置，可以添加新的 common_config 项）
		if hasattr(ConstDefs, 'contractRebirthUniversalRetrunProportion'):
			universal_proportion = ConstDefs.contractRebirthUniversalRetrunProportion
		else:
			# 如果没有独立配置，使用通用返还比例
			universal_proportion = ConstDefs.contractRebirthRetrunProportion
		
		if universal_proportion > 0:
			universal_items = {}
			for itemID, count in contract.cost_universal_items.items():
				universal_items[itemID] = int(math.ceil(count * universal_proportion))
			
			# 合并万能道具返还
			for itemID, count in universal_items.items():
				return_items[itemID] = return_items.get(itemID, 0) + count

		# 重置契约
		contract.level = 1
		contract.advance = 0
		contract.sum_exp = 0
		
		# 重置突破消耗记录
		if hasattr(contract, 'advance_cost_contracts'):
			contract.advance_cost_contracts = {}
		
		# 给予返还资源
		if return_items:
			eff = ObjectGainAux(self.game, return_items)
			yield effectAutoGain(eff, self.game, self.dbcGame, src='contract_rebirth')
		else:
			eff = ObjectGainAux(self.game, {})
		
		# 返回重生结果给前端展示
		self.write({
			'view': {
				'result': eff.result if eff else {}
			}
		})


# 契约更换 - 参考芯片系统的更换逻辑
class ContractChange(RequestHandlerTask):
	url = r'/game/contract/change'

	@coroutine
	def run(self):
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Contract, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		cardDBID = self.input.get('cardDBID', None)
		position = self.input.get('position', None)
		oldContractDBID = self.input.get('oldContractDBID', None)
		newContractDBID = self.input.get('newContractDBID', None)
		
		if cardDBID is None or position is None:
			raise ClientError('param miss')
			
		card = self.game.cards.getCard(cardDBID)
		if card is None:
			raise ClientError('cardID error')
			
		# 检查位置是否合法
		if position < 0 or position >= len(card.contracts):
			raise ClientError('invalid position')
			
		# 检查位置是否解锁
		if not card.contracts[position].get('unlock', False):
			raise ClientError('position not unlocked')

		# 强制清理当前槽位 - 修复数据不同步问题
		current_slot_contract_id = card.contracts[position].get('contract_db_id', None)
		
		# 卸下旧契约
		if oldContractDBID:
			oldContract = self.game.contracts.getContract(oldContractDBID)
			if oldContract:
				oldContract.dress_off()
		
		# 额外安全清理：如果槽位还有契约引用，强制清理
		if current_slot_contract_id and current_slot_contract_id != newContractDBID:
			logger.warning("Force cleaning slot %d for card %s, had contract: %s", 
			              position, cardDBID, current_slot_contract_id)
			card.contracts[position]['contract_db_id'] = None
			# 强制触发保存
			card.contracts = card.contracts
			
			# 同时清理契约对象的引用（如果存在）
			slot_contract = self.game.contracts.getContract(current_slot_contract_id)
			if slot_contract and slot_contract.card_db_id == cardDBID:
				slot_contract.card_db_id = None
				slot_contract.position = -1

		# 装备新契约
		if newContractDBID:
			newContract = self.game.contracts.getContract(newContractDBID)
			if newContract is None or not newContract.exist_flag:
				raise ClientError('new contractID error')
				
			# 如果新契约已装备在其他位置，先卸下
			if newContract.card_db_id:
				oldCard = self.game.cards.getCard(newContract.card_db_id)
				if oldCard:
					for pos, pos_info in oldCard.contracts.items():
						if pos_info.get('contract_db_id') == newContractDBID:
							oldCard.contracts[pos]['contract_db_id'] = None
							break
					# 强制触发保存
					oldCard.contracts = oldCard.contracts
				ObjectCard.calcContractAttrsAddition(oldCard)
				oldCard.onUpdateAttrs()
					
			# 装备到新位置
			success = newContract.dress_on(card, position)
			if not success:
				raise ClientError('dress failed')

		# 强制重新计算属性和战斗力
		logger.info('=== CONTRACT CHANGE: UPDATING CARD ATTRIBUTES ===')
		logger.info('Card ID: %s, Position: %d', cardDBID, position)
		logger.info('Old Contract: %s, New Contract: %s', oldContractDBID, newContractDBID)
		
		# 记录更新前的属性
		old_hp = card._attrs.get('hp', 0) if card._attrs else 0
		old_damage = card._attrs.get('damage', 0) if card._attrs else 0
		old_fighting_point = card.fighting_point
		
		try:
			# 重新计算契约属性加成
			ObjectCard.calcContractAttrsAddition(card)
			card.onUpdateAttrs()
			
			# 记录更新后的属性对比
			new_hp = card._attrs.get('hp', 0) if card._attrs else 0
			new_damage = card._attrs.get('damage', 0) if card._attrs else 0
			new_fighting_point = card.fighting_point
			
			logger.info('Card attributes and fighting power updated successfully')
			logger.info('Fighting Point: %d -> %d (change: %+d)', old_fighting_point, new_fighting_point, new_fighting_point - old_fighting_point)
			logger.info('HP: %.1f -> %.1f (change: %+.1f)', old_hp, new_hp, new_hp - old_hp)
			logger.info('Damage: %.1f -> %.1f (change: %+.1f)', old_damage, new_damage, new_damage - old_damage)
			
		except Exception as e:
			logger.error('Error updating card attributes after contract change: %s', str(e))
			# 即使属性更新失败，更换操作也应该成功
		
		logger.info('=== CONTRACT CHANGE COMPLETE ===')
		
		# 返回成功响应和更新的卡牌数据
		ret = {
			'ret': True,
			'cards': {
				str(cardDBID): {
					'id': card.id,
					'fighting_point': card.fighting_point,
					'attrs': card._attrs,  # 更新的属性
					'contracts': card.contracts,  # 更新的契约信息
				}
			}
		}
		
		logger.info('Returning updated card data: fighting_point=%d, attrs_count=%d', 
		           card.fighting_point, len(card._attrs) if card._attrs else 0)
		
		# 详细记录返回的属性数据（用于调试）
		if card._attrs:
			logger.info('Sample attrs in response: hp=%s, damage=%s, specialDamage=%s', 
			           card._attrs.get('hp', 'N/A'), 
			           card._attrs.get('damage', 'N/A'), 
			           card._attrs.get('specialDamage', 'N/A'))
		
		self.write(ret)


# 契约交换 - 前端专用接口，交换两个契约的装备位置
class ContractSwap(RequestHandlerTask):
	url = r'/game/contract/swap'

	@coroutine
	def run(self):
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Contract, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		# 兼容前端参数命名: oldContractID, newContractID
		oldContractDBID = self.input.get('oldContractID', self.input.get('oldContractDBID', None))
		newContractDBID = self.input.get('newContractID', self.input.get('newContractDBID', None))
		
		if oldContractDBID is None or newContractDBID is None:
			raise ClientError('param miss')
		
		# 获取旧契约
		oldContract = self.game.contracts.getContract(oldContractDBID)
		if oldContract is None or not oldContract.exist_flag:
			oldContract = findContractByCleanDbid(self.game.contracts, oldContractDBID)
		if oldContract is None or not oldContract.exist_flag:
			raise ClientError('old contractID error')
		
		# 获取新契约
		newContract = self.game.contracts.getContract(newContractDBID)
		if newContract is None or not newContract.exist_flag:
			newContract = findContractByCleanDbid(self.game.contracts, newContractDBID)
		if newContract is None or not newContract.exist_flag:
			raise ClientError('new contractID error')
		
		# 获取旧契约的装备信息
		oldCardDBID = oldContract.card_db_id
		oldPosition = oldContract.position
		
		if oldCardDBID is None or oldPosition is None or oldPosition < 0:
			raise ClientError('old contract is not equipped')
		
		oldCard = self.game.cards.getCard(oldCardDBID)
		if oldCard is None:
			raise ClientError('old card not found')
		
		# 额外验证：检查卡牌的contracts字典中是否真的有这个旧契约
		is_really_equipped = False
		actual_position = None
		if hasattr(oldCard, 'contracts') and oldCard.contracts:
			for pos, slot_info in oldCard.contracts.items():
				if slot_info and slot_info.get('contract_db_id') == oldContractDBID:
					is_really_equipped = True
					actual_position = pos
					break
		
		if not is_really_equipped:
			# 契约对象认为已装备，但卡牌上找不到引用，数据不一致
			# 强制清理契约对象的状态，避免后续错误
			logger.warning("ContractSwap: Old contract %s thinks it's equipped to card %s at pos %s, but card has no reference. Cleaning contract state.", 
						 oldContractDBID, oldCardDBID, oldPosition)
			oldContract.card_db_id = None
			oldContract.position = -1
			raise ClientError('old contract is not equipped')
		
		# 使用实际找到的位置，而不是契约对象记录的位置
		if actual_position and actual_position != oldPosition:
			logger.info("ContractSwap: Old contract %s actual position %s differs from recorded position %s, using actual position", 
					   oldContractDBID, actual_position, oldPosition)
			oldPosition = actual_position
		
		# 初始化新契约的原卡牌（如果有的话）
		newCard = None
		
		# 卸下旧契约
		oldContract.dress_off()
		
		# 如果新契约已装备，先卸下
		if newContract.card_db_id:
			newCard = self.game.cards.getCard(newContract.card_db_id)
			if newCard:
				for pos, pos_info in newCard.contracts.items():
					if pos_info.get('contract_db_id') == newContractDBID:
						newCard.contracts[pos]['contract_db_id'] = None
						break
				# 强制触发保存
				newCard.contracts = newCard.contracts
				ObjectCard.calcContractAttrsAddition(newCard)
				newCard.onUpdateAttrs()
		
		# 装备新契约到旧位置
		success = newContract.dress_on(oldCard, oldPosition)
		if success:
			ObjectCard.calcContractAttrsAddition(oldCard)
			oldCard.onUpdateAttrs()
			
			# 返回更新的卡牌数据
			ret = {
				'ret': True,
				'cards': {
					str(oldCardDBID): {
						'id': oldCard.id,
						'fighting_point': oldCard.fighting_point,
						'attrs': oldCard._attrs,
						'contracts': oldCard.contracts,
					}
				}
			}
			
			# 如果新契约原本也装备在卡牌上，也返回那张卡牌的数据
			if newContract.card_db_id and newCard:
				ret['cards'][str(newCard.id)] = {
					'id': newCard.id,
					'fighting_point': newCard.fighting_point,
					'attrs': newCard._attrs,
					'contracts': newCard.contracts,
				}
			
			self.write(ret)
		else:
			raise ClientError('swap failed')


# 契约兑换 - 前端兑换接口
class ContractConvert(RequestHandlerTask):
	url = r'/game/contract/convert'

	@coroutine
	def run(self):
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Contract, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		# 前端参数: exchangeId (第1个), count (第2个), costContractIDs (第3个)
		exchangeId = None
		count = 1
		costContractIDs = []
		
		# 尝试按位置获取参数
		if len(self.input) >= 1:
			exchangeId = list(self.input.values())[0] if hasattr(self.input, 'values') else None
		if len(self.input) >= 2:
			count = list(self.input.values())[1] if hasattr(self.input, 'values') else 1
		if len(self.input) >= 3:
			costContractIDs = list(self.input.values())[2] if hasattr(self.input, 'values') else []
		
		# 也支持命名参数
		exchangeId = self.input.get('exchangeId', self.input.get('csvID', exchangeId))
		count = self.input.get('count', count)
		costContractIDs = self.input.get('costContractIDs', self.input.get('ids', costContractIDs))
		
		if exchangeId is None:
			raise ClientError('param miss')
		
		logger.info("ContractConvert: exchangeId=%s, count=%s, costContractIDs=%s", exchangeId, count, costContractIDs)
		
		# 检查兑换配置是否存在
		if (not hasattr(csvData, 'contract') or not csvData.contract or 
			not hasattr(csvData.contract, 'activate_book') or not csvData.contract.activate_book or
			exchangeId not in csvData.contract.activate_book):
			logger.error("ContractConvert: Exchange config not found for id=%s", exchangeId)
			raise ClientError('exchange config not found')
		
		exchange_cfg = csvData.contract.activate_book[exchangeId]
		
		# 检查兑换次数
		contract_books = getattr(self.game.role, 'contract_books', {})
		if not contract_books:
			contract_books = {}
		used_times = contract_books.get(exchangeId, 0)
		max_times = getattr(exchange_cfg, 'exchangeTimes', 0)
		
		if used_times + count > max_times:
			raise ClientError('exchange times exceeded')
		
		# 检查普通道具消耗
		cost_items = getattr(exchange_cfg, 'costItems', {})
		if cost_items:
			total_cost = {}
			for item_id, item_count in cost_items.items():
				total_cost[item_id] = item_count * count
			
			cost_aux = ObjectCostAux(self.game, total_cost)
			if not cost_aux.isEnough():
				raise ClientError(cost_aux.getErrorCode(), cost_aux.getErrorMsg())
			
			# 扣除消耗
			cost_aux.cost(src='contract_convert')
		
		# 检查并消耗契约
		cost_contract_map = getattr(exchange_cfg, 'costContractMap', {})
		if cost_contract_map and costContractIDs:
			# 验证提供的契约数量和品质
			for quality, need_count in cost_contract_map.items():
				total_need = need_count * count
			if len(costContractIDs) < total_need:
				raise ClientError('not enough contracts')
			
			# 消耗契约 - 收集契约对象
			contracts_to_delete = []
			for i in range(total_need):
				if i >= len(costContractIDs):
					break
				contract_dbid = costContractIDs[i]
				contract = self.game.contracts.getContract(contract_dbid)
				if contract and contract.exist_flag:
					contracts_to_delete.append(contract)
			
			# 使用 deleteContracts 方法，确保从数据库中删除
			if contracts_to_delete:
				logger.info("ContractConvert: Deleting %d contracts", len(contracts_to_delete))
				self.game.contracts.deleteContracts(contracts_to_delete)
		
		# 生成奖励
		contract_csv_id = getattr(exchange_cfg, 'contractCsvID', None)
		if not contract_csv_id:
			raise ClientError('exchange reward not configured')
		
		# 创建契约奖励
		gain_items = {contract_csv_id: count}
		gain_aux = ObjectGainAux(self.game, gain_items)
		
		# 记录兑换次数
		if not hasattr(self.game.role, 'contract_books') or not self.game.role.contract_books:
			self.game.role.contract_books = {}
		self.game.role.contract_books[exchangeId] = used_times + count
		
		# 发放奖励
		yield effectAutoGain(gain_aux, self.game, self.dbcGame, src='contract_convert')
		
		# 返回兑换结果给前端展示（弹窗）
		self.write({
			'view': {
				'result': gain_aux.result if gain_aux else {}
			}
		})


# 测试接口：添加契约数据（仅用于测试）
class ContractTestAdd(RequestHandlerTask):
	url = r'/game/contract/test/add'

	@coroutine
	def run(self):
		"""测试接口：为玩家添加测试契约数据"""
		try:
			# 创建测试契约数据
			test_contracts = []
			
			# 添加几个测试契约
			contract_ids = [101, 102, 103]  # 假设这些是有效的契约ID
			
			for contract_id in contract_ids:
				# 检查CSV配置是否存在
				if not hasattr(csvData, 'contract') or not csvData.contract or not hasattr(csvData.contract, 'contract'):
					logger.warning("Contract CSV not found")
					continue
					
				if contract_id not in csvData.contract.contract:
					logger.warning("Contract ID %d not found in CSV", contract_id)
					continue
				
				# 创建契约数据
				contract_data = {
					'role_db_id': self.game.role.id,
					'contract_id': contract_id,
					'level': 1,
					'advance': 0,
					'sum_exp': 0,
					'exist_flag': True,
					'locked': False,
					'card_db_id': None,
					'position': -1,
					'cost_universal_items': 0,
				}
				
				# 创建数据库记录
				contractData = yield self.dbcGame.call_async('DBCreate', 'RoleContract', contract_data)
				if contractData['ret']:
					test_contracts.append(contractData['model'])
					logger.info("Created test contract: %s", contractData['model']['id'])
				else:
					logger.warning("Failed to create test contract: %s", contract_id)
			
			if test_contracts:
				# 添加到游戏对象
				self.game.contracts.addContracts(test_contracts)
				
				# 更新角色的契约列表
				contract_ids = [c['id'] for c in test_contracts]
				self.game.role.contracts.extend(contract_ids)
				
				logger.info("Added %d test contracts to role %s", len(test_contracts), self.game.role.id)
				
				self.write({'view': {
					'success': True,
					'added_contracts': len(test_contracts),
					'contract_ids': contract_ids
				}})
			else:
				self.write({'view': {
					'success': False,
					'message': 'No contracts were created'
				}})
				
		except Exception as e:
			logger.warning("Contract test add failed: %s", e)
			self.write({'view': {
				'success': False,
				'message': str(e)
			}}) 

# 调试接口：检查当前角色和数据库连接状态
class ContractDebugInfo(RequestHandlerTask):
	url = r'/game/contract/debug/info'

	@coroutine
	def run(self):
		"""调试接口：检查当前角色和数据库连接状态"""
		try:
			debug_info = {
				'role_info': {
					'role_id': str(self.game.role.id),
					'role_name': self.game.role.name,
					'account_id': str(self.game.role.account_id) if hasattr(self.game.role, 'account_id') else 'N/A',
					'contracts_field': self.game.role.contracts,
					'contracts_count': len(self.game.role.contracts) if self.game.role.contracts else 0,
				},
				'contracts_manager': {
					'exists': hasattr(self.game, 'contracts') and self.game.contracts is not None,
					'contracts_count': len(self.game.contracts._objs) if hasattr(self.game, 'contracts') and self.game.contracts else 0,
				},
				'database_info': {
					'server_key': getattr(self.game, 'server_key', 'unknown'),
					'db_name': getattr(self.dbcGame, 'db_name', 'unknown'),
				}
			}
			
			# 检查契约管理器中的具体数据
			if hasattr(self.game, 'contracts') and self.game.contracts:
				contracts_detail = {}
				for contractID, contract in self.game.contracts._objs.items():
					if contract and contract.exist_flag:
						contracts_detail[str(contractID)] = {
							'contract_id': contract.contract_id,
							'level': contract.level,
							'advance': contract.advance,
							'exist_flag': contract.exist_flag,
							'locked': contract.locked,
							'card_db_id': str(contract.card_db_id) if contract.card_db_id else None,
						}
				debug_info['contracts_detail'] = contracts_detail
			
			# 尝试直接从数据库查询契约数据
			if hasattr(self.game, 'role') and self.game.role and hasattr(self.game.role, 'contracts'):
				if self.game.role.contracts:
					logger.info("Debug: Attempting to read contracts from database: %s", self.game.role.contracts)
					contractsData = yield self.dbcGame.call_async('DBMultipleRead', 'RoleContract', self.game.role.contracts)
					debug_info['database_query'] = {
						'success': contractsData['ret'] if contractsData else False,
						'models_count': len(contractsData['models']) if contractsData and contractsData.get('models') else 0,
						'models': contractsData.get('models', []) if contractsData else []
					}
					logger.info("Debug: Database query result: %s", debug_info['database_query'])
				else:
					debug_info['database_query'] = {
						'success': False,
						'message': 'No contracts in role.contracts field'
					}
			
			logger.info("ContractDebugInfo: %s", debug_info)
			self.write({'view': debug_info})
			
		except Exception as e:
			logger.warning("Contract debug info failed: %s", e)
			self.write({'view': {
				'error': str(e),
				'role_id': str(self.game.role.id) if hasattr(self.game, 'role') and self.game.role else 'N/A'
			}}) 

# 简单测试接口：直接查询数据库契约数据
class ContractTestQuery(RequestHandlerTask):
	url = r'/game/contract/test/query'

	@coroutine
	def run(self):
		"""测试接口：直接查询数据库中的契约数据"""
		try:
			logger.info("ContractTestQuery: Starting direct database query")
			
			# 获取当前角色信息
			role_id = str(self.game.role.id)
			role_name = self.game.role.name
			logger.info("ContractTestQuery: Role ID=%s, Name=%s", role_id, role_name)
			
			# 直接查询数据库中的所有契约数据
			contractsData = yield self.dbcGame.call_async('DBRead', 'RoleContract', None, False, {'role_db_id': self.game.role.id})
			logger.info("ContractTestQuery: Database query result: %s", contractsData)
			
			if contractsData and contractsData.get('ret'):
				models = contractsData.get('models', [])
				logger.info("ContractTestQuery: Found %d contracts in database", len(models))
				
				result = {
					'success': True,
					'role_id': role_id,
					'role_name': role_name,
					'contracts_count': len(models),
					'contracts': models
				}
			else:
				logger.warning("ContractTestQuery: Database query failed or returned no data")
				result = {
					'success': False,
					'role_id': role_id,
					'role_name': role_name,
					'error': 'Database query failed'
				}
			
			self.write({'view': result})
			
		except Exception as e:
			logger.warning("ContractTestQuery failed: %s", e)
			self.write({'view': {
				'success': False,
				'error': str(e)
			}}) 

# 修复契约数据 - 清理损坏的契约槽位数据
class ContractDataFix(RequestHandlerTask):
	url = r'/game/contract/data/fix'
	
	@coroutine
	def run(self):
		cardDBID = self.input.get('cardDBID', None)
		
		if cardDBID is None:
			raise ClientError('param miss')
			
		card = self.game.cards.getCard(cardDBID)
		if card is None:
			raise ClientError('cardID error')
		
		logger.info('Fixing contract data for card %s', cardDBID)
		
		# 备份原始数据
		original_contracts = card.db.get('contracts', {}).copy()
		logger.info('Original contracts data: %s', original_contracts)
		
		# 重新初始化契约槽位
		card._initContractSlots()
		
		# 记录修复结果
		new_contracts = card.db.get('contracts', {})
		logger.info('Fixed contracts data: %s', new_contracts)
		
		# 返回修复结果
		raise Return({
			'original_count': len(original_contracts),
			'fixed_count': len(new_contracts),
			'contracts': new_contracts
		}) 

# 修复契约槽位 - 重新初始化现有卡牌的契约槽位
class ContractSlotsFix(RequestHandlerTask):
	url = r'/game/contract/slots/fix'
	
	@coroutine
	def run(self):
		"""修复现有卡牌的契约槽位初始化问题"""
		fixed_cards = 0
		
		# 遍历所有卡牌
		for card_id, card in self.game.cards._objs.items():
			if card and card.exist_flag:
				# 检查是否需要修复
				need_fix = False
				
				# 检查contracts字段是否存在
				if not hasattr(card, 'contracts') or not card.contracts:
					need_fix = True
				else:
					# 检查是否有任何槽位解锁
					has_unlocked = any(slot.get('unlock', False) for slot in card.contracts.values())
					if not has_unlocked:
						need_fix = True
				
				if need_fix:
					# 重新初始化契约槽位
					logger.info('Fixing contract slots for card %s (card_id: %d)', card.id, card.card_id)
					card._initContractSlots()
					fixed_cards += 1
		
		logger.info('Contract slots fix completed: %d cards fixed', fixed_cards)
		
		ret = {
			'view': {
				'fixed_cards': fixed_cards,
				'message': 'Contract slots fix completed'
			}
		}
		
		self.write(ret) 