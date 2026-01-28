local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local std = shared.std
local Knit = std.Knit

local RobuxService = Knit.CreateService({
	Name = "RobuxService",
	Client = {
		ShowMessage = Knit.CreateSignal(),
		OnItemPurchased = Knit.CreateSignal(),
		LimitedStockUpdated = Knit.CreateSignal(),
		RegisterPendingAdminShopPurchase = function(self, player, componentName, mutationName)
			return self.Server:RegisterPendingAdminShopPurchase(player, componentName, mutationName)
		end,
		GetLimitedStock = function(self, player, productKey)
			return self.Server:GetLimitedStock(productKey)
		end,
	},
})
local RobuxModule = require(Knit.Shared.Config.Robux)
-- Game-specific configs (removed - uncomment if needed)
-- local GearShop = require(Knit.Shared.Config.GearShop)

local PlayerService
local DataService
local GeneralService
-- Game-specific services (removed)
-- local BuffsService
-- local TycoonService

RobuxService.Gamepasses = {}
for name, id in RobuxModule.Gamepasses do
	RobuxService.Gamepasses[id] = name
end

function RobuxService:Bind(productId, callback)
	assert(productId, "RobuxService:Bind: productId is nil")
	self.ProductCallbacks[productId] = callback
end

function RobuxService:BindGamepass(gamepassName, callback)
	self.GamepassesProcess[gamepassName] = callback
end

function RobuxService:ProcessEggQueue(player)
	-- Check if there are any queued eggs and available slots
	local queue = DataService:GetKey(player, "/System/Tycoon/EggQueue") or {}
	if #queue == 0 then
		return
	end

	local spawnSlots = DataService:GetKey(player, "/System/Tycoon/SpawnsUnlocked") or {}

	-- Get the actual spawners from ServerStorage (like other implementations)
	local spawnersOrdered = {}
	for _, spawner in game.ServerStorage.Tycoon.Spawners:GetChildren() do
		table.insert(spawnersOrdered, spawner)
	end
	table.sort(spawnersOrdered, function(a, b)
		return a.Name < b.Name
	end)
	task.defer(function()
		-- Find available slots and place queued eggs
		local processedEggs = 0
		for i = 1, #spawnersOrdered do
			if #queue > 0 then
				local spawnerName = spawnersOrdered[i].Name
				-- Check if this spawner is unlocked and has no NPC or Egg
				if spawnSlots[spawnerName] and not spawnSlots[spawnerName].NPC and not spawnSlots[spawnerName].Egg then
					-- Get the first egg from queue
					local eggData = table.remove(queue, 1)

					-- Place the egg in the available slot
					-- Add a small delay to allow visual update to process properly
					task.wait(0.5)
					-- Double check that the slot is still free before placing the egg
					local currentSlotData = DataService:GetKey(player, "/System/Tycoon/SpawnsUnlocked/" .. spawnerName)
					if currentSlotData and (currentSlotData.NPC or currentSlotData.Egg) then
						-- Slot was taken during the delay, put egg back in queue at start
						table.insert(queue, 1, eggData)
						continue
					end
					DataService:SetKey(player, "/System/Tycoon/SpawnsUnlocked/" .. spawnerName, {
						Egg = eggData,
					})

					processedEggs = processedEggs + 1

					-- Send notification to player
					GeneralService:SendStatusNotification(
						player,
						"An egg from your queue has been placed in your plot!",
						{
							Sound = "EggBuy",
						}
					)

					GeneralService.Client.UpdatePlotEggs:Fire(player)
				end
			end
		end

		-- Update the queue
		DataService:SetKey(player, "/System/Tycoon/EggQueue", queue)
	end)
end

