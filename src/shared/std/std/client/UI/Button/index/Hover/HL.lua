local std = shared.std
local GuiService = game:GetService("GuiService")

local UserInputService = game:GetService("UserInputService")
local guiInset = std.Util:GetGuiInset()

return function(button, growScale)
    local originalPosition = button.ButtonObject.Position
    button:AddHoverEffect("Grow", growScale)
    button:OnHoverEnter(function()
        -- determine offset position based off of button position and mouse cursor position
        local offset = UDim2.fromScale(0, -.005)
        if UserInputService.MouseEnabled then
            local mouseLocation = UserInputService:GetMouseLocation() - guiInset
            local difference = mouseLocation - (button.ButtonObject.AbsolutePosition + button.ButtonObject.AbsoluteSize/2)

            offset = std.Util.UDim2Multiply(UDim2.fromOffset(difference.X, difference.Y), 0.03) + UDim2.fromOffset(0, -1)
        end
        std.SimpleTween(button.ButtonObject, "Position", (button.ButtonObject:GetAttribute("OriginalPosition") or originalPosition) + offset, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end):OnHoverExit(function()
        std.SimpleTween(button.ButtonObject, "Position", (button.ButtonObject:GetAttribute("OriginalPosition") or originalPosition), 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    end)
end