-- chunkname: @src.app.views.city.card.embattle.arena

local CardEmbattleView = require("app.views.city.card.embattle.base")
local CardEmbattleArenaView = class("CardEmbattleArenaView", CardEmbattleView)

CardEmbattleArenaView.RESOURCE_FILENAME = "card_embattle.json"
CardEmbattleArenaView.RESOURCE_BINDING = clone(rawget(CardEmbattleView, "RESOURCE_BINDING"))
CardEmbattleArenaView.RESOURCE_BINDING.useDefaultBattle = {
	varname = "useDefaultBattle",
	binds = {
		event = "click",
		method = bindHelper.self("onUseDefaultBattle")
	}
}
CardEmbattleArenaView.RESOURCE_BINDING.btnGHimg = {
	varname = "btnGHimg",
	binds = {
		class = "buff_arms",
		event = "extend",
		props = {
			redHintTag = "arenaArmsTag",
			battleCards = bindHelper.self("clientBattleCards"),
			arms = bindHelper.self("selectArms"),
			sceneType = bindHelper.self("sceneType"),
			getCardAttrsEx = bindHelper.self("getCardAttrsEx", true),
			isRefresh = bindHelper.self("isRefresh")
		}
	}
}

function CardEmbattleArenaView:initRoundUIPanel()
	adapt.centerWithScreen("left", "right", nil, {
		{
			self.fightNote,
			"pos",
			"right"
		},
		{
			self.btnChallenge,
			"pos",
			"right"
		},
		{
			self.btnJump,
			"pos",
			"right"
		},
		{
			self.rightDown,
			"pos",
			"right"
		}
	})

	local showFightBtn = self.fightCb and true or false

	self.rightDown:visible(not showFightBtn)
	self.btnChallenge:visible(showFightBtn)
	self.btnJump:visible(false)
	self.useDefaultBattle:visible(not showFightBtn)
	self:initDeployment()
end

function CardEmbattleArenaView:onUseDefaultBattle()
	local flag = not self.deploymentFlag:read()
	local key = self.fightCb and "arena_cards" or "arena_defence_cards"

	gGameApp:requestServer("/game/deployment/sync", function()
		if flag then
			local battleAid = gGameModel.role:read("battle_aid_cards") or {}
			local aidNum = dataEasy.getAidNum(game.GATE_TYPE.arena)

			battleAid = dataEasy.fixAidCards(table.deepcopy(battleAid, true), aidNum)

			self.originAidCards:set(battleAid)
			self.battleCardsData:notify()
		end

		local battleExtra = gGameModel.role:read("battle_extra") or {}

		self.selectWeatherID:set(battleExtra.weather or 0)
		self.selectArms:modify(function(val)
			return true, table.deepcopy(battleExtra.arms or {}, true)
		end, true)

		self.originWeatherID = self.selectWeatherID:read()
		self.originArms = table.deepcopy(self.selectArms:read(), true)

		self:setDeploymentFlag()
	end, key, flag)
end

function CardEmbattleArenaView:setDeploymentFlag()
	local key = self.fightCb and "arena_cards" or "arena_defence_cards"
	local flag = gGameModel.role:read("deployments_sync")

	self.deploymentFlag:set(flag[key] or false)
end

function CardEmbattleArenaView:initDeployment()
	self.deploymentFlag = idler.new(false)

	idlereasy.when(self.deploymentFlag, function(_, flag)
		self.useDefaultBattle:get("checkBox"):setSelectedState(flag)
	end)
	idlereasy.any({
		self.clientBattleCards,
		self.selectWeatherID,
		self.selectArms,
		self.aidCards
	}, function(_, battle)
		self.deploymentFlag:set(false)
	end, true)
	self:setDeploymentFlag()
end

function CardEmbattleArenaView:oneKeyEmbattleBtn()
	CardEmbattleView.oneKeyEmbattleBtn(self)
	self.deploymentFlag:set(false)
end

return CardEmbattleArenaView
