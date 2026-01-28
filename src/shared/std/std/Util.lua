local std = shared.std
local Util = {}
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

function Util.GetUniqueId(t)
	-- local checkFunction = t
	-- if typeof(checkFunction) == "table" then
	-- 	checkFunction = function(x) return t[x] ~= nil end
	-- end
	-- local uuid
	-- while not uuid or checkFunction(uuid) do
	-- 	uuid = HttpService:GenerateGUID(false)
	-- end
	-- return uuid
    return HttpService:GenerateGUID(false)
end

function Util.InsertWithUniqueId(t, element)
    local uuid = Util.GetUniqueId(t)
    t[uuid] = element
    return uuid
end

function Util:CopyTable(original)
    local copy = {}
    for k, v in original do
        local result
        if typeof(v) == "table" then
            result = self:CopyTable(v)
        end
        copy[k] = result or v
    end
    return copy
end
function Util.TableCount(n);
    local count = 0
    for _, _ in n do
        count += 1
    end
    return count
end
function Util.ZipTable(...);
    -- t1: {5, 4, 3, 2, 1}
    -- t2: {1, 2, 3, 4, 5}
    -- return: {{5, 1}, {4, 2}, {3, 3}, {2, 4}, {1, 5}}
    -- Table length must be the same
    local ts = {...}
    assert(#ts > 1, "Cannot merge with only 1 or fewer table(s)", 2)
    local t1_len = #ts[1]
    for _, t in ts do
        assert(t1_len == #t, "Table length of all tables must be the same.", 2)
    end
    local r = {}
    for index = 1, t1_len do
        local s = {}
        for _, t in ts do
            table.insert(s, t[index])
        end
        table.insert(r, s)
    end
    return r
end
function Util.MergeTables(...);
    -- DICTIONARY ONLY
    local ts = {...}
    local r = {}
    for _, t in ts do
        for i, v in t do
            r[i] = v
        end
    end
    return r
end

function Util.Touched(part)
    local event = std.Bindable()
    local signal = part.Touched:Connect(function(p)
        if RunService:IsServer() then
            local m = p:FindFirstAncestorWhichIsA("Model")
            local player = game.Players:GetPlayerFromCharacter(m)
            if player then
                event:Fire(player)
            end
        else
            if p:IsDescendantOf(game.Players.LocalPlayer.Character) then
                event:Fire()
            end
        end
    end)
    event.OnLastDisconnect(function()
        signal:Disconnect()
    end)
    return event
end

function Util.UDim2Multiply(udim2, factor)
    local xs, xo, ys, yo = factor, factor, factor, factor
    if typeof(factor) == "UDim2" then
        xs, xo, ys, yo = factor.X.Scale, factor.X.Offset, factor.Y.Scale, factor.Y.Offset
    end
    return UDim2.new(udim2.X.Scale * xs, udim2.X.Offset * xo, udim2.Y.Scale * ys, udim2.Y.Offset * yo)
end

function Util.Color3Multiply(color3, factor)
    local factorr, factorg, factorb = factor, factor, factor
    if typeof(factor) == "Color3" then
        factorr, factorg, factorb = factor.R, factor.G, factor.B
    end
    return Color3.new(color3.R * factorr, color3.G * factorg, color3.B * factorb)
end

function Util.ManualToolWeld(character, tool)
    local Weld = Instance.new("Weld")
    Weld.C0 = character.RightHand.RightGripAttachment.CFrame
    Weld.C1 = tool.Grip
    Weld.Part0 = character.RightHand
    Weld.Part1 = tool.Handle

    Weld.Name = "ToolWeld"
    Weld.Parent = tool
end

function Util.SigFig(num: number, figures: number)
	if num == 0 then return 0 end
    local x = figures - math.ceil(math.log10(math.abs(num)))
	local roundNearest = math.pow(10, x)
    return math.round(num * roundNearest) / roundNearest
end

local ContentProvider = game:GetService("ContentProvider")
local UserInputService = game:GetService("UserInputService")
function Util.Preload(item)
    if typeof(item) == "table" then
        for _, v in pairs(item) do
            Util.Preload(v)
        end
        return
    end

    return task.defer(function()
        ContentProvider:PreloadAsync({item})
    end)
end

function Util.WaitUntilStable(func, interval)
    local call_n = 0
    return function()
        call_n += 1
        local my_call = call_n
        task.delay(interval, function()
            if my_call == call_n then
                func()
            end
        end)
    end
end
function Util.Reversed(l)
    return coroutine.wrap(function()
        local i = #l
        while i >= 1 do
            coroutine.yield(i, l[i])
            i -= 1
        end
    end)
end

function Util.InputEventAll()
    local UserInputService = game:GetService("UserInputService")
    local bindable = std.Bindable()
    bindable.Sources = {
        UserInputService.InputBegan:Connect(wlib.partial(bindable.Fire, bindable, Enum.UserInputState.Begin)),
        UserInputService.InputChanged:Connect(wlib.partial(bindable.Fire, bindable, Enum.UserInputState.Change)),
        UserInputService.InputEnded:Connect(wlib.partial(bindable.Fire, bindable, Enum.UserInputState.End)),
    }
    bindable:OnDestroy(function()
        for _, source in bindable.Sources do
            source:Disconnect()
        end
    end)
    return bindable
end

function Util:EmitParticles(instance)
    local yieldTime = 0
    local scan
    if typeof(instance) == "Instance" then
        scan = instance:GetDescendants()
        table.insert(scan, instance)
    else
        scan = {}
        for _, child in instance do
            for _, desc in child:GetDescendants() do
                table.insert(scan, desc)
            end
            table.insert(scan, child)
        end
    end
    for _, particle in scan do
        if particle:IsA("ParticleEmitter") then
            yieldTime = math.max(yieldTime, particle.Lifetime.Max)
            local function co()
                if particle:GetAttribute("EmitCount") then
                    particle:Emit(particle:GetAttribute("EmitCount"))
                end
                if particle:GetAttribute("EmitDuration") then
                    particle.Enabled = true
                    
                    task.delay(particle:GetAttribute("EmitDuration"), function()
                        local original = particle:GetAttribute("OriginalRate") or particle.Rate
                        particle:SetAttribute("OriginalRate", original)
                        particle.Rate = 0
                        task.delay(particle.Lifetime.Max, function()
                            particle.Rate = original
                            particle.Enabled = false
                        end)
                    end)
                end
            end
            if particle:GetAttribute("EmitDelay") and particle:GetAttribute("EmitDelay") > 0 then
                task.delay(particle:GetAttribute("EmitDelay"), co)
            else
                co()
            end
        end
    end

    return yieldTime
end

function Util:GetGuiInset(screengui)
    -- local sg = Instance.new("ScreenGui", game.Players.LocalPlayer.PlayerGui)
    -- sg.Enabled = false
    
    -- local frame = Instance.new("Frame", sg)
    
    -- local sg2 = sg:Clone()
    
    -- sg.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension
    -- sg.ScreenInsets = Enum.ScreenInsets.None
    
    -- local vect = sg2.AbsolutePosition - sg.AbsolutePosition
    -- sg:Destroy()
    -- sg2:Destroy()

    if screengui then
        if screengui.ScreenInsets == Enum.ScreenInsets.None then
            return Vector2.zero
        end
    end
    return GuiService:GetGuiInset()
end

function Util:GetHardwareSafeAreaInsets(dontModifyForLandscape)
    -- dontModifyForLandscape: this is to compensate for a bug on roblox where the safe area is not correct for landscape left/right
    local playerGui = game.Players.LocalPlayer.PlayerGui
    assert(playerGui)
    
    local fullscreenGui = playerGui:FindFirstChild("_FullscreenTestGui")
    if not fullscreenGui then
        fullscreenGui = Instance.new("ScreenGui")
        fullscreenGui.Name = "_FullscreenTestGui"
        fullscreenGui.Parent = playerGui
        fullscreenGui.ScreenInsets = Enum.ScreenInsets.None
    end
    
    local deviceGui = playerGui:FindFirstChild("_DeviceTestGui")
    if not deviceGui then
        deviceGui = Instance.new("ScreenGui")
        deviceGui.Name = "_DeviceTestGui"
        deviceGui.Parent = playerGui
        deviceGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
    end
    
    local tlInset = deviceGui.AbsolutePosition - fullscreenGui.AbsolutePosition
    local brInset = fullscreenGui.AbsolutePosition + fullscreenGui.AbsoluteSize
                    - (deviceGui.AbsolutePosition + deviceGui.AbsoluteSize)
    local result = {left = tlInset.X, top = tlInset.Y, right = brInset.X, bottom = brInset.Y}

    if not dontModifyForLandscape and game.Players.LocalPlayer.PlayerGui.CurrentScreenOrientation == Enum.ScreenOrientation.LandscapeLeft then
        result.left -= 49
    end
    if not dontModifyForLandscape and game.Players.LocalPlayer.PlayerGui.CurrentScreenOrientation == Enum.ScreenOrientation.LandscapeRight then
        result.right -= 49
    end
		
    return result
end

function Util.ScaleNumberSequence(numberSequence, scale)
	local newKeypoints = {}
	for _, keypoint in numberSequence.Keypoints do
		table.insert(newKeypoints, NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * scale, keypoint.Envelope * scale))
	end
	return NumberSequence.new(newKeypoints)
end

function Util.ScaleParticle(emitter: ParticleEmitter, scale: number)
    emitter.Size = Util.ScaleNumberSequence(emitter.Size, scale)
    emitter.Speed = NumberRange.new(emitter.Speed.Min * scale, emitter.Speed.Max * scale)
end
function Util.ScaleParticles(instance, scale)
    for _, particle in instance:GetDescendants() do
        if particle:IsA("ParticleEmitter") then
            Util.ScaleParticle(particle, scale)
        end
    end
end

function Util.IsTouching(point, part)
    local X, Y, Z = "X", "Y", "Z" -- faster lookup with wfuscator
	local relative = part.CFrame:PointToObjectSpace(point)
	local halfSize = part.Size / 2
	return (relative[X] >= -halfSize[X] and relative[X] <= halfSize[X])
		and (relative[Y] >= -halfSize[Y] and relative[Y] <= halfSize[Y])
		and (relative[Z] >= -halfSize[Z] and relative[Z] <= halfSize[Z])
end

function Util.ClosestPointOnPart(Part, Point)
	local Transform = Part.CFrame:pointToObjectSpace(Point) -- Transform into local space
	local HalfSize = Part.Size * 0.5
	return Part.CFrame * Vector3.new( -- Clamp & transform into world space
		math.clamp(Transform.x, -HalfSize.x, HalfSize.x),
		math.clamp(Transform.y, -HalfSize.y, HalfSize.y),
		math.clamp(Transform.z, -HalfSize.z, HalfSize.z)
	)
end


function Util.XZLookAt(origin, target)
    return CFrame.new(origin, target * Vector3.new(1, 0, 1) + origin * Vector3.new(0, 1, 0))
end

function Util:GetMouseWorldLocation(options)
    options = options or {}
    local location = UserInputService:GetMouseLocation()
    if std.client.MobileDetect:Detect() and options.mobile then
        location = options.mobile()
        -- convert to vector2 from udim2
        local size = std.MainGui.AbsoluteSize
        location = Vector2.new(location.X * size.X, location.Y * size.Y)
    end
    location -= GuiService:GetGuiInset()
    local ray = workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)
    local raycastParams
    if options.raycastParams then
        raycastParams = options.raycastParams
    else
        raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {game.Players.LocalPlayer.Character}
    end
    local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)

    return result and result.Position or (ray.Origin + ray.Direction * 100)
end

function Util.Rainbow(partOrFunction) -- call to make anything rainbow @whut
    local t = 0
    return std.Clock.every(function(dt)
        t += dt
        local color = Color3.fromHSV((t * .3) % 1, 1, 1)
        if typeof(partOrFunction) == "function" then
            partOrFunction(color, dt)
        else
            partOrFunction.Color = color
        end
    end)
end

return Util