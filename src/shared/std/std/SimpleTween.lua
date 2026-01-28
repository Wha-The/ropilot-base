--[[ compiled with [luau with classes] compiler v4.6 ]] __author__ = "@NWhut <https://whut.dev/>"	local getclassconstructor do _typeof = typeof; typeof = function(object) local object_type = _typeof(object); if object_type == "table" then local meta = getmetatable(object); if meta then if meta.__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE then object_type = "classinstance" end; if meta.__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR then object_type = "classconstructor" end end end; return object_type end; getclassconstructor = function(object) if typeof(object) == "classinstance" then return getmetatable(object).__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE end end end; local super = function(self) return getmetatable(self).__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS[1] end;wlib = (function() assert = function(condition, message, scope) if not condition then error(message, 2 + (scope or 0)) end end local wlib = {} function wlib.partial(fn, ...) local dargs = table.pack(...) return function(...) local args = {}; for _, darg in ipairs(dargs) do table.insert(args, darg) end; for _, darg in ipairs(table.pack(...)) do table.insert(args, darg) end; return fn(table.unpack(args)) end end function wlib.map(fn, iter) local values = nil if typeof(iter) == "table" then values = table.create(#iter) else values = {} end for idx, value in iter do values[idx] = fn(value) end return values end function wlib.filter(fn, iter) 		local values = {} for idx, value in iter do local condition = fn(value) if condition then 				values[idx] = value end end return values 	end function wlib.bool(x) 		return not not x end return wlib end)() --[[
    Whut <https://whut.dev/>
    Sep 10, 2023
]]
local Tweens = {}
local RunService = game:GetService("RunService")

local TweenService = game:GetService("TweenService")
local Bindable = shared.std.Bindable

