-- chunkname: @src.app.views.city.card.embattle.hunting_card_list

local EmbattleCardList = require("app.views.city.card.embattle.embattle_card_list")
local HuntingEmbattleCardList = class("EmbattleCardList", EmbattleCardList)

HuntingEmbattleCardList.RESOURCE_FILENAME = "common_battle_card_list.json"
HuntingEmbattleCardList.RESOURCE_BINDING = clone(rawget(EmbattleCardList, "RESOURCE_BINDING"))

function HuntingEmbattleCardList:initItem(list, node, k, v)
	EmbattleCardList.initItem(self, list, node, k, v)

	local hpBar = node:get("hpBar"):show()
	local mpBar = node:get("mpBar"):show()

	hpBar:get("bar"):setPercent(v.states[1] * 100)
	mpBar:get("bar"):setPercent(v.states[2] * 100)

	if v.states[1] > 0 then
		node:onTouch(functools.partial(list.clickCell, v))
	else
		node:onTouch(function()
			return
		end)
		node:get("deadMask"):show()
	end
end

function HuntingEmbattleCardList:onSortCards(list)
	local func = EmbattleCardList.onSortCards(self, list)

	return function(a, b)
		local statesA = a.states
		local statesB = b.states

		if statesA[1] <= 0 then
			return false
		end

		if statesB[1] <= 0 then
			return true
		end

		return func(a, b)
	end
end

return HuntingEmbattleCardList
