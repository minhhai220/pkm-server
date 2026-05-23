-- chunkname: @src.battle.views.lifebar

local heroResPsthTb = {
	mHp = "battle/bar_hero_blood.png",
	level = "battle/logo_hero_level.png",
	level2 = "battle/logo_hero_level2.png"
}
local enemyResPsthTb = {
	level2 = "battle/logo_enemy_level2.png",
	level = "battle/logo_enemy_level.png"
}
local shieldResPathTb = {
	shield = "battle/bar_shield_blue.png"
}
local comboResPathTb = {
	line = "battle/bar_nqt_kd.png"
}
local assimilateResPathTb = {
	normal = "battle/bar_enemy_white.png"
}
local universalMaxLen = 190

globals.CLifeBar = class("CLifeBar", cc.Node)

function CLifeBar:ctor(model, battleView)
	self.model = model

	self:init(battleView)
end

function CLifeBar:init(battleView)
	local pnode = battleView.UIWidget:getResourceNode()
	local resTb = self.model.force == 1 and heroResPsthTb or enemyResPsthTb
	local level = self.model.showLevel or self.model.level

	local function initBarPanel(isShield)
		local str = "hpBarPanel"
		local barPanel = pnode:get(str):clone()
		local sz = barPanel:get("di"):size()
		local halfWidth = sz.width / 2
		local halfHeight = sz.height / 2

		barPanel:addTo(self, 4):xy(-halfWidth, halfHeight)
		barPanel:get("level"):setString(level)

		return barPanel
	end

	self.barPanelS = initBarPanel(true)

	local size = self.barPanelS:get("di"):size()

	self.buffAddFirstPos = cc.p(-size.width / 2 + 70, 62)

	local unitCfg = self.model.unitCfg

	self:setPosition(unitCfg.everyPos.lifePos)
	self:setScale(unitCfg.lifeScale)

	self.canSetVisible = true
	self.lifeBarVisible = battleEasy.priorDataTable(true, "lifeBarVisible")
	self.updateCount = 1
	self.oldShieldMul = 0
	self.shieldMul = 0

	local function barPanelInit(curBarPanel)
		self.lastPer = {
			mpOverflowPer = 0,
			shieldPer = 0,
			mpPer = 0,
			hpPer = 0,
			assimilatePer = 0
		}

		curBarPanel:get("shieldBar"):setPercent(0)
		curBarPanel:get("hpBar"):setPercent(0)
		curBarPanel:get("mpBar"):setPercent(0)
		curBarPanel:get("mpOverflowBar"):setPercent(0)
		curBarPanel:get("assimilateBar"):setPercent(0)
		curBarPanel:get("shieldMulMark"):visible(false)
		curBarPanel:get("iconShield"):visible(false)
		curBarPanel:get("comboBar"):visible(false)

		local universalBar = curBarPanel:get("universalBar")

		universalBar:visible(false)
		universalBar:get("baseBar_prg"):setPercent(0)
		universalBar:get("coverBar_prg"):setPercent(0)

		local barCapture = CRenderSprite.newWithNodes(cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444, curBarPanel)

		barCapture:addTo(self, 5):coverTo(curBarPanel):setCaptureOffest(cc.p(0, 13))

		return barCapture
	end

	self.barCaptureS = barPanelInit(self.barPanelS)
	self.mulMarkCover = self:creatMulMarkCover(self.barPanelS:get("shieldBar"))
	self.specialShieldBar = nil
	self.spineShieldBar = nil
	self.comboBar = nil
	self.universalResPath = nil
end

