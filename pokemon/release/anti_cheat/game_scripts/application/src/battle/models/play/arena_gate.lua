-- Arena 排位赛关卡
local ArenaGate = class("ArenaGate", battlePlay.Gate)
battlePlay.ArenaGate = ArenaGate

-- 关卡内操作权限
ArenaGate.OperatorArgs = {
  isAuto       = true,
  isFullManual = false,
  canHandle    = false,
  canPause     = false,
  canSpeedAni  = true,
  canSkip      = true,
}

function ArenaGate:init(data)
  battlePlay.Gate.init(self, data)
  self:playStartAni()
end

-- 播放 VS/PVP 开场动画
function ArenaGate:playStartAni()
  gRootViewProxy:notify("showVsPvpView", 1)
end

-- 开波：把双方卡牌加入战场并做一次属性校正
function ArenaGate:newWaveAddObjsStrategy()
  self:waveAddCardRoles(1)
  self:waveAddCardRoles(2)
  self:doObjsAttrsCorrect(true, true)
  battlePlay.Gate.newWaveAddObjsStrategy(self)
end

-- 结算视图信息（最高伤害等）
function ArenaGate:makeEndViewInfos()
  local dbID, unitID = self:whoHighestDamageFromStats(1)
  return {
    result = self.result,
    dbID   = dbID,
    unitID = unitID,
  }
end

-- 把结果回传到服务端 /game/pw/battle/end
-- 回调 done(endViewInfos, serverResp)
function ArenaGate:postEndResultToServer(done)
  local endView = self:makeEndViewInfos()
  local sceneData = self.scene.data
  gRootViewProxy:raw():postEndResultToServer(
    "/game/pw/battle/end",
    function(resp) done(endView, resp) end,
    sceneData.preData.rightRank,
    endView.result
  )
end

-- 录像回放用的 Gate（继承 ArenaGate）
local ArenaGateRecord = class("ArenaGateRecord", ArenaGate)
battlePlay.ArenaGateRecord = ArenaGateRecord

ArenaGateRecord.OperatorArgs = {
  isAuto         = true,
  isFullManual   = false,
  canHandle      = false,
  canPause       = true,   -- 录像可暂停
  canSpeedAni    = true,
  canSkip        = true,
  canSkipInstant = true,
}

function ArenaGateRecord:init(data)
  battlePlay.Gate.init(self, data)
end
