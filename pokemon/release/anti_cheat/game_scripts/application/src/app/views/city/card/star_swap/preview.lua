-- chunkname: @src.app.views.city.card.star_swap.preview

local StarTools = require("app.views.city.card.star_swap.tools")
local zawakeTools = require("app.views.city.zawake.tools")
local ViewBase = cc.load("mvc").ViewBase
local StarSwapPreviewView = class("StarSwapPreviewView", ViewBase)
local armTools = require("app.views.city.develop.arm.tools")

StarSwapPreviewView.RESOURCE_FILENAME = "confirm_preview.json"
StarSwapPreviewView.RESOURCE_BINDING = {
	["bottomPanel.costList"] = "costList",
	bottomPanel = "bottomPanel",
	["centerPanel.rightIcon"] = "rightIcon",
	["centerPanel.leftIcon"] = "leftIcon",
	["centerPanel.item"] = "item",
	["centerPanel.starItem"] = "starItem",
	bottomNoUse = "bottomNoUse",
	["centerPanel.subList"] = "subList",
	closeBtn = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	},
	["centerPanel.leftStarList"] = {
		varname = "leftStarList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 6,
				data = bindHelper.self("starLeftDatas"),
				item = bindHelper.self("starItem"),
				onItem = function(list, node, k, v)
					node:get("img"):texture(v.icon)
				end
			}
		}
	},
	["centerPanel.rightStarList"] = {
		varname = "rightStarList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 6,
				data = bindHelper.self("starRightDatas"),
				item = bindHelper.self("starItem"),
				onItem = function(list, node, k, v)
					node:get("img"):texture(v.icon)
				end
			}
		}
	},
	["centerPanel.descList"] = {
		varname = "descList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				columnSize = 2,
				asyncPreload = 6,
				data = bindHelper.self("descData"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				itemAction = {
					isAction = true
				},
				onCell = function(list, node, k, v)
					local nodeHeight = node:height()
					local childs = node:multiget("title", "list")
					local originalTextHeight = childs.list:height()

					childs.title:text(v.title)

					local descList, itemHeight = beauty.textScroll({
						isRich = true,
						fontSize = 44,
						list = childs.list,
						strs = v.str
					})

					if originalTextHeight < itemHeight then
						local deltaHeight = itemHeight - originalTextHeight

						childs.title:y(childs.title:y() + deltaHeight)
						descList:height(itemHeight)
						node:height(nodeHeight + deltaHeight)
						list:height(math.max(node:height(), list:height()))
					end
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
				isShowStage = bindHelper.self("isShowStage")
			}
		}
	},
	confirmBtn = {
		varname = "confirmBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onConfirm")
			}
		}
	},
	["bottomPanel.text"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c4b(66, 61, 66, 255)
				}
			}
		}
	},
	["confirmBtn.text"] = {
		varname = "confirmText",
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["topPanel.title"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c4b(215, 124, 35, 255)
				}
			}
		}
	},
	["topPanel.tip"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c4b(66, 61, 66, 255)
				}
			}
		}
	}
}

function StarSwapPreviewView:onCreate(params)
	self.leftDbId = params.leftDbId
	self.rightDbId = params.rightDbId
	self.onShowCost = params.onShowCost
	self.onExchangeSuccess = params.onExchangeSuccess
	self.onShowAidSuccessAnim = params.onShowAidSuccessAnim
	self.type = params.type
	self.seatId = params.seatId
	self.starLeftDatas = idlertable.new({})
	self.starRightDatas = idlertable.new({})
	self.descData = idlers.new()

	self:addTime()
	self:cardStarChanged()
	self:updateIcon()
	self:refreshButtom()
	self:showText()
end

