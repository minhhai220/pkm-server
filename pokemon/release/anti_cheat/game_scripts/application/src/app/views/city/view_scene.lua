-- chunkname: @src.app.views.city.view_scene

local DEBUG_SPRITE_AREA

if device.platform == "windows" then
	DEBUG_SPRITE_AREA = dev.DEBUG_SHOW
end

local CityView = {}
local halloweenMessages = require("app.views.city.halloween_messages"):getInstance()
local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE
local SCHEDULE_TAG = {
	sceneSet = 1,
	mysteryShop = 3,
	cityMan = 2
}
local UNFREEZE_TIME = 2
local UNFREEZE_ACTION_TAG = 2012211734
local UNFREEZE_CLICKS = {
	3,
	9,
	16
}
local BG_CHANGE_TAG = 66
local FOLLOW_TYPE = {
	"role",
	"followCardPanel"
}
local FOLLOW_MOVETIME = 0.5
local FOLLOW_SCALE = 1.7
local FESTIVAL_EFFECT = {
	springfestival = {
		scale = 1.7,
		height = 400,
		width = 700,
		callback = "onClickChunjieDumpling",
		offx2 = 50,
		z2 = 120,
		y2 = -230,
		spineName2 = "chunjieMan",
		effectName2 = "effect_loop",
		spine2 = "zhuchangjing/chunjiezhucheng.skel",
		offx1 = 210,
		z1 = 150,
		y1 = -320,
		spineName1 = "dumpling",
		effectName1 = "day_loop",
		spine1 = "zhuchangjing/chunjiezhucheng_light.skel",
		pos = cc.p(580, 240)
	},
	christmastree = {
		effectNameActive2 = "dailingqu_loop",
		scale = 1.7,
		height = 800,
		width = 850,
		callback = "onClickChristmastree",
		offx2 = 0,
		z2 = 150,
		y2 = 200,
		spineName2 = "shengdanxiong",
		effectName2 = "daiji_loop",
		spine2 = "christmastree/shengdanxiong.skel",
		offx1 = 0,
		z1 = 120,
		y1 = 200,
		spineName1 = "shengdanshu",
		effectName1 = "day_loop",
		spine1 = "christmastree/shengdanshu.skel",
		pos = cc.p(900, 200)
	},
	midmoon = {
		effectNameActive2 = "day_loop",
		spineName2 = "midmoon",
		effectName2 = "day2_loop",
		spine2 = "event/huodongtandian.skel",
		scale = 1.4,
		height = 650,
		width = 750,
		callback = "onClickMidmoon",
		offx2 = 0,
		z2 = 120,
		y2 = 200,
		pos = cc.p(2900, 200)
	},
	halloween = {
		spineName2 = "shadiao",
		effectName2 = "effect_loop",
		spine2 = "wanshengjie/shadiao.skel",
		scale = 2,
		height = 200,
		width = 650,
		callback = "onClickHalloweenFour",
		offx2 = 0,
		z2 = 0,
		y2 = 10,
		pos = cc.p(1005, 245)
	},
	qixiDailyAward = {
		effectNameActive2 = "effect_kai_loop",
		spineName2 = "qixi",
		effectName2 = "effect_guan_loop",
		spine2 = "qixiqueqiao/qixirukou.skel",
		scale = 0.86,
		height = 400,
		width = 500,
		callback = "onClickQixiAward",
		offx2 = -50,
		z2 = 0,
		y2 = 10,
		pos = cc.p(815, 238)
	}
}

function CityView:initSceneData()
	self.bgPanel:setScrollBarEnabled(false)

	self.refreshBgShade = idler.new(true)
	self.snowmanId = idler.new()
	self.lightingNewYearId = idler.new()
	self.roleFigureNum = 1
	self.roleSprite = nil
	self.isNight = idler.new(false)

	self:initHalloween()
	idlereasy.when(self.citySceneIdx, function(_, idx)
		self.citySceneCfg = csv.cityscene[idx]
		self.festivalEffect = clone(FESTIVAL_EFFECT)

		for name, cfg in csvMapPairs(self.citySceneCfg.festivalEffectExtend) do
			for k, v in csvMapPairs(cfg) do
				self.festivalEffect[name][k] = csvClone(v)
			end
		end

		local innerSize = self.citySceneCfg.sceneSize

		self.bgPanel:setInnerContainerSize(innerSize)
		self.bgPanel:size(display.sizeInViewRect):x(display.sizeInViewRect.x):jumpToPercentHorizontal((1750 - display.sizeInViewRect.width / 2) / (innerSize.width - display.sizeInViewRect.width) * 100)
		self.bgPanel:removeAllChildren()

		self.roleSprite = nil
		self.dailyAssistantPanel = nil
		self.citySpriteDatas = {}
		self.spriteUnfreezeData = {}

		self:unSchedule(SCHEDULE_TAG.sceneSet)
		self:unSchedule(SCHEDULE_TAG.cityMan)
		self:unSchedule(SCHEDULE_TAG.mysteryShop)
		self:initBgPanel()
		self:onHalloween()
		self:addCitySprites()
		self:refreshMysteryShop()
		self:onSnowman()
		self:fishingGameTip()
		self:dailyAssistantTip()
		self:onLightingNewYear()
		self:initFloowPanel()----精灵跟随函数
		self:initBgShade()
	end)
	performWithDelay(self, function()
		self:refreshBaibian()
	end, 0)
	self:initFadeOutDatas()
end

function CityView:initBgPanel()
	self.effects = {}

	local effectNames = csv.cityscene[self.citySceneIdx:read()].effectNames

	for i, v in ipairs(effectNames) do
		local effect = widget.addAnimationByKey(self.bgPanel, v.res, v.name, "day_loop", v.zOrder):alignCenter(self.bgPanel:getInnerContainerSize()):scale(2)

		self.effects[v.name] = effect
	end

	idlereasy.any({
		self.yyOpen,
		self.yyhuodongs
	}, function(_, yyOpen, yyhuodongs)
		self.halloweenDailyAward:set(false)

		local isOpen = self:initLoginWeal()

		if not isOpen then
			for name, data in pairs(self.festivalEffect) do
				if data.spineName1 then
					self.effects[data.spineName1] = nil
				end

				if data.spineName2 then
					self[data.spineName2] = nil
				end

				if self.bgPanel:get(name) then
					self.bgPanel:get(name):removeSelf()
				end
			end
		end
	end):anonyOnly(self)
end

function CityView:initLoginWeal()
	local yyOpen = self.yyOpen:read()
	local yyhuodongs = self.yyhuodongs:read()
	local isOpen = false

	for _, id in ipairs(yyOpen) do
		local cfg = csv.yunying.yyhuodong[id]
		local clientType = cfg.clientParam.type

		if cfg.type == YY_TYPE.loginWeal and cfg.independent == -1 and self.festivalEffect[clientType] then
			isOpen = true

			local csvId
			local huodong = yyhuodongs[id] or {}

			for k, v in pairs(huodong.stamps or {}) do
				if v > 0 and (not csvId or k < csvId) then
					csvId = k
				end
			end

			local data = self.festivalEffect[clientType]
			local effectName1 = data.effectName1
			local effectName2 = data.effectName2

			if csvId and data.effectNameActive2 then
				effectName2 = data.effectNameActive2
			end

			local panel = self.bgPanel:get(clientType)

			if not panel then
				panel = ccui.Layout:create()

				panel:setTouchEnabled(true)
				panel:xy(data.pos)
				panel:addTo(self.bgPanel, 200, clientType)

				if DEBUG_SPRITE_AREA then
					panel:setBackGroundColorType(1)
					panel:setBackGroundColor(cc.c3b(200, 0, 0))
					panel:setBackGroundColorOpacity(100)
				end

				local box

				if data.spine1 then
					local effect = widget.addAnimation(panel, data.spine1, effectName1, data.z1):scale(data.scale)

					self.effects[data.spineName1] = effect

					if not box then
						box = effect:box()

						panel:size(data.width or box.width, data.height)
					end

					effect:xy(box.width / 2 + data.offx1, data.y1)
				end

				if data.spine2 then
					local effect = widget.addAnimation(panel, data.spine2, effectName2, data.z2)

					self[data.spineName2] = effect

					if not box then
						box = effect:box()

						panel:size(data.width or box.width, data.height)
					end

					effect:xy(box.width / 2 + data.offx2, data.y2):scale(data.scale)
				end
			else
				if self.effects[data.spineName1] then
					self.effects[data.spineName1]:play(effectName1)
				end

				if data.spine2 and self[data.spineName2] then
					self[data.spineName2]:play(effectName2)
				end
			end

			bind.click(self, panel, {
				method = functools.partial(self[data.callback], self, id, csvId)
			})

			if clientType == "halloween" then
				self.halloweenDailyAward:set(true)
			end
		end
	end

	return isOpen
end

