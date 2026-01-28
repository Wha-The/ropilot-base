	--[[
API for Billboard Handling.
Script by NWhut.
Revisited: Sep 10th, 2023
]]

local std = shared.std
local Knit = std.Knit

local BillboardController = Knit.CreateController{
    Name = "BillboardController"
}
local SimpleTween = std.SimpleTween
BillboardController.Billboards = {}

local Time = 0.15

local function BillboardFadeIn(billboard, info)
	for tween, _ in info.TemporaryTweens do
		tween:Cancel()
	end
	table.clear(info.TemporaryTweens)
	if info.TransparencyChanges then
		for element, changes in info.TransparencyChanges do
			for property, value in changes do
				info.TemporaryTweens[SimpleTween(element, property, value, Time)] = true
			end
		end
		info.TransparencyChanges = nil
	end
	info.TemporaryTweens[SimpleTween(billboard, "StudsOffsetWorldSpace", info.OriginalStudsOffset, Time)] = true
	task.wait(Time)
end

local function BillboardFadeOut(billboard, info, instant)
	for tween, _ in info.TemporaryTweens do
		tween:Cancel()
	end
	table.clear(info.TemporaryTweens)
	
	local BillboardTransparencyChanges = {}

	for element, clone in info.InspectList do
		if (element:IsA("GuiObject") or element:IsA("UIBase")) and (not element:FindFirstAncestorWhichIsA("LocalScript") or (element:FindFirstAncestorWhichIsA("BillboardGui") and element:FindFirstAncestorWhichIsA("BillboardGui"):GetAttribute("IgnoreScript"))) then
			local Changes = {}
			if element:IsA("GuiObject") then
				Changes.BackgroundTransparency = clone.BackgroundTransparency
			end

			if element:IsA("ImageLabel") or element:IsA("ImageButton") or element:IsA("ViewportFrame") then
				Changes.ImageTransparency = clone.ImageTransparency
			end

			if element:IsA("TextLabel") or element:IsA("TextButton") then
				Changes.TextTransparency = clone.TextTransparency
				Changes.TextStrokeTransparency = clone.TextStrokeTransparency
			end
			if element:IsA("UIStroke") then
				Changes.Transparency = clone.Transparency
			end
			if element:IsA("UIListLayout") then
				Changes.Padding = clone.Padding
				info.TemporaryTweens[SimpleTween(element, "Padding", UDim.new(0,0), instant and 0 or Time)] = true
			end
			if element:IsA("UIGridLayout") then
				Changes.CellPadding = clone.CellPadding
				info.TemporaryTweens[SimpleTween(element, "CellPadding", UDim2.new(0,0,0,0), instant and 0 or Time)] = true

				Changes.CellSize = clone.CellSize
				info.TemporaryTweens[SimpleTween(element, "CellSize", UDim2.new(0,0,0,0), instant and 0 or Time)] = true
			end

			for property, _ in Changes do
				if property == "Transparency" or string.find(property, "Transparency") then
					info.TemporaryTweens[SimpleTween(element, property, 1, instant and 0 or Time)] = true
				end
			end

			if not BillboardTransparencyChanges[element] then
				BillboardTransparencyChanges[element] = Changes
			end
		end
	end

	info.TemporaryTweens[SimpleTween(billboard, "StudsOffsetWorldSpace", info.OriginalStudsOffset - info.TweenOffset, Time)] = true
	info.TransparencyChanges = BillboardTransparencyChanges
	if not instant then task.wait(Time) end
end

BillboardController.BillboardFadeIn = BillboardFadeIn
BillboardController.BillboardFadeOut = BillboardFadeOut

function BillboardController.CreateProfile(billboard)
	local maxDistance = billboard.MaxDistance
	billboard.MaxDistance = (maxDistance * 1.5) + 25
	local adornee = billboard.Adornee or billboard.Parent

	local InspectList = {}
	for _, instance in billboard:GetDescendants() do
		InspectList[instance] = instance:Clone()
	end
	return {
		MaxDistance = maxDistance,
		Enabled = true,
		Visible = false,
		Position = function()
			local adorneePosition = (adornee:IsA("BasePart") and adornee.Position) or (adornee:IsA("Model") and adornee.PrimaryPart and adornee.PrimaryPart.Position) or (adornee:IsA("Model") and select(1, adornee:GetBoundingBox()).Position)
			if not adorneePosition then
				return Vector3.zero
			end
			local position = adorneePosition + billboard.StudsOffsetWorldSpace
			return position
		end,
		TransparencyChanges = {},
		TweenOffset = Vector3.new(0, 1.5, 0),
		InspectList = InspectList,
		OriginalStudsOffset = billboard.StudsOffsetWorldSpace,
		TemporaryTweens = setmetatable({}, {
			__mode = "kv",
		}),
	}
end

function BillboardController.Setup(billboard)
	assert(typeof(billboard) == "Instance" and billboard:IsA("BillboardGui"), `BillboardController.Setup: billboard must be a BillboardGui (is {typeof(billboard)})`)
	BillboardController.Billboards[billboard] = BillboardController.CreateProfile(billboard)
	billboard:SetAttribute("Visible", false)
	billboard.AncestryChanged:Connect(function(_, parent)
		if not parent then
			BillboardController.Destroy(billboard)
		end
	end)
	
	coroutine.wrap(BillboardFadeOut)(billboard, BillboardController.Billboards[billboard])
	
	return billboard
end

function BillboardController.Destroy(billboard)
	local info = BillboardController.Billboards[billboard]
	if not info then return end
	-- clear info inspect list
	for element, clone in info.InspectList do
		element:Destroy()
	end
	BillboardController.Billboards[billboard] = nil
end

function BillboardController.Config(billboard, property, value)
	if not BillboardController.Billboards[billboard] then return false end
	BillboardController.Billboards[billboard][property] = value
	return true
end

std.Clock.every(1/3, function() --@wfuscator run_unsandboxed=yes
    local PrimaryPart = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character.PrimaryPart
    if not PrimaryPart then return end
    local CharacterPosition = PrimaryPart.Position
    
    for billboard, info in BillboardController.Billboards do
        local closeEnough = (CharacterPosition - info.Position()).Magnitude < info.MaxDistance
        if closeEnough and info.Enabled then
            if not info.Visible then
                info.Visible = true
                billboard:SetAttribute("Visible", true)
                coroutine.wrap(BillboardController.BillboardFadeIn)(billboard, info)
            end
        else
            if info.Visible then
                info.Visible = false
                billboard:SetAttribute("Visible", false)
                coroutine.wrap(BillboardController.BillboardFadeOut)(billboard, info)
            end
        end
    end
end)


return BillboardController --@wfuscator enabled=no