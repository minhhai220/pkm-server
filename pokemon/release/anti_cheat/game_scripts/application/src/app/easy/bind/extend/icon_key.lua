-- chunkname: @src.app.easy.bind.extend.icon_key

local helper = require("easy.bind.helper")
local HeldItemTools = require("app.views.city.card.helditem.tools")
local ChipTools = require("app.views.city.card.chip.tools")
local iconByKey = class("iconByKey", cc.load("mvc").ViewBase)

iconByKey.defaultProps = {
	grayState = 0,
	isExtra = false
}

function iconByKey:initExtend()
	if self.panel then
		self.panel:removeFromParent()
	end

	local panel = ccui.Layout:create():alignCenter(self:size()):addTo(self, 1, "_icon_")

	self.panel = panel

	panel:setAnchorPoint(cc.p(0.5, 0.5))

	self.__type = nil
	self.__data = nil

	helper.callOrWhen(self.data, function(data)
		local panel = self.panel

		if data.key == "card" or data.key == game.UNKONW_CARD_ID then
			self:initCard(data)
		else
			if data.key == -1 then
				panel:removeAllChildren()

				local box = ccui.ImageView:create("common/icon/panel_icon.png")
				local size = box:size()

				box:alignCenter(size):addTo(panel, 1, "box")
				panel:size(size)

				return
			end

			local cfg, num, id, path = self:getItemCfg(data)

			if not cfg then
				return
			end

			if dataEasy.isContractItem(data.key) then
				self.simpleShow = true
			end

			local quality = cfg.quality

			quality = quality <= 0 and 1 or quality

			self:initItem(quality, path)
			self:setGrayState()

			if not dataEasy.isFurnitureItem(id) then
				self:setNum(num, data.targetNum, quality, data.noColor)
			end

			self:setEffect(cfg)
			self:setLogo(id, cfg, num)
			self:setItemState(data)
			self:setSpecialKey(data)
			self:setKey(data.key)

			if self.simpleShow then
				panel:get("box"):hide()
				panel:get("imgFG"):hide()
				panel:removeChildByName("logoActiveRes")

				if dataEasy.isChipItem(data.key) then
					panel:get("fragBg"):hide()
				end
			else
				panel:get("box"):show()
				panel:get("imgFG"):show()
			end

			self:setFurnInfo(id, num)
			self:setAidMaterial(id, num)
			self:testShowMaxStar(id, cfg)

			if dataEasy.isFragmentCard(id) and csv.fragments[id] and matchLanguageForce(csv.fragments[id].languages) == false then
				errorInWindows("配置可获取到卡牌碎片 %s, 但 csv.fragments (%s) 未开放", id, LOCAL_LANGUAGE)
			end
		end

		panel:setTouchEnabled(true)

		if not self.isSpecialKey and not self.noListener then
			bind.click(self, panel, {
				method = function()
					local params = {
						key = data.key,
						num = data.num,
						dbId = data.dbId
					}

					gGameUI:showItemDetail(panel, params)
				end
			})
		else
			bind.click(self, panel, {
				method = function()
					return
				end
			})
		end
	end)
	helper.callOrWhen(self.isExtra, function(isExtra)
		if isExtra then
			ccui.ImageView:create("common/txt/txt_ew.png"):align(cc.p(0.5, 0.5), 50, self.panel:box().height - 32):addTo(panel, 5, "isExtra")
		else
			panel:removeChildByName("isExtra")
		end
	end)
	helper.callOrWhen(self.isDouble, function(isDouble)
		if isDouble then
			local size = panel:size()

			ccui.ImageView:create("common/icon/icon_sb.png"):align(cc.p(1, 1), size.width, size.height):addTo(panel, 5, "isDouble")
		else
			panel:removeChildByName("isDouble")
		end
	end)

	if self.onNode then
		self.onNode(panel)
	end

	return self
end