function CityView:initBgShade()
	local speicalEffectNames = {
		"roleSprite",
		"dailyAssistantPanel",
		"lightingNewYearSprite"
	}

	for _, data in pairs(self.festivalEffect) do
		if data.spineName2 then
			table.insert(speicalEffectNames, data.spineName2)
		end
	end

	local startTime = gCommonConfigCsv.cityBgStartTime * 60
	local data = {
		{
			action = "day_loop",
			changeAction = "morning",
			duration = gCommonConfigCsv.cityBgDayDuration * 60,
			shaderColor = cc.vec4(1, 1, 1, 1)
		},
		{
			action = "night_loop",
			changeAction = "dusk",
			duration = gCommonConfigCsv.cityBgNightDuration * 60,
			shaderColor = cc.vec4(0.75, 0.75, 1.2, 1)
		}
	}
	local totalTime = 0

	for _, v in ipairs(data) do
		totalTime = totalTime + v.duration
	end

	local idx = 1
	local nextTime = 0
	local duration = 60

	local function changeBg(init)
		local curData = data[idx]

		self:unSchedule(SCHEDULE_TAG.sceneSet)

		if init or not curData.changeAction then
			for _, effect in pairs(self.effects) do
				effect:play(curData.action)
			end

			for _, name in ipairs(speicalEffectNames) do
				if not tolua.isnull(self[name]) then
					cache.setColor2Shader(self[name], false, curData.shaderColor)
				end
			end

			for _, info in pairs(self.citySpriteDatas) do
				cache.setColor2Shader(info.target:get("effect"), false, curData.shaderColor)
			end

			local spine = self.bgPanel:get("followCardPanel.card")

			if spine then
				if spine.isTintBlack then
					spine:setColor2Shader(curData.shaderColor)
				else
					cache.setColor2Shader(spine, false, curData.shaderColor)
				end
			end

			if self.bgPanel:get("followCardPanel") then
				self.bgPanel:get("followCardPanel").shaderColor = curData.shaderColor
			end

			self.curChangIndex = 0

			self.isNight:set(idx == 2)
		else
			for _, effect in pairs(self.effects) do
				effect:play(curData.changeAction)
				effect:addPlay(curData.action)
			end

			local lastIdx = idx == 1 and #data or idx - 1
			local lastColor = data[lastIdx].shaderColor
			local targetColor = curData.shaderColor
			local index = self.curChangIndex or 0

			self:schedule(function(dt)
				index = index + 1
				self.curChangIndex = index

				local pow = index / (duration / dt)
				local color = {}

				for k, v in pairs(targetColor) do
					color[k] = lastColor[k] + pow * (v - lastColor[k])
				end

				for _, name in ipairs(speicalEffectNames) do
					if self[name] then
						cache.setColor2Shader(self[name], false, color)
					end
				end

				for _, info in pairs(self.citySpriteDatas) do
					cache.setColor2Shader(info.target:get("effect"), false, color)
				end

				local spine = self.bgPanel:get("followCardPanel.card")

				if spine then
					if spine.isTintBlack then
						spine:setColor2Shader(curData.shaderColor)
					else
						cache.setColor2Shader(spine, false, curData.shaderColor)
					end
				end

				if pow >= 1 then
					self.isNight:set(idx == 2)

					self.curChangIndex = 0

					for _, effect in pairs(self.effects) do
						effect:play(curData.action)
					end

					return false
				end
			end, 0.016666666666666666, 0, SCHEDULE_TAG.sceneSet)
		end

		self.bgPanel:stopActionByTag(BG_CHANGE_TAG)

		local action = performWithDelay(self.bgPanel, function()
			idx = idx % #data + 1
			nextTime = data[idx].duration

			changeBg()
		end, nextTime)

		action:setTag(BG_CHANGE_TAG)
	end

	idlereasy.when(self.refreshBgShade, function()
		local nowDate = time.getNowDate()

		nextTime = nowDate.hour * 3600 + nowDate.min * 60 + nowDate.sec - startTime

		if nextTime < 0 then
			nextTime = nextTime + 86400
		end

		nextTime = nextTime % totalTime

		for i, v in ipairs(data) do
			if nextTime < v.duration then
				nextTime = v.duration - nextTime
				idx = i

				break
			end

			nextTime = nextTime - v.duration
		end

		changeBg(true)
	end):anonyOnly(self)
end

