repeat task.wait() until game:IsLoaded()

local Players = game:GetService('Players')
local Player = Players.LocalPlayer

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local VirtualInputManager = game:GetService("VirtualInputManager")

local Aerodynamic = false
local Aerodynamic_Time = tick()

local UserInputService = game:GetService('UserInputService')
local Last_Input = UserInputService:GetLastInputType()

local Debris = game:GetService('Debris')
local RunService = game:GetService('RunService')

local Alive = workspace.Alive

getgenv().Trail_Ball_Enabled = false
getgenv().self_effect_Enabled = false

local Vector2_Mouse_Location = nil
local Grab_Parry = nil

local Remotes = {}
local Parry_Key = nil

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

function create_animation(object, info, value)
    local animation = game:GetService('TweenService'):Create(object, info, value)

    animation:Play()
    task.wait(info.Time)

    Debris:AddItem(animation, 0)

    animation:Destroy()
    animation = nil
end

local Animation = {}
Animation.storage = {}

Animation.current = nil
Animation.track = nil

for _, v in pairs(game:GetService("ReplicatedStorage").Misc.Emotes:GetChildren()) do
    if v:IsA("Animation") and v:GetAttribute("EmoteName") then
        local Emote_Name = v:GetAttribute("EmoteName")
        Animation.storage[Emote_Name] = v
    end
end

local Emotes_Data = {}

for Object in pairs(Animation.storage) do
    table.insert(Emotes_Data, Object)
end

table.sort(Emotes_Data)

local RbxAnalyticsService = game:GetService('RbxAnalyticsService')

local client_id = RbxAnalyticsService:GetClientId()

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

function Auto_Parry.Parry_Data()
    local Camera = workspace.CurrentCamera
    if not Camera then return {0, CFrame.new(), {}, {0, 0}} end

    if Last_Input == Enum.UserInputType.MouseButton1 or Last_Input == Enum.UserInputType.MouseButton2 or Last_Input == Enum.UserInputType.Keyboard then
        Vector2_Mouse_Location = {UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y}
    else
        Vector2_Mouse_Location = {Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2}
    end

    local directionMap = {
        ['Backwards'] = function()
            return CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position - (Camera.CFrame.LookVector * 1000))
        end,
        ['Random'] = function()
            return CFrame.new(Camera.CFrame.Position, Vector3.new(math.random(-3000,3000), math.random(-3000,3000), math.random(-3000,3000)))
        end,
        ['Custom'] = function()
            return CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + (Camera.CFrame.LookVector * 1000))
        end,
        ['Default'] = function()
            return Camera.CFrame
        end
    }

    return {0, directionMap[Auto_Parry.Parry_Type] and directionMap[Auto_Parry.Parry_Type]() or Camera.CFrame, {}, Vector2_Mouse_Location}
end

local FirstParryDone = false
Auto_Parry.Parry = function()
    local Parry_Data = Auto_Parry.Parry_Data()
    
    if not FirstParryDone then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0.001)
        task.wait(0.1)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0.001)
        FirstParryDone = true
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

    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Ball_Direction)

    local Speed = Velocity.Magnitude

    local Speed_Threshold = math.min(Speed / 100, 40)
    local Angle_Threshold = 40 * math.max(Dot, 0)

    local Direction_Difference = (Ball_Direction - Velocity).Unit
    local Direction_Similarity = Direction:Dot(Direction_Difference)

    local Dot_Difference = Dot - Direction_Similarity
    local Dot_Threshold = 0.5 - Ping / 1000

    local Distance = (Player.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Reach_Time = Distance / Speed - (Ping / 1000)

    local Enough_Speed = Speed > 100
    local Ball_Distance_Threshold = 15 - math.min(Distance / 1000, 15) + Angle_Threshold + Speed_Threshold

    table.insert(Previous_Velocity, Velocity)

    if #Previous_Velocity > 4 then
        table.remove(Previous_Velocity, 1)
    end

    if Enough_Speed and Reach_Time > Ping / 10 then
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15)
    end

    if Distance < Ball_Distance_Threshold then
        return false
    end

    if (tick() - Curving) < Reach_Time / 1.5 then --warn('Curving')
        return true
    end

    if Dot_Difference < Dot_Threshold then
        return true
    end

    local Radians = math.rad(math.asin(Dot))

    Lerp_Radians = Auto_Parry.Linear_Interpolation(Lerp_Radians, Radians, 0.8)

    if Lerp_Radians < 0.018 then
        Last_Warping = tick()
    end

    if (tick() - Last_Warping) < (Reach_Time / 1.5) then
        return true
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

    if (tick() - Last_Warping) < (Reach_Time / 1.5) then
        return true
    end

    return Dot < Dot_Threshold