function iconByKey:getItemCfg(data)
	local cfg, num, id, path

	self.isSpecialKey = false

	if type(data.key) == "string" and string.find(data.key, "star_skill_points_%d+") then
		local markId = tonumber(string.sub(data.key, string.find(data.key, "%d+")))

		self.isSpecialKey = true

		local cardCfg = csv.cards[markId]

		if not cardCfg then
			return
		end

		cfg = dataEasy.getCfgByKey(cardCfg.fragID)
		num = data.num
		path = "city/card/system/extremity_property/icon_jxd.png"
	else
		cfg = dataEasy.getCfgByKey(data.key)
		num = data.num
		id = dataEasy.stringMapingID(data.key)
		path = dataEasy.getIconResByKey(id)
	end

	return cfg, num, id, path
end

function iconByKey:initCard(data)
	local panel = self.panel
	local cardId, star = dataEasy.getCardIdAndStar(data.num)
	local cardCfg = csv.cards[cardId]
	local unitCfg = csv.unit[cardCfg.unitID]

	if not self.__data then
		self.__data = {
			cardId = idler.new(cardId),
			star = idler.new(star),
			rarity = idler.new(unitCfg.rarity)
		}
	end

	local maxStar = self.specialKey and self.specialKey.maxStar or nil

	if self.__type ~= "card" then
		self.__type = "card"

		panel:removeAllChildren()
		bind.extend(self, panel, {
			class = "card_icon",
			props = {
				cardId = self.__data.cardId,
				star = self.__data.star,
				rarity = self.__data.rarity,
				grayState = self.grayState,
				simpleShow = self.simpleShowCard,
				maxStar = maxStar,
				onNode = function(node)
					if data.key == game.UNKONW_CARD_ID then
						local res = dataEasy.getCfgByKey(game.UNKONW_CARD_ID).icon

						node:get("icon"):texture(res)
					end

					local bound = node:box()

					node:alignCenter(bound)
					panel:size(bound)

					if self.specialKey and self.specialKey.isHigh then
						node:removeChildByName("highRes")
						ccui.ImageView:create("activity/new_compilation_page/txt_gn.png"):anchorPoint(cc.p(1, 1)):xy(bound.width * 0.6, bound.height * 0.4):addTo(node, 102, "highRes")
					end
				end
			}
		})
	else
		self.__data.cardId:set(cardId)
		self.__data.star:set(star)
		self.__data.rarity:set(unitCfg.rarity)
	end

	self:setEffect(cardCfg)
end

function iconByKey:initItem(quality, path)
	local panel = self.panel
	local boxRes = ui.QUALITY_BOX[quality]

	if self.__type ~= "item" then
		self.__type = "item"
	end

	panel:removeAllChildren()

	local box = ccui.ImageView:create(boxRes)
	local size = box:size()

	box:alignCenter(size):addTo(panel, 1, "box")
	panel:size(size)
	ccui.ImageView:create():alignCenter(size):scale(2):addTo(panel, 2, "icon")
	ccui.ImageView:create():alignCenter(size):addTo(panel, 4, "imgFG")
	panel:get("box"):texture(boxRes)
	panel:get("icon"):texture(path):scale(2):z(2)
	panel:get("imgFG"):texture(string.format("common/icon/panel_icon_k%d.png", quality)):hide()
end

function iconByKey:setGrayState()
	local panel = self.panel
	local grayState = self.grayState == 1 and cc.c3b(128, 128, 128) or cc.c3b(255, 255, 255)

	panel:get("box"):color(grayState)
	panel:get("icon"):color(grayState)

	local grayState = self.grayState == 2 and "hsl_gray" or "normal"

	cache.setShader(panel:get("box"), false, grayState)

	if self.grayState == 3 then
		grayState = "gray"
	end

	cache.setShader(panel:get("icon"), false, grayState)
end

