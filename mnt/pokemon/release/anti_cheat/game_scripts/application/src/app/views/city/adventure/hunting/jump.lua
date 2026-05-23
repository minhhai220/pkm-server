-- chunkname: @src.app.views.city.adventure.hunting.jump

local QUALITY_TYPE = {
	{
		res = "city/adventure/hunting/box_green.png",
		color = cc.c4b(68, 185, 117, 255)
	},
	{
		res = "city/adventure/hunting/box_yellow.png",
		color = cc.c4b(202, 153, 35, 255)
	},
	{
		res = "city/adventure/hunting/box_blue.png",
		color = cc.c4b(65, 142, 177, 255)
	},
	{
		res = "city/adventure/hunting/box_orange.png",
		color = cc.c4b(227, 118, 84, 255)
	},
	{
		res = "city/adventure/hunting/box_pink.png",
		color = cc.c4b(217, 85, 118, 255)
	},
	{
		res = "city/adventure/hunting/box_purple.png",
		color = cc.c4b(165, 82, 193, 255)
	},
	{
		res = "city/adventure/hunting/box_red.png",
		color = cc.c4b(227, 98, 91, 255)
	}
}
local ViewBase = cc.load("mvc").ViewBase
local HuntingJumpView = class("HuntingJumpView", Dialog)
local OPEN_TIMES = {
	ALL = "ALL",
	ONCE = "ONCE"
}

HuntingJumpView.RESOURCE_FILENAME = "hunting_jump.json"
HuntingJumpView.RESOURCE_BINDING = {
	["panel2.noData"] = "boxNoData",
	panel2 = "panel2",
	panel3 = "panel3",
	["panel2.item"] = "item2",
	["panel1.item"] = "awardItem",
	["panel3.item"] = "item3",
	panel1 = "panel1",
	["panel1.subList"] = "awardList",
	progressPanel = "progressPanel",
	["panel2.sortPanel"] = {
		varname = "sortPanel",
		binds = {
			event = "extend",
			class = "sort_menus",
			props = {
				btnType = 4,
				expandUp = true,
				data = bindHelper.self("sortDatas"),
				btnClick = bindHelper.self("onSortMenusBtnClick", true),
				onNode = function(node)
					node:xy(-1125, -477):z(18)
					node.btn4:setColor(cc.c3b(255, 255, 255))
				end
			}
		}
	},
	["panel2.btnOpenAll"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClickOpenAll")
			}
		}
	},
	["btnNext.textNote"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["panel2.textTitle"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("boxesCount"),
			method = function(val)
				return string.format(gLanguageCsv.randomTowerJumpBoxesCount, val)
			end
		}
	},
	["panel2.subList"] = {
		varname = "list2",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				margin = 24,
				asyncPreload = 4,
				data = bindHelper.self("boxData"),
				item = bindHelper.self("item2"),
				route = bindHelper.self("route"),
				itemAction = {
					isAction = true
				},
				onItem = function(list, node, k, v)
					local imgGotten = node:get("imgGotten")

					imgGotten:setVisible(v.times == v.maxOpen)

					if v.times == v.maxOpen then
						nodetools.invoke(node, {
							"imgGotten"
						}, "show")
						nodetools.invoke(node, {
							"btn1",
							"btn2",
							"imgDiamond1",
							"imgDiamond2",
							"textDiamond1",
							"textDiamond2"
						}, "hide")
					else
						nodetools.invoke(node, {
							"imgGotten"
						}, "hide")
						nodetools.invoke(node, {
							"btn1",
							"btn2",
							"imgDiamond1",
							"imgDiamond2",
							"textDiamond1",
							"textDiamond2"
						}, "show")

						local costCsv = gCostCsv.hunting_box_cost
						local openOneCost = costCsv[math.min(v.times, table.length(costCsv))]
						local openAllCost = 0

						for i = v.times, v.maxOpen - 1 do
							if costCsv[i] then
								openAllCost = openAllCost + costCsv[i]
							else
								openAllCost = openAllCost + costCsv[table.length(costCsv)]
							end
						end

						node:get("textDiamond1"):text(openOneCost)
						node:get("textDiamond2"):text(openAllCost)

						local btn1 = node:get("btn1")

						bind.touch(list, btn1, {
							methods = {
								ended = function()
									if gGameModel.role:read("rmb") < openOneCost then
										uiEasy.showDialog("rmb")
									else
										gGameApp:requestServer("/game/hunting/jump/box/open", function(tb)
											gGameUI:showGainDisplay(tb)
										end, list.route, v.boardID, "open1")
									end
								end
							}
						})

						local btn2 = node:get("btn2")

						btn2:get("textNote"):text(string.format(gLanguageCsv.openBoxesTimes, v.maxOpen - v.times))
						bind.touch(list, btn2, {
							methods = {
								ended = function()
									if gGameModel.role:read("rmb") < openAllCost then
										uiEasy.showDialog("rmb")
									else
										gGameApp:requestServer("/game/hunting/jump/box/open", function(tb)
											gGameUI:showGainDisplay(tb)
										end, list.route, v.boardID, "open3")
									end
								end
							}
						})
					end
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end
			}
		}
	},
	["panel2.textDiamond"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("openAllBoxesCost")
		}
	},
	["panel3.subList"] = {
		varname = "list3",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				margin = 100,
				data = bindHelper.self("bufData"),
				item = bindHelper.self("item3"),
				route = bindHelper.self("route"),
				itemAction = {
					isAction = true
				},
				onItem = function(list, node, k, v)
					local buffCsv = csv.cross.hunting.buffs[v]

					node:get("panel.icon"):texture(buffCsv.icon)
					node:get("panel.name"):text(buffCsv.name)
					text.addEffect(node:get("panel.name"), {
						color = QUALITY_TYPE[buffCsv.quality].color
					})
					node:get("panel.bg"):texture(QUALITY_TYPE[buffCsv.quality].res)
					beauty.textScroll({
						fontSize = 34,
						isRich = true,
						align = "center",
						list = node:get("panel.desc"),
						strs = "#C0x5B545B#" .. buffCsv.desc
					})
					bind.touch(list, node, {
						methods = {
							ended = function()
								gGameApp:requestServer("/game/hunting/jump/buff", function(tb)
									return
								end, list.route, k)
							end
						}
					})
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end
			}
		}
	},
	btnNext = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("requestNext")
			}
		}
	}
}

