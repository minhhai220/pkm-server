-- chunkname: @src.battle.app_views.battle.view

require("battle.app_views.battle.stage")
require("battle.app_views.battle.module.include")
require("battle.views.sprite")
require("battle.views.sprite_possess")
require("battle.views.sprite_follower")
require("battle.views.sprite_aid")
require("battle.views.event_effect.include")

local FPSCheckMax = 5
local ViewBase = cc.load("mvc").ViewBase

globals.BattleView = class("BattleView", ViewBase)

local BattleModel = require("battle.app_views.battle.model")
local battleUIWidget = {}


battleUIWidget.RESOURCE_FILENAME = "battle.json"
battleUIWidget.RESOURCE_BINDING = {
	feedbackPanel = "feedbackPanel",
	rightGroupPanel = "rightGroupPanel",
	leftGroupPanel = "leftGroupPanel",
	bottomRightPanel = "bottomRightPanel",
	bottomLeftPanel = "bottomLeftPanel",
	midPanel = "midPanel",
	topRightPanel = "topRightPanel",
	topLeftPanel = "topLeftPanel",
	midTopPanel = "midTopPanel",
	["topLeftPanel.leftAidPanel"] = "leftAidPanel",
	["topRightPanel.rightAidPanel"] = "rightAidPanel",
	["topLeftPanel.infoPVP.line"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = cc.c4b(92, 84, 92, 255)
				}
			}
		}
	},
	["topRightPanel.infoPVP.line"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = cc.c4b(92, 84, 92, 255)
				}
			}
		}
	}
}

local function initBuffEffectsMap()
	return {
		normal = {},
		forceSelf = {},
		forceEnemy = {},
		toHide = {}
	}
end

local gateEndStyles = {
	clickClose = true
}

function BattleView:onCreate(data, sceneID, modes, entrance)
	self._model = nil
	self._scene = nil
	self._play = nil
	self.modelWaitType = nil
	self.stage = nil
	self.stageLayer = nil
	self.effectLayerLower = nil
	self.gameLayer = nil
	self.effectLayer = nil
	self.effectLayerNum = nil
	self.frontStageLayer = nil
	self.weatherLayer = nil
	self.layer = nil
	self.sceneID = nil
	self.isGuideScene = nil
	self.gateType = nil
	self.tick = 0
	self.deathCache = {}
	self.modes = modes or clone(battle.DefaultModes)
	self.timeScale = battle.SpeedTimeScale.single
	self.brawlTimeScale = 1
	self.ultAccEnable = false
	self.inUltAcc = false
	self.effectManager = cow.proxyObject("effectManager", battleEffect.Manager.new("BattleView"))
	self.effectResManager = EffectResManager.new(nil, self)
	self.guideManager = require("battle.app_views.battle.guide").new(self)
	self.subModuleNotify = cow.proxyObject("subModuleNotify", battleModule.CNotify.new(self))
	self.effectDebug = {}
	self.buffEffectsCache = initBuffEffectsMap()
	self.deferList = {}
	self.deferListMap = CVector.new()
	self.curDeferList = nil
	self.filterMap = {}
	self.effectJumpCache = {}
	self.effectEventEnable = true

	self:initBattle(data, sceneID, self.modes.isRecord)

	self.modelPauseTimer = {}
	self.onceEffectWaitCount = 0
	self.queueCallBack = {}
	self.entrance = entrance
	self.DEBUG_BATTLE_HIDE = false
	self.fpsSum = 0
	self.fpsCount = 0
	self.lastLowFPSCount = 0
	self.fpsMax = userDefault.getForeverLocalKey("fps", 60, {
		rawKey = true
	})

	if self.fpsMax > 30 then
		-- block empty
	end
end

function BattleView:onClose()
	self:cleanUp()

	self._model = nil
	self._scene = nil
	self._play = nil

	battleComponents.clearAll()

	if self.guideManager:isInGuiding() then
		self.guideManager:onClose()
	end

	gGameUI:removeAllDelayTouchDispatch()
	cache.onBattleClear(self.sceneID == 1)
	cache.texturePreload("common_ui")
	battleEntrance.unloadConfig()
	ViewBase.onClose(self)
	display.director:resume()
	display.director:getScheduler():setTimeScale(1)

	local fps = userDefault.getForeverLocalKey("fps", 60, {
		rawKey = true
	})

	display.director:setAnimationInterval(1 / fps)

	if display.director.isSpineThreadDrawEnabled then
		display.director:setSpineThreadDrawEnabled(false)
	end
end

function BattleView:cleanUp()
	if self._model then
		self._model:cleanUp()
	end
end

function BattleView:reset()
	self:cleanUp()

	self._model = BattleModel.new()
	self._scene = nil
	self._play = nil
	self.tick = 0
end

