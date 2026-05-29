-- chunkname: @src.app.views.city.adventure.dispatch_task.view

local dispatchtaskTools = require("app.views.city.adventure.dispatch_task.tools")
local QUALITY_IMG = {
	"city/adventure/dispatchtask/icon_rarity1.png",
	"city/adventure/dispatchtask/icon_rarity2.png",
	"city/adventure/dispatchtask/icon_rarity3.png",
	"city/adventure/dispatchtask/icon_rarity4.png",
	"city/adventure/dispatchtask/icon_rarity5.png"
}
local REFRESH_COST = gCommonConfigCsv.dispatchTaskRefreshCostRMB
local DONE_COST = gCommonConfigCsv.dispatchTaskDoneAtOnceCostRMB
local DONE_SECOND = gCommonConfigCsv.dispatchTaskDoneAtOnceSecond

local function getTimeStr(timeMin)
	local str = ""
	local t = time.getCutDown(timeMin * 60)

	if t.day > 0 then
		str = str .. string.format(gLanguageCsv.day, t.day)
	end

	if t.hour > 0 then
		str = str .. string.format(gLanguageCsv.hour, t.hour)
	end

	if t.min > 0 then
		str = str .. string.format(gLanguageCsv.minute, t.min)
	end

	return str
end

local function setCostTxt(panel, myCoin, needCoin, isFree, curRefreshTimes)
	local cost = panel:get("cost")

	if isFree then
		local freeNum = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.DispatchTaskFreeRefreshTimes)

		needCoin = string.format("%s(%s/%s)", gLanguageCsv.free, freeNum - curRefreshTimes, freeNum)
	end

	cost:text(needCoin)

	local coinColor = ui.COLORS.NORMAL.WHITE

	if isFree then
		coinColor = ui.COLORS.NORMAL.FRIEND_GREEN
	elseif myCoin < needCoin then
		coinColor = ui.COLORS.NORMAL.RED
	end

	text.addEffect(cost, {
		color = coinColor
	})
	adapt.oneLinePos(panel:get("costIcon"), {
		cost,
		panel:get("costNote")
	}, cc.p(20, 0), "right")
	adapt.oneLinePos(panel:get("costNote"), {
		panel:get("taskNum"),
		panel:get("taskNumNote")
	}, {
		cc.p(80, 0),
		cc.p(5, 0)
	}, "right")
end

local function setSubTime(list, childs, v, k)
	local tmpTime = v.subTime

	adapt.oneLinePos(childs.countDownPanel:get("timeNote"), childs.countDownPanel:get("icon"), cc.p(5, 0))
	adapt.oneLinePos(childs.countDownPanel:get("icon"), childs.countDownPanel:get("text"), cc.p(10, 0))
	list:enableSchedule():schedule(function()
		if tmpTime <= time.getTime() then
			if v.status == 3 then
				gGameApp:requestServer("/game/dispatch/task/refresh", nil, false)
				childs.btnReward:show()
				childs.canRecievePanel:show()
				childs.btnComplete:hide()
				childs.countDownPanel:hide()
			end

			list:unSchedule(k)
		else
			childs.countDownPanel:get("text"):text(gLanguageCsv.exclusiveIconTime .. " " .. time.getCutDown(tmpTime - time.getTime()).str)
		end
	end, 1, 0, "item" .. k)
end

local function setEffect(parent, quality)
	local effect = parent:get("effect")
	local size = parent:size()
	local effectName = quality == 1 and "effect" or "effect" .. quality - 1

	if not effect then
		effect = widget.addAnimationByKey(parent, "diban/diban.skel", "effect", effectName, -1):xy(size.width / 2 + 5, size.height / 2 + 20):scale(2)
	else
		effect:play(effectName)
	end
end

local DispatchTaskView = class("DispatchTaskView", cc.load("mvc").ViewBase)

