local GuiService = game:GetService("GuiService")
--<< Services >>--


--<< Constants >>--
--< Module
local GUIManager

--< Others
local LinoriaRepository = "https://raw.githubusercontent.com/wally-rblx/LinoriaLib/main/"
local LinoriaGUILibrary = loadstring(game:HttpGet(LinoriaRepository .. "Library.lua"))()
local LinoriaSaveManager = loadstring(game:HttpGet(LinoriaRepository .. "addons/SaveManager.lua"))()

local AscHubRepository = "https://raw.githubusercontent.com/Ausicius/AscHub-Roblox/master/"
local AscHubESPManager = loadstring(game:HttpGet(AscHubRepository .. "managers/ESPManager.lua"))()
local AscHubThemeManager = loadstring(game:HttpGet(AscHubRepository .. "managers/ThemeManager.lua"))()


--<< Main Code >>--
GUIManager = {} do
    -- Module Variables
    do
        GUIManager.LinoriaGUILibrary = LinoriaGUILibrary
        GUIManager.AscHubESPManager = AscHubESPManager
        --GUIManager.UnloadFuncConnection = nil
    end

    -- Module Functions
    do
        function GUIManager:BuildSettings(Window, gamefolder)
            local tab = Window:AddTab("Settings")

            local MenuGroup = tab:AddLeftGroupbox("Menu")

            MenuGroup:AddButton("Unload", function()
                self.LinoriaGUILibrary:Unload()
            end)
            MenuGroup:AddLabel("Toggle GUI Keybind"):AddKeyPicker("Settings.ToggleGUIKeybind", {
                Text = "Toggle GUI Key Picker",
                Default = "RightControl",
                NoUI = true
            })
            self.LinoriaGUILibrary.ToggleKeybind = Options["Settings.ToggleGUIKeybind"]
            
            AscHubThemeManager:SetLibrary(self.LinoriaGUILibrary)
            LinoriaSaveManager:SetLibrary(self.LinoriaGUILibrary)

            LinoriaSaveManager:IgnoreThemeSettings()
            LinoriaSaveManager:SetIgnoreIndexes({"Settings.ToggleGUIKeybind"})

            AscHubThemeManager:SetFolder("AscHub")
            LinoriaSaveManager:SetFolder("AscHub/" .. tostring(gamefolder))

            AscHubThemeManager:ApplyToTab(tab)
            LinoriaSaveManager:BuildConfigSection(tab)

            return tab, MenuGroup
        end

        function GUIManager:BuildESP(tab)
            AscHubESPManager:SetLibrary(self.LinoriaGUILibrary)
            local Groupboxes = AscHubESPManager:CreateESPManager(tab)
            return Groupboxes
        end

        function GUIManager:CreateWindow(name)
            local Window = LinoriaGUILibrary:CreateWindow({
                Title = tostring("AscHub - " .. name),
                Center = true,
                AutoShow = true,
                Size = UDim2.new(0, 550, 0, 610)
            })

            return Window
        end

        function GUIManager:SetUnloadFunction(func)
            func = func or function() end

            self.LinoriaGUILibrary:OnUnload(function()
                self.LinoriaGUILibrary.Unloaded = true
                func()
            end)
        end
    end
end

return GUIManager