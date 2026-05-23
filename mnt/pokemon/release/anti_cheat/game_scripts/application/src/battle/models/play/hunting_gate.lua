-- chunkname: @src.battle.models.play.hunting_gate

local HuntingGate = class("HuntingGate", battlePlay.Gate)

battlePlay.HuntingGate = HuntingGate
HuntingGate.OperatorArgs = {
	canSkip = true,
	canSpeedAni = true,
	canPause = true,
	canHandle = true,
	isFullManual = false,
	isAuto = false
}
HuntingGate.SpecEndRuleCheck = {
	battle.EndSpecialCheck.EnemyOnlySummonOrAllDead
}

local function getForceKey(obj)
	return obj.dbID
end

function HuntingGate:newWaveAddObjsStrategy()
	local routeInfo = self.data.gamemodel_data and self.data.gamemodel_data.route_info or {}
	local buffs = routeInfo.buffs
	local roleOut = self.data.roleOut
	local skill_open = {}

	for _, buffId in pairs(buffs) do
		local buffCfg = csv.cross.hunting.buffs[buffId]

		skill_open[buffCfg.skillID] = 1
	end

	for i = 1, 6 do
		local role = roleOut[i]

		if role then
			role.passive_skills = role.passive_skills or {}

			for skillId, skillLevel in pairs(skill_open) do
				role.passive_skills[skillId] = skillLevel
			end
		end
	end

	self:waveAddCardRoles(1, nil, roleOut)
	self:waveAddCardRoles(2)
	self:doObjsAttrsCorrect(true, true)
	battlePlay.Gate.newWaveAddObjsStrategy(self)
	self:setCardStates()
end

function HuntingGate:setCardStates()
	local gateStates = {
		{},
		{}
	}
	local routeInfo = self.data.gamemodel_data and self.data.gamemodel_data.route_info or {}

	local function setStates(idlerName, map, gateState)
		local states = routeInfo[idlerName] or {}

		for id, obj in map:pairs() do
			if self:checkObjCanToServer(obj) then
				local idx = getForceKey(obj)
				local state = states[tonumber(idx)] or states[tostring(idx)]

				if state then
					local maxHp, maxMp = obj:hpMax(), obj:mp1Max()

					obj:correctHp(maxHp * state[1])
					obj:setMP1(maxMp * state[2])
				end

				gateState[idx] = {
					0,
					0
				}
			end
		end
	end

	setStates("enemy_states", self.scene:getHerosMap(2), gateStates[2])
	setStates("card_states", self.scene:getHerosMap(1), gateStates[1])

	self.gateStates = gateStates
end

function HuntingGate:getForceState(force)
	local map = self.scene:getHerosMap(force)
	local states = self.gateStates[force]

	for id, obj in map:pairs() do
		if self:checkObjCanToServer(obj) then
			states[getForceKey(obj)] = {
				obj:hp() / obj:hpMax(),
				obj:mp1() / obj:mp1Max()
			}
		end
	end

	return states
end

function HuntingGate:needExtraRound()
	if self.curRound > self.roundLimit then
		return false
	end

	for _, obj in self.scene:ipairsHeros() do
		if obj:isFakeDeath() then
			return true
		end
	end

	return false
end

function HuntingGate:checkBattleEnd()
	if self:checkBothAllRealDead() then
		return true, "win"
	end

	if self:needExtraRound() then
		return false
	end

	return battlePlay.Gate.checkBattleEnd(self)
end

function HuntingGate:postEndResultToServer(cb)
	local cardStates = self:getForceState(1)
	local enemyStates = self:getForceState(2)
	local endInfos = self:makeEndViewInfos({
		gateStar = true
	})
	local tb = self.scene.extraRecord:getEvent(battle.ExRecordEvent.campDamage)
	local totalDamage = tb and tb[1]

	gRootViewProxy:raw():postEndResultToServer("/game/hunting/battle/end", function(tb)
		local view = tb.view or {}

		if next(view) then
			endInfos.cardStates = cardStates
			endInfos.enemyStates = enemyStates

			cb(endInfos, view)
		else
			gGameUI:cleanStash()
			gGameUI:switchUI("city.view")
			gGameUI:showTip(gLanguageCsv.randomTimeOver)
		end
	end, self.scene.battleID, self.result, cardStates, enemyStates, totalDamage)
end
