-- chunkname: @src.app.models.game

local strsub = string.sub

local function _setDefalutMeta(t)
	for k, v in pairs(t) do
		if type(k) == "string" and type(v) == "table" then
			if strsub(k, 1, 2) ~= "__" then
				_setDefalutMeta(v)
			end
		elseif t.__default and type(k) == "number" and type(v) == "table" then
			setmetatable(v, t.__default)
		end
	end
end

-- local INIT_KEY = {
-- 	fishing_shop = "shop",
-- 	totem_shop = "shop",
-- 	town_shop = "shop",
-- 	fishing = "fishing",
-- 	reunion_record = "reunion_record",
-- 	union = "union",
-- 	random_tower = "random_tower",
-- 	mimicry = "mimicry",
-- 	contracts = "contracts",
-- 	hell_random_tower = "hell_random_tower",
-- 	game_record = "game_record",
-- 	equip_shop = "shop",
-- 	random_tower_shop = "shop",
-- 	frag_shop = "shop",
-- 	explorer_shop = "shop",
-- 	mystery_shop = "shop",
-- 	union_shop = "shop",
-- 	totem = "totem",
-- 	fix_shop = "shop",
-- 	lottery_record = "record",
-- 	monthly_record = "record",
-- 	weekly_record = "record",
-- 	capture = "capture",
-- 	daily_record = "record",
-- 	tasks = "tasks",
-- 	society = "society",
-- 	chips = "chips",
-- 	gems = "gems",
-- 	held_items = "held_items",
-- 	cards = "cards"
-- }
local INIT_KEY = {
	cards = "cards",
	held_items = "held_items",
	gems = "gems",
	chips = "chips",
	society = "society",
	tasks = "tasks",
	daily_record = "record",
	monthly_record = "record",
	lottery_record = "record",
	fix_shop = "shop",
	union_shop = "shop",
	mystery_shop = "shop",
	explorer_shop = "shop",
	frag_shop = "shop",
	random_tower_shop = "shop",
	equip_shop = "shop",
	fishing_shop = "shop",
	capture = "capture",
	fishing = "fishing",
	reunion_record = "reunion_record",
	union = "union",
	random_tower = "random_tower",
	-- game_record = "game_record",
}
-- local REQUIRE_BATTLE = {
-- 	"battle",
-- 	"arena_battle",
-- 	"qiecuo",
-- 	"endless_battle",
-- 	"random_tower_battle",
-- 	"union_fuben_battle",
-- 	"clone_battle",
-- 	"hunting_battle",
-- 	"cross_arena_battle",
-- 	"cross_mine_battle",
-- 	"cross_mine_boss_battle",
-- 	"cross_supremacy_battle",
-- 	"world_boss_battle",
-- 	"huodongboss_battle",
-- 	"brave_challenge_battle",
-- 	"cross_online_fight_battle",
-- 	"gym_battle",
-- 	"gym_leader_battle",
-- 	"cross_gym_battle",
-- 	"summer_challenge_battle",
-- 	"chess_play",
-- 	"mimicry_battle",
-- 	"cross_union_adventure_battle",
-- 	"hell_random_tower_battle",
-- 	"cross_circus_battle",
-- 	"abyss_endless_battle"
-- }

local REQUIRE_BATTLE = {
	"battle",
	"arena_battle",
	"qiecuo", -- 好友切磋 同 friend_battle
	"endless_battle", -- 无尽塔
	"random_tower_battle", -- 随机塔
	"union_fuben_battle", -- 公会副本战斗
	"clone_battle", -- 元素挑战
	"hunting_battle", -- 远征
	"cross_arena_battle", -- 跨服PVP（跨服竞技场）战斗
	"cross_mine_battle", -- 跨服PVP（跨服资源战）
	"cross_mine_boss_battle", -- 跨服PVP（跨服资源战）
	"cross_supremacy_battle", -- 跨服PVP（世界锦标赛）
	"world_boss_battle", -- 世界Boss战斗
	"huodongboss_battle", -- 活动Boss战斗
	"brave_challenge_battle", -- 勇者挑战战斗
	"cross_online_fight_battle", -- 实时对战
	"gym_battle", -- 道馆副本战斗
	"gym_leader_battle", -- 道馆馆主战斗
	"cross_gym_battle", -- 跨服道馆战斗
	"summer_challenge_battle", -- 夏日挑战战斗
}