function iconByKey:setNum(num, targetNum, quality, noColor)
	local panel = self.panel
	local size = panel:size()
	local label = panel:get("num")
	local label1 = panel:get("num1")
	local label2 = panel:get("num2")

	if not targetNum then
		if not num or num == 0 then
			num = ""
		end

		local fontSize = 36

		if type(num) ~= "number" then
			num = gLanguageCsv[num] or num
			fontSize = 30
		end

		if not label then
			label = cc.Label:createWithTTF(num, ui.FONT_PATH, fontSize):align(cc.p(1, 0), size.width - 30, 14):addTo(panel, 10, "num")

			text.addEffect(label, {
				outline = {
					color = ui.COLORS.QUALITY_OUTLINE[quality]
				}
			})
		end

		label:show():text(mathEasy.getShortNumber(num))

		if label1 then
			itertools.invoke({
				label1,
				label2
			}, "hide")
		end
	else
		num = num or 0

		if not label1 then
			label1 = ccui.Text:create(0, ui.FONT_PATH, 36):align(cc.p(1, 0), size.width - 30, 14):addTo(panel, 10, "num1")
			label2 = ccui.Text:create(0, ui.FONT_PATH, 36):align(cc.p(1, 0), size.width - 40, 14):addTo(panel, 10, "num2")
		end

		local fontSize = 36
		local outlineSize = 4
		local label2Color

		label1:show():text("/" .. mathEasy.getShortNumber(targetNum)):setFontSize(fontSize)
		label2:show():text(mathEasy.getShortNumber(num)):setFontSize(fontSize)
		text.addEffect(label1, {
			outline = {
				color = ui.COLORS.QUALITY_OUTLINE[quality],
				size = outlineSize
			}
		})
		text.addEffect(label2, {
			outline = {
				color = ui.COLORS.QUALITY_OUTLINE[quality],
				size = outlineSize
			}
		})

		local dw = label1:width() + label2:width() - 150

		if dw > 0 then
			fontSize = math.max(math.ceil(36 - dw / 5), 26)
			outlineSize = 6
		end

		if not noColor then
			label2Color = targetNum <= num and ui.COLORS.NORMAL.ALERT_GREEN or ui.COLORS.NORMAL.ALERT_YELLOW
		end

		label1:setFontSize(fontSize)
		label2:setFontSize(fontSize)
		text.addEffect(label1, {
			outline = {
				color = ui.COLORS.QUALITY_OUTLINE[quality],
				size = outlineSize
			}
		})
		text.addEffect(label2, {
			color = label2Color,
			outline = {
				color = ui.COLORS.QUALITY_OUTLINE[quality],
				size = outlineSize
			}
		})
		text.deleteAllEffect(label1)
		text.deleteAllEffect(label2)
		text.addEffect(label1, {
			outline = {
				color = ui.COLORS.QUALITY_OUTLINE[quality],
				size = outlineSize
			}
		})
		text.addEffect(label2, {
			color = label2Color,
			outline = {
				color = ui.COLORS.QUALITY_OUTLINE[quality],
				size = outlineSize
			}
		})
		adapt.oneLinePos(label1, label2, nil, "right")

		if label then
			label:hide()
		end
	end
end

