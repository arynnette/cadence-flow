local DataStoreService = game:GetService("DataStoreService")
local SettingsDatabase = DataStoreService:GetDataStore("ScoreDatabase")
local DatastoreSerializer = require(game.ReplicatedStorage.Serialization.Datastore)
local Network = require(game.ReplicatedStorage.Network)
local AssertType = require(game.ReplicatedStorage.Shared.AssertType)

local function getPlayerSettingsKey(playerID)
	return string.format("player_settings_playerid(%s)", tostring(playerID))
end

Network.onMessage("SaveSettings", function(player, settings)
	AssertType:is_int(settings.AudioOffset)
	AssertType:is_number(settings.NoteSpeedMultiplier)
	AssertType:is_table(settings.Keybinds)
	for _,itr in pairs(settings.Keybinds) do
		AssertType:is_table(itr)
		for _,itr in pairs(itr) do
			AssertType:is_true(typeof(itr) == "EnumItem")
		end
	end
	
	local playerID = player.UserId

	local saveName = getPlayerSettingsKey(playerID)

	local suc, err = pcall(function()
			local d = DatastoreSerializer:serialize_table(settings)
			SettingsDatabase:UpdateAsync(saveName, function(oldValue)
					return d
			end)
	end)

	if not suc then
			warn(err)
	end
end)

Network.onRequest("RetrieveSettings", function(player)
	local toReturn = {}
	local playerID = player.UserId
	local saveName = getPlayerSettingsKey(playerID)
	local suc, err = pcall(function()
			toReturn = SettingsDatabase:GetAsync(saveName)
	end)

	return toReturn
end)
