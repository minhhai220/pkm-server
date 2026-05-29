-- chunkname: @src.app.easy.bind.extend.card_icon

local helper = require("easy.bind.helper")
local cardIcon = class("cardIcon", cc.load("mvc").ViewBase)

cardIcon.defaultProps = {
	selected = false,
	showAttribute = false,
	isNew = false,
	isBoss = false,
	grayState = 0,
	frame = true,
	space = false
}

function cardIcon:initExtend()
	if self.panel then
		self.panel:removeFromParent()
	end

	local panelSize = cc.size(198, 198)
	local panel = ccui.Layout:create():size(198, 198):addTo(self, 1, "_card_")
	local imgBG = ccui.ImageView:create(ui.QUALITY_BOX[1]):alignCenter(panelSize):addTo(panel, 1, "imgBG")
	local imgFG = ccui.ImageView:create("common/icon/panel_icon_k1.png"):alignCenter(panelSize):addTo(panel, 3, "imgFG")

	if not self.advance then
		imgBG:texture("common/icon/panel_icon.png")
		imgFG:hide()
	end

	local img = ccui.ImageView:create("common/box/box_selected.png"):alignCenter(panelSize):addTo(panel, -1, "imgSel"):hide()

	if self.selected ~= nil then
		img:visible(self.selected)
	end

	self.panel = panel
	self.params = self.params or {}

	local size = panel:size()
	local frameNode = ccui.ImageView:create():align(cc.p(0, 0.5)):xy(15, 99):addTo(panel, 4, "frame")
	local frameNumNode = cc.Label:createWithTTF("", ui.FONT_PATH, 24):align(cc.p(0, 0.5), 2, 15):addTo(frameNode, 4, "num")

	text.addEffect(frameNumNode, {
		outline = {
			size = 3,
			color = ui.COLORS.OUTLINE.DEFAULT
		}
	})
	helper.callOrWhen(self.advance, function(advance)
		local panel = self.panel

		imgFG:hide()
		panel:get("frame"):hide()

		if not tonumber(advance) then
			local rarity = isIdler(self.rarity) and self.rarity:read() or self.rarity

			if tonumber(rarity) then
				self.panel:get("imgBG"):texture(ui.QUALITY_BOX[rarity + 2])
				self.panel:get("imgFG"):show():texture(string.format("common/icon/panel_icon_k%d.png", rarity + 2)):show()
			end

			return
		end

		local quality, numStr = dataEasy.getQuality(advance, self.space)
		local boxRes = ui.QUALITY_BOX[quality]
		local frameRes = ui.QUALITY_FRAME[quality]

		imgBG:texture(boxRes)
		imgFG:texture(string.format("common/icon/panel_icon_k%d.png", quality)):show()

		local cardId = self.cardId or self.unitId

		cardId = isIdler(cardId) and cardId:read() or cardId

		local cardCsv = csv.cards[cardId]
		local unitCsv = csv.unit[cardId]

		if cardCsv then
			unitCsv = csv.unit[cardCsv.unitID]
		end

		if unitCsv and unitCsv.shiny then
			imgBG:texture(string.format("common/icon/panel_shiny_icon_%d.png", quality))
			imgFG:texture(string.format("common/icon/panel_shiny_icon_k%d.png", quality))
		end

		panel:get("frame"):texture(frameRes):show()
		frameNumNode:text(numStr)
		panel:get("frame"):visible(self.frame ~= false and numStr ~= "")
		text.addEffect(frameNumNode, {
			outline = {
				color = ui.COLORS.QUALITY_OUTLINE[quality]
			}
		})

		if self.simpleShow then
			panel:get("imgFG"):hide()
			panel:get("imgBG"):hide()
		else
			panel:get("imgFG"):show()
			panel:get("imgBG"):show()
		end
	end)

	local icon = ccui.ImageView:create():alignCenter(panelSize):scale(2):addTo(panel, 2, "icon")

	helper.callOrWhen(self.unitId or self.cardId, function(id)
		local unitId = id

		if id == -1 then
			icon:texture("common/icon/icon_empty.png"):scale(1)
		else
			if not self.unitId then
				unitId = csv.cards[id].unitID
			end

			icon:texture(csv.unit[unitId].cardIcon):scale(2)
			self:testShowMaxStar(unitId)
		end

		self:setKey(id)
	end)
	self:setLock(panel)
	self:setStar(panel)
	self:setRarity(panel)
	self:setMaterial(panel)
	self:setShiny(panel)
	self:setNew(panel)
	self:setTeam(panel)

	local level = self.levelProps and self.levelProps.data or self.level

	if level then
		bind.extend(self, panel, {
			class = "card_level",
			props = {
				data = level,
				onNode = function(node)
					node:xy(90, 35):z(4)

					if self.levelProps and self.levelProps.onNode then
						self.levelProps.onNode(node)
					end
				end
			}
		})
	end

	helper.callOrWhen(self.isBoss, function(isBoss)
		local panel = self.panel
		local img = panel:get("boosIcon")

		img = img or ccui.ImageView:create("common/icon/txt_boss.png"):anchorPoint(1, 0.5):xy(size.width - 18, 24):addTo(panel, 14, "boosIcon")

		img:visible(isBoss)
	end)
	helper.callOrWhen(self.showAttribute, function(showAttribute)
		local panel = self.panel
		local attrPanel = panel:get("attrPanel")

		if not showAttribute then
			if attrPanel then
				attrPanel:visible(showAttribute)
			end

			return
		end

		attrPanel = attrPanel or ccui.Layout:create():size(150, 70):align(cc.p(0, 0.5), 10, 32):addTo(panel, 14, "attrPanel")

		attrPanel:removeAllChildren()

		local unitInfo

		if not self.cardId then
			unitInfo = csv.unit[self.unitId]
		else
			local cardInfo = csv.cards[self.cardId]

			unitInfo = csv.unit[cardInfo.unitID]
		end

		local img1 = ccui.ImageView:create(ui.ATTR_ICON[unitInfo.natureType]):xy(23, 35):scale(0.5):addTo(attrPanel, 1)

		if unitInfo.natureType2 then
			local img2 = ccui.ImageView:create(ui.ATTR_ICON[unitInfo.natureType2]):xy(23, 35):scale(0.5):addTo(attrPanel, 1)

			adapt.oneLinePos(img1, img2, nil, "left")
		end
	end)
	helper.callOrWhen(self.maxStar, function(maxStar)
		if maxStar and dataEasy.isUnlock(gUnlockCsv.fragShopMaxStar) then
			uiEasy.setMaxStar(self.panel, {
				cardId = self.cardId:read()
			})
		end
	end)

	local grayState = self.grayState == 1 and cc.c3b(128, 128, 128) or cc.c3b(255, 255, 255)

	imgBG:color(grayState)
	icon:color(grayState)

	local grayState = self.grayState == 2 and "hsl_gray" or "normal"

	cache.setShader(imgBG, false, grayState)
	cache.setShader(icon, false, grayState)

	if self.onNode then
		self.onNode(panel)
	end

	if self.onNodeClick then
		panel:setTouchEnabled(true)
		bind.touch(self, panel, {
			methods = {
				ended = function()
					self.onNodeClick(panel)
				end
			}
		})
	end

	return self
