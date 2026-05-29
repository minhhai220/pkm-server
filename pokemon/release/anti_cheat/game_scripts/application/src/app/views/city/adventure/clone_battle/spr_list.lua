-- chunkname: @src.app.views.city.adventure.clone_battle.spr_list

local CloneBattleSpriteList = class("CloneBattleSpriteList", Dialog)

CloneBattleSpriteList.RESOURCE_FILENAME = "clone_battle_spr_show.json"
CloneBattleSpriteList.RESOURCE_BINDING = {
	item = "item",
	showPanel = "showPanel",
	["item.spr1.text"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.DEFAULT
				}
			}
		}
	},
	["item.spr2.text"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.DEFAULT
				}
			}
		}
	},
	["item.spr3.text"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.DEFAULT
				}
			}
		}
	},
	["showPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("natureDatas"),
				item = bindHelper.self("item"),
				itemAction = {
					isAction = true
				},
				onItem = function(list, node, k, v)
					local natureId = v.natureId
					local children = node:multiget("natureImg", "text", "spr1", "spr2", "spr3")

					children.natureImg:texture(ui.SKILL_ICON[natureId])
					children.text:text(gLanguageCsv[game.NATURE_TABLE[natureId]] .. gLanguageCsv.talentElement)
					text.addEffect(children.text, {
						outline = {
							size = 4,
							color = ui.COLORS.OUTLINE.WHITE
						},
						color = ui.COLORS.ATTR[natureId]
					})
					adapt.setTextAdaptWithSize(children.text, {
						vertical = "center",
						size = cc.size(220, 130)
					})

					for i = 1, 3 do
						local tb = v.spriteTb[i]
						local imgItem = children["spr" .. i]

						imgItem:visible(tb and true or false)

						if tb then
							imgItem:texture(tb.config.iconSimple)
							imgItem:get("text"):text(tb.config.name)

							if not tb.inBox then
								cache.setShader(imgItem, false, "hsl_gray")
							end
						end
					end
				end
			}
		}
	}
}

function CloneBattleSpriteList:onCreate(data, posX, posY)
	self.natureDatas = data

	local dataCount = #data
	local height = self.item:size().height
	local targetH = (height + 20) * dataCount - 20

	self.list:height(targetH):xy(50, 50)
	self.showPanel:height(targetH + 98):xy(posX - self.showPanel:size().width - 70, 1000 - (targetH - height - 20))
	Dialog.onCreate(self, {
		noBlackLayer = true,
		clickClose = true
	})
end

return CloneBattleSpriteList