function CityView:addCitySprites()
	idlereasy.when(self.figure, function(_, figure)
		local roleCfg = gRoleFigureCsv[figure]
		local name = roleCfg.resSpine

		if self.roleSprite then
			self.roleSprite:removeFromParent()

			self.roleSprite = nil
		end

		if name and name ~= "" then
			local time = 0
			local distance = 30
			local rand
			local baseTime = gCommonConfigCsv.citySpecialTimeMin
			local panel = ccui.Layout:create()

			panel:setTouchEnabled(true)
			panel:xy(roleCfg.pos)
			panel:addTo(self.bgPanel, roleCfg.zOrder, "role")

			self.roleSprite = panel

			if DEBUG_SPRITE_AREA then
				panel:setBackGroundColorType(1)
				panel:setBackGroundColor(cc.c3b(0, 0, 200))
				panel:setBackGroundColorOpacity(100)
			end

			bind.click(self, panel, {
				method = functools.partial(self.onClickRoleSprite, self, figure)
			})

			local effect = widget.addAnimationByKey(panel, name, "effect", "standby_loop1", 1):scale(1)
			local box = effect:box()

			panel:size(box.width, box.height)
			effect:xy(box.width / 2, 0)
			self.refreshBgShade:notify()
			self:schedule(function()
				time = time + 1

				if time > baseTime then
					if not rand then
						rand = math.random(baseTime, baseTime + distance)
					end

					if time >= rand and self.roleSprite then
						time = 0
						rand = nil

						self.roleSprite:get("effect"):play("weixuanzhong")
						self:showRoleSpeak(figure, 2)
						self.roleSprite:get("effect"):setSpriteEventHandler(function(event, eventArgs)
							self.roleSprite:get("effect"):play("standby_loop1")
						end, sp.EventType.ANIMATION_COMPLETE)
					end
				end
			end, 1, 0, SCHEDULE_TAG.cityMan)
		end
	end):anonyOnly(self)

	self.spriteUnfreezeYYData = idlereasy.new({})

	idlereasy.any({
		self.yyOpen,
		self.yyhuodongs
	}, function(_, yyOpen, yyhuodongs)
		for _, id in ipairs(yyOpen) do
			local cfg = csv.yunying.yyhuodong[id]

			if cfg.type == YY_TYPE.spriteUnfreeze then
				local yyData = yyhuodongs[id] or {}
				local stamps = clone(yyData.stamps or {})

				self.spriteUnfreezeYYData:set({
					yyId = id,
					stamps = stamps
				})

				return
			end
		end

		self.spriteUnfreezeYYData:set({})
	end):anonyOnly(self)
	idlereasy.any({
		self.citySprites,
		self.yyOpen,
		self.spriteUnfreezeYYData
	}, function(_, citySprites, yyOpen, spriteUnfreezeYYData)
		for k, v in pairs(self.citySpriteDatas) do
			v.target:removeFromParent()
		end

		local yyOpenHash = arraytools.hash(yyOpen)

		self.citySpriteDatas = {}

		local baibian = citySprites.baibian or {}
		local mini = citySprites.miniQ or {}
		local spriteUnfreezeStamps = spriteUnfreezeYYData.stamps or {}
		local citySceneIdx = self.citySceneIdx:read()
		local baibianT = {}
		local miniT = {}

		local function createCitySprite(data)
			local x, y = data.position.x, data.position.y
			local scale = data.scale
			local pos = data["positionS" .. citySceneIdx]

			if pos then
				x, y = pos.x, pos.y
			end

			for _, activityId in csvPairs(data.activityIds) do
				if yyOpenHash[activityId] then
					x, y = data.activityPosition.x, data.activityPosition.y
					scale = data.activityScale

					local pos = data["activityPositionS" .. citySceneIdx]

					if pos then
						x, y = pos.x, pos.y
					end

					break
				end
			end

			local panel = ccui.Layout:create()

			panel:setTouchEnabled(true)
			panel:addTo(self.bgPanel, data.zOrder, string.format("cardSpine_%d", data.id))
			panel:xy(x, y)

			local obj = widget.addAnimationByKey(panel, data.res, "effect", "effect_loop", 1):scale(scale)
			local box = obj:box()

			if data.touchSize then
				box = {
					width = data.touchSize.width * scale,
					height = data.touchSize.height * scale
				}
			end

			panel:size(box.width, box.height)
			obj:xy(box.width / 2, 0)

			if DEBUG_SPRITE_AREA then
				panel:setBackGroundColorType(1)
				panel:setBackGroundColor(cc.c3b(200, 0, 0))
				panel:setBackGroundColorOpacity(100)
			end

			bind.click(self, panel, {
				method = functools.partial(self.onClickSprite, self, {
					cfg = data,
					csvId = data.id
				})
			})

			self.citySpriteDatas[data.id] = {
				data = data,
				target = panel
			}
		end

		for id, data in orderCsvPairs(csv.city_sprites) do
			if not data.action then
				table.insert(miniT, id)
			end

			if itertools.include(data.scene, citySceneIdx) then
				if data.shape_shifter then
					table.insert(baibianT, id)
				end

				createCitySprite(data)

				if spriteUnfreezeStamps[data.id] == 1 then
					if not self.spriteUnfreezeData[data.id] then
						self.spriteUnfreezeData[data.id] = {
							state = 1,
							clickCount = 0
						}
					end

					self:onFreezeSprite(data)
				end

				idlereasy.any({
					self.isNight,
					self.halloweenAllSpriteClicked,
					self.halloweenDailyAward
				}, function(_, isNight, halloweenAllSpriteClicked, halloweenDailyAward)
					local panel = self.citySpriteDatas[data.id].target

					panel:show()

					if isNight and halloweenAllSpriteClicked == false then
						panel:hide()
					end

					if halloweenDailyAward and data.type == 2 then
						panel:hide()
					end
				end):anonyOnly(self, data.id)
			end
		end

		if baibian.flag == 1 and #baibianT > 0 then
			local idx = math.random(1, #baibianT)
			local id = baibianT[idx]
			local data = self.citySpriteDatas[id]

			if data then
				data.isBaibian = true

				data.target:get("effect"):play("effect1_loop")
			end
		end

		if mini.flag == 1 and #miniT > 0 then
			local idx = math.random(1, #miniT)
			local id = miniT[idx]

			createCitySprite(csv.city_sprites[id])

			self.citySpriteDatas[id].isMiniQ = true
		end

		self.refreshBgShade:notify()
	end):anonyOnly(self)
end

function CityView:refreshBaibian()
	local citySprites = self.citySprites:read()
	local curTime = time.getTime()
	local baibian = citySprites.baibian or {}
	local active = false

	if baibian.period then
		local times = baibian.times or 0
		local endTime = time.getNumTimestamp(baibian.period or 0, time.getRefreshHour()) + gCommonConfigCsv.citySpriteBaibianPeriodDay * 24 * 3600 + 1

		if endTime < curTime then
			times = 0
		end

		if times < gCommonConfigCsv.citySpriteBaibianTimeMax and curTime - baibian.last > gCommonConfigCsv.citySpriteBaibianCD then
			local rand = math.random(1, 100)

			if rand <= gCommonConfigCsv.citySpriteBaibianProbability then
				active = true
			end
		end
	else
		active = true
	end

	if active then
		gGameApp:slientRequestServer("/game/role/city/sprite/active", nil, 1)

		return
	end

	local mini = citySprites.miniQ or {}

	if mini.period then
		local times = mini.times or 0
		local endTime = time.getNumTimestamp(mini.period or 0, time.getRefreshHour()) + gCommonConfigCsv.citySpriteMiniQPeriodDay * 24 * 3600 + 1

		if endTime < curTime then
			times = 0
		end

		if times < gCommonConfigCsv.citySpriteMiniQTimeMax and curTime - mini.last > gCommonConfigCsv.citySpriteMiniQCD then
			local rand = math.random(1, 100)

			if rand <= gCommonConfigCsv.citySpriteMiniQProbability then
				active = true
			end
		end
	else
		active = true
	end

	if active then
		gGameApp:slientRequestServer("/game/role/city/sprite/active", nil, 2)
	end
end

function CityView:showRoleSpeak(csvId, flag)
	local parent, cfg, effect

	if flag == 1 then
		local info = self.citySpriteDatas[csvId]

		parent = info.target
		cfg = csv.city_sprites[csvId]
	elseif flag == 2 then
		parent = self.roleSprite
		cfg = gRoleFigureCsv[csvId]
	end

	effect = parent:getChildByName("effect")

	parent:removeChildByName("talkContent")
	parent:removeChildByName("talkBg")

	local content = {}
	local count = 0

	for i = 1, 10 do
		local str = cfg["chattext" .. i]

		if not str or str == "" then
			break
		end

		table.insert(content, str)

		count = count + 1
	end

	if assertInWindows(content[1], "csv.%s[%s] chattext not exist", flag == 1 and "city_sprites" or "role_figure", csvId) then
		return
	end

	local box = effect:box()

	if count < self.roleFigureNum then
		self.roleFigureNum = math.random(1, count)
	end

	local offPos = cfg.offPos
	local width = 240

	if matchLanguage({
		"en"
	}) then
		width = 350
	end

	local txt = rich.createWithWidth("#C0x5b545b#" .. content[self.roleFigureNum], 40, nil, width):anchorPoint(0.5, 0):xy(box.width / 2 + offPos.x, box.height + 40 + offPos.y):addTo(parent, 3, "talkContent")
	local size = txt:size()
	local bg = ccui.Scale9Sprite:create()

	bg:initWithFile(cc.rect(75, 59, 1, 1), "city/gate/bg_dialog.png")
	bg:size(size.width + 60, size.height + 60):anchorPoint(0.5, 0):xy(box.width / 2 + offPos.x, box.height + offPos.y):scaleX(cfg.overture and -1 or 1):addTo(parent, 2, "talkBg")
	parent:setTouchEnabled(false)
	performWithDelay(parent, function()
		parent:removeChildByName("talkContent")
		parent:removeChildByName("talkBg")
		parent:setTouchEnabled(true)
	end, 2)

	self.roleFigureNum = math.max((self.roleFigureNum + 1) % (count + 1), 1)

	if self.isNight:read() then
		cache.setColor2Shader(parent, false, cc.vec4(0.75, 0.75, 1.2, 1))
	end
end

function CityView:addCar(z)
	local shopPanel = self.bgPanel:get("steryShop")

	if shopPanel then
		shopPanel:removeSelf()
	end

	local effect = self.bgPanel:getChildByName("chezi")

	if effect then
		return
	end

	effect = widget.addAnimationByKey(self.bgPanel, self.citySceneCfg.cheziEffectName, "chezi", "day_loop", z):alignCenter(self.bgPanel:getInnerContainerSize()):scale(2):setCascadeOpacityEnabled(true):opacity(0)
	self.effects.chezi = effect

	transition.fadeIn(effect, {
		time = 1
	})
end

function CityView:refreshMysteryShop()
	local mysteryState = userDefault.getForeverLocalKey("mySteryState", 0)
	local isOpen = uiEasy.isOpenMystertShop()
	local state = 1

	if uiEasy.showMysteryShop() or isOpen then
		state = 2
	elseif not isOpen then
		state = 0
	end

	userDefault.setForeverLocalKey("mySteryState", state)

	local mystery = self.bgPanel:getChildByName("steryShop")

	if isOpen and state ~= 0 and not mystery then
		local carEft = self.bgPanel:getChildByName("chezi")
		local z = 11

		if carEft then
			z = carEft:z()

			carEft:removeFromParent()
		end

		mystery = ccui.Layout:create():size(800, 550)

		mystery:setTouchEnabled(true)
		mystery:addTo(self.bgPanel, z, "steryShop")
		mystery:xy(2130, 400)
		mystery:anchorPoint(0, 0)

		local effect = widget.addAnimation(mystery, self.citySceneCfg.mysteryShopName, "day_loop", 1):scale(2):xy(self.citySceneCfg.mysteryShopPos.x + 50, self.citySceneCfg.mysteryShopPos.y + 50):setCascadeOpacityEnabled(true):opacity(0)

		transition.fadeIn(effect, {
			time = 1
		})

		self.effects.chezi = effect

		self:schedule(function()
			local openState = uiEasy.isOpenMystertShop()

			if not openState then
				userDefault.setForeverLocalKey("mySteryState", 0)
				self:addCar(z)

				return false
			end
		end, 1, 0, SCHEDULE_TAG.mysteryShop)

		if DEBUG_SPRITE_AREA then
			mystery:setBackGroundColorType(1)
			mystery:setBackGroundColor(cc.c3b(200, 0, 0))
			mystery:setBackGroundColorOpacity(100)
		end

		bind.click(self, mystery, {
			method = function()
				gGameApp:requestServer("/game/mystery/get", function()
					gGameUI:stackUI("city.mystery_shop.view", nil, {
						full = true
					})
				end)
			end
		})
	elseif not isOpen and mystery then
		self:addCar(mystery:z())
	end

	if self.isNight:read() and self.halloweenActivity:read() and not self.fixCar then
		local steryShop = self.bgPanel:get("steryShop")

		if steryShop then
			steryShop:hide()
		end

		local chezi = self.bgPanel:getChildByName("chezi")

		if chezi then
			chezi:hide()
		end
	end

	self.refreshBgShade:notify()
end

function CityView:onClickRoleSprite(csvId)
	local roleCfg = gRoleFigureCsv[csvId]
	local effect = self.roleSprite:get("effect")

	if not effect then
		return
	end

	effect:play("act")
	self.roleSprite:setTouchEnabled(false)
	self:showRoleSpeak(csvId, 2)
	effect:setSpriteEventHandler(function(event, eventArgs)
		self.roleSprite:setTouchEnabled(true)
		effect:play("standby_loop1")
	end, sp.EventType.ANIMATION_COMPLETE)
end

function CityView:onClickMidmoon(huodongId, csvId)
	if not csvId then
		gGameUI:showTip(gLanguageCsv.noGiftsToReceiveMidmoon)

		return
	end

	local showOver = {
		false
	}

	gGameApp:requestServerCustom("/game/yy/award/get"):params(huodongId, csvId):onResponse(function(tb)
		showOver[1] = true
	end):wait(showOver):doit(function(tb)
		gGameUI:showGainDisplay(tb)
	end)
end

function CityView:onClickChristmastree(huodongId, csvId)
	local effect = self.shengdanxiong

	if not effect or not csvId then
		gGameUI:showTip(gLanguageCsv.noGiftsToReceiveNow)

		return
	end

	local showOver = {
		false
	}

	gGameApp:requestServerCustom("/game/yy/award/get"):params(huodongId, csvId):onResponse(function(tb)
		local effectGet = self:get("effectGet")

		if not effectGet then
			effectGet = widget.addAnimationByKey(self, "christmastree/shengdanxiong.skel", "effectGet", "lingqu", 150):alignCenter(self:getContentSize()):scale(1.7)
		else
			effectGet:show():play("lingqu")
		end

		effectGet:setSpriteEventHandler(function(event, eventArgs)
			effect:play("daiji_loop")
			effectGet:hide()

			showOver[1] = true
		end, sp.EventType.ANIMATION_COMPLETE)
	end):wait(showOver):doit(function(tb)
		gGameUI:showGainDisplay(tb)
	end)
end

function CityView:onClickQixiAward(huodongId, csvId)
	local effect = self.qixi

	if not effect or not csvId then
		gGameUI:showTip(gLanguageCsv.noGiftsToReceiveNow)

		return
	end

	local showOver = {
		false
	}

	gGameApp:requestServerCustom("/game/yy/award/get"):params(huodongId, csvId):onResponse(function(tb)
		showOver[1] = true
	end):wait(showOver):doit(function(tb)
		gGameUI:showGainDisplay(tb)
	end)
end

function CityView:onClickChunjieDumpling(huodongId, csvId)
	local effect = self.chunjieMan

	if not effect or not csvId then
		gGameUI:showTip(gLanguageCsv.noGiftsToReceiveNow)

		return
	end

	local showOver = {
		false
	}

	gGameApp:requestServerCustom("/game/yy/award/get"):params(huodongId, csvId):onResponse(function(tb)
		showOver[1] = true
	end):wait(showOver):doit(function(tb)
		gGameUI:showGainDisplay(tb)
	end)
end

function CityView:onAllSaintsDaySpine(x, y, index)
	local csvHalloween = csv.yunying.halloween_sprites[index]
	local panel = ccui.Layout:create()
	local halloweenData = halloweenMessages.get()
	local range = csvHalloween.range
	local x = x
	local y = y

	if halloweenData[index] then
		x = halloweenData[index].x
		y = halloweenData[index].y
	end

	panel:setTouchEnabled(true)
	panel:anchorPoint(0.5, 0.5)
	panel:xy(x, y)
	panel:addTo(self.bgPanel, 1000, "halloween")

	local effect

	if csvHalloween.spcialAct ~= 0 and not halloweenData[index] then
		effect = widget.addAnimationByKey(panel, csvHalloween.res, "effect", "standby1_loop", 1000)
	else
		effect = widget.addAnimationByKey(panel, csvHalloween.res, "effect", "standby_loop", 1000)
	end

	local box = effect:box()
	local centerPosX = csvHalloween.normPos[1]
	local dir = x < centerPosX and -1 or 1

	effect:scale(csvHalloween.scale * dir, csvHalloween.scale)
	panel:size(150, 150)
	effect:xy(75, 75)

	if DEBUG_SPRITE_AREA then
		panel:setBackGroundColorType(1)
		panel:setBackGroundColor(cc.c3b(200, 0, 0))
		panel:setBackGroundColorOpacity(100)
	end

	bind.click(self, panel, {
		method = functools.partial(self.onClickhalloweenSpineChange, self, panel, index, dir)
	})

	self.halloweenTab["yexunling" .. index] = panel
end

function CityView:onClickhalloweenSpineChange(targetPanel, index, dir)
	local halloweenData = halloweenMessages.get()
	local csvHalloween = csv.yunying.halloween_sprites[index]
	local isFisrt = false
	local range = csvHalloween.range
	local clickNumTab = csvHalloween.needClick
	local x = math.random(range[1][1], range[2][1])
	local y = math.random(range[1][2], range[2][2])
	local clickNum = math.random(clickNumTab[1], clickNumTab[2])

	if not halloweenData[index] and csvHalloween.spcialAct ~= 0 then
		x = csvHalloween.posClick[1]
		y = csvHalloween.posClick[2]
		isFisrt = true
	end

	halloweenData = halloweenMessages.getHalloweenMessages(halloweenData, x, y, index, clickNum)

	halloweenMessages.set(halloweenData)

	if halloweenMessages.get()[index].num >= halloweenMessages.get()[index].clickNum then
		local panel = targetPanel:clone()

		panel:addTo(self.bgPanel):scale(targetPanel:scaleX(), targetPanel:scaleY()):xy(targetPanel:xy())
		targetPanel:removeSelf()

		self.halloweenTab["yexunling" .. index] = nil

		local effect = panel:getChildByName("effect")

		if not effect then
			effect = widget.addAnimationByKey(panel, csvHalloween.res, "effect", "standby_loop", 1000)

			effect:scale(csvHalloween.scale * dir, csvHalloween.scale)
			effect:xy(75, 75)
		end

		effect:play("effect_xiaoshi")
		effect:setSpriteEventHandler(function(event, eventArgs)
			performWithDelay(self, function()
				panel:removeSelf()
			end, 0)
		end, sp.EventType.ANIMATION_COMPLETE)
		gGameApp:requestServer("/game/yy/award/get", function(tb)
			gGameUI:showGainDisplay(tb)
		end, self.halloweenId, index)
	else
		local effect = targetPanel:getChildByName("effect")

		effect:scale(csvHalloween.scale * dir, csvHalloween.scale)

		if csvHalloween.spcialAct ~= 0 and isFisrt then
			effect:play("effect_tiaochu")
			effect:addPlay("standby_loop")
		else
			effect:play("effect_xiaoshi")
			effect:addPlay("effect_chuxian")
			effect:addPlay("standby_loop")
		end

		if csvHalloween.spcialAct == 2 then
			effect:xy(-400, 500)
		else
			effect:xy(75, 75)
		end

		performWithDelay(self, function()
			if self.halloweenTab["yexunling" .. index] and not tolua.isnull(targetPanel) then
				targetPanel:xy(x, y)

				if csvHalloween.spcialAct ~= 2 then
					local centerPosX = (range[1][1] + range[2][1]) / 2

					if centerPosX > x then
						effect:scaleX(-1 * csvHalloween.scale)
					else
						effect:scaleX(1 * csvHalloween.scale)
					end
				end
			end
		end, 0.5)
	end
end

function CityView:onClickhalloweenSpineMove(x, y, index)
	local csvHalloween = csv.yunying.halloween_sprites[index]
	local range = csvHalloween.range
	local panel = ccui.Layout:create()

	panel:setTouchEnabled(true)

	local halloweenData = halloweenMessages.get()
	local x = x
	local y = y

	if halloweenData[index] then
		x = halloweenData[index].x
		y = halloweenData[index].y
	end

	panel:xy(x, y)
	panel:addTo(self.bgPanel, 1000)

	local effect = widget.addAnimationByKey(panel, csvHalloween.res, "effect", "standby_loop", 1000)
	local box = effect:box()

	panel:size(box.width, box.height)
	effect:xy(box.width / 2, 0)
	effect:scale(csvHalloween.scale)

	if DEBUG_SPRITE_AREA then
		panel:setBackGroundColorType(1)
		panel:setBackGroundColor(cc.c3b(200, 0, 0))
		panel:setBackGroundColorOpacity(100)
	end

	bind.click(self, panel, {
		method = functools.partial(self.onClickhalloweenSpineMoveChange, self, x, y, panel, index)
	})

	self.halloweenTab["nanguajing" .. index] = panel
end

function CityView:onClickhalloweenSpineMoveChange(x, y, targetPanel, index)
	local halloweenData = halloweenMessages.get()

	targetPanel:setTouchEnabled(false)

	local csvHalloween = csv.yunying.halloween_sprites[index]
	local range = csvHalloween.range
	local clickNumTab = csvHalloween.needClick
	local finalPos = csvHalloween.finalPos
	local clickNum = math.random(clickNumTab[1], clickNumTab[2])
	local lenX, lenY = csvHalloween.randDistance[1], csvHalloween.randDistance[2]
	local directionX, directionY, randomNum = halloweenMessages.getSpritesPos(x, y, index)

	lenX = directionX - x
	lenY = directionY - y

	local isFinal = false

	if (halloweenData[index] and halloweenData[index].num + 1 or 1) >= (halloweenData[index] and halloweenData[index].clickNum or clickNum) then
		directionX, directionY = finalPos[1], finalPos[2]
		lenX = directionX - x
		lenY = directionY - y

		if lenX >= 0 and lenY >= 0 then
			randomNum = 1
		elseif lenX >= 0 and lenY < 0 then
			randomNum = 2
		elseif lenX < 0 and lenY < 0 then
			randomNum = 3
		elseif lenX < 0 and lenY >= 0 then
			randomNum = 4
		end

		isFinal = true
	end

	local panel = self.bgPanel:get("tmpNanguajing" .. index)

	if panel then
		panel:removeSelf()
	end

	local panel = targetPanel:clone()

	panel:addTo(self.bgPanel):scale(targetPanel:scale()):xy(targetPanel:xy()):name("tmpNanguajing" .. index)

	local effect = panel:get("effect")

	if not effect then
		effect = widget.addAnimationByKey(panel, csvHalloween.res, "effect", "standby_loop", 1000)

		effect:scale(csvHalloween.scale)

		local box = effect:box()

		effect:xy(box.width / 2, 0)
	end

	effect:play("run_loop")
	targetPanel:removeSelf()

	self.halloweenTab["nanguajing" .. index] = nil

	local function cb(x, y)
		self:unSchedule("nValueChange" .. index)

		if isFinal then
			effect:play("standby_loop")
			performWithDelay(self.bgPanel, function()
				if not tolua.isnull(effect) then
					effect:play("effect_zhuazhu")
				end
			end, 2)
			performWithDelay(self.bgPanel, function()
				panel:removeSelf()
				gGameApp:requestServer("/game/yy/award/get", function(tb)
					gGameUI:showGainDisplay(tb)
				end, self.halloweenId, index)
			end, 3)
		else
			panel:removeSelf()

			halloweenData = halloweenMessages.getHalloweenMessages(halloweenData, x, y, index, clickNum)

			halloweenMessages.set(halloweenData)
			self:onClickhalloweenSpineMove(x, y, index)
		end
	end

	self:enableSchedule():schedule(function()
		local tmp = math.abs(lenY) / math.abs(lenX)
		local tmpRandomX = lenX / 60
		local tmpRandomY = lenY / 60

		tmpRandomX = lenX >= 0 and 4 or -4

		if lenY >= 0 then
			tmpRandomY = 4 * tmp
		else
			tmpRandomY = -4 * tmp
		end

		x = x + tmpRandomX
		y = y + tmpRandomY

		panel:xy(x, y)

		if randomNum == 1 then
			if x + tmpRandomX >= directionX or y + tmpRandomY >= directionY then
				cb(x, y)
			end
		elseif randomNum == 2 then
			if x + tmpRandomX >= directionX or y + tmpRandomY <= directionY then
				cb(x, y)
			end
		elseif randomNum == 3 then
			if x + tmpRandomX <= directionX or y + tmpRandomY <= directionY then
				cb(x, y)
			end
		elseif randomNum == 4 and (x + tmpRandomX <= directionX or y + tmpRandomY >= directionY) then
			cb(x, y)
		end
	end, 0.016666666666666666, 1, "nValueChange" .. index)
end

function CityView:onClickHalloweenCar()
	local yyhuodongs = self.yyhuodongs:read()
	local stamps = yyhuodongs[self.halloweenId] and yyhuodongs[self.halloweenId].stamps or {}
	local canHalloweenGet = stamps[0] == 1

	if not canHalloweenGet then
		gGameUI:showTip(gLanguageCsv.halloweenInDay)

		return
	end

	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.halloweenId, 0)
end

function CityView:onClickHalloweenFour(id, csvId)
	if not csvId then
		gGameUI:showTip(gLanguageCsv.noGiftsToReceiveNow)

		return
	end

	local showOver = {
		false
	}

	gGameApp:requestServerCustom("/game/yy/award/get"):params(id, csvId):onResponse(function(tb)
		local effect = self.shadiao

		if effect then
			effect:play("effect_xiru")
			effect:addPlay("effect_loop")
			effect:setSpriteEventHandler(function(event, eventArgs)
				showOver[1] = true
			end, sp.EventType.ANIMATION_COMPLETE)
		else
			performWithDelay(self, function()
				showOver[1] = true
			end, 2)
		end
	end):wait(showOver):doit(function(tb)
		gGameUI:showGainDisplay(tb)
	end)
end

function CityView:fixCarAndHouse()
	if self.fixCar and self.bgPanel:getChildByName("halloweenBreakCar") then
		if self.bgPanel:get("halloweenBreakCar") then
			self.bgPanel:get("halloweenBreakCar"):removeSelf()
		end

		local effect = widget.addAnimationByKey(self.bgPanel, self.citySceneCfg.halloweenBreakCheName, "halloweenBreakCar", "effect_xiufu", 120):alignCenter(self.bgPanel:getInnerContainerSize()):scale(self.citySceneCfg.halloweenBreakScale):setCascadeOpacityEnabled(true):opacity(0)

		performWithDelay(self, function()
			if self.bgPanel:get("halloweenBreakCar") then
				self.bgPanel:get("halloweenBreakCar"):removeSelf()
			end
		end, 2)
	end

	if self.fixHouse and self.bgPanel:getChildByName("halloweenFang") then
		if self.bgPanel:get("halloweenFang") then
			self.bgPanel:get("halloweenFang"):removeSelf()
		end

		local effect = widget.addAnimationByKey(self.bgPanel, self.citySceneCfg.halloweenBreakFangName, "halloweenFang", "effect_xiufu", 9):alignCenter(self.bgPanel:getInnerContainerSize()):scale(self.citySceneCfg.halloweenBreakScale)

		performWithDelay(self, function()
			if self.bgPanel:get("halloweenFang") then
				self.bgPanel:get("halloweenFang"):removeSelf()
			end
		end, 2)
	end
end

function CityView:onSnowman()
	idlereasy.any({
		self.yyOpen
	}, function(_, yyOpen)
		for _, id in ipairs(yyOpen) do
			local cfg = csv.yunying.yyhuodong[id]

			if cfg.type == YY_TYPE.huoDongCloth then
				self.snowmanId:set(id)

				return
			end
		end

		self.snowmanId:set()
	end):anonyOnly(self)
	idlereasy.any({
		self.yyhuodongs,
		self.snowmanId
	}, function(_, yyhuodongs, snowmanId)
		local panel = self.bgPanel:get("snowman")

		if not snowmanId then
			if panel then
				panel:removeAllChildren()
			end
		else
			local yyData = yyhuodongs[snowmanId] or {}
			local snowLevel = 0

			if yyData.info then
				snowLevel = yyData.info.level
			end

			local yyCfg = csv.yunying.yyhuodong[snowmanId]
			local huodongID = yyCfg.huodongID
			local size = cc.size(500, 540)
			local pos = cc.p(250, 170)

			if not panel then
				panel = ccui.Layout:create():xy(cc.p(980, 180)):size(size):addTo(self.bgPanel, 9, "snowman")

				panel:setTouchEnabled(true)
			else
				panel:removeAllChildren()
			end

			ccui.ImageView:create("activity/snowman/img_cs_snowman.png"):xy(pos):addTo(panel, 30, "snow"):scale(1.6)

			if snowLevel == 0 then
				local tips = ccui.Scale9Sprite:create()

				tips:initWithFile(cc.rect(56, 43, 1, 1), "activity/snowman/box_sd_dialog.png")
				tips:size(190, 87):anchorPoint(0.3, 0):xy(330, 340):addTo(panel, 100, "snowTip")

				local label = cc.Label:createWithTTF(str, "font/youmi1.ttf", 28):color(cc.c4b(255, 255, 255, 255)):xy(90, 48):addTo(tips, 2, "tipText")

				label:text(gLanguageCsv.snowClothEntranceTip)
				tips:width(math.max(190, label:width() + 40))
				label:x(tips:width() / 2)
			end

			panel:get("snow"):setTouchEnabled(false)

			if DEBUG_SPRITE_AREA then
				panel:setBackGroundColorType(1)
				panel:setBackGroundColor(cc.c3b(200, 0, 0))
				panel:setBackGroundColorOpacity(100)
			end

			bind.click(self, panel, {
				method = functools.partial(self.onClickSnowman, self)
			})

			local targets = yyData.targets

			if targets then
				for i = 1, itertools.size(targets) do
					local cfg = csv.yunying.huodongcloth_part[targets[tostring(i)]]
					local panel1 = self.bgPanel:get("snowman"):get("decoration" .. targets[tostring(i)])
					local xPos = cfg.lookPos.x
					local yPos = cfg.lookPos.y

					if not pane1l then
						panel1 = ccui.Layout:create():xy(pos):size(size):addTo(self.bgPanel:get("snowman"), cfg.zOrder, "decoration" .. targets[tostring(i)])

						if cfg.showType == "pic" then
							ccui.ImageView:create(cfg.res):xy(xPos, yPos):addTo(panel1, 1, "decoration"):scale(0.75)
						else
							widget.addAnimationByKey(panel1, cfg.res, "decoration", "night_loop", 120):scale(0.75):xy(xPos, yPos)
						end
					end
				end
			end

			for k, v in orderCsvPairs(csv.yunying.huodongcloth_level) do
				for id, val in orderCsvPairs(csv.yunying.huodongcloth_part) do
					if snowLevel >= v.level and val.huodongID == huodongID and val.belongPart == v.unlockPart and v.unlockPart > 100 then
						local panel1 = self.bgPanel:get("snowman"):get("decoration" .. id)
						local xPos = val.lookPos.x
						local yPos = val.lookPos.y

						if not pane1l then
							panel1 = ccui.Layout:create():xy(pos):size(size):addTo(self.bgPanel:get("snowman"), val.zOrder, "decoration" .. id)

							if val.showType == "pic" then
								ccui.ImageView:create(val.res):xy(xPos, yPos):addTo(panel1, 1, "decoration"):scale(1.6)
							else
								widget.addAnimationByKey(panel1, val.res, "decoration", "night_loop", 120):scale(1.6):xy(xPos, yPos)
							end
						end
					end
				end
			end
		end
	end):anonyOnly(self)
end

function CityView:onClickSnowman()
	local snowmanId = self.snowmanId:read()

	if snowmanId then
		gGameApp:requestServer("/game/yy/cloth/main", function(tb)
			gGameUI:stackUI("city.activity.snowman", nil, nil, snowmanId)
		end, snowmanId)
	end
end

function CityView:onFreezeSprite(data)
	local csvId = data.id
	local res = data.res
	local panel = self.citySpriteDatas[csvId].target
	local size = panel:size()

	local function recover(panel, effect, spriteUnfreezeData)
		local state = spriteUnfreezeData.state
		local clickCount = spriteUnfreezeData.clickCount

		panel:stopActionByTag(UNFREEZE_ACTION_TAG)

		if state > 1 then
			local action = performWithDelay(panel, function()
				panel:stopActionByTag(UNFREEZE_ACTION_TAG)

				state = 1
				clickCount = 0
				spriteUnfreezeData.state = state
				spriteUnfreezeData.clickCount = clickCount

				effect:play("effect_loop")

				local freezeRecoverBg = widget.addAnimationByKey(panel, res, "freezeRecoverBg", "BK_huifu_hou", 0):scale(2):xy(size.width / 2, 0)
				local freezeRecoverFg = widget.addAnimationByKey(panel, res, "freezeRecoverFg", "BK_huifu_qian", 2):scale(2):xy(size.width / 2, 0)

				freezeRecoverFg:setSpriteEventHandler()
				freezeRecoverFg:setSpriteEventHandler(function()
					freezeRecoverFg:setSpriteEventHandler()
					performWithDelay(panel, function()
						freezeRecoverBg:removeFromParent()
						freezeRecoverFg:removeFromParent()
						effect:play("JS_bingdong" .. state .. "_loop")
					end, 0)
				end, sp.EventType.ANIMATION_COMPLETE)
			end, UNFREEZE_TIME)

			action:setTag(UNFREEZE_ACTION_TAG)
		end
	end

	local spriteUnfreezeData = self.spriteUnfreezeData[csvId]
	local state = spriteUnfreezeData.state

	if UNFREEZE_CLICKS[state] then
		local effect = panel:get("effect")

		effect:play("JS_bingdong" .. state .. "_loop")
		recover(panel, effect, spriteUnfreezeData)
	end

	bind.click(self, panel, {
		method = function()
			if not self.citySpriteDatas[csvId] then
				return
			end

			local panel = self.citySpriteDatas[csvId].target
			local effect = panel:get("effect")
			local size = panel:size()
			local spriteUnfreezeData = self.spriteUnfreezeData[csvId]
			local state = spriteUnfreezeData.state
			local clickCount = spriteUnfreezeData.clickCount

			if UNFREEZE_CLICKS[state] then
				local freezeEffect = panel:get("freezeEffect")

				freezeEffect = freezeEffect or widget.addAnimation(panel, "zhuchangjing/bingbao.skel", "bingbao", 10):alignCenter(size)

				local freezeRecoverFg = panel:get("freezeRecoverFg")

				if freezeRecoverFg then
					freezeRecoverFg:stopAllActions()
					freezeRecoverFg:removeFromParent()
					panel:get("freezeRecoverBg"):removeFromParent()
					effect:play("JS_bingdong" .. state .. "_loop")
				end

				freezeEffect:play("bingbao")

				clickCount = clickCount + 1
				spriteUnfreezeData.clickCount = clickCount

				if clickCount >= UNFREEZE_CLICKS[state] then
					state = state + 1
					spriteUnfreezeData.state = state

					if not UNFREEZE_CLICKS[state] then
						state = 0
						spriteUnfreezeData.state = state

						effect:play("effect_loop")

						local yydata = self.spriteUnfreezeYYData:read()
						local yyId = yydata.yyId

						self:onUnfreezeAward(yyId, csvId)
					else
						effect:play("JS_bingdong" .. state .. "_loop")
					end
				end

				recover(panel, effect, spriteUnfreezeData)
			end
		end
	})
end

function CityView:onUnfreezeAward(yyID, csvId)
	if not yyID or not csvId then
		return
	end

	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, yyID, csvId)
