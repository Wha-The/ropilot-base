local std = shared.std

local ActionVignette = Instance.new("ImageLabel")
ActionVignette.Size = UDim2.fromScale(1, 1)
ActionVignette.Visible = false
ActionVignette.Active = false
ActionVignette.Image = "rbxassetid://127366667073715"
ActionVignette.ImageTransparency = 1
ActionVignette.BackgroundTransparency = 1
ActionVignette.Parent = game.Players.LocalPlayer.PlayerGui:FindFirstChild("FullGui") or std.MainGui

local currentTween = nil
local callId = 0

return function()
	callId += 1
	local thisCallId = callId
	
	if currentTween then
		currentTween:Cancel()
	end
	
	ActionVignette.Visible = true
	ActionVignette.ImageTransparency = 1
	
	currentTween = std.SimpleTween(ActionVignette, "ImageTransparency", 0.5, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	currentTween.Completed:Connect(function()
		if thisCallId ~= callId then return end
		
		currentTween = std.SimpleTween(ActionVignette, "ImageTransparency", 1, 0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		currentTween.Completed:Connect(function()
			if thisCallId ~= callId then return end
			ActionVignette.Visible = false
		end)
	end)
end