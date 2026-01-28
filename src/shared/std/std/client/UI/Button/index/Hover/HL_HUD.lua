local std = shared.std
local GuiService = game:GetService("GuiService")

local UserInputService = game:GetService("UserInputService")

local guiInset = std.Util:GetGuiInset()
return function(button, growScale)
    local originalPosition = button.ButtonObject.Position

    local Icon = button.ButtonObject:FindFirstChild("Icon")
    assert(Icon, "HL_HUD: Icon not found in button")
    local originalRotation = Icon.Rotation

    button:AddHoverEffect("Grow", growScale)
    button:OnHoverEnter(function()
        -- determine offset position based off of button position and mouse cursor position
        local offset = UDim2.fromScale(0, -.005)
        if UserInputService.MouseEnabled then
            local mouseLocation = UserInputService:GetMouseLocation() - guiInset
            local difference = mouseLocation - (button.ButtonObject.AbsolutePosition + button.ButtonObject.AbsoluteSize/2)

            offset = std.Util.UDim2Multiply(UDim2.fromOffset(difference.X, difference.Y), 0.03) + UDim2.fromOffset(0, -1)
        end
        std.SimpleTween(button.ButtonObject, "Position", originalPosition + offset, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        std.SimpleTween(Icon, "Rotation", originalRotation + 7, .1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    end):OnHoverExit(function()
        std.SimpleTween(button.ButtonObject, "Position", originalPosition, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        std.SimpleTween(Icon, "Rotation", originalRotation, .1, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
    end)
end