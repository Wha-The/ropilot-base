local std = shared.std

return function(Menu, arguments)
    assert(Menu.MenuObject:IsA("CanvasGroup"), "Menu must be a CanvasGroup to use this fade component!")
    std.SimpleTween(Menu.MenuObject, "GroupTransparency", 0, table.unpack(arguments)).Completed:Wait()
end