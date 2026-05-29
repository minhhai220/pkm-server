-- chunkname: @src.easy.sprite

globals.CSprite = class("CSprite", cc.Node)
CSprite.Types = {
	SPINE = 3,
	PLIST = 5,
	ARMATURE = 1,
	SPINEBIN = 4,
	SPRITE = 2
}

local type = tolua and tolua.type or type
local findLast = string.findlastof

local function null_func()
	return
end

globals.SpineSpritesMap = setmetatable({}, {
	__mode = "kv"
})

function globals.isPng(s)
	return s:sub(-4) == ".png" and s
end

function globals.isSpine(s)
	return s:sub(-5) == ".skel" and s
end

function globals.pngPath(s)
	local p = s:find(".skel")

	if p then
		return s:sub(1, p) .. "png"
	end

	p = s:find(".png")

	if not p then
		return string.format("font/digital_%s.png", s)
	end

	return s
end

local sum = 0

function globals.isCSprite(spr)
	return tj.type(spr) == "CSprite"
end

function globals.newCSprite(aniRes, ...)
	local function new(...)
		local obj = cache.popByKey(aniRes)

		if obj then
			return obj, true
		end

		return CSprite.new(aniRes, ...), false
	end

	local sprite, inCache = new(...)

	sprite:show()

	return cache.addCSprite(sprite)
end

function globals.newCSpriteWithFunc(aniRes, newFunc, ...)
	local function new(...)
		local obj = cache.popByKey(aniRes)

		if obj then
			return obj, true
		end

		return newFunc(aniRes, ...), false
	end

	local sprite, inCache = new(...)

	sprite:show()

	return cache.addCSprite(sprite)
end

function globals.removeCSprite(sprite, cacheIt)
	if sprite == nil then
		return
	end

	if tj.type(sprite) ~= "CSprite" then
		error(string.format("sprite %s was not CSprite", tostring(sprite)))
	end

	local cb

	if cacheIt == nil then
		cacheIt = true
	end

	if cacheIt then
		function cb()
			cache.addByKey(sprite.__aniRes, sprite)
		end
	end

	return cache.eraseCSprite(sprite, cb)
end

local function parseResString(aniRes)
	if aniRes == nil or aniRes == "" then
		return
	end

	if device.platform == "windows" then
		assert(aniRes == string.trim(aniRes), aniRes .. " had space char")
	end

	local argsStr, aniStr
	local pos_ = string.find(aniRes, "%[")

	if pos_ ~= nil then
		aniStr = string.sub(aniRes, 1, pos_ - 1)
		argsStr = string.sub(aniRes, pos_ + 1, string.len(aniRes) - 1)
	else
		aniStr = aniRes
	end

	aniStr = string.gsub(aniStr, "\\", function(c)
		return "/"
	end)
	aniStr = string.gsub(aniStr, "//", function(c)
		return "/"
	end)

	return aniStr, argsStr
end

local function getResTypeAndPath(res)
	local aniStr, argsStr = parseResString(res)
	local typ, aniStr2
	local pos = string.find(aniStr, "%.skel")

	if pos then
		typ = CSprite.Types.SPINEBIN
		aniStr2 = string.sub(aniStr, 1, pos - 1) .. ".atlas"
	end

	if typ == nil then
		pos = string.find(aniStr, "%.json")

		if pos then
			typ = CSprite.Types.SPINE
			aniStr2 = string.sub(aniStr, 1, pos - 1) .. ".atlas"
		end
	end

	if typ == nil then
		pos = string.find(aniStr, "%.png") or string.find(aniStr, "%.jpg")

		if pos then
			typ = CSprite.Types.SPRITE
		end
	end

	if typ == nil then
		local pos = string.find(aniStr, "%.ExportJson")

		if pos then
			typ = CSprite.Types.ARMATURE

			local prePos = findLast(aniStr, "/")

			aniStr2 = string.sub(aniStr, prePos + 1, pos - 1)
		end
	end

	if typ == nil then
		pos = string.find(aniStr, "%.plist")

		if pos then
			typ = CSprite.Types.PLIST
		end
	end

	return typ, argsStr, aniStr, aniStr2
end

