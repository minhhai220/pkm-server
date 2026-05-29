-- chunkname: @src.app.easy.jump

local unionTools = require("app.views.city.union.tools")
local activityConfig = require("app.views.city.activity_config")
local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE
local jumpEasy = {}

globals.jumpEasy = jumpEasy

local SHOP_UNLOCK_KEY = game.SHOP_UNLOCK_KEY

local function enterUnionOrChildView(cb, notRequest)
	local result = true
	local unionId = gGameModel.role:read("union_db_id")
	local url = "/game/union/get"
	local viewName = "city.union.view"
	local styles = {
		full = true
	}
	local requestParams = {}

	if not unionId then
		result = false
		url = "/game/union/list"
		viewName = "city.union.join.join"
		styles = {}
		requestParams = {
			0,
			10
		}
	end

	local params = {
		result = result,
		unionId = unionId,
		viewName = viewName,
		cb = cb,
		styles = styles
	}

	if notRequest and unionId then
		if cb then
			cb(result)
		end

		return
	end

	gGameApp:requestServer(url, function(tb)
		local params = {}

		if not unionId then
			table.insert(params, tb.view.unions)
		end

		if gGameUI:goBackInStackUI(viewName) then
			if cb then
				cb(result)
			end

			return
		end

		gGameUI:stackUI(viewName, nil, styles, unpack(params), tb.view)

		if cb then
			cb(result)
		end
	end, unpack(requestParams))
	sdk.trackEvent("join_union")
end

