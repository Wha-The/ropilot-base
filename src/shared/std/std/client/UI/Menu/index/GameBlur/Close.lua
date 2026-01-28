local std = shared.std

return function(Menu, arguments)
    if not game.Lighting:FindFirstChild("GameBlur") then
        local blur = Instance.new("BlurEffect")
        blur.Name = "GameBlur"
        blur.Parent = game.Lighting
    end
    local t = arguments.Tween[1] or 0.5
    std.SimpleTween(game.Lighting.GameBlur, "Size", 0, t, table.unpack(table.move(arguments.Tween, 2, #arguments.Tween, 1, {}))).Completed:Wait()
end