function CSprite:init(argsStr)
	if argsStr == nil or self.__ani == nil then
		return
	end

	local posbs = string.find(argsStr, "bs")
	local posrotate = string.find(argsStr, "rotate")
	local posalpha = string.find(argsStr, "alpha")
	local poshsl = string.find(argsStr, "hsl")
	local poshscc = string.find(argsStr, "hscc")

	if posbs ~= nil then
		local T = {}

		for arg in argsStr:sub(posbs):gmatch("[-.%d]+") do
			table.insert(T, tonumber(arg))

			if #T >= 2 then
				break
			end
		end

		if #T ~= 2 then
			return
		end

		self.__ani:setScale(T[1], T[2])
	end

	if posrotate ~= nil then
		for arg in argsStr:sub(posrotate):gmatch("[-.%d]+") do
			self.__ani:setRotation(tonumber(arg))

			break
		end
	end

	if posalpha ~= nil then
		for arg in argsStr:sub(posalpha):gmatch("[-.%d]+") do
			self.__ani:setOpacity(tonumber(arg) * 255)

			break
		end
	end

	if poshsl ~= nil then
		local T = {}

		for arg in argsStr:sub(poshsl):gmatch("[-.%d]+") do
			table.insert(T, tonumber(arg))

			if #T >= 3 then
				break
			end
		end

		if #T ~= 3 then
			return
		end

		self:setHSLShader(T[1], T[2], T[3], 1)
	end

	if poshscc ~= nil then
		local T = {}

		for arg in argsStr:sub(poshscc):gmatch("[-.%d]+") do
			table.insert(T, tonumber(arg))

			if #T >= 3 then
				break
			end
		end

		if #T ~= 3 then
			return
		end

		self:setHSLShader(T[1], T[2], T[3], 2)
	end
end

function CSprite:ctor(aniRes, raw)
	self.__ani = nil
	self.__aniType = nil
	self.__shaderName = nil
	self.__rawShaderState = nil
	self.__aniRes = aniRes

	if raw ~= nil then
		self.__ani = raw
		self.__aniType = CSprite.Types.SPRITE

		self:addChild(self.__ani)

		return
	end

	if aniRes == nil then
		self.__ani = self
		self.__aniType = CSprite.Types.SPRITE

		return
	end

	local typ, argsStr, aniStr, aniStr2 = getResTypeAndPath(aniRes)

	self.__aniType = typ

	if typ == CSprite.Types.SPINE or typ == CSprite.Types.SPINEBIN then
		local atlas = aniStr2

		self.__ani = sp.SkeletonAnimation:create(aniStr, atlas)

		local tintEnabled = true

		if gGameUI.rootViewName == "battle.view" or gGameUI.rootViewName == "battle.loading" then
			tintEnabled = false
		end

		self.__ani:setTwoColorTint(tintEnabled)

		SpineSpritesMap[self.__ani] = self
	elseif typ == CSprite.Types.SPRITE then
		self.__ani = cc.Sprite:create(aniStr)
	elseif typ == CSprite.Types.ARMATURE then
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(aniStr)

		self.__ani = ccs.Armature:create(aniStr2)
	elseif typ == CSprite.Types.PLIST then
		self.__ani = cc.ParticleSystemQuad:create(aniStr)
	end

	if self.__ani then
		self:addChild(self.__ani)
	end

	self:init(argsStr)
end

function CSprite.preLoad(aniRes)
	if aniRes == nil or aniRes == "" then
		return
	end

	local typ, argsStr, aniStr, aniStr2 = getResTypeAndPath(aniRes)
	local ret

	if typ == CSprite.Types.SPINE or typ == CSprite.Types.SPINEBIN then
		ret = CSprite.new(aniRes)

		cache.addByKey(aniRes, ret)
	elseif typ == CSprite.Types.ARMATURE then
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(aniStr)
	elseif typ == CSprite.Types.SPRITE then
		display.textureCache:addImageAsync(aniStr, null_func)
	elseif typ == CSprite.Types.PLIST then
		cc.ParticleSystemQuad:create(aniStr)
	end

	return ret
end

function CSprite:isArmature()
	return self.__aniType == self.Types.ARMATURE
end

function CSprite:isSpine()
	return self.__aniType == self.Types.SPINE or self.__aniType == self.Types.SPINEBIN
end

function CSprite:isSprite()
	return self.__aniType == self.Types.SPRITE
end

