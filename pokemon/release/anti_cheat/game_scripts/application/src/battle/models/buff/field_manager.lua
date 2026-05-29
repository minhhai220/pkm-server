local FieldBuffManager = class("FieldBuffManager")
local CourtMap = {
	right = 2,
	left = 1,
	both = 3
}

FieldBuffManager.CourtMap = CourtMap

local replaceType = {
	newBeRestrain = -1,
	oldBeRestrain = 1,
	coexist = 0
}

function FieldBuffManager:ctor(scene)
	self.scene = scene
	self.fieldBuffCfg = {}
	self.courtBuffs = {
		{},
		{},
		{}
	}
end

function FieldBuffManager:addRelationCfg(buff, cfg)
	local force = buff.holder.force
	local fieldForce = {
		force,
		3 - force,
		CourtMap.both
	}
	local effectAbsForce = fieldForce[cfg.affectCourt]

	self.fieldBuffCfg[buff.id] = {
		level = cfg.level,
		nature = cfg.nature,
		effectAbsForce = effectAbsForce
	}
end

function FieldBuffManager:dealEffectBuff(newBuff)
	local id = newBuff.id
	local cfg = self.fieldBuffCfg[id]
	local absForce = cfg.effectAbsForce
	local buffList = self.courtBuffs[absForce]

	if itertools.isempty(buffList) then
		table.insert(buffList, newBuff)

		return
	end

	local removeIdxTb = {}
	local isAdd = true
	local newBuffOverType

	for i, curBuff in ipairs(buffList) do
		local courtCfg = self.fieldBuffCfg[curBuff.id]
		local type, overType = self:replaceCheck(cfg, courtCfg)

		if type == replaceType.oldBeRestrain then
			table.insert(removeIdxTb, {
				idx = i,
				overType = overType
			})
		elseif type == replaceType.newBeRestrain then
			isAdd = false
			newBuffOverType = overType
		end
	end

	removeIdxTb = itertools.reverse(removeIdxTb)

	for _, info in ipairs(removeIdxTb) do
		local curBuff = buffList[info.idx]

		table.remove(buffList, info.idx)
		curBuff:over({
			endType = info.overType
		})
	end

	if isAdd and not newBuff.isOver then
		table.insert(buffList, newBuff)
	else
		newBuff:over({
			endType = newBuffOverType
		})
	end
end

function FieldBuffManager:getAbsForce(buffId)
	local cfg = self.fieldBuffCfg[buffId]

	return cfg.effectAbsForce
end

function FieldBuffManager:clean(buffId)
	local absForce = self:getAbsForce(buffId)
	local buffList = self.courtBuffs[absForce]

	for i, buff in ipairs(buffList) do
		if buff.id == buffId then
			table.remove(buffList, i)

			break
		end
	end

	self.fieldBuffCfg[buffId] = nil
end

function FieldBuffManager:replaceCheck(cfg, courtCfg)
	local type = replaceType.coexist
	local overType = battle.BuffOverType.restrain

	if cfg.level == courtCfg.level then
		local restraintOld = skillHelper.getNatureMatrix(cfg.nature, game.NATURE_TABLE[courtCfg.nature], 0, 0)

		if restraintOld > 1 then
			type = replaceType.oldBeRestrain
		end

		local restraintNew = skillHelper.getNatureMatrix(courtCfg.nature, game.NATURE_TABLE[cfg.nature], 0, 0)

		if restraintNew > 1 then
			type = replaceType.newBeRestrain
		end
	else
		type = cfg.level > courtCfg.level and replaceType.oldBeRestrain or replaceType.newBeRestrain
		overType = battle.BuffOverType.level
	end

	return type, overType
end

return FieldBuffManager