local function calcWith(args)
	local hp = args.hp
	local hpMax = args.hpMax
	local shieldHpMax = args.shieldHpMax
	local shieldHp = args.shieldHp
	local delayHp = args.delayHp
	local assimilateHp = args.assimilateHp
	local specialShieldHp = args.specialShieldHp
	local barrierHp = args.barrierData.hp
	local freezeHp = args.freezeHp
	local universalHp = args.universalBarData.val
	local universalCurMax = args.universalBarData.curMax
	local universalMax = args.universalBarData.max
	local hpPer, shieldPer, delayPer, assimilatePer, barrierPer, freezePer = 0, 0, 0, 0, 0, 0
	local universalPer, universalTotalPer = 0, 0
	local maxProgress = hpMax < hp + assimilateHp and hp + assimilateHp or hpMax
	local minHpPer = math.min(hp / hpMax * 100, 10)

	delayHp = cc.clampf(delayHp, 0, hp)
	delayPer = hp / maxProgress * 100
	hpPer = (hp - delayHp) / maxProgress * 100

	if delayPer < minHpPer then
		delayPer = minHpPer
		hpPer = (hp - delayHp) / hp * minHpPer
	end

	assimilatePer = (hp + assimilateHp) / maxProgress * 100
	barrierPer = barrierHp / maxProgress * 100
	freezePer = freezeHp / maxProgress * 100
	universalPer = universalCurMax > 0 and universalHp / universalMax * 100 or 0
	universalTotalPer = universalMax > 0 and universalCurMax / universalMax * 100 or 0

	local specialShieldStatus = specialShieldHp > 0

	shieldPer = cc.clampf(shieldHp / shieldHpMax * 100, 5, 100)
	args.shieldMulNum = math.ceil(shieldHp / shieldHpMax)
	args.shieldMulMark = shieldHp % shieldHpMax / shieldHpMax
	args.hpPer = hpPer
	args.shieldPer = shieldPer
	args.shieldStatus = shieldHp > 0
	args.delayPer = delayPer
	args.delayStatus = delayHp > 0
	args.assimilatePer = assimilatePer
	args.assimilateStatus = assimilateHp > 0
	args.specialShieldStatus = specialShieldStatus
	args.barrierPer = barrierPer
	args.barrierStatus = barrierHp > 0
	args.freezePer = freezePer
	args.freezeStatus = freezeHp > 0
	args.universalPer = math.ceil(universalPer)
	args.universalTotalPer = math.ceil(universalTotalPer)
	args.universalStatus = args.universalBarData.active
end

function CLifeBar:updatePoint(args)
	local mp1OverflowData = args.mp1OverflowData
	local buffOverLayData = args.buffOverLayData

	if not mp1OverflowData and not buffOverLayData then
		return
	end

	local effectData
	local onlyRemove = true
	local point, pointLimit

	if mp1OverflowData and mp1OverflowData.mode == 1 then
		point = math.floor(args.mpOverflow / mp1OverflowData.rate)
		pointLimit = math.floor(mp1OverflowData.limit / mp1OverflowData.rate)
		effectData = mp1OverflowData.effectData or {}
		onlyRemove = false
	elseif buffOverLayData and buffOverLayData.overlayCount > 0 then
		point = buffOverLayData.overlayCount
		pointLimit = buffOverLayData.overlayLimit
		effectData = buffOverLayData.effectData or {}
		onlyRemove = false
	end

	self:removeChildByName("pointNode")

	if onlyRemove then
		return
	end

	local barSize = self.barPanelS:get("mpBar"):size()
	local _, barY = self.barPanelS:get("mpBar"):xy()
	local offsetX = effectData.offsetX or -72
	local offsetY = effectData.offsetY or 8
	local pointNode = cc.Node:create()

	self:addChild(pointNode, 10, "pointNode")

	local interval = barSize.width / pointLimit
	local res = effectData.res or "buff/nuqidian/nuqidian.skel"
	local emptyAction = effectData.emptyAction or "kong_effect_loop"
	local activeAction = effectData.activeAction or "jihuo_effect_loop"
	local hideEmptyPoint = effectData.hideEmptyPoint or false

	for i = 1, math.max(point, pointLimit) do
		local action = i <= point and activeAction or emptyAction

		widget.addAnimationByKey(pointNode, res, "pointLimit" .. i, action, 10):xy(interval * i + offsetX, barY + offsetY):scale(2)

		if i == point and hideEmptyPoint then
			break
		end
	end
end

