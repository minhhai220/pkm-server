-- chunkname: @src.battle.app_views.battle.module.weather

local WeatherInfo = class("WeatherInfo", battleModule.CBase)

function WeatherInfo:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.weatherLayer = self.parent.weatherLayer
	self.weatherInfo = self.parent.UIWidgetMid:get("widgetPanel.weatherInfo")
	self.weatherView = self.parent.UIWidgetMid:get("widgetPanel.topinfo.weather")
	self.widgetPanel = self.parent.UIWidgetMid:get("widgetPanel")
	self.effect = nil
	self.curWeatherId = nil
	self.effects = {}
	self.weatherCfgs = {}
	self.holderIcon = {}
	self.buffLifeRound = {}
	self.originDescsPos = {}
	self.relation = nil
	self.lightRes = "battle/bg_tq1.png"
	self.deepRes = "battle/bg_tq2.png"

	self:init()

	self.originSize = self.weatherView:getContentSize()
end

local nodeChoose = {
	[1] = "wLeft",
	[2] = "wRight"
}

function WeatherInfo:init()
	self.originDescsPos[1] = cc.p(self.weatherView:get(nodeChoose[1]):get("desc"):getPosition())
	self.originDescsPos[2] = cc.p(self.weatherView:get(nodeChoose[2]):get("desc"):getPosition())

	self.weatherView:setVisible(true)
	self:onClearWeatherView(1)
	self:onClearWeatherView(2)
	self.weatherInfo:setVisible(false)
end

function WeatherInfo:setWeatherUIPos(pos, yOffset)
	local localPos = self.weatherView:getParent():convertToNodeSpace(pos)

	localPos.y = localPos.y - self.originSize.height * yOffset

	self.weatherView:setPosition(localPos)
end

function WeatherInfo:registerEvent(force)
	local action = {}
	local weatherViewEvent = {
		[ccui.TouchEventType.began] = function(lOrR)
			action[lOrR] = self.parent:performWithDelay(self.weatherLayer, function()
				action[lOrR] = nil

				self:refreshInfoPanel(true, lOrR)
				self.weatherInfo:setVisible(true)
			end, 0.2)
		end,
		[ccui.TouchEventType.ended] = function(lOrR)
			self.weatherLayer:stopAction(action[lOrR])

			action[lOrR] = nil

			self:refreshInfoPanel(false, lOrR)
			self.weatherInfo:setVisible(false)
		end,
		[ccui.TouchEventType.canceled] = function(lOrR)
			self.weatherLayer:stopAction(action[lOrR])

			action[lOrR] = nil

			self:refreshInfoPanel(false, lOrR)
			self.weatherInfo:setVisible(false)
		end,
		[ccui.TouchEventType.moved] = function(lOrR)
			return
		end
	}

	self.weatherView:get(nodeChoose[force]):addTouchEventListener(function(sender, eventType)
		weatherViewEvent[eventType](force)
	end)
end

function WeatherInfo:refreshInfoPanel(isShow, force)
	local cfg = self.weatherCfgs[force]

	self.weatherInfo:setVisible(isShow)

	if not isShow or not cfg then
		return
	end

	local wNode = nodetools.get(self.weatherView, nodeChoose[force])
	local wNodePosInWorld = wNode:convertToWorldSpace(cc.p(0, 0))
	local posInWidegtPanel = self.widgetPanel:convertToNodeSpace(wNodePosInWorld)

	self.weatherInfo:setAnchorPoint(cc.p(0, 1))
	self.weatherInfo:setPosition(posInWidegtPanel)
	self.weatherInfo:get("name"):setString(cfg.name)

	local name = self.weatherInfo:get("name")

	name:setString(cfg.name)

	local nSize = name:getContentSize()
	local nOriPos = name:convertToWorldSpace(cc.p(0, 0))
	local icon = self.weatherInfo:get("icon")

	icon:loadTexture(self.holderIcon[force])
	icon:scale(0.7)

	local iconSize = icon:getContentSize()
	local iconPos = self.weatherInfo:convertToNodeSpace(cc.p(nOriPos.x + nSize.width + iconSize.width / 2, nOriPos.y + nSize.height / 2))

	icon:setPosition(iconPos)

	local lifeRoundDesc = nodetools.get(self.weatherInfo, "desc")

	lifeRoundDesc:setVisible(true)

	if self.buffLifeRound[force] > 99 then
		lifeRoundDesc:setString(gLanguageCsv.forever)
	elseif self.buffLifeRound[force] == 0 then
		lifeRoundDesc:setVisible(false)
	else
		lifeRoundDesc:setString(string.format(gLanguageCsv.leftRounds, self.buffLifeRound[force]))
	end

	local describe = self.weatherInfo:get("describe")

	describe:removeAllChildren()

	local descSize = describe:getContentSize()
	local richtext = rich.createWithWidth(string.format("#C0x5b545b#%s", cfg.describe), 42, nil, descSize.width)

	richtext:setAnchorPoint(cc.p(0, 1))
	describe:add(richtext)

	local infoBg = self.weatherInfo:get("bg")
	local bgsize = infoBg:getContentSize()
	local textHeight = richtext:getContentSize().height
	local upheight = describe:getPositionY()
	local newHeight = upheight + textHeight + 5

	infoBg:setContentSize(cc.size(bgsize.width, newHeight > self.originSize.height and newHeight or self.originSize.height))
