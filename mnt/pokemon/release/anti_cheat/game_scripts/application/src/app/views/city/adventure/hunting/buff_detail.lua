-- chunkname: @src.app.views.city.adventure.hunting.buff_detail

local HuntingBuffDetailView = class("HuntingBuffDetailView", cc.load("mvc").ViewBase)

HuntingBuffDetailView.RESOURCE_FILENAME = "hunting_buff_detail.json"
HuntingBuffDetailView.RESOURCE_BINDING = {
	["baseNode.title"] = "title",
	baseNode = "baseNode"
}

function HuntingBuffDetailView:onCreate(data)
	self.title:text(data.name)

	local richtext = rich.createWithWidth("#C0x5B545B#" .. data.desc, 40, nil, 600):anchorPoint(0.5, 1):addTo(self.baseNode, 10, "textNum")

	self.baseNode:height(richtext:height() + 150)
	self.title:y(richtext:height() + 90)
	richtext:xy(self.baseNode:width() / 2, richtext:height() + 50)
end

return HuntingBuffDetailView
