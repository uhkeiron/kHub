--<< Services >>--
local PlayersService = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")


--<< Constants >>--
local repository = "https://raw.githubusercontent.com/uhkeiron/kHub/master/"
local Library


--<< Managers >>--
local GUIManager = loadstring(game:HttpGet(repository .. "managers/GUIManager.lua"))()


--<< Main Code >>
Library = GUIManager.LinoriaGUILibrary

local Window = GUIManager:CreateWindow("Universal") --MarketplaceService:GetProductInfo(game.PlaceId).Name
local Tabs = {
    ["ESP"] = {
        Tab = Window:AddTab("ESP"),
    },
    ["Settings"] = {
        Tab = nil
    }
}

Tabs["ESP"].Groupboxes = GUIManager:BuildESP(Tabs["ESP"].Tab)
Tabs["Settings"].Tab = GUIManager:BuildSettings(Window, "Universal")
GUIManager:SetUnloadFunction(function()
    GUIManager.AscHubESPManager:UnbindFromRenderStep()
    GUIManager.AscHubESPManager:RemoveESP()
    Tabs = {}
end)
