-- chunkname: @src.battle.easy.log

function battleEasy.logHerosInfo(scene, tag)
	local l

	if tag == "newWave" then
		l = lazylog.battle.gate.newWave
	else
		l = lazylog.battle.scene.allHerosInfo
	end

	local function sortHerosLog(heros)
		local arr = {}

		printDebug(string.format("logHerosInfo tag=%s", tag))

		for _, obj in heros:order_pairs() do
			battleEasy.logHeroInfo(obj)
			table.insert(arr, obj)
		end

		return arr
	end

	l({
		heros = function()
			return sortHerosLog(scene.heros)
		end,
		enemyHeros = function()
			return sortHerosLog(scene.enemyHeros)
		end
	})
end

function battleEasy.logHeroInfo(obj)
	local objAttrStr = string.format(" -- seat=%s\nhp=%.2f\nhpMax=%.2f\nmp=%.2f", obj.seat, obj:hp(), obj:hpMax(), obj:mp1())
	local attrs = {}

	for k, _ in pairs(ObjectAttrs.AttrsTable) do
		table.insert(attrs, string.format("%s=%.2f", k, obj[k](obj)))
	end

	table.sort(attrs)

	for _, log in ipairs(attrs) do
		objAttrStr = objAttrStr .. "\n" .. log
	end

	printDebug(objAttrStr)
end

function battleEasy.logTraceInfo(depth)
	if device.platform ~= "windows" then
		return nil
	end

	return function()
		depth = depth or 5

		local result = ""

		for i = 1, depth do
			local info = debug.getinfo(i + 2, "nSl")

			if info then
				result = result .. string.format("\n\t[%d]文件:%s:%s 函数:%s", i, info.short_src, info.currentline, info.name)
			end
		end

		return result
	end
end

