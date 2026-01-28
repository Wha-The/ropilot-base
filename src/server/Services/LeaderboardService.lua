local LocalizationService = game:GetService("LocalizationService")
local std = shared.std
local Knit = std.Knit

local LeaderboardService = Knit.CreateService {
    Name = "LeaderboardService",
    Client = {
        UpdateTime = Knit.CreateProperty(0),
        LeaderboardUpdated = Knit.CreateSignal(),
    },
}
local DataService
local GeneralService

local DataStoreService = game:GetService("DataStoreService")

local lb_decode = function(value_raw)
    return value_raw ~= 0 and value_raw ~= 0 and (1.0000001^value_raw) or 0 or 0
end

local function getRankings(lb_technicalname)
    -- print("Fetching LB: "..lb_technicalname)
    local rankings = {}
    local DS = DataStoreService:GetOrderedDataStore(lb_technicalname)

    local smallestFirst = false--false = 2 before 1, true = 1 before 2
    local numberToShow = 100--Any number between 1-100, how many will be shown
    local success, pages
    while not success do
        success,pages = pcall(function()
            return DS:GetSortedAsync(smallestFirst, numberToShow)
        end)
        
        if not success then
            task.wait(3)
        end
    end
    local top = pages:GetCurrentPage()
    local userids = {}
    for _, entry in top do
        local userid = entry.key
        local value_raw = entry.value
        local value = math.round(lb_decode(value_raw))
        table.insert(rankings, {
            UserId = userid,
            Value = value,
        })
        table.insert(userids, userid)
    end
    local lookup = {}
    GeneralService:SlugFetchUserIds(userids, function(resolved_userid, resolved_username)
        lookup[resolved_userid] = resolved_username
    end) -- yields
    for _, ranking in rankings do
        ranking.Username = lookup[tonumber(ranking.UserId)]
    end

    return rankings
end

function LeaderboardService:LoadGlobalLeaderboards()
    -- refresh ALL leaderboards

    for _, lb in self.LeaderboardNames do
        -- set refreshing text: TRUE
        table.insert(self.GetSortedAsyncQueue, function()
            self.LeaderboardCache.Global.AllTime[lb] = getRankings("AllTime:"..lb)
            self.Client.LeaderboardUpdated:FireAll("Global", "AllTime", lb, self.LeaderboardCache.Global.AllTime[lb])
        end)
        table.insert(self.GetSortedAsyncQueue, function()
            local day = os.date("%x")
            self.LeaderboardCache.Global.Daily[lb] = getRankings("Daily:"..day..":"..lb)
            self.Client.LeaderboardUpdated:FireAll("Global", "Daily", lb, self.LeaderboardCache.Global.Daily[lb])
        end)
        -- set refreshing text: FALSE
    end
end


function LeaderboardService.Client:RequestLeaderboardCacheUpdate(player)
    self = self.Server
    -- local code = self:GetClientCountryCode(player)
    for _, lb in self.LeaderboardNames do
        -- global all time/daily
        if self.LeaderboardCache.Global.AllTime[lb] then
            self.Client.LeaderboardUpdated:Fire(player, "Global", "AllTime", lb, self.LeaderboardCache.Global.AllTime[lb])
        end
    end
end

function LeaderboardService:StartWorkers()
    task.defer(function()
        -- worker
        while true do
            local command = table.remove(self.Queue, 1)
            if command then
                local success, err = pcall(function()
                    if command.Command == "Load" then
                        if command.Global then
                            self:LoadGlobalLeaderboards()
                        end
                    end
                end)
                if not success then
                    warn("LeaderboardService worker error: "..err)
                end
            end

            task.wait(1)
        end
    end)

    task.defer(function() -- keeps an eye on the limits and schedules the calls later if necessary
        while true do
            local budget = DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.GetSortedAsync)
            if budget <= 1 then
                print("LeaderboardService: GetSortedAsync budget is <=1, waiting 10 seconds before dispatching rest of the queue")
                task.wait(10)
                continue
            end
            local command = table.remove(self.GetSortedAsyncQueue, 1)
            if command then
                local success, err = pcall(function()
                    command()
                end)
                if not success then
                    warn("LeaderboardService: GetSortedAsync callback failed: "..tostring(err))
                end
            end
            task.wait(1)
        end
    end)
end


function LeaderboardService:KnitStart()
    DataService = Knit.GetService("DataService")
	GeneralService = Knit.GetService("GeneralService")

    self.LeaderboardCache = {
        Global = {
            AllTime = {},
            Daily = {},
        },
        Country = {},
    }
    self.LeaderboardNames = {"Cash"}

    self.Queue = {}
    
    self.PlayerCountryCodeCache = {}
    local playerAdded = function(player)
        local result, code = pcall(function()
            return LocalizationService:GetCountryRegionForPlayerAsync(player)
        end)
        code = result and code or "US"
        self.PlayerCountryCodeCache[player] = code
    end
    game.Players.PlayerAdded:Connect(playerAdded)
    game.Players.PlayerRemoving:Connect(function(player)
        local code = self.PlayerCountryCodeCache[player]
        task.delay(15, function() self.PlayerCountryCodeCache[player] = nil end)
    end)
    for _, player in game.Players:GetPlayers() do task.spawn(playerAdded, player) end

    self:StartWorkers()

    local clock = std.Clock.every(5 * 60, function()
        print("Refreshing leaderboard now")
        self.Client.UpdateTime:Set(os.time() + 5 * 60)
        table.insert(self.Queue, {Command = "Load", Global = true})
    end, true)


    local prepareOrderedStore = function(value)
        local storedValue = value ~= 0 and math.floor(math.log(value) / math.log(1.0000001)) or 0
        return storedValue
    end

    self.PushToLBRequest:Connect(function(player)
        print("PushToLBRequest: "..player.DisplayName)
        local NO_YIELD = {yield=false}
        local function commit(boardName, key)
            local STAT = DataService:GetKey(player, key, NO_YIELD)
            if STAT then
                task.defer(function()
                    local success, err = pcall(function()
                        DataStoreService:GetOrderedDataStore(boardName):SetAsync(player.UserId, prepareOrderedStore(STAT))
                    end)
                    if not success then
                        warn("Failed to commit to leaderboard: "..err)
                    end
                end)
            end
        end

        local function remove(boardName) -- no error catching - deliberate
            DataStoreService:GetOrderedDataStore(boardName):RemoveAsync(player.UserId)
        end

        -- globals
        commit("AllTime:Cash", "/AllTime/Cash")
    end)
    self.RefreshLeaderboardNow:Connect(function()
        print("Refreshing leaderboard now")
        clock:Skip()
    end)
end

function LeaderboardService:KnitInit()
    self.PushToLBRequest = std.Bindable()
    self.RefreshLeaderboardNow = std.Bindable()
    self.GetSortedAsyncQueue = {}
end

return LeaderboardService