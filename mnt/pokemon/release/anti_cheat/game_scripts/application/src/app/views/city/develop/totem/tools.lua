-- chunkname: @src.app.views.city.develop.totem.tools

local TotemTools = {}

TotemTools.dotArrangeType = {
	{
		5
	},
	{
		1,
		9
	},
	{
		1,
		5,
		9
	},
	{
		1,
		3,
		7,
		9
	},
	{
		1,
		3,
		5,
		7,
		9
	},
	{
		1,
		3,
		4,
		5,
		7,
		9
	},
	{
		1,
		3,
		4,
		5,
		6,
		7,
		9
	},
	{
		1,
		3,
		4,
		5,
		6,
		7,
		8,
		9
	},
	{
		1,
		2,
		3,
		4,
		5,
		6,
		7,
		8,
		9
	}
}
TotemTools.totemPosition = {
	{
		{
			830,
			670
		}
	},
	{
		{
			617,
			670
		},
		{
			1030,
			670
		}
	},
	{
		{
			825,
			865
		},
		{
			630,
			610
		},
		{
			1025,
			610
		}
	},
	{
		{
			660,
			807
		},
		{
			985,
			807
		},
		{
			1007,
			600
		},
		{
			640,
			600
		}
	},
	{
		{
			663,
			790
		},
		{
			998,
			790
		},
		{
			837,
			620
		},
		{
			663,
			452
		},
		{
			1003,
			454
		}
	},
	{
		{
			645,
			785
		},
		{
			1020,
			785
		},
		{
			610,
			615
		},
		{
			1075,
			615
		},
		{
			645,
			447
		},
		{
			1025,
			449
		}
	},
	{
		{
			713,
			790
		},
		{
			963,
			790
		},
		{
			837,
			615
		},
		{
			628,
			615
		},
		{
			1043,
			615
		},
		{
			713,
			440
		},
		{
			963,
			440
		}
	},
	{
		{
			835,
			965
		},
		{
			835,
			760
		},
		{
			620,
			630
		},
		{
			1050,
			630
		},
		{
			380,
			525
		},
		{
			1285,
			525
		},
		{
			620,
			411
		},
		{
			1050,
			411
		}
	},
	{
		{
			835,
			965
		},
		{
			835,
			760
		},
		{
			620,
			630
		},
		{
			1050,
			630
		},
		{
			380,
			525
		},
		{
			1285,
			525
		},
		{
			835,
			525
		},
		{
			620,
			411
		},
		{
			1050,
			411
		}
	}
}
TotemTools.panelOffset = {
	{
		85,
		-370
	},
	{
		85,
		-475
	},
	{
		85,
		-510
	}
}
TotemTools.panelReflect = {
	1,
	1,
	1,
	1,
	2,
	2,
	2,
	3,
	3
}

local function getItem(param)
	local item = ccui.Layout:create()
	local img = ccui.ImageView:create(csv.items[param.csvId].icon):scale(param.scale or 1)
	local imgSize = img:size()

	item:size(imgSize.width, imgSize.height)
	img:xy(imgSize.width / 2, imgSize.height / 2):addTo(item, 2, "icon")

	return item
end

function TotemTools.getTotemMap(node, csvId, params)
	node:removeAllChildren()

	params = params and params or {}

	local cfg = csv.totem.symbol[csvId]
	local panelSize = cc.size(800, 400)
	local panel = ccui.Layout:create():size(panelSize.width, panelSize.height):alignCenter(node:size()):addTo(node, 1, "_panel_")
	local bg = ccui.ImageView:create("city/develop/totem/img_stone.png"):xy(panelSize.width / 2, panelSize.height / 2):scale(params.scale or 1):addTo(panel, 2, "bg")
	local nodeList = {}

	for i, v in pairs(cfg.totemGroup1) do
		local item = getItem({
			csvId = v
		})

		item:addTo(panel, 10, "item" .. i):xy(i * 100, i * 110)
		table.insert(nodeList, item)
	end

	return nodeList
end

function TotemTools.refreshData(csvId, params, node)
	local helper = require("easy.bind.helper")
	local data, idler, idlers = helper.dataOrIdler(params.data)

	if data then
		local totem = data

		idlereasy.any({
			csvId
		}, function(_, id)
			local index = 1
			local panel, scale = TotemTools.getBgNode(node, id, params)

			for i, v in pairs(totem) do
				local item = TotemTools.getOneNode(panel, id, index, params)

				if params.onItem then
					item:setTouchEnabled(true)
					params.onItem(item, i, v)
				end

				index = index + 1
			end

			if params.bgScale then
				panel:scale(params.bgScale)
			else
				panel:scale(scale)
			end
		end)
	else
		local idlerTotem = idler and idler or idlers

		idlereasy.any({
			csvId,
			idlerTotem
		}, function(_, id, totem)
			local index = 1
			local panel, scale = TotemTools.getBgNode(node, id, params)

			for i, v in pairs(totem) do
				local item = TotemTools.getOneNode(panel, id, index, params)

				if params.onItem then
					item:setTouchEnabled(true)
					params.onItem(item, i, v)
				end

				index = index + 1
			end

			if params.bgScale then
				panel:scale(params.bgScale)
			else
				panel:scale(scale)
			end
		end)
	end
end

