local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

if (game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0) then
	if (game:GetService("RunService"):IsStudio()) then
		return
	end
	-- this is a reserved server without a VIP server owner
	task.wait(.5)

	Players.PlayerAdded:Connect(function(player)
		TeleportService:Teleport(game.PlaceId, player)
	end)

	for _, player in Players:GetPlayers() do
		TeleportService:Teleport(game.PlaceId, player)
	end
else
	game:BindToClose(function()
		task.wait(.1)
		if (#Players:GetPlayers() == 0) then
			return
		end

		if (game:GetService("RunService"):IsStudio()) then
			return
		end
		local reservedServerCode = TeleportService:ReserveServer(game.PlaceId)

		local ServerType = Instance.new("StringValue")
		ServerType.Name = "ServerType"
		ServerType.Value = "Shutdown"
		ServerType.Parent = game.ReplicatedStorage
		

		for _, player in Players:GetPlayers() do
			TeleportService:TeleportToPrivateServer(game.PlaceId, reservedServerCode, { player })
		end
		Players.PlayerAdded:Connect(function(player)
			TeleportService:TeleportToPrivateServer(game.PlaceId, reservedServerCode, { player })
		end)
		while (#Players:GetPlayers() > 0) do
			task.wait(1)
		end
	end)
end --@wfuscator minified=no