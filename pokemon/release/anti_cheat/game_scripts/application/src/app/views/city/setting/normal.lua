-- chunkname: @src.app.views.city.setting.normal

local SettingMainView = require("app.views.city.setting.view")
local BTN_TYPE = SettingMainView.BTN_TYPE
local BTN_DATA = SettingMainView.BTN_DATA
local PAGE_TYPE = {
	base = 1,
	speeder = 3,
	music = 2
}
local STATE = {
	OPEN = 1,
	CLOSE = 2
}
local BIND_GLOW = {
	color = ui.COLORS.NORMAL.WHITE,
	glow = {
		color = ui.COLORS.GLOW.WHITE
	}
}
local pageListData = {
	{
		name = gLanguageCsv.settingFPS,
		select1 = gLanguageCsv.settingFPSSelect1,
		select2 = gLanguageCsv.settingFPSSelect2,
		btnType = BTN_TYPE.RADIO,
		initFunc = function()
			local fps = userDefault.getForeverLocalKey("fps", 60, {
				rawKey = true
			})
			local state = fps <= 30 and STATE.OPEN or STATE.CLOSE

			return state
		end,
		func = function(state)
			local fps = state and 30 or 60

			cc.Director:getInstance():setAnimationInterval(1 / fps)
			userDefault.setForeverLocalKey("fps", fps, {
				rawKey = true
			})
		end
	},
	{
		name = gLanguageCsv.settingScreen,
		select1 = gLanguageCsv.settingScreenSelect1,
		select2 = gLanguageCsv.settingScreenSelect2,
		btnType = BTN_TYPE.RADIO,
		initFunc = function()
			local flag = cc.UserDefault:getInstance():getBoolForKey("isNotchScreen", false)

			return flag and STATE.CLOSE or STATE.OPEN
		end,
		func = function(state)
			local flag = cc.UserDefault:getInstance():getBoolForKey("isNotchScreen", false)

			if flag ~= state then
				return
			end

			gGameUI:sendMessage("adapterNotchScreen", true)

			flag = not state

			cc.UserDefault:getInstance():setBoolForKey("isNotchScreen", flag)

			if flag then
				display.notchSceenSafeArea = display.fullScreenSafeArea
				display.notchSceenDiffX = display.fullScreenDiffX
			else
				display.notchSceenSafeArea = 0
				display.notchSceenDiffX = 0
			end

			gGameUI:sendMessage("adapterNotchScreen", false)
		end
	},
	{
		name = gLanguageCsv.settingVip,
		select1 = gLanguageCsv.settingHide,
		select2 = gLanguageCsv.settingShow,
		btnType = BTN_TYPE.RADIO,
		initFunc = function()
			local vipDisplay = gGameModel.role:read("vip_hide")
			local state = not vipDisplay and STATE.CLOSE or STATE.OPEN

			return state
		end,
		func = function(state)
			local vipDisplay = gGameModel.role:read("vip_hide")

			if vipDisplay ~= state then
				gGameApp:requestServer("/game/role/vip/display/switch", function(tb)
					return
				end, state)
			end
		end
	},
	{
		name = gLanguageCsv.settingBattleSimplify,
		select1 = gLanguageCsv.settingBattleText,
		btnType = BTN_TYPE.BTN,
		needCallBack = function(btnNumber)
			return true
		end,
		initFunc = function(btnNumber, cb)
			local keyName = "buffTextHide"
			local isHide = userDefault.getForeverLocalKey(keyName, false)
			local state = isHide and STATE.OPEN or STATE.CLOSE

			cb(state)
		end,
		func = function(state, btnNumber)
			local keyName = "buffTextHide"

			userDefault.setForeverLocalKey(keyName, state)
		end
	}
}

