-- chunkname: @src.battle.app_views.battle.module.spec.gym

local currentTextParam = {
	scale = 1.1,
	pos1 = {
		x = 16,
		y = 25
	},
	pos2 = {
		x = 32,
		y = 23
	}
}
local backupTextParam = {
	offx = 102,
	scale = 1,
	pos1 = {
		x = 14,
		y = 26
	},
	pos2 = {
		x = 33,
		y = 23
	}
}
local PosByForce = {
	2,
	8
}

local function updateRankIcon(icon, rank, param)
	local word = "th"

	if rank == 1 then
		word = "st"
	elseif rank == 2 then
		word = "nd"
	elseif rank == 3 then
		word = "rd"
	end

	icon:scale(param.scale)
	icon:get("num"):setString(tostring(rank)):xy(param.pos1)
	icon:get("txt"):setString(word):xy(param.pos2)
end

local GymSpecView = class("GymSpecView", battleModule.CBase)

GymSpecView.RESOURCE_FILENAME = "battle_craft.json"
GymSpecView.RESOURCE_BINDING = {
	["enemyInfo.enemyList"] = "enemyInfoList",
	["selfInfo.selfList"] = "selfInfoList",
	backUpItem = "backUpItem",
	enemyInfo = "enemyInfo",
	selfInfo = "selfInfo",
	enemyWin = "enemyWin",
	selfWin = "selfWin",
	enemyMp = "enemyMp",
	selfMp = "selfMp"
}

function GymSpecView:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.root = cache.createWidget(self.RESOURCE_FILENAME)

	bindUI(self, self.root, self.RESOURCE_BINDING)
	self.root:addTo(parent, 99):show()
	self:init()
	self:initBar(self.selfMp:get("progress"), 1)
	self:initBar(self.enemyMp:get("progress"), -1)

	self.selfInfoProgress = self.selfInfo:get("progress")
	self.enemyInfoProgress = self.enemyInfo:get("progress")

	self:initProgressBar(self.selfInfo:get("progress"))
	self:initProgressBar(self.enemyInfo:get("progress"))
end

function GymSpecView:init()
	self.selfWin:hide()
	self.enemyWin:hide()

	self.myHpPercent = 100
	self.enemyHpPercent = 100
	self.myMpPercent = 0
	self.enemyMpPercent = 0
	self.items = {
		{},
		{}
	}

	nodetools.invoke(self.selfInfo, {
		"secondIcon",
		"thirdIcon",
		"iconBase1",
		"iconBase2"
	}, "hide")
	nodetools.invoke(self.enemyInfo, {
		"secondIcon",
		"thirdIcon",
		"iconBase1",
		"iconBase2"
	}, "hide")

	self.backUpIconData = {
		{},
		{}
	}

	self.root:setVisible(false)
end

function GymSpecView:setCurrent(panel, idx)
	local play = self.parent:getPlayModel()
	local firstRoleOut = play:getFirstRoleOut(idx)
	local bigHead = csv.unit[firstRoleOut.originUnitID].cardIcon2

	panel:get("current"):loadTexture(bigHead)

	local roleName = csv.unit[firstRoleOut.originUnitID].name

	panel:get("name"):setString(roleName)

	local forceWaveNum = play.groupRoundInit.forceTeams[play.groupRound]

	updateRankIcon(panel:get("firstIcon"), forceWaveNum[idx].waveIndex, currentTextParam)
end

function GymSpecView:setSkillName(panel, idx)
	local play = self.parent:getPlayModel()
	local firstRoleOut = play:getFirstRoleOut(idx)
	local bigSkillName = ""

	for k, v in pairs(firstRoleOut.skills) do
		local skillCfg = csv.skill[k]

		if skillCfg.skillType2 == battle.MainSkillType.BigSkill then
			bigSkillName = skillCfg.skillName
		end
	end

	panel:get("skillname"):setString(bigSkillName)
	adapt.setTextScaleWithWidth(panel:get("skillname"), nil, 220)
end

