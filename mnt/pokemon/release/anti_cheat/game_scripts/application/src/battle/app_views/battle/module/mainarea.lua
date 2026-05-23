-- chunkname: @src.battle.app_views.battle.module.mainarea

local ASSIGN_LAYER_TYPE = {
	[0] = "stageLayer",
	"effectLayerLower",
	"gameLayer",
	nil,
	"frontStageLayer"
}
local teamNumToStringTb = {
	gLanguageCsv.firstTeam,
	gLanguageCsv.secondTeam,
	gLanguageCsv.thirdTeam,
	gLanguageCsv.fourthTeam,
	gLanguageCsv.fifthTeam,
	gLanguageCsv.sixthTeam,
	gLanguageCsv.seventhTeam,
	gLanguageCsv.eighthTeam,
	gLanguageCsv.ninthTeam,
	gLanguageCsv.tenthTeam
}

require("battle.models.skill.helper")

local _insert = table.insert
local _format = string.format
local MainArea = class("MainArea", battleModule.CBase)

function MainArea:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.isFirstEnter = true
	self.preNumber = 0
	self.sumNumber = 0
	self.showNumberType = nil
	self.mp1AwardCount = {}

	for i = 1, battlePlay.Gate.ObjectNumber do
		self.mp1AwardCount[i] = 0
	end

	self.damangeSumSprite = cc.Sprite:create(battle.MainAreaRes.txtZsh)
	self.hpSumSprite = cc.Sprite:create(battle.MainAreaRes.txtZzl)
	self.sumSprite = nil

	self.damangeSumSprite:hide():z(999):anchorPoint(1, 0.5):addTo(self.parent.effectLayer)
	self.hpSumSprite:hide():z(999):anchorPoint(1, 0.5):addTo(self.parent.effectLayer)

	self.damageSumLabel = ccui.Layout:create():z(1099):addTo(self.parent.effectLayer):hide()
	self.hpSumLabel = ccui.Layout:create():z(1099):addTo(self.parent.effectLayer):hide()
	self.sumLabel = nil
	self.sumLabelNum = idler.new(0)

	bind.extend(self.parent, self.damageSumLabel, {
		class = "text_atlas",
		props = {
			align = "center",
			isEqualDist = false,
			data = self.sumLabelNum,
			pathName = battle.MainAreaRes.fontZsh
		}
	})
	bind.extend(self.parent, self.hpSumLabel, {
		class = "text_atlas",
		props = {
			align = "center",
			isEqualDist = false,
			data = self.sumLabelNum,
			pathName = battle.MainAreaRes.fontZzl
		}
	})

	local di = cc.Sprite:create(battle.MainAreaRes.diZzl)

	di:addTo(self.hpSumLabel, -100):anchorPoint(0.5, 0.5)

	self.hpDiWidth = di:width()
	self.showSwitch = {
		showNumber = true
	}
	self.roundLabelNode = self.parent.UIWidgetMid:get("widgetPanel.topinfo.round")
	self.hits = {}

	for i = 1, battlePlay.Gate.ObjectNumber do
		local panel = ccui.Layout:create()

		panel:setTag(i)
		panel:setName("hitPanel" .. i)
		panel:setAnchorPoint(cc.p(0.5, 0.5))
		self.parent.layer:add(panel, 101)
		panel:setContentSize(cc.size(300, 300))
		panel:setVisible(false)

		panel.showAttrPanelFlag = true
		panel.canChooseObjFlag = false

		panel:onClick(function()
			local objSeat = i
			local spr = self:call("getSceneObjBySeat", objSeat)

			if spr and not spr.model:isDeath() then
				if panel.showAttrPanelFlag and false then
					self.parent.objAttrPanel:showPanel(spr)
				elseif panel.canChooseObjFlag then
					self:notify("selectObj", spr)
				end
			end
		end)

		self.hits[i] = panel
	end

	local showInfoPVP = self.parent:isPVPScene()

	if self.parent:isPVEScene() then
		showInfoPVP = false

		if self.parent:isBossScene() then
			self.roundLabelNode:hide()
		end
	elseif self.parent:isPVPScene() and self.parent:isSepcPVPScene() then
		showInfoPVP = false
	end

	if showInfoPVP then
		local gateReplacePanelBg = {
			[game.GATE_TYPE.battlebet] = {
				"battle/panel_role.png",
				"battle/panel_role_b.png"
			},
			[game.GATE_TYPE.contestbet] = {
				"battle/panel_role.png",
				"battle/panel_role_b.png"
			}
		}
		local t = self.parent.data

		t.names = t.names or {
			"leftPlayer",
			"rightPlayer"
		}
		t.levels = t.levels or {
			99,
			99
		}
		t.logos = t.logos or {
			1,
			1
		}

		local left, right = self.parent.UIWidgetLeft:get("infoPVP"), self.parent.UIWidgetRight:get("infoPVP")
		local panelBgTb = gateReplacePanelBg[t.gateType] or {}

		left:get("roleName"):setString(t.names[1] or "leftPlayer")
		left:get("level"):setString(t.levels[1] or 99)
		left:get("roleImg"):loadTexture(dataEasy.getRoleLogoIcon(t.logos[1]))
		right:get("roleName"):setString(t.names[2] or "rightPlayer")
		right:get("level"):setString(t.levels[2] or 99)
		right:get("roleImg"):loadTexture(dataEasy.getRoleLogoIcon(t.logos[2]))
		right:get("bg"):loadTexture(panelBgTb[2] or "battle/panel_role.png")

		if matchLanguage({
			"cn"
		}) then
			local leftLv, rightLv = left:get("levelLv"), right:get("levelLv")

			leftLv:text(gLanguageCsv.textLv)
			leftLv:xy(leftLv:x() - 18, leftLv:y() - 10)
			rightLv:text(gLanguageCsv.textLv)
			rightLv:xy(rightLv:x() - 18, rightLv:y() - 10)
		end

		self.renderLeftSpr = CRenderSprite.newWithNodes(cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444, left)
		self.renderRightSpr = CRenderSprite.newWithNodes(cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444, right)

		self.renderLeftSpr:addTo(self.parent.UIWidgetLeft):coverTo(left):show()
		self.renderRightSpr:addTo(self.parent.UIWidgetRight):coverTo(right):show()
	end

	self.explorerShowList = {
		{},
		[-1] = {}
	}
	self.showNumberCnt = 0

	self:captureScreen()
	self:onReduceTarget()
