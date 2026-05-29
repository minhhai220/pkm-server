-- chunkname: @cocos.framework.extends.SpriteEx

local Sprite = cc.Sprite

function Sprite:playAnimationOnce(animation, args)
	local actions = {}
	local showDelay = args.showDelay

	if showDelay then
		self:setVisible(false)

		actions[#actions + 1] = cc.DelayTime:create(showDelay)
		actions[#actions + 1] = cc.Show:create()
	end

	local delay = args.delay or 0

	if delay > 0 then
		actions[#actions + 1] = cc.DelayTime:create(delay)
	end

	actions[#actions + 1] = cc.Animate:create(animation)

	if args.removeSelf then
		actions[#actions + 1] = cc.RemoveSelf:create()
	end

	if args.onComplete then
		actions[#actions + 1] = cc.CallFunc:create(args.onComplete)
	end

	local action

	if #actions > 1 then
		action = cc.Sequence:create(actions)
	else
		action = actions[1]
	end

	self:runAction(action)

	return action
end

function Sprite:playAnimationForever(animation)
	local animate = cc.Animate:create(animation)
	local action = cc.RepeatForever:create(animate)

	self:runAction(action)

	return action
end

function Sprite:onClick(cb)
	local function began()
		return true
	end

	local function ended(touch, event)
		local sender = event:getCurrentTarget()

		if cb then
			cb(sender, touch)
		end
	end

	local listener = cc.EventListenerTouchOneByOne:create()

	listener:setSwallowTouches(true)
	listener:registerScriptHandler(began, cc.Handler.EVENT_TOUCH_BEGAN)
	listener:registerScriptHandler(ended, cc.Handler.EVENT_TOUCH_ENDED)

	local eventDispatcher = self:getEventDispatcher()

	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end