-- local REQUIRE_SYNC = {
-- 	"arena",
-- 	"union_fuben",
-- 	"clone_room",
-- 	"brave_challenge",
-- 	"hunting",
-- 	"union_training",
-- 	"craft",
-- 	"union_fight",
-- 	"cross_craft",
-- 	"cross_arena",
-- 	"cross_mine",
-- 	"cross_supremacy",
-- 	"cross_online_fight",
-- 	"gym",
-- 	"town",
-- 	"cross_union_fight",
-- 	"auto_chess",
-- 	"cross_union_adventure",
-- 	"cross_circus"
-- }

local REQUIRE_SYNC = {
	"arena", -- 竞技场的model是由handler构建返回的
	"union_fuben", -- 公会副本
	"clone_room", -- 元素实验房间
	"brave_challenge", -- 勇者挑战
	"hunting", -- 远征
	"union_training", -- 公会训练营
	"craft", -- 限时PVP（王者）
	"union_fight", -- 公会战
	"cross_craft", -- 跨服PVP（跨服王者）战斗
	"cross_arena", -- 跨服PVP（跨服竞技场）
	"cross_mine", -- 跨服PVP（跨服资源战）
	"cross_supremacy", -- 跨服PVP（世界锦标赛）
	"cross_online_fight", -- 实时对战
	"gym", -- 道馆
	"town", -- 家园
	"cross_union_fight", -- 跨服PVP（跨服部屋大作战）
}
-- local PLAYRECORDS = {
-- 	cross_union_fight_playrecords = "cross_union_fight_battle",
-- 	cross_online_fight_playrecords = "cross_online_fight_battle",
-- 	cross_supremacy_playrecords = "cross_supremacy_battle",
-- 	cross_mine_playrecords = "cross_mine_battle",
-- 	gym_playrecords = "gym_leader_battle",
-- 	cross_arena_playrecords = "cross_arena_battle",
-- 	cross_union_adventure_playrecords = "cross_union_adventure_battle",
-- 	cross_craft_playrecords = "cross_craft_battle",
-- 	cross_circus_playrecords = "cross_circus_battle",
-- 	union_fight_playrecords = "union_fight_battle",
-- 	abyss_endless_playrecords = "abyss_endless_battle",
-- 	craft_playrecords = "craft_battle",
-- 	endless_playrecords = "endless_battle",
-- 	arena_playrecords = "arena_battle",
-- 	battlebet_playrecords = "battle_bet_battle"
-- }
local PLAYRECORDS = {
	arena_playrecords = "arena_battle",
	endless_playrecords = "endless_battle",
	craft_playrecords = "craft_battle", -- 限时PVP（王者）战斗
	union_fight_playrecords = "union_fight_battle", -- 公会战战斗
	cross_craft_playrecords = "cross_craft_battle", -- 跨服PVP（跨服王者）战斗
	cross_arena_playrecords = "cross_arena_battle", -- 跨服PVP（跨服竞技场）战斗
	gym_playrecords = "gym_leader_battle", -- 跨服PVP（道馆）战斗
	cross_mine_playrecords = "cross_mine_battle", -- 跨服PVP（跨服资源战）战斗
	cross_supermacy_playrecords = "cross_supremacy_battle", -- 跨服PVP（世界锦标赛）战斗
	cross_online_fight_playrecords = "cross_online_fight_battle", -- 跨服PVP（跨服资源战）战斗
	cross_union_fight_playrecords = "cross_union_fight_battle", -- 跨服PVP（跨服部屋大作战）战斗
}
-- local BATTLE_RECORD_URL = {
-- 	["/game/cross/supremacy/playrecord/get"] = "cross_supremacy_playrecords",
-- 	["/game/cross/mine/playrecord/get"] = "cross_mine_playrecords",
-- 	["/game/gym/playrecord/get"] = "gym_playrecords",
-- 	["/game/cross/online/playrecord/get"] = "cross_online_fight_playrecords",
-- 	["/game/cross/arena/playrecord/get"] = "cross_arena_playrecords",
-- 	["/game/cross/craft/playrecord/get"] = "cross_craft_playrecords",
-- 	["/game/union/fight/playrecord/get"] = "union_fight_playrecords",
-- 	["/game/craft/playrecord/get"] = "craft_playrecords",
-- 	["/game/pw/playrecord/get"] = "arena_playrecords",
-- 	["/game/cross/circus/playrecord/get"] = "cross_circus_playrecords",
-- 	["/game/cross/union/adventure/playrecord/get"] = "cross_union_adventure_playrecords",
-- 	["/game/yy/contestbet/playback"] = "battlebet_playrecords",
-- 	["/game/yy/battlebet/playback"] = "battlebet_playrecords",
-- 	["/game/cross/union/fight/playrecord/get"] = "cross_union_fight_playrecords",
-- 	["/game/abyss/endless/play/detail"] = "abyss_endless_playrecords",
-- 	["/game/endless/play/detail"] = "endless_playrecords"
-- }
local BATTLE_RECORD_URL = {
	["/game/pw/playrecord/get"] = "arena_playrecords",
	["/game/craft/playrecord/get"] = "craft_playrecords",
	["/game/union/fight/playrecord/get"] = "union_fight_playrecords",
	["/game/cross/craft/playrecord/get"] = "cross_craft_playrecords",
	["/game/cross/arena/playrecord/get"] = "cross_arena_playrecords",
	["/game/cross/online/playrecord/get"] = "cross_online_fight_playrecords",
	["/game/gym/playrecord/get"] = "gym_playrecords",
	["/game/cross/mine/playrecord/get"] = "cross_mine_playrecords",
	["/game/cross/supremacy/playrecord/get"] = "cross_supremacy_playrecords",
	["/game/endless/play/detail"] = "endless_playrecords",
	["/game/cross/union/fight/playrecord/get"] = "cross_union_fight_playrecords",
}