end

local function cleanData(data)
	data.lastBuffPos = {}
	data.lastBuffCount = 0
end

function MainArea:refreshInfoPvP(hideRT)
	if self.renderLeftSpr and self.renderRightSpr then
		self.renderLeftSpr:refresh()
		self.renderRightSpr:refresh()
	end
end

function MainArea:getObjHitPanel(objSeat)
	return self.hits[objSeat]
end

function MainArea:onPlayMainSkillEffect(objSeat)
	local spr = self:call("getSceneObjBySeat", objSeat)

	if spr then
		spr:playMainSkillEffect()
	end
end

function MainArea:onReduceTarget(seat, effectRes, effectAni)
	if seat then
		self.reduceEffectRes[seat] = effectRes
		self.reduceEffectAni[seat] = effectAni
	else
		self.reduceEffectRes = {}
		self.reduceEffectAni = {}
	end
end

function MainArea:onSelectSkill(skill, exactImmuneInfos)
	local targets = skill:getTargetsHint()
	local map = {}

	for _, target in ipairs(targets) do
		map[target.seat] = target
	end

	self:hideSkillTargetsHelpTips()

	local units = self:call("getSceneObjs")

	for key, spr in pairs(units) do
		local objModel = spr.model
		local objSeat = objModel.seat
		local hitPanel = self.hits[objSeat]

		if hitPanel then
			hitPanel.showAttrPanelFlag = false

			if map[objSeat] then
				local restraintType = skillHelper.natureRestraintType(skill:getSkillNatureType(), objModel, skill.owner:natureRestraint(), spr.model:natureResistance())
				local isShow = not skill.owner:isSameForce(map[objSeat].force)

				spr:showSkillSelectTextState(isShow, restraintType, exactImmuneInfos[objModel.id])

				hitPanel.canChooseObjFlag = true
			else
				spr:onAddCantSelect(self.reduceEffectRes[objSeat], self.reduceEffectAni[objSeat])
				spr:onShadeByShadow()

				hitPanel.canChooseObjFlag = false
			end
		end
	end
end

function MainArea:onSelectedHero()
	local units = self:call("getSceneObjs")

	for key, spr in pairs(units) do
		local objModel = spr.model
		local objSeat = objModel.seat
		local hitPanel = self.hits[objSeat]

		if hitPanel then
			hitPanel.showAttrPanelFlag = false
			hitPanel.canChooseObjFlag = false
		end

		spr:onAddCantSelect(self.reduceEffectRes[objSeat], self.reduceEffectAni[objSeat])
		spr:onShadeByShadow()
	end

	self:hideSkillTargetsHelpTips()
end

function MainArea:resetHitPanelStateToShowAttrsPanel()
	local units = self:call("getSceneObjs")

	for key, spr in pairs(units) do
		local objModel = spr.model
		local objSeat = objModel.seat
		local hitPanel = self.hits[objSeat]

		if hitPanel then
			hitPanel.showAttrPanelFlag = true
			hitPanel.canChooseObjFlag = false
		end
	end

	self:hideSkillTargetsHelpTips()
end

function MainArea:onHideAllObjsSkillTips()
	if self.enterShowCb then
		self.enterShowCb()
	end

	local units = self:call("getSceneObjs")

	for _, spr in pairs(units) do
		spr.natureQuan.canSelect:hide()
		spr.natureQuan.textDi:hide()
		spr.groundRingVisible:set(false)
		spr.groundRing:setVisible(spr.groundRingVisible:get())
	end
