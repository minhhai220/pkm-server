#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

DB LRU Queue
'''

from framework import nowtime_t
from framework.lru import LRUCache
from framework.log import logger
from tornado.gen import coroutine, moment
from tornado.ioloop import PeriodicCallback
from toro import JoinableQueue


class TimerJoinableQueue(JoinableQueue, PeriodicCallback):
	def __init__(self, flushSecs):
		PeriodicCallback.__init__(self, self._process, flushSecs * 1000)
		JoinableQueue.__init__(self)
		self._preGet = None
		self._joined = False
		self._closed = False
		self._flushSecs = flushSecs

	def _item_wrap(self, item):
		return (item, nowtime_t())

	def _put_done(self, fu, item):
		return

	def put(self, item, deadline=None):
		ret = JoinableQueue.put(self, self._item_wrap(item), deadline)
		ret.add_done_callback(lambda fu: self._put_done(fu, item))
		return ret

	def _get_done(self, fu):
		return

	def get(self, deadline=None):
		ret = JoinableQueue.get(self, deadline)
		ret.add_done_callback(self._get_done)
		return ret

	def join(self, closed=True):
		self._joined = True
		self._closed = closed
		return self._process()

	def qsize(self):
		return (1 if self._preGet else 0) + JoinableQueue.qsize(self)

	@coroutine
	def _process_item(self, item):
		pass

	@coroutine
	def _on_closed(self):
		pass

	@coroutine
	def _process(self):
		nowTM = nowtime_t()

		try:
			while self.qsize() > 0:
				if not self._preGet:
					self._preGet = yield self.get()
				item, tm = self._preGet
				if not self._joined and nowTM - tm < self._flushSecs:
					break
				self._preGet = None

				yield self._process_item(item)
				del item
				yield moment

		except:
			logger.exception('%s Exception queuing %d' % (type(self), self.qsize()))

		finally:
			if self._closed:
				yield self._on_closed()


class DBJoinableQueue(TimerJoinableQueue):
	# TODO: 无关db object是否热点
	# 定时器到了就刷，可能导致大对象刷新比较耗性能
	DBFlushTimerSecs = 10
	Singleton = None

	def __init__(self):
		TimerJoinableQueue.__init__(self, self.DBFlushTimerSecs)
		self._lru = LRUCache()
		self._dbcGame = None
		self._flushOK = False

		if DBJoinableQueue.Singleton is not None:
			raise ValueError('This is singleton object')
		DBJoinableQueue.Singleton = self

	def _item_wrap(self, item):
		return id(item)

	def _put_done(self, _, item):
		self._lru.set(id(item), TimerJoinableQueue._item_wrap(self, item))

	def put(self, item, deadline=None):
		if id(item) in self._lru:
			# 保持queue和lru大小一致，否则queue会无限变长导致内存泄露
			self._put_done(None, item)
			ret = moment
		else:
			ret = JoinableQueue.put(self, self._item_wrap(item), deadline)
			ret.add_done_callback(lambda fu: self._put_done(None, item))
		return ret

	def _get_done(self, fu):
		fu._result = self._lru.pop()

	def join(self, closed=True):
		print 'DBJoinableQueue joining', self.qsize()
		return TimerJoinableQueue.join(self, closed)

	def qsize(self):
		return (1 if self._preGet else 0) + self._lru.size()

	@coroutine
	def _process_item(self, item):
		dbObj = item
		try:
			ret = yield dbObj.save_async()
			if not ret['ret']:
				logger.warning('DBJoinableQueue process err %s', str(ret))
			if not self._dbcGame:
				self._dbcGame = getattr(dbObj, '_dbc', None)
		except Exception as e:
			dbObj.restoreLastDBSyncKeys()
			logger.warning('%s %s process error, keys %s', dbObj.DBModel, dbObj.pid, dbObj.lastDBSyncKeys)
			if dbObj.DBModel == 'RoleCard':
				try:
					card_summary = {
						'id': getattr(dbObj, 'id', None),
						'role_db_id': getattr(dbObj, 'role_db_id', None),
						'card_id': getattr(dbObj, 'card_id', None),
						'exist_flag': getattr(dbObj, 'exist_flag', None),
						'level': getattr(dbObj, 'level', None),
						'advance': getattr(dbObj, 'advance', None),
						'star': getattr(dbObj, 'star', None),
						'develop': getattr(dbObj, 'develop', None),
						'held_item': getattr(dbObj, 'held_item', None),
					}
					logger.warning('[DIAG-ROLECARD] summary=%s', card_summary)
					diag_vals = {}
					for key in dbObj.lastDBSyncKeys:
						try:
							val = getattr(dbObj, key, None)
							diag_vals[key] = repr(val)[:200]
						except Exception as fe:
							diag_vals[key] = 'unreadable: %s' % fe
					logger.warning('[DIAG-ROLECARD] dirty_values=%s', diag_vals)
				except Exception as fe:
					logger.warning('[DIAG-ROLECARD] summary failed: %s', fe)
			# 全面诊断所有可能导致 msgpack decode error 的字段
			# 使用 dbObj 的属性访问（db_property 定义的），而不是直接访问 _db
			try:
				# 1. 检查 document.ID 类型字段（不能是 None）
				id_fields = ['pw_playing_db_id', 'explorer_shop_db_id', 'random_tower_shop_db_id', 
							 'clone_room_db_id', 'clone_deploy_card_db_id', 'hunting_record_db_id',
							 'pvp_record_db_id', 'cross_arena_record_db_id', 'cross_mine_record_db_id',
							 'gym_record_db_id', 'cross_online_fight_record_db_id']
				for field in id_fields:
					if field in dbObj.lastDBSyncKeys:
						try:
							val = getattr(dbObj, field, 'N/A')
							if val is None:
								logger.error('[BUG!] %s = None (应为空字符串)', field)
						except Exception as fe:
							logger.warning('[DIAG] 读取 %s 失败: %s', field, fe)
				
				# 2. 检查指针结构体字段（不能是 None）
				struct_fields = ['grid_walk', 'battle_extra']
				for field in struct_fields:
					if field in dbObj.lastDBSyncKeys:
						try:
							val = getattr(dbObj, field, 'N/A')
							if val is None:
								logger.error('[BUG!] %s = None (应为空字典{})', field)
						except Exception as fe:
							logger.warning('[DIAG] 读取 %s 失败: %s', field, fe)
				
				# 3. 检查固定长度数组字段
				array_fields = {'battle_cards': 6, 'top10_cards': 10, 'top12_cards': 12}
				for field, expected_len in array_fields.items():
					if field in dbObj.lastDBSyncKeys:
						try:
							val = getattr(dbObj, field, None)
							if val is not None:
								actual_len = len(val) if hasattr(val, '__len__') else -1
								if actual_len != expected_len:
									logger.error('[BUG!] %s 长度=%d (应为%d)', field, actual_len, expected_len)
								# 检查元素是否有 None
								for i, item in enumerate(val):
									if item is None:
										logger.error('[BUG!] %s[%d] = None', field, i)
									elif isinstance(item, (list, tuple)):
										for j, sub in enumerate(item):
											if sub is None:
												logger.error('[BUG!] %s[%d][%d] = None', field, i, j)
						except Exception as fe:
							logger.warning('[DIAG] 读取 %s 失败: %s', field, fe)
				
				# 4. 检查 ready_cards 内部结构
				if 'ready_cards' in dbObj.lastDBSyncKeys:
					try:
						ready = getattr(dbObj, 'ready_cards', None)
						if ready and hasattr(ready, 'items'):
							for idx, info in ready.items():
								if isinstance(info, dict) or hasattr(info, 'get'):
									cards = info.get('cards', []) if hasattr(info, 'get') else info.get('cards', [])
									if len(cards) != 6:
										logger.error('[BUG!] ready_cards[%s].cards 长度=%d (应为6)', idx, len(cards))
									for i, c in enumerate(cards):
										if c is None:
											logger.error('[BUG!] ready_cards[%s].cards[%d] = None', idx, i)
					except Exception as fe:
						logger.warning('[DIAG] 读取 ready_cards 失败: %s', fe)
				
				# 5. 检查 card_embattle.extra 格式
				if 'card_embattle' in dbObj.lastDBSyncKeys:
					try:
						embattle = getattr(dbObj, 'card_embattle', None)
						if embattle and hasattr(embattle, 'items'):
							for mode, data in embattle.items():
								for extra_field in ['extra', 'defence_extra']:
									# DictWatcher.get() 在键不存在时会抛 KeyError，所以用 in 检查
									if extra_field in data:
										extra_val = data[extra_field]
										if extra_val is not None and not isinstance(extra_val, (list, tuple)):
											logger.error('[BUG!] card_embattle[%s].%s 格式错误! type=%s (应为数组)', mode, extra_field, type(extra_val).__name__)
					except Exception as fe:
						logger.warning('[DIAG] 读取 card_embattle 失败: %s', fe)
				
				# 6. 打印所有脏字段的类型（辅助排查未知问题）
				logger.warning('[DIAG] 脏字段类型(前10个):')
				for key in dbObj.lastDBSyncKeys[:10]:
					try:
						val = getattr(dbObj, key, None)
						logger.warning('[DIAG]   %s: %s', key, type(val).__name__)
					except Exception:
						logger.warning('[DIAG]   %s: 无法读取', key)
				
				# 7. Town 文档字段详细诊断
				if dbObj.DBModel == 'Town':
					logger.warning('[DIAG-TOWN] 开始 Town 字段详细诊断...')
					town_map_fields = ['cards', 'factory_teams', 'order_factory', 'continuous_factory', 
									   'buildings', 'relic_buff', 'home_layout_plan', 'home_apply_layout']
					for field in town_map_fields:
						if field in dbObj.lastDBSyncKeys:
							try:
								val = getattr(dbObj, field, None)
								if val is None:
									logger.error('[DIAG-TOWN] %s = None (应为空字典{})', field)
								elif hasattr(val, 'items'):
									logger.warning('[DIAG-TOWN] %s 有 %d 个条目', field, len(val))
									# 打印每个条目的键和值类型
									for k, v in list(val.items())[:5]:  # 只打印前5个
										logger.warning('[DIAG-TOWN]   %s[%s] type=%s', field, k, type(v).__name__)
										# 检查嵌套字段
										if isinstance(v, dict) or hasattr(v, 'items'):
											for inner_k, inner_v in (v.items() if hasattr(v, 'items') else []):
												if inner_v is None:
													logger.error('[DIAG-TOWN]   %s[%s][%s] = None!', field, k, inner_k)
												else:
													logger.warning('[DIAG-TOWN]     [%s] = %s (type=%s)', 
																   inner_k, repr(inner_v)[:50], type(inner_v).__name__)
							except Exception as fe:
								import traceback
								logger.warning('[DIAG-TOWN] 读取 %s 失败: %s\n%s', field, fe, traceback.format_exc())
			except Exception as diag_e:
				import traceback
				logger.warning('[DIAG] 诊断失败: %s\n%s', str(diag_e), traceback.format_exc())
			raise e


	@coroutine
	def _on_closed(self):
		if self._dbcGame and not self._flushOK:
			yield self._dbcGame.call_async('DBCommit', True, True)
			self._flushOK = True
