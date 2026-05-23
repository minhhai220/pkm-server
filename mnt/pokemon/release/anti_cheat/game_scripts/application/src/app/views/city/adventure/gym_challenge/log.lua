-- chunkname: @src.app.views.city.adventure.gym_challenge.log

local ViewBase = cc.load("mvc").ViewBase
local GymLog = class("GymLog", ViewBase)
local onelineHeight = 46
local fontSize = 40
local itemHeight = 80
local LOG_TYPE = {
	gymClosed = 19,
	gymReset = 1
}
local LOG_LANGUGE = {
	"gymReset",
	"gymFubenPass",
	"gymAllPass",
	"gymOccupy",
	"gymLeaderWin",
	"gymLeaderFail",
	"crossGymLeaderOccupy",
	"crossGymOccupy",
	"crossGymLeaderWin",
	"crossGymWin",
	"crossGymLeaderFail",
	"crossGymFail",
	"gymLeaderDefenceWin",
	"gymLeaderDefenceFail",
	"crossGymLeaderDefenceWin",
	"crossGymLeaderDefenceFail",
	"crossGymDefenceWin",
	"crossGymDefenceFail",
	"gymClosed",
	"gymGarrison2",
	"gymPassGate2"
}

GymLog.RESOURCE_FILENAME = "gym_log.json"
GymLog.RESOURCE_BINDING = {
	item = "item",
	recordList = {
		varname = "recordList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("logDatas"),
				item = bindHelper.self("item"),
				time = bindHelper.self("lastTime"),
				preloadCenterIndex = bindHelper.self("preloadCenterIndex"),
				itemAction = {
					isAction = true
				},
				preloadBottom = bindHelper.self("preloadBottom"),
				onItem = function(list, node, k, v)
					local height = itemHeight
					local timeStamps = v.time
					local hour, min = time.getHourAndMin(v.time)
					local t = time.getDate(v.time)

					node:get("textTime"):text(string.format("[%02d:%02d]", t.hour, t.min))

					local str = ""
					local urlData = {}

					if LOG_LANGUGE[v.type] == "gymClosed" then
						if v.pass_num > 0 then
							str = gLanguageCsv[LOG_LANGUGE[v.type]] .. "\n" .. string.format(gLanguageCsv.gymPassGate1, v.pass_num)
						else
							str = gLanguageCsv[LOG_LANGUGE[v.type]] .. "\n" .. string.format(gLanguageCsv.gymPassGate2, v.pass_num)
						end

						if v.leader_gym_id then
							local name = csv.gym.gym[v.leader_gym_id].name
							local color = csv.gym.gym[v.leader_gym_id].fontColor

							str = str .. "\n" .. string.format(gLanguageCsv.gymGarrison1, color .. name .. "#C0x5B545B#", "#T44-0.8#")
						end

						if v.cross_leader_gym_id then
							local name = csv.gym.gym[v.cross_leader_gym_id].name
							local color = csv.gym.gym[v.cross_leader_gym_id].fontColor

							str = str .. "\n" .. string.format(gLanguageCsv.gymGarrison1, color .. gLanguageCsv.crossServer .. name .. "#C0x5B545B#", "#T45-0.8#")
						end

						if v.cross_gym_id then
							local name = csv.gym.gym[v.cross_gym_id].name
							local color = csv.gym.gym[v.cross_gym_id].fontColor

							str = str .. "\n" .. string.format(gLanguageCsv.gymGarrison2, color .. gLanguageCsv.crossServer .. name .. "#C0x5B545B#", "#T45-0.8#")
						end
					elseif v.gym_id then
						local color = csv.gym.gym[v.gym_id].fontColor
						local name = csv.gym.gym[v.gym_id].name

						if string.find(LOG_LANGUGE[v.type], "cross") then
							str = string.format(gLanguageCsv[LOG_LANGUGE[v.type]], color .. gLanguageCsv.crossServer .. name .. "#C0x5B545B#")
						else
							str = string.format(gLanguageCsv[LOG_LANGUGE[v.type]], color .. name .. "#C0x5B545B#")
						end

						str = string.format(str, color .. name .. "#C0x5B545B#")

						if v.gym_battle_history then
							str = str .. "#LULgymLog##Icommon/btn/img_ckxq.png-182-54#"
							urlData = v.gym_battle_history
						end
					else
						str = gLanguageCsv[LOG_LANGUGE[v.type]]
					end

					node:removeChildByName("text")

					local richText = rich.createByStr(str, 40)

					rich.adjustWidth(richText, 2000, 34)
					richText:formatText()
					richText:anchorPoint(cc.p(0, 1))
					richText:xy(cc.p(330, 40))
					richText:addTo(node, 10, "text")

					local dataTb = table.deepcopy(urlData or {}, true)

					dataTb.type = v.type

					uiEasy.setUrlHandler(richText, dataTb)

					local textHeight = richText:height()

					height = height - onelineHeight + richText:height()

					richText:xy(330, (itemHeight - onelineHeight) / 2 + textHeight)
					node:get("textTime"):y((itemHeight - onelineHeight) / 2 + textHeight - onelineHeight / 2)

					if v.showDate then
						node:get("textDate"):text(t.month .. "." .. t.day)
						node:get("imgSlider1"):show()

						height = height + 100

						node:get("textDate"):y(height - 50)
						node:get("imgSlider1"):y(height - 50)
					else
						node:get("textDate"):hide()
						node:get("imgSlider1"):hide()
					end

					if v.showTitle then
						node:get("imgWeek"):y(height + 10)

						height = height + 60

						node:get("imgWeek"):show()

						if v.weekType == 1 then
							node:get("imgWeek.textNote"):text(gLanguageCsv.lastWeek)
						else
							node:get("imgWeek.textNote"):text(gLanguageCsv.thisWeek)
						end
					end

					node:height(height)
					node:get("imgSlider2"):height(height)

					if timeStamps > list.time and k > #list.data - 5 then
						node:get("imgNew"):y((itemHeight - onelineHeight) / 2 + textHeight - onelineHeight / 2):show()
					end
				end
			},
			handlers = {
				detailClick = bindHelper.self("onDetailClick")
			}
		}
	}
}

