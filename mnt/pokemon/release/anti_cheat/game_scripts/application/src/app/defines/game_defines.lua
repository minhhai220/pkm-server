local game = {}

globals.game = game
game.TRIAL_MODEL = true
game.GAME_SYNC_TIME = 1500
game.VIP_LIMIT = 15
game.VIP_SUPREME = 19
game.STAMINA_LIMIT = 3000
game.STAMINA_COLD_TIME = 300
game.FRIEND_LIMIT = 60
game.FRIEND_STAMINA_GET_TIMES = 20
game.MAIL_LIMIT = 60
game.NVALUE_ATTR_LIMIT = 31
game.RACE_ATTR_LIMIT = 255
game.FRAME_TICK = 16.666666666666668
game.SERVER_OPENTIME = 0
game.FISHING_GAME = 999
game.WEATHER = true
game.SKIN_ADD_NUM = 100000
game.NATURE_ENUM_TABLE = {
	ground = 9,
	poison = 8,
	combat = 7,
	ice = 6,
	electricity = 5,
	grass = 4,
	water = 3,
	fire = 2,
	normal = 1,
	fairy = 18,
	steel = 17,
	evil = 16,
	dragon = 15,
	ghost = 14,
	rock = 13,
	worm = 12,
	super = 11,
	fly = 10
}
game.NATURE_TABLE = {}

for k, v in pairs(game.NATURE_ENUM_TABLE) do
	game.NATURE_TABLE[v] = k
end

game.ONESELF_NATURE_ENUM_TABLE = {
	attrDefence = 9,
	attrSpecialDamage = 8,
	attrDamage = 7,
	attrHp = 1,
	attrSpeed = 13,
	attrSpecialDefence = 10
}
game.ATTRDEF_ENUM_TABLE = {
	grassCure = 75,
	electricityCure = 76,
	iceCure = 77,
	combatCure = 78,
	iceDamageAdd = 41,
	electricityDamageAdd = 40,
	grassDamageAdd = 39,
	waterDamageAdd = 38,
	fireDamageAdd = 37,
	normalDamageAdd = 36,
	specialDamageSub = 35,
	specialDamageAdd = 34,
	physicalDamageSub = 33,
	physicalDamageAdd = 32,
	damageReduce = 31,
	damageDeepen = 30,
	natureRestraint = 29,
	cure = 28,
	rebound = 27,
	suckBlood = 26,
	ultimateSub = 25,
	ultimateAdd = 24,
	damageSub = 23,
	damageAdd = 22,
	hit = 21,
	dodge = 20,
	blockPower = 19,
	breakBlock = 18,
	block = 17,
	strikeResistance = 16,
	strikeDamage = 15,
	strike = 14,
	speed = 13,
	specialDefenceIgnore = 12,
	defenceIgnore = 11,
	specialDefence = 10,
	defence = 9,
	specialDamage = 8,
	damage = 7,
	mp2Recover = 6,
	mp1Recover = 5,
	hpRecover = 4,
	initMp1 = 3,
	mp1 = 2,
	hp = 1,
	waterCure = 74,
	fireCure = 73,
	normalCure = 72,
	fairyDamageSub = 71,
	steelDamageSub = 70,
	evilDamageSub = 69,
	dragonDamageSub = 68,
	ghostDamageSub = 67,
	rockDamageSub = 66,
	wormDamageSub = 65,
	superDamageSub = 64,
	flyDamageSub = 63,
	groundDamageSub = 62,
	poisonDamageSub = 61,
	combatDamageSub = 60,
	iceDamageSub = 59,
	electricityDamageSub = 58,
	grassDamageSub = 57,
	waterDamageSub = 56,
	fireDamageSub = 55,
	normalDamageSub = 54,
	fairyDamageAdd = 53,
	steelDamageAdd = 52,
	evilDamageAdd = 51,
	dragonDamageAdd = 50,
	ghostDamageAdd = 49,
	rockDamageAdd = 48,
	wormDamageAdd = 47,
	superDamageAdd = 46,
	flyDamageAdd = 45,
	groundDamageAdd = 44,
	poisonDamageAdd = 43,
	combatDamageAdd = 42,
	poisonCure = 79,
	groundCure = 80,
	flyCure = 81,
	superCure = 82,
	wormCure = 83,
	rockCure = 84,
	ghostCure = 85,
	dragonCure = 86,
	evilCure = 87,
	steelCure = 88,
	fairyCure = 89,
	controlPer = 90,
	immuneControl = 91,
	pvpDamageAdd = 92,
	pvpDamageSub = 93,
	damageHit = 94,
	damageDodge = 95,
	finalDamageAdd = 96,
	finalDamageSub = 97,
	finalDamageDeepen = 98,
	finalDamageReduce = 99
}
game.ATTRDEF_TABLE = {}

