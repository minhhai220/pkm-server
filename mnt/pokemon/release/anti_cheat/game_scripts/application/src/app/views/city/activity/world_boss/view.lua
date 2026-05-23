-- chunkname: @src.app.views.city.activity.world_boss.view

local ActivityView = require("app.views.city.activity.view")
local ActivityWorldBossView = class("ActivityWorldBossView", cc.load("mvc").ViewBase)

ActivityWorldBossView.RESOURCE_FILENAME = "activity_world_boss.json"
ActivityWorldBossView.RESOURCE_BINDING = {
	["centerPanel.num"] = "num",
	["centerPanel.num1"] = "num1",
	["centerPanel.countdownBg"] = "countdownBg",
	["rightPanel.timesPanel.times"] = "times",
	["centerPanel.title.txt2"] = "bossAllDamage",
	["centerPanel.title.txt1"] = "bosslevel",
	["centerPanel.title"] = "title",
	centerPanel = "centerPanel",
	["rightPanel.timesPanel.timesLabel"] = "timesLabel",
	["centerPanel.skillItem"] = "skillItem",
	["centerPanel.nameBg.name"] = "bossName",
	["centerPanel.barBg"] = "barBg",
	bgPanel = "bgPanel",
	["leftPanel.rule"] = {
		varname = "ruleBtn",
		binds = {
			event = "touch",
			scaletype = 0,
			methods = {
				ended = bindHelper.self("onRuleClick")
			}
		}
	},
	["leftPanel.rank"] = {
		varname = "rankBtn",
		binds = {
			event = "touch",
			scaletype = 0,
			methods = {
				ended = bindHelper.self("onRankClick")
			}
		}
	},
	["leftPanel.award"] = {
		varname = "awardBtn",
		binds = {
			event = "touch",
			scaletype = 0,
			methods = {
				ended = bindHelper.self("onAwardClick")
			}
		}
	},
	["centerPanel.countdownBg.label"] = {
		varname = "countdownLabel",
		binds = {
			event = "effect",
			data = {
				outline = {
					color = cc.c4b(66, 59, 66, 255)
				}
			}
		}
	},
	["centerPanel.countdownBg.time"] = {
		varname = "countdown",
		binds = {
			event = "effect",
			data = {
				outline = {
					color = cc.c4b(66, 59, 66, 255)
				}
			}
		}
	},
	["centerPanel.skillList"] = {
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("skillDatas"),
				item = bindHelper.self("skillItem"),
				onItem = function(list, node, k, v)
					if v.skillId == 0 then
						node:get("icon"):hide()
						node:get("frame"):hide()
					else
						node:get("icon"):show():texture(v.icon)
						node:get("frame"):show()
						bind.touch(list, node, {
							methods = {
								ended = functools.partial(list.clickCell, node, v)
							}
						})
					end
				end
			},
			handlers = {
				clickCell = bindHelper.self("onSkillClick")
			}
		}
	},
	["centerPanel.bar"] = {
		varname = "bar",
		binds = {
			class = "loadingbar",
			event = "extend",
			props = {
				maskImg = "activity/world_boss/main/jdt_1.png",
				data = bindHelper.self("barPoint")
			}
		}
	},
	["centerPanel.title.txt"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 3,
					color = cc.c4b(254, 253, 236, 255)
				}
			}
		}
	},
	["centerPanel.gift"] = {
		varname = "gift",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onBoxClick")
			}
		}
	},
	["rightPanel.startBtn"] = {
		binds = {
			event = "touch",
			scaletype = 0,
			methods = {
				ended = bindHelper.self("onStartClick")
			}
		}
	},
	["rightPanel.timesBuyBtn"] = {
		binds = {
			event = "touch",
			scaletype = 0,
			methods = {
				ended = bindHelper.self("onTimesBuyClick")
			}
		}
	}
}

