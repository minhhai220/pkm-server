-- chunkname: @src.app.views.city.adventure.dispatch_task.one_key_detail

local dispatchtaskTools = require("app.views.city.adventure.dispatch_task.tools")
local QUALITY_IMG = {
	"city/adventure/dispatchtask/icon_rarity1.png",
	"city/adventure/dispatchtask/icon_rarity2.png",
	"city/adventure/dispatchtask/icon_rarity3.png",
	"city/adventure/dispatchtask/icon_rarity4.png",
	"city/adventure/dispatchtask/icon_rarity5.png"
}
local QUALITY_COLOR = {
	cc.c4b(92, 153, 112, 255),
	cc.c4b(61, 138, 153, 255),
	cc.c4b(138, 92, 153, 255),
	cc.c4b(230, 153, 0, 255),
	cc.c4b(241, 59, 84, 255)
}
local DispatchTaskOneKeyDetailView = class("DispatchTaskOneKeyDetailView", Dialog)

DispatchTaskOneKeyDetailView.RESOURCE_FILENAME = "dispatch_task_reward_detail.json"
DispatchTaskOneKeyDetailView.RESOURCE_BINDING = {
	list = "list",
	item = "item",
	sureBtn = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onSureBtnClick")
			}
		}
	},
	["sureBtn.text"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.OUTLINE.WHITE
				}
			}
		}
	},
	btnClose = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	}
}

function DispatchTaskOneKeyDetailView:onCreate(data)
	Dialog.onCreate(self)

	self.taskDatas = {}

	local taskDatas = {}

	for k, v in ipairs(data) do
		local cfg = csv.dispatch_task.tasks[v.csvID]
		local subTime = v.ending_time or 0
		local award = {}

		for k1, v1 in pairs(v.result or {}) do
			table.insert(award, {
				extra = false,
				key = k1,
				num = v1
			})
		end

		for k1, v1 in pairs(v.extra or {}) do
			table.insert(award, {
				extra = true,
				key = k1,
				num = v1
			})
		end

		table.insert(taskDatas, {
			name = cfg.name,
			award = award,
			quality = cfg.quality
		})
	end

	table.sort(taskDatas, function(a, b)
		return a.quality > b.quality
	end)

	self.taskDatas = taskDatas

	self.list:setScrollBarEnabled(false)
	self:sweepAction()
end

function DispatchTaskOneKeyDetailView:sweepAction()
	local curIdx = 1
	local subTime = 0
	local time = 0.3

	self:enableSchedule():schedule(function(dt)
		subTime = subTime + dt

		if subTime < time then
			return
		end

		subTime = 0

		local v = self.taskDatas[curIdx]

		if curIdx <= #self.taskDatas then
			local item = self.item:clone():show()
			local childs = item:multiget("list", "name", "icon")

			childs.icon:texture(QUALITY_IMG[v.quality])
			childs.name:color(QUALITY_COLOR[v.quality]):text(v.name)
			adapt.oneLinePos(childs.name, childs.icon, cc.p(10, 0))
			uiEasy.createItemsToList(self, childs.list, v.award, {
				onAfterBuild = function()
					childs.list:setItemAlignCenter()
				end,
				sortFunc = function(a, b)
					if a.extra ~= b.extra then
						return not a.extra
					end

					return dataEasy.sortItemCmp(a, b)
				end
			})
			self.list:pushBackCustomItem(item)
		else
			local item = self.item:clone():show()
			local childs = item:multiget("list", "name", "icon")

			itertools.invoke({
				item:get("list"),
				item:get("name"),
				item:get("icon")
			}, "hide")

			local effect = widget.addAnimationByKey(item, "level/saodangchenggong.skel", "paiqianwancheng", "paiqianwancheng", 100)

			effect:alignCenter(item:size())
			effect:addPlay("paiqianwancheng_loop")
			self.list:pushBackCustomItem(item)
		end

		performWithDelay(self, function()
			self.list:scrollToBottom(0.15, true)
		end, 0.016666666666666666)

		if curIdx == #self.taskDatas + 1 then
			self:unSchedule("detailView")
		end

		curIdx = curIdx + 1
	end, 0.016666666666666666, 0, "detailView")
end

function DispatchTaskOneKeyDetailView:onSureBtnClick()
	self:onClose()
end

return DispatchTaskOneKeyDetailView
