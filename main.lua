--<< Functions >>--
local function RunAndCheckPlaceID(gameName, placeIds, func)
    placeIds = placeIds or {}
    func = func or function() end

    print("Running", gameName)
    for index, placeId in ipairs(placeIds) do
        if (placeId == 0) then
            func()
            break
        end

        if (game.PlaceId == placeId) then
            func()
        end
    end
end


--<< Main Code >>--
RunAndCheckPlaceID("Universal", {0}, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/uhKeiron/kHub/master/games/!universal.lua"))()
end)
