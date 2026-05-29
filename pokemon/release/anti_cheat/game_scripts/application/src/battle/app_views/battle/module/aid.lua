-- chunkname: @src.battle.app_views.battle.module.aid

local _max = math.max
local AidInfo = class("AidInfo", battleModule.CBase)

function AidInfo:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.lAid = self.parent.UIWidgetLeftAid
	self.rAid = self.parent.UIWidgetRightAid
	self.skillModel = {
		{},
		{}
	}

	self:initAidObjLimit()

	self.isShow = self.aidObjLimit[1] + self.aidObjLimit[2] > 0
	self.aidVisible = {
		false,
		false
	}
	self.aidManager = nil

	if self.parent:isPVEScene() then
		local wavaPanel = self.parent.UIWidgetMid:get("widgetPanel.wavePanel")
		local lx, ly = self.lAid:getPosition()
		local rx, ry = self.rAid:getPosition()
		local pos = self.lAid:getParent():convertToNodeSpace(wavaPanel:convertToWorldSpace(cc.p(0, 0)))

		self.lAid:setPosition(pos.x, pos.y)
		self.rAid:setPosition(rx + (lx - pos.x), ry + (pos.y - ly))
	end

	self.lAid:hide()
	self.rAid:hide()
end

function AidInfo:initAidObjLimit()
	local levels = self.parent.data.levels or {
		200,
		200
	}
	local gateType = self.parent.gateType
	local deployType = self.parent:getDeployType()
	local mulitp = 1

	if deployType == game.DEPLOY_TYPE.MultTwo then
		mulitp = 2
	elseif deployType == game.DEPLOY_TYPE.MultThree then
		mulitp = 3
	end

	local aidObjLimit1 = dataEasy.getAidNum(gateType, mulitp, levels[1])
	local aidObjLimit2 = dataEasy.getAidNum(gateType, mulitp, levels[2] or 200)

	self.aidObjLimit = {
		aidObjLimit1,
		aidObjLimit2
	}
end

function AidInfo:onInitAidInfo(aidManager)
	if not self:isShowAid() then
		return
	end

	self.aidManager = aidManager
	self.aidTimesLimit = self.aidManager.timesLimit
	self.initTimes = self.aidManager.initTimes

	self:onResetAidInfo(1)
	self:onResetAidInfo(2)
end

function AidInfo:onResetAidInfo(force)
	if not self:isShowAid() then
		return
	end

	if force == 1 then
		self.lAid:hide()
		self:initForceAid(self.lAid:get("aidPoint"))
	else
		self.rAid:hide()
		self:initForceAid(self.rAid:get("aidPoint"))
	end

	self.aidVisible[force] = false

	for k, data in ipairs(self.skillModel[force]) do
		data.node:removeFromParent()
	end

	self.skillModel[force] = {}

	self:refreshInfo(force)
	self:onUpdateForceAidTimes(force, self.initTimes)
end

function AidInfo:onNewAidSkill(force, key, unitID, timesLimit)
	if not self:isShowAid() then
		return
	end

	local aidSkillModel = {
		key = key,
		unitID = unitID,
		timesLimit = timesLimit,
		leftTimes = timesLimit
	}

	table.insert(self.skillModel[force], aidSkillModel)

	self.aidVisible[force] = true

	if force == 1 then
		self.lAid:show()
	else
		self.rAid:show()
	end
end

local function changePoint(points, num, limit)
	for i = 1, limit do
		local point = points:get("point" .. i)

		if i <= num then
			point:get("light"):setVisible(true)
		else
			point:get("light"):setVisible(false)
		end
	end
end

function AidInfo:initForceAid(points)
	local width = 12 + 36 * self.aidTimesLimit

	points:setContentSize(width, points:getContentSize().height)

	local tempPoint = points:get("point")
	local ox = -27
	local limit = math.max(self.aidTimesLimit, points:getChildrenCount() - 1)

	for i = 1, limit do
		if not points:getChildByName("point" .. i) then
			local point = tempPoint:clone()

			point:addTo(points):name("point" .. i):setPosition(ox + i * 36, 21):setVisible(true)
		elseif i > self.aidTimesLimit then
			points:removeChildByName("point" .. i)
		end
	end

	changePoint(points, self.initTimes, self.aidTimesLimit)
