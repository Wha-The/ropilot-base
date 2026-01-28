local prefixes = {"k", "m", "b", "t", "qa", "qi", "sx", "sp", "o", "n", "d", "ud", "dd", "td", "qd", "qnd", "sxd", "ocd", "nod", "vg", "uvg", "dvg", "tvg", "qavg", "qivg", "sxvg", "spvg", "ocvg"}
local UPPERCASE_PREFIXES = true -- adjust based on your needs - @whut
local std = shared.std

-- formats the number and adds commas
local function ShortenNumberComma(n)
	local formatted = n
	local replacements = 1
	while replacements > 0 do
		formatted, replacements = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
	end
	return formatted
end

local function FormatNumber(n, comma)
	if comma then return ShortenNumberComma(n) end
    if not tonumber(n) then return n end
    n = tonumber(n)
    if n < 1_000_000 then
		return ShortenNumberComma(math.floor(n))
	end
    local d = math.floor(math.log10(n) / 3) * 3
    local s = std.Util.SigFig(n / (10^d), 4)

	if UPPERCASE_PREFIXES then
    	return s ..string.upper(tostring(prefixes[math.floor(d / 3)]))
	else
		return s ..(tostring(prefixes[math.floor(d / 3)]))
	end
end

return FormatNumber