function BattleView:initBattle(data, sceneID, isRecord)
	self:reset()

	self.data = data
	self.sceneID = sceneID or data.sceneID
	self.gateType = data.gateType or csv.scene_conf[sceneID].gateType

	self:add(self:createLayerStage()):add(self:createLayerBelowGameLayer()):add(self:createLayerGame()):add(self:createLayerUpGameLayer()):add(self:createLayerEffect()):add(self:createWeatherLayer()):add(self:createUILayer()):add(self:createEffectLayerNum()):add(self:createBuffPanelLayer()):add(self:createFrontLayerStage()):add(self:createDeleteObjLayer())
	self.UIWidget.midTopPanel:release()
	self.subModuleNotify:init()
	self:showMainUI(false)

	self.deferListMap = CVector.new()
	self.curDeferList = nil
	
	self:pushDeferList()
	self:initStage()
	self._model:reset(data, sceneID, isRecord)
	self:onViewProxyNotify("initBattle")

	self.timeScale = battle.SpeedTimeScale.single

	display.director:resume()
	display.director:getScheduler():setTimeScale(self.timeScale)

	if display.director.isSpineThreadDrawEnabled then
		display.director:setSpineThreadDrawEnabled(false)
	end

	if display.director.getSpineThreadDrawVersion then
		display.director:setSpineThreadDrawEnabled(true)
	end

	collectgarbage("stop")
end

local gateStageFuncs = {
	[game.GATE_TYPE.test] = function(self)
		return gMonsterCsv[self.sceneID][1].bkCsv
	end,
	[game.GATE_TYPE.randomTower] = function(self)
		local room_info = self.data.gamemodel_data and self.data.gamemodel_data.room_info
		local enemyId = room_info and room_info.enemy[room_info.board_id].id or 1001
		local csvCfg = csv.random_tower.monsters[enemyId]

		return csvCfg.backGround
	end,
	[game.GATE_TYPE.hellRandomTower] = function(self)
		local enemyId = self.data.monsters_csv_id or 1001
		local csvCfg = csv.hell_random_tower.monsters[enemyId]

		return csvCfg.backGround
	end,
	[game.GATE_TYPE.braveChallenge] = function(self)
		local csvCfg = csv.brave_challenge.floor[self.data.floorID]

		return csvCfg.scene
	end,
	[game.GATE_TYPE.hunting] = function(self)
		local gateID = self.data.gateID
		local csvCfg = csv.cross.hunting.gate[gateID]

		return csvCfg.backGround
	end,
	[game.GATE_TYPE.summerChallenge] = function(self)
		local gateID = self.data.gateID
		local csvCfg = csv.summer_challenge.gates[gateID]

		return csvCfg.scene
	end,
	[game.GATE_TYPE.crossCircus] = function(self)
		local themeID = self.data.themeID
		local csvCfg = csv.cross.circus.theme[themeID]

		return csvCfg.scene
	end
}

function BattleView:initStage()
	local getStageCfg = gateStageFuncs[self.gateType] or gateStageFuncs[game.GATE_TYPE.test]

	if self.modes.fromRecordFile then
		getStageCfg = gateStageFuncs[game.GATE_TYPE.test]
	end

	self.stage = CStageModel.new(self)

	self.stage:init(getStageCfg(self))
end

function BattleView:createLayerStage()
	local layer = cc.Layer:create()

	layer:name("stageLayer")

	self.stageLayer = layer

	return layer
end

function BattleView:createFrontLayerStage()
	local layer = cc.Layer:create()

	layer:name("frontStageLayer")

	self.frontStageLayer = layer

	return layer
end

function BattleView:createDeleteObjLayer()
	local layer = cc.Layer:create()

	layer:name("deleteObjLayer"):setVisible(false)

	self.deleteObjLayer = layer

	return layer
end

function BattleView:createLayerBelowGameLayer()
	local layer = cc.Layer:create()

	layer:name("effectLayerLower")

	self.effectLayerLower = layer

	return layer
end

function BattleView:createLayerGame()
	local layer = cc.Layer:create()

	layer:name("gameLayer")
	layer:setPosition(cc.p(0, display.fightLower))

	self.gameLayer = layer

	return layer
end

function BattleView:createLayerUpGameLayer()
	local layer = cc.Layer:create()

	layer:name("effectLayerUpper")

	self.effectLayerUpper = layer

	return layer
end

function BattleView:createLayerEffect()
	local layer = cc.Layer:create()

	layer:name("effectLayer")
	layer:setPosition(cc.p(0, display.fightLower))

	self.effectLayer = layer

	return layer
end

function BattleView:createWeatherLayer()
	local layer = cc.Layer:create()

	layer:name("weatherLayer")

	self.weatherLayer = layer

	return layer
end

function BattleView:createEffectLayerNum()
	local layer = cc.Layer:create()

	layer:name("effectLayerNum")
	layer:setPosition(cc.p(0, display.fightLower))

	self.effectLayerNum = layer

	return layer
end

function BattleView:createBuffPanelLayer()
	self.UIWidget.midTopPanel:retain()
	self.UIWidget.midTopPanel:removeFromParent()
	self.UIWidget.midTopPanel:xy(display.width / 2, display.height / 2)

	return self.UIWidget.midTopPanel
end

