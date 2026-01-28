local StarterGui = game:GetService("StarterGui")
local global_n = 0
return function()
	if global_n == 0 then
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end
	global_n += 1
	return {
		Destroy = function()
			global_n -= 1
			if global_n == 0 then
				task.defer(function()
					StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
				end)
			end
		end
	}
end