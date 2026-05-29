-- chunkname: @src.app.models.battle

local function card2RoleOut(t, cardAttrs, cardStates, roleForce)
	local dbID, cardID, skinID

	if type(t) == "table" then
		dbID, cardID, skinID = unpack(t, 1, 3)
	else
		dbID = t
	end

	if dbID == nil or dbID == 0 or dbID == "" then
		return nil
	end

	local card = cardAttrs[dbID]

	cardID, skinID = card.card_id, card.skin_id

	local state = cardStates[dbID]
	local unitID = 0

	if card.unit_id and card.unit_id ~= 0 then
		unitID = card.unit_id
	else
		unitID = csv.cards[cardID].unitID

		if skinID and skinID ~= 0 then
			unitID = csv.card_skin[skinID].unitIDs[cardID]
		end
	end

	local roleOut = {
		roleForce = roleForce,
		roleId = unitID,
		cardId = dbID,
		cardCsvId = cardID,
		fightPoint = card.fighting_point,
		level = card.level,
		advance = card.advance,
		skills = card.skills,
		star = card.star,
		starEffect = card.star_effect,
		passive_skills = card.passive_skills or {},
		hpScale = state and state[1] or 1,
		mp1Scale = state and state[2] or 1
	}

	for k, v in pairs(card.attrs) do
		roleOut[k] = v
	end

	if card.attrs2 then
		for k, v in pairs(card.attrs2) do
			roleOut[k] = v
		end
	end

	if card.aid then
		for k, v in pairs(card.aid) do
			roleOut[k] = v
		end
	end

	return roleOut
end

local function card2AidRoleOut(t, cardAttrs, cardStates, roleForce)
	local roleOut = card2RoleOut(t, cardAttrs, cardStates, roleForce)

	if not roleOut then
		return nil
	end

	local dbID, cardID, skinID

	if type(t) == "table" then
		dbID, cardID, skinID = unpack(t, 1, 3)
	else
		dbID = t
	end

	local card = cardAttrs[dbID]

	cardID, skinID = card.card_id, card.skin_id

	local aidID = csv.cards[cardID].aidID
	local unitID = roleOut.roleId

	if skinID and skinID ~= 0 and not csv.aid.aid_skill[aidID].skin2SkillID[unitID] then
		unitID = csv.cards[cardID].unitID
	end

	roleOut.roleId = unitID

	return roleOut
end

local GameBattleModel = class("GameBattleModel")

GameBattleModel.card2RoleOut = card2RoleOut
GameBattleModel.card2AidRoleOut = card2AidRoleOut

function GameBattleModel:ctor(game)
	self.game = game
	self.operateForceSwitch = false
end

function GameBattleModel:init(tb)
	for k, v in pairs(tb) do
		self[k] = v
	end

	self:dealModelMuti()

	self._isMultipGroup = nil

	assert(self.level ~= nil, "level is required")
	assert(self.cards ~= nil, "cards is required")
	self:recordCheat(tb)

	return self
end

function GameBattleModel:dealModelMuti()
	local dealKeys = {
		"cards",
		"defence_cards",
		"actions"
	}

	for _, key in pairs(dealKeys) do
		local keyMulti = key .. "_multi"

		if self[keyMulti] ~= nil and #self[keyMulti] > 0 then
			self[key] = self[keyMulti]
			self[keyMulti] = nil
		end
	end
end

function GameBattleModel:sceneConf(sceneID)
	return csv.scene_conf[sceneID]
end

function GameBattleModel:getRoleOut()
	if self:isMultipGroup() then
		return self:getGroupRoleOut()
	end

	local roleOut = {}
	local idx = 1

	for i, t in maptools.order_pairs(self.cards) do
		local pos = self.OmitEmpty and idx or i

		roleOut[pos] = card2RoleOut(t, self.card_attrs, self.card_states or {}, 1)
		idx = idx + 1
	end

	if self.defence_cards then
		local idx = 1

		for i, t in maptools.order_pairs(self.defence_cards) do
			local pos = self.OmitEmpty and idx or i

			roleOut[6 + pos] = card2RoleOut(t, self.defence_card_attrs, self.defence_card_states or {}, 2)
			idx = idx + 1
		end
	end

	return roleOut
end