function RobuxService:PurchaseLuckyBlocks(player, quantity)
	local spawnSlots = DataService:GetKey(player, "/System/Tycoon/SpawnsUnlocked") or {}

	-- Get the actual spawners from ServerStorage (like other implementations)
	local spawnersOrdered = {}
	for _, spawner in game.ServerStorage.Tycoon.Spawners:GetChildren() do
		table.insert(spawnersOrdered, spawner)
	end
	table.sort(spawnersOrdered, function(a, b)
		return a.Name < b.Name
	end)

	local eggsPlaced = 0
	local eggsQueued = 0

	-- Try to place eggs for the requested quantity
	for eggIndex = 1, quantity do
		-- Find the next available spawn slot
		local nextSpawnSlot = nil
		for i = 1, #spawnersOrdered do
			local spawnerName = spawnersOrdered[i].Name
			-- Check if this spawner is unlocked and has no NPC or Egg
			if spawnSlots[spawnerName] and not spawnSlots[spawnerName].NPC and not spawnSlots[spawnerName].Egg then
				nextSpawnSlot = spawnerName
				break
			end
		end

		-- Create LuckyBlock egg data
		local eggData = {
			Name = "LuckyBlock",
			PurchaseTime = os.time(),
			HatchTime = os.time() + 3, -- Quick hatch time (3 seconds as per EggsIndex)
		}

		if nextSpawnSlot then
			-- Place egg directly if slot is available
			DataService:SetKey(player, "/System/Tycoon/SpawnsUnlocked/" .. nextSpawnSlot, {
				Egg = eggData,
			})
			eggsPlaced = eggsPlaced + 1
			-- Update spawnSlots for next iteration
			spawnSlots[nextSpawnSlot] = { Egg = eggData }
		else
			-- Add to queue if no slots available
			local queue = DataService:GetKey(player, "/System/Tycoon/EggQueue") or {}
			table.insert(queue, eggData)
			DataService:SetKey(player, "/System/Tycoon/EggQueue", queue)
			eggsQueued = eggsQueued + 1
		end
	end

	-- Construct return message
	local message = ""
	if eggsPlaced > 0 then
		message = message .. "+ " .. eggsPlaced .. " Lucky Block" .. (eggsPlaced > 1 and "s" or "") .. " placed"
	end
	if eggsQueued > 0 then
		if eggsPlaced > 0 then
			message = message .. ", "
		else
			message = message .. "+ "
		end
		message = message .. eggsQueued .. " Lucky Block" .. (eggsQueued > 1 and "s" or "") .. " queued"
	end
	if eggsQueued > 0 then
		message = message .. "! Buy more slots to place them!"
	else
		message = message .. "!"
	end

	GeneralService.Client.UpdatePlotEggs:Fire(player)

	return message
end

