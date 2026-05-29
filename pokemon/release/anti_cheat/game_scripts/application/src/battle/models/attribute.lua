local AttrsTable = {
	natureRestraint = 0,
	immuneControl = 0,
	controlPer = 0,
	cure = 0,
	rebound = 0,
	suckBlood = 0,
	ultimateSub = 0,
	ultimateAdd = 0,
	damageSub = 0,
	damageAdd = 0,
	hit = 0,
	dodge = 0,
	blockPower = 0,
	breakBlock = 0,
	block = 0,
	strikeResistance = 0,
	strikeDamage = 0,
	strike = 0,
	speed = 0,
	specialDefenceIgnore = 0,
	defenceIgnore = 0,
	specialDefence = 0,
	defence = 0,
	specialDamage = 0,
	damage = 0,
	mp1Recover = 0,
	hpRecover = 0,
	initMp1 = 0,
	mp1Max = 0,
	hpMax = 0,
	evilDamageReduce = 0,
	steelDamageReduce = 0,
	fairyDamageReduce = 0,
	pvpDamageAdd = 0,
	pvpDamageSub = 0,
	strikeDamageSub = 0,
	healAdd = 0,
	beHealAdd = 0,
	dragonDamageReduce = 0,
	ghostDamageReduce = 0,
	rockDamageReduce = 0,
	wormDamageReduce = 0,
	superDamageReduce = 0,
	flyDamageReduce = 0,
	groundDamageReduce = 0,
	poisonDamageReduce = 0,
	combatDamageReduce = 0,
	iceDamageReduce = 0,
	electricityDamageReduce = 0,
	grassDamageReduce = 0,
	waterDamageReduce = 0,
	fireDamageReduce = 0,
	normalDamageReduce = 0,
	fairyDamageDeepen = 0,
	steelDamageDeepen = 0,
	evilDamageDeepen = 0,
	dragonDamageDeepen = 0,
	ghostDamageDeepen = 0,
	rockDamageDeepen = 0,
	wormDamageDeepen = 0,
	superDamageDeepen = 0,
	damageRateAdd = 0,
	damageHit = 0,
	damageDodge = 0,
	ignoreDamageSub = 0,
	ignoreStrikeResistance = 0,
	finalSkillAddRate = 0,
	finalDamageAdd = 0,
	finalDamageSub = 0,
	finalDamageDeepen = 0,
	finalDamageReduce = 0,
	mpBeAttackRecover = 0,
	trueDamageAdd = 0,
	trueDamageSub = 0,
	weight = 0,
	height = 0,
	finalCureRate = 0,
	cureStrikeEffect = 0,
	cureStrike = 0,
	natureResistance = 0,
	flyDamageDeepen = 0,
	groundDamageDeepen = 0,
	poisonDamageDeepen = 0,
	combatDamageDeepen = 0,
	iceDamageDeepen = 0,
	electricityDamageDeepen = 0,
	grassDamageDeepen = 0,
	waterDamageDeepen = 0,
	fireDamageDeepen = 0,
	normalDamageDeepen = 0,
	fairyCure = 0,
	steelCure = 0,
	evilCure = 0,
	dragonCure = 0,
	ghostCure = 0,
	rockCure = 0,
	wormCure = 0,
	superCure = 0,
	flyCure = 0,
	groundCure = 0,
	poisonCure = 0,
	combatCure = 0,
	iceCure = 0,
	electricityCure = 0,
	grassCure = 0,
	waterCure = 0,
	fireCure = 0,
	normalCure = 0,
	fairyDamageSub = 0,
	steelDamageSub = 0,
	evilDamageSub = 0,
	dragonDamageSub = 0,
	ghostDamageSub = 0,
	rockDamageSub = 0,
	wormDamageSub = 0,
	superDamageSub = 0,
	flyDamageSub = 0,
	groundDamageSub = 0,
	poisonDamageSub = 0,
	combatDamageSub = 0,
	iceDamageSub = 0,
	electricityDamageSub = 0,
	grassDamageSub = 0,
	waterDamageSub = 0,
	fireDamageSub = 0,
	normalDamageSub = 0,
	fairyDamageAdd = 0,
	steelDamageAdd = 0,
	evilDamageAdd = 0,
	dragonDamageAdd = 0,
	ghostDamageAdd = 0,
	rockDamageAdd = 0,
	wormDamageAdd = 0,
	superDamageAdd = 0,
	flyDamageAdd = 0,
	groundDamageAdd = 0,
	poisonDamageAdd = 0,
	combatDamageAdd = 0,
	iceDamageAdd = 0,
	electricityDamageAdd = 0,
	grassDamageAdd = 0,
	waterDamageAdd = 0,
	fireDamageAdd = 0,
	normalDamageAdd = 0,
	specialDamageSub = 0,
	specialDamageAdd = 0,
	physicalDamageSub = 0,
	physicalDamageAdd = 0,
	damageReduce = 0,
	damageDeepen = 0
}
local SaltAttrsTable = table.salttable(AttrsTable)