for k, v in pairs(game.ATTRDEF_ENUM_TABLE) do
	game.ATTRDEF_TABLE[v] = k
end

game.ATTRDEF_SHOW_NUMBER = {
	[game.ATTRDEF_ENUM_TABLE.hp] = true,
	[game.ATTRDEF_ENUM_TABLE.mp1] = true,
	[game.ATTRDEF_ENUM_TABLE.initMp1] = true,
	[game.ATTRDEF_ENUM_TABLE.hpRecover] = true,
	[game.ATTRDEF_ENUM_TABLE.damage] = true,
	[game.ATTRDEF_ENUM_TABLE.specialDamage] = true,
	[game.ATTRDEF_ENUM_TABLE.defence] = true,
	[game.ATTRDEF_ENUM_TABLE.specialDefence] = true,
	[game.ATTRDEF_ENUM_TABLE.speed] = true
}
game.ATTRDEF_SIMPLE_ENUM_TABLE = {
	speed = 2,
	hp = 1,
	specialDefence = 6,
	defence = 4,
	specialDamage = 5,
	damage = 3
}
game.ATTRDEF_SIMPLE_TABLE = {}

for k, v in pairs(game.ATTRDEF_SIMPLE_ENUM_TABLE) do
	game.ATTRDEF_SIMPLE_TABLE[v] = k
end

game.GENDER_ENUM_TABLE = {
	female = 2,
	male = 1,
	none = 0
}
game.GENDER_TABLE = {}

for k, v in pairs(game.GENDER_ENUM_TABLE) do
	game.GENDER_TABLE[v] = k
end

game.ITEM_STRING_ENUM_TABLE = {
	coin22 = 436,
	coin21 = 435,
	coin20 = 434,
	coin19 = 433,
	coin18 = 432,
	coin17 = 431,
	yycoin = 6321,
	coin16 = 430,
	coin15 = 429,
	coin14 = 428,
	coin13 = 427,
	gym_talent_point = 426,
	coin12 = 425,
	skill_point = 424,
	coin11 = 423,
	coin10 = 422,
	coin9 = 421,
	coin8 = 420,
	coin7 = 419,
	coin6 = 416,
	coin5 = 415,
	coin4 = 414,
	coin3 = 413,
	coin2 = 412,
	coin1 = 411,
	contrib = 408,
	equip_awake_frag = 407,
	talent_point = 406,
	vip_exp = 405,
	vip = 404,
	stamina = 403,
	rmb = 402,
	gold = 401,
	role_exp = 400
}
game.ITEM_STRING_TABLE = {}

for k, v in pairs(game.ITEM_STRING_ENUM_TABLE) do
	game.ITEM_STRING_TABLE[v] = k
end

