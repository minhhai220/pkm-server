-- chunkname: @src.app.views.city.adventure.gym_challenge.buff

local ViewBase = cc.load("mvc").ViewBase
local GymBuffTree = class("GymBuffTree", ViewBase)

GymBuffTree.RESOURCE_FILENAME = "gym_buff.json"
GymBuffTree.RESOURCE_BINDING = {
	["rightTopPanel.textPoint"] = "textPoint",
	rightTopPanel = "rightTopPanel",
	["leftPanel.item"] = "leftItem",
	leftPanel = "leftPanel",
	bufItem = "bufItem",
	["leftPanel.listview"] = {
		varname = "list",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("leftDatas"),
				item = bindHelper.self("leftItem"),
				showTab = bindHelper.self("showTab"),
				itemAction = {
					isAction = true
				},
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel

					if v.select then
						normal:hide()

						panel = selected:show()
					else
						selected:hide()

						panel = normal:show()

						panel:get("subTxt"):text(v.subName)
					end

					panel:get("txt"):text(v.name)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {
						methods = {
							ended = functools.partial(list.clickCell, k)
						}
					})
					adapt.setTextScaleWithWidth(panel:get("txt"), nil, 300)

					local a = bindHelper.self("gymDatas"), bind.extend(list, node, {
						class = "red_hint",
						props = {
							specialTag = "gymBuffTab",
							state = list.showTab:read() ~= k,
							listenData = {
								treeId = k,
								gymDatas = bindHelper.parent("gymDatas"),
								round = gGameModel.gym:getIdler("round")
							},
							onNode = function(panel)
								panel:xy(340, 160)
							end
						}
					})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick")
			}
		}
	},
	scrollview = {
		varname = "scrollview",
		binds = {
			data = false,
			event = "scrollBarEnabled"
		}
	},
	["rightTopPanel.btnAdd"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onAddClick")
			}
		}
	},
	btnReset = {
		varname = "btnReset",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onResetClick")
			}
		}
	}
}

function GymBuffTree:onCreate(data)
	gGameUI.topuiManager:createView("default", self, {
		onClose = self:createHandler("onClose")
	}):init({
		subTitle = "CHALLENGE ADD",
		title = gLanguageCsv.gymBuff
	})
	self:initData()
	self:initModel()
	adapt.setTextAdaptWithSize(self.leftPanel:get("textTips"), {
		horizontal = "center",
		vertical = "center",
		size = cc.size(600, 120)
	})
end

function GymBuffTree:initModel()
	self.showTab = idler.new(1)
	self.treeId = idler.new(1)

	local leftData = {}

	for k, v in orderCsvPairs(csv.gym.talent_tree) do
		leftData[k] = {
			select = false,
			name = v.name,
			subName = v.desc
		}
	end

	self.leftDatas = idlers.newWithMap(leftData)

	self.showTab:addListener(function(val, oldval)
		self.leftDatas:atproxy(oldval).select = false
		self.leftDatas:atproxy(val).select = true

		self.treeId:set(val)
	end)

	self.unlockTable = idlertable.new()
	self.gymDatas = gGameModel.role:getIdler("gym_datas")

	idlereasy.any({
		self.gymDatas,
		self.treeId
	}, function(_, gymDatas, treeID)
		self.depthData = {}

		self:refreshShowData(treeID)
		self.textPoint:text(gymDatas.gym_talent_point)
		adapt.oneLinePos(self.rightTopPanel:get("btnAdd"), {
			self.textPoint,
			self.rightTopPanel:get("textNote"),
			self.rightTopPanel:get("imgIcon")
		}, {
			cc.p(10, 0),
			cc.p(5, 0),
			cc.p(10, 0)
		}, "right")

		local tree = gymDatas.gym_talent_trees[treeID] or {}
		local unlockTable = {}

		for id, lv in pairs(tree.talent or {}) do
			local depth = csv.gym.talent_buff[id].depth

			self.depthData[treeID] = self.depthData[treeID] or {}
			self.depthData[treeID][depth] = id
		end

		for id, icon in orderCsvPairs(csv.gym.talent_buff) do
			unlockTable[id] = self:checkUnlock(id)
		end

		self.unlockTable:set(unlockTable)

		for id, icon in pairs(self.bufIcons) do
			if tree.talent and tree.talent[id] then
				self:refreshBufIcon(id, tree.talent[id])
			else
				self:refreshBufIcon(id, 0)
			end
		end

		if itertools.isempty(gymDatas.gym_talent_trees) then
			uiEasy.setBtnShader(self.btnReset, self.btnReset:get("textNote"), 3)
		else
			uiEasy.setBtnShader(self.btnReset, self.btnReset:get("textNote"), 1)
		end
	end)

	local textNote1 = self.rightTopPanel:get("textNote1"):hide()
	local richText = rich.createByStr(string.format(gLanguageCsv.gymBuffDesc, gCommonConfigCsv.gymAutoRecoverPoints), 40):xy(cc.p(textNote1:xy())):anchorPoint(1, 0.5):addTo(self.rightTopPanel, 3)

	self.buyTimes = gGameModel.daily_record:getIdler("gym_talent_point_buy_times")
