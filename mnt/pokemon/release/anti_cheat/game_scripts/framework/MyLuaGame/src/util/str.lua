local var_0_0 = string.format
local var_0_1 = string.find
local var_0_2 = string.sub
local var_0_3 = table.concat
local var_0_4 = table.remove
local var_0_5 = itertools.isarray

function string.caption(arg_1_0)
	return string.upper(var_0_2(arg_1_0, 1, 1)) .. var_0_2(arg_1_0, 2)
end

local function var_0_6(arg_2_0)
	if arg_2_0 == nil then
		return "nil"
	end

	if type(arg_2_0) == "table" then
		local var_2_0 = arg_2_0

		if var_0_5(var_2_0) then
			local var_2_1 = {}

			for iter_2_0, iter_2_1 in ipairs(var_2_0) do
				var_2_1[iter_2_0] = var_0_6(iter_2_1)
			end

			return var_0_0("{%s}", var_0_3(var_2_1, ", "))
		else
			return dumps(var_2_0)
		end
	end

	return dumps(arg_2_0)
end

function string.structformat(arg_3_0, arg_3_1, arg_3_2)
	arg_3_2 = arg_3_2 or function(arg_4_0, arg_4_1)
		return arg_4_0[arg_4_1]
	end

	return arg_3_0:gsub("{([%w_.]+)}", function(arg_5_0)
		local var_5_0 = tonumber(arg_5_0)

		if var_5_0 ~= nil then
			arg_5_0 = var_5_0
		end

		local var_5_1 = arg_3_2(arg_3_1, arg_5_0)

		if var_5_1 == nil then
			if type(arg_5_0) == "string" then
				var_5_1 = arg_3_1

				for iter_5_0 in arg_5_0:gmatch("([^.]+)") do
					iter_5_0 = tonumber(iter_5_0) or iter_5_0
					var_5_1 = arg_3_2(var_5_1, iter_5_0)

					if var_5_1 == nil then
						return ""
					end
				end
			end

			return var_0_6(var_5_1)
		end

		return var_0_6(var_5_1)
	end)
end

function string.formatex(arg_6_0, ...)
	local var_6_0 = {
		...
	}

	if type(var_6_0[1]) == "table" then
		local var_6_1 = clone(var_6_0[1])

		for iter_6_0, iter_6_1 in pairs(var_6_1) do
			var_6_1[iter_6_0] = string.gsub(iter_6_1, "%%", "%%%%")
		end

		local var_6_2 = {}
		local var_6_3 = var_0_1(arg_6_0, "{")
		local var_6_4 = var_0_1(arg_6_0, "}", var_6_3)

		while var_6_3 and var_6_4 do
			local var_6_5 = var_0_2(arg_6_0, var_6_3 + 1, var_6_4 - 1)

			if var_6_1[var_6_5] then
				var_6_2[#var_6_2 + 1] = var_0_2(arg_6_0, 1, var_6_3 - 1)
				var_6_2[#var_6_2 + 1] = var_6_1[var_6_5]
			else
				var_6_2[#var_6_2 + 1] = var_0_2(arg_6_0, 1, var_6_4)
			end

			arg_6_0 = var_0_2(arg_6_0, var_6_4 + 1)
			var_6_3 = var_0_1(arg_6_0, "{")
			var_6_4 = var_0_1(arg_6_0, "}", var_6_3)
		end

		var_6_2[#var_6_2 + 1] = arg_6_0
		arg_6_0 = var_0_3(var_6_2)

		var_0_4(var_6_0, 1)
	end

	return var_0_0(arg_6_0, unpack(var_6_0))
end

function string.utf8limit(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = 1
	local var_7_1 = 0
	local var_7_2 = 0

	while var_7_0 <= #arg_7_0 do
		local var_7_3 = string.byte(arg_7_0, var_7_0)
		local var_7_4 = string.utf8charlen(var_7_3)

		var_7_2 = var_7_2 + (arg_7_2 and 1 or var_7_4)

		if arg_7_1 < var_7_2 then
			return string.sub(arg_7_0, 1, var_7_0 - 1), var_7_2
		end

		var_7_0 = var_7_0 + var_7_4
	end

	return arg_7_0, var_7_2
end

local var_0_7 = {
	{
		{
			0,
			127
		},
		0
	},
	{
		{
			192,
			223
		},
		1
	},
	{
		{
			224,
			239
		},
		2
	},
	{
		{
			240,
			247
		},
		3
	}
}

function string.isbin(arg_8_0)
	local var_8_0 = 0

	for iter_8_0 = 1, #arg_8_0 do
		local var_8_1 = arg_8_0:byte(iter_8_0)

		if var_8_0 == 0 then
			local var_8_2 = false

			for iter_8_1, iter_8_2 in ipairs(var_0_7) do
				if var_8_1 >= iter_8_2[1][1] and var_8_1 <= iter_8_2[1][2] then
					var_8_0 = iter_8_2[2]
					var_8_2 = true

					break
				end
			end

			if not var_8_2 then
				return true
			end
		else
			if var_8_1 < 128 or var_8_1 > 191 then
				return true
			end

			var_8_0 = var_8_0 - 1
		end
	end

	if var_8_0 == 0 then
		return false
	end

	return true
end

local var_0_8 = string.isbin

function string.isobjectid(arg_9_0)
	return #arg_9_0 == 12 and var_0_8(arg_9_0)
end