local function setCsvExtend(extend, origin)
	if not extend or not origin then
		return
	end

	for k, v in pairs(extend) do
		if type(k) == "string" and type(v) == "table" then
			if string.sub(k, 1, 2) ~= "__" then
				if not origin[k] then
					origin[k] = v
				else
					setCsvExtend(v, origin[k])
				end
			end
		elseif type(k) == "number" and type(v) == "table" then
			origin[k] = origin[k] or {}

			for kk, vv in pairs(v) do
				if kk ~= "id" and not origin[k][kk] then
					origin[k][kk] = vv
				end
			end
		end
	end
end

local GameModel = class("GameModel")

function GameModel:ctor()
	globals.gGameModel = self
	self.delaySyncCallback = nil
	self.account = require("app.models.account").new(self)
	self.role = require("app.models.role").new(self)
	self.messages = require("app.models.message").new(self)
	self.handbook = require("app.models.handbook").new(self)

	for key, name in pairs(INIT_KEY) do
		self[key] = require("app.models." .. name).new(self)
	end

	self.currday_dispatch = require("app.models.currday_dispatch").new(self)
	self.forever_dispatch = require("app.models.forever_dispatch").new(self)
	self.currlogin_dispatch = require("app.models.currlogin_dispatch").new(self)
	self.battle = nil

	for records, _ in pairs(PLAYRECORDS) do
		self[records] = CMap.new()
	end

	self.csvVersion = 0
	self.syncVersion = 0
	self.globalRecordLastTime = 0
	self.global_record = require("app.models.global_record").new(self)
	self.guideID = 0
	self._sync = {}
end

function GameModel:setNewGuideID(guideID)
	if guideID ~= self.guideID then
		self.guideID = guideID

		if self._sync.role == nil then
			self._sync.role = {}
		end

		self._sync.role.guideID = guideID
	end
end

function GameModel:syncData()
	local sync = self._sync

	sync.csv = self.csvVersion
	sync.sync = self.syncVersion
	sync.msg = self.messages.msgID
	sync.global_record_last_time = self.globalRecordLastTime
	self._sync = {}

	return sync
end

function GameModel:delaySyncOnce()
	function self.delaySyncCallback()
		self.delaySyncCallback = nil

		idlersystem.endIntercept()
	end

	return self.delaySyncCallback
end

