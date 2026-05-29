-- chunkname: @cocos.framework.extends.NodeEx

local Node = cc.Node

function Node:add(child, zorder, tag)
	if tag then
		self:addChild(child, zorder, tag)
	elseif zorder then
		self:addChild(child, zorder)
	else
		self:addChild(child)
	end

	return self
end

function Node:addTo(parent, zorder, tag)
	if tag then
		parent:addChild(self, zorder, tag)
	elseif zorder then
		parent:addChild(self, zorder)
	else
		parent:addChild(self)
	end

	return self
end

function Node:removeSelf()
	if self.isExiting_ then
		return self
	end

	self:removeFromParent()

	return self
end

function Node:align(anchorPoint, x, y)
	self:setAnchorPoint(anchorPoint)

	if x == nil then
		return self
	end

	return self:move(x, y)
end

function Node:show()
	self:setVisible(true)

	return self
end

function Node:hide()
	self:setVisible(false)

	return self
end

function Node:move(x, y)
	if y then
		self:setPosition(x, y)
	else
		self:setPosition(x)
	end

	return self
end

function Node:moveTo(args)
	transition.moveTo(self, args)

	return self
end

function Node:moveBy(args)
	transition.moveBy(self, args)

	return self
end

function Node:fadeIn(args)
	transition.fadeIn(self, args)

	return self
end

function Node:fadeOut(args)
	transition.fadeOut(self, args)

	return self
end

function Node:fadeTo(args)
	transition.fadeTo(self, args)

	return self
end

function Node:rotate(rotation)
	self:setRotation(rotation)

	return self
end

function Node:rotateTo(args)
	transition.rotateTo(self, args)

	return self
end

function Node:rotateBy(args)
	transition.rotateBy(self, args)

	return self
end

function Node:scaleTo(args)
	transition.scaleTo(self, args)

	return self
end

function Node:scheduleUpdate(callback)
	self:scheduleUpdateWithPriorityLua(callback, 0)

	return self
end

function Node:onNodeEvent(eventName, callback)
	local new

	if eventName == "enter" then
		new = callbacks.new(self.onEnter, callback)
		self.onEnter = new
	elseif eventName == "exit" then
		new = callbacks.new(self.onExit, callback)
		self.onExit = new
	elseif eventName == "enterTransitionFinish" then
		new = callbacks.new(self.onEnterTransitionFinish, callback)
		self.onEnterTransitionFinish = new
	elseif eventName == "exitTransitionStart" then
		new = callbacks.new(self.onExitTransitionStart, callback)
		self.onExitTransitionStart = new
	elseif eventName == "cleanup" then
		new = callbacks.new(self.onCleanup, callback)
		self.onCleanup = new
	end

	self:enableNodeEvents()

	return new
end

function Node:enableNodeEvents()
	if self.isNodeEventEnabled_ then
		return self
	end

	self:registerScriptHandler(function(state)
		if state == "enter" then
			return self:onEnter()
		elseif state == "exit" then
			self.isExiting_ = true

			return self:onExit()
		elseif state == "enterTransitionFinish" then
			return self:onEnterTransitionFinish()
		elseif state == "exitTransitionStart" then
			return self:onExitTransitionStart()
		elseif state == "cleanup" then
			return self:onCleanup()
		end
	end)

	self.isNodeEventEnabled_ = true

	return self
end

function Node:disableNodeEvents()
	self:unregisterScriptHandler()

	self.isNodeEventEnabled_ = false

	return self
end

function Node:onEnter()
	self.isExiting_ = false
end

function Node:onExit()
	return
end

function Node:onEnterTransitionFinish()
	return
end

function Node:onExitTransitionStart()
	self.isExiting_ = true
end

function Node:onCleanup()
	return
end
