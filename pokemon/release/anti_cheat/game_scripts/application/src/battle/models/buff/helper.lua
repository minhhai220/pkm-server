-- chunkname: @src.battle.models.buff.helper

local helper = {}

function helper.argsCheck(args, buff)
	if args < 0 then
		errorInWindows("buff(%s) args(%s) < 0", buff.cfgId, args)

		return 0
	end

	return args
end

function helper.argsArray(args)
	if type(args[1]) ~= "table" then
		return {
			args
		}
	end

	return args
end

function helper.adjustSkillType2Data(default, specialVal)
	if specialVal then
		default = {
			[battle.MainSkillType.SmallSkill] = true,
			[battle.MainSkillType.BigSkill] = true,
			[battle.MainSkillType.NormalSkill] = true
		}

		for _, v in ipairs(specialVal) do
			default[v] = false
		end
	end

	return default
end

return helper