function HuntingJumpView:onCreate(params)
	self:initModel()
	self:getSize(params.route)

	self.cb = params.cb
	self.route = params.route
	self.data = params.data

	idlereasy.when(self.routeInfo, function(_, routeInfo)
		local jumpStep = routeInfo[params.route].jump_step
		local jumpInfo = routeInfo[params.route].jump_info

		self.jumpStep = jumpStep
		self.jumpInfo = jumpInfo

		if jumpStep == game.HUNTING_JUMP_STATE.POINT then
			self.panel1:show()
		elseif jumpStep == game.HUNTING_JUMP_STATE.BOX then
			self.panel1:hide()
			self.panel2:show()
		elseif jumpStep == game.HUNTING_JUMP_STATE.BUFF then
			self.panel2:hide()
			self.panel3:show()
		elseif jumpStep == game.HUNTING_JUMP_STATE.OVER then
			self:addCallbackOnExit(self.cb)
			performWithDelay(self, function()
				Dialog.onClose(self)
			end, 0.016666666666666666)
		end

		if jumpStep <= game.HUNTING_JUMP_STATE.BUFF then
			self["refreshPanel" .. jumpStep .. "Data"](self, jumpInfo)
			self:refreshProgressPanel(jumpStep)
		end
	end)
	Dialog.onCreate(self)
end

function HuntingJumpView:onClose()
	return
end

function HuntingJumpView:getSize(route)
	local routeInfo = self.routeInfo:read()
	local version = routeInfo[route].version or 0
	local count = 0

	for k, v in orderCsvPairs(csv.cross.hunting.route) do
		if v.routeTag == route and version == v.version then
			count = count + 1
		end
	end

	self.routeMaxSize = count

	local lastMaxNode = routeInfo[route].last_max_node
	local hisMaxNode = routeInfo[route].history_max_node
	local lastCanPass = 0
	local historyCanPass = 0

	if csv.cross.hunting.route[lastMaxNode] then
		lastCanPass = csv.cross.hunting.route[lastMaxNode].lastCanPass
	end

	if csv.cross.hunting.route[hisMaxNode] then
		historyCanPass = csv.cross.hunting.route[hisMaxNode].historyCanPass
	end

	self.canPassNode = math.max(lastCanPass, historyCanPass)
end

function HuntingJumpView:initModel()
	self.routeInfo = gGameModel.hunting:getIdler("hunting_route")
	self.boxData = idlers.newWithMap({})
	self.openAllBoxesCost = idler.new(0)
	self.boxesCount = idler.new(0)
	self.bufData = idlertable.new({})
	self.bufRoomIndex = idler.new(0)
	self.eventData = idlers.newWithMap({})

	local OPEN_TIMES1 = {
		gLanguageCsv.randomTowerOpenAll,
		gLanguageCsv.randomTowerOpenOnce
	}

	self.sortDatas = idlertable.new(OPEN_TIMES1)
	self.openTimes = idler.new(OPEN_TIMES.ALL)
end

