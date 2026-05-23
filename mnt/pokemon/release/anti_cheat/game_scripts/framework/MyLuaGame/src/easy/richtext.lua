-- chunkname: @src.easy.richtext

local rich = {}

globals.rich = rich

function rich.color(color, text, blackEnd)
	if blackEnd == nil then
		blackEnd = true
	end

	return {
		text = text,
		color = color,
		blackEnd = blackEnd
	}
end

function rich.font(size, text)
	return {
		text = text,
		fontSize = size
	}
end

local function getColor(str)
	local num = tonumber(str)

	if #str > 8 then
		return cc.c4b(math.floor(num / 65536 % 256), math.floor(num / 256 % 256), num % 256, math.floor(num / 16777216))
	end

	return cc.c3b(math.floor(num / 65536), math.floor(num / 256 % 256), num % 256)
end

local function getLastVal(path)
	local val
	local p, q = string.find(path, "-[%d.]*$")

	if p and q then
		val = path:sub(p + 1, q)
		path = path:sub(1, p - 1)
	end

	return path, val
end

local function getFlags(v)
	local flags = tonumber(string.sub(v, 2), 2)

	if flags then
		return {
			type = "flags",
			val = flags
		}
	end

	local chExtra = string.sub(v, 2, 3)
	local str = string.sub(v, 4)

	if chExtra == "SO" then
		local t = string.split(str, ",")

		if #t >= 2 then
			return {
				flags = "shaderOffset",
				type = "flags",
				val = cc.size(t[1], t[2])
			}
		else
			printWarn("richtext(%s): format may be like #LSO2,-2#", v)

			return
		end
	end

	if chExtra == "UL" then
		return {
			flags = "url",
			type = "flags",
			val = str
		}
	end

	local num = tonumber(str)

	if not num then
		printWarn("richtext(%s): format can't transform to number", v)

		return
	end

	if chExtra == "OC" then
		return {
			flags = "outlineColor",
			type = "flags",
			val = getColor(str)
		}
	end

	if chExtra == "OS" then
		return {
			flags = "outlineSize",
			type = "flags",
			val = num
		}
	end

	if chExtra == "SC" then
		return {
			flags = "shadowColor",
			type = "flags",
			val = getColor(str)
		}
	end

	if chExtra == "SR" then
		return {
			flags = "shadowBlurRadius",
			type = "flags",
			val = num
		}
	end

	if chExtra == "GC" then
		return {
			flags = "glowColor",
			type = "flags",
			val = getColor(str)
		}
	end

	printWarn("richtext(%s): chExtra Invalid", v)
end