end

function WeatherInfo:initInfoPanel(isShow)
	self.weatherInfo:setVisible(isShow)

	if not isShow or not self.cfg then
		return
	end

	self.weatherInfo:get("name"):setString(self.cfg.name)

	if self.model.lifeRound > 99 then
		nodetools.get(self.weatherInfo, "desc"):setString(gLanguageCsv.forever)
	else
		nodetools.get(self.weatherInfo, "desc"):setString(string.format(gLanguageCsv.leftRounds, self.model.lifeRound))
	end

	local describe = self.weatherInfo:get("describe")

	describe:removeAllChildren()

	local descSize = describe:getContentSize()
	local richtext = rich.createWithWidth(string.format("#C0x5b545b#%s", self.cfg.describe), 42, nil, descSize.width)

	richtext:setAnchorPoint(cc.p(0, 1))
	describe:add(richtext)

	local infoBg = self.weatherInfo:get("bg")
	local bgsize = infoBg:getContentSize()
	local textHeight = richtext:getContentSize().height
	local upheight = describe:getPositionY()
	local newHeight = upheight + textHeight + 5

	infoBg:setContentSize(cc.size(bgsize.width, newHeight > self.originSize.height and newHeight or self.originSize.height))
end

function WeatherInfo:onWeatherRefresh(model, buff)
	if not buff.isShow then
		self.weatherView:setVisible(false)

		if self.effect then
			self.effect:play("effect_danchu")
		end

		self.curWeatherId = nil
	else
		self.cfg = csv.weather[buff.weatherCfgId]

		if buff.weatherCfgId ~= self.curWeatherId then
			if self.effect then
				self.effect:play("effect_danchu")
				performWithDelay(self.weatherLayer, function()
					self:onShowWeatherAnimation(self.cfg.effectRes)
				end, 1)
			else
				self:onShowWeatherAnimation(self.cfg.effectRes)
			end
		end

		self.weatherView:get("icon"):loadTexture(self.cfg.iconRes)
		self.weatherView:setVisible(true)

		self.model = buff
		self.curWeatherId = self.model.weatherCfgId

		nodetools.get(self.weatherView, "weatherDesc"):setString(self.cfg and self.cfg.name)

		if self.model.lifeRound > 99 then
			nodetools.get(self.weatherView, "roundDesc"):setString(gLanguageCsv.forever)
		else
			nodetools.get(self.weatherView, "roundDesc"):setString(string.format(gLanguageCsv.leftRounds, self.model.lifeRound))
		end
	end
end

function WeatherInfo:onClearWeatherView(force)
	local curNode = nodetools.get(self.weatherView, nodeChoose[force])

	curNode:addTouchEventListener(function(sender, eventType)
		return
	end)
	curNode:get("icon"):setVisible(false)

	local wDesc = curNode:get("desc")

	wDesc:setString(gLanguageCsv.none)

	local wSize = curNode:getContentSize()
	local descParentCenterPos = cc.p(0.5 * wSize.width, 0.5 * wSize.height)

	wDesc:setPosition(descParentCenterPos)
	curNode:get("bg"):loadTexture(self.lightRes)
	self:dealBg(curNode:get("bg"), false)
	curNode:setVisible(true)
