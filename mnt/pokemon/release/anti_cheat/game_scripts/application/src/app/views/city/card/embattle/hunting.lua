-- chunkname: @src.app.views.city.card.embattle.hunting

local CardEmbattleView = require("app.views.city.card.embattle.base")
local CardEmbattleHuntingView = class("CardEmbattleHuntingView", CardEmbattleView)

CardEmbattleHuntingView.RESOURCE_FILENAME = "card_embattle.json"
CardEmbattleHuntingView.RESOURCE_BINDING = clone(rawget(CardEmbattleView, "RESOURCE_BINDING"))

function CardEmbattleHuntingView:getCardStates()
	return gGameModel.hunting:read("hunting_route")[self.route].card_states or {}
end

function CardEmbattleHuntingView:initBottomList()
	CardEmbattleView.initBottomList(self, "city.card.embattle.hunting_card_list")
end

function CardEmbattleHuntingView:limtFunc(params)
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

function CardEmbattleHuntingView:embattleBtnFunc(hash, v)
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

return CardEmbattleHuntingView
