-- chunkname: @src.app.views.common.card_detail

local CardDetailView = class("CardDetailView", cc.load("mvc").ViewBase)

CardDetailView.RESOURCE_FILENAME = "common_card_detail.json"
CardDetailView.RESOURCE_BINDING = {
	["baseCardNode.raceNote"] = "raceNote",
	["baseCardNode.skillDescribeList"] = "skillDescribeList",
	["baseCardNode.raceNum"] = "raceNum",
	["baseCardNode.skillAttr"] = "skillAttr",
	["baseCardNode.attrItem"] = "attrItem",
	["baseCardNode.skillName"] = "skillName",
	["baseCardNode.skillIcon"] = "skillIcon",
	["baseCardNode.attr2"] = "attr2",
	["baseCardNode.attr1"] = "attr1",
	baseCardNode = "baseCardNode",
	["baseCardNode.cardName"] = "cardName",
	["baseCardNode.cardIcon"] = {
		binds = {
			class = "card_icon",
			event = "extend",
			props = {
				cardId = bindHelper.self("cardId"),
				star = bindHelper.self("star"),
				rarity = bindHelper.self("rarity"),
				onNode = function(node)
					local size = node:size()

					node:alignCenter(size)
				end
			}
		}
	},
	["baseCardNode.list"] = {
		varname = "attrList",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				asyncPreload = 6,
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("attrItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "note", "num", "bar")

					childs.note:text(v.note)
					childs.num:text(v.num)
					childs.icon:texture(v.icon)

					local width = childs.bar:box().x - childs.note:box().x

					adapt.setTextScaleWithWidth(childs.note, nil, width)

					local percent = v.num * 100 / game.RACE_ATTR_LIMIT

					childs.bar:setPercent(percent)
				end
			}
		}
	}
}

function CardDetailView:onCreate(params)
	local cardId = params.num

	self:getResourceNode():setTouchEnabled(false)

	self.attrDatas = idlertable.new({})

	local cardId, star = dataEasy.getCardIdAndStar(cardId)
	local cardCsv = csv.cards[cardId]
	local unitCsv = csv.unit[cardCsv.unitID]
	local skillCsv = csv.skill[cardCsv.innateSkillID]

	self.cardId = idler.new(cardId)
	self.star = idler.new(star)
	self.rarity = idler.new(unitCsv.rarity)

	beauty.textScroll({
		isRich = true,
		fontSize = 40,
		list = self.skillDescribeList,
		strs = "#C0x5B545B#" .. skillCsv.simDesc
	})
	self.cardName:text(cardCsv.name)
	self.attr1:texture(ui.ATTR_ICON[unitCsv.natureType])

	if unitCsv.natureType2 then
		self.attr2:texture(ui.ATTR_ICON[unitCsv.natureType2]):show()
	else
		self.attr2:hide()
	end

	self.skillName:text(skillCsv.skillName)

	local skillNameWidth = self.skillName:size().width

	if not skillCsv.skillNatureType then
		self.skillAttr:hide()
		self.skillIcon:hide()
	else
		self.skillAttr:texture(ui.SKILL_TEXT_ICON[skillCsv.skillNatureType]):show()
		self.skillIcon:texture(ui.SKILL_ICON[skillCsv.skillNatureType]):show()
	end

	self.raceNum:text(cardCsv.specValue[csvSize(cardCsv.specValue)])

	local attrDatas = {}
	local attrName = {
		{
			"hp",
			"sm"
		},
		{
			"speed",
			"sd"
		},
		{
			"damage",
			"wg"
		},
		{
			"defence",
			"wf"
		},
		{
			"specialDamage",
			"tg"
		},
		{
			"specialDefence",
			"tf"
		}
	}

	for i, v in ipairs(attrName) do
		local data = {
			note = getLanguageAttr(v[1]),
			num = cardCsv.specValue[i],
			icon = ui.ATTR_LOGO[v[1]],
			barImg = "card_info/bar_" .. v[2] .. ".png"
		}

		attrDatas[i] = data
	end

	self.attrDatas:set(attrDatas)
end

function CardDetailView:hitTestPanel(pos)
	if self.skillDescribeList:isTouchEnabled() then
		local node = self.baseCardNode
		local rect = node:box()
		local nodePos = node:parent():convertToWorldSpace(cc.p(rect.x, rect.y))

		rect.x = nodePos.x
		rect.y = nodePos.y

		return cc.rectContainsPoint(rect, pos)
	end

	return false
end

return CardDetailView
