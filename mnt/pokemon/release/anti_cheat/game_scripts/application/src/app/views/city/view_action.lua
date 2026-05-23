-- chunkname: @src.app.views.city.view_action

local CityView = {}
local redHintHelper = require("app.easy.bind.helper.red_hint")
local DispatchTaskView = require("app.views.city.adventure.dispatch_task.view")
local SCHEDULE_TAG = {
	dispatchTaskRefresh = 6
}

local function getActionBtnsData()
	return {
		{
			key = "shop",
			viewName = "city.shop",
			icon = "city/main/icon_sd.png",
			name = gLanguageCsv.shop,
			styles = {
				full = true
			},
			func = function(cb)
				uiEasy.goToShop(nil, cb)
			end
		},
		{
			key = "drawCard",
			viewName = "city.drawcard.view",
			icon = "city/main/icon_nd@.png",
			name = gLanguageCsv.drawCard,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"drawcardDiamondFree",
						"drawcardGoldFree",
						"drawcardEquipFree"
					}
				}
			}
		},
		{
			key = "handbook",
			unlockKey = "handbook",
			viewName = "city.handbook.view",
			icon = "city/main/icon_tj@.png",
			name = gLanguageCsv.handbook,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "handbookAdvance"
				}
			}
		},
		{
			key = "develop",
			actionExpandName = "develop",
			icon = "city/main/icon_yc@.png",
			offx = -111,
			name = gLanguageCsv.develop,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"cityGemFreeExtract",
						"cityTalent",
						"cityTrainer",
						"explorerTotal",
						"explorerFind",
						"totemGroup",
						"totemFree"
					}
				}
			}
		},
		{
			key = "bag",
			viewName = "city.bag",
			icon = "city/main/icon_bb@.png",
			name = gLanguageCsv.bag,
			styles = {
				full = true
			}
		},
		{
			key = "task",
			actionExpandName = "task",
			viewName = "city.task",
			icon = "city/main/icon_rw.png",
			offx = 255,
			name = gLanguageCsv.task,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"cityTaskDaily",
						"cityTaskMain",
						"achievementTask",
						"achievementBox",
						"medalCollection"
					}
				}
			}
		},
		{
			key = "cardBag",
			viewName = "city.card.bag",
			icon = "city/main/icon_jl@.png",
			name = gLanguageCsv.card,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"bottomFragment",
						"totalCard",
						"starSwapAid",
						"starSwapExchange"
					}
				}
			}
		},
		{
			key = "team",
			viewName = "city.card.embattle.base",
			icon = "city/main/icon_bd@.png",
			name = gLanguageCsv.formation,
			styles = {
				full = true
			}
		},
		-- 家园注释标记
		-- {
		-- 	key = "town",
		-- 	viewName = "city.town.view",
		-- 	icon = "city/main/icon_jy.png",
		-- 	unlockKey = "town",
		-- 	name = gLanguageCsv.town,
		-- 	styles = {
		-- 		full = true
		-- 	},
		-- 	redHint = {
		-- 		class = "red_hint",
		-- 		props = {
		-- 			specialTag = {
		-- 				"townBuildingUpLevel",
		-- 				"townFactoryAward",
		-- 				"explorerTown",
		-- 				"townExplorationTask",
		-- 				"townWishDailyClick",
		-- 				"townWishAward",
		-- 				"hasPartyTimes"
		-- 			},
		-- 			func = function(t, node)
		-- 				local normalTag = {
		-- 					redHintHelper.townBuildingUpLevel(t),
		-- 					redHintHelper.townFactoryAward(t),
		-- 					redHintHelper.explorerTown(t),
		-- 					redHintHelper.townExplorationTask(t),
		-- 					redHintHelper.townWishDailyClick(t),
		-- 					redHintHelper.townWishAward(t)
		-- 				}
		-- 				local redHint = false

		-- 				for k, v in pairs(normalTag) do
		-- 					if v then
		-- 						redHint = true

		-- 						break
		-- 					end
		-- 				end

		-- 				local hasPartyTimes = redHintHelper.hasPartyTimes(t)
		-- 				local townBtn = node:getParent()

		-- 				townBtn:removeChildByName("partyIcon")

		-- 				if hasPartyTimes then
		-- 					local spr = cc.Sprite:create("city/town/home/party/logo_pdkq.png")

		-- 					spr:addTo(townBtn, 5, "partyIcon"):xy(94, 230):scale(2)

		-- 					local musicIcon = cc.Sprite:create("city/town/home/party/icon_yinfu.png"):addTo(spr, 5, "musicIcon"):anchorPoint(0.5, 0.5):xy(spr:width() - 20, 48):scale(0.5)
		-- 					local action1 = cc.RepeatForever:create(cc.RotateBy:create(1, 90))

		-- 					musicIcon:runAction(action1)
		-- 				end

		-- 				return redHint
		-- 			end
		-- 		}
		-- 	},
		-- 	func = function(cb)
		-- 		gGameApp:requestServer("/town/get", function(tb)
		-- 			townDataEasy.homeFriends(tb.view)
		-- 			display.textureCache:removeUnusedTextures()
		-- 			cb(tb.view)
		-- 		end)
		-- 	end
		-- }
	}
