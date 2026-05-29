-- chunkname: @src.battle.app_views.battle.view_effect

function BattleView:onEventEffect(obj, typ, args)
	local sprite

	if obj then
		sprite = self:onViewProxyCall("getSceneObj", tostring(obj))
	end

	local view = sprite or self
	local target = sprite or view
	local effect = newEventEffect(typ, view, args, target)

	return self.effectManager:addAndPlay(nil, effect)
end

function BattleView:onEventEffectByObj(obj, typ, args)
	local sprite

	if obj then
		sprite = self:onViewProxyCall("getSceneObj", tostring(obj))
	end

	if not sprite then
		return
	end

	local effect = newEventEffect(typ, sprite, args, sprite)

	return self.effectManager:addAndPlay(nil, effect)
end

function BattleView:onEventEffectQueue(type, args)
	local target = self
	local effect = newEventEffect(type, self, args, target)

	if self:onViewProxyCall("checkExtraRoundCache", effect) then
		return
	end

	return self.effectManager:queueAppend(effect)
end

function BattleView:onEventEffectQueueFront(type, args)
	local target = self
	local effect = newEventEffect(type, self, args, target)

	if self:onViewProxyCall("checkExtraRoundCache", effect, true) then
		return
	end

	return self.effectManager:queuePrepend(effect)
end

function BattleView:onEventEffectQueueFor(view, type, args)
	local target = view
	local effect = newEventEffect(type, view, args, target)

	if self:onViewProxyCall("checkExtraRoundCache", effect) then
		return
	end

	return self.effectManager:queueAppend(effect)
end

function BattleView:onEventEffectCancel(effect)
	if effect.key then
		self.effectManager:delAndStop(effect.key)
	elseif effect.queID then
		self.effectManager:queueErase(effect.queID)
	end

	self:onViewProxyNotify("mergeEventEffectCancel", effect)
end

local globalDeferListKey = 1
local popDebug = setmetatable({}, {
	__mode = "k"
})

local function deferListKey(skillID, processID, segID)
	local key

	if skillID or processID or segID then
		key = ""

		if skillID then
			key = key .. string.format("skill_%s|", skillID)
		end

		if processID then
			key = key .. string.format("process_%s|", processID)
		end

		if segID then
			key = key .. string.format("seg_%s|", segID)
		end

		key = key .. math.random()
	end

	return key or globalDeferListKey
end

local function getDeferMapKeys(self)
	return tostring(dumps(itertools.keys(self.deferListMap)))
end

function BattleView:pushDeferList(skillID, processID, segID)
	local key = deferListKey(skillID, processID, segID)
	local list = CVector.new()

	if key == globalDeferListKey then
		self.deferListMap:push_front(list)
	else
		self.deferListMap:push_back(list)
	end

	self.curDeferList = list

	return key
end

function BattleView:popDeferList(key)
	key = key or globalDeferListKey

	local list

	if self.deferListMap:empty() then
		errorInWindows("deferListMap is empty key?!", key)

		return
	end

	if key == globalDeferListKey then
		list = self.deferListMap:pop_front()

		self:pushDeferList()
	else
		list = self.deferListMap:pop_back()
		self.curDeferList = self.deferListMap:back()
	end

	if device.platform == "windows" then
		popDebug[list] = battleEasy.getTraceInfo(3)
	end

	return list
end

function BattleView:addCallbackToCurDeferList(f, tag)
	if self.curDeferList == nil then
		assertInWindows(self.curDeferList, "curDeferList is nil?! %s", getDeferMapKeys(self))

		return
	end

	self.curDeferList:push_back({
		func = f,
		tag = tag or battle.FilterDeferListTag.none,
		cbTrace = battleEasy.getTraceInfo(3)
	})
end

function BattleView:flushCurDeferList()
	if self.curDeferList == nil then
		assertInWindows(self.curDeferList, "curDeferList is nil?! %s", getDeferMapKeys(self))

		return
	end

	local key
	local list = self.curDeferList

	self.curDeferList = nil

	for k, l in self.deferListMap:ipairs() do
		if list == l then
			self.deferListMap:erase(k)

			if k == globalDeferListKey then
				self:pushDeferList()

				break
			end

			self.curDeferList = self.deferListMap:back()

			break
		end
	end

	self:runDeferToQueue(list)
end

function BattleView:flushAllDeferList()
	local list = self.deferListMap[globalDeferListKey]

	while not self.deferListMap:empty() do
		list = self.deferListMap:pop_front()

		if not list:empty() then
			self:runDeferToQueue(list)
		end
	end

	self:pushDeferList()
end

function BattleView:runDeferToQueue(list)
	if not list then
		return
	end

	for i, f in list:ipairs() do
		if self:filterTagCheck(f.tag) then
			self:onEventEffectQueue("callback", {
				func = f.func,
				cleanTag = f.tag,
				cbTrace = f.cbTrace,
				deferListTrace = battleEasy.getTraceInfo(2, 3),
				deferListPopTrace = popDebug[list]
			})
		end
	end

	popDebug[list] = nil
	self.filterMap = {}
end

function BattleView:runDeferToQueueFront(list)
	if not list then
		return
	end

	while list:size() > 0 do
		local f = list:pop_back()

		if self:filterTagCheck(f.tag) then
			self:onEventEffectQueueFront("callback", {
				func = f.func,
				cleanTag = f.tag,
				cbTrace = f.cbTrace,
				deferListTrace = battleEasy.getTraceInfo(2, 3),
				deferListPopTrace = popDebug[list]
			})
		end
	end

	popDebug[list] = nil
	self.filterMap = {}
end

function BattleView:runDefer(list)
	if not list then
		return
	end

	for i, f in list:ipairs() do
		if self:filterTagCheck(f.tag) then
			self:onEventEffect(nil, "callback", {
				func = f.func,
				cbTrace = f.cbTrace,
				deferListTrace = battleEasy.getTraceInfo(2, 3),
				deferListPopTrace = popDebug[list]
			})
		end
	end

	popDebug[list] = nil
	self.filterMap = {}
end

function BattleView:filterTagCheck(tag)
	return table.length(self.filterMap) == 0 or table.length(self.filterMap) > 0 and self.filterMap[tag]
end

function BattleView:filter(tag)
	self.filterMap[tag] = true

	return self
end

function BattleView:setEffectDebugEnabled(flag)
	return BattleSprite.setEffectDebugEnabled(self, flag)
end

function BattleView:setEffectDebugBreakpoint(cb)
	self.effectManager:resume()

	if cb == nil then
		self.effectManager:setEffectPlayCallback(nil)

		return
	end

	self.effectManager:setEffectPlayCallback(function(...)
		if cb(...) then
			self.effectManager:resume()
		else
			self.effectManager:pause()
		end
	end)
end
