--[[ compiled with [luau with classes] compiler v4.6 ]] __author__ = "@NWhut <https://whut.dev/>"	local getclassconstructor do _typeof = typeof; typeof = function(object) local object_type = _typeof(object); if object_type == "table" then local meta = getmetatable(object); if meta then if meta.__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE then object_type = "classinstance" end; if meta.__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR then object_type = "classconstructor" end end end; return object_type end; getclassconstructor = function(object) if typeof(object) == "classinstance" then return getmetatable(object).__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE end end end; local super = function(self) return getmetatable(self).__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS[1] end;wlib = (function() assert = function(condition, message, scope) if not condition then error(message, 2 + (scope or 0)) end end local wlib = {} function wlib.partial(fn, ...) local dargs = table.pack(...) return function(...) local args = {}; for _, darg in ipairs(dargs) do table.insert(args, darg) end; for _, darg in ipairs(table.pack(...)) do table.insert(args, darg) end; return fn(table.unpack(args)) end end function wlib.map(fn, iter) local values = nil if typeof(iter) == "table" then values = table.create(#iter) else values = {} end for idx, value in iter do values[idx] = fn(value) end return values end function wlib.filter(fn, iter) 		local values = {} for idx, value in iter do local condition = fn(value) if condition then 				values[idx] = value end end return values 	end function wlib.bool(x) 		return not not x end return wlib end)() local std = shared.std

local Nothing do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _Nothing_ = {};
    function _Nothing_.__init__(self)
        self.CurrentSound = nil
    end

    function _Nothing_.Play(self, soundController, backgroundState)
        -- Cleanup any existing sound
        if self.CurrentSound and self.CurrentSound.Parent then
            self.CurrentSound:Destroy()
        end

        -- Create a dummy sound that plays nothing
        self.CurrentSound = Instance.new("Sound")
        self.CurrentSound.Name = "Nothing"
        self.CurrentSound.Volume = 0
        self.CurrentSound.SoundId = ""
        self.CurrentSound.Parent = game:GetService("SoundService")
        
        -- Add equalizer for consistency with other sound templates
        local EqualizerSoundEffect = Instance.new("EqualizerSoundEffect")
        EqualizerSoundEffect.MidGain = 0
        EqualizerSoundEffect.HighGain = 0
        EqualizerSoundEffect.LowGain = 0
        EqualizerSoundEffect.Parent = self.CurrentSound
        
        -- Update background state with the dummy sound
        backgroundState:Update(self.CurrentSound)
    end

    function _Nothing_.Destroy(self)
        if self.CurrentSound and self.CurrentSound.Parent then
            self.CurrentSound:Destroy()
            self.CurrentSound = nil
        end
    end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] Nothing=setmetatable(_Nothing_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_Nothing_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _Nothing_.__index__ then return _Nothing_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("Nothing").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=Nothing,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor Nothing>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end

return Nothing 