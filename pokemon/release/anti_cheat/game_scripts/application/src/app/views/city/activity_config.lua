-- chunkname: @src.app.views.city.activity_config

local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE

local function checkActivityOpen(params)
	params = params or {}

	local yyOpen = gGameModel.role:read("yy_open")
	local hash = arraytools.hash(yyOpen)

	if type(params[1]) == "number" then
		if not hash[params[1]] then
			gGameUI:showTip(gLanguageCsv.activityOver)

			return false
		end
	elseif type(params[1]) == "table" then
		for _, data in pairs(params[1]) do
			if hash[data.id] then
				return true
			end
		end

		gGameUI:showTip(gLanguageCsv.activityOver)

		return false
	end

	return true
end

local function getActivityDefaultData()
	local function defaultFunc(cb, params)
		gGameApp:requestServer("/game/yy/active/get", function(tb)
			if checkActivityOpen(params) then
				cb(params)
			end
		end)
	end

	local t = {
		{
			viewName = "city.activity.view",
			sortWeight = -103,
			icon = "city/main/icon_fl@.png",
			independentStyle = "award",
			styles = {
				full = true
			},
			func = function(cb)
				gGameApp:requestServer("/game/yy/active/get", function(tb)
					cb("award")
				end)
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "totalActivityShow",
					listenData = {
						independent = 3
					}
				}
			}
		},
		{
			viewName = "city.activity.view",
			sortWeight = -102,
			icon = "city/main/icon_xshd.png",
			independentStyle = "main",
			styles = {
				full = true
			},
			func = function(cb)
				gGameApp:requestServer("/game/yy/active/get", function(tb)
					cb()
				end)
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "totalActivityShow",
					listenData = {
						independent = 0
					}
				}
			}
		},
		{
			viewName = "city.recharge",
			sortWeight = -101,
			icon = "city/main/icon_tqlb.png",
			styles = {
				full = true
			},
			params = {
				{
					showPrivilege = true
				}
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"vipGift",
						"onHonourableVip"
					}
				}
			}
		}
	}

	for _, v in orderCsvPairs(csv.activity_city_theme) do
		table.insert(t, {
			cityTheme = v.cityTheme,
			icon = v.icon,
			viewName = v.viewName,
			sortWeight = v.sortWeight,
			styles = {
				full = true
			},
			func = defaultFunc
		})
	end

	return t
end

