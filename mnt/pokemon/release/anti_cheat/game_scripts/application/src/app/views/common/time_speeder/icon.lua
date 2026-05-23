-- chunkname: @src.app.views.common.time_speeder.icon

local TimeSpeederIcon = class("TimeSpeederIcon", cc.load("mvc").ViewBase)

TimeSpeederIcon.RESOURCE_FILENAME = "common_time_speeder_icon.json"
TimeSpeederIcon.RESOURCE_BINDING = {
	icon = "icon"
}

function TimeSpeederIcon:onCreate()
	self:enableSchedule()
	self.icon:onTouch(functools.partial(self.iconTouch, self))
	performWithDelay(self, function()
		local defaultPos = {
			x = display.sizeInViewRect.width * 2 / 5,
			y = display.sizeInViewRect.height * 3 / 5
		}
		local pos = userDefault.getForeverLocalKey("timeSpeederPos", defaultPos, {
			rawKey = true
		})
		local edgePos = self:getEdgePos(pos)

		self.icon:xy(edgePos)
	end, 0)
end

function TimeSpeederIcon:iconTouch(event)
	if event.name == "began" then
		self.touchBeganPos = event
		self.isMoved = false

		self.icon:scale(1.2)
		self.icon:xy(event)
		self:stopAllActions()
		self.icon:stopAllActions()
		self.icon:unscheduleUpdate()
	elseif event.name == "moved" then
		self.icon:scale(1.2)

		if event.x < display.sizeInViewRect.x then
			event.x = display.sizeInViewRect.x
		elseif event.x > display.sizeInViewRect.x + display.sizeInViewRect.width then
			event.x = display.sizeInViewRect.x + display.sizeInViewRect.width
		end

		if event.y < display.sizeInViewRect.y then
			event.y = display.sizeInViewRect.y
		elseif event.y > display.sizeInViewRect.y + display.sizeInViewRect.height then
			event.y = display.sizeInViewRect.y + display.sizeInViewRect.height
		end

		local deltaX = math.abs(event.x - self.touchBeganPos.x)
		local deltaY = math.abs(event.y - self.touchBeganPos.y)

		if deltaX > ui.TOUCH_MOVED_THRESHOLD or deltaY > ui.TOUCH_MOVED_THRESHOLD then
			self.isMoved = true
		end

		self.icon:xy(event)
	elseif event.name == "ended" or event.name == "cancelled" then
		self.touchEndTime = socket.gettime()

		self.icon:scheduleUpdate(function(dt)
			if socket.gettime() - self.touchEndTime >= 2 then
				self:iconMoveToEdge(event)

				return false
			end
		end)

		if event.name == "ended" and not self.isMoved then
			self:showTimeSpeeder()
		end
	end
end

function TimeSpeederIcon:getEdgePos(pos)
	local posT = {
		{
			l = pos.x - display.sizeInViewRect.x,
			pos = {
				x = display.sizeInViewRect.x,
				y = pos.y
			},
			prePos = {
				x = display.sizeInViewRect.x + 300,
				y = pos.y
			}
		},
		{
			l = display.sizeInViewRect.x + display.sizeInViewRect.width - pos.x,
			pos = {
				x = display.sizeInViewRect.x + display.sizeInViewRect.width,
				y = pos.y
			},
			prePos = {
				x = display.sizeInViewRect.x + display.sizeInViewRect.width - 300,
				y = pos.y
			}
		},
		{
			l = pos.y - display.sizeInViewRect.y,
			pos = {
				x = pos.x,
				y = display.sizeInViewRect.y
			},
			prePos = {
				x = pos.x,
				y = display.sizeInViewRect.y + 200
			}
		},
		{
			l = display.sizeInViewRect.y + display.sizeInViewRect.height - pos.y,
			pos = {
				x = pos.x,
				y = display.sizeInViewRect.y + display.sizeInViewRect.height
			},
			prePos = {
				x = pos.x,
				y = display.sizeInViewRect.y + display.sizeInViewRect.height - 200
			}
		}
	}
	local posIndex = 1

	for i, v in ipairs(posT) do
		if v.l < posT[posIndex].l then
			posIndex = i
		end
	end

	return posT[posIndex].pos, posT[posIndex].prePos
end

function TimeSpeederIcon:iconMoveToEdge(pos)
	self:stopAllActions()
	self.icon:stopAllActions()
	self.icon:unscheduleUpdate()

	local edgePos = self:getEdgePos(pos)
	local actionx = cc.EaseSineInOut:create(cc.MoveTo:create(0.3 * gGameUI:getTimeScale(true), edgePos))

	self.icon:runAction(actionx)
	self.icon:scale(1)
	userDefault.setForeverLocalKey("timeSpeederPos", {
		x = edgePos.x,
		y = edgePos.y
	}, {
		rawKey = true
	})
end

function TimeSpeederIcon:showAni()
	self:stopAllActions()
	self.icon:stopAllActions()
	self.icon:unscheduleUpdate()

	local pos, prePos = self:getEdgePos(cc.p(self.icon:xy()))

	self.icon:xy(prePos):show()
	performWithDelay(self, function()
		self:iconMoveToEdge(pos)
	end, 1 * gGameUI:getTimeScale(true))
end

function TimeSpeederIcon:showTimeSpeeder()
	if gGameUI.timeSpeederManager.isYield() then
		gGameUI:showTip(gLanguageCsv.speedUpForbidden)

		return
	end

	gGameUI:showTimeSpeeder()
end

return TimeSpeederIcon
