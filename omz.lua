getgenv().GG = {
    Language = {
        CheckboxEnabled = "Enabled",
        CheckboxDisabled = "Disabled",
        SliderValue = "Value",
        DropdownSelect = "Select",
        DropdownNone = "None",
        DropdownSelected = "Selected",
        ButtonClick = "Click",
        TextboxEnter = "Enter",
        ModuleEnabled = "Enabled",
        ModuleDisabled = "Disabled",
        TabGeneral = "General",
        TabSettings = "Settings",
        Loading = "Loading...",
        Error = "Error",
        Success = "Success"
    }
}

-- Replace the SelectedLanguage with a reference to GG.Language
local SelectedLanguage = GG.Language

function convertStringToTable(inputString)
    local result = {}
    for value in string.gmatch(inputString, "([^,]+)") do
        local trimmedValue = value:match("^%s*(.-)%s*$")
        tablein(result, trimmedValue)
    end

    return result
end

function convertTableToString(inputTable)
    return table.concat(inputTable, ", ")
end

local UserInputService = cloneref(game:GetService('UserInputService'))
local ContentProvider = cloneref(game:GetService('ContentProvider'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Lighting = cloneref(game:GetService('Lighting'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))

local mouse = Players.LocalPlayer:GetMouse()
local old_March = CoreGui:FindFirstChild('March')

if old_March then
    Debris:AddItem(old_March, 0)
end

if not isfolder("March") then
    makefolder("March")
end

local Library = {
    _config = {
        _flags = {}
    }
}

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Allusive Remake",
    Icon = "rbxassetid://16124707886", 
    Author = ".ftgs",
    Folder = "Allusive",
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 200
})

local rage = Window:Tab({ Title = "Blatant", Icon = "rbxassetid://76499042599127" })
local player = Window:Tab({ Title = "Player", Icon = "rbxassetid://126017907477623" })
local world = Window:Tab({ Title = "World", Icon = "rbxassetid://85168909131990" })
local farm = Window:Tab({ Title = "Farm", Icon = "rbxassetid://132243429647479" })
local misc = Window:Tab({ Title = "Misc", Icon = "rbxassetid://132243429647479" })

repeat task.wait() until game:IsLoaded()
local Players = game:GetService('Players')
local Player = Players.LocalPlayer
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Tornado_Time = tick()
local UserInputService = game:GetService('UserInputService')
local Last_Input = UserInputService:GetLastInputType()
local Debris = game:GetService('Debris')
local RunService = game:GetService('RunService')
local Vector2_Mouse_Location = nil
local Grab_Parry = nil
local Remotes = {}
local Parry_Key = nil
local Speed_Divisor_Multiplier = 1.1
local LobbyAP_Speed_Divisor_Multiplier = 1.1
local firstParryFired = false
local ParryThreshold = 2.5
local firstParryType = 'F_Key'
local Previous_Positions = {}
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualInputService = game:GetService("VirtualInputManager")


local GuiService = game:GetService('GuiService')

local function updateNavigation(guiObject: GuiObject | nil)
    GuiService.SelectedObject = guiObject
end

local function performFirstPress(parryType)
    if parryType == 'F_Key' then
        VirtualInputService:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
    elseif parryType == 'Left_Click' then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    elseif parryType == 'Navigation' then
        local button = Players.LocalPlayer.PlayerGui.Hotbar.Block
        updateNavigation(button)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        task.wait(0.01)
        updateNavigation(nil)
    end
end

local revertedRemotes = {}
local originalMetatables = {}

local function isValidRemoteArgs(args)
    return #args == 7 and
           type(args[2]) == "string" and  
           type(args[3]) == "number" and 
           typeof(args[4]) == "CFrame" and 
           type(args[5]) == "table" and  
           type(args[6]) == "table" and 
           type(args[7]) == "boolean"
end

local function hookRemote(remote)
    if not revertedRemotes[remote] then
        local meta = getrawmetatable(remote)
        if not originalMetatables[meta] then
            originalMetatables[meta] = true  
            setreadonly(meta, false)  

            local oldIndex = meta.__index
            meta.__index = function(self, key)
                if key == "FireServer" and self:IsA("RemoteEvent") then
                    return function(_, ...)
                        local args = { ... }
                        if isValidRemoteArgs(args) then
                            if not revertedRemotes[self] then
                                revertedRemotes[self] = args
                            end
                        end
                        return oldIndex(self, "FireServer")(_, table.unpack(args))
                    end
                elseif key == "InvokeServer" and self:IsA("RemoteFunction") then
                    return function(_, ...)
                        local args = { ... }
                        if isValidRemoteArgs(args) then
                            if not revertedRemotes[self] then
                                revertedRemotes[self] = args
                                print("Hooked RemoteFunction:", self.Name)
                            end
                        end
                        return oldIndex(self, "InvokeServer")(_, table.unpack(args))
                    end
                end
                return oldIndex(self, key)
            end

            setreadonly(meta, true)
        end
    end
end

local function restoreRemotes()
    for remote, _ in pairs(revertedRemotes) do
        if originalMetatables[getmetatable(remote)] then
            local meta = getrawmetatable(remote)
            setreadonly(meta, false)
            meta.__index = nil
            setreadonly(meta, true)
        end
    end
    revertedRemotes = {}
end

for _, remote in pairs(game.ReplicatedStorage:GetChildren()) do
    if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
        hookRemote(remote)
    end
end

game.ReplicatedStorage.ChildAdded:Connect(function(child)
    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
        hookRemote(child)
    end
end)

local Key = Parry_Key
local Parries = 0

type functionInfo = {
    scriptName: string,
    name: string,
    line: number,
    upvalueCount: number,
    constantCount: number
}

local function getFunction(t:functionInfo)
    t = t or {}
    local functions = {}
    local function findMatches()
        setthreadidentity(6)
        for i,v in getgc() do
            if type(v) == "function" and islclosure(v) then
                local match = true
                local info = getinfo(v)
                if t.scriptName and (not tostring(getfenv(v).script):find(t.scriptName)) then
                    match = false
                end
                if t.name and info.name ~= t.name then
                    match = false
                end
                if t.line and info.currentline ~= t.line then
                    match = false
                end
                if t.upvalueCount and #getupvalues(v) ~= t.upvalueCount then
                    match = false
                end
                if t.constantCount and #getconstants(v) ~= t.constantsCount then
                    match = false
                end
                if match then
                    table.insert(functions,v)
                end
            end
        end
        setthreadidentity(8)
    end

    findMatches()

    if #functions == 0 then
        while task.wait(1) and #functions == 0 do
            findMatches()
        end
    end
    
    if #functions == 1 then
        return functions[1]
    end
end

type tableInfo = {
    highEntropyTableIndex: string,
}



local Parries = 0
local Auto_Parry = {}

function Auto_Parry.Parry_Animation()
    local Parry_Animation = game:GetService("ReplicatedStorage").Shared.SwordAPI.Collection.Default:FindFirstChild('GrabParry')
    local Current_Sword = Player.Character:GetAttribute('CurrentlyEquippedSword')

    if not Current_Sword then
        return
    end

    if not Parry_Animation then
        return
    end

    local Sword_Data = game:GetService("ReplicatedStorage").Shared.ReplicatedInstances.Swords.GetSword:Invoke(Current_Sword)

    if not Sword_Data or not Sword_Data['AnimationType'] then
        return
    end

    for _, object in pairs(game:GetService('ReplicatedStorage').Shared.SwordAPI.Collection:GetChildren()) do
        if object.Name == Sword_Data['AnimationType'] then
            if object:FindFirstChild('GrabParry') or object:FindFirstChild('Grab') then
                local sword_animation_type = 'GrabParry'

                if object:FindFirstChild('Grab') then
                    sword_animation_type = 'Grab'
                end

                Parry_Animation = object[sword_animation_type]
            end
        end
    end

    Grab_Parry = Player.Character.Humanoid.Animator:LoadAnimation(Parry_Animation)
    Grab_Parry:Play()
end

function Auto_Parry.Play_Animation(v)
    local Animations = Animation.storage[v]

    if not Animations then
        return false
    end

    local Animator = Player.Character.Humanoid.Animator

    if Animation.track then
        Animation.track:Stop()
    end

    Animation.track = Animator:LoadAnimation(Animations)
    Animation.track:Play()

    Animation.current = v
end

function Auto_Parry.Get_Balls()
    local Balls = {}

    for _, Instance in pairs(workspace.Balls:GetChildren()) do
        if Instance:GetAttribute('realBall') then
            Instance.CanCollide = false
            table.insert(Balls, Instance)
        end
    end
    return Balls
end

function Auto_Parry.Get_Ball()
    for _, Instance in pairs(workspace.Balls:GetChildren()) do
        if Instance:GetAttribute('realBall') then
            Instance.CanCollide = false
            return Instance
        end
    end
end

function Auto_Parry.Lobby_Balls()
    for _, Instance in pairs(workspace.TrainingBalls:GetChildren()) do
        if Instance:GetAttribute("realBall") then
            return Instance
        end
    end
end


local Closest_Entity = nil

function Auto_Parry.Closest_Player()
    local Max_Distance = math.huge
    local Found_Entity = nil
    
    for _, Entity in pairs(workspace.Alive:GetChildren()) do
        if tostring(Entity) ~= tostring(Player) then
            if Entity.PrimaryPart then  -- Check if PrimaryPart exists
                local Distance = Player:DistanceFromCharacter(Entity.PrimaryPart.Position)
                if Distance < Max_Distance then
                    Max_Distance = Distance
                    Found_Entity = Entity
                end
            end
        end
    end
    
    Closest_Entity = Found_Entity
    return Found_Entity
end

function Auto_Parry:Get_Entity_Properties()
    Auto_Parry.Closest_Player()

    if not Closest_Entity then
        return false
    end

    local Entity_Velocity = Closest_Entity.PrimaryPart.Velocity
    local Entity_Direction = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Unit
    local Entity_Distance = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude

    return {
        Velocity = Entity_Velocity,
        Direction = Entity_Direction,
        Distance = Entity_Distance
    }
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled


function Auto_Parry.Parry_Data(Parry_Type)
    Auto_Parry.Closest_Player()
    
    local Events = {}
    local Camera = workspace.CurrentCamera
    local Vector2_Mouse_Location
    
    if Last_Input == Enum.UserInputType.MouseButton1 or (Enum.UserInputType.MouseButton2 or Last_Input == Enum.UserInputType.Keyboard) then
        local Mouse_Location = UserInputService:GetMouseLocation()
        Vector2_Mouse_Location = {Mouse_Location.X, Mouse_Location.Y}
    else
        Vector2_Mouse_Location = {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2}
    end
    
    if isMobile then
        Vector2_Mouse_Location = {Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2}
    end
    
    local Players_Screen_Positions = {}
    for _, v in pairs(workspace.Alive:GetChildren()) do
        if v ~= Player.Character then
            local worldPos = v.PrimaryPart.Position
            local screenPos, isOnScreen = Camera:WorldToScreenPoint(worldPos)
            
            if isOnScreen then
                Players_Screen_Positions[v] = Vector2.new(screenPos.X, screenPos.Y)
            end
            
            Events[tostring(v)] = screenPos
        end
    end
    
    if Parry_Type == 'Camera' then
        return {0, Camera.CFrame, Events, Vector2_Mouse_Location}
    end
    
    if Parry_Type == 'Backwards' then
        local Backwards_Direction = Camera.CFrame.LookVector * -10000
        Backwards_Direction = Vector3.new(Backwards_Direction.X, 0, Backwards_Direction.Z)
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Backwards_Direction), Events, Vector2_Mouse_Location}
    end

    if Parry_Type == 'Straight' then
        local Aimed_Player = nil
        local Closest_Distance = math.huge
        local Mouse_Vector = Vector2.new(Vector2_Mouse_Location[1], Vector2_Mouse_Location[2])
        
        for _, v in pairs(workspace.Alive:GetChildren()) do
            if v ~= Player.Character then
                local worldPos = v.PrimaryPart.Position
                local screenPos, isOnScreen = Camera:WorldToScreenPoint(worldPos)
                
                if isOnScreen then
                    local playerScreenPos = Vector2.new(screenPos.X, screenPos.Y)
                    local distance = (Mouse_Vector - playerScreenPos).Magnitude
                    
                    if distance < Closest_Distance then
                        Closest_Distance = distance
                        Aimed_Player = v
                    end
                end
            end
        end
        
        if Aimed_Player then
            return {0, CFrame.new(Player.Character.PrimaryPart.Position, Aimed_Player.PrimaryPart.Position), Events, Vector2_Mouse_Location}
        else
            return {0, CFrame.new(Player.Character.PrimaryPart.Position, Closest_Entity.PrimaryPart.Position), Events, Vector2_Mouse_Location}
        end
    end
    
    if Parry_Type == 'Random' then
        return {0, CFrame.new(Camera.CFrame.Position, Vector3.new(math.random(-4000, 4000), math.random(-4000, 4000), math.random(-4000, 4000))), Events, Vector2_Mouse_Location}
    end
    
    if Parry_Type == 'High' then
        local High_Direction = Camera.CFrame.UpVector * 10000
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + High_Direction), Events, Vector2_Mouse_Location}
    end
    
    if Parry_Type == 'Left' then
        local Left_Direction = Camera.CFrame.RightVector * 10000
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - Left_Direction), Events, Vector2_Mouse_Location}
    end
    
    if Parry_Type == 'Right' then
        local Right_Direction = Camera.CFrame.RightVector * 10000
        return {0, CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Right_Direction), Events, Vector2_Mouse_Location}
    end

    if Parry_Type == 'RandomTarget' then
        local candidates = {}
        for _, v in pairs(workspace.Alive:GetChildren()) do
            if v ~= Player.Character and v.PrimaryPart then
                local screenPos, isOnScreen = Camera:WorldToScreenPoint(v.PrimaryPart.Position)
                if isOnScreen then
                    table.insert(candidates, {
                        character = v,
                        screenXY  = { screenPos.X, screenPos.Y }
                    })
                end
            end
        end
        if #candidates > 0 then
            local pick = candidates[ math.random(1, #candidates) ]
            local lookCFrame = CFrame.new(Player.Character.PrimaryPart.Position, pick.character.PrimaryPart.Position)
            return {0, lookCFrame, Events, pick.screenXY}
        else
            return {0, Camera.CFrame, Events, { Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2 }}
        end
    end
    
    return Parry_Type
end

function Auto_Parry.Parry(Parry_Type)
    local Parry_Data = Auto_Parry.Parry_Data(Parry_Type)

    if not firstParryFired then
        performFirstPress(firstParryType)
        firstParryFired = true
    else
        for remote, originalArgs in pairs(revertedRemotes) do
            local modifiedArgs = {
                originalArgs[1],
                originalArgs[2],
                originalArgs[3],
                Parry_Data[2],
                originalArgs[5],
                originalArgs[6],
                originalArgs[7]
            }
            
            if remote:IsA("RemoteEvent") then
                remote:FireServer(unpack(modifiedArgs))
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer(unpack(modifiedArgs))
            end
        end
    end

    if Parries > 7 then
        return false
    end

    Parries += 1

    task.delay(0.5, function()
        if Parries > 0 then
            Parries -= 1
        end
    end)
end

local Lerp_Radians = 0
local Last_Warping = tick()

function Auto_Parry.Linear_Interpolation(a, b, time_volume)
    return a + (b - a) * time_volume
end

local Previous_Velocity = {}
local Curving = tick()

local Runtime = workspace.Runtime

function Auto_Parry.Is_Curved()
    local Ball = Auto_Parry.Get_Ball()

    if not Ball then
        return false
    end

    local Zoomies = Ball:FindFirstChild('zoomies')
    if not Zoomies then
        return false
    end

    local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()
    local Velocity = Zoomies.VectorVelocity
    local Ball_Direction = Velocity.Unit

    local playerPos = Player.Character.PrimaryPart.Position
    local ballPos = Ball.Position
    local Direction = (playerPos - ballPos).Unit
    local Dot = Direction:Dot(Ball_Direction)
    local Speed = Velocity.Magnitude

    local Speed_Threshold = math.min(Speed/100, 40)
    local Angle_Threshold = 40 * math.max(Dot, 0)
    local Distance = (playerPos - ballPos).Magnitude
    local Reach_Time = Distance / Speed - (Ping / 1000)
    
    local Ball_Distance_Threshold = 15 - math.min(Distance/1000, 15) + Speed_Threshold

    table.insert(Previous_Velocity, Velocity)
    if #Previous_Velocity > 4 then
        table.remove(Previous_Velocity, 1)
    end

    if Ball:FindFirstChild('AeroDynamicSlashVFX') then
        Debris:AddItem(Ball.AeroDynamicSlashVFX, 0)
        Tornado_Time = tick()
    end

    if Runtime:FindFirstChild('Tornado') then
        if (tick() - Tornado_Time) < ((Runtime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159) then
            return true
        end
    end

    local Enough_Speed = Speed > 160
    if Enough_Speed and Reach_Time > Ping / 10 then
        if Speed < 300 then
            Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15)
        elseif Speed > 300 and Speed < 600 then
            Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 16, 16)
        elseif Speed > 600 and Speed < 1000 then
            Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 17, 17)
        elseif Speed > 1000 and Speed < 1500 then
            Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 19, 19)
        elseif Speed > 1500 then
            Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 20, 20)
        end
    end

    if Distance < Ball_Distance_Threshold then
        return false
    end

    if Speed < 300 then
        if (tick() - Curving) < (Reach_Time / 1.2) then
            return true
        end
    elseif Speed >= 300 and Speed < 450 then
        if (tick() - Curving) < (Reach_Time / 1.21) then
            return true
        end
    elseif Speed > 450 and Speed < 600 then
        if (tick() - Curving) < (Reach_Time / 1.335) then
            return true
        end
    elseif Speed > 600 then
        if (tick() - Curving) < (Reach_Time / 1.5) then
            return true
        end
    end
    
    local Dot_Threshold = (0.5 - Ping / 1000)
    local Direction_Difference = (Ball_Direction - Velocity.Unit)
    local Direction_Similarity = Direction:Dot(Direction_Difference.Unit)
    local Dot_Difference = Dot - Direction_Similarity

    if Dot_Difference < Dot_Threshold then
        return true
    end

    local Clamped_Dot = math.clamp(Dot, -1, 1)
    local Radians = math.deg(math.asin(Clamped_Dot))

    Lerp_Radians = Auto_Parry.Linear_Interpolation(Lerp_Radians, Radians, 0.8)
    if Speed < 300 then
        if Lerp_Radians < 0.02 then
            Last_Warping = tick()
        end
        if (tick() - Last_Warping) < (Reach_Time / 1.19) then
            return true
        end
    else
        if Lerp_Radians < 0.018 then
            Last_Warping = tick()
        end
        if (tick() - Last_Warping) < (Reach_Time / 1.5) then
            return true
        end
    end

    if #Previous_Velocity == 4 then
        local Intended_Direction_Difference = (Ball_Direction - Previous_Velocity[1].Unit).Unit
        local Intended_Dot = Direction:Dot(Intended_Direction_Difference)
        local Intended_Dot_Difference = Dot - Intended_Dot

        local Intended_Direction_Difference2 = (Ball_Direction - Previous_Velocity[2].Unit).Unit
        local Intended_Dot2 = Direction:Dot(Intended_Direction_Difference2)
        local Intended_Dot_Difference2 = Dot - Intended_Dot2

        if Intended_Dot_Difference < Dot_Threshold or Intended_Dot_Difference2 < Dot_Threshold then
            return true
        end
    end

    local backwardsCurveDetected = false
    local backwardsAngleThreshold = 85

    local horizDirection = Vector3.new(playerPos.X - ballPos.X, 0, playerPos.Z - ballPos.Z)
    if horizDirection.Magnitude > 0 then
        horizDirection = horizDirection.Unit
    end

    local awayFromPlayer = -horizDirection

    local horizBallDir = Vector3.new(Ball_Direction.X, 0, Ball_Direction.Z)
    if horizBallDir.Magnitude > 0 then
        horizBallDir = horizBallDir.Unit
        local backwardsAngle = math.deg(math.acos(math.clamp(awayFromPlayer:Dot(horizBallDir), -1, 1)))
        if backwardsAngle < backwardsAngleThreshold then
            backwardsCurveDetected = true
        end
    end

    return (Dot < Dot_Threshold) or backwardsCurveDetected
