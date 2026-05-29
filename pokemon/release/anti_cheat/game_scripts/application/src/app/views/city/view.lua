-- chunkname: @src.app.views.city.view


local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE
local CHANNELS = {
	news = {
		name = gLanguageCsv.system,
		color = cc.c4b(238, 115, 143, 255)
	},
	world = {
		name = gLanguageCsv.world,
		color = cc.c4b(139, 175, 223, 255)
	},
	union = {
		name = gLanguageCsv.guild,
		color = cc.c4b(204, 143, 223, 255)
	},
	cross = {
		name = gLanguageCsv.crossChat,
		color = cc.c4b(236, 183, 42, 255)
	},
	team = {
		name = gLanguageCsv.formTeam,
		color = cc.c4b(236, 183, 43, 255)
	},
	huodong = {
		name = gLanguageCsv.activity,
		color = cc.c4b(255, 94, 66, 255)
	},
	private = {
		name = gLanguageCsv.privateChat,
		color = cc.c4b(204, 143, 223, 255)
	}
}
local CHAT_PAGE_IDX = {
	team = 5,
	private = 7,
	cross = 4,
	news = 1,
	union = 3,
	world = 2,
	huodong = 6
}
local SCHEDULE_TAG_SYSOPEN_TAG = 1000

local function isClickToday(key)
	local flag = userDefault.getForeverLocalKey(key, "")
	local today = time.getTodayStr()

	return flag == today
end

local function isClickVal(key, val)
	local flag = userDefault.getForeverLocalKey(key, "")

	return flag == tostring(val)
end

local function delURLConfig(str)
	local result = false
	local flags = tonumber(string.sub(str, 2), 2)

	if not flags then
		return str
	end

	local len = string.len(str)

	if len < 5 then
		return str
	end

	local idx = len - 5 + 1

	if string.sub(str, idx, idx) == "0" then
		return str
	end

	local result = string.sub(str, 1, idx - 1) .. "0"

	result = result .. string.sub(str, idx + 1)

	return result
end

local function getLeftBtnsData()
	return {
		{
			icon = "city/main/icon_zc_qd.png",
			viewName = "city.sign_in",
			key = "signIn",
			name = gLanguageCsv.signIn,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "signIn",
					onNode = function(node)
						node:xy(128, 128)
						node:scale(0.9)
					end
				}
			}
		},
		{
			icon = "city/main/icon_zc_hy.png",
			viewName = "city.friend",
			key = "friend",
			name = gLanguageCsv.friend,
			func = function(cb)
				local friendView = require("app.views.city.friend")
				local showType, param = friendView.initFriendShowType()

				friendView.sendProtocol(showType, param, cb)
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"friendStaminaRecv",
						"friendReqs"
					},
					onNode = function(node)
						node:xy(124, 124)
						node:scale(0.9)
					end
				}
			}
		},
		{
			icon = "city/main/icon_zc_ph.png",
			unlockKey = "rank",
			viewName = "city.rank",
			key = "rank",
			name = gLanguageCsv.rank,
			styles = {
				full = true
			},
			func = function(cb)
				sdk.trackEvent("check_powerrank")
				gGameApp:requestServer("/game/rank", function(tb)
					cb(tb.view.rank)
				end, "fight", 0, 10)
			end
		},
		{
			icon = "city/main/icon_zc_gh.png",
			unlockKey = "union",
			key = "union",
			name = gLanguageCsv.guild,
			func = function()
				jumpEasy.jumpTo("union")
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"unionTraining",
						"unionSystemRedPacket",
						"unionMemberRedPacket",
						"unionSendedRedPacket",
						"unionDailyGift",
						"unionLobby",
						"unionContribute",
						"unionFuben",
						"unionFragDonate",
						"unionFightSignUp",
						"unionAnswer"
					},
					onNode = function(node)
						node:xy(128, 128)
						node:scale(0.9)
					end
				}
			}
		}
	}
end

local function getLeftBottomBtnsData(view)
	return {
		{
			icon = "city/icon_xinxi.png",
			viewName = "city.chat.privataly",
			key = "chatPrivataly",
			func = function(cb)
				local msg = gGameModel.messages:read("private")

				if itertools.isempty(msg) then
					gGameUI:showTip(gLanguageCsv.noPrivateChatList)

					return
				end

				cb()
			end
		},
		{
			viewName = "city.mail",
			key = "mail"
		},
		{
			viewName = "city.setting.view",
			key = "setting",
			params = {
				{
					citySceneIdx = view.citySceneIdx
				}
			}
		}
	}
end

local function getMainBtnsData()
	return {
		{
			viewName = "city.adventure.pvp",
			key = "pvp",
			name = gLanguageCsv.pvp,
			styles = {
				full = true
			},
			func = function(cb)
				cb("pvp")
			end
		},
		{
			viewName = "city.adventure.pve",
			key = "pve",
			name = gLanguageCsv.adventure,
			styles = {
				full = true
			},
			func = function(cb)
				cb("pve")
			end
		},
		{
			viewName = "city.gate.view",
			key = "gate",
			name = gLanguageCsv.gate,
			styles = {
				full = true
			}
		}
	}
end

local ViewBase = cc.load("mvc").ViewBase
local CityView = class("CityView", ViewBase)

