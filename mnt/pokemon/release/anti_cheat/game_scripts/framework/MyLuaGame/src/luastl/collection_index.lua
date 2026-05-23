-- chunkname: @src.luastl.collection_index

CCollection.index = {}
CCollection.index.__index = CCollection.index

local IDCounter = 0
local order_stats_count = 0
local order_stats_sort = 0
local order_stats_sort_load = 0
local order_stats_get = 0
local order_stats_delete = 0
local hash_stats_count = 0
local hash_stats_update = 0
local hash_stats_index = 0
local hash_stats_delete = 0
local filter_stats_count = 0
local filter_stats_miss = 0
local update_stats = {}

function CCollection.index.new(name)
	IDCounter = IDCounter + 1

	return setmetatable({
		_immutably = true,
		changedcount = 0,
		id = IDCounter,
		name = name
	}, CCollection.index)
end

function CCollection.index.hash(t, field)
	if type(field) == "table" then
		t._fields = field

		function t._hashf(k, v)
			local h = v

			for _, name in ipairs(field) do
				h = h[name]
			end

			return h
		end
	else
		t._field = field

		function t._hashf(k, v)
			return v[field]
		end
	end

	return t
end

function CCollection.index.hash_byfunc(t, f)
	t._hashf = f

	return t
end

function CCollection.index.filter(t, f)
	t._filter = f

	return t
end

function CCollection.index.order(t, cmp)
	t._cmp = cmp

	return t
end

function CCollection.index.order_bykey(t, cmp)
	t._keycmp = cmp

	return t
end

function CCollection.index.value_immutably(t, flag)
	if flag == nil then
		flag = true
	end

	t._immutably = flag

	return t
end

function CCollection.index.default(t)
	t._default = true

	return t
end

function CCollection.index.stats()
	return {
		order_index = {
			count = order_stats_count,
			sort = order_stats_sort,
			sort_load = order_stats_sort_load,
			get = order_stats_get,
			delete = order_stats_delete
		},
		hash_index = {
			count = hash_stats_count,
			update = hash_stats_update,
			index = hash_stats_index,
			delete = hash_stats_delete
		},
		filter = {
			count = filter_stats_count,
			miss = filter_stats_miss
		},
		update = update_stats
	}
end

function CCollection.index.build_(t, c)
	t._c = c
	t = setmetatable(t, CCollection.index_impl)

	if t._filter then
		t.keyhash = {}
	end

	if t._cmp then
		assert(not t._keycmp, "only one between order or order_bykey")

		order_stats_count = order_stats_count + 1

		local cmp = t._cmp
		local m = c.m

		function t._keycmp(k1, k2)
			return cmp(m[k1], m[k2])
		end
	end

	if t._hashf then
		hash_stats_count = hash_stats_count + 1
		t.hash = {}
		t.hashsize = {}

		if not t._immutably then
			t.oldhash = {}
		end

		for k, v in c:pairs() do
			t:update_hash_(c, "insert", k, v)
		end
	end

	if t._default then
		assert(t._keycmp, "CCollection no order index")

		if c.defaultindex then
			c:delete_index(c.defaultindex)
		end

		c.defaultindex = t
	end

	return t
end

CCollection.index_impl = {}
CCollection.index_impl.__index = CCollection.index_impl

function CCollection.index_impl:is_order()
	return self._keycmp ~= nil
end

function CCollection.index_impl:is_hash()
	return self._hashf ~= nil
end

function CCollection.index_impl:size()
	assert(self._filter == nil, "filter size not implement")

	return self._c:size()
end

function CCollection.index_impl:get_order()
	if self._keycmp then
		return self:get_order_()
	end

	error("CCollection index no order")
end

function CCollection.index_impl:sort_for(keys)
	if self._keycmp then
		table.sort(keys, self._keycmp)

		return keys
	end

	error("CCollection index no order")
end

function CCollection.index_impl:group(key)
	if self.hash then
		hash_stats_index = hash_stats_index + 1

		local h = self.hash[key]

		if h == nil then
			return self._c:single_result_()
		end

		if type(h) == "table" then
			local first = next(h)

			if first == nil then
				return self._c:single_result_()
			end

			return self._c:hash_result_(h, self.hashsize[key] or 0)
		end

		return self._c:single_result_(h)
	end

	error(string.format("CCollection index no hash group(%s)", key))
end

function CCollection.index_impl:update(reason, key, value)
	local keyhash = self.keyhash
	local inset = true

	if self._filter then
		inset = self._filter(key, value)
		filter_stats_count = filter_stats_count + 1
		filter_stats_miss = filter_stats_miss + (inset and 0 or 1)
	end

	local changed = true

	if inset then
		if reason == "insert" or reason == "change" then
			if keyhash then
				keyhash[key] = true
			end
		elseif keyhash then
			changed = keyhash[key] ~= nil
			keyhash[key] = nil
		end
	elseif keyhash and keyhash[key] then
		reason = "erase"
		keyhash[key] = nil
	else
		changed = false
	end

	update_stats[reason] = (update_stats[reason] or 0) + 1

	if changed then
		if self._hashf then
			self:update_hash_(reason, key, value)
		end

		if self._keycmp then
			self:update_order_(reason, key, value)
		end
	end