function GameBattleModel:getGroupRoleOut()
	local groupRoleOut = {
		{},
		{}
	}

	for group, cards in ipairs(self.cards) do
		groupRoleOut[1][group] = groupRoleOut[1][group] or {}

		local idx = 1

		for i, t in maptools.order_pairs(cards) do
			local pos = self.OmitEmpty and idx or i

			groupRoleOut[1][group][pos] = card2RoleOut(t, self.card_attrs, self.card_states or {}, 1)
			idx = idx + 1
		end
	end

	if self.defence_cards then
		for group, cards in ipairs(self.defence_cards) do
			groupRoleOut[2][group] = groupRoleOut[2][group] or {}

			local idx = 1

			for i, t in maptools.order_pairs(cards) do
				local pos = self.OmitEmpty and idx or i

				groupRoleOut[2][group][6 + pos] = card2RoleOut(t, self.defence_card_attrs, self.defence_card_states or {}, 2)
				idx = idx + 1
			end
		end
	end

	return groupRoleOut
end

local function fillAidRoleOut(roleOut, force, wave, pos, packArgs)
	if not roleOut[force] then
		roleOut[force] = {}
	end

	if not roleOut[force][wave] then
		roleOut[force][wave] = {}
	end

	local card_data = packArgs[1]
	local card_attrs = packArgs[2]
	local card_states = packArgs[3] or {}

	roleOut[force][wave][pos] = card2AidRoleOut(card_data, card_attrs, card_states, force)
end

function GameBattleModel:get_embattle_info()
	return {
		aid_cards = self.aid_cards,
		card_states = self.card_states,
		defence_aid_cards = self.defence_aid_cards,
		defence_card_states = self.defence_card_states
	}
end

function GameBattleModel:getAidRoleOut()
	if self:isMultipGroup() then
		return self:getGroupAidRoleOut()
	end

	local aidRoleOut = {
		{},
		{}
	}

	if self:get_embattle_info().aid_cards then
		local idx = 1

		for i, t in maptools.order_pairs(self:get_embattle_info().aid_cards) do
			local pos = self.OmitEmpty and idx or i

			fillAidRoleOut(aidRoleOut, 1, 1, pos, {
				t,
				self.card_attrs,
				self:get_embattle_info().card_states
			})

			idx = idx + 1
		end
	end

	if self:get_embattle_info().defence_aid_cards then
		local idx = 1

		for i, t in maptools.order_pairs(self:get_embattle_info().defence_aid_cards) do
			local pos = self.OmitEmpty and idx or i

			fillAidRoleOut(aidRoleOut, 2, 1, 6 + pos, {
				t,
				self.defence_card_attrs,
				self:get_embattle_info().defence_card_states
			})

			idx = idx + 1
		end
	end

	return aidRoleOut
end

function GameBattleModel:getGroupAidRoleOut()
	local groupRoleOut = {
		{},
		{}
	}

	if self:get_embattle_info().aid_cards then
		for group, cards in ipairs(self:get_embattle_info().aid_cards) do
			groupRoleOut[1][group] = groupRoleOut[1][group] or {}

			local idx = 1

			for i, t in maptools.order_pairs(cards) do
				local pos = self.OmitEmpty and idx or i

				fillAidRoleOut(groupRoleOut, 1, group, pos, {
					t,
					self.card_attrs,
					self:get_embattle_info().card_states
				})

				idx = idx + 1
			end
		end
	end

	if self:get_embattle_info().defence_aid_cards then
		for group, cards in ipairs(self:get_embattle_info().defence_aid_cards) do
			groupRoleOut[2][group] = groupRoleOut[2][group] or {}

			local idx = 1

			for i, t in maptools.order_pairs(cards) do
				local pos = self.OmitEmpty and idx or i

				fillAidRoleOut(groupRoleOut, 2, group, 6 + pos, {
					t,
					self.defence_card_attrs,
					self:get_embattle_info().defence_card_states
				})

				idx = idx + 1
			end
		end
	end

	return groupRoleOut
end

local function getDBId(t)
	local dbID = t

	if type(t) == "table" then
		dbID = t[1]
	end

	return t
end

