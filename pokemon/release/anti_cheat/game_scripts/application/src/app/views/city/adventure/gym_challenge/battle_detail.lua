-- chunkname: @src.app.views.city.adventure.gym_challenge.battle_detail

local GymBattleDetail = class("GymBattleDetail", Dialog)

local function initItem(list, node, k, v)
	if not v.card_id then
		node:get("emptyPanel"):show()

		return
	end

	node:get("emptyPanel"):hide()

	local unitId = dataEasy.getUnitId(v.card_id, v.skin_id)

	bind.extend(list, node, {
		class = "card_icon",
		props = {
			unitId = unitId,
			advance = v.advance,
			rarity = v.rarity,
			star = v.star,
			levelProps = {
				data = v.level
			},
			onNode = function(node)
				node:xy(0, -6):scale(0.8)
			end
		}
	})
end

GymBattleDetail.RESOURCE_FILENAME = "gym_battle_detail.json"
GymBattleDetail.RESOURCE_BINDING = {
	["imgBG.img"] = "img",
	["left.imgBg.btnWeather"] = "btnWeather1",
	["right.imgBg.btnWeather"] = "btnWeather2",
	["left.imgBg.imgBuf"] = "imgBuf1",
	["right.imgBg.imgBuf"] = "imgBuf2",
	right = "right",
	left = "left",
	item = "item",
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	},
	["left.textLv"] = {
		varname = "textLvL",
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.DEFAULT
				}
			}
		}
	},
	["left.textNote3"] = {
		varname = "textNote3L",
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.DEFAULT
				}
			}
		}
	},
	["right.textLv"] = {
		varname = "textLvR",
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.DEFAULT
				}
			}
		}
	},
	["right.textNote3"] = {
		varname = "textNote3R",
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.DEFAULT
				}
			}
		}
	},
	["left.list1"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 3,
				data = bindHelper.self("team1"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end
			}
		}
	},
	["left.list2"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 3,
				data = bindHelper.self("team2"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end
			}
		}
	},
	["right.list1"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 3,
				data = bindHelper.self("team3"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end
			}
		}
	},
	["right.list2"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 3,
				data = bindHelper.self("team4"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end
			}
		}
	},
	["imgBG.btnReplay"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onReplay")
			}
		}
	},
	["imgBG.btnReplay.textNote"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = cc.c4b(254, 253, 236, 255)
				}
			}
		}
	},
	["left.head"] = {
		binds = {
			event = "extend",
			class = "role_logo",
			props = {
				vip = false,
				level = false,
				logoId = bindHelper.self("logoId1"),
				frameId = bindHelper.self("frameId1"),
				onNode = function(panel)
					panel:scale(1.2)
				end
			}
		}
	},
	["right.head"] = {
		binds = {
			event = "extend",
			class = "role_logo",
			props = {
				vip = false,
				level = false,
				logoId = bindHelper.self("logoId2"),
				frameId = bindHelper.self("frameId2"),
				onNode = function(panel)
					panel:scale(1.2)
				end
			}
		}
	},
	["left.textName"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("name1")
		}
	},
	["right.textName"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("name2")
		}
	}
}

function GymBattleDetail:onCreate(data)
	self.data = data

	Dialog.onCreate(self)
	self:initRole(data)
	self:initAidPanel(data)
	self:initCardData(data)

	self.recordID = data.play_record_id
	self.crossKey = data.cross_key
end

function GymBattleDetail:initRole(data)
	self.logoId1 = idler.new(data.logo)
	self.logoId2 = idler.new(data.defence_logo)
	self.frameId1 = idler.new(data.frame)
	self.frameId2 = idler.new(data.defence_frame)
	self.name1 = idler.new(data.name)
	self.name2 = idler.new(data.defence_name)

	self.left:get("textLv"):text(data.level)
	adapt.oneLineCenterPos(cc.p(230, 640), {
		self.left:get("textNote3"),
		self.left:get("textLv")
	}, cc.p(2, 3))
	self.right:get("textLv"):text(data.defence_level)
	adapt.oneLineCenterPos(cc.p(230, 640), {
		self.right:get("textNote3"),
		self.right:get("textLv")
	}, cc.p(2, 3))

	if data.role_key ~= "" then
		self.left:get("textService"):text(getServerArea(data.role_key))
	else
		self.left:get("textService"):hide()
	end

	if data.defence_role_key ~= "" then
		self.right:get("textService"):text(getServerArea(data.defence_role_key))
	else
		self.right:get("textService"):hide()
	end

	local my = gGameModel.role:read("id")

	if my == data.role_id and data.result == "win" or my ~= data.role_id and data.result ~= "win" then
		self.left:get("head.imgResult"):texture("city/pvp/craft/icon_win.png")
		self.right:get("head.imgResult"):texture("city/pvp/craft/icon_lose.png")
		self.img:texture("city/adventure/gym_challenge/bg_1.png")
	else
		self.right:get("head.imgResult"):texture("city/pvp/craft/icon_win.png")
		self.left:get("head.imgResult"):texture("city/pvp/craft/icon_lose.png")
		self.img:texture("city/adventure/gym_challenge/bg_2.png")
	end

	if matchLanguage({
		"en"
	}) then
		adapt.setAutoText(self.left:get("textNote1"), nil, 120)
		adapt.setAutoText(self.left:get("textNote2"), nil, 120)
		adapt.setAutoText(self.right:get("textNote1"), nil, 120)
		adapt.setAutoText(self.right:get("textNote2"), nil, 120)
	end
