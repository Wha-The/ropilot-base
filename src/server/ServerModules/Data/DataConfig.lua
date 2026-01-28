local IS_STUDIO = game:GetService("RunService"):IsStudio()
local DataStoreConfig = {
	--[[
        Key = "String" -- The main data key, this key must maintain the same in order for player data to remain.
        Main = { -- Main table containing all the data
            Default = {} -- A table with all of the default values (e.g. currencies, level, etc), these values will be visible on the leaderboard.
            System = {} -- A table with systematic values (e.g. exp, plot, etc), these values are for the backend and will not be (directly) visible on the leaderboard.
        }
    ]]
	--

	Key = IS_STUDIO and "StudioStore" or "DataStore",
	Main = {
		AllTime = {
			Cash = 0
		},
		Default = {
			Cash = 0,
		},
		System = {
			Flags = {},
			Settings = {},
			RedeemedCodes = {},
			OwnedGamepasses = {},
		},
	},
}

return DataStoreConfig