end

function CityView:dailyAssistantTip()
	dataEasy.getListenShow("dailyAssistant", function(show)
		if not show then
			return
		end

		local dailyAssistantPanel = self.bgPanel:getChildByName("dailyAssistantPanel")

		if dailyAssistantPanel == nil then
			dailyAssistantPanel = ccui.Layout:create()

			dailyAssistantPanel:setTouchEnabled(true)
			dailyAssistantPanel:addTo(self.bgPanel, 20, "dailyAssistantPanel")
			dailyAssistantPanel:xy(2100, 700)
			dailyAssistantPanel:anchorPoint(0.5, 0)

			local scaleAll = 1.4
			local obj = widget.addAnimationByKey(dailyAssistantPanel, "luotuomutujian/luotuomutujian.skel", "luotuomutujian", "effect_loop", 1)

			obj:anchorPoint(cc.p(0.5, 0.5))
			obj:scale(scaleAll)

			local box = obj:box()

			box.width = box.width * scaleAll
			box.height = box.height * scaleAll

			obj:xy(box.width / 2, -50)
			dailyAssistantPanel:size(box.width, box.height)

			if DEBUG_SPRITE_AREA then
				dailyAssistantPanel:setBackGroundColorType(1)
				dailyAssistantPanel:setBackGroundColor(cc.c3b(200, 0, 0))
				dailyAssistantPanel:setBackGroundColorOpacity(100)
			end

			bind.click(self, dailyAssistantPanel, {
				method = function()
					jumpEasy.jumpTo("dailyAssistant")
				end
			})
			bind.extend(self, dailyAssistantPanel, {
				class = "red_hint",
				props = {
					specialTag = "dailyAssistant",
					onNode = function(node)
						node:xy(box.width - 10, box.height - 10)
						node:scale(0.8)
					end
				}
			})

			local tipDatas = {}

			for i = 1, math.huge do
				local tip = gLanguageCsv["dailyAssistantShowTips" .. i]

				if tip == nil then
					break
				end

				table.insert(tipDatas, tip)
			end

			local offPos = {
				y = 0,
				x = 250
			}

			local function showTip()
				local redHint = dailyAssistantPanel:getChildByName("_redHint_")

				if not redHint or not redHint:visible() then
					return
				end

				local idx = math.random(1, #tipDatas)
				local txt = rich.createByStr("#C0x5b545b#" .. tipDatas[idx], 40):anchorPoint(0.5, 0):xy(box.width / 2 + offPos.x, box.height + 40 + offPos.y):addTo(dailyAssistantPanel, 3, "talkContent"):formatText()
				local size = txt:size()
				local bg = ccui.Scale9Sprite:create()

				bg:initWithFile(cc.rect(75, 59, 1, 1), "city/gate/bg_dialog.png")
				bg:size(size.width + 60, size.height + 60):anchorPoint(0.5, 0):xy(box.width / 2 + offPos.x, box.height + offPos.y):scaleX(-1):addTo(dailyAssistantPanel, 2, "talkBg")

				if self.isNight:read() then
					cache.setColor2Shader(dailyAssistantPanel, false, cc.vec4(0.75, 0.75, 1.2, 1))
				end

				performWithDelay(dailyAssistantPanel, function()
					dailyAssistantPanel:removeChildByName("talkContent")
					dailyAssistantPanel:removeChildByName("talkBg")
				end, 2)
			end

			local animate = cc.Sequence:create(cc.DelayTime:create(8), cc.CallFunc:create(function()
				showTip()
			end))
			local action = cc.RepeatForever:create(animate)

			dailyAssistantPanel:runAction(action)
		end

		dailyAssistantPanel:visible(dataEasy.isShow("dailyAssistant"))

		self.dailyAssistantPanel = dailyAssistantPanel
	end):anonyOnly(self)
end

function CityView:fishingGameTip()
	self.fishPanel = ccui.Layout:create()

	self.fishPanel:setTouchEnabled(true)
	self.fishPanel:addTo(self.bgPanel, 10, "fishing")
	self.fishPanel:xy(1390, 610)
	self.fishPanel:removeAllChildren()

	local obj = widget.addAnimationByKey(self.fishPanel, "fishing/diaoyudasairukou.skel", "diaoyudasai", "effect_loop", 1)

	obj:anchorPoint(cc.p(0.5, 0.5))
	obj:scale(0.8)

	local box = obj:box()

	self.fishPanel:size(box.width, box.height)
	obj:xy(box.width / 2, 0)

	if DEBUG_SPRITE_AREA then
		self.fishPanel:setBackGroundColorType(1)
		self.fishPanel:setBackGroundColor(cc.c3b(200, 0, 0))
		self.fishPanel:setBackGroundColorOpacity(100)
	end

	bind.click(self, self.fishPanel, {
		method = functools.partial(self.fishingClick)
	})
	idlereasy.when(self.crossFishingRound, function(_, crossFishingRound)
		local isUnlock = dataEasy.isUnlock(gUnlockCsv.fishing)

		self.fishPanel:visible(crossFishingRound == "start" and isUnlock == true)
	end):anonyOnly(self)
	self:setFishingGameTimer()
end

function CityView:fishingClick()
	if self.crossFishingRound:read() == "closed" then
		gGameUI:showTip(gLanguageCsv.fishGameNotStart)
		self.fishPanel:hide()

		return
	end

	local function onFishingView()
		gGameApp:requestServer("/game/cross/fishing/rank", function(tb)
			gGameUI:stackUI("city.adventure.fishing.view", nil, {
				full = true
			}, game.FISHING_GAME, tb.view, self:createHandler("onOpenFishingMain"))
		end)
	end

	if self.fishingSelectScene:read() == game.FISHING_GAME then
		onFishingView()
	elseif self.fishingIsAuto:read() then
		gGameUI:stackUI("city.adventure.fishing.auto", nil, {
			clickClose = false,
			blackLayer = true
		}, game.FISHING_GAME, self:createHandler("onOpenView"))
	else
		gGameApp:requestServer("/game/fishing/prepare", onFishingView, "scene", game.FISHING_GAME)
	end
end

function CityView:setFishingGameTimer()
	local timer = {
		18015,
		82800
	}

	timer[#timer + 1] = timer[1] + 86400

	local currTime = time.getNowDate()
	local currSec = currTime.hour * 3600 + currTime.min * 60 + currTime.sec
	local delta = 1

	for i = 1, #timer do
		if currSec < timer[i] then
			delta = timer[i] - currSec + 1

			break
		end
	end

	performWithDelay(self, function()
		gGameApp:slientRequestServer("/game/sync", functools.handler(self, "setFishingGameTimer"))
	end, delta)
end

function CityView:onOpenView()
	if self.crossFishingRound:read() == "closed" then
		gGameUI:showTip(gLanguageCsv.fishGameNotStart)
		self.fishPanel:hide()

		return
	end

	gGameApp:requestServer("/game/fishing/prepare", function(tb)
		gGameApp:requestServer("/game/cross/fishing/rank", function(tb)
			gGameUI:stackUI("city.adventure.fishing.view", nil, {
				full = true
			}, game.FISHING_GAME, tb.view, self:createHandler("onOpenFishingMain"))
		end)
	end, "scene", game.FISHING_GAME)
end

function CityView:onOpenFishingMain()
	gGameUI:stackUI("city.adventure.fishing.sence_select", nil, {
		full = true
	})
end

function CityView:onClickSprite(data)
	local info = self.citySpriteDatas[data.csvId]
	local showOver = {
		false
	}

	local function callback()
		showOver[1] = true
	end

	local giftType = 3

	if not info.isBaibian and not info.isMiniQ then
		if self.spriteGiftTimes:read() < 3 and not info.isGetGift then
			function callback(tb)
				info.target:setTouchEnabled(true)

				if data.cfg.action then
					self:showRoleSpeak(data.csvId, 1)

					local effect = info.target:getChildByName("effect")

					if effect then
						effect:play("effect")
						effect:setSpriteEventHandler(function(event, eventArgs)
							effect:play("effect_loop")
						end, sp.EventType.ANIMATION_COMPLETE)
					end
				end

				showOver[1] = true
				self.citySpriteDatas[data.csvId].isGetGift = true
			end
		elseif data.cfg.action then
			local effect = info.target:getChildByName("effect")

			if effect then
				effect:play("effect")
				self:showRoleSpeak(data.csvId, 1)
				effect:setSpriteEventHandler(function(event, eventArgs)
					effect:play("effect_loop")
				end, sp.EventType.ANIMATION_COMPLETE)
			end

			return
		end
	elseif info.isBaibian and not info.isGet then
		giftType = 1

		function callback(tb)
			local effect = info.target:getChildByName("effect")

			if effect then
				effect:hide()

				local allNames = {
					"effect_jingya",
					"effect_shengqi",
					"effect_kaixin"
				}
				local effectName = allNames[math.random(1, 3)]
				local baibianEft = widget.addAnimationByKey(info.target, "zhuchangjing/zjm_bbg.skel", "changeEft", effectName, 1):xy(effect:xy())

				baibianEft:setSpriteEventHandler(function(event, eventArgs)
					info.target:setTouchEnabled(true)

					self.citySpriteDatas[data.csvId].isGet = true
					showOver[1] = true
				end, sp.EventType.ANIMATION_COMPLETE)
			end
		end
	elseif info.isMiniQ then
		giftType = 2

		function callback(tb)
			local effect = info.target:getChildByName("effect")

			if effect then
				effect:play("effect")
				effect:setSpriteEventHandler(function(event, eventArgs)
					performWithDelay(self, function()
						info.target:removeFromParent()

						self.citySpriteDatas[data.csvId] = nil
						showOver[1] = true
					end, 0.016666666666666666)
				end, sp.EventType.ANIMATION_COMPLETE)
			end
		end
	end

	info.target:setTouchEnabled(false)
	gGameApp:requestServerCustom("/game/role/city/sprite/gift"):params(data.csvId, giftType):onResponse(function()
		if tolua.isnull(info.target) then
			showOver[1] = true
		else
			callback()
		end
	end):wait(showOver):doit(function(tb)
		gGameUI:showGainDisplay(tb)
	end)
end

function CityView:initHalloween()
	self.halloweenActivity = idler.new(false)
	self.halloweenDailyAward = idler.new(false)
	self.halloweenAllSpriteClicked = idler.new()
end

function CityView:setHalloweenMoveSprites()
	self.fixHouse = true
	self.fixCar = true

	self.halloweenAllSpriteClicked:set(true)

	local yyhuodongs = self.yyhuodongs:read()
	local stamps = yyhuodongs[self.halloweenId] and yyhuodongs[self.halloweenId].stamps or {}
	local moveSprites = 0

	for k, v in pairs(stamps) do
		if k ~= 0 then
			local cfg = csv.yunying.halloween_sprites[k]

			if cfg.type == 1 then
				if cfg.buildNum == 1 and v ~= 0 then
					self.fixHouse = false

					self.halloweenAllSpriteClicked:set(false)
				end

				if cfg.buildNum == 2 and v ~= 0 then
					self.fixCar = false

					self.halloweenAllSpriteClicked:set(false)
				end
			elseif v == 0 then
				moveSprites = moveSprites + 1
			else
				self.halloweenAllSpriteClicked:set(false)
			end
		end
	end

	for k, v in pairs(stamps) do
		if k ~= 0 and v == 1 then
			local cfg = csv.yunying.halloween_sprites[k]
			local randomNum = math.random(csvSize(cfg.pos))
			local x = cfg.pos[randomNum][1]
			local y = cfg.pos[randomNum][2]

			if cfg.type == 1 then
				self:onAllSaintsDaySpine(x, y, k)
			elseif cfg.type == 2 and self.fixHouse and self.fixCar then
				self:onClickhalloweenSpineMove(x, y, k)
			end
		end
	end

	local panel = self.bgPanel:get("halloweenCar")
	local effect = panel:get("halloweenCar")

	if moveSprites == 1 then
		effect:play("night_deng1_bianhua")
		effect:addPlay("night_po_hou1_loop")
	end

	if moveSprites == 2 then
		if stamps[0] == 1 then
			effect:play("night_deng2_bianhua")
			effect:addPlay("night_hao_loop")
		else
			effect:play("night_loop")
		end
	end
end

function CityView:onHalloween()
	self.halloweenTab = {}

	idlereasy.any({
		self.yyOpen
	}, function(_, yyOpen)
		self.halloweenActivity:set(false)

		for _, id in ipairs(yyOpen) do
			local cfg = csv.yunying.yyhuodong[id]
			local clientType = cfg.clientParam.type

			if clientType == "halloween" and cfg.type == YY_TYPE.halloween then
				self.halloweenId = id

				self.halloweenActivity:set(true)

				break
			end
		end
	end):anonyOnly(self)
	idlereasy.any({
		self.isNight,
		self.halloweenActivity,
		self.yyhuodongs
	}, function(_, isNight, halloweenActivity, yyhuodongs)
		for _, v in pairs(self.halloweenTab) do
			v:removeSelf()
		end

		self.halloweenTab = {}

		if self.bgPanel:get("halloweenFang") then
			self.bgPanel:get("halloweenFang"):removeSelf()
		end

		if self.bgPanel:get("halloweenShan") then
			self.bgPanel:get("halloweenShan"):removeSelf()
		end

		if self.bgPanel:get("halloweenBreakCar") then
			self.bgPanel:get("halloweenBreakCar"):removeSelf()
		end

		if self.bgPanel:get("halloweenCar") then
			self.bgPanel:get("halloweenCar"):removeSelf()
		end

		local steryShop = self.bgPanel:get("steryShop")

		if steryShop then
			steryShop:show()
		end

		local chezi = self.bgPanel:get("chezi")

		if chezi then
			chezi:show()
		end

		if halloweenActivity then
			self:addHalloweenCar()

			if isNight then
				self:setHalloweenMoveSprites()
				widget.addAnimationByKey(self.bgPanel, self.citySceneCfg.halloweenBreakShanName, "halloweenShan", "effect_loop", 100):alignCenter(self.bgPanel:getInnerContainerSize()):scale(self.citySceneCfg.halloweenBreakScale)

				if not self.fixHouse then
					widget.addAnimationByKey(self.bgPanel, self.citySceneCfg.halloweenBreakFangName, "halloweenFang", "effect_loop", 9):alignCenter(self.bgPanel:getInnerContainerSize()):scale(self.citySceneCfg.halloweenBreakScale)
				end

				if not self.fixCar then
					local steryShop = self.bgPanel:get("steryShop")

					if steryShop then
						steryShop:hide()
					end

					local chezi = self.bgPanel:get("chezi")

					if chezi then
						chezi:hide()
					end

					self:addBreakCar()
				end

				self:fixCarAndHouse()
			end
		end
	end):anonyOnly(self)
end

function CityView:addBreakCar()
	local breakCar = widget.addAnimationByKey(self.bgPanel, self.citySceneCfg.cheziEffectName, "halloweenBreakCar", "night_loop", 100):alignCenter(self.bgPanel:getInnerContainerSize()):scale(2):setCascadeOpacityEnabled(true):opacity(0)

	widget.addAnimationByKey(breakCar, self.citySceneCfg.halloweenBreakCheName, "effect", "effect_loop", 120):scale(self.citySceneCfg.halloweenBreakScale / 2):setCascadeOpacityEnabled(true):opacity(255)
	transition.fadeIn(breakCar, {
		time = 1
	})
end

function CityView:addHalloweenCar()
	local panel = self.bgPanel:get("halloweenCar")

	if not panel then
		panel = ccui.Layout:create():xy(self.citySceneCfg.halloweenCarPos):size(850, 800):addTo(self.bgPanel, 200, "halloweenCar")

		panel:setTouchEnabled(true)

		local name = self.isNight:read() and "night_po_loop" or "day_loop"

		widget.addAnimationByKey(panel, "wanshengjie/wsj_nanguache.skel", "halloweenCar", name, 120):scale(2):xy(500, 200)

		if DEBUG_SPRITE_AREA then
			panel:setBackGroundColorType(1)
			panel:setBackGroundColor(cc.c3b(200, 0, 0))
			panel:setBackGroundColorOpacity(100)
		end

		bind.click(self, panel, {
			method = functools.partial(self.onClickHalloweenCar, self)
		})
	else
		panel:xy(self.citySceneCfg.halloweenCarPos)
	end
end

function CityView:onLightingNewYear()
	local idx = dataEasy.getCitySceneIdx()

	if idx ~= 4 then
		return
	end

	idlereasy.any({
		self.yyOpen
	}, function(_, yyOpen)
		for _, id in ipairs(yyOpen) do
			local cfg = csv.yunying.yyhuodong[id]

			if cfg.type == YY_TYPE.lightingNewYear then
				self.lightingNewYearId:set(id)

				return
			end
		end

		self.lightingNewYearId:set()
	end):anonyOnly(self)
	idlereasy.any({
		self.yyhuodongs,
		self.lightingNewYearId
	}, function(_, yyhuodongs, id)
		self.lightingNewYearSprite = nil
		self.effects.lightingNewYear = nil

		local panel = self.bgPanel:get("lightingNewYear")

		if panel then
			panel:removeSelf()
		end

		panel = ccui.Layout:create():xy(4850, 350):size(1700, 800):addTo(self.bgPanel, 9, "lightingNewYear")

		panel:setTouchEnabled(true)

		if DEBUG_SPRITE_AREA then
			panel:setBackGroundColorType(1)
			panel:setBackGroundColor(cc.c3b(200, 0, 0))
			panel:setBackGroundColorOpacity(100)
		end

		local effect = widget.addAnimation(panel, "xinchundenglong/xinchundenglong.skel", "day_loop", 1):xy(850, 150)

		self.effects.lightingNewYear = effect

		if id then
			local animaCfg = {}
			local huodongID = csv.yunying.yyhuodong[id].huodongID

			for i, v in orderCsvPairs(csv.yunying.lighting_new_year) do
				if huodongID == v.huodongID and not animaCfg[v.day] then
					table.insert(animaCfg, v)
				end
			end

			local csvId = dataEasy.getLightingNewYearCsvId(id)

			for i, v in ipairs(animaCfg) do
				local cfg = csv.yunying.lighting_new_year[csvId]

				if cfg and cfg.day == i then
					local scaleX = animaCfg[i].particleData.scaleX or 1
					local scaleX, scaleY = scaleX, animaCfg[i].particleData.scaleY or 1

					if animaCfg[i].particleData.scale then
						scaleX, scaleY = animaCfg[i].particleData.scale, animaCfg[i].particleData.scale
					end

					widget.addAnimationByKey(effect, "xinchundenglong/xinchundenglong.skel", "lizi" .. i, "lizi_loop", 100):xy(animaCfg[i].particleData):scale(scaleX, scaleY)
				end
			end

			bind.click(self, panel, {
				method = functools.partial(self.onClickLightingNewYear, self)
			})
			self:onLightingNewYearSprite(id)
			self.refreshBgShade:notify()
		end

		idlereasy.when(self.isNight, function(_, isNight)
			if self.bgPanel:get("lightingNewYearObj16") then
				self.bgPanel:get("lightingNewYearObj16"):removeSelf()
			end

			if id then
				if effect then
					effect:removeChildByName("obj16")

					local animaCfg = {}
					local huodongID = csv.yunying.yyhuodong[id].huodongID

					for i, v in orderCsvPairs(csv.yunying.lighting_new_year) do
						if huodongID == v.huodongID and not animaCfg[v.day] then
							table.insert(animaCfg, v)
						end
					end

					local yyData = yyhuodongs[id] or {}
					local days = yyData.info and yyData.info.days or 0
					local stamps = yyData.stamps or {}

					if days == 16 then
						if stamps[16] ~= 1 or not isNight then
							local spineName = animaCfg[16].spine2

							widget.addAnimationByKey(effect, "xinchundenglong/xinchundenglong.skel", "obj16", spineName, animaCfg[16].zOrder)
						else
							widget.addAnimationByKey(self.bgPanel, "xinchundenglong/kmd.skel", "lightingNewYearObj16", "night_loop", 0):xy(3050, 650):scale(2)
						end
					end
				end
			else
				local nowDate = time.getNowDate()
				local flag = userDefault.getForeverLocalKey("lightingNewYearFlag" .. tostring(nowDate.year), false)

				if flag then
					for i, v in orderCsvPairs(csv.yunying.lighting_new_year) do
						if v.day == 16 then
							if not isNight then
								widget.addAnimationByKey(effect, "xinchundenglong/xinchundenglong.skel", "obj16", v.spine2, v.zOrder)

								break
							end

							widget.addAnimationByKey(self.bgPanel, "xinchundenglong/kmd.skel", "lightingNewYearObj16", "night_loop", 0):xy(3050, 650):scale(2)

							break
						end
					end
				end
			end
		end):anonyOnly(self)
	end):anonyOnly(self)
end

function CityView:onLightingNewYearSprite(id)
	local csvId = dataEasy.getLightingNewYearCsvId(id)
	local panel = self.bgPanel:get("lightingNewYear")
	local box = cc.size(500, 500)
	local spritePanel = ccui.Layout:create():size(box):xy(200, 50):anchorPoint(0.5, 0):addTo(panel, 100, "sprite")

	spritePanel:setTouchEnabled(false)
	spritePanel:stopAllActions()

	local effectName = csvId == 0 and "hhb_standby_loop" or "hhb_diandeng2_loop"

	widget.addAnimationByKey(spritePanel, "xinchundenglong/hhb.skel", "effect", effectName, 1):xy(200, 50):scale(-0.75, 0.75)

	self.lightingNewYearSprite = spritePanel

	if not csvId then
		if DEBUG_SPRITE_AREA then
			spritePanel:setBackGroundColorType(1)
			spritePanel:setBackGroundColor(cc.c3b(200, 0, 0))
			spritePanel:setBackGroundColorOpacity(100)
		end

		spritePanel:setTouchEnabled(true)
		spritePanel:xy(-2000, -150)

		local effect = spritePanel:get("effect")

		effect:play("hhb_standby_loop")
		effect:scale(0.75, 0.75)
		bind.click(self, spritePanel, {
			method = functools.partial(self.onClickLightingNewYearSprite, self, id)
		})

		local offPos = {
			y = 60,
			x = 100
		}
		local txt = rich.createByStr("#C0x5b545b#" .. gLanguageCsv.cityLightingNewYearTip2, 40):anchorPoint(0.5, 0):xy(box.width / 2 + offPos.x, box.height / 2 + 40 + offPos.y):addTo(spritePanel, 3, "talkContent"):formatText():hide()
		local size = txt:size()
		local bg = ccui.Scale9Sprite:create()

		bg:initWithFile(cc.rect(75, 59, 1, 1), "city/gate/bg_dialog.png")
		bg:size(size.width + 60, size.height + 60):anchorPoint(0.5, 0):xy(box.width / 2 + offPos.x, box.height / 2 + offPos.y):scaleX(-1):addTo(spritePanel, 2, "talkBg"):hide()

		local function showTip()
			txt:show()
			bg:show()
			performWithDelay(spritePanel, function()
				txt:hide()
				bg:hide()
			end, 3)
		end

		spritePanel:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.DelayTime:create(7), cc.CallFunc:create(showTip))))
	end

	return spritePanel
