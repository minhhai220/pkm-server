-- chunkname: @src.app.views.city.pvp.arena.personal_info

local ArenaPersonalInfoView = class("ArenaPersonalInfoView", Dialog)

ArenaPersonalInfoView.RESOURCE_FILENAME = "arena_personal_info.json"
ArenaPersonalInfoView.RESOURCE_BINDING = {
	item = "item",
	["top.imgVipInfo"] = "imgVipInfo",
	imgBG = "imgBG",
	["top.textUnionNote"] = "textUnionNote",
	aidPanel = "aidPanel",
	["top.textName"] = {
		varname = "textName",
		binds = {
			event = "text",
			idler = bindHelper.self("roleName")
		}
	},
	["top.textRank"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("rank")
		}
	},
	["top.textFightPoint"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("fightPoint")
		}
	},
	["top.textUnion"] = {
		varname = "textUnion",
		binds = {
			event = "text",
			idler = bindHelper.self("union")
		}
	},
	["top.textLv"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("level")
		}
	},
	["top.head"] = {
		binds = {
			class = "role_logo",
			event = "extend",
			props = {
				vip = false,
				level = false,
				logoId = bindHelper.self("logoId"),
				frameId = bindHelper.self("frameId"),
				onNode = function(panel)
					panel:scale(1.1)
				end
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
	},
	["top.btnTake"] = {
		varname = "btnTake",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onEnterChat")
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
	["top.btnAddFriend"] = {
		varname = "btnAddFriend",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onAddFriend")
			}
		}
	},
	["top.btnAddFriend.textNote"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["down.list"] = {
		varname = "list",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				asyncPreload = 6,
				data = bindHelper.self("team"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					if not v.isInfo then
						return
					end

					node:get("emptyPanel"):hide()

					local unitID = dataEasy.getUnitId(v.card_id, v.skin_id)

					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = unitID,
							advance = v.advance,
							rarity = v.rarity,
							star = v.star,
							levelProps = {
								data = v.level
							},
							onNode = function(node)
								node:xy(0, -6)
							end
						}
					})
				end
			}
		}
	}
}

function ArenaPersonalInfoView:onCreate(personalInfo)
	self:initModel()

	self.roleId = personalInfo.role_db_id
	self.level = idler.new(personalInfo.role_level)
	self.roleName = idler.new(personalInfo.role_name)
	self.vip = idler.new(personalInfo.role_vip)
	self.rank = idler.new(personalInfo.rank)
	self.fightPoint = idler.new(personalInfo.fighting_point)

	local unionName = string.len(personalInfo.union_name) > 0 and personalInfo.union_name or gLanguageCsv.noUnion

	self.union = idler.new(unionName)
	self.logoId = idler.new(personalInfo.role_logo)
	self.frameId = idler.new(personalInfo.role_frame)
	self.personalInfo = personalInfo
	self.team = idlers.newWithMap({})

	local team = {}
	local csvTab = csv.cards
	local unitTab = csv.unit

	for _, id in pairs(personalInfo.defence_cards) do
		local cardInfo = personalInfo.defence_card_attrs[id]

		if csvTab[cardInfo.card_id] then
			cardInfo.rarity = unitTab[csvTab[cardInfo.card_id].unitID].rarity
			cardInfo.isInfo = true

			table.insert(team, cardInfo)
		end
	end

	if #team < 6 then
		local num = #team

		for i = num + 1, 6 do
			table.insert(team, {
				isInfo = false
			})
		end
	end

	self.team:update(team)

	local vipLv = self.vip:read()

	self.imgVipInfo:visible(vipLv > 0)

	if vipLv > 0 then
		self.imgVipInfo:texture(string.format("common/icon/vip/icon_vip%d.png", vipLv))
	end

	if personalInfo.from == "battleRecommend" then
		self.btnTake:hide()
		self.btnAddFriend:hide()
		self.textUnion:hide()
		self.textUnionNote:hide()
	else
		self.btnTake:setVisible(not personalInfo.robot)
		self.btnAddFriend:setVisible(not personalInfo.robot)
		self.textUnion:show()
		self.textUnionNote:show()
	end

	self.textName:text(self.roleName:read())
	adapt.oneLinePos(self.textName, self.imgVipInfo, cc.p(10, 0))
	self:updateAidPanel()
	Dialog.onCreate(self)
end

function ArenaPersonalInfoView:initModel()
	self.friendMessage = gGameModel.messages:getIdler("private")
end

function ArenaPersonalInfoView:updateAidPanel()
	local aidNum = dataEasy.getAidNum(game.GATE_TYPE.arena, nil, self.level:read())

	if aidNum == 0 then
		return
	end

	self.aidPanel:show()
	self.list:x(120)
	self.imgBG:height(950)

	local aidTeam = {}
	local defenceAidCards = table.deepcopy(self.personalInfo.defence_aid_cards or {}, true)

	for i = 1, aidNum do
		if defenceAidCards[i] then
			local cardInfo = self.personalInfo.defence_card_attrs[defenceAidCards[i]]

			if cardInfo then
				aidTeam[i] = dataEasy.getUnitId(cardInfo.card_id, cardInfo.skin_id)
			end
		else
			aidTeam[i] = 0
		end
	end

	uiEasy.createSimpleCardToList(self, self.aidPanel:get("list"), aidTeam, {
		margin = 68,
		scale = 2
	})
end

function ArenaPersonalInfoView:onEnterChat()
	local data = {
		isMine = false,
		role = {
			level = self.personalInfo.role_level,
			id = self.personalInfo.role_db_id,
			logo = self.personalInfo.role_logo,
			name = self.personalInfo.role_name,
			vip = self.vip:read(),
			frame = self.personalInfo.role_frame
		}
	}

	gGameUI:stackUI("city.chat.privataly", nil, nil, data)
end

function ArenaPersonalInfoView:onAddFriend()
	local state = userDefault.getCurrDayKey("friendsAddState", {})
	local isAlreadyAdd = state[self.roleId]

	if isAlreadyAdd then
		gGameUI:showTip(gLanguageCsv.friendAlready)

		return
	end

	gGameApp:requestServer("/game/society/friend/askfor", function(tb)
		userDefault.setCurrDayKey("friendsAddState", alreadyFriend)
		gGameUI:showTip(gLanguageCsv.addFriendWait)
	end, {
		self.roleId
	})
end

return ArenaPersonalInfoView
