return function(timeleft) --@wfuscator run_unsandboxed=yes
    if timeleft <= 0 then
        return ""
    end

	local DAY_TO_SECONDS = 60 * 60 * 24
	local HOUR_TO_SECONDS = 60 * 60
	local MINUTE_TO_SECONDS = 60

	local DAY_TO_HOURS = 24
	local HOUR_TO_MINUTES = 60

	local DAY_TO_MINUTE = 60 * 24

    local apartdaysleft = math.floor(timeleft/DAY_TO_SECONDS)
    local aparthoursleft = math.floor(timeleft/HOUR_TO_SECONDS) - apartdaysleft * DAY_TO_HOURS
    local apartminsleft = math.floor(timeleft/60)       - apartdaysleft * DAY_TO_MINUTE - aparthoursleft * HOUR_TO_MINUTES
    local apartsecsleft = math.floor(timeleft)          - apartdaysleft * DAY_TO_SECONDS - aparthoursleft * HOUR_TO_SECONDS - apartminsleft * MINUTE_TO_SECONDS
    
	local components = {}
    if apartdaysleft > 0 then
        table.insert(components, apartdaysleft.."d")
    end
    if aparthoursleft > 0 or #components >= 1 then
        table.insert(components, aparthoursleft.."h")
    end
    if apartminsleft > 0 or #components >= 1 then
        table.insert(components, apartminsleft.."m")
    end
    if apartsecsleft > 0 or #components >= 1 then
        table.insert(components, apartsecsleft.."s")
    end
    return table.concat(components, " ")
end