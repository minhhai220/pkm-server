-- chunkname: @src.app.views.city.card.skill

local function getCostGold(skillLevel, costID, fastUpgradeNum)
	local costGold = 0

	for i = 1, fastUpgradeNum do
		if csv.base_attribute.skill_level[skillLevel + i - 1] then
			costGold = costGold + csv.base_attribute.skill_level[skillLevel + i - 1]["gold" .. costID]
		end
	end

	return costGold
end

local LINE_NUM = 50
local LINE_HIGHT = 50
local CardSkillView = class("CardSkillView", cc.load("mvc").ViewBase)

CardSkillView.RESOURCE_FILENAME = "card_skill.json"
CardSkillView.RESOURCE_BINDING = {
	topItem = "topItem",
	["panel.textNote"] = "textNote",
	["panel.textNum"] = "skillNum",
	-- ["townPanel.townMask"] = "townMask",
	panel = "skillPanel",
	-- ["townPanel.skillItem"] = "skillItem",
	-- townPanel = "townPanel",
	-- ["townPanel.conditionItem"] = "conditionItem",
	item = "item",
	["panel.fastUpgradePanel.btnPanel"] = "btnFastUpgrade",
	topList = {
		varname = "topList",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("topItem"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel

					if v.select then
						normal:hide()

						panel = selected:show()
					else
						selected:hide()

						panel = normal:show()
					end

					panel:get("txt"):text(v.name)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {
						methods = {
							ended = functools.partial(list.clickCell, k)
						}
					})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick")
			}
		}
	},
	-- ["townPanel.skillList"] = {
	-- 	varname = "skillList",
	-- 	binds = {
	-- 		class = "listview",
	-- 		event = "extend",
	-- 		props = {
	-- 			data = bindHelper.self("townSkillDatas"),
	-- 			item = bindHelper.self("skillItem"),
	-- 			onItem = function(list, node, k, v)
	-- 				if v.hasSkill then
	-- 					local childs = node:get("panel"):multiget("effectState", "effectName", "skillType", "desc", "icon")
	-- 					local cfg = v.cfg

	-- 					childs.effectState:text(v.state)
	-- 					childs.effectName:text(cfg.name .. gLanguageCsv["symbolRome" .. cfg.level])
	-- 					childs.skillType:text(cfg.name)
	-- 					childs.desc:text(cfg.desc)

	-- 					local t1 = math.ceil(#cfg.desc / LINE_NUM)

	-- 					childs.desc:height(LINE_HIGHT * t1)
	-- 					node:height(childs.desc:height() + 300)
	-- 					node:get("panel"):y(childs.desc:height() + 300)
	-- 					childs.icon:texture(cfg.icon)
	-- 					node:get("noData"):hide()
	-- 					node:get("panel"):show()
	-- 				else
	-- 					node:get("noData"):show()
	-- 					node:get("panel"):hide()
	-- 				end
	-- 			end
	-- 		}
	-- 	}
	-- },
	-- ["townPanel.conditionList"] = {
	-- 	varname = "conditionList",
	-- 	binds = {
	-- 		class = "listview",
	-- 		event = "extend",
	-- 		props = {
	-- 			data = bindHelper.self("townSkillConditionDatas"),
	-- 			item = bindHelper.self("conditionItem"),
	-- 			onItem = function(list, node, k, v)
	-- 				local childs = node:multiget("text", "tip")

	-- 				childs.tip:visible(not v.finish)
	-- 				childs.text:text(v.text)
	-- 				adapt.oneLinePos(childs.text, childs.tip, cc.p(5, 0), "left")
	-- 			end
	-- 		}
	-- 	}
	-- },
	["panel.btnAdd"] = {
		varname = "addBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onSkillAddClick")
			}
		}
	},
	["panel.textFlag"] = {
		varname = "skillMax",
		binds = {
			event = "text",
			idler = bindHelper.self("skillPointState")
		}
	},
	["panel.fastUpgradePanel"] = {
		varname = "fastUpgradePanel",
		binds = {
			event = "click",
			method = bindHelper.self("onFastUpgradeClick")
		}
	},
	["panel.list"] = {
		varname = "list",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				asyncPreload = 5,
				data = bindHelper.self("skillData"),
				item = bindHelper.self("item"),
				cardLv = bindHelper.self("cardLv"),
				star = bindHelper.self("star"),
				cardId = bindHelper.self("cardId"),
				advance = bindHelper.self("advance"),
				zawakeSkills = bindHelper.self("zawakeSkills"),
				canFastUpgrade = bindHelper.self("canFastUpgrade"),
				itemAction = {
					isAction = true
				},
				margin = bindHelper.self("listMargin"),
				dataOrderCmp = function(a, b)
					return a.id < b.id
				end,
				onItem = function(list, node, k, v)
					node:name("item" .. list:getIdx(k))

					local skillInfo = csv.skill[v.skillId]
					local cardLv = list.cardLv:read()
					local childs = node:multiget("textLvNum", "textCost", "textName", "imgType", "btnAdd", "imgIcon", "imgBG", "textFastUpgradeNum", "textLvNote")

					childs.textLvNote:text(gLanguageCsv.textLv1)
					childs.textLvNum:text(v.skillLevel)

					if matchLanguage({
						"cn"
					}) then
						childs.textLvNum:setPositionX(childs.textLvNum:getPositionX() - 50)
						childs.textLvNote:setPositionY(childs.textLvNum:getPositionY())
						adapt.oneLinePos(childs.textLvNum, childs.textLvNote)
					end

					local skillGold = getCostGold(v.skillLevel, skillInfo.costID, v.fastUpgradeNum)
					local goldColor = skillGold <= v.clientGold and cc.c4b(91, 84, 91, 255) or cc.c4b(249, 87, 114, 255)

					text.addEffect(childs.textCost, {
						color = goldColor
					})
					childs.textCost:text(skillGold)
					uiEasy.setSkillInfoToItems({
						name = childs.textName,
						icon = childs.imgIcon,
						type1 = childs.imgType
					}, v.skillId)
					adapt.setTextAdaptWithSize(childs.textName, {
						horizontal = "left",
						vertical = "center",
						size = cc.size(340, 150)
					})
					cache.setShader(childs.btnAdd, false, cardLv >= v.skillLevel + v.fastUpgradeNum and "normal" or "hsl_gray")
					childs.btnAdd:onTouch(functools.partial(list.clickCell, node, k, v))
					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.clickCellTip, k, v)
						}
					})

					local state = true
					local name = ""
					local title = "s%"

					if skillInfo.activeType == 1 then
						state = list.star:read() >= skillInfo.activeCondition
						title = gLanguageCsv.potentialIncreasedStarsUnlocked
						name = skillInfo.activeCondition
					elseif skillInfo.activeType == 2 then
						state = list.advance:read() >= skillInfo.activeCondition
						title = gLanguageCsv.skillBreakAdvanceUnlocked
						name = uiEasy.setIconName("card", list.cardId:read(), {
							space = true,
							node = node:get("textTip"),
							name = ui.QUALITY_COLOR_TEXT,
							advance = skillInfo.activeCondition
						})
						name = ui.QUALITYCOLOR[dataEasy.getQuality(skillInfo.activeCondition)] .. gLanguageCsv.symbolSquareBracketLeft .. name .. gLanguageCsv.symbolSquareBracketRight
					end

					childs.textFastUpgradeNum:text(string.format(gLanguageCsv.upLevelNumber, v.fastUpgradeNum)):visible(list.canFastUpgrade:read() and state)
					node:removeChildByName("activeCondition")

					local richText = rich.createWithWidth(string.format(title, name), 40, nil, 800)

					richText:anchorPoint(0, 1):xy(205, 95):visible(not state):addTo(node, 2, "activeCondition")
					node:get("imgMask"):visible(not state)
					node:get("imgCostIcon"):visible(state)
					node:get("textCost"):visible(state)
					node:get("btnAdd"):visible(state)
					childs.imgBG:z(0)
					node:removeChildByName("zawakeBg")
					childs.imgIcon:removeChildByName("zawakeUp")

					if dataEasy.isZawakeSkill(v.skillId, list.zawakeSkills:read()) then
						ccui.ImageView:create("city/zawake/panel_z1.png"):alignCenter(node:size()):addTo(node, 1, "zawakeBg")
						ccui.ImageView:create("city/drawcard/draw/txt_up.png"):scale(1.2):align(cc.p(1, 1), 200, 190):addTo(childs.imgIcon, 1, "zawakeUp")

						local zawakeEffectID = csv.skill[v.skillId].zawakeEffect[1]

						childs.textName:text(csv.skill[zawakeEffectID].skillName .. childs.textName:text())
					end
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemAddClick"),
				clickCellTip = bindHelper.self("onItemTipClick")
			}
		}
	}
}