function BattleView:createUILayer()
	self.layer = cc.Layer:create()

	self.layer:name("UILayer")

	self.UIWidget = gGameUI:createSimpleView(battleUIWidget, self.layer):init(self)
	self.UIWidgetLeft = self.UIWidget.topLeftPanel
	self.UIWidgetRight = self.UIWidget.topRightPanel
	self.UIWidgetMid = self.UIWidget.midPanel
	self.UIWidgetBottomLeft = self.UIWidget.bottomLeftPanel
	self.UIWidgetBottomRight = self.UIWidget.bottomRightPanel
	self.UIWidgetFeedback = self.UIWidget.feedbackPanel
	self.UIWidgetGroupLeft = self.UIWidgetLeft:get("infoTeam")
	self.UIWidgetGroupRight = self.UIWidgetRight:get("infoTeam")
	self.UIWidgetLeftAid = self.UIWidget.leftAidPanel
	self.UIWidgetRightAid = self.UIWidget.rightAidPanel

	self.UIWidgetMid:get("widgetPanel.speedRank"):setVisible(false)
	self.UIWidgetBottomRight:setVisible(false)

	if self:isPVEScene() then
		self.UIWidgetLeft:get("infoPVP"):setVisible(false)
		self.UIWidgetRight:get("infoPVP"):setVisible(false)
	elseif self:isPVPScene() then
		self.UIWidgetMid:get("widgetPanel.wavePanel"):setVisible(false)

		if self:isSepcPVPScene() then
			self.UIWidgetLeft:get("infoPVP"):setVisible(false)
			self.UIWidgetRight:get("infoPVP"):setVisible(false)
		end
	end

	if self.gateType == game.GATE_TYPE.dailyGold or self.gateType == game.GATE_TYPE.dailyExp or self.gateType == game.GATE_TYPE.gym and self:getDeployType() == game.DEPLOY_TYPE.OneByOneType then
		self.UIWidgetMid:get("widgetPanel.wavePanel"):setVisible(false)
	end

	self.objAttrPanel = gGameUI:createView("battle.attr_panel", self.layer):init(self)

	self.objAttrPanel:hide():z(999)

	return self.layer
end

function BattleView:showMainUI(isShow)
	self.UIWidget:setVisible(isShow)
end

function BattleView:clearDeleteObjLayer()
	self.deleteObjLayer:removeAllChildren()
end

function BattleView:showSpeedRank(isShow)
	self.UIWidgetMid:get("widgetPanel.speedRank"):setVisible(isShow)
end

local pveScenes = {
	[game.GATE_TYPE.normal] = true,
	[game.GATE_TYPE.dailyGold] = true,
	[game.GATE_TYPE.dailyExp] = true,
	[game.GATE_TYPE.unionFuben] = true,
	[game.GATE_TYPE.endlessTower] = true,
	[game.GATE_TYPE.gift] = true,
	[game.GATE_TYPE.fragment] = true,
	[game.GATE_TYPE.simpleActivity] = true,
	[game.GATE_TYPE.dailyContract] = true,
	[game.GATE_TYPE.friendFight] = true,
	[game.GATE_TYPE.randomTower] = true,
	[game.GATE_TYPE.hellRandomTower] = true,
	[game.GATE_TYPE.clone] = true,
	[game.GATE_TYPE.worldBoss] = true,
	[game.GATE_TYPE.huoDongBoss] = true,
	[game.GATE_TYPE.gym] = true,
	[game.GATE_TYPE.crossMineBoss] = true,
	[game.GATE_TYPE.braveChallenge] = true,
	[game.GATE_TYPE.hunting] = true,
	[game.GATE_TYPE.summerChallenge] = true,
	[game.GATE_TYPE.mimicry] = true,
	[game.GATE_TYPE.experience] = true,
	[game.GATE_TYPE.abyssEndlessTower] = true
}

function BattleView:isPVEScene()
	return pveScenes[self.gateType]
end

local bossScenes = {
	[game.GATE_TYPE.dailyGold] = true,
	[game.GATE_TYPE.worldBoss] = true,
	[game.GATE_TYPE.unionFuben] = true,
	[game.GATE_TYPE.mimicry] = true
}

function BattleView:isBossScene()
	return bossScenes[self.gateType]
end

local pvpScenes = {
	[game.GATE_TYPE.newbie] = true,
	[game.GATE_TYPE.test] = true,
	[game.GATE_TYPE.arena] = true,
	[game.GATE_TYPE.crossArena] = true,
	[game.GATE_TYPE.unionFight] = true,
	[game.GATE_TYPE.crossUnionFight] = true,
	[game.GATE_TYPE.crossOnlineFight] = true,
	[game.GATE_TYPE.gymLeader] = true,
	[game.GATE_TYPE.crossGym] = true,
	[game.GATE_TYPE.crossMine] = true,
	[game.GATE_TYPE.crossSupremacy] = true,
	[game.GATE_TYPE.battlebet] = true,
	[game.GATE_TYPE.contestbet] = true,
	[game.GATE_TYPE.bondEvolution] = true,
	[game.GATE_TYPE.crossUnionAdventure] = true,
	[game.GATE_TYPE.crossCircus] = true
}

function BattleView:isPVPScene()
	return pvpScenes[self.gateType] or self:isSepcPVPScene()
end

local specPVPScenes = {
	[game.GATE_TYPE.craft] = true,
	[game.GATE_TYPE.crossCraft] = true
}

