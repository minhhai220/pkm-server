-- chunkname: @src.battle.app_views.battle.module.stage

local Stage = class("Stage", battleModule.CBase)

function Stage:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.frontStageLayer = self.parent.frontStageLayer
	self.stageLayer = self.parent.stageLayer
	self.stage = nil
end

function Stage:setStage(res, resType)
	if self.stage then
		self.stage:removeFromParent()
	end

	local sprite = newCSpriteWithOption(res)

	sprite:setAnchorPoint(cc.p(0, 0))
	sprite:setPosition(display.center)

	if resType == 2 then
		self.frontStageLayer:add(sprite)
	else
		self.stageLayer:add(sprite)
	end

	self.stage = sprite

	return sprite
end

function Stage:onAddGround(arg)
	local spos = cc.p(arg.x, arg.y)

	for i = 1, arg.xtileSize do
		spos.y = arg.y

		for j = 1, arg.ytileSize do
			local sprite = self:setStage(arg.config.res, arg.config.resType):scale(arg.config.scale)
			local oldPosX, oldPosY = sprite:getPosition()

			sprite:setPosition(cc.pAdd(cc.p(oldPosX, oldPosY), spos))

			if sprite:isSpine() then
				if arg.config.aniName then
					sprite:play(arg.config.aniName)
					sprite:addPlay("effect_loop")
				else
					sprite:play("effect_loop")
				end

				sprite:setAnimationSpeedScale(arg.config.frameScale, true)
			end

			sprite:setName(arg.id .. i * arg.ytileSize + j)
		end

		spos.x = spos.x + arg.xlength
	end
end

function Stage:onMoveGround(arg)
	local spos = cc.p(arg.x, arg.y)

	for i = 1, arg.xtileSize do
		spos.y = arg.y

		for j = 1, arg.ytileSize do
			local name = arg.id .. i * arg.ytileSize + j
			local bg

			if arg.config.resType == 2 then
				bg = self.frontStageLayer:get(name)
			else
				bg = self.stageLayer:get(name)
			end

			bg:setPosition(spos)

			spos.y = spos.y + arg.ylength
		end

		spos.x = spos.x + arg.xlength
	end
end

function Stage:onUltSkillPreAni1()
	self.parent.subModuleNotify:notify("showMain", false)
	self.parent.subModuleNotify:notify("showSpec", false)
	self.parent.subModuleNotify:notify("showLinkEffect", false)
end

