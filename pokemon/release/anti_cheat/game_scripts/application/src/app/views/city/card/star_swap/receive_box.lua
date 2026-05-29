-- chunkname: @src.app.views.city.card.star_swap.receive_box

local StarSwapReceiveBoxView = class("StarSwapReceiveBoxView", Dialog)
local StarTools = require("app.views.city.card.star_swap.tools")

StarSwapReceiveBoxView.RESOURCE_FILENAME = "receive_prompt_box.json"
StarSwapReceiveBoxView.RESOURCE_BINDING = {
	panel = "panel",
	closeBtn = {
		varname = "closeBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	}
}

function StarSwapReceiveBoxView:onCreate(params)
	self.count = params.count

	self.panel:hide()

	self.node = self:getResourceNode()

	local originX = self.closeBtn:x()

	idlereasy.when(self.count, function(_, count)
		self.node:removeChildByName("tempLeft")
		self.node:removeChildByName("tempRight")

		if count <= 0 then
			return
		end

		self:getReceiveData()
		self.closeBtn:x(originX)

		local countRight = count - self.countLeft

		if not self.receiveDataLeft then
			self:refreshView(self.receiveDataRight, countRight, "right"):name("tempRight")
		elseif not self.receiveDataRight then
			self:refreshView(self.receiveDataLeft, self.countLeft, "left"):name("tempLeft")
		else
			self.closeBtn:x(originX + 530)
			self:refreshView(self.receiveDataLeft, self.countLeft, "left"):name("tempLeft"):x(self.panel:x() - 530)
			self:refreshView(self.receiveDataRight, countRight, "right"):name("tempRight"):x(self.panel:x() + 530)
		end
	end)
	Dialog.onCreate(self)
end

function StarSwapReceiveBoxView:getReceiveData()
	local data = {}
	local realTime = time.getTime()
	local createTime = gGameModel.role:read("created_time")
	local deliverRecord = gGameModel.role:read("card_star_swap_times_deliver_record")

	for id, v in orderCsvPairs(csv.card_star_swap_times_deliver) do
		if not deliverRecord or not deliverRecord[id] then
			local hour, min = time.getHourAndMin(v.time)
			local effectTime = time.getNumTimestamp(v.date, hour, min)
			local hourEnd, minEnd = time.getHourAndMin(v.endTime)
			local endTime = time.getNumTimestamp(v.endDate, hourEnd, minEnd)
			local vipLevel = gGameModel.role:read("vip_level")
			local roleLevel = gGameModel.role:read("level")
			local startRoleTime = time.getNumTimestamp(v.validRoleCreatedEarliestDate)
			local endRoleTime = time.getNumTimestamp(v.validRoleCreatedLatestDate)

			if matchLanguageForce(v.languages) and effectTime <= realTime and realTime <= endTime and (v.type ~= 3 or createTime <= endRoleTime and startRoleTime <= createTime) and ((v.type == 3 or v.type == 2) and roleLevel >= v.param or v.type == 1 and vipLevel >= v.param) then
				table.insert(data, {
					id = id,
					endTime = string.format(gLanguageCsv.yearMonthDay, time.getYearMonthDay(v.endDate)) .. " " .. hourEnd .. ":" .. minEnd,
					createRoleTime = v.validRoleCreatedEarliestDate,
					endRoleTime = v.validRoleCreatedLatestDate,
					type = v.type,
					value = v.param,
					award = v.starSwapTimes
				})
			end
		end
	end

	table.sort(data, function(a, b)
		return a.id < b.id
	end)

	self.receiveDataLeft = nil
	self.receiveDataRight = nil
	self.countLeft = 0

	for _, v in ipairs(data) do
		if v.type == 2 then
			self.countLeft = self.countLeft + 1

			if not self.receiveDataLeft then
				self.receiveDataLeft = v
			end
		elseif not self.receiveDataRight then
			self.receiveDataRight = v
		end
	end
end

function StarSwapReceiveBoxView:refreshView(receiveData, count, dir)
	local curData = receiveData
	local str = ""
	local createRoleTime = string.format(gLanguageCsv.yearMonthDay, time.getYearMonthDay(curData.createRoleTime))
	local endRoleTime = string.format(gLanguageCsv.yearMonthDay, time.getYearMonthDay(curData.endRoleTime))
	local level = gGameModel.role:read("level")

	if curData.type == 3 then
		str = string.format(gLanguageCsv.starReceive1, curData.value, createRoleTime, endRoleTime, curData.endTime)
	elseif curData.type == 2 then
		local color = level >= curData.value and "#C0x60C456#" or "#C0xF76B45#"
		local state = level >= curData.value and gLanguageCsv.complete or gLanguageCsv.notReach

		str = string.format(gLanguageCsv.starReceive3, color, string.format("%s/%s", level, curData.value), string.format(gLanguageCsv.brackets, state))
	elseif curData.type == 1 then
		str = string.format(gLanguageCsv.starReceive2, uiEasy.getVipStr(curData.value).str, createRoleTime, endRoleTime, curData.endTime)
	end

	local panel = self.panel:clone():addTo(self.node):xy(self.panel:xy()):show()
	local title = panel:get("title")

	if dir == "left" then
		title:text(gLanguageCsv.starReceiveTitleLeft)
	else
		title:text(gLanguageCsv.starReceiveTitleRight)
	end

	local content = panel:get("content")
	local contentList = content:get("list")

	content:removeChildByName("richText")
	rich.createWithWidth(str, 44, nil, 800):anchorPoint(0.5, 1):addTo(content):xy(450, content:height() - 30):name("richText")
	contentList:setScrollBarEnabled(false)
	contentList:removeAllItems()

	local specialColorTab = {
		StarTools.SNOUSEPROPKEY,
		StarTools.SPLUSNOUSEPROPKEY
	}

	for key, num in csvMapPairs(curData.award) do
		local color = itertools.include(specialColorTab, key) and "#C0x60C456#" or "#C0x5B545B#"
		local txt = color .. dataEasy.getCfgByKey(key).name .. " x" .. num
		local richText = rich.createByStr(txt, 44)

		contentList:pushBackCustomItem(richText:formatText())
	end

	local contentCount = content:get("count")
	local tipText = content:get("tipText")

	tipText:text(gLanguageCsv.starSwapGet)
	contentCount:text(count)
	adapt.oneLineCenterPos(cc.p(contentList:x() + 400, contentList:y() - 30), {
		tipText,
		contentCount
	}, cc.p(10, 0))

	local btn = panel:get("btnOkCenter")

	text.addEffect(btn:get("title"), {
		glow = {
			color = ui.COLORS.GLOW.WHITE
		}
	})
	bind.touch(self, btn, {
		methods = {
			ended = function()
				self:onReceive(receiveData)
			end
		}
	})

	return panel
end

function StarSwapReceiveBoxView:onReceive(receiveData)
	local curData = receiveData
	local sPropCount = math.min(dataEasy.getNumByKey(StarTools.SPROPKEY) + dataEasy.getNumByKey(StarTools.SNOUSEPROPKEY), gCommonConfigCsv.starSwapSMax)

	sPropCount = sPropCount + (curData.award[StarTools.SPROPKEY] or 0) + (curData.award[StarTools.SNOUSEPROPKEY] or 0)

	local sPlusPropCount = math.min(dataEasy.getNumByKey(StarTools.SPLUSPROPKEY) + dataEasy.getNumByKey(StarTools.SPLUSNOUSEPROPKEY), gCommonConfigCsv.starSwapSPlusMax)

	sPlusPropCount = sPlusPropCount + (curData.award[StarTools.SPLUSPROPKEY] or 0) + (curData.award[StarTools.SPLUSNOUSEPROPKEY] or 0)

	if sPropCount > gCommonConfigCsv.starSwapSMax or sPlusPropCount > gCommonConfigCsv.starSwapSPlusMax then
		gGameUI:showTip(gLanguageCsv.starSwapNumLimit)

		return
	end

	gGameApp:requestServer("/game/role/card_star_swap/times/get", function(tb)
		if self.count:read() <= 0 then
			self:addCallbackOnExit(function()
				gGameUI:showGainDisplay(tb)
			end)
			self:onClose()
		else
			gGameUI:showGainDisplay(tb)
		end
	end, curData.id)
end

function StarSwapReceiveBoxView:onClose()
	Dialog.onClose(self)
end

return StarSwapReceiveBoxView
