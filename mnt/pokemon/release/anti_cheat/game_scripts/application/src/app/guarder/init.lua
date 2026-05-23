-- chunkname: @src.app.guarder.init

local fixEnKofiEntryID

local function fix_en_kofi()
	-- local ret, err = pcall(function()
	-- 	require("kofi")
	-- end)

	-- if err and string.find(err, "not found") == nil then
	-- 	display.director:endToLua()
	-- end

	-- if not fixEnKofiEntryID then
	-- 	local cnt = 1

	-- 	fixEnKofiEntryID = display.director:getScheduler():scheduleScriptFunc(function()
	-- 		if globals.gKofiParams ~= nil then
	-- 			display.director:endToLua()
	-- 		end

	-- 		if gGameUI.scene then
	-- 			if gGameUI.scene:getChildByName("kofi") ~= nil then
	-- 				display.director:endToLua()
	-- 			end

	-- 			cnt = cnt + 1

	-- 			if cnt > 10 then
	-- 				display.director:getScheduler():unscheduleScriptEntry(fixEnKofiEntryID)
	-- 			end
	-- 		end
	-- 	end, 5, false)
	-- end
end

local function init()
	print("app guarder init")
	-- fix_en_kofi()

	-- local guarder = require("util.guarder")

	-- guarder.check_main_stack()
	-- guarder.check_proc_maps(function(maps)
	-- 	return string.find(maps, "kofi") or string.find(maps, "koofi")
	-- end)
end

local function check()
	print("app guarder check")
	-- fix_en_kofi()
end

-- init()

return check
