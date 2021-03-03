local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local CurveUtil = require(game.ReplicatedStorage.Shared.CurveUtil)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local SFXManager = require(game.ReplicatedStorage.RobeatsGameCore.SFXManager)
local InputUtil = require(game.ReplicatedStorage.Shared.InputUtil)
local NoteResultPopupEffect = require(game.ReplicatedStorage.RobeatsGameCore.Effects.NoteResultPopupEffect)
local HoldingNoteEffect = require(game.ReplicatedStorage.RobeatsGameCore.Effects.HoldingNoteEffect)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)

local ScoreManager = {}

function ScoreManager:new(_game)
	local self = {}
	
	local _chain = 0
	function self:get_chain() return _chain end

	local _marvelous_count = 0
	local _perfect_count = 0
	local _great_count = 0
	local _good_count = 0
	local _bad_count = 0
	local _miss_count = 0
	local _max_chain = 0
	function self:get_end_records() return _marvelous_count,_perfect_count,_great_count,_good_count,_bad_count,_miss_count,_max_chain end

	function self:get_total_judgements()
		return _marvelous_count + _perfect_count + _great_count + _good_count + _bad_count
	end

	function self:get_accuracy()
		local total_count = self:get_total_judgements() + _miss_count
		
		return ((_marvelous_count * 1.0) + (_perfect_count * 1.0) + (_great_count * 0.75) + (_good_count * 0.37) + (_bad_count * 0.25)) / total_count
	end

	local _frame_has_played_sfx = false

	function self:register_hit(
		note_result,
		slot_index,
		track_index,
		params
	)
		local track = _game:get_tracksystem(slot_index):get_track(track_index)
		_game._effects:add_effect(NoteResultPopupEffect:new(
			_game,
			track:get_end_position() + Vector3.new(0,0.25,0),
			note_result
		))

		if params.PlaySFX == true then
			
			--Make sure only one sfx is played per frame
			if _frame_has_played_sfx == false then
				if note_result ~= NoteResult.Miss then
					if params.IsHeldNoteBegin == true then
						_game._audio_manager:get_hit_sfx_group():play_first()
					else
						_game._audio_manager:get_hit_sfx_group():play_alternating()
					end
				else
					_game._sfx_manager:play_sfx(SFXManager.SFX_MISS)
				end
				_frame_has_played_sfx = true
			end
			
			--Create an effect at HoldEffectPosition if PlayHoldEffect is true
			if params.PlayHoldEffect then
				if note_result ~= NoteResult.Miss then
					_game._effects:add_effect(HoldingNoteEffect:new(
						_game,
						params.HoldEffectPosition,
						note_result
					))
				end
			end
		end
		
		--Increment stats
		if note_result == NoteResult.Marvelous then
			_marvelous_count += 1
			_chain += 1

		elseif note_result == NoteResult.Perfect then
			_chain += 1
			_perfect_count += 1

		elseif note_result == NoteResult.Great then
			_chain += 1
			_great_count += 1

		elseif note_result == NoteResult.Good then
			_chain += 1
			_good_count += 1

		elseif note_result == NoteResult.Bad then
			_bad_count = _bad_count + 1
		else
			if _chain > 0 then
				_chain = 0
				_miss_count = _miss_count + 1

			elseif params.TimeMiss == true then
				_miss_count = _miss_count + 1
			end
		end

		_max_chain = math.max(_chain,_max_chain)
	end

	function self:update(dt_scale)
		_frame_has_played_sfx = false
	end

	return self
end

return ScoreManager
