-- chunkname: @src.battle.models.buff.spec.aura_buff

local AuraBuffModel = class("AuraBuffModel", BuffModel)

globals.AuraBuffModel = AuraBuffModel

function AuraBuffModel:ctor(cfgId, holder, caster, args)
	BuffModel.ctor(self, cfgId, holder, caster, args)

	self.isAuraType = true
end
