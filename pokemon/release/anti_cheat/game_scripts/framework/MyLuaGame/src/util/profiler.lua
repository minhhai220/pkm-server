local var_0_0 = {}

globals.tjprofiler = var_0_0

if device.platform ~= "windows" or ANTI_AGENT then
	local function var_0_1()
		return
	end

	var_0_0.nInc = var_0_1
	var_0_0.tBegin = var_0_1
	var_0_0.tEnd = var_0_1
	var_0_0.tAuto = var_0_1

	return
end

local var_0_2 = {}
local var_0_3 = {}
local var_0_4 = {}
local var_0_5 = {}
local var_0_6 = false
local var_0_7
local var_0_8
local var_0_9
local var_0_10
local var_0_11 = {}
local var_0_12 = 0
local var_0_13 = os.clock

if cc.utils and cc.utils.gettime then
	function var_0_13()
		return cc.utils:gettime()
	end
end

local var_0_14
local var_0_15

local function var_0_16(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local var_3_0 = arg_3_1()

	for iter_3_0 = 1, arg_3_2 do
		arg_3_0()
	end

	local var_3_1 = arg_3_1() - var_3_0

	if arg_3_3 then
		print("!!!", arg_3_3, var_3_1, "qps", arg_3_2 / var_3_1)
	end

	return arg_3_2 / var_3_1, var_3_1
end

local var_0_17 = "| TOTAL TIME = %f - (%d / %f QPS) = %f"
local var_0_18 = "| %-60s: %-40s: %-20s: %-12s: %-12s: %-12s: %-12s: %-12s|"
local var_0_19 = "| %-60.60s: %-40.40s: %-20s"
local var_0_20 = "%s: %-12s: %-12s: %-12s: %-12s: %-12s|"
local var_0_21 = "%4i"
local var_0_22 = "%04.3f"
local var_0_23 = "%03.2f%%"

local function var_0_24(arg_4_0)
	local var_4_0 = arg_4_0.name or "anonymous"
	local var_4_1 = arg_4_0.short_src or "C_FUNC"
	local var_4_2 = arg_4_0.linedefined or 0
	local var_4_3 = string.format(var_0_21, var_4_2)

	return string.format(var_0_19, var_4_1, var_4_0, var_4_3)
end

local function var_0_25(arg_5_0)
	var_0_12 = var_0_12 + 1

	if var_0_12 > #var_0_11 then
		table.insert(var_0_11, {
			lastElapse = 0,
			drillCount = 1,
			st = {},
			stAuto = {}
		})
	end

	local var_5_0 = var_0_11[var_0_12]

	table.clear(var_5_0.st)
	table.clear(var_5_0.stAuto)

	var_5_0.g = arg_5_0
	var_5_0.lastElapse = 0
	var_5_0.drillCount = 1
	var_0_7 = arg_5_0
	var_0_8 = var_5_0.st
	var_0_9 = var_5_0.stAuto
	var_0_6 = var_0_7 == var_0_5

	return var_5_0
end

local function var_0_26()
	local var_6_0 = var_0_11[var_0_12]

	var_0_12 = var_0_12 - 1

	local var_6_1

	if var_0_12 > 0 then
		var_6_1 = var_0_11[var_0_12]
		var_0_7 = var_6_1.g
		var_0_8 = var_6_1.st
		var_0_9 = var_6_1.stAuto
		var_6_1.drillCount = var_6_1.drillCount + var_6_0.drillCount
		var_0_6 = var_0_7 == var_0_5
	end

	return var_6_0, var_6_1
end

local function var_0_27(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = var_0_13() - arg_7_0[arg_7_2]

	arg_7_0[arg_7_2] = nil

	if arg_7_3 then
		local var_7_1 = arg_7_1[arg_7_2]

		if var_7_1 == nil then
			var_7_1 = {
				count = 0,
				timer = 0
			}
			arg_7_1[arg_7_2] = var_7_1
		end

		var_7_1.count = var_7_1.count + arg_7_3
		var_7_1.timer = var_7_1.timer + var_7_0
	else
		arg_7_1[arg_7_2] = (arg_7_1[arg_7_2] or 0) + var_7_0
	end
end

local function var_0_28(arg_8_0)
	local var_8_0 = debug.getinfo(arg_8_0, "nSl")

	if var_8_0 then
		local var_8_1 = var_8_0.short_src or "[C]"

		if var_8_1:find("profiler") then
			arg_8_0 = arg_8_0 + 1
			var_8_0 = debug.getinfo(arg_8_0, "nSl")
			var_8_1 = var_8_0.short_src or "[C]"
		end

		local var_8_2 = var_8_0.name or "anonymous"
		local var_8_3 = var_8_0.currentline

		return string.format("%s %s:%d", var_8_1, var_8_2, var_8_3)
	end
end

local function var_0_29(arg_9_0)
	local var_9_0 = {}
	local var_9_1 = 8

	for iter_9_0, iter_9_1 in pairs(arg_9_0) do
		local var_9_2 = tostring(iter_9_0)

		if #var_9_2 > 64 then
			var_9_2 = string.sub(var_9_2, #var_9_2 - 64)
		end

		var_9_1 = math.max(#var_9_2, var_9_1)
		var_9_0[iter_9_0] = var_9_2
	end

	local var_9_3 = {}

	for iter_9_2, iter_9_3 in pairs(arg_9_0) do
		if type(iter_9_3) == "table" and iter_9_3.timer and iter_9_3.count then
			iter_9_3.key = iter_9_2

			table.insert(var_9_3, iter_9_3)
		end
	end

	local var_9_4 = string.format("%%-%ds = %%s", var_9_1 + 5)

	if #var_9_3 > 0 then
		table.sort(var_9_3, function(arg_10_0, arg_10_1)
			return arg_10_0.timer > arg_10_1.timer
		end)

		local var_9_5 = #var_9_3
		local var_9_6 = {
			all_count = 0,
			timer = 0,
			count = 0,
			all_timer = 0
		}

		for iter_9_4, iter_9_5 in ipairs(var_9_3) do
			var_9_6.all_timer = var_9_6.all_timer + iter_9_5.timer
			var_9_6.all_count = var_9_6.all_count + iter_9_5.count
		end

		var_9_6.all_timer = var_9_6.all_timer - var_9_6.all_count / var_0_14

		for iter_9_6, iter_9_7 in ipairs(var_9_3) do
			if iter_9_6 > 6 or iter_9_7.timer < 0.001 and iter_9_7.count < 100 then
				var_9_5 = iter_9_6 - 1

				break
			end

			var_9_6.timer = var_9_6.timer + iter_9_7.timer
			var_9_6.count = var_9_6.count + iter_9_7.count

			local var_9_7 = string.format("%-10.2f %12d", iter_9_7.timer, iter_9_7.count)

			var_9_3[iter_9_6] = string.format(var_9_4, var_9_0[iter_9_7.key], var_9_7)
		end

		var_9_6.timer = var_9_6.timer - var_9_6.count / var_0_14

		if var_9_5 == 0 then
			return ""
		end

		local var_9_8 = string.format("%.2f/%.2f %.2f%% %12d/%d %.2f%%", var_9_6.timer, var_9_6.all_timer, 100 * var_9_6.timer / var_9_6.all_timer, var_9_6.count, var_9_6.all_count, 100 * var_9_6.count / var_9_6.all_count)

		var_9_3[var_9_5 + 1] = string.format(var_9_4, "TOP6SUM", var_9_8)

		return table.concat(var_9_3, "\n", 1, var_9_5 + 1)
	end

	local var_9_9 = {}

	for iter_9_8, iter_9_9 in pairs(arg_9_0) do
		if type(iter_9_9) == "number" then
			table.insert(var_9_9, iter_9_8)
		else
			local var_9_10 = ""

			if type(iter_9_9) == "table" then
				var_9_10 = dumps(iter_9_9)
			else
				var_9_10 = tostring(iter_9_9)
			end

			table.insert(var_9_3, string.format(var_9_4, var_9_0[iter_9_8], var_9_10))
		end
	end

	table.sort(var_9_9, function(arg_11_0, arg_11_1)
		return arg_9_0[arg_11_0] > arg_9_0[arg_11_1]
	end)

	for iter_9_10, iter_9_11 in ipairs(var_9_9) do
		var_9_9[iter_9_10] = string.format(var_9_4, var_9_0[iter_9_11], tostring(arg_9_0[iter_9_11]))
	end

	if #var_9_9 > 0 then
		return table.concat(var_9_9, "\n") .. "\n" .. table.concat(var_9_3, "\n")
	end

	return table.concat(var_9_3, "\n")
end

local var_0_30 = 0

local function var_0_31(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = debug.getinfo(arg_12_1, "nS")

	var_12_0.name = arg_12_0

	local var_12_1 = type(arg_12_2) == "function"
	local var_12_2 = type(arg_12_2) == "table"
	local var_12_3 = var_12_1 or var_12_2
	local var_12_4 = {
		dcount = 0,
		timer = 0,
		count = 0,
		selftimer = 0,
		title = var_0_24(var_12_0),
		hook = var_12_2 and arg_12_2 or {},
		fhook = {}
	}
	local var_12_5 = var_12_4.hook
	local var_12_6 = var_12_4.fhook

	return function(...)
		local var_13_0 = select("#", ...)
		local var_13_1 = {
			...
		}
		local var_13_2 = var_0_13()

		var_0_25(var_12_3 and var_12_5 or var_0_5)

		local var_13_3

		local function var_13_4(arg_14_0)
			if arg_14_0:find("PROFILE") == nil then
				var_13_3 = "PROFILE XPCALL ERR: " .. arg_14_0

				print(var_13_3)
				print(debug.traceback())
			else
				var_13_3 = arg_14_0
			end
		end

		local var_13_5, var_13_6, var_13_7, var_13_8, var_13_9, var_13_10 = xpcall(function()
			return arg_12_1(unpack(var_13_1, 1, var_13_0))
		end, var_13_4)

		if var_12_3 then
			for iter_13_0, iter_13_1 in pairs(var_0_9) do
				var_0_27(var_0_9, var_0_7, iter_13_0, 1)
			end
		end

		local var_13_11, var_13_12 = var_0_26()

		var_0_30 = var_0_30 + 1
		var_12_4.count = var_12_4.count + 1
		var_12_4.dcount = var_12_4.dcount + var_13_11.drillCount

		local var_13_13 = var_0_13() - var_13_2

		var_12_4.timer = var_12_4.timer + var_13_13
		var_12_4.selftimer = var_12_4.selftimer + math.max(0, var_13_13 - var_13_11.lastElapse)

		if var_13_12 then
			var_13_12.lastElapse = var_13_12.lastElapse + var_13_13
		end

		if var_12_1 then
			arg_12_2(var_12_6, var_13_13, ...)
		end

		if var_13_3 then
			error(var_13_3)
		end

		if var_13_10 == nil then
			if var_13_9 == nil then
				if var_13_8 == nil then
					if var_13_7 == nil then
						return var_13_6
					end

					return var_13_6, var_13_7
				end

				return var_13_6, var_13_7, var_13_8
			end

			return var_13_6, var_13_7, var_13_8, var_13_9
		end

		return var_13_6, var_13_7, var_13_8, var_13_9, var_13_10
	end, var_12_4
end

local var_0_32 = var_0_31("__test__", function(arg_16_0, arg_16_1, arg_16_2)
	return 0 + arg_16_0 + arg_16_1 + arg_16_2
end)
local var_0_33

var_0_14, var_0_33 = var_0_16(function()
	var_0_32(1, 2, 3)
end, var_0_13, 10000)

print("util.profiler wrapFuncQPS", var_0_33, var_0_14)

function var_0_0.class(arg_18_0, arg_18_1)
	if var_0_3[arg_18_0] then
		return
	end

	local var_18_0 = {}
	local var_18_1 = ""

	if arg_18_0.__cname then
		var_18_1 = arg_18_0.__cname .. "."
	end

	arg_18_1 = arg_18_1 or {}

	for iter_18_0, iter_18_1 in pairs(arg_18_0) do
		if type(iter_18_1) == "function" and var_0_4[iter_18_1] == nil then
			local var_18_2, var_18_3 = var_0_31(string.format("%s%s", var_18_1, iter_18_0), iter_18_1, arg_18_1[iter_18_0])

			var_0_4[iter_18_1] = var_18_3
			var_18_0[iter_18_0] = iter_18_1
			arg_18_0[iter_18_0] = var_18_2
		end
	end

	var_0_3[arg_18_0] = var_18_0
end

function var_0_0.func(arg_19_0, arg_19_1)
	local var_19_0 = globals
	local var_19_1 = arg_19_0
	local var_19_2 = globals[arg_19_0]

	if var_19_2 == nil and arg_19_0:find("%.") then
		local var_19_3 = arg_19_0:sub(1, arg_19_0:find("%.") - 1)

		var_19_0 = globals[var_19_3]

		if var_19_0 == nil then
			error("no such module " .. var_19_3)
		end

		var_19_1 = arg_19_0:sub(1 + arg_19_0:find("%."))
		var_19_2 = var_19_0[var_19_1]
	end

	if var_19_2 == nil then
		error("only global function could be profiler " .. arg_19_0)
	end

	if var_0_4[var_19_2] then
		return
	end

	local var_19_4, var_19_5 = var_0_31(arg_19_0, var_19_2, arg_19_1)

	var_19_0[var_19_1] = var_19_4
	var_0_4[var_19_2] = var_19_5
end

function var_0_0.memberfunc(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = arg_20_0[arg_20_1]

	if var_20_0 == nil then
		error("only member function could be profiler " .. arg_20_1)
	end

	if var_0_4[var_20_0] then
		return
	end

	local var_20_1, var_20_2 = var_0_31(arg_20_1, var_20_0, arg_20_2)

	arg_20_0[arg_20_1] = var_20_1
	var_0_4[var_20_0] = var_20_2
end

local var_0_34

local function var_0_35(arg_21_0, arg_21_1)
	arg_21_1 = arg_21_1 or print

	arg_21_1(arg_21_0)

	if var_0_34 then
		var_0_34:write(arg_21_0)
		var_0_34:write("\n")
	end
end

function var_0_0.start()
	var_0_10 = var_0_13()
	var_0_12 = 0
	var_0_5 = {}
	var_0_6 = false
	var_0_7, var_0_8, var_0_9 = nil
end

function var_0_0.nInc(arg_23_0, arg_23_1)
	if var_0_6 or var_0_10 == nil then
		return
	end

	arg_23_1 = arg_23_1 or 1
	var_0_7[arg_23_0] = (var_0_7[arg_23_0] or 0) + arg_23_1
end

function var_0_0.tBegin(arg_24_0, arg_24_1)
	if var_0_6 or var_0_10 == nil then
		return
	end

	local var_24_0 = arg_24_1

	if arg_24_0 ~= "" then
		var_24_0 = string.format("%s/%s", arg_24_0, arg_24_1)
	end

	var_0_8[var_24_0] = var_0_13()
end

function var_0_0.tEnd(arg_25_0, arg_25_1, arg_25_2)
	if var_0_6 or var_0_10 == nil then
		return
	end

	local var_25_0 = arg_25_1

	if arg_25_0 ~= "" then
		var_25_0 = string.format("%s/%s", arg_25_0, arg_25_1)
	end

	return var_0_27(var_0_8, var_0_7, var_25_0, arg_25_2)
end

function var_0_0.tAuto(arg_26_0)
	if var_0_6 or var_0_10 == nil then
		return
	end

	var_0_9[arg_26_0] = var_0_13()
end

function var_0_0.stop(arg_27_0)
	local var_27_0 = var_0_13() - var_0_10

	arg_27_0 = (arg_27_0 or "") .. ".profiler.txt"

	local var_27_1, var_27_2 = io.open(arg_27_0, "w")

	assert(var_27_1, var_27_2)

	var_0_34 = var_27_1

	local var_27_3 = {}

	for iter_27_0, iter_27_1 in pairs(var_0_4) do
		table.insert(var_27_3, iter_27_0)

		if iter_27_1.count > 0 then
			iter_27_1.timer = iter_27_1.timer - iter_27_1.dcount / var_0_14
			iter_27_1.selftimer = iter_27_1.selftimer - iter_27_1.count / var_0_14
		end
	end

	table.sort(var_27_3, function(arg_28_0, arg_28_1)
		local var_28_0 = var_0_4[arg_28_0].timer - var_0_4[arg_28_1].timer

		if math.abs(var_28_0) < 1e-05 then
			return var_0_4[arg_28_0].count > var_0_4[arg_28_1].count
		end

		return var_28_0 > 0
	end)

	local var_27_4 = var_27_0 - var_0_30 / var_0_14
	local var_27_5 = string.format(var_0_17, var_27_0, var_0_30, var_0_14, var_27_4)

	var_0_35(var_27_5)

	local var_27_6 = string.format(var_0_18, "FILE", "FUNCTION", "LINE", "SELFTIME", "TIME", "RELATIVE", "CALLED", "D-CALLED")

	var_0_35(var_27_6)

	for iter_27_2, iter_27_3 in ipairs(var_27_3) do
		local var_27_7 = var_0_4[iter_27_3]

		if var_27_7.count > 0 and var_27_7.timer > 0.0005 then
			local var_27_8 = string.format(var_0_22, var_27_7.timer)
			local var_27_9 = string.format(var_0_22, var_27_7.selftimer)
			local var_27_10 = string.format(var_0_23, var_27_7.timer / var_27_4 * 100)

			var_0_35(string.format(var_0_20, var_27_7.title, var_27_9, var_27_8, var_27_10, var_27_7.count, var_27_7.dcount))

			local var_27_11 = false

			if table.nums(var_27_7.fhook) > 0 then
				local var_27_12 = var_0_29(var_27_7.fhook)

				var_0_35(var_27_12, release_print)

				var_27_11 = true
			end

			if table.nums(var_27_7.hook) > 0 then
				var_0_35("internal:", release_print)

				local var_27_13 = var_0_29(var_27_7.hook)

				var_0_35(var_27_13, release_print)

				var_27_11 = true
			end

			if var_27_11 then
				var_0_35("", release_print)
			end
		end
	end

	if var_27_1 then
		var_27_1:close()

		var_0_34 = nil
		var_0_10 = nil
	end
end

function var_0_2.nCallFrom(arg_29_0)
	return function(arg_30_0)
		local var_30_0 = var_0_28(arg_29_0)

		arg_30_0[var_30_0] = (arg_30_0[var_30_0] or 0) + 1
	end
end

function var_0_0.initBattleAll()
	require("battle.app_views.battle.battle_entrance.include")
	var_0_0.func("addBuffToHero")
	var_0_0.func("addBuffToScene")
	var_0_0.func("addAuraBuffToHero")
	var_0_0.func("newTargetFinder")
	var_0_0.func("newTargetTypeFinder")
	var_0_0.memberfunc(battleSkill.SkillModel, "processAfterObjTrigger")
	var_0_0.memberfunc(BuffModel, "cfg2Value")
end

local function var_0_36(arg_32_0, arg_32_1, arg_32_2)
	local var_32_0 = arg_32_0[arg_32_2]

	if var_32_0 == nil then
		var_32_0 = {
			count = 0,
			timer = 0
		}
		arg_32_0[arg_32_2] = var_32_0
	end

	var_32_0.count = var_32_0.count + 1
	var_32_0.timer = var_32_0.timer + arg_32_1
end

function var_0_0.initBattle()
	require("battle.app_views.battle.battle_entrance.include")

	local function var_33_0(arg_34_0, arg_34_1, arg_34_2, ...)
		if not arg_34_2 then
			return
		end

		local var_34_0 = arg_34_2

		if type(arg_34_2) == "table" then
			var_34_0 = ""

			for iter_34_0, iter_34_1 in ipairs(arg_34_2) do
				var_34_0 = string.format("[%x]=%s;%s", iter_34_0, iter_34_1, var_34_0)
			end
		end

		var_0_36(arg_34_0, arg_34_1, var_34_0)
	end

	var_0_0.func("battleCsv.doFormula", var_33_0)
	var_0_0.func("battleEasy.calcStrValue")
	var_0_0.func("battleEasy.runDamageProcess")

	local function var_33_1(arg_35_0, arg_35_1, arg_35_2, ...)
		local var_35_0 = tostring(arg_35_2) .. "-" .. csv.buff[arg_35_2].easyEffectFunc

		var_0_36(arg_35_0, arg_35_1, var_35_0)
	end

	var_0_0.func("addBuffToHero", var_33_1)

	local function var_33_2(arg_36_0, arg_36_1, arg_36_2, ...)
		local var_36_0 = tostring(arg_36_2.cfgId) .. "-" .. arg_36_2.csvCfg.easyEffectFunc

		var_0_36(arg_36_0, arg_36_1, var_36_0)
	end

	var_0_0.memberfunc(BuffModel, "ctor", var_33_2)
	var_0_0.memberfunc(BuffModel, "init", var_33_2)
	var_0_0.memberfunc(BuffModel, "cfg2Value", var_33_2)
	var_0_0.memberfunc(BuffModel, "over", var_33_2)
	var_0_0.memberfunc(AuraBuffModel, "over", var_33_2)
	var_0_0.memberfunc(BuffNodeManager, "init")
	var_0_0.memberfunc(BuffNodeManager, "check")

	local function var_33_3(arg_37_0, arg_37_1, arg_37_2, ...)
		local var_37_0 = tostring(arg_37_2.id) .. "-" .. arg_37_2.cfg.skillName

		var_0_36(arg_37_0, arg_37_1, var_37_0)
	end

	var_0_0.memberfunc(battleSkill.SkillModel, "spellTo", var_33_3)
	var_0_0.memberfunc(battleSkill.SkillModel, "processAddBuff", var_33_3)
	var_0_0.memberfunc(ObjectModel, "init")
	var_0_0.memberfunc(ObjectModel, "onNewBattleTurn")
	var_0_0.memberfunc(ObjectModel, "onBattleTurnEnd")
	var_0_0.memberfunc(SceneModel, "updateBuffEveryTurn")
	var_0_0.memberfunc(SceneModel, "endBattleTurn")
	var_0_0.memberfunc(SceneModel, "onAllPassive")
	var_0_0.memberfunc(battlePlay.Gate, "onNewRound")
	var_0_0.memberfunc(battlePlay.Gate, "onNewBattleTurn")
	var_0_0.memberfunc(battlePlay.Gate, "endBattleTurn")
	var_0_0.memberfunc(battlePlay.Gate, "onTurnEndSupply")
end
