local var_0_0 = math.min
local var_0_1 = math.max
local var_0_2 = {}

globals.arraytools = var_0_2

function var_0_2.merge(arg_1_0)
	local var_1_0 = {}

	for iter_1_0, iter_1_1 in ipairs(arg_1_0) do
		for iter_1_2, iter_1_3 in ipairs(iter_1_1) do
			table.insert(var_1_0, iter_1_3)
		end
	end

	return var_1_0
end

function var_0_2.merge_inplace(arg_2_0, arg_2_1)
	for iter_2_0, iter_2_1 in ipairs(arg_2_1) do
		for iter_2_2, iter_2_3 in ipairs(iter_2_1) do
			table.insert(arg_2_0, iter_2_3)
		end
	end

	return arg_2_0
end

function var_0_2.merge_two_inplace(arg_3_0, arg_3_1)
	for iter_3_0, iter_3_1 in ipairs(arg_3_1) do
		table.insert(arg_3_0, iter_3_1)
	end

	return arg_3_0
end

function var_0_2.first(arg_4_0, arg_4_1)
	if arg_4_1 == nil then
		return arg_4_0[1]
	end

	arg_4_1 = var_0_0(table.length(arg_4_0), arg_4_1 or 1)

	local var_4_0 = {}

	for iter_4_0 = 1, arg_4_1 do
		table.insert(var_4_0, arg_4_0[iter_4_0])
	end

	return var_4_0
end

function var_0_2.last(arg_5_0, arg_5_1)
	local var_5_0 = table.length(arg_5_0)

	if arg_5_1 == nil then
		return arg_5_0[var_5_0]
	end

	arg_5_1 = var_0_0(var_5_0, arg_5_1 or 1)

	local var_5_1 = {}

	for iter_5_0 = 1 + var_5_0 - arg_5_1, var_5_0 do
		table.insert(var_5_1, arg_5_0[iter_5_0])
	end

	return var_5_1
end

function var_0_2.slice(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = table.length(arg_6_0)
	local var_6_1 = {}

	arg_6_1 = var_0_1(arg_6_1, 1)

	local var_6_2 = var_0_0(arg_6_1 + arg_6_2 - 1, var_6_0)

	for iter_6_0 = arg_6_1, var_6_2 do
		table.insert(var_6_1, arg_6_0[iter_6_0])
	end

	return var_6_1
end

function var_0_2.push(arg_7_0, arg_7_1)
	return table.insert(arg_7_0, arg_7_1)
end

function var_0_2.pop(arg_8_0)
	return table.remove(arg_8_0)
end

function var_0_2.push_front(arg_9_0, arg_9_1)
	return table.insert(arg_9_0, 1, arg_9_1)
end

function var_0_2.pop_front(arg_10_0)
	return table.remove(arg_10_0, 1)
end

function var_0_2.hash(arg_11_0, arg_11_1)
	local var_11_0 = {}

	for iter_11_0, iter_11_1 in ipairs(arg_11_0) do
		var_11_0[iter_11_1] = arg_11_1 and iter_11_0 or true
	end

	return var_11_0
end

function var_0_2.sort_ipairs(arg_12_0, arg_12_1)
	local var_12_0 = {}

	for iter_12_0, iter_12_1 in ipairs(arg_12_0) do
		table.insert(var_12_0, iter_12_1)
	end

	local var_12_1 = arg_12_1

	if type(var_12_1) == "string" then
		function var_12_1(arg_13_0, arg_13_1)
			return arg_13_0[arg_12_1] < arg_13_1[arg_12_1]
		end
	end

	table.sort(var_12_0, var_12_1)

	return ipairs(var_12_0)
end

local var_0_3 = ipairs({})

function var_0_2.map(arg_14_0, arg_14_1)
	local var_14_0 = {}

	for iter_14_0, iter_14_1 in ipairs(arg_14_0) do
		var_14_0[iter_14_0] = arg_14_1(iter_14_0, iter_14_1)
	end

	return var_14_0
end

function var_0_2.reduce(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = arg_15_2

	for iter_15_0, iter_15_1 in ipairs(arg_15_0) do
		if var_15_0 ~= nil then
			var_15_0 = arg_15_1(var_15_0, iter_15_1)
		else
			var_15_0 = iter_15_1
		end
	end

	return var_15_0
end

function var_0_2.filter(arg_16_0, arg_16_1)
	local var_16_0 = {}

	for iter_16_0, iter_16_1 in ipairs(arg_16_0) do
		if arg_16_1(iter_16_0, iter_16_1) then
			table.insert(var_16_0, iter_16_1)
		end
	end

	return var_16_0
end

function var_0_2.each(arg_17_0, arg_17_1)
	for iter_17_0, iter_17_1 in ipairs(arg_17_0) do
		arg_17_1(iter_17_0, iter_17_1)
	end
end

function var_0_2.when(arg_18_0, arg_18_1)
	for iter_18_0, iter_18_1 in ipairs(arg_18_0) do
		if arg_18_1(iter_18_0, iter_18_1) then
			return iter_18_0, iter_18_1
		end
	end
end

function var_0_2.invoke(arg_19_0, arg_19_1)
	for iter_19_0, iter_19_1 in ipairs(arg_19_0) do
		iter_19_1[arg_19_1](iter_19_0, iter_19_1)
	end
end

function var_0_2.values(arg_20_0)
	local var_20_0 = {}

	for iter_20_0, iter_20_1 in ipairs(arg_20_0) do
		table.insert(var_20_0, iter_20_1)
	end

	return var_20_0
end

function var_0_2.ivalues(arg_21_0)
	local var_21_0 = 0
	local var_21_1

	return function()
		var_21_0, var_21_1 = var_0_3(arg_21_0, var_21_0)

		return var_21_0, var_21_1
	end
end

function var_0_2.items(arg_23_0)
	local var_23_0 = {}

	for iter_23_0, iter_23_1 in ipairs(arg_23_0) do
		table.insert(var_23_0, {
			iter_23_0,
			iter_23_1
		})
	end

	return var_23_0
end

function var_0_2.iitems(arg_24_0)
	local var_24_0 = 0
	local var_24_1

	return function()
		var_24_0, var_24_1 = var_0_3(arg_24_0, var_24_0)

		return var_24_0, {
			var_24_0,
			var_24_1
		}
	end
end

function var_0_2.filter_inplace(arg_26_0, arg_26_1)
	local var_26_0 = 1
	local var_26_1 = table.length(arg_26_0)

	for iter_26_0, iter_26_1 in ipairs(arg_26_0) do
		if arg_26_1(iter_26_0, iter_26_1) then
			if iter_26_0 ~= var_26_0 then
				arg_26_0[var_26_0] = arg_26_0[iter_26_0]
			end

			var_26_0 = var_26_0 + 1
		end
	end

	for iter_26_2 = var_26_0, var_26_1 do
		table.remove(arg_26_0)
	end

	return arg_26_0
end

var_0_2.join = table.concat

function var_0_2.compact(arg_27_0)
	for iter_27_0 = table.length(arg_27_0), 1, -1 do
		if arg_27_0[iter_27_0] == nil then
			table.remove(arg_27_0, iter_27_0)
		end
	end

	return arg_27_0
end

function var_0_2.clear(arg_28_0)
	local var_28_0 = table.length(arg_28_0)

	for iter_28_0 = 1, var_28_0 do
		arg_28_0[iter_28_0] = nil
	end

	return arg_28_0
end
