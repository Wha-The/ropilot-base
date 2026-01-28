local Knit = require(game:GetService("ReplicatedStorage").Packages:WaitForChild("Knit"))
local AnimationBase = {}
AnimationBase.Namespace = {
    -- put animations for your game here!
    -- animationName = id,
    -- example: DownedIdle = 91422893584973,

    
}
AnimationBase.Timings = {
	-- PogoJump = 1.1399999856948853,
}

function AnimationBase:LoadAnimation(anim, character)
    character = character or (game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait())
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    assert(humanoid, "[AnimationBase] Can't find humanoid within character!")

    local a
    -- If anim is an Animation instance, use it directly
    if typeof(anim) == "Instance" and anim:IsA("Animation") then
        a = anim
    else
        local id = typeof(anim) == "number" and anim or self.Namespace[anim]
        assert(id, `Can't find animation {anim}`)
        a = Instance.new("Animation")
        if typeof(id) == "string" then
            a.AnimationId = id
        else
            a.AnimationId = "rbxassetid://"..id
        end
    end
    if self.PreloadAnimation then task.defer(self.PreloadAnimation, self, a) end
    
    local Animator = humanoid:FindFirstChildWhichIsA("Animator")
    if not Animator then
        Animator = Instance.new("Animator")
        Animator.Parent = humanoid
    end
    local track = Animator:LoadAnimation(a)

    if not self.LoadedTracks[character] then self.LoadedTracks[character] = {} end
    -- Use AnimationId for Animation instances as the key, otherwise use the original anim parameter
    local trackKey = (typeof(anim) == "Instance" and anim:IsA("Animation")) and anim.AnimationId or anim
    self.LoadedTracks[character][trackKey] = track
    local object = {}
    function object:Play(properties)
        self = AnimationBase
        return self:PlayAnimation(anim, character, properties)
    end
    function object:Destroy()
        self = AnimationBase
        track:Destroy()
        if self.LoadedTracks[character] and self.LoadedTracks[character][trackKey] then
            self.LoadedTracks[character][trackKey] = nil
            if not next(self.LoadedTracks[character]) then
                self.LoadedTracks[character] = nil
            end
        end
    end

    return object
end

function AnimationBase:PlayAnimation(anim, character, properties)
    character = character or (game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait())
    properties = properties or {}
    
    -- Determine the cache key for lookup
    local cacheKey = (typeof(anim) == "Instance" and anim:IsA("Animation")) and anim.AnimationId or anim
    local track = self.LoadedTracks[character] and self.LoadedTracks[character][cacheKey]
    
    -- If anim is an Animation instance and no cached track exists, handle it directly
    if typeof(anim) == "Instance" and anim:IsA("Animation") and not track then
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        assert(humanoid, "[AnimationBase] Can't find humanoid within character!")
        
        local Animator = humanoid:FindFirstChildWhichIsA("Animator")
        if not Animator then
            Animator = Instance.new("Animator")
            Animator.Parent = humanoid
        end
        track = Animator:LoadAnimation(anim)
        
        if properties.Looped then
            track.Looped = true
        end
        track:Play()

        track.Ended:Once(function()
            track:Destroy()
        end)

        if properties.Speed then
            track:AdjustSpeed(properties.Speed)
        end
        
        track:SetAttribute("Name", anim.AnimationId)
        return track
    end
    if not track then
        warn(`Animation {anim} on {character:GetFullName()} is being hotloaded! This may cause performance issues! Please use AnimationBase:LoadAnimation() first!`)
        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        assert(humanoid, "[AnimationBase] Can't find humanoid within character!")

        local id = typeof(anim) == "number" and anim or self.Namespace[anim]
        assert(id, `Can't find animation {anim}`)
        local a = Instance.new("Animation")
        if typeof(id) == "string" then
			a.AnimationId = id
		else
			a.AnimationId = "rbxassetid://"..id
		end
        
        local Animator = humanoid:FindFirstChildWhichIsA("Animator")
        if not Animator then
            Animator = Instance.new("Animator")
            Animator.Parent = humanoid
        end
        track = Animator:LoadAnimation(a)
    end
    if properties.Looped then
        track.Looped = true
    end

    track:Play()
    
    track.Ended:Once(function()
        track:Destroy()
    end)
    
    if properties.Speed then
        track:AdjustSpeed(properties.Speed)
    end
    track:SetAttribute("Name", cacheKey)
    return track
end

AnimationBase.LoadedTracks = {}

return AnimationBase