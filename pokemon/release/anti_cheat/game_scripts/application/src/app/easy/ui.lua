-- chunkname: @src.app.easy.ui

local rectContainsPoint = cc.rectContainsPoint
local uiEasy = {}

globals.uiEasy = uiEasy

function uiEasy.isContainsWorldPoint(obj, point)
	if not obj or not point then
		return false
	end

	local rect = obj:box()
	local pos = obj:parent():convertToWorldSpace(cc.p(rect.x, rect.y))

	rect.x, rect.y = pos.x, pos.y

	if rectContainsPoint(rect, point) then
		return true
	end
end

local function getIconNameQuality(params, cfg, advance)
	local quality, numStr = dataEasy.getQuality(advance, params.space)
	local name = ""

	if params.name then
		if type(params.name) == "table" then
			name = gLanguageCsv[params.name[quality]]
		elseif params.name == "" then
			name = cfg.name
		else
			name = params.name
		end
	else
		name = cfg.name
	end

	name = name .. numStr

	return name, quality
end

function uiEasy.setIconName(key, num, params)
	params = params or {}

	local quality = 1
	local name, numStr = "", ""
	local effect

	if key == "card" then
		local cardId = dataEasy.getCardIdAndStar(num)
		local cardCfg = csv.cards[cardId]

		name, quality = getIconNameQuality(params, cardCfg, params.advance or 1)
	elseif key == "explore" then
		local exploreCfg = csv.explorer.explorer[num]

		name, quality = getIconNameQuality(params, exploreCfg, params.advance or 1)
	elseif type(key) == "string" and string.find(key, "star_skill_points_%d+") then
		local markId = tonumber(string.sub(key, string.find(key, "%d+")))
		local mergeInfo = dataEasy.getCardMergeInfo()

		name = csv.cards[markId].name .. gLanguageCsv.starSkill

		local roleCardMerge = gGameModel.role:read("card_merge") or {}

		roleCardMerge = roleCardMerge[markId] or {}

		if roleCardMerge.id then
			local cardData = gGameModel.cards:find(roleCardMerge.id)
			local cardId = cardData:read("card_id")

			name = csv.cards[cardId].name .. gLanguageCsv.starSkill
		end
	else
		local cfg = dataEasy.getCfgByKey(key)

		if not cfg then
			return
		end

		quality = dataEasy.isFurnitureItem(key) and 1 or cfg.quality
		name = cfg.name

		if (dataEasy.isHeldItem(key) or dataEasy.isContractItem(key)) and params.advance and params.advance > 0 then
			name = name .. string.format("%s+%s", params.space and " " or "", params.advance)
		end
	end

	effect = {
		color = ui.COLORS.QUALITY_OUTLINE[quality]
	}

	if params.node then
		params.node:text(name)

		if not params.noColor then
			text.addEffect(params.node, effect)
		end

		if params.width and params.node:width() > params.width then
			local anchor = params.node:anchorPoint()
			local nodeHeight = params.node:height()
			local nodeY = params.node:y()
			local offsetY = (1 - anchor.y) * nodeHeight

			params.node:anchorPoint(anchor.x, 1)
			params.node:y(nodeY + offsetY)
			adapt.setTextAdaptWithSize(params.node, {
				vertical = "top",
				size = cc.size(params.width, nodeHeight * 3)
			})
		end
	end

	return name, effect
end

function uiEasy.getCardName(cardDbId)
	local card = gGameModel.cards:find(cardDbId)
	local cardId = card:read("card_id")
	local advance = card:read("advance")
	local quality, nameStr = dataEasy.getQuality(advance)
	local color = ui.QUALITY_OUTLINE_COLOR[quality]
	local name = csv.cards[cardId].name

	return string.format("%s%s%s", color, name, nameStr)
end

function uiEasy.getIconDesc(key, num)
	local desc = ""
	local cfg = dataEasy.getCfgByKey(key)

	if dataEasy.isFragment(key) then
		desc = string.format(cfg.desc, cfg.combCount)
	else
		desc = cfg.desc
	end

	if cfg.descType and cfg.descType ~= 0 and cfg.type == game.ITEM_TYPE_ENUM_TABLE.chooseGift then
		local t = {}

		local function setData(id, data)
			if id == "card" then
				local cardCfg = csv.cards[data.id]

				if not assertInWindows(cardCfg, "csv.item[%s].specialArgsMap card:%s not exist", key, data.id) then
					table.insert(t, cardCfg.name)
				end
			else
				local itemCfg = dataEasy.getCfgByKey(id)
				local str = itemCfg.name

				if data > 1 or cfg.descType == 2 then
					str = string.format("%s*%s", str, data)
				end

				table.insert(t, str)
			end
		end

		for _, v in csvMapPairs(cfg.specialArgsMap) do
			if type(v) == "string" then
				for _, tagCfg in ipairs(gTagItemsLibCsv[v] or {}) do
					if tagCfg.itemID == 0 and tagCfg.cardID == 0 or tagCfg.itemID ~= 0 and tagCfg.cardID ~= 0 then
						errorInWindows("csv.item[%s].specialArgsMap %s error", key, v)
					end

					if tagCfg.itemID ~= 0 then
						setData(tagCfg.itemID, tagCfg.chooseItemNum)
					end

					if tagCfg.cardID ~= 0 then
						assertInWindows(tagCfg.chooseItemNum <= 1, "csv.item[%s].specialArgsMap %s error card chooseItemNum > 1", key, v)
						setData("card", {
							id = tagCfg.cardID
						})
					end
				end
			else
				local id, data = csvNext(v)

				setData(id, data)
			end
		end

		desc = string.format(gLanguageCsv.itemDescType, table.concat(t, gLanguageCsv.symbolComma))
	end

	return desc
end

function uiEasy.createItemsToList(parent, list, data, params)
	params = params or {}

	local item = ccui.Layout:create():size(0, 0):hide()

	item:retain()
	parent:onNodeEvent("exit", function()
		if item then
			item:release()

			item = nil
		end
	end)

	local function onAfterBuild(list)
		if params.onAfterBuild then
			params.onAfterBuild(list)
		end

		list:adaptTouchEnabled()
	end

	bind.extend(parent, list, {
		class = "listview",
		props = {
			data = dataEasy.getItemData(data),
			item = item,
			margin = params.margin,
			padding = params.padding,
			dataOrderCmp = params.sortFunc or dataEasy.sortItemCmp,
			onAfterBuild = onAfterBuild,
			itemAction = {
				isAction = false
			},
			onItem = function(list, node, k, v)
				bind.extend(list, node, {
					class = "icon_key",
					props = {
						data = v,
						grayState = v.grayState,
						isDouble = params.isDouble,
						specialKey = params.specialKey,
						noListener = params.noListener,
						isExtra = v.extra,
						onNode = function(panel)
							if params.scale then
								panel:scale(params.scale)
							end

							local bound = panel:box()

							panel:alignCenter(bound)
							node:size(bound)

							if params.onNode then
								params.onNode(panel, v)
							end

							if params.func then
								params.func(panel)
							end
						end
					}
				})
			end
		}
	})
end

function uiEasy.createSimpleCardToList(parent, list, data, params)
	params = params or {}

	local type = params.type or 1
	local item = ccui.Layout:create():size(150, 150):scale(params.itemScale or 1):hide()

	item:retain()
	parent:onNodeEvent("exit", function()
		if item then
			item:release()

			item = nil
		end
	end)

	local function onAfterBuild(list)
		if params.onAfterBuild then
			params.onAfterBuild(list)
		end

		list:adaptTouchEnabled()
	end

	bind.extend(parent, list, {
		class = "listview",
		props = {
			data = data,
			item = item,
			margin = params.margin,
			padding = params.padding,
			onAfterBuild = onAfterBuild,
			itemAction = {
				isAction = false
			},
			onItem = function(list, node, k, v)
				if v ~= 0 then
					local unitCsv = csv.unit[v]

					if params.itemFunc then
						params.itemFunc(k, node)
					end

					ccui.ImageView:create(unitCsv.iconSimple):addTo(node, 2, "icon"):scale(params.scale or 2):xy(node:width() / 2, node:height() / 2)
				elseif type == 1 then
					ccui.ImageView:create("common/icon/icon_empty.png"):addTo(node, 1, "bg"):scale(params.bgScale or 1):xy(node:width() / 2, node:height() / 2)
				end
			end
		}
	})
end

function uiEasy.showDialog(name, params, styles)
	params = params or {}

	local content = params.content

	local function tryOpenRecharge()
		if not gGameUI:goBackInStackUI("city.recharge") then
			gGameUI:stackUI("city.recharge", nil, {
				full = true
			})
		end
	end

	if name == "gold" then
		gGameUI:stackUI("common.gain_gold")
	elseif name == "rmb" then
		gGameUI:showDialog({
			clearFast = true,
			btnType = 2,
			title = gLanguageCsv.rmbNotEnough,
			content = content or gLanguageCsv.noDiamondGoBuy,
			cb = tryOpenRecharge
		}, styles)
	elseif name == "vip" then
		local defaultContent = {
			string.format(gLanguageCsv.commonTodayMax, params.titleName),
			string.format(gLanguageCsv.commonVipIncrease, params.titleName)
		}

		gGameUI:showDialog({
			clearFast = true,
			btnType = 2,
			title = params.titleName,
			content = content or defaultContent,
			cb = tryOpenRecharge,
			btnStr = gLanguageCsv.showVip
		}, styles)
	else
		local cfg = dataEasy.getCfgByKey(name)

		if cfg then
			gGameUI:showTip(content or string.format(gLanguageCsv.coinNotEnough, cfg.name))
		else
			printWarn("uiEasy.showDialog not have:", name)
		end
	end
end

