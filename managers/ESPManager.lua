--<< Services >>--
local HttpService = game:GetService("HttpService")
local PlayersService = game:GetService("Players")
local RunService = game:GetService("RunService")
local WorkspaceService = game:GetService("Workspace")


--<< Constants >>--
--< Module
local ESPManager

--< PlayersService Descendants
local LocalPlayer = PlayersService.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

--< WorkspaceService Descendants
local CurrentCamera = WorkspaceService.CurrentCamera

--< Others
local drawingTypes = {"Line", "Text", "Image", "Circle", "Square", "Quad", "Triangle"}
shared.RunServiceName = nil
shared.RunServiceName = shared.RunServiceName or "AscHub-" .. HttpService:GenerateGUID(false)
local GetDataName = shared.RunServiceName .. "-GetData"
local UpdateNmae = shared.RunServiceName .. "-Update"


--<< Variables >>--
shared.InstanceData = shared.InstanceData or {}
local lastRefresh = 0
local lastInvalidCheck = 0
local lastRayIgnoreUpdate = 0
local IgnoreList = {}
local RayIgnoreList = {}


--<< Functions >>--
local function IsInArray(array, valueToFind)
    array = array or {}
    valueToFind = valueToFind or "dummy"

    for index, value in pairs(array) do
        if (valueToFind == value) then
            return true
        end
    end

    return false
end

local function NewDrawing(drawingType, properties)
    if (IsInArray(drawingTypes, drawingType)) then
        local DrawingInstance = Drawing.new(drawingType)

        properties = properties or {}

        if (typeof(properties) == "table") then
            for property, value in ipairs(properties) do
                pcall(function()
                    DrawingInstance[property] = value
                end)
            end
        end

        return DrawingInstance
    end
end

local function GetCharacter(player)
    return player.Character
end

local function CheckTeam(player)
    if (player.Neutral) and (LocalPlayer.Neutral) then
        return true
    end

    return player.TeamColor == LocalPlayer.TeamColor
end

