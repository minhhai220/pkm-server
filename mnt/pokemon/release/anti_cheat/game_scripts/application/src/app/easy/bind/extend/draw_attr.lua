-- chunkname: @src.app.easy.bind.extend.draw_attr

local helper = require("easy.bind.helper")
local drawAttr = class("drawAttr", cc.load("mvc").ViewBase)
local ATTR_MAX_VAL = 31

drawAttr.defaultProps = {
	perfectShow = true,
	type = "small",
	lock = false,
	offsetPos = {
		{
			x = 0,
			y = 0
		},
		{
			x = 0,
			y = 0
		},
		{
			x = 0,
			y = 0
		},
		{
			x = 0,
			y = 0
		},
		{
			x = 0,
			y = 0
		},
		{
			x = 0,
			y = 0
		}
	},
	nvalue = {
		0,
		0,
		0,
		0,
		0,
		0
	}
}

local hexagonItem = {}

hexagonItem.RESOURCE_FILENAME = "common_hexagon_item.json"
hexagonItem.RESOURCE_BINDING = {
	txt = "panel.txt",
	num = "panel.num",
	perfect = "panel.perfect",
	imgType = "panel.imgType",
	panel = "panel",
	lock = "panel.lock"
}

function drawAttr:refresh(nvalue)
	local img = self.panel:get("img")
	local bgSize = img:size()
	local drawNode = img:get("MyDrawNode")

	if not drawNode then
		drawNode = cc.DrawNode:create()

		drawNode:alignCenter(img:size()):addTo(img, 3, "MyDrawNode")
	end

	drawNode:clear()

	local x, y = 0, 0
	local d = 220
	local g3 = math.sqrt(3)
	local dLength = {}

	for i, v in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
		table.insert(dLength, d * (nvalue[v] or 0) / ATTR_MAX_VAL)
	end

	local pointTab = {
		cc.p(x, y + dLength[1]),
		cc.p(x + dLength[2] / 2 * g3, y + dLength[2] / 2),
		cc.p(x + dLength[3] / 2 * g3, y - dLength[3] / 2),
		cc.p(x, y - dLength[4]),
		cc.p(x - dLength[5] / 2 * g3, y - dLength[5] / 2),
		cc.p(x - dLength[6] / 2 * g3, y + dLength[6] / 2)
	}
	local size = self.item:size()
	local offset = cc.p(bgSize.width / 2 + 90, bgSize.height - 50)
	local offsetPos = self.offsetPos
	local itemPos = {
		cc.p(offset.x + offsetPos[1].x, offset.y + d + offsetPos[1].y),
		cc.p(offset.x + d / 2 * g3 + offsetPos[2].x, offset.y + d / 2 + offsetPos[2].y),
		cc.p(offset.x + d / 2 * g3 + offsetPos[3].x, offset.y - d / 2 + offsetPos[3].y),
		cc.p(offset.x + offsetPos[4].x, offset.y - d + offsetPos[4].y),
		cc.p(offset.x - d / 2 * g3 + offsetPos[5].x, offset.y - d / 2 + offsetPos[5].y),
		cc.p(offset.x - d / 2 * g3 + offsetPos[6].x, offset.y + d / 2 + offsetPos[6].y)
	}
	local hash3 = arraytools.hash({
		3,
		4,
		5
	})

	for i, v in ipairs(self.itemNodes) do
		local lock = v:get("lock")
		local num = v:get("num")
		local txt = v:get("txt")
		local zwakeAdd = v:get("zwake_add")
		local anchorPointX = self.lock and 1 or 0.5
		local offsetX = self.lock and lock:x() - 30 or txt:x() + txt:width() / 2

		if self.numFontSize then
			num:setFontSize(self.numFontSize)
		end

		num:text(nvalue[game.ATTRDEF_SIMPLE_TABLE[i]]):anchorPoint(anchorPointX, 0.5)
		v:get("perfect"):visible(nvalue[game.ATTRDEF_SIMPLE_TABLE[i]] == ATTR_MAX_VAL and self.perfectShow)
		v:xy(itemPos[i])
		adapt.oneLineCenterPos(cc.p(txt:x() + 44, num:y()), {
			num,
			zwakeAdd,
			lock
		}, {
			cc.p(0, 3),
			cc.p(5, 2)
		})
	end

	local idx = 1

	for i = 1, #pointTab do
		local ps = {
			pointTab[idx],
			pointTab[idx + 1] or pointTab[1],
			cc.p(x, y)
		}

		drawNode:drawPolygon(ps, 3, cc.c4f(0.9450980392156862, 0.3607843137254902, 0.3843137254901961, 0.6), 0.5, cc.c4f(0.9450980392156862, 0.3607843137254902, 0.3843137254901961, 0.6))

		idx = idx + 1
	end

	img:xy(self.offset.x, self.offset.y)
end

