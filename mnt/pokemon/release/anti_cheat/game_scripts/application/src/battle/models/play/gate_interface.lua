local Gate = battlePlay.Gate

Gate.GroupRoundCheckType = {
	SelfForceNotFail = 2,
	WinOfMore = 1
}
Gate.CheckStarType = {
	All = 1
}

function Gate:onInitGroupRoundSupply()
	return
end

function Gate:onInitRoleOutSupply()
	return
end

function Gate:onProcessSupply()
	return
end

function Gate:onStartGroupRoundSupply()
	return
end

function Gate:onGroupRoundEndSupply()
	return
end

Gate.WaveCheckType = {
	FinalForceWin = 3,
	SelfForceNotFail = 2,
	WinOfMore = 1
}
Gate.AfteWaveEndType = {
	WinNext = 1,
	AllClear = 2
}

function Gate:onWaveAddObjsStrategySupply()
	return
end

function Gate:onGetWaveRoleOutSupply(force, groupRound, waveID, isRoleOut2)
	return
end

function Gate:onWaveResultCheckSupply()
	local isLeftAllRealDead = self:checkForceAllRealDead(1)

	if isLeftAllRealDead then
		return battle.Const.Fail
	end

	local isRightAllRealDead = self:checkForceAllRealDead(2)

	if isRightAllRealDead then
		return battle.Const.Win
	end

	if isLeftAllRealDead and isRightAllRealDead then
		return battle.Const.Draw
	end
end

function Gate:onSpecEndRuleCheckSupply()
	return
end

function Gate:endMoreDelayTime()
	return 2000
end
