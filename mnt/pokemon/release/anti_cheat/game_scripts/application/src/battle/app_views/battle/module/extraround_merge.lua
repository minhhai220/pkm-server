-- chunkname: @src.battle.app_views.battle.module.extraround_merge

local ExtraRoundMerge = class("ExtraRoundMerge", battleModule.CBase)

function ExtraRoundMerge:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.viewMergeCache = {
		state = {},
		queue = CVector.new()
	}
	self.sprKeys = {}
	self.sprs = {}
	self.runningList = {}
	self.delayEffects = {}
	self.waitEffect = nil
	self.isLastRound = false
end

function ExtraRoundMerge:onUpdateExtraRoundState(roundMode, force, objId, sprKey, roundId)
	local state = self.viewMergeCache.state
	local needBreak = false

	if roundMode then
		self.isLastRound = false

		if state.isCollecting and (state.objHash and state.objHash[objId] or state.force ~= force) then
			needBreak = true
		end

		state.isCollecting = true
		state.force = force
		state.objId = objId
		state.sprKey = sprKey
		state.curRound = roundId
		state.objHash = state.objHash or {}
		state.objHash[objId] = true
	else
		if state.isCollecting then
			needBreak = true
		end

		if not roundId then
			self.isLastRound = true
		end
	end

	if needBreak and state.isCollecting then
		state.isCollecting = false
		state.force = nil

		self:runAllExtraRoundCache()
	end
end

function ExtraRoundMerge:cleanWait()
	if self.waitEffect then
		self.waitEffect:stop()

		self.waitEffect = nil
	end
end

function ExtraRoundMerge:onMarkBigSkillExtraRound()
	if not self:isMergeEffectCollecting() then
		return
	end

	local queue = self:getExtraRoundCacheQueue()

	queue.isBigSkill = true
end

function ExtraRoundMerge:runAllExtraRoundCache()
	if self.viewMergeCache.queue:empty() then
		self.viewMergeCache.state = {}

		return
	end

	self.viewMergeCache.state.isRunning = true

	local hashId = {}
	local sprKeys = {}

	for _, oneRoundData in self.viewMergeCache.queue:ipairs() do
		local sprKey = oneRoundData.sprKey

		if not hashId[sprKey] then
			hashId[sprKey] = true

			table.insert(sprKeys, sprKey)
		end
	end

	self.sprKeys = sprKeys

	for _, key in ipairs(sprKeys) do
		local spr = self.parent:onViewProxyCall("getSceneObj", key)

		table.insert(self.sprs, spr)
	end

	self.waitEffect = self.parent:onEventEffectQueue("wait")
end

function ExtraRoundMerge:onUpdate()
	if not self:isMergeEffectRunning() then
		return
	end

	local runOver = true

	for idx, spr in ipairs(self.sprs) do
		if spr.effectManager:queueSize() > 0 then
			runOver = false
		else
			local key = self.sprKeys[idx]
			local data = self.runningList[key]

			self.runningList[key] = nil

			if data then
				self:runOneExtraRoundCache(data)

				runOver = false
			end
		end
	end

	if runOver then
		if self.viewMergeCache.queue:empty() then
			if table.length(self.delayEffects) > 0 then
				for _, v in ipairs(self.delayEffects) do
					self.viewMergeCache.state.replaceSpr.effectManager:queueAppend(v)
				end

				self.delayEffects = {}
			else
				self:onStop()
			end
		else
			self:runExtraRoundCache()
		end
	end
end

function ExtraRoundMerge:onStop()
	self.viewMergeCache.state = {}
	self.sprKeys = {}
	self.sprs = {}
	self.runningList = {}
	self.isLastRound = false

	self:cleanWait()
end

function ExtraRoundMerge:returnToView(oneRoundData)
	local list = oneRoundData.list

	for _, sub in ipairs(list) do
		for _, v in ipairs(sub) do
			self.parent.effectManager:queueAppend(v)
		end
	end