function CLifeBar:update(args)
	if args.needCalc then
		calcWith(args)

		self.specialShieldStatus = args.specialShieldStatus
	end

	local hpPer, shieldPer, shieldStatus = args.hpPer, args.shieldPer, args.shieldStatus
	local delayPer, delayStatus = args.delayPer, args.delayStatus
	local assimilatePer, assimilateStatus = args.assimilatePer, args.assimilateStatus
	local barrierPer, barrierStatus = args.barrierPer, args.barrierStatus
	local freezePer, freezeStatus = args.freezePer, args.freezeStatus
	local universalPer, universalTotalPer, universalStatus, universalResPath, universalTime

	if args.universalBarData then
		universalPer, universalTotalPer, universalStatus, universalResPath, universalTime = args.universalPer, args.universalTotalPer, args.universalStatus, args.universalBarData.resPath, args.universalBarData.time
	end

	local curBarPanel = self.barPanelS

	local function doCaptureShow()
		self.updateCount = self.updateCount - 1

		if self.updateCount > 0 then
			return
		end

		if not self.specialShieldStatus and not self.spineShieldBar and not self.barrierBar and not self.freezeHpBar then
			self.barCaptureS:show()
		end
	end

	local function checkBarStatus(barName, status)
		local curBar = curBarPanel:get(barName)
		local barVisible = curBar:visible()

		status = status or false

		if status ~= barVisible then
			curBar:visible(status)

			self.updateCount = self.updateCount + 1

			performWithDelay(self, doCaptureShow, 0)
		end
	end

	local function setBarPercent(barName, barPer, recordName)
		if not barPer then
			return
		end

		local perInt = math.ceil(barPer)

		if self.lastPer[recordName] ~= perInt then
			self.lastPer[recordName] = perInt
			self.updateCount = self.updateCount + 1

			transition.executeSequence(curBarPanel:get(barName)):progressTo(0.1, barPer):func(doCaptureShow):done()
		end
	end

	checkBarStatus("delayBar", delayStatus)
	checkBarStatus("assimilateBar", assimilateStatus)
	setBarPercent("hpBar", hpPer, "hpPer")
	setBarPercent("delayBar", delayPer, "delayPer")
	setBarPercent("assimilateBar", assimilatePer, "assimilatePer")

	if args.mp and not self:updateComboPoint() then
		local mp = args.mp
		local mpMax = args.mpMax
		local mpOverflow = args.mpOverflow
		local mpPer, mpOverflowPer = 0, 0
		local mp1OverflowData = args.mp1OverflowData
		local mpBarSpriteYLerp = 5

		mpPer = math.min(mp + mpOverflow, mpMax) / mpMax * 100
		mpOverflowPer = math.min(mpOverflow, mpMax) / mpMax * 100

		local mpOverflowStatus = (not mp1OverflowData or mp1OverflowData and mp1OverflowData.mode ~= 1) and mpOverflow > 0
		local realMpPer = mp / mpMax * 100

		checkBarStatus("mpOverflowBar", mpOverflowStatus)
		setBarPercent("mpBar", mpPer, "mpPer")

		if realMpPer >= 100 then
			local sz = curBarPanel:get("di"):size()
			local halfWidth = sz.width / 2
			local halfHeight = sz.height / 2
			local mankuangEffect = "xuetiao_mankuang_loop"

			if mpOverflowStatus then
				curBarPanel:get("mpBar"):setScaleY(1.5)
				curBarPanel:get("mpOverflowBar"):setScaleY(1.5)

				mankuangEffect = "xuetiao_mankuang2_loop"
			end

			widget.addAnimationByKey(self, battle.SpriteRes.mainSkill, "mpBarSprite", "xuetiao_mankuang", 10):xy(halfWidth - 110, halfHeight - 100 + mpBarSpriteYLerp):addPlay(mankuangEffect)
		else
			curBarPanel:get("mpBar"):setScaleY(1)
			curBarPanel:get("mpOverflowBar"):setScaleY(1)
			self:removeChildByName("mpBarSprite")
		end

		setBarPercent("mpOverflowBar", mpOverflowPer, "mpOverflowPer")
		self:updatePoint(args)
	end

	local function setShieldMul()
		self.shieldMul = args.shieldMulNum

		local mulNum = args.shieldMulNum
		local mulMark = args.shieldMulMark
		local shieldBar = self.barPanelS:get("shieldBar")
		local mulMarkNode = self.mulMarkCover:get("shieldMulMark")

		mulMarkNode:visible(mulNum > 1)
		self:updateShieldMulNum()

		local width = shieldBar:size().width

		mulMarkNode:stopAllActions()

		local function setOldShieldMul()
			self.oldShieldMul = mulNum

			doCaptureShow()
		end

		self.updateCount = self.updateCount + 1

		if mulNum > self.oldShieldMul then
			transition.executeSequence(mulMarkNode):moveTo(0.1, width):moveTo(0.05, 0):moveTo(0.1, mulMark * width):func(setOldShieldMul):done()
		elseif mulNum < self.oldShieldMul then
			transition.executeSequence(mulMarkNode):moveTo(0.1, 0):moveTo(0.05, width):moveTo(0.1, mulMark * width):func(setOldShieldMul):done()
		else
			transition.executeSequence(mulMarkNode):moveTo(0.1, mulMark * width):func(setOldShieldMul):done()
		end
	end

	if args.shieldHp then
		setShieldMul()
		checkBarStatus("shieldBar", shieldStatus, true)
		setBarPercent("shieldBar", shieldPer, "shieldPer", true)

		if not self:updateSpineShield(shieldStatus, shieldPer) then
			if self.specialShieldStatus then
				local sz = self.barPanelS:get("di"):size()
				local shieldBar = self.barPanelS:get("shieldBar")
				local halfWidth = sz.width / 2
				local halfHeight = sz.height / 2

				self.barPanelS:get("shieldBar"):setOpacity(0)
				self:switchMulMarkType(battle.SpriteRes.fireShield, "yichu_loop", 1, 5, cc.p(-20, 55))

				self.specialShieldBar = self.specialShieldBar or self:createSpineClip("shieldBar", "specialShield", 6)

				local sprite = self.specialShieldBar:get("shieldBarSprite")

				sprite = sprite or widget.addAnimationByKey(self.specialShieldBar, battle.SpriteRes.fireShield, "shieldBarSprite", "xuetiao_loop", 6):align(cc.p(0.5, 0.5)):setScaleY(1.7):xy(0, -5):addPlay("xuetiao_loop")

				local direction = shieldBar:getDirection()
				local x = shieldBar:width() * (1 - shieldPer / 100) * (-1 + direction * 2)

				sprite:stopAllActions()
				sprite:runAction(cc.MoveTo:create(0.1, cc.p(x, sprite:y())))
			else
				self.barPanelS:get("shieldBar"):setOpacity(255)
				self:switchMulMarkType()
				self.barPanelS:removeChildByName("specialShield")

				self.specialShieldBar = nil
			end
		end
	end

	if args.barrierData then
		if barrierStatus then
			local hpBar = self.barPanelS:get("hpBar")
			local hpBox = hpBar:getBoundingBox()
			local leftBarrier = hpBox.width * (1 - barrierPer / 100)

			self.barrierBar = self.barrierBar or self:createSpineClipWithSprite("hpBar", "barrierNode", 6, heroResPsthTb.mHp, 0.3, {
				x = 1,
				y = 1.5
			})

			local sprite = self.barrierBar:get("barrierBarSprite")

			if not sprite then
				sprite = widget.addAnimationByKey(self.barrierBar, battle.SpriteRes.freezeHp, "barrierBarSprite", "ningbing_loop", 6)

				sprite:align(cc.p(0.5, 0.5)):setScaleY(-2):setScaleX(1.08):setOpacity(args.barrierData.opacity):x(-hpBox.width):addPlay("ningbing_loop")
				sprite:stopAllActions()
				sprite:runAction(cc.MoveTo:create(0.1, cc.p(-leftBarrier, sprite:y())))

				self.barrierLastPos = sprite:x()
			elseif math.abs(leftBarrier - self.barrierLastPos) > 1e-05 then
				self.barrierLastPos = leftBarrier

				sprite:stopAllActions()
				sprite:runAction(cc.MoveTo:create(0.1, cc.p(-leftBarrier, sprite:y())))
			end
		elseif self.barrierBar then
			self.barrierBar:removeChildByName("barrierBarSprite")
			self.barPanelS:removeChildByName("barrierNode")

			self.barrierBar = nil
			self.barrierLastPos = 0
		end
	end

	if args.freezeHp then
		if freezeStatus then
			local hpBar = self.barPanelS:get("hpBar")
			local freezeLeft = hpBar:width()

			self.freezeHpBar = self.freezeHpBar or self:createSpineClipWithSprite("hpBar", "freezeNode", 7, heroResPsthTb.mHp)

			local sprite = self.freezeHpBar:get("freezeHpBarSprite")

			if not sprite then
				sprite = widget.addAnimationByKey(self.freezeHpBar, battle.SpriteRes.freezeHp, "freezeHpBarSprite", "dongxue_loop", 7)

				sprite:align(cc.p(0.5, 0.5)):setScaleY(2):xy(hpBar:width(), 0):addPlay("xuetiao_loop")
			end

			local x = hpBar:width() * (1 - freezePer / 100)

			sprite:stopAllActions()
			sprite:runAction(cc.MoveTo:create(0.1, cc.p(x, sprite:y())))
		else
			self.barPanelS:removeChildByName("freezeNode")

			self.freezeHpBar = nil
		end
	end

	local universalBar = curBarPanel:get("universalBar")

	if universalStatus then
		universalBar:visible(true)

		if self.universalResPath ~= universalResPath then
			local coverBar = universalBar:get("coverBar_prg")

			coverBar:setScale9Enabled(true)
			coverBar:loadTexture(universalResPath)

			local texture = coverBar:getVirtualRenderer():getTexture()
			local originalSize = texture:getContentSize()
			local halfWidth = math.ceil(originalSize.width / 2)
			local halfHeight = math.ceil(originalSize.height / 2)
			local capInsets = cc.rect(halfWidth, halfHeight, 1, halfHeight)

			coverBar:setCapInsets(capInsets)
			coverBar:size(universalMaxLen, originalSize.height)

			self.universalResPath = universalResPath
		end

		transition.executeSequence(universalBar:get("coverBar_prg")):progressTo(universalTime, universalPer):done()
		transition.executeSequence(universalBar:get("baseBar_prg")):progressTo(universalTime, universalTotalPer):done()
	else
		universalBar:visible(false)
	end

	if self.updateCount > 0 then
		self.barCaptureS:hide()
	end
