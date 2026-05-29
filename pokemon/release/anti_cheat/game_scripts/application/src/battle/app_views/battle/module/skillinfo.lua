-- chunkname: @src.battle.app_views.battle.module.skillinfo

local SkillInfo = class("SkillInfo", battleModule.CBase)
local _format = string.format
local widgetEffectNames = {
	shui = "dazhao_shui_loop",
	shan = "dazhao_shan",
	qian = "dazhao_qian_loop",
	man = "dazhao_man_loop",
	hou = "dazhao_hou_loop",
	mankuang = "dazhao_mankuang",
	res = "dz_ice.skel",
	mankuang_l = "dazhao_mankuang_loop"
}

function SkillInfo:selectIsFirstMainCharge(model, state)
	self.skillMainTb = self.skillMainTb or {}

	local key = tostring(model)

	if self.skillMainTb[key] ~= state and state then
		self.skillMainTb[key] = state

		return true
	end

	self.skillMainTb[key] = state

	return false
end

function SkillInfo:playMainSkillEffect(widget, state, model)
	if not widget.mpWater then
		error("water effect not exist")
	end

	local wsize = widget:size()

	if not widget.kuang then
		local res = self:getEffectName(widget, "res")

		widget.kuang = newCSpriteWithOption(res)

		widget:z(6):add(widget.kuang)
		widget.kuang:setPosition(cc.p(wsize.width / 2 - 3, 5))
	end

	widget.kuang:visible(state)

	if state then
		widget.mpWater:play(self:getEffectName(widget, "shan"))
		widget.mpWater:addPlay(self:getEffectName(widget, "man"))

		if self:selectIsFirstMainCharge(model, state) then
			widget.kuang:z(10):play(self:getEffectName(widget, "mankuang"))
			widget.kuang:z(8):addPlay(self:getEffectName(widget, "mankuang_l"))
		else
			widget.kuang:play(self:getEffectName(widget, "mankuang_l"))
		end
	else
		widget.mpWater:play(self:getEffectName(widget, "shui"))
	end
end

function SkillInfo:getEffectName(widget, name, useDefault)
	local widgetEffects = widget.widgetEffects
	local effectName = widgetEffectNames[name]

	if widgetEffects and widgetEffects[name] then
		effectName = widgetEffects[name]
	end

	if name == "res" then
		effectName = "effect/" .. effectName
	end

	return effectName
end

function SkillInfo:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.widgets = {
		self.parent.UIWidgetBottomRight:get("skill1"),
		self.parent.UIWidgetBottomRight:get("skill2"),
		self.parent.UIWidgetBottomRight:get("skill3"),
		self.parent.UIWidgetBottomRight:get("skill4")
	}

	for _, v in ipairs(self.widgets) do
		v:hide()
	end

	self.cardClipping = self.parent.UIWidgetBottomRight:get("cardClipping")

	self.cardClipping:hide()
	self.cardClipping:setClippingEnabled(true)

	self.cardPx, self.cardPy = self.cardClipping:xy()
	self.cardPHalfWidth = self.cardClipping:size().width / 2
	self.heroIcon = self.cardClipping:get("halfHeroIcon")
	self.curSkill = nil
	self.skillWidgetMap = {}
	self.originWidigetY = self.widgets[1]:getPositionY()

	local infoPanel = self.parent.UIWidgetBottomRight:get("skillInfo")

	infoPanel:hide()

	self.infoPanelSize = infoPanel:getContentSize()
	self.infoPanelDescPos = cc.p(infoPanel:get("container.skillDescribe"):xy())
	self.skillCdMap = {}
	self.mpWaterRes = nil
end

