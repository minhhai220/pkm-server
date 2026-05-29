local ModuleBase = class("ModuleBase")

function ModuleBase:init()
	errorInWindows("ModuleBase:init() error")
end

local UIModule = class("UIModule", ModuleBase)

function UIModule:init()
	self._control = {}
end

function UIModule:initCrossArena()
	self._control._showTeamWave = true
	self._control._showEnemyTeam = true

	self:initTeamUI()
end

function UIModule:initCrossMine()
	self._control._showTeamWave = true
	self._control._multTeams = true
	self._control._showEnemyTeam = true

	self:initTeamUI(game.DEPLOY_TYPE.MultThree)
end

function UIModule:initMultipGroupPVE(deployType)
	self._control._showTeamGroup = true
	self._control._multTeams = true

	self:initTeamUI(deployType)
end

function UIModule:initGymWheel()
	self._control._showTeamWave = true

	self:initTeamUI()
end

function UIModule:initCarft()
	self._control._refreshUIHp = true
	self._control._refreshUIMp = true
	self._control._newWaveAddObjsStrategy = true

	gRootViewProxy:proxy():addSpecModule(battleModule.craftMods)
end

function UIModule:initGymOneByOne()
	self._control._refreshUIHp = true
	self._control._refreshUIMp = true
	self._control._newWaveAddObjsStrategyGym = true

	gRootViewProxy:proxy():addSpecModule(battleModule.gymMods)
end

function UIModule:initCrossCircus(deployType)
	if deployType == game.DEPLOY_TYPE.MultTwo or deployType == game.DEPLOY_TYPE.MultThree then
		self._control._showTeamGroup = true
		self._control._showEnemyTeam = true
		self._control._multTeams = true

		self:initTeamUI(deployType)
	end

	gRootViewProxy:proxy():addSpecModule(battleModule.crossCircusMods)
end

function UIModule:newWaveAddObjsStrategy(inputBB)
	if self._control._newWaveAddObjsStrategy then
		if inputBB.gate.curWave == 1 then
			battleEasy.deferNotify(nil, "initPvp")
		end

		inputBB.gate:refreshUIHp()
		inputBB.gate:refreshUIMp()
	elseif self._control._newWaveAddObjsStrategyGym then
		if inputBB.gate.curWave == 1 then
			battleEasy.deferNotify(nil, "initPvp")
		elseif inputBB.gate.waveResultList then
			battleEasy.deferNotify(nil, "changeWave", inputBB.gate.waveResultList[inputBB.gate.curWave - 1])
		else
			battleEasy.deferNotify(nil, "changeWave", inputBB.gate.waveResultHistory[inputBB.gate.curWave - 1])
		end

		inputBB.gate:refreshUIHp()
		inputBB.gate:refreshUIMp()
	end

	if self._control._showTeamWave then
		if self._control._multTeams then
			local totalNum = table.length(inputBB.waveResultHistory)
			local preWin = inputBB.waveResult == battle.Const.Win and 1 or 2

			gRootViewProxy:notify("changeTeam", totalNum, preWin, self._control._showEnemyTeam)
		else
			local lef, rig

			if inputBB.gate.waveInit.endType then
				lef, rig = inputBB.gate:getWaveInfo(1).waveIndex, inputBB.gate:getWaveInfo(2).waveIndex
			else
				lef, rig = 1, 1

				for _, result in ipairs(inputBB.waveResultHistory) do
					if result == battle.Const.Win or result == battle.Const.Draw then
						rig = rig + 1
					end

					if result == battle.Const.Fail or result == battle.Const.Draw then
						lef = lef + 1
					end
				end
			end

			gRootViewProxy:notify("setTeamNumber", lef, self._control._showEnemyTeam and rig)
		end
	end
end

function UIModule:initTeamUI(deployType)
	local deployNum

	if deployType == game.DEPLOY_TYPE.MultTwo then
		deployNum = 2
	elseif deployType == game.DEPLOY_TYPE.MultThree then
		deployNum = 3
	end

	gRootViewProxy:call("initTeamUI", {
		showMultTeams = self._control._multTeams and deployNum,
		showEnemyTeam = self._control._showEnemyTeam
	})
end

function UIModule:onGroupRoundStart(inputBB)
	if self._control._showTeamGroup and self._control._multTeams then
		local totalNum = inputBB.groupRound - 1
		local preWin = inputBB.groupResult == battle.Const.Win and 1 or 2

		gRootViewProxy:notify("changeTeam", totalNum, preWin, self._control._showEnemyTeam)
	end
end

function UIModule:refreshUIHp(inputBB)
	if self._control._refreshUIHp then
		local selfHpRatio, enemyHpRatio = -1, -1
		local me, enemy

		for _, obj in inputBB.gate.scene:ipairsHeros() do
			if obj.force == 1 then
				me = obj
			else
				enemy = obj
			end
		end

		if me then
			selfHpRatio = me:hp() / me:hpMax()
		end

		if enemy then
			enemyHpRatio = enemy:hp() / enemy:hpMax()
		end

		battleEasy.deferNotify(nil, "changeHpMp", {
			selfHpRatio = selfHpRatio,
			enemyHpRatio = enemyHpRatio
		})
	end
end