function CardSkillView:onCreate(dbHandler)
	self.selectDbId = dbHandler()

	self:initModel()
	self:enableSchedule()

	self.skillData = idlers.new()
	self.listMargin = idler.new(11)
	self.skillPointState = idler.new("")
	self.skillList = {}
	self.tmpSkillPoint = idler.new(0)
	self.refreshPoint = idler.new(true)
	self.serverSkillPoint = idler.new(0)

	local state = userDefault.getForeverLocalKey("skillFastUpgrade", false)

	self.btnFastUpgrade:get("checkBox"):setSelectedState(state)

	self.canFastUpgrade = idler.new(false)

	dataEasy.getListenUnlock(gUnlockCsv.fastUpgrade, function(isUnlock)
		self.canFastUpgrade:set(state and isUnlock)
		self.fastUpgradePanel:visible(isUnlock)
	end)
	-- self.townPanel:visible(false)
	-- self.townMask:visible(false)
	-- dataEasy.getListenUnlock(gUnlockCsv.town, function(isUnlock)
	-- 	self.topList:visible(isUnlock)

	-- 	local size = self.topList:size()

	-- 	if not isUnlock then
	-- 		self.skillPanel:y(self.skillPanel:y() + size.height)
	-- 		self.list:y(self.list:y() - 120)
	-- 		self.list:height(self.list:height() + 120)
	-- 	else
	-- 		self.listMargin:set(0)
	-- 	end
	-- end)
	idlereasy.any({
		self.cardId,
		self.skinId,
		self.zawakeSkills
	}, function(_, cardId, skinId)
		local skillData = {}
		local list = dataEasy.getSortCardSkillList(cardId, skinId)

		self.skillList = list

		for k, v in ipairs(self.skillList) do
			local passive = 1

			if csv.skill[v].skillType2 == battle.MainSkillType.PassiveSkill then
				passive = 2
			end

			local skillLevel = self.skills:read()[v] or 1

			skillData[v] = {
				id = k,
				skillId = v,
				skillLevel = skillLevel,
				skillPassive = passive,
				clientGold = self.gold:read(),
				fastUpgradeNum = self:getFastUpgradeNum(skillLevel)
			}
		end

		self:unSchedule("skillLvUp")
		self.skillData:update(skillData)
		self.tmpSkillPoint:set(0)
		self:updateTownPanel()
	end)
	idlereasy.any({
		self.skills,
		self.cardLv
	}, function(_, skills)
		for i, v in csvPairs(self.skillList) do
			self.skillData:at(v):modify(function(data)
				data.skillLevel = skills[v] or 1
				data.fastUpgradeNum = self:getFastUpgradeNum(data.skillLevel)
			end, true)
		end
	end)

	self.clientGold = idler.new(0)

	idlereasy.when(self.gold, function(_, gold)
		self.clientGold:set(gold)
	end)
	idlereasy.when(self.clientGold, function(_, clientGold)
		for i, v in csvPairs(self.skillList) do
			self.skillData:at(v):modify(function(data)
				data.clientGold = clientGold
			end, true)
		end
	end)

	local csvRecoverTime = 0

	idlereasy.when(self.vipLevel, function(_, vipLevel)
		csvRecoverTime = gVipCsv[vipLevel].skillPointRecoverTime
	end)

	local skillPointMax = 0

	idlereasy.when(self.roleLv, function(_, roleLv)
		skillPointMax = dataEasy.getSkillPointMax(roleLv)
	end)

	local valTime

	idlereasy.any({
		self.skillPointLast,
		self.skillPoint,
		self.tmpSkillPoint,
		self.refreshPoint
	}, function(_, skillPointLast, skillPoint, tmpSkillPoint)
		valTime = math.max(time.getTime() - math.ceil(skillPointLast), 0)

		for i = 0, skillPointMax do
			if skillPoint >= skillPointMax then
				valTime = csvRecoverTime

				break
			end

			if valTime >= csvRecoverTime then
				valTime = valTime - csvRecoverTime
				skillPoint = skillPoint + 1
			else
				valTime = csvRecoverTime - valTime

				self.skillPointState:set("(" .. time.getCutDown(valTime).min_sec_clock .. ")")

				break
			end
		end

		self.serverSkillPoint:set(skillPoint - tmpSkillPoint)
	end)

	self.timeStart = idler.new(true)

	idlereasy.when(self.timeStart, function(_, timeStart)
		if timeStart then
			self:schedule(function()
				self.refreshPoint:set(not self.refreshPoint:read())
			end, 1, 0, "CardSkillView")
		else
			self:unSchedule("CardSkillView")
			self.skillPointState:set("(MAX)")
		end
	end)
	idlereasy.any({
		self.serverSkillPoint,
		self.canFastUpgrade
	}, function(_, serverSkillPoint)
		local notSkillPointMax = serverSkillPoint < skillPointMax

		self.timeStart:set(notSkillPointMax)
		self.addBtn:visible(false)
		self.skillNum:text(serverSkillPoint)

		if serverSkillPoint >= gCommonConfigCsv.skillPointLimitMax then
			self.skillPointState:set("(" .. gLanguageCsv.alreadyMax .. ")")
		elseif serverSkillPoint >= skillPointMax then
			self.skillPointState:set("(MAX)")
		end

		adapt.oneLinePos(self.textNote, {
			self.skillNum,
			self.skillMax
		}, cc.p(20, 0), "left")

		for i, v in csvPairs(self.skillList) do
			self.skillData:at(v):modify(function(data)
				data.fastUpgradeNum = self:getFastUpgradeNum(data.skillLevel)
			end, true)
		end
	end)
