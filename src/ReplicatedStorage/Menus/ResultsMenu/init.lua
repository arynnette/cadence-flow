local MenuBase = require(game.ReplicatedStorage.Menus.System.MenuBase)
local EnvironmentSetup = require(game.ReplicatedStorage.RobeatsGameCore.EnvironmentSetup)
local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)

local Animation = require(script.Animation)

local ResultsMenu = {}

function ResultsMenu:new(_local_services, _score_data)
	local self = MenuBase:new()
	local _results_menu_ui

	local _animation

	local _accuracy_marks = {100,95,90,80,70,60,50}
	
	function self:cons()
		_results_menu_ui = EnvironmentSetup:get_menu_protos_folder().ResultsMenuUI:Clone()

		_animation = Animation.new(_results_menu_ui)
	end

	function self:get_formatted_data(data)
		local str = "%.2f%% | %0d / %0d / %0d / %0d"
		return string.format(str, data.accuracy*100, data.perfects, data.greats, data.okays, data.misses)
	end
	
	--[[Override--]] function self:should_remove()
		return _should_remove
	end
	
	--[[Override--]] function self:do_remove()
		_results_menu_ui:Destroy()
	end
	
	--[[Override--]] function self:set_is_top_element(val)
		if val then
			EnvironmentSetup:set_mode(EnvironmentSetup.Mode.Menu)
			_results_menu_ui.Parent = EnvironmentSetup:get_player_gui_root()

			coroutine.wrap(function()
				_animation:Start()
			end)()
		else
			_results_menu_ui.Parent = nil
			_animation:Stop()
		end
	end
	
	self:cons()
	
	return self
end

return ResultsMenu