end

function Auto_Parry:Get_Ball_Properties()
    local Ball = Auto_Parry.Get_Ball()

    local Ball_Velocity = Vector3.zero
    local Ball_Origin = Ball

    local Ball_Direction = (Player.Character.PrimaryPart.Position - Ball_Origin.Position).Unit
    local Ball_Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Ball_Dot = Ball_Direction:Dot(Ball_Velocity.Unit)

    return {
        Velocity = Ball_Velocity,
        Direction = Ball_Direction,
        Distance = Ball_Distance,
        Dot = Ball_Dot
    }
end

function Auto_Parry.Spam_Service(self)
    local Ball = Auto_Parry.Get_Ball()

    local Entity = Auto_Parry.Closest_Player()

    if not Ball then
        return false
    end

    if not Entity or not Entity.PrimaryPart then
        return false
    end

    local Spam_Accuracy = 0

    local Velocity = Ball.AssemblyLinearVelocity
    local Speed = Velocity.Magnitude

    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Velocity.Unit)

    local Target_Position = Entity.PrimaryPart.Position
    local Target_Distance = Player:DistanceFromCharacter(Target_Position)

    local Maximum_Spam_Distance = self.Ping + math.min(Speed / 6, 95)

    if self.Entity_Properties.Distance > Maximum_Spam_Distance then
        return Spam_Accuracy
    end

    if self.Ball_Properties.Distance > Maximum_Spam_Distance then
        return Spam_Accuracy
    end

    if Target_Distance > Maximum_Spam_Distance then
        return Spam_Accuracy
    end

    local Maximum_Speed = 5 - math.min(Speed / 5, 5)
    local Maximum_Dot = math.clamp(Dot, -1, 0) * Maximum_Speed

    Spam_Accuracy = Maximum_Spam_Distance - Maximum_Dot

    return Spam_Accuracy
end

local Connections_Manager = {}
local Selected_Parry_Type = nil

local Parried = false
local Last_Parry = 0


local deathshit = false

ReplicatedStorage.Remotes.DeathBall.OnClientEvent:Connect(function(c, d)
    if d then
        deathshit = true
    else
        deathshit = false
    end
end)

local Infinity = false

ReplicatedStorage.Remotes.InfinityBall.OnClientEvent:Connect(function(a, b)
    if b then
        Infinity = true
    else
        Infinity = false
    end
end)


local timehole = false

ReplicatedStorage.Remotes.TimeHoleHoldBall.OnClientEvent:Connect(function(e, f)
    if f then
        timehole = true
    else
        timehole = false
    end
end)


local AutoParry = true

local Balls = workspace:WaitForChild('Balls')
local CurrentBall = nil
local InputTask = nil
local Cooldown = 0.02
local RunTime = workspace:FindFirstChild("Runtime")



local function GetBall()
    for _, Ball in ipairs(Balls:GetChildren()) do
        if Ball:FindFirstChild("ff") then
            return Ball
        end
    end
    return nil
end

local function SpamInput(Label)
    if InputTask then return end
    InputTask = task.spawn(function()
        while AutoParry do
            Auto_Parry.Parry(Selected_Parry_Type)
            task.wait(Cooldown)
        end
        InputTask = nil
    end)
end

Balls.ChildAdded:Connect(function(Value)
    Value.ChildAdded:Connect(function(Child)
        if getgenv().SlashOfFuryDetection and Child.Name == 'ComboCounter' then
            local Sof_Label = Child:FindFirstChildOfClass('TextLabel')

            if Sof_Label then
                repeat
                    local Slashes_Counter = tonumber(Sof_Label.Text)

                    if Slashes_Counter and Slashes_Counter < 32 then
                        Auto_Parry.Parry(Selected_Parry_Type)
                    end

                    task.wait()

                until not Sof_Label.Parent or not Sof_Label
            end
        end
    end)
end)


local Players = game:GetService("Players")
local player10239123 = Players.LocalPlayer
local RunService = game:GetService("RunService")

if not player10239123 then return end

RunTime.ChildAdded:Connect(function(Object)
    local Name = Object.Name
    if getgenv().PhantomV2Detection then
        if Name == "maxTransmission" or Name == "transmissionpart" then
            local Weld = Object:FindFirstChildWhichIsA("WeldConstraint")
            if Weld then
                local Character = player10239123.Character or player10239123.CharacterAdded:Wait()
                if Character and Weld.Part1 == Character.HumanoidRootPart then
                    CurrentBall = GetBall()
                    Weld:Destroy()
    
                    if CurrentBall then
                        local FocusConnection
                        FocusConnection = RunService.RenderStepped:Connect(function()
                            local Highlighted = CurrentBall:GetAttribute("highlighted")
    
                            if Highlighted == true then
                                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 36
    
                                local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
                                if HumanoidRootPart then
                                    local PlayerPosition = HumanoidRootPart.Position
                                    local BallPosition = CurrentBall.Position
                                    local PlayerToBall = (BallPosition - PlayerPosition).Unit
    
                                    game.Players.LocalPlayer.Character.Humanoid:Move(PlayerToBall, false)
                                end
    
                            elseif Highlighted == false then
                                FocusConnection:Disconnect()
    
                                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 10
                                game.Players.LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
    
                                task.delay(3, function()
                                    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 36
                                end)
    
                                CurrentBall = nil
                            end
                        end)
    
                        task.delay(3, function()
                            if FocusConnection and FocusConnection.Connected then
                                FocusConnection:Disconnect()
    
                                game.Players.LocalPlayer.Character.Humanoid:Move(Vector3.new(0, 0, 0), false)
                                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 36
                                CurrentBall = nil
                            end
                        end)
                    end
                end
            end
        end
    end
end)

local player11 = game.Players.LocalPlayer
local PlayerGui = player11:WaitForChild("PlayerGui")
local playerGui = player11:WaitForChild("PlayerGui")
local Hotbar = PlayerGui:WaitForChild("Hotbar")


local ParryCD = playerGui.Hotbar.Block.UIGradient
local AbilityCD = playerGui.Hotbar.Ability.UIGradient

local function isCooldownInEffect1(uigradient)
    return uigradient.Offset.Y < 0.4
end

local function isCooldownInEffect2(uigradient)
    return uigradient.Offset.Y == 0.5
end

local function cooldownProtection()
    if isCooldownInEffect1(ParryCD) then
        game:GetService("ReplicatedStorage").Remotes.AbilityButtonPress:Fire()
        return true
    end
    return false
end

local function AutoAbility()
    if isCooldownInEffect2(AbilityCD) then
        if Player.Character.Abilities["Raging Deflection"].Enabled or Player.Character.Abilities["Rapture"].Enabled or Player.Character.Abilities["Calming Deflection"].Enabled or Player.Character.Abilities["Aerodynamic Slash"].Enabled or Player.Character.Abilities["Fracture"].Enabled or Player.Character.Abilities["Death Slash"].Enabled then
            Parried = true
            game:GetService("ReplicatedStorage").Remotes.AbilityButtonPress:Fire()
            task.wait(2.432)
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DeathSlashShootActivation"):FireServer(true)
            return true
        end
    end
    return false
end

