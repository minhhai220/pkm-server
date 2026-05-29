-- chunkname: @src.app.views.city.adventure.clone_battle.vote

local ViewBase = cc.load("mvc").ViewBase
local CloneBattleVoteView = class("CloneBattleVoteView", Dialog)

CloneBattleVoteView.RESOURCE_FILENAME = "clone_battle_kick_note.json"
CloneBattleVoteView.RESOURCE_BINDING = {
	txt3 = "txt3",
	name3 = "name3",
	name4 = "name4",
	content = "contentLabel",
	txt4 = "txt4",
	name2 = "name2",
	txt1 = "txt1",
	name1 = "name1",
	txt2 = "txt2",
	closeBtn = {
		varname = "closeBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	},
	leaveBtn = {
		varname = "leaveBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onLeaveBtn")
			}
		}
	},
	stayBtn = {
		varname = "stayBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onStayBtn")
			}
		}
	},
	btnClose = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	}
}

function CloneBattleVoteView:onCreate(isFromInfo)
	self:initModel()

	local isFromInfo = isFromInfo

	idlereasy.any({
		self.beasIdler.finishNum,
		self.beasIdler.places,
		self.beasIdler.voteRound
	}, function(_, finishNum, places, voteRound)
		if voteRound == "start" then
			local nameTab = {}
			local leaveNum = 0
			local stayNum = 0
			local isVote = 0
			local selfId = gGameModel.role:read("id")

			self.name = places[1].name

			local defaultAlign = "center"
			local size = self.contentLabel:size()
			local list, height = beauty.textScroll({
				fontSize = 50,
				verticalSpace = 10,
				isRich = true,
				margin = 20,
				size = size,
				effect = {
					color = ui.COLORS.NORMAL.DEFAULT
				},
				strs = string.format("#C0x5b545b#" .. gLanguageCsv.cloneBattleKickText, self.name),
				align = defaultAlign
			})
			local y = 0

			if height < size.height then
				y = -(size.height - height) / 2
			end

			list:addTo(self.contentLabel, 10):y(y)

			for k, v in pairs(places) do
				if v.kick_leader ~= 0 then
					table.insert(nameTab, v.name)

					if v.kick_leader < 0 then
						stayNum = stayNum + 1
					else
						leaveNum = leaveNum + 1
					end

					if v.id == selfId then
						isVote = v.kick_leader
					end
				end
			end

			for k = 1, 4 do
				if nameTab[k] then
					self["name" .. k]:text(nameTab[k])
					self["name" .. k]:show()
				else
					self["name" .. k]:hide()
				end
			end

			if isVote ~= 0 then
				cache.setShader(self.leaveBtn, false, "hsl_gray")
				cache.setShader(self.stayBtn, false, "hsl_gray")

				if isVote == 1 then
					self.leaveBtn:get("gou"):show()
				else
					self.stayBtn:get("gou"):show()
				end

				adapt.oneLineCenterPos(cc.p(140, 60), {
					self.leaveBtn:get("gou"),
					self.leaveBtn:get("txt")
				}, cc.p(0, 0))
				adapt.oneLineCenterPos(cc.p(140, 60), {
					self.stayBtn:get("gou"),
					self.stayBtn:get("txt")
				}, cc.p(0, 0))
				self.leaveBtn:setTouchEnabled(false)
				self.stayBtn:setTouchEnabled(false)
				self.txt3:text(string.format(gLanguageCsv.cloneBattleVote, leaveNum))
				self.txt3:show()
				self.txt4:text(string.format(gLanguageCsv.cloneBattleVote, stayNum))
				self.txt4:show()
			end

			isFromInfo = false
		elseif isFromInfo == false then
			ViewBase.onClose(self)

			return
		end
	end)
	Dialog.onCreate(self)
end

function CloneBattleVoteView:initModel()
	self.beasIdler = {
		date = gGameModel.clone_room:getIdler("date"),
		finishNum = gGameModel.clone_room:getIdler("finish_num"),
		monsters = gGameModel.clone_room:getIdler("monsters"),
		places = gGameModel.clone_room:getIdler("places"),
		voteRound = gGameModel.clone_room:getIdler("vote_round")
	}
end

function CloneBattleVoteView:onLeaveBtn()
	local name = self.name

	gGameUI:showDialog({
		btnType = 2,
		isRich = true,
		content = "#C0x5b545b#" .. gLanguageCsv.cloneBattleKickVoteTipLeave,
		cb = function()
			gGameApp:requestServer("/game/clone/room/vote", function(tb)
				if tb.view.result == "win" then
					gGameUI:showTip(string.format(gLanguageCsv.cloneBattleKickVoteResultTipLeave, name))
				elseif tb.view.result == "fail" then
					gGameUI:showTip(string.format(gLanguageCsv.cloneBattleKickVoteResultTipStay, name))
				end
			end, 1)
		end,
		dialogParams = {
			clickClose = false
		}
	})
end

function CloneBattleVoteView:onStayBtn()
	local name = self.name

	gGameUI:showDialog({
		btnType = 2,
		isRich = true,
		content = "#C0x5b545b#" .. gLanguageCsv.cloneBattleKickVoteTipStay,
		cb = function()
			gGameApp:requestServer("/game/clone/room/vote", function(tb)
				if tb.view.result == "win" then
					gGameUI:showTip(string.format(gLanguageCsv.cloneBattleKickVoteResultTipLeave, name))
				elseif tb.view.result == "fail" then
					gGameUI:showTip(string.format(gLanguageCsv.cloneBattleKickVoteResultTipStay, name))
				end
			end, -1)
		end,
		dialogParams = {
			clickClose = false
		}
	})
end

return CloneBattleVoteView
