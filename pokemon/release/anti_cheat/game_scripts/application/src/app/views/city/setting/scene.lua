-- chunkname: @src.app.views.city.setting.scene

local ViewBase = cc.load("mvc").ViewBase
local SettingSceneView = class("SettingSceneView", ViewBase)

SettingSceneView.RESOURCE_FILENAME = "setting_scene.json"
SettingSceneView.RESOURCE_BINDING = {
	["centerPanel.subList"] = "subList",
	["centerPanel.item"] = "item",
	["centerPanel.btnOK"] = {
		varname = "btnOK",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onBtnOK")
			}
		}
	},
	["centerPanel.btnOK.text"] = {
		binds = {
			event = "effect",
			data = {
				color = ui.COLORS.NORMAL.WHITE,
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["centerPanel.list"] = {
		varname = "list",
		binds = {
			class = "tableview",
			event = "extend",
			props = {
				topPadding = 20,
				asyncPreload = 6,
				columnSize = 2,
				data = bindHelper.self("data"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				preloadCenterIndex = bindHelper.self("preloadCenterIndex"),
				onCell = function(list, node, k, v)
					local childs = node:multiget("img", "selected", "name", "logo", "tip")

					childs.img:texture(v.cfg.path)
					childs.name:text(v.cfg.name)

					local usedId = list.usedId()

					idlereasy.when(usedId, function(_, id)
						childs.logo:visible(id == v.csvId)
					end):anonyOnly(list, v.csvId)

					local selectId = list.selectId()

					idlereasy.when(selectId, function(_, id)
						childs.selected:visible(id == v.csvId)
					end):anonyOnly(list, v.csvId)

					local isActivityScene = list.isActivityScene()

					childs.tip:hide()

					if isActivityScene and usedId:read() ~= v.csvId then
						childs.tip:show()
						text.addEffect(childs.tip, {
							color = ui.COLORS.NORMAL.RED,
							outline = {
								color = ui.COLORS.NORMAL.WHITE
							}
						})
						cache.setShader(node, false, "hsl_gray")
					elseif not isActivityScene and not v.cfg.canChoose then
						childs.tip:show():text(gLanguageCsv.settingSceneNotCanChoose)
						text.addEffect(childs.tip, {
							color = ui.COLORS.NORMAL.RED,
							outline = {
								color = ui.COLORS.NORMAL.WHITE
							}
						})
						cache.setShader(node, false, "hsl_gray")
					end

					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.clickCell, k, v)
						}
					})
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()

					if itertools.size(list.data) == 1 then
						list:x(313)
					end
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
				selectId = bindHelper.self("selectId", true),
				usedId = bindHelper.self("usedId", true),
				isActivityScene = bindHelper.self("isActivityScene", true)
			}
		}
	}
}

function SettingSceneView:onCreate(params)
	self.params = params

	local id, isActivityScene = dataEasy.getCitySceneIdx()

	self.isActivityScene = isActivityScene
	self.usedId = idler.new(id)
	self.selectId = idler.new(id)

	local data = {}

	for csvId, cfg in orderCsvPairs(csv.cityscene) do
		table.insert(data, {
			csvId = csvId,
			cfg = cfg
		})

		if csvId == id then
			self.preloadCenterIndex = math.ceil(#data / 2)
		end
	end

	self.data = data

	idlereasy.any({
		self.selectId,
		self.usedId
	}, function(_, selectId, usedId)
		uiEasy.setBtnShader(self.btnOK, self.btnOK:get("text"), selectId == usedId and 2 or 1)
	end)
end

function SettingSceneView:onBtnOK()
	local selectId = self.selectId:read()

	if selectId == self.usedId:read() then
		return
	end

	gGameApp:requestServer("/game/role/city/scene/switch", function(tb)
		local id = dataEasy.getCitySceneIdx()

		self.usedId:set(id)
		gGameUI:showTip(string.format(gLanguageCsv.settingSceneChange, csv.cityscene[id].name))

		if self.params.citySceneIdx then
			self.params.citySceneIdx:set(id)
		end
	end, selectId)
end

function SettingSceneView:onItemClick(list, k, v)
	if self.selectId:read() == v.csvId then
		return
	end

	if self.isActivityScene then
		gGameUI:showTip(gLanguageCsv.settingSceneSpecialActivity)

		return
	end

	if not v.cfg.canChoose then
		gGameUI:showTip(gLanguageCsv.settingSceneSpecialActivity)

		return
	end

	self.selectId:set(v.csvId)
end

return SettingSceneView