CityView.RESOURCE_FILENAME = "city.json"
CityView.RESOURCE_BINDING = {
	leftTopPanel = "leftTopPanel",
	activityItem = "activityItem",
	item = "item",
	["leftTopPanel.yeartime"] = "yeartime",
	leftPanel = "leftPanel",
	growGuide = "growGuide",
	["rightPanel.panel"] = "activityPanel",
	["activityTip.textNote2"] = "textNote2",
	bgPanel = "bgPanel",
	["rightPanel.showList"] = "topShowList",
	activityTip = "activityTip",
	bottomItem = "bottomItem",
	["leftBottomPanel.talkPanel.baseTalkPanel"] = "baseTalkPanel",
	["developPanel.listItem"] = "listItem",
	["rightPanel.achievementPanel"] = "achievementPanel",
	["developPanel.bg"] = "developBg",
	rightPanel = "rightPanel",
	["leftTopPanel.daytime"] = "daytime",
	rightBottomPanel = "rightBottomPanel",
	["leftBottomPanel.panel"] = "leftBottomBtnPanel",
	leftBottomPanel = "leftBottomPanel",
	centerBottomPanel = "centerBottomPanel",
	["leftTopPanel.vipNum"] = "vipNum",
	["leftTopPanel.vip"] = "roleVip",
	["leftTopPanel.lv"] = "lvTxt",
	["rightPanel.panel2"] = "activityPanel2",
	["leftTopPanel.level"] = "levelTxt",
	["rightBottomPanel.mainList"] = "mainList",
	["leftTopPanel.name"] = "nameTxt",
	["rightPanel.onlineGiftPanel"] = "onlineGiftPanelItem",
	["leftBottomPanel.talkPanel.baseTalkPanel.list"] = "talkList",
	["rightPanel.go"] = "go",
	["activityTip.textNote1"] = "textNote1",
	["leftBottomPanel.talkPanel.baseTalkPanel.textPos"] = "textPos",
	["rightPanel.titlePanel"] = "titlePanel",
	followPanel = {
		varname = "followPanel",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onFollowClick")
			}
		}
	},
	["leftTopPanel.head"] = {
		binds = {
			{
				event = "click",
				method = bindHelper.self("onPersonalInfo")
			},
			{
				event = "extend",
				class = "role_logo",
				props = {
					level = false,
					vip = false,
					logoId = bindHelper.self("logo"),
					frameId = bindHelper.self("frame")
				}
			}
		}
	},
	["leftTopPanel.powerNum"] = {
		varname = "powerNum",
		binds = {
			event = "text",
			idler = bindHelper.model("role", "top6_fighting_point")
		}
	},
	["rightPanel.achievementPanel.txt"] = {
		binds = {
			{
				event = "effect",
				data = {
					outline = {
						size = 4,
						color = cc.c4b(109, 54, 186, 255)
					}
				}
			}
		}
	},
	["rightPanel.achievementPanel.txt1"] = {
		binds = {
			{
				event = "effect",
				data = {
					outline = {
						size = 4,
						color = cc.c4b(109, 54, 186, 255)
					}
				}
			}
		}
	},
	["rightPanel.achievementPanel.bg"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.defer(function(view)
					view:onClickAchievement()
				end)
			}
		}
	},
	["rightPanel.titlePanel.txt"] = {
		binds = {
			{
				event = "effect",
				data = {
					outline = {
						size = 4,
						color = ui.COLORS.NORMAL.PINK
					}
				}
			}
		}
	},
	["rightPanel.titlePanel.txt1"] = {
		binds = {
			{
				event = "effect",
				data = {
					outline = {
						size = 4,
						color = ui.COLORS.NORMAL.PINK
					}
				}
			}
		}
	},
	["rightPanel.titlePanel.bg"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.defer(function(view)
					idlereasy.do_(function(val)
						for i, v in ipairs(val) do
							if v.key == "title_book" then
								return view:onItemClick(nil, v)
							end
						end
					end, view.developBtns)
				end)
			}
		}
	},
	["leftTopPanel.rechargeItem"] = {
		varname = "rechargeItem",
		binds = {
			{
				event = "touch",
				methods = {
					ended = bindHelper.self("onRechargeClick")
				}
			},
			{
				event = "extend",
				class = "multi_text_effect",
				props = {
					data = gLanguageCsv.recharge,
					effects = {
						{
							outline = {
								size = 6,
								color = cc.c4b(54, 66, 82, 255)
							}
						},
						{
							outline = {
								size = 12,
								color = cc.c4b(255, 255, 255, 255)
							}
						}
					},
					onNode = function(node)
						node:xy(140, 72):z(5)
					end
				}
			}
		}
	},
	["leftPanel.list"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				padding = 10,
				margin = 30,
				data = bindHelper.self("leftBtns"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					node:name(v.key)
					node:get("icon"):texture(v.icon):scale(1.2)
					node:removeChildByName("name")

					local name = label.create(v.name, {
						fontPath = "font/youmi1.ttf",
						fontSize = 30,
						color = ui.COLORS.NORMAL.DEFAULT
					})

					text.addEffect(name, {
						outline = {
							size = 4,
							color = ui.COLORS.NORMAL.WHITE
						}
					})
					name:addTo(node, 5, "name"):xy(60, 20)

					if v.redHint and (v.key ~= "union" or gGameModel.union_training) then
						bind.extend(list, node, v.redHint)
					end

					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.clickCell, v)
						}
					})
					uiEasy.updateUnlockRes(v.unlockKey, node, {
						justRemove = not v.unlockKey,
						pos = cc.p(100, 100)
					}):anonyOnly(list, list:getIdx(k))
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick")
			}
		}
	},
	["leftBottomPanel.panel.btnTalk"] = {
		varname = "btnTalk",
		binds = {
			{
				event = "touch",
				methods = {
					ended = bindHelper.defer(function(view)
						return view:onItemClick(nil, view.leftBottomBtns[1])
					end)
				}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					state = bindHelper.self("talkRedHint"),
					onNode = function(node)
						node:xy(120, 116)
					end
				}
			}
		}
	},
	["leftBottomPanel.panel.btnMsg"] = {
		varname = "btnMsg",
		binds = {
			{
				event = "touch",
				methods = {
					ended = bindHelper.defer(function(view)
						gGameApp:slientRequestServer("/game/sync")

						return view:onItemClick(nil, view.leftBottomBtns[2])
					end)
				}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "mail",
					onNode = function(node)
						node:xy(120, 116)
					end
				}
			}
		}
	},
	["leftBottomPanel.panel.btnSet"] = {
		varname = "btnSetting",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.defer(function(view)
					return view:onItemClick(nil, view.leftBottomBtns[3])
				end)
			}
		}
	},
	["leftBottomPanel.talkPanel.talkbg"] = {
		varname = "talkbg",
		binds = {
			event = "click",
			method = bindHelper.self("onTalkClick")
		}
	},
	["rightPanel.btnExpand"] = {
		varname = "activityExpandBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onActivityExpandClick")
			}
		}
	},
	["rightPanel.panel.list"] = {
		varname = "activityList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("activityBtns"),
				dataOrderCmp = function(a, b)
					return a.sortWeight > b.sortWeight
				end,
				item = bindHelper.self("activityItem"),
				margin = ACTIVITY_LIST_MARGIN,
				itemAction = {
					isAction = true
				},
				onBeforeBuild = function(list)
					list:enableSchedule():unScheduleAll()
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "labelTime")

					if v.id then
						uiEasy.showHoudongId(node, v.id, {
							dy1 = 40,
							dy2 = 0
						})
					end

					childs.icon:texture(v.icon)
					text.addEffect(childs.labelTime, {
						outline = {
							size = 3,
							color = ui.COLORS.OUTLINE.DEFAULT
						}
					})

					if v.endTime then
						CityView.setCountdown(list, childs.labelTime, {
							endTime = v.endTime,
							tag = v.tag
						})
					else
						childs.labelTime:hide()
					end

					if v.redHint then
						bind.extend(list, node, v.redHint)
					end

					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.clickCell, v)
						}
					})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick")
			}
		}
	},
	["rightPanel.panel2.list"] = {
		varname = "activityList2",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("activityBtns2"),
				dataOrderCmp = function(a, b)
					return a.sortWeight > b.sortWeight
				end,
				item = bindHelper.self("activityItem"),
				margin = ACTIVITY_LIST_MARGIN,
				itemAction = {
					isAction = true
				},
				onBeforeBuild = function(list)
					list:enableSchedule():unScheduleAll()
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "labelTime")

					uiEasy.showHoudongId(node, v.id, {
						dy1 = 40,
						dy2 = 0
					})
					childs.icon:texture(v.icon)
					text.addEffect(childs.labelTime, {
						outline = {
							size = 3,
							color = ui.COLORS.OUTLINE.DEFAULT
						}
					})

					if v.endTime then
						CityView.setCountdown(list, childs.labelTime, {
							endTime = v.endTime,
							tag = v.tag
						})
					else
						childs.labelTime:hide()
					end

					if v.redHint then
						bind.extend(list, node, v.redHint)
					end

					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.clickCell, v)
						}
					})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick")
			}
		}
	},
	["centerBottomPanel.actionList"] = {
		varname = "actionList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				margin = 10,
				data = bindHelper.self("actionBtns"),
				item = bindHelper.self("bottomItem"),
				onItem = function(list, node, k, v)
					node:name(v.key)
					node:get("icon"):texture(v.icon)
					node:get("bg"):texture("city/main/panel_icon.png")
					node:get("bg"):scale(0.9)
					node:removeChildByName("name")

					local fontSize = 40

					if matchLanguage({
						"cn",
						"tw"
					}) then
						fontSize = 50
					end

					local name = label.create(v.name, {
						fontPath = "font/youmi1.ttf",
						color = ui.COLORS.NORMAL.DEFAULT,
						fontSize = fontSize
					})

					text.addEffect(name, {
						outline = {
							size = 4,
							color = ui.COLORS.NORMAL.WHITE
						}
					})
					name:addTo(node, 5, "name"):xy(84, 20)

					if v.redHint then
						bind.extend(list, node, v.redHint)
					end

					if v.actionExpandName then
						bind.touch(list, node, {
							methods = {
								ended = functools.partial(list.clickDevelop, node, v)
							}
						})
					else
						bind.touch(list, node, {
							methods = {
								ended = functools.partial(list.clickCell, v)
							}
						})
					end

					uiEasy.updateUnlockRes(v.unlockKey, node, {
						justRemove = not v.unlockKey,
						pos = cc.p(144, 144)
					}):anonyOnly(list, list:getIdx(k))
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
					list:setClippingEnabled(false)
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
				clickDevelop = bindHelper.self("onItemDevelopClick")
			}
		}
	},
	developPanel = {
		varname = "developPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("actionExpandName"),
			method = function(name)
				return name ~= ""
			end
		}
	},
	["developPanel.developList"] = {
		varname = "developList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				backupCached = false,
				yMargin = 10,
				xMargin = 10,
				columnSize = 4,
				data = bindHelper.self("developBtns"),
				item = bindHelper.self("listItem"),
				cell = bindHelper.self("item"),
				onCell = function(list, node, k, v)
					node:size(170, 170)
					node:scaleY(-1)
					node:name(v.key)
					node:get("icon"):texture(v.icon):y(90):x(node:width() / 2)
					node:get("bg"):hide()
					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.clickCell, v)
						}
					})
					node:removeChildByName("name")

					local fontSize = matchLanguage({
						"kr"
					}) and 34 or 38
					local name = ccui.Text:create(v.name, "font/youmi1.ttf", fontSize):anchorPoint(cc.p(0.5, 0.5)):xy(node:width() / 2, 15):addTo(node, 5, "name")

					name:getVirtualRenderer():setLineSpacing(-10)
					text.addEffect(name, {
						color = ui.COLORS.NORMAL.DEFAULT,
						outline = {
							size = 4,
							color = ui.COLORS.NORMAL.WHITE
						}
					})
					adapt.setTextAdaptWithSize(name, {
						vertical = "top",
						horizontal = "center",
						size = cc.size(180, 80)
					})
					node:get("icon"):scale(1.5)

					if v.redHint then
						bind.extend(list, node, v.redHint)
					end

					v.unlockRes = uiEasy.updateUnlockRes(v.unlockKey, node, {
						justRemove = not v.unlockKey,
						specialLock = v.specialLock,
						pos = cc.p(125, 125)
					}):anonyOnly(list, list:getIdx(k))
				end,
				dataOrderCmp = function(a, b)
					local keyA = gUnlockCsv[a.unlockKey]
					local keyB = gUnlockCsv[b.unlockKey]

					if keyA and keyB then
						if csv.unlock[keyA].startLevel == csv.unlock[keyB].startLevel then
							return keyA < keyB
						end

						return csv.unlock[keyA].startLevel < csv.unlock[keyB].startLevel
					elseif not keyA and not keyB then
						return false
					else
						return keyA == nil
					end
				end,
				onAfterBuild = function(list)
					list:adaptTouchEnabled()
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick")
			}
		}
	},
	["rightBottomPanel.btnPvp"] = {
		varname = "itemPvp",
		binds = {
			{
				event = "touch",
				methods = {
					ended = bindHelper.defer(function(view)
						return view:onItemClick(nil, view.mainBtns[1])
					end)
				}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = {
						"arenaAward",
						"crossArenaAward",
						"onlineFightAward",
						"crossSupremacyWeek",
						"crossSupremacyAward",
						"crossUnionAdventure",
						"onlineAutoChessGrade",
						"onlineAutoChessGaming"
					},
					onNode = function(node)
						node:xy(244, 244)
					end
				}
			}
		}
	},
	["rightBottomPanel.btnPvp.namePanel"] = {
		binds = {
			event = "extend",
			class = "multi_text_effect",
			props = {
				data = gLanguageCsv.pvp,
				effects = {
					{
						outline = {
							size = 4,
							color = ui.COLORS.NORMAL.WHITE
						}
					}
				},
				labelParams = {
					fontPath = "font/youmi1.ttf",
					fontSize = 60,
					color = ui.COLORS.NORMAL.DEFAULT
				},
				onNode = function(node)
					node:xy(95, 50):z(5)
				end
			}
		}
	},
	["rightBottomPanel.btnAdventure"] = {
		varname = "itemAdventure",
		binds = {
			{
				event = "touch",
				methods = {
					ended = bindHelper.defer(function(view)
						return view:onItemClick(nil, view.mainBtns[2])
					end)
				}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = {
						"dispatchTask",
						"abyssEndlessTowerAward",
						"randomTower",
						"randomTowerPoint",
						"gymChallenge",
						"cloneBattle",
						"braveChallengeAch"
					},
					listenData = {
						sign = game.BRAVE_CHALLENGE_TYPE.common
					},
					onNode = function(node)
						node:xy(244, 244)
					end
				}
			}
		}
	},
	["rightBottomPanel.btnAdventure.namePanel"] = {
		binds = {
			event = "extend",
			class = "multi_text_effect",
			props = {
				data = gLanguageCsv.adventure,
				effects = {
					{
						outline = {
							size = 4,
							color = ui.COLORS.NORMAL.WHITE
						}
					}
				},
				labelParams = {
					fontPath = "font/youmi1.ttf",
					fontSize = 60,
					color = ui.COLORS.NORMAL.DEFAULT
				},
				onNode = function(node)
					node:xy(95, 50):z(5)
				end
			}
		}
	},
	["rightBottomPanel.btnPve"] = {
		varname = "itemPve",
		binds = {
			{
				event = "touch",
				clicksafe = true,
				methods = {
					ended = bindHelper.defer(function(view)
						return view:onItemClick(nil, view.mainBtns[3])
					end)
				}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "pve",
					onNode = function(node)
						node:xy(244, 244)
					end
				}
			}
		}
	},
	["rightBottomPanel.btnPve.namePanel"] = {
		binds = {
			event = "extend",
			class = "multi_text_effect",
			props = {
				data = gLanguageCsv.gate,
				effects = {
					{
						outline = {
							size = 4,
							color = ui.COLORS.NORMAL.WHITE
						}
					}
				},
				labelParams = {
					fontPath = "font/youmi1.ttf",
					fontSize = 60,
					color = ui.COLORS.NORMAL.DEFAULT
				},
				onNode = function(node)
					node:xy(95, 50):z(5)
				end
			}
		}
	},
	["growGuide.textNote1"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = ui.COLORS.OUTLINE.DEFAULT
				}
			}
		}
	},
	marqueePanel = {
		varname = "marqueePanel",
		binds = {
			event = "extend",
			class = "marquee"
		}
	}
}

