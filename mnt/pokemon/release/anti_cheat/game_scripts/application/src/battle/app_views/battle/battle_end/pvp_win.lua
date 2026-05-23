-- chunkname: @src.battle.app_views.battle.battle_end.pvp_win

local BattleEndPvpWinView = class("BattleEndPvpWinView", cc.load("mvc").ViewBase)

BattleEndPvpWinView.RESOURCE_FILENAME = "battle_end_pvp_win.json"
BattleEndPvpWinView.RESOURCE_BINDING = {
	sharePanel = "sharePanel",
	sliderRankBg = "sliderRankPanel",
	awardsList = "awardsList",
	["imgRankBg.imgUp"] = "imgUp",
	cardItem = "awardsItem",
	textReward = "textReward",
	playBackPanel = "playBackPanel",
	imgBestCard = "bestCard",
	imgNewRecord = "newRecord",
	["imgRankBg.bg"] = "imgRankBg",
	imgRankBg = "imgRankPanel",
	["imgBestBg.bestName"] = {
		varname = "bestName",
		binds = {
			event = "effect",
			data = {
				italic = true,
				outline = {
					color = ui.COLORS.NORMAL.RED
				}
			}
		}
	},
	["playBackPanel.playBackBg"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onPlayBackBtnClick")
			}
		}
	},
	["playBackPanel.txt"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.NORMAL.WHITE
				}
			}
		}
	},
	["sharePanel.txt"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.NORMAL.WHITE
				}
			}
		}
	},
	["sharePanel.shareBg"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onShareBtnClick")
			}
		}
	},
	imgBg = {
		binds = {
			event = "click",
			method = bindHelper.self("onCloseClick")
		}
	},
	["sliderRankBg.head"] = {
		binds = {
			event = "effect",
			data = {
				italic = true,
				outline = {
					color = ui.COLORS.NORMAL.BLACK
				}
			}
		}
	},
	["sliderRankBg.rankUp"] = {
		binds = {
			event = "effect",
			data = {
				italic = true,
				outline = {
					color = ui.COLORS.NORMAL.BLACK
				}
			}
		}
	},
	["sliderRankBg.score"] = {
		binds = {
			event = "effect",
			data = {
				italic = true,
				outline = {
					color = ui.COLORS.NORMAL.BLACK
				}
			}
		}
	},
	["sliderRankBg.teamScoreBg.text"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = ui.COLORS.NORMAL.RED
				}
			}
		}
	},
	["imgRankBg.rank"] = {
		varname = "rank",
		binds = {
			event = "effect",
			data = {
				italic = true,
				outline = {
					color = ui.COLORS.NORMAL.RED
				}
			}
		}
	},
	["imgRankBg.rankUp"] = {
		varname = "rankUp",
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = cc.c4b(235, 99, 54, 255)
				}
			}
		}
	}
}

local PlayModuleMap = {}

function PlayModuleMap:default(curRank, topMove, serverDataView)
	self.rank:text(curRank)
	self.rankUp:text(serverDataView.rank_move)
	adapt.oneLineCenterPos(cc.p(400, 80), {
		self.rank,
		self.imgUp,
		self.rankUp
	}, cc.p(20, 0))
end

function PlayModuleMap:crossArena(curRank, topMove, serverDataView)
	local curData = self.results.curData
	local preData = self.results.preData
	local prestr = preData.stageName .. " " .. preData.rank
	local curstr = curData.stageName .. " " .. curData.rank

	self.rank:text(prestr)
	self.rankUp:text(curstr)
	self.rankUp:setRotationSkewX(12)
	adapt.oneLineCenterPos(cc.p(550, 80), {
		self.rank,
		self.imgUp,
		self.rankUp
	}, cc.p(40, 0))
	self.newRecord:y(900)

	local x = self.rank:x() - self.rank:anchorPoint().x * self.rank:width()
	local width = self.rankUp:x() + (1 - self.rankUp:anchorPoint().x) * self.rankUp:width() - x
	local headLength = 240

	self.imgRankBg:x(x - headLength):width(width + headLength)

	self.crossData = table.deepcopy(gGameModel.cross_arena:read("record").history, true)

	table.sort(self.crossData, function(a, b)
		return a.time > b.time
	end)