local function setNodeItem(parent, children, data)
	children.text:text(data.name)
	children.btnPanel1:get("text"):text(data.select1)

	if data.select2 then
		children.btnPanel2:show():get("text"):text(data.select2)
	else
		children.btnPanel2:hide()
	end

	local function setBtnSwitch(panel, btnNumber)
		local dt = BTN_DATA[data.btnType]
		local btn = panel:get("btn")
		local img = btn:get("btnImg")

		btn:texture(dt.resNormal)
		img:texture(dt.resBtnImg)
		img:xy(30, 30)

		local btnState = idler.new()

		btnState:addListener(function(val, oldval)
			local state = val == STATE.OPEN

			btn:texture(state and dt.resSelected or dt.resNormal)

			if state then
				img:xy(100, 30)
			else
				img:xy(30, 30)
			end

			data.func(state, btnNumber)
		end, true)

		if data.needCallBack(btnNumber) then
			data.initFunc(btnNumber, function(state)
				btnState:set(state)
			end)
		else
			local state = data.initFunc()

			btnState:set(state)
		end

		bind.click(parent, panel, {
			method = function()
				local ty = btnState:read() == STATE.OPEN and STATE.CLOSE or STATE.OPEN

				btnState:set(ty)
			end
		})
	end

	local function setBtnRadio(panel1, panel2)
		local dt = BTN_DATA[data.btnType]
		local btn1 = panel1:get("btn")
		local btn2 = panel2:get("btn")

		btn1:texture(dt.resNormal)
		btn1:get("btnImg"):texture(dt.resBtnImg)
		btn2:texture(dt.resNormal)
		btn2:get("btnImg"):texture(dt.resBtnImg)

		local btnState = idler.new()

		btnState:addListener(function(val, oldval)
			local state = val == STATE.OPEN

			btn1:get("btnImg"):visible(state)
			btn2:get("btnImg"):visible(not state)
			data.func(state)
		end, true)
		btnState:set(data.initFunc())

		local function func1()
			btnState:set(STATE.OPEN)
		end

		local function func2()
			btnState:set(STATE.CLOSE)
		end

		bind.click(parent, panel1, {
			method = function()
				btnState:set(STATE.OPEN)
			end
		})
		bind.click(parent, panel2, {
			method = function()
				btnState:set(STATE.CLOSE)
			end
		})
	end

	if data.btnType == BTN_TYPE.RADIO then
		setBtnRadio(children.btnPanel1, children.btnPanel2)
	else
		setBtnSwitch(children.btnPanel1, 1)
		setBtnSwitch(children.btnPanel2, 2)
	end
end

local SettingNormalView = class("SettingNormalView", cc.load("mvc").ViewBase)

SettingNormalView.RESOURCE_FILENAME = "setting_normal.json"
SettingNormalView.RESOURCE_BINDING = {
	["centerPanel.item"] = "listItem",
	versionPanel = "versionPanel",
	["centerPanel.bottomPanel"] = "bottomPanel",
	serverTimePanel = "serverTimePanel",
	centerPanel = "centerPanel",
	btnBase = {
		varname = "btnBase",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onBtnBase")
			}
		}
	},
	btnMusic = {
		varname = "btnMusic",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onBtnMusic")
			}
		}
	},
	btnSpeeder = {
		varname = "btnSpeeder",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("btnTimeSpeeder")
			}
		}
	},
	["centerPanel.btnList"] = {
		varname = "btnList",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("listData"),
				item = bindHelper.self("listItem"),
				margin = bindHelper.self("margin"),
				onItem = function(list, node, k, v)
					local children = node:multiget("text", "btnPanel1", "btnPanel2")

					setNodeItem(list, children, v)
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end
			}
		}
	},
	["centerPanel.bottomPanel.btnService"] = {
		varname = "btnService",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onService")
			}
		}
	},
	["centerPanel.bottomPanel.btnService.text"] = {
		binds = {
			event = "effect",
			data = BIND_GLOW
		}
	},
	["centerPanel.bottomPanel.btnLogOut"] = {
		varname = "btnLogOut",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onLogOut")
			}
		}
	},
	["centerPanel.bottomPanel.btnLogOut.text"] = {
		varname = "btnLogOutText",
		binds = {
			event = "effect",
			data = BIND_GLOW
		}
	},
	["centerPanel.bottomPanel.btnRedeemCode"] = {
		varname = "btnRedeemCode",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onRedeemCode")
			}
		}
	},
	["centerPanel.bottomPanel.btnRedeemCode.text"] = {
		binds = {
			event = "effect",
			data = BIND_GLOW
		}
	},
	["centerPanel.bottomPanel.btnNotice"] = {
		varname = "btnNotice",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onNotice")
			}
		}
	},
	["centerPanel.bottomPanel.btnNotice.text"] = {
		binds = {
			event = "effect",
			data = BIND_GLOW
		}
	},
	["centerPanel.bottomPanel.btnFeedback"] = {
		varname = "btnFeedback",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onFeedback")
			}
		}
	},
	["centerPanel.bottomPanel.btnFeedback.text"] = {
		binds = {
			event = "effect",
			data = BIND_GLOW
		}
	},
	["centerPanel.bottomPanel.btnTcPrivacy"] = {
		varname = "btnTcPrivacy",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onTcPrivacy")
			}
		}
	},
	["centerPanel.bottomPanel.btnTcPrivacy.text"] = {
		binds = {
			event = "effect",
			data = BIND_GLOW
		}
	},
	["centerPanel.bottomPanel.btnTcPermission"] = {
		varname = "btnTcPermission",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onTcPermission")
			}
		}
	},
	["centerPanel.bottomPanel.btnTcPermission.text"] = {
		binds = {
			event = "effect",
			data = BIND_GLOW
		}
	},
	["centerPanel.bottomPanel.btnComments"] = {
		varname = "btnComments",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onGoComments")
			}
		}
	},
	["centerPanel.bottomPanel.btnComments.text"] = {
		binds = {
			event = "effect",
			data = BIND_GLOW
		}
	}
}

