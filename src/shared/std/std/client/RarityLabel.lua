local std = shared.std

local RarityColors = {
	Common = Color3.fromRGB(50, 255, 50),
	Uncommon = Color3.fromRGB(0, 200, 0),
	Rare = Color3.fromRGB(0, 100, 255),
	Epic = Color3.fromRGB(255, 20, 147),
	Legendary = Color3.fromRGB(255, 220, 0),
	Mythic = Color3.fromRGB(255, 0, 0),
	Divine = Color3.fromRGB(255, 255, 255),
	Secret = Color3.fromRGB(255, 255, 255),
}

-- we can easily add more in the future
local GradientConfigs = {
	Divine = {
		colors = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 100)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 200)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 200, 100)),
		}),
		speed = 0.3,
	},
	Secret = {
		colors = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 50)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 200, 200)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 50, 50)),
		}),
		speed = 0.5,
	},
}

local function Configure(rarityLabel, rarity, maid)
	if not rarityLabel then
		return
	end

	rarity = rarity or "Common"
	rarityLabel.Text = rarity
	rarityLabel.TextColor3 = RarityColors[rarity] or RarityColors.Common

	local gradient = rarityLabel:FindFirstChild("RarityGradient")
	local config = GradientConfigs[rarity]

	if not config then
		if gradient then
			gradient.Enabled = false
		end
		return
	end

	if not gradient then
		gradient = Instance.new("UIGradient")
		gradient.Name = "RarityGradient"
		gradient.Parent = rarityLabel
	end

	gradient.Color = config.colors
	gradient.Rotation = 90
	gradient.Enabled = true

	if maid then
		local offset = 0
		maid:GiveTask(std.Clock.every(1 / 30, function(dt)
			offset = (offset + config.speed * dt) % 1
			gradient.Offset = Vector2.new(0, offset)
		end))
	end
end

return {
	Colors = RarityColors,
	Gradients = GradientConfigs,
	Configure = Configure,
}