function globals.RefreshSaltAttrsTable()
	SaltAttrsTable = table.salttable(AttrsTable)
end

local function intFuncFinalWrap(attr, min)
	return function(self, getBase2)
		if type(min) == "string" then
			min = ConstSaltNumbers[min]
		end

		if getBase2 then
			local v = self.base2[attr] + self.buff[attr]

			return math.max(v, min)
		else
			local v = self.base[attr] + self.buff[attr]

			self.final[attr] = math.max(v, min)
		end
	end
end

local function floatFuncFinalWrap(attr, min, start)
	return function(self, getBase2)
		if type(start) == "string" then
			start = ConstSaltNumbers[start]
		end

		if type(min) == "string" then
			min = ConstSaltNumbers[min]
		end

		if getBase2 then
			local v = (start or 0) + self.base2[attr] + self.buff[attr]

			return math.max(v / ConstSaltNumbers.wan, min)
		else
			local v = (start or 0) + self.base[attr] + self.buff[attr]

			self.final[attr] = math.max(v / ConstSaltNumbers.wan, min)
		end
	end
end

local function gateTypeWrapGen(wrap, key)
	return function(self)
		if self.sceneTag[key] then
			wrap(self)
		end
	end
end

local AttrGateTypes = {
	PVP = "pvpAttrTakeEffect"
}
local AttrsFinalFuncTable = {
	hpRecover = intFuncFinalWrap("hpRecover", "zero"),
	damage = intFuncFinalWrap("damage", "zero"),
	specialDamage = intFuncFinalWrap("specialDamage", "zero"),
	defence = intFuncFinalWrap("defence", "zero"),
	specialDefence = intFuncFinalWrap("specialDefence", "zero"),
	defenceIgnore = floatFuncFinalWrap("defenceIgnore", "zero"),
	specialDefenceIgnore = floatFuncFinalWrap("specialDefenceIgnore", "zero"),
	hpMax = intFuncFinalWrap("hpMax", "one"),
	mp1Max = intFuncFinalWrap("mp1Max", "one"),
	speed = intFuncFinalWrap("speed", "zero"),
	initMp1 = intFuncFinalWrap("initMp1", "zero"),
	mp1Recover = floatFuncFinalWrap("mp1Recover", "neg1"),
	strike = floatFuncFinalWrap("strike", "zero"),
	strikeDamage = floatFuncFinalWrap("strikeDamage", "zero"),
	strikeResistance = floatFuncFinalWrap("strikeResistance", "zero"),
	block = floatFuncFinalWrap("block", "zero"),
	breakBlock = floatFuncFinalWrap("breakBlock", "zero"),
	blockPower = floatFuncFinalWrap("blockPower", "zero"),
	dodge = floatFuncFinalWrap("dodge", "zero"),
	hit = floatFuncFinalWrap("hit", "zero"),
	damageAdd = floatFuncFinalWrap("damageAdd", "zero"),
	damageSub = floatFuncFinalWrap("damageSub", "zero"),
	suckBlood = floatFuncFinalWrap("suckBlood", "zero"),
	rebound = floatFuncFinalWrap("rebound", "zero"),
	ultimateAdd = floatFuncFinalWrap("ultimateAdd", "zero"),
	ultimateSub = floatFuncFinalWrap("ultimateSub", "zero"),
	controlPer = floatFuncFinalWrap("controlPer", "zero"),
	immuneControl = floatFuncFinalWrap("immuneControl", "zero"),
	natureRestraint = floatFuncFinalWrap("natureRestraint", "zero"),
	cure = floatFuncFinalWrap("cure", "dot05", "zero"),
	damageDeepen = floatFuncFinalWrap("damageDeepen", "zero"),
	damageReduce = floatFuncFinalWrap("damageReduce", "zero"),
	physicalDamageAdd = floatFuncFinalWrap("physicalDamageAdd", "zero"),
	physicalDamageSub = floatFuncFinalWrap("physicalDamageSub", "zero"),
	specialDamageAdd = floatFuncFinalWrap("specialDamageAdd", "zero"),
	specialDamageSub = floatFuncFinalWrap("specialDamageSub", "zero"),
	normalDamageAdd = floatFuncFinalWrap("normalDamageAdd", "zero"),
	fireDamageAdd = floatFuncFinalWrap("fireDamageAdd", "zero"),
	waterDamageAdd = floatFuncFinalWrap("waterDamageAdd", "zero"),
	grassDamageAdd = floatFuncFinalWrap("grassDamageAdd", "zero"),
	electricityDamageAdd = floatFuncFinalWrap("electricityDamageAdd", "zero"),
	iceDamageAdd = floatFuncFinalWrap("iceDamageAdd", "zero"),
	combatDamageAdd = floatFuncFinalWrap("combatDamageAdd", "zero"),
	poisonDamageAdd = floatFuncFinalWrap("poisonDamageAdd", "zero"),
	groundDamageAdd = floatFuncFinalWrap("groundDamageAdd", "zero"),
	flyDamageAdd = floatFuncFinalWrap("flyDamageAdd", "zero"),
	superDamageAdd = floatFuncFinalWrap("superDamageAdd", "zero"),
	wormDamageAdd = floatFuncFinalWrap("wormDamageAdd", "zero"),
	rockDamageAdd = floatFuncFinalWrap("rockDamageAdd", "zero"),
	ghostDamageAdd = floatFuncFinalWrap("ghostDamageAdd", "zero"),
	dragonDamageAdd = floatFuncFinalWrap("dragonDamageAdd", "zero"),
	evilDamageAdd = floatFuncFinalWrap("evilDamageAdd", "zero"),
	steelDamageAdd = floatFuncFinalWrap("steelDamageAdd", "zero"),
	fairyDamageAdd = floatFuncFinalWrap("fairyDamageAdd", "zero"),
	normalDamageSub = floatFuncFinalWrap("normalDamageSub", "zero"),
	fireDamageSub = floatFuncFinalWrap("fireDamageSub", "zero"),
	waterDamageSub = floatFuncFinalWrap("waterDamageSub", "zero"),
	grassDamageSub = floatFuncFinalWrap("grassDamageSub", "zero"),
	electricityDamageSub = floatFuncFinalWrap("electricityDamageSub", "zero"),
	iceDamageSub = floatFuncFinalWrap("iceDamageSub", "zero"),
	combatDamageSub = floatFuncFinalWrap("combatDamageSub", "zero"),
	poisonDamageSub = floatFuncFinalWrap("poisonDamageSub", "zero"),
	groundDamageSub = floatFuncFinalWrap("groundDamageSub", "zero"),
	flyDamageSub = floatFuncFinalWrap("flyDamageSub", "zero"),
	superDamageSub = floatFuncFinalWrap("superDamageSub", "zero"),
	wormDamageSub = floatFuncFinalWrap("wormDamageSub", "zero"),
	rockDamageSub = floatFuncFinalWrap("rockDamageSub", "zero"),
	ghostDamageSub = floatFuncFinalWrap("ghostDamageSub", "zero"),
	dragonDamageSub = floatFuncFinalWrap("dragonDamageSub", "zero"),
	evilDamageSub = floatFuncFinalWrap("evilDamageSub", "zero"),
	steelDamageSub = floatFuncFinalWrap("steelDamageSub", "zero"),
	fairyDamageSub = floatFuncFinalWrap("fairyDamageSub", "zero"),
	normalCure = floatFuncFinalWrap("normalCure", "zero"),
	fireCure = floatFuncFinalWrap("fireCure", "zero"),
	waterCure = floatFuncFinalWrap("waterCure", "zero"),
	grassCure = floatFuncFinalWrap("grassCure", "zero"),
	electricityCure = floatFuncFinalWrap("electricityCure", "zero"),
	iceCure = floatFuncFinalWrap("iceCure", "zero"),
	combatCure = floatFuncFinalWrap("combatCure", "zero"),
	poisonCure = floatFuncFinalWrap("poisonCure", "zero"),
	groundCure = floatFuncFinalWrap("groundCure", "zero"),
	flyCure = floatFuncFinalWrap("flyCure", "zero"),
	superCure = floatFuncFinalWrap("superCure", "zero"),
	wormCure = floatFuncFinalWrap("wormCure", "zero"),
	rockCure = floatFuncFinalWrap("rockCure", "zero"),
	ghostCure = floatFuncFinalWrap("ghostCure", "zero"),
	dragonCure = floatFuncFinalWrap("dragonCure", "zero"),
	evilCure = floatFuncFinalWrap("evilCure", "zero"),
	steelCure = floatFuncFinalWrap("steelCure", "zero"),
	fairyCure = floatFuncFinalWrap("fairyCure", "zero"),
	normalDamageDeepen = floatFuncFinalWrap("normalDamageDeepen", "zero"),
	fireDamageDeepen = floatFuncFinalWrap("fireDamageDeepen", "zero"),
	waterDamageDeepen = floatFuncFinalWrap("waterDamageDeepen", "zero"),
	grassDamageDeepen = floatFuncFinalWrap("grassDamageDeepen", "zero"),
	electricityDamageDeepen = floatFuncFinalWrap("electricityDamageDeepen", "zero"),
	iceDamageDeepen = floatFuncFinalWrap("iceDamageDeepen", "zero"),
	combatDamageDeepen = floatFuncFinalWrap("combatDamageDeepen", "zero"),
	poisonDamageDeepen = floatFuncFinalWrap("poisonDamageDeepen", "zero"),
	groundDamageDeepen = floatFuncFinalWrap("groundDamageDeepen", "zero"),
	flyDamageDeepen = floatFuncFinalWrap("flyDamageDeepen", "zero"),
	superDamageDeepen = floatFuncFinalWrap("superDamageDeepen", "zero"),
	wormDamageDeepen = floatFuncFinalWrap("wormDamageDeepen", "zero"),
	rockDamageDeepen = floatFuncFinalWrap("rockDamageDeepen", "zero"),
	ghostDamageDeepen = floatFuncFinalWrap("ghostDamageDeepen", "zero"),
	dragonDamageDeepen = floatFuncFinalWrap("dragonDamageDeepen", "zero"),
	evilDamageDeepen = floatFuncFinalWrap("evilDamageDeepen", "zero"),
	steelDamageDeepen = floatFuncFinalWrap("steelDamageDeepen", "zero"),
	fairyDamageDeepen = floatFuncFinalWrap("fairyDamageDeepen", "zero"),
	normalDamageReduce = floatFuncFinalWrap("normalDamageReduce", "zero"),
	fireDamageReduce = floatFuncFinalWrap("fireDamageReduce", "zero"),
	waterDamageReduce = floatFuncFinalWrap("waterDamageReduce", "zero"),
	grassDamageReduce = floatFuncFinalWrap("grassDamageReduce", "zero"),
	electricityDamageReduce = floatFuncFinalWrap("electricityDamageReduce", "zero"),
	iceDamageReduce = floatFuncFinalWrap("iceDamageReduce", "zero"),
	combatDamageReduce = floatFuncFinalWrap("combatDamageReduce", "zero"),
	poisonDamageReduce = floatFuncFinalWrap("poisonDamageReduce", "zero"),
	groundDamageReduce = floatFuncFinalWrap("groundDamageReduce", "zero"),
	flyDamageReduce = floatFuncFinalWrap("flyDamageReduce", "zero"),
	superDamageReduce = floatFuncFinalWrap("superDamageReduce", "zero"),
	wormDamageReduce = floatFuncFinalWrap("wormDamageReduce", "zero"),
	rockDamageReduce = floatFuncFinalWrap("rockDamageReduce", "zero"),
	ghostDamageReduce = floatFuncFinalWrap("ghostDamageReduce", "zero"),
	dragonDamageReduce = floatFuncFinalWrap("dragonDamageReduce", "zero"),
	evilDamageReduce = floatFuncFinalWrap("evilDamageReduce", "zero"),
	steelDamageReduce = floatFuncFinalWrap("steelDamageReduce", "zero"),
	fairyDamageReduce = floatFuncFinalWrap("fairyDamageReduce", "zero"),
	pvpDamageAdd = gateTypeWrapGen(floatFuncFinalWrap("pvpDamageAdd", "zero"), AttrGateTypes.PVP),
	pvpDamageSub = gateTypeWrapGen(floatFuncFinalWrap("pvpDamageSub", "zero"), AttrGateTypes.PVP),
	strikeDamageSub = floatFuncFinalWrap("strikeDamageSub", "zero"),
	healAdd = floatFuncFinalWrap("healAdd", "neg1"),
	beHealAdd = floatFuncFinalWrap("beHealAdd", "neg1"),
	damageRateAdd = intFuncFinalWrap("damageRateAdd", "zero"),
	damageDodge = floatFuncFinalWrap("damageDodge", "zero"),
	damageHit = floatFuncFinalWrap("damageHit", "zero"),
	ignoreDamageSub = floatFuncFinalWrap("ignoreDamageSub", "zero"),
	ignoreStrikeResistance = floatFuncFinalWrap("ignoreStrikeResistance", "zero"),
	finalSkillAddRate = floatFuncFinalWrap("finalSkillAddRate", "zero"),
	finalDamageAdd = floatFuncFinalWrap("finalDamageAdd", "zero"),
	finalDamageSub = floatFuncFinalWrap("finalDamageSub", "zero"),
	finalDamageDeepen = floatFuncFinalWrap("finalDamageDeepen", "zero"),
	finalDamageReduce = floatFuncFinalWrap("finalDamageReduce", "zero"),
	mpBeAttackRecover = floatFuncFinalWrap("mpBeAttackRecover", "zero"),
	trueDamageAdd = floatFuncFinalWrap("trueDamageAdd", "zero"),
	trueDamageSub = floatFuncFinalWrap("trueDamageSub", "zero"),
	natureResistance = floatFuncFinalWrap("natureResistance", "zero"),
	cureStrike = floatFuncFinalWrap("cureStrike", "zero"),
	cureStrikeEffect = floatFuncFinalWrap("cureStrikeEffect", "zero"),
	finalCureRate = floatFuncFinalWrap("finalCureRate", "neg1"),
	height = intFuncFinalWrap("height", "zero"),
	weight = intFuncFinalWrap("weight", "zero")
}
local SixDimensionAttrs = {
	damage = true,
	specialDefence = true,
	speed = true,
	hpMax = true,
	defence = true,
	specialDamage = true
}

