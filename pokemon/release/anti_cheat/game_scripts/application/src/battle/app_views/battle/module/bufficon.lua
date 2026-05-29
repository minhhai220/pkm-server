-- chunkname: @src.battle.app_views.battle.module.bufficon

local HideIndex = 10000

local function newBuffIconInPlist(path)
	local raw

	if path:find("battle/buff_icon") then
		local shortName = path:sub(18)
		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrameByName(shortName)

		if frame then
			raw = cc.Sprite:createWithSpriteFrame(frame)
		else
			errorInWindows("buff_icon not in batch %s", shortName)
		end
	end

	return CSprite.new(path, raw)
end

local function newBuffOverlayCountLabel(count)
	local label = cc.Label:createWithTTF(count, "font/youmi1.ttf", 30)

	label:enableOutline(cc.c4b(0, 0, 0, 255), 1)
	label:setAnchorPoint(cc.p(1, 0))

	return label
end

local function updateIconPos(sprite, iconPos)
	local buffIconIdx = sprite.firstIdx
	local lineLimit = iconPos.lineLimit
	local box = sprite:getBoundingBox()
	local offX = (buffIconIdx - 1) % lineLimit * (box.width + iconPos.widthLerp)

	if iconPos.force ~= nil then
		offX = offX * iconPos.force
	end

	local offY = math.floor((buffIconIdx - 1) / lineLimit) * (box.height + iconPos.heightLerp)

	if iconPos.yDir then
		offY = -offY
	end

	local newPos = cc.p(offX, offY)

	sprite:setPosition(newPos)
	sprite:visible(sprite.active and buffIconIdx <= iconPos.total)

	if sprite.overlayCountLabel then
		sprite.overlayCountLabel:visible(sprite.overlayCountLabel.active and buffIconIdx <= iconPos.total)
		sprite.overlayCountLabel:setPosition(cc.pAdd(newPos, cc.p(box.width, -5)))
	end
end

local function updateBuffPanelPos(panels, force)
	local order = {}

	for key, t in pairs(panels) do
		if t.force == force then
			table.insert(order, t)
		end
	end

	table.sort(order, function(a, b)
		if a.idx == b.idx then
			return a.id < b.id
		end

		return a.idx < b.idx
	end)

	for i, t in ipairs(order) do
		local node = t.node
		local posy = t.totalHeight - (i - 1) * t.height

		if force == 1 then
			node:setPosition(cc.p(0, posy))
		else
			node:setPosition(cc.p(t.width, posy))
		end

		if i > 6 or t.idx == HideIndex then
			node:hide()
		else
			node:show()
		end
	end
end

local BuffIcon = class("BuffIcon", battleModule.CBase)

local function createNode()
	local node = cc.Node:create()

	node.prevVisible = nil

	return node
end

local function setNodeVisible(node, visible)
	if node.prevVisible ~= visible then
		node:setVisible(visible)

		node.prevVisible = visible
	end
end

function BuffIcon:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.layer = self.parent.gameLayer
	self.layerPos = self.parent:convertToBattleViewSpace(self.layer, cc.p(0, 0))
	self.usedBuffPanel = dataEasy.isUnlock(gUnlockCsv.battleIconSimplify)
	self.buffIconPanel = self.parent.UIWidget.midTopPanel

	self.buffIconPanel:onTouch(function()
		self.buffIconPanel:hide()
	end)
	self.buffIconPanel:get("buffIconPanel"):setTouchEnabled(true)

	self.rolePanel = {
		self.buffIconPanel:get("buffIconPanel"):get("heroPanel"),
		self.buffIconPanel:get("buffIconPanel"):get("enemyPanel")
	}
	self.roleItem = {
		self.buffIconPanel:get("buffIconPanel"):get("heroItem"),
		self.buffIconPanel:get("buffIconPanel"):get("enemyItem")
	}
	self.unitPanels = {}
	self.buffTexts = {}
	self.units = {}
	self.allIconVisible = true
	self.allTextVisible = true
end

local BuffStorageIconPos = {
	yDir = true,
	heightLerp = 10,
	lineLimit = 7,
	total = 21,
	widthLerp = 10
}

