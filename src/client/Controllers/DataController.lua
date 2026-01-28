local std = shared.std
local Knit = std.Knit

local RunService = game:GetService("RunService")
local DataController = Knit.CreateController{
    Name = "DataController"
}

local lock = std.Lock()

local DataService

function DataController:GetData()
    return self.Cached or self:FetchFromServer()
end

function DataController:FetchFromServer()
    if self.cache_is_fetching then
        local called = false
        local trace = debug.traceback()
        task.defer(function()
            task.wait(8)
            if not called then warn("Infinite yield possible with data fetching"); print(trace) end
        end)
        repeat task.wait() until self.Cached
        called = true
        return self.Cached
    end
    self.Cached = nil
    self.cache_is_fetching = true
    
    -- DataService *might* be nil, if it is, yield until it is not
    while not DataService do task.wait() end

    self.Cached = DataService:GetPlayerData()
    self.Cached.cache_fetch_time = os.time()
    self.DataUpdated:Fire()

    self.cache_is_fetching = nil
    
    return self.Cached
end
local function splitRemoveEmpty(str, sep)
    local segments = string.split(str, sep)
    for index, segment in segments do
        if segment == "" then
            table.remove(segments, index)
        end
    end
    return segments
end
function DataController:Observe(path, callback)
    local segments = splitRemoveEmpty(string.gsub(path, "/", "."), ".")
    local traverser = std.parsePath(segments)
    local oldValue = newproxy()
    if self.Cached then
        oldValue = traverser(self:GetData())
        task.defer(callback, oldValue)
    end
    return self.DataUpdated:Connect(function(updateSegments, value)
        if not updateSegments then
            -- general update
            local newValue = traverser(self:GetData())
            if oldValue == newValue then return end
            callback(newValue, oldValue)
            oldValue = newValue
        else
            for index, segment in updateSegments do
                if segment ~= segments[index] then
                    return
                end
            end
            if #updateSegments < #segments then -- table above us got updated
                value = traverser(self:GetData())
            end

            callback(value, oldValue)
            oldValue = value
        end
    end)
end
function DataController:ObserveTable(path, callback, suppressChildrenUpdates)
	-- called with the key of what changed and the value of the key of the table at `path`
	-- also passes in a Maid() for convenience
	-- the maid is cleaned up before every invocation
	local segments = splitRemoveEmpty(string.gsub(path, "/", "."), ".")
	local traverser = std.parsePath(segments)
	local localCache = {}
	if self.Cached then
		local t = traverser(self:GetData())
		if t then
			for key, value in t do
				local maid = std.Maid()
				-- don't need to clean up the maid because it's a new one every time
				task.defer(callback, key, value, maid, {})
				localCache[key] = {value, maid}
			end
		end
	end

    local tableObserveMaid = std.Maid()
    tableObserveMaid:GiveTask(self.DataUpdated:Connect(function(updateSegments, value)
        -- print("data updated", updateSegments, value)
        if not updateSegments then
            -- general update
			local t = traverser(self:GetData())
			if t then
				for key, value in t do
					if not localCache[key] or value ~= localCache[key][1] then
						local maid = localCache[key] and localCache[key][2] or std.Maid()
						maid:Destroy()
	
						callback(key, value, maid, {})
						localCache[key] = {value, maid}
					end
				end
			else
				-- update nil with all cached keys
				for key, value in localCache do
					local maid = value[2]
					maid:Destroy()
					callback(key, nil, maid, {})
				end
			end
        else
            for index, segment in segments do
                if segment ~= updateSegments[index] then
                    return
                end
            end
            if #updateSegments <= 0 then return print("updateSegments is empty") end
			local remaining = table.move(updateSegments, #segments+1, #updateSegments, 1, {})
			local updateSegment = remaining[1]
            if not updateSegment then
                -- entire table got updated - check against localCache to see what changed!
                -- print("entire table updated - propagating changes")
                if typeof(value) ~= "table" then return warn("DataController: value is not a table!") end
                local remainingValue = table.clone(value) -- keep track of new keys
                for key, data in localCache do
                    remainingValue[key] = nil
                    local cacheKeyValue, cacheKeyValueMaid = data[1], data[2]
					if not value[key] or cacheKeyValue ~= value[key] then
						local maid = cacheKeyValueMaid or std.Maid()
						cacheKeyValueMaid:Destroy()
                        callback(key, value[key], maid, remaining)
                        if value[key] == nil then
                            -- deletion
                            localCache[key] = nil
                        else
                            localCache[key] = {value[key], maid}
                        end
					end
				end

                for key, value in remainingValue do
                    if not localCache[key] or localCache[key] ~= value then
                        local maid = localCache[key] and localCache[key][2] or std.Maid()
                        maid:Destroy()

                        callback(key, value, maid, remaining)
                        if value == nil then
                            -- deletion
                            localCache[key] = nil
                        else
                            localCache[key] = {value, maid}
                        end
                    end
                end

                return
            elseif #remaining > 1 then
                if suppressChildrenUpdates then return end
            end
			local updateValue = (traverser(self:GetData()) or {})[updateSegment]
			
			local maid = localCache[updateSegment] and localCache[updateSegment][2] or std.Maid()
			maid:Destroy()
			callback(updateSegment, updateValue, maid, remaining)
            if updateSegment then
                if updateValue == nil then
                    -- deletion
                    localCache[updateSegment] = nil
                else
                    localCache[updateSegment] = {updateValue, maid}
                end
            end
        end
    end))
    tableObserveMaid:GiveTask(function()
        for _, value in localCache do
            value[2]:Destroy()
        end
        table.clear(localCache)
    end)

	return tableObserveMaid
end

function DataController:Get(path)
	local segments = splitRemoveEmpty(string.gsub(path, "/", "."), ".")
	local traverser = std.parsePath(segments)
	return traverser(self:GetData())
end

function DataController:LocalSet(path, value)
    local segments = splitRemoveEmpty(string.gsub(path, "/", "."), ".")
    local folder = table.move(segments, 1, #segments-1, 1, {})
    local traverser = std.parsePath(folder, function(object, index)
        if object[index] == nil then
            object[index] = {}
        end
        return object[index]
    end)
    
    traverser(self:GetData())[segments[#segments]] = value
    self.DataUpdated:Fire(segments, value)
end

function DataController:KnitStart()
    DataService = Knit.GetService("DataService")
    DataService.ForceUpdateData:Connect(function(newdata)
        self.Cached = newdata
        self.DataUpdated:Fire()
    end)
    DataService.DataUpdated:Connect(function(path, value)
        path = string.gsub(path, "/", ".")
        local segments = splitRemoveEmpty(path, ".")
        local folder, key = table.move(segments, 1, #segments-1, 1, {}), segments[#segments]
		local f = std.parsePath(folder)(self:GetData())
		if f then
			f[key] = value
        else
            warn(`Tried to update data at a nil path {path}. Creating path. Packets not arriving in order?`)
            local current = self:GetData()
            local currentFolder = current
            for _, segment in folder do
                if not currentFolder[segment] then
                    currentFolder[segment] = {}
                end
                currentFolder = currentFolder[segment]
            end
            currentFolder[key] = value
		end
        
        self.DataUpdated:Fire(segments, value)
    end)
    task.defer(function() self:FetchFromServer() end)
end

function DataController:KnitInit()
    self.DataUpdated = std.Bindable()
end

return DataController