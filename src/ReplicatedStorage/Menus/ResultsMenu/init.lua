local MenuBase = require(game.ReplicatedStorage.Menus.System.MenuBase)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)
local Grade = require(game.ReplicatedStorage.RobeatsGameCore.Enums.Grade)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local Rating = require(game.ReplicatedStorage.RobeatsGameCore.Enums.Rating)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local TweenService = game:GetService("TweenService")

local debug_message = [[
	Score Finished!

	Play Rating: %0.2f
]]

local Animation = require(script.Animation)

local ResultsMenu = {}

function ResultsMenu:new(_local_services, _score_data)
	local self = MenuBase:new()
	local _results_menu_ui

	local _should_remove = false
	
	local _animation

	local judgement_to_color = {
		[0] = Color3.fromRGB(255, 0, 0);
		[1] = Color3.fromRGB(190, 10, 240);
		[2] = Color3.fromRGB(56, 10, 240);
		[3] = Color3.fromRGB(7, 232, 74);
		[4] = Color3.fromRGB(252, 244, 5);
		[5] = Color3.fromRGB(255, 255, 255);
	}
	
	function self:cons()
		_results_menu_ui = EnvironmentSetup:get_menu_protos_folder().ResultsMenuUI:Clone()

		local play_rating = Rating:get_rating_from_accuracy(_score_data._song_key, _score_data.accuracy)
		local song_length = SongDatabase:get_song_length_for_key(_score_data._song_key)

		DebugOut:puts(debug_message, play_rating)

		local statistics = _results_menu_ui.Statistics
		statistics.Accuracy.Count.Text = string.format("%0.2f%%", _score_data.accuracy*100)
		statistics.MaxCombo.Count.Text = string.format("%0dx", _score_data.max_combo)
		statistics.PlayRating.Count.Text = string.format("%0.2f", play_rating)
		
		local graph = _results_menu_ui.Graph
		
		local mean = 0
		
		for _, hit in ipairs(_score_data.hits) do
			local x = hit.hit_object_time / song_length
			local y = SPUtil:inverse_lerp(-250, 250, hit.time_left)
			
			local dot = Instance.new("Frame")
			dot.Size = UDim2.fromOffset(2, 2)
			dot.Position = UDim2.fromScale(x, y)
			dot.BackgroundColor3 = judgement_to_color[hit.judgement]
			dot.BorderSizePixel = 0
			
			dot.Parent = graph.Frame
			
			mean += hit.time_left
		end
		
		mean /= #_score_data.hits

		statistics.Mean.Count.Text = string.format("%0.2f ms", mean)
		statistics.GhostTaps.Count.Text = string.format("%0dx", _score_data.ghost_taps)

		local judgement = _results_menu_ui.Judgement
		judgement.Marvelous.Count.Text = _score_data.marv_count
		judgement.Perfect.Count.Text = _score_data.perf_count
		judgement.Great.Count.Text = _score_data.great_count
		judgement.Good.Count.Text = _score_data.good_count
		judgement.Bad.Count.Text = _score_data.bad_count
		judgement.Miss.Count.Text = _score_data.miss_count

		local total_count = _score_data.marv_count +
			_score_data.perf_count + 
			_score_data.great_count +
			_score_data.good_count + 
			_score_data.bad_count + 
			_score_data.miss_count

		judgement.Marvelous.Bar.Fill.Size = UDim2.fromScale(_score_data.marv_count/total_count, 1)
		judgement.Marvelous.Bar.Fill.Visible = _score_data.marv_count ~= 0

		judgement.Perfect.Bar.Fill.Size = UDim2.fromScale(_score_data.perf_count/total_count, 1)
		judgement.Perfect.Bar.Fill.Visible = _score_data.perf_count ~= 0

		judgement.Great.Bar.Fill.Size = UDim2.fromScale(_score_data.great_count/total_count, 1)
		judgement.Great.Bar.Fill.Visible = _score_data.great_count ~= 0

		judgement.Good.Bar.Fill.Size = UDim2.fromScale(_score_data.good_count/total_count, 1)
		judgement.Good.Bar.Fill.Visible = _score_data.good_count ~= 0

		judgement.Bad.Bar.Fill.Size = UDim2.fromScale(_score_data.bad_count/total_count, 01)
		judgement.Bad.Bar.Fill.Visible = _score_data.bad_count ~= 0

		judgement.Miss.Bar.Fill.Size = UDim2.fromScale(_score_data.miss_count/total_count, 1)
		judgement.Miss.Bar.Fill.Visible = _score_data.miss_count ~= 0

		_results_menu_ui.NextButton.MouseButton1Click:Connect(function()
			_should_remove = true
		end)

		_animation = Animation.new(_results_menu_ui)
	end
	
	--[[Override--]] function self:should_remove()
		return _should_remove
	end
	
	--[[Override--]] function self:do_remove()
		_animation:Stop()
		_results_menu_ui:Destroy()
	end
	
	--[[Override--]] function self:set_is_top_element(val)
		if val then
			EnvironmentSetup:set_mode(EnvironmentSetup.Mode.Menu)
			_results_menu_ui.Parent = EnvironmentSetup:get_player_gui_root()

			coroutine.wrap(function()
				_animation:Start(_score_data.score)
			end)()

			_results_menu_ui.Size = UDim2.fromScale(3, 3)

			local info = TweenInfo.new(3.5)

			TweenService:Create(_results_menu_ui, info, {
				Size = UDim2.fromScale(1, 1)
			}):Play()
		else
			_results_menu_ui.Parent = nil
			_animation:Stop()
		end
	end
	
	self:cons()
	
	return self
end

return ResultsMenu