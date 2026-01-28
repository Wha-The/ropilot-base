local std = shared.std

return function(Menu, arguments)
    local childrenList = table.unpack(arguments.Args)
    local started, completed = 0, 0
    local completedb = std.Bindable()
    for _, child in childrenList do
        if not child.Visible then continue end
        if not child:GetAttribute("OriginalSize") then child:SetAttribute("OriginalSize", child.Size) end
        started += 1
        std.SimpleTween(child, "Size", UDim2.fromScale(0, 0), table.unpack(arguments.Tween)).Completed:Connect(function()
            completed += 1
            completedb:Fire()
        end)
        if arguments.Tween[1] ~= 0 then task.wait(arguments.Tween[1] / 10) end
    end
    if arguments.Tween[1] ~= 0 then
        while completed < started do completedb:Wait() end
    end
    Menu.MenuObject.Visible = false
end