function uiEasy.addTouchOneByOne(node, params)
	node:visible(params.nodeVisible or false)

	local listener = cc.EventListenerTouchOneByOne:create()
	local eventDispatcher = display.director:getEventDispatcher()
	local touchBeganPos = cc.p(0, 0)

	local function transferTouch(event)
		listener:setEnabled(false)
		eventDispatcher:dispatchEvent(event)
		listener:setEnabled(true)
	end

	local function onTouchBegan(touch, event)
		touchBeganPos = touch:getLocation()

		local flag

		if params.beforeBegan then
			flag = params.beforeBegan(touchBeganPos)
		end

		if flag ~= false then
			transferTouch(event)
		end

		if params.began then
			params.began(touchBeganPos)
		end

		return true
	end

	local function onTouchMoved(touch, event)
		local pos = touch:getLocation()
		local dx = pos.x - touchBeganPos.x
		local dy = pos.y - touchBeganPos.y
		local flag

		if params.moved then
			flag = params.moved(pos, dx, dy, transferTouch, event)
		end

		if flag ~= false then
			transferTouch(event)
		end
	end

	local function onTouchEnded(touch, event)
		local pos = touch:getLocation()
		local dx = pos.x - touchBeganPos.x
		local dy = pos.y - touchBeganPos.y
		local flag

		if params.ended then
			flag = params.ended(pos, dx, dy, transferTouch, event)
		end

		if flag ~= false then
			transferTouch(event)
		end

		if params.afterEnded then
			params.afterEnded(pos, dx, dy)
		end
	end

	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
	listener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
	listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
	listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_CANCELLED)
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)

	return listener
end

function uiEasy.addListviewScroll(list, leftBtn, rightBtn, isJump)
	local isVerticality = list:getDirection() == ccui.ScrollViewDir.vertical
	local innerContainer = list:getInnerContainer()

	local function getPercent(isRight)
		local innerSize = innerContainer:getContentSize()
		local listSize = list:getContentSize()
		local x, y = innerContainer:getPosition()
		local startPos, length, d = x, innerSize.width, listSize.width

		if isVerticality then
			startPos, length, d = y, innerSize.height, listSize.height
		end

		local k = isRight and 1 or -1
		local endPos = math.abs(startPos) + k * d

		endPos = math.max(0, endPos)
		endPos = math.min(length, endPos)

		return endPos / (length - d) * 100
	end

	local function jump(isRight)
		local percent = getPercent(isRight)

		percent = math.max(0, percent)
		percent = math.min(100, percent)

		if percent == 0 then
			leftBtn:visible(false)
			rightBtn:visible(true)
		elseif percent == 100 then
			rightBtn:visible(false)
			leftBtn:visible(true)
		else
			leftBtn:visible(true)
			rightBtn:visible(true)
		end

		if isJump then
			if isVerticality then
				list:jumpToPercentVertical(percent)
			else
				list:jumpToPercentHorizontal(percent)
			end
		elseif isVerticality then
			list:scrollToPercentVertical(percent, 0.2, false)
		else
			list:scrollToPercentHorizontal(percent, 0.2, false)
		end
	end

	bind.touch(list, leftBtn, {
		methods = {
			ended = functools.partial(jump, false)
		}
	})
	bind.touch(list, rightBtn, {
		methods = {
			ended = functools.partial(jump, true)
		}
	})
end

function uiEasy.addTabListClipping(list, parent, params)
	params = params or {}

	local mask = params.mask or "common/box/mask_tab.png"

	list:retain()
	list:removeFromParent()

	local size = list:size()
	local rect = params.rect or cc.rect(59, 1, 1, 1)
	local maskS = ccui.Scale9Sprite:create()
	local offsetX = params.offsetX or 0
	local offsetY = params.offsetY or 0

	maskS:initWithFile(rect, mask)
	maskS:size(size):anchorPoint(0, 0):xy(list:x() + offsetX, list:y() + offsetY)
	cc.ClippingNode:create(maskS):setAlphaThreshold(0.1):add(list):addTo(parent, list:z())
	list:release()
end

function uiEasy.setRankIcon(k, rankImg, textRank1, textRank2)
	if k < 4 then
		rankImg:texture(ui.RANK_ICON[k])
		textRank1:hide()
		textRank2:hide()
	elseif k < 11 then
		rankImg:texture(ui.RANK_ICON[4])
		textRank1:text(k)
		textRank2:hide()
	else
		rankImg:hide()
		textRank1:hide()
		textRank2:text(k)
	end
end

function uiEasy.updateUnlockRes(key, item, params)
	params = params or {}

	if params.justRemove then
		item:removeChildByName("_lock_res_")

		return idlereasy.assign(idler.new(true))
	end

	return dataEasy.getListenUnlock(key, function(isUnlock)
		item:removeChildByName("_lock_res_")

		if not isUnlock or params.specialLock == true then
			local size = item:size()
			local defaultPos = cc.p(size.width * 0.5, size.height * 0.5)

			ccui.ImageView:create(params.res or "common/btn/btn_lock1.png"):xy(params.pos or defaultPos):scale(params.scale or 1):addTo(item, params.zOrder or 10, "_lock_res_")
		end
	end)
end

function uiEasy.checkText(text, params, needSpecialChar)
	params = params or {}

	local noBlackList = params.noBlackList or false
	local specialChar = {
		"\"",
		"'",
		"\\",
		"/",
		"#"
	}

	if not needSpecialChar then
		for _, v in pairs(specialChar) do
			if string.find(text, v) then
				gGameUI:showTip(gLanguageCsv.noContainSpecailChar)

				return false
			end
		end
	end

	if text == "" then
		gGameUI:showTip(gLanguageCsv.canNotEmpty)

		return false
	end

	if LOCAL_LANGUAGE == "cn" then
		local numTotal = 0

		for i = 1, #text do
			local b = text:byte(i)

			if b >= 48 and b <= 57 then
				numTotal = numTotal + 1
			end
		end

		if numTotal >= 4 then
			gGameUI:showTip(gLanguageCsv.noContainSpecailChar)

			return false
		end
	end

	if #text > 0 and (string.byte(text, 1) == 32 or string.byte(text, #text) == 32) then
		gGameUI:showTip(gLanguageCsv.hasSpaceBothEnds)

		return false
	end

	if params.name and text == params.name then
		gGameUI:showTip(gLanguageCsv.noChangeName)

		return false
	end

	if not noBlackList and blacklist.findBlacklist(text) then
		gGameUI:showTip(gLanguageCsv.inBlacklist)

		return false
	end

	if params.cost and params.cost > 0 and gGameModel.role:read("rmb") < params.cost then
		uiEasy.showDialog("rmb")

		return false
	end

	return true
end

function uiEasy.setBtnShader(btn, title, state)
	if state == 1 then
		if title then
			text.deleteAllEffect(title)
			text.addEffect(title, {
				color = ui.COLORS.NORMAL.WHITE,
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			})
		end

		btn:setTouchEnabled(true)
		cache.setShader(btn, false, "normal")
	else
		if title then
			text.deleteAllEffect(title)
			text.addEffect(title, {
				color = ui.COLORS.DISABLED.WHITE
			})
		end

		btn:setTouchEnabled(state == 3)
		cache.setShader(btn, false, "hsl_gray")
	end
end

function uiEasy.setBoxEffect(box, scale, cb, offsetX, offsetY)
	local size = box:size()
	local effect = box:get("effect")
	local scale = scale or 1
	local offsetX = offsetX or 0
	local offsetY = offsetY or 0

	if not effect then
		effect = widget.addAnimationByKey(box, "effect/kaixiangguang.skel", "effect", "effect", 10):xy(size.width / 2 + offsetX, size.height / 2 + offsetY):scale(scale)

		effect:setSpriteEventHandler(function(event, eventArgs)
			effect:hide()

			if cb then
				cb()
			end
		end, sp.EventType.ANIMATION_COMPLETE)
	else
		effect:show():play("effect")
	end
end

function uiEasy.setTitleEffect(parent, effectName, params)
	if params and params.mega then
		local anima = widget.addAnimation(parent, "chaojinhua/jiesuan2.skel", "effect", 25)

		anima:y(anima:y() + 450)
		performWithDelay(parent, function()
			anima:play("effect_loop")
		end, 1.1)
	else
		local effect = widget.addAnimationByKey(parent, "level/jiesuanshengli.skel", "effect", effectName, 20)
		local effectBg = widget.addAnimationByKey(parent, "level/jiesuanshengli.skel", "effectBg", "jiesuan_shenglitu", 10)

		effect:setSpriteEventHandler(function(event, eventArgs)
			effect:play(effectName .. "_loop")
			effectBg:play("jiesuan_shenglitu_loop")
		end, sp.EventType.ANIMATION_COMPLETE)
	end
end

function uiEasy.setExecuteSequence(nodes, params)
	if type(nodes) ~= "table" then
		nodes = {
			nodes
		}
	end

	local params = params or {}
	local offx = params.offx or -300
	local time = params.time or 1
	local delayTime = params.delayTime or 0
	local outx = 50
	local pow = cc.clampf(offx / (outx - offx), 0.1, 0.9)

	for _, node in ipairs(nodes) do
		node:hide()
		performWithDelay(node, function()
			node:show()

			local x, y = node:xy()
			local scaleX = node:scaleX()
			local scaleY = node:scaleY()

			node:x(x + offx):scaleX(0)
			transition.executeSequence(node):easeBegin("EaseInOut"):moveTo(time / 2, x + outx, y):moveTo(time / 2, x, y):easeEnd():done()
			transition.executeSequence(node):scaleXTo(time * pow / 2, scaleX):scaleTo(time * (1 - pow) / 2, scaleX * 1.25, scaleY * 1.25):scaleTo(time / 2, scaleX, scaleY):done()
		end, delayTime)
	end