function CityView:onCreate()
	self.developList:setClippingEnabled(false)

	self.cityTopView = gGameUI.topuiManager:createView("city", self):init()

	self:enableSchedule()
	self:initModel()

	local subInject = {
		"app.views.city.view_scene",
		"app.views.city.view_action",
		"app.views.city.view_activity"
	}

	for _, name in ipairs(subInject) do
		local inject = require(name)

		inject(CityView)
	end

	idlereasy.when(self.vipHide, function(_, vipHide)
		self.roleVip:visible(not vipHide)
		self.vipNum:visible(not vipHide)
	end)
	idlereasy.when(self.vipLevel, function(_, vipLevel)
		local isSupreme = vipLevel >= game.VIP_SUPREME
		local vipStr = uiEasy.getVipStr(vipLevel)

		self.roleVip:text(vipStr.title):setFontSize(isSupreme and 30 or 24)
		self.vipNum:text(vipStr.level):setFontSize(isSupreme and 40 or 48)

		local normalColor = cc.c4b(241, 59, 84, 255)
		local numColor = isSupreme and cc.c4b(255, 153, 35, 255) or normalColor
		local textColor = isSupreme and cc.c4b(255, 237, 40, 255) or normalColor

		text.addEffect(self.roleVip, {
			color = textColor,
			outline = {
				color = numColor,
				size = isSupreme and 4 or 0
			}
		})
		text.addEffect(self.vipNum, {
			color = numColor
		})
		self.roleVip:xy(455 + (isSupreme and 18 or 0), self.powerNum:y() + (isSupreme and 4 or 0))
		self.vipNum:y(self.powerNum:y())
		adapt.oneLinePos(self.roleVip, self.vipNum, cc.p(10, 0), "left")
	end)
	self.baseTalkPanel:get("list"):setScrollBarEnabled(false)
	idlereasy.any({
		self.level,
		self.roleName
	}, function(obj, level, name)
		self.levelTxt:text(level)
		self.lvTxt:text(gLanguageCsv.textLv1)
		self.nameTxt:text(name)

		local width = math.max(630, self.nameTxt:x() + self.nameTxt:width() + 40)

		self.leftTopPanel:get("bg"):width(width)

		if matchLanguage({
			"cn"
		}) then
			adapt.oneLinePos(self.levelTxt, self.lvTxt)
			adapt.oneLinePos(self.lvTxt, self.nameTxt, cc.p(15, 0), "left")

			local powerX = cc.clampf(self.leftTopPanel:get("power"):x() + (width - self.leftTopPanel:get("bg"):width()) / 2, 275, 300)

			self.leftTopPanel:get("power"):x(powerX)
		else
			adapt.oneLinePos(self.levelTxt, self.nameTxt, cc.p(15, 0), "left")
		end

		text.addEffect(self.nameTxt, {
			color = cc.c4b(255, 255, 255, 255)
		})
		self.followPanel:x(self.leftTopPanel:x() + width + 90)
	end)
	self.topShowList:setScrollBarEnabled(false)

	self.actionExpandName = idler.new("")
	self.autoNewPlayerWealId = idler.new(0)

	self:initData()
	self:initTitlePanel()
	self:initTalkPanel()
	self:initGrowPanel()
	self:achievementTip()
	self:medalCollectionTip()

	self.autoPopBoxInfo = {}

	self:initPoster()

	local lastSignInDay = gGameModel.monthly_record:read("last_sign_in_day")

	if lastSignInDay < time.getNowDate().day then
		table.insert(self.autoPopBoxInfo, {
			viewName = "city.sign_in",
			params = {
				true
			}
		})
	end

	self:initAutoNewPlayerWeal()
	self:initSkinGive()
	self:checkPopBox(true)

	local curMusicIdx = userDefault.getForeverLocalKey("musicIdx", 1)
	local cfg = csv.citysound[curMusicIdx]

	if cfg then
		audio.playMusic(cfg.path)
	else
		printWarn("music index not exist", curMusicIdx)
	end

	self.isRefresh = idler.new(false)

	idlereasy.any({
		self.level,
		self.isRefresh
	}, function(_, level, isRefresh)
		self:unSchedule(SCHEDULE_TAG_SYSOPEN_TAG)

		local cfgT = {}
		local date = time.getNowDate()
		local curTime = date.hour * 100 + date.min
		local wday = date.wday

		wday = wday == 1 and 7 or wday - 1

		local nextTime = math.huge

		local function isOK(v)
			if v.reminder ~= 2 and v.roundKey then
				local roundState = gGameModel.role:read(v.roundKey)

				if roundState ~= v.roundState then
					return false
				end
			elseif v.reminder == 2 then
				local roundState = gGameModel.role:read(v.roundKey)

				if roundState == nil or tostring(roundState) == v.roundState then
					return false
				end
			end

			if v.unionlevel then
				local unionId = gGameModel.role:read("union_db_id")
				local unionLv = gGameModel.union:read("level")

				if not unionId or unionLv < v.unionlevel then
					return false
				end
			end

			if dataEasy.serverOpenDaysLess(v.serverday) then
				return false
			end

			if not itertools.include(v.openseq, wday) then
				return false
			end

			if curTime < v.startTime or curTime >= v.endTime then
				return false
			end

			return true
		end

		for k, v in orderCsvPairs(csv.sysopen) do
			if v.feature == "" or dataEasy.isUnlock(v.feature) then
				if (v.reminder == 0 or v.reminder == 1 and not isClickToday("sysOpen" .. v.sighid) or v.reminder == 2 and not isClickVal("sysOpen" .. v.sighid, gGameModel.role:read(v.roundKey))) and isOK(v) and (v.goto ~= "townHome" or dataEasy.isTownBuildingUnlock(game.TOWN_BUILDING_ID.PARTY)) then
					table.insert(cfgT, v)
				end

				local todayNum = tonumber(time.getTodayStr())

				if csvSize(v.startTimes) > 0 then
					for _, startTime in csvMapPairs(v.startTimes) do
						local dt = time.getNumTimestamp(todayNum, startTime / 100, startTime % 100) - time.getTime()

						if dt < 0 then
							dt = dt + 86400
						end

						nextTime = math.min(nextTime, dt)
					end
				else
					local dt = time.getNumTimestamp(todayNum, v.startTime / 100, v.startTime % 100) - time.getTime()

					if dt < 0 then
						dt = dt + 86400
					end

					nextTime = math.min(nextTime, dt)
				end
			end
		end

		table.sort(cfgT, function(a, b)
			return a.priority > b.priority
		end)
		self:initActivityTip(cfgT[1])
		self:schedule(function()
			self.isRefresh:notify()

			return false
		end, nextTime, nextTime, SCHEDULE_TAG_SYSOPEN_TAG)
	end)
	self:enableMessage():registerMessage("adapterNotchScreen", function(flag)
		adaptUI(self:getResourceNode(), "city.json", flag)
	end)
	self:registerMessage("stackUIViewExit", function(_, parentName)
		if parentName == "city.view" then
			performWithDelay(self, function()
				self:checkPopBox()
				self:refreshBaibian()
				self:refreshMysteryShop()
				self:refreshHuodongBoss()
				self:checkAchievementForGameUI()
				self.isRefresh:notify()

				if self.followCardId then
					self.followCardId:notify()
				end
			end, 0)
		end
	end)
	self:setGameSyncTimer()
	self:setHorseRaceTimer()
	self:specialGiftLink()
	self:setTimeLabel()
	self:setSecialSupport()

	if device.platform == "windows" then
		for _, card in gGameModel.cards:pairs() do
			local cardId = card:read("card_id")

			if not csv.cards[cardId] then
				gGameUI:showDialog({
					content = string.format("数据中包含未开放的卡牌%d, 检查本地 language 与服务器是否一致", cardId)
				})

				break
			end
		end
	end

	gGameModel.role:getIdler("rmb_consume"):addListener(function(val, oldval, _)
		local currentTime = time.getTime()
		local createdTime = gGameModel.role:read("created_time")
		local timeGap = currentTime - createdTime
		local time24 = 86400
		local time48 = 172800
		local isTime24 = timeGap <= time24
		local isTime48 = timeGap <= time48

		if val >= 1000 and oldval < 1000 and isTime24 then
			sdk.trackEvent("dia_24h_1k")
		end

		if val >= 2000 and oldval < 2000 and isTime24 then
			sdk.trackEvent("dia_24h_2k")
		end

		if val >= 3000 and oldval < 3000 and isTime24 then
			sdk.trackEvent("dia_24h_3k")
		end

		if val >= 5000 and oldval < 5000 and isTime24 then
			sdk.trackEvent("dia_24h_5k")
		end

		if val >= 8000 and oldval < 8000 and isTime48 then
			sdk.trackEvent("dia_48h_8k")
		end

		if val >= 10000 and oldval < 10000 and isTime48 then
			sdk.trackEvent("dia_48h_10K")
		end
	end)
	dataEasy.getListenUnlock(gUnlockCsv.timeSpeeder, function(isUnlock)
		local hide = userDefault.getForeverLocalKey("timeSpeederIconHide", false)
		local scheduler = display.director:getScheduler()

		if isUnlock and scheduler.setSpeedUp then
			local enabled = userDefault.getForeverLocalKey("timeSpeederViewEnabled", false)

			gGameUI.timeSpeederManager.setTimeSpeedEnabled(enabled)

			local speed = userDefault.getForeverLocalKey("timeSpeederViewSpeeed", 1)

			gGameUI.timeSpeederManager.setTimeSpeed(speed)

			if not hide then
				gGameUI.timeSpeederLayer:show()

				if not self.timeSpeederShowAni then
					self.timeSpeederShowAni = true

					gGameUI.timeSpeederIconView:showAni()
				end
			else
				gGameUI.timeSpeederLayer:hide()
			end
		else
			gGameUI.timeSpeederLayer:hide()
		end
	end)

	if dev.SHOW_GAIN_ITEMS then
		local editor = gGameUI.scene.clientEditor

		editor:showItems(true)
	end

	adapt.setTextScaleWithWidth(self.growGuide:get("textNote1"), nil, 240)
