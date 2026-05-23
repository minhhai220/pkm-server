-- chunkname: @src.battle.views.event_effect.effect2

local MoveByDis = class("MoveByDis", battleEffect.EventEffect)

battleEffect.MoveByDis = MoveByDis

function MoveByDis:onPlay()
	local args = self.args
	local speed = args.speed

	speed = math.max(speed, 1)

	local a = args.a
	local dis = cc.pGetLength(cc.p(args.x, args.y))

	dis = math.max(dis, 1)

	local time

	if a == 0 then
		time = dis / speed
	else
		local det = speed * speed + 2 * a * dis

		det = math.max(det, 0)
		time = (math.sqrt(det) - speed) / a
	end

	local move = cc.MoveBy:create(time, cc.p(args.x, args.y))
	local action

	action = transition.speed(self.target, {
		speed = 1,
		action = transition.spawnEx():sequenceBegin():action(move):func(function()
			self.target:runAction(move:reverse())
		end):sequenceEnd():func(function()
			action:setSpeed(1 + a * move:getDuration())
		end):done()
	})

	self.target:runAction(action)
	self.view:setActionState(battle.SpriteActionTable.run)
end

function MoveByDis:onUpdate(delta)
	return
end

function MoveByDis:onStop(delta)
	self.view:setActionState(battle.SpriteActionTable.standby)
end

local MoveByTime = class("MoveByTime", battleEffect.EventEffect)

battleEffect.MoveByTime = MoveByTime

function MoveByTime:onPlay()
	local args = self.args
	local speed = args.speed
	local a = args.a
	local time = args.t
	local angle = args.angle
	local dis = speed * time + a * time * time / 2
	local x = math.cos(math.rad(angle)) * dis
	local y = math.sin(math.rad(angle)) * dis
	local action = cc.Speed:create(cc.MoveBy:create(time, cc.p(x, y)), 2)

	self.target:runAction(action)
	self.view:setActionState(battle.SpriteActionTable.run)
end

function MoveByTime:onUpdate(delta)
	return
end

function MoveByTime:onStop(delta)
	self.view:setActionState(battle.SpriteActionTable.standby)
end

local MoveTo = class("MoveTo", battleEffect.EventEffect)

battleEffect.MoveTo = MoveTo

function MoveTo:onPlay()
	local args = self.args
	local speed = args.speed
	local a = args.a
	local x, y = args.x, args.y
	local x2, y2 = self.target:getCurPos()
	local dis = cc.pGetLength(cc.p(x - x2, y - y2))
	local time
	local delay = 0
	local turnBack = args.turnBack
	local knockUp = args.knockUp
	local knockUpBack = args.knockUpBack

	if a == 0 then
		time = dis / speed
	else
		local det = speed * speed + 2 * a * dis

		det = math.max(det, 0)
		time = (math.sqrt(det) - speed) / a
	end

	if args.costTime and args.costTime >= 0 then
		time = args.costTime / 1000
	end

	if args.delayMove then
		delay = args.delayMove / 1000
	end

	if args.timeScale then
		time = time * args.timeScale
	end

	local move

	if knockUp then
		local faceToknockUp

		if self.target.force == 1 then
			faceToknockUp = 1
		elseif self.target.force == 2 then
			faceToknockUp = -1
		end

		local function knockUpTurn()
			faceToknockUp = faceToknockUp * -1

			self.target:setShowFaceTo(faceToknockUp)
		end

		move = cc.Spawn:create(cc.EaseIn:create(cc.MoveTo:create(time, cc.p(x, y)), 2), cc.Repeat:create(cc.Sequence:create(cc.DelayTime:create(0.25), cc.CallFunc:create(knockUpTurn)), 4))
	else
		move = cc.EaseIn:create(cc.MoveTo:create(time, cc.p(x, y)), 2)

		if time == 0 then
			move = cc.CallFunc:create(function()
				self.target:setPosition(cc.p(x, y))
			end)
		end
	end

	local isTurnBack = false

	if turnBack then
		if self.target.force == 1 and x < x2 then
			isTurnBack = true
		elseif self.target.force == 2 and x2 < x then
			isTurnBack = true
		end
	end

	local faceTo = isTurnBack and -1 or 1

	local function changeFaceTo()
		if args.changeFaceTo then
			self.target:setShowFaceTo(faceTo * args.changeFaceTo)

			faceTo = 1
		end
	end

	local action = cc.Sequence:create(cc.CallFunc:create(changeFaceTo), cc.DelayTime:create(delay), move, cc.CallFunc:create(changeFaceTo), cc.CallFunc:create(handler(self, self.stop)))

	self.target:runAction(action)

	if not knockUp and not knockUpBack then
		self.view:setActionState(battle.SpriteActionTable.run)
	end

	if knockUp then
		self.target:isComeBacking(true)
	elseif knockUpBack then
		self.target:isComeBacking(false)
	end
