-- chunkname: @src.app.easy.math

local mathEasy = {}

globals.mathEasy = mathEasy

function mathEasy.getPreciseDecimal(number, n, isRound)
	local num = number
	local power = math.pow(10, n or 0)

	num = num * power + 1e-08

	local integer = math.floor(num)
	local off = isRound and math.floor(num - integer + 0.5) or 0
	local val = (integer + off) / power

	return val
end

function mathEasy.getShortNumber(number, n)
	if type(number) ~= "number" then
		return number
	end

	local str = number
	local showLanguage = getShowLanguage()

	if not matchLanguage({
		"cn",
		"tw"
	}, showLanguage) then
		if number >= 1000000000 then
			str = mathEasy.getPreciseDecimal(number / 1000000000, n) .. "Bn"
		elseif number >= 1000000 then
			str = mathEasy.getPreciseDecimal(number / 1000000, n) .. "M"
		elseif number >= 10000 then
			str = mathEasy.getPreciseDecimal(number / 1000, n) .. "K"
		end
	elseif number >= 100000000 then
		str = mathEasy.getPreciseDecimal(number / 100000000, n) .. gLanguageCsv.hundredMillion
	elseif number >= 100000 then
		str = mathEasy.getPreciseDecimal(number / 10000, n) .. gLanguageCsv.tenThousand
	end

	return str
end

function mathEasy.getRowCol(index, lineNum)
	local row = math.floor((index - 1) / lineNum) + 1
	local col = (index - 1) % lineNum + 1

	return row, col
end

function mathEasy.getIndex(row, col, lineNum)
	return col + (row - 1) * lineNum
end

function mathEasy.showProgress(progress, data, targetVal)
	local idx = 0
	local min, max = 0, 0

	for _, val in ipairs(data) do
		idx = idx + 1
		min = max
		max = val

		if targetVal < val then
			break
		end
	end

	if targetVal > data[idx] then
		return 100
	end

	local rate = (targetVal - min) / (max - min)
	local base = progress[idx - 1] or 0
	local percent = base + rate * (progress[idx] - base)

	return math.min(percent, 100)
end

function mathEasy.setRankIndex(data, key)
	local func = key

	if type(key) == "string" then
		function func(preData, data)
			return preData[key] == data[key]
		end
	end

	for i, v in ipairs(data) do
		local preData = data[i - 1]

		if preData and func(preData, v) then
			v.index = preData.index
		else
			v.index = i
		end
	end
end
