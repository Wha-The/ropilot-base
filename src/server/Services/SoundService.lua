local std = shared.std
local CollectionService = game:GetService("CollectionService")
local Knit = std.Knit
local SoundBase = require(Knit.Shared.Base.SoundBase)
local SoundService = Knit.CreateService(setmetatable({
    Name = "SoundService",
    Client = {}
}, {__index=SoundBase}))

function SoundService:PlaySoundExcept(sound, exceptList)
    sound = self:GetSound(sound)
    local clonedSound = sound:Clone()
    if exceptList then
        local flagged
        for _, except in typeof(exceptList) == "table" and exceptList or {exceptList} do
            assert(typeof(except) == "Instance" and except:IsA("Player"), "Invalid exceptList")
            clonedSound:SetAttribute("Except_"..except.UserId, true)
            flagged = true
        end
        if flagged then
            CollectionService:AddTag(clonedSound, "SoundWithExceptList")
        end
    end
    clonedSound.Parent = sound.Parent
    sound = self:PlaySound(clonedSound, {DoNotClone = true})
    return sound
end

function SoundService:PreloadSound(...)
    return -- can't preload sounds on the server
end

return SoundService