end

function CityView:onClose()
	self:unregisterMessage("stackUIViewExit")

	self.onlineGiftPanel = nil

	ViewBase.onClose(self)
end

function CityView:initModel()
	self.level = gGameModel.role:getIdler("level")
	self.roleName = gGameModel.role:getIdler("name")
	self.levelExp = gGameModel.role:getIdler("level_exp")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.vipHide = gGameModel.role:getIdler("vip_hide")
	self.logo = gGameModel.role:getIdler("logo")
	self.frame = gGameModel.role:getIdler("frame")
	self.allChannel = gGameModel.messages:getIdler("all")
	self.friendMessage = gGameModel.messages:getIdler("private")
	self.id = gGameModel.role:getIdler("id")
	self.figure = gGameModel.role:getIdler("figure")
	self.title = gGameModel.role:getIdler("title_id")
	self.titles = gGameModel.role:getIdler("titles")
	self.yyOpen = gGameModel.role:getIdler("yy_open")
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.yy_endtime = gGameModel.role:read("yy_endtime")
	self.citySprites = gGameModel.role:getIdler("city_sprites")
	self.spriteGiftTimes = gGameModel.daily_record:getIdler("city_sprite_gift_times")
	self.mysteryShopLastTime = gGameModel.mystery_shop:getIdler("last_active_time")
	self.growGuideData = gGameModel.role:getIdler("grow_guide")
	self.tasks = gGameModel.role:getIdler("achievement_tasks")
	self.medalTasks = gGameModel.role:getIdler("medal_task")
	self.achiBoxes = gGameModel.role:getIdler("achievement_box_awards")
	self.redHintRefresh = idler.new(true)
	self.crossFishingRound = gGameModel.role:getIdler("cross_fishing_round")
	self.fishingSelectScene = gGameModel.fishing:getIdler("select_scene")
	self.fishingIsAuto = gGameModel.fishing:getIdler("is_auto")
	self.reunion = gGameModel.role:getIdler("reunion")
