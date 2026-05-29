-- chunkname: @src.easy.vmproxy

require("battle.models.cow_proxy")

local defaultproxy, proxyfunc
local proxymeta = {
	__index = function(t, k)
		return proxyfunc
	end,
	__newindex = function(t, k, v)
		return
	end
}
local checkmeta = {
	__index = function(t, k)
		local f = t.__raw[k]

		if type(f) == "function" then
			return function(self, ...)
				if self == t then
					self = cow.proxyView(tostring(t.__raw), t.__raw)
				end

				return f(self, ...)
			end
		end

		if k:sub(1, 2) == "__" then
			return f
		end

		error(string.format("ViewProxy could not access non-function member %s[%s] = %s", t.__raw, k, f))
	end,
	__newindex = function(t, k, v)
		return
	end
}
local ProxyObjs = setmetatable({}, {
	__mode = "kv"
})
local ProxyResumeObjs = {}

globals.ViewProxy = class("ViewProxy")

function ViewProxy.allModelOnly()
	ProxyResumeObjs = {}

	for p, view in pairs(ProxyObjs) do
		local raw = p:raw()

		if p == gRootViewProxy then
			table.insert(ProxyResumeObjs, {
				p,
				view
			})
		end

		if raw and raw.modelOnly then
			raw:modelOnly()
		end

		p:modelOnly()

		ProxyObjs[p] = nil
	end
end

function ViewProxy.allModelResum()
	for _, data in ipairs(ProxyResumeObjs) do
		local p, view = data[1], data[2]
		local raw = p:raw()

		if raw and raw.modelOnly and raw.v then
			raw.vproxy = nil
		end

		if p.v then
			p.vproxy = nil
		end

		ProxyObjs[p] = view
	end

	ProxyResumeObjs = {}
end

function ViewProxy:ctor(view)
	self.__proxy = true
	self.v = view
	self.vproxy = nil

	if view == nil then
		self:modelOnly()
	elseif device.platform == "windows" then
		self.v = setmetatable({
			__raw = view
		}, checkmeta)
	end

	ProxyObjs[self] = view
end

function ViewProxy:modelOnly(proxy)
	self.vproxy = setmetatable(proxy or {}, proxymeta)
end

function ViewProxy:isModelOnly()
	return self.vproxy ~= nil
end

function ViewProxy:raw()
	return self:cow() or self.vproxy
end

function ViewProxy:cow()
	if device.platform == "windows" then
		return self.v
	end

	return cow.proxyView(tostring(self.v), self.v)
end

if device.platform == "windows" then
	function ViewProxy:raw()
		return self:cow() and self:cow().__raw or self.vproxy
	end
end

function ViewProxy:proxy()
	return self.vproxy or self:cow()
end

function ViewProxy:notify(...)
	if self.vproxy == nil and self.v.onViewProxyNotify then
		return self:cow():onViewProxyNotify(...)
	end
end

function ViewProxy:call(...)
	if self.vproxy == nil and self.v.onViewProxyCall then
		return self:cow():onViewProxyCall(...)
	end
end

function ViewProxy:getProxy(...)
	if self.vproxy == nil and self.v.onViewProxyCall then
		local view = self:cow():onViewProxyCall(...)
		local proxy = ViewProxy.new(view)

		if self.v.onViewBeProxy then
			self:cow():onViewBeProxy(view, proxy)
		end

		return proxy
	end

	return defaultproxy
end

defaultproxy = ViewProxy.new()

function proxyfunc(...)
	return defaultproxy
end

local isObject = isObject
local isClass = isClass
local ProtectWritePass = {
	hash = true,
	keyhash = true,
	order = true
}

local function _readOnlyObject(obj, proxy)
	if device.platform ~= "windows" and (proxy == nil or itertools.isempty(proxy)) then
		return obj
	end

	proxy = proxy or {}

	if not proxy.__tostring then
		function proxy.__tostring(tp)
			return string.format("readonly(%s)", tostring(table.getraw(tp)))
		end
	end

	return table.proxytable(obj, proxy, nil, function(t, k, v)
		if ProtectWritePass[k] then
			return true
		end

		error(string.format("%s read only! do not set %s!", tostring(t), k))
	end)
end

local function _readOnlyProxy(objOrTable, proxy)
	if objOrTable == nil then
		return nil
	end

	if type(objOrTable) == "table" then
		if table.isproxy(objOrTable) then
			return objOrTable
		end

		return _readOnlyObject(objOrTable, proxy)
	end

	return objOrTable
end

function globals.readOnlyProxy(objOrTable, proxy)
	local ret = _readOnlyProxy(objOrTable, proxy)

	if not ret then
		error(string.format("can not proxy with %s!", tostring(objOrTable)))
	end

	return ret
end
