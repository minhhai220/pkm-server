-- chunkname: @src.app.views.city.adventure.gym_challenge.gate

local DIFF_ICON = {
	"city/adventure/exp/icon_jd.png",
	"city/adventure/exp/icon_kn.png",
	"city/adventure/exp/icon_jj.png",
	"city/adventure/exp/icon_ds.png",
	"city/adventure/exp/icon_ly.png",
	"city/adventure/exp/icon_sy.png"
}
local STATE = {
	OVER = 1,
	LOCK = 3,
	UNLOCK = 2
}
local GymGate = class("GymGate", cc.load("mvc").ViewBase)

GymGate.RESOURCE_FILENAME = "gym_gate.json"
GymGate.RESOURCE_BINDING = {
	["panelLeft.imgOwner"] = "imgOwner",
	panelRightDown = "rightDownPanel",
	item = "item",
	["panelLeft.imgBg"] = "leftBg",
	["panelRightDown.attrItem"] = "attrItem",
	panelLeft = "panelLeft",
	["panelLeft.imgBgCircle"] = "imgBgCircle",
	imgFileter = "imgFileter",
	["panelLeft.textNameNPC"] = {
		varname = "textNameNPC",
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c4b(255, 89, 24, 255)
				}
			}
		}
	},
	["panelLeft.textFight"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c4b(90, 84, 91, 255)
				}
			}
		}
	},
	["panelLeft.textName"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c4b(90, 84, 91, 255)
				}
			}
		}
	},
	["panelLeft.textFightNote"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c4b(90, 84, 91, 255)
				}
			}
		}
	},
	["panelLeft.textLv"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c4b(90, 84, 91, 255)
				}
			}
		}
	},
	["panelLeft.btnChallenge"] = {
		varname = "btnOwerChallenge",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onBtnOwnerChallenge")
			}
		}
	},
	["panelLeft.figure"] = {
		varname = "figure",
		binds = {
			class = "role_figure",
			event = "extend",
			props = {
				spine = true,
				data = bindHelper.self("ownerFigure"),
				onNode = function(node)
					return
				end,
				onSpine = function(spine)
					spine:scale(2)
				end
			}
		}
	},
	["panelLeft.textTime"] = {
		varname = "textTime",
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 3,
					color = cc.c4b(207, 207, 207, 255)
				}
			}
		}
	},
	["panelRightDown.btnBuf.textNote"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 3,
					color = cc.c4b(90, 84, 91, 255)
				}
			}
		}
	},
	["panelRightDown.btnBuf"] = {
		binds = {
			{
				event = "touch",
				methods = {
					ended = bindHelper.self("onBtnBuf")
				}
			},
			{
				class = "red_hint",
				event = "extend",
				props = {
					specialTag = "gymBuff",
					listenData = {
						gymDatas = bindHelper.self("gymDatas"),
						round = bindHelper.self("round")
					},
					onNode = function(node)
						node:xy(120, 135)
					end
				}
			}
		}
	},
	["panelRightDown.btnAward.textNote"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 3,
					color = cc.c4b(90, 84, 91, 255)
				}
			}
		}
	},
	["panelRightDown.btnAward"] = {
		binds = {
			{
				event = "touch",
				methods = {
					ended = bindHelper.self("onBtnAward")
				}
			},
			{
				class = "red_hint",
				event = "extend",
				props = {
					specialTag = "gymAward",
					listenData = {
						gymDatas = bindHelper.self("gymDatas"),
						id = bindHelper.self("id")
					},
					onNode = function(node)
						node:xy(120, 120)
					end
				}
			}
		}
	},
	listview = {
		varname = "list",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				asyncPreload = 4,
				data = bindHelper.self("gates"),
				item = bindHelper.self("item"),
				id = bindHelper.self("id"),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				itemAction = {
					isAction = true
				},
				onItem = function(list, node, k, v)
					node:get("imgDiff"):texture(DIFF_ICON[v.diff])

					if v.state == STATE.OVER then
						node:get("imgOver"):show()
						node:get("btnChallenge"):hide()
						node:get("btnChallenge2"):hide()
						node:get("btnPass"):hide()
					elseif v.state == STATE.UNLOCK then
						node:get("imgOver"):hide()

						if v.canPass then
							node:get("btnChallenge"):hide()

							local btnChallenge2 = node:get("btnChallenge2"):show()
							local btnPass = node:get("btnPass"):show()

							uiEasy.setBtnShader(btnChallenge2, btnChallenge2:get("textNote"), 1)
							uiEasy.setBtnShader(btnPass, btnPass:get("textNote"), 1)
						else
							local btnChallenge = node:get("btnChallenge"):show()

							uiEasy.setBtnShader(btnChallenge, btnChallenge:get("textNote"), 1)
							node:get("btnChallenge2"):hide()
							node:get("btnPass"):hide()
						end
					else
						node:get("btnChallenge2"):hide()
						node:get("btnPass"):hide()
						node:get("imgOver"):hide()

						local btnChallenge = node:get("btnChallenge"):show()

						uiEasy.setBtnShader(btnChallenge, btnChallenge:get("textNote"), 2)
					end

					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.clickCell, k, v)
						}
					})
					bind.touch(list, node:get("btnChallenge"), {
						methods = {
							ended = functools.partial(list.clickCell, k, v)
						}
					})
					bind.touch(list, node:get("btnChallenge2"), {
						methods = {
							ended = functools.partial(list.clickCell, k, v)
						}
					})
					bind.touch(list, node:get("btnPass"), {
						methods = {
							ended = functools.partial(list.clickPass, k, v)
						}
					})

					local subList = node:get("subList")

					uiEasy.createItemsToList(list, subList, v.award, {
						margin = 20,
						onNode = function(panel, v)
							if v.key ~= "gold" then
								ccui.ImageView:create("city/adventure/endless_tower/icon_gl.png"):anchorPoint(1, 0.5):xy(panel:width() - 5, panel:height() - 25):addTo(panel, 15)
							end
						end
					})
				end,
				preloadCenterIndex = bindHelper.self("curHardIndex")
			},
			handlers = {
				clickCell = bindHelper.self("onGateDetail"),
				clickPass = bindHelper.self("onGatePass")
			}
		}
	},
	["panelRightDown.arrList"] = {
		varname = "arrList",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("attrData"),
				item = bindHelper.self("attrItem"),
				onItem = function(list, node, k, v)
					node:get("imgIcon"):texture(ui.ATTR_ICON[v])
				end
			}
		}
	}
}

