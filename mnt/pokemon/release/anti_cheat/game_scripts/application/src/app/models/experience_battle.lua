-- chunkname: @src.app.models.experience_battle

local GameBattleModel = require("app.models.battle")
local ExperienceBattle = class("ExperienceBattle", GameBattleModel)

function ExperienceBattle:init(tb)
	for k, v in pairs(tb) do
		self[k] = v
	end

	self.name = gGameModel.role:read("name")
	self.logo = gGameModel.role:read("logo")
	self.figure = gGameModel.role:read("figure")
	self.role_db_id = gGameModel.role:read("id")
	self.level = gGameModel.role:read("level")

	assert(self.level ~= nil, "level is required")
	assert(self.cards ~= nil, "cards is required")

	local trialCardData = csv.experience.cards[self.experienceCard.dbID]

	self.trialData = csv.experience.list[trialCardData.cardID]
	self.enemy_cards = self:makeEnemyCards()
	self.enemy_weather = self:makeEnemyWeather()

	self:makeWeatherData()
	self:recordCheat(tb)

	return self
end

function ExperienceBattle:makeWeatherData()
	if self.weahter then
		self.extra = {
			weather = self.weahter
		}
	end

	if self.enemy_weather then
		self.defence_extra = {
			weather = self.enemy_weather
		}
	end
end

function ExperienceBattle:makeEnemyCards()
	local trialData = self.trialData

	for _, id in ipairs(trialData.enemyRandomCards) do
		assert(csv.experience.cards[id] ~= nil, "enmey card not in cards csv")
	end

	local seatUnlocked = {}

	for i, lock in ipairs(trialData.enemydeployLock) do
		if lock == 0 then
			table.insert(seatUnlocked, 6 + i)
		end
	end

	local randomResult = random.sample(trialData.enemyRandomCards, table.length(seatUnlocked))
	local enemy_cards = {}

	for i, seat in ipairs(seatUnlocked) do
		enemy_cards[seat] = randomResult[i]
	end

	return enemy_cards
end

function ExperienceBattle:makeEnemyWeather()
	local cardsData = {}

	for _, csvID in pairs(self.enemy_cards) do
		local csvCard = csv.experience.cards[csvID]
		local cardInfo = csv.cards[csvCard.cardID]
		local csvUnit = csv.unit[cardInfo.unitID]
		local data = {
			csvID = csvID,
			cardID = csvCard.cardID,
			unitID = cardInfo.unitID,
			star = csvCard.star,
			attr1 = csvUnit.natureType,
			attr2 = csvUnit.natureType2
		}

		table.insert(cardsData, data)
	end

	local weathers = dataEasy.getTeamWeather(nil, true, {
		isTestPlay = true,
		cardsData = cardsData
	})

	if table.length(weathers) > 0 then
		return weathers[1].weatherID
	else
		return nil
	end
end

function ExperienceBattle:makeNetData()
	local allCards = table.deepcopy(self.cards, true)

	maptools.union_with(allCards, self.enemy_cards)

	local ret = {}
	local csvCards = csv.experience.cards

	for _, id in pairs(allCards) do
		if csvCards[id].cardID == self.experienceCard.cardID and self.skinID ~= nil then
			ret[csvCards[id].cardID] = self.skinID
		else
			ret[csvCards[id].cardID] = 0
		end
	end

	local weathers = {}

	if self.weahter then
		table.insert(weathers, self.weahter)
	end

	if self.enemy_weather then
		table.insert(weathers, self.enemy_weather)
	end

	if table.length(weathers) == 0 then
		weathers = nil
	end

	local passiveSkills = self.trialData.passiveSkillList

	if table.length(passiveSkills) == 0 then
		passiveSkills = nil
	end

	return ret, weathers, passiveSkills
end

function ExperienceBattle:setActualData(ret)
	self.skill_process = ret.view.skill_process
end

local fakePassiveSkillVals = {
	[7630] = 1,
	[7633] = 3,
	[7634] = 10,
	[7635] = 99,
	[90000001] = 1,
	[7632] = 2
}

