-- chunkname: @src.battle.models.cow_proxy

globals.cow = {}

local nil_value = "__nil_in_begin__"
local conv2proxy, cow_proxy, cow_cdx_proxy
local g_enable_cow = false
local g_enable_log = false
local g_watch_begin = false
local g_lookup_table = {}
local g_data, g_proxy, g_proxy_raw, g_proxy_cdx, g_write, g_app_data
local cow_table = {}
local node_proxy = {}
local string_caption = string.caption
local table_insert = table.insert
local table_remove = table.remove
local table_sort = table.sort
local table_getn = table.getn
local table_maxn = table.maxn
local table_concat = table.concat
local table_getraw = table.getraw
local table_isproxy = table.isproxy
local table_isimmutable = table.isimmutable
local string_format = string.format
local lua_type = lua_type or type
local lua_pairs = lua_pairs or pairs
local lua_ipairs = lua_ipairs or ipairs
local rawget = rawget

local function isDebugPrint()
	return false
end

local function debugPrint(...)
	return
end

if g_enable_cow and g_enable_log and device.platform == "windows" then
	local function isDebugPrint()
		return true
	end

	local function debugPrint(...)
		print("[COW]", ...)
	end
end

local function create_write(t)
	local w = g_write[t]

	if w == nil then
		w = {}
		g_write[t] = w
	end

	if w.__isclone then
		return
	end

	return w
end

local function _rawget(t, key)
	if lua_type(t) == "table" then
		return rawget(t, key)
	end

	return t[key]
end

local function get_cow_raw(t)
	if lua_type(t) == "table" then
		local rt = rawget(t, "__cow_raw")

		if rt ~= nil then
			return rt
		end
	end

	return t
end

local function get_raw_in_cow(t)
	return _rawget(t, "__cow_raw")
end

function cow_table.insert(t, ...)
	local rt = get_raw_in_cow(t)

	if rt then
		t:__clone()
	else
		rt = t
	end

	return table_insert(rt, ...)
end

function cow_table.remove(t, ...)
	local rt = get_raw_in_cow(t)

	if rt then
		t:__clone()
	else
		rt = t
	end

	return table_remove(rt, ...)
end

function cow_table.sort(t, ...)
	local rt = get_raw_in_cow(t)

	if rt then
		t:__clone()
	else
		rt = t
	end

	return table_sort(rt, ...)
end

function cow_table.concat(t, ...)
	return table_concat(table_getraw(t), ...)
end

function cow_table.getn(t)
	return table_getn(table_getraw(t))
end

function cow_table.maxn(t)
	return table_maxn(table_getraw(t))
end

local lua_table = {}

for k, f in lua_pairs(table) do
	lua_table[k] = f
end

for k, _ in lua_pairs(cow_table) do
	lua_table[k] = table[k]
end

local function cow_clone(object)
	local function _copy(object)
		if lua_type(object) ~= "table" then
			return object
		elseif g_lookup_table[object] then
			return g_lookup_table[object]
		elseif get_raw_in_cow(object) then
			return object
		end

		g_app_data._clone_t_count = g_app_data._clone_t_count + 1

		local newObject = {
			__isclone = object
		}

		g_lookup_table[object] = newObject

		for key, value in lua_pairs(object) do
			newObject[key] = value
		end

		return setmetatable(newObject, getmetatable(object))
	end

	return _copy(object)
end

local function cow_revert(t)
	local typ = lua_type(t)

	if typ ~= "table" and typ ~= "userdata" then
		return t
	end

	local rt = get_raw_in_cow(t)

	if rt ~= nil then
		return cow_revert(rt)
	end

	local tref = _rawget(t, "__isclone")

	if tref ~= nil then
		return cow_revert(tref)
	end

	local w = g_write[t]

	if w == nil then
		return t
	end

	g_write[t] = nil
	g_app_data._revert_t_count = g_app_data._revert_t_count + 1

	if w.__isclone then
		debugPrint("revert by clone", t, w.__isclone)
		assert(t == w.__isclone, "w clone must with t")

		w.__isclone = nil

		for k, v in lua_pairs(t) do
			if w[k] == nil then
				t[k] = nil

				debugPrint("revert.del1", t, k)
			end
		end
	end

	for k, v in lua_pairs(w) do
		if v == nil_value then
			t[k] = nil

			debugPrint("revert.del2", t, k)
		else
			local new = isDebugPrint() and t[k]

			t[k] = cow_revert(v)

			if isDebugPrint() then
				local _ = debugPrint("revert", t, k, new, "->", t[k])
			end
		end
	end

	return t