function RobuxService:KnitStart()
	PlayerService = Knit.GetService("PlayerService")
	DataService = Knit.GetService("DataService")
	-- TycoonService = Knit.GetService("TycoonService")
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local callback = self.ProductCallbacks[receiptInfo.ProductId]
		if not callback then
			warn("No callback for product", receiptInfo.ProductId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local callbackSuccess, callbackResult = pcall(function()
			return callback(player, receiptInfo)
		end)

		if not callbackSuccess then
			warn("[RobuxService] Product callback failed for", receiptInfo.ProductId, ":", callbackResult)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local RobuxItemsPurchased = DataService:GetKey(player, "/System/Robux/ItemsPurchased") or 0
		DataService:SetKey(player, "/System/Robux/ItemsPurchased", RobuxItemsPurchased + 1)

		task.defer(function()
			local cost = MarketplaceService:GetProductInfo(receiptInfo.ProductId, Enum.InfoType.Product)
			if not cost then
				cost = { PriceInRobux = 0 }
			end
			cost = cost.PriceInRobux
			DataService:GetLock(player):with(function()
				local RobuxSpent = DataService:GetKey(player, "/System/Robux/Spent") or 0
				DataService:SetKey(player, "/System/Robux/Spent", RobuxSpent + cost)
			end)
		end)

		task.defer(function()
			self.Client.OnItemPurchased:Fire(player, receiptInfo.ProductId)
			if callbackResult then
				task.wait(1)
				self.Client.ShowMessage:Fire(player, callbackResult)
			end
		end)

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, purchased)
		if not purchased then
			return
		end
		local gamepassName = self.Gamepasses[gamepassId]
		if not gamepassName then
			return warn("No gamepass name for", gamepassId)
		end

		if not DataService:GetKey(player, "/System/OwnedGamepasses/" .. gamepassName) then
			local RobuxItemsPurchased = DataService:GetKey(player, "/System/Robux/ItemsPurchased") or 0
			DataService:SetKey(player, "/System/Robux/ItemsPurchased", RobuxItemsPurchased + 1)
			task.defer(function()
				local cost = MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
				if not cost then
					cost = { PriceInRobux = 0 }
				end
				cost = cost.PriceInRobux
				DataService:GetLock(player):with(function()
					local RobuxSpent = DataService:GetKey(player, "/System/Robux/Spent") or 0
					DataService:SetKey(player, "/System/Robux/Spent", RobuxSpent + cost)
				end)
			end)

			DataService:SetKey(player, "/System/OwnedGamepasses/" .. gamepassName, true)
			if self.GamepassesProcess[gamepassName] then
				task.defer(function()
					local msg = self.GamepassesProcess[gamepassName](player)
					self.Client.OnItemPurchased:Fire(player, gamepassId)
					if msg then
						task.wait(1)
						self.Client.ShowMessage:Fire(player, msg)
					end
				end)
			end
		end
	end)

	-- Function to check and set gamepass ownership for a player
	local function checkPlayerGamepasses(player)
		for gamepassId, gamepassName in self.Gamepasses do
			if gamepassId == 0 then
				continue
			end -- 0 = testing
			task.defer(function()
				local success, owned = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
				end)
				if success and owned then
					-- check if it is defined in the data structure
					if not DataService:GetKey(player, "/System/OwnedGamepasses/" .. gamepassName) then
						DataService:SetKey(player, "/System/OwnedGamepasses/" .. gamepassName, true)
						if self.GamepassesProcess[gamepassName] then
							task.defer(self.GamepassesProcess[gamepassName], player)
						end
					end
				end
			end)
		end
	end
	
	-- Check gamepasses for new players
	game.Players.PlayerAdded:Connect(checkPlayerGamepasses)
	
	-- Check gamepasses for players already in the game (e.g., in Studio)
	for _, player in game.Players:GetPlayers() do
		checkPlayerGamepasses(player)
	end

	-- check, for every gamepassId in self.Gamepasses there must be a GamepassesProcess function
	for gamepassId, gamepassName in self.Gamepasses do
		if not self.GamepassesProcess[gamepassName] then
			self:BindGamepass(gamepassName, function(player)
				warn("No GamepassesProcess function for", gamepassId)
				return "Purchased " .. gamepassName .. "!"
			end)
		end
	end

	return self:Setup()
end

function RobuxService.Client:GetCashPurchases(player)
	return RobuxModule:CalculateCashPurchases(player)
end