function GymGate:onCreate(id)
	gGameUI.topuiManager:createView("default", self, {
		onClose = self:createHandler("onClose")
	}):init({
		subTitle = "The Pavilion Challenge",
		title = csv.gym.gym[id].name
	})

	self.id = id

	self:initModel()
	self:initUI()
end

function GymGate:initModel()
	self.gates = idlers.newWithMap({})
	self.gymDatas = gGameModel.role:getIdler("gym_datas")
	self.gatesDatas = gGameModel.gym:getIdler("gymGates")
	self.round = gGameModel.gym:getIdler("round")
	self.inCd = idler.new(false)
	self.curHardIndex = 1

	idlereasy.any({
		self.gymDatas,
		self.gatesDatas,
		self.inCd
	}, function(_, gymDatas, gatesDatas, inCd)
		local cfg = csv.gym.gym[self.id]
		local dataCfg = gatesDatas[self.id]
		local gates = {}

		for k, v in orderCsvPairs(cfg.hardDegreeID) do
			local state

			if gymDatas.gym_fuben[self.id] == nil then
				state = STATE.LOCK
			elseif gymDatas.gym_fuben[self.id] == v then
				state = STATE.UNLOCK
			elseif v < gymDatas.gym_fuben[self.id] then
				state = STATE.OVER
			else
				state = STATE.LOCK
			end

			local canPassNode = 0

			if dataEasy.isUnlock(gUnlockCsv.gymPass) then
				local lastJump = gymDatas.last_jump
				local hisJump = gymDatas.history_jump
				local lastJumpNode = lastJump[self.id] or 0
				local hisJumpNode = hisJump[self.id] or 0

				canPassNode = math.max(lastJumpNode, hisJumpNode)
			end

			local gateId = dataCfg[v]

			gates[k] = {
				diff = k,
				state = state,
				award = csv.scene_conf[gateId].dropIds,
				gateId = gateId,
				canPass = v <= canPassNode
			}

			local count = csvSize(csv.gym.gym[self.id].hardDegreeID)
			local maxDegreeID = csv.gym.gym[self.id].hardDegreeID[count]

			if gymDatas.gym_fuben[self.id] == v then
				self.curHardIndex = k + 1
			end

			if maxDegreeID < gymDatas.gym_fuben[self.id] then
				if inCd then
					uiEasy.setBtnShader(self.btnOwerChallenge, self.btnOwerChallenge:get("textNote"), 3)
				else
					uiEasy.setBtnShader(self.btnOwerChallenge, self.btnOwerChallenge:get("textNote"), 1)
				end

				self.ownerUnlock = true
			else
				uiEasy.setBtnShader(self.btnOwerChallenge, self.btnOwerChallenge:get("textNote"), 3)

				self.ownerUnlock = false
			end
		end

		self.gates:update(gates)
	end)

	self.attrData = idlers.newWithMap(csv.gym.gym[self.id].limitAttribute)

	idlereasy.when(self.gymDatas, function(_, data)
		self:initCountDown()
	end)
