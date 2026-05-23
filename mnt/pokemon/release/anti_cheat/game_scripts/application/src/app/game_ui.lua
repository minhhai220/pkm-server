-- chunkname: @src.app.game_ui

local ConnectingNodeName = "connecting"
local messageComponent = cc.load("message")
local GameUI = class("GameUI")
local TouchDispatchTag = 2105271208
local LAYER = {
	modal = 99,
	achievementTip = 9,
	tip = 11,
	timeSpeeder = 100,
	guide = 10,
	view = 1,
	connecting = 99
}

function GameUI:ctor(app)
	globals.gGameUI = self
	globals.gRootViewProxy = ViewProxy.new()
	self.app = app
	self.scene = nil
	self.uiStack = {}
	self.modalStack = {}
	self.tipQueue = {}
	self.achievementTipQueue = {}
	self.achievementTipWaitQueue = {}
	self.delayCalls = {}
	self.singletonViews = {}
	self.topuiManager = require("app.views.topui.manager").new()
	self.guideManager = require("app.views.guide.manager").new()
	self.guideManagerLocal = require("app.views.guide.manager_local").new()
	self.timeSpeederManager = require("app.views.common.time_speeder.manager").new()
	self.effectAllCount = 0
	self.modalLayer = cc.LayerColor:create(cc.c4b(120, 0, 0, 0), display.width, display.height)
	self.viewLayer = cc.LayerColor:create(cc.c4b(0, 120, 0, 0), display.width, display.height)
	self.guideLayer = cc.LayerColor:create(cc.c4b(0, 0, 120, 0), display.width, display.height)
	self.timeSpeederLayer = cc.LayerColor:create(cc.c4b(120, 0, 0, 200), 0, 0)
	self.connectingLayer = ccui.Layout:create()
	self.isMultiTouches = false
	self.outSceneNode = nil
	self.rootViewName = nil
	self.avoidClickCount = 0

	self:onCreate()
end

function GameUI:tryCloseItemDetail(pos)
	if self.itemDetailView then
		local isClose = false

		if self.itemDetailView.hitTestPanel and pos then
			isClose = not self.itemDetailView:hitTestPanel(pos)
		else
			isClose = true
		end

		if isClose then
			self.itemDetailView:onClose()

			self.itemDetailView = nil

			return true
		end
	end

	return false
end

function GameUI:onCreate()
	self.modalLayer:retain()
	self.modalLayer:setName("modalLayer")
	self.modalLayer:setVisible(false)
	self.modalLayer:setTouchMode(cc.TOUCHES_ONE_BY_ONE)
	self.modalLayer:setSwallowsTouches(true)
	self.modalLayer:setTouchEnabled(false)
	self.modalLayer:setLocalZOrder(LAYER.modal)
	self.modalLayer:registerScriptTouchHandler(function(state, x, y)
		return true
	end)
	self.viewLayer:retain()
	self.viewLayer:setName("viewLayer")
	self.viewLayer:setTouchEnabled(false)
	self.viewLayer:setLocalZOrder(LAYER.view)
	self.guideLayer:retain()
	self.guideLayer:setName("guideLayer")
	self.guideLayer:setVisible(false)
	self.guideLayer:setTouchEnabled(true)
	self.guideLayer:setLocalZOrder(LAYER.guide)
	self.connectingLayer:retain()
	self.connectingLayer:setName("connectingLayer")
	self.connectingLayer:setVisible(false)
	self.connectingLayer:setContentSize(display.sizeInView)
	self.connectingLayer:setTouchEnabled(true)
	self.connectingLayer:setLocalZOrder(LAYER.connecting)
	self.connectingLayer:setPosition(cc.p(display.board_left, 0))
	self.timeSpeederLayer:retain()
	self.timeSpeederLayer:setName("timeSpeederLayer")
	self.timeSpeederLayer:hide()
	self.timeSpeederLayer:setTouchEnabled(false)
	self.timeSpeederLayer:setLocalZOrder(LAYER.timeSpeeder)

	local listener = cc.EventListenerTouchOneByOne:create()
	local eventDispatcher = display.director:getEventDispatcher()

	local function onTouchBegan(touch, event)
		self:tryCloseItemDetail(touch:getLocation())

		local swallow = false

		if not self.isMultiTouches and cc.Device.setMultipleTouchEnabled == nil then
			local nTouch = #display.director:getOpenGLView():getAllTouches()

			if nTouch > 1 then
				swallow = true
			end
		end

		return swallow
	end

	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
	eventDispatcher:addEventListenerWithFixedPriority(listener, -999)

	self.outSceneNode = cc.Node:create()

	display.director:setNotificationNode(self.outSceneNode)

	if CC_DESIGN_RESOLUTION.autoscale == "SHOW_ALL" then
		local outSceneNode = self.outSceneNode
		local scaleX, scaleY = display.sizeInPixels.width / display.sizeInView.width, display.sizeInPixels.height / display.sizeInView.height
		local scale = math.min(scaleX, scaleY)
		local heightInPixels = (display.sizeInPixels.height - scale * display.sizeInView.height) / 2
		local top = cc.Sprite:create("img/scene_board_bottom.png")

		top:setFlippedY(true)
		top:setAnchorPoint(0, 0)
		top:setContentSize(2560, 315)
		top:setPosition(0, (heightInPixels + scale * display.sizeInView.height) / scaleY)
		outSceneNode:addChild(top)

		local bottom = cc.Sprite:create("img/scene_board_bottom.png")

		bottom:setAnchorPoint(0, 1)
		bottom:setContentSize(2560, 315)
		bottom:setPosition(0, heightInPixels / scaleY)
		outSceneNode:addChild(bottom)
	end

	if display.uiOrigin.x > display.uiOriginMax.x then
		local outSceneNode = self.outSceneNode
		local widthInPixels = display.uiOrigin.x - display.uiOriginMax.x
		local left = cc.Sprite:create("img/scene_board_right.png")

		left:setFlippedX(true)
		left:setAnchorPoint(1, 0)
		left:setContentSize(600, 1440)
		left:setPosition(widthInPixels, 0)
		outSceneNode:addChild(left)

		local right = cc.Sprite:create("img/scene_board_right.png")

		right:setAnchorPoint(0, 0)
		right:setContentSize(600, 1440)
		right:setPosition(widthInPixels + display.maxWidth, 0)
		outSceneNode:addChild(right)
	end

	cache.addTexturePreload(ui.ATTR_LOGO, "common_ui")
	cache.addTexturePreload(ui.ATTR_ICON, "common_ui")
	cache.addTexturePreload(ui.SKILL_ICON, "common_ui")
	cache.addTexturePreload(ui.SKILL_TEXT_ICON, "common_ui")
	cache.addTexturePreload(ui.RARITY_ICON, "common_ui")
	cache.addTexturePreload(ui.COMMON_ICON, "common_ui")
	cache.addTexturePreload(ui.QUALITY_BOX, "common_ui")
	cache.addTexturePreload(ui.QUALITY_FRAME, "common_ui")
	cache.addTexturePreload(ui.VIP_ICON, "common_ui")
	cache.addTexturePreload(battle.SpriteRes, "battle_module", pngPath)
	cache.addTexturePreload(battle.ShowHeadNumberRes, "battle_module", pngPath)
	cache.addTexturePreload(battle.MainAreaRes, "battle_module", pngPath)
	cache.addTexturePreload(battle.StageRes, "battle_module", pngPath)
	cache.addTexturePreload(battle.RestraintTypeIcon, "battle_module", pngPath)
	cache.texturePreload("common_ui")
	display.director:setFontAutoScaleDownEnabled(true)
	self:showTimeSpeederIcon()
