-- chunkname: @src.battle.easy.effect

function battleEasy.effect(id, fOrStr, args)
	local typ = type(fOrStr)

	if typ == "function" then
		gRootViewProxy:proxy():onEventEffect(id, "callback", {
			func = fOrStr,
			delay = args and args.delay,
			lifetime = args and args.lifetime
		})
	elseif typ == "string" then
		gRootViewProxy:proxy():onEventEffect(id, fOrStr, args)
	else
		error("only function or string be allowed")
	end
end

function battleEasy.queueEffect(fOrStr, args)
	local typ = type(fOrStr)

	if typ == "function" then
		gRootViewProxy:proxy():onEventEffectQueue("callback", {
			func = fOrStr,
			delay = args and args.delay,
			lifetime = args and args.lifetime,
			zOrder = args and args.zOrder
		})
	elseif typ == "string" then
		gRootViewProxy:proxy():onEventEffectQueue(fOrStr, args)
	else
		error("only function or string be allowed")
	end
end

function battleEasy.queueNotify(msg, ...)
	assert(type(msg) == "string", "msg not string type")

	local args = {
		...
	}

	gRootViewProxy:proxy():onEventEffectQueue("callback", {
		func = function()
			gRootViewProxy:notify(msg, unpack(args))
		end
	})
end

function battleEasy.queueZOrderNotify(msg, zOrder, ...)
	assert(type(msg) == "string", "msg not string type")

	local args = {
		...
	}

	gRootViewProxy:proxy():onEventEffectQueue("callback", {
		func = function()
			gRootViewProxy:notify(msg, unpack(args))
		end,
		zOrder = zOrder
	})
end

function battleEasy.queueNotifyFor(view, msg, ...)
	assert(view, "view is nil, plz use queueNotify")
	assert(type(msg) == "string", "msg not string type")

	local args = {
		...
	}

	gRootViewProxy:proxy():onEventEffectQueue("callback", {
		func = function()
			view:notify(msg, unpack(args))
		end
	})
end

function battleEasy.deferEffect(...)
	error("temporary")

	return gRootViewProxy:proxy():addCallbackToCurDeferList(...)
end

function battleEasy.deferCallback(f)
	return gRootViewProxy:proxy():addCallbackToCurDeferList(f)
end

function battleEasy.deferNotify(view, msg, ...)
	local f = functools.handler(view or gRootViewProxy, "notify", msg, ...)

	return gRootViewProxy:proxy():addCallbackToCurDeferList(f)
end

function battleEasy.deferCallbackCantJump(f)
	return gRootViewProxy:proxy():addCallbackToCurDeferList(f, battle.FilterDeferListTag.cantJump)
end

function battleEasy.deferNotifyCantJump(view, msg, ...)
	local f = functools.handler(view or gRootViewProxy, "notify", msg, ...)

	return gRootViewProxy:proxy():addCallbackToCurDeferList(f, battle.FilterDeferListTag.cantJump)
end

function battleEasy.deferNotifyCantClean(view, msg, ...)
	local f = functools.handler(view or gRootViewProxy, "notify", msg, ...)

	return gRootViewProxy:proxy():addCallbackToCurDeferList(f, battle.FilterDeferListTag.cantClean)
end

function battleEasy.pushNotifyCantJump(view, msg, id, isLast, ...)
	local f = functools.handler(view, "notify", msg, ...)
	local tag = battle.queueCallBackTag[msg]
	local isLast = isLast

	view:proxy():pushQueueCallBack(tag, id, f, isLast)

	local function callback()
		local f = view:proxy():popQueueCallBack(tag, id, isLast)

		if f and type(f) == "function" then
			f()
		end
	end

	return battleEasy.deferCallbackCantJump(callback)
end

function battleEasy.pushNotifyRootView(msg, ...)
	local f = functools.handler(gRootViewProxy, "notify", msg, ...)
	local tag = battle.queueCallBackTag[msg]

	gRootViewProxy:proxy():pushQueueCallBack(tag, msg, f, false)

	local function callback()
		local f = gRootViewProxy:proxy():popQueueCallBack(tag, msg, false)

		if f and type(f) == "function" then
			f()
		end
	end

	return battleEasy.deferCallbackCantJump(callback)
end

function battleEasy.priorDataTable(initVal, varName)
	local tb = {
		__isDirty = true,
		__value = {},
		__varName = varName
	}

	assert(battle.VariablePriorityTb[varName], "battle.priorDataTable need priority define")

	local defaultP = battle.VariablePriorityTb[varName].default

	tb.__value[defaultP] = initVal

	function tb:get()
		local ret = self.__value

		if self.__isDirty then
			for key, _ in pairs(ret) do
				self.__lastKey = (self.__lastKey == nil or key > self.__lastKey) and key or self.__lastKey
			end

			self.__isDirty = false
		end

		return ret[self.__lastKey]
	end

	function tb:set(value, reason, isRelease)
		local prior = battle.VariablePriorityTb[self.__varName][reason] or battle.VariablePriorityTb[self.__varName].default

		if isRelease and prior ~= battle.VariablePriorityTb[self.__varName].default then
			self.__value[prior] = nil
		else
			self.__value[prior] = value
		end

		self.__isDirty = true
		self.__lastKey = nil
	end

	return tb
end

function battleEasy.getTraceInfo(depth, from)
	if device.platform ~= "windows" then
		return nil
	end

	depth = depth or 2
	from = from or 2

	local info
	local debugTrace = {}

	for i = 1, depth do
		info = debug.getinfo(i + from, "nSl")

		if not info then
			break
		end

		debugTrace[i] = {
			name = info.name,
			file = info.short_src,
			line = info.currentline
		}
	end

	return debugTrace
end

local function wrapIfNotModelOnly(f)
	return function(...)
		if gRootViewProxy:isModelOnly() then
			return
		end

		return f(...)
	end
end

battleEasy.modifierTargetsViewVisible = wrapIfNotModelOnly(function(targets, visible)
	if gRootViewProxy:isModelOnly() then
		return
	end

	for _, tar in ipairs(targets) do
		tar.view:proxy():setVisible(false)
		tar.view:proxy():setVisibleEnable(false)
	end
end)
battleEasy.mergeDeferList = wrapIfNotModelOnly(function(ori, deferList)
	if gRootViewProxy:isModelOnly() then
		return
	end

	for _, func in deferList:ipairs() do
		ori:push_back(func)
	end
end)
