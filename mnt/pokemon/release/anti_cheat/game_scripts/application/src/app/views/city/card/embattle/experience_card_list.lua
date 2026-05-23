-- chunkname: @src.app.views.city.card.embattle.experience_card_list

local CardListView = require("app.views.city.card.embattle.embattle_card_list")
local TestPlayEmbattleCardList = class("TestPlayEmbattleCardList", CardListView)

TestPlayEmbattleCardList.RESOURCE_FILENAME = "common_battle_card_list.json"
TestPlayEmbattleCardList.RESOURCE_BINDING = clone(rawget(CardListView, "RESOURCE_BINDING"))
TestPlayEmbattleCardList.RESOURCE_BINDING.btnPanel = "btnPanel"

function TestPlayEmbattleCardList:initItem(list, node, k, v)
	bind.extend(list, node, {
		class = "card_icon",
		props = {
			unitId = v.unit_id,
			advance = v.advance,
			rarity = v.rarity,
			star = v.star,
			grayState = v.battle == 1 and 1 or 0,
			levelProps = {
				data = v.level
			},
			lock = v.lock >= 0,
			onNode = function(panel)
				local size = panel:size()

				panel:xy(-4, -4)

				local lockPanel = panel:get("lock")

				lockPanel:scale(1)
				lockPanel:xy(size.width - 30, size.height - 30)
			end
		}
	})

	local textNote = node:get("textNote")

	textNote:visible(v.battle == 1)
	uiEasy.addTextEffect1(textNote)
	node:onTouch(functools.partial(list.clickCell, v))
end

function TestPlayEmbattleCardList:getKey(data)
	if not data then
		return nil
	end

	return data.csvID
end

function TestPlayEmbattleCardList:initAllCards()
	return
end

function TestPlayEmbattleCardList:onCardItemTouch(list, v, event)
	if v.lock >= 0 then
		gGameUI:showTip(gLanguageCsv.testPlayNoMove)

		return
	end

	if event.name == "began" then
		self.moved = false
		self.touchBeganPos = event

		self.deleteMovingItem()
	elseif event.name == "moved" then
		local deltaX = math.abs(event.x - self.touchBeganPos.x)
		local deltaY = math.abs(event.y - self.touchBeganPos.y)

		if not self.moved and not self.isMovePanelExist() and (deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD) then
			if deltaY > deltaX * 0.7 then
				local data = self.allCardDatas:atproxy(v.csvID)

				self.createMovePanel(data)
			end

			self.moved = true
		end

		self.cardList:setTouchEnabled(not self.isMovePanelExist())
		self.moveMovePanel(event)
	elseif event.name == "ended" or event.name == "cancelled" then
		if self.isMovePanelExist() == false and self.moved == false then
			self.onCardClick(v, true)

			return
		end

		self.moveEndMovePanel(v)
	end
end

return TestPlayEmbattleCardList