end

function CityView:onClickLightingNewYearSprite(id)
	local sprite = self.lightingNewYearSprite

	if sprite then
		gGameUI:disableTouchDispatch(2)
		sprite:stopAllActions()
		sprite:removeChildByName("talkContent")
		sprite:removeChildByName("talkBg")
		transition.executeSequence(sprite, true):scaleTo(0.1, 0, 0):func(function()
			self.bgPanel:scrollToPercentHorizontal(100, 1.8, false)
		end):delay(1):func(function()
			sprite:xy(200, 50)

			local effect = sprite:get("effect")

			effect:play("hhb_diandeng2_loop")
			effect:scale(-0.75, 0.75)
		end):scaleTo(0.1, 1, 1):func(function()
			local nowDate = time.getNowDate()

			userDefault.setForeverLocalKey("lightingNewYearFlag" .. tostring(nowDate.year), true)
			self.lightingNewYearId:notify()
		end):done()
	end
end

function CityView:onClickLightingNewYear()
	local yyid = self.lightingNewYearId:read()

	if yyid then
		local csvId = dataEasy.getLightingNewYearCsvId(yyid)

		if not csvId then
			gGameUI:showTip(gLanguageCsv.cityLightingNewYearTip1)

			return
		end

		gGameUI:stackUI("city.activity.lighting_new_year.view", nil, {
			full = true
		}, yyid)
	end