function StarSwapPreviewView:onConfirm()
	if self.isChillDown then
		gGameUI:showTip(gLanguageCsv.starPreviewWait)

		return
	end

	local leftDbId = self.leftDbId
	local rightDbId = self.rightDbId
	local seatId = self.seatId

	if self.isEnough == false and not self.isNoUse then
		local str = string.format("%s %s", table.concat(self.costTip, ","), gLanguageCsv.townCostNotEnough)

		gGameUI:showTip(str)

		return
	end

	local leftCard = gGameModel.cards:find(leftDbId)
	local leftCardParam = leftCard:read("card_id", "name", "advance")
	local rightCard = gGameModel.cards:find(rightDbId)
	local rightCardParam = rightCard:read("card_id", "name", "advance")
	local leftNameText = uiEasy.setIconName("card", leftCard:read("card_id"), {
		space = true,
		noColor = true,
		name = leftCardParam.name,
		advance = leftCardParam.advance
	})
	local rightNameText = uiEasy.setIconName("card", rightCard:read("card_id"), {
		space = true,
		noColor = true,
		name = rightCardParam.name,
		advance = rightCardParam.advance
	})

	if self.type == 1 then
		local cdCfg = string.format(gLanguageCsv.hour, csv.card_star_swap_field[seatId].chillDown)

		gGameUI:showDialog({
			isRich = true,
			btnType = 2,
			cb = function()
				gGameApp:requestServer("/game/card/star/swap", function(tb)
					gGameUI:showTip(gLanguageCsv.starAidSuccess)
					self:addCallbackOnExit(functools.partial(self.onShowAidSuccessAnim))
					self:onClose()
				end, seatId, leftDbId, rightDbId, "on")
			end,
			content = string.format(gLanguageCsv.confirmAid, leftNameText, rightNameText, cdCfg),
			dialogParams = {
				clickClose = false
			}
		})
	elseif self.type == 2 then
		local onExchangeSuccess = self.onExchangeSuccess
		local cardCsv = csv.cards[leftCardParam.card_id]
		local rarity = csv.unit[cardCsv.unitID].rarity
		local txt = string.format(gLanguageCsv.confirmExchange, leftNameText, rightNameText)

		if rarity == 3 and dataEasy.getNumByKey(StarTools.SNOUSEPROPKEY) > 0 or rarity == 4 and dataEasy.getNumByKey(StarTools.SPLUSNOUSEPROPKEY) > 0 then
			local key = rarity == 3 and StarTools.SNOUSEPROPKEY or StarTools.SPLUSNOUSEPROPKEY

			txt = txt .. "\n" .. string.format(gLanguageCsv.starSwapNoUse, dataEasy.getCfgByKey(key).name)
		end

		gGameUI:showDialog({
			isRich = true,
			btnType = 2,
			cb = function()
				gGameApp:requestServer("/game/card/star/swap", function(tb)
					self:addCallbackOnExit(function()
						onExchangeSuccess()
						gGameUI:stackUI("city.card.star_swap.swap_over", nil, nil, {
							leftDbId = leftDbId,
							rightDbId = rightDbId
						})
					end)
					self:onClose()
				end, 0, leftDbId, rightDbId)
			end,
			content = txt,
			dialogParams = {
				clickClose = false
			}
		})
	end
end

function StarSwapPreviewView:addTime()
	local diffTime = 1
	local endTime = time.getTime() + diffTime
	local text = self.type == 1 and gLanguageCsv.starAid or gLanguageCsv.starExchange

	uiEasy.setBtnShader(self.confirmBtn, self.confirmText, 3)

	self.isChillDown = true

	self:enableSchedule():schedule(function()
		local nowTime = time.getTime()

		if nowTime == endTime then
			self:unScheduleAll()

			self.isChillDown = false

			uiEasy.setBtnShader(self.confirmBtn, self.confirmText, 1)
			self.confirmText:text(string.format(text, " "))
		else
			self.confirmText:text(string.format(text, "") .. gLanguageCsv.symbolBracketLeft .. endTime - nowTime .. gLanguageCsv.symbolBracketRight)
		end
	end, 1, 0, "PreView")
end

function StarSwapPreviewView:updateCostList()
	local card = gGameModel.cards:find(self.leftDbId)
	local cardCsv = csv.cards[card:read("card_id")]
	local rarity = csv.unit[cardCsv.unitID].rarity
	local leftStar = gGameModel.cards:find(self.leftDbId):read("star")
	local rightStar = gGameModel.cards:find(self.rightDbId):read("star")
	local award, isEnough, costTip = StarTools.getCostList(self.type, rarity, math.max(leftStar, rightStar))

	self.isEnough = isEnough
	self.costTip = costTip

	uiEasy.createItemsToList(self, self.costList, award, {
		scale = 0.8
	})
end

function StarSwapPreviewView:refreshButtom()
	local card = gGameModel.cards:find(self.leftDbId)
	local cardCsv = csv.cards[card:read("card_id")]
	local rarity = csv.unit[cardCsv.unitID].rarity

	if self.type == 2 and (rarity == 3 and dataEasy.getNumByKey(StarTools.SNOUSEPROPKEY) > 0 or rarity == 4 and dataEasy.getNumByKey(StarTools.SPLUSNOUSEPROPKEY) > 0) then
		self.bottomNoUse:show()

		self.isNoUse = true
	end

	self.bottomPanel:show()
	self:updateCostList()