DispatchTaskView.RESOURCE_FILENAME = "dispatch_task.json"
DispatchTaskView.RESOURCE_BINDING = {
	bottomPanel = "bottomPanel",
	["bottomPanel.costIcon"] = "costIcon",
	attrItem = "attrItem",
	item = "item",
	list = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				padding = 38,
				data = bindHelper.self("taskDatas"),
				item = bindHelper.self("item"),
				attrItem = bindHelper.self("attrItem"),
				onItem = function(list, node, k, v)
					node:stopAllActions()
					node:removeChildByName("effect")
					node:setName("item" .. list:getIdx(k))

					local attrItem = list.attrItem
					local childs = node:multiget("canRecievePanel", "countDownPanel", "iconCompleted", "textTitle", "imgQuality", "normalPanel", "conditionPanel", "rewardPanel", "btnReward", "btnComplete")

					setSubTime(list, childs, v, k)
					dispatchtaskTools.setRewardPanel(list, childs.rewardPanel, v.cfg.award, "icon", "main")
					dispatchtaskTools.setRewardPanel(list, childs.rewardPanel, v.cfg.extraAward, "extraIcon", "main")
					dispatchtaskTools.setItemCondition(childs.conditionPanel, v, attrItem, "main")
					childs.textTitle:text(v.cfg.name)
					childs.imgQuality:texture(QUALITY_IMG[v.quality])
					childs.normalPanel:get("time"):text(getTimeStr(v.cfg.duration))
					adapt.oneLinePos(childs.normalPanel:get("timeNote"), childs.normalPanel:get("time"))
					adapt.oneLinePos(childs.canRecievePanel:get("timeNote"), childs.canRecievePanel:get("text"))
					text.addEffect(childs.btnReward:get("textNote"), {
						glow = {
							color = ui.COLORS.GLOW.WHITE
						},
						color = ui.COLORS.NORMAL.WHITE
					})
					itertools.invoke(childs, "hide")
					performWithDelay(node, function()
						setEffect(node, v.quality)

						local effect = node:get("effect")

						effect:setSpriteEventHandler(function(event, eventArgs)
							itertools.invoke(childs, "show")
							childs.normalPanel:visible(v.status ~= 1 and v.status ~= 3)
							childs.canRecievePanel:visible(v.status == 1)
							childs.iconCompleted:visible(v.status == 4)
							childs.btnReward:visible(v.status == 1)
							childs.btnComplete:visible(v.status == 3)
							childs.countDownPanel:visible(v.status == 3)
							effect:setSpriteEventHandler()
						end, sp.EventType.ANIMATION_COMPLETE)
					end, 0.2)
					performWithDelay(node, function()
						childs.btnReward:visible(v.status == 1)
						childs.btnComplete:visible(v.status == 3)
					end, 0.5)
					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.clickCell, k, v)
						}
					})
					bind.touch(list, childs.btnReward, {
						methods = {
							ended = functools.partial(list.btnReward, k, v)
						}
					})
					bind.touch(list, childs.btnComplete, {
						methods = {
							ended = functools.partial(list.btnComplete, k, v)
						}
					})
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild"),
				clickCell = bindHelper.self("onItemClick"),
				btnReward = bindHelper.self("onBtnReward"),
				btnComplete = bindHelper.self("onBtnComplete")
			}
		}
	},
	["bottomPanel.btn"] = {
		varname = "bottomBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onRefresh")
			}
		}
	},
	["bottomPanel.costNote"] = {
		varname = "costNote",
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.DEFAULT
				}
			}
		}
	},
	["bottomPanel.cost"] = {
		varname = "cost",
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.DEFAULT
				}
			}
		}
	},
	["bottomPanel.taskNumNote"] = {
		varname = "taskNumNote",
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.DEFAULT
				}
			}
		}
	},
	["bottomPanel.taskNum"] = {
		varname = "taskNum",
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.DEFAULT
				}
			}
		}
	},
	["bottomPanel.taskTimeNote"] = {
		varname = "taskTimeNote",
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.DEFAULT
				}
			}
		}
	},
	["bottomPanel.taskTime"] = {
		varname = "taskTime",
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.DEFAULT
				},
				color = ui.COLORS.NORMAL.LIGHT_GREEN
			}
		}
	},
	["bottomPanel.oneKeyBtn"] = {
		varname = "oneKeyBtn",
		binds = {
			{
				event = "touch",
				methods = {
					ended = bindHelper.self("onOneKeyBtnClick")
				}
			},
			{
				event = "visible",
				idler = bindHelper.self("oneKeyListen")
			}
		}
	}
}

