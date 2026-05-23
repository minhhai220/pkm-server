-- chunkname: @src.app.easy.bind.extend.auto_chess_card1

local helper = require("easy.bind.helper")
local STAR_POS = {
	{
		{
			scale = 0.5,
			x = 0,
			y = 0
		}
	},
	{
		{
			x = -20,
			y = 0
		},
		{
			x = 20,
			y = 0
		}
	},
	[4] = {
		{
			x = -20,
			y = 20
		},
		{
			x = 20,
			y = 20
		},
		{
			x = -20,
			y = -20
		},
		{
			x = 20,
			y = -20
		}
	}
}
local RARITY = {
	"hui",
	"lv",
	"lan",
	"zi",
	"huang"
}
local EVENT_TYPE = {
	"dc",
	"cxx",
	"cd"
}
local autoChessCard1 = class("autoChessCard1", cc.load("mvc").ViewBase)

autoChessCard1.RARITY = RARITY

local cards = {}

cards.RESOURCE_FILENAME = "auto_chess_common_card1.json"
cards.RESOURCE_BINDING = {
	panelEquip2 = "panelEquip2",
	["panelDmg.bg"] = "dmgBg",
	panelStar = "panelStar",
	panelDef = "panelDef",
	panelHp = "panelHp",
	panelDmg = "panelDmg",
	panelEvent = "panelEvent",
	["panelIcon.icon"] = "icon",
	panelIcon = "panelIcon",
	cardFrame = "cardFrame",
	cardBg = "cardBg",
	panelEquip1 = "panelEquip1",
	["panelStar.bg"] = "starBg",
	["panelDef.bg"] = "defBg",
	["panelHp.bg"] = "hpBg",
	["panelDmg.txt"] = {
		varname = "dmgText",
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 6,
					color = cc.c3b(35, 33, 33)
				}
			}
		}
	},
	["panelHp.txt"] = {
		varname = "hpText",
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 6,
					color = cc.c3b(35, 33, 33)
				}
			}
		}
	},
	["panelDef.txt"] = {
		varname = "defText",
		binds = {
			event = "effect",
			data = {
				color = cc.c3b(251, 248, 233),
				outline = {
					size = 6,
					color = cc.c3b(35, 33, 33)
				}
			}
		}
	},
	["panelEvent.name"] = {
		varname = "eventName",
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 6,
					color = cc.c3b(35, 33, 33)
				}
			}
		}
	}
}
autoChessCard1.defaultProps = {
	star = 1,
	grayState = 0
}

local function getValue(idler)
	if isIdler(idler) then
		return idler:read()
	end

	return idler
end

function autoChessCard1:initExtend(simpleView)
	if not tolua.isnull(self.node) then
		self.node:removeSelf()
	end

	local node = gGameUI:createSimpleView(simpleView or cards, self):init()

	self.node = node

	node:size(node:getResourceNode():size()):anchorPoint(0.5, 0.5)
	self:buildExtend()

	return self
end

function autoChessCard1:buildExtend()
	local node = self.node

	helper.callOrWhen(self.id, function(id)
		local cfg = csv.auto_chess.cards[id]

		self._type = "card"

		if not cfg then
			cfg = csv.auto_chess.equip[id]
			self._type = "equip"
		end

		if not cfg then
			cfg = csv.auto_chess.event[id]
			self._type = "event"
		end

		if not cfg then
			printError("auto_chess_card id(%s) error", tostring(id))

			self._type = nil

			return
		end

		self.cfg = cfg

		itertools.invoke({
			self.node.panelDmg,
			self.node.panelHp,
			self.node.panelDef,
			self.node.panelStar,
			self.node.panelEvent,
			self.node.panelEquip1,
			self.node.panelEquip2
		}, "hide")

		if self._type == "card" then
			itertools.invoke({
				self.node.panelDmg,
				self.node.panelHp,
				self.node.panelStar
			}, "show")
		elseif self._type == "equip" then
			itertools.invoke({
				self.node.panelDmg,
				self.node.panelHp
			}, "show")
		elseif self._type == "event" then
			itertools.invoke({
				self.node.panelEvent
			}, "show")

			if node.eventName then
				node.eventName:text(cfg.name)
				node.eventName:hide()
			end

			node.panelEvent:get("signBg"):texture(string.format("lushi/icon_zzqsj_%s.png", RARITY[cfg.rarity]))
			node.panelEvent:get("signIcon"):texture(string.format("lushi/icon_zzq_%s.png", EVENT_TYPE[cfg.type]))
		end

		node.icon:texture(cfg.res):xy(node.panelIcon:width() / 2 + cfg.resPos.x, node.panelIcon:height() / 2 + cfg.resPos.y):scale(cfg.resScale)
		node.cardBg:texture(string.format("lushi/icon_zzqbg_%s.png", RARITY[cfg.rarity]))
		node.dmgBg:texture(string.format("lushi/icon_zzqgj_%s.png", RARITY[cfg.rarity]))
		node.hpBg:texture(string.format("lushi/icon_zzqxl_%s.png", RARITY[cfg.rarity]))
		node.starBg:texture(string.format("lushi/icon_zzqxj_%s.png", RARITY[cfg.rarity]))
		node.cardFrame:texture(string.format("lushi/icon_zzqkp_%s.png", RARITY[cfg.rarity]))
		self:_setData()
	end)

	local midPos = cc.p(node.panelStar:width() / 2, node.panelStar:height() / 2)

	helper.callOrWhen(self.star, function(star)
		if not itertools.include(itertools.keys(STAR_POS), star) then
			printError("auto_chess_card star(%s) 不在定义范围内", tostring(str))

			return
		end

		for i = 1, 4 do
			local starObj = node.panelStar:get("star" .. i)

			if i <= star then
				starObj:show():xy(cc.pAdd(midPos, STAR_POS[star][i]))

				if STAR_POS[star][i].scale and star == 1 then
					starObj:scale(STAR_POS[star][i].scale)
				else
					starObj:scale(0.4)
				end
			else
				starObj:hide()
			end
		end

		self:_setData()
	end)
	self:_initGray()

	if self.onNode then
		self.onNode(node)
	end

	return self
