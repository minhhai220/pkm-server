local helper = require("battle.models.buff.helper")
local BuffEffectFuncTb = BuffModel.BuffEffectFuncTb

function BuffEffectFuncTb.replaceBuffHolder(buff, args, isOver)
	local scene = buff.holder.scene
	local sceneBuffRecord = scene.recordBuffManager:getRecord("replaceBuffHolder")

	if not isOver then
		sceneBuffRecord:addSceneBuff(buff, args)
	else
		sceneBuffRecord:delSceneBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.aura(buff, args, isOver)
	local holder = buff.holder
	local auraBuffRecord = holder.scene.recordBuffManager:getRecord("aura")

	if not isOver then
		auraBuffRecord:addSceneBuff(buff, args)
	else
		auraBuffRecord:delSceneBuff(buff)
	end

	return true
end
