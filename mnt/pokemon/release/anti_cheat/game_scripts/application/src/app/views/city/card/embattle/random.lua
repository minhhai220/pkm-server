-- chunkname: @src.app.views.city.card.embattle.random

local randomTowerTools = require("app.views.city.adventure.random_tower.tools")
local CardEmbattleView = require("app.views.city.card.embattle.base")
local CardEmbattleRandomView = class("CardEmbattleRandomView", CardEmbattleView)

CardEmbattleRandomView.RESOURCE_FILENAME = "card_embattle.json"
CardEmbattleRandomView.RESOURCE_BINDING = clone(rawget(CardEmbattleView, "RESOURCE_BINDING"))

function CardEmbattleRandomView:getFightSumNum()
	local battle = self.clientBattleCards:read()
	local fightSumNum = 0
	local calcFightingPointf = randomTowerTools.calcFightingPointFunc()

	for k, v in pairs(battle) do
		fightSumNum = fightSumNum + calcFightingPointf(v)
	end

	return fightSumNum
end

function CardEmbattleRandomView:getCardStates()
	return gGameModel.random_tower:read("card_states") or {}
end

function CardEmbattleRandomView:initBottomList()
	CardEmbattleView.initBottomList(self, "city.card.embattle.random_card_list")
end

function CardEmbattleRandomView:limtFunc(params)
	local card = gGameModel.cards:find(params.dbid)
	local level = card:read("level")

	if level < 10 then
		return nil
	end

	local tb = CardEmbattleView.limtFunc(self, params)
	local cardStates = self:getCardStates()

	tb.states = cardStates[params.dbid] or {
		1,
		0
	}

	return tb
end

function CardEmbattleRandomView:embattleBtnFunc(hash, v)
	if not CardEmbattleView.embattleBtnFunc(self, hash, v) then
		return false
	end

	local states = self:getCardStates()
	local state = states[v.dbid] or {
		1,
		1
	}

	return state[1] > 0
end

return CardEmbattleRandomView
