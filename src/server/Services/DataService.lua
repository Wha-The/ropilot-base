local std = shared.std
local Knit = std.Knit

local DataService = Knit.CreateService {
    Name = "DataService";
    Client = {
        ForceUpdateData = Knit.CreateSignal(),
        DataUpdated = Knit.CreateSignal(),
    };
}

local DataStoreService = game:GetService("DataStoreService")
local ProfileService = require(Knit.ServerModules.Data.ProfileService)
local DataStore = require(Knit.ServerModules.Data.DataConfig)
local MainProfileStore = ProfileService.GetProfileStore(DataStore.Key, DataStore.Main)

DataService.MainProfileStore = MainProfileStore
local KICK_MESSAGE = "Kicked due to error: "

local NonReplicateToClient = {
    "System/Server",
}

-- Get Data on the Server
function DataService:_GetPlayerData(player, config)
    config = config or {}
    if not self.CachedProfiles then
        if config.yield == false then
            return warn("No DataService.CachedProfiles")
        end
        while not self.CachedProfiles do task.wait() end
    end
    
    if (typeof(player) ~= "Instance") then return warn("Player is not an instance!") end
    local profile = self.CachedProfiles[player]
    if not profile then
        if config.yield == false then
            return warn("No profile found for player")
        else
            while not profile do
                profile = self.CachedProfiles[player]
                task.wait()
            end
        end
    end
    return profile.Data
end

--[[
    CUSTOM BEHAVIOR:
    SERVER:
        local data = DataService:_GetPlayerData(player)
        table.insert(data.System.OwnedTrails, "Trail1")
        DataService:SendUpdateSignal(player, "System/OwnedTrails")

    CLIENT:
        DataController:Observe("System/OwnedTrails", function(ownedTrails)
            
        end)

]]
local function splitRemoveEmpty(str, sep)
    local segments = string.split(str, sep)
    for index, segment in ipairs(segments) do
        if segment == "" then
            table.remove(segments, index)
        end
    end
    return segments
end

