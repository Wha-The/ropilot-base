local ContentProvider = game:GetService("ContentProvider")
--//
-- Confetti Cannon by Richard, Onogork 2018.
--//
--@wfuscator enabled=no
local std = shared.std
local Camera = workspace.CurrentCamera

-- Confetti Defaults.
local SquareConfetti; do
	SquareConfetti = Instance.new("ImageLabel")
	SquareConfetti.Name = "SquareConfetti"
	SquareConfetti.Visible = false
	SquareConfetti.AnchorPoint = Vector2.new(0.5, 0.5)
	SquareConfetti.Size = UDim2.new(0, 50, 0, 50)
	SquareConfetti.BackgroundTransparency = 0
	SquareConfetti.BorderSizePixel = 0
	SquareConfetti.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	-- SquareConfetti.Image = "rbxassetid://910256717"
	task.defer(function() ContentProvider:PreloadAsync({SquareConfetti}) end)
end
local shapes = {SquareConfetti};
local colorsDefault = {Color3.fromRGB(255, 75, 78), Color3.fromRGB(255, 103, 227), Color3.fromRGB(74, 128, 255), Color3.fromRGB(89, 255, 214), Color3.fromRGB(135, 255, 71), Color3.fromRGB(255, 192, 66)}
-- Module.
local _Confetti = {}; _Confetti.__index = _Confetti;
	-- Set the gravitational pull for the confetti.
	local gravity = Vector2.new(0,1);
	function _Confetti.setGravity(paramVec2)
		gravity = paramVec2;
	end;
	-- Create a confetti particle.	
	function _Confetti.createParticle(paramEmitter, paramForce, paramParent, paramColors)
		local _Particle = {}; setmetatable(_Particle, _Confetti);
		-- Adjust forces.
		local xforce = paramForce.X; if (xforce < 0) then xforce = xforce * -1; end;
		local distanceFromZero = 0 - xforce;
		paramForce = Vector2.new(paramForce.X, paramForce.Y + (distanceFromZero * 0.75));
		if (paramColors == nil) then paramColors = colorsDefault; end; 
		-- Confetti data.		
		_Particle.EmitterPosition = paramEmitter;
		_Particle.EmitterPower = paramForce;
		_Particle.Position = Vector2.new(0,0);
		_Particle.Power = paramForce;
		_Particle.Color = std.random.choice(paramColors)
		local function getParticle()
			local label = std.random.choice(shapes):Clone()
			label.BackgroundColor3 = _Particle.Color
			label.Parent = paramParent
			label.Rotation = std.random.int(360);
			label.Visible = true;
			label.ZIndex = 20;
			return label;
		end;
		_Particle.Label = getParticle();
		_Particle.DefaultSize = 30;
		_Particle.Size = 1; _Particle.Side = -1;
		_Particle.OutOfBounds = false;
		_Particle.Enabled = false;
		_Particle.Cycles = 0;
		return _Particle;
	end;
	-- Update the position of the confetti.
	function _Confetti:Update(paramDeltaTime) --@wfuscator run_unsandboxed=yes;
		if self.Enabled and self.OutOfBounds then
			self.Label.ImageColor3 = self.Color;
			self.Position = Vector2.new(0,0);
			self.Power = Vector2.new(self.EmitterPower.X + std.random.float(-5, 5), self.EmitterPower.Y + std.random.float(-5, 5));
			self.Cycles = self.Cycles + 1;
		end
		if (
			(not(self.Enabled) and self.OutOfBounds) or
			(not(self.Enabled) and (self.Cycles == 0))) then
				self.Label.Visible = false;
				self.OutOfBounds = true;
				self.Color = colorsDefault[math.random(#colorsDefault)];
				return;
		else
			self.Label.Visible = true;
		end;
		local startPosition, currentPosition, currentPower = self.EmitterPosition, self.Position, self.Power;
		local imageLabel = self.Label;
		-- Apply change.
		if (imageLabel) then
			-- Update position.
			local newPosition = Vector2.new(currentPosition.X - currentPower.X, currentPosition.Y - currentPower.Y);
			local newPower = Vector2.new((currentPower.X/1.09) - gravity.X, (currentPower.Y/1.1) - gravity.Y);
			local ViewportSize = Camera.ViewportSize;
			imageLabel.Position = UDim2.new(startPosition.X, newPosition.X, startPosition.Y, newPosition.Y);
			self.OutOfBounds = 
				(imageLabel.AbsolutePosition.X > ViewportSize.X and gravity.X > 0) or
				(imageLabel.AbsolutePosition.Y > ViewportSize.Y and gravity.Y > 0) or
				(imageLabel.AbsolutePosition.X < 0  and gravity.X < 0) or
				(imageLabel.AbsolutePosition.Y < 0 and gravity.Y < 0);
			self.Position, self.Power = newPosition, newPower;
			-- Start spinning if it's reached max height.
			if (newPower.Y < 0) then
				if (self.Size <= 0) then
					self.Side = 1;
					imageLabel.ImageColor3 = self.Color;
				end;
				if (self.Size >= self.DefaultSize) then 
					self.Side = -1;
					local H, S, V = self.Color:ToHSV()
					imageLabel.ImageColor3 = Color3.fromHSV(H, S, V - 0.3)
				end;
				self.Size = self.Size + (self.Side * 2);
				imageLabel.Size = UDim2.new(0, self.DefaultSize, 0, self.Size);
			end;
		end;
	end;
	-- Stops a confetti from firing again once it's out of bounds.
	function _Confetti:Toggle()
		self.Enabled = not(self.Enabled);
	end;
return _Confetti;
