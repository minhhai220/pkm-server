-- chunkname: @src.app.easy.bind.extend.buff_arms

local helper = require("easy.bind.helper")

local function getValue(idler)
	if isIdler(idler) then
		return idler:get_()
	end

	return idler
end

local buffArms = class("buffArms", cc.load("mvc").ViewBase)

buffArms.defaultProps = {}

function buffArms:initExtend()
	if self.panel then
		self.panel:removeFromParent()
	end

	local panelSize = cc.size(150, 150)
	local panel = ccui.Layout:create():anchorPoint(cc.p(0.5, 0.5)):size(panelSize):xy(self:width() / 2, self:height() / 2):addTo(self, 1, "_buffArms_")

	self.panel = panel

	local buffImg = ccui.ImageView:create("config/embattle/icon_gh.png"):addTo(panel, 10, "buffImg"):alignCenter(panelSize):scale(2)

	self.buffImg = buffImg

	self:checkTeamBuffOpen()
	helper.callOrWhen(self.battleCards, function(battleCards)
		self:setBuff()
	end, self, "battleCards")
	helper.callOrWhen(self.arms, function(arms)
		self:setArms()
	end, self, "arms")
	helper.callOrWhen(self.idx, function()
		self:setBuff()
		self:setArms()
	end, self, "idx")

	if self.onNode then
		self.onNode(panel)
	end

	if self.panel:visible() and not self.noListener then
		self.panel:setTouchEnabled(true)
		bind.touch(self, self.panel, {
			methods = {
				ended = function()
					self:onTeamBuffClick()
				end
			}
		})
	else
		self.panel:setTouchEnabled(false)
	end

	return self
end

function buffArms:setBuff()
	if not self.buffOpen then
		return
	end

	local battleCards = getValue(self.battleCards)
	local idx

	if self.getBattleCardsEx then
		local battleIdx = getValue(self.battleIdx)

		battleCards = self.getBattleCardsEx(battleIdx)
	else
		idx = getValue(self.idx)
	end

	local attrs = {}
	local baseIdx = idx and (idx - 1) * 6 or 0

	for i = 1, 6 do
		local dbid = battleCards[baseIdx + i]
		local data = self:getCardAttrsEx_(dbid)

		if data then
			local cardCfg = csv.cards[data.card_id]
			local unitCfg = csv.unit[cardCfg.unitID]

			attrs[i] = {
				unitCfg.natureType,
				unitCfg.natureType2
			}
		end
	end

	local result = dataEasy.getTeamBuffBest(attrs)

	self.buffImg:texture(result.buf.imgPath)

	self.teamBuffs = result

	if self.isRefresh then
		performWithDelay(self, function()
			self.isRefresh:notify()
		end, 0.016666666666666666)
	end

	if self.redHintTag then
		self:setRedHint()
	end
end

function buffArms:setArms()
	if not dataEasy.isUnlock(gUnlockCsv.arms) and not self.enemyData then
		return
	end

	local arms = getValue(self.arms)

	if arms == nil then
		return
	end

	local idx = getValue(self.idx)

	if idx then
		arms = arms[idx]

		if arms == nil then
			return
		end
	end

	self.buffImg:scale(1.35)

	local panel = self.panel

	panel:show()

	if not panel:get("armsBg") then
		ccui.ImageView:create("city/arms/di.png"):addTo(panel, 11, "armsBg"):alignCenter(panel:size())
	end

	if not panel:get("arms1") then
		ccui.ImageView:create("city/arms/none.png"):addTo(panel, 12, "arms1"):xy(33, 117)
	end

	if not panel:get("arms2") then
		ccui.ImageView:create("city/arms/none.png"):addTo(panel, 12, "arms2"):xy(117, 33)
	end

	local arms1 = arms[1] and arms[1][1] or 0
	local arms2 = arms[2] and arms[2][1] or 0

	arms1 = self:isHasArm(arms1) and arms1 or 0
	arms2 = self:isHasArm(arms2) and arms2 or 0

	if arms1 == 0 then
		arms1, arms2 = arms2, arms1
	end

	if arms1 ~= 0 then
		panel:get("arms1"):texture(string.format("city/arms/icon_%s.png", game.NATURE_TABLE[arms1]))
	else
		panel:get("arms1"):texture("city/arms/none.png")
	end

	if arms2 ~= 0 then
		panel:get("arms2"):texture(string.format("city/arms/icon_%s.png", game.NATURE_TABLE[arms2]))
	else
		panel:get("arms2"):texture("city/arms/none.png")
	end
end

function buffArms:isHasArm(armdID)
	if self.noListener then
		return true
	end

	local allArms = gGameModel.role:read("arms_stage") or {}
	local stage = allArms[armdID]

	if stage then
		for i = 1, stage do
			local cfg = gArmStage[armdID][i]

			if cfg.skillID ~= 0 then
				return true
			end
		end
	end

	return false
end

function buffArms:getCardAttrsEx_(dbid)
	if self.getCardAttrsEx then
		return self.getCardAttrsEx(dbid)
	end

	local card = gGameModel.cards:find(dbid)

	if card then
		local cardDatas = card:read("card_id", "skin_id", "fighting_point", "level", "star", "advance")

		cardDatas.dbid = dbid

		return cardDatas
	end

	return nil
end

function buffArms:checkTeamBuffOpen()
	self.buffOpen = true

	for _, cfg in csvPairs(csv.battle_card_halo) do
		if itertools.include(cfg.invalidScenes, self.sceneType) then
			self.buffOpen = false

			break
		end
	end

	self.panel:visible(self.buffOpen)
end

function buffArms:onTeamBuffClick()
	local teamBuffs = self.teamBuffs and self.teamBuffs.buf.teamBuffs or {}
	local teamArms = self.arms

	if self.noTeamBuff then
		teamBuffs = nil
	end

	if self.noTeamArm then
		teamArms = nil
	end

	if self.redHintTag and self:isArmCanUp() then
		local armRedHintTag = gGameModel.forever_dispatch:getIdlerOrigin("armRedHintTag")

		armRedHintTag:modify(function(data)
			data[self.redHintTag] = true

			return true, data
		end, true)
	end

	gGameUI:stackUI("city.card.embattle.attr_dialog", nil, {}, {
		teamBuffs = teamBuffs,
		teamArms = teamArms,
		idx = getValue(self.idx)
	})
end

function buffArms:setRedHint()
	if not self:isArmCanUp() then
		return
	end

	local arms = getValue(self.arms)

	if arms == nil then
		return
	end

	local arms1 = arms[1] and arms[1][1] or 0
	local arms2 = arms[2] and arms[2][1] or 0

	if arms1 ~= 0 or arms2 ~= 0 then
		return
	end

	bind.extend(self, self.panel, {
		class = "red_hint",
		props = {
			specialTag = "armTag",
			listenData = {
				armTagName = self.redHintTag
			}
		}
	})
end

function buffArms:isArmCanUp()
	local allArms = gGameModel.role:read("arms_stage") or {}

	if itertools.size(allArms) == 0 then
		return false
	end

	for armsID, stage in pairs(allArms) do
		for _, val in orderCsvPairs(csv.arms.stage) do
			if val.armID == armsID and stage >= val.stage and val.skillID ~= 0 then
				return true
			end
		end
	end

	return false
end

return buffArms
