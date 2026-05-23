-- chunkname: @src.app.views.city.weather.weather_select

local ViewBase = cc.load("mvc").ViewBase
local WeatherSelectView = class("WeatherSelectView", Dialog)

WeatherSelectView.RESOURCE_FILENAME = "weather_select.json"
WeatherSelectView.RESOURCE_BINDING = {
	["panel.item"] = "item",
	["panel.txtWeather"] = "txtWeather",
	panel = "panel",
	["panel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	},
	["panel.btnRule"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onRuleClick")
			}
		}
	},
	["panel.btnSure"] = {
		varname = "btnSure",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onSure")
			}
		}
	},
	["panel.btnSure.txt"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["panel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				margin = 10,
				data = bindHelper.self("data"),
				item = bindHelper.self("item"),
				weatherID = bindHelper.self("weatherID"),
				itemAction = {
					isAction = true
				},
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "select", "imgCheck", "bg", "spriteNode", "name", "txtDesc")

					idlereasy.when(list.weatherID, function(_, weatherID)
						local select = weatherID == v.weatherID

						childs.select:visible(select)
						childs.imgCheck:visible(select)
						childs.bg:visible(not select)
					end):anonyOnly(list, k)

					local cfg = csv.weather_system.weather[v.weatherID]

					childs.name:text(cfg.name)
					childs.txtDesc:text(cfg.describe)
					childs.icon:texture(cfg.iconRes)
					adapt.setTextAdaptWithSize(childs.name, {
						horizontal = "center",
						vertical = "center",
						size = cc.size(220, 100)
					})

					local data = v.data
					local unitCfg = csv.unit[data.unitID]

					bind.extend(list, childs.spriteNode, {
						class = "card_icon",
						props = {
							unitId = data.unitID,
							advance = data.advance,
							rarity = unitCfg.rarity,
							star = data.star,
							dbid = data.dbid,
							levelProps = {
								data = data.level
							},
							onNode = function(node)
								node:scale(0.8)
							end
						}
					})
					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.clickCell, node, k, v)
						}
					})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick")
			}
		}
	}
}

function WeatherSelectView:onCreate(params)
	self.params = params
	self.data = idlers.newWithMap(params.cardsData)

	local weatherData = params.weatherID

	if isIdler(params.weatherID) then
		weatherData = params.weatherID:read()
	end

	if params.idx then
		weatherData = weatherData[params.idx]
	end

	self.weatherID = idler.new(weatherData)

	idlereasy.when(self.weatherID, function(_, weatherID)
		local cfg = csv.weather_system.weather[weatherID]

		if cfg then
			self.txtWeather:text(gLanguageCsv.nowWeather .. cfg.name)
		end
	end)
	Dialog.onCreate(self)
end

function WeatherSelectView:onItemClick(list, node, k, v)
	self.weatherID:set(v.weatherID)
end

function WeatherSelectView:onSure()
	if self.params.cb then
		self.params.cb(self.weatherID:read())
	elseif self.params.idx then
		self.params.weatherID:modify(function(data)
			data[self.params.idx] = self.weatherID:read()

			return true, data
		end, true)
	else
		self.params.weatherID:set(self.weatherID)
	end

	Dialog.onClose(self)
end

function WeatherSelectView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {
		width = 1350
	})
end

function WeatherSelectView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.noteText(133101, 133300)
	}

	return context
end

return WeatherSelectView