function SkillInfo:skillInit(args, needMove)
	local orderId = args.orderId
	local widget = args.widget
	local skillID = args.skillID
	local leftCd = args.leftCd
	local model = args.model
	local precent = args.precent
	local costMp1 = args.costMp1
	local skillCfg = args.skillCfg

	widget:get("skillName"):setString(skillCfg.skillName)

	if skillCfg.skillDamageTypeIcon then
		widget:get("damageType"):loadTexture(skillCfg.skillDamageTypeIcon)
	else
		widget:get("damageType"):loadTexture(skillCfg.skillDamageType == battle.SkillDamageType.Physical and "battle/icon_w.png" or "battle/icon_t.png")
	end

	if game.NATURE_TABLE[args.natureType] ~= nil then
		widget:get("skillAttribute"):setVisible(true)
		widget:get("skillAttribute"):loadTexture(ui.ATTR_ICON[args.natureType])
	else
		widget:get("skillAttribute"):setVisible(false)
	end

	widget:setTouchEnabled(true)

	local zSkillCfg = self:isZawakeSkill(skillCfg, model)

	widget:get("bgLogo"):setVisible(zSkillCfg ~= nil)

	if widget.mpWater then
		widget.mpWater:removeFromParent()
		widget.kuang:removeFromParent()
		widget.mpHou:removeFromParent()
		widget.mpBall:removeFromParent()

		widget.mpWater = nil
		widget.kuang = nil
		widget.mpHou = nil
		widget.mpBall = nil

		widget:get("bg"):show()
	end

	if skillCfg.skillType2 == battle.MainSkillType.BigSkill then
		local cdPercent = math.floor(100 * precent)

		cdPercent = math.min(math.max(0, cdPercent), 100)
		widget.widgetEffects = skillCfg.widgetEffects or {}

		local wsize = widget:size()
		local res = self:getEffectName(widget, "res")

		self.mpWaterRes = res

		widget:get("bg"):hide()

		local spr = newCSprite("battle/btn_skill_2.png"):addTo(widget, 3):xy(wsize.width / 2, wsize.height / 2)
		local mpHou = newCSpriteWithOption(res)

		mpHou:play(self:getEffectName(widget, "hou"))
		mpHou:setPosition(cc.p(wsize.width / 2 - 3, 5))
		widget:add(mpHou, 2)

		widget.mpHou = mpHou

		local mpBall = newCSpriteWithOption(res)

		mpBall:play(self:getEffectName(widget, "qian"))
		mpBall:setPosition(cc.p(wsize.width / 2 - 3, 5))
		widget:add(mpBall, 4)

		widget.mpBall = mpBall

		local mpWater = newCSpriteWithOption(res)

		mpWater:play(self:getEffectName(widget, "shui"))

		local bgWidget = cc.Sprite:create("battle/btn_skill.png")

		bgWidget:anchorPoint(0, 0):scale(0.98)

		local clipNode = cc.ClippingNode:create(bgWidget)

		clipNode:setAlphaThreshold(0.2)
		widget:add(clipNode)
		clipNode:add(mpWater)

		widget.mpWater = mpWater

		local pos = cc.p(150, 200 * cdPercent / 100 - 75)

		widget.mpWater:stopAllActions()

		if needMove then
			widget.mpWater:setPosition(pos)
			self:playMainSkillEffect(widget, cdPercent >= 100, model)
		else
			local time = 0.6

			transition.executeSequence(widget.mpWater):moveTo(time, 150, pos.y):delay(0.01):func(function()
				self:playMainSkillEffect(widget, cdPercent >= 100, model)
			end):done()
		end

		if costMp1 and costMp1 == 0 and not args.canSpell then
			widget:get("bg"):show()
			self:playMainSkillEffect(widget, false, model)
			widget.mpWater:hide()
			widget.mpHou:hide()
			widget.mpBall:hide()
		else
			widget:get("bg"):hide()
			widget.mpWater:show()
			widget.mpHou:show()
			widget.mpBall:show()
		end
	end

	local roundLabel = widget:get("round")

	roundLabel:hide()
	roundLabel:scale(2.5)
	roundLabel:opacity(0)

	local skillCdBg = widget:get("cdBg")

	skillCdBg:hide()

	if not args.canSpell then
		if leftCd and leftCd > 0 and leftCd < 100 then
			skillCdBg:show()
			roundLabel:setVisible(true)
			roundLabel:setString(leftCd)

			if not next(self.skillCdMap) or self.skillCdMap[skillID] ~= leftCd then
				transition.executeParallel(roundLabel):fadeTo(0.5, 255):scaleTo(0.5, 1)

				self.skillCdMap[skillID] = leftCd
			else
				roundLabel:scale(1)
				roundLabel:opacity(255)
			end

			local cdPercent

			cdPercent = (1 - leftCd / skillCfg.cdRound) * 100
		end

		local cantUseSkill, showInfo = args.cantUseSkill, args.showInfo

		if cantUseSkill and showInfo and showInfo.setGray then
			skillCdBg:show()
		end
	end
end

function SkillInfo:isZawakeSkill(skillCfg, model)
	local zawakeID = skillCfg.zawakeEffect[1]

	if zawakeID and model.tagSkills[zawakeID] then
		return csv.skill[zawakeID]
	end
end

function SkillInfo:getSkillName(skillCfg, model)
	local skillName = skillCfg.skillName
	local zSkillCfg = self:isZawakeSkill(skillCfg, model)

	if zSkillCfg then
		return zSkillCfg.skillName .. skillName
	end

	return skillName