end

function GymBuffTree:initData()
	local data = {}

	for id, cfg in orderCsvPairs(csv.gym.talent_buff) do
		data[id] = {
			id = id
		}

		for k, v in pairs(cfg) do
			data[id][k] = v
		end
	end

	for id, cfg in pairs(data) do
		for i, preID in pairs(cfg.preTalentIDs or {}) do
			data[preID].nextTalentIDs = data[preID].nextTalentIDs or {}

			table.insert(data[preID].nextTalentIDs, id)
		end
	end

	self.cfgData = {}

	for id, cfg in pairs(data) do
		self.cfgData[cfg.treeID] = self.cfgData[cfg.treeID] or {}
		self.cfgData[cfg.treeID][id] = cfg
	end
end

function GymBuffTree:createBufIcon(id)
	local cfg = csv.gym.talent_buff[id]
	local item = self.bufItem:clone():z(5):scale(cfg.iconRate)
	local icon = item:get("imgBg.icon"):texture(cfg.icon)

	item:setTouchEnabled(true)
	bind.touch(self, item, {
		methods = {
			ended = function()
				local unlockTable = self.unlockTable:read()
				local preLv, needPerLv = self:getPreLv(id)

				gGameUI:stackUI("city.adventure.gym_challenge.buff_detail", nil, {
					clickClose = true,
					blackLayer = true
				}, id, unlockTable[id], preLv, needPerLv)
			end
		}
	})

	self.bufIcons[id] = item

	bind.extend(self, self.bufIcons[id], {
		class = "red_hint",
		props = {
			specialTag = "gymBuffIcon",
			listenData = {
				id = id,
				round = gGameModel.gym:getIdler("round"),
				gymDatas = bindHelper.self("gymDatas")
			},
			onNode = function(panel)
				panel:x(panel:x() - 10)
				panel:y(panel:y() - 10)
			end
		}
	})

	return item
end

function GymBuffTree:refreshBufIcon(id, lv)
	local bufItem = self.bufIcons[id]
	local unlock = self.unlockTable:read()[id]

	if unlock == false then
		bufItem:get("imgLockBg"):show()
		bufItem:get("imgLvBg"):hide()
		bufItem:get("textLv"):hide()
	else
		bufItem:get("imgLockBg"):hide()
		bufItem:get("imgLvBg"):show()
		bufItem:get("textLv"):show()
	end

	for preId, lines in pairs(self.lines[id]) do
		for _, line in ipairs(lines) do
			if unlock == false then
				line:setColor(cc.c4b(183, 176, 158, 127.5))
				line:z(0)
			elseif self.unlockTable:read()[preId] == false then
				line:setColor(cc.c4b(183, 176, 158, 127.5))
				line:z(0)
			else
				line:setColor(cc.c4b(241, 59, 84, 255))
				line:z(1)
			end
		end
	end

	bufItem:get("textLv"):text(gLanguageCsv.textLv2 .. lv)
	bufItem:get("imgLvBg"):width((bufItem:get("textLv"):width() + 40) * 2)
end

function GymBuffTree:checkUnlock(id)
	local cfg = csv.gym.talent_buff[id]
	local preId = cfg.preTalentIDs
	local preLevel = cfg.preLevel
	local depth = cfg.depth
	local tree = self.gymDatas:read().gym_talent_trees[cfg.treeID] or {}
	local lv = tree.talent and tree.talent[id] or 0

	if lv > 0 then
		return true
	end

	if depth == 1 then
		return true
	end

	if self.depthData[cfg.treeID] and self.depthData[cfg.treeID][depth] and self.depthData[cfg.treeID][depth] ~= id then
		return false
	end

	for _, _id in ipairs(preId) do
		local lv = tree.talent and tree.talent[_id] or 0

		if preLevel <= lv then
			return true
		end
	end

	return false