function BuffIcon:getRecord(unit, newWhenNil)
	local key = unit.model.id
	local t = self.units[key]

	if t == nil and newWhenNil then
		t = {
			visible = true,
			buffLastIndex = 0,
			buffEffectsMap = {},
			delArray = {},
			buffGroupNode = createNode(),
			buffOverlayNode = createNode(),
			buffTextNode = createNode(),
			iconPos = {
				yDir = false,
				heightLerp = 0,
				lineLimit = 5,
				total = 99,
				widthLerp = 5
			},
			seat = unit.seat
		}
		self.units[key] = t

		if self.usedBuffPanel then
			t.iconPos.total = 5
		end

		local isFixed = false
		local bossLifePanel = self:call("getBossBuffPanel")

		t.shadowNode = cc.Node:create()

		t.shadowNode:addTo(unit.lifebar):xy(cc.pSub(unit.lifebar.buffAddFirstPos, self.layerPos))

		if unit.model.isBoss and bossLifePanel then
			local startPos = cc.p(577, 99)

			t.buffGroupNode:addTo(bossLifePanel, battle.GameLayerZOrder.icon):xy(startPos)
			t.buffOverlayNode:addTo(bossLifePanel, battle.GameLayerZOrder.overlay):xy(startPos)

			isFixed = true

			local scale = 0.8

			t.buffGroupNode:scale(scale)
			t.buffOverlayNode:scale(scale)

			t.iconPos.lineLimit = 13
			t.iconPos.widthLerp = 10

			t.buffGroupNode:setVisible(true)
			t.buffOverlayNode:setVisible(true)
		else
			local startPos = self.parent:convertToBattleViewSpace(t.shadowNode, cc.p(0, 0))

			t.buffGroupNode:addTo(self.layer, battle.GameLayerZOrder.icon + unit.posZ:get()):xy(startPos)
			t.buffOverlayNode:addTo(self.layer, battle.GameLayerZOrder.overlay + unit.posZ:get()):xy(startPos)
		end

		local cb

		cb = t.shadowNode:onNodeEvent("exit", function()
			cb:remove()

			self.units[key] = nil

			for cfgId, sprite in pairs(t.buffEffectsMap) do
				sprite:removeSelf()
				sprite:hide()
			end

			self:removeBuffPanel(key)
			performWithDelay(self.layer, function()
				t.buffGroupNode:removeSelf()
				t.buffOverlayNode:removeSelf()
				t.buffTextNode:removeSelf()
			end, 0)
		end)

		local prevPos = cc.p(0, 0)

		t.shadowNode:scheduleUpdate(function()
			local x, y = unit:getPosition()

			if (prevPos.x ~= x or prevPos.y ~= y or unit.refreshBuffIconOnce) and isFixed == false then
				prevPos = cc.p(x, y)

				local startPos = self.parent:convertToBattleViewSpace(t.shadowNode, cc.p(0, 0))

				t.buffGroupNode:setPosition(startPos)
				t.buffOverlayNode:setPosition(startPos)

				unit.refreshBuffIconOnce = false

				t.buffTextNode:setPosition(cc.pAdd(prevPos, unit.unitCfg.everyPos.headPos))
			end

			local visible = t.visible and unit:visible()
			local textVisible = visible and self.allTextVisible

			setNodeVisible(t.buffTextNode, textVisible)

			if isFixed == false then
				visible = visible and unit.lifebar:visible()

				local iconVisible = visible and self.allIconVisible

				setNodeVisible(t.buffGroupNode, iconVisible)
				setNodeVisible(t.buffOverlayNode, iconVisible)
			end
		end)
		t.buffTextNode:addTo(self.layer, battle.GameLayerZOrder.text + unit.posZ:get()):xy(cc.pAdd(cc.p(unit:getPosition()), unit.unitCfg.everyPos.headPos))
	end

	return t
end

function BuffIcon:getBuffStoragePanel(unit)
	local key = unit.model.id

	if not self.unitPanels[key] then
		self:initBuffIconPanel(unit)
	end

	return self.unitPanels[key]
end

