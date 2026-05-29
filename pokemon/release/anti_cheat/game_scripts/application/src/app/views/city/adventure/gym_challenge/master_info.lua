-- chunkname: @src.app.views.city.adventure.gym_challenge.master_info

local GymMasterInfoView = class("GymMasterInfoView", Dialog)

GymMasterInfoView.RESOURCE_FILENAME = "gym_master_info.json"
GymMasterInfoView.RESOURCE_BINDING = {
	["top.textUnion"] = "textUnion",
	["top.textName"] = "textName",
	["top.imgVipInfo"] = "imgVipInfo",
	["top.textServer"] = "textServer",
	aidPanel = "aidPanel",
	["top.textNoteServer"] = "textNoteServer",
	["top.textUnionNote"] = "textUnionNote",
	["top.textFightPoint"] = "textFightPoint",
	down = "down",
	imgBG = "bg",
	["down.list"] = {
		varname = "battleArrayList",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				margin = 65,
				data = bindHelper.self("battleData"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							rarity = v.rarity,
							star = v.star,
							dbid = v.id,
							levelProps = {
								data = v.level
							},
							onNode = function(node)
								node:scale(1.2)
								node:xy(-10, -30)
							end
						}
					})
				end
			}
		}
	},
	["top.head"] = {
		varname = "headImg",
		binds = {
			class = "role_logo",
			event = "extend",
			props = {
				level = false,
				vip = false,
				logoId = bindHelper.self("logoId"),
				frameId = bindHelper.self("frameId"),
				onNode = function(node)
					node:scale(1.1)
				end
			}
		}
	},
	["top.textLevel1"] = {
		varname = "textLevel1",
		binds = {
			{
				event = "effect",
				data = {
					outline = {
						size = 4,
						color = cc.c3b(91, 84, 91)
					}
				}
			}
		}
	},
	["top.textLevel2"] = {
		varname = "textLevel2",
		binds = {
			{
				event = "effect",
				data = {
					outline = {
						size = 4,
						color = cc.c3b(91, 84, 91)
					}
				}
			},
			{
				event = "text",
				idler = bindHelper.self("levelId")
			}
		}
	},
	["top.btnTake"] = {
		varname = "btnChat",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onPrivateChat")
			}
		}
	},
	["top.btnTake.textNote"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["top.btnChallenge.textNote"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["top.btnChallenge"] = {
		varname = "btnChallenge",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onChallenge")
			}
		}
	},
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	}
}

function GymMasterInfoView:onCreate(masterData, id, isCross, unlocked, pos)
	self.masterData = masterData
	self.friendMessage = gGameModel.messages:getIdler("private")

	self.textName:text(masterData.role_name)

	self.logoId = idler.new(masterData.role_logo)
	self.frameId = idler.new(masterData.role_frame)
	self.levelId = idler.new(masterData.role_level)

	if masterData.role_vip == 0 then
		self.imgVipInfo:hide()
	else
		self.imgVipInfo:texture("common/icon/vip/icon_vip" .. masterData.role_vip .. ".png")
	end

	self.isCross = isCross
	self.unlocked = unlocked
	self.id = id
	self.pos = pos

	if isCross == true then
		self.textUnionNote:hide()
		self.textUnion:hide()
		self.textNoteServer:show()
		self.textServer:text(getServerArea(masterData.game_key, true))
		self.textServer:show()
		self.btnChat:hide()
		self.btnChallenge:y(self.btnChat:y())
	else
		self.textUnionNote:show()
		self.textUnion:text(masterData.union_name)
		self.textUnion:show()
		self.textNoteServer:hide()
		self.textServer:hide()
	end

	local a = gGameModel.role:read("gym_record_db_id")
	local b = self.masterData.id

	if self.masterData.id == gGameModel.role:read("gym_record_db_id") then
		self.btnChallenge:hide()
		self.btnChat:hide()
	end

	if not unlocked then
		uiEasy.setBtnShader(self.btnChallenge, self.btnChallenge:get("textNote"), 2)
	end

	adapt.oneLinePos(self.textLevel1, self.textLevel2, cc.p(-5, 0))
	adapt.oneLinePos(self.textName, self.imgVipInfo, cc.p(10, 0))
	self:initAidPanel()
	self:initSprites(masterData)
	Dialog.onCreate(self)
end

function GymMasterInfoView:initSprites(masterData)
	self.item = ccui.Layout:create():size(180, 180):show():setTouchEnabled(false):retain():scale(0.8)

	local t = {}
	local fighting = 0
	local cardAttrs = {}
	local cards = {}

	if self.isCross then
		cards = masterData.cross_cards
		cardAttrs = masterData.cross_card_attrs
	else
		cards = masterData.cards
		cardAttrs = masterData.card_attrs
	end

	for i, v in pairs(cards) do
		local cardInfo = cardAttrs[v]

		if cardInfo then
			local cardCsv = csv.cards[cardInfo.card_id == 0 and 11 or cardInfo.card_id]
			local unitCsv = csv.unit[cardCsv.unitID]
			local unitId = dataEasy.getUnitId(cardInfo.card_id, cardInfo.skin_id)

			table.insert(t, {
				cardId = cardInfo.card_id == 0 and 11 or cardInfo.card_id,
				advance = cardInfo.advance,
				unitId = unitId,
				star = cardInfo.star,
				level = cardInfo.level,
				rarity = unitCsv.rarity,
				id = cardInfo.id
			})

			fighting = fighting + cardInfo.fighting_point
		end
	end

	if #t < 6 then
		local num = #t

		for i = num + 1, 6 do
			table.insert(t, {
				unitId = -1
			})
		end
	end

	self.battleData = idlertable.new(t)

	self.textFightPoint:text(fighting + self.aidFightingPoint)
