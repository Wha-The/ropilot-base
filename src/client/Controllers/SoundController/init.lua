local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local std = shared.std
local Knit = std.Knit

local Sounds = SoundService.Sounds
local SoundBase = require(Knit.Shared.Base.SoundBase)

local SoundController = Knit.CreateController(setmetatable({
    Name = "SoundController"
}, {__index=SoundBase}))

local SoundCollection = require(script.Collection)
local Nothing = require(script.Nothing)
SoundController.SoundCollection = SoundCollection
SoundController.Nothing = Nothing


function SoundController.Beats(sound)
    -- sound: PlayingSound
    assert(typeof(sound) ~= "classinstance" or not sound:IsA("PlayingSound"))
    sound = sound.Sound
    assert(sound:FindFirstChild("Beats"), "Could not find beats for sound!")
    local beats = require(sound.Beats)
    local nextBeat = 1
    local BeatController = {}
    BeatController.OnBeatReached = std.Bindable()
    BeatController.LastBeat = std.Bindable()
    
    local soundPlayStateChangedConnection, heartbeat
    BeatController.OnBeatReached:OnFirstConnect(function()
        local function playStateChanged()
            if heartbeat then
                heartbeat:Destroy()
                heartbeat = nil
            end
            if sound.Playing then
                heartbeat = std.Clock.every(function()
                    if not beats[nextBeat] then return end
                    if sound.TimePosition > beats[nextBeat] then
                        BeatController.OnBeatReached:Fire(nextBeat)
                        nextBeat += 1
                        if not beats[nextBeat] then
                            BeatController.LastBeat:Fire()
                        end
                    end
                end)
            end
       end
        soundPlayStateChangedConnection = sound:GetPropertyChangedSignal("Playing"):Connect(playStateChanged)
        playStateChanged()
        sound.Ended:Connect(function()
            sound.Playing = false
            playStateChanged()
        end)
    end)
    BeatController.OnBeatReached:OnLastDisconnect(function()
        if soundPlayStateChangedConnection then
            soundPlayStateChangedConnection:Disconnect()
            soundPlayStateChangedConnection = nil
        end
        if heartbeat then
            heartbeat:Destroy()
            heartbeat = nil
        end
    end)
    return BeatController
end

local ContentProvider = game:GetService("ContentProvider")
function SoundController:PreloadSound(sound)
    local sound = typeof(sound) == "table" and sound or {sound}
    local load = {}
    for _, s in sound do
        table.insert(load, self:GetSound(s))
    end
    return ContentProvider:PreloadAsync(load)
end

SoundController.BackgroundEnabled = true
SoundController.Background = std.State()
local changeIdx = 0
SoundController.Background:Observe(function(newSound, oldSound)
    -- do
    --     if oldSound then
    --         local lastEqualizer = oldSound:FindFirstChildWhichIsA("EqualizerSoundEffect")
    --         if lastEqualizer then
    --             if newSound and newSound:FindFirstChildWhichIsA("EqualizerSoundEffect") then
    --                 newSound:FindFirstChildWhichIsA("EqualizerSoundEffect"):Destroy()
    --             end
    --             lastEqualizer.Parent = newSound
    --         end
    --     end
    -- end
    changeIdx += 1
    local myid = changeIdx
    if oldSound then
        oldSound.Name = "_"
        local t = std.SimpleTween(oldSound, "Volume", 0, 1, Enum.EasingStyle.Quart)
        t.Completed:Connect(function()
            oldSound:Destroy()
        end)
        t.HalfwayCompleted:Wait()
    end
    if myid ~= changeIdx then return end
    if SoundController.BackgroundEnabled and newSound then
        newSound.SoundGroup = SoundController.Groups.BackgroundSoundtrack.SoundGroup
        newSound:Play()
        local originalVolume = newSound.Volume
        newSound.Volume = 0
        std.SimpleTween(newSound, "Volume", originalVolume, 1, Enum.EasingStyle.Quart)
        SoundController.BackgroundDampened:UpdateEqualizer()
    end
end)