end

local Closest_Entity = nil

function Auto_Parry.Closest_Player()
    local Max_Distance = math.huge

    for _, Entity in pairs(workspace.Alive:GetChildren()) do
        if tostring(Entity) ~= tostring(Player) then
            local Distance = Player:DistanceFromCharacter(Entity.PrimaryPart.Position)

            if Distance < Max_Distance then
                Max_Distance = Distance
                Closest_Entity = Entity
            end
        end
    end
    return Closest_Entity
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

function Auto_Parry:Spam_Service()
    local Ball = Auto_Parry.Get_Ball()

    if not Ball then
        return false
    end

    Auto_Parry.Closest_Player()

    local Spam_Accuracy = 0

    local Velocity = Ball.AssemblyLinearVelocity
    local Speed = Velocity.Magnitude

    local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Velocity.Unit)

    local Target_Position = Closest_Entity.PrimaryPart.Position
    local Target_Distance = Player:DistanceFromCharacter(Target_Position)

    local Maximum_Spam_Distance = self.Ping + math.min(Speed / 6.5, 95)

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

getgenv().Trail_Enabled = true -- Toggle on/off

-- Black color sequence
local blackSequence = ColorSequence.new(Color3.new(0, 0, 0))

-- Trail creator
local function addTrail(ball)
	if ball and ball:IsA("BasePart") and not ball:FindFirstChild("Trail") then
		local att0 = Instance.new("Attachment")
		att0.Position = Vector3.new(0, 0.5, 0)
		att0.Parent = ball

		local att1 = Instance.new("Attachment")
		att1.Position = Vector3.new(0, -0.5, 0)
		att1.Parent = ball

		local trail = Instance.new("Trail")
		trail.Attachment0 = att0
		trail.Attachment1 = att1
		trail.Color = blackSequence
		trail.Lifetime = 0.2
		trail.Transparency = NumberSequence.new(0.2, 1)
		trail.MinLength = 0.1
		trail.Parent = ball
	end
end

-- Main toggleable loop
task.defer(function()
	RunService.RenderStepped:Connect(function()
		if getgenv().Trail_Ball_Enabled then
			local ball = Auto_Parry.Get_Ball()
			addTrail(ball)
		end
	end)
end)

task.defer(function()
	game:GetService("RunService").Heartbeat:Connect(function()

		if not Player.Character then
			return
		end

		if getgenv().self_effect_Enabled then
			local effect = game:GetObjects("rbxassetid://17519530107")[1]

			effect.Name = 'nurysium_efx'

			if Player.Character.PrimaryPart:FindFirstChild('nurysium_efx') then
				return
			end

			effect.Parent = Player.Character.PrimaryPart
		else

			if Player.Character.PrimaryPart:FindFirstChild('nurysium_efx') then
				Player.Character.PrimaryPart['nurysium_efx']:Destroy()
			end
		end

	end)
end)

local Library = loadstring(game:HttpGet("https://pastebin.com/raw/ziuAUZNm"))()
local main = Library.new()

