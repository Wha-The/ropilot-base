local std = shared.std
local Knit = std.Knit
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ButtonEffects = require(script.Effects)

local globalMouseUp do
    globalMouseUp = std.Bindable()
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if table.find({Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch}, input.UserInputType) or input.KeyCode == Enum.KeyCode.ButtonA then
            globalMouseUp:Fire()
        end
    end)
end

local mcp_registeredButtons
if RunService:IsStudio() then
    -- maintain a table of all registered buttons for playtest simulation
    mcp_registeredButtons = {}
    shared.mcp_registeredButtons = mcp_registeredButtons
end

local Button do --[=[ [LUAUPP]: Luau with Classes; inherit: []  ]=]local _Button_ = {};
    function _Button_.__init__(self, button, options)
        self.ButtonObject = button
        self.Options = options or {}
        if self.Options.Sound ~= false then
            self.ClickSound = self.Options.Sound or "Click"
            self.ClickDownSound = self.Options.ClickDownSound or "Click Down"
            self.HoverSound = self.Options.HoverSound or "Hover"
        end
		self.Enabled = true

        self._maid = std.Maid()

        self.IsRealButton = self.ButtonObject:IsA("TextButton") or self.ButtonObject:IsA("ImageButton")
        self.OnMouseEvent = std.Bindable()
		if self.IsRealButton then
            if self.Options.ForceUnreliableGui ~= nil then
                self.IsOnUnreliableGui = self.Options.ForceUnreliableGui
            elseif self.ButtonObject:FindFirstAncestorWhichIsA("SurfaceGui") or self.ButtonObject:FindFirstAncestorWhichIsA("BillboardGui") then
                self.IsOnUnreliableGui = true
            end
            
            if self.IsOnUnreliableGui then
                self.ActivatedEvent = std.Bindable(self.ButtonObject.Activated)
            else
                self.ActivatedEvent = std.Bindable()
            end
            self._maid:GiveTask(self.ButtonObject.MouseButton1Down:Connect(function()
                self.CachedAbsoluteSize = self.ButtonObject.AbsoluteSize
                self.OnMouseEvent:Fire("Down")
            end))
            self._maid:GiveTask(self.ButtonObject.MouseButton1Up:Connect(function()
                self.OnMouseEvent:Fire("Up")
                globalMouseUp:Fire(true)
            end))
		else
			self.ActivatedEvent = std.Bindable()
            -- self.ActivatedEvent:Connect(function()
            --     self.OnMouseEvent:Fire("Down")
            --     task.wait(.1)
            --     self.OnMouseEvent:Fire("Up")
            -- end)
		end

        self.OnVerifiedMouseEvent = std.Bindable()
        self:initVerifiedChecker()

		self.ActivatedEvent:AddFireCondition(function()
			return self.Enabled
		end)
		self.ActivatedEvent:Connect(function()
            game:GetService("GuiService").SelectedObject = nil
			if self.ClickSound then
				Knit.GetController("SoundController"):PlaySound(self.ClickSound)
			end
		end)
		self._maid:GiveTask(self.ActivatedEvent)
		self._maid:GiveTask(self.OnMouseEvent)
		self:OnHoverEnter(function()
            if self.HoverSound then
                Knit.GetController("SoundController"):PlaySound(self.HoverSound)
            end
        end)
		self:OnHoverExit(function()end)
        self._maid:GiveTask(self.OnMouseEvent:Connect(function(state)
            if state == "Down" then
                if self.ClickDownSound then
                    Knit.GetController("SoundController"):PlaySound(self.ClickDownSound)
                end
            end
        end))

        -- auto cleanup bc im lazy sometimes
		self._maid:GiveTask(button.AncestryChanged:Connect(function(_, newParent)
            if not newParent then
                self:Destroy()
            end
        end))

        self.AppliedEffects = {Click = {}, Hover = {}}

        if mcp_registeredButtons then
            mcp_registeredButtons[self] = true
        end

        return self
    end

    function _Button_.initVerifiedChecker(self)
        local called_down = false
        self.OnMouseEvent:Connect(function(event)
            if event == "Down" then called_down = true; self.OnVerifiedMouseEvent:Fire("Down") end
        end)
        if self.IsOnUnreliableGui then
            self.OnMouseEvent:Connect(function(event)
                if event == "Up" then
                    self.OnVerifiedMouseEvent:Fire("Up")
                    called_down = false
                end
            end)
        end
        -- self.ActivatedEvent:Connect(function()
        --     if called_down then
        --         self.OnVerifiedMouseEvent:Fire("Up")
        --         called_down = false
        --     end
        -- end)
        local guiInset = std.Util:GetGuiInset()
        local applyAnchorPoint = function(anchorPoint, position, size)
            local bounds = {
                X = position.X,
                Y = position.Y,
                Width = size.X,
                Height = size.Y
            }
            bounds.X = bounds.X - (bounds.Width * anchorPoint.X)
            bounds.Y = bounds.Y - (bounds.Height * anchorPoint.Y)
            return bounds
        end
        self._maid:GiveTask(globalMouseUp:Connect(function(isFromButtonMouseUp) --@wfuscator run_unsandboxed=yes
            if called_down then
                self.OnVerifiedMouseEvent:Fire("Up")
                called_down = false
                if self.IsOnUnreliableGui then return end
                -- if UserInputService.MouseEnabled then
                --     if self.hovering then
                --         self:Activate()
                --     end
                -- else
                local bypass_mouse_cursor_pos_check = false
                if #UserInputService:GetConnectedGamepads() >= 1 and isFromButtonMouseUp then
                    bypass_mouse_cursor_pos_check = true
                end
                if not self.CachedAbsoluteSize then return end
                if bypass_mouse_cursor_pos_check then
                    return self:Activate()
                end
                local AbsoluteSize = self.CachedAbsoluteSize * 1.1
                local mouseLocation = UserInputService:GetMouseLocation() - guiInset -- Vector2.new(screenInset.left, screenInset.top)
                if not self.ButtonObject.AbsolutePosition or not mouseLocation then return end
                
                -- local bounds = applyAnchorPoint(self.ButtonObject.AnchorPoint, self.ButtonObject.AbsolutePosition, AbsoluteSize)
                local bounds = {
                    X = self.ButtonObject.AbsolutePosition.X - AbsoluteSize.X * 0.2,
                    Y = self.ButtonObject.AbsolutePosition.Y - AbsoluteSize.Y * 0.2,
                    Width = AbsoluteSize.X * 1.4,
                    Height = AbsoluteSize.Y * 1.4
                }
                if  mouseLocation.X >= bounds.X and
                    mouseLocation.X <= (bounds.X + bounds.Width) and
                    mouseLocation.Y >= bounds.Y and
                    mouseLocation.Y <= (bounds.Y + bounds.Height) then
                    self:Activate()
                end
                -- end
            end
        end))
    end
    function _Button_.SetSound(self, clickSound, hoverSound)
        self.ClickSound = clickSound
        self.HoverSound = hoverSound
    end
    function _Button_.SetVisible(self, visible)
        self.ButtonObject.Visible = visible
    end
    function _Button_.AddClickEffect(self, effect, ...)
        table.insert(self.AppliedEffects.Click, effect)
        ButtonEffects.Click[effect](self, ...)
        return self
    end
    function _Button_.AddHoverEffect(self, effect, ...)
        table.insert(self.AppliedEffects.Hover, effect)
        ButtonEffects.Hover[effect](self, ...)
        return self
    end
    function _Button_.OnClick(self, callback)
        self.ActivatedEvent:Connect(callback)
        return self
    end
    function _Button_.OnClick_fast(self, callback)
        self.ButtonObject.MouseButton1Click:Connect(callback)
        return self
    end
    function _Button_.OnMouse(self, callback)
        self.OnVerifiedMouseEvent:Connect(callback)
        return self
    end
    function _Button_.OnHoverEnter(self, callback)
        -- Store callback for MCP simulation
        if not self._hoverEnterCallbacks then
            self._hoverEnterCallbacks = {}
        end
        table.insert(self._hoverEnterCallbacks, callback)
        
        self._maid:GiveTask(self.ButtonObject.MouseEnter:Connect(function()
			if not self.Enabled then return end
            self.hovering = true
            if UserInputService.MouseEnabled then
                callback()
            end
        end))
        return self
    end
    function _Button_.OnHoverExit(self, callback) -- arg 0 to callback: (instant)
        -- Store callback for MCP simulation
        if not self._hoverExitCallbacks then
            self._hoverExitCallbacks = {}
        end
        table.insert(self._hoverExitCallbacks, callback)
        
        self._maid:GiveTask(function()
            if self.hovering then
                if UserInputService.MouseEnabled then
                    callback(true) -- call hover exit
                end
            end
        end)
        self._maid:GiveTask(self.ButtonObject.MouseLeave:Connect(function()
			if not self.Enabled then return end
            self.hovering = false
            if UserInputService.MouseEnabled then
                callback()
            end
        end))
        return self
    end
    
    -- MCP: Simulate hover enter (for testing)
    function _Button_.SimulateHoverEnter(self)
        if not self.Enabled then return false end
        self.hovering = true
        if self._hoverEnterCallbacks then
            for _, callback in ipairs(self._hoverEnterCallbacks) do
                pcall(callback)
            end
        end
        return true
    end
    
    -- MCP: Simulate hover exit (for testing)
    function _Button_.SimulateHoverExit(self, instant)
        if not self.Enabled then return false end
        self.hovering = false
        if self._hoverExitCallbacks then
            for _, callback in ipairs(self._hoverExitCallbacks) do
                pcall(callback, instant)
            end
        end
        return true
    end
    function _Button_.Activate(self, mute)
        local sound
        if mute then
            sound = self.ClickSound
            self.ClickSound = nil
        end
        self.ActivatedEvent:Fire()
        if sound then
            self.ClickSound = sound
        end
    end
    function _Button_.OnEnabled(self, callback)
        self.Options.OnEnabled = callback
    end
    function _Button_.OnDisabled(self, callback)
        self.Options.OnDisabled = callback
    end

	function _Button_.Disable(self)
		if self.Options.OnDisabled then
			task.spawn(self.Options.OnDisabled, self)
		end
		self.Enabled = false
	end
	function _Button_.Enable(self)
		if self.Options.OnEnabled then
			task.spawn(self.Options.OnEnabled, self)
		end
		self.Enabled = true
	end

    function _Button_.Destroy(self)

        if mcp_registeredButtons then
            mcp_registeredButtons[self] = nil
        end

        -- disconnects everything
        if self._maid then
            self._maid:Destroy()
        end
    end
 --[[ [luau with classes] little bit of code to make the constructor work :) ]] Button=setmetatable(_Button_,{__call=function(classconstructor_reference,...)local self={}local memaddr=tostring(self)self=setmetatable(self,{__index=function(_,i)local v=_Button_[i]if typeof(v)=="function"then return function(...)local args=table.pack(...)if not rawequal(args[1],self)then return v(self,table.unpack(args))end;return v(table.unpack(args))end;end;if rawequal(v,nil)then if _Button_.__index__ then return _Button_.__index__(self,i)end;end;return v;end,__tostring=function(self)return self.__repr__ and self.__repr__()or"<classinstance of "..tostring("Button").." at "..memaddr..">"end,__call=function(self,...)assert(self.__call__,tostring(self).." is not callable!")return self.__call__(...)end,__mul=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__mul__,"Attempted to multiply with incompatible type: "..tostring(self))return self.__mul__(other)end,__add=function(a,b)local other=nil;if rawequal(a,self)then other=b;else other=a;end;assert(self.__add__,"Attempted to add with incompatible type: "..tostring(self))return self.__add__(other)end,__eq=function(self,...)if self.__eq__ then return self.__eq__(...)else return rawequal(self,...)end;end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__CONSTRUCTOR_REFERENCE=Button,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__INHERITCLASSCONSTRUCTORS={},})if self.__init__ then self.__init__(...)end;return self;end,__tostring=function()return"<classconstructor Button>"end,__LUAUWITHCLASSES_INTERNAL_DO_NOT_MODIFY__ISCONSTRUCTOR=true,})end

Button.globalMouseUp = globalMouseUp

return Button