function BuffIcon:initBuffIconPanel(unit)
	local model = unit.model
	local key = model.id

	if self.unitPanels[key] then
		return
	end

	local panels = self.buffIconPanel:get("buffIconPanel")
	local forcePanel = self.rolePanel[unit.force]
	local roleItem = self.roleItem[unit.force]:clone()

	roleItem:addTo(forcePanel)

	self.unitPanels[key] = {
		node = roleItem,
		buffIconPanel = roleItem:get("iconPanel"),
		idx = unit.isBoss and 0 or unit.seat,
		id = key,
		force = unit.force,
		unit = unit,
		width = roleItem:width() * roleItem:scaleX(),
		height = roleItem:height(),
		totalHeight = forcePanel:height(),
		buffGroupNode = createNode(),
		buffOverlayNode = createNode()
	}

	local t = self.unitPanels[key]
	local isLeft = unit.force == 1
	local startPos = isLeft and cc.p(20, 135) or cc.p(380, 135)

	if unit.force == 1 then
		t.buffGroupNode:setAnchorPoint(cc.p(0, 1))
		t.buffOverlayNode:setAnchorPoint(cc.p(0, 1))
	else
		t.buffGroupNode:setAnchorPoint(cc.p(1, 1))
		t.buffOverlayNode:setAnchorPoint(cc.p(1, 1))
	end

	t.buffGroupNode:addTo(t.buffIconPanel, battle.GameLayerZOrder.icon):xy(startPos):visible(true)
	t.buffOverlayNode:addTo(t.buffIconPanel, battle.GameLayerZOrder.overlay):xy(startPos):visible(true)
	bind.extend(self.parent, roleItem:get("frame"), {
		class = "card_icon",
		props = {
			unitId = model.originUnitID,
			advance = model.advance,
			star = model.star,
			rarity = model.rarity,
			isBoss = model.isBoss,
			levelProps = {
				data = model.level
			}
		}
	})

	return roleItem
end

local name2Res = {
	boxRes = battle.iconBoxRes.selectedBox,
	freezeBox = battle.iconBoxRes.freezeBox
}

function BuffIcon:sortObjectBuffPanel()
	if self.usedBuffPanel == false then
		return
	end

	if self.buffIconPanel:visible() == false then
		return
	end

	for _, panel in pairs(self.unitPanels) do
		panel.idx = HideIndex
	end

	if not self.parent._model then
		return
	end

	local scene = self.parent:getSceneModel()

	if not scene then
		return
	end

	for seat = 1, 12 do
		local obj = scene:getObjectBySeat(seat)

		if obj then
			local spr = self:call("getSceneObjById", obj.id)

			if spr and spr:isInBuffPanel() then
				local storageItem = self:getBuffStoragePanel(spr)

				storageItem.idx = storageItem.unit.isBoss and 0 or seat

				local t = self:getRecord(spr, false)

				if t then
					for cfgId, buffIcon in pairs(t.buffEffectsMap) do
						if buffIcon.ref > 0 then
							local storageBuffNode = storageItem.buffGroupNode:getChildByName("buff_" .. tostring(cfgId))

							if not storageBuffNode then
								storageBuffNode = newCSpriteWithFunc(buffIcon.iconResPath, newBuffIconInPlist)
								storageBuffNode.overlayCountLabel = nil
								storageBuffNode.cfgId = cfgId
								storageBuffNode.firstIdx = nil

								storageBuffNode:getAni():scale(1)
								storageBuffNode:getAni():setAnchorPoint(cc.p(0, 0))
								storageBuffNode:hide()
								storageItem.buffGroupNode:addChild(storageBuffNode, 0, "buff_" .. tostring(cfgId))
							end

							if buffIcon.overlayCountLabel and not storageBuffNode.overlayCountLabel then
								local count = tonumber(buffIcon.overlayCountLabel:text())
								local label = newBuffOverlayCountLabel(count)

								label:setPosition(cc.pAdd(cc.p(storageBuffNode:xy()), cc.p(storageBuffNode:getBoundingBox().width, -5)))

								storageBuffNode.overlayCountLabel = label

								storageBuffNode.overlayCountLabel:hide()
								storageItem.buffOverlayNode:addChild(label)
							elseif not buffIcon.overlayCountLabel and storageBuffNode.overlayCountLabel then
								storageBuffNode.overlayCountLabel:removeFromParent()

								storageBuffNode.overlayCountLabel = nil
							end

							for name, res in pairs(name2Res) do
								local frame = buffIcon:getChildByName(name)
								local storageFrame = storageBuffNode:getChildByName(name)

								if frame and not storageFrame then
									frame = newCSpriteWithFunc(res, newBuffIconInPlist)

									storageBuffNode:addChild(frame, 99, name)
									frame:setPosition(25, 25)
								elseif not frame and storageFrame then
									storageFrame:removeFromParent()
								end
							end
						end
					end

					for _, storageBuffNode in pairs(storageItem.buffGroupNode:getChildren()) do
						local buffIcon = t.buffEffectsMap[storageBuffNode.cfgId]

						if buffIcon then
							storageBuffNode:visible(buffIcon.active)

							if buffIcon.active then
								if storageBuffNode.firstIdx ~= buffIcon.firstIdx then
									storageBuffNode.firstIdx = buffIcon.firstIdx
									BuffStorageIconPos.force = spr.force == 1 and 1 or -1

									updateIconPos(storageBuffNode, BuffStorageIconPos)
								end

								storageBuffNode:visible(buffIcon.active and storageBuffNode.firstIdx <= BuffStorageIconPos.total)

								if storageBuffNode.overlayCountLabel then
									storageBuffNode.overlayCountLabel:setString(buffIcon.overlayCountLabel:text())
									storageBuffNode.overlayCountLabel:visible(buffIcon.overlayCountLabel.active and storageBuffNode.firstIdx <= BuffStorageIconPos.total)
								end
							end
						else
							if storageBuffNode.overlayCountLabel then
								storageBuffNode.overlayCountLabel:removeFromParent()
							end

							storageBuffNode:removeFromParent()
						end
					end
				end
			end
		end
	end

	updateBuffPanelPos(self.unitPanels, 1)
	updateBuffPanelPos(self.unitPanels, 2)