end

function CardSkillView:initModel()
	self.items = gGameModel.role:getIdler("items")
	self.skillPointLast = gGameModel.role:getIdler("skill_point_last_recover_time")
	self.skillPoint = gGameModel.role:getIdler("skill_point")
	self.roleLv = gGameModel.role:getIdler("level")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.gold = gGameModel.role:getIdler("gold")

	idlereasy.when(self.selectDbId, function(_, selectDbId)
		local card = gGameModel.cards:find(selectDbId)

		self.cardId = idlereasy.assign(card:getIdler("card_id"), self.cardId)
		self.skinId = idlereasy.assign(card:getIdler("skin_id"), self.skinId)
		self.cardLv = idlereasy.assign(card:getIdler("level"), self.cardLv)
		self.skills = idlereasy.assign(card:getIdler("skills"), self.skills)
		self.star = idlereasy.assign(card:getIdler("star"), self.star)
		self.advance = idlereasy.assign(card:getIdler("advance"), self.advance)
		self.zawakeSkills = idlereasy.assign(card:getIdler("zawake_skills"), self.advance)

		dataEasy.tryCallFunc(self.list, "setItemAction", {
			isAction = true
		})
	end)

	self.showTab = idler.new(1)
	self.tabDatas = idlers.newWithMap({
		{
			id = 1,
			redHint = "skillBattle",
			name = gLanguageCsv.zhandou,
			panel = self.skillPanel
		},
		-- {
		-- 	id = 2,
		-- 	redHint = "townSkill",
		-- 	name = gLanguageCsv.town,
		-- 	panel = self.townPanel
		-- }
	})

	self.showTab:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true

		if self.tabDatas:atproxy(oldval).panel then
			self.tabDatas:atproxy(oldval).panel:hide()
		end

		self.tabDatas:atproxy(val).panel:show()
	end)

	self.townSkillDatas = idlers.new()
	self.townSkillConditionDatas = idlers.new({})