end

function MainArea:hideSkillTargetsHelpTips()
	local units = self:call("getSceneObjs")

	for _, spr in pairs(units) do
		local objModel = spr.model
		local objSeat = objModel.seat
		local hitPanel = self.hits[objSeat]

		if hitPanel then
			if hitPanel.showAttrPanelFlag == false then
				spr.natureQuan.canSelect:hide()
				spr.natureQuan.textDi:hide()
			else
				spr.natureQuan:setVisible(false)
			end
		end
	end
end

function MainArea:onShowSkillName(skillID)
	local skillName = csv.skill[skillID].skillName
end

function MainArea:onSetWaveNumber(curWave, waveLimit)
	local waveLabel = self.parent.UIWidgetMid:get("widgetPanel.wavePanel.wave")

	waveLabel:setString(_format(gLanguageCsv.theWave, curWave or 1, waveLimit or 1))
end

function MainArea:onPlayWaveAni(curWave, waveLimit, delTime)
	local str = _format(gLanguageCsv.theWave, curWave or 1, waveLimit or 1)
	local diTu = cc.Sprite:create(battle.MainAreaRes.waveDiTu):align(cc.p(0.5, 0.5), display.cx, display.cy):addTo(self.parent.layer, 998):scale(2)
	local label = cc.Label:createWithTTF(str, "font/youmi1.ttf", 50):align(cc.p(0.5, 0.5), display.cx, display.cy):addTo(self.parent.layer, 999, "waveText")

	text.addEffect(label, {
		color = ui.COLORS.NORMAL.WHITE
	})

	delTime = delTime or 1.2

	transition.executeSequence(diTu):delay(delTime):func(function()
		diTu:removeFromParent()
		label:removeFromParent()
	end):done()
end

function MainArea:setRoundNumber(curRound, roundLimit)
	curRound = math.max(math.min(curRound, roundLimit), 0)

	self.roundLabelNode:get("round"):setString(_format(gLanguageCsv.theRound, curRound, roundLimit))
end

local NoQRCodeGate = {
	[game.GATE_TYPE.experience] = true
}

function MainArea:captureScreen()
	local gateType = self.parent.data.gateType

	if NoQRCodeGate[gateType] then
		return
	end

	local action

	self.parent.UIWidgetFeedback:addTouchEventListener(function(sender, eventType)
		if eventType == ccui.TouchEventType.began then
			action = performWithDelay(self.parent, function()
				local size = self.parent.UIWidgetMid:size()
				local gameKey = gGameModel.role:read("game_key")
				local date = time.getFormatValue("%Y%m%d")
				local uid = gGameModel.role:read("uid")
				local battleID = stringz.bintohex(self.parent.data.battleID)
				local infoKey = gameKey .. "-" .. date .. "-" .. uid .. "-" .. battleID

				require("util.qrpng")

				local qrpath = writeQRcodeImage(infoKey)
				local qrspr = cc.Sprite:create(qrpath)

				qrspr:scale(1):xy(display.center.x, 200):addTo(self.parent.frontStageLayer, 999999, "qrcode")

				if not self.notifySaveRecord then
					gGameApp:requestServer("/game/feedback/battle", function(tb)
						return
					end)

					self.notifySaveRecord = true
				end

				action = nil

				performWithDelay(self.parent, function()
					qrspr:removeSelf()

					qrspr = nil
				end, 5)
			end, 1.2)
		elseif (eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled) and action then
			self.parent.UIWidgetFeedback:stopAction(action)

			action = nil
		end
	end)
end

function MainArea:onNewBattleTurnBefore(obj)
	if not self.isFirstEnter then
		self:notify("showHero", {
			typ = "showAll"
		})
	end
end

function MainArea:onNewBattleRoundTo(args)
	cleanData(self)
	self:onShowMain(true)
	self:showSKillUIWidgets(not args.isTurnAutoFight)

	local play = self.parent:getPlayModel()

	self:setRoundNumber(args.curRound, play.roundLimit)
	self:onHideAllObjsSkillTips()

	if not self.isFirstEnter then
		self:notify("showHero", {
			typ = "showAll",
			obj = tostring(args.obj)
		})
	else
		self.firstBattleObj = args.obj
	end

	for _, panel in pairs(self.hits) do
		panel.showAttrPanelFlag = true
		panel.canChooseObjFlag = false
	end
end

function MainArea:onObjMainSkill()
	for _, panel in pairs(self.hits) do
		panel.showAttrPanelFlag = false
	end
end