function iconByKey:setLogo(id, cfg, num)
	local panel = self.panel

	panel:removeChildByName("clipper")
	panel:removeChildByName("fragBg")
	panel:removeChildByName("fragFg")
	panel:removeChildByName("logoRes")
	panel:removeChildByName("highRes")
	panel:removeChildByName("logoActiveRes")

	if dataEasy.checkActiveSpecialLogo(id, cfg) then
		ccui.ImageView:create("common/txt/logo_yjh1.png"):align(cc.p(0, 0), 10, 6):addTo(panel, 5, "logoActiveRes")
	end

	if self.isSpecialKey then
		return
	end

	local size = panel:size()

	if dataEasy.isFragment(id) then
		self.__type = nil

		local fragBg = ccui.ImageView:create("common/icon/ico_sp.png"):align(cc.p(0.5, 0.5), size.width / 2, size.height / 2):addTo(panel, 2, "fragBg")
		local fragFg = ccui.ImageView:create("common/icon/ico_sp1.png"):align(cc.p(0.5, 0.5), size.width / 2, size.height / 2):addTo(panel, 4, "fragFg")
		local icon = self.panel:get("icon")

		icon:retain()
		icon:removeFromParent()
		icon:xy(0, 0)

		local stencil = cc.Sprite:create("common/icon/ico_spzz.png")
		local clip = cc.ClippingNode:create():setStencil(stencil):setInverted(false):setAlphaThreshold(0.05):xy(cc.p(size.width / 2, size.height / 2)):add(icon, 1):addTo(panel, 3, "clipper")

		icon:release()

		local grayState = self.grayState == 1 and cc.c3b(128, 128, 128) or cc.c3b(255, 255, 255)

		fragBg:color(grayState)
		fragFg:color(grayState)

		local grayState = self.grayState == 2 and "hsl_gray" or "normal"

		cache.setShader(fragBg, false, grayState)
		cache.setShader(fragFg, false, grayState)

		if csv.fragments[id].type ~= 1 and num and num >= csv.fragments[id].combCount then
			local fragBg = ccui.ImageView:create("common/icon/txt_khc.png"):align(cc.p(0.5, 0.5), size.width / 2, size.height / 2 + 82):addTo(panel, 10, "fragFg")
		end
	elseif dataEasy.isZawakeFragment(id) and cfg.type == 5 then
		local fragBg = ccui.ImageView:create("common/icon/icon_zjx_02.png"):align(cc.p(0.5, 0.5), size.width / 2, size.height / 2):scale(2):addTo(panel, 2, "fragBg")
		local fragFg = ccui.ImageView:create("common/icon/icon_zjx_01.png"):align(cc.p(0.5, 0.5), size.width / 2, size.height / 2):scale(2):addTo(panel, 4, "fragFg")

		self.panel:get("icon"):scale(1.36):z(3)

		local grayState = self.grayState == 1 and cc.c3b(128, 128, 128) or cc.c3b(255, 255, 255)

		fragBg:color(grayState)
		fragFg:color(grayState)

		local grayState = self.grayState == 2 and "hsl_gray" or "normal"

		cache.setShader(fragBg, false, grayState)
		cache.setShader(fragFg, false, grayState)
	elseif dataEasy.isChipItem(id) then
		local fragBg = ccui.ImageView:create(string.format("city/card/chip/icon_d_%d.png", cfg.quality)):align(cc.p(0.5, 0.5), size.width / 2, size.height / 2):rotate(60 * (cfg.pos - 1)):addTo(panel, 2, "fragBg")
		local icon = self.panel:get("icon"):scale(1):z(3)
		local grayState = self.grayState == 1 and cc.c3b(128, 128, 128) or cc.c3b(255, 255, 255)

		fragBg:color(grayState)

		local grayState = self.grayState == 2 and "hsl_gray" or "normal"

		cache.setShader(fragBg, false, grayState)
	end

	if cfg.specialArgsMap and cfg.specialArgsMap.logoRes then
		ccui.ImageView:create(cfg.specialArgsMap.logoRes):align(cc.p(1, 1), size.width, size.height):addTo(panel, 5, "logoRes")
	end
end

function iconByKey:setEffect(cfg)
	local panel = self.panel

	panel:removeChildByName("effect")

	if self.isSpecialKey then
		return
	end

	local size = panel:size()

	helper.callOrWhen(self.effect, function(effect)
		local panel = self.panel

		panel:removeChildByName("effect")

		if effect and cfg.effect and cfg.effect[effect] then
			widget.addAnimationByKey(panel, "effect/huanraoguang.skel", "effect", cfg.effect[effect], 5):xy(size.width / 2, size.height / 2)
		else
			local sprite = panel:getChildByName("effect")

			if sprite then
				sprite:removeFromParent()
			end
		end
	end)
end

