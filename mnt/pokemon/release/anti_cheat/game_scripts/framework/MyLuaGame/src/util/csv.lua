if device.platform == "windows" then
	require("easy.table_override")
end

local var_0_0 = lua_type
local var_0_1 = {
	__size = true,
	__sorted = true,
	__default = true
}
local var_0_2 = {
	__size = true,
	mp1MaxC = true,
	hpMaxC = true,
	roomIdx = true,
	__default = true,
	__sorted = true,
	yunying = true
}
local var_0_3 = {}

function globals.getCsv(arg_1_0)
	if arg_1_0 == nil then
		return nil
	end

	if var_0_3[arg_1_0] then
		return var_0_3[arg_1_0]
	end

	var_0_3[arg_1_0] = loadstring("return " .. arg_1_0)()

	return var_0_3[arg_1_0]
end

function globals.getMonsterCsv(arg_2_0)
	if arg_2_0 == nil then
		return nil
	end

	local var_2_0 = string.gsub(arg_2_0, "%.", function(arg_3_0)
		return "_"
	end)
	local var_2_1 = "csv.Load" .. string.sub(var_2_0, 5)

	return loadstring(var_2_1 .. "() return " .. arg_2_0)()
end

function globals.csvSize(arg_4_0)
	if arg_4_0.__size == nil then
		local var_4_0 = 0

		for iter_4_0, iter_4_1 in csvMapPairs(arg_4_0) do
			var_4_0 = var_4_0 + 1
		end

		return var_4_0
	end

	return arg_4_0.__size
end

function globals.csvNext(arg_5_0)
	local var_5_0, var_5_1 = next(arg_5_0)

	while var_5_0 and string.sub(var_5_0, 1, 2) == "__" do
		var_5_0, var_5_1 = next(arg_5_0, var_5_0)
	end

	return var_5_0, var_5_1
end

function globals.csvPairs(arg_6_0)
	return function(arg_7_0, arg_7_1)
		local var_7_0, var_7_1 = next(arg_6_0, arg_7_1)

		while var_7_0 ~= nil and var_0_0(var_7_0) ~= "number" do
			var_7_0, var_7_1 = next(arg_6_0, var_7_0)
		end

		return var_7_0, var_7_1
	end, arg_6_0, nil
end

function globals.csvMapPairs(arg_8_0)
	return function(arg_9_0, arg_9_1)
		local var_9_0, var_9_1 = next(arg_8_0, arg_9_1)

		while var_9_0 and string.sub(var_9_0, 1, 2) == "__" do
			var_9_0, var_9_1 = next(arg_8_0, var_9_0)
		end

		return var_9_0, var_9_1
	end, arg_8_0, nil
end

function globals.orderCsvPairs(arg_10_0)
	if arg_10_0.__sorted == nil then
		local var_10_0 = {}

		for iter_10_0, iter_10_1 in pairs(arg_10_0) do
			if var_0_0(iter_10_0) == "number" then
				table.insert(var_10_0, iter_10_0)
			end
		end

		table.sort(var_10_0)

		arg_10_0.__sorted = var_10_0
	end

	local var_10_1

	return function(arg_11_0, arg_11_1)
		local var_11_0, var_11_1 = next(arg_10_0.__sorted, var_10_1)

		var_10_1 = var_11_0

		return var_11_1, arg_10_0[var_11_1]
	end, arg_10_0, nil
end

local function var_0_4(arg_12_0)
	local var_12_0 = arg_12_0

	arg_12_0 = table.getraw(arg_12_0)

	while arg_12_0 ~= var_12_0 do
		var_12_0 = arg_12_0
		arg_12_0 = table.getraw(arg_12_0)
	end

	return arg_12_0
end

function globals.csvClone(arg_13_0)
	if not arg_13_0 then
		return nil
	end

	if var_0_0(arg_13_0) ~= "table" then
		return arg_13_0
	end

	local function var_13_0(arg_14_0)
		local var_14_0 = {}
		local var_14_1, var_14_2 = getmetatable(var_0_4(arg_14_0))

		if var_14_1 and var_0_0(var_14_1.__index) == "table" then
			var_14_2 = var_14_1.__index
		end

		for iter_14_0, iter_14_1 in pairs(arg_14_0) do
			if var_0_0(iter_14_1) == "table" then
				var_14_0[iter_14_0] = var_13_0(iter_14_1)
			else
				var_14_0[iter_14_0] = iter_14_1
			end
		end

		if var_14_2 then
			local var_14_3 = var_13_0(var_14_2)

			for iter_14_2, iter_14_3 in pairs(var_14_3) do
				if var_14_0[iter_14_2] == nil then
					var_14_0[iter_14_2] = iter_14_3
				end
			end
		end

		for iter_14_4, iter_14_5 in pairs(var_0_1) do
			var_14_0[iter_14_4] = nil
		end

		return var_14_0
	end

	return var_13_0(arg_13_0)
end

function globals.csvNumSum(arg_15_0)
	if var_0_0(arg_15_0) ~= "table" then
		return nil
	end

	local var_15_0 = 0

	for iter_15_0, iter_15_1 in pairs(arg_15_0) do
		if not var_0_1[iter_15_0] then
			local var_15_1 = var_0_0(iter_15_1)

			if var_15_1 == "number" then
				var_15_0 = var_15_0 + iter_15_1
			elseif var_15_1 == "table" then
				var_15_0 = var_15_0 + csvNumSum(iter_15_1)
			end
		end
	end

	return var_15_0
end

function globals.csvReadOnlyInWindows(arg_16_0, arg_16_1)
	if device.platform == "windows" then
		-- block empty
	end

	do return arg_16_0 end
	return table.proxytable(arg_16_0, nil, nil, function(arg_17_0, arg_17_1, arg_17_2)
		if var_0_2[arg_17_1] then
			return true
		end

		error(string.format("dont write %s in read only mode! do not set %s, %s!", arg_16_1, arg_17_1, arg_17_2))
	end)
end

function globals.csvSetDefalutMeta(arg_18_0)
	if arg_18_0.__default then
		for iter_18_0, iter_18_1 in pairs(arg_18_0) do
			if var_0_0(iter_18_0) == "number" and var_0_0(iter_18_1) == "table" then
				setmetatable(iter_18_1, arg_18_0.__default)
			end
		end
	end
end

function globals.csvReset(arg_19_0)
	arg_19_0 = var_0_4(arg_19_0)
	arg_19_0.__sorted = nil
	arg_19_0.__size = nil
	arg_19_0.__size = csvSize(arg_19_0)

	csvSetDefalutMeta(arg_19_0)
end


----------------------------------------------------------------
-- 把 src 的记录追加到 dst（两个表不会有 id 冲突）
-- 仅拷贝“普通记录”（非 "__" 开头的键），保持原始键值（数字/字符串）。
-- 追加完成后会自动 csvReset(dst)。
----------------------------------------------------------------
local function _is_meta_key(k)
  return type(k) == "string" and string.sub(k, 1, 2) == "__"
end

function globals.csvAppendNoConflict(dst, src, set_id_when_numeric)
  assert(type(dst)=="table" and type(src)=="table", "csvAppendNoConflict: expect two tables")

  local set_id = set_id_when_numeric == true
  for k, v in pairs(src) do
    if not _is_meta_key(k) then
      -- 因为保证不冲突，直接塞
      dst[k] = v
      -- 如果需要把记录里的 id 字段补齐成 key
      if set_id and type(k)=="number" and type(v)=="table" and v.id == nil then
        v.id = k
      end
    end
  end

  if csvReset then csvReset(dst) end
  return dst
end

