-- chunkname: @src.battle.models.play.experience_gate

local ExperienceGate = class("ExperienceGate", battlePlay.Gate)

battlePlay.ExperienceGate = ExperienceGate
ExperienceGate.OperatorArgs = {
	canPause = true,
	canHandle = true,
	isFullManual = false,
	isAuto = false,
	lockAuto = false,
	canSkip = false,
	canSpeedAni = true
}

function ExperienceGate:newWaveAddObjsStrategy()
	self:waveAddCardRoles(1)
	self:waveAddCardRoles(2)
	self:doObjsAttrsCorrect(true, true)
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

local function adjustObjAttrs(obj)
	local cardData, attriRandom, randomNum

	cardData = csv.experience.cards[obj.dbID]
	attriRandom = table.deepcopy(cardData.attributeRandom)
	randomNum = ymrand.random(attriRandom[1] * 10000, attriRandom[2] * 10000)
	randomNum = randomNum / 10000

	local cfg = {}

	for attr, _ in pairs(ObjectAttrs.SixDimensionAttrs) do
		cfg[attr .. "C"] = randomNum
	end

	obj:objAttrsCorrect(cfg)
end

local function adjustTrialObjAttrs(obj, trialID, cfg)
	if obj.dbID == trialID then
		obj:objAttrsCorrect(cfg)
	end
end

function ExperienceGate:doObjsAttrsCorrect(isLeftC, isRightC)
	local trialID = self.data.trialID
	local trialCardID = csv.experience.cards[trialID].cardID
	local data = csv.experience.list[trialCardID]
	local cfg = {}

	for attr, _ in pairs(ObjectAttrs.AttrsTable) do
		if data[attr] then
			cfg[attr .. "C"] = data[attr]
		end
	end

	for _, obj in self.scene:ipairsHeros() do
		adjustObjAttrs(obj)
		adjustTrialObjAttrs(obj, trialID, cfg)
	end

	battlePlay.Gate.doObjsAttrsCorrect(self, isLeftC, isRightC)
end
