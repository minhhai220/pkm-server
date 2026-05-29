local SpriteController = {}

globals.SpriteController = SpriteController

local function emptyFunc()
	return
end

local function isSpriteExist(obj)
	local view = gRootViewProxy:call("getSceneObj", tostring(obj))

	if view then
		return true, view
	end

	return false, nil
end

local mt = {
	__newindex = function(t, k, v)
		if type(v) == "function" then
			local function actualFunc(obj, ...)
				local exist, sprite = isSpriteExist(obj)

				if exist then
					return v(sprite, ...)
				else
					return emptyFunc
				end
			end

			rawset(t, k, actualFunc)
		else
			error("can't set value to SpriteController")
		end
	end
}

setmetatable(SpriteController, mt)

function SpriteController.createCallFunc(sprite, funcName, ...)
	return functools.partial(SpriteController[funcName], sprite.key, ...)
end

function SpriteController.forceSetVisible(sprite, visible)
	sprite:setVisibleEnable(visible)
	sprite:setVisible(visible)
end