end

function CLifeBar:setVisibleEnable(enable)
	self.canSetVisible = enable
end

function CLifeBar:setVisible(visible)
	if not self.canSetVisible then
		return
	end

	cc.Node.setVisible(self, visible)
end

function CLifeBar:onSetLifebarVisible(visible, reason, isOver)
	self.lifeBarVisible:set(visible, reason, isOver)
	self:setVisible(self.lifeBarVisible:get())
end

function CLifeBar:creatMulMarkCover(shieldBar)
	local shieldCover = self.barPanelS:get("mulMarkCover")

	if shieldCover then
		return shieldCover
	end

	shieldCover = ccui.Layout:create()

	shieldCover:setBackGroundImage(shieldResPathTb.shield)

	local width, height = shieldCover:getBackGroundImageTextureSize().width, shieldCover:getBackGroundImageTextureSize().height

	shieldCover:setContentSize(cc.size(width, height + 8))
	shieldCover:setClippingEnabled(true)
	shieldCover:setBackGroundImageOpacity(0)
	shieldCover:setName("mulMarkCover")
	shieldCover:addTo(self.barPanelS, 10)
	shieldCover:align(cc.p(0.5, 0.5), shieldBar:x(), shieldBar:y())

	local shieldMulMark = self.barPanelS:get("shieldMulMark")

	shieldMulMark:removeFromParent()
	shieldMulMark:addTo(shieldCover)
	shieldMulMark:xy(0, 7)

	return shieldCover