function ActivityWorldBossView:onCreate(activityID, data)
	gGameUI.topuiManager:createView("default", self, {
		onClose = self:createHandler("onClose")
	}):init({
		subTitle = "WORLD BOSS",
		title = gLanguageCsv.worldBoss
	})
	self:initModel()
	widget.addAnimationByKey(self.bgPanel, "worldboss/shijiebossbeijing.skel", "effect", "effect_loop", 1):xy(1560, 720):scale(2)
	self.ruleBtn:xy(125, 398)
	self.rankBtn:xy(185, 254)
	self.awardBtn:xy(235, 104)

	self.activityID = activityID

	local yyCfg = csv.yunying.yyhuodong[activityID]
	local baseCfg

	for _, v in orderCsvPairs(csv.world_boss.base) do
		if v.huodongID == yyCfg.huodongID then
			baseCfg = v

			break
		end
	end

	self.baseCfg = baseCfg
	self.level = data.view.bossLevel

	self.bosslevel:text(self.level)
	self.bossAllDamage:text(gLanguageCsv.worldBossServerDamageTip)

	self.barPoint = idler.new(0)

	local hip = csv.world_boss.hp_fix[self.level]
	local hp_fix = hip.hpFix / 100

	self.bossHp = math.floor(baseCfg.baseHP * hp_fix)

	text.addEffect(self.num, {
		outline = {
			size = 2,
			color = cc.c4b(254, 253, 236, 255)
		}
	})
	text.addEffect(self.num1, {
		outline = {
			size = 2,
			color = cc.c4b(209, 128, 0, 255)
		}
	})
	text.addEffect(self.bosslevel, {
		outline = {
			size = 3,
			color = cc.c4b(254, 253, 236, 255)
		}
	})

	local unitCfg = csv.unit[baseCfg.bossID]

	self.bossName:text(unitCfg.name)

	local cardSprite = widget.addAnimation(self.centerPanel, unitCfg.unitRes, "standby_loop", 0):scale(unitCfg.scale * 2 * baseCfg.bossScale):xy(960 + (baseCfg.bossPos.x or 0), 500 + (baseCfg.bossPos.y or 0))

	cardSprite:setSkin(unitCfg.skin)

	self.skillDatas = {}

	for i, v in ipairs(unitCfg.skillList) do
		self.skillDatas[i] = {
			skillId = v,
			icon = baseCfg.skillIcon[i]
		}
	end

	for i = #self.skillDatas + 1, 4 do
		self.skillDatas[i] = {
			skillId = 0
		}
	end

	self.leftTimes = idlereasy.any({
		self.bossGatePlay,
		self.bossGateBuy
	}, function(_, play, buy)
		local freeTimes = yyCfg.paramMap.freeCount
		local leftTimes = freeTimes + buy - play

		self.times:text(string.format("%d/%d", leftTimes, freeTimes))

		return true, leftTimes
	end)

	ActivityView.setCountdown(self, activityID, self.countdownLabel, self.countdown, {
		labelChangeCb = function()
			adapt.oneLineCenterPos(cc.p(210, 50), {
				self.countdownLabel,
				self.countdown
			}, cc.p(15, 0))
		end
	})
	self.gift:texture(baseCfg.serverTargetRes)

	local delay = self.damageSum and 0 or 10

	self.damageSum = self.damageSum or data.view.damageSum

	self:refreshDamage()

	local lastSocketTime = socket.gettime()

	self:scheduleUpdate(function()
		if socket.gettime() - lastSocketTime > delay then
			gGameApp:requestServer("/game/yy/world/boss/main", function(tb)
				self.damageSum = tb.view.damageSum

				self:refreshDamage()
			end, activityID)

			lastSocketTime = socket.gettime()
			delay = 10
		end
	end)
	adapt.oneLinePos(self.title:get("txt"), {
		self.bosslevel,
		self.bossAllDamage
	}, cc.p(10, 0), "left")
	adapt.oneLinePos(self.bosslevel, self.bossAllDamage, cc.p(36, 0), "left")

	local sw = self.bosslevel:size().width

	self.title:size(self.title:size().width + sw, self.title:size().height)
end