end

function cardIcon:setLock(panel)
	if self.lock ~= nil then
		local size = panel:size()

		ccui.ImageView:create("common/btn/btn_lock.png"):scale(0.74):align(cc.p(0.5, 0.5), size.width - 10, size.height - 7):addTo(panel, 5, "lock")
		helper.callOrWhen(self.lock, function(lock)
			local panel = self.panel

			panel:get("lock"):visible(lock)
		end)
	end
end

function cardIcon:setNew(panel)
	if self.isNew ~= nil then
		local size = panel:size()

		ccui.ImageView:create("other/gain_sprite/txt_new.png"):scale(0.5):align(cc.p(0.5, 0.5), size.width - 50, size.height - 20):addTo(panel, 5, "new")
		helper.callOrWhen(self.isNew, function(isNew)
			local panel = self.panel

			panel:get("new"):visible(isNew)
		end)
	end
end

function cardIcon:setStar(panel)
	local size = panel:size()

	ccui.Layout:create():size(size.width, 70):align(cc.p(0, 0), 0, 0):addTo(panel, 5, "star")
	helper.callOrWhen(self.star, function(star)
		local starPanel = self.panel:get("star")

		starPanel:removeAllChildren()

		if tonumber(star) then
			local interval = self.params.starInterval or 12
			local starNum = star > 6 and 6 or star

			for i = 1, starNum do
				local starIdx = star - 6
				local icon = "city/card/equip/icon_star.png"

				if i <= starIdx then
					icon = "common/icon/icon_star_z1.png"
				end

				if dataEasy.getIsStarAidState(isIdler(self.dbid) and self.dbid:read() or self.dbid) then
					widget.addAnimationByKey(starPanel, "starswap/xingji.skel", "effctStar" .. i, "effect_loop", 10):xy(99 - interval * (starNum + 1 - 2 * i), 20):scale(self.params.starScale or 0.75):setCascadeOpacityEnabled(true):opacity(204)
				end

				ccui.ImageView:create(icon):xy(99 - interval * (starNum + 1 - 2 * i), 20):addTo(starPanel, 4, "star"):scale(self.params.starScale or 0.75)
			end
		end
	end)
end

