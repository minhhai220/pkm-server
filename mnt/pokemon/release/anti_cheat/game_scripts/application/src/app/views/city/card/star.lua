-- chunkname: @src.app.views.city.card.star

local function getAttrName(key)
	if key == game.ATTRDEF_ENUM_TABLE.damage then
		return gLanguageCsv.attrDoubleAttack
	end

	if key == game.ATTRDEF_ENUM_TABLE.defence then
		return gLanguageCsv.attrDoubleDefence
	end

	if key == game.ATTRDEF_ENUM_TABLE.defenceIgnore then
		return gLanguageCsv.attrDoubleDefenceIgnore
	end

	if itertools.include({
		game.ATTRDEF_ENUM_TABLE.specialDamage,
		game.ATTRDEF_ENUM_TABLE.specialDefence,
		game.ATTRDEF_ENUM_TABLE.specialDefenceIgnore
	}, key) then
		return
	end

	return getLanguageAttr(key)
end

local function setCardIcon(list, node, v)
	bind.extend(list, node, {
		class = "card_icon",
		props = {
			unitId = v.unitId,
			advance = v.advance,
			rarity = v.rarity,
			star = v.star,
			levelProps = {
				data = v.level
			},
			params = {
				starScale = 0.9520000000000001,
				starInterval = 14.560000000000002
			},
			onNode = function(panel)
				panel:get("star"):y(-40)
			end
		}
	})
end

local function setItemIcon(list, node, v)
	bind.extend(list, node, {
		class = "icon_key",
		props = {
			data = {
				key = v.key,
				num = v.num
			},
			onNode = function(panel)
				panel:setTouchEnabled(false):scale(0.9)
			end
		}
	})
end

local function setStarIcon(parent, star)
	parent:removeAllChildren()

	local interval = 15
	local starNum = star > 6 and 6 or star

	for i = 1, starNum do
		local starIdx = star - 6
		local icon = "common/icon/icon_star_d.png"

		if i <= star then
			icon = i <= starIdx and "common/icon/icon_star_z.png" or "common/icon/icon_star.png"
		end

		ccui.ImageView:create(icon):xy(99 - interval * (starNum + 1 - 2 * i), -20):addTo(parent, 4, "star"):scale(0.35)
	end
end

local function getBattleCards()
	local battleCards = {}
	local mainBattCards = gGameModel.role:read("battle_cards")

	for k, v in pairs(mainBattCards) do
		table.insert(battleCards, v)
	end

	local cardDeployment = gGameModel.role:read("card_embattle")
	local arena = cardDeployment.arena

	for k, v in pairs(arena.defence_cards or {}) do
		table.insert(battleCards, v)
	end

	return battleCards
end

local function getCostEp(skillLevel, costID, fastUpgradeNum)
	local costEp = 0

	fastUpgradeNum = fastUpgradeNum or 1

	for i = 1, fastUpgradeNum do
		if csv.base_attribute.skill_level[skillLevel + i - 1] then
			costEp = costEp + csv.base_attribute.skill_level[skillLevel + i - 1]["itemNum" .. costID]
		end
	end

	return costEp
end

local RebirthTools = require("app.views.city.card.rebirth.tools")
local CardStarView = class("CardStarView", cc.load("mvc").ViewBase)

