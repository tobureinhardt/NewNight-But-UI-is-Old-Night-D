local Night: {[string]: any} = getgenv().Night
local DefaultConfig: {[string]: any} = {
    ConfigName = "Default",
    Modules = {},
    Sliders = {},
    ColorSliders = {},
    Dropdowns = {},
    TextBoxes = {},
    Keybinds = {},
    MiniToggles = {},
    Others = {
        MobileButtonPosition = {},
        TabData = {}
    }
}

local function DeepClone(Clone: {[any]: any})
    local RealClone = table.clone(Clone)
    for i,v in RealClone do
        if typeof(v) == "table" then
            RealClone[i] = DeepClone(v)
        end
    end

    return RealClone
end

Night.CurrentConfig = DeepClone(DefaultConfig)
local cloneref = cloneref or function(Reference: Instance): Instance
    return Reference
end

local Players : Players = cloneref(game:GetService("Players"))
local TweenService : TweenService = cloneref(game:GetService("TweenService"))
local HttpService : HttpService = cloneref(game:GetService("HttpService"))
local Workspace : Workspace = cloneref(game:GetService("Workspace"))
local UserInputService : UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))

local RequestFunc = (request or http and http.request)
local Camera: Camera = Workspace.CurrentCamera
local LocalPlayer : Player = Players.LocalPlayer

local Assets = {}
local UIData = {
    UIOpen = false,
    Windows = {
        Windows = {},
        Dragging = nil :: Frame?,
        DraggingSpeed = 0.05
    },
    TargetHud = nil,
    DashButtons = {},
    MobileButtons = {},
    Notifications = {},
    ConfigButtons = {},
    ArrayListEntries = {},
    CustomizableItems = {
        Modules = {} :: {any},
        Other = {} :: {any}
    },
    Theme = {
        ModuleTheme = {Color3.fromRGB(26, 95, 181), Color3.fromRGB(21, 80, 152)},
        Other = Color3.fromRGB(26, 95, 181)
    },
    NotificationsSettings = {
        All = true,
        Modules = true,
        Other = true,
        Alignment = "Bottom"
    },
    Icons = {
        Configs = "rbxassetid://8992031246" :: string,
        Close = "rbxassetid://17895651193" :: string,
        Settings = "rbxassetid://8992031056" :: string,
        TabSettings = "rbxassetid://75988696107576" :: string,
        Arrow = "rbxassetid://11421095840" :: string,
        Config = "rbxassetid://8992030918" :: string,
        Trash = "rbxassetid://10747362241" :: string,
        Combat = "rbxassetid://104133331585248" :: string,
        Movement = "rbxassetid://121899433518557" :: string,
        Render = "rbxassetid://127386420152841" :: string,
        Utility = "rbxassetid://110186208471082" :: string,
        Premium = "rbxassetid://94522713973114" :: string
    },
    Fonts = {
        BuilderExtended = {Checked = false, Font = "rbxassetid://16658237174"},
        BuilderSans = {Checked = true, Font = "rbxasset://fonts/families/BuilderSans.json"},
        BuilderMono = {Checked = false, Font = "rbxassetid://16658246179"}
    },
    InputFuncs = {
        Changed = function(Input: InputObject) end,
        Ended = function(Input: InputObject) end
    }
}

    Night.Scale = 0.5
    Night.OnUninject = Instance.new("BindableEvent")

    Night.UIData = UIData
    Night.Assets = Assets

local UIScale: UIScale = Instance.new("UIScale")
UIScale.Scale = Night.Scale

