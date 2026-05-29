-- chunkname: @src.app.easy.bind.extend.card_level

local helper = require("easy.bind.helper")
local cardLevel = class("cardLevel", cc.load("mvc").ViewBase)

cardLevel.defaultProps = {}

function cardLevel:initExtend()
	local panel = ccui.Layout:create():size(150, 60):align(cc.p(0, 1)):addTo(self)
	local labelLv = panel:get("txtLv")
	local isCn = matchLanguage({
		"cn"
	})

	if not labelLv then
		labelLv = cc.Label:createWithTTF(gLanguageCsv.textLv1, ui.FONT_PATH, isCn and 30 or 24):align(cc.p(1, 0), isCn and 90 or 75, 55):addTo(panel, 2, "txtLv")

		text.addEffect(labelLv, {
			outline = {
				color = ui.COLORS.OUTLINE.DEFAULT
			}
		})
	end

	local txtLvNum = panel:get("txtLvNum")

	if not txtLvNum then
		txtLvNum = cc.Label:createWithTTF("", ui.FONT_PATH, 30):align(cc.p(1, 0), isCn and 75 or 90, 55):addTo(panel, 2, "txtLvNum")

		text.addEffect(txtLvNum, {
			outline = {
				color = ui.COLORS.OUTLINE.DEFAULT
			}
		})
	end

	helper.callOrWhen(self.data, function(data)
		if not data then
			panel:hide()

			return
		end

		panel:show()
		panel:get("txtLvNum"):show():text(data)

		if isCn then
			adapt.oneLinePos(labelLv, txtLvNum, cc.p(5, labelLv:y() - txtLvNum:y()), "right")
		else
			adapt.oneLinePos(txtLvNum, labelLv, cc.p(5, 0), "right")
		end
	end)

	if self.onNode then
		self.onNode(panel)
	end

	return self
end

return cardLevel