function DispatchTaskView:onCreate(datas)
	self:initModel()
	gGameUI.topuiManager:createView("default", self, {
		onClose = self:createHandler("onClose")
	}):init({
		subTitle = "SEND",
		title = gLanguageCsv.dispatch
	})

	self.oneKeyListen = dataEasy.getListenShow(gUnlockCsv.dispatchTaskAwardOneKey)

	if self.oneKeyListen:read() == false then
		local diffX = self.oneKeyBtn:x() - self.bottomBtn:x()

		for _, v in ipairs({
			self.bottomBtn,
			self.costIcon,
			self.cost,
			self.costNote,
			self.taskNum,
			self.taskNumNote
		}) do
			v:x(v:x() + diffX)
		end
	end

	adapt.centerWithScreen({
		"left",
		nil,
		false
	}, {
		"right",
		nil,
		false
	}, nil, {
		{
			self.taskTimeNote,
			"pos",
			"left"
		},
		{
			self.taskTime,
			"pos",
			"left"
		},
		{
			self.taskNum,
			"pos",
			"right"
		},
		{
			self.taskNumNote,
			"pos",
			"right"
		},
		{
			self.cost,
			"pos",
			"right"
		},
		{
			self.costNote,
			"pos",
			"right"
		},
		{
			self.costIcon,
			"pos",
			"right"
		},
		{
			self.bottomBtn,
			"pos",
			"right"
		},
		{
			self.oneKeyBtn,
			"pos",
			"right"
		},
		{
			self.list,
			"width"
		},
		{
			self.list,
			"pos",
			"left"
		}
	})
	self.item:get("conditionPanel.attrList"):setScrollBarEnabled(false)
	adapt.oneLinePos(self.item:get("conditionPanel.extraCondition2"), self.item:get("conditionPanel.attrList"))

	self.taskDatas = idlertable.new({})
	self.accessibleNum = idler.new(0)

	idlereasy.any({
		self.dispatchTasks,
		self.vipLevel
	}, function(_, dispatchTasks, vipLevel)
		local curTime = time.getTime()
		local t = time.getTimeTable()
		local hour

		if t.hour < 5 then
			hour = 4 - t.hour
		elseif t.hour >= 18 then
			hour = 28 - t.hour
		else
			hour = 17 - t.hour
		end

		local nextTime = curTime + hour * 3600 + (59 - t.min) * 60 + (59 - t.sec) + 1

		gGameModel.forever_dispatch:getIdlerOrigin("dispatchTasksNextAutoTime"):set(nextTime)

		self.canGetNum = 0
		self.selectIdx = 1

		local taskDatas = {}
		local accessibleNum = 0
		local canGetNum = 0

		for k, v in ipairs(dispatchTasks) do
			local cfg = csv.dispatch_task.tasks[v.csvID]
			local status = v.status
			local subTime = v.ending_time or 0

			if status == 1 then
				status = 4
			end

			if status == 3 and subTime <= time.getTime() then
				status = 1
			end

			if status == 2 then
				accessibleNum = accessibleNum + 1
			end

			if status == 1 then
				canGetNum = canGetNum + 1
			end

			table.insert(taskDatas, {
				dbid = k,
				csvID = v.csvID,
				fightingPoint = v.fighting_point,
				status = status,
				cardIDs = v.cardIDs or {},
				endingTime = v.ending_time,
				subTime = subTime,
				extraAwardPoint = v.extra_award_point or 0,
				cfg = cfg,
				quality = cfg.quality,
				taskData = v
			})
		end

		self.accessibleNum:set(accessibleNum)

		self.canGetNum = canGetNum

		self.bottomPanel:get("taskNum"):text(accessibleNum .. "/" .. gVipCsv[vipLevel].dispatchTaskCount)

		local color = accessibleNum == 0 and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.LIGHT_GREEN

		text.addEffect(self.bottomPanel:get("taskNum"), {
			color = color
		})
		table.sort(taskDatas, function(a, b)
			if a.status ~= b.status then
				return a.status < b.status
			end

			return a.quality > b.quality
		end)

		if self.showAcceptPos then
			for k, v in ipairs(taskDatas) do
				if v.status == 2 then
					self.selectIdx = k + 1

					break
				end
			end
		end

		if canGetNum > 0 then
			text.addEffect(self.oneKeyBtn:get("textNote"), {
				glow = {
					color = ui.COLORS.OUTLINE.WHITE
				}
			})
			uiEasy.setBtnShader(self.oneKeyBtn, nil, 1)
		else
			text.deleteAllEffect(self.oneKeyBtn:get("textNote"))
			uiEasy.setBtnShader(self.oneKeyBtn, nil, 2)
		end

		uiEasy.setBtnShader(self.oneKeyBtn, nil, canGetNum > 0 and 1 or 2)
		self.taskDatas:set(taskDatas)
	end)
	idlereasy.any({
		self.rmb,
		self.accessibleNum,
		self.freeRefreshTimes
	}, function(_, rmb, accessibleNum, freeRefreshTimes)
		local freeNum = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.DispatchTaskFreeRefreshTimes)
		local isFree = freeRefreshTimes < freeNum

		self.costIcon:visible(not isFree)
		setCostTxt(self.bottomPanel, rmb, accessibleNum * REFRESH_COST, isFree, freeRefreshTimes)
	end)
	DispatchTaskView.setRefreshTime(self, self.taskTime, {
		sendGameProtocol = true,
		tag = "DispatchTaskView",
		cb = function()
			self.showAcceptPos = true
		end
	})

	if self.relicBuff then
		local node = self:getResourceNode()

		idlereasy.when(self.relicBuff, function(_, relicBuff)
			uiEasy.addRelicIcon(node, relicBuff, game.RELIC_BUFF.DISPATCH, {
				scale = 0.8,
				y = 90,
				x = self.taskNumNote:x() - 130
			})
		end)
	end
