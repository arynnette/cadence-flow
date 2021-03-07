--[[
    Server-sided map adder. Live-adds maps into the game.

    Credit: kisperal
]]

local RunService = game:GetService("RunService")
local FlashEvery = require(game.ReplicatedStorage.Shared.FlashEvery)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local TryRequire = require(game.ReplicatedStorage.Shared.TryRequire)

local RetrieveSongsFlash = FlashEvery:new(15)

local InsertService = game:GetService("InsertService")

local function requestMaps()
    local song_maps = InsertService:LoadAsset(6485121344)
    local song_maps_folder = song_maps.SongMaps
    song_maps_folder.Parent = nil
    song_maps_folder.Name = "SongMaps"
    song_maps:Destroy()
    return song_maps_folder
end

RunService.Heartbeat:Connect(function(dt)
    local dt_scale = CurveUtil:DeltaTimeToTimescale(dt)

    RetrieveSongsFlash:update(dt_scale)

    if RetrieveSongsFlash:do_flash() then
        local newMaps = requestMaps()

        local newMapsChildren = newMaps:GetChildren()

        for _, map in pairs(newMapsChildren) do
            local wasFound = false
            for _, map2 in pairs(workspace.SongMaps:GetChildren()) do
                if SPUtil:shallow_equal(TryRequire(map), TryRequire(map2), true) then
                    wasFound = true
                    break
                end
            end 

            if not wasFound then
                map.Parent = workspace.SongMaps
            end
        end
    end
end)

local maps = requestMaps()

maps.Parent = workspace