function ActivityWorldBossView:refreshDamage()
	local damageSum = self.damageSum or 0

	self.num:text(mathEasy.getShortNumber(damageSum, 2))
	self.num1:text("/" .. mathEasy.getShortNumber(self.bossHp, 2))
	adapt.oneLineCenterPos(cc.p(903, 410), {
		self.num,
		self.num1
	}, cc.p(10, 0))

	if damageSum >= self.bossHp then
		damageSum = self.bossHp

		widget.addAnimationByKey(self.gift, "effect/jiedianjiangli.skel", "rewardEffect", "effect_loop", -1):xy(85, 50):scale(0.45)
	end

	self.barPoint:set(damageSum / self.bossHp * 100)
end

function ActivityWorldBossView:initModel()
	self.bossGatePlay = gGameModel.daily_record:getIdler("boss_gate")
	self.bossGateBuy = gGameModel.daily_record:getIdler("boss_gate_buy")
	self.vip = gGameModel.role:getIdler("vip_level")
end

function ActivityWorldBossView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {
		width = 1500
	})
end

function ActivityWorldBossView:onAwardClick()
	gGameUI:stackUI("city.activity.world_boss.reward", nil, nil, self.activityID)
end

function ActivityWorldBossView:onRankClick()
	gGameApp:requestServer("/game/yy/world/boss/rank", function(tb)
		gGameUI:stackUI("city.activity.world_boss.rank", nil, nil, self.activityID, tb.view)
	end)
end

function ActivityWorldBossView:onStartClick()
	if self.leftTimes:read() > 0 then
		gGameUI:stackUI("city.card.embattle.base", nil, {
			full = true
		}, {
			fightCb = self:createHandler("startFighting"),
			from = game.EMBATTLE_FROM_TABLE.huodong,
			fromId = game.EMBATTLE_HOUDONG_ID.worldBoss
		})
	else
		self:onTimesBuyClick(gLanguageCsv.yyWorldBossCountLimit)
	end
end

function ActivityWorldBossView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(143),
		c.noteText(85001, 85099)
	}

	return context
end

function ActivityWorldBossView:onTimesBuyClick(tip)
	local buyLimit = gVipCsv[self.vip:read()].bossTimeBuyLimit
	local buy = self.bossGateBuy:read()

	if buyLimit <= buy then
		if type(tip) ~= "string" then
			tip = gLanguageCsv.yyWorldBossBuyMax
		end

		gGameUI:showTip(tip)

		return
	end

	local costSeq = gCostCsv.world_boss_buy_cost
	local num = math.min(buy + 1, table.length(costSeq))

	local function showPassView()
		if gGameModel.role:read("rmb") < costSeq[num] then
			uiEasy.showDialog("rmb")
		else
			gGameApp:requestServer("/game/yy/world/boss/buy")
		end
	end

	gGameUI:showDialog({
		isRich = true,
		clearFast = true,
		btnType = 2,
		cb = showPassView,
		title = gLanguageCsv.spaceTips,
		content = string.format(gLanguageCsv.worldBossBuyTip, costSeq[num]),
		dialogParams = {
			clickClose = false
		}
	})
end

function ActivityWorldBossView:onSkillClick(list, node, v)
	if v.skillId == 0 then
		return
	end

	local view = gGameUI:stackUI("common.skill_detail", nil, {
		clickClose = true,
		dispatchNodes = list
	}, {
		ignoreStar = true,
		hideSkillLevel = false,
		skillLevel = self.level,
		skillId = v.skillId,
		skillIcon = v.icon
	})

	if not dataEasy.isSkillChange() then
		local panel = view:getResourceNode()
		local x, y = panel:xy()

		panel:xy(x + node:x() + 65, view.panel:y() - 25)
	end
end

function ActivityWorldBossView:startFighting(view, battleCards, extra, aidCards)
	self:disableSchedule()
	battleEntrance.battleRequest("/game/yy/world/boss/start", battleCards, self.activityID, extra, aidCards):onStartOK(function(data)
		data.activityID = self.activityID

		if view then
			view:onClose(false)

			view = nil
		end
	end):show()
end

function ActivityWorldBossView:onBoxClick(list)
	gGameUI:showBoxDetail({
		state = 1,
		data = self.baseCfg.serverTargetAward,
		content = string.format(gLanguageCsv.allDamageGet, time.getRefreshHour())
	})
end

return ActivityWorldBossView
