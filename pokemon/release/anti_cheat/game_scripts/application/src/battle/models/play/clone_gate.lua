-- chunkname: @src.battle.models.play.clone_gate

local CloneGate = class("CloneGate", battlePlay.Gate)

battlePlay.CloneGate = CloneGate
CloneGate.OperatorArgs = {
	isFullManual = false,
	isAuto = false,
	canSkip = true,
	canSpeedAni = true,
	canPause = true,
	canHandle = true
}

function CloneGate:init(data)
	local canJump = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.BattleSkip, game.GATE_TYPE.clone)

	if canJump then
		self.OperatorArgs.canSkip = true
	end

	battlePlay.Gate.init(self, data)
end

function CloneGate:newWaveAddObjsStrategy()
	self:waveAddCardRoles(1)
	self:waveAddCardRoles(2)
	self:doObjsAttrsCorrect(true, true)
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

function CloneGate:postEndResultToServer(cb)
	local endInfos = self:makeEndViewInfos()
	local battleView = gRootViewProxy:raw()

	local function cbFunc(tb)
		if not battleView.modes.fromRecordFile then
			endInfos.freeBox = tb.view.freeBox
		end

		cb(endInfos, tb)
	end

	battleView:postEndResultToServer("/game/clone/battle/end", {
		cb = cbFunc,
		onErrClose = function(tb)
			if tb and tb.err ~= "cloneRoomOutDate" and tb.err ~= "ErrCloneRoomNotExists" then
				return
			end

			gGameUI:switchUI("city.view")
			gGameUI:goBackInStackUI("city.adventure.clone_battle.base")
		end
	}, endInfos.result)
end

function CloneGate:getMonsterCsv(sceneId, waveId)
	sceneId = sceneId or self.scene.sceneID

	return battleEasy.getMonsterCsv(sceneId, 1)
end

local CloneGateRecord = class("CloneGateRecord", CloneGate)

battlePlay.CloneGateRecord = CloneGateRecord
CloneGateRecord.OperatorArgs = {
	isFullManual = false,
	isAuto = true,
	canSkip = true,
	canSpeedAni = true,
	canPause = true,
	canHandle = false
}

function CloneGateRecord:init(data)
	battlePlay.Gate.init(self, data)
end
