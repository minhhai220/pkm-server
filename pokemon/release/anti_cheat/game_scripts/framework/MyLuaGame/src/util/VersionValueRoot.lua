-- 全局唯一 ID 计数器
local idCounter = 0

-- 版本化的 Value（引用自 Root）
local VersionValue = {}
VersionValue.__index = VersionValue

function VersionValue.new(root)
	idCounter = idCounter + 1

	local id = idCounter
	local self = setmetatable({
		__id = id
	}, VersionValue)

	self:ctor(root)

	return self
end

function VersionValue:ctor(root)
	self.root = root
	self.version = 0
end

function VersionValue:get()
	self.version = self.root.version
	return self.root.value
end

function VersionValue:isChanged()
	return self.version ~= self.root.version
end

function VersionValue:setChangedCallback(callback)
	assert(self.callback == nil, "VersionValue called more than once setChangedCallback")

	if self.callback == nil then
		self.callback = callback
		self.root:addCallback(callback)
	end
end

function VersionValue:destroy()
	if self.callback then
		self.root:delCallback(self.callback)
		self.callback = nil
	end
	self.root = nil
end

-- 全局挂载
globals.VersionValueRoot = {}
local VersionValueRoot = globals.VersionValueRoot
VersionValueRoot.__index = VersionValueRoot

function VersionValueRoot.new(initialValue)
	idCounter = idCounter + 1

	local id = idCounter
	local self = setmetatable({
		__root = true,
		__id = id
	}, VersionValueRoot)

	self:ctor(initialValue)

	return self
end

function VersionValueRoot:ctor(initialValue)
	self.value = initialValue
	self.version = 0
end

function VersionValueRoot:set(newValue)
	self.value = newValue
	self.version = self.version + 1

	if self.callbacks then
		for _, cb in ipairs(self.callbacks) do
			cb()
		end
	end
end

function VersionValueRoot:cmpSet(newValue)
	if newValue == self.value then
		return
	end
	self:set(newValue)
end

function VersionValueRoot:get()
	return self.value
end

function VersionValueRoot:newValue()
	return VersionValue.new(self)
end

function VersionValueRoot:addCallback(cb)
	if self.callbacks == nil then
		self.callbacks = {}
	end
	table.insert(self.callbacks, cb)
end

function VersionValueRoot:delCallback(cb)
	local count = self.callbacks and #self.callbacks or 0
	if count > 0 then
		for i, fn in ipairs(self.callbacks) do
			if fn == cb then
				self.callbacks[i] = self.callbacks[count]
				table.remove(self.callbacks)
				return
			end
		end
	end
end
