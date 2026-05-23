-- chunkname: @src.app.easy.bind.extend.explore_icon

local helper = require("easy.bind.helper")
local exploreByKey = class("exploreByKey", cc.load("mvc").ViewBase)

exploreByKey.defaultProps = {
	gemIconShow = false,
	longtouch = false
}

function exploreByKey:initExtend()
	if self.panel then
		self.panel:removeFromParent()
	end

	local panel = ccui.Layout:create():alignCenter(self:size()):addTo(self, 1, "_icon_")

	self.panel = panel

	panel:setAnchorPoint(cc.p(0.5, 0.5))
	helper.callOrWhen(self.data, function(data)
		local panel = self.panel
		local cfg = dataEasy.getCfgByKey(data.key)

		if not cfg then
			return
		end

		local id = dataEasy.stringMapingID(data.key)
		local path = dataEasy.getIconResByKey(id)
		local quality = cfg.quality
		local boxRes = string.format("city/card/helditem/panel_icon_%d.png", quality)

		if self.gemIconShow then
			boxRes = string.format("common/icon/panel_icon_%d.png", quality)
		end

		if not panel:get("box") then
			panel:removeAllChildren()

			local box = ccui.ImageView:create(boxRes)
			local size = box:size()

			box:alignCenter(size):addTo(panel, 1, "box")
			panel:size(size)
			ccui.ImageView:create():alignCenter(size):scale(2):addTo(panel, 2, "icon")
			ccui.ImageView:create("city/develop/explore/btn_js.png"):align(cc.p(0.5, 0.5), 150, self.panel:size().height - 32):addTo(panel, 13, "reduceIcon"):hide():setTouchEnabled(true)
		else
			panel:get("box"):texture(boxRes)
		end

		panel:get("icon"):texture(path)

		if self.showReduce and data.targetNum and data.targetNum > 0 then
			panel:get("reduceIcon"):show()
		else
			panel:get("reduceIcon"):hide()
		end

		self:setNum(data.num, data.targetNum, quality, data.noColor)
		panel:setTouchEnabled(true)

		if not self.longtouch then
			bind.click(self, panel, {
				method = function()
					local params = {
						key = data.key,
						num = data.num
					}

					gGameUI:showItemDetail(panel, params)
				end
			})
		end

		self:setEffect(cfg)
		self:setItemState(data)
	end)

	if self.onNode then
		self.onNode(panel)
	end

	return self
end

function exploreByKey:setEffect(cfg)
	local panel = self.panel
	local size = panel:size()

	helper.callOrWhen(self.effect, function(effect)
		local panel = self.panel

		panel:removeChildByName("effect")

		if effect and cfg.effect[effect] then
			widget.addAnimationByKey(panel, "effect/huanraoguang.skel", "effect", cfg.effect[effect], 5):xy(size.width / 2, size.height / 2)
		else
			local sprite = panel:getChildByName("effect")

			if sprite then
				sprite:removeFromParent()
			end
		end
	end)
end

function exploreByKey:setNum(num, targetNum, quality, noColor)
	local panel = self.panel
	local size = panel:size()
	local label = panel:get("num")
	local label1 = panel:get("num1")
	local label2 = panel:get("num2")

	if not targetNum then
		if not num or num == 0 then
			num = ""
		end

		local outlineSize = ui.DEFAULT_OUTLINE_SIZE

		if type(num) ~= "number" then
			num = gLanguageCsv[num] or num
			outlineSize = 3
		end

		if not label then
			label = cc.Label:createWithTTF(num, ui.FONT_PATH, 36):align(cc.p(1, 0), size.width - 30, 12):addTo(panel, 10, "num")

			text.addEffect(label, {
				outline = {
					color = ui.COLORS.QUALITY_OUTLINE[quality],
					size = outlineSize
				}
			})
		end

		label:show():text(mathEasy.getShortNumber(num))

		if label1 then
			itertools.invoke({
				label1,
				label2
			}, "hide")
		end
	else
		num = num or 0

		if not label1 then
			label1 = cc.Label:createWithTTF(0, ui.FONT_PATH, 30):align(cc.p(1, 0), size.width - 20, 10):addTo(panel, 10, "num1")

			text.addEffect(label1, {
				outline = {
					color = ui.COLORS.QUALITY_OUTLINE[quality]
				}
			})

			label2 = cc.Label:createWithTTF(0, ui.FONT_PATH, 30):align(cc.p(1, 0), size.width - 30, 10):addTo(panel, 10, "num2")

			text.addEffect(label2, {
				outline = {
					color = ui.COLORS.OUTLINE.DEFAULT
				},
				color = cc.c4b(255, 225, 76, 255)
			})
		end

		label2:show():text(mathEasy.getShortNumber(targetNum))
		label1:show():text("/" .. mathEasy.getShortNumber(num))
		adapt.oneLinePos(label1, label2, nil, "right")

		if label then
			label:hide()
		end
	end
end

function exploreByKey:setItemState(data)
	local panel = self.panel

	panel:removeChildByName("maxLimit")
	helper.callOrWhen(self.specialKey, function(specialKey)
		local panel = self.panel
		local size = panel:size()

		panel:removeChildByName("heldItemLv")

		if specialKey.lv then
			local lv = cc.Label:createWithTTF(gLanguageCsv.textLv2 .. specialKey.lv, ui.FONT_PATH, 26):align(cc.p(0, 0.5), 16, 65):addTo(panel, 6, "heldItemLv")

			text.addEffect(lv, {
				outline = {
					color = ui.COLORS.NORMAL.DEFAULT
				}
			})
		end

		panel:removeChildByName("levelBg")
		panel:removeChildByName("level")

		if specialKey.leftTopLv then
			local level = cc.Label:createWithTTF(gLanguageCsv.textLv .. specialKey.leftTopLv, ui.FONT_PATH, 30):align(cc.p(0, 1), size.width * 0.06 + 10, size.height * 0.95 - 10):addTo(panel, 101, "level")

			text.addEffect(level, {
				color = ui.COLORS.NORMAL.WHITE,
				outline = {
					color = ui.COLORS.NORMAL.DEFAULT
				}
			})
		end

		panel:removeChildByName("maxLimit")

		if specialKey.maxLimit then
			local key = data.key
			local cfg = dataEasy.getCfgByKey(key)
			local flag = true

			if game.ITEM_STRING_ENUM_TABLE[key] or game.ITEM_EXP_HASH[key] then
				flag = false
			elseif csv.items[key] and csv.items[key].type == game.ITEM_TYPE_ENUM_TABLE.roleDisplayType then
				flag = false
			end

			if flag and cfg.stackMax and cfg.stackMax > 3 and dataEasy.getNumByKey(key) >= cfg.stackMax then
				ccui.ImageView:create("common/txt/icon_ysx.png"):anchorPoint(cc.p(1, 1)):scale(0.9):xy(size.width + 8, size.height):addTo(panel, 102, "maxLimit")
			end
		end
	end)
end

return exploreByKey