end

function conv2proxy(k, v)
	if v == nil then
		return nil
	end

	local vtype = lua_type(v)

	if vtype ~= "table" and vtype ~= "userdata" then
		return v
	end

	local pv = g_proxy[v]

	if pv ~= nil then
		return pv
	end

	local rv = g_proxy_raw[v]

	if rv ~= nil then
		return v
	end

	if vtype == "table" then
		if table_isimmutable(v) or table_isproxy(v) then
			return v
		end

		local pv = cow_proxy(k, v)

		g_proxy[v] = pv
		g_proxy_raw[pv] = v

		return pv
	elseif vtype == "userdata" then
		return cow.proxyView(k, v)
	end

	return v
end

local function write_watch(t, k, oldv)
	local w = create_write(t)

	if not w then
		return
	end

	if w[k] == nil then
		if oldv == nil then
			oldv = nil_value
		end

		w[k] = oldv

		debugPrint("write backup", t, k, oldv)
	end
end

node_proxy.attribute = {}

function node_proxy:watch_begin(t)
	self.__children = {}
	self.__operate = {
		setPosition = {
			t:getPosition()
		}
	}

	for k, v in pairs(node_proxy.attribute) do
		self.__operate[k] = {
			t[v](t)
		}
	end

	for _, node in ipairs(t:getChildren()) do
		table_insert(self.__children, {
			ref = 1,
			is_add = false,
			node = node,
			getName = function(data)
				return data.node:getName()
			end
		})
	end

	g_write[self] = t
end

function node_proxy.record_set(name)
	node_proxy[name] = function(self, ...)
		self.__operate[name] = {
			...
		}
	end
end

function node_proxy:attribute_set(name, set, get)
	set = set or {}
	set[1] = set[1] or "set" .. string_caption(name)
	set[2] = set[2] or function(self, value)
		self.__operate[set[1]] = {
			value
		}
	end
	get = get or {}
	get[1] = get[1] or "get" .. string_caption(name)
	get[2] = get[2] or function(self)
		return self.__operate[set[1]][1]
	end
	node_proxy[set[1]] = set[2]
	node_proxy[get[1]] = get[2]
	node_proxy.attribute[set[1]] = get[1]
end

function node_proxy:addChild(node, z, name)
	table_insert(self.__children, {
		is_add = true,
		ref = 1,
		node = node,
		z = z,
		name = name,
		getName = function(_self)
			local tmpName = _self.name or node:getName()

			if tmpName == "" then
				return nil
			else
				return tmpName
			end
		end
	})
end

function node_proxy:removeFromParent()
	local parent = self:getParent()
	local view_proxy = g_proxy[parent]

	view_proxy = view_proxy or cow.proxyView(parent:getName(), parent)

	node_proxy.removeChildByName(view_proxy, self:getName())
end

function node_proxy:getChildByName(name)
	for k, v in ipairs(self.__children) do
		if v:getName() == name then
			return cow.proxyView(name, v.node)
		end
	end
end

function node_proxy:removeChildByName(name)
	for k, v in ipairs(self.__children) do
		if v:getName() == name then
			v.ref = v.ref - 1

			break
		end
	end
end

function node_proxy:getChildrenCount()
	local count = 0

	for k, v in ipairs(self.__children) do
		if v.ref > 0 then
			count = count + 1
		end
	end

	return count
end

function node_proxy:setPosition(x, y)
	if y then
		self.__operate.setPosition = {
			x,
			y
		}
	else
		self.__operate.setPosition = {
			x
		}
	end
end

function node_proxy:getPosition()
	return self.__operate.setPosition[1], self.__operate.setPosition[2]
end

