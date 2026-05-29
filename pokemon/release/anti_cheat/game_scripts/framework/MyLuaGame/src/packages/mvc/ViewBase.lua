-- chunkname: @src.packages.mvc.ViewBase

local InitStepTotal = 6
local CreateStackDeep = 0
local ViewBase = class("ViewBase", cc.Node)
local PngBase = cclass("loading", cc.Node)

local function printViewDebug(fmt, view, ...)
	if DEBUG < 2 then
		return
	end

	local s = tostring(view)
	local notExtend = s:match("ccui.") == nil

	if notExtend then
		printDebug(fmt, s, ...)
	end
end

local function getViewCreateTrace(level)
	return getCallTrace(level, function(tb)
		local pos = tb.source:find("/app/views/")

		return pos
	end)
end

function ViewBase:ctor(app, parent, handlers)
	PngBase.ctor(self)

	self.app_ = app
	self.parent_ = parent
	self.inited_ = 0

	if device.platform == "windows" then
		self.from_ = getViewCreateTrace().desc
	end

	if handlers then
		for k, v in pairs(handlers) do
			if type(v) ~= "table" or v.__handler ~= true then
				error(string.format("%s is not handler, %s, please use ViewBase:createHandler", k, v))
			end

			self[k] = v
		end
	end

	local res = self.__class and rawget(self.__class, "RESOURCE_FILENAME")

	if res then
		self:createResourceNode(res)
	end

	local binding = self.__class and rawget(self.__class, "RESOURCE_BINDING")

	if res and binding then
		self.deferBinds_ = {}

		self:createResourceBinding(binding)
	end

	self:enableNodeEvents()

	if self.onUpdate then
		self:enableUpdate()
	end
end

function ViewBase:init(...)
	if self.parent_ and self.parent_.rebuiltIniting_ and not self.rebuiltIniting_ then
		self.initArgs_ = functools.args(...)
		self.parent_.rebuilt_[self] = true

		return self:beginRebuild()
	end

	self.inited_ = 1

	idlersystem.onViewBaseCreateBegin(self)

	self.initArgs_ = functools.args(...)

	if device.platform == "windows" then
		for i = 1, self.initArgs_:size() do
			local varg = self.initArgs_:at(i)

			if type(varg) ~= "table" or varg.__handler ~= true then
				assert(not isIdler(varg), "idler could not be onCreate's arg, it will be lost when ViewBase rebuild, use ViewBase:createHandler reimplement")
				assert(type(varg) ~= "function", "function could not be onCreate's arg, it will be problem when ViewBase rebuild, use ViewBase:createHandler replace")
			end
		end
	end

	self:onCreate_(...)

	self.inited_ = 4

	if self.rebuilding_ then
		self:onRebuild(self.parent_)
	end

	self.inited_ = 5

	idlersystem.onViewBaseCreateEnd(self)

	self.inited_ = InitStepTotal

	return self
end

function ViewBase:isRebuilding()
	return self.rebuilding_
end

function ViewBase:beRebuilding()
	if self:isRebuilding() then
		return true
	end

	if self.parent_ and self.parent_.rebuiltIniting_ and not self.rebuiltIniting_ and not self.parent_.rebuilt_[self] then
		return true
	end

	return false
end

function ViewBase:beginRebuild()
	self.rebuilding_ = true
	self.rebuilt_ = {}
	self.rebuiltIniting_ = true

	self:ctor(self.app_, self.parent_)

	local status, msg = xpcall(function()
		self:init(self.initArgs_:unpack())
	end, function(...)
		self.rebuiltIniting_ = false

		__G__TRACKBACK__(...)
	end)

	self.rebuiltIniting_ = false

	if not status then
		printError("beginRebuild error %s %s", status, msg)

		self.rebuilding_ = false

		return
	end

	for _, child in pairs(self:getChildren()) do
		if child.beginRebuild and not self.rebuilt_[child] then
			self.rebuilt_[child] = true

			child:beginRebuild()
		end
	end

	return self
end

