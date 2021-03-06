local SongDatabase = require(game.ReplicatedStorage.RobeatsGameCore.SongDatabase)

local Rating = {}

function Rating:get_rating_from_accuracy(song_key, accuracy, rate)
    rate = rate or 1

    local difficulty = SongDatabase:get_data_for_key(song_key).AudioDifficulty
    local ratemult = 1

	if rate then
		if rate >= 1 then
			ratemult = 1 + (rate-1) * 0.6
		else
			ratemult = 1 + (rate-1) * 2
		end
	end

	return ratemult * ((accuracy/97)^4) * difficulty
end

return Rating