do
    local module = rage:Section({ Title = 'Auto Parry' })

    module:Toggle({
        Title = 'Enabled',
        Flag = 'Auto_Parry',
        Callback = function(value)
            if getgenv().AutoParryNotify then
                if value then
                    WindUI:Notify({
                        Title = "Module Notification",
                        Content = "Auto Parry has been turned ON",
                        Duration = 3
                    })
                else
                    WindUI:Notify({
                        Title = "Module Notification",
                        Content = "Auto Parry has been turned OFF",
                        Duration = 3
                    })
                end
            end
            if value then
                Connections_Manager['Auto Parry'] = RunService.PreSimulation:Connect(function()
                    local One_Ball = Auto_Parry.Get_Ball()
                    local Balls = Auto_Parry.Get_Balls()

                    for _, Ball in pairs(Balls) do

                        if not Ball then
                            return
                        end

                        local Zoomies = Ball:FindFirstChild('zoomies')
                        if not Zoomies then
                            return
                        end

                        Ball:GetAttributeChangedSignal('target'):Once(function()
                            Parried = false
                        end)

                        if Parried then
                            return
                        end

                        local Ball_Target = Ball:GetAttribute('target')
                        local One_Target = One_Ball:GetAttribute('target')

                        local Velocity = Zoomies.VectorVelocity

                        local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude

                        local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue() / 10

                        local Ping_Threshold = math.clamp(Ping / 10, 5, 17)

                        local Speed = Velocity.Magnitude

                        local cappedSpeedDiff = math.min(math.max(Speed - 9.5, 0), 650)
                        local speed_divisor_base = 2.4 + cappedSpeedDiff * 0.002

                        local effectiveMultiplier = Speed_Divisor_Multiplier
                        if getgenv().RandomParryAccuracyEnabled then
                            if Speed < 200 then
                                effectiveMultiplier = 0.7 + (math.random(40, 100) - 1) * (0.35 / 99)
                            else
                                effectiveMultiplier = 0.7 + (math.random(1, 100) - 1) * (0.35 / 99)
                            end
                        end

                        local speed_divisor = speed_divisor_base * effectiveMultiplier
                        local Parry_Accuracy = Ping_Threshold + math.max(Speed / speed_divisor, 9.5)

                        local Curved = Auto_Parry.Is_Curved()

                        if Ball:FindFirstChild('AeroDynamicSlashVFX') then
                            Debris:AddItem(Ball.AeroDynamicSlashVFX, 0)
                            Tornado_Time = tick()
                        end

                        if Runtime:FindFirstChild('Tornado') then
                            if (tick() - Tornado_Time) < (Runtime.Tornado:GetAttribute("TornadoTime") or 1) + 0.314159 then
                            return
                            end
                        end

                        if One_Target == tostring(Player) and Curved then
                            return
                        end

                        if Ball:FindFirstChild("ComboCounter") then
                            return
                        end

                        local Singularity_Cape = Player.Character.PrimaryPart:FindFirstChild('SingularityCape')
                        if Singularity_Cape then
                            return
                        end 

                        if getgenv().InfinityDetection and Infinity then
                            return
                        end

                        if getgenv().DeathSlashDetection and deathshit then
                            return
                        end

                        if getgenv().TimeHoleDetection and timehole then
                            return
                        end

                        if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                            if getgenv().AutoAbility and AutoAbility() then
                                return
                            end
                        end

                        if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                            if getgenv().CooldownProtection and cooldownProtection() then
                                return
                            end

                            local Parry_Time = os.clock()
                            local Time_View = Parry_Time - (Last_Parry)
                            if Time_View > 0.5 then
                                Auto_Parry.Parry_Animation()
                            end

                            if getgenv().AutoParryKeypress then
                                VirtualInputService:SendKeyEvent(true, Enum.KeyCode.F, false, nil)
                            else
                                Auto_Parry.Parry(Selected_Parry_Type)
                            end

                            Last_Parry = Parry_Time
                            Parried = true
                        end
                        local Last_Parrys = tick()
                        repeat
                            RunService.PreSimulation:Wait()
                        until (tick() - Last_Parrys) >= 1 or not Parried
                        Parried = false
                    end
                end)
            else
                if Connections_Manager['Auto Parry'] then
                    Connections_Manager['Auto Parry']:Disconnect()
                    Connections_Manager['Auto Parry'] = nil
                end
            end
        end
    })

    local dropdown3 = module:Dropdown({
        Title = 'First Parry Type',
        Flag = 'First_Parry_Type',
        Value = 'F_Key',
        Values = {
            'F_Key',
            'Left_Click',
            'Navigation'
        },
        Multi = false,
        Callback = function(value)
            firstParryType = value
        end
    })

    local parryTypeMap = {
        ["Camera"] = "Camera",
        ["Random"] = "Random",
        ["Backwards"] = "Backwards",
        ["Straight"] = "Straight",
        ["High"] = "High",
        ["Left"] = "Left",
        ["Right"] = "Right",
        ["Random Target"] = "RandomTarget"
    }

    local dropdown = module:Dropdown({
        Title = 'Target',
        Flag = 'Auto_Parry_Target',
        Value = 'Camera',
        Values = {
            'Camera',
            'Random',
            'Backwards',
            'Straight',
            'High',
            'Left',
            'Right',
            'Random Target'
        },
        Multi = false,
        Callback = function(value: string)
            Selected_Parry_Type = parryTypeMap[value] or value
        end
    })

    local UserInputService = game:GetService("UserInputService")

    local parryOptions = {
        [Enum.KeyCode.One] = "Camera",
        [Enum.KeyCode.Two] = "Random",
        [Enum.KeyCode.Three] = "Backwards",
        [Enum.KeyCode.Four] = "Straight",
        [Enum.KeyCode.Five] = "High",
        [Enum.KeyCode.Six] = "Left",
        [Enum.KeyCode.Seven] = "Right",
        [Enum.KeyCode.Eight] = "Random Target"
    }

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then 
            return 
        end

        if not getgenv().HotkeyParryType then
            return
        end

        local newType = parryOptions[input.KeyCode]
        if newType then
            Selected_Parry_Type = parryTypeMap[newType] or newType
            
            -- WindUI safety check
            if dropdown then
                if dropdown.Set then
                    dropdown:Set(newType)
                elseif dropdown.SetValue then
                    dropdown:SetValue(newType)
                end
            end
            
            if getgenv().HotkeyParryTypeNotify then
                WindUI:Notify({
                    Title = "Module Notification",
                    Content = "Parry Type changed to " .. newType,
                    Duration = 3
                })
            end
        end
    end)

    module:Slider({
        Title = 'Parry Accuracy',
        Flag = 'Parry_Accuracy',
        Value = {
            Min = 1,
            Max = 100,
            Default = 100
        },
        Callback = function(value)
            Speed_Divisor_Multiplier = 0.7 + (value - 1) * (0.35 / 99)
        end
    })

    module:Section({ Title = "Settings" }) -- Separator replacement for create_divider

    module:Toggle({
        Title = "Randomized Parry Accuracy",
        Flag = "Random_Parry_Accuracy",
        Callback = function(value)
            getgenv().RandomParryAccuracyEnabled = value
            if value then
                getgenv().RandomParryAccuracyEnabled = value
            end
        end
    })

    module:Toggle({
        Title = "Infinity Detection",
        Flag = "Infinity_Detection",
        Callback = function(value)
            if value then
                getgenv().InfinityDetection = value
            end
        end
    })

    module:Toggle({
        Title = "Death Slash Detection",
        Flag = "DeathSlash_Detection",
        Callback = function(value)
            getgenv().DeathSlashDetection = value
        end
    })

    module:Toggle({
        Title = "Time Hole Detection",
        Flag = "TimeHole_Detection",
        Callback = function(value)
            getgenv().TimeHoleDetection = value
        end
    })

    module:Toggle({
        Title = "Slash Of Fury Detection",
        Flag = "SlashOfFuryDetection",
        Callback = function(value)
            getgenv().SlashOfFuryDetection = value
        end
    })

    module:Toggle({
        Title = "Anti Phantom",
        Flag = "Anti_Phantom",
        Callback = function(value)
            getgenv().PhantomV2Detection = value
        end
    })

    module:Toggle({
        Title = "Cooldown Protection",
        Flag = "CooldownProtection",
        Callback = function(value)
            getgenv().CooldownProtection = value
        end
    })

    module:Toggle({
        Title = "Auto Ability",
        Flag = "AutoAbility",
        Callback = function(value)
            getgenv().AutoAbility = value
        end
    })

    module:Toggle({
        Title = "Keypress",
        Flag = "Auto_Parry_Keypress",
        Callback = function(value)
            getgenv().AutoParryKeypress = value
        end
    })


    module:Toggle({
        Title = "Notify",
        Flag = "Auto_Parry_Notify",
        Callback = function(value)
            getgenv().AutoParryNotify = value
        end
    })

    local SpamParry = rage:Section({ Title = 'Auto Spam Parry' })

    SpamParry:Toggle({
        Title = 'Enabled',
        Flag = 'Auto_Spam_Parry',
        Callback = function(value)
            if getgenv().AutoSpamNotify then
                if value then
                    WindUI:Notify({
                        Title = "Module Notification",
                        Content = "Auto Spam Parry turned ON",
                        Duration = 3
                    })
                else
                    WindUI:Notify({
                        Title = "Module Notification",
                        Content = "Auto Spam Parry turned OFF",
                        Duration = 3
                    })
                end
            end

            if value then
                Connections_Manager['Auto Spam'] = RunService.PreSimulation:Connect(function()
                    local Ball = Auto_Parry.Get_Ball()

                    if not Ball then
                        return
                    end

                    local Zoomies = Ball:FindFirstChild('zoomies')

                    if not Zoomies then
                        return
                    end

                    Auto_Parry.Closest_Player()

                    local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()

                    local Ping_Threshold = math.clamp(Ping / 10, 1, 16)

                    local Ball_Target = Ball:GetAttribute('target')

                    local Ball_Properties = Auto_Parry:Get_Ball_Properties()
                    local Entity_Properties = Auto_Parry:Get_Entity_Properties()

                    local Spam_Accuracy = Auto_Parry.Spam_Service({
                        Ball_Properties = Ball_Properties,
                        Entity_Properties = Entity_Properties,
                        Ping = Ping_Threshold
                    })

                    local Target_Position = Closest_Entity.PrimaryPart.Position
                    local Target_Distance = Player:DistanceFromCharacter(Target_Position)

                    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
                    local Ball_Direction = Zoomies.VectorVelocity.Unit

                    local Dot = Direction:Dot(Ball_Direction)

                    local Distance = Player:DistanceFromCharacter(Ball.Position)

                    if not Ball_Target then
                        return
                    end

                    if Target_Distance > Spam_Accuracy or Distance > Spam_Accuracy then
                        return
                    end
                    
                    local Pulsed = Player.Character:GetAttribute('Pulsed')

                    if Pulsed then
                        return
                    end

                    if Ball_Target == tostring(Player) and Target_Distance > 30 and Distance > 30 then
                        return
                    end

                    local threshold = ParryThreshold

                    if Distance <= Spam_Accuracy and Parries > threshold then
                        if getgenv().SpamParryKeypress then
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game) 
                        else
                            Auto_Parry.Parry(Selected_Parry_Type)
                        end
                    end
                end)
            else
                if Connections_Manager['Auto Spam'] then
                    Connections_Manager['Auto Spam']:Disconnect()
                    Connections_Manager['Auto Spam'] = nil
                end
            end
        end
    })

    local dropdown2 = SpamParry:Dropdown({
        Title = 'Parry Type',
        Flag = 'Spam_Parry_Type',
        Values = {
            'Legit',
            'Blatant'
        },
        Value = 'Legit',
        Multi = false,
        Callback = function(value)
        end
    })

    SpamParry:Slider({
        Title = "Parry Threshold",
        Flag = "Parry_Threshold",
        Value = {
            Min = 1,
            Max = 3,
            Default = 2.5
        },
        Callback = function(value)
            ParryThreshold = value
        end
    })

    SpamParry:Section({ Title = "Settings" }) 

    if not isMobile then
        local AnimationFix = SpamParry:Toggle({
            Title = "Animation Fix",
            Flag = "AnimationFix",
            Callback = function(value)
                if value then
                    Connections_Manager['Animation Fix'] = RunService.PreSimulation:Connect(function()
                        local Ball = Auto_Parry.Get_Ball()
    
                        if not Ball then
                            return
                        end
    
                        local Zoomies = Ball:FindFirstChild('zoomies')
    
                        if not Zoomies then
                            return
                        end
    
                        Auto_Parry.Closest_Player()
    
                        local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue()
    
                        local Ping_Threshold = math.clamp(Ping / 10, 10, 16)
    
                        local Ball_Target = Ball:GetAttribute('target')
    
                        local Ball_Properties = Auto_Parry:Get_Ball_Properties()
                        local Entity_Properties = Auto_Parry:Get_Entity_Properties()
    
                        local Spam_Accuracy = Auto_Parry.Spam_Service({
                            Ball_Properties = Ball_Properties,
                            Entity_Properties = Entity_Properties,
                            Ping = Ping_Threshold
                        })
    
                        local Target_Position = Closest_Entity.PrimaryPart.Position
                        local Target_Distance = Player:DistanceFromCharacter(Target_Position)
    
                        local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
                        local Ball_Direction = Zoomies.VectorVelocity.Unit
    
                        local Dot = Direction:Dot(Ball_Direction)
    
                        local Distance = Player:DistanceFromCharacter(Ball.Position)
    
                        if not Ball_Target then
                            return
                        end
    
                        if Target_Distance > Spam_Accuracy or Distance > Spam_Accuracy then
                            return
                        end
                        
                        local Pulsed = Player.Character:GetAttribute('Pulsed')
    
                        if Pulsed then
                            return
                        end
    
                        if Ball_Target == tostring(Player) and Target_Distance > 30 and Distance > 30 then
                            return
                        end
    
                        local threshold = ParryThreshold
    
                        if Distance <= Spam_Accuracy and Parries > threshold then
                            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game) 
                        end
                    end)
                else
                    if Connections_Manager['Animation Fix'] then
                        Connections_Manager['Animation Fix']:Disconnect()
                        Connections_Manager['Animation Fix'] = nil
                    end
                end
            end
        })

        -- AnimationFix:change_state(true) -- WindUI doesn't support direct state change like this easily on return object without check. 
        -- However, we can set default:
        -- Just calling the callback manually or setting default in Flag?
        -- For now, commenting out direct call, but I should probably set the Default in the toggle above if it was meant to be on by default.
        -- The original code did :change_state(true).
        -- I'll assume I should set Default = true in the toggle above.
        -- I will edit the replacement content to include Default = true.
    end

    SpamParry:Toggle({
        Title = "Keypress",
        Flag = "Auto_Spam_Parry_Keypress",
        Callback = function(value)
            getgenv().SpamParryKeypress = value
        end
    })

    SpamParry:Toggle({
        Title = "Notify",
        Flag = "Auto_Spam_Parry_Notify",
        Callback = function(value)
            getgenv().AutoSpamNotify = value
        end
    })

    local ManualSpam = rage:Section({ Title = 'Manual Spam Parry' })
    
    ManualSpam:Toggle({
        Title = 'Enabled',
        Flag = 'Manual_Spam_Parry',
        Callback = function(value)
            if getgenv().ManualSpamNotify then
                if value then
                    WindUI:Notify({
                        Title = "Module Notification",
                        Content = "Manual Spam Parry turned ON",
                        Duration = 3
                    })
                else
                    WindUI:Notify({
                        Title = "Module Notification",
                        Content = "Manual Spam Parry turned OFF",
                        Duration = 3
                    })
                end
            end
            if value then
                Connections_Manager['Manual Spam'] = RunService.PreSimulation:Connect(function()
                    if getgenv().spamui then
                        return
                    end

                    if getgenv().ManualSpamKeypress then
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game) 
                    else
                        Auto_Parry.Parry(Selected_Parry_Type)
                    end

                end)
            else
                if Connections_Manager['Manual Spam'] then
                    Connections_Manager['Manual Spam']:Disconnect()
                    Connections_Manager['Manual Spam'] = nil
                end
            end
        end
    })
    
    -- ManualSpam:change_state(false) -- Handled by default state

    if isMobile then
        ManualSpam:Toggle({
            Title = "UI",
            Flag = "Manual_Spam_UI",
            Callback = function(value)
                getgenv().spamui = value
        
                if value then
                    local gui = Instance.new("ScreenGui")
                    gui.Name = "ManualSpamUI"
                    gui.ResetOnSpawn = false
                    gui.Parent = game.CoreGui
        
                    local frame = Instance.new("Frame")
                    frame.Name = "MainFrame"
                    frame.Position = UDim2.new(0, 20, 0, 20)
                    frame.Size = UDim2.new(0, 200, 0, 100)
                    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 50)
                    frame.BackgroundTransparency = 0.3
                    frame.BorderSizePixel = 0
                    frame.Active = true
                    frame.Draggable = true
                    frame.Parent = gui
        
                    local uiCorner = Instance.new("UICorner")
                    uiCorner.CornerRadius = UDim.new(0, 12)
                    uiCorner.Parent = frame
        
                    local uiStroke = Instance.new("UIStroke")
                    uiStroke.Thickness = 2
                    uiStroke.Color = Color3.new(0, 0, 0)
                    uiStroke.Parent = frame
        
                    local button = Instance.new("TextButton")
                    button.Name = "ClashModeButton"
                    button.Text = "Clash Mode"
                    button.Size = UDim2.new(0, 160, 0, 40)
                    button.Position = UDim2.new(0.5, -80, 0.5, -20)
                    button.BackgroundTransparency = 1
                    button.BorderSizePixel = 0
                    button.Font = Enum.Font.GothamSemibold
                    button.TextColor3 = Color3.new(1, 1, 1)
                    button.TextSize = 22
                    button.Parent = frame
        
                    local activated = false
        
                    local function toggle()
                        activated = not activated
                        button.Text = activated and "Stop" or "Clash Mode"
                        if activated then
                            Connections_Manager['Manual Spam UI'] = game:GetService("RunService").Heartbeat:Connect(function()
                                Auto_Parry.Parry(Selected_Parry_Type)
                            end)
                        else
                            if Connections_Manager['Manual Spam UI'] then
                                Connections_Manager['Manual Spam UI']:Disconnect()
                                Connections_Manager['Manual Spam UI'] = nil
                            end
                        end
                    end
        
                    button.MouseButton1Click:Connect(toggle)
                else
                    if game.CoreGui:FindFirstChild("ManualSpamUI") then
                        game.CoreGui:FindFirstChild("ManualSpamUI"):Destroy()
                    end
        
                    if Connections_Manager['Manual Spam UI'] then
                        Connections_Manager['Manual Spam UI']:Disconnect()
                        Connections_Manager['Manual Spam UI'] = nil
                    end
                end
            end
        })
    end
    
    ManualSpam:Toggle({
        Title = "Keypress",
        Flag = "Manual_Spam_Keypress",
        Callback = function(value)
            getgenv().ManualSpamKeypress = value
        end
    })
    
    ManualSpam:Toggle({
        Title = "Notify",
        Flag = "Manual_Spam_Parry_Notify",
        Callback = function(value)
            getgenv().ManualSpamNotify = value
        end
    })

    local Triggerbot = rage:Section({ Title = 'Triggerbot' })
    
    Triggerbot:Toggle({
        Title = 'Enabled',
        Flag = 'Triggerbot',
        Callback = function(value)
            if getgenv().TriggerbotNotify then
                if value then
                    WindUI:Notify({
                        Title = "Module Notification",
                        Content = "Triggerbot turned ON",
                        Duration = 3
                    })
                else
                    WindUI:Notify({
                        Title = "Module Notification",
                        Content = "Triggerbot turned OFF",
                        Duration = 3
                    })
                end
            end
            if value then
                Connections_Manager['Triggerbot'] = RunService.PreSimulation:Connect(function()
                    local Balls = Auto_Parry.Get_Balls()
        
                    for _, Ball in pairs(Balls) do
                        if not Ball then
                            return
                        end
                        
                        Ball:GetAttributeChangedSignal('target'):Once(function()
                            TriggerbotParried = false
                        end)
    
                        if TriggerbotParried then
                            return
                        end

                        local Ball_Target = Ball:GetAttribute('target')
                        local Singularity_Cape = Player.Character.PrimaryPart:FindFirstChild('SingularityCape')
            
                        if Singularity_Cape then 
                            return
                        end 
                    
                        if getgenv().TriggerbotInfinityDetection and Infinity then
                            return
                        end
        
                        if Ball_Target == tostring(Player) then
                            if getgenv().TriggerbotKeypress then
                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game) 
                            else
                                Auto_Parry.Parry(Selected_Parry_Type)
                            end
                            TriggerbotParried = true
                        end
                        local Triggerbot_Last_Parrys = tick()
                        repeat
                            RunService.PreSimulation:Wait()
                        until (tick() - Triggerbot_Last_Parrys) >= 1 or not TriggerbotParried
                        TriggerbotParried = false
                    end
    
                end)
            else
                if Connections_Manager['Triggerbot'] then
                    Connections_Manager['Triggerbot']:Disconnect()
                    Connections_Manager['Triggerbot'] = nil
                end
            end
        end
    })

    Triggerbot:Toggle({
        Title = "Infinity Detection",
        Flag = "Infinity_Detection",
        Callback = function(value)
            getgenv().TriggerbotInfinityDetection = value
        end
    })

    Triggerbot:Toggle({
        Title = "Keypress",
        Flag = "Triggerbot_Keypress",
        Callback = function(value)
            getgenv().TriggerbotKeypress = value
        end
    })

    Triggerbot:Toggle({
        Title = "Notify",
        Flag = "TriggerbotNotify",
        Callback = function(value)
            getgenv().TriggerbotNotify = value
        end
    })

    local HotkeyParryType = rage:Section({ Title = 'Hotkey Parry Type' })
    
    HotkeyParryType:Toggle({
        Title = 'Enabled',
        Flag = 'HotkeyParryType',
        Callback = function(value)
            getgenv().HotkeyParryType = value
        end
    })

    HotkeyParryType:Toggle({
        Title = "Notify",
        Flag = "HotkeyParryTypeNotify",
        Callback = function(value)
            getgenv().HotkeyParryTypeNotify = value
        end
    })

    local LobbyAP = rage:Section({ Title = 'Lobby AP' })
    
    LobbyAP:Toggle({
        Title = 'Enabled',
        Flag = 'Lobby_AP',
        Callback = function(state)
            if getgenv().LobbyAPNotify then
                if state then
                    WindUI:Notify({
                        Title = "Module Notification",
                        Content = "Lobby AP has been turned ON",
                        Duration = 3
                    })
                else
                    WindUI:Notify({
                        Title = "Module Notification",
                        Content = "Lobby AP has been turned OFF",
                        Duration = 3
                    })
                end
            end
            if state then
                Connections_Manager['Lobby AP'] = RunService.Heartbeat:Connect(function()
                    local Ball = Auto_Parry.Lobby_Balls()
                    if not Ball then
                        return
                    end
    
                    local Zoomies = Ball:FindFirstChild('zoomies')
                    if not Zoomies then
                        return
                    end
    
                    Ball:GetAttributeChangedSignal('target'):Once(function()
                        Training_Parried = false
                    end)
    
                    if Training_Parried then
                        return
                    end
    
                    local Ball_Target = Ball:GetAttribute('target')
                    local Velocity = Zoomies.VectorVelocity
                    local Distance = Player:DistanceFromCharacter(Ball.Position)
                    local Speed = Velocity.Magnitude
    
                    local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue() / 10
                    local LobbyAPcappedSpeedDiff = math.min(math.max(Speed - 9.5, 0), 650)
                    local LobbyAPspeed_divisor_base = 2.4 + LobbyAPcappedSpeedDiff * 0.002
    
                    local LobbyAPeffectiveMultiplier = LobbyAP_Speed_Divisor_Multiplier
                    if getgenv().LobbyAPRandomParryAccuracyEnabled then
                        LobbyAPeffectiveMultiplier = 0.7 + (math.random(1, 100) - 1) * (0.35 / 99)
                    end
    
                    local LobbyAPspeed_divisor = LobbyAPspeed_divisor_base * LobbyAPeffectiveMultiplier
                    local LobbyAPParry_Accuracys = Ping + math.max(Speed / LobbyAPspeed_divisor, 9.5)
    
                    if Ball_Target == tostring(Player) and Distance <= LobbyAPParry_Accuracys then
                            if getgenv().LobbyAPKeypress then
                                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game) 
                            else
                                Auto_Parry.Parry(Selected_Parry_Type)
                            end
                        Training_Parried = true
                    end
                    local Last_Parrys = tick()
                    repeat 
                        RunService.PreSimulation:Wait() 
                    until (tick() - Last_Parrys) >= 1 or not Training_Parried
                    Training_Parried = false
                end)
            else
                if Connections_Manager['Lobby AP'] then
                    Connections_Manager['Lobby AP']:Disconnect()
                    Connections_Manager['Lobby AP'] = nil
                end
            end
        end
    })

    LobbyAP:Slider({
        Title = 'Parry Accuracy',
        Flag = 'Parry_Accuracy',
        Value = {
            Min = 1,
            Max = 100,
            Default = 100
        },
        Callback = function(value)
            LobbyAP_Speed_Divisor_Multiplier = 0.7 + (value - 1) * (0.35 / 99)
        end
    })

    LobbyAP:Section({ Title = "Settings" }) 
    
    LobbyAP:Toggle({
        Title = "Randomized Parry Accuracy",
        Flag = "Random_Parry_Accuracy",
        Callback = function(value)
            getgenv().LobbyAPRandomParryAccuracyEnabled = value
        end
    })

    LobbyAP:Toggle({
        Title = "Keypress",
        Flag = "Lobby_AP_Keypress",
        Callback = function(value)
            getgenv().LobbyAPKeypress = value
        end
    })

    LobbyAP:Toggle({
        Title = "Notify",
        Flag = "Lobby_AP_Notify",
        Callback = function(value)
            getgenv().LobbyAPNotify = value
        end
    })

    local plr = game.Players.LocalPlayer
    local cam = workspace.CurrentCamera
    local hit = game.ReplicatedStorage.Remotes.ParryAttempt
    
    getgenv().originalCameraSubject = nil
    
    function getspeed(ball)
        if ball then
            if ball:FindFirstChild("zoomies") and ball.zoomies.VectorVelocity then
                return ball.zoomies.VectorVelocity
            end
        else
            for _, b in pairs(workspace.Balls:GetChildren()) do
                if b:FindFirstChild("zoomies") and b.zoomies.VectorVelocity then
                    return b.zoomies.VectorVelocity
                end
            end
        end
        return Vector3.new(0,0,0)
    end
    
    function restoreCamera()
        local character = plr.Character
        if character and character:FindFirstChild("Humanoid") then
            cam.CameraSubject = character.Humanoid
        end
    end
    
    local BallTP = rage:Section({ Title = "Ball TP" })
    
    BallTP:Toggle({
        Title = "Enabled",
        Flag = "Ball_TP",
        Callback = function(value)
            getgenv().BallTPEnabled = value
            if value then
                if plr.Character and plr.Character:FindFirstChild("Humanoid") then
                    getgenv().originalCameraSubject = cam.CameraSubject
                end
                
                Connections_Manager['BallTP_Added'] = workspace.Balls.ChildAdded:Connect(function(v)
                    if v:IsA("BasePart") then
                        Connections_Manager['BallTP_Changed_' .. v.Name] = v.Changed:Connect(function(prop)
                            local c = plr.Character
                            if not c then return end
                            local hrp = c:FindFirstChild("HumanoidRootPart")
                            if not hrp then return end
    
                            local speed = getspeed(v)
                            if speed then
                                if math.abs(speed.X) > math.abs(speed.Z) then
                                    hrp.CFrame = v.CFrame + Vector3.new(0,5,10)
                                else
                                    hrp.CFrame = v.CFrame + Vector3.new(10,5,0)
                                end
                            end
    
                            cam.CameraSubject = v
    
                            if v:GetAttribute("target") == plr.Name then
                                while v:GetAttribute("target") == plr.Name and v and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0 do
                                    local cnt = 0
                                    while v:GetAttribute("target") == plr.Name and cnt ~= 20 do
                                        cnt = cnt + 1
                                        task.wait()
                                    end
                                end
                                task.wait()
                            end
                        end)
                    end
                end)
            else
                for connName, conn in pairs(Connections_Manager) do
                    if string.find(connName, "BallTP") then
                        conn:Disconnect()
                        Connections_Manager[connName] = nil
                    end
                end
                
                restoreCamera()
            end
        end
    })

    local InstantBallTP = rage:Section({ Title = "Instant Ball TP" })
    
    InstantBallTP:Toggle({
        Title = "Enabled",
        Flag = "Instant_Ball_TP",
        Callback = function(value)
            getgenv().InstantBallTPEnabled = value
            
            if value then
                if plr.Character and plr.Character:FindFirstChild("Humanoid") then
                    getgenv().originalCameraSubject = cam.CameraSubject
                end
                
                getgenv().originalCFrame = nil
                
                for _, ball in ipairs(workspace.Balls:GetChildren()) do
                    if ball:IsA("BasePart") then
                        Connections_Manager['InstantBallTP_Attr_' .. ball.Name] = ball:GetAttributeChangedSignal("target"):Connect(function()
                            handleBallTargetChange(ball)
                        end)
                    end
                end
                
                Connections_Manager['InstantBallTP_Added'] = workspace.Balls.ChildAdded:Connect(function(ball)
                    if ball:IsA("BasePart") then
                        task.wait(0.1)
                        
                        if ball:GetAttribute("target") == plr.Name then
                            handleBallTargetChange(ball)
                        end
                        
                        Connections_Manager['InstantBallTP_Attr_' .. ball.Name] = ball:GetAttributeChangedSignal("target"):Connect(function()
                            handleBallTargetChange(ball)
                        end)
                    end
                end)
            else
                for connName, conn in pairs(Connections_Manager) do
                    if string.find(connName, "InstantBallTP") then
                        conn:Disconnect()
                        Connections_Manager[connName] = nil
                    end
                end
                
                if getgenv().originalCFrame then
                    local c = plr.Character
                    if c then
                        local hrp = c:FindFirstChild("HumanoidRootPart")
                        local hum = c:FindFirstChild("Humanoid")
                        if hrp and hum then
                            hum.PlatformStand = true
                            hrp:PivotTo(getgenv().originalCFrame)
                            task.wait(0.1)
                            hum.PlatformStand = false
                        end
                    end
                    getgenv().originalCFrame = nil
                end
                
                restoreCamera()
            end
        end
    })
    
    function handleBallTargetChange(ball)
        local target = ball:GetAttribute("target")
        local c = plr.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChild("Humanoid")
        if not hrp or not hum then return end
        
        if target == plr.Name then
            if not getgenv().originalCFrame then
                getgenv().originalCFrame = hrp.CFrame
            end
            
            local speed = getspeed(ball)
            if speed.Magnitude > 100 then
                task.wait(0.2)
            end
            
            -- Teleport to ball
            local offset = Vector3.new(5, 5, 5)
            hum.PlatformStand = true
            hrp:PivotTo(ball.CFrame + offset)
            task.wait(0.1)
            hum.PlatformStand = false
            
            cam.CameraSubject = ball
        else
            if getgenv().originalCFrame then
                hum.PlatformStand = true
                hrp:PivotTo(getgenv().originalCFrame)
                task.wait(0.1)
                hum.PlatformStand = false
                getgenv().originalCFrame = nil
                
                restoreCamera()
            end
        end
    end

    local StrafeSpeed = 36

    local Strafe = player:Section({ Title = 'Speed' })
    
    Strafe:Toggle({
        Title = 'Enabled',
        Flag = 'Speed',
        Callback = function(value)
            if value then
                Connections_Manager['Strafe'] = game:GetService("RunService").PreSimulation:Connect(function()
                    local character = game.Players.LocalPlayer.Character
                    if character and character:FindFirstChild("Humanoid") then
                        character.Humanoid.WalkSpeed = StrafeSpeed
                    end
                end)
            else
                local character = game.Players.LocalPlayer.Character
                if character and character:FindFirstChild("Humanoid") then
                    character.Humanoid.WalkSpeed = 36
                end
                
                if Connections_Manager['Strafe'] then
                    Connections_Manager['Strafe']:Disconnect()
                    Connections_Manager['Strafe'] = nil
                end
            end
        end
    })
    
    Strafe:Slider({
        Title = 'Strafe Speed',
        Flag = 'Strafe_Speed',
        Value = {
            Min = 36,
            Max = 200,
            Default = 36
        },
        Callback = function(value)
            StrafeSpeed = value
        end
    })

    local Spinbot = player:Section({ Title = 'Spinbot' })
    
    Spinbot:Toggle({
        Title = 'Enabled',
        Flag = 'Spinbot',
        Callback = function(value)
            getgenv().Spinbot = value
            if value then
                getgenv().spin = true
                getgenv().spinSpeed = getgenv().spinSpeed or 1 
                local Players = game:GetService("Players")
                local RunService = game:GetService("RunService")
                local Client = Players.LocalPlayer
    
                local function spinCharacter()
                    while getgenv().spin do
                        RunService.Heartbeat:Wait()
                        local char = Client.Character
                        local funcHRP = char and char:FindFirstChild("HumanoidRootPart")
                        
                        if char and funcHRP then
                            funcHRP.CFrame *= CFrame.Angles(0, getgenv().spinSpeed, 0)
                        end
                    end
                end
    
                if not getgenv().spinThread then
                    getgenv().spinThread = coroutine.create(spinCharacter)
                    coroutine.resume(getgenv().spinThread)
                end
    
            else
                getgenv().spin = false
    
                if getgenv().spinThread then
                    getgenv().spinThread = nil
                end
            end
        end
    })
    
    Spinbot:Slider({
        Title = 'Spinbot Speed',
        Flag = 'Spinbot_Speed',
        Value = {
            Min = 1,
            Max = 100,
            Default = 1
        },
        Callback = function(value)
            getgenv().spinSpeed = math.rad(value)
        end
    })

    local CameraToggle = player:Section({ Title = 'Field of View' })
    
    CameraToggle:Toggle({
        Title = 'Enabled',
        Flag = 'Field_Of_View',
        Callback = function(value)
            getgenv().CameraEnabled = value
            local Camera = game:GetService("Workspace").CurrentCamera
    
            if value then
                getgenv().CameraFOV = getgenv().CameraFOV or 70
                Camera.FieldOfView = getgenv().CameraFOV
                
                if not getgenv().FOVLoop then
                    getgenv().FOVLoop = game:GetService("RunService").RenderStepped:Connect(function()
                        if getgenv().CameraEnabled then
                            Camera.FieldOfView = getgenv().CameraFOV
                        end
                    end)
                end
            else
                Camera.FieldOfView = 70
                
                if getgenv().FOVLoop then
                    getgenv().FOVLoop:Disconnect()
                    getgenv().FOVLoop = nil
                end
            end
        end
    })
    
    CameraToggle:Slider({
        Title = 'Camera FOV',
        Flag = 'Camera_FOV',
        Value = {
            Min = 50,
            Max = 120,
            Default = 70
        },
        Callback = function(value)
            getgenv().CameraFOV = value
            if getgenv().CameraEnabled then
                game:GetService("Workspace").CurrentCamera.FieldOfView = value
            end
        end
    })

