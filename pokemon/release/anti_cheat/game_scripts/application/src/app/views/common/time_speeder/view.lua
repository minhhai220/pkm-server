-- chunkname: @src.app.views.common.time_speeder.view

local TimeSpeederView = class("TimeSpeederView", Dialog)

TimeSpeederView.RESOURCE_FILENAME = "common_time_speeder.json"
TimeSpeederView.RESOURCE_BINDING = {
	combTipPos = "combTipPos",
	barPanel = "barPanel",
	["barPanel.bar"] = "slider",
	textTip = "textTip",
	note = "needNumNote",
	closeBtn = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	},
	btnRule = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onRule")
			}
		}
	},
	["barPanel.current"] = {
		varname = "currentText",
		binds = {
			event = "text",
			idler = bindHelper.self("current"),
			method = function(val)
				return "x" .. val
			end
		}
	},
	["barPanel.subBtn"] = {
		varname = "subBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -1)
			end)
		}
	},
	["barPanel.addBtn"] = {
		varname = "addBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 1)
			end)
		}
	},
	sureBtn = {
		varname = "sureBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onEnbaleClick")
			}
		}
	}
}

function TimeSpeederView:onCreate(selectDbId)
	self:enableSchedule()

	self.max = 10

	local speed = userDefault.getForeverLocalKey("timeSpeederViewSpeeed", 1)

	speed = cc.clampf(speed, 1, self.max)
	self.current = idler.new(speed)
	self.enabled = idler.new(gGameUI.timeSpeederManager.getTimeSpeedEnabled())

	self.textTip:text(string.format(gLanguageCsv.speedText, self.max))
	idlereasy.when(self.current, function(_, current)
		current = cc.clampf(current, 1, self.max)

		cache.setShader(self.subBtn, false, current > 1 and "normal" or "hsl_gray")
		cache.setShader(self.addBtn, false, current < self.max and "normal" or "hsl_gray")
		gGameUI.timeSpeederManager.setTimeSpeed(current)
	end)
	idlereasy.when(self.enabled, function(_, enabled)
		userDefault.setForeverLocalKey("timeSpeederViewEnabled", enabled)
		gGameUI.timeSpeederManager.setTimeSpeedEnabled(enabled)

		if enabled then
			self.sureBtn:loadTextureNormal("city/setting/btn_bf.png")
		else
			self.sureBtn:loadTextureNormal("city/setting/btn_zt.png")
		end
	end)
	Dialog.onCreate(self)
end

function TimeSpeederView:getMaxSpeed()
	local vipLv = gGameModel.role:read("vip_level")
	local level = gGameModel.role:read("level")
	local lvAdd = 0
	local vipAdd = 0

	for k, v in orderCsvPairs(csv.time_speeder) do
		if v.type == 1 and level >= v.arg then
			lvAdd = math.max(lvAdd, v.speedAdd)
		end

		if v.type == 2 and vipLv >= v.arg then
			vipAdd = math.max(vipAdd, v.speedAdd)
		end
	end

	return lvAdd + vipAdd + 1
end

function TimeSpeederView:onEnbaleClick()
	self.enabled:set(not self.enabled:read())
end

function TimeSpeederView:onChangeNum(node, event, step)
	if event.name == "click" then
		self:unscheduleUpdate()
		self:onIncreaseNum(step)
	elseif event.name == "began" then
		local time1 = socket.gettime()

		self:onIncreaseNum(step)
		self:scheduleUpdate(function()
			if socket.gettime() - time1 > 0.1 then
				self:onIncreaseNum(step)

				time1 = socket.gettime()
			end
		end)
	elseif event.name == "ended" or event.name == "cancelled" then
		self:unscheduleUpdate()
	end
end

function TimeSpeederView:onIncreaseNum(step)
	self.current:modify(function(selectNum)
		return true, cc.clampf(selectNum + step, 1, self.max)
	end)
end

function TimeSpeederView:onClose(step)
	userDefault.setForeverLocalKey("timeSpeederViewSpeeed", self.current:read())
	Dialog.onClose(self)
end

function TimeSpeederView:onRule()
	gGameUI:createView("common.rule", gGameUI.timeSpeederLayer):init(self:createHandler("getRuleContext"))
end

function TimeSpeederView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.noteText(166),
		c.noteText(135401, 135450)
	}

	for k, v in orderCsvPairs(csv.time_speeder) do
		table.insert(context, string.format(gLanguageCsv["speederRule" .. v.type], v.arg, v.speedAdd))
	end

	return context
end

return TimeSpeederView
