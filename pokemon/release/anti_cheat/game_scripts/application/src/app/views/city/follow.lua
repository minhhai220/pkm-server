-- chunkname: @src.app.views.city.follow

local ViewBase = cc.load("mvc").ViewBase
local FollowView = class("FollowView", ViewBase)

local function getRarityData(index)
	local qbRes = ""

	if not index then
		local t = clone(ui.RARITY_ICON)

		t[table.maxn(t) + 1] = qbRes

		return t
	end

	return ui.RARITY_ICON[index] or qbRes, not ui.RARITY_ICON[index]
end

FollowView.RESOURCE_FILENAME = "follow.json"
FollowView.RESOURCE_BINDING = {
	["rightPanel.noData"] = "noData",
	["rightPanel.rarityItem"] = "rarityItem",
	role = "role",
	["rightPanel.subList"] = "subList",
	btnFlip = "btnFlip",
	["rightPanel.item"] = "item",
	card = "card",
	rightPanel = "rightPanel",
	btnSure = {
		varname = "btnSure",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("btnSureClick")
			}
		}
	},
	["rightPanel.btnSure.txt"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["rightPanel.btnAll"] = {
		varname = "btnAll",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onSelectedAll")
			}
		}
	},
	["rightPanel.rarityList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				margin = 50,
				data = bindHelper.self("rarityDatas"),
				item = bindHelper.self("rarityItem"),
				dataOrderCmp = function(a, b)
					return a.rarity > b.rarity
				end,
				onItem = function(list, node, k, v)
					local path = getRarityData(v.rarity)

					node:get("img"):texture(path)
					node:get("selected"):hide()

					if v.selected then
						node:get("selected"):show()
					end

					node:onClick(functools.partial(list.itemClick, list:getIdx(k), v))
				end
			},
			handlers = {
				itemClick = bindHelper.self("onRarityItemClick")
			}
		}
	},
	["rightPanel.item.txt"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.NORMAL.ALERT_ORANGE
				}
			}
		}
	},
	["rightPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				yMargin = 10,
				leftPadding = 10,
				asyncPreload = 25,
				xMargin = 10,
				topPadding = 10,
				columnSize = 5,
				data = bindHelper.self("cardsDatas"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				dataFilterGen = bindHelper.self("onFilterFurns", true),
				dataOrderCmp = function(a, b)
					if a.feelLevel == b.feelLevel then
						return a.rarity > b.rarity
					end

					return a.feelLevel > b.feelLevel
				end,
				onCell = function(list, node, k, v)
					local unitId = dataEasy.getUnitId(v.cardId, v.skinId)

					bind.extend(list, node:get("icon"), {
						class = "card_icon",
						props = {
							unitId = unitId,
							rarity = v.rarity,
							onNode = function(panel)
								return
							end
						}
					})
					node:get("select"):hide()
					node:get("txt"):hide()

					if v.selected then
						node:get("select"):show()
					end

					if v.followed then
						node:get("txt"):show()
					end

					node:onClick(functools.partial(list.itemClick, k, v))
				end
			},
			handlers = {
				itemClick = bindHelper.self("onCardItemClick")
			}
		}
	}
}

function FollowView:onCreate(params)
	gGameUI.topuiManager:createView("title", self, {
		onClose = self:createHandler("checkSelectCard")
	}):init({
		notShow = false,
		subTitle = "FOLLOW",
		title = gLanguageCsv.follow
	})
	gGameUI:disableTouchDispatch(nil, true)

	self.cb = params.cb
	self.followCardPanel = params.panel:get("followCardPanel")

	self:initModel()
	self:updataData()
	adapt.setTextAdaptWithSize(self.noData:get("txt"), {
		vertical = "center",
		horizontal = "center",
		maxLine = 3,
		size = cc.size(500, 150)
	})
end

