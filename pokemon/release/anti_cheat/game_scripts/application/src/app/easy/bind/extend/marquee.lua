-- chunkname: @src.app.easy.bind.extend.marquee

local helper = require("easy.bind.helper")
local marquee = class("marquee", cc.load("mvc").ViewBase)

marquee.defaultProps = {}

local marqueeMessagesAlready = {}
local SORT = {}
local WAITTIME = {}

for k, v in csvPairs(csv.marquee) do
	SORT[v.key] = v.sortValue
	WAITTIME[v.key] = v.waitTime
end

function marquee:initExtend()
	self:initMode()
	self:removeAllChildren()

	local bg = ccui.ImageView:create("city/marquee/bg_1.png"):alignCenter(self:size()):addTo(self, 1, "bg")
	local voice = ccui.ImageView:create("city/marquee/icon_lb.png"):anchorPoint(0, 0.5):xy((self:width() - bg:width()) / 2 + 40, self:height() / 2):addTo(self, 2, "voice")
	local list = ccui.ListView:create():size(1100, 50):anchorPoint(0, 0.5):xy((self:width() - bg:width()) / 2 + 110, self:height() / 2):addTo(self, 3, "list")

	list:setScrollBarEnabled(false)
	list:setOpacity(0)

	local item = ccui.Layout:create():size(list:size()):anchorPoint(0, 1):addTo(list, 1)

	self.item = item
	self.isPlay = false

	helper.callOrWhen(self.marquee, function(data)
		self.marqueeMessages = {}
		self.index = 0

		table.sort(data, function(a, b)
			if SORT[a.args.key] ~= SORT[b.args.key] then
				return SORT[a.args.key] > SORT[b.args.key]
			end

			if a.time == b.time then
				return false
			end

			return a.time > b.time
		end)

		for id, msg in ipairs(data) do
			local isAlreadyPlay = false

			for k, v in ipairs(marqueeMessagesAlready) do
				if v.id == msg.id then
					isAlreadyPlay = true
				end
			end

			local isPlay = self.curMessage and msg.id == self.curMessage.id or false

			if not isAlreadyPlay and not isPlay then
				local isInTime = time.getTime() - msg.time < WAITTIME[msg.args.key] * 60

				if itertools.size(self.marqueeMessages) <= gCommonConfigCsv.marqueeMax and isInTime then
					table.insert(self.marqueeMessages, msg)
				else
					table.insert(marqueeMessagesAlready, msg)
				end
			end
		end

		if not self.isPlay then
			self:play()
		end
	end)

	return self
end

function marquee:initMode()
	self.marquee = gGameModel.messages:getIdler("marquee")
end

function marquee:play()
	local curMessage = self:getNextMessage()

	if curMessage then
		local isInTime = time.getTime() - curMessage.time < WAITTIME[curMessage.args.key] * 60

		if isInTime then
			self:show()
			self.item:removeAllChildren()

			local richText = rich.createByStr(curMessage.msg, 40)

			richText:anchorPoint(0, 0):xy(1100, 0):addTo(self.item, 999)
			richText:formatText()

			self.curMessage = curMessage
			self.isPlay = true

			local v = 160
			local pos1 = math.min(self.item:width() - richText:width(), 0)
			local pos2 = -richText:width()
			local t1 = (richText:x() - pos1) / v
			local t2 = 3
			local t3 = (pos1 - pos2) / v

			transition.executeSequence(richText, true):moveTo(t1, pos1):delay(t2):moveTo(t3, pos2):func(function()
				self:addToAlready(curMessage)

				self.curMessage = nil

				self:play()
			end):done()
		else
			self:addToAlready(curMessage)
			self:play()
		end
	else
		self.isPlay = false

		self:hide()
	end
end

function marquee:getNextMessage()
	self.index = self.index + 1

	local curMessage = self.marqueeMessages[self.index]

	if curMessage then
		return curMessage
	end

	return false
end

function marquee:addToAlready(msg)
	local isExist = false

	for k, v in pairs(marqueeMessagesAlready) do
		if v.id == msg.id then
			isExist = true
		end
	end

	if not isExist then
		table.insert(marqueeMessagesAlready, msg)
	end
end

return marquee
