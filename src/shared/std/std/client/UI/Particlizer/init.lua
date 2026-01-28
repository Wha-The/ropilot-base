local std = shared.std
local ParticleEngine = require(script.ParticleEngine)
local Particlizer = {}

function Particlizer:Run(GuiElement, properties)
    -- rate = particles per second
    if properties.Rate > 60 then
        print("rate > 60 is probably not a good idea")
    end
    local persistantFrames = properties.PersistantFrames or {50, 100}
    return std.Clock.every(1/properties.Rate, function(dt)
        if properties.Condition and not properties.Condition() then
            return
        end
        local image = Instance.new("ImageLabel")
        image.ZIndex = 10
        image.Size = std.Util.UDim2Multiply(UDim2.new(0.025, 0, 0.025, 0), properties.SizeMultiplier or 1)
        image.Position = UDim2.fromOffset(std.random.int(GuiElement.AbsolutePosition.X, GuiElement.AbsolutePosition.X + GuiElement.AbsoluteSize.X), std.random.int(GuiElement.AbsolutePosition.Y, GuiElement.AbsolutePosition.Y + GuiElement.AbsoluteSize.Y))
        image.Rotation = properties.HasRotation == false and 0 or std.random.int(-35, 35)
        image.AnchorPoint = Vector2.new(0.5,0.5)
        image.SizeConstraint = Enum.SizeConstraint.RelativeYY
        image.BorderSizePixel = 0
        image.ImageColor3 = properties.Color or Color3.new(1, 1, 1)
        image.ScaleType = Enum.ScaleType.Fit
        image.Image = properties.Image
        image.BackgroundTransparency = 1

        ParticleEngine.createParticle(
            image, -- ImageLabel object
            std.random.int(persistantFrames[1], persistantFrames[2]), --the amount of frames the particle will exist for
            properties.InitialVelocity or UDim2.new(std.random.float(-0.09375,0.09375),0,std.random.float(-0.09375,0.09375),0), --the initial velocity of the part
            properties.RotationSpeed or std.random.float(.15, .25) * std.random.choice({1, -1}), --The speed at which the part will rotate
            UDim2.new(0,0,0,0),
            UDim2.new(0,0,0,0),
            0.025,
            0
        )
    end)
end

function Particlizer:Load()

end

return Particlizer