local checkMap = {
	[battle.BuffCantAddReason.powerFlag] = function(cfgId, group, flags, holder, caster)
		local str = "\n\t权限flag可生效的Buff列表:{"
		local idsMap = {}

		for _, infos in holder.buffImmuneCache.powerFlag:pairs() do
			for _, info in pairs(infos) do
				local infoCfgId = info.cfgId

				if not idsMap[infoCfgId] then
					idsMap[infoCfgId] = true
					str = str .. string.format("%d,", infoCfgId)
				end
			end
		end

		return string.sub(str, 1, -2) .. "}"
	end,
	[battle.BuffCantAddReason.powerGroup] = function(cfgId, group, flags, holder, caster)
		local str = "\n\t权限group可生效的Buff列表:{"
		local idsMap = {}
		local powerGroup = holder.buffImmuneCache.powerGroup

		if powerGroup:size() > 0 and not powerGroup:find(group) then
			for _, infos in powerGroup:pairs() do
				for _, info in pairs(infos) do
					local infoCfgId = info.cfgId

					if not idsMap[infoCfgId] then
						idsMap[infoCfgId] = true
						str = str .. string.format("%d,", infoCfgId)
					end
				end
			end

			return string.sub(str, 1, -2) .. "}"
		end
	end,
	[battle.BuffCantAddReason.filter] = function(cfgId, group, flags, holder, caster)
		if not holder:checkOverlaySpecBuffExit("filterGroup") and not holder:checkOverlaySpecBuffExit("filterFlag") then
			return
		end

		local str = "\n\t过滤flag或group可生效的Buff列表:{"

		for _, data in holder:ipairsOverlaySpecBuff("filterGroup") do
			local filterGroupResult = data:checkFilterGroup(caster, group)

			if filterGroupResult then
				return
			end

			str = str .. string.format("%d,", data.cfgId)
		end

		for _, data in holder:ipairsOverlaySpecBuff("filterFlag") do
			local filterFlagsResult = data:checkFilterFlag(caster, flags)

			if filterFlagsResult then
				return
			end

			str = str .. string.format("%d,", data.cfgId)
		end

		return string.sub(str, 1, -2) .. "}"
	end,
	[battle.BuffCantAddReason.commandeer] = function(cfgId, group, flags, holder, caster)
		local str = "\n\t免疫夺取可生效的Buff列表:{"
		local res = true

		for _, data in caster:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.applyCommandeer) do
			if data.cfgIdHashTb[cfgId] and data.howToDo == 1 then
				str = str .. string.format("%d,", data.cfgId)
				res = false
			end
		end

		for _, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.applyCommandeer) do
			if (data.groupHashTb[group] or data.cfgIdHashTb[cfgId]) and (data.howToDo == 2 or data.howToDo == 3) then
				str = str .. string.format("%d,", data.cfgId)
				res = false
			end
		end

		if not res then
			return string.sub(str, 1, -2) .. "}"
		end
	end,
	[battle.BuffCantAddReason.immune] = function(cfgId, group, flags, holder, caster, groupPower, sortBuffInfos)
		if groupPower.beImmune ~= 1 then
			return
		end

		local strTemp = "\n\t免疫%s可生效的Buff列表:{"
		local resultS = ""
		local cfgIdMap = {}
		local notOverIdMap = {}

		if sortBuffInfos then
			for _, v in ipairs(sortBuffInfos) do
				cfgIdMap[v.cfgId] = true
			end
		end

		local function checkCfgId(cfgId)
			if not sortBuffInfos then
				return true
			end

			return cfgIdMap[cfgId]
		end

		local immGroup = holder.buffImmuneCache.immuneGroup:find(group)

		if immGroup and next(immGroup) then
			local str = string.format(strTemp, "group")
			local immuneRes = false

			for k, v in pairs(immGroup) do
				if not battleEasy.loseImmuneEfficacyCheck(holder, {
					group = group,
					cfgId = v.cfgId,
					indexGroup = v.group
				}) and checkCfgId(v.cfgId) then
					notOverIdMap[v.cfgId] = true
					str = str .. string.format("%d,", v.cfgId)
					immuneRes = true
				end
			end

			if immuneRes then
				resultS = resultS .. string.sub(str, 1, -2) .. "}"
			end
		end

		local immBuff = holder.buffImmuneCache.immuneBuff:find(cfgId)

		if immBuff and next(immBuff) then
			local str = string.format(strTemp, "cfgId")
			local immuneRes = false

			for k, v in pairs(immBuff) do
				if not battleEasy.loseImmuneEfficacyCheck(holder, {
					cfgId = v.cfgId
				}) and checkCfgId(v.cfgId) then
					notOverIdMap[v.cfgId] = true
					str = str .. string.format("%d,", v.cfgId)
					immuneRes = true
				end
			end

			if immuneRes then
				resultS = resultS .. string.sub(str, 1, -2) .. "}"
			end
		end

		local immFlag = {}

		if next(flags) then
			for _, flag in ipairs(flags) do
				local data = holder.buffImmuneCache.immuneFlag:find(flag)

				if data and next(data) then
					local immuneRes = false
					local ids = ""

					for _, v in pairs(data) do
						if checkCfgId(v.cfgId) then
							notOverIdMap[v.cfgId] = true
							immuneRes = true
							ids = ids .. string.format("%d,", v.cfgId)
						end
					end

					if immuneRes then
						resultS = resultS .. string.format(strTemp, "flag:" .. flag) .. string.sub(ids, 1, -2) .. "}"
					end
				end
			end
		end

		if sortBuffInfos then
			local hasOverBuff = false
			local str = "\n\t已被结束但免疫可生效的Buff列表:{"

			for _, v in ipairs(sortBuffInfos) do
				if not notOverIdMap[v.cfgId] then
					hasOverBuff = true
					str = str .. string.format("%d,", v.cfgId)
				end
			end

			if hasOverBuff then
				resultS = resultS .. string.sub(str, 1, -2) .. "}"
			end
		end

		return resultS
	end
}
local checkRank = {
	battle.BuffCantAddReason.powerFlag,
	battle.BuffCantAddReason.powerGroup,
	battle.BuffCantAddReason.filter,
	battle.BuffCantAddReason.commandeer,
	battle.BuffCantAddReason.immune
}

function battleEasy.logImmuneInfos(result, reason, cfgId, group, flags, groupPower, holder, caster, sortBuffInfos)
	if device.platform ~= "windows" then
		return nil
	end

	if result == true then
		return nil
	end

	return function()
		local infos = ", 可生效buff如下:"
		local check = false

		for _, v in ipairs(checkRank) do
			if v == reason then
				check = true
			end

			if check then
				local checkS = checkMap[v](cfgId, group, flags, holder, caster, groupPower, sortBuffInfos)

				if checkS then
					infos = infos .. checkS
				end
			end
		end

		return infos
	end
end