do
    Assets.Functions = {}
    Assets.Functions.cloneref = cloneref
    Assets.Functions.DeepClone = DeepClone
    Assets.Functions.clonefunction = clonefunction or function(func: () -> ()) : () -> ()
        return func
    end

    Assets.Functions.gethui = gethui or function(): PlayerGui?
        return LocalPlayer:FindFirstChildWhichIsA("PlayerGui")
    end

    Assets.Functions.newcclosure = newcclosure and Assets.Functions.clonefunction(newcclosure) or function(func: () -> ())
        return func
    end

    function Assets.Functions:SearchTable(Search: {}, Value: any, Searched: {}, Results: {})
        Searched = Searched or {}
        Results = Results or {}

        for i,v in next, Search do
            if typeof(v) == "table" then
                if not table.find(Searched, v) then
                    table.insert(Searched, v)
                    Assets.Functions:SearchTable(v, Value, Searched, Results)
                end
            else
                local OldMT = nil
                if typeof(v) == "userdata" and getrawmetatable and getrawmetatable(v) and setrawmetatable then
                    OldMT = getrawmetatable(v)
                    setrawmetatable(v, {})
                end

                if tostring(v):lower() == Value then
                    table.insert(Results, v)
                else
                    if OldMT then
                        setrawmetatable(v, OldMT)
                    end
                end
            end

            if typeof(i) == "table" then
                if not table.find(Searched, i) then
                    table.insert(Searched, i)
                    Assets.Functions:SearchTable(i, Value, Searched, Results)
                end
            else
                local OldMT = nil
                if typeof(i) == "userdata" and getrawmetatable and getrawmetatable(i) and setrawmetatable then
                    OldMT = getrawmetatable(i)
                    setrawmetatable(i, {})
                end

                if tostring(i):lower() == Value then
                    table.insert(Results, i)
                else
                    if OldMT then
                        setrawmetatable(i, OldMT)
                    end
                end
            end
        end
        
        return Results
    end

    function Assets.Functions:IsAlive(Player: Player | Model, IsCharacter: boolean?): boolean
        if (not IsCharacter and Player and Player.Character) or IsCharacter then
            local Char: Model = Player
            if not IsCharacter then
                Char = Char.Character
            end

            local Humanoid = Char:FindFirstChild("Humanoid") :: Humanoid
            if Humanoid and (Humanoid:GetState() ~= Enum.HumanoidStateType.Dead or Humanoid.Health > 0.05) then
                if Char.PrimaryPart then
                    return true
                end
            end
        end

        return false
    end

    function Assets.Functions:GetDistanceFrom(Point: Vector3, To: Vector3, IgnoreY: boolean?): number
        if not IgnoreY then
            return (Point - To).Magnitude
        else
            return (Point - Vector3.new(To.X, Point.Y, To.Z)).Magnitude
        end
    end

    function Assets.Functions:GetClosestPlayer(Data: {Player: Player, TeamCheck: boolean?}): { Distance: number, Player: Player? }
        local RealData = {
            Player = nil,
            Distance = math.huge
        }

        if not Data.Player then
            Data.Player = LocalPlayer
        end

        if Assets.Functions:IsAlive(Data.Player) then
            for i,v : Player in Players:GetPlayers() do
                if Assets.Functions:IsAlive(v) and v ~= LocalPlayer and (Data.TeamCheck and v.Team and v.Team ~= Data.Player.Team or not v.Team or not Data.TeamCheck) then
                    local Root: BasePart = v.Character.PrimaryPart
                    local PlayerRoot: BasePart = Data.Player.Character.PrimaryPart

                    local Distance: number = Assets.Functions:GetDistanceFrom(PlayerRoot.Position, Root.Position)
                    if RealData.Distance >= Distance then
                        RealData = {
                            Player = v,
                            Distance = Distance
                        }
                    end
                end
            end
        end

        return RealData
    end

    function Assets.Functions:GetNerestPlayerToMouse(Data: {TeamCheck: boolean, Distance: number?, Exclude: {}?, Extras: {}?, Targets: {Players: boolean, Npcs: boolean}?}): { DistanceFromMouse: number, DistanceFromPlayer: number, Player: Player?, Character: Model?}
        local RealData = {
            Character = nil,
            Player = nil,
            DistanceFromMouse = math.huge,
            DistanceFromPlayer = math.huge
        }

        if not Data.Exclude then 
            Data.Exclude = {}
        end

        if not Data.Targets then
            Data.Targets = {
                Players = true,
                Npcs = true
            }
        end

        if not Data.Distance then
            Data.Distance = math.huge
        end

        local AllEntities = {}
        for i,v in Players:GetPlayers() do
            table.insert(AllEntities, v.Character)
        end

        if Data.Extras then
            for i,v in Data.Extras do
                table.insert(AllEntities, v)
            end
        end

        local Mouse: Mouse = LocalPlayer:GetMouse()
        if Mouse and Assets.Functions:IsAlive(LocalPlayer) then 
            for i,v : Model? in AllEntities do
                if Assets.Functions:IsAlive(v, true) and not table.find(Data.Exclude, v) then
                    local Player: Player = Players:GetPlayerFromCharacter(v)
                    if ((Data.Targets.Players and Player) or (Data.Targets.Npcs and not Player)) then
                        if Player and table.find(Data.Exclude, Player) then
                            continue
                        end

                        if Data.TeamCheck and (not Player or not Player.Team or Player.Team == LocalPlayer.Team) then
                            continue
                        end

                        local Root: BasePart = v.PrimaryPart
                        local MousePos: Vector3 = Mouse.Hit.Position
                        local MouseDistance: number = Assets.Functions:GetDistanceFrom(MousePos, Root.Position)
                        local PlayerDistance: number = Assets.Functions:GetDistanceFrom(LocalPlayer.Character.PrimaryPart.Position, Root.Position)

                        if RealData.DistanceFromMouse >= MouseDistance and Data.Distance >= MouseDistance then
                            RealData = {
                                Character = v,
                                Player = Player,
                                DistanceFromMouse = MouseDistance,
                                DistanceFromPlayer = PlayerDistance
                            }
                        end
                    end
                end
            end
        end

        return RealData
    end

    function Assets.Functions:GetTextBounds(Text: string, Font: Font, Size: number): Vector2
        local Params = Instance.new("GetTextBoundsParams")
        Params.Text = Text
        Params.Font = Font
        Params.Size = Size
        Params.Width = 1e9
        Params.RichText = false
        
        return TextService:GetTextBoundsAsync(Params)
    end

    function Assets.Functions:ConvertColor3toInt(RGB: Color3): {B: number, G: number, R: number}
        local R: number = math.floor(RGB.R * 255)
        local G: number = math.floor(RGB.G * 255)
        local B: number = math.floor(RGB.B * 255)

        return {R = R, G = G, B = B}
    end

    function Assets.Functions:LoadAsset(Name: string): string
        local path = "NewNight/Assets/Icons/"..Name..".png"
        local icon = ""
        if isfile and isfile(path) and getcustomasset then
            icon = getcustomasset(path)
        elseif UIData.Icons[Name] then
            icon = UIData.Icons[Name]
        end

        if not icon then
            if Name:find("rbxasset") or  Name:find("roblox.com") then
                icon = Name
            end
        end
        return icon
    end

    function Assets.Functions:GetFont(Name: string, Faces: {{Name: string, Weight: number, File: string}}): string
        local Font = UIData.Fonts[Name]
        if Font and Font.Checked or not getcustomasset or not writefile then
            return Font.Font
        end

        local FontFamily = {name = Name, faces = {}}
        for i,v in Faces do
            local FontPath = "NewNight/Assets/Fonts/"..v.File..".otf"
            if isfile and isfile(FontPath) then
                local Face = {
                    name = v.Name,
                    weight = v.Weight,
                    style = "normal",
                    assetId = getcustomasset(FontPath),
                }

                table.insert(FontFamily.faces, Face)
            else
                if Font then
                    return Font.Font
                end
            end
        end

        writefile("NewNight/Assets/Fonts/"..Name..".json", HttpService:JSONEncode(FontFamily))
        local id = getcustomasset("NewNight/Assets/Fonts/"..Name..".json")
        UIData.Fonts[Name] = {
            Checked = true,
            Font = id
        }

        return id
    end

    function Assets.Functions:Drag(Data: {Window: Frame, StartInputPos: Vector3, FrameStartPos: UDim2}, input: InputObject?)
        local Viewport : Vector2 = Camera.ViewportSize
        local Delta : Vector2 = Vector2.new(0, 0)
        local MouseStart : Vector3 = Data.StartInputPos
        local FrameStart : UDim2 = Data.FrameStartPos

        if FrameStart then
            if MouseStart and input then
                Delta = (Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(MouseStart.X, MouseStart.Y))
            end

            local XVal: number = FrameStart.X.Scale + (Delta.X / (Viewport.X / (Data.Window.Size.X.Scale + 0.8)))
            local YVal: number = FrameStart.Y.Scale + (Delta.Y / (Viewport.Y / 0.8))

            TweenService:Create(Data.Window, TweenInfo.new(UIData.Windows.DraggingSpeed), {Position = UDim2.fromScale(XVal, YVal)}):Play()
        end
    end

    Assets.Connections = {}
    function Assets.Connections:Add(Connection: RBXScriptConnection | thread | () -> (), AddTo: { {any} }): { Connection: RBXScriptConnection, Disconnect: () -> () }
        AddTo = AddTo or {}
        local ConnectionData = {
            Connection = Connection :: RBXScriptConnection | thread | () -> (),
            Disconnect = nil :: () -> ()?
        }

        if not table.find(AddTo, Night.Connections) then
            table.insert(AddTo, Night.Connections)
        end

        for i,v : {} in AddTo do
            if typeof(v) == "table" and not table.find(v, ConnectionData) then
                table.insert(v, ConnectionData)
            end
        end

        function ConnectionData:Disconnect()
            if typeof(Connection) == "RBXScriptConnection" then
                Connection:Disconnect()
            elseif typeof(Connection) == "thread" then
                task.cancel(Connection)
            elseif typeof(Connection) == "function" then
                Connection()
            end

            task.delay(0.1, function()
                for i,v in AddTo do
                    if typeof(v) == "table" and v ~= Night.Connections then
                        local ConFind = table.find(v, ConnectionData)
                        if ConFind then
                            table.remove(v, ConFind)
                        end
                    end
                end

                table.clear(ConnectionData)
            end)
        end

        return ConnectionData
    end

    function Assets.Functions:Uninject()
        Night.OnUninject:Fire()
    end

    function Assets.Functions:GetTargetHud()
        return {
            Update = function(self, data) end,
            Destroy = function(self) end
        }
    end

    function Assets.Functions:DestroyTargetHud()
    end

    function Assets.Functions:Countdown(time)
        return {
            Update = function(self, text) end,
            Destroy = function(self) end
        }
    end

    function Assets.Functions:DisconnectAll()
        for i,v : {Connection: RBXScriptConnection | thread, Disconnect: (self: any) -> ()} in Night.Connections do
            if v and v.Disconnect then
                v:Disconnect()
            end
        end

        table.clear(Night.Connections)
    end
   
    Assets.Config = {}
    Assets.ArrayList = {}
    function Assets.Config:Save(Data: {}, Path: string, Directories: {}?): boolean
        if not Night.Load.Loaded then return end
        
        local Suc, NewData = pcall(HttpService.JSONEncode, HttpService, Data)
        if not isfolder("NewNight/Configs") then
            makefolder("NewNight/Configs")
        end

        if Suc and NewData and writefile and makefolder then
            if Directories then
                for i,v in Directories do
                    if not isfolder("NewNight/Configs/"..v) then
                        makefolder("NewNight/Configs/"..v)
                    end
                end
            end

            writefile("NewNight/Configs/"..Path..".json", NewData)
            return true
        end

        return false
    end

    function Assets.Config:Load(Config: string): boolean
        local _, NewData = true, DeepClone(DefaultConfig)
        if isfile and isfile("NewNight/Configs/"..Config..".json") and readfile then
            _, NewData = pcall(HttpService.JSONDecode, HttpService, readfile("NewNight/Configs/"..Config..".json"))
        end


        -- sigma ud load 💯💯
        for i,v in NewData do
            if Night.CurrentConfig[i] then
                Night.CurrentConfig[i] = v        
            end
        end

        for i, v in UIData.Windows.Windows do
            if i ~= "MainTabWindow" then
                local Button = UIData.DashButtons[i]
                if Button then
                    if Button.Selected then
                        Button:Toggle(false, false)
                    end
                else
                    if v.Window.Visible then
                        v.Window.Visible = false
                    end
                end

                v.Window.Position = v.Data.Position
            end

            for i2, v2 in v.Modules.Modules do
                local ModuleValue = NewData.Modules[i2]
                if ModuleValue == nil then
                    if v2.Data.Default then
                        ModuleValue = v2.Data.Default
                    else
                        ModuleValue = false
                    end
                end

                v2:ToggleSettings(false)

                -- Only disable the module if it needs to actually turn off,
                -- to avoid the enable→disable→enable cycle that causes
                -- CallingFunction to fire redundantly and override itself.
                if not ModuleValue and v2.Enabled then
                    v2:SetValue(false, false, false)
                end

                for i3, v3 in v2.Settings do
                    local Section = NewData[i3]
                    if Section then
                        for i4, v4 in v3 do
                            if v4.SetValue then
                                local Value = Section[i4]
                                if Value == nil then
                                    if v4.Data.Default then
                                        Value = v4.Data.Default
                                        if typeof(Value) == "Color3" then
                                            Value = Assets.Functions:ConvertColor3toInt(Value)
                                        end
                                    end
                                end

                                if i3 == "Dropdowns" then
                                    v4:ToggleSideMenu(false)
                                elseif i3 == "Keybinds" then
                                    if not Night.Mobile and Value == "Button" then
                                        Value = v4.Data.Default
                                    end
                                end

                                if Value == nil then
                                    Value = false
                                end
                                
                                v4:SetValue(Value, false, true)
                            end
                        end
                    end
                end

                -- Only set the module value if the state actually needs to change
                if ModuleValue ~= v2.Enabled then
                    v2:SetValue(ModuleValue, false, false, true)
                end
            end
        end

        for i,v in NewData.Others do
            if i == "TabData" then
                for i2, v2 in v do
                    local Window = UIData.Windows.Windows[i2]
                    if Window then
                        local Pos = v2.Position
                        local Visible = v2.Visible

                        if Pos then
                            Window.Window.Position = UDim2.fromScale(table.unpack(Pos)) 
                        end

                        local Button = UIData.DashButtons[i2]
                        if Visible then
                            if Button then
                                Button:Toggle(Visible)
                            else
                                Window.Window.Visible = Visible
                            end
                        end
                    end
                end
            end
        end

        task.delay(0.3, function()
            for i,v in UIData.CustomizableItems.Other do
                if v.CanChange then
                    if v.Item:IsA("Frame") or v.ChangeBackground then
                        v.Item.BackgroundColor3 = UIData.Theme.Other
                    elseif v.Item:IsA("ImageButton") or v.Item:IsA("ImageLabel") then
                        v.Item.ImageColor3 = UIData.Theme.Other
                    elseif v.Item:IsA("TextLabel") or v.Item:IsA("TextButton") or v.Item:IsA("TextBox") then
                        v.Item.TextColor3 = UIData.Theme.Other
                    end
                end
            end
        end)

        for i,v: {Main: boolean, Gradient: UIGradient} in UIData.CustomizableItems.Modules do
            if v.Main then
                v.Gradient.Color =  ColorSequence.new({ColorSequenceKeypoint.new(0, UIData.Theme.ModuleTheme[1]), ColorSequenceKeypoint.new(1, UIData.Theme.ModuleTheme[2])})
            else
                local RGB, RGB2 = Assets.Functions:ConvertColor3toInt(UIData.Theme.ModuleTheme[1]), Assets.Functions:ConvertColor3toInt(UIData.Theme.ModuleTheme[2])
                local Gradients = {
                    [1] = {
                        math.clamp(RGB.R - 7, 0, 255), 
                        math.clamp(RGB.G - 24, 0, 255), 
                        math.clamp(RGB.B - 46, 0, 255)
                    },
                    [2] = {
                        math.clamp(RGB2.R - 5, 0, 255), 
                        math.clamp(RGB2.G - 19, 0, 255), 
                        math.clamp(RGB2.B - 37, 0, 255)
                    }
                }

                v.Gradient.Color =  ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(table.unpack(Gradients[1]))), ColorSequenceKeypoint.new(1, Color3.fromRGB(table.unpack(Gradients[2])))})
                table.clear(Gradients)
            end
        end
        return true
    end

    function Assets.Functions:LoadFile(Game: string, LoadConfig: boolean?, Premium: boolean?)
        local Path: string = "NewNight/Games/"..tostring(Game)..".luau"
        local PremiumPath: string = "NewNight/Premium/Games/"..tostring(Game)..".luau"

        if LoadConfig == nil then
            LoadConfig = true
        end

        local suc: boolean, err: string? = pcall(function()
            if Night.Dev and isfile and isfile(Path) and readfile then
                loadstring(readfile(Path))()
            else
                local Success: boolean, Req: string? = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/null-wtf/NewNight/refs/heads/main/Games/"..Game..".luau")
                if Success and typeof(Req) == "string" and Req ~= "404: Not Found" then
                    loadstring(Req)()
                end
            end
        end)

        if not suc then
            return Assets.Functions:CreateNotification({
                Title = "Failed to load file: "..tostring(Game),
                Description = "Failed to load file: "..tostring(Game)..": "..err
            })
        end

        if Night.Premium and Game ~= "Universal" then
            local suc2: boolean, err2: string? = pcall(function()
                if Night.Dev and isfile and isfile(PremiumPath) and readfile then
                    loadstring(readfile(PremiumPath))()
                else
                    local Success: boolean, Req: string? = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/null-wtf/NewNight/refs/heads/main/Premium/Games/"..Game..".luau")
                    if Success and typeof(Req) == "string" and Req ~= "404: Not Found" then
                        loadstring(Req)()
                    end
                end
            end)

            if not suc2 then
                if setthreadidentity then
                    pcall(setthreadidentity, 8)
                end
            
                return Assets.Functions:CreateNotification({
                    Title = "Failed to load premium file: "..tostring(Game),
                    Description = "Failed to load premium file: "..tostring(Game)..": "..err2
                })
            end
        end

        if LoadConfig then
            local ConfigPath: string = tostring(not table.find(Night.IgnoreConfigs, tostring(Night.Game)) and Night.Game or Game)
            if not isfolder("NewNight/Configs/"..ConfigPath) and not table.find(Night.IgnoreConfigs, tostring(Game)) then
                ConfigPath = tostring(Game)
            end

            if ConfigPath then
                if makefolder and not isfolder("NewNight/Configs/"..ConfigPath) then
                    makefolder("NewNight/Configs/"..ConfigPath)
                end

                if isfile("NewNight/Configs/"..ConfigPath.."/LastUsed.txt") then
                    ConfigPath = ConfigPath.."/"..readfile("NewNight/Configs/"..ConfigPath.."/LastUsed.txt")
                else
                    writefile("NewNight/Configs/"..ConfigPath.."/LastUsed.txt", "Default")
                    ConfigPath = ConfigPath.."/Default"
                end
            end

            if ConfigPath then
                Assets.Config:Load(ConfigPath)
                local BaseConfigFolder = ConfigPath:split("/")[1]
                if BaseConfigFolder then
                    Assets.Functions:CreateConfigOptions(BaseConfigFolder)
                end
            end
        end

        return
    end