end

function AidInfo:initSkillNodes(force, aidObjLimit)
	local aidNode = force == 1 and self.lAid or self.rAid
	local aidInfoNode = aidNode:get("aidInfo")
	local tempAidRole = aidInfoNode:get("aidRole")
	local sumWidth = 0

	aidObjLimit = math.max(#self.skillModel[force], aidObjLimit)

	for index = 1, aidObjLimit do
		local aidRole = tempAidRole:clone()
		local aidSkillModel = self.skillModel[force][index]
		local num = aidSkillModel.timesLimit or 3
		local points = aidRole:get("aidPoint")
		local width = 12 + 36 * _max(num, 3)

		points:setContentSize(width, points:getContentSize().height)
		aidRole:addTo(aidInfoNode):name("aidRole" .. index):setContentSize(width + 10, aidRole:getContentSize().height):setPosition(30 + sumWidth, 28):setVisible(true)

		aidSkillModel.node = aidRole
		sumWidth = sumWidth + aidRole:getContentSize().width

		if aidSkillModel.unitID then
			aidRole:get("head"):texture(csv.unit[aidSkillModel.unitID].iconSimple):scale(1.6)

			local tempPoint = points:get("point")
			local ox = -27

			if num < 3 then
				ox = ox + 36 / num
			end

			for i = 1, num do
				local point = tempPoint:clone()

				point:addTo(points):name("point" .. i):setPosition(ox + i * 36, 21):setVisible(true)
			end
		else
			points:opacity(76)
		end
	end

	aidInfoNode:setContentSize(sumWidth + 60, aidInfoNode:getContentSize().height)
end

function AidInfo:refreshInfo(force, isShow)
	local aid = force == 1 and self.lAid or self.rAid
	local aidInfo = aid:get("aidInfo")

	if isShow ~= nil then
		aidInfo:setVisible(isShow)
	end

	for i, data in ipairs(self.skillModel[force]) do
		if data.unitID then
			changePoint(data.node:get("aidPoint"), data.leftTimes, data.timesLimit)
		end
	end
end

function AidInfo:onUpdateObjAidTimes(force, key, delta)
	if not self:isShowAid() then
		return
	end

	for i, t in ipairs(self.skillModel[force]) do
		if t.key == key then
			t.leftTimes = t.leftTimes + delta

			self:refreshInfo(force)
		end
	end
end

function AidInfo:onSetObjAidTimes(force, key, leftTimes)
	if not self:isShowAid() then
		return
	end

	for i, t in ipairs(self.skillModel[force]) do
		if t.key == key then
			t.leftTimes = leftTimes

			self:refreshInfo(force)
		end
	end
end

function AidInfo:onShowSpec(isShow)
	if not self:isShowAid() then
		return
	end

	self.lAid:setVisible(isShow and self.aidVisible[1])
	self.rAid:setVisible(isShow and self.aidVisible[2])
end

function AidInfo:onUpdateForceAidTimes(force, times)
	if not self:isShowAid() then
		return
	end

	local aid = force == 1 and self.lAid or self.rAid
	local points = aid:get("aidPoint")

	changePoint(points, times, self.aidTimesLimit)
end

function AidInfo:onWaveAddCardRoles(force)
	if not self:isShowAid() then
		return
	end

	if self.aidVisible[force] then
		local aidObjLimit = self.aidObjLimit[force]

		for i = 1, aidObjLimit do
			if not self.skillModel[force][i] then
				self.skillModel[force][i] = {
					timesLimit = 3,
					leftTimes = 3,
					key = "temp" .. i
				}
			end
		end

		self:initSkillNodes(force, aidObjLimit)
	end

	local lSwitch, rSwitch = false, false

	self.lAid:get("img"):onClick(function()
		lSwitch = not lSwitch

		self:refreshInfo(1, lSwitch)
	end)
	self.rAid:get("img"):onClick(function()
		rSwitch = not rSwitch

		self:refreshInfo(2, rSwitch)
	end)
end

function AidInfo:isShowAid()
	return self.isShow
end

return AidInfo