function ExperienceBattle:card2RoleOut(cardCsvID, cardAttrs, roleForce)
	local dbID = cardCsvID
	local cardBaseData = csv.experience.cards[cardCsvID]
	local unitID = csv.cards[cardBaseData.cardID].unitID
	local skills = {}
	local cardData = csv.cards[cardBaseData.cardID]

	if dbID == self.experienceCard.dbID and self.experienceCard.skinID ~= nil then
		unitID = dataEasy.getUnitId(self.experienceCard.cardID, self.experienceCard.skinID)

		for _, skillID in ipairs(cardData.skinSkillMap[self.experienceCard.skinID]) do
			skills[skillID] = cardBaseData.level
		end
	else
		for _, skillID in ipairs(cardData.skillList) do
			skills[skillID] = cardBaseData.level
		end
	end

	local passive_skills = table.deepcopy(fakePassiveSkillVals)

	if roleForce == 1 then
		for _, skillID in ipairs(self.trialData.passiveSkillList) do
			passive_skills[skillID] = cardBaseData.level
		end
	end

	local roleOut = {
		hpScale = 1,
		mp1Scale = 1,
		fightPoint = 0,
		roleForce = roleForce,
		roleId = unitID,
		cardId = dbID,
		cardCsvId = cardBaseData.cardID,
		level = cardBaseData.level,
		advance = cardBaseData.advance,
		star = cardBaseData.star,
		skills = skills,
		passive_skills = passive_skills
	}

	for attr, _ in pairs(game.ATTRDEF_ENUM_TABLE) do
		if cardBaseData[attr] then
			roleOut[attr] = cardBaseData[attr]
		end
	end

	return roleOut
end

function ExperienceBattle:getRoleOut()
	local roleOut = {}
	local idx = 1

	for i, cardCsvID in maptools.order_pairs(self.cards) do
		local pos = self.OmitEmpty and idx or i

		roleOut[pos] = self:card2RoleOut(cardCsvID, {}, 1)
		idx = idx + 1
	end

	idx = 1

	for i, cardCsvID in maptools.order_pairs(self.enemy_cards) do
		local pos = self.OmitEmpty and idx or i

		roleOut[pos] = self:card2RoleOut(cardCsvID, {}, 2)
		idx = idx + 1
	end

	return roleOut
end

function ExperienceBattle:getExtraOut()
	if self:isMultipGroup() then
		return self:getGroupExtraOut()
	end

	local extraOut = {}

	if self.extra then
		extraOut[1] = self.extra
	end

	if self.defence_extra then
		extraOut[2] = self.defence_extra
	end

	return extraOut
end

function ExperienceBattle:sceneConf(sceneID)
	return csv.scene_conf[game.GATE_TYPE.experience]
end

function ExperienceBattle:getData()
	local sceneID = game.GATE_TYPE.experience
	local role_db_id = self.role_db_id or self.role_key and self.role_key[2]

	self.defence_role_db_id = 99999999

	local defence_role_db_id = self.defence_role_db_id or self.defence_role_key and self.defence_role_key[2]
	local sceneConf = self:sceneConf(sceneID)
	local roleOut = self:getRoleOut()
	local extraOut = self:getExtraOut()
	local result = self.result

	if result and result == "" then
		result = nil
	end

	local datas = {
		operateForce = 1,
		sceneID = sceneID,
		trialID = self.experienceCard.dbID,
		roleOut = roleOut,
		randSeed = math.random(1, 99999999),
		gateType = sceneConf.gateType,
		sceneTag = sceneConf.tag,
		names = {
			self.name,
			self.defence_name
		},
		levels = {
			self.level,
			self.defence_level
		},
		logos = {
			self.logo,
			self.defence_logo
		},
		figures = {
			self.figure,
			self.defence_figure
		},
		passive_skills = {
			self.passive_skills,
			self.defence_passive_skills
		},
		skill_process = self.skill_process,
		role_db_ids = {
			role_db_id,
			defence_role_db_id
		},
		preData = {},
		result = result,
		extraOut = extraOut,
		backUIData = {
			cards = self.cards,
			trialID = self.experienceCard.dbID
		}
	}

	if device.platform == "windows" then
		self:display(roleOut, {})
	end

	return datas
end

return ExperienceBattle