end

function GymBuffTree:getPreLv(id)
	local cfg = csv.gym.talent_buff[id]
	local preId = cfg.preTalentIDs
	local preLevel = cfg.preLevel
	local depth = cfg.depth
	local tree = self.gymDatas:read().gym_talent_trees[cfg.treeID] or {}
	local lv = tree.talent and tree.talent[id] or 0

	if depth == 1 then
		return 0, 0
	end

	for _, _id in ipairs(preId) do
		local lv = tree.talent and tree.talent[_id]

		if lv and lv ~= 0 then
			return lv, cfg.preLevel
		end
	end

	return 0, cfg.preLevel
end

function GymBuffTree:getDepthData(index)
	local data = {}
	local maxW = 0

	for i, cfg in pairs(self.cfgData[index]) do
		data[cfg.depth] = data[cfg.depth] or {}

		table.insert(data[cfg.depth], cfg)

		maxW = math.max(maxW, #data[cfg.depth])
	end

	for k, v in ipairs(data) do
		table.sort(v, function(a, b)
			return a.id < b.id
		end)
	end

	return data, maxW
end

function GymBuffTree:drawBufIcon(data, maxW)
	local width = self.scrollview:width()
	local maxDepth = #data
	local containerSize = cc.size(width, math.max(maxDepth * 300 - 100, 1120))
	local spacingY1 = 350
	local spacingY2 = 180
	local spacingX = (containerSize.width - 300) / (maxW - 1)

	self.scrollview:setInnerContainerSize(containerSize)

	local posY = containerSize.height - 120

	for i, v in ipairs(data) do
		local iconY = 0

		if i == 1 then
			iconY = posY
			posY = iconY
		elseif i == 2 or i == #data then
			iconY = posY - spacingY2
			posY = iconY
		else
			iconY = posY - spacingY1
			posY = iconY
		end

		for ii, vv in ipairs(v) do
			local icon = self:createBufIcon(vv.id):addTo(self.scrollview)

			if #v == 2 then
				icon:xy(width / 3 * ii, iconY)
			else
				local pos1 = width / 2 - spacingX / 2 * (#v - 1)
				local iconX = pos1 + spacingX * (ii - 1)

				icon:xy(iconX, iconY)
			end

			data[i][ii].pos = cc.p(icon:xy())
			data[i][ii].icon = icon
		end
	end
end

function GymBuffTree:drawLineFirst(leftData, rightData, vv)
	local lines = self.lines[vv.id]
	local iconWidth = vv.icon:getBoundingBox().width / 2
	local cornerWidth = 22

	if leftData then
		local parentIconWidth = leftData.icon:getBoundingBox().width / 2
		local params = {
			oneNodeShow = true,
			rotation = 270,
			scaleX = 1,
			lfData = leftData,
			height2 = math.abs(vv.pos.x - leftData.pos.x) - cornerWidth - parentIconWidth,
			height3 = leftData.pos.y - vv.pos.y - cornerWidth - iconWidth,
			anchor = {
				0.5,
				1
			},
			xy1 = {
				vv.pos.x,
				leftData.pos.y
			},
			xy2 = {
				vv.pos.x - cornerWidth,
				leftData.pos.y
			},
			xy3 = {
				vv.pos.x,
				leftData.pos.y - cornerWidth
			},
			lines = lines
		}

		self:settingOutUiShow(params)
	end

	if rightData then
		local parentIconWidth = rightData.icon:getBoundingBox().width / 2
		local params = {
			oneNodeShow = true,
			rotation = 90,
			scaleX = -1,
			lfData = rightData,
			height2 = math.abs(vv.pos.x - rightData.pos.x) - cornerWidth - parentIconWidth,
			height3 = rightData.pos.y - vv.pos.y - cornerWidth - iconWidth,
			anchor = {
				0.5,
				1
			},
			xy1 = {
				vv.pos.x,
				rightData.pos.y
			},
			xy2 = {
				vv.pos.x + cornerWidth,
				rightData.pos.y
			},
			xy3 = {
				vv.pos.x,
				rightData.pos.y - cornerWidth
			},
			lines = lines
		}

		self:settingOutUiShow(params)
	end
end

function GymBuffTree:drawLineLast(leftData, rightData, vv)
	local lines = self.lines[vv.id]
	local iconWidth = vv.icon:getBoundingBox().width / 2
	local cornerWidth = 22
	local posY = vv.pos.y
	local posX = vv.pos.x

	if leftData then
		local leftLines = {}
		local params = {}

		params.lfData = leftData
		params.rotation = 90
		params.lines = lines
		params.oneNodeShow = #leftData.nextTalentIDs == 1

		local parentIconWidth = leftData.icon:getBoundingBox().width / 2
		local iconLHight = leftData.icon:getBoundingBox().height / 2

		if #leftData.nextTalentIDs == 1 then
			params.height2 = math.abs(posX - leftData.pos.x) - iconWidth - cornerWidth
			params.height3 = leftData.pos.y - posY - cornerWidth - parentIconWidth + 10
			params.scale = -1
			params.xy1 = {
				leftData.pos.x,
				posY
			}
			params.xy2 = {
				leftData.pos.x + cornerWidth,
				posY
			}
			params.xy3 = {
				leftData.pos.x,
				posY + cornerWidth
			}
		else
			params.height2 = posX - leftData.pos.x - iconWidth
			params.height3 = leftData.pos.y - posY - iconLHight + 10
			params.xy2 = {
				leftData.pos.x,
				posY
			}
			params.xy3 = {
				leftData.pos.x,
				posY - 10
			}
			params.rect = cc.rect(15, 10, 1, 1)
		end

		self:settingOutUiShow(params)
	end

	if rightData then
		local params = {}

		params.lfData = rightData
		params.lines = lines
		params.rotation = 270
		params.oneNodeShow = #rightData.nextTalentIDs == 1

		if #rightData.nextTalentIDs == 1 then
			local parentIconWidth = rightData.icon:getBoundingBox().width / 2

			params.height3 = rightData.pos.y - posY - cornerWidth - parentIconWidth + 10
			params.height2 = math.abs(posX - rightData.pos.x) - iconWidth - cornerWidth
			params.scaleY = -1
			params.xy1 = {
				rightData.pos.x,
				posY
			}
			params.xy3 = {
				rightData.pos.x,
				posY + cornerWidth
			}
			params.xy2 = {
				rightData.pos.x - cornerWidth,
				posY
			}
		else
			local iconLHight = rightData.icon:getBoundingBox().height / 2

			params.height2 = rightData.pos.x - posX - iconWidth
			params.height3 = rightData.pos.y - posY - iconLHight + 10
			params.xy2 = {
				rightData.pos.x,
				posY
			}
			params.xy3 = {
				rightData.pos.x,
				posY - 10
			}
			params.rect = cc.rect(15, 10, 1, 1)
		end

		self:settingOutUiShow(params)
	end
end

function GymBuffTree:drawLine(data)
	self.lines = {}

	for i, v in ipairs(data) do
		for ii, vv in ipairs(v) do
			local lines = {}

			self.lines[vv.id] = lines

			local leftData, rightData, preNum

			if i > 1 then
				if #data[i - 1] > #v then
					leftData = data[i - 1][ii]
					rightData = data[i - 1][ii + 1]
				elseif #data[i - 1] < #v then
					leftData = data[i - 1][ii - 1]
					rightData = data[i - 1][ii]
				end

				preNum = leftData and rightData and 2 or 1
			end

			local iconWidth = vv.icon:getBoundingBox().width / 2
			local cornerWidth = 22

			if i == 2 then
				self:drawLineFirst(leftData, rightData, vv)
			elseif i == #data then
				self:drawLineLast(leftData, rightData, vv)
			elseif i > 1 and i ~= #data then
				local posY = (data[i - 1][1].pos.y + vv.pos.y) / 2

				if leftData then
					local leftLines = {}
					local multiple, height2, height3, xy2, xy3
					local cornerLX = preNum == 1 and vv.pos.x or vv.pos.x - (iconWidth / 2 - 5)
					local params = {}

					params.lfData = leftData
					params.scaleX = 1
					params.xy1 = {
						cornerLX,
						posY
					}
					params.rotation = #leftData.nextTalentIDs == 2 and 270 or 90
					params.rect = cc.rect(15, 10, 1, 1)
					params.oneNodeShow = true
					params.lines = lines
					params.leftLines = leftLines

					local iconLHight = leftData.icon:getBoundingBox().height / 2

					if #leftData.nextTalentIDs == 2 then
						params.xy2 = {
							cornerLX - 22,
							posY
						}
						params.xy3 = {
							leftData.pos.x,
							posY - 10
						}
						params.height2 = cornerLX - leftData.pos.x - 22
						params.height3 = leftData.pos.y - posY - iconLHight + 10
					else
						params.multiple = {
							scale = -1,
							xy = {
								leftData.pos.x,
								posY
							}
						}
						params.xy2 = {
							cornerLX + cornerWidth,
							posY
						}
						params.xy3 = {
							leftData.pos.x,
							posY + cornerWidth
						}
						params.height2 = cornerLX - leftData.pos.x - cornerWidth * 2
						params.height3 = leftData.pos.y - posY - iconLHight - cornerWidth + 10
					end

					lines, leftLines = self:settingOutUiShow(params)

					local params2 = {}
					local height = posY - 22 - vv.pos.y - vv.icon:getBoundingBox().height / 2

					params2.leftLines = leftLines
					params2.xy = {
						cornerLX,
						posY - 22
					}
					params2.height = preNum == 2 and height + 15 or height
					params2.preNum = preNum
					params2.scale = -1
					leftLines = self:settingOutUiShow2(params2)
					lines[leftData.id] = leftLines
				end

				if rightData then
					local rightLines = {}
					local multiple
					local rightLines = {}
					local height2, height3, xy2, xy3
					local cornerRX = preNum == 1 and vv.pos.x or vv.pos.x + (iconWidth / 2 - 5)
					local iconLHight = rightData.icon:getBoundingBox().height / 2
					local params = {}

					params.lfData = rightData
					params.scaleX = -1
					params.xy1 = {
						cornerRX,
						posY
					}
					params.rotation = #rightData.nextTalentIDs == 2 and 90 or 270
					params.rect = cc.rect(15, 10, 1, 1)
					params.oneNodeShow = true
					params.lines = lines
					params.leftLines = rightLines

					if #rightData.nextTalentIDs == 2 then
						params.height2 = rightData.pos.x - cornerRX - 22
						params.height3 = rightData.pos.y - posY - iconLHight + 10
						params.xy2 = {
							cornerRX + 22,
							posY
						}
						params.xy3 = {
							rightData.pos.x,
							posY - 10
						}
					else
						params.multiple = {
							scaleY = -1,
							xy = {
								rightData.pos.x,
								posY
							}
						}
						params.height2 = rightData.pos.x - cornerRX - cornerWidth * 2
						params.height3 = rightData.pos.y - posY - iconLHight - cornerWidth + 10
						params.xy2 = {
							rightData.pos.x - cornerWidth,
							posY
						}
						params.xy3 = {
							rightData.pos.x,
							posY + cornerWidth
						}
					end

					lines, rightLines = self:settingOutUiShow(params)

					local params2 = {}
					local height = posY - 22 - vv.pos.y - vv.icon:getBoundingBox().height / 2

					params2.leftLines = rightLines
					params2.xy = {
						cornerRX,
						posY - 22
					}
					params2.height = preNum == 2 and height + 15 or height
					params2.preNum = preNum
					rightLines = self:settingOutUiShow2(params2)
					lines[rightData.id] = rightLines
				end
			end
		end
	end
end

function GymBuffTree:settingOutUiShow(params)
	local data = params.lfData
	local lines = params.lines
	local LinesData = params.leftLines or {}

	if params.oneNodeShow then
		local corner1 = ccui.ImageView:create("city/adventure/gym_challenge/bar_1.png")

		table.insert(LinesData, corner1)

		if params.scaleX then
			corner1:scaleX(params.scaleX)
		elseif params.scale then
			corner1:scale(params.scale)
		elseif params.scaleY then
			corner1:scaleY(params.scaleY)
		end

		corner1:anchorPoint(0.6875, 0.6875):xy(params.xy1[1], params.xy1[2]):addTo(self.scrollview)
	end

	if params.multiple and params.multiple then
		local corner2 = ccui.ImageView:create("city/adventure/gym_challenge/bar_1.png")

		table.insert(LinesData, corner2)

		if params.multiple.scale then
			corner1:scale(params.multiple.scale)
		elseif params.multiple.scaleY then
			corner1:scaleY(params.multiple.scaleY)
		end

		corner2:anchorPoint(0.6875, 0.6875):xy(params.multiple.xy[1], params.multiple.xy[2]):addTo(self.scrollview)
	end

	local rect = params.rect or cc.rect(10, 27, 1, 1)
	local horizontal = ccui.Scale9Sprite:create()

	table.insert(LinesData, horizontal)
	horizontal:initWithFile(rect, "city/adventure/gym_challenge/bar_3.png")
	horizontal:height(params.height2):setRotation(params.rotation):anchorPoint(0.5, 0):xy(params.xy2[1], params.xy2[2]):addTo(self.scrollview)

	local anchor = params.anchor or {
		0.5,
		0
	}
	local vertical = ccui.Scale9Sprite:create()

	table.insert(LinesData, vertical)
	vertical:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
	vertical:height(params.height3)
	vertical:anchorPoint(anchor[1], anchor[2]):xy(params.xy3[1], params.xy3[2]):addTo(self.scrollview)

	lines[data.id] = LinesData

	return lines, LinesData
end

function GymBuffTree:settingOutUiShow2(params)
	if params.preNum == 2 then
		local verticalL2 = ccui.Scale9Sprite:create()

		table.insert(params.leftLines, verticalL2)
		verticalL2:initWithFile(cc.rect(15, 10, 1, 1), "city/adventure/gym_challenge/bar_5.png")
		verticalL2:height(params.height):scaleX(params.scale or 1):anchorPoint(0.5, 1):xy(params.xy[1], params.xy[2]):addTo(self.scrollview)
	else
		local verticalL2 = ccui.Scale9Sprite:create()

		table.insert(params.leftLines, verticalL2)
		verticalL2:initWithFile(cc.rect(10, 27, 1, 1), "city/adventure/gym_challenge/bar_3.png")
		verticalL2:height(params.height):scaleX(params.scale or 1):anchorPoint(0.5, 1):xy(params.xy[1], params.xy[2]):addTo(self.scrollview)
	end

	return params.leftLines
end

function GymBuffTree:refreshShowData(index)
	self.bufIcons = {}

	self.scrollview:removeAllChildren()

	local data, maxW = self:getDepthData(index)

	self:drawBufIcon(data, maxW)
	self:drawLine(data)
end

function GymBuffTree:onTabClick(list, index)
	self.showTab:set(index)
end

function GymBuffTree:onResetClick()
	local resetTime = self.gymDatas:read().gym_talent_reset_times or 0
	local times = math.min(resetTime + 1, csvSize(gCostCsv.gym_talent_reset_cost))
	local cost = gCostCsv.gym_talent_reset_cost[times]
	local gymDatas = self.gymDatas:read()

	if csvSize(gymDatas.gym_talent_trees) == 0 then
		gGameUI:showTip(gLanguageCsv.gymBuffCannotReset)

		return
	end

	local str = string.format(gLanguageCsv.gymBuffReset, cost)

	gGameUI:showDialog({
		isRich = true,
		btnType = 2,
		clearFast = true,
		strs = {
			str
		},
		cb = function()
			if gGameModel.role:read("rmb") >= cost then
				gGameApp:requestServer("/game/gym/talent/reset", function(tb)
					return
				end)
			else
				uiEasy.showDialog("rmb")
			end
		end,
		dialogParams = {
			clickClose = false
		}
	})
end

function GymBuffTree:onAddClick()
	local costCft = gCostCsv.gym_talent_point_buy_cost
	local times = math.min(self.buyTimes:read() + 1, csvSize(gCostCsv.gym_talent_point_buy_cost))
	local cost = costCft[times]

	if gGameModel.daily_record:read("gym_talent_point_buy_times") >= gVipCsv[gGameModel.role:read("vip_level")].gymTalentPointBuyTimes then
		gGameUI:showTip(gLanguageCsv.cardCapacityBuyMax)

		return
	end

	local str = string.format(gLanguageCsv.gymBuffBuy, cost, gCommonConfigCsv.gymTalentPointBuyCount)

	gGameUI:showDialog({
		isRich = true,
		btnType = 2,
		clearFast = true,
		strs = {
			str
		},
		cb = function()
			if gGameModel.role:read("rmb") >= cost then
				gGameApp:requestServer("/game/gym/talent/point/buy", function(tb)
					gGameUI:showTip(gLanguageCsv.buySuccess)
				end)
			else
				uiEasy.showDialog("rmb")
			end
		end,
		dialogParams = {
			clickClose = false
		}
	})
end

return GymBuffTree
