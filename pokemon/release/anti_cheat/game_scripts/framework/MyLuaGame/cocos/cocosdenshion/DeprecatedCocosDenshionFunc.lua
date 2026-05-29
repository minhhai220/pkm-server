-- chunkname: @cocos.cocosdenshion.DeprecatedCocosDenshionFunc

if cc.SimpleAudioEngine == nil then
	return
end

local function deprecatedTip(old_name, new_name)
	return
end

local SimpleAudioEngineDeprecated = {}

function SimpleAudioEngineDeprecated.sharedEngine()
	deprecatedTip("SimpleAudioEngine:sharedEngine", "SimpleAudioEngine:getInstance")

	return cc.SimpleAudioEngine:getInstance()
end

SimpleAudioEngine.sharedEngine = SimpleAudioEngineDeprecated.sharedEngine

function SimpleAudioEngineDeprecated:playBackgroundMusic(...)
	deprecatedTip("SimpleAudioEngine:playBackgroundMusic", "SimpleAudioEngine:playMusic")

	return self:playMusic(...)
end

SimpleAudioEngine.playBackgroundMusic = SimpleAudioEngineDeprecated.playBackgroundMusic