CardStarView.RESOURCE_FILENAME = "card_star.json"
CardStarView.RESOURCE_BINDING = {
	["panel.costInfo.textCostNum"] = "needGoldTxt",
	["panel.costInfo.imgIcon"] = "costIcon",
	item = "item",
	["selectPanel.subList"] = "subList",
	cardItem = "cardItem",
	["extremePanel.item"] = "extremeItem",
	["selectPanel.bg.bgIcon"] = "bgIcon",
	["extremePanel.subList"] = "extremeSubList",
	["selectPanel.empty.text"] = "txtEmpty",
	["panel.costInfo.textCostNote"] = "costTxt",
	["panel.costInfo"] = "costInfo",
	["selectPanel.textNum"] = "textNum",
	effectItem = "effectItem",
	panel = "panel",
	["selectPanel.progressBar2"] = {
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				maskImg = "common/icon/mask_bar_red.png",
				data = bindHelper.self("chipBarPercent")
			}
		}
	},
	["selectPanel.textHasNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("chipNum")
		}
	},
	["selectPanel.textNeedNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("chipNeed")
		}
	},
	["selectPanel.btnFrags"] = {
		varname = "btnFrags",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onChangeClick")
			}
		}
	},
	["selectPanel.btnFrags.textNote"] = {
		binds = {
			event = "effect",
			data = {
				color = ui.COLORS.NORMAL.WHITE,
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["selectPanel.btnAdd"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onGainWayClick")
			}
		}
	},
	selectPanel = {
		varname = "selectPanel",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("selectPanelState")
			},
			{
				event = "click",
				method = bindHelper.self("onSelectPanelClick")
			}
		}
	},
	["selectPanel.btnCombine"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onCombClick")
			}
		}
	},
	["selectPanel.btnCombine.textNote"] = {
		binds = {
			event = "effect",
			data = {
				color = ui.COLORS.NORMAL.WHITE,
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["selectPanel.btnSure"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onSureClick")
			}
		}
	},
	["selectPanel.btnSure.textNote"] = {
		binds = {
			event = "effect",
			data = {
				color = ui.COLORS.NORMAL.WHITE,
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["selectPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				asyncPreload = 8,
				columnSize = 2,
				data = bindHelper.self("cardInfos"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("cardItem"),
				onCell = function(list, node, k, v)
					local t = list:getIdx(k)

					node:name("item" .. t.k)
					bind.extend(list, node:get("iconPanel"), {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							rarity = v.rarity,
							star = v.star,
							dbid = v.dbid,
							levelProps = {
								data = v.level
							},
							params = {
								starScale = 0.88,
								starInterval = 14
							}
						}
					})
					uiEasy.setIconName("card", v.id, {
						space = true,
						node = node:get("textName"),
						name = v.name,
						advance = v.advance
					})
					adapt.setTextScaleWithWidth(node:get("textName"), nil, 300)
					node:get("textFight"):text(v.fight)
					node:get("iconLock"):visible(v.locked)
					node:get("textPanel"):visible(v.battleType ~= nil)

					if v.battleType and ui.CARD_USING_TXTS[v.battleType] then
						local txt = node:get("textPanel"):get("text")

						txt:text(gLanguageCsv[ui.CARD_USING_TXTS[v.battleType]])
						node:get("textPanel"):get("bg"):size(txt:size().width + 50, 60)
					end

					adapt.oneLinePos(node:get("textFightNote"), node:get("textFight"))
					node:get("mask"):visible(v.status ~= 0)
					node:get("iconSelect"):visible(v.selectState == true)
					node:setTouchEnabled(v.status == 0)

					if v.canSelect == true and v.selectState == false then
						node:setTouchEnabled(false)
						node:get("mask"):show()
					end

					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.itemClick, list:getIdx(k), v)
						}
					})
				end
			},
			handlers = {
				itemClick = bindHelper.self("onCardItemClick")
			}
		}
	},
	extremePanel = {
		varname = "extremePanel",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("extremePanelState")
			},
			{
				event = "click",
				method = bindHelper.self("closeExtreme")
			}
		}
	},
	["extremePanel.imgBg.textExtremePoint"] = {
		varname = "textExtremePoint",
		binds = {
			event = "text",
			idler = bindHelper.self("extremePoint")
		}
	},
	["extremePanel.imgBg"] = {
		varname = "btnAddExtrePoint",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onAddExtrePointClick")
			}
		}
	},
	["extremePanel.btnReset"] = {
		varname = "btnResetEp",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onResetEp")
			}
		}
	},
	["extremePanel.textResetEpCost"] = {
		varname = "textResetEpCost",
		binds = {
			event = "text",
			idler = bindHelper.self("resetEpCost")
		}
	},
	["extremePanel.imgBg.imgIcon"] = {
		binds = {
			event = "texture",
			idler = bindHelper.self("starSkillIcon")
		}
	},
	["extremePanel.list"] = {
		varname = "extremeList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				margin = 0,
				asyncPreload = 6,
				columnSize = 2,
				data = bindHelper.self("starSkills"),
				item = bindHelper.self("extremeSubList"),
				cell = bindHelper.self("extremeItem"),
				cardId = bindHelper.self("cardId"),
				onCell = function(list, node, k, v)
					node:get("textLv"):text(v.skillLevel)
					adapt.oneLinePos(node:get("textLv1"), node:get("textLv"), cc.p(3, -5), "left")
					node:removeChildByName("richText")

					local skillCfg = csv.skill[v.skillId]
					local describe = dataEasy.getSkillDesc(skillCfg)
					local desc = string.format("#C0x5b545b#%s", eval.doMixedFormula(describe, {
						skillLevel = v.skillLevel or 1,
						math = math
					}, nil) or "no desc")
					local skillLevel = math.max(v.skillLevel, 1)
					local attrCfg

					for csvID, cfg in orderCsvPairs(csv.card_star_skill_attr) do
						if cfg.skillID == v.skillId and cfg.level == skillLevel then
							attrCfg = cfg

							break
						end
					end

					assert(attrCfg, string.format("csv.card_star_skill_attr not exist skillID(%s), level(%s)", v.skillId, skillLevel))

					local attrT = {}

					for i = 1, math.huge do
						local key = attrCfg["attrType" .. i]

						if not key or key == 0 then
							break
						end

						if getAttrName(key) then
							local val = attrCfg["attrNum" .. i]

							if v.skillLevel == 0 then
								val = string.find(val, "%%") and "0%" or 0
							end

							table.insert(attrT, string.format("#C0x5B545B#%s#C0x5C9970#+%s", getAttrName(key), dataEasy.getAttrValueString(key, val)))
						end
					end

					local desc = table.concat(attrT, "\n")
					local size = matchLanguage({
						"kr",
						"en"
					}) and 30 or 42
					local skillContent = rich.createWithWidth(desc, size, cc.size(400, 130), 400, 20):anchorPoint(0, 1):xy(60, 220):addTo(node):z(2):name("richText")

					node:get("imgIcon"):texture(v.icon)

					local costId = csv.skill[v.skillId].costID
					local costEp = getCostEp(v.skillLevel, costId)

					node:get("textNum3"):text(costEp)

					local skillMaxLevel = csv.cards[v.cardId].starSkillMaxLevel

					if skillMaxLevel < v.skillLevel + 1 then
						uiEasy.setBtnShader(node:get("btnAdd"), nil, 3)
					end

					if list.isAiding() then
						uiEasy.setBtnShader(node:get("btnAdd"), nil, 2)
					end

					bind.touch(list, node:get("btnAdd"), {
						methods = {
							ended = functools.partial(list.clickAdd, k, v, costEp)
						}
					})
				end
			},
			handlers = {
				clickAdd = bindHelper.self("onEpUpClick"),
				isAiding = bindHelper.self("isAiding")
			}
		}
	},
	["panel.btnChange"] = {
		varname = "panelBtnChange",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onChangeClick")
			}
		}
	},
	["panel.effectList"] = {
		varname = "effectList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("effectStartConfig"),
				item = bindHelper.self("effectItem"),
				itemAction = {
					isAction = true
				},
				onItem = function(list, node, k, v)
					local childs = node:multiget("textNote", "iconStar")

					childs.textNote:removeChildByName("richText1")

					local richText1 = rich.createWithWidth(string.format("%s%s", v.color, "x" .. v.value .. ": "), 44, nil, 100, 5):anchorPoint(0, 0.5):addTo(childs.textNote, 6):name("richText1")

					childs.textNote:removeChildByName("richText2")

					local richText2 = rich.createWithWidth(v.str, 44, nil, 678, 5):anchorPoint(0, 0.5):addTo(childs.textNote, 6):name("richText2")
					local height1 = richText1:size().height - 46
					local height2 = richText2:size().height - 46

					richText1:y(height2 - height1 - 0)
					richText2:y(height2 / 2)
					richText2:x(richText2:x() + 100)
					node:size(879, height2 + 74)

					local starIconPath = string.format("common/icon/icon_star%s.png", v.value > v.star and "_d" or "")

					childs.iconStar:texture(starIconPath):y(node:size().height / 2 + height2 / 2)
					childs.textNote:text("")
				end
			}
		}
	},
	["panel.btnOk"] = {
		varname = "btnOk",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onStarClick")
			}
		}
	},
	["panel.btnOk.textNote"] = {
		binds = {
			event = "effect",
			data = {
				color = ui.COLORS.NORMAL.WHITE,
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["panel.btnExtreme"] = {
		varname = "btnExtreme",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onExtremeClick")
			}
		}
	},
	["panel.btnExtreme.textNote"] = {
		binds = {
			event = "effect",
			data = {
				color = ui.COLORS.NORMAL.WHITE,
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["panel.itemList"] = {
		varname = "itemList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				data = bindHelper.self("costItems"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					node:name("item" .. list:getIdx(k))

					local grayState = v.num < v.targetNum and 1 or 0

					grayState = list.isAiding() and 2 or grayState

					node:get("cardIcon"):visible(v.typ == "card")
					node:get("itemIcon"):visible(v.typ ~= "card")

					if v.typ == "card" then
						bind.extend(list, node:get("cardIcon"), {
							class = "card_icon",
							props = {
								cardId = v.id,
								rarity = v.rarity,
								grayState = grayState,
								onNode = function(panel)
									uiEasy.setCardNum(panel, v.num, v.targetNum, 1)
									panel:setTouchEnabled(false)
								end
							}
						})
					else
						local binds = {
							class = "icon_key",
							props = {
								data = {
									key = v.id,
									num = v.num,
									targetNum = v.targetNum
								},
								grayState = grayState,
								onNode = function(panel)
									panel:setTouchEnabled(false)
								end
							}
						}

						bind.extend(list, node, binds)
					end

					node:get("mask"):visible(v.num < v.targetNum)
					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.itemClick, k, v)
						}
					})
				end
			},
			handlers = {
				itemClick = bindHelper.self("onCostItemClick"),
				isAiding = bindHelper.self("isAiding")
			}
		}
	}
}