local jumpInfos = {
	shop = {
		key = "shop",
		viewName = "city.shop",
		styles = {
			full = true
		},
		func = function(cb, param)
			param = param or 1

			local key = SHOP_UNLOCK_KEY[param].unlockKey

			if key and not dataEasy.isUnlock(key) then
				gGameUI:showTip(gLanguageCsv.shopNotOpen)

				return
			end

			uiEasy.goToShop(param, cb)
		end
	},
	activity = {
		key = "activity",
		viewName = "city.activity.view",
		styles = {
			full = true
		},
		func = function(cb, style)
			gGameApp:requestServer("/game/yy/active/get", function(tb)
				cb(style)
			end)
		end
	},
	roleLogo = {
		key = "roleLogo",
		viewName = "city.personal.role_logo"
	},
	figure = {
		key = "figure",
		viewName = "city.personal.figure"
	},
	gainGold = {
		key = "gainGold",
		viewName = "common.gain_gold"
	},
	recharge = {
		key = "recharge",
		viewName = "city.recharge",
		styles = {
			full = true
		}
	},
	gainStamina = {
		key = "gainStamina",
		viewName = "common.gain_stamina"
	},
	friend = {
		key = "friend",
		viewName = "city.friend",
		func = function(cb)
			local friendView = require("app.views.city.friend")
			local showType, param = friendView.initFriendShowType()

			friendView.sendProtocol(showType, param, cb)
		end
	},
	gate = {
		key = "gate",
		viewName = "city.gate.view",
		styles = {
			full = true
		}
	},
	cardBag = {
		key = "cardBag",
		viewName = "city.card.bag",
		styles = {
			full = true
		}
	},
	strengthen = {
		key = "strengthen",
		viewName = "city.card.strengthen",
		styles = {
			full = true
		}
	},
	handbook = {
		key = "handbook",
		viewName = "city.handbook.view",
		styles = {
			full = true
		}
	},
	arena = {
		key = "arena",
		viewName = "city.pvp.arena.view",
		styles = {
			full = true
		},
		func = function(cb)
			gGameApp:requestServer("/game/pw/battle/get", function(tb)
				cb()
			end)
		end
	},
	drawCard = {
		key = "drawCard",
		viewName = "city.drawcard.view",
		styles = {
			full = true
		}
	},
	cloneBattle = {
		unlockKey = "cloneBattle",
		viewName = "city.adventure.clone_battle.base",
		key = "cloneBattle",
		styles = {
			full = true
		},
		func = function(cb)
			gGameApp:requestServer("/game/clone/get", function(tb)
				cb(tb.view)
			end)
		end
	},
	union = {
		unlockKey = "union",
		key = "union",
		func = function()
			enterUnionOrChildView()
		end
	},
	redpacket = {
		key = "redpacket",
		func = function()
			enterUnionOrChildView(function(result)
				if not result then
					return
				end

				local canEnter = unionTools.canEnterBuilding("redpacket", true)

				if not canEnter then
					return
				end

				gGameApp:requestServer("/game/union/redpacket/info", function(tb)
					gGameUI:stackUI("city.union.redpack.view", nil, {
						full = true
					}, tb.view)
				end)
			end, true)
		end
	},
	contribute = {
		key = "contribute",
		func = function()
			enterUnionOrChildView(function(result)
				if not result then
					return
				end

				local canEnter = unionTools.canEnterBuilding("contribute")

				if not canEnter then
					return
				end

				gGameUI:stackUI("city.union.contrib.view")
			end)
		end
	},
	fuben = {
		key = "fuben",
		func = function()
			enterUnionOrChildView(function(result)
				if not result then
					return
				end

				local canEnter = unionTools.canEnterBuilding("fuben")

				if not canEnter then
					return
				end

				gGameApp:requestServer("/game/union/fuben/get", function(tb)
					gGameUI:stackUI("city.union.gate.view", nil, nil, tb.view)
				end)
			end)
		end
	},
	training = {
		key = "training",
		func = function()
			enterUnionOrChildView(function(result)
				if not result then
					return
				end

				local canEnter = unionTools.canEnterBuilding("training")

				if not canEnter then
					return
				end

				gGameApp:requestServer("/game/union/training/open", function(tb)
					if gGameModel.union_training then
						gGameUI:stackUI("city.union.train.view", nil, nil, tb)
					end
				end)
			end)
		end
	},
	unionQA = {
		key = "unionQA",
		func = function()
			enterUnionOrChildView(function(result)
				if not result then
					return
				end

				local canEnter = unionTools.canEnterBuilding("unionqa")

				if not canEnter then
					return
				end

				gGameApp:requestServer("/game/union/qa/main", function(tb)
					gGameUI:stackUI("city.union.answer.view", nil, {
						full = true
					}, tb)
				end)
			end, true)
		end
	},
	crossunionfight = {
		key = "crossunionfight",
		func = function()
			enterUnionOrChildView(function(result)
				if not result then
					return
				end

				local canEnter = unionTools.canEnterBuilding("crossunionfight")

				if not canEnter then
					return
				end

				gGameApp:requestServer("/game/cross/union/fight/main", function()
					gGameUI:stackUI("city.union.cross_unionfight.view", nil, nil, nil)
				end)
			end, true)
		end
	},
	craft = {
		unlockKey = "craft",
		key = "craft",
		styles = {
			full = true
		},
		func = function()
			gGameApp:requestServer("/game/craft/battle/main", function(tb)
				local round = gGameModel.craft:read("round")
				local viewName = "city.pvp.craft.myschedule"

				if round == "over" or round == "closed" or round == "signup" then
					viewName = "city.pvp.craft.view"
				end

				if gGameUI:goBackInStackUI(viewName) then
					return
				end

				gGameUI:stackUI(viewName, nil, {
					full = true
				})
			end)
		end
	},
	task = {
		key = "task",
		viewName = "city.task",
		styles = {
			full = true
		}
	},
	talent = {
		unlockKey = "talent",
		viewName = "city.develop.talent.view",
		key = "talent",
		styles = {
			full = true
		}
	},
	explorer = {
		unlockKey = "explorer",
		viewName = "city.develop.explorer.view",
		key = "explorer",
		styles = {
			full = true
		}
	},
	dispatchTask = {
		unlockKey = "dispatchTask",
		viewName = "city.adventure.dispatch_task.view",
		key = "dispatchTask",
		styles = {
			full = true
		},
		func = function(cb)
			gGameApp:requestServer("/game/dispatch/task/refresh", function(tb)
				cb()
			end, false)
		end
	},
	randomTower = {
		unlockKey = "randomTower",
		viewName = "city.adventure.random_tower.view",
		key = "randomTower",
		styles = {
			full = true
		},
		func = function(cb)
			gGameApp:requestServer("/game/random_tower/prepare", function(tb)
				cb()
			end)
		end
	},
	hellRandomTower = {
		unlockKey = "hellRandomTower",
		viewName = "city.adventure.random_tower.view",
		key = "hellRandomTower",
		styles = {
			full = true
		},
		func = function(cb)
			gGameApp:requestServer("/game/random_tower/prepare", function(tb)
				cb()
			end)
		end
	},
	endlessTower = {
		unlockKey = "endlessTower",
		viewName = "city.adventure.endless_tower.view",
		key = "endlessTower",
		styles = {
			full = true
		}
	},
	activityGate = {
		unlockKey = "activityGate",
		viewName = "city.adventure.daily_activity.view",
		key = "activityGate",
		styles = {
			full = true
		},
		func = function(cb, _type)
			gGameApp:requestServer("/game/huodong/show", function(tb)
				if _type then
					cb(tb.view)
				else
					cb("", tb.view)
				end
			end)
		end
	},
	trainer = {
		key = "trainer",
		viewName = "city.develop.trainer.view",
		styles = {
			full = true
		}
	},
	heldItem = {
		key = "heldItem",
		viewName = "city.card.helditem.bag",
		func = function(cb)
			if not gGameUI:goBackInStackUI("city.card.strengthen") then
				gGameUI:stackUI("city.card.strengthen")
			end

			cb()
		end
	},
	feel = {
		key = "feel",
		viewName = "city.card.feel.view",
		func = function(cb)
			if not gGameUI:goBackInStackUI("city.card.strengthen") then
				gGameUI:stackUI("city.card.strengthen")
			end

			cb()
		end
	},
	propertySwap = {
		key = "propertySwap",
		viewName = "city.card.property_swap.view",
		func = function(cb)
			if not gGameUI:goBackInStackUI("city.card.strengthen") then
				gGameUI:stackUI("city.card.strengthen")
			end

			cb()
		end
	},
	explorerDraw = {
		unlockKey = "explorer",
		viewName = "city.develop.explorer.draw_item.view",
		key = "explorerDraw",
		styles = {
			full = true
		}
	},
	unionFight = {
		unlockKey = "unionFight",
		key = "unionFight",
		styles = {
			full = true
		},
		func = function()
			local canEnter = unionTools.canEnterBuilding("unionFight")

			if not canEnter then
				return
			end

			if not gGameUI:goBackInStackUI("city.union.union_fight.view") then
				gGameApp:requestServer("/game/union/fight/battle/main", function(tb)
					gGameUI:stackUI("city.union.union_fight.view", nil, {
						full = true
					})
				end)
			end
		end
	},
	crossCraft = {
		unlockKey = "crossCraft",
		key = "crossCraft",
		styles = {
			full = true
		},
		func = function()
			gGameApp:requestServer("/game/cross/craft/battle/main", function(tb)
				local viewName = "city.pvp.cross_craft.view"

				if gGameUI:goBackInStackUI(viewName) then
					return
				end

				gGameUI:stackUI(viewName, nil, {
					full = true
				})
			end)
		end
	},
	capture = {
		unlockKey = "limitCapture",
		key = "capture",
		styles = {
			full = true
		},
		func = function()
			gGameUI:stackUI("city.capture.capture_limit", nil, nil)
		end
	},
	gemTitle = {
		unlockKey = "gem",
		key = "gemTitle",
		styles = {
			full = true
		},
		func = function()
			gGameUI:stackUI("city.card.gem.view", nil, nil)
		end
	},
	gemDraw = {
		unlockKey = "gem",
		key = "gemDraw",
		styles = {
			full = true
		},
		func = function()
			gGameUI:stackUI("city.card.gem.draw")
		end
	},
	chipDraw = {
		unlockKey = "chip",
		key = "chipDraw",
		styles = {
			full = true
		},
		func = function()
			gGameUI:stackUI("city.card.chip.draw")
		end
	},
	chipBag = {
		unlockKey = "chip",
		viewName = "city.card.chip.bag",
		key = "chipBag",
		styles = {
			full = true
		}
	},
	crossArena = {
		unlockKey = "crossArena",
		key = "crossArena",
		styles = {
			full = true
		},
		func = function()
			local cards = gGameModel.role:read("cards")

			if table.length(cards) < 2 then
				gGameUI:showTip(gLanguageCsv.crossArenaCardNotEnoughTip)

				return
			end

			gGameApp:requestServer("/game/cross/arena/battle/main", function(tb)
				local viewName = "city.pvp.cross_arena.view"

				if gGameUI:goBackInStackUI(viewName) then
					return
				end

				gGameUI:stackUI(viewName, nil, {
					full = true
				}, tb.view)
			end)
		end
	},
	cardMega = {
		unlockKey = "mega",
		viewName = "city.card.mega.view",
		key = "cardMega",
		styles = {
			full = true
		}
	},
	megaStone = {
		unlockKey = "mega",
		viewName = "city.card.mega.conversion",
		key = "megaStone"
	},
	keyStone = {
		unlockKey = "mega",
		viewName = "city.card.mega.conversion",
		key = "keyStone"
	},
	fishing = {
		unlockKey = "fishing",
		key = "fishing",
		styles = {
			full = true
		},
		func = function()
			gGameUI:stackUI("city.adventure.fishing.sence_select")
		end
	},
	hunting = {
		unlockKey = "hunting",
		key = "hunting",
		styles = {
			full = true
		},
		func = function()
			gGameApp:requestServer("/game/hunting/main", function(tb)
				gGameUI:stackUI("city.adventure.hunting.view")
			end)
		end
	},
	specialHunting = {
		unlockKey = "specialHunting",
		key = "specialHunting",
		styles = {
			full = true
		},
		func = function()
			gGameApp:requestServer("/game/hunting/main", function(tb)
				gGameUI:stackUI("city.adventure.hunting.view")
			end)
		end
	},
	onlineFight = {
		unlockKey = "onlineFight",
		key = "onlineFight",
		styles = {
			full = true
		},
		func = function()
			local num = 12
			local cards = gGameModel.role:read("cards")

			if num > table.length(cards) then
				gGameUI:showTip(gLanguageCsv.onlineFightNotEnoughCards .. num)

				return
			end

			if gGameModel.role:read("in_cross_online_fight_battle") then
				gGameUI:showDialog({
					clearFast = true,
					btnType = 2,
					isRich = true,
					content = "#C0x5B545B#" .. gLanguageCsv.onlineFightReconnection,
					cb = function()
						dataEasy.onlineFightLoginServer()
					end
				})
			else
				gGameApp:requestServer("/game/cross/online/main", function(tb)
					gGameUI:stackUI("city.pvp.online_fight.view", nil, {
						full = true
					})
				end)
			end
		end
	},
	reunion = {
		key = "reunion",
		viewName = "city.activity.reunion.view",
		styles = {
			full = true
		},
		func = function(cb)
			local reunion = gGameModel.role:read("reunion")
			local reunionBindRoleId = gGameModel.reunion_record:read("bind_role_db_id")
			local roleID = ""

			if reunion.role_type == 1 then
				roleID = reunionBindRoleId or ""
			elseif reunion.role_type == 2 then
				roleID = reunion.info.role_id
			end

			if roleID ~= "" then
				gGameApp:requestServer("/game/role_info", function(tb)
					local info = tb.view
					local params = {
						info = info
					}

					if reunion.role_type == 2 then
						gGameApp:requestServer("/game/yy/reunion/record/get", function(tb)
							params = {
								info = info,
								reunionRecord = tb.view.reunion_record
							}

							if cb then
								cb(params)
							end
						end, roleID)
					elseif cb then
						cb(params)
					end
				end, roleID)
			else
				cb({})
			end
		end
	},
	gymChallenge = {
		unlockKey = "gym",
		key = "gymChallenge",
		styles = {
			full = true
		},
		func = function()
			gGameApp:requestServer("/game/gym/main", function(tb)
				local viewName = "city.adventure.gym_challenge.view"

				if gGameUI:goBackInStackUI(viewName) then
					return
				end

				gGameUI:stackUI(viewName, nil, {
					full = true
				})
			end)
		end
	},
	crossMine = {
		unlockKey = "crossMine",
		key = "crossMine",
		styles = {
			full = true
		},
		func = function()
			local cards = gGameModel.role:read("cards")

			if table.length(cards) < 3 then
				gGameUI:showTip(gLanguageCsv.crossMineCardNotEnoughTip)

				return
			end

			gGameApp:requestServer("/game/cross/mine/main", function(tb)
				local viewName = "city.pvp.cross_mine.view"

				if gGameUI:goBackInStackUI(viewName) then
					return
				end

				gGameUI:stackUI(viewName, nil, {
					full = true
				})
			end)
		end
	},
	crossMineBoss = {
		unlockKey = "crossMine",
		key = "crossMine",
		styles = {
			full = true
		},
		func = function()
			local cards = gGameModel.role:read("cards")

			if table.length(cards) < 3 then
				gGameUI:showTip(gLanguageCsv.crossMineCardNotEnoughTip)

				return
			end

			gGameApp:requestServer("/game/cross/mine/main", function(tb)
				local viewName = "city.pvp.cross_mine.view"

				if gGameUI:goBackInStackUI(viewName) then
					return
				end

				gGameUI:stackUI(viewName, nil, {
					full = true
				}, {
					isShowBoss = true
				})
			end)
		end
	},
	dailyAssistant = {
		unlockKey = "dailyAssistant",
		key = "dailyAssistant",
		styles = {
			full = true
		},
		func = function()
			local dailyAssistantTools = require("app.views.city.daily_assistant.tools")
			local isOpen = dailyAssistantTools.getUnionFubenIsOpen()

			local function callBack()
				local viewName = "city.daily_assistant.view"

				if gGameUI:goBackInStackUI(viewName) then
					return
				end

				gGameUI:stackUI(viewName, nil, {
					full = true
				})
			end

			if isOpen then
				gGameApp:requestServer("/game/union/fuben/get", function(tb)
					callBack()
				end)
			else
				callBack()
			end
		end
	},
	zawakeFragExclusive = {
		unlockKey = "zawake",
		viewName = "city.zawake.debris",
		key = "zawakeFragExclusive"
	},
	zawakeFragCurrency = {
		unlockKey = "zawake",
		viewName = "city.zawake.debris",
		key = "zawakeFragCurrency"
	},
	normalBraveChallenge = {
		unlockKey = "normalBraveChallenge",
		viewName = "city.activity.brave_challenge.view",
		key = "normalBraveChallenge",
		styles = {
			full = true
		},
		func = function(cb, params)
			gGameApp:requestServer("/game/brave_challenge/main", function(tb)
				cb(0, 2)
			end)
		end
	},
	crossSupremacy = {
		unlockKey = "crossSupremacy",
		key = "crossSupremacy",
		styles = {
			full = true
		},
		func = function()
			local cards = gGameModel.role:read("cards")

			if table.length(cards) < 3 then
				gGameUI:showTip(gLanguageCsv.crossSupremacyCardNotEnoughTip)

				return
			end

			gGameApp:requestServer("/game/cross/supremacy/main", function(tb)
				local viewName = "city.pvp.cross_supremacy.view"

				if gGameUI:goBackInStackUI(viewName) then
					return
				end

				gGameUI:stackUI(viewName, nil, {
					full = true
				}, tb.view)
			end)
		end
	},
	town = {
		unlockKey = "town",
		viewName = "city.town.view",
		key = "town",
		styles = {
			full = true
		},
		func = function()
			gGameApp:requestServer("/town/get", function(tb)
				townDataEasy.homeFriends(tb.view)
				display.textureCache:removeUnusedTextures()
				gGameUI:stackUI("city.town.view", nil, {
					full = true
				}, tb.view)
			end)
		end
	},
	townHome = {
		unlockKey = "town",
		viewName = "city.town.view",
		key = "townHome",
		styles = {
			full = true
		},
		func = function()
			if dataEasy.isTownBuildingUnlock(game.TOWN_BUILDING_ID.HOME) then
				gGameApp:requestServer("/town/get", function(tb)
					townDataEasy.homeFriends(tb.view)

					local function cb()
						display.textureCache:removeUnusedTextures()
						gGameUI:stackUI("city.town.view", nil, {
							full = true
						})
						gGameUI:stackUI("city.town.home.view")
					end

					local partyUid = townDataEasy.getPartyUID()
					local partyData = townDataEasy.findParty(partyUid)

					if not partyData then
						cb()
					else
						gGameApp:requestServer("/game/town/party/room/get", cb, partyData.room_id)
					end
				end)
			end
		end
	},
	townExploration = {
		unlockKey = "town",
		viewName = "city.town.exploration.view",
		key = "townExploration",
		styles = {
			full = true
		},
		func = function()
			if dataEasy.isTotemUnlock() then
				gGameUI:stackUI("city.town.exploration.view", nil, {
					full = true
				}, game.TOWN_BUILDING_ID.EXPLORATION)
			else
				gGameUI:showTip(gLanguageCsv.townTopuiClickLockTip)
			end
		end
	},
	totemDecompose = {
		unlockKey = "totem",
		viewName = "city.develop.totem.decompose",
		key = "totemDecompose",
		styles = {
			full = true
		},
		func = function()
			if dataEasy.isTotemUnlock() then
				gGameUI:stackUI("city.develop.totem.decompose", nil, nil)
			else
				local key = gUnlockCsv.totem
				local cfg = csv.unlock[key]

				gGameUI:showTip(string.format(gLanguageCsv.totemTownExplorationUnlock, cfg.startLevel))
			end
		end
	},
	townSupermarket = {
		unlockKey = "town",
		viewName = "city.town.view",
		key = "townSupermarket",
		styles = {
			full = true
		},
		func = function()
			if gGameModel.town and gGameModel.town:read("buildings") then
				local buildCsv = gTownBuildingCsv[game.TOWN_BUILDING_ID.SUPERSHOP][1]
				local sign = townDataEasy.getBuildingUnlockStateAll(buildCsv)

				if sign then
					gGameApp:requestServer("/game/town/shop/get", function(tb)
						gGameUI:stackUI("city.town.supershop", nil, {
							full = true
						})
					end)

					return
				end
			end

			gGameUI:showTip(gLanguageCsv.shopNotExisted)
		end
	},
	mimicry = {
		unlockKey = "mimicry",
		key = "mimicry",
		styles = {
			full = true
		},
		func = function()
			gGameApp:requestServer("/game/mimicry/main", function(tb)
				gGameUI:stackUI("city.adventure.mimicry.view", nil, {
					full = true
				}, tb.view)
			end)
		end
	},
	autoChess = {
		unlockKey = "autoChess",
		key = "autoChess",
		styles = {
			full = true
		},
		func = function()
			gGameApp:requestServer("/game/auto_chess/main", function(tb)
				for _, id in pairs(gGameModel.auto_chess:read("newbie_guide")) do
					if id == 1 then
						gGameUI:stackUI("city.adventure.auto_chess.view", nil, {
							full = true
						})

						return
					end
				end

				gGameUI:switchUIAndStash("lushi_battle.loading", {
					isGuide = true
				})
			end)
		end
	},
	crossUnionAdventure = {
		unlockKey = "crossUnionAdventure",
		key = "crossUnionAdventure",
		styles = {
			full = true
		},
		func = function()
			local num = 12
			local cards = gGameModel.role:read("cards")

			if num > table.length(cards) then
				gGameUI:showTip(gLanguageCsv.onlineFightNotEnoughCards .. num)

				return
			end

			enterUnionOrChildView(function(result)
				if not result then
					return
				end

				local unionLv = gGameModel.union:read("level")

				if unionLv < gUnionFeatureCsv.crossUnionAdventure then
					gGameUI:showTip(string.format(gLanguageCsv.guildReachLevelUnlock, gUnionFeatureCsv.crossUnionAdventure))

					return
				end

				local canEnter = unionTools.canEnterBuilding("crossUnionAdventure")

				if not canEnter then
					return
				end

				gGameApp:requestServer("/game/cross/union/adventure/main", function(tb)
					gGameUI:stackUI("city.union.cross_union_adventure.main.view")
				end)
			end, true)
		end
	},
	crossCircus = {
		unlockKey = "crossCircus",
		key = "crossCircus",
		styles = {
			full = true
		},
		func = function()
			gGameApp:requestServer("/game/cross/circus/main", function(tb)
				gGameUI:stackUI("city.pvp.cross_circus.view", nil, {
					full = true
				}, tb)
			end)
		end
	},
	achievement = {
		unlockKey = "achievement",
		viewName = "city.achievement",
		key = "achievement",
		styles = {
			full = true
		}
	},
	arm = {
		unlockKey = "arms",
		viewName = "city.develop.arm.view",
		key = "arm",
		styles = {
			full = true
		}
	},
	medalCollection = {
		unlockKey = "medalCollection",
		viewName = "city.medal_collection.view",
		key = "medalCollection",
		styles = {
			full = true
		}
	},
	gymBadge = {
		unlockKey = "badge",
		viewName = "city.develop.gym_badge.view",
		key = "gymBadge",
		styles = {
			full = true
		}
	},
	cardStarTemporarySwap = {
		unlockKey = "cardStarTemporarySwap",
		viewName = "city.card.star_swap.view",
		key = "cardStarTemporarySwap",
		styles = {
			full = true
		}
	},
	totem = {
		unlockKey = "totem",
		key = "totem",
		func = function()
			if dataEasy.isTotemUnlock() then
				gGameUI:stackUI("city.develop.totem.view", nil, {
					full = true
				})
			else
				local cfg = csv.unlock[gUnlockCsv.totem]

				gGameUI:showTip(string.format(gLanguageCsv.totemTownExplorationUnlock, cfg.startLevel))
			end
		end
	},
	contract = {
		unlockKey = "contract",
		viewName = "city.develop.contract.view",
		key = "contract",
		styles = {
			full = true
		}
	},
	meteorite = {
		unlockKey = "meteorite",
		viewName = "city.develop.strange_meteor.view",
		key = "meteorite",
		styles = {
			full = true
		}
	},
	onlineAutoChess = {
		unlockKey = "onlineAutoChess",
		key = "onlineAutoChess",
		styles = {
			full = true
		},
		func = function()
			gGameApp:requestServer("/game/auto_chess/main", function(tb)
				for _, id in pairs(gGameModel.auto_chess:read("newbie_guide")) do
					if id == 3 then
						gGameUI:stackUI("city.pvp.online_auto_chess.view", nil, {
							full = true
						})

						return
					end
				end

				gGameUI:switchUIAndStash("lushi_battle.loading", {
					isMulti = true,
					isGuide = true
				})
			end, true)
		end
	},
	huodongId = {
		func = function(cb, huodongId)
			if gGameUI.rootViewName == "city.view" then
				local yyOpen = gGameModel.role:read("yy_open")
				local yyhuodongs = gGameModel.role:read("yyhuodongs")
				local isOpen = false

				for _, yyId in ipairs(yyOpen) do
					if yyId == huodongId then
						isOpen = true

						break
					end
				end

				if not isOpen then
					gGameUI:showTip(gLanguageCsv.huodongNoOpen)

					return
				end

				local _type = csv.yunying.yyhuodong[huodongId].type

				if _type == YY_TYPE.timeLimitDraw then
					jumpEasy.jumpTo("drawCard-limit-" .. huodongId)

					return
				end

				local activityInfos = activityConfig.getActivityInfoData(gGameUI.uiRoot)
				local activityInfo

				if not gGameUI.uiRoot:isIndependent(huodongId, activityInfos) then
					activityInfo = {
						viewName = "city.activity.view",
						independent = csv.yunying.yyhuodong[huodongId].independent,
						styles = {
							full = true
						},
						func = function(cb, params)
							gGameApp:requestServer("/game/yy/active/get", function(tb)
								cb(params)
							end)
						end
					}
				else
					local huodong = yyhuodongs[huodongId] or {}

					if not gGameUI.uiRoot:isActivityShow(huodongId, activityInfos) then
						gGameUI:showTip(gLanguageCsv.huodongNoOpen)

						return
					end

					activityInfo = clone(activityInfos[_type])
					activityInfo.styles = {
						dialog = true
					}

					if _type == YY_TYPE.reunion then
						activityInfo.params = {}
					else
						activityInfo.params = {
							huodongId
						}
					end
				end

				if activityInfo.func then
					activityInfo.func(function(...)
						local params = {}

						if activityInfo.independent == 0 or activityInfo.independent == 4 then
							params = {
								"main",
								huodongId
							}
						elseif activityInfo.independent == 3 or activityInfo.independent == 5 then
							params = {
								"award",
								huodongId
							}
						else
							params = clone(activityInfo.params or {})

							for _, activityInfo in ipairs({
								...
							}) do
								table.insert(params, activityInfo)
							end
						end

						gGameUI:stackUI(activityInfo.viewName, nil, activityInfo.styles, unpack(params))
					end, activityInfo.params or {})
				elseif activityInfo.viewName then
					gGameUI:stackUI(activityInfo.viewName, nil, activityInfo.styles, unpack(activityInfo.params or {}))
				end
			end
		end
	},
	huodongType = {
		func = function(cb, _type)
			if _type == YY_TYPE.timeLimitDraw then
				jumpEasy.jumpTo("drawCard-limit")

				return
			end

			local yyOpen = gGameModel.role:read("yy_open")

			for _, yyId in ipairs(yyOpen) do
				if csv.yunying.yyhuodong[yyId].type == _type then
					jumpEasy.jumpTo("huodongId-" .. yyId)

					return
				end
			end

			gGameUI:showTip(gLanguageCsv.huodongNoOpen)
		end
	},
	abyssEndlessTower = {
		unlockKey = "abyssEndlessTower",
		viewName = "city.adventure.endless_tower.abyss.view",
		key = "abyssEndlessTower",
		styles = {
			full = true
		}
	}
}

