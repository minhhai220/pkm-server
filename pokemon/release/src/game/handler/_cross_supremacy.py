#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Cross Supremacy (World Championship) handlers.
"""
from __future__ import absolute_import

import copy
import random
import uuid

from framework import nowdatetime_t, nowtime_t
from framework.csv import csv
from framework.helper import (
	transform2list,
	WeightRandomObject,
	objectid2string,
	string2objectid,
	randomRobotName,
)
from framework.service.helper import game2crosssupremacy
from framework.log import logger
from game import ClientError
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.handler._pvp import _normalize_battle_extra
from game.object import SceneDefs
from game.object.game import ObjectGame, ObjectCostCSV
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from game.object.game.shop import ObjectCrossSupremacyShop
from game.object.game.cross_supremacy import ObjectCrossSupremacyGameGlobal
from game.object.game.card import ObjectCard, randomCharacter, randomNumericalValue
from msgpackrpc.error import CallError
from tornado.gen import coroutine, Return


TEAM_COUNT = 3
SUPREMACY_SCENE = SceneDefs.CrossMine


def _iter_csv_items(table):
	if not table:
		return []
	if isinstance(table, dict):
		return table.iteritems()
	if hasattr(table, 'keys'):
		return ((k, table[k]) for k in table.keys())
	return []


def _csv_keys(table):
	if not table:
		return []
	if isinstance(table, dict):
		keys = list(table.keys())
		if '__default' in keys:
			keys.remove('__default')
		return keys
	if hasattr(table, 'keys'):
		return table.keys()
	return []


def _csv_get(table, key, default=None):
	if not table:
		return default
	if isinstance(table, dict):
		return table.get(key, default)
	getter = getattr(table, 'get', None)
	if callable(getter):
		return getter(key, default)
	try:
		return table[key]
	except Exception:
		return default


def _get_input_param(input_data, idx, *keys):
	if input_data is None:
		return None
	try:
		val = input_data.get(idx, None)
	except TypeError:
		val = input_data.get(idx)
	if val is None and isinstance(idx, int):
		try:
			val = input_data.get(str(idx), None)
		except TypeError:
			val = input_data.get(str(idx))
	if val is None:
		for key in keys:
			try:
				candidate = input_data.get(key, None)
			except TypeError:
				candidate = input_data.get(key)
			if candidate is not None:
				return candidate
	return val


def _as_bool(value):
	if isinstance(value, bool):
		return value
	if value is None:
		return False
	if isinstance(value, (int, long)):
		return value != 0
	if isinstance(value, basestring):
		text = value.strip().lower()
		if text in ('1', 'true', 'yes', 'y', 't', 'on'):
			return True
		if text in ('0', 'false', 'no', 'n', 'f', 'off', ''):
			return False
	return bool(value)


def _dict_has_any_key(data, keys):
	if not isinstance(data, dict):
		return False
	for key in keys:
		if key in data:
			return True
	return False


def _dict_get_with_str_key(data, key, default=None):
	if not isinstance(data, dict):
		return default
	if key in data:
		return data.get(key)
	key_str = str(key)
	if key_str in data:
		return data.get(key_str)
	return default


def _normalize_id(value):
	if value is None:
		return None
	if isinstance(value, basestring):
		if len(value) == 12:
			try:
				return objectid2string(value)
			except Exception:
				pass
		return value
	try:
		return objectid2string(value)
	except Exception:
		return str(value)


def _find_enemy_info(data, record_id):
	if not isinstance(data, dict):
		return None
	target = _normalize_id(record_id)
	for enemy in data.get('enemies', []) or []:
		if _normalize_id(enemy.get('record_db_id')) == target:
			return enemy
		if _normalize_id(enemy.get('role_db_id')) == target:
			return enemy
	return None


def _get_record_by_id(record_map, record_id):
	if not isinstance(record_map, dict):
		return None
	if record_id in record_map:
		return record_map.get(record_id)
	record_id = _normalize_id(record_id)
	if record_id in record_map:
		return record_map.get(record_id)
	for key, val in record_map.iteritems():
		if _normalize_id(key) == record_id:
			return val
	return None


def _get_show_card_from_record(record):
	if not isinstance(record, dict):
		return [0, 0]
	try:
		cards = record.get('cards', {})
		if isinstance(cards, dict):
			team_cards = cards.get(1, []) or cards.get('1', [])
			if team_cards:
				return [team_cards[0], 0]
	except Exception:
		pass
	return [0, 0]


def _looks_like_hex(value):
	if not isinstance(value, basestring):
		return False
	if len(value) not in (24, 32):
		return False
	try:
		int(value, 16)
	except Exception:
		return False
	return True


def _normalize_rank_entry(game, entry):
	if isinstance(entry, dict):
		if not entry.get('game_key'):
			entry['game_key'] = game.role.areaKey
		if not entry.get('figure'):
			entry['figure'] = 1
		return entry
	if isinstance(entry, (list, tuple)):
		if len(entry) >= 11:
			return {
				'record_db_id': _normalize_id(entry[0]),
				'role_db_id': _normalize_id(entry[1]),
				'game_key': entry[2] or game.role.areaKey,
				'name': entry[3] or '',
				'level': entry[4] or 1,
				'score': entry[5] or 0,
				'fighting_point': entry[6] or 0,
				'logo': entry[7] or 1,
				'frame': entry[8] or 1,
				'figure': entry[9] or 1,
				'title': entry[10] or 0,
			}
		result = {
			'game_key': game.role.areaKey,
			'name': '',
			'level': 1,
			'score': 0,
			'fighting_point': 0,
			'logo': 1,
			'frame': 1,
			'figure': 1,
			'title': 0,
		}
		nums = []
		for val in entry:
			if isinstance(val, basestring):
				if val.startswith('game.'):
					result['game_key'] = val
					continue
				if _looks_like_hex(val):
					if len(val) == 24 and not result.get('role_db_id'):
						result['role_db_id'] = val
					elif len(val) == 32 and not result.get('record_db_id'):
						result['record_db_id'] = val
					continue
				if not result['name']:
					result['name'] = val
			elif isinstance(val, (int, long)):
				nums.append(val)
		if nums:
			level_candidate = min(nums)
			if 0 < level_candidate <= 500:
				result['level'] = level_candidate
			result['score'] = max(nums)
			if len(nums) > 1:
				result['fighting_point'] = sorted(nums, reverse=True)[1]
		return result
	return {
		'game_key': game.role.areaKey,
		'name': '',
		'level': 1,
		'score': 0,
		'fighting_point': 0,
		'logo': 1,
		'frame': 1,
		'figure': 1,
		'title': 0,
	}


def _normalize_rank_entries(game, ranks):
	if not isinstance(ranks, list):
		return []
	normalized = []
	for entry in ranks:
		normalized.append(_normalize_rank_entry(game, entry))
	return normalized


def _build_cross_role_info(game, data):
	role = game.role
	record_id = role.cross_supremacy_record_db_id or role.id
	if role.cross_supremacy_record_db_id is None:
		role.cross_supremacy_record_db_id = record_id
	return {
		'record_db_id': record_id,
		'role_db_id': role.id,
		'game_key': role.areaKey,
		'name': role.name,
		'level': role.level,
		'score': data.get('score', 0),
		'fighting_point': getattr(role, 'top12_fighting_point', 0),
		'logo': role.logo,
		'frame': role.frame,
		'figure': getattr(role, 'figure', 0) or 1,
		'title': getattr(role, 'title_id', 0),
	}


@coroutine
def _fetch_cross_supremacy_record(game_key, record_id):
	if not game_key:
		raise Return(None)
	try:
		from game.server import Server
		container = Server.Singleton.container
		client = container.getserviceOrCreate(game_key)
		if not client:
			raise Return(None)
		record_id = _normalize_id(record_id)
		ret = yield client.call_async('CrossSupremacyGetRecord', record_id)
		raise Return(ret)
	except Return:
		raise
	except Exception as e:
		logger.warning('cross_supremacy fetch record error: %s', e)
	raise Return(None)


@coroutine
def _fetch_top_battle_history(game):
	if not ObjectCrossSupremacyGameGlobal.isOpen(game.role.areaKey):
		raise Return(None)
	rpc = ObjectCrossSupremacyGameGlobal.cross_client(game.role.areaKey)
	if not rpc:
		raise Return(None)
	try:
		top_history = yield rpc.call_async('GetCrossSupremacyTopBattleHistory', game.role.areaKey)
		raise Return(top_history)
	except CallError, e:
		logger.warning('cross_supremacy top history error: %s', e)
	raise Return(None)


def _normalize_enemy_entry(enemy, default_game_key):
	if not isinstance(enemy, dict):
		return False
	changed = False

	fp = enemy.get('fighting_point', None)
	if fp is None:
		enemy['fighting_point'] = 0
		changed = True
	elif not isinstance(fp, (int, long)):
		try:
			enemy['fighting_point'] = int(fp)
		except Exception:
			enemy['fighting_point'] = 0
		changed = True

	if enemy.get('score', None) is None:
		enemy['score'] = 0
		changed = True

	level = enemy.get('level', None)
	if level is None:
		role_level = enemy.get('role_level', None)
		enemy['level'] = role_level if role_level is not None else 1
		changed = True
	elif not isinstance(level, (int, long)):
		try:
			enemy['level'] = int(level)
		except Exception:
			enemy['level'] = 1
		changed = True

	if enemy.get('game_key', None) in (None, ''):
		enemy['game_key'] = default_game_key
		changed = True
	if enemy.get('name', None) is None:
		enemy['name'] = ''
		changed = True

	show_card = enemy.get('show_card', None)
	if isinstance(show_card, (list, tuple)):
		if len(show_card) < 2:
			enemy['show_card'] = (list(show_card) + [0, 0])[:2]
			changed = True
	else:
		enemy['show_card'] = [0, 0]
		changed = True

	if enemy.get('title', None) is None:
		enemy['title'] = 0
		changed = True
	if enemy.get('figure', None) is None:
		enemy['figure'] = ''
		changed = True
	if enemy.get('logo', None) is None:
		enemy['logo'] = 1
		changed = True
	if enemy.get('frame', None) is None:
		enemy['frame'] = 1
		changed = True

	return changed


def _default_event_data():
	return {
		'event_id': 0,
		'event_time': 0,
		'buff': {},
		'triggered': {},
		'battle_times': 0,
		'win_times': 0,
		'enter_times': 0,
	}


def _ensure_event_data(data):
	event = data.get('event', None)
	if not isinstance(event, dict):
		event = {}
	defaults = _default_event_data()
	for key, value in defaults.iteritems():
		if key not in event:
			event[key] = value
	if not isinstance(event.get('buff', None), dict):
		event['buff'] = {}
	if not isinstance(event.get('triggered', None), dict):
		event['triggered'] = {}
	data['event'] = event
	return event


def _pick_event_id_by_trigger(trigger_id):
	pool = []
	event_rand = getattr(csv.cross.supremacy, 'event_rand', {}) or {}
	for _, cfg in _iter_csv_items(event_rand):
		if getattr(cfg, 'triggerID', 0) != trigger_id:
			continue
		event_id = getattr(cfg, 'eventID', 0) or 0
		weight = getattr(cfg, 'weight', 0) or 0
		if event_id <= 0 or weight <= 0:
			continue
		pool.append((event_id, weight))
	if not pool:
		return 0
	try:
		event_id, _ = WeightRandomObject.onceRandom(pool)
	except Exception:
		return 0
	return event_id or 0


def _refresh_event_state(data, now=None, enter=False):
	if now is None:
		now = nowtime_t()
	event = _ensure_event_data(data)
	if enter:
		event['enter_times'] = (event.get('enter_times', 0) or 0) + 1

	event_id = event.get('event_id', 0) or 0
	if event_id > 0:
		cfg = _csv_get(getattr(csv.cross.supremacy, 'event_lib', {}), event_id, None)
		time_limit = getattr(cfg, 'timeLimit', 0) if cfg else 0
		if time_limit and event.get('event_time', 0):
			if event['event_time'] + time_limit * 3600 <= now:
				event['event_id'] = 0
				event['event_time'] = 0
		if event.get('event_id', 0):
			data['event'] = event
			return False

	triggered = event.get('triggered', {}) or {}
	trigger_cfgs = list(_iter_csv_items(getattr(csv.cross.supremacy, 'event_trigger', {})))
	trigger_cfgs.sort(key=lambda kv: kv[0])
	for trigger_id, cfg in trigger_cfgs:
		trigger_type = getattr(cfg, 'triggerType', 0) or 0
		trigger_num = getattr(cfg, 'triggerNum', 0) or 0
		trigger_limit = getattr(cfg, 'triggerLimit', 0) or 1
		if triggered.get(trigger_id, 0) >= trigger_limit:
			continue
		if trigger_type == 1:
			if (event.get('battle_times', 0) or 0) < trigger_num:
				continue
		elif trigger_type == 2:
			if (event.get('win_times', 0) or 0) < trigger_num:
				continue
		elif trigger_type == 4:
			grade_id = data.get('grade', 0) or 0
			if grade_id <= 0 or grade_id > trigger_num:
				continue
		elif trigger_type == 5:
			if (event.get('enter_times', 0) or 0) < trigger_num:
				continue
		else:
			continue

		event_id = _pick_event_id_by_trigger(trigger_id)
		if event_id <= 0:
			continue
		event['event_id'] = event_id
		event['event_time'] = now
		triggered[trigger_id] = triggered.get(trigger_id, 0) + 1
		event['triggered'] = triggered
		data['event'] = event
		return True

	data['event'] = event
	return False


def _get_service_cfg():
	service_cfg = getattr(csv.cross, 'service', None)
	if not service_cfg:
		return 1, None
	# 优先 crosssupremacy 服务
	for csv_id, cfg in _iter_csv_items(service_cfg):
		if getattr(cfg, 'service', '') == 'crosssupremacy':
			return csv_id, cfg
	# 否则取最小的一个
	keys = _csv_keys(service_cfg)
	if not keys:
		return 1, None
	csv_id = min(keys)
	return csv_id, _csv_get(service_cfg, csv_id, None)


def _get_aid_num_max():
	aid_cfg = getattr(csv, 'aid', None)
	if not aid_cfg:
		return 0
	scene_cfg = getattr(aid_cfg, 'scene', None)
	if not scene_cfg or 29 not in scene_cfg:
		return 0
	levels = getattr(scene_cfg[29], 'aidUnlockLevel', None) or []
	return len(levels)


def _normalize_extra_list(raw, team_count=TEAM_COUNT):
	if isinstance(raw, (list, tuple)):
		out = []
		for idx in xrange(team_count):
			out.append(_normalize_battle_extra(raw[idx] if idx < len(raw) else None))
		return out
	return [_normalize_battle_extra(raw) for _ in xrange(team_count)]


def _split_cards(cards, team_count=TEAM_COUNT):
	if isinstance(cards, dict):
		# 兼容两种格式：
		# 1) {1:[...],2:[...],3:[...]} 或 {1:{pos:card},...}
		# 2) 扁平化 {1:card,2:card,...,18:card}
		has_nested = False
		for i in xrange(1, team_count + 1):
			if isinstance(_dict_get_with_str_key(cards, i, None), (dict, list, tuple)):
				has_nested = True
				break
		if has_nested:
			out = {}
			for i in xrange(1, team_count + 1):
				out[i] = transform2list(_dict_get_with_str_key(cards, i, []))
			return out
		# 扁平化: 按槽位拆分
		cards = [_dict_get_with_str_key(cards, i, None) for i in xrange(1, team_count * 6 + 1)]
	cards = list(cards) if cards else []
	out = {}
	for i in xrange(team_count):
		start = i * 6
		out[i + 1] = transform2list(cards[start:start + 6])
	return out


def _convert_aid_cards_to_nested(flat, aid_num_max, team_count=TEAM_COUNT):
	result = {i: {} for i in xrange(1, team_count + 1)}
	if not flat or aid_num_max <= 0:
		return result
	if isinstance(flat, dict):
		# 已是嵌套结构 {team: {slot: cardID}} 或 {team: [cardID, ...]}
		is_nested = False
		for team in xrange(1, team_count + 1):
			team_data = _dict_get_with_str_key(flat, team, None)
			if isinstance(team_data, (dict, list, tuple)):
				is_nested = True
				break
		if is_nested:
			for team in xrange(1, team_count + 1):
				team_data = _dict_get_with_str_key(flat, team, {})
				if isinstance(team_data, dict):
					for j in xrange(1, aid_num_max + 1):
						card_id = _dict_get_with_str_key(team_data, j, None)
						if card_id:
							result[team][j] = card_id
				elif isinstance(team_data, (list, tuple)):
					for j in xrange(1, aid_num_max + 1):
						idx = j - 1
						if idx < len(team_data):
							card_id = team_data[idx]
							if card_id:
								result[team][j] = card_id
			return result
		for team in xrange(1, team_count + 1):
			base = (team - 1) * aid_num_max
			for j in xrange(1, aid_num_max + 1):
				idx = base + j
				card_id = _dict_get_with_str_key(flat, idx, None)
				if card_id:
					result[team][j] = card_id
		return result
	# list
	for team in xrange(1, team_count + 1):
		base = (team - 1) * aid_num_max
		for j in xrange(1, aid_num_max + 1):
			idx = base + j - 1
			if idx < len(flat):
				card_id = flat[idx]
				if card_id:
					result[team][j] = card_id
	return result


def _flatten_aid_cards_to_slots(nested, aid_num_max, team_count=TEAM_COUNT):
	result = {}
	if not nested or aid_num_max <= 0:
		return result
	for team in xrange(1, team_count + 1):
		team_data = _dict_get_with_str_key(nested, team, {}) if isinstance(nested, dict) else {}
		for j in xrange(1, aid_num_max + 1):
			card_id = _dict_get_with_str_key(team_data, j, None) if isinstance(team_data, dict) else None
			if card_id:
				result[(team - 1) * aid_num_max + j] = card_id
	return result


def _collect_aid_card_ids(nested):
	if not nested:
		return []
	ids = []
	if isinstance(nested, dict):
		for team_data in nested.values():
			if isinstance(team_data, dict):
				ids.extend([v for v in team_data.values() if v])
			elif isinstance(team_data, list):
				ids.extend(filter(None, team_data))
	elif isinstance(nested, list):
		ids.extend(filter(None, nested))
	return ids


def _get_runtime_cache(role):
	cache = getattr(role, '_cross_supremacy_cache', None)
	if not isinstance(cache, dict):
		cache = {}
		role._cross_supremacy_cache = cache
	return cache


def _build_card_attrs(game, cards_map, aid_cards, scene=SUPREMACY_SCENE):
	card_attrs = {}
	card_attrs2 = {}
	all_cards = []
	for team in xrange(1, TEAM_COUNT + 1):
		team_cards = transform2list(cards_map.get(team, []))
		cards_map[team] = team_cards
		all_cards.extend(team_cards)
		attrs, attrs2 = game.cards.makeBattleCardModel(team_cards, scene)
		card_attrs.update(attrs)
		card_attrs2.update(attrs2)
	passive_skills = game.cards.markBattlePassiveSkills(all_cards, scene)
	
	aid_fp = 0
	aid_card_ids = _collect_aid_card_ids(aid_cards)
	if aid_card_ids:
		aid_attrs, aid_attrs2 = game.cards.makeBattleCardModel(aid_card_ids, scene, is_aid=True)
		card_attrs.update(aid_attrs)
		card_attrs2.update(aid_attrs2)
		for aid_attr in aid_attrs.values():
			aid_fp += aid_attr.get('aid_fighting_point', 0)
	return card_attrs, card_attrs2, passive_skills, aid_fp


def _build_record_base(cards, defence_cards, aid_cards, defence_aid_cards, elite_cards, elite_aid_cards, extra, defence_extra):
	cards_map = _split_cards(cards)
	defence_cards_map = _split_cards(defence_cards)
	aid_num_max = _get_aid_num_max()

	aid_nested = _convert_aid_cards_to_nested(aid_cards, aid_num_max)
	defence_aid_nested = _convert_aid_cards_to_nested(defence_aid_cards, aid_num_max)

	extra_list = _normalize_extra_list(extra)
	defence_extra_list = _normalize_extra_list(defence_extra)

	return {
		'cards': cards_map,
		'defence_cards': defence_cards_map,
		'aid_cards': aid_nested,
		'defence_aid_cards': defence_aid_nested,
		'elite_cards': elite_cards or [],
		'elite_aid_cards': elite_aid_cards or [],
		'extra': extra_list,
		'defence_extra': defence_extra_list,
	}


def _build_role_record(game, cards, defence_cards, aid_cards, defence_aid_cards, elite_cards, elite_aid_cards, extra, defence_extra):
	cards_map = _split_cards(cards)
	defence_cards_map = _split_cards(defence_cards)
	aid_num_max = _get_aid_num_max()
	
	aid_nested = _convert_aid_cards_to_nested(aid_cards, aid_num_max)
	defence_aid_nested = _convert_aid_cards_to_nested(defence_aid_cards, aid_num_max)

	extra_list = _normalize_extra_list(extra)
	defence_extra_list = _normalize_extra_list(defence_extra)

	card_attrs, card_attrs2, passive_skills, aid_fp = _build_card_attrs(game, cards_map, aid_nested)
	defence_attrs, defence_attrs2, defence_passive_skills, defence_aid_fp = _build_card_attrs(game, defence_cards_map, defence_aid_nested)

	return {
		'cards': cards_map,
		'defence_cards': defence_cards_map,
		'card_attrs': card_attrs,
		'card_attrs2': card_attrs2,
		'defence_card_attrs': defence_attrs,
		'defence_card_attrs2': defence_attrs2,
		'passive_skills': passive_skills,
		'defence_passive_skills': defence_passive_skills,
		'aid_cards': aid_nested,
		'defence_aid_cards': defence_aid_nested,
		'elite_cards': elite_cards or [],
		'elite_aid_cards': elite_aid_cards or [],
		'extra': extra_list,
		'defence_extra': defence_extra_list,
		'aid_fighting_point': aid_fp,
		'defence_aid_fighting_point': defence_aid_fp,
	}


def _build_record_view(game, record):
	if not record or not isinstance(record, dict):
		record = _build_default_record(game)
	role = game.role
	cards = record.get('cards', None) or _get_default_cards(role)
	defence_cards = record.get('defence_cards', None) or cards
	aid_cards = record.get('aid_cards', {})
	defence_aid_cards = record.get('defence_aid_cards', {})
	elite_cards = record.get('elite_cards', [])
	elite_aid_cards = record.get('elite_aid_cards', [])
	extra_raw = record.get('extra', {'weather': 0, 'arms': []})
	defence_extra_raw = record.get('defence_extra', {'weather': 0, 'arms': []})
	return _build_role_record(
		game,
		cards,
		defence_cards,
		aid_cards,
		defence_aid_cards,
		elite_cards,
		elite_aid_cards,
		extra_raw,
		defence_extra_raw,
	)


def _get_initial_grade():
	grades = getattr(csv.cross.supremacy, 'grade', {}) or {}
	if not grades:
		return 1, None
	min_item = None
	min_score = None
	for grade_id, cfg in _iter_csv_items(grades):
		score = getattr(cfg, 'score', 0) or 0
		if min_score is None or score < min_score:
			min_score = score
			min_item = (grade_id, cfg)
	return min_item


def _get_grade_by_score(score):
	grades = getattr(csv.cross.supremacy, 'grade', {}) or {}
	if not grades:
		return 1, None
	items = sorted(_iter_csv_items(grades), key=lambda kv: getattr(kv[1], 'score', 0) or 0, reverse=True)
	for grade_id, cfg in items:
		need = getattr(cfg, 'score', 0) or 0
		if score >= need:
			return grade_id, cfg
	return items[-1]


def _update_supremacy_res(data, now=None):
	if now is None:
		now = nowtime_t()
	last_time = data.get('last_product_time', now) or now
	if now <= last_time:
		return
	delta_minutes = int((now - last_time) / 60)
	if delta_minutes <= 0:
		return

	grade_id = data.get('grade', 0)
	grade_cfg = _csv_get(getattr(csv.cross.supremacy, 'grade', {}), grade_id, None)
	minute_res = getattr(grade_cfg, 'minuteRes', {}) if grade_cfg else {}
	grow_limit = getattr(grade_cfg, 'growResLimit', {}) if grade_cfg else {}

	event = data.get('event', {}) or {}
	buff_map = event.get('buff', {}) or {}
	buff_ratio = 0
	expired = []
	for event_id, start_time in buff_map.iteritems():
		cfg = _csv_get(getattr(csv.cross.supremacy, 'event_lib', {}), event_id, None)
		if not cfg:
			expired.append(event_id)
			continue
		buff_time = getattr(cfg, 'buffTime', 0) or 0
		if start_time + buff_time <= now:
			expired.append(event_id)
			continue
		buff_ratio = max(buff_ratio, getattr(cfg, 'buffRouduct', 0) or 0)
	for event_id in expired:
		buff_map.pop(event_id, None)
	if expired:
		event['buff'] = buff_map
		data['event'] = event

	res = data.get('res', {}) or {}
	for key, rate in minute_res.iteritems():
		if rate is None:
			continue
		add = rate * delta_minutes
		if buff_ratio:
			add += add * buff_ratio / 100.0
		add = int(add)
		if add <= 0:
			continue
		current = res.get(key, 0) or 0
		limit = grow_limit.get(key, 0) or 0
		if limit > 0:
			res[key] = min(current + add, limit)
		else:
			res[key] = current + add
	data['res'] = res
	data['last_product_time'] = now


def _get_default_cards(role):
	cards = list(role.top_cards or [])
	cards = cards[:18]
	if len(cards) < 18:
		cards += [None for _ in xrange(18 - len(cards))]
	return cards


def _build_default_record(game):
	role = game.role
	cards = _get_default_cards(role)
	cards_map = _split_cards(cards)

	card_embattle = role.card_embattle.get('cross_supremacy', {}) if role.card_embattle else {}
	aid_cards = card_embattle.get('aid_cards', {})
	defence_aid_cards = card_embattle.get('defence_aid_cards', {})

	extra_raw = card_embattle.get('extra', {'weather': 0, 'arms': []})
	defence_extra_raw = card_embattle.get('defence_extra', {'weather': 0, 'arms': []})

	return _build_record_base(
		cards_map,
		cards_map,
		aid_cards,
		defence_aid_cards,
		[],
		[],
		extra_raw,
		defence_extra_raw,
	)


def _ensure_supremacy_data(game):
	role = game.role
	data = role.cross_supremacy_datas or {}
	changed = False

	if not data:
		init_grade = _get_initial_grade()
		if init_grade:
			grade_id, grade_cfg = init_grade
			init_score = getattr(grade_cfg, 'score', 0) or 0
		else:
			grade_id, init_score = 1, 0
		data = {
			'grade': grade_id,
			'score': init_score,
			'res': {},
			'last_product_time': nowtime_t(),
			'event': _default_event_data(),
			'record': _build_default_record(game),
			'enemies': [],
			'enemy_records': {},
			'memorial_records': {},
			'memorial_ranks': [],
			'history': [],
			'top_battle_history': [],
			'history_num': 0,
			'last_rank': [],
			'play_records': {},
			'round': 'start',
		}
		role.cross_supremacy_datas = data
		return data

	# 补全字段
	defaults = {
		'grade': _get_initial_grade()[0] if _get_initial_grade() else 1,
		'score': 0,
		'res': {},
		'last_product_time': nowtime_t(),
		'event': _default_event_data(),
		'enemies': [],
		'enemy_records': {},
		'memorial_records': {},
		'memorial_ranks': [],
		'history': [],
		'top_battle_history': [],
		'history_num': 0,
		'last_rank': [],
		'play_records': {},
		'round': 'start',
	}
	for k, v in defaults.iteritems():
		if k not in data:
			data[k] = v
			changed = True
	event = data.get('event', None)
	event_changed = False
	if not isinstance(event, dict):
		event_changed = True
	else:
		for key in _default_event_data():
			if key not in event:
				event_changed = True
				break
	if event_changed:
		changed = True
	_ensure_event_data(data)

	record = data.get('record', None)
	if not isinstance(record, dict):
		record = _build_default_record(game)
		data['record'] = record
		changed = True
	else:
		cards = record.get('cards', None) or _get_default_cards(role)
		defence_cards = record.get('defence_cards', None) or cards
		aid_cards = record.get('aid_cards', {})
		defence_aid_cards = record.get('defence_aid_cards', {})
		elite_cards = record.get('elite_cards', [])
		elite_aid_cards = record.get('elite_aid_cards', [])
		extra_raw = record.get('extra', {'weather': 0, 'arms': []})
		defence_extra_raw = record.get('defence_extra', {'weather': 0, 'arms': []})
		record = _build_record_base(
			cards,
			defence_cards,
			aid_cards,
			defence_aid_cards,
			elite_cards,
			elite_aid_cards,
			extra_raw,
			defence_extra_raw,
		)
		data['record'] = record
		changed = True

	if 'battle_cache' in data:
		data.pop('battle_cache', None)
		changed = True
	play_records = data.get('play_records', None)
	if not isinstance(play_records, dict) or play_records:
		data['play_records'] = {}
		changed = True

	enemies = data.get('enemies', [])
	if isinstance(enemies, list):
		enemy_changed = False
		cleaned = []
		for enemy in enemies:
			if not isinstance(enemy, dict):
				enemy_changed = True
				continue
			if _normalize_enemy_entry(enemy, role.areaKey):
				enemy_changed = True
			cleaned.append(enemy)
		if enemy_changed:
			data['enemies'] = cleaned
			changed = True
	elif enemies:
		data['enemies'] = []
		changed = True

	if changed:
		role.cross_supremacy_datas = data
	return data


def _make_cross_supremacy_model(game, data):
	csv_id, cfg = _get_service_cfg()
	date = getattr(cfg, 'date', 0) if cfg else 0
	servers = getattr(cfg, 'servers', []) if cfg else []
	role = game.role
	round_state = data.get('round', 'start')
	last_rank = data.get('last_rank', [])
	top_history = data.get('top_battle_history', [])

	cross_model = ObjectCrossSupremacyGameGlobal.getCrossGameModel(role.areaKey)
	if cross_model:
		cross_csv_id = cross_model.get('csvID', 0)
		if cross_csv_id:
			csv_id = cross_csv_id
			date = cross_model.get('date', date)
			servers = cross_model.get('servers', servers)
			last_rank = cross_model.get('lastRanks', last_rank)
		round_state = cross_model.get('round', round_state)
	if not ObjectCrossSupremacyGameGlobal.isOpen(role.areaKey):
		global_history = ObjectCrossSupremacyGameGlobal.getTopBattleHistory(role.areaKey)
		if global_history is not None:
			top_history = global_history
	last_rank = _normalize_rank_entries(game, last_rank)
	record_view = _build_record_view(game, data.get('record', None))

	return {
		'csvID': csv_id,
		'date': date,
		'round': round_state,
		'historyNum': data.get('history_num', 0),
		'lastRank': last_rank,
		'lastProductTime': data.get('last_product_time', nowtime_t()),
		'role': {
			'id': role.id,
			'name': role.name,
			'level': role.level,
			'grade': data.get('grade', 1),
			'score': data.get('score', 0),
			'figure': getattr(role, 'figure', 0),
			'res': data.get('res', {}),
			'event': data.get('event', {'event_id': 0, 'buff': {}}),
		},
		'record': record_view,
		'enemies': data.get('enemies', []),
		'servers': servers,
		'topBattleHistory': top_history,
	}


def _make_rank_entry(game, data):
	role = game.role
	return {
		'record_db_id': objectid2string(role.id),
		'role_db_id': objectid2string(role.id),
		'game_key': role.areaKey,
		'name': role.name,
		'level': role.level,
		'score': data.get('score', 0),
		'fighting_point': getattr(role, 'top12_fighting_point', 0),
		'logo': role.logo,
		'frame': role.frame,
		'figure': getattr(role, 'figure', 0) or 1,
		'title': getattr(role, 'title_id', 0),
	}


def _build_rank_list():
	games, guard = ObjectGame.getAll()
	ranks = []
	for game in games:
		if not game or not getattr(game, 'role', None):
			continue
		data = _ensure_supremacy_data(game)
		ranks.append(_make_rank_entry(game, data))
	ranks.sort(key=lambda x: (-x.get('score', 0), -x.get('fighting_point', 0)))
	return ranks


def _get_match_range(score, idx):
	match_cfgs = getattr(csv.cross.supremacy, 'match', {}) or {}
	for _, cfg in _iter_csv_items(match_cfgs):
		range_cfg = getattr(cfg, 'range', None)
		if not range_cfg:
			continue
		low, high = range_cfg
		if low <= score <= high:
			field = 'matchRange%d' % idx
			match_range = getattr(cfg, field, None)
			if match_range:
				return match_range
	return [-50, 50]


def _is_supremacy_fight_time(now=None):
	now = now or nowdatetime_t()
	weekday = now.isoweekday()
	if weekday not in (5, 6, 7):
		return False
	if weekday == 5 and now.hour < 10:
		return False
	return True


def _check_supremacy_open(game, data=None):
	role = game.role
	if ObjectCrossSupremacyGameGlobal.isOpen(role.areaKey):
		return
	data = data or _ensure_supremacy_data(game)
	model = _make_cross_supremacy_model(game, data)
	cross_model = ObjectCrossSupremacyGameGlobal.getCrossGameModel(role.areaKey)
	history_num = data.get('history_num', 0) or 0
	has_history = bool(cross_model.get('lastRanks', [])) or history_num > 0
	err = 'crossSupremacySeasonEnd' if has_history else 'crossSupremacyNotOpen'
	raise ClientError(err, model={'cross_supremacy': model})


def _make_robot_cards(card_lists, level, advance, star, record_id):
	fake_card = ObjectCard(None, None)
	fake_card.new_deepcopy()

	card_attrs = {}
	card_attrs2 = {}
	cards_map = {}
	total_fp = 0
	idx = 1
	
	for team in xrange(1, TEAM_COUNT + 1):
		team_cards = []
		raw_cards = card_lists[team - 1] if team - 1 < len(card_lists) else []
		for pos, card_csv_id in enumerate(raw_cards, 1):
			if not card_csv_id or card_csv_id not in csv.cards:
				continue
			card_cfg = csv.cards[card_csv_id]
			skills = {}
			skill_levels = []
			for skill_id in card_cfg.skillList:
				skills[skill_id] = 1
				skill_levels.append(1)
			equips = {}
			for k, v in enumerate(card_cfg.equipsList):
				if v not in csv.equips:
					equips = None
					break
				equips[k + 1] = {
					'equip_id': v,
					'level': 1,
					'star': 0,
					'advance': 1,
					'exp': 0,
					'awake': 0,
				}
			if equips is None:
				continue
			card_id = 'robot-%s-%04d' % (record_id[:6], idx)
			idx += 1
			fake_card.set({
				'id': card_id,
				'role_db_id': None,
				'card_id': card_csv_id,
				'skin_id': 0,
				'advance': advance,
				'star': star,
				'develop': card_cfg.develop,
				'level': level,
				'character': randomCharacter(card_cfg.chaRnd),
				'nvalue': randomNumericalValue(card_cfg.nValueRnd),
				'skills': skills,
				'skill_level': skill_levels,
				'effort_values': {},
				'effort_advance': 1,
				'equips': equips,
				'fetters': [],
				'fighting_point': 0,
				'held_item': None,
				'abilities': {},
				'zawake_skills': [],
				'zawake_nvalue': {},
			}).initRobot()
			in_front = pos <= 3
			in_back = pos > 3
			attrs = fake_card.battleModel(in_front, in_back, SUPREMACY_SCENE)
			attrs['fighting_point'] = ObjectCard.calcFightingPoint(fake_card, attrs['attrs'])
			card_attrs[card_id] = attrs
			total_fp += attrs['fighting_point']
			team_cards.append(card_id)
		cards_map[team] = transform2list(team_cards)

	return cards_map, card_attrs, card_attrs2, total_fp


def _build_robot_record(cfg, score_base, game_key=None, record_id=None, seed=None):
	state = None
	if seed is not None:
		state = random.getstate()
		random.seed(seed)
	try:
		level_start = getattr(cfg, 'levelStart', None) or getattr(cfg, 'level_start', None) or 1
		level_end = getattr(cfg, 'levelEnd', None) or getattr(cfg, 'level_end', None) or level_start
		if level_end < level_start:
			level_end = level_start
		level = random.randint(level_start, level_end)

		advance_start = getattr(cfg, 'advanceStart', None) or 1
		advance_end = getattr(cfg, 'advanceEnd', None) or advance_start
		if advance_end < advance_start:
			advance_end = advance_start
		advance = random.randint(advance_start, advance_end)

		star_start = getattr(cfg, 'starStart', None) or 1
		star_end = getattr(cfg, 'starEnd', None) or star_start
		if star_end < star_start:
			star_end = star_start
		star = random.randint(star_start, star_end)

		record_id = record_id or uuid.uuid4().hex
		cards1 = list(getattr(cfg, 'cards1', []) or [])
		cards2 = list(getattr(cfg, 'cards2', []) or [])
		cards3 = list(getattr(cfg, 'cards3', []) or [])
		cards_map, card_attrs, card_attrs2, total_fp = _make_robot_cards([cards1, cards2, cards3], level, advance, star, record_id)

		elite_cards = list(getattr(cfg, 'eliteCards', []) or [])
		show_card = [cards1[0], 0] if cards1 else [0, 0]

		name = randomRobotName()
		logo = random.randint(1, 2)
		frame = 1
		figure = random.choice([1, 2, 3, 7, 27])

		extra = _normalize_extra_list({'weather': 0, 'arms': []})

		return {
			'record_db_id': record_id,
			'role_db_id': record_id,
			'game_key': game_key,
			'role_level': level,
			'name': name,
			'logo': logo,
			'frame': frame,
			'figure': figure,
			'score': score_base,
			'fighting_point': total_fp,
			'show_card': show_card,
			'cards': cards_map,
			'defence_cards': cards_map,
			'card_attrs': card_attrs,
			'defence_card_attrs': card_attrs,
			'card_attrs2': card_attrs2,
			'defence_card_attrs2': card_attrs2,
			'passive_skills': {},
			'defence_passive_skills': {},
			'aid_cards': {1: {}, 2: {}, 3: {}},
			'defence_aid_cards': {1: {}, 2: {}, 3: {}},
			'elite_cards': elite_cards,
			'elite_aid_cards': [],
			'extra': extra,
			'defence_extra': extra,
			'title': 0,
		}
	finally:
		if state is not None:
			random.setstate(state)


def _generate_enemies(game, data, count=3, start_idx=1):
	grade_id = data.get('grade', 1)
	robots = [cfg for _, cfg in _iter_csv_items(getattr(csv.cross.supremacy, 'robots', {}) or {}) if getattr(cfg, 'grade', 0) == grade_id]
	if not robots:
		robots = [cfg for _, cfg in _iter_csv_items(getattr(csv.cross.supremacy, 'robots', {}) or {})]
	if not robots:
		return [], {}

	chosen = WeightRandomObject.onceSample(robots, count, wgetter=lambda c: getattr(c, 'weight', 1) or 1)
	if len(chosen) < count:
		chosen = chosen + [random.choice(robots) for _ in xrange(count - len(chosen))]

	enemies = []
	enemy_records = {}
	base_score = data.get('score', 0)
	for offset, cfg in enumerate(chosen):
		idx = start_idx + offset
		match_range = _get_match_range(base_score, idx)
		score = max(0, base_score + random.randint(match_range[0], match_range[1]))
		record = _build_robot_record(cfg, score, game_key=game.role.areaKey)
		enemy_records[record['record_db_id']] = record
		enemies.append({
			'record_db_id': record['record_db_id'],
			'role_db_id': record['role_db_id'],
			'game_key': game.role.areaKey,
			'name': record['name'],
			'level': record['role_level'],
			'score': record['score'],
			'fighting_point': record['fighting_point'],
			'title': record.get('title', 0),
			'figure': record.get('figure', 0),
			'show_card': record.get('show_card', [0, 0]),
			'logo': record.get('logo', 1),
			'frame': record.get('frame', 1),
		})
	return enemies, enemy_records


def _is_robot_record_id(record_id):
	if not isinstance(record_id, basestring):
		return False
	return len(record_id) != 24


def _is_memorial_meta_record(record):
	if not isinstance(record, dict):
		return False
	if record.get('robot_cfg_id') is None:
		return False
	if record.get('seed') is None:
		return False
	return True


def _build_memorial_meta(cfg_id, cfg, score_base, game_key=None):
	seed = random.randint(1, 2147483647)
	record_id = uuid.uuid4().hex
	record = _build_robot_record(cfg, score_base, game_key=game_key, record_id=record_id, seed=seed)
	return {
		'record_db_id': record_id,
		'role_db_id': record_id,
		'game_key': game_key,
		'role_level': record.get('role_level', 1),
		'name': record.get('name', ''),
		'logo': record.get('logo', 1),
		'frame': record.get('frame', 1),
		'figure': record.get('figure', 1) or 1,
		'score': record.get('score', 0),
		'fighting_point': record.get('fighting_point', 0),
		'show_card': record.get('show_card', [0, 0]),
		'title': record.get('title', 0),
		'robot_cfg_id': cfg_id,
		'seed': seed,
	}


def _make_memorial_rank_entry(meta):
	return {
		'record_db_id': meta.get('record_db_id'),
		'role_db_id': meta.get('role_db_id'),
		'game_key': meta.get('game_key'),
		'name': meta.get('name', ''),
		'level': meta.get('role_level', 1),
		'score': meta.get('score', 0),
		'fighting_point': meta.get('fighting_point', 0),
		'title': meta.get('title', 0),
		'figure': meta.get('figure', 0),
		'show_card': meta.get('show_card', [0, 0]),
		'logo': meta.get('logo', 1),
		'frame': meta.get('frame', 1),
	}


def _generate_memorial_entries(game, data, count=3):
	grade_id = data.get('grade', 1)
	robots = [(cfg_id, cfg) for cfg_id, cfg in _iter_csv_items(getattr(csv.cross.supremacy, 'robots', {}) or {}) if getattr(cfg, 'grade', 0) == grade_id]
	if not robots:
		robots = [(cfg_id, cfg) for cfg_id, cfg in _iter_csv_items(getattr(csv.cross.supremacy, 'robots', {}) or {})]
	if not robots:
		return [], {}

	chosen = WeightRandomObject.onceSample(robots, count, wgetter=lambda item: getattr(item[1], 'weight', 1) or 1)
	if len(chosen) < count:
		chosen = chosen + [random.choice(robots) for _ in xrange(count - len(chosen))]

	ranks = []
	memorial_records = {}
	base_score = data.get('score', 0)
	for idx, item in enumerate(chosen, 1):
		cfg_id, cfg = item
		match_range = _get_match_range(base_score, idx)
		score = max(0, base_score + random.randint(match_range[0], match_range[1]))
		meta = _build_memorial_meta(cfg_id, cfg, score, game_key=game.role.areaKey)
		memorial_records[meta['record_db_id']] = meta
		ranks.append(_make_memorial_rank_entry(meta))
	return ranks, memorial_records


def _build_memorial_dummy(game, data, count):
	if count <= 0:
		return [], {}
	enemies, enemy_records = _generate_memorial_entries(game, data, count)
	if not enemies:
		return [], {}
	for idx, enemy in enumerate(enemies, 1):
		if not enemy.get('name'):
			enemy['name'] = 'MemorialBot%02d' % idx
	return enemies, enemy_records


def _memorial_records_ready(memorial_ranks, memorial_records):
	if not isinstance(memorial_ranks, list):
		return False
	if not isinstance(memorial_records, dict):
		return False
	for rank in memorial_ranks[:8]:
		record_id = None
		if isinstance(rank, dict):
			record_id = rank.get('record_db_id', None) or rank.get('role_db_id', None)
		if not _is_robot_record_id(record_id):
			continue
		meta = _get_record_by_id(memorial_records, record_id)
		if not _is_memorial_meta_record(meta):
			return False
	return True


def _get_or_build_memorial_ranks(game, data, base_ranks):
	memorial_ranks = data.get('memorial_ranks', [])
	memorial_records = data.get('memorial_records', {})
	if isinstance(memorial_ranks, list) and len(memorial_ranks) >= 8 and _memorial_records_ready(memorial_ranks, memorial_records):
		return memorial_ranks[:8]
	ranks = list(base_ranks)
	if len(ranks) < 8:
		need = 8 - len(ranks)
		dummy_ranks, dummy_records = _build_memorial_dummy(game, data, need)
		if dummy_ranks:
			ranks = ranks + dummy_ranks
			data['memorial_records'] = dummy_records
			data['memorial_ranks'] = ranks[:8]
	return ranks[:8]


def _record_has_battle_data(record):
	if not isinstance(record, dict):
		return False
	if 'defence_card_attrs' in record or 'card_attrs' in record:
		return True
	return False


def _record_has_lineup(record):
	if not isinstance(record, dict):
		return False
	card_attrs = record.get('defence_card_attrs', None)
	if card_attrs is None:
		card_attrs = record.get('card_attrs', None)
	return bool(card_attrs)


def _filter_cards_map_by_attrs(cards_map, attrs):
	if not isinstance(cards_map, dict) or not isinstance(attrs, dict):
		return cards_map
	cleaned = {}
	for team, cards in cards_map.iteritems():
		team_cards = transform2list(cards)
		out = []
		for card_id in team_cards:
			out.append(card_id if card_id in attrs else None)
		cleaned[team] = out
	return cleaned


@coroutine
def _build_offline_record_view(dbc_game, role_db, record):
	from framework.distributed.helper import multi_future
	from game.object.game import ObjectGame
	if not role_db:
		raise Return(None)
	game = ObjectGame(dbc_game, lambda *_args, **_kwargs: None)
	game.disableModelWatch = True
	role_id = role_db.get('id', None)
	try:
		game.role.set(role_db)

		futures = {}
		cards = role_db.get('cards', []) or []
		if cards:
			futures['cards'] = dbc_game.call_async('DBMultipleRead', 'RoleCard', cards)
		held_items = role_db.get('held_items', []) or []
		if held_items:
			futures['held_items'] = dbc_game.call_async('DBMultipleRead', 'RoleHeldItem', held_items)
		gems = role_db.get('gems', []) or []
		if gems:
			futures['gems'] = dbc_game.call_async('DBMultipleRead', 'RoleGem', gems)
		chips = role_db.get('chips', []) or []
		if chips:
			futures['chips'] = dbc_game.call_async('DBMultipleRead', 'RoleChip', chips)
		emeras = role_db.get('emeras', []) or []
		if emeras:
			futures['emeras'] = dbc_game.call_async('DBMultipleRead', 'RoleEmera', emeras)
		contracts = role_db.get('contracts', []) or []
		if contracts:
			futures['contracts'] = dbc_game.call_async('DBMultipleRead', 'RoleContract', contracts)
		totem_db_id = role_db.get('totem_db_id', None)
		if totem_db_id:
			futures['totem'] = dbc_game.call_async('DBRead', 'Totem', totem_db_id, False)

		results = yield multi_future(futures, rasie_exc=False) if futures else {}

		def _models(key):
			data = results.get(key, None)
			if isinstance(data, dict) and data.get('ret'):
				return data.get('models', []) or []
			return []

		game.cards.set(_models('cards'))
		game.heldItems.set(_models('held_items'))
		game.gems.set(_models('gems'))
		game.chips.set(_models('chips'))
		game.emeras.set(_models('emeras'))
		game.contracts.set(_models('contracts'))

		totem_model = {}
		totem_data = results.get('totem', None)
		if isinstance(totem_data, dict) and totem_data.get('ret') and totem_data.get('model'):
			totem_model = totem_data['model']
		game.totem.set(totem_model)

		role = game.role
		role._initTitle()
		role._initCardSkin()
		role._initFigure()
		role._initUnionSkill()
		role._initSkillFigures()

		game.talentTree.init()
		game.pokedex.init()
		game.trainer.init()
		game.feels.init()
		game.zawake.init()
		game.explorer.init()
		game.gymTalentTree.init()
		game.badge.init()
		game.medal.set().init()
		game.meteorite.set().init()
		game.totem.init()

		game.heldItems.init()
		game.gems.init()
		game.chips.init()
		game.emeras.init()
		game.contracts.init()

		game.fishing = None

		if not game.cards._objs:
			raise Return(None)

		game.cards.init()
		record_view = _build_record_view(game, record)
		record_view['cards'] = _filter_cards_map_by_attrs(record_view.get('cards', {}), record_view.get('card_attrs', {}))
		record_view['defence_cards'] = _filter_cards_map_by_attrs(record_view.get('defence_cards', {}), record_view.get('defence_card_attrs', {}))
		raise Return(record_view)
	except Exception as e:
		logger.warning('cross_supremacy build offline record error: %s', e)
		raise Return(None)
	finally:
		if role_id is not None:
			ObjectGame.ObjsMap[role_id] = game
			ObjectGame.popByRoleID(role_id)


def _build_memorial_record_from_meta(game, meta):
	if not _is_memorial_meta_record(meta):
		return None
	cfg_id = meta.get('robot_cfg_id', None)
	cfg = _csv_get(getattr(csv.cross.supremacy, 'robots', {}), cfg_id, None)
	if not cfg:
		return None
	record_id = meta.get('record_db_id', None) or meta.get('role_db_id', None) or uuid.uuid4().hex
	game_key = meta.get('game_key', None) or game.role.areaKey
	score_base = meta.get('score', 0)
	seed = meta.get('seed', None)
	record = _build_robot_record(cfg, score_base, game_key=game_key, record_id=record_id, seed=seed)
	if not record:
		return None
	for key in ('role_db_id', 'game_key', 'role_level', 'name', 'logo', 'frame', 'figure', 'score', 'fighting_point', 'show_card', 'title'):
		if key in meta and meta.get(key) is not None:
			record[key] = meta.get(key)
	record['record_db_id'] = record_id
	return record


@coroutine
def _get_enemy_record(game, data, record_id, game_key=None):
	record = _get_record_by_id(data.get('enemy_records', {}), record_id)
	if record:
		raise Return(record)
	memorial_records = data.get('memorial_records', {})
	record = _get_record_by_id(memorial_records, record_id)
	if record:
		if _record_has_battle_data(record):
			raise Return(record)
		full_record = _build_memorial_record_from_meta(game, record)
		if full_record:
			raise Return(full_record)

	if game_key:
		record = yield _fetch_cross_supremacy_record(game_key, record_id)
		if record:
			raise Return(record)

	enemy_info = _find_enemy_info(data, record_id)
	enemy_game_key = enemy_info.get('game_key') if enemy_info else None
	if enemy_game_key and enemy_game_key != game.role.areaKey:
		record = yield _fetch_cross_supremacy_record(enemy_game_key, record_id)
		if record:
			raise Return(record)

	# 尝试从在线玩家中获取（同服）
	role_id = None
	if isinstance(record_id, basestring) and len(record_id) == 24:
		try:
			role_id = string2objectid(record_id)
		except Exception:
			role_id = None
	elif enemy_info:
		try:
			role_id = enemy_info.get('role_db_id')
		except Exception:
			role_id = None
	if isinstance(role_id, basestring):
		try:
			role_id = string2objectid(role_id)
		except Exception:
			role_id = None
	if role_id:
		other_game, _ = ObjectGame.getByRoleID(role_id)
		if other_game and other_game.role:
			other_data = _ensure_supremacy_data(other_game)
			record = _build_record_view(other_game, other_data.get('record', None))
			record['record_db_id'] = objectid2string(other_game.role.id)
			record['role_db_id'] = objectid2string(other_game.role.id)
			record['game_key'] = other_game.role.areaKey
			record['role_level'] = other_game.role.level
			record['name'] = other_game.role.name
			record['logo'] = other_game.role.logo
			record['frame'] = other_game.role.frame
			record['figure'] = getattr(other_game.role, 'figure', 0)
			record['score'] = other_data.get('score', 0)
			record['fighting_point'] = getattr(other_game.role, 'top12_fighting_point', 0)
			record['show_card'] = _get_show_card_from_record(record)
			raise Return(record)
	raise Return(None)


def _refresh_weekly_award(weekly_record):
	fight_times = weekly_record.cross_supremacy_week_fight
	award_map = weekly_record.cross_supremacy_week_award
	for csv_id in sorted(_csv_keys(getattr(csv.cross.supremacy, 'week_award', {}))):
		cfg = _csv_get(getattr(csv.cross.supremacy, 'week_award', {}), csv_id, None)
		if not cfg:
			continue
		if fight_times >= cfg.fightTimes and csv_id not in award_map:
			award_map[csv_id] = 1
	weekly_record.cross_supremacy_week_award = award_map


def _calc_score_move(grade_cfg, win):
	if not grade_cfg:
		return 0
	base = getattr(grade_cfg, 'battleWinScore', 0) or 0
	if win:
		ratio = getattr(grade_cfg, 'battleWinScoreRatio', 1) or 1
		return int(base * ratio)
	fail_ratio = getattr(grade_cfg, 'battleFailScoreRatio', 0) or 0
	fail_add = getattr(grade_cfg, 'failAddScore', 0) or 0
	return int(-base * fail_ratio + fail_add)


class CrossSupremacyMain(RequestHandlerTask):
	url = r'/game/cross/supremacy/main'

	@coroutine
	def run(self):
		data = _ensure_supremacy_data(self.game)
		_update_supremacy_res(data)
		_refresh_event_state(data, enter=True)

		# 更新缓存榜单
		is_open = ObjectCrossSupremacyGameGlobal.isOpen(self.game.role.areaKey)
		cross_model = ObjectCrossSupremacyGameGlobal.getCrossGameModel(self.game.role.areaKey)
		history_num = data.get('history_num', 0) or 0
		has_history = bool(cross_model.get('lastRanks', [])) or history_num > 0
		if not is_open and not has_history:
			data['last_rank'] = []
			data['memorial_records'] = {}
			data['memorial_ranks'] = []
		else:
			ranks = _build_rank_list()
			last_rank = _get_or_build_memorial_ranks(self.game, data, ranks)
			last_rank = _normalize_rank_entries(self.game, last_rank)
			data['last_rank'] = last_rank

		if is_open:
			rpc = ObjectCrossSupremacyGameGlobal.cross_client(self.game.role.areaKey)
			if rpc:
				role_info = _build_cross_role_info(self.game, data)
				try:
					yield rpc.call_async('CrossSupremacyRoleUpdate', role_info)
				except CallError, e:
					logger.warning('cross_supremacy role update error: %s', e)

		self.game.role.cross_supremacy_datas = data
		model = _make_cross_supremacy_model(self.game, data)
		top_history = yield _fetch_top_battle_history(self.game)
		if top_history is not None:
			data['top_battle_history'] = top_history
			self.game.role.cross_supremacy_datas = data
			model['topBattleHistory'] = top_history
		self.write({
			'view': {
				'cross_supremacy': model,
				'change_match_times': self.game.dailyRecord.cross_supremacy_change_times,
			},
			'model': {
				'cross_supremacy': model,
			},
		})


class CrossSupremacyMatch(RequestHandlerTask):
	url = r'/game/cross/supremacy/match'

	@coroutine
	def run(self):
		_check_supremacy_open(self.game)
		if not _is_supremacy_fight_time():
			raise ClientError('crossSupremacyNotFightTime')
		payload = self.input
		first_param = payload.get(1, None)
		if isinstance(first_param, dict) and _dict_has_any_key(first_param, (
			'change', 'change_match', 'changeMatch', 'refresh',
		)):
			payload = first_param
		change = _as_bool(_get_input_param(payload, 1, 'change', 'change_match', 'changeMatch', 'refresh'))
		data = _ensure_supremacy_data(self.game)
		role = self.game.role

		if not change and data.get('enemies'):
			# After initial match, default to refresh behavior to keep counts independent.
			change = True
		
		base_cfg = _csv_get(getattr(csv.cross.supremacy, 'base', {}), 1, None)
		free_times = getattr(base_cfg, 'matchTime', 0) or 0
		if change:
			cost_cfg = ObjectCostCSV.CostMap.get('cross_supremacy_rematch', None)
			if cost_cfg:
				cost_list = cost_cfg.seqParam
				idx = min(len(cost_list) - 1, self.game.dailyRecord.cross_supremacy_change_times)
				cost = cost_list[idx]
				if cost > 0:
					cost_aux = ObjectCostAux(self.game, {'rmb': cost})
					if not cost_aux.isEnough():
						raise ClientError('cost rmb not enough')
					cost_aux.cost(src='cross_supremacy_rematch')
			self.game.dailyRecord.cross_supremacy_change_times += 1
		else:
			available = free_times + self.game.dailyRecord.cross_supremacy_purchased_times - self.game.dailyRecord.cross_supremacy_match_times
			if available <= 0:
				raise ClientError('crossSupremacyMatchTimesNotEnough')
			self.game.dailyRecord.cross_supremacy_match_times += 1

		enemies = []
		enemy_records = {}
		if ObjectCrossSupremacyGameGlobal.isOpen(role.areaKey):
			rpc = ObjectCrossSupremacyGameGlobal.cross_client(role.areaKey)
			if rpc:
				role_info = _build_cross_role_info(self.game, data)
				try:
					enemies = yield rpc.call_async('GetCrossSupremacyMatch', role_info, 3)
				except CallError, e:
					logger.warning('cross_supremacy match error: %s', e)
					enemies = []

		if not enemies:
			enemies = []
		else:
			for enemy in enemies:
				_normalize_enemy_entry(enemy, role.areaKey)
				enemy['record_db_id'] = _normalize_id(enemy.get('record_db_id'))
				enemy['role_db_id'] = _normalize_id(enemy.get('role_db_id'))

		if enemies:
			filtered = []
			for enemy in enemies:
				record_id = enemy.get('record_db_id', None) or enemy.get('role_db_id', None)
				if not record_id:
					continue
				game_key = enemy.get('game_key', None) or role.areaKey
				record = yield _fetch_cross_supremacy_record(game_key, record_id)
				if not record or not _record_has_lineup(record):
					continue
				filtered.append(enemy)
				enemy_records[_normalize_id(record_id)] = record
			enemies = filtered

		if len(enemies) < 3:
			robots, robot_records = _generate_enemies(
				self.game,
				data,
				count=3 - len(enemies),
				start_idx=len(enemies) + 1,
			)
			enemies.extend(robots)
			enemy_records.update(robot_records)

		data['enemies'] = enemies
		data['enemy_records'] = enemy_records
		self.game.role.cross_supremacy_datas = data

		model = _make_cross_supremacy_model(self.game, data)
		self.write({
			'view': {
				'change_match_times': self.game.dailyRecord.cross_supremacy_change_times,
			},
			'model': {
				'cross_supremacy': model,
			},
		})


class CrossSupremacyMatchCancel(RequestHandlerTask):
	url = r'/game/cross/supremacy/match/cancel'

	@coroutine
	def run(self):
		data = _ensure_supremacy_data(self.game)
		data['enemies'] = []
		data['enemy_records'] = {}
		self.game.role.cross_supremacy_datas = data
		model = _make_cross_supremacy_model(self.game, data)
		self.write({'model': {'cross_supremacy': model}})


class CrossSupremacyEnemyGet(RequestHandlerTask):
	url = r'/game/cross/supremacy/enemy/get'

	@coroutine
	def run(self):
		record_id = self.input.get(1, None)
		if record_id is None:
			record_id = self.input.get('recordID', None) or self.input.get('record_id', None) or self.input.get('record_db_id', None)
		game_key = self.input.get('gameKey', None) or self.input.get('game_key', None)
		if record_id is None:
			raise ClientError('param miss')
		data = _ensure_supremacy_data(self.game)
		enemy = yield _get_enemy_record(self.game, data, record_id, game_key=game_key)
		if not enemy:
			raise ClientError('enemy not found')
		self.write({'view': enemy})


class CrossSupremacyDeploy(RequestHandlerTask):
	url = r'/game/cross/supremacy/deploy'

	@coroutine
	def run(self):
		payload = self.input
		first_param = payload.get(1, None)
		if isinstance(first_param, dict) and _dict_has_any_key(first_param, (
			'cards', 'attack_cards', 'attackCards', 'atk_cards', 'atkCards',
			'defence_cards', 'defense_cards', 'defenceCards', 'defenseCards',
			'def_cards', 'defCards',
		)):
			payload = first_param
		cards = _get_input_param(payload, 1, 'cards', 'attack_cards', 'attackCards', 'atk_cards', 'atkCards')
		defence_cards = _get_input_param(payload, 2, 'defence_cards', 'defense_cards', 'defenceCards', 'defenseCards', 'def_cards', 'defCards')
		elite_cards = _get_input_param(payload, 3, 'elite_cards', 'eliteCards')
		extra = _get_input_param(payload, 4, 'extra', 'attack_extra', 'attackExtra')
		defence_extra = _get_input_param(payload, 5, 'defence_extra', 'defense_extra', 'defenceExtra', 'defenseExtra')
		aid_cards = _get_input_param(payload, 6, 'aid_cards', 'aidCards', 'attack_aid_cards', 'attackAidCards')
		defence_aid_cards = _get_input_param(payload, 7, 'defence_aid_cards', 'defense_aid_cards', 'defenceAidCards', 'defenseAidCards')
		elite_aid_cards = _get_input_param(payload, 8, 'elite_aid_cards', 'eliteAidCards')
		if cards is None or defence_cards is None:
			raise ClientError('param miss')

		data = _ensure_supremacy_data(self.game)
		aid_num_max = _get_aid_num_max()

		aid_nested = _convert_aid_cards_to_nested(aid_cards, aid_num_max)
		defence_aid_nested = _convert_aid_cards_to_nested(defence_aid_cards, aid_num_max)

		record = _build_record_base(
			cards,
			defence_cards,
			aid_nested,
			defence_aid_nested,
			elite_cards or [],
			elite_aid_cards or [],
			extra or {'weather': 0, 'arms': []},
			defence_extra or {'weather': 0, 'arms': []},
		)
		data['record'] = record
		self.game.role.cross_supremacy_datas = data

		# 记录助战/天气到 card_embattle
		card_embattle = self.game.role.card_embattle or {}
		card_embattle.setdefault('cross_supremacy', {})
		card_embattle['cross_supremacy']['aid_cards'] = _flatten_aid_cards_to_slots(aid_nested, aid_num_max)
		card_embattle['cross_supremacy']['defence_aid_cards'] = _flatten_aid_cards_to_slots(defence_aid_nested, aid_num_max)
		card_embattle['cross_supremacy']['extra'] = record.get('extra', [])
		card_embattle['cross_supremacy']['defence_extra'] = record.get('defence_extra', [])
		self.game.role.card_embattle = card_embattle

		model = _make_cross_supremacy_model(self.game, data)
		self.write({'model': {'cross_supremacy': model}})


class CrossSupremacyBattleStart(RequestHandlerTask):
	url = r'/game/cross/supremacy/battle/start'

	@coroutine
	def run(self):
		_check_supremacy_open(self.game)
		if not _is_supremacy_fight_time():
			raise ClientError('crossSupremacyNotFightTime')
		param = self.input.get(1, None)
		record_id = None
		if isinstance(param, basestring):
			record_id = param
		elif isinstance(param, dict):
			record_id = (
				param.get('record_db_id', None) or
				param.get('recordID', None) or
				param.get('record_id', None) or
				param.get('role_db_id', None) or
				param.get('enemyRoleID', None)
			)
		if record_id is None:
			record_id = (
				_get_input_param(self.input, 1, 'record_db_id', 'recordID', 'record_id', 'role_db_id', 'enemyRoleID') or
				self.input.get('record_db_id', None) or
				self.input.get('recordID', None) or
				self.input.get('record_id', None) or
				self.input.get('role_db_id', None) or
				self.input.get('enemyRoleID', None)
			)
		if record_id is None:
			raise ClientError('param miss')

		data = _ensure_supremacy_data(self.game)
		enemy_record = yield _get_enemy_record(self.game, data, record_id)
		if not enemy_record:
			raise ClientError('enemy not found')
		enemy_info = _find_enemy_info(data, record_id) or {}

		record = _build_record_view(self.game, data.get('record', None))
		battle_id = uuid.uuid4().hex
		rand_seed = random.randint(1, 99999999)

		enemy_name = enemy_info.get('name', '') or enemy_record.get('name', '')
		enemy_logo = enemy_info.get('logo', 1) or enemy_record.get('logo', 1)
		enemy_frame = enemy_info.get('frame', 1) or enemy_record.get('frame', 1)
		enemy_level = enemy_info.get('level', 1) or enemy_record.get('role_level', 1)
		enemy_game_key = enemy_info.get('game_key') or enemy_record.get('game_key') or self.game.role.areaKey
		enemy_score = enemy_info.get('score', None)
		if enemy_score is None:
			enemy_score = enemy_record.get('score', 0)

		battle = {
			'id': battle_id,
			'rand_seed': rand_seed,
			'role_key': [self.game.role.areaKey],
			'defence_role_key': [enemy_game_key],
			'cards': record.get('cards', {}),
			'defence_cards': enemy_record.get('defence_cards', {}),
			'card_attrs': record.get('card_attrs', {}),
			'card_attrs2': record.get('card_attrs2', {}),
			'defence_card_attrs': enemy_record.get('defence_card_attrs', {}),
			'defence_card_attrs2': enemy_record.get('defence_card_attrs2', {}),
			'passive_skills': record.get('passive_skills', {}),
			'defence_passive_skills': enemy_record.get('defence_passive_skills', {}),
			'aid_cards': record.get('aid_cards', {}),
			'defence_aid_cards': enemy_record.get('defence_aid_cards', {}),
			'extra': record.get('extra', []),
			'defence_extra': enemy_record.get('defence_extra', []),
			'level': self.game.role.level,
			'name': self.game.role.name,
			'defence_name': enemy_name,
			'logo': self.game.role.logo,
			'frame': self.game.role.frame,
			'defence_logo': enemy_logo,
			'defence_frame': enemy_frame,
		}

		runtime_cache = _get_runtime_cache(self.game.role)
		runtime_cache['battle_cache'] = {
			'enemy_record_id': record_id,
			'enemy_name': enemy_name,
			'enemy_logo': enemy_logo,
			'enemy_frame': enemy_frame,
			'enemy_level': enemy_level,
			'enemy_game_key': enemy_game_key,
			'enemy_score': enemy_score,
			'score_before': data.get('score', 0),
			'battle_model': battle,
		}
		self.game.role.cross_supremacy_datas = data
		self.write({'model': {'cross_supremacy_battle': battle}})


class CrossSupremacyBattleEnd(RequestHandlerTask):
	url = r'/game/cross/supremacy/battle/end'

	@coroutine
	def run(self):
		payload = self.input
		first_param = payload.get(1, None)
		if isinstance(first_param, dict) and _dict_has_any_key(first_param, (
			'result', 'battle_result', 'battleResult',
			'stats', 'stat', 'waveResult', 'wave_result', 'roundResult', 'round_result',
			'isTopBattle', 'topBattle', 'is_top_battle', 'top_battle',
		)):
			payload = first_param
		result = _get_input_param(payload, 1, 'result', 'battle_result', 'battleResult')
		param2 = _get_input_param(payload, 2, 'stats', 'stat', 'waveResult', 'wave_result', 'roundResult', 'round_result', 'isTopBattle', 'topBattle', 'is_top_battle', 'top_battle')
		param3 = _get_input_param(payload, 3, 'isTopBattle', 'topBattle', 'is_top_battle', 'top_battle')
		stats = None
		is_top_battle = False
		if isinstance(param2, (list, dict)):
			stats = param2
			is_top_battle = bool(param3)
		else:
			is_top_battle = bool(param3 if param3 is not None else param2)
		if result is None:
			raise ClientError('param miss')

		data = _ensure_supremacy_data(self.game)
		runtime_cache = _get_runtime_cache(self.game.role)
		cache = runtime_cache.get('battle_cache', None)
		if not cache:
			cache = data.get('battle_cache', None)
		if not cache:
			raise ClientError('battle not found')

		win = (result == 'win')
		grade_id, grade_cfg = _get_grade_by_score(data.get('score', 0))
		score_move = _calc_score_move(grade_cfg, win)
		score_before = cache.get('score_before', data.get('score', 0))
		score_after = max(0, score_before + score_move)
		new_grade_id, _ = _get_grade_by_score(score_after)

		data['score'] = score_after
		data['grade'] = new_grade_id

		event = _ensure_event_data(data)
		event['battle_times'] = (event.get('battle_times', 0) or 0) + 1
		if win:
			event['win_times'] = (event.get('win_times', 0) or 0) + 1
		data['event'] = event
		_refresh_event_state(data)

		# 周次数记录
		weekly = self.game.weeklyRecord
		weekly.cross_supremacy_week_fight += 1
		_refresh_weekly_award(weekly)

		# 奖励
		award = {}
		award_cfg = grade_cfg.battleWinAward if win else grade_cfg.battleFailAward
		if award_cfg:
			eff = ObjectGainAux(self.game, award_cfg)
			yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_supremacy_battle')
			award = eff.result

		# 战报
		record_id = uuid.uuid4().hex
		play_record_id = record_id
		battle_model = copy.deepcopy(cache.get('battle_model', {}))
		battle_model['result'] = result
		if stats is not None:
			battle_model['stats'] = stats

		cross_key = ObjectCrossSupremacyGameGlobal.getCrossKey(self.game.role.areaKey) or self.game.role.areaKey
		if ObjectCrossSupremacyGameGlobal.isOpen(self.game.role.areaKey):
			rpc = ObjectCrossSupremacyGameGlobal.cross_client(self.game.role.areaKey)
			if rpc:
				try:
					cross_id = yield rpc.call_async('SaveCrossSupremacyPlayRecord', battle_model)
					if cross_id:
						play_record_id = objectid2string(cross_id) if not isinstance(cross_id, basestring) else cross_id
				except CallError, e:
					logger.warning('cross_supremacy save play record error: %s', e)

		runtime_cache.setdefault('play_records', {})[play_record_id] = battle_model

		history_entry = {
			'enemy_level': cache.get('enemy_level', 1),
			'enemy_name': cache.get('enemy_name', ''),
			'enemy_game_key': cache.get('enemy_game_key', ''),
			'enemy_logo': cache.get('enemy_logo', 1),
			'enemy_frame': cache.get('enemy_frame', 1),
			'result': result,
			'move': score_move,
			'score': score_before,
			'battle_mode': 1,
			'time': nowtime_t(),
			'play_record_id': play_record_id,
			'role_key': [self.game.role.areaKey],
			'cross_key': cross_key,
		}
		data.setdefault('history', []).append(history_entry)
		data['history'] = data['history'][-50:]

		if is_top_battle:
			best_entry = {
				'name': self.game.role.name,
				'defence_name': cache.get('enemy_name', ''),
				'logo': self.game.role.logo,
				'frame': self.game.role.frame,
				'defence_logo': cache.get('enemy_logo', 1),
				'defence_frame': cache.get('enemy_frame', 1),
				'score': score_before,
				'defence_score': cache.get('enemy_score', 0),
				'role_key': [self.game.role.areaKey],
				'defence_role_key': [cache.get('enemy_game_key', '')],
				'result': result,
				'play_record_id': play_record_id,
				'cross_key': cross_key,
			}
			data.setdefault('top_battle_history', []).append(best_entry)
			data['top_battle_history'] = data['top_battle_history'][-20:]
			if ObjectCrossSupremacyGameGlobal.isOpen(self.game.role.areaKey):
				rpc = ObjectCrossSupremacyGameGlobal.cross_client(self.game.role.areaKey)
				if rpc:
					try:
						yield rpc.call_async('CrossSupremacyAddTopBattleHistory', self.game.role.areaKey, best_entry)
					except CallError, e:
						logger.warning('cross_supremacy top battle history error: %s', e)

		# 清理对手列表
		data['enemies'] = []
		data['enemy_records'] = {}
		runtime_cache.pop('battle_cache', None)
		data.pop('battle_cache', None)

		if ObjectCrossSupremacyGameGlobal.isOpen(self.game.role.areaKey):
			rpc = ObjectCrossSupremacyGameGlobal.cross_client(self.game.role.areaKey)
			if rpc:
				role_info = _build_cross_role_info(self.game, data)
				try:
					yield rpc.call_async('CrossSupremacyRoleUpdate', role_info)
				except CallError, e:
					logger.warning('cross_supremacy battle update error: %s', e)

		self.game.role.cross_supremacy_datas = data
		model = _make_cross_supremacy_model(self.game, data)
		top_history = yield _fetch_top_battle_history(self.game)
		if top_history is not None:
			data['top_battle_history'] = top_history
			self.game.role.cross_supremacy_datas = data
			model['topBattleHistory'] = top_history
		self.write({
			'view': {
				'result': result,
				'score': score_before,
				'score_move': score_move,
				'award': award,
			},
			'model': {
				'cross_supremacy': model,
			},
		})


class CrossSupremacyRank(RequestHandlerTask):
	url = r'/game/cross/supremacy/rank'

	@coroutine
	def run(self):
		offset = self.input.get(1, 0)
		size = self.input.get(2, 10)
		rank_type = self.input.get(3, None)
		if rank_type is None:
			rank_type = self.input.get('type', None) or self.input.get('rankType', None)
		if isinstance(rank_type, basestring):
			rank_type = rank_type.lower()
		data = _ensure_supremacy_data(self.game)
		is_open = ObjectCrossSupremacyGameGlobal.isOpen(self.game.role.areaKey)
		cross_model = ObjectCrossSupremacyGameGlobal.getCrossGameModel(self.game.role.areaKey)
		history_num = data.get('history_num', 0) or 0
		has_history = bool(cross_model.get('lastRanks', [])) or history_num > 0
		if not is_open and not has_history:
			raise ClientError('crossSupremacyNotOpen')
		ranks = []
		sliced = []
		my_rank = 0
		my_info = {}

		if rank_type in ('server', 'local'):
			ranks = _build_rank_list()
			my_id = objectid2string(self.game.role.id)
			for idx, info in enumerate(ranks, 1):
				if _normalize_id(info.get('record_db_id')) == my_id:
					my_rank = idx
					my_info = info
					break
			sliced = ranks[offset:offset + size]
			self.write({
				'view': {
					'rank': {
						'ranks': sliced,
						'myRank': my_rank,
						'myInfo': my_info,
					},
				},
			})
			return

		if is_open:
			rpc = ObjectCrossSupremacyGameGlobal.cross_client(self.game.role.areaKey)
			if rpc:
				role_info = _build_cross_role_info(self.game, data)
				try:
					resp = yield rpc.call_async('GetCrossSupremacyRank', offset, size, role_info)
					if resp:
						ranks = resp.get('ranks', []) if isinstance(resp, dict) else getattr(resp, 'ranks', [])
						my_rank = resp.get('my_rank', 0) if isinstance(resp, dict) else getattr(resp, 'my_rank', 0)
						my_info = resp.get('my_info', {}) if isinstance(resp, dict) else getattr(resp, 'my_info', {})
						sliced = ranks
				except CallError, e:
					logger.warning('cross_supremacy rank error: %s', e)

		if not ranks:
			cross_model = ObjectCrossSupremacyGameGlobal.getCrossGameModel(self.game.role.areaKey)
			if cross_model:
				ranks = cross_model.get('lastRanks', []) or []
				if ranks:
					sliced = ranks[offset:offset + size]
			if not ranks:
				ranks = _build_rank_list()
				sliced = ranks[offset:offset + size]
			my_id = objectid2string(self.game.role.id)
			for idx, info in enumerate(ranks, 1):
				if _normalize_id(info.get('record_db_id')) == my_id:
					my_rank = idx
					my_info = info
					break

		self.write({
			'view': {
				'rank': {
					'ranks': sliced,
					'myRank': my_rank,
					'myInfo': my_info,
				},
			},
		})


class CrossSupremacyPlayRecordGet(RequestHandlerTask):
	url = r'/game/cross/supremacy/playrecord/get'

	@coroutine
	def run(self):
		payload = self.input
		first_param = payload.get(1, None)
		if isinstance(first_param, dict) and _dict_has_any_key(first_param, (
			'recordID', 'record_id', 'recordId', 'playRecordID', 'play_record_id',
			'crossKey', 'cross_key', 'crossKeyID',
		)):
			payload = first_param
		record_id = _get_input_param(payload, 1, 'recordID', 'record_id', 'recordId', 'playRecordID', 'play_record_id')
		cross_key = _get_input_param(payload, 2, 'crossKey', 'cross_key', 'crossKeyID')
		if record_id is None:
			raise ClientError('param miss')
		origin_record_id = record_id

		is_object_id = not isinstance(record_id, basestring) or len(record_id) == 24
		if isinstance(record_id, basestring) and len(record_id) == 24:
			record_id = string2objectid(record_id)

		if cross_key is None:
			cross_key = ObjectCrossSupremacyGameGlobal.getCrossKey(self.game.role.areaKey)
		if cross_key and is_object_id:
			if isinstance(cross_key, basestring) and cross_key.startswith('game'):
				cross_key = game2crosssupremacy(cross_key)
			rpc = ObjectCrossSupremacyGameGlobal.cross_client(self.game.role.areaKey, cross_key=cross_key)
			if rpc:
				model = yield rpc.call_async('GetCrossSupremacyPlayRecord', record_id)
				if model:
					self.write({
						'model': {
							'cross_supremacy_playrecords': {
								origin_record_id: model,
							}
						}
					})
					return

		runtime_cache = _get_runtime_cache(self.game.role)
		play_records = runtime_cache.get('play_records', {})
		model = play_records.get(record_id, None)
		if model is None and isinstance(origin_record_id, basestring):
			model = play_records.get(origin_record_id, None)
		if model is None:
			data = _ensure_supremacy_data(self.game)
			play_records = data.get('play_records', {}) or {}
			model = play_records.get(record_id, None)
			if model is None and isinstance(origin_record_id, basestring):
				model = play_records.get(origin_record_id, None)
		if model is None:
			raise ClientError('Cross Supremacy Play Not Existed')
		self.write({
			'model': {
				'cross_supremacy_playrecords': {
					origin_record_id: model,
				}
			}
		})


class CrossSupremacyResGet(RequestHandlerTask):
	url = r'/game/cross/supremacy/res/get'

	@coroutine
	def run(self):
		data = _ensure_supremacy_data(self.game)
		_update_supremacy_res(data)
		res = data.get('res', {}) or {}
		if not res:
			self.write({'view': {}})
			return
		eff = ObjectGainAux(self.game, res)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_supremacy_res_get')
		data['res'] = {}
		data['last_product_time'] = nowtime_t()
		self.game.role.cross_supremacy_datas = data
		self.write({'view': eff.result, 'model': {'cross_supremacy': _make_cross_supremacy_model(self.game, data)}})


class CrossSupremacyWeeklyAwardGet(RequestHandlerTask):
	url = r'/game/cross/supremacy/weekly/award/get'

	@coroutine
	def run(self):
		csv_id = _get_input_param(self.input, 1, 'csvID', 'csv_id', 'id')
		if csv_id is None:
			raise ClientError('param miss')
		try:
			csv_id = int(csv_id)
		except Exception:
			pass
		weekly = self.game.weeklyRecord
		_refresh_weekly_award(weekly)
		status = weekly.cross_supremacy_week_award.get(csv_id, 0)
		if status != 1:
			raise ClientError('award not open')
		cfg = _csv_get(getattr(csv.cross.supremacy, 'week_award', {}), csv_id, None)
		if not cfg:
			raise ClientError('award not found')
		eff = ObjectGainAux(self.game, cfg.weekAward)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_supremacy_week_award')
		weekly.cross_supremacy_week_award[csv_id] = 2
		self.write({'view': eff.result})


class CrossSupremacyWeeklyAwardGetOneKey(RequestHandlerTask):
	url = r'/game/cross/supremacy/weekly/award/get/onekey'

	@coroutine
	def run(self):
		weekly = self.game.weeklyRecord
		_refresh_weekly_award(weekly)
		award_map = weekly.cross_supremacy_week_award
		eff = ObjectGainAux(self.game, {})
		for csv_id, flag in award_map.items():
			if flag == 1:
				cfg = _csv_get(getattr(csv.cross.supremacy, 'week_award', {}), csv_id, None)
				if cfg:
					eff += ObjectGainAux(self.game, cfg.weekAward)
					award_map[csv_id] = 2
		weekly.cross_supremacy_week_award = award_map
		if eff.result:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_supremacy_week_award_onekey')
		self.write({'view': eff.result})


class CrossSupremacyExtraMatchBuy(RequestHandlerTask):
	url = r'/game/cross/supremacy/extra/match/buy'

	@coroutine
	def run(self):
		vip_cfg = getattr(self.game.role, '_currVIPCsv', None)
		max_buy = getattr(vip_cfg, 'crossSupremacyExtraBuyTimes', 0) if vip_cfg else 0
		if self.game.dailyRecord.cross_supremacy_purchased_times >= max_buy:
			raise ClientError('crossSupremacyBuyTimesMax')
		cost_cfg = ObjectCostCSV.CostMap.get('cross_supremacy_vip_match_times', None)
		cost_list = cost_cfg.seqParam if cost_cfg else []
		idx = min(len(cost_list) - 1, self.game.dailyRecord.cross_supremacy_purchased_times) if cost_list else 0
		cost = cost_list[idx] if cost_list else 0
		if cost > 0:
			cost_aux = ObjectCostAux(self.game, {'rmb': cost})
			if not cost_aux.isEnough():
				raise ClientError('cost rmb not enough')
			cost_aux.cost(src='cross_supremacy_extra_match_buy')
		self.game.dailyRecord.cross_supremacy_purchased_times += 1
		self.write({'view': {}})


class CrossSupremacyShop(RequestHandlerTask):
	url = r'/game/cross/supremacy/shop'

	@coroutine
	def run(self):
		csv_id = self.input.get('csvID', None)
		if csv_id is None:
			csv_id = self.input.get(1, None)
		count = self.input.get('count', None)
		if count is None:
			count = self.input.get(2, 1)
		if csv_id is None:
			raise ClientError('param miss')
		if count <= 0:
			raise ClientError('param error')
		shop = ObjectCrossSupremacyShop(self.game)
		eff = yield shop.buyItem(csv_id, count, src='cross_supremacy_shop_buy')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='cross_supremacy_shop_buy')


class CrossSupremacyHistoryTopRank(RequestHandlerTask):
	url = r'/game/cross/supremacy/history/top/rank'

	@coroutine
	def run(self):
		csv_id, cfg = _get_service_cfg()
		date = getattr(cfg, 'date', 0) if cfg else 0
		end_date = getattr(cfg, 'endDate', 0) if cfg else 0
		ranks = []
		cross_model = ObjectCrossSupremacyGameGlobal.getCrossGameModel(self.game.role.areaKey)
		if cross_model:
			ranks = cross_model.get('lastRanks', []) or []
		if not ranks:
			raise ClientError('crossSupremacyNotOpen')
		ranks = _normalize_rank_entries(self.game, ranks)
		self.write({
			'view': {
				'rank': {
					'rank': ranks[:8],
					'start_date': date,
					'end_date': end_date,
				}
			}
		})


class CrossSupremacyEventGet(RequestHandlerTask):
	url = r'/game/cross/supremacy/event/get'

	@coroutine
	def run(self):
		data = _ensure_supremacy_data(self.game)
		event = _ensure_event_data(data)
		event_id = event.get('event_id', 0) or 0
		award = {}
		if event_id > 0:
			cfg = _csv_get(getattr(csv.cross.supremacy, 'event_lib', {}), event_id, None)
			if cfg:
				event_type = getattr(cfg, 'eventType', 0) or 0
				if event_type == 1:
					buff_map = event.get('buff', {}) or {}
					buff_map[event_id] = nowtime_t()
					event['buff'] = buff_map
				elif event_type == 2:
					award = getattr(cfg, 'itemAward', {}) or {}
			event['event_id'] = 0
			event['event_time'] = 0
		data['event'] = event
		self.game.role.cross_supremacy_datas = data
		self.write({
			'view': {
				'eventID': event_id,
				'award': award,
			},
			'model': {
				'cross_supremacy': _make_cross_supremacy_model(self.game, data),
			},
		})
