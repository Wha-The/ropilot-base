--[[
    https://www.roblox.com/library/2217334446/Chems-Particle-Engine
	Chem's Particle Engine
	Used to mass handle ImageLabels to work as particles for the graphic screen. v1.0
	By Chemicalex (ChemicalHex)
--]]

local std = shared.std
local pModule = {}

---You can disable creating a new Gui or just set the default holder value to a preexisting one if you don't like this.
local holder = Instance.new("ScreenGui",game.Players.LocalPlayer:WaitForChild("PlayerGui"))
holder.Name = "MainInterface"
holder.DisplayOrder += 1
local holder = Instance.new("Frame",holder)
holder.Name = "ParticleFrame"
holder.Size = UDim2.new(1,0,1,0)
holder.BackgroundTransparency = 1

local particleCap = 200 --Very high values may cause the system to function improperly. 200 is very safe though

pModule.particleList = {}

local mouse = game.Players.LocalPlayer:GetMouse()

function pModule.createParticle(
	 baseObject, 
	 lifespan,
	 initVelocity,
	 rotVelocity,
	 acceleration,
	 sizeChange,
	 transparencyShift,
	 movementMode,
	 parentObject
	 )
-------------------------------------------------------	
	
	--Create the particle data table to be inserted into the list.
	
	local tableToInsert = {
		baseObject, --object to alter. 1
		lifespan, --remaining frames. 2
		initVelocity, --the value affected by acceleration. 3
		rotVelocity, --the value that alters rotating the particle, and how much. 4
		acceleration, -- the value that changes the speed or direction of the particle in a constant. 5
		sizeChange, --acceleration but for the size. 6
		transparencyShift, --the constant shift in transparency. 7
		movementMode, -- 0 for scale, 1 for offset
		parentObject
	}
	
		if not parentObject then parentObject = holder end
		
		if parentObject then
			baseObject.Parent = parentObject
			local originalSize = baseObject.Size
			baseObject.Size = UDim2.new(0, 0, 0, 0)
			std.SimpleTween(baseObject, "Size", originalSize, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out).Completed:Wait()
		end
	
		local neededIndex = false
		
		if #pModule.particleList < 200 then
			table.insert(pModule.particleList, tableToInsert)
			return #pModule.particleList
		else
			for i,v in ipairs(pModule.particleList) do
				if not pModule.particleList[i + 1] then 
        			neededIndex = i + 1
    			end
			end
			if not neededIndex then -- in case the first element of the table was nil
    			neededIndex = 1
			end
			
			if neededIndex < particleCap+1 then
				pModule.particleList[neededIndex] = tableToInsert
				return neededIndex
			else
				print("No open particle slots :(")	
				tableToInsert[1]:Destroy()
			end
			
		end	


end

function pModule.updateParticle(dt)
	for index, particle in pairs(pModule.particleList) do
		if particle ~= nil then
			
			particle[1].Position = particle[1].Position + std.Util.UDim2Multiply(particle[3], dt)
			
			pModule.particleList[index][3] = pModule.particleList[index][3] + particle[5]
			
			if particle[1].AbsoluteSize.X > 0 or particle[1].AbsoluteSize.Y > 0 then
				particle[1].Size = particle[1].Size + std.Util.UDim2Multiply(particle[6], dt)
			else
				particle[1].Size = UDim2.new(0,0,0,0)
			end	
			
			
			particle[1].Rotation = particle[1].Rotation + particle[4]
			
			particle[1].ImageTransparency = particle[1].ImageTransparency + particle[7]
			
			if particle[8] ~= 0 then
				for pi, pv in pairs(particle[8]) do
					
					if pv[1] == "TweenToMouse" then
						particle[1]:TweenPosition(UDim2.new(0,mouse.X,0,mouse.Y),"Out",pv[2],pv[3],pv[4])
					end
					
				end
			end
			
			if particle[2] ~= -1 then pModule.particleList[index][2] = pModule.particleList[index][2] - 1 end
			
			-----DELETE IF ENDED----
			if pModule.particleList[index][2] <= 0 and pModule.particleList[index][2] ~= -1 then
				task.spawn(function()
					std.SimpleTween(particle[1], "Size", UDim2.new(), 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out).Completed:Wait()
					particle[1]:Destroy()
				end)
				pModule.particleList[index] = nil
			end
		end
	end
end

game:GetService("RunService").RenderStepped:Connect(pModule.updateParticle)

return pModule