local function getActivityInfoData(self)
	local function defaultFunc(cb, params)
		gGameApp:requestServer("/game/yy/active/get", function(tb)
			if checkActivityOpen(params) then
				cb(tb)
			end
		end)
	end

	return {
		[YY_TYPE.firstRecharge] = {
			viewName = "city.activity.first_recharge",
			sortWeight = -100,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"firstRecharge",
						"firstRechargeDailyAward"
					}
				}
			}
		},
		[YY_TYPE.serverOpen] = {
			viewName = "city.activity.server_open.view",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "serverOpen"
				}
			}
		},
		[YY_TYPE.fightRank] = {
			viewName = "city.activity.activity_fight_rank",
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/fightrank/get", function(tb)
					if checkActivityOpen(params) then
						cb(tb)
					end
				end, params[1])
			end
		},
		[YY_TYPE.luckyCat] = {
			viewName = "city.activity.lucky_cat",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "luckyCat"
				}
			}
		},
		[YY_TYPE.rmbgoldReward] = {
			viewName = "city.activity.rmbgold_reward",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "rmbgoldReward"
				}
			}
		},
		[YY_TYPE.passport] = {
			viewName = "city.activity.passport.view",
			func = defaultFunc,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"passportCurrDay",
						"passportReward",
						"passportTask"
					}
				}
			}
		},
		[YY_TYPE.playPassport] = {
			viewName = "city.activity.passport.game_view",
			func = defaultFunc,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"playPassport"
					}
				}
			}
		},
		[YY_TYPE.timeLimitBox] = {
			viewName = "city.activity.limit_sprite",
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/limit/box/get", function(tb)
					if checkActivityOpen(params) then
						cb(tb.view, self:createHandler("onReFreshRedHint"))
					end
				end, params[1])
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"limitSpritesHasFreeDrawCard",
						"limitSpritesHasBoxAward"
					},
					listenData = {
						refresh = bindHelper.self("redHintRefresh")
					},
					onNode = function(node)
						node:xy(156, 236)
					end
				}
			}
		},
		[YY_TYPE.loginWeal] = {
			viewName = "city.activity.recharge_feedback.new_player_welfare",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "loginWealRedHint"
				}
			}
		},
		[YY_TYPE.LoginGift] = {
			viewName = "city.activity.recharge_feedback.normal_view",
			icon = "city/main/icon_xshd.png",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "loginGiftRedHint"
				}
			}
		},
		[YY_TYPE.rechargeWheel] = {
			viewName = "city.activity.recharge_wheel",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"rechargeWheel",
						"rechargeWheelFree"
					}
				}
			}
		},
		[YY_TYPE.livenessWheel] = {
			viewName = "city.activity.liveness_wheel",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "livenessWheel"
				}
			}
		},
		[YY_TYPE.onceRechageAward] = {
			viewName = "city.activity.once_recharge_award",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "onceRechargeAward"
				}
			}
		},
		[YY_TYPE.limitBuyGift] = {
			viewName = "city.activity.limit_buy_gift",
			tag = true,
			func = defaultFunc,
			timeLabelFunc = function(yyId, huodong, cb, item)
				local times = {}

				for _, yyId in ipairs(self.yyOpen:read()) do
					local cfg = csv.yunying.yyhuodong[yyId]

					if cfg.type == YY_TYPE.limitBuyGift then
						for i, v in orderCsvPairs(csv.yunying.limitbuygift) do
							if v.huodongID == cfg.huodongID and huodong.valinfo[i] and time.getTime() - huodong.valinfo[i].time < v.duration * 60 then
								local leftTimes = huodong.stamps[i] or 1
								local buyTimes = 1 - leftTimes

								buyTimes = dataEasy.getPayClientBuyTimes("directBuyData", yyId, i, buyTimes)

								if buyTimes == 0 then
									table.insert(times, {
										startTime = huodong.valinfo[i].time,
										cfg = v
									})
								end
							end
						end
					end
				end

				if #times > 0 then
					if item then
						self:setLimitBuyGiftCountTime(item, times, cb)
					end

					return true
				end

				return false
			end
		},
		[YY_TYPE.festival] = {
			viewName = "city.activity.chinese_new_year",
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/red/packet/list", function(data)
					if checkActivityOpen(params) then
						for k, v in pairs(data.view.packets) do
							v.roleId = self.id:read()
						end

						cb(clone(data.view.packets))
					end
				end)
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "festivalRedHint"
				}
			}
		},
		[YY_TYPE.huodongCrossRedPacket] = {
			viewName = "city.activity.chinese_new_year",
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/cross/red/packet/list", function(data)
					if checkActivityOpen(params) then
						for k, v in pairs(data.view.packets) do
							v.roleId = self.id:read()
						end

						cb(clone(data.view.packets))
					end
				end)
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "crossFestivalRedHint"
				}
			}
		},
		[YY_TYPE.luckyEgg] = {
			viewName = "city.activity.recharge_feedback.activity_lucky_egg",
			styles = {
				full = true
			},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"luckyEggDrawCardFree"
					}
				}
			}
		},
		[YY_TYPE.directBuyGift] = {
			viewName = "city.activity.direct_buy_gift",
			styles = {
				full = true
			},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "activityDirectBuyGift"
				}
			}
		},
		[YY_TYPE.generalTask] = {
			viewName = "city.activity.first_recharge_daily",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "firstRechargeDaily"
				}
			}
		},
		[YY_TYPE.weeklyCard] = {
			viewName = "city.activity.view",
			styles = {
				full = true
			},
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/active/get", function(tb)
					cb("main")
				end)
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "activityWeeklyCard"
				}
			}
		},
		[YY_TYPE.worldBoss] = {
			viewName = "city.activity.world_boss.view",
			styles = {
				full = true
			},
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/world/boss/main", function(tb)
					if checkActivityOpen(params) then
						cb(tb)
					end
				end, params[1])
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "activityWorldBoss"
				}
			}
		},
		[YY_TYPE.gemUp] = {
			viewName = "city.activity.gem_up.view",
			tag = true,
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "gemUp"
				}
			}
		},
		[YY_TYPE.baoZongzi] = {
			viewName = "city.activity.duan_wu_festival.view",
			tag = true,
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "zongZiActivity"
				}
			}
		},
		[YY_TYPE.qualityExchange] = {
			viewName = "city.activity.quality_exchange_fragment",
			func = defaultFunc
		},
		[YY_TYPE.flipCard] = {
			viewName = "city.activity.flip_card",
			tag = true,
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "flipCardActivity"
				}
			}
		},
		[YY_TYPE.huoDongBoss] = {
			viewName = "city.activity.activity_boss.view",
			styles = {
				full = true
			},
			func = function(cb, params)
				local huodongId

				for _, id in ipairs(self.yyOpen:read()) do
					local cfg = csv.yunying.yyhuodong[id]

					if cfg.type == YY_TYPE.huoDongBoss then
						huodongId = id

						break
					end
				end

				gGameApp:requestServer("/game/yy/huodongboss/list", function(tb)
					if checkActivityOpen(params) then
						cb(tb)
					end
				end, huodongId, gCommonConfigCsv.huodongbossMaxNumber)
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "activityBoss"
				}
			}
		},
		[YY_TYPE.reunion] = {
			viewName = "city.activity.reunion.view",
			styles = {
				full = true
			},
			func = function(cb)
				local reunion = self.reunion:read()

				if reunion.info.end_time - time.getTime() < 0 or reunion.role_type == 0 then
					self.updateActivity:notify()
					gGameUI:showTip(gLanguageCsv.activityOver)

					return
				end

				local bind_role_db_id = gGameModel.reunion_record:read("bind_role_db_id")
				local roleID = ""

				if reunion.role_type == 1 then
					roleID = bind_role_db_id or ""
				elseif reunion.role_type == 2 then
					roleID = reunion.info.role_id
				end

				if roleID ~= "" then
					gGameApp:requestServer("/game/role_info", function(tb)
						local info = tb.view
						local params = {
							info = info
						}

						if reunion.role_type == 2 then
							gGameApp:requestServer("/game/yy/reunion/record/get", function(tb)
								params = {
									info = info,
									reunionRecord = tb.view.reunion_record
								}

								if cb then
									cb(params)
								end
							end, roleID)
						elseif cb then
							cb(params)
						end
					end, roleID)
				else
					cb({})
				end
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "reunionActivity"
				}
			}
		},
		[YY_TYPE.double11] = {
			viewName = "city.activity.double11.view",
			styles = {
				full = true
			},
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/double11/main", function(tb)
					if checkActivityOpen(params) then
						cb(tb)
					end
				end, params[1])
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "double11"
				}
			}
		},
		[YY_TYPE.snowBall] = {
			viewName = "city.activity.snow_ball.view",
			styles = {
				full = true
			},
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/snowball/main", function(tb)
					if checkActivityOpen(params) then
						cb(tb)
					end
				end, params[1])
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "snowBall"
				}
			}
		},
		[YY_TYPE.flipNewYear] = {
			viewName = "city.activity.new_year_flip_card",
			tag = true,
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "flipNewYear"
				}
			}
		},
		[YY_TYPE.skyScraper] = {
			viewName = "city.activity.sky_scraper.view",
			styles = {
				full = true
			},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "skyScraper"
				}
			}
		},
		[YY_TYPE.gridWalk] = {
			viewName = "city.activity.grid_walk.view",
			styles = {
				full = true
			},
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/gridwalk/main", function(tb)
					if checkActivityOpen(params) then
						cc.SpriteFrameCache:getInstance():addSpriteFrames("activity/grid_walk/gezi.plist")
						cb()
					end
				end, params[1])
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "gridWalkMain"
				}
			}
		},
		[YY_TYPE.braveChallenge] = {
			viewName = "city.activity.brave_challenge.view",
			styles = {
				full = true
			},
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/brave_challenge/main", function(tb)
					if checkActivityOpen(params) then
						cb(1)
					end
				end, params[1])
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "braveChallengeAch",
					listenData = {
						sign = game.BRAVE_CHALLENGE_TYPE.anniversary
					}
				}
			}
		},
		[YY_TYPE.horseRace] = {
			viewName = "city.activity.horse_race.view",
			styles = {
				full = true
			},
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/horse/race/main", function(tb)
					if checkActivityOpen(params) then
						cb(tb)
					end
				end, params[1])
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "horseRaceMain"
				}
			}
		},
		[YY_TYPE.itemBuy2] = {
			viewName = "city.activity.coupon_shop",
			styles = {
				full = true
			},
			func = defaultFunc
		},
		[YY_TYPE.exclusiveLimit] = {
			viewName = "city.activity.exclusive_limit",
			tag = true,
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "exclusiveLimit"
				}
			}
		},
		[YY_TYPE.dispatch] = {
			viewName = "city.activity.dispatch.view",
			styles = {
				full = true
			},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "activityDispatch"
				}
			}
		},
		[YY_TYPE.summerChallenge] = {
			viewName = "city.activity.summer_challenge.view_annual",
			styles = {
				full = true
			},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "summerChallenge"
				}
			}
		},
		[YY_TYPE.shavedIce] = {
			viewName = "city.activity.beach_ice.view",
			styles = {
				full = true
			},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "shavedIce"
				}
			}
		},
		[YY_TYPE.volleyball] = {
			viewName = "city.activity.volleyball.view",
			styles = {
				full = true
			},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "volleyball"
				}
			}
		},
		[YY_TYPE.midAutumnDraw] = {
			viewName = "city.activity.mid_autumn_draw",
			styles = {
				full = true
			},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "midAutumnDraw"
				}
			}
		},
		[YY_TYPE.customizeGift] = {
			viewName = "city.activity.customize_gift",
			styles = {
				full = false
			},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "customizeGift"
				}
			}
		},
		[YY_TYPE.yyBet] = {
			viewName = "city.activity.yy_bet.view",
			styles = {
				full = true
			},
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/battlebet/main", function(tb)
					if checkActivityOpen(params) then
						cb(tb)
					end
				end, params[1])
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "battleBetMain"
				}
			}
		},
		[YY_TYPE.contestBet] = {
			viewName = "city.activity.contest_bet.view",
			styles = {
				full = true
			},
			func = function(cb, params)
				gGameApp:requestServer("/game/yy/contestbet/main", function(tb)
					if checkActivityOpen(params) then
						cb(tb)
					end
				end, params[1])
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"contestBetAllContestBet",
						"contestBetAward",
						"contestBetTaskAward",
						"contestBetChampionBet"
					}
				}
			}
		},
		[YY_TYPE.seekpokemon] = {
			viewName = "city.activity.seeksprite.view",
			styles = {
				full = true
			},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "seekpokemon"
				}
			}
		},
		[YY_TYPE.roleDayAward] = {
			viewName = "city.activity.role_day_award.view",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "roleDayAward"
				}
			}
		},
		[YY_TYPE.elementCrush] = {
			viewName = "city.activity.element_crush.view",
			styles = {
				full = true
			},
			func = function(cb, params)
				local data = {
					recognition_times = 0,
					elements = {},
					board = {},
					every_crush_times = {},
					sync_time = time.getTime()
				}

				gGameApp:requestServer("/game/yy/element_crush/sync", function(tb)
					if checkActivityOpen(params) then
						cb(tb)
					end
				end, params[1], data)
			end,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "elementCrush"
				}
			}
		},
		[YY_TYPE.worldcup] = {
			viewName = "city.activity.worldcup.view",
			styles = {
				full = true
			},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"wordcupAchievement",
						"wordcupGuess",
						"worldcupItemBet",
						"worldcupDailyAward"
					}
				}
			}
		},
		[YY_TYPE.spritejump] = {
			viewName = "city.activity.sprite_jump.view",
			styles = {
				full = true
			},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"spritejumpTask",
						"spritejumpGame"
					}
				}
			}
		},
		[YY_TYPE.clientShow] = {
			func = function(cb, params)
				local cfg = csv.yunying.yyhuodong[params[1]]
				local params2 = {
					id = params[1],
					cfg = cfg
				}

				cb(params2)
			end
		},
		[YY_TYPE.qixi] = {
			viewName = "city.activity.qixi.view",
			styles = {
				full = true
			},
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"qixiGame",
						"qixiCollect",
						"qixiDraw"
					}
				}
			}
		},
		[YY_TYPE.praise] = {
			viewName = "city.activity.good_comments.tik",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"tiktok"
					}
				}
			}
		},
		[YY_TYPE.mitu] = {
			viewName = "city.activity.block_blast.view",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"mituTask",
						"mituGame"
					}
				}
			}
		},
		[YY_TYPE.luckyDraw] = {
			viewName = "ity.activity.lucky_draw.view",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"luckyDraw"
					}
				}
			}
		},
		[YY_TYPE.dailyRandomGift] = {
			viewName = "city.activity.daily_random_gift",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"dailyRandomGiftDailyHint"
					}
				}
			}
		},
		[YY_TYPE.roundDraw] = {
			viewName = "city.activity.round_draw.view",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"roundDraw"
					}
				}
			}
		},
		[YY_TYPE.thousandDraw] = {
			viewName = "city.activity.thousand_draw",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"thousandDraw"
					}
				}
			}
		},
		[YY_TYPE.refloat] = {
			viewName = "city.activity.lucky_lottery.view",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"luckyLotteryTask",
						"luckyLotteryCanDraw"
					}
				}
			}
		},
		[YY_TYPE.moveBlock] = {
			viewName = "city.activity.move_block.view",
			func = defaultFunc,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"moveBlockTask",
						"moveBlockGame"
					}
				}
			}
		}
	}
end

return {
	getActivityDefaultData = getActivityDefaultData,
	getActivityInfoData = getActivityInfoData
}
