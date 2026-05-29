-- chunkname: @src.app.views.city.adventure.clone_battle.base

local ViewBase = cc.load("mvc").ViewBase
local CloneBattleBaseView = class("CloneBattleBaseView", ViewBase)

CloneBattleBaseView.RESOURCE_FILENAME = "clone_battle_base.json"
CloneBattleBaseView.RESOURCE_BINDING = {}

function CloneBattleBaseView:onCreate(data)
	local pnode = self:getResourceNode()
	local size = pnode:size()

	self.bgAni = widget.addAnimation(pnode, "huizhangbeijing/yuansudizuo.skel", "effect_1_loop", 2):scale(2):xy(size.width / 2, size.height / 2):hide()
	self.bgAniB = widget.addAnimation(pnode, "huizhangbeijing/yuansubeijing.skel", "effect_loop", 1):scale(2):xy(size.width / 2, size.height / 2):hide()
	self.bgAniF = widget.addAnimation(pnode, "huizhangbeijing/yuansu_qianjing.skel", "effect_loop", 11):scale(2):xy(size.width / 2, size.height / 2):hide()

	if data then
		self.data = data

		self:refreshView()
	else
		self:refresh()
	end
end

function CloneBattleBaseView:onCleanup()
	if self.view then
		self.view:removeFromParent()

		self.view = nil
	end

	ViewBase.onCleanup(self)
end

function CloneBattleBaseView:refresh()
	gGameApp:requestServer("/game/clone/get", function(tb)
		self.data = tb.view

		self:refreshView()
	end)
end

function CloneBattleBaseView:refreshView(data)
	self.data = data or self.data

	if self.view then
		self.view:onClose()

		self.view = nil

		self.bgAni:hide()
	end

	local dbId = gGameModel.role:read("clone_room_db_id")

	if dbId then
		self.bgAniB:visible(false)
		self.bgAniF:visible(false)

		self.view = gGameUI:createView("city.adventure.clone_battle.room", self:getResourceNode()):init(self):x(display.uiOrigin.x):z(3)
	else
		self:playBgAni(nil)
		self.bgAniB:visible(true)
		self.bgAniF:visible(true)

		self.view = gGameUI:createView("city.adventure.clone_battle.view", self:getResourceNode()):init(self.data, self):x(display.uiOrigin.x):z(3)
	end

	gGameUI.topuiManager:createView("default", self, {
		onClose = self:createHandler("onClose")
	}):init({
		subTitle = "CloneBattle",
		title = gLanguageCsv.clone
	})
end

function CloneBattleBaseView:playBgAni(natureId)
	if natureId then
		self.bgAni:show()
		self.bgAni:play("effect_" .. natureId .. "_loop")
	else
		self.bgAni:hide()
	end
end

return CloneBattleBaseView