end

function BuffIcon:removeBuffPanel(key)
	local t = self.unitPanels[key]

	if not t then
		return
	end

	t.node:removeFromParent()

	self.unitPanels[key] = nil

	self:sortObjectBuffPanel(false)
end

local function newBuffTxtInPlist(path)
	local raw

	if path:find("battle/txt") then
		local shortName = path:sub(12)
		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrameByName(shortName)

		if frame then
			raw = cc.Sprite:createWithSpriteFrame(frame)

			raw:setScale(2.5)
		elseif APP_CHANNEL == "bare" then
			errorInWindows("buff_txt not in batch " .. shortName)
		end
	end

	return CSprite.new(path, raw)
end

function BuffIcon:onNewBattleRound(args)
	self:sortObjectBuffPanel()
end

function BuffIcon:setAllBuffIconVisible(visible)
	self.buffIconPanel:setVisible(visible)
	self:sortObjectBuffPanel()
end

function BuffIcon:onShowBuffText(unit, textRes)
	if not textRes or textRes == "" then
		return
	end

	local t = self:getRecord(unit, true)

	self.buffTexts[unit.id] = self.buffTexts[unit.id] or {}

	local buffTexts = self.buffTexts[unit.id]

	if buffTexts[textRes] then
		return
	end

	local height, count, avg = 0, 0, 0

	for k, v in pairs(buffTexts) do
		height = height + v
		count = count + 1
	end

	if height + t.buffTextNode:getPositionY() > display.sizeInView.height then
		return
	end

	local sprite = unit.effectResManager:add(battle.EffectResType.BuffText, textRes, textRes, {
		scale = 1,
		spr = newCSpriteWithFunc(textRes, newBuffTxtInPlist)
	})

	if not sprite then
		return
	end

	local box = sprite:getBoundingBox()

	avg = count == 0 and box.height or (height + box.height) / (count + 1)

	local newPos = cc.p(0, height + avg)

	buffTexts[textRes] = avg

	sprite:setPosition(newPos)
	t.buffTextNode:add(sprite)

	local function remove()
		buffTexts[textRes] = nil

		removeCSprite(sprite)
	end

	transition.executeSequence(sprite):delay(1):fadeOut(0.25):func(remove):done()
end

function BuffIcon:onShowBuffIcon(unit, iconResPath, cfgId, overlayCount)
	local t = self:getRecord(unit, true)
	local sprite = t.buffEffectsMap[cfgId]

	if sprite == nil then
		return
	end

	local overlayCountLabel = sprite.overlayCountLabel

	if overlayCountLabel and overlayCount and overlayCount <= 1 then
		overlayCountLabel.active = false
	end

	if overlayCount and overlayCount > 1 then
		if overlayCountLabel == nil then
			local label = newBuffOverlayCountLabel(overlayCount)

			t.buffOverlayNode:addChild(label)

			sprite.overlayCountLabel = label
			overlayCountLabel = label
		end

		overlayCountLabel.active = true

		overlayCountLabel:setString(overlayCount)
	end

	sprite:show()

	sprite.active = true

	self:refreshBuffIcons(t)
end

