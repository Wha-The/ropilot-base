local function splitRemoveEmpty(str, sep)
    local segments = string.split(str, sep)
    for index, segment in ipairs(segments) do
        if segment == "" then
            table.remove(segments, index)
        end
    end
    return segments
end

return function(segments, __index)
	__index = __index or function(object, index)
		return object[index]
	end
    if typeof(segments) == "string" then
        segments = string.gsub(segments, "/", ".")
        segments = splitRemoveEmpty(segments, ".")
    end
    local function traverser(object)
        local current = object
        for _, segment in segments do
            if string.len(segment) == 0 then continue end
            current = __index(current, segment)
            if current == nil then return end
        end
        return current
    end
    return setmetatable({}, {
        __call = function(_, object)
            return traverser(object)
        end,
        __index = {
            segments = segments,
        }
    })
end