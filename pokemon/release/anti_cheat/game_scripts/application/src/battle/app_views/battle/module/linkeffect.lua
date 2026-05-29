-- chunkname: @src.battle.app_views.battle.module.linkeffect

local LinkEffect = class("LinkEffect", battleModule.CBase)

function LinkEffect:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.lines = {}
	self.pos = {}
	self.kPos = {}
	self.caster2Keys = {}
	self.isShow = true
	self.forceShow = {
		[1] = true,
		[2] = true
	}
	self.updateObjKey = nil
	self.updateObjNode = nil
	self.lastx = 0
	self.lasty = 0
	self.holderKeyCnt = {}
	self.wrongOrderDelRecord = {}
end

function LinkEffect:alterLine(objKey1, objKey2, line, scaleX)
	if not self.pos[objKey1] or not self.pos[objKey2] then
		return
	end

	local x1 = self.pos[objKey1][1] + self.kPos[objKey1].x
	local y1 = self.pos[objKey1][2] + self.kPos[objKey1].y
	local x2 = self.pos[objKey2][1] + self.kPos[objKey2].x
	local y2 = self.pos[objKey2][2] + self.kPos[objKey2].y
	local len = math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))

	if line.boxWidth == 0 then
		line.boxWidth = line:getBoundingBox().width
	end

	local _scaleX = scaleX * (len / line.boxWidth)
	local p = {}

	p.x = x1 - x2
	p.y = y1 - y2

	local r = math.atan2(p.y, p.x) * 180 / math.pi

	line:scaleX(_scaleX):setRotation(-r)
end

function LinkEffect:getLineVisible(lineData)
	local holderSpr = self:call("getSceneObj", lineData.holderKey)
	local casterSpr = self:call("getSceneObj", lineData.casterKey)

	if not holderSpr or not casterSpr then
		return false
	end

	local realVisible = holderSpr:isVisible() and casterSpr:isVisible()
	local spriteVisible = holderSpr.spriteVisible:get() and casterSpr.spriteVisible:get()

	return self.isShow and self.forceShow[lineData.force] and realVisible and spriteVisible
end

function LinkEffect:onUpdateSpriteLinkVisible(objKey)
	local function alterLinkVisible(data)
		local finalVisible = self:getLineVisible(data)

		if finalVisible then
			self:onDoShiftPos(data.holderKey)
		end

		data.line:setVisible(finalVisible)
	end

	for _, data in pairs(self.lines) do
		if data.holderKey == objKey then
			alterLinkVisible(data)

			break
		end
	end

	if self:tryGetCaster(objKey) then
		local data

		for _, lineKey in ipairs(self.caster2Keys[objKey]) do
			data = self.lines[lineKey]

			alterLinkVisible(data)
		end
	end
end

function LinkEffect:refreshByObj(objKey)
	for key, data in pairs(self.lines) do
		local newKey = self:tryGetCaster(data.casterKey)

		if newKey == objKey or data.holderKey == objKey then
			self:alterLine(newKey, data.holderKey, data.line, data.scaleX)
		end
	end
end

function LinkEffect:checkObjMove()
	local pos = self.pos[self.updateObjKey]

	if not pos then
		return false
	end

	local x, y = pos[1], pos[2]

	if x ~= self.lastx or y ~= self.lasty then
		self.lastx, self.lasty = x, y

		return true
	end

	return false
end

function LinkEffect:onUpdate(delta)
	if not self.updateObjKey or not self.isShow or not self:checkObjMove() then
		return
	end

	self:refreshByObj(self.updateObjKey)
end