game.ITEM_STRING_ENUM_TABLE.recharge_rmb = 402
game.ITEM_TICKET = {
	shopRefresh = 522,
	card4 = 520,
	diamondUpCard = 527,
	limitCard = 526,
	equipCard = 503,
	goldCard = 518,
	rmbCard = 519,
	pvpTicket = 517,
	totemCard = 541,
	chipCard = 537,
	skinCard = 536,
	passportVipCoin = 533,
	passportCoin = 532,
	rmbGem = 531,
	goldGem = 530,
	luckyEggCard = 6320
}
game.ITEM_EXP_HASH = arraytools.hash({
	399,
	"role_exp",
	"vip",
	"vip_exp",
	"contrib",
	417,
	437
})
game.QUALITY_TO_FITST_ADVANCE = {
	1,
	2,
	5,
	9,
	14,
	20,
	26
}
game.QUALITY_MAX = #game.QUALITY_TO_FITST_ADVANCE
game.ITEM_CSVID_LIMIT = 10000
game.EQUIP_CSVID_LIMIT = 20000
game.FRAGMENT_CSVID_LIMIT = 30000
game.HELD_ITEM_CSVID_LIMIT = 40000
game.GEM_CSVID_LIMIT = 50000
game.ZAWAKE_FRAGMENT_CSVID_LIMIT = 60000
game.CHIP_CSVID_LIMIT = 70000
game.FURNITURE_CSVID_LIMIT = 80000
game.CONTRACT_CSVID_LIMIT = 90000
game.AID_ADVANCE_MATERIAL_CSVID_LIMIT = 98000
game.AID_AWAKE_MATERIAL_CSVID_LIMIT = 100000
game.ITEM_TYPE_ENUM_TABLE = {
	totemType = 20,
	yyItem = 24,
	drawItemManualType = 23,
	drawItemAutoType = 22,
	yyCountType = 21,
	normal = 0,
	characterType = 18,
	roleDisplayType = 17,
	chooseGift = 16,
	skin = 15,
	randomGiftOpen = 10,
	feelExp = 9,
	equipStarUp = 8,
	randomGift = 7,
	key = 6,
	material = 5,
	equipExp = 4,
	gift = 3,
	staminaRecover = 2,
	cardExp = 1
}
game.ITEM_NUM_HIDE_TYPE_HASH = arraytools.hash({
	game.ITEM_TYPE_ENUM_TABLE.roleDisplayType,
	game.ITEM_TYPE_ENUM_TABLE.yyCountType
})
game.SPRITE_BALL_ID = {
	normal = 523,
	hero = 524,
	nightmare = 525
}
game.BRAVE_CHALLENGE_TYPE = {
	anniversary = 1,
	common = 2
}
game.YYHUODONG_TYPE_ENUM_TABLE = {
	snowBall = 53,
	huoDongCloth = 52,
	moveBlock = 91,
	double11 = 51,
	halloween = 50,
	huoDongBoss = 49,
	flipCard = 48,
	qualityExchange = 47,
	reunion = 46,
	baoZongzi = 45,
	gemUp = 44,
	weeklyCard = 43,
	festival = 42,
	Retrieve = 41,
	luckyEgg = 40,
	livenessWheel = 39,
	rechargeWheel = 38,
	LoginGift = 37,
	timeLimitUpDraw = 36,
	passport = 35,
	limitBuyGift = 34,
	directBuyGift = 33,
	gameGoDown100 = 32,
	rechargeReset = 31,
	gameEatGreenBlock = 30,
	game2048 = 29,
	onceRechageAward = 28,
	regainStamina = 27,
	worldBoss = 26,
	breakEgg = 25,
	yyClone = 24,
	itemBuy = 23,
	levelFund = 22,
	vipBuy = 21,
	timeLimitBox = 20,
	dailyBuy = 19,
	collectCard = 18,
	luckyCat = 17,
	fightRank = 16,
	serverOpen = 15,
	generalTask = 14,
	rmbCost = 13,
	itemExchange = 12,
	vipAward = 10,
	gateAward = 9,
	clientShow = 8,
	dinnerTime = 7,
	monthlyCard = 6,
	timeLimitDraw = 5,
	rechargeGift = 4,
	levelAward = 3,
	loginWeal = 2,
	firstRecharge = 1,
	limitDrop = -3,
	doubleDrop = -2,
	everyDayLogin = -1,
	megaAssist = 90,
	firstRechargeAward = 89,
	thousandDraw = 88,
	refloat = 87,
	roundDraw = 86,
	dailyRandomGift = 85,
	luckyDraw = 84,
	mitu = 83,
	vipGift2 = 82,
	qixi = 80,
	spritejump = 79,
	contestBet = 78,
	worldcup = 77,
	praise = 76,
	roleDayAward = 75,
	elementCrush = 74,
	yyBet = 73,
	lightingNewYear = 72,
	seekpokemon = 71,
	customizeGift = 70,
	midAutumnDraw = 69,
	volleyball = 68,
	summerChallenge = 67,
	shavedIce = 66,
	dispatch = 65,
	exclusiveLimit = 64,
	itemBuy2 = 63,
	horseRace = 62,
	braveChallenge = 61,
	gridWalk = 60,
	playPassport = 59,
	rmbgoldReward = 58,
	huodongCrossRedPacket = 57,
	flipNewYear = 56,
	skyScraper = 55,
	spriteUnfreeze = 54
}
game.MESSAGE_TYPE_DEFS = {
	recommendReunionInvite = 19,
	breakEgg = 5,
	crossOfficial = 24,
	crossBattleShare = 23,
	crossCardShare = 22,
	crossChat = 21,
	official = 20,
	normal = 0,
	worldReunionInvite = 18,
	marqueeType = 17,
	yyHuoDongRedPacketType = 16,
	unionCardShare = 15,
	friendCloneInvite = 14,
	unionCloneInvite = 13,
	worldCloneInvite = 12,
	worldCardShare = 11,
	battleShare = 10,
	news = 9,
	roleChat = 8,
	unionChat = 7,
	worldChat = 6,
	unionPlay = 4,
	roleUnion = 3,
	cloneInvite = 2,
	unionJoinUp = 1
}
game.MESSAGE_SHOW_TYPE = {
	[game.MESSAGE_TYPE_DEFS.normal] = {
		1
	},
	[game.MESSAGE_TYPE_DEFS.unionJoinUp] = {
		1
	},
	[game.MESSAGE_TYPE_DEFS.cloneInvite] = {
		1
	},
	[game.MESSAGE_TYPE_DEFS.roleUnion] = {
		1
	},
	[game.MESSAGE_TYPE_DEFS.unionPlay] = {
		1
	},
	[game.MESSAGE_TYPE_DEFS.breakEgg] = {
		1
	},
	[game.MESSAGE_TYPE_DEFS.worldChat] = {
		2,
		3
	},
	[game.MESSAGE_TYPE_DEFS.unionChat] = {
		2,
		3
	},
	[game.MESSAGE_TYPE_DEFS.roleChat] = {
		2,
		3
	},
	[game.MESSAGE_TYPE_DEFS.news] = {
		1
	},
	[game.MESSAGE_TYPE_DEFS.battleShare] = {
		4
	},
	[game.MESSAGE_TYPE_DEFS.worldCloneInvite] = {
		4
	},
	[game.MESSAGE_TYPE_DEFS.unionCloneInvite] = {
		4
	},
	[game.MESSAGE_TYPE_DEFS.friendCloneInvite] = {
		4
	},
	[game.MESSAGE_TYPE_DEFS.worldCardShare] = {
		4
	},
	[game.MESSAGE_TYPE_DEFS.unionCardShare] = {
		4
	},
	[game.MESSAGE_TYPE_DEFS.yyHuoDongRedPacketType] = {
		4
	},
	[game.MESSAGE_TYPE_DEFS.marqueeType] = {
		1
	},
	[game.MESSAGE_TYPE_DEFS.worldReunionInvite] = {
		4
	},
	[game.MESSAGE_TYPE_DEFS.recommendReunionInvite] = {
		4
	},
	[game.MESSAGE_TYPE_DEFS.official] = {
		4
	},
	[game.MESSAGE_TYPE_DEFS.crossChat] = {
		2,
		3
	},
	[game.MESSAGE_TYPE_DEFS.crossCardShare] = {
		4
	},
	[game.MESSAGE_TYPE_DEFS.crossBattleShare] = {
		4
	}
}
game.GATE_TYPE = {
	worldBoss = 15,
	hunting = 26,
	braveChallenge = 25,
	summerChallenge = 27,
	clone = 12,
	newbie = 999,
	normal = 1,
	abyssEndlessTower = 39,
	crossCircus = 38,
	hellRandomTower = 37,
	experience = 36,
	dailyContract = 35,
	crossUnionAdventure = 34,
	contestbet = 33,
	mimicry = 32,
	bondEvolution = 31,
	battlebet = 30,
	crossSupremacy = 29,
	crossUnionFight = 28,
	huoDongBoss = 22,
	crossMineBoss = 24,
	crossMine = 23,
	crossOnlineFight = 21,
	crossGym = 20,
	gymLeader = 19,
	gym = 18,
	crossArena = 17,
	simpleActivity = 16,
	crossCraft = 14,
	unionFight = 13,
	gift = 7,
	randomTower = 11,
	craft = 10,
	friendFight = 9,
	fragment = 8,
	unionFuben = 6,
	endlessTower = 5,
	dailyExp = 4,
	dailyGold = 3,
	arena = 2,
	test = 0,
	skillTest = 99
}
game.GATE_TYPE_STRING_TABLE = {}

