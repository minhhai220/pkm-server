#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
cross_union_adventure Handlers (mock data)
'''

import time

from game import ClientError
from game.handler.task import RequestHandlerTask
from game.object.game.servrecord import ObjectServerGlobalRecord
from tornado.gen import coroutine


_DEFAULT_ROUND = 'union_prepare'
_ROUND_ORDER = ['closed', 'union_prepare', 'union_match', 'role_prepare', 'battle']
_SIGNUP_MIN = 5
_SIGNUP_MAX = 35
_MOCK_RUDP_HOST = '127.0.0.1'
_MOCK_RUDP_PORT = 23333
_MOCK_ROOM_ID = '000000000001'
_STATE = {
	'round': _DEFAULT_ROUND,
	'unions': {},  # union_id -> {'signup_roles': set, 'disabled_roles': set, 'signup': bool}
	'roles': {},  # role_id -> {'record': {}, 'cars': [], 'select_car': int, 'last_cmd': {}}
	'last_ranks': {
		'union': [{'rank': 1, 'union_id': 1, 'name': 'MockUnion', 'score': 100}],
		'role': [{'rank': 1, 'role_id': 1, 'name': 'MockRole', 'score': 100}],
	},
}


def _get_union_id(role):
	return role.union_db_id or role.id


def _get_union_state(union_id):
	union = _STATE['unions'].get(union_id)
	if union is None:
		union = {
			'signup_roles': set(),
			'disabled_roles': set(),
			'signup': False,
			'members': [],
		}
		_STATE['unions'][union_id] = union
	return union


def _ensure_union_mock_members(role, union):
	if union['members']:
		return
	union['members'].append({
		'role_id': role.id,
		'name': role.name,
		'level': role.level,
		'fight_point': getattr(role, 'fighting_point', 0),
	})
	for idx in xrange(1, _SIGNUP_MIN):
		if isinstance(role.id, (int, long)):
			mock_role_id = role.id + idx
		else:
			mock_role_id = '%s_%s' % (role.id, idx)
		union['members'].append({
			'role_id': mock_role_id,
			'name': 'MockMember%s' % idx,
			'level': max(1, role.level - idx),
			'fight_point': max(1000, getattr(role, 'fighting_point', 0) - idx * 1000),
		})
	for member in union['members']:
		union['signup_roles'].add(member['role_id'])
	union['signup'] = True


def _get_role_state(role_id):
	role = _STATE['roles'].get(role_id)
	if role is None:
		role = {
			'record': {
				'cards': [0] * 12,
				'extra': {'weather': 0, 'camp': 0},
			},
			'cars': [1],
			'select_car': 1,
			'last_cmd': {},
		}
		_STATE['roles'][role_id] = role
	return role


def _make_battle_info(role, union_id):
	now = int(time.time())
	left_union = {
		'union_db_id': union_id,
		'union_id': union_id,
		'name': getattr(role, 'union_name', None) or 'MockUnion',
		'logo': 1,
		'game_key': 'game.cn.1',
		'battle_member_num': max(_SIGNUP_MIN, 5),
		'score': 100,
	}
	right_union = {
		'union_db_id': 999,
		'union_id': 999,
		'name': 'MockEnemy',
		'logo': 1,
		'game_key': 'game.cn.1',
		'battle_member_num': max(_SIGNUP_MIN, 5),
		'score': 80,
	}
	return {
		'round_id': 1,
		'status': _get_round(),
		'prepare_time': now + 300,
		'battle_time': now + 1800,
		'match_time': now + 120,
		'left_union': {'union_id': union_id, 'name': getattr(role, 'union_name', None) or 'MockUnion'},
		'right_union': {'union_id': 999, 'name': 'MockEnemy'},
		'left': left_union,
		'right': right_union,
		'start_time': now,
		'end_time': now + 3600,
		'host': _MOCK_RUDP_HOST,
		'port': _MOCK_RUDP_PORT,
		'room_id': _MOCK_ROOM_ID,
		'role_id': role.id,
		'team': 1,
		'theme': 1,
	}


def _make_main_model(game):
	role = game.role
	union_id = _get_union_id(role)
	union = _get_union_state(union_id)
	role_state = _get_role_state(role.id)
	round_name = _get_round()
	_ensure_union_mock_members(role, union)

	return {
		'round': round_name,
		'battle_info': _make_battle_info(role, union_id),
		'union_is_signup': union['signup'],
		'role_is_signup': role.id in union['signup_roles'],
		'signup_num': len(union['signup_roles']),
		'signup_num_min': _SIGNUP_MIN,
		'signup_num_max': _SIGNUP_MAX,
		'record': role_state['record'],
		'role_info': {
			'select_car': role_state['select_car'],
			'cars': role_state['cars'],
		},
		'union_info': {
			'union_id': union_id,
			'name': getattr(role, 'union_name', None) or 'MockUnion',
			'logo': 1,
			'level': 7,
			'member_num': max(len(union['members']), _SIGNUP_MAX),
			'sign_num': len(union['signup_roles']),
			'sign_roles': list(union['signup_roles']),
			'is_signup': union['signup'],
			'sign_num_min': _SIGNUP_MIN,
			'sign_num_max': _SIGNUP_MAX,
		},
		'last_union_top_ranks': _STATE['last_ranks']['union'],
		'last_role_top_ranks': _STATE['last_ranks']['role'],
		'servers': ['game.cn.1'],
		'merge_servers': ['game.cn.1'],
		'date': int(time.time()),
		'csvID': 90001,
	}


def _set_round(round_name):
	if round_name not in _ROUND_ORDER:
		raise ClientError('round error')
	_STATE['round'] = round_name
	serv_record = ObjectServerGlobalRecord.Singleton
	if serv_record:
		serv_record.cross_union_adventure_round = round_name
		serv_record.last_time = int(time.time())


def _get_round():
	serv_record = ObjectServerGlobalRecord.Singleton
	if serv_record and serv_record.cross_union_adventure_round:
		return serv_record.cross_union_adventure_round
	return _STATE['round']


def _advance_round():
	cur = _get_round()
	if cur not in _ROUND_ORDER:
		_set_round(_DEFAULT_ROUND)
		return _DEFAULT_ROUND
	idx = _ROUND_ORDER.index(cur)
	next_round = _ROUND_ORDER[(idx + 1) % len(_ROUND_ORDER)]
	_set_round(next_round)
	return next_round


class CrossUnionAdventureMain(RequestHandlerTask):
	url = r'/game/cross/union/adventure/main'

	@coroutine
	def run(self):
		round_name = self.input.get('round', None)
		advance = self.input.get('advance', None)
		if round_name:
			_set_round(round_name)
		elif advance:
			_advance_round()

		self.write({'model': {'cross_union_adventure': _make_main_model(self.game)}})


class CrossUnionAdventureSignup(RequestHandlerTask):
	url = r'/game/cross/union/adventure/signup'

	@coroutine
	def run(self):
		role = self.game.role
		union = _get_union_state(_get_union_id(role))
		flag = self.input.get('flag', True)
		if flag:
			union['signup'] = True
			union['signup_roles'].add(role.id)
		else:
			union['signup'] = False
			union['signup_roles'].discard(role.id)

		self.write({
			'view': {'union_is_signup': union['signup'], 'role_is_signup': role.id in union['signup_roles']},
			'model': {'cross_union_adventure': _make_main_model(self.game)},
		})


class CrossUnionAdventureSignupMembers(RequestHandlerTask):
	url = r'/game/cross/union/adventure/signup/members'

	@coroutine
	def run(self):
		role = self.game.role
		union = _get_union_state(_get_union_id(role))
		_ensure_union_mock_members(role, union)
		members = [{
			'role_id': member['role_id'],
			'name': member['name'],
			'level': member['level'],
			'fight_point': member['fight_point'],
			'disabled': member['role_id'] in union['disabled_roles'],
			'signup': member['role_id'] in union['signup_roles'],
		} for member in union['members']]
		self.write({'view': {'members': members, 'disabled_roles': list(union['disabled_roles'])}})


class CrossUnionAdventureSignupMemberInfo(RequestHandlerTask):
	url = r'/game/cross/union/adventure/signup/member/info'

	@coroutine
	def run(self):
		role = self.game.role
		self.write({
			'view': {
				'role_id': role.id,
				'name': role.name,
				'level': role.level,
				'fight_point': getattr(role, 'fighting_point', 0),
			},
		})


class CrossUnionAdventureDeployMember(RequestHandlerTask):
	url = r'/game/cross/union/adventure/deploy/member'

	@coroutine
	def run(self):
		role = self.game.role
		union = _get_union_state(_get_union_id(role))
		role_id = self.input.get('roleID', role.id)
		disabled = bool(self.input.get('disabled', False))
		if disabled:
			union['disabled_roles'].add(role_id)
			union['signup_roles'].discard(role_id)
		else:
			union['disabled_roles'].discard(role_id)

		self.write({
			'view': {'disabled_roles': list(union['disabled_roles'])},
			'model': {'cross_union_adventure': _make_main_model(self.game)},
		})


class CrossUnionAdventureDeployCard(RequestHandlerTask):
	url = r'/game/cross/union/adventure/deploy/card'

	@coroutine
	def run(self):
		role = self.game.role
		cards = self.input.get('cards', None)
		extra = self.input.get('extra', {})
		if cards is None:
			raise ClientError('cards miss')
		if isinstance(cards, dict):
			cards = cards.values()
		if len(cards) < 12:
			cards = list(cards) + [0] * (12 - len(cards))
		role_state = _get_role_state(role.id)
		role_state['record'] = {'cards': list(cards), 'extra': extra}
		self.write({'model': {'cross_union_adventure': _make_main_model(self.game)}})


class CrossUnionAdventureCarUnlock(RequestHandlerTask):
	url = r'/game/cross/union/adventure/car/unlock'

	@coroutine
	def run(self):
		role = self.game.role
		car_id = self.input.get('carID', None)
		if car_id is None:
			raise ClientError('carID miss')
		role_state = _get_role_state(role.id)
		if car_id not in role_state['cars']:
			role_state['cars'].append(car_id)
		self.write({
			'view': {'cars': role_state['cars'], 'select_car': role_state['select_car']},
			'model': {'cross_union_adventure': _make_main_model(self.game)},
		})


class CrossUnionAdventureCarSelect(RequestHandlerTask):
	url = r'/game/cross/union/adventure/car/select'

	@coroutine
	def run(self):
		role = self.game.role
		car_id = self.input.get('carID', None)
		if car_id is None:
			raise ClientError('carID miss')
		role_state = _get_role_state(role.id)
		if car_id not in role_state['cars']:
			raise ClientError('param error')
		role_state['select_car'] = car_id
		self.write({
			'view': {'select_car': role_state['select_car'], 'cars': role_state['cars']},
			'model': {'cross_union_adventure': _make_main_model(self.game)},
		})


class CrossUnionAdventureRoundBattleInfo(RequestHandlerTask):
	url = r'/game/cross/union/adventure/round/battle/info'

	@coroutine
	def run(self):
		self.write({
			'view': {
				'rounds': [{
					'round_id': 1,
					'winner': 'left',
					'score': [100, 80],
				}],
			},
		})


class CrossUnionAdventureRank(RequestHandlerTask):
	url = r'/game/cross/union/adventure/rank'

	@coroutine
	def run(self):
		self.write({
			'view': {
				'union': _STATE['last_ranks']['union'],
				'role': _STATE['last_ranks']['role'],
			},
		})


class CrossUnionAdventurePlayRecordGet(RequestHandlerTask):
	url = r'/game/cross/union/adventure/playrecord/get'

	@coroutine
	def run(self):
		self.write({
			'view': {
				'playrecord': {
					'id': 1,
					'events': [],
				},
			},
		})


class CrossUnionAdventureShop(RequestHandlerTask):
	url = r'/game/cross/union/adventure/shop'

	@coroutine
	def run(self):
		self.write({'view': {'items': []}})


class CrossUnionAdventureInput(RequestHandlerTask):
	url = r'/unionadventure/input'

	@coroutine
	def run(self):
		role = self.game.role
		cmd = self.input.get('cmd', None)
		if cmd is None:
			raise ClientError('cmd miss')
		role_state = _get_role_state(role.id)
		role_state['last_cmd'] = {'cmd': cmd, 'data': self.input}
		self.write({'view': {'ok': True, 'cmd': cmd}})


class CrossUnionAdventureMockReset(RequestHandlerTask):
	url = r'/game/cross/union/adventure/mock/reset'

	@coroutine
	def run(self):
		_STATE['round'] = _DEFAULT_ROUND
		_STATE['unions'].clear()
		_STATE['roles'].clear()
		serv_record = ObjectServerGlobalRecord.Singleton
		if serv_record:
			serv_record.cross_union_adventure_round = _DEFAULT_ROUND
			serv_record.last_time = int(time.time())
		self.write({'view': {'ok': True}})