function BattleView:isSepcPVPScene()
	if self.gateType == game.GATE_TYPE.crossUnionFight then
		return self.data.battleType == 3
	end

	return specPVPScenes[self.gateType]
end

local multiOneByOneScenes = {
	[game.GATE_TYPE.crossMine] = true,
	[game.GATE_TYPE.crossSupremacy] = true
}

function BattleView:isMultiOneByOneScenes()
	if self.gateType == game.GATE_TYPE.crossArena then
		return false
	end

	if self.data.multipGroup then
		if self.gateType == game.GATE_TYPE.crossCircus then
			return self:getDeployType() == game.DEPLOY_TYPE.MultTwo or self:getDeployType() == game.DEPLOY_TYPE.MultThree
		end

		if self.gateType == game.GATE_TYPE.gym then
			return self:getDeployType() ~= game.DEPLOY_TYPE.WheelType
		end

		return true
	end

	return multiOneByOneScenes[self.gateType]
end

function BattleView:onModelWait(type)
	log.battle.battleView.wait(type)

	self.modelWaitType = type

	self._model:setModelEnable(false)

	self.modelPauseTimer[1] = os.clock()
end

function BattleView:onModelResume()
	self.modelWaitType = nil

	self._model:setModelEnable(true)

	self.modelPauseTimer = {}
end

function BattleView:onCheckFPS()
	local fps = 1 / display.director:getSecondsPerFrame()

	self.fpsSum = self.fpsSum + fps
	self.fpsCount = self.fpsCount + 1

	if self.fpsCount >= FPSCheckMax then
		local avg = self.fpsSum / self.fpsCount

		self.fpsCount = 0
		self.fpsSum = 0
		fps = 60

		if avg < 30 and self.lastLowFPSCount < 3 then
			fps = 40
			self.lastLowFPSCount = self.lastLowFPSCount + 1
		else
			self.lastLowFPSCount = 0
		end

		display.director:setAnimationInterval(1 / math.min(fps, self.fpsMax))
	end
end

local longTimeToWait, debugQueHead, debugQueTail

function BattleView:onUpdate(delta)
	if not self.gameLayer then
		return
	end

	updateSaltNumber(delta)

	delta = delta * 1000

	if self.modelWaitType then
		self.modelPauseTimer[2] = os.clock()

		if self.modelPauseTimer[2] - self.modelPauseTimer[1] > 1000 and longTimeToWait ~= self.modelWaitType then
			longTimeToWait = self.modelWaitType

			printWarn("Model Disable Time too Long, modelWaitType:" .. self.modelWaitType)
		end

		if self.effectManager:queueSize() == 0 and self.onceEffectWaitCount <= 0 then
			log.battle.battleView.resume(self.modelWaitType)

			if battle.OuterGuideName[self.modelWaitType] then
				self:checkOuterGuideState()
			elseif self.modelWaitType == "guiding" then
				self.guideManager:update(delta)
			else
				self:onModelResume()
			end
		elseif device.platform == "windows" and (debugQueHead ~= self.effectManager.queHeadID or debugQueTail ~= self.effectManager.queTailID) then
			lazylog.battle.battleView.wait(self.modelWaitType, function()
				for i, v in ipairs(self.effectManager:queueInfo()) do
					print(i, v)
				end

				return ""
			end)

			debugQueHead = self.effectManager.queHeadID
			debugQueTail = self.effectManager.queTailID
		end
	end

	self.tick = self.tick + delta

	cache.onBattleUpdate(delta)
	self.effectManager:update(delta)
	self:onViewProxyNotify("update", delta)
	self._model:update(delta)
	self:onViewProxyNotify("updateOver", delta)
	collectgarbage("step", 10)
end

function BattleView:getSceneModel()
	if not self._scene then
		self._scene = readOnlyProxy(self._model.scene)
	end

	return self._scene
end

function BattleView:getPlayModel()
	if not self._play then
		self._play = readOnlyProxy(self._model.scene.play)
	end

	return self._play
end

local operators = {
	[battle.OperateTable.timeScale] = function(self, num)
		self.timeScale = battle.SpeedTimeScale[num]

		display.director:getScheduler():setTimeScale(self.timeScale * self.brawlTimeScale)
	end,
	[battle.OperateTable.ultAcc] = function(self)
		self.inUltAcc = true

		display.director:getScheduler():setTimeScale(battle.SpeedTimeScale.ultAcc)
	end,
	[battle.OperateTable.ultAccEnd] = function(self)
		self.inUltAcc = false

		display.director:getScheduler():setTimeScale(self.timeScale)
	end,
	[battle.OperateTable.pass] = function(self)
		self:stopAllActions()
		self:disableUpdate()

		return self._model:handleOperation(battle.OperateTable.pass, self.modes.fromEditor)
	end
}

function BattleView:handleOperation(_type, ...)
	local f = operators[_type]

	if f then
		return f(self, ...)
	else
		return self._model:handleOperation(_type, ...)
	end
end

function BattleView:setGuideData(cfgIds)
	self.guideManager:setData(cfgIds)
end

function BattleView:setGuideClickCall(f)
	self.guideManager:setChoicesFunc(f)
end