for k, v in pairs(game.GATE_TYPE) do
	game.GATE_TYPE_STRING_TABLE[v] = k
end

game.SCENE_TYPE = {
	worldBoss = 11,
	gate = 1,
	city = 0,
	braveChallenge = 19,
	hunting = 20,
	summerChallenge = 21,
	abyssEndlessTower = 28,
	huoDongBoss = 15,
	crossMineBoss = 18,
	crossMine = 17,
	crossOnlineFight = 13,
	gym = 14,
	crossArena = 12,
	crossCraft = 10,
	unionFight = 9,
	clone = 7,
	randomTower = 8,
	craft = 6,
	gymPvp = 16,
	huodongFuben = 3,
	unionFuben = 5,
	endlessTower = 4,
	arena = 2
}
game.TALENT_TYPE = {
	sceneType = 6,
	cardNatureType = 4,
	cardsAll = 3,
	battleBack = 2,
	battleFront = 1
}
game.EMBATTLE_FROM_TABLE = {
	hunting = "hunting",
	mimicry = "mimicry",
	hellRandomTowerReady = "hellRandomTowerReady",
	strangeMeteor = "strangeMeteor",
	supermacyElite = "supermacyElite",
	ready = "ready",
	huodongBoss = "huodongBoss",
	onekey = "onekey",
	onlineFight = "onlineFight",
	gymChallenge = "gymChallenge",
	huodong = "huodong",
	default = "default",
	endlessTower = "endlessTower",
	input = "input",
	arena = "arena",
	crossCircus = "crossCircus",
	hellRandomTower = "hellRandomTower"
}
game.EMBATTLE_GYMCHALLENGE_ID = {
	pve = "pve",
	pvp = "pvp"
}
game.SCENE_TYPE_STRING_TABLE = {}

