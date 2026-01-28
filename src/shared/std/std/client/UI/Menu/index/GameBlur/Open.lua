local std = shared.std

return function(Menu, arguments)
    local blur = table.unpack(arguments.Args)
    if not game.Lighting:FindFirstChild("GameBlur") then
        local blur = Instance.new("BlurEffect")
        blur.Name = "GameBlur"
        blur.Parent = game.Lighting
    end
    local t = arguments.Tween[1] and arguments.Tween[1]/0.7 or 0.5
    std.SimpleTween(game.Lighting.GameBlur, "Size", blur, t, table.unpack(table.move(arguments.Tween, 2, #arguments.Tween, 1, {}))).Completed:Wait()
end