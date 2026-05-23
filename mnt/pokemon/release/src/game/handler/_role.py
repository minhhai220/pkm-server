#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.

Role Handlers
'''

from framework import todayinclock5date2int, nowdatetime_t, int2time, nowdate_t, nowtime_t, int2date
from framework.csv import csv, ErrDefs, ConstDefs
from framework.log import logger
from framework.word_filter import filterName
from framework.helper import getL10nCsvValue, objectid2string

from game import ServerError, ClientError
from game import globaldata
from game.object import YYHuoDongDefs, PokedexAdvanceDefs, TargetDefs, AchievementDefs, MessageDefs, ReunionDefs, PlayPassportDefs
from game.globaldata import StaminaLimitMax, SkillPointBuy, AllCanItemID, MonthSignGiftDays, ReadMailBoxMax, NoticeMail, CitySpriteMiniQType, TestOrderID
from game.handler.task import RequestHandlerTask
from game.handler.inl import effectAutoGain, createCardsDB, createHeldItemsDB
from game.handler.inl_mail import deleteMail
from game.object import MapDefs, ItemDefs, TaskDefs, FeatureDefs
from game.object.game import ObjectDrawRandomItem
from game.object.game.item import GiftItemEffect, ObjectItemEffectFactory
from game.object.game.gain import ObjectGainAux,ObjectCostAux, unpack
from game.object.game.costcsv import ObjectCostCSV
from game.object.game.message import ObjectMessageGlobal
from game.object.game.target import predGen
from game.object.game.yyhuodong import ObjectYYHuoDongFactory, ObjectYYRegainStamina
from game.object.game.servrecord import ObjectServerGlobalRecord
from game.object.game.rank import ObjectRankGlobal
from game.object.game.role import ObjectRole
from game.object.game.levelcsv import ObjectFeatureUnlockCSV
from game.object.game.society import ObjectSocietyGlobal
from game.thinkingdata import ta

from tornado.gen import coroutine, Return
import copy
import datetime

def nameValid(name):
	uname = name.decode('utf8')
	# if len(name) > 21:
	# 	raise ClientError(ErrDefs.roleNameTooLong)
	if filterName(uname):
		raise ClientError(ErrDefs.roleNameInvalid)

@coroutine
def rolerename(dbc, role, name, cache):
	# 更改名字是需要原子操作，这里模拟锁的方式
	if name in cache:
		raise Return(False)
	cache.add(name)

	ret = yield dbc.call_async('DBReadBy', 'Role', {'name': name})
	if ret['ret'] and len(ret['models']) == 0:
		cache.discard(role.name)
		role.name = name
		raise Return(True)
	cache.discard(name)
	raise Return(False)

# 新手改名,选择形象
class RoleNewbieInit(RequestHandlerTask):
	url = r'/game/role/newbie/init'

	@coroutine
	def run(self):
		guideID = self.input.get('guideID', None)
		name = self.input.get('name', None)
		figure = self.input.get('figure', None)
		if name is None or figure is None:
			raise ClientError('param is miss')

		if guideID in self.game.role.newbie_guide:
			raise ClientError("guideID error")

		cfg = csv.newbie_init[1]
		if figure not in cfg.figures:
			raise ClientError('choose invalid')

		nameValid(name)

		if self.servMerged: # 合服，则添加相应的后缀
			name = '%s.s%d' % (name, self.game.role.area)
		ret = yield rolerename(self.dbcGame, self.game.role, name, self.roleNameCache)
		if ret:
			self.game.role.figure = figure
			self.game.role.figures[figure] = nowtime_t()
			self.game.role.logo = figure
			self.game.role.addLogo(figure) # 在这里形象和头像一一对应
			self.game.role.frame = 1
			self.game.role.addFrame(1)
			self.game.role.newbie_guide.append(guideID)
			ObjectSocietyGlobal.onRoleInfo(self.game)
		else:
			raise ClientError(ErrDefs.roleNameExisted)

		self.write({'view': {'result': ret}})

# 新手选择卡牌
class RoleNewbieCardChoose(RequestHandlerTask):
	url = r'/game/role/newbie/card/choose'

	@coroutine
	def run(self):
		guideID = self.input.get('guideID', None)
		cardID = self.input.get('cardID', None)
		if cardID is None:
			raise ClientError('cardID is miss')

		if guideID in self.game.role.newbie_guide:
			raise ClientError("guideID error")

		cfg = csv.newbie_init[1]
		card = None
		for v in cfg.cards:
			if v['id'] == cardID:
				card = v
				break
		if card is None:
			raise ClientError('cardID invalid')

		self.game.role.newbie_card_choice = card['id']
		eff = ObjectGainAux(self.game, {'card': card})
		yield effectAutoGain(eff, self.game, self.dbcGame, src='newbie_card')

		self.game.role.newbie_guide.append(guideID)

		cardID, _ = eff.result['carddbIDs'][0]
		self.game.role.deployBattleCards([None, cardID, None, None, None, None])
		ta.track(self.game, event='register',card_id=card['id'])

# 新手引导
class RoleNewbieGuide(RequestHandlerTask):
	url = r'/game/role/guide/newbie'

	@coroutine
	def run(self):
		guideID = self.input.get('guideID', None)
		if guideID in self.game.role.newbie_guide:
			raise ClientError("guideID error")
		self.game.role.newbie_guide.append(guideID)
		ta.track(self.game, event='guide',guide_id=guideID)

# 新手引导默默发奖励
class RoleNewbieGuideAward(RequestHandlerTask):
	url = r'/game/role/guide/newbie/award'

	@coroutine
	def run(self):
		guideCsvID = self.input.get('guideCsvID', None)
		if guideCsvID not in csv.new_guide:
			raise ClientError("guideCsvID error")
		guideID = csv.new_guide[guideCsvID].stage
		if guideID in self.game.role.newbie_guide:
			raise ClientError("guideID in error")
		self.game.role.newbie_guide.append(guideID)
		award = csv.new_guide[guideCsvID].award
		awardChoose = csv.new_guide[guideCsvID].awardChoose
		ret = {}
		eff = None
		if award:
			eff = ObjectGainAux(self.game, award)
		if awardChoose: # 和初始选择的卡牌有关
			award = awardChoose.get(self.game.role.newbie_card_choice, None)
			if award:
				if eff:
					eff += ObjectGainAux(self.game, award)
				else:
					eff = ObjectGainAux(self.game, award)
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='newbie_award')
			ret = eff.result
		self.write({'view': ret})


# 出售道具
class RoleItemSell(RequestHandlerTask):
	url = r'/game/role/item/sell'

	@coroutine
	def run(self):
		itemsD = self.input.get('itemsD', None)
		eff, cost = self.game.role.sellItems(itemsD) # 内部判断是否足够
		cost.cost(src='item_sell')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='item_sell')


# 使用道具（礼包类）
class RoleItemUse(RequestHandlerTask):
	url = r'/game/role/item/use'

	@coroutine
	def run(self):
		itemsD = self.input.get('itemsD', None)

		itemEffD = self.game.items.getCostItems(itemsD)
		if itemEffD is None:
			raise ClientError(ErrDefs.costNotEnough)

		ret = {}
		for itemID, itemEff in itemEffD.iteritems():
			yield effectAutoGain(itemEff,self.game,self.dbcGame,src='use_item')
			if isinstance(itemEff, ObjectGainAux):
				for k, v in itemEff.result.iteritems():
					if k not in ret:
						ret[k] = [v]
					else:
						ret[k].append(v)
		ret = {k: reduce(lambda x, y: x + y, v) for k, v in ret.iteritems()}
		self.write({
			'view': ret
		})


# 物品互换（进阶材料转换）
class RoleItemSwitch(RequestHandlerTask):
	url = r'/game/role/item/switch'

	@coroutine
	def run(self):
		itemsD = self.input.get('itemsD', None)  # 消耗的物品字典 {itemID: count}
		needItemID = self.input.get('needItemID', None)  # 目标物品ID

		if not itemsD or not isinstance(itemsD, dict):
			raise ClientError('itemsD is error')
		if needItemID is None:
			raise ClientError('needItemID is error')
		needItemID = int(needItemID)

		# 找到目标物品所属的转换组
		targetGroup = None
		for cfgID in csv.item_switch:
			cfg = csv.item_switch[cfgID]
			if needItemID in cfg.items:
				targetGroup = cfg.items
				break

		if targetGroup is None:
			raise ClientError('needItemID not in item_switch')

		# 验证所有消耗的物品都在同一组中，并且目标物品不在消耗列表中
		totalCost = 0
		costDict = {}
		for itemID, count in itemsD.iteritems():
			itemID = int(itemID)
			count = int(count)
			if count <= 0:
				continue
			if itemID not in targetGroup:
				raise ClientError('cost itemID not in same group')
			if itemID == needItemID:
				raise ClientError('can not switch to same item')
			costDict[itemID] = count
			totalCost += count

		if totalCost <= 0:
			raise ClientError('cost count is error')

		# 扣除消耗的物品
		cost = ObjectCostAux(self.game, costDict)
		if not cost.isEnough():
			raise ClientError(ErrDefs.costNotEnough)
		cost.cost(src='item_switch')

		# 给予等量的目标物品
		eff = ObjectGainAux(self.game, {needItemID: totalCost})
		yield effectAutoGain(eff, self.game, self.dbcGame, src='item_switch')


# 出售碎片
class RoleFragSellMany(RequestHandlerTask):
	url = r'/game/role/frag/sell_many'

	@coroutine
	def run(self):
		fragsD = self.input.get('fragsD', None)
		eff, cost = self.game.role.sellFrags(fragsD) # 内部判断是否足够
		cost.cost(src='item_sell')
		yield effectAutoGain(eff, self.game, self.dbcGame, src='item_sell')


# 碎片合成
# 碎片合成（兼容 fragIDs = <int> 或 fragIDs = {<id>: <times>, ...}）
class RoleFragComb(RequestHandlerTask):
    url = r'/game/role/frag/comb'

    @coroutine
    def run(self):
        payload = self.input.get('fragIDs', None)
        if payload is None:
            raise ClientError('fragID error')

        # 1) 归一化成 [(fragID, times), ...]
        tasks = []  # list of (fid, times)

        def _to_int(x):
            if isinstance(x, (int, long)):
                return int(x)
            # 兼容 "123" 这样的字符串
            return int(str(x))

        if isinstance(payload, dict):
            # 批量：{id: times}
            for k, v in payload.iteritems():
                try:
                    fid = _to_int(k)
                    times = max(1, _to_int(v))
                except Exception:
                    raise ClientError('fragIDs map format error')
                tasks.append((fid, times))
        else:
            # 单个：数字或数字字符串
            try:
                fid = _to_int(payload)
            except Exception:
                raise ClientError('fragIDs must be int or map')
            tasks.append((fid, 1))

        # 2)（可选）容量预检：估算将新增的卡数量
        role = self.game.role
        try:
            capacity = role.card_capacity
        except Exception:
            capacity = getattr(role, 'card_capacity', 0)
        current_count = len(role.cards or [])

        # 粗略预估：先统计会产卡的次数
        will_create = 0
        for fid, times in tasks:
            for _ in xrange(times):
                fe = self.game.frags.getCombFrag(fid)
                if fe is None:
                    raise ClientError('fragEff error: {}'.format(fid))
                if fe.cardID:
                    will_create += 1

        if capacity - (current_count + will_create) <= 0:
            raise ClientError('card capacity not enough')

        # 3) 真正执行：逐次生成
        created = []  # [{'db_id': ...}, ...]
        for fid, times in tasks:
            for _ in xrange(times):
                fragEff = self.game.frags.getCombFrag(fid)
                if fragEff is None:
                    raise ClientError('fragEff error: {}'.format(fid))

                if not role.card_capacity_free and fragEff.cardID:
                    # 保险：逐次落地前再判一次
                    raise ClientError('card capacity not enough')

                dbModel = None
                if fragEff.cardID:
                    # 生成卡记录
                    dbModel = yield createCardsDB({'id': fragEff.cardID}, role.id, self.dbcGame)

                # 结算
                fragEff.setDB(dbModel)
                fragEff.gain(src='frag_comb')

                # 跑马灯/公告
                if fragEff.cardID:
                    obj = fragEff.getObj()
                    ObjectMessageGlobal.newsCardMsg(role, obj, 'comb')
                    ObjectMessageGlobal.marqueeBroadcast(role, MessageDefs.MqFragCombCard, card=obj)
                    # 收集前端需要的 db_id
                    db_id = dbModel['id'] if isinstance(dbModel, dict) else dbModel.id
                    created.append({'db_id': db_id})

        # 4) 统一回包给前端：两种入参都返回 carddbIDs 数组
        self.write({
            'view': {
                'carddbIDs': created
            }
        })


# 碎片合成道具/携带道具
class RoleFragCombItem(RequestHandlerTask):
	url = r'/game/role/frag/comb/item'

	@coroutine
	def run(self):
		fragID = self.input.get('fragID', None)
		count = self.input.get('count', None)  # 合成数量
		if fragID is None or count is None:
			raise ClientError('parame is miss')
		if count <= 0:
			raise ClientError('count error')

		fragEff = self.game.frags.getCombFrag(fragID, count)
		if fragEff is None:
			raise ClientError('fragEff error')

		if fragEff.heldItemID:
			heldItemIDL = [fragEff.heldItemID for x in xrange(count)]
			dbModel = yield createHeldItemsDB(heldItemIDL, self.game.role.id, self.dbcGame)
			fragEff.setHeldItemDB(dbModel)
		fragEff.gain(src='frag_comb_item')

		if fragEff.heldItemID:
			objL = fragEff.getHeldItemObjL()
			for obj in objL:
				# TODO 目前没有这个消息
				ObjectMessageGlobal.newsHoldItemMsg(self.game.role, obj, 'comb')

		self.write({
			'view': fragEff.view
		})


# 使用体力药水
class RoleStaminaByUseItem(RequestHandlerTask):
	url = r'/game/role/stamina/use_item'

	@coroutine
	def run(self):
		itemID = self.input.get('itemID', None)
		itemCount = self.input.get('itemCount', 1)

		if itemID is None:
			raise ClientError('itemID error')
		if itemCount <= 0:
			raise ClientError('itemCount error')

		itemEff = self.game.items.getCostItem(itemID, itemCount)
		if itemEff is None:
			raise ClientError('item %d not enough' % itemID)

		itemEff.gain(src='use_stamina_item')


# 购买体力
class RoleStaminaBuy(RequestHandlerTask):
	url = r'/game/role/stamina/buy'

	@coroutine
	def run(self):
		if self.game.role.stamina >= StaminaLimitMax:
			raise ClientError(ErrDefs.staminaBuyNoNeed)

		if self.game.dailyRecord.buy_stamina_free_times < self.game.privilege.staminaBuyFreeTimes:
			# 月卡免费体力购买
			self.game.dailyRecord.buy_stamina_free_times += 1
			costRMB = 0
		else:
			times = self.game.dailyRecord.buy_stamina_times - self.game.dailyRecord.buy_stamina_free_times # 正常购买次数
			if times >= self.game.role.buyStaminaMaxTimes:
				raise ClientError(ErrDefs.staminaBuyMax)

			costRMB = ObjectCostCSV.getStaminaBuyCost(times)

		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='stamina_buy')

		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.BuyStaminaTimes, 1)

		# 运营活动 双倍
		yyTimes = 1
		yyID = ObjectYYHuoDongFactory.getDoubleDropOpenID(YYHuoDongDefs.DoubleBuyStamina)
		if yyID:
			count = csv.yunying.yyhuodong[yyID].paramMap['count']
			if self.game.dailyRecord.buy_stamina_times < count:
				yyTimes = 2

		# 进度赶超 双倍 (不和运营活动叠加)
		catchupCfg = ObjectYYHuoDongFactory.getReunionCatchUpCfg(self.game.role, ReunionDefs.DoubleBuyStamina)
		if self.game.role.canReunionCatchUp(catchupCfg) and catchupCfg.params['count'] > self.game.dailyRecord.buy_stamina_times:
			yyTimes = 2
			self.game.role.addReunionCatchUpRecord(catchupCfg.id)

		# 遗迹祝福 - 购买体力额外获得 (type=7)
		relicBonus = 0
		if self.game.town:
			from game.object.game.town_lottery import ObjectTownRelicBuff
			from framework.log import logger
			buffCfg = ObjectTownRelicBuff.consumeBuff(self.game, 7)  # type=7 购买体力祝福
			if buffCfg:
				param = getattr(buffCfg, 'param', 0)
				if param > 0:
					relicBonus = int(ConstDefs.staminaBuyRecover * param)
					logger.info('[RelicBuff] stamina buy: type=7 triggered, param=%s bonus=%s', param, relicBonus)
			else:
				logger.info('[RelicBuff] stamina buy: type=7 no buff available')

		totalStamina = ConstDefs.staminaBuyRecover * yyTimes + relicBonus
		eff = ObjectGainAux(self.game, {'stamina': totalStamina})
		eff.gain(src='stamina_buy')
		self.game.dailyRecord.buy_stamina_times += 1


# 领取关卡星级奖励
class RoleTakeMapStarAward(RequestHandlerTask):
	url = r'/game/role/map/star_award'

	@coroutine
	def run(self):
		mapID = self.input.get('mapID', None)
		awardLevel = self.input.get('awardLevel', -1)

		if mapID not in csv.world_map:
			raise ClientError('mapID error')
		if awardLevel < 0 or awardLevel > MapDefs.starAwardGold:
			raise ClientError('awardLevel error')

		giftID = self.game.role.takeMapStarAward(mapID, awardLevel)
		if giftID:
			giftEff = ObjectItemEffectFactory.getEffectByType(ItemDefs.giftInMemType, self.game, giftID, 1)
			if isinstance(giftEff, GiftItemEffect):
				yield effectAutoGain(giftEff, self.game, self.dbcGame, src='star')
			else:
				# general item gain
				giftEff.gain(src='star')
			self.write({
				'view': giftEff.result,
			})


# 领取日常任务奖励
class RoleDailyTaskGain(RequestHandlerTask):
	url = r'/game/role/daily_task/gain'

	@coroutine
	def run(self):
		taskID = self.input.get('taskID', None)

		if taskID not in csv.tasks:
			raise ClientError('taskID error')
		cfg = csv.tasks[taskID]
		if cfg.type != TaskDefs.dailyType:
			raise ClientError('task type error')

		taskEff = self.game.role.takeTaskAward(taskID)
		taskEff.gain(src='daily_task')

		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DailyTaskFinish, 1)
		ObjectYYHuoDongFactory.onTaskChange(self.game, PlayPassportDefs.DailyTask, cfg.point)

		self.write({'view': {
			'result': taskEff.result,
		}})


# 领取主线任务奖励
class RoleMainTaskGain(RequestHandlerTask):
	url = r'/game/role/main_task/gain'

	@coroutine
	def run(self):
		taskID = self.input.get('taskID', None)

		if taskID not in csv.tasks:
			raise ClientError('taskID error')
		if csv.tasks[taskID].type != TaskDefs.mainType:
			raise ClientError('task type error')

		# 主角升级和任务奖励均有可能赠送RMB
		oldLevel = self.game.role.level
		oldRMB = self.game.role.rmb

		taskEff = self.game.role.takeTaskAward(taskID)
		if taskEff:
			taskEff.gain(src='main_task')

		self.write({'view': {
			'role': {
				'addExp': taskEff.exp if taskEff else 0,
				'addLevel': self.game.role.level - oldLevel,
				'addGold': taskEff.gold if taskEff else 0,
				'addRMB': self.game.role.rmb - oldRMB,
			}
		}})

# 领取活跃度阶段奖励
class RoleLivenessStageAward(RequestHandlerTask):
	url = r'/game/role/liveness/stageaward'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		if csvID not in csv.livenessaward:
			raise ClientError('csvID error')
		eff = self.game.role.takeLivenessStageAward(csvID)
		eff.gain(src='liveness_stage_task')
		
		# 勋章计数：领取最高活跃度宝箱 (targetType=1, medalID=1001)
		# csvID=5 是最高档位（100点活跃度）
		if csvID == 5:
			self.game.medal.incrementMedalCounter(1001)

		self.write({'view': eff.result if eff else {}})


# 购买重置英雄关卡
class RoleHeroGateBuy(RequestHandlerTask):
	url = r'/game/role/hero_gate/buy'

	@coroutine
	def run(self):
		gateID = self.input.get('gateID', None)

		if gateID not in csv.scene_conf:
			raise ClientError('gateID error')

		if self.game.dailyRecord.buy_herogate_times.get(gateID, 0) >= self.game.role.buyHeroGateMaxTimes:
			raise ClientError(ErrDefs.herogateBuyMax)

		costRMB = ObjectCostCSV.getHeroGateBuyCost(self.game.dailyRecord.buy_herogate_times.get(gateID, 0))

		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='hero_gate_buy')

		self.game.role.resetHeroGate(gateID)
		if gateID in self.game.dailyRecord.buy_herogate_times:
			self.game.dailyRecord.buy_herogate_times[gateID] += 1
		else:
			self.game.dailyRecord.buy_herogate_times[gateID] = 1


# 充值（内部测试用）
class RoleRechargeBuy(RequestHandlerTask):
	url = r'/game/role/recharge/buy'

	@coroutine
	def run(self):
		if self.game.role.channel != 'none':
			raise ClientError('你是测试人员？')

		rechargeID = self.input.get('rechargeID', None)
		yyID = self.input.get('yyID', 0)
		csvID = self.input.get('csvID', 0)

		if rechargeID not in csv.recharges:
			raise ClientError('rechargeID error')

		self.game.role.buyRecharge(rechargeID, TestOrderID, yyID, csvID, push=True)


# 获取阅读邮件内容
class RoleMailGet(RequestHandlerTask):
	url = r'/game/role/mail/get'

	@coroutine
	def run(self):
		mailID = self.input.get('mailID', None)

		if not self.game.role.isMailExisted(mailID):
			mailData = self.game.role.getReadMailModel(mailID)
			if mailData is None:
				raise ClientError('mailID error')

		else:
			mailData = self.game.role.getMailModel(mailID)
			if mailData is None:
				mailData = yield self.dbcGame.call_async('DBRead', 'Mail', mailID, False)
				if not mailData['ret']:
					self.game.role.delMail(mailID)
					logger.info('not find !!! role %d del mail %s', self.game.role.uid, objectid2string(mailID))
					raise ServerError('db read mail error')
				mailData = mailData['model']
				self.game.role.setMailModel(mailID, mailData)
		# recharge_rmb在显示上转成rmb，防止客户端报错
		# 以后客户端邮件加上相关保护即可
		if mailData and 'attachs' in mailData:
			attachs = mailData['attachs']
			if attachs:
				mailData = copy.deepcopy(mailData)
				mailData['attachs'] = unpack(mailData['attachs'])
				attachs = mailData['attachs']
				rmb = attachs.pop('recharge_rmb', 0) # 服务器用
				if rmb > 0:
					attachs['rmb'] = rmb + attachs.get('rmb', 0)
				attachs.pop('recharge', None) # 服务器用
				attachs.pop('yyid', None) # 服务器用
				attachs.pop('csvid', None) # 服务器用

		self.write({'view': mailData})


# 领取邮件奖励或者已阅读邮件
class RoleMailRead(RequestHandlerTask):
	url = r'/game/role/mail/read'

	@coroutine
	def run(self):
		mailID = self.input.get('mailID', None)
		ret = {}

		mailData = self.game.role.getMailModel(mailID)
		if mailData is None:
			if not self.game.role.isReadMail(mailID):
				raise ClientError('mailID error')

		else:
			attachs = mailData['attachs']
			if attachs:
				attachs = unpack(attachs)
				eff = ObjectGainAux(self.game, attachs)
				if len(eff.cards) > self.game.role.card_capacity_free:
					raise ClientError(ErrDefs.cardCapacityLimit)
				yield deleteMail(self.game.role.id, mailID, self.dbcGame, self.game, gglobal=self.game.role.isGlobalMail(mailID))
				yield effectAutoGain(eff, self.game, self.dbcGame, src='mail')
				ret = eff.result
				# VIP奖励（邮件附件特有）
				vip = attachs.get('vip', None)
				if vip:
					self.game.role.setVIPLevel(vip)
				vipExp = attachs.get('vip_exp', None)
				if vipExp:
					self.game.role.addVIPExp(vipExp)
				recharge = attachs.get('recharge', None)
				if recharge:
					yyid = attachs.get('yyid', 0)
					csvid = attachs.get('csvid', 0)
					self.game.role.buyRecharge(recharge, TestOrderID, yyid, csvid)
			else:
				yield deleteMail(self.game.role.id, mailID, self.dbcGame, self.game, gglobal=self.game.role.isGlobalMail(mailID))

		self.write({'view': ret})

# 删除已读邮件
class RoleMailDelete(RequestHandlerTask):
	url = r'/game/role/mail/delete'

	@coroutine
	def run(self):
		# 删除已读邮件
		self.game.role.read_mailbox = []

# 签到
class RoleSignIn(RequestHandlerTask):
	url = r'/game/role/sign_in'

	@coroutine
	def run(self):
		eff = self.game.role.todaySignIn()
		ret = {}
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='sign')
			ret = eff.result
		self.write({'view': ret})

# 补签
class RoleSignInBuy(RequestHandlerTask):
	url = r'/game/role/sign_in/buy'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		eff = self.game.role.signInBuy(csvID)
		ret = {}
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='sign_in_buy')
			ret = eff.result
		self.write({'view': ret})


# 炼金
class RoleLianJin(RequestHandlerTask):
	url = r'/game/role/lianjin'

	@coroutine
	def run(self):
		count = self.input.get('count', None)
		if count is None or count <= 0:
			raise ClientError('count is error')

		role = self.game.role
		totalLimitTimes = role.lianJinTimes + role.freeLianJinTimes
		lianjinTimes = self.game.dailyRecord.lianjin_times
		freeTimes = self.game.dailyRecord.lianjin_free_times
		if lianjinTimes >= totalLimitTimes:
			raise ClientError(ErrDefs.lianjinMax)

		if freeTimes >= role.freeLianJinTimes:
			costRMB = ObjectCostCSV.getLianJinCost(lianjinTimes - freeTimes)
			if costRMB and costRMB > role.rmb:
				raise ClientError(ErrDefs.lianjinRMBNotEnough)

		# 遗迹祝福 - 聚宝额外金币 (type=8)
		relicGoldBonus = 0
		if self.game.town:
			from game.object.game.town_lottery import ObjectTownRelicBuff
			from framework.log import logger
			buffCfg = ObjectTownRelicBuff.consumeBuff(self.game, 8)
			if buffCfg:
				param = getattr(buffCfg, 'param', 0)
				if param > 0:
					relicGoldBonus = param  # 每次聚宝额外获得 param 比例的金币
					logger.info('[RelicBuff] lianjin: type=8 triggered, param=%s', param)
			else:
				logger.info('[RelicBuff] lianjin: type=8 no buff available')

		retView = []
		costSum = 0
		goldSum = 0
		relicBonusSum = 0
		for x in xrange(count):
			if lianjinTimes >= totalLimitTimes:
				break
			if freeTimes < role.freeLianJinTimes:
				current = 0 # 免费炼金rate一直取第一个
				nowcost = 0
				freeTimes += 1
			else:
				current = lianjinTimes - freeTimes
				nowcost = ObjectCostCSV.getLianJinCost(current)
				if nowcost and costSum + nowcost > role.rmb:
					break
			multiple, gold = role.lianjin(current, lianjinTimes)
			lianjinTimes += 1
			costSum += nowcost
			goldSum += gold
			# 计算遗迹祝福额外金币
			if relicGoldBonus > 0:
				relicBonusSum += int(gold * relicGoldBonus)
			retView.append({
				'multiple': multiple,
				'gold': gold,
			})

		cost = ObjectCostAux(self.game, {'rmb': costSum})
		cost.cost(src='lianjin')

		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.LianjinTimes, lianjinTimes - self.game.dailyRecord.lianjin_times)
		# 发放金币（包含遗迹祝福额外金币）
		totalGold = goldSum + relicBonusSum
		eff = ObjectGainAux(self.game, {'gold': totalGold})
		eff.gain(src='lianjin')
		self.game.dailyRecord.lianjin_times = lianjinTimes
		self.game.dailyRecord.lianjin_free_times = freeTimes
		for times in self.game.role.lianJinGift:
			if lianjinTimes >= times and times not in self.game.dailyRecord.lianjin_gifts:
				self.game.dailyRecord.lianjin_gifts[times] = 1 # 可领取

		self.write({'view': retView})


# 炼金每日累计奖励
class RoleLianjinTotalAward(RequestHandlerTask):
	url = r'/game/role/lianjin/total_award'

	@coroutine
	def run(self):
		times = self.input.get('times', None)  # 不传 则一键领取

		eff = ObjectGainAux(self.game, {})
		if not times:
			for times, flag in self.game.dailyRecord.lianjin_gifts.iteritems():
				if flag == 1:
					award = self.game.role.lianJinGift.get(times, None)
					if not award:
						continue
					self.game.dailyRecord.lianjin_gifts[times] = 0
					eff += ObjectGainAux(self.game, award)
			src = "lianjin_total_award_oneKey"
		else:
			flag = self.game.dailyRecord.lianjin_gifts.get(times, -1)
			if flag != 1:
				raise ClientError('can not get total award')
			award = self.game.role.lianJinGift.get(times, None)
			if not award:
				raise ClientError('no award')
			self.game.dailyRecord.lianjin_gifts[times] = 0
			eff += ObjectGainAux(self.game, award)
			src = "lianjin_total_award"
		yield effectAutoGain(eff, self.game, self.dbcGame, src=src)
		self.write({
			'view': eff.result,
		})

# 角色重命名
class RoleRename(RequestHandlerTask):
	url = r'/game/role/rename'

	@coroutine
	def run(self):
		name = self.input.get('name', None)

		if name is None:
			raise ClientError('name is miss')

		nameValid(name)

		rmb = ObjectCostCSV.getRenameCost(self.game.role.rename_count)
		if self.game.role.name != name:
			cost = ObjectCostAux(self.game, {'rmb': rmb})
			if not cost.isEnough():
				raise ClientError(ErrDefs.roleNameRMBNotEnough)

			if self.servMerged: # 合服，则添加相应的后缀
				name = '%s.s%d' % (name, self.game.role.area)
			ret = yield rolerename(self.dbcGame, self.game.role, name, self.roleNameCache)
			if ret:
				if self.game.role.rename_count > 0:
					cost.cost(src='role_rename')
				self.game.role.rename_count += 1
				self.write({'view': {'result': 'ok'}})
			else:
				raise ClientError(ErrDefs.roleNameExisted)
		else:
			self.write({'view': {'result': 'ok'}})

# 角色展示更换
class RoleDisplay(RequestHandlerTask):
	url = r'/game/role/display'

	@coroutine
	def run(self):
		display = self.input.get('display', None)
		if display is None:
			raise ClientError('display is miss')
		logo = display.get('logo', None)
		if logo:
			self.game.role.logo = logo
		frame = display.get('frame', None)
		if frame:
			if frame not in self.game.role.frames:
				raise ClientError('not have this frame')
			self.game.role.frame = frame

# 更换头像
class RoleLogo(RequestHandlerTask):
	url = r'/game/role/logo'

	@coroutine
	def run(self):
		logo = self.input.get('logo', None)

		if logo is None:
			raise ClientError('logo is miss')

		cfg = csv.role_logo[logo]
		role = self.game.role
		if not (cfg.cardID in role.pokedex or cfg.roleID in role.figures or cfg.skinID in role.skins or logo in role.logos):
			raise ClientError(ErrDefs.logoNotOwn)
		role.logo = logo

# 更换头像框
class RoleFrame(RequestHandlerTask):
	url = r'/game/role/frame'

	@coroutine
	def run(self):
		frame = self.input.get('frame', None)

		if frame is None:
			raise ClientError('frame is miss')

		if frame not in self.game.role.frames:
			raise ClientError('not have this frame')

		self.game.role.frame = frame


# 更换形象
class RoleFigure(RequestHandlerTask):
	url = r'/game/role/figure'

	@coroutine
	def run(self):
		figure = self.input.get('figure', None)

		if figure is None:
			raise ClientError('figure is miss')

		if figure not in self.game.role.figures:
			raise ClientError('not have this figure')

		self.game.role.figure = figure

# 分享
class RoleShare(RequestHandlerTask):
	url = r'/game/role/share'

	@coroutine
	def run(self):
		share = self.input.get('share', None)

		if share is None:
			raise ClientError('share is miss')

		self.game.dailyRecord.share_times += 1


# 全部领取或阅读邮件
class RoleMailReadAll(RequestHandlerTask):
	url = r'/game/role/mail/read/all'

	@coroutine
	def run(self):
		retL = []
		mailIDs = []
		for mailID in self.game.role.getMailIDs():
			mailData = self.game.role.getMailModel(mailID)
			if mailData is None:
				mailIDs.append(mailID)
			else:
				retL.append(mailData)

		if mailIDs:
			mailsData = yield self.dbcGame.call_async('DBMultipleRead', 'Mail', mailIDs)
			if not mailsData['ret']:
				raise ServerError('db query mails error')
			retL = retL + mailsData['models']
			for v in mailsData['models']:
				self.game.role.setMailModel(v['id'], v)

		from game.object.game.gain import ObjectGainResult
		result = ObjectGainResult({})
		for mailData in retL:
			if mailData is None:
				self.game.role.delMail(mailData['id'])
				continue
			cfg = csv.mail[mailData['type']]
			if cfg.tab == NoticeMail: # 通知类型邮件不能一键领取
				continue
			attachs = mailData['attachs']
			mailID = mailData['id']
			if attachs:
				attachs = unpack(attachs)
				eff = ObjectGainAux(self.game, attachs)
				if len(eff.cards) > self.game.role.card_capacity_free:
					continue
				yield deleteMail(self.game.role.id, mailID, self.dbcGame, self.game, gglobal=self.game.role.isGlobalMail(mailID))
				yield effectAutoGain(eff, self.game, self.dbcGame, src='mail')
				result += eff.result
				# VIP奖励（邮件附件特有）
				vip = attachs.get('vip', None)
				if vip:
					self.game.role.setVIPLevel(vip)
				vipExp = attachs.get('vip_exp', None)
				if vipExp:
					self.game.role.addVIPExp(vipExp)
				recharge = attachs.get('recharge', None)
				if recharge:
					yyid = attachs.get('yyid', 0)
					csvid = attachs.get('csvid', 0)
					self.game.role.buyRecharge(recharge, TestOrderID, yyid, csvid)
			else:
				yield deleteMail(self.game.role.id, mailID, self.dbcGame, self.game, gglobal=self.game.role.isGlobalMail(mailID))

		self.write({'view': result})


# 累积签到领取奖励
class RoleSignInTotalAward(RequestHandlerTask):
	url = r'/game/role/sign_in/total_award'

	@coroutine
	def run(self):
		if len(self.game.role.sign_in_gift) != 2:
			raise ClientError('sign total len error')
		sign_idx,sign_flag = self.game.role.sign_in_gift[0],self.game.role.sign_in_gift[1]
		if sign_idx not in csv.sighingift:
			raise ClientError('id not in csv.sighingift')
		if sign_flag == -1:
			raise ClientError('sign total can not award')

		nextID = sign_idx + 1
		self.game.role.sign_in_gift = [nextID, -1]
		if nextID in csv.sighingift:
			ncfg = csv.sighingift[nextID]
			if self.game.role.sign_in_count >= ncfg.day:
				self.game.role.sign_in_gift[1] = 1

		cfg = csv.sighingift[sign_idx]
		eff = ObjectGainAux(self.game, cfg.reward)
		ret = {}
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='sign_total')
			ret = eff.result

		self.write({'view': ret})

# 月累积签到领取奖励
class RoleSignInMonthTotalAward(RequestHandlerTask):
	url = r'/game/role/sign_in/month/total_award'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		if csvID is None:
			raise ClientError('csv id is None')
		sign_in_gift = self.game.monthlyRecord.sign_in_gift
		flag = sign_in_gift.get(csvID, -1)
		if flag != 1:
			raise ClientError('sign total can not award')

		sign_in_gift[csvID] = 0
		month = nowdate_t().month
		eff = ObjectGainAux(self.game, getL10nCsvValue(csv.signin[csvID], 'month%d' % month))
		ret = {}
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='month_sign_total')
			ret = eff.result

		self.write({'view': ret})


# 领取关卡星级奖励
class RoleGateAward(RequestHandlerTask):
	url = r'/game/role/gate/award'

	@coroutine
	def run(self):
		gateID = self.input.get('gateID', None)
		type = self.input.get('type', None)
		if gateID not in csv.scene_conf:
			raise ClientError('gateID error')
		eff = self.game.role.getGateExtraAwarrd(gateID, type)
		ret = {}
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='gate_award')
			ret = eff.result

		self.write({'view': ret})


# 购买技能点数
class RoleSkillPointBuy(RequestHandlerTask):
	url = r'/game/role/skill/point/buy'

	@coroutine
	def run(self):
		if self.game.role.skill_point >= self.game.role.skillPointMax:
			raise ClientError(ErrDefs.skillPointBuyNoNeed)
		if self.game.dailyRecord.buy_skill_point_times >= self.game.role.buySkillPointMaxTimes:
			raise ClientError(ErrDefs.skillPointBuyMax)

		costRMB = ObjectCostCSV.getSkillPointBuyCost(self.game.dailyRecord.buy_skill_point_times)

		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.buyRMBNotEnough)
		cost.cost(src='role_skillPoint_buy')

		eff = ObjectGainAux(self.game, {'skill_point': SkillPointBuy}) # 买依然是固定20点
		eff.gain(src='role_skillPoint_buy')
		self.game.dailyRecord.buy_skill_point_times += 1


# 购买vip礼包
class RoleVipGiftBuy(RequestHandlerTask):
	url = r'/game/role/vipgift/buy'

	@coroutine
	def run(self):
		vipLevel = self.input.get('vipLevel', None)
		if vipLevel is None or vipLevel == 0:
			raise ClientError('vipLevel error')

		role = self.game.role
		if role.vip_level < vipLevel:
			raise ClientError(ErrDefs.vipGiftLevelUp)

		if vipLevel in role.vip_gift and role.vip_gift[vipLevel] == 0:
			raise ClientError(ErrDefs.vipGiftAreadyBuy)

		cfg = csv.vip[vipLevel+1]
		if role.level < cfg.giftLevelLimit:
			raise ClientError('role level no enough')

		cost = ObjectCostAux(self.game, {'rmb': cfg.newPrice})
		if not cost.isEnough():
			raise ClientError(ErrDefs.vipGiftRmbUp)
		cost.cost(src='role_vipGift_buy')

		role.vip_gift[vipLevel] = 0

		eff = ObjectGainAux(self.game, cfg.gift)
		ret = {}
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='vip_gift')
			ret = eff.result

		self.write({'view': ret})


# 一键领取日常任务奖励
class RoleDailyTaskAllGain(RequestHandlerTask):
	url = r'/game/role/daily_task/allgain'

	@coroutine
	def run(self):
		from game.object.game.gain import ObjectGainResult
		result = ObjectGainResult({})
		tasks = self.game.tasks.getCanAwardDailyTasks()
		taskData = {}
		point = 0  # 活跃度总和
		for task in tasks:
			taskEff = task.getEffect()
			taskEff.gain(src='daily_task')
			result += taskEff.result
			taskData[task.id] = taskEff.result
			cfg = csv.tasks[task.id]
			point += cfg.point
		ObjectYYHuoDongFactory.onGeneralTask(self.game, TargetDefs.DailyTaskFinish, len(tasks))
		if point:
			ObjectYYHuoDongFactory.onTaskChange(self.game, PlayPassportDefs.DailyTask, point)

		# 自动领取可领取的活跃度宝箱奖励
		for csvID in csv.livenessaward:
			status = self.game.dailyRecord.liveness_stage_award.get(csvID, TaskDefs.taskNoneFlag)
			if status == TaskDefs.taskOpenFlag:
				eff = self.game.tasks.getLivenessStageEffect(csvID)
				eff.gain(src='liveness_stage_task')
				result += eff.result

		self.write({'view': {
			'result': result,
		}})

# 角色个性签名
class RolePersonalSign(RequestHandlerTask):
	url = r'/game/role/personal/sign'

	@coroutine
	def run(self):
		sign = self.input.get('sign', None)

		if sign is None:
			raise ClientError('sign is miss')

		usign = sign.decode('utf8')
		if len(usign) > 50:
			raise ClientError(ErrDefs.rolePersonalSignTooLong)
		if filterName(usign):
			raise ClientError(ErrDefs.rolePersonalSignInvalid)

		self.game.role.personal_sign = sign

# 万能碎片转换
class RoleAllCanItemSwitch(RequestHandlerTask):
	url = r'/game/role/acitem/switch'

	@coroutine
	def run(self):
		fragID = self.input.get('fragID', None)
		count = self.input.get('count', None)

		if count is None or count <= 0:
			raise ClientError('count is error')

		# fragID 不传为 普通万能碎片 ==》 神兽万能碎片
		# fragID   传为 万能碎片 ==》 精灵碎片
		if not fragID:
			costUniversalFragID = ConstDefs.universalFragGeneral
			fragID = ConstDefs.universalFragSpecial
			costCount = int(ConstDefs.universalFragSwitch * count)
		else:
			if fragID not in csv.fragments:
				raise ClientError('switch fragID error')
			cfg = csv.fragments[fragID]
			if not self.game.cards.isExistedByMarkID(csv.cards[cfg.combID].cardMarkID):
				raise ClientError(ErrDefs.allCanItemIDNoCard)
			# 不能转换为 万能整卡碎片
			if cfg.universalFragID == 0:
				raise ClientError('can not switch universalCard frag')
			costUniversalFragID = cfg.universalFragID
			costCount = count

		cost = ObjectCostAux(self.game, {costUniversalFragID: costCount})
		if not cost.isEnough():
			raise ClientError('cost item no enough')
		cost.cost(src='role_acitem_switch')

		eff = ObjectGainAux(self.game, {fragID: count})
		yield effectAutoGain(eff, self.game, self.dbcGame, src='role_acitem_switch')


# 领取在线礼包
class RoleOnlineGiftAward(RequestHandlerTask):
	url = r'/game/role/online_gift/award'

	@coroutine
	def run(self):
		self.game.role.refreshOnlineGift()
		eff = self.game.role.getOnlineGiftEffect()
		result = {}
		if eff:
			yield effectAutoGain(eff, self.game, self.dbcGame, src='online_gift')
			result = eff.result
		self.write({'view': result})


# 切换称号
class RoleSwitchTitle(RequestHandlerTask):
	url = r'/game/role/title/switch'

	@coroutine
	def run(self):
		titleID = self.input.get('titleID', 0)

		if titleID == -1:
			self.game.role.title_id = -1

		else:
			if titleID not in self.game.role.titles:
				raise ClientError(ErrDefs.titleNotExisted)
			self.game.role.title_id = titleID


# 使用可选择道具（礼包类）
class RoleGiftChoose(RequestHandlerTask):
	url = r'/game/role/gift/choose'

	@coroutine
	def run(self):
		itemID = self.input.get('itemID', None)
		count = self.input.get('count', None)
		choose = self.input.get('choose', None)
		isShowMsg = self.input.get('isShowMsg', False)
		tagItemCsvID = self.input.get('tagItemCsvID', None)  # 用户选择的具体 tag_items_lib 条目ID

		if itemID is None or count is None or choose is None or count <= 0:
			raise ClientError('param error')

		if itemID not in csv.items or csv.items[itemID].type != ItemDefs.chooseItemGift:
			raise ClientError('itemID error')

		if not ItemDefs.isItemID(itemID):
			raise ClientError('itemID error2')

		if not self.game.items.isEnough({itemID:count}):
			raise ClientError('count no enough')

		award = csv.items[itemID].specialArgsMap[choose]
		cost = ObjectCostAux(self.game, {itemID: count})
		if not cost.isEnough():
			raise ClientError('cost item no enough')
		cost.cost(src='role_gift_choose')

		# 处理标签字符串（如 tag_cardS）
		if isinstance(award, (str, unicode)):
			# award 是标签名，需要根据 tagItemCsvID 从 tag_items_lib 中获取具体道具/卡牌
			if tagItemCsvID is None:
				raise ClientError('tagItemCsvID required for tag award')
			
			if tagItemCsvID not in csv.tag_items_lib:
				raise ClientError('invalid tagItemCsvID')
			
			tag_cfg = csv.tag_items_lib[tagItemCsvID]
			
			# 验证标签是否匹配
			if getattr(tag_cfg, 'tag', None) != award:
				raise ClientError('tag mismatch')
			
			# 构造奖励字典
			if tag_cfg.cardID > 0:
				# ObjectGainAux expects {'card': {'id': card_id}} format for single card
				award = {'card': {'id': tag_cfg.cardID}}
			elif tag_cfg.itemID > 0:
				award = {tag_cfg.itemID: tag_cfg.chooseItemNum}
			else:
				raise ClientError('tag config error')
		
		eff = ObjectGainAux(self.game, award)
		ret = {}
		if eff:
			eff *= count
			yield effectAutoGain(eff, self.game, self.dbcGame, src='gift_choose')
			if isShowMsg and eff and eff.getCardsObjD():
				for dbID, obj in eff.getCardsObjD().iteritems():
					ObjectMessageGlobal.newsCardMsg(self.game.role, obj, 'limit_draw')
					ObjectMessageGlobal.marqueeBroadcast(self.game.role, MessageDefs.MqLimitDrawCard, card=obj)
			ret = eff.result

		self.write({
			'view': ret
		})

# 溢出经验兑换
class RoleOverflowExpExchange(RequestHandlerTask):
	url = r'/game/role/overflow_exp_exchange'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		count = self.input.get('count', 1)
		if csvID not in csv.overflow_exp_exchange:
			raise ClientError('csvID error')
		if count <= 0:
			raise ClientError('param error')
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.OverflowExpExchange, self.game):
			raise ClientError(ErrDefs.overflowExpNotOpen)

		cfg = csv.overflow_exp_exchange[csvID]
		if self.game.role.overflow_exp < cfg.needExp * count:
			raise ClientError(ErrDefs.overflowExpNotEnough)
		times = self.game.role.overflow_exp_exchanges.get(csvID, 0) + count
		if cfg.limit > 0 and times > cfg.limit:
			raise ClientError('count limit')
		self.game.role.overflow_exp -= cfg.needExp * count
		self.game.role.overflow_exp_exchanges[csvID] = times
		eff = ObjectGainAux(self.game, cfg.award)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='overflow_exp_exchange', mul=count)

		self.write({'view': eff.result if eff else {}})

# 精灵背包容量购买
class RoleCardCapacityBuy(RequestHandlerTask):
	url = r'/game/role/card_capacity/buy'

	@coroutine
	def run(self):
		if self.game.role.card_capacity_times >= self.game.role.cardbgBuyNum:
			raise ClientError("buy limit")
		rmb = ObjectCostCSV.getCardbagBuyCost(self.game.role.card_capacity_times)
		cost = ObjectCostAux(self.game, {'rmb': rmb})
		if not cost.isEnough():
			raise ClientError("cost rmb not enough")
		cost.cost(src='role_card_capacity_buy')
		self.game.role.card_capacity_times += 1
		self.game.role.card_capacity_buy += ConstDefs.cardBagCapacityIncrease

# 精灵图签突破
class PokedexAdvance(RequestHandlerTask):
	url = r'/game/role/pokedex_advance'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		if csvID == None:
			raise ClientError("param miss")
		self.game.pokedex.advance(csvID)

# 个人形象激活
class FigureActive(RequestHandlerTask):
	url = r'/game/role/figure_active'

	@coroutine
	def run(self):
		figureID = self.input.get('figureID', None)
		if self.game.role.figures.get(figureID, None):
			raise ClientError("already active")

		cfg = csv.role_figure[figureID]
		if not cfg.unlock:
			raise ClientError("only active get")
		for t, v in cfg.unlock.iteritems():
			_, pred = predGen(t, v, None)
			if not pred(self.game, None):
				raise ClientError("condition limit")

		self.game.role.activeFigure(figureID, False)

# 个人形象技能设置
class FigureSkillSwitch(RequestHandlerTask):
	url = r'/game/role/figure/skill/switch'

	@coroutine
	def run(self):
		figureID = self.input.get('figureID', 0)
		idx = self.input.get('idx', 0)  # 不传默认一号位
		skillFigureID = self.input.get('skillFigureID', 0)  # -1 置空

		role = self.game.role
		if idx >= role.figure_skill_count:
			raise ClientError('figure skill position locked')
		elif idx < 0:
			raise ClientError('idx error')

		if figureID not in self.game.role.figures:
			raise ClientError('figure not get')

		skillFigureIDs = role.skill_figures.setdefault(figureID, [figureID] if csv.role_figure[figureID].skills else [])
		if skillFigureID == -1:
			if len(skillFigureIDs) <= idx:
				raise ClientError('no skills')
			skillFigureIDs.pop(idx)
		elif skillFigureID > 0:
			cfg = csv.role_figure[figureID]
			if not cfg:
				raise ClientError('figure not existed')
			skillFigureCfg = csv.role_figure[skillFigureID]
			if not skillFigureCfg.skills:
				raise ClientError('figure skill error')
			if skillFigureID not in role.figures:
				raise ClientError('figure skill not get')

			if skillFigureID in skillFigureIDs:
				raise ClientError('skill already equipped')

			if len(skillFigureIDs) <= idx:
				skillFigureIDs.append(skillFigureID)
			else:
				skillFigureIDs[idx] = skillFigureID
		else:
			raise ClientError('figureID error')

		if figureID == role.figure:
			role.displayDirty = True

# 个人形象技能栏位解锁
class FigureSkillUnlock(RequestHandlerTask):
	url = r'/game/role/figure/skill/unlock'

	@coroutine
	def run(self):
		idx = self.input.get('idx', None)
		if idx is None:
			raise ClientError('param miss')
		if idx >= ConstDefs.figureSkillLimit:
			raise ClientError('figure skill position limit')
		role = self.game.role
		if idx != role.figure_skill_count or idx < 0:
			raise ClientError('idx error')

		if len(role.figures) < getattr(ConstDefs, 'figureSkill%d' % (idx+1)):
			raise ClientError(ErrDefs.figuresNotEnough)

		costRMB = ObjectCostCSV.getFigureSkillUnlockCost(idx-1)
		cost = ObjectCostAux(self.game, {'rmb': costRMB})
		if not cost.isEnough():
			raise ClientError(ErrDefs.costNotEnough)
		cost.cost(src='figure_skill_unlock')

		role.figure_skill_count += 1

# 主城彩蛋奖励领取
class CitySpriteGift(RequestHandlerTask):
	url = r'/game/role/city/sprite/gift'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		if csvID is None:
			raise ClientError('param miss')

		cfg = csv.city_sprites[csvID]
		if cfg.type == CitySpriteMiniQType: # 谜拟Q
			times = self.game.role.city_sprites['miniQ']['times']
			if times >= ConstDefs.citySpriteMiniQTimeMax:
				raise ClientError('times max')
			self.game.role.city_sprites['miniQ']['times'] += 1
			self.game.role.city_sprites['miniQ']['id'] = 0
			randLib = cfg.randLib
			self.game.achievement.onCount(AchievementDefs.MiniQActive, 1)
		else:
			baibian = self.game.role.city_sprites['baibian']
			if baibian and baibian['id'] == csvID:
				# 百变怪
				if baibian['times'] >= ConstDefs.citySpriteBaibianTimeMax:
					raise ClientError('times max')
				baibian['times'] += 1
				baibian['id'] = 0
				randLib = cfg.baibianRandLib
				self.game.achievement.onCount(AchievementDefs.BaiBianActive, 1)
			else:
				# 常规彩蛋奖励
				if self.game.dailyRecord.city_sprite_gift_times >= ConstDefs.citySpriteTimesMax:
					raise ClientError('times max')
				self.game.dailyRecord.city_sprite_gift_times += 1
				randLib = cfg.randLib
		# 随机奖励
		award = {}
		lib = ObjectDrawRandomItem.getObject(randLib)
		if lib:
			item = lib.getRandomItem()
			award = ObjectDrawRandomItem.packToDict(item)
		eff = ObjectGainAux(self.game, award)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='city_sprite_gift')
		self.game.achievement.onCount(AchievementDefs.CitySpriteCount, 1)
		self.write({
			'view': eff.result,
		})

# 主城百变怪/谜拟Q触发
class CitySpriteActive(RequestHandlerTask):
	url = r'/game/role/city/sprite/active'

	@coroutine
	def run(self):
		typ = self.input.get('type', None) # 1-百变怪; 2-谜拟Q
		if typ == 1:
			key = 'baibian'
			days = ConstDefs.citySpriteBaibianPeriodDay
			cd = ConstDefs.citySpriteBaibianCD
			timeMax = ConstDefs.citySpriteBaibianTimeMax
		else:
			key = 'miniQ'
			days = ConstDefs.citySpriteMiniQPeriodDay
			cd = ConstDefs.citySpriteMiniQCD
			timeMax = ConstDefs.citySpriteMiniQTimeMax

		city_sprites = self.game.role.city_sprites
		ndt = todayinclock5date2int()
		refresh = not city_sprites[key]
		if not refresh:
			period = city_sprites[key]['period']
			if (int2date(ndt) - int2date(period)).days >= days: # 周期刷新
				refresh = True
		if refresh:
			city_sprites[key] = {
				'period': ndt,
				'times': 0,
				'last': 0,
				'id': 0,
			}

		if city_sprites[key]['times'] >= timeMax: # 周期内领取达到上限不再触发
			return

		# if nowtime_t() - city_sprites[key]['last'] > cd:
			# if typ == 1:
				# self.game.role.randomBaibian()
			# else:
				# self.game.role.randomMiniQ()

# 成长向导奖励领取
class GrowGuideAwardGet(RequestHandlerTask):
	url = r'/game/role/growguide/award/get'

	@coroutine
	def run(self):
		csvID = self.input.get('csvID', None)
		if csvID is None:
			raise ClientError('param error')
		grow_guide = self.game.role.grow_guide
		info = grow_guide.get(csvID, None)
		if info is None:
			raise Return('not active this grow guide')
		flag, count = info
		if flag == 0:
			raise Return('already get award')
		if flag != 1:
			raise Return('can not get award')
		grow_guide[csvID] = (0, count)

		cfg = csv.grow_guide[csvID]
		eff = ObjectGainAux(self.game, cfg.award)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='grow_guide')
		self.write({'view': eff.result})


# 成就宝箱奖励领取
class AchievementBoxAwardGet(RequestHandlerTask):
	url = r'/game/role/achievement/box/award/get'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.achievement, self.game):
			raise ClientError(ErrDefs.achievementNotOpen)
		csvID = self.input.get('csvID', None)
		if csvID is None:
			raise ClientError('param error')
		awards = self.game.role.achievement_box_awards
		flag = awards.get(csvID, None)
		if flag is None:
			raise Return('not active this box')
		if flag == AchievementDefs.BoxAwardCloseFlag:
			raise Return('already get award')
		if flag != AchievementDefs.BoxAwardOpenFlag:
			raise Return('can not get award')
		awards[csvID] = AchievementDefs.BoxAwardCloseFlag

		cfg = csv.achievement.achievement_level[csvID]
		eff = ObjectGainAux(self.game, cfg.award)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='achievement_box_award')
		self.write({'view': eff.result})


# 成就任务奖励领取
class AchievementTaskAwardGet(RequestHandlerTask):
	url = r'/game/role/achievement/task/award/get'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.achievement, self.game):
			raise ClientError(ErrDefs.achievementNotOpen)
		csvID = self.input.get('csvID', None)
		if csvID is None:
			raise ClientError('param error')
		tasks = self.game.role.achievement_tasks
		task = tasks.get(csvID, None)
		if task is None:
			raise Return('not active this task')

		flag, time = task
		if flag == AchievementDefs.TaskAwardCloseFlag:
			raise Return('already get award')
		if flag != AchievementDefs.TaskAwardOpenFlag:
			raise Return('can not get award')

		# 获得奖励
		eff = self.game.achievement.getAchievementTaskAward(csvID)
		tasks[csvID] = (AchievementDefs.TaskAwardCloseFlag, time)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='achievement_task_award')

		yield ObjectRankGlobal.onKeyInfoChange(self.game, 'achievement')
		self.write({'view': eff.result})


# vip显示切换
class VipDisplaySwitch(RequestHandlerTask):
	url = r'/game/role/vip/display/switch'

	@coroutine
	def run(self):
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.VipDisplaySwitch, self.game):
			raise ClientError('vip display switch not open')

		flag = self.input.get('flag', None)  # bool

		if flag == None:
			raise ClientError('flag param miss')

		if flag == self.game.role.vip_hide:
			raise ClientError('flag param error')

		self.game.role.vip_hide = flag
		self.game.role.displayDirty = True


# vip 月度礼包
class VipMonthGift(RequestHandlerTask):
	url = r'/game/role/vip/month/gift'

	@coroutine
	def run(self):
		cfg = csv.vip[self.game.monthlyRecord.vip + 1]
		if not cfg or not cfg.monthGift:
			raise ClientError('current vip has not award')

		if self.game.monthlyRecord.vip_gift.get(cfg.id, -1) == 0:
			raise ClientError('has gained')

		self.game.monthlyRecord.vip_gift[cfg.id] = 0

		eff = ObjectGainAux(self.game, cfg.monthGift)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='vip_month_gift')

		self.write({'view': eff.result})
        
        
class RoleCitySceneSwitch(RequestHandlerTask):
    url = r'/game/role/city/scene/switch'

    @coroutine
    def run(self):
        sceneID = self.input.get('sceneID', None)
        if sceneID is None:
            raise ClientError('sceneID is miss')

        # 从 CSV 验证场景 ID 是否有效
        if sceneID not in csv.cityscene:
            raise ClientError('sceneID error')

        sceneCfg = csv.cityscene[sceneID]

        # 检查是否允许选择（canChoose 为 FALSE 时不允许手动切换）
        if not sceneCfg.canChoose:
            raise ClientError('scene not chooseable')

        # 设置场景ID
        self.game.role.city_scene = sceneID

        # 返回更详细的信息给前端
        self.write({
            'view': {
                'result': 'ok',
                'sceneID': sceneID,
                'sceneName': sceneCfg.name,
                'message': '场景切换成功'
            }
        })
   




# 主城跟随精灵--
class FollowSprite(RequestHandlerTask):
	url = r'/game/follow/sprite'

	@coroutine
	def run(self):
		cardID = self.input.get('cardID', None)
		if not isinstance(cardID, (str, unicode)):
			raise ServerError("cardDbID must be a string")
		
		self.game.role.follow_sprite = [cardID]

# 兵种卡牌放置接口
class RoleArmsCardsPlace(RequestHandlerTask):
	url = r'/game/role/arms/cards/place'

	@coroutine
	def run(self):
		armID = self.input.get('armID', None)
		markIDs = self.input.get('markIDs', [])
		cardIDs = self.input.get('cardIDs', None)
		
		if armID is None:
			raise ClientError('armID参数缺失')
		if not isinstance(markIDs, (list, tuple)):
			raise ClientError('markIDs参数格式错误')
		stageHint = self.input.get('i', None)
		stageInfo, refreshMarks, refreshNatureTypes = self.game.role.placeArmsCards(armID, markIDs, stageHint, cardIDs=cardIDs)
		yield self.game.role.save_async()
		armsData = self.game.role.getArmsData()

		cardsView = {}
		cardObjs = set()
		if refreshMarks:
			cardObjs.update(self.game.cards.getCardsByMarkIDs(refreshMarks))
		if refreshNatureTypes:
			cardObjs.update(self.game.cards.getCardsByNatures(refreshNatureTypes))

		for card in cardObjs:
			cardsView[str(card.id)] = {
				'id': card.id,
				'mark_id': card.markID,
				'card_id': card.card_id,
				'star': card.star,
				'fighting_point': card.fighting_point,
				'attrs': card._attrs,
			}

		# 归一化 arms_stage 键类型（确保前端收到 int 键）
		normalizedArmsStage = self.game.role._normalizeArmsStage(
			self.game.role.arms_stage if isinstance(self.game.role.arms_stage, dict) else {}
		)
		viewData = {
			'armID': stageInfo.get('armID'),
			'stage': stageInfo.get('stage', 0),
			'skillID': stageInfo.get('skillID', 0),
			'attrMap': stageInfo.get('attrMap', {}),
			'conditions': stageInfo.get('conditions', []),
			'markIDs': stageInfo.get('markIDs', []),
			'arms': dict(armsData),
			'arms_stage': normalizedArmsStage,
		}
		if cardsView:
			viewData['cards'] = cardsView

		self.write({
			'view': viewData
		})


#
# 星转系统 Card Star Swap
#

class CardStarSwap(RequestHandlerTask):
	"""
	卡牌星转接口
	前端传参：fieldID, cardID, targetCardID, action
	fieldID: 席位索引（0=永久兑换，>0=临时援助席位，1-based）
	cardID: 左侧卡牌ID（ObjectId 二进制）
	targetCardID: 右侧卡牌ID（ObjectId 二进制）
	action: 操作类型 "on"=开始援助，"off"=停止援助，None/空=永久兑换
	"""
	url = r'/game/card/star/swap'
	
	@coroutine
	def run(self):
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.CardStarSwap, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		# 参数解析（前端传字典参数）
		# 前端：gGameApp:requestServer("/game/card/star/swap", callback, fieldID, cardID, targetCardID, action)
		# 后端：self.input = {'fieldID': ..., 'cardID': ..., 'targetCardID': ..., 'action': ...}
		fieldID = int(self.input.get('fieldID', 0))  # 席位索引（0=永久兑换）
		leftCardDbId = self.input.get('cardID', None)  # ObjectId 二进制，直接使用
		rightCardDbId = self.input.get('targetCardID', None)  # ObjectId 二进制，直接使用
		action = self.input.get('action', None)  # "on" / "off" / None
		
		if not leftCardDbId or not rightCardDbId:
			raise ClientError('invalid card id')
		
		# 判断操作类型
		if action == 'on':
			# 开始援助
			if fieldID <= 0:
				raise ClientError('invalid seat index')
			
			self.game.role.cardStarSwapAid(fieldID, leftCardDbId, rightCardDbId, isStart=True)
			
			# 保存
			yield self.game.role.save_async()
			yield self.game.cards.save_async()
			
			# 返回数据
			leftCard = self.game.cards.getCard(leftCardDbId)
			rightCard = self.game.cards.getCard(rightCardDbId)
			
			self.write({
				'view': {
					'card_star_swap_fields': self.game.role.card_star_swap_fields,
					'cards': {
						str(leftCardDbId): {
							'id': leftCard.id,
							'star': leftCard.star,
							'fighting_point': leftCard.fighting_point,
							'attrs': leftCard._attrs,
							'skills': leftCard.skills,
							'star_skill_level': leftCard.star_skill_level,
							'skill_level': leftCard.skill_level,
						},
						str(rightCardDbId): {
							'id': rightCard.id,
							'star': rightCard.star,
							'fighting_point': rightCard.fighting_point,
							'attrs': rightCard._attrs,
							'skills': rightCard.skills,
							'star_skill_level': rightCard.star_skill_level,
							'skill_level': rightCard.skill_level,
						}
					}
				}
			})
		
		elif action == 'off':
			# 停止援助
			if fieldID <= 0:
				raise ClientError('invalid seat index')
			
			self.game.role.cardStarSwapAid(fieldID, leftCardDbId, rightCardDbId, isStart=False)
			
			# 保存
			yield self.game.role.save_async()
			yield self.game.cards.save_async()
			
			# 返回数据
			leftCard = self.game.cards.getCard(leftCardDbId)
			rightCard = self.game.cards.getCard(rightCardDbId)
			
			self.write({
				'view': {
					'card_star_swap_fields': self.game.role.card_star_swap_fields,
					'cards': {
						str(leftCardDbId): {
							'id': leftCard.id,
							'star': leftCard.star,
							'fighting_point': leftCard.fighting_point,
							'attrs': leftCard._attrs,
							'skills': leftCard.skills,
							'star_skill_level': leftCard.star_skill_level,
							'skill_level': leftCard.skill_level,
						},
						str(rightCardDbId): {
							'id': rightCard.id,
							'star': rightCard.star,
							'fighting_point': rightCard.fighting_point,
							'attrs': rightCard._attrs,
							'skills': rightCard.skills,
							'star_skill_level': rightCard.star_skill_level,
							'skill_level': rightCard.skill_level,
						}
					}
				}
			})
		
		else:
			# 永久兑换
			self.game.role.cardStarSwapExchange(leftCardDbId, rightCardDbId)
			
			# 保存
			yield self.game.role.save_async()
			yield self.game.cards.save_async()
			
			# 返回数据
			leftCard = self.game.cards.getCard(leftCardDbId)
			rightCard = self.game.cards.getCard(rightCardDbId)
			
			self.write({
				'view': {
					'card_star_swap_times': self.game.role.card_star_swap_times,
					'card_star_swap_times_cd': self.game.role.card_star_swap_times_cd,
					'card_star_swap_times_total': self.game.role.card_star_swap_times_total or 0,
					'cards': {
						str(leftCardDbId): {
							'id': leftCard.id,
							'star': leftCard.star,
							'fighting_point': leftCard.fighting_point,
							'attrs': leftCard._attrs,
							'skills': leftCard.skills,
							'star_skill_level': leftCard.star_skill_level,
							'skill_level': leftCard.skill_level,
						},
						str(rightCardDbId): {
							'id': rightCard.id,
							'star': rightCard.star,
							'fighting_point': rightCard.fighting_point,
							'attrs': rightCard._attrs,
							'skills': rightCard.skills,
							'star_skill_level': rightCard.star_skill_level,
							'skill_level': rightCard.skill_level,
						}
					}
				}
			})


class CardStarSwapReceive(RequestHandlerTask):
	"""
	领取星转奖励
	前端传参：csvID (单个CSV ID)
	"""
	url = r'/game/role/card_star_swap/times/get'
	
	@coroutine
	def run(self):
		# 检查功能解锁
		if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.CardStarSwap, self.game):
			raise ClientError(ErrDefs.levelLessNoOpened)
		
		from game.object.game.gain import ObjectGainAux
		import framework
		
		# 获取要领取的CSV ID
		csvId = self.input.get('csvID', None)
		if not csvId:
			raise ClientError('invalid csvID')
		
		csvId = int(csvId)
		
		# 检查CSV配置是否存在
		if csvId not in csv.card_star_swap_times_deliver:
			raise ClientError('invalid csvID')
		
		cfg = csv.card_star_swap_times_deliver[csvId]
		
		# 检查是否已领取
		deliverRecord = self.game.role.card_star_swap_times_deliver_record or {}
		if deliverRecord.get(csvId, False):
			raise ClientError('already received')
		
		# 检查语言
		if framework.__language__ not in cfg.languages:
			raise ClientError('language not match')
		
		# 检查时间（前端逻辑：CSV 字段为整数日期和时间字符串，直接用时间戳比较）
		nowTime = nowtime_t()
		
		# 注意：CSV 中的日期字段在后端可能已经被转换为时间戳
		# 如果是整数日期（如 20250101），需要特殊处理
		# 这里直接使用时间戳比较（假设 CSV 加载时已转换）
		if cfg.date and cfg.endDate:
			# 简单判断：如果 date 是小整数（如 < 100000000），说明是时间戳
			# 否则是日期整数，需要转换
			startTime = cfg.date if cfg.date > 100000000 else 0
			endTime = cfg.endDate if cfg.endDate > 100000000 else 9999999999
			
			if not (startTime <= nowTime <= endTime):
				raise ClientError('not in time range')
		
		# 检查类型和条件
		if cfg.type == 1:
			# VIP等级
			if self.game.role.vip_level < cfg.param:
				raise ClientError('vip level not enough')
		elif cfg.type == 2:
			# 角色等级
			if self.game.role.level < cfg.param:
				raise ClientError('role level not enough')
		elif cfg.type == 3:
			# 创建时间（比较日期部分）
			from framework import datetimefromtimestamp, date2int
			roleCreatedDate = date2int(datetimefromtimestamp(self.game.role.created_time).date())
			
			validStart = cfg.validRoleCreatedEarliestDate if cfg.validRoleCreatedEarliestDate else 0
			validEnd = cfg.validRoleCreatedLatestDate if cfg.validRoleCreatedLatestDate else 99991231
			
			if not (validStart <= roleCreatedDate <= validEnd):
				raise ClientError('role created time not in range')
		
		# 发放奖励
		eff = ObjectGainAux(self.game, {})
		if cfg.starSwapTimes:
			eff += ObjectGainAux(self.game, cfg.starSwapTimes)
		
		eff.gain(src='star_swap_receive')
		
		# 标记已领取
		if not self.game.role.card_star_swap_times_deliver_record:
			self.game.role.card_star_swap_times_deliver_record = {}
		
		self.game.role.card_star_swap_times_deliver_record[csvId] = True
		
		# 保存
		yield self.game.role.save_async()
		
		# 返回数据
		self.write({
			'view': {
				'card_star_swap_times_deliver_record': self.game.role.card_star_swap_times_deliver_record,
				'result': eff.result,
			}
		})


# 勋章领取奖励
class MedalAwardGet(RequestHandlerTask):
	url = r'/game/role/medal/award/get'
	
	@coroutine
	def run(self):
		medalID = self.input.get('medalID', None)
		if medalID is None:
			raise ClientError('param miss')
		
		medalID = int(medalID)
		
		# 前端传的是 medalID（勋章组ID），需要找到对应的 csvID
		# 查找当前可领取的该 medalID 的勋章
		medalTask = self.game.role.medal_task or {}
		csvID = None
		for k in csv.medal:
			cfg = csv.medal[k]
			if cfg.medalID == medalID and medalTask.get(k) == 1:
				csvID = k
				break
		
		if csvID is None:
			raise ClientError('medal cannot get award')
		
		cfg = csv.medal[csvID]
		
		# 激活勋章
		self.game.medal.activateMedal(csvID)
		
		# 设置为已领取（medalTask[csvID] = 0）
		medalTask[csvID] = 0
		self.game.role.medal_task = medalTask
		
		# 更新所有卡牌的属性和战力（勋章提供全局属性加成）
		for cardID in self.game.role.cards:
			card = self.game.cards.getCard(cardID)
			if card:
				card._attrs = None  # 清空属性缓存，强制重新计算
				card.onUpdateAttrs()  # 触发属性和战力更新
		
		# 发放奖励
		eff = ObjectGainAux(self.game, cfg.award)
		yield effectAutoGain(eff, self.game, self.dbcGame, src='medal_award')
		
		self.write({
			'view': eff.result
		})


# 勋章展示设置
class MedalShow(RequestHandlerTask):
	url = r'/game/role/medal/show'
	
	@coroutine
	def run(self):
		medalID = self.input.get('medalID', None)
		if medalID is None:
			raise ClientError('param miss')
		
		medalID = int(medalID)
		
		# medalID 是勋章组 ID，需要检查该组是否有已激活的勋章
		if medalID != 0:
			hasActivated = False
			for k in csv.medal:
				cfg = csv.medal[k]
				if cfg.medalID == medalID and self.game.medal.isMedalActive(k):
					hasActivated = True
					break
			
			if not hasActivated:
				raise ClientError('medal not activated')
		
		# 设置展示勋章（使用勋章组 ID）
		if self.game.role.medal_show == medalID:
			# 如果当前已经展示这个勋章，则取消展示
			self.game.role.medal_show = 0
		else:
			# 否则展示这个勋章
			self.game.role.medal_show = medalID
		
		self.write({
			'view': {}
		})