end

function CardSkillView:onTabClick(list, index)
	self.showTab:set(index)
end

function CardSkillView:updateTownPanel()
	if not dataEasy.isUnlock(gUnlockCsv.town) then
		return
	end

	local cardId = self.cardId:read()
	local cardCsv = csv.cards[cardId]
	local card = gGameModel.cards:find(self.selectDbId:read())
	local cardData = card:read("star", "advance")
	local skillId = cardCsv.townSkill

	if skillId == 0 then
		-- self.townMask:show()
		-- self.townPanel:get("max"):hide()
		-- self.townPanel:get("condition"):hide()
		-- self.townSkillDatas:update({})
		-- self.townSkillConditionDatas:update({})
	else
		-- self.townMask:hide()

		local skillCfg, csvId
		local t = {}
		local condition = {}

		for k, val in orderCsvPairs(csv.town.skill) do
			if val.skill == skillId and cardData.advance >= val.needAdvance and cardData.star >= val.needStar then
				skillCfg = val
				csvId = k
			end
		end

		local nextLevelCfg

		if csvId then
			table.insert(t, {
				hasSkill = true,
				state = gLanguageCsv.townSkillNowEffect,
				cfg = skillCfg
			})

			if csv.town.skill[csvId + 1] and csv.town.skill[csvId + 1].skill == skillId then
				nextLevelCfg = csv.town.skill[csvId + 1]
			else
				-- self.townPanel:get("condition"):hide()
				-- self.townPanel:get("max"):show()
			end
		else
			table.insert(t, {
				hasSkill = false
			})

			nextLevelCfg = gTownSkillCsv[skillId][1]
		end

		if nextLevelCfg then
			-- self.townPanel:get("max"):hide()
			-- self.townPanel:get("condition"):show()

			local quality, numStr = dataEasy.getQuality(nextLevelCfg.needAdvance)
			local str = ""

			if not itertools.isempty(numStr) then
				str = gLanguageCsv[ui.QUALITY_COLOR_TEXT[quality]] .. "+" .. numStr
			else
				str = gLanguageCsv[ui.QUALITY_COLOR_TEXT[quality]] .. numStr
			end

			-- self.townPanel:get("max"):hide()
			-- self.townPanel:get("condition"):show()
			table.insert(t, {
				hasSkill = true,
				state = gLanguageCsv.townSkillNextEffect,
				cfg = nextLevelCfg
			})
			table.insert(condition, {
				text = gLanguageCsv.townCardSkillConditionStar .. nextLevelCfg.needStar,
				finish = cardData.star >= nextLevelCfg.needStar
			})
			table.insert(condition, {
				text = gLanguageCsv.townCardSkillConditionAdvance .. str,
				finish = cardData.advance >= nextLevelCfg.needAdvance
			})
		end

		self.townSkillDatas:update(t)
		self.townSkillConditionDatas:update(condition)
	end