local function checkGateID(gateID)
	local gateOpen = gGameModel.role:read("gate_open")
	local mapOpen = gGameModel.role:read("map_open")
	local openType = {}
	local worldMapCsv = csv.world_map
	local maxRoleLv = table.length(gRoleLevelCsv)

	for _, chapterId in ipairs(mapOpen) do
		if maxRoleLv >= worldMapCsv[chapterId].openLevel then
			local chapterType = worldMapCsv[chapterId].chapterType

			openType[chapterType] = true
		end
	end

	if not itertools.include(gateOpen, gateID) then
		local _type, charterId, id = dataEasy.getChapterInfoByGateID(gateID)

		if not openType[_type] then
			if isShowTip then
				if _type == 2 then
					gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.heroGate))
				elseif _type == 3 then
					gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.nightmareGate))
				end
			end

			return false
		end

		gateID = _type * 10000

		if id == 0 then
			gateID = gateID + charterId * 100
		end
	end

	return gateID
end

function jumpEasy.isJumpUnlock(target, isShowTip, ...)
	target = target or ""

	local params = {
		...
	}
	local arr = string.split(target, "-")

	for i = 2, #arr do
		local val = tonumber(arr[i]) or arr[i]

		table.insert(params, val)
	end

	local info = jumpInfos[arr[1]]
	local gateID = tonumber(arr[1])

	if gateID then
		gateID = checkGateID(gateID)
		info = jumpInfos.gate

		table.insert(params, gateID)
	end

	if info.key == "strengthen" then
		if params and params[1] == "ability" then
			local cardAbilityCan = dataEasy.getListenUnlock(gUnlockCsv.cardAbility)

			if not cardAbilityCan:read() then
				gGameUI:showTip(dataEasy.getUnlockTip("cardAbility"))

				return false
			end
		elseif params and params[1] == "effortvalue" then
			local cardEffortCan = dataEasy.getListenUnlock(gUnlockCsv.cardEffort)

			if not cardEffortCan:read() then
				gGameUI:showTip(dataEasy.getUnlockTip("cardEffort"))

				return false
			end
		end
	end

	if not info then
		return false
	end

	if info.unlockKey then
		if not dataEasy.isUnlock(info.unlockKey) then
			if isShowTip then
				gGameUI:showTip(dataEasy.getUnlockTip(info.unlockKey))
			end

			return false
		end

		local state, day = dataEasy.judgeServerOpen(info.unlockKey)

		if not state and day then
			gGameUI:showTip(string.format(gLanguageCsv.unlockServerOpen, day))

			return
		end
	end

	return true, info, params
end

function jumpEasy.jumpTo(target, ...)
	if target == "gainWay" then
		gGameUI:stackUI("common.gain_way", nil, nil, ...)

		return
	end

	local isUnlock, info, params = jumpEasy.isJumpUnlock(target, true, ...)

	if not isUnlock then
		return
	end

	if info.viewName and gGameUI:goBackInStackUI(info.viewName) then
		return
	end

	local function jump(...)
		local nargs = select("#", ...)
		local t = {
			...
		}
		local len = #params

		for i = 1, nargs do
			len = len + 1
			params[len] = t[i]
		end

		gGameUI:stackUI(info.viewName, nil, info.styles, unpack(params, 1, len))
	end

	if info.func then
		info.func(jump, unpack(params))
	else
		jump()
	end
end

return jumpEasy
