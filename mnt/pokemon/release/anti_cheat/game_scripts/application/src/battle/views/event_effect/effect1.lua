-- chunkname: @src.battle.views.event_effect.effect1

local _min = math.min
local _max = math.max
local SegShow = class("SegShow", battleEffect.EventEffect)

battleEffect.SegShow = SegShow

function SegShow:onPlay()
	self.idx = 1
	self.model = self.view.model
	self.viewKey = self.view.key
	self.segs = self.args.damageSeg or self.args.hpSeg
	self.intervals = self.args.segInterval
	self.waitTick = self.intervals[1]

	if not self.args.processArgs or not self.args.processArgs.values[self.model.id] then
		local processId = self.args.processArgs and self.args.processArgs.process and self.args.processArgs.process.id or -1
		local unitId = self.model and self.model.unitID or -1

		errorInWindows("SegShow Args valueArgs nil,unitId = %s,processCfg id = %s", unitId, processId)

		return self:free()
	end

	self.valueArgs = self.args.processArgs.values[self.model.id]

	if self.args.processArgs.buffTb then
		self.buffArgs = self.args.processArgs.buffTb[self.model.id]
	end

	self.type = self.args.processArgs.process.segType
	self.numShow = self.type == self.args.processArgs.showType

	if self.type == battle.SkillSegType.damage then
		self.view:beHit(0, 0)
	end
end

function SegShow:onUpdate(delta)
	local battleView = gRootViewProxy:raw()
	local existed = gRootViewProxy:call("isObjExisted", self.viewKey)

	if not existed then
		return self:free()
	end

	local endSeg = table.length(self.segs)

	if self.type == battle.SkillSegType.damage then
		self.view:beHit(delta)
	end

	if self.tick >= self.waitTick and battleView then
		local valueArg = self.valueArgs[self.idx] or {}

		if not assertInWindows(valueArg, "effect_event seg is missed!!") then
			local v = valueArg.value and valueArg.value:get() or 0

			if self.idx == 1 and self.buffArgs then
				battleView:runDefer(self.buffArgs)
			end

			battleView:runDefer(valueArg and valueArg.deferList)

			if self.numShow then
				gRootViewProxy:notify("showNumber", {
					delta = v,
					skillId = self.args.processArgs.skillId,
					typ = self.type
				})
			end

			if self.type == battle.SkillSegType.damage then
				self.view:beHit(0, 600)
			end
		end

		self.idx = self.idx + 1

		if endSeg < self.idx or not self.valueArgs[self.idx] then
			if self.type == battle.SkillSegType.damage then
				battleEasy.effect(self.view.model, function()
					local existed = gRootViewProxy:call("isObjExisted", self.viewKey)

					if not existed then
						return
					end

					if self.view.actionState == "hit" then
						self.view:setActionState(battle.SpriteActionTable.standby)
					end
				end, {
					delay = self.view:getLeftBeHitTime()
				})
			end

			return self:stop()
		end

		self.waitTick = self.waitTick + self.intervals[self.idx] or 0
	end
end

function SegShow:onFree()
	return
end

function SegShow:onStop()
	return
end

local Sound = class("Sound", battleEffect.EventEffect)

battleEffect.Sound = Sound

function Sound:onPlay()
	local args = self.args.music and self.args.music or self.args.sound
	local isLoop = args.loop > 0
	local battleView = gRootViewProxy:raw()

	if args.bgmChanged then
		audio.pauseMusic()

		battleView.bgmChanged = true
	end

	self.handle = audio.playEffectWithWeekBGM(args.res, isLoop)

	if not isLoop then
		self:free()
	end
end

function Sound:onStop()
	if self.handle then
		audio.stopSound(self.handle)

		self.handle = nil
	end
end

function Sound:debugString()
	local args = self.args.music and self.args.music or self.args.sound

	return string.format("Sound: %s", args.res)
end

local Music = class("Music", battleEffect.OnceEventEffect)

battleEffect.Music = Music

local musicOp = {
	play = audio.playMusic,
	stop = audio.stopMusic,
	pause = audio.pauseMusic,
	resume = audio.resumeMusic
}

function Music:onPlay()
	local args = self.args.music
	local battleView = gRootViewProxy:raw()

	if args.res then
		musicOp[args.op](args.res, args.isLoop or false)
	else
		musicOp[args.op]()
	end

	if args.bgmChanged then
		battleView.bgmChanged = true
	end
end

function Music:debugString()
	local args = self.args.music

	return string.format("Music: %s", args.res)
end

local ShowCards = class("ShowCards", battleEffect.EventEffect)

battleEffect.ShowCards = ShowCards

