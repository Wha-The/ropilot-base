local std = shared.std

return function(button)
    if not button.ButtonObject:FindFirstChild("Icon") then return warn("[ButtonHoverEffect: ExpandIcon]: Unable to find button's Icon ImageLabel:", button.ButtonObject) end

    local Icon = button.ButtonObject.Icon
    local originalSize = Icon.Size
    local originalPosition = Icon.Position
    button:OnHoverEnter(function()
        std.SimpleTween(Icon, "Position", UDim2.fromScale(.5, .5), 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        std.SimpleTween(Icon, "Size", UDim2.fromScale(.8, .8), 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end):OnHoverExit(function()
        std.SimpleTween(Icon, "Position", originalPosition, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        std.SimpleTween(Icon, "Size", originalSize, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    end)
end