function CardStarView:onCreate(dbHandler)
	self.selectDbId = dbHandler()
	self.isAiding = dataEasy.getIsStarAidState(self.selectDbId:read())

	self:initModel()
	self.txtEmpty:anchorPoint(0.5, 0.5)
	self.txtEmpty:x(self.txtEmpty:x() + 250)

	self.costCardIDs = {}
	self.chipBarPercent = idler.new(0)
	self.chipNum = idler.new(0)
	self.chipNeed = idler.new(0)
	self.needCash = idler.new(0)
	self.effectStartConfig = idlers.new()
	self.selectPanelState = idler.new(false)
	self.extremePanelState = idler.new(false)
	self.cardInfos = idlers.new()
	self.costItems = idlers.new()
	self.selectIdx = idler.new()
	self.eps = idlers.new()
	self.extremePoint = idler.new(0)
	self.starSkillIcon = idler.new()
	self.resetEpCost = idler.new(gCommonConfigCsv.cardStarSkillResetCostRMB)
	self.starSkills = idlers.new()
	self.canResetEp = idler.new(false)

	local times = 0

	idlereasy.any({
		self.cardId,
		self.star,
		self.frags,
		self.cards,
		self.items,
		self.extremePoints
	}, function(_, cardId, star, frags, cards, items, extremePoints)
		times = times + 1

		performWithDelay(self, function()
			if times > 0 then
				self:refreshView()

				times = 0
			end
		end, 0)
	end)
	idlereasy.when(self.canResetEp, function(_, canResetEp)
		uiEasy.setBtnShader(self.btnResetEp, nil, canResetEp and 1 or 3)
	end)
	idlereasy.when(self.gold, function(_, gold)
		local cardCsv = csv.cards[self.cardId:read()]
		local csvStar = gStarCsv[cardCsv.starTypeID][self.star:read()]
		local color = gold >= csvStar.gold and cc.c4b(91, 84, 91, 255) or cc.c4b(249, 87, 114, 255)

		text.addEffect(self.needGoldTxt, {
			color = color
		})
	end)

	self.selectMax = idler.new(1)
	self.selectNum = 0

	idlereasy.any({
		self.selectIdx,
		self.selectMax
	}, function(_, selectIdx, selectMax)
		self.textNum:text("0/" .. selectMax)

		if self.cardInfos:atproxy(selectIdx) then
			local cardData = self.cardInfos:atproxy(selectIdx)

			if selectMax <= self.selectNum and cardData.selectState == false then
				return
			end

			cardData.selectState = not cardData.selectState

			local selectNum = 0
			local selectedDbId = {}

			for i = 1, self.cardInfos:size() do
				local cardInfos = self.cardInfos:atproxy(i)

				if cardInfos.selectState == true then
					selectNum = selectNum + 1

					table.insert(selectedDbId, cardInfos.dbid)
				end
			end

			self.selectNum = selectNum

			self.textNum:text(selectNum .. "/" .. selectMax)

			for i = 1, self.cardInfos:size() do
				local cardInfos = self.cardInfos:atproxy(i)

				cardInfos.canSelect = selectMax <= selectNum
			end
		end
	end)
	adapt.setTextScaleWithWidth(self.btnFrags:get("textNote"), nil, 200)