function GymSpecView:syncBackUpData(force)
	local play = self.parent:getPlayModel()
	local datas = play.groupRoleOut[play.groupRound]
	local forceWaveNum = play.groupRoundInit.forceTeams[play.groupRound]
	local ret = {}

	for k, v in ipairs(datas.waveRoleOut[force]) do
		if k ~= forceWaveNum[force].waveIndex then
			local roleOut = v[PosByForce[force]]
			local props = {
				rank = k,
				unitId = roleOut.roleId,
				advance = roleOut.advance,
				grayState = k < forceWaveNum[force].waveIndex and 2 or 1,
				flip = force == 2
			}

			table.insert(ret, props)
		end
	end

	if force == 1 then
		self:updateBackUpView(self.selfInfoList, ret, force)
	else
		self:updateBackUpView(self.enemyInfoList, ret, force)
	end
end

function GymSpecView:updateBackUpView(panel, datas, force)
	local function getItem(id)
		if self.items[force][id] then
			return self.items[force][id]
		end

		local item = self.backUpItem:clone()

		item:addTo(panel)
		table.insert(self.items[force], item)

		local size = item:size()
		local posx

		if force == 1 then
			posx = panel:x() + size.width * (id - 0.5) + 18 * (id - 1)
		else
			posx = panel:x() - size.width * (id - 0.5) - 18 * (id - 1)
		end

		item:xy(posx, panel:y())

		return item
	end

	for k, v in ipairs(datas) do
		local item = getItem(k)
		local childs = item:multiget("sortIcon", "iconBase")

		updateRankIcon(childs.sortIcon, v.rank, backupTextParam)

		if force == 2 then
			childs.sortIcon:xy(backupTextParam.offx, childs.sortIcon:y())
		end

		GymSpecView.setIconByData(childs.iconBase, v)
	end
end

function GymSpecView:onInitPvp()
	self:setCurrent(self.selfInfo, 1)
	self:setCurrent(self.enemyInfo, 2)
	self:setSkillName(self.selfMp, 1)
	self:setSkillName(self.enemyMp, 2)
	self:syncBackUpData(1)
	self:syncBackUpData(2)
	self.root:setVisible(true)
end

function GymSpecView:onChangeWave(winForce)
	if winForce == battle.Const.Win then
		self:setCurrent(self.enemyInfo, 2)
		self:setSkillName(self.enemyMp, 2)
		self:syncBackUpData(2)
	else
		self:setCurrent(self.selfInfo, 1)
		self:setSkillName(self.selfMp, 1)
		self:syncBackUpData(1)
	end
end

local showTime = 0.1

local function setHpBar(progress, value)
	transition.executeSequence(progress):progressTo(showTime, value):done()
end

local function setMpBar(panel, value)
	local progress = panel:get("progress")
	local fullPanel = panel:get("full")
	local width = progress:size().width

	transition.executeSequence(progress):func(function()
		if progress.whenChange then
			progress.whenChange(showTime, value)
		end
	end):delay(showTime):func(function()
		progress:visible(value < 100)
		fullPanel:visible(value >= 100)
	end):done()
end

function GymSpecView:onChangeHpMp(ratioTb)
	local function safeSet(value, num)
		if num >= 0 then
			self[value] = math.floor(num * 100)
		end
	end

	if ratioTb.selfHpRatio and ratioTb.enemyHpRatio then
		if ratioTb.selfHpRatio == -1 and self.myHpPercent == 1 then
			self.myHpPercent = 0
		end

		if math.abs(self.myHpPercent - ratioTb.selfHpRatio) > 1e-05 then
			safeSet("myHpPercent", ratioTb.selfHpRatio)
			setHpBar(self.selfInfoProgress, self.myHpPercent)
		end

		if ratioTb.enemyHpRatio == -1 and self.enemyHpPercent == 1 then
			self.enemyHpPercent = 0
		end

		if math.abs(self.enemyHpPercent - ratioTb.enemyHpRatio) > 1e-05 then
			safeSet("enemyHpPercent", ratioTb.enemyHpRatio)
			setHpBar(self.enemyInfoProgress, self.enemyHpPercent)
		end
	end

	if ratioTb.selfMpRatio and ratioTb.enemyMpRatio then
		if ratioTb.selfMpRatio == -1 and self.myMpPercent == 1 then
			self.myMpPercent = 0
		end

		if math.abs(self.myMpPercent - ratioTb.selfMpRatio) > 1e-05 then
			safeSet("myMpPercent", ratioTb.selfMpRatio)
			setMpBar(self.selfMp, self.myMpPercent)
		end

		if ratioTb.enemyMpRatio == -1 and self.enemyMpPercent == 1 then
			self.enemyMpPercent = 0
		end

		if math.abs(self.enemyMpPercent - ratioTb.enemyMpRatio) > 1e-05 then
			safeSet("enemyMpPercent", ratioTb.enemyMpRatio)
			setMpBar(self.enemyMp, self.enemyMpPercent)
		end
	end