globals.ObjectAttrs = class("ObjectAttrs")
ObjectAttrs.AttrsTable = AttrsTable
ObjectAttrs.SixDimensionAttrs = SixDimensionAttrs
ObjectAttrs.AttrsFinalFuncTable = AttrsFinalFuncTable

local function checkAttrsTableCheat()
	for k, v in pairs(AttrsTable) do
		if math.abs(SaltAttrsTable[k] - v) > 1e-05 then
			exitApp("close your cheating software")
		end
	end
end

function globals.getAttrTransformRate(attrName)
	if not AttrsFinalFuncTable[attrName] then
		return 1
	end

	local _self = {
		base = {
			[attrName] = 1
		},
		buff = {
			[attrName] = 0
		},
		final = {
			[attrName] = 0
		}
	}

	AttrsFinalFuncTable[attrName](_self)

	return 1 / _self.final[attrName]
end

function ObjectAttrs:ctor()
	checkAttrsTableCheat()

	self.base = table.salttable(AttrsTable)
	self.base2 = table.salttable(AttrsTable)
	self.buff = table.salttable(AttrsTable)
	self.aura = table.salttable(AttrsTable)
	self.final = table.salttable(AttrsTable)
	self.sceneTag = {}

	self:calcFinal()
end

function ObjectAttrs:setSceneTag(sceneTag)
	self.sceneTag = sceneTag or {}