function HuntingJumpView:refreshOpenAllBoxesCost(boxes, openTimes)
	local maxOpen = csv.cross.hunting.base[self.route].boxOpenLimit
	local costCsv = gCostCsv.hunting_box_cost
	local openAllCost = 0

	if openTimes == OPEN_TIMES.ONCE then
		for k, v in pairs(boxes) do
			if costCsv[v] and v <= maxOpen - 1 then
				openAllCost = openAllCost + costCsv[v]
			end
		end
	else
		for k, v in pairs(boxes) do
			for i = v, maxOpen - 1 do
				if costCsv[i] then
					openAllCost = openAllCost + costCsv[i]
				else
					openAllCost = openAllCost + costCsv[table.length(costCsv)]
				end
			end
		end
	end

	self.openAllBoxesCost:set(openAllCost)
end

function HuntingJumpView:refreshPanel1Data(jumpInfo)
	self.panel1:show()
	self:initRichPanel()
	self:initAward(jumpInfo)
end

function HuntingJumpView:refreshPanel2Data(jumpInfo)
	self.panel1:hide()
	self.panel2:show()

	local maxOpen = csv.cross.hunting.base[self.route].boxOpenLimit

	idlereasy.when(self.openTimes, function(_, openTimes)
		local boxes = gGameModel.hunting:read("hunting_route")[self.route].jump_info.boxes or {}
		local data = {}

		for k, v in pairs(boxes) do
			table.insert(data, {
				boardID = k,
				times = v,
				maxOpen = maxOpen
			})
		end

		self.boxNoData:visible(itertools.size(data) == 0)
		self.boxData:update(data)
		self.boxesCount:set(itertools.size(boxes))
		self:refreshOpenAllBoxesCost(boxes, openTimes)
		adapt.oneLinePos(self.panel2:get("textCost"), {
			self.panel2:get("textDiamond"),
			self.panel2:get("imgDiamond")
		}, {
			cc.p(10, 0),
			cc.p(10, 0)
		})
	end)
end

function HuntingJumpView:refreshPanel3Data(jumpInfo)
	self.panel2:hide()
	self.panel3:show()

	local buffs = jumpInfo.board_buffs
	local buffIdx = jumpInfo.buff_index or 1

	if buffs then
		self.bufData:set(buffs)
		self.bufRoomIndex:set(buffIdx)
		self:refreshBuffIndex()
	else
		self.bufData:set({})
	end
end

function HuntingJumpView:getPanel1Str()
	local tablestr = {
		"",
		"",
		"",
		""
	}

	if self.canPassNode <= 1 then
		tablestr[1] = ""
	else
		local str1 = gLanguageCsv.huntingJumpTips1

		tablestr[1] = string.format(str1, self.canPassNode, self.routeMaxSize)
	end

	local jumpInfo = self.jumpInfo
	local normalTimes = 0
	local eliteTimes = 0
	local gateIds = self.data.gateIDs or {}

	for k, v in pairs(gateIds) do
		local cfg = csv.cross.hunting.gate[v]

		if cfg.type == 1 then
			normalTimes = normalTimes + 1
		elseif cfg.type == 2 then
			eliteTimes = eliteTimes + 1
		end
	end

	local str2 = gLanguageCsv.huntingJumpTips2

	tablestr[2] = string.format(str2, normalTimes, eliteTimes)

	local buffs = jumpInfo.buff_gates or {}
	local bufCount = itertools.size(buffs)
	local str3 = gLanguageCsv.huntingJumpTips3

	tablestr[3] = string.format(str3, bufCount)

	local boxes = jumpInfo.boxes or {}
	local boxCount = itertools.size(boxes)
	local str4 = gLanguageCsv.huntingJumpTips4

	tablestr[4] = string.format(str4, boxCount)

	return tablestr
end

function HuntingJumpView:initRichPanel()
	local str = self:getPanel1Str()

	for k, v in ipairs(str) do
		local rich = rich.createByStr(v, 50):addTo(self.panel1, 10):setAnchorPoint(cc.p(0, 0.5)):xy(cc.p(80, 1000 - 90 * k)):formatText()
	end
end

function HuntingJumpView:initAward(jumpInfo)
	local data = {}
	local award = self.data.award

	for k, v in pairs(award) do
		if k ~= "chipdbIDs" then
			data[k] = v
		end
	end

	bind.extend(self, self.awardList, {
		class = "listview",
		props = {
			data = dataEasy.getItemData(data),
			item = self.awardItem,
			dataOrderCmp = dataEasy.sortItemCmp,
			itemAction = {
				isAction = true
			},
			onAfterBuild = function()
				self.awardList:adaptTouchEnabled()
			end,
			onItem = function(list, node, k, v)
				bind.extend(list, node, {
					class = "icon_key",
					props = {
						data = v,
						grayState = v.grayState,
						specialKey = {
							maxLimit = true
						}
					}
				})
			end
		}
	})