end

function CardSkillView:onFastUpgradeClick()
	local state = userDefault.getForeverLocalKey("skillFastUpgrade", false)

	self.btnFastUpgrade:get("checkBox"):setSelectedState(not state)
	userDefault.setForeverLocalKey("skillFastUpgrade", not state)
	self.canFastUpgrade:set(not state)
end

function CardSkillView:getFastUpgradeNum(skillLevel)
	local fast = self.canFastUpgrade:read()

	if not fast then
		return 1
	end

	local cardLv = self.cardLv:read()

	if cardLv <= skillLevel then
		return 5
	end

	local nowSkill = self.serverSkillPoint:read()

	if nowSkill == 0 then
		return 1
	end

	return math.min(cardLv - skillLevel, math.min(nowSkill, 5))
end

function CardSkillView:onItemAddClick(list, node, k, v, event)
	if event.name == "began" then
		self.tmpSkillPoint:set(0)

		local time = 0.4
		local speed = 0.6

		self.notMoved = true
		self.touchBeganPos = clone(event)

		self:enableSchedule():schedule(function(dt)
			if time <= 0 and not gGameUI:isConnecting() then
				speed = speed <= 0.2 and 0.2 or speed - 0.2
				time = speed
				v.skillLevel = self.skillData:atproxy(k).skillLevel
				v.fastUpgradeNum = self.skillData:atproxy(k).fastUpgradeNum

				if self:canLevelUp(v, false) then
					local fastUpgradeNum = v.fastUpgradeNum

					self.tmpSkillPoint:modify(function(oldVal)
						return true, oldVal + fastUpgradeNum
					end)

					local skillGold = getCostGold(v.skillLevel, csv.skill[v.skillId].costID, fastUpgradeNum)

					self.clientGold:modify(function(oldVal)
						return true, oldVal - skillGold
					end)

					local skillLevel = self.skillData:atproxy(k).skillLevel + fastUpgradeNum

					self.skillData:atproxy(k).skillLevel = skillLevel
					self.skillData:atproxy(k).fastUpgradeNum = self:getFastUpgradeNum(skillLevel)

					if self.serverSkillPoint:read() + self.tmpSkillPoint:read() >= dataEasy.getSkillPointMax(self.roleLv:read()) and self.serverSkillPoint:read() < dataEasy.getSkillPointMax(self.roleLv:read()) then
						local num = self.tmpSkillPoint:read()

						gGameApp:requestServer("/game/card/skill/level/up", function(tb)
							self.tmpSkillPoint:modify(function(oldVal)
								return true, oldVal - num
							end)
						end, self.selectDbId, v.skillId, num)
					end

					for i = 1, fastUpgradeNum do
						self:upgradeFloatingWord(node, v.skillId)
					end

					local size = node:get("imgIcon"):getContentSize()

					audio.playEffectWithWeekBGM("circle.mp3")
					widget.addAnimationByKey(node:get("imgIcon"), "effect/jineng.skel", nil, "effect", 555):xy(size.width / 2, size.height / 2):scale(1.3)
				end
			end

			time = time - dt
		end, 0.1, 0, "skillLvUp")
	elseif event.name == "moved" then
		local pos = event
		local deltaX = math.abs(pos.x - self.touchBeganPos.x)
		local deltaY = math.abs(pos.y - self.touchBeganPos.y)

		if deltaX >= ui.TOUCH_MOVE_CANCAE_THRESHOLD or deltaY >= ui.TOUCH_MOVE_CANCAE_THRESHOLD then
			self.notMoved = false

			self:unSchedule("skillLvUp")
		end
	elseif event.name == "ended" or event.name == "cancelled" then
		self:unSchedule("skillLvUp")
		self:canLevelUp(v, true)

		if gGameUI:isConnecting() then
			return
		end

		if self.tmpSkillPoint:read() > 0 then
			gGameApp:requestServer("/game/card/skill/level/up", function(tb)
				self.tmpSkillPoint:set(0)
			end, self.selectDbId, v.skillId, self.tmpSkillPoint)
		elseif self.notMoved then
			if not self:canLevelUp(v, false) then
				return
			end

			gGameApp:requestServer("/game/card/skill/level/up", function(tb)
				self.tmpSkillPoint:set(0)
			end, self.selectDbId, v.skillId, v.fastUpgradeNum)

			for i = 1, v.fastUpgradeNum do
				self:upgradeFloatingWord(node, v.skillId)
			end

			local size = node:get("imgIcon"):getContentSize()

			audio.playEffectWithWeekBGM("circle.mp3")
			widget.addAnimationByKey(node:get("imgIcon"), "effect/jineng.skel", nil, "effect", 555):xy(size.width / 2, size.height / 2):scale(1.3)
		end
	end
