-- chunkname: @src.battle.views.event_effect.effect

local isnull = tolua.isnull
local const_proxy = setmetatable({}, {
	__index = function(t, k)
		return function()
			errorInWindows("cobj has been remove")
		end
	end
})
local EventEffect = class("EventEffect")

battleEffect.EventEffect = EventEffect

function EventEffect:ctor(view, args, target)
	self.key = nil
	self.queID = nil
	self.args = args
	self.playOver = false
	self.delay = args and args.delay or 0
	self.tick = nil
	self.lifetime = args and args.lifetime
	self.view = view or gRootViewProxy:raw()
	self.target = target or self.view
	self.zOrder = args and args.zOrder or battle.EffectZOrder.none

	if device.platform == "windows" then
		self.traceback = debug.traceback()
	end

	if args then
		if args.delay then
			args.delay = nil
		end

		if args.lifetime then
			args.lifetime = nil
		end
	end
end

function EventEffect:play()
	if self.delay == 0 then
		self.tick = 0

		return self:onPlay()
	end
end

function EventEffect:onPlay()
	return
end

function EventEffect:stop()
	if not self.playOver then
		self.playOver = true

		return self:onStop()
	end
end

function EventEffect:free()
	self.playOver = true

	self:onFree()
end

function EventEffect:onFree()
	return
end

function EventEffect:onStop()
	return
end

function EventEffect:isStop()
	return self.playOver
end

function EventEffect:update(delta)
	if self.delay > 0 then
		self.delay = self.delay - delta

		if self.delay > 0 then
			return
		end

		delta = -self.delay
	end

	if self.tick == nil then
		self.tick = 0

		self:onPlay()

		if not self.onUpdate then
			return
		end
	end

	self.tick = self.tick + delta

	if self.lifetime and self.lifetime <= self.tick then
		delta = delta - (self.tick - self.lifetime)

		self:onUpdate(delta)

		return self:stop()
	end

	return self:onUpdate(delta)
end

function EventEffect:canUpdate()
	return not self.playOver and (self.onUpdate or self.delay > 0)
end

function EventEffect:debugString()
	return tostring(self)
end

function EventEffect:safeTarget()
	if isnull(self.target) then
		return const_proxy
	end

	return self.target
end

local OnceEventEffect = class("OnceEventEffect", EventEffect)

battleEffect.OnceEventEffect = OnceEventEffect

function OnceEventEffect:play()
	if self.delay == 0 then
		self:onPlay()

		return self:free()
	end
end

function OnceEventEffect:update(delta)
	self.delay = self.delay - delta

	if self.delay > 0 then
		return
	end

	self:onPlay()

	return self:free()
end

local Manager = class("Manager")

battleEffect.Manager = Manager

function Manager:ctor(key)
	self.key = key
	self.effects = {}
	self.updEffects = {}
	self.queHeadID = 1
	self.queTailID = 0
	self.queEffects = {}
	self.keyCounter = 1
	self.running = true
end

function Manager:addAndPlay(key, effect)
	if key == nil then
		key = self.keyCounter
		self.keyCounter = self.keyCounter + 1
	end

	effect:play()

	if not effect:isStop() then
		self.effects[key] = effect
		effect.key = key

		if effect:canUpdate() then
			self.updEffects[key] = effect
		end
	end

	gRootViewProxy:notify("effectUpdated")

	return effect
end

function Manager:delAndStop(key)
	local effect = self.effects[key]

	if effect then
		effect:stop()

		self.effects[key] = nil
		self.updEffects[key] = nil
	end

	gRootViewProxy:notify("effectUpdated")
end

function Manager:queueAppend(effect)
	self.queTailID = self.queTailID + 1
	self.queEffects[self.queTailID] = effect
	effect.queID = self.queTailID

	gRootViewProxy:notify("effectUpdated")

	return effect
end

function Manager:queuePrepend(effect)
	local curEffect = self.queEffects[self.queHeadID]

	if self:queueSize() > 0 and not curEffect:isStop() then
		return self:queueInsert(1, effect)
	end

	return self:queueInsert(0, effect)
