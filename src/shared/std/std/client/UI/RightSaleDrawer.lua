local std = shared.std
local Knit = std.Knit

local ZenController
local RobuxController
local DataController

--[[
    RightSaleDrawer
    A utility class for displaying rotating sale products on the right side of the screen.
    
    Usage:
    ```lua
    local drawer = std.client.UI.RightSaleDrawer(std.MainGui.RightSaleDrawer)
    drawer:Setup({
        {
            -- Group 1: Progressive purchase (player buys tier 1, then tier 2, etc.)
            { Id = 123456, Image = "rbxassetid://...", Name = "Gold Pack", DataPath = "/System/Purchases/GoldPack" },
            { Id = 234567, Image = "rbxassetid://...", Name = "Diamond Pack", DataPath = "/System/Purchases/DiamondPack" },
        },
        {
            -- Group 2: Another progressive purchase
            { Id = 345678, Image = "rbxassetid://...", Name = "Starter", DataPath = "/System/Flags/PurchasedStarter" },
        },
    }, {
        CycleDuration = 8,        -- How long each product shows (default: 8 seconds)
        CooldownAfterPurchase = 20, -- Cooldown after purchase before showing again (default: 20 seconds)
    })
    ```
    
    Product fields:
    - Id: Developer product ID or gamepass ID (required for price/icon fetching)
    - IsGamepass: If true, treats Id as a gamepass ID instead of product ID (optional, default: false)
    - Image: rbxassetid:// string for the icon (optional, will fetch from marketplace if not provided)
    - Title: Display title shown on the item (optional, falls back to Name, then marketplace info)
    - Caption: Secondary text shown below/beside title (optional, hidden if not provided)
    - Name: Fallback display name (optional, will fetch from marketplace if not provided)
    - DataPath: Path to observe for ownership/tier tracking (optional)
    - Callback: Custom function to call on click (optional, defaults to prompting product/gamepass purchase)
    - HideWhenOwned: If true, hides when DataPath returns truthy (default: true for single-item groups)
]]

