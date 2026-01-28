local std = shared.std
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local MobileDetect = {}


function MobileDetect:Detect()
    return self.IsMobile
end

function MobileDetect:DetectNoIpad()
    return self.IsMobileNoIpad
end

function MobileDetect:_Observe(callback)
    callback(self.IsMobile)
    return self.DeviceChanged:Connect(function()
        return callback(self.IsMobile)
    end)
end
function MobileDetect:Observe(callback)
    if not self.Started then
        return self:QueueUntilStart(self._Observe, self, callback)
    end
    return self:_Observe(callback)
end

function MobileDetect:ObserveNoIpad(callback)
    -- ipad is classified as PC
    callback(self.IsMobileNoIpad)
    return self.DeviceChangedNoIpad:Connect(callback)
end

function MobileDetect:QueueUntilStart(callback, ...)
    while not self.Started do task.wait() end
    return callback(...)
end


if RunService:IsClient() then
    MobileDetect.IsMobile = not UserInputService.KeyboardEnabled and UserInputService.TouchEnabled
    local screen_ratio = std.MainGui.AbsoluteSize.X / std.MainGui.AbsoluteSize.Y
    local ipad = MobileDetect.IsMobile and screen_ratio < 1.6
    MobileDetect.IsMobileNoIpad = MobileDetect.IsMobile and not ipad


    local DeviceChangedNoIpad = Instance.new("BoolValue")
    MobileDetect.DeviceChangedNoIpad = DeviceChangedNoIpad:GetPropertyChangedSignal("Value")
    DeviceChangedNoIpad.Value = MobileDetect.IsMobileNoIpad

    local DeviceChanged = Instance.new("BoolValue")
    MobileDetect.DeviceChanged = DeviceChanged:GetPropertyChangedSignal("Value")
    DeviceChanged.Value = MobileDetect.IsMobile
    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        MobileDetect.IsMobile = input.UserInputType == Enum.UserInputType.Touch
        DeviceChanged.Value = MobileDetect.IsMobile

        local screen_ratio = std.MainGui.AbsoluteSize.X / std.MainGui.AbsoluteSize.Y
        local ipad = MobileDetect.IsMobile and screen_ratio < 1.6
        MobileDetect.IsMobileNoIpad = MobileDetect.IsMobile and not ipad
        DeviceChangedNoIpad.Value = MobileDetect.IsMobileNoIpad
    end)

    MobileDetect.Started = true
else
    error("MobileDetect required from server...?")
end

return MobileDetect