function Stage:onUltSkillPreAni2(id, skillCfg, hideHero, combineSkillCfg)
	local bg = newCSpriteWithOption(battle.StageRes.cutRes)
	local bg2 = newCSpriteWithOption(battle.StageRes.cutRes)
	local st = newCSpriteWithOption(battle.StageRes.cutRes)
	local hero = newCSprite("config/big_hero/normal/" .. skillCfg.effectBigName[1] .. ".png")
	local heroBg = newCSprite("config/big_hero/normal/" .. skillCfg.effectBigName[1] .. ".png")
	local combSt, combHero, combHeroBg
	local isCombineSkill = skillCfg.skillType == battle.SkillType.NormalCombine

	if isCombineSkill then
		combHero = newCSprite("config/big_hero/normal/" .. combineSkillCfg.effectBigName[1] .. ".png")
		combHeroBg = newCSprite("config/big_hero/normal/" .. combineSkillCfg.effectBigName[1] .. ".png")
		combSt = newCSpriteWithOption(battle.StageRes.cutRes)
	end

	local clipNode = cc.ClippingNode:create(st)
	local aniNode = cc.Node:create()
	local ownerSpr = self.parent:onViewProxyCall("getSceneObj", id)
	local faceTo = ownerSpr.faceTo
	local isHide = false

	local function hide()
		if isHide then
			return
		end

		isHide = true

		for _, obj in pairs(hideHero) do
			self.parent:onEventEffectByObj(obj, "show", {
				show = {
					{
						hide = true
					}
				}
			})
		end
	end

	local effectFront = isCombineSkill and "htj_effect" or "effect"

	bg:play(effectFront .. "_hou")
	bg:setSpriteEventHandler(function(event, eventArgs)
		if event == sp.EventType.ANIMATION_COMPLETE then
			removeCSprite(bg)
			removeCSprite(bg2)
			removeCSprite(st)
			removeCSprite(hero)
			removeCSprite(heroBg)

			if isCombineSkill then
				removeCSprite(combSt)
				removeCSprite(combHero)
				removeCSprite(combHeroBg)
			end

			hide()
			aniNode:removeFromParent()
			self:skillStageEffect(id, skillCfg)
		end
	end)
	bg:scale(faceTo * 1.42, 1.2):setPositionY(-20)

	local heroNode = cc.Node:create()

	hero:setPositionX(-420)
	heroBg:setPositionX(-420)
	hero:setPositionY(0)
	heroBg:setPositionY(0)

	local heroNodeScaleX = 1

	if skillCfg.effectBigFlip then
		heroNodeScaleX = -1
	end

	local effectBigPos = skillCfg.effectBigPos

	if effectBigPos.x ~= 0 then
		hero:setPositionX(hero:getPositionX() + effectBigPos.x)
		heroBg:setPositionX(heroBg:getPositionX() + effectBigPos.x)
	end

	if effectBigPos.y ~= 0 then
		hero:setPositionY(hero:getPositionY() + effectBigPos.y)
		heroBg:setPositionY(heroBg:getPositionY() + effectBigPos.y)
	end

	hero:scale(heroNodeScaleX * 1.35, 1.35)
	heroBg:scale(heroNodeScaleX * 1.4, 1.4)
	heroBg:setGLProgram("color"):setUniformVec3("color", cc.Vertex3F(0.93, 0.07, 0.41))
	st:xy(0, 0):scale(1, 1):play(effectFront .. "_zhezhao")
	heroNode:add(heroBg, 1):add(hero, 2):xy(-500, -500):scale(1.2)
	clipNode:scale(faceTo * 1.2, 1.2)
	clipNode:add(heroNode)
	transition.executeSequence(heroNode):delay(0.5):easeBegin("IN"):spawnBegin():moveTo(0.33, 0, 0):scaleTo(0.33, 1):spawnEnd():easeEnd():easeBegin("IN"):moveBy(0.33, -50, -50):moveBy(0.33, 50, 50):easeEnd():easeBegin("OUT"):spawnBegin():moveTo(0.5, 1136, 640):scaleTo(0.5, 0.1):func(hide):spawnEnd():easeEnd():done()
	bg2:play(effectFront .. "_qian")
	bg2:setScaleX(faceTo)

	local scaleY = 2

	if display.uiOrigin.y ~= 0 then
		local value = display.sizeInPixels.height

		scaleY = scaleY * ((value + display.uiOrigin.y) / value)
	end

	aniNode:add(bg, 1):add(clipNode, 2):add(bg2, 3):scale(scaleY):setPosition(display.center)
	aniNode:x(aniNode:x() - faceTo * display.uiOrigin.x)

	if isCombineSkill then
		local combClipNode = cc.ClippingNode:create(combSt)
		local combHeroNode = cc.Node:create()

		combHero:setPositionX(-420)
		combHeroBg:setPositionX(-420)
		combHero:setPositionY(0)
		combHeroBg:setPositionY(0)

		if effectBigPos.combX and effectBigPos.combX ~= 0 then
			combHero:setPositionX(combHero:getPositionX() + effectBigPos.combX)
			combHeroBg:setPositionX(combHeroBg:getPositionX() + effectBigPos.combX)
		end

		if effectBigPos.combY and effectBigPos.combY ~= 0 then
			combHero:setPositionY(combHero:getPositionY() + effectBigPos.combY)
			combHeroBg:setPositionY(combHeroBg:getPositionY() + effectBigPos.combY)
		end

		combHero:scale(heroNodeScaleX * 1.35, -1.35)
		combHeroBg:scale(heroNodeScaleX * 1.4, -1.4)
		combHeroBg:setGLProgram("color"):setUniformVec3("color", cc.Vertex3F(0.93, 0.07, 0.41))
		combSt:xy(0, 0):scale(1, 1):play(effectFront .. "_zhezhao")
		combHeroNode:add(combHeroBg, 1):add(combHero, 2):xy(-500, -500):scale(1.2)
		combClipNode:scale(-1 * faceTo * 1.2, -1.2)
		combClipNode:add(combHeroNode)
		transition.executeSequence(combHeroNode):delay(0.5):easeBegin("IN"):spawnBegin():moveTo(0.33, 0, 0):scaleTo(0.33, 1):spawnEnd():easeEnd():easeBegin("IN"):moveBy(0.33, -50, -50):moveBy(0.33, 50, 50):easeEnd():easeBegin("OUT"):spawnBegin():moveTo(0.5, 1136, 640):scaleTo(0.5, 0.1):func(hide):spawnEnd():easeEnd():done()
		aniNode:add(combClipNode, 2)
	end

	self.parent.layer:add(aniNode)
end