end

local function getDevelopBtnsData()
	return {
		{
			key = "totem",
			unlockKey = "totem",
			viewName = "city.develop.totem.view",
			icon = "city/main/icon_zc_tt.png",
			name = gLanguageCsv.totem,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"totemGroup",
						"totemAwardAllGet",
						"totemFree"
					},
					onNode = function(node)
						node:xy(150, 150)
					end
				}
			}
		},
		{
			key = "title_book",
			unlockKey = "title",
			viewName = "city.develop.title_book.view",
			icon = "city/main/icon_zc_ch.png",
			name = gLanguageCsv.titleBook
		},
		{
			key = "trainer",
			unlockKey = "trainer",
			viewName = "city.develop.trainer.view",
			icon = "city/main/icon_zc_mxjz.png",
			name = gLanguageCsv.training,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "cityTrainer",
					onNode = function(node)
						node:xy(150, 150)
					end
				}
			}
		},
		{
			icon = "city/main/icon_zc_tf.png",
			key = "talent",
			viewName = "city.develop.talent.view",
			bg = "city/panel_icon2.png",
			unlockKey = "talent",
			name = gLanguageCsv.talent,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "cityTalent",
					onNode = function(node)
						node:xy(150, 150)
					end
				}
			}
		},
		{
			unlockKey = "explorer",
			key = "explore",
			viewName = "city.develop.explorer.view",
			icon = "city/main/icon_zc_txq.png",
			name = gLanguageCsv.explorer,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"explorerTotal",
						"explorerFind",
						"explorerAdvance"
					},
					onNode = function(node)
						node:xy(150, 150)
					end
				}
			}
		},
		{
			key = "gem",
			unlockKey = "gem",
			viewName = "city.card.gem.view",
			icon = "city/main/icon_zc_fs.png",
			name = gLanguageCsv.gemTitle,
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "cityGemFreeExtract",
					onNode = function(node)
						node:xy(150, 150)
					end
				}
			}
		},
		{
			key = "mega",
			unlockKey = "mega",
			viewName = "city.card.mega.view",
			icon = "city/main/icon_zc_cjh.png",
			name = gLanguageCsv.megaTitle,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "cardMega",
					onNode = function(node)
						node:xy(150, 150)
					end
				}
			}
		},
		{
			key = "gymBadge",
			unlockKey = "badge",
			viewName = "city.develop.gym_badge.view",
			icon = "city/main/icon_zc_hz.png",
			name = gLanguageCsv.badgeTitle,
			styles = {
				full = true
			}
		},
		{
			key = "zawake",
			unlockKey = "zawake",
			viewName = "city.zawake.view",
			icon = "city/main/icon_zc_zjx.png",
			name = gLanguageCsv.zawake,
			styles = {
				full = true
			},
			func = function(cb)
				local zawakeTools = require("app.views.city.zawake.tools")
				local zawakeID = zawakeTools.getFightPointMaxCard()

				if zawakeID then
					cb({
						zawakeID = zawakeID
					})
				else
					gGameUI:showTip(gLanguageCsv.noZawakeCard)
				end
			end
		},
		{
			key = "chip",
			unlockKey = "chip",
			viewName = "city.card.chip.bag",
			icon = "city/main/icon_zc_xp.png",
			name = gLanguageCsv.chip,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "cityChipFreeExtract",
					onNode = function(node)
						node:xy(150, 150)
					end
				}
			}
		},
		{
			key = "meteorite",
			unlockKey = "meteorite",
			viewName = "city.develop.strange_meteor.view",
			icon = "city/main/icon_zc_ys.png",
			name = gLanguageCsv.meteor,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = "meteorite",
					onNode = function(node)
						node:xy(150, 150)
					end
				}
			}
		}
	}
end

