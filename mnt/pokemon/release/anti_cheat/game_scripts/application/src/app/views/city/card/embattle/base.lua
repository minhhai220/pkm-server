-- chunkname: @src.app.views.city.card.embattle.base

local ViewBase = cc.load("mvc").ViewBase
local CardEmbattleView = class("CardEmbattleView", ViewBase)
local ITEM_SIZES_POS = {
	{
		pos = cc.p(0, 50),
		size = cc.size(450, 250)
	},
	{
		pos = cc.p(0, 20),
		size = cc.size(500, 250)
	},
	{
		pos = cc.p(0, 20),
		size = cc.size(500, 250)
	},
	{
		pos = cc.p(0, 50),
		size = cc.size(450, 250)
	},
	{
		pos = cc.p(0, 20),
		size = cc.size(500, 250)
	},
	{
		pos = cc.p(0, 20),
		size = cc.size(500, 250)
	}
}
local ZORDER = {
	2,
	4,
	6,
	1,
	3,
	5
}
local FROM_TABLE_FUNC = {
	[game.EMBATTLE_FROM_TABLE.default] = {
		initModelFunc = function(self)
			return gGameModel.role:getIdler("battle_cards")
		end,
		getWeatherID = function(self)
			local battleExtra = gGameModel.role:read("battle_extra") or {}

			return battleExtra.weather or 0
		end,
		getArmsData = function(self)
			local battleExtra = gGameModel.role:read("battle_extra") or {}

			return table.deepcopy(battleExtra.arms or {}, true)
		end,
		getAidData = function(self)
			local aidData = gGameModel.role:read("battle_aid_cards") or {}
			local aidNum = dataEasy.getAidNum(game.GATE_TYPE.normal)

			aidData = dataEasy.fixAidCards(table.deepcopy(aidData, true), aidNum)

			return idlertable.new(aidData), gGameModel.role:getIdler("battle_aid_cards")
		end,
		getAidNum = function(self)
			return dataEasy.getAidNum(game.GATE_TYPE.normal)
		end,
		getSendRequest = function(self)
			if self.clientBattleCards:size() == 0 then
				return
			end

			local selectArms = table.deepcopy(self.selectArms:read(), true)

			return gGameApp:requestServerCustom("/game/battle/card"):params(self.clientBattleCards, {
				weather = self.selectWeatherID:read(),
				arms = selectArms
			}, self.aidCards:read())
		end
	},
	[game.EMBATTLE_FROM_TABLE.arena] = {
		initModelFunc = function(self)
			local battleCards = idlertable.new({})

			idlereasy.when(gGameModel.arena:getIdler("record"), function(_, record)
				local battleCard = {}
				local cards = self.fightCb and record.cards or record.defence_cards

				battleCards:set(cards)
			end)

			return battleCards
		end,
		getWeatherID = function(self)
			local defenceExtra = gGameModel.arena:read("record") and gGameModel.arena:read("record").defence_extra or {}
			local weather = defenceExtra.weather

			if self.fightCb then
				local extra = gGameModel.arena:read("record") and gGameModel.arena:read("record").extra or {}

				weather = extra.weather
			end

			return weather or 0
		end,
		getArmsData = function(self)
			local defenceExtra = gGameModel.arena:read("record") and gGameModel.arena:read("record").defence_extra or {}
			local arms = defenceExtra.arms

			if self.fightCb then
				local extra = gGameModel.arena:read("record") and gGameModel.arena:read("record").extra or {}

				arms = extra.arms
			end

			return table.deepcopy(arms or {}, true)
		end,
		getAidData = function(self)
			local aid = gGameModel.arena:read("record").defence_aid_cards or {}

			if self.fightCb then
				aid = gGameModel.arena:read("record").aid_cards or {}
			end

			local aidNum = dataEasy.getAidNum(game.GATE_TYPE.arena)

			aid = dataEasy.fixAidCards(table.deepcopy(aid, true), aidNum)

			return idlertable.new(aid)
		end,
		getAidNum = function(self)
			return dataEasy.getAidNum(game.GATE_TYPE.arena)
		end,
		getSendRequest = function(self)
			local selectArms = table.deepcopy(self.selectArms:read(), true)
			local selectWeatherID = self.selectWeatherID:read()

			if self.fightCb then
				return gGameApp:requestServerCustom("/game/pw/battle/deploy"):params(self.clientBattleCards, nil, {
					weather = selectWeatherID,
					arms = selectArms
				}, nil, self.aidCards:read())
			else
				return gGameApp:requestServerCustom("/game/pw/battle/deploy"):params(nil, self.clientBattleCards, nil, {
					weather = selectWeatherID,
					arms = selectArms
				}, nil, self.aidCards:read())
			end
		end
	},
	[game.EMBATTLE_FROM_TABLE.huodong] = {
		initModelFunc = function(self)
			local battleCards = idlertable.new({})

			idlereasy.when(gGameModel.role:getIdler("huodong_cards"), function(_, huodong_cards)
				if not huodong_cards[self.fromId] then
					local originBattleCards = gGameModel.role:read("battle_cards")
					local cardsTb = {}

					for k, dbid in pairs(originBattleCards) do
						local card = gGameModel.cards:find(dbid)

						if card then
							local rTb = self:limtFunc({
								inBattle = 0,
								dbid = dbid
							})

							if rTb then
								cardsTb[k] = dbid
							end
						end
					end

					battleCards:set(cardsTb)
				else
					battleCards:set(huodong_cards[self.fromId])
				end
			end)

			return battleCards
		end,
		getWeatherID = function(self)
			local battleExtra = gGameModel.role:read("huodong_extra") and gGameModel.role:read("huodong_extra")[self.fromId] or {}
			return battleExtra.weather or 0
		end,
		getArmsData = function(self)
			local battleExtra = gGameModel.role:read("huodong_extra") and gGameModel.role:read("huodong_extra")[self.fromId] or {}

			return table.deepcopy(battleExtra.arms or {}, true)
		end,
		getAidData = function(self)
			-- if self.fromId == game.EMBATTLE_HOUDONG_ID.nightmare or self.fromId == game.EMBATTLE_HOUDONG_ID.worldBoss then
			-- 	local aidBattleCards = {}

			-- 	idlereasy.when(gGameModel.role:getIdler("huodong_aid_cards"), function(_, huodong_cards)
			-- 		if not huodong_cards[self.fromId] then
			-- 			local originAidBattleCards = gGameModel.role:read("battle_aid_cards") or {}
			-- 			local cardsTb = {}

			-- 			for k, dbid in pairs(originAidBattleCards) do
			-- 				local card = gGameModel.cards:find(dbid)

			-- 				if card then
			-- 					local rTb = self:limtFunc({
			-- 						inBattle = 1,
			-- 						dbid = dbid
			-- 					})

			-- 					if rTb then
			-- 						cardsTb[k] = dbid
			-- 					end
			-- 				end
			-- 			end

			-- 			aidBattleCards = cardsTb
			-- 		else
			-- 			aidBattleCards = huodong_cards[self.fromId]
			-- 		end
			-- 	end)

			-- 	local aidNum = 0

			-- 	if self.fromId == game.EMBATTLE_HOUDONG_ID.nightmare then
			-- 		aidNum = dataEasy.getAidNum(game.GATE_TYPE.normal)
			-- 	end

			-- 	if self.fromId == game.EMBATTLE_HOUDONG_ID.worldBoss then
			-- 		aidNum = dataEasy.getAidNum(game.GATE_TYPE.worldBoss)
			-- 	end

			-- 	aidBattleCards = dataEasy.fixAidCards(table.deepcopy(aidBattleCards, true), aidNum)

			-- 	return idlertable.new(aidBattleCards)
			-- end

			return idlertable.new({})
		end,
		getAidNum = function(self)
			if self.fromId == game.EMBATTLE_HOUDONG_ID.nightmare then
				return dataEasy.getAidNum(game.GATE_TYPE.normal)
			end

			if self.fromId == game.EMBATTLE_HOUDONG_ID.worldBoss then
				return dataEasy.getAidNum(game.GATE_TYPE.worldBoss)
			end

			return 0
		end,
		getSendRequest = function(self)
			local selectArms = table.deepcopy(self.selectArms:read(), true)

			return gGameApp:requestServerCustom("/game/huodong/card"):params(self.fromId, self.clientBattleCards, {
				weather = self.selectWeatherID:read(),
				arms = selectArms
			}, self.aidCards:read())
		end
	},
	[game.EMBATTLE_FROM_TABLE.input] = {
		initModelFunc = function(self)
			return self.inputCards
		end,
		getWeatherID = function(self)
			return nil
		end,
		getArmsData = function(self)
			return nil
		end,
		getAidData = function(self)
			return idlertable.new({})
		end,
		getAidNum = function(self)
			return 0
		end,
		getSendRequest = function(self)
			return
		end
	},
	[game.EMBATTLE_FROM_TABLE.gymChallenge] = {
		initModelFunc = function(self)
			local gymbattleCards = userDefault.getForeverLocalKey("gym_emabttle" .. self.gymId, {})

			gymbattleCards = dataEasy.fixInMeteorCards(gymbattleCards)

			local function checkError()
				local hash = {}

				for _, id in pairs(gymbattleCards) do
					if hash[id] then
						return true
					end

					hash[id] = true
				end

				return false
			end

			if itertools.size(gymbattleCards) == 0 or checkError() then
				local cardDatas = gGameModel.role:read("battle_cards")

				return idlertable.new(table.shallowcopy(cardDatas))
			else
				local myCards = gGameModel.role:read("cards")
				local cardDatas = {}
				local hash = itertools.map(myCards, function(k, v)
					return v, k
				end)

				for k, hexdbid in pairs(gymbattleCards) do
					local dbid = stringz.hextobin(hexdbid)

					if hash[dbid] then
						cardDatas[k] = dbid
					end
				end

				return idlertable.new(cardDatas)
			end
		end,
		getWeatherID = function(self)
			local weather = userDefault.getForeverLocalKey("gym_emabttle_weather" .. self.gymId, 0)

			return weather
		end,
		getArmsData = function(self)
			local arms = userDefault.getForeverLocalKey("gym_emabttle_arms" .. self.gymId, {})

			return arms
		end,
		getAidData = function(self)
			return idlertable.new({})
		end,
		getAidNum = function(self)
			return 0
		end,
		getSendRequest = function(self)
			return
		end
	},
	[game.EMBATTLE_FROM_TABLE.onekey] = {
		initModelFunc = function(self)
			return idlertable.new({})
		end,
		getWeatherID = function(self)
			if self.deployType ~= 2 then
				if self.deployType == 3 then
					return {}
				end

				return 0
			end

			return nil
		end,
		getArmsData = function(self)
			if self.deployType ~= 2 then
				return {}
			end

			return nil
		end,
		getAidData = function(self)
			return idlertable.new({})
		end,
		getAidNum = function(self)
			if self.deployType == 1 and self.fromId == game.EMBATTLE_GYMCHALLENGE_ID.pvp then
				return dataEasy.getAidNum(game.GATE_TYPE.crossGym)
			end

			return 0
		end,
		getSendRequest = function(self)
			return
		end
	},
	[game.EMBATTLE_FROM_TABLE.onlineFight] = {
		initModelFunc = function(self)
			return gGameModel.cross_online_fight:getIdler("cards")
		end,
		getWeatherID = function(self)
			local battleExtra = gGameModel.cross_online_fight:read("extra") or {}

			return battleExtra.weather or 0
		end,
		getArmsData = function(self)
			local battleExtra = gGameModel.cross_online_fight:read("extra") or {}

			return table.deepcopy(battleExtra.arms or {}, true)
		end,
		getAidData = function(self)
			local aidData = gGameModel.cross_online_fight:read("aid_cards") or {}
			local aidNum = dataEasy.getAidNum(game.GATE_TYPE.crossOnlineFight)

			aidData = dataEasy.fixAidCards(table.deepcopy(aidData, true), aidNum)

			return idlertable.new(aidData)
		end,
		getAidNum = function(self)
			return dataEasy.getAidNum(game.GATE_TYPE.crossOnlineFight)
		end,
		getSendRequest = function(self)
			local selectArms = table.deepcopy(self.selectArms:read(), true)
			local extra = {
				weather = self.selectWeatherID:read(),
				arms = selectArms
			}

			return gGameApp:requestServerCustom("/game/cross/online/deploy"):params(self.clientBattleCards, nil, 1, extra, self.aidCards:read())
		end
	},
	[game.EMBATTLE_FROM_TABLE.huodongBoss] = {
		initModelFunc = function(self)
			local huodongBossBattleCards = userDefault.getForeverLocalKey("huodongboss_emabttle", {})

			huodongBossBattleCards = dataEasy.fixInMeteorCards(huodongBossBattleCards)

			if huodongBossBattleCards == nil or itertools.size(huodongBossBattleCards) == 0 then
				local cardDatas = gGameModel.role:read("battle_cards")

				return idlertable.new(table.shallowcopy(cardDatas))
			else
				local myCards = gGameModel.role:read("cards")
				local cardDatas = {}
				local hash = itertools.map(myCards, function(k, v)
					return v, k
				end)

				for k, hexdbid in pairs(huodongBossBattleCards) do
					local dbid = stringz.hextobin(hexdbid)

					if hash[dbid] then
						cardDatas[k] = dbid
					end
				end

				return idlertable.new(cardDatas)
			end
		end,
		getWeatherID = function(self)
			local weather = userDefault.getForeverLocalKey("huodongboss_emabttle_weather", 0)

			return weather
		end,
		getArmsData = function(self)
			local arms = userDefault.getForeverLocalKey("huodongboss_emabttle_arms", {})

			return arms
		end,
		getAidData = function(self)
			return idlertable.new({})
		end,
		getAidNum = function()
			return 0
		end,
		getSendRequest = function(self)
			return
		end
	},
	[game.EMBATTLE_FROM_TABLE.ready] = {
		initModelFunc = function(self)
			return self.inputCards
		end,
		getWeatherID = function(self)
			return self.inputExtra and self.inputExtra.weather or 0
		end,
		getArmsData = function(self)
			return self.inputExtra and self.inputExtra.arms or {}
		end,
		getAidData = function(self)
			local inputAidCards = dataEasy.fixAidCards(table.deepcopy(self.inputAidCards:read(), true), self.inputAidNum)

			return idlertable.new(inputAidCards)
		end,
		getAidNum = function(self)
			return self.inputAidNum
		end,
		getSendRequest = function(self)
			return
		end
	},
	[game.EMBATTLE_FROM_TABLE.hunting] = {
		initModelFunc = function(self)
			local battleCards = gGameModel.hunting:read("hunting_route")[self.route].cards or {}
			local cardStates = gGameModel.hunting:read("hunting_route")[self.route].card_states or {}

			if itertools.size(cardStates) == 0 then
				local cardDatas = table.deepcopy(gGameModel.role:read("battle_cards"), true)

				for k, dbid in pairs(cardDatas) do
					local card = gGameModel.cards:find(dbid)

					if card and card:read("level") < 10 then
						cardDatas[k] = nil
					end
				end

				return idlertable.new(table.shallowcopy(cardDatas))
			else
				local myCards = gGameModel.role:read("cards")
				local cardDatas = {}
				local hash = itertools.map(myCards, function(k, v)
					return v, k
				end)

				for k, dbid in pairs(battleCards) do
					if hash[dbid] then
						cardDatas[k] = dbid
					end
				end

				return idlertable.new(cardDatas)
			end
		end,
		getWeatherID = function(self)
			local battleExtra = gGameModel.hunting:read("hunting_route")[self.route].extra or {}

			return battleExtra.weather or 0
		end,
		getArmsData = function(self)
			local battleExtra = gGameModel.hunting:read("hunting_route")[self.route].extra or {}

			return table.deepcopy(battleExtra.arms or {}, true)
		end,
		getAidData = function(self)
			local cardStates = gGameModel.hunting:read("hunting_route")[self.route].card_states or {}
			local cardDatas = {}

			if itertools.size(cardStates) ~= 0 then
				local aidData = gGameModel.hunting:read("hunting_route")[self.route].aid_cards or {}
				local myCards = gGameModel.role:read("cards")
				local hash = itertools.map(myCards, function(k, v)
					return v, k
				end)

				for k, dbid in pairs(aidData) do
					if hash[dbid] then
						cardDatas[k] = dbid
					end
				end
			end

			local aidNum = dataEasy.getAidNum(game.GATE_TYPE.hunting)

			cardDatas = dataEasy.fixAidCards(table.deepcopy(cardDatas, true), aidNum)

			return idlertable.new(cardDatas)
		end,
		getAidNum = function(self)
			return dataEasy.getAidNum(game.GATE_TYPE.hunting)
		end,
		getSendRequest = function(self)
			local selectArms = table.deepcopy(self.selectArms:read(), true)
			local selectWeatherID = self.selectWeatherID:read()
			local node = gGameModel.hunting:read("hunting_route")[self.route].node or 1

			return gGameApp:requestServerCustom("/game/hunting/battle/deploy"):params(self.route, node, self.clientBattleCards, {
				weather = self.selectWeatherID:read(),
				arms = selectArms
			}, self.aidCards:read())
		end
	},
	[game.EMBATTLE_FROM_TABLE.crossCircus] = {
		initModelFunc = function(self)
			return idlertable.new({})
		end,
		getWeatherID = function(self)
			return 0
		end,
		getArmsData = function(self)
			return {}
		end,
		getAidData = function(self)
			return idlertable.new({})
		end,
		getAidNum = function(self)
			return 0
		end,
		getSendRequest = function(self)
			return
		end
	}
}

