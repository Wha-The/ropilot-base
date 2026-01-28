--[[
    CurrencyCollectionAnimation: Animates currency icons from center to arc position, then down.
    
    Animation Flow:
    1. Spawn at center (0.5, 0.5)
    2. Tween along circular arc to left or right (ease-out: fast start, slow end)
    3. Sweep down to (0.5, 0.8)
    4. Destroy after completion
    
    Usage:
        local CurrencyCollectionAnimation = require(path.to.CurrencyCollectionAnimation)
        
        -- Spawn a single animation with amount
        CurrencyCollectionAnimation.Spawn(100) -- Shows "+100"
        
        -- Start debug mode (spawns every 0.2s)
        CurrencyCollectionAnimation.StartDebug()
        
        -- Stop debug mode
        CurrencyCollectionAnimation.StopDebug()
]]

local std = shared.std

local CurrencyCollectionAnimation = {}

-- Configuration
local CONFIG = {
    ArcRadius = 0.25, -- Screen scale units
    ArcTweenDuration = 0.4,
    DownTweenDuration = 0.3,
    FinalPosition = UDim2.fromScale(0.5, 0.8),
}

-- Template reference (loaded on first use)
local ShoeTemplate = nil

-- Debug state
local debugConnection = nil

--[[
    Get or load the shoe template
    @return Frame - the shoe template
]]
local function getTemplate()
    if not ShoeTemplate then
        ShoeTemplate = std.MainGui:WaitForChild("PopupTemplates"):WaitForChild("Shoe")
    end
    return ShoeTemplate
end

--[[
    Create a currency icon by cloning the template
    @param amount: number - the currency amount to display
    @return Frame, UDim2 - the icon and its original size
]]
local function createIcon(amount)
    local template = getTemplate()
    local icon = template:Clone()
    
    -- Store original size before modifying
    local originalSize = icon.Size
    
    -- Set up the clone
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.Visible = true
    icon.ZIndex = 100
    
    -- Start at size 0 for pop-in effect
    icon.Size = UDim2.fromScale(0, 0)
    
    -- Update the amount text
    local textLabel = icon:FindFirstChild("TextLabel")
    if textLabel then
        textLabel.Text = "+" .. std.FormatNumber(amount or 0)
        textLabel.ZIndex = 101
    end
    
    -- Update image ZIndex
    local imageLabel = icon:FindFirstChild("ImageLabel")
    if imageLabel then
        imageLabel.ZIndex = 100
    end
    
    icon.Parent = std.MainGui
    return icon, originalSize
end

--[[
    Calculate arc target position based on random angle
    @param goLeft: boolean - whether to arc to the left side
    @return UDim2 - the target position on the arc
]]
local function calculateArcPosition(goLeft)
    local angle
    if goLeft then
        -- Left side: 135° to 225° (in radians)
        angle = std.random.float(math.rad(135), math.rad(225))
    else
        -- Right side: -45° to 45° (in radians)
        angle = std.random.float(math.rad(-45), math.rad(45))
    end
    
    -- Calculate position on arc relative to center (0.5, 0.5)
    local offsetX = math.cos(angle) * CONFIG.ArcRadius
    local offsetY = math.sin(angle) * CONFIG.ArcRadius
    
    return UDim2.fromScale(0.5 + offsetX, 0.5 + offsetY)
end

--[[
    Spawn and animate a single currency collection animation
    @param amount: number - the currency amount to display (optional, defaults to random)
]]
function CurrencyCollectionAnimation.Spawn(amount)
    amount = amount or math.random(10, 500)
    local icon, originalSize = createIcon(amount)
    
    -- Randomly choose left or right
    local goLeft = std.random.float(0, 1) > 0.5
    local arcPosition = calculateArcPosition(goLeft)
    
    -- Phase 1: Arc tween (fast start, slow end) + size pop-in
    local arcTween = std.SimpleTween(
        icon,
        "Position",
        arcPosition,
        CONFIG.ArcTweenDuration,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    )
    
    -- Size pop-in: 0 -> original size with Back easing for bounce effect
    std.SimpleTween(
        icon,
        "Size",
        originalSize,
        CONFIG.ArcTweenDuration,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out
    )
    
    -- Phase 2: Sweep down after arc completes + shrink
    arcTween.Completed:Connect(function()
        local downTween = std.SimpleTween(
            icon,
            "Position",
            CONFIG.FinalPosition,
            CONFIG.DownTweenDuration,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut
        )
        
        -- Shrink while going down
        std.SimpleTween(
            icon,
            "Size",
            UDim2.fromScale(0, 0),
            CONFIG.DownTweenDuration,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.In
        )
        
        -- Destroy after sweep completes
        downTween.Completed:Connect(function()
            icon:Destroy()
        end)
    end)
end

--[[
    Start debug mode - spawns animation every 0.2 seconds
]]
function CurrencyCollectionAnimation.StartDebug()
    if debugConnection then
        return -- Already running
    end
    
    debugConnection = std.Clock.every(1/5, function()
        CurrencyCollectionAnimation.Spawn()
    end)
    
    print("[CurrencyCollectionAnimation] Debug mode started - spawning every 0.2s")
end

--[[
    Stop debug mode
]]
function CurrencyCollectionAnimation.StopDebug()
    if debugConnection then
        debugConnection:Disconnect()
        debugConnection = nil
        print("[CurrencyCollectionAnimation] Debug mode stopped")
    end
end

return CurrencyCollectionAnimation
