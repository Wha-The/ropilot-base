--@index
local EffectsIndex = {}
local addChildrenRecursive
addChildrenRecursive = function(index, parent)
    for _, child in parent:GetChildren() do
        if child:IsA("ModuleScript") then
            index[child.Name] = require(child)
        elseif child:IsA("Folder") then
            index[child.Name] = {}
        end
        if index[child.Name] then
            addChildrenRecursive(index[child.Name], child)
        end
    end
end

addChildrenRecursive(EffectsIndex, script.Parent:WaitForChild("index"))
return EffectsIndex