end

function CityView:initFloowPanel()
	self.followPanel:hide()

	local panel = ccui.Layout:create()

	panel:xy(1750, 460)
	panel:addTo(self.bgPanel, 11, "followCardPanel")
	dataEasy.getListenUnlock(gUnlockCsv.followSprite, function(isUnlock)
		if isUnlock then
			self.followCardId = gGameModel.role:getIdler("follow_sprite")

			idlereasy.when(self.followCardId, function(_, followCardId)
				local cardIdler = gGameModel.cards:find(followCardId[1])
				local cardSpine = self.bgPanel:get("followCardPanel.card")

				if cardIdler then
					local cardData = cardIdler:read("card_id", "unit_id", "skin_id")
					local unitCfg = dataEasy.getUnitCsv(cardData.card_id, cardData.skin_id)

					if cardSpine then
						local a, b = cardData, cardSpine.cardData

						if b == nil or a.card_id ~= b.card_id or a.skin_id ~= b.skin_id then
							self.bgPanel:get("followCardPanel"):removeChildByName("card")

							cardSpine = nil
						end
					end

					if not cardSpine then
						cardSpine = widget.addAnimationByKey(self.bgPanel:get("followCardPanel"), unitCfg.unitRes, "card", "standby_loop", 9)

						cardSpine:xy(unitCfg.followSpinePos.x, unitCfg.followSpinePos.y):scaleY(unitCfg.scale * unitCfg.followSpineScale):scaleX(-unitCfg.scale * unitCfg.followSpineScale):setSkin(unitCfg.skin)

						cardSpine.isTintBlack = gStandbyEffectOptionCsv[unitCfg.unitRes]
						cardSpine.cardData = cardData
					end

					self.followPanel:get("add"):hide()
					self.followPanel:get("icon"):texture(unitCfg.cardIcon):show()
					self.refreshBgShade:notify()
				else
					self.bgPanel:get("followCardPanel"):removeChildByName("card")
					self.followPanel:get("add"):show()
					self.followPanel:get("icon"):hide()
				end
			end):anonyOnly(self)
			self.followPanel:show()
		end
	end):anonyOnly(self)
