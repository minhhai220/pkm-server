-- chunkname: @src.util.lazy_require

local DYNAMIC_ENABLE = true

print("DYNAMIC_ENABLE", DYNAMIC_ENABLE)

local CSV_DIR_ROOT = "config"
local CSV_VAR_ROOT = "csv"
local strsub = string.sub

local function _setDefalutMeta(t)
	for k, v in pairs(t) do
		if type(k) == "string" and type(v) == "table" then
			if strsub(k, 1, 2) ~= "__" then
				_setDefalutMeta(v)
			end
		elseif t.__default and type(k) == "number" and type(v) == "table" then
			setmetatable(v, t.__default)
		end
	end
end

local function _dynamicLoading(t, path)
	if type(t) == "table" then
		for k, v in pairs(t) do
			_dynamicLoading(v, path .. "." .. k)
		end

		local mt = {
			__dynamic = true,
			__index = function(_, key)
				if strsub(key, 1, 2) == "__" then
					return nil
				end

				local mem = collectgarbage("count")
				local clock = os.clock()
				local curPath = path .. "." .. key
				local configCsv = require(curPath)
				local curMem = collectgarbage("count")

				if device.platform == "windows" then
					printDebug("lazy_require csv %s cost %.2fKB %.3fs", curPath, curMem - mem, os.clock() - clock)
				end

				csvSetDefalutMeta(configCsv)
				setL10nConfig(configCsv)

				t[key] = csvReadOnlyInWindows(configCsv, curPath)

				return t[key]
			end
		}

		setmetatable(t, mt)
	end
end

function globals.lazy_require(path)
	if not DYNAMIC_ENABLE then
		require(path)
	end
end

function globals.configLoad()
	if DYNAMIC_ENABLE then
		_dynamicLoading(csv, CSV_DIR_ROOT)
	else
		_setDefalutMeta(csv)
		setL10nConfig(csv)
	end
end

function globals.configUnload(pathsArray)
	if not DYNAMIC_ENABLE then
		return
	end

	for _, k in ipairs(pathsArray) do
		local path = string.format("%s%s", CSV_DIR_ROOT, strsub(k, #CSV_VAR_ROOT + 1))
		local loaded = package.loaded[path] or package.preload[path]

		if loaded then
			printDebug("configUnload %s", k)

			package.loaded[path] = nil
			package.preload[path] = nil

			local array = string.split(k, ".")
			local cur, prev = csv

			for i = 2, #array do
				prev = cur
				cur = cur[array[i]]
			end

			prev[array[#array]] = nil
		end
	end
end

local function dfsCheckLoaded(t, path, f)
	local k = next(t)
	local leaf = type(k) ~= "string"

	leaf = leaf or strsub(k, 1, 2) == "__"

	if leaf then
		local mt = getmetatable(t)
		local typ = "dynamic_csv"

		if mt and not rawget(mt, "__dynamic") then
			typ = "loaded_csv"
		end

		f(path, typ)

		return
	end

	for k, v in pairs(t) do
		f(k, "enter")
		dfsCheckLoaded(v, path .. "." .. k, f)
		f(k, "leave")
	end
end

function globals.getLoadedCsvPathSet()
	local ret = {}

	dfsCheckLoaded(csv, CSV_VAR_ROOT, function(path, typ)
		if typ == "loaded_csv" then
			ret[path] = true
		end
	end)

	return ret
end

function globals.printCsvLoadState()
	local t = {}
	local cur = t
	local stack = {}

	dfsCheckLoaded(csv, CSV_VAR_ROOT, function(path, typ)
		if typ == "enter" then
			cur[path] = {}

			table.insert(stack, cur)

			cur = cur[path]
		elseif typ == "leave" then
			cur = table.remove(stack)

			if cur[path][".leaf"] then
				cur[path] = cur[path][".leaf"]
			end
		else
			cur[".leaf"] = typ
		end
	end)
	print_r(t)
end

function globals.safeLoad(path)
	return pcall(function()
		require(path)
	end)
end
