csv['buff_2'] = {
	[762111] = {
		id = 762111,
		name = '超梦x',
		easyEffectFunc = 'damage',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_wgtg.png'
	},
	[762112] = {
		id = 762112,
		easyEffectFunc = 'breakBlock',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_pdyltg.png'
	},
	[762113] = {
		id = 762113,
		easyEffectFunc = 'suckBlood',
		overlayType = 1,
		overlayLimit = 1
	},
	[762114] = {
		id = 762114,
		easyEffectFunc = 'breakBlock',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_pdyltg.png'
	},
	[762115] = {
		id = 762115,
		easyEffectFunc = 'damageAdd',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_shtg.png'
	},
	[762116] = {
		id = 762116,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 15, ['damageType'] = 2, __size = 2}},
		buffFlag = {4021},
		skinEffect = {[7034] = 7031222, __size = 1}
	},
	[762117] = {
		id = 762117,
		easyEffectFunc = 'ignoreDamageSub',
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[762201] = {
		id = 762201,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'koudai_chaomengmegax/hero_chaomengmegax.skel',
		effectAniName = {'huajinchuxian_loop'},
		onceEffectResPath = 'koudai_chaomengmegax/hero_chaomengmegax.skel',
		onceEffectAniName = 'huajinchuxian',
		textResPath = 'battle/txt/txt_huajin.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 762202, ['caster'] = 2, ['value'] = '(2000+((skillLv(7622,7592) or 0)*10-10))', ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 5, ['cfgId'] = 762203, ['caster'] = 2, ['value'] = {'self:flagZ2() and 0.2 or 0.15', 1, 0}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'more(target:getSpecBuffSubkeySize("delayDamage","damageTb",list(762203) ),0)'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 762204, ['caster'] = 2, ['value'] = 'target:getSpecBuffFuncVal("delayDamage","getRoundDamage",list(762203) )', ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'curHeroNowTarget', ['process'] = 'buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|random(1)', __size = 2}, ['lifeRound'] = 1, ['value'] = 'math.min(self:Bdamage()*1.5,(self:hasBuff(762204) and self:getBuff(762204):getValue() or 0))', ['cfgId'] = 762206, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'curHeroNowTarget', ['process'] = 'buffDifferExclude(\'id\',{762206})|buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 762206, ['caster'] = 2, ['value'] = 'math.min(self:Bdamage()*1.5,(self:hasBuff(762204) and self:getBuff(762204):getValue() or 0))', ['prob'] = 'self:flagZ2() and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 762207, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 8, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {1044},
		skinEffect = {[759] = 762201, __size = 1}
	},
	[762202] = {
		id = 762202,
		easyEffectFunc = 'block',
		skillTimePos = 2,
		group = 1203,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_dyl_up.png',
		textResPath = 'battle/txt/txt_dyltg.png'
	},
	[762203] = {
		id = 762203,
		easyEffectFunc = 'delayDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		iconShowType = {1, 10}
	},
	[762204] = {
		id = 762204,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1
	},
	[762205] = {
		id = 762205,
		easyEffectFunc = 'reduceDelayDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {762203}
	},
	[762206] = {
		id = 762206,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_chaomengmegax/hero_chaomengmegax.skel',
		onceEffectAniName = 'huajinshouji',
		specialVal = {{['processId'] = 15, ['damageType'] = 2, __size = 2}},
		buffFlag = {4021}
	},
	[762207] = {
		id = 762207,
		skillTimePos = 2,
		dispelBuff = {762203},
		overlayType = 1,
		overlayLimit = 1
	},
	[762301] = {
		id = 762301,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 762302, ['caster'] = 2, ['value'] = {'self:hasBuff(759111) and 758 or 763', 99, 0, 1, 1, {['speed'] = '0.5+((skillLv(7623,7593) or 0)*0.005-0.005)', ['rebound'] = 0, ['hpMax'] = 1, ['damage'] = 1, ['specialDamage'] = 1, ['specialDefence'] = '0.5+((skillLv(7623,7593) or 0)*0.005-0.005)', ['defence'] = 1, __size = 7}, 1, {['y'] = -10, ['followMark'] = 15, ['x'] = -150, ['dealGroup'] = 5, __size = 4}, 1, 0}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[762302] = {
		id = 762302,
		name = '幻影低档概率',
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_canying.png',
		specialVal = {0, 0},
		specialTarget = {2},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 762303, ['caster'] = 20, ['value'] = {2, 0, 1, '(0.4+((skillLv(7622,7592) or 0)*0.002-0.002))'}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 762305, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762308, ['caster'] = 20, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[762303] = {
		id = 762303,
		easyEffectFunc = 'replaceTarget',
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762304, ['caster'] = 1, ['value'] = {1, 2, 19, 200}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762306, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999}
	},
	[762304] = {
		id = 762304,
		easyEffectFunc = 'damageAllocate',
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_bq.png',
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999}
	},
	[762305] = {
		id = 762305,
		easyEffectFunc = 'stun',
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'exitInTab(trigger.beAddBuff:getCfgId(),list(762306))'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 762307, ['caster'] = 2, ['value'] = 1, ['prob'] = 'moreE(self:getBuffOverlayCount(762306),2) and 1 or 0', __size = 6}}}, ['triggerPoint'] = 29, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762624, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999}
	},
	[762306] = {
		id = 762306,
		group = 1030001,
		overlayType = 8,
		overlayLimit = 2,
		buffFlag = {9999}
	},
	[762307] = {
		id = 762307,
		easyEffectFunc = 'kill',
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {true, true},
		buffFlag = {9999}
	},
	[762308] = {
		id = 762308,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'exitInTab(trigger.beAddBuff:getGroup(),list(c.kongzhi1_kongzhi2_oc()))'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 'list(list(c.kongzhi1_kongzhi2_oc()),2,99)', ['cfgId'] = 762309, ['caster'] = 20, __size = 5}}}, ['triggerPoint'] = 29, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999}
	},
	[762309] = {
		id = 762309,
		easyEffectFunc = 'transferBuffToOther',
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {1},
		lifeRoundType = 4,
		buffFlag = {9999}
	},
	[762411] = {
		id = 762411,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 32, ['nodeId'] = 0, __size = 3}},
		noDelWhenFakeDeath = 1,
		buffFlag = {9998}
	},
	[762412] = {
		id = 762412,
		easyEffectFunc = 'fieldBuff',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {411},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762413, ['caster'] = 2, ['value'] = {'3+(self:hasBuff(762636) and 1 or 0)+(self:hasBuff(762637) and 2 or 0)+(self:hasBuff(762638) and 2 or 0)', 'list(0,0,0)', 3, 1, 'list(list(0),list(0))', 0, 'list(1,1)', 0, 1}, ['bond'] = 2, ['prob'] = 'self:hasBuff(762412) and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[762413] = {
		id = 762413,
		easyEffectFunc = 'brawl',
		skillTimePos = 2,
		dispelBuff = {762401},
		overlayType = 1,
		overlayLimit = 1,
		deepCorrect = 11,
		specialVal = {{'assistAttack'}, {3007}},
		specialTarget = {{['input'] = 'And(enemyForce(),enemyForceEx())', ['process'] = 'buffDifferExclude(\'group\',{c.fly_oc()})|ignoreBuffGroup(list(c.yinshenplus_oc()))|buffDiffer(\'id\',{762411})|random(1)', __size = 2}},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'trigger.reason==2'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762414, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['triggerPoint'] = 28, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'trigger.reason==1 or trigger.reason==2'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 762651, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 28, ['nodeId'] = 2, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'trigger.reason==0'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 762453, ['caster'] = 2, ['value'] = '(target2:hp()-1)', ['prob'] = '(self:flagZ3() and self:hasBuff(762638) and (not target2:flag(99)) ) and 0.5 or 0', __size = 6}}}, ['triggerPoint'] = 28, ['nodeId'] = 3, __size = 5}, {['triggerTimes'] = {1, 1}, ['triggerPoint'] = 42, ['nodeId'] = 0, __size = 3}},
		buffFlag = {3004, 2017}
	},
	[762414] = {
		id = 762414,
		skillTimePos = 2,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_ylc.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 14, ['lifeRound'] = 999, ['cfgId'] = 762415, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 'moreE(self:damage(),target2:damage()) and 1 or 0', __size = 7}}, {{['holder'] = 14, ['lifeRound'] = 999, ['cfgId'] = 762431, ['caster'] = 2, ['value'] = 2000, ['bond'] = 1, ['prob'] = 'self:hasBuff(762636) and 1 or 0', __size = 7}}, {{['holder'] = 14, ['lifeRound'] = 999, ['cfgId'] = 762421, ['caster'] = 2, ['value'] = 2000, ['bond'] = 1, ['prob'] = 'self:hasBuff(762637) and 1 or 0', __size = 7}}, {{['holder'] = 14, ['lifeRound'] = 999, ['cfgId'] = 762441, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 'self:hasBuff(762638) and 1 or 0', __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762451, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = '(self:flagZ3() and self:hasBuff(762649) ) and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		stageArgs = {{['delay'] = 0, ['bkCsv'] = 'csv.stage.xlc', __size = 2}},
		iconShowType = {1, 10}
	},
	[762415] = {
		id = 762415,
		skillTimePos = 2,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 762416, ['caster'] = 2, ['value'] = 'math.min(target2:hp()*0.05+((skillLv(7624,7594) or 0)*0.001-0.001),self:hpMax()*0.3)', ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 762417, ['caster'] = 2, ['value'] = '500+((skillLv(7624,7594) or 0)*10-10)', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 30, ['cfgId'] = 762418, ['caster'] = 2, ['value'] = '500+((skillLv(7624,7594) or 0)*5-5)', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 30, ['cfgId'] = 762419, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 30, ['cfgId'] = 762461, ['caster'] = 2, ['value'] = {2, 99, 2}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 14, ['lifeRound'] = 30, ['cfgId'] = 762461, ['caster'] = 2, ['value'] = {2, 99, 2}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[762416] = {
		id = 762416,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 32, ['damageType'] = 2, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {4021},
		skinEffect = {[7034] = 7031222, __size = 1}
	},
	[762417] = {
		id = 762417,
		easyEffectFunc = 'damageSub',
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[762418] = {
		id = 762418,
		easyEffectFunc = 'damageAdd',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjc_up.png',
		textResPath = 'battle/txt/txt_shtg.png'
	},
	[762419] = {
		id = 762419,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762420, ['caster'] = 2, ['value'] = {16}, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[762420] = {
		id = 762420,
		easyEffectFunc = 'immuneDamage',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[762421] = {
		id = 762421,
		easyEffectFunc = 'damageReduce',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjc_down.png',
		textResPath = 'battle/txt/txt_shjd.png'
	},
	[762431] = {
		id = 762431,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 25, ['funcArgs'] = {{{['holder'] = 14, ['lifeRound'] = 1, ['cfgId'] = 762432, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 14, ['lifeRound'] = 1, ['cfgId'] = 762433, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 14, ['lifeRound'] = 1, ['cfgId'] = 762434, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}}
	},
	[762432] = {
		id = 762432,
		easyEffectFunc = 'filterFlag',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		specialVal = {{['selfForce'] = {'all'}, ['allForce'] = {}, ['enemyForce'] = {9999}, ['self'] = {'all'}, __size = 4}}
	},
	[762433] = {
		id = 762433,
		skillTimePos = 2,
		group = 70043,
		overlayType = 1,
		overlayLimit = 1
	},
	[762434] = {
		id = 762434,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		dispelBuff = {762432, 762433},
		overlayType = 1,
		overlayLimit = 1
	},
	[762441] = {
		id = 762441,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 762442, ['caster'] = 2, ['value'] = 2000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 14, ['lifeRound'] = 1, ['cfgId'] = 762443, ['caster'] = 2, ['value'] = -2000, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}}
	},
	[762442] = {
		id = 762442,
		easyEffectFunc = 'damageDeepen',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_ys.png'
	},
	[762443] = {
		id = 762443,
		easyEffectFunc = 'block',
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[762451] = {
		id = 762451,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762452, ['caster'] = 2, ['value'] = {1, 99, 0}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}}
	},
	[762452] = {
		id = 762452,
		easyEffectFunc = 'lockHp',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[762453] = {
		id = 762453,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 2001, ['damageType'] = 2, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 4021},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[762461] = {
		id = 762461,
		easyEffectFunc = 'alterDmgRecordVal',
		overlayLimit = 1,
		specialVal = {{['groupShield'] = 2, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1
	},
	[762611] = {
		id = 762611,
		easyEffectFunc = 'seal',
		overlayLimit = 1,
		specialVal = {0, 1, 2},
		noDelWhenFakeDeath = 1
	},
	[762612] = {
		id = 762612,
		easyEffectFunc = 'seal',
		overlayLimit = 1,
		specialVal = {0, 1, 2},
		noDelWhenFakeDeath = 1
	},
	[762621] = {
		id = 762621,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['onSomeFlag'] = {'(getExtraRoundId()~=762718) and (getExtraRoundId()~=762413)'}, ['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['value'] = 1, ['cfgId'] = 762624, ['caster'] = 2, __size = 5}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, ['onSkillType'] = 3, __size = 7}},
		noDelWhenFakeDeath = 1
	},
	[762622] = {
		id = 762622,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['onSomeFlag'] = {'(getExtraRoundId()~=762718) and (getExtraRoundId()~=762413)'}, ['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['value'] = 1, ['cfgId'] = 762624, ['caster'] = 2, __size = 5}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, ['onSkillType'] = 2, __size = 7}},
		noDelWhenFakeDeath = 1
	},
	[762623] = {
		id = 762623,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['onSomeFlag'] = {'(getExtraRoundId()~=762718) and (getExtraRoundId()~=762413)'}, ['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['value'] = 1, ['cfgId'] = 762624, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 762652, ['caster'] = 2, __size = 5}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSkillType'] = 1, __size = 7}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[762624] = {
		id = 762624,
		group = 5311,
		overlayType = 8,
		overlayLimit = 12,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762625, ['caster'] = 2, ['value'] = 500, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762626, ['caster'] = 2, ['value'] = 'self:Bdamage()*0.03', ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762627, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		extraOverlayLimit = {['zawake'] = {4, 4}, __size = 1}
	},
	[762625] = {
		id = 762625,
		easyEffectFunc = 'breakBlock',
		overlayType = 8,
		overlayLimit = 12,
		noDelWhenFakeDeath = 1,
		extraOverlayLimit = {['zawake'] = {4, 4}, __size = 1}
	},
	[762626] = {
		id = 762626,
		easyEffectFunc = 'damage',
		overlayType = 8,
		overlayLimit = 12,
		iconResPath = 'battle/buff_icon/logo_wg_up.png',
		textResPath = 'battle/txt/txt_wgtg.png',
		noDelWhenFakeDeath = 1,
		extraOverlayLimit = {['zawake'] = {4, 4}, __size = 1}
	},
	[762627] = {
		id = 762627,
		overlayType = 8,
		overlayLimit = 13,
		holderActionType = {['typ'] = 'comboPoint', ['args'] = {['res'] = 'koudai_chaomengmegax/hero_chaomengmegax.skel', ['activeAction'] = 'quanyilianjie_loop', ['highLightLimit'] = 4, ['hideEmptyPoint'] = true, __size = 4}, __size = 2},
		noDelWhenFakeDeath = 1,
		skinEffect = {[759] = 762624, __size = 1},
		extraOverlayLimit = {['zawake'] = {4, 4}, __size = 1}
	},
	[762628] = {
		id = 762628,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['value'] = 1, ['cfgId'] = 762627, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[762631] = {
		id = 762631,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'exitInTab(trigger.beAddBuff:getCfgId(),list(762624))'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762632, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762633, ['caster'] = 2, ['value'] = 1, ['prob'] = 'moreE(self:getBuffOverlayCount(762624),4) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 762644, ['caster'] = 2, ['value'] = 1, ['prob'] = 'moreE(self:getBuffOverlayCount(762624),4) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762634, ['caster'] = 2, ['value'] = 1, ['prob'] = 'moreE(self:getBuffOverlayCount(762624),8) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762635, ['caster'] = 2, ['value'] = 1, ['prob'] = '(moreE(self:getBuffOverlayCount(762624),12) and self:flagZ4())  and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762645, ['caster'] = 2, ['value'] = 1, ['prob'] = '(self:getBuffOverlayCount(762624)==4 or self:getBuffOverlayCount(762624)==8  or self:getBuffOverlayCount(762624)==12 or self:getBuffOverlayCount(762624)==16) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762648, ['caster'] = 2, ['value'] = 1, ['prob'] = '(self:getBuffOverlayCount(762624)==4 or self:getBuffOverlayCount(762624)==8  or self:getBuffOverlayCount(762624)==12 or self:getBuffOverlayCount(762624)==16) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 762653, ['caster'] = 2, ['value'] = {'list(0,0,1)', 1, 0}, ['prob'] = '(self:getBuffOverlayCount(762624)==16 ) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 762649, ['caster'] = 2, ['value'] = 1, ['prob'] = '(( (self:flagZ4() and  (self:getBuffOverlayCount(762624)==16))) or ((not self:flagZ4()) and (self:getBuffOverlayCount(762624)==12)))  and 1 or 0', __size = 6}}}, ['triggerPoint'] = 29, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'exitInTab(trigger.beAddBuff:getCfgId(),list(762636,762637,762638)) and (not self:hasBuff(759111))'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762643, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762642, ['caster'] = 2, ['value'] = {'list(7621)', 'list(7629)'}, ['prob'] = '(self:hasBuff(762638) and self:flagZ1()) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762641, ['caster'] = 2, ['value'] = {'list(7621)', 'list(7628)'}, ['prob'] = '(self:hasBuff(762637)) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762640, ['caster'] = 2, ['value'] = {'list(7621)', 'list(7627)'}, ['prob'] = '(self:hasBuff(762636)) and 1 or 0', __size = 6}}}, ['triggerPoint'] = 29, ['nodeId'] = 2, __size = 5}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'exitInTab(trigger.beAddBuff:getCfgId(),list(762636,762637,762638)) and (self:hasBuff(759111))'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762643, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762642, ['caster'] = 2, ['value'] = {'list(7591)', 'list(7599)'}, ['prob'] = '(self:hasBuff(762638)and self:flagZ1()) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762641, ['caster'] = 2, ['value'] = {'list(7591)', 'list(7598)'}, ['prob'] = '(self:hasBuff(762637)) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762640, ['caster'] = 2, ['value'] = {'list(7591)', 'list(7597)'}, ['prob'] = '(self:hasBuff(762636)) and 1 or 0', __size = 6}}}, ['triggerPoint'] = 29, ['nodeId'] = 3, __size = 5}},
		noDelWhenFakeDeath = 1
	},
	[762632] = {
		id = 762632,
		dispelBuff = {762633, 762634, 762635},
		overlayType = 1,
		overlayLimit = 1
	},
	[762633] = {
		id = 762633,
		dispelBuff = {762634, 762635},
		overlayLimit = 1,
		noDelWhenFakeDeath = 1,
		spineEffect = {['action'] = {['skill_1'] = 's2_2', ['skill1'] = 's1_2', __size = 2}, ['unitRes'] = {'koudai_chaomengmegax/hero_chaomengmegax.skel'}, __size = 2}
	},
	[762634] = {
		id = 762634,
		dispelBuff = {762633, 762635},
		overlayLimit = 1,
		noDelWhenFakeDeath = 1,
		spineEffect = {['action'] = {['skill_1'] = 's2_4', ['skill1'] = 's1_4', __size = 2}, ['unitRes'] = {'koudai_chaomengmegax/hero_chaomengmegax.skel'}, __size = 2}
	},
	[762635] = {
		id = 762635,
		dispelBuff = {762634, 762635},
		overlayLimit = 1,
		noDelWhenFakeDeath = 1,
		spineEffect = {['action'] = {['skill_1'] = 's2_5', ['skill1'] = 's1_5', __size = 2}, ['unitRes'] = {'koudai_chaomengmegax/hero_chaomengmegax.skel'}, __size = 2}
	},
	[762636] = {
		id = 762636,
		dispelBuff = {762637, 762638},
		overlayLimit = 1
	},
	[762637] = {
		id = 762637,
		dispelBuff = {762636, 762638},
		overlayLimit = 1
	},
	[762638] = {
		id = 762638,
		dispelBuff = {762636, 762637},
		overlayLimit = 1
	},
	[762640] = {
		id = 762640,
		easyEffectFunc = 'replaceSkill',
		dispelBuff = {762641, 762642},
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[762641] = {
		id = 762641,
		easyEffectFunc = 'replaceSkill',
		dispelBuff = {762640, 762642},
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[762642] = {
		id = 762642,
		easyEffectFunc = 'replaceSkill',
		dispelBuff = {762640, 762641},
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[762643] = {
		id = 762643,
		dispelBuff = {762640, 762641, 762642},
		overlayType = 1,
		overlayLimit = 1
	},
	[762644] = {
		id = 762644,
		dispelBuff = {762611},
		overlayType = 1,
		overlayLimit = 1
	},
	[762645] = {
		id = 762645,
		overlayType = 2,
		overlayLimit = 3,
		onceEffectResPath = 'koudai_chaomengmegax/hero_chaomengmegax.skel',
		onceEffectAniName = 'quanyichufa',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerTimes'] = {1, 1}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 762646, ['caster'] = 2, ['value'] = 1, ['prob'] = 'target2:hasBuff(762612) and 1 or 0', __size = 6}}}, ['triggerPoint'] = 1, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'exitInTab(trigger.beAddBuff:getCfgId(),list(762612))'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 762646, ['caster'] = 2, ['value'] = 1, ['prob'] = 'target2:hasBuff(762612) and 1 or 0', __size = 6}}}, ['triggerPoint'] = 29, ['nodeId'] = 2, __size = 5}},
		noDelWhenFakeDeath = 1
	},
	[762646] = {
		id = 762646,
		skillTimePos = 2,
		dispelBuff = {762612},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 762647, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[762647] = {
		id = 762647,
		skillTimePos = 2,
		dispelBuff = {762645},
		dispelType = {3, 0, 1},
		overlayType = 1,
		overlayLimit = 1
	},
	[762648] = {
		id = 762648,
		skillTimePos = 2,
		immuneBuff = {762624},
		overlayType = 1,
		overlayLimit = 1
	},
	[762649] = {
		id = 762649,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 762650, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		lifeRoundType = 6,
		noDelWhenFakeDeath = 1
	},
	[762650] = {
		id = 762650,
		skillTimePos = 2,
		dispelBuff = {762624},
		overlayType = 1,
		overlayLimit = 1
	},
	[762651] = {
		id = 762651,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 762638, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(762635) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 762637, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(762634) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 762636, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(762633) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 762654, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(762649) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[762652] = {
		id = 762652,
		dispelBuff = {762648},
		overlayType = 1,
		overlayLimit = 1,
		buffFlag = {9999}
	},
	[762653] = {
		id = 762653,
		easyEffectFunc = 'assistAttack',
		skillTimePos = 2,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'(getExtraRoundId()==762653)'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 762645, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[762654] = {
		id = 762654,
		skillTimePos = 2,
		overlayType = 2,
		overlayLimit = 2,
		noDelWhenFakeDeath = 1
	},
	[762655] = {
		id = 762655,
		skillTimePos = 2,
		dispelBuff = {762649},
		overlayType = 1,
		overlayLimit = 1
	},
	[762681] = {
		id = 762681,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['value'] = {0}, ['cfgId'] = 762682, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}}
	},
	[762682] = {
		id = 762682,
		easyEffectFunc = 'aura',
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {2},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['value'] = '0.2*self:Bdamage()*(math.min(1,((self:lostHp()) / (self:hpMax())) ))', ['cfgId'] = 762683, ['caster'] = 2, __size = 5}}, {{['holder'] = 20, ['lifeRound'] = 999, ['value'] = '0.2* math.floor(math.min(1,((self:lostHp()) / (self:hpMax())) )*10000)', ['cfgId'] = 762684, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[762683] = {
		id = 762683,
		easyEffectFunc = 'damage',
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[762684] = {
		id = 762684,
		easyEffectFunc = 'breakBlock',
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[762686] = {
		id = 762686,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'exitInTab(trigger.beAddBuff:getGroup(),list(c.kongzhi1_kongzhi2_oc()))'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = {'list(list(list(c.kongzhi1_kongzhi2_oc()),list()),list(762688),list(2,1),1,2,1)'}, ['cfgId'] = 762687, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 29, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[762687] = {
		id = 762687,
		easyEffectFunc = 'atOnceTransformAttrBuff',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3003}
	},
	[762688] = {
		id = 762688,
		easyEffectFunc = 'silence',
		skillTimePos = 2,
		group = 107,
		ignoreControlVal = 1,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_cm.png',
		effectResPath = 'buff/chenmo/chenmo.skel',
		effectAniName = {'chenmo_loop'},
		effectPos = 1,
		effectOffsetPos = {['y'] = -320, ['x'] = 0, __size = 2},
		textResPath = 'battle/txt/txt_cm.png',
		specialVal = {0}
	},
	[762691] = {
		id = 762691,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['value'] = {1, 99, 1}, ['cfgId'] = 762692, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[762692] = {
		id = 762692,
		easyEffectFunc = 'alterDmgRecordVal',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['finalRate'] = {'setValue(list(\'finalDamageAdd\'), not attacker:curSkill():getDamageState(\'block\')   and list(env:finalDamageAdd()*10000+(5+attacker:skillLv(7626,7596) *0.1-0.1)*100) or  list(env:finalDamageAdd()*10000) )'}, __size = 1}},
		noDelWhenFakeDeath = 1
	},
	[762695] = {
		id = 762695,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['value'] = {'list()', 'list(c.yinshen_oc())'}, ['cfgId'] = 762696, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 999, ['value'] = {2, 99, 1}, ['cfgId'] = 762697, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[762696] = {
		id = 762696,
		easyEffectFunc = 'ignoreSpecBuff',
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[762697] = {
		id = 762697,
		easyEffectFunc = 'alterDmgRecordVal',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['finalRate'] = {'setValue(list("finalDamageSub"),((target:checkIsSkillTarget() )) and list(env:finalDamageSub()*10000+(5+attacker:skillLv(7626,7596) *0.1-0.1)*100) or list(env:finalDamageSub()*10000))'}, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[762701] = {
		id = 762701,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'lessE(getNowRound(),5) and ( not self:hasBuff(762705) ) and (getExtraRoundMode()~=7 and getExtraRoundMode()~=8 and getExtraRoundMode()~=9)'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'attr("damage","max",1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 762704, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 762702, ['caster'] = 2, ['value'] = 1, ['prob'] = 'self:hasBuff(762704) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 762705, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 5, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[762702] = {
		id = 762702,
		easyEffectFunc = 'atOnceBattleRound',
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 762703, ['caster'] = 2, ['value'] = {-1, 762702}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2
	},
	[762703] = {
		id = 762703,
		easyEffectFunc = 'changeSpeedPriority',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {1},
		lifeRoundType = 2
	},
	[762704] = {
		id = 762704,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_qyzs.png',
		lifeRoundType = 6,
		noDelWhenFakeDeath = 1
	},
	[762705] = {
		id = 762705,
		overlayLimit = 1,
		lifeRoundType = 6,
		noDelWhenFakeDeath = 1
	},
	[762709] = {
		id = 762709,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762711, ['caster'] = 2, ['value'] = {1, 99, 0}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[762710] = {
		id = 762710,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[762711] = {
		id = 762711,
		easyEffectFunc = 'lockHp',
		overlayType = 1,
		overlayLimit = 1,
		triggerPriority = 11,
		specialVal = {'not self:hasBuff(762405)'},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'not self:hasBuff(762715)'}, ['triggerPoint'] = 28, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 762712, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 23, ['lifeRound'] = 2, ['cfgId'] = 762713, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762714, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762715, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerTimes'] = {1, 1}, ['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, __size = 6}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 42, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 762716, ['caster'] = 2, ['value'] = 0, ['prob'] = '(self:hasBuff(762714) and (not target2:hasBuff(762718,762712)) and  (getExtraRoundMode()~=7 and getExtraRoundMode()~=8 and getExtraRoundMode()~=9)) and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[762712] = {
		id = 762712,
		overlayType = 1,
		overlayLimit = 1,
		deepCorrect = 15,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'getExtraRoundMode()~=7 and getExtraRoundMode()~=8 and getExtraRoundMode()~=9 and (not  self:hasBuff(764041) )'}, ['triggerPoint'] = 42, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 20, ['cfgId'] = 762717, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['delSelfWhenTriggered'] = 1, ['triggerTimes'] = {1, 1}, ['effectFuncs'] = {'castBuff'}, __size = 7}}
	},
	[762713] = {
		id = 762713,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		buffFlag = {9998}
	},
	[762714] = {
		id = 762714,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[762715] = {
		id = 762715,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[762716] = {
		id = 762716,
		dispelBuff = {762711},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[762717] = {
		id = 762717,
		easyEffectFunc = 'fieldBuff',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {412},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762718, ['caster'] = 2, ['value'] = {10, 'list(0,0,0)', 4, 1, 'list(list(0,1),list(0))', 0, 'list(1,1)', 0, 1}, ['bond'] = 2, ['prob'] = 'self:hasBuff(762717) and 1 or 0', __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 762719, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(762685) and 0 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[762718] = {
		id = 762718,
		easyEffectFunc = 'brawl',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{'assistAttack'}, {3007}},
		specialTarget = {{['input'] = 'enemyForce()', ['process'] = 'buffDifferExclude(\'group\',{c.fly_oc()})|ignoreBuffGroup(list(c.yinshenplus_oc()))|buffDifferExclude(\'id\',{762710})|buffDifferOptional(\'id\',{762713})|random(1)', __size = 2}},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'trigger.reason==2'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762720, ['caster'] = 2, ['value'] = 1, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 14, ['lifeRound'] = 999, ['cfgId'] = 762431, ['caster'] = 2, ['value'] = 2000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 14, ['lifeRound'] = 999, ['cfgId'] = 762421, ['caster'] = 2, ['value'] = 2000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 14, ['lifeRound'] = 999, ['cfgId'] = 762441, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 762451, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 'self:flagZ3() and 1 or 0', __size = 7}}}, ['triggerPoint'] = 28, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'trigger.reason==0  or trigger.reason==3'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 762721, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 28, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {3004, 2017}
	},
	[762719] = {
		id = 762719,
		skillTimePos = 2,
		dispelBuff = {762717},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1
	},
	[762720] = {
		id = 762720,
		skillTimePos = 2,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_ylc_slj.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 762722, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 'target2:hpMax()*0.3', ['cfgId'] = 762723, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 30, ['cfgId'] = 762419, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 30, ['cfgId'] = 762461, ['caster'] = 2, ['value'] = {2, 99, 2}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 14, ['lifeRound'] = 30, ['cfgId'] = 762461, ['caster'] = 2, ['value'] = {2, 99, 2}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		stageArgs = {{['delay'] = 0, ['bkCsv'] = 'csv.stage.xlcsdj', __size = 2}},
		iconShowType = {1, 10}
	},
	[762721] = {
		id = 762721,
		dispelBuff = {762718, 762720},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[762722] = {
		id = 762722,
		group = 60000,
		overlayType = 1,
		overlayLimit = 1
	},
	[762723] = {
		id = 762723,
		easyEffectFunc = 'addHP',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'buff/zhiliao/zhiliao.skel',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[759111] = {
		id = 759111,
		name = '官方使用超x皮肤补的',
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[4121650] = {
		id = 4121650,
		name = '召唤物专用',
		immuneBuff = {4121311, 4121411},
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[2821147] = {
		id = 2821147,
		name = '召唤物专用',
		immuneBuff = {2821127},
		overlayType = 1,
		overlayLimit = 1,
		iconShowType = {1, 10}
	},
	[764011] = {
		id = 764011,
		name = '超梦y',
		skillTimePos = 2,
		dispelBuff = {764021},
		overlayLimit = 1,
		holderActionType = {['list'] = {{['typ'] = 'hide', ['args'] = {['sprite'] = {['isShow'] = false, __size = 1}, ['other'] = {['isShow'] = false, __size = 1}, ['lifebar'] = {['isShow'] = false, __size = 1}, __size = 3}, ['playType'] = 1, __size = 3}, {['typ'] = 'onceEffect', ['args'] = {['onceEffectOffsetPos'] = {['y'] = 0, ['x'] = 0, __size = 2}, ['onceEffectAniName'] = 'bianshen', ['onceEffectResPath'] = 'koudai_chaomengmegay/hero_chaomengmegay.skel', __size = 3}, ['playType'] = 1, __size = 3}, {['typ'] = 'wait', ['args'] = {['lifetime'] = 2360, __size = 1}, ['playType'] = 1, __size = 3}, {['typ'] = 'hide', ['args'] = {['sprite'] = {['isShow'] = true, __size = 1}, ['other'] = {['isShow'] = true, __size = 1}, ['lifebar'] = {['isShow'] = true, __size = 1}, __size = 3}, ['playType'] = 1, __size = 3}}, __size = 1},
		textResPath = 'battle/txt/txt_jst.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 764033, ['caster'] = 2, ['value'] = {'list(7672,7642)', 2, 1, 1}, ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 764012, ['caster'] = 2, ['value'] = 1678, ['bond'] = 1, ['prob'] = 0, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 764013, ['caster'] = 2, ['value'] = {1, 99, 1}, ['bond'] = 1, ['prob'] = 0, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 764014, ['caster'] = 2, ['value'] = {99, 1, 0, 0, 0}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 764623, ['caster'] = 2, ['value'] = 'self:hp()+target:BhpMax()*0.1', ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 764031, ['caster'] = 2, ['value'] = 'ifElse(target2:getBuff(764622):getValue()==0,1,max(0.01,target2:getBuff(764622):getValue()/target2:hpMax()))', ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 764623, ['caster'] = 2, ['ignoreField'] = 1, ['value'] = 'target:getBuff(764623):getValue()+target:BhpMax()*0.1', ['prob'] = 0, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'not self:hasBuff(764683)'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 764622, ['caster'] = 2, ['value'] = 'self:hp()+target:BhpMax()*0.1', ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 764021, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 764031, ['caster'] = 2, ['value'] = 'ifElse(target2:getBuff(764623):getValue()==0,1,max(0.01,target2:getBuff(764623):getValue()/target2:hpMax()))', ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 2, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {1012, 1044},
		spineEffect = {['action'] = {['attack'] = 'jst_attack', ['skill2'] = 'skill2', ['hit'] = 'jst_hit', ['run_loop'] = 'jst_run_loop', ['standby_loop'] = 'jst_standby_loop', ['skill1'] = 'skill1', __size = 6}, ['unitRes'] = {'koudai_chaomengmegay/hero_chaomengmegay.skel', 'koudai_chaomengmegay_pifu/hero_chaomengmegay_pifu.skel'}, __size = 2},
		skinEffect = {[767] = 764011, __size = 1}
	},
	[764012] = {
		id = 764012,
		easyEffectFunc = 'finalDamageSub',
		overlayType = 1,
		overlayLimit = 1
	},
	[764013] = {
		id = 764013,
		easyEffectFunc = 'alterDmgRecordVal',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['damageAdd'] = {'setValue(list("damageAdd"),(intersection(arg.buffFlag,list(7643)) or attacker:curSkill():skillFlag(7643) ==true) and list(env:damageAdd()*10000+1000) or list(env:damageAdd()*10000 ))'}, __size = 1}}
	},
	[764014] = {
		id = 764014,
		easyEffectFunc = 'lockHp',
		overlayLimit = 1,
		specialVal = {'not target:hasBuff(764684)'},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 764015, ['caster'] = 2, ['value'] = {1}, ['bond'] = 2, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffActionEffect = {['triggerEffect'] = {['onceEffectAniName'] = 'effect', ['textResPath'] = 'battle/txt/txt_mysw.png', ['onceEffectResPath'] = 'buff/miansi/miansi.skel', __size = 3}, __size = 1}
	},
	[764015] = {
		id = 764015,
		easyEffectFunc = 'immuneDamage',
		overlayLimit = 1,
		triggerPriority = 0,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 42, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['value'] = 'ifElse(target2:getBuff(764622):getValue()==0,1,max(0.01,target2:getBuff(764622):getValue()/target2:hpMax()))', ['cfgId'] = 764031, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 1, ['cfgId'] = 764021, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[764021] = {
		id = 764021,
		skillTimePos = 2,
		dispelBuff = {764011},
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 764033, ['caster'] = 2, ['value'] = {'list(7673,7643)', 2, 1, 1}, ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 764622, ['caster'] = 2, ['ignoreField'] = 1, ['value'] = 'target:getBuff(764622):getValue()+target:BhpMax()*0.1', ['prob'] = 0, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		spineEffect = {['action'] = {['attack'] = 'attack', ['skill2'] = 'skill2', ['hit'] = 'hit', ['run_loop'] = 'run_loop', ['standby_loop'] = 'standby_loop', ['skill1'] = 'skill1', __size = 6}, ['unitRes'] = {'koudai_chaomengmegay/hero_chaomengmegay.skel', 'koudai_chaomengmegay_pifu/hero_chaomengmegay_pifu.skel'}, __size = 2},
		skinEffect = {[767] = 764021, __size = 1}
	},
	[764031] = {
		id = 764031,
		easyEffectFunc = 'setHpPer',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {true},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[764033] = {
		id = 764033,
		easyEffectFunc = 'seal',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999}
	},
	[764041] = {
		id = 764041,
		easyEffectFunc = 'buildScene',
		skillTimePos = 2,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_chaomengmegay/hero_chaomengmegay.skel',
		onceEffectAniName = 'lishijie_chuxian',
		onceEffectPos = 3,
		onceEffectAssignLayer = 3,
		onceEffectOffsetPos = {['y'] = -150, ['x'] = 0, __size = 2},
		onceEffectWait = true,
		textResPath = 'battle/txt/txt_lsjzk.png',
		specialVal = {{1}},
		specialTarget = {{['input'] = 'enemyForce(true)', ['process'] = 'buffDifferExclude(\'group\',{c.fly_oc()})|ignoreBuffGroup(list(c.yinshenplus_oc()))|buffDifferOptional(\'id\',{764041})|random(1)', __size = 2}},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'trigger.reason==2'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 764042, ['caster'] = 2, ['value'] = {'self:flag(200) and 768 or 766', 0, 0, 1.01, 'min(6,2+self:getBuff(764425):getValue())', {['speed'] = 1, ['initMp1'] = 0, ['mp1Max'] = 1, __size = 3}, 0, {['y'] = 200, ['followMark'] = 1008, ['x'] = 500, ['dealGroup'] = 1, __size = 4}, 1, 1}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 764048, ['caster'] = 2, ['value'] = {1, 1, 11}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 764049, ['caster'] = 2, ['value'] = {'list()', 1, 1, 0}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 764054, ['caster'] = 2, ['value'] = {3, 99, 2}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['triggerPoint'] = 28, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 764047, ['caster'] = 2, ['value'] = 0, ['prob'] = '1-1/(2+self:getBuff(764425):getValue())', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 764044, ['caster'] = 1, ['value'] = {'list(1,100,9000)', 1, 0}, ['prob'] = 'target:hasBuff(764047) and 0 or 1', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 764052, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 14, ['lifeRound'] = 1, ['cfgId'] = 764045, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.5', ['prob'] = 'self:flagZ3() and (target:hasBuff(764047) and 1 or 0) or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 764053, ['caster'] = 2, ['value'] = 'countObjByNatureExit(self:force(),11)', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 3, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'trigger.reason==0'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce()', ['process'] = 'buffDiffer(\'id\',{764043})', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 764685, ['caster'] = {['input'] = 'selfForce()', ['process'] = 'buffDiffer(\'id\',{764043})', __size = 2}, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 28, ['nodeId'] = 4, __size = 5}, {['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 12, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 1, ['cfgId'] = 764685, ['caster'] = 2, ['value'] = 0, ['prob'] = 'target2:flag(20006) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 764052, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 14, ['lifeRound'] = 1, ['cfgId'] = 764045, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.5', ['prob'] = 'self:flagZ3() and (target:hasBuff(764047) and 1 or 0) or 0', __size = 6}}}, ['nodeId'] = 5, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		stageArgs = {{['bkCsv'] = 'csv.stage.lsj', __size = 1}},
		buffFlag = {9998},
		skinEffect = {[768] = 764041, [767] = 764041, __size = 2}
	},
	[764042] = {
		id = 764042,
		easyEffectFunc = 'summon',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_lsj.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 764043, ['caster'] = 20, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999, 3007}
	},
	[764043] = {
		id = 764043,
		easyEffectFunc = 'stun',
		group = 80015,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_chaomengmegay/hero_chaomengmegay.skel',
		onceEffectAniName = 'bianshen',
		onceEffectWait = true,
		holderActionType = {['typ'] = 'hide', ['args'] = {['other'] = {['isShow'] = false, __size = 1}, ['lifebar'] = {['isShow'] = false, __size = 1}, __size = 2}, __size = 2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 764685, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999},
		spineEffect = {['action'] = {['attack'] = 'jst_attack', ['skill2'] = 'skill2', ['hit'] = 'jst_hit', ['run_loop'] = 'jst_run_loop', ['standby_loop'] = 'jst_standby_loop', ['skill1'] = 'jst_skill1', __size = 6}, ['unitRes'] = {'koudai_chaomengmegay/hero_chaomengmegay.skel', 'koudai_chaomengmegay_pifu/hero_chaomengmegay_pifu.skel'}, __size = 2},
		skinEffect = {[768] = 764043, [767] = 764043, __size = 2}
	},
	[764044] = {
		id = 764044,
		easyEffectFunc = 'assistAttack',
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		textResPath = 'battle/txt/txt_ewxd.png',
		triggerBehaviors = {{['onSomeFlag'] = {'getExtraRoundId()==764044'}, ['triggerPoint'] = 7, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 764046, ['caster'] = 2, ['value'] = 7000, ['bond'] = 1, ['prob'] = 'self:hasBuff(764047) and 0 or 1', __size = 7}}, {{['holder'] = {['input'] = 'all()', ['process'] = 'random(12)', __size = 2}, ['lifeRound'] = 2, ['cfgId'] = 764050, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 0, __size = 7}}}, ['extraAttackTrigger'] = 3, ['effectFuncs'] = {'castBuff', 'castBuff'}, __size = 6}, {['delSelfWhenTriggered'] = 1, ['onSomeFlag'] = {'getExtraRoundId()==764044'}, ['triggerPoint'] = 8, ['extraAttackTrigger'] = 3, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999}
	},
	[764045] = {
		id = 764045,
		easyEffectFunc = 'buffDamage',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_chaomengmegay/chaomengy_buff.skel',
		onceEffectAniName = 'buffdamage',
		onceEffectWait = true,
		specialVal = {{['processId'] = 30, ['damageType'] = 1, __size = 2}},
		lifeRoundType = 4,
		buffFlag = {7643, 4021},
		skinEffect = {[768] = 764045, [767] = 764045, __size = 2}
	},
	[764046] = {
		id = 764046,
		easyEffectFunc = 'damageReduce',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjc_down.png',
		textResPath = 'battle/txt/txt_shjd.png',
		buffFlag = {9999}
	},
	[764047] = {
		id = 764047,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_sb.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 764045, ['caster'] = 2, ['value'] = 'self:specialDamage()*(65+skillLv(7646) *0.1-0.1)*0.01', ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 764051, ['caster'] = 2, ['value'] = {0, 1, 1}, ['prob'] = 0, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999}
	},
	[764048] = {
		id = 764048,
		easyEffectFunc = 'opGameData',
		overlayLimit = 1,
		specialVal = {'(oldValue==2 or oldValue==3) and (skill:getSkillType2()==0 or skill:getSkillType2()==1 or skill:getSkillType2()==2)'},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999}
	},
	[764049] = {
		id = 764049,
		easyEffectFunc = 'seal',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0},
		buffFlag = {9999}
	},
	[764050] = {
		id = 764050,
		easyEffectFunc = 'filterFlag',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_bq.png',
		specialVal = {{['allForce'] = {9999}, __size = 1}}
	},
	[764051] = {
		id = 764051,
		easyEffectFunc = 'confusion',
		skillTimePos = 2,
		group = 604,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/icon_jssx.png',
		effectResPath = 'koudai_chaomengmegay/chaomengy_buff.skel',
		effectAniName = {'jssx_loop'},
		effectPos = 2,
		effectOffsetPos = {['y'] = -50, ['x'] = 0, __size = 2},
		onceEffectOffsetPos = {['y'] = -80, ['x'] = 0, __size = 2},
		onceEffectWait = true,
		effectOnEnd = {['pos'] = 2, ['aniName'] = 'jssx_xiaoshi', ['res'] = 'koudai_chaomengmegay/chaomengy_buff.skel', __size = 3},
		textResPath = 'battle/txt/txt_jssx.png',
		specialVal = {0, 1, 2},
		lifeRoundType = 4,
		iconShowType = {0, 20}
	},
	[764052] = {
		id = 764052,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_chaomengmegay/hero_chaomengmegay.skel',
		onceEffectAniName = 'lishijie_xiaoshi',
		onceEffectPos = 3,
		onceEffectAssignLayer = 0,
		onceEffectOffsetPos = {['y'] = -20, ['x'] = 0, __size = 2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 4,
		buffFlag = {9999},
		skinEffect = {[768] = 764052, [767] = 764052, __size = 2}
	},
	[764053] = {
		id = 764053,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 4,
		buffFlag = {9999}
	},
	[764054] = {
		id = 764054,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['groupShield'] = 2, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999}
	},
	[764111] = {
		id = 764111,
		easyEffectFunc = 'specialDamage',
		skillTimePos = 2,
		group = 1002,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tg_up.png',
		textResPath = 'battle/txt/txt_tgtg.png'
	},
	[764112] = {
		id = 764112,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		group = 1305,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjc_up.png',
		textResPath = 'battle/txt/txt_ctshts.png',
		specialVal = {{['damageAdd'] = {'setValue(list("damageAdd"),exitInTab(processId,list(c.chuantoudamage_oc())) and list(env:damageAdd()*10000+1000) or  list(env:damageAdd()*10000 ) )'}, __size = 1}}
	},
	[764113] = {
		id = 764113,
		easyEffectFunc = 'speed',
		skillTimePos = 2,
		group = 1081,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_up.png',
		textResPath = 'battle/txt/txt_sdtg.png'
	},
	[764121] = {
		id = 764121,
		easyEffectFunc = 'ignoreDamageSub',
		overlayType = 1,
		overlayLimit = 1,
		lifeRoundType = 4
	},
	[764211] = {
		id = 764211,
		easyEffectFunc = 'suckMp',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		lifeRoundType = 4
	},
	[764231] = {
		id = 764231,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForceEx(list(4006))', ['process'] = 'selfSeat()', __size = 2}, ['lifeRound'] = 2, ['cfgId'] = 764233, ['caster'] = 2, ['value'] = '-self:BspecialDefence()*0.1', ['prob'] = 'self:hasBuffGroup(c.debuff1_debuff2_oc()) and 0 or 1', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 'list(list(c.debuff1_debuff2_oc()),2,self:flagZ2() and 2 or 1)', ['cfgId'] = 764232, ['caster'] = {['input'] = 'selfForceEx(list(4006))', ['process'] = 'selfSeat()', __size = 2}, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[764232] = {
		id = 764232,
		easyEffectFunc = 'transferBuffToOther',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_fc.png',
		specialVal = {3}
	},
	[764233] = {
		id = 764233,
		easyEffectFunc = 'specialDefence',
		group = 10022,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_down.png',
		textResPath = 'battle/txt/txt_tfjd.png'
	},
	[764311] = {
		id = 764311,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForceEx(list(4006))', ['process'] = 'selfSeat()', __size = 2}, ['lifeRound'] = 2, ['cfgId'] = 764312, ['caster'] = 25, ['value'] = 'list(list(c.kongzhi1_kongzhi2_oc()),2,5)', ['prob'] = 1, __size = 6}}, {{['holder'] = 5, ['lifeRound'] = 1, ['cfgId'] = 764313, ['caster'] = 2, ['value'] = '1*max(0,self:getBuff(764647):getValue()/max(1,getForceNum(3-self:force())))*(self:hasBuff(764314) and 1 or 1.1)', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 42, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 764315, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[764312] = {
		id = 764312,
		easyEffectFunc = 'transferBuffToOther',
		overlayLimit = 1,
		specialVal = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 764314, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 4
	},
	[764313] = {
		id = 764313,
		easyEffectFunc = 'buffDamage',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_chaomengmegay/hero_chaomengmegay.skel',
		onceEffectAniName = 'lishijiechongji',
		onceEffectPos = 6,
		onceEffectOffsetPos = {['y'] = 0, ['x'] = -680, __size = 2},
		onceEffectWait = true,
		textResPath = 'battle/txt/txt_lsjcj.png',
		specialVal = {{['processId'] = 30, ['damageType'] = 1, __size = 2}},
		lifeRoundType = 2,
		buffFlag = {7643, 4021},
		skinEffect = {[767] = 764313, __size = 1}
	},
	[764314] = {
		id = 764314,
		overlayLimit = 1,
		lifeRoundType = 4
	},
	[764315] = {
		id = 764315,
		dispelBuff = {764647},
		overlayLimit = 1,
		lifeRoundType = 4
	},
	[764321] = {
		id = 764321,
		skillTimePos = 2,
		group = 15305,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/icon_jsyw.png',
		effectResPath = 'koudai_chaomengmegay/chaomengy_buff.skel',
		effectAniName = {'jsyw_loop'},
		effectPos = 2,
		effectOffsetPos = {['y'] = -80, ['x'] = 0, __size = 2},
		onceEffectOffsetPos = {['y'] = -80, ['x'] = 0, __size = 2},
		onceEffectWait = true,
		effectOnEnd = {['pos'] = 2, ['aniName'] = 'jsyw_xiaoshi', ['res'] = 'koudai_chaomengmegay/chaomengy_buff.skel', __size = 3},
		textResPath = 'battle/txt/txt_jsyw.png',
		triggerBehaviors = {{['onSomeFlag'] = {'not (target:selectCsvTarget():force()==target:force())'}, ['triggerPoint'] = 7, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 1, ['cfgId'] = 764322, ['caster'] = 1, ['value'] = 0, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 5, ['lifeRound'] = 1, ['cfgId'] = 764323, ['caster'] = 1, ['value'] = 0, ['bond'] = 2, ['prob'] = 1, __size = 7}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSkillType'] = 1, __size = 7}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 764324, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {0, 20}
	},
	[764322] = {
		id = 764322,
		easyEffectFunc = 'filterFlag',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_bq.png',
		specialVal = {{['enemyForce'] = {9999}, ['selfForce'] = {'all'}, __size = 2}},
		lifeRoundType = 4
	},
	[764323] = {
		id = 764323,
		easyEffectFunc = 'filterFlag',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_bq.png',
		specialVal = {{['enemyForce'] = {'all'}, ['selfForce'] = {9999}, __size = 2}},
		lifeRoundType = 4
	},
	[764324] = {
		id = 764324,
		skillTimePos = 2,
		overlayType = 2,
		overlayLimit = 10
	},
	[764411] = {
		id = 764411,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForceEx(list(4006))', ['process'] = 'selfSeat()', __size = 2}, ['lifeRound'] = 2, ['cfgId'] = 764412, ['caster'] = {['input'] = 'enemyForce|nodead', ['process'] = 'random(12)', __size = 2}, ['value'] = 'list(list(c.debuff1_debuff2_oc()),2,5)', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[764412] = {
		id = 764412,
		easyEffectFunc = 'copyCasterBuffsToHolder',
		overlayType = 8,
		overlayLimit = 6,
		specialVal = {2}
	},
	[764420] = {
		id = 764420,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_bq.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 14, ['lifeRound'] = 2, ['cfgId'] = 764421, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 6
	},
	[764421] = {
		id = 764421,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_rh.png',
		triggerPriority = 9,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'less(self:getBuffOverlayCount(764423),1) and (not target:hasBuff(764041,764044))'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 764422, ['caster'] = 2, ['value'] = {0, 0, 1}, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 24, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {9998}
	},
	[764422] = {
		id = 764422,
		easyEffectFunc = 'cancelToAttack',
		overlayLimit = 1,
		isShow = false,
		textResPath = 'battle/txt/txt_xdwx.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 764423, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 764424, ['caster'] = 2, ['value'] = 0, ['prob'] = 'moreE(self:getBuffOverlayCount(764423),2) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 5, ['cfgId'] = 764425, ['caster'] = 2, ['value'] = 'countObjByNatureExit(self:force(),11)', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 42, ['nodeId'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 764041, ['caster'] = 2, ['value'] = {2, 'list(1,1,1)', 'list(1,1,list(1,0,0),7645)', 'list(assistAttack,summon)', 'list(3007)', 1}, ['prob'] = 1, __size = 6}}}, ['delSelfWhenTriggered'] = 1, ['triggerTimes'] = {1, 1}, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[764423] = {
		id = 764423,
		overlayType = 2,
		overlayLimit = 2,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_qyzs.png',
		noDelWhenFakeDeath = 1
	},
	[764424] = {
		id = 764424,
		dispelBuff = {764420, 764423},
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[764425] = {
		id = 764425,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[764431] = {
		id = 764431,
		easyEffectFunc = 'specialRecord',
		skillTimePos = 2,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_byzs.png',
		specialVal = {1, {['input'] = 'enemyForce|nodead', ['process'] = 'random(12)', __size = 2}, 1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 19, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 764436, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 764432, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 764433, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(764432) and 0 or 1', __size = 6}}}, ['nodeId'] = 3, __size = 4}, {['triggerPoint'] = 32, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 6
	},
	[764432] = {
		id = 764432,
		skillTimePos = 2,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/icon_zhdjs2.png',
		lifeRoundType = 6,
		iconShowType = {1, 15}
	},
	[764433] = {
		id = 764433,
		skillTimePos = 2,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/icon_zhdjs1.png',
		lifeRoundType = 6,
		iconShowType = {1, 15}
	},
	[764434] = {
		id = 764434,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_chaomengmegay/hero_chaomengmegay.skel',
		onceEffectAniName = 'jingshenjuxiang',
		onceEffectPos = 3,
		onceEffectAssignLayer = 0,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 4,
		skinEffect = {[767] = 764434, __size = 1}
	},
	[764435] = {
		id = 764435,
		easyEffectFunc = 'assistAttack',
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_jsjx.png',
		specialVal = {1},
		lifeRoundType = 4
	},
	[764436] = {
		id = 764436,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['onSomeFlag'] = {'(not self:isBackHeros()) and (not self:hasBuff(764053))'}, ['triggerPoint'] = 42, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 764435, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1, 'list(self:flag(200) and 7677 or 7647)'}, ['prob'] = 1, __size = 6}}}, ['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['onSomeFlag'] = {'(not self:isBackHeros()) and (not self:hasBuff(764053))'}, ['triggerPoint'] = 3, ['nodeId'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 764435, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1, 'list(self:flag(200) and 7677 or 7647)'}, ['prob'] = 1, __size = 6}}}, ['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[764437] = {
		id = 764437,
		easyEffectFunc = 'ignoreSpecBuff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 4
	},
	[764438] = {
		id = 764438,
		easyEffectFunc = 'ignorePriorityBuff',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {'replaceTarget'},
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 4
	},
	[764441] = {
		id = 764441,
		easyEffectFunc = 'fieldBuff',
		skillTimePos = 2,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_chaomengmegay/hero_chaomengmegay.skel',
		onceEffectAniName = 'lishijie_chuxian',
		onceEffectPos = 3,
		onceEffectAssignLayer = 3,
		onceEffectOffsetPos = {['y'] = -150, ['x'] = 0, __size = 2},
		onceEffectWait = true,
		textResPath = 'battle/txt/txt_lsjzk.png',
		specialVal = {413},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 14, ['lifeRound'] = 999, ['cfgId'] = 764442, ['caster'] = 2, ['value'] = 1000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 11, ['lifeRound'] = 999, ['cfgId'] = 764443, ['caster'] = 2, ['value'] = 1000, ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(11)))  and 1 or 0', __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 764444, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:flagZ3() and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 764442, ['caster'] = 2, ['value'] = 1000, ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and 0 or 1', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 764443, ['caster'] = 2, ['value'] = 1000, ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and ((target2:natureIntersection(list(11)))  and 1 or 0) or 0', __size = 7}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		gateLimit = {{['limit'] = 2, ['type'] = 1, __size = 2}},
		stageArgs = {{['bkCsv'] = 'csv.stage.lsj', __size = 1}},
		skinEffect = {[768] = 764441, [767] = 764441, __size = 2}
	},
	[764442] = {
		id = 764442,
		easyEffectFunc = 'natureDamageDeepen',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjc_down.png',
		textResPath = 'battle/txt/txt_ys.png',
		specialVal = {11}
	},
	[764443] = {
		id = 764443,
		easyEffectFunc = 'finalDamageSub',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjc_up.png',
		textResPath = 'battle/txt/txt_shjmtg.png',
		noDelWhenFakeDeath = 1
	},
	[764444] = {
		id = 764444,
		overlayType = 2,
		overlayLimit = 3,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_qyzs.png',
		noDelWhenFakeDeath = 1
	},
	[764611] = {
		id = 764611,
		easyEffectFunc = 'fieldBuff',
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_rh.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 5, ['lifeRound'] = 999, ['cfgId'] = 764612, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(11)))  and 1 or 0', __size = 7}}, {{['holder'] = 5, ['lifeRound'] = 999, ['cfgId'] = 764615, ['caster'] = 2, ['value'] = {1, 99, 1}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 5, ['lifeRound'] = 999, ['cfgId'] = 764616, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(11)))  and (target2:id()==self:id() and 0 or 1) or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 764612, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and ((target2:natureIntersection(list(11)))  and 1 or 0) or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 764615, ['caster'] = 2, ['value'] = {1, 99, 1}, ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and 1 or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 764616, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(11)))  and (trigger.obj.force == self:force() and (target2:id()==self:id() and 0 or 1) or 0) or 0', __size = 7}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[764612] = {
		id = 764612,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjc_up.png',
		textResPath = 'battle/txt/txt_sgtg.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 764613, ['caster'] = 2, ['value'] = 'target2:Bdamage()*countObjByNatureExit(self:force(),11)*0.015', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 764614, ['caster'] = 2, ['value'] = 'target2:BspecialDamage()*countObjByNatureExit(self:force(),11)*0.015', ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[764613] = {
		id = 764613,
		easyEffectFunc = 'damage',
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[764614] = {
		id = 764614,
		easyEffectFunc = 'specialDamage',
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[764615] = {
		id = 764615,
		easyEffectFunc = 'alterDmgRecordVal',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['damageAdd'] = {'setValue(list("damageAdd"),(exitInTab(processId,list(c.chuantoudamage_oc())) or attacker:curSkill():skillFlag(10001) ==true) and list(env:damageAdd()*10000+(5+attacker:skillLv(7646) *0.05-0.05)*100) or  list(env:damageAdd()*10000 ) )'}, __size = 1}},
		noDelWhenFakeDeath = 1
	},
	[764616] = {
		id = 764616,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {'trigger.beAddBuff:hasFlag(1012)'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_yinshenplus_oc()})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 764617, ['caster'] = 2, ['value'] = 'self:specialDamage()*(70+skillLv(7646) *0.1-0.1)*0.01', ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 764618, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 29, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[764617] = {
		id = 764617,
		easyEffectFunc = 'buffDamage',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_chaomengmegay/chaomengy_buff.skel',
		onceEffectAniName = 'buffdamage',
		onceEffectWait = true,
		specialVal = {{['processId'] = 30, ['damageType'] = 1, __size = 2}},
		lifeRoundType = 4,
		buffFlag = {7643, 4021}
	},
	[764618] = {
		id = 764618,
		overlayType = 2,
		overlayLimit = 999,
		noDelWhenFakeDeath = 1
	},
	[764621] = {
		id = 764621,
		easyEffectFunc = 'fieldBuff',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 764622, ['caster'] = 2, ['ignoreField'] = 1, ['value'] = 'target:getBuff(764622):getValue()+target:BhpMax()*0.1', ['prob'] = 0, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 764623, ['caster'] = 2, ['ignoreField'] = 1, ['value'] = 'target:getBuff(764623):getValue()+target:BhpMax()*0.1', ['prob'] = 0, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 14, ['lifeRound'] = 999, ['cfgId'] = 764624, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 764624, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = '((not (trigger.obj.force == self:force()))  and (not target2:flag(1101)) ) and 1 or 0', __size = 7}}}, ['nodeId'] = 3, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 45, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 764021, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 4, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[764622] = {
		id = 764622,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[764623] = {
		id = 764623,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[764624] = {
		id = 764624,
		overlayType = 6,
		overlayLimit = 6,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_rh.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'self:checkIsSkillTarget() and (not self:hasBuff(764626)) and less(self:getBuffOverlayCount(764627),2)'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 764625, ['caster'] = 2, ['value'] = {0, 0, 1}, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 24, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9998}
	},
	[764625] = {
		id = 764625,
		easyEffectFunc = 'cancelToAttack',
		overlayLimit = 1,
		isShow = false,
		textResPath = 'battle/txt/txt_xdwx.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 5, ['cfgId'] = 764626, ['caster'] = 2, ['ignoreField'] = 1, ['value'] = 0, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 764627, ['caster'] = 2, ['ignoreField'] = 1, ['value'] = 0, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 5, ['cfgId'] = 764425, ['caster'] = 2, ['ignoreField'] = 1, ['value'] = 'countObjByNatureExit(self:force(),11)', ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 42, ['nodeId'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 764041, ['caster'] = 2, ['value'] = {2, 'list(1,1,1)', 'list(1,1,list(1,0,0),7645)', 'list(assistAttack,summon)', 'list(3007)', 1}, ['prob'] = 1, __size = 6}}}, ['delSelfWhenTriggered'] = 1, ['triggerTimes'] = {1, 1}, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9998}
	},
	[764626] = {
		id = 764626,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_xglq.png',
		lifeRoundType = 6,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[764627] = {
		id = 764627,
		overlayType = 2,
		overlayLimit = 5,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_qyzs.png',
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[764631] = {
		id = 764631,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'lessE(getNowRound(),5) and ( not self:hasBuff(764635) ) and (getExtraRoundMode()~=7 and getExtraRoundMode()~=8 and getExtraRoundMode()~=9)'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce | nodead', ['process'] = 'attrWitOutFilter("BspecialDamage","max",1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 764634, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 764632, ['caster'] = 2, ['value'] = 1, ['prob'] = 'self:hasBuff(764634) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 764635, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 6, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[764632] = {
		id = 764632,
		easyEffectFunc = 'atOnceBattleRound',
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 764633, ['caster'] = 2, ['value'] = {-1, 764632}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2
	},
	[764633] = {
		id = 764633,
		easyEffectFunc = 'changeSpeedPriority',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {1},
		lifeRoundType = 2
	},
	[764634] = {
		id = 764634,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_qyzs.png',
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[764635] = {
		id = 764635,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_qyzs.png',
		lifeRoundType = 6,
		noDelWhenFakeDeath = 1
	},
	[764641] = {
		id = 764641,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 764642, ['caster'] = 2, ['value'] = {765, 99, 0, 1.01, 1, {['speed'] = 1, ['immuneControl'] = 0, ['initMp1'] = 0, ['mp1Max'] = 1, __size = 4}, 1, {['y'] = 1300, ['followMark'] = 4006, ['x'] = 500, ['dealGroup'] = 1, __size = 4}, 1, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'less(self:getBuff(764647):getValue(),self:BspecialDamage()*2.4)'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 764646, ['caster'] = 2, ['value'] = 'min(self:BspecialDamage()*2.4-self:getBuff(764647):getValue(),self:BspecialDamage()*1.2)', ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 3, ['nodeId'] = 2, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'less(self:getBuff(764647):getValue(),self:BspecialDamage()*2.4)'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['value'] = 'min(self:BspecialDamage()*2.4,self:getBuff(764647):getValue()+(self:BspecialDamage()*1.2-self:assimilateDamageHp(764646)))', ['cfgId'] = 764647, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 5, ['nodeId'] = 3, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 764650, ['caster'] = 2, ['value'] = 1500, ['prob'] = '(30+skillLv(7646)*0.2-0.2)*0', __size = 6}}}, ['nodeId'] = 4, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[764642] = {
		id = 764642,
		easyEffectFunc = 'summon',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 764643, ['caster'] = 20, ['value'] = {1}, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 764644, ['caster'] = 2, ['value'] = {'list(c.kongzhi1_kongzhi2_oc())', 0}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'getNowRound()%2==1'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 764644, ['caster'] = 2, ['value'] = {'list(c.kongzhi1_kongzhi2_oc())', 0}, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 3, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[764643] = {
		id = 764643,
		easyEffectFunc = 'immuneDamage',
		overlayType = 1,
		overlayLimit = 1,
		holderActionType = {['typ'] = 'hide', ['args'] = {['sprite'] = {['isShow'] = false, __size = 1}, ['other'] = {['isShow'] = false, __size = 1}, ['lifebar'] = {['isShow'] = true, __size = 1}, __size = 3}, __size = 2},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[764644] = {
		id = 764644,
		easyEffectFunc = 'reboundBuff',
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_rh.png',
		specialVal = {{['input'] = 'selfForceEx(list(4006))', ['process'] = 'selfSeat()', __size = 2}, 999},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 764648, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 2, ['value'] = 0, ['cfgId'] = 764645, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 764649, ['caster'] = 2, ['value'] = 0, ['prob'] = 'moreE(self:getBuffOverlayCount(764645),2) and 1 or 10', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[764645] = {
		id = 764645,
		overlayType = 2,
		overlayLimit = 2,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_xglq.png',
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1
	},
	[764646] = {
		id = 764646,
		easyEffectFunc = 'assimilateDamage',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'less(self:getBuff(764647):getValue(),self:BspecialDamage()*2.4)'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['value'] = 'min(self:BspecialDamage()*2.4,self:getBuff(764647):getValue()+(self:BspecialDamage()*1.2-self:assimilateDamageHp(764646)))', ['cfgId'] = 764647, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 4, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[764647] = {
		id = 764647,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[764648] = {
		id = 764648,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_fc.png',
		lifeRoundType = 4
	},
	[764649] = {
		id = 764649,
		dispelBuff = {764644},
		overlayType = 1,
		overlayLimit = 1,
		lifeRoundType = 4
	},
	[764650] = {
		id = 764650,
		easyEffectFunc = 'ignoreDamageSub',
		overlayType = 1,
		overlayLimit = 1
	},
	[764681] = {
		id = 764681,
		easyEffectFunc = 'lockHp',
		overlayLimit = 1,
		specialVal = {'self:hasBuff(764021)'},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 5, ['value'] = {1}, ['cfgId'] = 764682, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		gateLimit = {{['limit'] = 1, ['type'] = 1, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffActionEffect = {['triggerEffect'] = {['onceEffectAniName'] = 'effect', ['textResPath'] = 'battle/txt/txt_mysw.png', ['onceEffectResPath'] = 'buff/miansi/miansi.skel', __size = 3}, __size = 1},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[764682] = {
		id = 764682,
		easyEffectFunc = 'immuneDamage',
		overlayLimit = 1,
		triggerPriority = 7,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 32, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 0, ['cfgId'] = 764683, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 5}, {['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 4, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 0, ['cfgId'] = 764683, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {1041}
	},
	[764683] = {
		id = 764683,
		dispelBuff = {764681},
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 'self:flagZ4() and 3 or 2', ['value'] = 'max(0.3,target2:getBuff(764622):getValue()/target2:hpMax())', ['cfgId'] = 764684, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 8, ['value'] = 1, ['cfgId'] = 764011, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[764684] = {
		id = 764684,
		easyEffectFunc = 'setHpPer',
		overlayLimit = 1,
		specialVal = {true},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 19, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 764685, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 764686, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:flagZ4() and (self:hasBuffGroup(c.kongzhis_oc()) and 0 or 1) or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2
	},
	[764685] = {
		id = 764685,
		easyEffectFunc = 'kill',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {true, true},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999}
	},
	[764686] = {
		id = 764686,
		easyEffectFunc = 'atOnceBattleRound',
		overlayLimit = 1
	},
	[764691] = {
		id = 764691,
		easyEffectFunc = 'finalDamageAdd',
		overlayType = 8,
		overlayLimit = 8,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[764692] = {
		id = 764692,
		easyEffectFunc = 'finalDamageSub',
		overlayType = 8,
		overlayLimit = 8,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[764693] = {
		id = 764693,
		easyEffectFunc = 'alterDmgRecordVal',
		overlayType = 8,
		overlayLimit = 8,
		specialVal = {{['finalRate'] = {'setValue(list("finalDamageSub"),( (arg.from==1) and list(env:finalDamageSub()*10000+5000) or list(env:finalDamageSub()*10000)) )'}, __size = 1}},
		noDelWhenFakeDeath = 1
	},
	[1961001] = {
		id = 1961001,
		name = '盖欧卡',
		easyEffectFunc = 'fieldBuff',
		overlayLimit = 1,
		specialVal = {11},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 5, ['lifeRound'] = 999, ['cfgId'] = 1961002, ['caster'] = 2, ['value'] = 1000, ['bond'] = 1, ['prob'] = 'self:hasBuff(1961001) and 1 or 0', __size = 7}}, {{['holder'] = 5, ['lifeRound'] = 999, ['cfgId'] = 1961003, ['caster'] = 2, ['value'] = {2, 99, 1}, ['bond'] = 1, ['prob'] = 'self:hasBuff(1961001) and 1 or 0', __size = 7}}, {{['holder'] = 5, ['lifeRound'] = 999, ['cfgId'] = 1961004, ['caster'] = 2, ['value'] = 1000, ['bond'] = 1, ['prob'] = '( target2:natureIntersection(list(3))) and (self:hasBuff(1961001) and 1 or 0) or 0', __size = 7}}, {{['holder'] = 5, ['lifeRound'] = 999, ['cfgId'] = 1961005, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = '( target2:natureIntersection(list(3))) and (self:hasBuff(1961001) and 1 or 0) or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'trigger.obj.force == self:force()'}, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 1961002, ['caster'] = 2, ['value'] = 1000, ['bond'] = 1, ['prob'] = 'self:hasBuff(1961001) and 1 or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 1961003, ['caster'] = 2, ['value'] = {2, 99, 1}, ['bond'] = 1, ['prob'] = 'self:hasBuff(1961001) and 1 or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 1961004, ['caster'] = 2, ['value'] = 1000, ['bond'] = 1, ['prob'] = '( target2:natureIntersection(list(3))) and (self:hasBuff(1961001) and 1 or 0) or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 1961005, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = '( target2:natureIntersection(list(3))) and (self:hasBuff(1961001) and 1 or 0) or 0', __size = 7}}}, ['triggerPoint'] = 28, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5011},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1961002] = {
		id = 1961002,
		easyEffectFunc = 'waterDamageAdd',
		group = 1000,
		groupPower = 102,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_shjc_up.png',
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5011},
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1961003] = {
		id = 1961003,
		easyEffectFunc = 'alterDmgRecordVal',
		overlayLimit = 1,
		specialVal = {{['finalRate'] = {'setValue(list("finalDamageAdd"),(exitInTab(processId,list(3003,3651334)) or attacker:curSkill():skillFlag(203,203,211,212) ==true) and list(env:finalDamageAdd()*10000+1000) or  list(env:finalDamageAdd()*10000 ) )'}, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5011},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1961004] = {
		id = 1961004,
		easyEffectFunc = 'strikeResistance',
		groupPower = 102,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjkx_up.png',
		textResPath = 'battle/txt/txt_bjkxtg.png',
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5011},
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1961005] = {
		id = 1961005,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1961006, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5011},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1961006] = {
		id = 1961006,
		easyEffectFunc = 'qusan',
		group = 61004,
		dispelType = {3, 0, 1},
		overlayLimit = 1,
		specialTarget = {{['input'] = 'selfForce()|nodead', ['process'] = 'buffDiffer(\'groupFilter\',{{beDispel=10},{c.groupdebuffs1_oc()}})|random(1)', __size = 2}},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 4,
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5011},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1961121] = {
		id = 1961121,
		easyEffectFunc = 'strikeResistance',
		skillTimePos = 2,
		groupPower = 102,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjkx_up.png',
		textResPath = 'battle/txt/txt_bjkxtg.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1961122] = {
		id = 1961122,
		easyEffectFunc = 'immuneControlVal',
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_kzmy.png',
		specialVal = {70002},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1961123] = {
		id = 1961123,
		easyEffectFunc = 'specialDamage',
		skillTimePos = 2,
		group = 10002,
		groupPower = 102,
		overlayType = 8,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tg_down.png',
		textResPath = 'battle/txt/txt_tgjd.png'
	},
	[1961124] = {
		id = 1961124,
		easyEffectFunc = 'specialDefence',
		group = 10022,
		groupPower = 102,
		overlayType = 8,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_down.png',
		textResPath = 'battle/txt/txt_tfjd.png'
	},
	[1961141] = {
		id = 1961141,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1961142, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1961143, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1961148, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[1961142] = {
		id = 1961142,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 60027,
		dispelType = {3, 2},
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {11},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1961144, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962936, ['caster'] = 2, ['value'] = 'target2:hp()*(0.02+fromSkillLevel*0.001-0.001)', ['prob'] = 'self:hasBuff(1961144) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['delSelfWhenTriggered'] = 2, ['triggerPoint'] = 1, ['nodeId'] = 0, __size = 3}}
	},
	[1961143] = {
		id = 1961143,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 60028,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {{['input'] = 'selfForce()|nodead', ['process'] = 'exclude(list(csvSelf:id()))|attrDiffer("natureType", {3})', __size = 2}},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 1961145, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'attrDiffer("natureType", {3})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962936, ['caster'] = 2, ['value'] = 'target2:hp()*(0.02+fromSkillLevel*0.001-0.001)*2', ['prob'] = 'self:hasBuff(1961145) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['delSelfWhenTriggered'] = 2, ['triggerPoint'] = 1, ['nodeId'] = 0, __size = 3}},
		noDelWhenFakeDeath = 1
	},
	[1961144] = {
		id = 1961144,
		overlayType = 1,
		overlayLimit = 1,
		lifeRoundType = 2,
		iconShowType = {1, 10}
	},
	[1961145] = {
		id = 1961145,
		overlayType = 1,
		overlayLimit = 1,
		lifeRoundType = 2,
		iconShowType = {1, 10}
	},
	[1961146] = {
		id = 1961146,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962936, ['caster'] = 2, ['value'] = 'target2:hp()*(0.02+fromSkillLevel*0.001-0.001)', ['prob'] = 'self:hasBuff(1961144) and 0 or 0', __size = 6}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'attrDiffer("natureType", {3})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962936, ['caster'] = 2, ['value'] = 'target2:hp()*(0.02+fromSkillLevel*0.001-0.001)*2', ['prob'] = 'self:hasBuff(1961145) and 0 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		lifeRoundType = 2,
		iconShowType = {1, 10}
	},
	[1961147] = {
		id = 1961147,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao2',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		lifeRoundType = 2,
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[1961148] = {
		id = 1961148,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 60028,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1961151] = {
		id = 1961151,
		overlayLimit = 1,
		triggerBehaviors = {{['onSomeFlag'] = {'trigger.strike'}, ['triggerPoint'] = 40, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 1962949, ['caster'] = 2, ['value'] = 5000, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}},
		noDelWhenFakeDeath = 1
	},
	[1961152] = {
		id = 1961152,
		easyEffectFunc = 'strikeResistance',
		skillTimePos = 2,
		groupPower = 102,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjkx_up.png',
		textResPath = 'battle/txt/txt_bjkxtg.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1961161] = {
		id = 1961161,
		skillTimePos = 2,
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 1962972, ['caster'] = 2, ['value'] = {1966, 99, 0, 1, 1, {['hpMax'] = 1, ['rebound'] = 0, __size = 2}, 1, {['y'] = 0, ['followMark'] = 2004, ['x'] = 150, ['dealGroup'] = 4, __size = 4}, 1, 0}, ['bond'] = 1, ['prob'] = '(self:cardID()==1962 and (not self:flagZ4()))and 1 or 0', __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 1962972, ['caster'] = 2, ['value'] = {1967, 99, 0, 1, 1, {['hpMax'] = 1, ['rebound'] = 0, __size = 2}, 1, {['y'] = 0, ['followMark'] = 2004, ['x'] = 150, ['dealGroup'] = 4, __size = 4}, 1, 0}, ['bond'] = 1, ['prob'] = '(self:cardID()==1962 and self:flagZ4()) and 1 or 0', __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 1962976, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 3, ['cfgId'] = 1962982, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1961162] = {
		id = 1961162,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0, 0},
		specialTarget = {2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 1962974, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962975, ['caster'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['value'] = {0.5, 2, 17, 2}, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962973, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1}, ['prob'] = 1, __size = 6}}, {{['holder'] = 20, ['lifeRound'] = 99, ['value'] = 1, ['cfgId'] = 1962978, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1961163] = {
		id = 1961163,
		easyEffectFunc = 'inviteAttack',
		skillTimePos = 2,
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{0, 1, 2}},
		specialTarget = {{['input'] = 'allEx(list(2004))', ['process'] = 'random(6)', __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1
	},
	[1961164] = {
		id = 1961164,
		group = 70006,
		overlayType = 1,
		overlayLimit = 1,
		buffFlag = {9999}
	},
	[1961165] = {
		id = 1961165,
		easyEffectFunc = 'damageAllocate',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[1961166] = {
		id = 1961166,
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 19, ['funcArgs'] = {{{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1961170, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 3,
		noDelWhenFakeDeath = 1
	},
	[1961167] = {
		id = 1961167,
		easyEffectFunc = 'kill',
		skillTimePos = 2,
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {true, true},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1961168] = {
		id = 1961168,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {'moreE(trigger.delta,1)'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1961169, ['caster'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['value'] = 'self2:mp1()*0.5', ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962980, ['caster'] = 2, ['value'] = '-target2:mp1()*0.5', ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 34, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[1961169] = {
		id = 1961169,
		easyEffectFunc = 'addMp1',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[1961170] = {
		id = 1961170,
		easyEffectFunc = 'addMp1',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[1961171] = {
		id = 1961171,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		group = 10141,
		overlayType = 8,
		overlayLimit = 3,
		iconResPath = 'battle/buff_icon/logo_lx.png',
		effectResPath = 'buff/liuxue/liuxue.skel',
		effectAniName = {'liuxue_loop'},
		textResPath = 'battle/txt/txt_lx.png',
		specialVal = {{['processId'] = 5, ['damageType'] = 2, __size = 2}},
		triggerBehaviors = {{['triggerPoint'] = 5, ['nodeId'] = 0, __size = 2}}
	},
	[1961181] = {
		id = 1961181,
		easyEffectFunc = 'inviteAttack',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_qyzs.png',
		specialVal = {{1}},
		specialTarget = {{['input'] = 'selfForceEx(list(c.shuixigensui_oc()))', ['process'] = 'random(1)', __size = 2}},
		lifeTimeEnd = 0
	},
	[1961182] = {
		id = 1961182,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'lessThan(target:hp()/target:hpMax(),0.4)'}, ['triggerPoint'] = 18, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 1962971, ['caster'] = 2, __size = 5}}}, ['triggerTimes'] = {1, 1}, ['effectFuncs'] = {'castBuff'}, __size = 6}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1961201] = {
		id = 1961201,
		easyEffectFunc = 'strikeResistance',
		skillTimePos = 2,
		group = 1026,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjkx_up.png',
		textResPath = 'battle/txt/txt_bjkxtg.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1961211] = {
		id = 1961211,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 60027,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {11},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'attrDifferExclude("natureType", {3})', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962927, ['caster'] = 2, ['value'] = '-target:speed()*0.06', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['delSelfWhenTriggered'] = 2, ['triggerPoint'] = 1, ['nodeId'] = 0, __size = 3}}
	},
	[1961611] = {
		id = 1961611,
		easyEffectFunc = 'aura',
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {{['input'] = 'all', ['process'] = 'random(12)', __size = 2}},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 1961121, ['caster'] = 2, ['value'] = '(1500+skillLevel*15-15)*(target2:id()==self:id() and 1 or 0.5)', ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and (( target2:natureIntersection(list(3))) and 1 or 0) or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 1961122, ['caster'] = 2, ['value'] = '(1000+skillLevel*10-10)*(target2:id()==self:id() and 1 or 0.5)', ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and (( target2:natureIntersection(list(3))) and 1 or 0) or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 1961123, ['caster'] = 2, ['value'] = '-target2:specialDamage()*0.03*countObjByNatureExit(self:force(),3)', ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and 0 or 1', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 1961124, ['caster'] = 2, ['value'] = '-target2:specialDefence()*0.03*countObjByNatureExit(self:force(),3)', ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and 0 or 1', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1961621] = {
		id = 1961621,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1961622, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'exclude(list(csvSelf:id()))|buffDiffer(\'group\',{c.groupdebuffs2_oc()})|attrDiffer("natureType", {3})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1961622, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1961622] = {
		id = 1961622,
		easyEffectFunc = 'jinghua2',
		group = 60027,
		dispelType = {3, 2},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 4
	},
	[1961623] = {
		id = 1961623,
		easyEffectFunc = 'gjjh1',
		group = 60028,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 4
	},
	[1961631] = {
		id = 1961631,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'target:getDamageStateToMe(\'strike\')'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1961632, ['caster'] = 2, ['value'] = 5000, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 10, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1961632] = {
		id = 1961632,
		easyEffectFunc = 'strikeResistance',
		skillTimePos = 2,
		groupPower = 102,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjkx_up.png',
		textResPath = 'battle/txt/txt_bjkxtg.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962001] = {
		id = 1962001,
		name = '原始盖欧卡',
		easyEffectFunc = 'fieldBuff',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_ym.png',
		specialVal = {21},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 1962924, ['caster'] = 2, ['value'] = 1500, ['bond'] = 1, ['prob'] = '(target2:force()==self:force()) and (self:hasBuff(1962001) and 1 or 0) or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 1962918, ['caster'] = 2, ['value'] = 1500, ['bond'] = 1, ['prob'] = '(target2:force()==self:force() and ( target2:natureIntersection(list(3)))) and (self:hasBuff(1962001) and 1 or 0) or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 1962925, ['caster'] = 2, ['value'] = {2, 99, 1}, ['bond'] = 1, ['prob'] = '(target2:force()==self:force() and ( target2:natureIntersection(list(3)))) and (self:hasBuff(1962001) and 1 or 0) or 0', __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962922, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962926, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = '(self:hasBuff(1962001) and 1 or 0)', __size = 7}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'attrDifferExclude("natureType", {3})', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962927, ['caster'] = 2, ['value'] = '-target2:speed()*0.06', ['bond'] = 1, ['prob'] = '(self:hasBuff(1962001) and 1 or 0)', __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962928, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = '(self:hasBuff(1962001) and 1 or 0)', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5021},
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962002] = {
		id = 1962002,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bq.png',
		buffFlag = {5000}
	},
	[1962003] = {
		id = 1962003,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_rh.png',
		buffFlag = {5000}
	},
	[1962101] = {
		id = 1962101,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'battleFlagDiffer(\'battleFlag\', {1962,7031})|attr("speed", \'min\',1)', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 1962102, ['caster'] = 2, ['value'] = 1, ['prob'] = '(moreE((countObjByFlag(self:force(),1982)+countObjByFlag(self:force(),1972)), 1) or moreE(countObjByNatureExit(self:force(),3),2)) and moreE(countObjByBuff(self:force(),{7031710}),3) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962102] = {
		id = 1962102,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962111] = {
		id = 1962111,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962112] = {
		id = 1962112,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|random(3)', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 1962115, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962453, ['caster'] = 2, ['value'] = '1000*((getGateType() == 10 or getGateType() == 14 or getForceNum(self:force()) == 1) and 0.8 or 0.4)', ['prob'] = 'moreE(getNowRound(),11) and 0 or 1', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962454, ['caster'] = 2, ['value'] = '2000*((getGateType() == 10 or getGateType() == 14 or getForceNum(self:force()) == 1) and 0.8 or 0.4)', ['prob'] = 'moreE(getNowRound(),11) and 0 or 1', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962455, ['caster'] = 2, ['value'] = '2000*((getGateType() == 10 or getGateType() == 14 or getForceNum(self:force()) == 1) and 0.8 or 0.4)', ['prob'] = 'moreE(getNowRound(),11) and 0 or 1', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962457, ['caster'] = 2, ['value'] = 800, ['prob'] = 'moreE(getNowRound(),11) and 0 or 1', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962282, ['caster'] = 2, ['value'] = {2, 99, 1}, ['prob'] = 'moreE(getNowRound(),11) and 0 or 1', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962113] = {
		id = 1962113,
		easyEffectFunc = 'speed',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_up.png',
		textResPath = 'battle/txt/txt_sdtg.png',
		iconShowType = {1, 10}
	},
	[1962114] = {
		id = 1962114,
		easyEffectFunc = 'speed',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_down.png',
		textResPath = 'battle/txt/txt_sdjd.png',
		iconShowType = {1, 10}
	},
	[1962115] = {
		id = 1962115,
		easyEffectFunc = 'swapSpeed',
		overlayLimit = 1,
		onceEffectResPath = 'buff/gaioukamega_buff/gaioukamega_buff.skel',
		onceEffectAniName = 'luansu',
		onceEffectPos = 1,
		textResPath = 'battle/txt/txt_ls3.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[1962116] = {
		id = 1962116,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 32, ['funcArgs'] = {{{['holder'] = {['input'] = 'allEx(list(c.shuixigensui_oc()))', ['process'] = 'random(99)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962117, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		iconShowType = {1, 10}
	},
	[1962117] = {
		id = 1962117,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962456, ['caster'] = 2, ['value'] = 800, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[1962121] = {
		id = 1962121,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 99, ['value'] = 'target2:speed()*0.1*((target2:natureIntersection(list(3))) and 2 or 1)', ['cfgId'] = 1962122, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = '(moreE(countObjByNatureExit(self:force(),3),2) and 99 or (2+(self:flagZ4() and 1 or 0)))', ['cfgId'] = 1962127, ['caster'] = 2, ['value'] = 0, ['prob'] = 0, __size = 6}}, {{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 1962144, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962122] = {
		id = 1962122,
		easyEffectFunc = 'speed',
		group = 1081,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_up.png',
		textResPath = 'battle/txt/txt_sdtg.png',
		noDelWhenFakeDeath = 1
	},
	[1962123] = {
		id = 1962123,
		easyEffectFunc = 'immuneControlVal',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_kzmy.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962124] = {
		id = 1962124,
		easyEffectFunc = 'immuneControlVal',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_mkltg.png',
		specialVal = {70022},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962125] = {
		id = 1962125,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'not trigger.strike'}, ['triggerPoint'] = 40, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962126, ['caster'] = 2, ['value'] = 2000, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962142, ['caster'] = 2, ['value'] = {2, 100, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962126] = {
		id = 1962126,
		easyEffectFunc = 'finalDamageSub',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962127] = {
		id = 1962127,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_ym.png',
		textResPath = 'battle/txt/txt_ym.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'(not self:hasBuff(1962102))'}, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 1962123, ['caster'] = 2, ['value'] = 3500, ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(3))) and 1 or 0', __size = 7}}, {{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 1962124, ['caster'] = 2, ['value'] = 3500, ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(3))) and 1 or 0', __size = 7}}, {{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 1962125, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(3))) and 1 or 0', __size = 7}}, {{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 1962137, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(3))) and 1 or 0', __size = 7}}, {{['holder'] = 14, ['lifeRound'] = 99, ['cfgId'] = 1962141, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962128, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 1962839, ['caster'] = 2, ['value'] = 0, ['prob'] = '((target2:natureIntersection(list(3))) and self:flagZ3()) and 1 or 0', __size = 6}}}, ['triggerPoint'] = 38, ['nodeId'] = 1, __size = 5}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962128] = {
		id = 1962128,
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'buff/gaioukamega_buff/gaioukamega_changjing.skel',
		effectPos = 3,
		effectAssignLayer = 3,
		effectOffsetPos = {['y'] = 200, ['x'] = 450, __size = 2},
		onceEffectResPath = 'buff/gaioukamega_buff/gaioukamega_changjing.skel',
		onceEffectAniName = 'effect_danru',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962129, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962129] = {
		id = 1962129,
		overlayType = 1,
		overlayLimit = 1,
		effectPos = 3,
		effectAssignLayer = 3,
		effectOffsetPos = {['y'] = 200, ['x'] = 450, __size = 2},
		onceEffectResPath = 'buff/gaioukamega_buff/gaioukamega_changjing.skel',
		onceEffectAniName = 'effect_danchu',
		noDelWhenFakeDeath = 1
	},
	[1962130] = {
		id = 1962130,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 1962131, ['caster'] = 2, ['value'] = {0, 'target:hpMax()*0.3', 'self:mp1Max()*1', 21}, ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(3))) and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		iconShowType = {1, 10}
	},
	[1962131] = {
		id = 1962131,
		easyEffectFunc = 'reborn',
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1962132, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 'self:hpMax()*0.15', ['cfgId'] = 1962136, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 521610, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(521601) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['onSomeFlag'] = {'moreE(self:hp()/self:hpMax(),0.15) and (not self:hasBuff(1962478)) and (not target:hasBuff(1962472))'}, ['triggerPoint'] = 12, ['nodeId'] = 0, __size = 3}},
		gateLimit = {{['limit'] = 1, ['type'] = 1, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962132] = {
		id = 1962132,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_laixilamu/hero_laixilamu.skel',
		onceEffectAniName = 'chaopin',
		noDelWhenFakeDeath = 1
	},
	[1962133] = {
		id = 1962133,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 65001,
		dispelType = {1, 1},
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_qs.png'
	},
	[1962134] = {
		id = 1962134,
		overlayType = 2,
		overlayLimit = 5,
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[1962135] = {
		id = 1962135,
		dispelBuff = {1962134},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[1962136] = {
		id = 1962136,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 10, __size = 1}},
		buffFlag = {4021},
		iconShowType = {1, 10}
	},
	[1962137] = {
		id = 1962137,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962138, ['caster'] = 2, ['value'] = {0.4, 10, 1}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962138, ['caster'] = 2, ['value'] = {0.8, 11, 1}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962138] = {
		id = 1962138,
		easyEffectFunc = 'buffSputtering',
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[1962139] = {
		id = 1962139,
		group = 1962139,
		overlayType = 2,
		overlayLimit = 10,
		effectPos = 2,
		onceEffectResPath = 'buff/gaioukamega_buff/gaioukamega_buff.skel',
		onceEffectAniName = 'lianyi',
		textResPath = 'battle/txt/txt_ly1.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962140] = {
		id = 1962140,
		dispelBuff = {1962139, 1963139},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962141] = {
		id = 1962141,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'trigger.buffCfgId == 1962138'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962139, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'self:hasBuff(1963000) and 0 or 1', __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1963139, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'self:hasBuff(1963000) and 1 or 0', __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962133, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'moreE(target2:sumBuffOverlayByGroup(1962139,1963139),3) and 1 or 0', __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962140, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'moreE(target2:sumBuffOverlayByGroup(1962139,1963139),3) and 1 or 0', __size = 7}}}, ['triggerPoint'] = 49, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962142] = {
		id = 1962142,
		easyEffectFunc = 'alterDmgRecordVal',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['finalRate'] = {'setValue(list("finalDamageSub"),( (arg.from==1) and list(env:finalDamageSub()*10000+3000) or list(env:finalDamageSub()*10000)) )'}, __size = 1}}
	},
	[1962143] = {
		id = 1962143,
		dispelBuff = {1962127},
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1
	},
	[1962144] = {
		id = 1962144,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962143, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = '(moreE((countObjByFlag(self:force(),1982)+countObjByFlag(self:force(),1972)), 1) or moreE(countObjByNatureExit(self:force(),3),2)) and 0 or 1', __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962161] = {
		id = 1962161,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'battleFlagDiffer(\'battleFlag\', {1972,1982})', __size = 2}, ['lifeRound'] = 99, ['value'] = 0, ['cfgId'] = 1962162, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'battleFlagDiffer(\'battleFlag\', {1982})', __size = 2}, ['lifeRound'] = 2, ['value'] = 'target2:Bdamage()*0.15', ['cfgId'] = 1962163, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'battleFlagDiffer(\'battleFlag\', {1982})', __size = 2}, ['lifeRound'] = 99, ['value'] = 'target2:BspecialDamage()*0.15', ['cfgId'] = 1962164, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'battleFlagDiffer(\'battleFlag\', {1982})', __size = 2}, ['lifeRound'] = 99, ['value'] = 2000, ['cfgId'] = 1962165, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'battleFlagDiffer(\'battleFlag\', {1972})', __size = 2}, ['lifeRound'] = 99, ['value'] = 'target2:Bdefence()*0.6', ['cfgId'] = 1962166, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'battleFlagDiffer(\'battleFlag\', {1972})', __size = 2}, ['lifeRound'] = 99, ['value'] = 'target2:BspecialDefence()*0.6', ['cfgId'] = 1962167, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'battleFlagDiffer(\'battleFlag\', {1972})', __size = 2}, ['lifeRound'] = 99, ['value'] = 1500, ['cfgId'] = 1962168, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[1962162] = {
		id = 1962162,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_fysl.png',
		iconShowType = {1, 10}
	},
	[1962163] = {
		id = 1962163,
		easyEffectFunc = 'damage',
		group = 1001,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wg_up.png',
		textResPath = 'battle/txt/txt_wgtg.png'
	},
	[1962164] = {
		id = 1962164,
		easyEffectFunc = 'specialDamage',
		group = 1002,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tg_up.png',
		textResPath = 'battle/txt/txt_tgtg.png'
	},
	[1962165] = {
		id = 1962165,
		easyEffectFunc = 'strikeDamage',
		group = 1007,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjsh_up.png',
		textResPath = 'battle/txt/txt_bjshtg.png'
	},
	[1962166] = {
		id = 1962166,
		easyEffectFunc = 'defence',
		group = 1021,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_up.png',
		textResPath = 'battle/txt/txt_wftg.png'
	},
	[1962167] = {
		id = 1962167,
		easyEffectFunc = 'specialDefence',
		group = 1022,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_up.png',
		textResPath = 'battle/txt/txt_tftg.png'
	},
	[1962168] = {
		id = 1962168,
		easyEffectFunc = 'block',
		group = 1028,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_dyl_up.png',
		textResPath = 'battle/txt/txt_dyltg.png'
	},
	[1962220] = {
		id = 1962220,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'not trigger.strike'}, ['triggerPoint'] = 40, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962321, ['caster'] = 2, ['value'] = 2000, ['prob'] = 'self:hasBuff(1963000) and 0 or 1', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1963321, ['caster'] = 2, ['value'] = 2000, ['prob'] = 'self:hasBuff(1963000) and 1 or 0', __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff'}, __size = 6}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962221] = {
		id = 1962221,
		easyEffectFunc = 'strikeResistance',
		skillTimePos = 2,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjkx_up.png',
		textResPath = 'battle/txt/txt_bjkxtg.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962222] = {
		id = 1962222,
		easyEffectFunc = 'immuneControlVal',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_kzmy.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962223] = {
		id = 1962223,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'trigger.strike'}, ['triggerPoint'] = 40, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962321, ['caster'] = 2, ['value'] = 2000, ['prob'] = 'self:hasBuff(1963000) and 0 or 1', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1963321, ['caster'] = 2, ['value'] = 2000, ['prob'] = 'self:hasBuff(1963000) and 1 or 0', __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff'}, __size = 6}, {['onSomeFlag'] = {'trigger.strike'}, ['triggerPoint'] = 40, ['nodeId'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962321, ['caster'] = 2, ['value'] = 2000, ['prob'] = 'self:hasBuff(1963000) and 0 or max(1-getNowRound()*0.1+0.1,0.5)', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1963321, ['caster'] = 2, ['value'] = 2000, ['prob'] = 'self:hasBuff(1963000) and max(1-getNowRound()*0.1+0.1,0.5) or 0', __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff'}, __size = 6}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962224] = {
		id = 1962224,
		easyEffectFunc = 'immuneControlVal',
		dispelBuff = {1981110, 1982124},
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_kzmy.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962225] = {
		id = 1962225,
		easyEffectFunc = 'immuneControlVal',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_mkltg.png',
		specialVal = {70022},
		iconShowType = {1, 10}
	},
	[1962226] = {
		id = 1962226,
		easyEffectFunc = 'alterDmgRecordVal',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['strike'] = {'setValue(list("isNeedImmuneStrike"),list(ifElse(arg.strike == true,1,0)))'}, __size = 1}},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 32, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962232, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'target:hasBuff(1962121) and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 10}
	},
	[1962227] = {
		id = 1962227,
		overlayType = 1,
		overlayLimit = 1,
		iconShowType = {1, 10}
	},
	[1962228] = {
		id = 1962228,
		easyEffectFunc = 'buffDamage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 5, ['damageType'] = 2, __size = 2}},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962229, ['caster'] = 2, ['value'] = 'self:specialDamage()*1.2', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {4021}
	},
	[1962229] = {
		id = 1962229,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		group = 10141,
		overlayType = 2,
		overlayLimit = 3,
		iconResPath = 'battle/buff_icon/logo_lx.png',
		effectResPath = 'buff/liuxue/liuxue.skel',
		effectAniName = {'liuxue_loop'},
		textResPath = 'battle/txt/txt_lx.png',
		specialVal = {{['processId'] = 5, ['damageType'] = 2, __size = 2}},
		triggerBehaviors = {{['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {4021}
	},
	[1962230] = {
		id = 1962230,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['strike'] = {'setValue(list("strike","rate"),list(0,1))'}, __size = 1}}
	},
	[1962231] = {
		id = 1962231,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['onSomeFlag'] = {'trigger.strike'}, ['triggerPoint'] = 40, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962226, ['caster'] = 2, ['value'] = {2, 1}, ['bond'] = 1, ['prob'] = 'target:hasBuff(1962121) and 1 or 0', __size = 7}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}}
	},
	[1962232] = {
		id = 1962232,
		dispelBuff = {1962231, 1962226},
		overlayType = 1,
		overlayLimit = 1
	},
	[1962233] = {
		id = 1962233,
		easyEffectFunc = 'immuneControlVal',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_mkltg.png',
		specialVal = {70022},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962251] = {
		id = 1962251,
		skillTimePos = 2,
		group = 1962251,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 1962252, ['caster'] = 2, ['value'] = {1966, 99, 0, 1, 1, {['hpMax'] = 1, ['rebound'] = 0, __size = 2}, 1, {['y'] = 0, ['followMark'] = 2004, ['x'] = 150, ['dealGroup'] = 4, __size = 4}, 1, 0}, ['bond'] = 1, ['prob'] = '(self:cardID()==1962 and 1 or 0)', __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 3, ['cfgId'] = 1962265, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1962252] = {
		id = 1962252,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		group = 1962251,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0, 0},
		specialTarget = {2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 1962259, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 1962260, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 0, 1}, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962253, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1}, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962271, ['caster'] = 2, ['value'] = 1, ['prob'] = 'self:hasBuff(1962127) and 1 or 0', __size = 6}}, {{['holder'] = 20, ['lifeRound'] = 99, ['value'] = 1, ['cfgId'] = 1962266, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 1962269, ['caster'] = 2, ['value'] = {1, 1, 0, 1, 0, 1}, ['prob'] = 0, __size = 6}}, {{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 1962270, ['caster'] = 2, ['value'] = {1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1962253] = {
		id = 1962253,
		easyEffectFunc = 'inviteAttack',
		skillTimePos = 2,
		group = 1962251,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{0, 1, 2}},
		specialTarget = {{['input'] = 'allEx(list(2004))', ['process'] = 'random(6)', __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1
	},
	[1962254] = {
		id = 1962254,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		group = 10181,
		overlayType = 2,
		overlayLimit = 5,
		iconResPath = 'battle/buff_icon/logo_zd.png',
		effectResPath = 'buff/zhongdu/zhongdu.skel',
		effectAniName = {'zhongdu_loop'},
		textResPath = 'battle/txt/txt_zd.png',
		specialVal = {{['natureType'] = 8, ['damageType'] = 2, ['processId'] = 3008, __size = 3}},
		triggerBehaviors = {{['triggerPoint'] = 5, ['nodeId'] = 0, __size = 2}},
		buffFlag = {4008, 4027}
	},
	[1962255] = {
		id = 1962255,
		easyEffectFunc = 'replaceTarget',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[1962256] = {
		id = 1962256,
		overlayType = 1,
		overlayLimit = 1
	},
	[1962257] = {
		id = 1962257,
		overlayType = 1,
		overlayLimit = 1
	},
	[1962258] = {
		id = 1962258,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1
	},
	[1962259] = {
		id = 1962259,
		group = 50019,
		overlayType = 1,
		overlayLimit = 1
	},
	[1962260] = {
		id = 1962260,
		easyEffectFunc = 'counterAttack',
		skillTimePos = 2,
		group = 1962251,
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {{['input'] = 'selfForce()', ['process'] = 'buffDiffer(\'id\',{1962121})|random(1)', __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1
	},
	[1962261] = {
		id = 1962261,
		easyEffectFunc = 'assistAttack',
		group = 1962251,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962262] = {
		id = 1962262,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 10, ['funcArgs'] = {{{['holder'] = 7, ['lifeRound'] = 1, ['cfgId'] = 1962257, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962261, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 0, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1962263] = {
		id = 1962263,
		easyEffectFunc = 'prophet',
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1962264] = {
		id = 1962264,
		easyEffectFunc = 'kill',
		skillTimePos = 2,
		group = 1962251,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {true, true},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962265] = {
		id = 1962265,
		group = 1962251,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 19, ['funcArgs'] = {{{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1962264, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 3,
		noDelWhenFakeDeath = 1
	},
	[1962266] = {
		id = 1962266,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {'moreE(trigger.delta,1)'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962267, ['caster'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['value'] = 'self2:mp1()*0.5', ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962268, ['caster'] = 2, ['value'] = '-target2:mp1()*0.5', ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 34, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[1962267] = {
		id = 1962267,
		easyEffectFunc = 'addMp1',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[1962268] = {
		id = 1962268,
		easyEffectFunc = 'addMp1',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[1962269] = {
		id = 1962269,
		easyEffectFunc = 'depart',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[1962270] = {
		id = 1962270,
		easyEffectFunc = 'immuneDamage',
		group = 1962252,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1
	},
	[1962271] = {
		id = 1962271,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce()', ['process'] = 'exclude(list(csvSelf:id()))|buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|random(12)', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 1962272, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(3))) and 1 or 1', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 3,
		noDelWhenFakeDeath = 1
	},
	[1962272] = {
		id = 1962272,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962273, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1}, ['bond'] = 1, ['prob'] = 'more(self:getBuffOverlayCount(1962275),2) and 0 or 1', __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962275, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 6, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 1, ['cfgId'] = 1962274, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962273] = {
		id = 1962273,
		easyEffectFunc = 'inviteAttack',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{0, 1, 2}},
		specialTarget = {{['input'] = 'allEx(list(2004))', ['process'] = 'random(6)', __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1
	},
	[1962274] = {
		id = 1962274,
		dispelBuff = {1962273},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962275] = {
		id = 1962275,
		overlayType = 2,
		overlayLimit = 3,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962281] = {
		id = 1962281,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962282, ['caster'] = 2, ['value'] = {2, 99, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[1962282] = {
		id = 1962282,
		easyEffectFunc = 'alterDmgRecordVal',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['finalRate'] = {'setValue(list("finalDamageSub"),((arg.from==1) and list(env:finalDamageSub()*10000+2000) or list(env:finalDamageSub()*10000)) )'}, __size = 1}}
	},
	[1962321] = {
		id = 1962321,
		easyEffectFunc = 'finalDamageSub',
		skillTimePos = 2,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_ylht.png',
		effectResPath = 'buff/gaioukamega_buff/gaioukamega_buff.skel',
		effectAniName = {'yuanliuhuti_loop'},
		textResPath = 'battle/txt/txt_ylht.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962224, ['caster'] = 2, ['value'] = 15000, ['bond'] = 1, ['prob'] = 'target:hasBuff(1962121) and 1 or 0', __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962225, ['caster'] = 2, ['value'] = 15000, ['bond'] = 1, ['prob'] = 'target:hasBuff(1962121) and 1 or 0', __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962231, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'target:hasBuff(1962121) and 1 or 0', __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962251, ['caster'] = 2, ['value'] = 0, ['prob'] = 'target:hasBuff(1962121) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962323, ['caster'] = 2, ['value'] = 'target2:hpMax()*0.1', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962326, ['caster'] = 2, ['value'] = 5000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962327, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'target:hasBuff(1962121) and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962322] = {
		id = 1962322,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		deepCorrect = 9,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962323] = {
		id = 1962323,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao2',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[1962324] = {
		id = 1962324,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'trigger.strike'}, ['triggerPoint'] = 40, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962325, ['caster'] = 2, ['value'] = 5000, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962325] = {
		id = 1962325,
		easyEffectFunc = 'finalDamageSub',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962326] = {
		id = 1962326,
		easyEffectFunc = 'strikeDamageSub',
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962327] = {
		id = 1962327,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 80023,
		immuneBuff = {2381121, 2351137, 2351138, 1981120, 3631217, 2351160, 1811130, 1811125, 2391148, 2441122, 3243141, 1982120, 1982130, 2461212, 2461213, 1261215, 1271314, 1271315, 1271371, 1271373, 1281230, 1281231, 1281232, 1281233, 1281234, 1281236, 1281311, 1281312, 1281313, 1281314, 1281315, 1281321, 1281322, 1281331, 1281332, 1281623, 1281625, 1961129, 1962115, 1962718, 1962723, 1962719, 1962720, 1962723, 1971212, 1972313, 1981120, 1982130, 1991657, 2351150, 2351151, 2391148, 2391149, 2391150, 2421317, 2421335, 2421622, 2461226, 3611118, 3611160, 3611161, 3611162, 3611163, 3611164, 3611171, 3622311, 3622312, 3622313, 3622314, 3623712, 3623715, 3642311, 3642312, 3642313, 4161021, 4024311, 1963718},
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[1962421] = {
		id = 1962421,
		overlayType = 1,
		overlayLimit = 1,
		triggerPriority = 100,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 1962422, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 1962423, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962422] = {
		id = 1962422,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 60009,
		dispelType = {1, 2},
		overlayType = 1,
		overlayLimit = 1,
		triggerPriority = 100,
		specialTarget = {11},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962424, ['caster'] = 2, ['value'] = 'self:specialDamage()*1.5', ['prob'] = 'self:hasBuff(1962431) and 0 or 1', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[1962423] = {
		id = 1962423,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 60005,
		dispelType = {1, 2},
		overlayType = 1,
		overlayLimit = 1,
		triggerPriority = 100,
		specialTarget = {11},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962431, ['caster'] = 2, ['value'] = 'self:specialDamage()*1.5', ['prob'] = 'self:hasBuff(1962424) and 0 or 1', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[1962424] = {
		id = 1962424,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao2',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		lifeRoundType = 2,
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[1962425] = {
		id = 1962425,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'moreE(self:hp()/self:hpMax(),0.8) and (not self:hasBuffGroup(c.kongzhi1_kongzhi2_kongzhi3_oc())) and more(getNowRound(),1)'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'buffDiffer(\'groupFilter\',{{beDispel=10},{c.kongzhi1_kongzhi2_kongzhi3_oc()}})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962426, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(1962434) and 0 or 1', __size = 6}}}, ['triggerPoint'] = 5, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'less(self:hp()/self:hpMax(),0.8) or (self:hasBuffGroup(c.kongzhi1_kongzhi2_kongzhi3_oc())) and more(getNowRound(),1)'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962433, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(1962434) and 0 or 1', __size = 6}}}, ['triggerPoint'] = 5, ['nodeId'] = 2, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'moreE(self:hp()/self:hpMax(),0.8) and more(getNowRound(),1)'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_oc()})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962426, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(1962434) and 0 or 1', __size = 6}}}, ['triggerPoint'] = 5, ['nodeId'] = 3, __size = 5}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962426] = {
		id = 1962426,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 80022,
		dispelBuff = {2381121, 2351137, 2351138, 1981120, 3631217, 2351160, 1811130, 1811125, 2391148, 2441122, 3243141, 1982120, 1982130, 2461212, 2461213, 1261215, 1271314, 1271315, 1271371, 1271373, 1281230, 1281231, 1281232, 1281233, 1281234, 1281236, 1281311, 1281312, 1281313, 1281314, 1281315, 1281321, 1281322, 1281331, 1281332, 1281623, 1281625, 1961129, 1962115, 1962718, 1962723, 1962719, 1962720, 1962723, 1971212, 1972313, 1981120, 1982130, 1991657, 2351150, 2351151, 2391148, 2391149, 2391150, 2421317, 2421335, 2421622, 2461226, 3611118, 3611160, 3611161, 3611162, 3611163, 3611164, 3611171, 3622311, 3622312, 3622313, 3622314, 3623712, 3623715, 3642311, 3642312, 3642313, 4161021, 4024311, 1963718},
		dispelType = {2, 999, 0, 1, 0, 9},
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_wqjh.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 3, ['value'] = 1, ['cfgId'] = 1962434, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[1962427] = {
		id = 1962427,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 60005,
		dispelType = {1, 2},
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {11},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 1962429, ['caster'] = 2, ['value'] = 'self:specialDamage()*1.5', ['prob'] = 'self:hasBuff(1962430) and 0 or 1', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['delSelfWhenTriggered'] = 2, ['triggerPoint'] = 1, ['nodeId'] = 0, __size = 3}},
		noDelWhenFakeDeath = 1
	},
	[1962428] = {
		id = 1962428,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 60009,
		dispelType = {1, 2},
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {11},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962430, ['caster'] = 2, ['value'] = 'self:specialDamage()*1.5', ['prob'] = 'self:hasBuff(1962429) and 0 or 1', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['delSelfWhenTriggered'] = 2, ['triggerPoint'] = 1, ['nodeId'] = 0, __size = 3}}
	},
	[1962429] = {
		id = 1962429,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao2',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		lifeRoundType = 2,
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[1962430] = {
		id = 1962430,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao2',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		lifeRoundType = 2,
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[1962431] = {
		id = 1962431,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao2',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		lifeRoundType = 2,
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[1962432] = {
		id = 1962432,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao2',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		specialVal = {{['ignoreLockResume'] = true, ['ignoreToDamage'] = true, ['ignoreHealAddRate'] = true, ['ignoreBeHealAddRate'] = true, __size = 4}},
		lifeRoundType = 2,
		iconShowType = {1, 10}
	},
	[1962433] = {
		id = 1962433,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 80022,
		dispelBuff = {2381121, 2351137, 2351138, 1981120, 3631217, 2351160, 1811130, 1811125, 2391148, 2441122, 3243141, 1982120, 1982130, 2461212, 2461213, 1261215, 1271314, 1271315, 1271371, 1271373, 1281230, 1281231, 1281232, 1281233, 1281234, 1281236, 1281311, 1281312, 1281313, 1281314, 1281315, 1281321, 1281322, 1281331, 1281332, 1281623, 1281625, 1961129, 1962115, 1962718, 1962723, 1962719, 1962720, 1962723, 1971212, 1972313, 1981120, 1982130, 1991657, 2351150, 2351151, 2391148, 2391149, 2391150, 2421317, 2421335, 2421622, 2461226, 3611118, 3611160, 3611161, 3611162, 3611163, 3611164, 3611171, 3622311, 3622312, 3622313, 3622314, 3623712, 3623715, 3642311, 3642312, 3642313, 4161021, 4024311, 1963718},
		dispelType = {2, 999, 0, 1, 0, 9},
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_wqjh.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 3, ['value'] = 1, ['cfgId'] = 1962434, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[1962434] = {
		id = 1962434,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962451] = {
		id = 1962451,
		easyEffectFunc = 'speed',
		group = 10081,
		groupPower = 302,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_down.png',
		textResPath = 'battle/txt/txt_sdjd.png',
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962452] = {
		id = 1962452,
		easyEffectFunc = 'strike',
		group = 10006,
		groupPower = 302,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjl_down.png',
		textResPath = 'battle/txt/txt_bjljd.png',
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962453] = {
		id = 1962453,
		easyEffectFunc = 'finalDamageAdd',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962454] = {
		id = 1962454,
		easyEffectFunc = 'finalDamageSub',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962455] = {
		id = 1962455,
		easyEffectFunc = 'ultimateSub',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962456] = {
		id = 1962456,
		easyEffectFunc = 'mp1Recover',
		overlayType = 2,
		overlayLimit = 5,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962457] = {
		id = 1962457,
		easyEffectFunc = 'mp1Recover',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962461] = {
		id = 1962461,
		easyEffectFunc = 'buff2',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 3, ['cfgId'] = 1962465, ['caster'] = 2, ['value'] = {0, 1, 0, 10}, ['prob'] = '((target2:natureIntersection(list(3))) and self:cardID()==1962) and 1 or 0', __size = 6}}, {{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'exclude(list(csvSelf:id()))|random(12)', __size = 2}, ['lifeRound'] = 3, ['cfgId'] = 1962471, ['caster'] = 2, ['value'] = {0, 1, 0, 10}, ['prob'] = '((target2:natureIntersection(list(3))) and self:cardID()==1962) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962462] = {
		id = 1962462,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962463] = {
		id = 1962463,
		easyEffectFunc = 'speed',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_down.png',
		textResPath = 'battle/txt/txt_sdjd.png',
		iconShowType = {1, 10}
	},
	[1962464] = {
		id = 1962464,
		easyEffectFunc = 'lockMp1Add',
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962264, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962465] = {
		id = 1962465,
		easyEffectFunc = 'reborn',
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['value'] = 0, ['cfgId'] = 1962466, ['caster'] = 2, __size = 5}}, {{['holder'] = 11, ['lifeRound'] = 99, ['value'] = 1500, ['cfgId'] = 1962482, ['caster'] = 2, __size = 5}}, {{['holder'] = 11, ['lifeRound'] = 99, ['value'] = 1500, ['cfgId'] = 1962483, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['onSomeFlag'] = {'more(getForceNum(self:force()),0)'}, ['triggerPoint'] = 12, ['nodeId'] = 0, __size = 3}},
		gateLimit = {{['limit'] = 1, ['type'] = 1, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962466] = {
		id = 1962466,
		easyEffectFunc = 'buff10',
		group = 80021,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerTimes'] = {1, 1}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['value'] = 1965, ['cfgId'] = 1962488, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 99, ['value'] = {99, 1}, ['cfgId'] = 1962473, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 99, ['value'] = 0, ['cfgId'] = 1962464, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 99, ['value'] = 0, ['cfgId'] = 1962478, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962475, ['caster'] = 2, ['value'] = {0, 0, 0, 1, 0, 0}, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['value'] = 0, ['cfgId'] = 1962487, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 99, ['value'] = 1, ['cfgId'] = 1962484, ['caster'] = 2, __size = 5}}, {{['holder'] = 11, ['lifeRound'] = 99, ['value'] = 1, ['cfgId'] = 1962489, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 99, ['value'] = 0, ['cfgId'] = 1962479, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'allEx(list(c.shuixigensui_oc()))', ['process'] = 'random(99)', __size = 2}, ['lifeRound'] = 99, ['value'] = 1, ['cfgId'] = 1962489, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 1, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962467] = {
		id = 1962467,
		easyEffectFunc = 'buff2',
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		effectShowOnAttack = true,
		holderActionType = {['typ'] = 'hide', ['args'] = {['other'] = {['isShow'] = false, __size = 1}, ['lifebar'] = {['isShow'] = false, __size = 1}, __size = 2}, __size = 2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 19, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962468, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'lessE(getForceNum(self:force()),countObjByBuff(self:force(),{1962466,1962472})) and (getGateType() == 21)'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962477, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 32, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 3,
		noDelWhenFakeDeath = 1,
		buffFlag = {3001},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962468] = {
		id = 1962468,
		easyEffectFunc = 'kill',
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		specialVal = {true, true},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962470] = {
		id = 1962470,
		easyEffectFunc = 'changeUnit',
		skillTimePos = 2,
		group = 1962471,
		dispelBuff = {3304611, 3304621, 3304622},
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_hyzl.png',
		textResPath = 'battle/txt/txt_hyzl.png',
		specialVal = {{true, false, false}, true, true},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962471] = {
		id = 1962471,
		easyEffectFunc = 'reborn',
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['value'] = 0, ['cfgId'] = 1962472, ['caster'] = 2, __size = 5}}, {{['holder'] = 11, ['lifeRound'] = 99, ['value'] = 1500, ['cfgId'] = 1962482, ['caster'] = 2, __size = 5}}, {{['holder'] = 11, ['lifeRound'] = 99, ['value'] = 1500, ['cfgId'] = 1962483, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 12, ['nodeId'] = 0, __size = 2}},
		gateLimit = {{['limit'] = 2, ['type'] = 2, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962472] = {
		id = 1962472,
		easyEffectFunc = 'buff10',
		group = 80021,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerTimes'] = {1, 1}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['value'] = 1965, ['cfgId'] = 1962470, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 99, ['value'] = {99, 1}, ['cfgId'] = 1962473, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 99, ['value'] = 0, ['cfgId'] = 1962474, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 5, ['value'] = 0, ['cfgId'] = 1962467, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962475, ['caster'] = 2, ['value'] = {0, 0, 0, 1, 0, 0}, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 99, ['value'] = 0, ['cfgId'] = 1962487, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 99, ['value'] = 1, ['cfgId'] = 1962484, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 99, ['value'] = 1, ['cfgId'] = 1962492, ['caster'] = 1, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 99, ['value'] = 0, ['cfgId'] = 1962479, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'allEx(list(c.shuixigensui_oc()))', ['process'] = 'random(99)', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 1962489, ['caster'] = 2, ['value'] = 1, ['prob'] = 0, __size = 6}}}, ['triggerPoint'] = 1, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962473] = {
		id = 1962473,
		easyEffectFunc = 'keepHpUnChanged',
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962474] = {
		id = 1962474,
		easyEffectFunc = 'lockMp1Add',
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962264, ['caster'] = 2, ['value'] = 1, ['prob'] = 0, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962475] = {
		id = 1962475,
		easyEffectFunc = 'depart',
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		holderActionType = {['typ'] = 'opacity', __size = 1},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962476] = {
		id = 1962476,
		easyEffectFunc = 'stun',
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962477] = {
		id = 1962477,
		easyEffectFunc = 'kill',
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		specialVal = {true, true},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962478] = {
		id = 1962478,
		easyEffectFunc = 'buff2',
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		effectShowOnAttack = true,
		holderActionType = {['typ'] = 'hide', ['args'] = {['other'] = {['isShow'] = false, __size = 1}, ['lifebar'] = {['isShow'] = false, __size = 1}, __size = 2}, __size = 2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'lessE(getForceNum(self:force()),countObjByBuff(self:force(),{1962466}))'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962477, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 32, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962479] = {
		id = 1962479,
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962476, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 1, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 6, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1962481, ['caster'] = 2, __size = 5}}}, ['extraAttackTrigger'] = 1, ['nodeId'] = 2, __size = 5}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962480] = {
		id = 1962480,
		easyEffectFunc = 'syncAttack',
		skillTimePos = 2,
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{0, 1, 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'target:getExAttackMode()==3'}, ['triggerPoint'] = 7, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1500, ['cfgId'] = 2241000, ['caster'] = 1, __size = 5}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['onSomeFlag'] = {'target:getExAttackMode()==3 and getExtraRoundId()==1962480'}, ['triggerPoint'] = 30, ['nodeId'] = 2, ['funcArgs'] = {{{['holder'] = 18, ['lifeRound'] = 2, ['cfgId'] = 1962463, ['caster'] = 1, ['value'] = '-target2:speed()*0.1', ['prob'] = '(self2:natureIntersection(list(3))) and 1 or 0', __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962481] = {
		id = 1962481,
		group = 1962471,
		dispelBuff = {1962476},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962482] = {
		id = 1962482,
		easyEffectFunc = 'damageAdd',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjc_up.png',
		textResPath = 'battle/txt/txt_shtg.png',
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[1962483] = {
		id = 1962483,
		easyEffectFunc = 'damageSub',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjm_up.png',
		textResPath = 'battle/txt/txt_shjmtg.png',
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[1962484] = {
		id = 1962484,
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962485, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 0}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962485] = {
		id = 1962485,
		easyEffectFunc = 'assistAttack',
		skillTimePos = 2,
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'target:getExAttackMode()==5 and getExtraRoundId()==1962485'}, ['triggerPoint'] = 30, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 18, ['lifeRound'] = 2, ['cfgId'] = 1962463, ['caster'] = 1, ['value'] = '-target2:speed()*0.1', ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962486] = {
		id = 1962486,
		easyEffectFunc = 'replaceSkill',
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962487] = {
		id = 1962487,
		easyEffectFunc = 'silence',
		skillTimePos = 2,
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0},
		ignoreHolder = 1,
		ignoreCaster = {1},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962488] = {
		id = 1962488,
		easyEffectFunc = 'changeUnit',
		skillTimePos = 2,
		group = 1962471,
		dispelBuff = {3304611, 3304621, 3304622},
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_hyzl.png',
		textResPath = 'battle/txt/txt_hyzl.png',
		specialVal = {{false, false, false}, true, true},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962489] = {
		id = 1962489,
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962480, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 7, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962491, ['caster'] = 1, ['value'] = 500, ['prob'] = '(self2:natureIntersection(list(3))) and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 6, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962490, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 3, __size = 4}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962490] = {
		id = 1962490,
		skillTimePos = 2,
		group = 1962471,
		dispelBuff = {1962480, 1962493},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[1962491] = {
		id = 1962491,
		easyEffectFunc = 'finalDamageAdd',
		group = 1962471,
		overlayType = 2,
		overlayLimit = 5,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962492] = {
		id = 1962492,
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962493, ['caster'] = 1, ['value'] = {'list(1,0,0)', 1, 1}, ['bond'] = 1, ['prob'] = 'self2:hasBuff(1962121) and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 6, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962490, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962493] = {
		id = 1962493,
		easyEffectFunc = 'syncAttack',
		skillTimePos = 2,
		group = 1962471,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{0, 1, 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'target:getExAttackMode()==3'}, ['triggerPoint'] = 7, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1500, ['cfgId'] = 2241000, ['caster'] = 1, __size = 5}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['onSomeFlag'] = {'target:getExAttackMode()==3 and getExtraRoundId()==1962493'}, ['triggerPoint'] = 30, ['nodeId'] = 2, ['funcArgs'] = {{{['holder'] = 18, ['lifeRound'] = 2, ['cfgId'] = 1962463, ['caster'] = 1, ['value'] = '-target2:speed()*0.1', ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962511] = {
		id = 1962511,
		easyEffectFunc = 'block',
		skillTimePos = 2,
		group = 1028,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_dyl_up.png',
		textResPath = 'battle/txt/txt_dyltg.png'
	},
	[1962512] = {
		id = 1962512,
		easyEffectFunc = 'strikeResistance',
		skillTimePos = 2,
		group = 1026,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjkx_up.png',
		textResPath = 'battle/txt/txt_bjkxtg.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962513] = {
		id = 1962513,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 60002,
		dispelType = {1, 2},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[1962600] = {
		id = 1962600,
		easyEffectFunc = 'aura',
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {{['input'] = 'all', ['process'] = 'random(12)', __size = 2}},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 1961121, ['caster'] = 2, ['value'] = '(2000+skillLevel*20-20)*(target2:id()==self:id() and 1 or 0.5)', ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and (( target2:natureIntersection(list(3))) and 1 or 0) or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 1961122, ['caster'] = 2, ['value'] = '(1000+skillLevel*10-10)*(target2:id()==self:id() and 1 or 0.5)', ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and (( target2:natureIntersection(list(3))) and 1 or 0) or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 1961123, ['caster'] = 2, ['value'] = '-target2:specialDamage()*0.03*countObjByNatureExit(self:force(),3)', ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and 0 or 1', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 1961124, ['caster'] = 2, ['value'] = '-target2:specialDefence()*0.03*countObjByNatureExit(self:force(),3)', ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and 0 or 1', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1962601] = {
		id = 1962601,
		easyEffectFunc = 'aura',
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {{['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|attr("strike","max",1)', __size = 2}},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 1962915, ['caster'] = 2, ['value'] = '-0.06*target2:Bspeed()', ['bond'] = 1, __size = 6}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 1962916, ['caster'] = 2, ['value'] = -1500, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1962611] = {
		id = 1962611,
		easyEffectFunc = 'finalDamageSub',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'koudai_gaiouka/shuiliuhuanrao1.skel',
		effectAniName = {'shuiliuhuanrao_qian_loop'},
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao1.skel',
		onceEffectAniName = 'shuiliuhuanrao_qian',
		effectOnEnd = {['pos'] = 0, ['aniName'] = 'shuiliuxiaoshi_qian', ['res'] = 'koudai_gaiouka/shuiliuhuanrao1.skel', __size = 3},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 1962612, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 19, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962613, ['caster'] = 2, ['value'] = 'self:hpMax()*0.1', ['prob'] = 0, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 6, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962613, ['caster'] = 2, ['value'] = 'self:hpMax()*0.1', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 3, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 10}
	},
	[1962612] = {
		id = 1962612,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'koudai_gaiouka/shuiliuhuanrao2.skel',
		effectAniName = {'shuiliuhuanrao_hou_loop'},
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao2.skel',
		onceEffectAniName = 'shuiliuhuanrao_hou',
		effectOnEnd = {['pos'] = 0, ['aniName'] = 'shuiliuxiaoshi_hou', ['res'] = 'koudai_gaiouka/shuiliuhuanrao1.skel', __size = 3},
		deepCorrect = 9,
		iconShowType = {1, 10}
	},
	[1962613] = {
		id = 1962613,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao2',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[1962614] = {
		id = 1962614,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962615, ['caster'] = 2, ['value'] = 'list(list(c.groupdebuffs2_oc()),2,99)', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		iconShowType = {1, 10}
	},
	[1962615] = {
		id = 1962615,
		easyEffectFunc = 'transferBuffToOther',
		overlayLimit = 1,
		specialVal = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 1962616, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 10}
	},
	[1962616] = {
		id = 1962616,
		easyEffectFunc = 'transfereffect',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_zyjh.png',
		iconShowType = {1, 10}
	},
	[1962617] = {
		id = 1962617,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 29, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962614, ['caster'] = 2, ['value'] = 1, ['prob'] = 'ifElse(exitInTab(trigger.beAddBuff:getGroup(),list(c.groupdebuffs2_oc())),1,0)', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[1962651] = {
		id = 1962651,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 7, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 2, ['cfgId'] = 1962657, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 7, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDiffer(\'id\',{1962657})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962656, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['delSelfWhenTriggered'] = 2, ['triggerPoint'] = 1, ['nodeId'] = 0, __size = 3}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962652] = {
		id = 1962652,
		easyEffectFunc = 'shiftPos',
		skillTimePos = 2,
		group = 10,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0, 'nil', 'shiftObj:hasBuff(1962653) or not shiftObj:hasBuff(1962657)'},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962653, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962654, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962653] = {
		id = 1962653,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962654] = {
		id = 1962654,
		skillTimePos = 2,
		dispelBuff = {1962657},
		overlayType = 2,
		overlayLimit = 2
	},
	[1962655] = {
		id = 1962655,
		skillTimePos = 2,
		overlayType = 2,
		overlayLimit = 2
	},
	[1962656] = {
		id = 1962656,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerTimes'] = {1, 1}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962652, ['caster'] = 1, ['value'] = {3, 3, {1}}, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 1, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1962657] = {
		id = 1962657,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1962711] = {
		id = 1962711,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 30, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 1962712, ['caster'] = 2, __size = 5}}, {{['holder'] = 18, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 1962721, ['caster'] = 2, __size = 5}}, {{['holder'] = 18, ['lifeRound'] = 2, ['value'] = '-target2:speed()*0.1', ['cfgId'] = 1962713, ['caster'] = 2, __size = 5}}, {{['holder'] = 18, ['lifeRound'] = 2, ['value'] = 1, ['cfgId'] = 1962714, ['caster'] = 2, __size = 5}}, {{['holder'] = 18, ['lifeRound'] = 2, ['cfgId'] = 1962716, ['caster'] = 2, ['value'] = 2000, ['prob'] = 1, __size = 6}}, {{['holder'] = 18, ['lifeRound'] = 1, ['cfgId'] = 1962717, ['caster'] = 2, ['value'] = 0, ['prob'] = 'target2:hasBuff(1962115) and 0.5 or 0', __size = 6}}, {{['holder'] = 18, ['lifeRound'] = '(self:hasBuff(1962127) and 2 or 1)', ['cfgId'] = 1962718, ['caster'] = 2, ['value'] = 'target2:hpMax()*0.65', ['prob'] = '(not self:hasBuff(1963000)) and (not target2:hasBuff(1962718)) and moreE(target2:getBuffOverlayCount(1962721),2) and (less(sumBuffOverlayByGroupInForce((self:force() == 1 and 2 or 1),list(99999),1962718),2)) and 1 or 0', __size = 6}}, {{['holder'] = 18, ['lifeRound'] = '(self:hasBuff(1962127) and 2 or 1)', ['cfgId'] = 1963718, ['caster'] = 2, ['value'] = 'target2:hpMax()*0.65', ['prob'] = 'self:hasBuff(1963000) and (not target2:hasBuff(1963718)) and moreE(target2:getBuffOverlayCount(1962721),2) and (less(sumBuffOverlayByGroupInForce((self:force() == 1 and 2 or 1),list(99999),1962718),2)) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['delSelfWhenTriggered'] = 2, ['triggerPoint'] = 1, ['nodeId'] = 0, __size = 3}},
		iconShowType = {1, 10}
	},
	[1962712] = {
		id = 1962712,
		group = 1961132,
		overlayType = 2,
		overlayLimit = 6
	},
	[1962713] = {
		id = 1962713,
		easyEffectFunc = 'speed',
		group = 10081,
		overlayType = 2,
		overlayLimit = 5,
		iconResPath = 'battle/buff_icon/logo_sd_down.png',
		textResPath = 'battle/txt/txt_sdjd.png'
	},
	[1962714] = {
		id = 1962714,
		group = 10000,
		overlayType = 2,
		overlayLimit = 5,
		iconResPath = 'battle/buff_icon/logo_sxys.png',
		textResPath = 'battle/txt/txt_sxys.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 30, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 800, ['cfgId'] = 1962715, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'(target:attackerSkill():getNatureType()==3) or false'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['value'] = 800, ['cfgId'] = 1962715, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 14, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 30, ['nodeId'] = 0, __size = 2}}
	},
	[1962715] = {
		id = 1962715,
		easyEffectFunc = 'damageDeepen',
		skillTimePos = 2,
		overlayType = 2,
		overlayLimit = 5,
		triggerBehaviors = {{['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 10}
	},
	[1962716] = {
		id = 1962716,
		easyEffectFunc = 'damageReduce',
		group = 10005,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjc_down.png',
		textResPath = 'battle/txt/txt_shjd.png'
	},
	[1962717] = {
		id = 1962717,
		easyEffectFunc = 'confusion',
		skillTimePos = 2,
		group = 108,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_hl.png',
		effectPos = 1,
		effectOffsetPos = {['y'] = -280, ['x'] = 0, __size = 2},
		textResPath = 'battle/txt/txt_hl.png',
		iconShowType = {1, 10}
	},
	[1962718] = {
		id = 1962718,
		easyEffectFunc = 'freeze',
		group = 1962718,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sl.png',
		effectResPath = 'buff/gaioukamega_buff/gaioukamega_buff.skel',
		effectAniName = {'shuilao_loop'},
		onceEffectResPath = 'buff/gaioukamega_buff/gaioukamega_buff.skel',
		onceEffectAniName = 'shuilao_chuxian',
		holderActionType = {['typ'] = 'pause', __size = 1},
		textResPath = 'battle/txt/txt_sl2.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'near|exclude(list(csvSelf:id()))|buffDifferExclude(\'group\',{c.yinshenplus_fly_oc()})|buffDifferExclude(\'id\',{1962718,1963718})|random(1)', __size = 2}, ['lifeRound'] = 3, ['cfgId'] = 1962722, ['caster'] = 1, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'attrDiffer("natureType", {3})', __size = 2}, ['lifeRound'] = 3, ['cfgId'] = 1962754, ['caster'] = 1, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 1962756, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 1962757, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962759, ['caster'] = 2, ['value'] = 'self:specialDamage()*2', ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 19, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962753, ['caster'] = 2, ['value'] = {'list(381213,641311,641312,177123,2411639,3301124,3681211,3771114,2421317,2421335,2421622,3304131,3304211)', 'list(50001,50002,50003,50005,50014,50021,50022,50030,50034,80016)', 'list(\'controlPerVal\',\'immuneControlVal\')', 'list(\'controlPer\',\'immuneControl\')'}, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'attrDiffer("natureType", {3,4,6})', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962752, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962760, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962834, ['caster'] = 2, ['value'] = 0, ['prob'] = '(moreE(self:getBuffOverlayCount(1962835),3) and self:flagZ3()) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962833, ['caster'] = 2, ['value'] = 0, ['prob'] = '(less(self:getBuffOverlayCount(1962835),3) and self:flagZ3() and (not target2:hasBuff(1962834))) and 1 or 0', __size = 6}}}, ['nodeId'] = 3, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 10}
	},
	[1962719] = {
		id = 1962719,
		easyEffectFunc = 'damageLink',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[1962720] = {
		id = 1962720,
		easyEffectFunc = 'stun',
		group = 1962723,
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'koudai_gaiouka_mega/xuanwo.skel',
		effectAniName = {'xuanwo_loop'},
		holderActionType = {['typ'] = 'pause', __size = 1},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 1962723, ['caster'] = 2, ['value'] = {1, 1, 0, 1, 1, 1}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[1962721] = {
		id = 1962721,
		overlayType = 2,
		overlayLimit = 6,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[1962722] = {
		id = 1962722,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 1962719, ['caster'] = 2, ['value'] = {1, 0, 2}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 3, ['cfgId'] = 1962719, ['caster'] = 2, ['value'] = {1, 0, 2}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 1962720, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[1962723] = {
		id = 1962723,
		easyEffectFunc = 'depart',
		group = 1962723,
		overlayType = 1,
		overlayLimit = 1,
		holderActionType = {['typ'] = 'opacity', ['args'] = {['value'] = 0, __size = 1}, __size = 2},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[1962751] = {
		id = 1962751,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 65001,
		dispelType = {1, 2},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 30, ['nodeId'] = 0, __size = 2}}
	},
	[1962752] = {
		id = 1962752,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962755, ['caster'] = 8, ['value'] = 'self:hpMax()*0.05', ['prob'] = 'self2:hasBuff(1962753) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		iconShowType = {1, 10}
	},
	[1962753] = {
		id = 1962753,
		easyEffectFunc = 'loseImmuneEfficacy',
		group = 1962753,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{26, 29}},
		iconShowType = {1, 10}
	},
	[1962754] = {
		id = 1962754,
		easyEffectFunc = 'sneer',
		skillTimePos = 2,
		group = 110,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tx.png',
		specialVal = {0, 1, 2},
		iconShowType = {1, 10}
	},
	[1962755] = {
		id = 1962755,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao2',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[1962756] = {
		id = 1962756,
		group = 60005,
		overlayType = 1,
		overlayLimit = 1
	},
	[1962757] = {
		id = 1962757,
		group = 10000,
		overlayType = 2,
		overlayLimit = 5,
		iconResPath = 'battle/buff_icon/logo_sxys.png',
		textResPath = 'battle/txt/txt_sxys.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'(target:attackerSkill():getNatureType()==3) or false'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['value'] = 1000, ['cfgId'] = 1962758, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 14, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[1962758] = {
		id = 1962758,
		easyEffectFunc = 'damageDeepen',
		overlayType = 2,
		overlayLimit = 5,
		triggerBehaviors = {{['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 10}
	},
	[1962759] = {
		id = 1962759,
		easyEffectFunc = 'buffDamage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['natureType'] = 3, ['damageType'] = 2, ['processId'] = 3003, __size = 3}},
		buffFlag = {4003, 4021}
	},
	[1962760] = {
		id = 1962760,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 42, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962761, ['caster'] = 2, ['value'] = 'self:specialDamage()*2', ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962762, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 32, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962761, ['caster'] = 2, ['value'] = 'self:specialDamage()*2', ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962762, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 1, ['nodeId'] = 0, __size = 3}},
		iconShowType = {1, 10}
	},
	[1962761] = {
		id = 1962761,
		easyEffectFunc = 'buffDamage',
		overlayLimit = 1,
		specialVal = {{['natureType'] = 3, ['damageType'] = 2, ['processId'] = 3003, __size = 3}},
		buffFlag = {4003, 4021}
	},
	[1962762] = {
		id = 1962762,
		dispelBuff = {1962760},
		overlayLimit = 1,
		iconShowType = {1, 10}
	},
	[1962811] = {
		id = 1962811,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'lessE(self:hp()/self:hpMax(),0.35)'}, ['triggerPoint'] = 18, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962812, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(1962813) and 0 or 1', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 'self:hpMax()*0.3', ['cfgId'] = 1962814, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 3, ['cfgId'] = 1962282, ['caster'] = 2, ['value'] = {2, 101, 1}, ['prob'] = 1, __size = 6}}}, ['triggerTimes'] = {1, 1}, ['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, __size = 6}},
		gateLimit = {{['limit'] = 1, ['type'] = 1, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962812] = {
		id = 1962812,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 80022,
		dispelBuff = {2381121, 2351137, 2351138, 1981120, 3631217, 2351160, 1811130, 1811125, 2391148, 2441122, 3243141, 1982120, 1982130, 2461212, 2461213, 1261215, 1271314, 1271315, 1271371, 1271373, 1281230, 1281231, 1281232, 1281233, 1281234, 1281236, 1281311, 1281312, 1281313, 1281314, 1281315, 1281321, 1281322, 1281331, 1281332, 1281623, 1281625, 1961129, 1962115, 1962718, 1962723, 1962719, 1962720, 1962723, 1971212, 1972313, 1981120, 1982130, 1991657, 2351150, 2351151, 2391148, 2391149, 2391150, 2421317, 2421335, 2421622, 2461226, 3611118, 3611160, 3611161, 3611162, 3611163, 3611164, 3611171, 3622311, 3622312, 3622313, 3622314, 3623712, 3623715, 3642311, 3642312, 3642313, 4161021, 4024311, 1963718},
		dispelType = {2, 999, 0, 1, 0, 9},
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_wqjh.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 99, ['value'] = 1, ['cfgId'] = 1962813, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[1962813] = {
		id = 1962813,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962814] = {
		id = 1962814,
		easyEffectFunc = 'addHP',
		overlayLimit = 1,
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao2',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		specialVal = {{['ignoreLockResume'] = true, ['ignoreToDamage'] = true, ['ignoreHealAddRate'] = true, ['ignoreBeHealAddRate'] = true, __size = 4}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[1962815] = {
		id = 1962815,
		easyEffectFunc = 'alterDmgRecordVal',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['finalRate'] = {'setValue(list("finalDamageSub"),((arg.from==1) and list(env:finalDamageSub()*10000+8000) or list(env:finalDamageSub()*10000)) )'}, __size = 1}}
	},
	[1962821] = {
		id = 1962821,
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 10, ['funcArgs'] = {{{['holder'] = 15, ['lifeRound'] = 2, ['cfgId'] = 1962822, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = '(self2:hasBuff(1962321) or self2:hasBuff(1963321)) and 1 or 0', __size = 7}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962822] = {
		id = 1962822,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 5, ['lifeRound'] = 2, ['cfgId'] = 1962824, ['caster'] = 1, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 5, ['lifeRound'] = 2, ['cfgId'] = 1962825, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		lifeRoundType = 2,
		gateLimit = {{['limit'] = 1, ['type'] = 2, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962823] = {
		id = 1962823,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_xiaozhibanpikaqiu/hero_xiaozhibanpikaqiu.skel',
		onceEffectAniName = 'shandianlian_loop',
		onceEffectWait = true,
		textResPath = 'battle/txt/txt_dlcd.png',
		specialVal = {{['natureType'] = 5, ['damageType'] = 2, ['processId'] = 3005, __size = 3}},
		specialTarget = {1, {['input'] = 'selfForce()|nodead', ['process'] = 'buffDiffer(\'id\',{1961124})|random(1)', __size = 2}},
		buffFlag = {4005, 4021}
	},
	[1962824] = {
		id = 1962824,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 10, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962823, ['caster'] = 1, ['value'] = '(self2:attackerSkill() and self2:attackerSkill():getTargetTotalDamage(self2) or 0)*0.3', ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962825] = {
		id = 1962825,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 10, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962826, ['caster'] = 1, ['value'] = '(self2:attackerSkill() and self2:attackerSkill():getTargetTotalDamage(self2) or 0)*0.3', ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962826] = {
		id = 1962826,
		easyEffectFunc = 'addHP',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao2',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[1962831] = {
		id = 1962831,
		easyEffectFunc = 'speed',
		group = 10081,
		groupPower = 302,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_down.png',
		textResPath = 'battle/txt/txt_sdjd.png',
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[1962832] = {
		id = 1962832,
		easyEffectFunc = 'mp1Recover',
		group = 1321,
		groupPower = 302,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_nqhf_down.png',
		textResPath = 'battle/txt/txt_nqhfjd.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[1962833] = {
		id = 1962833,
		group = 1962718,
		groupPower = 302,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sl2.png',
		effectResPath = 'koudai_gaiouka_mega/xuanwo.skel',
		effectAniName = {'xuanwo_loop'},
		effectPos = 2,
		textResPath = 'battle/txt/txt_xw.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 1962831, ['caster'] = 2, ['value'] = '-target2:Bspeed()*0.6', ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 1962832, ['caster'] = 2, ['value'] = -6000, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962835, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[1962834] = {
		id = 1962834,
		easyEffectFunc = 'stun',
		group = 1962718,
		groupPower = 103,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sl2.png',
		textResPath = 'battle/txt/txt_zx.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962837, ['caster'] = 2, ['value'] = 'target2:hp()*0.2', ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962838, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962836, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[1962835] = {
		id = 1962835,
		overlayType = 2,
		overlayLimit = 3,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[1962836] = {
		id = 1962836,
		dispelBuff = {1962835},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[1962837] = {
		id = 1962837,
		easyEffectFunc = 'buffDamage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['natureType'] = 3, ['damageType'] = 2, ['processId'] = 3003, __size = 3}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {4003, 4021}
	},
	[1962838] = {
		id = 1962838,
		easyEffectFunc = 'lockMp1Add',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[1962839] = {
		id = 1962839,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDiffer(\'id\',{1962833,1962834})', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962840, ['caster'] = 1, ['value'] = 'self2:curSkill():getTotalDamage()*0.8', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'attrDiffer("natureType", {3})|attr("hp","min",1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962841, ['caster'] = 1, ['value'] = 'self2:curSkill():getTotalDamage()*0.8', ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[1962840] = {
		id = 1962840,
		easyEffectFunc = 'buffDamage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['natureType'] = 3, ['damageType'] = 2, ['processId'] = 3003, __size = 3}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {4003, 4021}
	},
	[1962841] = {
		id = 1962841,
		easyEffectFunc = 'addHP',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao2',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[1962911] = {
		id = 1962911,
		easyEffectFunc = 'strikeResistance',
		skillTimePos = 2,
		groupPower = 102,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjkx_up.png',
		textResPath = 'battle/txt/txt_bjkxtg.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962912] = {
		id = 1962912,
		easyEffectFunc = 'immuneControlVal',
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_kzmy.png',
		specialVal = {70002},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962913] = {
		id = 1962913,
		easyEffectFunc = 'specialDamage',
		skillTimePos = 2,
		group = 10002,
		groupPower = 102,
		overlayType = 8,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tg_down.png',
		textResPath = 'battle/txt/txt_tgjd.png'
	},
	[1962914] = {
		id = 1962914,
		easyEffectFunc = 'specialDefence',
		group = 10022,
		groupPower = 102,
		overlayType = 8,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_down.png',
		textResPath = 'battle/txt/txt_tfjd.png'
	},
	[1962915] = {
		id = 1962915,
		easyEffectFunc = 'speed',
		group = 10081,
		groupPower = 302,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_down.png',
		textResPath = 'battle/txt/txt_sdjd.png',
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962916] = {
		id = 1962916,
		easyEffectFunc = 'strike',
		group = 10006,
		groupPower = 302,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjl_down.png',
		textResPath = 'battle/txt/txt_bjljd.png',
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962917] = {
		id = 1962917,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'(getNowRound()==3)'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962921, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 3, ['nodeId'] = 1, __size = 5}}
	},
	[1962918] = {
		id = 1962918,
		easyEffectFunc = 'strikeResistance',
		skillTimePos = 2,
		group = 2026,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjkx_up.png',
		textResPath = 'battle/txt/txt_bjkxtg.png',
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5021},
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962919] = {
		id = 1962919,
		group = 99997,
		immuneBuff = {1972616},
		dispelBuff = {1972616},
		overlayLimit = 1,
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962920] = {
		id = 1962920,
		group = 99997,
		dispelBuff = {1972616, 2441681, 2441691},
		overlayLimit = 1,
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962921] = {
		id = 1962921,
		easyEffectFunc = 'fieldBuff',
		group = 50001,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_ym.png',
		textResPath = 'battle/txt/txt_ym.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 1962924, ['caster'] = 2, ['value'] = 1000, ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(3))) and 1 or 0', __size = 7}}, {{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 1962918, ['caster'] = 2, ['value'] = 1500, ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(3))) and 1 or 0', __size = 7}}, {{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 1962925, ['caster'] = 2, ['value'] = {2, 99, 1}, ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(3))) and 1 or 0', __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962922, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962929, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962926, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'attrDifferExclude("natureType", {3})', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962927, ['caster'] = 2, ['value'] = '-target:speed()*0.06', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962928, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962922] = {
		id = 1962922,
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'buff/gaioukamega_buff/gaioukamega_changjing.skel',
		effectPos = 3,
		effectAssignLayer = 3,
		effectOffsetPos = {['y'] = 200, ['x'] = 450, __size = 2},
		onceEffectResPath = 'buff/gaioukamega_buff/gaioukamega_changjing.skel',
		onceEffectAniName = 'effect_danru',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962923, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962923] = {
		id = 1962923,
		overlayType = 1,
		overlayLimit = 1,
		effectPos = 3,
		effectAssignLayer = 3,
		effectOffsetPos = {['y'] = 200, ['x'] = 450, __size = 2},
		onceEffectResPath = 'buff/gaioukamega_buff/gaioukamega_changjing.skel',
		onceEffectAniName = 'effect_danchu',
		noDelWhenFakeDeath = 1
	},
	[1962924] = {
		id = 1962924,
		easyEffectFunc = 'waterDamageAdd',
		group = 2005,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_shjc_up.png',
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5021},
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962925] = {
		id = 1962925,
		easyEffectFunc = 'alterDmgRecordVal',
		group = 2005,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['finalRate'] = {'setValue(list("finalDamageAdd"),(exitInTab(processId,list(3003,3651334)) or attacker:curSkill():skillFlag(203,203,211,212) ==true) and list(env:finalDamageAdd()*10000+1500) or  list(env:finalDamageAdd()*10000 ) )'}, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5021},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962926] = {
		id = 1962926,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 61004,
		dispelType = {3, 0, 2},
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {{['input'] = 'selfForce()|nodead', ['process'] = 'exclude(list(csvSelf:id()))|attrDiffer("natureType", {3})', __size = 2}},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['delSelfWhenTriggered'] = 2, ['triggerPoint'] = 1, ['nodeId'] = 0, __size = 3}},
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5021},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962927] = {
		id = 1962927,
		easyEffectFunc = 'speed',
		group = 11081,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_down.png',
		textResPath = 'battle/txt/txt_sdjd.png',
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5021},
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962928] = {
		id = 1962928,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962926, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'attrDifferExclude("natureType", {3})', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962927, ['caster'] = 2, ['value'] = '-target2:speed()*0.06', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962929] = {
		id = 1962929,
		easyEffectFunc = 'weather',
		skillTimePos = 2,
		group = 99998,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 1962920, ['caster'] = 2, __size = 5}}, {{['holder'] = 14, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 1962919, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		lifeTimeEnd = 0,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962930] = {
		id = 1962930,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962931, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962932, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962937, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[1962931] = {
		id = 1962931,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 60027,
		dispelType = {3, 2},
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {11},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 61, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 1, ['cfgId'] = 1962936, ['caster'] = 2, ['value'] = 'target2:hp()*(0.02+fromSkillLevel*0.001-0.001)', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['delSelfWhenTriggered'] = 2, ['triggerPoint'] = 1, ['nodeId'] = 0, __size = 3}}
	},
	[1962932] = {
		id = 1962932,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 60028,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {{['input'] = 'selfForce()|nodead', ['process'] = 'exclude(list(csvSelf:id()))|attrDiffer("natureType", {3})', __size = 2}},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 61, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 1, ['cfgId'] = 1962936, ['caster'] = 2, ['value'] = 'target2:hp()*(0.02+fromSkillLevel*0.001-0.001)', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['delSelfWhenTriggered'] = 2, ['triggerPoint'] = 1, ['nodeId'] = 0, __size = 3}},
		noDelWhenFakeDeath = 1
	},
	[1962933] = {
		id = 1962933,
		overlayType = 1,
		overlayLimit = 1,
		lifeRoundType = 2,
		iconShowType = {1, 10}
	},
	[1962934] = {
		id = 1962934,
		overlayType = 1,
		overlayLimit = 1,
		lifeRoundType = 2,
		iconShowType = {1, 10}
	},
	[1962935] = {
		id = 1962935,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962936, ['caster'] = 2, ['value'] = 'target2:hp()*(0.02+fromSkillLevel*0.001-0.001)', ['prob'] = 'self:hasBuff(1962933) and 0 or 0', __size = 6}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'attrDiffer("natureType", {3})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962936, ['caster'] = 2, ['value'] = 'target2:hp()*(0.02+fromSkillLevel*0.001-0.001)*2', ['prob'] = 'self:hasBuff(1962934) and 0 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		lifeRoundType = 2,
		iconShowType = {1, 10}
	},
	[1962936] = {
		id = 1962936,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao2',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		lifeRoundType = 2,
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[1962937] = {
		id = 1962937,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 60028,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962936, ['caster'] = 2, ['value'] = 'self:hp()*(0.02+fromSkillLevel*0.001-0.001)', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1962940] = {
		id = 1962940,
		overlayLimit = 1,
		triggerPriority = 100,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962941, ['caster'] = 2, ['value'] = 0, ['prob'] = '(getNowRound()%2 ==1) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['onSomeFlag'] = {'trigger.strike'}, ['triggerPoint'] = 40, ['nodeId'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 1962949, ['caster'] = 2, ['value'] = 5000, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}},
		noDelWhenFakeDeath = 1
	},
	[1962941] = {
		id = 1962941,
		easyEffectFunc = 'finalDamageSub',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_ylht.png',
		effectResPath = 'buff/gaioukamega_buff/gaioukamega_buff.skel',
		effectAniName = {'yuanliuhuti_loop'},
		textResPath = 'battle/txt/txt_ylht.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962942, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962943, ['caster'] = 2, ['value'] = 2000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962944, ['caster'] = 2, ['value'] = 2500, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962945, ['caster'] = 2, ['value'] = 5000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962946, ['caster'] = 2, ['value'] = 5000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962947, ['caster'] = 2, ['value'] = 'self:hpMax()*0.08', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962947, ['caster'] = 2, ['value'] = 'self:hpMax()*0.08', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962942] = {
		id = 1962942,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 60000,
		dispelBuff = {2381121, 2351137, 2351138, 1981120, 3631217, 2351160, 1811130, 1811125, 2391148, 2441122, 3243141, 1982120, 1982130, 2461212, 2461213, 1261215, 1271314, 1271315, 1271371, 1271373, 1281230, 1281231, 1281232, 1281233, 1281234, 1281236, 1281311, 1281312, 1281313, 1281314, 1281315, 1281321, 1281322, 1281331, 1281332, 1281623, 1281625, 1961129, 1962115, 1962718, 1962723, 1962719, 1962720, 1962723, 1971212, 1972313, 1981120, 1982130, 1991657, 2351150, 2351151, 2391148, 2391149, 2391150, 2421317, 2421335, 2421622, 2461226, 3611118, 3611160, 3611161, 3611162, 3611163, 3611164, 3611171, 3622311, 3622312, 3622313, 3622314, 3623712, 3623715, 3642311, 3642312, 3642313, 4161021, 4024311, 1963718},
		dispelType = {3, 999, 0, 10},
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_wqjh.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 3, ['value'] = 1, ['cfgId'] = 1962434, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 61, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 1, ['cfgId'] = 1962936, ['caster'] = 2, ['value'] = 'target2:hp()*(0.02+fromSkillLevel*0.001-0.001)', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[1962943] = {
		id = 1962943,
		easyEffectFunc = 'finalDamageSub',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962944] = {
		id = 1962944,
		easyEffectFunc = 'strikeDamageSub',
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962945] = {
		id = 1962945,
		easyEffectFunc = 'immuneControlVal',
		dispelBuff = {1981110, 1982124},
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_kzmy.png',
		specialVal = {70002},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962946] = {
		id = 1962946,
		easyEffectFunc = 'immuneControlVal',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {70022},
		iconShowType = {1, 10}
	},
	[1962947] = {
		id = 1962947,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao2',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[1962948] = {
		id = 1962948,
		easyEffectFunc = 'strikeDamageSub',
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962949] = {
		id = 1962949,
		easyEffectFunc = 'strikeResistance',
		skillTimePos = 2,
		groupPower = 102,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjkx_up.png',
		textResPath = 'battle/txt/txt_bjkxtg.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962950] = {
		id = 1962950,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 1962951, ['caster'] = 2, ['value'] = {0, 'target:hpMax()*0.2', 'self:mp1Max()*1', 21}, ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(3))) and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		iconShowType = {1, 10}
	},
	[1962951] = {
		id = 1962951,
		easyEffectFunc = 'reborn',
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 'self:hpMax()*0.05', ['cfgId'] = 1962954, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 521610, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(521601) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 1962932, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['onSomeFlag'] = {'moreE(self:hp()/self:hpMax(),0.15) and (not self:hasBuff(1962478)) and (not target:hasBuff(1962472))'}, ['triggerPoint'] = 12, ['nodeId'] = 0, __size = 3}},
		gateLimit = {{['limit'] = 1, ['type'] = 1, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962952] = {
		id = 1962952
	},
	[1962953] = {
		id = 1962953,
		easyEffectFunc = 'buff2',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 1962956, ['caster'] = 2, ['value'] = {0, 1, 0, -1}, ['prob'] = '((target2:natureIntersection(list(3))) and self:cardID()==1962) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962954] = {
		id = 1962954,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 10, __size = 1}},
		buffFlag = {4021, 1019},
		iconShowType = {1, 10}
	},
	[1962955] = {
		id = 1962955,
		easyEffectFunc = 'lockMp1Add',
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962962, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962956] = {
		id = 1962956,
		easyEffectFunc = 'reborn',
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['value'] = 0, ['cfgId'] = 1962957, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['onSomeFlag'] = {'(more(getForceNum(self:force()),0) and (getExtraRoundMode()~=7 or getExtraRoundMode()~=8))  or (getExtraRoundMode()==7 or getExtraRoundMode()==8)'}, ['triggerPoint'] = 12, ['nodeId'] = 0, __size = 3}},
		gateLimit = {{['limit'] = 1, ['type'] = 1, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962957] = {
		id = 1962957,
		easyEffectFunc = 'buff10',
		group = 80009,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerTimes'] = {1, 1}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['value'] = 1965, ['cfgId'] = 1962961, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 99, ['value'] = {99, 1}, ['cfgId'] = 1962963, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 99, ['value'] = 0, ['cfgId'] = 1962955, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 3, ['value'] = 0, ['cfgId'] = 1962959, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 3, ['value'] = 0, ['cfgId'] = 1962959, ['caster'] = 1, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962958, ['caster'] = 2, ['value'] = {0, 0, 0, 1, 0, 0}, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 99, ['value'] = 0, ['cfgId'] = 1962960, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 1, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 1019},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962958] = {
		id = 1962958,
		easyEffectFunc = 'depart',
		group = 4204,
		overlayType = 1,
		overlayLimit = 1,
		holderActionType = {['typ'] = 'opacity', __size = 1},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962959] = {
		id = 1962959,
		easyEffectFunc = 'buff2',
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		effectShowOnAttack = true,
		holderActionType = {['typ'] = 'hide', ['args'] = {['other'] = {['isShow'] = false, __size = 1}, ['lifebar'] = {['isShow'] = false, __size = 1}, __size = 2}, __size = 2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962964, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'(lessE(getForceNum(self:force()),1) and (getExtraRoundMode()~=7 or getExtraRoundMode()~=8))'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962964, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 32, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962960] = {
		id = 1962960,
		easyEffectFunc = 'silence',
		skillTimePos = 2,
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0},
		ignoreHolder = 1,
		ignoreCaster = {1},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962961] = {
		id = 1962961,
		easyEffectFunc = 'changeUnit',
		skillTimePos = 2,
		group = 81009,
		dispelBuff = {3304611, 3304621, 3304622},
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_hyzl.png',
		textResPath = 'battle/txt/txt_hyzl.png',
		specialVal = {{false, false, false}, true, true},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962962] = {
		id = 1962962,
		easyEffectFunc = 'kill',
		skillTimePos = 2,
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {true, true},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962963] = {
		id = 1962963,
		easyEffectFunc = 'keepHpUnChanged',
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962964] = {
		id = 1962964,
		easyEffectFunc = 'kill',
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		specialVal = {true, true},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[1962968] = {
		id = 1962968,
		easyEffectFunc = 'strikeResistance',
		skillTimePos = 2,
		group = 1026,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjkx_up.png',
		textResPath = 'battle/txt/txt_bjkxtg.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962969] = {
		id = 1962969,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 60027,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {11},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 61, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 1, ['cfgId'] = 1962936, ['caster'] = 2, ['value'] = 'target2:hp()*(0.02+fromSkillLevel*0.001-0.001)', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['delSelfWhenTriggered'] = 2, ['triggerPoint'] = 1, ['nodeId'] = 0, __size = 3}}
	},
	[1962971] = {
		id = 1962971,
		skillTimePos = 2,
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 1962972, ['caster'] = 2, ['value'] = {1966, 99, 0, 1, 1, {['hpMax'] = 1, ['rebound'] = 0, __size = 2}, 1, {['y'] = 0, ['followMark'] = 2004, ['x'] = 150, ['dealGroup'] = 4, __size = 4}, 1, 0}, ['bond'] = 1, ['prob'] = '(self:cardID()==1961 or self:cardID()==1962) and (not self:flagZ4()) and 1 or 0', __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 1962972, ['caster'] = 2, ['value'] = {1967, 99, 0, 1, 1, {['hpMax'] = 1, ['rebound'] = 0, __size = 2}, 1, {['y'] = 0, ['followMark'] = 2004, ['x'] = 150, ['dealGroup'] = 4, __size = 4}, 1, 0}, ['bond'] = 1, ['prob'] = '((self:cardID()==1961 or self:cardID()==1962) and self:flagZ4()) and 1 or 0', __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 1962976, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 3, ['cfgId'] = 1962982, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1962972] = {
		id = 1962972,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0, 0},
		specialTarget = {2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 1962974, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962975, ['caster'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['value'] = {0.5, 2, 17, 2}, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962973, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1}, ['prob'] = 1, __size = 6}}, {{['holder'] = 20, ['lifeRound'] = 99, ['value'] = 1, ['cfgId'] = 1962978, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1962973] = {
		id = 1962973,
		easyEffectFunc = 'inviteAttack',
		skillTimePos = 2,
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{0, 1, 2}},
		specialTarget = {{['input'] = 'allEx(list(2004))', ['process'] = 'random(6)', __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1
	},
	[1962974] = {
		id = 1962974,
		group = 70006,
		overlayType = 1,
		overlayLimit = 1,
		buffFlag = {9999}
	},
	[1962975] = {
		id = 1962975,
		easyEffectFunc = 'damageAllocate',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[1962976] = {
		id = 1962976,
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 19, ['funcArgs'] = {{{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1962977, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1
	},
	[1962977] = {
		id = 1962977,
		easyEffectFunc = 'kill',
		skillTimePos = 2,
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {true, true},
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962978] = {
		id = 1962978,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {'moreE(trigger.delta,1)'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962979, ['caster'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['value'] = 'self2:mp1()*0.5', ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962980, ['caster'] = 2, ['value'] = '-target2:mp1()*0.5', ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 34, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[1962979] = {
		id = 1962979,
		easyEffectFunc = 'addMp1',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[1962980] = {
		id = 1962980,
		easyEffectFunc = 'addMp1',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[1962981] = {
		id = 1962981,
		easyEffectFunc = 'finalDamageSub',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_ylht.png',
		effectResPath = 'buff/gaioukamega_buff/gaioukamega_buff.skel',
		effectAniName = {'yuanliuhuti_loop'},
		textResPath = 'battle/txt/txt_ylht.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962942, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962943, ['caster'] = 2, ['value'] = 1500, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962944, ['caster'] = 2, ['value'] = 2000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962945, ['caster'] = 2, ['value'] = 5000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962946, ['caster'] = 2, ['value'] = 5000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962947, ['caster'] = 2, ['value'] = 'self:hpMax()*0.08', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962947, ['caster'] = 2, ['value'] = 'self:hpMax()*0.08', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962982] = {
		id = 1962982,
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 19, ['funcArgs'] = {{{['holder'] = {['input'] = 'allEx(list(2004))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1962977, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1962983] = {
		id = 1962983,
		easyEffectFunc = 'finalDamageSub',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_ylht.png',
		effectResPath = 'buff/gaioukamega_buff/gaioukamega_buff.skel',
		effectAniName = {'yuanliuhuti_loop'},
		textResPath = 'battle/txt/txt_ylht.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962942, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962943, ['caster'] = 2, ['value'] = 1500, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962944, ['caster'] = 2, ['value'] = 2000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962945, ['caster'] = 2, ['value'] = 5000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962946, ['caster'] = 2, ['value'] = 5000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962947, ['caster'] = 2, ['value'] = 'self:hpMax()*0.08', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962947, ['caster'] = 2, ['value'] = 'self:hpMax()*0.08', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		gateLimit = {{['limit'] = 2, ['type'] = 1, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962990] = {
		id = 1962990,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'allEx(list(c.shuixizhaohuan_oc()))', __size = 1}, ['lifeRound'] = 1, ['cfgId'] = 1962996, ['caster'] = 2, ['value'] = 1000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = {['input'] = 'allEx(list(c.shuixizhaohuan_oc()))', __size = 1}, ['lifeRound'] = 1, ['cfgId'] = 1962997, ['caster'] = 2, ['value'] = 1000, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 1, ['cfgId'] = 1962998, ['caster'] = 2, ['value'] = 'target2:specialDamage()*0.5', ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 2, __size = 4}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962991] = {
		id = 1962991,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 65009,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 30, ['nodeId'] = 0, __size = 2}}
	},
	[1962992] = {
		id = 1962992,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		group = 60028,
		dispelType = {3, 2},
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {11},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 1241000, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962933, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['delSelfWhenTriggered'] = 2, ['triggerPoint'] = 1, ['nodeId'] = 0, __size = 3}}
	},
	[1962993] = {
		id = 1962993,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_gaiouka/shuiliuhuanrao2',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[1962994] = {
		id = 1962994,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962996, ['caster'] = 2, ['value'] = 3000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962997, ['caster'] = 2, ['value'] = 1000, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = {['input'] = 'holderDamageTargets', ['process'] = 'targetNear()', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962998, ['caster'] = 2, ['value'] = 'target:specialDamage()*0.3', ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 2, __size = 5}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962995] = {
		id = 1962995,
		easyEffectFunc = 'buffSputtering',
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[1962996] = {
		id = 1962996,
		easyEffectFunc = 'strikeResistance',
		skillTimePos = 2,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjkx_up.png',
		textResPath = 'battle/txt/txt_bjkxtg.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1962997] = {
		id = 1962997,
		easyEffectFunc = 'damageSub',
		skillTimePos = 2,
		group = 1025,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjm_up.png',
		textResPath = 'battle/txt/txt_shjmtg.png'
	},
	[1962998] = {
		id = 1962998,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'buff/gaioukamega_buff/gaioukamega_buff.skel',
		onceEffectAniName = 'lianyi',
		specialVal = {{['natureType'] = 3, ['damageType'] = 2, ['processId'] = 3003, __size = 3}},
		lifeRoundType = 4,
		buffFlag = {4003, 4021}
	},
	[1962999] = {
		id = 1962999,
		group = 1961132,
		overlayType = 2,
		overlayLimit = 6
	},
	[1963000] = {
		id = 1963000,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1963001] = {
		id = 1963001,
		skillTimePos = 2,
		group = 81009,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 1962972, ['caster'] = 1, ['value'] = {1966, 99, 0, 1, 1, {['hpMax'] = 1, ['rebound'] = 0, __size = 2}, 1, {['y'] = 0, ['followMark'] = 2004, ['x'] = 150, ['dealGroup'] = 4, __size = 4}, 1, 0}, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 1962976, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 3, ['cfgId'] = 1962982, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1963002] = {
		id = 1963002,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421211, ['caster'] = 1, ['value'] = {2422, 99, 0, 1, 1, {['hpMax'] = 'self2:flagZ2() and 0.8 or 0.6', ['rebound'] = 0, __size = 2}, 1, {['y'] = 0, ['followMark'] = 2001, ['x'] = -150, ['dealGroup'] = 5, __size = 4}, 1, 0}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[1963003] = {
		id = 1963003,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['onSomeFlag'] = {'less(sumBuffOverlayByGroupInForce(self:force(),list(c.undeath_oc()),2421646),1)'}, ['triggerPoint'] = 1, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 3, ['value'] = {2423, 99, 0, 1, 1, {['hpMax'] = 'self2:flagZ4() and 1.5 or 1.2', ['specialDefence'] = 'self2:flagZ4() and 1.5 or 1.2', ['defence'] = 'self2:flagZ4() and 1.5 or 1.2', ['rebound'] = 0, __size = 4}, 1, {['y'] = -40, ['followMark'] = 2002, ['x'] = 190, ['dealGroup'] = 2, __size = 4}, 1, 1}, ['cfgId'] = 2421642, ['caster'] = 1, __size = 5}}}, ['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[1963004] = {
		id = 1963004,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3305222, ['caster'] = 1, ['value'] = {7016, 99, 0, 1.01, 1, {['speed'] = 1, ['initMp1'] = 0, ['mp1Max'] = 1, __size = 3}, 1, {['y'] = 70, ['followMark'] = 2005, ['x'] = 120, ['dealGroup'] = 4, __size = 4}, 1, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[1963005] = {
		id = 1963005,
		overlayType = 2,
		overlayLimit = 99
	},
	[1963006] = {
		id = 1963006,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'(self:getBuffOverlayCount(1963005) == 1) or (self:getBuffOverlayCount(1963005) == 3)'}, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 1, ['cfgId'] = 1963001, ['caster'] = 2, ['value'] = 0, ['prob'] = 'target2:cardID()==1962 and 1 or 0', __size = 6}}, {{['holder'] = 11, ['lifeRound'] = 1, ['cfgId'] = 1963002, ['caster'] = 2, ['value'] = 0, ['prob'] = 'target2:cardID()==2421 and 1 or 0', __size = 6}}, {{['holder'] = 11, ['lifeRound'] = 1, ['cfgId'] = 1963003, ['caster'] = 2, ['value'] = 0, ['prob'] = 'target2:cardID()==2421 and 1 or 0', __size = 6}}, {{['holder'] = 11, ['lifeRound'] = 1, ['cfgId'] = 1963004, ['caster'] = 2, ['value'] = 0, ['prob'] = 'target2:cardID()==7011 and 1 or 0', __size = 6}}, {{['holder'] = 11, ['lifeRound'] = 1, ['cfgId'] = 1963007, ['caster'] = 2, ['value'] = 0, ['prob'] = 'target2:cardID()==7071 and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1963005, ['caster'] = 2, ['value'] = 0, ['prob'] = 0, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1963011, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1}, ['prob'] = 'self:flagZ3() and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1963012, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 1, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1963007] = {
		id = 1963007,
		skillTimePos = 2,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 7071212, ['caster'] = 1, ['value'] = {'target:flag(200) and 7074 or 7072', 99, 0, '(self:flagZ2() and 1 or 1)', 1, {['speed'] = 1, ['initMp1'] = 0, ['mp1Max'] = 1, __size = 3}, 1, {['y'] = -30, ['followMark'] = 16, ['x'] = -210, ['dealGroup'] = 1, __size = 4}, 1, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 7, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 1, ['cfgId'] = 7071216, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999}
	},
	[1963011] = {
		id = 1963011,
		easyEffectFunc = 'inviteAttack',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_qyzs.png',
		specialVal = {{0, 1, 2}},
		specialTarget = {{['input'] = 'selfForceEx(list(c.shuixizhaohuan_oc()))', ['process'] = 'random(99)', __size = 2}},
		lifeTimeEnd = 0
	},
	[1963012] = {
		id = 1963012,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'allEx(list(c.shuixizhaohuan_oc()))', ['process'] = 'random(99)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962994, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1963021] = {
		id = 1963021,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'lessThan(target:hp()/target:hpMax(),0.4)'}, ['triggerPoint'] = 18, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 1962971, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 2, ['value'] = 1500, ['cfgId'] = 1963022, ['caster'] = 2, __size = 5}}}, ['triggerTimes'] = {1, 1}, ['effectFuncs'] = {'castBuff', 'castBuff'}, __size = 6}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1963022] = {
		id = 1963022,
		easyEffectFunc = 'finalDamageSub',
		skillTimePos = 2,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_ylht.png',
		effectResPath = 'buff/gaioukamega_buff/gaioukamega_buff.skel',
		effectAniName = {'yuanliuhuti_loop'},
		textResPath = 'battle/txt/txt_ylht.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962942, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962943, ['caster'] = 2, ['value'] = 1500, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962944, ['caster'] = 2, ['value'] = 2000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962945, ['caster'] = 2, ['value'] = 5000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 1962946, ['caster'] = 2, ['value'] = 5000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962947, ['caster'] = 2, ['value'] = 'self:hpMax()*0.08', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 1962947, ['caster'] = 2, ['value'] = 'self:hpMax()*0.08', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1963139] = {
		id = 1963139,
		group = 1962139,
		overlayType = 2,
		overlayLimit = 10,
		effectPos = 2,
		onceEffectResPath = 'koudai_gaioukamega_pf/gok_buff.skel',
		onceEffectAniName = 'lianyi',
		textResPath = 'battle/txt/txt_ly1.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1963321] = {
		id = 1963321,
		easyEffectFunc = 'finalDamageSub',
		skillTimePos = 2,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_ylht.png',
		effectResPath = 'koudai_gaioukamega_pf/gok_buff.skel',
		effectAniName = {'yuanliuhuti_loop'},
		textResPath = 'battle/txt/txt_ylht.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962224, ['caster'] = 2, ['value'] = 15000, ['bond'] = 1, ['prob'] = 'target:hasBuff(1962121) and 1 or 0', __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962225, ['caster'] = 2, ['value'] = 15000, ['bond'] = 1, ['prob'] = 'target:hasBuff(1962121) and 1 or 0', __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962231, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'target:hasBuff(1962121) and 1 or 0', __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962251, ['caster'] = 2, ['value'] = 0, ['prob'] = 'target:hasBuff(1962121) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962323, ['caster'] = 2, ['value'] = 'target2:hpMax()*0.1', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962326, ['caster'] = 2, ['value'] = 5000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 1962327, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'target:hasBuff(1962121) and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[1963718] = {
		id = 1963718,
		easyEffectFunc = 'freeze',
		group = 1962718,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sl.png',
		effectResPath = 'koudai_gaioukamega_pf/gok_buff.skel',
		effectAniName = {'shuilao_loop'},
		onceEffectResPath = 'buff/gaioukamega_buff/gaioukamega_buff.skel',
		onceEffectAniName = 'shuilao_chuxian',
		holderActionType = {['typ'] = 'pause', __size = 1},
		textResPath = 'battle/txt/txt_sl2.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'near|exclude(list(csvSelf:id()))|buffDifferExclude(\'group\',{c.yinshenplus_fly_oc()})|buffDifferExclude(\'id\',{1962718,1963718})|random(1)', __size = 2}, ['lifeRound'] = 3, ['cfgId'] = 1962722, ['caster'] = 1, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'attrDiffer("natureType", {3})', __size = 2}, ['lifeRound'] = 3, ['cfgId'] = 1962754, ['caster'] = 1, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 1962756, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 1962757, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962759, ['caster'] = 2, ['value'] = 'self:specialDamage()*2', ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 19, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962753, ['caster'] = 2, ['value'] = {'list(381213,641311,641312,177123,2411639,3301124,3681211,3771114,2421317,2421335,2421622,3304131,3304211)', 'list(50001,50002,50003,50005,50014,50021,50022,50030,50034,80016)', 'list(\'controlPerVal\',\'immuneControlVal\')', 'list(\'controlPer\',\'immuneControl\')'}, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'attrDiffer("natureType", {3,4,6})', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 1962752, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962760, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962834, ['caster'] = 2, ['value'] = 0, ['prob'] = '(moreE(self:getBuffOverlayCount(1962835),3) and self:flagZ3()) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 1962833, ['caster'] = 2, ['value'] = 0, ['prob'] = '(less(self:getBuffOverlayCount(1962835),3) and self:flagZ3() and (not target2:hasBuff(1962834))) and 1 or 0', __size = 6}}}, ['nodeId'] = 3, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 10}
	},
	[580011] = {
		id = 580011,
		name = '自然属性触发不满足6人',
		overlayLimit = 1,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3300000] = {
		id = 3300000,
		name = '重复使用buff',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_jinghua.png'
	},
	[3300001] = {
		id = 3300001,
		name = '重复使用buff',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'buff/qusan/qusan.skel',
		onceEffectAniName = 'qusan',
		textResPath = 'battle/txt/txt_qs.png',
		iconShowType = {1, 10}
	},
	[3300002] = {
		id = 3300002,
		name = '重复使用buff',
		easyEffectFunc = 'qusan1',
		group = 60001,
		dispelType = {3, 0, 1},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300003] = {
		id = 3300003,
		name = '重复使用buff',
		easyEffectFunc = 'qusan2',
		group = 60001,
		dispelType = {3, 0, 2},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300004] = {
		id = 3300004,
		name = '重复使用buff',
		easyEffectFunc = 'qusan3',
		group = 60001,
		dispelType = {3, 0, 3},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300005] = {
		id = 3300005,
		name = '重复使用buff',
		easyEffectFunc = 'jinghua1',
		group = 60002,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300006] = {
		id = 3300006,
		name = '重复使用buff',
		easyEffectFunc = 'jinghua2',
		group = 60002,
		dispelType = {3, 2},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300007] = {
		id = 3300007,
		name = '重复使用buff',
		easyEffectFunc = 'jinghua3',
		group = 60002,
		dispelType = {3, 3},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300008] = {
		id = 3300008,
		name = '重复使用buff',
		easyEffectFunc = 'gjqs1',
		group = 60003,
		dispelType = {3, 0, 1},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300009] = {
		id = 3300009,
		name = '重复使用buff',
		easyEffectFunc = 'gjqs2',
		group = 60003,
		dispelType = {3, 0, 2},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300010] = {
		id = 3300010,
		name = '重复使用buff',
		easyEffectFunc = 'gjqs3',
		group = 60003,
		dispelType = {3, 0, 3},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300011] = {
		id = 3300011,
		name = '重复使用buff',
		easyEffectFunc = 'gjjh1',
		group = 60004,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300012] = {
		id = 3300012,
		name = '重复使用buff',
		easyEffectFunc = 'gjjh2',
		group = 60004,
		dispelType = {3, 2},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300013] = {
		id = 3300013,
		name = '重复使用buff',
		easyEffectFunc = 'gjjh3',
		group = 60004,
		dispelType = {3, 3},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300014] = {
		id = 3300014,
		name = '重复使用buff',
		easyEffectFunc = 'jinghua1',
		group = 60027,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300015] = {
		id = 3300015,
		name = '重复使用buff',
		easyEffectFunc = 'jinghua2',
		group = 60027,
		dispelType = {3, 2},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300016] = {
		id = 3300016,
		name = '重复使用buff',
		easyEffectFunc = 'jinghua3',
		group = 60027,
		dispelType = {3, 3},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300017] = {
		id = 3300017,
		name = '重复使用buff',
		easyEffectFunc = 'gjjh1',
		group = 60028,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300018] = {
		id = 3300018,
		name = '重复使用buff',
		easyEffectFunc = 'gjjh2',
		group = 60028,
		dispelType = {3, 2},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300019] = {
		id = 3300019,
		name = '重复使用buff',
		easyEffectFunc = 'gjjh3',
		group = 60028,
		dispelType = {3, 3},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300020] = {
		id = 3300020,
		name = '重复使用buff',
		easyEffectFunc = 'yc',
		group = 60000,
		dispelType = {3, 999, 0, 10},
		overlayType = 1,
		overlayLimit = 1
	},
	[3300051] = {
		id = 3300051,
		name = '重复使用buff',
		easyEffectFunc = 'qusan1',
		group = 60005,
		dispelType = {3, 0, 1},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300052] = {
		id = 3300052,
		name = '重复使用buff',
		easyEffectFunc = 'qusan2',
		group = 60005,
		dispelType = {3, 0, 2},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300053] = {
		id = 3300053,
		name = '重复使用buff',
		easyEffectFunc = 'qusan3',
		group = 60005,
		dispelType = {3, 0, 3},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300054] = {
		id = 3300054,
		name = '重复使用buff',
		easyEffectFunc = 'qusan1',
		group = 60009,
		dispelType = {3, 0, 1},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300055] = {
		id = 3300055,
		name = '重复使用buff',
		easyEffectFunc = 'qusan2',
		group = 60009,
		dispelType = {3, 0, 2},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300056] = {
		id = 3300056,
		name = '重复使用buff',
		easyEffectFunc = 'qusan3',
		group = 60009,
		dispelType = {3, 0, 3},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300057] = {
		id = 3300057,
		name = '重复使用buff',
		easyEffectFunc = 'qusan1',
		group = 60009,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300058] = {
		id = 3300058,
		name = '重复使用buff',
		easyEffectFunc = 'qusan2',
		group = 60009,
		dispelType = {3, 2},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3300059] = {
		id = 3300059,
		name = '重复使用buff',
		easyEffectFunc = 'qusan3',
		group = 60009,
		dispelType = {3, 3},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2421209] = {
		id = 2421209,
		name = '玛纳霏',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421211, ['caster'] = 2, ['value'] = {2427, 99, 0, 1, 1, {['hpMax'] = 'self:flagZ2() and 0.8 or 0.6', ['rebound'] = 0, __size = 2}, 1, {['y'] = 0, ['followMark'] = 2001, ['x'] = -150, ['dealGroup'] = 5, __size = 4}, 1, 0}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2421210] = {
		id = 2421210,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421211, ['caster'] = 2, ['value'] = {2422, 99, 0, 1, 1, {['hpMax'] = 'self:flagZ2() and 0.8 or 0.6', ['rebound'] = 0, __size = 2}, 1, {['y'] = 0, ['followMark'] = 2001, ['x'] = -150, ['dealGroup'] = 5, __size = 4}, 1, 0}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2421211] = {
		id = 2421211,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_zhhcl.png',
		specialVal = {0, 0},
		specialTarget = {2},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421213, ['caster'] = {['input'] = 'allEx(list(2001))', ['process'] = 'selectObjSeat()', __size = 2}, ['value'] = {2, 0, 0, 0.5}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 2, ['cfgId'] = 2421214, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2421212] = {
		id = 2421212,
		easyEffectFunc = 'inviteAttack',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{0, 1, 2}},
		specialTarget = {{['input'] = 'allEx(list(2001))', ['process'] = 'random(6)', __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[2421213] = {
		id = 2421213,
		easyEffectFunc = 'replaceTarget',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[2421214] = {
		id = 2421214,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 2421215, ['caster'] = 1, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2
	},
	[2421215] = {
		id = 2421215,
		easyEffectFunc = 'kill',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {true, true},
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[2421310] = {
		id = 2421310,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		buffFlag = {1019}
	},
	[2421311] = {
		id = 2421311,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'buff/zhiliao/zhiliao.skel',
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[2421312] = {
		id = 2421312,
		skillTimePos = 2,
		group = 5305,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_spp.png',
		effectResPath = 'koudai_manafei/hero_manafei.skel',
		effectAniName = {'paopao_loop'},
		effectOffsetPos = {['y'] = 70, ['x'] = 20, __size = 2},
		textResPath = 'battle/txt/txt_spp.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421313, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421314, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421315, ['caster'] = 2, ['value'] = {2, 99, 1}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421316, ['caster'] = 2, ['value'] = {2, 99, 1}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421317, ['caster'] = 2, ['value'] = 1500, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421318, ['caster'] = 2, ['value'] = {2, 99, 1}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {0, 20}
	},
	[2421313] = {
		id = 2421313,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1
	},
	[2421314] = {
		id = 2421314,
		skillTimePos = 2,
		group = 71009,
		overlayType = 1,
		overlayLimit = 1
	},
	[2421315] = {
		id = 2421315,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['finalRate'] = {'setValue(list("finalDamageSub"),((arg.from==2)) and list(env:finalDamageSub()*10000+5000) or list(env:finalDamageSub()*10000))'}, __size = 1}}
	},
	[2421316] = {
		id = 2421316,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['finalRate'] = {'setValue(list("finalDamageSub"),((arg.from==1) and (exitInTab(arg.buffCfgId, list(3642634,2461317,2461332,1861115,1861124,1861126,2421650))) or exitInTab(arg.buffGroupId, list(c.zhuoshao_oc))) and list(env:finalDamageSub()*10000+5000+(target:flagZ3() and 1000 or 0)) or list(env:finalDamageSub()*10000))'}, __size = 1}}
	},
	[2421317] = {
		id = 2421317,
		easyEffectFunc = 'strikeResistance',
		skillTimePos = 2,
		group = 1026,
		groupPower = 201,
		overlayType = 2,
		overlayLimit = 2,
		iconResPath = 'battle/buff_icon/logo_bjkx_up.png',
		textResPath = 'battle/txt/txt_bjkxtg.png'
	},
	[2421318] = {
		id = 2421318,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['strike'] = {'setValue(list(\'strikeDamage\'), attacker:curSkill():getDamageState(\'strike\')   and list(env:strikeDamage()*10000-1500) or  list(env:strikeDamage()*10000) )'}, __size = 1}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[2421331] = {
		id = 2421331,
		easyEffectFunc = 'fieldBuff',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 2421332, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = '(trigger.obj.force == self:force() and (target2:natureIntersection(list(3)))) and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[2421332] = {
		id = 2421332,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|random(1)', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 2421612, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 2421333, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 2421334, ['caster'] = 2, ['value'] = 1, ['prob'] = 'moreE(self:getBuffOverlayCount(2421333),2) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[2421333] = {
		id = 2421333,
		overlayType = 2,
		overlayLimit = 2
	},
	[2421334] = {
		id = 2421334,
		dispelBuff = {2421331},
		overlayType = 1,
		overlayLimit = 1
	},
	[2421340] = {
		id = 2421340,
		overlayType = 1,
		overlayLimit = 1
	},
	[2421341] = {
		id = 2421341,
		skillTimePos = 2,
		overlayType = 2,
		overlayLimit = 5
	},
	[2421342] = {
		id = 2421342,
		easyEffectFunc = 'secondAttack',
		skillTimePos = 2,
		group = 2421317,
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {{['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_yinshenplus_shuilao_oc()})|buffDiffer(\'id\',{2421340})|random(1)', __size = 2}},
		buffFlag = {1019}
	},
	[2421343] = {
		id = 2421343,
		easyEffectFunc = 'changeImage',
		skillTimePos = 2,
		group = 105,
		overlayType = 1,
		overlayLimit = 1,
		effectShowOnAttack = true,
		onceEffectResPath = 'buff/manafei_buff/houjingwang.skel',
		onceEffectAniName = 'effect1',
		effectOnEnd = {['pos'] = 0, ['aniName'] = 'effect2', ['res'] = 'buff/manafei_buff/houjingwang.skel', __size = 3},
		holderActionType = {['typ'] = 'hide', ['args'] = {['other'] = {['isShow'] = false, __size = 1}, ['lifebar'] = {['isShow'] = false, __size = 1}, __size = 2}, __size = 2},
		deepCorrect = 11,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421344, ['caster'] = 1, ['value'] = {1, 3, 'list(2)'}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['bond'] = 2, ['cfgId'] = 2421345, ['caster'] = 2, ['childBind'] = {1, 1}, ['value'] = 1, ['prob'] = 1, __size = 8}}, {{['holder'] = 1, ['lifeRound'] = 99, ['bond'] = 2, ['cfgId'] = 2421346, ['caster'] = 2, ['childBind'] = {1, 1}, ['value'] = {0, 0, 0, 0, 1, 1}, ['prob'] = 1, __size = 8}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		skinEffect = {[2424] = 2424602, __size = 1}
	},
	[2421344] = {
		id = 2421344,
		easyEffectFunc = 'shiftPos',
		skillTimePos = 2,
		group = 10,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {1},
		triggerBehaviors = {{['triggerPoint'] = 32, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 10}
	},
	[2421345] = {
		id = 2421345,
		skillTimePos = 2,
		group = 2421319,
		overlayType = 1,
		overlayLimit = 1,
		ignoreCaster = {1},
		lifeRoundType = 3
	},
	[2421346] = {
		id = 2421346,
		easyEffectFunc = 'depart',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreCaster = {1}
	},
	[2421361] = {
		id = 2421361,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerTimes'] = {1, 1}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 2421362, ['caster'] = 2, ['value'] = {2423, 99, 0, 1, 1, {['hpMax'] = 1.2, ['specialDefence'] = 1.2, ['defence'] = 1.2, ['rebound'] = 0, __size = 4}, 1, {['y'] = -40, ['followMark'] = 2002, ['x'] = 190, ['dealGroup'] = 2, __size = 4}, 1, 1}, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 6, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[2421362] = {
		id = 2421362,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {2},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421363, ['caster'] = 20, ['value'] = {'0.3+0.002*(skillLv(24216,24246,24376) or 0)-0.002', 2, 17, 2}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 2421364, ['caster'] = 1, ['value'] = {1, 1}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2421363] = {
		id = 2421363,
		easyEffectFunc = 'damageAllocate',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[2421364] = {
		id = 2421364,
		easyEffectFunc = 'transferMp',
		overlayType = 1,
		overlayLimit = 1
	},
	[2421365] = {
		id = 2421365,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[2421611] = {
		id = 2421611,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|random(1)', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 2421612, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[2421612] = {
		id = 2421612,
		group = 18001,
		overlayType = 8,
		overlayLimit = 5,
		iconResPath = 'battle/buff_icon/logo_rdy.png',
		effectResPath = 'buff/manafei_buff/ruodingyu.skel',
		effectAniName = {'buff1_loop', 'buff2_loop', 'buff3_loop', 'buff4_loop', 'standby_loop'},
		effectAniChoose = {['mapping'] = {1, 2, 3, 4, 5}, ['type'] = 1, __size = 2},
		effectOffsetPos = {['y'] = 120, ['x'] = 0, __size = 2},
		textResPath = 'battle/txt/txt_rdy.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421613, ['caster'] = 2, ['value'] = {1, 99, 1}, ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421614, ['caster'] = 2, ['value'] = '-target:Bspeed()*0.03', ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 2421616, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 7, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 2421615, ['caster'] = 1, ['value'] = 1, ['prob'] = '(target:natureIntersection(list(4)) or target:natureIntersection(list(5))) and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 20},
		skinEffect = {[2424] = 2424601, [2437] = 2437601, __size = 2}
	},
	[2421613] = {
		id = 2421613,
		easyEffectFunc = 'alterDmgRecordVal',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['finalRate'] = {'setValue(list("finalDamageSub"),((attacker:hasBuff(2421612) and (target:natureIntersection(list(3)))) and list(env:finalDamageSub()*10000+attacker:getBuffOverlayCount(2421612)*300) or list(env:finalDamageSub()*10000) ))'}, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[2421614] = {
		id = 2421614,
		easyEffectFunc = 'speed',
		overlayType = 8,
		overlayLimit = 4
	},
	[2421615] = {
		id = 2421615,
		group = 68001,
		dispelType = {1, 1, 1},
		overlayType = 1,
		overlayLimit = 1
	},
	[2421616] = {
		id = 2421616,
		overlayType = 1,
		overlayLimit = 1,
		buffFlag = {1019}
	},
	[2421621] = {
		id = 2421621,
		easyEffectFunc = 'fieldBuff',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 2421622, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[2421622] = {
		id = 2421622,
		overlayType = 1,
		overlayLimit = 1,
		triggerPriority = 11,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 2421623, ['caster'] = 2, ['value'] = 1, ['prob'] = 'moreE(sumBuffOverlayByGroupInForce(target2:force(),list(c.undeath_oc()),18001),5)  and 1 or 0', __size = 6}}, {{['holder'] = 14, ['lifeRound'] = 1, ['cfgId'] = 2421636, ['caster'] = 2, ['value'] = 1, ['prob'] = 'moreE(sumBuffOverlayByGroupInForce(self:force() == 1 and 2 or 1,list(c.undeath_oc()),18001),5)  and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 6, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 2421623, ['caster'] = 2, ['value'] = 1, ['prob'] = 'moreE(sumBuffOverlayByGroupInForce(target2:force(),list(c.undeath_oc()),18001),5)  and 1 or 0', __size = 6}}, {{['holder'] = 14, ['lifeRound'] = 1, ['cfgId'] = 2421636, ['caster'] = 2, ['value'] = 1, ['prob'] = 'moreE(sumBuffOverlayByGroupInForce(self:force() == 1 and 2 or 1,list(c.undeath_oc()),18001),5)  and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[2421623] = {
		id = 2421623,
		skillTimePos = 2,
		group = 18002,
		dispelBuff = {2421612},
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_rdyq.png',
		onceEffectResPath = 'buff/manafei_buff/ruodingyu.skel',
		onceEffectAniName = 'buff_huiju',
		textResPath = 'battle/txt/txt_rdyq.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 2421624, ['caster'] = 2, ['value'] = {2425, 'target:id()', 0, 1, 1, {['hpMax'] = 5, ['rebound'] = 0, __size = 2}, 1, {['y'] = 30, ['followMark'] = 3001, ['x'] = 0, ['dealGroup'] = 3, __size = 4}, 1}, ['prob'] = '(self:originUnitId()==2421) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 2421635, ['caster'] = 2, ['value'] = {2430, 'target:id()', 0, 1, 1, {['hpMax'] = 5, ['rebound'] = 0, __size = 2}, 1, {['y'] = -10, ['followMark'] = 3001, ['x'] = 0, ['dealGroup'] = 3, __size = 4}, 1}, ['prob'] = '(self:originUnitId()==2424) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 2421635, ['caster'] = 2, ['value'] = {2434, 'target:id()', 0, 1, 1, {['hpMax'] = 5, ['rebound'] = 0, __size = 2}, 1, {['y'] = -10, ['followMark'] = 3001, ['x'] = 0, ['dealGroup'] = 3, __size = 4}, 1}, ['prob'] = '(self:originUnitId()==2437) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		iconShowType = {0, 20}
	},
	[2421624] = {
		id = 2421624,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = {['input'] = 'selected()', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 2421625, ['caster'] = 2, ['childBind'] = {1, 1}, ['value'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 2421632, ['caster'] = 20, ['childBind'] = {1, 1}, ['value'] = 1, __size = 6}}, {{['holder'] = 20, ['lifeRound'] = 999, ['value'] = 1, ['cfgId'] = 2421633, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2421625] = {
		id = 2421625,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 2421627, ['caster'] = 2, ['value'] = 'self:specialDamage()*2', ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 2421628, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 2421629, ['caster'] = 2, ['value'] = 1500, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 2421630, ['caster'] = 2, ['value'] = '-target:Bspeed()*0.03', ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 2421631, ['caster'] = 2, ['value'] = {1, 99, 1}, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[2421626] = {
		id = 2421626,
		easyEffectFunc = 'kill',
		skillTimePos = 2,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {true, true},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999},
		iconShowType = {1, 10}
	},
	[2421627] = {
		id = 2421627,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 15, ['damageType'] = 2, __size = 2}},
		buffFlag = {4021}
	},
	[2421628] = {
		id = 2421628,
		easyEffectFunc = 'filterFlag',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['allForce'] = {}, ['enemyForce'] = {}, ['selfForce'] = {'all'}, __size = 3}}
	},
	[2421629] = {
		id = 2421629,
		easyEffectFunc = 'natureDamageDeepen',
		skillTimePos = 2,
		group = 10030,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		specialVal = {3}
	},
	[2421630] = {
		id = 2421630,
		easyEffectFunc = 'speed',
		skillTimePos = 2,
		overlayType = 8,
		overlayLimit = 5
	},
	[2421631] = {
		id = 2421631,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['finalRate'] = {'setValue(list("finalDamageSub"),((attacker:hasBuff(2421612) and (target:natureIntersection(list(3)))) and list(env:finalDamageSub()*10000+1500) or list(env:finalDamageSub()*10000) ))'}, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[2421632] = {
		id = 2421632,
		easyEffectFunc = 'sneer',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0, 1, 2},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForceEx(list(3001))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 2421626, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2421633] = {
		id = 2421633,
		skillTimePos = 2,
		group = 80017,
		overlayType = 1,
		overlayLimit = 1,
		holderActionType = {['typ'] = 'hide', ['args'] = {['onlyHideLifebar'] = true, __size = 1}, __size = 2},
		buffFlag = {9999}
	},
	[2421634] = {
		id = 2421634,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		holderActionType = {['typ'] = 'hideEffect', ['args'] = {['process'] = {['isShow'] = false, __size = 1}, __size = 1}, __size = 2},
		buffFlag = {9999}
	},
	[2421635] = {
		id = 2421635,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = {['input'] = 'selected()', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 2421625, ['caster'] = 2, ['childBind'] = {1, 1}, ['value'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 2421632, ['caster'] = 20, ['childBind'] = {1, 1}, ['value'] = 1, __size = 6}}, {{['holder'] = 20, ['lifeRound'] = 999, ['value'] = 1, ['cfgId'] = 2421633, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2421636] = {
		id = 2421636,
		easyEffectFunc = 'qusan',
		skillTimePos = 2,
		dispelBuff = {2421612},
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {14}
	},
	[2421641] = {
		id = 2421641,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {'getNowRound()%3 ==1'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 3, ['cfgId'] = 2421642, ['caster'] = 2, ['value'] = {2423, 99, 0, 1, 1, {['hpMax'] = 'self:flagZ4() and 1.2 or 1', ['specialDefence'] = 'self:flagZ4() and 1.2 or 1', ['defence'] = 'self:flagZ4() and 1.2 or 1', ['rebound'] = 0, __size = 4}, 1, {['y'] = -40, ['followMark'] = 2002, ['x'] = 190, ['dealGroup'] = 2, __size = 4}, 1, 1}, ['prob'] = '((not self:hasBuff(2421650)) and (self:originUnitId()==2421 or self:originUnitId()==2424)) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 3, ['cfgId'] = 2421642, ['caster'] = 2, ['value'] = {2435, 99, 0, 1, 1, {['hpMax'] = 'self:flagZ4() and 1.2 or 1', ['specialDefence'] = 'self:flagZ4() and 1.2 or 1', ['defence'] = 'self:flagZ4() and 1.2 or 1', ['rebound'] = 0, __size = 4}, 1, {['y'] = -40, ['followMark'] = 2002, ['x'] = 190, ['dealGroup'] = 2, __size = 4}, 1, 1}, ['prob'] = '((not self:hasBuff(2421650)) and (self:originUnitId()==2437 )) and 1 or 0', __size = 6}}}, ['triggerPoint'] = 3, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[2421642] = {
		id = 2421642,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {2},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 2421643, ['caster'] = 20, ['value'] = {'0.3+0.002*fromSkillLevel-0.002', 2, 17, 2}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 2421655, ['caster'] = 2, ['childBind'] = {2, 1}, ['value'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 2421656, ['caster'] = 2, ['childBind'] = {1, 1}, ['value'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2421643] = {
		id = 2421643,
		easyEffectFunc = 'damageAllocate',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[2421644] = {
		id = 2421644,
		easyEffectFunc = 'transferMp',
		overlayType = 1,
		overlayLimit = 1
	},
	[2421645] = {
		id = 2421645,
		easyEffectFunc = 'lockHp',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {'(not target:hasBuff(2421652)) and self:hasBuff(2421656)'},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 5, ['bond'] = 1, ['cfgId'] = 2421646, ['caster'] = 2, ['childBind'] = {1, 1}, ['value'] = 1, ['prob'] = 1, __size = 8}}, {{['holder'] = {['input'] = 'allEx(list(2002))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 2, ['cfgId'] = 2421647, ['caster'] = 2, ['childBind'] = {1, 1}, ['value'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = {['input'] = 'allEx(list(2002))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 5, ['cfgId'] = 2421648, ['caster'] = 2, ['childBind'] = {1, 1}, ['value'] = 'target2:getRecordTakeDamage(3)', ['prob'] = 1, __size = 7}}, {{['holder'] = {['input'] = 'allEx(list(2002))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 5, ['cfgId'] = 2421649, ['caster'] = 2, ['childBind'] = {1, 1}, ['value'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		craftTriggerLimit = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[2421646] = {
		id = 2421646,
		easyEffectFunc = 'stun',
		group = 2421646,
		overlayType = 1,
		overlayLimit = 1,
		holderActionType = {['list'] = {{['typ'] = 'hide', ['args'] = {['sprite'] = {['isShow'] = false, __size = 1}, ['lifebar'] = {['isShow'] = false, __size = 1}, ['key'] = 'hide', ['other'] = {['isShow'] = false, __size = 1}, __size = 4}, ['playType'] = 0, __size = 3}}, __size = 1},
		lifeTimeEnd = 0,
		buffFlag = {9999}
	},
	[2421647] = {
		id = 2421647,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 2421650, ['caster'] = {['input'] = 'allEx(list(2002))', ['process'] = 'selectObjSeat()', __size = 2}, ['value'] = {2, 0, 0, 1, 1}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 2421651, ['caster'] = {['input'] = 'allEx(list(2002))', ['process'] = 'selectObjSeat()', __size = 2}, ['value'] = {1, 2, 17, 3}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 13, ['lifeRound'] = 1, ['value'] = 'div(1,getForceNum(self:force() == 1 and 2 or 1),1)*(self2:getRecordTakeDamage(3)-(self2:hasBuff(2421648) and self2:getBuff(2421648):getValue() or 0))', ['cfgId'] = 2421653, ['caster'] = 1, __size = 5}}, {{['holder'] = 13, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 2421652, ['caster'] = 1, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 2421654, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 13, ['lifeRound'] = 1, ['value'] = 'self:flag(99099) and min(div(1,getForceNum(self:force() == 1 and 2 or 1),1)*(self2:getRecordTakeDamage(3)-(self2:hasBuff(2421648) and self2:getBuff(2421648):getValue() or 0)),self:BspecialDamage()*3) or div(1,getForceNum(self:force() == 1 and 2 or 1),1)*(self2:getRecordTakeDamage(3)-(self2:hasBuff(2421648) and self2:getBuff(2421648):getValue() or 0))', ['cfgId'] = 2421653, ['caster'] = 1, __size = 5}}, {{['holder'] = 13, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 2421652, ['caster'] = 1, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 2421654, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 3, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2421648] = {
		id = 2421648,
		overlayType = 1,
		overlayLimit = 1
	},
	[2421649] = {
		id = 2421649,
		easyEffectFunc = 'stun',
		overlayLimit = 1,
		effectShowOnAttack = true,
		holderActionType = {['list'] = {{['typ'] = 'setPositionTo', ['playType'] = 0, __size = 2}}, ['effect'] = {{['typ'] = 'hide', ['revertFrame'] = 1, ['args'] = {['sprite'] = {['isShow'] = false, __size = 1}, ['other'] = {['isShow'] = false, __size = 1}, ['lifebar'] = {['isShow'] = false, __size = 1}, __size = 3}, __size = 3}, {['typ'] = 'onceEffect', ['args'] = {['onceEffectOffsetPos'] = {['y'] = 150, ['x'] = -200, __size = 2}, ['onceEffectAniName'] = 'manafei_effect', ['onceEffectResPath'] = 'koudai_cijiabei/hero_cijiabei.skel', __size = 3}, __size = 2}, {['typ'] = 'wait', ['args'] = {['lifetime'] = 1333.3, __size = 1}, __size = 2}}, __size = 2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		spineEffect = {['action'] = {['attack'] = 'attack', ['skill2'] = 'skill2', ['hit'] = 'hit_bihe', ['run_loop'] = 'standby_loop', ['standby_loop'] = 'manafei_standby_loop', ['skill1'] = 'skill1', ['win_loop'] = 'win_loop', __size = 7}, ['unitRes'] = {'koudai_cijiabei/hero_cijiabei.skel', 'buff/manafei_buff/manafei_pifu2/hero_cijiabei_pf2.skel'}, __size = 2},
		skinEffect = {[2437] = 2437604, __size = 1}
	},
	[2421650] = {
		id = 2421650,
		easyEffectFunc = 'replaceTarget',
		overlayLimit = 1,
		specialVal = {0},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[2421651] = {
		id = 2421651,
		easyEffectFunc = 'damageAllocate',
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[2421652] = {
		id = 2421652,
		overlayLimit = 1
	},
	[2421653] = {
		id = 2421653,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 15, ['damageType'] = 2, __size = 2}},
		ignoreCaster = {1},
		buffFlag = {2002, 4021, 4026}
	},
	[2421654] = {
		id = 2421654,
		skillTimePos = 2,
		dispelBuff = {2421645, 2421646},
		overlayType = 1,
		overlayLimit = 1
	},
	[2421655] = {
		id = 2421655,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[2421656] = {
		id = 2421656,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[2421661] = {
		id = 2421661,
		easyEffectFunc = 'aura',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 2421662, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 2421667, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[2421662] = {
		id = 2421662,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'trigger.beAddBuff:hasFlag(1019)'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 2421663, ['caster'] = 2, ['value'] = 1, ['prob'] = 'less(self:getBuffOverlayCount(2421666),3) and 1 or  0', __size = 6}}}, ['triggerPoint'] = 29, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1
	},
	[2421663] = {
		id = 2421663,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 2421664, ['caster'] = 2, ['value'] = 1, ['prob'] = 'moreE(self:star(),6) and 1 or 0', __size = 6}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|attrDiffer("natureType", {3})|random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 2421665, ['caster'] = 2, ['value'] = 'target2:hpMax()*(0.05+0.0005*(skillLv(24216,24246,24376) or 0)-0.0005)*0.85', ['prob'] = 'moreE(self:star(),6) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 2421666, ['caster'] = 2, ['value'] = 1, ['prob'] = 'moreE(self:star(),6) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[2421664] = {
		id = 2421664,
		skillTimePos = 2,
		group = 60027,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2421665] = {
		id = 2421665,
		easyEffectFunc = 'addHP',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'buff/zhiliao/zhiliao.skel',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031}
	},
	[2421666] = {
		id = 2421666,
		overlayType = 2,
		overlayLimit = 3,
		lifeRoundType = 6,
		noDelWhenFakeDeath = 1
	},
	[2421667] = {
		id = 2421667,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'exitInTab(trigger.obj:followMark(),{c.shuixigensui_oc()})'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 2421663, ['caster'] = 2, ['value'] = 1, ['prob'] = 'less(self:getBuffOverlayCount(2421666),3) and 1 or  0', __size = 6}}}, ['triggerPoint'] = 58, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1
	},
	[2421671] = {
		id = 2421671,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'lessE(target:hp()/target:hpMax(),0.5) and (not self:hasBuff(2421672))'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'random(2)', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 2421209, ['caster'] = 2, ['value'] = 1, ['prob'] = 'self:flagZ2() and  1 or 0', __size = 6}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'random(2)', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 2421210, ['caster'] = 2, ['value'] = 1, ['prob'] = 'self:flagZ2() and  0 or 1', __size = 6}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'attrDiffer("natureType", {3})', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 2421212, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1}, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 2421672, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 18, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1
	},
	[2421672] = {
		id = 2421672,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[2424209] = {
		id = 2424209,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421211, ['caster'] = 2, ['value'] = {2428, 99, 0, 1, 1, {['hpMax'] = 'self:flagZ2() and 0.8 or 0.6', ['rebound'] = 0, __size = 2}, 1, {['y'] = 0, ['followMark'] = 2001, ['x'] = -150, ['dealGroup'] = 5, __size = 4}, 1, 0}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2424210] = {
		id = 2424210,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421211, ['caster'] = 2, ['value'] = {2438, 99, 0, 1, 1, {['hpMax'] = 'self:flagZ2() and 0.8 or 0.6', ['rebound'] = 0, __size = 2}, 1, {['y'] = 0, ['followMark'] = 2001, ['x'] = -150, ['dealGroup'] = 5, __size = 4}, 1, 0}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2424611] = {
		id = 2424611,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[2437111] = {
		id = 2437111,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[2437209] = {
		id = 2437209,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421211, ['caster'] = 2, ['value'] = {2436, 99, 0, 1, 1, {['hpMax'] = 'self:flagZ2() and 0.8 or 0.6', ['rebound'] = 0, __size = 2}, 1, {['y'] = 0, ['followMark'] = 2001, ['x'] = -150, ['dealGroup'] = 5, __size = 4}, 1, 0}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2437210] = {
		id = 2437210,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 2421211, ['caster'] = 2, ['value'] = {2449, 99, 0, 1, 1, {['hpMax'] = 'self:flagZ2() and 0.8 or 0.6', ['rebound'] = 0, __size = 2}, 1, {['y'] = 0, ['followMark'] = 2001, ['x'] = -150, ['dealGroup'] = 5, __size = 4}, 1, 0}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3305010] = {
		id = 3305010,
		name = '小智版甲贺忍蛙',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 'self:hasBuff(3305017) and 3305021 or 3305011', ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[3305011] = {
		id = 3305011,
		name = '小智版甲贺忍蛙',
		overlayType = 2,
		overlayLimit = 6,
		iconResPath = 'battle/buff_icon/logo_sslj3.png',
		triggerBehaviors = {{['onSomeFlag'] = {'not self:hasBuff(3305021)'}, ['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 25, ['lifeRound'] = 1, ['cfgId'] = 3305012, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.8', ['prob'] = 1, __size = 6}}, {{['holder'] = 25, ['lifeRound'] = 1, ['cfgId'] = 3305014, ['caster'] = 2, ['value'] = '-target2:speed()*0.03', ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3305015, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[3305012] = {
		id = 3305012,
		name = '小智版甲贺忍蛙',
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_xiaozhibanjiaherenwa/hero_xiaozhibanjiaherenwa.skel',
		onceEffectAniName = 'shuishoulijian_chuxian',
		onceEffectPos = 2,
		onceEffectOffsetPos = {['y'] = -160, ['x'] = 0, __size = 2},
		textResPath = 'battle/txt/txt_sslj.png',
		specialVal = {{['natureType'] = 3, ['damageType'] = 2, ['processId'] = 3003, __size = 3}},
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 4, ['lifeRound'] = 1, ['cfgId'] = 3305013, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.4', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {4003, 4021}
	},
	[3305013] = {
		id = 3305013,
		name = '小智版甲贺忍蛙',
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['natureType'] = 3, ['damageType'] = 2, ['processId'] = 3003, __size = 3}},
		ignoreCaster = {1},
		buffFlag = {4003, 4021}
	},
	[3305014] = {
		id = 3305014,
		name = '小智版甲贺忍蛙',
		easyEffectFunc = 'speed',
		group = 10081,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_down.png',
		textResPath = 'battle/txt/txt_sdjd.png'
	},
	[3305015] = {
		id = 3305015,
		name = '小智版甲贺忍蛙',
		dispelBuff = {3305011},
		dispelType = {1, 1, 1},
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3305016, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3305017, ['caster'] = 2, ['value'] = 0, ['prob'] = 'moreE(self:getBuffOverlayCount(3305016),5) and (moreE(self:star(),8) and 1 or 0) or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 2, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3305016] = {
		id = 3305016,
		name = '小智版甲贺忍蛙',
		overlayType = 2,
		overlayLimit = 20,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_zs.png'
	},
	[3305017] = {
		id = 3305017,
		name = '小智版甲贺忍蛙',
		dispelBuff = {3305016},
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_rh.png'
	},
	[3305021] = {
		id = 3305021,
		name = '小智版甲贺忍蛙',
		dispelBuff = {3305017},
		overlayType = 2,
		overlayLimit = 6,
		iconResPath = 'battle/buff_icon/logo_sslj2.png',
		triggerBehaviors = {{['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 14, ['lifeRound'] = 1, ['cfgId'] = 3305022, ['caster'] = 2, ['value'] = 'self:specialDamage()*1.2', ['prob'] = 1, __size = 6}}, {{['holder'] = 14, ['lifeRound'] = 1, ['cfgId'] = 3305023, ['caster'] = 2, ['value'] = '-target2:speed()*0.06', ['prob'] = 1, __size = 6}}}, ['delSelfWhenTriggered'] = 1, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		gateLimit = {{['limit'] = 2, ['type'] = 1, __size = 2}},
		noDelWhenFakeDeath = 1,
		spineEffect = {['skin'] = 'pifu', ['unitRes'] = {'koudai_xiaozhibanjiaherenwa/hero_xiaozhibanjiaherenwa.skel'}, __size = 2}
	},
	[3305022] = {
		id = 3305022,
		name = '小智版甲贺忍蛙',
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_xiaozhibanjiaherenwa/hero_xiaozhibanjiaherenwa.skel',
		onceEffectAniName = 'shuishoulijian_chuxian',
		onceEffectPos = 2,
		onceEffectOffsetPos = {['y'] = -160, ['x'] = 0, __size = 2},
		textResPath = 'battle/txt/txt_hjsslj.png',
		specialVal = {{['natureType'] = 3, ['damageType'] = 2, ['processId'] = 3003, __size = 3}},
		ignoreCaster = {1},
		buffFlag = {4003, 4021}
	},
	[3305023] = {
		id = 3305023,
		name = '小智版甲贺忍蛙',
		easyEffectFunc = 'speed',
		group = 10081,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_down.png',
		textResPath = 'battle/txt/txt_sdjd.png'
	},
	[3305111] = {
		id = 3305111,
		name = '小智版甲贺忍蛙',
		easyEffectFunc = 'speed',
		group = 1081,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_up.png',
		textResPath = 'battle/txt/txt_sdtg.png'
	},
	[3305121] = {
		id = 3305121,
		easyEffectFunc = 'speed',
		group = 10081,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_down.png',
		textResPath = 'battle/txt/txt_sdjd.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 6, ['cfgId'] = 3305122, ['caster'] = 2, ['value'] = '-buff:getValue()', ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3305122] = {
		id = 3305122,
		easyEffectFunc = 'speed',
		group = 1081,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_up.png',
		textResPath = 'battle/txt/txt_sdtg.png'
	},
	[3305211] = {
		id = 3305211,
		easyEffectFunc = 'changeSpeedPriority',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_jt.png',
		specialVal = {2}
	},
	[3305220] = {
		id = 3305220,
		overlayType = 2,
		overlayLimit = 20,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_zs.png',
		noDelWhenFakeDeath = 1
	},
	[3305221] = {
		id = 3305221,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 32, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 3305222, ['caster'] = 2, ['value'] = {7016, 99, 0, 1.01, 1, {['speed'] = 1, ['initMp1'] = 0, ['mp1Max'] = 1, __size = 3}, 1, {['y'] = 70, ['followMark'] = 2005, ['x'] = 120, ['dealGroup'] = 4, __size = 4}, 1, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3305222] = {
		id = 3305222,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_syfs.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3305220, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3305223, ['caster'] = 20, ['value'] = {2, 0, 0, 1, 1}, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 3305224, ['caster'] = 2, ['value'] = 0, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3305228, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3305223] = {
		id = 3305223,
		easyEffectFunc = 'replaceTarget',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_syfs.png',
		specialVal = {0},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 7, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 3305227, ['caster'] = 1, ['value'] = {'list(1,0,0)', 1, 1}, ['bond'] = 2, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 20}
	},
	[3305224] = {
		id = 3305224,
		easyEffectFunc = 'finalDamageDeepen',
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_shjm_down.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3305225, ['caster'] = 2, ['value'] = 2500, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3305226, ['caster'] = 2, ['value'] = 0, ['bond'] = 2, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3305010, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3305010, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3305010, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 3305231, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:flagZ4() and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3305229, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3305010, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3305010, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3305010, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 3305231, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:flagZ4() and 1 or 0', __size = 6}}}, ['nodeId'] = 3, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3305225] = {
		id = 3305225,
		easyEffectFunc = 'finalDamageSub',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjm_up.png',
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3305226] = {
		id = 3305226,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 45, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3305227] = {
		id = 3305227,
		easyEffectFunc = 'assistAttack',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {{['input'] = 'enemyForce|nodead', ['process'] = 'frontRowRandom(1)', __size = 2}},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['onSomeFlag'] = {'getExtraRoundId()==3305227'}, ['triggerPoint'] = 8, ['extraAttackTrigger'] = 3, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3305228] = {
		id = 3305228,
		easyEffectFunc = 'jinghua1',
		group = 60027,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3305229] = {
		id = 3305229,
		easyEffectFunc = 'kill',
		skillTimePos = 2,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {true, true},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999},
		iconShowType = {1, 10}
	},
	[3305231] = {
		id = 3305231,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 32, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 3305222, ['caster'] = 2, ['value'] = {7016, 99, 0, 1.01, 1, {['speed'] = 1, ['initMp1'] = 0, ['mp1Max'] = 1, __size = 3}, 1, {['y'] = 70, ['followMark'] = 2005, ['x'] = 120, ['dealGroup'] = 4, __size = 4}, 1, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		gateLimit = {{['limit'] = 1, ['type'] = 1, __size = 2}}
	},
	[3305311] = {
		id = 3305311,
		easyEffectFunc = 'ultimateAdd',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bssh_up.png',
		textResPath = 'battle/txt/txt_bsshtg.png'
	},
	[3305321] = {
		id = 3305321,
		easyEffectFunc = 'assistAttack',
		skillTimePos = 2,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_pljhz.png',
		specialTarget = {{['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_yinshenplus_oc()})|random(1)', __size = 2}},
		lifeTimeEnd = 0,
		gateLimit = {{['limit'] = 1, ['type'] = 1, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[3305322] = {
		id = 3305322,
		easyEffectFunc = 'assistAttack',
		skillTimePos = 2,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_pljhz.png',
		specialTarget = {{['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_yinshenplus_oc()})|random(1)', __size = 2}},
		lifeTimeEnd = 0,
		gateLimit = {{['limit'] = 1, ['type'] = 1, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[3305323] = {
		id = 3305323,
		easyEffectFunc = 'assistAttack',
		skillTimePos = 2,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_pljhz.png',
		specialTarget = {{['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_yinshenplus_oc()})|random(1)', __size = 2}},
		lifeTimeEnd = 0,
		gateLimit = {{['limit'] = 1, ['type'] = 1, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[3305325] = {
		id = 3305325,
		easyEffectFunc = 'jinghua1',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3305341] = {
		id = 3305341,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_xiaozhibanjiaherenwa/hero_xiaozhibanjiaherenwa.skel',
		onceEffectAniName = 'win',
		onceEffectPos = 5,
		onceEffectOffsetPos = {['y'] = 0, ['x'] = 100, __size = 2},
		holderActionType = {['list'] = {{['typ'] = 'wait', ['args'] = {['lifetime'] = 1000, __size = 1}, ['playType'] = 1, __size = 3}}, __size = 1},
		textResPath = 'battle/txt/txt_sylx.png',
		triggerBehaviors = {{['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_egg_yinshenplus_oc()})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3305346, ['caster'] = 2, ['value'] = 'self:specialDamage()*(80+skillLv(33043) *0.15-0.15)*0.01', ['prob'] = 1, __size = 6}}}, ['delSelfWhenTriggered'] = 1, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3305342] = {
		id = 3305342,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_xiaozhibanjiaherenwa/hero_xiaozhibanjiaherenwa.skel',
		onceEffectAniName = 'win',
		onceEffectDelay = 100,
		onceEffectPos = 5,
		onceEffectOffsetPos = {['y'] = -350, ['x'] = 340, __size = 2},
		triggerBehaviors = {{['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_egg_yinshenplus_oc()})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3305348, ['caster'] = 2, ['value'] = 'self:specialDamage()*(80+skillLv(33043) *0.15-0.15)*0.01', ['prob'] = 1, __size = 6}}}, ['delSelfWhenTriggered'] = 1, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3305343] = {
		id = 3305343,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_xiaozhibanjiaherenwa/hero_xiaozhibanjiaherenwa.skel',
		onceEffectAniName = 'win',
		onceEffectDelay = 200,
		onceEffectPos = 5,
		onceEffectOffsetPos = {['y'] = 280, ['x'] = 380, __size = 2},
		triggerBehaviors = {{['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_egg_yinshenplus_oc()})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3305347, ['caster'] = 2, ['value'] = 'self:specialDamage()*(80+skillLv(33043) *0.15-0.15)*0.01', ['prob'] = 1, __size = 6}}}, ['delSelfWhenTriggered'] = 1, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3305344] = {
		id = 3305344,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_xiaozhibanjiaherenwa/hero_xiaozhibanjiaherenwa.skel',
		onceEffectAniName = 'win',
		onceEffectDelay = 300,
		onceEffectPos = 5,
		onceEffectOffsetPos = {['y'] = -200, ['x'] = 640, __size = 2},
		triggerBehaviors = {{['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_egg_yinshenplus_oc()})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3305349, ['caster'] = 2, ['value'] = 'self:specialDamage()*(80+skillLv(33043) *0.15-0.15)*0.01', ['prob'] = 1, __size = 6}}}, ['delSelfWhenTriggered'] = 1, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3305345] = {
		id = 3305345,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_xiaozhibanjiaherenwa/hero_xiaozhibanjiaherenwa.skel',
		onceEffectAniName = 'win',
		onceEffectDelay = 460,
		onceEffectPos = 5,
		onceEffectOffsetPos = {['y'] = 130, ['x'] = 680, __size = 2},
		triggerBehaviors = {{['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_egg_yinshenplus_oc()})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3305350, ['caster'] = 2, ['value'] = 'self:specialDamage()*(80+skillLv(33043) *0.15-0.15)*0.01', ['prob'] = 1, __size = 6}}}, ['delSelfWhenTriggered'] = 1, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3305346] = {
		id = 3305346,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_xiaozhibanjiaherenwa/hero_xiaozhibanjiaherenwa.skel',
		onceEffectAniName = 'attack2',
		onceEffectPos = 2,
		onceEffectOffsetPos = {['y'] = -120, ['x'] = 280, __size = 2},
		onceEffectWait = true,
		specialVal = {{['natureType'] = 3, ['damageType'] = 1, ['processId'] = 23, __size = 3}},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {4021}
	},
	[3305347] = {
		id = 3305347,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_xiaozhibanjiaherenwa/hero_xiaozhibanjiaherenwa.skel',
		onceEffectAniName = 'attack2',
		onceEffectDelay = 100,
		onceEffectPos = 2,
		onceEffectOffsetPos = {['y'] = -120, ['x'] = 290, __size = 2},
		onceEffectWait = true,
		specialVal = {{['natureType'] = 3, ['damageType'] = 1, ['processId'] = 23, __size = 3}},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {4021}
	},
	[3305348] = {
		id = 3305348,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_xiaozhibanjiaherenwa/hero_xiaozhibanjiaherenwa.skel',
		onceEffectAniName = 'attack2',
		onceEffectDelay = 200,
		onceEffectPos = 2,
		onceEffectOffsetPos = {['y'] = -120, ['x'] = 300, __size = 2},
		onceEffectWait = true,
		specialVal = {{['natureType'] = 3, ['damageType'] = 1, ['processId'] = 23, __size = 3}},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {4021}
	},
	[3305349] = {
		id = 3305349,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_xiaozhibanjiaherenwa/hero_xiaozhibanjiaherenwa.skel',
		onceEffectAniName = 'attack2',
		onceEffectDelay = 300,
		onceEffectPos = 2,
		onceEffectOffsetPos = {['y'] = -120, ['x'] = 310, __size = 2},
		onceEffectWait = true,
		specialVal = {{['natureType'] = 3, ['damageType'] = 1, ['processId'] = 23, __size = 3}},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {4021}
	},
	[3305350] = {
		id = 3305350,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_xiaozhibanjiaherenwa/hero_xiaozhibanjiaherenwa.skel',
		onceEffectAniName = 'attack2',
		onceEffectDelay = 400,
		onceEffectPos = 2,
		onceEffectOffsetPos = {['y'] = -120, ['x'] = 320, __size = 2},
		onceEffectWait = true,
		specialVal = {{['natureType'] = 3, ['damageType'] = 1, ['processId'] = 23, __size = 3}},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {4021}
	},
	[3305361] = {
		id = 3305361,
		skillTimePos = 2,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 14, ['lifeRound'] = 1, ['cfgId'] = 3305022, ['caster'] = 2, ['value'] = 'self:specialDamage()*1.2', ['prob'] = 1, __size = 6}}, {{['holder'] = 14, ['lifeRound'] = 1, ['cfgId'] = 3305023, ['caster'] = 2, ['value'] = '-target2:speed()*0.06', ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3305015, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3305362, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(3305011) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		gateLimit = {{['limit'] = 1, ['type'] = 1, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3305362] = {
		id = 3305362,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3305012, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.8', ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3305014, ['caster'] = 2, ['value'] = '-target2:speed()*0.03', ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3305015, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[3305611] = {
		id = 3305611,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 999, ['cfgId'] = 3305612, ['caster'] = 2, ['value'] = '-target2:Bspeed()*0.01', ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[3305612] = {
		id = 3305612,
		easyEffectFunc = 'speed',
		group = 10081,
		groupPower = 102,
		overlayType = 8,
		overlayLimit = 99,
		iconResPath = 'battle/buff_icon/logo_sd_down.png',
		textResPath = 'battle/txt/txt_sdjd.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['value'] = 'self:BspecialDamage()*0.01', ['cfgId'] = 3305613, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3305613] = {
		id = 3305613,
		easyEffectFunc = 'specialDamage',
		group = 1002,
		groupPower = 102,
		overlayType = 8,
		overlayLimit = 10,
		iconResPath = 'battle/buff_icon/logo_tg_up.png',
		textResPath = 'battle/txt/txt_tgtg.png'
	},
	[3305621] = {
		id = 3305621,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 7, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3305622, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}, {['onSomeFlag'] = {'moreE(self:getBuffOverlayCount(3305622),3)'}, ['triggerPoint'] = 8, ['nodeId'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3305221, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3305623, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[3305622] = {
		id = 3305622,
		overlayType = 2,
		overlayLimit = 20,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_qyzs.png'
	},
	[3305623] = {
		id = 3305623,
		dispelBuff = {3305622},
		overlayType = 1,
		overlayLimit = 1
	},
	[3305645] = {
		id = 3305645,
		overlayType = 1,
		overlayLimit = 1,
		spineEffect = {['skin'] = 'pifu', ['unitRes'] = {'koudai_xiaozhibanjiaherenwa/hero_xiaozhibanjiaherenwa.skel'}, __size = 2}
	},
	[550281] = {
		id = 550281,
		name = '体系补充buff',
		easyEffectFunc = 'buff2',
		overlayLimit = 1,
		triggerPriority = 20,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 7, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 1, ['cfgId'] = 550282, ['caster'] = 2, ['value'] = 0, ['prob'] = 'target2:hasBuffGroup(c.debuff1_oc()) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[550282] = {
		id = 550282,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 550283, ['caster'] = 2, ['value'] = '(15+(skillLv(55028)-1)*1.5)*100', ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 3, ['cfgId'] = 550284, ['caster'] = 2, ['value'] = 'self:speed()*(0.1+((skillLv(55028) or 0)-1)*0.01)', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		heldItemID = {30418}
	},
	[550283] = {
		id = 550283,
		name = '体系补充buff',
		easyEffectFunc = 'finalDamageAdd',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_shtg.png',
		lifeRoundType = 2
	},
	[550284] = {
		id = 550284,
		name = '体系补充buff',
		easyEffectFunc = 'speed',
		overlayType = 2,
		overlayLimit = 2,
		iconResPath = 'battle/buff_icon/logo_sd_up.png',
		textResPath = 'battle/txt/txt_sdtg.png',
		iconShowType = {1, 10}
	},
	[550291] = {
		id = 550291,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 550292, ['caster'] = 2, ['value'] = '(20+(skillLv(55029)-1)*3)*0.01+((self:id() == target2:id()) and 0.15 or 0)', ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[550292] = {
		id = 550292,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 32, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 550298, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 550294, ['caster'] = 2, ['value'] = {24}, ['bond'] = 1, ['prob'] = 'buff:getValue()-(self:hasBuff(550297) and 0.1 or 0)', __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		iconShowType = {1, 10}
	},
	[550294] = {
		id = 550294,
		name = '体系补充buff',
		easyEffectFunc = 'immuneDamage',
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_mysh.png',
		specialVal = {'attacker:curSkill():getSkillType2() == 2 and attacker:curSkill():isSpellTo() and (not self:hasBuffGroup(c.egg_oc())) and not(attacker:getExAttackMode()==5)'},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 550297, ['caster'] = 2, ['value'] = 'trigger.triggerTime', ['prob'] = 'trigger.triggerTime == 1 and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 550296, ['caster'] = 2, ['value'] = 'trigger.triggerTime', ['prob'] = 'trigger.triggerTime == 1 and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['onSomeFlag'] = {'less(self:getBuffOverlayCount(550297),2) and less(target:getBuffOverlayCount(550296),1)'}, ['triggerPoint'] = 1, ['nodeId'] = 0, __size = 3}},
		gateLimit = {{['limit'] = 1, ['type'] = 1, ['scenes'] = {10, 14}, __size = 3}},
		buffFlag = {2010}
	},
	[550296] = {
		id = 550296,
		name = '体系补充buff',
		overlayType = 2,
		overlayLimit = 99,
		textResPath = 'battle/txt/txt_mysh.png',
		noDelWhenFakeDeath = 1,
		heldItemID = {30419}
	},
	[550297] = {
		id = 550297,
		name = '体系补充buff',
		overlayType = 2,
		overlayLimit = 99,
		noDelWhenFakeDeath = 1
	},
	[550298] = {
		id = 550298,
		name = '体系补充buff',
		dispelBuff = {550293, 550294},
		overlayType = 1,
		overlayLimit = 1
	},
	[550301] = {
		id = 550301,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['onSomeFlag'] = {'trigger.strike'}, ['triggerPoint'] = 40, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 550302, ['caster'] = 2, __size = 5}}}, ['extraAttackTrigger'] = 1, ['effectFuncs'] = {'castBuff'}, __size = 6}},
		noDelWhenFakeDeath = 1
	},
	[550302] = {
		id = 550302,
		name = '体系补充buff',
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'near', __size = 2}, ['lifeRound'] = 1, ['value'] = 'target:id()==target2:id() and (1300+(skillLv(55030)-1)*150) or (1300+(skillLv(55030)-1)*150)*0.6', ['cfgId'] = 550303, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}}
	},
	[550303] = {
		id = 550303,
		name = '体系补充buff',
		easyEffectFunc = 'damageSub',
		overlayType = 6,
		overlayLimit = 2,
		iconResPath = 'battle/buff_icon/logo_shjm_up.png',
		textResPath = 'battle/txt/txt_shjmtg.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		heldItemID = {30420}
	},
	[550304] = {
		id = 550304,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 10, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 550305, ['caster'] = 2, __size = 5}}}, ['extraAttackTrigger'] = 1, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1
	},
	[550305] = {
		id = 550305,
		name = '体系补充buff',
		dispelBuff = {550302},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[550310] = {
		id = 550310,
		name = '体系补充buff',
		overlayLimit = 1,
		deepCorrect = 40,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'self:isBeControlled()'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['value'] = 1, ['cfgId'] = 550315, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 5, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[550311] = {
		id = 550311,
		name = '体系补充buff',
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 25, ['lifeRound'] = 1, ['value'] = '(1+self:getBuffOverlayCount(550313))*(self:specialDamage()+self:damage())*(0.2+(skillLv(55031)-1)*0.025)', ['cfgId'] = 550312, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 550316, ['caster'] = 25, ['value'] = 'self2:getMomentBuffDamage(550312)', ['prob'] = 'self:hasBuff(550313) and 1  or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 550318, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 550314, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'self:hasBuff(550315)'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['value'] = 1, ['cfgId'] = 550313, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 99, ['value'] = 1, ['cfgId'] = 550319, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 550321, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 6, ['nodeId'] = 2, __size = 5}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[550312] = {
		id = 550312,
		name = '体系补充buff',
		easyEffectFunc = 'buffDamage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 15, ['damageType'] = 2, __size = 2}},
		buffFlag = {4021},
		iconShowType = {1, 10}
	},
	[550313] = {
		id = 550313,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[550314] = {
		id = 550314,
		name = '体系补充buff',
		dispelBuff = {550313},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[550315] = {
		id = 550315,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1
	},
	[550316] = {
		id = 550316,
		name = '体系补充buff',
		easyEffectFunc = 'addHpMax',
		groupPower = 206,
		overlayType = 8,
		overlayLimit = 5,
		iconResPath = 'battle/buff_icon/logo_smsx_up.png',
		textResPath = 'battle/txt/txt_smsxtg.png',
		specialVal = {{['effectHp'] = true, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[550318] = {
		id = 550318,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[550319] = {
		id = 550319,
		name = '体系补充buff',
		group = 50030,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tkmj.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 550320, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[550320] = {
		id = 550320,
		name = '体系补充buff',
		dispelBuff = {550319},
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_mykz.png',
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[550321] = {
		id = 550321,
		name = '体系补充buff',
		dispelBuff = {550315},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		heldItemID = {30421}
	},
	[550331] = {
		id = 550331,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSkillType'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 550336, ['caster'] = 2, ['value'] = 1, ['prob'] = '(1.2-0.2*self:getBuffOverlayCount(550333))', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 550334, ['caster'] = 2, ['value'] = '(2000+(skillLv(55033)-1)*200)', ['prob'] = 'not self:hasBuff(550336) and 1 or 0', __size = 6}}}, ['triggerPoint'] = 7, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['onSkillType'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 550332, ['caster'] = 2, ['value'] = 1, ['prob'] = 'self:hasBuff(550336) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['value'] = 'self:hasBuff(550336) and 1 or 0', ['cfgId'] = 550333, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 'self:speed()*(0.08+(skillLv(55033)-1)*0.01)', ['cfgId'] = 550335, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 8, ['nodeId'] = 2, __size = 5}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[550332] = {
		id = 550332,
		name = '体系补充buff',
		easyEffectFunc = 'updSkillSpellRoundOnce',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		heldItemID = {30423},
		iconShowType = {1, 10}
	},
	[550333] = {
		id = 550333,
		name = '体系补充buff',
		overlayType = 2,
		overlayLimit = 4,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[550334] = {
		id = 550334,
		name = '体系补充buff',
		easyEffectFunc = 'damageAdd',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjc_up.png',
		textResPath = 'battle/txt/txt_shtg.png',
		iconShowType = {1, 10}
	},
	[550335] = {
		id = 550335,
		name = '体系补充buff',
		easyEffectFunc = 'speed',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_up.png',
		textResPath = 'battle/txt/txt_sdtg.png',
		iconShowType = {1, 10}
	},
	[550336] = {
		id = 550336,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1
	},
	[550341] = {
		id = 550341,
		name = '体系补充buff',
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'exclude(list(csvSelf:id()))', __size = 2}, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 550345, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 32, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 550347, ['caster'] = 2, ['value'] = 0, ['prob'] = '(getObjInAttackerArrayId(self:id(),0) == 1 and 1 or 0)', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 550348, ['caster'] = 2, ['value'] = 0, ['prob'] = 'moreE(getObjInAttackerArrayId(self:id(),0) or 0, getForceNum(self:force())) and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 32, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = '1600+(skillLv(55034)-1)*150+500*(self:hasBuff(550347) and 1 or 0)-200*self:getBuffOverlayCount(550346)', ['cfgId'] = 550342, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = '400+(skillLv(55034)-1)*100+500*(self:hasBuff(550348) and 1 or 0)+200*self:getBuffOverlayCount(550346)', ['cfgId'] = 550343, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 550344, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 3, __size = 4}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[550342] = {
		id = 550342,
		name = '体系补充buff',
		easyEffectFunc = 'damageAdd',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjc_up.png',
		textResPath = 'battle/txt/txt_shtg.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['triggerPoint'] = 5, ['buffValueUpdatePoint'] = 5, ['nodeId'] = 0, __size = 3}},
		lifeRoundType = 3,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[550343] = {
		id = 550343,
		name = '体系补充buff',
		easyEffectFunc = 'damageSub',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjm_up.png',
		textResPath = 'battle/txt/txt_shjmtg.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['triggerPoint'] = 5, ['buffValueUpdatePoint'] = 5, ['nodeId'] = 0, __size = 3}},
		lifeRoundType = 3,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[550344] = {
		id = 550344,
		name = '体系补充buff',
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		heldItemID = {30424},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[550345] = {
		id = 550345,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 3, ['value'] = 0, ['cfgId'] = 550346, ['caster'] = 1, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 3,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[550346] = {
		id = 550346,
		name = '体系补充buff',
		overlayType = 2,
		overlayLimit = 5,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 3,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[550347] = {
		id = 550347,
		name = '体系补充buff',
		dispelBuff = {550346},
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[550348] = {
		id = 550348,
		name = '体系补充buff',
		dispelBuff = {550346},
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[561111] = {
		id = 561111,
		name = '体系补充buff',
		easyEffectFunc = 'defence',
		skillTimePos = 2,
		group = 1021,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_up.png',
		textResPath = 'battle/txt/txt_wftg.png'
	},
	[561112] = {
		id = 561112,
		name = '体系补充buff',
		easyEffectFunc = 'specialDefence',
		skillTimePos = 2,
		group = 1022,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_up.png',
		textResPath = 'battle/txt/txt_tftg.png'
	},
	[561113] = {
		id = 561113,
		name = '体系补充buff',
		easyEffectFunc = 'shield',
		skillTimePos = 2,
		group = 9001,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_hd.png',
		effectResPath = 'buff/hudun/hudun.skel',
		effectAniName = {'hudun_loop'},
		textResPath = 'battle/txt/txt_pmhd.png',
		specialVal = {0, 0, 10, {3, 0, 0.3}},
		iconShowType = {1, 10}
	},
	[561114] = {
		id = 561114,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_pz.png',
		effectResPath = 'koudai_moqiangrenou/hero_moqiangrenou.skel',
		effectAniName = {'pingzhang_loop'},
		effectOffsetPos = {['y'] = 0, ['x'] = 200, __size = 2},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 14, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 561116, ['caster'] = 2, ['value'] = {1}, ['prob'] = 0.3, __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 10, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['value'] = 0, ['cfgId'] = 561115, ['caster'] = 2, __size = 5}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 2, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 561117, ['caster'] = 2, ['value'] = '(self:specialDefence()+ self:defence())*0.6', ['prob'] = 'to10(moreEqualThan(self:star(),11))', __size = 6}}}, ['nodeId'] = 3, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 561126, ['caster'] = 2, ['value'] = 'self:flagZ3() and 1000 or 500', ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 4, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 20}
	},
	[561115] = {
		id = 561115,
		name = '体系补充buff',
		dispelBuff = {561116},
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[561116] = {
		id = 561116,
		name = '体系补充buff',
		easyEffectFunc = 'immuneDamage',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_moqiangrenou/hero_moqiangrenou.skel',
		onceEffectAniName = 'pingzhang_bierenyong',
		onceEffectOffsetPos = {['y'] = 0, ['x'] = 200, __size = 2},
		noDelWhenFakeDeath = 1,
		buffFlag = {2010}
	},
	[561117] = {
		id = 561117,
		name = '体系补充buff',
		easyEffectFunc = 'shield',
		skillTimePos = 2,
		group = 9001,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_hd.png',
		effectResPath = 'buff/hudun/hudun.skel',
		effectAniName = {'hudun_loop'},
		textResPath = 'battle/txt/txt_pmhd.png',
		specialVal = {0, 0, 10, {3, 0, 0.3}},
		iconShowType = {1, 10}
	},
	[561118] = {
		id = 561118,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 14, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 561120, ['caster'] = 2, ['value'] = {1}, ['prob'] = 'moreE(self:star(),6) and 0.3 or 0', __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 10, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['value'] = 0, ['cfgId'] = 561119, ['caster'] = 2, __size = 5}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[561119] = {
		id = 561119,
		name = '体系补充buff',
		dispelBuff = {561120},
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[561120] = {
		id = 561120,
		name = '体系补充buff',
		easyEffectFunc = 'immuneDamage',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_moqiangrenou/hero_moqiangrenou.skel',
		onceEffectAniName = 'pingzhang_bierenyong',
		onceEffectOffsetPos = {['y'] = 0, ['x'] = 200, __size = 2},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 561124, ['caster'] = 2, ['value'] = 'self:Bdefence()*(0.02+fromSkillLevel*0.0001-0.0001)', ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 561125, ['caster'] = 2, ['value'] = 'self:BspecialDefence()*(0.02+fromSkillLevel*0.0001-0.0001)', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 561127, ['caster'] = 2, ['value'] = {2, 99, 1}, ['prob'] = 'self:flagZ4() and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {2010}
	},
	[561121] = {
		id = 561121,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 561122, ['caster'] = 2, ['value'] = '((target2:natureIntersection(list(11)) ) or (target2:natureIntersection(list(18)) ))  and self:Bdefence()*0.2 or self:Bdefence()*0.1', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 561123, ['caster'] = 2, ['value'] = '((target2:natureIntersection(list(11)) ) or (target2:natureIntersection(list(18)) ))  and self:BspecialDefence()*0.2 or self:BspecialDefence()*0.1', ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 32, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 561122, ['caster'] = 2, ['value'] = '((target2:natureIntersection(list(11)) ) or (target2:natureIntersection(list(18))  ))  and self:Bdefence()*0.2 or self:Bdefence()*0.1', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 561123, ['caster'] = 2, ['value'] = '((target2:natureIntersection(list(11)) ) or (target2:natureIntersection(list(18)) ))  and self:BspecialDefence()*0.2 or self:BspecialDefence()*0.1', ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 2, __size = 4}}
	},
	[561122] = {
		id = 561122,
		name = '体系补充buff',
		easyEffectFunc = 'defence',
		skillTimePos = 2,
		group = 1021,
		groupPower = 102,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_up.png',
		textResPath = 'battle/txt/txt_wftg.png'
	},
	[561123] = {
		id = 561123,
		name = '体系补充buff',
		easyEffectFunc = 'specialDefence',
		skillTimePos = 2,
		group = 1022,
		groupPower = 102,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_up.png',
		textResPath = 'battle/txt/txt_tftg.png'
	},
	[561124] = {
		id = 561124,
		name = '体系补充buff',
		easyEffectFunc = 'defence',
		skillTimePos = 2,
		group = 1021,
		groupPower = 102,
		overlayType = 8,
		overlayLimit = 10,
		iconResPath = 'battle/buff_icon/logo_wf_up.png',
		textResPath = 'battle/txt/txt_wftg.png'
	},
	[561125] = {
		id = 561125,
		name = '体系补充buff',
		easyEffectFunc = 'specialDefence',
		skillTimePos = 2,
		group = 1022,
		groupPower = 102,
		overlayType = 8,
		overlayLimit = 10,
		iconResPath = 'battle/buff_icon/logo_tf_up.png',
		textResPath = 'battle/txt/txt_tftg.png'
	},
	[561126] = {
		id = 561126,
		name = '体系补充buff',
		easyEffectFunc = 'damageSub',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjm_up.png',
		textResPath = 'battle/txt/txt_shjmtg.png'
	},
	[561127] = {
		id = 561127,
		name = '体系补充buff',
		easyEffectFunc = 'alterDmgRecordVal',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['finalRate'] = {'setValue(list("finalDamageSub"),((arg.from==1)) and list(env:finalDamageSub()*10000+5000) or list(env:finalDamageSub()*10000))'}, __size = 1}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1
	},
	[574175] = {
		id = 574175,
		name = '体系补充buff',
		skillTimePos = 2,
		overlayType = 2,
		overlayLimit = 3,
		lifeRoundType = 2
	},
	[600001] = {
		id = 600001,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 13, ['lifeRound'] = 999, ['value'] = 1, ['cfgId'] = 600002, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}}
	},
	[600002] = {
		id = 600002,
		name = '体系补充buff',
		easyEffectFunc = 'directWin',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600101] = {
		id = 600101,
		name = '体系补充buff',
		easyEffectFunc = 'damageDodge',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/icon_sbts.png',
		textResPath = 'battle/txt/txt_sbts.png',
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600102] = {
		id = 600102,
		name = '体系补充buff',
		easyEffectFunc = 'strike',
		group = 1006,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjl_up.png',
		textResPath = 'battle/txt/txt_bjltg.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[600103] = {
		id = 600103,
		name = '体系补充buff',
		easyEffectFunc = 'block',
		group = 1028,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_dyl_up.png',
		textResPath = 'battle/txt/txt_dyltg.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[600201] = {
		id = 600201,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 13, ['lifeRound'] = 999, ['cfgId'] = 600202, ['caster'] = 2, ['value'] = 1, ['prob'] = 'more(countForceNum(self:force()),0) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[600202] = {
		id = 600202,
		name = '体系补充buff',
		easyEffectFunc = 'directWin',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600203] = {
		id = 600203,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 999, ['cfgId'] = 600202, ['caster'] = 2, ['value'] = 1, ['prob'] = 'more(countForceNum(self:force()),0) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[600204] = {
		id = 600204,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 32, ['funcArgs'] = {{{['holder'] = 13, ['lifeRound'] = 999, ['cfgId'] = 600202, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[600301] = {
		id = 600301,
		name = '体系补充buff',
		easyEffectFunc = 'stun',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bd.png',
		effectResPath = 'buff/bingdong/bingdong.skel',
		effectAniName = {'bingdong_loop'},
		effectOnEnd = {['pos'] = 0, ['aniName'] = 'bingdong_end', ['res'] = 'buff/bingdong/bingdong.skel', __size = 3},
		holderActionType = {['typ'] = 'pause', __size = 1},
		deepCorrect = 11,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600302] = {
		id = 600302,
		name = '体系补充buff',
		easyEffectFunc = 'immuneDamage',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600303] = {
		id = 600303,
		name = '体系补充buff',
		easyEffectFunc = 'stun',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 0, ['cfgId'] = 600306, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 0, ['cfgId'] = 600306, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 0, ['cfgId'] = 600306, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 10, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 600305, ['caster'] = 2, __size = 5}}, {{['holder'] = 13, ['lifeRound'] = 1, ['cfgId'] = 600304, ['caster'] = 2, ['value'] = 1, ['prob'] = '(self:getBuffOverlayCount(600306)==0) and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 6, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 600304, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 3, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[600304] = {
		id = 600304,
		name = '体系补充buff',
		easyEffectFunc = 'directWin',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600305] = {
		id = 600305,
		name = '体系补充buff',
		dispelBuff = {600306},
		dispelType = {1, 1, 1},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600306] = {
		id = 600306,
		name = '体系补充buff',
		overlayType = 2,
		overlayLimit = 3,
		iconResPath = 'battle/buff_icon/logo_xglq.png',
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600307] = {
		id = 600307,
		name = '体系补充buff',
		easyEffectFunc = 'addMp1',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_nqtg.png',
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600401] = {
		id = 600401,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 13, ['lifeRound'] = 999, ['cfgId'] = 600402, ['caster'] = 16, ['value'] = 2, ['prob'] = 'self2:hasBuff(600403) and 0 or 1', __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[600402] = {
		id = 600402,
		name = '体系补充buff',
		easyEffectFunc = 'directWin',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600403] = {
		id = 600403,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600501] = {
		id = 600501,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 600502, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[600502] = {
		id = 600502,
		name = '体系补充buff',
		easyEffectFunc = 'stun',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600503] = {
		id = 600503,
		name = '体系补充buff',
		easyEffectFunc = 'strike',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjl_up.png',
		textResPath = 'battle/txt/txt_bjltg.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[600601] = {
		id = 600601,
		name = '体系补充buff',
		easyEffectFunc = 'stun',
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'buff/bingdong/bingdong.skel',
		effectAniName = {'bingdong_loop'},
		effectOnEnd = {['pos'] = 0, ['aniName'] = 'bingdong_end', ['res'] = 'buff/bingdong/bingdong.skel', __size = 3},
		holderActionType = {['typ'] = 'pause', __size = 1},
		deepCorrect = 11,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 10, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 600604, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 600606, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:getBuffOverlayCount(600603)==0 and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 13, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 600607, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[600602] = {
		id = 600602,
		name = '体系补充buff',
		easyEffectFunc = 'immuneDamage',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600603] = {
		id = 600603,
		name = '体系补充buff',
		overlayType = 2,
		overlayLimit = 99,
		iconResPath = 'battle/buff_icon/logo_hl2.png',
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600604] = {
		id = 600604,
		name = '体系补充buff',
		dispelBuff = {600603},
		dispelType = {1, 1, 1},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600605] = {
		id = 600605,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600606] = {
		id = 600606,
		name = '体系补充buff',
		easyEffectFunc = 'kill',
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		specialVal = {true, true},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600607] = {
		id = 600607,
		name = '体系补充buff',
		easyEffectFunc = 'atOnceBattleRound',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[600608] = {
		id = 600608,
		name = '体系补充buff',
		easyEffectFunc = 'replaceSkill',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600700] = {
		id = 600700,
		name = '体系补充buff',
		easyEffectFunc = 'aura',
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {11},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 600701, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[600701] = {
		id = 600701,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 25, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['value'] = 0, ['cfgId'] = 600702, ['caster'] = 2, __size = 5}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 42, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['value'] = {0, 'self:hpMax()', 1000, 0, 99}, ['cfgId'] = 600704, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[600702] = {
		id = 600702,
		name = '体系补充buff',
		group = 600702,
		overlayType = 6,
		overlayLimit = 99,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 600703, ['caster'] = 2, ['value'] = 1, ['prob'] = 'moreE(target:getBuffOverlayCount(600702),50) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[600703] = {
		id = 600703,
		name = '体系补充buff',
		easyEffectFunc = 'directWin',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[600704] = {
		id = 600704,
		name = '体系补充buff',
		easyEffectFunc = 'reborn',
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeTimeEnd = 0,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[600801] = {
		id = 600801,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 13, ['lifeRound'] = 999, ['cfgId'] = 600803, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[600802] = {
		id = 600802,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 13, ['lifeRound'] = 999, ['cfgId'] = 600803, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[600803] = {
		id = 600803,
		name = '体系补充buff',
		easyEffectFunc = 'directWin',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600804] = {
		id = 600804,
		name = '体系补充buff',
		easyEffectFunc = 'shield',
		skillTimePos = 2,
		group = 9001,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_hd.png',
		effectResPath = 'buff/hudun/hudun.skel',
		effectAniName = {'hudun_loop'},
		textResPath = 'battle/txt/txt_hd.png',
		specialVal = {0, 0, 10, {3, 0, 0.3}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[600805] = {
		id = 600805,
		name = '体系补充buff',
		easyEffectFunc = 'addMp1',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_nqtg.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[600806] = {
		id = 600806,
		name = '体系补充buff',
		easyEffectFunc = 'strikeDamage',
		skillTimePos = 2,
		group = 1007,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjsh_up.png',
		textResPath = 'battle/txt/txt_bjshtg.png',
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600807] = {
		id = 600807,
		name = '体系补充buff',
		skillTimePos = 2,
		dispelBuff = {2491616},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[600808] = {
		id = 600808,
		name = '体系补充buff',
		easyEffectFunc = 'reborn',
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 600810, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 26, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 600810, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 12, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[600809] = {
		id = 600809,
		name = '体系补充buff',
		group = 80008,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_fh.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2},
		spineEffect = {['skin'] = 'yuannian', ['unitRes'] = {'koudai_zhuguangling/hero_zhuguangling.skel', 'koudai_denghuoyouling/hero_denghuoyouling.skel', 'koudai_shuijingdenghuoling/hero_shuijingdenghuoling.skel'}, __size = 2}
	},
	[600810] = {
		id = 600810,
		name = '体系补充buff',
		easyEffectFunc = 'stun',
		skillTimePos = 2,
		group = 101,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_xy.png',
		effectResPath = 'buff/xuanyun/xuanyun.skel',
		effectAniName = {'xuanyun_loop'},
		effectPos = 1,
		effectOffsetPos = {['y'] = -320, ['x'] = 0, __size = 2},
		textResPath = 'battle/txt/txt_xy.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[600811] = {
		id = 600811,
		name = '体系补充buff',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 42, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'buffDifferExclude(\'id\',{600802})', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 600808, ['caster'] = 2, ['value'] = {0, 'self:hpMax()', 0, 99, 99}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[603111] = {
		id = 603111,
		name = '体系补充buff',
		easyEffectFunc = 'specialDamageAdd',
		group = 1004,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tg_up.png',
		textResPath = 'battle/txt/txt_tstg.png'
	},
	[603112] = {
		id = 603112,
		name = '体系补充buff',
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		group = 10101,
		overlayType = 2,
		overlayLimit = 5,
		iconResPath = 'battle/buff_icon/logo_zs.png',
		effectResPath = 'buff/zhuoshao/zhuoshao.skel',
		effectAniName = {'zhuoshao_loop_top'},
		textResPath = 'battle/txt/txt_zs1.png',
		specialVal = {{['natureType'] = 2, ['damageType'] = 1, ['processId'] = 3, __size = 3}},
		triggerBehaviors = {{['triggerPoint'] = 5, ['nodeId'] = 0, __size = 2}}
	},
	[603113] = {
		id = 603113,
		name = '体系补充buff',
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 3, ['damageType'] = 1, __size = 2}},
		buffFlag = {4021},
		iconShowType = {1, 10}
	},
	[603114] = {
		id = 603114,
		name = '体系补充buff',
		skillTimePos = 2,
		group = 60013,
		overlayType = 1,
		overlayLimit = 1
	},
	[603121] = {
		id = 603121,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		iconShowType = {1, 10}
	},
	[603122] = {
		id = 603122,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 7, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'id\',{603121})|buffDifferExclude(\'group\',{c.fly_oc()})|rowfront|random(1)', __size = 2}, ['lifeRound'] = 2, ['cfgId'] = 603112, ['caster'] = 8, ['value'] = 'self:specialDamage()*0.4', ['prob'] = 'self2:hasBuffGroup(c.zhuoshao_oc()) and (self:flagZ2() and 0 or 1) or 0', __size = 6}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'id\',{603121})|buffDifferExclude(\'group\',{c.fly_oc()})|rowfront|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 603125, ['caster'] = 8, ['value'] = 0, ['prob'] = 'self2:hasBuffGroup(c.zhuoshao_oc()) and (self:flagZ2() and 1 or 0) or 0', __size = 6}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'id\',{603121,603125})|buffDifferExclude(\'group\',{c.fly_oc()})|rowfront|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 603125, ['caster'] = 8, ['value'] = 0, ['prob'] = 'self2:hasBuffGroup(c.zhuoshao_oc()) and (self:flagZ2() and 1 or 0) or 0', __size = 6}}, {{['holder'] = 8, ['lifeRound'] = 1, ['cfgId'] = 603123, ['caster'] = 2, ['value'] = '(target2:sumBuffLifeRoundByGroup(c.zhuoshao_oc())*target2:sumBuffOverlayByGroup(c.zhuoshao_oc())*0.4+(0.6+0.002*skillLevel-0.002))*1.5*self:specialDamage()', ['prob'] = 'target2:hasBuffGroup(c.zhuoshao_oc()) and 1 or 0', __size = 6}}, {{['holder'] = 8, ['lifeRound'] = 1, ['cfgId'] = 603124, ['caster'] = 2, ['value'] = 0, ['prob'] = 'target2:hasBuffGroup(c.zhuoshao_oc()) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		iconShowType = {1, 10}
	},
	[603123] = {
		id = 603123,
		name = '体系补充buff',
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 3, ['damageType'] = 1, __size = 2}},
		buffFlag = {4021},
		iconShowType = {1, 10}
	},
	[603124] = {
		id = 603124,
		name = '体系补充buff',
		skillTimePos = 2,
		group = 60013,
		overlayType = 1,
		overlayLimit = 1
	},
	[603125] = {
		id = 603125,
		name = '体系补充buff',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 603112, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.4', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		iconShowType = {1, 10}
	},
	[603131] = {
		id = 603131,
		name = '体系补充buff',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 603132, ['caster'] = 2, ['value'] = '(target:hasBuff(603132) and target:getBuff(603132):getValue() or 0)+(target:sumBuffLifeRoundByGroup(c.zhuoshao_oc())*target:sumBuffOverlayByGroup(c.zhuoshao_oc())*0.4+(0.6+0.002*skillLevel-0.002))', ['prob'] = 'target:hasBuffGroup(c.zhuoshao_oc()) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 603135, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.4', ['prob'] = 'target:hasBuffGroup(c.zhuoshao_oc()) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 19, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 'self:specialDamage()*target:getBuff(603132):getValue()*(2+(moreE(self:star(),11) and 0.5 or 0)+(self:flagZ3() and 0.5 or 0))', ['cfgId'] = 603133, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 603134, ['caster'] = 2, ['value'] = 0, ['prob'] = 'target:hasBuffGroup(c.zhuoshao_oc()) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 603112, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.4', ['prob'] = 'self:flagZ3() and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}},
		lifeRoundType = 2,
		iconShowType = {1, 10}
	},
	[603132] = {
		id = 603132,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		lifeRoundType = 2
	},
	[603133] = {
		id = 603133,
		name = '体系补充buff',
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 3, ['damageType'] = 1, __size = 2}},
		buffFlag = {4021},
		iconShowType = {1, 10}
	},
	[603134] = {
		id = 603134,
		name = '体系补充buff',
		skillTimePos = 2,
		group = 60013,
		overlayType = 1,
		overlayLimit = 1
	},
	[603135] = {
		id = 603135,
		name = '体系补充buff',
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 3, ['damageType'] = 1, __size = 2}},
		buffFlag = {4021},
		iconShowType = {1, 10}
	},
	[603141] = {
		id = 603141,
		name = '体系补充buff',
		group = 70019,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_mybd.png'
	},
	[603142] = {
		id = 603142,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 9, ['funcArgs'] = {{{['holder'] = 7, ['lifeRound'] = 1, ['cfgId'] = 603112, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.4', ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 603143, ['caster'] = 7, ['value'] = 'self:hpMax()*(0.05+0.0005*skillLevel-0.0005)', ['prob'] = '(self2:natureIntersection(list(6))) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		iconShowType = {1, 10}
	},
	[603143] = {
		id = 603143,
		name = '体系补充buff',
		easyEffectFunc = 'addHP',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'buff/zhiliao/zhiliao.skel',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[603151] = {
		id = 603151,
		name = '体系补充buff',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'rowfront|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 603112, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.4', ['prob'] = 'self:flagZ4() and 0 or 1', __size = 6}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'rowfront|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 603152, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.6', ['prob'] = 'self:flagZ4() and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		iconShowType = {1, 10}
	},
	[603152] = {
		id = 603152,
		name = '体系补充buff',
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		group = 10102,
		overlayType = 2,
		overlayLimit = 5,
		iconResPath = 'battle/buff_icon/logo_zs.png',
		effectResPath = 'buff/zhuoshao/zhuoshao.skel',
		effectAniName = {'zhuoshao_loop_top'},
		textResPath = 'battle/txt/txt_zs1.png',
		specialVal = {{['natureType'] = 2, ['damageType'] = 1, ['processId'] = 3, __size = 3}},
		triggerBehaviors = {{['triggerPoint'] = 5, ['nodeId'] = 0, __size = 2}}
	},
	[603161] = {
		id = 603161,
		name = '体系补充buff',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {'moreE(countObjByFlag(self:force(),591),1)'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'battleFlagDiffer(\'battleFlag\', {591})|random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 603162, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 603163, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 1, ['nodeId'] = 1, __size = 5}},
		lifeRoundType = 4
	},
	[603162] = {
		id = 603162,
		name = '体系补充buff',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 603164, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 603167, ['caster'] = 2, ['value'] = 'target:Bspeed()*0.06', ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 603168, ['caster'] = 2, ['value'] = 1500, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 592162, ['caster'] = 2, ['value'] = 1, ['prob'] = 'target:flagZ4() and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 603165, ['caster'] = 2, ['value'] = 'self:Bdamage()*0.04', ['prob'] = 'lessE(getNowRound(),5) and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['onSomeFlag'] = {'target:flagZ4()'}, ['triggerPoint'] = 7, ['nodeId'] = 3, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 603174, ['caster'] = 2, ['value'] = 'self:specialDamage()*1.5', ['prob'] = 1, __size = 6}}}, ['effectFuncs'] = {'castBuff'}, ['onSkillType'] = 1, __size = 6}},
		iconShowType = {1, 10}
	},
	[603163] = {
		id = 603163,
		name = '体系补充buff',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 603164, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 603171, ['caster'] = 2, ['value'] = 150, ['prob'] = 'self:flagZ4() and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 603167, ['caster'] = 2, ['value'] = 'target:Bspeed()*0.06', ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 603168, ['caster'] = 2, ['value'] = 1500, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 603166, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.04', ['prob'] = 'lessE(getNowRound(),5) and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSkillType'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 603172, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:flagZ4() and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 603173, ['caster'] = 2, ['value'] = 'self:specialDamage()*1.5', ['prob'] = 'self:flagZ4() and 1 or 0', __size = 6}}}, ['triggerPoint'] = 7, ['nodeId'] = 3, __size = 5}},
		iconShowType = {1, 10}
	},
	[603164] = {
		id = 603164,
		name = '体系补充buff',
		group = 70018,
		overlayType = 1,
		overlayLimit = 1,
		deepCorrect = 9,
		noDelWhenFakeDeath = 1
	},
	[603165] = {
		id = 603165,
		name = '体系补充buff',
		easyEffectFunc = 'damage',
		group = 1001,
		overlayType = 2,
		overlayLimit = 5,
		iconResPath = 'battle/buff_icon/logo_wg_up.png',
		textResPath = 'battle/txt/txt_wgtg.png'
	},
	[603166] = {
		id = 603166,
		name = '体系补充buff',
		easyEffectFunc = 'specialDamage',
		group = 1002,
		overlayType = 2,
		overlayLimit = 5,
		iconResPath = 'battle/buff_icon/logo_tg_up.png',
		textResPath = 'battle/txt/txt_tgtg.png'
	},
	[603167] = {
		id = 603167,
		name = '体系补充buff',
		easyEffectFunc = 'speed',
		group = 1081,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_up.png',
		textResPath = 'battle/txt/txt_sdtg.png'
	},
	[603168] = {
		id = 603168,
		name = '体系补充buff',
		easyEffectFunc = 'damageSub',
		group = 3025,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjm_up.png',
		textResPath = 'battle/txt/txt_shjmtg.png',
		iconShowType = {1, 10}
	},
	[603171] = {
		id = 603171,
		name = '体系补充buff',
		easyEffectFunc = 'addMp1',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_nqtg.png',
		iconShowType = {1, 10}
	},
	[603172] = {
		id = 603172,
		name = '体系补充buff',
		overlayType = 2,
		overlayLimit = 6
	},
	[603173] = {
		id = 603173,
		name = '体系补充buff',
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['natureType'] = 5, ['damageType'] = 2, ['processId'] = 3005, __size = 3}},
		buffFlag = {4005},
		iconShowType = {1, 10}
	},
	[603174] = {
		id = 603174,
		name = '体系补充buff',
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['natureType'] = 2, ['damageType'] = 2, ['processId'] = 3002, __size = 3}},
		buffFlag = {4002},
		iconShowType = {1, 10}
	},
	[7071121] = {
		id = 7071121,
		name = '凯路迪欧觉悟',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'holderDamageTargets', ['process'] = 'targetNear()', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 7071124, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.45', ['prob'] = 'moreE(self:getBuffOverlayCount(7071122),3) and 1 or 0', __size = 6}}, {{['holder'] = 25, ['lifeRound'] = 1, ['cfgId'] = 7071131, ['caster'] = 2, ['value'] = 0, ['prob'] = 'moreE(self:getBuffOverlayCount(7071122),3) and (self:flagZ1() and 1 or 0) or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071125, ['caster'] = 2, ['value'] = 0, ['prob'] = 'moreE(self:getBuffOverlayCount(7071122),3) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7071122, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSkillType'] = 3, __size = 6}, {['onSomeFlag'] = {'moreE(self:getBuffOverlayCount(7071122),3)'}, ['triggerPoint'] = 5, ['nodeId'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 7071123, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[7071122] = {
		id = 7071122,
		overlayType = 2,
		overlayLimit = 99,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_byzs.png',
		noDelWhenFakeDeath = 1
	},
	[7071123] = {
		id = 7071123,
		overlayType = 1,
		overlayLimit = 1,
		lifeRoundType = 4,
		spineEffect = {['action'] = {['attack'] = 'attack2', __size = 1}, ['unitRes'] = {'koudai_kailudiou_juewuxingtai/hero_kailudiou_juewuxingtai.skel', 'koudai_kailudiou_juewu_pifu/hero_kailudiou_juewu_pifu.skel'}, __size = 2}
	},
	[7071124] = {
		id = 7071124,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'buff/gaioukamega_buff/gaioukamega_buff.skel',
		onceEffectAniName = 'lianyi',
		specialVal = {{['natureType'] = 3, ['damageType'] = 2, ['processId'] = 3003, __size = 3}},
		lifeRoundType = 4,
		buffFlag = {4003, 4021}
	},
	[7071125] = {
		id = 7071125,
		dispelBuff = {7071122},
		overlayType = 1,
		overlayLimit = 1,
		lifeRoundType = 4
	},
	[7071131] = {
		id = 7071131,
		easyEffectFunc = 'jinghua1',
		group = 65004,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071612, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 4
	},
	[7071211] = {
		id = 7071211,
		skillTimePos = 2,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 7071212, ['caster'] = 1, ['value'] = {'self:flag(200) and 7074 or 7072', 99, 0, '(self:flagZ2() and 1 or 1)', 1, {['speed'] = 1, ['initMp1'] = 0, ['mp1Max'] = 1, __size = 3}, 1, {['y'] = -30, ['followMark'] = 16, ['x'] = -210, ['dealGroup'] = 1, __size = 4}, 1, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 7, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 1, ['cfgId'] = 7071216, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999}
	},
	[7071212] = {
		id = 7071212,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		overlayLimit = 1,
		specialVal = {1, 0},
		specialTarget = {{['input'] = 'myself', ['process'] = 'random(1)', __size = 2}, {['input'] = 'enemyForce|nodead', ['process'] = 'mirrorPosOptional(csvSelectObj:id())|selfRowOptional()|buffDifferExcludeOptional(\'id\',{7071213})|random(1)', __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 20, ['cfgId'] = 7071213, ['caster'] = 20, ['value'] = 0, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 1, ['cfgId'] = 7071215, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1, 'list()', 1}, ['prob'] = 0, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 6,
		noDelWhenFakeDeath = 1
	},
	[7071213] = {
		id = 7071213,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_rh.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7071214, ['caster'] = 1, ['value'] = 0, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7071217, ['caster'] = 2, ['value'] = {'self:flagZ2() and 0.35 or 0.25', 2, 19, 100}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 7, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 1, ['cfgId'] = 7071216, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071215, ['caster'] = 1, ['value'] = {'list(1,0,0)', 1, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 3, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071218, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 4, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071218, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 5, __size = 4}, {['onSomeFlag'] = {'exitInTab(trigger.beAddBuff:getGroup(),list(c.kongzhi1_kongzhi2_oc()))'}, ['triggerPoint'] = 29, ['nodeId'] = 6, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071219, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerTimes'] = {1, 1}, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[7071214] = {
		id = 7071214,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		holderActionType = {['list'] = {{['typ'] = 'hide', ['args'] = {['sprite'] = {['isShow'] = false, __size = 1}, ['other'] = {['isShow'] = false, __size = 1}, ['lifebar'] = {['isShow'] = false, __size = 1}, __size = 3}, ['playType'] = 1, __size = 3}, {['typ'] = 'onceEffect', ['args'] = {['onceEffectOffsetPos'] = {['y'] = 150, ['x'] = 0, __size = 2}, ['onceEffectAniName'] = 'chuxian', ['onceEffectResPath'] = 'koudai_kailudiou_juewuxingtai/hero_kailudiou_buff.skel', __size = 3}, ['playType'] = 1, __size = 3}, {['typ'] = 'wait', ['args'] = {['lifetime'] = 590, __size = 1}, ['playType'] = 1, __size = 3}, {['typ'] = 'hide', ['args'] = {['sprite'] = {['isShow'] = true, __size = 1}, ['other'] = {['isShow'] = true, __size = 1}, ['lifebar'] = {['isShow'] = true, __size = 1}, __size = 3}, ['playType'] = 1, __size = 3}, {['typ'] = 'opacity', ['args'] = {['value'] = 0.7, __size = 1}, ['playType'] = 1, __size = 3}}, __size = 1},
		textResPath = 'battle/txt/txt_lbjs.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 5, ['lifeRound'] = 999, ['cfgId'] = 7071223, ['caster'] = 1, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7071230, ['caster'] = 1, ['value'] = {{7031314}}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7071225, ['caster'] = 1, ['value'] = {0, 99, 2, 0.35, 10}, ['bond'] = 1, ['prob'] = 'self:flagZ2() and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071218, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuf', 'castBuff'}, ['onSomeFlag'] = {'self:flagZ2()'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071612, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071612, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 13, ['nodeId'] = 3, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		spineEffect = {['action'] = {['death'] = 'xiaoshi', __size = 1}, ['unitRes'] = {'koudai_kailudiou_juewuxingtai/hero_kailudiou_buff.skel', 'koudai_kailudiou_juewu_pifu/hero_kailudiou_pifu_buff.skel'}, __size = 2},
		skinEffect = {[7073] = 7071214, __size = 1}
	},
	[7071215] = {
		id = 7071215,
		easyEffectFunc = 'assistAttack',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_xz1.png',
		specialTarget = {{['input'] = 'object(csvSelectObj:id())', ['process'] = 'random(1)', __size = 2}},
		buffFlag = {3009, 1023}
	},
	[7071216] = {
		id = 7071216,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_qyzs.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 4
	},
	[7071217] = {
		id = 7071217,
		easyEffectFunc = 'damageAllocate',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[7071218] = {
		id = 7071218,
		easyEffectFunc = 'kill',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {true, true},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[7071219] = {
		id = 7071219,
		easyEffectFunc = 'gjjh1',
		group = 60028,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071612, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 4
	},
	[7071223] = {
		id = 7071223,
		group = 1030001,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_rh.png',
		triggerBehaviors = {{['onSomeFlag'] = {'exitInTab(getExtraRoundId(),list(c.lianji_oc()))'}, ['triggerPoint'] = 7, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071224, ['caster'] = 2, ['value'] = 0.15, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 3, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071224] = {
		id = 7071224,
		easyEffectFunc = 'damageRateAdd',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_shtg.png',
		lifeRoundType = 4
	},
	[7071225] = {
		id = 7071225,
		easyEffectFunc = 'lockHp',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[7071230] = {
		id = 7071230,
		easyEffectFunc = 'ignoreSpecBuff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[7071241] = {
		id = 7071241,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce() | nodead', ['process'] = 'exclude(list(csvSelf:id()))|buffDifferExclude(\'id\',{7071619})|targetAnd("attrDiffer",{"natureType", {3,7}},"battleFlagDiffer",{\'battleFlag\',{10006}})|setSelectAttr({"damage","specialDamage"},"max")|attr("selectAttr","max",1)', __size = 2}, ['lifeRound'] = 2, ['cfgId'] = 7071211, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999}
	},
	[7071310] = {
		id = 7071310,
		skillTimePos = 2,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 10, ['cfgId'] = 'target:flag(10006)  and 7071311 or 7071321', ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[7071311] = {
		id = 7071311,
		skillTimePos = 2,
		group = 3309,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/icon_lz.png',
		textResPath = 'battle/txt/txt_lianzhan.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 5, ['cfgId'] = 7071312, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 10, ['cfgId'] = 7071316, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'self:flagZ3() and 1 or 0', __size = 7}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[7071312] = {
		id = 7071312,
		easyEffectFunc = 'assistAttack',
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {{['input'] = 'selectObjectMainTarget', ['process'] = 'random(1)', __size = 2}},
		triggerBehaviors = {{['onSomeFlag'] = {'getExtraRoundId()==7071312'}, ['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 1, ['cfgId'] = 7071313, ['caster'] = 2, ['value'] = 'min(target2:hp()*0.05,self:specialDamage()*1.5)', ['prob'] = 'target:hasBuff(7071311) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071314, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 3, ['effectFuncs'] = {'castBuff', 'castBuff'}, __size = 6}, {['onSomeFlag'] = {'getExtraRoundId()==7071312'}, ['triggerPoint'] = 7, ['nodeId'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071315, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 3, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {1022}
	},
	[7071313] = {
		id = 7071313,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 15, ['damageType'] = 2, __size = 2}},
		buffFlag = {2007, 4021}
	},
	[7071314] = {
		id = 7071314,
		skillTimePos = 2,
		dispelBuff = {7071311, 7071321},
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[7071315] = {
		id = 7071315,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_lianji.png'
	},
	[7071316] = {
		id = 7071316,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['onSomeFlag'] = {'exitInTab(getExtraRoundId(),list(c.lianji_oc()))'}, ['triggerPoint'] = 7, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 6, ['cfgId'] = 'randomChoice(7071632,7071633,7071634)', ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 8, ['lifeRound'] = 2, ['cfgId'] = 7071649, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 3, ['effectFuncs'] = {'castBuff', 'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071321] = {
		id = 7071321,
		skillTimePos = 2,
		group = 3308,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/icon_lj.png',
		textResPath = 'battle/txt/txt_lianji.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 5, ['cfgId'] = 7071312, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[7071331] = {
		id = 7071331,
		easyEffectFunc = 'fieldBuff',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 7071332, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[7071332] = {
		id = 7071332,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['onSomeFlag'] = {'exitInTab(getExtraRoundId(),list(c.lianji_oc()))'}, ['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 10, ['cfgId'] = 7071333, ['caster'] = 2, ['value'] = '(20+skillLv(70713,70733) *0.15-0.15)*100', ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 3, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[7071333] = {
		id = 7071333,
		easyEffectFunc = 'ultimateAdd',
		group = 1222,
		overlayType = 2,
		overlayLimit = 6,
		iconResPath = 'battle/buff_icon/logo_bssh_up.png',
		textResPath = 'battle/txt/txt_bsshtg.png',
		triggerBehaviors = {{['triggerPoint'] = 8, ['onSkillType'] = 1, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[7071341] = {
		id = 7071341,
		easyEffectFunc = 'secondAttack',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_lbsj.png',
		specialTarget = {{['input'] = 'selectObjectMainTarget', ['process'] = 'random(1)', __size = 2}},
		buffFlag = {3009, 1022}
	},
	[7071410] = {
		id = 7071410,
		dispelBuff = {7071642, 7071643, 7071644},
		overlayType = 1,
		overlayLimit = 1
	},
	[7071411] = {
		id = 7071411,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'buff/gaioukamega_buff/gaioukamega_buff.skel',
		onceEffectAniName = 'lianyi',
		specialVal = {{['natureType'] = 3, ['damageType'] = 2, ['processId'] = 3003, __size = 3}},
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {4003, 4021}
	},
	[7071412] = {
		id = 7071412,
		easyEffectFunc = 'jinghua2',
		group = 65009,
		dispelType = {3, 2},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071612, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[7071413] = {
		id = 7071413,
		skillTimePos = 2,
		dispelBuff = {7071410},
		overlayType = 1,
		overlayLimit = 1
	},
	[7071600] = {
		id = 7071600,
		easyEffectFunc = 'assistAttack',
		overlayType = 6,
		overlayLimit = 3,
		textResPath = 'battle/txt/txt_lianji.png',
		specialTarget = {{['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_yinshenplus_oc()})|buffDiffer(\'id\',{7071614})|random(1)', __size = 2}},
		triggerBehaviors = {{['onSomeFlag'] = {'getExtraRoundId()==7071600'}, ['triggerPoint'] = 7, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071315, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 3, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		buffFlag = {1022}
	},
	[7071611] = {
		id = 7071611,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'exitInTab(trigger.beAddBuff:getGroup(),list(c.shuixijinghua_oc()))'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071612, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 29, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'not target:curSkill():getDamageState(\'block\')'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071612, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 8, ['nodeId'] = 2, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'exitInTab(trigger.beAddBuff:getGroup(),list(c.debuff1_oc()))'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071617, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 29, ['nodeId'] = 3, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071612, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:flagZ4() and 1 or 0', __size = 6}}}, ['nodeId'] = 4, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 5, ['lifeRound'] = 999, ['cfgId'] = 7071620, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 5, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[7071612] = {
		id = 7071612,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 7071613, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(7071621) and 0 or 1', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 7071621, ['caster'] = 2, ['value'] = 0, ['prob'] = 'moreE(self:getBuffOverlayCount(7071613),5) and (target2:cardID()==7071 and 1 or 0) or 0', __size = 6}}, {{['holder'] = {['input'] = 'selfForce() | nodead', ['process'] = 'exclude(list(csvSelf:id()))|buffDifferExclude(\'id\',{7071619})|targetAnd("attrDiffer",{"natureType", {3,7}},"battleFlagDiffer",{\'battleFlag\',{10006}})|setSelectAttr({"damage","specialDamage"},"max")|attr("selectAttr","max",1)', __size = 2}, ['lifeRound'] = 3, ['cfgId'] = 7071613, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(7071621) and 1 or 0', __size = 6}}, {{['holder'] = {['input'] = 'selfForce() | nodead', ['process'] = 'exclude(list(csvSelf:id()))|buffDifferExclude(\'id\',{7071619})|targetAnd("attrDiffer",{"natureType", {3,7}},"battleFlagDiffer",{\'battleFlag\',{10006}})|setSelectAttr({"damage","specialDamage"},"max")|attr("selectAttr","max",1)', __size = 2}, ['lifeRound'] = 2, ['cfgId'] = 7071619, ['caster'] = 2, ['value'] = 0, ['prob'] = 'moreE(target2:getBuffOverlayCount(7071613),5) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		delRefreshMode = {1, 1}
	},
	[7071613] = {
		id = 7071613,
		group = 1302,
		overlayType = 6,
		overlayLimit = 5,
		iconResPath = 'battle/buff_icon/icon_lbjy.png',
		textResPath = 'battle/txt/txt_lbjy.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 1, ['cfgId'] = 7071614, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071615, ['caster'] = 1, ['value'] = {'list(1,0,0)', 1, 1}, ['prob'] = 0.16, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7071616, ['caster'] = 2, ['value'] = 300, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7071618, ['caster'] = 2, ['value'] = 500, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 30},
		delRefreshMode = {1, 1}
	},
	[7071614] = {
		id = 7071614,
		group = 1030001,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_qyzs.png',
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071615] = {
		id = 7071615,
		easyEffectFunc = 'assistAttack',
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_lianji.png',
		specialTarget = {{['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_yinshenplus_oc()})|buffDiffer(\'id\',{7071614})|random(1)', __size = 2}},
		triggerBehaviors = {{['onSomeFlag'] = {'getExtraRoundId()==7071615'}, ['triggerPoint'] = 7, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071315, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 3, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		buffFlag = {1022}
	},
	[7071616] = {
		id = 7071616,
		easyEffectFunc = 'damageAdd',
		group = 2005,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_shjc_up.png',
		textResPath = 'battle/txt/txt_shtg.png'
	},
	[7071617] = {
		id = 7071617,
		easyEffectFunc = 'qusan',
		group = 60029,
		dispelType = {3, 1},
		overlayLimit = 1,
		onceEffectWait = true,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071612, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2
	},
	[7071618] = {
		id = 7071618,
		easyEffectFunc = 'breakBlock',
		group = 2009,
		overlayType = 6,
		overlayLimit = 5,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_pdy_up.png',
		textResPath = 'battle/txt/txt_pdyltg.png'
	},
	[7071619] = {
		id = 7071619,
		overlayType = 1,
		overlayLimit = 1
	},
	[7071620] = {
		id = 7071620,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'exitInTab(trigger.beAddBuff:getGroup(),list(c.shuixijinghua_oc()))'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071612, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 29, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[7071621] = {
		id = 7071621,
		group = 5306,
		immuneBuff = {7071613, 7071619},
		dispelBuff = {7071613, 7071619},
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/icon_jynx.png',
		textResPath = 'battle/txt/txt_jynx.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 7, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071622, ['caster'] = 2, ['value'] = 4000, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071623, ['caster'] = 2, ['value'] = '0.2*(self:curSkill():targetType() == \'single\' and 2 or 1)', ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071624, ['caster'] = 2, ['value'] = {'list()', 'list(2010,80028)'}, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7071625, ['caster'] = 2, ['value'] = '(20+skillLv(70716,70736) *0.1-0.1)*100', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7071626, ['caster'] = 2, ['value'] = '(20+skillLv(70716,70736) *0.1-0.1)*100', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7071681, ['caster'] = 2, ['value'] = 0, ['prob'] = 'moreE(self:star(),8) and (less(self:getBuffOverlayCount(7071690),2) and 1 or 0) or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7071627, ['caster'] = 2, ['value'] = 1000, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 1, ['cfgId'] = 7071614, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071600, ['caster'] = 1, ['value'] = {'list(1,0,0)', 1, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 3, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 20}
	},
	[7071622] = {
		id = 7071622,
		easyEffectFunc = 'breakBlock',
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_pdy_up.png',
		textResPath = 'battle/txt/txt_pdyltg.png',
		lifeRoundType = 4
	},
	[7071623] = {
		id = 7071623,
		easyEffectFunc = 'damageRateAdd',
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		textResPath = 'battle/txt/txt_shtg.png',
		lifeRoundType = 4
	},
	[7071624] = {
		id = 7071624,
		easyEffectFunc = 'ignoreSpecBuff',
		overlayType = 1,
		overlayLimit = 1,
		lifeRoundType = 4
	},
	[7071625] = {
		id = 7071625,
		easyEffectFunc = 'ultimateSub',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bskx_up.png',
		textResPath = 'battle/txt/txt_bskxtg.png',
		iconShowType = {1, 10}
	},
	[7071626] = {
		id = 7071626,
		easyEffectFunc = 'strikeDamageSub',
		overlayType = 1,
		overlayLimit = 1
	},
	[7071627] = {
		id = 7071627,
		easyEffectFunc = 'damageSub',
		group = 1223,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjm_up.png',
		textResPath = 'battle/txt/txt_shjmtg.png',
		iconShowType = {1, 10}
	},
	[7071631] = {
		id = 7071631,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['onSomeFlag'] = {'exitInTab(getExtraRoundId(),list(c.lianji_oc())) and (not self:hasBuff(7071648))'}, ['triggerPoint'] = 7, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 6, ['cfgId'] = '(self:hasBuff(7071632) and self:hasBuff(7071633)) and 7071634 or ((self:hasBuff(7071632) and self:hasBuff(7071634)) and 7071633 or ( (self:hasBuff(7071633) and self:hasBuff(7071634)) and 7071632 or (self:hasBuff(7071632) and randomChoice(7071633,7071634) or (self:hasBuff(7071633) and randomChoice(7071632,7071634) or randomChoice(7071632,7071633))) ))', ['caster'] = 1, ['value'] = 0, ['prob'] = 'self:hasBuff(7071632,7071633,7071634) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 6, ['cfgId'] = 'randomChoice(7071632,7071633,7071634)', ['caster'] = 1, ['value'] = 0, ['prob'] = 'self:hasBuff(7071632,7071633,7071634) and 0 or 1', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071648, ['caster'] = 2, ['value'] = 0, ['prob'] = 0, __size = 6}}, {{['holder'] = 8, ['lifeRound'] = 2, ['cfgId'] = 7071649, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 3, ['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071632] = {
		id = 7071632,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_czj.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071638, ['caster'] = 2, ['value'] = 'self:specialDamage()*2', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 8, ['nodeId'] = 2, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDiffer(\'id\',{7071649})|random(1)', __size = 2}, ['lifeRound'] = 2, ['cfgId'] = 7071635, ['caster'] = 2, ['value'] = 'self:specialDamage()*1.2', ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7071642, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071650, ['caster'] = 2, ['value'] = 0, ['prob'] = '(self:hasBuff(7071632) and self:hasBuff(7071633) and self:hasBuff(7071634))  and 1 or 0', __size = 6}}}, ['triggerTimes'] = {1, 1}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071633] = {
		id = 7071633,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_gzj.png',
		triggerBehaviors = {{['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDiffer(\'id\',{7071649})|random(1)', __size = 2}, ['lifeRound'] = 2, ['cfgId'] = 7071636, ['caster'] = 2, ['value'] = 'self:specialDamage()*1.2', ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7071639, ['caster'] = 2, ['value'] = 'self:hpMax()*0.15', ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7071643, ['caster'] = 2, ['value'] = 0, ['prob'] = '(self:hasBuff(7071632) and self:hasBuff(7071633) and self:hasBuff(7071634))  and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071651, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerTimes'] = {1, 1}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071634] = {
		id = 7071634,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_yzj.png',
		triggerBehaviors = {{['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDiffer(\'id\',{7071649})|random(1)', __size = 2}, ['lifeRound'] = 2, ['cfgId'] = 7071637, ['caster'] = 2, ['value'] = 'self:specialDamage()*1.2', ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 10, ['cfgId'] = 7071640, ['caster'] = 2, ['value'] = 2000, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7071644, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071652, ['caster'] = 2, ['value'] = 0, ['prob'] = '(self:hasBuff(7071632) and self:hasBuff(7071633) and self:hasBuff(7071634))  and 1 or 0', __size = 6}}}, ['triggerTimes'] = {1, 1}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071635] = {
		id = 7071635,
		easyEffectFunc = 'buffDamage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['natureType'] = 4, ['damageType'] = 2, ['processId'] = 3004, __size = 3}},
		lifeRoundType = 4,
		buffFlag = {4021}
	},
	[7071636] = {
		id = 7071636,
		easyEffectFunc = 'buffDamage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['natureType'] = 17, ['damageType'] = 2, ['processId'] = 3017, __size = 3}},
		lifeRoundType = 4,
		buffFlag = {4021}
	},
	[7071637] = {
		id = 7071637,
		easyEffectFunc = 'buffDamage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['natureType'] = 13, ['damageType'] = 2, ['processId'] = 3013, __size = 3}},
		lifeRoundType = 4,
		buffFlag = {4021}
	},
	[7071638] = {
		id = 7071638,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'buff/zhiliao/zhiliao.skel',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		lifeRoundType = 4,
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[7071639] = {
		id = 7071639,
		easyEffectFunc = 'shield',
		group = 9001,
		overlayType = 6,
		overlayLimit = 99,
		iconResPath = 'battle/buff_icon/logo_hd.png',
		effectResPath = 'buff/hudun/hudun.skel',
		effectAniName = {'hudun_loop'},
		textResPath = 'battle/txt/txt_hd.png',
		specialVal = {0, 0, 10, {3, 0, 0.3}},
		iconShowType = {1, 10}
	},
	[7071640] = {
		id = 7071640,
		easyEffectFunc = 'damageSub',
		group = 1223,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjm_up.png',
		textResPath = 'battle/txt/txt_shjmtg.png',
		triggerBehaviors = {{['triggerPoint'] = 10, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 10, ['cfgId'] = 7071641, ['caster'] = 2, ['value'] = 1000, ['prob'] = 1, __size = 6}}}, ['delSelfWhenTriggered'] = 1, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 10}
	},
	[7071641] = {
		id = 7071641,
		easyEffectFunc = 'damageSub',
		group = 1223,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjm_up.png',
		textResPath = 'battle/txt/txt_shjmtg.png',
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 10, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 10}
	},
	[7071642] = {
		id = 7071642,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7071410, ['caster'] = 2, ['value'] = 0, ['prob'] = '(self:hasBuff(7071642) and self:hasBuff(7071643) and  self:hasBuff(7071644)) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071643] = {
		id = 7071643,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7071410, ['caster'] = 2, ['value'] = 0, ['prob'] = '(self:hasBuff(7071642) and self:hasBuff(7071643) and  self:hasBuff(7071644)) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071644] = {
		id = 7071644,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7071410, ['caster'] = 2, ['value'] = 0, ['prob'] = '(self:hasBuff(7071642) and self:hasBuff(7071643) and  self:hasBuff(7071644)) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071646] = {
		id = 7071646,
		easyEffectFunc = 'buffDamage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 15, ['damageType'] = 2, __size = 2}},
		lifeRoundType = 4,
		buffFlag = {4021}
	},
	[7071648] = {
		id = 7071648,
		group = 1030001,
		overlayLimit = 1,
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071649] = {
		id = 7071649,
		group = 1030001,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_qyzs.png',
		lifeRoundType = 4,
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071650] = {
		id = 7071650,
		group = 1030001,
		dispelBuff = {7071633, 7071634},
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_qyzs.png',
		lifeRoundType = 4,
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071651] = {
		id = 7071651,
		group = 1030001,
		dispelBuff = {7071632, 7071634},
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_qyzs.png',
		lifeRoundType = 4,
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071652] = {
		id = 7071652,
		group = 1030001,
		dispelBuff = {7071632, 7071633},
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_qyzs.png',
		lifeRoundType = 4,
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071653] = {
		id = 7071653,
		group = 1030001,
		overlayType = 6,
		overlayLimit = 3,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 6, ['cfgId'] = '(self:hasBuff(7071632) and self:hasBuff(7071633)) and 7071634 or ((self:hasBuff(7071632) and self:hasBuff(7071634)) and 7071633 or ( (self:hasBuff(7071633) and self:hasBuff(7071634)) and 7071632 or (self:hasBuff(7071632) and randomChoice(7071633,7071634) or (self:hasBuff(7071633) and randomChoice(7071632,7071634) or randomChoice(7071632,7071633))) ))', ['caster'] = 1, ['value'] = 0, ['prob'] = 'self:hasBuff(7071632,7071633,7071634) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 6, ['cfgId'] = 'randomChoice(7071632,7071633,7071634)', ['caster'] = 1, ['value'] = 0, ['prob'] = 'self:hasBuff(7071632,7071633,7071634) and 0 or 1', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071661] = {
		id = 7071661,
		group = 1030001,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 1, ['cfgId'] = 7071662, ['caster'] = 2, ['value'] = 'min(target2:hpMax()*0.1,self:specialDamage()*1.5)', ['prob'] = 0.35, __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[7071662] = {
		id = 7071662,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 15, ['damageType'] = 2, __size = 2}},
		buffFlag = {4021}
	},
	[7071680] = {
		id = 7071680,
		easyEffectFunc = 'fieldBuff',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {314},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerTimes'] = {1, 1}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 7071684, ['caster'] = 2, ['value'] = {1, 'list(0,0,0)', 1, 1, 'list(list(2),list(2))', 1, 'list(1,1)', 0, 1}, ['bond'] = 2, ['prob'] = 'self:hasBuff(7071680) and 1 or 0', __size = 7}}}, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9998}
	},
	[7071681] = {
		id = 7071681,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 14, ['lifeRound'] = 999, ['cfgId'] = 7071682, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[7071682] = {
		id = 7071682,
		overlayLimit = 1,
		triggerBehaviors = {{['onSomeFlag'] = {'not target:hasBuffGroup(c.fly_yinshenplus_oc())  and (not self:isBeControlled())'}, ['triggerPoint'] = 24, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 5, ['cfgId'] = 7071680, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7071690, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(7071680) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071683, ['caster'] = 2, ['value'] = {1, 1, 1}, ['prob'] = 'self:hasBuff(7071680) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 5, ['cfgId'] = 7071687, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(7071680) and 1 or 0', __size = 6}}}, ['triggerTimes'] = {1, 3}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSkillType'] = 1, __size = 8}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {9998}
	},
	[7071683] = {
		id = 7071683,
		easyEffectFunc = 'cancelToAttack',
		overlayLimit = 1,
		isShow = false,
		textResPath = 'battle/txt/txt_xdwx.png',
		lifeRoundType = 4,
		buffFlag = {9998}
	},
	[7071684] = {
		id = 7071684,
		easyEffectFunc = 'brawl',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_lbhj.png',
		specialVal = {{'assistAttack', 'seal', 'summon'}, {3009, 9999}},
		specialTarget = {{['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_yinshenplus_oc()})|buffDiffer(\'id\',{7071687})|random(1)', __size = 2}},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'trigger.reason==2'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7071685, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'self:hasBuff(7071684) and 1 or 0', __size = 7}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDiffer(\'id\',{7071687})|random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 7071686, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'self:hasBuff(7071684) and 1 or 0', __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7071686, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'self:hasBuff(7071684) and 1 or 0', __size = 7}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDiffer(\'id\',{7071687})|random(1)', __size = 2}, ['lifeRound'] = 4, ['cfgId'] = 7071699, ['caster'] = 2, ['value'] = -5000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDiffer(\'id\',{7071687})|random(1)', __size = 2}, ['lifeRound'] = 4, ['cfgId'] = 7071700, ['caster'] = 2, ['value'] = -5000, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['triggerPoint'] = 28, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {1}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071691, ['caster'] = 2, ['value'] = {'list(0,0,1)', 1, 1}, ['prob'] = 'moreE(self:getBuff(7071688):getValue(),self:getBuff(7071689):getValue()) and 0 or (target:hasBuff(762412) and 0 or 1)', __size = 6}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDiffer(\'id\',{7071687})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 7071691, ['caster'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDiffer(\'id\',{7071687})|random(1)', __size = 2}, ['value'] = {'list(0,0,1)', 1, 1}, ['prob'] = 'self:hasBuff(7071691) and 0 or 1', __size = 6}}}, ['triggerPoint'] = 19, ['nodeId'] = 2, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDiffer(\'id\',{7071687})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 7071691, ['caster'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDiffer(\'id\',{7071687})|random(1)', __size = 2}, ['value'] = {'list(0,0,1)', 1, 1}, ['prob'] = 'self:hasBuff(7071691) and 0 or 1', __size = 6}}}, ['nodeId'] = 3, __size = 4}, {['delSelfWhenTriggered'] = 1, ['onSomeFlag'] = {'trigger.reason==3'}, ['triggerPoint'] = 28, ['nodeId'] = 4, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		stageArgs = {{['delay'] = 200, ['bkCsv'] = 'csv.stage.lbhj', __size = 2}},
		buffFlag = {3004, 9998, 2017}
	},
	[7071685] = {
		id = 7071685,
		skillTimePos = 2,
		dispelBuff = {7071681},
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'koudai_kailudiou_juewuxingtai/kailudiou_cj.skel',
		effectAniName = {'linbohj_qian_loop'},
		effectPos = 5,
		effectAssignLayer = 4,
		deepCorrect = 99999,
		buffFlag = {9998}
	},
	[7071686] = {
		id = 7071686,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7071693, ['caster'] = 2, ['value'] = {7072, 99, 0, 1, 1, {['speed'] = 1, ['hpMax'] = 50, ['initMp1'] = 0, ['mp1Max'] = 1, __size = 4}, 1, {['y'] = 0, ['followMark'] = 4005, ['x'] = 0, ['dealGroup'] = 12, __size = 4}, 1, 1}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 5, ['cfgId'] = '((target:id()==self:id()) and 7071688 or 7071689)', ['caster'] = 1, ['value'] = 'self2:curSkill():getTotalDamage()*1', ['prob'] = 0, __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {9998}
	},
	[7071687] = {
		id = 7071687,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'self:hasBuff(7071684)'}, ['triggerPoint'] = 5, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071699, ['caster'] = 2, ['value'] = -5000, ['prob'] = 0, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071700, ['caster'] = 2, ['value'] = -5000, ['prob'] = 0, __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9998}
	},
	[7071688] = {
		id = 7071688,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_byzs.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 7071689, ['caster'] = 2, ['value'] = 'buff:getValue()', ['prob'] = 'target:hasBuff(7071687) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		buffFlag = {9999, 9998}
	},
	[7071689] = {
		id = 7071689,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_byzs.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 2,
		buffFlag = {9999, 9998}
	},
	[7071690] = {
		id = 7071690,
		skillTimePos = 2,
		group = 1030001,
		overlayType = 2,
		overlayLimit = 99,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999, 9998},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7071691] = {
		id = 7071691,
		easyEffectFunc = 'assistAttack',
		skillTimePos = 2,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_ewxd.png',
		specialTarget = {{['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_yinshenplus_oc()})|buffDiffer(\'id\',{7071687})|random(1)', __size = 2}},
		triggerBehaviors = {{['onSomeFlag'] = {'getExtraRoundId()==7071691'}, ['triggerPoint'] = 7, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071692, ['caster'] = 1, ['value'] = 5000, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 3, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['onSomeFlag'] = {'getExtraRoundId()==7071691'}, ['triggerPoint'] = 8, ['nodeId'] = 2, ['funcArgs'] = {{{['holder'] = {['input'] = 'all|nodead', ['process'] = 'random(12)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 7071698, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 3, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		buffFlag = {9998}
	},
	[7071692] = {
		id = 7071692,
		easyEffectFunc = 'damageReduce',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_shjd.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 4,
		buffFlag = {9998}
	},
	[7071693] = {
		id = 7071693,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		overlayLimit = 1,
		specialVal = {1, 0},
		specialTarget = {{['input'] = 'myself', ['process'] = 'random(1)', __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 20, ['cfgId'] = 7071694, ['caster'] = 20, ['value'] = {2, 100, 2}, ['bond'] = 2, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {9998, 9999}
	},
	[7071694] = {
		id = 7071694,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['damageAllocate'] = 'run', ['rebound'] = 'jump', ['groupShield'] = 'jump', ['assimilateDamage'] = 'jump', ['keepHpUnChanged'] = 'jump', ['stealth'] = 'jump', ['suckblood'] = 'jump', ['shield'] = 'jump', __size = 8}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7071695, ['caster'] = 1, ['value'] = 0, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7071696, ['caster'] = 2, ['value'] = {1, 2, 19, 1}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7071697, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7071701, ['caster'] = 2, ['value'] = {1, 2, 2}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7071218, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9998}
	},
	[7071695] = {
		id = 7071695,
		overlayType = 1,
		overlayLimit = 1,
		holderActionType = {['typ'] = 'opacity', ['args'] = {['value'] = 0, __size = 1}, __size = 2},
		triggerPriority = 200,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7071218, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 42, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 5, ['cfgId'] = 7071688, ['caster'] = 1, ['value'] = 'target:hpMax()-target:hp()', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9998}
	},
	[7071696] = {
		id = 7071696,
		easyEffectFunc = 'damageAllocate',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9998}
	},
	[7071697] = {
		id = 7071697,
		easyEffectFunc = 'filterFlag',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['selfForce'] = {'all'}, ['allForce'] = {4020, 9999}, ['enemyForce'] = {4020, 9999}, ['self'] = {'all'}, __size = 4}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9998}
	},
	[7071698] = {
		id = 7071698,
		group = 1030001,
		dispelBuff = {7071688, 7071689, 7071687},
		overlayType = 1,
		overlayLimit = 1,
		lifeRoundType = 4,
		buffFlag = {9999, 9998}
	},
	[7071699] = {
		id = 7071699,
		easyEffectFunc = 'strikeDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjsh_down.png',
		textResPath = 'battle/txt/txt_bjshjd.png',
		lifeRoundType = 4,
		buffFlag = {9999}
	},
	[7071700] = {
		id = 7071700,
		easyEffectFunc = 'ultimateAdd',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bssh_down.png',
		textResPath = 'battle/txt/txt_bsshjd.png',
		lifeRoundType = 4,
		buffFlag = {9999}
	},
	[7071701] = {
		id = 7071701,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['rebound'] = 2, ['groupShield'] = 2, ['assimilateDamage'] = 2, ['keepHpUnChanged'] = 2, ['stealth'] = 2, ['suckblood'] = 2, ['shield'] = 2, __size = 7}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9998}
	},
	[7072111] = {
		id = 7072111,
		skillTimePos = 2,
		dispelBuff = {7071216},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[7031001] = {
		id = 7031001,
		name = '闪光班基拉斯',
		easyEffectFunc = 'fieldBuff',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {15},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 7031002, ['caster'] = 2, ['value'] = 'target2:Bdefence()*0.2', ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and (target2:natureIntersection(list(9)) or target2:natureIntersection(list(13))) and (self:hasBuff(7031001) and 1 or 0) or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 7031003, ['caster'] = 2, ['value'] = 'target2:BspecialDefence()*0.2', ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and (target2:natureIntersection(list(9)) or target2:natureIntersection(list(13))) and (self:hasBuff(7031001) and 1 or 0) or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 7031004, ['caster'] = 2, ['value'] = {1, 2, 1}, ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and (target2:natureIntersection(list(9)) or target2:natureIntersection(list(13))) and (self:hasBuff(7031001) and 1 or 0) or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7031006, ['caster'] = 2, ['ignoreField'] = 1, ['value'] = 0, ['prob'] = '(self:hasBuff(7031001) and 1 or 0)', __size = 7}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5015},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031002] = {
		id = 7031002,
		easyEffectFunc = 'defence',
		skillTimePos = 2,
		group = 1021,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_up.png',
		textResPath = 'battle/txt/txt_wftg.png',
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5015},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031003] = {
		id = 7031003,
		easyEffectFunc = 'specialDefence',
		skillTimePos = 2,
		group = 1022,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_up.png',
		textResPath = 'battle/txt/txt_tftg.png',
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5015},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031004] = {
		id = 7031004,
		easyEffectFunc = 'alterDmgRecordVal',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['finalRate'] = {'setValue(list("finalDamageAdd"),(arg.from==1 and list(env:finalDamageSub()*10000+1000) or list(env:finalDamageSub()*10000)))'}, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5015},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031005] = {
		id = 7031005,
		dispelBuff = {7031001, 7031006},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5025},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031006] = {
		id = 7031006,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {'more(countObjByFlag(self:force(),3633),0) and not self:hasBuff(7031051)'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7031051, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7031005, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 3, ['nodeId'] = 1, __size = 5}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5015},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031051] = {
		id = 7031051,
		easyEffectFunc = 'fieldBuff',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {25},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 7031052, ['caster'] = 2, ['value'] = 'target2:Bdefence()*0.3', ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and (target2:natureIntersection(list(9)) or target2:natureIntersection(list(13))) and (self:hasBuff(7031051) and 1 or 0) or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 7031053, ['caster'] = 2, ['value'] = 'target2:BspecialDefence()*0.3', ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and (target2:natureIntersection(list(9)) or target2:natureIntersection(list(13))) and (self:hasBuff(7031051) and 1 or 0) or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 7031054, ['caster'] = 2, ['value'] = {1, 2, 1}, ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and (target2:natureIntersection(list(9)) or target2:natureIntersection(list(13))) and (self:hasBuff(7031051) and 1 or 0) or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 7031055, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and (target2:natureIntersection(list(9)) or target2:natureIntersection(list(13))) and (self:hasBuff(7031051) and 1 or 0) or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {'countObjByFlag(self:force(),3633)==0 and getExtraRoundMode()~=7 and getExtraRoundMode()~=8 and getExtraRoundMode()~=9'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7031001, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 7031058, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 42, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5025},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031052] = {
		id = 7031052,
		easyEffectFunc = 'defence',
		skillTimePos = 2,
		group = 2021,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_up.png',
		textResPath = 'battle/txt/txt_wftg.png',
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5025},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031053] = {
		id = 7031053,
		easyEffectFunc = 'specialDefence',
		skillTimePos = 2,
		group = 2022,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_up.png',
		textResPath = 'battle/txt/txt_tftg.png',
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5025},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031054] = {
		id = 7031054,
		easyEffectFunc = 'alterDmgRecordVal',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['finalRate'] = {'setValue(list("finalDamageAdd"),(arg.from==1 and list(env:finalDamageSub()*10000+1500) or list(env:finalDamageSub()*10000)))'}, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5025},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031055] = {
		id = 7031055,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'not target:hasBuff(7031056)'}, ['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 25, ['lifeRound'] = 1, ['cfgId'] = 7031057, ['caster'] = 1, ['value'] = 300000, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7031056, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff'}, __size = 6}},
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5025},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031056] = {
		id = 7031056,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5025},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031057] = {
		id = 7031057,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 2001, ['damageType'] = 2, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5025, 4021},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031058] = {
		id = 7031058,
		dispelBuff = {7031051},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {5000, 5025},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031110] = {
		id = 7031110,
		group = 21,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['bond'] = 2, ['cfgId'] = 7031111, ['caster'] = 2, ['value'] = 'target:Bdamage()*(self:flagZ1() and 0.2 or 0.1)', ['childBind'] = {2, 1}, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 7031112, ['caster'] = 2, ['childBind'] = {1, 1}, ['value'] = '-target:Bdamage()*(self:flagZ1() and 0.2 or 0.1)', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[7031111] = {
		id = 7031111,
		easyEffectFunc = 'defence',
		skillTimePos = 2,
		group = 1021,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_up.png',
		textResPath = 'battle/txt/txt_wftg.png'
	},
	[7031112] = {
		id = 7031112,
		easyEffectFunc = 'defence',
		group = 10021,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_down.png',
		textResPath = 'battle/txt/txt_wfjd.png'
	},
	[7031113] = {
		id = 7031113,
		group = 21,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['bond'] = 2, ['cfgId'] = 7031114, ['caster'] = 2, ['value'] = 'target:BspecialDamage()*(self:flagZ1() and 0.2 or 0.1)', ['childBind'] = {2, 1}, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 7031115, ['caster'] = 2, ['childBind'] = {1, 1}, ['value'] = '-target:BspecialDamage()*(self:flagZ1() and 0.2 or 0.1)', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[7031114] = {
		id = 7031114,
		easyEffectFunc = 'specialDefence',
		skillTimePos = 2,
		group = 1022,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_up.png',
		textResPath = 'battle/txt/txt_tftg.png'
	},
	[7031115] = {
		id = 7031115,
		easyEffectFunc = 'specialDefence',
		group = 10021,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_down.png',
		textResPath = 'battle/txt/txt_tfjd.png'
	},
	[7031210] = {
		id = 7031210,
		skillTimePos = 2,
		group = 81010,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 32, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7031212, ['caster'] = 2, ['value'] = {7032, 99, 0, 0.5, 1, {['speed'] = 1, ['initMp1'] = 0, ['mp1Max'] = 1, __size = 3}, 1, {['y'] = 0, ['followMark'] = 1003, ['x'] = 0, ['dealGroup'] = 7, __size = 4}, 1, 1}, ['prob'] = 'self:flag(200) and 0 or 1', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7031212, ['caster'] = 2, ['value'] = {7035, 99, 0, 0.5, 1, {['speed'] = 1, ['initMp1'] = 0, ['mp1Max'] = 1, __size = 3}, 1, {['y'] = 0, ['followMark'] = 1003, ['x'] = 0, ['dealGroup'] = 7, __size = 4}, 1, 1}, ['prob'] = 'self:flag(200) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999, 1005},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031211] = {
		id = 7031211,
		skillTimePos = 2,
		group = 81010,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 32, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 7031212, ['caster'] = 2, ['value'] = {7032, 99, 0, 0.5, 1, {['speed'] = 1, ['initMp1'] = 0, ['mp1Max'] = 1, __size = 3}, 1, {['y'] = 0, ['followMark'] = 1003, ['x'] = 0, ['dealGroup'] = 7, __size = 4}, 1, 1}, ['prob'] = 'self:flag(200) and 0 or 1', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 7031212, ['caster'] = 2, ['value'] = {7035, 99, 0, 0.5, 1, {['speed'] = 1, ['initMp1'] = 0, ['mp1Max'] = 1, __size = 3}, 1, {['y'] = 0, ['followMark'] = 1003, ['x'] = 0, ['dealGroup'] = 7, __size = 4}, 1, 1}, ['prob'] = 'self:flag(200) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999, 1005},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031212] = {
		id = 7031212,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		group = 81010,
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 7031213, ['caster'] = 2, ['value'] = 0, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 7031214, ['caster'] = 20, ['value'] = {2, 0, 1, 1}, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 7031215, ['caster'] = 20, ['value'] = {1, 2, 19, 100}, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 7031216, ['caster'] = 2, ['value'] = 0, ['bond'] = 2, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForceEx(list(1003))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031217, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForceEx(list(1003))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031217, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 3, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031213] = {
		id = 7031213,
		easyEffectFunc = 'stun',
		skillTimePos = 2,
		group = 81010,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'self:cardID()==7031'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031611, ['caster'] = 2, __size = 5}}, {{['holder'] = 16, ['lifeRound'] = 1, ['cfgId'] = 7031221, ['caster'] = 2, ['value'] = 250000, ['prob'] = 'self:flagZ2() and 1 or 0', __size = 6}}, {{['holder'] = 16, ['lifeRound'] = 1, ['cfgId'] = 7031222, ['caster'] = 2, ['value'] = 1500, ['prob'] = 'self:flagZ2() and 1 or 0', __size = 6}}}, ['triggerPoint'] = 13, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {'self:hasSkill(52109) and (self:cardID()==7031)'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 521802, ['caster'] = 2, ['value'] = '100+(10*(skillLv(52109) or 0)-10)', ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 521803, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 13, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031214] = {
		id = 7031214,
		easyEffectFunc = 'replaceTarget',
		skillTimePos = 2,
		group = 81010,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999, 2020, 3019},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031215] = {
		id = 7031215,
		easyEffectFunc = 'damageAllocate',
		skillTimePos = 2,
		group = 81010,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999, 2019},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031216] = {
		id = 7031216,
		skillTimePos = 2,
		group = 80010,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031217] = {
		id = 7031217,
		easyEffectFunc = 'kill',
		skillTimePos = 2,
		group = 81010,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {true, true},
		specialTarget = {1},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031221] = {
		id = 7031221,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 2001, ['damageType'] = 2, __size = 2}},
		buffFlag = {4021}
	},
	[7031222] = {
		id = 7031222,
		easyEffectFunc = 'damageDeepen',
		group = 10025,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjm_down.png',
		textResPath = 'battle/txt/txt_ys.png'
	},
	[7031311] = {
		id = 7031311,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 'moreE(self:star(),11) and 2 or 1', ['cfgId'] = 7031312, ['caster'] = 2, ['value'] = {7033, 99, 0, 'self:flagZ3() and 1 or 0.8', 1, {['speed'] = 1, ['initMp1'] = 0, ['mp1Max'] = 1, __size = 3}, 1, {['y'] = 100, ['followMark'] = 4001, ['x'] = 0, ['dealGroup'] = 8, ['posType'] = 3, __size = 5}, 1, 1}, ['prob'] = 'self:flag(200) and 0 or 1', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 'moreE(self:star(),11) and 2 or 1', ['cfgId'] = 7031312, ['caster'] = 2, ['value'] = {7036, 99, 0, 'self:flagZ3() and 1 or 0.8', 1, {['speed'] = 1, ['initMp1'] = 0, ['mp1Max'] = 1, __size = 3}, 1, {['y'] = 100, ['followMark'] = 4001, ['x'] = 0, ['dealGroup'] = 8, ['posType'] = 3, __size = 5}, 1, 1}, ['prob'] = 'self:flag(200) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {1006},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031312] = {
		id = 7031312,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 7031313, ['caster'] = 2, ['value'] = 0, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 7031318, ['caster'] = 2, ['value'] = 0, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 7031315, ['caster'] = 2, ['value'] = 0, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 13, ['lifeRound'] = 99, ['cfgId'] = 7031316, ['caster'] = 2, ['value'] = {0}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 7031317, ['caster'] = 2, ['value'] = {2, 99, 2}, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'rowback', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 7031322, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 7031326, ['caster'] = 2, ['value'] = {'list(list(),list(9999,4021,9997))'}, ['bond'] = 1, ['prob'] = 0, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForceEx(list(4001))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031217, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForceEx(list(4001))', ['process'] = 'selectObjSeat()', __size = 2}, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031217, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 3, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031313] = {
		id = 7031313,
		easyEffectFunc = 'stun',
		skillTimePos = 2,
		group = 81010,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'attrDiffer(\'natureType\', {13,9,16})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 7031210, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:flagZ3() and less(self:getBuffOverlayCount(7031323),3) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 7031323, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031611, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031611, ['caster'] = 2, __size = 5}}, {{['holder'] = 13, ['lifeRound'] = 1, ['cfgId'] = 7031221, ['caster'] = 2, ['value'] = '2000*(skillLv(70316) or 0)', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 7031319, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031314] = {
		id = 7031314,
		easyEffectFunc = 'forceSneer',
		skillTimePos = 2,
		group = 81010,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0, 1, 2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031315] = {
		id = 7031315,
		skillTimePos = 2,
		group = 80010,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031316] = {
		id = 7031316,
		easyEffectFunc = 'filterFlag',
		skillTimePos = 2,
		group = 81010,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['otherRow'] = {3001}, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031317] = {
		id = 7031317,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		group = 81010,
		overlayLimit = 1,
		specialVal = {{['groupShield'] = 2, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031318] = {
		id = 7031318,
		skillTimePos = 2,
		group = 81010,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7031325, ['caster'] = 1, ['value'] = {{['input'] = 'And(selfForce(),selfForceEx())|nodead', __size = 1}, 2, 1, 1, 1, 99, 10001}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031319] = {
		id = 7031319,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForceEx(list(4001))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 7031320, ['caster'] = 2, ['value'] = 0, ['prob'] = '(target:force()==target2:force()) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 6, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForceEx(list(4001))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031321, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031320] = {
		id = 7031320,
		group = 81010,
		overlayType = 1,
		overlayLimit = 1,
		holderActionType = {['list'] = {{['typ'] = 'opacity', ['args'] = {['value'] = 0.2, __size = 1}, ['playType'] = 1, __size = 3}}, __size = 1},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031321] = {
		id = 7031321,
		skillTimePos = 2,
		group = 81010,
		dispelBuff = {7031320},
		overlayType = 1,
		overlayLimit = 1,
		holderActionType = {['list'] = {{['typ'] = 'opacity', ['args'] = {['value'] = 1, __size = 1}, ['playType'] = 1, __size = 3}}, __size = 1},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031322] = {
		id = 7031322,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031323] = {
		id = 7031323,
		skillTimePos = 2,
		group = 81010,
		overlayType = 2,
		overlayLimit = 99,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031324] = {
		id = 7031324,
		easyEffectFunc = 'damageAllocate',
		skillTimePos = 2,
		group = 81010,
		overlayLimit = 1,
		specialTarget = {{['input'] = 'enemyForce|nodead', ['process'] = 'row(false,false,false)', __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {2019},
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031325] = {
		id = 7031325,
		easyEffectFunc = 'replaceTarget',
		skillTimePos = 2,
		group = 81010,
		overlayLimit = 1,
		specialVal = {1, 0},
		specialTarget = {{['input'] = 'enemyForce|nodead', ['process'] = 'row(false,false,false)', __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999, 2020, 3013, 3019},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031326] = {
		id = 7031326,
		easyEffectFunc = 'replaceBuffHolder',
		skillTimePos = 2,
		group = 81010,
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {{['input'] = 'enemyForce|nodead', ['process'] = 'row(false,false,false)', __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031610] = {
		id = 7031610,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 10, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031611, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'self:flagZ4() and (self:frontOrBack()==1)'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031611, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031611, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031611, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031611, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031611, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031210, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 1, ['nodeId'] = 2, __size = 5}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031611] = {
		id = 7031611,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7031618, ['caster'] = 2, ['value'] = 'target:hpMax()*0.1', ['prob'] = 'target:hasBuff(7031616) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7031612, ['caster'] = 2, ['value'] = 0, ['prob'] = 'target:hasBuff(7031616) and 0 or 1', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031612] = {
		id = 7031612,
		skillTimePos = 2,
		group = 9300,
		overlayType = 6,
		overlayLimit = 10,
		iconResPath = 'battle/buff_icon/logo_xwyk.png',
		effectResPath = 'koudai_shinybanjilasimega/sg_banjila_buff.skel',
		effectAniName = {'2hujia_loop'},
		textResPath = 'battle/txt/txt_xwyk.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7031613, ['caster'] = 2, ['value'] = 'target:Bdefence()*0.05', ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7031614, ['caster'] = 2, ['value'] = 'target:BspecialDefence()*0.08', ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7031615, ['caster'] = 2, ['value'] = 300, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 7031616, ['caster'] = 2, ['value'] = 0, ['prob'] = 'moreE(target:getBuffOverlayCount(7031612),10) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		iconShowType = {1, 20},
		skinEffect = {[7034] = 7031612, __size = 1}
	},
	[7031613] = {
		id = 7031613,
		easyEffectFunc = 'defence',
		skillTimePos = 2,
		group = 1021,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_up.png',
		textResPath = 'battle/txt/txt_wftg.png'
	},
	[7031614] = {
		id = 7031614,
		easyEffectFunc = 'specialDefence',
		skillTimePos = 2,
		group = 1022,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_up.png',
		textResPath = 'battle/txt/txt_tftg.png'
	},
	[7031615] = {
		id = 7031615,
		easyEffectFunc = 'damageSub',
		skillTimePos = 2,
		group = 1025,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjm_up.png',
		textResPath = 'battle/txt/txt_shjmtg.png'
	},
	[7031616] = {
		id = 7031616,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031617, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}}
	},
	[7031617] = {
		id = 7031617,
		dispelBuff = {7031612},
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'self:flagZ4()'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031210, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 1, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[7031618] = {
		id = 7031618,
		easyEffectFunc = 'addHP',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'buff/zhiliao/zhiliao.skel',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031}
	},
	[7031710] = {
		id = 7031710,
		easyEffectFunc = 'fieldBuff',
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 7031711, ['caster'] = 2, ['value'] = {}, ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(13)) or target2:natureIntersection(list(9)))  and (target2:force() == self:force()) and 1 or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 7031713, ['caster'] = 2, ['value'] = 'target2:Bdefence()*(0.1+(skillLv(70316) or 0)*0.002-0.002)', ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(13)) or target2:natureIntersection(list(9)))  and (target2:force() == self:force()) and 1 or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 7031714, ['caster'] = 2, ['value'] = 'target2:BspecialDefence()*(0.1+(skillLv(70316) or 0)*0.002-0.002)', ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(13)) or target2:natureIntersection(list(9)))  and (target2:force() == self:force()) and 1 or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 7031715, ['caster'] = 2, ['value'] = '1000+(skillLv(70316) or 0)*10-10', ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(13)) or target2:natureIntersection(list(9)))  and (target2:force() == self:force()) and 1 or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 7031716, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'exitInTab(target2:followMark(),{c.yanxizhangai_oc()}) and (target2:force() == self:force()) and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031711] = {
		id = 7031711,
		easyEffectFunc = 'ignoreSpecBuff',
		skillTimePos = 2,
		group = 70016,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{'shiftPos'}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'rowback|targetColumn', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 7031712, ['caster'] = 2, ['value'] = {}, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031712] = {
		id = 7031712,
		easyEffectFunc = 'ignoreSpecBuff',
		skillTimePos = 2,
		group = 70016,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{'shiftPos'}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031713] = {
		id = 7031713,
		easyEffectFunc = 'defence',
		skillTimePos = 2,
		group = 1021,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_up.png',
		textResPath = 'battle/txt/txt_wftg.png'
	},
	[7031714] = {
		id = 7031714,
		easyEffectFunc = 'specialDefence',
		skillTimePos = 2,
		group = 1022,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_up.png',
		textResPath = 'battle/txt/txt_tftg.png'
	},
	[7031715] = {
		id = 7031715,
		easyEffectFunc = 'damageSub',
		skillTimePos = 2,
		group = 1025,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjm_up.png',
		textResPath = 'battle/txt/txt_shjmtg.png'
	},
	[7031716] = {
		id = 7031716,
		skillTimePos = 2,
		group = 81010,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_cj.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 7031717, ['caster'] = 2, ['value'] = 5000, ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 7031718, ['caster'] = 2, ['value'] = {2, 99, 1}, ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 7031719, ['caster'] = 2, ['value'] = 5000, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		buffFlag = {9999},
		iconShowType = {1, 20}
	},
	[7031717] = {
		id = 7031717,
		easyEffectFunc = 'damageSub',
		skillTimePos = 2,
		group = 81010,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999}
	},
	[7031718] = {
		id = 7031718,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		group = 81010,
		overlayLimit = 1,
		specialVal = {{['calcInternalDamageFinish'] = {'setValue(list("calFinalDamage"),exitInTab(processId,list(3001,3002,3003,3004,3005,3006,3007,3008,3009,3010,3011,3012,3013,3014,3015,3016,3017,3018,3102,3104,3106,3108,3110,3112,3114,3116,3118,3120,3122,3124,3126,3128,3130,3132,3134,3136)) and list(calFinalDamage*0) or list(calFinalDamage*1))'}, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999}
	},
	[7031719] = {
		id = 7031719,
		easyEffectFunc = 'trueDamageSub',
		skillTimePos = 2,
		group = 81010,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999}
	},
	[7031811] = {
		id = 7031811,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'lessE(self:hp()/self:hpMax(),0.45)'}, ['triggerPoint'] = 42, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 'min(self:hpMax()*0.3,self:damage()*3)', ['cfgId'] = 7031812, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 2, ['value'] = 0, ['cfgId'] = 7031813, ['caster'] = 2, __size = 5}}}, ['triggerTimes'] = {1, 1}, ['effectFuncs'] = {'castBuff', 'castBuff'}, __size = 6}},
		craftTriggerLimit = {1},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031812] = {
		id = 7031812,
		easyEffectFunc = 'addHP',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'buff/zhiliao/zhiliao.skel',
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031}
	},
	[7031813] = {
		id = 7031813,
		skillTimePos = 2,
		group = 10036,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bzzt.png',
		textResPath = 'battle/txt/txt_bzzt.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7031820, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7031814, ['caster'] = 2, ['value'] = 5000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7031815, ['caster'] = 2, ['value'] = 2000, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7031816, ['caster'] = 2, ['value'] = 'target:Bspeed()*0.12', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 7031817, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'target:flag(7031) and 1 or 0', __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 7031818, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'target:flag(7031) and 0 or 1', __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 7031819, ['caster'] = 2, ['value'] = 1000, ['bond'] = 1, ['prob'] = 'target:flag(7031) and 1 or 0', __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 7031824, ['caster'] = 2, ['value'] = {{}, 'list(c.kongzhi1_kongzhi2_kongzhi3_oc())', {}}, ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 7031827, ['caster'] = 2, ['value'] = {1, 1}, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'more(target:getSpecBuffSubkeySize("delayDamage","damageTb"),0)'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 'target:getSpecBuffFuncVal("delayDamage","getRoundDamage")', ['cfgId'] = 7031828, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 7031829, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 'target:getBuff(7031828):getValue()*0.5', ['cfgId'] = 7031825, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 2, ['nodeId'] = 2, __size = 5}},
		buffFlag = {1044},
		iconShowType = {1, 10}
	},
	[7031814] = {
		id = 7031814,
		easyEffectFunc = 'strike',
		group = 1006,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjl_up.png',
		textResPath = 'battle/txt/txt_bjltg.png'
	},
	[7031815] = {
		id = 7031815,
		easyEffectFunc = 'strikeDamage',
		group = 1007,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjsh_up.png',
		textResPath = 'battle/txt/txt_bjshtg.png'
	},
	[7031816] = {
		id = 7031816,
		easyEffectFunc = 'speed',
		skillTimePos = 2,
		group = 1081,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_up.png',
		textResPath = 'battle/txt/txt_sdtg.png'
	},
	[7031817] = {
		id = 7031817,
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'koudai_shanguangbanjilasi_mega/hero_shanguangbanjilasi_mega.skel',
		effectAniName = {'baozou_loop'},
		ignoreHolder = 1,
		ignoreCaster = {1},
		spineEffect = {['skin'] = 'baozou', ['unitRes'] = {'koudai_shanguangbanjilasi_mega/hero_shanguangbanjilasi_mega.skel', 'koudai_sgcjbjlspf/hero_sgcjbjlspf.skel'}, __size = 2},
		skinEffect = {[7034] = 7031838, __size = 1}
	},
	[7031818] = {
		id = 7031818,
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'koudai_shanguangbanjilasi_mega/hero_shanguangbanjilasi_mega.skel',
		effectAniName = {'baozou_loop'},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffshader = {[3] = {0.3, 0.1, 0.1, 1}, __size = 1},
		skinEffect = {[7034] = 7031839, __size = 1}
	},
	[7031819] = {
		id = 7031819,
		easyEffectFunc = 'addMp1',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[7031820] = {
		id = 7031820,
		group = 60030,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[7031824] = {
		id = 7031824,
		easyEffectFunc = 'delayBuff',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[7031825] = {
		id = 7031825,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 3, ['damageType'] = 0, __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {4021}
	},
	[7031827] = {
		id = 7031827,
		easyEffectFunc = 'delayDamage',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[7031828] = {
		id = 7031828,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[7031829] = {
		id = 7031829,
		dispelBuff = {7031827},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[7031911] = {
		id = 7031911,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'self:flagZ4() and self:hasBuff(7031813)'}, ['funcArgs'] = {{{['holder'] = 13, ['lifeRound'] = 1, ['value'] = 'self:damage()*1.5*(target2:natureIntersection(list(11,14)) and 1.5 or 1)', ['cfgId'] = 7031912, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 25, ['nodeId'] = 1, __size = 5}},
		craftTriggerLimit = {1},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[7031912] = {
		id = 7031912,
		easyEffectFunc = 'buffDamage',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_shilabi/hero_shilabi.skel',
		onceEffectAniName = 'zhadan_baozha',
		onceEffectWait = true,
		specialVal = {{['processId'] = 39, ['damageType'] = 0, __size = 2}},
		buffFlag = {4021}
	},
	[3633111] = {
		id = 3633111,
		name = '超级蒂安希',
		group = 1010,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3633112, ['caster'] = 2, ['value'] = 'target:Bdamage()*0.1', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3633113, ['caster'] = 2, ['value'] = 'target:BspecialDamage()*0.1', ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}}
	},
	[3633112] = {
		id = 3633112,
		easyEffectFunc = 'damage',
		group = 2001,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wg_up.png',
		textResPath = 'battle/txt/txt_wgtg.png'
	},
	[3633113] = {
		id = 3633113,
		easyEffectFunc = 'specialDamage',
		group = 2002,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tg_up.png',
		textResPath = 'battle/txt/txt_tgtg.png'
	},
	[3633116] = {
		id = 3633116,
		skillTimePos = 2,
		group = 1030,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_sftg.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3633117, ['caster'] = 2, ['value'] = 'target:Bdefence()*0.2', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3633118, ['caster'] = 2, ['value'] = 'target:BspecialDefence()*0.2', ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}}
	},
	[3633117] = {
		id = 3633117,
		easyEffectFunc = 'defence',
		skillTimePos = 2,
		group = 2021,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_up.png'
	},
	[3633118] = {
		id = 3633118,
		easyEffectFunc = 'specialDefence',
		skillTimePos = 2,
		group = 2022,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_up.png'
	},
	[3633121] = {
		id = 3633121,
		skillTimePos = 2,
		group = 1030,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3633117, ['caster'] = 2, ['value'] = 'target:Bdefence()*0.3', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3633118, ['caster'] = 2, ['value'] = 'target:BspecialDefence()*0.3', ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}}
	},
	[3633122] = {
		id = 3633122,
		easyEffectFunc = 'defence',
		skillTimePos = 2,
		group = 2021,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_up.png',
		textResPath = 'battle/txt/txt_wftg.png'
	},
	[3633123] = {
		id = 3633123,
		easyEffectFunc = 'specialDefence',
		skillTimePos = 2,
		group = 2022,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_up.png',
		textResPath = 'battle/txt/txt_tftg.png'
	},
	[3633131] = {
		id = 3633131,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()', ['process'] = 'buffDifferExclude(\'group\',{c.notbuff_oc()})|ignoreBuffGroup(list(c.yinshenplus_oc()))|buffDifferOptional(\'id\',{3633311})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3633132, ['caster'] = 2, ['value'] = 200000, ['prob'] = '(moreE(self:getBuffOverlayCount(3633642),1)) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['castTimes'] = 4, ['cfgId'] = 3633642, ['caster'] = 2, ['value'] = 1, ['prob'] = '(moreE(self:getBuffOverlayCount(3633642),1)) and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}}
	},
	[3633132] = {
		id = 3633132,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 2001, ['damageType'] = 2, __size = 2}},
		ignoreCaster = {1},
		buffFlag = {4021, 4022},
		rayEffect = {['startDelayTime'] = 0, ['scaleX'] = 1, ['endDelayTime'] = 300, ['deep'] = 13, ['aniName'] = 'buff_guangshu_skill_loop', ['effectRes'] = 'koudai_dianxi_mega/guangshu.skel', ['offsetPos'] = {['y'] = 0, ['x'] = 0, __size = 2}, ['time'] = 100, __size = 8}
	},
	[3633141] = {
		id = 3633141,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3633641, ['caster'] = 2, ['value'] = 1, ['prob'] = '(less(self:getBuffOverlayCount(3633642),1) and less(self:getBuffOverlayCount(3633642),2) ) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3633142, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[3633142] = {
		id = 3633142,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1
	},
	[3633211] = {
		id = 3633211,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'koudai_dianxi_mega/hero_dianxi_mega.skel',
		effectAniName = {'buff_cuicangguangmang_loop'},
		onceEffectResPath = 'koudai_dianxi_mega/hero_dianxi_mega.skel',
		onceEffectAniName = 'buff_cuicangguangmang_chuxian',
		effectOnEnd = {['pos'] = 0, ['aniName'] = 'buff_cuicangguangmang_xiaoshi', ['res'] = 'koudai_dianxi_mega/hero_dianxi_mega.skel', __size = 3},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3633212, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3633213, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3633218, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 'self:flagZ2() and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 14, ['funcArgs'] = {{{['holder'] = 7, ['lifeRound'] = 3, ['cfgId'] = 3633214, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 2, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'((not intersection(trigger.damageArgs.buffFlag,list(2002))) and  (trigger.damageArgs.from~=2))'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.notbuff_oc()})|ignoreBuffGroup(list(c.yinshenplus_oc()))|buffDifferOptional(\'id\',{3633311})|random(2)', __size = 2}, ['lifeRound'] = 1, ['value'] = 300000, ['cfgId'] = 3633219, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 18, ['nodeId'] = 3, __size = 5}},
		buffFlag = {1044},
		skinEffect = {[3634] = 3633211, [3639] = 3639211, __size = 2}
	},
	[3633212] = {
		id = 3633212,
		skillTimePos = 2,
		group = 70021,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3633221, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[3633213] = {
		id = 3633213,
		skillTimePos = 2,
		group = 70025,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3633222, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[3633214] = {
		id = 3633214,
		group = 10010,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3633215, ['caster'] = 2, ['value'] = '-target:Bdamage()*0.1', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3633216, ['caster'] = 2, ['value'] = '-target:BspecialDamage()*0.1', ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}}
	},
	[3633215] = {
		id = 3633215,
		easyEffectFunc = 'damage',
		group = 11001,
		overlayType = 1,
		overlayLimit = 1
	},
	[3633216] = {
		id = 3633216,
		easyEffectFunc = 'specialDamage',
		group = 11002,
		overlayType = 1,
		overlayLimit = 1
	},
	[3633217] = {
		id = 3633217,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		holderActionType = {['list'] = {{['typ'] = 'rayEffect', ['args'] = {['startDelayTime'] = 0, ['scaleX'] = 1, ['endDelayTime'] = 300, ['deep'] = 13, ['aniName'] = 'buff_guangshu_skill_loop', ['effectRes'] = 'koudai_dianxi_mega/guangshu.skel', ['offsetPos'] = {['y'] = 0, ['x'] = 0, __size = 2}, ['time'] = 100, __size = 8}, __size = 2}, {['typ'] = 'wait', ['args'] = {['lifetime'] = 500, __size = 1}, __size = 2}}, __size = 1},
		specialVal = {{['processId'] = 2001, ['damageType'] = 2, __size = 2}},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 0, __size = 3}},
		buffFlag = {2002, 4021, 4022, 4026}
	},
	[3633218] = {
		id = 3633218,
		skillTimePos = 2,
		group = 70028,
		overlayType = 1,
		overlayLimit = 1
	},
	[3633219] = {
		id = 3633219,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		holderActionType = {['list'] = {{['typ'] = 'rayEffect', ['args'] = {['startDelayTime'] = 0, ['scaleX'] = 1, ['endDelayTime'] = 300, ['deep'] = 13, ['aniName'] = 'buff_guangshu_skill_loop', ['effectRes'] = 'koudai_dianxi_mega/guangshu.skel', ['offsetPos'] = {['y'] = 0, ['x'] = 0, __size = 2}, ['time'] = 100, __size = 8}, __size = 2}, {['typ'] = 'wait', ['args'] = {['lifetime'] = 500, __size = 1}, __size = 2}}, __size = 1},
		specialVal = {{['processId'] = 2001, ['damageType'] = 2, __size = 2}},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 0, __size = 3}},
		buffFlag = {4021}
	},
	[3633221] = {
		id = 3633221,
		skillTimePos = 2,
		dispelBuff = {3633212},
		overlayType = 1,
		overlayLimit = 1
	},
	[3633222] = {
		id = 3633222,
		skillTimePos = 2,
		dispelBuff = {3633213},
		overlayType = 1,
		overlayLimit = 1
	},
	[3633225] = {
		id = 3633225,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[3633231] = {
		id = 3633231,
		easyEffectFunc = 'shield',
		skillTimePos = 2,
		group = 9006,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_xzd.png',
		effectResPath = 'koudai_dianxi_mega/hero_dianxi_mega.skel',
		effectAniName = {'buff_hudun_loop'},
		effectOnEnd = {['pos'] = 0, ['aniName'] = 'buff_hudun_xiaoshi', ['res'] = 'koudai_dianxi_mega/hero_dianxi_mega.skel', __size = 3},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3633232, ['caster'] = 2, ['value'] = 'target2:Bdefence()*0.2', ['prob'] = '(target2:natureIntersection(list(13)) or target2:natureIntersection(list(18))) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 3633233, ['caster'] = 2, ['value'] = 'target2:BspecialDefence()*0.2', ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(13)) or target2:natureIntersection(list(18))) and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 19, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3633234, ['caster'] = 2, ['value'] = 'target2:hpMax()*0.1', ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(13)) or target2:natureIntersection(list(18))) and 1 or 0', __size = 7}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {0, 20},
		skinEffect = {[3634] = 3633231, [3639] = 3639231, __size = 2}
	},
	[3633232] = {
		id = 3633232,
		easyEffectFunc = 'defence',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_up.png',
		textResPath = 'battle/txt/txt_wftg.png'
	},
	[3633233] = {
		id = 3633233,
		easyEffectFunc = 'specialDefence',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_up.png',
		textResPath = 'battle/txt/txt_tftg.png'
	},
	[3633234] = {
		id = 3633234,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[3633311] = {
		id = 3633311,
		easyEffectFunc = 'stun',
		skillTimePos = 2,
		group = 602,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_zsfy.png',
		effectResPath = 'koudai_dianxi_mega/hero_dianxi_mega.skel',
		effectAniName = {'buff_fengying_loop'},
		onceEffectResPath = 'koudai_dianxi_mega/hero_dianxi_mega.skel',
		onceEffectAniName = 'buff_fengying_chuxian',
		effectOnEnd = {['pos'] = 0, ['aniName'] = 'buff_fengying_xiaoshi', ['res'] = 'koudai_dianxi_mega/hero_dianxi_mega.skel', __size = 3},
		textResPath = 'battle/txt/txt_sjfy.png',
		deepCorrect = 11,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {'trigger.beAddBuff:hasFlag(4022)'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'near', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3633312, ['caster'] = 2, ['value'] = 200000, ['prob'] = 'less(target:getBuffOverlayCount(3633313),6) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3633313, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 29, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 20},
		skinEffect = {[3634] = 3633311, [3639] = 3639311, __size = 2}
	},
	[3633312] = {
		id = 3633312,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 2001, ['damageType'] = 2, __size = 2}},
		ignoreCaster = {1},
		buffFlag = {4021}
	},
	[3633313] = {
		id = 3633313,
		skillTimePos = 2,
		overlayType = 2,
		overlayLimit = 6,
		noDelWhenFakeDeath = 1
	},
	[3633315] = {
		id = 3633315,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[3633316] = {
		id = 3633316,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|ignoreBuffGroup(list(c.yinshenplus_oc()))|buffDifferExclude(\'group\',{602})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3633311, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3633321] = {
		id = 3633321,
		easyEffectFunc = 'buffRecord',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {-3, '(self:Bdamage()+self:specialDamage())*(1+self:skillLv(36336,36346,36396)*0.003-0.003)*(1+countObjByBuffExGroup(self:force(),list(3633611,3633612),list(),list(c.undeath_oc()))*0.4)'},
		noDelWhenFakeDeath = 1
	},
	[3633322] = {
		id = 3633322,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3633323, ['caster'] = 2, ['value'] = {'self:hasBuff(3634111) and 3638 or (self:hasBuff(3639111) and 3640 or 3635)', 99, 0, 0, 1, {['hpMax'] = -3, ['specialDefence'] = 1, ['damageDodge'] = 0, ['rebound'] = 0, ['defence'] = 1, __size = 5}, 2, {['y'] = 150, ['followMark'] = 4004, ['x'] = 680, ['dealGroup'] = 11, ['posType'] = 2, __size = 5}, 1, 0}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3633323] = {
		id = 3633323,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0, 0},
		specialTarget = {2},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForceEx(list(4004))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 3633328, ['caster'] = {['input'] = 'selfForceEx(list(4004))', ['process'] = 'random(1)', __size = 2}, ['value'] = {0}, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForceEx(list(4004))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 3633327, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForceEx(list(4004))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 3633326, ['caster'] = 2, ['value'] = {'list(list(),list(9998))'}, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForceEx(list(4004))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 3633631, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3633324] = {
		id = 3633324,
		easyEffectFunc = 'damageAllocate',
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {2014, 2019},
		iconShowType = {1, 10}
	},
	[3633325] = {
		id = 3633325,
		easyEffectFunc = 'replaceTarget',
		skillTimePos = 2,
		overlayLimit = 1,
		specialVal = {0, 0, 1},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {2020}
	},
	[3633326] = {
		id = 3633326,
		easyEffectFunc = 'replaceBuffHolder',
		skillTimePos = 2,
		group = 81013,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3633327] = {
		id = 3633327,
		easyEffectFunc = 'stun',
		skillTimePos = 2,
		group = 80013,
		overlayType = 1,
		overlayLimit = 1
	},
	[3633328] = {
		id = 3633328,
		easyEffectFunc = 'aura',
		skillTimePos = 2,
		group = 81013,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 3633324, ['caster'] = {['input'] = 'selfForceEx(list(4004))', ['process'] = 'random(1)', __size = 2}, ['value'] = {1, 2, 17, 10000}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 3633325, ['caster'] = {['input'] = 'selfForceEx(list(4004))', ['process'] = 'random(1)', __size = 2}, ['value'] = {2, 1, 1, 1, 1, 99, 10000}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[3633341] = {
		id = 3633341,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 42, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 3633342, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1, 'list(36337)'}, ['prob'] = '(self:hasBuff(3634111) or self:hasBuff(3639111))  and 0 or 1', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 3633342, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1, 'list(36347)'}, ['prob'] = 'self:hasBuff(3634111) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 3633342, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1, 'list(36397)'}, ['prob'] = 'self:hasBuff(3639111) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3633342] = {
		id = 3633342,
		easyEffectFunc = 'assistAttack',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1
	},
	[3633343] = {
		id = 3633343,
		easyEffectFunc = 'qusan1',
		skillTimePos = 2,
		group = 60001,
		dispelType = {3, 0, 1},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300001, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3633344] = {
		id = 3633344,
		skillTimePos = 2,
		overlayType = 2,
		overlayLimit = 3,
		noDelWhenFakeDeath = 1
	},
	[3633351] = {
		id = 3633351,
		skillTimePos = 2,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 13, ['lifeRound'] = 5, ['cfgId'] = 3633352, ['caster'] = 1, ['value'] = 1500, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {2029}
	},
	[3633352] = {
		id = 3633352,
		easyEffectFunc = 'damageDeepen',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjm_down.png',
		textResPath = 'battle/txt/txt_ys.png',
		buffFlag = {2030}
	},
	[3633361] = {
		id = 3633361,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_gjxt.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3633642, ['caster'] = 2, ['value'] = 1, ['bond'] = 2, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'(trigger.resumeHpFrom~=103)'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()', ['process'] = 'buffDifferExclude(\'group\',{c.notbuff_oc()})|ignoreBuffGroup(list(c.yinshenplus_oc()))|buffDifferOptional(\'id\',{762680})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3633644, ['caster'] = 2, ['value'] = 200000, ['prob'] = '(moreE(self:getBuffOverlayCount(3633642),1)) and 1 or 0', __size = 6}}}, ['triggerPoint'] = 27, ['nodeId'] = 2, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 10, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()', ['process'] = 'buffDifferExclude(\'group\',{c.notbuff_oc()})|ignoreBuffGroup(list(c.yinshenplus_oc()))|buffDifferOptional(\'id\',{762680})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3633644, ['caster'] = 2, ['value'] = 200000, ['prob'] = '(moreE(self:getBuffOverlayCount(3633642),1)) and 1 or 0', __size = 6}}}, ['nodeId'] = 3, __size = 4}},
		spineEffect = {['action'] = {['standby'] = 'jian_standby_loop', ['attack'] = 'jian_attack', ['skill2'] = 'skill2', ['hit'] = 'jian_hit', ['run_loop'] = 'jian_run_loop', ['skill1'] = 'jian_skill1', ['win_loop'] = 'jian_win_loop', __size = 7}, ['unitRes'] = {'koudai_dianxi_mega/hero_dianxi_mega.skel', 'koudai_dianxi_megapf/hero_dianxi_megapf.skel'}, __size = 2}
	},
	[3633362] = {
		id = 3633362,
		overlayType = 1,
		overlayLimit = 1,
		lifeRoundType = 2
	},
	[3633363] = {
		id = 3633363,
		overlayType = 2,
		overlayLimit = 2
	},
	[3633370] = {
		id = 3633370,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 42, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForceEx(list(4003))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 3633371, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3633371] = {
		id = 3633371,
		group = 81013,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3633372, ['caster'] = 2, ['value'] = {'list(3633211),1'}, ['prob'] = 'target2:hasBuff(3633211) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3633211, ['caster'] = 2, ['value'] = 1, ['prob'] = 'target2:hasBuff(3633211) and 0 or 1', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3633372] = {
		id = 3633372,
		easyEffectFunc = 'changeBuffLifeRound',
		overlayType = 1,
		overlayLimit = 1,
		iconShowType = {1, 10}
	},
	[3633611] = {
		id = 3633611,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[3633612] = {
		id = 3633612,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[3633620] = {
		id = 3633620,
		skillTimePos = 2,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3633621, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3633621] = {
		id = 3633621,
		easyEffectFunc = 'buffRecord',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {-1, '(self:Bdamage()+self:specialDamage())*(1+self:skillLv(36336,36346,36396)*0.003-0.003)*(1+countObjByBuffExGroup(self:force(),list(3633611,3633612),list(),list(c.undeath_oc()))*0.4)'},
		noDelWhenFakeDeath = 1
	},
	[3633622] = {
		id = 3633622,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3633623, ['caster'] = 2, ['value'] = {'self:hasBuff(3634111) and 3638 or (self:hasBuff(3639111) and 3640 or 3635)', 99, 0, 0, 1, {['hpMax'] = -1, ['specialDefence'] = 1, ['damageDodge'] = 1, ['rebound'] = 0, ['defence'] = 1, __size = 5}, 2, {['y'] = 120, ['followMark'] = 4002, ['x'] = '(self:hasBuff(3634111) and 600 or 650)', ['dealGroup'] = 11, ['posType'] = 2, __size = 5}, 1, 0}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3633623] = {
		id = 3633623,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0, 0},
		specialTarget = {2},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForceEx(list(4002))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 3633627, ['caster'] = {['input'] = 'selfForceEx(list(4002))', ['process'] = 'random(1)', __size = 2}, ['value'] = {0}, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForceEx(list(4002))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 3633327, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForceEx(list(4002))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 3633626, ['caster'] = 2, ['value'] = {'list(list(),list(9998))'}, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForceEx(list(4002))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 3633631, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3633624] = {
		id = 3633624,
		easyEffectFunc = 'damageAllocate',
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {2014, 2019},
		iconShowType = {1, 10}
	},
	[3633625] = {
		id = 3633625,
		easyEffectFunc = 'replaceTarget',
		skillTimePos = 2,
		overlayLimit = 1,
		specialVal = {0, 0, 1},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {2020}
	},
	[3633626] = {
		id = 3633626,
		easyEffectFunc = 'replaceBuffHolder',
		skillTimePos = 2,
		group = 81013,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3633627] = {
		id = 3633627,
		easyEffectFunc = 'aura',
		skillTimePos = 2,
		group = 81013,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 3633624, ['caster'] = {['input'] = 'selfForceEx(list(4002))', ['process'] = 'random(1)', __size = 2}, ['value'] = {1, 2, 17, 10000}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 3633625, ['caster'] = {['input'] = 'selfForceEx(list(4002))', ['process'] = 'random(1)', __size = 2}, ['value'] = {2, 1, 1, 1, 1, 99, 10000}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[3633631] = {
		id = 3633631,
		skillTimePos = 2,
		group = 81013,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 999, ['cfgId'] = 3633231, ['caster'] = 2, ['value'] = 'self:damage()*0.3+self:specialDamage()*0.3', ['prob'] = 1, __size = 6}}, {{['holder'] = 13, ['lifeRound'] = 1, ['cfgId'] = 3633632, ['caster'] = 2, ['value'] = 'skillLv(36336,36346,36396)*2000-2000', ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3633641, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|ignoreBuffGroup(list(c.yinshenplus_oc()))|buffDifferExclude(\'group\',{602})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3633311, ['caster'] = 2, ['value'] = 1, ['prob'] = '(self:flagZ4() and less(self:getBuffOverlayCount(3633633),2) ) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3633633, ['caster'] = 2, ['value'] = 1, ['prob'] = 'self:flagZ4() and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3633632] = {
		id = 3633632,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 2001, ['damageType'] = 2, __size = 2}},
		ignoreCaster = {1},
		buffFlag = {4021},
		rayEffect = {['startDelayTime'] = 0, ['scaleX'] = 1, ['endDelayTime'] = 300, ['deep'] = 13, ['aniName'] = 'buff_guangshu_dun_loop', ['effectRes'] = 'koudai_dianxi_mega/guangshu.skel', ['offsetPos'] = {['y'] = 0, ['x'] = 0, __size = 2}, ['time'] = 100, __size = 8}
	},
	[3633633] = {
		id = 3633633,
		skillTimePos = 2,
		overlayType = 2,
		overlayLimit = 3
	},
	[3633641] = {
		id = 3633641,
		skillTimePos = 2,
		immuneBuff = {3633361},
		dispelBuff = {3633361},
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_gjxt.png',
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3633642, ['caster'] = 2, ['value'] = 1, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3633642, ['caster'] = 2, ['value'] = 1, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3633642, ['caster'] = 2, ['value'] = 1, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3633642, ['caster'] = 2, ['value'] = 1, ['bond'] = 2, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'(trigger.resumeHpFrom~=103)'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()', ['process'] = 'buffDifferExclude(\'group\',{c.notbuff_oc()})|ignoreBuffGroup(list(c.yinshenplus_oc()))|buffDifferOptional(\'id\',{762680})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3633644, ['caster'] = 2, ['value'] = 200000, ['prob'] = '(moreE(self:getBuffOverlayCount(3633642),1)) and 1 or 0', __size = 6}}}, ['triggerPoint'] = 27, ['nodeId'] = 2, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 10, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()', ['process'] = 'buffDifferExclude(\'group\',{c.notbuff_oc()})|ignoreBuffGroup(list(c.yinshenplus_oc()))|buffDifferOptional(\'id\',{762680})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3633644, ['caster'] = 2, ['value'] = 200000, ['prob'] = '(moreE(self:getBuffOverlayCount(3633642),1)) and 1 or 0', __size = 6}}}, ['nodeId'] = 3, __size = 4}},
		noDelWhenFakeDeath = 1,
		spineEffect = {['action'] = {['standby'] = 'jian_standby_loop', ['attack'] = 'jian_attack', ['skill2'] = 'skill2', ['hit'] = 'jian_hit', ['run_loop'] = 'jian_run_loop', ['skill1'] = 'jian_skill1', ['win_loop'] = 'jian_win_loop', __size = 7}, ['unitRes'] = {'koudai_dianxi_mega/hero_dianxi_mega.skel', 'koudai_dianxi_megapf/hero_dianxi_megapf.skel'}, __size = 2}
	},
	[3633642] = {
		id = 3633642,
		skillTimePos = 2,
		overlayType = 2,
		overlayLimit = 4,
		iconResPath = 'battle/buff_icon/logo_gj.png',
		iconShowType = {0, 30}
	},
	[3633643] = {
		id = 3633643,
		skillTimePos = 2,
		dispelBuff = {3633642},
		dispelType = {1, 1, 1},
		overlayType = 1,
		overlayLimit = 1
	},
	[3633644] = {
		id = 3633644,
		easyEffectFunc = 'buffDamage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 2001, ['damageType'] = 2, __size = 2}},
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3633643, ['caster'] = 2, ['value'] = 1, ['prob'] = '(moreE(self:getBuffOverlayCount(3633642),1)) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {4021, 4022},
		rayEffect = {['startDelayTime'] = 0, ['scaleX'] = 1, ['endDelayTime'] = 300, ['deep'] = 13, ['aniName'] = 'buff_guangshu_skill_loop', ['effectRes'] = 'koudai_dianxi_mega/guangshu.skel', ['offsetPos'] = {['y'] = 0, ['x'] = 0, __size = 2}, ['time'] = 100, __size = 8}
	},
	[3633645] = {
		id = 3633645,
		easyEffectFunc = 'buffDamage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 2001, ['damageType'] = 2, __size = 2}},
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3633643, ['caster'] = 2, ['value'] = 1, ['prob'] = '(moreE(self:getBuffOverlayCount(3633642),1)) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {4021, 4022},
		rayEffect = {['startDelayTime'] = 0, ['scaleX'] = 1, ['endDelayTime'] = 300, ['deep'] = 13, ['aniName'] = 'buff_guangshu_skill_loop', ['effectRes'] = 'koudai_dianxi_mega/guangshu.skel', ['offsetPos'] = {['y'] = 0, ['x'] = 0, __size = 2}, ['time'] = 100, __size = 8}
	},
	[3633651] = {
		id = 3633651,
		overlayType = 1,
		overlayLimit = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'more(getValueTab(trigger.resumeHp,overFlowValIdx),0)'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForceEx(list(4002,4003))', ['process'] = 'random(2)', __size = 2}, ['lifeRound'] = 1, ['value'] = 'min(getValueTab(trigger.resumeHp,overFlowValIdx)*0.5,self:Bdamage()*0.5+self:BspecialDamage()*0.5)', ['cfgId'] = 3633652, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 27, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1
	},
	[3633652] = {
		id = 3633652,
		easyEffectFunc = 'addHP',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_hf.png',
		specialVal = {{['ignoreLockResume'] = true, ['ignoreToDamage'] = true, ['ignoreHealAddRate'] = true, ['ignoreBeHealAddRate'] = true, __size = 4}},
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[3633660] = {
		id = 3633660,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'getNowRound()==1'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 3633661, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['triggerPoint'] = 3, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1
	},
	[3633661] = {
		id = 3633661,
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'koudai_dianxi_mega/hero_dianxi_mega.skel',
		effectAniName = {'buff_yanjingyan_loop'},
		effectPos = 3,
		effectAssignLayer = 2,
		effectOffsetPos = {['y'] = 400, ['x'] = 200, __size = 2},
		onceEffectResPath = 'koudai_dianxi_mega/hero_dianxi_mega.skel',
		onceEffectAniName = 'buff_yanjingyan_chuxian',
		onceEffectPos = 5,
		onceEffectAssignLayer = 2,
		onceEffectOffsetPos = {['y'] = 400, ['x'] = 200, __size = 2},
		textResPath = 'battle/txt/txt_yjy.png',
		deepCorrect = 20050,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 3633642, ['caster'] = 2, ['value'] = 'self:damage()*0.5', ['bond'] = 1, ['prob'] = '(not target2:hasBuff(3633620)) and  (target2:natureIntersection(list(9))  or target2:natureIntersection(list(13)) or  target2:natureIntersection(list(18))) and 1 or 0', __size = 7}}, {{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 3633643, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.5', ['bond'] = 1, ['prob'] = '(not target2:hasBuff(3633620)) and  (target2:natureIntersection(list(9))  or target2:natureIntersection(list(13)) or  target2:natureIntersection(list(18))) and 1 or 0', __size = 7}}, {{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 3633644, ['caster'] = 2, ['value'] = 'self:damage()*0.5', ['bond'] = 1, ['prob'] = '(not target2:hasBuff(3633620)) and  (target2:natureIntersection(list(9))  or target2:natureIntersection(list(13)) or  target2:natureIntersection(list(18))) and 1 or 0', __size = 7}}, {{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 3633645, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.5', ['bond'] = 1, ['prob'] = '(not target2:hasBuff(3633620)) and  (target2:natureIntersection(list(9))  or target2:natureIntersection(list(13)) or  target2:natureIntersection(list(18))) and 1 or 0', __size = 7}}, {{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 3633666, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = '(target2:natureIntersection(list(9))  or target2:natureIntersection(list(13)) or  target2:natureIntersection(list(18))) and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		skinEffect = {[3634] = 3633661, [3639] = 3639661, __size = 2}
	},
	[3633662] = {
		id = 3633662,
		easyEffectFunc = 'damage',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wg_up.png',
		textResPath = 'battle/txt/txt_wgtg.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[3633663] = {
		id = 3633663,
		easyEffectFunc = 'specialDamage',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tg_up.png',
		textResPath = 'battle/txt/txt_tgtg.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[3633664] = {
		id = 3633664,
		easyEffectFunc = 'defence',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_up.png',
		textResPath = 'battle/txt/txt_wftg.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[3633665] = {
		id = 3633665,
		easyEffectFunc = 'specialDefence',
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_up.png',
		textResPath = 'battle/txt/txt_tftg.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[3633666] = {
		id = 3633666,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 1, ['cfgId'] = 3633667, ['caster'] = 2, ['value'] = 150000, ['prob'] = '((target2:force()~=self:force())  and less(self:getBuffOverlayCount(3633669),5)) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3633668, ['caster'] = 2, ['value'] = 'target2:hpMax()*0.05', ['prob'] = '(less(self:getBuffOverlayCount(3633669),5)) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3633669, ['caster'] = 2, ['value'] = 1, ['prob'] = '(less(self:getBuffOverlayCount(3633669),5)) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3633667] = {
		id = 3633667,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 2001, ['damageType'] = 2, __size = 2}},
		ignoreCaster = {1},
		buffFlag = {4021}
	},
	[3633668] = {
		id = 3633668,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[3633669] = {
		id = 3633669,
		skillTimePos = 2,
		overlayType = 2,
		overlayLimit = 5,
		lifeRoundType = 2
	},
	[3633681] = {
		id = 3633681,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3633682, ['caster'] = 2, ['value'] = {0, 1, 0, 15}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3633682] = {
		id = 3633682,
		easyEffectFunc = 'reborn',
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 26, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 3633683, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 3633701, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 3633702, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 12, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3633683] = {
		id = 3633683,
		easyEffectFunc = 'buff10',
		group = 80012,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerTimes'] = {1, 1}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 3633684, ['caster'] = 2, ['value'] = {99, 1}, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 3633685, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 3633686, ['caster'] = 2, ['value'] = {0, 0, 0, 1, 1, 0}, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 3633687, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 3633688, ['caster'] = 2, ['value'] = {99, 1, 1}, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 3633689, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}}, ['triggerPoint'] = 1, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 19, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 'self:hpMax()*0.5', ['cfgId'] = 3633690, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 500, ['cfgId'] = 3633691, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}},
		lifeTimeEnd = 0,
		noDelWhenFakeDeath = 1,
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3633684] = {
		id = 3633684,
		easyEffectFunc = 'keepHpUnChanged',
		group = 81012,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3633685] = {
		id = 3633685,
		easyEffectFunc = 'lockMp1Add',
		group = 81012,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3633686] = {
		id = 3633686,
		easyEffectFunc = 'depart',
		group = 4207,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3633687] = {
		id = 3633687,
		easyEffectFunc = 'stun',
		group = 81012,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3633688] = {
		id = 3633688,
		easyEffectFunc = 'lockHp',
		group = 81012,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_ailanpenhuolongx_mega/hero_ailanpenhuolongx_mega.skel',
		onceEffectAniName = 'buff_fuhuo',
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 4,
		noDelWhenFakeDeath = 1,
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3633689] = {
		id = 3633689,
		easyEffectFunc = 'stun',
		group = 81012,
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'koudai_dianxi_mega/hero_dianxi_mega.skel',
		effectAniName = {'die_loop'},
		holderActionType = {['typ'] = 'hide', ['args'] = {['sprite'] = {['isShow'] = false, __size = 1}, ['lifebar'] = {['isShow'] = false, __size = 1}, __size = 2}, __size = 2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2},
		skinEffect = {[3634] = 3633689, [3639] = 3639689, __size = 2}
	},
	[3633690] = {
		id = 3633690,
		easyEffectFunc = 'addHP',
		group = 81012,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_hf.png',
		specialVal = {{['ignoreLockResume'] = true, ['ignoreToDamage'] = true, ['ignoreHealAddRate'] = true, ['ignoreBeHealAddRate'] = true, __size = 4}},
		ignoreCaster = {1},
		buffFlag = {9999},
		iconShowType = {1, 10}
	},
	[3633691] = {
		id = 3633691,
		easyEffectFunc = 'addMp1',
		skillTimePos = 2,
		group = 81012,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_nqtg.png',
		specialVal = {{['ignoreLockMp1Add'] = true, ['ignoreMp1Recover'] = true, __size = 2}},
		ignoreCaster = {1},
		buffFlag = {9999}
	},
	[3633692] = {
		id = 3633692,
		easyEffectFunc = 'kill',
		skillTimePos = 2,
		group = 81012,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {true, true},
		buffFlag = {9999}
	},
	[3633701] = {
		id = 3633701,
		easyEffectFunc = 'buffRecord',
		skillTimePos = 2,
		group = 81012,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {-2, '(self:Bdamage()+self:specialDamage())*(1+self:skillLv(36336,36346,36396)*0.003-0.003)*(1+countObjByBuffExGroup(self:force(),list(3633611,3633612),list(),list(c.undeath_oc()))*0.4)*(self:flagZ4() and 5 or 3)'},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[3633702] = {
		id = 3633702,
		skillTimePos = 2,
		group = 81012,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['triggerPoint'] = 32, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3633703, ['caster'] = 2, ['value'] = {'self:hasBuff(3634111) and 3638 or (self:hasBuff(3639111) and 3640 or 3635)', 99, 0, 0, 1, {['hpMax'] = -2, ['specialDefence'] = 1, ['damageDodge'] = 1, ['rebound'] = 0, ['defence'] = 1, __size = 5}, 2, {['y'] = 120, ['followMark'] = 4003, ['x'] = '(self:hasBuff(3634111) and 600 or 650)', ['dealGroup'] = 11, ['posType'] = 2, __size = 5}, 1, 0}, ['prob'] = 1, __size = 6}}}, ['delSelfWhenTriggered'] = 1, ['triggerTimes'] = {1, 1}, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999}
	},
	[3633703] = {
		id = 3633703,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		group = 81012,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0, 0},
		specialTarget = {2},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForceEx(list(4003))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 3633708, ['caster'] = {['input'] = 'selfForceEx(list(4003))', ['process'] = 'random(1)', __size = 2}, ['value'] = {0}, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForceEx(list(4003))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 3633327, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForceEx(list(4003))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 3633706, ['caster'] = 2, ['value'] = {'list(list(),list(9998))'}, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForceEx(list(4003))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 3633631, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForceEx(list(4003))', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 3633707, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999}
	},
	[3633704] = {
		id = 3633704,
		easyEffectFunc = 'damageAllocate',
		skillTimePos = 2,
		group = 81012,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {2014, 9999, 2019},
		iconShowType = {1, 10}
	},
	[3633705] = {
		id = 3633705,
		easyEffectFunc = 'replaceTarget',
		skillTimePos = 2,
		group = 81012,
		overlayLimit = 1,
		specialVal = {0, 0, 1},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999, 2020}
	},
	[3633706] = {
		id = 3633706,
		easyEffectFunc = 'replaceBuffHolder',
		skillTimePos = 2,
		group = 81013,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {9999}
	},
	[3633707] = {
		id = 3633707,
		skillTimePos = 2,
		group = 81013,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()', ['process'] = 'buffDifferExclude(\'group\',{c.notbuff_oc()})|ignoreBuffGroup(list(c.yinshenplus_oc()))|buffDifferOptional(\'id\',{3633311})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3633311, ['caster'] = 2, ['value'] = 1, ['prob'] = 'self:flagZ4() and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3633692, ['caster'] = 2, ['value'] = 1, ['prob'] = 'self:hasBuff(3633683) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {9999}
	},
	[3633708] = {
		id = 3633708,
		easyEffectFunc = 'aura',
		skillTimePos = 2,
		group = 81013,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 3633704, ['caster'] = {['input'] = 'selfForceEx(list(4003))', ['process'] = 'random(1)', __size = 2}, ['value'] = {1, 2, 17, 10000}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 3633705, ['caster'] = {['input'] = 'selfForceEx(list(4003))', ['process'] = 'random(1)', __size = 2}, ['value'] = {2, 1, 1, 1, 1, 99, 10000}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999}
	},
	[3634111] = {
		id = 3634111,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[3634342] = {
		id = 3634342,
		easyEffectFunc = 'assistAttack',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1
	},
	[3639111] = {
		id = 3639111,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		noDelWhenFakeDeath = 1
	},
	[2461111] = {
		id = 2461111,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		group = 10101,
		overlayType = 2,
		overlayLimit = 5,
		iconResPath = 'battle/buff_icon/logo_zs.png',
		effectResPath = 'buff/zhuoshao/zhuoshao.skel',
		effectAniName = {'zhuoshao_loop_top'},
		textResPath = 'battle/txt/txt_zs1.png',
		specialVal = {{['natureType'] = 2, ['damageType'] = 1, ['processId'] = 3, __size = 3}},
		triggerBehaviors = {{['triggerPoint'] = 5, ['nodeId'] = 0, __size = 2}}
	},
	[2461220] = {
		id = 2461220,
		immuneBuff = {2461220},
		overlayType = 1,
		overlayLimit = 1
	},
	[2461221] = {
		id = 2461221,
		easyEffectFunc = 'immuneDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_yl.png',
		textResPath = 'battle/txt/txt_yl2.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|buffDiffer(\'id\',{2461220})|random(2)', __size = 2}, ['lifeRound'] = 3, ['cfgId'] = 2461222, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 'target2:hasBuff(2461220) and 1 or 0', __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 3, ['cfgId'] = 2461226, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 3, ['cfgId'] = 2461223, ['caster'] = 2, ['value'] = 7500, ['bond'] = 1, ['prob'] = 'self:flagZ2() and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 29, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 2461229, ['caster'] = 2, ['value'] = 0, ['prob'] = 'exitInTab(trigger.beAddBuff:getGroup(),list(c.kongzhis_oc())) and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 10, ['funcArgs'] = {{{['holder'] = 7, ['lifeRound'] = 2, ['value'] = 'self:specialDamage()*0.4', ['cfgId'] = 2461111, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 3, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		buffFlag = {1012},
		iconShowType = {1, 10},
		spineEffect = {['action'] = {['attack'] = 'attack_yl', ['skill2'] = 'skill2', ['hit'] = 'hit2', ['run_loop'] = 'run_loop2', ['standby_loop'] = 'standby_loop2', ['skill1'] = 'skill1_yl', __size = 6}, ['unitRes'] = {'koudai_biketini/hero_biketini.skel', 'koudai_biketini_pifu/hero_biketini_pifu.skel'}, __size = 2}
	},
	[2461222] = {
		id = 2461222,
		easyEffectFunc = 'stun',
		skillTimePos = 2,
		group = 603,
		dispelBuff = {2461220},
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_nlfs.png',
		effectResPath = 'koudai_biketini/hero_biketini.skel',
		effectAniName = {'suolian_loop'},
		onceEffectResPath = 'koudai_biketini/hero_biketini.skel',
		onceEffectAniName = 'suolian_chuxian',
		onceEffectOffsetPos = {['y'] = 20, ['x'] = 0, __size = 2},
		textResPath = 'battle/txt/txt_yys.png',
		iconShowType = {1, 20}
	},
	[2461223] = {
		id = 2461223,
		easyEffectFunc = 'immuneControlVal',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_mkltg.png'
	},
	[2461224] = {
		id = 2461224,
		easyEffectFunc = 'strike',
		skillTimePos = 2,
		group = 1006,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjl_up.png',
		textResPath = 'battle/txt/txt_bjltg.png',
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[2461225] = {
		id = 2461225,
		overlayType = 1,
		overlayLimit = 1
	},
	[2461226] = {
		id = 2461226,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 2461227, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 1, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 6, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 2461228, ['caster'] = 2, __size = 5}}}, ['extraAttackTrigger'] = 1, ['nodeId'] = 2, __size = 5}}
	},
	[2461227] = {
		id = 2461227,
		easyEffectFunc = 'stun',
		overlayType = 1,
		overlayLimit = 1
	},
	[2461228] = {
		id = 2461228,
		dispelBuff = {2461227},
		overlayType = 1,
		overlayLimit = 1
	},
	[2461229] = {
		id = 2461229,
		dispelBuff = {2461221},
		overlayType = 1,
		overlayLimit = 1
	},
	[2461321] = {
		id = 2461321,
		easyEffectFunc = 'fieldBuff',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 2461322, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 'trigger.obj.force ~= self:force() and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[2461322] = {
		id = 2461322,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 5, ['cfgId'] = 2461323, ['caster'] = 2, ['value'] = {'list(c.zhuoshao_oc())', '0.1+skillLevel*0.001-0.001', 2}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 2461324, ['caster'] = 2, ['value'] = {'list(c.zhuoshao_oc())', 1, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[2461323] = {
		id = 2461323,
		easyEffectFunc = 'otherBuffEnhance',
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1
	},
	[2461324] = {
		id = 2461324,
		easyEffectFunc = 'changeBuffLifeRound',
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2461325] = {
		id = 2461325,
		easyEffectFunc = 'strike',
		skillTimePos = 2,
		group = 1006,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjl_up.png',
		textResPath = 'battle/txt/txt_bjltg.png',
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[2461326] = {
		id = 2461326,
		easyEffectFunc = 'strikeDamage',
		skillTimePos = 2,
		group = 1007,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjsh_up.png',
		textResPath = 'battle/txt/txt_bjshtg.png',
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[2461331] = {
		id = 2461331,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_yj.png',
		effectResPath = 'buff/biketini_buff/biketini_buff.skel',
		effectAniName = {'kaijia_loop'},
		effectPos = 2,
		effectOffsetPos = {['y'] = -170, ['x'] = 0, __size = 2},
		onceEffectResPath = 'buff/biketini_buff/biketini_buff.skel',
		onceEffectAniName = 'kaijia_chuxian',
		textResPath = 'battle/txt/txt_yj.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 5, ['cfgId'] = 2461332, ['caster'] = 2, ['value'] = '(target2:natureIntersection(list(2))) and 2000 or 1000', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 2461334, ['caster'] = 2, ['value'] = 'target2:hpMax()*0.2', ['prob'] = '((target2:natureIntersection(list(2))) and moreE(self:star(),11)) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 10, ['funcArgs'] = {{{['holder'] = 15, ['lifeRound'] = 1, ['cfgId'] = 2461333, ['caster'] = 1, ['value'] = 'math.min( (self2:attackerSkill():getTargetTotalDamage(target))*0.2,self:Bdamage()*3)', ['prob'] = 'more(self2:attackerSkill():getTargetTotalDamage(target),0) and 1 or 0', __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 2, __size = 5}},
		iconShowType = {1, 20}
	},
	[2461332] = {
		id = 2461332,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1
	},
	[2461333] = {
		id = 2461333,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 15, ['damageType'] = 2, __size = 2}},
		buffFlag = {2002, 4021, 4026}
	},
	[2461334] = {
		id = 2461334,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'buff/zhiliao/zhiliao.skel',
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[2461341] = {
		id = 2461341,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 'self:specialDamage()', ['cfgId'] = 2461342, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2461342] = {
		id = 2461342,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['natureType'] = 2, ['damageType'] = 1, ['processId'] = 3002, __size = 3}},
		buffFlag = {4021}
	},
	[2461343] = {
		id = 2461343,
		easyEffectFunc = 'addMp1',
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[2461611] = {
		id = 2461611,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 38, ['funcArgs'] = {{{['holder'] = 13, ['lifeRound'] = 2, ['cfgId'] = 2461111, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.4', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'(getNowRound()%3 ==0)'}, ['funcArgs'] = {{{['holder'] = 13, ['lifeRound'] = 2, ['cfgId'] = 2461111, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.4', ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 3, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[2461612] = {
		id = 2461612,
		easyEffectFunc = 'fieldBuff',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 2461613, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 'trigger.obj.force ~= self:force() and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[2461613] = {
		id = 2461613,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 2461614, ['caster'] = 2, ['value'] = 'self:specialDamage()*target:sumBuffOverlayByGroup(c.zhuoshao_oc())*(0.2+skillLevel*0.002-0.002)', ['prob'] = '((not target:hasBuff(2461615)) and moreE(target:sumBuffOverlayByGroup(c.zhuoshao_oc()),5)) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[2461614] = {
		id = 2461614,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 3, ['damageType'] = 1, __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 2461615, ['caster'] = 1, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {4021}
	},
	[2461615] = {
		id = 2461615,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		lifeRoundType = 6,
		noDelWhenFakeDeath = 1,
		buffFlag = {9998, 9999}
	},
	[2461620] = {
		id = 2461620,
		easyEffectFunc = 'aura',
		overlayLimit = 1,
		specialTarget = {13},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 2461621, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[2461621] = {
		id = 2461621,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 1, ['cfgId'] = 2461331, ['caster'] = 2, ['value'] = 1, ['prob'] = '(not target2:hasBuff(2461331)) and 1 or 0', __size = 6}}, {{['holder'] = 11, ['lifeRound'] = 1, ['cfgId'] = 2461622, ['caster'] = 2, ['value'] = {'list(2461331)', 1}, ['prob'] = '(target2:hasBuff(2461331)) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 2461623, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1}, ['prob'] = 'not self:hasBuff(2461221) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 2461624, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1}, ['prob'] = 'self:hasBuff(2461221) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[2461622] = {
		id = 2461622,
		easyEffectFunc = 'changeBuffLifeRound',
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_yj.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2461623] = {
		id = 2461623,
		easyEffectFunc = 'assistAttack',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[2461624] = {
		id = 2461624,
		easyEffectFunc = 'assistAttack',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 2461625, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2461625] = {
		id = 2461625,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['onSomeFlag'] = {'target:getExAttackMode()==5 and getExtraRoundId()==2461624'}, ['triggerPoint'] = 5, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 2461626, ['caster'] = 2, ['value'] = {'list(24611)', 'list(24621)'}, ['prob'] = '(self:originUnitId()==2461 and 1 or 0 )', __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['onSomeFlag'] = {'target:getExAttackMode()==5 and getExtraRoundId()==2461624'}, ['triggerPoint'] = 6, ['nodeId'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 2461627, ['caster'] = 2, ['value'] = 1, ['prob'] = '(self:originUnitId()==2461 and 1 or 0 )', __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 42, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 2461627, ['caster'] = 2, ['value'] = 1, ['prob'] = '(self:originUnitId()==2461 and 1 or 0 )', __size = 6}}}, ['nodeId'] = 3, __size = 4}, {['onSomeFlag'] = {'target:getExAttackMode()==5 and getExtraRoundId()==2461624'}, ['triggerPoint'] = 5, ['nodeId'] = 4, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 2461626, ['caster'] = 2, ['value'] = {'list(24631)', 'list(24639)'}, ['prob'] = '(self:originUnitId()==2463 and 1 or 0 )', __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['onSomeFlag'] = {'target:getExAttackMode()==5 and getExtraRoundId()==2461624'}, ['triggerPoint'] = 6, ['nodeId'] = 5, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 2461627, ['caster'] = 2, ['value'] = 1, ['prob'] = '(self:originUnitId()==2463 and 1 or 0 )', __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 42, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 2461627, ['caster'] = 2, ['value'] = 1, ['prob'] = '(self:originUnitId()==2463 and 1 or 0 )', __size = 6}}}, ['nodeId'] = 6, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[2461626] = {
		id = 2461626,
		easyEffectFunc = 'replaceSkill',
		overlayType = 1,
		overlayLimit = 1
	},
	[2461627] = {
		id = 2461627,
		dispelBuff = {2461626},
		overlayType = 1,
		overlayLimit = 1
	},
	[2461628] = {
		id = 2461628,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'buff/biketini_buff/biketini_buff.skel',
		onceEffectAniName = 'yunsh'
	},
	[2461651] = {
		id = 2461651,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_mybd.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1
	},
	[2461652] = {
		id = 2461652,
		skillTimePos = 2,
		group = 71012,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_mycr.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1
	},
	[2461653] = {
		id = 2461653,
		easyEffectFunc = 'immuneControlVal',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_mkltg.png',
		specialVal = {71012},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1
	},
	[2461654] = {
		id = 2461654,
		easyEffectFunc = 'buff2',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 2461655, ['caster'] = 2, ['value'] = {0, 'self:hpMax()*0.5', 0, 15}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[2461655] = {
		id = 2461655,
		easyEffectFunc = 'reborn',
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'buffDiffer(\'id\',{2461670})|buffDifferExclude(\'group\',{c.fly_notbuff_oc})|setSelectAttr({"damage","specialDamage"},"max")|attr("selectAttr","max",1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 2461671, ['caster'] = 2, ['value'] = 1, ['prob'] = '(not self:flagZ4()) and 1 or 0', __size = 6}}, {{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'buffDiffer(\'id\',{2461670})|buffDifferExclude(\'group\',{c.fly_notbuff_oc})|setSelectAttr({"damage","specialDamage"},"max")|attr("selectAttr","max",2)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 2461671, ['caster'] = 2, ['value'] = 1, ['prob'] = '(self:flagZ4()) and 1 or 0', __size = 6}}, {{['holder'] = 13, ['lifeRound'] = 2, ['cfgId'] = 2461611, ['caster'] = 2, ['value'] = 'self:specialDamage()', ['prob'] = '(self:flagZ4()) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 26, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['value'] = 1, ['cfgId'] = 2461657, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = {'list(0,1,0)', 1, 1}, ['cfgId'] = 2461656, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 12, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[2461656] = {
		id = 2461656,
		easyEffectFunc = 'assistAttack',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[2461657] = {
		id = 2461657,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerTimes'] = {1, 1}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 2, ['value'] = {99, 1}, ['cfgId'] = 2461658, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 99, ['value'] = 1, ['cfgId'] = 2461661, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 1, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		buffFlag = {1041},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[2461658] = {
		id = 2461658,
		easyEffectFunc = 'keepHpUnChanged',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[2461659] = {
		id = 2461659,
		easyEffectFunc = 'kill',
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		specialVal = {true, true},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[2461661] = {
		id = 2461661,
		overlayType = 1,
		overlayLimit = 1
	},
	[2461662] = {
		id = 2461662,
		easyEffectFunc = 'immuneDamage',
		skillTimePos = 2,
		immuneBuff = {2461221},
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_yl.png',
		textResPath = 'battle/txt/txt_yl2.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|buffDiffer(\'id\',{2461220})|random(2)', __size = 2}, ['lifeRound'] = 3, ['cfgId'] = 2461222, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 'target2:hasBuff(2461220) and 1 or 0', __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 3, ['cfgId'] = 2461226, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 3, ['cfgId'] = 2461223, ['caster'] = 2, ['value'] = 7500, ['bond'] = 1, ['prob'] = 'self:flagZ2() and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 29, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 2461222, ['caster'] = 2, ['value'] = 0, ['prob'] = 'exitInTab(trigger.beAddBuff:getGroup(),list(c.kongzhi1_kongzhi2_kongzhi3_oc())) and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 10, ['funcArgs'] = {{{['holder'] = 7, ['lifeRound'] = 2, ['value'] = 'self:specialDamage()*0.4', ['cfgId'] = 2461111, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 3, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 2461659, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 4, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		iconShowType = {1, 10},
		spineEffect = {['action'] = {['attack'] = 'attack_yl', ['skill2'] = 'skill2', ['hit'] = 'hit2', ['run_loop'] = 'run_loop2', ['standby_loop'] = 'standby_loop2', ['skill1'] = 'skill1_yl', __size = 6}, ['unitRes'] = {'koudai_biketini/hero_biketini.skel', 'koudai_biketini_pifu/hero_biketini_pifu.skel'}, __size = 2}
	},
	[2461665] = {
		id = 2461665,
		easyEffectFunc = 'buff2',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'buffDiffer(\'id\',{2461670})|buffDifferExclude(\'group\',{c.fly_notbuff_oc})|setSelectAttr({"damage","specialDamage"},"max")|attr("selectAttr","max",1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 2461671, ['caster'] = 2, ['value'] = 1, ['prob'] = '(not self:flagZ4()) and 1 or 0', __size = 6}}, {{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'buffDiffer(\'id\',{2461670})|buffDifferExclude(\'group\',{c.fly_notbuff_oc})|setSelectAttr({"damage","specialDamage"},"max")|attr("selectAttr","max",2)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 2461671, ['caster'] = 2, ['value'] = 1, ['prob'] = '(self:flagZ4()) and 1 or 0', __size = 6}}, {{['holder'] = 13, ['lifeRound'] = 2, ['cfgId'] = 2461611, ['caster'] = 2, ['value'] = 'self:specialDamage()', ['prob'] = '(self:flagZ4()) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[2461670] = {
		id = 2461670,
		overlayType = 1,
		overlayLimit = 1
	},
	[2461671] = {
		id = 2461671,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'buff/biketini_buff/biketini_buff.skel',
		onceEffectAniName = 'huozhong_chuxian',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 'target2:hpMax()*0.3', ['cfgId'] = 2461672, ['caster'] = 1, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 'self:Bdamage()*0.15', ['cfgId'] = 2461673, ['caster'] = 1, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 'self:BspecialDamage()*0.15', ['cfgId'] = 2461674, ['caster'] = 1, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 2000, ['cfgId'] = 2461675, ['caster'] = 1, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 2000, ['cfgId'] = 2461676, ['caster'] = 1, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['onSomeFlag'] = {'(not target:hasBuff(1972225))'}, ['triggerPoint'] = 32, ['nodeId'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['value'] = {1, 1, 0, 0, 0}, ['cfgId'] = 2461677, ['caster'] = 1, __size = 5}}}, ['triggerTimes'] = {1, 1}, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[2461672] = {
		id = 2461672,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'buff/zhiliao/zhiliao.skel',
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[2461673] = {
		id = 2461673,
		easyEffectFunc = 'damage',
		group = 1001,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wg_up.png',
		textResPath = 'battle/txt/txt_wgtg.png',
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[2461674] = {
		id = 2461674,
		easyEffectFunc = 'specialDamage',
		group = 1002,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tg_up.png',
		textResPath = 'battle/txt/txt_tgtg.png',
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[2461675] = {
		id = 2461675,
		easyEffectFunc = 'strike',
		group = 1006,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjl_up.png',
		textResPath = 'battle/txt/txt_bjltg.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[2461676] = {
		id = 2461676,
		easyEffectFunc = 'strikeDamage',
		group = 1007,
		groupPower = 102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_bjsh_up.png',
		textResPath = 'battle/txt/txt_bjshtg.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[2461677] = {
		id = 2461677,
		easyEffectFunc = 'lockHp',
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		gateLimit = {{['limit'] = 1, ['type'] = 1, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffActionEffect = {['triggerEffect'] = {['onceEffectAniName'] = 'effect', ['textResPath'] = 'battle/txt/txt_mysw.png', ['onceEffectResPath'] = 'buff/miansi/miansi.skel', __size = 3}, __size = 1},
		buffFlag = {2009},
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3621001] = {
		id = 3621001,
		name = '基格尔德',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 45, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'buffDiffer(\'id\',{3621001,3622001})|frontRowRandom(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3622942, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3621111] = {
		id = 3621111,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 15, ['damageType'] = 2, __size = 2}},
		buffFlag = {4021}
	},
	[3621211] = {
		id = 3621211,
		skillTimePos = 2,
		group = 1301,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3621212, ['caster'] = 2, ['value'] = {1, 2, 1}, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[3621212] = {
		id = 3621212,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		group = 2084,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['damageHit'] = {'setValue(list("damageHit"),(target:natureIntersection(list(5))) and list(env:damageHit()*10000+100000) or ((target:natureIntersection(list(10))) and list(env:damageHit()*10000) or list(env:damageHit()*10000+3000)))'}, __size = 1}}
	},
	[3621221] = {
		id = 3621221,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3621222, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3621222] = {
		id = 3621222,
		easyEffectFunc = 'inviteAttack',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{1}},
		specialTarget = {{['input'] = 'selfForce()|nodead', ['process'] = 'exclude(list(csvSelf:id()))|buffDiffer(\'id\',{3621001})', __size = 2}},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 2, ['triggerPoint'] = 1, ['nodeId'] = 0, __size = 3}}
	},
	[3621311] = {
		id = 3621311,
		easyEffectFunc = 'silence',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0, 1},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {'moreE(self:mp1(),self:mp1Max())'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = '90+10*(skillLv(36213,36243) or 0)', ['cfgId'] = 3621312, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3621313, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1, 1, 1}, ['prob'] = 'self:flagZ3() and 1 or 0', __size = 6}}}, ['triggerPoint'] = 32, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'less(self:mp1(),self:mp1Max())'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 3621314, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 42, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3621312] = {
		id = 3621312,
		easyEffectFunc = 'suckBlood',
		group = 3034,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_xx.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[3621313] = {
		id = 3621313,
		easyEffectFunc = 'counterAttack',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3621314] = {
		id = 3621314,
		dispelBuff = {3621312, 3621313},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3621321] = {
		id = 3621321,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3621322, ['caster'] = 2, ['value'] = '500*countObjByBuff(self:force(),{3621001})', ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3621322] = {
		id = 3621322,
		easyEffectFunc = 'damageAdd',
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_shjc_up.png',
		textResPath = 'battle/txt/txt_shtg.png',
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10}
	},
	[3621611] = {
		id = 3621611,
		easyEffectFunc = 'counterAttack',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3621810] = {
		id = 3621810,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {'trigger.buffCfgId==3622712 or trigger.buffCfgId==3621812'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()|nodead', ['process'] = 'buffDifferExcludeOptional(\'id\',{3623212})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3623212, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:flagZ4() and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3623112, ['caster'] = 2, ['value'] = 'self:Bdamage()*0.05', ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 35, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3621811] = {
		id = 3621811,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'trigger.buffCfgId==3622712 and not isSoloFightType() and getExtraRoundMode()~=7 and getExtraRoundMode()~=8 and getExtraRoundMode()~=9 and getGateType() ~= 10 and getGateType() ~= 14'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = {0, 'self:hasBuff(3626001) and 3624 or 3621', 1, 1}, ['cfgId'] = 3621812, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 35, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3621812] = {
		id = 3621812,
		easyEffectFunc = 'frontStage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {12},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3621910] = {
		id = 3621910,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3621911, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3621911] = {
		id = 3621911,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {'target:hasBuff(3623811) and target:getBuff(3623811):getCaster():hasBuff(3623817)'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'buffDiffer(\'id\',{3622001})|frontRowRandom(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3621912, ['caster'] = 2, ['value'] = {1}, ['prob'] = 'moreE(countObjByBuff(self:force(),{3622001}),1) and 1 or 0', __size = 6}}, {{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'buffDiffer(\'id\',{3621001})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3621916, ['caster'] = 2, ['value'] = {1}, ['prob'] = 'moreE(countObjByBuff(self:force(),{3622001}),1) and 0 or 1', __size = 6}}}, ['triggerPoint'] = 6, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3621912] = {
		id = 3621912,
		easyEffectFunc = 'immuneDamage',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = {'self:id()', 'self:hasBuff(3626001) and 3626 or 3623', 1, 1}, ['cfgId'] = 3621914, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'And(selfForceBack(),selfForce())|nodead', ['process'] = 'buffDiffer(\'id\',{3621001,3622001})', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3621915, ['caster'] = 2, ['value'] = 0, ['prob'] = '(self:getSummonGroup() == target2:getSummonGroup()) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[3621913] = {
		id = 3621913,
		easyEffectFunc = 'removeObj',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {3001}
	},
	[3621914] = {
		id = 3621914,
		easyEffectFunc = 'frontStage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {19},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3621915] = {
		id = 3621915,
		dispelBuff = {3241182},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = {1, 1}, ['cfgId'] = 3621913, ['caster'] = 1, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {3001}
	},
	[3621916] = {
		id = 3621916,
		easyEffectFunc = 'immuneDamage',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = {'self:id()', 'self:hasBuff(3626001) and 3625 or 3622', 1, 1}, ['cfgId'] = 3621914, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'buffDiffer(\'id\',{3621001,3622001})', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3621915, ['caster'] = 2, ['value'] = 0, ['prob'] = '(self:getSummonGroup() == target2:getSummonGroup()) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[3622001] = {
		id = 3622001,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 45, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'buffDiffer(\'id\',{3621001,3622001})|frontRowRandom(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3622942, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3622111] = {
		id = 3622111,
		easyEffectFunc = 'damage',
		group = 1001,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wg_up.png',
		textResPath = 'battle/txt/txt_wgtg.png'
	},
	[3622211] = {
		id = 3622211,
		skillTimePos = 2,
		overlayType = 8,
		overlayLimit = 5,
		iconResPath = 'battle/buff_icon/logo_sgdj.png',
		effectResPath = 'buff/zhongdu/zhongdu.skel',
		effectAniName = {'zhongdu_loop'},
		textResPath = 'battle/txt/txt_sgdj.png',
		triggerPriority = 9,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3622212, ['caster'] = 2, ['value'] = 'self:damage()*0.6', ['bond'] = 2, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3622213, ['caster'] = 2, ['value'] = {1, 2, 1}, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		iconShowType = {0, 20}
	},
	[3622212] = {
		id = 3622212,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		group = 10304,
		overlayType = 8,
		overlayLimit = 5,
		specialVal = {{['natureType'] = 8, ['damageType'] = 2, ['processId'] = 3008, __size = 3}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['triggerPoint'] = 5, ['nodeId'] = 0, __size = 2}},
		buffFlag = {4008}
	},
	[3622213] = {
		id = 3622213,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['calcInternalDamageFinish'] = {'setValue(list("calFinalDamage"),attacker:hasBuff(3622211) and (target:natureIntersection(list(9))) and list(calFinalDamage*(1-attacker:getBuffOverlayCount(3622211)*0.03)) or list(calFinalDamage*1))'}, __size = 1}}
	},
	[3622221] = {
		id = 3622221,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 5, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3622222, ['caster'] = 2, ['value'] = {'list(0,1,0)', 1, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[3622222] = {
		id = 3622222,
		easyEffectFunc = 'inviteAttack',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{0, 1, 2}},
		specialTarget = {{['input'] = 'selfForce()|nodead', ['process'] = 'exclude(list(csvSelf:id()))|buffDiffer(\'id\',{3622001})', __size = 2}},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 2, ['triggerPoint'] = 1, ['nodeId'] = 0, __size = 3}}
	},
	[3622311] = {
		id = 3622311,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3622611] = {
		id = 3622611,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 3, ['cfgId'] = 3622211, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3622711] = {
		id = 3622711,
		easyEffectFunc = 'reborn',
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = {'self:id()', 'self:hasBuff(3626001) and 3624 or 3621', 1, 1}, ['cfgId'] = 3622712, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'enemyForce()|nodead', ['process'] = 'buffDifferExcludeOptional(\'id\',{3623212})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3623212, ['caster'] = 2, ['value'] = 0, ['prob'] = 'ifElse(self:flagZ4(),0,1)*ifElse(moreE(self:star(),6),1,0)', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3623321, ['caster'] = 2, ['value'] = 'min(self:damage()*3,self:hpMax()*0.05)', ['prob'] = 'ifElse(moreE(self:star(),8),1,0)', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 26, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 3622713, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = {1}, ['cfgId'] = 3622714, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 3622715, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 12, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[3622712] = {
		id = 3622712,
		easyEffectFunc = 'frontStage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {18},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3622713] = {
		id = 3622713,
		easyEffectFunc = 'qusan',
		group = 61006,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3622714] = {
		id = 3622714,
		easyEffectFunc = 'backStage',
		group = 4205,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3622715] = {
		id = 3622715,
		easyEffectFunc = 'stun',
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_xy.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 35, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3622810] = {
		id = 3622810,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {'trigger.buffCfgId==3623712 or trigger.buffCfgId==3622812'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce()|nodead', ['process'] = 'buffDifferExcludeOptional(\'id\',{3623212})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3623212, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:flagZ4() and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3623112, ['caster'] = 2, ['value'] = 'self:Bdamage()*0.05', ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 35, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3622811] = {
		id = 3622811,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'trigger.buffCfgId==3623712 and not isSoloFightType() and getExtraRoundMode()~=7 and getExtraRoundMode()~=8 and getExtraRoundMode()~=9 and getGateType() ~= 10 and getGateType() ~= 14'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = {0, 'self:hasBuff(3626001) and 3625 or 3622', 1, 1}, ['cfgId'] = 3622812, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 35, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3622812] = {
		id = 3622812,
		easyEffectFunc = 'frontStage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {12},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3622910] = {
		id = 3622910,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3622911, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3622911] = {
		id = 3622911,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'target:hasBuff(3623811) and target:getBuff(3623811):getCaster():hasBuff(3623817) and (target:unitID()==3625 or target:unitID()==3622)'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'buffDiffer(\'id\',{3622001})|frontRowRandom(1)', __size = 2}, ['lifeRound'] = 1, ['value'] = {1}, ['cfgId'] = 3622912, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 6, ['nodeId'] = 1, __size = 5}}
	},
	[3622912] = {
		id = 3622912,
		easyEffectFunc = 'immuneDamage',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = {'self:id()', 'self:hasBuff(3626001) and 3626 or 3623', 1, 1}, ['cfgId'] = 3622914, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'And(selfForceBack(),selfForce())|nodead', ['process'] = 'buffDiffer(\'id\',{3621001,3622001})', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3622915, ['caster'] = 2, ['value'] = 0, ['prob'] = '(self:getSummonGroup() == target2:getSummonGroup()) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3622913] = {
		id = 3622913,
		easyEffectFunc = 'removeObj',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {3001}
	},
	[3622914] = {
		id = 3622914,
		easyEffectFunc = 'frontStage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {19},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3622915] = {
		id = 3622915,
		dispelBuff = {3241182},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = {1, 1}, ['cfgId'] = 3622913, ['caster'] = 1, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {3001}
	},
	[3622942] = {
		id = 3622942,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = {'self:id()', 'self:hasBuff(3626001) and 3626 or 3623', 1, 1}, ['cfgId'] = 3622944, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'And(selfForceBack(),selfForce())|nodead', ['process'] = 'buffDiffer(\'id\',{3621001,3622001})', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3622945, ['caster'] = 2, ['value'] = 0, ['prob'] = '(self:getSummonGroup() == target2:getSummonGroup()) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[3622943] = {
		id = 3622943,
		easyEffectFunc = 'removeObj',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {3001}
	},
	[3622944] = {
		id = 3622944,
		easyEffectFunc = 'frontStage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {19},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3622945] = {
		id = 3622945,
		dispelBuff = {3241182},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = {1, 1}, ['cfgId'] = 3622943, ['caster'] = 1, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {3001}
	},
	[3623001] = {
		id = 3623001,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 45, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'buffDiffer(\'id\',{3621001,3622001})|frontRowRandom(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3622942, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623111] = {
		id = 3623111,
		easyEffectFunc = 'damageSub',
		skillTimePos = 2,
		group = 1025,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjm_up.png',
		textResPath = 'battle/txt/txt_shjmtg.png'
	},
	[3623112] = {
		id = 3623112,
		easyEffectFunc = 'damage',
		group = 1001,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wg_up.png',
		textResPath = 'battle/txt/txt_wgtg.png'
	},
	[3623211] = {
		id = 3623211,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 15, ['damageType'] = 2, __size = 2}},
		buffFlag = {4021}
	},
	[3623212] = {
		id = 3623212,
		skillTimePos = 2,
		group = 18003,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_hxcf.png',
		effectResPath = 'buff/jged_buff/jged_hxcfbuff.skel',
		effectAniName = {'buff_loop'},
		effectPos = 2,
		effectOffsetPos = {['y'] = -150, ['x'] = 0, __size = 2},
		textResPath = 'battle/txt/txt_hxcf.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 25, ['funcArgs'] = {{{['holder'] = 13, ['lifeRound'] = 1, ['cfgId'] = 3623213, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'attr("hp","min",1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3623214, ['caster'] = 1, ['value'] = 'min(self:damage()*3,target:hpMax()*0.1)', ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3623215, ['caster'] = 1, ['value'] = 'min(self:damage()*3,target:hpMax()*0.1)', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}},
		iconShowType = {1, 20},
		skinEffect = {[3625] = 3626212, [3624] = 3626212, [3626] = 3626212, __size = 3}
	},
	[3623213] = {
		id = 3623213,
		easyEffectFunc = 'filterFlag',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['selfForce'] = {'all'}, ['allForce'] = {}, ['enemyForce'] = {3008}, ['self'] = {'all'}, __size = 4}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3623214] = {
		id = 3623214,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {3008, 2031}
	},
	[3623215] = {
		id = 3623215,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 15, ['damageType'] = 2, __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {4021}
	},
	[3623221] = {
		id = 3623221,
		skillTimePos = 2,
		group = 10303,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {'target:nature(1) ~=10 and target:nature(2) ~=10'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3623222, ['caster'] = 2, ['value'] = '-target:speed()*0.24', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3623223, ['caster'] = 2, ['value'] = {1, 10, 1}, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['triggerPoint'] = 1, ['nodeId'] = 1, __size = 5}}
	},
	[3623222] = {
		id = 3623222,
		easyEffectFunc = 'speed',
		skillTimePos = 2,
		group = 11081,
		overlayType = 1,
		overlayLimit = 1
	},
	[3623223] = {
		id = 3623223,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		group = 11084,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['damageHit'] = {'setValue(list("damageHit"),(attacker:hasBuff(3623221) and (target:natureIntersection(list(9))) and list(env:damageHit()*10000-4000) or list(env:damageHit()*10000)))'}, __size = 1}}
	},
	[3623224] = {
		id = 3623224,
		easyEffectFunc = 'updSkillSpellRoundOnce',
		overlayType = 1,
		overlayLimit = 1,
		iconShowType = {1, 10}
	},
	[3623311] = {
		id = 3623311,
		easyEffectFunc = 'fieldBuff',
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 3623312, ['caster'] = 2, ['value'] = {1, 2, 1}, ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and (target2:natureIntersection(list(9))) and 1 or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 3623313, ['caster'] = 2, ['value'] = {1, 2, 1}, ['bond'] = 1, ['prob'] = 'trigger.obj.force == self:force() and (target2:natureIntersection(list(9))) and 1 or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 3623314, ['caster'] = 2, ['value'] = '-target2:speed()*0.12', ['bond'] = 1, ['prob'] = 'trigger.obj.force ~= self:force() and target2:nature(1) ~=10 and target2:nature(2)~=10 and 1 or 0', __size = 7}}, {{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 3623315, ['caster'] = 2, ['value'] = {1, 2, 1}, ['bond'] = 1, ['prob'] = 'trigger.obj.force ~= self:force() and target2:nature(1) ~=10 and target2:nature(2)~=10 and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		buffFlag = {2029},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623312] = {
		id = 3623312,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		overlayLimit = 1,
		specialVal = {{['damageAdd'] = {'setValue(list("damageAdd"),(target:natureIntersection(list(5))) and list(env:damageAdd()*10000+1000) or list(env:damageAdd()*10000))'}, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623313] = {
		id = 3623313,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		overlayLimit = 1,
		specialVal = {{['damageHit'] = {'setValue(list("damageHit"),(target:natureIntersection(list(5))) and list(env:damageHit()*10000+100000) or list(env:damageHit()*10000))'}, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623314] = {
		id = 3623314,
		easyEffectFunc = 'speed',
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {2030},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623315] = {
		id = 3623315,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		overlayLimit = 1,
		specialVal = {{['damageHit'] = {'setValue(list("damageHit"),(target:natureIntersection(list(9))) and list(env:damageHit()*10000-2000) or list(env:damageHit()*10000))'}, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {2030},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623321] = {
		id = 3623321,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		group = 123456,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 38, ['damageType'] = 0, __size = 2}},
		specialTarget = {{['input'] = 'enemyForce|nodead', __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {4021, 4023, 1041}
	},
	[3623611] = {
		id = 3623611,
		easyEffectFunc = 'addHpMax',
		skillTimePos = 2,
		group = 2082,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_smsx_up.png',
		textResPath = 'battle/txt/txt_smsxtg.png',
		specialVal = {{['effectHp'] = true, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623621] = {
		id = 3623621,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 14, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3623622, ['caster'] = 15, ['value'] = '500+(skillLv(36236,36266) or 0)*10-10', ['prob'] = 'lessE(self2:hpMax(),target2:hpMax()) and 1 or 0', __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 7, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3623623, ['caster'] = 8, ['value'] = '500+(skillLv(36236,36266) or 0)*10-10', ['prob'] = 'moreE(self2:hpMax(),target2:hpMax()) and 1 or 0', __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 2, __size = 5}}
	},
	[3623622] = {
		id = 3623622,
		easyEffectFunc = 'damageSub',
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3623623] = {
		id = 3623623,
		easyEffectFunc = 'damageAdd',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3623711] = {
		id = 3623711,
		easyEffectFunc = 'reborn',
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = {'self:id()', 'self:originUnitId()==3626 and 3625 or 3622', 1, 1}, ['cfgId'] = 3623712, ['caster'] = 2, __size = 5}}, {{['holder'] = {['input'] = 'enemyForce()|nodead', ['process'] = 'buffDifferExcludeOptional(\'id\',{3623212})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3623212, ['caster'] = 2, ['value'] = 0, ['prob'] = 'ifElse(self:flagZ4(),0,1)*ifElse(moreE(self:star(),6),1,0)', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3623321, ['caster'] = 2, ['value'] = 'min(self:damage()*3,self:hpMax()*0.05)', ['prob'] = 'ifElse(moreE(self:star(),8),1,0)', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 26, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 3623713, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = {1}, ['cfgId'] = 3623714, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = {1}, ['cfgId'] = 3623715, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 12, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['value'] = {1}, ['cfgId'] = 3623716, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 3, __size = 4}, {['triggerPoint'] = 12, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3008}
	},
	[3623712] = {
		id = 3623712,
		easyEffectFunc = 'frontStage',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {18},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {3008}
	},
	[3623713] = {
		id = 3623713,
		easyEffectFunc = 'qusan',
		group = 61006,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {3008}
	},
	[3623714] = {
		id = 3623714,
		easyEffectFunc = 'backStage',
		group = 4205,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 32, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeTimeEnd = 0,
		buffFlag = {3008}
	},
	[3623715] = {
		id = 3623715,
		easyEffectFunc = 'stun',
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 35, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {3008}
	},
	[3623716] = {
		id = 3623716,
		easyEffectFunc = 'immuneDamage',
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_mysh.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 35, ['nodeId'] = 1, __size = 3}, {['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 32, ['nodeId'] = 2, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3008},
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623717] = {
		id = 3623717,
		dispelBuff = {3623716},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {3008},
		iconShowType = {1, 10}
	},
	[3623810] = {
		id = 3623810,
		easyEffectFunc = 'fieldBuff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 3623811, ['caster'] = 2, ['ignoreField'] = 1, ['value'] = 0, ['bond'] = 1, ['prob'] = '(self:getSummonGroup() == target2:getSummonGroup()) and 1 or 0', __size = 8}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3008},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623811] = {
		id = 3623811,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_hd.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'trigger.buffCfgId==3621914 or trigger.buffCfgId==3622914'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 3623812, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3623822, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3623819, ['caster'] = 2, ['value'] = {1, 2, {2}}, ['prob'] = 'target2:hasBuff(3623001) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3623717, ['caster'] = 2, ['value'] = 0, ['prob'] = 'target:hasBuff(3623001) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3623823, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 'max((self2:getBuffOverlayCount(3623833)*0.3+self2:getBuffOverlayCount(3623834)*0.15),0.15)', ['cfgId'] = 3623815, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 3623835, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 35, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3623833, ['caster'] = 2, ['ignoreField'] = 1, ['value'] = 0, ['prob'] = 'target:hasBuff(3622915,3622945,3621915) and target:hasBuff(3622001) and 1 or 0', __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3623834, ['caster'] = 2, ['ignoreField'] = 1, ['value'] = 0, ['prob'] = 'target:hasBuff(3622915,3622945,3621915) and target:hasBuff(3621001) and 1 or 0', __size = 7}}}, ['nodeId'] = 2, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623812] = {
		id = 3623812,
		group = 61006,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3623813] = {
		id = 3623813,
		easyEffectFunc = 'fieldBuff',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 3623814, ['caster'] = 2, ['value'] = 0, ['prob'] = '(self:getSummonGroup() == target2:getSummonGroup()) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623814] = {
		id = 3623814,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623815] = {
		id = 3623815,
		easyEffectFunc = 'setHpPer',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3623816] = {
		id = 3623816,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623817] = {
		id = 3623817,
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623818] = {
		id = 3623818,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 3623817, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623819] = {
		id = 3623819,
		easyEffectFunc = 'shiftPos',
		group = 14,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {1},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3623820] = {
		id = 3623820,
		dispelBuff = {3623814},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3623821] = {
		id = 3623821,
		dispelBuff = {3623816},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3623822] = {
		id = 3623822,
		dispelBuff = {3623817},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3623823] = {
		id = 3623823,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'And(selfForceBack(),selfForce())|nodead', ['process'] = 'buffDiffer(\'id\',{3621001,3622001})', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3623825, ['caster'] = 2, ['value'] = 0, ['prob'] = 'target:hasBuff(3623001) and (self:getSummonGroup() == target2:getSummonGroup()) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[3623824] = {
		id = 3623824,
		easyEffectFunc = 'removeObj',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3623825] = {
		id = 3623825,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = {1, 1}, ['cfgId'] = 3623824, ['caster'] = 1, __size = 5}}}, ['nodeId'] = 1, __size = 4}}
	},
	[3623833] = {
		id = 3623833,
		overlayType = 2,
		overlayLimit = 2,
		isShow = false,
		iconResPath = 'battle/buff_icon/logo_hd.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623834] = {
		id = 3623834,
		overlayType = 2,
		overlayLimit = 4,
		isShow = false,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3623835] = {
		id = 3623835,
		dispelBuff = {3623833, 3623834},
		overlayType = 1,
		overlayLimit = 1,
		isShow = false,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3626001] = {
		id = 3626001,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3651111] = {
		id = 3651111,
		name = '波尔凯尼恩',
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'koudai_boerkainien/hero_boerkainien.skel',
		effectAniName = {'dilei_loop'},
		effectResDelay = 990,
		onceEffectPos = 4,
		textResPath = 'battle/txt/txt_zqxj.png',
		deepCorrect = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'trigger.buffCfgId~=3622829 and trigger.buffCfgId~=4121312'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 'self:specialDamage()*1.2', ['cfgId'] = 3651112, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 47, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 'self:specialDamage()*1.2', ['cfgId'] = 3651112, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}},
		buffFlag = {2015, 2027}
	},
	[3651112] = {
		id = 3651112,
		easyEffectFunc = 'buffDamage',
		dispelBuff = {3651111},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_boerkainien/hero_boerkainien.skel',
		onceEffectAniName = 'dilei',
		onceEffectPos = 4,
		onceEffectWait = true,
		specialVal = {{['processId'] = 24, ['damageType'] = 0, __size = 2}},
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['value'] = 'self:specialDamage()*0.4', ['cfgId'] = 3651121, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {1014, 4021}
	},
	[3651113] = {
		id = 3651113,
		easyEffectFunc = 'specialDamage',
		group = 1002,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tg_up.png',
		textResPath = 'battle/txt/txt_tgtg.png'
	},
	[3651121] = {
		id = 3651121,
		easyEffectFunc = 'buffDamage',
		group = 13313,
		overlayType = 2,
		overlayLimit = 4,
		iconResPath = 'battle/buff_icon/logo_zf.png',
		effectResPath = 'koudai_boerkainien/hero_boerkainien.skel',
		effectAniName = {'zhengfa_loop'},
		onceEffectResPath = 'koudai_boerkainien/hero_boerkainien.skel',
		onceEffectAniName = 'zhengfa',
		textResPath = 'battle/txt/txt_zf1.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 3651122, ['caster'] = 2, ['value'] = '-target2:defence()*0.05', ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 3651123, ['caster'] = 2, ['value'] = '-target2:specialDefence()*0.05', ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 3651124, ['caster'] = 2, ['value'] = -500, ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 3651125, ['caster'] = 2, ['value'] = -500, ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 3651126, ['caster'] = 2, ['value'] = -500, ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 3651129, ['caster'] = 2, ['value'] = {1, 99, 1}, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'near|exclude(list(csvSelf:id()))|buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|random(1)', __size = 2}, ['lifeRound'] = 2, ['value'] = 'self:specialDamage()*0.4', ['cfgId'] = 3651121, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}, {['onSomeFlag'] = {'(target:attackerSkill():owner():nature(1)==2) or (target:attackerSkill():owner():nature(2)==2) or (target:attackerSkill():owner():nature(1)==3) or (target:attackerSkill():owner():nature(2)==3)'}, ['triggerPoint'] = 14, ['nodeId'] = 3, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 9, ['value'] = 1, ['cfgId'] = 3651127, ['caster'] = 2, __size = 5}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 29, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 3651128, ['caster'] = 2, ['value'] = {'list(3651121)', 1}, ['prob'] = '(exitInTab(trigger.beAddBuff:getGroup(),{c.zhuoshao_oc()}) and self:flagZ4() ) and 1 or 0', __size = 6}}}, ['nodeId'] = 4, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 46, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 3651128, ['caster'] = 2, ['value'] = {'list(3651121)', 1}, ['prob'] = '(exitInTab(trigger.beAddBuff:getGroup(),{c.zhuoshao_oc()})  and self:flagZ4()) and 1 or 0', __size = 6}}}, ['nodeId'] = 5, __size = 4}, {['triggerPoint'] = 5, ['nodeId'] = 0, __size = 2}},
		iconShowType = {0, 20}
	},
	[3651122] = {
		id = 3651122,
		easyEffectFunc = 'defence',
		group = 10021,
		groupPower = 102,
		overlayType = 2,
		overlayLimit = 4,
		iconResPath = 'battle/buff_icon/logo_wf_down.png',
		textResPath = 'battle/txt/txt_wfjd.png'
	},
	[3651123] = {
		id = 3651123,
		easyEffectFunc = 'specialDefence',
		group = 10022,
		groupPower = 102,
		overlayType = 2,
		overlayLimit = 4,
		iconResPath = 'battle/buff_icon/logo_tf_down.png',
		textResPath = 'battle/txt/txt_tfjd.png'
	},
	[3651124] = {
		id = 3651124,
		easyEffectFunc = 'strikeResistance',
		group = 10026,
		groupPower = 102,
		overlayType = 2,
		overlayLimit = 4,
		iconResPath = 'battle/buff_icon/logo_bjkx_down.png',
		textResPath = 'battle/txt/txt_bjkxjd.png'
	},
	[3651125] = {
		id = 3651125,
		easyEffectFunc = 'natureDamageDeepen',
		group = 10030,
		groupPower = 102,
		overlayType = 2,
		overlayLimit = 4,
		onceEffectWait = true,
		specialVal = {2}
	},
	[3651126] = {
		id = 3651126,
		easyEffectFunc = 'natureDamageDeepen',
		group = 10030,
		groupPower = 102,
		overlayType = 2,
		overlayLimit = 4,
		onceEffectWait = true,
		specialVal = {3}
	},
	[3651127] = {
		id = 3651127,
		overlayType = 8,
		overlayLimit = 6,
		iconResPath = 'battle/buff_icon/logo_zqdl.png',
		iconShowType = {1, 30}
	},
	[3651128] = {
		id = 3651128,
		easyEffectFunc = 'changeBuffLifeRound',
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3651129] = {
		id = 3651129,
		easyEffectFunc = 'alterDmgRecordVal',
		overlayType = 8,
		overlayLimit = 4,
		specialVal = {{['finalRate'] = {'setValue(list("finalDamageReduce"),( target:hasBuff(3651642) ) and list(env:finalDamageReduce()*10000+800) or  list(env:finalDamageReduce()*10000 ) )'}, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3651211] = {
		id = 3651211,
		easyEffectFunc = 'stealth',
		skillTimePos = 2,
		group = 9102,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_zqnw.png',
		holderActionType = {['typ'] = 'opacity', ['args'] = {['value'] = 0.9, __size = 1}, __size = 2},
		textResPath = 'battle/txt/txt_zqnw.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 4, ['cfgId'] = 3651212, ['caster'] = 2, ['value'] = 8000, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 10, ['funcArgs'] = {{{['holder'] = 15, ['lifeRound'] = 2, ['cfgId'] = 3651121, ['caster'] = 2, ['value'] = 'self:specialDamage()*0.4', ['prob'] = '(target:getDamageStateToMe(\'miss\')) and 1 or 0', __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 2, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 19, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3651213, ['caster'] = 2, ['value'] = 'target2:hpMax()*0.15', ['prob'] = '(self:flagZ2()) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3651214, ['caster'] = 2, ['value'] = 1, ['prob'] = '(self:flagZ2()) and 1 or 0', __size = 6}}}, ['nodeId'] = 3, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {0, 20},
		spineEffect = {['skin'] = 'w', ['unitRes'] = {'koudai_boerkainien/hero_boerkainien.skel'}, __size = 2}
	},
	[3651212] = {
		id = 3651212,
		easyEffectFunc = 'damageDodge',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		iconShowType = {1, 10}
	},
	[3651213] = {
		id = 3651213,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'buff/zhiliao/zhiliao.skel',
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031},
		iconShowType = {1, 10}
	},
	[3651214] = {
		id = 3651214,
		skillTimePos = 2,
		group = 60027,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1
	},
	[3651311] = {
		id = 3651311,
		easyEffectFunc = 'fieldBuff',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 3651312, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = '(trigger.obj.force == self:force() and (target2:natureIntersection(list(2)) or target2:natureIntersection(list(3))))  and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3651312] = {
		id = 3651312,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['onSomeFlag'] = {'(trigger.skill:owner():curSkill():getNatureType()==3 or trigger.skill:owner():curSkill():getNatureType()==2)'}, ['triggerPoint'] = 8, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3651313, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[3651313] = {
		id = 3651313,
		overlayType = 2,
		overlayLimit = 5,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3651314] = {
		id = 3651314,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 15, ['damageType'] = 2, __size = 2}},
		buffFlag = {4021}
	},
	[3651315] = {
		id = 3651315,
		skillTimePos = 2,
		overlayType = 8,
		overlayLimit = 5
	},
	[3651316] = {
		id = 3651316,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 13, ['lifeRound'] = 1, ['cfgId'] = 3651614, ['caster'] = 2, ['value'] = 'self:specialDamage()*(1+0.0015*fromSkillLevel-0.0015)', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3651317] = {
		id = 3651317,
		dispelBuff = {3651313},
		overlayType = 1,
		overlayLimit = 1
	},
	[3651611] = {
		id = 3651611,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 29, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 3651613, ['caster'] = 2, ['value'] = 1, ['prob'] = '(exitInTab(trigger.beAddBuff:getCfgId(),list(3651127))  and  moreE(target:getBuffOverlayCount(3651127),6)  and (not target:hasBuff(3651615)) ) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 46, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 3651613, ['caster'] = 2, ['value'] = 1, ['prob'] = '(exitInTab(trigger.beAddBuff:getCfgId(),list(3651127))  and  moreE(target:getBuffOverlayCount(3651127),6)  and (not target:hasBuff(3651615)) ) and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 3651613, ['caster'] = 2, ['value'] = 1, ['prob'] = '( moreE(target:getBuffOverlayCount(3651127),6)  and (not target:hasBuff(3651615))  ) and 1 or 0', __size = 6}}}, ['nodeId'] = 3, __size = 4}}
	},
	[3651613] = {
		id = 3651613,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 42, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 3, ['cfgId'] = 3651615, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = 14, ['lifeRound'] = 1, ['cfgId'] = 3651614, ['caster'] = 2, ['value'] = 'self:specialDamage()*(1+0.0015*fromSkillLevel-0.0015)', ['prob'] = '(not self:hasBuff(3651615)) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3651211, ['caster'] = 2, ['value'] = {1, 1, 1}, ['prob'] = '(self:flagZ4() ) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 3651617, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 2, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3651614] = {
		id = 3651614,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_boerkainien/hero_boerkainien.skel',
		onceEffectAniName = 'guangyuzhengqi',
		onceEffectPos = 5,
		onceEffectWait = true,
		specialVal = {{['natureType'] = 2, ['damageType'] = 2, ['processId'] = 3002, __size = 3}},
		ignoreCaster = {1},
		buffFlag = {4002, 4021}
	},
	[3651615] = {
		id = 3651615,
		skillTimePos = 2,
		dispelBuff = {3651127},
		overlayType = 1,
		overlayLimit = 1,
		lifeRoundType = 6
	},
	[3651616] = {
		id = 3651616,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 7, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 2, ['value'] = 'self:specialDamage()*0.4', ['cfgId'] = 3651121, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}}
	},
	[3651617] = {
		id = 3651617,
		overlayType = 2,
		overlayLimit = 4
	},
	[3651621] = {
		id = 3651621,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 1, ['cfgId'] = 3651622, ['caster'] = 2, ['value'] = 1, ['prob'] = 'target2:hasBuff(3651121) and 1 or 0', __size = 6}}, {{['holder'] = 8, ['lifeRound'] = 1, ['cfgId'] = 3651623, ['caster'] = 2, ['value'] = 'self:specialDamage()*(0.3+0.001*fromSkillLevel-0.001)', ['prob'] = 'target2:hasBuff(3651121) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[3651622] = {
		id = 3651622,
		easyEffectFunc = 'jinghua1',
		group = 65004,
		dispelType = {3, 1},
		overlayType = 1,
		overlayLimit = 1,
		onceEffectWait = true,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3300000, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3651623] = {
		id = 3651623,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['natureType'] = 2, ['damageType'] = 2, ['processId'] = 3002, __size = 3}, '{damageType=2;natureType=6;processId=3006}>', '<self:specialDamage()*(0.3+0.001*fromSkillLevel-0.001);self:specialDamage()*(0.3+0.001*fromSkillLevel-0.001)'},
		buffFlag = {4021}
	},
	[3651631] = {
		id = 3651631,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 99, ['cfgId'] = 3651632, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, ['prob'] = '(trigger.obj.force == self:force() and (target2:natureIntersection(list(2)) or target2:natureIntersection(list(3))))  and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}}
	},
	[3651632] = {
		id = 3651632,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 7, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 1, ['cfgId'] = 3651633, ['caster'] = 2, ['value'] = 1, ['prob'] = 'target2:hasBuff(3651121) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3651634, ['caster'] = 2, ['value'] = 'countObjByBuffExGroup(3-self:force(),list(3651633),list(),list(c.egg_undeath_oc()))*300', ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 3651635, ['caster'] = 2, ['value'] = 1, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}}
	},
	[3651633] = {
		id = 3651633,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['delSelfWhenTriggered'] = 2, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3651634] = {
		id = 3651634,
		easyEffectFunc = 'finalDamageAdd',
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['delSelfWhenTriggered'] = 2, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[3651635] = {
		id = 3651635,
		skillTimePos = 2,
		overlayType = 2,
		overlayLimit = 3,
		iconResPath = 'battle/buff_icon/logo_zqnl.png',
		effectResPath = 'koudai_boerkainien/hero_boerkainien.skel',
		effectAniName = {'1_loop2', '2_loop2', '3_loop2', '4_loop', '5_loop', '6_loop', '7_loop', '8_loop', '9_loop', '10_loop'},
		effectAniChoose = {['mapping'] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}, ['type'] = 1, __size = 2},
		effectPos = 1,
		effectOffsetPos = {['y'] = 30, ['x'] = 0, __size = 2},
		onceEffectResPath = 'koudai_boerkainien/hero_boerkainien.skel',
		onceEffectAniName = 'zhengqidongli',
		onceEffectPos = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 99, ['cfgId'] = 3651636, ['caster'] = 2, ['value'] = {1, 99, 1}, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 20}
	},
	[3651636] = {
		id = 3651636,
		easyEffectFunc = 'alterDmgRecordVal',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['finalRate'] = {'setValue(list("finalDamageAdd"),((attacker:curSkill():getNatureType()==3 or attacker:curSkill():getNatureType()==2)   and target:hasBuff(3651121)  and attacker:curSkill():getSkillType2() == 2) and list(env:finalDamageAdd()*10000+1000) or  list(env:finalDamageAdd()*10000 ) )'}, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[3651640] = {
		id = 3651640,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 3651641, ['caster'] = 1, ['value'] = 'self2:specialDamage()', ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1
	},
	[3651641] = {
		id = 3651641,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3651642] = {
		id = 3651642,
		easyEffectFunc = 'buffRecord',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {-1, 'target:BhpMax()*3'},
		noDelWhenFakeDeath = 1
	},
	[3651643] = {
		id = 3651643,
		easyEffectFunc = 'buffRecord',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {-2, 'target:Bdamage()*1.5'},
		noDelWhenFakeDeath = 1
	},
	[3651644] = {
		id = 3651644,
		easyEffectFunc = 'buffRecord',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {-3, 'target:BspecialDamage()*1.5'},
		noDelWhenFakeDeath = 1
	},
	[3651645] = {
		id = 3651645,
		easyEffectFunc = 'buffRecord',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {-4, 'target:Bdefence()*3'},
		noDelWhenFakeDeath = 1
	},
	[3651646] = {
		id = 3651646,
		easyEffectFunc = 'buffRecord',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {-5, 'target:BspecialDefence()*3'},
		noDelWhenFakeDeath = 1
	},
	[3651647] = {
		id = 3651647,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 9999, ['cfgId'] = 3651648, ['caster'] = 2, ['value'] = {99, 3, 0, 0, 1}, ['prob'] = '(not self:hasBuff(3651653)) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'self:hasBuff(3651652) and (not self:hasBuff(3651653))'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 3651654, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 42, ['nodeId'] = 2, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[3651648] = {
		id = 3651648,
		easyEffectFunc = 'lockHp',
		overlayLimit = 1,
		specialVal = {'not self:hasBuff(3651653)'},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 99, ['cfgId'] = 3651652, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9998, 9999},
		iconShowType = {1, 10},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3651649] = {
		id = 3651649,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 3, ['value'] = {3652, -1, 0, 1, 1, {['rebound'] = 0, ['hpMax'] = -1, ['damage'] = -2, ['specialDamage'] = -3, ['specialDefence'] = -5, ['defence'] = -4, __size = 6}}, ['cfgId'] = 3651650, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9998, 9999}
	},
	[3651650] = {
		id = 3651650,
		easyEffectFunc = 'summon',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0, 0},
		specialTarget = {2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {3001, 3006, 9998, 9999}
	},
	[3651651] = {
		id = 3651651,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {3001, 3006, 9998, 9999}
	},
	[3651652] = {
		id = 3651652,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9998, 9999}
	},
	[3651653] = {
		id = 3651653,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9998, 9999}
	},
	[3651654] = {
		id = 3651654,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 5, ['cfgId'] = 3651655, ['caster'] = 2, ['value'] = 'target2:id()', ['prob'] = 1, __size = 6}}, {{['holder'] = 11, ['lifeRound'] = 1, ['cfgId'] = 3651656, ['caster'] = 2, ['value'] = {1}, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForceBack()', ['process'] = 'random(20)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3651657, ['caster'] = 2, ['value'] = {'exactSeat(self:force(),5)', 3652, 0, 0, 0, 2}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {3001, 3006, 9998, 9999}
	},
	[3651655] = {
		id = 3651655,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {3001, 3006, 9998, 9999}
	},
	[3651656] = {
		id = 3651656,
		easyEffectFunc = 'backStage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9998, 9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3651657] = {
		id = 3651657,
		easyEffectFunc = 'frontStage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {20},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9998, 9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3651658] = {
		id = 3651658,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['onSomeFlag'] = {'trigger.buffCfgId==3651657'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 3651660, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForceBack()', ['process'] = 'battleFlagDiffer(\'battleFlag\', {3651})', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 3651653, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 35, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {3001, 3006, 9998, 9999}
	},
	[3651659] = {
		id = 3651659,
		skillTimePos = 2,
		group = 81008,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {3001, 3006, 9998, 9999}
	},
	[3651660] = {
		id = 3651660,
		skillTimePos = 2,
		group = 81008,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'trigger.overType==1 or trigger.overType==6'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3651662, ['caster'] = 1, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 2, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 3651661, ['caster'] = 1, ['value'] = {1, 1, 0}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 2,
		buffFlag = {3001, 3006, 9998, 9999},
		roundInherit = {['gameEnd'] = 2, ['wave'] = 2, __size = 2}
	},
	[3651661] = {
		id = 3651661,
		easyEffectFunc = 'lockHp',
		skillTimePos = 2,
		group = 81008,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3651662, ['caster'] = 1, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {3001, 3006, 9998, 9999}
	},
	[3651662] = {
		id = 3651662,
		skillTimePos = 2,
		group = 81008,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 11, ['lifeRound'] = 1, ['cfgId'] = 3651663, ['caster'] = 2, ['value'] = {1}, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForceBack()', ['process'] = 'buffDiffer(\'id\',{3651655})|random(12)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3651664, ['caster'] = 2, ['value'] = {'(target2:hasBuff(3651655) and target2:getBuff(3651655):getValue() or 0)', 'target2:unitID()', 0, 0, 0, 2}, ['prob'] = 1, __size = 6}}, {{['holder'] = 11, ['lifeRound'] = 1, ['cfgId'] = 3651665, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForceBack()', ['process'] = 'buffDiffer(\'id\',{3651655})|random(12)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 3651665, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {3001, 3006, 9998, 9999}
	},
	[3651663] = {
		id = 3651663,
		easyEffectFunc = 'backStage',
		skillTimePos = 2,
		group = 81008,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9998, 9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3651664] = {
		id = 3651664,
		easyEffectFunc = 'frontStage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {20},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9998, 9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[3651665] = {
		id = 3651665,
		skillTimePos = 2,
		group = 81008,
		dispelBuff = {3651655, 3651648},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {3001, 3006, 9998, 9999}
	},
	[3651670] = {
		id = 3651670,
		skillTimePos = 2,
		group = 80008,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 35, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3651671, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3651672, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3651673, ['caster'] = 2, ['value'] = {2, 99, 1}, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3651674, ['caster'] = 2, ['value'] = {2, 99, 2}, ['prob'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 3651675, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {3001, 3006, 9998}
	},
	[3651671] = {
		id = 3651671,
		skillTimePos = 2,
		group = 81008,
		overlayLimit = 1,
		holderActionType = {['typ'] = 'hideGroundRing', __size = 1},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9998}
	},
	[3651672] = {
		id = 3651672,
		skillTimePos = 2,
		group = 81008,
		overlayLimit = 1,
		holderActionType = {['typ'] = 'hideGroupObj', __size = 1},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9998}
	},
	[3651673] = {
		id = 3651673,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		group = 81008,
		overlayLimit = 1,
		specialVal = {{['calcInternalDamageFinish'] = {'setValue(list("calFinalDamage"),exitInTab(processId,list(3002,3003,3005,3006,3008)) and list(calFinalDamage*0) or list(calFinalDamage*1))'}, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {3001, 3006, 9998}
	},
	[3651674] = {
		id = 3651674,
		easyEffectFunc = 'alterDmgRecordVal',
		group = 81008,
		overlayLimit = 1,
		specialVal = {{['groupShield'] = 2, __size = 1}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {3001, 3006, 9998}
	},
	[3651675] = {
		id = 3651675,
		skillTimePos = 2,
		group = 81008,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 1, ['cfgId'] = 3651676, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 6,
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9998}
	},
	[3651676] = {
		id = 3651676,
		group = 81008,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 6, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 3651677, ['caster'] = 2, ['value'] = 1, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 5}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 6,
		noDelWhenFakeDeath = 1
	},
	[3651677] = {
		id = 3651677,
		easyEffectFunc = 'atOnceBattleRound',
		skillTimePos = 2,
		group = 81008,
		overlayType = 1,
		overlayLimit = 1,
		iconShowType = {1, 10}
	},
	[3651691] = {
		id = 3651691,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 38, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferExclude(\'group\',{c.fly_notbuff_oc()})|random(1)', __size = 2}, ['lifeRound'] = 2, ['value'] = 'self:specialDamage()*0.4', ['cfgId'] = 3651121, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[4023111] = {
		id = 4023111,
		name = '索尔迦雷欧',
		easyEffectFunc = 'defence',
		group = 1021,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_up.png',
		textResPath = 'battle/txt/txt_wftg.png'
	},
	[4023112] = {
		id = 4023112,
		easyEffectFunc = 'defence',
		group = 1021,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_up.png',
		textResPath = 'battle/txt/txt_wftg.png'
	},
	[4023211] = {
		id = 4023211,
		skillTimePos = 2,
		group = 3301,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_lyk.png',
		effectResPath = 'koudai_suoerjialeiou/hero_suoerjialeiou.skel',
		effectAniName = {'buff_lieyangkai_loop'},
		effectOffsetPos = {['y'] = 0, ['x'] = -100, __size = 2},
		textResPath = 'battle/txt/txt_lyk.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 4023212, ['caster'] = 2, ['value'] = 'self:defence()*3', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 4023213, ['caster'] = 2, ['value'] = 1500, ['bond'] = 1, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		iconShowType = {0, 20},
		skinEffect = {[4123] = 4023211, __size = 1}
	},
	[4023212] = {
		id = 4023212,
		easyEffectFunc = 'shield',
		skillTimePos = 2,
		group = 9003,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {0, 0, 10, {3, 0, 0.3}},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'more(buff:getFinalLifeRound(),0)'}, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 4023214, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1, 1}, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 19, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 4023215, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {3010}
	},
	[4023213] = {
		id = 4023213,
		easyEffectFunc = 'damageSub',
		skillTimePos = 2,
		group = 1025,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjm_up.png',
		textResPath = 'battle/txt/txt_shjmtg.png'
	},
	[4023214] = {
		id = 4023214,
		easyEffectFunc = 'counterAttack',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{40237}, 0},
		specialTarget = {{['input'] = 'selfForce|nodead', ['process'] = 'buffDiffer(\'id\',{4023211})', __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023215] = {
		id = 4023215,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 42, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 4023216, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[4023216] = {
		id = 4023216,
		dispelBuff = {4023211},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[4023221] = {
		id = 4023221,
		skillTimePos = 2,
		group = 9300,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tcdk.png',
		textResPath = 'battle/txt/txt_tcdk.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 4023222, ['caster'] = 2, ['value'] = 'self:Bdefence()*0.3', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 4023223, ['caster'] = 2, ['value'] = 'self:BspecialDefence()*0.3', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 4023224, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1, 1}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4023224, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1, 1}, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 4023225, ['caster'] = 2, ['value'] = 0, ['bond'] = 2, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4023225, ['caster'] = 2, ['value'] = 0, ['bond'] = 2, ['prob'] = 1, __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		iconShowType = {1, 20}
	},
	[4023222] = {
		id = 4023222,
		easyEffectFunc = 'defence',
		skillTimePos = 2,
		group = 1021,
		overlayType = 1,
		overlayLimit = 1
	},
	[4023223] = {
		id = 4023223,
		easyEffectFunc = 'specialDefence',
		skillTimePos = 2,
		group = 1022,
		overlayType = 1,
		overlayLimit = 1
	},
	[4023224] = {
		id = 4023224,
		easyEffectFunc = 'counterAttack',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{40237}, 0},
		specialTarget = {{['input'] = 'selfForce|nodead', ['process'] = 'exclude(list(csvSelectObj:id()))|buffDiffer(\'id\',{4023225})', __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'getExtraRoundId()==4023224'}, ['triggerPoint'] = 23, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4023227, ['caster'] = 1, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, __size = 6}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023225] = {
		id = 4023225,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[4023226] = {
		id = 4023226,
		dispelBuff = {4023225, 4023227},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[4023227] = {
		id = 4023227,
		overlayType = 6,
		overlayLimit = 2,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'target:getBuffOverlayCount(4023227)==2'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'buffDiffer(\'id\',{4023225})', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 4023226, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['triggerPoint'] = 1, ['nodeId'] = 1, __size = 5}}
	},
	[4023311] = {
		id = 4023311,
		easyEffectFunc = 'sneer',
		skillTimePos = 2,
		group = 408,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tx.png',
		effectResPath = 'buff/chaofeng/beichaofeng.skel',
		effectAniName = {'beichaofeng_loop'},
		effectPos = 1,
		effectOffsetPos = {['y'] = -300, ['x'] = 0, __size = 2},
		textResPath = 'battle/txt/txt_cf.png',
		specialVal = {0},
		ignoreCaster = {1},
		iconShowType = {1, 10}
	},
	[4023321] = {
		id = 4023321,
		skillTimePos = 2,
		group = 5306,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_xrzt.png',
		textResPath = 'battle/txt/txt_xrzt.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4023322, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4023645, ['caster'] = 2, ['value'] = 'self:damage()*0.3+(self:hasBuff(4023645) and self:getBuff(4023645):getValue() or 0)', ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4023323, ['caster'] = 2, ['value'] = 'self:damage()', ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4023324, ['caster'] = 2, ['value'] = 'self:specialDamage()', ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4023326, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}, {{['holder'] = 11, ['lifeRound'] = 999, ['cfgId'] = 4023341, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = '(moreE(self:star(),11) and (target2:natureIntersection(list(17)) or target2:natureIntersection(list(11)))) and 1 or 0', __size = 7}}, {{['holder'] = 14, ['lifeRound'] = 999, ['cfgId'] = 4023325, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 14, ['lifeRound'] = 999, ['cfgId'] = 4023343, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'moreE(self:star(),11) and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}},
		lifeRoundType = 3,
		buffFlag = {1012},
		iconShowType = {1, 20},
		spineEffect = {['skin'] = 'xr', ['unitRes'] = {'koudai_suoerjialeiou/hero_suoerjialeiou.skel', 'koudai_sejlopifu/hero_sejlopifu.skel'}, __size = 2}
	},
	[4023322] = {
		id = 4023322,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[4023323] = {
		id = 4023323,
		easyEffectFunc = 'defence',
		skillTimePos = 2,
		group = 1021,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_up.png',
		textResPath = 'battle/txt/txt_wftg.png',
		iconShowType = {1, 10}
	},
	[4023324] = {
		id = 4023324,
		easyEffectFunc = 'specialDefence',
		skillTimePos = 2,
		group = 1022,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_tf_up.png',
		textResPath = 'battle/txt/txt_tftg.png',
		iconShowType = {1, 10}
	},
	[4023325] = {
		id = 4023325,
		skillTimePos = 2,
		group = 61005,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[4023326] = {
		id = 4023326,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[4023331] = {
		id = 4023331,
		skillTimePos = 2,
		group = 13301,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_dq.png',
		textResPath = 'battle/txt/txt_dq.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 7, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 4023332, ['caster'] = 8, ['value'] = -2000, ['prob'] = '(self2:flag(4023) or self2:flag(4123)) and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 4023333, ['caster'] = 8, ['value'] = 2000, ['prob'] = '(self2:flag(4023) or self2:flag(4123)) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		iconShowType = {0, 20}
	},
	[4023332] = {
		id = 4023332,
		easyEffectFunc = 'strike',
		skillTimePos = 2,
		group = 11006,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_bjljd.png',
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[4023333] = {
		id = 4023333,
		easyEffectFunc = 'damageReduce',
		skillTimePos = 2,
		group = 11005,
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_shjd.png',
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[4023341] = {
		id = 4023341,
		group = 9300,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 4023342, ['caster'] = 2, ['value'] = {0.3, 2, 101}, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[4023342] = {
		id = 4023342,
		easyEffectFunc = 'damageAllocate',
		group = 9300,
		overlayType = 1,
		overlayLimit = 1,
		buffFlag = {2001}
	},
	[4023343] = {
		id = 4023343,
		skillTimePos = 2,
		group = 71008,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[4023351] = {
		id = 4023351,
		easyEffectFunc = 'replaceSkill',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[4023352] = {
		id = 4023352,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['processId'] = 5, ['damageType'] = 2, __size = 2}},
		buffFlag = {4021}
	},
	[4023611] = {
		id = 4023611,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 4023612, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1, 1, 3}, ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 4023613, ['caster'] = 2, ['value'] = {}, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023612] = {
		id = 4023612,
		easyEffectFunc = 'counterAttack',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{40237}, 0},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023613] = {
		id = 4023613,
		easyEffectFunc = 'ignoreSpecBuff',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{'counterAttack', 'prophet'}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023621] = {
		id = 4023621,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 4023622, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 4023625, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023622] = {
		id = 4023622,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 14, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 4023626, ['caster'] = 15, ['value'] = '1000+(skillLv(40236) or 0)*10-10', ['prob'] = 'less(self2:defence(),target2:defence()) and 1 or 0', __size = 6}}}, ['extraAttackTrigger'] = 2, ['nodeId'] = 1, __size = 5}, {['onSomeFlag'] = {'less(target:getBuffOverlayCount(4023623),3)'}, ['triggerPoint'] = 10, ['nodeId'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4023624, ['caster'] = 15, ['value'] = 'self:defence()*(1+(skillLv(40236) or 0)*0.002-0.002)', ['prob'] = 1, __size = 6}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff'}, __size = 6}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023623] = {
		id = 4023623,
		overlayType = 2,
		overlayLimit = 3,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023624] = {
		id = 4023624,
		easyEffectFunc = 'shield',
		skillTimePos = 2,
		group = 9001,
		overlayType = 6,
		overlayLimit = 99,
		iconResPath = 'battle/buff_icon/logo_hd.png',
		effectResPath = 'buff/hudun/hudun.skel',
		effectAniName = {'hudun_loop'},
		textResPath = 'battle/txt/txt_hd.png',
		specialVal = {0, 0, 10, {3, 0, 0.3}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 4023623, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {3010}
	},
	[4023625] = {
		id = 4023625,
		group = 80030,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023626] = {
		id = 4023626,
		easyEffectFunc = 'finalDamageSub',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[4023630] = {
		id = 4023630,
		easyEffectFunc = 'aura',
		overlayType = 1,
		overlayLimit = 1,
		specialTarget = {{['input'] = 'selfForce()|nodead', ['process'] = 'attrDiffer("natureType", {11,17})', __size = 2}},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 20, ['lifeRound'] = 999, ['cfgId'] = 4023631, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, ['prob'] = 'not target2:flag(20006) and trigger.obj.force == self:force() and 1 or 0', __size = 7}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1
	},
	[4023631] = {
		id = 4023631,
		group = 1030001,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['onSomeFlag'] = {'less(self:getBuffOverlayCount(4023636),5)'}, ['funcArgs'] = {{{['holder'] = 16, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 4023634, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 4023632, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 4023633, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1, 'list(40235)'}, ['prob'] = 'target2:flag(4023) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 4023633, ['caster'] = 2, ['value'] = {'list(1,0,0)', 1, 1, 'list(41235)'}, ['prob'] = 'target2:flag(4123) and 1 or 0', __size = 6}}}, ['triggerPoint'] = 13, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023632] = {
		id = 4023632,
		group = 60030,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 4023635, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[4023633] = {
		id = 4023633,
		easyEffectFunc = 'assistAttack',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_gtfc.png',
		specialTarget = {{['input'] = 'And(enemyForce(),enemyForceEx())|nodead', ['process'] = 'buffDiffer(\'id\',{4023634})', __size = 2}},
		buffFlag = {1021}
	},
	[4023634] = {
		id = 4023634,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 3}}
	},
	[4023635] = {
		id = 4023635,
		group = 70025,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 3
	},
	[4023636] = {
		id = 4023636,
		overlayType = 2,
		overlayLimit = 99,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023637] = {
		id = 4023637,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {2031}
	},
	[4023641] = {
		id = 4023641,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['onSomeFlag'] = {'not self:hasBuff(4023642) and lessE(self:hp(),self:hpMax()*0.3)'}, ['triggerPoint'] = 32, ['nodeId'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 0, ['cfgId'] = 4023642, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 4023643, ['caster'] = 2, __size = 5}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff'}, __size = 6}, {['onSomeFlag'] = {'not self:hasBuff(4023642) and lessE(self:hp(),self:hpMax()*0.3)'}, ['triggerPoint'] = 42, ['nodeId'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 0, ['cfgId'] = 4023642, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 4023643, ['caster'] = 2, __size = 5}}}, ['extraAttackTrigger'] = 2, ['effectFuncs'] = {'castBuff', 'castBuff'}, __size = 6}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023642] = {
		id = 4023642,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023643] = {
		id = 4023643,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 'min(self:hpMax()*0.3,self:damage()*3)', ['cfgId'] = 4023644, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 'min(self:getBuff(4023645):getValue(),self:defence())', ['cfgId'] = 4023646, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 2, ['value'] = {0, 2, 3, 'list()', 15}, ['cfgId'] = 4023647, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 2, ['value'] = 0, ['cfgId'] = 4023321, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 4023651, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:flagZ4() and 1 or 0', __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 2, ['cfgId'] = 4023652, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:flagZ4() and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}}
	},
	[4023644] = {
		id = 4023644,
		easyEffectFunc = 'addHP',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {2031}
	},
	[4023645] = {
		id = 4023645,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 3,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023646] = {
		id = 4023646,
		easyEffectFunc = 'defence',
		group = 5002,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_wf_up.png',
		textResPath = 'battle/txt/txt_jyjs.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023647] = {
		id = 4023647,
		easyEffectFunc = 'lockHp',
		overlayType = 1,
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_bqzz.png',
		specialVal = {'less(attacker:damage(),target:defence())'},
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 3,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2},
		spineEffect = {['action'] = {['standby'] = 'standby_loop2', __size = 1}, ['unitRes'] = {'koudai_suoerjialeiou/hero_suoerjialeiou.skel', 'koudai_sejlopifu/hero_sejlopifu.skel'}, __size = 2}
	},
	[4023651] = {
		id = 4023651,
		group = 60030,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 4023211, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:flagZ4() and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeRoundType = 3,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023652] = {
		id = 4023652,
		group = 70025,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeRoundType = 3,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4023711] = {
		id = 4023711,
		easyEffectFunc = 'defence',
		group = 10021,
		overlayType = 2,
		overlayLimit = 3,
		iconResPath = 'battle/buff_icon/logo_wf_down.png',
		textResPath = 'battle/txt/txt_wfjd.png'
	},
	[4024111] = {
		id = 4024111,
		name = '露奈雅拉',
		easyEffectFunc = 'addHpMax',
		skillTimePos = 2,
		group = 1082,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_smsx_up.png',
		textResPath = 'battle/txt/txt_smsxtg.png',
		specialVal = {{['effectHp'] = true, __size = 1}}
	},
	[4024211] = {
		id = 4024211,
		easyEffectFunc = 'stealth',
		skillTimePos = 2,
		group = 9101,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_ys.png',
		holderActionType = {['typ'] = 'opacity', ['args'] = {['value'] = 0.5, __size = 1}, __size = 2},
		textResPath = 'battle/txt/txt_ys1.png',
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 4024321, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		iconShowType = {1, 10}
	},
	[4024212] = {
		id = 4024212,
		easyEffectFunc = 'addHP',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031}
	},
	[4024311] = {
		id = 4024311,
		skillTimePos = 2,
		group = 406,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_guyue.png',
		effectResPath = 'koudai_lunaiyala/hero_lunaiyala.skel',
		effectAniName = {'buff_guyue_loop'},
		textResPath = 'battle/txt/txt_guyue.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 4024312, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 4024313, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		skinEffect = {[4124] = 4024311, __size = 1}
	},
	[4024312] = {
		id = 4024312,
		skillTimePos = 2,
		immuneBuff = {3601139, 3601133, 3611171},
		dispelBuff = {3601139, 3601133, 3611171},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[4024313] = {
		id = 4024313,
		easyEffectFunc = 'filterFlag',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['selfForce'] = {3006}, ['allForce'] = {}, ['enemyForce'] = {'all'}, ['self'] = {'all'}, __size = 4}},
		ignoreHolder = 1,
		ignoreCaster = {1},
		buffFlag = {3001}
	},
	[4024320] = {
		id = 4024320,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferOptional(\'id\',{4024311})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 4024321, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferOptional(\'id\',{4024311})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 4024321, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferOptional(\'id\',{4024311})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 4024321, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferOptional(\'id\',{4024311})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 4024321, ['caster'] = 2, ['value'] = 0, ['prob'] = 'moreE(self:star(),11) and moreE(self:getBuffOverlayCount(4024333),1) and 1 or 0', __size = 6}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferOptional(\'id\',{4024311})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 4024321, ['caster'] = 2, ['value'] = 0, ['prob'] = 'moreE(self:star(),11) and moreE(self:getBuffOverlayCount(4024333),2) and 1 or 0', __size = 6}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'buffDifferOptional(\'id\',{4024311})|random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 4024321, ['caster'] = 2, ['value'] = 0, ['prob'] = 'moreE(self:star(),11) and moreE(self:getBuffOverlayCount(4024333),3) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024321] = {
		id = 4024321,
		skillTimePos = 2,
		overlayType = 6,
		overlayLimit = 99,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['cfgId'] = 4024322, ['caster'] = 2, ['value'] = 'min(self:hpMax()*0.06,self:specialDamage()*3)*(1+0.2*self:getBuffOverlayCount(4024333)*(self:flagZ3() and 1 or 0))', ['prob'] = 'isSoloFightType() and less(target:getBuffOverlayCount(4024322),2) and 1 or ((not isSoloFightType()) and 1 or 0)', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024322] = {
		id = 4024322,
		easyEffectFunc = 'buffDamage',
		skillTimePos = 2,
		overlayType = 6,
		overlayLimit = 99,
		onceEffectResPath = 'koudai_lunaiyala/hero_lunaiyala.skel',
		onceEffectAniName = 'buff_yuehua',
		specialVal = {{['processId'] = 30, ['damageType'] = 1, __size = 2}},
		ignoreCaster = {1},
		lifeRoundType = 2,
		buffFlag = {4021},
		skinEffect = {[4124] = 4024322, __size = 1}
	},
	[4024331] = {
		id = 4024331,
		skillTimePos = 2,
		group = 9300,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_myzt.png',
		textResPath = 'battle/txt/txt_myzt.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 4024320, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024332, ['caster'] = 2, ['value'] = '1000+(skillLv(40246) or 0)*10-10', ['bond'] = 1, ['prob'] = 1, __size = 7}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024333, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 8, ['funcArgs'] = {{{['holder'] = 8, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 4024321, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'self:getBuffOverlayCount(4024333)==1'}, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'attrDiffer(\'natureType\', {14})', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 4024334, ['caster'] = 2, ['value'] = {1, 1, 1}, ['prob'] = 'self:flagZ3() and 1 or 0', __size = 6}}}, ['triggerPoint'] = 2, ['nodeId'] = 3, __size = 5}},
		buffFlag = {1012},
		spineEffect = {['skin'] = 'manyue', ['unitRes'] = {'koudai_lunaiyala/hero_lunaiyala.skel'}, __size = 2}
	},
	[4024332] = {
		id = 4024332,
		easyEffectFunc = 'damageSub',
		skillTimePos = 2,
		group = 1125,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shjm_up.png',
		textResPath = 'battle/txt/txt_shjmtg.png',
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[4024333] = {
		id = 4024333,
		skillTimePos = 2,
		overlayType = 2,
		overlayLimit = 3,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024334] = {
		id = 4024334,
		easyEffectFunc = 'stealth',
		group = 9101,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_ys.png',
		holderActionType = {['typ'] = 'opacity', ['args'] = {['value'] = 0.5, __size = 1}, __size = 2},
		textResPath = 'battle/txt/txt_ys1.png',
		iconShowType = {1, 10}
	},
	[4024610] = {
		id = 4024610,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'buff/lunaiyala_buff/yuexiang.skel',
		effectAniName = {'beijing'},
		effectPos = 5,
		effectAssignLayer = 0,
		effectOffsetPos = {['y'] = 400, ['x'] = 0, __size = 2},
		deepCorrect = 19998,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2},
		skinEffect = {[4124] = 4024610, __size = 1}
	},
	[4024611] = {
		id = 4024611,
		skillTimePos = 2,
		group = 9300,
		dispelBuff = {4024621, 4024631, 4024641},
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_xinyue.png',
		effectResPath = 'buff/lunaiyala_buff/yuexiang.skel',
		effectAniName = {'suyue'},
		effectPos = 7,
		effectAssignLayer = 0,
		textResPath = 'battle/txt/txt_xinyue.png',
		deepCorrect = 19999,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024610, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'random(3)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 4024612, ['caster'] = 2, ['value'] = 150, ['prob'] = 'self:flagZ4() and 0 or 1', __size = 6}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'random(6)', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 4024612, ['caster'] = 2, ['value'] = 150, ['prob'] = 'self:flagZ4() and (not self:hasBuff(4024613)) and 1 or 0', __size = 6}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'random(1)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 4024311, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:flagZ4() and 0 or 1', __size = 6}}, {{['holder'] = {['input'] = 'enemyForce|nodead', ['process'] = 'random(3)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 4024311, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:flagZ4() and (not self:hasBuff(4024613)) and 1 or 0', __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024613, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(4024613) and 0 or 1', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 4, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 0, ['cfgId'] = 4024621, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3003},
		skinEffect = {[4124] = 4024611, __size = 1}
	},
	[4024612] = {
		id = 4024612,
		easyEffectFunc = 'addMp1Max',
		skillTimePos = 2,
		group = 13034,
		overlayType = 1,
		overlayLimit = 1,
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['triggerPoint'] = 8, ['onSkillType'] = 1, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}}
	},
	[4024613] = {
		id = 4024613,
		skillTimePos = 2,
		overlayType = 2,
		overlayLimit = 99,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024621] = {
		id = 4024621,
		skillTimePos = 2,
		group = 9300,
		dispelBuff = {4024611},
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_shangxian.png',
		effectResPath = 'buff/lunaiyala_buff/yuexiang.skel',
		effectAniName = {'xianyue_shang'},
		effectPos = 7,
		effectAssignLayer = 0,
		textResPath = 'battle/txt/txt_shangxian.png',
		deepCorrect = 19999,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024610, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 2, ['cfgId'] = 4024622, ['caster'] = 2, ['value'] = {1, 1, 1}, ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'exclude(list(csvSelf:id()))|attrDiffer(\'natureType\', {14})|attrWitOutFilter({"damage","specialDamage"},"max",2)', __size = 2}, ['lifeRound'] = 2, ['cfgId'] = 4024622, ['caster'] = 2, ['value'] = {1, 1, 1}, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 4, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 0, ['cfgId'] = 4024631, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3003},
		skinEffect = {[4124] = 4024621, __size = 1}
	},
	[4024622] = {
		id = 4024622,
		easyEffectFunc = 'stealth',
		group = 9101,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_ys.png',
		holderActionType = {['typ'] = 'opacity', ['args'] = {['value'] = 0.5, __size = 1}, __size = 2},
		textResPath = 'battle/txt/txt_ys1.png',
		iconShowType = {1, 10}
	},
	[4024631] = {
		id = 4024631,
		skillTimePos = 2,
		group = 9300,
		dispelBuff = {4024621},
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_manyue.png',
		effectResPath = 'buff/lunaiyala_buff/yuexiang.skel',
		effectAniName = {'manyue'},
		effectPos = 7,
		effectAssignLayer = 0,
		textResPath = 'battle/txt/txt_manyue.png',
		deepCorrect = 19999,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024610, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 4024320, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 4, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 0, ['cfgId'] = 4024641, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3003},
		skinEffect = {[4124] = 4024631, __size = 1}
	},
	[4024641] = {
		id = 4024641,
		skillTimePos = 2,
		group = 9300,
		dispelBuff = {4024631},
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_xiaxian.png',
		effectResPath = 'buff/lunaiyala_buff/yuexiang.skel',
		effectAniName = {'xianyue_xia'},
		effectPos = 7,
		effectAssignLayer = 0,
		textResPath = 'battle/txt/txt_xiaxian.png',
		deepCorrect = 19999,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024610, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'attrDiffer(\'natureType\', {14,11})', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 4024642, ['caster'] = 2, ['value'] = 'target:speed()*0.09', ['bond'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForce()|nodead', ['process'] = 'attrDiffer(\'natureType\', {14,11})', __size = 2}, ['lifeRound'] = 1, ['value'] = 'min(target:hpMax()*0.2,self:specialDamage()*3)', ['cfgId'] = 4024643, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 4024651, ['caster'] = 2, ['value'] = 0, ['prob'] = 'moreE(self:star(),6) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 4, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['value'] = 0, ['cfgId'] = 4024611, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3003},
		iconShowType = {0, 20},
		skinEffect = {[4124] = 4024641, __size = 1}
	},
	[4024642] = {
		id = 4024642,
		easyEffectFunc = 'speed',
		skillTimePos = 2,
		group = 1081,
		overlayType = 1,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_sd_up.png',
		textResPath = 'battle/txt/txt_sdtg.png'
	},
	[4024643] = {
		id = 4024643,
		easyEffectFunc = 'addHP',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031}
	},
	[4024651] = {
		id = 4024651,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 'min(self:specialDamage()*3,self:hpMax()*(0.2+(skillLv(40246) or 0)*0.0015-0.0015))', ['cfgId'] = 4024652, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024653, ['caster'] = 2, ['value'] = 0, ['prob'] = '1*math.pow(0.5,self:getBuffOverlayCount(4024654))*(moreE(self:getBuffOverlayCount(4024654),3) and 0 or 1)', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		buffFlag = {3003}
	},
	[4024652] = {
		id = 4024652,
		easyEffectFunc = 'addHP',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031}
	},
	[4024653] = {
		id = 4024653,
		skillTimePos = 2,
		group = 5307,
		overlayLimit = 1,
		iconResPath = 'battle/buff_icon/logo_ylyj.png',
		textResPath = 'battle/txt/txt_ylyj.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 1, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['value'] = 0, ['cfgId'] = 4024654, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3003},
		iconShowType = {0, 30},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024654] = {
		id = 4024654,
		skillTimePos = 2,
		overlayType = 2,
		overlayLimit = 99,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3003},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024711] = {
		id = 4024711,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 12, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 999, ['cfgId'] = 4024712, ['caster'] = 2, ['value'] = {0, 'self:hpMax()', 0, 8}, ['prob'] = 'not self:hasBuff(1271311) and self:hasBuff(4024653) and moreE(self:star(),6) and (self:flag(99099) and 0.5 or 1) or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024712] = {
		id = 4024712,
		easyEffectFunc = 'reborn',
		skillTimePos = 2,
		dispelBuff = {4024653},
		overlayLimit = 1,
		textResPath = 'battle/txt/txt_fh.png',
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 28, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 4024713, ['caster'] = 2, __size = 5}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 4024726, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 4024714, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 26, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'attrDiffer(\'natureType\', {14})', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 4024730, ['caster'] = 2, ['value'] = 'min(target:hpMax()*0.2,self:specialDamage()*3)', ['prob'] = 'moreE(self:star(),8) and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeTimeEnd = 0,
		noDelWhenFakeDeath = 1,
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024713] = {
		id = 4024713,
		easyEffectFunc = 'buff10',
		group = 70006,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerTimes'] = {1, 1}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024715, ['caster'] = 2, ['value'] = {99, 1}, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024716, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024717, ['caster'] = 2, ['value'] = {0, 1, 0, 0, 0, 0}, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024718, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024719, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}}, ['triggerPoint'] = 1, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 19, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = 0, ['cfgId'] = 4024720, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 2, __size = 4}},
		lifeRoundType = 2,
		noDelWhenFakeDeath = 1,
		buffFlag = {9999, 1041},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024714] = {
		id = 4024714,
		dispelBuff = {4024611, 4024621, 4024631, 4024641},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024715] = {
		id = 4024715,
		easyEffectFunc = 'keepHpUnChanged',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024716] = {
		id = 4024716,
		easyEffectFunc = 'lockMp1Add',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024717] = {
		id = 4024717,
		easyEffectFunc = 'depart',
		overlayType = 1,
		overlayLimit = 1,
		holderActionType = {['typ'] = 'opacity', ['args'] = {['value'] = 0.4, __size = 1}, __size = 2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024718] = {
		id = 4024718,
		easyEffectFunc = 'stun',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024719] = {
		id = 4024719,
		easyEffectFunc = 'stun',
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'koudai_lunaiyala/hero_lunaiyala.skel',
		effectAniName = {'buff_yueying_loop'},
		holderActionType = {['typ'] = 'hide', ['args'] = {['sprite'] = {['isShow'] = false, __size = 1}, ['lifebar'] = {['isShow'] = false, __size = 1}, __size = 2}, __size = 2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2},
		skinEffect = {[4124] = 4024719, __size = 1}
	},
	[4024720] = {
		id = 4024720,
		easyEffectFunc = 'buff10',
		group = 70006,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerTimes'] = {1, 1}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024721, ['caster'] = 2, ['value'] = {99, 1}, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024722, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024723, ['caster'] = 2, ['value'] = {0, 1, 0, 0, 0, 0}, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024724, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024725, ['caster'] = 2, ['value'] = 0, ['bond'] = 1, __size = 6}}}, ['triggerPoint'] = 1, ['nodeId'] = 1, __size = 5}, {['effectFuncs'] = {'castBuff', 'castBuff'}, ['triggerPoint'] = 19, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['cfgId'] = 4024611, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 4024331, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:flagZ4() and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}},
		lifeTimeEnd = 0,
		noDelWhenFakeDeath = 1,
		buffFlag = {9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024721] = {
		id = 4024721,
		easyEffectFunc = 'keepHpUnChanged',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeTimeEnd = 0,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024722] = {
		id = 4024722,
		easyEffectFunc = 'lockMp1Add',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeTimeEnd = 0,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024723] = {
		id = 4024723,
		easyEffectFunc = 'depart',
		overlayType = 1,
		overlayLimit = 1,
		holderActionType = {['typ'] = 'opacity', ['args'] = {['value'] = 0.5, __size = 1}, __size = 2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeTimeEnd = 0,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024724] = {
		id = 4024724,
		easyEffectFunc = 'stun',
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 2, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 4024727, ['caster'] = 2, ['value'] = 0, ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 4024728, ['caster'] = 2, ['value'] = 'self:hpMax()*(0.2+(skillLv(40246) or 0)*0.0015-0.0015)', ['prob'] = 1, __size = 6}}, {{['holder'] = 2, ['lifeRound'] = 1, ['cfgId'] = 4024729, ['caster'] = 2, ['value'] = 'self:mp1Max()*(0.2+(skillLv(40246) or 0)*0.0015-0.0015)', ['prob'] = 1, __size = 6}}, {{['holder'] = {['input'] = 'selfForceBack()', ['process'] = 'buffDiffer(\'id\',{4024811})|random(12)', __size = 2}, ['lifeRound'] = 1, ['cfgId'] = 4024813, ['caster'] = 2, ['value'] = {'target2:getBuff(4024811):getValue()', 'target2:originUnitId()', 0, 0, 1, 2}, ['prob'] = 'moreE(self:star(),8) and getExtraRoundMode()~=8 and getExtraRoundMode()~=9 and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		lifeTimeEnd = 0,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024725] = {
		id = 4024725,
		easyEffectFunc = 'stun',
		overlayType = 1,
		overlayLimit = 1,
		effectResPath = 'koudai_lunaiyala/hero_lunaiyala.skel',
		effectAniName = {'buff_yueying_loop'},
		holderActionType = {['typ'] = 'hide', ['args'] = {['sprite'] = {['isShow'] = false, __size = 1}, ['lifebar'] = {['isShow'] = false, __size = 1}, __size = 2}, __size = 2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		lifeTimeEnd = 0,
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2},
		skinEffect = {[4124] = 4024725, __size = 1}
	},
	[4024726] = {
		id = 4024726,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_lunaiyala/hero_lunaiyala.skel',
		onceEffectAniName = 'buff_yueying_chuxian',
		ignoreHolder = 1,
		ignoreCaster = {1},
		skinEffect = {[4124] = 4024726, __size = 1}
	},
	[4024727] = {
		id = 4024727,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		onceEffectResPath = 'koudai_lunaiyala/hero_lunaiyala.skel',
		onceEffectAniName = 'buff_yueying_xiaoshi',
		ignoreHolder = 1,
		ignoreCaster = {1},
		skinEffect = {[4124] = 4024727, __size = 1}
	},
	[4024728] = {
		id = 4024728,
		easyEffectFunc = 'addHP',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['ignoreLockResume'] = true, ['ignoreToDamage'] = true, ['ignoreHealAddRate'] = true, ['ignoreBeHealAddRate'] = true, __size = 4}},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[4024729] = {
		id = 4024729,
		easyEffectFunc = 'addMp1',
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {{['ignoreLockMp1Add'] = true, ['ignoreMp1Recover'] = true, __size = 2}},
		ignoreHolder = 1,
		ignoreCaster = {1}
	},
	[4024730] = {
		id = 4024730,
		easyEffectFunc = 'addHP',
		overlayType = 1,
		overlayLimit = 1,
		onceEffectAniName = 'zhiliao_lv',
		textResPath = 'battle/txt/txt_hf.png',
		buffFlag = {2031}
	},
	[4024810] = {
		id = 4024810,
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 32, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'attrDiffer(\'natureType\', {14,11})', __size = 2}, ['lifeRound'] = 99, ['cfgId'] = 4024817, ['caster'] = 2, ['value'] = '500+(skillLv(40246,41246) or 0)*10-10', ['prob'] = 'target2:hasBuffGroup(c.yinshen_oc()) and 1 or 0', __size = 6}}, {{['holder'] = 11, ['lifeRound'] = 999, ['cfgId'] = 4024821, ['caster'] = 2, ['value'] = 0, ['prob'] = 'target2:hasBuffGroup(c.yinshen_oc()) and 1 or 0', __size = 6}}, {{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'attrDiffer(\'natureType\', {14})', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 4024822, ['caster'] = 2, ['value'] = {1, 2, 1}, ['prob'] = 'moreE(self:star(),11) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 3, ['funcArgs'] = {{{['holder'] = {['input'] = 'selfForce|nodead', ['process'] = 'exclude(list(csvSelf:id()))|buffDifferExclude(\'id\',{4683853})|attrDiffer(\'natureType\', {14})', __size = 2}, ['lifeRound'] = 999, ['cfgId'] = 4024811, ['caster'] = 2, ['value'] = 'target2:id()', ['prob'] = 'moreE(self:star(),8) and (not target2:hasBuff(4683853)) and 1 or 0', __size = 6}}}, ['nodeId'] = 2, __size = 4}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024811] = {
		id = 4024811,
		easyEffectFunc = 'buffRecord',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {'realFakeDeath', 3},
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 13, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 2, ['value'] = 0, ['cfgId'] = 4024818, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 1, ['value'] = {0, 'target:hpMax()*(self:flagZ4() and 0.4 or 0.35)', 'target:mp1Max()*(self:flagZ4() and 0.4 or 0.35)', 7}, ['cfgId'] = 4024814, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 99, ['value'] = {1}, ['cfgId'] = 4024819, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 99, ['value'] = {0, 0, 0, 0, 1, 1}, ['cfgId'] = 4024820, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024812] = {
		id = 4024812,
		easyEffectFunc = 'backStage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024813] = {
		id = 4024813,
		easyEffectFunc = 'frontStage',
		skillTimePos = 2,
		dispelBuff = {4024819, 4024820},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff', 'castBuff', 'castBuff'}, ['triggerPoint'] = 35, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 4024815, ['caster'] = 2, ['value'] = 0, ['prob'] = 0, __size = 6}}, {{['holder'] = 1, ['lifeRound'] = 99, ['value'] = 0, ['cfgId'] = 4024816, ['caster'] = 2, __size = 5}}, {{['holder'] = 1, ['lifeRound'] = 99, ['cfgId'] = 521610, ['caster'] = 2, ['value'] = 0, ['prob'] = 'self:hasBuff(521601) and 1 or 0', __size = 6}}}, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024814] = {
		id = 4024814,
		easyEffectFunc = 'reborn',
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024815] = {
		id = 4024815,
		easyEffectFunc = 'changeScaleAttrs',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		specialVal = {1, 1},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024816] = {
		id = 4024816,
		skillTimePos = 2,
		immuneBuff = {4024811},
		dispelBuff = {4024811},
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024817] = {
		id = 4024817,
		easyEffectFunc = 'damageSub',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['onSomeFlag'] = {'not target:hasBuffGroup(c.yinshen_oc())'}, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {3001, 3006, 9999}
	},
	[4024818] = {
		id = 4024818,
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['effectFuncs'] = {'castBuff'}, ['triggerPoint'] = 42, ['funcArgs'] = {{{['holder'] = 1, ['lifeRound'] = 1, ['value'] = {1}, ['cfgId'] = 4024812, ['caster'] = 2, __size = 5}}}, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024819] = {
		id = 4024819,
		easyEffectFunc = 'immuneDamage',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024820] = {
		id = 4024820,
		easyEffectFunc = 'depart',
		skillTimePos = 2,
		overlayType = 1,
		overlayLimit = 1,
		holderActionType = {['typ'] = 'hide', ['args'] = {['sprite'] = {['isShow'] = false, __size = 1}, ['lifebar'] = {['isShow'] = false, __size = 1}, __size = 2}, __size = 2},
		ignoreHolder = 1,
		ignoreCaster = {1},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024821] = {
		id = 4024821,
		skillTimePos = 2,
		immuneBuff = {3601139, 3601133, 3611171},
		dispelBuff = {3601139, 3601133, 3611171},
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['onSomeFlag'] = {'not target:hasBuffGroup(c.yinshen_oc())'}, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		buffFlag = {3001, 3006, 9999}
	},
	[4024822] = {
		id = 4024822,
		easyEffectFunc = 'alterDmgRecordVal',
		skillTimePos = 2,
		overlayLimit = 1,
		specialVal = {{['calcInternalDamageFinish'] = {'setValue(list("calFinalDamage"),target:hasBuff(4024311) and list(calFinalDamage*1.1) or list(calFinalDamage*1))'}, __size = 1}},
		buffFlag = {3001, 3006, 9999}
	},
	[4024911] = {
		id = 4024911,
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['effectFuncs'] = {'castBuff'}, ['onSomeFlag'] = {'moreE(self:hp(),self:hpMax()*0.7)'}, ['funcArgs'] = {{{['holder'] = 2, ['lifeRound'] = 999, ['value'] = 3000, ['cfgId'] = 4024912, ['caster'] = 2, __size = 5}}}, ['triggerPoint'] = 32, ['nodeId'] = 1, __size = 5}},
		noDelWhenFakeDeath = 1,
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	[4024912] = {
		id = 4024912,
		easyEffectFunc = 'damageSub',
		skillTimePos = 2,
		overlayLimit = 1,
		ignoreHolder = 1,
		ignoreCaster = {1},
		triggerBehaviors = {{['delSelfWhenTriggered'] = 1, ['onSomeFlag'] = {'less(self:hp(),self:hpMax()*0.7)'}, ['triggerPoint'] = 42, ['nodeId'] = 1, __size = 4}, {['triggerPoint'] = 1, ['nodeId'] = 0, __size = 2}},
		noDelWhenFakeDeath = 1,
		buffFlag = {3001, 3006, 9999},
		roundInherit = {['gameEnd'] = 0, ['wave'] = 0, __size = 2}
	},
	__size = 1495,}
return csv.buff_2
