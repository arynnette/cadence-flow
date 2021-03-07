local InsertService = game:GetService("InsertService")

local song_maps = InsertService:LoadAsset(6485121344)
local song_maps_folder = song_maps.SongMaps

song_maps_folder.Parent = workspace
song_maps_folder.Name = "SongMaps"

song_maps:Destroy()
