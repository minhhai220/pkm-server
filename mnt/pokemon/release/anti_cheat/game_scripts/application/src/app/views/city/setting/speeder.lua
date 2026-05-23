-- chunkname: @src.app.views.city.setting.speeder

local SettingView = require("app.views.city.setting.view")
local BTN_TYPE = SettingView.BTN_TYPE
local BTN_DATA = SettingView.BTN_DATA

local function setBtnState(btn, btnType, state)
	local t = BTN_DATA[btnType]

	if btnType == BTN_TYPE.BTN then
		btn:texture(state and t.resNormal or t.resSelected)

		local img = btn:get("btnImg")

		if state then
			img:xy(30, 30)
		else
			img:xy(100, 30)
		end
	elseif btnType == BTN_TYPE.RADIO then
		btn:get("btnImg"):visible(state)
	end
end

local ViewBase = cc.load("mvc").ViewBase
local TimeSpeederView = class("TimeSpeederView", ViewBase)

TimeSpeederView.RESOURCE_FILENAME = "setting_speeder.json"
TimeSpeederView.RESOURCE_BINDING = {
	["centerPanel.btn"] = {
		varname = "btn",
		binds = {
			event = "click",
			method = bindHelper.self("btnClick")
		}
	}
}

function TimeSpeederView:onCreate()
	self.hide = userDefault.getForeverLocalKey("timeSpeederIconHide", false)

	setBtnState(self.btn, BTN_TYPE.BTN, self.hide)
end

function TimeSpeederView:btnClick()
	self.hide = not self.hide

	userDefault.setForeverLocalKey("timeSpeederIconHide", self.hide)
	setBtnState(self.btn, BTN_TYPE.BTN, self.hide)
	gGameUI.timeSpeederLayer:setVisible(not self.hide)

	if not self.hide then
		gGameUI.timeSpeederIconView:showAni()
	end
end

return TimeSpeederView