end

function ExtraRoundMerge:runOneExtraRoundCache(oneRoundData)
	local spr = self.parent:onViewProxyCall("getSceneObj", oneRoundData.sprKey)

	if spr then
		self.viewMergeCache.state.replaceSpr = spr

		local list = oneRoundData.list
		local first = list[1]

		if first then
			table.remove(list, 1)
		end

		if table.length(list) > 0 then
			self.runningList[oneRoundData.sprKey] = oneRoundData
		end

		for _, v in ipairs(first) do
			if v.zOrder == battle.EffectZOrder.dead then
				table.insert(self.delayEffects, v)
			else
				spr.effectManager:queueAppend(v)
			end
		end
	else
		errorInWindows("extraRound effect spr miss objId:%s", oneRoundData.objId)
	end
end

function ExtraRoundMerge:runExtraRoundCache()
	local queue = self.viewMergeCache.queue
	local ids = {}
	local runningObjIdHash = {}

	while queue:front() do
		local oneRoundData = queue:front()

		if oneRoundData.isBigSkill then
			if next(runningObjIdHash) then
				break
			end

			queue:pop_front()
			self:runOneExtraRoundCache(oneRoundData)

			break
		elseif runningObjIdHash[oneRoundData.objId] then
			break
		elseif self.isLastRound and queue:size() == 1 then
			queue:pop_front()
			self:returnToView(oneRoundData)

			break
		else
			queue:pop_front()

			runningObjIdHash[oneRoundData.objId] = true

			self:runOneExtraRoundCache(oneRoundData)
		end
	end
end

function ExtraRoundMerge:checkExtraRoundCache(effect, isPrepend)
	if self:isMergeEffectCollecting() then
		self:collectExtraRoundEffect(effect, isPrepend)

		return true
	end

	local spr = self.viewMergeCache.state.replaceSpr

	if spr then
		if effect.zOrder == battle.EffectZOrder.dead then
			table.insert(self.delayEffects, effect)
		elseif isPrepend then
			spr.effectManager:queuePrepend(effect)
		else
			spr.effectManager:queueAppend(effect)
		end

		return true
	end

	return false
end

function ExtraRoundMerge:getExtraRoundCacheQueue()
	local state = self.viewMergeCache.state
	local objId = state.objId
	local sprKey = state.sprKey
	local curRound = state.curRound
	local last = self.viewMergeCache.queue:back()

	if not last or last.roundId ~= curRound then
		self.viewMergeCache.queue:push_back({
			isBigSkill = false,
			list = {
				{}
			},
			objId = objId,
			sprKey = sprKey,
			roundId = curRound
		})

		last = self.viewMergeCache.queue:back()
	end

	return last
end

function ExtraRoundMerge:onExtraRoundModelWait()
	if not self:isMergeEffectCollecting() then
		return
	end

	local queue = self:getExtraRoundCacheQueue()

	table.insert(queue.list, {})
end

function ExtraRoundMerge:collectExtraRoundEffect(effect, isPrepend)
	local queue = self:getExtraRoundCacheQueue()
	local list = queue.list
	local len = table.length(queue.list)

	if isPrepend then
		table.insert(list[len], 1, effect)
	else
		table.insert(list[len], effect)
	end
end

function ExtraRoundMerge:isMergeEffectRunning()
	return self.viewMergeCache.state.isRunning
end

function ExtraRoundMerge:isMergeEffectCollecting()
	return self.viewMergeCache.state.isCollecting
end

function ExtraRoundMerge:onMergeEventEffectCancel(effect)
	local spr = self.viewMergeCache.state.replaceSpr

	if spr then
		if effect.key then
			spr.effectManager:delAndStop(effect.key)
		elseif effect.queID then
			spr.effectManager:queueErase(effect.queID)
		end
	end
end

return ExtraRoundMerge
