-- chunkname: @src.app.views.city.activity.contest_bet.tools

local STATE = {
	BETTING = 1,
	OVER = 3,
	BATTLING = 2,
	CHAMPITION_BETTING = 0
}
local ContestBetTools = {}

function ContestBetTools.getProtocol(key)
	local protocol = {
		bet = "/game/yy/contestbet/bet",
		buy = "/game/yy/contestbet/buy",
		award = "/game/yy/contestbet/award",
		send = "/game/yy/contestbet/send",
		card = "/game/yy/contestbet/card",
		playback = "/game/yy/contestbet/playback",
		contest = "/game/yy/contestbet/contest",
		danmu = "/game/yy/contestbet/team"
	}

	return protocol[key]
end

function ContestBetTools.getCsv(csvName)
	return csv.cross.contestbet[csvName]
end

function ContestBetTools:updateTeams(teamsData)
	self.teamsData = teamsData
end

function ContestBetTools:teamIndex2TeamId(id)
	return self.teamsData[id].csv_id
end

function ContestBetTools.getContestDate(yyId, contestDate)
	local beginDate = csv.yunying.yyhuodong[yyId].beginDate
	local stamp = time.getNumTimestamp(beginDate) + (contestDate - 1) * 24 * 3600
	local t = time.getDate(stamp)

	return string.format("%04d%02d%02d", t.year, t.month, t.day)
end

function ContestBetTools.getChampionBetDueStamp(yyId)
	local beginDate = csv.yunying.yyhuodong[yyId].beginDate
	local baseID = csv.yunying.yyhuodong[yyId].paramMap.base
	local contestIDs = csv.cross.contestbet.base[baseID].contestIDs
	local firstContestId = contestIDs[1]
	local cfg = csv.cross.contestbet.contest[firstContestId]
	local stamp = time.getNumTimestamp(ContestBetTools.getContestDate(yyId, cfg.contestDate), time.getHourAndMin(cfg.betEndTime, true))

	return stamp
end

function ContestBetTools.getChampionShowStamp(yyId)
	local nowTimeStamp = time.getTime()
	local baseID = csv.yunying.yyhuodong[yyId].paramMap.base
	local contestIDs = csv.cross.contestbet.base[baseID].contestIDs
	local firstContestId = contestIDs[1]
	local firtstContestcfg = csv.cross.contestbet.contest[firstContestId]
	local championShowTime = time.getNumTimestamp(ContestBetTools.getContestDate(yyId, firtstContestcfg.contestDate), 0, 0)

	return championShowTime
end

function ContestBetTools.getNextContestAndState(yyId)
	local nowTimeStamp = time.getTime()
	local baseID = csv.yunying.yyhuodong[yyId].paramMap.base
	local contestIDs = csv.cross.contestbet.base[baseID].contestIDs
	local contestId = 0

	if nowTimeStamp < ContestBetTools.getChampionShowStamp(yyId) then
		return 0, STATE.CHAMPITION_BETTING
	end

	for i, csvId in orderCsvPairs(contestIDs) do
		local cfg = csv.cross.contestbet.contest[csvId]
		local endTimeStamp1 = time.getNumTimestamp(ContestBetTools.getContestDate(yyId, cfg.contestDate), time.getHourAndMin(cfg.betEndTime, true))
		local endTimeStamp2 = time.getNumTimestamp(ContestBetTools.getContestDate(yyId, cfg.contestDate), time.getHourAndMin(cfg.contestEndTime, true))

		if nowTimeStamp < endTimeStamp1 then
			contestId = csvId

			return contestId, STATE.BETTING
		elseif endTimeStamp1 <= nowTimeStamp and nowTimeStamp < endTimeStamp2 then
			contestId = csvId

			return contestId, STATE.BATTLING
		end
	end

	return 0, STATE.OVER
end

local function isFisrtDayContest(yyId, contestId)
	local baseID = csv.yunying.yyhuodong[yyId].paramMap.base
	local contestIDs = csv.cross.contestbet.base[baseID].contestIDs
	local firstContestId = contestIDs[1]

	if ContestBetTools.getCsv("contest")[firstContestId].contestDate == ContestBetTools.getCsv("contest")[contestId].contestDate then
		return true
	end

	return false
end

function ContestBetTools.createTopui(view, activityId, notShow)
	gGameUI.topuiManager:createView("battlebet", view, {
		onClose = view:createHandler("onClose")
	}):init({
		subTitle = "COMPETITION BATTLE GUESS",
		title = gLanguageCsv.contestBet,
		activityId = activityId,
		notShow = notShow
	})
end

function ContestBetTools.getBgTexture()
	return "activity/contest_bet/bg_dzqd.png"
end

function ContestBetTools.getMatchName(activityId, csvId, contest)
	return contest.contestName
end

function ContestBetTools.getContestBetTime(yyId, contestId)
	local beginDate = csv.yunying.yyhuodong[yyId].beginDate
	local contestDate = ContestBetTools.getCsv("contest")[contestId].contestDate
	local stamp = time.getNumTimestamp(beginDate) + (contestDate - 1) * 24 * 3600
	local betEndTime = ContestBetTools.getCsv("contest")[contestId].betEndTime
	local betEndHour, betEndMin = time.getHourAndMin(betEndTime, true)
	local betEndStamp = stamp + betEndHour * 3600 + betEndMin * 60
	local betStartStamp = stamp - 18000
	local yyCfg = csv.yunying.yyhuodong[yyId]
	local cfg = ContestBetTools.getCsv("base")[yyCfg.paramMap.base]

	if isFisrtDayContest(yyId, contestId) then
		local yyCfg = csv.yunying.yyhuodong[yyId]
		local beginHour, beginMin = time.getHourAndMin(yyCfg.beginTime, true)
		local beginTime = time.getNumTimestamp(yyCfg.beginDate, beginHour, beginMin)

		betStartStamp = beginTime
	else
		for _, id in ipairs(cfg.contestIDs) do
			local contest = ContestBetTools.getCsv("contest")[id]

			if contest and contest.contestDate == contestDate - 1 then
				local contestEndHour, contestEndMin = time.getHourAndMin(contest.contestEndTime, true)
				local contestEndTimestamp = time.getNumTimestamp(ContestBetTools.getContestDate(yyId, contest.contestDate), contestEndHour, contestEndMin)

				betStartStamp = math.max(betStartStamp, contestEndTimestamp)
			end
		end
	end

	local contestEndTime = ContestBetTools.getCsv("contest")[contestId].contestEndTime
	local contestEndHour, contestEndMin = time.getHourAndMin(contestEndTime, true)
	local contestEndStamp = stamp + contestEndHour * 3600 + contestEndMin * 60

	return betStartStamp, betEndStamp, contestEndStamp
end

return ContestBetTools