function GameBattleModel:getRoleOut2()
	if self:isMultipGroup() then
		return self:getGroupRoleOut2()
	end

	local roleOut = {}
	local idx = 1

	if self.card_attrs2 then
		for i, t in maptools.order_pairs(self.cards) do
			if self.card_attrs2[getDBId(t)] then
				local pos = self.OmitEmpty and idx or i

				roleOut[pos] = card2RoleOut(t, self.card_attrs2, self.card_states or {}, 1)
			end

			idx = idx + 1
		end
	end

	if self.defence_card_attrs2 and self.defence_cards then
		local idx = 1

		for i, t in maptools.order_pairs(self.defence_cards) do
			if self.defence_card_attrs2[getDBId(t)] then
				local pos = self.OmitEmpty and idx or i

				roleOut[6 + pos] = card2RoleOut(t, self.defence_card_attrs2, self.defence_card_states or {}, 2)
			end

			idx = idx + 1
		end
	end

	return roleOut
end

function GameBattleModel:getGroupRoleOut2()
	local groupRoleOut = {
		{},
		{}
	}

	if self.card_attrs2 then
		for group, cards in ipairs(self.cards) do
			groupRoleOut[1][group] = groupRoleOut[1][group] or {}

			local idx = 1

			for i, t in maptools.order_pairs(cards) do
				if self.card_attrs2[getDBId(t)] then
					local pos = self.OmitEmpty and idx or i

					groupRoleOut[1][group][pos] = card2RoleOut(t, self.card_attrs2, self.card_states or {}, 1)
				end

				idx = idx + 1
			end
		end
	end

	if self.defence_card_attrs2 and self.defence_cards then
		for group, cards in ipairs(self.defence_cards) do
			groupRoleOut[2][group] = groupRoleOut[2][group] or {}

			local idx = 1

			for i, t in maptools.order_pairs(cards) do
				if self.defence_card_attrs2[getDBId(t)] then
					local pos = self.OmitEmpty and idx or i

					groupRoleOut[2][group][6 + pos] = card2RoleOut(t, self.defence_card_attrs2, self.defence_card_states or {}, 2)
				end

				idx = idx + 1
			end
		end
	end

	return groupRoleOut
end

function GameBattleModel:getExtraOut()
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

function GameBattleModel:getGroupExtraOut()
	local groupExtraOut = {
		{},
		{}
	}

	if self.extra then
		groupExtraOut[1] = self.extra
	end

	if self.defence_extra then
		groupExtraOut[2] = self.defence_extra
	end

	return groupExtraOut
end

local swapKeysTb = {
	"levels",
	"names",
	"figures",
	"logos"
}

function GameBattleModel:isMultipGroup()
	if self._isMultipGroup == nil then
		local sceneID = self.gate_id or self.DefaultGateID
		local sceneConf = self:sceneConf(sceneID)

		self._isMultipGroup = sceneConf.deployType == game.DEPLOY_TYPE.MultTwo or sceneConf.deployType == game.DEPLOY_TYPE.MultThree
	end

	return self._isMultipGroup or self.MultipGroup
end

function GameBattleModel:getData()
	local sceneID = self.gate_id or self.DefaultGateID
	local sceneConf = self:sceneConf(sceneID)
	local roleOut = self:getRoleOut()
	local roleOut2 = self:getRoleOut2()
	local aidRoleOut = self:getAidRoleOut()
	local role_db_id = self.role_db_id or self.role_key and self.role_key[2]
	local defence_role_db_id = self.defence_role_db_id or self.defence_role_key and self.defence_role_key[2]
	local extraOut = self:getExtraOut()
	local result = self.result

	if result and result == "" then
		result = nil
	end

	local datas = {
		battleID = self.id,
		sceneID = sceneID,
		roleOut = roleOut,
		roleOut2 = roleOut2,
		aidRoleOut = aidRoleOut,
		randSeed = self.rand_seed,
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
		preData = self:getPreDataForEnd(roleOut),
		multipGroup = self:isMultipGroup(),
		operateForce = gGameModel.role:read("id") == defence_role_db_id and 2 or 1,
		result = result,
		play_record_id = self.play_record_id,
		cross_key = self.cross_key,
		record_url = self.record_url,
		extraOut = extraOut
	}

	if not self.operateForceSwitch then
		datas.operateForce = 1
	end

	if datas.operateForce == 2 then
		for _, key in ipairs(swapKeysTb) do
			table.swapvalue(datas[key], 1, 2)
		end
	end

	if device.platform == "windows" then
		self:display(roleOut, roleOut2)
	end

	datas.top_cards_data = self:getTopCardsData()

	return datas