end

function CardSkillView:canLevelUp(v, isShowTip)
	local skillGold = getCostGold(v.skillLevel, csv.skill[v.skillId].costID, v.fastUpgradeNum)

	if v.skillLevel + v.fastUpgradeNum > self.cardLv:read() then
		self:showTip(gLanguageCsv.spriteLevelNotEnough, isShowTip)

		return false
	end

	if self.serverSkillPoint:read() < v.fastUpgradeNum then
		self:onSkillAddClick(isShowTip)

		return false
	end

	if skillGold > self.clientGold:read() then
		self:showTip(gLanguageCsv.skillLevelGoldNotEnough, isShowTip)

		return false
	end

	return true
end

function CardSkillView:showTip(txt, isShowTip)
	if isShowTip then
		gGameUI:showTip(txt)
	end
end

function CardSkillView:upgradeFloatingWord(node, skillId)
	self.floatingWordData = self.floatingWordData or {}

	local floatingWordData = self.floatingWordData
	local data = string.split(csv.skill[skillId].upLvDesc, "|")

	for k, v in pairs(data) do
		if not floatingWordData[skillId] then
			floatingWordData[skillId] = {}
		end

		table.insert(floatingWordData[skillId], v)
	end

	if not self.oldselectDbId then
		self.oldselectDbId = self.selectDbId:read()
	end

	if not self.skillId then
		self.skillId = skillId
	end

	if self.skillId ~= skillId then
		self.skillId = skillId
		self.floatingWordIndex = false
	end

	if not self.floatingWordIndex then
		self.floatingWordIndex = true

		local i = 0

		self:enableSchedule():schedule(function(dt)
			if next(floatingWordData[skillId]) == nil then
				if not tolua.isnull(node) then
					for j = 1, 4 do
						local panel = node:get("num" .. j)

						if panel then
							panel:hide()
						end
					end
				end

				self:unSchedule("upgradeFloatingWord" .. skillId)

				self.floatingWordIndex = false
			elseif self.oldselectDbId ~= self.selectDbId:read() then
				self.oldselectDbId = self.selectDbId:read()

				for k, v in pairs(floatingWordData) do
					floatingWordData[k] = {}
				end
			else
				if tolua.isnull(node) then
					floatingWordData[skillId] = {}

					return
				end

				i = i < 4 and i + 1 or 1

				local panel = node:get("num" .. i)

				if not panel then
					panel = cc.Label:createWithTTF(floatingWordData[skillId][1], ui.FONT_PATH, 50):align(cc.p(0, 0.5), 300, 80):addTo(node, 4000, "num" .. i)

					text.addEffect(panel, {
						color = cc.c4b(92, 153, 113, 255)
					})
				end

				panel:text(floatingWordData[skillId][1]):xy(300, 80):show():opacity(255)
				transition.executeSequence(panel):moveBy(0.4, 0, 100):fadeOut(0.3):done()
				table.remove(floatingWordData[skillId], 1)
			end
		end, 0.2, 0.2, "upgradeFloatingWord" .. skillId)
	end
