-- chunkname: @src.battle.app_views.battle.module.team

local Team = class("Team", battleModule.CBase)

function Team:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.selfTeam = self.parent.UIWidgetGroupLeft
	self.enemyTeam = self.parent.UIWidgetGroupRight

	self.selfTeam:hide()
	self.enemyTeam:hide()

	self.isShow = false
end

function Team:initTeamUI(args)
	self.isShow = true

	self.selfTeam:show()

	if args.showMultTeams then
		self:showTeams(args.showMultTeams, args.showEnemyTeam)
	end

	if args.showEnemyTeam then
		self.enemyTeam:show()

		self.isShowEnemyTeam = true
	else
		local wavaPanel = self.parent.UIWidgetMid:get("widgetPanel.wavePanel")
		local posX = wavaPanel:getContentSize().width
		local pos = self.selfTeam:getParent():convertToNodeSpace(wavaPanel:convertToWorldSpace(cc.p(posX, 0)))

		self.selfTeam:setPositionX(pos.x)
	end
end

function Team:showTeams(num, isShowEnemy)
	local function showTeams(teamsNode, visible)
		for i = 1, num do
			teamsNode:get("team" .. i):setVisible(visible)
		end
	end

	showTeams(self.selfTeam, true)
	showTeams(self.enemyTeam, isShowEnemy)
end

function Team:changeTeamState(force, group, winForce)
	local teams = force == 1 and self.selfTeam or self.enemyTeam

	if group > 0 then
		local team = teams:get("team" .. group)

		if force == winForce then
			team:get("lightFlag"):setVisible(false)
			team:get("win"):setVisible(true)
		else
			team:get("lightFlag"):setVisible(false)
			team:get("fail"):setVisible(true)
		end
	end

	local nextGroup = group + 1

	teams:get("team" .. nextGroup):get("lightFlag"):setVisible(true)
end

function Team:onNewBattleRoundTo(args)
	self:onShowMain(true)
end

function Team:onShowMain(isShow)
	if not self.isShow then
		return
	end

	self.selfTeam:setVisible(isShow)
	self.enemyTeam:setVisible(isShow and self.isShowEnemyTeam)
end

function Team:onChangeTeam(totalNum, preWin, isShowEnemy)
	self:changeTeamState(1, totalNum, preWin)

	if isShowEnemy then
		self:changeTeamState(2, totalNum, preWin)
	end
end

function Team:onSetTeamNumber(lef, rig)
	self.selfTeam:get("team1"):get("txt"):text(tostring(lef))
	self.enemyTeam:get("team3"):get("txt"):text(tostring(rig))
end

return Team
