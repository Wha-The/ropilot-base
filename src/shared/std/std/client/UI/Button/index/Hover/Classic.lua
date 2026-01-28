local std = shared.std
local Knit = std.Knit

return function(button)
    local buttonColor = button.ButtonObject.ImageColor3
    button:OnHoverEnter(function()
        std.SimpleTween(button.ButtonObject, "ImageColor3", std.Util.Color3Multiply(buttonColor, 0.8), 0.25)
    end):OnHoverExit(function()
        std.SimpleTween(button.ButtonObject, "ImageColor3", buttonColor, 0.25)
    end)
end