function LinkEffect:onAddLinkEffect(holderKey, casterKey, cfg, buffId)
	local key = buffId

	if self.lines[key] or self.wrongOrderDelRecord[key] then
		return
	end

	self.holderKeyCnt[holderKey] = self.holderKeyCnt[holderKey] or 0
	self.holderKeyCnt[holderKey] = self.holderKeyCnt[holderKey] + 1

	local effectRes = cfg.effectRes
	local aniName = cfg.aniName
	local offsetPos = cfg.offsetPos
	local deep = cfg.deep
	local scaleX = cfg.scaleX or 1
	local holderSpr = self:call("getSceneObj", holderKey)

	offsetPos = offsetPos and cc.p(offsetPos.x, offsetPos.y) or cc.p(0, 0)

	if holderSpr.force == 2 then
		offsetPos = cc.p(-offsetPos.x, offsetPos.y)
	end

	local effectPos = holderSpr.unitCfg.everyPos.hitPos

	effectPos = cc.pAdd(effectPos, offsetPos)

	local newLine = newCSpriteWithOption(effectRes)

	newLine:addTo(holderSpr, deep)
	newLine:setPosition(effectPos)
	newLine:play(aniName)
	newLine:setVisible(self.isShow and self.forceShow[holderSpr.force])

	newLine.boxWidth = 0
	self.kPos[holderKey] = effectPos

	self:savePosition(holderSpr, holderKey)

	self.lines[key] = {
		line = newLine,
		buffId = buffId,
		holderKey = holderKey,
		casterKey = casterKey,
		scaleX = scaleX,
		force = holderSpr.force
	}
	self.caster2Keys[casterKey] = self.caster2Keys[casterKey] or {}

	if holderKey == casterKey then
		table.insert(self.caster2Keys[casterKey], 1, key)
	else
		table.insert(self.caster2Keys[casterKey], key)
	end

	local newKey = self:tryGetCaster(casterKey)

	self:refreshByObj(newKey)
	newLine:scheduleUpdate(function()
		local tmpKey = self:tryGetCaster(casterKey)

		newLine.boxWidth = newLine:getBoundingBox().width

		if newLine.boxWidth > 0 then
			newLine:unscheduleUpdate()
		end

		self:alterLine(tmpKey, holderKey, newLine, scaleX)
	end)
end

function LinkEffect:onDelLinkEffect(buffId)
	local key = buffId

	if not self.lines[key] then
		self.wrongOrderDelRecord[key] = true

		return
	end

	local tmpCasterKey = self.lines[key].casterKey

	if self.caster2Keys[tmpCasterKey] then
		for k, objKey in ipairs(self.caster2Keys[tmpCasterKey]) do
			if objKey == key then
				table.remove(self.caster2Keys[tmpCasterKey], k)

				break
			end
		end
	end

	local holderKey = self.lines[key].holderKey

	self.holderKeyCnt[holderKey] = self.holderKeyCnt[holderKey] or 0
	self.holderKeyCnt[holderKey] = self.holderKeyCnt[holderKey] - 1

	if self.holderKeyCnt[holderKey] <= 0 then
		self.pos[holderKey] = nil
		self.kPos[holderKey] = nil
	end

	local line = self.lines[key].line

	removeCSprite(line)

	self.lines[key] = nil

	self:refreshByObj(self:tryGetCaster(tmpCasterKey))
end

function LinkEffect:onShowLinkEffect(isShow)
	if isShow == self.isShow then
		return
	end

	self.isShow = isShow

	for k, v in pairs(self.lines) do
		v.line:setVisible(self:getLineVisible(v))
	end
end

function LinkEffect:onLinkEffectForceVisible(isShow, force)
	if isShow == self.forceShow[force] then
		return
	end

	self.forceShow[force] = isShow

	for k, v in pairs(self.lines) do
		v.line:setVisible(self:getLineVisible(v))
	end
end

function LinkEffect:onDoShiftPos(objKey)
	local spr = self:call("getSceneObj", objKey)

	self:savePosition(spr, objKey)
	self:refreshByObj(objKey)
end

function LinkEffect:onUpdateLinkEffect(needUpdate, objKey)
	local spr = self:call("getSceneObj", objKey)

	if needUpdate then
		if spr then
			local linkShadow = cc.Node:new()

			spr:addChild(linkShadow, 1, "linkShadow")

			self.updateObjNode = linkShadow
			self.updateObjKey = objKey

			self.updateObjNode:scheduleUpdate(function()
				self:savePosition(spr, objKey)
			end)
			self.updateObjNode:registerScriptHandler(function(state)
				if state == "cleanup" and self.updateObjNode == linkShadow then
					self.updateObjNode = nil
				end
			end)
		end
	elseif objKey == self.updateObjKey then
		if self.updateObjNode then
			self.updateObjNode:unscheduleUpdate()
			self.updateObjNode:removeFromParent()
		end

		self.updateObjKey = nil
		self.updateObjNode = nil
		self.lastx = 0
		self.lasty = 0

		if spr then
			self:savePosition(spr, objKey)
		end

		self:refreshByObj(objKey)
	end
end

function LinkEffect:tryGetCaster(objKey)
	local key = self.caster2Keys[objKey] and self.caster2Keys[objKey][1]

	if key and self.lines[key] then
		return self.lines[key].holderKey
	end
end

function LinkEffect:savePosition(spr, objKey)
	if not spr or not objKey then
		return
	end

	if self.updateObjKey == objKey then
		self.pos[objKey] = {
			spr:xy()
		}
	else
		self.pos[objKey] = {
			spr:getSelfPos()
		}
	end
end

return LinkEffect