end

function uiEasy.setPrivilegeRichText(privilegeType, parent, txt, pos, isBracket)
	local privilegeNum = dataEasy.getPrivilegeVal(privilegeType)

	if privilegeNum and privilegeNum ~= 0 then
		if string.find(tostring(privilegeNum), ".", 1, true) then
			privilegeNum = privilegeNum * 100 .. "%"
		end

		local str

		if isBracket then
			str = "#C0x5B545B#(" .. string.format(gLanguageCsv.currentPrivilege, txt, tostring(privilegeNum)) .. "#C0x5B545B#)"
		else
			str = string.format(gLanguageCsv.currentPrivilege, txt, tostring(privilegeNum))
		end

		local richText = rich.createByStr(str, 40, nil, nil, cc.p(0, 0.5)):addTo(parent, 10, "privilege"):anchorPoint(cc.p(0, 0.5)):xy(pos):formatText()

		return richText
	end
end

function uiEasy.setCardNum(panel, num, targetNum, quality, noColor)
	local size = panel:size()
	local label = panel:get("num")
	local label1 = panel:get("num1")
	local label2 = panel:get("num2")

	if not targetNum then
		if not num or num == 0 then
			num = ""
		end

		local outlineSize = ui.DEFAULT_OUTLINE_SIZE

		if type(num) ~= "number" then
			num = gLanguageCsv[num] or num
			outlineSize = 3
		end

		if not label then
			label = cc.Label:createWithTTF(num, ui.FONT_PATH, 36):align(cc.p(1, 0), size.width - 30, 12):addTo(panel, 10, "num")

			text.addEffect(label, {
				outline = {
					color = ui.COLORS.QUALITY_OUTLINE[quality],
					size = outlineSize
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
			label1 = cc.Label:createWithTTF(0, ui.FONT_PATH, 36):align(cc.p(1, 0), size.width - 20, 10):addTo(panel, 10, "num1")

			text.addEffect(label1, {
				outline = {
					color = ui.COLORS.QUALITY_OUTLINE[quality]
				}
			})

			label2 = cc.Label:createWithTTF(0, ui.FONT_PATH, 36):align(cc.p(1, 0), size.width - 30, 10):addTo(panel, 10, "num2")

			text.addEffect(label2, {
				outline = {
					color = ui.COLORS.QUALITY_OUTLINE[quality]
				}
			})
		end

		label1:show():text("/" .. mathEasy.getShortNumber(targetNum))
		label2:show():text(mathEasy.getShortNumber(num))

		if not noColor then
			local color = targetNum <= num and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE

			text.addEffect(label2, {
				color = color
			})
		end

		adapt.oneLinePos(label1, label2, nil, "right")

		if label then
			label:hide()
		end
	end
end

function uiEasy.isOpenMystertShop()
	local curTime = time.getTime()
	local mysteryShopLastTime = gGameModel.mystery_shop:read("last_active_time")
	local cfg = csv.mystery_shop_config[1]
	local live = cfg.shop_exist_time
	local delta = mysteryShopLastTime + live - 1 - curTime

	return delta > 0, delta
end

function uiEasy.showMysteryShop()
	local isOpen = uiEasy.isOpenMystertShop()
	local roleLv = gGameModel.role:read("level")
	local mysteryTimes = gGameModel.daily_record:read("mystery_active_times")
	local cfg = csv.mystery_shop_config[1]
	local minLv = cfg.min_level
	local maxTime = cfg.daily_active_times
	local mysteryState = userDefault.getForeverLocalKey("mySteryState", 0)

	if minLv <= roleLv and mysteryTimes < maxTime and isOpen and mysteryState == 0 then
		userDefault.setForeverLocalKey("mySteryState", 1)
		gGameUI:stackUI("city.mystery_shop.show")

		return true
	end

	return false
end

function uiEasy.showActivityBoss()
	local yyhuodongs = gGameModel.role:read("yyhuodongs")
	local yyOpen = gGameModel.role:read("yy_open")
	local huodongId

	for _, id in ipairs(yyOpen) do
		local cfg = csv.yunying.yyhuodong[id]

		if cfg.type == game.YYHUODONG_TYPE_ENUM_TABLE.huoDongBoss then
			huodongId = id

			break
		end
	end

	if yyhuodongs[huodongId] and yyhuodongs[huodongId].info then
		local myBossTimes = yyhuodongs[huodongId].info.huodong_boss_count
		local oldBossTimes = userDefault.getForeverLocalKey("activityBossCount", 0)

		if myBossTimes and myBossTimes ~= oldBossTimes then
			userDefault.setForeverLocalKey("activityBossCount", myBossTimes)
			gGameUI:stackUI("city.activity.activity_boss.show")

			return true
		end
	end

	return false
end

function uiEasy.setBottomMask(list, maskPanel, typ)
	local container = list:getInnerContainer()
	local listWidth = list:size().width
	local isShow = true

	list:onScroll(function(event)
		if typ and typ == "x" then
			local x = container:getPositionX()
			local containerWidth = container:getContentSize().width

			isShow = x > listWidth - containerWidth + 10
		else
			local y = container:getPositionY()

			isShow = math.abs(y) > 10
		end

		maskPanel:get("mask"):visible(isShow)
	end)
end

function uiEasy.addVibrateToNode(view, node, state, tag)
	local steps = {
		{
			t2 = 0.1,
			t1 = 0.1,
			rotation = 7
		},
		{
			t2 = 0.1,
			t1 = 0.1,
			rotation = -5
		},
		{
			t2 = 0.1,
			t1 = 0.1,
			rotation = 3
		},
		{
			t2 = 0.1,
			t1 = 0.1,
			rotation = -2
		},
		{
			t2 = 0.1,
			t1 = 0.1,
			rotation = 1
		}
	}

	tag = tag or node:getName() .. "toRotationScheduleTag"

	if state then
		view:enableSchedule():schedule(function(dt)
			if tolua.isnull(node) then
				view:enableSchedule():unSchedule(tag)

				return
			end

			local seq = transition.executeSequence(node)

			for _, t in pairs(steps) do
				seq:rotateTo(t.t1, t.rotation):delay(t.t2)
			end

			seq:rotateTo(0.1, 0):done()
		end, 2, nil, tag)
	else
		view:enableSchedule():unSchedule(tag)
	end
end

function uiEasy.shareBattleToChat(playRecordID, enemyName, from, crossKey, shareTimesKey)
	if not dataEasy.isChatOpen(gUnlockCsv.battleShare) then
		return
	end

	local battleShareTimes = gGameModel.daily_record:read(shareTimesKey or "battle_share_times")

	if battleShareTimes >= gCommonConfigCsv.shareTimesLimit then
		gGameUI:showTip(gLanguageCsv.shareTimesNotEnough)

		return
	end

	local leftTimes = gCommonConfigCsv.shareTimesLimit - battleShareTimes

	local function cb(chatFrom)
		gGameApp:requestServer("/game/battle/share", function(tb)
			gGameUI:showTip(gLanguageCsv.recordShareSuccess)
			sdk.trackEvent("share_arenawin")
		end, playRecordID, enemyName, from or "arena", crossKey, chatFrom)
	end

	gGameUI:stackUI("common.share_record", nil, nil, {
		shareTimes = battleShareTimes,
		cb = cb
	})
end

local URL_HANDLE = {
	{
		key = "redpack",
		func = function(target, data, key)
			gGameApp:requestServer("/game/union/redpacket/info", function(tb)
				gGameUI:stackUI("city.union.redpack.view", nil, {
					full = true
				}, tb.view, 2)
			end)
		end
	},
	{
		key = "gymLog",
		func = function(target, data, key)
			gGameUI:stackUI("city.adventure.gym_challenge.battle_detail", nil, nil, data)
		end
	},
	{
		key = "reunion",
		func = function(target, data, key)
			local args = data.args or {}

			if not data.isMine then
				local roleLevel = gGameModel.role:read("level") or 0
				local fightingPoint = gGameModel.role:read("top6_fighting_point")
				local id = gGameModel.role:read("id")
				local reunion = gGameModel.role:read("reunion") or {}
				local nowTime = time.getTime()

				gGameApp:requestServer("/game/yy/reunion/record/get", function(tb)
					local reunion_record = tb.view.reunion_record
					local reunionBindHistory = reunion_record.bind_history
					local reunionBindRoleId = reunion_record.bind_role_db_id

					if not itertools.isempty(reunionBindHistory) and itertools.include(reunionBindHistory, id) then
						gGameUI:showTip(gLanguageCsv.reunionWorldChatErr2)
					elseif reunion.info and reunion.info.end_time > nowTime then
						gGameUI:showTip(gLanguageCsv.reunionWorldChatErr4)
					elseif reunion.bind_cd and reunion.bind_cd > nowTime then
						local countDownTime = reunion.bind_cd - nowTime
						local time1 = time.getCutDown(countDownTime)
						local str = string.format(gLanguageCsv.reunionWorldChatErr3, time1.day, time1.hour, time1.min)

						gGameUI:showTip(str)
					elseif not args.end_time or args.end_time < nowTime or reunionBindRoleId then
						gGameUI:showTip(gLanguageCsv.reunionWorldChatErr5)
					elseif roleLevel < gCommonConfigCsv.seniorRoleLevel or fightingPoint < gCommonConfigCsv.seniorRoleFightingPoint or reunion.role_type ~= 0 then
						gGameUI:showTip(gLanguageCsv.reunionWorldChatErr6)
					else
						gGameApp:requestServer("/game/role_info", function(tb)
							gGameUI:showDialog({
								isRich = true,
								btnType = 2,
								content = string.format(gLanguageCsv.reunionBindDialogText, tb.view.name),
								cb = function()
									gGameApp:requestServer("/game/yy/reunion/bind/join", function(tb)
										if tb.view.result then
											jumpEasy.jumpTo("reunion")
											gGameUI:showTip(gLanguageCsv.reunionBindDialogSuccess)
										end
									end, args.yyID, args.roleID, args.end_time)
								end
							})
						end, args.roleID)
					end
				end, args.roleID)
			else
				gGameUI:showTip(gLanguageCsv.reunionWorldChatErr1)
			end
		end
	},
	{
		key = "party",
		func = function(target, data, key)
			data.cb()
		end
	}
}
local URL_HANDLE_ARGS = {
	{
		key = "^role",
		func = function(target, data, key)
			local args = data.args

			if args[key].id ~= gGameModel.role:read("id") then
				local x, y = target:xy()
				local pos = target:getParent():convertToWorldSpace(cc.p(x, y))

				gGameUI:stackUI("city.chat.personal_info", nil, nil, pos, {
					role = args[key]
				})
			end
		end
	},
	{
		key = "^card",
		func = function(target, data, key)
			local args = data.args
			local role = data.role or {}

			gGameApp:requestServerCustom("/game/card_info"):onErrCall(function()
				gGameUI:showTip(gLanguageCsv.cardDoesNotExist)
			end):params(args[key], role.game_key):doit(function(tb)
				gGameUI:stackUI("city.card.info", nil, nil, tb.view)
			end)
		end
	},
	{
		key = "^union",
		func = function(target, data, key)
			local args = data.args

			gGameApp:requestServer("/game/union/find", function(tb)
				gGameUI:stackUI("city.union.join.detail", nil, nil, nil, tb.view[1])
			end, args[key])
		end
	},
	{
		key = "battleID",
		func = function(target, data, key)
			local args = data.args
			local battleID = args[key]
			local url = "/game/pw/playrecord/get"

			if string.find(args.from, "crossArena") then
				url = "/game/cross/arena/playrecord/get"
			elseif string.find(args.from, "onlineFight") then
				url = "/game/cross/online/playrecord/get"
			elseif string.find(args.from, "crossMine") then
				url = "/game/cross/mine/playrecord/get"
			elseif string.find(args.from, "crossSupremacy") then
				url = "/game/cross/supremacy/playrecord/get"
			end

			gGameModel:playRecordBattle(battleID, args.crossKey, url, 2)
		end
	},
	{
		key = "nature_room_id",
		func = function(target, data, key)
			local args = data.args
			local kickNum = gGameModel.role:read("clone_daily_be_kicked_num")

			if not data.isMine then
				if kickNum < 3 then
					gGameApp:requestServer("/game/clone/room/join", function(tb)
						gGameUI:goBackInStackUI("city.view")
						jumpEasy.jumpTo("cloneBattle")
					end, args.nature_room_id)
				else
					gGameUI:showTip(gLanguageCsv.beKickThreeTimesPleaseNext)
				end
			else
				gGameUI:showTip(gLanguageCsv.cloneInviteMyRoom)
			end
		end
	},
	{
		key = "hd_redPacket_idx",
		func = function(target, data, key)
			local args = data.args
			local yyOpen = gGameModel.role:read("yy_open")
			local openYdFlag = false
			local yyType = csv.yunying.yyhuodong[args.yy_id].type

			for _, v in ipairs(yyOpen) do
				if args.yy_id == v then
					openYdFlag = true

					break
				end
			end

			if not openYdFlag then
				gGameUI:showTip(gLanguageCsv.huodongNoOpen)

				return
			end

			local getredPacket = gGameModel.daily_record:read("huodong_redPacket_rob")
			local vipLevel = gGameModel.role:read("vip_level")
			local getVipNum = gVipCsv[vipLevel].huodongRedPacketRob

			if yyType == game.YYHUODONG_TYPE_ENUM_TABLE.huodongCrossRedPacket then
				if data.args.type == 2 then
					getredPacket = gGameModel.daily_record:read("huodong_redPacket_rob2")
					getVipNum = gVipCsv[vipLevel].huodongCrossRedPacketRob2
				else
					getVipNum = gVipCsv[vipLevel].huodongCrossRedPacketRob1
				end
			end

			if getredPacket == getVipNum then
				gGameUI:showTip(gLanguageCsv.redPacketRoleRobLimit)

				return
			end

			local interface = "/game/yy/red/packet/rob"

			if yyType == game.YYHUODONG_TYPE_ENUM_TABLE.huodongCrossRedPacket then
				interface = "/game/yy/cross/red/packet/rob"
			end

			gGameApp:requestServerCustom(interface):onErrCall(function(err)
				if gLanguageCsv[err.err] then
					gGameUI:showTip(gLanguageCsv[err.err])
				end
			end):params(args.hd_redPacket_idx, args.type):doit(function(data)
				gGameUI:stackUI("city.activity.chinese_new_year", nil, nil, args.yy_id, data.view.info, "world")
			end)
		end
	}
}

function uiEasy.setUrlHandler(target, data, key)
	local args = data.args or {}

	target:setOpenUrlHandler(function(key)
		for _, val in ipairs(URL_HANDLE) do
			if string.find(key, val.key) then
				return val.func(target, data, key)
			end
		end

		if not args[key] then
			printWarn("chat url 缺少对应 key(%s) 的数据", tostring(key))

			return
		end

		for _, val in ipairs(URL_HANDLE_ARGS) do
			if string.find(key, val.key) then
				return val.func(target, data, key)
			end
		end

		printWarn("chat url 未知 key(%s) type(%s)", tostring(key), type(key))
	end)
end

function uiEasy.setSkillInfoToItems(items, skillCfgOrId)
	local SKILL_TYPE_TEXT = {
		[0] = gLanguageCsv.normalSkill,
		gLanguageCsv.smallSkills,
		gLanguageCsv.uniqueSkill,
		gLanguageCsv.passiveSkill
	}

	items = items or {}

	local skillCfg = skillCfgOrId

	if type(skillCfgOrId) == "number" then
		skillCfg = csv.skill[skillCfgOrId]
	end

	local natureType = skillCfg.skillNatureType
	local skillType = skillCfg.skillType
	local iconPath = "city/card/system/skill/icon_skill.png"
	local typePath = "city/card/system/skill/icon_skill_text.png"

	if skillType == battle.SkillType.NormalSkill then
		iconPath = ui.SKILL_ICON[natureType]
		typePath = ui.SKILL_TEXT_ICON[natureType]
	end

	if items.icon then
		items.icon:texture(iconPath)
	end

	if items.name then
		items.name:text(skillCfg.skillName)
	end

	if items.type1 then
		items.type1:texture(typePath)
	end

	if items.type2 then
		items.type2:text(SKILL_TYPE_TEXT[skillCfg.skillType2])
	end

	if items.target then
		items.target:text(skillCfg.targetTypeDesc)

		if items.name then
			local len = items.target:width() + items.name:width()
			local max = items.target:x() - items.name:x()

			if max < len then
				adapt.setTextAdaptWithSize(items.name, {
					horizontal = "left",
					vertical = "center",
					maxLine = 2,
					size = cc.size(600, items.name:height() * 2)
				})
			end
		end
	end
end

function uiEasy.getMaxStar(cardId)
	local cards = gGameModel.role:read("cards")
	local star = csv.cards[cardId].star

	for i, v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local cardData = card:read("card_id", "star")

		if cardData.card_id == cardId and star < cardData.star then
			star = cardData.star
		end
	end

	return star
end

function uiEasy.getStarPanel(star, params)
	params = params or {}

	local panel = ccui.Layout:create():size(0, 0):name("starPanel")
	local interval = params.interval or 0
	local dbid = params.dbid
	local num = star > 6 and 6 or star
	local width = 104
	local length = width * num + interval * (num - 1)
	local st = width / 2 - length / 2

	if params.align == "left" then
		st = width / 2
	elseif params.align == "right" then
		st = width / 2 - length
	end

	for i = 1, num do
		local res = i > star - 6 and "common/icon/icon_star.png" or "common/icon/icon_star_z.png"

		if dataEasy.getIsStarAidState(dbid) then
			widget.addAnimationByKey(panel, "starswap/xingji.skel", "effctStar" .. i, "effect_loop", 10):xy(st + (i - 1) * (width + interval), 0):scale(2.5):setCascadeOpacityEnabled(true):opacity(204)
		end

		ccui.ImageView:create(res):xy(st + (i - 1) * (width + interval), 0):addTo(panel)
	end

	return panel
end

function uiEasy.addTextEffect1(textNote)
	text.addEffect(textNote, {
		outline = {
			size = 3,
			color = cc.c4b(255, 84, 0, 255)
		},
		glow = {
			color = cc.c4b(255, 71, 0, 255)
		}
	})
end

function uiEasy.useEditBox(textField, cb)
	if device.platform ~= "ios" and device.platform ~= "windows" then
		return
	end

	local parent = textField:parent()
	local pos = cc.p(textField:xy())
	local sp = cc.Scale9Sprite:create()
	local editBox = cc.EditBox:create(textField:getContentSize(), sp):anchorPoint(textField:anchorPoint()):xy(pos):addTo(parent, textField:z() + 1)

	editBox:registerScriptEditBoxHandler(function(event)
		printInfo("# uiEasy.useEditBox handler event: " .. event)

		if event == "began" then
			editBox:setPosition(pos)
			editBox:setText(textField:getStringValue())
		end

		if event == "changed" then
			textField:setText(editBox:getText())
		end

		if event == "ended" then
			local text = editBox:getText()

			textField:setText(text)
			editBox:setText("")

			if cb then
				cb(text)
			end
		end
	end)

	textField.editBox = editBox
end

function uiEasy.setTeamBuffItem(panel, cardId, flag, unitCfg)
	if not unitCfg then
		local cardCfg = csv.cards[cardId]

		unitCfg = csv.unit[cardCfg.unitID]
	end

	panel:get("attrBg"):show()

	local attrPanel1 = panel:get("attrBg.attr1")
	local attrPanel2 = panel:get("attrBg.attr2")

	attrPanel1:get("img"):texture(ui.ATTR_ICON[unitCfg.natureType])
	attrPanel1:get("bg"):visible(flag == 1)
	attrPanel1:get("bg2"):visible(flag == 2)
	attrPanel1:y(flag == 1 and 45 or 42)
	attrPanel1:scale(flag == 1 and 1 or 0.9)
	attrPanel1:get("img"):scale(flag == 1 and 0.64 or 0.56)

	if unitCfg.natureType2 then
		attrPanel2:show()
		attrPanel2:get("img"):texture(ui.ATTR_ICON[unitCfg.natureType2])
		attrPanel2:get("bg"):visible(flag == 2)
		attrPanel2:get("bg2"):visible(flag == 1)
		attrPanel2:y(flag == 2 and 45 or 42)
		attrPanel2:scale(flag == 2 and 1 or 0.9)
		attrPanel2:get("img"):scale(flag == 2 and 0.64 or 0.56)
	else
		attrPanel2:hide()
	end
end

function uiEasy.showConfirmNature(unitId1, unitId2)
	local csvUnit = csv.unit
	local natureTable1 = {
		csvUnit[unitId1].natureType,
		csvUnit[unitId1].natureType2
	}
	local natureTable2 = {
		csvUnit[unitId2].natureType,
		csvUnit[unitId2].natureType2
	}

	for k = 1, 2 do
		local nature = natureTable1[k]

		if nature and not itertools.include(natureTable2, nature) then
			local content = gLanguageCsv.changeNatureToChangeTeam

			gGameUI:showDialog({
				btnType = 1,
				content = content
			})

			break
		end
	end
end

function uiEasy.storageTo(params)
	local timeScale = params.timeScale or 1
	local targetPos = params.targetPos

	targetPos = targetPos or params.node:parent():convertToWorldSpace(cc.p(params.node:xy()))

	local animationName = params.animationName or "answerGift"
	local panel = params.panel or gGameUI.scene
	local mask = ccui.Layout:create():size(display.sizeInView):addTo(panel, 111, animationName)

	mask:setBackGroundColorType(1)
	mask:setBackGroundColorOpacity(0)

	local img = cc.Sprite:create(params.img or "city/union/answer/daxingxing.png"):alignCenter(display.sizeInView):addTo(mask)
	local plistFile = params.plistFile or "particle/xingxing.plist"
	local aniFile = params.aniFile or "particle/xingxing2.json"
	local particleNode = cc.ParticleSystemQuad:create(plistFile, aniFile)

	particleNode:addTo(mask):scale(4):alignCenter(display.sizeInView)

	local x, y = img:xy()
	local originP = cc.p(x, y)
	local endP = targetPos
	local controlP1 = cc.p(x + (targetPos.x - x) * 2 / 3, y)
	local controlP2 = cc.p(targetPos.x, y + (targetPos.y - y) * 1 / 2)
	local bezierPos = {
		controlP1,
		controlP2,
		endP
	}

	gGameUI:disableTouchDispatch(nil, false)

	local cb

	cb = img:onNodeEvent("exit", function()
		cb:remove()
		gGameUI:disableTouchDispatch(nil, true)
	end)

	img:runAction(transition.sequence({
		cc.RotateTo:create(0.1 / timeScale, 300),
		cc.EaseIn:create(cc.BezierTo:create(1 / timeScale, bezierPos), 3),
		cc.CallFunc:create(function()
			img:removeSelf()
			widget.addAnimationByKey(mask, "union_answer/xingxing_guang.skel", "effect", "effect", 999):xy(endP)
		end)
	}))
	particleNode:runAction(transition.sequence({
		cc.RotateTo:create(0.1 / timeScale, 300),
		cc.EaseIn:create(cc.BezierTo:create(1 / timeScale, bezierPos), 3)
	}))

	return mask
end

function uiEasy.digitRollAction(textNode, start, over, scale, timeScale, hideText)
	if over <= start then
		return
	end

	scale = scale or 1.2

	local timeScale = timeScale or 1
	local curScale = textNode:scale()
	local step = math.modf((over - start) / 10)

	step = step == 0 and 1 or step

	local stepAddScale = (scale - curScale) / 40

	textNode:stopAllActions()
	schedule(textNode, function()
		if start >= over then
			textNode:stopAllActions()
			textNode:runAction(cc.EaseOut:create(cc.ScaleTo:create(0.5, 1), 0.5))
			textNode:text(over)
			hideText:hide()
			performWithDelay(textNode, function()
				textNode:disableEffect()
			end, 0.5)
		else
			curScale = math.min(curScale + stepAddScale, scale)

			textNode:text(start)
			textNode:scale(curScale)

			local size = textNode:size()

			start = start + step
		end
	end, 0.048 / timeScale)
end

function uiEasy.sweepingEffect(node, params)
	local panel = node:getChildByName("_sweepPanel_")

	if panel then
		return
	end

	params = params or {}

	local nodeW = node:width()
	local nodeH = node:height()
	local speedTime = params.speedTime or 1
	local delayTime = params.delayTime or 0.5
	local angle = params.angle or 20
	local scaleX = params.scaleX or 3
	local offx = math.tan(math.rad(angle)) * nodeH
	local panelHeight = nodeH / math.cos(math.rad(angle))
	local startPosx = -100 - offx
	local endPosx = nodeW + 50
	local lightPath = "common/icon/img_light_2.png"
	local lightRect = cc.rect(20, 20, 1, 1)
	local mask = cc.utils:captureNodeSprite(node, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888, 1, 0, 0)

	mask:retain()

	panel = ccui.Layout:create():anchorPoint(0, 0):xy(0, 0):size(node:width(), node:height()):addTo(node, 100, "_sweepPanel_")

	local ClippingPanel = ccui.Layout:create():setClippingEnabled(true):anchorPoint(0, 0):xy(0, 0):size(node:width(), node:height())
	local ClippingNode = cc.ClippingNode:create(mask):setAlphaThreshold(0.05):xy(0, 0):addChild(ClippingPanel, 1, "_ClippingPanel_"):addTo(panel, 1, "_ClippingNode_")
	local light = ccui.Scale9Sprite:create()

	light:initWithFile(lightRect, lightPath)
	light:setSkewX(angle)
	light:height(panelHeight)
	light:setBlendFunc({
		src = GL_DST_COLOR,
		dst = GL_ONE
	})
	light:anchorPoint(0, 0)
	light:xy(startPosx, 0)
	light:scaleX(scaleX)
	light:addTo(ClippingPanel, 1, "_light_")
	mask:release()

	startPosx = startPosx - light:width() * scaleX

	local function setSweepAction(node, startPos, endPos)
		node:xy(startPos[1], startPos[2])

		local animate = cc.Sequence:create(cc.MoveTo:create(speedTime, cc.p(endPos[1], endPos[2])), cc.CallFunc:create(function()
			node:xy(startPos[1], startPos[2])
		end), cc.DelayTime:create(delayTime))
		local action = cc.RepeatForever:create(animate)

		node:runAction(action)
	end

	setSweepAction(light, {
		startPosx,
		0
	}, {
		endPosx,
		0
	})

	local function setBreatheAction(node)
		local animate = cc.Sequence:create(cc.DelayTime:create(speedTime), cc.ScaleTo:create(delayTime / 4, 1.05), cc.ScaleTo:create(delayTime / 4, 0.95), cc.ScaleTo:create(delayTime / 4, 1.01), cc.ScaleTo:create(delayTime / 4, 1))
		local action = cc.RepeatForever:create(animate)

		node:runAction(action)
	end

	setBreatheAction(node)

	local function setImgOutlight(node)
		node:setOpacity(5)

		local animate = cc.Sequence:create(cc.FadeTo:create((speedTime + delayTime) / 4, 50), cc.FadeTo:create((speedTime + delayTime) / 4, 5), cc.FadeTo:create((speedTime + delayTime) / 4, 50), cc.FadeTo:create((speedTime + delayTime) / 4, 5))
		local action = cc.RepeatForever:create(animate)

		node:runAction(action)
	end
end

function uiEasy.goToShop(key, cb)
	if not gGameUI:goBackInStackUI("city.shop") then
		local getUrl = game.SHOP_GET_PROTOL[key] or game.SHOP_GET_PROTOL[1]

		gGameApp:requestServer(getUrl, function(tb)
			if cb then
				cb()
			else
				gGameUI:stackUI("city.shop", nil, {
					full = true
				}, key)
			end
		end)
	end
end

function uiEasy.showHoudongId(panel, yyid, params)
	if not dev.SHOW_HUODONG_ID then
		return
	end

	panel:removeChildByName("_editor_yyid_")
	panel:removeChildByName("_editor_huodongid_")

	if not yyid then
		return
	end

	params = params or {}

	local size = panel:size()
	local label1 = ccui.Text:create("yyid:" .. yyid, "font/youmi1.ttf", 36):opacity(200):align(cc.p(0.5, 0.5), size.width / 2, size.height / 2 + (params.dy1 or 0)):addTo(panel, 999, "_editor_yyid_")

	adapt.setTextScaleWithWidth(label1, nil, params.width or 160)
	text.addEffect(label1, {
		color = ui.COLORS.NORMAL.DEFAULT,
		outline = {
			size = 2,
			color = ui.COLORS.OUTLINE.WHITE
		}
	})

	local yyHdid = gGameModel.role:read("yy_hdid") or {}
	local huodongId = yyHdid[yyid] or csv.yunying.yyhuodong[yyid].huodongID
	local label2 = ccui.Text:create("hdid:" .. huodongId, "font/youmi1.ttf", 36):opacity(200):align(cc.p(0.5, 0.5), size.width / 2, size.height / 2 + (params.dy2 or 0)):addTo(panel, 999, "_editor_huodongid_")

	adapt.setTextScaleWithWidth(label2, nil, params.width or 160)
	text.addEffect(label2, {
		color = ui.COLORS.NORMAL.DEFAULT,
		outline = {
			size = 2,
			color = ui.COLORS.OUTLINE.WHITE
		}
	})
end

function uiEasy.onTownHomeClick(params)
	gGameApp:requestServer("/game/town/society/home/visit", function(tb)
		params.data = tb.view

		gGameUI:stackUI("city.town.home.view", nil, nil, params)
	end, params.serverKey, params.townDBID)
end

function uiEasy.setMaxStar(node, params)
	node:removeChildByName("maxStarBg")
	node:removeChildByName("maxStarText")

	if dataEasy.isUnlock(gUnlockCsv.fragShopMaxStar) then
		local size = node:box()
		local cfg = csv.cards[params.cardId]

		if cfg and dataEasy.getCardMaxStar(cfg.cardMarkID) == 12 then
			params.align = params.align or "right"

			local ratX = params.align == "right" and 0.69 or 0.11
			local ratY = 0.72
			local scale = params.scale or 0.85
			local scaleX = params.align == "right" and scale or -scale
			local x = params.position and params.position.x or math.floor(size.width * ratX) + 8
			local y = params.position and params.position.y or math.floor(size.height * ratY) + 22
			local label = cc.Label:createWithTTF(gLanguageCsv.maxStar, "font/youmi1.ttf", 42):align(cc.p(0.5, 0.5), 0, 0):scale(scale):addTo(node, 101, "maxStarText")
			local maxStarBg = ccui.Scale9Sprite:create()

			maxStarBg:initWithFile(cc.rect(60, 0, 1, 1), "city/shop/logo_shop_sp.png")
			maxStarBg:align(cc.p(0.5, 0.5), x, y):addTo(node, 100, "maxStarBg"):scale(scaleX, scale)
			text.addEffect(label, {
				color = cc.c4b(254, 127, 76, 255)
			})

			local txtSize = label:size()
			local bgWidth = math.min(txtSize.width + 40, 160)

			maxStarBg:width(bgWidth)
			label:scale(bgWidth / (txtSize.width + 40) * scale):xy(maxStarBg:x(), maxStarBg:y() + 7 * scale)
		end
	end
end

local buffIconInfo = {
	function(id, parent, relicBuff, this, effect)
		return {
			offsetY = 230,
			canvasDir = "vertical",
			dir = "top",
			x = effect.x or parent:width() / 2,
			y = effect.y or 150,
			scale = effect.scale or 1,
			type = id,
			countDown = relicBuff[id][1],
			this = this
		}
	end,
	function(id, effect)
		return {
			canvasDir = "horizontal",
			offsetY = 440,
			x = effect.x or 510,
			y = effect.y or 260,
			scale = effect.scale and 0.85 or 1,
			type = id,
			dir = effect.dir or id > 2 and "left" or "right"
		}
	end,
	function(id)
		return {
			x = 960,
			scale = 0.6,
			canvasDir = "vertical",
			dir = "top",
			offsetY = 440,
			y = 400,
			type = id
		}
	end,
	function(id)
		return {
			x = 1100,
			scale = 0.8,
			canvasDir = "vertical",
			dir = "top",
			offsetY = 440,
			y = 260,
			type = id
		}
	end,
	function(id, parent, effect)
		return {
			scale = 0.8,
			canvasDir = "vertical",
			dir = "top",
			offsetY = 440,
			x = effect.x or parent:width() / 2,
			y = effect.y or 120,
			type = id
		}
	end,
	function(id, parent, relicBuff, this)
		return {
			y = 45,
			x = 914,
			offsetY = 440,
			canvasDir = "vertical",
			dir = "top",
			scale = 0.5,
			type = id,
			countDown = relicBuff[id][1],
			this = this
		}
	end
}

function uiEasy.addRelicIcon(parent, relicBuff, id, effect, this)
	effect = effect or {}

	local params

	if relicBuff then
		if id then
			if relicBuff[id] and itertools.size(relicBuff[id]) > 0 then
				if itertools.include({
					game.RELIC_BUFF.ENDLESSTOWER,
					game.RELIC_BUFF.DISPATCH
				}, id) then
					params = buffIconInfo[1](id, parent, relicBuff, this, effect)
				elseif itertools.include({
					game.RELIC_BUFF.GOLD_ECTYPAL,
					game.RELIC_BUFF.EXP_ECTYPAL,
					game.RELIC_BUFF.GIFT_ECTYPAL,
					game.RELIC_BUFF.FRAGMENT_ECTYPAL,
					game.RELIC_BUFF.CONTRACT_ECTYPAL
				}, id) then
					params = buffIconInfo[2](id, effect)
				elseif id == game.RELIC_BUFF.BUY_STAMINA then
					params = buffIconInfo[3](id)
				elseif id == game.RELIC_BUFF.LIANJIN then
					params = buffIconInfo[4](id)
				elseif id == game.RELIC_BUFF.TOWN_DISPATCH then
					params = buffIconInfo[5](id, parent, effect)
				elseif itertools.include({
					game.RELIC_BUFF.TOWN_FELLING,
					game.RELIC_BUFF.TOWN_LIANJIN,
					game.RELIC_BUFF.TOWN_DESSERT_SHOP
				}, id) then
					params = buffIconInfo[6](id, parent, relicBuff, this)
				end
			elseif parent:get("relicPanel") then
				parent:get("relicPanel"):hide()
			end
		else
			params = {
				y = 100,
				action = true,
				canvasDir = "horizontal",
				dir = "down",
				offsetY = -80,
				x = 100
			}
		end

		if params then
			return uiEasy.addRelicIconShwo(parent, params)
		end
	end
end

function uiEasy.addRelicIconShwo(parent, params)
	params.key = "relicBuff"

	local relicPanel = parent:get("relicPanel")

	relicPanel = relicPanel or ccui.Layout:create():size(200, 200):anchorPoint(0.5, 0.5):xy(params.x, params.y):addTo(parent, 100, "relicPanel"):setTouchEnabled(true):scale(params.scale or 1)

	local relicBg = relicPanel:get("relicBg")

	relicBg = relicBg or cc.Sprite:create("common/btn/btn_sz.png"):alignCenter(relicPanel:size()):scale(1.54):addTo(relicPanel, 1, "relicBg")

	if not relicBg:get("relicIcon") then
		cc.Sprite:create("city/town/relic/icon_yjzf.png"):alignCenter(relicBg:size()):addTo(relicBg, 3, "relicIcon"):scale(0.7)
	end

	if params.action then
		relicPanel:stopActionByTag(10021)

		local animate = cc.Sequence:create(cc.MoveBy:create(0.8, cc.p(0, 30)), cc.MoveBy:create(0.8, cc.p(0, -30)))

		animate:setTag(10021)

		local action = cc.RepeatForever:create(animate)

		relicPanel:runAction(action)
	end

	local buffTimeTypes = {
		game.RELIC_BUFF.TOWN_FELLING,
		game.RELIC_BUFF.TOWN_LIANJIN,
		game.RELIC_BUFF.TOWN_DESSERT_SHOP,
		game.RELIC_BUFF.ENDLESSTOWER
	}

	if itertools.include(buffTimeTypes, params.type) then
		local times = relicPanel:get("times")
		local timeTag = params.timeTag or 1

		if not times then
			times = cc.Label:createWithTTF("", ui.FONT_PATH, 30):alignCenter(relicPanel:size()):y(20):addTo(relicPanel, 10, "times"):show()

			text.addEffect(times, {
				outline = {
					size = 4,
					color = cc.c4b(91, 84, 91, 255)
				}
			})
		else
			times:unScheduleAll()
		end

		times:removeAllChildren()

		local cfg = csv.town.relic_buff[params.countDown.buff_id]
		local timeNum = cfg.duration * 60 * 60
		local tt = timeNum + params.countDown.effect_time

		if params.type ~= game.RELIC_BUFF.ENDLESSTOWER then
			times:hide()
		end

		bind.extend(params.this, times, {
			class = "cutdown_label",
			props = {
				endTime = tt + 2,
				tag = timeTag,
				endFunc = function()
					times:unSchedule(timeTag)
					gGameApp:requestServer("/town/relic/buff/refresh", function(tb)
						return
					end)
				end,
				callFunc = function(t)
					times:text(times:text() .. gLanguageCsv.relicAoexpiryDate)
				end
			}
		})
	end

	local buffTimeTypes2 = {
		game.RELIC_BUFF.TOWN_FELLING,
		game.RELIC_BUFF.TOWN_LIANJIN,
		game.RELIC_BUFF.TOWN_DESSERT_SHOP
	}

	if itertools.include(buffTimeTypes2, params.type) then
		local textBg = relicPanel:get("textBg")

		textBg = textBg or ccui.ImageView:create("city/town/map/factory/box_zf.png"):setScale9Enabled(true):setCapInsets(cc.rect(27, 25, 1, 1)):addTo(relicPanel, 10, "textBg"):xy(-480, 100):size(120, 50):scale(2)

		local title = textBg:get("title")

		title = title or cc.Label:createWithTTF(gLanguageCsv.benediction, ui.FONT_PATH, 40):alignCenter(textBg:size()):addTo(textBg, 10, "title")

		local buildings = gGameModel.town:read("buildings")
		local factoryId = params.this.factoryId
		local level = buildings[factoryId].level or 1
		local townFactoryCfg = gTownFactoryCsv[factoryId][level]
		local relicCfg = csv.town.relic_buff[params.countDown.buff_id]
		local efficient = townFactoryCfg.efficient * relicCfg.param
		local addAttr = relicPanel:get("addAttr")

		if not addAttr then
			addAttr = cc.Label:createWithTTF(string.format(gLanguageCsv.omniHora, efficient), ui.FONT_PATH, 40):addTo(relicPanel, 10, "addAttr"):xy(-220, 100):scale(2):color(cc.c4b(252, 100, 58, 255)):anchorPoint(0, 0.5)
		else
			addAttr:text(string.format(gLanguageCsv.omniHora, efficient))
		end

		addAttr:x(-350)
		adapt.oneLinePos(addAttr, relicBg, cc.p(6, 0))
	end

	local function callBackFun(data, node)
		gGameUI:showItemDetail(node, data)
	end

	bind.touch(parent, relicPanel, {
		methods = {
			ended = functools.partial(callBackFun, params, relicPanel)
		}
	})

	return relicPanel
end

function uiEasy.hex2Color(str)
	str = string.sub(str, 3, #str - 1)

	local num = tonumber(str)

	if #str > 8 then
		return cc.c4b(math.floor(num / 65536 % 256), math.floor(num / 256 % 256), num % 256, math.floor(num / 16777216))
	end

	return cc.c3b(math.floor(num / 65536), math.floor(num / 256 % 256), num % 256)
end

function uiEasy.color2hex(color)
	local num = color.r * 65536 + color.g * 256 + color.b
	local count = 6

	if color.a then
		num = num * 16777216
		count = 8
	end

	return string.format("#C0x%0" .. count .. "x#", num)
end

function uiEasy.autoChessDesc(desc, keyWords, params)
	params = params or {}

	local defaultColor = params.defaultColor or "#L100010##LOC0x232121##LOS3##C0xFFFCED#"
	local ret = string.split(desc, "@")

	for i = 2, #ret, 2 do
		if ret[i] == "" then
			ret[i] = "@"
		else
			local tmp = string.split(ret[i], "M0REN")

			ret[i] = params.fromBattle and tmp[1] or tmp[2] or ""
		end
	end

	desc = table.concat(ret)

	if params.env then
		local formulaColor = "#L100010##LOC0x232121##LOS3##C0x21E038#"

		if params.noOutLine then
			formulaColor = "#L10##C0x21E038#"
		end

		formulaColor = params.formulaColor or formulaColor

		local t = string.split(desc, "$")
		local str = ""

		for i = 1, #t do
			if i % 2 == 1 then
				str = str .. defaultColor .. t[i]
			else
				str = str .. formulaColor .. "$" .. t[i] .. "$"
			end
		end

		desc = eval.doMixedFormula(str, params.env)
	else
		desc = defaultColor .. desc
	end

	for _, key in orderCsvPairs(keyWords) do
		if not gAutoChessKeyWordsCsv[key] then
			printError("csv.auto_chess.key_words key[%s] 不存在", key)
		else
			local name = gAutoChessKeyWordsCsv[key].name
			local p, q

			while true do
				p, q = string.find(desc, name, p, true)

				if p == nil then
					break
				end

				local color = uiEasy.color2hex(cc.c4b(unpack(gAutoChessKeyWordsCsv[key].fontColor, 1, 4)))
				local format

				if params.noOutLine then
					format = string.format("%s#L0#%s#L0#%s", color, string.sub(desc, p, q), defaultColor)
				else
					local outlineColor = "#LOC" .. string.sub(uiEasy.color2hex(cc.c4b(unpack(gAutoChessKeyWordsCsv[key].strokeColor, 1, 4))), 3)

					format = string.format("%s#L100010#%s#LOS3#%s#L0#%s", outlineColor, color, string.sub(desc, p, q), defaultColor)
				end

				desc = string.format("%s" .. format .. "%s", string.sub(desc, 1, p - 1), string.sub(desc, q + 1))
				p = p + #format
			end
		end
	end

	return desc
end

function uiEasy.getVipStr(level, short)
	local lv = level or gGameModel.role:read("vip_level")
	local isSupreme = lv >= game.VIP_SUPREME
	local name = isSupreme and "supreme" or "textVIP"
	local title = short and gLanguageCsv[name] or gLanguageCsv[name .. "1"]

	if isSupreme then
		lv = lv - game.VIP_SUPREME + 1
	end

	return {
		str = title .. lv,
		level = lv,
		title = title
	}
end

function uiEasy.skillDesc2str(t, params)
	params = params or {}

	local tmp = {}

	for _, v in ipairs(t) do
		if type(v) == "table" then
			local key, val = csvNext(v)

			if params.defaultColor and key == "title" then
				val = "#C0xFFFCED##D0xCCC6B6##F48##L00100010##LOC0x8C887D##LOS3#" .. val
			end

			table.insert(tmp, val)
		else
			if params.defaultColor then
				v = "#F40##C0x5B545B#" .. v
			end

			table.insert(tmp, v)
		end
	end

	return table.concat(tmp, "\n")
end

local function formatStarDesc(desc, clearTag)
	if not desc then
		return {}
	end

	local newDesc = {}
	local titleDesc

	for idx, val in orderCsvPairs(desc) do
		local str

		if type(val) == "string" then
			str = val
		elseif type(val) == "table" then
			local k, v = csvNext(val)

			titleDesc = v
		end

		if str then
			if clearTag then
				local p, q

				while true do
					local pattern = string.match(str, "#C[^#]+#")

					if pattern == nil then
						break
					end

					p, q = string.find(str, pattern, p, true)
					str = string.sub(str, 1, p - 1) .. string.sub(str, q + 1)
				end
			end

			table.insert(newDesc, str)
		end
	end

	return newDesc, titleDesc
end

local function getStarEveryPartSkillDesc(params, typ, isDetail, idx)
	if not dataEasy.isUnlock(gUnlockCsv.starEffect) then
		return
	end

	local skillCsv = csv.skill[params.skillId]

	idx = idx or 1

	local tmpStar = skillCsv.starEffect[idx]

	if tmpStar then
		local cardCsv = csv.cards[params.cardId]
		local myStar = cardCsv and cardCsv.star or 0

		if params.star then
			myStar = params.star
		end

		local isUnlock = tmpStar <= myStar
		local color = isUnlock and "#C0x5B545B#" or "#C0xB7B09E#"
		local starDesc = skillCsv.starEffectDesc1

		if params.isZawake and csvSize(skillCsv.zawakeStarEffectDesc1) > 0 then
			starDesc = skillCsv.zawakeStarEffectDesc1
		end

		if csvSize(skillCsv.starEffect) > 1 then
			starDesc = starDesc[idx]
		end

		local newDesc, titleDesc = formatStarDesc(starDesc, not isUnlock)
		local starPre = {
			string.format(gLanguageCsv.starUnlockSkillDesc, tmpStar, ""),
			titleDesc
		}

		return newDesc, starPre, color, isUnlock
	end
end

function uiEasy.getStarSkillDesc(params, typ, isDetail)
	if dataEasy.isSkillChange() then
		return uiEasy.getStarSkillDesc1(params, typ, isDetail)
	end

	if not dataEasy.isUnlock(gUnlockCsv.starEffect) then
		return ""
	end

	local skillCsv = csv.skill[params.skillId]
	local cardCsv = csv.cards[params.cardId]
	local myStar = cardCsv and cardCsv.star or 0

	if params.star then
		myStar = params.star
	end

	local starStr = ""

	if skillCsv.starEffect and csvSize(skillCsv.starEffect) > 0 then
		local color = myStar >= skillCsv.starEffect[1] and "#C0x60c456#" or "#C0xB7B09E#"

		if typ == "handbook" then
			color = "#C0xB7B09E#"
		end

		local tmpStar = skillCsv.starEffect[1]

		for _, needStar in orderCsvPairs(skillCsv.starEffect) do
			if needStar <= myStar then
				tmpStar = needStar
			end
		end

		local desc = skillCsv.starEffectDesc

		if isDetail == false and skillCsv.starEffectDescShort ~= "" then
			desc = skillCsv.starEffectDescShort
		end

		if params.isZawake and skillCsv.zawakeEffect[2] == 1 then
			desc = skillCsv.zawakeEffectDesc

			if isDetail == false and skillCsv.zawakeEffectDescShort ~= "" then
				desc = skillCsv.zawakeEffectDescShort
			end
		end

		starStr = "\n\n" .. color .. string.format(gLanguageCsv.starUnlockSkillDesc, tmpStar, eval.doMixedFormula(desc, {
			skillLevel = params.skillLevel or 1,
			math = math
		}, nil))
	end

	return starStr
end

function uiEasy.getStarSkillDesc1(params, typ, isDetail)
	local t = {}

	for idx = 1, math.huge do
		local starDesc, starPre, color = getStarEveryPartSkillDesc(params, typ, isDetail, idx)

		if starDesc then
			local starStr = eval.doMixedFormula(uiEasy.skillDesc2str(starDesc, params), {
				skillLevel = params.skillLevel or 1,
				math = math
			}, nil)

			table.insert(t, "\n\n" .. color .. table.concat(starPre, "  ") .. starStr)
		else
			break
		end
	end

	return table.concat(t)
end

function uiEasy.setSkillDescKeyWords(desc, keyWordsCfg, params)
	for _, key in orderCsvPairs(keyWordsCfg) do
		if not gSkillDescKeyWordsCsv[key] then
			printError("csv.skill_desc_key_words[%s] 不存在", key)
		else
			local keyWords = gSkillDescKeyWordsCsv[key].name

			if keyWords ~= "" then
				local p, q

				while true do
					p, q = string.find(desc, keyWords, p, true)

					if p == nil then
						break
					end

					local color = uiEasy.color2hex(cc.c3b(unpack(gSkillDescKeyWordsCsv[key].fontColor, 1, 3)))
					local format = string.format("%s#L10#%s#L0#%s", color, string.sub(desc, p, q), "#C0x5B545B#")

					if params.linkFunc then
						format = string.format("%s#L10010##LUL%s#%s#L0#%s", color, key, string.sub(desc, p, q), "#C0x5B545B#")
					end

					desc = string.format("%s" .. format .. "%s", string.sub(desc, 1, p - 1), string.sub(desc, q + 1))
					p = p + #format
				end
			end
		end
	end

	return desc
end

function uiEasy.showSkillDesc(list, params, typ, isDetail, skillTb)
	list:removeAllChildren()
	list:setItemsMargin(params.margin or 10)

	local skillCsv = csv.skill[params.skillId]
	local desc = {}
	local size = 1

	if skillTb then
		size = itertools.size(skillTb)
	end

	for i = 1, size do
		if skillTb then
			skillCsv = csv.skill[skillTb[i].skillID]
		end

		if params.descGray and skillCsv.descGray ~= "" then
			table.insert(desc, {
				normal = "#C0xB8B19F#" .. skillCsv.descGray
			})
		end

		local normalDesc = skillCsv.describe1

		if params.isZawake and csvSize(skillCsv.zawakeEffectDesc1) > 0 then
			normalDesc = skillCsv.zawakeEffectDesc1
		end

		local keyWords = skillCsv.keyWords

		if params.isZawake then
			keyWords = skillCsv.zawakeKeyWords
		end

		for _, v in orderCsvPairs(normalDesc) do
			if type(v) == "string" then
				local str = "#C0x5B545B#" .. eval.doMixedFormula(v, {
					skillLevel = params.skillLevel or 1,
					math = math
				})

				str = uiEasy.setSkillDescKeyWords(str, keyWords, params)

				table.insert(desc, str)
			else
				table.insert(desc, v)
			end
		end

		if not params.ignoreStar and csvSize(skillCsv.starEffect) > 0 then
			params.defaultColor = true

			for idx = 1, math.huge do
				local starDesc, starPre, color, isUnlock = getStarEveryPartSkillDesc(params, typ, isDetail, idx)

				if starDesc then
					table.insert(desc, {
						height = 5
					})

					local titleColor = isUnlock and "#C0x60c456#" or color
					local subTitleColor = isUnlock and "#C0x8CB4E4#" or color
					local outLineColor = isUnlock and "#LOC0x5580B4#" or "#LOC0x8C887D#"
					local title = {
						string.format("#C0xFFFCED##D0x%s##F48##L00100010##LOC0x8C887D##LOS3#%s#L0#", string.sub(titleColor, 5, 10), starPre[1])
					}

					if starPre[2] then
						title[2] = string.format("#C0xFFFCED##D0x%s##F48##L00100010#%s#LOS3#%s#L0#", string.sub(subTitleColor, 5, 10), outLineColor, starPre[2])
					end

					table.insert(desc, {
						title = table.concat(title, "  ")
					})

					for _, v in orderCsvPairs(starDesc) do
						if type(v) == "string" then
							local str = color .. eval.doMixedFormula(v, {
								skillLevel = params.skillLevel or 1,
								math = math
							})

							if isUnlock then
								str = uiEasy.setSkillDescKeyWords(str, keyWords, params)
							end

							table.insert(desc, str)
						else
							table.insert(desc, v)
						end
					end
				else
					break
				end
			end
		end
	end

	for idx, val in ipairs(desc) do
		if type(val) == "string" then
			local dx = 10
			local item = ccui.Layout:create():anchorPoint(0, 0):size(list:width(), 0)

			list:pushBackCustomItem(item)

			local img = ccui.ImageView:create("common/box/log_jlq_jn.png")
			local txt = rich.createWithWidth(val, 40, nil, list:width() - img:width() - dx):anchorPoint(0, 1)

			item:height(txt:height())
			img:addTo(item):xy(img:width() / 2, txt:height() - img:height() / 2 - 6)
			txt:addTo(item):xy(img:width() + dx, txt:height())

			if params.linkFunc then
				txt:setOpenUrlHandler(function(key)
					params.linkFunc(key)
				end)
			end
		else
			local txt = val.normal or ""

			if val.title then
				txt = "#C0xFFFCED##D0x8CB4E4##F48##L00100010##LOC0x5580B4##LOS3#" .. val.title
			end

			local item = ccui.Layout:create():anchorPoint(0, 0):size(list:width(), 0)

			list:pushBackCustomItem(item)

			local txt = rich.createWithWidth(txt, 40, nil, list:width()):anchorPoint(0, 0.5):addTo(item):formatText()

			item:height(txt:height() + 10)

			if val.height then
				item:height(val.height)
			end

			txt:y(item:height() / 2)
		end
	end
	list:refreshView()
end

function uiEasy.getArmstexture(node, data)
	if not dataEasy.isUnlock(gUnlockCsv.arms) then
		return
	end

	local data = data or {}
	local armsPanel = node:get("armsPanel")
	local alone = false

	armsPanel = armsPanel or ccui.Layout:create():size(150, 150):anchorPoint(0.5, 0.5):xy(node:size().width / 2, node:size().height / 2):addTo(node, 100, "armsPanel")

	local bg = armsPanel:get("bg")

	bg = bg or ccui.ImageView:create("city/arms/di.png"):addTo(armsPanel, 10, "bg"):xy(armsPanel:width() / 2, armsPanel:height() / 2):scale(1)

	armsPanel:removeChildByName("fistDot")

	local res = "city/arms/none.png"

	if data[1] and data[1] ~= 0 then
		res = string.format("city/arms/icon_%s.png", game.NATURE_TABLE[data[1]])
	elseif data[2] and data[2] ~= 0 then
		res = string.format("city/arms/icon_%s.png", game.NATURE_TABLE[data[2]])
		alone = true
	end

	local fistDot = ccui.ImageView:create(res):xy(117, 117):addTo(armsPanel, 11, "fistDot"):scale(1)

	armsPanel:removeChildByName("secondDot")

	local res = "city/arms/none.png"

	if data[2] and data[2] ~= 0 and not alone then
		res = string.format("city/arms/icon_%s.png", game.NATURE_TABLE[data[2]])
	end

	local secondDot = ccui.ImageView:create(res):xy(33, 33):addTo(armsPanel, 12, "secondDot"):scale(1)
end

function uiEasy.createTexParameters(res, rect, params)
	params = params or {}

	local grid = cc.Sprite:create(res)
	local size = params.size

	if not size then
		size = cc.size(2, 2)

		while size.width < grid:width() do
			size.width = size.width * 2
		end

		while size.height < grid:height() do
			size.height = size.height * 2
		end
	end

	local scale = size.width / grid:width() / (params.scale or 1)
	local gridPanel = ccui.Layout:create():size(size)

	grid:addTo(gridPanel):scale(scale):alignCenter(size)

	local obj = cc.utils:captureNodeSprite(gridPanel, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888, 1, 0, 0)

	obj:getTexture():setTexParameters(gl.LINEAR, gl.LINEAR, gl.REPEAT, gl.REPEAT)

	local width = rect.width * scale

	if params.autoWidth then
		width = size.width

		if tonumber(params.autoWidth) then
			width = width * params.autoWidth
		end
	end

	local height = rect.height * scale

	if params.autoHeight then
		height = size.height

		if tonumber(params.autoHeight) then
			height = height * params.autoHeight
		end
	end

	obj:setTextureRect(cc.rect(rect.x, rect.y, width, height))
	obj:anchorPoint(0.5, 0.5):scale(1 / scale)

	return obj
end

function uiEasy.selectLanguageReload()
	local backupYunying = clone(csv.yunying)

	csv.yunying = nil

	setL10nConfig(csv)

	package.loaded["app.defines.config_defines"] = nil
	package.preload["app.defines.config_defines"] = nil

	require("app.defines.config_defines")

	for k, v in pairs(package.loaded) do
		if string.find(k, "app.views.", nil, true) then
			package.loaded[k] = nil
			package.preload[k] = nil
		end
	end

	setRemoteL10nConfig(backupYunying)

	csv.yunying = backupYunying

	collectgarbage()
end

function uiEasy.createSelectLanguage(params)
	local showLanguage = getShowLanguage()
	local node = ccui.Layout:create():anchorPoint(0.5, 0.5):size(245, 100)
	local langs = {
		en = "English",
		kr = "한어",
		rus = "Россия",
		cn = "简体中文",
		esp = "español",
		tw = "繁體中文",
		idn = "Indonésia",
		vn = "Việt nam"
	}
	local data = {}

	for i, v in ipairs(SHOW_LANGUAGES) do
		data[i] = langs[v]
	end

	local hash = arraytools.hash(SHOW_LANGUAGES, true)

	node:setTouchEnabled(false)
	bind.extend(params.parent, node, {
		class = "sort_menus",
		props = {
			width = 245,
			height = 70,
			maxCount = 6.5,
			btnHeight = 80,
			btnWidth = 270,
			btnType = 2,
			data = idlereasy.new(data),
			showSelected = hash[showLanguage] or 1,
			btnClick = function(node, k, v)
				userDefault.setForeverLocalKey("SHOW_LANGUAGE", SHOW_LANGUAGES[k], {
					rawKey = true
				})
				uiEasy.selectLanguageReload()

				if params.cb then
					params.cb()
				end
			end,
			onNode = function(node)
				node:xy(-1150, -522):z(20)
			end
		}
	})

	return node
end