function BattleView:bulletTimeShow()
	display.director:getScheduler():setTimeScale(battle.SpeedTimeScale.single * 0.25)
	performWithDelay(self, function()
		display.director:getScheduler():setTimeScale(1)
	end, 0.25)
end

function BattleView:_onShowArenaEndView(results)
	if self.modes.noShowEndRewards or self.modes.isRecord then
		local isWin = results.result == "win"

		if isWin and not self.modes.isRecord then
			gGameUI:stackUI("battle.battle_end.pvp_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		else
			gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)
		end
	else
		self.modes.noShowEndRewards = true

		gGameUI:stackUI("battle.battle_end.pvp_reward", {
			showEndView = self:createHandler("_onShowArenaEndView", results, true)
		}, gateEndStyles, results):z(999)
		sdk.trackEvent("challenge_arena")
	end
end

function BattleView:_onShowCircusEndView(results)
	if self.modes.isRecord then
		gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)
	else
		gGameUI:stackUI("battle.battle_end.cross_circus", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
	end
end

function BattleView:_onShowEndView(results, curdata, predata)
	assert(results.flag, "_onShowEndView results.flag is nil")
	assert(results.stageUpInfo, "_onShowEndView results.stageUpInfo is nil")

	if results.serverData == nil then
		gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)

		return
	end

	local isWin = results.result == "win"

	if isWin and not self.modes.isRecord then
		if not self.modes.nextShowStageUp then
			if curdata.stageName == predata.stageName then
				gGameUI:stackUI("battle.battle_end.pvp_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)

				results.backCity = true
			else
				gGameUI:stackUI("battle.battle_end.pvp_win", {
					showEndView = self:createHandler("_onShowEndView", results, curdata, predata)
				}, gateEndStyles, self.sceneID, self.data, results):z(999)

				self.modes.nextShowStageUp = true
			end
		else
			gGameUI:stackUI("battle.battle_end.pvp_stage_up", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		end
	else
		gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)
	end
end

function BattleView:_onShowGymLeaderEndView(results)
	if self.modes.isRecord then
		gGameUI:switchUI("city.view")

		return
	end

	results.flag = "gymLeader"
	results.gymName = csv.gym.gym[gGameModel.battle.gym_id].name

	if results.result == "win" then
		gGameUI:stackUI("battle.battle_end.pvp_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
	else
		gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)
	end
end

local gateEndFuncs = {
	[game.GATE_TYPE.newbie] = function(self, results)
		gGameUI:switchUI("new_character.view")
	end,
	[game.GATE_TYPE.test] = function(self, results)
		gGameUI:switchUI("city.view")
	end,
	[game.GATE_TYPE.normal] = function(self, results)
		if results.result == "win" then
			gGameUI:stackUI("battle.battle_end.win", nil, gateEndStyles, self, results):z(999)
			self:showCaptureTips(results.oldCapture)
		else
			self:jumpToPveFailView(results, 1)
		end
	end,
	[game.GATE_TYPE.arena] = function(self, results)
		return self:_onShowArenaEndView(results)
	end,
	[game.GATE_TYPE.crossArena] = function(self, results)
		results.flag = "crossArena"
		results.stageUpInfo = {
			mainSpine = "crossarena/duanwei.skel",
			upx = "_loop"
		}

		return self:_onShowEndView(results, results.curData, results.preData)
	end,
	[game.GATE_TYPE.friendFight] = function(self, results)
		gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)
	end,
	[game.GATE_TYPE.randomTower] = function(self, results)
		if results.result == "win" then
			gGameUI:stackUI("battle.battle_end.random_win", nil, gateEndStyles, self, results):z(999)
		else
			self:jumpToPveFailView(results, 3)
		end
	end,
	[game.GATE_TYPE.dailyGold] = function(self, results)
		gGameUI:stackUI("battle.battle_end.daily_activity", nil, gateEndStyles, self.sceneID, results):z(999)
	end,
	[game.GATE_TYPE.endlessTower] = function(self, results)
		if self.modes.noShowEndRewards or self.modes.isRecord then
			gGameUI:switchUI("city.view")
		elseif results.result == "win" then
			gGameUI:stackUI("battle.battle_end.endless_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		else
			gGameUI:stackUI("battle.battle_end.endless_fail", nil, gateEndStyles, self, results, 1):z(999)
		end
	end,
	[game.GATE_TYPE.unionFuben] = function(self, results)
		gGameUI:stackUI("battle.battle_end.daily_activity", nil, gateEndStyles, self.sceneID, results):z(999)
	end,
	[game.GATE_TYPE.gift] = function(self, results)
		if results.result == "win" then
			gGameUI:stackUI("battle.battle_end.simple_activity_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		else
			self:jumpToPveFailView(results, 3)
		end
	end,
	[game.GATE_TYPE.clone] = function(self, results)
		if results.result == "win" then
			gGameUI:stackUI("battle.battle_end.clone_win", nil, nil, self.sceneID, self.data, results):z(999)
		else
			self:jumpToPveFailView(results, 3)
		end
	end,
	[game.GATE_TYPE.worldBoss] = function(self, results)
		gGameUI:stackUI("battle.battle_end.world_boss_win", nil, gateEndStyles, self.sceneID, results):z(999)
	end,
	[game.GATE_TYPE.crossOnlineFight] = function(self, results)
		if results.showReward then
			gGameUI:stackUI("battle.battle_end.reward", nil, gateEndStyles, self:createHandler("_onShowRewardEndView", results), results):z(999)

			return
		end

		if results.result == "win" then
			if results.showMvpView then
				gGameUI:stackUI("battle.battle_end.pvp_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
			else
				gGameUI:stackUI("battle.battle_end.jf", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
			end
		else
			gGameUI:stackUI("battle.battle_end.jf", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		end
	end,
	[game.GATE_TYPE.crossCircus] = function(self, results)
		return self:_onShowCircusEndView(results)
	end,
	[game.GATE_TYPE.gym] = function(self, results)
		if gGameModel.battle.gym_id and csv.gym.gate[gGameModel.battle.gate_id].npc then
			self.data.actions = results.actions

			return self:_onShowGymLeaderEndView(results)
		end

		if results.result == "win" then
			results.flag = "gym"

			gGameUI:stackUI("battle.battle_end.simple_activity_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		else
			self:jumpToPveFailView(results, 3)
		end
	end,
	[game.GATE_TYPE.gymLeader] = function(self, results)
		return self:_onShowGymLeaderEndView(results)
	end,
	[game.GATE_TYPE.crossGym] = function(self, results)
		local crossGymRoles = gGameModel.gym:getIdler("crossGymRoles"):read()
		local gymLeader = crossGymRoles and crossGymRoles[gGameModel.battle.gym_id][1]

		if not gymLeader or gymLeader.record_id ~= gGameModel.battle.defence_record_id then
			results.gymMember = true
		end

		return self:_onShowGymLeaderEndView(results)
	end,
	[game.GATE_TYPE.crossMine] = function(self, results)
		results.flag = "crossMine"

		if results.result == "win" then
			if self.modes.isRecord then
				gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)
			else
				gGameUI:stackUI("battle.battle_end.pvp_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
			end
		else
			gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)
		end
	end,
	[game.GATE_TYPE.crossMineBoss] = function(self, results)
		gGameUI:stackUI("battle.battle_end.daily_activity", nil, gateEndStyles, self.sceneID, results):z(999)
	end,
	[game.GATE_TYPE.braveChallenge] = function(self, results)
		if results.result == "win" then
			gGameUI:stackUI("battle.battle_end.brave_challenge_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		else
			self:jumpToPveFailView(results, 3)
		end
	end,
	[game.GATE_TYPE.summerChallenge] = function(self, results)
		if results.result == "win" then
			gGameUI:stackUI("battle.battle_end.activity_challenge_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		else
			gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)
		end
	end,
	[game.GATE_TYPE.hunting] = function(self, results)
		if results.result == "win" then
			gGameUI:stackUI("battle.battle_end.hunting_win", nil, gateEndStyles, self, self.sceneID, self.data, results):z(999)
		else
			self:jumpToPveFailView(results, 3)
		end
	end,
	[game.GATE_TYPE.crossSupremacy] = function(self, results)
		results.flag = "crossSupremacy"
		results.stageUpInfo = {
			mainSpine = "cross_supremacy/duanwei.skel",
			upx = "_upx"
		}

		self:_onShowEndView(results, results.curData, results.preData)
	end,
	[game.GATE_TYPE.mimicry] = function(self, results)
		gGameUI:stackUI("battle.battle_end.mimicry_win", nil, gateEndStyles, self.sceneID, results):z(999)
	end,
	[game.GATE_TYPE.crossUnionAdventure] = function(self, results)
		gGameUI:switchUI("city.view")

		local uiBack = self.data.uiBack

		if uiBack and uiBack == "city.union.cross_union_adventure.view" then
			dataEasy.crossUnionAdventureLoginServer({
				cb = function()
					return
				end,
				errCb = function()
					gGameUI:goBackInStackUI("city.union.cross_union_adventure.main.view")
				end
			})
		end
	end,
	[game.GATE_TYPE.abyssEndlessTower] = function(self, results)
		if self.modes.noShowEndRewards or self.modes.isRecord then
			gGameUI:switchUI("city.view")
		elseif results.result == "win" then
			gGameUI:stackUI("battle.battle_end.abyss_endless_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		else
			gGameUI:stackUI("battle.battle_end.abyss_endless_fail", nil, gateEndStyles, self, results, 1):z(999)
		end
	end
}

gateEndFuncs[game.GATE_TYPE.dailyExp] = gateEndFuncs[game.GATE_TYPE.dailyGold]
gateEndFuncs[game.GATE_TYPE.fragment] = gateEndFuncs[game.GATE_TYPE.gift]
gateEndFuncs[game.GATE_TYPE.simpleActivity] = gateEndFuncs[game.GATE_TYPE.gift]
gateEndFuncs[game.GATE_TYPE.dailyContract] = gateEndFuncs[game.GATE_TYPE.gift]
gateEndFuncs[game.GATE_TYPE.huoDongBoss] = gateEndFuncs[game.GATE_TYPE.gift]
gateEndFuncs[game.GATE_TYPE.hellRandomTower] = gateEndFuncs[game.GATE_TYPE.randomTower]

local gateEndErrorFuncs = {
	backToView = function()
		gGameUI:switchUI("city.view")
	end
}

function BattleView:_onShowRewardEndView(results)
	results.showReward = false

	gateEndFuncs[self.gateType](self, results)
end

function BattleView:postEndResultToServer(url, cbOrT, ...)
	checkGGCheat()

	if type(cbOrT) == "function" then
		local cb = cbOrT

		return gGameApp:requestServer(url, function(tb)
			cb(tb)
		end, ...)
	end

	local req = gGameApp:requestServerCustom(url):params(...)
	local cb = cbOrT.cb

	cbOrT.cb = nil
	cbOrT.onErrClose = cbOrT.onErrClose or gateEndErrorFuncs.backToView

	for k, v in pairs(cbOrT) do
		req[k](req, v)
	end

	return req:doit(cb)
end

function BattleView:showEndView(results)
	display.director:getScheduler():setTimeScale(1)
	audio.stopMusic()
	self:showMainUI(false)
	self.gameLayer:setVisible(false)
	self.effectLayer:setVisible(false)
	self:onViewProxyNotify("showSpec", false)
	self:disableUpdate()
	performWithDelay(self, function()
		if gateEndFuncs[self.gateType] and not self.modes.fromRecordFile then
			gateEndFuncs[self.gateType](self, results)
		else
			gateEndFuncs[game.GATE_TYPE.test](self, results)
		end
	end, 0)
end

function BattleView:showCaptureTips(oldCapture)
	if not dataEasy.isUnlock(gUnlockCsv.limitCapture) then
		return
	end

	local newCapture = gGameModel.capture:read("limit_sprites")

	for i, capture in pairs(newCapture) do
		if not itertools.equal(capture, oldCapture[i]) then
			gGameUI:stackUI("common.capture_tips")

			break
		end
	end
end

function BattleView:newbieEndPlayAni()
	display.director:getScheduler():setTimeScale(1)
	self:showMainUI(false)

	local function addEffect(name, action, zOrder)
		return widget.addAnimationByKey(self.frontStageLayer, name, "effect" .. zOrder, action, zOrder):xy(display.center):scale(2)
	end

	audio.playEffectWithWeekBGM("newbie_finish.mp3")
	addEffect("koudai_beijing/huangtu.skel", "gaoguangshike", 1)
	addEffect("koudai_beijing/changguan.skel", "gaoguangshike", 2)
	addEffect("koudai_beijing/huangtu.skel", "gaoguangshike_qian", 3)
	addEffect("koudai_beijing/shuizhu.skel", "gaoguangshike", 4)
	addEffect("newguide/gaoguangshike.skel", "gaoguangshike", 5)
	addEffect("koudai_beijing/shuizhu.skel", "gaoguangshike_qian", 6)
end

function BattleView:getEffectEventEnable()
	return self.effectEventEnable
end

function BattleView:closeEffectEventEnable()
	self.effectEventEnable = false

	return self.effectEventEnable
end

function BattleView:resetEffectEventEnable()
	self.effectEventEnable = true

	return self.effectEventEnable
end

function BattleView:hasGuide()
	if self.isGuideScene ~= nil then
		return self.isGuideScene
	end

	local cfg = gMonsterCsv[self.sceneID][1]

	self.isGuideScene = battleEasy.ifElse(cfg.storys, true, false)

	return self.isGuideScene
end

function BattleView:getSceneConf()
	local sceneCsvs = {
		default = csv.scene_conf,
		[game.GATE_TYPE.endlessTower] = csv.endless_tower_scene,
		-- [game.GATE_TYPE.abyssEndlessTower] = csv.abyss_endless_tower.scene
	}
	local sceneCsv = sceneCsvs[self.gateType] or sceneCsvs.default

	return sceneCsv[self.sceneID]
end

function BattleView:getDeployType()
	if self.deployType then
		return self.deployType
	end

	local sceneConf = self:getSceneConf()

	if sceneConf then
		self.deployType = sceneConf.deployType
	end

	if self.gateType == game.GATE_TYPE.gym then
		local cfg = csv.gym.gate[self.sceneID]

		self.deployType = cfg and cfg.deployType
	elseif self.gateType == game.GATE_TYPE.hellRandomTower then
		self.deployType = self.data.gamemodel_data.deployType
	elseif self.gateType == game.GATE_TYPE.crossCircus then
		self.deployType = csv.cross.circus.theme[self.data.themeID].deployType
	end

	if not self.deployType then
		self.deployType = game.DEPLOY_TYPE.GeneralType
	end

	return self.deployType
end

function BattleView:jumpToPveFailView(results, mode)
	gGameUI:stackUI("battle.battle_end.pve_fail", nil, gateEndStyles, self, results, mode):z(999)
end

function BattleView:getAssignLayer(assignLayer)
	local AssignLayer = {
		[battle.AssignLayer.stageLayer] = self.stageLayer,
		[battle.AssignLayer.gameLayer] = self.gameLayer,
		[battle.AssignLayer.effectLayerLower] = self.effectLayerLower,
		[battle.AssignLayer.effectLayer] = self.effectLayer,
		[battle.AssignLayer.frontStageLayer] = self.frontStageLayer
	}

	return AssignLayer[assignLayer]
end

function BattleView:onPassOneMultWaveClean()
	self:flushAllDeferList()

	for _, v in ipairs(self.effectJumpCache) do
		self:onEventEffectCancel(v)
	end

	self.effectJumpCache = {}
	self.deferList = {}

	self.effectManager:passOneMultWaveClear()
	self.effectResManager:passOneMultWaveClean()
end

function BattleView:onBrawlSpeedChange(times)
	if not times then
		self.brawlTimeScale = 1
	else
		self.brawlTimeScale = times
	end

	display.director:getScheduler():setTimeScale(self.timeScale * self.brawlTimeScale)
end

function BattleView:getEffectMap(pos, force)
	if pos == 4 then
		force = 3 - force
	end

	if pos == 3 or pos == 4 then
		if force == 1 then
			return self.buffEffectsCache.forceSelf
		elseif force == 2 then
			return self.buffEffectsCache.forceEnemy
		end
	elseif pos == 5 then
		return self.buffEffectsCache.normal
	end

	return self.buffEffectsCache[pos]
end

function BattleView:forceClearBuffEffects()
	for name, t in pairs(self.buffEffectsCache) do
		self.buffEffectsCache[name] = {}

		for key, tt in pairs(t) do
			if tt.sprite then
				removeCSprite(tt.sprite)
			end
		end
	end
end

function BattleView:runDeferList(key)
	if self.deferList[key] then
		while not self.deferList[key]:empty() do
			local data = self.deferList[key]:pop_front()

			battleEasy.queueEffect(data.func)
		end
	end
end

function BattleView:runDeferListWithEffect(key)
	if self:onViewProxyCall("isMergeEffectCollecting") then
		local list = {}

		while not self.deferList[key]:empty() do
			local data = self.deferList[key]:pop_front()

			table.insert(list, data)
		end

		self:onEventEffectQueue("callback", {
			func = function()
				for _, data in ipairs(list) do
					battleEasy.effect(nil, data.func)
				end
			end
		})

		return
	end

	if self.deferList[key] then
		while not self.deferList[key]:empty() do
			local data = self.deferList[key]:pop_front()

			battleEasy.effect(nil, data.func)
		end
	end
end

function BattleView:getDeferList(key)
	if not self.deferList[key] then
		self.deferList[key] = CList.new()
	end

	return self.deferList[key]
end

function BattleView:collectNotify(key, obj, msg, ...)
	local f = functools.handler(obj and obj.view or gRootViewProxy, "notify", msg, ...)

	self:getDeferList(key):push_back({
		func = f,
		source = obj and obj.id or "global"
	})
end

function BattleView:collectCallBack(key, f)
	if key == self.modelWaitType then
		battleEasy.queueEffect(f)

		return
	end

	self:getDeferList(key):push_back({
		source = "global",
		func = f
	})
end

function BattleView:collectDeferList(key, obj, list)
	if not list then
		return
	end

	for k, v in list:ipairs() do
		self:getDeferList(key):push_back({
			func = v.func,
			source = obj and obj.id or "global"
		})
	end
end

function BattleView:enableQuickPass(scene)
	return
end

function BattleView:enableQuickPassOneWave(scene)
	return
end

function BattleView:modelCallSprite(obj, funcName, ...)
	SpriteController[funcName](obj, ...)
end

function BattleView:createModelCallSprite(obj, funcName, ...)
	return SpriteController.createCallFunc(obj, funcName, ...)
end

function BattleView:convertToBattleViewSpace(node, pos)
	return self:convertToNodeSpace(node:convertToWorldSpace(pos))
end

function BattleView:pushQueueCallBack(tag, id, f, isLast)
	if not self.queueCallBack[tag] then
		self.queueCallBack[tag] = {}
	end

	self.queueCallBack[tag][id] = self.queueCallBack[tag][id] or {}

	table.insert(self.queueCallBack[tag][id], {
		f = f,
		isLast = isLast
	})
end

function BattleView:popQueueCallBack(tag, id, isLast)
	if self.queueCallBack[tag][id] then
		if isLast then
			local data = table.remove(self.queueCallBack[tag][id])

			self.queueCallBack[tag][id] = nil

			return data.f
		end

		local data = table.remove(self.queueCallBack[tag][id], 1)

		if table.length(self.queueCallBack[tag][id]) == 0 then
			self.queueCallBack[tag][id] = nil
		end

		return data.f
	end
end

function BattleView:checkOuterGuide(specialName)
	gGameUI.guideManager:setIgnoreGuide(false)
	gGameUI.guideManager:checkGuide({
		specialName = specialName
	})
end

function BattleView:checkOuterGuideState()
	if gGameUI.guideManager:isInGuiding() then
		return
	end

	self:onModelResume()
end

function BattleView:performWithDelay(node, f, delay)
	performWithDelay(node, function()
		if tolua.isnull(self) then
			return
		end

		f()
	end, delay)
end

require("battle.app_views.battle.view_effect")
require("battle.app_views.battle.view_proxy")

return BattleView
