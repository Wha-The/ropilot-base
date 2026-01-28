local Robux = {}
Robux.Gamepasses = {
	-- put gamepasses for your game here! - @whut
	-- [gamepassCodeName] = gamepassId
	-- example: VIP = 1572888189,
	-- check if a player has a gamepass by running:
	-- Server: DataService:GetKey(player, "/System/OwnedGamepasses/(gamepassCodeName)"), if truthy, the player owns it.
	-- Client: DataController:Get("/System/OwnedGamepasses/(gamepassCodeName)"), if truthy, the player owns it.


}

Robux.Products = {
	-- put developer products for your game here! - @whut
	-- [developerProductName] = developerProductId
	-- example: StarterPack = 3449995669,

}

-- optional: adjust to your game's needs
function Robux:CalculateCashPurchases(allTimeCash)
	allTimeCash = allTimeCash or 0

	-- Progressive scaling based on all-time cash earned (more generous)
	local base
	if allTimeCash < 50000 then -- Less than $50K
		base = 1000
	elseif allTimeCash < 250000 then -- Less than $250K
		base = 5000
	elseif allTimeCash < 1000000 then -- Less than $1M
		base = 20000
	elseif allTimeCash < 5000000 then -- Less than $5M
		base = 100000
	elseif allTimeCash < 25000000 then -- Less than $25M
		base = 500000
	elseif allTimeCash < 100000000 then -- Less than $100M
		base = 2000000
	else -- $100M+
		base = 10000000
	end

	return {
		base, -- Cash Pack 1: 1x base
		base * 7, -- Cash Pack 2: 7x base (was 5x)
		base * 25, -- Cash Pack 3: 25x base (was 15x)
		base * 64, -- Cash Pack 4: 64x base (was 100x)
	}
end

return Robux
