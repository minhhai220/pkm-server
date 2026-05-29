-- chunkname: @src.app.views.city.adventure.hunting.gate_detail

local ROUTE_TYPE = {
	normal = 1,
	elite = 2
}
local ENEMY_TYPE = {
	"city/adventure/hunting/icon_pt.png",
	"city/adventure/hunting/icon_jy.png",
	"city/adventure/exp/icon_zj.png"
}
local BIND_EFFECT = {
	event = "effect",
	data = {
		outline = {
			size = 4,
			color = cc.c4b(91, 84, 91, 255)
		}
	}
}
local HuntingGateDetailView = class("HuntingGateDetailView", Dialog)

HuntingGateDetailView.RESOURCE_FILENAME = "hunting_gate_detail.json"
HuntingGateDetailView.RESOURCE_BINDING = {
	["titleBg.title1"] = "title1",
	["awardPanel.awardList"] = "awardList",
	awardPanel = "awardPanel",
	["enemyPanel.item"] = "item",
	enemyPanel = "enemyPanel",
	infoPanel = "infoPanel",
	["skipBtn.skipNote"] = "skipNote",
	titleBg = "titleBg",
	bg = "imgBG",
	aidPanel = "aidPanel",
	["titleBg.title2"] = "title2",
	["titleBg.btnClose"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	},
	["battleBtn.title"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = cc.c4b(255, 255, 255, 255)
				}
			}
		}
	},
	battleBtn = {
		varname = "battleBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onBattleClick")
			}
		}
	},
	["passBtn.title"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = cc.c4b(255, 255, 255, 255)
				}
			}
		}
	},
	passBtn = {
		varname = "passBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onPassClick")
			}
		}
	},
	["infoPanel.lvText"] = {
		binds = BIND_EFFECT
	},
	["infoPanel.level"] = {
		binds = BIND_EFFECT
	},
	["enemyPanel.enemyList"] = {
		varname = "enemyList",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				padding = 10,
				asyncPreload = 6,
				data = bindHelper.self("enemyDatas"),
				item = bindHelper.self("item"),
				itemAction = {
					isAction = true
				},
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							showAttribute = false,
							unitId = v.unitId,
							advance = v.advance,
							levelProps = {
								data = v.level
							},
							star = v.star,
							rarity = v.rarity,
							onNode = function(panel)
								return
							end
						}
					})
				end
			}
		}
	},
	skipBtn = {
		varname = "selectSkip",
		binds = {
			event = "click",
			method = bindHelper.self("onSkipClick")
		}
	}
}

function HuntingGateDetailView:onCreate(data, enemyId, route, node, cb)
	self.data = data.defence_role_info or {}
	self.route = route
	self.enemyId = enemyId
	self.node = node
	self.enemyDatas = {}
	self.cb = cb

	self:initInfoPanel()
	self:updateAidPanel()
	self:initEnemyPanel()
	self:initAwardPanel()
	self:initSkipBtn()
	self:initPassBtn()
	adapt.oneLinePos(self.title1, self.title2, cc.p(4, 0))
	adapt.setTextAdaptWithSize(self.skipNote, {
		vertical = "center",
		horizontal = "left",
		size = cc.size(260, 60)
	})
	Dialog.onCreate(self)
end

function HuntingGateDetailView:initInfoPanel()
	local cfg = csv.cross.hunting.gate

	bind.extend(self, self.infoPanel:get("icon"), {
		class = "role_logo",
		event = "extend",
		props = {
			vip = false,
			level = false,
			logoId = self.data.logo,
			frameId = self.data.frame
		}
	})
	self.infoPanel:get("name"):text(self.data.name)
	self.infoPanel:get("area"):text(getServerArea(self.data.game_key))
	self.infoPanel:get("type"):texture(ENEMY_TYPE[cfg[self.enemyId].type])
	self.infoPanel:get("level"):text(self.data.level)
	adapt.oneLinePos(self.infoPanel:get("nameText"), self.infoPanel:get("name"), cc.p(2, 0))
	adapt.oneLinePos(self.infoPanel:get("areaText"), self.infoPanel:get("area"), cc.p(2, 0))
	adapt.oneLineCenterPos(cc.p(self.infoPanel:get("icon"):size().width / 2, self.infoPanel:get("level"):y()), {
		self.infoPanel:get("lvText"),
		self.infoPanel:get("level")
	}, cc.p(0, 0), "left")