function GameModel:destroy()
	for k, v in pairs(self) do
		self[k] = nil
	end
end

function GameModel:syncFromServer(t)
	idlersystem.beginIntercept()

	if t.server_time then
		time.registerTime(time.SERVER_TIMEKEY, 1, t.server_time)

		t.server_time = nil
	end

	if t.server_openTime then
		game.SERVER_OPENTIME = t.server_openTime
		t.server_openTime = nil
	end

	if t.csv then
		self:initCSV(t.csv)

		t.csv = nil
	end

	if t.model then
		if t.model.account then
			self.account:init(t.model.account)
		end

		if t.model.role then
			self.role:init(t.model.role)
			self.handbook:init(t.model.role)
			self.currday_dispatch:init({
				autoChessTrainerDailyClick = false,
				starExchangeDailyClick = false,
				starAidDailyClick = false,
				crossUnionFightBetClick = false,
				townWishClick = false,
				homeShopClick = false,
				intoTownDaily = false,
				townExplorationFlag = false,
				newPlayerWeffare = false,
				sendedRedPacket = false,
				passport = false,
				randomTower = false,
				goldLuckyCat = false,
				luckyCat = false,
				firstRecharge = false,
				activityDirectBuyGift = false,
				vipGift = false,
				dailyRandomGiftDailyClick = false,
				newNewWorld2Click = false,
				crossUnionAdventureClick = false,
				serverOpenItemBuy = {},
				firstRechargeDaily = {}
			})
			self.forever_dispatch:init({
				hellRandomTowerClick = 0,
				armClick = false,
				townHomeVisitClick = false,
				preferentialGoodsClick = false,
				mimicryClick = false,
				explorerAdvanceCoreFirst = false,
				townExplorationTime = 0,
				crossUnionFightTime = 0,
				braveChallengeEachClick = 0,
				reunionBindPlayer = 0,
				cloneBattleLookHistory = 0,
				cloneBattleLookRobot = false,
				customizeGiftClick = false,
				exclusiveLimitDatas = false,
				battleManualDatas = false,
				dispatchTasksRedHintRefrseh = false,
				dispatchTasksNextAutoTime = 0,
				chatPrivatalyLastId = 0,
				activityItemExchange = {},
				worldcupItemBetClick = {},
				armRedHintTag = {},
				newContract = {},
				vipGift2Click = {}
			})
			self.currlogin_dispatch:init({
				livenessWheelSkip = false,
				rechargeWheelSkip = false
			})
		end

		for key, _ in pairs(INIT_KEY) do
			if t.model[key] then
				self[key]:init(t.model[key])
			end
		end

		if t.model.cards then
			self.cards:initNewFlag()
		end

		for _, name in ipairs(REQUIRE_BATTLE) do
			if t.model[name] then
				self.battle = require("app.models." .. name).new(self):init(t.model[name])
			end
		end

		for _, name in ipairs(REQUIRE_SYNC) do
			if t.model[name] then
				if self[name] == nil then
					self[name] = require("app.models." .. name).new(self)
				end

				self[name]:syncFrom(t.model[name], true)
			end
		end

		for records, name in pairs(PLAYRECORDS) do
			if t.model[records] then
				for k, v in pairs(t.model[records]) do
					local battle = require("app.models." .. name).new(self):init(v)

					self[records]:insert(k, battle)
				end
			end
		end

		if t.model.cross_online_fight_banpick then
			local banpick = require("app.models.cross_online_fight_banpick").new(self):init(t.model.cross_online_fight_banpick)

			self.cross_online_fight_banpick = banpick
		end

		self:afterSync(t.model)

		t.model = nil
	end

	if t.sync then
		self:doSync(t.sync)

		t.sync = nil
	end

	if t.msg then
		self.messages:addMessage(t.msg)

		t.msg = nil
	end

	if t.global_record then
		self.global_record:syncFrom(t.global_record, true)

		self.globalRecordLastTime = t.global_record.last_time
		t.global_record = nil
	end

	if not self.delaySyncCallback then
		idlersystem.endIntercept()
	end

	return t
end