end

function StarSwapPreviewView:cardStarChanged()
	local leftStar = gGameModel.cards:find(self.leftDbId):read("star")
	local rightStar = gGameModel.cards:find(self.rightDbId):read("star")
	local data = {
		self.starRightDatas,
		self.starLeftDatas
	}

	for i, v in ipairs({
		leftStar,
		rightStar
	}) do
		data[i]:set(StarTools.getStarData(v))
	end
end

function StarSwapPreviewView:showText()
	local textTable = {
		self.getStarText,
		self.getHomeText
	}
	local unlockKey = {
		{
			key = "zawake",
			func = self.getZawakeText
		},
		{
			key = "meteorite",
			func = self.getMeteoritesText
		},
		{
			key = "badge",
			func = self.getBadgeText
		},
		-- {
			-- key = "arms",--纹章暂不开开放
			-- func = self.getArmText
		-- },
		{
			key = "aid",
			func = self.getAidText
		}
	}

	for _, v in ipairs(unlockKey) do
		if dataEasy.isUnlock(gUnlockCsv[v.key]) then
			table.insert(textTable, v.func)
		end
	end

	local descData = {}

	for k, f in ipairs(textTable) do
		for i = 1, 2 do
			local title, str = f(self, i)

			title = dataEasy.deleteStrFormat(title, "#([F][^#]+)#")
			title = dataEasy.deleteStrFormat(title, "#([C][^#]+)#")
			title = dataEasy.deleteStrFormat(title, "\n")
			str = dataEasy.deleteStrFormat(str, "#([F][^#]+)#")
			str = dataEasy.deleteStrFormat(str, "\n")

			table.insert(descData, {
				title = title,
				str = str
			})
		end
	end

	self.descData:update(descData)
end

function StarSwapPreviewView:getStarText(index)
	local leftCard = gGameModel.cards:find(self.leftDbId)
	local rightCard = gGameModel.cards:find(self.rightDbId)
	local leftStar = leftCard:read("star")
	local rightStar = rightCard:read("star")
	local changeStar = index == 2 and leftStar or rightStar
	local star = index == 1 and leftStar or rightStar
	local text = {
		noEffect = gLanguageCsv.starNoEffect,
		starAdditionText = gLanguageCsv.starAddition,
		starAdditionMore = gLanguageCsv.starAddition1,
		starAdditionMoreLimit = gLanguageCsv.starAddition2,
		starAdditionMoreLimit1 = gLanguageCsv.starAddition3,
		starAdditionLess = gLanguageCsv.starAddition4
	}
	local str = ""

	if changeStar == 12 then
		if self.type == 1 then
			str = str .. text.starAdditionMoreLimit
		else
			str = str .. text.starAdditionMoreLimit1
		end
	elseif star < changeStar then
		str = str .. text.starAdditionMore
	elseif changeStar < star then
		str = str .. string.format(text.starAdditionLess, changeStar)
	else
		str = str .. text.noEffect
	end

	local title = text.starAdditionText

	return title, str
end

function StarSwapPreviewView:getZawakeText(index)
	local leftCard = gGameModel.cards:find(self.leftDbId)
	local rightCard = gGameModel.cards:find(self.rightDbId)
	local cardTb = {
		leftCard,
		rightCard
	}
	local leftCardData = leftCard:read("star", "card_id", "advance")
	local rightCardData = rightCard:read("star", "card_id", "advance")
	local changeCardStar = index == 2 and leftCardData.star or rightCardData.star
	local curCardStar = index == 1 and leftCardData.star or rightCardData.star

	local function getZawakeID(card)
		local cardId = card:read("card_id")
		local zawakeID = csv.cards[cardId].zawakeID

		if zawakeTools.isOpenByStage(zawakeID) then
			return zawakeID
		end

		return 0
	end

	local curState = 0

	for k = 1, zawakeTools.MAXSTAGE do
		local zawakeId = getZawakeID(cardTb[index])

		if zawakeId == 0 then
			break
		end

		local stageCfg = zawakeTools.getStagesCfg(zawakeId, k)
		local needStar = stageCfg.unlockLimit1.star

		if needStar then
			if curCardStar < needStar then
				break
			else
				curState = k
			end
		end
	end

	local changeState = 0

	for k = 1, zawakeTools.MAXSTAGE do
		local zawakeId = getZawakeID(cardTb[index])

		if zawakeId == 0 then
			break
		end

		local stageCfg = zawakeTools.getStagesCfg(zawakeId, k)
		local needStar = stageCfg.unlockLimit1.star

		if needStar then
			if changeCardStar < needStar then
				break
			else
				changeState = k
			end
		end
	end

	local text = {
		noEffect = gLanguageCsv.starNoEffect,
		starZawake = gLanguageCsv.starZawake,
		starZawake1 = gLanguageCsv.starZawake1,
		starZawake2 = gLanguageCsv.starZawake2
	}
	local str = ""
	local zawakeID1 = getZawakeID(cardTb[1])
	local zawakeID2 = getZawakeID(cardTb[2])

	if curState == 0 and changeState == 0 or curState == changeState or zawakeID1 == zawakeID2 then
		str = str .. text.noEffect
	elseif curState < changeState then
		str = str .. string.format(text.starZawake1, gLanguageCsv["symbolRome" .. changeState] or changeState)
	elseif changeState < curState then
		str = str .. string.format(text.starZawake2, gLanguageCsv["symbolRome" .. changeState] or changeState)
	end

	local title = text.starZawake

	return title, str
