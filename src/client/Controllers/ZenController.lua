--[[
	ZenController: A simplified UI controller responsible for basic UI interactions using the Zen framework.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local PolicyService = game:GetService("PolicyService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local std = shared.std
local Knit = std.Knit

local ZenController = Knit.CreateController({
	Name = "ZenController",
})

-- Controller dependencies (to be loaded on KnitStart)
local DataController
local SoundController

local Fade = function(frame, isRestoring)
	local desc = frame:GetDescendants()
	table.insert(desc, frame)
	local changes = {}
	for _, child in desc do
		local properties = {}
		if child:IsA("TextLabel") then
			table.insert(properties, "TextTransparency")
			table.insert(properties, "TextStrokeTransparency")
			table.insert(properties, "BackgroundTransparency")
		elseif child:IsA("ImageLabel") then
			table.insert(properties, "ImageTransparency")
			table.insert(properties, "BackgroundTransparency")
		elseif child:IsA("Frame") then
			table.insert(properties, "BackgroundTransparency")
		elseif child:IsA("CanvasGroup") then
			table.insert(properties, "BackgroundTransparency")
		elseif child:IsA("TextButton") then
			table.insert(properties, "TextTransparency")
			table.insert(properties, "BackgroundTransparency")
		elseif child:IsA("ImageButton") then
			table.insert(properties, "ImageTransparency")
			table.insert(properties, "BackgroundTransparency")
		elseif child:IsA("UIStroke") then
			table.insert(properties, "Transparency")
		elseif child:IsA("ViewportFrame") then
			table.insert(properties, "BackgroundTransparency")
			table.insert(properties, "ImageTransparency")
		end
		if #properties > 0 then
			changes[child] = properties
		end
	end

	return function(t)
		t = 1 - t
		for child, properties in changes do
			for _, property in properties do
				if not child:GetAttribute("Original" .. property) then
					child:SetAttribute("Original" .. property, child[property])
				end
				if isRestoring then
					if child[property] == child:GetAttribute("Original" .. property) then
						continue
					end
				end
				child[property] = 1 - (t * (1 - child:GetAttribute("Original" .. property)))
			end
		end
	end
end
function ZenController:FadeOne(frame, fade, duration)
	-- fade = true: hide frame
	-- fade = false: RESTORE frame
	if fade then
		return std.client.NumberTween(
			Fade(frame),
			0,
			1,
			duration or 0.35,
			Enum.EasingStyle.Quart,
			Enum.EasingDirection.Out,
			frame
		)
	else
		return std.client.NumberTween(
			Fade(frame, true),
			1,
			0,
			duration or 0.35,
			Enum.EasingStyle.Quart,
			Enum.EasingDirection.Out,
			frame
		)
	end
end

function ZenController:InitMenu(menu, maid)
	-- Generate unique request ID for this menu instance
	local menuName = menu.MenuObject.Name or "UnknownMenu"
	local requestId = "Menu:" .. menuName .. ":" .. tostring(tick())
	
	local UIScale = menu.MenuObject:FindFirstChildWhichIsA("UIScale")
	if UIScale then
		maid:GiveTask(std.client.MobileDetect:Observe(function(isMobile)
			local isIpad = isMobile and not std.client.MobileDetect:DetectNoIpad()

			local scale = 1
			if isIpad then
				scale = menu.MenuObject:GetAttribute("IpadMenuSizeScale") or 1.3
			elseif isMobile then
				scale = menu.MenuObject:GetAttribute("MobileMenuSizeScale") or 1.3
			end

			std.SimpleTween(UIScale, "Scale", scale, 0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
			-- -- also move down a little bit because there isnt a close button anymore at the bottom

			if not isIpad then
				if not menu.MenuObject:GetAttribute("OriginalPosition") then
					menu.MenuObject:SetAttribute("OriginalPosition", menu.originalPosition)
				end
				local newPos = menu.MenuObject:GetAttribute("OriginalPosition")
					+ UDim2.fromScale(0, (isMobile and 0.05) or 0)
				menu.originalPosition = newPos
				std.SimpleTween(
					menu.MenuObject,
					"Position",
					newPos,
					0.35,
					Enum.EasingStyle.Quart,
					Enum.EasingDirection.Out
				)
			end
		end))
	end
end

function ZenController:ReduceMobileStroke(menu, maid)
	if typeof(menu) == "classinstance" then
		menu = menu.MenuObject
	end
	-- maid:GiveTask(std.client.MobileDetect:Observe(function(isMobile)
	-- 	for _, stroke in menu:GetDescendants() do
	-- 		if stroke:IsA("UIStroke") then
	-- 			if not stroke:GetAttribute("OriginalThickness") then
	-- 				stroke:SetAttribute("OriginalThickness", stroke.Thickness)
	-- 			end
	-- 			stroke.Thickness = isMobile and stroke:GetAttribute("OriginalThickness")/2 or stroke:GetAttribute("OriginalThickness")
	-- 		end
	-- 	end
	-- end))

	-- maid:GiveTask(menu.DescendantAdded:Connect(function(descendant)
	-- 	if descendant:IsA("UIStroke") then
	-- 		if not descendant:GetAttribute("OriginalThickness") then
	-- 			descendant:SetAttribute("OriginalThickness", descendant.Thickness)
	-- 		end
	-- 		descendant.Thickness = std.client.MobileDetect:Detect() and descendant:GetAttribute("OriginalThickness") / 2
	-- 			or descendant:GetAttribute("OriginalThickness")
	-- 	end
	-- end))
end

function ZenController:KnitStart()
	-- Get controller dependencies
	DataController = Knit.GetController("DataController")
	SoundController = Knit.GetController("SoundController")

	-- for robux items
	local loadprice = function(textLabel, productId, productType, returnInfo)
		textLabel.Text = "..."
		local co = function()
			local success, info = pcall(function()
				return MarketplaceService:GetProductInfo(productId, productType)
			end)
			while not success do
				task.wait(1)
				success, info = pcall(function()
					return MarketplaceService:GetProductInfo(productId, productType)
				end)
			end
			textLabel.Text = info.PriceInRobux and std.FormatNumber(info.PriceInRobux, true) .. utf8.char(0xE002) or "?"
			if productType == Enum.InfoType.GamePass then
				task.defer(function()
					local success, owned
					while not success do
						success, owned = pcall(function()
							return MarketplaceService:UserOwnsGamePassAsync(game.Players.LocalPlayer.UserId, productId)
						end)
						if not success then
							print("Failed to check gamepass ownership: ", owned)
						end
						task.wait(1)
					end

					if owned then
						textLabel.Text = "Owned!"
					end
				end)
			end

			return info
		end
		if not returnInfo then
			task.defer(co)
		else
			return co()
		end
	end
	self.LoadPrice = loadprice

	-- Get the main GUI frame
	local mainFrame = std.MainGui

	-- Initialize the Zen UI framework
	local Zen = std.client.UI.Zen
	Zen.SetCloseButtonName("Close")
	local main = Zen.Zen(mainFrame)
	local Actions = Zen.Actions(main)

	local Button = Zen.Button
	local CurrencyLabel = Zen.CurrencyLabel
	local Event = Zen.Event


	self.Main = main

	-- HUD Configuration Tree (simplified without tools since we handle it manually)
	local tree = {
		-- [Button(".Tools"):SetCreatedCallback(useHUDHoverEffect)] = Actions.Menu("ToolsShop"), -- Removed, handled manually above
		-- [Button(".Index"):SetCreatedCallback(useHUDHoverEffect)] = Actions.Menu("Index"),
		-- [Button(".Settings"):SetCreatedCallback(useHUDHoverEffect)] = Actions.Menu("Settings"),
		-- [Button(".Shop"):SetCreatedCallback(useHUDHoverEffect)] = Actions.Menu("Shop"),
	}

	-- Configure the HUD with the tree
	-- main:ConfigureHUD(".HUD.Left.Buttons", tree)

	-- Store the main Zen instance for future use
	self.Main = main

	-- Mount the UI - this sets up the basic framework
	main:Mount()
end

return ZenController