end

function CityView:onFollowClick()
	self.actionExpandName:set("")

	local dx = display.sizeInView.width * 0.3
	local size = self.bgPanel:size()
	local innerSize = self.bgPanel:getInnerContainerSize()
	local percent = self.bgPanel:get("role"):x()
	local percent = (self.bgPanel:get("role"):x() - (400 + display.uiOrigin.x + dx) / FOLLOW_SCALE) / (innerSize.width - size.width)
	local sequence = cc.Sequence:create(cc.Spawn:create(cc.CallFunc:create(function()
		gGameUI:disableTouchDispatch(nil, false)
	end), cc.ScaleTo:create(FOLLOW_MOVETIME, FOLLOW_SCALE), cc.MoveTo:create(FOLLOW_MOVETIME, cc.p(-dx, -display.sizeInViewRect.height * 0.33)), cc.CallFunc:create(function()
		self.bgPanel:scrollToPercentHorizontal(percent * 100, FOLLOW_MOVETIME, false)
		self:allPanelFadeout(0.8, true)
		self:updateAllStatue(false)
	end)), cc.CallFunc:create(function()
		gGameUI:stackUI("city.follow", nil, {
			full = false
		}, {
			panel = self.bgPanel,
			cb = self:createHandler("followCb")
		})
	end))

	self.bgPanel:runAction(sequence)