end

function GymBattleDetail:initAidPanel(data)
	self.aidFightingPoint = {
		0,
		0
	}

	if data.type == 5 or data.type == 6 or data.type == 13 or data.type == 14 then
		return
	end

	local aidData = {
		data.aid_cards,
		data.defence_aid_cards
	}
	local attrData = {
		data.card_attrs,
		data.defence_card_attrs
	}
	local panel = {
		self.left,
		self.right
	}

	for i = 1, 2 do
		local roleLevel = i == 1 and self.data.level or self.data.defence_level
		local aidNum = dataEasy.getAidNum(game.GATE_TYPE.crossGym, nil, roleLevel)
		local item = panel[i]

		item:get("list1"):setDirection(1):size(180, 470):setInnerContainerSize(cc.size(180, 470)):setItemsMargin(10):xy(520, 0)
		item:get("list2"):setDirection(1):size(180, 470):setInnerContainerSize(cc.size(180, 470)):setItemsMargin(10):xy(340, 0)
		itertools.invoke({
			item:get("textNote1"),
			item:get("textNote2")
		}, "hide")
		item:get("aidPanel"):show()

		if aidNum == 0 then
			item:get("aidPanel.list"):hide()
			item:get("aidPanel.list1"):hide()
			item:get("aidPanel.aid"):hide()
			item:get("aidPanel.font"):x(item:get("aidPanel.font"):x() - 60)
			item:get("aidPanel.last"):x(item:get("aidPanel.last"):x() - 60)
			item:get("list1"):x(item:get("list1"):x() - 60)
			item:get("list2"):x(item:get("list2"):x() - 60)
		end

		local unitIDs = {}
		local unitIDs1 = {}

		for k = 1, aidNum do
			local id = aidData[i] and aidData[i][k]
			local info = attrData[i][id]

			if k > 3 then
				unitIDs1[k - 3] = info and dataEasy.getUnitId(info.card_id, info.skin_id) or 0
			else
				unitIDs[k] = info and dataEasy.getUnitId(info.card_id, info.skin_id) or 0
			end

			if info then
				self.aidFightingPoint[i] = self.aidFightingPoint[i] + (info.aid_fighting_point or 0)
			end
		end

		local list = item:get("aidPanel.list")
		local list1 = item:get("aidPanel.list1")

		if aidNum > 3 then
			list1:x(list1:x() - 115)
			list:x(list:x() + 5)
			uiEasy.createSimpleCardToList(self, list1, unitIDs1, {
				bgScale = 0.9,
				scale = 1.5
			})
		else
			item:get("aidPanel.list1"):hide()
		end

		uiEasy.createSimpleCardToList(self, list, unitIDs, {
			bgScale = 0.9,
			scale = 1.5
		})
	end
end