local function getTaskBtnsData()
	return {
		{
			key = "task",
			viewName = "city.task",
			icon = "city/main/icon_zc_rw.png",
			name = gLanguageCsv.task,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"cityTaskDaily",
						"cityTaskMain"
					},
					onNode = function(node)
						node:xy(150, 150)
					end
				}
			}
		},
		{
			key = "achievement",
			unlockKey = "achievement",
			viewName = "city.achievement",
			icon = "city/main/icon_zc_cj.png",
			name = gLanguageCsv.achievement,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"achievementTask",
						"achievementBox"
					},
					onNode = function(node)
						node:xy(150, 150)
					end
				}
			}
		},
		{
			key = "medalCollection",
			unlockKey = "medalCollection",
			viewName = "city.medal_collection.view",
			icon = "city/main/icon_zc_xzc.png",
			name = gLanguageCsv.medalCollection,
			styles = {
				full = true
			},
			redHint = {
				class = "red_hint",
				props = {
					specialTag = {
						"medalCollection"
					},
					onNode = function(node)
						node:xy(150, 150)
					end
				}
			}
		}
	}
end

function CityView:updateActionBtnsDatas()
	local t = {}

	for k, v in ipairs(getActionBtnsData()) do
		local show = true

		if v.unlockKey then
			show = dataEasy.isShow(v.unlockKey)
		end

		if show then
			table.insert(t, v)
		end
	end

	self.actionBtns:update(t)
end

function CityView:setActionBtnsDatasIdler()
	local sign = false

	for k, v in ipairs(getActionBtnsData()) do
		if v.unlockKey then
			dataEasy.getListenShow(v.unlockKey, function(isShow)
				if sign then
					self:updateActionBtnsDatas()
				end
			end)
		end
	end

	sign = true

	self:updateActionBtnsDatas()
end

function CityView:initActionData()
	self.actionBtns = idlers.newWithMap({})
	self.developBtns = idlertable.new({})

	local developKeys = {
		"title",
		"trainer",
		"talent",
		"explorer",
		"achievement",
		"gem",
		"mega",
		"badge",
		"zawake",
		"chip",
		"totem",
		"meteorite",
		"medalCollection"
	}
	local developShowListen = {}

	for _, v in ipairs(developKeys) do
		table.insert(developShowListen, dataEasy.getListenShow(v))
	end

	self:setActionBtnsDatasIdler()
	idlereasy.any(arraytools.merge({
		{
			self.actionExpandName
		},
		developShowListen
	}), function(_, actionExpandName, ...)
		local params = {
			...
		}
		local isShow = {}

		for k, v in ipairs(developKeys) do
			isShow[v] = params[k]
		end

		for _, v in self.developBtns:pairs() do
			if v.unlockRes then
				v.unlockRes:destroy()
			end
		end

		local developBtns

		if actionExpandName == "task" then
			developBtns = getTaskBtnsData()
		else
			developBtns = getDevelopBtnsData()
		end

		for i = #developBtns, 1, -1 do
			local v = developBtns[i]

			if v.unlockKey then
				if not isShow[v.unlockKey] then
					table.remove(developBtns, i)
				elseif v.unlockKey == "totem" then
					v.specialLock = not dataEasy.isTotemUnlock()
				end
			end
		end

		local columnSize = math.max(4, math.ceil(#developBtns / 2))

		self.developList.columnSize = columnSize

		local listHigh, tmp = math.modf(#developBtns / columnSize)

		self.developBg:size(180 * (columnSize > #developBtns and #developBtns or columnSize) + 10, 190 * (tmp == 0 and listHigh or listHigh + 1))
		self.developList:size(180 * columnSize, 190 * (tmp == 0 and listHigh or listHigh + 1))
		self.listItem:size(180 * columnSize, 180)
		self.developBg:y(0)
		self.developList:xy(self.developBg:x() - self.developBg:width() / 2 + 5, self.developBg:height() + 10)
		self.developBtns:set(developBtns)

		for i, v in self.actionBtns:ipairs() do
			local data = v:proxy()

			if data.key == "task" then
				if not isShow.achievement then
					data.actionExpandName = nil

					break
				end

				data.actionExpandName = "task"

				break
			end
		end
	end)
	dataEasy.getListenUnlock(gUnlockCsv.dispatchTask, function(isUnlock)
		if isUnlock == true then
			DispatchTaskView.setRefreshTime(self, nil, {
				tag = SCHEDULE_TAG.dispatchTaskRefresh,
				cb = function()
					local dispatchTasksRedHintRefrseh = gGameModel.forever_dispatch:getIdlerOrigin("dispatchTasksRedHintRefrseh")

					dispatchTasksRedHintRefrseh:modify(function(val)
						return true, not val
					end)
				end
			})
		end
	end)
end

return function(cls)
	for k, v in pairs(CityView) do
		cls[k] = v
	end
end
