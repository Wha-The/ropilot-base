local random = {}

function random.getExpProb(luck)
	if luck > 2 then
		local rest = luck - 2
		if rest > 1 then
			-- luck > 3
			luck = 2 + math.sqrt(rest)
		else
			-- luck = 2 -> 3
			luck = 2 + rest / 1.5
		end
	end
	local exp = (1 + (luck - 1)/12)

	return exp
end

function random.probabilityFromLowest(probibilityList, options)
	if not next(probibilityList) then return warn("No probibility list provided/probability table is EMPTY!!") end
	--[[
		options: [table]
			- ReturnIfNotPicked: any
			- Luck: number (1, higher = lucker)
	]] options = options or {}

	--[[
		Luck = 1
		Cat = 70%
		Dog = 30%
		----------
		Luck = 2 (2x luck)
		[can't divide because that would rule out some options making some of the common ones impossible to get]
		[ we want to make small numbers smaller, and at the same time not rule out any options]
		n = log(n)
		Cat = 70%
		Dog = 30%
	]]

	local luck = options.Luck or 1
	
	local probabilities = {}
	for item, prob in probibilityList do
		table.insert(probabilities, {item, prob})
	end
	table.sort(probabilities, function(a, b)
		return a[2] < b[2]
	end)
	-- local n = random.float() ^ (1 + (luck - 1)/3.5) -- exponentiation < 1 makes the number SMALLER!
	local exp = random.getExpProb(luck)
	n = random.float() ^ exp
	-- print(`rolling with luck x{luck}, n raised to: {exp} | n => {n}`)
	for _, data_unpack in probabilities do
		local item, prob = table.unpack(data_unpack)
		local picked = n <= prob
		if picked then
			return item
		else
			n -= prob
		end
	end
	return options.ReturnIfNotPicked or probabilities[#probabilities][1]
end

local rng

function random.seed(seedoffset)
	local seed = (function()
		local s = tick()
		local c = 1924295815 + seedoffset
		s = bit32.bxor(bit32.rshift(s, 13), s * c + 24531)
		return s
	end)()
	math.randomseed(seed)
	rng = Random.new(seed)
end

random.seed(0) -- change offset to a random number for your game so your game does not have the seed as other games using Ropilot @whut

function random.choice(choices)
	assert(#choices > 0, "No choices available")
	return choices[random.int(1, #choices)]
end
function random.int(min, max)
	if not max and min then max = min; min = 0 end
	if not min and not max then
		min, max = 0, 1
	end
	return rng:NextInteger(min, max)
end
function random.float(min, max) 
	if not min and not max then
		return rng:NextNumber()
	end
	return rng:NextNumber(min, max)
end
function random.pick(...)
	return random.choice({...})
end

function random.shuffle(list)
	local shuffled = {}
    local copy = table.clone(list)
    for index = 1, #list do
        local rindex = random.int(1, #copy)
        local value = copy[rindex]
        table.remove(copy, rindex)
        table.insert(shuffled, value)
    end
    return shuffled
end

function random.point(min, max)
	local minV = min:Min(max)
	local maxV = max:Max(max)
	return Vector3.new(random.float(minV.X, maxV.X), random.float(minV.Y, maxV.Y), random.float(minV.Z, maxV.Z))
end

function random.chance(chance)
	return random.float() <= chance
end

return random