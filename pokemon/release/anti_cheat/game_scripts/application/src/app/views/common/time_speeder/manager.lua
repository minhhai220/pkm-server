-- chunkname: @src.app.views.common.time_speeder.manager

local scheduler = display.director:getScheduler()
local originSetTimeScale = scheduler.setTimeScale
local originGetTimeScale = scheduler.getTimeScale
local timeScale = 1
local timeSpeed = 1
local timeRate = 1
local speedUp = 1
local speedEnable = false
local yieldRef = 0

local function updateSpeedUp()
    speedUp = timeScale
    
    if yieldRef <= 0 and speedEnable then
        speedUp = (1 + (timeSpeed - 1) * timeRate) * timeScale
    end
    
    printInfo("加速计算 - timeScale:%s, timeSpeed:%s, timeRate:%s, yieldRef:%s, speedEnable:%s, 最终速度:%s", 
        timeScale, timeSpeed, timeRate, yieldRef, speedEnable, speedUp)
    
    if scheduler.setSpeedUp then
        scheduler:setSpeedUp(speedUp)
    else
        -- 如果没有setSpeedUp方法，使用原始方法
        originSetTimeScale(scheduler, speedUp)
    end
end

local function getTimeScale(scheduler)
	return timeScale
end

local function setTimeScale(scheduler, scale)
	timeScale = scale

	if scheduler.setSpeedUp then
		updateSpeedUp()
	else
		originSetTimeScale(scheduler, scale)
	end
end

function scheduler.getSpeedUp(scheduler)
	return speedUp
end

local TimeSpeederManager = class("TimeSpeederManager")

function TimeSpeederManager:ctor()
	scheduler.getTimeScale = getTimeScale
	scheduler.setTimeScale = setTimeScale
end

function TimeSpeederManager:onClose()
	self.clearSpeeder()

	scheduler.setTimeScale = originSetTimeScale
	scheduler.getTimeScale = originGetTimeScale
end

function TimeSpeederManager.setTimeRate(val)
	timeRate = val

	updateSpeedUp()
end

function TimeSpeederManager.setTimeSpeed(val)
	timeSpeed = val

	updateSpeedUp()
end

function TimeSpeederManager.getTimeSpeedEnabled()
	return speedEnable
end

function TimeSpeederManager.setTimeSpeedEnabled(enabled)
	speedEnable = enabled

	updateSpeedUp()
end

function TimeSpeederManager.yieldSpeeder()
	yieldRef = yieldRef + 1

	updateSpeedUp()
end

function TimeSpeederManager.resumeSpeeder()
	yieldRef = math.max(0, yieldRef - 1)

	updateSpeedUp()
end

function TimeSpeederManager.isYield()
	return yieldRef > 0
end

function TimeSpeederManager.clearSpeeder()
	speedEnable = false
	timeSpeed = 1
	timeRate = 1
	yieldRef = 0

	updateSpeedUp()
end

function TimeSpeederManager.get3rdSpeedScale(time, cb)
	local startTime = socket.gettime()
	local sumDt = 0
	local times = time * 60
	local countTimeId

	countTimeId = scheduler:scheduleScriptFunc(function(dt)
		sumDt = sumDt + dt
		times = times - 1

		if times == 0 then
			scheduler:unscheduleScriptEntry(countTimeId)

			local now = socket.gettime()
			local timeScale = mathEasy.getPreciseDecimal(sumDt / (now - startTime) / scheduler:getTimeScale(), 0, true)

			printInfo("第三方加速器倍速:" .. timeScale)

			if cb then
				cb(timeScale)
			end
		end
	end, 0, false)
end

return TimeSpeederManager
