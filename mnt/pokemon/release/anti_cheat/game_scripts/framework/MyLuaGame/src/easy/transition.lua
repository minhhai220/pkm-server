-- chunkname: @src.easy.transition

local insert = table.insert
local remove = table.remove
local transition = transition

local function cacheReturnCall(methods, target)
	local rets = {}

	return setmetatable({}, {
		__index = function(t, k)
			local f = methods[k]

			if f == nil then
				return
			end

			return function(t, ...)
				local ret, handle = f(rets, target, ...)

				if handle then
					return handle(t)
				end

				insert(rets, ret)

				return t
			end
		end,
		__call = function(t, ret)
			insert(rets, ret)
		end
	})
end

local function runCall(methods, target)
	return setmetatable({}, {
		__index = function(t, k)
			local f = methods[k]

			if f == nil then
				return
			end

			return function(t, ...)
				local ret, handle = f(nil, target, ...)

				if handle then
					return handle(t)
				end

				target:runAction(ret)

				return t
			end
		end,
		__call = function(t, ret)
			target:runAction(ret)
		end
	})
end

local chainTransition = {}

function chainTransition:delay(target, t)
	return cc.DelayTime:create(t)
end

function chainTransition:moveTo(target, t, x, y)
	x = x or target:getPositionX()
	y = y or target:getPositionY()

	return cc.MoveTo:create(t, cc.p(x, y))
end

function chainTransition:moveBy(target, t, x, y)
	x = x or 0
	y = y or 0

	return cc.MoveBy:create(t, cc.p(x, y))
end

function chainTransition:fadeIn(target, t)
	return cc.FadeIn:create(t)
end

function chainTransition:fadeOut(target, t)
	return cc.FadeOut:create(t)
end

function chainTransition:fadeTo(target, t, opacity)
	opacity = checkint(opacity)

	if opacity < 0 then
		opacity = 0
	elseif opacity > 255 then
		opacity = 255
	end

	return cc.FadeTo:create(t, opacity)
end

function chainTransition:scaleBy(target, t, scale, scaleY)
	if scaleY then
		scale = scale or target:getScaleX()

		return cc.ScaleBy:create(t, scale, scaleY)
	end

	return cc.ScaleBy:create(t, scale)
end

function chainTransition:scaleTo(target, t, scale, scaleY)
	if scaleY then
		scale = scale or target:getScaleX()

		return cc.ScaleTo:create(t, scale, scaleY)
	end

	return cc.ScaleTo:create(t, scale)
end

function chainTransition:scaleXTo(target, t, scaleX)
	return cc.ScaleTo:create(t, scaleX, target:getScaleY())
end

function chainTransition:scaleYTo(target, t, scaleY)
	return cc.ScaleTo:create(t, target:getScaleX(), scaleY)
end

function chainTransition:rotateTo(target, t, rotation)
	rotation = rotation or target:getRotation()

	return cc.RotateTo:create(t, rotation)
end

function chainTransition:rotateBy(target, t, rotation)
	rotation = rotation or 0

	return cc.RotateBy:create(t, rotation)
end

function chainTransition:progressTo(target, t, percent)
	return cc.ProgressTo:create(t, percent)
end

function chainTransition:tintTo(target, t, color)
	color = color or cc.c3b(1, 255, 255)

	return cc.TintTo:create(t, color.r, color.g, color.b)
end

function chainTransition:func(target, f)
	return cc.CallFunc:create(f)
end

function chainTransition:place(target, x, y)
	x = x or target:getPositionX()
	y = y or target:getPositionY()

	return cc.Place:create(cc.p(x, y))
end

function chainTransition:remove(target)
	return cc.RemoveSelf:create()
end

function chainTransition:show(target)
	return cc.Show:create()
end

function chainTransition:hide(target)
	return cc.Hide:create()
end

function chainTransition:toggle(target)
	return cc.ToggleVisibility:create()
end

function chainTransition:action(target, action)
	return action
end

function chainTransition:easeBegin(target, easingName, more)
	local ret = cacheReturnCall(chainTransition, target)

	ret.__ease = {
		easingName,
		more
	}

	return nil, function(t)
		ret.__parent = t

		return ret
	end
end

function chainTransition:easeEnd(target)
	return nil, function(t)
		local easeAction = transition.newEasing(transition.sequence(self), unpack(t.__ease))

		t.__parent(easeAction)

		return t.__parent
	end
end

local sequenceMethods, parallelMethods, spawnMethods

function chainTransition:sequenceBegin(target)
	local ret = cacheReturnCall(sequenceMethods, nil)

	return nil, function(t)
		ret.__parent = t

		return ret
	end
end

function chainTransition:sequenceEnd(target)
	return nil, function(t)
		t.__parent(t:done())

		return t.__parent
	end
end

function chainTransition:spawnBegin(target)
	local ret = cacheReturnCall(spawnMethods, nil)

	return nil, function(t)
		ret.__parent = t

		return ret
	end
end

function chainTransition:spawnEnd(target)
	return nil, function(t)
		t.__parent(t:done())

		return t.__parent
	end
end

sequenceMethods = clone(chainTransition)
parallelMethods = clone(chainTransition)
spawnMethods = clone(chainTransition)

function transition.speed(target, args)
	assert(not tolua.isnull(target), "transition.speed() - target is not cc.Node")

	local speed = args.speed or 1
	local speedAction = cc.Speed:create(args.action, speed)

	return target:runAction(speedAction)
end

function transition.follow(target, args)
	assert(not tolua.isnull(target), "transition.follow() - target is not cc.Node")
	assert(not tolua.isnull(args.node), "transition.follow() - target is not cc.Node")

	local action = cc.Follow:create(target, node, args.rect)

	return target:runAction(action)
end

function sequenceMethods:done(target)
	return nil, function(t)
		if target == nil then
			return transition.sequence(self)
		end

		return target:runAction(transition.sequence(self))
	end
end

function transition.executeSequence(target, stopPrev)
	assert(not tolua.isnull(table.getraw(target)), "transition.executeSequence() - target is not cc.Node")

	if stopPrev then
		target:stopAllActions()
	end

	return cacheReturnCall(sequenceMethods, target)
end

function transition.sequenceEx()
	return cacheReturnCall(sequenceMethods, nil)
end

function transition.executeParallel(target, stopPrev)
	assert(not tolua.isnull(target), "transition.executeParallel() - target is not cc.Node")

	if stopPrev then
		target:stopAllActions()
	end

	return runCall(parallelMethods, target)
end

function spawnMethods:done(target)
	return nil, function(t)
		if target == nil then
			return transition.spawn(self)
		end

		return target:runAction(transition.spawn(self))
	end
end

function transition.executeSpawn(target, stopPrev)
	assert(not tolua.isnull(target), "transition.executeParallel() - target is not cc.Node")

	if stopPrev then
		target:stopAllActions()
	end

	return cacheReturnCall(spawnMethods, target)
end

function transition.spawnEx()
	return cacheReturnCall(spawnMethods, nil)
end

function transition.tintTo(target, t, color)
	assert(not tolua.isnull(target), "transition.tintTo() - target is not cc.Node")

	color = color or cc.c3b(255, 255, 255)
	t = t or 0.3

	local tinttoAction = cc.TintTo:create(t, color.r, color.g, color.b)

	return target:runAction(tinttoAction)
end