function SoundController:CreateSoundFromTemplate(tmp)
    if typeof(tmp) == "classinstance" then
        return tmp
    end
    local sound = tmp:Clone()
    sound.Name = "Background"
    sound.Parent = SoundService

    if not sound:FindFirstChildWhichIsA("EqualizerSoundEffect") then
        local EqualizerSoundEffect = Instance.new("EqualizerSoundEffect")
        EqualizerSoundEffect.MidGain = 0
        EqualizerSoundEffect.HighGain = 0
        EqualizerSoundEffect.LowGain = 0
        EqualizerSoundEffect.Parent = sound
    end
    
    return sound
end

SoundController.DO_NOT_INSERT_INTO_BACKGROUND_STACK = newproxy(true)

function SoundController:SetBackground(soundTemplate, priority)
    self.BackgroundStack = self.BackgroundStack or {}
    assert(not table.find(self.BackgroundStack, soundTemplate), "Sound is already in the background stack!")
    if priority ~= SoundController.DO_NOT_INSERT_INTO_BACKGROUND_STACK then
        if priority then
            table.insert(self.BackgroundStack, priority, soundTemplate)
        else
            table.insert(self.BackgroundStack, soundTemplate)
        end
    end

    local sound
    local highestIndex = 0
    for i, sound in self.BackgroundStack do
        highestIndex = math.max(highestIndex, i)
    end
    if (not priority and highestIndex == #self.BackgroundStack) or (priority and priority >= highestIndex) then
        if typeof(soundTemplate) == "classinstance" then
            soundTemplate:Play(self, self.Background)
        else
            sound = self:CreateSoundFromTemplate(soundTemplate)
            self.Background:Update(sound)
        end
    end

    return {
        SoundObject = sound,
        SoundTemplate = soundTemplate,
        Destroy = function()
            local index
            for _index, _sound in self.BackgroundStack do
                if _sound == soundTemplate then
                    index = _index
                    break
                end
            end
            if not index then
                warn(`Can't find soundTemplate={soundTemplate} in BackgroundStack!`)
                return
            end

            local highestIndex = 0
            for i, sound in self.BackgroundStack do
                highestIndex = math.max(highestIndex, i)
            end

            local was_top_item = index == highestIndex
            self.BackgroundStack[index] = nil

            -- Handle cleanup
            if typeof(soundTemplate) == "classinstance" then
                soundTemplate:Destroy()
            elseif sound and sound.Parent then
                sound:Destroy()
            end

            -- Update to next sound if this was the top item
            if was_top_item and #self.BackgroundStack > 0 then
                local highestIndex = 0
                for i, sound in self.BackgroundStack do
                    highestIndex = math.max(highestIndex, i)
                end

                local nextTemplate = self.BackgroundStack[highestIndex]
                if typeof(nextTemplate) == "classinstance" then
                    nextTemplate:Play(self, self.Background)
                else
                    local nextSound = self:CreateSoundFromTemplate(nextTemplate)
                    self.Background:Update(nextSound)
                end
            elseif was_top_item then
                self.Background:Update()
            end
        end
    }
end

function SoundController:SetBackgroundEnabled(enabled)
    std.SimpleTween(SoundController.Groups.BackgroundSoundtrack.SoundGroup, "Volume", enabled and 1.5 or 0, 1, Enum.EasingStyle.Quart)
end

function SoundController:AddRegion(state, regions)
    local parts = {}
    local scan = regions:GetDescendants()
    table.insert(scan, regions)
    for _, part in scan do
        if part:IsA("BasePart") then
            table.insert(parts, part)
        end
    end
    return std.Clock.every(.1, function()
        local primaryPart = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character.PrimaryPart
        if not primaryPart then return end

        local isTouchingRegion = false
        for _, part in parts do
            if std.Util.IsTouching(primaryPart.Position, part) then
                isTouchingRegion = true
                break
            end
        end
        state:Update(isTouchingRegion)
    end)
end

function SoundController:KnitStart()
    CollectionService:GetInstanceAddedSignal("SoundWithExceptList"):Connect(function(sound)
        if sound:GetAttribute("Except_"..game.Players.LocalPlayer.UserId) then
            task.defer(function()
                task.wait()
                Debris:AddItem(sound, 0)
            end)
        end
    end)
    
    self.BackgroundDampened = {
        profiles = {},
        UpdateEqualizer = function()
            local Volume = 0
            local MidGain = 0
            local HighGain = 0

            if #self.BackgroundDampened.profiles > 0 then
                Volume = 0.15
                MidGain = -20
                HighGain = -35
            end
            for _, profile in self.BackgroundDampened.profiles do
                if typeof(profile) == "table" then
                    Volume = math.min(Volume, profile.Volume or 0.15)
                    MidGain = math.min(MidGain, profile.MidGain or -20)
                    HighGain = math.min(HighGain, profile.HighGain or -35)
                end
            end

            local sound = self.Background:Get()
            if not sound then return end
            local equalizer = sound:FindFirstChildWhichIsA("EqualizerSoundEffect")
            if equalizer then
                std.SimpleTween(equalizer, "MidGain", MidGain, .25, Enum.EasingStyle.Quart, MidGain == 0 and Enum.EasingDirection.Out or Enum.EasingDirection.In)
                std.SimpleTween(equalizer, "HighGain", HighGain, .25, Enum.EasingStyle.Quart, HighGain == 0 and Enum.EasingDirection.Out or Enum.EasingDirection.In)
            end
        end,
        Dampen = function(_, state)
            table.insert(self.BackgroundDampened.profiles, state or true)
            
            self.BackgroundDampened:UpdateEqualizer()
            -- if #self.BackgroundDampened.profiles == 1 then
            --     -- updateDampened(true)
            --     self.BackgroundDampened:UpdateEqualizer()
            -- end
        end,
        Undampen = function(_, state)
            local index
            for i = #self.BackgroundDampened.profiles, 1, -1 do
                if self.BackgroundDampened.profiles[i] == (state or true) then
                    index = i
                    break
                end
            end
            table.remove(self.BackgroundDampened.profiles, index)
            -- update equalizer
            self.BackgroundDampened:UpdateEqualizer()
            -- if #self.BackgroundDampened.profiles == 0 then
            --     -- updateDampened(false)
            --     self.BackgroundDampened:UpdateEqualizer()
            -- end
        end
    }
    game:GetService("UserInputService").WindowFocusReleased:Connect(function()
        -- dampen sound
        self.BackgroundDampened:Dampen()
    end)
    game:GetService("UserInputService").WindowFocused:Connect(function()
        self.BackgroundDampened:Undampen()
    end)


    local DataController = Knit.GetController("DataController")
    DataController:Observe("/System/Settings/Music", function(value)
        if value == nil then value = true end
        self:SetBackgroundEnabled(value)
    end)

    local soundtracks = SoundService.Soundtracks:GetChildren()
    std.random.shuffle(soundtracks)
    task.defer(function()
        while true do
            for _, soundtrack in soundtracks do
                local obj = self:SetBackground(soundtrack)
                obj.SoundObject.Ended:Wait()
                obj:Destroy()
                task.wait(5)
            end
        end
    end)
end

-- help with prediction
if false then
    -- Play a sound
    function SoundController:PlaySound(soundName)
        return {
            Group = function(group: SoundGroup) end,
            Origin = function(origin: Instance) end,
            Speed = function(speed: number) end,
            Volume = function(volume: number) end,
            Pitch = function(pitch: number) end,
            Seek = function(time: number) end,
            FadeIn = function(duration: number) end,
            FadeOut = function(duration: number) end,
            Looped = function(looped: boolean) end,
            Destroy = function() end
        }
    end
end

return SoundController