end

function CardStarView:refreshView()
	local cardId = self.cardId:read()
	local skinId = self.skinId:read()
	local star = self.star:read()
	local frags = self.frags:read()
	local cardCsv = csv.cards[cardId]

	self.panelBtnChange:visible(cardCsv.cardType == 1)

	local maxStar = table.length(gStarCsv[cardCsv.starTypeID])

	self:setEffectPanel(star, gStarEffectCsv[cardCsv.starEffectIndex])

	local csvStar = gStarCsv[cardCsv.starTypeID][star]

	self:setCostDatas(csvStar, cardId, cardCsv)

	local cardMarkCfg = csv.cards[cardCsv.cardMarkID]
	local starSkillSeqID = cardMarkCfg.starSkillSeqID
	local starSkill = csv.card_star_skill[starSkillSeqID].starSkillList

	if dataEasy.isUnlock(gUnlockCsv.extremityProperty) and maxStar <= star and itertools.size(starSkill) > 0 then
		self.panel:get("btnExtreme"):show()
		self.panel:get("iconMax"):hide()
	else
		self.panel:get("iconMax"):visible(maxStar <= star)
		self.panel:get("btnExtreme"):hide()
	end

	self:setFragsPanel(cardCsv, frags)

	local unitId = dataEasy.getUnitId(cardId, skinId)
	local unitCsv = csv.unit[cardCsv.unitID]
	local v = {
		id = cardId,
		unitId = unitId,
		advance = self.advance:read(),
		rarity = unitCsv.rarity,
		star = star,
		level = self.level:read()
	}

	setCardIcon(self, self.panel:get("iconPanel1"), v)

	v.star = math.min(star + 1, maxStar)

	setCardIcon(self, self.panel:get("iconPanel2"), v)

	if csvStar then
		self.needCash:set(csvStar.gold)
		self.needGoldTxt:text(csvStar.gold)

		local color = dataEasy.getNumByKey("gold") >= csvStar.gold and cc.c4b(91, 84, 91, 255) or cc.c4b(249, 87, 114, 255)

		text.addEffect(self.needGoldTxt, {
			color = color
		})

		local x, y = self.btnOk:xy()

		self.costInfo:xy(x, y + self.btnOk:height() / 2 + 30)
		adapt.oneLineCenterPos(cc.p(self.costInfo:width() / 2, self.costInfo:height() / 2), {
			self.costTxt,
			self.needGoldTxt,
			self.costIcon
		}, cc.p(10, 0))
	end

	self:setCardDatas(csvStar)

	if self.extremePanelState:read() == true then
		self:onExtremeClick()
	end

	local isAiding = self.isAiding

	self.costInfo:visible(not isAiding and star < maxStar and csvStar and csvStar.gold and csvStar.gold > 0)
	self.btnOk:visible(not isAiding and star < maxStar)
	self.btnResetEp:visible(not isAiding)
	self.extremePanel:get("textCost"):visible(not isAiding)
	self.extremePanel:get("textResetEpCost"):visible(not isAiding)
	self.extremePanel:get("imgCost"):visible(not isAiding)

	if isAiding then
		if self.extremePanel:get("aidTip") then
			self.extremePanel:get("aidTip"):show()
		else
			local tips = cc.Label:createWithTTF(gLanguageCsv.starNotExtremity, "font/youmi1.ttf", 40):addTo(self.extremePanel):anchorPoint(0.5, 0.5):name("aidTip"):xy(self.btnResetEp:x(), self.btnResetEp:y()):color(cc.c4b(247, 107, 69, 255))
		end

		if star < maxStar then
			if self.panel:get("aidStarTip") then
				self.panel:get("aidStarTip"):show()
			else
				local tips = cc.Label:createWithTTF(gLanguageCsv.starNotUp, "font/youmi1.ttf", 40):addTo(self.panel):anchorPoint(0.5, 0.5):name("aidStarTip"):xy(self.btnOk:x() - 240, self.btnOk:y() - 32):color(cc.c4b(247, 107, 69, 255))
			end
		elseif self.panel:get("aidStarTip") then
			self.panel:get("aidStarTip"):hide()
		end
	else
		if self.extremePanel:get("aidTip") then
			self.extremePanel:get("aidTip"):hide()
		end

		if self.panel:get("aidStarTip") then
			self.panel:get("aidStarTip"):hide()
		end
	end
