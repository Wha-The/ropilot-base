--[[
    CashGainedAnimation: Animates a currency TextLabel when cash is gained.
    
    Features:
    - Label grows slightly bigger when cash is gained
    - NumberTween animates the value increasing satisfyingly
    - UIGradient tweens from GreenGradient (default) to WhiteGradient while increasing
    - Shrinks back and gradient returns to GreenGradient after animation completes
    
    Usage:
        local CashGainedAnimation = require(path.to.CashGainedAnimation)
        
        -- TextLabel must have:
        --   UIGradient (the active gradient that gets animated)
        --   GreenGradient (UIGradient reference for the default state)
        --   WhiteGradient (UIGradient reference for the "gaining" state)
        
        CashGainedAnimation.Bind(textLabel, DataController, "/Default/Cash", {
            Prefix = "",
            GetAnimTime = function(gained) return math.clamp(gained / 1000, 0.3, 1.5) end, -- optional
        })
        
        -- To trigger the animation manually:
        CashGainedAnimation.Animate(textLabel, oldValue, newValue)
]]

local std = shared.std

local CashGainedAnimation = {}

-- Configuration
local DEFAULT_CONFIG = {
    ScaleMultiplier = 1.15, -- How much bigger the label grows
    ScaleUpDuration = 0.1, -- Duration to scale up
    ScaleDownDuration = 0.15, -- Duration to scale back down
    DefaultAnimTime = 0.35, -- Default number tween duration
    EasingStyle = Enum.EasingStyle.Quart,
    EasingDirection = Enum.EasingDirection.Out,
}

-- Active animations tracker to cancel previous animations
local activeAnimations = {}

--[[
    Animate the cash gained effect on a TextLabel
    @param textLabel: The TextLabel to animate
    @param oldValue: The previous cash value
    @param newValue: The new cash value
    @param options: Optional configuration table
        - GetAnimTime: function(value) -> number (animation duration based on value)
        - Prefix: string prefix for the text (default "")
]]
function CashGainedAnimation.Animate(textLabel, oldValue, newValue, options)
    options = options or {}
    local prefix = options.Prefix or ""
    local getAnimTime = options.GetAnimTime
    
    -- Only animate if gaining cash
    if newValue <= oldValue then
        textLabel.Text = prefix .. std.FormatNumber(newValue)
        return
    end
    
    -- Cancel any existing animation on this label
    local labelId = tostring(textLabel)
    if activeAnimations[labelId] then
        for _, tween in activeAnimations[labelId] do
            if tween and tween.Cancel then
                tween:Cancel()
            end
        end
    end
    activeAnimations[labelId] = {}
    
    -- Get references
    -- UIGradient is the active gradient, GreenGradient and WhiteGradient are references
    local greenGradient = textLabel:FindFirstChild("GreenGradient")
    local whiteGradient = textLabel:FindFirstChild("WhiteGradient")
    local activeGradient = nil
    
    -- Find the active UIGradient (the one that's not a reference)
    for _, child in textLabel:GetChildren() do
        if child:IsA("UIGradient") and child.Name ~= "GreenGradient" and child.Name ~= "WhiteGradient" then
            activeGradient = child
            break
        end
    end
    
    -- Store original size if not already stored
    if not textLabel:GetAttribute("OriginalSize") then
        textLabel:SetAttribute("OriginalSize", textLabel.Size)
    end
    local originalSize = textLabel:GetAttribute("OriginalSize")
    
    -- Calculate animation time
    local animTime = DEFAULT_CONFIG.DefaultAnimTime
    if getAnimTime then
        animTime = getAnimTime(newValue - oldValue)
    end
    animTime = math.max(animTime, 0.1) -- Minimum animation time
    
    -- Scale up the label
    local scaledSize = std.Util.UDim2Multiply(originalSize, DEFAULT_CONFIG.ScaleMultiplier)
    local scaleUpTween = std.SimpleTween(
        textLabel, 
        "Size", 
        scaledSize, 
        DEFAULT_CONFIG.ScaleUpDuration, 
        Enum.EasingStyle.Circular, 
        Enum.EasingDirection.Out
    )
    table.insert(activeAnimations[labelId], scaleUpTween)
    
    -- Tween active gradient from green to white (matches number tween duration and easing)
    if activeGradient and whiteGradient then
        local gradientTween = std.Util.TweenColorSequence(
            activeGradient, 
            whiteGradient, 
            animTime/2, 
            Enum.EasingStyle.Sine, -- Match the number tween easing
            Enum.EasingDirection.Out
        )
        table.insert(activeAnimations[labelId], gradientTween)
    end
    
    -- Number tween for the cash value
    local numberTween = std.client.NumberTween(function(value)
        textLabel.Text = prefix .. std.FormatNumber(math.floor(value))
    end, oldValue, newValue, animTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    table.insert(activeAnimations[labelId], numberTween)
    
    -- When number animation completes, shrink back and restore gradient
    numberTween.Completed:Connect(function()
        -- Scale back down
        local scaleDownTween = std.SimpleTween(
            textLabel, 
            "Size", 
            originalSize, 
            DEFAULT_CONFIG.ScaleDownDuration, 
            Enum.EasingStyle.Circular, 
            Enum.EasingDirection.In
        )
        
        -- Tween active gradient back to green reference
        if activeGradient and greenGradient then
            std.Util.TweenColorSequence(
                activeGradient, 
                greenGradient, 
                DEFAULT_CONFIG.ScaleDownDuration, 
                DEFAULT_CONFIG.EasingStyle, 
                DEFAULT_CONFIG.EasingDirection
            )
        end
        
        -- Clean up animation tracker
        activeAnimations[labelId] = nil
    end)
end

--[[
    Bind the animation to a TextLabel that observes a data path
    @param textLabel: The TextLabel to bind
    @param dataController: The DataController instance
    @param dataPath: The data path to observe (e.g., "/Default/Cash")
    @param options: Optional configuration table
]]
function CashGainedAnimation.Bind(textLabel, dataController, dataPath, options)
    options = options or {}
    local prefix = options.Prefix or ""
    
    return dataController:Observe(dataPath, function(value)
        value = value or 0
        local last = textLabel:GetAttribute("LastValue")
        textLabel:SetAttribute("LastValue", value)
        
        if last == nil then
            -- First time, just set the value without animation
            textLabel.Text = prefix .. std.FormatNumber(value)
        else
            CashGainedAnimation.Animate(textLabel, last, value, options)
        end
    end)
end

--[[
    Quick test function - hooks up clicking to trigger the animation
    @param textLabel: The TextLabel to test
]]
function CashGainedAnimation.HookClickTest(textLabel)
    local testValue = 0
    
    -- Make it clickable
    local button = Instance.new("TextButton")
    button.Name = "ClickTestButton"
    button.Size = UDim2.fromScale(1, 1)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = textLabel
    
    button.MouseButton1Click:Connect(function()
        local oldValue = testValue
        local gained = math.random(50, 500)
        testValue = testValue + gained
        CashGainedAnimation.Animate(textLabel, oldValue, testValue, {
            Prefix = "$",
            GetAnimTime = function(gained) 
                return math.clamp(gained / 500, 0.2, 0.6) 
            end,
        })
    end)
    
    print("[CashGainedAnimation] Click test hooked! Click the label to test.")
    return button
end

return CashGainedAnimation