local function _generateRichTexts(array, fontSize, deltaSize, adjustWidth)
	deltaSize = deltaSize or 0
	fontSize = fontSize or ui.FONT_SIZE

	local elems = {}
	local tag = 1
	local ttf = ui.FONT_PATH
	local opacity = 255
	local color = ui.COLORS.WHITE
	local textBgColor
	local flags = {}

	for k, t in ipairs(array) do
		if t.type == "color" then
			color = t.color
		elseif t.type == "font" then
			if t.path then
				ttf = t.path
			else
				fontSize = t.size + deltaSize
			end
		elseif t.type == "textBgColor" then
			textBgColor = t.color
		elseif t.type == "image" then
			local path = t.path or ""
			local url = flags.url or ""
			local element = ccui.RichElementImage:create(0, ui.COLORS.WHITE, 255, path, url)

			if t.width then
				element:setWidth(t.width)
				element:setHeight(t.heightOrScale)
			elseif t.heightOrScale then
				local img = cc.Sprite:create(path)
				local size = img:size()

				element:setWidth(size.width * t.heightOrScale)
				element:setHeight(size.height * t.heightOrScale)
			end

			table.insert(elems, {
				element
			})

			flags = {}
			textBgColor = nil
		elseif t.type == "spine" then
			local width = t.width * t.scale
			local height = t.height * t.scale
			local node = cc.Node:create()

			node:setContentSize(width, height)

			local url = flags.url or ""
			local element = ccui.RichElementCustomNode:create(0, ui.COLORS.WHITE, 255, node, url)
			local spine = CSprite.new(t.path)

			spine:play(t.action)
			spine:setPosition(cc.p(width / 2, height / 2))
			spine:scale(t.scale)
			node:addChild(spine)
			table.insert(elems, {
				element
			})

			flags = {}
			textBgColor = nil
		elseif t.type == "text" then
			local text = t.text

			if #text == 1 and text == "\n" then
				text = " " .. text
			end

			local outlineColor = flags.outlineColor or ui.COLORS.NORMAL.DEFAULT
			local outlineSize = flags.outlineSize or ui.DEFAULT_OUTLINE_SIZE
			local shadowColor = flags.shadowColor or ui.COLORS.NORMAL.DEFAULT
			local shaderOffset = flags.shaderOffset or cc.size(6, -6)
			local shadowBlurRadius = flags.shadowBlurRadius or 0
			local glowColor = flags.glowColor or ui.COLORS.NORMAL.DEFAULT
			local url = flags.url or ""

			if textBgColor then
				local params = {
					fontPath = ttf,
					fontSize = fontSize,
					color = color,
					effect = {}
				}

				if flags.val then
					if bit.band(flags.val, tonumber("100000", 2)) > 0 then
						params.effect.outline = {
							color = outlineColor,
							size = outlineSize
						}
					end

					if bit.band(flags.val, tonumber("1000000", 2)) > 0 then
						params.effect.shadow = {
							color = shadowColor,
							offset = shaderOffset,
							size = shadowBlurRadius
						}
					end

					if bit.band(flags.val, tonumber("10000000", 2)) > 0 then
						params.effect.glow = {
							color = glowColor
						}
					end
				end

				local labelText = label.create(text, params)
				local size = labelText:size()

				size.width = size.width * 1.05
				size.height = size.height * 1.05 + 2

				labelText:anchorPoint(0.5, 0.5):xy(size.width / 2, size.height / 2)

				local node = cc.Node:create()

				node:setContentSize(size.width + 2, size.height)

				local textBg = ccui.Scale9Sprite:create()

				textBg:initWithFile(cc.rect(13, 13, 1, 1), "common/box/box_jn.png")
				textBg:size(size):anchorPoint(0.5, 0.5):xy(size.width / 2, size.height / 2)
				textBg:color(textBgColor)
				node:addChild(textBg)
				node:addChild(labelText)

				local element = ccui.RichElementCustomNode:create(0, ui.COLORS.WHITE, 255, node, url)

				table.insert(elems, {
					element
				})
			else
				if adjustWidth and k < #array then
					text = text .. "\n"
				end

				local element = ccui.RichElementText:create(tag, color, opacity, text, ttf, fontSize, flags.val or 0, url, outlineColor, outlineSize, shadowColor, shaderOffset, shadowBlurRadius, glowColor)

				table.insert(elems, {
					element,
					{
						color,
						opacity,
						text,
						ttf,
						fontSize,
						flags.val or 0,
						url,
						outlineColor,
						outlineSize,
						shadowColor,
						shaderOffset,
						shadowBlurRadius,
						glowColor
					}
				})
			end

			flags = {}
			ttf = ui.FONT_PATH
			textBgColor = nil
		elseif t.type == "flags" then
			flags = flags or {}

			if t.flags then
				flags[t.flags] = t.val
			elseif bit.band(t.val, tonumber("10", 2)) > 0 then
				flags.val = t.val - tonumber("10", 2)
				ttf = "font/youmi1.ttf"
			else
				flags.val = t.val
			end
		end
	end

	return elems
end

