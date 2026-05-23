

function BattleView:onViewProxyNotify(msg, ...)
	return self.subModuleNotify:notify(msg, ...)
end

function BattleView:onViewProxyCall(msg, ...)
	return self.subModuleNotify:call(msg, ...)
end

function BattleView:onViewBeProxy(view, proxy)
	return self.subModuleNotify:notify("ViewBeProxy", view, proxy)
end

function BattleView:addSpecModule(mods)
	self.subModuleNotify:addSpec(mods)
end

