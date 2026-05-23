local AidManager = class("AidManager")

function AidManager:ctor(gate)
	self.csvCfg = nil
	self.gate = gate
	self.timesLimit = 0
	self.initTimes = 0
	self.roundResumeCfg = {
		0,
		0
	}
	self.deadResumeCfg = {
		0,
		0
	}
	self.leftTimes = {
		0,
		0
	}
	self.deadCounts = {
		0,
		0
	}
end

function AidManager:init(gateType)
	self.csvCfg = csv.aid.scene[gateType]

	if not self.csvCfg then
		return
	end

	local aidTimes = self.csvCfg.aidTimes

	self.timesLimit = aidTimes[1]
	self.initTimes = aidTimes[2]
	self.roundResumeCfg = {
		aidTimes[3],
		aidTimes[4]
	}
	self.deadResumeCfg = {
		aidTimes[5],
		aidTimes[6]
	}
	self.leftTimes = {
		self.initTimes,
		self.initTimes
	}
	self.deadCounts = {
		0,
		0
	}

	gRootViewProxy:notify("initAidInfo", self)
end

function AidManager:reset(force)
	self.leftTimes[force] = self.initTimes
	self.deadCounts[force] = 0

	gRootViewProxy:notify("resetAidInfo", force)
end

function AidManager:triggerAidAttack(aidTriggerType, skill)
	if not self.csvCfg then
		return
	end

	if aidTriggerType == battle.aidTriggerType.RoundStartBefore and self.gate.curRound > 1 and (self.gate.curRound - 1) % self.roundResumeCfg[1] == 0 then
		self:updateForceAidTimes(1, self.roundResumeCfg[2])
		self:updateForceAidTimes(2, self.roundResumeCfg[2])
		battleEasy.pushNotifyRootView("updateForceAidTimes", 1, self:getLeftAidTimes(1))
		battleEasy.pushNotifyRootView("updateForceAidTimes", 2, self:getLeftAidTimes(2))
	end

	local timesLimit = {
		battle.Const.AidTriggerObjectLimit,
		battle.Const.AidTriggerObjectLimit
	}

	for _, obj in self.gate.scene:ipairsAidHeros() do
		local force = obj.force

		if timesLimit[force] > 0 and obj:onAidAttack(aidTriggerType, skill) then
			timesLimit[force] = timesLimit[force] - 1
		end
	end
end

function AidManager:addAidTimesByRealDead(obj)
	if not self.csvCfg then
		return
	end

	if obj:isExtraObj() then
		return
	end

	local deadCounts = self.deadCounts
	local force = obj.force

	deadCounts[force] = deadCounts[force] + 1

	if deadCounts[force] % self.deadResumeCfg[1] == 0 then
		self:updateForceAidTimes(force, self.deadResumeCfg[2])
		battleEasy.pushNotifyRootView("updateForceAidTimes", force, self:getLeftAidTimes(force))
	end
end

function AidManager:updateForceAidTimes(force, delta)
	if not self.csvCfg then
		return
	end

	local leftTimes = self.leftTimes

	leftTimes[force] = cc.clampf(leftTimes[force] + delta, 0, self.timesLimit)
end

function AidManager:getLeftAidTimes(force)
	if not self.csvCfg then
		return 0
	end

	return self.leftTimes[force]
end

function AidManager:waveAddCardRoles(force, wave, aidRoleOut)
	if aidRoleOut[force][wave] then
		for _, obj in self.gate.scene:ipairsAidHeros() do
			if obj.force == force then
				obj:processRealDeathClean()
				battleComponents.unbindAll(obj)
				self.gate.scene.aidHeros:erase(obj.id)
			end
		end

		self:reset(force)
	end

	self.gate.scene.aidHerosOrder = nil
end

function AidManager:initAidRoleOut(force, groupRound, aidRoleOut)
	for _, obj in self.gate.scene:ipairsAidHeros() do
		if obj.force == force then
			obj:processRealDeathClean()
			battleComponents.unbindAll(obj)
			self.gate.scene.aidHeros:erase(obj.id)
		end
	end

	self:reset(force)

	self.gate.scene.aidHerosOrder = nil
end

return AidManager
