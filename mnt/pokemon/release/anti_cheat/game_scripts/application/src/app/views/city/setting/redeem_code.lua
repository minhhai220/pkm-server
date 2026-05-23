-- chunkname: @src.app.views.city.setting.redeem_code

local SettingRedeemCodeView = class("SettingRedeemCodeView", Dialog)

SettingRedeemCodeView.RESOURCE_FILENAME = "setting_redeem_code.json"
SettingRedeemCodeView.RESOURCE_BINDING = {
	textField = "textField",
	btnClose = {
		varname = "btnClose",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	},
	btnCancel = {
		varname = "btnCancel",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onCancelBtn")
			}
		}
	},
	btnComfirm = {
		varname = "btnComfirm",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onConfirmBtn")
			}
		}
	}
}

local function isNumber(num)
	return num >= 48 and num <= 57
end

local function isUpper(num)
	return num >= 65 and num <= 90
end

local function isLower(num)
	return num >= 97 and num <= 122
end

local function limitLanguageWord(str)
	local flag = false
	local idx = 1

	while idx <= #str do
		local curByte = string.byte(str, idx)
		local num = string.utf8charlen(curByte)
		local character = ""

		for i = 1, num do
			character = character .. string.format("%x", string.byte(str, idx + i - 1, idx + i - 1))
		end

		local number = tonumber(character, 16)
		local valid = isNumber(number) or isUpper(number) or isLower(number)

		if not valid then
			return true, {
				idx
			}
		end

		idx = idx + num
	end

	return false
end

local function removeOtherFromString(str)
	local repStr = ""
	local flag, t = limitLanguageWord(str)

	if flag then
		table.sort(t, function(a, b)
			return b < a
		end)

		for _, v in ipairs(t) do
			local len = string.utf8charlen(string.byte(str, v))

			str = string.sub(str, 1, v - 1) .. repStr .. string.sub(str, v + len)
		end
	end

	return str
end

function SettingRedeemCodeView:onCreate()
	local input = self.textField

	input:addEventListener(function(sender, eventType)
		if eventType == ccui.TextFiledEventType.insert_text then
			input:setText(removeOtherFromString(input:text()))
		end
	end)
	self.textField:setPlaceHolderColor(ui.COLORS.DISABLED.GRAY)
	self.textField:setTextColor(ui.COLORS.NORMAL.DEFAULT)
	self.textField:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
	Dialog.onCreate(self, {
		clickClose = false
	})
end

function SettingRedeemCodeView:onConfirmBtn()
	local str = self.textField:getStringValue()

	gGameApp:requestServer("/game/gift", function(tb)
		sdk.trackEvent("redeem_code")
		gGameUI:showGainDisplay(tb.view.award)
	end, str)
end

function SettingRedeemCodeView:onCancelBtn()
	self:onClose()
end

return SettingRedeemCodeView
