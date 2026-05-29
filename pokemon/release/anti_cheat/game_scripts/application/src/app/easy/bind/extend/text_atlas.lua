-- chunkname: @src.app.easy.bind.extend.text_atlas

local helper = require("easy.bind.helper")
local textAtlasHelper = require("app.easy.bind.helper.text_atlas")
local textAtlas = class("textAtlas", cc.load("mvc").ViewBase)

textAtlas.defaultProps = {
	isEqualDist = false,
	align = "left"
}

function textAtlas:initExtend()
	if not tolua.isnull(self.panel) then
		self.panel:removeFromParent()
	end

	local panel = ccui.Layout:create():setTouchEnabled(false):addTo(self, 1, "_textAtlas_")

	self.panel = panel

	local anchorPoint = cc.p(0.5, 0.5)

	if self.align == "left" then
		anchorPoint.x = 0
	elseif self.align == "right" then
		anchorPoint.x = 1
	end

	panel:align(anchorPoint)

	local datas = textAtlasHelper.findFileInfoByPathName(self.pathName)

	if not datas then
		return
	end

	local width = datas.width
	local interval = datas.interval or 0
	local height = datas.height
	local rect = datas.rect or {}
	local changeText = datas.changeText or ""
	local path = string.format("font/digital_%s.png", self.pathName)
	local changeT = {}

	for i = 1, string.len(changeText) do
		local char = string.sub(changeText, i, i)

		changeT[char] = string.char(57 + i)
	end

	helper.callOrWhen(self.data, function(data)
		self.panel:removeAllChildren()

		local panel = self.panel

		data = tostring(data)

		if self.isEqualDist then
			local dataT = {}

			for i = 1, string.len(data) do
				local char = string.sub(data, i, i)

				table.insert(dataT, changeT[char] or char)
			end

			data = table.concat(dataT, "")

			local label = cc.LabelAtlas:_create(data, path, width, height, string.byte("0")):addTo(panel)

			panel:size(label:size())
		else
			local textWidth = 0

			for i = 1, string.len(data) do
				local char = string.sub(data, i, i)
				local changeChar = changeT[char] or char
				local number = tonumber(char)
				local idx = number and number + 1 or string.byte(changeChar) - string.byte(9) + 10
				local w = rect[char] or width
				local distance = math.max(width - w, 0)
				local label = cc.Sprite:create(path):setTextureRect(cc.rect((idx - 1) * width + distance / 2, 0, w, height)):align(cc.p(0, 0.5)):xy(cc.p(textWidth + interval / 2, height / 2)):addTo(panel):z(-textWidth)

				textWidth = textWidth + w + interval / 2
			end

			panel:size(cc.size(textWidth, height))
		end

		if self.onNode then
			self.onNode(panel)
		end
	end)

	return self
end

return textAtlas