function GymBattleDetail:initCardData(data)
	local extra = table.deepcopy(data.extra or {}, true)
	local defenceExtra = table.deepcopy(data.defence_extra or {}, true)
	local selectWeatherID = {
		extra.weather or 0,
		defenceExtra.weather or 0
	}
	local selectArms = {
		extra.arms,
		defenceExtra.arms
	}

	if self.btnWeather1 then
		for i = 1, 2 do
			local btnWeather = self["btnWeather" .. i]

			if selectWeatherID[i] == 0 then
				btnWeather:hide()
			else
				btnWeather:show():scale(0.8)
				btnWeather:get("icon"):texture(csv.weather_system.weather[selectWeatherID[i]].iconRes)
			end
		end
	end

	self.team1 = {}
	self.team2 = {}
	self.team3 = {}
	self.team4 = {}

	local battleCards = {}
	local defenceBattleCards = {}
	local unitTab = csv.unit
	local csvTab = csv.cards

	for i = 1, 6 do
		if i <= 3 then
			local dbId1 = data.cards[i]

			if dbId1 then
				local cardInfo = table.shallowcopy(data.card_attrs[dbId1])

				self.team1[i] = cardInfo

				local unitID = csvTab[cardInfo.card_id].unitID

				self.team1[i].rarity = unitTab[unitID].rarity
				battleCards[i] = dbId1
			else
				self.team1[i] = {}
			end

			local dbId2 = data.defence_cards[i]

			if dbId2 then
				local cardInfo = table.shallowcopy(data.defence_card_attrs[dbId2])

				self.team3[i] = cardInfo

				local unitID = csvTab[cardInfo.card_id].unitID

				self.team3[i].rarity = unitTab[unitID].rarity
				defenceBattleCards[i] = dbId2
			else
				self.team3[i] = {}
			end
		else
			local dbId1 = data.cards[i]

			if dbId1 then
				local cardInfo = table.shallowcopy(data.card_attrs[dbId1])

				self.team2[i - 3] = cardInfo

				local unitID = csvTab[cardInfo.card_id].unitID

				self.team2[i - 3].rarity = unitTab[unitID].rarity
				battleCards[i] = dbId1
			else
				self.team2[i - 3] = {}
			end

			local dbId2 = data.defence_cards[i]

			if dbId2 then
				local cardInfo = table.shallowcopy(data.defence_card_attrs[dbId2])

				self.team4[i - 3] = cardInfo

				local unitID = csvTab[cardInfo.card_id].unitID

				self.team4[i - 3].rarity = unitTab[unitID].rarity
				defenceBattleCards[i] = dbId2
			else
				self.team4[i - 3] = {}
			end
		end
	end

	local fightPoint1 = 0

	for i = 1, 3 do
		fightPoint1 = fightPoint1 + (self.team1[i].fighting_point or 0)
		fightPoint1 = fightPoint1 + (self.team2[i].fighting_point or 0)
	end

	local fightPoint2 = 0

	for i = 1, 3 do
		fightPoint2 = fightPoint2 + (self.team3[i].fighting_point or 0)
		fightPoint2 = fightPoint2 + (self.team4[i].fighting_point or 0)
	end

	self.left:get("imgBg.textZl"):text(fightPoint1 + self.aidFightingPoint[1])
	self.right:get("imgBg.textZl"):text(fightPoint2 + self.aidFightingPoint[2])
	bind.extend(self, self.imgBuf1, {
		class = "buff_arms",
		props = {
			noListener = true,
			battleCards = battleCards,
			arms = selectArms[1],
			getCardAttrsEx = functools.partial(self.getCardAttrs, self),
			enemyData = data.name ~= gGameModel.role:read("name"),
			onNode = function(node)
				node:scale(0.6)
			end
		}
	})
	bind.extend(self, self.imgBuf2, {
		class = "buff_arms",
		props = {
			noListener = true,
			battleCards = defenceBattleCards,
			arms = selectArms[2],
			getCardAttrsEx = functools.partial(self.getCardAttrs, self),
			enemyData = data.defence_name ~= gGameModel.role:read("name"),
			onNode = function(node)
				node:scale(0.6)
			end
		}
	})
	adapt.oneLinePos(self.left:get("imgBg.textZl"), {
		self.imgBuf1,
		self.btnWeather1
	}, {
		cc.p(15, 0),
		cc.p(0, 10)
	})
	adapt.oneLinePos(self.right:get("imgBg.textZl"), {
		self.imgBuf2,
		self.btnWeather2
	}, {
		cc.p(15, 0),
		cc.p(0, 10)
	})
end

function GymBattleDetail:onReplay()
	local interface = "/game/gym/playrecord/get"

	gGameModel:playRecordBattle(self.recordID, self.crossKey, interface, 0, nil)
end

function GymBattleDetail:getCardAttrs(dbid)
	if dbid then
		local cardInfo = self.data.card_attrs[dbid]
		local defenceCardInfo = self.data.defence_card_attrs[dbid]

		if cardInfo then
			return {
				card_id = cardInfo.card_id
			}
		end

		if defenceCardInfo then
			return {
				card_id = defenceCardInfo.card_id
			}
		end
	end

	return nil
end

return GymBattleDetail
