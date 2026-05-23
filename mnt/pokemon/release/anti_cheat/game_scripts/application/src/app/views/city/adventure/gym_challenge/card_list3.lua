-- chunkname: @src.app.views.city.adventure.gym_challenge.card_list3

local EmbattleCardList = require("app.views.city.card.embattle.embattle_card_list")
local EmbattleCardList3 = class("EmbattleCardList3", EmbattleCardList)

EmbattleCardList3.RESOURCE_FILENAME = "common_battle_card_list.json"
EmbattleCardList3.RESOURCE_BINDING = clone(rawget(EmbattleCardList, "RESOURCE_BINDING"))

return EmbattleCardList3