node_proxy:attribute_set("z", {
	"setLocalZOrder"
}, {
	"getLocalZOrder"
})
node_proxy:attribute_set("x", {
	"setPositionX"
}, {
	"getPositionX"
})
node_proxy:attribute_set("y", {
	"setPositionY"
}, {
	"getPositionY"
})
node_proxy:attribute_set("scaleX")
node_proxy:attribute_set("scaleY")
node_proxy:attribute_set("name")
node_proxy:attribute_set("contentSize")
node_proxy:attribute_set("visible", {}, {
	"isVisible"
})
node_proxy.record_set("runAction")
node_proxy.record_set("play")
node_proxy.record_set("setSkin")
node_proxy.record_set("setEnabled")
node_proxy.record_set("setTouchEnabled")
node_proxy.record_set("setAnchorPoint")

function node_proxy:revert(revert)
	if revert then
		return
	end

	local t = get_raw_in_cow(self)
	local name

	for _, data in ipairs(self.__children) do
		name = data:getName()

		if data.ref <= 0 and not data.is_add then
			t:removeChildByName(name)
		elseif data.ref > 0 and data.is_add then
			t:add(data.node, data.z, name)
		end
	end

	for k, v in pairs(self.__operate) do
		t[k](t, unpack(v))
	end
end

function cow_cdx_proxy(name, t)
	local proxy = {
		__proxy = true,
		__iscdx = true,
		__raw = t,
		__cow_raw = t,
		__name = name,
		__revert = {}
	}

	node_proxy.watch_begin(proxy, t)

	local mt = {
		__index = function(_, k)
			local v = t[k]

			if type(v) == "function" and cc.Node[k] == v then
				local _v = v

				if k == "addChild" then
					function v(_, arg1, ...)
						return _v(t, get_raw_in_cow(arg1) or arg1, ...)
					end
				else
					function v(_, ...)
						return _v(t, ...)
					end
				end
			end

			if not g_watch_begin then
				return v
			end

			return node_proxy[k] or conv2proxy(k, v)
		end,
		__newindex = function(_, k, v)
			k = get_cow_raw(k)
			v = get_cow_raw(v)

			local oldv

			if g_watch_begin then
				oldv = _rawget(t, k)
			end

			t[k] = v

			if g_watch_begin then
				if _rawget(t, k) ~= v then
					debugPrint("cow_cdx_proxy __newindex may be write in meta", t, k, v)
				else
					write_watch(t, k, oldv)
				end
			end
		end,
		__tostring = function(_)
			return string_format("cdx_proxy(%s)", tostring(t))
		end
	}

	g_app_data._cow_cdx_count = g_app_data._cow_cdx_count + 1

	return setmetatable(proxy, mt)
end

local cow_proxy_mt = {
	__index = function(proxy, k)
		local t = rawget(proxy, "__cow_raw")

		if t == nil then
			return
		end

		k = get_cow_raw(k)

		local v = t[k]

		if not g_watch_begin then
			return v
		end

		return conv2proxy(k, v)
	end,
	__newindex = function(proxy, k, v)
		local t = rawget(proxy, "__cow_raw")

		k = get_cow_raw(k)
		v = get_cow_raw(v)

		local oldv

		if g_watch_begin then
			oldv = rawget(t, k)
		end

		t[k] = v

		if g_watch_begin then
			if rawget(t, k) ~= v then
				debugPrint("cow_proxy __newindex may be write in meta", t, k, v)
			else
				write_watch(t, k, oldv)
			end
		end
	end,
	__pairs = function(proxy)
		local t = rawget(proxy, "__cow_raw")
		local name = rawget(proxy, "__name") or "nil"
		local it, tb, init = lua_pairs(t)

		if not g_watch_begin then
			return it, tb, init
		end

		return function()
			local nk, nv = it(tb, init)

			init = nk

			local skey = lua_tostring(nk)

			return conv2proxy(string_format("%s_%s", name, skey), nk), conv2proxy(string_format("%s[%s]", name, skey), nv)
		end
	end,
	__ipairs = function(proxy)
		local t = rawget(proxy, "__cow_raw")
		local name = rawget(proxy, "__name") or "nil"
		local it, tb, init = lua_ipairs(t)

		if not g_watch_begin then
			return it, tb, init
		end

		return function()
			local nk, nv = it(tb, init)

			init = nk

			local skey = lua_tostring(nk)

			return nk, conv2proxy(string_format("%s[%s]", name, skey), nv)
		end
	end,
	__next = function(proxy, k)
		local t = rawget(proxy, "__cow_raw")
		local name = rawget(proxy, "__name") or "nil"
		local i, v = lua_next(t, k)

		if not g_watch_begin then
			return i, v
		end

		local skey = lua_tostring(i)

		return conv2proxy(string_format("%s_%s", name, skey), i), conv2proxy(string_format("%s[%s]", name, skey), v)
	end,
	__len = function(proxy)
		local t = rawget(proxy, "__cow_raw")

		return itertools.size(t)
	end,
	__tostring = function(proxy)
		local t = rawget(proxy, "__cow_raw")
		local name = rawget(proxy, "__name") or "nil"

		return string_format("cow_proxy(%s %s)", name, tostring(t))
	end
}

