local ObjectSimpleBuff = {}
local SimpleBuffModel = class("SimpleBuffModel")

function SimpleBuffModel:ctor(easyEffectFunc, holder, caster, buffValues)
	BuffModel.IDCounter = BuffModel.IDCounter + 1
	self.id = BuffModel.IDCounter
	self.scene = holder.scene
	self.cfgId = BuffModel.ObjectSimpleBuffBuffCfgID
	self.csvCfg = {
		easyEffectFunc = easyEffectFunc
	}
	self.caster = caster
	self.holder = holder
	self.isNumberType = false
	self.isOver = false
	self.buffEffectData = nil
	self.doEffectValue = buffValues
end

function SimpleBuffModel:overClean()
	if self.isOver then
		return
	end

	self.isOver = true

	self:doEffect(true)
	self.holder.simpleBuffs:erase(self.id)
end

function SimpleBuffModel:group()
	return BuffModel.ObjectSimpleBuffBuffGroup
end

function SimpleBuffModel:getValue()
	return self.doEffectValue
end

function SimpleBuffModel:doEffect(isOver)
	local f = ObjectSimpleBuff[self.csvCfg.easyEffectFunc]

	return f(self, self.doEffectValue, isOver)
end

function ObjectModel:addSimpleBuff(easyEffectFunc, caster, buffValues)
	local buff = SimpleBuffModel.new(easyEffectFunc, self, caster, buffValues)

	buff:doEffect(false)
	self.simpleBuffs:insert(buff.id, buff)
end

function ObjectModel:cleanSimpleBuff()
	for _, buff in self.simpleBuffs:order_pairs() do
		buff:overClean()
	end
end

function ObjectSimpleBuff.occupiedSeat(simpleBuff, args, isOver)
	local scene = simpleBuff.holder.scene
	local sceneBuffRecord = scene.recordBuffManager:getRecord(battle.OverlaySpecBuff.occupiedSeat)

	if not isOver then
		sceneBuffRecord:addSceneBuff(simpleBuff, args)
	else
		sceneBuffRecord:delSceneBuff(simpleBuff)
	end
end

function ObjectSimpleBuff.followObject(simpleBuff, args, isOver)
	local holder = simpleBuff.holder

	if not isOver then
		holder:addOverlaySpecBuff(simpleBuff, function(old)
			old.caster = simpleBuff.caster
		end)

		simpleBuff.caster.benchmarkObjId = simpleBuff.holder.id
	else
		holder:deleteOverlaySpecBuff(simpleBuff)
	end
end
