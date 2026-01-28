local quickRay = function(origin: Vector3, direction: Vector3, paramFilter, fn)
    
    local params
    if typeof(paramFilter) == nil then -- RaycastParams = nil? roblox...
        params = paramFilter
    else
        params = RaycastParams.new()
        if typeof(paramFilter) == "function" then
            paramFilter(params)
        end
    end

    local raycast
    if fn then
        raycast = fn(workspace, origin, direction, params)
    else
        raycast = workspace:Raycast(origin, direction, params)
    end

    local RaycastResult = {}
    RaycastResult.Position = raycast and raycast.Position or (origin + direction)
    RaycastResult.Normal = raycast and raycast.Normal or Vector3.zero
    RaycastResult.Instance = raycast and raycast.Instance
    RaycastResult.Success = raycast ~= nil
    return RaycastResult
end
return quickRay