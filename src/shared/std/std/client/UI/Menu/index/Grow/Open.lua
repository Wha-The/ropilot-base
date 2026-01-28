local std = shared.std

return function(Menu, arguments)
    local _ = table.unpack(arguments.Args)
    Menu.MenuObject.Visible = true
    Menu.originalSize = Menu.originalSize or Menu.MenuObject.Size
    std.SimpleTween(Menu.MenuObject, "Size",  Menu.originalSize, table.unpack(arguments.Tween)).Completed:Wait()
end