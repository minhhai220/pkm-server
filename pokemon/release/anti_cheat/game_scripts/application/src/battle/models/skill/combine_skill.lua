local CombineSkillModel = class("CombineSkillModel", battleSkill.SkillModel)

battleSkill.CombineSkillModel = CombineSkillModel

function CombineSkillModel:ctor(scene, owner, cfg, level)
	battleSkill.SkillModel.ctor(self, scene, owner, cfg, level)

	self.combinationObjCardId = self.cfg.conditionValue[1]
	self.reduceMpType = self.cfg.conditionValue[2]
	self.hideCombineObj = self.cfg.conditionValue[3] == 1
	self.playWithEffectID = self.cfg.conditionValue[4]
end

function CombineSkillModel:updateStateInfoTb()
	battleSkill.SkillModel.updateStateInfoTb(self)

	self.owner.combineObj = self.owner:getCombineSkillBindObject(self.combinationObjCardId)
end

function CombineSkillModel:canSpell()
	if not self.owner.combineObj then
		return false
	end

	if self.owner:checkCanUseSkill() == false then
		return false
	end

	if self.owner.combineObj:checkCanUseSkill() == false then
		return false
	end

	local tar = self:getTargetsHint()
	local sneerAtMeObj = self.owner:getSneerObj()

	if sneerAtMeObj and sneerAtMeObj:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, {
		fromObj = self.owner
	}) then
		if self.owner:isBeInDuel() then
			return false
		else
			tar = self.owner:getCanAttackObjs(sneerAtMeObj.force)
		end
	end

	if table.length(tar) == 0 then
		return false
	end

	return self:getLeftCDRound() < 1
end

function CombineSkillModel:isJumpBigSkill()
	return self.canJump and userDefault.getForeverLocalKey("mainSkillPass", false)
end

function CombineSkillModel:updateRecord()
	self.owner:addExRecord(self.skillType2, 1)

	if self.scene:getExtraRoundMode() and self.skillType2 == battle.MainSkillType.BigSkill then
		self.owner:addExRecord(battle.ExRecordEvent.exAttackSpellBigSkill, 1)
	end
end

function CombineSkillModel:onSpellView(skillBB)
	local function effectSpell()
		battleEasy.deferNotify(nil, "hideAllObjsSkillTips")
		battleEasy.deferNotify(nil, "showHero", {
			typ = "showAll",
			hideLife = true
		})
		gRootViewProxy:proxy():flushCurDeferList()
		self:_onSpellView(skillBB)
	end

	effectSpell()
end

