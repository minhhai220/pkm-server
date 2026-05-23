-- chunkname: @src.battle.models.play.normal_gate

local NormalGate = class("NormalGate", battlePlay.Gate)

battlePlay.NormalGate = NormalGate
NormalGate.OperatorArgs = {
	canHandle = true,
	isFullManual = false,
	isAuto = false,
	canSkip = false,
	canSpeedAni = true,
	canPause = true
}
NormalGate.SpecEndRuleCheck = {
	battle.EndSpecialCheck.BothDead
}

function NormalGate:onProcessSupply()
	if self.scene.sceneConf.deployType == game.DEPLOY_TYPE.MultTwo or self.scene.sceneConf.deployType == game.DEPLOY_TYPE.MultThree then
		self.moduleProcess:initModule("UIModule"):initMultipGroupPVE(self.scene.sceneConf.deployType)
	end

	self.moduleProcess:initModule("StarModule"):initGroupRoundStar(battlePlay.Gate.CheckStarType.All, self:getStarConditionsInfo())
end

function NormalGate:onInitGroupRoundSupply()
	if self.scene.sceneConf.deployType == game.DEPLOY_TYPE.MultTwo then
		self:initGroupRound(1, 1, self.waveCount):initGroupRound(2, 1, self.waveCount)
	elseif self.scene.sceneConf.deployType == game.DEPLOY_TYPE.MultThree then
		self:initGroupRound(1, 1, self.waveCount):initGroupRound(2, 1, self.waveCount):initGroupRound(3, 1, self.waveCount)
	else
		self:initGroupRound(1, 1, self.waveCount)
	end

	self:initAfterWaveEnd(battlePlay.Gate.AfteWaveEndType.WinNext):initGroupRoundCheck(battlePlay.Gate.GroupRoundCheckType.SelfForceNotFail)
end

function NormalGate:onInitRoleOutSupply()
	local waveRoleOutInfo = self.groupRoleOut[self.groupRound]

	if not waveRoleOutInfo then
		self.groupRoleOut[self.groupRound] = {
			waveRoleOut = {
				{},
				{}
			},
			waveRoleOut2 = {
				{},
				{}
			},
			aidRoleOut = self.data.aidRoleOut
		}
		waveRoleOutInfo = self.groupRoleOut[self.groupRound]

		if self.data.multipGroup then
			table.insert(waveRoleOutInfo.waveRoleOut[1], self.data.roleOut[1][self.groupRound])
			table.insert(waveRoleOutInfo.waveRoleOut2[1], self.data.roleOut2[1][self.groupRound])
		else
			table.insert(waveRoleOutInfo.waveRoleOut[1], self.data.roleOut)
			table.insert(waveRoleOutInfo.waveRoleOut2[1], self.data.roleOut2)
		end

		for j = 1, self.waveCount do
			local enemyRoleOut = self:getEnemyRoleOutT(j, self.groupRound)

			table.insert(waveRoleOutInfo.waveRoleOut[2], enemyRoleOut[j])
		end
	end
end

function NormalGate:createObjectModel(force, seat)
	local obj

	if force == 1 then
		obj = ObjectModel.new(self.scene, seat)
	else
		obj = MonsterModel.new(self.scene, seat)
	end

	return obj
end

function NormalGate:postEndResultToServer(cb)
	local oldCapture = gGameModel.capture:read("limit_sprites")
	local endInfo = self:makeEndViewInfos({
		gateStar = true
	})

	gRootViewProxy:raw():postEndResultToServer("/game/end_gate", function(tb)
		cb(endInfo, tb, oldCapture)
	end, self.scene.battleID, self.scene.sceneID, endInfo.result, endInfo.gateStar)
end