end

function StarSwapPreviewView:getHomeText(index)
	local leftCard = gGameModel.cards:find(self.leftDbId)
	local rightCard = gGameModel.cards:find(self.rightDbId)
	local leftCardData = leftCard:read("star", "card_id", "advance")
	local rightCardData = rightCard:read("star", "card_id", "advance")
	local cardTb = {
		leftCardData,
		rightCardData
	}
	local changeCardStar = index == 2 and leftCardData.star or rightCardData.star
	local curCardStar = index == 1 and leftCardData.star or rightCardData.star
	local changeEnergyMax, changeSkillName
	local changeCsvData = csv.cards[cardTb[index].card_id]

	for k, v in orderCsvPairs(csv.town.skill) do
		if v.skill == changeCsvData.townSkill and cardTb[index].advance >= v.needAdvance and changeCardStar >= v.needStar then
			if v.level == 0 then
				break
			end

			changeSkillName = v.name .. gLanguageCsv["symbolRome" .. v.level]
			changeEnergyMax = math.floor(townDataEasy.getCardEnergy(cardTb[index].card_id, cardTb[index].advance, changeCardStar))

			break
		end
	end

	local curEnergyMax = gLanguageCsv.notUnlock
	local curSkillName = gLanguageCsv.notUnlock

	for k, v in orderCsvPairs(csv.town.skill) do
		if v.skill == csv.cards[cardTb[index].card_id].townSkill and cardTb[index].advance >= v.needAdvance and curCardStar >= v.needStar then
			if v.level == 0 then
				break
			end

			curSkillName = v.name .. gLanguageCsv["symbolRome" .. v.level]
			curEnergyMax = math.floor(townDataEasy.getCardEnergy(cardTb[index].card_id, cardTb[index].advance, curCardStar))

			break
		end
	end

	local text = {
		homeSkillText = gLanguageCsv.starHomeTown,
		homeEnergy = gLanguageCsv.starHomeTown1,
		homeSkill = gLanguageCsv.starHomeTown2,
		homeEnergyAndSkill = gLanguageCsv.starHomeTown3,
		homeNotEnergyAndSkill = gLanguageCsv.starHomeTown4
	}
	local str = ""

	if changeEnergyMax and changeSkillName then
		if changeEnergyMax ~= curEnergyMax and curSkillName ~= changeSkillName then
			str = str .. string.format(text.homeEnergyAndSkill, curSkillName, changeSkillName, curEnergyMax, changeEnergyMax)
		elseif changeEnergyMax ~= curEnergyMax then
			str = str .. string.format(text.homeEnergy, curEnergyMax, changeEnergyMax)
		elseif curSkillName ~= changeSkillName then
			str = str .. string.format(text.homeSkill, curSkillName, changeSkillName)
		end
	else
		str = str .. text.homeNotEnergyAndSkill
	end

	local title = text.homeSkillText

	return title, str
end