end

function PlayModuleMap:onlineFight(curRank, topMove, serverDataView)
	if self.results.serverData.view.pattern == 1 then
		self.crossData = table.deepcopy(gGameModel.cross_online_fight:read("unlimited_history"), true)
	else
		self.crossData = table.deepcopy(gGameModel.cross_online_fight:read("limited_history"), true)
	end

	table.sort(self.crossData, function(a, b)
		return a.time > b.time
	end)
	self.rank:text(curRank)
	self.rankUp:text(serverDataView.rank_move)
	adapt.oneLineCenterPos(cc.p(400, 80), {
		self.rank,
		self.imgUp,
		self.rankUp
	}, cc.p(20, 0))
end

function PlayModuleMap:gymLeader(curRank, topMove, serverDataView)
	local posx, posy = self.imgRankPanel:x(), self.imgRankPanel:y()

	self.newRecord:loadTexture("city/pvp/reward/panle_gx.png"):scale(1):visible(true):xy(posx, posy)

	local richStr = self.results.gymMember and gLanguageCsv.gymMemberBattleWin or string.format(gLanguageCsv.gymLeaderBattleWin, self.results.gymName)
	local fontSize = matchLanguage({
		"kr",
		"en"
	}) and 65 or 80

	rich.createByStr(richStr, fontSize):anchorPoint(0.5, 0.5):xy(posx, posy + 22):addTo(self.newRecord:parent()):z(10)
	self.imgRankPanel:hide()
	self.sharePanel:hide()
end

function PlayModuleMap:crossMine(curRank, topMove, serverDataView)
	local posx, posy = self.imgRankPanel:x(), self.imgRankPanel:y()

	self.imgRankPanel:xy(posx, posy + 150)

	if serverDataView.speed then
		local newSpeed = string.format(gLanguageCsv.crossMinePVPSpeed, serverDataView.speed)

		rich.createByStr(newSpeed, 50):anchorPoint(0, 0.5):xy(posx - 290, posy + 50):addTo(self.imgRankPanel:parent()):z(10)
	end

	if serverDataView.robNum then
		local rarityPanel = ccui.ImageView:create():anchorPoint(0.5, 0.5):xy(posx - 200, posy - 50):addTo(self.imgRankPanel:parent()):texture("city/pvp/cross_mine/icon_kfzy.png"):show()
		local robNum = string.format(gLanguageCsv.crossMinePVPRob, serverDataView.robNum)

		rich.createByStr(robNum, 60):anchorPoint(0, 0.5):xy(posx - 120, posy - 50):addTo(self.imgRankPanel:parent()):z(10)
	end

	self.rank:text(curRank)
	self.rankUp:text(serverDataView.rank_move)

	self.crossData = table.deepcopy(gGameModel.cross_mine:read("record").history, true)
end