local GroupTween do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _GroupTween_ = {};
    function _GroupTween_.__init__(self, listOfTweens) --@wfuscator run_unsandboxed=yes;
        self.tweens = listOfTweens

        self.Completed = self.tweens[1].Completed
        self.AlphaCompleted = self.tweens[1].AlphaCompleted
    end
    function _GroupTween_.Undo(self, ...) --@wfuscator run_unsandboxed=yes;
        for _, tween in pairs(self.tweens) do
            tween:Undo(...)
        end
    end
    function _GroupTween_.Cancel(self) --@wfuscator run_unsandboxed=yes;
        for _, tween in pairs(self.tweens) do
            tween:Cancel()
        end
    end
    function _GroupTween_.ForceComplete(self)
        for _, tween in pairs(self.tweens) do
            tween:ForceComplete()
        end
    end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] GroupTween=setmetatable(_GroupTween_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_GroupTween_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _GroupTween_.__index__ then return _GroupTween_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("GroupTween").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=GroupTween,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor GroupTween>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end
local SimpleTween do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _SimpleTween_ = {};
    _SimpleTween_.GlobalTweens = {}
    function _SimpleTween_.__init__(self, part, property, value, playtime, EasingStyle, EasingDirection) --@wfuscator run_unsandboxed=yes;
        -- defaults
        playtime = playtime or 0.5
        EasingStyle = EasingStyle or Enum.EasingStyle.Sine
        EasingDirection = EasingDirection or Enum.EasingDirection.InOut
        local tweenInfo
        if typeof(playtime) ~= "number" then tweenInfo = playtime end
        ------
        assert(typeof(property) == "string", "Property: string expected, got "..tostring(typeof(property), "! this was formatted from {}"))
        local hasattr, previousValue = pcall(function()
            return part[property]
        end)
        assert(hasattr, "Instance of class "..tostring(part.ClassName, "! this was formatted from {}").." d.oes not have the property: "..tostring(property, "! this was formatted from {}"))

        self.part = part
        self.property = property
        self.playtime = playtime
        self.value = value

        self:_cancelSameProperty()
        self.GlobalTweens[self] = true

        self.tween = TweenService:Create(part, tweenInfo or TweenInfo.new(playtime, EasingStyle, EasingDirection), {[property] = value})
        self:Play()

        self:RegisterCompleted()
        self.HalfwayCompleted = self.AlphaCompleted(0.5)

        if playtime == 0 then
			part[property] = value
            self.Completed:Fire(Enum.PlaybackState.Completed)
		end
    end
    function _SimpleTween_._cancelSameProperty(self) --@wfuscator run_unsandboxed=yes;
        for tween, _ in self.GlobalTweens do
            if tween.part == self.part and tween.property == self.property then
                tween:Cancel()
            end
        end
    end
    function _SimpleTween_.RegisterCompleted(self) --@wfuscator run_unsandboxed=yes;
        self.IsComplete = false
        self.Completed = Bindable(self.tween.Completed)
        self.Completed:AddFireCondition(function()
            return not self.IsComplete
        end)
        self.Completed:Connect(function(state)
            self.IsComplete = state
            self:Destroy()
        end)
        self.Completed:OnConnect(function(signal)
            if self.IsComplete then
                signal.Callback(self.IsComplete)
            end
        end)
    end
    function _SimpleTween_.Play(self) --@wfuscator run_unsandboxed=yes;
        self.tween:Play()
    end
    function _SimpleTween_.Cancel(self) --@wfuscator run_unsandboxed=yes;
        self.tween:Cancel()
    end
    function _SimpleTween_.AlphaCompleted(self, alpha) --@wfuscator run_unsandboxed=yes;
        -- bindable must be created as soon as the tween plays
        local bindable = Bindable()
        local s_stat = os.clock()
        bindable:OnFirstConnect(function()
            local toffset = os.clock() - s_stat
            task.wait((self.playtime * alpha) - toffset)
            bindable:Fire()
            bindable:Destroy()
        end)
        return bindable
    end
    function _SimpleTween_.ForceComplete(self)
        if self.IsComplete then return end
        self.part[self.property] = self.value
        self.tween:Cancel()
        self.Completed:Fire(Enum.PlaybackState.Completed)
    end

    function _SimpleTween_.Undo(self, newProperty, newValue, newPlaytime)
		warn("[SimpleTween:Undo] is no longer supported, there is no replacement for this function.")
        -- return SimpleTween(self.part, newProperty or self.property, newValue or self.previousValue, newPlaytime or self.playtime)
    end

    function _SimpleTween_.Destroy(self) --@wfuscator run_unsandboxed=yes;
        self.tween:Cancel()
        self.tween:Destroy()
        self.GlobalTweens[self] = nil
    end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] SimpleTween=setmetatable(_SimpleTween_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_SimpleTween_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _SimpleTween_.__index__ then return _SimpleTween_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("SimpleTween").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=SimpleTween,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor SimpleTween>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end

local server_constructor
local server_init
do
	local SimpleTweenRequest
	-- @part Instance
	-- @property string
	-- @value any
	-- @playtime number
	-- @EasingStyle Enum.EasingStyle
	-- @EasingDirection Enum.EasingDirection
	server_constructor = function(part, property, value, playtime, EasingStyle, EasingDirection) --@wfuscator run_unsandboxed=yes;
		-- ask all clients to perform the tween
		SimpleTweenRequest:FireAllClients(part, property, value, playtime, EasingStyle, EasingDirection)

		local SimpleTweenMock = {
			Completed = Bindable(),
			AlphaCompleted = function(n)
				local bindable = Bindable()
				task.delay(playtime * n, bindable.Fire, bindable)
				return bindable
			end
		}
		SimpleTweenMock.Completed:OnConnect(function(signal)
			task.delay(playtime, signal.Callback, Enum.PlaybackState.Completed)
		end)
        task.delay(playtime, function()
            part[property] = value
        end)
		return SimpleTweenMock
	end

	server_init = function()
		SimpleTweenRequest = Instance.new("RemoteEvent")
		SimpleTweenRequest.Name = "SimpleTweenRequest"
		SimpleTweenRequest.Parent = script
	end
end

local constructor
local client_init

do
	-- @part Instance
	-- @property string
	-- @value any
	-- @playtime number
	-- @EasingStyle Enum.EasingStyle
	-- @EasingDirection Enum.EasingDirection
	constructor = function(part, property, value, playtime, EasingStyle, EasingDirection) --@wfuscator run_unsandboxed=yes;
		if typeof(part) == "table" then
			local tweens = {}
			for _, gpart in part do
				table.insert(tweens, constructor(gpart, property, value, playtime, EasingStyle, EasingDirection))
			end
			return GroupTween(tweens)
		end
		if typeof(property) == "table" then
			playtime, EasingStyle, EasingDirection = value, playtime, EasingStyle
			local tweens = {}
			for gprop, gvalue in property do
				table.insert(tweens, constructor(part, gprop, gvalue, playtime, EasingStyle, EasingDirection))
			end
			return GroupTween(tweens)
		end

		return SimpleTween(part, property, value, playtime, EasingStyle, EasingDirection)
	end

	client_init = function()
		task.defer(function()
			script:WaitForChild("SimpleTweenRequest").OnClientEvent:Connect(constructor)
		end)
	end
end

local constructor_for_context = constructor
if RunService:IsServer() then
	server_init()
	constructor_for_context = constructor
else
	client_init()
end
return constructor_for_context