function iconByKey:setItemState(data)
	local panel = self.panel

	panel:removeChildByName("isDress")
	panel:removeChildByName("isExclusive")
	panel:removeChildByName("defaultLv")
	panel:removeChildByName("gemLevelBg")
	panel:removeChildByName("gemLevel")
	panel:removeChildByName("maxStarBg")
	panel:removeChildByName("maxStarText")
	panel:removeChildByName("locked")
	panel:removeChildByName("cardHead")
	panel:removeChildByName("cardHeadDi")
	panel:removeChildByName("maxLimit")
	panel:removeChildByName("maxTotemIcon")
	panel:removeChildByName("contractType")

	if self.isSpecialKey then
		return
	end

	local size = panel:box()

	if dataEasy.isHeldItem(data.key) then
		local isDress, isExclusive = HeldItemTools.isExclusive({
			csvId = data.key,
			dbId = data.dbId
		})

		if isDress then
			ccui.ImageView:create("city/card/helditem/bag/icon_cd.png"):align(cc.p(0.5, 0.5), 30, size.height - 40):addTo(panel, 5, "isDress")
		end

		if isExclusive then
			ccui.ImageView:create("common/icon/txt_zs.png"):align(cc.p(0.5, 0.5), size.width / 2, size.height - 32):addTo(panel, 5, "isExclusive")
		end
	elseif dataEasy.isChipItem(data.key) then
		local isDress = ChipTools.isDress(data.dbId)

		if isDress and self.specialKey.showDress then
			ccui.ImageView:create("city/card/helditem/bag/icon_cd.png"):align(cc.p(0.5, 0.5), 30, size.height - 40):addTo(panel, 5, "isDress")
		end
	elseif dataEasy.isContractItem(data.key) then
		panel:get("icon"):scale(1.2)
	elseif dataEasy.isAidAdvanceMaterialItem(data.key) or dataEasy.isAidAwakeMaterialItem(data.key) then
		panel:get("icon"):scale(1.2)
	end

	self.specialKey = self.specialKey or {}

	helper.callOrWhen(self.specialKey, function(specialKey)
		panel:removeChildByName("defaultLv")

		if specialKey.lv then
			local x, y = 16, 65
			local anchorPoint = cc.p(0, 0.5)

			if specialKey.lvDir == "rightDown" then
				x, y = size.width * 0.9, 30
				anchorPoint = cc.p(1, 0.5)
			end

			local lv = cc.Label:createWithTTF(gLanguageCsv.textLv .. specialKey.lv, ui.FONT_PATH, 26):align(anchorPoint, x, y):addTo(panel, 6, "defaultLv")

			text.addEffect(lv, {
				outline = {
					color = ui.COLORS.NORMAL.DEFAULT
				}
			})
		end

		panel:removeChildByName("gemLevel")

		if specialKey.leftTopLv then
			local level = cc.Label:createWithTTF(gLanguageCsv.textLv .. specialKey.leftTopLv, ui.FONT_PATH, 30):align(cc.p(0, 1), size.height * 0.06 + 10, size.height * 0.95 - 10):addTo(panel, 101, "gemLevel")

			text.addEffect(level, {
				color = ui.COLORS.NORMAL.WHITE,
				outline = {
					color = ui.COLORS.NORMAL.DEFAULT
				}
			})
		end

		panel:removeChildByName("maxStarBg")
		panel:removeChildByName("maxStarText")

		if specialKey.maxStar and dataEasy.isUnlock(gUnlockCsv.fragShopMaxStar) and dataEasy.isFragment(data.key) then
			local cardCsv = csv.cards[csv.fragments[data.key].combID]

			if cardCsv and dataEasy.getCardMaxStar(cardCsv.cardMarkID) == 12 then
				local label = cc.Label:createWithTTF(gLanguageCsv.maxStar, "font/youmi1.ttf", 40):align(cc.p(0.5, 0.5), size.width * 0.11, size.height * 0.8 + 5):scale(0.7):addTo(panel, 101, "maxStarText")

				text.addEffect(label, {
					color = cc.c4b(245, 144, 73, 255)
				})

				local txtSize = label:size()
				local maxStarBg = ccui.Scale9Sprite:create()

				maxStarBg:initWithFile(cc.rect(60, 0, 1, 1), "city/shop/logo_shop_sp.png")
				maxStarBg:align(cc.p(0.5, 0.5), size.width * 0.11, size.height * 0.8):addTo(panel, 100, "maxStarBg"):scale(-0.7, 0.7)

				local bgWidth = math.min(txtSize.width + 35, 160)

				maxStarBg:width(bgWidth)
				label:scale(bgWidth / (txtSize.width + 35) * 0.7)
			end
		end

		panel:removeChildByName("maxTotemIcon")

		if specialKey.maxTotem and dataEasy.isTotemUnlock() and dataEasy.isTotemItem(data.key) and not dataEasy.isTotemInsert(data.key) then
			ccui.ImageView:create("common/icon/icon_man.png"):scale(0.7):align(cc.p(0.5, 0.5), size.width * 0.11, size.height * 0.8 + 5):addTo(panel, 10, "maxTotemIcon")
		end

		panel:removeChildByName("locked")

		if specialKey.locked then
			ccui.ImageView:create("city/card/chip/icon_lock.png"):addTo(panel, 10, "locked"):anchorPoint(1, 1):xy(size.width - 5, size.height - 10)
		end

		panel:removeChildByName("cardHeadDi")
		panel:removeChildByName("cardHead")

		if specialKey.unitId then
			local x, y = size.width * 0.8, size.height * 0.2

			if dataEasy.isContractItem(data.key) then
				x, y = size.width * 0.2, size.height * 0.8
			end

			local bottomImg = ccui.ImageView:create("activity/world_boss/bg_tx.png"):scale(0.3):anchorPoint(cc.p(0.5, 0.5)):opacity(150):xy(x, y):addTo(panel, 100, "cardHeadDi")
			local mask = cc.Sprite:create("activity/world_boss/bg_tx.png"):alignCenter(size)
			local logoClipping = cc.ClippingNode:create(mask):setAlphaThreshold(0.1):size(size):anchorPoint(cc.p(0.5, 0.5)):xy(x, y):scale(0.6):addTo(panel, 100, "cardHead")
			local logo = ccui.ImageView:create(csv.unit[specialKey.unitId].cardIcon):alignCenter(size):addTo(logoClipping, 1, "logo")
		end

		panel:removeChildByName("maxLimit")

		if specialKey.maxLimit then
			local key = data.key
			local cfg = dataEasy.getCfgByKey(key)
			local flag = true

			if game.ITEM_STRING_ENUM_TABLE[key] or game.ITEM_EXP_HASH[key] then
				flag = false
			elseif csv.items[key] and csv.items[key].type == game.ITEM_TYPE_ENUM_TABLE.roleDisplayType then
				flag = false
			end

			if flag and cfg.stackMax and cfg.stackMax > 3 and dataEasy.getNumByKey(key) >= cfg.stackMax then
				ccui.ImageView:create("common/txt/icon_ysx.png"):anchorPoint(cc.p(1, 1)):xy(size.width - 8, size.height - 8):addTo(panel, 102, "maxLimit")
			end
		end

		panel:removeChildByName("contractType")

		if dataEasy.isContractItem(data.key) then
			local x, y = 50, size.height - 30

			if specialKey.unitId or specialKey.typeDir == "topCenter" then
				x = size.width * 0.5
			end

			local cfg = dataEasy.getCfgByKey(data.key)

			ccui.ImageView:create(string.format("city/develop/contract/log_type%s.png", cfg.type)):addTo(panel, 10, "contractType"):anchorPoint(0.5, 0.5):xy(x, y)
		end

		panel:removeChildByName("highRes")

		if specialKey.isHigh then
			ccui.ImageView:create("activity/new_compilation_page/txt_gn.png"):anchorPoint(cc.p(1, 1)):xy(size.width * 0.6, size.height - 8):addTo(panel, 102, "highRes")
		end
	end)