end

function CardStarView:initModel()
	self.gold = gGameModel.role:getIdler("gold")
	self.items = gGameModel.role:getIdler("items")
	self.frags = gGameModel.role:getIdler("frags")
	self.cards = gGameModel.role:getIdler("cards")
	self.cardCapacity = gGameModel.role:getIdler("card_volume")
	self.extremePoints = gGameModel.role:getIdler("star_skill_points")

	idlereasy.when(self.selectDbId, function(_, selectDbId)
		self.costCardIDs = {}

		local card = gGameModel.cards:find(selectDbId)

		self.level = idlereasy.assign(card:getIdler("level"), self.level)
		self.cardId = idlereasy.assign(card:getIdler("card_id"), self.cardId)
		self.skinId = idlereasy.assign(card:getIdler("skin_id"), self.skinId)
		self.fight = idlereasy.assign(card:getIdler("fighting_point"), self.fight)
		self.advance = idlereasy.assign(card:getIdler("advance"), self.advance)
		self.attrs = idlereasy.assign(card:getIdler("attrs"), self.attrs)
		self.skills = idlereasy.assign(card:getIdler("skills"), self.skills)
		self.star = idlereasy.assign(card:getIdler("star"), self.star)
		self.isAiding = dataEasy.getIsStarAidState(selectDbId)
	end)
end