function ShowCards:onPlay()
	if self.args.showCards == 1 then
		for k = 1, SELF_HERO_COUNT do
			if self.showCardIDs[k] then
				local obj = self.showCardIDs[k]

				if obj then
					gRootViewProxy:notify("processSkillTargetHide", tostring(obj), false)
				end
			end
		end
	elseif self.args.showCards == 2 then
		for k = 1, SELF_HERO_COUNT do
			local obj = self.showCardIDs[k]
			local flag = obj and not obj:isDeath() and obj.id ~= self.owner.id

			if flag then
				for k, v in pairs(self.sputteringTargets) do
					if obj.id == v.id then
						flag = false
					end
				end
			end

			if flag then
				gRootViewProxy:notify("processSkillTargetHide", tostring(obj), true)
			else
				gRootViewProxy:notify("processSkillTargetHide", tostring(obj), false)
			end
		end
	end
end

function ShowCards:onStop()
	return
end

local Shaker = class("Shaker", battleEffect.EventEffect)

battleEffect.Shaker = Shaker

function Shaker:onPlay()
	self.view = gRootViewProxy:raw()
	self.target = self.view

	local shakerArgs = self.args.shaker

	self:resetShaker()

	self.disx = shakerArgs.disx or 0
	self.disy = shakerArgs.disy or 0
	self.isRepeat = shakerArgs.isRepeat

	if self.isRepeat and self.args.segInterval then
		self.timeList = self.args.segInterval
		self.timer = 0
		self.seg = 1
	end

	if self:shakerCountOver() then
		self:stop()
	end
end

function Shaker:onStop()
	self:safeTarget():setPosition(0, 0)
end

function Shaker:resetShaker()
	local shakerArgs = self.args.shaker

	self.lastTime = shakerArgs.lastTime or shakerArgs.endT - shakerArgs.beginT
	self.count = shakerArgs.count or 1
	self.dur = 0
	self.wait = shakerArgs.beginT or 0
	self.interval = shakerArgs.interval or 0
end

function Shaker:waiting()
	return self.wait >= 0
end

function Shaker:shakerIng()
	return self.dur > 0
end

function Shaker:shakerCountOver()
	return self.count <= 0
end

function Shaker:needRepeat()
	if not self.timeList or not self.seg then
		return false
	end

	return self.timeList[self.seg + 1]
end

function Shaker:repeatWaiting()
	return self.timeList[self.seg + 1] > self.timer
end

function Shaker:onUpdate(delta)
	if self.timer then
		self.timer = self.timer + delta
	end

	if self:shakerIng() then
		self.dur = self.dur - delta

		if self.dur > 0 then
			local x = math.random(-self.disx, self.disx)
			local y = math.random(-self.disy, self.disy)

			self.target:setPosition(x, y)
		else
			self.target:setPosition(0, 0)
		end
	elseif self:shakerCountOver() then
		if self:needRepeat() then
			if not self:repeatWaiting() then
				self.seg = self.seg + 1
				self.timer = 0

				self.target:setPosition(0, 0)
				self:resetShaker()
			end
		else
			return self:stop()
		end
	elseif self:waiting() then
		self.wait = self.wait - delta

		if self.wait < 0 then
			if self.count > 0 then
				self.dur = self.lastTime
				self.wait = self.interval
			end

			self.count = self.count - 1
		end
	else
		return self:stop()
	end
end

function Shaker:debugString()
	local t = self.dur or 0
	local seg = ""

	if self.seg then
		seg = string.format("%s/%s", self.seg, table.length(self.timeList))
	end

	return string.format("Shaker: %5.2f %s", t, seg)
end

local Move = class("Move", battleEffect.OnceEventEffect)

battleEffect.Move = Move

function Move:onPlay()
	log.battle.event_effect.move("受击目标表现！！！")

	self.targets = self.args.targets or {}

	local faceTo = 1

	if self.args.faceTo then
		faceTo = self.args.faceTo == 1 and 1 or -1
	end

	local ret = self:adaptArgs(faceTo)
	local lastX, lastY = 0, 0

	for _, arg in ipairs(ret) do
		if arg.t == nil then
			break
		end

		local t = arg.t / 1000

		t = _max(t, 0.01)

		local deltaX, deltaY = 0, 0

		local function actFunc()
			local spawn = transition.executeSpawn(self.target)

			spawn:delay(t)

			if arg.rot then
				spawn:rotateTo(t, arg.rot * faceTo)
			end

			if arg.scale then
				spawn:scaleTo(t, arg.scale)
			end

			if arg.x or arg.y then
				arg.x = arg.x and arg.x * faceTo or lastX
				arg.y = arg.y or lastY
				deltaX, deltaY = arg.x - lastX, arg.y - lastY
				lastX, lastY = arg.x, arg.y

				spawn:moveBy(t, deltaX, deltaY)
			end

			spawn:done()
		end

		local function actFunc2()
			local posx, posy = self.target:getCurPos()

			log.battle.event_effect.moveBefore({
				target = self.target,
				posx = posx,
				posy = posy
			})

			posx, posy = posx + deltaX, posy + deltaY

			self.target:setCurPos(cc.p(posx, posy))
			log.battle.event_effect.moveAfter({
				target = self.target,
				posx = posx,
				posy = posy
			})
		end

		local sequence = transition.executeSequence(self.target)

		if arg.delay then
			sequence:delay(arg.delay / 1000)
		end

		sequence:func(actFunc):func(actFunc2):done()
	end
