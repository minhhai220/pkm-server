-- chunkname: @src.app.views.common.skill_detail

if dataEasy.isSkillChange() then
	return require("app.views.common.skill_detail1")
end

local SkillDetailView = class("SkillDetailView", Dialog)

SkillDetailView.RESOURCE_FILENAME = "common_skill_detail.json"
SkillDetailView.RESOURCE_BINDING = {
	list = "list",
	panel = "panel",
	["panel.textNum"] = "powerNum",
	["btnChange.text"] = "btnText",
	["panel.textSkillPower"] = "textSkillPower",
	["panel.textNote"] = "skillType",
	["panel.imgIcon"] = "imgIcon",
	["panel.textLevel"] = "skillLv",
	["panel.imgType"] = "imgType",
	["panel.textNoteType"] = "attackType",
	imgBg = "imgBg",
	["panel.textName"] = "skillName",
	btnChange = {
		varname = "btnChange",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onBtnChangeClick")
			}
		}
	}
}
SkillDetailView.RESOURCE_STYLES = {
	clickClose = true
}

function SkillDetailView:onCreate(params, typ)
	self.params = params
	self.typ = typ
	params.skillLevel = params.skillLevel or 1

	local skillCsv = csv.skill[params.skillId]

	if params.hideSkillLevel then
		self.skillLv:hide()
	else
		self.skillLv:text(gLanguageCsv.textLv2 .. params.skillLevel)
	end

	itertools.invoke({
		self.textSkillPower,
		self.powerNum
	}, "hide")
	uiEasy.setSkillInfoToItems({
		name = self.skillName,
		icon = self.imgIcon,
		type1 = self.imgType,
		type2 = self.skillType,
		target = self.attackType
	}, skillCsv)

	if params.skillIcon then
		self.imgIcon:texture(params.skillIcon)
	end

	if params.isZawake then
		ccui.ImageView:create("city/drawcard/draw/txt_up.png"):scale(1.2):align(cc.p(1, 1), 200, 190):addTo(self.imgIcon, 1, "zawakeUp")

		local zawakeEffectID = csv.skill[params.skillId].zawakeEffect[1]

		self.skillName:text(csv.skill[zawakeEffectID].skillName .. self.skillName:text())
	end

	if userDefault.getForeverLocalKey("skillDetailOrSimple") == true or userDefault.getForeverLocalKey("skillDetailOrSimple") == nil then
		self.btnText:text(gLanguageCsv.detailDesc)
	elseif userDefault.getForeverLocalKey("skillDetailOrSimple") == false then
		self.btnText:text(gLanguageCsv.easyDesc)
	end

	if dataEasy.isUnlock(gUnlockCsv.shortDesc) then
		if skillCsv.describeShort == "" then
			self.btnChange:hide()
		else
			self.btnChange:show()
		end
	else
		self.btnChange:hide()
	end

	self.originData = {
		imgBgSize = self.imgBg:size(),
		panelY = self.panel:y(),
		listY = self.list:y(),
		btnChangeY = self.btnChange:y()
	}

	self:UpdateSkillDetailText(params, typ)

	if checkLanguage("kr") or checkLanguage("en") then
		self.attackType:anchorPoint(0, 0)
		self.attackType:xy(self.skillName:x(), self.skillName:y() - self.skillName:height() - 15)
		adapt.setTextAdaptWithSize(self.skillName, {
			vertical = "center",
			horizontal = "left",
			maxLine = 1,
			size = cc.size(610, self.skillName:height())
		})
		adapt.setTextAdaptWithSize(self.attackType, {
			vertical = "center",
			horizontal = "left",
			maxLine = 1,
			size = cc.size(450, self.attackType:height())
		})
	end

	Dialog.onCreate(self, {
		clickClose = false,
		noBlackLayer = true
	})
end

function SkillDetailView:UpdateSkillDetailText(params, typ)
	local skillCsv = csv.skill[params.skillId]
	local isDetail = userDefault.getForeverLocalKey("skillDetailOrSimple", true)
	local desc, starStr

	starStr = params.ignoreStar and "" or uiEasy.getStarSkillDesc(params, typ, isDetail)
	desc = skillCsv.describe

	if not isDetail and skillCsv.describeShort ~= "" then
		desc = skillCsv.describeShort
	end

	if params.isZawake and skillCsv.zawakeEffect[1] and skillCsv.zawakeEffect[2] ~= 1 then
		desc = skillCsv.zawakeEffectDesc

		if not isDetail and skillCsv.zawakeEffectDescShort ~= "" then
			desc = skillCsv.zawakeEffectDescShort
		end
	end

	local list, height = beauty.textScroll({
		isRich = true,
		fontSize = 40,
		list = self.list,
		strs = "#C0x5B545B#" .. eval.doMixedFormula(desc, {
			skillLevel = params.skillLevel,
			math = math
		}, nil) .. starStr
	})
	local diffHeight = cc.clampf(height, 250, 750) - 250

	if skillCsv.describeShort ~= "" then
		self.imgBg:size(self.originData.imgBgSize.width, self.originData.imgBgSize.height + diffHeight + 60)
		self.btnChange:setPosition(self.btnChange:x(), self.originData.btnChangeY - diffHeight / 2 - 30)
		self.panel:y(self.originData.panelY + diffHeight / 2 + 40)
		list:height(250 + diffHeight)
		list:y(self.originData.listY - diffHeight / 2 + 40)
		list:jumpToTop()
	else
		self.imgBg:size(self.originData.imgBgSize.width, self.originData.imgBgSize.height + diffHeight)
		self.btnChange:setPosition(self.btnChange:x(), self.originData.btnChangeY)
		self.panel:y(self.originData.panelY + diffHeight / 2)
		list:height(250 + diffHeight)
		list:y(self.originData.listY - diffHeight / 2)
	end
end

function SkillDetailView:onBtnChangeClick()
	local skillCsv = csv.skill[self.params.skillId]

	if userDefault.getForeverLocalKey("skillDetailOrSimple") == true or userDefault.getForeverLocalKey("skillDetailOrSimple") == nil then
		self.btnText:text(gLanguageCsv.easyDesc)
		userDefault.setForeverLocalKey("skillDetailOrSimple", false)
		self:UpdateSkillDetailText(self.params, self.typ)
	elseif userDefault.getForeverLocalKey("skillDetailOrSimple") == false then
		self.btnText:text(gLanguageCsv.detailDesc)
		userDefault.setForeverLocalKey("skillDetailOrSimple", true)
		self:UpdateSkillDetailText(self.params, self.typ)
	end
end

return SkillDetailView