end

function CityView:followCb()
	local sequenceCb = cc.Sequence:create(cc.Spawn:create(cc.ScaleTo:create(FOLLOW_MOVETIME, 1), cc.MoveTo:create(FOLLOW_MOVETIME, display.sizeInViewRect)))

	self:updateAllStatue(true)
	self.bgPanel:runAction(sequenceCb)
end

local function opacityAction(widget, moveTime, type)
	transition.executeSpawn(widget, true):fadeTo(moveTime, type and 0 or 255):done()

	for _, child in pairs(widget:getChildren()) do
		opacityAction(child, moveTime, type)
	end
end

function CityView:initFadeOutDatas()
	self.fadeOutPanels = {
		{
			panel = {
				self.leftTopPanel,
				self.followPanel,
				self.rightPanel,
				self.cityTopView:get("Panel")
			},
			move = cc.p(0, 800)
		},
		{
			panel = {
				self.leftPanel
			},
			move = cc.p(-400, 0)
		},
		{
			panel = {
				self.rightBottomPanel,
				self.growGuide,
				self.activityTip
			},
			move = cc.p(600, 0)
		},
		{
			panel = {
				self.leftBottomPanel,
				self.centerBottomPanel
			},
			move = cc.p(0, -400)
		}
	}

	for idx1, panels in ipairs(self.fadeOutPanels) do
		for idx2, panel in ipairs(panels.panel) do
			self.fadeOutPanels[idx1].panel[idx2].orgPos = cc.p(panel:xy())
			self.fadeOutPanels[idx1].panel[idx2].fadePos = cc.p(panel.orgPos.x + panels.move.x, panel.orgPos.y + panels.move.y)
		end
	end
end

function CityView:allPanelFadeout(moveTime, type)
	for idx, panels in ipairs(self.fadeOutPanels) do
		for _, panel in ipairs(panels.panel) do
			opacityAction(panel, moveTime, type)
			panel:runAction(cc.MoveTo:create(moveTime, type and panel.fadePos or panel.orgPos))
		end
	end
end

function CityView:updateAllStatue(type)
	if type then
		self:allPanelFadeout(0.5)

		for _, child in ipairs(self.bgPanel:getChildren()) do
			if self.bgPanelStatue[child:name()] then
				opacityAction(child, 0.8, false)
			end
		end
	else
		self.bgPanelStatue = {}

		for j, child in ipairs(self.bgPanel:getChildren()) do
			local name = child:name()

			self.bgPanelStatue[name] = {
				visible = child:isVisible()
			}

			if not self.effects[name] and not itertools.include(FOLLOW_TYPE, name) then
				opacityAction(child, 0.8, true)
			end
		end
	end

	self.bgPanel:setTouchEnabled(type)
end

function CityView:initAutoChessEntrance()
	dataEasy.getListenUnlock(gUnlockCsv.autoChess, function(isUnlock)
		self.bgPanel:removeChildByName("autoChessEntrance")
		self.bgPanel:removeChildByName("autoChessEntranceRedHint")

		if isUnlock then
			local panel = ccui.Layout:create():size(1000, 650):anchorPoint(0.5, 0.5)

			panel:xy(700, 800)
			panel:addTo(self.bgPanel, 1, "autoChessEntrance")

			if DEBUG_SPRITE_AREA then
				panel:setBackGroundColorType(1)
				panel:setBackGroundColor(cc.c3b(200, 0, 200))
				panel:setBackGroundColorOpacity(100)
			end

			panel:setTouchEnabled(true)
			bind.click(self, panel, {
				method = function()
					jumpEasy.jumpTo("autoChess")
				end
			})

			local redHintPanel = ccui.Layout:create():anchorPoint(0.5, 0.5):xy(700, 850)

			redHintPanel:addTo(self.bgPanel, 99, "autoChessEntranceRedHint")
			bind.extend(self, redHintPanel, {
				class = "red_hint",
				props = {
					specialTag = {
						"autoChessAchievement",
						"autoChessTrainerDailyHint"
					},
					onNode = function(node)
						node:xy(120, 320)
					end
				}
			})
		end
	end):anonyOnly(self)
end

return function(cls)
	for k, v in pairs(CityView) do
		cls[k] = v
	end
end