function CardStarView:setFragsPanel(cardCsv, frags)
	local fragCsv = csv.fragments[cardCsv.fragID]
	local chipNeedNum = fragCsv.combCount
	local myFragsNum = dataEasy.getNumByKey(cardCsv.fragID)

	setItemIcon(self, self.selectPanel:get("iconPanel"), {
		key = cardCsv.fragID,
		num = myFragsNum
	})
	self.chipNum:set(myFragsNum)
	self.chipNeed:set("/" .. chipNeedNum)

	local percent = cc.clampf(myFragsNum / chipNeedNum * 100, 0, 100)

	self.chipBarPercent:set(percent)
end

function CardStarView:setCostDatas(csvStar, cardId, cardCsv)
	local costItems = {}
	local rarityData = {}

	if csvStar then
		if csvStar.costCardNum > 0 then
			local unitCsv = csv.unit[cardCsv.unitID]
			local rarity = unitCsv.rarity

			table.insert(costItems, {
				typ = "card",
				num = 0,
				id = cardCsv.cardMarkID,
				rarity = rarity,
				targetNum = csvStar.costCardNum
			})
		end

		for k, v in csvPairs(csvStar.costItems) do
			table.insert(costItems, {
				id = k,
				num = dataEasy.getNumByKey(k),
				targetNum = v
			})
		end
	end

	self.costItems:update(costItems)
end