end

function iconByKey:setSpecialKey(data)
	local panel = self.panel

	panel:removeChildByName("starSkillPoints")

	local size = panel:box()

	if type(data.key) == "string" and string.find(data.key, "star_skill_points_%d+") then
		panel:get("icon"):scale(1.8)

		local markId = tonumber(string.sub(data.key, string.find(data.key, "%d+")))
		local cardCfg = csv.cards[markId]
		local path = csv.unit[cardCfg.unitID].iconSimple

		ccui.ImageView:create(path):addTo(panel, 3, "starSkillPoints"):alignCenter(size):z(3):scale(1.8)
	end
end

function iconByKey:setKey(key)
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

function iconByKey:setFurnInfo(id, num, path)
	if not dataEasy.isFurnitureItem(id) then
		return
	end

	local panel = self.panel
	local quality = csv.town.home_furniture[id].quality

	panel:get("box"):texture("city/town/collection/img_dk.png"):scale(0.5)

	if quality == 1 then
		ccui.ImageView:create("city/town/logo_bq.png"):xy(155, 175):scale(0.9):scaleX(-0.9):addTo(panel, 9, "rare")

		local text = label.create(gLanguageCsv.furnitureRare, {
			fontSize = 21,
			fontPath = "font/youmi1.ttf",
			color = ui.COLORS.NORMAL.WHITE
		})

		text:addTo(panel:get("rare"), 111, "text"):alignCenter(panel:get("rare"):size()):scale(2):scaleX(-2)
	end

	panel:get("imgFG"):hide()
	panel:get("icon"):texture(path):scale(0.8)

	local icon = panel:get("icon")

	icon:retain()
	icon:removeFromParent()
	icon:xy(0, 0)

	local stencil = cc.Sprite:create("common/box/box_mask2.png")

	stencil:scale(1.25)

	local clip = cc.ClippingNode:create():setStencil(stencil):setInverted(false):setAlphaThreshold(0.05):xy(cc.p(panel:width() / 2, panel:height() / 2)):add(icon, 1):addTo(panel, 3, "clip")

	icon:release()
	panel:removeChildByName("spineRes")

	if csv.town.home_furniture[id].spineRes ~= "" then
		ccui.ImageView:create("city/town/logo_hd2.png"):xy(180, 120):scale(0.75):addTo(panel, 10, "spineRes")
	end

	if not self.effect then
		return
	end

	local panel = self.panel

	ccui.ImageView:create("city/town/collection/logo_sl.png"):xy(160, 20):scale(0.5):addTo(panel, 9, "mask")

	local numText = label.create(num, {
		fontSize = 21,
		fontPath = "font/youmi1.ttf",
		color = ui.COLORS.NORMAL.DEFAULT
	})

	numText:addTo(panel:get("mask"), 111, "text"):scale(3):xy(115, 50)
