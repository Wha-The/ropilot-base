local std = shared.std
local Knit = shared.Knit

local ConfigService = game:GetService("ConfigService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerService = Knit.CreateService({
	Name = "PlayerService",
	Client = {

	},
})
local DataService
local LeaderboardService
local GeneralService

function PlayerService:AddStat(player, stat, amount)
	if not player.Parent then
		return
	end
	DataService:IncrementKey(player, "/Default/" .. stat, amount)
	if amount > 0 then
		DataService:IncrementKey(player, "/AllTime/" .. stat, amount)
	end
end


function PlayerService:KnitStart()
	DataService = Knit.GetService("DataService")
	LeaderboardService = Knit.GetService("LeaderboardService")
	GeneralService = Knit.GetService("GeneralService")

	std.Clock.every(60, function(dt)
		for _, player in game.Players:GetPlayers() do
			PlayerService:AddStat(player, "Playtime", 1)

			task.defer(function()
				LeaderboardService.PushToLBRequest:Fire(player)
			end)
		end
	end)

	local playerAdded = function(player)
		if game.CreatorType == Enum.CreatorType.Group then
			local GROUP_ID = game.CreatorId
			task.spawn(function()
				local success, isInGroup = pcall(function()
					return player:IsInGroup(GROUP_ID)
				end)
				if success then
					player:SetAttribute("IsInGroup", isInGroup)
				else
					player:SetAttribute("IsInGroup", false)
				end
			end)
		end

		local leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player

		local Cash = Instance.new("IntValue")
		Cash.Name = "Cash"
		Cash.Parent = leaderstats


		-- Update leaderstats when steps change
		DataService:Observe(player, "/Default/Cash", function(cashAmount)
			-- Cash changed!
		end)

		-- Set character collision groups
		local function setupCharacterCollision(character)
			-- Assign all character parts to Players collision group
			for _, part in character:GetDescendants() do
				if part:IsA("BasePart") then
					part.CollisionGroup = "Players"
				end
			end

			-- Also handle parts added after character spawn
			character.DescendantAdded:Connect(function(descendant)
				if descendant:IsA("BasePart") then
					descendant.CollisionGroup = "Players"
				end
			end)
		end

		-- Setup for current character if it exists
		if player.Character then
			setupCharacterCollision(player.Character)
		end

		-- Setup for future characters
		player.CharacterAdded:Connect(setupCharacterCollision)
	end
	game.Players.PlayerAdded:Connect(playerAdded)
	for _, player in game.Players:GetPlayers() do
		playerAdded(player)
	end
end

return PlayerService
