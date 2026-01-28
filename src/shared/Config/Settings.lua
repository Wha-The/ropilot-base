--[[
    Settings Configuration
    Defines all available settings with their types and default values
]]--

local SettingsConfig = {
    {
        Name = "Music",
        Type = "Switch",
        Path = "/System/Settings/Music",
        Default = true,
        Desc = "Toggle background music on/off"
    },
    {
        Name = "Cash Sound", 
        Type = "Switch",
        Path = "/System/Settings/CashSound",
        Default = true,
        Desc = "Toggle cash sound effects on/off"
    }
}

return SettingsConfig
