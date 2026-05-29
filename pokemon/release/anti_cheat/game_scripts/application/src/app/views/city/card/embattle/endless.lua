-- chunkname: @src.app.views.city.card.embattle.endless

local CardEmbattleView = require("app.views.city.card.embattle.base")
local CardEmbattleEndLessView = class("CardEmbattleEndLessView", CardEmbattleView)

CardEmbattleEndLessView.RESOURCE_FILENAME = "card_embattle.json"
CardEmbattleEndLessView.RESOURCE_BINDING = clone(rawget(CardEmbattleView, "RESOURCE_BINDING"))

function CardEmbattleEndLessView:initParams(params)
	CardEmbattleView.initParams(self, params)

	self.limitInfo = params.limitInfo or {}
end

function CardEmbattleEndLessView:limtFunc(params)
	local limitType, limitArg = csvNext(self.limitInfo)
	local hashMap = itertools.map(limitArg or {}, function(k, v)
		return v, 1
	end)
	local card = gGameModel.cards:find(params.dbid)
	local cardID = card:read("card_id")
	local cardCsv = csv.cards[cardID]
	local unitCsv = csv.unit[cardCsv.unitID]

	if not limitType or limitType > 2 and limitType < 7 or limitType == 1 and (hashMap[unitCsv.natureType] or hashMap[unitCsv.natureType2]) or limitType == 2 and not hashMap[unitCsv.natureType] and not hashMap[unitCsv.natureType2] then
		return CardEmbattleView.limtFunc(self, params)
	else
		return nil
	end
end

return CardEmbattleEndLessView