function UIModule:refreshUIMp(inputBB)
	if self._control._refreshUIMp then
		local selfMpRatio, enemyMpRatio = -1, -1
		local me, enemy

		for _, obj in inputBB.gate.scene:ipairsHeros() do
			if obj.force == 1 then
				me = obj
			else
				enemy = obj
			end
		end

		if me then
			selfMpRatio = me:mp1() / me:mp1Max()
		end

		if enemy then
			enemyMpRatio = enemy:mp1() / enemy:mp1Max()
		end

		battleEasy.deferNotify(nil, "changeHpMp", {
			selfMpRatio = selfMpRatio,
			enemyMpRatio = enemyMpRatio
		})
	end
end

local StarModule = class("StarModule", ModuleBase)
local StarConditionCheckTb = {
	function(gate, params, inputBB)
		local c = inputBB.result == battle.Const.Win

		return c, c and 1 or 0
	end,
	function(gate, params, inputBB)
		local startCount = gate.scene.forceRecordTb[1].herosStartCount
		local count = 0

		for _, obj in gate.scene.heros:order_pairs() do
			if obj and not obj:isRealDeath() then
				count = count + 1
			end
		end

		return params >= startCount - count, startCount - count
	end,
	function(gate, params, inputBB)
		return not gate.isBossBattle or params >= gate.curRound, gate.isBossBattle and gate.curRound or 0
	end,
	function(gate, params, inputBB)
		local startCount = gate.scene.forceRecordTb[1].herosStartCount

		return startCount <= params, startCount
	end,
	function(gate, params, inputBB)
		local startCount = gate.scene.forceRecordTb[1].herosStartCount

		return params <= startCount, startCount
	end
}

function StarModule:init()
	self._checkType = nil
	self._historyStar = {}
	self._gateStar = nil
	self._starConditionTb = nil
end

function StarModule:initGroupRoundStar(checkType, starConditionTb)
	self._checkType = checkType
	self._starConditionTb = starConditionTb

	return self
end

function StarModule:getGateStar()
	return self._gateStar, self._starConditionTb
end

function StarModule:onGroupRoundEnd(inputBB)
	if self._checkType == battlePlay.Gate.CheckStarType.All then
		local conditionTb = self._starConditionTb
		local totalCount = 0
		local tb = {
			{
				false,
				0
			},
			{
				false,
				0
			},
			{
				false,
				0
			}
		}

		for i = 1, 3 do
			local infos = conditionTb[i]
			local func = StarConditionCheckTb[infos[1]]

			if func then
				tb[i][1], tb[i][2] = func(inputBB.gate, infos[2], inputBB)

				if self._gateStar then
					tb[i][1] = self._gateStar.tb[i][1] and tb[i][1]
					tb[i][2] = math.min(self._gateStar.tb[i][2], tb[i][2])
				end
			end

			if tb[i][1] then
				totalCount = totalCount + 1
			end
		end

		self._gateStar = {
			totalCount = totalCount,
			tb = tb
		}
	end
end

local PostEndParamModule = class("PostEndParamModule", ModuleBase)

function PostEndParamModule:init()
	self._cardState = nil
	self._isOneTeam = false
end

function PostEndParamModule:initCardState(groupRoundLimit)
	self._cardState = {
		{},
		{}
	}

	for i = 1, groupRoundLimit do
		self._cardState[1][i] = {}
		self._cardState[2][i] = {}
	end

	self._isOneTeam = groupRoundLimit == 1

	return self
end

function PostEndParamModule:initCardStateByGroupRound(force, groupRound, dbID, state)
	self._cardState[force][groupRound][dbID] = table.deepcopy(state)
end

function PostEndParamModule:getCardState(inputBB)
	if self._isOneTeam then
		local groupRound = 1

		return {
			self._cardState[1][groupRound],
			self._cardState[2][groupRound]
		}
	end

	return self._cardState
end

function PostEndParamModule:onGroupRoundEnd(inputBB)
	if self._cardState then
		local liveObjHash = {
			{},
			{}
		}

		for _, obj in inputBB.gate.scene:ipairsHeros() do
			if inputBB.gate:checkObjCanToServer(obj) and self._cardState[obj.force][inputBB.groupRound][obj.dbID] then
				liveObjHash[obj.force][obj.dbID] = true
				self._cardState[obj.force][inputBB.groupRound][obj.dbID] = {
					obj:hp() / obj:hpMax(),
					obj:mp1() / obj:mp1Max()
				}
			end
		end

		for dbID, state in pairs(self._cardState[1][inputBB.groupRound]) do
			if not liveObjHash[1][dbID] then
				state[1] = 0
				state[2] = 0
			end
		end

		for dbID, state in pairs(self._cardState[2][inputBB.groupRound]) do
			if not liveObjHash[2][dbID] then
				state[1] = 0
				state[2] = 0
			end
		end
	end
end

local GateProcess = class("GateProcess")

GateProcess.Module = {
	UIModule = UIModule,
	StarModule = StarModule,
	PostEndParamModule = PostEndParamModule
}

function GateProcess:ctor()
	self.modules = {}
end

function GateProcess:initModule(mType)
	local cls = GateProcess.Module[mType]

	if not cls then
		errorInWindows("GateProcess:initModule() mType(%s) error", mType)

		return
	end

	cls:init()

	self.modules[mType] = cls

	return cls
end

function GateProcess:proxy()
	return self.modules
end

function GateProcess:notifyAndRun(msg, inputBB)
	for _, cls in maptools.order_pairs(self.modules) do
		if cls[msg] then
			cls[msg](cls, inputBB)
		end
	end
end

return GateProcess
