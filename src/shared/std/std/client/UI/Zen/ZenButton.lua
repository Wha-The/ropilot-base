--[[ compiled with [luau with classes] compiler v4.6 ]] __author__ = "@NWhut <https://whut.dev/>"	local getclassconstructor do _typeof = typeof; typeof = function(object) local object_type = _typeof(object); if object_type == "table" then local meta = getmetatable(object); if meta then if meta.__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE then object_type = "classinstance" end; if meta.__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR then object_type = "classconstructor" end end end; return object_type end; getclassconstructor = function(object) if typeof(object) == "classinstance" then return getmetatable(object).__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE end end end; local super = function(self) return getmetatable(self).__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS[1] end;wlib = (function() assert = function(condition, message, scope) if not condition then error(message, 2 + (scope or 0)) end end local wlib = {} function wlib.partial(fn, ...) local dargs = table.pack(...) return function(...) local args = {}; for _, darg in ipairs(dargs) do table.insert(args, darg) end; for _, darg in ipairs(table.pack(...)) do table.insert(args, darg) end; return fn(table.unpack(args)) end end function wlib.map(fn, iter) local values = nil if typeof(iter) == "table" then values = table.create(#iter) else values = {} end for idx, value in iter do values[idx] = fn(value) end return values end function wlib.filter(fn, iter) 		local values = {} for idx, value in iter do local condition = fn(value) if condition then 				values[idx] = value end end return values 	end function wlib.bool(x) 		return not not x end return wlib end)() local std = shared.std

local function assertwarn(condition, message)
	if not condition then
		warn(message)
	end
end
local function timegated(callback)
	local tg = std.Timegate()
	return function(...)
		local args = table.pack(...)
		if not tg:consume() then return end
		local success, err = xpcall(function()
			return table.pack(callback(table.unpack(args)))
		end, debug.traceback)
		if not success then
			warn("ZenButton: timegated wrap: error whilst invoking callback: "..tostring(err))
		end
		tg:unlock()
		return success and table.unpack(err)
	end
end

local ZenButton do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _ZenButton_ = {};
    function _ZenButton_.__init__(self, path, options)
        self.Path = path
        self.Options = options or {}
        self.ComposeCallbacks = {}
        self.CreatedCallback = {function(button) return button:AddHoverEffect("HL"):AddClickEffect("Bounce") end}
		self.CallbackTimegated = false
    end
    function _ZenButton_.Compose(self, frame, action, maid)
		if self.CallbackTimegated then
			action = timegated(action)
		end
        local buttonObject = std.parsePath(self.Path)(frame)
		if not self.Options.SuppressWarnings then
        	assertwarn(buttonObject:IsA("TextButton") or buttonObject:IsA("ImageButton"), "ZenButton: Path must point to a TextButton or ImageButton, path: "..self.Path)
		end
		local button = std.client.UI.Button(buttonObject, self.Options)
        self.CreatedCallback[1](button)
        button:OnClick(function()
			ZenButton.TrackInteractionsFunction(self.Path)
			return action(button)
        end)
        maid:GiveTask(button)
		self.Button = button

        for _, callback in self.ComposeCallbacks do
            callback(button, maid)
        end
    end

	function _ZenButton_.BindActivate(self, event)
		std.client.UI.Zen.GlobalTopicHandler[event] = function()
			if not self.Button then return warn("ZenButton: Attempted to activate button before it was composed, path: "..self.Path) end
			self.Button:Activate()
		end
		return self
	end

    function _ZenButton_.Extend(self, callback)
        table.insert(self.ComposeCallbacks, callback)
        return self
    end
    function _ZenButton_.SetCreatedCallback(self, callback)
        self.CreatedCallback = {callback}
        return self
    end
	function _ZenButton_.Timegated(self)
		self.CallbackTimegated = true
		return self
	end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] ZenButton=setmetatable(_ZenButton_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_ZenButton_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _ZenButton_.__index__ then return _ZenButton_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("ZenButton").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=ZenButton,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor ZenButton>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end
ZenButton.SupplyMenuToCallback = true
ZenButton.TrackInteractionsFunction = function() end

return ZenButton