local battleSkill = {}

globals.battleSkill = battleSkill

require("battle.models.skill.skill")
require("battle.models.skill.passive_skill")
require("battle.models.skill.immediate_skill")
require("battle.models.skill.summon_skill")
require("battle.models.skill.combine_skill")
require("battle.models.skill.aid_skill")
require("battle.models.skill.helper")

local map = {
	[battle.SkillType.NormalSkill] = battleSkill.SkillModel,
	[battle.SkillType.PassiveAura] = battleSkill.BuffSkillModel,
	[battle.SkillType.PassiveSkill] = battleSkill.PassiveSkillModel,
	[battle.SkillType.PassiveSummon] = battleSkill.SummonSkillModel,
	[battle.SkillType.AidSkill] = battleSkill.AidSkillModel,
	[battle.SkillType.NormalCombine] = battleSkill.CombineSkillModel
}

function globals.newSkillModel(scene, owner, skillID, level, source)
	local cfg = csv.skill[skillID]
	local cls = map[cfg.skillType]

	if cls == nil then
		error(string.format("skill type %d not existed", cfg.skillType))
	end

	return cls.new(scene, owner, cfg, level, source)
end