function MainArea:onShowMain(isShow)
	self.parent.UIWidgetLeft:setVisible(isShow)
	self.parent.UIWidgetRight:setVisible(isShow)
	self.parent.UIWidgetMid:get("widgetPanel"):setVisible(isShow)
	self.parent.UIWidgetBottomRight:setVisible(isShow)

	local battleView = self.parent

	if self.parent.DEBUG_BATTLE_HIDE then
		return
	end

	local function effectResManagerVisible(key)
		for resKey, effectInfo in battleView.effectResManager:pairs(key) do
			if effectInfo.spr then
				if isShow then
					effectInfo.spr:setVisible(battleView.effectResManager:getKeyInResInfoBy(key, resKey, "visible", "last"))
				else
					effectInfo.spr:setVisible(isShow)
				end
			end
		end
	end

	effectResManagerVisible(battle.EffectResType.BuffEffectInNormal)
	effectResManagerVisible(battle.EffectResType.BuffEffectInForceSelf)
	effectResManagerVisible(battle.EffectResType.BuffEffectInForceEnemy)
end

function MainArea:onSetUltAccEnable(enable)
	local isAcc = self.parent.inUltAcc

	self.parent.ultAccEnable = enable

	if isAcc and not enable then
		self.parent:handleOperation(battle.OperateTable.ultAccEnd)
	end
end

function MainArea:showSKillUIWidgets(isShow)
	local widget = self.parent.UIWidgetBottomRight

	widget:setVisible(isShow)
end

function MainArea:onShowNumber(args)
	local function closeFunc(delayMark)
		if delayMark and delayMark ~= self.showNumberCnt then
			return
		end

		if self.showSwitch.showNumber then
			return
		end

		if self.sumSprite then
			self.sumSprite:hide()

			self.sumSprite = nil
		end

		if self.sumLabel then
			self.sumLabel:hide():unscheduleUpdate()

			self.sumLabel = nil
		end

		self.preNumber = 0
		self.sumNumber = 0
		self.showNumberType = nil
		self.showSwitch.showNumber = true
	end

	if self.parent.DEBUG_BATTLE_HIDE then
		self.damangeSumSprite:hide()
		self.hpSumSprite:hide()
		self.damageSumLabel:hide():unscheduleUpdate()
		self.hpSumLabel:hide():unscheduleUpdate()

		return
	end

	if not self.showSwitch.showNumber then
		self.showNumberCnt = self.showNumberCnt + 1

		closeFunc()
	end

	if args.close then
		self.showSwitch.showNumber = false

		transition.executeSequence(self.parent.effectLayer):delay(1.5):func(functools.partial(closeFunc, self.showNumberCnt)):done()

		return
	end

	self.sumNumber = self.sumNumber + (args.delta or 0)

	local needInit = not self.sumSprite or self.showNumberType ~= args.typ

	if not needInit then
		return
	end

	self.damangeSumSprite:hide()
	self.hpSumSprite:hide()
	self.damageSumLabel:hide():unscheduleUpdate()
	self.hpSumLabel:hide():unscheduleUpdate()

	if args.typ == battle.SkillSegType.damage then
		self.sumSprite = self.damangeSumSprite
		self.sumLabel = self.damageSumLabel
	elseif args.typ == battle.SkillSegType.resumeHp then
		self.sumSprite = self.hpSumSprite
		self.sumLabel = self.hpSumLabel
	end

	local function changeLabelNumber(dt)
		local pre, sum = self.preNumber, self.sumNumber
		local delta = math.floor((sum - pre) * dt * 10 + 1)

		self.sumLabelNum:set(pre)

		self.preNumber = math.min(pre + delta, sum)
	end

	assert(self.sumSprite, string.format("type %s is error", args.typ))
	self.sumSprite:show()
	self.sumLabelNum:set(0)
	self.sumLabel:show():scheduleUpdate(changeLabelNumber)

	self.showNumberType = args.typ
	self.preNumber = 0
	self.sumNumber = args.delta or 0

	local yMove = 130
	local w = self.sumSprite:width()
	local offPos = csv.skill[args.skillId].hurtPos
	local x = display.cx + offPos.x
	local y = display.cy / 4 + offPos.y

	if args.typ == battle.SkillSegType.damage then
		local w1 = 320
		local w2 = 370
		local numW = self.sumLabel.panel:width()
		local w3 = w2 / 2

		if w2 < numW then
			w3 = numW / 2
		end

		self.sumLabel:xy(x - w / 2 + w1 + w3, y - 20 + yMove)
		self.sumSprite:xy(x + w / 2, y + yMove)
	elseif args.typ == battle.SkillSegType.resumeHp then
		local w1 = self.hpDiWidth
		local numW = self.sumLabel.panel:width()
		local w2 = w1 / 2

		if w1 < numW then
			w2 = numW / 2
		end

		self.sumLabel:xy(x + w2, y - 15 + yMove)
		self.sumSprite:xy(x, y + yMove)
	end
end

