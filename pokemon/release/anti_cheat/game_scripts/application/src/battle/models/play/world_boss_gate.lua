-- 活动·世界BOSS关卡
require "battle.app_views.battle.module.include"

local ActivityWorldBossGate = class("ActivityWorldBossGate", battlePlay.Gate)
battlePlay.ActivityWorldBossGate = ActivityWorldBossGate

-- 操作相关配置
ActivityWorldBossGate.OperatorArgs = {
  isAuto       = false,
  isFullManual = false,
  canHandle    = true,
  canPause     = false,
  canSpeedAni  = true,
  canSkip      = true,
}

-- 常规参数
ActivityWorldBossGate.CommonArgs = {
  AntiMode = battle.GateAntiMode.Operate,
}

-- CSV派发（示例：按 damage 字段取值）
ActivityWorldBossGate.PlayCsvFunc = {
  damage = function(cfg, idx)
    local row = cfg.damageAward[idx] or {}
    return row.damage
  end
}

function ActivityWorldBossGate:ctor(sceneData)
  battlePlay.Gate.ctor(self, sceneData)
  self.curKillMonsterCount  = 0
  self.lastKillMonsterCount = 0
  self.gateStar             = 3
  self.totalDeadMonsterHp   = 0
  self.recoverHp            = 1
  self.endMoreDelayTime     = 1500

  local yyRow = csv.yunying.yyhuodong[sceneData.data.activityID]
  self.yyCsvVersion   = yyRow.huodongID
  self.boss_damage_max = sceneData.data.boss_damage_max

  self:initVersionInfo()
end

function ActivityWorldBossGate:initVersionInfo()
  self.damageAward       = {}
  self.damageAwardInfo   = {}
  self.curtotalTakeDamage = 0

  -- 只收集当前活动版本的奖励档位
  for _, row in orderCsvPairs(csv.world_boss.damage_award) do
    if row.huodongID == self.yyCsvVersion then
      table.insert(self.damageAward, csvClone(row))
    end
  end

  self:refreshAwardInfoByDamage(0)
end

-- 根据累计伤害刷新“当前档位/下一档位”信息
function ActivityWorldBossGate:refreshAwardInfoByDamage(totalDamage)
  local startLevel = 1

  if self.damageAwardInfo.next then
    if totalDamage < self.damageAwardInfo.next.damage then
      return
    end
  end

  if self.damageAwardInfo.cur then
    if not self.damageAwardInfo.next then
      return
    end
    startLevel = self.damageAwardInfo.cur.level + 1
  end

  self.damageAwardInfo = {}
  for i = startLevel, table.length(self.damageAward) do
    local row = self.damageAward[i]
    if totalDamage < row.damage then
      self.damageAwardInfo.next = row
      break
    end
    self.damageAwardInfo.cur = row
  end
end

function ActivityWorldBossGate:init(params)
  battlePlay.Gate.init(self, params)

  -- UI 模块：世界Boss条形血条等
  gRootViewProxy:proxy():addSpecModule(battleModule.bossMods)

  -- 关卡第一波配置（取 boss 标记）
  local gateCfg = csvClone(gMonsterCsv[self.scene.sceneID][1])

  self.bossLifeTotalCount  = gateCfg.bossLifeCount or 1
  self.bossLastLifeBarsPer = self.bossLifeTotalCount * 100

  local bossUnitID
  for idx, unitID in ipairs(gateCfg.monsters) do
    if unitID > 0 and gateCfg.bossMark and gateCfg.bossMark[idx] == 1 then
      bossUnitID = unitID
    end
  end

  if bossUnitID then
    local unitCfg = csv.unit[bossUnitID]
    gRootViewProxy:notify("initBossLife", {
      name        = unitCfg.name,
      headIconRes = unitCfg.icon,
      damageAward = self.damageAward
    })
  end
end

function ActivityWorldBossGate:setBoss(bossObj)
  self.curBoss = bossObj
  self:setRecoverHp(0)  -- 初始化时刷新一次
  bossObj.view:proxy():updateLifeBarState(false)
end

-- 根据（当前）累计伤害设置一次“回复血量”（这里按最大血量 * 1）
function ActivityWorldBossGate:setRecoverHp(_)
  local RATE = 1
  self.recoverHp = self.curBoss:hpMax() * RATE
end

-- 关卡内对象模型工厂
function ActivityWorldBossGate:createObjectModel(force, unitID)
  if force == 1 then
    return ObjectModel.new(self.scene, unitID)
  else
    if unitID == 11 then
      return BossModel.new(self.scene, unitID)
    end
    return MonsterModel.new(self.scene, unitID)
  end
end

function ActivityWorldBossGate:newWaveAddObjsStrategy()
  self:waveAddCardRoles(1)
  self:waveAddCardRoles(2, 1, self:getEnemyRoleOutT(1))
  self:doObjsAttrsCorrect(true, true)
  battlePlay.Gate.newWaveAddObjsStrategy(self)
