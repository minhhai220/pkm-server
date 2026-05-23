-- chunkname: @src.app.views.city.handbook.skill

local HandbookSkillView = class("HandbookSkillView", cc.load("mvc").ViewBase)

HandbookSkillView.RESOURCE_FILENAME = "handbook_skill.json"
HandbookSkillView.RESOURCE_BINDING = {
	panel = "panel",
	skillItem = "skillItem",
	["panel.list"] = {
		varname = "list",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("skillDatas"),
				item = bindHelper.self("skillItem"),
				itemAction = {
					alwaysShow = true,
					isAction = true
				},
				onItem = function(list, node, k, v)
					node:get("textLV"):text(gLanguageCsv.textLv)
					node:get("textLVNum"):text(v.skillLevel)
					adapt.oneLinePos(node:get("textLVNum"), node:get("textLV"), cc.p(0, 0), "right")
					uiEasy.setSkillInfoToItems({
						name = node:get("textSkillName"),
						icon = node:get("imgIcon"),
						type1 = node:get("imgFlag")
					}, v.skillId)
					adapt.setTextAdaptWithSize(node:get("textSkillName"), {
						vertical = "center",
						horizontal = "left",
						size = cc.size(500, 150)
					})
					bind.touch(list, node:get("btnInfo"), {
						methods = {
							ended = functools.partial(list.clickItem, v)
						}
					})
					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.clickItem, v)
						}
					})
				end
			},
			handlers = {
				clickItem = bindHelper.self("onShowSkillInfo")
			}
		}
	}
}

function HandbookSkillView:onCreate(params)
	self.cardIdIdler = params.selCardId()
	self.skillDatas = idlertable.new({})

	idlereasy.when(self.cardIdIdler, function(_, cardId)
		if cardId == 0 then
			return
		end

		local skillDatas = {}
		local cardcfg = csv.cards[cardId]
		local skillList = dataEasy.getSortCardSkillList(cardId)

		for _, v in ipairs(skillList) do
			local passive = 1

			if csv.skill[v].skillType2 == battle.MainSkillType.PassiveSkill then
				passive = 2
			end

			table.insert(skillDatas, {
				skillLevel = 1,
				skillId = v,
				skillPassive = passive
			})
		end

		self.skillDatas:set(skillDatas)

		local unitcfg = csv.unit[cardcfg.unitID]
		local natureAttr = {}

		table.insert(natureAttr, unitcfg.natureType)

		if unitcfg.natureType2 then
			table.insert(natureAttr, unitcfg.natureType2)
		end
	end)
end

function HandbookSkillView:onShowSkillInfo(node, skillInfo)
	if dataEasy.isSkillChange() then
		gGameUI:stackUI("common.skill_detail", nil, nil, {
			star = 1,
			skillId = skillInfo.skillId,
			skillLevel = skillInfo.skillLevel,
			cardId = self.cardIdIdler:read()
		})

		return
	end

	local view = gGameUI:stackUI("common.skill_detail", nil, {
		clickClose = true,
		dispatchNodes = self.list
	}, {
		skillId = skillInfo.skillId,
		skillLevel = skillInfo.skillLevel,
		cardId = self.cardIdIdler:read(),
		star = uiEasy.getMaxStar(self.cardIdIdler:read())
	}, "handbook")
	local panel = view:getResourceNode()
	local x, y = panel:xy()

	panel:x(x - 165)
end

return HandbookSkillView