end

function MoveTo:onUpdate(delta)
	return
end

function MoveTo:onStop(delta)
	self.view:setCurPos(cc.p(self.args.x, self.args.y))
	self.view:setActionState(battle.SpriteActionTable.standby)
end

local ComeBack = class("ComeBack", battleEffect.MoveTo)

battleEffect.ComeBack = ComeBack

function ComeBack:onPlay()
	local x, y = self.target:getSelfPos()

	self.args = {
		speed = 1500,
		a = 2000,
		turnBack = true,
		costTime = self.args.costTime,
		delayMove = self.args.delayMove,
		x = x,
		y = y,
		changeFaceTo = self.target.forceFaceTo
	}

	battleEffect.MoveTo.onPlay(self)
	self.target:isComeBacking(true)
end

function ComeBack:onStop(delta)
	battleEffect.MoveTo.onStop(self, delta)
	self.target:resetPos()
	self.target:isComeBacking(false)
end

function ComeBack:debugString()
	return string.format("ComeBack: %s", toDebugString(self.target))
end

local Callback = class("Callback", battleEffect.OnceEventEffect)

battleEffect.Callback = Callback

function Callback:onPlay()
	self.args.func()
end

function Callback:traceInfo(depth, dListTrace, dListPopTrace)
	depth = depth or 2

	if self.args.cbTrace then
		print("================ cbTrace ================")

		for i, info in ipairs(self.args.cbTrace) do
			if depth < i then
				break
			end

			print("cbTrace", i, info.name, info.file, info.line)
		end
	end

	if self.args.deferListTrace and dListTrace then
		print("================ dLTrace ================")

		for i, info in ipairs(self.args.deferListTrace) do
			if depth < i then
				break
			end

			print("deferListTrace", i, info.name, info.file, info.line)
		end
	end

	if self.args.deferListPopTrace and dListPopTrace then
		print("================ dLPopTrace ================")

		for i, info in ipairs(self.args.deferListPopTrace) do
			if depth < i then
				break
			end

			print("deferListPopTrace", i, info.name, info.file, info.line)
		end
	end
end

local OnceEffect = class("OnceEffect", battleEffect.EventEffect)

battleEffect.OnceEffect = OnceEffect

function OnceEffect:onPlay()
	local cfg = self.args

	self.view:onViewProxyCall("onBuffPlayOnceEffect", cfg.tostrModel, cfg.resPath, cfg.aniName, cfg.pos, cfg.offsetPos, cfg.assignLayer, cfg.wait)
end

local Wait = class("Wait", battleEffect.EventEffect)

battleEffect.Wait = Wait

function Wait:onUpdate(delta)
	return
end

local Jump = class("Jump", battleEffect.OnceEventEffect)

battleEffect.Jump = Jump

function Jump:onPlay()
	if self.args.jumpFlag and self.view.skillJumpSwitchOnce then
		local battleView = gRootViewProxy:raw()

		battleView:closeEffectEventEnable()
		self.view:onCleanEffectCache()
	end
end

local BattleViewTarget = {}

