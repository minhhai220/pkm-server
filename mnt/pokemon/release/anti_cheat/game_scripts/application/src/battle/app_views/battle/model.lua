-- chunkname: @src.battle.app_views.battle.model

require("battle.models.include")

local BattleModel = class("BattleModel")

function BattleModel:ctor()
	self.scene = nil
	self.updateFrame = nil
	self.updateDelta = nil
	self.battleData = nil
	self.battleSceneID = nil
	self.modelEnable = true
	self.modelPause = false
end

function BattleModel:init()
	cow.battleModelInit()
end

function BattleModel:cleanUp()
	self.scene = nil
	self.battleData = nil
	self.battleSceneID = nil
	self.updateFrame = nil
	self.updateDelta = nil

	cow.battleModelDestroy()
	BattleAssert.clear()
end

function BattleModel:reset(data, sceneID, isRecord)
	self:cleanUp()
	cow.battleModelInit()

	self.scene = cow.proxyObject("scene", SceneModel.new())
	self.updateDelta = 0
	self.updateFrame = 0
	self.modelPause = false
	self.modelEnable = true
	self.battleData = data
	self.battleSceneID = sceneID
	self.battleIsRecord = isRecord
end

function BattleModel:onInitInUpdate()
	local data, sceneID, isRecord = self.battleData, self.battleSceneID, self.battleIsRecord

	self.battleData = nil
	self.battleSceneID = nil
	self.battleIsRecord = nil

	local title = string.format("\n\n\t\tbattle %s start - seed=%s, scene=%s\n\n", isRecord and "record" or "", data.randSeed, sceneID)

	printInfo(title)
	log.battle(title)
	ymrand.randomseed(data.randSeed)

	ymrand.randCount = 0

	self.scene:init(sceneID, data, isRecord)
end

function BattleModel:update(delta)
	if not self.modelEnable or self.modelPause then
		return
	end

	if self.scene.isBattleAllEnd then
		return
	end

	self.updateDelta = self.updateDelta + delta
	self.updateFrame = self.updateFrame + 1

	if self.updateFrame == 1 then
		self:onInitInUpdate()
	end

	if self.updateFrame <= 5 then
		return
	end

	local frametick = game.FRAME_TICK

	if frametick > self.updateDelta then
		return
	end

	local frames = math.floor(self.updateDelta / frametick)

	for i = 1, frames do
		if not self.modelEnable or self.modelPause then
			break
		end

		self.scene:update(frametick)

		self.updateDelta = self.updateDelta - frametick
	end
end

function BattleModel:setModelEnable(v)
	self.modelEnable = v
end

function BattleModel:runUntilEnd()
	self.modelPause = false
	self.modelEnable = true

	ViewProxy.allModelOnly()
	gRootViewProxy:raw():enableQuickPass(self.scene)
	self.scene:setAutoFight(true)

	while true do
		if self.scene.isBattleAllEnd then
			break
		end

		self:update(game.FRAME_TICK)
	end

	self.modelEnable = false
end

function BattleModel:runUnitlNextWave()
	self.modelPause = false
	self.modelEnable = true
	self.updateDelta = 0

	ViewProxy.allModelOnly()

	local isAuto = self.scene.autoFight

	self.scene:setAutoFight(true)
	gRootViewProxy:raw():enableQuickPassOneWave(self.scene)

	while true do
		if self.scene.isBattleAllEnd then
			self.modelEnable = false

			break
		end

		if self.scene.play:isMultWaveEnd() then
			self.scene:setAutoFight(isAuto)
			ViewProxy.allModelResum()

			break
		end

		self:update(game.FRAME_TICK)
	end
end

local operators = {
	[battle.OperateTable.skill] = function(self, seat)
		if self.scene.gateType == game.GATE_TYPE.arena then
			return
		end

		local hero = self.scene.heros:find(seat)

		if hero and hero:isCanHandSkill() and not self.scene.inMainSkill then
			hero:handSkill()
		end
	end,
	[battle.OperateTable.attack] = function(self, seat, skillID)
		self.scene.play:setAttack(seat, skillID)
	end,
	[battle.OperateTable.noAttack] = function(self)
		self.scene:setNoAttackFlag()
	end,
	[battle.OperateTable.autoFight] = function(self, flag)
		self.scene:setAutoFight(flag)
	end,
	[battle.OperateTable.pass] = function(self, fromEditor)
		self:runUntilEnd()
	end,
	[battle.OperateTable.passOneWave] = function(self)
		self.scene.play:onPassOneMultWave(function()
			self:runUnitlNextWave()
		end)
	end,
	[battle.OperateTable.fullManual] = function(self)
		self.scene:setFullManual(self.battleData.moduleType == 2)
	end
}

function BattleModel:handleOperation(_type, ...)
	if self.scene == nil then
		return
	end

	local f = operators[_type]

	if f then
		return f(self, ...)
	end
end

return BattleModel