function TotemTools.getBgNode(node, csvId, params)
	node:removeAllChildren()

	params = params and params or {}

	local scale = 1
	local cfg = csv.totem.symbol[csvId]
	local size = itertools.size(cfg.totemGroup1) or 3
	local bg = ccui.ImageView:create(string.format("city/develop/totem/img_stone_%d.png", TotemTools.panelReflect[size]))
	local panelSize = bg:size()

	if panelSize.height > 500 then
		scale = 500 / panelSize.height
	end

	local panel = ccui.Layout:create():size(panelSize.width, panelSize.height):alignCenter(node:size()):addTo(node, 1, "_panel_")
	local count = itertools.size(cfg.totemGroup1)
	local color = csv.totem.symbol_group[cfg.symbolGroupType].spineAnimation
	local aniStr = string.format("%s_%d_hou_loop", color, TotemTools.panelReflect[count])

	if dataEasy.isUnlock(gUnlockCsv.totemStar) then
		local totemStar = gGameModel.totem:read("totem_star")

		if totemStar and totemStar[csvId] and totemStar[csvId] > 0 then
			aniStr = string.format("%s_%d_xingjie_loop", color, TotemTools.panelReflect[count])
		end
	end

	local offset = {
		{
			-12,
			-270
		},
		{
			-8,
			-300
		},
		{
			-10,
			-305
		}
	}
	local xy = offset[TotemTools.panelReflect[size]]

	widget.addAnimationByKey(panel, "tuteng/tutengdx.skel", "bgSpine", aniStr, 5):scale(1):xy(panelSize.width / 2 + xy[1], panelSize.height / 2 + xy[2])

	return panel, scale
end

TotemTools.offset = {
	{
		400,
		45
	},
	{
		400,
		45
	},
	{
		400,
		45
	},
	{
		400,
		45
	},
	{
		300,
		0
	},
	{
		300,
		0
	},
	{
		300,
		0
	},
	{
		165,
		-90
	},
	{
		165,
		-90
	}
}

function TotemTools.getOneNode(panel, csvId, index, params)
	local cfg = csv.totem.symbol[csvId]
	local item = getItem({
		csvId = cfg.totemGroup1[index]
	})
	local size = itertools.size(cfg.totemGroup1) or 3
	local xx, yy = TotemTools.offset[size][1], TotemTools.offset[size][2]

	item:scale(params.scale or 1):addTo(panel, 10, "item" .. index):xy((TotemTools.totemPosition[size][index][1] - xx) / 2, (TotemTools.totemPosition[size][index][2] - yy) / 2)

	return item
end

function TotemTools.initData(node, id, params)
	TotemTools.refreshData(id, params, node)
end

function TotemTools.attrMultraction(cfgData, starCfg)
	local num, percent

	if string.find(cfgData, "%%") then
		cfgData = string.sub(cfgData, 1, #cfgData - 1)
		percent = starCfg.attrPercent2
		num = cfgData * string.sub(percent, 1, #percent - 1) * 0.01

		return mathEasy.getPreciseDecimal(num, 2, true) .. "%"
	end

	percent = starCfg.attrPercent
	num = cfgData * string.sub(percent, 1, #percent - 1) * 0.01

	return mathEasy.getPreciseDecimal(num, 0, true)
end

function TotemTools.getActivateTotem(data)
	local cfg = csv.totem.symbol
	local activeGroup = {}
	local isUnlock = dataEasy.isUnlock(gUnlockCsv.totemStar)
	local totemStar = {}

	if isUnlock then
		totemStar = gGameModel.totem:read("totem_star")
	end

	for i, v in pairs(data) do
		if cfg[i] and (itertools.size(cfg[i].totemGroup1) <= itertools.size(v) or isUnlock and totemStar[i]) then
			table.insert(activeGroup, i)
		end
	end

	return activeGroup
end

function TotemTools.getActivateTotemEnergy(activeTotem)
	local activityData = TotemTools.getActivateTotem(activeTotem)
	local energy = 0
	local totemStar = gGameModel.totem:read("totem_star") or {}

	for i, v in pairs(activityData) do
		energy = energy + csv.totem.symbol[v].power * (1 + TotemTools.getActivateTotemExtraEnergyPercent(v, totemStar[v]))
	end

	return energy
end

function TotemTools.getActivateTotemExtraEnergyPercent(csvID, starLevel)
	local energyPercent = 0

	if dataEasy.isUnlock(gUnlockCsv.totemStar) and starLevel and starLevel > 0 then
		energyPercent = dataEasy.parsePercentStr(gTotemStarIdCsv[csv.totem.symbol[csvID].starSeqID][starLevel].energyPercent) / 100
	end

	return energyPercent
end

function TotemTools.isShowAndNotUse()
	local countEnegy = TotemTools.getActivateTotemEnergy(gGameModel.totem:read("totem_insetted"))

	return countEnegy >= gCommonConfigCsv.totemStarShowNeedEnergy and countEnegy < gCommonConfigCsv.totemStarUnlockNeedEnergy
end

function TotemTools.isUnlockUse()
	local countEnegy = TotemTools.getActivateTotemEnergy(gGameModel.totem:read("totem_insetted"))

	return countEnegy >= gCommonConfigCsv.totemStarUnlockNeedEnergy
end

return TotemTools