end

function GymGate:initUI()
	local path = "city/adventure/gym_challenge/gate/"

	self.imgFileter:texture(path .. "bg_" .. csv.gym.gym[self.id].texture):size(display.sizeInView)
	self.imgBgCircle:texture(path .. "icon_" .. csv.gym.gym[self.id].texture)
	self.leftBg:texture(path .. "lighting_" .. csv.gym.gym[self.id].texture)
	self.item:get("imgTexture"):texture(path .. "logo_" .. csv.gym.gym[self.id].texture)
	self.imgBgCircle:runAction(cc.RepeatForever:create(cc.RotateBy:create(90, 360)))
	self:initOwner()

	self.richText = rich.createWithWidth(gLanguageCsv.gymGateDesc, 38, nil, 800, 38):addTo(self.rightDownPanel, 6):setAnchorPoint(0, 0.5):xy(5, 100)
end

function GymGate:initOwner()
	self.gymOwners = gGameModel.gym:getIdler("leaderRoles")
	self.ownerFigure = idler.new(1)

	idlereasy.any({
		self.gymOwners,
		self.round
	}, function(_, _gymOwners, round)
		local gymOwners

		if round == "start" then
			gymOwners = _gymOwners or {}
		else
			gymOwners = gGameModel.gym:read("lastLeaderRoles") or {}
		end

		local data = gymOwners[self.id]

		if gymOwners == nil or gymOwners[self.id] == nil then
			local npcID = csv.gym.gym[self.id].npcID
			local npcCfg = csv.gym.npc[npcID]
			local figureCfg = csv.role_figure[npcCfg.figure]

			self.textNameNPC:text(figureCfg.name):show()
			self.ownerFigure:set(npcCfg.figure)
			nodetools.invoke(self.panelLeft, {
				"textFight",
				"textName",
				"textFightNote",
				"textLv"
			}, "hide")
			self.btnOwerChallenge:show()
			self.imgOwner:texture("city/adventure/gym_challenge/txt_gz.png")
		elseif gGameModel.role:read("id") == data.role_id then
			self.textNameNPC:hide()
			self.ownerFigure:set(gGameModel.role:read("figure"))
			nodetools.invoke(self.panelLeft, {
				"textFight",
				"textName",
				"textFightNote",
				"textLv"
			}, "show")
			self.ownerFigure:set(data.figure)
			self.panelLeft:get("textLv"):text(gLanguageCsv.textLv .. data.level)
			self.panelLeft:get("textFight"):text(data.fighting_point)
			self.panelLeft:get("textName"):text(data.name)
			self.btnOwerChallenge:hide()
			self.textTime:hide()
			self.imgOwner:texture("city/adventure/gym_challenge/txt_rygz.png")
		else
			self.textNameNPC:hide()
			nodetools.invoke(self.panelLeft, {
				"textFight",
				"textName",
				"textFightNote",
				"textLv"
			}, "show")
			self.ownerFigure:set(data.figure)
			self.panelLeft:get("textLv"):text(gLanguageCsv.textLv .. data.level)
			self.panelLeft:get("textFight"):text(data.fighting_point)
			self.panelLeft:get("textName"):text(data.name)
			self.btnOwerChallenge:show()

			local endTime = gGameModel.role:read("gym_datas").gym_pw_last_time + gCommonConfigCsv.gymPwCD

			self.textTime:setVisible(endTime > time.getTime())
			self.imgOwner:texture("city/adventure/gym_challenge/txt_rygz.png")
		end

		bind.touch(self, self.figure, {
			methods = {
				ended = function()
					if gymOwners == nil or gymOwners[self.id] == nil then
						gGameUI:createView("city.adventure.gym_challenge.npc_info", self):init(self.id)
					else
						gGameApp:requestServer("/game/gym/role/info", function(tb)
							local count = csvSize(csv.gym.gym[self.id].hardDegreeID)
							local maxDegreeID = csv.gym.gym[self.id].hardDegreeID[count]
							local unlocked = self.ownerUnlock and maxDegreeID < self.gymDatas:read().gym_fuben[self.id]

							gGameUI:createView("city.adventure.gym_challenge.master_info", self):init(tb.view, self.id, false, unlocked)
						end, gymOwners[self.id].record_id)
					end
				end
			}
		})
	end)
	adapt.oneLineCenterPos(cc.p(443, self.panelLeft:get("textLv"):y()), {
		self.panelLeft:get("textLv"),
		self.panelLeft:get("textName")
	}, cc.p(5, 0))
	adapt.oneLineCenterPos(cc.p(443, self.panelLeft:get("textFightNote"):y()), {
		self.panelLeft:get("textFightNote"),
		self.panelLeft:get("textFight")
	})