for k, v in pairs(game.SCENE_TYPE) do
	game.SCENE_TYPE_STRING_TABLE[v] = k
end

game.NUM_TYPE = {
	percent = 0,
	number = 1
}
game.SELL_TYPE = {
	hand = 0,
	auto = 1
}
game.TARGET_TYPE = {
	DrawEquip = 52,
	DrawEquipRMB10 = 53,
	CloneBattleTimes = 66,
	RandomTowerFloorMax = 67,
	DailyTaskFinish = 70,
	DailyTaskAchieve = 71,
	ItemBuy = 72,
	YYHuodongOpen = 73,
	MimicryBattle = 136,
	ContractConvertCount = 135,
	TotemCount = 134,
	GymPassCount = 133,
	MedalGroupDone = 132,
	CrossCraftSignup = 131,
	RandomTowerBattleClearance = 130,
	MarkCardAdvanceCount = 129,
	MarkCardStarCount = 128,
	RandomTowerBattle = 127,
	DailyAllOnlineGift = 126,
	DailyLivenessPoint = 125,
	AutoChess = 124,
	DrawTotem = 123,
	DrawChip = 117,
	DrawChipItem = 116,
	DrawChipRMB = 115,
	HuntingSpecialPass = 114,
	HuntingPass = 113,
	RandomTowerFloorSum = 112,
	ReunionFriend = 111,
	CooperateClone = 110,
	FishingWinTimes = 109,
	FishingTimes = 108,
	DrawGemUpAndRMB = 107,
	DrawGemUp = 106,
	DrawGem = 105,
	DrawGemGold = 104,
	DrawGemRMB = 103,
	CraftSignup = 102,
	DispatchTask = 101,
	RandomTowerBattleWin = 100,
	TalentPointCost = 99,
	UnionFragDonate = 98,
	Top6FightingPoint = 97,
	DrawCardUpAndRMB = 96,
	DrawCardUp = 95,
	DrawItem = 94,
	EndlessChallenge = 93,
	CardAbilityStrength = 92,
	EffortSeniorTrainTimes = 91,
	EffortGeneralTrainTimes = 90,
	EffortTrainTimes = 89,
	HeldItemAdvance = 88,
	HeldItemStrength = 87,
	DispatchTaskQualityDone = 86,
	DispatchTaskDone = 85,
	ExplorerAdvance = 84,
	ExplorerComponentStrength = 83,
	Explorer = 82,
	CaptureSuccessSum = 81,
	CaptureLevel = 80,
	TrainerLevel = 79,
	Friends = 78,
	RandomTowerPoint = 63,
	RandomTowerPointDaily = 62,
	RandomTowerBoxOpen = 61,
	RandomTowerTimes = 60,
	UnionFuben = 59,
	UnionRobPacket = 58,
	UnionSendPacket = 57,
	UnionSpeedup = 56,
	UnionContrib = 55,
	DrawEquipRMB1 = 54,
	WorldBossBattleTimes = 65,
	RandomTowerFloorTimes = 64,
	DrawCardGold = 51,
	DrawCardRMB = 50,
	DrawCardGold1 = 49,
	DrawCardGold10 = 48,
	DrawCardRMB1 = 47,
	DrawCardRMB10 = 46,
	DrawCard = 45,
	ArenaRank = 44,
	ArenaPoint = 43,
	ArenaBattleWin = 42,
	ArenaBattle = 41,
	EquipStar = 40,
	EquipAdvance = 39,
	EquipStrength = 38,
	CardStar = 37,
	CardLevelUp = 36,
	CardAdvance = 35,
	CardSkillUp = 34,
	GateSum = 33,
	HuodongChanllenge = 32,
	NightmareGateChanllenge = 31,
	HeroGateChanllenge = 30,
	GateChanllenge = 29,
	CostStamina = 28,
	GiveStaminaTimes = 27,
	BuyStaminaTimes = 26,
	SigninTimes = 25,
	ShareTimes = 23,
	RechargeRmb = 22,
	CostRmb = 21,
	CostGold = 20,
	GainGold = 19,
	LianjinTimes = 18,
	LoginDays = 17,
	OnlineDuration = 16,
	CompleteImmediate = 15,
	GainCardTimes = 14,
	HadCard = 13,
	EquipStarCount = 12,
	EquipAdvanceCount = 11,
	CardStarCount = 10,
	CardAdvanceCount = 9,
	GateStar = 8,
	CardAdvanceTotalTimes = 7,
	FightingPoint = 6,
	Vip = 5,
	CardGainTotalTimes = 4,
	CardsTotal = 3,
	Gate = 2,
	Level = 1,
	EndlessPassed = 77,
	UnlockPokedex = 76,
	UnionContribSum = 75,
	UnionDailyGiftTimes = 74
}
game.EMBATTLE_HOUDONG_ID = {
	worldBoss = -4,
	nightmare = -2,
	endlessTower = -5,
	crossMineBoss = -6,
	abyssEndlessTower = -7,
	randomTower = -1,
	unionGate = -3
}
game.PRIVILEGE_TYPE = {
	BattleSkip = 5,
	LianjinBuyTimes = 4,
	StaminaBuyTimes = 3,
	StaminaMax = 2,
	FirstRMBDrawCardHalf = 1,
	HuodongTypeContractDropRate = 29,
	HuodongTypeContractTimes = 28,
	FirstRMBDrawItemHalf = 27,
	HuodongTypeFragDropRate = 26,
	HuodongTypeFragTimes = 25,
	HuodongTypeGiftDropRate = 24,
	HuodongTypeGiftTimes = 23,
	DispatchTaskFreeRefreshTimes = 22,
	DrawItemFreeTimes = 21,
	GateSaoDangTimes = 20,
	HeroGateGoldDropRate = 19,
	GateGoldDropRate = 18,
	UnionContribCoinRate = 17,
	HuodongTypeExpDropRate = 16,
	HuodongTypeGoldDropRate = 15,
	StaminaGain = 14,
	LianjinDropRate = 13,
	LianjinFreeTimes = 12,
	FreeGoldDrawCardTimes = 11,
	TrainerAttrSkills = 10,
	ExpItemCostFallRate = 9,
	HuodongTypeExpTimes = 8,
	HuodongTypeGoldTimes = 7,
	DailyTaskExpRate = 6
}
game.PRIVILEGE_TYPE_STRING_TABLE = {}