end

function SkillInfo:skillButtonInit(args)
	local orderId = args.orderId
	local widget = args.widget
	local skillID = args.skillID
	local leftCd = args.leftCd
	local leftStartRound = args.leftStartRound
	local model = args.model
	local skillCfg = csv.skill[skillID]
	local clickFrame = widget:get("clickFrame")

	clickFrame:hide()

	local longTouchTriggered = false

	local function showSkillInfo(isShow)
		longTouchTriggered = isShow

		local skillInfo = self.parent.UIWidgetBottomRight:get("skillInfo")
		local container = skillInfo:get("container")
		local skillDescribe = container:get("skillDescribe")

		skillInfo:show()

		if not isShow then
			skillInfo:hide()

			return
		end

		local skillPosX, skillPosY = widget:getPosition()
		local wsize = widget:getBoundingBox()
		local offx = orderId == 1 and -160 or 0

		skillInfo:setPosition(cc.p(skillPosX + offx, skillPosY + wsize.height / 2 + 15))
		skillInfo:setLocalZOrder(99999)
		skillInfo:setVisible(true)

		local skillName = container:get("skillName")

		skillName:setString(self:getSkillName(skillCfg, model))

		local targetDesc = nodetools.get(container, "skillrange")

		targetDesc:setString(skillCfg.targetTypeDesc)

		local descSize = skillDescribe:getContentSize()
		local widthAdapt = math.max(0, skillName:getContentSize().width + targetDesc:getContentSize().width - descSize.width)
		local offsetValue = 0

		if matchLanguage({
			"en"
		}) then
			offsetValue = 150
		end

		self.descSizeWidth = descSize.width + widthAdapt + offsetValue

		skillDescribe:removeAllChildren()

		local isZawakeReplaceStarDesc = false
		local zSkillCfg = self:isZawakeSkill(skillCfg, model)
		local textHeight

		if dataEasy.isSkillChange() then
			if zSkillCfg then
				isZawakeReplaceStarDesc = true
			end

			local list = ccui.ListView:create()

			list:setLocalZOrder(99)
			list:setAnchorPoint(cc.p(0, 0))
			list:setPosition(cc.p(0, 0))
			list:setBackGroundColorType(1)
			list:setScrollBarEnabled(false)
			list:setBackGroundColor(cc.c3b(0, 0, 0))
			list:setBackGroundColorOpacity(0)
			list:addTo(skillDescribe)

			local listWidth = self.descSizeWidth

			for i = 1, 2 do
				list:removeAllChildren()
				list:size(listWidth, 0)

				local skillLv = args.level

				uiEasy.showSkillDesc(list, {
					descGray = true,
					skillLevel = skillLv,
					skillId = skillID,
					star = model:getStar(),
					isZawake = isZawakeReplaceStarDesc
				}, nil, false)

				local innerSize = list:getInnerContainerSize()

				list:height(innerSize.height)

				if i == 1 and innerSize.height > 900 then
					listWidth = listWidth * innerSize.height / 900
				end
			end

			widthAdapt = widthAdapt + listWidth - self.descSizeWidth

			if orderId == 1 then
				skillInfo:x(skillInfo:x() - widthAdapt / 2)
			end

			textHeight = list:height()
		else
			local describe = skillCfg.describeShort == "" and skillCfg.describe or skillCfg.describeShort

			if zSkillCfg then
				if skillCfg.zawakeEffect[2] == 1 then
					isZawakeReplaceStarDesc = true
				else
					describe = skillCfg.zawakeEffectDescShort == "" and skillCfg.zawakeEffectDesc or skillCfg.zawakeEffectDescShort
				end
			end

			local skillLv = args.level
			local str = uiEasy.getStarSkillDesc({
				skillLevel = skillLv,
				skillId = skillID,
				star = model:getStar(),
				isZawake = isZawakeReplaceStarDesc
			}, _, false)
			local skillContent = rich.createWithWidth(string.format("#C0x5b545b#%s", eval.doMixedFormula(describe, {
				skillLevel = skillLv or 1,
				math = math
			}, nil) or "no desc") .. str, 40, nil, self.descSizeWidth)

			skillContent:setAnchorPoint(cc.p(0, 1))
			skillContent:setPosition(cc.p(0, 0))
			skillDescribe:addChild(skillContent, 99)

			textHeight = skillContent:height()
		end

		local offy = math.max(0, textHeight - descSize.height)
		local newWidth = self.infoPanelSize.width + widthAdapt
		local newHeight = self.infoPanelSize.height + offy

		skillInfo:get("bg"):setContentSize(cc.size(newWidth + offsetValue, newHeight))
		targetDesc:setPosition(cc.p(self.infoPanelSize.width / 2 + widthAdapt + offsetValue / 2, targetDesc:getPositionY()))
		container:setPosition(cc.p(self.infoPanelSize.width / 2 - widthAdapt / 2 - offsetValue / 2, newHeight))

		if dataEasy.isSkillChange() then
			skillDescribe:setPosition(cc.p(self.infoPanelDescPos.x, self.infoPanelDescPos.y - textHeight))
		end
	end

	local action
	local nodeSize = widget:getContentSize()
	local rect = cc.rect(0, 0, nodeSize.width, nodeSize.height)

	widget:addTouchEventListener(function(sender, eventType)
		if self.parent.guideManager:isInGuiding() then
			showSkillInfo(false)

			if action then
				widget:stopAction(action)

				action = nil
			end

			return
		end

		if eventType == ccui.TouchEventType.began then
			if action then
				widget:stopAction(action)

				action = nil
			end

			showSkillInfo(false)

			action = performWithDelay(widget, function()
				action = nil

				showSkillInfo(not self.parent.guideManager:isInGuiding())
			end, 0.3)
		elseif eventType == ccui.TouchEventType.moved then
			local touchPos = sender:getTouchMovePosition()
			local pos = widget:convertToNodeSpace(touchPos)

			if not cc.rectContainsPoint(rect, pos) then
				widget:stopAction(action)

				action = nil

				showSkillInfo(false)
			end
		elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
			widget:stopAction(action)

			action = nil

			showSkillInfo(false)
		end
	end)
	widget:onClick(function()
		if longTouchTriggered then
			return
		end

		if self.cannotClick then
			return
		end

		local selectedSkill = model.skills[skillID]

		if not selectedSkill then
			errorInWindows("selectedSkill is nil model unitID(%s), originUnitID(%s), skillID(%s), skillsOrder(%s)", model.unitID, model.originUnitID, skillID, dumps(model.skillsOrder or {}))

			return
		end

		local canSelectObjNums = table.length(selectedSkill:getTargetsHint())

		if not args.canSpell then
			local cantUseSkill, showInfo = model:isLogicStateExit(battle.ObjectLogicState.cantUseSkill, {
				skillType2 = skillCfg.skillType2,
				skillId = skillID
			})
			local str

			if leftCd > 0 or leftStartRound > 0 then
				str = gLanguageCsv.skillCannotSpell
			elseif cantUseSkill then
				str = showInfo and showInfo.tipStr or gLanguageCsv.objectInControl
			elseif model:isBeInSneer() then
				str = gLanguageCsv.objectInSneer
			elseif canSelectObjNums == 0 then
				str = gLanguageCsv.canNotSelect
			else
				str = gLanguageCsv.mpNotEnough
			end

			if str then
				gGameUI:showTip(str)
			end

			return
		end

		self:notify("selectedHero")

		if self.curSkill then
			local preBox = self.widgets[self.skillWidgetMap[self.curSkill]]

			preBox:get("clickFrame"):hide()
			transition.executeParallel(preBox):moveBy(0.02, 0, -10)

			if self.curSkill == skillID then
				self:call("resetHitPanelStateToShowAttrsPanel")

				self.curSkill = nil

				return
			end
		end

		self:notify("selectSkill", selectedSkill, args.exactImmuneInfos)
	end)