function RobuxService:Setup()
	GeneralService = Knit.GetService("GeneralService")
	-- BuffsService = Knit.GetService("BuffsService") -- Game-specific, removed

	-- Game-specific gamepass bindings (uncomment and modify for your game)
	-- self:BindGamepass("x2Cash", function(player)
	-- 	return "You now earn 2x Cash!"
	-- end)

	-- self:BindGamepass("VIP", function(player)
	-- 	return "You are now a VIP!"
	-- end)

	-- self:BindGamepass("x2BuoySpeed", function(player)
	-- 	return "Your buoys now move 2x faster!"
	-- end)

	-- Bind Cash purchase products
	-- for i, productId in ipairs(RobuxModule.CashProducts) do
	--     self:Bind(productId, function(player)
	--         local cashOptions = RobuxModule:CalculateCashPurchases(player)
	--         if cashOptions and cashOptions[i] then
	--             local cashAmount = cashOptions[i]
	--             PlayerService:AddStat(player, "Cash", cashAmount, "RobuxPurchase:Cash")

	--             -- First purchase bonus for Cash Pack 5
	--             if i == 5 then
	--                 -- Give Cash_8GB_RAM PC part
	--                 DataService:IncrementKey(player, "/System/Components/PCParts/Cash_8GB_RAM", 1)
	--                 return "Received $" .. std.FormatNumber(cashAmount) .. " and a bonus Cash_8GB_RAM PC part!"
	--             end

	--             return "Received $" .. std.FormatNumber(cashAmount) .. "!"
	--         else
	--             warn("Failed to calculate cash amount for product ID:", productId)
	--             return "Error processing purchase. Please contact support."
	--         end
	--     end)
	-- -- end

	-- Game-specific Starter Pack Purchase (removed - uncomment if needed)
	-- self:Bind(RobuxModule.Products.StarterPack, function(player)
	-- 	-- Uses BuffsService which was removed
	-- 	return "Starter Pack received!"
	-- end)

	-- self:Bind(RobuxModule.Products.XLPack, function(player)
	-- 	-- Give XL Epic Egg
	-- 	local spawnSlots = DataService:GetKey(player, "/System/Tycoon/SpawnsUnlocked") or {}

	-- 	-- Get the actual spawners from ServerStorage (like other implementations)
	-- 	local spawnersOrdered = {}
	-- 	for _, spawner in game.ServerStorage.Tycoon.Spawners:GetChildren() do
	-- 		table.insert(spawnersOrdered, spawner)
	-- 	end
	-- 	table.sort(spawnersOrdered, function(a, b)
	-- 		return a.Name < b.Name
	-- 	end)

	-- 	-- Find the next available spawn slot
	-- 	local nextSpawnSlot = nil
	-- 	for i = 1, #spawnersOrdered do
	-- 		local spawnerName = spawnersOrdered[i].Name
	-- 		-- Check if this spawner is unlocked and has no NPC or Egg
	-- 		if spawnSlots[spawnerName] and not spawnSlots[spawnerName].NPC and not spawnSlots[spawnerName].Egg then
	-- 			nextSpawnSlot = spawnerName
	-- 			break
	-- 		end
	-- 	end

	-- 	-- Create XL Epic Egg data
	-- 	local eggData = {
	-- 		Name = "DemonEgg",
	-- 		PurchaseTime = os.time(),
	-- 		HatchTime = os.time() + 15, -- Quick hatch time for purchase
	-- 		Size = "XL",
	-- 	}

	-- 	if nextSpawnSlot then
	-- 		-- Place egg directly if slot is available
	-- 		DataService:SetKey(player, "/System/Tycoon/SpawnsUnlocked/" .. nextSpawnSlot, {
	-- 			Egg = eggData,
	-- 		})
	-- 	else
	-- 		-- Add to queue if no slots available
	-- 		local queue = DataService:GetKey(player, "/System/Tycoon/EggQueue") or {}
	-- 		table.insert(queue, eggData)
	-- 		DataService:SetKey(player, "/System/Tycoon/EggQueue", queue)
	-- 	end

	-- 	-- Give 2x Cash buff for 2 hours (120 minutes)
	-- 	BuffsService:GrantBuff(player, "x2Cash", 120)

	-- 	-- Give 2x Luck buff for 2 hours (120 minutes)
	-- 	BuffsService:GrantBuff(player, "x2Luck", 120)

	-- 	DataService:SetKey(player, "/System/Flags/PurchasedXLPack", true)

	-- 	GeneralService.Client.UpdatePlotEggs:Fire(player)

	-- 	if nextSpawnSlot then
	-- 		return "+ 1 XL Epic Egg, 2x Cash & Luck for 2 hours!"
	-- 	else
	-- 		return "+ 1 XL Epic Egg, 2x Cash & Luck for 2 hours! Buy a new slot to place it!"
	-- 	end
	-- end)

	-- -- LuckyBlock purchases
	-- self:Bind(RobuxModule.Products.LuckyBlock1, function(player)
	-- 	return self:PurchaseLuckyBlocks(player, 1)
	-- end)

	-- self:Bind(RobuxModule.Products.LuckyBlock3, function(player)
	-- 	return self:PurchaseLuckyBlocks(player, 3)
	-- end)

	-- Cash pack purchases
	for i = 1, 4 do
		self:Bind(RobuxModule.Products["Cash" .. i], function(player)
			local allTimeCash = DataService:GetKey(player, "/AllTime/Cash") or 0
			local cashOptions = RobuxModule:CalculateCashPurchases(allTimeCash)
			local cashAmount = cashOptions[i]

			PlayerService:AddStat(player, "Cash", cashAmount, "Robux")

			return "Received $" .. std.FormatNumber(cashAmount) .. " Cash!"
		end)
	end

	-- Permanent Clones Bonus (CVR)
	-- Stores cumulative clone bonus amount (3 -> 11 -> 26 -> 56)
	local clonesBonusAmounts = {
		3,   -- Tier 1: +3 clones
		8,   -- Tier 2: +8 clones
		15,  -- Tier 3: +15 clones
		30,  -- Tier 4: +30 clones
	}
	local clonesBonusCumulative = { 0, 3, 11, 26, 56 } -- Expected totals after each tier (index 1 = before any purchase)
	
	for i = 1, 4 do
		self:Bind(RobuxModule.Products["ClonesBonus" .. i], function(player)
			local currentBonus = DataService:GetKey(player, "/System/ClonesBonus") or 0
			
			-- Check if player already purchased this tier or higher
			if currentBonus >= clonesBonusCumulative[i + 1] then
				return nil -- Already purchased this tier
			end
			
			-- Check if player is on the correct tier (must purchase sequentially)
			if currentBonus ~= clonesBonusCumulative[i] then
				return nil -- Must purchase previous tier first
			end
			
			-- Add the clone bonus amount
			DataService:IncrementKey(player, "/System/ClonesBonus", clonesBonusAmounts[i])
			
			return "+" .. clonesBonusAmounts[i] .. " Clones Unlocked!"
		end)
	end

	-- Permanent Steps Multiplier (CVR)
	local stepsMultipliers = {
		2,    -- Tier 1: x2
		4,    -- Tier 2: x4
		8,    -- Tier 3: x8
		16,   -- Tier 4: x16
		32,   -- Tier 5: x32
		64,   -- Tier 6: x64
		128,  -- Tier 7: x128
		256,  -- Tier 8: x256
		512,  -- Tier 9: x512
		1024, -- Tier 10: x1024
	}
	for i = 1, 10 do
		self:Bind(RobuxModule.Products["StepsMultiplier" .. i], function(player)
			local currentTier = DataService:GetKey(player, "/System/StepsMultiplier") or 0
			
			-- Check if player already purchased this tier or higher
			if currentTier >= i then
				return nil -- Already purchased this tier
			end
			
			-- Check if player is on the correct tier (must purchase sequentially)
			if currentTier ~= i - 1 then
				return nil -- Must purchase previous tier first
			end
			
			-- Update tier tracking
			DataService:SetKey(player, "/System/StepsMultiplier", i)
			
			return "x" .. stepsMultipliers[i] .. " Steps Multiplier Unlocked!"
		end)
	end
	
	-- Ad reward dev product (wins are granted by GeneralService, this just acknowledges the receipt)
	local AD_REWARD_DEV_PRODUCT_ID = RobuxModule.Products.AdReward
	self:Bind(AD_REWARD_DEV_PRODUCT_ID, function(player)
		-- Wins are tracked and granted by GeneralService.Client:RequestAdReward
		-- This callback just acknowledges the ProcessReceipt for the ad reward product
		return nil -- No message needed, GeneralService handles notifications
	end)
	
	-- x2 Wins dev product (fallback when ads aren't ready)
	local X2_WINS_DEV_PRODUCT_ID = RobuxModule.Products.X2Wins
	self:Bind(X2_WINS_DEV_PRODUCT_ID, function(player)
		-- Get pending ad reward data from GeneralService
		local pendingData = GeneralService.PendingAdRewards[player.UserId]
		if pendingData then
			-- Grant wins and teleport player (with rebirth multiplier)
			local actualWins = PlayerService:GrantWins(player, pendingData.winsToGrant)
			
			-- Deduct portal cost if player used a portal this run (prevents 2x win exploit)
			-- Only deduct the original portal cost (what they paid to skip)
			local portalCost = GeneralService.PortalCostsThisRun[player.UserId]
			if portalCost and portalCost > 0 then
				-- Ensure wins don't go below 0
				local currentWins = DataService:GetKey(player, "/Default/Wins") or 0
				local deduction = math.floor(math.min(portalCost, currentWins))
				DataService:IncrementKey(player, "/Default/Wins", -deduction)
				DataService:IncrementKey(player, "/AllTime/Wins", -deduction)
				GeneralService.PortalCostsThisRun[player.UserId] = nil
			end
			
			-- Teleport player back to spawn
			local character = player.Character
			if character and character.PrimaryPart then
				local spawnLocation = workspace:FindFirstChild("SpawnLocation")
				if spawnLocation then
					local spawnPos = spawnLocation.Position + Vector3.new(0, 3, 0)
					character:PivotTo(CFrame.new(spawnPos))
					
					-- Notify client to teleport clones
					GeneralService.Client.PlayerTeleportedToSpawn:Fire(player)
				end
			end
			
			-- Clear pending data
			GeneralService.PendingAdRewards[player.UserId] = nil
			
			-- Notify client that purchase completed
			GeneralService.Client.AdRewardCompleted:Fire(player, true, 2, 2)
			
			return "+" .. actualWins .. " Wins!"
		else
			-- No pending data, just give default wins (with rebirth multiplier)
			local actualWins = PlayerService:GrantWins(player, 2)
			
			-- Still deduct portal cost if player used a portal this run (prevents exploit)
			-- Only deduct the original portal cost (what they paid to skip)
			local portalCost = GeneralService.PortalCostsThisRun[player.UserId]
			if portalCost and portalCost > 0 then
				-- Ensure wins don't go below 0
				local currentWins = DataService:GetKey(player, "/Default/Wins") or 0
				local deduction = math.floor(math.min(portalCost, currentWins))
				DataService:IncrementKey(player, "/Default/Wins", -deduction)
				DataService:IncrementKey(player, "/AllTime/Wins", -deduction)
				GeneralService.PortalCostsThisRun[player.UserId] = nil
			end
			
			return "+" .. actualWins .. " Wins!"
		end
	end)

	-- Skip Rebirth purchases (pay to skip level requirement)
	local RebirthService = Knit.GetService("RebirthService")
	for i = 1, 5 do
		local productId = RobuxModule.Products["SkipRebirth" .. i]
		if productId then
			self:Bind(productId, function(player)
				local currentRebirths = DataService:GetKey(player, "/AllTime/Rebirths") or 0
				local nextRebirthNumber = currentRebirths + 1
				
				-- Verify this is the correct product for their rebirth level
				local expectedTier = math.min(nextRebirthNumber, 5)
				if expectedTier ~= i then
					return nil -- Wrong product, don't process
				end
				
				local success, errorMessage = RebirthService:SkipRebirth(player)
				if success then
					return "Rebirth " .. nextRebirthNumber .. " complete!"
				else
					return nil -- Will refund if purchase fails
				end
			end)
		end
	end

	-- Game-specific purchase bindings (removed - uncomment if needed)
	-- Includes: Tower purchases, Lucky Crates, Slide Prompts, Plot Expansions, Pirate Buoy
	--[[
	local PlotService = Knit.GetService("PlotService")
	-- Tower, Lucky Crate, Slide Prompt, Plot Expansion, Pirate Buoy purchase bindings
	-- These all use PlotService which was removed
	]]

	-- Game-specific Gear Shop and Slide purchase bindings (removed - uncomment if needed)
	--[[
	local GearService = Knit.GetService("GearService")

	for _, gearInfo in GearShop.StoreInfo do
		local productKey = RobuxModule.GearToProductKey[gearInfo.Name]
		if productKey and RobuxModule.Products[productKey] then
			self:Bind(RobuxModule.Products[productKey], function(player)
				if gearInfo.Type == "Potion" then
					DataService:IncrementKey(player, "/System/Potions/" .. gearInfo.Name, 1)
				else
					GearService:GrantGear(player, gearInfo.Name, 1)
				end
				local displayName = gearInfo.DisplayName or gearInfo.Name
				return "Received 1x " .. displayName .. "!"
			end)
		end
	end

	-- Individual Slide Purchases (uses centralized mapping from Robux config)
	local Mutations = require(Knit.Shared.Mutations)

	for componentName, productKey in RobuxModule.ComponentToProductKey do
		if RobuxModule.Products[productKey] then
			self:Bind(RobuxModule.Products[productKey], function(player)
				-- Uses SecretShopService and Mutations which were removed
				DataService:IncrementKey(player, "/System/Inventory/" .. componentName, 1)
				return "Received 1x " .. componentName .. "!"
			end)
		end
	end
	]]

	-- Uncomment and modify the Gem pack purchases to include first purchase bonus for Gem Pack 5
	-- for i=1, 5 do
	--     self:Bind(RobuxModule.Products["Gem"..i], function(player)
	--         local amount = RobuxModule:CalculateGemPurchases(DataService:GetKey(player, "/Default/Rebirths") or 0)[i]
	--         PlayerService:AddStat(player, "Gems", amount, "Robux")

	--         -- First purchase bonus for Gem Pack 5
	--         if i == 5 and not DataService:GetKey(player, "/System/Flags/GemPack5FirstPurchase") then
	--             DataService:SetKey(player, "/System/Flags/GemPack5FirstPurchase", true)
	--             -- Give Gem_Core_CPU PC part
	--             DataService:IncrementKey(player, "/System/Components/PCParts/Gem_Core_CPU", 1)
	--             return "Received "..std.FormatNumber(amount).." Gems and a bonus Gem_Core_CPU PC part!"
	--         end

	--         return "Received "..std.FormatNumber(amount).." Gems!"
	--     end)
	-- end

	-- for _, buffName in {"x2Power", "x2Wins", "x2Luck", "x2Gems"} do
	-- 	local productName = `x3{buffName}Potions`
	-- 	self:Bind(RobuxModule.Products[productName], function(player)
	-- 		local statPath = "/System/OwnedPotions/"..buffName

	-- 		local owned = DataService:GetKey(player, statPath) or 0
	-- 		DataService:SetKey(player, statPath, owned + 3)
	-- 	end)
	-- end

	-- self:Bind(RobuxModule.Products.LimitedStarterPack, function(player)
	-- 	if not DataService:GetKey(player, "/System/Timers/StarterPackOffer") then
	-- 		return "Offer has expired!"
	-- 	end
	-- 	PlayerService:AddStat(player, "Wins", math.ceil(math.clamp((DataService:GetKey(player, "/Defaults/Wins") or 0) * .2, 2500, 5_000_000)))
	-- 	PlayerService:AddStat(player, "Power", math.ceil(math.clamp((DataService:GetKey(player, "/Defaults/Power") or 0) * .2, 50000, 15_000_000)))
	-- 	PetService:GivePet(player, "Valentine's Cat", true)
	-- 	DataService:SetKey(player, "/System/Timers/StarterPackOffer", nil)
	-- end)

	-- self:BindGamepass("Speedy", function(player)
	-- 	if player.Character and player.Character.Humanoid then
	-- 		player.Character.Humanoid.WalkSpeed = 32
	-- 	end
	-- end)
end

function RobuxService:KnitInit()
	self.ProductCallbacks = {}
	self.GamepassesProcess = {}
	self.PendingAdminShopPurchases = {} -- [player.UserId] = { ComponentName, MutationName, Timestamp }
	self.LimitedStockCache = {} -- [productKey] = { Stock = number, LastFetched = timestamp }
	self.LimitedStockDataStore = DataStoreService:GetDataStore("LimitedStockProducts")

	self:InitializeLimitedStockPolling()
end

function RobuxService:InitializeLimitedStockPolling()
	for productKey, config in RobuxModule.LimitedStockProducts do
		self:FetchLimitedStock(productKey)
	end

	-- fetch every 4 minutes so we dont reach quota
	task.spawn(function()
		while true do
			task.wait(240)
			for productKey, config in RobuxModule.LimitedStockProducts do
				self:FetchLimitedStock(productKey)
			end
		end
	end)
end

function RobuxService:FetchLimitedStock(productKey)
	local config = RobuxModule.LimitedStockProducts[productKey]
	if not config then
		return nil
	end

	local success, stock = pcall(function()
		return self.LimitedStockDataStore:GetAsync(config.DataStoreKey)
	end)

	if success then
		if stock == nil then
			stock = config.InitialStock
			pcall(function()
				self.LimitedStockDataStore:SetAsync(config.DataStoreKey, stock)
			end)
		end

		self.LimitedStockCache[productKey] = {
			Stock = stock,
			LastFetched = os.time(),
		}

		for _, player in game:GetService("Players"):GetPlayers() do
			self.Client.LimitedStockUpdated:Fire(player, productKey, stock)
		end

		return stock
	else
		return nil
	end
end

function RobuxService:GetLimitedStock(productKey)
	local cached = self.LimitedStockCache[productKey]
	if cached then
		return cached.Stock
	end

	return self:FetchLimitedStock(productKey)
end

function RobuxService:DecrementLimitedStock(productKey)
	local config = RobuxModule.LimitedStockProducts[productKey]
	if not config then
		return false, "Invalid product"
	end

	local success, newStock = pcall(function()
		return self.LimitedStockDataStore:UpdateAsync(config.DataStoreKey, function(currentStock)
			currentStock = currentStock or config.InitialStock
			if currentStock <= 0 then
				return nil
			end
			return currentStock - 1
		end)
	end)

	if success and newStock then
		self.LimitedStockCache[productKey] = {
			Stock = newStock,
			LastFetched = os.time(),
		}

		for _, player in game:GetService("Players"):GetPlayers() do
			self.Client.LimitedStockUpdated:Fire(player, productKey, newStock)
		end

		return true, newStock
	elseif success and newStock == nil then
		return false, "Out of stock"
	else
		return false, "DataStore error"
	end
end

-- Register a pending Admin Shop purchase (called by client before prompting Robux purchase)
function RobuxService:RegisterPendingAdminShopPurchase(player, componentName, mutationName)
	self.PendingAdminShopPurchases[player.UserId] = {
		ComponentName = componentName,
		MutationName = mutationName,
		Timestamp = os.time(),
	}
	return true
end

-- Get and clear pending Admin Shop purchase for a player
function RobuxService:GetPendingAdminShopPurchase(player, componentName)
	local pending = self.PendingAdminShopPurchases[player.UserId]
	if not pending then
		return nil
	end

	-- Check if it's for the right component and not too old (60 seconds max)
	if pending.ComponentName ~= componentName then
		return nil
	end

	if os.time() - pending.Timestamp > 60 then
		self.PendingAdminShopPurchases[player.UserId] = nil
		return nil
	end

	-- Clear the pending purchase
	self.PendingAdminShopPurchases[player.UserId] = nil

	return pending
end

return RobuxService