end

local function getCloseXY(targets, objPosTb, selfPos, per)
	per = 1 - per

	local maxX, maxY, minX, minY = -math.huge, -math.huge, math.huge, math.huge

	for id, pos in pairs(objPosTb) do
		maxX = _max(maxX, pos.x)
		minX = _min(minX, pos.x)
		maxY = _max(maxY, pos.y)
		minY = _min(minY, pos.y)
	end

	local targetPos = cc.p((maxX + minX) / 2, (maxY + minY) / 2)
	local xdis, ydis = targetPos.x - selfPos.x, targetPos.y - selfPos.y

	return xdis * per, ydis * per
end

function Move:adaptArgs(faceTo)
	local node = self.target

	if not node then
		return
	end

	faceTo = faceTo or 1

	local nodeX, nodeY = node:getPosition()
	local pos = node:getParent():convertToWorldSpace(cc.p(nodeX, nodeY))
	local worldPos = gGameUI.uiRoot:convertToNodeSpace(pos)
	local worldX, worldY = worldPos.x, worldPos.y
	local ret = clone(self.args.move)

	for _, arg in ipairs(ret) do
		if arg.absX or arg.absY then
			arg.absX = arg.absX and (faceTo == 1 and arg.absX or display.width - arg.absX)

			local ax = arg.absX and faceTo * (arg.absX - worldX)
			local ay = arg.absY and arg.absY - worldY

			if ax then
				arg.x = arg.x and arg.x + ax or ax
			end

			if ay then
				arg.y = arg.y and arg.y + ay or ay
			end
		end

		if arg.teamClose then
			arg.delay = arg.delay and arg.delay + 20

			if not self.objPosTb then
				local objPosTb = {}
				local selfPos

				for _, obj in pairs(self.targets) do
					if obj then
						local px, py = obj:getCurPos()

						px = faceTo == 1 and px or display.width - px
						objPosTb[obj.id] = cc.p(px, py)

						if obj.id == node.id then
							selfPos = cc.p(px, py)
						end
					end
				end

				self.objPosTb = objPosTb
				self.selfPos = selfPos
			end

			local x, y = getCloseXY(self.targets, self.objPosTb, self.selfPos, arg.teamClose)

			arg.x = arg.x and arg.x + x or x
			arg.y = arg.y and arg.y + y or y
		end
	end

	return ret
end

local Show = class("Show", battleEffect.OnceEventEffect)

battleEffect.Show = Show

function Show:onPlay()
	local args = self.args.show

	for _, arg in ipairs(args) do
		if arg.hide == nil then
			break
		end

		local sequence = transition.executeSequence(self.view)

		if arg.delay then
			sequence:delay(arg.delay / 1000)
		end

		local function doShow()
			self.view:setVisible(not arg.hide)
		end

		local function showBack()
			self.view:setVisible(arg.hide)
		end

		sequence:func(doShow)

		if arg.lastTime then
			sequence:delay(arg.lastTime / 1000)
			sequence:func(showBack)
		end

		sequence:done()
	end
end

local Delay = class("Delay", battleEffect.EventEffect)

battleEffect.Delay = Delay

function Delay:onUpdate(delta)
	return
end

function Delay:debugString()
	return string.format("Delay: %5.2f", self.lifetime - (self.tick or 0))
end

local SpriteEffect = class("SpriteEffect", battleEffect.EventEffect)

battleEffect.SpriteEffect = SpriteEffect