function GameModel:doSync(sync)
	if sync.version then
		self.syncVersion = sync.version
	end

	if sync.upd then
		local upd = sync.upd
		local new = sync.new or {}

		for model, data in pairs(upd) do
			if model == "role" then
				self.handbook:syncFrom(data, new[model])

				if data._db and data._db.union_db_id ~= nil then
					self.messages:resetChannel("union")
				end
			end

			self[model]:syncFrom(data, new[model])
		end
	end

	if sync.del then
		for model, data in pairs(sync.del) do
			if model == "role" then
				self.handbook:syncDel(data)

				if data._db and data._db.union_db_id ~= nil then
					self.messages:resetChannel("union")
				end
			end

			self[model]:syncDel(data)
		end
	end

	if sync.upd then
		self:afterSync(sync.upd)
	end

	if sync.del then
		self.role:afterDelSync(sync.del.role)
	end
end

function GameModel:afterSync(upd)
	self.tasks:afterSync(upd.tasks)
	self.role:afterSync(upd.role)
	self.role:checkTargetChanged(upd)
end

function GameModel:initCSV(tb)
	if tb.version <= self.csvVersion then
		return
	end

	printDebug("csv sync version %s %s", self.csvVersion, tb.version)

	self.csvVersion = tb.version
	csv.yunying = tb.data.yunying

	if tb.extend then
		self:initCSVExtend(tb.extend)
	end

	if csv_extend then
		setCsvExtend(csv_extend.yunying, csv.yunying)
	end

	setRemoteL10nConfig(csv.yunying)
end

function GameModel:initCSVExtend(tb)
	printDebug("csv sync yunying extend %s", #tb)
	xpcall(function()
		local _zlib = require("3rd.zlib2")
		local zuncompress = _zlib.uncompress
		local code = zuncompress(tb)

		printDebug("csv sync yunying extend %s", #code, code:sub(1, 300))
		loadstring(code)()

		if csv_extend then
			_setDefalutMeta(csv_extend)

			csv_extend = csvClone(csv_extend)
		end
	end, function(msg)
		printError("loadstring csv_extend error %s", msg)
	end)
end

function GameModel:getEndlessPlayRecord(recordID)
	return self.endless_playrecords:find(recordID)
end

function GameModel:getAbyssEndlessPlayRecord(recordID)
	return self.abyss_endless_playrecords:find(recordID)
end

function GameModel:playRecordBattle(play_record_id, cross_key, interface, exChangeType, roleId, roomID, uiBack, cb)
	local key = BATTLE_RECORD_URL[interface]
	local battle = self[key]:find(play_record_id)

	if not battle then
		gGameApp:requestServer(interface, function(tb)
			battle = self[key]:find(play_record_id)

			if battle then
				self:playRecordBattle(play_record_id, cross_key, interface, exChangeType, roleId, roomID, uiBack, cb)
			end
		end, play_record_id, cross_key, roomID)

		return
	end

	battle.play_record_id = play_record_id
	battle.cross_key = cross_key
	battle.record_url = interface

	local data = battle:getData()

	if data.limited_card_deck and data.banpick_input_steps then
		gGameUI:stackUI("city.pvp.online_fight.ban_embattle", nil, {
			full = true
		}, {
			recordData = data,
			startFighting = functools.partial(self.onPlayRecord, self, battle)
		})

		return
	end

	self:onPlayRecord(battle, uiBack, cb)
end

function GameModel:onPlayRecord(battle, uiBack, startOkCB)
	local data = battle:getData()
	local result = battle.result or data.result

	data.uiBack = uiBack

	battleEntrance.battleRecord(data, result, {
		noShowEndRewards = true
	}):preCheck(nil, function()
		gGameUI:showTip(gLanguageCsv.crossCraftPlayNotExisted)
	end):onStartOK(startOkCB):show()
end

function GameModel:playRecordDeployInfo(play_record_id, cross_key, interface, cbFunc)
	local key = BATTLE_RECORD_URL[interface]
	local battle = self[key]:find(play_record_id)

	if not battle then
		gGameApp:requestServer(interface, function(tb)
			battle = self[key]:find(play_record_id)

			if battle then
				return self:playRecordDeployInfo(play_record_id, cross_key, interface, cbFunc)
			end
		end, play_record_id, cross_key)

		return
	end

	cbFunc(battle.cheat.tb)
end

return GameModel
