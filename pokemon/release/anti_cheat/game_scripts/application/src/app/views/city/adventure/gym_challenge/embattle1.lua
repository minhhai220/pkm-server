-- chunkname: @src.app.views.city.adventure.gym_challenge.embattle1

local ViewBase = cc.load("mvc").ViewBase
local CardEmbattleView = require("app.views.city.card.embattle.base")
local GymChallengeEmbattleView = class("GymChallengeEmbattleView", CardEmbattleView)

GymChallengeEmbattleView.RESOURCE_FILENAME = "gym_embattle1.json"
GymChallengeEmbattleView.RESOURCE_BINDING = {
	battlePanel = "battlePanel",
	bottomPanel = "bottomPanel",
	rightTop = "rightTop",
	["rightTop.imgBg"] = "attrBg",
	aidText = "aidText",
	fightNote = "fightNote",
	["rightTop.textNote"] = "textNote",
	textNotRole = "emptyTxt",
	attrItem = "attrItem",
	spritePanel = "spriteItem",
	rightDown = "rightDown",
	btnGHimg = {
		varname = "btnGHimg",
		binds = {
			class = "buff_arms",
			event = "extend",
			props = {
				redHintTag = "gymChallenge",
				battleCards = bindHelper.self("clientBattleCards"),
				arms = bindHelper.self("selectArms"),
				sceneType = bindHelper.self("sceneType"),
				getCardAttrsEx = bindHelper.self("getCardAttrsEx", true),
				isRefresh = bindHelper.self("isRefresh")
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
	["fightNote.textFightPoint"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("fightSumNum")
		}
	},
	["battlePanel.ahead.txt"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["battlePanel.back.txt"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["rightDown.btnChallenge"] = {
		varname = "btnChallenge",
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {
				ended = bindHelper.self("fightBtn")
			}
		}
	},
	["rightDown.btnChallenge.textNote"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["rightDown.btnSave"] = {
		varname = "btnSave",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("saveBtn")
			}
		}
	},
	["rightDown.btnSave.textNote"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["rightDown.btnOneKeySet"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("oneKeyEmbattleBtn")
			}
		}
	},
	["rightDown.btnOneKeySet.textNote"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["rightTop.arrList"] = {
		varname = "arrList",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("limitInfo"),
				item = bindHelper.self("attrItem"),
				textNote = bindHelper.self("textNote"),
				attrBg = bindHelper.self("attrBg"),
				onItem = function(list, node, k, v)
					node:get("imgIcon"):texture(ui.ATTR_ICON[v])
				end,
				onAfterBuild = function(list)
					local size = list.item:size()
					local count = csvSize(list.data)
					local width = size.width * count + list:getItemsMargin() * (count - 1)

					list:setAnchorPoint(cc.p(1, 0.5))
					list:width(width)
					list:xy(cc.p(600, 50))
					adapt.oneLinePos(list, list.textNote, cc.p(0, 0), "right")
					list.attrBg:width(width + list.textNote:width() + 40)
					list.attrBg:x(list.textNote:x() - 40)
				end
			}
		}
	},
	["textPanel.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("battleNum")
		}
	}
}

function GymChallengeEmbattleView:onCreate(params)
	gGameUI.topuiManager:createView("title", self, {
		onClose = self:createHandler("onClose", false)
	}):init({
		subTitle = "FORMATION",
		title = gLanguageCsv.formation
	})
	self.spriteItem:get("attrBg"):hide()
	self:initDefine(params)
	self:initParams(params)
	self:initModel(params)
	self:initRoundUIPanel()
	self:initHeroSprite()
	self:initBottomList()

	self.haveSaved = false

	if self.from == game.EMBATTLE_FROM_TABLE.gymChallenge then
		local battleCards = self.battleCardsData:read()

		if itertools.size(battleCards) == 0 then
			battleCards = self:getOneKeyCardDatas()

			self.battleCardsData:set(battleCards)
		end
	elseif self.from == game.EMBATTLE_FROM_TABLE.onekey then
		local battleCards, aidCards = self:getOneKeyCardDatas()

		self.battleCardsData:set(battleCards)
		self.aidCards:set(aidCards)
	end

	self:initBattleChange()