local function startswith(str, start)
    return str:sub(1, #start) == start
end

function DataService:SendUpdateSignal(player: Player, segments: table | string, options)
    options = options or {}
    if typeof(segments) == "string" then
        segments = splitRemoveEmpty(string.gsub(segments, "/", "."), ".")
    end
    assert(typeof(player) == "Instance" and player:IsA("Player"), "player must be a Player instance, is "..typeof(player))
    assert(typeof(segments) == "table", "segments must be a table, is "..typeof(segments))
    local data = self:_GetPlayerData(player)
    local value = std.parsePath(segments)(data)
    local path = table.concat(segments, "/")


    local nonReplicate = false
    for _, nonReplicatePath in NonReplicateToClient do
        if startswith(path, nonReplicatePath) then
            nonReplicate = true
            break
        end
    end
    if not nonReplicate then
        self.Client.DataUpdated:Fire(player, path, value)
    end
    if not options.SuppressServerUpdateSignal then
        if self.OnDataUpdated[player] then
            self.OnDataUpdated[player]:Fire(segments, value)
        end
    end
end

function DataService:EnsurePath(player, folder: table, path: table | string)
    local segments = typeof(path) == "string" and splitRemoveEmpty(string.gsub(path, "/", "."), ".") or path
    for _, segment in segments do
        if not folder[segment] then
            folder[segment] = {}
            print("Created path "..table.concat(segments, "/"))
            self:SendUpdateSignal(player, segments)
        end
        if typeof(folder[segment]) ~= "table" then
            warn("Path "..table.concat(segments, "/").." is not a folder")
            return
        end
        folder = folder[segment]
    end
end

function DataService:SetKey(player, key, value, options)
    assert(player and player:IsA("Player"), "DataService:SetKey(): player must be a Player instance")
    assert(typeof(key) == "string", "DataService:SetKey(): key must be a string, is "..typeof(key))
    self.DSOperationsPer30Second.Write += 1

    options = options or {}

    local segments = splitRemoveEmpty(string.gsub(key, "/", "."), ".")
    local folder, key = table.move(segments, 1, #segments-1, 1, {}), segments[#segments]
    local data = self:_GetPlayerData(player, {yield = options.yield})
    self:EnsurePath(player, data, folder)
    local folderObject = std.parsePath(folder)(data)
    folderObject[key] = value
    if not options.Silent then
        self:SendUpdateSignal(player, segments, options)
    end
end

function DataService:GetKey(player, key, options)
    self.DSOperationsPer30Second.Read += 1
    
    options = options or {}
    local data = self:_GetPlayerData(player, {yield = options.yield})
    if not data then return end
    return std.parsePath(splitRemoveEmpty(string.gsub(key, "/", "."), "."))(data)
end

function DataService:IncrementKey(player, key, amount)
    -- thread-safe increment
    amount = amount or 1
    return self:GetLock(player):with(function()
        local value = self:GetKey(player, key) or 0
        self:SetKey(player, key, value + amount)
        return value + amount
    end)
end

-- function DataService:GetAndLockKey(player, key, options)
--     options = options or {}
--     self.PlayerDataLocks[player]:take()

--     -- get the running coroutine
--     local running = coroutine.running()
--     print("Current coroutine ID:", running)

--     return self:GetKey(player, key, options), self.PlayerDataLocks[player]
-- end

function DataService:GetLock(player)
    return self.PlayerDataLocks[player]
end

function DataService:ObserveTable(player, path, callback)
	-- called with the key of what changed and the value of the key of the table at `path`
	-- also passes in a Maid() for convenience
	-- the maid is cleaned up before every invocation
	local segments = splitRemoveEmpty(string.gsub(path, "/", "."), ".")
	local traverser = std.parsePath(segments)
	local localCache = {}
    do
		local t = traverser(self:_GetPlayerData(player))
		if t then
			for key, value in t do
				local maid = std.Maid()
				-- don't need to clean up the maid because it's a new one every time
				task.defer(callback, key, value, maid, true)
				localCache[key] = {value, maid}
			end
		end
	end

    local generalMaid = std.Maid()
    generalMaid:GiveTask(self.OnDataUpdated[player]:Connect(function(updateSegments, value)
        if not updateSegments then
            -- general update
            local t = traverser(self:_GetPlayerData(player))
            if t then
                for key, value in t do
                    if not localCache[key] or value ~= localCache[key][1] then
                        local maid = localCache[key] and localCache[key][2] or std.Maid()
                        maid:Destroy()
    
                        callback(key, value, maid)
                        localCache[key] = {value, maid}
                    end
                end
            else
                -- update nil with all cached keys
                for key, value in localCache do
                    local maid = value[2]
                    maid:Destroy()
                    callback(key, nil, maid)
                end
            end
        else
            for index, segment in segments do
                if segment ~= updateSegments[index] then
                    return
                end
            end
            local remaining = table.move(updateSegments, #segments+1, #updateSegments, 1, {})
            if #remaining <= 0 then return end
            local updateSegment = remaining[1]
            local updateValue = traverser(self:_GetPlayerData(player))[updateSegment]
            
            local maid = localCache[updateSegment] and localCache[updateSegment][2] or std.Maid()
            maid:Destroy()
            callback(updateSegment, updateValue, maid)
            localCache[updateSegment] = {updateValue, maid}
        end
    end))

    generalMaid:GiveTask(function()
        table.clear(localCache)
    end)
	return generalMaid
end

function DataService:Observe(player, path, callback)
    -- Called with the value at the path whenever it changes
    -- Returns a Maid that can be used to clean up the observer
    local segments = splitRemoveEmpty(string.gsub(path, "/", "."), ".")
    local traverser = std.parsePath(segments)
    local oldValue = traverser(self:_GetPlayerData(player))
    task.defer(callback, oldValue)

    local generalMaid = std.Maid()
    generalMaid:GiveTask(self.OnDataUpdated[player]:Connect(function(updateSegments, value)
        if not updateSegments then
            -- general update
            local newValue = traverser(self:_GetPlayerData(player))
            if oldValue == newValue then return end
            callback(newValue, oldValue)
            oldValue = newValue
        else
            for index, segment in segments do
                if segment ~= updateSegments[index] then
                    return
                end
            end
            if #updateSegments < #segments then -- table above us got updated
                value = traverser(self:_GetPlayerData(player))
            end

            callback(value, oldValue)
            oldValue = value
        end
    end))

    return generalMaid
end

function DataService:InitializeData(player)
    -- performs checks on the loaded data
    -- task.spawn(function()
    --     BadgeService:CheckBadges(player)
    -- end)
    -- badge recovery snipplet
    -- task.spawn(function()
    --     for _, data in pairs(Awards.Subscribers) do
    --         if Data.Default.Subscribers >= data.RequiredSubscribers then
    --             if data.Badge then
    --                 BadgeService:GrantBadge(player, data.Badge)
    --             end
    --         end
    --     end
    -- end)
    local data = self:_GetPlayerData(player)
    for key, defaultValue in DataStore.Main.AllTime do
        if not data.AllTime[key] then
            data.AllTime[key] = defaultValue
        end
    end
	data.System.OwnedGamepasses = data.System.OwnedGamepasses or {}
	
	-- Reset sack on session start (session-based storage)
	data.System.Sack = {}
end

function DataService:UpdatedData(player, options)
	self.Client.ForceUpdateData:Fire(player, self:_GetPlayerData(player))
end

function DataService:LoadPlayerProfile(player, retryAttemptNumber)
    local profile = MainProfileStore:LoadProfileAsync("Player_" .. player.UserId, "ForceLoad")

    if (not profile) then
        return player:Kick(KICK_MESSAGE.."PNF1: failed to load data")
    end
    if retryAttemptNumber then
        retryAttemptNumber += 1
        if retryAttemptNumber > 4 then
            player:Kick(KICK_MESSAGE.."RF1: logged into multiple sessions")
            return
        end
    end

    -- Remove player from the game, due to their data being released
    profile:ListenToRelease(function()
        task.delay(3, function()
            self.CachedProfiles[player] = nil
            task.defer(function()
                task.wait()
                if player:IsDescendantOf(game.Players) then
                    self:LoadPlayerProfile(player, retryAttemptNumber)
                end
            end)
        end)
    end)

    -- Check if the player is a part of the game, if so, add the player to the profiles
    if (player:IsDescendantOf(game.Players)) then
        self.CachedProfiles[player] = profile
        self:InitializeData(player)
        if not retryAttemptNumber then
            self.DataLoaded:Fire(player)
        end
        print("[DataService]: " .. player.Name .. "'s profile loaded successfully.")
    else
        profile:Release()
    end
end

function DataService:ReleasePlayerProfile(player)
    local profile = self.CachedProfiles[player]
    if (profile) then
        profile:Release()
    end
end

local function deepCopy(original)
	local copy = {}
	for key, value in original do
		copy[key] = type(value) == "table" and deepCopy(value) or value
	end
	return copy
end

function DataService.Client:GetPlayerData(player)
    while not player:GetAttribute("DataLoaded") do task.wait() end
    local data = deepCopy(self.Server:_GetPlayerData(player))
    if data.Ban then return end

    for _, nonReplicatePath in NonReplicateToClient do
        local segments = splitRemoveEmpty(string.gsub(nonReplicatePath, "/", "."), ".")
        local path, key = table.move(segments, 1, #segments-1, 1, {}), segments[#segments]
        local value = std.parsePath(table.concat(path, "/"))(data)
        if value then
            value[key] = nil
        end
    end

    return data
end

function DataService:KnitStart()
    local playerAdded = function(player)
        self.PlayerDataLocks[player] = std.Lock()
        self.OnDataUpdated[player] = std.Bindable()
        self:LoadPlayerProfile(player)

        local Data = DataService:_GetPlayerData(player)
        if Data.Ban then
            -- User is BANNED!
            player:Kick(string.format(".\nYou have been permanently banned from playing this game!\n\nReason: %s\n", Data.Ban.Reason))
            return
        end

        -- local success, BackupDataStore = pcall(function()
        --     return DataStoreService:GetOrderedDataStore("BackupStore_"..player.UserId.."#"..(Data.BackupIndex or 1))
        -- end)
        -- if success then
        --     local success, pages = pcall(function()
        --         return BackupDataStore:GetSortedAsync(false, 100, nil, os.time())
        --     end)
        --     if success then
        --         local top = pages:GetCurrentPage()

        --         for dkey, data in top do
        --             local number, lastUpdated = data.key, data.value
        --             local n = tonumber(number)
        --             if n then
        --                 -- if n > Data.AllTime. then
        --                 --     -- replace
        --                 --     local success, playerDataStore = pcall(function()
        --                 --         return DataStoreService:GetDataStore("BackupStore_"..player.UserId.."#"..(Data.BackupIndex or 1))
        --                 --     end)
        --                 --     if success then
        --                 --         local success, oldData = pcall(function()
        --                 --             return playerDataStore:GetAsync(lastUpdated)
        --                 --         end)
        --                 --         if success then
        --                 --             for key, value in pairs(oldData) do
        --                 --                 Data[key] = value
        --                 --             end
        --                 --         else
        --                 --             warn(oldData)
        --                 --         end
        --                 --     else
        --                 --         warn(playerDataStore)
        --                 --     end
        --                 --     break
        --                 -- end
        --             end
        --         end
        --     else
        --         warn(pages)
        --     end
        -- else
        --     warn(BackupDataStore)
        -- end

        player:SetAttribute("DataLoaded", true)
    end

    game.Players.PlayerAdded:Connect(playerAdded)
    for _, player in game.Players:GetPlayers() do
        playerAdded(player)
    end

    game.Players.PlayerRemoving:Connect(function(player)
        self.PlayerDataLocks[player] = nil
        local event = self.OnDataUpdated[player]
        if event then
            event:Destroy()
        end
        self.OnDataUpdated[player] = nil

        self:ReleasePlayerProfile(player)
    end)
    std.Clock.every(30, function()
        self.DSOperationsPer30Second.Read = 0
        self.DSOperationsPer30Second.Write = 0
    end)
end


function DataService:ResetPlayer(player)
    assert(player and player:IsA("Player"), "player must be a Player instance")
    self.CachedProfiles[player].Data = DataStore.Main
end
function DataService:KnitInit()
    self.CachedProfiles = {}
    self.PlayerDataLocks = {}
    self.DataLoaded = std.Bindable()
    self.OnDataUpdated = {}
	-- self.OnDataUpdated = std.Bindable()
    
    self.DSOperationsPer30Second = {
        Read = 0;
        Write = 0;
    }
end

return DataService