end

-- 刷新世界Boss UI血量/奖励进度
function ActivityWorldBossGate:refreshUIHp(bossObj)
  if self.curBoss ~= bossObj then return end

  local total = bossObj:getTakeDamageRecord(battle.ValueType.normal)

  self:refreshAwardInfoByDamage(total)
  self:setRecoverHp(total)

  local percent = 1
  local cur  = self.damageAwardInfo.cur
  local next = self.damageAwardInfo.next

  local curLevel  = cur  and cur.level  or 0
  local curDamage = cur  and cur.damage or 0
  local nxtDamage = next and next.damage or curDamage

  if cur and next then
    percent = (total - cur.damage) / (next.damage - cur.damage)
  elseif not cur then
    percent = total / (next and next.damage or 1)
  end

  if total > self.curtotalTakeDamage then
    self.curtotalTakeDamage = total
    -- 事件：刷新Boss血量（不允许跳转）
    battleEasy.deferNotifyCantJump(nil, "refreshBossHp", percent, total, nxtDamage, curLevel)
  end
end

function ActivityWorldBossGate:makeEndViewInfos()
  local total = self.curBoss:getTakeDamageRecord(battle.ValueType.normal)
  self.bossTotalTakeDamage = total
  return {
    result = self.result,
    damage = total,
  }
end

function ActivityWorldBossGate:sendParams()
  return
    self.scene.battleID,
    self.scene.data.activityID,
    self.bossTotalTakeDamage,
    battlePlay.Gate.sendActionParams(self)
end

function ActivityWorldBossGate:postEndResultToServer(done)
  local view = self:makeEndViewInfos()
  gRootViewProxy:raw():postEndResultToServer(
    "/game/yy/world/boss/end",
    {
      cb = function(resp)
        view.award = resp.view.award
        view.isNewRecordDamage = (self.boss_damage_max < view.damage)
        done(view, resp)
      end
    },
    self:sendParams()
  )
end

-- 每回合结束：播放一个 delay 特效，死亡对象时延长停留
function ActivityWorldBossGate:endBattleTurn(arg)
  local lifetime = 500
  if self.battleTurnInfoTb["hasDeadObj"] then
    lifetime = 1500
  end
  battleEasy.queueEffect(function()
    battleEasy.queueEffect("delay", { lifetime = lifetime })
  end)
  battlePlay.Gate.endBattleTurn(self, arg)
end

-- ========= 回放 =========
local ActivityWorldBossGateRecord = class("ActivityWorldBossGateRecord", ActivityWorldBossGate)
battlePlay.ActivityWorldBossGateRecord = ActivityWorldBossGateRecord

function ActivityWorldBossGateRecord:init(data)
  -- 回放没有 actions 时，走普通 Gate 的 OperatorArgs
  if not data.actions then
    self.OperatorArgs = ActivityWorldBossGate.OperatorArgs
  end
  battlePlay.ActivityWorldBossGate.init(self, data)
  self.actionRecv = data.actions
end

-- 取一帧动作（seat, skillId, extra）
function ActivityWorldBossGateRecord:getActionRecv()
  local t = table.get(self.actionRecv, self.curRound, self.curBattleRound)
  if t == nil then return end
  if t[1] == 0 then return end
  return unpack(t)
end

-- 回放不需要 sendActionParams 的附加项
function ActivityWorldBossGateRecord:sendParams()
  local _ = self:makeEndViewInfos()
  return self.scene.battleID, self.scene.data.activityID, self.bossTotalTakeDamage
end

function ActivityWorldBossGateRecord:checkBattleEnd()
  if self.scene.isBattleAllEnd then
    return true, self.result
  end
  return battlePlay.Gate.checkBattleEnd(self)
end

-- 回放用的单步对战驱动
function ActivityWorldBossGateRecord:onceBattle(inputSeat, inputAction)
  local seat, skillId, extra = self:getActionRecv()

  -- 守卫：回放数据里 seat 与当前出手者不符，直接结束
  if (seat or 0) ~= 0 and seat ~= self.curHero.seat then
    printWarn("ActivityWorldBossGate为何input会在记录中出现错位")
    self.result = "fail"
    self.scene.isBattleAllEnd = true
    self:onOver()
    return
  end

  -- 回放的这一拍是“指定技能/操作”
  if (extra or 0) ~= 0 then
    self.scene.autoFight = false
    battlePlay.Gate.onceBattle(self, skillId, extra)
    self.scene.autoFight = true
    if self.waitInput then
      error("why input be wait in record")
    end
    return
  end

  -- 否则按普通输入执行
  battlePlay.Gate.onceBattle(self, inputSeat, inputAction)
end
