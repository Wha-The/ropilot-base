local std = shared.std

return function(button, scale)
    local originalSize = button.ButtonObject:GetAttribute("OriginalSize") or button.ButtonObject.Size
    button.ButtonObject:SetAttribute("OriginalSize", originalSize)

    local function animate(direction, sizeBefore)
        std.SimpleTween(
            button.ButtonObject,
            "Size",
            (direction == 1) and std.Util.UDim2Multiply(sizeBefore, scale or 0.6) or (button.Hovered and sizeBefore or button.ButtonObject:GetAttribute("OriginalSize") or originalSize),
            0.05,
            Enum.EasingStyle.Circular,
            Enum.EasingDirection[direction == 1 and "In" or "Out"]
        ).Completed:Wait()
        task.wait((direction == 1) and 0.05 or 0)
    end

    
    local sizeBefore
    button:OnMouse(function(state)
        if state == "Down" then
            sizeBefore = button.ButtonObject:GetAttribute("OriginalSize") or originalSize
            if table.find(button.AppliedEffects.Hover, "Grow") and not button.IsOnUnreliableGui then
                sizeBefore = button.ButtonObject.Size
            end

            animate(1, sizeBefore)
        else
            animate(2, sizeBefore)
        end
    end)
end