local function CheckRay(instance, distance, position, unitDirection)
    local pass = true
    local Model = instance

    if (distance > 999) then
        return false
    end

    if (instance.ClassName == "Player") then
        model = GetCharacter(instance)
    end

    if not (model) then
        model = instance.Parent

        if (model.Parent == workspace) then
            model = instance
        end
    end

    if not (model) then
        return false
    end

    if (tick() - lastRayIgnoreUpdate > 3) then
        lastRayIgnoreUpdate = tick()

        table.clear(RayIgnoreList)
        table.insert(RayIgnoreList, LocalPlayer.Character)
        table.insert(RayIgnoreList, CurrentCamera)

        if (Mouse.TargetFilter) then
            table.insert(RayIgnoreList, Mouse.TargetFilter)
        end

        if (#RayIgnoreList > 64) then
            while #RayIgnoreList > 64 do
                table.remove(IgnoreList, 1)
            end
        end

        for _, value in pairs(IgnoreList) do
            table.insert(RayIgnoreList, value)
        end
    end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = RayIgnoreList

    local raycastResult = WorkspaceService:Raycast(position, unitDirection * distance, raycastParams)

    if (raycastResult) and not (raycastResult.Instance:IsDescendantOf(Model)) then
        pass = false
        if (raycastResult.Instance.Transparency >= .3) or not (raycastResult.Instance.CanCollide) and (raycastResult.Instance.ClassName ~= "Terrain") then
            table.insert(IgnoreList, raycastResult.Instance)
        end
    end
end

local function CheckPlayer(player)
    if not (ESPManager.Settings.Enabled) then
        return false
    end

    local pass = true
    local distance = 0

    local Character = GetCharacter(player)

    if (player ~= LocalPlayer) and (Character) then
        local Head = Character:FindFirstChild("Head")

        if (pass) and (Character) and (Head) then
            distance = (CurrentCamera.CFrame.Position - Head.Position).Magnitude
            if (ESPManager.Settings.VisibleCheck) then
                pass = CheckRay(player, distance, CurrentCamera.CFrame.Position, (Head.Position - CurrentCamera.CFrame.Position).Unit)
            end
            if (distance > ESPManager.Settings.MaxDrawDistance) then
                pass = false
            end
        end
    else
        pass = false
    end

    return pass, distance
end


--<< Main Code >>--
--< Module
ESPManager = {} do
    -- Module Variables
    do
        ESPManager.Library = nil
        ESPManager.RenderList = {Instances = {}}
        ESPManager.InstanceData = shared.InstanceData

        ESPManager.Settings = {
            Enabled = true,
            EnableKeybind = "LeftAlt",
            MaxDrawDistance = 2500,
            RefreshRate = 5,
            TeamCheck = false,
            TeamColor = false,
            VisibleCheck = false,
            Boxes = {
                Show = true,
                Mode = 2,
                FillColor = Color3.fromHSV(0, 0, 1),
                FillThickness = 1,
                FillTransparency = 1,
                OutlineColor = Color3.fromHSV(0, 0, 0),
                OutlineThickness = 4,
                OutlineTransparency = .2,
            }
        }
        ESPManager.IsQuadSupported = false --[[pcall(function()
            Drawing.new("Quad"):Remove()
        end)]]--
    end

    -- Module Functions
    do
        local Settings = ESPManager.Settings

        function ESPManager:SetLibrary(library)
            ESPManager.Library = library
        end

        do -- Instances Functions
            function ESPManager:CreateStaticBox()
                local Box = {Type = "StaticBox"}
    
                local properties = {
                    Fill = {
                        Visible = true,
                        ZIndex = 2,
                        Transparency = Settings.Boxes.FillTransparency,
                        Color = Settings.Boxes.FillColor,
                        Thickness = Settings.Boxes.FillThickness
                    },
                    Outline = {
                        Visible = true,
                        ZIndex = 1,
                        Transparency = Settings.Boxes.OutlineTransparency,
                        Color = Settings.Boxes.OutlineColor,
                        Thickness = Settings.Boxes.OutlineThickness
                    }
                }
    
                if (ESPManager.IsQuadSupported) then
                    Box["Fill"] = NewDrawing("Quad", properties.Fill)
                    Box["Outline"] = NewDrawing("Quad", properties.Outline)
                else
                    Box = {
                        Type = "StaticBox",
                        ["Fill"] = {
                            ["TopLeft"] = nil,
                            ["TopRight"] = nil,
                            ["BottomLeft"] = nil,
                            ["BottomRight"] = nil
                        },
                        ["Outline"] = {
                            ["TopLeft"] = nil,
                            ["TopRight"] = nil,
                            ["BottomLeft"] = nil,
                            ["BottomRight"] = nil
                        }
                    }

                    Box["Fill"]["TopLeft"] = NewDrawing("Line", properties.Fill)
                    Box["Fill"]["TopRight"] = NewDrawing("Line", properties.Fill)
                    Box["Fill"]["BottomLeft"] = NewDrawing("Line", properties.Fill)
                    Box["Fill"]["BottomRight"] = NewDrawing("Line", properties.Fill)
    
                    Box["Outline"]["TopLeft"] = NewDrawing("Line", properties.Outline)
                    Box["Outline"]["TopRight"] = NewDrawing("Line", properties.Outline)
                    Box["Outline"]["BottomLeft"] = NewDrawing("Line", properties.Outline)
                    Box["Outline"]["BottomRight"] = NewDrawing("Line", properties.Outline)
                end
                
                do
                    function Box:Update(CF, size, player)
                        if not (CF) and not (size) and not (player) then
                            return
                        end
    
                        local topLeftPos, visibleTL = CurrentCamera:WorldToViewportPoint((CF * CFrame.new(size.X, size.Y, 0)).Position)
                        local topRightPos, visibleTR = CurrentCamera:WorldToViewportPoint((CF * CFrame.new(-size.X, size.Y, 0)).Position)
                        local bottomLeftPos, visibleBL = CurrentCamera:WorldToViewportPoint((CF * CFrame.new(size.X, -size.Y, 0)).Position)
                        local bottomRightPos, visibleBR = CurrentCamera:WorldToViewportPoint((CF * CFrame.new(-size.X, -size.Y, 0)).Position)
    
                        local _properties = {
                            ["Fill"] = {
                                Transparency = Settings.Boxes.FillTransparency,
                                Color = Color3.fromRGB(255, 255, 255),
                                Thickness = Settings.Boxes.FillThickness
                            },
                            ["Outline"] = {
                                Transparency = Settings.Boxes.OutlineTransparency,
                                Color = Settings.Boxes.OutlineColor,
                                Thickness = Settings.Boxes.OutlineThickness
                            }
                        }
    
                        do
                            if (Settings.TeamCheck) then
                                if (CheckTeam(player)) then
                                    _properties.Fill.Color = Color3.fromRGB(0, 255, 0)
                                else
                                    _properties.Fill.Color = Color3.fromRGB(0, 255, 0)
                                end
                            elseif (Settings.TeamColor) then
                                if (player.TeamColor.Color) then
                                    _properties.Fill.Color = player.TeamColor.Color
                                end
                            elseif not (Settings.TeamCheck) and not (Settings.TeamColor) then
                                _properties.Fill.Color = Settings.Boxes.FillColor
                            end
                        end
    
                        
    
                        if (ESPManager.IsQuadSupported) then
                            local function Update(quadType)
                                local QuadBox = Box[quadType]
        
                                QuadBox.Visible = true
                                QuadBox.PointA = Vector2.new(topLeftPos.X, topLeftPos.Y)
                                QuadBox.PointB = Vector2.new(topRightPos.X, topRightPos.Y)
                                QuadBox.PointC = Vector2.new(bottomRightPos.X, bottomRightPos.Y)
                                QuadBox.PointD = Vector2.new(bottomLeftPos.X, bottomLeftPos.Y)
        
                                for property, value in pairs(_properties[quadType]) do
                                    QuadBox[property] = value
                                end
                            end
    
                            if (visibleTL) and (visibleTR) and (visibleBL) and (visibleBR) then
                                Update("Fill")
                                Update("Outline")
                            else
                                Box["Fill"].Visible = false
                                Box["Outline"].Visible = false
                            end
                        else
                            visibleTL = topLeftPos.Z > 0
                            visibleTR = topRightPos.Z > 0
                            visibleBL = bottomLeftPos.Z > 0
                            visibleBR = bottomRightPos.Z > 0
                            
                            local function Update(visiblePos, corner, fromto)
                                local LineFill = Box["Fill"][corner]
                                local LineOutline = Box["Outline"][corner]
    
                                if (visiblePos) then
                                    LineFill.Visible = true
                                    LineFill.From = fromto[1]
                                    LineFill.To = fromto[2]
    
                                    LineOutline.Visible = true
                                    LineOutline.From = fromto[1]
                                    LineOutline.To = fromto[2]
    
                                    for property, value in pairs(_properties["Fill"]) do
                                        LineFill[property] = value
                                    end
    
                                    for property, value in pairs(_properties["Outline"]) do
                                        LineOutline[property] = value
                                    end
    
                                else
                                    LineFill.Visible = false
                                    LineOutline.Visible = false
                                end
                            end
    
                            Update(visibleTL, "TopLeft", {
                                Vector2.new(topLeftPos.X, topLeftPos.Y),
                                Vector2.new(topRightPos.X, topRightPos.Y)
                            })
                            Update(visibleTR, "TopRight", {
                                Vector2.new(topRightPos.X, topRightPos.Y),
                                Vector2.new(bottomRightPos.X, bottomRightPos.Y)
                            })
                            Update(visibleBL, "BottomLeft", {
                                Vector2.new(bottomLeftPos.X, bottomLeftPos.Y),
                                Vector2.new(topLeftPos.X, topLeftPos.Y)
                            })
                            Update(visibleBR, "BottomRight", {
                                Vector2.new(bottomRightPos.X, bottomRightPos.Y),
                                Vector2.new(bottomLeftPos.X, bottomLeftPos.Y)
                            })
                        end
                    end
    
                    function Box:SetVisibility(boolean)
                        local function UpdateUnQuad(lineType)
                            Box[lineType]["TopLeft"].Visible = boolean
                            Box[lineType]["TopRight"].Visible = boolean
                            Box[lineType]["BottomLeft"].Visible = boolean
                            Box[lineType]["BottomRight"].Visible = boolean
                        end
    
                        if (ESPManager.IsQuadSupported) then
                            Box["Fill"].Visible = boolean
                            Box["Outline"].Visible = boolean
                        else
                            UpdateUnQuad("Fill")
                            UpdateUnQuad("Outline")
                        end
                    end
    
                    function Box:Remove()
                        Box:SetVisibility(false)
    
                        local function UpdateUnQuad(lineType)
                            Box[lineType]["TopLeft"]:Remove()
                            Box[lineType]["TopRight"]:Remove()
                            Box[lineType]["BottomLeft"]:Remove()
                            Box[lineType]["BottomRight"]:Remove()
                        end
    
                        if (ESPManager.IsQuadSupported) then
                            Box["Fill"]:Remove()
                            Box["Outline"]:Remove()
                        else
                            UpdateUnQuad("Fill")
                            UpdateUnQuad("Outline")
                        end
                    end
                end
    
                return Box
            end
    
            function ESPManager:RemoveAllStaticBox()
                for playerName, instancesTable in pairs(ESPManager.InstanceData) do
                    if not (ESPManager.InstanceData[playerName].DontDelete) then
                        for key, value in pairs(instancesTable.Instances) do
                            if (value.Type == "StaticBox") then
                                value:SetVisibility(false)
                                value:Remove()
                                instancesTable.Instances[key] = nil
                            end
                        end
                    end
                end
            end
        end

        function ESPManager:RemoveESP(dedicatedForLoop, playerName, instancesTable)
            dedicatedForLoop = dedicatedForLoop or true

            local function Remove(_playerName, _instancesTable)
                if not (ESPManager.InstanceData[_playerName].DontDelete) then
                    for key, value in pairs(_instancesTable.Instances) do
                        value:SetVisibility(false)
                        value:Remove()
                        _instancesTable.Instances[key] = nil
                    end
                    ESPManager.InstanceData[_playerName] = nil
                end
            end

            if (dedicatedForLoop) then
                for _playerName, _instancesTable in pairs(ESPManager.InstanceData) do
                    Remove(_playerName, _instancesTable)
                end
            else
                Remove(playerName, instancesTable)
            end
        end

        function ESPManager:UpdatePlayerData()
            if (tick() - lastRefresh) > (ESPManager.Settings.RefreshRate / 1000) then
                lastRefresh = tick()
                --[[
                for i, v in pairs(self.RenderList.Instances) do
                    if (v.Instance ~= nil) and (v.Instance.Parent ~= nil) and (v.Instance:IsA("BasePart")) then
                        local data = self.InstanceData[v.Instance:GetDebugId()] or {Instances = {}, DontDelete = true}

                        data.Instance = v.Instance

                        data.Instances
                    end
                end
                ]]--
                for _, player in pairs(PlayersService:GetPlayers()) do
                    local data = ESPManager.InstanceData[player.Name] or {Instances = {}}

                    if (ESPManager.Settings.Boxes.Mode == "Dynamic") then
                        data.Instances["Box"] = data.Instances["Box"] or ESPManager:CreateStaticBox()
                    else
                        data.Instances["Box"] = data.Instances["Box"] or ESPManager:CreateStaticBox()
                    end

                    local Box = data.Instances["Box"]

                    local Character = GetCharacter(player)
                    local pass, distance = CheckPlayer(player)

                    if (pass) and (Character) then
                        local Humanoid = Character:FindFirstChild("Humanoid")
                        local Head = Character:FindFirstChild("Head")
                        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

                        local dead = (Humanoid and Humanoid:GetState().Name == "Dead")
                        
                        if (Character ~= nil) and (Head) and (HumanoidRootPart) and not (dead) then
                            local screenPosition, visible = CurrentCamera:WorldToViewportPoint(Head.Position)
                            local objectPosition = CurrentCamera.CFrame:PointToObjectSpace(Head.Position)

                            if (screenPosition.Z < 0) then
                                local atan = math.atan2(objectPosition.Y, objectPosition.X) + math.pi
                                objectPosition = CFrame.Angles(0, 0, atan):VectorToWorldSpace((CFrame.Angles(0, math.rad(89.9), 0):VectorToWorldSpace(Vector3.new(0, 0, -1))))
                            end

                            local position = CurrentCamera:WorldToViewportPoint(CurrentCamera.CFrame:PointToWorldSpace(objectPosition))

                            if (screenPosition.Z > 0) then
                                local screenPositionUpper = CurrentCamera:WorldToViewportPoint((HumanoidRootPart:GetRenderCFrame() * CFrame.new(0, Head.Size.Y + HumanoidRootPart.Size.Y + 0, 0)).Position)
                                local scale = Head.Size.Y / 2

                                if (ESPManager.Settings.Boxes.Show) and (visible) and (HumanoidRootPart) then
                                    local Body = {
                                        Head,
                                        Character:FindFirstChild("Left Leg")or Character:FindFirstChild("LeftLowerLeg"),
                                        Character:FindFirstChild("Right Leg") or Character:FindFirstChild("RightLowerLeg"),
                                        Character:FindFirstChild("Left Arm")or Character:FindFirstChild("LeftLowerArm"),
                                        Character:FindFirstChild("Right Arm") or Character:FindFirstChild("RightLowerArm")
                                    }
    
                                    Box:Update(HumanoidRootPart.CFrame, Vector3.new(2, 3, 1) * (scale * 2), player)
                                else
                                    Box:SetVisibility(false)
                                end
                            else
                                Box:SetVisibility(false)
                            end
                        else
                            Box:SetVisibility(false)
                        end
                    else
                        Box:SetVisibility(false)
                    end

                    ESPManager.InstanceData[player.Name] = data
                end
            end
        end

        function ESPManager:Update()
            if (tick() - lastInvalidCheck > .3) then
                lastInvalidCheck = tick()

                if (CurrentCamera.Parent ~= workspace) then
                    CurrentCamera = WorkspaceService.CurrentCamera
                end
                
                for playerName, instancesTable in pairs(ESPManager.InstanceData) do
                    if not (PlayersService:FindFirstChild(tostring(playerName))) then
                        ESPManager:RemoveESP(false, playerName, instancesTable)
                        --[[
                        if not (ESPManager.InstanceData[i].DontDelete) then
                            table.foreach(value.Instances, function(i, object)
                                object.Visible = false
                                object:Remove()
                                value.Instances[i] = nil
                            end)
                            ESPManager.InstanceData[i] = nil
                        else
                            if (ESPManager.InstanceData[i].Instance == nil) or (ESPManager.InstanceData[i].Instance.Parent == nil) then
                                table.foreach(value.Instances, function(i, obj)
                                    obj.Visible = false
                                    obj:Remove()
                                    value.Instances[i] = nil
                                end)
                                ESPManager.InstanceData[i] = nil
                            end
                        end
                        ]]--
                    end
                end
            end
        end

        function ESPManager:UnbindFromRenderStep()
            RunService:UnbindFromRenderStep(GetDataName)
            RunService:UnbindFromRenderStep(UpdateNmae)
        end

        function ESPManager:BindToRenderStep()
            ESPManager:UnbindFromRenderStep()

            RunService:BindToRenderStep(GetDataName, 300, ESPManager.UpdatePlayerData)
            RunService:BindToRenderStep(UpdateNmae, 199, ESPManager.Update)
        end

        function ESPManager:CreateESPManager(Tab)
            assert(ESPManager.Library, "You must set ESPManager.Library first before doing this")

            local Groupboxes = {
                MainBox = Tab:AddLeftGroupbox("Main"),
                ESPTypes1 = {
                    Tabbox = Tab:AddLeftTabbox()
                },
                ESPTypes2 = {
                    Tabbox = Tab:AddRightTabbox()
                }
            }
            Groupboxes.ESPTypes1.BoxesBox = Groupboxes.ESPTypes1.Tabbox:AddTab("Boxes")
            Groupboxes.ESPTypes1.ChamsBox = Groupboxes.ESPTypes1.Tabbox:AddTab("Chams")
            Groupboxes.ESPTypes1.TextsBox = Groupboxes.ESPTypes1.Tabbox:AddTab("Texts")
            Groupboxes.ESPTypes2.TracersBox = Groupboxes.ESPTypes2.Tabbox:AddTab("Tracers")
            Groupboxes.ESPTypes2.ArrowsBox = Groupboxes.ESPTypes2.Tabbox:AddTab("Arrows")
            Groupboxes.ESPTypes2.DotsBox = Groupboxes.ESPTypes2.Tabbox:AddTab("Dots")

            local function AssignToggle(index, settingDirectories, func)
                func = func or function() end

                if (#settingDirectories == 1) then
                    Toggles[index]:OnChanged(function()
                        Settings[settingDirectories[1]] = Toggles[index].Value
                        func()
                    end)
                elseif (#settingDirectories == 2) then
                    Toggles[index]:OnChanged(function()
                        Settings[settingDirectories[1]][settingDirectories[2]] = Toggles[index].Value
                        func()
                    end)
                end
            end

            local function AssignOptions(index, settingDirectories, func)
                func = func or function() end

                if (#settingDirectories == 1) then
                    Options[index]:OnChanged(function()
                        Settings[settingDirectories[1]] = Options[index].Value
                        func()
                    end)
                elseif (#settingDirectories == 2) then
                    Options[index]:OnChanged(function()
                        Settings[settingDirectories[1]][settingDirectories[2]] = Options[index].Value
                        func()
                    end)
                end
            end

            -- Main Groupbox
            do
                local Groupbox = Groupboxes.MainBox

                Groupbox:AddDivider()
                
                Groupbox:AddToggle("Settings.Enabled", {
                    Text = "ESP Enabled",
                    Default = Settings.Enabled,
                    Tooltip = "Enable it to enable ESP."
                }):AddKeyPicker("Settings.EnableKeybind", {
                    Text = "ESP Enable Keybind",
                    Default = Settings.EnableKeybind,
                    Mode = "Toggle",
                    SyncToggleState = true,
                    NoUI = false
                })
                Groupbox:AddSlider("Settings.MaxDrawDistance", {
                    Text = "Max Draw Distance",
                    Default = Settings.MaxDrawDistance,
                    Min = 100,
                    Max = 25000,
                    Rounding = 0,
                    Compact = false
                })
                Groupbox:AddSlider("Settings.RefreshRate", {
                    Text = "Refresh Rate",
                    Default = Settings.RefreshRate,
                    Min = 1,
                    Max = 200,
                    Rounding = 0,
                    Compact = false
                })

                Groupbox:AddDivider()

                Groupbox:AddToggle("Settings.TeamColor", {
                    Text = "Team Color",
                    Default = Settings.TeamColor,
                    Tooltip = "Enable it to set players their team color."
                })
                Groupbox:AddToggle("Settings.TeamCheck", {
                    Text = "Team Check",
                    Default = Settings.TeamCheck,
                    Tooltip = "Enable it to make teammates color to green and enemies color to red."
                })
                Groupbox:AddToggle("Settings.VisibleCheck", {
                    Text = "Visible Check",
                    Default = Settings.VisibleCheck,
                    Tooltip = "Enable it to"
                })
                
                do
                    local isChanging = false

                    AssignToggle("Settings.Enabled", {"Enabled"}, function()
                        if (Toggles["Settings.Enabled"].Value) then
                            ESPManager:BindToRenderStep()
                        else
                            task.wait(.21)
                            ESPManager:UnbindFromRenderStep()
                        end
                    end)
                    --AssignOptions("Settings.EnableKeybind", {"EnableKeybind"})
                    AssignOptions("Settings.MaxDrawDistance", {"MaxDrawDistance"})
                    AssignOptions("Settings.RefreshRate", {"RefreshRate"})
                    AssignToggle("Settings.TeamColor", {"TeamColor"}, function()
                        if (Toggles["Settings.TeamCheck"].Value) and not (isChanging) then
                            isChanging = true
                            Toggles["Settings.TeamCheck"]:SetValue(false)
                            isChanging = false
                        end
                    end)
                    AssignToggle("Settings.TeamCheck", {"TeamCheck"}, function()
                        if (Toggles["Settings.TeamColor"].Value) and not (isChanging) then
                            isChanging = true
                            Toggles["Settings.TeamColor"]:SetValue(false)
                            isChanging = false
                        end
                    end)
                    AssignToggle("Settings.VisibleCheck", {"VisibleCheck"})
                end
            end

            -- Boxes Groupbox
            do
                local Groupbox = Groupboxes.ESPTypes1.BoxesBox

                Groupbox:AddDivider()

                Groupbox:AddToggle("Settings.Boxes.Show", {
                    Text = "Show Boxes",
                    Default = Settings.Boxes.Show,
                    Tooltip = "Enable it to show boxes type esp."
                })
                Groupbox:AddDropdown("Settings.Boxes.Mode", {
                    Text = "Drawing Mode",
                    Default = Settings.Boxes.Mode,
                    Values = {"Dynamic", "Static"},
                    Multi = false,
                    Tooltip = "Dynamic for dynamic box type or Static for static box type."
                })
                Groupbox:AddLabel("Fill Color"):AddColorPicker("Settings.Boxes.FillColor", {
                    Title = "Box Fill Color Picker",
                    Default = Settings.Boxes.FillColor
                })
                Groupbox:AddSlider("Settings.Boxes.FillThickness", {
                    Text = "Fill Thickness",
                    Default = Settings.Boxes.FillThickness,
                    Min = 1,
                    Max = 5,
                    Rounding = 1,
                    Compact = false
                })
                Groupbox:AddSlider("Settings.Boxes.FillTransparency", {
                    Text = "Fill Transparency",
                    Default  = Settings.Boxes.FillTransparency,
                    Min = 0,
                    Max = 1,
                    Rounding = 2,
                    Compact = false
                })
                Groupbox:AddLabel("Outline Color"):AddColorPicker("Settings.Boxes.OutlineColor", {
                    Title = "Box Outline Color Picker",
                    Default = Settings.Boxes.OutlineColor
                })
                Groupbox:AddSlider("Settings.Boxes.OutlineThickness", {
                    Text = "Outline Thickness",
                    Default = Settings.Boxes.OutlineThickness,
                    Min = 1,
                    Max = 5,
                    Rounding = 1,
                    Compact = false
                })
                Groupbox:AddSlider("Settings.Boxes.OutlineTransparency", {
                    Text = "Outline Transparency",
                    Default  = Settings.Boxes.OutlineTransparency,
                    Min = 0,
                    Max = .2,
                    Rounding = 2,
                    Compact = false
                })

                do
                    AssignToggle("Settings.Boxes.Show", {"Boxes", "Show"})
                    AssignOptions("Settings.Boxes.Mode", {"Boxes", "Mode"}, function()
                        if (Options["Settings.Boxes.Mode"].Value == "Dynamic") then
                            ESPManager:RemoveAllStaticBox()
                        elseif (Options["Settings.Boxes.Mode"].Value == "Static") then
                        end
                    end)
                    AssignOptions("Settings.Boxes.FillColor", {"Boxes", "FillColor"})
                    AssignOptions("Settings.Boxes.FillThickness", {"Boxes", "FillThickness"})
                    AssignOptions("Settings.Boxes.FillTransparency", {"Boxes", "FillTransparency"})
                    AssignOptions("Settings.Boxes.OutlineColor", {"Boxes", "OutlineColor"})
                    AssignOptions("Settings.Boxes.OutlineThickness", {"Boxes", "OutlineThickness"})
                    AssignOptions("Settings.Boxes.OutlineTransparency", {"Boxes", "OutlineTransparency"})
                end
            end

            return Groupboxes
        end
    end
end

return ESPManager