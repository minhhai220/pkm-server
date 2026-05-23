-- chunkname: @src.app.views.city.activity.worldcup.tools

local worldcupTools = {}
local checkConditions = {
	function()
		local data = gGameModel.role:read("worldcup")
		local ret = {}
		local wdl = data.bet_wdl or {}
		local betScore = data.bet_score or {}

		for k, v in pairs(wdl) do
			ret[k] = true
		end

		for k, v in pairs(betScore) do
			ret[k] = true
		end

		return itertools.size(ret)
	end,
	function()
		local count = 0
		local data = gGameModel.role:read("worldcup")
		local wdl = data.bet_wdl or {}

		for k, v in pairs(wdl) do
			local matchCfg = csv.yunying.worldcup_match[k]
			local inTime = time.getTime() > worldcupTools.getCurTimeStamp(matchCfg.awardDate, matchCfg.awardTime)

			if inTime and matchCfg.point ~= "" then
				local score = string.split(matchCfg.point, ":")
				local left, right = tonumber(score[1]), tonumber(score[2])

				if v == 1 and right < left or v == 0 and left == right or v == -1 and left < right then
					count = count + 1
				end
			end
		end

		return count
	end,
	function()
		local count = 0
		local data = gGameModel.role:read("worldcup")
		local betScore = data.bet_score or {}

		for k, v in pairs(betScore) do
			local matchCfg = csv.yunying.worldcup_match[k]
			local inTime = time.getTime() > worldcupTools.getCurTimeStamp(matchCfg.awardDate, matchCfg.awardTime)

			if inTime and matchCfg.point ~= "" then
				local score = string.split(matchCfg.point, ":")
				local left, right = tonumber(score[1]), tonumber(score[2])

				if left - right == v then
					count = count + 1
				end
			end
		end

		return count
	end,
	function()
		local count = 0
		local data = gGameModel.role:read("worldcup")
		local wdl = data.bet_wdl or {}
		local betScore = data.bet_score or {}
		local ret = {}

		for k, v in pairs(wdl) do
			ret[k] = true
		end

		for k, v in pairs(betScore) do
			ret[k] = true
		end

		for k, v in pairs(ret) do
			local matchCfg = csv.yunying.worldcup_match[k]

			if matchCfg.focus == 1 then
				count = count + 1
			end
		end

		return count
	end,
	function()
		local data = gGameModel.role:read("worldcup")
		local bet = data.champion_bet or {}
		local teamId = bet[1] or 0

		if teamId ~= 0 then
			return csv.yunying.worldcup_team[teamId].finalRank
		end

		return 0
	end
}

function worldcupTools.getCurTimeStr(startDate, startTime)
	local curTime = worldcupTools.getCurTimeStamp(startDate, startTime)
	local timeData = time.getDate(curTime)
	local str = string.format(gLanguageCsv.worldcupTime, timeData.month, timeData.day, timeData.hour, timeData.min)

	return str
end

function worldcupTools.getCurTimeStamp(startDate, startTime)
	local hour, min = time.getHourAndMin(startTime, true)
	local curTime = time.getNumTimestamp(startDate, hour, min) - 28800 + UNIVERSAL_TIMEDELTA

	return curTime
end

function worldcupTools.guessPointResult(id)
	local cfg = csv.yunying.worldcup_match[id]

	if time.getTime() - worldcupTools.getCurTimeStamp(cfg.awardDate, cfg.awardTime) < 0 then
		return
	end

	if cfg.point == "" then
		return
	end

	local data = gGameModel.role:read("worldcup")
	local wdl = data.bet_wdl or {}
	local result = wdl[id]
	local score = string.split(cfg.point, ":")
	local left, right = tonumber(score[1]), tonumber(score[2])

	if result == 1 and right < left then
		return "right"
	end

	if result == 0 and left == right then
		return "right"
	end

	if result == -1 and left < right then
		return "right"
	end

	return "wrong"
end

function worldcupTools.guessScoreResult(id)
	local cfg = csv.yunying.worldcup_match[id]

	if time.getTime() - worldcupTools.getCurTimeStamp(cfg.awardDate, cfg.awardTime) < 0 then
		return
	end

	if cfg.point == "" or cfg.focus ~= 1 then
		return
	end

	local data = gGameModel.role:read("worldcup")
	local betScore = data.bet_score or {}
	local result = betScore[id]
	local score = string.split(cfg.point, ":")
	local left, right = tonumber(score[1]), tonumber(score[2])

	return result == left - right
end

function worldcupTools.getAchievementCount(id)
	local cfg = csv.yunying.worldcup_tasks[id]

	return checkConditions[cfg.targetType]()
end

return worldcupTools