local RightSaleDrawer do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _RightSaleDrawer_ = {};
    function _RightSaleDrawer_.__init__(self, drawer)
        ZenController = Knit.GetController("ZenController")
        RobuxController = Knit.GetController("RobuxController")
        DataController = Knit.GetController("DataController")
        
        self.Drawer = drawer
        self.DrawerTemplate = drawer:FindFirstChild("Template")
        assert(self.DrawerTemplate, "RightSaleDrawer requires a 'Template' child")
        self.DrawerTemplate.Parent = nil
        
        self.ProductGroups = {}
        self.ActiveItems = {} -- Currently displayed items
        self.GroupStates = {} -- Track state per group (current tier, cooldown, etc.)
        self.CurrentIndex = 0 -- Which group is currently being cycled to
        
        -- Animation state
        self.SwayTime = 0
        self.SwayConnection = nil
    end

    function _RightSaleDrawer_.Setup(self, productGroups, options)
        options = options or {}
        self.CycleDuration = options.CycleDuration or 8
        self.CooldownAfterPurchase = options.CooldownAfterPurchase or 20
        self.MaxVisible = options.MaxVisible or 3
        self.InitialLoadGracePeriod = options.InitialLoadGracePeriod or 3 -- seconds
        
        self.ProductGroups = productGroups
        self.SetupTime = os.clock()
        
        -- Initialize group states
        for groupIndex, group in ipairs(productGroups) do
            self.GroupStates[groupIndex] = {
                CurrentTier = 0, -- 0 means show tier 1
                IsOnCooldown = false,
            }
            
            -- Setup data observers for each product in the group
            for tierIndex, product in ipairs(group) do
                if product.DataPath then
                    DataController:Observe(product.DataPath, function(value)
                        self:_onDataChanged(groupIndex, tierIndex, value, product)
                    end)
                end
            end
        end
        
        -- Start the sway animation
        self:_startSwayAnimation()
        
        -- Initial display and cycling
        self:_refreshDisplay()
        self:_startCycling()
        
        return self
    end
    
    function _RightSaleDrawer_._onDataChanged(self, groupIndex, tierIndex, value, product)
        local state = self.GroupStates[groupIndex]
        if not state then return end
        
        -- Determine if this tier is purchased
        -- If product has DataValue, compare value >= DataValue (for numeric tier tracking)
        -- Otherwise, just check if value is truthy (for boolean tier tracking)
        local isPurchased
        if product and product.DataValue then
            isPurchased = value and value >= product.DataValue
        else
            isPurchased = value and true or false
        end
        
        -- Update current tier if this tier is purchased
        if isPurchased and tierIndex > state.CurrentTier then
            state.CurrentTier = tierIndex
            
            -- Only apply cooldown if we're past the initial load grace period
            -- This ensures loading existing data on join doesn't trigger cooldown
            local timeSinceSetup = os.clock() - self.SetupTime
            if timeSinceSetup > self.InitialLoadGracePeriod then
                state.IsOnCooldown = true
                
                -- Schedule cooldown end
                task.delay(self.CooldownAfterPurchase, function()
                    state.IsOnCooldown = false
                    self:_refreshDisplay()
                end)
            end
            
            -- Always refresh display when data changes
            self:_refreshDisplay()
        end
    end
    
    function _RightSaleDrawer_._getNextAvailableProduct(self, groupIndex)
        local group = self.ProductGroups[groupIndex]
        local state = self.GroupStates[groupIndex]
        
        if not group or not state then return nil end
        
        -- Check cooldown
        if state.IsOnCooldown then
            return nil
        end
        
        -- Get next tier
        local nextTier = state.CurrentTier + 1
        
        -- Check if we've completed all tiers
        if nextTier > #group then
            return nil
        end
        
        return group[nextTier], nextTier
    end
    
    function _RightSaleDrawer_._createItemUI(self, product, groupIndex, tierIndex)
        local item = self.DrawerTemplate:Clone()
        item.Name = "SaleItem_" .. groupIndex .. "_" .. tierIndex
        item.Visible = false
        item.Parent = self.Drawer
        
        -- Setup icon and price
        local icon = item:FindFirstChild("Icon")
        if icon and product.Id then
            if product.Image then
                icon.Image = product.Image
            end
            
            local priceLabel = icon:FindFirstChild("Price")
            task.defer(function()
                -- Load price and get product info in one call
                -- Use GamePass info type if IsGamepass flag is set
                local infoType = product.IsGamepass and Enum.InfoType.GamePass or Enum.InfoType.Product
                local info = ZenController.LoadPrice(priceLabel, product.Id, infoType, true)
                
                -- Set icon image from info if not provided
                if not product.Image and info and info.IconImageAssetId then
                    icon.Image = "rbxassetid://" .. info.IconImageAssetId
                end
            end)
        end
        
        -- Setup title label
        local titleLabel = item:FindFirstChild("Title")
        if titleLabel then
            if product.Title then
                titleLabel.Text = product.Title
            elseif product.Name then
                titleLabel.Text = product.Name
            else
                titleLabel.Text = "..."
                task.defer(function()
                    local success, info = pcall(function()
                        return game:GetService("MarketplaceService"):GetProductInfo(product.Id, Enum.InfoType.Product)
                    end)
                    if success and info then
                        titleLabel.Text = info.Name or "Sale"
                    end
                end)
            end
        end
        
        -- Setup caption label
        local captionLabel = item:FindFirstChild("Caption")
        if captionLabel then
            if product.Caption then
                captionLabel.Text = product.Caption
                captionLabel.Visible = true
            else
                captionLabel.Visible = false
            end
        end
        
        -- Setup button click
        local button = std.client.UI.Button(item):AddClickEffect("Bounce"):AddHoverEffect("HL", 1.1)
        button:OnClick(function()
            if product.Callback then
                product.Callback()
            elseif product.Id then
                -- Use PromptGamepass for gamepasses, PromptProduct for dev products
                if product.IsGamepass then
                    RobuxController:PromptGamepass(product.Id)
                else
                    RobuxController:PromptProduct(product.Id)
                end
            end
        end)
        
        return item, icon, product.Rainbow
    end
    
    function _RightSaleDrawer_._refreshDisplay(self)
        -- Clear existing items
        for _, item in pairs(self.ActiveItems) do
            if item.Instance then
                item.Instance:Destroy()
            end
        end
        self.ActiveItems = {}
        
        -- Find all available products
        local availableProducts = {}
        for groupIndex, _ in ipairs(self.ProductGroups) do
            local product, tierIndex = self:_getNextAvailableProduct(groupIndex)
            if product then
                table.insert(availableProducts, {
                    Product = product,
                    GroupIndex = groupIndex,
                    TierIndex = tierIndex,
                })
            end
        end
        
        -- Display up to MaxVisible items
        local displayCount = math.min(#availableProducts, self.MaxVisible)
        for i = 1, displayCount do
            local data = availableProducts[i]
            local item, icon, rainbow = self:_createItemUI(data.Product, data.GroupIndex, data.TierIndex)
            item.Visible = true
            
            -- Animate in
            item.Position = item.Position + UDim2.fromScale(0.2, 0)
            local originalPos = item.Position - UDim2.fromScale(0.2, 0)
            std.SimpleTween(item, "Position", originalPos, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            
            self.ActiveItems[i] = {
                Instance = item,
                Product = data.Product,
                GroupIndex = data.GroupIndex,
                TierIndex = data.TierIndex,
                Icon = icon,
                Rainbow = rainbow,
            }
        end
    end
    
    function _RightSaleDrawer_._startSwayAnimation(self)
        if self.SwayConnection then return end
        
        self.SwayConnection = std.Clock.every(function(dt)
            self.SwayTime = self.SwayTime + dt
            
            -- Apply gentle sway to all active items
            for i, itemData in pairs(self.ActiveItems) do
                if itemData.Instance then
                    -- Offset phase per item for variety
                    local phase = self.SwayTime * 0.5 + (i * 0.5)
                    itemData.Instance.Rotation = 1.5 * math.sin(phase)
                    
                    -- Apply rainbow effect to icon if enabled
                    if itemData.Rainbow and itemData.Icon then
                        local rainbowPhase = self.SwayTime * 0.5 + (i * 0.3)
                        local hue = (rainbowPhase % 1)
                        itemData.Icon.ImageColor3 = Color3.fromHSV(hue, 0.8, 1)
                    end
                end
            end
        end)
    end
    
    function _RightSaleDrawer_._startCycling(self)
        -- For now, just refresh periodically to check for state changes
        task.defer(function()
            while self.Drawer and self.Drawer.Parent do
                task.wait(self.CycleDuration)
                self:_refreshDisplay()
            end
        end)
    end
    
    function _RightSaleDrawer_.Destroy(self)
        if self.SwayConnection then
            self.SwayConnection()
            self.SwayConnection = nil
        end
        
        for _, item in pairs(self.ActiveItems) do
            if item.Instance then
                item.Instance:Destroy()
            end
        end
        self.ActiveItems = {}
    end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] RightSaleDrawer=setmetatable(_RightSaleDrawer_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_RightSaleDrawer_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _RightSaleDrawer_.__index__ then return _RightSaleDrawer_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("RightSaleDrawer").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=RightSaleDrawer,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor RightSaleDrawer>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end


return RightSaleDrawer