end

function ObjectAttrs:setBase(data)
	data.hpMax = math.floor(data.hp)
	data.mp1Max = data.mp1
	data.damageHit = data.damageHit or 10000

	local base = clone(AttrsTable)
	local base2 = clone(AttrsTable)

	for attr, _ in pairs(base) do
		if data[attr] ~= nil then
			base[attr] = data[attr]
			base2[attr] = data.role2Data and data.role2Data[attr] or data[attr]
		end

		self.aura[attr] = 1
	end

	self.base = table.salttable(base)
	self.base2 = table.salttable(base2)

	self:calcFinal()
end

local forceIntAttrs = {
	hpMax = true
}

local function checkToInt(v, attr)
	if not forceIntAttrs[attr] then
		return v
	end

	return math.floor(v + 0.5)
end

function ObjectAttrs:correct(cfg)
	for attr, _ in pairs(AttrsTable) do
		local v = cfg[attr .. "C"]

		if v ~= nil then
			self.base[attr] = checkToInt(self.base[attr] * v, attr)
			self.base2[attr] = checkToInt(self.base2[attr] * v, attr)
		end
	end

	self:calcFinal()
end

function ObjectAttrs:calcFinal()
	for attr, f in pairs(AttrsFinalFuncTable) do
		f(self)
	end