end

function iconByKey:setAidMaterial(id, num)
	if not dataEasy.isAidAdvanceMaterialItem(id) and not dataEasy.isAidAwakeMaterialItem(id) then
		return
	end

	local panel = self.panel

	panel:removeChildByName("iconBg")
	panel:removeChildByName("iconMask")

	local scaleNum = 2

	if dataEasy.isAidAdvanceMaterialItem(id) then
		ccui.ImageView:create("common/icon/icon_tp_02.png"):xy(panel:width() / 2, panel:height() / 2):scale(scaleNum):addTo(panel, 9, "iconBg")
		ccui.ImageView:create("common/icon/icon_tp_01.png"):xy(panel:width() / 2, panel:height() / 2):scale(scaleNum):addTo(panel, 1, "iconMask")
	else
		ccui.ImageView:create("common/icon/icon_jx_02.png"):xy(panel:width() / 2, panel:height() / 2):scale(scaleNum):addTo(panel, 9, "iconBg")
		ccui.ImageView:create("common/icon/icon_jx_01.png"):xy(panel:width() / 2, panel:height() / 2):scale(scaleNum):addTo(panel, 1, "iconMask")
	end
end

function iconByKey:testShowMaxStar(id, cfg)
	if not dev.DEBUG_SHOW then
		return
	end

	local panel = self.panel

	panel:removeChildByName("_maxStar_")

	if dataEasy.isFragmentCard(id) then
		local markId = csv.cards[cfg.combID].cardMarkID
		local cards = gGameModel.role:read("cards")

		if cards then
			local maxStar = 0

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
end

return iconByKey
