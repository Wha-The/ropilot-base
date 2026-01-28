local std = shared.std

return function(object, ...)
    if not object.PrimaryPart then return warn(`Object {object} has no primary part`) end
    local data = {}
    local args = {...}
    if typeof(args[#args]) == "table" then
        data = args[#args]
        table.remove(args, #args)
    end


    local accumulated = 0
    local updatedisconnect = std.Clock.every(function(frameTime) --@wfuscator run_unsandboxed=yes
        accumulated += frameTime
    end)
    -- local sendUpdate = function(cf) --@wfuscator run_unsandboxed=yes
    --     local fInterval = 0--((4 - (4 --[[self.Handlers.GetDevicePerformance()]])) * (0.75 * (data.SlowFactor or 1)/60))
    --     if accumulated > fInterval then
    --         if object.PrimaryPart then
    --             object:SetPrimaryPartCFrame(cf)
    --         end
    --         accumulated -= fInterval
    --     end
    -- end

    local cfRepersentation = Instance.new("CFrameValue")
    cfRepersentation.Value = object:GetPrimaryPartCFrame()
    cfRepersentation:GetPropertyChangedSignal("Value"):Connect(function()
        -- sendUpdate(cfRepersentation.Value)
        if not object.PrimaryPart then return end
        object:SetPrimaryPartCFrame(cfRepersentation.Value)
    end)
    
    local tween = std.SimpleTween(cfRepersentation, "Value", table.unpack(args))
    tween.Completed:Connect(function()
        cfRepersentation:Destroy()
        updatedisconnect:Disconnect()
    end)
    return tween
end