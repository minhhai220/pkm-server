-- chunkname: @src.app.views.city.card.embattle.clone_battle

local CardEmbattleView = require("app.views.city.card.embattle.base")
local CardEmbattleCloneView = class("CardEmbattleCloneView", CardEmbattleView)

CardEmbattleCloneView.RESOURCE_FILENAME = "card_embattle.json"
CardEmbattleCloneView.RESOURCE_BINDING = clone(rawget(CardEmbattleView, "RESOURCE_BINDING"))
CardEmbattleCloneView.RESOURCE_BINDING.btnGHimg = {
	varname = "btnGHimg",
	binds = {
		event = "extend",
		class = "buff_arms",
		props = {
			redHintTag = "cloneBattleArms",
			battleCards = bindHelper.self("clientBattleCards"),
			arms = bindHelper.self("selectArms"),
			sceneType = bindHelper.self("sceneType"),
			getCardAttrsEx = bindHelper.self("getCardAttrsEx", true),
			isRefresh = bindHelper.self("isRefresh")
		}
	}
}

function CardEmbattleCloneView:onCreate(params)
	CardEmbattleView.onCreate(self, params)
	self.fightNote:hide()
	self.cardListView:hide()
	self.rightDown:hide()
	self.bottomMask:show()

	self.originWeatherID = nil

	self.selectWeatherID:set(nil)
	self.selectArms:set(nil)
end

function CardEmbattleCloneView:initRoundUIPanel()
	self.btnChallenge:visible(true)
	self.rightDown:visible(false)
	self.btnJump:visible(false)
end

function CardEmbattleCloneView:initParams(params)
	params = params or {}
	self.sceneType = game.SCENE_TYPE.clone
	self.fightCb = params.fightCb
	self.from = game.EMBATTLE_FROM_TABLE.input
	self.inputCardAttrs = params.inputCardAttrs
	self.inputCards = params.inputCards
	self.checkBattleArr = params.checkBattleArr or function()
		return true
	end
	self.aidNum = 0
	self.aidCards = idlertable.new({})
	self.originAidCards = idlertable.new({})

	self:refreshAidUI(false)
end

function CardEmbattleCloneView:showItemFightPoint(fightPointText, unitCsv, dbid)
	fightPointText:show()

	local fPString = self:getCardAttr(dbid, "fighting_point")

	fightPointText:get("text"):text(fPString)

	local textSize = fightPointText:get("text"):size()
	local bgSize = fightPointText:get("bg"):size()

	fightPointText:get("bg"):size(textSize.width + 80, bgSize.height)

	local headY = unitCsv.everyPos.headPos.y

	fightPointText:y(headY + 100)
end

function CardEmbattleCloneView:getCardAttr(cardId, attrString)
	return self.inputCardAttrs:read()[cardId][attrString]
end

function CardEmbattleCloneView:onCardClick(data, isShowTip)
	return
end

function CardEmbattleCloneView:getCardAttrs(dbid)
	local data = self.inputCardAttrs:read()[dbid]

	if data then
		local unitId = dataEasy.getUnitId(data.card_id, data.skin_id)

		return {
			battle = 1,
			card_id = data.card_id,
			dbid = data.id,
			unit_id = unitId
		}
	end
end

return CardEmbattleCloneView
