-- chunkname: @cocos.cocos2d.luaArkTs

local luaArkTs = {}
local callArkTsStaticMethod = LuaArkTSBridge.callStaticMethod

function luaArkTs.callStaticMethod(className, methodName, args)
	local ok, ret = callArkTsStaticMethod(className, methodName, args)

	if not ok then
		print("callArkTsStaticMethod error")
	end

	return ok, ret
end

return luaArkTs