function CardStarView:setCardDatas(csvStar)
	self.selectNum = 0

	self.selectIdx:set(0)

	local cards = self.cards:read()
	local cardMarkID = dataEasy.getCardMarkID(self.cardId:read())
	local hash = dataEasy.inUsingCardsHash()
	local universalCards = {}

	if csvStar and csvStar.universalCards then
		universalCards = itertools.map(csvStar.universalCards, function(k, v)
			return v, k
		end)
	end

	local cardInfos = {}

	for i, v in pairs(cards) do
		local card = gGameModel.cards:find(v)

		if card then
			local cardData = card:read("card_id", "unit_id", "skin_id", "name", "fighting_point", "locked", "level", "star", "advance")
			local cardCsv = csv.cards[cardData.card_id]
			local unitId = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)
			local unitCsv = csv.unit[cardData.unit_id]
			local status = 0

			if cardData.locked then
				status = 1
			elseif hash[v] then
				status = 3
			elseif cardData.star > self.star:read() then
				status = 4
			end

			if cardCsv.cardMarkID == cardMarkID and self.selectDbId:read() ~= v or universalCards[cardData.card_id] then
				local tmpCardInfo = {
					selectState = false,
					id = cardData.card_id,
					markID = cardCsv.cardMarkID,
					unitId = unitId,
					rarity = unitCsv.rarity,
					attr1 = unitCsv.natureType,
					attr2 = unitCsv.natureType2,
					level = cardData.level,
					star = cardData.star,
					name = cardData.name,
					locked = cardData.locked,
					advance = cardData.advance,
					fight = cardData.fighting_point,
					dbid = v,
					status = status,
					battleType = hash[v],
					universal = universalCards[cardData.card_id]
				}

				table.insert(cardInfos, tmpCardInfo)
			end
		end
	end

	self.selectPanel:get("empty"):visible(#cardInfos == 0)
	self.bgIcon:visible(#cardInfos ~= 0)
	table.sort(cardInfos, function(a, b)
		if a.universal and not b.universal then
			return true
		elseif not a.universal and b.universal then
			return false
		end

		return a.fight > b.fight
	end)
	self.cardInfos:update(cardInfos)
end

function CardStarView:setEffectPanel(star, effectCfg)
	local keys = itertools.keys(effectCfg)
	local c1 = "#C0x5B545B##F44#"
	local c2 = "#C0x60C456##F44#"

	table.sort(keys)

	local datas = {}

	for k1, i in ipairs(keys) do
		local v = effectCfg[i]
		local str = ""
		local args = {}
		local color = star < i and "#C0xB7B09E#" or "#C0x5B545B#"
		local color1 = i <= star and c1 or "#C0xB7B09E#"
		local color2 = i <= star and c2 or "#C0xB7B09E#"
		local isTheSame = true
		local lastStr

		for k, v in csvPairs(v.attrNum) do
			local attr = game.ATTRDEF_TABLE[k]
			local name = gLanguageCsv["attr" .. string.caption(attr)]
			local effectNum = "+" .. dataEasy.getAttrValueString(k, v)

			if i >= 12 then
				if lastStr then
					if lastStr ~= effectNum then
						isTheSame = false
					end
				else
					lastStr = effectNum
				end
			end

			table.insert(args, color1 .. name .. color2 .. effectNum)
		end

		if i >= 12 and isTheSame and csvSize(v.attrNum) == 6 then
			str = color1 .. gLanguageCsv.cardStarSixD .. color2 .. lastStr
		else
			str = table.concat(args, " ")
		end

		str = str .. color1 .. (v.effectDesc or "")
		datas[k1] = {
			str = str,
			value = i,
			star = star,
			color = color
		}
	end

	self.effectStartConfig:update(datas)
end

function CardStarView:onGainWayClick()
	local fragsId = csv.cards[self.cardId:read()].fragID
	local fragCsv = csv.fragments[fragsId]
	local chipNeedNum = fragCsv.combCount

	gGameUI:stackUI("common.gain_way", nil, nil, fragsId, nil, chipNeedNum)
end

function CardStarView:onCombClick()
	if itertools.size(self.cards:read()) >= self.cardCapacity:read() then
		gGameUI:showTip(gLanguageCsv.cardBagHaveBeenFull)

		return
	end

	local cardCsv = csv.cards[self.cardId:read()]

	cardCsv = csv.cards[cardCsv.cardMarkID]

	local fragCsv = csv.fragments[cardCsv.fragID]
	local name = csv.cards[fragCsv.combID].name

	if self.chipNum:read() < fragCsv.combCount then
		gGameUI:showTip(gLanguageCsv.fragCombfragNotEnough)

		return
	end

	local strs = {
		string.format("#C0x5b545b#" .. gLanguageCsv.wantConsumeFragsCombCard, fragCsv.combCount, "#C0x60C456#" .. fragCsv.name .. "#C0x5b545b#", "#C0x60C456#" .. name)
	}

	gGameUI:showDialog({
		clearFast = true,
		isRich = true,
		btnType = 2,
		content = strs,
		cb = function()
			gGameApp:requestServer("/game/role/frag/comb", function(tb)
				gGameUI:stackUI("common.gain_sprite", nil, {
					full = true
				}, tb.view.carddbIDs[1], nil, false, self:createHandler("resetSelectNum"))
			end, {
				[cardCsv.fragID] = 1
			})
		end
	})
end

function CardStarView:resetSelectNum()
	self.selectNum = 0
end

function CardStarView:onCardItemClick(list, k, v)
	local card = gGameModel.cards:find(v.dbid)
	local baseStar = card:read("getstar")

	if v.selectState == false and (baseStar < v.star or v.level > 1 or v.advance > 1 or self:getDevelopState(v.dbid)) then
		gGameUI:showDialog({
			btnType = 2,
			isRich = true,
			content = gLanguageCsv.tipsForSelectingMaterials,
			cb = function()
				self.selectIdx:set(k.k, true)
			end
		})
	else
		self.selectIdx:set(k.k, true)
	end
end

function CardStarView:getDevelopState(dbid)
	local card = gGameModel.cards:find(dbid)
	local effortValue = card:read("effort_values")
	local equips = card:read("equips")
	local skills = card:read("skills")
	local cardId = card:read("card_id")

	for k, v in pairs(skills) do
		if v > 1 then
			return true
		end
	end

	local cardCsv = csv.cards[cardId]
	local fragCsv = csv.fragments[cardCsv.fragID]

	if cardId > fragCsv.combID then
		return true
	end

	for k, v in pairs(effortValue) do
		if v > 0 then
			return true
		end
	end

	for k, v in pairs(equips) do
		if v.level > 1 or v.star > 0 or v.awake > 0 then
			return true
		end
	end

	return false
end

function CardStarView:onSureClick()
	self.costCardIDs = {}

	local rarityData = {}

	for i, v in self.cardInfos:pairs() do
		local v = v:proxy()

		if v.selectState then
			table.insert(self.costCardIDs, v.dbid)
		end
	end

	self.costItems:atproxy(1).num = self.selectNum

	self.selectPanelState:set(false)
end

function CardStarView:onSelectPanelClick()
	self.selectPanelState:set(false)
end

function CardStarView:onCostItemClick(list, k, v)
	if self.isAiding then
		return
	end

	if v.typ == "card" then
		self.selectMax:set(v.targetNum)
		self.selectPanelState:set(not self.selectPanelState:read())
	else
		gGameUI:stackUI("common.gain_way", nil, nil, v.id, nil, v.targetNum)
	end
end

function CardStarView:onStarSkillCostItemClick()
	self.selectMax:set(1)
	self.selectPanelState:set(true)
end

function CardStarView:onChangeClick()
	if self.star:read() == 12 and not dataEasy.isUnlock(gUnlockCsv.extremityProperty) then
		gGameUI:showTip(gLanguageCsv.cardStarMaxErr)

		return
	end

	gGameUI:stackUI("city.card.star_changefrags", nil, nil, self.selectDbId:read())
end

function CardStarView:onStarClick()
	if self.star:read() == 12 then
		gGameUI:showTip(gLanguageCsv.cardStarMaxErr)

		return
	end

	if dataEasy.getNumByKey("gold") < self.needCash:read() then
		gGameUI:showTip(gLanguageCsv.starNoEnoughGold)

		return
	end

	for i, v in self.costItems:ipairs() do
		local v = v:proxy()

		if v.num < v.targetNum then
			gGameUI:showTip(gLanguageCsv.starMaterialsNotEnough)

			return
		end
	end

	local fight = self.fight:read()
	local attrs = clone(self.attrs:read())

	local function requestServer()
		gGameApp:requestServer("/game/card/star", function(tb)
			self.selectNum = 0

			gGameUI:stackUI("city.card.common_success", nil, {
				blackLayer = true
			}, self.selectDbId:read(), fight, {
				starOld = true,
				attrs = attrs,
				skills = self.skills:read()
			})
			audio.playEffectWithWeekBGM("star.mp3")
		end, self.selectDbId, self.costCardIDs)
	end

	local hasMoreStar = false
	local markID = csv.cards[self.cardId:read()].cardMarkID

	for i, v in self.cardInfos:pairs() do
		local v = v:proxy()

		if v.markID == markID and v.star > self.star:read() then
			hasMoreStar = true
		end
	end

	if hasMoreStar then
		local str = gLanguageCsv.moreStarTips

		gGameUI:showDialog({
			btnType = 2,
			clearFast = true,
			content = str,
			cb = requestServer
		})
	else
		requestServer()
	end
end

function CardStarView:onExtremeClick()
	local extremePoints = self.extremePoints:read()
	local cardId = self.cardId:read()
	local cardCsv = csv.cards[cardId]
	local cardMarkCfg = csv.cards[cardCsv.cardMarkID]

	if self.star:read() == 12 and dataEasy.isUnlock(gUnlockCsv.extremityProperty) then
		self.extremePoint:set(extremePoints[cardCsv.cardMarkID] or 0)

		local starSkillSeqID = cardMarkCfg.starSkillSeqID

		self.starSkillIcon:set(csv.unit[cardMarkCfg.unitID].iconSimple)

		local starSkills = {}
		local starSkill = csv.card_star_skill[starSkillSeqID].starSkillList
		local canResetEp = false

		for k, v in ipairs(starSkill) do
			local skillLevel = self.skills:read()[v] or 0

			if skillLevel > 0 then
				canResetEp = true
			end

			starSkills[v] = {
				fastUpgradeNum = 1,
				cardId = self.cardId:read(),
				skillId = v,
				skillLevel = skillLevel,
				clientGold = self.gold:read(),
				icon = self.starSkillIcon:read()
			}
		end

		self.canResetEp:set(canResetEp)
		self.starSkills:update(starSkills)
		self.extremePanelState:set(true)
	end
end

function CardStarView:closeExtreme()
	self.extremePanelState:set(false)
end

function CardStarView:onAddExtrePointClick()
	gGameUI:stackUI("city.card.star_changestarskill", nil, nil, self:createHandler("selectDbId"))
end

function CardStarView:onResetEp()
	if gGameModel.role:read("rmb") < self.resetEpCost:read() then
		uiEasy.showDialog("rmb")
	else
		if self.canResetEp:read() == false then
			gGameUI:showTip(gLanguageCsv.haveNotUpStarSkill)

			return false
		end

		local cardId = self.cardId:read()
		local name = csv.unit[csv.cards[cardId].unitID].name
		local quality = dataEasy.getCfgByKey(csv.cards[cardId].fragID).quality
		local textColor = ui.QUALITYCOLOR[quality]

		gGameUI:showDialog({
			isRich = true,
			btnType = 2,
			title = "",
			content = string.format(gLanguageCsv.starSkillResetTips, self.resetEpCost:read(), textColor .. name),
			cb = function()
				gGameApp:requestServer("/game/card/star/skill/reset", function(tb)
					gGameUI:showGainDisplay(tb)
				end, self.selectDbId:read())
			end
		})
	end
end

function CardStarView:onEpUpClick(list, k, v, cost)
	local skillMaxLevel = csv.cards[v.cardId].starSkillMaxLevel

	if skillMaxLevel < v.skillLevel + 1 then
		gGameUI:showTip(gLanguageCsv.starSkillMaxTips)

		return
	end

	if cost <= self.extremePoint:read() then
		gGameApp:requestServer("/game/card/skill/level/up", function(tb)
			return
		end, self.selectDbId, v.skillId, v.fastUpgradeNum)
	else
		self:onAddExtrePointClick()
	end
end

return CardStarView