function SettingNormalView:onCreate()
	adapt.setTextScaleWithWidth(self.btnMusic:get("text"), nil, 200)

	self.listData = clone(pageListData)

	self.btnService:hide()
	self:judgeTc()
	self:judgeKs()
	self.versionPanel:get("version"):text(APP_VERSION)
	self.btnLogOutText:text(gLanguageCsv.logOutText)
	adapt.oneLinePos(self.versionPanel:get("version"), self.versionPanel:get("text"), nil, "right")
	self:enableSchedule():schedule(function()
		local date = time.getNowDate()

		if TEST_CHANNELS[APP_CHANNEL] then
			self.serverTimePanel:get("time"):text(string.format("%s/%s/%s %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec))
		else
			self.serverTimePanel:get("time"):text(string.format("%02d:%02d:%02d", date.hour, date.min, date.sec))
		end

		adapt.oneLinePos(self.serverTimePanel:get("time"), self.serverTimePanel:get("text"), nil, "right")
	end, 1, 0, 1)

	if not dataEasy.isUnlock(gUnlockCsv.vipDisplaySwitch) then
		self.listData[3] = nil
	end

	if not dataEasy.isUnlock(gUnlockCsv.battleSimplify) then
		self.listData[4] = nil
	end

	local function hideNorchScreen()
		self.listData[2] = nil
	end

	if display.sizeInPixels.width < display.sizeInPixels.height * 2 then
		hideNorchScreen()
	elseif device.platform == "windows" then
		if device.model == "iphone x" then
			hideNorchScreen()
		end
	elseif display.isNotchSceen ~= 1 then
		hideNorchScreen()
	end

	local margin = {
		0,
		50,
		15,
		0
	}

	self.margin = margin[itertools.size(self.listData)]

	local antiCopy = 0

	self.versionPanel:onClick(function()
		antiCopy = antiCopy + 1

		if antiCopy % 10 == 0 then
			gGameUI:showTip("Copyright (c) 2020 HangZhou TianJi Information Technology Inc.")

			local url = dataEasy.getPacketUrl()

			if url then
				cc.Application:getInstance():openURL(url)
			end
		end
	end)
	self:setLoginProtocol()

	self.pageType = idler.new(PAGE_TYPE.base)

	idlereasy.when(self.pageType, function(_, page)
		if not self.subViewMusic then
			self.subViewMusic = gGameUI:createView("city.setting.voice", self:getResourceNode()):init():x(display.uiOrigin.x)

			self.subViewMusic:z(2)
		end

		itertools.invoke({
			self.versionPanel,
			self.serverTimePanel,
			self.centerPanel
		}, page == PAGE_TYPE.base and "show" or "hide")
		self.subViewMusic:visible(page == PAGE_TYPE.music)

		local scheduler = display.director:getScheduler()

		if dataEasy.isUnlock(gUnlockCsv.timeSpeeder) and scheduler.setTimeScale then
			if not self.subViewSpeeder then
				self.subViewSpeeder = gGameUI:createView("city.setting.speeder", self:getResourceNode()):init():x(display.uiOrigin.x)

				self.subViewSpeeder:z(2)
			end

			itertools.invoke({
				self.versionPanel,
				self.serverTimePanel,
				self.centerPanel
			}, page == PAGE_TYPE.base and "show" or "hide")
			self.subViewSpeeder:visible(page == PAGE_TYPE.speeder)
			self.btnSpeeder:show()
		else
			self.btnSpeeder:hide()
		end

		text.deleteAllEffect(self.btnBase:get("text"))
		text.deleteAllEffect(self.btnMusic:get("text"))

		if page == PAGE_TYPE.base then
			text.addEffect(self.btnBase:get("text"), BIND_GLOW)
			text.addEffect(self.btnSpeeder:get("text"), {
				color = ui.COLORS.NORMAL.RED
			})
			text.addEffect(self.btnMusic:get("text"), {
				color = ui.COLORS.NORMAL.RED
			})
			self.btnBase:texture("common/btn/btn_nomal_2.png")
			self.btnMusic:texture("common/btn/btn_nomal_3.png")
			self.btnSpeeder:texture("common/btn/btn_nomal_3.png")
		elseif page == PAGE_TYPE.music then
			text.addEffect(self.btnMusic:get("text"), BIND_GLOW)
			text.addEffect(self.btnSpeeder:get("text"), {
				color = ui.COLORS.NORMAL.RED
			})
			text.addEffect(self.btnBase:get("text"), {
				color = ui.COLORS.NORMAL.RED
			})
			self.btnMusic:texture("common/btn/btn_nomal_2.png")
			self.btnBase:texture("common/btn/btn_nomal_3.png")
			self.btnSpeeder:texture("common/btn/btn_nomal_3.png")
		elseif page == PAGE_TYPE.speeder then
			text.addEffect(self.btnSpeeder:get("text"), BIND_GLOW)
			text.addEffect(self.btnBase:get("text"), {
				color = ui.COLORS.NORMAL.RED
			})
			text.addEffect(self.btnMusic:get("text"), {
				color = ui.COLORS.NORMAL.RED
			})
			self.btnSpeeder:texture("common/btn/btn_nomal_2.png")
			self.btnBase:texture("common/btn/btn_nomal_3.png")
			self.btnMusic:texture("common/btn/btn_nomal_3.png")
		end
	end)

	if matchLanguageForce({
		"en",
		"en_eu"
	}) then
		self.btnFeedback:hide()
	end

	self:createSelectLanguage()
	-- self:addAccountUnbinding()
end

function SettingNormalView:onBtnBase()
	self.pageType:set(PAGE_TYPE.base)
end

function SettingNormalView:onBtnMusic()
	self.pageType:set(PAGE_TYPE.music)
end

function SettingNormalView:btnTimeSpeeder()
	self.pageType:set(PAGE_TYPE.speeder)
end

function SettingNormalView:onService()
	return
end

function SettingNormalView:setLoginProtocol()
	if not APP_TAG:find("_qq") then
		return
	end

	local url = "http://page.kuyangsh.cn/site/privacy?key=08a412053778cad3de9a8fcddb7e21582d3cfda0"
	local str = string.format("#C0xB7B09E##L00010100##LUL%s#隐私政策和用户协议", url)
	local richText = rich.createWithWidth(str, 36, nil, 1000):setAnchorPoint(cc.p(0, 0.5)):addTo(self.bottomPanel, 5, "richText")

	adapt.oneLinePos(self.btnNotice, richText, cc.p(200, 40), "left")
end

function SettingNormalView:onLogOut()
	sdk.logout(function(info)
		print("sdk logout callback", info)
	end)
	sdk.commitRoleInfo(3, function()
		print("sdk commitRoleInfo logout")
	end)
	gGameApp:onBackLogin()
end

function SettingNormalView:onNotice()
	gGameApp:getNotice(function(ret)
		gGameUI:stackUI("login.placard", nil, nil, ret.notice)
	end)
	sdk.trackEvent("check_gameannou")
end

function SettingNormalView:onRedeemCode()
	gGameUI:stackUI("city.setting.redeem_code")
end

function SettingNormalView:onFeedback()
	if matchLanguage({
		"kr"
	}) then
		if APP_TAG:find("as_") then
			local vip = gGameModel.role:read("vip_level")

			sdk.openCustomerService(vip)
		else
			sdk.commitRoleInfo(54, function()
				print("sdk commitRoleInfo customerService")
			end)
		end

		return
	end

	local count = userDefault.getCurrDayKey("feedBackDayCount", 0)

	if count >= gCommonConfigCsv.feedBackDayCount then
		gGameUI:showTip(gLanguageCsv.feedBackTooMany)
	else
		gGameUI:stackUI("city.setting.feed_back")
	end
end

function SettingNormalView:judgeTc()
	local judgeString = APP_TAG

	print("SettingNormalView:APP_TAG is ", judgeString)

	local replaceString = string.gsub(judgeString, "_", " ")
	local words = {}

	for _t in string.gmatch(replaceString, "%w+") do
		words[#words + 1] = _t
	end

	if LOCAL_LANGUAGE == "cn" and words[1] and tonumber(words[3]) and words[1] == "a10054" and tonumber(words[3]) > 20210329 then
		self.btnTcPrivacy:show()
		self.btnTcPermission:show()
	else
		self.btnTcPrivacy:hide()
		self.btnTcPermission:hide()
	end
end

function SettingNormalView:onTcPrivacy()
	sdk.openPrivacyProtocols()
end

function SettingNormalView:onTcPermission()
	sdk.openPermissionSetting()
end

function SettingNormalView:judgeKs()
	if not APP_CHANNEL:find("ks_") then
		return
	end

	local yyOpen = gGameModel.role:read("yy_open")
	local yyId = 0

	for _, id in ipairs(yyOpen) do
		local cfg = csv.yunying.yyhuodong[id]

		if cfg.type == game.YYHUODONG_TYPE_ENUM_TABLE.praise and cfg.paramMap and cfg.paramMap.goodComments then
			yyId = id
			self.award = cfg.paramMap.award

			break
		end
	end

	if yyId == 0 then
		return
	end

	self.yyID = yyId

	local isConfigUrl = false
	local cfg = csv.yunying.praise_tag

	for k, v in csvPairs(cfg) do
		if v.tag == APP_TAG then
			self.commentUrl = v.url
			isConfigUrl = true

			break
		end
	end

	if yyId ~= 0 and isConfigUrl then
		self.btnComments:show()
	else
		self.btnComments:hide()

		return
	end

	idlereasy.when(gGameModel.role:getIdler("yyhuodongs"), function(_, yyhuodongs)
		local huodong = yyhuodongs[yyId]
		local isGet = false

		if huodong and huodong.info and huodong.info[APP_TAG] then
			isGet = true
		end

		local roleLv = gGameModel.role:read("level")
		local btn = self.btnComments
		local label = btn:get("text")

		adapt.setTextAdaptWithSize(label, {
			margin = -10,
			horizontal = "center",
			maxLine = 2,
			vertical = "center",
			size = cc.size(250, 120)
		})

		if isGet then
			if roleLv >= 70 then
				btn:hide()
			else
				btn:show()
				text.deleteAllEffect(label)
				cache.setShader(btn, false, "hsl_gray")
				btn:setTouchEnabled(false)
			end
		else
			cache.setShader(btn, false, "normal")
			text.addEffect(label, {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			})
			btn:setTouchEnabled(true)
		end
	end)
end

function SettingNormalView:onGoComments()
	local v = {
		tag = APP_TAG,
		url = self.commentUrl,
		award = self.award,
		yyID = self.yyID
	}

	gGameUI:stackUI("city.activity.good_comments.view", nil, nil, v)
end

function SettingNormalView:createSelectLanguage()
	if not SHOW_LANGUAGES then
		return
	end

	local node = uiEasy.createSelectLanguage({
		parent = self,
		cb = function()
			gGameUI.rootViewName = nil

			gGameUI:switchUI("city.view")
		end
	})

	node:xy(self:getResourceNode():width() / 2 + 500, 980):addTo(self:getResourceNode(), 999, "showLanguage")
end

-- function SettingNormalView:addAccountUnbinding()
	-- sdk.isShowUnBinding(function(info)
		-- if info == "ok" then
			-- local btn = self.btnService:clone():show():addTo(self.bottomPanel, self.btnService:z(), "unbinding")

			-- btn:get("text"):text("账号解绑")
			-- bind.touch(self, btn, {
				-- methods = {
					-- ended = functools.partial(self.showUnbindingTip)
				-- }
			-- })
		-- end
	-- end)
-- end

-- function SettingNormalView:showUnbindingTip()
	-- local str = "您正在解除当前华为账号和游戏官方账号的关联关系，解绑后无法使用当前华为账号一键登录。"

	-- gGameUI:showDialogModel({
		-- align = "left",
		-- fontSize = 30,
		-- title = "账号解绑",
		-- content = str,
		-- cb = function()
			-- sdk.unBinding(function(info)
				-- if info == "ok" then
					-- sdk.logout(function(info)
						-- gGameApp:onBackLogin()
					-- end)
				-- else
					-- print("sdk unBinding error")
				-- end
			-- end)
		-- end,
		-- dialogParams = {
			-- clickClose = false
		-- }
	-- })
-- end

return SettingNormalView
