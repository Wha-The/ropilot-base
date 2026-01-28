local std = shared.std

local function tweenFieldOfView(fov, t, ...)
	local tween
	if game.Players.LocalPlayer:GetAttribute("DynamicFieldOfViewRequired") then
		local reserved_n = (shared.FOVTweenReserve or 0) + 1
		shared.FOVTweenReserve = reserved_n
		tween = std.client.NumberTween(function(n)
			if shared.FOVTweenReserve ~= reserved_n then return end
			game.Players.LocalPlayer:SetAttribute("FieldOfView", n)
		end, workspace.CurrentCamera.FieldOfView, fov, t, ...)
		tween.Completed:Connect(function()
			if shared.FOVTweenReserve == reserved_n then shared.FOVTweenReserve = 0 end
		end)
	else
		tween = std.SimpleTween(workspace.CurrentCamera, "FieldOfView", fov, t, ...)
	end
	return tween
end

return function(Menu, arguments)
    local addFOV = table.unpack(arguments.Args)
    if not workspace.CurrentCamera:GetAttribute("OriginalFOV") then
        workspace.CurrentCamera:SetAttribute("OriginalFOV", workspace.CurrentCamera.FieldOfView)
    end
	local t = arguments.Tween[1] and arguments.Tween[1]/0.7 or 0.5
	shared.ZoomedOutFOV = shared.ZoomedOutFOV or (workspace.CurrentCamera.FieldOfView + (addFOV or 5))
    tweenFieldOfView(shared.ZoomedOutFOV, t, table.unpack(table.move(arguments.Tween, 2, #arguments.Tween, 1, {}))).Completed:Wait()
end