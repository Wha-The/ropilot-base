--[[ compiled with [luau with classes] compiler v4.6 ]] __author__ = "@NWhut <https://whut.dev/>"	local getclassconstructor do _typeof = typeof; typeof = function(object) local object_type = _typeof(object); if object_type == "table" then local meta = getmetatable(object); if meta then if meta.__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE then object_type = "classinstance" end; if meta.__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR then object_type = "classconstructor" end end end; return object_type end; getclassconstructor = function(object) if typeof(object) == "classinstance" then return getmetatable(object).__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE end end end; local super = function(self) return getmetatable(self).__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS[1] end;wlib = (function() assert = function(condition, message, scope) if not condition then error(message, 2 + (scope or 0)) end end local wlib = {} function wlib.partial(fn, ...) local dargs = table.pack(...) return function(...) local args = {}; for _, darg in ipairs(dargs) do table.insert(args, darg) end; for _, darg in ipairs(table.pack(...)) do table.insert(args, darg) end; return fn(table.unpack(args)) end end function wlib.map(fn, iter) local values = nil if typeof(iter) == "table" then values = table.create(#iter) else values = {} end for idx, value in iter do values[idx] = fn(value) end return values end function wlib.filter(fn, iter) 		local values = {} for idx, value in iter do local condition = fn(value) if condition then 				values[idx] = value end end return values 	end function wlib.bool(x) 		return not not x end return wlib end)() local std = shared.std
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local SoundBase = {}

local Sounds = SoundService.Sounds

local SoundGroup do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _SoundGroup_ = {};
    function _SoundGroup_.__init__(self, name)
        self.Name = name
        if RunService:IsClient() then
            self.SoundGroup = SoundService:WaitForChild(name)
        else
            self.SoundGroup = Instance.new("SoundGroup")
            self.SoundGroup.Name = name
            self.SoundGroup.Parent = SoundService
            self.SoundGroup.Volume = 1.5
        end
    end
    function _SoundGroup_.SoundAdded(self, sound)
        sound.Sound.SoundGroup = self.SoundGroup
    end
    function _SoundGroup_.AddSoundRaw(self, sound)
        sound.SoundGroup = self.SoundGroup
    end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] SoundGroup=setmetatable(_SoundGroup_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_SoundGroup_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _SoundGroup_.__index__ then return _SoundGroup_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("SoundGroup").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=SoundGroup,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor SoundGroup>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end
SoundBase.Groups = {
    Interface = SoundGroup("Interface"),
    Environment = SoundGroup("Environment"),
    Ambient = SoundGroup("Ambient"),
    Mechanics = SoundGroup("Mechanics"),

    BackgroundSoundtrack = SoundGroup("BackgroundSoundtrack"),
}

local PlayingSound do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _PlayingSound_ = {};
    function _PlayingSound_.__init__(self, soundOriginal, options)
        options = options or {}

        self.Sound = options.DoNotClone and soundOriginal or soundOriginal:Clone()
        self.Sound.Parent = soundOriginal.Parent
        if self.Sound.Parent ~= SoundService and self.Sound:IsDescendantOf(SoundService) then
            self.Sound.Parent = SoundService
        end

        self:Group(SoundBase.Groups.Interface)

        task.defer(function() -- this pushes this callback to the end of the stack, so if there are any subsequence :Origin calls, it gets parented *first* before it plays.
            self.Sound:Play()
            self.Sound.Ended:Once(function()
                self.Sound:Destroy()
            end)
        end)
        self.Tweening = false
    end
    function _PlayingSound_.Group(self, group)
        self.CurrentGroup = group
        group:SoundAdded(self)
        return self
    end
    function _PlayingSound_.Origin(self, origin)
        self.Sound.Parent = origin or SoundService
        return self
    end
    function _PlayingSound_.Speed(self, speed)
        self.Sound.PlaybackSpeed = speed
        return self
    end
    function _PlayingSound_.Volume(self, volume)
        self.Sound.Volume = volume
        return self
    end
    function _PlayingSound_.Pitch(self, pitch)
        local pitchShiftSoundEffect = self.Sound:FindFirstChildWhichIsA("PitchShiftSoundEffect")
        if not pitchShiftSoundEffect then
            pitchShiftSoundEffect = Instance.new("PitchShiftSoundEffect")
            pitchShiftSoundEffect.Parent = self.Sound
        end
        pitchShiftSoundEffect.Octave = pitch
        return self
    end
    function _PlayingSound_.Seek(self, time)
        self.Sound.TimePosition = time
        return self
    end
    function _PlayingSound_.Looped(self, looped)
        self.Sound.Looped = looped
        return self
    end
    function _PlayingSound_.FadeIn(self, duration)
        local original = self.Sound.Volume
        self.Sound.Volume = 0
        self.Tweening = true
        std.SimpleTween(self.Sound, "Volume", original, duration or 0.3, Enum.EasingStyle.Quart).Completed:Connect(function()
            self.Tweening = false
        end)
        return self
    end
    function _PlayingSound_.FadeOut(self, duration)
        self.Tweening = true
        std.SimpleTween(self.Sound, "Volume", 0, duration or 0.3, Enum.EasingStyle.Quart).Completed:Connect(function()
            self.Tweening = false
        end)
        return self
    end
    function _PlayingSound_.SeekToRandom(self)
        self.Sound.TimePosition = math.random() * self.Sound.TimeLength
        return self
    end
    function _PlayingSound_.Destroy(self)
        self.Sound:Destroy()
    end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] PlayingSound=setmetatable(_PlayingSound_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_PlayingSound_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _PlayingSound_.__index__ then return _PlayingSound_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("PlayingSound").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=PlayingSound,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor PlayingSound>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end

local assertwarn = function(condition, message)
    if not condition then
        warn(message)
        return nil;
    end
    return condition
end

function SoundBase:GetSound(sound)
    if typeof(sound) == "string" then
        local soundInstance = std.parsePath(sound, function(x, y)
            return x and x:FindFirstChild(y)
        end)(Sounds)
        if not assertwarn(sound, "[SoundBase]: The requested sound could not be found: "..sound) then return end
        
        return soundInstance
    end
    return sound
end

function SoundBase:PlaySound(sound, options)
    local sound = self:GetSound(sound)
    if not sound then return PlayingSound(Instance.new("Sound"), options) end
    return PlayingSound(sound, options)
end

return SoundBase