end

function SkillInfo:onSelectSkill(skill)
	local skillID = skill.id
	local widget = self.widgets[self.skillWidgetMap[skillID]]

	if not self.skillWidgetMap[skillID] or not widget then
		return
	end

	local clickFrame = widget:get("clickFrame")

	transition.executeParallel(widget):moveBy(0.02, 0, 10)
	clickFrame:setVisible(true)

	self.curSkill = skillID
end

function SkillInfo:onSkillRefresh(model, skillsOrder, skillsStateInfoTb, immuneInfos)
	if not skillsOrder or not next(skillsOrder) or not skillsStateInfoTb or not next(skillsStateInfoTb) then
		return
	end

	local play = model.scene.play

	if not play:isPlaying() then
		self.cannotClick = true

		return
	end

	if play:isNowTurnAutoFight() then
		self.cannotClick = true
	end

	local skillsOrderLen = table.length(skillsOrder)
	local ret = {}
	local slow = 0

	for order, skillID in ipairs(skillsOrder) do
		local i = order - slow

		if i <= table.length(self.widgets) then
			skillID = model.skillsMap[skillID] or skillID

			local skillCfg = csv.skill[skillID]
			local cantUseSkill, showInfo = model:isLogicStateExit(battle.ObjectLogicState.cantUseSkill, {
				skillType2 = skillCfg.skillType2,
				skillId = skillID
			})

			if cantUseSkill and showInfo and showInfo.hide then
				slow = slow + 1
				skillsOrderLen = skillsOrderLen - 1
			else
				local skillStateInfo = skillsStateInfoTb[skillID].stateInfoTb
				local args = {
					orderId = i,
					skillID = skillID,
					skillCfg = skillCfg,
					widget = self.widgets[i],
					canSpell = skillStateInfo.canSpell,
					cantUseSkill = cantUseSkill,
					showInfo = showInfo,
					leftCd = skillStateInfo.leftCd,
					leftStartRound = skillStateInfo.leftStartRound,
					precent = skillStateInfo.precent,
					level = skillStateInfo.level,
					model = model,
					costMp1 = skillsStateInfoTb[skillID].costMp1,
					exactImmuneInfos = immuneInfos[skillID],
					natureType = skillsStateInfoTb[skillID]:getSkillNatureType()
				}

				ret[i] = args

				self:skillInit(args, true)

				self.skillWidgetMap[skillID] = i

				self.widgets[i]:setVisible(true)
				self.widgets[i]:setTouchEnabled(false)

				local delayI = i

				performWithDelay(self.widgets[delayI], function()
					self.widgets[delayI]:setTouchEnabled(true)
				end, 0)
			end
		end
	end

	self.heroIcon:loadTexture(model.unitCfg.show)
	self.heroIcon:scale(model.unitCfg.bansxScale)

	local fixPos = model.unitCfg.bansxPosC

	self.heroIcon:xy(self.cardPHalfWidth + (fixPos.x or 0), fixPos.y or 0)
	self.heroIcon:setVisible(false)

	if skillsOrderLen < table.length(self.widgets) then
		for i = skillsOrderLen + 1, table.length(self.widgets) do
			self.widgets[i]:hide()
		end
	end

	local newX = self.widgets[math.min(skillsOrderLen, table.length(self.widgets))]:getPositionX()

	self.cardClipping:xy(newX - 40 - self.cardPHalfWidth, self.cardPy)

	for i, args in ipairs(ret) do
		self:skillButtonInit(args)
	end

	for i, _ in pairs(self.widgets) do
		self.widgets[i]:setPositionY(self.originWidigetY)
	end