end


local SpaceUI = getgenv().SpaceUI or loadstring(game:HttpGet("https://raw.githubusercontent.com/tobureinhardt/SpaceUI/refs/heads/main/dist/SpaceUI.lua"))()

if SpaceUI and not SpaceUI.Background then
    SpaceUI.Main.Load("NightUI")
    -- Ensure it starts open
    if SpaceUI.Main.ToggleVisibility then
        SpaceUI.Main.ToggleVisibility(true)
    end
end

function Assets.Functions:CreateTab(Data)
    local STab = SpaceUI.Dashboard.NewTab({
        Name = Data.Name,
        Icon = "rbxassetid://11433532073",
        TabInfo = Data.Name .. " Features"
    })
    
    local Tab = {
        Modules = setmetatable({}, {
            __index = function(t, k)
                return {
                    Enabled = false,
                    Destroy = function() end,
                    Enable = function() end,
                    Disable = function() end,
                    SetVisiblity = function() end,
                    SetValue = function() end,
                    Slider = function() return { SetVisiblity = function() end, SetValue = function() end } end,
                    MiniToggle = function() return { SetVisiblity = function() end, SetValue = function() end } end,
                    Toggle = function() return { SetVisiblity = function() end, SetValue = function() end } end,
                    Dropdown = function() return { SetVisiblity = function() end, SetValue = function() end } end,
                    ColorSlider = function() return { SetVisiblity = function() end, SetValue = function() end } end,
                    TextBox = function() return { SetVisiblity = function() end, SetValue = function() end } end,
                    KeyBind = function() return { SetVisiblity = function() end, SetValue = function() end } end,
                    Connection = function() return {} end
                }
            end
        })
    }
    
    Night.UIData = Night.UIData or {}
    Night.UIData[Data.Flag or Data.Name] = Tab
    
    function Tab:CreateModule(MData)
        local Module = {
            Enabled = false,
            Functions = {},
            Connections = {}
        }
        
        local SModule = STab.Functions.NewModule({
            Name = MData.Name,
            Description = MData.Name,
            Flag = MData.Flag,
            Callback = function(self, state)
                Module.Enabled = state
                if not state then
                    for i, con in pairs(Module.Connections) do
                        if typeof(con) == "thread" then
                            coroutine.close(con)
                        elseif typeof(con) == "table" and con.Disconnect then
                            con:Disconnect()
                        elseif typeof(con) == "RBXScriptConnection" then
                            con:Disconnect()
                        end
                    end
                    table.clear(Module.Connections)
                end
                
                if MData.CallingFunction then
                    MData.CallingFunction(Module, state)
                end
            end
        })
        
        
        function Module:Connection(con)
            table.insert(Module.Connections, con)
            return con
        end
        
        function Module:Destroy()
            if SModule and SModule.Functions and SModule.Functions.Destroy then
                SModule.Functions.Destroy()
            end
        end

        
        function Module:Slider(SData)
            local Setting = SModule.Functions.Settings.Slider({
                Name = SData.Name,
                Flag = SData.Flag,
                Min = SData.Min,
                Max = SData.Max,
                Default = SData.Default,
                Callback = function(self, val)
                    if SData.CallingFunction then
                        SData.CallingFunction(self, val)
                    end
                end
            })
            local Wrapper = {}
                        function Wrapper:SetVisiblity(v)
                if Setting and Setting.Functions and Setting.Functions.SetVisiblity then
                    Setting.Functions.SetVisiblity(v)
                end
            end
            function Wrapper:SetValue(v)
                if Setting and Setting.Functions and Setting.Functions.SetValue then
                    Setting.Functions.SetValue(v)
                end
            end
            return Wrapper
        end
        
        function Module:Dropdown(SData)
            local Setting = SModule.Functions.Settings.Dropdown({
                Name = SData.Name,
                Flag = SData.Flag,
                Default = SData.Default,
                Options = SData.Options,
                Callback = function(self, val)
                    if SData.CallingFunction then
                        SData.CallingFunction(self, val)
                    end
                end
            })
            local Wrapper = {}
                        function Wrapper:SetVisiblity(v)
                if Setting and Setting.Functions and Setting.Functions.SetVisiblity then
                    Setting.Functions.SetVisiblity(v)
                end
            end
            function Wrapper:SetValue(v)
                if Setting and Setting.Functions and Setting.Functions.SetValue then
                    Setting.Functions.SetValue(v)
                end
            end
            return Wrapper
        end
        
        function Module:MiniToggle(SData)
            local Setting = SModule.Functions.Settings.MiniToggle({
                Name = SData.Name,
                Flag = SData.Flag,
                Default = SData.Default or false,
                Callback = function(self, val)
                    if SData.CallingFunction then
                        SData.CallingFunction(self, val)
                    end
                end
            })
            local Wrapper = {}
                        function Wrapper:SetVisiblity(v)
                if Setting and Setting.Functions and Setting.Functions.SetVisiblity then
                    Setting.Functions.SetVisiblity(v)
                end
            end
            function Wrapper:SetValue(v)
                if Setting and Setting.Functions and Setting.Functions.SetValue then
                    Setting.Functions.SetValue(v)
                end
            end
            return Wrapper
        end

        function Module:Toggle(SData)
            return Module:MiniToggle(SData)
        end
        
        function Module:ColorSlider(SData)
            local Setting = SModule.Functions.Settings.TextBox({
                Name = SData.Name,
                Flag = SData.Flag,
                Default = "255, 255, 255",
                Callback = function(self, val)
                end
            })
            local Wrapper = {}
                        function Wrapper:SetVisiblity(v)
                if Setting and Setting.Functions and Setting.Functions.SetVisiblity then
                    Setting.Functions.SetVisiblity(v)
                end
            end
            function Wrapper:SetValue(v)
                if Setting and Setting.Functions and Setting.Functions.SetValue then
                    Setting.Functions.SetValue(v)
                end
            end
            return Wrapper
        end
        
        function Module.Functions:KeyBind(SData)
            local Setting = SModule.Functions.Settings.Keybind({
                Name = SData.Name,
                Flag = SData.Flag,
                Default = SData.Default and (typeof(SData.Default) == "EnumItem" and SData.Default.Name or tostring(SData.Default)) or "Unknown",
                Callbacks = {
                    Began = function()
                        if SData.Events and SData.Events.Began then SData.Events.Began() end
                    end,
                    End = function()
                        if SData.Events and SData.Events.Ended then SData.Events.Ended() end
                    end
                }
            })
            local Wrapper = {}
                        function Wrapper:SetVisiblity(v)
                if Setting and Setting.Functions and Setting.Functions.SetVisiblity then
                    Setting.Functions.SetVisiblity(v)
                end
            end
            function Wrapper:SetValue(v)
                if Setting and Setting.Functions and Setting.Functions.SetValue then
                    Setting.Functions.SetValue(v)
                end
            end
            return Wrapper
        end
        
        function Module:KeyBind(SData)
            return Module.Functions:KeyBind(SData)
        end
        
        function Module:TextBox(SData)
            local Setting = SModule.Functions.Settings.TextBox({
                Name = SData.Name,
                Flag = SData.Flag,
                Default = SData.Default or "",
                Placeholder = SData.Placeholder or SData.Name,
                Callback = function(self, val)
                    if SData.CallingFunction then
                        SData.CallingFunction(self, val)
                    end
                end
            })
            local Wrapper = {}
                        function Wrapper:SetVisiblity(v)
                if Setting and Setting.Functions and Setting.Functions.SetVisiblity then
                    Setting.Functions.SetVisiblity(v)
                end
            end
            function Wrapper:SetValue(v)
                if Setting and Setting.Functions and Setting.Functions.SetValue then
                    Setting.Functions.SetValue(v)
                end
            end
            return Wrapper
        end
        
        if MData.Flag then
            Tab.Modules[MData.Flag] = Module
        end
        Tab.Modules[MData.Name] = Module
        return Module
    end
    
    return Tab
end

function Assets.Functions:CreateNotification(Data)
    if SpaceUI.Notifications and SpaceUI.Notifications.Send then
        SpaceUI.Notifications.Send({
            Description = Data.Description or Data.Title or "Notification"
        })
    end
end

Assets.ArrayList = {}
function Assets.ArrayList:Push(...) end
function Assets.ArrayList:Sort(...) end
function Assets.ArrayList:SetColor(...) end

function Assets.Functions:CreateConfigOptions(...) end

setmetatable(Night, {
    __index = Night.Assets
})

setmetatable(Night.Assets, {
    __index = Night.Assets.Functions
})

if UIData and UIData.Windows then
    setmetatable(UIData, {
        __index = UIData.Windows.Windows
    })
end
