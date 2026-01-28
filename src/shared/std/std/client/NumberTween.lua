local RunService = game:GetService("RunService")
local std = shared.std

local ongoingTweens = {}

local function NumberTween(callback, start, finish, duration, easingStyle, easingDirection, uniqueKey)
	-- assert(RunService:IsClient(), "NumberTween can only be used on the client")
	assert(typeof(callback) == "function", "callback must be a function")
	assert(typeof(start) == "number", "start must be a number")
	assert(typeof(finish) == "number", "finish must be a number")
	assert(typeof(duration) == "number", "duration must be a number")
	assert(not easingStyle or (typeof(easingStyle) == "EnumItem"), "easingStyle must be an EnumItem")
	assert(not easingDirection or (typeof(easingDirection) == "EnumItem"), "easingDirection must be an EnumItem")

	-- can use TweenService:GetValue instead

	if uniqueKey then
		if ongoingTweens[uniqueKey] then
			ongoingTweens[uniqueKey]:Destroy()
		end
	end

	local NumberValue = Instance.new("NumberValue")
	NumberValue.Value = start
	NumberValue.Changed:Connect(function()
		callback(NumberValue.Value)
	end)
	
	local tween = shared.std.SimpleTween(NumberValue, "Value", finish, duration, easingStyle, easingDirection)
	if uniqueKey then
		ongoingTweens[uniqueKey] = tween
	end
	tween.Completed:Connect(function()
		task.wait()
		NumberValue:Destroy()
		if uniqueKey then
			ongoingTweens[uniqueKey] = nil
		end
	end)
	return tween
end

return NumberTween