end

function GymSpecView.setIconByData(iconPanel, cardData)
	if iconPanel.panel then
		iconPanel:removeAllChildren()
	end

	local panelSize = cc.size(198, 198)
	local panel = ccui.Layout:create():size(198, 198):scale(0.7):addTo(iconPanel, 1, "_card_")
	local quality = dataEasy.getQuality(cardData.advance, false)
	local boxRes = ui.QUALITY_BOX[quality]
	local imgBG = ccui.ImageView:create(boxRes):alignCenter(panelSize):addTo(panel, 1, "imgBG")
	local imgFG = ccui.ImageView:create(string.format("common/icon/panel_icon_k%d.png", quality)):alignCenter(panelSize):addTo(panel, 3, "imgFG")

	iconPanel.panel = panel

	local icon = ccui.ImageView:create(csv.unit[cardData.unitId].cardIcon):alignCenter(panelSize):scale(2):addTo(panel, 2, "icon")
	local grayState = cardData.grayState == 2 and "hsl_gray" or "normal"

	cache.setShader(imgBG, false, grayState)
	cache.setShader(icon, false, grayState)

	if cardData.flip then
		iconPanel:setFlippedX(true)
	end
end

function GymSpecView:onShowSpec(isShow)
	self.root:setVisible(isShow)
end

function GymSpecView:onClose()
	ViewBase.onClose(self)
end

function GymSpecView:initProgressBar(bar)
	local sprite9 = bar:getVirtualRenderer()
	local imgPath = sprite9:getTexture():getPath()
	local size = bar:size()
	local rect = sprite9:getCapInsets()
	local mask = ccui.Scale9Sprite:create()

	mask:initWithFile(rect, imgPath)
	mask:setScale9Enabled(true)
	mask:size(size)

	local x, y = bar:xy()
	local parent = bar:parent()

	bar:retain():removeSelf():xy(0, 0)

	local clip = cc.ClippingNode:create(mask):setAlphaThreshold(0.15):size(size):add(bar):xy(x, y):addTo(parent)

	bar:release()
end

function GymSpecView:initBar(bar, scale)
	local imgPath = "battle/craft/bar_card_b.png"
	local size = bar:size()
	local rect = cc.rect(0, 0, size.width, size.height)
	local width = size.width
	local img = ccui.Scale9Sprite:create()

	img:initWithFile(rect, imgPath)
	img:setScale9Enabled(isScale9Enabled)
	img:size(size):anchorPoint(0, 0):setCapInsets(rect)

	local mask = ccui.Scale9Sprite:create()

	mask:initWithFile(rect, imgPath)
	mask:setScale9Enabled(isScale9Enabled)
	mask:size(size):anchorPoint(0, 0):setCapInsets(rect)
	cc.ClippingNode:create(mask):setAlphaThreshold(0.15):anchorPoint(0, 0):size(size):add(img, 999, "img"):x(scale == 1 and 0 or width):scale(scale, 1):addTo(bar, 999, "clip")

	function bar.whenChange(showTime, p)
		local x = width * (p / 100 - 1)

		img:stopAllActions()

		local sequence = transition.executeSequence(img):moveTo(showTime, x, 0):done()
	end
end

return GymSpecView