end

function CLifeBar:switchMulMarkType(res, action, scaleX, scaleY, offsetPos)
	local shieldMulMark = self.mulMarkCover:get("shieldMulMark")

	if not res then
		shieldMulMark:setOpacity(255)
		shieldMulMark:removeChildByName("specialMulMark")
	else
		offsetPos = offsetPos or cc.p(0, 0)
		scaleX = scaleX or 1
		scaleY = scaleY or 1

		shieldMulMark:setOpacity(0)

		local sprite = CSprite.new(res)

		sprite:play(action)
		sprite:addTo(shieldMulMark, 1):align(cc.p(1, 0.5), offsetPos.x, offsetPos.y):setScaleX(scaleX):setScaleY(scaleY):setVisible(true)
		sprite:setName("specialMulMark")
	end
end

function CLifeBar:onShowIconShield()
	local iconShield = self:onHideIconShield()
	local sz = iconShield:size()
	local halfWidth = sz.width / 2
	local halfHeight = sz.height / 2
	local textNode = cc.Label:createWithTTF(self.shieldMul, "font/youmi1.ttf", 36)

	textNode:enableOutline(cc.c4b(0, 0, 0, 255), 1):setAnchorPoint(cc.p(0.5, 0.5)):addTo(iconShield):xy(halfWidth, halfHeight):setName("shieldMulNum")
	iconShield:visible(self.shieldMul > 0)

	return iconShield