function ViewBase:endRebuild()
	for _, child in pairs(self:getChildren()) do
		if child.endRebuild then
			child:endRebuild()
		end
	end

	self.rebuilding_ = nil
	self.rebuilt_ = nil
	self.rebuiltIniting_ = nil

	return self
end

function ViewBase:tearDown()
	if self.resourceNode_ then
		self.resourceNode_:removeSelf()

		self.resourceNode_ = nil
	end

	for _, child in pairs(self:getChildren()) do
		if child.tearDown then
			child:tearDown()
		else
			child:removeSelf()
		end
	end
end

function ViewBase:getApp()
	return self.app_
end

function ViewBase:getResourceNode(path)
	if path then
		return nodetools.get(self.resourceNode_, path)
	else
		return self.resourceNode_
	end
end

function ViewBase:createHandler(name, ...)
	local val = self[name]

	if type(val) == "function" then
		local method = self.__class[name]

		assert(type(method) == "function", "ViewBase:createHandler() - not such method in class")

		local vargs = functools.args(...)

		return functools.tablefunc({
			__handler = true
		}, function(t, ...)
			if tolua.isnull(self) then
				return
			end

			local method = self.__class[name]

			assert(type(method) == "function", "ViewBase:createHandler() - not such method in class")

			if vargs:size() == 0 then
				return method(self, ...)
			else
				local vargs2 = vargs + functools.args(...)

				return method(self, vargs2:unpack())
			end
		end)
	else
		return functools.tablefunc({
			__handler = true
		}, function()
			return self[name]
		end)
	end
end

function ViewBase:createResourceNode(resourceFilename)
	if self.resourceNode_ then
		self.resourceNode_:removeSelf()

		self.resourceNode_ = nil
	end

	self.resource_ = resourceFilename
	self.resourceNode_ = cache.createWidget(resourceFilename)

	self:addChild(self.resourceNode_)
end

function ViewBase:createResourceBinding(binding)
	assert(self.resourceNode_, "ViewBase:createResourceBinding() - not load resource node")
	bindUI(self, self.resourceNode_, binding)
end

function ViewBase:deferUntilCreated(f)
	if self.deferBinds_ == nil then
		return f()
	end

	return table.insert(self.deferBinds_, f)
end

function ViewBase:enableUpdate()
	if self.updating_ then
		return
	end

	self.updating_ = true

	self:scheduleUpdate(function(...)
		return self:onUpdate_(...)
	end)
end

function ViewBase:disableUpdate()
	self.updating_ = false

	self:unscheduleUpdate()
end

function ViewBase:isUpdateEnabled()
	return self.updating_ or false
end

function ViewBase:onCreate_(...)
	self._cbsOnExit = {}

	local st = os.clock()

	printViewDebug("ViewBase:onCreate_ start %s", self)

	if self.onCreate then
		CreateStackDeep = CreateStackDeep + 1

		self:onCreate(...)

		CreateStackDeep = CreateStackDeep - 1
	end

	self.inited_ = 2

	if self.deferBinds_ then
		local binds = self.deferBinds_

		self.deferBinds_ = nil

		for _, f in pairs(binds) do
			f()
		end
	end

	self.inited_ = 3

	printViewDebug("ViewBase:onCreate_ end %s %s", self, os.clock() - st)

	return self
end

function ViewBase:onUpdate_(delta)
	if self.updating_ and self.onUpdate then
		return self:onUpdate(delta)
	end
end

function ViewBase:assertInited()
	local s

	if self.inited_ == 0 then
		s = string.format("%s(%s), if you want removeSelf in onCreate, plz try performWithDelay or you not init() when create", tj.type(self), self:name())
	elseif self.inited_ < InitStepTotal then
		s = string.format("%s(%s), may be error in init(), it would cause next other error, inited=%d", tj.type(self), self:name(), self.inited_)
	end

	if s then
		performWithDelay(gGameUI.scene, function()
			errorInWindows(s)
		end, 0)
	end
end