end

function DispatchTaskView:initModel()
	self.dispatchTasks = gGameModel.role:getIdler("dispatch_tasks")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.last_time = gGameModel.role:getIdler("dispatch_task_last_time")
	self.freeRefreshTimes = gGameModel.daily_record:getIdler("dispatch_refresh_free_times")

	if dataEasy.isTownRelicBuffUnlock() then
		self.relicBuff = gGameModel.town:getIdler("relic_buff")
	end
end

function DispatchTaskView:onItemClick(list, k, v)
	self.showAcceptPos = true

	local subTime = v.endingTime or 0

	if v.status == 3 and subTime > time.getTime() then
		gGameUI:showTip(gLanguageCsv.currentTaskDispatched)

		return
	end

	if v.status == 4 then
		gGameUI:showTip(gLanguageCsv.currentTaskCompleted)

		return
	end

	if v.status ~= 2 then
		return
	end

	if self.canGetNum >= 24 then
		gGameUI:showTip(gLanguageCsv.pleaseCollectCompletedReward)

		return
	end

	gGameUI:stackUI("city.adventure.dispatch_task.sprite_select", nil, {
		full = true
	}, v)
end

function DispatchTaskView:onBtnReward(list, k, v)
	self.showAcceptPos = false

	gGameApp:requestServer("/game/dispatch/task/award", function(tb)
		gGameUI:showGainDisplay(tb)
	end, v.dbid, false)