end

function CLifeBar:onHideIconShield()
	local iconShield = self.barPanelS:get("iconShield")
	local textNode = iconShield:get("shieldMulNum")

	if textNode then
		textNode:removeFromParent()
	end

	iconShield:visible(false)

	return iconShield
end

function CLifeBar:updateShieldMulNum()
	local iconShield = self.barPanelS:get("iconShield")
	local textNode = iconShield:get("shieldMulNum")

	if textNode then
		textNode:setString(self.shieldMul)
		iconShield:visible(self.shieldMul > 0)
	end
end

function CLifeBar:boundingBoxVisible(node, boxColor, boxThickness, centerColor, centerSize)
	boxColor = boxColor or cc.c4b(1, 1, 0, 0.2)
	boxThickness = boxThickness or 1
	centerColor = centerColor or cc.c4b(1, 0, 0, 1)
	centerSize = centerSize or 1

	local box = node:getBoundingBox()
	local nodeList = {
		cc.p(-box.width / 2, -box.height / 2),
		cc.p(-box.width / 2, box.height / 2),
		cc.p(box.width / 2, box.height / 2),
		cc.p(box.width / 2, -box.height / 2)
	}
	local drawnode = cc.DrawNode:create()

	drawnode:drawPolygon(nodeList, #nodeList, cc.c4b(1, 0, 0, 0.2), boxThickness, boxColor)

	local center = cc.DrawNode:create()

	center:drawDot(cc.p(0, 0), centerSize, centerColor)

	return drawnode, center
end

function CLifeBar:createSpineClipWithSprite(toBarNode, nodeName, layer, imgPath, threshold, scale)
	local barNode = self.barPanelS:get(toBarNode)
	local stencil = cc.Sprite:create(imgPath)

	scale = scale or {
		x = 1,
		y = 1
	}

	stencil:scaleX(scale.x)
	stencil:scaleY(scale.y)

	local clipNode = cc.ClippingNode:create(stencil)

	threshold = threshold or 0.5

	clipNode:setAlphaThreshold(threshold)
	clipNode:addTo(self.barPanelS, layer):align(cc.p(0.5, 0.5), barNode:x(), barNode:y()):setName(nodeName):setVisible(true)

	return clipNode
end

function CLifeBar:createSpineClip(toBarNode, nodeName, layer)
	local barNode = self.barPanelS:get(toBarNode)
	local box = barNode:getBoundingBox()
	local height = 100
	local width = box.width / 2
	local nodeList = {
		cc.p(-width, -height),
		cc.p(-width, height),
		cc.p(width, height),
		cc.p(width, -height)
	}
	local drawnode = cc.DrawNode:create()

	drawnode:drawPolygon(nodeList, #nodeList, cc.c4b(1, 1, 0, 0), 1, cc.c4b(0, 1, 0, 1))

	local clipNode = cc.ClippingNode:create(drawnode)

	clipNode:addTo(self.barPanelS, layer):align(cc.p(0.5, 0.5), barNode:x(), barNode:y()):setName(nodeName):setVisible(true)

	return clipNode
end

function CLifeBar:onAddSpineShield(args)
	self:onDelSpineShield()

	local aniRes, action = args.resPath, args.aniName
	local offsetPos = args.offSet or cc.p(0, 0)
	local scaleX = args.scaleX or 1
	local scaleY = args.scaleY or 1
	local mulMarkAniRes, mulMarkAction = args.mulMarkResPath, args.mulMarkAniName
	local mulMarkOffsetPos = args.mulMarkOffSet
	local mulMarkScaleX = args.mulMarkScaleX
	local mulMarkScaleY = args.mulMarkScaleY
	local shieldBar = self.barPanelS:get("shieldBar")

	shieldBar:setOpacity(0)
	self:switchMulMarkType(mulMarkAniRes, mulMarkAction or "yichu_loop", mulMarkScaleX, mulMarkScaleY, mulMarkOffsetPos)

	local per = shieldBar:getPercent()
	local isShow = shieldBar:isVisible()

	self.spineShieldBar = self:createSpineClip("shieldBar", "spineShieldBar", 8)

	local sprite = CSprite.new(aniRes)

	sprite:play(action or "effect")
	sprite:addTo(self.spineShieldBar):align(cc.p(0.5, 0.5), offsetPos.x, offsetPos.y):scaleX(scaleX):scaleY(scaleY):setVisible(true)
	sprite:setName("barSpine")
	self:updateSpineShield(isShow, per)
end

function CLifeBar:onDelSpineShield()
	if not self.spineShieldBar then
		return
	end

	self:switchMulMarkType()
	self.barPanelS:get("shieldBar"):setOpacity(255)
	self.spineShieldBar:removeFromParent()

	self.spineShieldBar = nil
end

function CLifeBar:updateSpineShield(status, per)
	if not self.spineShieldBar then
		return
	end

	status = status and true or false

	if self.spineShieldBar:isVisible() ~= status then
		self.spineShieldBar:setVisible(status or false)
	end

	if not per then
		return
	end

	local perInt = math.ceil(per)

	if self.lastPer.shieldBar == perInt then
		return
	end

	local shieldBar = self.barPanelS:get("shieldBar")
	local direction = shieldBar:getDirection()
	local x = shieldBar:width() * (1 - per / 100) * (-1 + direction * 2)
	local sprite = self.spineShieldBar:get("barSpine")

	sprite:stopAllActions()
	sprite:runAction(cc.MoveTo:create(0.1, cc.p(x, sprite:y())))

	return true
end

function CLifeBar:showComboBar(args)
	self.barPanelS:get("mpBar"):setPercent(0)
	self.barPanelS:get("mpOverflowBar"):setPercent(0)
	self:removeChildByName("mpBarSprite")

	local comboBar = self.barPanelS:get("comboBar")

	comboBar:visible(true)

	local sz = comboBar:size()
	local width = sz.width
	local height = sz.height
	local pointLimit = args.overlayLimit
	local pointWidth = width / pointLimit
	local line = cc.DrawNode:create()

	line:addTo(comboBar, 2, "lines"):setContentSize(width, height):align(cc.p(0.5, 0.5), width / 2, height / 2):setLineWidth(1)

	for i = 1, args.overlayLimit - 1 do
		local x = i * pointWidth

		line:drawLine(cc.p(x, 0), cc.p(x, height), cc.c4f(0.52, 0.29, 0.2, 1))
	end

	self.comboBar = comboBar

	return comboBar
end

function CLifeBar:updateComboPoint(args)
	if not args then
		if not self.comboBar then
			return false
		else
			return true
		end
	end

	args.overlayCount = math.max(args.overlayCount - 1, 0)
	args.overlayLimit = args.overlayLimit - 1

	if not self.comboBar then
		self:showComboBar(args)
	end

	self.comboBar:get("comboBarCover"):show():setPercent((1 - args.overlayCount / args.overlayLimit) * 100)
	self:updateHighLightPoint(args)

	return true
end

function CLifeBar:updateHighLightPoint(args)
	local limit = args.overlayLimit
	local count = args.overlayCount
	local effectData = args.effectData or {}
	local highLightLimit = effectData.highLightLimit or 0
	local res = effectData.res or "buff/nuqidian/nuqidian.skel"
	local emptyAction = effectData.emptyAction or "kong_effect_loop"
	local activeAction = effectData.activeAction or "jihuo_effect_loop"
	local hideEmptyPoint = effectData.hideEmptyPoint or true

	if not self.comboBar or highLightLimit == 0 then
		return
	end

	local sz = self.comboBar:size()
	local width = sz.width
	local height = sz.height
	local offset = effectData.offset or cc.p(0, 0)
	local scale = effectData.scale or 1.5

	local function createHighLightPoint(i, name, active, hideEmptyPoint)
		local pointWidth = width / limit
		local x = pointWidth * (i * highLightLimit - 1) + pointWidth / 2
		local y = height / 2
		local isVisible = active or not hideEmptyPoint
		local action = active and activeAction or emptyAction

		widget.addAnimationByKey(self.comboBar, res, name, action, 10):xy(x + offset.x, y + offset.y):scale(scale):visible(isVisible)
	end

	local numLimit = math.floor(limit / highLightLimit)
	local num = math.floor(count / highLightLimit)

	for i = 1, numLimit do
		local name = "highLight" .. i

		self.comboBar:removeChildByName(name)
		createHighLightPoint(i, name, i <= num, hideEmptyPoint)
	end
end
