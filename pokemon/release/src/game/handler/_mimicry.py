#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
============================================================================
拟态对战 (Mimicry Battle) - HTTP 接口处理器
文档: docs/拟态对战_接口文档.md
============================================================================
'''

from __future__ import absolute_import

from tornado.gen import coroutine, Return

from framework import todayinclock5date2int
from framework.csv import csv, ErrDefs
from framework.helper import transform2list
from framework.log import logger
from game import ClientError, ServerError
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain
from game.object.game.battle import ObjectMimicryBattle
from game.object.game.gain import ObjectGainAux


# 拟态对战 主界面
class MimicryMain(RequestHandlerTask):
	url = r'/game/mimicry/main'

	@coroutine
	def run(self):
		role = self.game.role
		# 首次进入时创建 Mimicry 记录
		if getattr(role, 'mimicry_db_id', None) is None:
			recordData = yield self.dbcGame.call_async('DBCreate', 'Mimicry', {
				'role_db_id': role.id,
			})
			if not recordData['ret']:
				raise ServerError('db create mimicry record error')
			role.mimicry_db_id = recordData['model']['id']
			self.game.mimicry.set(recordData['model']).init()
		elif not self.game.mimicry.inited:
			recordData = yield self.dbcGame.call_async('DBRead', 'Mimicry', role.mimicry_db_id, False)
			if not recordData['ret']:
				raise ServerError('db read mimicry record error')
			self.game.mimicry.set(recordData['model']).init()

		# 刷新每日战斗次数
		today = todayinclock5date2int()
		self.game.mimicry.refreshBattleTimes(today)
		limit = csv.mimicry.base[1].battleTimesLimit
		self.game.dailyRecord.mimicry_battle_times = min(limit, self.game.mimicry.battle_times)

		# 检测活动周期变化，重置掉落触发次数（根据 crontab 计算当前期数）
		currentPeriod = self._getCurrentMimicryPeriod()
		try:
			lastPeriod = self.game.mimicry.last_end_date or 0
		except KeyError:
			lastPeriod = 0
		if currentPeriod != lastPeriod and currentPeriod > 0:
			logger.info('=== mimicry period changed: %s -> %s, resetting player data for role %s ===', 
				lastPeriod, currentPeriod, self.game.role.id)
			# 新周期开始，重置所有数据（与前端 deleteSaveDate 对应）
			# 重置掉落触发次数
			self.game.mimicry.drop_trigger_count = {}
			self.game.mimicry.total_battle_count = 0
			# 重置积分数据（新周期排行榜从0开始）
			self.game.mimicry.best_score = 0
			self.game.mimicry.best_boss_id = 0
			self.game.mimicry.total_scores = {}
			self.game.mimicry.history_scores = {}
			# 重置成就进度（成就是每期的）
			self.game.mimicry.achievement_value = {}
			self.game.mimicry.achievement_state = {}
			# 重置Buff槽位（根据积分解锁，新周期从初始值开始）
			self.game.mimicry.buff_field = {}
			# 重置已解锁的Buff（每期重新获得）
			self.game.mimicry.buffs = []
			# 重置Buff选择（依赖于buffs）
			self.game.mimicry.buff_choice = {}
			# 重置战斗阵容
			self.game.mimicry.battle_cards = {}
			# 保存当前期数
			self.game.mimicry.last_end_date = currentPeriod
			# 重新分配初始buff（因为buffs已被清空为[]）
			self.game.mimicry._ensureDefaults()
			logger.info('=== mimicry player data reset COMPLETED, new buffs=%s ===', self.game.mimicry.buffs)

		view = self._buildMainView()
		self.write({'view': view})

	def _buildMainView(self):
		openCfg = csv.mimicry.open_boss[1]
		bossMapping = {}
		for bossID, limitID in openCfg.openBosses.iteritems():
			try:
				bossMapping[int(bossID)] = int(limitID)
			except (TypeError, ValueError):
				continue

		# 根据 crontab 计算活动状态和日期
		round_status, start_date, end_date = self._getMimicrySchedule()

		return {
			'round': round_status,
			'start_date': start_date,
			'end_date': end_date,
			'bosses': bossMapping,
			'version': getattr(openCfg, 'issue', 1) or 1,
			'battle_times': self.game.mimicry.battle_times,
		}

	def _getMimicrySchedule(self):
		"""
		根据 crontab.csv 计算活动状态和日期
		返回: (round_status, start_date, end_date)
		"""
		from game.object.game.servrecord import MergeServ
		from game.session import Session
		from framework.distributed.helper import node_key2domains
		from framework import int2date, date2int
		import datetime

		try:
			# 获取服务器key
			key = MergeServ.getSrcServKeys(Session.server.key)[0]
			domains = node_key2domains(key)
			serverKey = domains[1]
			fullKey = '%s.%s.%s' % (domains[0], serverKey, domains[2])

			today = todayinclock5date2int()

			# 查找匹配的 crontab 配置
			for cronID in csv.cross.crontab:
				cfg = csv.cross.crontab[cronID]
				if cfg.service != 'crossmimicry':
					continue

				# 检查服务器
				servers = getattr(cfg, 'servers', None)
				cross = getattr(cfg, 'cross', None)
				if servers:
					if fullKey not in servers:
						continue
				elif cross and cross != serverKey:
					continue

				# 计算当前周期的开始和结束日期
				startDate = cfg.date  # 起始日期
				periodDays = getattr(cfg, 'periodDays', 14) or 14
				durationDay = getattr(cfg, 'durationDay', 12) or 12

				startDateObj = int2date(startDate)
				todayObj = int2date(today)
				daysPassed = (todayObj - startDateObj).days

				if daysPassed < 0:
					# 活动还未开始
					return ('closed', startDate, startDate)

				# 计算当前是第几个周期（从0开始）
				currentPeriodIndex = daysPassed // periodDays
				
				# 当前周期的开始日期
				periodStartObj = startDateObj + datetime.timedelta(days=currentPeriodIndex * periodDays)
				periodEndObj = periodStartObj + datetime.timedelta(days=durationDay - 1)
				
				periodStart = date2int(periodStartObj)
				periodEnd = date2int(periodEndObj)

				# 检查是否在活动期间
				daysInCurrentPeriod = daysPassed % periodDays
				if daysInCurrentPeriod < durationDay:
					return ('start', periodStart, periodEnd)
				else:
					# 在休息期间，返回下一期的日期
					nextPeriodStartObj = periodStartObj + datetime.timedelta(days=periodDays)
					nextPeriodEndObj = nextPeriodStartObj + datetime.timedelta(days=durationDay - 1)
					return ('closed', date2int(nextPeriodStartObj), date2int(nextPeriodEndObj))

			# 没有匹配的配置
			return ('closed', 0, 0)
		except Exception as e:
			logger.warning('_getMimicrySchedule error: %s', e)
			return ('start', 0, 0)  # 出错时默认开放

	def _getCurrentMimicryPeriod(self):
		"""
		根据 crontab.csv 中的 crossmimicry 配置计算当前期数
		返回: 当前期数（从1开始），如果活动未开启返回0
		"""
		from game.object.game.servrecord import MergeServ
		from game.session import Session
		from framework.distributed.helper import node_key2domains
		from framework import int2date
		import datetime

		try:
			# 获取服务器key
			key = MergeServ.getSrcServKeys(Session.server.key)[0]
			domains = node_key2domains(key)
			serverKey = domains[1]
			fullKey = '%s.%s.%s' % (domains[0], serverKey, domains[2])

			today = todayinclock5date2int()

			# 查找匹配的 crontab 配置
			for cronID in csv.cross.crontab:
				cfg = csv.cross.crontab[cronID]
				if cfg.service != 'crossmimicry':
					continue

				# 检查服务器
				servers = getattr(cfg, 'servers', None)
				cross = getattr(cfg, 'cross', None)
				if servers:
					if fullKey not in servers:
						continue
				elif cross and cross != serverKey:
					continue

				# 计算当前期数
				startDate = cfg.date  # 起始日期，如 20230616
				periodDays = getattr(cfg, 'periodDays', 14) or 14  # 周期天数
				durationDay = getattr(cfg, 'durationDay', 12) or 12  # 持续天数

				# 计算从起始日期到今天经过了多少天
				startDateObj = int2date(startDate)
				todayObj = int2date(today)
				daysPassed = (todayObj - startDateObj).days

				if daysPassed < 0:
					# 活动还未开始
					return 0

				# 计算当前是第几个周期（从1开始）
				currentPeriod = (daysPassed // periodDays) + 1

				# 检查是否在活动期间（每个周期的前 durationDay 天）
				daysInCurrentPeriod = daysPassed % periodDays
				if daysInCurrentPeriod < durationDay:
					return currentPeriod
				else:
					# 在休息期间，返回负数表示休息期
					return -currentPeriod

			return 0
		except Exception as e:
			logger.warning('_getCurrentMimicryPeriod error: %s', e)
			return 0


# 部署 Buff
class MimicryDeployBuff(RequestHandlerTask):
	url = r'/game/mimicry/deploy/buff'

	@coroutine
	def run(self):
		if getattr(self.game.role, 'mimicry_db_id', None) is None:
			raise ClientError('mimicry not unlocked')

		bossID = self.input.get('bossID')
		buffIDs = self.input.get('buffIDs', [])
		if bossID is None:
			raise ClientError('param missing')

		try:
			bossID = int(bossID)
		except (TypeError, ValueError):
			raise ClientError('boss id error')

		buffIDs = transform2list(buffIDs)
		self.game.mimicry.deployBuff(bossID, buffIDs)
		buff_choice = self.game.mimicry.buff_choice or {}
		self.write({'view': {
			'bossID': bossID,
			'buff_choice': buff_choice[bossID] if bossID in buff_choice else [],
		}})


# 战斗开始
class MimicryBattleStart(RequestHandlerTask):
	url = r'/game/mimicry/battle/start'

	@coroutine
	def run(self):
		role = self.game.role
		if getattr(role, 'mimicry_db_id', None) is None:
			raise ClientError('mimicry not unlocked')

		inputData = self.input
		bossID = inputData.get('bossID', inputData.get(1))
		cardCsvIDs = inputData.get('cardCsvIDs', inputData.get(2, {}))
		skinIDs = inputData.get('skinIDs', inputData.get(3, {}))
		isPass = inputData.get('isPass', inputData.get(4))  # 快速挑战标记
		extra = inputData.get('extra', inputData.get(5, {}))

		if bossID is None:
			raise ClientError('boss id missing')
		try:
			bossID = int(bossID)
		except (TypeError, ValueError):
			raise ClientError('boss id error')

		# 转换 cardCsvIDs 格式
		if not isinstance(cardCsvIDs, dict):
			cardCsvIDs = {idx + 1: val for idx, val in enumerate(cardCsvIDs or []) if val}
		cardCsvIDs = {int(k): int(v) for k, v in cardCsvIDs.iteritems()}

		# 转换 skinIDs 格式
		if not isinstance(skinIDs, dict):
			skinIDs = {int(idx + 1): val for idx, val in enumerate(skinIDs or []) if val}
		skinIDs = {int(k): int(v) for k, v in skinIDs.iteritems() if v}

		extra = extra or {}
		if not isinstance(extra, dict):
			extra = {}

		# 检查战斗次数
		today = todayinclock5date2int()
		self.game.mimicry.refreshBattleTimes(today)
		if self.game.mimicry.battle_times <= 0:
			raise ClientError(ErrDefs.todayChanllengeToMuch)

		# 构建战斗卡牌（验证图鉴并返回配置信息）
		cardsInfo = self.game.mimicry.buildBattleCards(bossID, cardCsvIDs, skinIDs)

		# 获取Boss配置
		try:
			bossCfg = csv.mimicry.boss[bossID]
		except KeyError:
			raise ClientError('boss config error')
		gateID = bossCfg.gateID
		if gateID not in csv.scene_conf:
			raise ClientError('gateID error')

		# 构建cardIDs列表 - 拟态对战统一使用 card_id (CSV ID)
		# 因为前端 csv.cards[cardID] 需要 CSV ID，不能用数据库ID
		cardIDs = []
		for pos in range(1, 7):
			info = cardsInfo.get(pos)
			if info:
				cardIDs.append(info['card_id'])  # 使用 CSV ID
			else:
				cardIDs.append(None)

		# 更新战斗次数显示
		self.game.dailyRecord.mimicry_battle_times = self.game.mimicry.battle_times

		# 保存天气数据
		self.game.role.battle_extra = {
			'weather': extra.get('weather', 0),
			'arms': extra.get('arms', []),
		}

		# 创建战斗对象
		self.game.battle = ObjectMimicryBattle(self.game)
		battleModel = self.game.battle.begin(bossID, gateID, cardIDs, cardsInfo, isPass, extra)

		# 获取已选择的Buff - 兼容整数键和字符串键
		buff_choice = self.game.mimicry.buff_choice or {}
		# DictWatcher.get() 可能抛出 KeyError，使用 in 检查
		buffIDs = []
		if bossID in buff_choice:
			buffIDs = buff_choice[bossID] or []
		elif str(bossID) in buff_choice:
			buffIDs = buff_choice[str(bossID)] or []
		buffIDs = [int(x) for x in buffIDs] if buffIDs else []

		# 构建返回数据 - 注意：前端期望的是 mimicry_battle 而不是 battle
		battleData = battleModel['battle']
		battleData['drop'] = {}

		# 确保 buff_ids 始终是数组（即使为空）
		battleData['buff_ids'] = buffIDs

		# 计算Boss血量阈值
		threshold = self._getBossHpThreshold(bossCfg)
		battleData['boss_hp_threshold'] = int(threshold)

		# 获取Boss限制技能
		bossLimitSkills = self._getBossLimitSkills(bossID)
		if bossLimitSkills:
			battleData['boss_limit_skills'] = bossLimitSkills

		# 前端通过 model.mimicry_battle 初始化 gGameModel.battle
		self.write({'model': {'mimicry_battle': battleData}})

	def _getBossHpThreshold(self, bossCfg):
		"""获取Boss血量阈值"""
		thresholdIdx = getattr(bossCfg, 'hpThresholdIndex', 0) or 0
		if thresholdIdx:
			try:
				thresholdIdx = int(thresholdIdx)
				return csv.mimicry.boss_threshold[thresholdIdx].threshold
			except (TypeError, ValueError, KeyError):
				pass
		# 默认阈值
		try:
			return csv.mimicry.boss_threshold[1].threshold
		except KeyError:
			return 1000000

	def _getBossLimitSkills(self, bossID):
		"""获取Boss限制技能"""
		openCfg = csv.mimicry.open_boss[1]
		limitID = None
		for k, v in openCfg.openBosses.iteritems():
			if int(k) == bossID:
				limitID = int(v)
				break
		if limitID is None:
			return {}

		try:
			limitCfg = csv.mimicry.boss_limit[limitID]
		except KeyError:
			return {}

		rawSkills = limitCfg.specialLimitParameter.get('skillIDs', {})
		skillMap = {}
		if isinstance(rawSkills, dict):
			iterable = rawSkills.itervalues()
		elif isinstance(rawSkills, (list, tuple)):
			iterable = rawSkills
		else:
			iterable = (rawSkills,)
		for skillID in iterable:
			if not skillID:
				continue
			try:
				skillID = int(skillID)
			except (TypeError, ValueError):
				continue
			if skillID > 0:
				skillMap[skillID] = 1
		return skillMap


# 战斗结束
class MimicryBattleEnd(RequestHandlerTask):
	url = r'/game/mimicry/battle/end'

	@coroutine
	def run(self):
		if not isinstance(self.game.battle, ObjectMimicryBattle):
			raise ServerError('mimicry battle miss')

		inputData = self.input
		battleID = inputData.get('battleID', inputData.get(1))
		damage = inputData.get('damage', inputData.get(2, 0))
		actions = inputData.get('actions', inputData.get(3))

		if battleID is None:
			raise ClientError('param miss')
		if battleID != self.game.battle.id:
			raise ClientError('battleID error')

		try:
			damage = int(damage)
		except (TypeError, ValueError):
			damage = 0

		role = self.game.role
		mimicry = self.game.mimicry
		bossID = self.game.battle.bossID

		# 计算分数
		bossScores, buffScores = self._calculateScores(bossID, damage)

		# 记录战斗结果
		oldBestScore = mimicry.best_score or 0
		mimicry.recordBattle(bossID, bossScores, buffScores)
		newBestScore = mimicry.best_score or 0

		# 如果刷新了最高分，更新跨服排行榜
		if newBestScore > oldBestScore:
			from game.object.game.cross_mimicry import ObjectCrossMimicryGameGlobal
			role = self.game.role
			areaKey = role.areaKey
			# 检查跨服是否开启
			if ObjectCrossMimicryGameGlobal.isOpen(areaKey):
				historyScore = mimicry.history_scores.get(mimicry.best_boss_id, 0)
				bestBossID = mimicry.best_boss_id
				# 获取最高分Boss对应的阵容和Buff
				battleCardsRaw = mimicry.battle_cards.get(bestBossID, {}) or mimicry.battle_cards.get(str(bestBossID), {}) or {}
				buffIds = mimicry.buff_choice.get(bestBossID, []) or mimicry.buff_choice.get(str(bestBossID), []) or []
				# 转换阵容格式：csv_id -> card_csv_id（前端期望的字段名）
				battleCards = {}
				for pos, cardInfo in battleCardsRaw.items():
					if cardInfo:
						battleCards[int(pos)] = {
							'card_csv_id': cardInfo.get('csv_id', 0),
							'skin_id': cardInfo.get('skin_id', 0),
							'star': cardInfo.get('star', 8),
							'fighting_point': cardInfo.get('fighting_point', 0),
						}
				roleInfo = {
					'role_db_id': role.id,
					'game_key': areaKey,
					'name': role.name,
					'logo': role.logo,
					'frame': role.frame,
					'level': role.level,
					'score': historyScore,  # 单次最高分
					'boss_id': bestBossID,
					'battle_cards': battleCards,  # 阵容（前端期望的字段名）
					'buff_ids': list(buffIds),  # Buff选择（前端期望的字段名）
				}
				yield ObjectCrossMimicryGameGlobal.updateRankRole(areaKey, roleInfo)

		# 更新 buff 槽位（根据分数解锁）
		self._updateBuffField(bossID, mimicry)

		# 消耗战斗次数
		mimicry.consumeBattleTimes()
		self.game.dailyRecord.mimicry_battle_times = mimicry.battle_times

		# 计算掉落 (随机Buff)
		newBuffs, dropItems = self._calculateDrop(bossID, damage, bossScores + buffScores)
		addedBuffs = []
		if newBuffs:
			addedBuffs = mimicry.appendBuffs(newBuffs)

		# 获取战斗卡牌和Buff信息（用于成就判定）
		cardIDs = self.game.battle.cardIDs if self.game.battle else []
		buff_choice = mimicry.buff_choice or {}
		buffIDs = buff_choice.get(bossID, []) or buff_choice.get(str(bossID), []) or []

		# 更新成就进度
		self._updateAchievements(bossID, damage, bossScores + buffScores, cardIDs, buffIDs, addedBuffs)

		# 发放掉落
		eff = ObjectGainAux(self.game, dropItems)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='mimicry_drop_%d' % bossID)

		# 清理战斗对象
		self.game.battle = None

		self.write({
			'view': {
				'drop': eff.result,
				'boss_scores': bossScores,
				'buff_scores': buffScores,
				'new_buff': bool(newBuffs),
			}
		})

	# 积分计算基础乘数（配置表系数需要乘以此值作为实际除数）
	SCORE_COEFFICIENT_MULTIPLIER = 25

	def _calculateScores(self, bossID, damage):
		"""计算伤害得分和Buff加成得分
		
		计算规则：
		1. bossScores = damage / (scoresCoefficient * 25) (从 scores_coefficient.csv 查询)
		2. buffScores = sum(bossScores × buff_coefficient) (从 buff_coefficient.csv 查询每个buff的系数)
		"""
		# 构建 scores_coefficient 查找表: {index(bossID): [(damageRange, scoresCoefficient), ...]}
		# 注意：scores_coefficient.csv 的 index 字段对应的是 Boss ID (1, 2, 3)
		scoresCoeffTable = {}
		if hasattr(csv, 'mimicry') and hasattr(csv.mimicry, 'scores_coefficient'):
			for cfgID in csv.mimicry.scores_coefficient:
				cfg = csv.mimicry.scores_coefficient[cfgID]
				idx = getattr(cfg, 'index', 0) or 0  # index 对应 bossID
				damageRange = getattr(cfg, 'damageRange', 0) or 0
				scoresCoeff = getattr(cfg, 'scoresCoefficient', 0) or 0
				if idx not in scoresCoeffTable:
					scoresCoeffTable[idx] = []
				scoresCoeffTable[idx].append((damageRange, scoresCoeff))
			for idx in scoresCoeffTable:
				scoresCoeffTable[idx].sort(key=lambda x: x[0])
		
		# 计算基础伤害得分：bossScores = damage / (scoresCoefficient * 25)
		# 使用 bossID 作为索引查询 scores_coefficient 表
		bossScores = damage
		if bossID in scoresCoeffTable:
			scoresCoeff = 1.0
			for damageRange, coeff in scoresCoeffTable[bossID]:
				if damage <= damageRange:
					scoresCoeff = coeff
					break
			else:
				if scoresCoeffTable[bossID]:
					scoresCoeff = scoresCoeffTable[bossID][-1][1]
			
			if scoresCoeff > 0:
				# 配置表系数需要乘以基础乘数（25）作为实际除数
				bossScores = int(damage / (scoresCoeff * self.SCORE_COEFFICIENT_MULTIPLIER))
		
		# Buff加成得分
		buffScores = 0
		buff_choice = self.game.mimicry.buff_choice or {}
		buffIDs = []
		if bossID in buff_choice:
			buffIDs = buff_choice[bossID] or []
		elif str(bossID) in buff_choice:
			buffIDs = buff_choice[str(bossID)] or []

		if not buffIDs:
			return bossScores, buffScores

		# 构建 buff_coefficient 查找表: {(index, bossID): [(damageRange, scoresCoefficient), ...]}
		buffCoeffTable = {}
		if hasattr(csv, 'mimicry') and hasattr(csv.mimicry, 'buff_coefficient'):
			for cfgID in csv.mimicry.buff_coefficient:
				cfg = csv.mimicry.buff_coefficient[cfgID]
				idx = getattr(cfg, 'index', 0) or 0
				cfgBossID = getattr(cfg, 'bossID', 0) or 0
				damageRange = getattr(cfg, 'damageRange', 0) or 0
				scoresCoeff = getattr(cfg, 'scoresCoefficient', 0) or 0
				key = (idx, cfgBossID)
				if key not in buffCoeffTable:
					buffCoeffTable[key] = []
				buffCoeffTable[key].append((damageRange, scoresCoeff))
			for key in buffCoeffTable:
				buffCoeffTable[key].sort(key=lambda x: x[0])

		for buffID in buffIDs:
			try:
				buffCfg = csv.mimicry.buffs[int(buffID)]
				# 获取 buff 的 coefficientIndex
				coeffIdx = getattr(buffCfg, 'coefficientIndex', 0) or 0
				if coeffIdx == 0:
					continue

				# 查找对应的系数表
				key = (coeffIdx, bossID)
				if key not in buffCoeffTable:
					continue

				# 根据伤害值找到对应的系数（找到第一个 damageRange >= damage 的配置）
				scoresCoeff = 0
				for damageRange, coeff in buffCoeffTable[key]:
					if damage <= damageRange:
						scoresCoeff = coeff
						break
				else:
					# 如果伤害超过所有范围，使用最后一个系数
					if buffCoeffTable[key]:
						scoresCoeff = buffCoeffTable[key][-1][1]

				# 计算该 buff 的加成得分：buffScores += bossScores × coefficient
				buffScores += int(bossScores * scoresCoeff)
			except (KeyError, TypeError, ValueError):
				continue

		return bossScores, buffScores

	def _updateBuffField(self, bossID, mimicry):
		"""根据分数更新 buff 槽位"""
		if not hasattr(csv, 'mimicry') or not hasattr(csv.mimicry, 'buff_field'):
			return

		mimicry.ensureBossEntry(bossID)
		total_scores = mimicry.total_scores or {}
		totalScore = total_scores[bossID] if bossID in total_scores else 0
		buff_field = mimicry.buff_field or {}
		buffField = buff_field[bossID] if bossID in buff_field else [0, 0, 0, 0]

		# 按 quality 分组统计每个品质应该有的槽位数
		qualitySlots = {1: 0, 2: 0, 3: 0, 4: 0}
		for cfgID in csv.mimicry.buff_field:
			cfg = csv.mimicry.buff_field[cfgID]
			quality = getattr(cfg, 'quality', 0)
			condition = getattr(cfg, 'scoresCondition', 0) or 0
			if quality in qualitySlots and totalScore >= condition:
				qualitySlots[quality] += 1

		# 更新槽位数（取最大值，不会减少）
		newBuffField = list(buffField) if buffField else [0, 0, 0, 0]
		while len(newBuffField) < 4:
			newBuffField.append(0)
		for quality in range(1, 5):
			idx = quality - 1
			newBuffField[idx] = max(newBuffField[idx], qualitySlots.get(quality, 0))

		mimicry.buff_field[bossID] = newBuffField

	def _calculateDrop(self, bossID, damage, totalScores):
		"""计算掉落物品和新Buff"""
		import random

		newBuffs = []
		dropItems = {}
		mimicry = self.game.mimicry
		ownedBuffs = set(mimicry.buffs or [])
		total_scores = mimicry.total_scores or {}
		totalScore = total_scores[bossID] if bossID in total_scores else 0

		# 增加累计挑战次数
		totalBattleCount = (mimicry.total_battle_count or 0) + 1
		mimicry.total_battle_count = totalBattleCount

		# 获取已触发的掉落配置次数
		dropTriggerCount = dict(mimicry.drop_trigger_count or {})

		# 构建 dropID -> [buffID, ...] 映射表
		dropIDToBuffs = {}
		if hasattr(csv, 'mimicry') and hasattr(csv.mimicry, 'buffs'):
			for buffID in csv.mimicry.buffs:
				buffCfg = csv.mimicry.buffs[buffID]
				dropID = getattr(buffCfg, 'dropID', 0) or 0
				buffBossID = getattr(buffCfg, 'bossID', 0) or 0
				# 过滤 bossID（0 表示通用，否则必须匹配）
				if buffBossID == 0 or buffBossID == bossID:
					if dropID not in dropIDToBuffs:
						dropIDToBuffs[dropID] = []
					dropIDToBuffs[dropID].append(buffID)

		def _pickBuffByDropID(dropID, count=1):
			"""根据 dropID 随机选取 buff"""
			candidates = dropIDToBuffs.get(dropID, [])
			# 过滤掉已拥有的
			candidates = [bid for bid in candidates if bid not in ownedBuffs]
			if not candidates:
				return []
			picked = []
			for _ in range(count):
				if not candidates:
					break
				bid = random.choice(candidates)
				picked.append(bid)
				ownedBuffs.add(bid)
				candidates.remove(bid)
			return picked

		# 尝试掉落新Buff
		try:
			if hasattr(csv, 'mimicry') and hasattr(csv.mimicry, 'buff_drop'):
				for cfgID in csv.mimicry.buff_drop:
					dropCfg = csv.mimicry.buff_drop[cfgID]
					scoresCondition = getattr(dropCfg, 'scoresCondition', 0) or 0
					probInit = getattr(dropCfg, 'probInit', 0) or 0

					# 分数条件解锁的 buff（scoresCondition > 0 的配置）
					if scoresCondition > 0 and totalScore >= scoresCondition:
						# 从 lotteryType1 等字段获取 buff (格式: {dropID=count})
						for i in range(1, 11):
							lotteryType = getattr(dropCfg, 'lotteryType%d' % i, None)
							if lotteryType and isinstance(lotteryType, dict):
								for dropID, count in lotteryType.iteritems():
									try:
										dropID = int(dropID)
										count = int(count) if count else 1
										picked = _pickBuffByDropID(dropID, count)
										newBuffs.extend(picked)
									except (TypeError, ValueError):
										continue
					# 概率掉落的 buff（probInit > 0 的配置）
					elif probInit > 0:
						if random.random() < probInit:
							# 根据权重抽取 buff
							weights = []
							dropIDList = []
							for i in range(1, 11):
								weight = getattr(dropCfg, 'lotteryWeight%d' % i, 0) or 0
								lotteryType = getattr(dropCfg, 'lotteryType%d' % i, None)
								if weight > 0 and lotteryType and isinstance(lotteryType, dict):
									for dropID, count in lotteryType.iteritems():
										try:
											dropID = int(dropID)
											# 检查该 dropID 是否有可选的 buff
											candidates = dropIDToBuffs.get(dropID, [])
											candidates = [bid for bid in candidates if bid not in ownedBuffs]
											if candidates:
												weights.append(weight)
												dropIDList.append((dropID, int(count) if count else 1))
										except (TypeError, ValueError):
											continue
							if weights and dropIDList:
								# 按权重随机选择一个 dropID
								totalWeight = sum(weights)
								r = random.random() * totalWeight
								cumulative = 0
								for idx, w in enumerate(weights):
									cumulative += w
									if r <= cumulative:
										dropID, count = dropIDList[idx]
										picked = _pickBuffByDropID(dropID, count)
										newBuffs.extend(picked)
										break
								if newBuffs:
									break  # 每次最多掉一组新Buff
					# 次数触发掉落的 buff（dropTriggerTimes > 0 的配置）
					else:
						dropTriggerTimes = getattr(dropCfg, 'dropTriggerTimes', 0) or 0
						effectLimit = getattr(dropCfg, 'effectLimit', 0) or 0
						
						if dropTriggerTimes > 0:
							# 检查是否达到触发次数
							triggeredCount = dropTriggerCount.get(cfgID, 0)
							
							# 检查效果限制（最多触发几次）
							if effectLimit > 0 and triggeredCount >= effectLimit:
								continue
							
							# 检查是否达到触发条件（每 dropTriggerTimes 次触发一次）
							if totalBattleCount % dropTriggerTimes == 0:
								# 根据权重抽取 buff
								weights = []
								dropIDList = []
								for i in range(1, 11):
									weight = getattr(dropCfg, 'lotteryWeight%d' % i, 0) or 0
									lotteryType = getattr(dropCfg, 'lotteryType%d' % i, None)
									if weight > 0 and lotteryType and isinstance(lotteryType, dict):
										for dropID, count in lotteryType.iteritems():
											try:
												dropID = int(dropID)
												# 检查该 dropID 是否有可选的 buff
												candidates = dropIDToBuffs.get(dropID, [])
												candidates = [bid for bid in candidates if bid not in ownedBuffs]
												if candidates:
													weights.append(weight)
													dropIDList.append((dropID, int(count) if count else 1))
											except (TypeError, ValueError):
												continue
								if weights and dropIDList:
									# 按权重随机选择一个 dropID
									totalWeight = sum(weights)
									r = random.random() * totalWeight
									cumulative = 0
									for idx, w in enumerate(weights):
										cumulative += w
										if r <= cumulative:
											dropID, count = dropIDList[idx]
											picked = _pickBuffByDropID(dropID, count)
											newBuffs.extend(picked)
											# 记录触发次数
											dropTriggerCount[cfgID] = triggeredCount + 1
											break
			
			# 保存已触发次数
			mimicry.drop_trigger_count = dropTriggerCount
		except Exception as e:
			logger.warning('mimicry buff drop error: %s', e)

		# 掉落其他物品 (根据挑战奖励配置)
		# challenge_award.csv: index=bossID, scoresRange=分数阈值, award=奖励
		# 只发放当前 Boss 的最高档位奖励
		try:
			if hasattr(csv, 'mimicry') and hasattr(csv.mimicry, 'challenge_award'):
				# 筛选当前 Boss 的配置，按 scoresRange 降序排列
				bossCfgs = []
				for awardID in csv.mimicry.challenge_award:
					awardCfg = csv.mimicry.challenge_award[awardID]
					cfgIndex = getattr(awardCfg, 'index', 0) or 0
					if cfgIndex == bossID:
						scoresRange = getattr(awardCfg, 'scoresRange', 0) or 0
						bossCfgs.append((scoresRange, awardCfg))
				
				# 按 scoresRange 降序排列，找到最高满足条件的档位
				bossCfgs.sort(key=lambda x: x[0], reverse=True)
				for scoresRange, awardCfg in bossCfgs:
					if totalScores >= scoresRange:
						# 固定奖励
						award = getattr(awardCfg, 'award', {}) or {}
						for itemID, count in (award or {}).iteritems():
							try:
								itemID = int(itemID)
								count = int(count)
								dropItems[itemID] = dropItems.get(itemID, 0) + count
							except (TypeError, ValueError):
								continue
						# 随机奖励 (格式: {libs=<112>} 表示从奖励库抽取)
						randomAward = getattr(awardCfg, 'randomAward', {}) or {}
						if randomAward:
							for key, val in randomAward.iteritems():
								if key == 'libs':
									# libs 是列表，如 [112]
									if 'libs' not in dropItems:
										dropItems['libs'] = []
									if isinstance(val, (list, tuple)):
										dropItems['libs'].extend(val)
									else:
										dropItems['libs'].append(val)
								else:
									try:
										dropItems[int(key)] = dropItems.get(int(key), 0) + int(val)
									except (TypeError, ValueError):
										continue
						break  # 只发放最高档位
		except Exception as e:
			logger.warning('mimicry challenge award error: %s', e)

		return newBuffs, dropItems

	def _updateAchievements(self, bossID, damage, totalScore, cardIDs=None, buffIDs=None, addedBuffs=None):
		"""更新成就进度
		
		成就类型（tasks.csv 的 type 字段）：
		- type=5: 挑战次数
		- type=2: 获得某品质增益数量（targetArg=品质）
		- type=6: 携带指定精灵挑战（specialArg=精灵ID列表）
		- type=7: 安装满某品质增益挑战（specialArg=品质列表）
		"""
		mimicry = self.game.mimicry
		achievementValue = mimicry.achievement_value or {}
		achievementState = mimicry.achievement_state or {}

		# 安全检查：csv.mimicry.tasks 可能不存在
		if not hasattr(csv, 'mimicry') or not hasattr(csv.mimicry, 'tasks'):
			return

		# 统计本次新获得的 Buff 按品质数量
		addedBuffQualities = {}  # {quality: count}
		for buffID in (addedBuffs or []):
			if buffID and buffID in csv.mimicry.buffs:
				buffCfg = csv.mimicry.buffs[buffID]
				quality = getattr(buffCfg, 'quality', 0) or 0
				addedBuffQualities[quality] = addedBuffQualities.get(quality, 0) + 1

		# 成就状态定义（与前端一致）：0=已领取, 1=可领取, 2=不可领取
		for taskID in csv.mimicry.tasks:
			if achievementState.get(taskID, 2) == 0:  # 已领取
				continue

			taskCfg = csv.mimicry.tasks[taskID]
			taskType = getattr(taskCfg, 'type', 0) or 0
			targetArg = getattr(taskCfg, 'targetArg', 0) or 0
			targetArg2 = getattr(taskCfg, 'targetArg2', 0) or 0
			specialArg = getattr(taskCfg, 'specialArg', []) or []

			currentValue = achievementValue.get(taskID, 0)
			oldValue = currentValue

			# 根据成就类型累计进度
			if taskType == 5:  # 挑战次数
				currentValue += 1
			elif taskType == 2:  # 获得某品质增益数量（targetArg=品质，如1=绿,2=蓝,3=紫,4=橙）
				quality = targetArg
				if quality in addedBuffQualities:
					currentValue += addedBuffQualities[quality]
			elif taskType == 6:  # 携带指定精灵挑战
				if cardIDs and specialArg:
					# specialArg 是 mimicry/cards.csv 的 csvID，需要转换为 cards.csv 的 cardID
					targetCardIDs = set()
					for v in specialArg:
						try:
							mimicryCsvID = int(v)
							if mimicryCsvID in csv.mimicry.cards:
								realCardID = csv.mimicry.cards[mimicryCsvID].cardID
								targetCardIDs.add(realCardID)
						except (TypeError, ValueError, AttributeError):
							pass
					# 检查是否携带了指定精灵
					for cardID in (cardIDs or []):
						if cardID and int(cardID) in targetCardIDs:
							currentValue += 1
							break
			elif taskType == 7:  # 安装满某品质增益挑战
				if buffIDs and specialArg:
					# 转换 specialArg 为整数列表（品质：1=绿, 2=蓝, 3=紫, 4=橙）
					targetQualities = []
					for v in specialArg:
						try:
							targetQualities.append(int(v))
						except (TypeError, ValueError):
							pass
					
					# 检查是否安装满了指定品质的增益
					qualityCounts = {}  # {quality: count}
					qualityLimits = {}  # {quality: limit}
					for quality in targetQualities:
						qualityCounts[quality] = 0
						qualityLimits[quality] = mimicry.getBuffCapacity(bossID, quality)
					
					for buffID in (buffIDs or []):
						if buffID and buffID in csv.mimicry.buffs:
							buffCfg = csv.mimicry.buffs[buffID]
							quality = getattr(buffCfg, 'quality', 0) or 0
							if quality in qualityCounts:
								qualityCounts[quality] += 1
					
					# 检查所有指定品质是否都满了
					allFull = True
					for quality in targetQualities:
						if qualityCounts.get(quality, 0) < qualityLimits.get(quality, 0):
							allFull = False
							break
					if allFull and qualityLimits:
						currentValue += 1

			if currentValue != oldValue:
				achievementValue[taskID] = currentValue

				# 检查是否达成（当前状态是不可领取时，才设为可领取）
				if currentValue >= targetArg2 and achievementState.get(taskID, 2) == 2:
					achievementState[taskID] = 1  # 可领取

		mimicry.achievement_value = achievementValue
		mimicry.achievement_state = achievementState


# 领取成就奖励
class MimicryAward(RequestHandlerTask):
	url = r'/game/mimicry/award'

	@coroutine
	def run(self):
		if getattr(self.game.role, 'mimicry_db_id', None) is None:
			raise ClientError('mimicry not unlocked')

		csvID = self.input.get('csvID')
		if csvID is None:
			raise ClientError('param miss')

		try:
			csvID = int(csvID)
		except (TypeError, ValueError):
			raise ClientError('csvID error')

		# 安全检查
		if not hasattr(csv, 'mimicry') or not hasattr(csv.mimicry, 'tasks'):
			raise ClientError('task config not found')

		if csvID not in csv.mimicry.tasks:
			raise ClientError('task not found')

		mimicry = self.game.mimicry
		state = mimicry.achievement_state.get(csvID, 2)  # 默认不可领取
		if state != 1:  # 不是可领取状态
			raise ClientError('can not get award')

		taskCfg = csv.mimicry.tasks[csvID]
		award = getattr(taskCfg, 'award', {}) or {}

		eff = ObjectGainAux(self.game, award)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='mimicry_award_%d' % csvID)

		mimicry.achievement_state[csvID] = 0  # 已领取

		self.write({
			'view': eff.result
		})


# 一键领取成就奖励
class MimicryAwardOnekey(RequestHandlerTask):
	url = r'/game/mimicry/award/onekey'

	@coroutine
	def run(self):
		if getattr(self.game.role, 'mimicry_db_id', None) is None:
			raise ClientError('mimicry not unlocked')

		mimicry = self.game.mimicry
		eff = ObjectGainAux(self.game, {})

		# 安全检查
		if not hasattr(csv, 'mimicry') or not hasattr(csv.mimicry, 'tasks'):
			self.write({'view': eff.result})
			return

		for csvID in csv.mimicry.tasks:
			state = mimicry.achievement_state.get(csvID, 2)  # 默认不可领取
			if state == 1:  # 可领取
				taskCfg = csv.mimicry.tasks[csvID]
				award = getattr(taskCfg, 'award', {}) or {}
				eff += ObjectGainAux(self.game, award)
				mimicry.achievement_state[csvID] = 0  # 已领取

		if eff.gain:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='mimicry_award_onekey')

		self.write({
			'view': eff.result
		})


# 跨服排行榜
class MimicryRank(RequestHandlerTask):
	url = r'/game/cross/mimicry/rank'

	@coroutine
	def run(self):
		offset = self.input.get('offset', 0)
		size = self.input.get('size', 30)

		try:
			offset = int(offset)
			size = min(int(size), 100)  # 限制最大查询数量
		except (TypeError, ValueError):
			offset = 0
			size = 30

		# 查询跨服排行榜
		ranks = yield self._queryRanks(offset, size)

		# 获取自己的排名
		myRank = yield self._getMyRank()

		# 前端期望 view 中直接包含 rank, score, boss_id
		self.write({
			'view': {
				'ranks': ranks,
				'rank': myRank.get('rank', 0),
				'score': myRank.get('score', 0),
				'boss_id': myRank.get('boss_id', 0),
			}
		})

	@coroutine
	def _queryRanks(self, offset, size):
		"""查询跨服排行榜数据"""
		from game.object.game.cross_mimicry import ObjectCrossMimicryGameGlobal
		from game.server import Server

		ranks = []
		areaKey = self.game.role.areaKey
		defaultGameKey = Server.Singleton.key if Server.Singleton else 'game_cn_1'
		
		# 调试日志
		globalObj = ObjectCrossMimicryGameGlobal.getByAreaKey(areaKey)
		if globalObj:
			logger.info('mimicry _queryRanks: areaKey=%s, cross_key=%s, round=%s, isOpen=%s', 
				areaKey, globalObj.cross_key, globalObj.round, ObjectCrossMimicryGameGlobal.isOpen(areaKey))
		else:
			logger.warning('mimicry _queryRanks: globalObj is None for areaKey=%s', areaKey)
		
		try:
			# 检查跨服是否开启
			if ObjectCrossMimicryGameGlobal.isOpen(areaKey):
				# 从跨服服务获取排行榜
				result = yield ObjectCrossMimicryGameGlobal.getCrossRankInfo(self.game.role.id, areaKey)
				if result and 'ranks' in result:
					for item in result['ranks']:
						# 处理字段映射（跨服返回的字段名可能不同）
						if 'role_db_id' in item and 'id' not in item:
							item['id'] = item['role_db_id']
						if not item.get('game_key'):
							item['game_key'] = defaultGameKey
					ranks = result['ranks'][:size] if len(result['ranks']) > size else result['ranks']
			else:
				# 跨服未开启，从本地历史数据获取
				localRankInfo = ObjectCrossMimicryGameGlobal.getRankInfo(self.game.role.id, areaKey)
				if localRankInfo and 'ranks' in localRankInfo:
					ranks = localRankInfo['ranks'][:size] if len(localRankInfo['ranks']) > size else localRankInfo['ranks']
		except Exception as e:
			logger.warning('mimicry cross rank query error: %s', e)

		raise Return(ranks)

	@coroutine
	def _getMyRank(self):
		"""获取自己在跨服排行榜的排名"""
		from game.object.game.cross_mimicry import ObjectCrossMimicryGameGlobal

		mimicry = self.game.mimicry
		if not mimicry or not mimicry.inited:
			raise Return({'score': 0, 'boss_id': 0, 'rank': 0})

		areaKey = self.game.role.areaKey
		myRank = 0
		myScore = 0
		myBossID = mimicry.best_boss_id or 0

		try:
			# 检查跨服是否开启
			if ObjectCrossMimicryGameGlobal.isOpen(areaKey):
				# 从跨服服务获取自己的排名
				result = yield ObjectCrossMimicryGameGlobal.getCrossRankInfo(self.game.role.id, areaKey)
				if result:
					myRank = result.get('rank', 0)
					myScore = result.get('score', 0)
					myBossID = result.get('boss_id', myBossID)
			else:
				# 跨服未开启，从本地历史数据获取
				localRankInfo = ObjectCrossMimicryGameGlobal.getRankInfo(self.game.role.id, areaKey)
				if localRankInfo:
					myRank = localRankInfo.get('rank', 0)
					myScore = localRankInfo.get('score', 0)
					myBossID = localRankInfo.get('boss_id', myBossID)
		except Exception as e:
			logger.warning('mimicry cross rank query error: %s', e)

		# 如果跨服没有数据，使用本地数据
		if myScore == 0:
			historyScores = mimicry.history_scores or {}
			myScore = historyScores.get(myBossID, 0) or historyScores.get(str(myBossID), 0) or 0

		raise Return({
			'score': myScore,  # 单次最高分
			'boss_id': myBossID,
			'rank': myRank,
		})