function BuffIcon:refreshBuffIcons(t)
	local order = {}

	for id, spr in pairs(t.buffEffectsMap) do
		if spr.ref > 0 then
			spr.active = true

			table.insert(order, spr)
		end
	end

	table.sort(order, function(a, b)
		if a.priority == b.priority then
			return a.firstIdx < b.firstIdx
		end

		return a.priority > b.priority
	end)

	for i, spr in ipairs(order) do
		spr.firstIdx = i
	end

	t.buffLastIndex = table.length(order)

	for _, spr in ipairs(order) do
		updateIconPos(spr, t.iconPos)
	end
end

function BuffIcon:clearDelArray(t)
	for _, cfgId in ipairs(t.delArray) do
		local sprite = t.buffEffectsMap[cfgId]

		if sprite and sprite.ref <= 0 then
			t.buffEffectsMap[cfgId] = nil

			if sprite.overlayCountLabel then
				sprite.overlayCountLabel:removeSelf()

				sprite.overlayCountLabel = nil
			end

			for name, _ in pairs(name2Res) do
				local frame = sprite:getChildByName(name)

				if frame then
					sprite:removeChildByName(name)
				end
			end

			removeCSprite(sprite)
		end
	end

	t.delArray = {}
end

function BuffIcon:onDelBuffIcon(unit, cfgId)
	local t = self:getRecord(unit)

	if t == nil then
		return
	end

	local sprite = t.buffEffectsMap[cfgId]

	if sprite == nil then
		return
	end

	sprite.ref = sprite.ref - 1

	if sprite.ref > 0 then
		return
	end

	sprite:hide()

	sprite.active = false

	self:refreshBuffIcons(t)
	table.insert(t.delArray, cfgId)

	local mark = table.length(t.delArray)

	if t.shadowNode then
		performWithDelay(t.shadowNode, function()
			if mark ~= table.length(t.delArray) then
				return
			end

			self:clearDelArray(t)
		end, 1)
	end
end

function BuffIcon:onDealBuffIconBox(unit, cfgId, name, boxRes, isOver)
	local t = self:getRecord(unit, true)
	local sprite = t.buffEffectsMap[cfgId]

	if sprite == nil then
		return
	end

	local frame = sprite:getChildByName(name)

	if not isOver then
		if frame == nil then
			frame = newCSpriteWithFunc(boxRes, newBuffIconInPlist)

			sprite:addChild(frame, 99, name)
			frame:setPosition(25, 25)

			frame.ref = 0
		end

		frame.ref = frame.ref + 1
	elseif frame then
		frame.ref = frame.ref - 1

		if frame.ref == 0 then
			sprite:removeChildByName(name)
		end
	end
end

function BuffIcon:onDealBuffEffectsMap(unit, iconResPath, cfgId, boxRes)
	local t = self:getRecord(unit, true)
	local sprite = t.buffEffectsMap[cfgId]

	if sprite then
		if sprite.ref < 0 then
			sprite.ref = 0
		end

		sprite.ref = sprite.ref + 1

		return
	end

	if iconResPath and iconResPath ~= "" then
		t.buffLastIndex = t.buffLastIndex + 1

		local idx = t.buffLastIndex

		sprite = newCSpriteWithFunc(iconResPath, newBuffIconInPlist)
		sprite.ref = 1
		sprite.cfgId = cfgId
		sprite.priority = 0
		sprite.overlayCountLabel = nil
		sprite.iconResPath = iconResPath
		sprite.active = false

		if boxRes[2] then
			sprite.priority = boxRes[2]
		end

		sprite.firstIdx = idx

		if boxRes[1] == 1 then
			local frame = newCSpriteWithFunc(battle.iconBoxRes.selectedBox, newBuffIconInPlist)

			sprite:addChild(frame, 99, "boxRes")
			frame:setPosition(25, 25)
		end

		sprite:getAni():scale(1)
		sprite:getAni():setAnchorPoint(cc.p(0, 0))
		sprite:hide()
		t.buffGroupNode:add(sprite)

		t.buffEffectsMap[cfgId] = sprite
	end
end

function BuffIcon:onSetBuffIconVisible(unit, flag)
	local t = self:getRecord(unit)

	if t == nil then
		return
	end

	t.visible = flag
end

function BuffIcon:onSetAllBuffIconVisible(visible)
	self.allIconVisible = visible
end

function BuffIcon:onSetAllBuffTextVsisible(visible)
	self.allTextVisible = visible
end

function BuffIcon:onSetDebugBattleVisible(visible)
	self:onSetAllBuffTextVsisible(visible)
	self:onSetAllBuffIconVisible(visible)
end

return BuffIcon
