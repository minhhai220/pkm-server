-- chunkname: @src.battle.app_views.battle.module.speedrank

local rankResTb = {
	redBg = "battle/box_bg_red.png",
	gray = "battle/box_elves_gray.png",
	greenBg = "battle/box_bg_green.png",
	green = "battle/box_elves_green.png",
	grayBg = "battle/box_bg_gray.png",
	red = "battle/box_elves_red.png",
	blue = "battle/box_elves_blue.png"
}
local SpeedRank = class("SpeedRank", battleModule.CBase)
local RankLimit = 6
local touxiangScale = 0.9

function SpeedRank:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.widget = self.parent.UIWidgetMid:get("widgetPanel.speedRank")
	self.iconItem = self.widget:get("rankItem")
	self.backGound = self.widget:get("di")
	self.iconRange = self.widget:get("iconRange")
	self.barLength = self.iconRange:size().height
	self.iconHeight = self.iconItem:size().height

	self.iconItem:hide()

	self.newRanksInfo = {}
	self.objWidget = {}
	self.firstObjPosY = 0
	self.posAddValue = 0
	self.refreshCount = 0
	self.specObjects = {}

	self:initSpecRoundObject()
	self.roundWidget:show()

	if not self.parent:hasGuide() then
		self.captureSprite = CRenderSprite.newWithNodes(cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444, self.widget)

		self.captureSprite:addTo(self.parent.UIWidgetMid:get("widgetPanel")):coverTo(self.widget)
		self.captureSprite:setCaptureOffest(cc.p(120, 0))
	end

	self.roundWidget:hide()

	self.hideObjIdDict = {}
end

function SpeedRank:onRankRefresh(newRanksInfo)
	self.refreshCount = self.refreshCount + 1

	local speedRankSign = {}

	if newRanksInfo then
		self.newRanksInfo = newRanksInfo
	elseif self.parent then
		self.newRanksInfo, speedRankSign = self.parent:getPlayModel():getSpeedRankArray()
	else
		self.newRanksInfo, speedRankSign = {}, {}
	end

	self:removeHideObjs(self.newRanksInfo, speedRankSign)

	local maxSpeed = 0
	local minSpeed = math.huge
	local hasAttacked = false
	local notAttackedHeros = {}
	local hasAttackedHeros = {}

	for idx, obj in ipairs(self.newRanksInfo) do
		if obj.isAlreadyDead and not obj:isAlreadyDead() then
			local curSpeed = obj:speed()
			local unitId = speedRankSign[idx] ~= 0 and speedRankSign[idx]
			local unitIcon = unitId and csv.unit[unitId].icon or obj.unitCfg.icon

			if speedRankSign[idx] and speedRankSign[idx] ~= 0 then
				if not hasAttacked and obj.unitID % 2 == 0 then
					curSpeed = obj:speed(0)
				end

				if hasAttacked and obj.unitID % 2 ~= speedRankSign[idx] % 2 then
					curSpeed = obj:speed(0)
				end
			end

			local view = self:call("getSceneObjById", obj.id)

			maxSpeed = math.max(maxSpeed, curSpeed)
			minSpeed = math.min(minSpeed, curSpeed)

			local tb = {
				objSeat = view.seat,
				dbID = tostring(obj) .. tostring(unitIcon),
				speed = curSpeed,
				heroIcon = obj:getChangeUnitShowIcon() or unitIcon,
				force = view.force,
				faceTo = view.faceTo,
				hasAttacked = hasAttacked,
				curHero = idx == 1,
				objType = obj.type
			}

			if not hasAttacked then
				table.insert(notAttackedHeros, tb)
			else
				table.insert(hasAttackedHeros, tb)
			end
		elseif obj.seat == 99999 then
			hasAttacked = true
		end
	end

	self.maxSpeed = maxSpeed
	self.minSpeed = minSpeed

	for idx, obj in ipairs(self.specObjects) do
		obj:sort(notAttackedHeros, hasAttackedHeros)
	end

	table.sort(hasAttackedHeros, function(a, b)
		return a.speed > b.speed
	end)

	local speedRank = arraytools.merge({
		notAttackedHeros,
		hasAttackedHeros
	})

	self.speedRankTb = speedRank

	local curCount = self.refreshCount
	local widgetCount = 0

	local function onMoveDone()
		widgetCount = widgetCount - 1

		if widgetCount ~= 0 or curCount ~= self.refreshCount then
			return
		end

		if self.captureSprite then
			self.captureSprite:show()
		end
	end

	if self.captureSprite then
		self.captureSprite:hide()
	end

	local startPosX = self.iconRange:size().width / 2
	local iconHeight = self.iconHeight
	local posY = self.barLength
	local hasRanked = {}

	for i, v in ipairs(self.speedRankTb) do
		if not hasRanked[v.dbID] then
			hasRanked[v.dbID] = true
			widgetCount = widgetCount + 1

			local widget = self:getWidget(i, v.dbID, v.heroIcon, v.force, v.faceTo, v.objType)

			if i <= 8 then
				transition.executeSequence(widget, true):moveTo(0.2, startPosX, posY):func(onMoveDone):done()

				posY = posY - 13 - iconHeight
			else
				widget:hide()
			end
		end
	end
