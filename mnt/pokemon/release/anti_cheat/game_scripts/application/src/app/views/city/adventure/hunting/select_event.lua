-- chunkname: @src.app.views.city.adventure.hunting.select_event

local EVENT_TYPE = {
	boxDropLibs = 1,
	supplyGroup = 2
}
local LOGO_TYPE = {
	{
		"city/adventure/hunting/box_orange.png",
		"city/adventure/hunting/img_ptxlj.png",
		gLanguageCsv.commonPk
	},
	{
		"city/adventure/hunting/box_purple.png",
		"city/adventure/hunting/img_jyxlj.png",
		gLanguageCsv.seniorPk
	},
	{
		"city/adventure/hunting/box_pink.png",
		"city/adventure/hunting/img_sqbbzx@.png",
		gLanguageCsv.huntingCure
	}
}
local COLOR_TYPE = {
	cc.c3b(161, 137, 113, 1),
	cc.c3b(159, 108, 172, 1),
	(cc.c3b(222, 106, 130, 1))
}
local CARD_TYPE = {
	eliteGate = 2,
	normalGate = 1,
	careCenter = 3
}
local ViewBase = cc.load("mvc").ViewBase
local HuntingSelectEventView = class("HuntingSelectEventView", ViewBase)

HuntingSelectEventView.RESOURCE_FILENAME = "hunting_select_event.json"
HuntingSelectEventView.RESOURCE_BINDING = {
	item = "item",
	title = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 6,
					color = cc.c3b(192, 91, 69, 1)
				}
			}
		}
	},
	list = {
		varname = "eventList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("eventDatas"),
				item = bindHelper.self("item"),
				margin = bindHelper.self("eventMargin"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("bg", "icon", "select", "name")

					if v.type == CARD_TYPE.normalGate then
						childs.bg:texture(LOGO_TYPE[1][1])
						childs.icon:texture(LOGO_TYPE[1][2]):xy(317, 483)
						childs.name:text(LOGO_TYPE[1][3])
						text.addEffect(childs.name, {
							color = COLOR_TYPE[1]
						})
					elseif v.type == CARD_TYPE.eliteGate then
						childs.bg:texture(LOGO_TYPE[2][1])
						childs.icon:texture(LOGO_TYPE[2][2]):xy(317, 483)
						childs.name:text(LOGO_TYPE[2][3])
						text.addEffect(childs.name, {
							color = COLOR_TYPE[2]
						})
					else
						childs.bg:texture(LOGO_TYPE[3][1])
						childs.icon:texture(LOGO_TYPE[3][2]):xy(317, 437)
						childs.name:text(LOGO_TYPE[3][3])
						text.addEffect(childs.name, {
							color = COLOR_TYPE[3]
						})
					end

					childs.select:visible(v.select)
					bind.touch(list, node, {
						clicksafe = false,
						methods = {
							ended = functools.partial(list.clickCell, k)
						}
					})
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end
			},
			handlers = {
				clickCell = bindHelper.self("clickCell")
			}
		}
	},
	btnSure = {
		varname = "eventSure",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onEventSure")
			}
		}
	}
}

function HuntingSelectEventView:onCreate(node, cb)
	self.node = node
	self.cb = cb
	self.selectNum = 1
	self.eventMargin = 100
	self.eventDatas = idlers.new()

	self:initModel()
end

function HuntingSelectEventView:initModel()
	local t = {}
	local cfg = csv.cross.hunting.route[self.node]

	self.routeType = cfg.routeTag

	local eventDatas = {}

	for k, v in pairs(cfg.gateIDs) do
		local gateCfg = csv.cross.hunting.gate[v]
		local type = gateCfg.type

		table.insert(eventDatas, {
			id = v,
			type = type
		})
	end

	table.sort(eventDatas, function(a, b)
		return a.type < b.type
	end)

	if cfg.supplyGroup > 0 then
		table.insert(eventDatas, {
			id = -1,
			type = 3
		})
	end

	for k, v in pairs(eventDatas) do
		if k == 1 then
			v.select = true
		else
			v.select = false
		end
	end

	self.data = eventDatas
	self.eventMargin = itertools.size(eventDatas) == 2 and 400 or 100

	self.eventDatas:update(eventDatas)
	self.eventList:setTouchEnabled(false)
end

function HuntingSelectEventView:onClose()
	self:addCallbackOnExit(self.cb, true)
	ViewBase.onClose(self)

	return self
end

function HuntingSelectEventView:clickCell(k, v)
	for i = 1, #self.data do
		if i == v then
			self.eventDatas:atproxy(i).select = true
		else
			self.eventDatas:atproxy(i).select = false
		end
	end

	self.selectNum = v
end

function HuntingSelectEventView:onEventSure()
	local broadID

	broadID = self.data[self.selectNum].id == -1 and 2 or self.data[self.selectNum].id

	gGameApp:requestServer("/game/hunting/board/choose", function(tb)
		self:onClose()
	end, self.routeType, self.node, broadID)
end

return HuntingSelectEventView
