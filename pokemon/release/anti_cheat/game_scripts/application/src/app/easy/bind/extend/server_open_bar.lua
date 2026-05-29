-- chunkname: @src.app.easy.bind.extend.server_open_bar

local listview = require("easy.bind.extend.listview")
local inject = require("easy.bind.extend.inject")
local helper = require("easy.bind.helper")
local awardRes = {
	"activity/server_open/award/icon_jnh1",
	"activity/server_open/award/icon_jnh2",
	"activity/server_open/award/icon_jnh3",
	"activity/server_open/award/icon_jnh4"
}
local progressBar = class("progressBar", cc.load("mvc").ViewBase)
local bar = {}

bar.RESOURCE_FILENAME = "common_server_open_bar.json"
bar.RESOURCE_BINDING = {
	["barPanel.curPanel"] = "curPanel",
	barPanel = "barPanel",
	awardPanel = "awardPanel"
}
progressBar.defaultProps = {
	showAward = false
}

function progressBar:initExtend()
	self.showCur = self.showCur or idler.new(self.showCur)

	local node = gGameUI:createSimpleView(bar, self):init()

	self.node = node

	self.node.barPanel:get("text"):text(gLanguageCsv.carnivalTargetCollectText)
	idlereasy.when(self.showCur, function(obj, cur)
		self:initBarPanel()

		if self.showAward then
			self:updateAwardPanel()
		end

		if not cur then
			self.node.curPanel:hide()

			return
		end

		self.node.curPanel:show()

		local nowIdx = math.min(cur, 100)

		for idx = 0, nowIdx do
			local bar = self.bar[idx]

			if bar then
				bar:get("img"):show()
			end
		end

		local x = 0

		if nowIdx > 0 and self.bar[nowIdx] then
			x = self.bar[nowIdx]:x() + self.bar[nowIdx]:width() / 2
		end

		self.node.barPanel:get("curPanel"):x(x)
		self.node.barPanel:get("curPanel.txt"):text(nowIdx)
	end)

	if self.showAward then
		self:updateAwardPanel()
	end

	if self.onNode then
		self.onNode(node)
	end

	return self
end

function progressBar:initBarPanel()
	self.bar = {}
	self.prograssData = {}
	self.award = {}

	local barPanel = self.node.barPanel
	local x = 0

	if not barPanel then
		return
	end

	for i = 1, itertools.size(self.data) do
		local bar

		if self.data[i].award then
			if i == itertools.size(self.data) then
				bar = barPanel:get("panel4"):clone():show():addTo(barPanel, 5, "bar" .. i):xy(x, barPanel:height() / 2)
			else
				bar = barPanel:get("panel3"):clone():show():addTo(barPanel, 5, "bar" .. i):xy(x, barPanel:height() / 2)
			end

			bar:get("txt"):text(self.data[i].target)

			self.award[i] = self.data[i]
		elseif i == 1 then
			bar = barPanel:get("panel1"):clone():show():addTo(barPanel, 5, "bar" .. i):xy(x, barPanel:height() / 2)
		elseif i == itertools.size(self.data) then
			bar = barPanel:get("panel1"):clone():show():addTo(barPanel, 5, "bar" .. i):xy(x + barPanel:get("panel1"):width(), barPanel:height() / 2):scale(-1, 1)
		else
			bar = barPanel:get("panel2"):clone():show():addTo(barPanel, 5, "bar" .. i):xy(x, barPanel:height() / 2)
		end

		if bar then
			self.prograssData[i] = {
				x = x,
				width = bar:width(),
				idx = i
			}
			x = x + bar:width()
			self.bar[i] = bar
		end
	end

	itertools.invoke({
		barPanel:get("panel1"),
		barPanel:get("panel2"),
		barPanel:get("panel3"),
		barPanel:get("panel4")
	}, "hide")
end

function progressBar:updateAwardPanel()
	local award = self.node.awardPanel

	if not award then
		return
	end

	for idx, val in pairs(self.award) do
		if self.node.barPanel:get("award" .. idx) then
			self.node.barPanel:removeChildByName("award" .. idx)
		end

		local icon = award:clone():show():addTo(self.node.barPanel, 5, "award" .. idx):xy(self.node.barPanel:get("bar" .. idx):x() + self.node.barPanel:get("bar" .. idx):width() / 2, self.node.barPanel:get("bar" .. idx):y() + award:height() / 2 + 30)

		icon:get("icon"):texture(string.format("%s%s.png", awardRes[math.min(#awardRes, val.count)], val.got and "_1" or ""))
		icon:get("img"):visible(not val.got and idx <= self.showCur:read())
		bind.touch(self, icon, {
			methods = {
				ended = function()
					self:onItemClick(icon, idx)
				end
			}
		})
	end

	award:hide()
end

function progressBar:onItemClick(node, idx)
	if self.btnClick then
		self.btnClick(node, idx)
	end
end

return progressBar