end

local gateReplaceItemRes = {
	[game.GATE_TYPE.battlebet] = {
		rankResTb.red,
		rankResTb.blue
	},
	[game.GATE_TYPE.contestbet] = {
		rankResTb.red,
		rankResTb.blue
	}
}

function SpeedRank:getWidget(idx, dbID, iconRes, force, faceTo, objType)
	local zOrder = table.length(self.speedRankTb) - idx

	if self.objWidget[dbID] then
		return self.objWidget[dbID]:z(zOrder):show()
	end

	local item = self.iconItem:clone()
	local icon = item:get("icon")
	local box = item:get("box")
	local bg = item:get("bg"):hide()
	local itemResTb = gateReplaceItemRes[self.parent.gateType] or {
		rankResTb.green,
		rankResTb.red
	}
	local itemResBgTb = {
		rankResTb.greenBg,
		rankResTb.redBg
	}

	if objType == battle.ObjectType.Aid then
		bg:loadTexture(itemResBgTb[force]):show()
	end

	item:loadTexture(itemResTb[force]):anchorPoint(0.5, 0.5):addTo(self.iconRange, zOrder):show()
	icon:loadTexture(iconRes):scale(touxiangScale)
	box:loadTexture(itemResTb[force])

	self.objWidget[dbID] = item

	return item:show()
end

function SpeedRank:initSpecRoundObject()
	local obj = {
		speed = -100,
		hasAttacked = false,
		icon = "battle/icon_sl.png",
		fixedSpacePrecent = {
			0.15,
			0.15
		}
	}

	obj.dbID = tostring(obj)

	function obj.sort(o, notAttackedHeros, hasAttackedHeros)
		table.insert(notAttackedHeros, o)

		self.minSpeed = math.min(self.minSpeed, o.speed)

		self.objWidget[o.dbID]:get("round"):setText(self.parent:getPlayModel().curRound + 1)
	end

	local item = self.iconItem:clone()
	local icon = item:get("icon")
	local box = item:get("box")
	local bg = item:get("bg"):hide()
	local tipSprite = newCSprite("city/embattle/logo_sxd.png")

	item:addChild(tipSprite)
	tipSprite:setAnchorPoint(cc.p(0, 1))
	tipSprite:setPosition(cc.p(20 - item:width(), item:height() - 30))
	tipSprite:setScaleX(-1)
	tipSprite:setRotation(-30)

	local text = ccui.Text:create("1", "font/youmi1.ttf", 48)

	item:addChild(text, 99, "round")
	text:setPosition(cc.p(20 - item:width(), item:height() - 30))
	item:loadTexture(rankResTb.gray):anchorPoint(0.5, 0.5):addTo(self.iconRange):xy(cc.p(self.iconRange:size().width / 2, 0))
	icon:loadTexture(obj.icon):scale(-1, 1):xy(item:width() / 2, item:height() / 2)
	box:loadTexture(rankResTb.gray)

	self.objWidget[obj.dbID] = item

	table.insert(self.specObjects, obj)

	self.roundWidget = item
end

function SpeedRank:onNewBattleRound(args)
	self.nowWave = self.nowWave or args.wave

	if args.wave > self.nowWave then
		self.nowWave = args.wave
	end

	for _, w in pairs(self.objWidget) do
		w:hide()
	end

	self.widget:show()
	self:onRankRefresh()
end

function SpeedRank:onSpeedRankHideObj(id, isHide)
	if not id then
		return
	end

	self.hideObjIdDict[id] = self.hideObjIdDict[id] or 0

	if isHide then
		self.hideObjIdDict[id] = self.hideObjIdDict[id] + 1
	else
		self.hideObjIdDict[id] = self.hideObjIdDict[id] - 1
	end
end

function SpeedRank:removeHideObjs(array, sign)
	for i = table.length(array), 1, -1 do
		local obj = array[i]

		if obj.id and self.hideObjIdDict[obj.id] and self.hideObjIdDict[obj.id] > 0 then
			table.remove(array, i)
			table.remove(sign, i)
		end
	end
end

return SpeedRank
