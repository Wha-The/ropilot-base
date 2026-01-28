local std = shared.std

local function tweenFieldOfView(fov, t, ...)
	local tween
	if game.Players.LocalPlayer:GetAttribute("DynamicFieldOfViewRequired") then
		local reserved_n = (shared.FOVTweenReserve or 0) + 1
		shared.FOVTweenReserve = reserved_n
		tween = std.client.NumberTween(function(n)
			-- if shared.FOVTweenReserve ~= reserved_n then return print("isn't equal! got overwritten - LOOK INTO THIS") end
			game.Players.LocalPlayer:SetAttribute("FieldOfView", n)
		end, workspace.CurrentCamera.FieldOfView, fov, t, ...)
		tween.Completed:Connect(function()
			if shared.FOVTweenReserve == reserved_n then
				shared.FOVTweenReserve = 0
				shared.ZoomedOutFOV = nil
				game.Players.LocalPlayer:SetAttribute("FieldOfView")
			end
		end)
	else
		tween = std.SimpleTween(workspace.CurrentCamera, "FieldOfView", fov, t, ...)
	end
	return tween
end

return function(Menu, arguments)
    local originalFOV = workspace.CurrentCamera:GetAttribute("OriginalFOV") or 70

    tweenFieldOfView(originalFOV, table.unpack(arguments.Tween)).Completed:Wait()
end