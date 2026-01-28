local std = shared.std --@wfuscator vm=no;

local RunService = game:GetService("RunService");
local ConfettiCannon = require(script.ConfettiCannon);
ConfettiCannon.setGravity(Vector2.new(0.1,1));
local confetti = {};
local ConfettiFrame = Instance.new("Frame"); ConfettiFrame.Size = UDim2.fromScale(1, 1); ConfettiFrame.BackgroundTransparency = 1; ConfettiFrame.Parent = std.MainGui;
ConfettiFrame.ZIndex = 1000; ConfettiFrame.Name = "ConfettiFrame"

-- Create confetti paper.
local AmountOfConfetti = 100;
for i=1, AmountOfConfetti do
	local p = ConfettiCannon.createParticle(
		Vector2.new(0.5,1), 									-- Position on screen. (Scales)
		Vector2.new(std.random.float(-45*1.5, 45*1.5), std.random.int(70,100)), 		-- The direction power of the blast.
		ConfettiFrame, 												-- The frame that these should be displayed on.
		nil
	);
	table.insert(confetti, p);
end;

local confettiActive = false
-- Update position of all confetti.
std.Clock.every(1/60, function(dt)--@wfuscator run_unsandboxed=yes;
	for _,val in confetti do
		val.Enabled = confettiActive;
		val:Update(dt);
	end;
end);

return function()
	local SoundController = std.Knit.GetController("SoundController")
	SoundController:PlaySound("Confetti"):Group(SoundController.Groups.Interface)
	SoundController:PlaySound("ConfettiPop"):Group(SoundController.Groups.Interface)
	SoundController:PlaySound("ConfettiComplete"):Group(SoundController.Groups.Interface)

    task.defer(function()
        confettiActive = true
        task.wait(1/15)
        confettiActive = false
    end)
end