function CSprite:_initRTForSpineAnimation(shaderName, scaleIt, handler)
	self.__isTwoColorTint = true

	if self.__twoColorSprites then
		for _, node in ipairs(self.__twoColorSprites) do
			node:removeSelf()
		end

		self.__twoColorSprites = nil
	end

	performWithDelay(gGameUI.scene, function()
		if tolua.isnull(self) or tolua.isnull(self.__ani) then
			return
		end

		if self.__ani == nil then
			return
		end

		if self.__shaderName ~= shaderName then
			return
		end

		local selfScale = 1

		if scaleIt then
			selfScale = math.abs(self:getScaleX())
		end

		local scale = self.__ani:getScale()
		local size = self.__ani:getContentSize()
		local box = self.__ani:getBoundingBox()

		if scaleIt then
			if box.width * selfScale > 1024 or box.height * selfScale > 1024 then
				local fitScale = math.floor(1024 / math.max(box.width, box.height))

				selfScale = math.max(1, fitScale)
			end

			self.__ani:setScale(scale * selfScale)

			size = self.__ani:getContentSize()
			box = self.__ani:getBoundingBox()
		end

		box.x = box.x - 60
		box.y = box.y - 60
		box.width = box.width + 120
		box.height = box.height + 120

		self.__ani:retain():autorelease()
		self.__ani:removeSelf()
		self.__ani:setPosition(-box.x, -box.y)

		if scaleIt then
			self:setScaleX(self:getScaleX() / selfScale)
			self:setScaleY(self:getScaleY() / selfScale)
		end

		local node = cc.Node:create()

		node:add(self.__ani):name("sprite_spine_rt")

		if box.height < 1 or box.width < 1 then
			node:setContentSize(1, 1)
		else
			node:setContentSize(box)
		end

		local rt = cc.RenderTexture:createWithNode(node, 1, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444)

		rt:setAutoDraw(true)
		rt:setClearFlags(gl.COLOR_BUFFER_BIT)
		rt:addTo(self)
		rt:setPosition(box.x, box.y)
		rt:setContentSize(box)

		self.__twoColorSprites = {
			node,
			rt
		}

		handler(rt)
	end, 0.1)
end

function CSprite:setHSLShader(hue, saturation, brightness, alpha, time, switch)
	if self.__ani == nil then
		return
	end

	if self.__shaderName == "hsl" then
		return
	end

	self.__shaderName = "hsl"

	if self:isSpine() then
		if self.__isTwoColorTint or self.__ani:isTwoColorTint() then
			self:_initRTForSpineAnimation("hsl", false, function(rt)
				cache.setHSLShader(rt:getSprite(), false, hue, saturation, brightness, alpha, time, switch)
			end)
		else
			cache.setHSLShader(self.__ani, true, hue, saturation, brightness, alpha, time, switch)
		end
	else
		cache.setHSLShader(self.__ani, self:isSpine(), hue, saturation, brightness, alpha, time, switch)
	end
end

function CSprite:setColor2Shader(color)
	if self.__ani == nil then
		return
	end

	if self.__shaderName == "color2" then
		if self.__twoColorSprites then
			local rt = self.__twoColorSprites[2]

			cache.setColor2Shader(rt:getSprite(), false, color)
		end

		return
	end

	self.__shaderName = "color2"

	if self:isSpine() then
		if self.__isTwoColorTint or self.__ani:isTwoColorTint() then
			self:_initRTForSpineAnimation("color2", true, function(rt)
				cache.setColor2Shader(rt:getSprite(), false, color)
			end)
		else
			cache.setColor2Shader(self.__ani, true, color)
		end
	else
		cache.setColor2Shader(self.__ani, self:isSpine(), color)
	end
end

function CSprite:setShihuaShader(brightness)
	if self.__ani == nil then
		return
	end

	if self.__shaderName == "shihua" then
		return
	end

	self.__shaderName = "shihua"

	if self:isSpine() then
		if self.__isTwoColorTint or self.__ani:isTwoColorTint() then
			self.__isTwoColorTint = true

			performWithDelay(self, function()
				if self.__ani == nil then
					return
				end

				if self.__shaderName ~= "shihua" then
					return
				end

				local scale = self.__ani:getScale()
				local size = self.__ani:getContentSize()
				local box = self.__ani:getBoundingBox()

				if box.height < 1 or box.width < 1 then
					self.__ani:setContentSize(1, 1)
				else
					self.__ani:setContentSize(box)
				end

				local spr = cc.utils:captureNodeSprite(self.__ani, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444, 1, -box.x, -box.y)

				spr:xy(box)
				self:addChild(spr)
				self.__ani:setScale(scale)
				self.__ani:setContentSize(size)

				self.__twoColorSprites = {
					spr
				}

				cache.setShihuaShader(spr, false, brightness)
				self.__ani:hide()
			end, 0.1)
		else
			cache.setShihuaShader(self.__ani, true, brightness)
		end
	else
		cache.setShihuaShader(self.__ani, false, brightness)
	end
