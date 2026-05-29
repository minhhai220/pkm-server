-- chunkname: @cocos.cocosbuilder.DeprecatedCocosBuilderClass

if cc.CCBProxy == nil then
	return
end

DeprecatedCocosBuilderClass = {} or DeprecatedCocosBuilderClass

local function deprecatedTip(old_name, new_name)
	return
end

function DeprecatedCocosBuilderClass.CCBReader()
	deprecatedTip("CCBReader", "cc.BReader")

	return cc.BReader
end

_G.CCBReader = DeprecatedCocosBuilderClass.CCBReader()

function DeprecatedCocosBuilderClass.CCBAnimationManager()
	deprecatedTip("CCBAnimationManager", "cc.BAnimationManager")

	return cc.BAnimationManager
end

_G.CCBAnimationManager = DeprecatedCocosBuilderClass.CCBAnimationManager()

function DeprecatedCocosBuilderClass.CCBProxy()
	deprecatedTip("CCBProxy", "cc.CCBProxy")

	return cc.CCBProxy
end

_G.CCBProxy = DeprecatedCocosBuilderClass.CCBProxy()