end

function WeatherInfo:onNewBattleRoundTo(args)
	local weathers = args.weathers

	if not weathers[1] and not weathers[2] then
		self.weatherView:setVisible(false)
	else
		self.weatherView:setVisible(true)
	end

	local function setShow(force, curW)
		if curW then
			self.weatherCfgs[force] = curW.cfg
			self.holderIcon[force] = curW.holderIcon
			self.buffLifeRound[force] = curW.lifeRound

			self:refresh(weathers.relation, force)
			self:registerEvent(force)
		else
			self.weatherCfgs[force] = nil
			self.holderIcon[force] = nil
			self.buffLifeRound[force] = nil

			self:onClearWeatherView(force)
		end
	end

	local function setRestrain(force)
		self:onWeatherEffect(weathers[force], force)
		self:onWeatherEffect(false, 3 - force)
		setShow(force, weathers[force])
		setShow(3 - force, weathers[3 - force])
	end

	local relationFunc = {
		[battle.WeatherRelation.coexist] = function()
			for i = 1, 2 do
				self:onWeatherEffect(weathers[i], i)
				setShow(i, weathers[i])
			end
		end,
		[battle.WeatherRelation.inEffectL] = function()
			setRestrain(1)
		end,
		[battle.WeatherRelation.inEffectR] = function()
			setRestrain(2)
		end
	}

	relationFunc[weathers.relation]()

	self.relation = weathers.relation
end

function WeatherInfo:onWeatherEffect(weather, force)
	local function clearEffect()
		if self.effects[force] then
			self.effects[force]:play("effect_danchu")

			self.effects[force] = nil
		end
	end

	if not weather then
		clearEffect()

		return
	end

	local curID = self.weatherCfgs[force] and self.weatherCfgs[force].id

	if self.effects[force] then
		if weather.cfg.id ~= curID then
			clearEffect()
			self:createWeatherEffect(force, weather.cfg.effectRes)
		end
	else
		self:createWeatherEffect(force, weather.cfg.effectRes)
	end
end

function WeatherInfo:dealBg(bg, isDeep)
	if not isDeep then
		bg:loadTexture(self.lightRes)
		bg:setLocalZOrder(100)
	else
		bg:loadTexture(self.deepRes)
		bg:setLocalZOrder(1)
	end
end

function WeatherInfo:refresh(relation, force)
	local curNode = self.weatherView:get(nodeChoose[force])
	local curIcon = curNode:get("icon")
	local curDesc = curNode:get("desc")
	local curBg = curNode:get("bg")

	curIcon:loadTexture(self.weatherCfgs[force].iconRes)
	curIcon:setVisible(true)
	curDesc:setPosition(self.originDescsPos[force])
	curDesc:text(self.weatherCfgs[force].name)

	if force == 1 then
		adapt.setTextAdaptWithSize(curDesc, {
			vertical = "center",
			horizontal = "right",
			size = cc.size(140, 66)
		})
	else
		adapt.setTextAdaptWithSize(curDesc, {
			vertical = "center",
			horizontal = "left",
			size = cc.size(140, 66)
		})
	end

	if relation == battle.WeatherRelation.coexist or relation == force then
		self:dealBg(curBg, true)
	else
		self:dealBg(curBg, false)
	end
end

function WeatherInfo:createWeatherEffect(force, res)
	if self.effects[force] then
		return
	end

	if not res then
		return
	end

	self.effects[force] = newCSpriteWithOption(res)

	self.effects[force]:xy(display.cx, display.cy):scale(2):play("effect_danru")
	self.parent:performWithDelay(self.effects[force], function()
		if self.effects[force] then
			self.effects[force]:play("effect_loop")
		end
	end, 3)
	self.weatherLayer:add(self.effects[force], 9999)
end

function WeatherInfo:onShowWeatherAnimation(res)
	if self.effect then
		self.effect:removeFromParent()
	end

	if not res then
		return
	end

	self.effect = newCSpriteWithOption(res)

	self.effect:xy(display.cx, display.cy):scale(2):play("effect_danru")
	self.parent:performWithDelay(self.effect, function()
		self.effect:play("effect_loop")
	end, 1)
	self.weatherLayer:add(self.effect, 9999)
end

return WeatherInfo
