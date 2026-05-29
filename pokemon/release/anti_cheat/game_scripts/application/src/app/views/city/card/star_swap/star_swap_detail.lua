-- chunkname: @src.app.views.city.card.star_swap.star_swap_detail

local StarSwapDetailView = class("StarSwapDetailView", cc.load("mvc").ViewBase)

StarSwapDetailView.RESOURCE_FILENAME = "star_swap_info.json"
StarSwapDetailView.RESOURCE_BINDING = {
	sevenPanel = "sevenPanel",
	["sevenPanel.bg"] = "bg"
}

function StarSwapDetailView:onCreate(key)
	local str = string.format(gLanguageCsv.starSwapNoUseTip, dataEasy.getCfgByKey(key).name, dataEasy.getNumByKey(key))
	local richText = rich.createWithWidth(str, 34, nil, 430):anchorPoint(0.5, 0.5):addTo(self.sevenPanel):xy(260, 100)

	self.bg:height(richText:height() + 50)
end

return StarSwapDetailView