end

function HuntingGateDetailView:initEnemyPanel()
	local fighting_point = 0

	for _, v in pairs(self.data.defence_cards) do
		local data = self.data.defence_card_attrs[v]
		local unitID = csv.cards[data.card_id].unitID
		local unitCfg = csv.unit[unitID]

		table.insert(self.enemyDatas, {
			unitId = unitID,
			level = data.level,
			advance = data.advance,
			rarity = unitCfg.rarity,
			star = data.star
		})

		fighting_point = fighting_point + data.fighting_point
	end

	table.sort(self.enemyDatas, function(a, b)
		return a.advance > b.advance
	end)
	self.infoPanel:get("fightPoint"):text(fighting_point + self.aidFightingPoint)
	adapt.oneLinePos(self.infoPanel:get("fightPointText"), self.infoPanel:get("fightPoint"), cc.p(2, 0))
end

function HuntingGateDetailView:initAwardPanel()
	local cfg = csv.cross.hunting.gate

	uiEasy.createItemsToList(self, self.awardList, cfg[self.enemyId].dropsView, {
		onNode = function(panel, v)
			if v.key ~= "gold" then
				ccui.ImageView:create("city/adventure/endless_tower/icon_gl.png"):anchorPoint(1, 0.5):xy(panel:width() - 5, panel:height() - 25):addTo(panel, 15)
			end
		end
	})
	self.awardList:setTouchEnabled(true)
end

function HuntingGateDetailView:initSkipBtn()
	local state = userDefault.getForeverLocalKey("huntingSkipBattle", false)

	self.selectSkip:get("skipBtn"):setSelectedState(state)
end

function HuntingGateDetailView:initPassBtn()
	local unlockKey = self.route == 1 and "huntingPass" or "specialHuntingPass"
	local lastMaxNode = gGameModel.hunting:read("hunting_route")[self.route].last_max_node
	local hisMaxNode = gGameModel.hunting:read("hunting_route")[self.route].history_max_node
	local lastCanPass = 0
	local historyCanPass = 0

	if csv.cross.hunting.route[lastMaxNode] then
		lastCanPass = csv.cross.hunting.route[lastMaxNode].lastCanPass
	end

	if csv.cross.hunting.route[hisMaxNode] then
		historyCanPass = csv.cross.hunting.route[hisMaxNode].historyCanPass
	end

	local canPassNode = math.max(lastCanPass, historyCanPass)

	dataEasy.getListenUnlock(unlockKey, function(isShow)
		self.passBtn:visible(isShow and self.node % 100 <= canPassNode)
	end)
end

function HuntingGateDetailView:onBattleClick()
	local battleCardIDs = gGameModel.hunting:read("hunting_route")[self.route].cards or {}
	local _, fix = dataEasy.fixEmattleCards(battleCardIDs, true)
	local skip = userDefault.getForeverLocalKey("huntingSkipBattle", false)

	if not fix and skip then
		if not itertools.isempty(battleCardIDs) and self:checkEmbattle() then
			self:skipEmbattleToFight()
		else
			self:goEmbattle()
		end
	else
		if not self:checkEmbattle() then
			gGameUI:showTip(gLanguageCsv.randomTowerCheckEmbattleLevel)
		end

		self:goEmbattle()
	end
end

function HuntingGateDetailView:onPassClick()
	local cb = self.cb

	gGameApp:requestServer("/game/hunting/battle/pass", function(tb)
		self:addCallbackOnExit(function()
			gGameUI:showGainDisplay(tb.view.drop, {
				cb = cb
			})
		end)
		Dialog.onClose(self)
	end, self.route, self.node, self.enemyId)
end