local function _getRichTextsByStr(str, fontSize, deltaSize, adjustWidth)
	local nstr = string.gsub(str, "\\n", function(c)
		return "\n"
	end)
	local T = {}
	local start = 1

	while true do
		local l, r, ss = nstr:find("#([CFPTILD][^#]+)#", start)

		if l == nil then
			break
		end

		if start < l then
			table.insert(T, {
				s = nstr:sub(start, l - 1)
			})
		end

		table.insert(T, {
			format = true,
			s = ss
		})

		start = r + 1
	end

	if start <= #nstr then
		table.insert(T, {
			s = nstr:sub(start)
		})
	end

	local T2 = {}

	for k, t in ipairs(T) do
		local v = t.s
		local t2 = {}

		if t.format then
			local ch = string.sub(v, 1, 1)

			if ch == "C" then
				local num = tonumber(string.sub(v, 2))

				if num == nil then
					t2 = {
						type = "text",
						text = tostring(v)
					}
				else
					t2 = {
						type = "color",
						color = getColor(string.sub(v, 2))
					}
				end
			elseif ch == "F" then
				local size = tonumber(string.sub(v, 2))

				if size == nil or size > 200 or size < 0 then
					t2 = {
						type = "text",
						text = tostring(v)
					}
				else
					t2 = {
						type = "font",
						size = size
					}
				end
			elseif ch == "P" then
				local fontPath = string.sub(v, 2)

				t2 = {
					type = "font",
					path = fontPath
				}
			elseif ch == "T" then
				local str = string.sub(v, 2)
				local num, hOrScale = getLastVal(str)
				local num, w = getLastVal(num)

				num = tonumber(num)

				if num and csv.title[num] then
					local cfg = csv.title[num]
					local showType = cfg.showType

					if showType == "pic" then
						t2 = {
							type = "image",
							path = cfg.res,
							width = w,
							heightOrScale = hOrScale
						}
					elseif showType == "txt" then
						table.insert(T2, getFlags("L100000"))
						table.insert(T2, {
							flags = "outlineColor",
							type = "flags",
							val = cc.c4b(cfg.color[1], cfg.color[2], cfg.color[3], 255)
						})

						t2 = {
							type = "text",
							text = cfg.title
						}
					elseif showType == "spine" then
						t2 = {
							action = "effect_loop",
							type = "spine",
							path = cfg.res,
							scale = hOrScale or 1,
							width = cfg.spineSize[1],
							height = cfg.spineSize[2]
						}
					end
				end
			elseif ch == "I" then
				local resPath = string.sub(v, 2)
				local resPath, hOrScale = getLastVal(resPath)
				local resPath, w = getLastVal(resPath)

				t2 = {
					type = "image",
					path = resPath,
					width = w,
					heightOrScale = hOrScale
				}
			elseif ch == "D" then
				local num = tonumber(string.sub(v, 2))

				if num == nil then
					t2 = {
						type = "text",
						text = tostring(v)
					}
				else
					t2 = {
						type = "textBgColor",
						color = getColor(string.sub(v, 2))
					}
				end
			elseif ch == "L" then
				t2 = getFlags(v)
			end
		else
			v = tostring(v)

			if matchLanguage({
				"en"
			}) and v:byte(#v) == 10 then
				v = v .. "\n"
			end

			t2 = {
				type = "text",
				text = v
			}
		end

		if t2 and next(t2) then
			table.insert(T2, t2)
		end
	end

	return _generateRichTexts(T2, fontSize, deltaSize, adjustWidth)
end

local function _getRichTextsByArray(array, fontSize, deltaSize)
	local T2 = {}

	for _, t in ipairs(array) do
		if type(t) == "table" then
			if t.color then
				table.insert(T2, {
					type = "color",
					color = t.color
				})
				table.insert(T2, {
					type = "text",
					text = t.text
				})

				if t.blackEnd then
					table.insert(T2, {
						type = "color",
						color = ui.COLORS.WHITE
					})
				end
			elseif t.fontSize then
				table.insert(T2, {
					type = "font",
					size = t.fontSize
				})
				table.insert(T2, {
					type = "text",
					text = t.text
				})
			end
		else
			table.insert(T2, {
				type = "text",
				text = t
			})
		end
	end

	return _generateRichTexts(T2, fontSize, deltaSize)
end

local function round(f)
	local n = math.floor(f)
	local e = f - n

	if e < 0.5 then
		return n
	else
		return n + 1
	end
end

local function _binarySearchSplit(richTextTest, params, lineWidth)
	local tag = 1
	local color, opacity, s, ttf, fontSize, val, url, outlineColor, outlineSize, shadowColor, shaderOffset, shadowBlurRadius, glowColor = unpack(params)
	local l, r = 1, #s + 1

	while l < r do
		local mid = math.floor((l + r) / 2)
		local left = s:sub(1, mid)
		local elem = ccui.RichElementText:create(tag, color, opacity, left, ttf, fontSize, val, url, outlineColor, outlineSize, shadowColor, shaderOffset, shadowBlurRadius, glowColor)

		richTextTest:pushBackElement(elem)
		richTextTest:formatText()

		local size = richTextTest:getContentSize()

		if lineWidth < size.width then
			r = mid
		else
			l = mid + 1
		end

		richTextTest:removeElement(elem)
	end

	local split = r - 1

	while split > 0 and split < #s do
		if s:byte(split) == 32 then
			break
		else
			split = split - 1
		end
	end

	return split
end

local function _getRichTextsWordLineFeed(strOrArray, size, deltaSize, lineWidth, onlyElems)
	onlyElems = onlyElems or false

	local tag = 1
	local richText = onlyElems or ccui.RichText:create()
	local richTextTest = ccui.RichText:create()

	richTextTest:ignoreContentAdaptWithSize(true)

	local testCount = 0
	local retElems = {}
	local elems

	if type(strOrArray) == "table" then
		elems = _getRichTextsByArray(strOrArray, size, deltaSize)
	else
		elems = _getRichTextsByStr(strOrArray, size, deltaSize)
	end

	local lineElems = {}

	for _, t in ipairs(elems) do
		local elem, params = t[1], t[2]

		richTextTest:pushBackElement(elem)

		testCount = testCount + 1

		richTextTest:formatText()

		local size = richTextTest:getContentSize()

		while lineWidth < size.width do
			richTextTest:removeElement(elem)

			testCount = testCount - 1

			if tolua.type(elem) == "ccui.RichElementText" then
				local color, opacity, s, ttf, fontSize, val, url, outlineColor, outlineSize, shadowColor, shaderOffset, shadowBlurRadius, glowColor = unpack(params)
				local split = _binarySearchSplit(richTextTest, params, lineWidth)

				if split == 0 and #lineElems == 0 then
					break
				end

				local left = s:sub(1, split) .. "\n"

				table.insert(lineElems, {
					ccui.RichElementText:create(tag, color, opacity, left, ttf, fontSize, val, url, outlineColor, outlineSize, shadowColor, shaderOffset, shadowBlurRadius, glowColor),
					{
						color,
						opacity,
						left,
						ttf,
						fontSize,
						val,
						url,
						outlineColor,
						outlineSize,
						shadowColor,
						shaderOffset,
						shadowBlurRadius,
						glowColor
					}
				})

				local right = string.ltrim(s:sub(split + 1))

				elem = ccui.RichElementText:create(tag, color, opacity, right, ttf, fontSize, val, url, outlineColor, outlineSize, shadowColor, shaderOffset, shadowBlurRadius, glowColor)
				params[3] = right
			end

			for _, t2 in ipairs(lineElems) do
				if onlyElems then
					table.insert(retElems, t2)
				else
					richText:pushBackElement(t2[1])
				end
			end

			for i = testCount, 1, -1 do
				richTextTest:removeElement(i - 1)
			end

			lineElems = {}

			richTextTest:ignoreContentAdaptWithSize(false)
			richTextTest:ignoreContentAdaptWithSize(true)
			richTextTest:pushBackElement(elem)

			testCount = 1

			richTextTest:formatText()

			size = richTextTest:getContentSize()
		end

		table.insert(lineElems, {
			elem,
			params
		})
	end

	for _, t2 in ipairs(lineElems) do
		if onlyElems then
			table.insert(retElems, t2)
		else
			richText:pushBackElement(t2[1])
		end
	end

	return onlyElems and retElems or richText
end

function rich.createByArray(array, size, deltaSize, anchor)
	local richText = ccui.RichText:create()
	local elems = _getRichTextsByArray(array, size, deltaSize)

	for _, t in ipairs(elems) do
		local elem = t[1]

		if anchor then
			elem:setAnchorPoint(anchor)
		end

		richText:pushBackElement(elem)
	end

	return richText
end

function rich.createByStr(str, size, deltaSize, adjustWidth, anchor)
	local richText = ccui.RichText:create()
	local elems = _getRichTextsByStr(str, size, deltaSize, adjustWidth)

	for _, t in ipairs(elems) do
		local elem = t[1]

		if anchor then
			elem:setAnchorPoint(anchor)
		end

		richText:pushBackElement(elem)
	end

	return richText
end

function rich.adjustWidth(richText, fixedWidth, verticalSpace)
	if verticalSpace then
		richText:setVerticalSpace(verticalSpace)
	end

	richText:ignoreContentAdaptWithSize(false)
	richText:setContentSize(cc.size(fixedWidth, 0))
	richText:formatText()

	return richText:getContentSize()
end

function rich.createWithWidth(strOrArray, size, deltaSize, lineWidth, verticalSpace, anchor)
	local richText

	if matchLanguage({
		"en"
	}) then
		richText = _getRichTextsWordLineFeed(strOrArray, size, deltaSize, lineWidth)
	elseif type(strOrArray) == "table" then
		richText = rich.createByArray(strOrArray, size, deltaSize, anchor)
	else
		richText = rich.createByStr(strOrArray, size, deltaSize, true, anchor)
	end

	rich.adjustWidth(richText, lineWidth, verticalSpace)

	return richText
end

function rich.createElemsWithWidth(strOrArray, size, deltaSize, lineWidth)
	if matchLanguage({
		"en"
	}) then
		return _getRichTextsWordLineFeed(strOrArray, size, deltaSize, lineWidth, true)
	elseif type(strOrArray) == "table" then
		return _getRichTextsByArray(strOrArray, size, deltaSize)
	else
		return _getRichTextsByStr(strOrArray, size, deltaSize)
	end
end
