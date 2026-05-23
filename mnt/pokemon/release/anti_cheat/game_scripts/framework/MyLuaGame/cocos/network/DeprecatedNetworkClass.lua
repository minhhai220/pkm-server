-- chunkname: @cocos.network.DeprecatedNetworkClass

if cc.XMLHttpRequest == nil then
	return
end

DeprecatedNetworkClass = {} or DeprecatedNetworkClass

local function deprecatedTip(old_name, new_name)
	return
end

function DeprecatedNetworkClass.WebSocket()
	deprecatedTip("WebSocket", "cc.WebSocket")

	return cc.WebSocket
end

_G.WebSocket = DeprecatedNetworkClass.WebSocket()
