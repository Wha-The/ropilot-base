local std = {}
shared.std = std

-- need to be careful: if an std module wants to access another std module,
-- there may be a chance that the other std module is not loaded yet.
-- this module should be able to work around it though

local skeleton = {}
-- construct the std object: require
local indexSubmodules; function indexSubmodules(index, parent)
	for _, child in parent:GetChildren() do
		if child:IsA("ModuleScript") then
			index[child.Name] = child
		elseif child:IsA("Folder") then
			index[child.Name] = {}
			indexSubmodules(index[child.Name], child)
		end
	end
end
indexSubmodules(skeleton, script.Parent:WaitForChild("std"))

-- dynamically require std modules as they are being indexed
local applyMeta; function applyMeta(index, skeleton)
	local index_to_require = {}

	for name, child in skeleton do
		if typeof(child) == "table" then
			index[name] = setmetatable({}, {
				__index = function(self, key)
					local module = child[key]
					if typeof(module) == "table" then
						self[key] = {}
						applyMeta(self[key], module)
						return self[key]
					else
						assert(module, `Trying to import non module ${key} from ${name}`)
						self[key] = require(module)
						return self[key]
					end
				end
			})
			applyMeta(index[name], child)
		else
			index_to_require[name] = child
		end
	end

	if next(index_to_require) then
		setmetatable(index, {
			__index = function(self, key)
				local module = index_to_require[key]
				assert(module, `Trying to import non module {key} from (unable to determine origin) (module is {module})`)
				self[key] = require(module)
				return self[key]
			end
		})
	end
end

applyMeta(std, skeleton)
return std