function drawAttr:baseShow()
	self.itemNodes = {}

	if self.panel then
		self.panel:removeFromParent()
	end

	local panel = ccui.Layout:create():size(198, 198):alignCenter(self:size()):addTo(self, 1, "_draw_")
	local scale = self.bgScale or self.type == "small" and 1.8 or 1
	local img = ccui.ImageView:create("city/card/system/nvalue/bg_individual.png"):scale(scale):addTo(panel, 2, "img"):alignCenter(panel:size())

	self.panel = panel

	local hexagonItemView = gGameUI:createSimpleView(hexagonItem, self):init()

	hexagonItemView:hide()

	self.item = hexagonItemView.panel

	self.item:hide()

	local childs = self.item:multiget("perfect", "txt", "lock", "imgType", "num")

	if self.type == "small" then
		itertools.invoke({
			childs.txt,
			childs.num
		}, "setFontSize", 45)
		childs.txt:y(childs.txt:y() - 10)
		childs.lock:hide()
	elseif self.lock == false then
		childs.lock:hide()
	end

	local hash1 = arraytools.hash({
		1
	})
	local hash2 = arraytools.hash({
		2,
		6
	})
	local hash3 = arraytools.hash({
		3,
		4,
		5
	})

	for i = 1, 6 do
		local itemClone = self.item:clone():tag(i):scale(self.type == "small" and 0.68 or 1)

		table.insert(self.itemNodes, itemClone)

		local childs = itemClone:multiget("perfect", "txt", "lock", "imgType", "num", "zwake_add")

		childs.txt:text(getLanguageAttr(game.ATTRDEF_SIMPLE_TABLE[i]))

		if self.textFontSize then
			childs.txt:setFontSize(self.textFontSize)
		end

		childs.imgType:texture(ui.ATTR_LOGO[game.ATTRDEF_SIMPLE_TABLE[i]])
		itemClone:show()
		itemClone:addTo(self.panel, 5, "tag" .. i)

		if hash3[i] then
			local y1 = childs.num:y()

			childs.perfect:y(y1 - 55)
			itertools.invoke({
				childs.imgType,
				childs.txt
			}, "y", y1 + 50)
		end

		if hash2[i] then
			local y1 = childs.txt:y()

			childs.perfect:y(y1 - 60)
		end

		childs.zwake_add:hide()
	end
end

function drawAttr:zwakeAdd(zwakeValue)
	local img = self.panel:get("img")

	img:removeChildByName("zwake")

	self.zwakeImg = ccui.ImageView:create("city/zawake/logo_z.png"):scale(1):addTo(img, 10, "zwake"):alignCenter(img:size())

	self.zwakeImg:visible(not itertools.isempty(zwakeValue))

	local value = {}

	for key, v in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
		value[key] = zwakeValue[v]
	end

	for i = 1, 6 do
		local item = self.panel:getChildByName("tag" .. i)
		local textZwakeAdd = item:get("zwake_add")

		if value[i] then
			textZwakeAdd:show()
			textZwakeAdd:text(string.format("(+%d)", value[i]))
		else
			textZwakeAdd:hide()
		end

		local lock = item:get("lock")
		local num = item:get("num")
		local zwakeAdd = item:get("zwake_add")
		local x = item:get("txt"):x()
		local y = item:get("num"):y()

		adapt.oneLineCenterPos(cc.p(x + 44, y), {
			num,
			zwakeAdd,
			lock
		}, {
			cc.p(0, 3),
			cc.p(5, 2)
		})
	end
end

function drawAttr:initExtend()
	self:baseShow()
	helper.callOrWhen(self.nvalue, functools.partial(self.refresh, self))
	helper.callOrWhen(self.zwakeValue, functools.partial(self.zwakeAdd, self))

	if self.nvalueLocked then
		idlereasy.when(self.nvalueLocked, function(_, nvalueLocked)
			for i, v in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
				local state = nvalueLocked[v] or false
				local lockImg = "common/btn/btn_unlock_big.png"

				if state then
					lockImg = "common/btn/btn_lock_big.png"
				end

				local node = self.itemNodes[i]
				local lock = self.itemNodes[i]:get("lock")
				local num = self.itemNodes[i]:get("num")
				local zwakeAdd = self.itemNodes[i]:get("zwake_add")

				lock:show()
				lock:texture(lockImg)

				local x = self.itemNodes[i]:get("txt"):x()
				local y = self.itemNodes[i]:get("num"):y()

				adapt.oneLineCenterPos(cc.p(x + 44, y), {
					num,
					zwakeAdd,
					lock
				}, {
					cc.p(0, 3),
					cc.p(5, 2)
				})
			end
		end)

		local function getTouchCbParams()
			local nvalueLocked = self.nvalueLocked:read()
			local tmpLockNum = 0

			for i, v in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
				if nvalueLocked[v] then
					tmpLockNum = tmpLockNum + 1
				end
			end

			local state = nvalueLocked[v] or false

			return tmpLockNum, state
		end

		for i, v in ipairs(game.ATTRDEF_SIMPLE_TABLE) do
			local node = self.itemNodes[i]
			local lock = self.itemNodes[i]:get("lock")

			if lock and self.lockCb then
				bind.touch(self, node, {
					methods = {
						ended = function()
							local tmpLockNum, state = getTouchCbParams()

							self.lockCb(self, i, self.selectDbId, tmpLockNum, state)
						end
					}
				})
				lock:setTouchEnabled(true)
				bind.touch(self, lock, {
					methods = {
						ended = function()
							local tmpLockNum, state = getTouchCbParams()

							self.lockCb(self, i, self.selectDbId, tmpLockNum, state)
						end
					}
				})
			end
		end
	end

	if self.onNode then
		self.onNode(self.panel)
	end

	return self
end

return drawAttr
