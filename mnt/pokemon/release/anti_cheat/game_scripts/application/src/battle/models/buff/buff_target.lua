-- chunkname: @src.battle.models.buff.buff_target

local PosMap = {
	left = {
		{
			x = 2,
			y = 1
		},
		{
			x = 2,
			y = 2
		},
		{
			x = 2,
			y = 3
		},
		{
			x = 1,
			y = 1
		},
		{
			x = 1,
			y = 2
		},
		{
			x = 1,
			y = 3
		}
	},
	right = {
		[7] = {
			x = 1,
			y = 1
		},
		[8] = {
			x = 1,
			y = 2
		},
		[9] = {
			x = 1,
			y = 3
		},
		[10] = {
			x = 2,
			y = 1
		},
		[11] = {
			x = 2,
			y = 2
		},
		[12] = {
			x = 2,
			y = 3
		}
	}
}
local Pos = {
	left = {
		{
			4,
			5,
			6
		},
		{
			1,
			2,
			3
		}
	},
	right = {
		{
			7,
			8,
			9
		},
		{
			10,
			11,
			12
		}
	}
}
local NeighbourXY = {
	{
		0,
		1
	},
	{
		1,
		0
	},
	{
		0,
		-1
	},
	{
		-1,
		0
	}
}

local function getObjSideAllTarget(scene, obj)
	local heros = scene:getHerosMap(obj.force)
	local ret = {}

	for _, v in heros:order_pairs() do
		if v and not v:isDeath() then
			table.insert(ret, v)
		end
	end

	return ret
end

local function getObjOtherSideAllTarget(scene, obj)
	local heros = scene:getHerosMap(3 - obj.force)
	local ret = {}

	for _, v in heros:order_pairs() do
		if v and not v:isDeath() then
			table.insert(ret, v)
		end
	end

	return ret
end

local function getObjNear(obj, targets)
	local isLeft = obj.seat <= 6
	local positionMap = isLeft and PosMap.left or PosMap.right
	local position = isLeft and Pos.left or Pos.right
	local selfIdx = positionMap[obj.seat]
	local seatMap = {}

	if not selfIdx then
		return {}
	end

	for _, xy in ipairs(NeighbourXY) do
		local x = xy[1] + selfIdx.x
		local y = xy[2] + selfIdx.y

		if x > 0 and x <= 2 and y > 0 and y <= 3 then
			seatMap[position[x][y]] = true
		end
	end

	return arraytools.filter(targets, function(_, o)
		return seatMap[o.seat]
	end)
end

local function getRandomIdx(ret)
	if table.length(ret) > 0 then
		return ymrand.random(1, table.length(ret))
	end
end

local FindExtraTargetFuncs = {
	[battle.BuffExtraTargetType.holder] = function(self)
		return {
			self.holder
		}
	end,
	[battle.BuffExtraTargetType.caster] = function(self)
		return {
			self.caster
		}
	end,
	[battle.BuffExtraTargetType.holderForceNoDeathRandom] = function(self)
		local all = getObjSideAllTarget(self.scene, self.holder)
		local seat = getRandomIdx(all)

		return {
			all[seat]
		}
	end,
	[battle.BuffExtraTargetType.surroundHolderNoDath] = function(self)
		return getObjNear(self.holder, getObjSideAllTarget(self.scene, self.holder))
	end,
	[battle.BuffExtraTargetType.holderForce] = function(self)
		return getObjSideAllTarget(self.scene, self.holder)
	end,
	[battle.BuffExtraTargetType.casterForceNoDeathRandom] = function(self)
		local all = getObjSideAllTarget(self.scene, self.caster)
		local seat = getRandomIdx(all)

		return {
			all[seat]
		}
	end,
	[battle.BuffExtraTargetType.surroundCasterNoDath] = function(self)
		return getObjNear(self.caster, getObjSideAllTarget(self.scene, self.caster))
	end,
	[battle.BuffExtraTargetType.casterForce] = function(self)
		return getObjSideAllTarget(self.scene, self.caster)
	end,
	[battle.BuffExtraTargetType.holderEnemyForce] = function(self)
		return getObjOtherSideAllTarget(self.scene, self.holder)
	end,
	[battle.BuffExtraTargetType.casterEnemyForce] = function(self)
		return getObjOtherSideAllTarget(self.scene, self.caster)
	end,
	[battle.BuffExtraTargetType.skillOwner] = function(self)
		return {
			self.objThatTriggeringMeNow.owner
		}
	end,
	[battle.BuffExtraTargetType.killHolder] = function(self)
		return {
			self.holder.attackMeDeadObj
		}
	end,
	[battle.BuffExtraTargetType.casterEnemyForceRandom] = function(self)
		local all = getObjOtherSideAllTarget(self.scene, self.caster)
		local seat = getRandomIdx(all)

		return {
			all[seat]
		}
	end,
	[battle.BuffExtraTargetType.surroundHolderKill] = function(self)
		return getObjNear(self.objThatTriggeringMeNow, getObjSideAllTarget(self.scene, self.objThatTriggeringMeNow))
	end,
	[battle.BuffExtraTargetType.triggerObject] = function(self)
		return {
			self.objThatTriggeringMeNow.obj
		}
	end,
	[battle.BuffExtraTargetType.segProcessTargetRandom] = function(self)
		local target = self.holder:getCurTarget()

		if target then
			return {
				target
			}
		end

		local segProcessTargets = self.extraTargets[battle.BuffExtraTargetType.segProcessTargets] or {}
		local seat = getRandomIdx(segProcessTargets)

		return {
			segProcessTargets[seat]
		}
	end,
	[battle.BuffExtraTargetType.mainTarget] = function(self)
		return {
			self.holder:getCurTarget()
		}
	end,
	[battle.BuffExtraTargetType.skillNowTarget] = function(self)
		if self.holder.curSkill then
			return {
				self.holder.curSkill:getNowTarget()
			}
		end

		return {
			self.holder:getCurTarget()
		}
	end,
	[battle.BuffExtraTargetType.skillAllDamageTargets] = function(self)
		local runSkill = self.holder.curSkill

		if runSkill then
			return runSkill.allDamagedOrder
		end

		return {}
	end,
	[battle.BuffExtraTargetType.triggerAttacker] = function(self)
		return {
			self.objThatTriggeringMeNow.attacker
		}
	end,
	[battle.BuffExtraTargetType.triggerCaster] = function(self)
		return {
			self.objThatTriggeringMeNow.buffCaster
		}
	end
}

function BuffModel:findTargetsByCfg(nOrStr, getSelectableExObj, exArgs)
	local typ = type(nOrStr)

	if typ == "number" then
		local f = FindExtraTargetFuncs[nOrStr]

		if f then
			return f(self)
		else
			return self.extraTargets[nOrStr]
		end
	elseif typ == "table" then
		if nOrStr.input then
			local args = {
				trigger = self.triggerEnv,
				extraTargets = self.extraTargets,
				getSelectableExObj = getSelectableExObj,
				inputExtraStr = exArgs and exArgs.inputExtraStr
			}
			local targets = newTargetFinder(self.caster, self.holder, nil, args, nOrStr)

			return targets
		end
	else
		return self:cfg2ValueWithTrigger(nOrStr)
	end
end