function FollowView:initModel()
	self.rarity = idler.new(0)
	self.cards = gGameModel.role:getIdler("cards")
	self.cardFeels = gGameModel.role:getIdler("card_feels")
	self.followCardId = gGameModel.role:read("follow_sprite")
	self.cardsDatas = idlers.newWithMap({})
	self.rarityDatas = idlers.newWithMap(table.deepcopy(ui.RARITY_DATAS))
	self.selectedCardDbid = idler.new(self.followCardId[1])

	self.rarity:addListener(function(val, oldval)
		dataEasy.tryCallFunc(self.list, "filterSortItems", false)
		self.noData:visible(self.list:getChildrenCount() <= 2)

		for k, v in self.rarityDatas:pairs() do
			if k == val then
				self.rarityDatas:atproxy(k).selected = true
			elseif k == oldval then
				self.rarityDatas:atproxy(k).selected = false
			end
		end

		self.btnAll:get("normal"):visible(val ~= 0)
		self.btnAll:get("select"):visible(val == 0)
	end)
	self.selectedCardDbid:addListener(function(val, oldval)
		for k, v in self.cardsDatas:pairs() do
			if val == v:read().dbid then
				self:initCard(self.cardsDatas:atproxy(k))

				self.cardsDatas:atproxy(k).selected = true
			elseif oldval == v:read().dbid then
				self.cardsDatas:atproxy(k).selected = false
			end
		end
	end)
end

function FollowView:initEditor()
	if not EDITOR_ENABLE then
		return false
	end

	local tips = cc.Label:createWithTTF("↑↓←→调整位置 pageUp pageDown调整缩放", "font/youmi1.ttf", 50):addTo(self:getResourceNode(), 666):xy(400, 80):anchorPoint(0, 0.5):color(cc.c4b(255, 255, 0, 255))

	text.addEffect(tips, {
		outline = {
			color = ui.COLORS.OUTLINE.DEFAULT
		}
	})

	self.editorLabel = cc.Label:createWithTTF("位置参数", "font/youmi1.ttf", 50):addTo(self:getResourceNode(), 666):xy(700, 150):anchorPoint(0, 0.5):color(cc.c4b(255, 0, 0, 255))

	text.addEffect(self.editorLabel, {
		outline = {
			color = ui.COLORS.OUTLINE.DEFAULT
		}
	})

	local sp

	idlereasy.when(self.selectedCardDbid, function(_, selectedCardDbid)
		if selectedCardDbid ~= 0 and selectedCardDbid ~= nil then
			sp = self.followCardPanel

			local card = gGameModel.cards:find(selectedCardDbid)
			local cardData = card:read("card_id", "unit_id", "skin_id")
			local scale = mathEasy.getPreciseDecimal(sp:get("card"):scaleY(), 2, true)
			local unitCsv = dataEasy.getUnitCsv(cardData.card_id, cardData.skin_id)

			self.editorLabel:text("cardid=" .. cardData.card_id .. " x=" .. sp:x() - 1750 .. " y=" .. sp:y() - 460 .. " followscale=" .. scale / unitCsv.scale)
		else
			sp = nil
		end
	end)

	local operating = false
	local keys = {
		[26] = false,
		[25] = false,
		[27] = false,
		[28] = false,
		[29] = false,
		[22] = false
	}

	local function onKeyPressed(keyCode, event)
		keys[keyCode] = true
	end

	local function onKeyReleased(keyCode, event)
		keys[keyCode] = false
	end

	local listener = cc.EventListenerKeyboard:create()

	listener:registerScriptHandler(onKeyPressed, cc.Handler.EVENT_KEYBOARD_PRESSED)
	listener:registerScriptHandler(onKeyReleased, cc.Handler.EVENT_KEYBOARD_RELEASED)
	self:getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self)
	self:enableSchedule()
	self:schedule(function(dt)
		if sp then
			local x = sp:x()
			local y = sp:y()
			local anyKeyPressed = false
			local scale = mathEasy.getPreciseDecimal(sp:get("card"):scaleY(), 2, true)

			for key, v in pairs(keys) do
				if v then
					if key == 26 then
						sp:x(x - 1)
					elseif key == 27 then
						sp:x(x + 1)
					elseif key == 28 then
						sp:y(y + 1)
					elseif key == 29 then
						sp:y(y - 1)
					elseif key == 29 then
						sp:y(y - 1)
					elseif key == 22 then
						sp:get("card"):scaleY(scale - 0.01)
						sp:get("card"):scaleX(0.01 - scale)
					elseif key == 25 then
						sp:get("card"):scaleY(scale + 0.01)
						sp:get("card"):scaleX(-0.01 - scale)
					end

					anyKeyPressed = true
				end
			end

			if anyKeyPressed then
				local card = gGameModel.cards:find(self.selectedCardDbid:read())
				local cardData = card:read("card_id", "unit_id", "skin_id")
				local unitCsv = dataEasy.getUnitCsv(cardData.card_id, cardData.skin_id)

				self.editorLabel:text("cardid=" .. cardData.card_id .. " x=" .. sp:x() - 1750 .. " y=" .. sp:y() - 460 .. " followscale=" .. scale / unitCsv.scale)
			end
		end
	end, 0, 0.02, 66)