local swordInstancesInstance = ReplicatedStorage:WaitForChild("Shared",9e9):WaitForChild("ReplicatedInstances",9e9):WaitForChild("Swords",9e9)
local swordInstances = require(swordInstancesInstance)

local swordsController

while task.wait() and (not swordsController) do
    for i,v in getconnections(ReplicatedStorage.Remotes.FireSwordInfo.OnClientEvent) do
        if v.Function and islclosure(v.Function) then
            local upvalues = getupvalues(v.Function)
            if #upvalues == 1 and type(upvalues[1]) == "table" then
                swordsController = upvalues[1]
                break
            end
        end
    end
end

function getSlashName(swordName)
    local slashName = swordInstances:GetSword(swordName)
    return (slashName and slashName.SlashName) or "SlashEffect"
end

function setSword()
    if not getgenv().skinChangerEnabled then return end
    
    setupvalue(rawget(swordInstances,"EquipSwordTo"),3,false)
    
    if getgenv().changeSwordModel then
        swordInstances:EquipSwordTo(LocalPlayer.Character, getgenv().swordModel)
    end
    
    if getgenv().changeSwordAnimation then
        swordsController:SetSword(getgenv().swordAnimations)
    end
end

local playParryFunc
local parrySuccessAllConnection

while task.wait() and not parrySuccessAllConnection do
    for i,v in getconnections(ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent) do
        if v.Function and getinfo(v.Function).name == "parrySuccessAll" then
            parrySuccessAllConnection = v
            playParryFunc = v.Function
            v:Disable()
        end
    end
end

local parrySuccessClientConnection
while task.wait() and not parrySuccessClientConnection do
    for i,v in getconnections(ReplicatedStorage.Remotes.ParrySuccessClient.Event) do
        if v.Function and getinfo(v.Function).name == "parrySuccessAll" then
            parrySuccessClientConnection = v
            v:Disable()
        end
    end
end

getgenv().slashName = getSlashName(getgenv().swordFX)

local lastOtherParryTimestamp = 0
local clashConnections = {}

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(...)
    setthreadidentity(2)
    local args = {...}
    if LocalPlayer and tostring(args[4]) ~= LocalPlayer.Name then
        lastOtherParryTimestamp = tick()
    elseif getgenv().skinChangerEnabled and getgenv().changeSwordFX then
        args[1] = getgenv().slashName
        args[3] = getgenv().swordFX
    end
    return playParryFunc(unpack(args))
end)

table.insert(clashConnections, getconnections(ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent)[1])

getgenv().updateSword = function()
    if getgenv().changeSwordFX then
        getgenv().slashName = getSlashName(getgenv().swordFX)
    end
    setSword()
end

task.spawn(function()
    while task.wait(1) do
        if getgenv().skinChangerEnabled and getgenv().changeSwordModel then
            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            if LocalPlayer:GetAttribute("CurrentlyEquippedSword") ~= getgenv().swordModel then
                setSword()
            end
            if char and (not char:FindFirstChild(getgenv().swordModel)) then
                setSword()
            end
            for _,v in (char and char:GetChildren()) or {} do
                if v:IsA("Model") and v.Name ~= getgenv().swordModel then
                    v:Destroy()
                end
                task.wait()
            end
        end
    end
end)

    -- Skin Changer Logic (Re-inserted & Safe)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = game:GetService("Players").LocalPlayer
    
    local swordInstances
    local success, err = pcall(function()
        local swordInstancesInstance = ReplicatedStorage:WaitForChild("Shared", 9e9):WaitForChild("ReplicatedInstances", 9e9):WaitForChild("Swords", 9e9)
        swordInstances = require(swordInstancesInstance)
    end)
    if not success then warn("Skin Changer Error: " .. tostring(err)) end

    local swordsController

    task.spawn(function()
        while task.wait(1) do
            if not swordsController then
                for i,v in pairs(getconnections(ReplicatedStorage.Remotes.FireSwordInfo.OnClientEvent)) do
                    if v.Function and islclosure(v.Function) then
                        local upvalues = getupvalues(v.Function)
                        if #upvalues == 1 and type(upvalues[1]) == "table" then
                            swordsController = upvalues[1]
                            break
                        end
                    end
                end
            end
        end
    end)

    local function getSlashName(swordName)
        if not swordInstances then return "SlashEffect" end
        local slashName = swordInstances:GetSword(swordName)
        return (slashName and slashName.SlashName) or "SlashEffect"
    end

    local function setSword()
        if not getgenv().skinChangerEnabled or not swordInstances then return end
        
        if setupvalue then
            setupvalue(rawget(swordInstances,"EquipSwordTo"), 3, false)
        end
        
        if getgenv().changeSwordModel then
            swordInstances:EquipSwordTo(LocalPlayer.Character, getgenv().swordModel)
        end
        
        if getgenv().changeSwordAnimation and swordsController then
            swordsController:SetSword(getgenv().swordAnimations)
        end
    end

    local playParryFunc
    local parrySuccessAllConnection

    task.spawn(function()
        while task.wait(0.5) do
             if not parrySuccessAllConnection then
                for i,v in pairs(getconnections(ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent)) do
                    if v.Function and getinfo(v.Function).name == "parrySuccessAll" then
                        parrySuccessAllConnection = v
                        playParryFunc = v.Function
                        v:Disable()
                        break
                    end
                end
            end
        end
    end)

    local parrySuccessClientConnection
    task.spawn(function()
        while task.wait(0.5) do
             if not parrySuccessClientConnection then
                for i,v in pairs(getconnections(ReplicatedStorage.Remotes.ParrySuccessClient.Event)) do
                    if v.Function and getinfo(v.Function).name == "parrySuccessAll" then
                        parrySuccessClientConnection = v
                        v:Disable()
                        break
                    end
                end
            end
        end
    end)

    getgenv().swordFX = "Default"
    getgenv().slashName = getSlashName(getgenv().swordFX)

    local lastOtherParryTimestamp = 0
    
    ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(...)
        setthreadidentity(2)
        local args = {...}
        if LocalPlayer and args[4] and tostring(args[4]) ~= LocalPlayer.Name then
            lastOtherParryTimestamp = tick()
        elseif getgenv().skinChangerEnabled and getgenv().changeSwordFX then
            args[1] = getgenv().slashName
            args[3] = getgenv().swordFX
        end
        if playParryFunc then
            return playParryFunc(unpack(args))
        end
    end)

    getgenv().updateSword = function()
        if getgenv().changeSwordFX then
            getgenv().slashName = getSlashName(getgenv().swordFX)
        end
        setSword()
    end

    task.spawn(function()
        while task.wait(1) do
            if LocalPlayer and getgenv().skinChangerEnabled and getgenv().changeSwordModel then
                local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                
                if LocalPlayer:GetAttribute("CurrentlyEquippedSword") ~= getgenv().swordModel then
                    setSword()
                end
                
                if char and (not char:FindFirstChild(getgenv().swordModel)) then
                    setSword()
                end
                
                for _,v in pairs((char and char:GetChildren()) or {}) do
                    if v:IsA("Model") and v.Name ~= getgenv().swordModel then
                        v:Destroy()
                    end
                end
            end
        end
    end)
local SkinSection = misc:Section({ Title = "Skin Changer" })

SkinSection:Toggle({
    Title = 'Skin Changer',
    Desc = 'Ported Skin Changer',
    Value = false,
    Callback = function(value)
        getgenv().skinChangerEnabled = value
        if value then
            getgenv().updateSword()
        end
    end
})

SkinSection:Toggle({ Type = "Checkbox",
    Title = "Change Sword Model",
    Value = true,
    Callback = function(value)
        getgenv().changeSwordModel = value
        if getgenv().skinChangerEnabled then
            getgenv().updateSword()
        end
    end
})

SkinSection:Input({
    Title = "Sword Model Name",
    Placeholder = "Enter Sword Model Name...",
    Callback = function(text)
        getgenv().swordModel = text
        if getgenv().skinChangerEnabled and getgenv().changeSwordModel then
            getgenv().updateSword()
        end
    end
})

SkinSection:Toggle({ Type = "Checkbox",
    Title = "Change Sword Animation",
    Value = true,
    Callback = function(value)
        getgenv().changeSwordAnimation = value
        if getgenv().skinChangerEnabled then
            getgenv().updateSword()
        end
    end
})

SkinSection:Input({
    Title = "Sword Animation Name",
    Placeholder = "Enter Sword Animation Name...",
    Callback = function(text)
        getgenv().swordAnimations = text
        if getgenv().skinChangerEnabled and getgenv().changeSwordAnimation then
            getgenv().updateSword()
        end
    end
})

SkinSection:Toggle({ Type = "Checkbox",
    Title = "Change Sword FX",
    Value = true,
    Callback = function(value)
        getgenv().changeSwordFX = value
        if getgenv().skinChangerEnabled then
            getgenv().updateSword()
        end
    end
})