function SpriteEffect:onPlay()
	local typ = self.args.effectType or 0
	local res = self.args.effectRes or self.args.action
	local args = self.args.effectArgs or {}
	local battleView = gRootViewProxy:raw()

	self.onComplete = self.args.onComplete

	if self.onComplete then
		local callback = self.onComplete

		function self.onComplete()
			if self.onComplete then
				self.onComplete = nil

				callback()
				self:stop()
			end
		end
	end

	local function actFunc()
		if typ == 0 then
			if self.args.isCantMoveBigSkill then
				self.view:setPosition(self.view:getCurPos())
			end

			self.view:setActionState(res, self.onComplete)

			if self.view:isVisible() == false then
				errorInWindows("effect action: %s view visible is false", res)
				self.onComplete()
			end
		elseif typ == 1 then
			local faceTo = self.args.faceTo
			local viewScale = 3
			local pos = cc.p(0, 0)

			if args.offsetX and args.offsetY then
				pos = cc.p(faceTo * args.offsetX, args.offsetY)
			end

			self.sprite = newCSpriteWithOption(res)

			assert(self.sprite, "ERROR!!! effectArgs add res error, not find the res:", res)
			self.sprite:setAnchorPoint(cc.p(0.5, 0.5))

			args.scale = args.scale or 1

			if args.addTolayer == 0 then
				self.sprite:setScaleX(2.35)
				self.sprite:setScaleY(2)
			else
				self.sprite:setScaleX(faceTo * viewScale * args.scale)
				self.sprite:setScaleY(viewScale * args.scale)
			end

			if args.screenPos then
				if args.screenPos == 0 then
					pos = cc.pAdd(pos, display.center)
				elseif args.screenPos == 1 then
					local x, y = self.target:getCurPos()
					local effectPos = cc.p(x, y)

					pos = cc.pAdd(pos, effectPos)
				end

				self.sprite:setPosition(pos)

				if args.addTolayer == 1 then
					battleView.effectLayerUpper:add(self.sprite, args.zorder or 0)
				elseif args.addTolayer == 0 then
					battleView.stageLayer:add(self.sprite, args.zorder or 0)
				else
					battleView.effectLayerLower:add(self.sprite, args.zorder or 0)
				end
			else
				self.sprite:setPosition(pos)
				self.view:add(self.sprite, args.zorder or 0)
			end

			if self.sprite:isSpine() then
				if args.aniName then
					self.sprite:play(args.aniName)
				else
					args.aniLoop = self.sprite:play("effect_loop")

					if not args.aniLoop then
						self.sprite:play("effect")
					end
				end
			end

			local function remove()
				self:stop()
			end

			if args.aniLoop then
				if args.flytime and args.flyX and args.flyY then
					transition.executeSequence(self.sprite):moveBy(args.flytime / 1000, args.flyX * faceTo, args.flyY):func(remove):done()
				else
					transition.executeSequence(self.sprite):delay(args.lastTime and args.lastTime / 1000 or 1):func(remove):done()
				end
			elseif args.lastTime then
				transition.executeSequence(self.sprite):delay(args.lastTime / 1000):func(remove):done()
			else
				self.sprite:setSpriteEventHandler(function(_type, event)
					if _type == sp.EventType.ANIMATION_COMPLETE then
						removeCSprite(self.sprite)
					end
				end)
			end
		end
	end

	local sequence = transition.executeSequence(self.view)

	if args.delay then
		sequence:delay(args.delay / 1000)
	end

	sequence:func(actFunc):done()

	if not self.onComplete then
		self:stop()
	end
end

function SpriteEffect:onUpdate(delta)
	return
end

function SpriteEffect:onStop()
	if self.onComplete then
		if self.view.actionCompleteCallback == self.onComplete then
			self.view.actionCompleteCallback = nil
		end

		self.onComplete()
	end
end

function SpriteEffect:stop()
	if self.sprite then
		self.sprite:stopAllActions()
		removeCSprite(self.sprite)

		self.sprite = nil
	end

	battleEffect.EventEffect.stop(self)
end

function SpriteEffect:debugString()
	local args = self.args.effectArgs or {}
	local res = self.args.effectRes or self.args.action

	if args.aniName then
		res = string.format("%s#%s", res, args.aniName)
	end

	local obj = toDebugString(self.view)

	return string.format("SpriteEffect: %s -> %s", res, obj)
end

local ZOrder = class("ZOrder", battleEffect.OnceEventEffect)

battleEffect.ZOrder = ZOrder

function ZOrder:onPlay()
	local args = self.args.zOrder

	for _, arg in ipairs(args) do
		local zval = arg.zorder

		if not zval then
			break
		end

		local sequence = transition.executeSequence(self.view)

		if arg.delay then
			sequence:delay(arg.delay / 1000)
		end

		local zval0 = self.view:getLocalZOrder()

		local function setZOrder()
			zval0 = self.view:getLocalZOrder()

			self.view:setLocalZOrder(zval0 + zval)
		end

		local function setZOrderBack()
			self.view:setLocalZOrder(zval0)
		end

		sequence:func(setZOrder)

		if arg.lastTime then
			sequence:delay(arg.lastTime / 1000)
			sequence:func(setZOrderBack)
		end

		sequence:done()
	end
end
