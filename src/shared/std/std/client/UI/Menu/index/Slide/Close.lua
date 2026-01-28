local std = shared.std

return function(Menu, arguments)
    local offset = table.unpack(arguments.Args)
    Menu.originalPosition = Menu.originalPosition or Menu.MenuObject.Position
    local t = arguments.Tween[1] or 0.5
    local state = std.SimpleTween(Menu.MenuObject, "Position", Menu.originalPosition + std.Util.UDim2Multiply(offset or UDim2.new(0, 0, 0.1, 0), 2), t/2, table.unpack(table.move(arguments.Tween, 2, #arguments.Tween, 1, {}))).Completed:Wait()
    if state == Enum.PlaybackState.Completed then
        Menu.MenuObject.Position = Menu.originalPosition + (offset or UDim2.new(0, 0, 0.1, 0))
    end
end