end

function GymChallengeEmbattleView:initDefine(params)
	if params.gateId then
		self.embattleMax = csv.gym.gate[params.gateId].deployCardNumLimit
		self.deployType = csv.gym.gate[params.gateId].deployType
	else
		self.embattleMax = 6
		self.deployType = 1
	end

	self.panelNum = 6
	self.gymId = params.gymId
end

function GymChallengeEmbattleView:initParams(params)
	if not params.isCross then
		params.aidNum = 0
	end

	CardEmbattleView.initParams(self, params)

	params = params or {}
	self.from = params.from
	self.sceneType = game.SCENE_TYPE.gym
	self.saveCb = params.saveCb

	if params.gateId then
		self.limitInfo = csv.gym.gate[params.gateId].deployNatureLimit
	else
		self.limitInfo = params.limitInfo
	end
end

function GymChallengeEmbattleView:initRoundUIPanel()
	adapt.centerWithScreen("left", "right", nil, {
		{
			self.fightNote,
			"pos",
			"right"
		},
		{
			self.rightDown,
			"pos",
			"right"
		},
		{
			self.rightTop,
			"pos",
			"right"
		}
	})

	if itertools.size(self.limitInfo) == 0 then
		self.rightTop:hide()
	end

	self.btnChallenge:visible(self.fightCb and true or false)
	self.btnSave:visible(self.saveCb and true or false)
end

function GymChallengeEmbattleView:limtFunc(params)
	local hashMap = itertools.map(self.limitInfo or {}, function(k, v)
		return v, 1
	end)
	local card = gGameModel.cards:find(params.dbid)
	local cardID = card:read("card_id")
	local cardCsv = csv.cards[cardID]
	local unitCsv = csv.unit[cardCsv.unitID]

	if csvSize(self.limitInfo) == 0 or hashMap[unitCsv.natureType] or hashMap[unitCsv.natureType2] then
		return CardEmbattleView.limtFunc(self, params)
	else
		return nil
	end
end

function GymChallengeEmbattleView:saveBtn(node, bCloseView)
	local extra = {
		weather = self.selectWeatherID:read(),
		arms = table.deepcopy(self.selectArms:read(), true)
	}

	self.saveCb(self, self.clientBattleCards, self.battleCardsData, bCloseView, extra, self.aidCards)
end

function GymChallengeEmbattleView:onClose(sendRequeat)
	if sendRequeat ~= true then
		if self.saveCb then
			if not self.haveSaved or not itertools.equal(self.clientBattleCards:read(), self.battleCardsData:read()) then
				local params = {
					clearFast = true,
					btnType = 2,
					cb = function()
						self:saveBtn(nil, true)
					end,
					cancelCb = function()
						ViewBase.onClose(self)
					end,
					content = gLanguageCsv.gymOutCanNotChangeEmbattle
				}

				gGameUI:showDialog(params)
			else
				ViewBase.onClose(self)
			end
		else
			if self.from == game.EMBATTLE_FROM_TABLE.gymChallenge then
				local date = gGameModel.gym:read("date")
				local battleCards = self.clientBattleCards:read()
				local battleCardsHex = {}

				for k, v in pairs(battleCards) do
					battleCardsHex[k] = stringz.bintohex(v)
				end

				userDefault.setForeverLocalKey("gym_emabttle" .. self.gymId, battleCardsHex, {
					new = true
				})

				local selectWeatherID = self.selectWeatherID:read()
				local selectArms = table.deepcopy(self.selectArms:read(), true)

				userDefault.setForeverLocalKey("gym_emabttle_weather" .. self.gymId, selectWeatherID, {
					new = true
				})
				userDefault.setForeverLocalKey("gym_emabttle_arms" .. self.gymId, selectArms, {
					new = true
				})
			end

			ViewBase.onClose(self)
		end
	end
end

return GymChallengeEmbattleView
