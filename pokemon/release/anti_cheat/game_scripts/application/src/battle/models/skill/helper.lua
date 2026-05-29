-- chunkname: @src.battle.models.skill.helper

local skillHelper = {}

globals.skillHelper = skillHelper

function skillHelper.natureRestraint(skillNatureType, target, natureOrder, natureRestraintCEx, natureResistance)
	if not skillNatureType then
		return
	end

	local objNatureName = game.NATURE_TABLE[target:getNature(natureOrder)]

	return skillHelper.getNatureMatrix(skillNatureType, objNatureName, natureRestraintCEx, natureResistance)
end

local function checkNatureMatrixCheat(nature)
	if ANTI_AGENT then
		return
	end

	checkSpecificCsvCheat({
		"base_attribute",
		"nature_matrix"
	}, itertools.ivalues({
		nature
	}))
end

function skillHelper.getNatureMatrix(nature1, natureName, natureRestraintCEx, natureResistance)
	if nature1 and natureName and csv.base_attribute.nature_matrix[nature1] then
		checkNatureMatrixCheat(nature1)

		local baseValue = csv.base_attribute.nature_matrix[nature1][natureName]
		local fixValue = 0

		if baseValue > 1 then
			fixValue = math.max(-natureResistance, 1 - baseValue)
		end

		if baseValue > 1 or nature1 == 1 and baseValue >= 1 then
			fixValue = fixValue + natureRestraintCEx
		end

		return baseValue + fixValue
	end

	return 1
end

function skillHelper.getNatureFlag(val)
	local absDelta = math.abs(val - 1)

	if absDelta < 0.01 then
		return "normal", 1
	elseif val > 1 then
		return "strong", string.format("%.2f", val)
	elseif val > 0 then
		return "weak", string.format("%.2f", val)
	else
		return "fullweak", 0
	end
end

function skillHelper.natureRestraintType(skillNatureType, target, natureRestraintCEx, natureResistance)
	local val = 1

	natureRestraintCEx = natureRestraintCEx or 0
	natureResistance = natureResistance or 0

	for idx, _ in target:ipairsNature(true) do
		local resistVal = skillHelper.natureRestraint(skillNatureType, target, idx, natureRestraintCEx, natureResistance) or 1

		val = val + (resistVal - 1)
	end

	return skillHelper.getNatureFlag(val)
end

return skillHelper
