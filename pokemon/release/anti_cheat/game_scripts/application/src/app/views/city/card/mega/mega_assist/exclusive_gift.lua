-- chunkname: @src.app.views.city.card.mega.mega_assist.exclusive_gift

local MegaAssistExclusiveGiftView = class("MegaAssistExclusiveGiftView", cc.load("mvc").ViewBase)
local STATE_TYPE = {
	sellOut = 2,
	canBuy = 1
}
local NO_SELECT_ITEM = {
	specHeld = 11,
	specEvo = 13,
	specFrag = 12,
	specCard = game.UNKONW_CARD_ID
}

local function getShowAwardCfg(award, v)
	local tb = table.deepcopy(award, true)
	local yyCfg = csv.yunying.yyhuodong[v.activityID]

	for key, showKey in pairs(NO_SELECT_ITEM) do
		if tb[key] then
			if v.selectMarkID ~= 0 then
				if key == "specFrag" then
					local cardCfg = csv.cards[v.selectMarkID]
					local fragID = cardCfg.fragID

					tb[fragID] = tb[key]
					tb[key] = nil
				elseif key == "specEvo" or key == "specHeld" then
					tb[yyCfg.paramMap.markID[v.selectMarkID][key]] = tb[key]
					tb[key] = nil
				elseif key == "specCard" then
					tb.cards = {
						id = v.selectMarkID
					}
					tb[key] = nil
				end
			else
				tb[NO_SELECT_ITEM[key]] = tb[key]
				tb[key] = nil
			end
		end
	end

	return tb
end

MegaAssistExclusiveGiftView.RESOURCE_FILENAME = "mega_assist_exclusive.json"
MegaAssistExclusiveGiftView.RESOURCE_BINDING = {
	item = "item",
	btnClose = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	},
	list = {
		varname = "list",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				asyncPreload = 4,
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				dataOrderCmp = function(a, b)
					if a.state ~= b.state then
						return a.state < b.state
					end

					return a.csvId < b.csvId
				end,
				onItem = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("buyTimes", "btnBuy", "itemList")

					childs.buyTimes:text(string.format(gLanguageCsv.directBuyGiftOnetimeBuy, v.leftTimes, cfg.limit))

					local items = getShowAwardCfg(cfg.items, v)

					uiEasy.createItemsToList(list, childs.itemList, items, {
						margin = 0,
						scale = 0.65,
						onAfterBuild = function(list)
							childs.itemList:setItemAlignCenter()
						end
					})

					local priceStr

					if v.price ~= "free" then
						priceStr = v.leftTimes > 0 and string.format(gLanguageCsv.symbolMoney, v.price) or gLanguageCsv.sellout
					else
						priceStr = gLanguageCsv.freeToReceive
					end

					childs.btnBuy:get("txtPrice"):text(priceStr)
					text.addEffect(childs.btnBuy:get("txtPrice"), {
						color = ui.COLORS.NORMAL.WHITE,
						glow = {
							color = ui.COLORS.GLOW.WHITE
						}
					})

					local btnState = v.state == STATE_TYPE.canBuy and 1 or 2

					if v.selectMarkID == 0 then
						btnState = 3
					end

					local isInfo = btnState == 1 and v.price == "free"
					local props = {
						class = "red_hint",
						props = {
							state = isInfo,
							onNode = function(panel)
								panel:xy(330, 100)
							end
						}
					}

					bind.extend(list, childs.btnBuy, props)
					uiEasy.setBtnShader(childs.btnBuy, childs.btnBuy:get("txtPrice"), btnState)
					bind.touch(list, childs.btnBuy, {
						clicksafe = true,
						methods = {
							ended = functools.partial(list.clickBuy, k, v)
						}
					})
				end
			},
			handlers = {
				clickBuy = bindHelper.self("onBuyClick")
			}
		}
	}
}

function MegaAssistExclusiveGiftView:onCreate(activityId)
	Dialog.onCreate(self)

	self.activityId = activityId

	self:initModel()

	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongID = yyCfg.huodongID

	self.datas = idlers.new()
	self.clientBuyTimes = idler.new(true)

	idlereasy.any({
		self.yyhuodongs,
		self.clientBuyTimes
	}, function(_, yyhuodongs)
		local yydata = yyhuodongs[activityId] or {}
		local valsums = yydata.valsums or {}
		local info = yydata.info or {}
		local datas = {}

		for k, v in csvPairs(csv.yunying.mega_assist) do
			if v.huodongID == huodongID and v.taskType == 3 then
				local state = STATE_TYPE.sellOut
				local buyTimes = valsums[k] or 0

				buyTimes = dataEasy.getPayClientBuyTimes("directBuyData", activityId, k, buyTimes)

				local leftTimes = math.max(0, v.limit - buyTimes)

				if leftTimes > 0 and info.markID then
					state = STATE_TYPE.canBuy
				end

				local price

				if v.rechargeID > 0 then
					price = csv.recharges[v.rechargeID].rmbDisplay
				else
					price = "free"
				end

				table.insert(datas, {
					csvId = k,
					cfg = v,
					state = state,
					buyTimes = buyTimes,
					leftTimes = leftTimes,
					price = price,
					activityID = activityId,
					selectMarkID = info.markID or 0
				})
			end
		end

		self.datas:update(datas)
	end)
end

function MegaAssistExclusiveGiftView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function MegaAssistExclusiveGiftView:onBuyClick(list, k, v)
	if v.selectMarkID == 0 then
		gGameUI:showTip(gLanguageCsv.megaAssistUnlockTips)

		return
	end

	if v.price == "free" then
		self:buyRmbGift(v)

		return
	end

	gGameApp:payDirect(self, {
		rechargeId = v.cfg.rechargeID,
		yyID = self.activityId,
		csvID = v.csvId,
		name = v.cfg.name,
		buyTimes = v.buyTimes
	}, self.clientBuyTimes):doit()
end

function MegaAssistExclusiveGiftView:buyRmbGift(data, count)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		self.clientBuyTimes:notify()
		gGameUI:showGainDisplay(tb)
	end, self.activityId, data.csvId, count)
end

return MegaAssistExclusiveGiftView