function cardIcon:setRarity(panel)
	ccui.ImageView:create():align(cc.p(0.5, 0.5), 36, 164):addTo(panel, 14, "rarity"):scale(0.62)
	helper.callOrWhen(self.rarity, function(rarity)
		local panel = self.panel

		if not tonumber(rarity) then
			panel:get("rarity"):hide()

			return
		end

		panel:get("rarity"):texture(ui.RARITY_ICON[rarity]):show()

		local cardId = self.cardId or self.unitId

		cardId = isIdler(cardId) and cardId:read() or cardId

		local cardCsv = csv.cards[cardId]
		local unitCsv = csv.unit[cardId]

		if cardCsv then
			unitCsv = csv.unit[cardCsv.unitID]
		end

		local advance = isIdler(self.advance) and self.advance:read() or self.advance

		if not tonumber(advance) then
			self.panel:get("imgBG"):texture(ui.QUALITY_BOX[rarity + 2])
			self.panel:get("imgFG"):show():texture(string.format("common/icon/panel_icon_k%d.png", rarity + 2))

			if unitCsv and unitCsv.shiny then
				self.panel:get("imgBG"):texture(string.format("common/icon/panel_shiny_icon_%d.png", rarity + 2))
				self.panel:get("imgFG"):texture(string.format("common/icon/panel_shiny_icon_k%d.png", rarity + 2))
			end

			if self.simpleShow then
				panel:get("imgFG"):hide()
				panel:get("imgBG"):hide()
			else
				panel:get("imgFG"):show()
				panel:get("imgBG"):show()
			end
		end
	end)
end

function cardIcon:setMaterial(panel)
	ccui.ImageView:create("common/txt/txt_sc.png"):align(cc.p(0.5, 0.5), 108, 178):addTo(panel, 14, "material"):scale(0.64):hide()
	helper.callOrWhen(self.unitId or self.cardId, function(id)
		local unitCsv = csv.unit[id]
		local cardCsv = csv.cards[id]

		if unitCsv then
			cardCsv = csv.cards[unitCsv.cardID]
		end

		panel:get("material"):visible(cardCsv and cardCsv.cardType == 2)
	end)
end

function cardIcon:setShiny(panel)
	ccui.ImageView:create("common/txt/txt_sg.png"):align(cc.p(0.5, 0.5), 108, 178):addTo(panel, 14, "shiny"):scale(0.64):hide()
	helper.callOrWhen(self.unitId or self.cardId, function(id)
		local cardCsv = csv.cards[id]
		local unitCsv = csv.unit[id]

		if cardCsv then
			unitCsv = csv.unit[cardCsv.unitID]
		end

		panel:get("shiny"):visible(unitCsv and unitCsv.shiny)
	end)
end

function cardIcon:testShowMaxStar(unitId)
	if not dev.DEBUG_SHOW then
		return
	end

	local panel = self.panel

	panel:removeChildByName("_maxStar_")

	local cards = gGameModel.role:read("cards")

	if cards then
		local maxStar = 0
		local markId = csv.unit[unitId] and csv.cards[csv.unit[unitId].cardID] and csv.cards[csv.unit[unitId].cardID].cardMarkID

		for i, v in ipairs(cards) do
			local card = gGameModel.cards:find(v)

			if card then
				local cardId = card:read("card_id")
				local cardCfg = csv.cards[cardId]

				if cardCfg.cardMarkID == markId then
					maxStar = math.max(maxStar, card:read("star"))
				end
			end
		end

		if maxStar > 0 then
			local maxStar = label.create(maxStar .. "星", {
				fontSize = 30,
				fontPath = "font/youmi1.ttf",
				color = ui.COLORS.NORMAL.DEFAULT,
				effect = {
					outline = {
						size = 3,
						color = ui.COLORS.NORMAL.WHITE
					}
				}
			})

			maxStar:addTo(panel, 111, "_maxStar_"):xy(panel:width() / 2, panel:height() * 0.8):opacity(200)
		end
	end
end

function cardIcon:setKey(key)
	if not dev.SHOW_ITEM_ID then
		return
	end

	local panel = self.panel
	local size = panel:size()
	local label = panel:get("_key_")

	label = label or ccui.Text:create(key, ui.FONT_PATH, 32):align(cc.p(0.5, 1), size.width / 2, size.height - 15):addTo(panel, 999, "_key_")

	text.addEffect(label, {
		outline = {
			size = 1,
			color = ui.COLORS.BLACK
		}
	})
end

function cardIcon:setTeam(panel)
	if self.team ~= nil then
		local size = panel:size()
		local img = ccui.ImageView:create("common/icon/log_dw.png"):align(cc.p(0.5, 0.5), size.width - 30, size.height - 22):addTo(panel, 5, "team")
		local teamFont = label.create(self.team, {
			fontSize = 28,
			fontPath = "font/youmi1.ttf",
			color = ui.COLORS.NORMAL.WHITE
		})

		teamFont:addTo(img, 111, "_num_"):xy(img:width() / 2, img:height() / 2)
	end
end

return cardIcon
