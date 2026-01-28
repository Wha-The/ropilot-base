--[[
    example Zen menu creation setup code:

function ShopController:Mount(main)
    main:Menu("Shop", "/Shop", {
		[Event("Open")] = function(menu, maid)
			ZenController:InitMenu(menu, maid)
			ZenController:ReduceMobileStroke(menu, maid)

            -- any other init code

			-- Observe cash changes to update button states
			maid:GiveTask(DataController:Observe("/Default/Cash", function()
				-- cash changed, do something
                -- self:UpdateShopUI(menu, maid)
			end))
		end,

        -- only needed if Close button is in a special location, not directly .Close under the shop frame:
		[Button(".TopBar.Close")] = function()
            if main then
                main:CloseMenu("Shop")
            end
		end,
	}, { global = true })
end

add to ZenController in KnitStart:
ShopController:Mount(main)
    
]]




--[[ compiled with [luau with classes] compiler v4.6 ]] __author__ = "@NWhut <https://whut.dev/>"	local getclassconstructor do _typeof = typeof; typeof = function(object) local object_type = _typeof(object); if object_type == "table" then local meta = getmetatable(object); if meta then if meta.__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE then object_type = "classinstance" end; if meta.__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR then object_type = "classconstructor" end end end; return object_type end; getclassconstructor = function(object) if typeof(object) == "classinstance" then return getmetatable(object).__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE end end end; local super = function(self) return getmetatable(self).__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS[1] end;wlib = (function() assert = function(condition, message, scope) if not condition then error(message, 2 + (scope or 0)) end end local wlib = {} function wlib.partial(fn, ...) local dargs = table.pack(...) return function(...) local args = {}; for _, darg in ipairs(dargs) do table.insert(args, darg) end; for _, darg in ipairs(table.pack(...)) do table.insert(args, darg) end; return fn(table.unpack(args)) end end function wlib.map(fn, iter) local values = nil if typeof(iter) == "table" then values = table.create(#iter) else values = {} end for idx, value in iter do values[idx] = fn(value) end return values end function wlib.filter(fn, iter) 		local values = {} for idx, value in iter do local condition = fn(value) if condition then 				values[idx] = value end end return values 	end function wlib.bool(x) 		return not not x end return wlib end)() local std = shared.std
local Knit = std.Knit

local MenuEffects = require(script.Effects)
local MenuPreset = require(script.Presets)

local Menu do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _Menu_ = {};
    function _Menu_.__init__(self, Menu)
        self.MenuObject = Menu
        self.IsActive = false
        self.AnimationSets = {}
        self.Events = {}
        self.Opened, self.Closed = std.Bindable(), std.Bindable()

        return self
    end
    function _Menu_.UseAnimationSet(self, animationSet, ...)
        table.insert(self.AnimationSets, {animationSet, {...}, {0.15, Enum.EasingStyle.Back, "DynamicEaseDirection"}})
        return self
    end
    function _Menu_.ConfigureAnimationSet(self, set, ...)
        for index, t in self.AnimationSets do
            local setId, setArgs, setTween = table.unpack(t)
            if set == setId then
                self.AnimationSets[index] = {setId, {...}, setTween}
            end
        end
        return self
    end
    function _Menu_.ConfigureAnimationTween(self, set, ...)
        for index, t in self.AnimationSets do
            local setId, setArgs, setTween = table.unpack(t)
            if set == setId then
                local modifiedTweenArgs = table.clone(self.AnimationSets[index][3])
                for i, k in table.pack(...) do modifiedTweenArgs[i] = k end
                self.AnimationSets[index] = {setId, setArgs, modifiedTweenArgs}
            end
        end
        return self
    end
    function _Menu_.ParseArgs(self, args, config) -- modifies args in place
        for index, arg in args do
            if config[arg] then
                args[index] = config[arg]
            end
        end
    end
    function _Menu_.Open(self)
        self.Opened:Fire()
        self.MenuObject.Visible = true
        self.IsActive = true
        local longest = 0
        for _, t in self.AnimationSets do
            local setId, setArgs, setTween = table.unpack(t)
            task.defer(function()
                local tweenArgs = table.clone(setTween)
                self:ParseArgs(tweenArgs, {DynamicEaseDirection = Enum.EasingDirection.Out})
                if self.Events[setId] and self.Events[setId].OnOpen then
                    self.Events[setId].OnOpen:Fire(setArgs, tweenArgs)
                end
                MenuEffects[setId].Open(self, {
                    Args = setArgs,
                    Tween = tweenArgs,
                })
            end)
            longest = math.max(longest, setTween[1])
        end
        self.AnimationPlaying = true
        task.delay(longest, function()
            self.AnimationPlaying = nil
        end)
        return self
    end
    function _Menu_.Close(self)
        self.Closed:Fire()
        self.IsActive = false
        local longest = 0
        for _, t in self.AnimationSets do
            local setId, setArgs, setTween = table.unpack(t)
            local tweenArgs = table.clone(setTween)
                
            self:ParseArgs(tweenArgs, {DynamicEaseDirection = Enum.EasingDirection.In})
            if self.Events[setId] and self.Events[setId].OnClose then
                self.Events[setId].OnClose:Fire(setArgs, tweenArgs)
            end
            longest = math.max(longest, setTween[1])
            task.defer(function()
                MenuEffects[setId].Close(self, {
                    Args = setArgs,
                    Tween = tweenArgs,
                }) 
            end)
        end
        self.AnimationPlaying = true
        task.delay(longest, function()
            if self.IsActive then return end
            self.MenuObject.Visible = false
            self.AnimationPlaying = nil
        end)
        
        return self
    end
    function _Menu_.CloseInstant(self)
        self.Closed:Fire()
        self.IsActive = false
        for _, t in self.AnimationSets do
            local setId, setArgs, setTween = table.unpack(t)
            local tweenArgs = table.clone(setTween)
            tweenArgs[1] = 0
            self:ParseArgs(tweenArgs, {DynamicEaseDirection = Enum.EasingDirection.In})
            if self.Events[setId] and self.Events[setId].OnClose then
                self.Events[setId].OnClose:Fire(setArgs, tweenArgs)
            end
            MenuEffects[setId].Close(self, {
                Args = setArgs,
                Tween = tweenArgs,
            })
        end
        return self
    end
    function _Menu_.OnOpen(self, setId, callback)
        self.Events[setId] = self.Events[setId] or {}
        self.Events[setId].OnOpen = self.Events[setId].OnOpen or std.Bindable()
        return self.Events[setId].OnOpen:Connect(callback)
    end
    function _Menu_.OnClose(self, setId, callback)
        self.Events[setId] = self.Events[setId] or {}
        self.Events[setId].OnClose = self.Events[setId].OnClose or std.Bindable()
        return self.Events[setId].OnClose:Connect(callback)
    end
    
    function _Menu_.ApplyPreset(self, preset)
        MenuPreset[preset](self)
        return self
    end
    function _Menu_.Toggle(self)
        if self.IsActive then
            self:Close()
        else
            self:Open()
        end
    end
    function _Menu_.Destroy(self)
        return self.MenuObject:Destroy()
    end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] Menu=setmetatable(_Menu_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_Menu_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _Menu_.__index__ then return _Menu_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("Menu").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=Menu,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor Menu>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end

return Menu