BattleViewTarget.__index = BattleViewTarget
BattleViewTarget.__targes = {
	"stageLayer",
	"gameLayer",
	"effectLayerNum"
}
BattleViewTarget.__fmap = {
	getScaleX = "setScaleX",
	getScaleY = "setScaleY",
	getRotation = "setRotation",
	getPosition = "setPosition"
}

function BattleViewTarget.new()
	local ret = setmetatable({}, BattleViewTarget)

	ret:ctor()

	return ret
end

function BattleViewTarget:ctor()
	self.view = gRootViewProxy:raw()
	self.scaleX = 1
	self.scaleY = 1
	self.backups = {}
end

function BattleViewTarget:runAction(action)
	return self.view:runAction(action)
end

function BattleViewTarget:stopAction(action)
	return self.view:stopAction(action)
end

function BattleViewTarget:revert()
	for fname, t in pairs(self.backups) do
		for name, v in pairs(t) do
			local node = self.view[name]
			local f = node[self.__fmap[fname]]

			if type(v) == "table" then
				f(node, unpack(v))
			else
				f(node, v)
			end
		end
	end

	self.backups = {}
end

function BattleViewTarget:_backup(fname, nret)
	if self.backups[fname] then
		return
	end

	nret = nret or 1

	local t = {}

	for _, name in ipairs(self.__targes) do
		local node = self.view[name]

		if node then
			local f = node[fname]

			if f then
				if nret == 1 then
					t[name] = f(node)
				else
					t[name] = {
						f(node)
					}
				end
			end
		end
	end

	self.backups[fname] = t
end

function BattleViewTarget:_do(fname, ...)
	for _, name in ipairs(self.__targes) do
		local node = self.view[name]

		if node then
			local f = node[fname]

			if f then
				f(node, ...)
			end
		end
	end
end

function BattleViewTarget:setPosition(x, y)
	self:_backup("getPosition", 2)

	local newX = -(x - display.cx)
	local newY = -(y - display.cy)

	return self:_do("setPosition", newX * self.scaleX, newY * self.scaleY)
end

function BattleViewTarget:setRotation(rotation)
	self:_backup("getRotation")

	return self:_do("setRotation", rotation)
end

function BattleViewTarget:setScaleX(scaleX)
	self:_backup("getScaleX")

	self.scaleX = 1 / scaleX

	return self:_do("setScaleX", self.scaleX)
end

function BattleViewTarget:setScaleY(scaleY)
	self:_backup("getScaleY")

	self.scaleY = 1 / scaleY

	return self:_do("setScaleY", self.scaleY)
end

local Follow = class("Follow", battleEffect.EventEffect)

battleEffect.Follow = Follow

function Follow:onPlay()
	local faceTo = self.args.faceTo

	if self.args.follow.scene then
		faceTo = 1
	end

	local bones = self.args.follow.bones
	local targets = self.args.processArgs.viewTargets
	local curIndex = self.args.index
	local rnd = math.random(1, table.length(bones))

	if table.length(targets) > 1 and table.length(bones) > 1 then
		local idx = itertools.first(targets, function(obj)
			return obj.id == self.target.id
		end)

		if idx then
			rnd = (idx - 1) % table.length(bones) + 1
		end
	end

	self.boneName = bones[rnd]
	self.boneSprite = self.args.fromSprite

	if self.boneSprite == nil then
		return
	end

	if self.args.follow.scene then
		self.target = BattleViewTarget.new()
		self.view = self.target
	else
		self.oldX, self.oldY = self.target:getPosition()
		self.oldRotation = self.target:getRotation()
		self.oldScaleX = self.target:getScaleX()
		self.oldScaleY = self.target:getScaleY()
	end

	local boneName = self.boneName
	local sprite = self.boneSprite.sprite

	self.boneSprite:addActionCompleteListener(function(ani, count)
		self:stop()
	end)

	if self.args.follow.scene and curIndex > 1 then
		return
	end

	local function update()
		local posx, posy = self.boneSprite:getPosition()
		local sx, sy = sprite:getScaleX(), sprite:getScaleY()
		local bxy = sprite:getBonePosition(boneName)
		local rotation = sprite:getBoneRotation(boneName)
		local scaleX = sprite:getBoneScaleX(boneName)
		local scaleY = sprite:getBoneScaleY(boneName)

		bxy.x = bxy.x * sx + posx
		bxy.y = bxy.y * sy + posy

		self.target:setRotation(-rotation)
		self.target:setScaleX(scaleX * faceTo, true)
		self.target:setScaleY(scaleY, true)
		self.target:setPosition(bxy.x, bxy.y)
	end

	self.action = cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(update)))

	self.target:runAction(self.action)
