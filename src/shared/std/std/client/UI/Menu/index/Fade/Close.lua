local std = shared.std

return function(Menu, arguments)
    assert(Menu.MenuObject:IsA("CanvasGroup"), "Menu must be a CanvasGroup to use this fade component!")
	local state = std.SimpleTween(Menu.MenuObject, "GroupTransparency", 1, table.unpack(arguments)).Completed:Wait()
	if state == Enum.PlaybackState.Completed then
		Menu.Visible = false
	end
end