function MainArea:onShowMP1Award(args)
	local obj = self:call("getSceneObj", args.key)

	if not obj or obj.seat < 1 then
		return
	end

	local objSeat = obj.seat

	self.mp1AwardCount[objSeat] = self.mp1AwardCount[objSeat] + 1

	local awardImg = cc.Sprite:create(battle.MainAreaRes.txtNqz)
	local mpAward = cc.LabelAtlas:create(args.mp, battle.MainAreaRes.fontNqz, 34, 43, string.byte("0"))
	local x, y = obj:getCurPos()
	local pos = cc.pAdd(cc.p(x, y), obj.unitCfg.everyPos.headPos)

	mpAward:z(999):xy(cc.p(awardImg:width() / 2, awardImg:height())):anchorPoint(0.5, 0)
	awardImg:z(999):xy(pos):hide()
	awardImg:add(mpAward)
	self.parent.effectLayer:add(awardImg)
	transition.executeSequence(self.parent.effectLayer):delay((self.mp1AwardCount[objSeat] - 1) * 0.6):func(function()
		awardImg:show()
	end):delay(0.2):func(function()
		transition.moveBy(awardImg, {
			x = 5,
			y = 30,
			time = 0.8
		})
	end):delay(0.8):func(function()
		awardImg:removeSelf()

		self.mp1AwardCount[objSeat] = self.mp1AwardCount[objSeat] - 1
	end):done()
end

local gainSetArgs = {
	[0] = function(objSprite, sprite, offsetPos)
		local x, y = objSprite:getCurPos()

		return cc.pAdd(cc.p(x, y), offsetPos), objSprite.faceTo
	end,
	function(objSprite, sprite, offsetPos)
		local x, y = objSprite:getCurPos()
		local tmpPos = cc.pAdd(objSprite.unitCfg.everyPos.headPos, offsetPos)

		return cc.pAdd(cc.p(x, y), tmpPos), objSprite:getScaleX() * objSprite.faceTo
	end,
	function(objSprite, sprite, offsetPos)
		local x, y = objSprite:getCurPos()
		local tmpPos = cc.pAdd(objSprite.unitCfg.everyPos.hitPos, offsetPos)

		return cc.pAdd(cc.p(x, y), tmpPos), objSprite:getScaleX()
	end,
	function(objSprite, sprite, offsetPos)
		sprite:setPosition(display.center)

		local x, y = sprite:getPosition()

		return cc.pAdd(cc.p(x, y), offsetPos), 1
	end,
	function(objSprite, sprite, offsetPos)
		local x, y = objSprite:getSelfPos()

		return cc.pAdd(cc.p(x, y), offsetPos), objSprite.faceTo
	end,
	function(objSprite, sprite, offsetPos)
		local cx = (battle.StandingPos[2].x + battle.StandingPos[5].x) / 2

		cx = objSprite.force == 1 and cx or display.width - cx

		return cc.pAdd(cc.p(cx, battle.StandingPos[2].y), offsetPos), objSprite.faceTo
	end,
	function(objSprite, sprite, offsetPos)
		local cx = (battle.StandingPos[2].x + battle.StandingPos[5].x) / 2

		cx = objSprite.force == 1 and display.width - cx or cx

		return cc.pAdd(cc.p(cx, battle.StandingPos[2].y), offsetPos), objSprite.faceTo
	end,
	function(objSprite, sprite, offsetPos)
		return cc.p(offsetPos.x, offsetPos.y), offsetPos.faceTo
	end
}

function MainArea:onBuffPlayOnceEffect(key, resPath, aniName, pos, offsetPos, assignLayer, needWait)
	if not resPath or resPath == "" then
		return
	end

	local objSprite = self:call("getSceneObj", key)

	if not objSprite then
		return
	end

	if self.parent.DEBUG_BATTLE_HIDE then
		return
	end

	local sprite = objSprite.effectResManager:add(battle.EffectResType.OnceEffect, resPath, resPath, {})

	if not sprite then
		return
	end

	local useLayer = self.parent.effectLayer

	if assignLayer then
		local name = ASSIGN_LAYER_TYPE[assignLayer]

		if name then
			useLayer = self.parent[name]
		end
	end

	useLayer:addChild(sprite, 9999)
	sprite:setSpriteEventHandler(function(_type, event)
		if _type == sp.EventType.ANIMATION_COMPLETE then
			if needWait then
				self.parent.onceEffectWaitCount = self.parent.onceEffectWaitCount - 1
			end

			removeCSprite(sprite)
		end
	end)

	local aniName = aniName or "effect"
	local isOk = sprite:play(aniName)
	local flip = offsetPos.flip and -1 or 1

	needWait = needWait and isOk

	if needWait then
		self.parent.onceEffectWaitCount = self.parent.onceEffectWaitCount + 1
	end

	if pos ~= 7 and objSprite.force == 2 then
		offsetPos = cc.p(-offsetPos.x, offsetPos.y)
	end

	local effectPos, scaleX = gainSetArgs[pos](objSprite, sprite, offsetPos)

	sprite:setPosition(effectPos):scale(2)
	sprite:setScaleX(2 * flip * scaleX)
end