function cow_proxy(name, t)
	local pindex, pnewindex
	local tindex = rawget(t, "__index")
	local tnewindex = rawget(t, "__newindex")

	if tindex then
		function pindex(primary, k)
			return tindex(primary, k)
		end
	end

	if tnewindex then
		function pnewindex(primary, k, v)
			return tnewindex(primary, k, v)
		end
	end

	local proxy = {
		__proxy = true,
		__raw = t,
		__class = _rawget(t, "__class"),
		__cid = _rawget(t, "__cid"),
		__cname = _rawget(t, "__cname"),
		__cow_raw = t,
		__name = name,
		__index = pindex,
		__newindex = pnewindex,
		__clone = function(self)
			if not g_watch_begin then
				return
			end

			local w = g_write[t]

			if w ~= nil and w.__isclone then
				return
			end

			local newt = cow_clone(t)

			if w then
				for k, v in lua_pairs(w) do
					if v == nil_value then
						newt[k] = nil
					else
						newt[k] = v
					end
				end
			end

			g_write[t] = newt
		end
	}

	debugPrint("cow_proxy -------------->", name, t)

	g_app_data._cow_t_count = g_app_data._cow_t_count + 1

	return setmetatable(proxy, cow_proxy_mt)
end

function cow.battleModelInit()
	if not g_enable_cow then
		return
	end

	assert(false, "NO USE ANY MORE!")

	g_watch_begin = false

	for k, f in lua_pairs(cow_table) do
		table[k] = f
	end
end

function cow.battleModelDestroy()
	if not g_enable_cow then
		return
	end

	assert(false, "NO USE ANY MORE!")

	g_watch_begin = false

	for k, f in lua_pairs(cow_table) do
		table[k] = lua_table[k]
	end

	printDebug("cow.app_data %s", dumps(g_app_data))
	cow.switchCowData(cow.newCowData())
end

function cow.proxyObject(name, t)
	if t == nil then
		return nil
	end

	if not g_enable_cow then
		return t
	end

	if g_proxy[t] then
		return g_proxy[t]
	end

	local c = cow_proxy(name, t)

	g_proxy[t] = c
	g_proxy_raw[c] = t

	return c
end

function cow.proxyView(name, t)
	if t == nil then
		return nil
	end

	if not g_enable_cow then
		return t
	end

	if not g_watch_begin then
		return t
	end

	if g_proxy[t] then
		return g_proxy[t]
	end

	local c = cow_cdx_proxy(name, t)

	g_proxy[t] = c
	g_proxy_raw[c] = t

	return c
end

function cow.proxyWatchBegin()
	if not g_enable_cow then
		return
	end

	assert(not g_watch_begin, "g_watch_begin invalid")

	if g_watch_begin then
		cow.proxyWatchEnd(false)
	end

	g_watch_begin = true
	g_lookup_table = {}

	debugPrint("cow.proxyWatchBegin()")

	return true
end

function cow.proxyWatchEnd(revert)
	if not g_enable_cow then
		return
	end

	if revert then
		g_app_data._revert_count = g_app_data._revert_count + 1
	end

	for t, _ in lua_pairs(g_write) do
		if g_write[t] then
			if revert then
				cow_revert(t)
			end

			if t.__iscdx then
				node_proxy.revert(t, revert)

				g_proxy[get_raw_in_cow(t)], g_proxy_raw[t] = nil
				g_app_data._revert_cdx_count = g_app_data._revert_cdx_count + 1
			end

			g_write[t] = nil
		end
	end

	g_watch_begin = false
	g_lookup_table = {}

	debugPrint("cow.proxyWatchEnd()")