end

function CityView:stackUI(name, handlers, styles, ...)
	gGameUI:stackUI(name, handlers, styles, ...)
end

function CityView:initData()
	self.citySceneIdx = idler.new(dataEasy.getCitySceneIdx())
	self.leftBtns = getLeftBtnsData()
	self.leftBottomBtns = getLeftBottomBtnsData(self)
	self.mainBtns = getMainBtnsData()

	self:initActionData()
	self:initSceneData()
	self:initActivityData()
end

function CityView:onPersonalInfo()
	self:stackUI("city.personal.info", nil, {
		full = true
	}, self:createHandler("addCitySprites"))
end

function CityView:initTitlePanel()
	local originX = self.titlePanel:x()

	idlereasy.when(self.titles, function(_, val)
		if gGameModel.role.title_queue then
			self.titlePanel:show()
			transition.executeSequence(self.titlePanel, true):moveTo(2, originX - self.titlePanel:width()):delay(1):moveTo(2, originX):done()

			gGameModel.role.title_queue = nil
		else
			self.titlePanel:hide()
		end
	end)
end

function CityView:onItemClick(list, v)
	if v.unlockKey then
		if v.unlockKey == "handbook" then
			sdk.trackEvent("check_pokedex")
		end

		if not dataEasy.isUnlock(v.unlockKey) then
			gGameUI:showTip(dataEasy.getUnlockTip(v.unlockKey))

			return
		end

		if v.specialLock then
			if v.unlockKey == "totem" then
				local cfg = csv.unlock[gUnlockCsv.totem]

				gGameUI:showTip(string.format(gLanguageCsv.totemTownExplorationUnlock, cfg.startLevel))
			end

			if v.unlockKey == "meteorite" then
				gGameUI:showTip(gLanguageCsv.meteoriteSpeicalLock)
			end

			return
		end
	end

	local isInGuiding, _, stageId = gGameUI.guideManager:isInGuiding()

	if v.key == "pvp" and isInGuiding and stageId == 315 then
		jumpEasy.jumpTo("crossCircus")

		return
	end

	if v.func then
		v.func(function(...)
			local params = {}

			if v.independent == 4 or v.independent == 5 then
				if v.independent == 4 then
					params = {
						"main",
						v.params[1]
					}
				else
					params = {
						"award",
						v.params[1]
					}
				end
			else
				params = clone(v.params or {})

				for _, v in ipairs({
					...
				}) do
					table.insert(params, v)
				end
			end

			self:stackUI(v.viewName, nil, v.styles, unpack(params))
		end, v.params or {})
	elseif v.viewName then
		self:stackUI(v.viewName, nil, v.styles, unpack(v.params or {}))
	end

	self.actionExpandName:set("")
end

function CityView:onItemDevelopClick(list, node, v)
	local x, y = node:xy()
	local pos = list:convertToWorldSpace(cc.p(x, y))

	self.developPanel:x(pos.x)
	self.actionExpandName:modify(function(name)
		if v.actionExpandName ~= name then
			return true, v.actionExpandName
		end

		return true, ""
	end)
end

function CityView:onRechargeClick()
	self:stackUI("city.recharge", nil, {
		full = true
	})
end

function CityView:onTalkClick()
	self:stackUI("city.chat.view", nil, {
		clickClose = true
	}, self.charIdx)
end

function CityView:onTalkExpandClick()
	self.talkExpand:modify(function(val)
		return true, not val
	end)
end

function CityView:onActivityExpandClick()
	self.activityExpand:modify(function(val)
		return true, not val
	end)
end

function CityView:initTalkPanel()
	self.charIdx = CHAT_PAGE_IDX.world
	self.talkRedHint = idler.new(false)

	idlereasy.when(self.allChannel, function(obj, messages)
		local round = gGameModel.global_record:read("cross_chat_round")
		local crossChatOpen = false

		if round == "start" and dataEasy.isUnlock(gUnlockCsv.crossChat) then
			crossChatOpen = true
		end

		if messages and #messages > 0 then
			for i = #messages, 1, -1 do
				local message = messages[i]

				if (message.channel ~= "cross" or crossChatOpen) and message.channel ~= "private" and message.channel ~= "official" and CHAT_PAGE_IDX[message.channel] and message.msg ~= "" then
					self.charIdx = CHAT_PAGE_IDX[message.channel]

					local childs = self.baseTalkPanel:multiget("textChannel", "bg", "textPos", "list")

					childs.textChannel:text(CHANNELS[message.channel].name)
					text.addEffect(childs.textChannel, {
						color = CHANNELS[message.channel].color
					})

					local emojiKey = string.match(message.msg, "%[(%w+)%]")
					local newText = message.msg

					if gEmojiCsv[emojiKey] then
						newText = "#C0xA7F247#[" .. gEmojiCsv[emojiKey].text .. "]"
					end

					local showText

					if itertools.first(game.MESSAGE_SHOW_TYPE[message.type], 3) then
						showText = message.args and message.args.name or message.role.name
						showText = showText and showText .. ": " .. newText or newText
					else
						showText = message.msg
					end

					for i, v in csvMapPairs(csv.color) do
						showText = string.gsub(showText, v.key, v.exchange)
					end

					childs.textPos:removeAllChildren()
					childs.list:removeAllChildren()

					local p1, p2, s1 = string.find(showText, "#(L[^#]+)#")

					while p1 do
						local s2 = delURLConfig(s1)
						local str = string.sub(showText, 1, p1)

						showText = str .. s2 .. string.sub(showText, p2)
						p1, p2, s1 = string.find(showText, "#(L[^#]+)#", p2 + 1)
					end

					beauty.singleTextAutoScroll({
						speed = 108,
						waitTimeEnd = 2,
						align = "left",
						fontSize = 36,
						waitTimeSt = 2,
						isRich = true,
						style = 1,
						strs = showText,
						list = childs.list,
						anchor = cc.p(0, 0.5),
						vertical = cc.VERTICAL_TEXT_ALIGNMENT_CENTER
					})
					self.baseTalkPanel:show()

					return
				end
			end
		end

		self.baseTalkPanel:hide()
	end)

	local listPositionX = self.talkList:getInnerContainer():getPositionX()
	local deltaX = 0
	local boundX = 5

	local function openTalkView(sender, eventType)
		if eventType == ccui.TouchEventType.began then
			deltaX = 0
		elseif eventType == ccui.TouchEventType.moved then
			if deltaX <= boundX then
				local newPositionX = self.talkList:getInnerContainer():getPositionX()

				deltaX = deltaX + math.abs(newPositionX - listPositionX)
				listPositionX = newPositionX
			end
		elseif eventType == ccui.TouchEventType.ended then
			if deltaX < boundX then
				self:onTalkClick()
			end

			deltaX = 0
			listPositionX = self.talkList:getInnerContainer():getPositionX()
		end
	end

	self.talkList:addTouchEventListener(function(sender, eventType)
		openTalkView(sender, eventType)
	end)

	self.chatPrivatalyLastId = gGameModel.forever_dispatch:getIdlerOrigin("chatPrivatalyLastId")

	idlereasy.any({
		self.friendMessage,
		self.chatPrivatalyLastId
	}, function(_, msg, chatPrivatalyLastId)
		local msgSize = itertools.size(msg)
		local lastMsg = msg[msgSize]

		if msg and msgSize ~= 0 and chatPrivatalyLastId < lastMsg.id and not lastMsg.isMine then
			self.talkRedHint:set(true, true)
		else
			self.talkRedHint:set(false)
		end
	end)
