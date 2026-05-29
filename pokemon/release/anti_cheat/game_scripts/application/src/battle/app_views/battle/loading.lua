-- chunkname: @src.battle.app_views.battle.loading

require("battle.app_views.battle.preload_res")

local LOADING_STATE = {
	switchUI = 3,
	loadOver = 2,
	loading = 1
}
local ViewBase = cc.load("mvc").ViewBase
local BattleLoadingView = class("BattleLoadingView", ViewBase)

BattleLoadingView.RESOURCE_FILENAME = "battle_loading.json"
BattleLoadingView.RESOURCE_BINDING = {
	bg = "bg",
	bar = {
		varname = "bar",
		binds = {
			class = "loadingbar",
			event = "extend",
			props = {
				maskImg = "common/icon/mask_bar_red.png",
				data = bindHelper.self("percent")
			}
		}
	},
	percentText = {
		binds = {
			{
				event = "text",
				idler = bindHelper.self("percent"),
				method = function(val)
					return math.floor(val) .. "%"
				end
			},
			{
				event = "effect",
				data = {
					outline = {
						color = ui.COLORS.OUTLINE.DEFAULT
					}
				}
			}
		}
	},
	tipText = {
		varname = "tipText",
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.DEFAULT
				}
			}
		}
	}
}

local function fillResMap(resT, t)
	for k, v in pairs(t) do
		resT[v] = 1 + (resT[v] or 0)
	end
end

function BattleLoadingView:onCreate(data, sceneID, modes, entrance)
	assert(entrance, "entrance was nil !")

	self.data = data
	self.sceneID = sceneID
	self.modes = modes or {}
	self.entrance = entrance
	self.percent = idler.new(0)

	local idx = math.random(1, csvSize(csv.loading_tips))

	self.tipText:text(csv.loading_tips[idx].tip)

	local bgIdx = math.random(1, table.length(gCommonConfigArrayCsv.loadingBgTotal))

	self.bg:texture(string.format("loading/bg_%d.png", gCommonConfigArrayCsv.loadingBgTotal[bgIdx]))
	self:enableAsyncload():asyncFor(functools.partial(self.onLoading, self), functools.partial(self.onLoadOver, self))

	local x, y = self.bar:xy()
	local size = self.bar:box()
	local effect = widget.addAnimationByKey(self:getResourceNode(), "loading/loading_pikaqiu.skel", "effect", "effect_loop", 5):xy(x - size.width / 2, y + size.height / 2):scale(1.6)

	idlereasy.when(self.percent, function(_, percent)
		effect:x(x - size.width / 2 + percent * size.width / 100)
	end)

	self.canPlayMusic = false

	if not self.modes.baseMusic then
		local bgMusic = math.random(1, 5)
		local sMusic = string.format("battle%d.mp3", bgMusic)

		self.modes.baseMusic = sMusic
	end

	audio.preloadMusic(self.modes.baseMusic)
end

function BattleLoadingView:onLoading()
	local mem = collectgarbage("count")

	self.loadingState = LOADING_STATE.loading

	self.percent:set(1)
	coroutine.yield()
	self.percent:set(4)
	cache.onBattleClear()
	coroutine.yield()
	self.percent:set(5)
	checkGGCheat()
	coroutine.yield()
	self.percent:set(6)
	battleEntrance.preloadConfig()
	self.percent:set(7)
	cache.texturePreload("battle_common_ui")
	cache.texturePreload("battle_module")
	coroutine.yield()

	local resT = {}
	local audioT = {}
	local monsterCfg = gMonsterCsv[self.sceneID][1]

	if not monsterCfg then
		printError(" 查找 monster_scenes 时出错!!! 有场景第一波的配置不存在: sceneID=%s", self.sceneID)
	end

	visitFightResources(resT, audioT, monsterCfg, self.data)

	for i = 2, itertools.size(gMonsterCsv[self.sceneID]) do
		local monsterCfg = gMonsterCsv[self.sceneID][i]

		for _, unitId in ipairs(monsterCfg.monsters) do
			if unitId > 0 then
				local cfg = csv.unit[unitId]

				for i, skillId in ipairs(cfg.skillList) do
					local skillCfg = csv.skill[skillId]

					if skillCfg.sound then
						audioT[skillCfg.sound.res] = true
					end
				end
			end
		end
	end

	fillResMap(resT, battle.SpriteRes)
	fillResMap(resT, battle.ShowHeadNumberRes)
	fillResMap(resT, battle.MainAreaRes)
	fillResMap(resT, battle.StageRes)
	fillResMap(resT, battle.RestraintTypeIcon)

	local current = 0
	local allCount = itertools.sum(resT) + itertools.size(audioT)

	log.battleloading.preload(" ---- preLoad res, allCount=", allCount, itertools.sum(resT), itertools.size(audioT))
	self.percent:set(10)
	coroutine.yield()
	performWithDelay(self, function()
		self:onRunBattleModel()
	end, 0.01)

	for k, count in pairs(resT) do
		log.battleloading.preload(" ---- preload: file path=", k, count)

		for i = 1, count do
			CSprite.preLoad(k)

			current = current + 1

			self.percent:set(10 + 70 * current / allCount)
			coroutine.yield()
		end
	end

	local fileUtils = cc.FileUtils:getInstance()
	local n = display.textureCache:removeLongTimeUnusedTexturesWithCallback(function(delta, tex)
		local path = fileUtils:getRawPathInRepoCache(tex:getPath())

		return path:find("battle/") == nil and path:find("res/spine/koudai_") == nil
	end, 0, -1)

	if n > 0 then
		printInfo("remove %d textures in battle.loading", n)
	end

	coroutine.yield()
	cc.SpriteFrameCache:getInstance():addSpriteFrames("battle/buff_icon/buffs0.plist")
	cc.SpriteFrameCache:getInstance():addSpriteFrames("battle/txt/txts0.plist")
	coroutine.yield()

	self.canPlayMusic = true

	for k, v in pairs(audioT) do
		log.battleloading.preload(" ---- preload: audio path=", k, v)
		audio.preloadSound(k)

		current = current + 1

		self.percent:set(10 + 70 * current / allCount)
		coroutine.yield()
	end

	for i = 1, 15 do
		collectgarbage("step", 10000)
		self.percent:set(80 + i)
		coroutine.yield()
	end

	while self.loadingState ~= LOADING_STATE.loadOver do
		collectgarbage("step", 10000)
		coroutine.yield()
	end

	local clock = os.clock()

	collectgarbage()
	printInfo("battle loading gc over %.2f KB %s s", mem - collectgarbage("count"), os.clock() - clock)
	self.percent:set(100)
	coroutine.yield()

	self.loadingState = LOADING_STATE.loadOver
end

function BattleLoadingView:onPlayMusic(musicPath, args)
	if not self.canPlayMusic then
		return
	end

	if musicPath then
		audio.playMusic(musicPath)
	else
		audio.playMusic(self.modes.baseMusic)

		self.canPlayMusic = false
	end
end

function BattleLoadingView:onLoadOver()
	if self.loadingState ~= LOADING_STATE.loadOver then
		return
	end

	self.percent:set(100)
	performWithDelay(self, function()
		if not gGameUI.isPlayVideo then
			self.loadingState = LOADING_STATE.switchUI

			self:onPlayMusic()
			gGameUI:switchUI("battle.view", self.data, self.sceneID, self.modes, self.entrance)
		end
	end, 0)
end

function BattleLoadingView:onRunBattleModel()
	self.loadingState = LOADING_STATE.loadOver
end

return BattleLoadingView