local rage = main:create_tab('Blatant', 'rbxassetid://76499042599127')
local Visual = main:create_tab('Visuals', 'rbxassetid://85168909131990')

    local module = rage:create_module({
        title = 'Auto Parry',
        flag = 'Auto_Parry',
        description = 'Automatic Parry Ball',
        section = 'left',
        callback = function(state: boolean)
                if state then
            Connections_Manager['Auto Parry'] = RunService.PreSimulation:Connect(function()

                local One_Ball = Auto_Parry.Get_Ball()
                local Balls = Auto_Parry.Get_Balls()

                for _, Ball in pairs(Balls) do

                if not Ball then repeat task.wait() Balls = Auto_Parry.Get_Balls() until Balls
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
                local Speed = Velocity.Magnitude

                local Ping = game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue() / 10

                local Parry_Accuracy = (Speed / 3.25) + Ping
                local Curved = Auto_Parry.Is_Curved()

                if Ball_Target == tostring(Player) and Aerodynamic then
                    local Elasped_Tornado = tick() - Aerodynamic_Time

                    if Elasped_Tornado > 0.6 then
                        Aerodynamic_Time = tick()
                        Aerodynamic = false
                    end

                    return
                end

                if One_Target == tostring(Player) and Curved then
                    return
                end

                if Ball_Target == tostring(Player) and Distance <= Parry_Accuracy then
                    Auto_Parry.Parry(Selected_Parry_Type)
                    Parried = true
                end

                local Last_Parrys = tick()

                repeat RunService.PreSimulation:Wait() until (tick() - Last_Parrys) >= 1 or not Parried
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
    
    local dropdown = module:create_dropdown({
        title = 'Auto Curve Direction',
        flag = 'Parry_Type',

        options = {
            'Camera',
            'Backwards',
            'Random'
        },

        multi_dropdown = false,
        maximum_options = 3,

        callback = function(Selected)
            Auto_Parry.Parry_Type = Selected
        end
    })
    
        module:create_slider({
        title = 'Parry Accuracy',
        flag = 'Parry_Accuracy',

        maximum_value = 100,
        minimum_value = 1,
        value = 100,

        round_number = true,

        callback = function(v)
		local Adjusted_Value = v / 5.5

        getgenv().Parry_Accuracy = Adjusted_Value
        end
    })

    module:create_divider({
    })
    
        local SpamParry = rage:create_module({
        title = 'Auto Spam Parry',
        flag = 'Auto_Spam_Parry',
        description = 'Automatically spam parries ball',
        section = 'right',
        callback = function(state: boolean)
        if state then
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
                local Ping_Threshold = math.clamp(Ping / 10, 10, 16)

                local Ball_Properties = Auto_Parry:Get_Ball_Properties()
                local Entity_Properties = Auto_Parry:Get_Entity_Properties()

                local Spam_Accuracy = Auto_Parry.Spam_Service({
                    Ball_Properties = Ball_Properties,
                    Entity_Properties = Entity_Properties,
                    Ping = Ping_Threshold
                })

                local Distance = Player:DistanceFromCharacter(Ball.Position)

                local Target_Position = Closest_Entity.PrimaryPart.Position
                local Target_Distance = Player:DistanceFromCharacter(Target_Position)

                local Direction = (Player.Character.PrimaryPart.Position - Ball.Position).Unit
                local Ball_Direction = Zoomies.VectorVelocity.Unit

                local Dot = Direction:Dot(Ball_Direction)
                local Ball_Target = Alive:FindFirstChild(Ball:GetAttribute('target'))

                if not Ball_Target then
                    return
                end

                if Target_Distance > Spam_Accuracy or Distance > Spam_Accuracy then
                    return
                end

                local Ball_Targeted_Distance = Player:DistanceFromCharacter(Ball_Target.PrimaryPart.Position)

                if Distance <= Spam_Accuracy and Parries > 1 then
                    Auto_Parry.Parry(Selected_Parry_Type)
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
    
      local Skybox = Visual:create_module({
        title = 'Skybox',
        flag = 'Skybox',
        description = 'Changing Skybox',
        section = 'left',
        callback = function(state: boolean)
     local Lighting = game.Lighting
local Sky = Lighting:FindFirstChildOfClass("Sky")

if state then
    if not Sky then
        Sky = Instance.new("Sky", Lighting)
    end

    local customSkyboxId = "14961495673"
    local skyFaces = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}

    for _, face in ipairs(skyFaces) do
        Sky[face] = "rbxassetid://" .. customSkyboxId
    end
else
    if Sky then
        local defaultSkyboxIds = {
            "591058823", "591059876", "591058104",
            "591057861", "591057625", "591059642"
        }
        local skyFaces = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}

        for index, face in ipairs(skyFaces) do
            Sky[face] = "rbxassetid://" .. defaultSkyboxIds[index]
        end

        Lighting.GlobalShadows = true
    end
end
        end
    })
    
    local BallTrail = Visual:create_module({
        title = 'Ball Trail',
        flag = 'Balls',
        description = 'Make The Ball Have Black Trail',
        section = 'left',
        callback = function(state: boolean)
     getgenv().Trail_Ball_Enabled = state
        end
    })
    
    local aura = Visual:create_module({
        title = 'Aura Effect',
        flag = 'aura',
        description = 'Make The Ball Have Black Trail',
        section = 'left',
        callback = function(state: boolean)
     getgenv().self_effect_Enabled = state
        end
    })
    
    local BallTrail = Visual:create_module({
        title = 'No Render',
        flag = 'Balls',
        description = 'No Parry Sound/Effect To Avoid Lag',
        section = 'right',
        callback = function(state: boolean)
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
    
    main:load() 
    
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

Runtime.ChildAdded:Connect(function(Value)
    if Value.Name == 'Tornado' then
        Aerodynamic_Time = tick()
        Aerodynamic = true
    end
end)

workspace.Balls.ChildAdded:Connect(function()
    Parried = false
end)

workspace.Balls.ChildRemoved:Connect(function()
    Parries = 0
    Parried = false

    if Connections_Manager['Target Change'] then
        Connections_Manager['Target Change']:Disconnect()
        Connections_Manager['Target Change'] = nil
    end
end)
