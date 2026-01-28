local std = shared.std

return function(Menu, arguments)
    local _ = table.unpack(arguments.Args)
    Menu.originalPosition = Menu.originalPosition or Menu.MenuObject.Position
    std.SimpleTween(Menu.MenuObject, "Position", Menu.originalPosition, table.unpack(arguments.Tween)).Completed:Wait()
end