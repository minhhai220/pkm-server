-- chunkname: @src.app.easy.bind.extend.cutdown_label

local helper = require("easy.bind.helper")
local cutDownLabel = class("cutDownLabel", cc.load("mvc").ViewBase)

cutDownLabel.defaultProps = {
	dt = 1,
	delay = 0,
	str_key = "str"
}

function cutDownLabel:initExtend()
	if self.fontSize then
		self:setFontSize(self.fontSize)
	end

	if self.textColor then
		self:setTextColor(self.textColor)
	end

	self:enableSchedule()

	if self.onNode then
		self.onNode(self)
	end

	if self:setLabel(0) ~= false then
		self:schedule(function(dt)
			return self:setLabel(dt)
		end, self.dt, self.dt + self.delay, self.tag)
	end
end

function cutDownLabel:setLabel(dt)
	local t = 0

	if self.time then
		self.time = self.time - dt
		t = self.time
	elseif self.endTime then
		t = self.endTime - time.getTime()
	end

	t = math.max(t, 0)

	local timeTbl = time.getCutDown(t)

	if self.strFunc then
		self:text(self.strFunc(timeTbl))
	else
		self:text(timeTbl[self.str_key])
	end

	if t <= 0 then
		if self.endFunc then
			self.endFunc()
		end

		return false
	end

	if self.callFunc then
		local ret = self.callFunc(timeTbl)

		if ret == false then
			return false
		end
	end
end

return cutDownLabel