function CombineSkillModel:_onSpellView(skillBB)
	local target, posIdx = skillBB.target, skillBB.lastPosIdx
	local scene = self.scene
	local view = self.owner.view
	local combView = self.owner.combineObj.view
	local skillCfg = self.cfg
	local targets = self:targetsMap2Array(self.allTargets)
	local lastTarget

	self.owner.flashBack = skillCfg.flashBack

	view:proxy():setSkillJumpSwitch(self.canjumpBigSkill)

	for i, processCfg in self:ipairsProcess() do
		if processCfg.effectEventID then
			local effectCfg = self.processEventCsv[processCfg.id]

			if effectCfg and effectCfg.control then
				battleEasy.queueEffect("control", effectCfg.control)
			end
		end
	end

	local hideHero = {}

	for _, obj in self.scene:ipairsOnSiteHeros() do
		if not self.allTargets[obj.id] and obj.id ~= self.owner.id and (obj.id ~= self.owner.combineObj.id or self.hideCombineObj) and not self.protectorObjs[obj.id] then
			table.insert(hideHero, tostring(obj))
		end
	end

	local combineSkillCfg
	local unitCfg = csv.unit[self.owner.combineObj.unitID]

	for _, skillId in ipairs(unitCfg.skillList) do
		local skillCfg = csv.skill[skillId]

		if skillCfg.skillType2 == battle.MainSkillType.BigSkill then
			combineSkillCfg = skillCfg

			break
		end
	end

	battleEasy.queueEffect("sound", {
		delay = 0,
		sound = {
			loop = 0,
			res = "skill2_effect.mp3"
		}
	})
	battleEasy.queueEffect(function()
		gRootViewProxy:notify("ultSkillPreAni1")
		gRootViewProxy:notify("ultSkillPreAni2", tostring(self.owner), skillCfg, hideHero, combineSkillCfg)
		gRootViewProxy:notify("objMainSkill")
	end)
	battleEasy.queueEffect("delay", {
		lifetime = 2000
	})
	battleEasy.queueEffect(function()
		local tpz = target.view:proxy():getMovePosZ()

		for id, obj in ipairs(targets) do
			tpz = math.max(tpz, obj.view:proxy():getMovePosZ())
		end

		view:proxy():setLocalZOrder(tpz + 1)
	end)

	if self.counterAttackForView then
		view:proxy():onShowCounterAttackText(tostring(self.owner), self.owner:getExtraRoundMode())

		self.counterAttackForView = false
	end

	view:proxy():onSkillBefore(self.disposeDatasOnSkillStart, self.skillType, false, skillBB.sceneTag)
	view:proxy():onAttacting(true)

	if skillCfg.sound and not self.canjumpBigSkill then
		battleEasy.queueEffect("sound", {
			delay = skillCfg.sound.delay,
			sound = {
				res = skillCfg.sound.res,
				loop = skillCfg.sound.loop
			}
		})
	end

	local protectorIDList = {}

	for k, v in ipairs(self.actionSegArgs) do
		if not lastTarget or lastTarget and lastTarget.id ~= v.target.id then
			view:proxy():onMoveToTarget(v.posIdx, {
				delayBeforeMove = skillCfg.moveTime[1],
				moveCostTime = skillCfg.moveTime[2],
				timeScale = self.scene:getExtraRoundMode() and 0.51,
				cameraNear = skillCfg.cameraNear,
				cameraNear_posC = skillCfg.cameraNear_posC,
				posC = skillCfg.posC,
				attackFriend = self.owner:needAlterAttackTurn()
			}, false, tostring(v.target), self:filterProtectorView(v.target, protectorIDList))
		end

		lastTarget = v.target

		view:proxy():onPlayAction(v.spine, v.lifeTime)
	end

	if self.canjumpBigSkill then
		local totalDmg, totalResumeHp = self:getTargetsFinalValue()
		local dmg, typ = totalDmg, battle.SkillSegType.damage

		if totalDmg == 0 and self:isSameType(battle.SkillFormulaType.resumeHp) then
			dmg, typ = totalResumeHp, battle.SkillSegType.resumeHp
		end

		local params = {
			delta = dmg,
			skillId = skillCfg.id,
			typ = typ
		}

		view:proxy():onUltJumpShowNum(params)
	end

	view:proxy():onObjSkillEnd(self.disposeDatasOnSkillEnd, self.skillType)
	view:proxy():onComeBack(posIdx, false, {
		delayBeforeBack = skillCfg.moveTime[3],
		backCostTime = skillCfg.moveTime[4],
		timeScale = self.scene:getExtraRoundMode() and 0.51,
		flashBack = skillCfg.flashBack,
		attackFriend = self.owner:needAlterAttackTurn()
	}, false, protectorIDList)
	view:proxy():onAfterComeBack(self.disposeDatasAfterComeBack)
	view:proxy():onAttacting(false)
	view:proxy():onResetPos()
	view:proxy():onObjSkillOver()
end

function CombineSkillModel:startDeductMp(isBack)
	if self.hadDeductedMp then
		self.hadDeductedMp = false

		return
	end

	if self:needIgnoreMpCd() then
		return
	end

	if self:isNormalSkillType() then
		if self.reduceMpType == 0 then
			return
		end

		if self.reduceMpType == 1 then
			self.owner:setMP1(0, 0)

			return
		end

		if self.reduceMpType == 2 then
			self.owner:setMP1(0, 0)
			self.owner.combineObj:setMP1(0, 0)
		end

		return
	end
end

function CombineSkillModel:isNormalSkillType()
	return true
end
