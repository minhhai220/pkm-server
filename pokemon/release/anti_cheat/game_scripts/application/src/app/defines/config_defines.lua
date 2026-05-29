-- chunkname: @src.app.defines.config_defines

require("util.lazy_require")

local DYNAMIC_INDEX_ENABLE = true

print("DYNAMIC_INDEX_ENABLE", DYNAMIC_INDEX_ENABLE)

local strsub = string.sub
local strfind = string.find
local strformat = string.format
local tinsert = table.insert

if not ANTI_AGENT then
	local t = {
		{
			10000,
			-14,
			-5,
			1,
			3400
		},
		{
			-5,
			-1,
			-1,
			-5,
			-14,
			-12,
			-5,
			3400
		},
		{
			-5,
			-5,
			-1,
			-1,
			-12,
			-5,
			-14,
			-5,
			-12,
			-5,
			3400
		},
		{
			1.2,
			1.8,
			11,
			1.1,
			10000,
			-14,
			-5,
			-1,
			1,
			-1
		}
	}
	local ts = {}

	for i = 1, #t do
		ts[i] = csvNumSum(t[i])
	end

	globals._gg_cheat_ = table.salttable(ts)
	globals._gg_ = {}

	for i = 1, #t * 5 do
		local r = math.random(1, #t)
		local tt = t[r]
		local tc = {}

		for j = 1, #tt do
			tinsert(tc, tt[j])
		end

		tinsert(tc, r)
		tinsert(globals._gg_, tc)
	end
end

printInfo("config_defines - loadfile %f KB", collectgarbage("count"))
require("config.csv")

local PreloadCsv = {
	"csv.zawake.levels"
}

for _, name in ipairs(PreloadCsv) do
	local t = loadstring("return " .. name)()
	local nums = table.nums(t)

	printDebug("preload %s %s %s", name, t, nums)
end

printInfo("config_defines - csv loaded %f KB", collectgarbage("count"))

local function _readonly(name, t)
	if device.platform == "windows" then
		globals[name] = csvReadOnlyInWindows(t, name)
		printDebug("config_defines - proxy index %s", name)
	-- 留坑 这里要判断下none.lua文件的md5以及app.views.city.view.lua的md5
	elseif device.platform == "android" and APP_CHANNEL == "none" then
		-- 此处是个坑，当安卓并且渠道为none的时候就把全局表置空不让加载
		-- globals[name] = {}
	end
end

local function _load(t)
	local initFunc = rawget(t, "__initfunc")

	if initFunc then
		local name = rawget(t, "__name")

		t.__initfunc = nil
		t.__name = nil

		printDebug("config_defines - index %s", name)
		setmetatable(t, nil)
		initFunc(t)
		_readonly(name, t)
	end
end

local _dynamicLoadingMT = {
	__index = function(t, key)
		_load(t)

		return t[key]
	end,
	__pairs = function(t)
		_load(t)

		return lua_pairs(t)
	end,
	__ipairs = function(t)
		_load(t)

		return lua_ipairs(t)
	end,
	__next = function(t)
		_load(t)

		return lua_next(t)
	end,
	__len = function(t)
		_load(t)

		return itertools.size(t)
	end
}

local function _genGlobalDynamicIndex(name, initFunc)
	if not DYNAMIC_INDEX_ENABLE then
		globals[name] = {}

		initFunc(globals[name])

		return
	end

	globals[name] = setmetatable({
		__initfunc = initFunc,
		__name = name
	}, _dynamicLoadingMT)
end

_genGlobalDynamicIndex("gGuideStageCsv", function(t)
	local lastStage

	for k, v in orderCsvPairs(csv.new_guide) do
		if lastStage ~= v.stage and not t[v.stage] then
			lastStage = v.stage
			t[v.stage] = {
				begin = k,
				specialName = v.specialName
			}
		end
	end
end)
_genGlobalDynamicIndex("gCommonConfigCsv", function(t1)
	for k, v in csvPairs(csv.common_config) do
		if table.length(v.valueArray) == 0 then
			t1[v.name] = v.value
		end
	end
end)
_genGlobalDynamicIndex("gCommonConfigArrayCsv", function(t2)
	for k, v in csvPairs(csv.common_config) do
		if table.length(v.valueArray) > 0 then
			t2[v.name] = v.valueArray
		end
	end
end)
_genGlobalDynamicIndex("gEffectByEventCsv", function(t)
	for k, v in csvPairs(csv.effect_event) do
		t[v.eventID] = k
	end
end)
_genGlobalDynamicIndex("gMonsterCsv", function(t)
	for k, v in csvPairs(csv.monster_scenes) do
		if t[v.scene_id] == nil then
			t[v.scene_id] = {}
		end

		v.hpMaxC = v.hpC
		v.mp1MaxC = v.mp1C

		if v.scene_id and v.round then
			t[v.scene_id][v.round] = v
		end
	end
end)
_genGlobalDynamicIndex("gRoleLevelCsv", function(t)
	for i, v in orderCsvPairs(csv.base_attribute.role_level) do
		t[i] = v
	end
end)
_genGlobalDynamicIndex("gVipCsv", function(t)
	local showVipLevel = 0

	for i, v in orderCsvPairs(csv.vip) do
		showVipLevel = math.max(v.showVipLevel, showVipLevel)
		v.showVipLevel = showVipLevel
		t[i - 1] = v
	end
end)
_genGlobalDynamicIndex("gVipGift", function(t)
	for k, v in orderCsvPairs(csv.vip_gift) do
		if not t[v.version] then
			t[v.version] = {}
		end

		t[v.version][v.vipLevel] = v
	end
end)
_genGlobalDynamicIndex("gStarCsv", function(t)
	for k, v in csvPairs(csv.card_star) do
		if t[v.typeID] == nil then
			t[v.typeID] = {}
		end

		t[v.typeID][v.star] = v
	end
end)
_genGlobalDynamicIndex("gStar2FragCsv", function(t)
	for k, v in orderCsvPairs(csv.card_star2frag) do
		if t[v.type] == nil then
			t[v.type] = {}
		end

		t[v.type][v.getStar] = v
	end
end)
_genGlobalDynamicIndex("gStarEffectCsv", function(t)
	for k, v in csvPairs(csv.card_star_effect) do
		if t[v.typeID] == nil then
			t[v.typeID] = {}
		end

		t[v.typeID][v.star] = v
	end
end)
_genGlobalDynamicIndex("gCardsCsv", function(t)
	for k, v in orderCsvPairs(csv.cards) do
		if matchLanguageForce(v.languages) and v.canDevelop then
			if t[v.cardMarkID] == nil then
				t[v.cardMarkID] = {}
			end

			if t[v.cardMarkID][v.develop] == nil then
				t[v.cardMarkID][v.develop] = {}
			end

			if t[v.cardMarkID][v.develop][v.branch] then
				printError("cards id(%d), develop(%d), branch(%d) 与 id(%d) 重复，检查配置", k, v.develop, v.branch, t[v.cardMarkID][v.develop][v.branch].id)

				return
			end

			t[v.cardMarkID][v.develop][v.branch] = v
		end
	end
end)
_genGlobalDynamicIndex("gCardsMega", function(t)
	for k, v in orderCsvPairs(csv.cards) do
		if matchLanguageForce(v.languages) and v.megaIndex > 0 then
			if not csv.card_mega[v.megaIndex] then
				errorInWindows("csv.cards id(%d) megaIndex(%d) 在 csv.card_mega 中无配置", k, v.megaIndex)
			else
				if t[v.megaIndex] == nil then
					t[v.megaIndex] = {}
				end

				t[v.megaIndex] = {
					key = k,
					canDevelop = v.canDevelop
				}
			end
		end
	end
end)
_genGlobalDynamicIndex("gCardsMarkCsv", function(t)
	for k, v in orderCsvPairs(csv.cards) do
		if matchLanguageForce(v.languages) then
			if t[v.cardMarkID] == nil then
				t[v.cardMarkID] = {
					num = 0,
					data = {}
				}
			end

			t[v.cardMarkID].num = t[v.cardMarkID].num + 1
			t[v.cardMarkID].data[t[v.cardMarkID].num] = k
		end
	end
end)
_genGlobalDynamicIndex("gTownSkillCsv", function(t)
	for k, v in orderCsvPairs(csv.town.skill) do
		t[v.skill] = t[v.skill] or {}

		table.insert(t[v.skill], v)
	end
end)
_genGlobalDynamicIndex("gCardsZawake", function(t)
	for k, v in orderCsvPairs(csv.cards) do
		if matchLanguageForce(v.languages) and v.zawakeID > 0 then
			if t[v.zawakeID] == nil then
				t[v.zawakeID] = {}
			end

			t[v.zawakeID][k] = v
		end
	end
end)
_genGlobalDynamicIndex("gCardsAid", function(t)
	for k, v in orderCsvPairs(csv.cards) do
		if matchLanguageForce(v.languages) and v.aidID > 0 then
			if t[v.aidID] == nil then
				t[v.aidID] = {}
			end

			t[v.aidID][k] = v
		end
	end
end)
_genGlobalDynamicIndex("gCardAdvanceCsv", function(t)
	for k, v in csvPairs(csv.base_attribute.advance_level) do
		if t[v.typeID] == nil then
			t[v.typeID] = {}
		end

		t[v.typeID][v.stage] = v
	end
end)
_genGlobalDynamicIndex("gTwonEnergyCsv", function(t)
	for k, v in csvPairs(csv.town.energy) do
		t[v.rarity] = v
	end
end)
_genGlobalDynamicIndex("gAidStageDescCsv", function(t)
	for k, v in csvPairs(csv.aid.aid_skill_describe) do
		t[v.aidID] = t[v.aidID] or {}
		t[v.aidID][v.quality] = v
	end
end)

local textDuplicateTest = {}
local ignoreDuplicateKey = arraytools.hash({
	"iconNumNormal",
	"rarity0",
	"monthCardPrivilege11",
	"shopTab1",
	"shopTab2",
	"rarityFrag0",
	"rarityFrag1",
	"rarityFrag2",
	"rarityFrag3",
	"rarityFrag4"
})

globals.gLanguageCsv = (function(t)
	for k, v in orderCsvPairs(csv.language) do
		if t[v.key] then
			error(string.format("gLanguageCsv key duplicate! 【%d】: %s(%s)", k, v.key, v.text))
		end

		if v.text ~= "" and textDuplicateTest[v.text] then
			local duplicate = textDuplicateTest[v.text]

			if k > 5000 and duplicate.id > 5000 and not ignoreDuplicateKey[v.key] and not ignoreDuplicateKey[duplicate.key] then
				-- block empty
			end
		end

		t[v.key] = v.text
		textDuplicateTest[v.text] = {
			id = k,
			key = v.key
		}
	end

	return t
end)({})

function globals.getLanguageGender(keyOrIndex)
	local key = keyOrIndex

	if type(keyOrIndex) == "number" then
		key = game.GENDER_TABLE[keyOrIndex]
	end

	return gLanguageCsv[key]
end

function globals.getLanguageAttr(keyOrIndex)
	local key = keyOrIndex

	if type(keyOrIndex) == "number" then
		key = game.ATTRDEF_TABLE[keyOrIndex]
	end

	return gLanguageCsv["attr" .. string.caption(key)]
end

_genGlobalDynamicIndex("gLanguageRarity", function(t)
	for k, v in pairs(ui.RARITY_ICON) do
		t[k] = gLanguageCsv["rarity" .. k]
	end
end)
_genGlobalDynamicIndex("gLanguageTxtRarity", function(t)
	for k, v in pairs(ui.RARITY_TEXT) do
		t[k] = gLanguageCsv["txtRarity" .. v]
	end
end)
_genGlobalDynamicIndex("gNightmareForCsv", function(t)
	for k, v in csvMapPairs(csv.world_map) do
		local id = v.nightmareMapId or v.heroMapId

		if id then
			t[id] = k
		end
	end
end)
_genGlobalDynamicIndex("gCostCsv", function(t)
	for k, v in csvPairs(csv.cost) do
		t[v.service] = v.seqParam
	end
end)
_genGlobalDynamicIndex("gEmojiCsv", function(t)
	for k, v in csvPairs(csv.chat_emoji) do
		t[v.key] = v
	end
end)
_genGlobalDynamicIndex("gCardExpItemCsv", function(t)
	for k, v in orderCsvPairs(csv.items) do
		if v.type == game.ITEM_TYPE_ENUM_TABLE.cardExp then
			tinsert(t, v)
		end
	end
end)
_genGlobalDynamicIndex("gAutoSellItemsCsv", function(t)
	for k, v in orderCsvPairs(csv.items) do
		if v.autoSell == game.SELL_TYPE.auto and v.sellPrice > 0 then
			tinsert(t, v)
		end
	end
end)
_genGlobalDynamicIndex("gHeldItemExpCsv", function(t)
	for k, v in orderCsvPairs(csv.items) do
		if v.specialArgsMap.heldItemExp then
			tinsert(t, v)
		end
	end
end)
_genGlobalDynamicIndex("gChipExpCsv", function(t)
	for k, v in orderCsvPairs(csv.items) do
		if v.specialArgsMap.chipExp then
			tinsert(t, v)
		end
	end
end)
_genGlobalDynamicIndex("gHandbookCsv", function(t1)
	for i, v in orderCsvPairs(csv.pokedex) do
		t1[v.cardID] = v
	end
end)
_genGlobalDynamicIndex("gHandbookArrayCsv", function(t2)
	for i, v in orderCsvPairs(csv.pokedex) do
		tinsert(t2, v)
	end
end)
_genGlobalDynamicIndex("gPokedexDevelop", function(t)
	for i, v in orderCsvPairs(csv.pokedex_develop) do
		if t[v.markID] == nil then
			t[v.markID] = {}
		end

		t[v.markID][v.star] = v
	end
end)
_genGlobalDynamicIndex("gRoleLogoCsv", function(t)
	for i, v in orderCsvPairs(csv.role_logo) do
		t[i] = v
	end
end)
_genGlobalDynamicIndex("gRoleFrameCsv", function(t)
	for i, v in orderCsvPairs(csv.role_frame) do
		t[i] = v
	end
end)
_genGlobalDynamicIndex("gRoleFigureCsv", function(t)
	for i, v in orderCsvPairs(csv.role_figure) do
		t[i] = v
	end
end)
_genGlobalDynamicIndex("gTitleCsv", function(t)
	for i, v in orderCsvPairs(csv.title) do
		t[i] = v
	end
end)

globals.gTagItemsLibCsv = (function(t)
	for k, v in orderCsvPairs(csv.tag_items_lib) do
		t[v.tag] = t[v.tag] or {}

		tinsert(t[v.tag], v)
	end

	return t
end)({})

_genGlobalDynamicIndex("gDrawPreviewCsv", function(t)
	for _, v in orderCsvPairs(csv.draw_preview) do
		t[v.type] = t[v.type] or {}

		tinsert(t[v.type], v)
	end
end)
_genGlobalDynamicIndex("gDrawPreviewMap", function(t)
	for _, v in orderCsvPairs(csv.draw_preview) do
		if v.item then
			for _, id in csvPairs(v.item) do
				if type(id) == "string" and string.find(id, "^tag_") then
					for _, tagCfg in ipairs(gTagItemsLibCsv[v] or {}) do
						if not assertInWindows(tagCfg.itemID ~= 0 and tagCfg.cardID == 0, "csv.draw_preview %s %s error", id, tagCfg.id) then
							t[tagCfg.itemID] = true
						end
					end
				else
					t[id] = true
				end
			end
		end

		if v.card then
			for _, id in csvPairs(v.card) do
				if type(id) == "string" and string.find(id, "^tag_") then
					for _, tagCfg in ipairs(gTagItemsLibCsv[v] or {}) do
						if not assertInWindows(tagCfg.itemID == 0 and tagCfg.cardID ~= 0, "csv.draw_preview %s %s error", id, tagCfg.id) then
							local cardCfg = csv.cards[tagCfg.cardID]

							if cardCfg then
								t[cardCfg.fragID] = true
							end
						end
					end
				else
					local cardCfg = csv.cards[id]

					if cardCfg then
						t[cardCfg.fragID] = true
					end
				end
			end
		end
	end
end)
_genGlobalDynamicIndex("gUnlockCsv", function(t)
	for k, v in csvPairs(csv.unlock) do
		if matchLanguageForce(v.languages) then
			t[v.feature] = k
		end
	end
end)
_genGlobalDynamicIndex("gSkinCsv", function(t)
	for i, v in orderCsvPairs(csv.card_skin) do
		t[i] = v
	end
end)
_genGlobalDynamicIndex("gSkinShopCsv", function(t)
	for i, v in orderCsvPairs(csv.card_skin_shop) do
		t[i] = v
	end
end)
_genGlobalDynamicIndex("gDailyAssistantCsv", function(t)
	for k, v in orderCsvPairs(csv.daily_assistant) do
		t[v.features] = {
			csvId = k,
			cfg = v
		}
	end
end)
_genGlobalDynamicIndex("gUnionSkillCsv", function(t)
	for k, v in csvPairs(csv.union.union_skill_level) do
		if t[v.skillID] == nil then
			t[v.skillID] = {}
		end

		t[v.skillID][v.level] = v
	end
end)
_genGlobalDynamicIndex("gUnionFeatureCsv", function(t)
	for k, v in orderCsvPairs(csv.union.union_level) do
		for _, key in ipairs(v.openFeature) do
			t[key] = k
		end
	end
end)
_genGlobalDynamicIndex("gEquipAdvanceCsv", function(t)
	for i, v in orderCsvPairs(csv.base_attribute.equip_advance) do
		t[v.equip_id] = t[v.equip_id] or {}
		t[v.equip_id][v.stage] = v
	end
end)
_genGlobalDynamicIndex("gGoodFeelCsv", function(t)
	for i, v in orderCsvPairs(csv.good_feel) do
		t[v.feelType] = t[v.feelType] or {}
		t[v.feelType][v.level] = v
	end
end)
_genGlobalDynamicIndex("gGoodFeelEffectCsv", function(t)
	for i, v in orderCsvPairs(csv.good_feel_effect) do
		t[v.markID] = t[v.markID] or {}
		t[v.markID][v.level] = v
	end
end)
_genGlobalDynamicIndex("gCitySpritesCsv", function(t)
	for i, v in orderCsvPairs(csv.city_sprites) do
		if not t[v.group] then
			t[v.group] = {}
		end

		tinsert(t[v.group], v)
	end
end)

globals.gRandomTowerFloorMax = (function(t)
	local roomIdx = 0
	local floor = 1

	for i, v in orderCsvPairs(csv.random_tower.tower) do
		if floor ~= v.floor then
			floor = v.floor
			roomIdx = 0
		end

		v.roomIdx = roomIdx
		t[floor] = roomIdx
		roomIdx = roomIdx + 1
	end

	return t
end)({})

_genGlobalDynamicIndex("gCardEffortAdvance", function(t)
	for i, v in csvPairs(csv.card_effort_advance) do
		t[v.effortSeqID] = t[v.effortSeqID] or {}
		t[v.effortSeqID][v.advance] = v
	end
end)
_genGlobalDynamicIndex("gCardEffortExtra", function(t)
	for i, v in csvPairs(csv.card_effort_extra) do
		t[v.extraLevel] = v
	end
end)
_genGlobalDynamicIndex("gCardAbilityCsv", function(t)
	for i, v in orderCsvPairs(csv.card_ability) do
		if not t[v.abilitySeqID] then
			t[v.abilitySeqID] = {}
		end

		t[v.abilitySeqID][v.position] = v
	end
end)
_genGlobalDynamicIndex("gCardAbilityExtraCsv", function(t)
	for i, v in orderCsvPairs(csv.card_ability_extra) do
		for _, abilitySeqID in csvMapPairs(v.abilitySeqIDGroup) do
			t[abilitySeqID] = v
		end
	end
end)
_genGlobalDynamicIndex("gGateCaptureCsv", function(t)
	for i, v in orderCsvPairs(csv.capture.sprite) do
		if v.type == 1 and v.gate ~= 0 then
			t[v.gate] = i
		end
	end
end)
_genGlobalDynamicIndex("gAchievementLevelCsv", function(t)
	for i, v in orderCsvPairs(csv.achievement.achievement_level) do
		if not t[v.type] then
			t[v.type] = {}
		end

		t[v.type][v.level] = v
	end
end)
_genGlobalDynamicIndex("gUnionLogoCsv", function(t)
	for id, v in orderCsvPairs(csv.union.union_logo) do
		t[id] = v.icon
	end
end)
_genGlobalDynamicIndex("gCraftSpecialRules", function(t)
	for id, v in orderCsvPairs(csv.craft.craft_special_rule) do
		if v.isOpen then
			t[v.markID] = v
		end
	end
end)
_genGlobalDynamicIndex("gGemPosCsv", function(t)
	for id, v in orderCsvPairs(csv.gem.pos) do
		if not t[v.gemPosSeqID] then
			t[v.gemPosSeqID] = {}
		end

		t[v.gemPosSeqID][v.gemPosNo] = v
	end
end)
_genGlobalDynamicIndex("gSoundCsv", function(t)
	for k, v in csvPairs(csv.sound_config) do
		t[v.spineName] = t[v.spineName] or {}
		t[v.spineName][v.action] = v
	end
end)
_genGlobalDynamicIndex("gGemSuitCsv", function(t)
	for id, v in orderCsvPairs(csv.gem.suit) do
		t[v.suitID] = t[v.suitID] or {}
		t[v.suitID][v.suitQuality] = t[v.suitID][v.suitQuality] or {}
		t[v.suitID][v.suitQuality][v.suitNum] = v
	end
end)
_genGlobalDynamicIndex("gChipMainAttrCsv", function(t)
	for _, v in orderCsvPairs(csv.chip.main_attr) do
		t[v.seq] = t[v.seq] or {}
		t[v.seq][v.level] = v
	end
end)
_genGlobalDynamicIndex("gChipSuitCsv", function(t)
	for id, v in orderCsvPairs(csv.chip.suits) do
		t[v.suitID] = t[v.suitID] or {}
		t[v.suitID][v.suitQuality] = t[v.suitID][v.suitQuality] or {}
		t[v.suitID][v.suitQuality][v.suitNum] = v
	end
end)
_genGlobalDynamicIndex("gChipResonanceCsv", function(t)
	for id, v in orderCsvPairs(csv.chip.resonance) do
		t[v.type] = t[v.type] or {}
		t[v.type][v.groupID] = t[v.type][v.groupID] or {}

		tinsert(t[v.type][v.groupID], v)
	end

	for _type, groupData in pairs(t) do
		for _, data in pairs(groupData) do
			table.sort(data, function(v1, v2)
				return v1.priority > v2.priority
			end)
		end
	end
end)
_genGlobalDynamicIndex("gChipLevelSumExpCsv", function(t)
	for id, v in orderCsvPairs(csv.chip.strength_cost) do
		for i = 1, math.huge do
			local exp = v["levelExp" .. i]

			if exp then
				t[i] = t[i] or {
					[0] = 0
				}
				t[i][id] = t[i][id - 1] + exp
			else
				break
			end
		end
	end
end)
_genGlobalDynamicIndex("gGrowGuideCsv", function(t)
	for id, v in orderCsvPairs(csv.grow_guide) do
		if dataEasy.isInServer(v.feature) then
			tinsert(t, v)
		end
	end
end)
_genGlobalDynamicIndex("gControlPerType", function(t)
	for i, v in csvPairs(csv.base_attribute.controllbufftype) do
		if v.unlock then
			t[v.controllBuffType] = true
		end
	end
end)
_genGlobalDynamicIndex("gContractExpCsv", function(t)
	for k, v in orderCsvPairs(csv.items) do
		if v.specialArgsMap.contractExp then
			tinsert(t, v)
		end
	end
end)
_genGlobalDynamicIndex("gContractLevelAttrCsv", function(t)
	for k, v in orderCsvPairs(csv.contract.level_attr) do
		t[v.quality] = t[v.quality] or {}
		t[v.quality][v.level] = v
	end
end)
_genGlobalDynamicIndex("gContractAdvanceAttrCsv", function(t)
	for k, v in orderCsvPairs(csv.contract.advance_attr) do
		t[v.quality] = t[v.quality] or {}
		t[v.quality][v.advance] = v
	end
end)
_genGlobalDynamicIndex("gContractAdvanceCostCsv", function(t)
	for k, v in orderCsvPairs(csv.contract.advance_cost) do
		t[v.seq] = t[v.seq] or {}
		t[v.seq][v.advance] = v
	end
end)
_genGlobalDynamicIndex("gContractGroupCsv", function(t)
	for groupID, v in orderCsvPairs(csv.contract.group) do
		for _, itemID in pairs(v.items) do
			t[itemID] = groupID
		end
	end
end)
_genGlobalDynamicIndex("gContractPlanCsv", function(t)
	for _, v in orderCsvPairs(csv.contract.plan) do
		t[v.planID] = t[v.planID] or {}
		t[v.planID][v.fieldID] = v
	end
end)
_genGlobalDynamicIndex("gOnlineFightCards", function(t)
	for id, v in orderCsvPairs(csv.cross.online_fight.cards) do
		t[v.cardID] = v
	end
end)
_genGlobalDynamicIndex("gArmStage", function(t)
	for id, v in orderCsvPairs(csv.arms.stage) do
		t[v.armID] = t[v.armID] or {}
		t[v.armID][v.stage] = v
	end
end)
_genGlobalDynamicIndex("gAidLevelCsv", function(t)
	for id, v in orderCsvPairs(csv.aid.level) do
		t[v.level] = v or {}
	end
end)
_genGlobalDynamicIndex("gAidStageCsv", function(t)
	for id, v in orderCsvPairs(csv.aid.stage) do
		t[v.sequenceID] = t[v.sequenceID] or {}
		t[v.sequenceID][v.stage] = v
	end
end)
_genGlobalDynamicIndex("gAidAwakeCsv", function(t)
	for id, v in orderCsvPairs(csv.aid.awake) do
		t[v.sequenceID] = t[v.sequenceID] or {}
		t[v.sequenceID][v.level] = v
	end
end)

globals.gOnlineFightTalentAttrs = nil
globals.gOnlineFightTalentPositions = {
	[game.TALENT_TYPE.battleFront] = {},
	[game.TALENT_TYPE.battleBack] = {}
}
globals.gOnlineFightTalentNatures = {}

;(function(t)
	for _, v in pairs(game.NATURE_ENUM_TABLE) do
		t[v] = {}
	end
end)(globals.gOnlineFightTalentNatures)

function globals.initOnlineFightTalent(...)
	if gOnlineFightTalentAttrs ~= nil then
		return
	end

	globals.gOnlineFightTalentAttrs = {}

	for i, cfg in csvPairs(csv.cross.online_fight.talent) do
		local t

		if cfg.addType == game.TALENT_TYPE.battleFront then
			t = {
				gOnlineFightTalentPositions[game.TALENT_TYPE.battleFront]
			}
		elseif cfg.addType == game.TALENT_TYPE.battleBack then
			t = {
				gOnlineFightTalentPositions[game.TALENT_TYPE.battleBack]
			}
		elseif cfg.addType == game.TALENT_TYPE.cardsAll then
			t = gOnlineFightTalentNatures
		elseif cfg.addType == game.TALENT_TYPE.cardNatureType then
			t = {
				gOnlineFightTalentNatures[cfg.natureType]
			}
		else
			error("not support addType" .. cfg.addType)
		end

		local attr = cfg.attrType

		if gOnlineFightTalentAttrs[attr] == nil then
			gOnlineFightTalentAttrs[attr] = true
		end

		local num, numtype = dataEasy.parsePercentStr(cfg.attrNum)

		for _, v in pairs(t) do
			if v[attr] == nil then
				v[attr] = {
					0,
					0
				}
			end

			if numtype == game.NUM_TYPE.number then
				v[attr][1] = v[attr][1] + num
			else
				v[attr][2] = v[attr][2] + num
			end
		end
	end
end

globals.gShopType = {
	csv.fix_shop,
	csv.union.union_shop,
	csv.frag_shop,
	csv.pwshop,
	csv.explorer.explorer_shop,
	csv.random_tower.shop,
	csv.craft.shop,
	csv.equip_shop,
	csv.union_fight.shop,
	csv.cross.craft.shop,
	csv.cross.arena.shop,
	csv.fishing.shop,
	csv.cross.online_fight.shop,
	[15] = csv.cross.mine.shop,
	[16] = csv.cross.hunting.shop,
	[17] = csv.cross.supremacy.shop,
	-- [18] = csv.totem.shop,
	-- [19] = csv.auto_chess.shop,
	-- [20] = csv.signin_shop,
	-- [21] = csv.cross.union_adventure.shop
}

_genGlobalDynamicIndex("gShopGainMap", function(t)
	for idx, shop in pairs(gShopType) do
		if idx ~= 1 and idx ~= 3 then
			for _, v in orderCsvPairs(shop) do
				if v.itemMap then
					for k, _ in csvMapPairs(v.itemMap) do
						t[k] = true
					end
				end

				if v.itemWeightMap then
					for k, _ in csvMapPairs(v.itemWeightMap) do
						t[k] = true
					end
				end
			end
		end
	end
end)

local serverKeys = {}
local destServerKey = {}

for k, v in orderCsvPairs(csv.server.merge) do
	if destServerKey[v.destServer] then
		error(string.format("csv.server.merge: (%s) can't exist in (%d) and (%d) at the same time", v.destServer, destServerKey[v.destServer], k))
	end

	destServerKey[v.destServer] = k

	for _, key in ipairs(v.servers) do
		if serverKeys[key] then
			error(string.format("csv.server.merge: (%s) can't exist in (%d) and (%d) at the same time", key, serverKeys[key], k))
		end

		serverKeys[key] = k
	end
end

local function getDestServerID(id)
	local destServer = csv.server.merge[id].destServer
	local newId = serverKeys[destServer]

	if not newId then
		return id
	end

	return getDestServerID(newId)
end

local function getServers(tb, id)
	local cfg = csv.server.merge[id]
	local destServer = cfg.destServer

	if tb[destServer] then
		return tb[destServer].servers
	end

	local t = {}

	for _, key in ipairs(cfg.servers) do
		local mergeId = destServerKey[key]

		if mergeId then
			local servers = getServers(tb, mergeId)

			for _, server in ipairs(servers) do
				tinsert(t, server)
			end
		else
			tinsert(t, key)
		end
	end

	tb[destServer] = {
		servers = t,
		id = cfg.serverID
	}

	return t
end

_genGlobalDynamicIndex("gServersMergeID", function(t1)
	for k, v in orderCsvPairs(csv.server.merge) do
		local id = getDestServerID(k)

		for _, key in ipairs(v.servers) do
			if not destServerKey[key] then
				t1[key] = id
			end
		end
	end
end)
_genGlobalDynamicIndex("gDestServer", function(t2)
	for k, v in orderCsvPairs(csv.server.merge) do
		getServers(t2, k)
	end
end)
_genGlobalDynamicIndex("gZawakeLevelsCsv", function(t)
	for _, v in orderCsvPairs(csv.zawake.levels) do
		t[v.zawakeID] = t[v.zawakeID] or {}
		t[v.zawakeID][v.awakeSeqID] = t[v.zawakeID][v.awakeSeqID] or {}
		t[v.zawakeID][v.awakeSeqID][v.level] = v
	end
end)
_genGlobalDynamicIndex("gZawakeStagesCsv", function(t)
	for _, v in orderCsvPairs(csv.zawake.stages) do
		t[v.zawakeID] = t[v.zawakeID] or {}
		t[v.zawakeID][v.awakeSeqID] = v
	end
end)
_genGlobalDynamicIndex("gTownBuildingCsv", function(t)
	for _, v in orderCsvPairs(csv.town.building) do
		t[v.buildID] = t[v.buildID] or {}
		t[v.buildID][v.level] = v
	end
end)
_genGlobalDynamicIndex("gTownBuildingTypeCsv", function(t)
	for _, v in orderCsvPairs(csv.town.building) do
		t[v.buildType] = t[v.buildType] or {}
		t[v.buildType][v.buildID] = true
	end
end)
_genGlobalDynamicIndex("gTownRelicUpgradeCsv", function(t)
	for _, v in orderCsvPairs(csv.town.relic_upgrade_award) do
		t[v.relicID] = t[v.relicID] or {}
		t[v.relicID][v.level] = v
	end
end)
_genGlobalDynamicIndex("gHomeFurnitureOptCsv", function(t)
	for id, v in orderCsvPairs(csv.town.home_furniture) do
		local csvInfo = csv.town.home_furniture_type[v.type]

		if csvInfo then
			t[id] = csvInfo.frontType
		else
			t[id] = 0
		end
	end

	for id, v in orderCsvPairs(csv.town.home_demo_space) do
		local csvInfo = csv.town.home_furniture_type[v.type]

		if csvInfo then
			t[id] = csvInfo.frontType
		else
			t[id] = 0
		end
	end
end)
_genGlobalDynamicIndex("gTownFactoryCsv", function(t)
	for _, v in orderCsvPairs(csv.town.production_base) do
		t[v.baseID] = t[v.baseID] or {}
		t[v.baseID][v.level] = v
	end
end)
_genGlobalDynamicIndex("gMimicryBuffsCsv", function(t)
	for _, v in orderCsvPairs(csv.mimicry.buffs) do
		t[v.quality] = t[v.quality] or {}

		table.insert(t[v.quality], v.level)
	end

	for _, v in pairs(t) do
		table.sort(v, function(a, b)
			return b < a
		end)
	end
end)
_genGlobalDynamicIndex("gMedalCollectionCsv", function(t)
	for k, v in csvPairs(csv.medal) do
		t[v.medalID] = t[v.medalID] or {}
		t[v.medalID][v.sort] = v
	end
end)
_genGlobalDynamicIndex("gEffectOptionCsv", function(t)
	for k, v in csvPairs(csv.effect_option) do
		t[v.resPath] = v.tintBlack
	end
end)
_genGlobalDynamicIndex("gStandbyEffectOptionCsv", function(t)
	for k, v in csvPairs(csv.effect_option) do
		t[v.resPath] = v.standbyTinblack
	end
end)
-- _genGlobalDynamicIndex("gAutoChessKeyWordsCsv", function(t)
-- 	for k, v in csvPairs(csv.auto_chess.key_words) do
-- 		t[v.key] = v
-- 	end
-- end)
_genGlobalDynamicIndex("gSkillDescKeyWordsCsv", function(t)
	for k, v in csvPairs(csv.skill_desc_key_words) do
		t[v.key] = v
	end
end)
-- _genGlobalDynamicIndex("gTotemStarIdCsv", function(t)
-- 	for k, v in csvPairs(csv.totem.star) do
-- 		t[v.starSeqID] = t[v.starSeqID] or {}
-- 		t[v.starSeqID][v.starLevel] = v
-- 	end

-- 	for k, v in pairs(t) do
-- 		if itertools.size(v) == 0 then
-- 			error(string.format("symbol表中starSeqID的对应的star表星级未配置,starSeqID为%s", k))
-- 		end
-- 	end
-- end)
-- _genGlobalDynamicIndex("gAutoChessAchievementLevelCsv", function(t)
-- 	for k, v in csvPairs(csv.auto_chess.achievement_level) do
-- 		t[v.level] = v
-- 	end
-- end)

local function getAntiAndCsvByPath(path)
	local anti, config, lastName

	if type(path) == "table" then
		anti = gAntiCheat
		config = csv

		for _, n in ipairs(path) do
			anti = anti[n]
			config = config[n]
			lastName = n
		end
	else
		anti = gAntiCheat[path]
		config = csv[path]
		lastName = path
	end

	return anti, config, lastName
end

if false and not ANTI_AGENT then
	globals.gAntiCheat = {
		unit = {},
		buff = {},
		skill = {},
		skill_process = {},
		effect_event = {},
		base_attribute = {
			nature_matrix = {}
		}
	}

	local function record(path)
		local anti, config, lastName = getAntiAndCsvByPath(path)
		local t = {}

		for k, v in csvPairs(config) do
			t[k] = csvNumSum(v)
		end

		t.__default = csvNumSum(config.__default.__index)

		return table.salttable(t)
	end

	gAntiCheat.unit = record("unit")
	gAntiCheat.skill = record("skill")
	gAntiCheat.skill_process = record("skill_process")
	gAntiCheat.buff = record("buff")
	gAntiCheat.effect_event = record("effect_event")
	gAntiCheat.base_attribute.nature_matrix = record({
		"base_attribute",
		"nature_matrix"
	})

	printInfo("config_defines - anti cheat %f KB", collectgarbage("count"))
end

function globals.checkGGCheat()
	if ANTI_AGENT then
		return
	end

	for i, t in ipairs(_gg_) do
		local num = csvNumSum(t)
		local idx = t[#t]

		num = num - idx

		local antiCheatNum = _gg_cheat_[idx]

		if antiCheatNum == nil or math.abs(antiCheatNum - num) > 1e-05 then
			errorInWindows("checkGGCheat %d %s %s", i, antiCheatNum, num)
			exitApp("close your cheating software")
		end
	end

	checkSpecificCsvCheat("unit")
	checkSpecificCsvCheat("skill")
	checkSpecificCsvCheat("skill_process")
	checkSpecificCsvCheat("buff")
	checkSpecificCsvCheat("effect_event")
	checkSpecificCsvCheat({
		"base_attribute",
		"nature_matrix"
	})
end

function globals.checkSpecificCsvCheat(path, iter)
	do return end

	if ANTI_AGENT then
		return
	end

	local anti, config, lastName = getAntiAndCsvByPath(path)

	if iter == nil then
		iter = itertools.ikeys(csvPairs(config))
	end

	local num = csvNumSum(config.__default.__index)
	local antiCheatNum = anti.__default

	if math.abs(antiCheatNum - num) > 1e-05 then
		errorInWindows("checkSpecificCsvCheat %s default %s %s", lastName, antiCheatNum, num)
		exitApp("close your cheating software")
	end

	itertools.each(iter, function(_, k)
		local antiCheatNum = anti[k] or 0
		local num = csvNumSum(config[k]) or 0

		if math.abs(antiCheatNum - num) > 1e-05 then
			errorInWindows("checkSpecificCsvCheat %s %s %s %s", lastName, k, antiCheatNum, num)
			exitApp("close your cheating software")
		end
	end)
end

printInfo("config_defines - index and cache %f KB", collectgarbage("count"))
collectgarbage("collect")
printInfo("config_defines - after collect %f KB", collectgarbage("count"))

if device.platform == "windows" then
	for cardId, _ in pairs(gHandbookCsv) do
		if not csv.cards[cardId] then
			-- error(string.format("图鉴中有%d, 但cards表未开放", cardId))

			break
		end
	end

	local itemTable = csv.items
	local unitTable = csv.unit

	for k, v in orderCsvPairs(csv.cards) do
		local feelType = v.feelType

		if feelType <= 3 then
			if itertools.include(v.feelItems, 604) or itertools.include(v.feelItems, 605) then
				error(string.format("csv.cards[%d].feelItems 好感度道具有不合法的配置, 品质不对应", k))
			end
		elseif itertools.include(v.feelItems, 601) or itertools.include(v.feelItems, 602) or itertools.include(v.feelItems, 603) then
			error(string.format("csv.cards[%d].feelItems 好感度道具有不合法的配置, 品质不对应", k))
		end

		if LOCAL_LANGUAGE == "cn" then
			for skinID, skills in orderCsvPairs(v) do
				if not csv.card_skin[skinID] then
					error(string.format("csv.cards id(%s), field skinSkillMap, not exist csv.card_skin id(%s)", k, skinID))
				end
			end
		end
	end
end