end

function GymGate:onGateDetail(list, k, v)
	local canChallenge = v.state == STATE.UNLOCK

	gGameUI:createView("city.adventure.gym_challenge.gate_detail", self):init(v.gateId, k, list.id, canChallenge)
end

function GymGate:onGatePass(list, k, v)
	local buyTimes = gGameModel.daily_record:read("gym_battle_buy_times")

	if gCommonConfigCsv.gymBattleTimes - gGameModel.daily_record:read("gym_battle_times") + buyTimes <= 0 then
		gGameUI:showTip(gLanguageCsv.timesLimit2048)

		return
	end

	gGameApp:requestServer("/game/gym/gate/pass", function(tb)
		gGameUI:showGainDisplay(tb.view.drop)
	end, self.id, v.gateId)
end

function GymGate:onBtnOwnerChallenge()
	if self:getChallengeState() == false then
		gGameUI:showTip(gLanguageCsv.gymTimeOut)

		return
	end

	if not self.ownerUnlock then
		gGameUI:showTip(gLanguageCsv.gymTips1)

		return
	end

	if self.inCd:read() then
		gGameUI:showTip(gLanguageCsv.gymInCd)

		return
	end

	local endTime = gGameModel.role:read("gym_datas").gym_pw_last_time + gCommonConfigCsv.gymPwCD

	if endTime > time.getTime() then
		return
	end

	local natureLimit = csv.gym.gym[self.id].limitAttribute

	if #dataEasy.getNatureSprite(natureLimit) == 0 then
		gGameUI:showTip(gLanguageCsv.gymNoSptire1)

		return
	end

	local gymOwners = self.gymOwners:read()

	if gymOwners == nil or gymOwners[self.id] == nil then
		local npcGates = {}

		for id, cfg in csvPairs(csv.gym.gate) do
			if cfg.npc then
				npcGates[cfg.gymID] = id
			end
		end

		local gateId = npcGates[self.id]
		local deployType = csv.gym.gate[gateId].deployType

		local function fightCb(view, battleCards, extra)
			local data = battleCards:read()

			battleEntrance.battleRequest("/game/gym/gate/start", gateId, self.id, data, extra):onStartOK(function(data)
				view:onClose(false)
			end):show()
		end

		if deployType == 1 then
			local limitInfo = csv.gym.gym[self.id].limitAttribute
			local maxNum = csv.gym.gate[gateId].deployCardNumLimit
			local from = game.EMBATTLE_FROM_TABLE.gymChallenge

			if itertools.size(limitInfo) ~= 0 or maxNum ~= 6 then
				from = game.EMBATTLE_FROM_TABLE.onekey
			end

			gGameUI:stackUI("city.adventure.gym_challenge.embattle1", nil, {
				full = true
			}, {
				isCross = false,
				fightCb = fightCb,
				limitInfo = csv.gym.gym[self.id].limitAttribute,
				gymId = self.id,
				from = from,
				fromId = game.EMBATTLE_GYMCHALLENGE_ID.pve
			})
		elseif deployType == 2 then
			gGameUI:stackUI("city.adventure.gym_challenge.embattle2", nil, {
				full = true
			}, {
				fightCb = fightCb,
				limitInfo = csv.gym.gym[self.id].limitAttribute,
				gymId = self.id
			})
		else
			gGameUI:stackUI("city.adventure.gym_challenge.embattle3", nil, {
				full = true
			}, {
				fightCb = fightCb,
				limitInfo = csv.gym.gym[self.id].limitAttribute,
				gymId = self.id
			})
		end
	else
		local function fightCb(view, battleCards, extra, aidCards)
			local data = battleCards:read()

			battleEntrance.battleRequest("/game/gym/leader/battle/start", data, self.id, gymOwners[self.id].record_id, extra, aidCards:read()):onStartOK(function(data)
				view:onClose()
			end):run():show()
		end

		gGameUI:stackUI("city.adventure.gym_challenge.embattle1", nil, {
			full = true
		}, {
			isCross = false,
			fightCb = fightCb,
			limitInfo = csv.gym.gym[self.id].limitAttribute,
			from = game.EMBATTLE_FROM_TABLE.onekey,
			fromId = game.EMBATTLE_GYMCHALLENGE_ID.pvp
		})
	end