end

function ObjectAttrs:updateMaxBaseAttr(attr, val)
	self.base[attr] = math.max(self.base[attr], val)

	AttrsFinalFuncTable[attr](self)
end

function ObjectAttrs:setBaseAttr(attr, val)
	self.base[attr] = val

	AttrsFinalFuncTable[attr](self)
end

function ObjectAttrs:setBase2Attr(attr, val)
	self.base2[attr] = val
end

function ObjectAttrs:setBuffAttr(attr, val)
	self.buff[attr] = val

	AttrsFinalFuncTable[attr](self)
end

function ObjectAttrs:addBaseAttr(attr, delta)
	self.base[attr] = delta + self.base[attr]

	AttrsFinalFuncTable[attr](self)
end

function ObjectAttrs:addBase2Attr(attr, delta)
	self.base2[attr] = delta + self.base2[attr]
end

function ObjectAttrs:addBuffAttr(attr, delta)
	self.buff[attr] = delta + self.buff[attr]

	AttrsFinalFuncTable[attr](self)
end

function ObjectAttrs:addAuraAttr(attr, delta)
	self.aura[attr] = self.aura[attr] + delta
end

function ObjectAttrs:getSelfFinalAttr(attr)
	return self.final[attr]
end

function ObjectAttrs:getFinalAttr(attr)
	return self.final[attr] * math.max(self.aura[attr], 0)
end

function ObjectAttrs:getBase2FinalAttr(attr)
	return AttrsFinalFuncTable[attr](self, true) * math.max(self.aura[attr], 0)
end

function ObjectAttrs:getBase2RealFinalAttr(attr)
	return AttrsFinalFuncTable[attr](self, true)
end

local limitMin = {
	default = ConstSaltNumbers.zero,
	hpMax = ConstSaltNumbers.one,
	mp1Max = ConstSaltNumbers.one,
	mp1Recover = ConstSaltNumbers.neg1,
	healAdd = ConstSaltNumbers.neg1,
	beHealAdd = ConstSaltNumbers.neg1
}

function ObjectAttrs:cloneFinalAttr(fix)
	fix = fix or 1

	local ret, min = {}, limitMin.default

	for attr, f in pairs(AttrsTable) do
		min = limitMin[attr] or limitMin.default
		ret[attr] = math.max(self.buff[attr] + self.base[attr], min) * fix
	end

	return ret
end