end

function Manager:queueInsert(offset, effect)
	for i = self.queTailID, self.queHeadID + offset, -1 do
		self.queEffects[i].queID = i + 1
		self.queEffects[i + 1] = self.queEffects[i]
	end

	self.queTailID = self.queTailID + 1
	self.queEffects[self.queHeadID + offset] = effect
	effect.queID = self.queHeadID + offset

	gRootViewProxy:notify("effectUpdated")

	return effect
end

function Manager:queueClear()
	for id, effect in pairs(self.queEffects) do
		effect:stop()
	end

	self.queHeadID = 1
	self.queTailID = 0
	self.queEffects = {}

	gRootViewProxy:notify("effectUpdated")
end

function Manager:queueErase(id)
	local effect = self.queEffects[id]

	if effect then
		if id == self.queHeadID then
			effect:stop()
		else
			effect:free()
		end
	end

	gRootViewProxy:notify("effectUpdated")
end

function Manager:queueSize()
	return self.queTailID - self.queHeadID + 1
end

function Manager:queueInfo()
	local head, ret = self.queHeadID, {}

	while head <= self.queTailID do
		local effect = self.queEffects[head]

		table.insert(ret, string.format("%d. %s", head, effect:debugString()))

		head = head + 1
	end

	return ret
end

function Manager:update(delta)
	if not self.running then
		return false
	end

	local updated = false

	for key, effect in pairs(self.updEffects) do
		updated = true

		effect:update(delta)

		if not effect:canUpdate() then
			self.updEffects[key] = nil

			if effect:isStop() then
				self.effects[key] = nil
			end
		end
	end

	local updatedFirst = false

	while self.running and self.queHeadID <= self.queTailID do
		updated = true

		local effect = self.queEffects[self.queHeadID]

		if effect:isStop() then
			log.effect.stop(self.key, tostring(effect), self.queHeadID, "/", self.queTailID)

			self.queEffects[self.queHeadID] = nil
			self.queHeadID = self.queHeadID + 1

			if self.queHeadID <= self.queTailID then
				effect = self:getHeadEffect()

				if not effect:isStop() then
					effect:play()

					if self.playCallback then
						self.playCallback(self, self.queHeadID, effect)
					end
				end
			end
		else
			if updatedFirst then
				break
			end

			effect:update(delta)

			updatedFirst = true
		end
	end

	return updated
end

function Manager:getHeadEffect()
	if self.queTailID - self.queHeadID >= 1 and self.queEffects[self.queHeadID].zOrder > self.queEffects[self.queHeadID + 1].zOrder or self.queEffects[self.queHeadID].zOrder == battle.EffectZOrder.dead then
		for i = self.queTailID, self.queHeadID + 1, -1 do
			if self.queEffects[i - 1].zOrder > self.queEffects[i].zOrder then
				self:exchangeEffect(i - 1, i)
			end
		end
	end

	return self.queEffects[self.queHeadID]
end

function Manager:exchangeEffect(lef, rig)
	self.queEffects[lef].queID, self.queEffects[rig].queID = self.queEffects[rig].queID, self.queEffects[lef].queID
	self.queEffects[lef], self.queEffects[rig] = self.queEffects[rig], self.queEffects[lef]
end

function Manager:clear()
	self:queueClear()

	for key, effect in pairs(self.effects) do
		effect:stop()
	end

	self.effects = {}
	self.updEffects = {}
end

function Manager:resume()
	self.running = true
end

function Manager:pause()
	self.running = false
end

function Manager:setEffectPlayCallback(f)
	self.playCallback = f
end

function Manager:passOneMultWaveClear()
	for id, effect in pairs(self.queEffects) do
		if not effect.args or not effect.args.cleanTag or effect.args.cleanTag ~= battle.FilterDeferListTag.cantClean then
			self:queueErase(id)
		end
	end

	for key, effect in pairs(self.effects) do
		if not effect.args or not effect.args.cleanTag or effect.args.cleanTag ~= battle.FilterDeferListTag.cantClean then
			self:delAndStop(key)
		end
	end
end
