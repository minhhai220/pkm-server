globals.ConstSaltNumbers = table.salttable({
	dot2 = 0.2,
	dot1 = 0.1,
	dot01 = 0.01,
	dot05 = 0.05,
	neg1 = -1,
	wan = 10000,
	dot001 = 0.0001,
	one15 = 1.15,
	dot96 = 0.96,
	one = 1,
	zero = 0
})

local battle = {}

globals.battle = battle
battle.Const = {
	Fail = "fail",
	Win = "win",
	AidTriggerObjectLimit = 3,
	AidAwakeSkillID = 79102,
	AidStageSkillID = 79101,
	Draw = "draw",
	ZSkills = {
		79001,
		79002,
		79003,
		79004
	},
	AidStage = {
		79101,
		9
	},
	AidAwake = {
		79102,
		20
	}
}
battle.SpeedTimeScale = {
	1,
	1.6,
	2.5,
	ultAcc = 10,
	triple = 2.5,
	double = 1.6,
	single = 1
}

local StandingPos = {
	{
		x = 956,
		y = 826 - display.fightLower
	},
	{
		x = 792,
		y = 592 - display.fightLower
	},
	{
		x = 640,
		y = 348 - display.fightLower
	},
	{
		x = 600,
		y = 826 - display.fightLower
	},
	{
		x = 430,
		y = 592 - display.fightLower
	},
	{
		x = 244,
		y = 348 - display.fightLower
	},
	[13] = {
		x = display.width / 2,
		y = 826 - display.fightLower
	},
	[14] = {
		x = display.width / 2,
		y = 826 - display.fightLower
	},
	[99] = {
		x = 0,
		y = 9999
	}
}