end

function CSprite:setGLProgram(programName, state)
	if self.__ani == nil then
		return
	end

	if self.__shaderName == programName then
		return
	end

	self.__shaderName = programName

	if not self.__rawShaderState then
		self.__rawShaderState = self.__ani:getGLProgramState()
	end

	state = state or cache.getShader(self:isSpine(), programName)

	if state == nil and programName then
		return
	end

	if self:isSprite() then
		self.__ani:setGLProgramState(state)

		for k, v in pairs(self.__ani:getChildren()) do
			if iskindof(v, "cc.Sprite") then
				v:setGLProgramState(state)
			end
		end
	elseif self:isArmature() then
		self.__ani:setGLProgramState(state)

		for k, v in pairs(self.__ani:getChildren()) do
			if type(v) == "ccs.Bone" then
				local nodeList = v:getDisplayNodeList()

				for k1, v1 in pairs(nodeList) do
					v1:setGLProgramState(state)
				end
			end
		end
	elseif self:isSpine() then
		if state and tolua.isnull(state) then
			state = nil
		end

		if self.__isTwoColorTint then
			self.__ani:setTwoColorTint(true)
			self.__ani:retain():autorelease()
			self.__ani:removeSelf():addTo(self)
			self.__ani:setPosition(0, 0)
			self.__ani:show()

			if self.__twoColorSprites then
				for _, node in ipairs(self.__twoColorSprites) do
					node:removeSelf()
				end

				self.__twoColorSprites = nil
			end

			return
		end

		if state == nil then
			state = cc.GLProgramState:getOrCreateWithGLProgramName("ShaderPositionTextureColor_noMVP")
		end

		self.__ani:setGLProgramState(state)
	end

	return state
end

function CSprite:setTextureRect(size, rotated)
	if self.__ani == nil then
		return
	end

	if self:isSprite() then
		for k, v in pairs(self.__ani:getChildren()) do
			if iskindof(v, "cc.Sprite") then
				local rect = v:getTextureRect()
				local _size = {}

				if size.width < rect.width then
					_size.width = size.width
				else
					_size.width = rect.width
				end

				if size.height < rect.height then
					_size.height = size.height
				else
					_size.height = rect.height
				end

				v:setTextureRect(cc.rect(rect.x, rect.y, _size.width, _size.height), rotated, _size)
			end
		end
	elseif self:isArmature() then
		for k, v in pairs(self.__ani:getChildren()) do
			if iskindof(v, "ccs.Bone") then
				local nodeList = v:getDisplayNodeList()

				for k1, v1 in pairs(nodeList) do
					local rect = v1:getTextureRect()
					local _size = {}

					if size.width < rect.width then
						_size.width = size.width
					else
						_size.width = rect.width
					end

					if size.height < rect.height then
						_size.height = size.height
					else
						_size.height = rect.height
					end

					v1:setTextureRect(cc.rect(rect.x, rect.y, _size.width, _size.height), rotated, _size)
				end
			end
		end
	end
end

function CSprite:setLifeTime(time)
	return cache.setCSpriteLifeTime(self, time)
end

function CSprite:pause()
	if self.__ani == nil then
		return
	end

	if self:isArmature() then
		self.__ani:getAnimation():pause()
	elseif self:isSpine() then
		self.__ani:pause()
	end
end

function CSprite:resume()
	if self.__ani == nil then
		return
	end

	if self:isArmature() then
		self.__ani:getAnimation():resume()
	elseif self:isSpine() then
		self.__ani:resume()
	end
end

function CSprite:play(action, loop)
	local ok = false

	if self:isArmature() then
		ok = true

		if action then
			self.__ani:getAnimation():play(action)
		else
			self.__ani:getAnimation():playWithIndex(0)
		end
	elseif self:isSpine() then
		if loop or action:find("_loop") then
			ok = self.__ani:setAnimation(0, action, true)
		else
			ok = self.__ani:setAnimation(0, action, false)

			if not ok and action == "effect" then
				action = "effect_loop"
				ok = self.__ani:setAnimation(0, action, true)
			end
		end

		local soundRes = gSoundCsv and gSoundCsv[self.__aniRes] and gSoundCsv[self.__aniRes][action]

		if soundRes then
			performWithDelay(self, function()
				audio.playEffectWithWeekBGM(soundRes.res)
			end, soundRes.delay)
		end
	end

	return ok