function PlayModuleMap:crossSupremacy(curRank, topMove, serverDataView)
	self.sliderRankPanel:visible(true)
	self.imgRankPanel:visible(false)

	local pNode = self.sliderRankPanel
	local curData = self.results.curData
	local preData = self.results.preData

	pNode:get("head"):text(gLanguageCsv.winPoint .. ":")
	self:getResourceNode():get("title"):y(self:getResourceNode():get("title"):y() - 50)

	local bar = pNode:get("rankBar.rankNew")

	bar:setPercent(preData.lerp / preData.limit * 100)

	if curData.score ~= preData.score then
		local time = 1
		local sequence = transition.executeSequence(bar)

		if curData.rankScore < preData.rankScore then
			sequence:progressTo(time, 0):func(function()
				bar:setPercent(100)
			end):progressTo(time, curData.lerp / curData.limit * 100)
		elseif curData.rankScore > preData.rankScore then
			sequence:progressTo(time, 100):func(function()
				bar:setPercent(0)
			end):progressTo(time, curData.lerp / curData.limit * 100)
		else
			sequence:progressTo(time, curData.lerp / curData.limit * 100)
		end

		sequence:done()
	end

	pNode:get("rankUp"):text(serverDataView.score_move)

	if serverDataView.score_move < 0 then
		pNode:get("imgUp"):texture("common/icon/logo_arrow_red.png")
	end

	if curData.limit <= 0 then
		pNode:get("score"):text(curData.lerp)
	else
		pNode:get("score"):text(curData.lerp .. "/" .. curData.limit)
	end

	local awardsX = self.awardsList:getPosition()
	local awardsWidth = self.awardsList:size().width

	self.textReward:x(awardsX + awardsWidth / 2)
	self.textReward:show()

	if next(serverDataView.award) ~= nil then
		self.awardsList:show()

		local awardData = serverDataView.award
		local tmpData = {}

		for k, v in pairs(awardData) do
			table.insert(tmpData, {
				key = k,
				num = v
			})
		end

		uiEasy.createItemsToList(self, self.awardsList, tmpData, {
			margin = 50,
			onAfterBuild = function()
				self.awardsList:setItemAlignCenter()
			end
		})

		if topMove > 0 then
			pNode:get("teamScoreBg"):x(pNode:get("teamScoreBg"):x() - 270)
			self.newRecord:xy(self.newRecord:x() + 270, self.newRecord:y() + 365)
		end
	end

	pNode:get("teamScoreBg.text"):text(string.format("%s  :  %s", self.results.teamScore[1], self.results.teamScore[2]))

	self.crossData = table.deepcopy(gGameModel.cross_supremacy:read("record").history, true)
end

function BattleEndPvpWinView:playEffect()
	local pnode = self:getResourceNode()

	widget.addAnimationByKey(pnode, "level/zhandoujiangli.skel", "selEffect", "zhandoushengli", 100):anchorPoint(cc.p(0.5, 0.5)):xy(pnode:get("title"):xy()):addPlay("zhandoushengli_loop")
end

function BattleEndPvpWinView:plsyBestEffect()
	local pnode = self:getResourceNode()

	widget.addAnimationByKey(pnode, "level/zhandoujiangli.skel", "selEffect2", "quanchangzuijia", 2):anchorPoint(cc.p(0.5, 0.5)):xy(self.bestCard:xy()):addPlay("quanchangzuijia_loop")
end

function BattleEndPvpWinView:onCreate(sceneID, data, results)
	audio.playEffectWithWeekBGM("pvp_win.mp3")

	self.data = data
	self.results = results

	local cardId = results.dbID

	self.bestCardId = results.unitID

	local card = gGameModel.cards:find(cardId)
	local bestCardName

	if card then
		bestCardName = card:read("name")
	end

	if not card or not bestCardName or bestCardName == "" then
		local bestCardID = csv.unit[self.bestCardId].cardID

		bestCardName = csv.cards[bestCardID].name
	end

	if results.recordType and results.recordType == "jf" then
		self.imgRankBg:loadTexture("battle/end/win/img_jifen_bg.png")
	end

	self:cardPosCorrect()
	self.bestName:text(bestCardName)
	self:bestCardScale()
	self:plsyBestEffect()

	local serverDataView = results.serverData.view
	local topMove = serverDataView.top_move or 0
	local curRank = serverDataView.rank
	local preRank = curRank and curRank + serverDataView.rank_move

	self.newRecord:visible(topMove > 0)

	local moduleDealFunc = PlayModuleMap[results.flag] or PlayModuleMap.default

	moduleDealFunc(self, curRank, topMove, serverDataView)
	self:playEffect()
end