battle.StandingPos = StandingPos
battle.PauseNoShowStarConditionsGateType = {
	[game.GATE_TYPE.endlessTower] = true,
	[game.GATE_TYPE.test] = true,
	[game.GATE_TYPE.arena] = true,
	[game.GATE_TYPE.crossArena] = true,
	[game.GATE_TYPE.randomTower] = true,
	[game.GATE_TYPE.hellRandomTower] = true,
	[game.GATE_TYPE.crossOnlineFight] = true,
	[game.GATE_TYPE.gym] = true,
	[game.GATE_TYPE.gymLeader] = true,
	[game.GATE_TYPE.crossMine] = true,
	[game.GATE_TYPE.crossMineBoss] = true,
	[game.GATE_TYPE.braveChallenge] = true,
	[game.GATE_TYPE.hunting] = true,
	[game.GATE_TYPE.summerChallenge] = true,
	[game.GATE_TYPE.crossSupremacy] = true,
	[game.GATE_TYPE.experience] = true,
	[game.GATE_TYPE.abyssEndlessTower] = true
}
battle.EndSpecialCheck = {
	BothDead = 11,
	EnemyOnlySummonOrAllDead = 10,
	DirectWin = 9,
	LastWaveTotalDamage = 8,
	SoloSpecialRule = 7,
	CumulativeSpeedSum = 6,
	FightPoint = 5,
	AllHpRatioCheck = 4,
	TotalHpCheck = 3,
	HpRatioCheck = 2,
	ForceNum = 1
}
battle.MainSkillType = {
	SmallSkill = 1,
	NormalSkill = 0,
	TagSkill = 99,
	PassiveSkill = 3,
	BigSkill = 2
}
battle.SkillType = {
	NormalCombine = 5,
	NormalSkill = 0,
	PassiveAura = 2,
	PassiveAdd = 1,
	PassiveSummon = 4,
	PassiveSkill = 3,
	AidSkill = 6
}
battle.SkillAddBuffType = {
	After = 2,
	Before = 1,
	InPlay = 3
}
battle.SkillFormulaType = {
	resumeHp = 2,
	damage = 1,
	fix = 3
}
battle.SkillSegType = {
	resumeHp = "resumeHp",
	damage = "damage",
	buff = "buff"
}
battle.AttackPosIndex = {
	selfPos = 14,
	center = 13
}
battle.AttackPos = {
	{
		x = StandingPos[1].x + 200,
		y = StandingPos[1].y
	},
	{
		x = StandingPos[2].x + 200,
		y = StandingPos[2].y
	},
	{
		x = StandingPos[3].x + 200,
		y = StandingPos[3].y
	},
	{
		x = StandingPos[4].x + 200,
		y = StandingPos[4].y
	},
	{
		x = StandingPos[5].x + 200,
		y = StandingPos[5].y
	},
	{
		x = StandingPos[6].x + 200,
		y = StandingPos[6].y
	},
	[13] = {
		x = display.width / 2,
		y = StandingPos[2].y
	}
}
battle.ProtectPosIdx = {
	centerRight = 14,
	centerLeft = 13
}
battle.ProtectPos = {
	{
		x = StandingPos[1].x + 150,
		y = StandingPos[1].y
	},
	{
		x = StandingPos[2].x + 150,
		y = StandingPos[2].y
	},
	{
		x = StandingPos[3].x + 150,
		y = StandingPos[3].y
	},
	{
		x = StandingPos[4].x + 150,
		y = StandingPos[4].y
	},
	{
		x = StandingPos[5].x + 150,
		y = StandingPos[5].y
	},
	{
		x = StandingPos[6].x + 150,
		y = StandingPos[6].y
	},
	[13] = {
		x = display.width / 2 - 150,
		y = StandingPos[2].y
	},
	[14] = {
		x = display.width / 2 + 150,
		y = StandingPos[2].y
	}
}
battle.SpriteRes = {
	natureQuanTxtDi = "battle/logo_gray.png",
	fireShield = "koudai_guladuomega/hero_guladuomega.skel",
	natureQuan = "effect/xuanzhongkuang.skel",
	freezeHp = "buff/lgwbm/lgwbm_buff.skel",
	mainSkill = "effect/dz_ice.skel",
	groundRing = "effect/jiaodixzk.skel"
}
battle.SpecialObjectId = {
	teamShiled = 13
}
battle.ShowHeadNumberRes = {
	txtZlBjDi = "battle/txt/bg_zlbj_di.png",
	txtWeak = "battle/txt/txt_sxsw.png",
	txtBjDyDi = "battle/txt/bg_bjdy_di.png",
	txtStrong = "battle/txt/txt_xgbq.png",
	txtZlszDi = "battle/txt/bg_zlsz_di.png",
	txtKzDi = "battle/txt/bg_kz_di.png",
	txtPtshDi = "battle/txt/bg_ptsh_di.png",
	txtBjDi = "battle/txt/bg_bj_di.png",
	txtTypeImmune = "battle/txt/txt_my%s.png",
	txtZlBj = "battle/txt/txt_zlbj.png",
	fontZlBj = "bjzl",
	txtBjDy = "battle/txt/txt_bjdy.png",
	fontKz = "kz",
	txtXfzr = "battle/txt/txt_xfzr.png",
	fontZlsz = "zlsz",
	txtFj = "battle/txt/txt_fj.png",
	fontPtsh = "ptsh",
	txtBj = "battle/txt/txt_bj.png",
	fontBj = "bj",
	txtGd = "battle/txt/txt_gd.png",
	txtShieldReduce = "battle/txt/txt_hdsj.png",
	txtSb = "battle/txt/txt_sb.png",
	txtAllImmune = "battle/txt/txt_mysh.png",
	txtFs = "battle/txt/txt_fs.png",
	txtSpecialImmune = "battle/txt/txt_tgshmy.png",
	txtXx = "battle/txt/txt_xx.png",
	txtPhysicalImmune = "battle/txt/txt_wgshmy.png",
	txtFullweak = "battle/txt/txt_myxg.png"
}
battle.MainAreaRes = {
	fontNqz = "font/digital_nqjl.png",
	txtZsh = "battle/txt/txt_zsh.png",
	waveDiTu = "battle/img_pc.png",
	txtNqz = "battle/txt/txt_nqjl.png",
	fontZsh = "zsh",
	diZzl = "battle/txt/bg_zzl_di.png",
	fontZzl = "zzl",
	txtZzl = "battle/txt/txt_zzl.png"
}
battle.StageRes = {
	cutRes = "effect/cutscreen4.skel",
	daZhaoBJ = "effect/dazhao_bj.skel"
}
battle.SpriteLayerZOrder = {
	mainSkill = 15,
	qipao = 9500,
	quan = 14,
	lifebar = 12,
	selfSpr = 10,
	ground = 9
}
battle.GameLayerZOrder = {
	icon = 8000,
	text = 9999,
	overlay = 8500
}
battle.AssignLayer = {
	effectLayerLower = 3,
	gameLayer = 2,
	roleLayer = 1,
	stageLayer = 0,
	frontStageLayer = 5,
	effectLayer = 4
}
battle.EffectZOrder = {
	none = 0,
	merge = 19999,
	dead = 9999
}
battle.LoopActionMap = {
	standby_loop = true,
	win_loop = true,
	stun_loop = true,
	run_loop = true
}
battle.EffectEventArgFields = {
	sound = {
		"sound"
	},
	shaker = {
		"shaker",
		"segInterval"
	},
	music = {
		"music"
	},
	move = {
		"move"
	},
	show = {
		"show"
	},
	damageSeg = {
		"damageSeg",
		"segInterval"
	},
	hpSeg = {
		"hpSeg",
		"segInterval"
	},
	effect = {
		"effectType",
		"effectRes",
		"effectArgs"
	},
	zOrder = {
		"zOrder"
	},
	follow = {
		"follow"
	},
	jump = {
		"jumpFlag"
	},
	control = {
		"control"
	},
	cutting = {
		"cutting"
	}
}
battle.FilterDeferListTag = {
	none = 0,
	cantJump = 1,
	cantClean = 2
}
battle.SpriteActionTable = {
	death = "death",
	charging = "charging",
	hit = "hit",
	attack = "attack",
	run = "run_loop",
	standby = "standby_loop"
}
battle.OperateTable = {
	noAttack = 11,
	helper = 10,
	choose = 8,
	story = 7,
	autoFight = 6,
	timeScale = 3,
	pause = 2,
	skill = 1,
	ultAcc = 15,
	ultAccEnd = 16,
	passOneWave = 17,
	attack = 9,
	fullManual = 14,
	runAway = 13,
	pass = 12
}
battle.DefaultModes = {}
battle.PassiveSkillTypes = {
	realDead = 3,
	cycleRound = 2,
	round = 1,
	attack = 8,
	roundStartAttack = 23,
	roundStart = 29,
	dynamicTeamHpLess = 28,
	additional = 27,
	recoverHp = 26,
	teamHpLess = 25,
	dynamicHpLess = 24,
	create = 0,
	beToolsComsumed = 22,
	beSpeciaBuff = 21,
	beWeather = 20,
	beSpeciaSelfForce = 19,
	hpLess = 18,
	beSpecialDamage = 17,
	beDamage = 16,
	beDamageIfFullHp = 15,
	beNonNatureDamage = 14,
	beNatureDamage = 13,
	beStrike = 12,
	beSpecialNatureDamage = 11,
	kill = 10,
	roundEnd = 9,
	enter = 7,
	beAttack = 6,
	beDeathAttack = 5,
	fakeDead = 4
}
battle.PassiveRoundEndFlag = {
	Round = 1,
	SelfBattleTurn = 0
}
battle.ControllBuffType = {
	sleepy = true,
	changeImage = true,
	stun = true,
	leave = true,
	freeze = true,
	sneer = true,
	silence = true
}
battle.RestraintTypeIcon = {
	weak = "battle/logo_dk.png",
	special = "battle/txt_mytg.png",
	strong = "battle/logo_kz.png",
	allimmune = "battle/txt_mysh.png",
	physical = "battle/txt_mywg.png",
	fullweak = "battle/logo_myxg.png"
}
battle.BuffTriggerPoint = {
	onSkillSpellBeforeForAid = 500,
	onHolderLostHpBeforeCorrection = 154,
	onHolderLostHpCorrection = 148,
	onHolderMp1OverflowCorrection = 144,
	onHolderMp1ChangeCorrection = 134,
	onSkillHitTarget = 66,
	onHolderBeAttackEnd = 65,
	onSeatEmpty = 63,
	onBuffTakeEffectSelf = 62,
	onBuffDispel = 61,
	onHolderAssimilateDamageBreak = 60,
	onBattleTurnStartBefore = 59,
	onHolderSummon = 58,
	onHolderBattleTurnStartOther = 57,
	onBuffCantAdd = 56,
	onHolderPreHeal = 55,
	onHolderLostHpBefore = 54,
	onReflexDamage = 53,
	onFullShieldBreak = 52,
	onBuffOverBefore = 51,
	onHolderBuffOver = 50,
	onHolderBeBuffSputterHit = 49,
	onHolderLostHp = 48,
	onHolderShiftChange = 47,
	onBuffOverlayRefresh = 46,
	onRunGameEnd = 45,
	onHolderMp1Overflow = 44,
	onChargeBeInterrupted = 43,
	onBattleTurnEnd = 42,
	onHolderShieldChange = 41,
	onHolderCalcDamageProb = 40,
	onHolderLethal = 39,
	onHolderAfterEnter = 38,
	onHolderMakeTargetRealDeath = 37,
	onHolderAfterHit = 36,
	onHolderBackStage = 35,
	onHolderMp1Change = 34,
	onHolderShieldBreak = 33,
	onBattleTurnStart = 32,
	onHolderFakeDeath = 31,
	onHolderAfterRefreshTargets = 30,
	onBuffBeAdd = 29,
	onBuffTrigger = 28,
	onHolderHpAdd = 27,
	onHolderReborn = 26,
	onHolderBeForeSkillSpellTo = 25,
	onHolderToAttack = 24,
	onHolderCounterAttack = 23,
	onBuffControlEnd = 22,
	onBuffOverlay = 21,
	onBuffOverDispel = 20,
	onBuffOverNormal = 19,
	onHolderHpChange = 18,
	onHolderAfterBeHit = 17,
	onHolderMateKilledBySkill = 16,
	onHolderKillHandleChooseTarget = 15,
	onHolderBeforeBeHit = 14,
	onHolderRealDeath = 13,
	onHolderDeath = 12,
	onHolderKillTarget = 11,
	onHolderFinallyBeHit = 10,
	onHolderBeHit = 9,
	onHolderAttackEnd = 8,
	onHolderAttackBefore = 7,
	onHolderBattleTurnEnd = 6,
	onHolderBattleTurnStart = 5,
	onRoundEnd = 4,
	onRoundStart = 3,
	onBuffOver = 2,
	onBuffCreate = 1,
	onNodeCall = 0
}
battle.DamageFrom = {
	skill = 3,
	buff = 1,
	rebound = 2
}
battle.DamageFromExtra = {
	link = 202,
	allocate = 201,
	protect = 203
}
battle.DamageKind = {
	single = 3,
	other = 4,
	aoe = 2,
	skill = 1
}
battle.ResumeHpFrom = {
	suckblood = 103,
	buff = 101,
	skill = 102
}
battle.AddHpFrom = {
	changeScaleAttrs = 202,
	addHpMax = 201,
	setHpPer = 200,
	freezeHpMax = 203
}
battle.BuffCantAddReason = {
	filter = 2,
	powerGroup = 1,
	overlayLimit = 7,
	powerFlag = 6,
	prob = 5,
	immune = 4,
	commandeer = 3
}
battle.BuffExtraTargetType = {
	skillNowTarget = 25,
	triggerCaster = 24,
	triggerAttacker = 23,
	mainTarget = 22,
	segProcessTargetRandom = 21,
	triggerObject = 20,
	surroundHolderKill = 19,
	segProcessTargets = 18,
	casterEnemyForceRandom = 17,
	killHolder = 16,
	skillOwner = 15,
	casterEnemyForce = 14,
	holderEnemyForce = 13,
	overLayBuffCaster = 12,
	casterForce = 11,
	surroundCasterNoDath = 10,
	casterForceNoDeathRandom = 9,
	skillAllDamageTargets = 8,
	holderBeAttackFrom = 7,
	lastProcessTargets = 6,
	holderForce = 5,
	surroundHolderNoDath = 4,
	holderForceNoDeathRandom = 3,
	caster = 2,
	holder = 1
}
battle.copyOrTransferSpecType = {
	eachCaster = 100
}
battle.UITag = {
	pvpOpening = 2,
	passCD = 1
}
battle.SkillDamageType = {
	True = 2,
	Special = 1,
	Physical = 0
}
battle.CounterAttackMode = {
	bigSkill = 3,
	smallSkill = 2,
	onlyAttack = 1
}
battle.ValueType = {
	valid = 3,
	overFlow = 2,
	normal = 1
}
battle.DamageProcess = {
	"damageHit",
	"nature",
	"damageAdd",
	"damageDeepen",
	"dmgDelta",
	"natureDelta",
	"gateDelta",
	"reduce",
	"strikeBlock",
	"strike",
	"block",
	"extraAdd",
	"fatal",
	"behead",
	"damageByHpRate",
	"finalSkillAdd",
	"ultimateAdd",
	"skillPower",
	"buffAdd",
	"randFix",
	"limit",
	"calcInternalDamageFinish",
	"reflexDamage",
	"ignoreRoundDamage",
	"immuneAllDamage",
	"immuneDamage",
	"immunePhysicalDamage",
	"immuneSpecialDamage",
	"invincible",
	"keepHpUnChanged",
	"groupShield",
	"assimilateDamage",
	"delayDamage",
	"damageCounteract",
	"damageAllocate",
	"damageLink",
	"protection",
	"shield",
	"freeze",
	"finalRate",
	"barrier",
	"lockHp",
	"rebound",
	"suckblood",
	"lockHpShield",
	"result"
}
battle.DamageProbProcessId = 18
battle.ExtraAttackMode = {
	combo = 2,
	counter = 1,
	normal = 9,
	aid = 10,
	duel = 8,
	brawl = 7,
	prophet = 6,
	assistAttack = 5,
	inviteAttack = 4,
	syncAttack = 3
}
battle.ExtraBattleRoundMode = {
	atOnce = 2,
	gemini = 3,
	normal = 0,
	reset = 1
}
battle.JumpAllDamageProcessId = 9
battle.BuffOverType = {
	restrain = 4,
	dispel = 2,
	normal = 1,
	clean = 0,
	level = 5,
	process = 6,
	overlay = 3
}
battle.SkillInterruptType = {
	charge = 1
}
battle.WeatherRelation = {
	inEffectR = 2,
	inEffectL = 1,
	coexist = 0
}
battle.FieldType = {
	newField = 2,
	weather = 1,
	field = 0
}
battle.OverlaySpecBuff = {
	sleepy = "sleepy",
	addMp1Max = "addMp1Max",
	addAttr = "addAttr",
	freezeHpMax = "freezeHpMax",
	transformAttrBuff = "transformAttrBuff",
	addHpMax = "addHpMax",
	freeze = "freeze",
	commandeer = "commandeer",
	keepHp = "keepHpUnChanged",
	cantDispelBuffRound = "cantDispelBuffRound",
	damageByHpRate = "damageByHpRate",
	behead = "behead",
	fatal = "fatal",
	allocate = "damageAllocate",
	ignoreSpecBuff = "ignoreSpecBuff",
	occupiedSeat = "occupiedSeat",
	prophet = "prophet",
	inviteAttack = "inviteAttack",
	syncAttack = "syncAttack",
	lockHpShield = "lockHpShield",
	lockHp = "lockHp",
	barrier = "barrier",
	shield = "shield",
	protection = "protection",
	damageLink = "damageLink",
	followObject = "followObject",
	delayDamage = "delayDamage",
	aura = "aura",
	universalBar = "universalBar",
	freezeBuff = "freezeBuff",
	addNature = "addNature",
	castBuffModifiy = "castBuffModifiy",
	replaceBuffHolder = "replaceBuffHolder",
	immuneDamage = "immuneDamage",
	downPriorityOnAutoChoose = "downPriorityOnAutoChoose",
	ignorePriorityBuff = "ignorePriorityBuff",
	reflexDamage = "reflexDamage",
	calDmgKeepDefence = "calDmgKeepDefence",
	comboAttack = "comboAttack",
	registerBuffs = "registerBuffs",
	dmgAdjustAllocateAndLink = "dmgAdjustAllocateAndLink",
	forceMaxHpLimit = "forceMaxHpLimit",
	healBoost = "healBoost",
	transferMp = "transferMp",
	lockShield = "lockShield",
	forbiddenAddHP = "forbiddenAddHP",
	changeTreatment = "changeTreatment",
	needMoreDispel = "needMoreDispel",
	forbiddenExtraAttack = "forbiddenExtraAttack",
	applyCommandeer = "applyCommandeer",
	delayBuff = "delayBuff",
	reflectBuffToOther = "reflectBuffToOther",
	addAttackRange = "addAttackRange",
	controlEnemy = "controlEnemy",
	buffBattleRound = "buffBattleRound",
	pauseBuffLifeRound = "pauseBuffLifeRound",
	pausePassiveSkillEffect = "pausePassiveSkillEffect",
	pauseBuffEffect = "pauseBuffEffect",
	secondAttack = "secondAttack",
	cancelToAttack = "cancelToAttack",
	reboundBuff = "reboundBuff",
	changeBuffDamageArgs = "changeBuffDamageArgs",
	swapSpeed = "swapSpeed",
	buffSputtering = "buffSputtering",
	cantRecoverMp = "cantRecoverMp",
	replaceTarget = "replaceTarget",
	reduceSkillDamageTarget = "reduceSkillDamageTarget",
	changeSkillDamageTarget = "changeSkillDamageTarget",
	changeSkillNature = "changeSkillNature",
	changeObjNature = "changeObjNature",
	changeBuffLifeRound = "changeBuffLifeRound",
	healTodamage = "healTodamage",
	lethalProtect = "lethalProtect",
	alterRoundAttackInfo = "alterRoundAttackInfo",
	replaceExAttackSkill = "replaceExAttackSkill",
	opGameData = "opGameData",
	forceSneer = "forceSneer",
	atOnceBattleRound = "atOnceBattleRound",
	extraSkillWeightValueFix = "extraSkillWeightValueFix",
	counterAttack = "counterAttack",
	finalAttrLimit = "finalAttrLimit",
	sneer = "sneer",
	reborn = "reborn"
}
battle.ObjectState = {
	realDead = 4,
	normal = 2,
	dead = 3,
	none = 1,
	reborn = 5
}
battle.InfluenceSceneBuffType = {
	leave = 1,
	dead = 2
}
battle.ObjectLogicState = {
	cantAttack = 2,
	cantBeSelect = 1,
	cantUseSkill = 5,
	cantBeAttack = 4,
	cantBeAddBuff = 3
}
battle.ExRecordEvent = {
	correctCPCfg = 36,
	commandeerCaster = 35,
	commandeerAll = 34,
	attackState = 33,
	mpFromSuckMp = 32,
	soloTriggerBuffTime = 31,
	deadTakeDamage = 30,
	replaceTargetTime = 29,
	summoner = 28,
	frontStage = 27,
	skillAddBuffIds = 26,
	protectTarget = 25,
	extraBattleRound = 24,
	possessTarget = 23,
	chargeStateBeforeWave = 22,
	spellSkillTotal = 21,
	skillEffectLimit = 20,
	momentBuffDamage = 19,
	roundAttackTime = 18,
	score = 17,
	killNumber = 16,
	totalHp = 15,
	campDamage = 14,
	unitsDamage = 13,
	roundSyncAttackTime = 12,
	penetrate = 11,
	sputtering = 10,
	comboProcessTotalNum = 9,
	lostHp = 8,
	rebornRound = 7,
	transferSucessCount = 6,
	copySucessCount = 5,
	dispelSuccessCount = 4,
	spellBigSkill = 3,
	spellSmallSkill = 2,
	spellNormalSkill = 1,
	replaceTarget = 1017,
	swapSpeedRefresh = 2000,
	customRecord = 1023,
	transformBuffTriggerCount = 1022,
	addHpLimit = 1021,
	buffFreezeFlag = 1020,
	sceneRoundExAttackData = 1019,
	backStageRoundInfo = 1018,
	campBuffAddByFlag = 1016,
	lockHpTotalDamage = 1015,
	campBuffAddByGroup = 1014,
	campBuffAddByCfgId = 1013,
	buffRecord = 1012,
	keepHpUnChangedTriggerState = 1011,
	lockHpTriggerState = 1010,
	copyState = 1007,
	transferState = 1006,
	sucessCount = 1005,
	copyOrTransferBuff = 1004,
	dispelBuffCount = 1003,
	dispelSuccess = 1002,
	lockHpTriggerTime = 1001,
	lockHpDamage = 1000,
	extraAttackDataInFastReborn = 49,
	attackedRoundRecord = 48,
	roundAttackInfo = 47,
	barrierLockTurn = 46,
	assimilateDamageAbsorbDamage = 45,
	weatherLevels = 44,
	fieldBuffRelation = 43,
	immuneDamageVal = 42,
	allocateOverflow = 41,
	shieldAbsorbDamage = 40,
	extraAttackRoundLimit = 39,
	BrawlDuelCd = 38,
	brawlDuelist = 37
}
battle.TimeIntervalType = {
	battleRound = 3,
	mainSkillEnd = 4,
	round = 2,
	wave = 1
}
battle.FilterObjectType = {
	excludeObjLevel1 = 100,
	excludeEnvObj = 4,
	noBeSelectHint = 3,
	noRealDeath = 2,
	noAlreadyDead = 1
}
battle.EffectPowerType = {
	triggerPoint = "triggerPoint",
	killAddMp1 = "killAddMp1",
	canAsTurnTarget = "canAsTurnTarget",
	hpFormulaDiscount = "hpFormulaDiscount",
	needUnitID = "needUnitID",
	hpFixedDiscount = "hpFixedDiscount",
	normalSpecialCheck = "normalSpecialCheck",
	summonSpecialCheck = "summonSpecialCheck",
	passiveSkill = "passiveSkill"
}
battle.BuffOverlayType = {
	OverlayDrop = 7,
	Coexist = 6,
	IndeLifeRound = 5,
	CoverLifeRound = 4,
	CoverValue = 3,
	Overlay = 2,
	Cover = 1,
	Normal = 0,
	CoexistLifeRound = 8
}
battle.BuffEffectOverlayType = {
	SameMode = 2,
	PopTop = 1,
	Normal = 0
}
battle.BuffEffectAniType = {
	OverlayCount = 1,
	Normal = 0
}
battle.SneerType = {
	Duel = 1,
	Normal = 0
}
battle.SneerArgType = {
	BuffSpread = 2,
	DamageSpread = 1,
	NoSpread = 0,
	AllSpread = 3
}
battle.lifeRoundType = {
	battleTurnNormal = 4,
	pureBattleTurn = 3,
	round = 2,
	battleTurn = 1,
	roundNormal = 6
}
battle.ObjectClass = {
	Summon = 1,
	Normal = 0
}
battle.ObjectType = {
	FollowSummon = 1,
	Aid = 3,
	FollowNormal = 2,
	Normal = 0
}
battle.CsvStrToMap = {
	checkRealDeathIter = function(obj)
		return obj:isRealDeath()
	end
}
battle.TriggerEnvType = {
	PassiveSkill = 1
}
battle.GuideTriggerPoint = {
	Fail = 97,
	End = 99,
	Wave = 1000,
	Start = 0,
	Win = 98
}
battle.GateAntiMode = {
	Operate = 1,
	Normal = 0
}
battle.SpriteType = {
	Follower = 2,
	Possess = 1,
	Aid = 3,
	Normal = 0
}
battle.defaultExtraAttackCheckId = 1000
battle.VariablePriorityTb = {
	posZ = {
		default = 1,
		setPosTo = 2,
		reset = 1
	},
	posAdjust = {
		default = 1,
		init = 1,
		setPosTo = 2
	},
	spriteVisible = {
		default = 1,
		hideAdvanced = 2,
		hide = 2,
		reload = 1,
		hideSprite = 2,
		changeImage = 2,
		brawl = 3,
		depart = 4
	},
	groundRingVisible = {
		default = 1,
		holderAction = 2
	},
	lifeBarVisible = {
		default = 1,
		hideAdvanced = 2,
		hide = 2,
		brawl = 3
	}
}
battle.skillTargetChooseType = {
	SelfRow = 17,
	SelfColumn = 16,
	Near = 15,
	Myself = 14,
	Object = 13,
	Spurt = 12,
	All = 11,
	Column = 4,
	RowBack = 3,
	RowFront = 2,
	Single = 1,
	SelfAndEnemyRow1 = 25,
	Special = 24,
	ObjectEx = 23,
	BackRowRandom = 22,
	FrontRowRandom = 21,
	Random = 20,
	WhoKillMe = 19,
	EnemyNear = 18
}
battle.SkillCostType = {
	IgnoreMpCd = 1,
	Normal = 0
}
battle.specialChooseAttrTb = {
	"hpMax",
	"hpMin",
	"attackDamageMax",
	"attackDamageMin",
	"defenceMax",
	"defenceMin",
	"mp1Max",
	"mp1Min",
	"specialDamageMax",
	"specialDamageMin",
	"speedMax",
	"speedMin",
	"specialDefenceMax",
	"specialDefenceMin",
	"hpRatioMax",
	"hpRatioMin",
	"mp1RatioMax",
	"mp1RatioMin"
}
battle.fullRoundInfoType = {
	allHpRatio = "allHpRatio",
	hpRatio = "hpRatio",
	object = "object",
	damage = "damage",
	totalHp = "totalHp",
	soloTriggerTime = "soloTriggerTime"
}
battle.hpShowState = {
	normal = 0,
	always = 2,
	hide = 1
}
battle.aidTriggerType = {
	SpellBigSkill = 3,
	RoundStartAfter = 2,
	RoundStartBefore = 1
}
battle.EffectResType = {
	BuffEffectInForceSelf = "BuffEffectInForceSelf",
	BuffEffectInNormal = "BuffEffectInNormal",
	BuffEffectToHide = "BuffEffectToHide",
	BuffEffectInHolder = "BuffEffectInHolder",
	FollowToScale = "FollowToScale",
	FollowSprite = "FollowSprite",
	BuffText = "BuffText",
	OnceEffect = "OnceEffect",
	BuffEffectInForceEnemy = "BuffEffectInForceEnemy"
}
battle.iconBoxRes = {
	freezeBox = "battle/buff_icon/box_freeze.png",
	selectedBox = "battle/buff_icon/box_selected.png",
	commandeerBox = "battle/buff_icon/box_commandeer.png"
}
battle.queueCallBackTag = {
	updateObjAidTimes = "updateObjAidTimes",
	updateForceAidTimes = "updateForceAidTimes",
	dealBuffIconBox = "buffEffect",
	deleteBuffEffect = "buffEffect",
	playBuffAniEffect = "buffEffect"
}
battle.damageCorrectFormulaType = {
	set = 5,
	segIndex = 4,
	segMore = 3,
	segLess = 2,
	stage = 1
}
battle.damageCorrectType = {
	block = 2,
	damageAdd = 1,
	reduce = 3
}
battle.result = {
	inconformity = "inconformity",
	win = "win",
	fail = "fail"
}
battle.universalBarRes = {
	default = "battle/bar_xt2.png"
}
battle.FrontStagePriority = {
	maxPriority = 999,
	defaultPriority = 10
}
battle.FrontStageSeatType = {
	real = 1,
	follow = 2
}
battle.OuterGuideName = {
	aid = "aid"
}
battle.CircusType = {
	acrobatics = 3,
	lineup = 2,
	eement = 1
}
battle.TransformBuffEffectType = {
	caster = 1,
	holder = 0
}
battle.spstructure = {
	BuffFilterMap = "BuffFilterMap"
}
battle.RowSeatRange = {
	{
		{
			min = 1,
			max = 3
		},
		{
			min = 4,
			max = 6
		}
	},
	{
		{
			min = 7,
			max = 9
		},
		{
			min = 10,
			max = 12
		}
	}
}