end

function FollowView:updataData()
	local cards = self.cards:read()
	local cardFeels = self.cardFeels:read()
	local cardsDatas = {}

	for i, v in ipairs(cards) do
		local card = gGameModel.cards:find(v)

		if card then
			local cardData = card:read("card_id", "unit_id", "skin_id")
			local cardCsv = csv.cards[cardData.card_id]
			local unitCsv = dataEasy.getUnitCsv(cardData.card_id, cardData.skin_id)
			local cardFeel = cardFeels[cardCsv.cardMarkID] or {}
			local level = cardFeel.level or 0

			if level >= gCommonConfigCsv.followSpriteNeedFeelLevel and (not cardsDatas[cardData.card_id] or cardsDatas[cardData.card_id] and cardData.skin_id ~= 0 or v == self.followCardId[1]) then
				cardsDatas[cardData.card_id] = {
					dbid = v,
					cardId = cardData.card_id,
					markId = cardCsv.cardMarkID,
					rarity = unitCsv.rarity,
					skinId = cardData.skin_id,
					followed = v == self.followCardId[1],
					selected = v == self.followCardId[1],
					feelLevel = level
				}
			end
		end
	end

	self.cardsDatas:update(cardsDatas)
	self.noData:visible()

	if itertools.size(cardsDatas) == 0 then
		uiEasy.setBtnShader(self.btnSure, self.btnSure:get("txt"), 2)
		self.noData:show()
	else
		self.noData:hide()
	end
end

function FollowView:initCard(data)
	self.followCardPanel:removeChildByName("card")

	local unitCsv = dataEasy.getUnitCsv(data.cardId, data.skinId)
	local cardSpine = widget.addAnimationByKey(self.followCardPanel, unitCsv.unitRes, "card", "standby_loop", 10)

	cardSpine:xy(unitCsv.followSpinePos.x, unitCsv.followSpinePos.y)
	cardSpine:scaleX(-unitCsv.scale * unitCsv.followSpineScale):scaleY(unitCsv.scale * unitCsv.followSpineScale):setSkin(unitCsv.skin)

	cardSpine.isTintBlack = gStandbyEffectOptionCsv[unitCsv.unitRes]

	if self.followCardPanel.shaderColor then
		if cardSpine.isTintBlack then
			cardSpine:setColor2Shader(self.followCardPanel.shaderColor)
		else
			cache.setColor2Shader(cardSpine, false, self.followCardPanel.shaderColor)
		end
	end
end

function FollowView:btnSureClick()
	local selectedCardDbid = self.selectedCardDbid:read()

	gGameApp:requestServer("/game/follow/sprite", function(tb)
		self:onClose()
	end, selectedCardDbid == 0 and "" or selectedCardDbid)
end

function FollowView:onFilterFurns(list)
	local rarity = self.rarity:read()
	local isAll = rarity == 0

	return function(id, FurnData)
		if isAll then
			return true
		elseif FurnData.rarity == rarity then
			return true, FurnData.dbid
		else
			return false
		end

		return false
	end
end

function FollowView:onRarityItemClick(list, t, v)
	self.rarity:set(v.rarity)
end

function FollowView:onCardItemClick(list, k, v)
	if self.selectedCardDbid:read() == v.dbid then
		self.selectedCardDbid:set(0)
		self.followCardPanel:removeChildByName("card")
	else
		self.selectedCardDbid:set(v.dbid)
	end
end

function FollowView:onSelectedAll()
	self.rarity:set(0)
end

function FollowView:checkSelectCard()
	if type and self.followCardId[1] ~= self.selectedCardDbid:read() then
		gGameUI:showDialog({
			isRich = false,
			clearFast = true,
			btnType = 2,
			cb = function()
				local card = gGameModel.cards:find(self.followCardId[1])

				if card then
					local cardData = card:read("card_id", "unit_id", "skin_id")

					self:initCard({
						cardId = cardData.card_id,
						skinId = cardData.skin_id
					})
				else
					self.followCardPanel:removeChildByName("card")
				end

				self:onClose()
			end,
			title = gLanguageCsv.spaceTips,
			content = gLanguageCsv.followSelectExitTip,
			dialogParams = {
				clickClose = false
			}
		})
	else
		self:onClose()
	end
end

function FollowView:onClose()
	if self.cb then
		self:addCallbackOnExit(self.cb)
	end

	ViewBase.onClose(self)
end

return FollowView
