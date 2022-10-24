--<< Functions >>--
local function CreateLoadstring(gameName, placeIds, loadstring)
    return (function() -- I do this because I am bored :P
        placeIds = placeIds or {}

        print("Running ", gameName)
        for index, placeId in ipairs(placeIds) do
            if (placeId == 0) then
                loadstring(game:HttpGet(loadstring))()
                break
            end
    
            if (game.PlaceId == placeId) then
                loadstring(game:HttpGet(loadstring))()
            end
        end
    end)
end


--<< Main Code >>--
CreateLoadstring("Universal", {0}, "https://raw.githubusercontent.com/Ausicius/AscHub-Roblox/master/games/!universal.lua")()