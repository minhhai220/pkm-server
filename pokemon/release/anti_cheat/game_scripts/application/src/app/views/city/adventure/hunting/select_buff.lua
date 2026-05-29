-- chunkname: @src.app.views.city.adventure.hunting.select_buff

local QUALITY_TYPE = {
	{
		res = "city/adventure/hunting/box_green.png",
		color = cc.c4b(68, 185, 117, 255)
	},
	{
		res = "city/adventure/hunting/box_yellow.png",
		color = cc.c4b(202, 153, 35, 255)
	},
	{
		res = "city/adventure/hunting/box_blue.png",
		color = cc.c4b(65, 142, 177, 255)
	},
	{
		res = "city/adventure/hunting/box_orange.png",
		color = cc.c4b(227, 118, 84, 255)
	},
	{
		res = "city/adventure/hunting/box_pink.png",
		color = cc.c4b(217, 85, 118, 255)
	},
	{
		res = "city/adventure/hunting/box_purple.png",
		color = cc.c4b(165, 82, 193, 255)
	},
	{
		res = "city/adventure/hunting/box_red.png",
		color = cc.c4b(227, 98, 91, 255)
	}
}
local ViewBase = cc.load("mvc").ViewBase
local HuntingSelectBuffView = class("HuntingSelectBuffView", ViewBase)

HuntingSelectBuffView.RESOURCE_FILENAME = "hunting_select_buff.json"
HuntingSelectBuffView.RESOURCE_BINDING = {
	item = "item",
	title = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c4b(192, 91, 69, 255)
				}
			}
		}
	},
	list = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				padding = 10,
				data = bindHelper.self("eventDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("bg", "name", "icon", "select", "desc")

					childs.select:visible(v.isSel)
					childs.name:text(v.name)
					text.addEffect(childs.name, {
						color = QUALITY_TYPE[v.quality].color
					})
					childs.bg:texture(QUALITY_TYPE[v.quality].res)
					childs.icon:texture(v.icon)
					beauty.textScroll({
						isRich = true,
						align = "center",
						list = childs.desc,
						strs = "#C0x5B545B#" .. v.desc,
						fontSize = ui.FONT_SIZE
					})
					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.clickCell, k, v)
						}
					})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick")
			}
		}
	},
	btnSure = {
		varname = "eventSure",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onSure")
			}
		}
	}
}

function HuntingSelectBuffView:onCreate(params)
	self.params = params

	self:initModel()
	self.selectNum:addListener(function(val, oldval)
		if self.eventDatas:atproxy(oldval) then
			self.eventDatas:atproxy(oldval).isSel = false
		end

		if self.eventDatas:atproxy(val) then
			self.eventDatas:atproxy(val).isSel = true
		end
	end)
end

function HuntingSelectBuffView:initModel()
	self.selectNum = idler.new(1)
	self.eventDatas = idlers.newWithMap({})

	local datas = {}
	local data = gGameModel.hunting:read("hunting_route")[self.params.route].board_buffs

	for _, id in ipairs(data) do
		local buffCfg = csv.cross.hunting.buffs[id]

		table.insert(datas, {
			isSel = false,
			id = id,
			name = buffCfg.name,
			type = buffCfg.type,
			icon = buffCfg.icon,
			quality = buffCfg.quality,
			desc = buffCfg.desc
		})
	end

	self.eventDatas:update(datas)
end

function HuntingSelectBuffView:onItemClick(list, k, v)
	self.selectNum:set(k)
end

function HuntingSelectBuffView:onSure()
	gGameApp:requestServer("/game/hunting/battle/choose", function(tb)
		if self.params.cb then
			self:addCallbackOnExit(self.params.cb)
		end

		self:onClose()
	end, self.params.route, self.params.node, self.selectNum:read())
end

return HuntingSelectBuffView