function ViewBase:onExit()
	printViewDebug("ViewBase:onExit %s", self)
	self:assertInited()
	self.app_.ui:delViewDelayCall(self)
	self:disableUpdate()

	local names = table.keys(cc.components(self))

	if #names > 0 then
		cc.unbind(self, unpack(names))
	end

	return cc.Node.onExit(self)
end

function ViewBase:onCleanup()
	printViewDebug("ViewBase:onCleanup %s %s %s", self, self.__inject, self:getName())
	idlersystem.onViewBaseCleanup(self)

	return cc.Node.onCleanup(self)
end

function ViewBase:onClose()
	printViewDebug("ViewBase:onClose %s", self)
	self:delayCallOnExit()
	self:removeSelf()
end

function ViewBase:onRebuild(parent)
	return
end

function ViewBase:onBeforeChildViewCreate(name, handlers)
	if not self.rebuilding_ then
		return
	end

	local view = self:getChildByName(name)

	if view then
		if not self.rebuilt_[view] then
			view:ctor(self.app_, self, handlers)
		end

		self.rebuilt_[view] = true
	end

	return view
end

function ViewBase:onStackHide(skipHash)
	if self.stackShows_ ~= nil then
		return
	end

	skipHash = skipHash or {}
	self.stackShows_ = {}

	for _, child in pairs(self:getChildren()) do
		if child:isVisible() then
			self.stackShows_[child] = true
		end

		if not skipHash[child] then
			child:hide()
		end
	end
end

function ViewBase:onStackShow()
	if self.stackShows_ == nil then
		return
	end

	local stackShows_ = self.stackShows_

	self.stackShows_ = nil

	for _, child in pairs(self:getChildren()) do
		if stackShows_[child] then
			child:show()
		end
	end
end

function ViewBase:addCallbackOnExit(cb, front)
	if cb == nil then
		return self
	end

	assert(self._cbsOnExit, string.format("%s ViewBase add callback after exited", tostring(self)))

	if front then
		table.insert(self._cbsOnExit, 1, cb)
	else
		table.insert(self._cbsOnExit, cb)
	end

	return self
end

function ViewBase:delayCallOnExit()
	local cbs = self._cbsOnExit

	self._cbsOnExit = nil

	if cbs then
		if next(cbs) then
			performWithDelay(gGameUI.scene, function()
				for _, cb in ipairs(cbs) do
					cb()
				end
			end, 0)
		end
	else
		errorInWindows("ViewBase delayCallOnExit be call more then once or onCreate not be call")
	end
end

function ViewBase:bindEasy(pathOrNode)
	local node = pathOrNode

	if type(pathOrNode) == "string" then
		node = nodetools.get(self.resourceNode_, path)
	end

	if node == nil then
		return
	end

	return functools.chaincall(bind, self, node)
end

function ViewBase:nodeListenIdler(pathOrNode, pathOrIdler, f)
	local node = pathOrNode

	if type(pathOrNode) == "string" then
		node = nodetools.get(self.resourceNode_, path)
	end

	if node == nil then
		return
	end

	local idler = pathOrIdler

	if type(pathOrIdler) == "string" then
		idler = self[pathOrIdler]
	end

	if idler == nil then
		return
	end

	return node:listenIdler(idler, f)
end

function ViewBase.safeCall(view, fName, ...)
	if tolua.isnull(view) then
		return
	end

	local f = view[fName]

	if f == nil then
		return
	end

	return f(view, ...)
end

local supportComponents = {
	"schedule",
	"asyncload",
	"message"
}

for _, name in ipairs(supportComponents) do
	local capname = string.caption(name)

	ViewBase[string.format("enable%s", capname)] = function(self)
		local components = cc.components(self)

		if not components[name] then
			cc.bind(self, name)
		end

		return self
	end
	ViewBase[string.format("disable%s", capname)] = function(self)
		local components = cc.components(self)

		if components[name] then
			cc.unbind(self, name)
		end

		return self
	end
	ViewBase[string.format("is%sEnabled", capname)] = function(self)
		local components = cc.components(self)

		return components[name] ~= nil
	end
end

return ViewBase
