local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages:WaitForChild("Knit"))

-- Expose required Modules on server
Knit.Shared = ReplicatedStorage.Shared
Knit.ServerModules = script.Parent.ServerModules

shared.Knit = Knit

local std = require(Knit.Shared.std)
std.AssetStreamer = require(Knit.Shared.Base.AssetStreamer)

-- initialize some modules
local _ = std.SimpleTween
local _ = require(Knit.Shared.Base.SoundBase)

-- Load all services within "Services"
Knit.AddServicesDeep(script.Parent.Services)

local rateLimits = {}

local safetyCheck
safetyCheck = function(object)
    if typeof(object) == "number" then
        if object ~= object then local msg = "[whut's Firewall] Illegal number value! (NaN). Request Blocked."; warn(msg); return false, msg end
        
        local str_repr = tostring(object)
        if string.find(str_repr, "inf") then local msg = "[whut's Firewall] Illegal number value! (inf). Request Blocked."; warn(msg); return false, msg end
    elseif typeof(object) == "table" then
        for _, value in object do
            local success, err = safetyCheck(value)
            if not success then return success, err end
        end
    end
    return true -- ok
end

Knit.Start({
    Middleware = {
        Inbound = {
            function(func, player, args)
                if typeof(func) ~= "function" then return true end -- we havent patched this callback
                -- rate limit requests: when calling the same function, the client is only allowed to call it again AFTER it has finished
                -- processing on the server to prevent race conditions
                if not rateLimits[func] then rateLimits[func] = std.Timegate() end
                local timegate = rateLimits[func]
                
                if not timegate:lock(player) then
                    print("Last callback is still processing, please wait!")
                    return false, "An error occured, please try again!"
                end
                if not args then timegate:unlock(player); return warn("No arguments passed to function call!", func, debug.traceback()) end

                -- safety check
                local success, err = safetyCheck(args)
                if not success then timegate:unlock(player); return false, err end

                local result = table.pack(xpcall(function()
                    return func(player, table.unpack(args))
                end, debug.traceback))
                timegate:unlock(player)
                if not result[1] then
                    print("Error occured in function call: ")
                    warn(result[2])
                    return false, "An error occured, please try again!"
                end
                
                return false, table.unpack(table.move(result, 2, result.n, 1, {}))
            end
        },
    },
}):catch(warn)