function Stage:skillStageEffect(id, skillCfg)
	local node = self.parent:onViewProxyCall("getSceneObj", id)

	if node == nil then
		return
	end

	local blankTime = skillCfg.blankTime
	local scaleArgs = skillCfg.scaleArgs

	if skillCfg.cameraNear == 1 or skillCfg.cameraNear == 2 then
		blankTime = skillCfg.cameraNear_blankTime
		scaleArgs = skillCfg.cameraNear_scaleArgs
	end

	if not blankTime or blankTime <= 0 then
		return
	end

	if scaleArgs.scale and scaleArgs.scale ~= 1 then
		node:objToBlank(scaleArgs)
	end

	local battleView = self.parent
	local args = {
		addTolayer = 0,
		screenPos = 0,
		aniloop = false,
		scale = 2,
		zorder = 0,
		offsetY = 0,
		offsetX = 0,
		delay = 0,
		aniName = "dazhao_bj",
		lastTime = blankTime
	}
	local effect = self.parent:onEventEffect(nil, "effect", {
		faceTo = 1,
		effectType = 1,
		effectRes = battle.StageRes.daZhaoBJ,
		effectArgs = args,
		onComplete = function()
			return
		end
	})

	table.insert(self.parent.effectJumpCache, effect)
end

function Stage:onSkillStartStageMove(cameraNear)
	local scale = cameraNear == 2 and 1.15 or 0.85

	transition.executeParallel(self.stageLayer):scaleTo(0.8, scale)
	transition.executeParallel(self.parent.gameLayer):scaleTo(0.8, scale)
	transition.executeParallel(self.parent.effectLayer):scaleTo(0.8, scale)
end

function Stage:onSkillEndStageMoveBack()
	transition.executeParallel(self.stageLayer):moveTo(0.3, 0, 0):scaleTo(0.3, 1)
	transition.executeParallel(self.parent.gameLayer):moveTo(0.3, 0, display.fightLower):scaleTo(0.3, 1)
	transition.executeParallel(self.parent.effectLayer):moveTo(0.3, 0, display.fightLower):scaleTo(0.3, 1)
end

function Stage:onAlterBattleScene(args)
	if not self.bgSprGroup then
		self.bgSprGroup = {}
	end

	if self.bgSprGroup[args.buffId] then
		self.bgSprGroup[args.buffId]:removeSelf()

		self.bgSprGroup[args.buffId] = nil
	end

	if not args.restore then
		for _, v in pairs(self.bgSprGroup) do
			v:hide()
		end

		if args.aniName then
			local bgSpr = newCSpriteWithOption(args.resPath)

			self.parent.stageLayer:add(bgSpr, 9999)
			bgSpr:setPosition(display.center)

			local x, y = bgSpr:getPosition()

			bgSpr:setPosition(x + args.x, y + args.y):scale(2)
			bgSpr:play(args.aniName .. "_loop")

			self.bgSprGroup[args.buffId] = bgSpr
		else
			local bgSpr = cc.Sprite:create(args.resPath)

			bgSpr:xy(display.center):scale(2)
			self.parent.stageLayer:add(bgSpr, 9999)

			self.bgSprGroup[args.buffId] = bgSpr
		end
	else
		local maxBuffID = -1

		for k, _ in pairs(self.bgSprGroup) do
			if maxBuffID < k then
				maxBuffID = k
			end
		end

		if maxBuffID ~= -1 then
			self.bgSprGroup[maxBuffID]:show()
		end
	end
end

function Stage:onAidStageEffect(skillOwner, aidObjs)
	if not next(aidObjs) then
		return
	end

	if skillOwner and skillOwner.type == battle.ObjectType.Aid then
		return
	end

	for k, obj in ipairs(aidObjs) do
		local isLeft = obj.force == 1
		local node = cc.Node:create()

		node:xy(display.center.x, display.center.y):scale(2)

		local aidBg = newCSpriteWithOption("effect/juneizhuzhan.skel")

		aidBg:play("effect")
		aidBg:setSpriteEventHandler(function(event, eventArgs)
			if event == sp.EventType.ANIMATION_COMPLETE then
				aidBg:stopAllActions()
				node:removeFromParent()
			end
		end)
		aidBg:setScaleX(isLeft and 1 or -1)
		node:add(aidBg)

		local showCfg = csv.aid.aid_skill[obj.cardCfg.aidID].showConfig
		local aidCard = newCSprite(obj.unitCfg.cardShow):scale(showCfg.scale):setPosition(-9999, -9999):setCascadeOpacityEnabled(true)

		node:add(aidCard, 1, "aidCard")

		local function update()
			local sx = aidBg:getScaleX()
			local bxy = aidBg:getBonePosition("hitman_move")

			bxy.x = bxy.x * sx
			bxy.y = bxy.y

			aidCard:setPosition(bxy.x + showCfg.x * sx, bxy.y + showCfg.y)
		end

		local action = cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(update)))

		aidBg:runAction(action)

		local aidText = newCSpriteWithOption("effect/juneizhuzhan.skel")

		aidText:play(isLeft and "zi" or "zi2")
		node:add(aidText, 1, "aidText")
		self.parent.layer:add(node)
	end
end

return Stage
