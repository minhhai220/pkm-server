-- chunkname: @src.app.easy.bind.extend.sort_menus

local listview = require("easy.bind.extend.listview")
local inject = require("easy.bind.extend.inject")
local helper = require("easy.bind.helper")
local sortMenus = class("sortMenus", cc.load("mvc").ViewBase)
local menus = {}

menus.RESOURCE_FILENAME = "common_sort_menus.json"
menus.RESOURCE_BINDING = {
	btn7 = "btn7",
	btn6 = "btn6",
	btn5 = "btn5",
	btn4 = "btn4",
	btn3 = "btn3",
	btn2 = "btn2",
	btn1 = "btn1",
	list = "list",
	item = "item",
	listBg = "listBg"
}
sortMenus.defaultProps = {
	maxCount = 5.5,
	expandUp = false,
	btnType = 1,
	btnHeight = 122,
	btnWidth = 332,
	height = 80,
	width = 308,
	ignoreSelected = false,
	showLock = true
}

function sortMenus:initExtend()
	local width = self.width
	local height = self.height

	self._width = width
	self.width = cc.Node.width
	self.height = cc.Node.height
	self.showSortList = self.showSortList or idler.new(false)
	self.menuClick = self.menuClick or idler.new(true)
	self.lock = self.locked or idler.new(0)

	local node = gGameUI:createSimpleView(menus, self):init()

	node.item:size(width, height):hide()
	node.item:get("bg"):size(width, height)

	self.node = node

	for i = 1, 7 do
		if i ~= self.btnType then
			node["btn" .. i]:hide()
		end
	end

	local btn = node["btn" .. self.btnType]
	local btnTitle = btn:get("title")
	local btnWidth = self.btnWidth or width
	local color = self.btnType <= 3 and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.RED
	local effectData = {
		40,
		20,
		20,
		40,
		40,
		0
	}
	local effectH = effectData[self.btnType] or 40
	local size = cc.size(btnWidth, self.btnHeight or height + effectH)

	setContentSizeOfAnchor(btn, size)

	local noEffect = {
		5,
		6,
		7
	}

	if not itertools.include(noEffect, self.btnType) then
		text.addEffect(btnTitle, {
			glow = {
				color = ui.COLORS.GLOW.WHITE
			},
			color = color
		})
	end

	btn:get("img"):x(btnWidth - 57 * (self.btnType == 2 and 0.9 or 1))
	bind.touch(node, btn, {
		methods = {
			ended = function(view, sender)
				self.showSortList:modify(function(val)
					return true, not val
				end)

				if self.btnTouch then
					self.btnTouch(sender)
				end
			end
		}
	})
	idlereasy.when(self.showSortList, function(obj, show)
		if self.btnType ~= 6 then
			if self.expandUp then
				btn:get("img"):rotate(not show and 0 or 180)
			else
				btn:get("img"):rotate(show and 0 or 180)
			end
		end

		node.list:visible(show)
		node.listBg:visible(show)
	end)
	idlereasy.when(self.menuClick, function(obj, menuClick)
		btn:setTouchEnabled(menuClick)
	end)

	if self.showSelected then
		self.showSelected = isIdler(self.showSelected) and self.showSelected or idler.new(self.showSelected)
	else
		self.showSelected = idler.new(1)
	end

	self.stateData = idlers.new()
	self.isFirst = true

	idlereasy.any({
		self.data,
		self.lock
	}, function(obj, data, lock)
		self:lockData(data, lock, width, height)
	end):notify()

	local view = self.parent_
	local handlers = self.__handlers
	local props = {
		data = self.stateData,
		item = node.item,
		onItem = functools.partial(self.onItem_, self),
		onItemClick = functools.partial(self.onItemClick, self)
	}

	inject(listview, view, node.list, handlers, helper.props(view, node.list, props)):initExtend()
	helper.callOrWhen(self.defaultTitle, function(defaultTitle)
		btnTitle:text(defaultTitle)
	end)
	self.showSelected:addListener(function(val, oldval)
		if self.stateData:atproxy(oldval) then
			self.stateData:atproxy(oldval).selected = false
		end

		if self.stateData:atproxy(val) then
			self.stateData:atproxy(val).selected = true

			if not self.defaultTitle then
				btnTitle:text(self.stateData:atproxy(val).name)
			end

			local xPos

			if self.btnType ~= 2 then
				xPos = self.btnWidth and self.btnWidth / 2 - 30 or width / 2 - 30
			else
				xPos = self.btnWidth and self.btnWidth / 2 - 20 or width / 2 - 20
			end

			btnTitle:x(xPos)

			if not matchLanguage({
				"cn",
				"tw"
			}) then
				adapt.setTextScaleWithWidth(btnTitle, nil, self.btnWidth - 100)
			end
		end
	end)
	btn:show()

	if self.onNode then
		self.onNode(node)
	end

	if self.titleAnchorPoint then
		btnTitle:setAnchorPoint(self.titleAnchorPoint)
	end

	self.isFirst = false

	return self
