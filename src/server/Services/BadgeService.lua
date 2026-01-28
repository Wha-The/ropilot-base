local std = shared.std
local Knit = std.Knit

local BadgeService = Knit.CreateService {
    Name = "BadgeService",
}

BadgeService.Badges = {
    YourFirstSlide = 3797884728463075,
}

local _BadgeService = game:GetService("BadgeService")
local DataService

function BadgeService:GrantBadge(player, badgeName)
    if DataService:GetKey(player, "/System/OwnedBadges/"..badgeName) then return end
    local badgeId = self.Badges[badgeName]
    if badgeId then
        local success, message = pcall(function()
            return _BadgeService:AwardBadge(player.UserId, badgeId)
        end)
        if success then
            DataService:SetKey(player, "/System/OwnedBadges/"..badgeName, true)
        else
            warn(message)
        end
    else
        warn("No badge id for", badgeName)
    end
end

function BadgeService:KnitStart()
    DataService = Knit.GetService("DataService")
end

return BadgeService