end

function GymGate:onBtnBuf()
	if self:getChallengeState() then
		gGameUI:stackUI("city.adventure.gym_challenge.buff", nil, {
			full = true
		})
	else
		gGameUI:showTip(gLanguageCsv.gymEndTips)
	end
end

function GymGate:onBtnAward()
	local gateAward = {}

	for k, v in pairs(csv.gym.gym[self.id].gateAward) do
		if k ~= "libs" then
			gateAward[k] = v
		end
	end

	local state = 0
	local btnText = ""
	local passAward = self.gymDatas:read().gym_pass_awards or {}
	local cb

	if passAward[self.id] == 0 then
		state = 0
		btnText = gLanguageCsv.received
	elseif passAward[self.id] == 1 then
		state = 1
		btnText = gLanguageCsv.spaceReceive

		function cb()
			gGameApp:requestServer("/game/gym/gate/award", function(tb)
				gGameUI:showGainDisplay(tb)
			end, self.id)
		end
	else
		state = 1
		btnText = gLanguageCsv.commonTextOk
	end

	gGameUI:showBoxDetail({
		clearFast = true,
		data = gateAward or {},
		btnText = btnText,
		content = gLanguageCsv.gymAwardDesc,
		state = state,
		cb = cb
	})
end

function GymGate:getChallengeState()
	if self.round:read() == "closed" then
		return false
	end

	local endStamp = time.getNumTimestamp(gGameModel.gym:read("date"), 21, 45) + 518400

	return endStamp > time.getTime()
end

function GymGate:initCountDown()
	if not self:getChallengeState() then
		self.textTime:text(gLanguageCsv.gymTimeOut)

		return
	end

	if gGameModel.role:read("gym_datas").gym_pw_last_time == 0 then
		self.textTime:hide()

		return
	end

	local function setLabel()
		local endTime = gGameModel.role:read("gym_datas").gym_pw_last_time + gCommonConfigCsv.gymPwCD
		local remainTime = time.getCutDown(endTime - time.getTime())

		self.textTime:text(remainTime.short_date_str .. gLanguageCsv.gymTimeLimit)
		adapt.oneLinePos(self.textTime, self.textNote1, cc.p(5, 0), "right")

		if endTime - time.getTime() <= 0 then
			self.inCd:set(false)
			self.textTime:hide()
			self:unSchedule(1)

			return false
		else
			self.inCd:set(true)

			return true
		end
	end

	self:enableSchedule()
	setLabel()
	self:schedule(function(dt)
		if not setLabel() then
			return false
		end
	end, 1, 0, 1)
end

return GymGate