end

function CardSkillView:onSkillAddClick(isShowTip)
	if not isShowTip then
		return
	end

	gGameUI:stackUI("city.card.skill_buypoint", nil, nil, self:createHandler("getBuyInfoCb"))
end

function CardSkillView:getBuyInfoCb()
	if self.serverSkillPoint:read() >= dataEasy.getSkillPointMax(self.roleLv:read()) then
		gGameUI:showTip(gLanguageCsv.skillPointBuyNoNeed)

		return
	end

	gGameApp:requestServer("/game/role/skill/point/buy", function(tb)
		gGameUI:showTip(gLanguageCsv.hasBuy)
	end)
end

function CardSkillView:onItemTipClick(list, k, v)
	if dataEasy.isSkillChange() then
		gGameUI:stackUI("common.skill_detail1", nil, nil, {
			skillId = v.skillId,
			skillLevel = v.skillLevel,
			cardId = self.cardId:read(),
			star = self.star:read(),
			isZawake = dataEasy.isZawakeSkill(v.skillId, self.zawakeSkills:read())
		})

		return
	end

	gGameUI:stackUI("common.skill_detail", nil, {
		clickClose = true,
		dispatchNodes = list
	}, {
		skillId = v.skillId,
		skillLevel = v.skillLevel,
		cardId = self.cardId:read(),
		star = self.star:read(),
		isZawake = dataEasy.isZawakeSkill(v.skillId, self.zawakeSkills:read())
	})
end

return CardSkillView