end

function HuntingJumpView:requestNext()
	local step = self.jumpStep
	local jumpInfo = self.jumpInfo
	local tips = ""

	if step == game.HUNTING_JUMP_STATE.BOX then
		if self.openAllBoxesCost:read() ~= 0 then
			tips = gLanguageCsv.randomTowerJumpNextTips1
		end
	elseif step == game.HUNTING_JUMP_STATE.BUFF then
		local roomIndex = jumpInfo.buff_index or 0
		local buffs = jumpInfo.buff_gates or {}
		local count = itertools.size(buffs)

		if roomIndex < count then
			tips = gLanguageCsv.randomTowerJumpNextTips2
		end
	elseif step == game.HUNTING_JUMP_STATE.EVENT then
		local events = jumpInfo.events or {}

		for k, v in pairs(events) do
			if v[2] == 0 then
				tips = gLanguageCsv.randomTowerJumpNextTips3

				break
			end
		end
	end

	if tips ~= "" then
		gGameUI:showDialog({
			btnType = 2,
			title = gLanguageCsv.spaceTips,
			content = tips,
			cb = function()
				gGameApp:requestServer("/game/hunting/jump/next", function(tb)
					return
				end, self.route)
			end
		})
	else
		gGameApp:requestServer("/game/hunting/jump/next", function(tb)
			return
		end, self.route)
	end
end

function HuntingJumpView:refreshProgressPanel(step)
	local imgTab = {}
	local imgBarTab = {}
	local textTab = {}

	for i = 2, 4 do
		if i <= step then
			table.insert(imgTab, "img" .. i)
			table.insert(imgBarTab, "imgBar" .. i)
			table.insert(textTab, "text" .. i)
		end
	end

	local panel = self.progressPanel

	nodetools.invoke(panel, imgTab, "texture", "city/adventure/random_tower/bar_d.png")
	nodetools.invoke(panel, imgBarTab, "texture", "city/adventure/random_tower/bar_dt.png")
	nodetools.invoke(panel, textTab, "setTextColor", cc.c4b(247, 83, 100, 255))
end

function HuntingJumpView:refreshBuffIndex()
	local str1 = "#Pfont/youmi1.ttf#" .. gLanguageCsv.huntingJumpTips5
	local roomIndex = self.bufRoomIndex:read() or 0
	local buffs = self.jumpInfo.buff_gates or {}
	local count = itertools.size(buffs)
	local str = string.format(str1, roomIndex, count)
	local textTips = self.panel3:get("textTips"):hide()

	self.panel3:removeChildByName("richTips")
	rich.createByStr(str, 50):addTo(self.panel3, 10):setAnchorPoint(cc.p(0.5, 0.5)):xy(textTips:xy()):formatText():setName("richTips")
end

function HuntingJumpView:onClickOpenAll()
	if self.openAllBoxesCost:read() == 0 then
		return
	end

	if gGameModel.role:read("rmb") < self.openAllBoxesCost:read() then
		uiEasy.showDialog("rmb")
	else
		local showOver = {
			false
		}

		if self.openTimes:read() == OPEN_TIMES.ONCE then
			gGameApp:requestServerCustom("/game/hunting/jump/box/open"):params(self.route, 0, "open1"):onResponse(function(tb)
				showOver[1] = true
			end):wait(showOver):doit(function(tb)
				gGameUI:showGainDisplay(tb)
			end)
		else
			gGameApp:requestServerCustom("/game/hunting/jump/box/open"):params(self.route, 0, "open3"):onResponse(function(tb)
				showOver[1] = true
			end):wait(showOver):doit(function(tb)
				gGameUI:showGainDisplay(tb)
			end)
		end
	end
end

function HuntingJumpView:onClickBufRandom()
	local showOver = {
		false
	}

	gGameApp:requestServerCustom("/game/random_tower/jump/buff"):params(0):onResponse(function(tb)
		showOver[1] = true
	end):wait(showOver):doit(function(tb)
		return
	end)
end

function HuntingJumpView:onClickbuff(boardID)
	local showOver = {
		false
	}

	gGameApp:requestServerCustom("/game/random_tower/jump/buff"):params(boardID):onResponse(function(tb)
		showOver[1] = true
	end):wait(showOver):doit(function(tb)
		gGameUI:showTip("buf2")
	end)
end

function HuntingJumpView:onSortMenusBtnClick(panel, node, k, v, oldval)
	if k == 1 then
		self.openTimes:set(OPEN_TIMES.ALL)
	else
		self.openTimes:set(OPEN_TIMES.ONCE)
	end
end

return HuntingJumpView
