--[[ compiled with [luau with classes] compiler v4.6 ]] __author__ = "@NWhut <https://whut.dev/>"	local getclassconstructor do _typeof = typeof; typeof = function(object) local object_type = _typeof(object); if object_type == "table" then local meta = getmetatable(object); if meta then if meta.__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE then object_type = "classinstance" end; if meta.__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR then object_type = "classconstructor" end end end; return object_type end; getclassconstructor = function(object) if typeof(object) == "classinstance" then return getmetatable(object).__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE end end end; local super = function(self) return getmetatable(self).__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS[1] end;wlib = (function() assert = function(condition, message, scope) if not condition then error(message, 2 + (scope or 0)) end end local wlib = {} function wlib.partial(fn, ...) local dargs = table.pack(...) return function(...) local args = {}; for _, darg in ipairs(dargs) do table.insert(args, darg) end; for _, darg in ipairs(table.pack(...)) do table.insert(args, darg) end; return fn(table.unpack(args)) end end function wlib.map(fn, iter) local values = nil if typeof(iter) == "table" then values = table.create(#iter) else values = {} end for idx, value in iter do values[idx] = fn(value) end return values end function wlib.filter(fn, iter) 		local values = {} for idx, value in iter do local condition = fn(value) if condition then 				values[idx] = value end end return values 	end function wlib.bool(x) 		return not not x end return wlib end)() local FLAG_DISPATCH_FROM_GLOBAL_THREAD = false -- prevents stack overflow when firing too many events at once

local pending_dispatch = {}
local Bindable do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _Bindable_ = {};
    function _Bindable_.__init__(self, inheritConnection)
		-- @inheritConnection: Bindable / function <return: connection>
        self.connect = self.Connect --@alias

        self.Connections = {}
        self.Connections_n = 0
		self.Events = {} -- for events like `OnFirstConnect` and `OnLastDisconnect` that are bindables apart of this bindable

        if inheritConnection then
            local connection
            self:OnFirstConnect(function()
				if typeof(inheritConnection) == "function" then
					connection = inheritConnection()
					assert(connection.Fire, "`inheritConnection` return must be of type bindable")
				else
					connection = inheritConnection:Connect(function(...)
						self:Fire(...)
					end)
				end
            end)
            self:OnLastDisconnect(function()
                connection:Disconnect()
            end)
        end
    end
    function _Bindable_.OnConnect(self, fn)
		self.Events.OnConnect = self.Events.OnConnect or Bindable()
        return self.Events.OnConnect:Connect(fn)
    end
    function _Bindable_.OnFirstConnect(self, fn)
		self.Events.OnFirstConnect = self.Events.OnFirstConnect or Bindable()
        return self.Events.OnFirstConnect:Connect(fn)
    end
    function _Bindable_.OnDisconnect(self, fn)
		self.Events.OnDisconnect = self.Events.OnDisconnect or Bindable()
		return self.Events.OnDisconnect:Connect(fn)
    end
    function _Bindable_.OnLastDisconnect(self, fn)
		-- this can actually piggyback off of OnDisconnect
		return self:OnDisconnect(function(signal)
			if self.Connections_n <= 0 then
				fn(signal)
			end
		end)
    end
    function _Bindable_.GetConnections(self)
        return coroutine.wrap(function()
            for signal, _ in self.Connections do
                coroutine.yield(signal)
            end
        end)
    end

    function _Bindable_.Connect(self, fnCallback)
		local signal
        signal = {
			Callback = fnCallback,
            Disconnect = function()
                -- local index = table.find(self.Connections, signal)
                -- if index then
                --     table.remove(self.Connections, index)
                --     if self.Events.OnDisconnect then self.Events.OnDisconnect:Fire(signal) end
                -- end
                if self.Connections[signal] then
                    self.Connections[signal] = nil
                    self.Connections_n = self.Connections_n - 1
                    if self.Events.OnDisconnect then self.Events.OnDisconnect:Fire(signal) end
                end
            end,
        }
        signal.Destroy = signal.Disconnect

        -- table.insert(self.Connections, signal)
        self.Connections[signal] = true
        self.Connections_n = self.Connections_n + 1
        if self.Connections_n <= 1 then
            if self.Events.OnFirstConnect then self.Events.OnFirstConnect:Fire(signal) end
        end
        if self.Events.OnConnect then self.Events.OnConnect:Fire(signal) end

        return signal
    end
    function _Bindable_.Once(self, fn)
        local connection
        connection = self:Connect(function(...)
            if connection then
                if typeof(connection) == "function" then
                    print("`typeof(connection)` should not equal `function`")
                    print("This is a bug with wfuscator. Please make sure this file is flagged with --@wfuscator enabled=no")
                    return
                end
                connection:Disconnect()
            else
                task.defer(function() -- callback has been called back instantly... maybe because of OnFirstConnect
                    while not connection do task.wait() end
                    connection:Disconnect()
                end)
            end
            fn(...)
        end)
        return connection
    end
    function _Bindable_.Wait(self, timeout, options)
        options = options or {}
        local evt = Instance.new("BindableEvent")
		local fired_with
        self:Once(function(...)
			fired_with = table.pack(...)
			evt:Fire(...)
		end)
		if fired_with then return table.unpack(fired_with) end -- called instantly

        local rvalue
        if timeout then
            local None = newproxy()
            rvalue = None
            task.defer(function() rvalue = table.pack(evt.Event:Wait()) end)
            local start = os.clock()
            repeat task.wait() until rvalue ~= None or (os.clock() - start) > timeout
            evt:Destroy()

            if rvalue == None then rvalue = nil end
        else
            local yielded = false
            local traceback = debug.traceback()
			if options.warn_infinite_yield ~= false then
				task.delay(3, function()
					-- warn "infinite yield" after 3 seconds
					if not yielded then warn("infinite yield possible with bindable:Wait()"); print(traceback) end
				end)
			end
            
            rvalue = table.pack(evt.Event:Wait())
            yielded = true
            evt:Destroy()
        end
        
        return rvalue and table.unpack(rvalue)
    end
    function _Bindable_.Fire(self, ...) --@wfuscator run_unsandboxed=yes;
		-- check conditions
		if self.FireConditions then for _, condition in self.FireConditions do if not condition() then return end end end
		
        if FLAG_DISPATCH_FROM_GLOBAL_THREAD then
            table.insert(pending_dispatch, {self, table.pack(...)})
        else
            for signal, _ in self.Connections do task.spawn(signal.Callback, ...) end
        end
    end
    function _Bindable_.DisconnectAll(self)
        for signal, _ in self.Connections do
            signal:Disconnect()
        end
        self.Connections = {}
        self.Connections_n = 0
    end

	-- fire conditions: a set of callbacks that all have to return `true` for the event to be fired.
	function _Bindable_.AddFireCondition(self, conditionCallback)
		if not self.FireConditions then self.FireConditions = {} end
		table.insert(self.FireConditions, conditionCallback)
	end

    -- DESTROY
    function _Bindable_.OnDestroy(self, callback)
        self.Destroyed = self.Destroyed or Bindable()
        return self.Destroyed:Connect(callback)
    end
    function _Bindable_.Destroy(self)
        self:DisconnectAll()
        if self.Events.Destroyed then self.Events.Destroyed:Fire() end
    end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] Bindable=setmetatable(_Bindable_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_Bindable_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _Bindable_.__index__ then return _Bindable_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("Bindable").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=Bindable,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor Bindable>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end

if FLAG_DISPATCH_FROM_GLOBAL_THREAD then
    task.spawn(function()
        while true do
            for _, dispatch in pending_dispatch do
                local bindable, args = dispatch[1], dispatch[2]
                for signal, _ in bindable.Connections do task.spawn(signal.Callback, table.unpack(args)) end
            end
            table.clear(pending_dispatch)
            task.wait()
        end
    end)
end

return Bindable