for k, v in pairs(game.PRIVILEGE_TYPE) do
	game.PRIVILEGE_TYPE_STRING_TABLE[v] = k
end

game.DOUBLE_HUODONG = {
	buyGold = 6,
	fragActivity = 5,
	giftActivity = 4,
	expActivity = 3,
	goldActivity = 2,
	gateDrop = 1,
	endlessSaodang = 9,
	randomGold = 10,
	contractActivity = 11,
	heroGateTimes = 8,
	buyStamina = 7
}
game.REUNION_DOUBLE = {
	huodongCount = 1,
	doubleBuyStamina = 4,
	doubleDropGate = 3,
	doubleLianjin = 5,
	endlessSaodang = 2
}
game.NORMAL_TO_REUNION = {
	[game.DOUBLE_HUODONG.gateDrop] = game.REUNION_DOUBLE.doubleDropGate,
	[game.DOUBLE_HUODONG.endlessSaodang] = game.REUNION_DOUBLE.endlessSaodang,
	[game.DOUBLE_HUODONG.goldActivity] = game.REUNION_DOUBLE.huodongCount,
	[game.DOUBLE_HUODONG.expActivity] = game.REUNION_DOUBLE.huodongCount,
	[game.DOUBLE_HUODONG.giftActivity] = game.REUNION_DOUBLE.huodongCount,
	[game.DOUBLE_HUODONG.fragActivity] = game.REUNION_DOUBLE.huodongCount,
	[game.DOUBLE_HUODONG.buyStamina] = game.REUNION_DOUBLE.doubleBuyStamina,
	[game.DOUBLE_HUODONG.buyGold] = game.REUNION_DOUBLE.doubleLianjin
}
game.CROSS_CRAFT_ROUNDS = {
	"closed",
	"signup",
	"prepare",
	"pre11",
	"pre11_lock",
	"pre12",
	"pre12_lock",
	"pre13",
	"pre13_lock",
	"pre14",
	"pre14_lock",
	"pre21",
	"pre21_lock",
	"pre22",
	"pre22_lock",
	"pre23",
	"pre23_lock",
	"pre24",
	"pre24_lock",
	"halftime",
	"prepare2",
	"pre31",
	"pre31_lock",
	"pre32",
	"pre32_lock",
	"pre33",
	"pre33_lock",
	"pre34",
	"pre34_lock",
	"top64",
	"top64_lock",
	"top32",
	"top32_lock",
	"top16",
	"top16_lock",
	"final1",
	"final1_lock",
	"final2",
	"final2_lock",
	"final3",
	"final3_lock"
}
game.CROSS_CRAFT_ROUND_STATE = {
	closed = {},
	signup = {
		time = 31800
	},
	prepare = {
		time = 600
	},
	pre11 = {
		time = 180
	},
	pre11_lock = {
		time = 60
	},
	pre12 = {
		time = 180
	},
	pre12_lock = {
		time = 60
	},
	pre13 = {
		time = 180
	},
	pre13_lock = {
		time = 60
	},
	pre14 = {
		time = 180
	},
	pre14_lock = {
		time = 60
	},
	pre21 = {
		time = 180
	},
	pre21_lock = {
		time = 60
	},
	pre22 = {
		time = 180
	},
	pre22_lock = {
		time = 60
	},
	pre23 = {
		time = 180
	},
	pre23_lock = {
		time = 60
	},
	pre24 = {
		time = 180
	},
	pre24_lock = {
		time = 60
	},
	halftime = {
		time = 83880
	},
	prepare2 = {
		time = 600
	},
	pre31 = {
		time = 180
	},
	pre31_lock = {
		time = 60
	},
	pre32 = {
		time = 180
	},
	pre32_lock = {
		time = 60
	},
	pre33 = {
		time = 180
	},
	pre33_lock = {
		time = 60
	},
	pre34 = {
		time = 180
	},
	pre34_lock = {
		time = 60
	},
	top64 = {
		time = 240
	},
	top64_lock = {
		time = 60
	},
	top32 = {
		time = 240
	},
	top32_lock = {
		time = 60
	},
	top16 = {
		time = 240
	},
	top16_lock = {
		time = 60
	},
	final1 = {
		time = 240
	},
	final1_lock = {
		time = 60
	},
	final2 = {
		time = 240
	},
	final2_lock = {
		time = 60
	},
	final3 = {
		time = 240
	},
	final3_lock = {
		time = 60
	}
}
game.RANDOM_TOWER_JUMP_STATE = {
	BOX = 2,
	POINT = 1,
	BEGIN = 0,
	OVER = 5,
	EVENT = 4,
	BUFF = 3
}
game.HUNTING_JUMP_STATE = {
	BOX = 2,
	POINT = 1,
	BEGIN = 0,
	OVER = 4,
	BUFF = 3
}
game.BRAVE_CHALLENGE_JUMP_STATE = {
	OVER = 3,
	POINT = 1,
	BEGIN = 0,
	BUFF = 2
}
game.DEPLOY_TYPE = {
	OneByOneType = 2,
	GeneralType = 1,
	MultThree = 5,
	MultTwo = 4,
	WheelType = 3
}
game.SYNC_SCENE_STATE = {
	attack = 5,
	waitloading = 4,
	deploy = 3,
	banpick = 2,
	unknown = 0,
	waitresult = 6,
	battleover = 7,
	start = 1
}
game.TOWN_COIN = {
	TIANDIAN = 8201,
	GANGJIEGOU = 8203,
	MUCAI = 8202
}
game.SHOP_INIT = {
	CROSS_SUPREMACY_SHOP = 17,
	HUNTING_SHOP = 16,
	CROSS_MINE_SHOP = 15,
	SKIN_SHOP = 14,
	ONLINE_FIGHT_SHOP = 13,
	FISHING_SHOP = 12,
	CROSS_ARENA_SHOP = 11,
	CROSS_CRAFT_SHOP = 10,
	UNION_FIGHT_SHOP = 9,
	EQUIP_SHOP = 8,
	CRAFT_SHOP = 7,
	RANDOM_TOWER_SHOP = 6,
	EXPLORER_SHOP = 5,
	PVP_SHOP = 4,
	FRAG_SHOP = 3,
	UNION_SHOP = 2,
	FIX_SHOP = 1,
	CROSS_UNION_ADVENTURE_SHOP = 21,
	SIGNIN_SHOP = 20,
	AUTO_CHESS_SHOP = 19,
	TOTEM_SHOP = 18
}
game.SHOP_GET_PROTOL = {
	"/game/fixshop/get",
	"/game/union/shop/get",
	"/game/frag/shop/get",
	nil,
	"/game/explorer/shop/get",
	"/game/random_tower/shop/get",
	nil,
	"/game/equipshop/get",
	nil,
	nil,
	nil,
	"/game/fishing/shop/get",
	[18] = "/game/totem/shop/get"
}
game.SHOP_UNLOCK_KEY = {
	{},
	{
		mustHaveUion = true,
		unlockKey = "unionShop"
	},
	{
		unlockKey = "fragmentShop"
	},
	{
		unlockKey = "arenaShop"
	},
	{
		unlockKey = "explorer"
	},
	{
		unlockKey = "randomTower"
	},
	{
		unlockKey = "craft"
	},
	{
		unlockKey = "drawEquip"
	},
	{
		mustHaveUion = true,
		unlockKey = "unionFight"
	},
	{
		unlockKey = "crossCraft"
	},
	[12] = {
		unlockKey = "fishing"
	},
	[13] = {
		unlockKey = "onlineFight"
	},
	[14] = {
		unlockKey = "skinShop"
	},
	[15] = {
		unlockKey = "crossMine"
	},
	[16] = {
		unlockKey = "hunting"
	},
	[17] = {
		unlockKey = "crossSupremacy"
	},
	[18] = {
		unlockKey = "totem"
	},
	[19] = {
		unlockKey = "autoChess"
	},
	[20] = {
		unlockKey = "signInShop"
	},
	[21] = {
		mustHaveUion = true,
		unlockKey = "crossUnionAdventure"
	}
}
game.TOWN_CARD_STATE = {
	ALCHEMYFACTORY = 3,
	REST = 2,
	TOWN = 1,
	IDLE = 0,
	NONE = -1,
	TEAM = 102,
	PARTYRECOVERED = 101,
	ANENERGIA = 100,
	CARDFULL = 99,
	PRODUCTION_THREE1 = 9,
	ALCHEMYFACTORY1 = 8,
	ADVENTURE = 7,
	FINANCIAL_CENTER = 6,
	PRODUCTION_FOUR = 5,
	PRODUCTION_THREE = 4
}
game.TOWN_SKILL_EFFECT = {
	B_TIME_COST_SUB = 5,
	B_ENERGY_COST_SUB = 4,
	A_ENERGY_COST_SUB = 3,
	A_INVEOTORY_ADD = 2,
	A_SPEED_UP = 1,
	C_ENERGY_SUB = 9,
	C_ACTION_SUB = 8,
	C_TIME_SUB = 7,
	C_AWARD_ADD = 6
}
game.TOWN_BUILDING_ID = {
	TERMINAL = 11,
	REST = 101,
	CUTTINGHOUSE1 = 9,
	GOLDHOUSE1 = 8,
	EXPLORATION = 7,
	BANKHOUSE = 6,
	DESSERTHOUSE = 5,
	CUTTINGHOUSE = 4,
	GOLDHOUSE = 3,
	HOME = 2,
	CENTER = 1,
	SUPERSHOP = 10,
	LAVA_RELIC = 17,
	SNOW_RELIC = 16,
	MOUNTAINOUS_RELIC = 15,
	DESERT_RELIC = 14,
	PARTY = 13,
	WISH = 12
}
game.UNLOCK_TYPE = {
	BUILDING_LEVEL = 1,
	WISH_TIMES = 4,
	EXPLORATION_STAGE = 3,
	HOME_FURN_COUNT = 2
}
game.SERVER_RAW_MODEL_KEY = {
	"carddbIDs",
	"card2fragL",
	"card2mailL",
	"chipdbIDs",
	"cards",
	"heldItemdbIDs",
	"gemdbIDs",
	"contractdbIDs"
}
game.RELIC_BUFF = {
	TOWN_LIANJIN = 11,
	TOWN_FELLING = 10,
	TOWN_DISPATCH = 9,
	LIANJIN = 8,
	BUY_STAMINA = 7,
	DISPATCH = 6,
	ENDLESSTOWER = 5,
	FRAGMENT_ECTYPAL = 4,
	GIFT_ECTYPAL = 3,
	EXP_ECTYPAL = 2,
	GOLD_ECTYPAL = 1,
	CONTRACT_ECTYPAL = 13,
	TOWN_DESSERT_SHOP = 12
}
game.TOWN_BUFF_TYPE = {
	[game.RELIC_BUFF.TOWN_FELLING] = {
		game.TOWN_BUILDING_ID.CUTTINGHOUSE,
		game.TOWN_BUILDING_ID.CUTTINGHOUSE1
	},
	[game.RELIC_BUFF.TOWN_LIANJIN] = {
		game.TOWN_BUILDING_ID.GOLDHOUSE,
		game.TOWN_BUILDING_ID.GOLDHOUSE1
	},
	[game.RELIC_BUFF.TOWN_DESSERT_SHOP] = {
		game.TOWN_BUILDING_ID.DESSERTHOUSE
	}
}
game.SKIN_GIVE = false
game.AID_FIRST_STAGE = {
	1,
	2,
	3,
	4,
	5,
	7
}
game.PLAY_PASSPORT_TYPE = {
	dailyTask = 2,
	login = 1,
	stamina = 5,
	cross = 6,
	randomTower = 3,
	gym = 4
}
game.UNKONW_CARD_ID = 9058
