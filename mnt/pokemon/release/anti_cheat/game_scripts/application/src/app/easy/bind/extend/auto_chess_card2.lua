-- chunkname: @src.app.easy.bind.extend.auto_chess_card2

local helper = require("easy.bind.helper")
local autoChessCard1 = require("app.easy.bind.extend.auto_chess_card1")
local autoChessCard2 = class("autoChessCard2", autoChessCard1)
local cards = {}

cards.RESOURCE_FILENAME = "auto_chess_common_card2.json"
cards.RESOURCE_BINDING = {
	skillList = "skillList",
	["panelIcon.icon"] = "icon",
	panelIcon = "panelIcon",
	cardFrame = "cardFrame",
	panelEvent = "panelEvent",
	cardBg = "cardBg",
	attrList = "attrList",
	["panelStar.bg"] = "starBg",
	["panelDef.bg"] = "defBg",
	["panelHp.bg"] = "hpBg",
	["panelDmg.bg"] = "dmgBg",
	panelStar = "panelStar",
	panelDef = "panelDef",
	panelHp = "panelHp",
	panelDmg = "panelDmg",
	["panelDmg.txt"] = {
		varname = "dmgText",
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 6,
					color = cc.c3b(35, 33, 33)
				}
			}
		}
	},
	["panelHp.txt"] = {
		varname = "hpText",
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 6,
					color = cc.c3b(35, 33, 33)
				}
			}
		}
	},
	["panelDef.txt"] = {
		varname = "defText",
		binds = {
			event = "effect",
			data = {
				color = cc.c3b(251, 248, 233),
				outline = {
					size = 6,
					color = cc.c3b(35, 33, 33)
				}
			}
		}
	},
	["panelEvent.name"] = {
		varname = "eventName",
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 6,
					color = cc.c3b(35, 33, 33)
				}
			}
		}
	},
	cardName = {
		varname = "cardName",
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c3b(35, 33, 33)
				}
			}
		}
	},
	attrIcon = {
		varname = "attrIcon",
		binds = {
			data = false,
			event = "visible"
		}
	},
	buffPanel = {
		varname = "buffPanel",
		binds = {
			data = false,
			event = "visible"
		}
	},
	["buffPanel.item"] = {
		binds = {
			data = false,
			event = "visible"
		}
	},
	skillKeyWordsItem = {
		varname = "skillKeyWordsItem",
		binds = {
			data = false,
			event = "visible"
		}
	},
	skillKeyWordsList = {
		varname = "skillKeyWordsList",
		binds = {
			data = false,
			event = "visible"
		}
	}
}
autoChessCard2.defaultProps = {
	showKeyWords = false,
	grayState = 0,
	star = 1
}

function autoChessCard2:initExtend()
	if not tolua.isnull(self.node) then
		self.attrListOriginX = nil
		self.attrListOriginWidth = nil
		self.skillKeyWordsListOriginX = nil
	end

	autoChessCard1.initExtend(self, cards)

	return self
end

function autoChessCard2:buildExtend()
	self.attrListOriginX = self.attrListOriginX or self.node.attrList:x()
	self.attrListOriginWidth = self.attrListOriginWidth or self.node.attrList:width()
	self.skillKeyWordsListOriginX = self.skillKeyWordsListOriginX or self.node.skillKeyWordsList:x()

	autoChessCard1.buildExtend(self)

	if self._type == "event" then
		self.node.icon:scale(1.2)
	end

	return self
end

function autoChessCard2:_initGray()
	autoChessCard1._initGray(self)

	for _, obj in pairs({
		self.node.skillList,
		self.node.skillKeyWordsList
	}) do
		for _, child in pairs(obj:getChildren()) do
			child:setCascadeColorEnabled(true)

			for _, child2 in pairs(child:getChildren()) do
				child2:setCascadeColorEnabled(true)
			end
		end
	end
end

