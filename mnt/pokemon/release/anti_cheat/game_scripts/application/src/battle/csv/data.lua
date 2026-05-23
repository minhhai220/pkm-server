-- chunkname: @src.battle.csv.data

function battleCsv.getFixedOrPercent(s)
	local fixed, percent = 0, 0

	if s then
		local perPos = string.find(s, "%%")

		if perPos then
			local num = tonumber(string.sub(s, 1, perPos - 1))

			percent = num / 100
		else
			fixed = s
		end
	end

	return fixed, percent
end

function battleCsv.hasBuffGroup(groupTab, group)
	if groupTab then
		for k, v in ipairs(groupTab) do
			if v[group] then
				return true, k
			end
		end
	end

	return false, nil
end

function battleCsv.hasBuffFlag(flagTab, flags)
	if flagTab and flags then
		local flagHash = arraytools.hash(flags)

		for k, v in ipairs(flagTab) do
			if flagHash[v] then
				return true, k
			end
		end
	end

	return false, nil
end

function battleCsv.hasImmnueConfiguration(groupRelationID, group, flags)
	local groupRelation = gBuffGroupRelationCsv[groupRelationID]

	if not groupRelation then
		return false
	end

	if battleCsv.hasBuffGroup(groupRelation.immuneGroup, group) then
		return true
	end

	if battleCsv.hasBuffFlag(groupRelation.immuneFlag, flags) then
		return true
	end

	return false
end
