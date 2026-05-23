-- chunkname: @src.app.views.city.adventure.clone_battle.history

local ViewBase = cc.load("mvc").ViewBase
local HistoryView = class("HistoryView", Dialog)

HistoryView.RESOURCE_FILENAME = "clone_battle_history.json"
HistoryView.RESOURCE_BINDING = {
	["showPanel.item"] = "item",
	title = "title",
	["showPanel.list"] = "list",
	allPanel = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	}
}

local TIP = {
	gLanguageCsv.cloneBattleRecord1,
	gLanguageCsv.cloneBattleRecord2,
	gLanguageCsv.cloneBattleRecord3,
	gLanguageCsv.cloneBattleRecord4,
	gLanguageCsv.cloneBattleRecord5,
	gLanguageCsv.cloneBattleRecord6,
	gLanguageCsv.cloneBattleRecord7
}

function HistoryView:onCreate(parms)
	Dialog.onCreate(self)
	self.list:setScrollBarEnabled(false)
	self.list:setItemsMargin(0)

	local history = parms.historyTab or {}

	self.refreshNumber = parms.refreshNumber

	gGameModel.forever_dispatch:getIdlerOrigin("cloneBattleLookHistory"):set(#history)

	local dateRecord = {}

	for i, v in ipairs(history) do
		local t = time.getDate(v.time)
		local str = string.formatex(gLanguageCsv.timeMonthDay, {
			month = t.month,
			day = t.day
		})

		dateRecord[str] = dateRecord[str] or {}

		table.insert(dateRecord[str], v)
	end

	for date, data in pairs(dateRecord) do
		local item = self.item:clone()
		local richText = rich.createByStr("#Pfont/youmi1.ttf##C0x5B545B#" .. date, 40):addTo(item):anchorPoint(0, 0.5):xy(10, 32):height(45)

		self.list:pushBackCustomItem(item)

		local str1 = ""

		for i, v in ipairs(data) do
			local item = self.item:clone()
			local t = time.getDate(v.time)
			local time = "#C0xB2ABB2##Pfont/youmi1.ttf#" .. string.format("%02d:%02d", t.hour, t.min)
			local str = string.formatex("#C0x5B545B#" .. TIP[v.type], {
				name = "#C0x5FC355#" .. v.name .. "#C0x5B545B#"
			})
			local richTime = rich.createByStr(time, 40):addTo(item):anchorPoint(0, 1):xy(160, 32)
			local richText = rich.createWithWidth(str, 40, nil, 730):addTo(item):anchorPoint(0, 1):xy(280, 32)
			local height = richText:height()

			item:height(height)
			richTime:xy(160, height)
			richText:xy(280, height)
			self.list:pushBackCustomItem(item)
		end
	end

	self.list:jumpToBottom()
end

return HistoryView