end

function autoChessCard1:getEnv()
	return {
		self = {
			star = function()
				return getValue(self.star)
			end
		},
		star = getValue(self.star)
	}
end

function autoChessCard1:_initGray()
	local grayState = self.grayState ~= 0 and cc.c3b(180, 180, 180) or cc.c3b(255, 255, 255)

	for _, child in pairs(self.node:getResourceNode():getChildren()) do
		child:color(grayState)
	end

	for _, obj in pairs({
		self.node.panelStar,
		self.node.panelDmg,
		self.node.panelHp,
		self.node.panelDef,
		self.node.panelEquip1,
		self.node.panelEquip2,
		self.node.panelEvent
	}) do
		for _, child in pairs(obj:getChildren()) do
			child:color(grayState)
		end
	end

	self.node.icon:color(grayState)
	cache.setShader(self.node, false, self.grayState == 2 and "hsl_gray" or "normal")
end

function autoChessCard1:_setData()
	if not self.cfg then
		return self
	end

	self.defaultAttr = {
		attack = tonumber(eval.doMixedFormula(string.format("$%s$", self.cfg.attack), self:getEnv())),
		hp = tonumber(eval.doMixedFormula(string.format("$%s$", self.cfg.hp), self:getEnv())),
		defence = tonumber(eval.doMixedFormula(string.format("$%s$", self.cfg.defence), self:getEnv()))
	}

	self:setData(self.defaultAttr)

	return self
end

function autoChessCard1:setData(params)
	if not self.cfg then
		return self
	end

	params = params or {}

	if params.attack then
		local attack = math.max(tonumber(params.attack) or 0, 0)

		adapt.setTextScaleWithWidth(self.node.dmgText, attack, 200)

		local color = cc.c4b(255, 252, 237, 255)

		if attack > self.defaultAttr.attack then
			color = cc.c4b(57, 231, 127, 255)
		elseif attack < self.defaultAttr.attack then
			color = cc.c4b(250, 71, 95, 255)
		end

		text.addEffect(self.node.dmgText, {
			color = color
		})

		if params.action then
			local scale = self.node.dmgText:scale()

			transition.executeSequence(self.node.dmgText, true):scaleTo(0.15, scale * 2, scale * 2):easeBegin("BOUNCEOUT"):scaleTo(0.3, scale, scale):easeEnd():done()
		end
	end

	if params.hp then
		adapt.setTextScaleWithWidth(self.node.hpText, params.hp, 200)

		local hp = tonumber(params.hp) or 0
		local color = cc.c4b(255, 252, 237, 255)

		if hp > self.defaultAttr.hp then
			color = cc.c4b(57, 231, 127, 255)
		elseif hp < self.defaultAttr.hp then
			color = cc.c4b(250, 71, 95, 255)
		end

		text.addEffect(self.node.hpText, {
			color = color
		})
		adapt.setTextScaleWithWidth(self.node.hpText, params.hp, 200)

		if params.action then
			local scale = self.node.hpText:scale()

			transition.executeSequence(self.node.hpText, true):scaleTo(0.15, scale * 2, scale * 2):easeBegin("BOUNCEOUT"):scaleTo(0.3, scale, scale):easeEnd():done()
		end
	end

	if params.broken or params.defence then
		local broken = math.max(tonumber(params.broken) or 0, 0)

		if broken > 0 then
			self.node.panelDef:show()
			self.node.defBg:loadTexture("lushi/icon_zzq_fh1.png")
			adapt.setTextScaleWithWidth(self.node.defText, -broken, 200)
		else
			local defence = math.max(tonumber(params.defence) or 0, 0)

			if defence == 0 then
				self.node.panelDef:hide()
			else
				self.node.defBg:loadTexture("lushi/icon_zzq_fh.png")
				self.node.panelDef:show()
				adapt.setTextScaleWithWidth(self.node.defText, defence, 200)
			end
		end
	end

	if params.equips then
		for i = 1, 2 do
			local obj = self.node["panelEquip" .. i]:hide()

			if params.equips[i] then
				local equipCfg = csv.auto_chess.equip[params.equips[i]]

				obj:show()
				obj:get("icon"):texture(equipCfg.res)
			end
		end
	end

	return self
end

return autoChessCard1