local function getFuncFormTableResult(self, key, ...)
	local tb = FROM_TABLE_FUNC[self.from]
	local defaultTb = FROM_TABLE_FUNC[game.EMBATTLE_FROM_TABLE.default]
	local func = tb[key] or defaultTb[key]

	return func(self, ...)
end

CardEmbattleView.RESOURCE_FILENAME = "card_embattle.json"
CardEmbattleView.RESOURCE_BINDING = {
	bottomMask = "bottomMask",
	bottomPanel = "bottomPanel",
	textLimit = "textLimit",
	aidText = "aidText",
	rightDown = "rightDown",
	fightNote = "fightNote",
	textNotRole = "emptyTxt",
	dailyGateTipsPos = "dailyGateTipsPos",
	spritePanel = "spriteItem",
	battlePanel = "battlePanel",
	btnGHimg = {
		varname = "btnGHimg",
		binds = {
			event = "extend",
			class = "buff_arms",
			props = {
				battleCards = bindHelper.self("clientBattleCards"),
				arms = bindHelper.self("selectArms"),
				sceneType = bindHelper.self("sceneType"),
				getCardAttrsEx = bindHelper.self("getCardAttrsEx", true),
				isRefresh = bindHelper.self("isRefresh"),
				redHintTag = bindHelper.self("redHintTag")
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
	btnJump = {
		varname = "btnJump",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("cardBagBtn")
			}
		}
	},
	btnChallenge = {
		varname = "btnChallenge",
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {
				ended = bindHelper.self("fightBtn")
			}
		}
	},
	["fightNote.textFightPoint"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("fightSumNum")
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
	["btnJump.textNote"] = {
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
	},
	["rightDown.btnOneKeySet"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("oneKeyEmbattleBtn")
			}
		}
	},
	["rightDown.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("battleNum")
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
	btnReady = {
		varname = "btnReady",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("oneReadyBtn")
			}
		}
	},
	["btnReady.textNote"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["rightDown.btnSaveReady"] = {
		varname = "btnSaveReady",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("oneSaveReadyBtn")
			}
		}
	},
	["rightDown.btnSaveReady.textNote"] = {
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

function CardEmbattleView:onCreate(params)
	params = params or {}

	self.spriteItem:get("attrBg"):hide()
	self:initDefine()
	self.btnJump:z(5)

	self.topuiView = gGameUI.topuiManager:createView("title", self, {
		onClose = self:createHandler("onClose", true)
	}):init({
		subTitle = "FORMATION",
		title = params.readyIdx and gLanguageCsv.presetFormation or gLanguageCsv.formation
	})

	self:initParams(params)
	self:initModel(params)
	self:initReadTeam(params)
	self:initBottomList()
	self:initRoundUIPanel()
	self:initHeroSprite()
	self:initBattleChange()

	if self.startCb then
		local battleCards = self.startCb(self)

		if battleCards then
			battleCards = dataEasy.fixEmattleCards(battleCards, true)

			self.clientBattleCards:set(battleCards)
		end
	end
end

function CardEmbattleView:initDefine()
	self.embattleMax = 6
	self.panelNum = 6
end

function CardEmbattleView:initParams(params)
	self.params = params
	self.route = params.route
	self.inputCards = params.inputCards
	self.inputExtra = params.inputExtra
	self.inputAidCards = params.inputAidCards
	self.inputAidNum = params.aidNum
	self.sceneType = params.sceneType or -1
	self.from = params.from or game.EMBATTLE_FROM_TABLE.default
	self.fightCb = params.fightCb
	self.fromId = params.fromId
	self.startCb = params.startCb
	self.checkBattleArr = params.checkBattleArr or function()
		return true
	end
	self.redHintTag = string.format("%s_%s", self.from, self.fromId or "")
	self.aidNum = 0
	self.aidNumMax = 0
	self.aidCards = idlertable.new({})
	self.originAidCards = idlertable.new({})

	if not params.skipAidUnlock then
		adapt.centerWithScreen("left", "right", nil, {
			{
				self.battlePanel:get("aid1"),
				"pos",
				"left"
			},
			{
				self.battlePanel:get("aid2"),
				"pos",
				"left"
			},
			{
				self.battlePanel:get("aid3"),
				"pos",
				"left"
			},
			{
				self.battlePanel:get("aid4"),
				"pos",
				"left"
			},
			{
				self.battlePanel:get("aid5"),
				"pos",
				"left"
			}
		})

		self.roleLevel = gGameModel.role:getIdler("level")

		dataEasy.getListenUnlock(gUnlockCsv.aid, function(isUnlock)
			idlereasy.when(self.roleLevel, function()
				if params.aidNum then
					self.aidNum = params.aidNum
					self.aidUnlockLevel = params.aidUnlockLevel or {}
				else
					local aidNum, aidUnlockLevel = getFuncFormTableResult(self, "getAidNum")

					self.aidNum = isUnlock and aidNum or 0
					self.aidUnlockLevel = isUnlock and aidUnlockLevel or {}
				end

				self.aidNumMax = csvSize(self.aidUnlockLevel)

				self:refreshAidUI(isUnlock)
			end):anonyOnly(self)
		end)
	else
		self:refreshAidUI(false)
	end

	local textTip = self:getResourceNode("textTip")

	if textTip then
		textTip:x(textTip:x() + 140)
	end
end

function CardEmbattleView:initBottomList(name, params, extraParams)
	extraParams = extraParams or {}

	local data = {
		base = self,
		clientBattleCards = self.clientBattleCards,
		battleCardsData = self.battleCardsData,
		deleteMovingItem = self.deleteMovingItem,
		createMovePanel = self.createMovePanel,
		moveMovePanel = self.moveMovePanel,
		isMovePanelExist = self.isMovePanelExist,
		onCardClick = self.onCardClick,
		allCardDatas = self.allCardDatas,
		moveEndMovePanel = self.moveEndMovePanel,
		sortSign = self.sortSign,
		limtFunc = self.limtFunc,
		aidCards = self.aidCards,
		originAidCards = self.originAidCards
	}

	for k, v in pairs(params or {}) do
		data[k] = v
	end

	local bAdaptUi = true

	if extraParams.bAdaptUi ~= nil then
		bAdaptUi = extraParams.bAdaptUi
	end

	self.cardListView = gGameUI:createView(name or "city.card.embattle.embattle_card_list", self.bottomPanel):init(data, bAdaptUi)
end

function CardEmbattleView:getCardAttr(dbid, attrString)
	return gGameModel.cards:find(dbid):read(attrString)
end

function CardEmbattleView:initModel()
	self.cards = gGameModel.role:getIdler("cards")
	self.allCardDatas = idlers.newWithMap({})
	self.battleCardsData = getFuncFormTableResult(self, "initModelFunc")
	self.clientBattleCards = idlertable.new({})
	self.fightSumNum = idler.new(0)
	self.battleNum = idler.new("")
	self.selectIndex = idler.new()

	local aidIdler

	self.aidCards, aidIdler = getFuncFormTableResult(self, "getAidData")
	self.originAidCards = idlertable.new(table.deepcopy(self.aidCards:read(), true))
	self.draggingIndex = idler.new(0)
	self.selectWeatherID = getFuncFormTableResult(self, "getWeatherID")
	self.originWeatherID = self.selectWeatherID
	self.selectWeatherID = idlereasy.new(self.selectWeatherID)
	self.selectArms = getFuncFormTableResult(self, "getArmsData")
	self.originArms = self.selectArms
	self.selectArms = idlereasy.new(table.deepcopy(self.selectArms, true))
	self.isRefresh = idler.new(true)

	local datas = {}
	local datasCount = 0

	idlereasy.when(self.battleCardsData, function(_, battleCards)
		datas = {}
		datasCount = itertools.size(battleCards)

		for i, v in pairs(battleCards) do
			local card = gGameModel.cards:find(v)

			if card then
				local cardData = card:multigetIdler("card_id")

				idlereasy.when(cardData, function(_, card_id)
					datas[i] = true

					if itertools.size(datas) == datasCount then
						local clientBattleCards = battleCards

						if self.from ~= game.EMBATTLE_FROM_TABLE.input then
							clientBattleCards = dataEasy.fixEmattleCards(battleCards)
						end

						self.clientBattleCards:set(clientBattleCards, true)
					end
				end):anonyOnly(self, stringz.bintohex(v))
			end
		end
	end)

	if aidIdler then
		idlereasy.when(aidIdler, function(_, aidCards)
			self.originAidCards:set(aidCards)
		end)
	end
end

function CardEmbattleView:getFightSumNum(battle, aidCards)
	battle = battle or self.clientBattleCards:read()
	aidCards = aidCards or self.aidCards:read()

	local fightSumNum = 0

	for k, v in pairs(battle) do
		local fightPoint = self:getCardAttr(v, "fighting_point")

		fightSumNum = fightSumNum + fightPoint
	end

	for k, v in pairs(aidCards) do
		local fightPoint = self:getCardAttr(v, "aid_fighting_point") or 0

		fightSumNum = fightSumNum + fightPoint
	end

	return fightSumNum
end

function CardEmbattleView:sendRequeat(cb, isClose)
	local equality = itertools.equal(self.battleCardsData:read(), self.clientBattleCards:read())
	local aidEquality = itertools.equal(self.originAidCards:read(), self.aidCards:read())
	local selectArms = table.deepcopy(self.selectArms:read(), true)

	if not equality or not aidEquality or not itertools.equal(self.originWeatherID, self.selectWeatherID:read()) or not itertools.equal(self.originArms or {}, selectArms or {}) then
		if self.clientBattleCards:size() == 0 and not itertools.include({
			game.EMBATTLE_FROM_TABLE.default,
			game.EMBATTLE_FROM_TABLE.ready
		}, self.from) then
			gGameUI:showTip(gLanguageCsv.embattleEmptyTip)

			return
		end

		local result = self.checkBattleArr(self.clientBattleCards:read())

		if not result then
			if isClose then
				cb()
			else
				gGameUI:showTip(gLanguageCsv.lineupInconsistency)
			end

			return
		end

		local req = getFuncFormTableResult(self, "getSendRequest")

		if not req then
			return cb()
		end

		if isClose then
			req:onBeforeSync(cb):doit()
		else
			req:doit(cb)
		end
	else
		cb()
	end
end

function CardEmbattleView:initRoundUIPanel()
	adapt.centerWithScreen("left", "right", nil, {
		{
			self.fightNote,
			"pos",
			"right"
		},
		{
			self.btnChallenge,
			"pos",
			"right"
		},
		{
			self.btnJump,
			"pos",
			"right"
		},
		{
			self.rightDown,
			"pos",
			"right"
		},
		{
			self.aidText,
			"pos",
			"left"
		}
	})

	local showFightBtn = self.fightCb and true or false

	self.rightDown:visible(not showFightBtn)
	self.btnChallenge:visible(showFightBtn)
	self.btnJump:visible(self.from == game.EMBATTLE_FROM_TABLE.default)
end

function CardEmbattleView:initReadTeam(params)
	self.readyIdx = params.readyIdx

	if self.readyIdx then
		self.btnSaveReady:visible(true)
	end

	local showTeam = params.team and true or false
	local isUnlock = dataEasy.isShow(gUnlockCsv.readyTeam)

	self.btnReady:visible(isUnlock)

	if isUnlock then
		self.btnReady:visible(self.from == game.EMBATTLE_FROM_TABLE.default or self.from == game.EMBATTLE_FROM_TABLE.onlineFight or showTeam)
	end

	uiEasy.updateUnlockRes(gUnlockCsv.readyTeam, self.btnReady, {
		pos = cc.p(285, 102)
	})
end

function CardEmbattleView:embattleBtnFunc(hash, v)
	local key = self:getKey(v)
	local cardID = self:getCardAttr(key, "card_id")
	local cardCsv = csv.cards[cardID]
	local mergeInfo = dataEasy.getCardMergeInfo()
	local hash1 = dataEasy.getHashMarkIDs(cardID)

	return not v.inMeteor and not mergeInfo.mergeAB[v.dbid] and not mergeInfo.relieveC[v.dbid] and itertools.isempty(maptools.intersection({
		hash,
		hash1
	}))
end

function CardEmbattleView:getOneKeyCardDatas()
	local cardDatas = {}

	for _, v in self.allCardDatas:pairs() do
		table.insert(cardDatas, v:read())
	end

	table.sort(cardDatas, function(a, b)
		if a.fighting_point == b.fighting_point then
			return a.rarity > b.rarity
		else
			return a.fighting_point > b.fighting_point
		end
	end)

	local hash = {}
	local newBattleCards = {}
	local newAidCards = {}
	local i = 0

	for _, v in ipairs(cardDatas) do
		local key = self:getKey(v)
		local cardID = self:getCardAttr(key, "card_id")
		local cardCsv = csv.cards[cardID]

		if self:embattleBtnFunc(hash, v) then
			local hash1 = dataEasy.getHashMarkIDs(cardID)

			maptools.union_with(hash, hash1)

			if i < self.embattleMax then
				i = i + 1
				newBattleCards[i] = key
			elseif i < self.embattleMax + self.aidNum then
				if dataEasy.isOpenAid(nil, v.dbid, true) then
					i = i + 1
					newAidCards[i - self.embattleMax] = v.dbid
				end
			else
				break
			end
		end
	end

	return newBattleCards, newAidCards
end

function CardEmbattleView:oneKeyEmbattleBtn()
	local onekeyDatas, onekeyAidDatas = self:getOneKeyCardDatas()

	self.clientBattleCards:set(onekeyDatas)

	if self.aidCards then
		self.aidCards:set(onekeyAidDatas or {})
	end
end

function CardEmbattleView:initBattleChange()
	idlereasy.when(self.clientBattleCards, function(_, battle)
		self:refreshTeamWeather(battle)
	end)
	idlereasy.when(self.selectWeatherID, function(_, selectWeatherID)
		if self.btnWeather then
			if self.originWeatherID == nil or not selectWeatherID or selectWeatherID == 0 then
				self.btnWeather:hide()
			else
				self.btnWeather:show()
				self.btnWeather:get("icon"):texture(csv.weather_system.weather[selectWeatherID].iconRes)
			end
		else
			printWarn("CardEmbattleView.btnWeather not exist")
		end
	end)
end

function CardEmbattleView:initHeroSprite()
	self.heroSprite = {}

	for i = 1, self.panelNum do
		local tmpPanel = self.spriteItem:clone():addTo(self.battlePanel, 10 + ZORDER[i], "panel" .. i)

		tmpPanel:show()
		tmpPanel:get("imgBg"):hide()

		local posx, posy = self.battlePanel:get("item" .. i):xy()

		self.heroSprite[i] = {
			sprite = tmpPanel,
			posx = posx,
			posy = posy,
			node = self.battlePanel:get("item" .. i),
			idx = i
		}
	end

	for i = 1, self.panelNum do
		local itemPos = self.battlePanel:get("item" .. i, "pos")

		if ITEM_SIZES_POS[i] then
			local size = ITEM_SIZES_POS[i].size
			local pos = ITEM_SIZES_POS[i].pos
			local widthRatio = display.sizeInView.width / display.size.width
			local heightRatio = display.sizeInView.height / display.size.height
			local newSize = cc.size(widthRatio * size.width, heightRatio * size.height)
			local newPos = cc.p(widthRatio * pos.x, heightRatio * pos.y)
			local item = self.battlePanel:get("item" .. i)

			itemPos:size(newSize):xy(item:size().width / 2 + newPos.x, item:size().height / 2 + newPos.y)
		end

		itemPos:onTouch(functools.partial(self.onBattleCardTouch, self, i))
	end

	for j = 1, math.huge do
		local idx = self.panelNum + j
		local item = self.battlePanel:get("aid" .. j)

		if item then
			local posx, posy = item:xy()

			item:get("icon"):setTouchEnabled(false)
			item:setTouchEnabled(true)

			self.heroSprite[idx] = {
				item = item,
				sprite = item:get("icon"),
				addIcon = item:get("addIcon"),
				posx = posx,
				posy = posy,
				node = self.battlePanel:get("aid" .. j),
				idx = idx
			}

			item:onTouch(functools.partial(self.onBattleCardTouch, self, idx))
		else
			break
		end
	end

	idlereasy.any({
		self.clientBattleCards,
		self.isRefresh
	}, function(_, battle)
		local battleNum = 0

		for i = 1, self.panelNum do
			local spriteTb = self.heroSprite[i]
			local idx = spriteTb.idx

			spriteTb.sprite:xy(spriteTb.posx, spriteTb.posy):z(10 + ZORDER[i])

			local fightPointText = spriteTb.sprite:get("fightPoint")
			local attrPanel = spriteTb.sprite:get("attrBg")

			attrPanel:hide()

			if battle[i] then
				local dbid = battle[i]

				if dbid and self:getCardAttrs(dbid) then
					battleNum = battleNum + 1

					local card_id = self:getCardAttr(dbid, "card_id")
					local skin_id = self:getCardAttr(dbid, "skin_id")
					local unitCsv = dataEasy.getUnitCsv(card_id, skin_id)
					local dbdata = {
						dbid = dbid,
						card_id = card_id,
						skin_id = skin_id
					}

					if not spriteTb.dbdata or not itertools.equal(spriteTb.dbdata, dbdata) then
						spriteTb.sprite:get("icon"):removeAllChildren()

						local cardSprite = widget.addAnimation(spriteTb.sprite:get("icon"), unitCsv.unitRes, "standby_loop", 11):scale(unitCsv.scale):xy(50, 50)

						cardSprite:setSkin(unitCsv.skin)

						spriteTb.dbdata = dbdata

						if self.showItemFightPoint then
							self:showItemFightPoint(fightPointText, unitCsv, dbid)
						end
					end

					local teamBuffs = self.btnGHimg and self.btnGHimg.teamBuffs

					if teamBuffs then
						local flags = teamBuffs.flags or {
							1,
							1,
							1,
							1,
							1,
							1
						}

						uiEasy.setTeamBuffItem(spriteTb.sprite, card_id, flags[i])
					end
				end
			elseif spriteTb.dbdata then
				spriteTb.sprite:get("icon"):removeAllChildren()

				spriteTb.dbdata = nil

				fightPointText:hide()
			end
		end

		self.battleNum:set(battleNum .. "/" .. self.embattleMax)
		self.fightSumNum:set(self:getFightSumNum())
	end)

	self.roleLevel = gGameModel.role:getIdler("level")

	idlereasy.any({
		self.aidCards,
		self.roleLevel
	}, function(_, aidCards, roleLevel)
		for i = 1, self.aidNumMax or self.aidNum do
			local idx = self.panelNum + i
			local item = self.heroSprite[idx]

			item.sprite:hide()
			item.addIcon:hide()
			item.addIcon:parent():removeChildByName("unlockRes")

			if aidCards and aidCards[i] then
				local dbid = aidCards[i]

				if dbid and self:getCardAttrs(dbid) then
					local card_id = self:getCardAttr(dbid, "card_id")
					local skin_id = self:getCardAttr(dbid, "skin_id")
					local unitCsv = dataEasy.getUnitCsv(card_id, skin_id)

					item.sprite:texture(unitCsv.iconSimple):show()
				end
			elseif roleLevel >= self.aidUnlockLevel[i] then
				item.addIcon:show()
			else
				ccui.ImageView:create("common/btn/btn_zz_lock.png"):addTo(item.addIcon:parent(), 5, "unlockRes"):xy(item.addIcon:xy())
			end
		end

		self.fightSumNum:set(self:getFightSumNum())
	end)
	idlereasy.when(self.draggingIndex, function(_, index)
		for i = 1, self.panelNum do
			local heroSprite = self.heroSprite[i].sprite:get("icon"):getChildren()

			if heroSprite[1] then
				heroSprite[1]:setCascadeOpacityEnabled(true)

				if index == 0 then
					heroSprite[1]:opacity(255)
				elseif index == -1 then
					heroSprite[1]:opacity(155)
				elseif index == i then
					heroSprite[1]:opacity(255)
				else
					heroSprite[1]:opacity(155)
				end
			end
		end
	end)
	self:initSelectHalo()
end

function CardEmbattleView:refreshAidUI(isUnlock)
	if not isUnlock then
		for i = 1, math.huge do
			local item = self.battlePanel:get("aid" .. i)

			if item then
				item:hide()
			else
				break
			end
		end

		if self.aidText then
			self.aidText:hide()
		end

		return
	end

	self.aidText:visible(self.aidNumMax > 0)

	if self.aidNumMax <= 0 then
		if not self.btnWeatherOriginX then
			self.btnWeatherOriginX = self.btnWeather:x()
			self.btnGHimgOriginX = self.btnGHimg:x()
		end

		self.btnWeather:x(self.btnWeatherOriginX - 150)
		self.btnGHimg:x(self.btnGHimgOriginX - 150)
	end

	if self.aidNumMax <= 3 then
		for i = 1, math.huge do
			local node = self.battlePanel:get("aid" .. i)

			if node then
				if not node.originX then
					node.originX = node:x()
				end

				if i <= self.aidNumMax then
					node:x(node.originX - node:width() / 2)
				else
					node:hide()
				end
			else
				break
			end
		end
	else
		for i = self.aidNumMax + 1, math.huge do
			local item = self.battlePanel:get("aid" .. i)

			if item then
				item:hide()
			else
				break
			end
		end
	end
end

function CardEmbattleView:initSelectHalo()
	for i = 1, self.panelNum do
		local panel = self.battlePanel:get("item" .. i)
		local size = panel:size()
		local scale = ((i > 3 and i - 3 or i) + 7) / 10
		local anchorPoint = panel:anchorPoint()
		local imgSel = widget.addAnimationByKey(panel, "effect/buzhen2.skel", "imgSel", "effect_loop", 2):xy(panel:width() * anchorPoint.x, panel:height() * anchorPoint.y):scale(scale):hide()
	end

	idlereasy.when(self.selectIndex, function(_, selectIndex)
		for i = 1, self.panelNum do
			local panel = self.battlePanel:get("item" .. i)

			panel:get("imgSel"):visible(selectIndex == i)
			panel:get("imgBg"):visible(selectIndex ~= i)
		end
	end)
end

function CardEmbattleView:createMovePanel(data)
	if self.movePanel then
		self.movePanel:removeSelf()
	end

	local unitCsv = csv.unit[data.unit_id]
	local movePanel = self.spriteItem:clone():addTo(self:getResourceNode(), 1000)

	movePanel:show()

	local size = movePanel:get("icon"):size()
	local cardSprite = widget.addAnimationByKey(movePanel:get("icon"), unitCsv.unitRes, "hero", "run_loop", 1000):scale(unitCsv.scale):alignCenter(size)

	cardSprite:setSkin(unitCsv.skin)
	widget.addAnimationByKey(movePanel:get("icon"), "effect/buzhen.skel", "effect", "effect_loop", 1002):scale(1):alignCenter(size)

	self.movePanel = movePanel

	self.draggingIndex:set(-1)

	local simpleShow = unitCsv.iconSimple
	local cardPanel = ccui.ImageView:create(simpleShow):scale(2):xy(movePanel:get("icon"):xy()):addTo(movePanel, 1, "cardPanel")

	nodetools.invoke(self.movePanel, {
		"imgBg",
		"cardPanel"
	}, "hide")

	return movePanel
end

function CardEmbattleView:deleteMovingItem()
	self.selectIndex:set(0)

	if self.movePanel then
		self.movePanel:removeSelf()

		self.movePanel = nil
	end

	self.draggingIndex:set(0)
end

function CardEmbattleView:moveMovePanel(event)
	if self.movePanel then
		self.movePanel:xy(event)
		self.selectIndex:set(self:whichEmbattleTargetPos(event))

		if (self.aidNumMax or self.aidNum) > 0 then
			self:updShowPanel(event)
		end
	end
end

function CardEmbattleView:updShowPanel(event)
	if event.x < 500 + display.uiOrigin.x then
		nodetools.invoke(self.movePanel, {
			"imgBg",
			"icon"
		}, "hide")
		nodetools.invoke(self.movePanel, {
			"cardPanel"
		}, "show")
	else
		nodetools.invoke(self.movePanel, {
			"imgBg",
			"icon"
		}, "show")
		nodetools.invoke(self.movePanel, {
			"cardPanel"
		}, "hide")
	end
end

function CardEmbattleView:moveEndMovePanel(data)
	if not self.movePanel then
		return
	end

	local index = self.selectIndex:read()

	self:onCardMove(data, index, true)
	self:deleteMovingItem()
end

function CardEmbattleView:isMovePanelExist()
	return self.movePanel ~= nil
end

function CardEmbattleView:onCardClick(data, isShowTip)
	if data.battle <= 0 then
		if data.inMeteor then
			gGameUI:showTip(gLanguageCsv.cardInMeteorites)

			return
		end

		local mergeInfo = dataEasy.getCardMergeInfo()

		if mergeInfo.mergeAB[data.dbid] then
			gGameUI:showTip(gLanguageCsv.inMerge)

			return
		end

		if mergeInfo.relieveC[data.dbid] then
			gGameUI:showTip(gLanguageCsv.inRelieve)

			return
		end
	end

	local tip
	local dbid = self:getKey(data)
	local idx = self:getIdxByDbId(dbid)

	if data.battle > 0 then
		if idx and self:canBattleDown(idx) then
			self:downBattle(dbid)

			tip = gLanguageCsv.downToEmbattle
		else
			tip = gLanguageCsv.battleCannotEmpty
		end
	else
		local idx = self:getIdxByDbId()

		if not self:canBattleUp() then
			tip = gLanguageCsv.battleCardCountEnough
		elseif self:hasSameMarkIDCard(data) then
			tip = gLanguageCsv.alreadyHaveSameSprite
		elseif self.aidNum > 0 and idx > self.panelNum and not dataEasy.isOpenAid(nil, dbid, true) then
			tip = gLanguageCsv.notOpenAid
		else
			self:upBattle(dbid, idx)

			tip = gLanguageCsv.addToEmbattle
		end
	end

	if isShowTip and tip then
		gGameUI:showTip(tip)
	end
end

function CardEmbattleView:getBattle(idx)
	return math.ceil(idx / 6), (idx - 1) % 6 + 1
end

function CardEmbattleView:canBattleDown(idx)
	local leftCount

	if self:isBattleCard(idx) then
		leftCount = self.readyIdx and 0 or 1
	else
		leftCount = 0
	end

	return leftCount < self.clientBattleCards:size()
end

function CardEmbattleView:canBattleUp()
	if dataEasy.isUnlock(gUnlockCsv.aid) then
		return self.clientBattleCards:size() < self.embattleMax or self.aidCards:size() < self.aidNum
	else
		return self.clientBattleCards:size() < self.embattleMax
	end
end

function CardEmbattleView:onCardMove(data, targetIdx, isShowTip)
	local tip

	if targetIdx then
		local dbid = self:getKey(data)
		local idx = self:getIdxByDbId(dbid)
		local targetDbid = self.clientBattleCards:read()[targetIdx]

		if targetIdx and not self:isBattleCard(targetIdx) then
			targetDbid = self.aidCards:read()[targetIdx - self.panelNum]
		end

		if data.battle > 0 then
			local clientBattleCards = table.deepcopy(self.clientBattleCards:read(), true)
			local aidCards = table.deepcopy(self.aidCards:read(), true)

			if self:isBattleCard(idx) and self:isBattleCard(targetIdx) then
				clientBattleCards[idx], clientBattleCards[targetIdx] = clientBattleCards[targetIdx], clientBattleCards[idx]
			elseif self:isBattleCard(idx) and not self:isBattleCard(targetIdx) then
				if not dbid or dataEasy.isOpenAid(nil, dbid, true) then
					if targetDbid or self:canBattleDown(idx) then
						clientBattleCards[idx], aidCards[targetIdx - self.panelNum] = aidCards[targetIdx - self.panelNum], clientBattleCards[idx]
					else
						tip = gLanguageCsv.battleNumberNo
					end
				else
					tip = gLanguageCsv.notOpenAid
				end
			elseif not self:isBattleCard(idx) and self:isBattleCard(targetIdx) then
				if not targetDbid and itertools.size(clientBattleCards) >= self.embattleMax then
					tip = gLanguageCsv.battleCardCountEnough
				elseif not targetDbid or dataEasy.isOpenAid(nil, targetDbid, true) then
					aidCards[idx - self.panelNum], clientBattleCards[targetIdx] = clientBattleCards[targetIdx], aidCards[idx - self.panelNum]
				else
					tip = gLanguageCsv.notOpenAid
				end
			elseif not self:isBattleCard(idx) and not self:isBattleCard(targetIdx) then
				aidCards[idx - self.panelNum], aidCards[targetIdx - self.panelNum] = aidCards[targetIdx - self.panelNum], aidCards[idx - self.panelNum]
			end

			self.clientBattleCards:modify(function(oldval)
				return true, clientBattleCards
			end, true)
			self.aidCards:modify(function(oldval)
				return true, aidCards
			end, true)
		else
			local commonIdx = self:hasSameMarkIDCard(data)

			if commonIdx and commonIdx ~= targetIdx then
				tip = gLanguageCsv.alreadyHaveSameSprite
			elseif not targetDbid and not self:canBattleUp() then
				tip = gLanguageCsv.battleCardCountEnough
			elseif not self:isBattleCard(targetIdx) and self.aidNum > 0 and not dataEasy.isOpenAid(nil, dbid, true) then
				tip = gLanguageCsv.notOpenAid
			else
				self:upBattle(dbid, targetIdx)

				tip = gLanguageCsv.addToEmbattle
			end
		end
	end

	if isShowTip and tip then
		gGameUI:showTip(tip)
	end
end

function CardEmbattleView:onBattleCardTouch(i, event)
	local dbid

	if self:isBattleCard(i) then
		dbid = self.clientBattleCards:read()[i]
	else
		local aidIdx = i - self.panelNum
		local roleLevel = gGameModel.role:read("level")
		local needLevel = self.aidUnlockLevel[aidIdx]

		if roleLevel < needLevel then
			gGameUI:showTip(gLanguageCsv.lvToUnlock, needLevel)

			return
		end

		dbid = self.aidCards:read()[aidIdx]
	end

	if not dbid then
		return
	end

	local data = self:getCardAttrs(dbid)

	if event.name == "began" then
		self:createMovePanel(data)
		self:moveMovePanel(event)
		self.selectIndex:set(i)

		if i <= self.panelNum then
			self.heroSprite[i].sprite:hide()
		end

		if self.movePanel then
			self.movePanel:xy(event.x, event.y)
		end
	elseif event.name == "moved" then
		self:moveMovePanel(event)
	elseif event.name == "ended" or event.name == "cancelled" then
		self.heroSprite[i].sprite:show()
		self:deleteMovingItem()

		if event.y < 340 then
			self:onCardClick(data, true)
		else
			local targetIdx = self:whichEmbattleTargetPos(event)

			if targetIdx then
				if targetIdx ~= i then
					self:onCardMove(data, targetIdx, true)
					audio.playEffectWithWeekBGM("formation.mp3")
				else
					self:onCardMove(data, targetIdx, false)
				end
			else
				self:onCardMove(data, i, false)
			end
		end
	end
end

function CardEmbattleView:getIdxByDbId(dbid)
	if dbid or self.clientBattleCards:size() < self.embattleMax then
		for i = 1, self.panelNum do
			if self.clientBattleCards:read()[i] == dbid then
				return i
			end
		end
	end

	for i = 1, self.aidNum do
		if self.aidCards:read()[i] == dbid then
			return i + self.panelNum
		end
	end
end

function CardEmbattleView:getKey(data)
	if not data then
		return nil
	end

	return data.dbid
end

function CardEmbattleView:getCardAttrsEx(node, dbid)
	return self:getCardAttrs(dbid)
end

function CardEmbattleView:getCardAttrs(dbid)
	return self.allCardDatas:atproxy(dbid)
end

function CardEmbattleView:isBattleCard(idx)
	if idx and idx <= self.panelNum then
		return true
	end

	return false
end

function CardEmbattleView:downBattle(dbid)
	local idx = self:getIdxByDbId(dbid)

	if self:isBattleCard(idx) then
		self.clientBattleCards:modify(function(oldval)
			oldval[idx] = nil

			return true, oldval
		end, true)
	else
		self.aidCards:modify(function(oldval)
			oldval[idx - self.panelNum] = nil

			return true, oldval
		end, true)
	end
end

function CardEmbattleView:upBattle(dbid, idx)
	if self:isBattleCard(idx) then
		self.clientBattleCards:modify(function(oldval)
			oldval[idx] = dbid

			return true, oldval
		end, true)
	else
		local index = idx - self.panelNum

		self.aidCards:modify(function(oldval)
			oldval[index] = dbid

			return true, oldval
		end, true)
	end
end

function CardEmbattleView:hasSameMarkIDCard(data)
	if not data then
		return false
	end

	for i = 1, self.panelNum do
		local dbid = self.clientBattleCards:read()[i]

		if dbid then
			local cardData = self:getCardAttrs(dbid)

			if dataEasy.hasSameMarkIDCard(cardData.card_id, data.card_id) then
				return i
			end
		end
	end

	for i = 1, self.aidNum do
		local dbid = self.aidCards:read()[i]

		if dbid then
			local cardData = self:getCardAttrs(dbid)

			if dataEasy.hasSameMarkIDCard(cardData.card_id, data.card_id) then
				return i + self.panelNum
			end
		end
	end

	return false
end

function CardEmbattleView:whichEmbattleTargetPos(p)
	for i = self.panelNum, 1, -1 do
		local box = self.heroSprite[i].box

		if not box then
			box = self.heroSprite[i].node:box()

			local pos = self.heroSprite[i].node:parent():convertToWorldSpace(box)

			box.x = pos.x
			box.y = pos.y
			self.heroSprite[i].box = box
		end

		if cc.rectContainsPoint(box, p) then
			return i
		end
	end

	for i = self.aidNum, 1, -1 do
		local box = self.heroSprite[self.panelNum + i].box

		if not box then
			box = self.heroSprite[self.panelNum + i].node:box()

			local pos = self.heroSprite[self.panelNum + i].node:parent():convertToWorldSpace(box)

			box.x = pos.x
			box.y = pos.y
			self.heroSprite[self.panelNum + i].box = box
		end

		if cc.rectContainsPoint(box, p) then
			return self.panelNum + i
		end
	end
end

function CardEmbattleView:refreshTeamWeather(battleCards)
	dataEasy.getListenUnlock(gUnlockCsv.weather, function(isUnlock)
		local weatherID = dataEasy.getWeatherID(battleCards, self.selectWeatherID:read())

		self.selectWeatherID:set(weatherID)
	end):anonyOnly(self)
end

function CardEmbattleView:fightBtn()
	local cards = table.deepcopy(self.clientBattleCards:read(), true)

	if not next(cards) then
		gGameUI:showTip(gLanguageCsv.noSpriteAvailable)

		return
	end

	local selectArms = table.deepcopy(self.selectArms:read(), true)
	local selectWeatherID = table.deepcopy(self.selectWeatherID:read(), true)

	self:sendRequeat(function()
		self.fightCb(self, self.clientBattleCards, {
			weather = selectWeatherID,
			arms = selectArms
		}, self.aidCards)
	end)
end

function CardEmbattleView:onClose(sendRequeat, isTeamSave)
	local function closeCb()
		if sendRequeat == true then
			self:sendRequeat(functools.partial(ViewBase.onClose, self), true)
		else
			ViewBase.onClose(self)
		end
	end

	if self.readyIdx and isTeamSave ~= true and self:isChangeBattleCards() then
		self:teamNotSave(closeCb)
	else
		closeCb()
	end
end

function CardEmbattleView:isChangeBattleCards()
	local haveChange = false

	if self.inputCards then
		if self.inputCards:size() == self.clientBattleCards:size() then
			local inputCards = self.inputCards:read()

			for k, val in pairs(self.clientBattleCards:read()) do
				if inputCards[k] ~= val then
					haveChange = true
				end
			end
		else
			haveChange = true
		end
	end

	if self.inputAidCards then
		if self.originAidCards:size() == self.aidCards:size() then
			local originAidCards = self.originAidCards:read()

			for k, val in pairs(self.aidCards:read()) do
				if originAidCards[k] ~= val then
					haveChange = true
				end
			end
		else
			haveChange = true
		end
	end

	if self.inputExtra then
		local selectArms = table.deepcopy(self.selectArms:read(), true)

		if not itertools.equal(self.originWeatherID, self.selectWeatherID:read()) or not itertools.equal(self.originArms or {}, selectArms or {}) then
			haveChange = true
		end
	end

	return haveChange
end

function CardEmbattleView:cardBagBtn()
	self:sendRequeat(function()
		if not isIdlerComputer(self.battleCardsData) then
			self.battleCardsData:set(table.deepcopy(self.clientBattleCards:read(), true), true)
		end

		self.originAidCards:set(table.deepcopy(self.aidCards:read(), true), true)

		self.originWeatherID = self.selectWeatherID:read()
		self.originArms = table.deepcopy(self.selectArms:read(), true)

		performWithDelay(self, function()
			gGameUI:stackUI("city.card.bag", nil, {
				full = true
			})
		end, 0.016666666666666666)
	end)
end

function CardEmbattleView:onTeamWeatherClick()
	gGameUI:stackUI("city.weather.weather_select", nil, nil, {
		cardsData = dataEasy.getTeamWeather(self.clientBattleCards:read(), true),
		weatherID = self.selectWeatherID
	})
end

function CardEmbattleView:limtFunc(params)
	local meteorCardsHash = dataEasy.getInMeteorCardsHash()
	local card = gGameModel.cards:find(params.dbid)
	local cardDatas = card:read("card_id", "skin_id", "fighting_point", "level", "star", "advance", "created_time", "aid_fighting_point")
	local cardID = cardDatas.card_id
	local cardCsv = csv.cards[cardID]
	local unitCsv = csv.unit[cardCsv.unitID]
	local unitId = dataEasy.getUnitId(cardID, cardDatas.skin_id)

	return {
		card_id = cardID,
		unit_id = unitId,
		rarity = unitCsv.rarity,
		attr1 = unitCsv.natureType,
		attr2 = unitCsv.natureType2,
		fighting_point = cardDatas.fighting_point,
		aid_fighting_point = cardDatas.aid_fighting_point or 0,
		level = cardDatas.level,
		star = cardDatas.star,
		getTime = cardDatas.created_time,
		dbid = params.dbid,
		advance = cardDatas.advance,
		battle = params.inBattle,
		atkType = cardCsv.atkType,
		markId = cardCsv.cardMarkID,
		inMeteor = meteorCardsHash[params.dbid]
	}
end

function CardEmbattleView:oneReadyBtn()
	if not dataEasy.isUnlock(gUnlockCsv.readyTeam) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.readyTeam))

		return
	end

	local function useTeamBattles(battleCards, cb, extra, aidCards)
		battleCards = dataEasy.fixEmattleCards(battleCards)
		aidCards = dataEasy.fixEmattleCards(aidCards)

		self.clientBattleCards:set(battleCards)
		self.selectWeatherID:set(extra.weather)
		self.selectArms:set(extra.arms)
		self.aidCards:set(aidCards)
		self.clientBattleCards:notify()

		if cb then
			cb()
		end
	end

	gGameUI:stackUI("city.card.embattle.ready", nil, nil, {
		sceneType = self.sceneType,
		from = self.from,
		cb = useTeamBattles,
		aidNum = self.aidNum,
		aidUnlockLevel = self.aidUnlockLevel
	})
end

function CardEmbattleView:oneSaveReadyBtn()
	local extra = {
		weather = self.selectWeatherID:read(),
		arms = table.deepcopy(self.selectArms:read(), true)
	}

	gGameApp:requestServer("/game/ready/card/deploy", function(tb)
		self:onClose(nil, true)
		gGameUI:showTip(gLanguageCsv.positionSave)
	end, self.readyIdx, self.clientBattleCards:read(), extra, self.aidCards)
end

function CardEmbattleView:teamNotSave(cb)
	gGameUI:showDialog({
		btnType = 2,
		content = gLanguageCsv.teamNotSave,
		cb = function()
			self:oneSaveReadyBtn()
		end,
		cancelCb = cb
	})
end

return CardEmbattleView