end

function Follow:onUpdate(delta)
	return
end

local EventEffect = battleEffect.EventEffect

function Follow:safeTarget()
	if self.args.follow.scene then
		return self.target
	else
		return EventEffect.safeTarget(self)
	end
end

function Follow:onStop()
	self:safeTarget():stopAction(self.action)

	local notBack = self.args.follow.notback

	if self.args.follow.scene then
		self:safeTarget():revert()
	elseif not notBack then
		self:safeTarget():setPosition(self.oldX, self.oldY)
		self:safeTarget():setRotation(self.oldRotation)
		self:safeTarget():setScaleX(self.oldScaleX)
		self:safeTarget():setScaleY(self.oldScaleY)
	else
		self:safeTarget():isComeBacking(true)
	end
end

local Control = class("Control", battleEffect.OnceEventEffect)

battleEffect.Control = Control

function Control:onPlay()
	local battleView = gRootViewProxy:raw()
	local lifeBar = self.args.lifeBar

	if not battleView then
		errorInWindows("Control:onPlay battleView is nil")

		return
	end

	local objs = battleView:onViewProxyCall("getSceneObjs")

	for _, objSpr in maptools.order_pairs(objs) do
		if objSpr and objSpr.model and not objSpr.model:isRealDeath() and lifeBar then
			objSpr.lifebar:setVisible(lifeBar.show or false)
			objSpr:onAttacting(false)
		end
	end
end

local Cutting = class("Cutting", battleEffect.OnceEventEffect)

battleEffect.Cutting = Cutting

function Cutting:createCapture(node, format)
	local x, y = node:xy()
	local box = cc.utils:getCascadeBoundingBox(node)
	local wpos = node:convertToWorldSpace(cc.p(0, 0))
	local rect = cc.rect(wpos.x, wpos.y, box.width, box.height)
	local anchor = node:getAnchorPoint()
	local rt = cc.RenderTexture:create(rect.width, rect.height, format)
	local spr = cc.Node:create()

	spr:setContentSize(rect.width, rect.height):setAnchorPoint(cc.p(0, 0))
	spr:add(rt)
	rt:beginWithClear(0, 0, 0, 0)

	local size = node:size()
	local relOffest = cc.pSub(wpos, rect)
	local selfAnchorOffest = cc.p(size.width * anchor.x, size.height * anchor.y)
	local capturePos = cc.pAdd(selfAnchorOffest, relOffest)

	node:xy(selfAnchorOffest):visit()
	node:visit()
	rt:endToLua()
	rt:drawOnce(true)
	node:xy(cc.p(x, y))

	local realSpr = rt:getChildren()[1]

	if realSpr then
		cache.setHSLShader(realSpr, false, unpack(self.hsl))
	end

	return spr
end

