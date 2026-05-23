-- chunkname: @src.app.models.clone_battle

local GameBattleModel = require("app.models.battle")
local CloneBattle = class("CloneBattle", GameBattleModel)

CloneBattle.DefaultGateID = game.GATE_TYPE.clone
CloneBattle.OmitEmpty = false

return CloneBattle