end

function CityView:initPoster()
	self.posterState = idler.new(false)

	local posterShow = userDefault.getForeverLocalKey("posterLoginShow", false, {
		rawKey = true
	})

	if posterShow then
		return
	end

	local data = {}

	self.posterIds = {}

	local posterNotShowInfo = userDefault.getCurrDayKey("posterNotShowInfo", {})
	local newPlayerWeffare = gGameModel.currday_dispatch:getIdlerOrigin("newPlayerWeffare"):read()

	for _, id in ipairs(self.yyOpen:read()) do
		local cfg = csv.yunying.yyhuodong[id]

		if cfg.type == YY_TYPE.clientShow and cfg.independent == -1 and not posterNotShowInfo[id] then
			local function insertPoster()
				self.posterIds[id] = true

				table.insert(data, {
					viewName = "city.activity.poster",
					id = id,
					sortWeight = cfg.sortWeight,
					params = {
						{
							id = id,
							cfg = cfg,
							state = self:createHandler("posterState"),
							onLimitBoxReFreshRedHint = self:createHandler("onReFreshRedHint")
						}
					}
				})
			end

			if cfg.clientParam.isReunion then
				local reunion = self.reunion:read()

				if reunion and reunion.role_type == 1 then
					for k, v in ipairs(self.yyOpen:read()) do
						if v == reunion.info.yyID and reunion.info.end_time > time.getTime() then
							insertPoster()
						end
					end
				end
			elseif cfg.clientParam.showIntervalDay then
				local t = userDefault.getForeverLocalKey("activity", {})
				local date = t[id] or 0
				local showIntervalDay = cfg.clientParam.showIntervalDay
				local preDate = tonumber(time.getStrInClock(time.getTime() - showIntervalDay * 86400))

				if date <= preDate then
					insertPoster()
				end
			else
				insertPoster()
			end
		end
	end

	if not itertools.isempty(data) then
		table.sort(data, function(a, b)
			if a.sortWeight ~= b.sortWeight then
				return a.sortWeight < b.sortWeight
			end

			return a.id < b.id
		end)

		data[#data].params[1].cb = self:createHandler("onPosterCb")

		arraytools.merge_inplace(self.autoPopBoxInfo, {
			data
		})
	end
end

function CityView:onPosterCb()
	if self.posterState:read() then
		userDefault.setCurrDayKey("posterNotShowInfo", self.posterIds)
	end
end

function CityView:checkPopBox(isFirst)
	local function normalPopBox()
		if dev.IGNORE_POPUP_BOX then
			return
		end

		if isFirst and self.hasCheckPopBoxFirst then
			return
		end

		self.hasCheckPopBoxFirst = true

		if not itertools.isempty(self.autoPopBoxInfo) then
			local data = self.autoPopBoxInfo[1]

			if data.viewName == "city.activity.poster" then
				userDefault.setForeverLocalKey("posterLoginShow", true, {
					rawKey = true
				})
			end

			table.remove(self.autoPopBoxInfo, 1)

			if data.func then
				data.func(function()
					self:stackUI(data.viewName, nil, data.styles, unpack(data.params or {}))
				end)
			else
				self:stackUI(data.viewName, nil, data.styles, unpack(data.params or {}))
			end

			return true
		end

		if self:onSpecialChannelID() then
			return true
		end

		local flag = userDefault.getForeverLocalKey("privilegeCustomerClick", false)

		-- if matchLanguage({
		-- 	"tw"
		-- }) and not flag and self.vipLevel:read() >= 10 then
		-- 	gGameUI:stackUI("city.activity.privilege_customer")

		-- 	return true
		-- end

		if self:checkCrossCircusGuide() then
			return true
		end
		
		-- 暂时不检查pvp结束显示
		-- if self:initPvpOverShow() then
		-- 	return true
		-- end
	end

	gGameUI:disableTouchDispatch(0.016666666666666666)
	performWithDelay(self, function()
		if gGameUI.guideManager:isInGuiding() then
			return
		end

		local _, name = gGameUI:getTopStackUI()

		if name ~= "city.view" then
			return
		end

		if not game.hasCheckOnlineFight and gGameModel.role:read("in_cross_online_fight_battle") then
			game.hasCheckOnlineFight = true

			gGameUI:showDialog({
				isRich = true,
				clearFast = true,
				btnType = 2,
				content = "#C0x5B545B#" .. gLanguageCsv.onlineFightReconnection,
				cb = function()
					dataEasy.onlineFightLoginServer(self, normalPopBox)
				end,
				closeCb = normalPopBox
			})

			return
		end

		if not game.hasCheckOnlineChessFignt and gGameModel.role:read("in_cross_online_autochess_battle") then
			game.hasCheckOnlineChessFignt = true

			gGameUI:showDialog({
				isRich = true,
				clearFast = true,
				btnType = 2,
				content = gLanguageCsv.onlineAutoChessReconnection,
				cb = function()
					dataEasy.onlineChessLoginServer({
						errCb = normalPopBox
					})
				end,
				closeCb = normalPopBox
			})

			return
		end

		normalPopBox()
	end, 0.016666666666666666)
end

function CityView:onSpecialChannelID()
	if sdk.loginInfo then
		local t = json.decode(sdk.loginInfo)

		if t and t.channelId == "21" then
			local flag = userDefault.getCurrDayKey("baiduAccountUpdaterTip", false, {
				rawKey = true
			})

			if not flag then
				userDefault.setCurrDayKey("baiduAccountUpdaterTip", true, {
					rawKey = true
				})

				local content = "#C0x5B545B#亲爱的训练家：\n\n由于平台游戏账户升级，我们特别提醒使用百度平台游戏的玩家，请前往应用商店手动下载最新的游戏安装包进行更新替换。具体步骤如下：\n1.打开【百度APP】-搜索【百度游戏】进入-搜索【口袋觉醒】下载安装；\n2.用您之前的百度账号进入游戏创建新角色至新手引导通关；\n3.继续在旧游戏包内进行游戏直到无法登录（大约2-3个工作日）；\n4.旧游戏包无法登陆后直接在新游戏安装包内就可以登录游戏；\n5.稳定在新包登录几天后删除旧安装包即可。\n\n温馨提示：旧安装包后续可能出现卡顿、无法登录等情况，请各位训练家尽快下载新包，在等待账号升级的时间，旧安装包可以正常游戏，本次操作不会影响到您的区服角色信息。\n#C0x45B1FF##L10100##LULhttps://game-union.cdn.bcebos.com/apk/202412/com.happytoo.kdjx.g.baidu_v3.1.0.111168_60018.apk#【跳转链接】#L0##C0x5B545B#\n感谢各位训练家的理解！如有任何问题请您及时联系客服QQ：3008086559咨询，祝大家游戏愉快！"

				gGameUI:showDialog({
					title = "百度账号升级提示",
					fontSize = 40,
					isRich = true,
					align = "left",
					content = content,
					dialogParams = {
						clearFast = true,
						clickClose = false
					}
				})

				return true
			end
		end
	end
end

function CityView:checkCrossCircusGuide()
	if not dataEasy.isUnlock(gUnlockCsv.crossCircus) then
		return
	end

	if gGameModel.role:read("cross_circus_round") == "closed" or gGameUI.guideManager:checkFinished(315) then
		return
	end

	gGameUI.guideManager:checkGuide({
		specialName = "crossCircus1",
		callFunc = function(key)
			if key == "crossCircusCity" then
				jumpEasy.jumpTo("crossCircus")
			end
		end
	})

	return true
end

function CityView:initAutoNewPlayerWeal()
	local newPlayerWeffare = gGameModel.currday_dispatch:getIdlerOrigin("newPlayerWeffare"):read()

	if newPlayerWeffare == true then
		return
	end

	idlereasy.when(self.autoNewPlayerWealId, function(_, id)
		if id > 0 then
			table.insert(self.autoPopBoxInfo, {
				viewName = "city.activity.recharge_feedback.new_player_welfare",
				params = {
					id
				},
				func = function(cb)
					gGameApp:requestServer("/game/yy/active/get", function(tb)
						cb()
					end)
				end
			})
			self.autoNewPlayerWealId:set(-1)
		end
	end)
end

function CityView:initSkinGive()
	local skinGiveData = gGameModel.role:read("compensate_skin") or {}

	if itertools.size(skinGiveData) <= 0 or game.SKIN_GIVE or skinGiveData.src == 0 or skinGiveData.gain == 0 then
		return
	end

	table.insert(self.autoPopBoxInfo, {
		viewName = "city.skin_unlock",
		params = {
			skinGiveData
		}
	})

	for i, v in ipairs(skinGiveData) do
		table.insert(self.autoPopBoxInfo, {
			viewName = "city.card.skin.award",
			params = {
				v.gain
			}
		})
	end
end

function CityView:initPvpOverShow()
	local overInfo = gGameModel.role:read("play_end_sync_info")

	if itertools.size(overInfo) == 0 then
		return
	end

	local unclock = {
		cross_arena = "crossArena",
		cross_union_adventure = "crossUnionAdventure",
		cross_circus = "crossCircus",
		cross_mine = "crossMine",
		cross_supremacy = "crossSupremacy",
		cross_online_fight = "onlineFight",
		union_fight = "unionFight",
		craft = "craft",
		cross_craft = "crossCraft"
	}
	local showData = userDefault.getForeverLocalKey("pvpOverShowDate", {})

	for k, v in pairs(overInfo) do
		if unclock[k] and dataEasy.isUnlock(unclock[k]) and v.date and showData[k] ~= v.date then
			gGameUI:stackUI("city.pvp.over_show.view")

			return true
		end
	end
end

function CityView:initActivityTip(data)
	if not data then
		self.activityTip:hide()
		self.activityTip:removeChildByName("gojt")

		return
	end

	widget.addAnimationByKey(self.activityTip, "huodongtixing/huodongtixing.skel", "gojt", "effect_loop", 1):alignCenter(self.activityTip:size())

	local name = data.name or csv.unlock[gUnlockCsv[data.feature]].name

	self.activityTip:get("textNote1"):text(name)
	adapt.setTextAdaptWithSize(self.activityTip:get("textNote1"), {
		vertical = "center",
		horizontal = "center",
		size = cc.size(180, 40)
	})
	self.activityTip:get("textNote2"):text(data.txt)
	adapt.setTextAdaptWithSize(self.activityTip:get("textNote2"), {
		vertical = "center",
		horizontal = "center",
		size = cc.size(180, 40)
	})

	if matchLanguageForce({
		"en_us"
	}) then
		self.activityTip:get("textNote1"):hide()
		self.activityTip:get("textNote2"):hide()
		self.activityTip:removeChildByName("textNoteAuto1")
		self.activityTip:removeChildByName("textNoteAuto2")
		beauty.singleTextAutoScroll({
			fontSize = 30,
			style = 1,
			align = "center",
			size = cc.size(180, 40),
			strs = name,
			effect = {
				color = ui.COLORS.NORMAL.DEFAULT
			},
			vertical = cc.VERTICAL_TEXT_ALIGNMENT_CENTER
		}):addTo(self.activityTip, 1, "textNoteAuto1"):xy(20, 60)
		beauty.singleTextAutoScroll({
			style = 1,
			fontSize = 30,
			align = "center",
			size = cc.size(180, 40),
			strs = data.txt,
			effect = {
				color = ui.COLORS.NORMAL.DEFAULT
			}
		}):addTo(self.activityTip, 1, "textNoteAuto2"):xy(20, 20)
	end

	bind.touch(self, self.activityTip, {
		methods = {
			ended = function()
				if data.reminder == 2 then
					userDefault.setForeverLocalKey("sysOpen" .. data.sighid, tostring(gGameModel.role:read(data.roundKey)))
				else
					userDefault.setForeverLocalKey("sysOpen" .. data.sighid, time.getTodayStr())
				end

				jumpEasy.jumpTo(data.goto)

				if data.reminder ~= 0 then
					self.isRefresh:notify()
				end
			end
		}
	})
	self.activityTip:show()
end

function CityView:initGrowPanel()
	local growGuideListen = {
		self.growGuideData
	}

	for _, v in ipairs(gGrowGuideCsv) do
		table.insert(growGuideListen, dataEasy.getListenUnlock(v.feature))
	end

	idlereasy.any(growGuideListen, function(_, growGuideData, ...)
		local unlocks = {
			...
		}
		local itemDatas = {}
		local count = 0

		for _, v in ipairs(gGrowGuideCsv) do
			local csvId = v.id

			count = count + 1

			if not growGuideData or not growGuideData[csvId] or growGuideData[csvId][1] ~= 0 then
				local data = {}

				data.cfg = v
				data.csvId = csvId

				local state = 3

				if growGuideData and growGuideData[csvId] and growGuideData[csvId][1] == 1 then
					state = 1
				elseif not unlocks[count] then
					state = 2
				end

				if v.feature == "craft" and state ~= 2 then
					local state1, day = dataEasy.judgeServerOpen("craft")

					if not state1 and day then
						state = 2
						data.serverDay = day
					end
				end

				data.state = state

				table.insert(itemDatas, data)
			end
		end

		table.sort(itemDatas, function(a, b)
			local csvTab = csv.unlock
			local cfgA = csvTab[gUnlockCsv[a.cfg.feature]]
			local unLockLvA = cfgA.startLevel
			local cfgB = csvTab[gUnlockCsv[b.cfg.feature]]
			local unLockLvB = cfgB.startLevel

			if unLockLvA ~= unLockLvB then
				return unLockLvA < unLockLvB
			end

			return a.csvId < b.csvId
		end)

		local useData, selIdx
		local target = 999

		for i, v in ipairs(itemDatas) do
			if target > v.state then
				useData = v
				target = v.state
				selIdx = i
			end

			if target == 1 then
				break
			end
		end

		if not useData then
			self.growGuide:hide()

			return
		end

		self.growGuide:get("textNote1"):text(useData.cfg.name)
		adapt.setTextScaleWithWidth(self.growGuide:get("textNote1"), nil, 240)
		self.growGuide:removeChildByName("getEffect")
		self.growGuide:get("imgBg"):show()

		local str = ""

		if useData.state == 1 then
			str = gLanguageCsv.rewardCanGet

			self.growGuide:get("imgBg"):hide()
			widget.addAnimationByKey(self.growGuide, "effect/xiangdao.skel", "getEffect", "effect_loop", 3):xy(-1078, 143)
		elseif useData.state == 2 then
			local key = gUnlockCsv[useData.cfg.feature]
			local cfg = csv.unlock[key]

			str = string.format(gLanguageCsv.arrivalLevelOpen, cfg.startLevel)

			if useData.serverDay then
				str = string.format(gLanguageCsv.unlockServerOpen, useData.serverDay)
			end
		elseif useData.state == 3 then
			str = gLanguageCsv.stateFighting
		end

		self.growGuide:get("textNote2"):text(str)
		adapt.setTextAdaptWithSize(self.growGuide:get("textNote2"), {
			vertical = "center",
			horizontal = "center",
			size = cc.size(170, 40)
		})
		self.growGuide:show()
		bind.touch(self, self.growGuide, {
			methods = {
				ended = function()
					gGameUI:stackUI("city.grow_guide", nil, nil, selIdx)
				end
			}
		})
	end)
end

function CityView:achievementTip()
	local width = self.achievementPanel:width()
	local originX = self.rightPanel:size().width + width

	idlereasy.any({
		self.tasks,
		self.achiBoxes
	}, function(_, tasks, box)
		self:checkAchievementForGameUI()
	end):anonyOnly(self, "achievementTasks")
end

function CityView:medalCollectionTip()
	idlereasy.any({
		self.medalTasks
	}, function(_, tasks)
		self:checkMedalCollectionForGameUI()
	end):anonyOnly(self, "medalCollectionTasks")
end

function CityView:checkAchievementForGameUI()
	if not dataEasy.isUnlock(gUnlockCsv.achievement) then
		return
	end

	if not gGameUI:findStackUI("city.view") or not gGameModel.role.achievement_queue then
		return
	end

	for csvId, state in pairs(gGameModel.role.achievement_queue) do
		gGameUI:showAchievement(csvId)
	end

	gGameModel.role.achievement_queue = nil
end

function CityView:checkMedalCollectionForGameUI()
	if not dataEasy.isUnlock(gUnlockCsv.medalCollection) then
		return
	end

	if not gGameUI:findStackUI("city.view") or not gGameModel.role.medal_task then
		return
	end

	for csvId, state in pairs(gGameModel.role.medal_task) do
		gGameUI:showMedalCollection(csvId)
	end

	gGameModel.role.medal_task = nil
end

function CityView:onClickAchievement()
	if not dataEasy.isUnlock(gUnlockCsv.achievement) then
		return
	end

	self:stackUI("city.achievement", nil, {
		full = true
	})
end

function CityView.setCountdown(view, uiTime, params)
	view:enableSchedule()
	view:unSchedule(params.tag)

	local countTime = params.endTime - time.getTime()

	if countTime <= 0 then
		uiTime:hide()

		if params.cb then
			params.cb()
		end

		return
	end

	view:schedule(function()
		countTime = params.endTime - time.getTime()

		local times = time.getCutDown(countTime)
		local hour = times.day * 24 + times.hour

		if times.day and times.day > 0 then
			uiTime:text(string.format("%s" .. gLanguageCsv.day, gLanguageCsv.exclusiveIconTime, times.day))
		else
			uiTime:text(string.format("%02d:%02d:%02d", times.hour, times.min, times.sec))
		end

		if countTime <= 0 then
			CityView.setCountdown(view, uiTime, params)
		end
	end, 1, 0, params.tag)
end

function CityView:onReFreshRedHint()
	self.redHintRefresh:modify(function(val)
		return true, not val
	end)
end

function CityView:setGameSyncTimer()
	local timer = {
		0,
		18000,
		75600
	}

	timer[#timer + 1] = timer[1] + 86400

	local currTime = time.getNowDate()
	local currSec = currTime.hour * 3600 + currTime.min * 60 + currTime.sec
	local delta = 1

	for i = 1, #timer do
		if currSec < timer[i] then
			delta = timer[i] - currSec + 1

			break
		end
	end

	performWithDelay(self, function()
		gGameApp:slientRequestServer("/game/sync", functools.handler(self, "setGameSyncTimer"))
	end, delta)
end

function CityView:specialGiftLink()
	if string.find(APP_TAG, "_ld_yidun_") then
		return
	end

	if matchLanguage({
		"kr"
	}) then
		local btn = ccui.ImageView:create("city/main/icon_krgift.png"):setTouchEnabled(true):scale(0.95):xy(128, 410)

		bind.touch(self, btn, {
			methods = {
				ended = function()
					gGameUI:stackUI("city.kr_gift_link_view")
				end
			}
		})
		self.rightBottomPanel:addChild(btn, 2, "krGift")
	end
end

function CityView:setSecialSupport()
	if matchLanguageForce({
		"en"
	}) then
		local btn = ccui.ImageView:create("login/icon_kfzx.png"):setTouchEnabled(true):scale(0.86):xy(443, 55)

		bind.touch(self, btn, {
			methods = {
				ended = function()
					cc.Application:getInstance():openURL(SUPPORT_URL)
				end
			}
		})
		self.leftBottomBtnPanel:addChild(btn, 2, "enSupport")

		local x, y = 443, 55

		if display.sizeInView.width / display.sizeInView.height >= 2 then
			x = x + 120
		else
			y = y - 120
		end

		local btnDiscord = ccui.ImageView:create("login/icon_discord.png"):setTouchEnabled(true):scale(0.86):xy(x, y)

		bind.touch(self, btnDiscord, {
			methods = {
				ended = function()
					sdk.trackEvent("tap_discord")
					cc.Application:getInstance():openURL(DISCORD_URL)
				end
			}
		})
		self.leftBottomBtnPanel:addChild(btnDiscord, 2, "enDiscord")
	elseif matchLanguage({
		"tw"
	}) then
		local currentLv = gGameModel.role:read("level")

		if currentLv >= 30 then
			local btn = ccui.ImageView:create("login/icon_kfzx.png"):setTouchEnabled(true):scale(0.86):xy(443, 55)

			bind.touch(self, btn, {
				methods = {
					ended = function()
						cc.Application:getInstance():openURL(FACEBOOK_URL)
					end
				}
			})
			self.leftBottomBtnPanel:addChild(btn, 2, "Facebook")
		end
	elseif matchLanguageForce({
		"en_us"
	}) then
		local btn = ccui.ImageView:create("login/icon_kfzx.png"):setTouchEnabled(true):scale(0.86):xy(443, 55)

		bind.touch(self, btn, {
			methods = {
				ended = function()
					cc.Application:getInstance():openURL(SUPPORT_URL_EN_US)
				end
			}
		})
		self.leftBottomBtnPanel:addChild(btn, 2, "enSupport")
	end
end

function CityView:setTimeLabel()
	if matchLanguage({
		"en",
		"tw"
	}) then
		self.daytime:visible(true)
		self.yeartime:visible(true)

		if matchLanguageForce({
			"en",
			"en_eu"
		}) then
			local Month = {
				"Jan.",
				"Feb.",
				"Mar.",
				"Apr.",
				"May.",
				"Jun.",
				"Jul.",
				"Aug.",
				"Sep.",
				"Oct.",
				"Nov.",
				"Dec."
			}
			local T = time.getTimeTable()

			self.yeartime:text(string.format("%s/%02d/%04d", Month[T.month], T.day, T.year))
			self.daytime:text(string.format("%02d:%02d", T.hour, T.min))
			self:enableSchedule():schedule(function()
				local T = time.getTimeTable()

				self.yeartime:text(string.format("%s/%02d/%04d", Month[T.month], T.day, T.year))
				self.daytime:text(string.format("%02d:%02d", T.hour, T.min))
			end, 1, 0)
		elseif matchLanguageForce({
			"en_us"
		}) then
			local Month = {
				"Jan.",
				"Feb.",
				"Mar.",
				"Apr.",
				"May.",
				"Jun.",
				"Jul.",
				"Aug.",
				"Sep.",
				"Oct.",
				"Nov.",
				"Dec."
			}
			local T = time.getTimeTable()

			self.yeartime:text(string.format("%s/%02d", Month[T.month], T.day))
			self.daytime:text(string.format("%02d:%02d %s", T.hour, T.min, "UTC" .. UNIVERSAL_TIMEDELTA / 3600))
			self:enableSchedule():schedule(function()
				local T = time.getTimeTable()

				self.yeartime:text(string.format("%s/%02d", Month[T.month], T.day))
				self.daytime:text(string.format("%02d:%02d %s", T.hour, T.min, "UTC" .. UNIVERSAL_TIMEDELTA / 3600))
			end, 1, 0)
		elseif matchLanguage({
			"tw"
		}) then
			local T = time.getTimeTable()

			self.yeartime:text(string.format("%04d/%s/%02d", T.year, T.month, T.day))
			self.daytime:text(string.format("%02d:%02d", T.hour, T.min))
			self:enableSchedule():schedule(function()
				local T = time.getTimeTable()

				self.yeartime:text(string.format("%04d/%s/%02d", T.year, T.month, T.day))
				self.daytime:text(string.format("%02d:%02d", T.hour, T.min))
			end, 1, 0)
		end
	else
		self.daytime:visible(false)
		self.yeartime:visible(false)
	end
end

return CityView
