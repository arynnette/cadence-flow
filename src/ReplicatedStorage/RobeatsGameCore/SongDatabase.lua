local SPList = require(game.ReplicatedStorage.Shared.SPList)
local SPDict = require(game.ReplicatedStorage.Shared.SPDict)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local SongErrorParser = require(game.ReplicatedStorage.RobeatsGameCore.SongErrorParser)

local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)

local SongMaps = workspace:WaitForChild("SongMaps")

local SongDatabase = {}

SongDatabase.SongMode = {
	Normal = 0;
	SupporterOnly = 1;
}

function SongDatabase:new()
	local self = {}
	self.SongMode = SongDatabase.SongMode
	self.on_map_added = Instance.new("BindableEvent")
	self.on_map_removed = Instance.new("BindableEvent")

	local songs = SongMaps:GetChildren()
	
	SongMaps.ChildAdded:Connect(function(child)
		DebugOut:puts("Song added! (filename %s)", child.Name)

		local derived_key = #songs+1

		local audio_data = require(child)
		SongErrorParser:scan_audiodata_for_errors(audio_data)
		
		child:SetAttribute("_key", derived_key)

		table.insert(songs, child)
		
		self.on_map_added:Fire(audio_data, derived_key, child)
	end)

	SongMaps.ChildRemoved:Connect(function(child)
		local _key = child:GetAttribute("_key")
		table.remove(songs, _key)

		self.on_map_removed:Fire(_key, child)
	end)

	function self:cons()
		local song_list = SongMaps:GetChildren()
		for i=1,#song_list do
			local itr_map = song_list[i]
			itr_map:SetAttribute("_key", i)

			local audio_data = require(itr_map)
			SongErrorParser:scan_audiodata_for_errors(audio_data)
		end
	end

	function self:key_itr()
		return pairs(songs)
	end

	function self:get_data_for_key(key)
		return require(songs[key])
	end

	function self:contains_key(key)
		return songs[key] ~= nil
	end

	function self:key_get_audiomod(key)
		local data = self:get_data_for_key(key)
		if data.AudioMod == 1 then
			return SongDatabase.SongMode.SupporterOnly
		end
		return SongDatabase.SongMode.Normal
	end

	function self:render_coverimage_for_key(cover_image, overlay_image, key)
		local songdata = self:get_data_for_key(key)
		cover_image.Image = songdata.AudioCoverImageAssetId

		local audiomod = self:key_get_audiomod(key)
		if audiomod == SongDatabase.SongMode.SupporterOnly then
			overlay_image.Image = "rbxassetid://837274453"
			overlay_image.Visible = true
		else
			overlay_image.Visible = false
		end
	end

	function self:get_title_for_key(key)
		local songdata = self:get_data_for_key(key)
		return songdata.AudioFilename
	end

	function self:get_artist_for_key(key)
		local songdata = self:get_data_for_key(key)
		return songdata.AudioArtist
	end

	function self:get_difficulty_for_key(key)
		local songdata = self:get_data_for_key(key)
		return songdata.AudioDifficulty
	end

	function self:get_description_for_key(key)
		local songdata = self:get_data_for_key(key)
		return songdata.AudioDescription
	end

	function self:get_song_length_for_key(key)
		local data = self:get_data_for_key(key)
		local hit_ob = data.HitObjects
		
		local len = 0

		for _, hit_object in pairs(hit_ob) do
			len = math.max(hit_object.Time + (hit_object.Duration or 0), len)
		end
		
		return len
	end
	
	function self:invalid_songkey() return -1 end

	self:cons()
	return self
end

return SongDatabase:new()