end

function CCollection.index_impl:erase_hash_key_(key, hkey, h)
	if h ~= nil then
		if type(h) == "table" then
			local idx = h[key]

			assert(idx, "hash index could not find the key, may be had diff hash key")

			h[key] = nil

			if idx then
				self.hashsize[hkey] = self.hashsize[hkey] - 1
			end
		else
			assert(h == key, "hash index had diff hash key with the same value")

			self.hash[hkey] = nil
			self.hashsize[hkey] = 0
		end

		self.changedcount = self.changedcount + 1
	end
end

function CCollection.index_impl:update_hash_(reason, key, value)
	local hkey_ = self._hashf(key, value)
	local setit = reason == "insert"

	setit = setit or reason == "change" and not self._immutably

	local oldhkey_ = self.oldhash and self.oldhash[key]

	if setit and reason == "change" and oldhkey_ then
		if type(oldhkey_) == "table" then
			for _, oldhkey in ipairs(oldhkey_) do
				self:erase_hash_key_(key, oldhkey, self.hash[oldhkey])
			end
		else
			self:erase_hash_key_(key, oldhkey_, self.hash[oldhkey_])
		end
	end

	if type(hkey_) == "table" then
		for _, hkey in ipairs(hkey_) do
			self:update_hash_one_(setit, key, value, hkey)
		end
	else
		self:update_hash_one_(setit, key, value, hkey_)
	end

	if setit and self.oldhash then
		self.oldhash[key] = hkey_
	end
end

function CCollection.index_impl:update_hash_one_(setit, key, value, hkey)
	hash_stats_update = hash_stats_update + 1

	local h = self.hash[hkey]

	if setit then
		if h == nil then
			self.hash[hkey] = key
			self.hashsize[hkey] = 1
			self.changedcount = self.changedcount + 1
		elseif type(h) == "table" then
			local num = h[key] and 0 or 1

			h[key] = true
			self.hashsize[hkey] = self.hashsize[hkey] + num
			self.changedcount = self.changedcount + num
		elseif h ~= key then
			self.hash[hkey] = {
				[key] = true,
				[h] = true
			}
			self.hashsize[hkey] = 2
			self.changedcount = self.changedcount + 1
		end
	else
		self:erase_hash_key_(key, hkey, h)
	end
end

function CCollection.index_impl:lower_bound_(arr, n, val)
	local cmp = self._keycmp
	local l, r = 1, n + 1

	while l < r do
		local mid = math.floor((l + r) / 2)

		if cmp(arr[mid], val) then
			l = mid + 1
		else
			r = mid
		end
	end

	return l
end

function CCollection.index_impl:get_order_()
	order_stats_get = order_stats_get + 1

	if self.order == nil then
		if self.realtimeorder then
			self.order = self.realtimeorder
			self.realtimeorder = nil
		else
			local keys = table.keys(self.keyhash or self._c.m)

			table.sort(keys, self._keycmp)

			self.order = keys
			order_stats_sort = order_stats_sort + 1

			if #keys > 0 then
				order_stats_sort_load = order_stats_sort_load + math.log(#keys) * #keys
			end
		end
	end

	return self.order
end

function CCollection.index_impl:update_order_(reason, key, value)
	if reason == "change" then
		if self._cmp == nil or self._immutably then
			return
		end

		self.realtimeorder = nil
	end

	if reason == "insert" or reason == "erase" then
		local n = self:size()

		if n > 24 and self.order then
			self.realtimeorder = arraytools.values(self.order)
		end

		if self.realtimeorder then
			local order = self.realtimeorder

			n = n + (reason == "insert" and -1 or 1)

			if device.platform == "windows" then
				assert(n == table.length(order), "order size error")
			end

			if reason == "erase" then
				self._c.m[key] = value
			end

			local index = self:lower_bound_(order, n, key)

			if reason == "insert" then
				table.insert(order, index, key)
			else
				assert(order[index] == key, "lower_bound_ error")

				self._c.m[key] = nil

				table.remove(order, index)
			end
		end
	end

	self.order = nil
	self.changedcount = self.changedcount + 1
	order_stats_delete = order_stats_delete + 1
end

function CCollection.index_impl:clear()
	self.order = nil
	self.realtimeorder = nil

	if self.hash then
		hash_stats_delete = hash_stats_delete + 1
		self.hash = {}
		self.hashsize = {}
	end

	if self._cmp then
		order_stats_delete = order_stats_delete + 1

		local cmp = self._cmp
		local m = self._c.m

		function self._keycmp(k1, k2)
			return cmp(m[k1], m[k2])
		end
	end

	self.changedcount = self.changedcount + 1
end
