local std = shared.std

return function(Menu, arguments)
    local closed_size_mul = table.unpack(arguments.Args)
    closed_size_mul = closed_size_mul or UDim2.fromScale(0, 0)
    Menu.originalSize = Menu.originalSize or Menu.MenuObject.Size
    local state = std.SimpleTween(Menu.MenuObject, "Size", std.Util.UDim2Multiply(Menu.originalSize, closed_size_mul), table.unpack(arguments.Tween)).AlphaCompleted(.9):Wait()
    if state == Enum.PlaybackState.Completed then
        Menu.MenuObject.Visible = false
    end
end