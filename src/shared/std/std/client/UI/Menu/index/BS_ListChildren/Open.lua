local std = shared.std
return function(Menu, arguments)
    Menu.MenuObject.Visible = true
    local childrenList = table.unpack(arguments.Args)
    for _, child in childrenList do
        if not child.Visible then continue end
        if not child:GetAttribute("OriginalSize") then child:SetAttribute("OriginalSize", child.Size) end
        child.Size = UDim2.fromScale(0, 0)
        std.SimpleTween(child, "Size", child:GetAttribute("OriginalSize"), table.unpack(arguments.Tween))
        task.wait(arguments.Tween[1] / 10)
    end
    --Knit.SimpleTween(Menu.MenuObject, "Size",  Menu.originalSize, table.unpack(arguments.Tween)).Completed:Wait()
end