function autoChessCard2:_setData()
	if not self.cfg then
		return
	end

	autoChessCard1._setData(self)
	self.node.cardFrame:texture(string.format("lushi/icon_zzqkp1_%s.png", self.RARITY[self.cfg.rarity]))
	adapt.setTextScaleWithWidth(self.node.cardName, self.cfg.name, 400)

	local desc = uiEasy.autoChessDesc(self.cfg.cardEffect, self.cfg.keyWords, {
		env = self:getEnv()
	})

	beauty.textScroll({
		align = "center",
		fontSize = 44,
		isRich = true,
		list = self.node.skillList,
		strs = desc
	})

	local data = {
		self.cfg.nature1,
		self.cfg.nature2
	}

	bind.extend(self.node, self.node.attrList, {
		class = "listview",
		props = {
			data = data,
			item = self.node.attrIcon,
			onItem = function(list, node, k, id)
				node:texture(ui.ATTR_ICON[id])
				node:scale(self.node.attrIcon:width() / node:width())
			end,
			onAfterBuild = function(list)
				list:refreshView()

				local num = itertools.size(data)
				local width = self.node.attrIcon:width() * num + list:getItemsMargin() * (num - 1)

				list:width(width):x(self.attrListOriginX + (self.attrListOriginWidth - width))
			end
		}
	})
	self:setKeyWords()
end

function autoChessCard2:setKeyWords(keyWords)
	if not self.showKeyWords then
		return
	end

	keyWords = keyWords or self.cfg.keyWords

	local data = {}

	for _, key in orderCsvPairs(keyWords) do
		if not gAutoChessKeyWordsCsv[key] then
			printError("csv.auto_chess.key_words key[%s] 不存在", key)
		else
			table.insert(data, gAutoChessKeyWordsCsv[key])
		end
	end

	self.node.skillKeyWordsList:show()
	bind.extend(self.node, self.node.skillKeyWordsList, {
		class = "listview",
		props = {
			data = data,
			item = self.node.skillKeyWordsItem,
			onItem = function(list, node, k, v)
				node:get("title"):text(v.name)
				text.addEffect(node:get("title"), {
					color = cc.c4b(unpack(v.fontColor, 1, 4))
				})

				local descList = node:get("list"):height(0)
				local desc = v.desc
				local _, height = beauty.textScroll({
					fontSize = 36,
					isRich = true,
					list = descList,
					strs = "#C0x5B545B#" .. desc
				})
				local diff = height - self.node.skillKeyWordsItem:get("list"):height()

				descList:height(height):y(descList:y() - diff)
				node:get("bg"):height(node:get("bg"):height() + diff / node:get("bg"):scale())
				setContentSizeOfAnchor(node, cc.size(node:width(), node:height() + diff))
			end,
			onAfterBuild = function(list)
				list:adaptTouchEnabled()
			end
		}
	})
end

function autoChessCard2:setBuffs(buffs)
	if itertools.isempty(buffs) then
		self.node.buffPanel:hide()
		self.node.skillKeyWordsList:x(self.skillKeyWordsListOriginX)

		return
	end

	local buffPanel = self.node.buffPanel

	buffPanel:show()
	self.node.skillKeyWordsList:x(self.skillKeyWordsListOriginX + buffPanel:width())
	bind.extend(self.node, buffPanel:get("list"), {
		class = "listview",
		props = {
			data = buffs,
			item = buffPanel:get("item"),
			onItem = function(list, node, k, v)
				local formatTitle = "#L10##C0x5F9A70#"

				if v.isEquip then
					formatTitle = "#L10##C0x5B545B#"
				end

				beauty.textScroll({
					fontSize = 38,
					isRich = true,
					list = node:get("title"),
					strs = formatTitle .. v.title
				})

				local descList = node:get("list"):height(0)
				local desc = v.desc
				local _, height = beauty.textScroll({
					fontSize = 36,
					isRich = true,
					list = descList,
					strs = "#C0x5B545B#" .. desc
				})
				local diff = height - buffPanel:get("item"):get("list"):height()

				descList:height(height):y(descList:y() - diff)
				node:get("line"):y(node:get("line"):y() - diff)

				if k == #buffs then
					node:get("line"):hide()

					diff = diff - 30
				end

				setContentSizeOfAnchor(node, cc.size(node:width(), node:height() + diff))
			end,
			onAfterBuild = function(list)
				list:adaptTouchEnabled()

				local height = list:refreshView():getInnerItemSize().height + 60

				height = math.min(height, buffPanel:height())

				buffPanel:get("bg"):height(height)
			end
		}
	})
end

function autoChessCard2:setBattleDesc(desc)
	beauty.textScroll({
		align = "center",
		fontSize = 44,
		isRich = true,
		list = self.node.skillList,
		strs = desc
	})
end

return autoChessCard2
