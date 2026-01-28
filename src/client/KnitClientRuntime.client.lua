local Knit = require(game:GetService("ReplicatedStorage").Packages:WaitForChild("Knit"))

-- Expose required Modules on client
Knit.Shared = game.ReplicatedStorage.Shared
Knit.ClientModules = script.Parent.ClientModules

shared.Knit = Knit

local std = require(Knit.Shared.std)
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
std.MainGui = PlayerGui:WaitForChild("MainGui")
std.AssetStreamer = require(Knit.Shared.Base.AssetStreamer)

print("Server Version: " .. game.PlaceVersion)

if Knit.ClientModules:FindFirstChild("UI") and Knit.ClientModules:FindFirstChild("UI"):FindFirstChild("Popup") then
	std.client.UI.Popup = require(Knit.ClientModules.UI.Popup)

	-- Initialize Popups system
	task.defer(function()
		local PopupTemplates = std.MainGui:WaitForChild("PopupTemplates")
		local PopupsFrame = std.MainGui:WaitForChild("Popups")
		std.Popups = {
			Cash = std.client.UI.Popups(PopupTemplates.Cash, PopupsFrame, std.MainGui.LeftCorner.CashSection.Cash),
		}
	end)
end


-- Load all controllers within "Controllers"
Knit.AddControllersDeep(script.Parent.Controllers)
Knit.Start({ ServicePromises = false }):catch(warn)