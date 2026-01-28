local std = shared.std

return function(button, scale)
    local originalSize = button.ButtonObject:GetAttribute("OriginalSize") or button.ButtonObject.Size
    button.ButtonObject:SetAttribute("OriginalSize", originalSize)
    button:OnHoverEnter(function()
        button.Hovered = true
        std.SimpleTween(button.ButtonObject, "Size", std.Util.UDim2Multiply(button.ButtonObject:GetAttribute("OriginalSize"), scale or 1.15), 0.05, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
    end):OnHoverExit(function()
        button.Hovered = false
        std.SimpleTween(button.ButtonObject, "Size", button.ButtonObject:GetAttribute("OriginalSize"), 0.05, Enum.EasingStyle.Circular, Enum.EasingDirection.In)
    end)
end