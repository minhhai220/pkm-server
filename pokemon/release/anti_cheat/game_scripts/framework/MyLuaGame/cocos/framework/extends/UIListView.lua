-- chunkname: @cocos.framework.extends.UIListView

local ListView = ccui.ListView

function ListView:onEvent(callback)
	if callback == nil then
		return self:disableEventListener()
	end

	self:addEventListener(function(sender, eventType)
		local event = {
			target = sender,
			type = eventType
		}

		if eventType == 0 then
			event.name = "ON_SELECTED_ITEM_START"
		else
			event.name = "ON_SELECTED_ITEM_END"
		end

		callback(event)
	end)

	return self
end

function ListView:onScroll(callback)
	if callback == nil then
		return self:disableScrollViewEventListener()
	end

	self:addScrollViewEventListener(function(sender, eventType)
		if self.isExiting_ then
			return
		end

		local event = {
			target = sender,
			type = eventType
		}

		if eventType == 0 then
			event.name = "SCROLL_TO_TOP"
		elseif eventType == 1 then
			event.name = "SCROLL_TO_BOTTOM"
		elseif eventType == 2 then
			event.name = "SCROLL_TO_LEFT"
		elseif eventType == 3 then
			event.name = "SCROLL_TO_RIGHT"
		elseif eventType == 4 then
			event.name = "SCROLLING"
		elseif eventType == 5 then
			event.name = "BOUNCE_TOP"
		elseif eventType == 6 then
			event.name = "BOUNCE_BOTTOM"
		elseif eventType == 7 then
			event.name = "BOUNCE_LEFT"
		elseif eventType == 8 then
			event.name = "BOUNCE_RIGHT"
		elseif eventType == 9 then
			event.name = "CONTAINER_MOVED"
		elseif eventType == 10 then
			event.name = "SCROLLING_BEGAN"
		elseif eventType == 11 then
			event.name = "SCROLLING_ENDED"
		elseif eventType == 12 then
			event.name = "AUTOSCROLL_BEGAN"
		elseif eventType == 13 then
			event.name = "AUTOSCROLL_ENDED"
		end

		callback(event)
	end)

	return self
end
