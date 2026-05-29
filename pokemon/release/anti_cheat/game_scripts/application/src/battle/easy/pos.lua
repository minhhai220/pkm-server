-- chunkname: @src.battle.easy.pos

function battleEasy.getRowAndColumn(idOrObj)
	local seat = idOrObj

	if type(idOrObj) ~= "number" then
		seat = idOrObj.seat
	end

	local rowNum = 2 - math.floor((seat + 2) / 3) % 2
	local columnNum = (seat - 1) % 3 + 1

	return rowNum, columnNum
end

local mirrorTb = {
	7,
	8,
	9,
	10,
	11,
	12,
	1,
	2,
	3,
	4,
	5,
	6,
	14,
	13
}

function battleEasy.mirrorSeat(seat)
	return mirrorTb[seat]
end

function battleEasy.exactSeat(force, seat)
	local forceNumber = battlePlay.Gate.ForceNumber

	if forceNumber < seat then
		seat = seat - forceNumber
	end

	return (force - 1) * forceNumber + seat
end

function battleEasy.getPos(index, posAdjust)
	posAdjust = posAdjust or cc.p(0, 0)

	if index >= 1 and index <= 12 or index == 13 or index == 14 or index == 99 then
		if index >= 7 and index <= 12 then
			return display.width - battle.StandingPos[index - 6].x + posAdjust.x, battle.StandingPos[index - 6].y + posAdjust.y
		end

		return battle.StandingPos[index].x + posAdjust.x, battle.StandingPos[index].y + posAdjust.y
	elseif index >= 101 and index <= 112 then
		local seat = index - 100

		if seat >= 7 and seat <= 12 then
			return display.width - battle.AttackPos[seat - 6].x + posAdjust.x, battle.AttackPos[seat - 6].y + posAdjust.y
		end

		return battle.AttackPos[seat].x + posAdjust.x, battle.AttackPos[seat].y + posAdjust.y
	end
end

function battleEasy.getAttackPos(index, posAdjust)
	return battleEasy.getPos(index + 100, posAdjust)
end