function BattleEndPvpWinView:showItem(index, data)
	local function addResToItem(node, res)
		local size = node:size()
		local sp = cc.Sprite:create(res):addTo(node, 999):anchorPoint(1, 1):xy(size.width, size.height)
	end

	local item = self.awardsItem:clone()

	item:show()

	local value = data[index]
	local binds = {
		class = "icon_key",
		props = {
			data = {
				key = value.key,
				num = value.num
			},
			specialKey = {
				maxLimit = true
			},
			onNode = function(node)
				local x, y = node:xy()

				node:xy(x, y + 3)
				node:hide():z(2)
				transition.executeSequence(node, true):delay(0.5):func(function()
					node:show()
				end):done()
			end
		}
	}

	bind.extend(self, item, binds)
	self.awardsList:setItemsMargin(25)
	self.awardsList:pushBackCustomItem(item)
	self.awardsList:setScrollBarEnabled(false)
	transition.executeSequence(self.awardsList):delay(0.1):func(function()
		if index < table.length(data) then
			self:showItem(index + 1, data)
		end
	end):done()
end

function BattleEndPvpWinView:onPlayBackBtnClick()
	sdk.trackEvent("arenawin_replay")

	if self.results.flag == "onlineFight" then
		local data = self.data

		if not self.data.play_record_id or not self.data.cross_key then
			local crossData

			if self.results.serverData.view.pattern == 1 then
				crossData = table.deepcopy(gGameModel.cross_online_fight:read("unlimited_history"), true)
			else
				crossData = table.deepcopy(gGameModel.cross_online_fight:read("limited_history"), true)
			end

			table.sort(crossData, function(a, b)
				return a.time > b.time
			end)

			data = crossData[1]
		end

		gGameModel:playRecordBattle(data.play_record_id, data.cross_key, "/game/cross/online/playrecord/get", 0)

		return
	end

	battleEntrance.battleRecord(self.data, self.results):show()
end

function BattleEndPvpWinView:onShareBtnClick()
	local shareKey, reqKey = "", ""
	local data = self.data

	if self.results.flag == "crossArena" then
		shareKey = "cross_arena_battle_share_times"
		reqKey = "crossArena"
		data = self.crossData[1]
	elseif self.results.flag == "onlineFight" then
		shareKey = "cross_online_fight_share_times"
		reqKey = "onlineFight"
		data = self.crossData[1]
		data.enemy_name = data.enemy.name
	elseif self.results.flag == "crossMine" then
		shareKey = "cross_mine_share_times"
		reqKey = "crossMine"
		data = self.crossData[1]
	elseif self.results.flag == "crossSupremacy" then
		shareKey = "cross_supremacy_share_times"
		reqKey = "crossSupremacy"
		data = self.crossData[1]
	end

	if shareKey ~= "" and reqKey ~= "" then
		uiEasy.shareBattleToChat(data.play_record_id, data.enemy_name, reqKey, data.cross_key, shareKey)
	else
		local data = self.data

		uiEasy.shareBattleToChat(data.battleID, data.names[2])
	end
end

function BattleEndPvpWinView:onCloseClick()
	if self.results.backCity == true then
		gGameUI:switchUI("city.view")
	elseif self.results.flag == "crossArena" or self.results.flag == "crossSupremacy" then
		local showEndView = self.showEndView

		self:onClose()
		showEndView()
	else
		gGameUI:switchUI("city.view")
	end
end

function BattleEndPvpWinView:cardPosCorrect()
	local originX, originY = self.bestCard:getPosition()
	local cardShowPosC = csv.unit[self.bestCardId].cardShowPosC
	local curX, curY = originX + cardShowPosC.x, originY + cardShowPosC.y

	self.bestCard:setPosition(curX, curY)
end

function BattleEndPvpWinView:bestCardScale()
	local cardShow = csv.unit[self.bestCardId].cardShow
	local cardShowScale = csv.unit[self.bestCardId].cardShowScale
	local pvpCardShowScale = gCommonConfigCsv.pvpCardShowScale
	local scale = cardShowScale * pvpCardShowScale

	self.bestCard:scale(scale)
	self.bestCard:texture(cardShow)
end

return BattleEndPvpWinView