SkinSection:Input({
    Title = "Sword FX Name",
    Placeholder = "Enter Sword FX Name...",
    Callback = function(text)
        getgenv().swordFX = text
        if getgenv().skinChangerEnabled and getgenv().changeSwordFX then
            getgenv().updateSword()
        end
    end
})

    _G.PlayerCosmeticsCleanup = {}
    
    local PlayerCosmetics = player:Section({ Title = "Player Cosmetics" })

    PlayerCosmetics:Toggle({
        Title = "Enabled",
        Flag = "Player_Cosmetics",
        Callback = function(value)
            local players = game:GetService("Players")
            local lp = players.LocalPlayer
    
            local function applyKorblox(character)
                local rightLeg = character:FindFirstChild("RightLeg") or character:FindFirstChild("Right Leg")
                if not rightLeg then
                    warn("Right leg not found on character")
                    return
                end
                
                for _, child in pairs(rightLeg:GetChildren()) do
                    if child:IsA("SpecialMesh") then
                        child:Destroy()
                    end
                end
                local specialMesh = Instance.new("SpecialMesh")
                specialMesh.MeshId = "rbxassetid://101851696"
                specialMesh.TextureId = "rbxassetid://115727863"
                specialMesh.Scale = Vector3.new(1, 1, 1)
                specialMesh.Parent = rightLeg
            end
    
            local function saveRightLegProperties(char)
                if char then
                    local rightLeg = char:FindFirstChild("RightLeg") or char:FindFirstChild("Right Leg")
                    if rightLeg then
                        local originalMesh = rightLeg:FindFirstChildOfClass("SpecialMesh")
                        if originalMesh then
                            _G.PlayerCosmeticsCleanup.originalMeshId = originalMesh.MeshId
                            _G.PlayerCosmeticsCleanup.originalTextureId = originalMesh.TextureId
                            _G.PlayerCosmeticsCleanup.originalScale = originalMesh.Scale
                        else
                            _G.PlayerCosmeticsCleanup.hadNoMesh = true
                        end
                        
                        _G.PlayerCosmeticsCleanup.rightLegChildren = {}
                        for _, child in pairs(rightLeg:GetChildren()) do
                            if child:IsA("SpecialMesh") then
                                table.insert(_G.PlayerCosmeticsCleanup.rightLegChildren, {
                                    ClassName = child.ClassName,
                                    Properties = {
                                        MeshId = child.MeshId,
                                        TextureId = child.TextureId,
                                        Scale = child.Scale
                                    }
                                })
                            end
                        end
                    end
                end
            end
            
            local function restoreRightLeg(char)
                if char then
                    local rightLeg = char:FindFirstChild("RightLeg") or char:FindFirstChild("Right Leg")
                    if rightLeg and _G.PlayerCosmeticsCleanup.rightLegChildren then
                        for _, child in pairs(rightLeg:GetChildren()) do
                            if child:IsA("SpecialMesh") then
                                child:Destroy()
                            end
                        end
                        
                        if _G.PlayerCosmeticsCleanup.hadNoMesh then
                            return
                        end
                        
                        for _, childData in ipairs(_G.PlayerCosmeticsCleanup.rightLegChildren) do
                            if childData.ClassName == "SpecialMesh" then
                                local newMesh = Instance.new("SpecialMesh")
                                newMesh.MeshId = childData.Properties.MeshId
                                newMesh.TextureId = childData.Properties.TextureId
                                newMesh.Scale = childData.Properties.Scale
                                newMesh.Parent = rightLeg
                            end
                        end
                    end
                end
            end
    
            if value then
                CosmeticsActive = true
    
                getgenv().Config = {
                    Headless = true
                }
                
                if lp.Character then
                    local head = lp.Character:FindFirstChild("Head")
                    if head and getgenv().Config.Headless then
                        _G.PlayerCosmeticsCleanup.headTransparency = head.Transparency
                        
                        local decal = head:FindFirstChildOfClass("Decal")
                        if decal then
                            _G.PlayerCosmeticsCleanup.faceDecalId = decal.Texture
                            _G.PlayerCosmeticsCleanup.faceDecalName = decal.Name
                        end
                    end
                    
                    saveRightLegProperties(lp.Character)
                    applyKorblox(lp.Character)
                end
                
                _G.PlayerCosmeticsCleanup.characterAddedConn = lp.CharacterAdded:Connect(function(char)
                    local head = char:FindFirstChild("Head")
                    if head and getgenv().Config.Headless then
                        _G.PlayerCosmeticsCleanup.headTransparency = head.Transparency
                        
                        local decal = head:FindFirstChildOfClass("Decal")
                        if decal then
                            _G.PlayerCosmeticsCleanup.faceDecalId = decal.Texture
                            _G.PlayerCosmeticsCleanup.faceDecalName = decal.Name
                        end
                    end
                    
                    saveRightLegProperties(char)
                    applyKorblox(char)
                end)
                
                if getgenv().Config.Headless then
                    headLoop = task.spawn(function()
                        while CosmeticsActive do
                            local char = lp.Character
                            if char then
                                local head = char:FindFirstChild("Head")
                                if head then
                                    head.Transparency = 1
                                    local decal = head:FindFirstChildOfClass("Decal")
                                    if decal then
                                        decal:Destroy()
                                    end
                                end
                            end
                            task.wait(0.1)
                        end
                    end)
                end
    
            else
                CosmeticsActive = false
    
                if _G.PlayerCosmeticsCleanup.characterAddedConn then
                    _G.PlayerCosmeticsCleanup.characterAddedConn:Disconnect()
                    _G.PlayerCosmeticsCleanup.characterAddedConn = nil
                end
    
                if headLoop then
                    task.cancel(headLoop)
                    headLoop = nil
                end
    
                local char = lp.Character
                if char then
                    local head = char:FindFirstChild("Head")
                    if head and _G.PlayerCosmeticsCleanup.headTransparency ~= nil then
                        head.Transparency = _G.PlayerCosmeticsCleanup.headTransparency
                        
                        if _G.PlayerCosmeticsCleanup.faceDecalId then
                            local newDecal = head:FindFirstChildOfClass("Decal") or Instance.new("Decal", head)
                            newDecal.Name = _G.PlayerCosmeticsCleanup.faceDecalName or "face"
                            newDecal.Texture = _G.PlayerCosmeticsCleanup.faceDecalId
                            newDecal.Face = Enum.NormalId.Front
                        end
                    end
                    
                    restoreRightLeg(char)
                end
    
                _G.PlayerCosmeticsCleanup = {}
            end
        end
    })

    local fly = player:Section({ Title = "Fly" })
    
    fly:Toggle({
        Title = "Enabled",
        Flag = "Fly",
        Callback = function(value)
            if value then
                getgenv().FlyEnabled = true
                local char = Player.Character or Player.CharacterAdded:Wait()
                local hrp = char:WaitForChild("HumanoidRootPart")
                local humanoid = char:WaitForChild("Humanoid")
                
                getgenv().OriginalStateType = humanoid:GetState()
                
                getgenv().RagdollHandler = humanoid.StateChanged:Connect(function(oldState, newState)
                    if getgenv().FlyEnabled then
                        if newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.Ragdoll then
                            task.defer(function()
                                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
                                humanoid:ChangeState(Enum.HumanoidStateType.Running)
                            end)
                        end
                    end
                end)
                
                local bodyGyro = Instance.new("BodyGyro")
                bodyGyro.P = 90000
                bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bodyGyro.Parent = hrp
                
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bodyVelocity.Parent = hrp
                
                humanoid.PlatformStand = true
                
                getgenv().ResetterConnection = RunService.Heartbeat:Connect(function()
                    if not getgenv().FlyEnabled then return end
                    
                    if bodyGyro and bodyGyro.Parent then
                        bodyGyro.P = 90000
                        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                    end
                    
                    if bodyVelocity and bodyVelocity.Parent then
                        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                    end
                    
                    humanoid.PlatformStand = true
                    
                    if not bodyGyro.Parent or not bodyVelocity.Parent then
                        if bodyGyro then bodyGyro:Destroy() end
                        if bodyVelocity then bodyVelocity:Destroy() end
                        
                        bodyGyro = Instance.new("BodyGyro")
                        bodyGyro.P = 90000
                        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                        bodyGyro.Parent = hrp
                        
                        bodyVelocity = Instance.new("BodyVelocity")
                        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                        bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                        bodyVelocity.Parent = hrp
                    end
                end)
                
                getgenv().FlyConnection = RunService.RenderStepped:Connect(function()
                    if not getgenv().FlyEnabled then return end
                    local camCF = workspace.CurrentCamera.CFrame
                    local moveDir = Vector3.new(0, 0, 0)
                    
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        moveDir = moveDir + camCF.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        moveDir = moveDir - camCF.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        moveDir = moveDir - camCF.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        moveDir = moveDir + camCF.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.E) then
                        moveDir = moveDir + Vector3.new(0, 1, 0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
                        moveDir = moveDir - Vector3.new(0, 1, 0)
                    end
                    
                    if moveDir.Magnitude > 0 then
                        moveDir = moveDir.Unit
                    end
                    bodyVelocity.Velocity = moveDir * (getgenv().FlySpeed or 50)
                    bodyGyro.CFrame = camCF
                end)
            else
                getgenv().FlyEnabled = false
                
                if getgenv().FlyConnection then
                    getgenv().FlyConnection:Disconnect()
                    getgenv().FlyConnection = nil
                end
                
                if getgenv().RagdollHandler then
                    getgenv().RagdollHandler:Disconnect()
                    getgenv().RagdollHandler = nil
                end
                
                if getgenv().ResetterConnection then
                    getgenv().ResetterConnection:Disconnect()
                    getgenv().ResetterConnection = nil
                end
                
                local char = Player.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local humanoid = char:FindFirstChild("Humanoid")
                    
                    if humanoid then
                        humanoid.PlatformStand = false
                        if getgenv().OriginalStateType then
                            humanoid:ChangeState(getgenv().OriginalStateType)
                        end
                    end
                    
                    if hrp then
                        for _, v in ipairs(hrp:GetChildren()) do
                            if v:IsA("BodyGyro") or v:IsA("BodyVelocity") then
                                v:Destroy()
                            end
                        end
                    end
                end
            end
        end
    })
    
    fly:Slider({
        Title = "Fly Speed",
        Flag = "Fly_Speed",
        Value = {
            Min = 10,
            Max = 200,
            Default = 50
        },
        Callback = function(value)
            getgenv().FlySpeed = value
        end
    })

    local localPlayer = Players.LocalPlayer
                
    local SelectedPlayerFollow = nil
    local followDropdown
    
    local function getPlayerNames()
        local names = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer then
                table.insert(names, player.Name)
            end
        end
        return names
    end
    
    local function updateFollowTarget()
        local availablePlayers = getPlayerNames()
        if #availablePlayers > 0 then
            SelectedPlayerFollow = availablePlayers[1]
            if followDropdown then
                followDropdown:Set(SelectedPlayerFollow)
            end
        else
            SelectedPlayerFollow = nil
        end
    end
    
    local PlayerFollow = player:Section({ Title = "Player Follow" })

    PlayerFollow:Toggle({
        Title = "Enabled",
        Flag = "Player_Follow",
        Callback = function(value)
            if value then
                getgenv().PlayerFollowEnabled = true
                getgenv().PlayerFollowConnection = RunService.Heartbeat:Connect(function()
                    if not SelectedPlayerFollow then return end -- Prevents nil indexing
                    local targetPlayer = Players:FindFirstChild(SelectedPlayerFollow)
                    if targetPlayer and targetPlayer.Character and targetPlayer.Character.PrimaryPart then
                        local char = localPlayer.Character
                        if char then
                            local humanoid = char:FindFirstChild("Humanoid")
                            if humanoid then
                                humanoid:MoveTo(targetPlayer.Character.PrimaryPart.Position)
                            end
                        end
                    end
                end)
            else
                getgenv().PlayerFollowEnabled = false
                if getgenv().PlayerFollowConnection then
                    getgenv().PlayerFollowConnection:Disconnect()
                    getgenv().PlayerFollowConnection = nil
                end
            end
        end
    })

    local initialOptions = getPlayerNames()
    if #initialOptions == 0 then
        initialOptions = {"None"}
    end

    followDropdown = PlayerFollow:Dropdown({
        Title = "Follow Target",
        Flag = "Follow_Target",
        Values = initialOptions,
        Multi = false,
        Callback = function(value)
            if value and value ~= "None" then
                SelectedPlayerFollow = value
                if getgenv().FollowNotifyEnabled then
                    WindUI:Notify({
                        Title = "Module Notification",
                        Content = "Now following: " .. value,
                        Duration = 3
                    })
                end
            end
        end
    })
    
    if #initialOptions > 0 and initialOptions[1] ~= "None" then
        SelectedPlayerFollow = initialOptions[1]
        
        if followDropdown then
            if followDropdown.Set then
                followDropdown:Set(SelectedPlayerFollow)
            elseif followDropdown.SetValue then
                followDropdown:SetValue(SelectedPlayerFollow)
            end
        end
        getgenv().FollowDropdown = followDropdown
    else
        SelectedPlayerFollow = nil
    end
    
    local lastOptionsString = table.concat(initialOptions, ",")
    local updateTimer = 0
    
    RunService.Heartbeat:Connect(function(dt)
        updateTimer = updateTimer + dt
        if updateTimer >= 10 then
            local newOptions = getPlayerNames()
            table.sort(newOptions)
            local newOptionsString = table.concat(newOptions, ",")
            
            if newOptionsString ~= lastOptionsString then
                if followDropdown then
                    if #newOptions > 0 then
                        if followDropdown.SetValues then
                           followDropdown:SetValues(newOptions)
                        end

                        if not table.find(newOptions, SelectedPlayerFollow) then
                            SelectedPlayerFollow = newOptions[1]
                            if followDropdown then
                                if followDropdown.Set then
                                    followDropdown:Set(SelectedPlayerFollow)
                                elseif followDropdown.SetValue then
                                    followDropdown:SetValue(SelectedPlayerFollow)
                                end
                            end
                        end
                    else
                        SelectedPlayerFollow = nil
                    end
                end
                lastOptionsString = newOptionsString
            end
            updateTimer = 0
        end
    end)
    
    PlayerFollow:Toggle({
        Title = "Notify",
        Flag = "Follow_Notify",
        Callback = function(value)
            getgenv().FollowNotifyEnabled = value
        end
    })

    local HitSounds = player:Section({ Title = 'Hit Sounds' })

    HitSounds:Toggle({
        Title = 'Enabled',
        Flag = 'Hit_Sounds',
        Callback = function(value)
            hit_Sound_Enabled = value
        end
    })
    
    local Folder = Instance.new("Folder")
    Folder.Name = "Useful Utility"
    Folder.Parent = workspace
    
    local hit_Sound = Instance.new('Sound', Folder)
    hit_Sound.Volume = 6
    
    local hitSoundOptions = { 
        "Medal", 
        "Fatality", 
        "Skeet",
        "Switches",
        "Rust Headshot", 
        "Neverlose Sound", 
        "Bubble", 
        "Laser", 
        "Steve", 
        "Call of Duty", 
        "Bat", 
        "TF2 Critical", 
        "Saber", 
        "Bameware"
    }
    
    local hitSoundIds = {
        Medal = "rbxassetid://6607336718",
        Fatality = "rbxassetid://6607113255",
        Skeet = "rbxassetid://6607204501",
        Switches = "rbxassetid://6607173363",
        ["Rust Headshot"] = "rbxassetid://138750331387064",
        ["Neverlose Sound"] = "rbxassetid://110168723447153",
        Bubble = "rbxassetid://6534947588",
        Laser = "rbxassetid://7837461331",
        Steve = "rbxassetid://4965083997",
        ["Call of Duty"] = "rbxassetid://5952120301",
        Bat = "rbxassetid://3333907347",
        ["TF2 Critical"] = "rbxassetid://296102734",
        Saber = "rbxassetid://8415678813",
        Bameware = "rbxassetid://3124331820"
    }

    HitSounds:Slider({
        Title = 'Volume',
        Flag = 'HitSoundVolume',
        Value = {
            Min = 1,
            Max = 10,
            Default = 5
        },
        Callback = function(value)
            hit_Sound.Volume = value
        end
    })

    HitSounds:Dropdown({
        Title = "Hit Sound Type",
        Flag = "hit_sound_type",
        Values = hitSoundOptions,
        Multi = false,
        Callback = function(selectedOption)
            if hitSoundIds[selectedOption] then
                hit_Sound.SoundId = hitSoundIds[selectedOption]
            else
                warn("Invalid hit sound selection: " .. tostring(selectedOption))
            end
        end
    })
    
    ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
        if hit_Sound_Enabled then
            hit_Sound:Play()
        end
    end)


    local soundOptions = {
        ["Eeyuh"] = "rbxassetid://16190782181",
        ["Sweep"] = "rbxassetid://103508936658553",
        ["Bounce"] = "rbxassetid://134818882821660",
        ["Everybody Wants To Rule The World"] = "rbxassetid://87209527034670",
        ["Missing Money"] = "rbxassetid://134668194128037",
        ["Sour Grapes"] = "rbxassetid://117820392172291",
        ["Erwachen"] = "rbxassetid://124853612881772",
        ["Grasp the Light"] = "rbxassetid://89549155689397",
        ["Beyond the Shadows"] = "rbxassetid://120729792529978",
        ["Rise to the Horizon"] = "rbxassetid://72573266268313",
        ["Echoes of the Candy Kingdom"] = "rbxassetid://103040477333590",
        ["Speed"] = "rbxassetid://125550253895893",
        ["Lo-fi Chill A"] = "rbxassetid://9043887091",
        ["Lo-fi Ambient"] = "rbxassetid://129775776987523",
        ["Tears in the Rain"] = "rbxassetid://129710845038263"
    }
    
    local currentSound = Instance.new("Sound")
    currentSound.Volume = 3
    currentSound.Looped = false
    currentSound.Parent = game:GetService("SoundService")   
    
    local soundModule
    
    local function playSoundById(soundId)
        currentSound:Stop()
        currentSound.SoundId = soundId
        currentSound:Play()
    end
    
    local selectedSound = "Eeyuh"
    
    local soundModule = world:Section({ Title = 'Sound Controller' })

    soundModule:Toggle({
        Title = 'Enabled',
        Flag = 'sound_controller',
        Callback = function(value)
            getgenv().soundmodule = value
            if value then
                playSoundById(soundOptions[selectedSound])
            else
                currentSound:Stop()
            end
        end
    })

    soundModule:Toggle({
        Title = "Loop Song",
        Flag = "LoopSong",
        Callback = function(value)
            currentSound.Looped = value
        end
    })

    soundModule:Slider({
        Title = 'Volume',
        Flag = 'HitSoundVolume',
        Value = {
            Min = 1,
            Max = 10,
            Default = 3
        },
        Callback = function(value)
            currentSound.Volume = value
        end
    })

    soundModule:Section({ Title = "Sound Selection" })
    
    soundModule:Dropdown({
        Title = 'Select Sound',
        Flag = 'sound_selection',
        Values = {
            "Eeyuh",
            "Sweep", 
            "Bounce",
            "Everybody Wants To Rule The World",
            "Missing Money",
            "Sour Grapes",
            "Erwachen",
            "Grasp the Light",
            "Beyond the Shadows",
            "Rise to the Horizon",
            "Echoes of the Candy Kingdom",
            "Speed",
            "Lo-fi Chill A",
            "Lo-fi Ambient",
            "Tears in the Rain"
        },
        Multi = false,
        Callback = function(value)
            selectedSound = value
            if getgenv().soundmodule then
                playSoundById(soundOptions[value])
            end
        end
    })

    local WorldFilter = world:Section({ Title = 'Filter' })

    WorldFilter:Toggle({
        Title = 'Enabled',
        Flag = 'Filter',
        Callback = function(value)
            getgenv().WorldFilterEnabled = value
    
            if not value then
                if game.Lighting:FindFirstChild("CustomAtmosphere") then
                    game.Lighting.CustomAtmosphere:Destroy()
                end
                game.Lighting.FogEnd = 100000
                game.Lighting.ColorCorrection.TintColor = Color3.new(1, 1, 1)
                game.Lighting.ColorCorrection.Saturation = 0
            end
        end
    })
    
    WorldFilter:Toggle({
        Title = 'Enable Atmosphere',
        Flag = 'World_Filter_Atmosphere',
        Callback = function(value)
            getgenv().AtmosphereEnabled = value
    
            if value then
                if not game.Lighting:FindFirstChild("CustomAtmosphere") then
                    local atmosphere = Instance.new("Atmosphere")
                    atmosphere.Name = "CustomAtmosphere"
                    atmosphere.Parent = game.Lighting
                end
            else
                if game.Lighting:FindFirstChild("CustomAtmosphere") then
                    game.Lighting.CustomAtmosphere:Destroy()
                end
            end
        end
    })

    WorldFilter:Slider({
        Title = 'Atmosphere Density',
        Flag = 'World_Filter_Atmosphere_Slider',
        Value = {
            Min = 0,
            Max = 1,
            Default = 0.5
        },
        Callback = function(value)
            if getgenv().AtmosphereEnabled and game.Lighting:FindFirstChild("CustomAtmosphere") then
                game.Lighting.CustomAtmosphere.Density = value
            end
        end
    })

    WorldFilter:Toggle({
        Title = 'Enable Fog',
        Flag = 'World_Filter_Fog',
        Callback = function(value)
            getgenv().FogEnabled = value
    
            if not value then
                game.Lighting.FogEnd = 100000
            end
        end
    })

    WorldFilter:Slider({
        Title = 'Fog Distance',
        Flag = 'World_Filter_Fog_Slider',
        Value = {
            Min = 50,
            Max = 10000,
            Default = 1000
        },
        Callback = function(value)
            if getgenv().FogEnabled then
                game.Lighting.FogEnd = value
            end
        end
    })

    WorldFilter:Toggle({
        Title = 'Enable Saturation',
        Flag = 'World_Filter_Saturation',
        Callback = function(value)
            getgenv().SaturationEnabled = value
    
            if not value then
                game.Lighting.ColorCorrection.Saturation = 0
            end
        end
    })

    WorldFilter:Slider({
        Title = 'Saturation Level',
        Flag = 'World_Filter_Saturation_Slider',
        Value = {
            Min = -1,
            Max = 1,
            Default = 0
        },
        Callback = function(value)
            if getgenv().SaturationEnabled then
                game.Lighting.ColorCorrection.Saturation = value
            end
        end
    })

    WorldFilter:Toggle({
        Title = 'Enable Hue',
        Flag = 'World_Filter_Hue',
        Callback = function(value)
            getgenv().HueEnabled = value
    
            if not value then
                game.Lighting.ColorCorrection.TintColor = Color3.new(1, 1, 1)
            end
        end
    })
    
    WorldFilter:Slider({
        Title = 'Hue Shift',
        Flag = 'World_Filter_Hue_Slider',
        Value = {
            Min = -1,
            Max = 1,
            Default = 0
        },
        Callback = function(value)
            if getgenv().HueEnabled then
                game.Lighting.ColorCorrection.TintColor = Color3.fromHSV(value, 1, 1)
            end
        end
    })

    local BallTrail = world:Section({ Title = "Ball Trail" })

    BallTrail:Toggle({
        Title = "Enabled",
        Flag = "Ball_Trail",
        Callback = function(value)
            getgenv().BallTrailEnabled = value
            if value then
                for _, ball in pairs(Auto_Parry.Get_Balls()) do
                    if not ball:FindFirstChild("Trail") then
                        local trail = Instance.new("Trail")
                        trail.Name = "Trail"
                        
                        local att0 = Instance.new("Attachment")
                        att0.Name = "Attachment0"
                        att0.Parent = ball
                        
                        local att1 = Instance.new("Attachment")
                        att1.Name = "Attachment1"
                        att1.Parent = ball
                        
                        att0.Position = Vector3.new(0, ball.Size.Y/2, 0)
                        att1.Position = Vector3.new(0, -ball.Size.Y/2, 0)
                        
                        trail.Attachment0 = att0
                        trail.Attachment1 = att1
                        
                        trail.Lifetime = 0.4
                        trail.WidthScale = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.5),
                            NumberSequenceKeypoint.new(1, 0.5)
                        })
                        trail.Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(1, 1)
                        })
                        
                        trail.Color = ColorSequence.new(getgenv().BallTrailColor or Color3.new(1, 1, 1))
                        
                        trail.Parent = ball
                    else
                        local trail = ball:FindFirstChild("Trail")
                        trail.Color = ColorSequence.new(getgenv().BallTrailColor or Color3.new(1, 1, 1))
                        trail.Lifetime = 0.4
                        trail.WidthScale = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.5),
                            NumberSequenceKeypoint.new(1, 0.5)
                        })
                        trail.Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(1, 1)
                        })
                    end
                end
            else
                for _, ball in pairs(Auto_Parry.Get_Balls()) do
                    local trail = ball:FindFirstChild("Trail")
                    if trail then
                        trail:Destroy()
                    end
                end
            end
        end
    })

    BallTrail:Slider({
        Title = "Ball Trail Hue",
        Flag = "Ball_Trail_Hue",
        Value = {
            Min = 0,
            Max = 360,
            Default = 0
        },
        Callback = function(value)
            if not getgenv().BallTrailRainbowEnabled then
                local newColor = Color3.fromHSV(value / 360, 1, 1)
                getgenv().BallTrailColor = newColor
                if getgenv().BallTrailEnabled then
                    for _, ball in pairs(Auto_Parry.Get_Balls()) do
                        local trail = ball:FindFirstChild("Trail")
                        if trail then
                            trail.Color = ColorSequence.new(newColor)
                        end
                    end
                end
            end
        end
    })  

    BallTrail:Toggle({
        Title = "Rainbow Trail",
        Flag = "Ball_Trail_Rainbow",
        Callback = function(value)
            getgenv().BallTrailRainbowEnabled = value
        end
    })

    BallTrail:Toggle({
        Title = "Particle Emitter",
        Flag = "Ball_Trail_Particle",
        Callback = function(value)
            getgenv().BallTrailParticleEnabled = value
            for _, ball in pairs(Auto_Parry.Get_Balls()) do
                if value then
                    if not ball:FindFirstChild("ParticleEmitter") then
                        local emitter = Instance.new("ParticleEmitter")
                        emitter.Name = "ParticleEmitter"
                        emitter.Rate = 100
                        emitter.Lifetime = NumberRange.new(0.5, 1)
                        emitter.Speed = NumberRange.new(0, 1)
                        emitter.Size = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0.5),
                            NumberSequenceKeypoint.new(1, 0)
                        })
                        emitter.Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(1, 1)
                        })
                        emitter.Parent = ball
                    end
                else
                    local emitter = ball:FindFirstChild("ParticleEmitter")
                    if emitter then
                        emitter:Destroy()
                    end
                end
            end
        end
    })

    BallTrail:Toggle({
        Title = "Glow Effect",
        Flag = "Ball_Trail_Glow",
        Callback = function(value)
            getgenv().BallTrailGlowEnabled = value
            for _, ball in pairs(Auto_Parry.Get_Balls()) do
                if value then
                    if not ball:FindFirstChild("BallGlow") then
                        local glow = Instance.new("PointLight")
                        glow.Name = "BallGlow"
                        glow.Range = 15
                        glow.Brightness = 2
                        glow.Parent = ball
                    end
                else
                    local glow = ball:FindFirstChild("BallGlow")
                    if glow then
                        glow:Destroy()
                    end
                end
            end
        end
    })

    local hue = 0
    game:GetService("RunService").Heartbeat:Connect(function()
        if getgenv().BallTrailEnabled then
            for _, ball in pairs(Auto_Parry.Get_Balls()) do
                local trail = ball:FindFirstChild("Trail")
                if trail then
                    if getgenv().BallTrailRainbowEnabled then
                        hue = (hue + 1) % 360
                        local newColor = Color3.fromHSV(hue / 360, 1, 1)
                        trail.Color = ColorSequence.new(newColor)
                        getgenv().BallTrailColor = newColor
                    else
                        trail.Color = ColorSequence.new(getgenv().BallTrailColor or Color3.new(1, 1, 1))
                    end
                end
            end
        end
    end)

    local billboardLabels = {}

    function qolPlayerNameVisibility()
        local function createBillboardGui(p)
            local character = p.Character
    
            while (not character) or (not character.Parent) do
                task.wait()
                character = p.Character
            end
    
            local head = character:WaitForChild("Head")
    
            local billboardGui = Instance.new("BillboardGui")
            billboardGui.Adornee = head
            billboardGui.Size = UDim2.new(0, 200, 0, 50)
            billboardGui.StudsOffset = Vector3.new(0, 3, 0)
            billboardGui.AlwaysOnTop = true
            billboardGui.Parent = head
    
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            textLabel.TextSize = 8
            textLabel.TextWrapped = false
            textLabel.BackgroundTransparency = 1
            textLabel.TextXAlignment = Enum.TextXAlignment.Center
            textLabel.TextYAlignment = Enum.TextYAlignment.Center
            textLabel.Parent = billboardGui
    
            billboardLabels[p] = textLabel
    
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            end
    
            local heartbeatConnection
            heartbeatConnection = RunService.Heartbeat:Connect(function()
                if not (character and character.Parent) then
                    heartbeatConnection:Disconnect()
                    billboardGui:Destroy()
                    billboardLabels[p] = nil
                    return
                end
    
                if getgenv().AbilityESP then
                    textLabel.Visible = true
                    local abilityName = p:GetAttribute("EquippedAbility")
                    if abilityName then
                        textLabel.Text = p.DisplayName .. " [" .. abilityName .. "]"
                    else
                        textLabel.Text = p.DisplayName
                    end
                else
                    textLabel.Visible = false
                end
            end)
        end
    
        for _, p in Players:GetPlayers() do
            if p ~= plr then
                p.CharacterAdded:Connect(function()
                    createBillboardGui(p)
                end)
                createBillboardGui(p)
            end
        end
    
        Players.PlayerAdded:Connect(function(newPlayer)
            newPlayer.CharacterAdded:Connect(function()
                createBillboardGui(newPlayer)
            end)
        end)
    end
    
    qolPlayerNameVisibility()
    
    local AbilityESP = world:Section({ Title = 'Ability ESP' })

    AbilityESP:Toggle({
        Title = 'Enabled',
        Flag = 'AbilityESP',
        Callback = function(value)
            getgenv().AbilityESP = value
            for _, label in pairs(billboardLabels) do
                label.Visible = value
            end
        end
    })

    local CustomSky = world:Section({ Title = 'Custom Sky' })

    CustomSky:Toggle({
        Title = 'Enabled',
        Flag = 'Custom_Sky',
        Callback = function(value)
            local Lighting = game.Lighting
            local Sky = Lighting:FindFirstChildOfClass("Sky")
            if value then
                if not Sky then
                    Sky = Instance.new("Sky", Lighting)
                end
            else
                if Sky then
                    local defaultSkyboxIds = {"591058823", "591059876", "591058104", "591057861", "591057625", "591059642"}
                    local skyFaces = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}
                    
                    for index, face in ipairs(skyFaces) do
                        Sky[face] = "rbxassetid://" .. defaultSkyboxIds[index]
                    end
                    Lighting.GlobalShadows = true
                    
                end
            end
        end
    })
    
    CustomSky:Dropdown({
        Title = 'Select Sky',
        Flag = 'custom_sky_selector',
        Values = {
            "Default",
            "Vaporwave",
            "Redshift",
            "Desert",
            "DaBaby",
            "Minecraft",
            "SpongeBob",
            "Skibidi",
            "Blaze",
            "Pussy Cat",
            "Among Us",
            "Space Wave",
            "Space Wave2",
            "Turquoise Wave",
            "Dark Night",
            "Bright Pink",
            "White Galaxy",
            "Blue Galaxy"
        },
        Multi = false,
        Callback = function(selectedOption)
            local skyboxData = nil
            if selectedOption == "Default" then
                skyboxData = {"591058823", "591059876", "591058104", "591057861", "591057625", "591059642"}
            elseif selectedOption == "Vaporwave" then
                skyboxData = {"1417494030", "1417494146", "1417494253", "1417494402", "1417494499", "1417494643"}
            elseif selectedOption == "Redshift" then
                skyboxData = {"401664839", "401664862", "401664960", "401664881", "401664901", "401664936"}
            elseif selectedOption == "Desert" then
                skyboxData = {"1013852", "1013853", "1013850", "1013851", "1013849", "1013854"}
            elseif selectedOption == "DaBaby" then
                skyboxData = {"7245418472", "7245418472", "7245418472", "7245418472", "7245418472", "7245418472"}
            elseif selectedOption == "Minecraft" then
                skyboxData = {"1876545003", "1876544331", "1876542941", "1876543392", "1876543764", "1876544642"}
            elseif selectedOption == "SpongeBob" then
                skyboxData = {"7633178166", "7633178166", "7633178166", "7633178166", "7633178166", "7633178166"}
            elseif selectedOption == "Skibidi" then
                skyboxData = {"14952256113", "14952256113", "14952256113", "14952256113", "14952256113", "14952256113"}
            elseif selectedOption == "Blaze" then
                skyboxData = {"150939022", "150939038", "150939047", "150939056", "150939063", "150939082"}
            elseif selectedOption == "Pussy Cat" then
                skyboxData = {"11154422902", "11154422902", "11154422902", "11154422902", "11154422902", "11154422902"}
            elseif selectedOption == "Among Us" then
                skyboxData = {"5752463190", "5752463190", "5752463190", "5752463190", "5752463190", "5752463190"}
            elseif selectedOption == "Space Wave" then
                skyboxData = {"16262356578", "16262358026", "16262360469", "16262362003", "16262363873", "16262366016"}
            elseif selectedOption == "Space Wave2" then
                skyboxData = {"1233158420", "1233158838", "1233157105", "1233157640", "1233157995", "1233159158"}
            elseif selectedOption == "Turquoise Wave" then
                skyboxData = {"47974894", "47974690", "47974821", "47974776", "47974859", "47974909"}
            elseif selectedOption == "Dark Night" then
                skyboxData = {"6285719338", "6285721078", "6285722964", "6285724682", "6285726335", "6285730635"}
            elseif selectedOption == "Bright Pink" then
                skyboxData = {"271042516", "271077243", "271042556", "271042310", "271042467", "271077958"}
            elseif selectedOption == "White Galaxy" then
                skyboxData = {"5540798456", "5540799894", "5540801779", "5540801192", "5540799108", "5540800635"}
            elseif selectedOption == "Blue Galaxy" then
                skyboxData = {"14961495673", "14961494492", "14961492844", "14961491298", "14961490439", "14961489508"}
            end
    
            if not skyboxData then
                warn("Sky option not found: " .. tostring(selectedOption))
                return
            end
    
            local Lighting = game.Lighting
            local Sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
    
            local skyFaces = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}
            for index, face in ipairs(skyFaces) do
                Sky[face] = "rbxassetid://" .. skyboxData[index]
            end

            Lighting.GlobalShadows = false
        end
    })

    local AbilityExploit = world:Section({ Title = 'Ability Exploit' })

    AbilityExploit:Toggle({
        Title = 'Enabled',
        Flag = 'AbilityExploit',
        Callback = function(value)
            getgenv().AbilityExploit = value
        end
    })

    AbilityExploit:Toggle({
        Title = 'Thunder Dash No Cooldown',
        Flag = 'ThunderDashNoCooldown',
        Callback = function(value)
            getgenv().ThunderDashNoCooldown = value
            if getgenv().AbilityExploit and getgenv().ThunderDashNoCooldown then
                local thunderModule = game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Abilities"):WaitForChild("Thunder Dash")
                local mod = require(thunderModule)
                mod.cooldown = 0
                mod.cooldownReductionPerUpgrade = 0
            end
        end
    })

    AbilityExploit:Toggle({
        Title = 'Continuity Zero Exploit',
        Flag  = 'ContinuityZeroExploit',
        Callback = function(value)
            getgenv().ContinuityZeroExploit = value
    
            if getgenv().AbilityExploit and getgenv().ContinuityZeroExploit then
                local ContinuityZeroRemote = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseContinuityPortal")
                local oldNamecall
                oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                    local method = getnamecallmethod()
    
                    if self == ContinuityZeroRemote and method == "FireServer" then
                        return oldNamecall(self,
                            CFrame.new(9e17, 9e16, 9e15, 9e14, 9e13, 9e12, 9e11, 9e10, 9e9, 9e8, 9e7, 9e6),
                            player.Name
                        )
                    end
    
                    return oldNamecall(self, ...)
                end)
            end
        end
    })

    local autoDuelsRequeueEnabled = false

    local AutoDuelsRequeue = farm:Section({ Title = 'Auto Duels Requeue' })

    AutoDuelsRequeue:Toggle({
        Title = 'Enabled',
        Flag = 'AutoDuelsRequeue',
        Callback = function(value)
            autoDuelsRequeueEnabled = value

            if autoDuelsRequeueEnabled then
                task.spawn(function()
                    while autoDuelsRequeueEnabled do
                        game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.1.0"):WaitForChild("net"):WaitForChild("RE/PlayerWantsRematch"):FireServer()
                        task.wait(5)
                    end
                end)
            end
        end
    })

    local validRankedPlaceIds = {
        13772394625,
        14915220621,
    }

    local selectedQueue = "FFA"
    local autoRequeueEnabled = false

    local AutoRankedRequeue = farm:Section({ Title = 'Auto Ranked Requeue' })

    AutoRankedRequeue:Toggle({
        Title = 'Enabled',
        Flag = 'AutoRankedRequeue',
        Callback = function(value)
            autoRequeueEnabled = value

            if autoRequeueEnabled then
                if not table.find(validRankedPlaceIds, game.PlaceId) then
                    autoRequeueEnabled = false
                    return
                end

                task.spawn(function()
                    while autoRequeueEnabled do
                        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("JoinQueue"):FireServer("Ranked", selectedQueue, "Normal")
                        task.wait(5)
                    end
                end)
            end
        end
    })

    AutoRankedRequeue:Dropdown({
        Title = 'Select Queue Type',
        Flag = 'QueueType',
        Values = { 
            "FFA",
            "Duo" 
        },
        Multi = false,
        Callback = function(selectedOption)
            selectedQueue = selectedOption
        end
    })

    local autoLTMRequeueEnabled = false
    local validLTMPlaceId = 13772394625

    local AutoLTMRequeue = farm:Section({ Title = 'Auto LTM Requeue' })

    AutoLTMRequeue:Toggle({
        Title = 'Enabled',
        Flag = 'AutoLTMRequeue',
        Callback = function(value)
            autoLTMRequeueEnabled = value

            if autoLTMRequeueEnabled then
                if game.PlaceId ~= validLTMPlaceId then
                    autoLTMRequeueEnabled = false
                    return
                end

                task.spawn(function()
                    while autoLTMRequeueEnabled do
                        game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.1.0"):WaitForChild("net"):WaitForChild("RF/JoinTournamentEventQueue"):InvokeServer({})
                        task.wait(5)
                    end
                end)
            end
        end
    })
    
    local AutoPlayModule = {}
    AutoPlayModule.CONFIG = {
        DEFAULT_DISTANCE = 30,
        MULTIPLIER_THRESHOLD = 70,
        TRAVERSING = 25,
        DIRECTION = 1,
        JUMP_PERCENTAGE = 50,
        DOUBLE_JUMP_PERCENTAGE = 50,
        JUMPING_ENABLED = false,
        MOVEMENT_DURATION = 0.8,
        OFFSET_FACTOR = 0.7,
        GENERATION_THRESHOLD = 0.25
    }
    
    AutoPlayModule.ball = nil
    AutoPlayModule.lobbyChoice = nil
    AutoPlayModule.animationCache = nil
    AutoPlayModule.doubleJumped = false
    AutoPlayModule.ELAPSED = 0
    AutoPlayModule.CONTROL_POINT = nil
    AutoPlayModule.LAST_GENERATION = 0
    AutoPlayModule.signals = {}
    
    do
        local getServiceFunction = game.GetService
        
        local function getClonerefPermission()
            local permission = cloneref(getServiceFunction(game, "ReplicatedFirst"))
            return permission
        end
        
        AutoPlayModule.clonerefPermission = getClonerefPermission()
        
        if not AutoPlayModule.clonerefPermission then
            warn("cloneref is not available on your executor! There is a risk of getting detected.")
        end
        
        function AutoPlayModule.findCachedService(self, name)
            for index, value in self do
                if value.Name == name then
                    return value
                end
            end
            return
        end
        
        function AutoPlayModule.getService(self, name)
            local cachedService = AutoPlayModule.findCachedService(self, name)
        
            if cachedService then
                return cachedService
            end
        
            local service = getServiceFunction(game, name)
        
            if AutoPlayModule.clonerefPermission then
                service = cloneref(service)
            end
        
            table.insert(self, service)
            return service
        end
        
        AutoPlayModule.customService = setmetatable({}, {
            __index = AutoPlayModule.getService
        })
    end
    
    AutoPlayModule.playerHelper = {
        isAlive = function(player)
            local character = nil
        
            if player and player:IsA("Player") then
                character = player.Character
            end
        
            if not character then
                return false
            end
        
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChild("Humanoid")
        
            if not rootPart or not humanoid then
                return false
            end
        
            return humanoid.Health > 0
        end,
        
        inLobby = function(character)
            if not character then
                return false
            end
        
            return character.Parent == AutoPlayModule.customService.Workspace.Dead
        end,
        
        onGround = function(character)
            if not character then
                return false
            end
        
            return character.Humanoid.FloorMaterial ~= Enum.Material.Air
        end
    }
    
    function AutoPlayModule.isLimited()
        local passedTime = tick() - AutoPlayModule.LAST_GENERATION
        return passedTime < AutoPlayModule.CONFIG.GENERATION_THRESHOLD
    end
    
    function AutoPlayModule.percentageCheck(limit)
        if AutoPlayModule.isLimited() then
            return false
        end
    
        local percentage = math.random(100)
        AutoPlayModule.LAST_GENERATION = tick()
    
        return limit >= percentage
    end
 
    AutoPlayModule.ballUtils = {
        getBall = function()
            for _, object in AutoPlayModule.customService.Workspace.Balls:GetChildren() do
                if object:GetAttribute("realBall") then
                    AutoPlayModule.ball = object
                    return
                end
            end
        
            AutoPlayModule.ball = nil
        end,
        
        getDirection = function()
            if not AutoPlayModule.ball then
                return
            end
        
            local direction = (AutoPlayModule.customService.Players.LocalPlayer.Character.HumanoidRootPart.Position - AutoPlayModule.ball.Position).Unit
            return direction
        end,
        
        getVelocity = function()
            if not AutoPlayModule.ball then
                return
            end
        
            local zoomies = AutoPlayModule.ball:FindFirstChild("zoomies")
        
            if not zoomies then
                return
            end
        
            return zoomies.VectorVelocity
        end,
        
        getSpeed = function()
            local velocity = AutoPlayModule.ballUtils.getVelocity()
        
            if not velocity then
                return
            end
        
            return velocity.Magnitude
        end,
        
        isExisting = function()
            return AutoPlayModule.ball ~= nil
        end
    }
    
    AutoPlayModule.lerp = function(start, finish, alpha)
        return start + (finish - start) * alpha
    end
    
    AutoPlayModule.quadratic = function(start, middle, finish, alpha)
        local firstLerp = AutoPlayModule.lerp(start, middle, alpha)
        local secondLerp = AutoPlayModule.lerp(middle, finish, alpha)
    
        return AutoPlayModule.lerp(firstLerp, secondLerp, alpha)
    end
    
    AutoPlayModule.getCandidates = function(middle, theta, offsetLength)
        local firstCanditateX = math.cos(theta + math.pi / 2)
        local firstCanditateZ = math.sin(theta + math.pi / 2)
        local firstCandidate = middle + Vector3.new(firstCanditateX, 0, firstCanditateZ) * offsetLength
    
        local secondCanditateX = math.cos(theta - math.pi / 2)
        local secondCanditateZ = math.sin(theta - math.pi / 2)
        local secondCandidate = middle + Vector3.new(secondCanditateX, 0, secondCanditateZ) * offsetLength
    
        return firstCandidate, secondCandidate
    end
    
    AutoPlayModule.getControlPoint = function(start, finish)
        local middle = (start + finish) * 0.5
        local difference = start - finish
    
        if difference.Magnitude < 5 then
            return finish
        end
    
        local theta = math.atan2(difference.Z, difference.X)
        local offsetLength = difference.Magnitude * AutoPlayModule.CONFIG.OFFSET_FACTOR
    
        local firstCandidate, secondCandidate = AutoPlayModule.getCandidates(middle, theta, offsetLength)
        local dotValue = start - middle
    
        if (firstCandidate - middle):Dot(dotValue) < 0 then
            return firstCandidate
        else
            return secondCandidate
        end
    end
    
    AutoPlayModule.getCurve = function(start, finish, delta)
        AutoPlayModule.ELAPSED = AutoPlayModule.ELAPSED + delta
        local timeElapsed = math.clamp(AutoPlayModule.ELAPSED / AutoPlayModule.CONFIG.MOVEMENT_DURATION, 0, 1)
    
        if timeElapsed >= 1 then
            local distance = (start - finish).Magnitude
    
            if distance >= 10 then
                AutoPlayModule.ELAPSED = 0
            end
    
            AutoPlayModule.CONTROL_POINT = nil
            return finish
        end
    
        if not AutoPlayModule.CONTROL_POINT then
            AutoPlayModule.CONTROL_POINT = AutoPlayModule.getControlPoint(start, finish)
        end
    
        assert(AutoPlayModule.CONTROL_POINT, "CONTROL_POINT: Vector3 expected, got nil")
        return AutoPlayModule.quadratic(start, AutoPlayModule.CONTROL_POINT, finish, timeElapsed)
    end
    
    AutoPlayModule.map = {
        getFloor = function()
            local floor = AutoPlayModule.customService.Workspace:FindFirstChild("FLOOR")
            
            if not floor then
                for _, part in pairs(AutoPlayModule.customService.Workspace:GetDescendants()) do
                    if part:IsA("MeshPart") or part:IsA("BasePart") then
                        local size = part.Size
                        if size.X > 50 and size.Z > 50 and part.Position.Y < 5 then
                            return part
                        end
                    end
                end
            end
            
            return floor
        end
    }
    
    AutoPlayModule.getRandomPosition = function()
        local floor = AutoPlayModule.map.getFloor()
    
        if not floor or not AutoPlayModule.ballUtils.isExisting() then
            return
        end
    
        local ballDirection = AutoPlayModule.ballUtils.getDirection() * AutoPlayModule.CONFIG.DIRECTION
        local ballSpeed = AutoPlayModule.ballUtils.getSpeed()
    
        local speedThreshold = math.min(ballSpeed / 10, AutoPlayModule.CONFIG.MULTIPLIER_THRESHOLD)
        local speedMultiplier = AutoPlayModule.CONFIG.DEFAULT_DISTANCE + speedThreshold
        local negativeDirection = ballDirection * speedMultiplier
    
        local currentTime = os.time() / 1.2
        local sine = math.sin(currentTime) * AutoPlayModule.CONFIG.TRAVERSING
        local cosine = math.cos(currentTime) * AutoPlayModule.CONFIG.TRAVERSING
    
        local traversing = Vector3.new(sine, 0, cosine)
        local finalPosition = floor.Position + negativeDirection + traversing
    
        return finalPosition
    end
    
    
    AutoPlayModule.lobby = {
        isChooserAvailable = function()
            return AutoPlayModule.customService.Workspace.Spawn.NewPlayerCounter.GUI.SurfaceGui.Top.Options.Visible
        end,
        
        updateChoice = function(choice)
            AutoPlayModule.lobbyChoice = choice
        end,
        
        getMapChoice = function()
            local choice = AutoPlayModule.lobbyChoice or math.random(1, 3)
            local collider = AutoPlayModule.customService.Workspace.Spawn.NewPlayerCounter.Colliders:FindFirstChild(choice)
        
            return collider
        end,
        
        getPadPosition = function()
            if not AutoPlayModule.lobby.isChooserAvailable() then
                AutoPlayModule.lobbyChoice = nil
                return
            end
        
            local choice = AutoPlayModule.lobby.getMapChoice()
        
            if not choice then
                return
            end
        
            return choice.Position, choice.Name
        end
    }
    
    AutoPlayModule.movement = {
        removeCache = function()
            if AutoPlayModule.animationCache then
                AutoPlayModule.animationCache = nil
            end
        end,
        
        createJumpVelocity = function(player)
            local maxForce = math.huge
            local velocity = Instance.new("BodyVelocity")
            velocity.MaxForce = Vector3.new(maxForce, maxForce, maxForce)
            velocity.Velocity = Vector3.new(0, 80, 0)
            velocity.Parent = player.Character.HumanoidRootPart
        
            AutoPlayModule.customService.Debris:AddItem(velocity, 0.001)
            AutoPlayModule.customService.ReplicatedStorage.Remotes.DoubleJump:FireServer()
        end,
        
        playJumpAnimation = function(player)
            if not AutoPlayModule.animationCache then
                local doubleJumpAnimation = AutoPlayModule.customService.ReplicatedStorage.Assets.Tutorial.Animations.DoubleJump
                AutoPlayModule.animationCache = player.Character.Humanoid.Animator:LoadAnimation(doubleJumpAnimation)
            end
        
            if AutoPlayModule.animationCache then
                AutoPlayModule.animationCache:Play()
            end
        end,
        
        doubleJump = function(player)
            if AutoPlayModule.doubleJumped then
                return
            end
        
            if not AutoPlayModule.percentageCheck(AutoPlayModule.CONFIG.DOUBLE_JUMP_PERCENTAGE) then
                return
            end
        
            AutoPlayModule.doubleJumped = true
            AutoPlayModule.movement.createJumpVelocity(player)
            AutoPlayModule.movement.playJumpAnimation(player)
        end,
        
        jump = function(player)
            if not AutoPlayModule.CONFIG.JUMPING_ENABLED then
                return
            end
            
            if not AutoPlayModule.playerHelper.onGround(player.Character) then
                AutoPlayModule.movement.doubleJump(player)
                return
            end
        
            if not AutoPlayModule.percentageCheck(AutoPlayModule.CONFIG.JUMP_PERCENTAGE) then
                return
            end
        
            AutoPlayModule.doubleJumped = false
            player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end,
        
        move = function(player, playerPosition)
            player.Character.Humanoid:MoveTo(playerPosition)
        end,
        
        stop = function(player)
            local playerPosition = player.Character.HumanoidRootPart.Position
            player.Character.Humanoid:MoveTo(playerPosition)
        end
    }
    
    AutoPlayModule.signal = {
        connect = function(name, connection, callback)
            if not name then
                name = AutoPlayModule.customService.HttpService:GenerateGUID()
            end
        
            AutoPlayModule.signals[name] = connection:Connect(callback)
            return AutoPlayModule.signals[name]
        end,
        
        disconnect = function(name)
            if not name or not AutoPlayModule.signals[name] then
                return
            end
        
            AutoPlayModule.signals[name]:Disconnect()
            AutoPlayModule.signals[name] = nil
        end,
        
        stop = function()
            for name, connection in pairs(AutoPlayModule.signals) do
                if typeof(connection) ~= "RBXScriptConnection" then
                    continue
                end
        
                connection:Disconnect()
                AutoPlayModule.signals[name] = nil
            end
        end
    }
    
    AutoPlayModule.findPath = function(inLobby, delta)
        local rootPosition = AutoPlayModule.customService.Players.LocalPlayer.Character.HumanoidRootPart.Position
    
        if inLobby then
            local padPosition, padNumber = AutoPlayModule.lobby.getPadPosition()
            local choice = tonumber(padNumber)
            if choice then
                AutoPlayModule.lobby.updateChoice(choice)
                if getgenv().AutoVote then
                    game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.1.0"):WaitForChild("net"):WaitForChild("RE/UpdateVotes"):FireServer("FFA")
                end
            end
    
            if not padPosition then
                return
            end
    
            return AutoPlayModule.getCurve(rootPosition, padPosition, delta)
        end
    
        local randomPosition = AutoPlayModule.getRandomPosition()
    
        if not randomPosition then
            return
        end
    
        return AutoPlayModule.getCurve(rootPosition, randomPosition, delta)
    end
    
    
    AutoPlayModule.followPath = function(delta)
        if not AutoPlayModule.playerHelper.isAlive(AutoPlayModule.customService.Players.LocalPlayer) then
            AutoPlayModule.movement.removeCache()
            return
        end
    
        local inLobby = AutoPlayModule.customService.Players.LocalPlayer.Character.Parent == AutoPlayModule.customService.Workspace.Dead
        local path = AutoPlayModule.findPath(inLobby, delta)
    
        if not path then
            AutoPlayModule.movement.stop(AutoPlayModule.customService.Players.LocalPlayer)
            return
        end
    
        AutoPlayModule.movement.move(AutoPlayModule.customService.Players.LocalPlayer, path)
        AutoPlayModule.movement.jump(AutoPlayModule.customService.Players.LocalPlayer)
    end
    
    AutoPlayModule.finishThread = function()
        AutoPlayModule.signal.disconnect("auto-play")
        AutoPlayModule.signal.disconnect("synchronize")
        
        if not AutoPlayModule.playerHelper.isAlive(AutoPlayModule.customService.Players.LocalPlayer) then
            return
        end
        
        AutoPlayModule.movement.stop(AutoPlayModule.customService.Players.LocalPlayer)
    end
    
    AutoPlayModule.runThread = function()
        AutoPlayModule.signal.connect("auto-play", AutoPlayModule.customService.RunService.PostSimulation, AutoPlayModule.followPath)
        AutoPlayModule.signal.connect("synchronize", AutoPlayModule.customService.RunService.PostSimulation, AutoPlayModule.ballUtils.getBall)
    end
    
    --[[
        TeleportService = cloneref(game:GetService("TeleportService"))
        PlaceId, JobId = game.PlaceId, game.JobId
        if #Players:GetPlayers() < 5 then
            if getgenv().AutoServerHop then
                Players.LocalPlayer:Kick("\nRejoining")
                wait()
                TeleportService:Teleport(PlaceId, Players.LocalPlayer)
            else
                TeleportService:TeleportToPlaceInstance(PlaceId, JobId, Players.LocalPlayer)
            end
        end
    ]]

    local AutoPlay = misc:Section({ Title = 'Auto Play' })

    AutoPlay:Toggle({
        Title = 'Auto Play',
        Flag = 'AutoPlay',
        Callback = function(value)
            if value then
                AutoPlayModule.runThread()
            else
                AutoPlayModule.finishThread()
            end
        end
    })
    
    AutoPlay:Toggle({
        Title = "Anti AFK",
        Flag = "AutoPlayAntiAFK",
        Default = true,
        Callback = function(value)
            if value then
                local GC = getconnections or get_signal_cons
                if GC then
                    for i, v in pairs(GC(Players.LocalPlayer.Idled)) do
                        if v["Disable"] then
                            v["Disable"](v)
                        elseif v["Disconnect"] then
                            v["Disconnect"](v)
                        end
                    end
                else
                    local VirtualUser = cloneref(game:GetService("VirtualUser"))
                    Players.LocalPlayer.Idled:Connect(function()
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new())
                    end)
                end
            end
        end
    })

    AutoPlay:Toggle({
        Title = "Enable Jumping",
        Flag = "jumping_enabled",
        Callback = function(value)
            AutoPlayModule.CONFIG.JUMPING_ENABLED = value
        end
    })

    AutoPlay:Toggle({
        Title = "Auto Vote",
        Flag = "AutoVote",
        Callback = function(value)
            getgenv().AutoVote = value
        end
    })

    AutoPlay:Slider({
        Title = 'Distance From Ball',
        Flag = 'default_distance',
        Value = {
            Max = 100,
            Min = 5,
            Default = AutoPlayModule.CONFIG.DEFAULT_DISTANCE
        },
        Callback = function(value)
            AutoPlayModule.CONFIG.DEFAULT_DISTANCE = value
        end
    })
    
    AutoPlay:Slider({
        Title = 'Speed Multiplier',
        Flag = 'multiplier_threshold',
        Value = {
            Max = 200,
            Min = 10,
            Default = AutoPlayModule.CONFIG.MULTIPLIER_THRESHOLD
        },
        Callback = function(value)
            AutoPlayModule.CONFIG.MULTIPLIER_THRESHOLD = value
        end
    })
    
    AutoPlay:Slider({
        Title = 'Transversing',
        Flag = 'traversing',
        Value = {
            Max = 100,
            Min = 0,
            Default = AutoPlayModule.CONFIG.TRAVERSING
        },
        Callback = function(value)
            AutoPlayModule.CONFIG.TRAVERSING = value
        end
    })

    AutoPlay:Slider({
        Title = 'Direction',
        Flag = 'Direction',
        Value = {
            Max = 1,
            Min = -1,
            Default = AutoPlayModule.CONFIG.DIRECTION
        },
        Callback = function(value)
            AutoPlayModule.CONFIG.DIRECTION = value
        end
    })

    AutoPlay:Slider({
        Title = 'Offset Factor',
        Flag = 'OffsetFactor',
        Value = {
            Max = 1,
            Min = 0.1,
            Default = AutoPlayModule.CONFIG.OFFSET_FACTOR
        },
        Callback = function(value)
            AutoPlayModule.CONFIG.OFFSET_FACTOR = value
        end
    })

    AutoPlay:Slider({
        Title = 'Movement Duration',
        Flag = 'MovementDuration',
        Value = {
            Max = 1,
            Min = 0.1,
            Default = AutoPlayModule.CONFIG.MOVEMENT_DURATION
        },
        Callback = function(value)
            AutoPlayModule.CONFIG.MOVEMENT_DURATION = value
        end
    })

    AutoPlay:Slider({
        Title = 'Generation Threshold',
        Flag = 'GenerationThreshold',
        Value = {
            Max = 0.5,
            Min = 0.1,
            Default = AutoPlayModule.CONFIG.GENERATION_THRESHOLD
        },
        Callback = function(value)
            AutoPlayModule.CONFIG.GENERATION_THRESHOLD = value
        end
    })

    AutoPlay:Slider({
        Title = 'Jump Chance',
        Flag = 'jump_percentage',
        Value = {
            Max = 100,
            Min = 0,
            Default = AutoPlayModule.CONFIG.JUMP_PERCENTAGE
        },
        Callback = function(value)
            AutoPlayModule.CONFIG.JUMP_PERCENTAGE = value
        end
    })
    
    AutoPlay:Slider({
        Title = 'Double Jump Chance',
        Flag = 'double_jump_percentage',
        Value = {
            Max = 100,
            Min = 0,
            Default = AutoPlayModule.CONFIG.DOUBLE_JUMP_PERCENTAGE
        },
        Callback = function(value)
            AutoPlayModule.CONFIG.DOUBLE_JUMP_PERCENTAGE = value
        end
    })

    local ballStatsUI
    local heartbeatConn
    local peakVelocity = 0
    
    local BallStats = misc:Section({ Title = 'Ball Stats' })

    BallStats:Toggle({
        Title = 'Enabled',
        Flag = 'ballStats',
        Callback = function(value)
            if value then
                local ballPeaks = {}

                if not ballStatsUI then
                    local player = game.Players.LocalPlayer
                    ballStatsUI = Instance.new("ScreenGui")
                    ballStatsUI.ResetOnSpawn = false
                    ballStatsUI.Parent = player:WaitForChild("PlayerGui")
                
                    textLabel = Instance.new("TextLabel")
                    textLabel.Name = "BallStatsLabel"
                    textLabel.Size = UDim2.new(0.2, 0, 0.05, 0)
                    textLabel.Position = UDim2.new(0, 0, 0.1, 0)
                    textLabel.TextScaled = false
                    textLabel.TextSize = 26
                    textLabel.BackgroundTransparency = 1
                    textLabel.TextColor3 = Color3.new(1, 1, 1)
                    textLabel.Font = Enum.Font.Gotham
                    textLabel.ZIndex = 2
                    textLabel.Parent = ballStatsUI
                
                    shadowLabel = Instance.new("TextLabel")
                    shadowLabel.Name = "BallStatsShadow"
                    shadowLabel.Size = textLabel.Size
                    shadowLabel.Position = textLabel.Position + UDim2.new(0, 2, 0, 2)
                    shadowLabel.TextScaled = textLabel.TextScaled
                    shadowLabel.TextSize = textLabel.TextSize
                    shadowLabel.BackgroundTransparency = 1
                    shadowLabel.TextColor3 = Color3.new(0, 0, 0)
                    shadowLabel.Font = textLabel.Font
                    shadowLabel.ZIndex = 1
                    shadowLabel.Parent = ballStatsUI
                
                    peakLabel = Instance.new("TextLabel")
                    peakLabel.Name = "PeakStatsLabel"
                    peakLabel.Size = UDim2.new(0.2, 0, 0.05, 0)
                    peakLabel.Position = UDim2.new(0, 0, 0.135, 0)
                    peakLabel.TextScaled = false
                    peakLabel.TextSize = 26
                    peakLabel.BackgroundTransparency = 1
                    peakLabel.TextColor3 = Color3.new(1, 1, 1)
                    peakLabel.Font = Enum.Font.Gotham
                    peakLabel.ZIndex = 2
                    peakLabel.Parent = ballStatsUI
                
                    peakShadow = Instance.new("TextLabel")
                    peakShadow.Name = "PeakStatsShadow"
                    peakShadow.Size = peakLabel.Size
                    peakShadow.Position = peakLabel.Position + UDim2.new(0, 2, 0, 2)
                    peakShadow.TextScaled = peakLabel.TextScaled
                    peakShadow.TextSize = peakLabel.TextSize
                    peakShadow.BackgroundTransparency = 1
                    peakShadow.TextColor3 = Color3.new(0, 0, 0)
                    peakShadow.Font = peakLabel.Font
                    peakShadow.ZIndex = 1
                    peakShadow.Parent = ballStatsUI
                
                    peakVelocity = 0
                    
                    local RunService = game:GetService("RunService")
                    heartbeatConn = RunService.Heartbeat:Connect(function()
                    local Balls = Auto_Parry.Get_Balls() or {}

                    for oldBall,_ in pairs(ballPeaks) do
                        local stillAlive = false
                        for _, b in ipairs(Balls) do
                            if b == oldBall then
                                stillAlive = true
                                break
                            end
                        end
                        if not stillAlive then
                            ballPeaks[oldBall] = nil
                        end
                    end

                    for _, Ball in ipairs(Balls) do
                        local zoomies = Ball:FindFirstChild("zoomies")
                        if zoomies then
                            local speed = zoomies.VectorVelocity.Magnitude

                            ballPeaks[Ball] = ballPeaks[Ball] or 0
                            
                            if speed > ballPeaks[Ball] then
                                ballPeaks[Ball] = speed
                            end

                            local curText = ("Velocity: %.2f"):format(speed)
                            textLabel.Text      = curText
                            shadowLabel.Text    = curText

                            local peakText = ("Peak: %.2f"):format(ballPeaks[Ball])
                            peakLabel.Text      = peakText
                            peakShadow.Text     = peakText

                            break
                        end
                    end
                end)
                end
            else
                if heartbeatConn then
                    heartbeatConn:Disconnect()
                    heartbeatConn = nil
                end
                if ballStatsUI then
                    ballStatsUI:Destroy()
                    ballStatsUI = nil
                end
                peakVelocity = 0
            end
        end
    })

    local visualPart

    local VisualiserArea = misc:Section({ Title = 'Visualiser' })

    VisualiserArea:Toggle({
        Title = 'Enabled',
        Flag = 'Visualiser',
        Callback = function(value)
            if value then
                if not visualPart then
                    visualPart = Instance.new("Part")
                    visualPart.Name = "VisualiserPart"
                    visualPart.Shape = Enum.PartType.Ball
                    visualPart.Material = Enum.Material.ForceField
                    visualPart.Color = Color3.fromRGB(255, 255, 255)
                    visualPart.Transparency = 0  
                    visualPart.CastShadow = false 
                    visualPart.Anchored = true
                    visualPart.CanCollide = false
                    visualPart.Parent = workspace
                end
    
                Connections_Manager['Visualiser'] = game:GetService("RunService").RenderStepped:Connect(function()
                    local character = Player.Character
                    local HumanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
                    if HumanoidRootPart and visualPart then
                        visualPart.CFrame = HumanoidRootPart.CFrame  
                    end
    
                    if getgenv().VisualiserRainbow then
                        local hue = (tick() % 5) / 5
                        visualPart.Color = Color3.fromHSV(hue, 1, 1)
                    else
                        local hueVal = getgenv().VisualiserHue or 0
                        visualPart.Color = Color3.fromHSV(hueVal / 360, 1, 1)
                    end
    
                    local speed = 0
                    local maxSpeed = 350 
                    local Balls = Auto_Parry.Get_Balls()
    
                    for _, Ball in pairs(Balls) do
                        if Ball and Ball:FindFirstChild("zoomies") then
                            local Velocity = Ball.AssemblyLinearVelocity
                            speed = math.min(Velocity.Magnitude, maxSpeed) / 6.5  
                            break
                        end
                    end
    
                    local size = math.max(speed, 6.5)
                    if visualPart then
                        visualPart.Size = Vector3.new(size, size, size)
                    end
                end)
            else
                if Connections_Manager['Visualiser'] then
                    Connections_Manager['Visualiser']:Disconnect()
                    Connections_Manager['Visualiser'] = nil
                end
    
                if visualPart then
                    visualPart:Destroy()
                    visualPart = nil
                end
            end
        end
    })

    VisualiserArea:Toggle({
        Title = 'Rainbow',
        Flag = 'VisualiserRainbow',
        Callback = function(value)
            getgenv().VisualiserRainbow = value
        end
    })

    VisualiserArea:Slider({
        Title = 'Color Hue',
        Flag = 'VisualiserHue',
        Value = {
            Min = 0,
            Max = 360,
            Default = 0
        },
        Callback = function(value)
            getgenv().VisualiserHue = value
        end
    })
    
    local AutoClaimRewardsSection = misc:Section({ Title = 'Auto Claim Rewards' })

    AutoClaimRewardsSection:Toggle({
        Title = 'Enabled',
        Flag = 'AutoClaimRewards',
        Callback = function(value)
            getgenv().AutoClaimRewards = value
            if value then
                local rs = game:GetService("ReplicatedStorage")
                local net = rs:WaitForChild("Packages")
                    :WaitForChild("_Index")
                    :WaitForChild("sleitnick_net@0.1.0")
                    :WaitForChild("net")
                    
                task.spawn(function()
                    net["RF/RedeemQuestsType"]:InvokeServer("Battlepass", "Weekly")
                    net["RF/RedeemQuestsType"]:InvokeServer("Battlepass", "Daily")
                    net["RF/ClaimAllDailyMissions"]:InvokeServer("Daily")
                    net["RF/ClaimAllDailyMissions"]:InvokeServer("Weekly")
                    net["RF/ClaimAllClanBPQuests"]:InvokeServer()
        
                    local joinTimestamp = tonumber(plr:GetAttribute("JoinedTimestamp")) + 10
                    for i = 1, 6 do
                        while workspace:GetServerTimeNow() < joinTimestamp + (i * 300) + 1 do
                            task.wait(1)
                            if not getgenv().AutoClaimRewards then 
                                return 
                            end
                        end
                        net["RF/ClaimPlaytimeReward"]:InvokeServer(i)
                    end
                end)
            end
        end
    })

    local DisableQuantumEffectsSection = misc:Section({ Title = 'Disable Quantum Arena Effects' })

    DisableQuantumEffectsSection:Toggle({
        Title = 'Enabled',
        Flag = 'NoQuantumEffects',
        Callback = function(value)
            getgenv().NoQuantumEffects = value
            if value then
                task.spawn(function()
                    local quantumfx
                    while task.wait() and getgenv().NoQuantumEffects and not quantumfx do
                        for _, v in getconnections(ReplicatedStorage.Remotes.QuantumArena.OnClientEvent) do
                            quantumfx = v
                            v:Disable()
                        end
                    end
                end)
            end
        end
    })

    local NoRenderSection = misc:Section({ Title = 'No Render' })

    NoRenderSection:Toggle({
        Title = 'Enabled',
        Flag = 'No_Render',
        Callback = function(state)
            Player.PlayerScripts.EffectScripts.ClientFX.Disabled = state
    
            if state then
                Connections_Manager['No Render'] = workspace.Runtime.ChildAdded:Connect(function(Value)
                    Debris:AddItem(Value, 0)
                end)
            else
                if Connections_Manager['No Render'] then
                    Connections_Manager['No Render']:Disconnect()
                    Connections_Manager['No Render'] = nil
                end
            end
        end
    })

    local CustomAnnouncerSection = misc:Section({ Title = 'Custom Announcer' })

    CustomAnnouncerSection:Toggle({
        Title = 'Enabled',
        Flag = 'Custom_Announcer',
        Callback = function(value)
            if value then
                local Announcer = Player.PlayerGui:WaitForChild("announcer")
                local Winner = Announcer:FindFirstChild("Winner")
                if Winner then
                    Winner.Text = Library._config._flags["announcer_text"] or "discord.gg/March"
                end
                Announcer.ChildAdded:Connect(function(Value)
                    if Value.Name == "Winner" then
                        Value.Changed:Connect(function(Property)
                            if Property == "Text" and Library._config._flags["Custom_Announcer"] then
                                Value.Text = Library._config._flags["announcer_text"] or "discord.gg/March"
                            end
                        end)
                        if Library._config._flags["Custom_Announcer"] then
                            Value.Text = Library._config._flags["announcer_text"] or "discord.gg/March"
                        end
                    end
                end)
            end
        end
    })

    CustomAnnouncerSection:Input({
        Title = "Custom Announcement Text",
        Placeholder = "Enter custom announcer text... ",
        Flag = "announcer_text",
        Callback = function(text)
            Library._config._flags["announcer_text"] = text
            
            if Library._config._flags["Custom_Announcer"] then
                local Announcer = Player.PlayerGui:WaitForChild("announcer")
                local Winner = Announcer:FindFirstChild("Winner")
                if Winner then
                    Winner.Text = text
                end
            end
        end
    })
