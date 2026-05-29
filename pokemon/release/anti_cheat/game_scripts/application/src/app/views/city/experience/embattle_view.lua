-- chunkname: @src.app.views.city.experience.embattle_view1

local ViewBase = cc.load("mvc").ViewBase
local CardEmbattleView = require("app.views.city.card.embattle.base")
local embattleView = class("embattleView", CardEmbattleView)
local PANEL_NUM = 6

embattleView.RESOURCE_FILENAME = "experience_embattle.json"
embattleView.RESOURCE_BINDING = {
	textLimit = "textLimit",
	bottomPanel = "bottomPanel",
	bottomMask = "bottomMask",
	spritePanel = "spriteItem",
	battlePanel = "battlePanel",
	btnGHimg = {
		varname = "btnBuff",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onTeamBuffClick")
			}
		}
	},
	btnWeather = {
		varname = "btnWeather",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onTeamWeatherClick")
			}
		}
	},
	btnChallenge = {
		varname = "btnChallenge",
		binds = {
			clicksafe = true,
			event = "touch",
			methods = {
				ended = bindHelper.self("fightBtn")
			}
		}
	},
	["ahead.txt"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["back.txt"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["btnChallenge.textNote"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	}
}

function embattleView:onCreate(cardID, skinID)
	self.spriteItem:get("attrBg"):hide()
	self.btnBuff:hide()
	gGameUI.topuiManager:createView("title", self, {
		onClose = self:createHandler("onClose", true)
	}):init({
		subTitle = "EXPERIENCE",
		title = gLanguageCsv.testPlay
	})
	adapt.centerWithScreen("left", "right", nil, {
		{
			self.btnChallenge,
			"pos",
			"right"
		}
	})

	local cardID = csv.experience.cards[cardID] and csv.experience.cards[cardID].cardID or cardID

	self.cardData = csv.experience.list[cardID]
	self.cardID = cardID
	self.skinID = skinID

	self:initParams()
	self:initModel()
	self:updateData()
	self:initSpriteItem()
	self:initBottomList()
	idlereasy.when(self.clientBattleCards, function(_, battle)
		self:refreshTeamWeather(battle)

		for index = 1, PANEL_NUM do
			self:initHeroSprite(index)
		end
	end)
	idlereasy.when(self.draggingIndex, function(_, index)
		for i = 1, PANEL_NUM do
			local sprite = self.heroSprite[i].item:get("sprite")

			if sprite then
				sprite:setCascadeOpacityEnabled(true)

				if index == 0 then
					sprite:opacity(255)
				elseif index == -1 then
					sprite:opacity(155)
				elseif index == i then
					sprite:opacity(255)
				else
					sprite:opacity(155)
				end
			end
		end
	end)
	idlereasy.when(self.selectIndex, function(_, selectIndex)
		for i = 1, PANEL_NUM do
			local imgSel = self.heroSprite[i].item:get("imgBg.imgSel")

			imgSel:visible(selectIndex == i)
		end
	end)
	idlereasy.when(self.selectWeatherID, function(_, selectWeatherID)
		if not selectWeatherID or selectWeatherID == 0 then
			self.btnWeather:hide()

			return
		end

		self.btnWeather:show()
		self.btnWeather:get("icon"):texture(csv.weather_system.weather[selectWeatherID].iconRes)
	end)
end

function embattleView:initParams()
	self.aidNum = 0
	self.aidCards = idlertable.new({})
	self.originAidCards = idlertable.new({})
end

function embattleView:updateData()
	local cardDatas = table.deepcopy(self.cardData.cards)
	local deployLock = self.cardData.deployLock
	local battleNum = 0

	for _, v in pairs(deployLock) do
		if v == 0 then
			battleNum = battleNum + 1
		end
	end

	self.battleNum = battleNum

	if self.clientBattleCards:size() > 0 then
		return
	end

	local autoCards = self.cardData.autoCards
	local hash = {}
	local tempBattleCardsData = {
		0,
		0,
		0,
		0,
		0,
		0
	}
	local tempClientBattleCards = {
		0,
		0,
		0,
		0,
		0,
		0
	}
	local tempCards = {}

	for id, lockPos in csvPairs(autoCards) do
		if not hash[id] then
			if lockPos == 0 then
				table.insert(tempCards, id)
			elseif deployLock[lockPos] == 1 then
				printError("pos(%s) was lock, cardID(%s)", lockPos, self.cardData.id)
			else
				tempBattleCardsData[lockPos] = id
				tempClientBattleCards[lockPos] = id
			end

			hash[id] = true
		end

		table.insert(cardDatas, id)
	end

	for i = 1, PANEL_NUM do
		if tempBattleCardsData[i] == 0 and deployLock[i] == 0 and tempCards[1] then
			local id = tempCards[1]

			tempBattleCardsData[i] = id
			tempClientBattleCards[i] = id

			table.remove(tempCards, 1)
		end
	end

	local tempAllCardDatas = {}

	for _, csvID in pairs(cardDatas) do
		local csvCard = csv.experience.cards[csvID]
		local cardInfo = csv.cards[csvCard.cardID]
		local unitID = cardInfo.unitID

		if csvCard.cardID == self.cardID and self.skinID then
			unitID = dataEasy.getUnitId(csvCard.cardID, self.skinID)
		end

		local csvUnit = csv.unit[unitID]

		tempAllCardDatas[csvID] = {
			isNew = false,
			csvID = csvID,
			cardID = csvCard.cardID,
			card_id = csvCard.cardID,
			unitID = unitID,
			unit_id = unitID,
			level = csvCard.level,
			star = csvCard.star,
			advance = csvCard.advance,
			rarity = csvUnit.rarity,
			attr1 = csvUnit.natureType,
			attr2 = csvUnit.natureType2,
			markId = cardInfo.cardMarkID,
			atkType = cardInfo.atkType,
			battle = hash[csvID] and 1 or 0,
			lock = autoCards[csvID] or -1
		}
	end

	self.allCardDatas:update(tempAllCardDatas)
	self.clientBattleCards:set(tempClientBattleCards)
	self.battleCardsData:set(tempBattleCardsData)
end

function embattleView:initBottomList(name)
	CardEmbattleView.initBottomList(self, "city.card.embattle.experience_card_list")
end

function embattleView:initModel()
	self.clientBattleCards = idlertable.new(self._clientBattleCards or {})
	self.battleCardsData = idlertable.new(self._battleCardsData or {})
	self.allCardDatas = idlers.newWithMap(self._allCardDatas or {})
	self.selectIndex = idler.new(0)
	self.draggingIndex = idler.new(0)
	self.selectWeatherID = idlereasy.new()
end

function embattleView:initHeroSprite(index)
	local panel = self.heroSprite[index].item
	local data = self:getCardAttrs(self.clientBattleCards:read()[index])

	if not data then
		if panel:getChildByName("sprite") then
			panel:getChildByName("sprite"):hide()
		end

		panel:get("attrBg"):hide()

		return
	end

	local unitID = data.unit_id

	if data.card_id == self.cardID and self.skinID then
		unitID = dataEasy.getUnitId(data.card_id, self.skinID)
	end

	local csvUnit = csv.unit[unitID]
	local imgBg = panel:get("imgBg")

	if panel.csvID == data.csvID and panel:getChildByName("sprite") then
		panel:getChildByName("sprite"):show()
	else
		panel:removeChildByName("sprite")
		panel:removeChildByName("lock")
		panel:removeChildByName("lock1")

		local cardSprite = widget.addAnimationByKey(panel, csvUnit.unitRes, "sprite", "standby_loop", 4):scale(csvUnit.scale * (0.8 + (index - 1) % 3 * 0.1)):xy(imgBg:x(), imgBg:y() + 15)

		cardSprite:setSkin(csvUnit.skin)

		panel.csvID = data.csvID

		if data.lock > 0 then
			self:createLockEffect(panel, index)
		end
	end

	local flags = self.teamBuff and self.teamBuff.flags or {
		1,
		1,
		1,
		1,
		1,
		1
	}
	local flag = flags[index]

	uiEasy.setTeamBuffItem(panel, data.cardID, flag)
end

function embattleView:createLockEffect(parent, index)
	local offsetYTab = {
		-40,
		0,
		5,
		-40,
		0,
		5
	}
	local scaleTab = {
		1.8,
		2,
		2.5,
		1.8,
		2,
		2.5
	}
	local effectName = "effect_hou_loop"
	local effect = widget.addAnimationByKey(parent, "summer_challenge/jld.skel", "lock", effectName, 2)

	effect:scale(scaleTab[index])
	effect:play(effectName)
	effect:xy(parent:width() / 2, parent:height() / 2 + offsetYTab[index])

	effectName = "effect_qian_loop"

	local effect1 = widget.addAnimationByKey(parent, "summer_challenge/jld.skel", "lock1", effectName, 50)

	effect1:scale(scaleTab[index])
	effect1:play(effectName)
	effect1:xy(parent:width() / 2, parent:height() / 2 + offsetYTab[index])
end

function embattleView:initSpriteItem()
	self.heroSprite = {}

	local deployLock = self.cardData.deployLock

	for i = 1, PANEL_NUM do
		local item = self.battlePanel:get("item" .. i)
		local rect = item:box()
		local pos = item:getParent():convertToWorldSpace(cc.p(rect.x, rect.y))

		rect.x, rect.y = pos.x, pos.y
		self.heroSprite[i] = {
			item = item,
			rect = rect,
			idx = i,
			lock = deployLock[i] == 1
		}

		item:get("posLockPanel"):visible(deployLock[i] == 1)
		item:onTouch(functools.partial(self.onBattleCardTouch, self, i))
	end

	for i = 1, PANEL_NUM do
		local imgBg = self.heroSprite[i].item:get("imgBg")
		local imgSel = imgBg:get("imgSel")
		local size = imgBg:size()

		imgSel = imgSel or widget.addAnimationByKey(imgBg, "effect/buzhen2.skel", "imgSel", "effect_loop", 2):xy(size.width / 2, size.height / 2 + 15)
	end
end

function embattleView:createMovePanel(data)
	if self.movePanel then
		self.movePanel:removeSelf()
	end

	local unitID = data.unit_id

	if data.card_id == self.cardID and self.skinID then
		unitID = dataEasy.getUnitId(data.card_id, self.skinID)
	end

	local unitCsv = csv.unit[unitID]
	local movePanel = self.spriteItem:clone():addTo(self:getResourceNode(), 1000)

	movePanel:show()

	local size = movePanel:get("icon"):size()
	local cardSprite = widget.addAnimationByKey(movePanel:get("icon"), unitCsv.unitRes, "hero", "run_loop", 1000):scale(unitCsv.scale):alignCenter(size)

	cardSprite:setSkin(unitCsv.skin)
	widget.addAnimationByKey(movePanel:get("icon"), "effect/buzhen.skel", "effect", "effect_loop", 1002):scale(1):alignCenter(size)

	self.movePanel = movePanel

	self.draggingIndex:set(-1)

	return movePanel
end

function embattleView:deleteMovingItem()
	self.selectIndex:set(0)

	if self.movePanel then
		self.movePanel:removeSelf()

		self.movePanel = nil
	end

	self.draggingIndex:set(0)
end

function embattleView:moveMovePanel(event)
	if self.movePanel then
		self.movePanel:xy(event)
		self.selectIndex:set(self:whichEmbattleTargetPos(event))
	end
end

function embattleView:moveEndMovePanel(data)
	if not self.movePanel then
		return
	end

	local index = self.selectIndex:read()

	self:onCardMove(data, index, true)
	self:deleteMovingItem()
end

function embattleView:isMovePanelExist()
	return self.movePanel ~= nil
end

function embattleView:getBattleIdx()
	for i = 1, PANEL_NUM do
		local id = self.clientBattleCards:read()[i] or 0

		if id == 0 and self.cardData.deployLock[i] == 0 then
			return i
		end
	end
end

function embattleView:onCardClick(data, isShowTip)
	local tip
	local csvID = data.csvID
	local idx = self:getIdxByCsvID(csvID)

	if data.battle > 0 then
		if data.lock >= 0 then
			gGameUI:showTip(gLanguageCsv.testPlayNoDown)

			return
		end

		if self:canBattleDown() then
			self:downBattle(csvID, true)
		else
			tip = gLanguageCsv.battleCannotEmpty
		end
	else
		local idx = self:getBattleIdx()

		if not self:canBattleUp() then
			tip = gLanguageCsv.battleCardCountEnough
		elseif self:hasSameMarkIDCard(data) then
			tip = gLanguageCsv.alreadyHaveSameSprite
		else
			self:upBattle(csvID, idx)
		end
	end

	if isShowTip and tip then
		gGameUI:showTip(tip)
	end
end

function embattleView:canBattleDown()
	return self.clientBattleCards:size() > 1
end

function embattleView:canBattleUp()
	local sum = 0

	for index, data in self.clientBattleCards:pairs() do
		if data > 0 then
			sum = sum + 1
		end
	end

	return sum < self.battleNum
end

function embattleView:onCardMove(data, targetIdx, isShowTip)
	local tip
	local csvID = data.csvID
	local idx = self:getIdxByCsvID(csvID)
	local targetCsvID = self.clientBattleCards:read()[targetIdx]
	local targetData = self:getCardAttrs(targetCsvID)
	local battle = idx == nil and 0 or 1

	if targetIdx then
		if self.cardData.deployLock[targetIdx] == 1 then
			gGameUI:showTip(gLanguageCsv.posLock)

			return
		end

		if data.battle > 0 then
			if targetData and targetData.lock > 0 then
				gGameUI:showTip(gLanguageCsv.testPlayNoMove)

				return
			end

			self.clientBattleCards:modify(function(oldval)
				oldval[idx], oldval[targetIdx] = oldval[targetIdx], oldval[idx]

				return true, oldval
			end, true)
		else
			if targetData and targetData.lock >= 0 then
				gGameUI:showTip(gLanguageCsv.testPlayNoMove)

				return
			end

			local commonIdx = self:hasSameMarkIDCard(data)

			if commonIdx and commonIdx ~= targetIdx then
				tip = gLanguageCsv.alreadyHaveSameSprite
			elseif not targetCsvID and not self:canBattleUp() then
				tip = gLanguageCsv.battleCardCountEnough
			else
				self:upBattle(csvID, targetIdx)

				tip = gLanguageCsv.addToEmbattle
			end
		end
	end

	if isShowTip and tip then
		gGameUI:showTip(tip)
	end
end

function embattleView:onBattleCardTouch(idx, event)
	if self.clientBattleCards:read()[idx] == 0 then
		return
	end

	local data = self:getCardAttrs(self.clientBattleCards:read()[idx])

	if data.lock > 0 then
		gGameUI:showTip(gLanguageCsv.testPlayNoMove)

		return
	end

	if event.name == "began" then
		self:deleteMovingItem()
		self:createMovePanel(data)

		local panel = self.heroSprite[idx].item

		panel:get("sprite"):hide()
		panel:get("attrBg"):hide()
		self:moveMovePanel(event)
	elseif event.name == "moved" then
		self:moveMovePanel(event)
	elseif event.name == "ended" or event.name == "cancelled" then
		local panel = self.heroSprite[idx].item

		panel:get("sprite"):show()
		panel:get("attrBg"):show()
		self:deleteMovingItem()

		if event.y < 340 then
			self:onCardClick(data, true)
		else
			local targetIdx = self:whichEmbattleTargetPos(event)

			if targetIdx then
				if targetIdx ~= idx then
					self:onCardMove(data, targetIdx, true)
					audio.playEffectWithWeekBGM("formation.mp3")
				else
					self:onCardMove(data, targetIdx, false)
				end
			else
				self:onCardMove(data, idx, false)
			end
		end
	end
end

function embattleView:getIdxByCsvID(csvID)
	for i = 1, PANEL_NUM do
		if self.clientBattleCards:read()[i] == csvID then
			return i
		end
	end
end

function embattleView:getCardAttrs(csvID)
	return self.allCardDatas:atproxy(csvID)
end

function embattleView:downBattle(csvID)
	local idx = self:getIdxByCsvID(csvID)

	self.clientBattleCards:modify(function(oldval)
		oldval[idx] = 0

		return true, oldval
	end, true)
end

function embattleView:upBattle(csvID, idx)
	self.clientBattleCards:modify(function(oldval)
		oldval[idx] = csvID
		self:getCardAttrs(csvID).isNew = false

		return true, oldval
	end, true)
end

function embattleView:hasSameMarkIDCard(data)
	for i = 1, PANEL_NUM do
		local csvID = self.clientBattleCards:read()[i]

		if csvID ~= 0 then
			local cardData = self:getCardAttrs(csvID)

			if dataEasy.hasSameMarkIDCard(cardData.card_id, data.card_id) then
				return i
			end
		end
	end

	return false
end

function embattleView:whichEmbattleTargetPos(pos)
	for i = PANEL_NUM, 1, -1 do
		local rect = self.heroSprite[i].rect

		if cc.rectContainsPoint(rect, pos) then
			return i
		end
	end
end

function embattleView:refreshTeamWeather()
	local result = dataEasy.getTeamWeather(nil, true, {
		isTestPlay = true,
		cardsData = self:getBattleCardsInfo()
	})
	local weatherID = dataEasy.getWeatherID(nil, self.selectWeatherID:read(), {
		result = result
	})

	self.selectWeatherID:set(weatherID)
end

function embattleView:getUnitCfg(csvID)
	local csvCards = csv.experience.cards[csvID]
	local unitID = csv.cards[csvCards.cardID].unitID

	return csv.unit[unitID]
end

function embattleView:fightBtn()
	local sign = false

	for index, id in pairs(self.clientBattleCards:read()) do
		if id ~= 0 then
			sign = true

			break
		end
	end

	if not sign then
		gGameUI:showTip(gLanguageCsv.noSpriteAvailable)

		return
	end

	self:startFighting()
end

function embattleView:startFighting()
	local clientBattleCards = {}

	for idx, id in pairs(self.clientBattleCards:read()) do
		if id > 0 then
			clientBattleCards[idx] = id
		end
	end

	local experienceCard = {}

	for _, v in self.allCardDatas:pairs() do
		local data = v:read()

		if data.cardID == self.cardID then
			experienceCard = {
				dbID = data.csvID,
				cardID = self.cardID,
				skinID = self.skinID
			}

			break
		end
	end

	local data = {
		weahter = self.selectWeatherID:read(),
		cards = clientBattleCards,
		experienceCard = experienceCard
	}
	local battle = require("app.models.experience_battle").new(gGameModel):init(data)

	if dataEasy.isSkillChange() then
		local battleData = battle:getData()
		local modes = {
			noShowEndRewards = true
		}
		local record = battleEntrance.battle(battleData, modes)

		record:enter()
	else
		local cards, weathers, passiveSkills = battle:makeNetData()

		local function callBack(ret)
			battle:setActualData(ret)

			local battleData = battle:getData()
			local modes = {
				noShowEndRewards = true
			}
			local record = battleEntrance.battle(battleData, modes)

			record:enter()
		end

		gGameApp:requestServer("/game/battle/card/confuse", callBack, cards, weathers, passiveSkills)
	end
end

function embattleView:onClose()
	ViewBase.onClose(self)
end

function embattleView:getBattleCardsInfo(battleCards)
	local cardsData = {}

	for _, id in pairs(battleCards or self.clientBattleCards:read()) do
		if id > 0 then
			table.insert(cardsData, self:getCardAttrs(id))
		end
	end

	return cardsData
end

function embattleView:onTeamWeatherClick()
	gGameUI:stackUI("city.weather.weather_select", nil, nil, {
		cardsData = dataEasy.getTeamWeather(nil, true, {
			isTestPlay = true,
			cardsData = self:getBattleCardsInfo()
		}),
		weatherID = self.selectWeatherID
	})
end

function embattleView:onCleanup()
	self._clientBattleCards = table.deepcopy(self.clientBattleCards:read(), true)
	self._battleCardsData = table.deepcopy(self.battleCardsData:read(), true)

	local allCardDatas = {}

	for csvID, v in self.allCardDatas:pairs() do
		allCardDatas[csvID] = table.deepcopy(v:read(), true)
	end

	self._allCardDatas = allCardDatas

	ViewBase.onCleanup(self)
end

return embattleView
