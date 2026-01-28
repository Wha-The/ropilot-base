--[[ compiled with [luau with classes] compiler v4.6 ]] __author__ = "@NWhut <https://whut.dev/>"	local getclassconstructor do _typeof = typeof; typeof = function(object) local object_type = _typeof(object); if object_type == "table" then local meta = getmetatable(object); if meta then if meta.__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE then object_type = "classinstance" end; if meta.__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR then object_type = "classconstructor" end end end; return object_type end; getclassconstructor = function(object) if typeof(object) == "classinstance" then return getmetatable(object).__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE end end end; local super = function(self) return getmetatable(self).__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS[1] end;wlib = (function() assert = function(condition, message, scope) if not condition then error(message, 2 + (scope or 0)) end end local wlib = {} function wlib.partial(fn, ...) local dargs = table.pack(...) return function(...) local args = {}; for _, darg in ipairs(dargs) do table.insert(args, darg) end; for _, darg in ipairs(table.pack(...)) do table.insert(args, darg) end; return fn(table.unpack(args)) end end function wlib.map(fn, iter) local values = nil if typeof(iter) == "table" then values = table.create(#iter) else values = {} end for idx, value in iter do values[idx] = fn(value) end return values end function wlib.filter(fn, iter) 		local values = {} for idx, value in iter do local condition = fn(value) if condition then 				values[idx] = value end end return values 	end function wlib.bool(x) 		return not not x end return wlib end)() --[[
    Zen: A UI Framework created by Whut (https://whut.dev/)


    Handy Dandy Quick Reference Manual:
    ZenButton: Zen.Button(path, options)
        arguments:
            path: string
            options: table
        methods:
            :Compose(frame, action, maid) => self; --> action(std.client.UI.Menu, std.client.UI.Button, maid) on compose
            :Extend(callback) => self; --> callback(std.client.UI.Button, maid) on compose

            :SetCreatedCallback(callback) => self; calls callback(button) on compose, **EXPECTS** a Button object returned
                -> you may use this to apply custom effects to the button
            :Timegated() => self; timegates the callback (layman's terms: prevents additional callbacks from being called when the current one hasn't finished)


    ZenItemInterface: Zen.ItemInterface(framePath, templatePathRel)
        arguments:
            framePath: string
            templatePathRel: string
        methods:
            :Compose(frame, getComposeData, maid) => self; --> getComposeData(frame, maid) => {Name = "xxx", Instances = {["path"] = {property = value}, [object] = passToCompose}}
            :ComposeIndividual(frame, maid, index, itemrenderinfo) => template; --> itemrenderinfo = getComposeData(frame, maid)[index]
            :Redraw() => self; --> re-composes the item interface

    ZenItemInterfaceD: Zen.ItemInterfaceD(framePath, templatePathRel, path)
        arguments:
            framePath: string
            templatePathRel: string
            path: string
        methods:
            :Compose(frame, getComposeDataIndividual, maid) => self; --> getComposeDataIndividual(frame, key, value, maid) => {Name = "xxx", Instances = {["path"] = {property = value}, [object] = passToCompose}}
            :AddFilter(filter) => self; --> filter(value, key) **RETURNS** boolean
            :ClearFilters() => self;
            :SetPlaceholder(path) => self;


    ZenDataObserver: ZenDataObserver(path)
        arguments:
            path: string
        methods:
            :Compose(frame, callback, maid) => self;
                -> callback[key, item, maid] is called to get info on how to render
    
    ZenPlayerlist: ZenPlayerlist(path, templatePathRel)
        arguments:
            path: string
            templatepathRel: string
        methods:
            :Compose(frame, btncallback, maid) => self;
                -> inserts players into template frame with relevant info and buttons responding to btncallback(Player)
]]

local ContentProvider = game:GetService("ContentProvider")
local ContextActionService = game:GetService("ContextActionService")
local std = shared.std
local parsePath = std.parsePath
local ZenButton = require(script.ZenButton)
local ZenGlossyMat = require(script.ZenGlossyMat)
local GlobalTopicHandler = {}
local GlobalCloseButtonNames = {"Close"}
local GlobalInteractionsQueue = {}

ZenButton.TrackInteractionsFunction = function(buttonPath)
    table.insert(GlobalInteractionsQueue, buttonPath)
end

local TrackFunction = function() end
local GlobalCurrentlyOpenedMenu = nil -- type: ZenSubMenu
local DataController

std.Knit.OnStart():andThen(function()
	DataController = std.Knit.GetController("DataController")
end)

local CloseButtons_Global = {}
local function endswith(str, suffix)
    return str:sub(-suffix:len()) == suffix
end

local removesuffix = function(str, suffix)
    return str:sub(1, -suffix:len() - 1)
end

local updateButtonMobile = function(button, isMobile)
    local isForMobile = endswith(button.ButtonObject.Name, "Mobile")
    if not isForMobile then 
        local originalSize = button.ButtonObject:GetAttribute("OriginalSize_internal")
        if isMobile then
            if not button.ButtonObject:GetAttribute("NoSizeUp") then
                button.ButtonObject.Size = std.Util.UDim2Multiply(originalSize, 1.5)
                button.ButtonObject:SetAttribute("OriginalSize", button.ButtonObject.Size)
            end
        else
            button.ButtonObject.Size = originalSize
            button.ButtonObject:SetAttribute("OriginalSize", button.ButtonObject.Size)
        end
    end

    if isForMobile then
        local name = removesuffix(button.ButtonObject.Name, "Mobile")
        local complementaryPCButton = button.ButtonObject.Parent:FindFirstChild(name)
        if complementaryPCButton then
            complementaryPCButton.Visible = not isMobile
        end
    else
        local name = button.ButtonObject.Name .. "Mobile"
        local complementaryMobileButton = button.ButtonObject.Parent:FindFirstChild(name)
        if complementaryMobileButton then
            complementaryMobileButton.Visible = isMobile
        end
    end
end


std.client.MobileDetect:ObserveNoIpad(function(isMobile)
    for _, button in CloseButtons_Global do
        updateButtonMobile(button, isMobile)
    end
end)

local ZINDICIES = {Menu = 4}

local runPrecompose, hookConfiguration

local ZenCurrencyLabel do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _ZenCurrencyLabel_ = {};
    function _ZenCurrencyLabel_.__init__(self, path)
        self.Path = path
    end
    function _ZenCurrencyLabel_.Compose(self, frame, statData, maid)
        local statName, statPath, getAnimTime, additionalOptions = statData.Name, statData.StatPath, statData.GetAnimTime, statData.AdditionalOptions
        local Frame = parsePath(self.Path)(frame)
        local TextLabel = Frame:FindFirstChild("Text")
        if Frame:IsA("TextLabel") then TextLabel = Frame end

		while not DataController do task.wait() end
        maid:GiveTask(DataController:Observe(statPath, function(value)
            value = value or 0
            local last = TextLabel:GetAttribute("Last") or -1
            TextLabel:SetAttribute("Last", value)

            local animTime = getAnimTime and getAnimTime(value) or 0
            local prefix = additionalOptions.Prefix or ""
            if animTime > 0 then
                std.client.NumberTween(function(value)
                    TextLabel.Text = prefix..std.FormatNumber(value)
                end, last, value, animTime, Enum.EasingStyle.Sine)
            else
                TextLabel.Text = prefix..std.FormatNumber(value)
            end
        end))
    end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] ZenCurrencyLabel=setmetatable(_ZenCurrencyLabel_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_ZenCurrencyLabel_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _ZenCurrencyLabel_.__index__ then return _ZenCurrencyLabel_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("ZenCurrencyLabel").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=ZenCurrencyLabel,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor ZenCurrencyLabel>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end

local RTL2CurrencyLabel do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _RTL2CurrencyLabel_ = {};
    function _RTL2CurrencyLabel_.__init__(self, path)
        self.Path = path
    end
    function _RTL2CurrencyLabel_.Compose(self, frame, statData, maid)
        local statName, statPath, getAnimTime = statData.Name, statData.StatPath, statData.GetAnimTime
        local TextLabel = parsePath(self.Path)(frame)

        while not DataController do task.wait() end
        local lastTween = nil
        maid:GiveTask(DataController:Observe(statPath, function(value)
            value = value or 0
            local last = TextLabel:GetAttribute("Last") or -1
            TextLabel:SetAttribute("Last", value)

            local prefix = ""
            local animTime = getAnimTime and getAnimTime(value) or 0
            if lastTween then lastTween:Cancel(); lastTween = nil end
            if animTime > 0 then
                lastTween = std.client.NumberTween(function(value)
                    TextLabel.Text = prefix..std.FormatNumber(value)
                end, last, value, animTime, Enum.EasingStyle.Sine)
            else
                TextLabel.Text = prefix..std.FormatNumber(value)
            end
        end))
    end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] RTL2CurrencyLabel=setmetatable(_RTL2CurrencyLabel_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_RTL2CurrencyLabel_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _RTL2CurrencyLabel_.__index__ then return _RTL2CurrencyLabel_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("RTL2CurrencyLabel").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=RTL2CurrencyLabel,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor RTL2CurrencyLabel>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end

local ZenPlayerlist do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _ZenPlayerlist_ = {};
    function _ZenPlayerlist_.__init__(self, path, templatePathRel)
        self.Path = path
        self.TemplatePathRel = templatePathRel
    end
    function _ZenPlayerlist_.Compose(self, frame, btncallback, maid)
        local Frame = parsePath(self.Path)(frame)
        local Template = parsePath(self.TemplatePathRel)(Frame)
        Template.Parent = nil

        maid:GiveTask(function() Template.Parent = Frame end) -- restore template

        local function insertPlayer(player)
            local template = Template:Clone()
            template.Name = player.UserId
            template.Playername.Text = player.Name
            template.Icon.Image = "rbxthumb://type=AvatarHeadShot&id="..tostring(player.UserId, "! this was formatted from {}").."&w=150&h=150"
            template.Parent = Frame

            maid:GiveTask(std.client.UI.Button(template):AddHoverEffect("Classic"):AddClickEffect("Bounce"):OnClick(wlib.partial(btncallback, player)))
            maid:GiveTask(template)
        end
        for _, player in game.Players:GetPlayers() do
            task.defer(insertPlayer, player)
        end
        maid:GiveTask(game.Players.PlayerAdded:Connect(insertPlayer))
        maid:GiveTask(game.Players.PlayerRemoving:Connect(function(player)
            local child = Frame:FindFirstChild(player.UserId)
            if child then
                child:Destroy()
            end
        end))
    end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] ZenPlayerlist=setmetatable(_ZenPlayerlist_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_ZenPlayerlist_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _ZenPlayerlist_.__index__ then return _ZenPlayerlist_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("ZenPlayerlist").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=ZenPlayerlist,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor ZenPlayerlist>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end

local ZenEvent do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _ZenEvent_ = {};
    _ZenEvent_.BuiltInEvents = {"Precompose", "Compose", "Open", "Close", "OnOpen", "OnClose"}
    function _ZenEvent_.__init__(self, name)
        self.Name = name
        self.OpenMaid = std.Maid()
    end
    function _ZenEvent_.Precompose(self, frame, callback)
        if self.Name == "Precompose" then callback(frame) end -- Frame: NOT std.client.UI.Menu!

        if not table.find(self.BuiltInEvents, self.Name) then -- bind to topic when composed
            GlobalTopicHandler[self.Name] = wlib.partial(callback, frame)
        end
    end
    function _ZenEvent_.Compose(self, frame, callback, maid)
        if self.Name == "Compose" then callback(frame, maid) end -- Frame: NOT std.client.UI.Menu!
    end
    function _ZenEvent_.OnOpen(self, menu, callback, maid)
        if self.Name == "Open" then
            if self.OpenMaid then self.OpenMaid:Destroy() end
            callback(menu, self.OpenMaid)
        end -- Frame: std.client.UI.Menu!
    end
    function _ZenEvent_.OnClose(self, menu, callback, maid)
        if self.OpenMaid then self.OpenMaid:Destroy() end
        if self.Name == "Close" then callback(menu) end -- Frame: std.client.UI.Menu!
    end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] ZenEvent=setmetatable(_ZenEvent_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_ZenEvent_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _ZenEvent_.__index__ then return _ZenEvent_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("ZenEvent").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=ZenEvent,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor ZenEvent>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end

ZenButton.ZenEvent = ZenEvent

local function Render(instanceTree, frame)
    local passToComposer = {}
    for path, item in instanceTree do
        if typeof(path) == "string" then
            local instance = parsePath(path, function(object, index)
                return object:FindFirstChild(index)
            end)(frame)
            for property, value in item do
                instance[property] = value
            end
        else
            passToComposer[path] = item
        end
    end
    
    return passToComposer
end

local ZenItemInterface do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _ZenItemInterface_ = {};
	function _ZenItemInterface_.__init__(self, framePath, templatePathRel)
		self.FramePath = framePath
		self.TemplatePath = templatePathRel

		self.SessionMaid = std.Maid()
	end
	function _ZenItemInterface_.ComposeIndividual(self, frame, maid, index, itemrenderinfo)
		assert(typeof(index) == "number", "ZenItemInterface: Data must be an array")
		local Frame = parsePath(self.FramePath)(frame)
		local Template = parsePath(self.TemplatePath)(Frame)

		local template = Template:Clone()
		template.Visible = true
		template.Name = itemrenderinfo.Name
		template.LayoutOrder = index
		template.Parent = Frame

        local passToComposer = Render(itemrenderinfo.Instances, template)
        
        local submaid = hookConfiguration(template, passToComposer)
		maid:GiveTask(submaid)

        if itemrenderinfo.Tooltip then
            maid:GiveTask(std.client.UI.Tooltip(template, itemrenderinfo.Tooltip))
        end

		maid:GiveTask(template)
		return template
	end
	function _ZenItemInterface_.Compose(self, frame, getComposeData, maid)
		maid:GiveTask(self.SessionMaid)
		self._frame = frame
		self._getComposeData = {getComposeData}
		
		self:Redraw()
	end
	function _ZenItemInterface_.Redraw(self)
		self.SessionMaid:Destroy()
		local frame = self._frame
		local getComposeData = self._getComposeData[1]

		local composeData = getComposeData(frame, self.SessionMaid)
		-- struct composeData:
		--[[ {{
			Name = "xxx",
			Instances = {
				[instancebypath] = properties,
				[object (must have :Compose)] = passToCompose,
			}
		 }, ...}]]
		local Template = parsePath(self.TemplatePath)(parsePath(self.FramePath)(frame))
		Template.Visible = false
		for index, itemrenderinfo in composeData do
			self:ComposeIndividual(frame, self.SessionMaid, index, itemrenderinfo)
		end
	end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] ZenItemInterface=setmetatable(_ZenItemInterface_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_ZenItemInterface_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _ZenItemInterface_.__index__ then return _ZenItemInterface_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("ZenItemInterface").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=ZenItemInterface,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor ZenItemInterface>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end
local ZenSubMenu do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _ZenSubMenu_ = {};
    function _ZenSubMenu_.__init__(self, path, options)
        self.Path = path
        self.options = options or {}
    end
    function _ZenSubMenu_.Compose(self, parentFrame, config, maid_outer)
        local frame
        if not parentFrame and typeof(self.Path) == "Instance" then
            frame = self.Path
        else
            frame = parsePath(self.Path)(parentFrame)
        end
        local menu = (self.options.create_menu or function(menuObject) return std.client.UI.Menu(menuObject):ApplyPreset("Default") end)(frame)
        self.Menu = menu
        
        if self.options.global then
            menu.Opened:Connect(function()
                GlobalCurrentlyOpenedMenu = self
            end)
            menu.Closed:Connect(function()
                if GlobalCurrentlyOpenedMenu == menu then
                    GlobalCurrentlyOpenedMenu = nil
                end
            end)
        end
        do
            local hasCloseButton = {}
            for element, callback in config do
                if getclassconstructor(element) == ZenButton then
                    for _, name in GlobalCloseButtonNames do
                        if element.Path == ("." .. name) or element.Path == name then
                            hasCloseButton[name] = true
                        end
                    end
                end
                if typeof(element) == "table" or typeof(element) == "classinstance" then
                    if element.SupplyMenuToCallback then
                        if typeof(callback) == "function" then
                            config[element] = wlib.partial(callback, menu)
                            -- print("supplied callback with menu! => ", getclassconstructor(element))
                        end
                    end
                end
            end
            for _, name in GlobalCloseButtonNames do
                if not hasCloseButton[name] and menu.MenuObject:FindFirstChild(name) then
                    print("adding close button", name)
                    config[ZenButton("." .. name, {Sound = "Close"}):Extend(function(btn)
                        btn.ButtonObject:SetAttribute("OriginalSize_internal", btn.ButtonObject.Size)
                        table.insert(CloseButtons_Global, btn) --! When we do disposable menus, this WILL cause a memory leak
                        updateButtonMobile(btn, std.client.MobileDetect:DetectNoIpad())
                    end)] = function()
                        if menu.AnimationPlaying then
                            return
                        end
                        menu:Close()
                    end
                end
            end
        end
        local maid = hookConfiguration(frame, config)
        maid:GiveTask(menu)
        maid_outer:GiveTask(maid)

        menu:CloseInstant()
        menu.Opened:Connect(function()
            for element, action in config do
                if element.OnOpen then
                    element:OnOpen(menu, action, maid)
                end
            end
        end)
        menu.Closed:Connect(function()
            for element, action in config do
                if element.OnClose then
                    element:OnClose(menu, action, maid)
                end
            end
        end)
    end
    function _ZenSubMenu_.__index__(self, key)
        if not rawget(self, "Menu") then
            return nil -- Menu has not been initialized!
        end
        return self.Menu[key]
    end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] ZenSubMenu=setmetatable(_ZenSubMenu_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_ZenSubMenu_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _ZenSubMenu_.__index__ then return _ZenSubMenu_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("ZenSubMenu").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=ZenSubMenu,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor ZenSubMenu>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end

local ZenItemInterfaceDStorageInterface do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _ZenItemInterfaceDStorageInterface_ = {};
    function _ZenItemInterfaceDStorageInterface_.__init__(self, options)
        self.options = options or {}
    end
    function _ZenItemInterfaceDStorageInterface_.__index__(self, key)
        return self.options[key]
    end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] ZenItemInterfaceDStorageInterface=setmetatable(_ZenItemInterfaceDStorageInterface_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_ZenItemInterfaceDStorageInterface_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _ZenItemInterfaceDStorageInterface_.__index__ then return _ZenItemInterfaceDStorageInterface_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("ZenItemInterfaceDStorageInterface").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=ZenItemInterfaceDStorageInterface,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor ZenItemInterfaceDStorageInterface>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end

local ZenItemInterfaceD do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _ZenItemInterfaceD_ = {};
	function _ZenItemInterfaceD_.__init__(self, framePath, templatePathRel, path, options)
		self.FramePath = framePath
		self.TemplatePath = templatePathRel
        
        self.options = options or {}
        local SuppressChildrenUpdates = self.options.SuppressChildrenUpdates
        if getclassconstructor(path) ~= ZenItemInterfaceDStorageInterface then
            local oldpath = path
            path = ZenItemInterfaceDStorageInterface({
                HasItems = function()
                    return next(DataController:Get(oldpath) or {})
                end,
                Observe = function(maid, callback)
                    maid:GiveTask(DataController:ObserveTable(oldpath, callback, SuppressChildrenUpdates))
                end
            })
        end
		self.interface = path
		
		self.ItemInterface = ZenItemInterface(framePath, templatePathRel)
		self.Items = {}
		self.Filters = {}
	end

	function _ZenItemInterfaceD_.Compose(self, frame, getComposeDataIndividual, maid)
		parsePath(self.TemplatePath)(parsePath(self.FramePath)(frame)).Visible = false -- hide template
        local updatePlaceholder = function() end
        if self.PlaceholderPath then
            local Placeholder = parsePath(self.PlaceholderPath)(frame)
            Placeholder.Visible = false
            updatePlaceholder = function()
                if Placeholder then Placeholder.Visible = not self.interface.HasItems() end
            end
        end
		
        updatePlaceholder()
		local _index = 0
		self.interface.Observe(maid, function(key, value, cleanupMaid) --@wfuscator run_unsandboxed=yes
            updatePlaceholder()
            if not value then
                return
            end

			local itemrenderinfo = getComposeDataIndividual(parsePath(self.FramePath)(frame), key, value, cleanupMaid)
			if not itemrenderinfo then return end
			_index = _index + 1
			local template = self.ItemInterface:ComposeIndividual(frame, cleanupMaid, _index, itemrenderinfo)
			self.Items[template] = {key, value}
			cleanupMaid:GiveTask(function()
				self.Items[template] = nil
			end)
			maid:GiveTask(cleanupMaid)
		end)
	end

    function _ZenItemInterfaceD_.SetPlaceholder(self, path)
        self.PlaceholderPath = path
        return self
    end

	function _ZenItemInterfaceD_.AddFilter(self, filter)
		table.insert(self.Filters, filter)
		for template, data in self.Items do
			if template.Visible then
				-- check against new filter
				local pass = filter(data[2], data[1], template)
				template.Visible = pass
			end
		end
	end
	function _ZenItemInterfaceD_.ClearFilters(self)
		self.Filters = {}
		for template, keyvalue in self.Items do
			template.Visible = true
		end
	end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] ZenItemInterfaceD=setmetatable(_ZenItemInterfaceD_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_ZenItemInterfaceD_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _ZenItemInterfaceD_.__index__ then return _ZenItemInterfaceD_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("ZenItemInterfaceD").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=ZenItemInterfaceD,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor ZenItemInterfaceD>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end

ZenItemInterfaceD.StorageInterface = ZenItemInterfaceDStorageInterface

local ZenDataTableObserver = require(script.ZenDataTableObserver)
local ZenDataObserver = require(script.ZenDataObserver)

runPrecompose = function(object, configuration)
    for element, action in configuration do
        if element.Precompose then
            element:Precompose(object, action)
        end
    end
end

hookConfiguration = function(object, configuration)
    local maid = std.Maid()
    for element, action in configuration do
        if element.Compose then
            element:Compose(object, action, maid)
        end
    end
    return maid
end

local Zen do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _Zen_ = {};
    function _Zen_.__init__(self, mainFrame)
        self.MainFrame = mainFrame
        self.DataController = std.Knit.GetController("DataController")
        self.Menus = {} -- name -> {state, data} (state: 1 = not loaded, 2 = loaded)
        self.HUDElements = {}

        self.Queue = {}
        self.UnmountMaid = std.Maid()
    end
    function _Zen_.ConfigureHUD(self, hud, configuration)
        hud = parsePath(hud)
        runPrecompose(hud(self.MainFrame), configuration)
        table.insert(self.Queue, function()
            return hookConfiguration(hud(self.MainFrame), configuration)
        end)
    end
    function _Zen_.Menu(self, name, path, configuration, options)
        options = options or {}

        if options.Track ~= false then
            local open_timestamp = 0
            configuration[ZenEvent("Open")] = function()
                open_timestamp = os.time()
            end
            configuration[ZenEvent("Close")] = function()
                if GlobalInteractionsQueue[#GlobalInteractionsQueue] == ("." .. GlobalCloseButtonNames[1]) then
                    table.remove(GlobalInteractionsQueue, #GlobalInteractionsQueue) -- we do not want to track the close button
                end
                TrackFunction(name, os.time() - open_timestamp, GlobalInteractionsQueue)
                GlobalInteractionsQueue = {}
            end
        end
        configuration[ZenEvent("Open")] = function(menu, maid)
            -- some weird issue where ButtonB fires when tab is pressed on PC / robux prompt pops up

            -- ContextActionService:BindAction("ConsoleExitMenu", function()
            --     print("ButtonB triggered")
            --     self:CloseMenu(name)
            --     return Enum.ContextActionResult.Sink
            -- end, false, Enum.KeyCode.ButtonB)
            -- maid:GiveTask(function()
            --     ContextActionService:UnbindAction("ConsoleExitMenu")
            -- end)
        end
        local menu = parsePath(path)(self.MainFrame)
        if menu.Visible then menu.Visible = false end
        runPrecompose(menu, configuration)
        self.Menus[name] = {1, {
            MenuObject = menu,
            Configuration = configuration,
            create_menu = options.fnCreateMenu or options.create_menu,
            global = options.global,
        }}

        local me
        me = {
			Compose = function()
				self:EnsureMenuInitialized(name)
                return me
			end,
            Preload = function()
                task.defer(function()
                    ContentProvider:PreloadAsync(menu:GetDescendants())
                end)
            end,
		}
        return me
    end
    function _Zen_.GetMenu(self, menuName)
        assert(self.Menus[menuName], "GetMenu: Unknown Menu: "..tostring(menuName, "! this was formatted from {}"))
        if self.Menus[menuName][1] == 1 then
            return nil
        end
        return self.Menus[menuName][2].Menu
    end
    function _Zen_.Mount(self)
        for _, callback in self.Queue do
            local maid = callback()
            self.UnmountMaid:GiveTask(maid)
        end
        -- print(`[Zen UI Framework]: Mounted {std.Util.TableCount(self.Menus)} menu(s)!`)

        -- -- slowly initialize all menus
        -- for _, menuState in self.Menus do
        --     self:EnsureMenuInitialized(menuState[2].MenuObject.Name)
        --     task.wait(0.1)
        -- end
    end
    function _Zen_.Unmount(self)
        for _, menuState in self.Menus do
            if menuState[1] == 2 then
                menuState[2].Maid:Destroy()
            end
        end
        table.clear(self.Menus)
        self.UnmountMaid:Destroy()
    end

    function _Zen_.EnsureMenuInitialized(self, menuName)
        local menuState = self.Menus[menuName]
        assert(menuState, "EnsureMenuInitialized: Unknown Menu: "..tostring(menuName, "! this was formatted from {}"))
        if menuState[1] == 1 then
            local maid_outer = std.Maid()
            -- passing in menuState[2] as options
            local menu = ZenSubMenu(menuState[2].MenuObject, menuState[2])
            menu:Compose(nil, menuState[2].Configuration, maid_outer)
            if not menu.MenuObject:GetAttribute("ForceZIndex") then
                menu.MenuObject.ZIndex = ZINDICIES.Menu
            else
                menu.MenuObject.ZIndex = menu.MenuObject:GetAttribute("ForceZIndex")
            end

            
            menuState[1] = 2
            menuState[2].Menu = menu
            menuState[2].Maid = maid_outer
        end
    end

    function _Zen_.OpenMenu(self, menuName, stayOpened)
        -- initialize the menu if it hasn't been initialized yet
        self:EnsureMenuInitialized(menuName)
        local menuState = self.Menus[menuName]
        if GlobalCurrentlyOpenedMenu and GlobalCurrentlyOpenedMenu ~= menuState[2].Menu then
            GlobalCurrentlyOpenedMenu:Close()
            GlobalCurrentlyOpenedMenu = nil
        end
        if stayOpened then
            if not menuState[2].Menu.IsActive then
                menuState[2].Menu:Open()
                return true
            end
        else
            menuState[2].Menu:Toggle()
        end
    end
    function _Zen_.CloseMenu(self, menuName)
        local menuState = self.Menus[menuName]
        local didClose = false
        if menuState and menuState[1] == 2 and menuState[2].Menu.IsActive then
            menuState[2].Menu:Close()
            didClose = true
        end
        if GlobalCurrentlyOpenedMenu == menuState[2].Menu then
            GlobalCurrentlyOpenedMenu = nil
        end
        return didClose
    end
	function _Zen_.IsOpen(self, menuName)
		local menuState = self.Menus[menuName]
		if menuState and menuState[1] == 2 then
			return menuState[2].Menu.IsActive
		end
		return false
	end

    function _Zen_.Render(self, instanceTree, frame)
        return Render(instanceTree, frame)
    end
    function _Zen_.HookConfiguration(self, object, configuration)
        return hookConfiguration(object, configuration)
    end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] Zen=setmetatable(_Zen_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_Zen_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _Zen_.__index__ then return _Zen_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("Zen").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=Zen,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor Zen>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end

local ZenActions = function(main)
    return {
        Menu = function(menuName)
            local tg = std.Timegate(0.2)
            return function(button)
                if not tg:consume() then return end
                main:OpenMenu(menuName)
            end
        end,
        ScrollTo = function(relScrollingFrame, elementInScrollingFrameRel)
            local relScrollingFrame = parsePath(relScrollingFrame)
            local elementInScrollingFrameRel = parsePath(elementInScrollingFrameRel)
            return function(menu, button)
                if getclassconstructor(menu) == std.client.UI.Menu then
                    menu = menu.MenuObject
                end
                local Scrolling = relScrollingFrame(menu)
                local element = elementInScrollingFrameRel(Scrolling)
                local scrollTo = element.AbsolutePosition.Y - Scrolling.AbsolutePosition.Y
                return std.SimpleTween(Scrolling, "CanvasPosition", Scrolling.CanvasPosition + Vector2.new(0, scrollTo), 0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
            end
        end,
        Stat = function(statName, path, getAnimTime, additionalOptions)
            return {
                StatPath = path,
                Name = statName,
                GetAnimTime = getAnimTime,
                AdditionalOptions = additionalOptions,
            }
        end
    }
end

return {
    Zen = Zen,
    Button = ZenButton,
    CurrencyLabel = ZenCurrencyLabel,
    RTL2CurrencyLabel = RTL2CurrencyLabel,
    Playerlist = ZenPlayerlist,
    TopicListener = ZenEvent, -- TopicListener and Event have been merged.
    Event = ZenEvent,
	ItemInterface = ZenItemInterface,
	ItemInterfaceD = ZenItemInterfaceD,
	DataTableObserver = ZenDataTableObserver,
	DataObserver = ZenDataObserver,
    GlossyMat = ZenGlossyMat,
    SubMenu = ZenSubMenu,

    Actions = ZenActions,

    GlobalTopicHandler = GlobalTopicHandler,
    InvokeTopic = function(self, topic, ...)
        local handler = GlobalTopicHandler[topic]
        if handler then
            return handler(...)
        else
            warn("InvokeTopic: Unknown Topic: "..tostring(topic, "! this was formatted from {}"))
        end
    end,
    SetCloseButtonName = function(name)
        if typeof(name) == "string" then
            GlobalCloseButtonNames = {name}
        else
            GlobalCloseButtonNames = name
        end
    end,
    SetTrackFunction = function(fn)
        TrackFunction = fn
    end
}