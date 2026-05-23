-- chunkname: @src.battle.models.skill.summon_skill

local PassiveSkillTypes = battle.PassiveSkillTypes
local SummonSkillModel = class("SummonSkillModel", battleSkill.SkillModel)

battleSkill.SummonSkillModel = SummonSkillModel

function SummonSkillModel:ctor(scene, owner, cfg, level)
	battleSkill.PassiveSkillModel.ctor(self, scene, owner, cfg, level)
end

function SummonSkillModel:initSkillArgs()
	local cfg = self.cfg

	self.summonArgs = cfg.skillArgs
	self.summonNum = cfg.skillArgs[5] or 1
	self.summonPos = battleEasy.ifElse(cfg.skillArgs[2] ~= -1 and self.summonNum > 1, 0, cfg.skillArgs[2])
	self.summonBackStage = self.summonPos == -1
	self.mode = cfg.skillArgs[7] or battle.ObjectType.Normal
	self.replaceObj = cfg.skillArgs[10] == 1
end

function SummonSkillModel:canSpell()
	if self.owner:isDeath() then
		return false
	end

	if self.summonBackStage then
		return true
	end

	if self.scene:getForceNumIncludeDead(self.owner.force) == 6 then
		return false
	end

	if self.summonPos ~= 0 and self.summonNum == 1 and not self.scene:isSeatEmpty(self.summonPos) then
		return false
	end

	return true
end

function SummonSkillModel:onTrigger(typ, target, args)
	if self.skillType ~= battle.SkillType.PassiveSummon then
		return
	end

	if self:canSpell() and battleSkill.PassiveSkillModel.trigger(self, target, args) then
		self:spellTo(target, args)
	end
end

function SummonSkillModel:processPlay(skillBB)
	local processArgs, noMissTargetsArray, allDamagedOrder = skillBB.processArgs, skillBB.noMissTargetsArray, skillBB.allDamagedOrder

	for i, processCfg in self:ipairsProcess() do
		local processTargets = self.allProcessesTargets[processCfg.id] and self.allProcessesTargets[processCfg.id].targets
		local extraTarget
		local lastProcessArg = self:getProcessArg(i - 1)

		if i > 1 and lastProcessArg and self.allProcessesTargets[lastProcessArg.id] then
			extraTarget = self.allProcessesTargets[lastProcessArg.id].buffTargets
		end

		processArgs[i].buffTb = self:processAddBuff(processCfg, processTargets, extraTarget, battle.SkillAddBuffType.InPlay)
	end
end

function SummonSkillModel:processTarget(skillBB)
	local processArgs = skillBB.processArgs
	local summonTargets = {}
	local summonPos = self.summonPos
	local owner = self.owner
	local stepNum = owner.force == 1 and 0 or self.scene.play.ForceNumber
	local summonGroupId = owner.summonGroup
	local summonBackStage = self.summonBackStage

	for i = 1, self.summonNum do
		if summonPos == 0 then
			for seat = 1 + stepNum, self.scene.play.ForceNumber + stepNum do
				if self.scene:isSeatEmpty(seat) then
					summonPos = seat

					break
				end
			end
		end

		if summonPos ~= 0 then
			local roleOut = battleEasy.getSummonRoleOut(self.summonArgs, owner)

			roleOut.summonGroup = summonGroupId

			local newTarget

			newTarget, summonBackStage = self.scene.play:addCardRole(summonPos, roleOut, summonBackStage, owner.force, self.replaceObj, owner)

			if newTarget then
				if summonBackStage == false then
					table.insert(self.scene.play.summonHeros, {
						obj = newTarget
					})
					newTarget:initedTriggerPassiveSkill()
					self.scene:tirggerFieldBuffs(newTarget)
				end

				newTarget:addExRecord(battle.ExRecordEvent.summoner, owner)
				table.insert(summonTargets, newTarget)
			end

			if not summonBackStage then
				summonPos = 0
			end
		end
	end

	for i, processCfg in self:ipairsProcess() do
		local args = processArgs[i]

		if i == 1 and self.mode ~= battle.ObjectType.Normal then
			summonTargets = self:getFollowTargets(processCfg, skillBB.target)
		end

		if processCfg.skillTarget == 24 then
			args.targets = summonTargets
			self.allProcessesTargets[processCfg.id] = {
				targets = args.targets,
				buffTargets = args.targets
			}
		end

		battleEasy.queueNotifyFor(self.owner.view, "processArgs", processCfg.id, args)
	end

	skillBB.summonTargets = summonTargets
end

function SummonSkillModel:getFollowTargets(processCfg, target)
	local followTargets = {}
	local processArgs = self:onProcess(processCfg, target)
	local roleOut, newTarget

	for _, obj in ipairs(processArgs.targets) do
		if obj.seat >= 1 and obj.seat <= self.scene.play.ObjectNumber then
			roleOut = battleEasy.getSummonRoleOut(self.summonArgs, self.owner)
			newTarget = self.scene.play:addCardRole(obj.seat, roleOut, false, obj.force, self.replaceObj, self.owner)

			if newTarget then
				table.insert(followTargets, newTarget)
				newTarget:initedTriggerPassiveSkill()
				self.scene:tirggerFieldBuffs(newTarget)
			end
		end
	end

	return followTargets
end

function SummonSkillModel:isAttackSkill()
	return false
end

function SummonSkillModel:_spellTo(target)
	self:sortRealProcess()

	local skillBB = {
		skillCfg = self.cfg,
		target = target
	}

	self:processBefore(skillBB)
	self:processPlay(skillBB)
	self:processTarget(skillBB)
	self:processAfter(skillBB)
	self:onSpellView(skillBB)
end

function SummonSkillModel:onSpellView(skillBB)
	if table.length(skillBB.summonTargets) == 0 then
		return
	end

	local scene = self.scene
	local view = self.owner.view
	local skillCfg = self.cfg
	local targets = skillBB.summonTargets
	local view = self.owner.view
	local actionTime = skillCfg.actionTime

	battleEasy.modifierTargetsViewVisible(targets, false)
	battleEasy.queueEffect(function()
		battleEasy.queueEffect(function()
			for _, tar in ipairs(targets) do
				tar.view:proxy():setVisibleEnable(true)
			end
		end)
	end)
	battleEasy.queueNotifyFor(view, "skillBefore", self.disposeDatasOnSkillStart, self.skillType)
	battleEasy.queueNotifyFor(view, "playAction", skillCfg.spineAction, actionTime)
	battleEasy.queueNotifyFor(view, "objSkillEnd", self.disposeDatasOnSkillEnd, self.skillType)
	battleEasy.queueNotifyFor(view, "objSkillOver")
end
