local RunService = game:GetService("RunService")
debug.setmemorycategory("std.Clock")
local Clock = {}
Clock._connected = false
Clock._connections = {}
Clock.DISCONNECT = newproxy()

local IS_SERVER = RunService:IsServer()
local Step = IS_SERVER and RunService.Heartbeat or RunService.RenderStepped

function Clock.init()
    Clock._connected = true
    local lastStep = tick()

    Step:Connect(function(deltaTime) --@wfuscator run_unsandboxed=yes;
        local timeSinceLastStepFromTick = tick() - lastStep
        lastStep = tick()
        if deltaTime > (timeSinceLastStepFromTick * 2) then -- fluctuations
            if not RunService:IsStudio() then
                -- studio output is already flooded enough
                -- print(`Clock.every: deltaTime is too high ({math.round(deltaTime * 1000 * 10)/10}ms), using timeSinceLastStepFromTick ({math.round(timeSinceLastStepFromTick * 1000 * 10)/10}ms) instead`)
            end
            deltaTime = timeSinceLastStepFromTick
        end

        for connection, _ in Clock._connections do
            local stepped, interval, invoke_closure, tickSpeed = table.unpack(connection)

            if not interval then
                task.spawn(invoke_closure, deltaTime * tickSpeed)
            else
                stepped += deltaTime * tickSpeed
                connection[1] = stepped
                if stepped >= interval then
                    task.spawn(invoke_closure, stepped)
                    
                    stepped -= interval
                    connection[1] = stepped
                end
            end
            
        end
    end)
end





function Clock.every(interval, callback, call_instantly)
    if not callback then
        callback = interval
        interval = nil
    end

    local DISCONNECT = Clock.DISCONNECT
    local disconnect
    local data = table.pack(0, interval, function(stepped)
        local rt = callback(stepped)
        if rt == DISCONNECT then
            disconnect()
        end
    end, 1)
    Clock._connections[data] = true
    -- table.insert(Clock._connections, data)
    if not Clock._connected then
        Clock.init()
    end
    if call_instantly then
        task.defer(callback, 0)
    end

    disconnect = function()
        -- local index = table.find(Clock._connections, data)
        -- if index then
        --     table.remove(Clock._connections, index)
        -- end
        Clock._connections[data] = nil
        -- return index
    end
    return {
		Disconnect = disconnect,
		Destroy = disconnect,
		Skip = function()
			data[1] = data[2]
		end,
        SetTickSpeed = function(_, tickSpeed)
            assert(type(tickSpeed) == "number", "tickSpeed must be a number")
            data[4] = tickSpeed
        end,
        SetInterval = function(_, interval)
            assert(type(interval) == "number", "interval must be a number")
            data[2] = interval
        end,
        GetTickSpeed = function()
            return data[4]
        end
	}
end

Clock.schedule = Clock.every

return Clock