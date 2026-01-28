local std = shared.std

local Approaching = function(part, threshold, callbackEnter, callbackLeave)
	callbackLeave = callbackLeave or function() end
	local maid = std.Maid()
	local within = std.State(false)
	maid:GiveTask(within:Observe(function(state)
		(state and callbackEnter or callbackLeave)()
	end))
    maid:GiveTask(std.Clock.every(1/5, function()
        local Position = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character.PrimaryPart and game.Players.LocalPlayer.Character.PrimaryPart.Position
        if not Position then return end
        local Distance = ((Position - part.Position) * Vector3.new(1, 0, 1)).Magnitude
        within:Update(Distance < threshold)
    end))
	return maid
end

return Approaching