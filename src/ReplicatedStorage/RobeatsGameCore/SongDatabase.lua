local SPList = require(game.ReplicatedStorage.Shared.SPList)
local SPDict = require(game.ReplicatedStorage.Shared.SPDict)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local SongErrorParser = require(game.ReplicatedStorage.RobeatsGameCore.SongErrorParser)

local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)

local SongMaps = workspace:WaitForChild("SongMaps")

local SongDatabase = {}

local invalid_require_error_message = [[
	There is an error in one of the song modules!
	Usually this is caused by a wacky require call in the module (this should never happen), or because there is no return statement at the end of the song module (song modules should end with "return rtv").

	If there is still an issue please contact one of the game's maintainers.

	Stack trace:

	%s
]]

SongDatabase.SongMode = {
	Normal = 0;
	SupporterOnly = 1;
}

function SongDatabase:new()
	local self = {}
	self.SongMode = SongDatabase.SongMode
	self.on_map_added = Instance.new("BindableEvent")
	self.on_map_removed = Instance.new("BindableEvent")

	local _all_keys = SPList:new()

	local function tryrequire(module, on_fail)
		on_fail = on_fail or function() end
		local data
		local suc, err = pcall(function()
			data = require(module)
		end)

		if not suc then
			on_fail(err)
		end

		return data
	end
	
	SongMaps.ChildAdded:Connect(function(child)
		DebugOut:puts("Song added! (filename %s)", child.Name)

		local derived_key = _all_keys:count()+1

		local audio_data = tryrequire(child, function(err)
			DebugOut:puts(invalid_require_error_message, err)
		end)
		
		child:SetAttribute("_key", derived_key)

		if audio_data then
			SongErrorParser:scan_audiodata_for_errors(audio_data)

			_all_keys:push_back(audio_data)
			
			self.on_map_added:Fire(audio_data, derived_key, child)
		end
	end)

	SongMaps.ChildRemoved:Connect(function(child)
		local _key = child:GetAttribute("_key")
		_all_keys:remove_at(_key)	
		self.on_map_removed:Fire(_key, child)
	end)

	function self:cons()
		local song_list = SongMaps:GetChildren()
		for i=1,#song_list do
			local itr_map = song_list[i]
			itr_map:SetAttribute("_key", i)

			local audio_data = tryrequire(itr_map, function(err)
				DebugOut:puts(invalid_require_error_message, err)
			end)

			if audio_data then
				SongErrorParser:scan_audiodata_for_errors(audio_data)
				_all_keys:push_back(audio_data)
			end
		end
	end

	function self:key_itr()
		return ipairs(_all_keys._table)
	end

	function self:get_data_for_key(key)
		return _all_keys:get(key)
	end

	function self:contains_key(key)
		return _all_keys:get(key) ~= nil
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