end

function sortMenus:onItem_(list, node, k, v)
	local title = node:get("title")

	if self.btnType ~= 2 then
		title:x(44)
	else
		title:x(10)
	end

	node:get("bg"):visible(v.selected)
	title:text(v.name)

	local color = v.selected and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.RED

	title:setTextColor(color)

	local width = math.max(self._width - 30, 230)

	title:anchorPoint(0.5, 0.5)
	title:x(node:width() / 2)
	adapt.setTextScaleWithWidth(title, nil, width)

	local lock = node:get("lock")

	if v.lock then
		if lock then
			lock:show()
		elseif self.showLock then
			lock = ccui.ImageView:create("common/btn/btn_lock.png"):align(cc.p(0.5, 0.5), 0, title:y()):addTo(node, 4, "lock")

			adapt.oneLinePos(title, lock, cc.p(10, 0), "right")
		end
	elseif lock then
		lock:hide()
	end

	if self.onItem then
		self:onItem(node, k, v)
	end
end

function sortMenus:lockData(data, lock, width, height)
	local node = self.node
	local btn = node["btn" .. self.btnType]
	local maxCount = math.min(self.maxCount, #data)
	local anchorPoint = btn:anchorPoint()
	local baseX = btn:x() - width * anchorPoint.x - 12
	local marg = (maxCount - 1) * 10

	if not self.expandUp then
		node.listBg:size(width + 24, height * maxCount + 86 + marg):anchorPoint(0, 1):xy(baseX, btn:y() - btn:size().height * anchorPoint.y)
		node.list:size(width, height * maxCount + marg):anchorPoint(0, 1):xy(baseX + 10, node.listBg:y() - 40)
	else
		node.listBg:size(width + 24, height * maxCount + 86 + marg):anchorPoint(0, 0):xy(baseX, btn:y() + btn:size().height / 2)
		node.list:size(width, height * maxCount + marg):xy(baseX + 10, node.listBg:y() + 46)
	end

	self.showSortList:set(false)

	local nowSelected = cc.clampf(self.showSelected:read(), 1, #data)
	local t = {}

	for i, v in ipairs(data) do
		t[i] = {
			name = v,
			lock = lock ~= 0 and lock <= i,
			selected = i == nowSelected
		}
	end

	self.stateData:update(t)

	if not self.isFirst or nowSelected ~= self.showSelected:read() then
		self.showSelected:set(nowSelected, true)
	end
end

function sortMenus:onItemClick(list, node, k, v)
	local oldval = self.showSelected:read()

	if not v.lock then
		if not self.ignoreSelected then
			self.showSelected:set(k)
		end

		self.showSortList:set(false)
	end

	self.btnClick(node, k, v, oldval)
end

return sortMenus