end

function GameUI:switchUI(name, ...)
	self:cleanTip()

	if name == "battle.view" then
		self:cleanAchievementTip()
		self.timeSpeederManager.setTimeRate(0.2)
	else
		self.timeSpeederManager.setTimeRate(1)
	end

	self.guideManager:setIgnoreGuide(true)
	self.guideManagerLocal:setIgnoreGuide(true)

	local oldName = self.rootViewName

	if oldName == name then
		self:goBackInStackUI(name)
		self.guideManager:setIgnoreGuide(false)
		self.guideManager:checkGuide({
			name = name
		})
		self.guideManagerLocal:setIgnoreGuide(false)
		self.guideManagerLocal:checkGuide({
			name = name
		})

		return self.uiRoot
	end

	if self.uiRoot then
		self.uiRoot:onClose()

		self.uiRoot = nil
	end

	local stash = false

	self.rootViewName = name

	if self.stashUI and self.stashUIName == name then
		self.uiRoot = self.stashUI

		self.uiRoot:beginRebuild()

		self.stashUI, self.stashUIName = nil
		stash = true
	else
		self.uiRoot = self:createView(name)
	end

	self:showWithScene(self.uiRoot)
	self.uiRoot:setContentSize(display.sizeInView)

	gRootViewProxy = ViewProxy.new(self.uiRoot)

	local topName = name

	self:initStackWithUIRoot_()

	if stash then
		for i, info in ipairs(self.stashUIStack) do
			self:stackUI_(info.name, nil, info.styles)

			topName = info.name
		end

		self.stashUIStack = nil

		self.uiRoot:endRebuild():autorelease()

		for i, info in ipairs(self.uiStack) do
			print("--- ui stack", i, info.name, info.view)
			print(info.view:getParent(), info.view:isVisible(), info.view:z(), info.view:getResourceNode(), info.view:getResourceNode():isVisible())

			for j, child in ipairs(info.view:getChildren()) do
				print(j, child, child:z(), child:name(), child:tag(), child:isVisible())
			end
		end
	else
		self.uiRoot:init(...)
	end

	self.guideManager:setIgnoreGuide(false)
	self.guideManager:checkGuide({
		name = topName
	})
	self.guideManagerLocal:setIgnoreGuide(false)
	self.guideManagerLocal:checkGuide({
		name = topName
	})
	printInfo("UI Switch %s %s %s %s", name, oldName and "From " .. oldName or "", stash and "By Stash" or "", topName)
	self:onSwitchUI(oldName, name)

	return self.uiRoot
end

function GameUI:switchUIAndStash(name, ...)
	self.guideManager:setIgnoreGuide(true)
	self.guideManagerLocal:setIgnoreGuide(true)

	if self.uiRoot then
		self.stashUI = self.uiRoot
		self.stashUIName = self.rootViewName
		self.stashUIStack = {}

		for i = 2, #self.uiStack do
			table.insert(self.stashUIStack, self.uiStack[i])
		end

		self.stashUI:hide():retain():onClose()
		self.uiRoot:tearDown()

		self.uiRoot = nil
	end

	if #self.uiStack > 0 then
		print_r(self.uiStack)
		error("the ui stack should be empty when stash save")
	end

	printInfo("UI Stash %s", self.stashUIName)

	return self:switchUI(name, ...)
end

function GameUI:cleanStash()
	if self.stashUI == nil then
		return
	end

	printInfo("UI CleanStash %s", self.stashUIName)
	self.stashUI:autorelease()

	self.stashUI, self.stashUIName = nil
	self.stashUIStack = nil
end

function GameUI:findStackUI(name)
	if name == self.rootViewName then
		return true
	else
		for i = #self.uiStack, 1, -1 do
			if name == self.uiStack[i].name then
				return true
			end
		end
	end

	return false
end

function GameUI:goBackInStackUI(name)
	local isExist = self:findStackUI(name)

	if isExist then
		for i = #self.uiStack, 2, -1 do
			if name == self.uiStack[i].name then
				break
			end

			self.uiStack[i].view:removeSelf()
		end
	end

	return isExist
end

