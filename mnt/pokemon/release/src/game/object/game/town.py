#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Town (家园) System - 家园系统核心对象
'''

from framework import nowtime_t, todayinclock5date2int, date2int, inclock5date, datetimefromtimestamp
from framework.csv import csv, ConstDefs
from framework.object import ObjectDBase, db_property
from framework.log import logger
from game import ClientError


# ============================================================================
# 测试模式开关
# ============================================================================
# 设置为 True 时，所有建筑初始化为满级（仅供测试使用，正式环境请设为 False）
DEBUG_MAX_LEVEL = False


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


# 卡牌状态
class TownCardStatus:
	"""卡牌状态（与前端 game.TOWN_CARD_STATE 对应）"""
	NONE = -1           # 无
	IDLE = 0            # 空闲
	TOWN = 1            # 在家园
	REST = 2            # 休息中
	ALCHEMYFACTORY = 3  # 炼金厂工作
	PRODUCTION_THREE = 4  # 甜品站工作
	PRODUCTION_FOUR = 5   # 伐木场工作
	FINANCIAL_CENTER = 6  # 金融银行工作
	ADVENTURE = 7       # 冒险中
	ALCHEMYFACTORY1 = 8  # 炼金厂2工作
	PRODUCTION_THREE1 = 9  # 伐木场2工作


#
# ObjectTown - 家园主对象
#
class ObjectTown(ObjectDBase):
	"""城镇家园对象"""
	
	DBModel = 'Town'
	
	# 数据库字段定义
	role_db_id = db_property('role_db_id')
	
	# 建筑信息 {buildingID: {level, finish_time, idx}}
	buildings = db_property('buildings')
	
	# 家园信息 {expand_level, expand_finish_time, liked, awards, visit_history}
	home = db_property('home')
	
	# 城镇卡牌 {cardDbId: {status, energy, max_energy, energy_refresh_time}}
	cards = db_property('cards')
	
	# 聚会信息
	party = db_property('party')
	
	# 聚会房间信息
	party_room = db_property('party_room')
	
	# 探险信息 {areas, missions}
	adventure = db_property('adventure')
	
	# 探险队伍数量
	adventure_num = db_property('adventure_num')
	
	# 许愿池信息 {wish_id, wish_times}
	wish = db_property('wish')
	
	# 连续生产工厂 {buildingID: {collection_time, total, card_ids}}
	continuous_factory = db_property('continuous_factory')
	
	# 订单工厂 {buildingID: {start_time, needs_time, count, card_ids}}
	order_factory = db_property('order_factory')
	
	# 遗迹buff {type: [{buff_id, ...}]}
	relic_buff = db_property('relic_buff')
	
	# 遗迹祝福抽取记录 {draw_times, weight, effect}
	relic_buff_draw_record = db_property('relic_buff_draw_record')
	
	# 任务信息
	tasks = db_property('tasks')
	
	# 待命卡牌（家园工厂预设队伍）{idx: {cards: [...], name: ""}}
	# 注意：使用 factory_teams 而不是 ready_cards，避免和 role.ready_cards 的数据库验证冲突
	factory_teams = db_property('factory_teams')
	
	# 家园布局方案 {planID: {furniture, wall, ...}}
	home_layout_plan = db_property('home_layout_plan')
	
	# 家园应用布局
	home_apply_layout = db_property('home_apply_layout')
	
	# 预设队伍解锁数量
	ready_card_unlock_num = db_property('ready_card_unlock_num')
	
	def __init__(self, game, dbc):
		ObjectDBase.__init__(self, game, dbc)
	
	def _validateFieldForGo(self, fieldName, value, expectedType, path=''):
		"""验证字段类型是否符合 Go 端要求，返回问题描述"""
		fullPath = '%s.%s' % (path, fieldName) if path else fieldName
		
		if value is None:
			return '[%s] 值为 None，Go 端可能无法处理' % fullPath
		
		try:
			intTypes = (int, long)
		except NameError:
			intTypes = (int,)
		if expectedType == 'int' and not isinstance(value, intTypes):
			return '[%s] 期望 int，实际是 %s: %r' % (fullPath, type(value).__name__, value)
		
		if expectedType == 'float' and not isinstance(value, (int, float)):
			return '[%s] 期望 float，实际是 %s: %r' % (fullPath, type(value).__name__, value)
		
		try:
			strTypes = (str, unicode)
		except NameError:
			strTypes = (str,)
		if expectedType == 'str' and not isinstance(value, strTypes):
			return '[%s] 期望 str，实际是 %s: %r' % (fullPath, type(value).__name__, value)
		
		if expectedType == 'list' and not isinstance(value, list):
			return '[%s] 期望 list，实际是 %s: %r' % (fullPath, type(value).__name__, value)
		
		if expectedType == 'dict' and not isinstance(value, dict):
			return '[%s] 期望 dict，实际是 %s: %r' % (fullPath, type(value).__name__, value)
		
		if expectedType == 'list_no_none' and isinstance(value, list):
			for i, item in enumerate(value):
				if item is None:
					return '[%s[%d]] 数组元素为 None' % (fullPath, i)
		
		return None
	
	def validateAdventureData(self):
		"""验证 adventure 数据结构，打印详细问题"""
		adventure = self._db.get('adventure', {})
		if not adventure:
			return
		
		problems = []
		
		# 验证 missions
		missions = adventure.get('missions', {})
		for areaId, mission in missions.items():
			if not isinstance(mission, dict):
				problems.append('[adventure.missions.%s] 不是 dict: %r' % (areaId, mission))
				continue
			
			# 验证每个字段
			fieldChecks = [
				('area_id', 'int'),
				('plan_id', 'int'),
				('cfg_id', 'int'),
				('card_ids', 'list_no_none'),
				('card_db_ids', 'list_no_none'),
				('explorer_id', 'int'),
				('start_time', 'float'),
				('end_time', 'float'),
			]
			
			for field, expectedType in fieldChecks:
				value = mission.get(field)
				err = self._validateFieldForGo(field, value, expectedType, 'adventure.missions.%s' % areaId)
				if err:
					problems.append(err)
		
		if problems:
			logger.warning('[Town] adventure 数据验证问题:\n  %s', '\n  '.join(problems))
			logger.warning('[Town] adventure 完整数据: %r', adventure)
		else:
			logger.info('[Town] adventure 数据验证通过')
	
	@property
	def model(self):
		"""返回给前端的数据 - 不使用 _db 包装
		
		重要：不能使用 {'_db': data} 格式！
		因为前端 Base.syncFrom 在 new=true 时会尝试访问 new._db，
		但 new 是布尔值，导致报错。正式端也是这样处理的。
		"""
		if not self._db:
			return {}
		
		# 直接返回数据的浅拷贝，不用 {'_db': ...} 包装
		result = dict(self._db)
		
		# 如果许愿池建筑未解锁，不返回 wish 数据（避免前端显示入口）
		# 当建筑解锁时，checkAndUnlockBuildings 会触发 wish 的同步
		buildings = result.get('buildings', {})
		wishKey = int(TownBuildingType.WISH)
		if wishKey not in buildings and 'wish' in result:
			del result['wish']
		
		# 确保 wish 内部字段存在（兼容旧数据和 Go 返回的 nil）
		if 'wish' in result and isinstance(result['wish'], dict):
			# wish_delay 可能是 None（Go 返回 nil）或不存在
			if result['wish'].get('wish_delay') is None:
				result['wish']['wish_delay'] = {}
			if result['wish'].get('wish_id') is None:
				result['wish']['wish_id'] = 0
			if result['wish'].get('wish_times') is None:
				result['wish']['wish_times'] = 0
			if result['wish'].get('total') is None:
				result['wish']['total'] = 0
		
		# 确保 cards 中的 energy 是整数（修复历史浮点数数据）
		if 'cards' in result and result['cards']:
			cards = result['cards']
			for cardDbId, cardData in cards.items():
				if isinstance(cardData, dict) and 'energy' in cardData:
					cardData['energy'] = int(cardData['energy'])
		
		# 把 factory_teams 映射为 ready_cards（前端读取的字段名）
		if 'factory_teams' in result:
			result['ready_cards'] = result['factory_teams']
		
		return result
	
	def set(self, dic=None):
		"""设置数据"""
		if dic is None:
			dic = {}
		
		# 确保基础字段存在
		defaults = {
			'buildings': {},
			'home': {'expand_level': 0, 'expand_finish_time': 0, 'liked': 0, 'awards': 0, 'visit_history': []},
			'cards': {},
			'party': {'role_info': {'rooms': [], 'invites': {}}},
			'party_room': {'party_roles': {}, 'danmus': []},
			'adventure': {'areas': {}, 'missions': {}},
			'adventure_num': 0,
			'wish': {'wish_id': 0, 'wish_times': 0, 'total': 0, 'wish_delay': {}},
			'continuous_factory': {},
			'order_factory': {},
			'relic_buff': {},
			'tasks': {},
			'factory_teams': {},
			'home_layout_plan': {},
			'home_apply_layout': {},
			'ready_card_unlock_num': 0,
		}
		
		for key, default in defaults.items():
			if key not in dic:
				dic[key] = default
		
		# 确保 adventure 内部字段
		if 'areas' not in dic['adventure']:
			dic['adventure']['areas'] = {}
		if 'missions' not in dic['adventure']:
			dic['adventure']['missions'] = {}
		
		# 确保 home 内部字段
		home_defaults = {
			'expand_level': 0, 'expand_finish_time': 0, 'liked': 0, 'awards': 0, 
			'visit_history': [], 'total_score': 0, 'score_num': 0, 'name': '',
			'furniture_placed_num': 0
		}
		for key, default in home_defaults.items():
			if key not in dic['home']:
				dic['home'][key] = default
		
		# 确保 wish 内部字段
		if 'wish_id' not in dic['wish']:
			dic['wish']['wish_id'] = 0
		if 'wish_times' not in dic['wish']:
			dic['wish']['wish_times'] = 0
		if 'total' not in dic['wish']:
			dic['wish']['total'] = 0
		if 'wish_delay' not in dic['wish']:
			dic['wish']['wish_delay'] = {}
		
		ObjectDBase.set(self, dic)
		return self
	
	def init(self):
		"""初始化 - 登录时调用"""
		ObjectDBase.init(self)
		
		if not self._db:
			return self
		
		# 确保所有字段都有默认值（兼容老数据）
		defaults = {
			'buildings': {},
			'home': {'expand_level': 0, 'expand_finish_time': 0, 'liked': 0, 'awards': 0, 'visit_history': []},
			'cards': {},
			'party': {'role_info': {'rooms': [], 'invites': {}}},
			'party_room': {'party_roles': {}, 'danmus': []},
			'adventure': {'areas': {}, 'missions': {}},
			'adventure_num': 0,
			'wish': {'wish_id': 0, 'wish_times': 0, 'total': 0, 'wish_delay': {}},
			'continuous_factory': {},
			'order_factory': {},
			'relic_buff': {},
			'tasks': {},
			'factory_teams': {},
			'home_layout_plan': {},
			'home_apply_layout': {},
			'ready_card_unlock_num': 0,
		}
		
		for key, default in defaults.items():
			if key not in self._db:
				self._db[key] = default
		
		# 确保 adventure 内部字段（处理 None 值）
		adventure = self._db.get('adventure', {})
		if not isinstance(adventure, dict):
			adventure = {}
		if adventure.get('areas') is None:
			adventure['areas'] = {}
		if adventure.get('missions') is None:
			adventure['missions'] = {}
		# 确保 drop_info 存在（特殊掉落记录）
		if adventure.get('drop_info') is None:
			adventure['drop_info'] = {'count': 0, 'weight': {}, 'effect': {}}
		# 确保 missions 中每个任务的数组字段不为 None（Go 要求数组类型）
		missions = adventure.get('missions', {})
		for areaId, mission in missions.items():
			if isinstance(mission, dict):
				if mission.get('card_ids') is None:
					mission['card_ids'] = []
				if mission.get('card_db_ids') is None:
					mission['card_db_ids'] = []
		self._db['adventure'] = adventure
		
		# 初始化探险区域（火山小道默认解锁，stage=1）
		self._initAdventureAreas()
		
		# 计算探险队伍数量
		self._updateAdventureNum()
		
		# 确保 home 内部字段
		home_defaults = {
			'expand_level': 0, 'expand_finish_time': 0, 'liked': 0, 'awards': 0, 
			'visit_history': [], 'total_score': 0, 'score_num': 0, 'name': '',
			'furniture_placed_num': 0
		}
		home = self._db.get('home', {})
		if not isinstance(home, dict):
			home = {}
		for key, default in home_defaults.items():
			# 处理 None 值和缺失字段
			if key not in home or home[key] is None:
				home[key] = default
		# 确保 visit_history 中每条记录的字符串字段不为 None
		visit_history = home.get('visit_history') or []
		for record in visit_history:
			if isinstance(record, dict):
				if record.get('game_key') is None:
					record['game_key'] = ''
				if record.get('name') is None:
					record['name'] = ''
		home['visit_history'] = visit_history
		self._db['home'] = home
		
		# 确保 wish 内部字段（处理 None 和不存在两种情况）
		wish = self._db.get('wish', {})
		if not isinstance(wish, dict):
			wish = {}
		if wish.get('wish_id') is None:
			wish['wish_id'] = 0
		if wish.get('wish_times') is None:
			wish['wish_times'] = 0
		if wish.get('total') is None:
			wish['total'] = 0
		if wish.get('wish_delay') is None:
			wish['wish_delay'] = {}
		self._db['wish'] = wish
		
		# 确保 cards 中没有 None 值，且键必须是字符串（ObjectId）
		# Go 端 Cards 是 map[document.ID]*TownCard，不接受整数键
		cards = self._db.get('cards', {})
		if not isinstance(cards, dict):
			cards = {}
		cleanedCards = {}
		for k, v in cards.items():
			# 只过滤整数键（如 cards[1]），字符串键都是有效的 ObjectId
			if not isinstance(k, basestring):
				logger.warning('[Town.init] 清理无效 cards 键: %s (type=%s)', k, type(k).__name__)
				continue
			if v is not None and isinstance(v, dict):
				# 确保必要字段存在
				if v.get('energy_refresh_time') is None:
					v['energy_refresh_time'] = 0
				if v.get('status') is None:
					v['status'] = 0  # IDLE
				if v.get('energy') is None:
					v['energy'] = 0
				if v.get('max_energy') is None:
					v['max_energy'] = 0
				cleanedCards[k] = v
		self._db['cards'] = cleanedCards
		
		# 确保 home_apply_layout 中没有 None 值（每个值必须是 [[int]] 格式）
		home_apply_layout = self._db.get('home_apply_layout', {})
		if not isinstance(home_apply_layout, dict):
			home_apply_layout = {}
		# 移除值为 None 或非数组的条目
		home_apply_layout = {k: v for k, v in home_apply_layout.items() if v is not None and isinstance(v, list)}
		self._db['home_apply_layout'] = home_apply_layout
		
		# 确保 party 内部字段（新结构：role_info.rooms/invites）
		party = self._db.get('party', {})
		if not isinstance(party, dict):
			party = {}
		if 'role_info' not in party or not isinstance(party.get('role_info'), dict):
			party['role_info'] = {'rooms': [], 'invites': {}}
		else:
			role_info = party['role_info']
			if 'rooms' not in role_info or role_info.get('rooms') is None:
				role_info['rooms'] = []
			if 'invites' not in role_info or role_info.get('invites') is None:
				role_info['invites'] = {}
		self._db['party'] = party
		
		# 确保 party_room 内部字段（新结构：party_roles/danmus）
		party_room = self._db.get('party_room', {})
		if not isinstance(party_room, dict):
			party_room = {}
		if 'party_roles' not in party_room or party_room.get('party_roles') is None:
			party_room['party_roles'] = {}
		if 'danmus' not in party_room or party_room.get('danmus') is None:
			party_room['danmus'] = []
		self._db['party_room'] = party_room
		
		# 确保 continuous_factory 内部字段
		continuous_factory = self._db.get('continuous_factory', {})
		now = nowtime_t()
		if isinstance(continuous_factory, dict):
			for k, v in continuous_factory.items():
				if isinstance(v, dict):
					if v.get('card_ids') is None:
						v['card_ids'] = {}
					# 确保 total >= 1，让前端能显示收取按钮（前端条件需要 total >= 1）
					if v.get('total', 0) < 1:
						v['total'] = 1
					# 确保 calc_time 存在（兼容老数据）
					if v.get('calc_time') is None or v.get('calc_time') == 0:
						v['calc_time'] = v.get('collection_time', now)
			self._db['continuous_factory'] = continuous_factory
		
		# 确保 order_factory 内部字段
		order_factory = self._db.get('order_factory', {})
		if isinstance(order_factory, dict):
			for k, v in order_factory.items():
				if isinstance(v, dict):
					if v.get('card_ids') is None:
						v['card_ids'] = {}
			self._db['order_factory'] = order_factory
		
		# 确保 factory_teams 内部字段（cards 是 map，不能是 None）
		factory_teams = self._db.get('factory_teams', {})
		if isinstance(factory_teams, dict):
			for k, v in factory_teams.items():
				if isinstance(v, dict):
					if v.get('cards') is None:
						v['cards'] = {}
					if v.get('name') is None:
						v['name'] = ''
			self._db['factory_teams'] = factory_teams
		
		# 确保 home_layout_plan 内部字段（layouts 是 map，不能是 None）
		home_layout_plan = self._db.get('home_layout_plan', {})
		if isinstance(home_layout_plan, dict):
			for k, v in home_layout_plan.items():
				if isinstance(v, dict):
					if v.get('layouts') is None:
						v['layouts'] = {}
					if v.get('name') is None:
						v['name'] = ''
			self._db['home_layout_plan'] = home_layout_plan
		
		# 确保 tasks 内部字段
		tasks = self._db.get('tasks', {})
		if not isinstance(tasks, dict):
			tasks = {}
		if tasks.get('area_task_value') is None:
			tasks['area_task_value'] = {}
		if tasks.get('stamp') is None:
			tasks['stamp'] = {}
		self._db['tasks'] = tasks
		
		# 确保 relic_buff 中每个 type 的值是数组而不是 None
		relic_buff = self._db.get('relic_buff', {})
		if isinstance(relic_buff, dict):
			for buffType, buffList in relic_buff.items():
				if buffList is None:
					relic_buff[buffType] = []
			self._db['relic_buff'] = relic_buff
		
		# 确保 relic_buff_draw_record 内部字段
		draw_record = self._db.get('relic_buff_draw_record', {})
		if isinstance(draw_record, dict):
			if draw_record.get('weight') is None:
				draw_record['weight'] = {}
			if draw_record.get('effect') is None:
				draw_record['effect'] = {}
			self._db['relic_buff_draw_record'] = draw_record
		
		# 初始化建筑（市中心默认1级）
		self._initBuildings()
		
		# 测试模式：将所有建筑初始化为满级
		if DEBUG_MAX_LEVEL:
			self._initBuildingsMaxLevel()
		
		# 修复 idx 字段（之前可能错误地存了CSV行ID，应该是建筑类型ID）
		self._fixBuildingIdx()
		
		# 修复卡牌状态不一致问题（检查工厂中不存在的卡牌）
		self._fixCardStatus()
		
		# 更新工厂产出
		self._updateFactoryProduction()
		
		# 刷新卡牌体力
		self._refreshCardEnergy()
		
		return self
	
	def _initBuildings(self):
		"""初始化建筑
		
		根据市中心等级来初始化已解锁的建筑
		解锁条件（来自 building.csv）：
		- 市中心(1): 无条件，初始1级
		- 炼金厂(3): 无条件，初始1级
		- 伐木场(4): 无条件，初始1级
		- 我的小屋(2): 需要市中心4级
		- 甜品站(5): 需要市中心7级
		- 金融银行(6): 需要市中心5级
		- 未知探险(7): 需要市中心6级
		- 炼金厂2(8): 需要市中心10级
		- 伐木场2(9): 需要市中心10级
		- 超级市场(10): 需要市中心5级
		"""
		
		# init() 已经确保这些字段存在
		buildings = self._db['buildings']
		continuousFactory = self._db['continuous_factory']
		orderFactory = self._db['order_factory']
		changed = False
		
		now = nowtime_t()
		
		# 市中心默认1级
		centerKey = int(TownBuildingType.CENTER)
		if centerKey not in buildings:
			buildings[centerKey] = {
				'level': 1,
				'finish_time': 0,
				'idx': centerKey
			}
			changed = True
		
		# 获取市中心等级
		centerLevel = buildings.get(centerKey, {}).get('level', 1)
		
		# 炼金厂默认1级（无解锁条件，初始可用）
		goldKey = int(TownBuildingType.GOLDHOUSE)
		if goldKey not in buildings:
			buildings[goldKey] = {
				'level': 1,
				'finish_time': 0,
				'idx': goldKey
			}
			changed = True
		if goldKey not in continuousFactory:
			continuousFactory[goldKey] = {
				'collection_time': now,
				'calc_time': now,
				'total': 0,
				'card_ids': {}  # Go 端期望 map[document.Integer]document.ID
			}
			changed = True
		
		# 伐木场默认1级（无解锁条件，初始可用）
		cutKey = int(TownBuildingType.CUTTINGHOUSE)
		if cutKey not in buildings:
			buildings[cutKey] = {
				'level': 1,
				'finish_time': 0,
				'idx': cutKey
			}
			changed = True
		if cutKey not in continuousFactory:
			continuousFactory[cutKey] = {
				'collection_time': now,
				'calc_time': now,
				'total': 0,
				'card_ids': {}  # Go 端期望 map[document.Integer]document.ID
			}
			changed = True
		
		# 我的小屋（需要市中心4级）
		homeKey = int(TownBuildingType.HOME)
		if centerLevel >= 4 and homeKey not in buildings:
			buildings[homeKey] = {
				'level': 1,
				'finish_time': 0,
				'idx': homeKey
			}
			changed = True
		
		# 金融银行（需要市中心5级）- 订单工厂
		bankKey = int(TownBuildingType.BANKHOUSE)
		if centerLevel >= 5 and bankKey not in buildings:
			buildings[bankKey] = {
				'level': 1,
				'finish_time': 0,
				'idx': bankKey
			}
			changed = True
		if centerLevel >= 5 and bankKey not in orderFactory:
			orderFactory[bankKey] = {
				'start_time': 0,
				'needs_time': 0,
				'count': 0,
				'card_ids': {}  # Go 端期望 map[document.Integer]document.ID
			}
			changed = True
		
		# 超级市场（需要市中心5级）
		shopKey = int(TownBuildingType.SUPERSHOP)
		if centerLevel >= 5 and shopKey not in buildings:
			buildings[shopKey] = {
				'level': 1,
				'finish_time': 0,
				'idx': shopKey
			}
			changed = True
		
		# 未知探险（需要市中心7级）
		exploKey = int(TownBuildingType.EXPLORATION)
		if centerLevel >= 7 and exploKey not in buildings:
			buildings[exploKey] = {
				'level': 1,
				'finish_time': 0,
				'idx': exploKey
			}
			changed = True
		
		# 甜品站（需要市中心7级）- 连续工厂
		dessertKey = int(TownBuildingType.DESSERTHOUSE)
		if centerLevel >= 7 and dessertKey not in buildings:
			buildings[dessertKey] = {
				'level': 1,
				'finish_time': 0,
				'idx': dessertKey
			}
			changed = True
		if centerLevel >= 7 and dessertKey not in continuousFactory:
			continuousFactory[dessertKey] = {
				'collection_time': now,
				'calc_time': now,
				'total': 0,
				'card_ids': {}  # Go 端期望 map[document.Integer]document.ID
			}
			changed = True
		
		# 炼金厂2（需要市中心6级）
		gold1Key = int(TownBuildingType.GOLDHOUSE1)
		if centerLevel >= 6 and gold1Key not in buildings:
			buildings[gold1Key] = {
				'level': 1,
				'finish_time': 0,
				'idx': gold1Key
			}
			changed = True
		if centerLevel >= 6 and gold1Key not in continuousFactory:
			continuousFactory[gold1Key] = {
				'collection_time': now,
				'calc_time': now,
				'total': 0,
				'card_ids': {}  # Go 端期望 map[document.Integer]document.ID
			}
			changed = True
		
		# 伐木场2（需要市中心6级）
		cut1Key = int(TownBuildingType.CUTTINGHOUSE1)
		if centerLevel >= 6 and cut1Key not in buildings:
			buildings[cut1Key] = {
				'level': 1,
				'finish_time': 0,
				'idx': cut1Key
			}
			changed = True
		if centerLevel >= 6 and cut1Key not in continuousFactory:
			continuousFactory[cut1Key] = {
				'collection_time': now,
				'calc_time': now,
				'total': 0,
				'card_ids': {}  # Go 端期望 map[document.Integer]document.ID
			}
			changed = True
		
		# 许愿池（需要市中心8级）
		wishKey = int(TownBuildingType.WISH)
		if centerLevel >= 8 and wishKey not in buildings:
			buildings[wishKey] = {
				'level': 1,
				'finish_time': 0,
				'idx': wishKey
			}
			# 触发 wish 数据同步（因为 model 在建筑未解锁时不返回 wish）
			# 通过重新赋值让 modelSync 知道需要同步 wish 字段
			self.wish = self.wish
			changed = True
		
		# 派对（需要市中心9级）
		partyKey = int(TownBuildingType.PARTY)
		if centerLevel >= 9 and partyKey not in buildings:
			buildings[partyKey] = {
				'level': 1,
				'finish_time': 0,
				'idx': partyKey
			}
			changed = True
		
		# 山城遗迹（需要市中心19级）
		mountKey = int(TownBuildingType.MOUNTAINOUS_RELIC)
		if centerLevel >= 19 and mountKey not in buildings:
			buildings[mountKey] = {
				'level': 1,
				'finish_time': 0,
				'idx': mountKey
			}
			changed = True
		
		# 大漠遗迹（需要市中心19级）
		desertKey = int(TownBuildingType.DESERT_RELIC)
		if centerLevel >= 19 and desertKey not in buildings:
			buildings[desertKey] = {
				'level': 1,
				'finish_time': 0,
				'idx': desertKey
			}
			changed = True
		
		# 苍雪遗迹（需要大漠遗迹5级 + 山城遗迹5级）
		snowKey = int(TownBuildingType.SNOW_RELIC)
		lavaKey = int(TownBuildingType.LAVA_RELIC)
		desertData = buildings.get(desertKey, None)
		mountData = buildings.get(mountKey, None)
		desertLevel = desertData.get('level', 0) if isinstance(desertData, dict) else 0
		mountainousLevel = mountData.get('level', 0) if isinstance(mountData, dict) else 0
		logger.info('_initBuildings: snowKey=%s lavaKey=%s desertLevel=%s mountainousLevel=%s snowInBuildings=%s lavaInBuildings=%s',
					snowKey, lavaKey, desertLevel, mountainousLevel, snowKey in buildings, lavaKey in buildings)
		if desertLevel >= 5 and mountainousLevel >= 5 and snowKey not in buildings:
			buildings[snowKey] = {
				'level': 1,
				'finish_time': 0,
				'idx': snowKey
			}
			changed = True
		
		# 熔岩遗迹（需要大漠遗迹5级 + 山城遗迹5级）
		if desertLevel >= 5 and mountainousLevel >= 5 and lavaKey not in buildings:
			buildings[lavaKey] = {
				'level': 1,
				'finish_time': 0,
				'idx': lavaKey
			}
			changed = True
		
		if changed:
			self._db['buildings'] = buildings
			self._db['continuous_factory'] = continuousFactory
			self._db['order_factory'] = orderFactory
	
	def _initBuildingsMaxLevel(self):
		"""测试用：将所有建筑初始化为满级
		
		各建筑满级（根据 building.csv）：
		- 市中心(1): 20级
		- 我的小屋(2): 6级
		- 炼金厂(3): 20级
		- 伐木场(4): 20级
		- 甜品站(5): 14级
		- 金融银行(6): 20级
		- 未知探险(7): 1级（无升级）
		- 炼金厂2(8): 20级
		- 伐木场2(9): 20级
		- 超级市场(10): 1级（无升级）
		- 拜访(11): 1级（无升级）
		- 许愿池(12): 5级
		- 派对(13): 1级（无升级）
		- 大漠遗迹(14): 50级
		- 山城遗迹(15): 50级
		- 苍雪遗迹(16): 50级
		- 熔岩遗迹(17): 50级
		- 小憩花园(101): 1级（无升级）
		"""
		buildings = self._db['buildings']
		continuousFactory = self._db['continuous_factory']
		orderFactory = self._db['order_factory']
		now = nowtime_t()
		
		# 建筑ID -> 满级（根据 building.csv 统计）
		maxLevels = {
			int(TownBuildingType.CENTER): 20,           # 市中心: 20级
			int(TownBuildingType.HOME): 6,              # 我的小屋: 6级
			int(TownBuildingType.GOLDHOUSE): 20,        # 炼金厂: 20级
			int(TownBuildingType.CUTTINGHOUSE): 20,     # 伐木场: 20级
			int(TownBuildingType.DESSERTHOUSE): 14,     # 甜品站: 14级
			int(TownBuildingType.BANKHOUSE): 20,        # 金融银行: 20级
			int(TownBuildingType.EXPLORATION): 1,       # 未知探险: 1级
			int(TownBuildingType.GOLDHOUSE1): 20,       # 炼金厂2: 20级
			int(TownBuildingType.CUTTINGHOUSE1): 20,    # 伐木场2: 20级
			int(TownBuildingType.SUPERSHOP): 1,         # 超级市场: 1级
			int(TownBuildingType.TERMINAL): 1,          # 拜访: 1级
			int(TownBuildingType.WISH): 5,              # 许愿池: 5级
			int(TownBuildingType.PARTY): 1,             # 派对: 1级
			int(TownBuildingType.DESERT_RELIC): 50,     # 大漠遗迹: 50级
			int(TownBuildingType.MOUNTAINOUS_RELIC): 50,# 山城遗迹: 50级
			int(TownBuildingType.SNOW_RELIC): 50,       # 苍雪遗迹: 50级
			int(TownBuildingType.LAVA_RELIC): 50,       # 熔岩遗迹: 50级
			int(TownBuildingType.REST): 1,              # 小憩花园: 1级
		}
		
		# 需要连续工厂数据的建筑
		continuousBuildings = [
			int(TownBuildingType.GOLDHOUSE),
			int(TownBuildingType.CUTTINGHOUSE),
			int(TownBuildingType.DESSERTHOUSE),
			int(TownBuildingType.GOLDHOUSE1),
			int(TownBuildingType.CUTTINGHOUSE1),
		]
		
		# 需要订单工厂数据的建筑
		orderBuildings = [
			int(TownBuildingType.BANKHOUSE),
		]
		
		for buildingID, maxLevel in maxLevels.items():
			buildings[buildingID] = {
				'level': maxLevel,
				'finish_time': 0,
				'idx': buildingID
			}
			
			if buildingID in continuousBuildings:
				if buildingID not in continuousFactory:
					continuousFactory[buildingID] = {
						'collection_time': now,
						'calc_time': now,
						'total': 0,
						'card_ids': {}  # Go 端期望 map[document.Integer]document.ID
					}
			
			if buildingID in orderBuildings:
				if buildingID not in orderFactory:
					orderFactory[buildingID] = {
						'start_time': 0,
						'needs_time': 0,
						'count': 0,
						'card_ids': {}  # Go 端期望 map[document.Integer]document.ID
					}
		
		self._db['buildings'] = buildings
		self._db['continuous_factory'] = continuousFactory
		self._db['order_factory'] = orderFactory
		
		logger.info('[Town] DEBUG_MAX_LEVEL enabled: all buildings set to max level')
	
	def _initAdventureAreas(self):
		"""初始化探险区域
		
		根据 adventure_area.csv 的解锁条件自动解锁区域：
		- 火山小道(1): 无条件，默认解锁 (unlockType1 为空)
		- 青海波市(2): 需要火山小道达到阶段2 (unlockType1=3, unlockParams1=<1;2>)
		- 名胜区(3): 需要青海波市达到阶段2 (unlockType1=3, unlockParams1=<2;2>)
		- 大浪海滩(4): 需要名胜区达到阶段2 (unlockType1=3, unlockParams1=<3;2>)
		"""
		adventure = self._db.get('adventure', {})
		areas = adventure.get('areas', {})
		
		# 火山小道（区域1）默认解锁，初始阶段为1
		if 1 not in areas:
			areas[1] = {
				'stage': 1,
				'points': 0
			}
			adventure['areas'] = areas
			self._db['adventure'] = adventure
		
		# 检查其他区域的解锁条件
		# unlockType1=3 表示需要前置区域达到指定阶段
		# unlockParams1=<前置区域ID;需要的阶段>
		areaUnlockConditions = {
			2: (1, 2),  # 青海波市需要火山小道(1)达到阶段2
			3: (2, 2),  # 名胜区需要青海波市(2)达到阶段2
			4: (3, 2),  # 大浪海滩需要名胜区(3)达到阶段2
		}
		
		changed = False
		for areaID, (requiredArea, requiredStage) in areaUnlockConditions.items():
			if areaID in areas:
				continue
			# 检查前置区域是否达到要求
			prevArea = areas.get(requiredArea, {})
			prevStage = prevArea.get('stage', 0)
			if prevStage >= requiredStage:
				areas[areaID] = {
					'stage': 1,
					'points': 0
				}
				changed = True
		
		if changed:
			adventure['areas'] = areas
			self._db['adventure'] = adventure
	
	def _updateAdventureNum(self):
		"""计算探险队伍数量
		
		根据 adventure_team.csv 的解锁条件计算可用队伍数：
		- ID 1: 无条件，增加1个队伍（默认）
		- ID 2: 需要青海波市(区域2)达到阶段1
		- ID 3: 需要市中心(建筑1)达到12级
		"""
		buildings = self._db.get('buildings', {})
		adventure = self._db.get('adventure', {})
		areas = adventure.get('areas', {})
		
		# 获取市中心等级
		centerData = buildings.get(int(TownBuildingType.CENTER), {})
		centerLevel = centerData.get('level', 1) if isinstance(centerData, dict) else 1
		
		teamNum = 0
		
		# ID 1: 无条件，+1
		teamNum += 1
		
		# ID 2: 青海波市(区域2)达到阶段1，+1
		area2 = areas.get(2, {})
		area2Stage = area2.get('stage', 0)
		if area2Stage >= 1:
			teamNum += 1
		
		# ID 3: 市中心达到12级，+1
		if centerLevel >= 12:
			teamNum += 1
		
		self._db['adventure_num'] = teamNum
	
	def _fixBuildingIdx(self):
		"""修复建筑的 idx 字段
		
		idx 应该等于建筑类型ID（就是 buildings 字典的 key）
		之前可能错误地存了 CSV 行ID，需要修正
		"""
		buildings = self._db['buildings']
		if not buildings:
			return
		
		changed = False
		for buildingID, buildData in buildings.items():
			if isinstance(buildData, dict):
				currentIdx = buildData.get('idx')
				# 如果 idx 不等于建筑类型ID，说明是错误的，需要修正
				if currentIdx != buildingID:
					buildData['idx'] = buildingID
					changed = True
		
		if changed:
			self._db['buildings'] = buildings
	
	def _fixCardStatus(self):
		"""修复卡牌状态不一致问题
		
		检查所有状态为"工作中"的卡牌，如果它们不在任何工厂中，则重置为空闲状态
		"""
		# init() 已经确保这些字段存在
		cards = self._db['cards']
		if not cards:
			return
		
		# 收集所有工厂中的卡牌
		factoryCards = set()
		
		continuousFactory = self._db['continuous_factory']
		for factoryData in continuousFactory.values():
			cardIds = factoryData.get('card_ids', {})
			# 兼容字典格式（Go端）和列表格式（旧数据）
			if isinstance(cardIds, dict):
				cardIdList = cardIds.values()
			else:
				cardIdList = cardIds
			for cardId in cardIdList:
				if cardId:
					factoryCards.add(cardId)
		
		orderFactory = self._db['order_factory']
		for factoryData in orderFactory.values():
			cardIds = factoryData.get('card_ids', {})
			# 兼容字典格式（Go端）和列表格式（旧数据）
			if isinstance(cardIds, dict):
				cardIdList = cardIds.values()
			else:
				cardIdList = cardIds
			for cardId in cardIdList:
				if cardId:
					factoryCards.add(cardId)
		
		# 检查并修复不一致的状态
		changed = False
		for cardDbId, cardData in cards.items():
			if not isinstance(cardData, dict):
				continue
			
			status = cardData.get('status', TownCardStatus.IDLE)
			# 如果状态是工厂工作状态，但卡牌不在任何工厂中
			if status in (TownCardStatus.ALCHEMYFACTORY, TownCardStatus.PRODUCTION_THREE, 
						 TownCardStatus.PRODUCTION_FOUR, TownCardStatus.FINANCIAL_CENTER,
						 TownCardStatus.ALCHEMYFACTORY1, TownCardStatus.PRODUCTION_THREE1):
				if cardDbId not in factoryCards:
					cardData['status'] = TownCardStatus.IDLE
					cardData['energy_refresh_time'] = 0
					changed = True
		
		if changed:
			self._db['cards'] = cards
	
	def _updateFactoryProduction(self):
		"""更新工厂产出（离线收益计算）
		
		注意：使用 calc_time 来计算产出，collection_time 只在收取时更新。
		这样前端可以根据 collection_time + 3600 < now 来判断是否可以收取。
		"""
		now = nowtime_t()
		# init() 已经确保这些字段存在
		continuousFactory = self._db['continuous_factory']
		buildings = self._db['buildings']
		
		for buildingID, factoryData in continuousFactory.items():
			if not factoryData.get('card_ids'):
				continue
			
			# 使用 calc_time 计算产出（如果不存在，回退到 collection_time）
			calcTime = factoryData.get('calc_time')
			if calcTime is None or calcTime == 0:
				calcTime = factoryData.get('collection_time', now)
			
			# 计算离线产出
			elapsedHours = (now - calcTime) // 3600
			if elapsedHours > 0:
				buildData = buildings.get(buildingID, {})
				curLevel = buildData.get('level', 1)
				
				prodCfg = self._getProductionCsv(buildingID, curLevel)
				if prodCfg:
					efficient = getattr(prodCfg, 'efficient', 0)
					inventory = getattr(prodCfg, 'inventory', 100)
					
					produced = efficient * elapsedHours
					totalStored = int(factoryData.get('total', 0)) + produced
					
					# 限制最大库存
					factoryData['total'] = int(min(totalStored, inventory))
					# 只更新 calc_time，不更新 collection_time
					# collection_time 只在收取时更新，让前端可以判断是否可收取
					factoryData['calc_time'] = now
		
		self._db['continuous_factory'] = continuousFactory
	
	def _refreshCardEnergy(self):
		"""刷新卡牌体力，并确保 max_energy 正确"""
		now = nowtime_t()
		# init() 已经确保这些字段存在
		cards = self._db['cards']
		
		# 获取小屋等级和恢复速度（从 home.csv 读取 reply 字段）
		buildings = self._db['buildings']
		homeBuilding = buildings.get(int(TownBuildingType.HOME), {})
		homeLevel = homeBuilding.get('level', 1) if isinstance(homeBuilding, dict) else 1
		replySpeed = 15  # 默认值
		if homeLevel in csv.town.home:
			homeCfg = csv.town.home[homeLevel]
			replySpeed = homeCfg.reply if homeCfg.reply else 15
		normalReply = int(getattr(ConstDefs, 'townHomeEnergyRecovery', 0) or 0)
		no_recover_status = set([
			TownCardStatus.ADVENTURE,
			TownCardStatus.ALCHEMYFACTORY,
			TownCardStatus.PRODUCTION_THREE,
			TownCardStatus.PRODUCTION_FOUR,
			TownCardStatus.FINANCIAL_CENTER,
			TownCardStatus.ALCHEMYFACTORY1,
			TownCardStatus.PRODUCTION_THREE1,
		])
		
		for cardDbId, cardData in cards.items():
			# 确保 max_energy 正确（每次登录重新计算）
			maxEnergy = int(self._getCardMaxEnergy(cardDbId))
			cardData['max_energy'] = maxEnergy
			
			# 确保 energy 不超过 max_energy（确保是整数）
			curEnergy = int(cardData.get('energy', maxEnergy))
			if curEnergy > maxEnergy:
				curEnergy = maxEnergy
			cardData['energy'] = curEnergy
			
			status = cardData.get('status', TownCardStatus.IDLE)
			if status in no_recover_status:
				continue
			
			if curEnergy >= maxEnergy:
				continue
			
			refreshTime = cardData.get('energy_refresh_time', 0)
			reply = replySpeed if status == TownCardStatus.REST else normalReply
			if reply <= 0:
				continue
			if refreshTime <= 0:
				cardData['energy_refresh_time'] = now
				continue
			elapsedHours = (now - refreshTime) // 3600
			if elapsedHours > 0:
				restored = int(elapsedHours * reply)
				if restored > 0:
					cardData['energy'] = int(min(curEnergy + restored, maxEnergy))
					cardData['energy_refresh_time'] = now
		
		self._db['cards'] = cards
	
	def _getCardMaxEnergy(self, cardDbId):
		"""计算卡牌在家园的最大能量值
		
		公式: cardCsv.energy + (energyCfg.advanceAdd * advance + energyCfg.starAdd * star) * cardCsv.energyCorrection
		"""
		try:
			# 获取卡牌数据（使用 getCard 方法）
			card = self.game.cards.getCard(cardDbId)
			if card is None:
				logger.warning('_getCardMaxEnergy: card not found for %s', cardDbId)
				return 100  # 默认值
			
			cardId = card.card_id
			advance = card.advance or 0
			star = card.star or 0
			
			# 获取卡牌配置
			if cardId not in csv.cards:
				logger.warning('_getCardMaxEnergy: cardId %s not in csv.cards', cardId)
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
						cfgRarity = getattr(energyCfg, 'rarity', 0)
						if cfgRarity == rarity:
							advanceAdd = getattr(energyCfg, 'advanceAdd', 0) or 0
							starAdd = getattr(energyCfg, 'starAdd', 0) or 0
							result = int(baseEnergy + (advanceAdd * advance + starAdd * star) * energyCorrection)
							return result
				else:
					logger.warning('_getCardMaxEnergy: csv.town.energy not found')
			else:
				logger.warning('_getCardMaxEnergy: unitId %s not found or invalid', unitId)
			
			return int(baseEnergy)
		except Exception as e:
			logger.warning('_getCardMaxEnergy error: %s', e)
			import traceback
			logger.warning(traceback.format_exc())
			return 100  # 出错时返回默认值
	
	def _getProductionCsv(self, buildingID, level):
		"""获取生产配置"""
		if not hasattr(csv, 'town') or not hasattr(csv.town, 'production_base'):
			return None
		
		for csvId in csv.town.production_base:
			cfg = csv.town.production_base[csvId]
			if cfg.baseID == buildingID and cfg.level == level:
				return cfg
		return None
	
	# ========================================================================
	# 建筑相关
	# ========================================================================
	def getBuildingLevel(self, buildingID):
		"""获取建筑等级"""
		buildings = self.buildings or {}
		buildData = buildings.get(buildingID, {})
		return buildData.get('level', 0)
	
	def isBuildingUnlocked(self, buildingID):
		"""检查建筑是否已解锁"""
		return self.getBuildingLevel(buildingID) > 0
	
	def isBuildingUpgrading(self, buildingID):
		"""检查建筑是否正在升级"""
		buildings = self.buildings or {}
		buildData = buildings.get(buildingID, {})
		finishTime = buildData.get('finish_time', 0)
		return finishTime > 0 and nowtime_t() < finishTime
	
	# ========================================================================
	# 卡牌相关
	# ========================================================================
	def getCardData(self, cardDbId):
		"""获取卡牌在家园的数据"""
		cards = self.cards or {}
		return cards.get(cardDbId, {})
	
	def setCardStatus(self, cardDbId, status):
		"""设置卡牌状态"""
		cards = self.cards or {}
		cardData = cards.get(cardDbId, {})
		cardData['status'] = status
		cards[cardDbId] = cardData
		self.cards = cards
	
	def getCardEnergy(self, cardDbId):
		"""获取卡牌体力"""
		cardData = self.getCardData(cardDbId)
		return cardData.get('energy', 0)
	
	def consumeCardEnergy(self, cardDbId, amount):
		"""消耗卡牌体力"""
		cards = self.cards or {}
		cardData = cards.get(cardDbId, {})
		
		curEnergy = int(cardData.get('energy', 0))
		if curEnergy < amount:
			return False
		
		cardData['energy'] = int(curEnergy - amount)
		cardData['energy_refresh_time'] = nowtime_t()
		cards[cardDbId] = cardData
		self.cards = cards
		return True
	
	def initCardForTown(self, cardDbId, maxEnergy=100):
		"""初始化卡牌的家园数据"""
		cards = self.cards or {}
		if cardDbId not in cards:
			maxEnergy = int(maxEnergy)
			cards[cardDbId] = {
				'status': TownCardStatus.IDLE,
				'energy': maxEnergy,
				'max_energy': maxEnergy,
				'energy_refresh_time': 0,
			}
			self.cards = cards
		return cards[cardDbId]


#
# ObjectTownShop - 超市商店对象
#
class ObjectTownShop(ObjectDBase):
	"""城镇超市商店对象"""
	
	DBModel = 'TownShop'
	
	# 数据库字段定义
	role_db_id = db_property('role_db_id')
	# 商店物品 {index: [csvID, itemID]}
	items = db_property('items')
	# 购买记录 {index: true/false}
	buy = db_property('buy')
	# 上次刷新时间
	last_time = db_property('last_time')
	# 废弃标记
	discard_flag = db_property('discard_flag')
	
	def __init__(self, game, dbc):
		ObjectDBase.__init__(self, game, dbc)
	
	def set(self, dic=None):
		"""设置数据"""
		if dic is None:
			dic = {}
		
		defaults = {
			'items': {},
			'buy': {},
			'last_time': 0,
			'discard_flag': False,
		}
		
		for key, default in defaults.items():
			if key not in dic:
				dic[key] = default
		
		ObjectDBase.set(self, dic)
		return self
	
	def init(self):
		"""初始化"""
		ObjectDBase.init(self)
		
		if not self._db:
			return self
		
		# 确保所有字段都有默认值
		defaults = {
			'items': {},
			'buy': {},
			'last_time': 0,
			'discard_flag': False,
		}
		
		for key, default in defaults.items():
			if key not in self._db:
				self._db[key] = default
		
		# 检查是否需要刷新商店
		if self.isPast():
			self.makeShop()
		
		return self
	
	def isPast(self):
		"""检查商店是否过期需要刷新"""
		if not self.last_time:
			return True
		
		# 获取上次刷新的日期和当前日期（凌晨5点刷新）
		lastdt = datetimefromtimestamp(self.last_time)
		return date2int(inclock5date(lastdt)) != todayinclock5date2int()
	
	def makeShop(self):
		"""生成商店物品"""
		import random
		
		# 清空购买记录
		self.buy = {}
		self.last_time = nowtime_t()
		
		# 获取玩家等级和VIP等级
		level = self.game.role.level
		vip_level = self.game.role.vip_level
		
		# 检查csv是否存在
		if not hasattr(csv, 'town') or not hasattr(csv.town, 'supermarket'):
			self.items = {}
			return
		
		# 按位置分组
		position_items = {}
		for csv_id in csv.town.supermarket:
			cfg = csv.town.supermarket[csv_id]
			
			# 检查VIP等级
			if hasattr(cfg, 'vipStart') and vip_level < cfg.vipStart:
				continue
			
			# 检查玩家等级
			if hasattr(cfg, 'levelRange'):
				if level < cfg.levelRange[0] or level > cfg.levelRange[1]:
					continue
			
			# 检查时间限制
			if hasattr(cfg, 'beginDate') and cfg.beginDate > 0:
				now_date = todayinclock5date2int()
				if now_date < cfg.beginDate or now_date >= cfg.endDate:
					continue
			
			pos = getattr(cfg, 'position', csv_id)
			if pos not in position_items:
				position_items[pos] = []
			position_items[pos].append(cfg)
		
		# 随机选择每个位置的物品
		items = {}
		for pos, cfgs in position_items.items():
			if not cfgs:
				continue
			
			# 权重随机
			weights = [getattr(cfg, 'weight', 1) for cfg in cfgs]
			total_weight = sum(weights)
			if total_weight <= 0:
				cfg = random.choice(cfgs)
			else:
				rnd = random.randint(1, total_weight)
				for i, cfg in enumerate(cfgs):
					rnd -= weights[i]
					if rnd <= 0:
						break
			
			# 获取物品ID（从 itemWeightMap 中提取，格式: {itemID: weight}）
			item_weight_map = getattr(cfg, 'itemWeightMap', {}) or {}
			item_id = list(item_weight_map.keys())[0] if item_weight_map else 0
			items[pos] = [cfg.id, item_id]
		
		self.items = items
	
	def canBuy(self, index):
		"""检查是否可以购买"""
		if index not in self.items:
			return False, 'item not exist'

		return True, None
	
	def buyItem(self, index):
		"""购买物品"""
		can, reason = self.canBuy(index)
		if not can:
			raise ClientError(reason)

		return self.items[index]