function StarSwapPreviewView:getMeteoritesText(index)
	local dbIdTb = {
		self.leftDbId,
		self.rightDbId
	}
	local leftCard = gGameModel.cards:find(self.leftDbId)
	local rightCard = gGameModel.cards:find(self.rightDbId)
	local cardTb = {
		leftCard,
		rightCard
	}
	local leftCardData = leftCard:read("star", "card_id", "advance")
	local rightCardData = rightCard:read("star", "card_id", "advance")
	local changeCardStar = index == 2 and leftCardData.star or rightCardData.star
	local curCardStar = index == 1 and leftCardData.star or rightCardData.star
	local text = {
		noEffect = gLanguageCsv.starNoEffect,
		starMeteorite = gLanguageCsv.starMeteorite,
		starMeteorite1 = gLanguageCsv.starMeteorite1
	}
	local meteorites = gGameModel.role:read("meteorites") or {}
	local isMeteorites = false

	for _, v in pairs(meteorites) do
		if dbIdTb[index] == v.card then
			isMeteorites = true

			break
		end
	end

	if not isMeteorites then
		return text.starMeteorite, text.noEffect
	end

	local cardCsv = csv.cards[cardTb[index]:read("card_id")]
	local unitCsv = csv.unit[cardCsv.unitID]
	local cardscfg = csv.meteorite.guard_effect[unitCsv.rarity]
	local curStarNum = cardscfg.starAttrs[curCardStar]
	local changeStarNum = cardscfg.starAttrs[changeCardStar]
	local str = ""

	if curStarNum == changeStarNum then
		str = str .. text.noEffect
	else
		str = str .. string.format(text.starMeteorite1, curStarNum, changeStarNum)
	end

	local title = text.starMeteorite

	return title, str
end

function StarSwapPreviewView:getBadgeText(index)
	local leftCard = gGameModel.cards:find(self.leftDbId)
	local rightCard = gGameModel.cards:find(self.rightDbId)
	local cardTb = {
		leftCard,
		rightCard
	}
	local leftCardData = leftCard:read("star", "card_id", "advance")
	local rightCardData = rightCard:read("star", "card_id", "advance")
	local changeCardStar = index == 2 and leftCardData.star or rightCardData.star
	local curCardStar = index == 1 and leftCardData.star or rightCardData.star
	local text = {
		noEffect = gLanguageCsv.starNoEffect,
		starBadge = gLanguageCsv.starBadge,
		starBadge1 = gLanguageCsv.starBadge1
	}
	local badge = cardTb[index]:read("badge_guard")[1]

	if not badge then
		return text.starBadge, text.noEffect
	end

	local curStarNum, changeStarNum
	local cardCsv = csv.cards[cardTb[index]:read("card_id")]
	local unitCsv = csv.unit[cardCsv.unitID]

	for k, v in orderCsvPairs(csv.gym_badge.guard_effect) do
		if k == unitCsv.rarity then
			curStarNum = v.starAttrs[curCardStar]
			changeStarNum = v.starAttrs[changeCardStar]
		end
	end

	local str = ""

	if curStarNum == changeStarNum then
		str = str .. text.noEffect
	else
		str = str .. string.format(text.starBadge1, curStarNum, changeStarNum)
	end

	local title = text.starBadge

	return title, str
end

function StarSwapPreviewView:getArmText(index)
	local leftCard = gGameModel.cards:find(self.leftDbId)
	local rightCard = gGameModel.cards:find(self.rightDbId)
	local cardTb = {
		leftCard,
		rightCard
	}
	local cardDbidTb = {
		self.leftDbId,
		self.rightDbId
	}
	local leftCardData = leftCard:read("star", "card_id", "advance")
	local rightCardData = rightCard:read("star", "card_id", "advance")
	local changeCardStar = index == 2 and leftCardData.star or rightCardData.star
	local curCardStar = index == 1 and leftCardData.star or rightCardData.star
	local text = {
		noEffect = gLanguageCsv.starNoEffect,
		starArm = gLanguageCsv.armsAddition,
		starArm1 = gLanguageCsv.armsAddition1
	}
	local armMarkIDs = gGameModel.role:read("arms")
	local armStage = gGameModel.role:read("arms_stage")
	local card = cardTb[index]
	local markID

	if card then
		local cardDatas = card:read("card_id", "skin_id", "fighting_point", "level", "star", "advance")

		markID = csv.cards[cardDatas.card_id].cardMarkID
	end

	local armID = armTools.getSpriteArm(markID)

	if not armID then
		return text.starArm, text.noEffect
	end

	local cards = {}
	local _, cardHash, sameMarkIDCardDatas = armTools.getArmAllCards(armID)

	sameMarkIDCardDatas = sameMarkIDCardDatas[markID] or {}

	for _, markId in pairs(armMarkIDs[armID] or {}) do
		if cardHash[markId] then
			if cardHash[markId].dbid == cardDbidTb[index] then
				local tbSize = itertools.size(sameMarkIDCardDatas)

				if tbSize == 1 then
					sameMarkIDCardDatas[1].star = changeCardStar

					table.insert(cards, sameMarkIDCardDatas[1])
				elseif tbSize > 1 then
					local maxStar = changeCardStar
					local t = {}

					for _, v in ipairs(sameMarkIDCardDatas) do
						if maxStar < v.star then
							if v.dbid ~= cardDbidTb[index] then
								table.insert(t, v)
							else
								v.star = changeCardStar

								table.insert(t, v)
							end
						end
					end

					table.sort(t, armTools.sortCmp)
					table.insert(cards, t[1])
				end
			else
				table.insert(cards, cardHash[markId])
			end
		end
	end

	local stage = armStage[armID] or 0
	local changeStage = armTools.getNowStageByArmSprites(armID, cards)
	local str = ""

	if stage ~= changeStage then
		str = str .. string.format(text.starArm1, gLanguageCsv[game.NATURE_TABLE[armID]], stage, changeStage)
	else
		str = str .. text.noEffect
	end

	local title = text.starArm

	return title, str