function Cutting:createClipSpr(nodeList, panel)
	local captureSpr = self:createCapture(panel, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444)
	local drawnode = cc.DrawNode:create()

	drawnode:drawPolygon(nodeList, #nodeList, cc.c4b(1, 1, 0, 0), 1, cc.c4b(0, 1, 0, 1))

	local clipNode = cc.ClippingNode:create(drawnode)

	clipNode:addChild(captureSpr)

	return clipNode
end

function Cutting:newSprite(objSpr)
	local faceTo = self.args.faceTo
	local res = objSpr.unitRes
	local cfg = objSpr.unitCfg
	local skinName = objSpr.skins:back() and objSpr.skins:back().skinName
	local spr = newCSpriteWithOption(res)

	if skinName then
		local ani = spr:getAni()

		ani:setSkin(skinName)
		ani:setToSetupPose()
	end

	spr:play(battle.SpriteActionTable.standby)
	spr:setScaleX(faceTo * cfg.scaleX * cfg.scale * cfg.scaleC)
	spr:setScaleY(cfg.scale * cfg.scaleC)
	spr:setAnchorPoint(cc.p(0.5, 0.5))

	return spr
end

function Cutting:onPlay()
	local battleView = gRootViewProxy:raw()
	local targets = self.args.processArgs.viewTargets
	local bones = self.args.cutting.bones

	self.boneSprite = self.args.fromSprite

	local sprite = self.boneSprite.sprite
	local posx, posy = self.boneSprite:getPosition()
	local sx, sy = sprite:getScaleX(), sprite:getScaleY()

	self.hsl = self.args.cutting.hsl or {
		0,
		-1,
		-1
	}

	local panel = ccui.Layout:create():size(display.width, display.height)

	for id, obj in ipairs(targets) do
		local objSpr = battleView:onViewProxyCall("getSceneObjById", obj.id)
		local spr = self:newSprite(objSpr)

		spr:addTo(panel)

		local boneName = bones[id]
		local bxy = sprite:getBonePosition(boneName)
		local rotation = sprite:getBoneRotation(boneName)
		local scaleX = sprite:getBoneScaleX(boneName) * spr:scaleX()
		local scaleY = sprite:getBoneScaleY(boneName) * spr:scaleY()

		bxy.x = bxy.x * sx + posx
		bxy.y = bxy.y * sy + posy

		spr:setRotation(rotation)
		spr:setScaleX(scaleX)
		spr:setScaleY(scaleY)
		spr:setPosition(bxy.x, bxy.y)
	end

	local lineRotation = self.args.cutting.lineRotation or 10
	local tanTheta = math.tan(math.rad(lineRotation))
	local l1 = display.height * tanTheta
	local off1 = l1 / 2
	local halfWidth = display.width / 2
	local halfHeight = display.height / 2
	local leftPoints = {
		cc.p(0, 0),
		cc.p(0, display.height),
		cc.p(halfWidth + off1, display.height),
		cc.p(halfWidth - off1, 0)
	}
	local rightPoints = {
		cc.p(display.width, 0),
		cc.p(display.width, display.height),
		cc.p(halfWidth + off1, display.height),
		cc.p(halfWidth - off1, 0)
	}
	local clipSpr1 = self:createClipSpr(leftPoints, panel):addTo(battleView.gameLayer, 888):setPosition(cc.p(0, 0))
	local clipSpr2 = self:createClipSpr(rightPoints, panel):addTo(battleView.gameLayer, 888):setPosition(cc.p(0, 0))
	local delayTime1 = 0.15
	local delayTime2 = self.args.cutting.delayEnd or 0.15
	local disMid = self.args.cutting.disMid or 10
	local time1 = 0.1
	local move1_1 = cc.MoveBy:create(time1, cc.p(-disMid, 0))
	local move2_1 = cc.MoveBy:create(time1, cc.p(disMid, 0))
	local time2 = self.args.cutting.timeMove or 0.2
	local disV = self.args.cutting.disVertical or 350
	local move1_2 = cc.MoveBy:create(time2, cc.p(disV * tanTheta, disV))
	local move2_2 = cc.MoveBy:create(time2, cc.p(-disV * tanTheta, -disV))

	clipSpr1:runAction(cc.Sequence:create(move1_1, cc.DelayTime:create(delayTime1), move1_2, cc.DelayTime:create(delayTime2), cc.CallFunc:create(function()
		clipSpr1:removeFromParent()
	end)))
	clipSpr2:runAction(cc.Sequence:create(move2_1, cc.DelayTime:create(delayTime1), move2_2, cc.DelayTime:create(delayTime2), cc.CallFunc:create(function()
		clipSpr2:removeFromParent()
	end)))
end
