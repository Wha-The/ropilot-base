--@index
local MenuEffects = {}
local addChildrenRecursive
function addChildrenRecursive(index, parent)
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

addChildrenRecursive(MenuEffects, script.Parent:WaitForChild("index"))
return MenuEffects