function MainArea:onEnterAnimation(leftTb, rightTb, wait)
	local function showCb()
		if leftTb or rightTb then
			self:notify("showHero", {
				typ = "showAll",
				obj = tostring(self.firstBattleObj)
			})

			self.isFirstEnter = nil
		end

		self.enterShowCb = nil
	end

	self.enterShowCb = showCb

	local function palyOneBall(faceTo, fixX, fixY)
		local ani = newCSpriteWithOption("ruchang/ruchang.skel")

		ani:setScaleX(2 * faceTo)
		ani:setScaleY(2)
		self.parent.frontStageLayer:add(ani)
		transition.executeSequence(ani):delay(0.05):func(function()
			ani:xy(display.cx + fixX, display.cy + fixY):play("changjing_1")
		end):delay(0.7):func(function()
			removeCSprite(ani, false)
		end):done()
	end

	local function playBallAni(faceTo)
		if (not leftTb or faceTo ~= 1) and (not rightTb or faceTo ~= -1) then
			return
		end

		local tb

		if faceTo == 1 then
			tb = leftTb
		else
			tb = rightTb
		end

		tb = tb or {}

		local spos = battle.StandingPos

		for _, id in pairs(tb) do
			local spr = self:call("getSceneObjById", id)

			if spr then
				local px, py = spr:getSelfPos()
				local fixX = px - (faceTo == 1 and spos[2].x + 150 or display.width - spos[2].x - 150)
				local fixY = py - spos[2].y - 100

				palyOneBall(faceTo, fixX, fixY)
			end
		end
	end

	playBallAni(1)
	playBallAni(-1)

	local waitEffect

	if wait then
		waitEffect = self.parent:onEventEffectQueue("wait")
	end

	transition.executeSequence(self.parent.frontStageLayer):delay(0.4):func(function()
		if self.enterShowCb then
			self.enterShowCb()
		end

		if waitEffect then
			waitEffect:stop()
		end
	end):done()
end

function MainArea:onQueueExplorer(faceTo, effectRes)
	if self.parent.DEBUG_BATTLE_HIDE then
		return
	end

	if not itertools.include(self.explorerShowList[faceTo], effectRes) then
		table.insert(self.explorerShowList[faceTo], effectRes)
	end
end

function MainArea:showExplorer(faceTo, res)
	if not next(res) then
		return
	end

	local panelSize = cc.size(615, 137)
	local panel = ccui.Layout:create():z(1099):size(615, 137):xy(display.center)
	local imgBase = ccui.Layout:create():size(615, 137):z(2):addTo(panel, 2)
	local imgs = {}

	for i = 1, table.length(res) do
		local img = ccui.ImageView:create(res[i]):xy((-700 - i * 120) * faceTo, 160):scale(1.6 * -faceTo, 1.6):z(2):addTo(imgBase)

		_insert(imgs, img)
	end

	local resPath = "tanxianqi/tanxianqi_skill.skel"
	local spriteBg = newCSpriteWithOption(resPath)

	if not spriteBg then
		return
	end

	spriteBg:xy(cc.p(0, -20)):scale(1.2 * faceTo, 1.2):addTo(panel, 1):play("bot_effect")

	local spriteFg = newCSpriteWithOption(resPath)

	if not spriteFg then
		return
	end

	spriteFg:xy(cc.p(0, -20)):scale(1.2 * faceTo, 1.2):addTo(panel, 3):play("top_effect")

	local function setMoveAction(img, idx, isLast)
		local t = transition.executeSequence(img):delay(0.3 + 0.05 * idx):easeBegin("EXPONENTIALOUT"):moveBy(1.2, 450 * faceTo, 0):easeEnd():func(function()
			transition.executeSpawn(img):easeBegin("EXPONENTIALOUT"):moveBy(1, 250 * faceTo, 0):fadeTo(1, 0.25):easeEnd():done()
		end)

		if isLast then
			t:delay(0.3)
			t:func(function()
				panel:removeFromParent()
			end)
		end

		t:done()
	end

	for i, img in ipairs(imgs) do
		setMoveAction(img, i, i == table.length(imgs))
	end

	panel:xy(panel:x() - faceTo * (display.uiOrigin.x + 500), 800):addTo(self.parent.effectLayer)
end

function MainArea:onPlayExplorer()
	local function show(faceTo)
		local effectRes = self.explorerShowList[faceTo]

		self:showExplorer(faceTo, effectRes)

		self.explorerShowList[faceTo] = {}
	end

	show(1)
	show(-1)
end

local BattleVsPvpView = {}

BattleVsPvpView.RESOURCE_FILENAME = "battle_vs_pvp.json"
BattleVsPvpView.RESOURCE_BINDING = {
	item = "item",
	rightMask = "rightMask",
	leftMask = "leftMask",
	item2 = "item2"
}