function GymLog:onCreate()
	gGameUI.topuiManager:createView("default", self, {
		onClose = self:createHandler("onClose")
	}):init({
		subTitle = "CHALLENGE LOG",
		title = gLanguageCsv.gymLogs
	})
	self:initData()

	self.lastTime = userDefault.getForeverLocalKey("gymLogOpenTime", 0)

	if self.preloadCenterIndex then
		dataEasy.tryCallFunc(self.recordList, "updatePreloadCenterIndex")
	else
		self.preloadBottom = true
	end
end

function GymLog:onCleanup()
	local currentItem = self.recordList:getCenterItemInCurrentView()

	if currentItem then
		self.preloadCenterIndex = self.recordList:getIndex(currentItem) + 1
	end

	self.preloadBottom = nil

	ViewBase.onCleanup(self)
end

function GymLog:initData()
	local modelRecord = gGameModel.gym:read("record")
	local lastLogs = modelRecord.last_logs or {}
	local curLogs = modelRecord.logs or {}
	local closeInfo = modelRecord.gym_close_info or {}
	local lastCloseInfo = modelRecord.last_gym_close_info or {}
	local logs = {}

	for i, log in pairs(lastLogs) do
		local log = table.shallowcopy(log)

		log.weekType = 1

		table.insert(logs, log)
	end

	for i, log in pairs(curLogs) do
		local log = table.shallowcopy(log)

		log.weekType = 2

		table.insert(logs, table.shallowcopy(log))
	end

	local refreshDayTime = time.getNumTimestamp(time.getWeekStrInClock(5))
	local timeReset1 = refreshDayTime + 18000 - 604800

	table.insert(logs, {
		weekType = 1,
		showTitle = true,
		time = timeReset1,
		type = LOG_TYPE.gymReset
	})

	local timeReset2 = refreshDayTime + 18000

	table.insert(logs, {
		weekType = 2,
		showTitle = true,
		time = timeReset2,
		type = LOG_TYPE.gymReset
	})

	local time1 = refreshDayTime - 7200 - 900

	if time1 < time.getTime() then
		table.insert(logs, {
			weekType = 1,
			time = time1,
			type = LOG_TYPE.gymClosed,
			pass_num = lastCloseInfo.pass_num or 0,
			leader_gym_id = lastCloseInfo.leader_gym_id,
			cross_leader_gym_id = lastCloseInfo.cross_leader_gym_id,
			cross_gym_id = lastCloseInfo.cross_gym_id
		})
	end

	local time1 = refreshDayTime + 604800 - 7200 - 900

	if time1 < time.getTime() then
		table.insert(logs, {
			weekType = 2,
			time = time1,
			type = LOG_TYPE.gymClosed,
			pass_num = closeInfo.pass_num or 0,
			leader_gym_id = closeInfo.leader_gym_id,
			cross_leader_gym_id = closeInfo.cross_leader_gym_id,
			cross_gym_id = closeInfo.cross_gym_id
		})
	end

	table.sort(logs, function(a, b)
		if a.time == b.time then
			return a.type < b.type
		else
			return a.time < b.time
		end
	end)

	for k, v in ipairs(logs) do
		if k == 1 then
			v.showDate = true
		elseif time.getDate(v.time).yday ~= time.getDate(logs[k - 1].time).yday then
			v.showDate = true
		else
			v.showDate = false
		end
	end

	self.logDatas = idlers.newWithMap(logs)
end

return GymLog
