-- chunkname: @cocos.cocosdenshion.DeprecatedCocosDenshionClass

if cc.SimpleAudioEngine == nil then
	return
end

DeprecatedCocosDenshionClass = {} or DeprecatedCocosDenshionClass

local function deprecatedTip(old_name, new_name)
	return
end

function DeprecatedCocosDenshionClass.SimpleAudioEngine()
	deprecatedTip("SimpleAudioEngine", "cc.SimpleAudioEngine")

	return cc.SimpleAudioEngine
end

_G.SimpleAudioEngine = DeprecatedCocosDenshionClass.SimpleAudioEngine()