end

function DispatchTaskView:onBtnComplete(list, k, v)
	self.showAcceptPos = false

	local cost = math.max(math.ceil((v.subTime - time.getTime()) / DONE_SECOND) - 1, 0) * DONE_COST

	gGameUI:stackUI("city.develop.talent.reset", nil, {
		clickClose = true
	}, {
		from = "dispatch_task",
		typ = "end",
		cost = cost,
		title = gLanguageCsv.tips,
		txt1 = gLanguageCsv.consumptionOrNot,
		txt2 = gLanguageCsv.completeTheTaskImmediately,
		requestParams = {
			v.dbid,
			true
		},
		cb = self:createHandler("onBtnCompleteCb")
	})
end

function DispatchTaskView:onBtnCompleteCb(tb)
	gGameUI:showGainDisplay(tb)
end

function DispatchTaskView:onRefresh()
	local freeNum = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.DispatchTaskFreeRefreshTimes)

	if self.accessibleNum:read() <= 0 then
		gGameUI:showTip(gLanguageCsv.currentlyNoTasksRefresh)

		return
	end

	if freeNum > self.freeRefreshTimes:read() then
		self.showAcceptPos = true

		gGameApp:requestServer("/game/dispatch/task/refresh", nil, true)

		return
	end

	if self.accessibleNum:read() * REFRESH_COST > self.rmb:read() then
		gGameUI:showTip(gLanguageCsv.yuanzhengShopRefreshRMBNotEnough)

		return
	end

	self.showAcceptPos = true

	gGameUI:stackUI("city.develop.talent.reset", nil, {
		clickClose = true
	}, {
		from = "dispatch_task",
		cost = self.accessibleNum:read() * REFRESH_COST,
		title = gLanguageCsv.tips,
		txt1 = gLanguageCsv.consumptionOrNot,
		txt2 = gLanguageCsv.refreshTaskQuality
	})
end

function DispatchTaskView:onSortCards(list)
	return function(a, b)
		if a.status ~= b.status then
			return a.status < b.status
		end

		return a.quality > b.quality
	end
end

function DispatchTaskView:onAfterBuild()
	if self.selectIdx ~= nil then
		self.list:jumpToItem(self.selectIdx, cc.p(1, 0), cc.p(1, 0))
	end
end

function DispatchTaskView.setRefreshTime(view, uiTime, params)
	view:enableSchedule():schedule(function()
		local t = time.getTimeTable()
		local hour

		if t.hour < 5 then
			hour = 4 - t.hour
		elseif t.hour >= 18 then
			hour = 28 - t.hour
		else
			hour = 17 - t.hour
		end

		if (t.hour == 5 or t.hour == 18) and t.min == 0 and t.sec == 0 then
			if params.cb then
				params.cb()
			end

			if params.sendGameProtocol then
				gGameApp:requestServer("/game/dispatch/task/refresh", nil, false)
			end
		end

		if uiTime then
			local str = string.format("%02d:%02d:%02d", hour, 59 - t.min, 59 - t.sec)

			uiTime:text(str)
		end
	end, 1, 0, params.tag)
end

function DispatchTaskView:onOneKeyBtnClick()
	gGameUI:showDialog({
		clearFast = true,
		btnType = 2,
		isRich = true,
		content = string.format(gLanguageCsv.dispatchTaskTip, self.canGetNum),
		cb = function()
			gGameApp:requestServer("/game/dispatch/task/award/onekey", function(tb)
				gGameUI:stackUI("city.adventure.dispatch_task.one_key_detail", nil, nil, tb.view.result)
			end)
		end
	})
end

return DispatchTaskView
