-- chunkname: @src.util.language

local format = string.format
local insert = table.insert

function globals.getShowLanguage()
	local showLanguage = getBaseLanguage() or LOCAL_LANGUAGE

	if SHOW_LANGUAGES then
		local lang = userDefault.getForeverLocalKey("SHOW_LANGUAGE", nil, {
			rawKey = true
		})

		if not lang then
			local langCode = cc.Application:getInstance():getCurrentLanguageCode()

			if langCode == "ru" then
				lang = "rus"
			elseif langCode == "es" then
				lang = "esp"
			elseif langCode == "id" then
				lang = "idn"
			end
		end

		local hash = arraytools.hash(SHOW_LANGUAGES, true)

		if hash[lang] then
			showLanguage = lang
		end
	end

	return showLanguage
end

function globals.isShowLanguage()
	local showLanguage = getShowLanguage()

	return itertools.include({
		"rus",
		"esp",
		"idn"
	}, showLanguage)
end

function globals.getShowLanguageList()
	local showLanguage = getShowLanguage()
	local baseLanguage = getBaseLanguage()
	local t = {}

	if #showLanguage == 3 then
		insert(t, format("%s_%s", LOCAL_LANGUAGE, showLanguage))

		if baseLanguage then
			insert(t, format("%s_%s", baseLanguage, showLanguage))
		end

		insert(t, showLanguage)
		insert(t, LOCAL_LANGUAGE)

		if baseLanguage then
			insert(t, baseLanguage)
		end
	else
		if baseLanguage == showLanguage then
			insert(t, LOCAL_LANGUAGE)
		end

		insert(t, showLanguage)
	end

	if not itertools.include(t, "cn") then
		insert(t, "cn")
	end

	return t
end

function globals.getBaseLanguage(language)
	language = language or LOCAL_LANGUAGE

	local p = string.find(language, "_")

	if p then
		return string.sub(language, 1, p - 1)
	end

	return nil
end

function globals.getL10nField(field, language)
	language = language or LOCAL_LANGUAGE

	if language == "cn" then
		return field
	else
		local path = format("%s_%s", field, language)
		local pathBase = getBaseLanguage(language)

		pathBase = pathBase and format("%s_%s", field, pathBase)

		return path, pathBase
	end
end

function globals.getL10nStr(csv, field, language)
	language = language or LOCAL_LANGUAGE

	if language == "cn" then
		return csv[field]
	else
		return csv[format("%s_%s", field, language)]
	end
end

function globals.checkLanguage(language)
	language = language or "cn"

	return matchLanguage({
		language
	})
end

function globals.matchLanguageForce(t, language)
	language = language or LOCAL_LANGUAGE
	t = t or {}

	for k, v in pairs(t) do
		if v == language then
			return true
		end
	end

	return false
end

function globals.matchLanguage(t, language)
	language = language or LOCAL_LANGUAGE
	t = t or {}

	local baseLanguage = getBaseLanguage(language)

	for k, v in pairs(t) do
		if v == language or v == baseLanguage then
			return true
		end
	end

	return false
end

function globals.getServerTag(servKey)
	if servKey then
		return string.split(servKey, ".")[2]
	end
end

function globals.getServerId(servKey, isOrgin)
	if gDestServer[servKey] then
		return gDestServer[servKey].id
	end

	if not isOrgin and gServersMergeID[servKey] then
		return csv.server.merge[gServersMergeID[servKey]].serverID
	end

	return tonumber(string.split(servKey, ".")[3])
end

function globals.getServerArea(servKey, showShort, isOrgin)
	local tag = getServerTag(servKey)
	local id = getServerId(servKey, isOrgin)
	local channelName = SERVER_MAP[tag] and SERVER_MAP[tag].name or ""

	if showShort then
		local str = "S" .. id

		if channelName ~= "" then
			str = string.format("%s.%s", channelName, str)
		end

		return str
	end

	return string.format("%s%d%s", channelName, id, matchLanguageForce({
		"kr",
		"en_us",
		"en_eu"
	}) and "" or gLanguageCsv.serverArea)
end

function globals.getServerName(servKey, isOrgin)
	local tag = getServerTag(servKey)
	local id = getServerId(servKey, isOrgin)
	local mergeKey = string.format("game.%s.%s", tag, id)

	if not SERVERS_INFO[mergeKey] then
		return ""
	end

	return SERVERS_INFO[mergeKey].name
end

function globals.getShortMergeRoleName(name)
	local gameKey = userDefault.getForeverLocalKey("serverKey", nil, {
		rawKey = true
	})

	if gServersMergeID[gameKey] then
		local id = getServerId(gameKey)
		local pos = string.find(name, string.format(".s%d$", id))

		if pos then
			return string.sub(name, 1, pos - 1)
		end
	end

	return name
end

function globals.isCurServerContainMerge(servKey)
	local gameKey = userDefault.getForeverLocalKey("serverKey", nil, {
		rawKey = true
	})

	if gDestServer[servKey] then
		return itertools.include(gDestServer[servKey].servers, gameKey)
	end

	return servKey == gameKey
end

function globals.getVersionContainMerge(key)
	local gameKey = userDefault.getForeverLocalKey("serverKey", nil, {
		rawKey = true
	})
	local mergeId = gServersMergeID[gameKey]
	local version = mergeId and csv.server.merge[mergeId][key] or 0

	return version
end

function globals.getMergeServers(servers)
	local hash = {}
	local mergeServers = {}

	for _, server in ipairs(servers) do
		local tag = getServerTag(server)
		local id = getServerId(server)
		local mergeKey = string.format("game.%s.%s", tag, id)

		if not hash[mergeKey] then
			hash[mergeKey] = true

			table.insert(mergeServers, mergeKey)
		end
	end

	return mergeServers
end

function globals.isServerTagInCross(cross)
	local gameKey = userDefault.getForeverLocalKey("serverKey", nil, {
		rawKey = true
	})
	local tag = getServerTag(gameKey)

	if tag == "cn_huawei" then
		tag = "cn_qd"
	end

	local crossTag = getServerTag(cross) or cross

	return tag == crossTag
end
