-- chunkname: @src.app.views.common.skill_detail1

local SkillDetailView = class("SkillDetailView", Dialog)

SkillDetailView.RESOURCE_FILENAME = "common_skill_detail1.json"
SkillDetailView.RESOURCE_BINDING = {
	["actionPanel.topPanel.imgType"] = "imgType",
	["actionPanel.middlePanel.btnChange.text"] = "btnText",
	item = "item",
	["actionPanel.topPanel"] = "panel",
	["actionPanel.imgBg"] = "imgBg",
	actionPanel = "actionPanel",
	["actionPanel.middlePanel.list"] = "list",
	["actionPanel.middlePanel.imgLine"] = "imgLine",
	["actionPanel.middlePanel"] = "middlePanel",
	["actionPanel.topPanel.imgBg"] = "topImgBg",
	["actionPanel.rightPanel.list"] = "rightList",
	["actionPanel.topPanel.startDesc"] = "startDesc",
	["actionPanel.rightPanel.item"] = "rightItem",
	["actionPanel.topPanel.textNote"] = "skillType",
	["actionPanel.rightPanel"] = "rightPanel",
	["actionPanel.topPanel.textLevel"] = "skillLv",
	["actionPanel.imgLine"] = "buttomLine",
	["actionPanel.topPanel.textNoteType"] = "attackType",
	["actionPanel.keyWordsScrollPanel.buttomPanel"] = "buttomPanel",
	["actionPanel.topPanel.textName"] = "skillName",
	["actionPanel.keyWordsScrollPanel"] = "keyWordsScrollPanel",
	["actionPanel.topPanel.imgIcon"] = "imgIcon",
	["actionPanel.middlePanel.btnChange"] = {
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
	blackLayer = true,
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

	self.lastSelectKeyWords = {}

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

	self.topImgBg:width(self.skillType:width() + 34)

	self.keyWords = skillCsv.keyWords

	if params.isZawake then
		self.keyWords = skillCsv.zawakeKeyWords

		ccui.ImageView:create("city/drawcard/draw/txt_up.png"):scale(1.2):align(cc.p(1, 1), 200, 190):addTo(self.imgIcon, 1, "zawakeUp")

		local zawakeEffectID = csv.skill[params.skillId].zawakeEffect[1]

		self.skillName:text(csv.skill[zawakeEffectID].skillName .. self.skillName:text())
	end

	adapt.setTextAdaptWithSize(self.skillName, {
		vertical = "center",
		horizontal = "left",
		size = cc.size(870 - self.topImgBg:width(), 120)
	})

	if userDefault.getForeverLocalKey("skillDetailOrSimple") == false then
		self.btnText:text(gLanguageCsv.easyDesc)
	else
		self.btnText:text(gLanguageCsv.detailDesc)
	end

	self.btnChange:hide()

	self.originData = {
		listHeight = self.list:height(),
		imgBgSize = self.imgBg:size(),
		panelY = self.panel:y(),
		actionPanelPos = cc.p(self.actionPanel:xy())
	}

	function params.linkFunc(key)
		self:onItemClick(key)
	end

	self:UpdateSkillDetailText(params, typ)
	adapt.setTextScaleWithWidth(self.attackType, nil, 600)
	adapt.oneLinePos(self.skillLv, self.attackType, cc.p(20, 0))
	self.list:setScrollBarEnabled(false)
	Dialog.onCreate(self, {
		noBlackLayer = true,
		clickClose = false
	})
	self.rightList:setScrollBarEnabled(false)
end

function SkillDetailView:updateDetailList()
	self.rightList:removeAllItems()

	local function createItem(key, text)
		local item = self.rightItem:clone():show()
		local name = self:createKeyWordsItem(key, 580):anchorPoint(0, 1):xy(42, 280):name("name"):addTo(item)
		local str = "#C0x5B545B#" .. eval.doMixedFormula(text, {
			skillLevel = self.params.skillLevel or 1,
			math = math
		})
		local richText = rich.createWithWidth(str, 40, nil, 570):anchorPoint(0, 1):xy(42, 0):addTo(item, 3, "text")
		local allHeight = richText:height() + 150

		item:height(allHeight)
		richText:y(item:height() - 102)
		name:y(item:height() - 28)

		local imgNode = item:get("imgBg")

		imgNode:height(allHeight)

		return item
	end

	for _, v in ipairs(self.lastSelectKeyWords) do
		self.rightList:pushBackCustomItem(createItem(v.key, v.str))
	end

	self.rightList:height(self.imgBg:height())
	self.rightPanel:height(self.imgBg:height())
	self.rightPanel:y(self.panel:y() + self.panel:height() / 2 + 20)
	self.rightList:y(0)
	self.rightList:adaptTouchEnabled()
end

function SkillDetailView:onItemClick(key)
	local isExit = false
	local index

	for i, v in ipairs(self.lastSelectKeyWords) do
		if v.key == key then
			isExit = true
			index = i

			break
		end
	end

	if isExit then
		table.remove(self.lastSelectKeyWords, index)

		if itertools.size(self.lastSelectKeyWords) == 0 then
			local action = cc.Spawn:create(cc.MoveTo:create(0.1, self.originData.actionPanelPos), cc.CallFunc:create(function()
				self.rightPanel:hide()
			end))

			self.actionPanel:runAction(action)

			self.lastSelectKeyWords = {}

			return
		end

		self:updateDetailList()

		return
	end

	local cfg = gSkillDescKeyWordsCsv[key]

	if not cfg then
		printError("csv.skill_desc_key_words[%s] 不存在", key)

		return
	end

	if itertools.size(self.lastSelectKeyWords) == 0 then
		local action = cc.Spawn:create(cc.MoveTo:create(0.1, cc.pAdd(self.originData.actionPanelPos, cc.p(-350, 0))), cc.Sequence:create(cc.DelayTime:create(0.1), cc.CallFunc:create(function()
			self.rightPanel:show()
		end)))

		self.actionPanel:runAction(action)
	end

	table.insert(self.lastSelectKeyWords, 1, {
		key = key,
		str = cfg.desc
	})
	self:updateDetailList()
end

function SkillDetailView:createKeyWordsItem(key, maxWidth)
	maxWidth = maxWidth or 1000

	local cfg = gSkillDescKeyWordsCsv[key]
	local item = self.item:clone()
	local txt = item:get("text"):show()

	txt:text(cfg.name)
	text.addEffect(txt, {
		outline = {
			size = 3,
			color = cc.c3b(unpack(cfg.strokeColor, 1, 3))
		}
	})
	item:removeChildByName("richText")

	local curWidth = txt:width()

	if maxWidth < curWidth then
		curWidth = maxWidth

		txt:hide()
		beauty.singleTextAutoScroll({
			style = 1,
			align = "left",
			size = cc.size(maxWidth, 50),
			strs = {
				fontPath = "font/youmi1.ttf",
				str = cfg.name
			},
			effect = {
				outline = {
					size = 3,
					color = cc.c3b(unpack(cfg.strokeColor, 1, 3))
				}
			}
		}):xy(0, 10):addTo(item, txt:z(), "richText")
	end

	if matchLanguage({
		"cn"
	}) then
		item:get("imgBg"):color(cc.c3b(unpack(cfg.bgColor, 1, 3))):width(curWidth)
	else
		item:get("imgBg"):color(cc.c3b(unpack(cfg.bgColor, 1, 3))):width(curWidth + 40)
	end

	item:width(curWidth)

	return item:show()
end

function SkillDetailView:UpdateSkillDetailText(params, typ)
	local skillCsv = csv.skill[params.skillId]
	local isDetail = userDefault.getForeverLocalKey("skillDetailOrSimple", true)
	local hasDescGray = false

	if skillCsv.descGray and skillCsv.descGray ~= "" then
		hasDescGray = true
	end

	self.list:height(0)
	uiEasy.showSkillDesc(self.list, params, typ, isDetail)
	self.list:jumpToTop()

	local innerSize = self.list:getInnerContainerSize()
	local itemHeight = innerSize.height
	local minHeight = 240
	local maxHeight = 860

	if not hasDescGray then
		maxHeight = maxHeight + 76
	end

	if csvSize(self.keyWords) == 0 then
		maxHeight = maxHeight + self.buttomPanel:height()
	end

	if self.btnChange:visible() then
		minHeight = minHeight - 90
		maxHeight = maxHeight - 90
	end

	local diffHeight = cc.clampf(itemHeight, minHeight, maxHeight) - self.originData.listHeight

	self.list:height(self.originData.listHeight + diffHeight)
	self.middlePanel:height(self.originData.listHeight + diffHeight)

	local diffButtomHeight = -100
	local maxLine = 1
	local noKeyWordsHeight = 0

	if csvSize(self.keyWords) > 0 then
		for _, child in pairs(self.buttomPanel:getChildren()) do
			if child:name() ~= "imgLine" then
				self.buttomPanel:removeChild(child)
			end
		end

		local margin = 50
		local heightIdx = 1
		local currentWidth = 0

		for _, key in orderCsvPairs(self.keyWords) do
			if not gSkillDescKeyWordsCsv[key] then
				printError("csv.skill_desc_key_words[%s] 不存在", key)
			elseif gSkillDescKeyWordsCsv[key].name ~= "" then
				local item = self:createKeyWordsItem(key)
				local curWidth = item:width()

				if currentWidth + curWidth > self.buttomPanel:width() then
					currentWidth = 0
					heightIdx = heightIdx + 1
				end

				item:addTo(self.buttomPanel):xy(currentWidth + item:width() / 2, -(heightIdx - 1) * 75 + self.buttomPanel:height() - item:height() / 2)

				currentWidth = currentWidth + curWidth + margin

				bind.touch(self, item, {
					methods = {
						ended = functools.partial(self.onItemClick, self, key)
					}
				})
			end
		end

		maxLine = heightIdx

		setContentSizeOfAnchor(self.buttomPanel, cc.size(self.buttomPanel:width(), heightIdx * 75 - 20))

		diffButtomHeight = cc.clampf(self.buttomPanel:height(), 100, 300) - 100
	else
		self.buttomPanel:hide()
		self.buttomLine:hide()

		noKeyWordsHeight = 40
	end

	local totalDiffHeight = diffHeight + diffButtomHeight

	totalDiffHeight = totalDiffHeight - 90

	if hasDescGray then
		self.startDesc:text(skillCsv.descGray):show()
	else
		self.startDesc:hide()
	end

	if not hasDescGray then
		totalDiffHeight = totalDiffHeight - 70
	end

	local itemHeight = self.item:height()
	local maxScrollHeight = itemHeight * 3.35
	local keyWordsSize = self.buttomPanel:size()
	local realHeight = maxScrollHeight >= keyWordsSize.height and keyWordsSize.height or maxScrollHeight

	if maxLine == 2 then
		realHeight = realHeight + 30

		self.keyWordsScrollPanel:setTouchEnabled(false)
	end

	self.keyWordsScrollPanel:size(keyWordsSize.width, realHeight):setInnerContainerSize(cc.size(keyWordsSize.width, keyWordsSize.height)):setInnerContainerPosition(cc.p(0, realHeight - keyWordsSize.height))
	self.keyWordsScrollPanel:setScrollBarEnabled(false)

	local deltaHeight = realHeight <= keyWordsSize.height and keyWordsSize.height - realHeight or 0
	local deltaBgHeight = maxLine >= 2 and 40 or 20
	local deltaLineHeight = maxLine == 1 and noKeyWordsHeight == 0 and 30 or 0

	self.imgBg:height(self.originData.imgBgSize.height + totalDiffHeight + deltaBgHeight - deltaHeight - noKeyWordsHeight - deltaLineHeight)
	self.panel:y(self.originData.panelY + totalDiffHeight / 2 - deltaHeight / 2 + deltaBgHeight / 2 - noKeyWordsHeight / 2 - deltaLineHeight / 2)

	local middlePos = self.panel:y() - self.panel:height() / 2 - self.middlePanel:height() / 2

	self.middlePanel:y(hasDescGray and middlePos - 30 or middlePos + 30)
	self.imgLine:y(self.middlePanel:height() + 20)
	self.buttomLine:y(self.middlePanel:y() - self.middlePanel:height() / 2 - 30 + deltaLineHeight / 2)
	self.keyWordsScrollPanel:y(self.middlePanel:y() - self.middlePanel:height() / 2 - self.keyWordsScrollPanel:height() - 50 + deltaLineHeight / 2)
	self.buttomPanel:y(keyWordsSize.height)
	self.rightPanel:y(self.panel:y() + self.panel:height() / 2 + 20)
end

function SkillDetailView:onBtnChangeClick()
	if userDefault.getForeverLocalKey("skillDetailOrSimple") == false then
		self.btnText:text(gLanguageCsv.detailDesc)
		userDefault.setForeverLocalKey("skillDetailOrSimple", true)
		self:UpdateSkillDetailText(self.params, self.typ)
	else
		self.btnText:text(gLanguageCsv.easyDesc)
		userDefault.setForeverLocalKey("skillDetailOrSimple", false)
		self:UpdateSkillDetailText(self.params, self.typ)
	end
end

return SkillDetailView