function GameUI:getTopStackUI()
	if #self.uiStack > 0 then
		local top = self.uiStack[#self.uiStack]

		return top.view, top.name
	end

	return self.uiRoot, self.rootViewName
end

function GameUI:addSingletonView(view, relatedView, notClear)
	local name = view:name()
	local parent = view:parent()

	assert(parent, "call addSingletonView after view addTo its parent")

	local relation = self.singletonViews[name] or {}

	self.singletonViews[name] = relation

	for other, t in pairs(relation) do
		if t.show then
			if not notClear then
				t.view:removeSelf()
			end

			t.show = false
		end
	end

	if relation[relatedView] then
		relation[relatedView].view:autorelease()

		relation[relatedView] = nil
	end

	view:retain()

	relation[relatedView] = {
		show = true,
		view = view,
		parent = parent,
		notClear = notClear
	}
end

function GameUI:removeSingletonView(relatedView)
	for name, relation in pairs(self.singletonViews) do
		local t = relation[relatedView]

		relation[relatedView] = nil

		if t and t.show then
			local view = t.view

			local function onShow()
				view:autorelease()
				view:removeSelf()
			end

			local levels = {}

			for i = #self.uiStack, 1, -1 do
				levels[self.uiStack[i].view] = i
			end

			local top, topLevel = nil, -1

			for other, t in pairs(relation) do
				assert(not t.show, "no other view be show, it singleton")

				local level = levels[other] or -1

				assert(level >= 0, "the ui not on the stack")

				if topLevel < level then
					topLevel = level
					top = other
				end
			end

			if top then
				t = relation[top]
				t.show = true

				if not t.notClear then
					local view, parent = t.view, t.parent

					function onShow()
						view:removeSelf():addTo(parent)
					end
				end
			end

			performWithDelay(self.scene, onShow, 0)
		end
	end
end

function GameUI:stackUI(name, handlers, styles, ...)
	if self.uiRoot:isRebuilding() then
		return
	end

	local _, parentName = self:getTopStackUI()
	local view = self:stackUI_(name, handlers, styles)

	self:disableTouchDispatch(0.01)
	view:show():init(...)
	self.guideManager:checkGuide({
		name = name
	})
	self.guideManagerLocal:checkGuide({
		name = name
	})

	local cb

	cb = view:onNodeEvent("exit", function()
		cb:remove()
		self:sendMessage("stackUIViewExit", name, parentName)

		if not styles or not styles.dispatchNodes then
			self:disableTouchDispatch(0.01)
		end

		self.guideManager:checkGuide({
			name = parentName
		})
		self.guideManagerLocal:checkGuide({
			name = parentName
		})

		if self.rootViewName == "city.view" then
			collectgarbage("step", 10)
		end
	end)

	return view
end

function GameUI:initStackWithUIRoot_()
	assert(#self.uiStack == 0, "the ui stack should be empty")

	local name = self.rootViewName
	local view = self.uiRoot

	self.uiStack = {}

	self:stackUI_(name)

	return view
end

function GameUI:checkStyles_(name, view, styles)
	if device.platform ~= "windows" then
		return
	end

	if name == "battle.view" then
		return
	end

	local ignoreView = {
		GainDisplayView = true,
		OnlineGiftGainView = true,
		BattleEndWinView = true,
		BattleEndFailView = true,
		BattleEndPvpWinView = true,
		BattleEndPvpFailView = true,
		DrawCardPreviewView = true,
		CaptureHandbook = true
	}
	local size = view:getResourceNode():getContentSize()

	printDebug("check full style %s %s %s %s %s %s", view, name, tj.type(view), dumps(size), dumps(styles), isDialog(view))

	if size.width == display.sizeInView.width and size.height == display.sizeInView.height then
		local flag = name ~= self.rootViewName and not isDialog(view)

		flag = flag and not ignoreView[tj.type(view)]

		if flag and styles.full ~= nil and styles.backGlass ~= nil then
			performWithDelay(view, function()
				self:showDialog({
					content = name .. "可能没正确设置styles，比如full\n不改打你屁屁"
				})
			end, 1)
		end
	end
end

function GameUI:stackUI_(name, handlers, styles)
	local parent = self:getTopStackUI()
	local view, glass

	self:cleanTip()

	if name == self.rootViewName then
		local viewCls = self.app:getViewClass(name)
		local resStyles = rawget(viewCls, "RESOURCE_STYLES") or {}

		styles = {
			disableTimeSpeeder = resStyles.disableTimeSpeeder
		}
		handlers = nil
		view = self.uiRoot
	else
		local viewCls = self.app:getViewClass(name)
		local resStyles = rawget(viewCls, "RESOURCE_STYLES") or {}

		if styles then
			for k, v in pairs(resStyles) do
				if styles[k] == nil then
					styles[k] = v
				end
			end
		else
			styles = resStyles
		end
	end

	if styles.backGlass then
		glass = effect.blurGlassScreen()
	end

	local visSiwtch

	if styles.full or styles.backGlass then
		visSiwtch = self:hideOtherUI(parent)
	elseif styles.dialog and isDialog(parent) then
		parent:onStackHide()
	end

	if styles.disableTimeSpeeder then
		self.timeSpeederManager.yieldSpeeder()
	end

	if glass then
		glass:xy(display.center):addTo(parent, -99, "__back_glass__")
	end

	view = view or self:createView(name, parent, handlers)

	table.insert(self.uiStack, {
		hideByStyles = 0,
		name = name,
		view = view,
		styles = styles
	})
	self:checkStyles_(name, view, styles)

	if glass then
		self:addSingletonView(glass, view, true)

		if styles.clickClose then
			performWithDelay(glass, function()
				view:getResourceNode():setTouchEnabled(false)
				bind.click(view, glass, {
					method = function()
						view:onClose()
					end
				})
			end, 0.1)
		end
	end

	if styles.blackLayer or styles.clickClose or styles.dispatchNodes then
		local blackLayer = ccui.Layout:create():size(display.sizeInView):xy(display.board_left, 0):addTo(view, -99, "__black_layer__")

		blackLayer:setBackGroundColorType(1)
		blackLayer:setBackGroundColor(cc.c3b(91, 84, 91))
		blackLayer:setBackGroundColorOpacity(0)
		blackLayer:setTouchEnabled(true)

		if styles.blackLayer then
			blackLayer:setBackGroundColorOpacity(204)
		end

		self:addSingletonView(blackLayer, view)
		self:setBlackLayerStyle(blackLayer, view, styles)
	end

	local stackIndex = #self.uiStack
	local cb

	cb = view:onNodeEvent("exit", function()
		cb:remove()
		printInfo("UI Stack Pop [%d] %s %d %s", stackIndex, name, #self.uiStack, tostring(self.uiStack[stackIndex].view))
		self:removeSingletonView(view)

		if visSiwtch then
			visSiwtch:revert()
		end

		parent:onStackShow()
		assert(stackIndex == #self.uiStack and self.uiStack[stackIndex].view == view, "must remove top uiStack first !!!")
		table.remove(self.uiStack, stackIndex)

		if styles.disableTimeSpeeder == true then
			self.timeSpeederManager.resumeSpeeder()
		end
	end)

	printInfo("UI Stack Push %s %d %s", name, #self.uiStack, tostring(view))

	return view
end

local function setUIVisibleByStyle(t, show, skipHash)
	t.hideByStyles = t.hideByStyles + (show and -1 or 1)
	t.hideByStyles = math.max(0, t.hideByStyles)

	if show and t.hideByStyles == 0 then
		t.view:onStackShow()
	elseif not show and t.hideByStyles == 1 then
		t.view:onStackHide(skipHash)
	end
end

function GameUI:hideOtherUI(skipNode)
	local skipHash = {}

	while skipNode do
		skipHash[skipNode] = true
		skipNode = skipNode:getParent()
	end

	local ops = {}

	for i = #self.uiStack, 1, -1 do
		local t = self.uiStack[i]

		setUIVisibleByStyle(t, false, skipHash)
		table.insert(ops, t)
	end

	return {
		revert = function()
			local hash = {}

			for i = #self.uiStack, 1, -1 do
				hash[self.uiStack[i]] = i
			end

			for i = #ops, 1, -1 do
				local t = ops[i]

				if hash[t] then
					setUIVisibleByStyle(t, true)
				end
			end
		end
	}
end

function GameUI:setBlackLayerStyle(blackLayer, view, styles)
	if styles.dispatchNodes then
		view:getResourceNode():setTouchEnabled(false)
		blackLayer:setTouchEnabled(false)

		local hasDispatchNode = false

		uiEasy.addTouchOneByOne(blackLayer, {
			nodeVisible = true,
			beforeBegan = function(pos)
				if not view:getResourceNode():isVisibleInGlobal() then
					return
				end

				local nodes = styles.dispatchNodes

				if type(nodes) ~= "table" then
					nodes = {
						nodes
					}
				end

				for _, node in pairs(nodes) do
					if not tolua.isnull(node) then
						local rect = node:box()
						local nodePos = node:parent():convertToWorldSpace(cc.p(rect.x, rect.y))

						rect.x = nodePos.x
						rect.y = nodePos.y

						if cc.rectContainsPoint(rect, pos) then
							if view.onCloseFast then
								view:onCloseFast()
							else
								view:onClose()
							end

							hasDispatchNode = true

							return true
						end
					end
				end

				return false
			end,
			ended = function()
				if not view:getResourceNode():isVisibleInGlobal() then
					return
				end

				if not hasDispatchNode and styles.clickClose then
					view:onClose()

					return false
				end
			end
		})
	end

	if not styles.dispatchNodes and styles.clickClose then
		performWithDelay(blackLayer, function()
			view:getResourceNode():setTouchEnabled(false)
			bind.click(view, blackLayer, {
				method = function()
					view:onClose()
				end
			})
		end, 0.1)
	end
end

function GameUI:enterScene(sceneName, transition, time, more)
	self.uiRoot = self:createView(sceneName)
	self.rootViewName = sceneName
	self.scene = self:showWithScene(self.uiRoot, transition, time, more)
	gRootViewProxy = ViewProxy.new(self.uiRoot)

	self.uiRoot:init()

	return self.uiRoot
end

function GameUI:showWithScene(view, transition, time, more)
	local scene = self.scene

	if scene == nil then
		scene = display.newScene(tostring(view))

		display.runScene(scene, transition, time, more)
		self.modalLayer:removeFromParent()
		scene:addChild(self.modalLayer)
		self.viewLayer:removeFromParent()
		self.viewLayer:removeAllChildren()
		scene:addChild(self.viewLayer)
		self.guideLayer:removeFromParent()
		self.guideLayer:removeAllChildren()
		scene:addChild(self.guideLayer)
		self.timeSpeederLayer:removeFromParent()
		scene:addChild(self.timeSpeederLayer)

		if CC_DESIGN_RESOLUTION.autoscale == "FIXED_HEIGHT" then
			self.modalLayer:setPosition(display.uiOrigin.x, 0)
			self.viewLayer:setPosition(display.uiOrigin.x, 0)
			self.guideLayer:setPosition(display.uiOrigin.x, 0)
			self.timeSpeederLayer:setPosition(display.uiOrigin.x, 0)
		end

		self:showIphoneXLayer()

		if EDITOR_ENABLE then
			printInfo("------ Editor init ------")

			local editor = require("editor.builder")

			editor:init(scene)
			printInfo("------------")
		end

		if dev.DEBUG_MODE and dev.DEV_PATH then
			local ok, err, code = os.rename(dev.DEV_PATH, "rb")
			local flag = not ok and (err:find("File exists") or code == 13 or code == 17)

			flag = flag or device.platform == "mac"

			if flag then
				local editor = require("editor.builder")

				editor:addTipLabel("in dev mode " .. dev.DEV_PATH, "_dev_tip_")
			end
		end
	end

	if view:name() == "login.view" or view:name() == "new_character.view" then
		self.timeSpeederLayer:hide()
	end

	view:setVisible(true)
	self.viewLayer:addChild(view)

	return scene
end

function GameUI:showDebugLayer()
	if self.outSceneNode == nil and display.uiOrigin.x > 0 then
		self.outSceneNode = cc.Node:create()

		display.director:setNotificationNode(self.outSceneNode)

		local widthInPixels = display.uiOrigin.x
		local backBoard1 = cc.LayerColor:create(cc.c4b(0, 0, 255, 200), widthInPixels, display.sizeInView.height)
		local backBoard2 = cc.LayerColor:create(cc.c4b(255, 0, 0, 200), widthInPixels, display.sizeInView.height)

		backBoard2:setPositionX(display.board_right)
		self.outSceneNode:addChild(backBoard1)
		self.outSceneNode:addChild(backBoard2)
	end

	local zMax = 9999
	local board = cc.p(10, 10)

	cc.LayerColor:create(cc.c4b(255, 0, 255, 200), display.width - 2 * board.x, display.height - 2 * board.y):move(cc.pAdd(display.left_bottom, board)):addTo(self.viewLayer, zMax)
	cc.LayerColor:create(cc.c4b(255, 255, 0, 200), 2 * board.x, 2 * board.x):move(cc.pSub(display.center, board)):addTo(self.viewLayer, zMax + 1)

	local d = cc.DrawNode:create(board.x * 2):addTo(self.viewLayer, zMax + 2)

	d:drawLine(display.left_center, display.right_center, cc.c4b(255, 255, 0, 200))
	d:drawLine(display.top_center, display.bottom_center, cc.c4b(255, 255, 0, 200))
end

function GameUI:showIphoneXLayer()
	if device.platform ~= "windows" or device.model ~= "iphone x" then
		return
	end

	local zMax = 9999
	local size = cc.size(0.054187192118226604 * (2.1653333333333333 * display.height), 0.6 * display.height)

	cc.LayerColor:create(cc.c4b(0, 0, 255, 200), size.width, size.height):xy(display.board_left, (display.height - size.height) / 2):addTo(self.viewLayer, zMax)
	cc.LayerColor:create(cc.c4b(255, 0, 0, 200), size.width, size.height):xy(display.board_right - size.width, (display.height - size.height) / 2):addTo(self.viewLayer, zMax)
end

function GameUI:createView(name, parent, handlers)
	if parent and parent.onBeforeChildViewCreate then
		local view = parent:onBeforeChildViewCreate(name, handlers)

		if view then
			return view:show()
		end
	end

	local view = self.app:createView(name, parent, handlers)

	view:setName(name)

	if parent then
		local z = parent and parent:getChildrenCount() or 0

		view:addTo(parent, z)
	end

	return view:show()
end

local simpleView = class("simpleView", cc.load("mvc").ViewBase)

function GameUI:createSimpleView(t, parent, handlers)
	simpleView.RESOURCE_FILENAME = t.RESOURCE_FILENAME
	simpleView.RESOURCE_BINDING = t.RESOURCE_BINDING

	if parent and parent.onBeforeChildViewCreate then
		local view = parent:onBeforeChildViewCreate(t.RESOURCE_FILENAME, handlers)

		if view then
			return view:show()
		end
	end

	simpleView.RESOURCE_FILENAME = t.RESOURCE_FILENAME
	simpleView.RESOURCE_BINDING = t.RESOURCE_BINDING

	local view = simpleView:create(self.app, parent, handlers)

	view:setName(t.RESOURCE_FILENAME)

	if parent then
		local z = parent and parent:getChildrenCount() or 0

		view:addTo(parent, z)
	end

	return view:show()
end

function GameUI:doModal(node, name)
	if name then
		local n = self.modalLayer:getChildByName(name)

		if n then
			error(string.format("the node already on modal stack `%s`", name))
		end
	end

	if node:getParent() == self.modalLayer then
		error(string.format("the node already on modal stack %s", tostring(node)))
	end

	local parent = node:getParent()
	local x, y = node:getPosition()

	name = name or node:getName()

	table.insert(self.modalStack, {
		node = node,
		parent = parent,
		pos = cc.p(x, y),
		z = node:getLocalZOrder(),
		name = name
	})
	node:retain():show()
	node:removeSelf()

	if parent then
		local wpos = parent:convertToWorldSpace(cc.p(x, y))

		node:setPosition(wpos)
	end

	self.modalLayer:setVisible(true)
	self.modalLayer:addChild(node, #self.modalStack, name)
	self.modalLayer:setTouchEnabled(true)
	node:autorelease()
	printDebug("UI Modal Push %s %d %s", name, #self.modalStack, tostring(node))
end

function GameUI:unModal(nodeOrName)
	if #self.modalStack == 0 then
		printWarn("modal stack is empty")

		return
	end

	local name, node

	if type(nodeOrName) == "string" then
		name = nodeOrName
	else
		node = nodeOrName or self.modalStack[#self.modalStack].node
	end

	local modalIndex

	for i = #self.modalStack, 1, -1 do
		local modal = self.modalStack[i]

		if name and modal.node:getName() == name or modal.node == node then
			modalIndex = i

			break
		end
	end

	if modalIndex == nil then
		error(string.format("no such node on modal stack `%s`", tostring(nodeOrName)))
	end

	local modal = self.modalStack[modalIndex]

	table.remove(self.modalStack, modalIndex)
	modal.node:retain()
	modal.node:removeSelf():move(modal.pos):autorelease()

	if modal.parent then
		modal.parent:addChild(modal.node, modal.z, modal.name)
	end

	printDebug("UI Modal Pop [%d] %s %d %s", modalIndex, modal.name, #self.modalStack, tostring(modal.node))

	if #self.modalStack == 0 then
		self.modalLayer:setVisible(false)
		self.modalLayer:setTouchEnabled(false)
	end

	return modal.node
end

function GameUI:showDialog(params, styles)
	self:stackUI("common.prompt_box", nil, styles, params)
end

function GameUI:showDialogModel(params)
	local view = self:createView("common.prompt_box")

	view:onNodeEvent("exit", functools.partial(self.unModal, self, view))
	view:init(params)
	self:doModal(view)
end

function GameUI:showTimeSpeederIcon()
	local view = self:createView("common.time_speeder.icon")

	view:init()
	self.timeSpeederLayer:addChild(view)
	self.timeSpeederLayer:hide()

	self.timeSpeederIconView = view
end

function GameUI:showTimeSpeeder()
	local view = self:createView("common.time_speeder.view")

	view:init()
	self.timeSpeederLayer:addChild(view)
end

local function pushTipQueue(queue, view)
	view:onNodeEvent("exit", function()
		table.remove(queue, 1)
	end)

	for i = #queue, 1, -1 do
		if not queue[i].onMoveUp then
			table.remove(queue, i)
		end
	end

	if #queue == 3 then
		queue[1]:onClose()
	end

	for i = 1, #queue do
		queue[i]:onMoveUp()
	end

	table.insert(queue, view)
end

function GameUI:showTip(str, ...)
	local tip = string.format(str or "", ...)

	if #self.tipQueue > 0 then
		local v = self.tipQueue[#self.tipQueue]

		if v.content == tip then
			return
		end
	end

	local view = self:createView("common.tip", self.scene)

	if CC_DESIGN_RESOLUTION.autoscale == "FIXED_HEIGHT" then
		view:setPosition(display.uiOrigin.x, 0)
	end

	view:setLocalZOrder(LAYER.tip)
	view:init(tip)
	pushTipQueue(self.tipQueue, view)
end

function GameUI:pushAchievementTipQueue(queue, view)
	view:onNodeEvent("exit", function()
		table.remove(queue, 1)
	end)

	for i = #queue, 1, -1 do
		if not queue[i].onMoveUp then
			table.remove(queue, i)
		end
	end

	for i = 1, #queue do
		queue[i]:onMoveUp()
	end

	table.insert(queue, view)
end

function GameUI:showAchievement(csvId, params, force)
	params = params or {}

	local cfg = csv.achievement.achievement_task[csvId]

	if params.type then
		cfg = params.cfg
	end

	if not cfg then
		return
	end

	if not force and #self.achievementTipQueue >= 3 then
		table.insert(self.achievementTipWaitQueue, {
			csvId = csvId,
			params = params
		})

		if not self.achievementAction then
			self.achievementAction = schedule(self.scene, function()
				if #self.achievementTipWaitQueue == 0 then
					self.scene:stopAction(self.achievementAction)

					self.achievementAction = nil

					return
				end

				local top = self.achievementTipWaitQueue[1]

				table.remove(self.achievementTipWaitQueue, 1)
				self:showAchievement(top.csvId, top.params, true)
			end, 1)
		end

		return
	end

	local viewName = params.viewName or "common.achievement_tip"
	local view = self:createView(viewName, self.scene)

	if CC_DESIGN_RESOLUTION.autoscale == "FIXED_HEIGHT" then
		view:setPosition(display.uiOrigin.x, 0)
	end

	view:setLocalZOrder(LAYER.achievementTip)
	view:init(csvId, cfg)
	self:pushAchievementTipQueue(self.achievementTipQueue, view)
end

function GameUI:showMedalCollection(csvId)
	self:showAchievement(csvId, {
		type = "medal",
		viewName = "common.medalcollection_tip",
		cfg = csv.medal[csvId]
	})
end

function GameUI:cleanTip()
	while #self.tipQueue > 0 do
		self.tipQueue[1]:removeSelf()
	end
end

function GameUI:cleanAchievementTip()
	while #self.achievementTipQueue > 0 do
		self.achievementTipQueue[1]:removeSelf()
	end

	self.achievementTipWaitQueue = {}
end

function GameUI:showGainDisplay(data, params)
	self:stackUI("common.gain_display", nil, nil, data, params)
end

function GameUI:showBoxDetail(params)
	self:stackUI("common.box_detail", nil, nil, params)
end

function GameUI:showItemDetail(target, params)
	if self.itemDetailView then
		self.itemDetailView:onClose()
	end

	local name = "common.item_detail"
	local canvasDir = "vertical"
	local childsName = {
		"baseNode"
	}

	if params.key == "card" then
		name = "common.card_detail"
		canvasDir = "horizontal"
		childsName = {
			"baseCardNode"
		}
	elseif params.key == "relicBuff" then
		name = "common.relic_buff"
		canvasDir = params.canvasDir

		function params.relicCb()
			self:tryCloseItemDetail()
		end
	elseif dataEasy.getCfgByKey(params.key).type == game.ITEM_TYPE_ENUM_TABLE.chooseGift then
		self:stackUI("common.choose_detail", nil, nil, params)

		return
	elseif dataEasy.isHeldItem(params.key) then
		name = "common.held_item_detail"
		canvasDir = "horizontal"
	elseif dataEasy.isGemItem(params.key) then
		name = "common.gem_details"
		canvasDir = "horizontal"
	elseif dataEasy.isChipItem(params.key) then
		name = "common.chip_details"
		canvasDir = "horizontal"
	elseif dataEasy.isTotemItem(params.key) and dataEasy.isTotemUnlock() then
		name = "common.totem_item_detail"
		canvasDir = "horizontal"
	elseif dataEasy.isContractItem(params.key) then
		name = "common.contract_details"
		canvasDir = "horizontal"
	end

	local view = tip.create(name, nil, {
		relativeNode = target,
		canvasDir = canvasDir,
		childsName = childsName
	}, params)

	view:onNodeEvent("exit", functools.partial(self.unModal, self, view))
	self:doModal(view)

	self.itemDetailView = view
end

function GameUI:showItemDetailCustom(target, params, name, extraParams)
	extraParams = extraParams or {}

	if self.itemDetailView then
		self.itemDetailView:onClose()
	end

	local canvasDir = extraParams.canvasDir or "vertical"
	local childsName = extraParams.childsName or {
		"baseNode"
	}
	local tipParams = {
		relativeNode = target,
		canvasDir = canvasDir,
		childsName = childsName
	}

	if extraParams.tipParams then
		for k, v in pairs(extraParams.tipParams) do
			tipParams[k] = v
		end
	end

	local view = tip.create(name, nil, tipParams, params)

	view:onNodeEvent("exit", functools.partial(self.unModal, self, view))
	self:doModal(view)

	self.itemDetailView = view
end

function GameUI:onAuthError()
	local function cb()
		self.app:onBackLogin()
	end

	return self:showDialogModel({
		content = gLanguageCsv.auth_error,
		cb = cb,
		closeCb = cb,
		dialogParams = {
			clickClose = false,
			clearFast = true
		}
	})
end

function GameUI:onBan()
	local function cb()
		self.app:onBackLogin()
	end

	performWithDelay(self.scene, function()
		self:showDialogModel({
			content = gLanguageCsv.auth_error,
			cb = cb,
			closeCb = cb,
			dialogParams = {
				clickClose = false,
				clearFast = true
			}
		})
	end, 1)
end

function GameUI:onClose()
	if self.guideManager:isInGuiding() then
		self.guideManager:onClose()
	end

	if self.guideManagerLocal:isInGuiding() then
		self.guideManagerLocal:onClose()
	end

	self.timeSpeederManager:onClose()
	self:cleanStash()
	self.scene:removeAllChildren()
	self.modalLayer:autorelease()
	self.viewLayer:autorelease()
	self.guideLayer:autorelease()
	self.connectingLayer:autorelease()
	self.timeSpeederLayer:autorelease()
	self:removeAllDelayTouchDispatch()
	self.app:resumeRequest()

	self.isMultiTouches = false
end

function GameUI:onRequestError(err, errcb)
	if err.err == "files_error" then
		return display.director:endToLua()
	end

	local errStr = err.err

	if gLanguageCsv[errStr] then
		errStr = gLanguageCsv[errStr]

		if device.platform == "windows" then
			errStr = errStr .. "\n" .. err.err
		end
	end

	local sIndex = string.find(errStr, "#L00010100##LUL") or 0
	local eIndex = string.find(errStr, "#", sIndex + 15) or 0
	local url

	if sIndex > 0 and eIndex > 0 then
		url = string.sub(errStr, sIndex + 15, eIndex - 1)
	end

	self:showDialogModel({
		isRich = true,
		content = "#C0x5B545B#" .. errStr,
		cb = function()
			errcb()

			if url then
				cc.Application:getInstance():openURL(url)
			end
		end,
		closeCb = errcb,
		dialogParams = {
			clickClose = false
		}
	})
end

local ConnectingRes = {
	"effect/kedayahuang.skel",
	"effect/zhaoyueyuzhuan.skel"
}

function GameUI:showConnecting()
	local timeScale = self:getTimeScale(true)
	local delayReal = 0.5 * timeScale

	performWithDelay(self.connectingLayer, function()
		self.connectingLayer:removeChildByName("bg")

		local blackLayer = ccui.Layout:create():size(display.sizeInView):addTo(self.connectingLayer, 0, "bg")

		blackLayer:setBackGroundColorType(1)
		blackLayer:setBackGroundColor(cc.c3b(0, 0, 0))
		blackLayer:setBackGroundColorOpacity(50)

		local sprite = widget.addAnimationByKey(self.connectingLayer, ConnectingRes[math.random(#ConnectingRes)], "spine", "effect_loop"):xy(display.sizeInView.width / 2, display.sizeInView.height / 2):scale(2):z(1):hide()

		performWithDelay(sprite, function()
			sprite:show()
		end, delayReal)
	end, delayReal)
	self:doModal(self.connectingLayer, ConnectingNodeName)
end

function GameUI:hideConnecting()
	self:unModal(ConnectingNodeName)

	local timeScale = self:getTimeScale(true)
	local delayReal = 0.5 * timeScale

	performWithDelay(self.scene, function()
		if not self.connectingLayer:getParent() then
			self.connectingLayer:removeChildByName("bg")
			self.connectingLayer:removeChildByName("spine")
		end
	end, delayReal)
end

function GameUI:isConnecting()
	return self.modalLayer:getChildByName(ConnectingNodeName) and true or false
end

function GameUI:registerMessageListener(...)
	return messageComponent.registerMessageListener(...)
end

function GameUI:unregisterMessageListenerByKey(...)
	return messageComponent.unregisterMessageListenerByKey(...)
end

function GameUI:sendMessage(...)
	return messageComponent.sendMessage(...)
end

function GameUI:addViewDelayCall(view, f)
	self.delayCalls[view] = f
end

function GameUI:delViewDelayCall(view)
	self.delayCalls[view] = nil
end

function GameUI:doViewDelayCall()
	if itertools.isempty(self.delayCalls) then
		return
	end

	local delayCalls = self.delayCalls

	self.delayCalls = {}

	for view, f in pairs(delayCalls) do
		idlersystem.onViewBaseBegin(view)
		f()
		idlersystem.onViewBaseEnd(view)
	end
end

function GameUI:onUpdate(delta)
	self:doViewDelayCall()
end

local disableTouchDispatchTimes = 0

function GameUI:disableTouchDispatch(enableDelay, state)
	if not self.scene then
		return
	end

	disableTouchDispatchTimes = disableTouchDispatchTimes + 1

	local times = disableTouchDispatchTimes
	local dispatcher = display.director:getEventDispatcher()

	if state == true then
		if self.avoidClickCount == 0 and device.platform == "windows" then
			errorInWindows("GameUI:disableTouchDispatch(nil, true) avoidClickCount already is 0")
		end

		local action = performWithDelay(self.scene, function()
			if self.avoidClickCount == 0 and device.platform == "windows" then
				errorInWindows("GameUI:disableTouchDispatch(nil, true) after delay avoidClickCount already is 0")
			end

			self.avoidClickCount = self.avoidClickCount - 1

			if self.avoidClickCount <= 0 then
				self.avoidClickCount = 0

				dispatcher:setInputEnabled(true)
			end
		end, 0.01)

		action:setTag(TouchDispatchTag)
	else
		self.avoidClickCount = self.avoidClickCount + 1

		dispatcher:setInputEnabled(false)

		if enableDelay then
			local action = performWithDelay(self.scene, function()
				if self.avoidClickCount == 0 and device.platform == "windows" then
					errorInWindows("GameUI:disableTouchDispatch(delay) avoidClickCount already is 0")
				end

				self.avoidClickCount = self.avoidClickCount - 1

				if self.avoidClickCount <= 0 then
					self.avoidClickCount = 0

					dispatcher:setInputEnabled(true)
				end
			end, enableDelay)

			action:setTag(TouchDispatchTag)
		end
	end
end

function GameUI:removeAllDelayTouchDispatch()
	self.scene:stopAllActionsByTag(TouchDispatchTag)

	self.avoidClickCount = 0

	display.director:getEventDispatcher():setInputEnabled(true)
end

function GameUI:getConvertPos(node, parent)
	parent = parent or self.viewLayer

	local x, y = node:xy()
	local pos = node:parent():convertToWorldSpace(cc.p(x, y))

	return parent:convertToNodeSpace(pos)
end

function GameUI:getConvertPosAR(node, parent)
	parent = parent or self.viewLayer

	local x, y = node:xy()
	local pos = node:parent():convertToWorldSpaceAR(cc.p(x, y))
	local ret = parent:convertToNodeSpaceAR(pos)

	return ret
end

function GameUI:playVideo(path, cb)
	if FOR_SHENHE then
		if cb then
			cb()
		end

		return
	end

	local targetPlatform = cc.Application:getInstance():getTargetPlatform()

	if device.platform ~= "android" and device.platform ~= "ios" then
		printWarn("%s platform can't play video", device.platform)

		if cb then
			cb()
		end

		return
	end

	local videoFullPath = cc.FileUtils:getInstance():fullPathForFilename(path)

	printInfo("video start PLAY: %s", path)
	printInfo(videoFullPath)

	if #videoFullPath == 0 then
		printWarn("video path not exit %s", path)

		if cb then
			cb()
		end

		return
	end

	self.isPlayVideo = true

	local videoPlayer = ccexp.VideoPlayer:create():size(display.sizeInView):anchorPoint(0.5, 0.5):xy(display.size.width / 2, display.size.height / 2):addTo(self.viewLayer, 999)
	local layer = ccui.Layout:create():size(display.sizeInView):anchorPoint(0.5, 0.5):xy(display.size.width / 2, display.size.height / 2):addTo(self.viewLayer, 1000)

	layer:setTouchEnabled(true)

	local function onVideoClose()
		if not self.isPlayVideo then
			return
		end

		self.isPlayVideo = false

		layer:removeFromParent()
		videoPlayer:runAction(cc.CallFunc:create(function()
			videoPlayer:removeFromParent()
		end))
		cc.Director:getInstance():resume()
		audio.resumeMusic()
		self.uiRoot:show()

		if cb then
			cb()
		end
	end

	local times = 0

	layer:addTouchEventListener(function(sender, eventType)
		if eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
			times = times + 1

			printInfo("video skip click %d", times)

			if times >= 2 then
				printInfo("video skip COMPLETED %d", times)
				onVideoClose()
			end
		end
	end)
	self.uiRoot:hide()
	videoPlayer:addEventListener(function(sener, eventType)
		if eventType == ccexp.VideoPlayerEvent.PLAYING then
			printInfo("video PLAYING")
			audio.pauseMusic()
		elseif eventType == ccexp.VideoPlayerEvent.PAUSED then
			printInfo("video PAUSED")
		elseif eventType == ccexp.VideoPlayerEvent.STOPPED then
			printInfo("video STOPPED")
		elseif eventType == ccexp.VideoPlayerEvent.COMPLETED then
			printInfo("video COMPLETED")
			onVideoClose()
			printInfo("video COMPLETED over")
		end
	end)
	videoPlayer:setFileName(videoFullPath)
	videoPlayer:play()
end

function GameUI:onSwitchUI(oldName, name)
	self.app:onSwitchUI(oldName, name)
	self:sendMessage("switchUI", name)
	display.director:startAnimation()

	if ui.IGNORE_CLEAN_MAP[name] then
		return
	end

	local fileUtils = cc.FileUtils:getInstance()

	if oldName == "login.view" then
		performWithDelay(self.scene, function()
			if ui.IGNORE_CLEAN_MAP[self.rootViewName] then
				return
			end

			local n = display.textureCache:removeLongTimeUnusedTexturesWithCallback(function(delta, tex)
				local path = fileUtils:getRawPathInRepoCache(tex:getPath())

				return path:find("login") ~= nil
			end, 0, -1)

			printInfo("remove %d textures after close login.view in onSwitchUI", n)
		end, 5)
	elseif oldName == "battle.view" then
		performWithDelay(self.scene, function()
			if ui.IGNORE_CLEAN_MAP[self.rootViewName] then
				return
			end

			local n = display.textureCache:removeLongTimeUnusedTexturesWithCallback(function(delta, tex)
				local path = fileUtils:getRawPathInRepoCache(tex:getPath())

				return path:find("battle/") ~= nil or path:find("res/spine/koudai_") ~= nil
			end, 0, -1)

			printInfo("remove %d textures after close battle.view in onSwitchUI", n)
		end, 60)
	end
end

function GameUI:getTimeScale(isSpeedUp)
	if isSpeedUp then
		return display.director:getScheduler():getSpeedUp()
	end

	return display.director:getScheduler():getTimeScale()
end

function GameUI:callUnessentialInIdle(f, delay)
	delay = delay or 1

	if self.scene == nil or ui.IGNORE_CLEAN_MAP[self.rootViewName] then
		return
	end

	performWithDelay(self.scene, f, delay)
end

function GameUI:setMultiTouches(state)
	self.isMultiTouches = state

	if cc.Device.setMultipleTouchEnabled then
		cc.Device:setMultipleTouchEnabled(state)
	end
end

function GameUI:resizeScreen(w, h)
	if not w then
		w = display.sizeInPixels.width
		h = display.sizeInPixels.height
	end

	cc.Director:getInstance():getOpenGLView():setFrameSize(w, h)

	package.loaded.defines = nil
	package.preload.defines = nil
	package.loaded["cocos.framework.display"] = nil
	package.preload["cocos.framework.display"] = nil

	require("defines")

	display = require("cocos.framework.display")

	for k, v in pairs(package.loaded) do
		if string.find(k, "^app.views.") then
			package.loaded[k] = nil
		end
	end

	if not self.outSceneNode then
		self.outSceneNode = cc.Node:create()

		display.director:setNotificationNode(self.outSceneNode)
	end

	self.outSceneNode:removeAllChildren()

	if CC_DESIGN_RESOLUTION.autoscale == "SHOW_ALL" then
		local scaleX, scaleY = display.sizeInPixels.width / display.sizeInView.width, display.sizeInPixels.height / display.sizeInView.height
		local scale = math.min(scaleX, scaleY)
		local heightInPixels = (display.sizeInPixels.height - scale * display.sizeInView.height) / 2
		local backBoard1 = cc.LayerColor:create(cc.c4b(0, 0, 0, 255), display.sizeInView.width, heightInPixels / scaleY)
		local backBoard2 = cc.LayerColor:create(cc.c4b(0, 0, 0, 255), display.sizeInView.width, heightInPixels / scaleY)

		backBoard2:setPositionY((heightInPixels + scale * display.sizeInView.height) / scaleY)
		self.outSceneNode:addChild(backBoard1)
		self.outSceneNode:addChild(backBoard2)
	end

	if display.uiOrigin.x > display.uiOriginMax.x then
		local widthInPixels = display.uiOrigin.x - display.uiOriginMax.x
		local backBoard1 = cc.LayerColor:create(cc.c4b(0, 0, 0, 255), widthInPixels, display.sizeInView.height)
		local backBoard2 = cc.LayerColor:create(cc.c4b(0, 0, 0, 255), widthInPixels, display.sizeInView.height)

		backBoard2:setPositionX(widthInPixels + display.maxWidth)
		self.outSceneNode:addChild(backBoard1)
		self.outSceneNode:addChild(backBoard2)
	end

	if CC_DESIGN_RESOLUTION.autoscale == "FIXED_HEIGHT" then
		self.modalLayer:setPosition(display.uiOrigin.x, 0)
		self.viewLayer:setPosition(display.uiOrigin.x, 0)
		self.guideLayer:setPosition(display.uiOrigin.x, 0)
		self.timeSpeederLayer:setPosition(display.uiOrigin.x, 0)
	else
		self.modalLayer:setPosition(0, 0)
		self.viewLayer:setPosition(0, 0)
		self.guideLayer:setPosition(0, 0)
		self.timeSpeederLayer:setPosition(0, 0)
	end

	if self.scene:getChildByName("_editor_") then
		local btn = self.scene:getChildByName("_editor_"):get("editBtn")

		btn:setPosition(cc.p(300 - display.board_left, display.height - 100))

		local btnPanel = self.scene:getChildByName("_editor_"):get("btnPanel")

		btnPanel:setPosition(cc.p(300 - display.board_left, display.height - 100))
	end

	self.connectingLayer:setPosition(cc.p(display.board_left, 0))

	if self.uiRoot then
		self.stashUI = self.uiRoot
		self.stashUIName = self.rootViewName
		self.stashUIStack = {}

		for i = 2, #self.uiStack do
			table.insert(self.stashUIStack, self.uiStack[i])
		end

		self.stashUI:hide():retain():onClose()
		self.uiRoot:tearDown()

		self.uiRoot = nil
		self.rootViewName = nil

		self:switchUI(self.stashUIName)
	end
end

return GameUI