end

function GymMasterInfoView:initAidPanel()
	self.aidFightingPoint = 0

	if not self.isCross then
		return
	end

	local aidNum = dataEasy.getAidNum(game.GATE_TYPE.crossGym, nil, self.masterData.role_level)

	if aidNum == 0 then
		return
	end

	self.aidPanel:show()
	self.down:get("textNote"):hide()
	self.battleArrayList:xy(self.battleArrayList:x() + 50, self.battleArrayList:y() + 78)
	self.bg:height(839):y(self.bg:y() - 33)

	local unitIDs = {}
	local cardAttrs = {}
	local cards = {}

	if self.isCross then
		cards = self.masterData.cross_aid_cards
		cardAttrs = self.masterData.cross_card_attrs
	else
		cards = {}
		cardAttrs = {}
	end

	for k = 1, aidNum do
		local cardInfo = cardAttrs[cards[k]]

		unitIDs[k] = cardInfo and dataEasy.getUnitId(cardInfo.card_id, cardInfo.skin_id) or 0

		if cardInfo then
			self.aidFightingPoint = self.aidFightingPoint + (cardInfo.aid_fighting_point or 0)
		end
	end

	uiEasy.createSimpleCardToList(self, self.aidPanel:get("listView"), unitIDs, {
		scale = 1.5,
		bgScale = 0.9,
		margin = 60
	})
end

function GymMasterInfoView:onPrivateChat()
	local data = {
		isMine = false,
		role = {
			level = self.masterData.role_level,
			id = self.masterData.role_id,
			logo = self.masterData.role_logo,
			name = self.masterData.role_name,
			vip = self.masterData.role_vip,
			frame = self.masterData.role_frame
		}
	}

	gGameUI:stackUI("city.chat.privataly", nil, nil, data)
end

function GymMasterInfoView:onChallenge()
	if self:getChallengeState() == false then
		gGameUI:showTip(gLanguageCsv.gymTimeOut)

		return
	end

	if self.isCross then
		local endTime = gGameModel.role:read("gym_datas").cross_gym_pw_last_time + gCommonConfigCsv.gymPwCD

		if endTime > time.getTime() then
			gGameUI:showTip(gLanguageCsv.gymInCd)

			return
		end
	else
		local endTime = gGameModel.role:read("gym_datas").gym_pw_last_time + gCommonConfigCsv.gymPwCD

		if endTime > time.getTime() then
			gGameUI:showTip(gLanguageCsv.gymInCd)

			return
		end
	end

	if not self.unlocked then
		if self.isCross then
			gGameUI:showTip(gLanguageCsv.gymCrossTips1)
		else
			gGameUI:showTip(gLanguageCsv.gymTips1)
		end

		return
	end

	local natureLimit = csv.gym.gym[self.id].limitAttribute

	if #dataEasy.getNatureSprite(natureLimit) == 0 then
		gGameUI:showTip(gLanguageCsv.gymNoSptire1)

		return
	end

	local id = self.id
	local pos = self.pos
	local masterData = self.masterData
	local isCross = self.isCross

	local function fightCb(view, battleCards, extra, aidCards)
		local endStamp = time.getNumTimestamp(gGameModel.gym:read("date"), 21, 45) + 518400

		if endStamp <= time.getTime() then
			gGameUI:showTip(gLanguageCsv.gymTimeOut)

			return
		end

		local data = battleCards:read()
		local aidCards = aidCards:read()

		if not isCross then
			battleEntrance.battleRequest("/game/gym/leader/battle/start", data, id, masterData.id, extra, aidCards):onStartOK(function(data)
				view:onClose(false)
			end):run():show()
		else
			battleEntrance.battleRequest("/game/cross/gym/battle/start", data, id, pos, masterData.game_key, masterData.id, extra, aidCards):onStartOK(function(data)
				view:onClose(false)
			end):run():show()
		end
	end

	gGameUI:stackUI("city.adventure.gym_challenge.embattle1", nil, {
		full = true
	}, {
		fightCb = fightCb,
		limitInfo = csv.gym.gym[self.id].limitAttribute,
		from = game.EMBATTLE_FROM_TABLE.onekey,
		fromId = game.EMBATTLE_GYMCHALLENGE_ID.pvp,
		isCross = self.isCross
	})
	self:onClose()
end

function GymMasterInfoView:getChallengeState()
	if gGameModel.gym:read("round") == "closed" then
		return false
	end

	local endStamp = time.getNumTimestamp(gGameModel.gym:read("date"), 21, 45) + 518400

	return endStamp > time.getTime()
end

return GymMasterInfoView