end

function GameBattleModel:getTopCardsData()
	local topCardsData = {}
	local topCards = gGameModel.role:read("top_cards") or {}

	topCardsData.top_cards = topCards
	topCardsData.card_attrs = {}

	for k, dbid in ipairs(topCards) do
		local card = gGameModel.cards:find(dbid)

		topCardsData.card_attrs[dbid] = card:read("attrs")
	end

	return topCardsData
end

function GameBattleModel:getPreDataForEnd(roleOut)
	local ret = {}
	local cardsInfo = {}

	if self:isMultipGroup() then
		local force = 1
		local groupRoleData = roleOut[force]

		for group, cards in ipairs(groupRoleData) do
			for id = 1, 6 do
				local roleData = cards[id]

				if roleData then
					table.insert(cardsInfo, {
						id = id,
						team = group,
						unitId = roleData.roleId,
						level = roleData.level,
						advance = roleData.advance,
						star = roleData.star,
						rarity = csv.unit[roleData.roleId].rarity,
						cardId = roleData.cardId
					})
				end
			end
		end
	else
		for id = 1, 6 do
			local roleData = roleOut[id]

			if roleData then
				table.insert(cardsInfo, {
					id = id,
					unitId = roleData.roleId,
					level = roleData.level,
					advance = roleData.advance,
					star = roleData.star,
					rarity = csv.unit[roleData.roleId].rarity,
					cardId = roleData.cardId
				})
			end
		end
	end

	ret.cardsInfo = cardsInfo
	ret.drop = self.drop
	ret.roleInfo = {
		level = gGameModel.role:read("level"),
		level_exp = gGameModel.role:read("level_exp"),
		sum_exp = gGameModel.role:read("sum_exp")
	}

	local gateStar = gGameModel.role:read("gate_star")[self.gate_id]

	ret.dungeonStar = gateStar and gateStar.star or 0

	return ret
end

function GameBattleModel:recordCheat(tb)
	if ANTI_AGENT then
		return
	end

	tb = clone(tb)
	self.cheat = {
		tb = tb,
		sum = csvNumSum(tb)
	}
end

function GameBattleModel:checkCheat()
	if ANTI_AGENT then
		return
	end

	local antiCheatNum = self.cheat.sum
	local num = csvNumSum(self.cheat.tb)

	if math.abs(antiCheatNum - num) > 1e-05 then
		errorInWindows("checkCheat %s %s %s", tostring(self), antiCheatNum, num)
		exitApp("close your cheating software")
	end
end

function GameBattleModel:display(roleOut, roleOut2)
	if self:isMultipGroup() == nil then
		local attrs = {
			{
				"hp",
				"生命"
			},
			{
				"speed",
				"速度"
			},
			{
				"damage",
				"物攻"
			},
			{
				"defence",
				"物防"
			},
			{
				"specialDamage",
				"特攻"
			},
			{
				"specialDefence",
				"特防"
			}
		}
		local t = {
			"名字"
		}

		for i = 1, 12 do
			local card = roleOut[i]

			if card ~= nil then
				table.insert(t, "" .. i .. "-" .. csv.unit[card.roleId].name .. "-" .. card.roleId)
			else
				table.insert(t, "")
			end
		end

		print(table.concat(t, "\t"))
		print("第一套属性")

		for _, v in ipairs(attrs) do
			local t = {
				v[2]
			}

			for i = 1, 12 do
				local card = roleOut[i]

				if card ~= nil then
					table.insert(t, card[v[1]])
				else
					table.insert(t, "")
				end
			end

			print(table.concat(t, "\t"))
		end

		print("第二套属性")

		for _, v in ipairs(attrs) do
			local t = {
				v[2]
			}

			for i = 1, 12 do
				local card = roleOut2[i]

				if card ~= nil then
					table.insert(t, card[v[1]])
				else
					table.insert(t, "")
				end
			end

			print(table.concat(t, "\t"))
		end
	end
end

return GameBattleModel
