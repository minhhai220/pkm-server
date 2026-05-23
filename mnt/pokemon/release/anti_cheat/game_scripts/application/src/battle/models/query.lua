globals.battleQuery = {}

function battleQuery.filterBuffNotOver(id, buff)
	return not buff.isOver
end

local filterBuffNotOver = battleQuery.filterBuffNotOver

local function alwaysOK()
	return true
end

local ObjectMethods = {}

battleQuery.ObjectMethods = ObjectMethods

local ObjectBuffQueryBinds = {
	queryBuffsWithGroup = "scene",
	hasBuffGroup = "scene",
	hasBuffFlag = "scene",
	iterBuffsWithEasyEffectFunc = "",
	iterBuffsWithCsvID = "",
	getSameBuffCount = "",
	hasTypeBuff = "",
	hasBuff = "",
	getBuff = "",
	getBuffByID = ""
}
local SceneMethods = {}

battleQuery.SceneMethods = SceneMethods

local SceneBuffQueryBinds = {
	getTargetsByBuff = "scene",
	getBuffByID = "",
	hasTypeBuff = ""
}

function battleQuery.objectBindBuff(scene, object, clt)
	for name, tag in pairs(ObjectBuffQueryBinds) do
		assert(object[name] == nil, tostring(object) .. "bind duplicated " .. name)

		local f = ObjectMethods[name]

		if tag == "scene" then
			object[name] = function(self, ...)
				return f(scene, clt, ...)
			end
		else
			object[name] = function(self, ...)
				return f(clt, ...)
			end
		end
	end
end

function battleQuery.sceneBindBuff(scene, clt)
	local object = scene

	for name, tag in pairs(SceneBuffQueryBinds) do
		assert(object[name] == nil, tostring(object) .. "bind duplicated " .. name)

		local f = SceneMethods[name]

		if tag == "scene" then
			object[name] = function(self, ...)
				return f(scene, clt, ...)
			end
		else
			object[name] = function(self, ...)
				return f(clt, ...)
			end
		end
	end
end

function ObjectMethods.getBuffByID(buffs, buffID)
	return buffs:find(buffID)
end

function ObjectMethods.getBuff(buffs, buffCsvID, noFilterOver)
	local filterFunc = filterBuffNotOver

	if noFilterOver then
		filterFunc = nil
	end

	return buffs:getQuery():group("cfgId", buffCsvID):first(filterFunc)
end

local getBuff = ObjectMethods.getBuff

function ObjectMethods.hasBuff(buffs, buffCsvID, noFilterOver)
	return getBuff(buffs, buffCsvID, noFilterOver) ~= nil
end

function ObjectMethods.iterBuffsWithCsvID(buffs, buffCsvID)
	return buffs:getQuery():group("cfgId", buffCsvID):order_pairs()
end

local function addAssginGroup(scene, query, buffGroupID)
	local cache = scene:getConvertGroupCache()

	if cache and cache.convertGroup == buffGroupID then
		for group, _ in pairs(cache.assignGroup) do
			query:groups("+", "groupID", group)
		end
	end

	return query
end

function ObjectMethods.queryBuffsWithGroup(scene, buffs, buffGroupID)
	local query = buffs:getQuery()

	addAssginGroup(scene, query, buffGroupID)
	query:groups("+", "groupID", buffGroupID)

	return query
end

local queryBuffsWithGroup = ObjectMethods.queryBuffsWithGroup

function ObjectMethods.hasBuffGroup(scene, buffs, buffGroupID, noFilterOver)
	local filterFunc = filterBuffNotOver

	if noFilterOver then
		filterFunc = nil
	end

	return not queryBuffsWithGroup(scene, buffs, buffGroupID):empty(filterFunc)
end

function ObjectMethods.hasBuffFlag(scene, buffs, buffFlagID, noFilterOver)
	local filterFunc = filterBuffNotOver

	if noFilterOver then
		filterFunc = nil
	end

	return not buffs:getQuery():group("flagID", buffFlagID):empty(filterFunc)
end

function ObjectMethods.iterBuffsWithEasyEffectFunc(buffs, buffType)
	return buffs:getQuery():group("easyEffectFunc", buffType):order_pairs()
end

function ObjectMethods.hasTypeBuff(buffs, buffType)
	return not buffs:getQuery():group("easyEffectFunc", buffType):empty()
end

function ObjectMethods.getSameBuffCount(buffs, buffCsvID)
	return buffs:getQuery():group("cfgId", buffCsvID):count()
end

local QueryFuncIndexMap = {
	hasBuff = "cfgId",
	hasBuffGroup = "groupID",
	hasTypeBuff = "easyEffectFunc",
	hasBuffFlag = "flagID"
}
local CheckBuffPost = {
	getBuff = filterBuffNotOver,
	hasBuff = filterBuffNotOver,
	hasBuffGroup = filterBuffNotOver,
	hasBuffFlag = filterBuffNotOver
}

function SceneMethods.getTargetsByBuff(scene, buffs, ids, buffFunc, targets)
	local hash = itertools.map(targets, function(_, target)
		return target.id, 0
	end)
	local query = buffs:getQuery()

	for _, id in ipairs(ids) do
		if buffFunc == "hasBuffGroup" then
			addAssginGroup(scene, query, id)
		end

		query:groups("+", QueryFuncIndexMap[buffFunc], id)
	end

	local check = CheckBuffPost[buffFunc] or alwaysOK

	query:empty(function(buffID, buff)
		local target = buff.holder

		if hash[target.id] and check(buffID, buff) then
			hash[target.id] = 1
		end

		return false
	end)

	local result = {}

	for _, target in ipairs(targets) do
		if hash[target.id] == 1 then
			table.insert(result, target)
		end
	end

	return result
end

function SceneMethods.getBuffByID(buffs, buffID)
	return buffs:find(buffID)
end

function SceneMethods.hasTypeBuff(buffs, buffType)
	return not buffs:getQuery():group("easyEffectFunc", buffType):empty()
end