end

function CSprite:addPlay(action)
	local ok = false

	if self:isSpine() then
		if action:find("_loop") then
			ok = self.__ani:addAnimation(0, action, true)
		else
			ok = self.__ani:addAnimation(0, action, false)
		end
	end

	return ok
end

function CSprite:findAnimation(action)
	if not action or not self.__ani then
		return false
	end

	if self:isSpine() then
		return self.__ani:findAnimation(action)
	end
end

function CSprite:removeAnimation()
	if self.__ani then
		self.__ani:removeFromParent()

		self.__ani = nil
		self.__aniRes = nil
	end

	self.__shaderName = nil
	self.__rawShaderState = nil

	return self
end

function CSprite:removeSelf()
	if self:isSpine() then
		self:setSpriteEventHandler()
	end

	self:removeAnimation()
	self:removeFromParent()

	return self
end

function CSprite:removeSelfToCache()
	if self.__rawShaderState then
		self:setGLProgram(nil, self.__rawShaderState)

		self.__rawShaderState = nil
	end

	if self:isSpine() then
		self.__ani:setToSetupPose()
		self:setSpriteEventHandler()
	end

	self:removeFromParent()

	return self
end

function CSprite:setAnimationSpeedScale(speedScale, isRelative)
	if self:isArmature() then
		local speed = isRelative and self.__ani:getAnimation():getSpeedScale() or 1

		self.__ani:getAnimation():setSpeedScale(speedScale * speed)
	elseif self:isSpine() then
		local speed = isRelative and self.__ani:getTimeScale() or 1

		self.__ani:setTimeScale(speedScale * speed)
	end

	return self
end

function CSprite:setSpriteEventHandler(handler, eventType)
	if self:isSpine() then
		if eventType then
			self.__ani:unregisterSpineEventHandler(eventType)

			if handler then
				self.__ani:registerSpineEventHandler(function(event)
					handler(eventType, event)
				end, eventType)
			end
		else
			for k, v in pairs(sp.EventType) do
				if v ~= sp.EventType.ANIMATION_DISPOSE then
					self.__ani:unregisterSpineEventHandler(v)

					if handler then
						self.__ani:registerSpineEventHandler(function(event)
							handler(v, event)
						end, v)
					end
				end
			end
		end
	end

	return self
end

function CSprite:getAni()
	return self.__ani
end

function CSprite:getBoundingBox()
	return self.__ani:getBoundingBox()
end

function CSprite:getCascadeBoundingBox()
	return cc.utils:getCascadeBoundingBox(self)
end

function CSprite:setTimeScale(scale)
	if self:isSpine() then
		return self.__ani:setTimeScale(scale)
	end

	error("only spine had setTimeScale")
end

function CSprite:setSkin(name)
	if self:isSpine() then
		return self.__ani:setSkin(name)
	end

	error("only spine had setSkin")
end

function CSprite:getBonePosition(name)
	if self:isSpine() then
		return self.__ani:getBonePosition(name)
	end

	error("only spine had getBonePosition")
end

function CSprite:getBoneRotation(name)
	if self:isSpine() then
		return self.__ani:getBoneRotation(name)
	end

	error("only spine had getBoneRotation")
end

function CSprite:getBoneRotationX(name)
	if self:isSpine() then
		return self.__ani:getBoneRotationX(name)
	end

	error("only spine had getBoneRotationX")
end

function CSprite:getBoneRotationY(name)
	if self:isSpine() then
		return self.__ani:getBoneRotationY(name)
	end

	error("only spine had getBoneRotationY")
end

function CSprite:getBoneScaleX(name)
	if self:isSpine() then
		return self.__ani:getBoneScaleX(name)
	end

	error("only spine had getBoneScaleX")
end

function CSprite:getBoneScaleY(name)
	if self:isSpine() then
		return self.__ani:getBoneScaleY(name)
	end

	error("only spine had getBoneScaleY")
end

function CSprite:getBoneShearX(name)
	if self:isSpine() then
		return self.__ani:getBoneShearX(name)
	end

	error("only spine had getBoneShearX")
end

function CSprite:getBoneShearY(name)
	if self:isSpine() then
		return self.__ani:getBoneShearY(name)
	end

	error("only spine had getBoneShearY")
end

function CSprite:modelOnly()
	self:stopAllActions()

	if self:isSpine() then
		for k, v in pairs(sp.EventType) do
			self.__ani:unregisterSpineEventHandler(v)
		end
	end
end
