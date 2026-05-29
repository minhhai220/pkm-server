--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--


globals.battleCsv = {}

function battleCsv.exportToCsvCls(cls, export)
	for fname, modelIdx in pairs(export) do
		if modelIdx == 0 then
			assert(cls[fname] == nil, "exportToCsvCls function "..fname.. " is in csv")
			cls[fname] = function(self, ...)
				return self.model[fname](self.model, ...)
			end
		else
			-- now only support return only 1 model value
			cls[fname] = function(self, ...)
				local ret = self.model[fname](self.model, ...)
				local cls = battleCsv.Model2CsvCls[type(ret)]
				if cls then
					return cls.new(ret)
				end
				return ret
			end
		end
	end
end

function battleCsv.newCsvCls(name)
  local cls = setmetatable({}, {
    __newindex = function(t, k, v)
      if type(v) == "function" then
        v = functools.wrap(v, function(fn, self, ...)
          if self.model or t.ignoreModelCheck[k] then
            return fn(self, ...)
          end
          return 0
        end)
      end
      rawset(t, k, v)
    end
  })

  cls.__cname = name
  cls.__index = cls
  cls.ignoreModelCheck = {}

  rawset(cls, "newWithCache", function(model)
    if model then
      local cached = model:getCsvObject()
      if cached then return cached end
    end
    local wrapper = { model = model }
    if model then model:setCsvObject(wrapper) end
    return setmetatable(wrapper, cls)
  end)

  return cls
end





require "battle.csv.data"
require "battle.csv.buff"
require "battle.csv.scene"
require "battle.csv.skill"
require "battle.csv.object"
require "battle.csv.export"

battleCsv.NilBuff = battleCsv.CsvBuff.newWithCache()
battleCsv.NilSkill = battleCsv.CsvSkill.newWithCache()
battleCsv.NilObject = battleCsv.CsvObject.newWithCache()
