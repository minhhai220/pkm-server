-- chunkname: @src.battle.easy.buff_filter_map

local FilterType = {
	exclude = "exclude",
	include = "include"
}
local KeyType = {
	group = "group",
	buffID = "buffID",
	flag = "flag"
}

local function initMapOrder(map)
	local ret = {}

	itertools.each(map, function(k, v)
		table.insert(ret, v)
	end)
	table.sort(ret)

	return ret
end

local filterOrder = initMapOrder(FilterType)
local keyOrder = initMapOrder(KeyType)
local defaultExecuteOrder = {
	FilterType.include,
	FilterType.exclude
}
local passCache = {}

local function newFilterMap()
	return {
		[KeyType.group] = {},
		[KeyType.flag] = {},
		[KeyType.buffID] = {}
	}
end

local BuffFilterMap = class("BuffFilterMap")

BuffFilterMap.ID = 0

function BuffFilterMap.newID()
	BuffFilterMap.ID = BuffFilterMap.ID + 1

	return BuffFilterMap.ID
end

function BuffFilterMap:ctor()
	self.id = self.newID()
	self.order = -1
	self.whiteMap = newFilterMap()
	self.blackMap = newFilterMap()
	self.executeOrder = {}
	self.fTypeEmptyMark = {}

	self:initFTypeEmptyMark()
end

function BuffFilterMap:initFTypeEmptyMark()
	for _, fType in ipairs(filterOrder) do
		self.fTypeEmptyMark[fType] = true
	end
end

function BuffFilterMap:include(keyTypes, ...)
	if self.order == -1 then
		self.order = 0
	end

	local lists = {
		...
	}
	local types = string.split(keyTypes, "|")

	for idx, keyType in ipairs(types) do
		arraytools.merge_two_inplace(self.whiteMap[keyType], lists[idx])

		if table.length(lists[idx]) > 0 then
			self.fTypeEmptyMark[FilterType.include] = false
		end
	end

	return self
end

function BuffFilterMap:exclude(keyTypes, ...)
	if self.order == -1 then
		self.order = 1
	end

	local lists = {
		...
	}
	local types = string.split(keyTypes, "|")

	for idx, keyType in ipairs(types) do
		arraytools.merge_two_inplace(self.blackMap[keyType], lists[idx])

		if table.length(lists[idx]) > 0 then
			self.fTypeEmptyMark[FilterType.exclude] = false
		end
	end

	return self
end

function BuffFilterMap:hashAllList()
	for _, keyType in ipairs(keyOrder) do
		self.whiteMap[keyType] = arraytools.hash(self.whiteMap[keyType])
		self.blackMap[keyType] = arraytools.hash(self.blackMap[keyType])
	end
end

function BuffFilterMap:initExecuteOrder()
	local isPositiveOrder = self.order == 0
	local len = #defaultExecuteOrder
	local s = isPositiveOrder and 1 or len
	local step = isPositiveOrder and 1 or -1
	local e = isPositiveOrder and len or 1

	for i = s, e, step do
		table.insert(self.executeOrder, defaultExecuteOrder[i])
	end
end

function BuffFilterMap:output()
	self:hashAllList()
	self:initExecuteOrder()

	passCache[self.id] = {}

	local ret = {}

	ret.__spstructure = battle.spstructure.BuffFilterMap
	ret.id = self.id
	ret.whiteMap = self.whiteMap
	ret.blackMap = self.blackMap
	ret.executeOrder = self.executeOrder
	ret.fTypeEmptyMark = self.fTypeEmptyMark

	setmetatable(ret, {
		__newindex = function(t, k, v)
			error("you could not write to a BuffFilterMap which is in gFormulaConst")
		end
	})

	return ret
end

local BuffFilterCsvMap = class("BuffFilterCsvMap")

function BuffFilterCsvMap:ctor()
	self.filterMap = BuffFilterMap.new()
end

function BuffFilterCsvMap:include(keyTypes, ...)
	self.filterMap:include(keyTypes, ...)

	return self
end

function BuffFilterCsvMap:exclude(keyTypes, ...)
	self.filterMap:exclude(keyTypes, ...)

	return self
end

function BuffFilterCsvMap:output()
	return self.filterMap:output()
end

function battleEasy.newBuffFilterCsvMap()
	return BuffFilterCsvMap.new()
end

local isInKeyListFunc = {
	[KeyType.group] = function(cList, group)
		if cList[group] then
			return true
		end
	end,
	[KeyType.flag] = function(cList, flags)
		for _, flag in ipairs(flags) do
			if cList[flag] then
				return true
			end
		end
	end,
	[KeyType.buffID] = function(cList, buffID)
		if cList[buffID] then
			return true
		end
	end
}

local function isInFilterList(filterMap, paramMap)
	local isInList = false

	for _, kType in ipairs(keyOrder) do
		isInList = isInKeyListFunc[kType](filterMap[kType], paramMap[kType])

		if isInList then
			break
		end
	end

	return isInList
end

local toFilterFunc = {
	[FilterType.include] = function(buffFilterMap, paramMap)
		if buffFilterMap.fTypeEmptyMark[FilterType.include] then
			return false
		end

		local isInList = isInFilterList(buffFilterMap.whiteMap, paramMap)

		return not isInList
	end,
	[FilterType.exclude] = function(buffFilterMap, paramMap)
		if buffFilterMap.fTypeEmptyMark[FilterType.exclude] then
			return false
		end

		local isInList = isInFilterList(buffFilterMap.blackMap, paramMap)

		return isInList
	end
}

local function groupFlagIDKey(id, group, flags)
	local key = string.format("%s_%s", id, group)

	for _, flag in ipairs(flags) do
		key = string.format("%s_%s", key, flag)
	end

	return key
end

local function params2Map(id, group, flag)
	return {
		[KeyType.group] = group,
		[KeyType.flag] = flag,
		[KeyType.buffID] = id
	}
end

local BuffFilterTool = class("BuffFilterTool")

function BuffFilterTool.filter(buffFilterMap, id, group, flags)
	local key = groupFlagIDKey(id, group, flags)

	if passCache[buffFilterMap.id][key] then
		return true
	end

	for _, filterType in ipairs(buffFilterMap.executeOrder) do
		if toFilterFunc[filterType](buffFilterMap, params2Map(id, group, flags)) then
			return false
		end
	end

	passCache[buffFilterMap.id][key] = true

	return true
end

battleEasy.BuffFilterTool = BuffFilterTool
