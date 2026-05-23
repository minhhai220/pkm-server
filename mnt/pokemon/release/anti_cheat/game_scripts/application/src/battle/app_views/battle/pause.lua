-- chunkname: @src.battle.app_views.battle.pause

local ViewBase = cc.load("mvc").ViewBase
local BattlePauseView = class("BattlePauseView", ViewBase)

local function setScale(view, node)
	node:scale(0.95)
end

local function resumeScale(view, node)
	node:scale(1)
end

BattlePauseView.RESOURCE_FILENAME = "battle_pause.json"
BattlePauseView.RESOURCE_BINDING = {
	text2 = "text2",
	setBtn = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onSetBtnClick")
			}
		}
	},
	backBtn = {
		binds = {
			event = "touch",
			methods = {
				began = setScale,
				ended = bindHelper.self("onBackBtnClick"),
				cancelled = resumeScale
			}
		}
	},
	restartBtn = {
		binds = {
			event = "touch",
			methods = {
				began = setScale,
				ended = bindHelper.self("onRestartBtnClick"),
				cancelled = resumeScale
			}
		}
	},
	continueBtn = {
		binds = {
			event = "touch",
			methods = {
				began = setScale,
				ended = bindHelper.self("onClose"),
				cancelled = resumeScale
			}
		}
	},
	["setBtn.text"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.NORMAL.WHITE
				}
			}
		}
	},
	["backBtn.text"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.NORMAL.WHITE
				}
			}
		}
	},
	["restartBtn.text"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.NORMAL.WHITE
				}
			}
		}
	},
	["continueBtn.text"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.NORMAL.WHITE
				}
			}
		}
	}
}

local btnTb = {
	backBtn = "battleBack",
	setBtn = "battleSet",
	continueBtn = "battleContinue",
	restartBtn = "battleRestart"
}

function BattlePauseView:onCreate(battleView)
	display.director:pause()
	self.text2:ignoreContentAdaptWithSize(false)
	self.text2:setContentSize(cc.size(410, 200))
	self.text2:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
	self.text2:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
	self.text2:getVirtualRenderer():setLineSpacing(-8)

	self.battleView = battleView

	local pnode = self:getResourceNode()

	for btnName, str in pairs(btnTb) do
		local textWgt = pnode:get(btnName .. ".text")

		textWgt:setString(gLanguageCsv[str])
		text.addEffect(textWgt, {
			outline = {
				size = 4,
				color = ui.COLORS.NORMAL.WHITE
			}
		})
	end

	pnode:get("setBtn"):setVisible(false)

	if not battle.PauseNoShowStarConditionsGateType[battleView.gateType] then
		local conditionTb = self.battleView:getPlayModel():getStarConditions()

		if not conditionTb then
			return
		end

		self.conditionTb = conditionTb

		for i = 1, 3 do
			local idx, needNum = conditionTb[i][1], conditionTb[i][2]
			local textNode = pnode:get("text" .. i)

			textNode:setString(string.format(gLanguageCsv["starCondition" .. idx], needNum))
			text.addEffect(textNode, {
				color = ui.COLORS.NORMAL.LIGHT_GREEN
			})

			local countNode = pnode:get("count" .. i)

			countNode:setString(string.format("(%s/%s)", 0, needNum))
			text.addEffect(countNode, {
				color = ui.COLORS.NORMAL.LIGHT_GREEN
			})
		end
	else
		for i = 1, 3 do
			pnode:get("text" .. i):hide()
			pnode:get("count" .. i):hide()
			pnode:get("star" .. i):hide()
		end

		for btnName, str in pairs(btnTb) do
			local btn = pnode:get(btnName)
			local x, y = btn:xy()

			btn:xy(x, y + 300)
		end
	end

	self:showPanel()

	self.timeSpeederLayerVisible = gGameUI.timeSpeederLayer:visible()

	gGameUI.timeSpeederLayer:hide()
end

function BattlePauseView:showPanel()
	if not self.conditionTb then
		return
	end

	local pnode = self:getResourceNode()
	local _, tb = self.battleView:getPlayModel():getGateStar()

	for i = 1, 3 do
		local cond = tb[i][1]
		local num = tb[i][2] or 0
		local needNum = self.conditionTb[i][2]
		local countNode = pnode:get("count" .. i)

		countNode:setString(string.format("(%s/%s)", num, needNum))

		if not cond then
			local textNode = pnode:get("text" .. i)

			text.addEffect(textNode, {
				color = cc.c4b(236, 183, 42, 255)
			})
			text.addEffect(countNode, {
				color = cc.c4b(236, 183, 42, 255)
			})
		end

		pnode:get("star" .. i .. ".achieve"):setVisible(cond)
	end
end

function BattlePauseView:onSetBtnClick()
	return
end

function BattlePauseView:onClose()
	display.director:resume()
	gGameUI.timeSpeederLayer:visible(self.timeSpeederLayerVisible)
	audio.resumeAllSounds()
	ViewBase.onClose(self)
end

function BattlePauseView:onBackBtnClick()
	audio.stopAllSounds()
	display.director:resume()
	gGameUI.timeSpeederLayer:visible(self.timeSpeederLayerVisible)
	gGameUI:switchUI("city.view")
end

local ClientCanReseedRandom = {
	[game.GATE_TYPE.normal] = true,
	[game.GATE_TYPE.endlessTower] = false,
	[game.GATE_TYPE.randomTower] = true,
	[game.GATE_TYPE.hellRandomTower] = true,
	[game.GATE_TYPE.dailyGold] = true,
	[game.GATE_TYPE.dailyExp] = true,
	[game.GATE_TYPE.fragment] = true,
	[game.GATE_TYPE.simpleActivity] = true,
	[game.GATE_TYPE.dailyContract] = true,
	[game.GATE_TYPE.gift] = true,
	[game.GATE_TYPE.unionFuben] = true,
	[game.GATE_TYPE.gym] = true,
	[game.GATE_TYPE.huoDongBoss] = true,
	[game.GATE_TYPE.braveChallenge] = false,
	[game.GATE_TYPE.summerChallenge] = false,
	[game.GATE_TYPE.hunting] = true,
	[game.GATE_TYPE.experience] = true,
	[game.GATE_TYPE.abyssEndlessTower] = false
}

function BattlePauseView:onRestartBtnClick()
	display.director:resume()
	gGameUI.timeSpeederLayer:visible(self.timeSpeederLayerVisible)
	display.director:getScheduler():setTimeScale(1)

	local data = self.battleView.data
	local entrance = self.battleView.entrance

	assert(data and entrance, "data and entrance was nil !")

	if data.play_record_id and data.cross_key and data.record_url then
		gGameModel:playRecordBattle(data.play_record_id, data.cross_key, data.record_url, 0)

		return
	end

	if self.battleView.modes.isRecord then
		battleEntrance.battleRecord(data, {}):show()
	elseif data.randSeed then
		if ClientCanReseedRandom[data.gateType] then
			data.randSeed = math.random(1, 99999999)

			local title = string.format("\n\n\t\tbattle reseed - gate=%s, new_seed=%s, scene=%s\n\n", data.gateType, data.randSeed, data.sceneID)

			printInfo(title)
			log.battle(title)
			gGameUI:switchUI("battle.loading", data, data.sceneID, nil, entrance)
		else
			entrance:restart()
		end
	end
end

return BattlePauseView