function HuntingGateDetailView:skipEmbattleToFight()
	local battleCards = gGameModel.hunting:read("hunting_route")[self.route].cards or {}
	local cardStates = gGameModel.hunting:read("hunting_route")[self.route].card_states or {}
	local battleExtra = gGameModel.hunting:read("hunting_route")[self.route].extra or {}
	local aidCards = gGameModel.hunting:read("hunting_route")[self.route].aid_cards or {}
	local cards = {}
	local aidCards = table.shallowcopy(aidCards)
	local weatherCards = {}

	if itertools.isempty(battleCards) then
		gGameUI:showTip(gLanguageCsv.noSpriteAvailable)

		return
	end

	if itertools.size(cardStates) == 0 then
		local cardDatas = gGameModel.role:read("battle_cards")
		local aidData = {}

		cards = table.shallowcopy(cardDatas)
		aidCards = table.shallowcopy(aidData)
	else
		local myCards = gGameModel.role:read("cards")
		local cardDatas = {}
		local hash = itertools.map(myCards, function(k, v)
			return v, k
		end)

		for k, dbid in pairs(battleCards) do
			if hash[dbid] then
				if cardStates[dbid] and cardStates[dbid][1] and cardStates[dbid][1] ~= 0 then
					weatherCards[k] = dbid
				end

				cardDatas[k] = dbid
			end
		end

		cards = cardDatas

		for k, dbid in pairs(aidCards) do
			if hash[dbid] then
				aidCards[k] = dbid
			end
		end
	end

	local weatherID = dataEasy.getWeatherID(weatherCards, battleExtra.weahter)

	battleEntrance.battleRequest("/game/hunting/battle/start", self.route, self.node, self.enemyId, cards, {
		arms = table.deepcopy(battleExtra.arms),
		weather = weatherID
	}, aidCards):onStartOK(function(data)
		gGameUI:goBackInStackUI("city.adventure.hunting.route")
	end):show()
end

function HuntingGateDetailView:goEmbattle()
	local skip = userDefault.getForeverLocalKey("huntingSkipBattle", false)
	local battleCardIDs = gGameModel.hunting:read("hunting_route")[self.route].cards or {}
	local _, fix = dataEasy.fixEmattleCards(battleCardIDs, true)

	if not fix and skip then
		self:skipEmbattleToFight()
	else
		gGameUI:stackUI("city.card.embattle.hunting", nil, {
			full = true
		}, {
			fightCb = function(view, battleCards, extra, aidCards)
				battleEntrance.battleRequest("/game/hunting/battle/start", self.route, self.node, self.enemyId, battleCards, extra, aidCards):onStartOK(function(data)
					gGameUI:goBackInStackUI("city.adventure.hunting.route")
				end):show()
			end,
			route = self.route,
			from = game.EMBATTLE_FROM_TABLE.hunting
		})
	end
end

function HuntingGateDetailView:checkEmbattle()
	local battleCardIDs = gGameModel.hunting:read("hunting_route")[self.route].cards or gGameModel.role:read("battle_cards")

	for _, dbid in pairs(battleCardIDs) do
		local card = gGameModel.cards:find(dbid)

		if card and card:read("level") < 10 then
			return false
		end
	end

	return true
end

function HuntingGateDetailView:onSkipClick()
	local state = userDefault.getForeverLocalKey("huntingSkipBattle", false)

	self.selectSkip:get("skipBtn"):setSelectedState(not state)
	userDefault.setForeverLocalKey("huntingSkipBattle", not state)
end

function HuntingGateDetailView:updateAidPanel()
	self.aidFightingPoint = 0

	local aidNum = dataEasy.getAidNum(game.GATE_TYPE.hunting, nil, self.data.level)

	if aidNum == 0 then
		return
	end

	self.aidPanel:show()
	self.titleBg:y(self.titleBg:y() + 75)
	self.imgBG:height(1150)
	self.infoPanel:y(self.infoPanel:y() + 90)
	self.enemyPanel:y(self.enemyPanel:y() + 90)
	self.enemyList:x(self.enemyList:x() + 30)
	self.awardPanel:y(self.awardPanel:y() - 70)
	self.battleBtn:y(self.battleBtn:y() - 40)
	self.passBtn:y(self.passBtn:y() - 40)
	self.selectSkip:y(self.selectSkip:y() - 40)

	local aidData = self.data.defence_aid_cards or {}
	local cardIDs = {}

	for i = 1, aidNum do
		if aidData[i] then
			local info = self.data.defence_card_attrs[aidData[i]]

			cardIDs[i] = dataEasy.getUnitId(info.card_id, info.skin_id)
			self.aidFightingPoint = self.aidFightingPoint + (info.aid_fighting_point or 0)
		else
			cardIDs[i] = 0
		end
	end

	self.aidPanel:get("list"):x(self.aidPanel:get("list"):x() + 30)
	self.aidPanel:get("list"):width(self.aidPanel:get("list"):width() + 200)
	uiEasy.createSimpleCardToList(self, self.aidPanel:get("list"), cardIDs, {
		scale = 2,
		margin = 65
	})
end

return HuntingGateDetailView