end

function StarSwapPreviewView:getAidText(index)
	local leftCard = gGameModel.cards:find(self.leftDbId)
	local rightCard = gGameModel.cards:find(self.rightDbId)
	local cardTb = {
		leftCard,
		rightCard
	}
	local cardDbidTb = {
		self.leftDbId,
		self.rightDbId
	}
	local leftCardData = leftCard:read("star", "card_id")
	local rightCardData = rightCard:read("star", "card_id")
	local changeCardStar = index == 2 and leftCardData.star or rightCardData.star
	local text = {
		noEffect = gLanguageCsv.starNoEffect,
		starAid = gLanguageCsv.starAidTitle,
		starAidActive = gLanguageCsv.starAidDesc1,
		starAidNotActive = gLanguageCsv.starAidDesc2,
		starNotOpenAid = gLanguageCsv.starAidDesc3
	}
	local activeAid = gGameModel.role:read("active_aid")
	local allAid = gGameModel.role:read("aid")
	local cards = gGameModel.role:read("cards")
	local cardID = cardTb[index]:read("card_id")
	local isOpenAid = dataEasy.isOpenAid(cardID)
	local str = ""

	if isOpenAid then
		local cardCfg = csv.cards[cardID]
		local aidID = cardCfg.aidID
		local canActive = true

		if allAid[aidID] then
			for _, dbid in ipairs(cards) do
				local card = gGameModel.cards:find(dbid)
				local cardData = card:read("level", "star", "advance", "card_id")

				if csv.cards[cardData.card_id].aidID == aidID then
					canActive = true

					local star = cardData.star

					if dbid == cardDbidTb[index] then
						star = changeCardStar
					end

					local aidCfg = csv.aid.aid[aidID]
					local t = {
						{
							key = "level",
							cfgNum = aidCfg.activeDemandLevel,
							cardDataNum = cardData.level
						},
						{
							key = "advance",
							cfgNum = aidCfg.activeDemandAdvance,
							cardDataNum = cardData.advance
						},
						{
							key = "star",
							cfgNum = aidCfg.activeDemandStar,
							cardDataNum = star
						}
					}

					for _, v in ipairs(t) do
						if not (v.cfgNum > 0) or v.cfgNum <= v.cardDataNum then
							-- block empty
						else
							canActive = false

							break
						end
					end

					if canActive == true then
						break
					end
				end
			end

			if canActive then
				str = text.noEffect

				if not activeAid[aidID] then
					str = text.starAidActive
				end
			elseif activeAid[aidID] then
				str = text.starAidNotActive
			else
				str = text.noEffect
			end
		else
			str = text.noEffect
		end
	else
		str = text.starNotOpenAid
	end

	local title = text.starAid

	return title, str
end

function StarSwapPreviewView:updateIcon()
	local node = {
		self.leftIcon,
		self.rightIcon
	}

	for i, v in ipairs({
		self.leftDbId,
		self.rightDbId
	}) do
		local card = gGameModel.cards:find(v)
		local cardData = card:read("card_id", "skin_id")
		local unitCsv = dataEasy.getUnitCsv(cardData.card_id, cardData.skin_id)

		node[i]:texture(unitCsv.iconSimple):show()
	end
end

function StarSwapPreviewView:onClose()
	self:addCallbackOnExit(self.onShowCost)
	ViewBase.onClose(self)
end

return StarSwapPreviewView