end

function cow.revert(t)
	return cow_revert(t)
end

function cow.addGlobalCount(delta)
	if not g_enable_cow then
		return
	end

	g_app_data.enable_count = g_app_data.enable_count + delta
end

function cow.getGlobalCount()
	return g_app_data.enable_count
end

function cow.newCowData()
	return {
		_proxy = {},
		_proxy_raw = {},
		_proxy_cdx = {},
		_lookup_table = {},
		_write = {},
		_app_data = {
			_revert_t_count = 0,
			_cow_cdx_count = 0,
			_cow_t_count = 0,
			_revert_cdx_count = 0,
			_revert_count = 0,
			_clone_t_count = 0,
			enable_count = 0
		}
	}
end

function cow.switchCowData(newCowData)
	local old = g_data

	g_data = newCowData
	g_proxy = newCowData._proxy
	g_proxy_raw = newCowData._proxy_raw
	g_proxy_cdx = newCowData._proxy_cdx
	g_write = newCowData._write
	g_app_data = newCowData._app_data

	return old
end

function cow.isproxy(t)
	return t and type(t) == "table" and rawget(t, "__cow_raw") ~= nil
end

if g_enable_cow then
	cow.switchCowData(cow.newCowData())
	print("cow.isEnable")
end

local tinsert = table_insert
local tconcat = table_concat
local tsort = table_sort
local srep = string.rep
local format = string.format

require("util.str")

local isobjectid = string.isobjectid
local bintohex = stringz.bintohex

function cow.dumps(t, verbose)
	if t == nil then
		return "nil"
	end

	local cache = {
		[t] = "."
	}

	local function _tree_dump(t, space, name)
		if not verbose then
			t = get_cow_raw(t)
		end

		local temp, keys = {}, {}

		for k, v in lua_pairs(t) do
			tinsert(keys, k)
		end

		tsort(keys, function(v1, v2)
			if lua_type(v1) == lua_type(v2) then
				return v1 < v2
			end

			v1 = lua_tostring(v1)
			v2 = lua_tostring(v2)

			return v1 < v2
		end)

		for i, k in lua_ipairs(keys) do
			local v = t[k]
			local key = lua_tostring(k)

			if isobjectid(key) then
				key = "objectid(" .. bintohex(key) .. ")"
			end

			if cache[v] then
				tinsert(temp, "+" .. key .. " {" .. cache[v] .. "}")
			elseif lua_type(v) == "table" then
				local new_key = name .. "." .. key

				cache[v] = new_key
				key = key .. format("(%s)", lua_tostring(v))

				tinsert(temp, "+" .. key .. _tree_dump(v, space .. (lua_next(keys, i) and "|" or " ") .. srep(" ", #key), new_key))
			elseif lua_type(v) == "function" then
				tinsert(temp, "+" .. key .. " [" .. lua_tostring(v) .. "]")
			elseif lua_type(v) == "string" and isobjectid(v) then
				tinsert(temp, "+" .. key .. " [" .. "objectid" .. " " .. bintohex(v) .. "]")
			else
				tinsert(temp, "+" .. key .. " [" .. lua_type(v) .. " " .. lua_tostring(v) .. "]")
			end
		end

		local meta = getmetatable(t)

		if meta then
			local key = format("(meta %s)", lua_tostring(meta))

			if cache[meta] then
				tinsert(temp, "+" .. key .. " {" .. cache[meta] .. "}")
			else
				local new_key = name .. ".meta"

				cache[meta] = new_key

				tinsert(temp, "+" .. key .. _tree_dump(meta, space .. " " .. srep(" ", #key), new_key))
			end
		end

		return tconcat(temp, "\n" .. space)
	end

	return _tree_dump(t, "", "")
end

function cow.dumpsToFile(t, filename)
	local s = cow.dumps(t)
	local fp = io.open(filename, "w+")

	fp:write(s)
	fp:close()
end