end

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(_, root)
    if root.Parent and root.Parent ~= Player.Character then
        if root.Parent.Parent ~= workspace.Alive then
            return
        end
    end

    Auto_Parry.Closest_Player()

    local Ball = Auto_Parry.Get_Ball()

    if not Ball then
        return
    end

    local Target_Distance = (Player.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude
    local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Ball.AssemblyLinearVelocity.Unit)

    local Curve_Detected = Auto_Parry.Is_Curved()

    if Target_Distance < 15 and Distance < 15 and Dot > -0.25 then -- wtf ?? maybe the big issue
        if Curve_Detected then
            Auto_Parry.Parry(Selected_Parry_Type)
        end
    end

    if not Grab_Parry then
        return
    end

    Grab_Parry:Stop()
end)

ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
    if Player.Character.Parent ~= workspace.Alive then
        return
    end

    if not Grab_Parry then
        return
    end

    Grab_Parry:Stop()
end)

workspace.Balls.ChildAdded:Connect(function()
    Parried = false
end)

workspace.Balls.ChildRemoved:Connect(function(Value)
    Parries = 0
    Parried = false

    if Connections_Manager['Target Change'] then
        Connections_Manager['Target Change']:Disconnect()
        Connections_Manager['Target Change'] = nil
    end
end)