function MainArea:onShowVsPvpView(mode)
	local node = gGameUI:createSimpleView(BattleVsPvpView, self.parent.frontStageLayer):init()

	node:z(100)

	local orgSize = node.leftMask:size()

	node.leftMask:hide():size(0, orgSize.height)
	node.rightMask:hide():size(0, orgSize.height)
	node.leftMask:setClippingEnabled(true)
	node.rightMask:setClippingEnabled(true)

	local ani = widget.addAnimationByKey(self.parent.frontStageLayer, "effect/jiemian_vs.skel", "ani", "effect", 1):scale(2):xy(display.cx, display.cy)

	ani:getAni():setTwoColorTint(true)
	performWithDelay(self.parent.frontStageLayer, function()
		ani:play("effect")
		ani:addPlay("effect2")
	end, 0.1)

	local figures = self.parent.data.figures
	local names = self.parent.data.names
	local play = self.parent:getPlayModel()

	local function getRoleOut(data, idx)
		if play.operateForce == 2 then
			return data[battleEasy.mirrorSeat(idx)]
		end

		return data[idx]
	end

	local roleOutT = {}

	for i = 1, play.ForceNumber do
		if self.parent.data.multipGroup then
			roleOutT[i] = getRoleOut(self.parent.data.roleOut[1][1], i)
			roleOutT[i + 6] = getRoleOut(self.parent.data.roleOut[2][1], i + 6)
		else
			roleOutT[i] = getRoleOut(self.parent.data.roleOut, i)
			roleOutT[i + 6] = getRoleOut(self.parent.data.roleOut, i + 6)
		end
	end

	local tempItem = node.item

	if mode == 3 then
		tempItem = node.item2
	end

	tempItem:hide()

	local w = tempItem:width()
	local h = tempItem:size().height

	local function setRoleInfo(infoPanel, idx)
		if figures == nil then
			return
		end

		local cfg = gRoleFigureCsv[figures[idx]] or {}

		infoPanel:get("role"):texture(cfg.resAct)

		local x = cfg.actPos.x

		if idx == 2 then
			x = -x
		end

		infoPanel:get("role"):x(infoPanel:get("role"):x() + x)
		infoPanel:get("role"):y(infoPanel:get("role"):y() + cfg.actPos.y)
		infoPanel:get("name.text"):text(names[idx])
	end

	local function setDatasMode1(infoPanel, idx)
		local stepNum = 0
		local stPosX = 300
		local stPosY = 370
		local xDir = 1

		if idx == 2 then
			stepNum = 6
			stPosX = 900
			xDir = -1
		end

		for i = 1, 6 do
			local row, col = mathEasy.getRowCol(i, 3)
			local x = stPosX + 200 * xDir * (col - 1) + 100 * xDir * (row - 1)
			local y = stPosY - 200 * (row - 1)
			local item = tempItem:clone():xy(x, y):show():addTo(infoPanel:get("cards"), 5)
			local cardData = roleOutT[i + stepNum]

			if cardData then
				item:get("empty"):hide()
				bind.extend(node, item, {
					class = "card_icon",
					props = {
						unitId = cardData.roleId,
						advance = cardData.advance,
						star = cardData.star,
						rarity = csv.unit[cardData.roleId].rarity,
						levelProps = {
							data = cardData.level
						},
						onNode = function(node)
							if idx == 2 then
								node:get("icon"):setFlippedX(true)
							end
						end
					}
				})
			end
		end
	end

	local function setDatasMode2(infoPanel, idx)
		local stepNum = 1

		if idx == 2 then
			stepNum = 7
		end

		local img = infoPanel:get("singleCard")
		local cardData = roleOutT[stepNum]

		if cardData == nil then
			for i = 1, 5 do
				cardData = roleOutT[stepNum + i]

				if cardData then
					break
				end
			end
		end

		local texture = csv.unit[cardData.roleId].cardIcon2

		img:texture(texture)
	end

	local function setDatasMode3(infoPanel, idx)
		local rankTb = {
			"battle/craft/opening/txt_1st_red.png",
			"battle/craft/opening/txt_2nd_red.png",
			"battle/craft/opening/txt_3rd_red.png",
			nil,
			nil,
			nil,
			"battle/craft/opening/txt_1st.png",
			"battle/craft/opening/txt_2nd.png",
			"battle/craft/opening/txt_3rd.png"
		}
		local stepNum = 0
		local stPosX = 360
		local stPosY = 320
		local xDir = 1

		if idx == 2 then
			stepNum = 6
		end

		for i = 1, 3 do
			local x = stPosX + 200 * xDir * (i - 1)
			local y = stPosY
			local item = tempItem:clone():xy(x, y):show():addTo(infoPanel:get("cards"), 5)
			local cardData = roleOutT[i + stepNum]

			if cardData then
				item:get("icon"):get("empty"):hide()
				bind.extend(node, item:get("icon"), {
					class = "card_icon",
					props = {
						unitId = cardData.roleId,
						advance = cardData.advance,
						star = cardData.star,
						rarity = csv.unit[cardData.roleId].rarity,
						levelProps = {
							data = cardData.level
						}
					}
				})
			end

			item:get("rank"):loadTexture(rankTb[i + stepNum])
		end
	end

	local function setCardPanel(panel, mode)
		if mode == 2 then
			panel:get("singleCard"):show()
			panel:get("cards"):hide()
		else
			panel:get("singleCard"):hide()
			panel:get("cards"):show()
		end
	end

	local leftPanel = node.leftMask:get("infoPanel")
	local rightPanel = node.rightMask:get("infoPanel")

	setCardPanel(leftPanel, mode)
	setCardPanel(rightPanel, mode)
	setRoleInfo(leftPanel, 1)
	setRoleInfo(rightPanel, 2)

	if mode == 1 then
		setDatasMode1(leftPanel, 1)
		setDatasMode1(rightPanel, 2)
	elseif mode == 2 then
		setDatasMode2(leftPanel, 1)
		setDatasMode2(rightPanel, 2)
	elseif mode == 3 then
		setDatasMode3(leftPanel, 1)
		setDatasMode3(rightPanel, 2)
	end

	local ly = leftPanel:y()
	local ry = rightPanel:y()
	local aniDelay = 1.2
	local changeTime = 0.4
	local dtTime = 0.01
	local dtWidth = orgSize.width / (changeTime / dtTime)
	local dt = 0
	local aniEndCount = 0
	local waitEffect = self.parent:onEventEffectQueue("wait")

	local function changeMaskWidth()
		local nowWidth = 0
		local tag = battle.UITag.pvpOpening

		self.parent:enableSchedule():schedule(function()
			nowWidth = nowWidth + dtWidth
			dt = dt + dtTime

			if nowWidth > orgSize.width then
				if dt > 2 and aniEndCount >= 4 then
					self.parent:enableSchedule():unSchedule(tag)
					ani:removeSelf()
					node:onClose()

					if waitEffect then
						waitEffect:stop()
					end
				end
			else
				node.leftMask:size(nowWidth, orgSize.height)
				node.rightMask:size(nowWidth, orgSize.height)
				leftPanel:xy(nowWidth / 2, ly)
				rightPanel:xy(nowWidth / 2, ry)
			end
		end, dtTime, 0, tag)
	end

	local allOffY = 50
	local allOffY2 = 6
	local roleOffX = 185
	local roleOffY = 320
	local nameOffX = 320
	local cardsOffX = 150

	local function setStartOff(panel, isLeft, mode)
		local dir = isLeft and 1 or -1
		local alx, aly = panel:xy()

		panel:xy(alx, aly - allOffY)

		local rx, ry = panel:get("role"):xy()

		panel:get("role"):xy(rx + dir * roleOffX, ry - roleOffY)

		local nx, ny = panel:get("name"):xy()

		panel:get("name"):xy(nx - dir * nameOffX, ny)

		local cardPanel

		if mode == 2 then
			cardPanel = panel:get("singleCard")
		else
			cardPanel = panel:get("cards")
		end

		local cx, cy = cardPanel:xy()

		cardPanel:xy(cx + cardsOffX, cy)
	end

	setStartOff(leftPanel, true, mode)
	setStartOff(rightPanel, false, mode)

	local function onAniEnd()
		aniEndCount = aniEndCount + 1
	end

	local function widgetsMove()
		local function moveFunc(panel, isLeft)
			local dir = isLeft and 1 or -1

			transition.executeSequence(panel):moveBy(0.83, 0, allOffY + allOffY2):moveBy(0.23, 0, -allOffY2):func(onAniEnd):done()
			transition.moveBy(panel:get("role"), {
				time = 0.83,
				x = -dir * cardsOffX,
				y = roleOffY
			})
			transition.executeSequence(panel:get("name")):delay(0.36):moveBy(0.6, dir * nameOffX, 0):func(onAniEnd):done()

			local cardPanel

			if mode == 2 then
				cardPanel = panel:get("singleCard")
			else
				cardPanel = panel:get("cards")
			end

			transition.moveBy(cardPanel, {
				time = 0.83,
				x = -cardsOffX
			})
		end

		moveFunc(leftPanel, true)
		moveFunc(rightPanel)
	end

	transition.executeSequence(node.leftMask):delay(aniDelay):show():func(changeMaskWidth):func(widgetsMove):done()
	transition.executeSequence(node.rightMask):delay(aniDelay):show():done()
end

local BattleBossComeView = {}

BattleBossComeView.RESOURCE_FILENAME = "battle_boss_come.json"
BattleBossComeView.RESOURCE_BINDING = {}

function MainArea:onShowBossComeView(showBossInfo)
	local node = gGameUI:createSimpleView(BattleBossComeView, self.parent.frontStageLayer):init()

	node:setLocalZOrder(99)

	local effect = widget.addAnimation(node, "level/qiangdilaixi.skel", "qiangdilaixi", 999)

	effect:xy(display.center):scale(1.9)

	local waitEffect = self.parent:onEventEffectQueue("wait")

	performWithDelay(node, function()
		node:setVisible(false)
		node:removeSelf()

		if showBossInfo then
			gGameUI:createView("battle.boss_info", self.parent.frontStageLayer):init(self.parent, waitEffect):z(999)
		elseif waitEffect then
			waitEffect:stop()
		end
	end, 1)
end

return MainArea
