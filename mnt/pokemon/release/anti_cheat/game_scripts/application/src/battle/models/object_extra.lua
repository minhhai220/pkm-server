
globals.ObjectExtraModel = class("ObjectExtraModel", ObjectModel)

local PassiveSkillTypes = battle.PassiveSkillTypes

function ObjectExtraModel:ctor(scene, seat)
	ObjectModel.ctor(self, scene, seat)
end

function ObjectExtraModel:init(data)
	self.modeArgs = data.modeArgs
	self.followMark = data.followMark
	self.selectEnable = data.selectEnable
	self.extraObjectCsvCfg = data.extraObjectCfgID and csv.extra_object[data.extraObjectCfgID] or gDealGroup2ExtraObjectCsv[self.modeArgs.dealGroup or 1]
	self.benchmarkObjId = nil

	ObjectModel.init(self, data)
	self:bornAddBuffs()
end

function ObjectExtraModel:delFollowObjWithDead(attacker, killDamage, deadArgs)
	return
end

function ObjectExtraModel:addObjViewToScene()
	local args = {
		type = battle.SpriteType.Follower,
		effectSeatType = self.data.viewCfg.effectSeatType or 1,
		offsetPos = self.data.viewCfg.offsetPos
	}

	self.view = gRootViewProxy:getProxy("onSceneAddObj", tostring(self), readOnlyProxy(self, {
		hp = function()
			return self:hp(true)
		end,
		mp1 = function()
			return self:mp1(true)
		end,
		setHP = function(_, v)
			return self:setHP(nil, v)
		end,
		setMP1 = function(_, v)
			return self:setMP1(nil, v)
		end
	}), args)
end

function ObjectExtraModel:delBuffsWithSelf()
	local enemyForce = self.force == 1 and 2 or 1

	for _, obj in self.scene:ipairsOnSiteHeros() do
		if not obj:isAlreadyDead() and obj:isBeInSneer() and obj:getSneerObj() and obj:getSneerObj().id == self.id then
			for _, buff in obj:iterBuffsWithEasyEffectFunc("sneer") do
				if buff.csvCfg.easyEffectFunc == "sneer" then
					buff:overClean()
				end
			end
		end
	end
end

function ObjectExtraModel:recordRealDeadHpMaxSum()
	return
end

function ObjectExtraModel:addAttackerMpOnSelfDead(attacker)
	if self.extraObjectCsvCfg.attakerMp == true then
		ObjectModel.addAttackerMpOnSelfDead(self, attacker)
	end
end

function ObjectExtraModel:bornAddBuffs()
	local buffCfgIds = self.extraObjectCsvCfg.bornAddBuffs

	for _, id in ipairs(buffCfgIds) do
		local args = {
			buffValue1 = 0,
			prob = 1,
			value = 0,
			lifeRound = 99,
			cfgId = id
		}
		local newArgs = BuffArgs.fromSceneBuff(args)

		addBuffToHero(id, self, self, newArgs)
	end
end

function ObjectExtraModel:realDeathCleanData()
	ObjectModel.realDeathCleanData(self)

	local benchmarkObj = self:getBenchMarkObj()

	if benchmarkObj then
		for _, data in benchmarkObj:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.followObject) do
			if self.id == data.caster.id then
				data.buff:overClean()

				break
			end
		end
	end
end

function ObjectExtraModel:isBindOwnerWithDead()
	if self.mode == battle.ObjectType.FollowNormal then
		return false
	end

	return self.extraObjectCsvCfg.deadDel
end

function ObjectExtraModel:isBindOwnerWithStage()
	if self.mode == battle.ObjectType.FollowNormal then
		return false
	end

	return self.extraObjectCsvCfg.detachBind
end

function ObjectExtraModel:isBindOwnerWithShiftPos()
	if self.mode == battle.ObjectType.FollowNormal then
		return false
	end

	return self.extraObjectCsvCfg.shiftPosBind
end

function ObjectExtraModel:updateBattleRound(type)
	self.battleRound[type] = self.battleRound[type] + 1
	self.battleRoundAllWave[type] = self.battleRoundAllWave[type] + 1
end

function ObjectExtraModel:doFrontStage()
	if self.scene.specialRound:isEffect() then
		if self:isBindOwnerWithStage() and self.scene:getBackObject(self.benchmarkObjId) ~= nil then
			return
		end

		if self.mode == battle.ObjectType.FollowNormal and self.scene.specialRound:isOtherBackObj(self.id) then
			return
		end
	end

	if self.mode == battle.ObjectType.FollowNormal then
		local data = self:getEventByKey(battle.ExRecordEvent.frontStage)

		if not data then
			return
		end

		local seat = data.frontStageTarget

		if seat == nil or self.scene:isSeatEmptyWithFollowType(data.seatType, seat, self) == false then
			return
		end

		self.scene.backHeros:erase(self.id)
		self.scene:addExtraObj(self)

		self.seat = seat

		self:cleanEventByKey(battle.ExRecordEvent.frontStage)

		if not data.isBrawl then
			self:initedTriggerPassiveSkill()
		end

		local faceToForce = seat <= 6 and 1 or 2

		self.view:proxy():updateFaceTo(faceToForce)
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBackStage, {
			obj = self,
			buffCfgId = data.cfgId
		})
		self:onPositionStateChange(true, true)
		battleEasy.deferNotifyCantJump(self.view, "stageChange", true)

		return
	end

	self.scene.backHeros:erase(self.id)
	self.scene:addExtraObj(self)
	battleEasy.deferNotifyCantJump(self.view, "stageChange", true)
end

function ObjectExtraModel:backStage()
	self.scene:eraseExtraObj(self)
	self.scene:addBackStageObj(self)
	self.scene.play:cleanExRoundFromAttackList(self)
	battleEasy.deferNotifyCantJump(self.view, "stageChange", false)
end

function ObjectExtraModel:isNormalSelectable()
	return self.selectEnable
end

function ObjectExtraModel:isFollowObject()
	return self.data.isFollowObject
end

function ObjectExtraModel:onLeaveSeat(buffInfo)
	if self:hasExtraOccupiedSeat() then
		ObjectModel.onLeaveSeat(self, buffInfo)
	end
end

function ObjectExtraModel:syncViewSeat()
	battleEasy.queueEffect(function()
		self.view:proxy():syncSeatWithMarkObj()
	end)
end

function ObjectExtraModel:getBenchMarkObj()
	return self.scene:getFieldObject(self.benchmarkObjId)
end

function ObjectExtraModel:syncSeatGetMarkObjId()
	local benchmarkObj = self:getBenchMarkObj()

	if not benchmarkObj then
		return nil
	end

	if not self:isBindOwnerWithStage() then
		return nil
	end

	if not self:isFollowObject() then
		return nil
	end

	return benchmarkObj.id
end