end

function SkillInfo:onNewBattleRoundTo(args)
	self.curSkill = nil
	self.skillWidgetMap = {}
	self.cannotClick = nil

	local scene = args.obj.scene

	if scene.autoFight or args.isTurnAutoFight or not scene.play.curBattleRoundAttack then
		self:hideAll()
	else
		self:onSkillRefresh(args.obj, args.skillsOrder, args.skillsStateInfoTb, args.immuneInfos)
	end
end

function SkillInfo:onBattleTurnEnd()
	self:hideAll()
end

function SkillInfo:onAutoSelectSkill(seat, skillId)
	local spr = self:call("getSceneObjBySeat", seat)

	if spr then
		self:onSelectObj(spr, skillId)
	end
end

function SkillInfo:onSelectObj(spr, skillID)
	local skillID = skillID or self.curSkill

	if self.curSkill == nil then
		if not skillID then
			return
		end

		self:onSelectSkill({
			id = skillID
		})
	end

	self:notify("selectedHero")
	spr.natureQuan:show()
	transition.executeSequence(spr.natureQuan):delay(0.5):func(function()
		spr.natureQuan:hide()
	end):done()
	transition.executeSequence(spr.groundRing):delay(0.5):func(function()
		spr.groundRingVisible:set(false)
		spr.groundRing:setVisible(spr.groundRingVisible:get())
	end):done()

	self.curSkill = nil
	self.skillWidgetMap = {}

	for i, widget in ipairs(self.widgets) do
		widget:setTouchEnabled(false)
	end

	self.parent:handleOperation(battle.OperateTable.attack, spr.model.seat, skillID)

	self.cannotClick = true
end

function SkillInfo:onClose()
	return
end

function SkillInfo:hideAll()
	for _, v in ipairs(self.widgets) do
		v:setPositionY(-self.originWidigetY - 100)
		v:setVisible(false)
	end

	self.heroIcon:hide()
end

return SkillInfo
