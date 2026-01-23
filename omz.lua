-- Chargement WindUI (version officielle/dist)
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "OMZ Hub",
    Folder = "OMZ_Config",
    Icon = "solar:shield-bold-duotone",
    OpenButton = {
        Title = "OMZ",
        CornerRadius = UDim.new(1, 0),
        Enabled = true,
        Draggable = true,
        Scale = 0.58,
        Color = ColorSequence.new(
            Color3.fromHex("#00ffea"),
            Color3.fromHex("#ff00aa")
        )
    },
    Topbar = { Height = 44, ButtonsType = "Mac" }
})

Window:Tag({ Title = "v1.0 • OMZ", Icon = "github", Color = Color3.fromHex("#1c1c1c"), Border = true })

repeat task.wait() until game:IsLoaded()

local Players = cloneref(game:GetService('Players'))
local ReplicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local UserInputService = cloneref(game:GetService('UserInputService'))
local RunService = cloneref(game:GetService('RunService'))
local TweenService = cloneref(game:GetService('TweenService'))
local Stats = cloneref(game:GetService('Stats'))
local Debris = cloneref(game:GetService('Debris'))
local CoreGui = cloneref(game:GetService('CoreGui'))

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

if not LocalPlayer.Character then
    LocalPlayer.CharacterAdded:Wait()
end

local Alive = workspace:FindFirstChild("Alive") or workspace:WaitForChild("Alive")
local Runtime = workspace.Runtime

local System = {
    __properties = {
        __autoparry_enabled = false,
        __triggerbot_enabled = false,
        __manual_spam_enabled = false,
        __auto_spam_enabled = false,
        __play_animation = false,
        __curve_mode = 1,
        __accuracy = 1,
        __divisor_multiplier = 1.1,
        __parried = false,
        __training_parried = false,
        __spam_threshold = 1.5,
        __parries = 0,
        __parry_key = nil,
        __grab_animation = nil,
        __tornado_time = tick(),
        __first_parry_done = false,
        __connections = {},
        __reverted_remotes = {},
        __spam_accumulator = 0,
        __spam_rate = 240,
        __infinity_active = false,
        __deathslash_active = false,
        __timehole_active = false,
        __slashesoffury_active = false,
        __slashesoffury_count = 0,
        __is_mobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled,
        __mobile_guis = {}
    },
    
    __config = {
        __curve_names = {'Camera', 'Random', 'Accelerated', 'Backwards', 'Slow', 'High'},
        __detections = {
            __infinity = false,
            __deathslash = false,
            __timehole = false,
            __slashesoffury = false,
            __phantom = false
        }
    },
    
    __triggerbot = {
        __enabled = false,
        __is_parrying = false,
        __parries = 0,
        __max_parries = 10000,
        __parry_delay = 0.5
    }
}
local firstParryFired = false
local revertedRemotes = {}
local originalMetatables = {}
local Parry_Key = nil
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

local function update_divisor()
    System.__properties.__divisor_multiplier = 0.75 + (System.__properties.__accuracy - 1) * (3 / 99)
end

function isValidRemoteArgs(args)
    return #args == 7 and
        type(args[2]) == "string" and
        type(args[3]) == "number" and
        typeof(args[4]) == "CFrame" and
        type(args[5]) == "table" and
        type(args[6]) == "table" and
        type(args[7]) == "boolean"
end

function hookRemote(remote)
    if not revertedRemotes[remote] then
        if not originalMetatables[getrawmetatable(remote)] then
            originalMetatables[getrawmetatable(remote)] = true
            local meta = getrawmetatable(remote)
            setreadonly(meta, false)

            local oldIndex = meta.__index
            meta.__index = function(self, key)
                if (key == "FireServer" and self:IsA("RemoteEvent")) or
                   (key == "InvokeServer" and self:IsA("RemoteFunction")) then
                    return function(_, ...)
                        local args = {...}
                        if isValidRemoteArgs(args) and not revertedRemotes[self] then
                            revertedRemotes[self] = args
                            Parry_Key = args[2]
                        end
                        return oldIndex(self, key)(_, unpack(args))
                    end
                end
                return oldIndex(self, key)
            end
            setreadonly(meta, true)
        end
    end
end

for _, remote in pairs(ReplicatedStorage:GetChildren()) do
    if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
        hookRemote(remote)
    end
end

ReplicatedStorage.ChildAdded:Connect(function(child)
    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
        hookRemote(child)
    end
end)

System.animation = {}

function System.animation.play_grab_parry()
    if not System.__properties.__play_animation then
        return
    end
    
    local character = LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass('Humanoid')
    local animator = humanoid and humanoid:FindFirstChildOfClass('Animator')
    if not humanoid or not animator then return end
    
    local sword_name
    if getgenv().skinChangerEnabled then
        sword_name = getgenv().swordAnimations
    else
        sword_name = character:GetAttribute('CurrentlyEquippedSword')
    end
    if not sword_name then return end
    
    local sword_api = ReplicatedStorage.Shared.SwordAPI.Collection
    local parry_animation = sword_api.Default:FindFirstChild('GrabParry')
    if not parry_animation then return end
    
    local sword_data = ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(sword_name)
    if not sword_data or not sword_data['AnimationType'] then return end
    
    for _, object in pairs(sword_api:GetChildren()) do
        if object.Name == sword_data['AnimationType'] then
            if object:FindFirstChild('GrabParry') or object:FindFirstChild('Grab') then
                local animation_type = object:FindFirstChild('GrabParry') and 'GrabParry' or 'Grab'
                parry_animation = object[animation_type]
            end
        end
    end
    
    if System.__properties.__grab_animation and System.__properties.__grab_animation.IsPlaying then
        System.__properties.__grab_animation:Stop()
    end
    
    System.__properties.__grab_animation = animator:LoadAnimation(parry_animation)
    System.__properties.__grab_animation.Priority = Enum.AnimationPriority.Action4
    System.__properties.__grab_animation:Play()
end

System.ball = {}

function System.ball.get()
    local balls = workspace:FindFirstChild('Balls')
    if not balls then return nil end
    
    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute('realBall') then
            ball.CanCollide = false
            return ball
        end
    end
    return nil
end

function System.ball.get_all()
    local balls_table = {}
    local balls = workspace:FindFirstChild('Balls')
    if not balls then return balls_table end
    
    for _, ball in pairs(balls:GetChildren()) do
        if ball:GetAttribute('realBall') then
            ball.CanCollide = false
            table.insert(balls_table, ball)
        end
    end
    return balls_table
end

System.player = {}

local Closest_Entity = nil

function System.player.get_closest()
    local max_distance = math.huge
    local closest_entity = nil
    
    if not Alive then return nil end
    
    for _, entity in pairs(Alive:GetChildren()) do
        if entity ~= LocalPlayer.Character then
            if entity.PrimaryPart then
                local distance = LocalPlayer:DistanceFromCharacter(entity.PrimaryPart.Position)
                if distance < max_distance then
                    max_distance = distance
                    closest_entity = entity
                end
            end
        end
    end
    
    Closest_Entity = closest_entity
    return closest_entity
end

function System.player.get_closest_to_cursor()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
        return nil
    end
    
    local closest_player = nil
    local minimal_dot = -math.huge
    local camera = workspace.CurrentCamera
    
    if not Alive then return nil end
    
    local success, mouse_location = pcall(function()
        return UserInputService:GetMouseLocation()
    end)
    
    if not success then return nil end
    
    local ray = camera:ScreenPointToRay(mouse_location.X, mouse_location.Y)
    local pointer = CFrame.lookAt(ray.Origin, ray.Origin + ray.Direction)
    
    for _, player in pairs(Alive:GetChildren()) do
        if player == LocalPlayer.Character then continue end
        if not player:FindFirstChild('HumanoidRootPart') then continue end
        
        local direction = (player.HumanoidRootPart.Position - camera.CFrame.Position).Unit
        local dot = pointer.LookVector:Dot(direction)
        
        if dot > minimal_dot then
            minimal_dot = dot
            closest_player = player
        end
    end
    
    return closest_player
end

System.curve = {}

function System.curve.get_cframe()
    local camera = workspace.CurrentCamera
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
    if not root then return camera.CFrame end
    
    local targetPart
    local closest = System.player.get_closest_to_cursor()
    if closest and closest:FindFirstChild('HumanoidRootPart') then
        targetPart = closest.HumanoidRootPart
    end
    
    local target_pos = targetPart and targetPart.Position or (root.Position + camera.CFrame.LookVector * 100)
    
    local curve_functions = {
        function() return camera.CFrame end,
        
        function()
            local direction = (target_pos - root.Position).Unit
            local random_offset
            local attempts = 0
            repeat
                random_offset = Vector3.new(
                    math.random(-4000, 4000),
                    math.random(-4000, 4000),
                    math.random(-4000, 4000)
                )
                local curve_direction = (target_pos + random_offset - root.Position).Unit
                local dot = direction:Dot(curve_direction)
                attempts = attempts + 1
            until dot < 0.95 or attempts > 10
            return CFrame.new(root.Position, target_pos + random_offset)
        end,
        
        function()
            return CFrame.new(root.Position, target_pos + Vector3.new(0, 5, 0))
        end,
        
        function()
            local direction = (root.Position - target_pos).Unit
            local backwards_pos = root.Position + direction * 10000 + Vector3.new(0, 1000, 0)
            return CFrame.new(camera.CFrame.Position, backwards_pos)
        end,
        
        function()
            return CFrame.new(root.Position, target_pos + Vector3.new(0, -9e18, 0))
        end,
        
        function()
            return CFrame.new(root.Position, target_pos + Vector3.new(0, 9e18, 0))
        end
    }
    
    return curve_functions[System.__properties.__curve_mode]()
end

System.parry = {}

function System.parry.execute()
    if System.__properties.__parries > 10000 or not LocalPlayer.Character then
        return
    end
    
    local camera = workspace.CurrentCamera
    local success, mouse = pcall(function()
        return UserInputService:GetMouseLocation()
    end)
    
    if not success then return end
    
    local vec2_mouse = {mouse.X, mouse.Y}
    local is_mobile = System.__properties.__is_mobile
    
    local event_data = {}
    if Alive then
        for _, entity in pairs(Alive:GetChildren()) do
            if entity.PrimaryPart then
                local success2, screen_point = pcall(function()
                    return camera:WorldToScreenPoint(entity.PrimaryPart.Position)
                end)
                if success2 then
                    event_data[entity.Name] = screen_point
                end
            end
        end
    end
    
    local curve_cframe = System.curve.get_cframe()
    
    if not System.__properties.__first_parry_done then
        for _, connection in pairs(getconnections(LocalPlayer.PlayerGui.Hotbar.Block.Activated)) do
            connection:Fire()
        end
        System.__properties.__first_parry_done = true
        return
    end

    local final_aim_target
    if is_mobile then
        local viewport = camera.ViewportSize
        final_aim_target = {viewport.X / 2, viewport.Y / 2}
    else
        final_aim_target = vec2_mouse
    end

    if not firstParryFired then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0.001)
        task.wait(0.1)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0.001)
        firstParryFired = true
    else
        for remote, original_args in pairs(revertedRemotes) do
            local modified_args = {
                original_args[1],
                original_args[2],
                original_args[3],
                curve_cframe,
                event_data,
                final_aim_target,
                original_args[7]
            }
        
            pcall(function()
                if remote:IsA('RemoteEvent') then
                    remote:FireServer(unpack(modified_args))
                elseif remote:IsA('RemoteFunction') then
                    remote:InvokeServer(unpack(modified_args))
                end
            end)
        end
    end
    
    if System.__properties.__parries > 10000 then return end
    
    System.__properties.__parries = System.__properties.__parries + 1
    task.delay(0.5, function()
        if System.__properties.__parries > 0 then
            System.__properties.__parries = System.__properties.__parries - 1
        end
    end)
end

function System.parry.keypress()
    if System.__properties.__parries > 10000 or not LocalPlayer.Character then
        return
    end

    PF()

    if System.__properties.__parries > 10000 then return end
    
    System.__properties.__parries = System.__properties.__parries + 1
    task.delay(0.5, function()
        if System.__properties.__parries > 0 then
            System.__properties.__parries = System.__properties.__parries - 1
        end
    end)
end

-- // aqqqqq

function System.parry.execute_action()
    System.animation.play_grab_parry()
    System.parry.execute()
end

local function linear_predict(a, b, time_volume)
    return a + (b - a) * time_volume
end

System.detection = {
    __ball_properties = {
        __aerodynamic_time = tick(),
        __last_warping = tick(),
        __lerp_radians = 0,
        __curving = tick()
    }
}

function System.detection.is_curved()
    local ball_properties = System.detection.__ball_properties
    local ball = System.ball.get()
    
    if not ball then return false end
    
    local zoomies = ball:FindFirstChild('zoomies')
    if not zoomies then return false end
    
    local velocity = zoomies.VectorVelocity
    local ball_direction = velocity.Unit
    
    local direction = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
    local dot = direction:Dot(ball_direction)
    
    local speed = velocity.Magnitude
    local speed_threshold = math.min(speed / 100, 40)
    
    local direction_difference = (ball_direction - velocity).Unit
    local direction_similarity = direction:Dot(direction_difference)
    
    local dot_difference = dot - direction_similarity
    local distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
    
    local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue()
    
    local dot_threshold = 0.5 - (ping / 1000)
    local reach_time = distance / speed - (ping / 1000)
    
    local ball_distance_threshold = 15 - math.min(distance / 1000, 15) + speed_threshold
    
    local clamped_dot = math.clamp(dot, -1, 1)
    local radians = math.rad(math.asin(clamped_dot))
    
    ball_properties.__lerp_radians = linear_predict(ball_properties.__lerp_radians, radians, 0.8)
    
    if speed > 0 and reach_time > ping / 10 then
        ball_distance_threshold = math.max(ball_distance_threshold - 15, 15)
    end
    
    if distance < ball_distance_threshold then return false end
    if dot_difference < dot_threshold then return true end
    
    if ball_properties.__lerp_radians < 0.018 then
        ball_properties.__last_warping = tick()
    end
    
    if (tick() - ball_properties.__last_warping) < (reach_time / 1.5) then
        return true
    end
    
    if (tick() - ball_properties.__curving) < (reach_time / 1.5) then
        return true
    end
    
    return dot < dot_threshold
end

Runtime.ChildAdded:Connect(function(Object)
    if System.__config.__detections.__phantom then
        if Object.Name == "maxTransmission" or Object.Name == "transmissionpart" then
            local Weld = Object:FindFirstChildWhichIsA("WeldConstraint")
            if Weld then
                local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
                if Character and Weld.Part1 == Character.HumanoidRootPart then
                    local CurrentBall = System.ball.get()
                    Weld:Destroy()
                    
                    if CurrentBall then
                        local FocusConnection
                        FocusConnection = RunService.RenderStepped:Connect(function()
                            local Highlighted = CurrentBall:GetAttribute("highlighted")
                            
                            if Highlighted == true then
                                ReplicatedStorage.Remotes.AbilityButtonPress:Fire()
                                System.__properties.__parried = true
                                
                                task.delay(1, function()
                                    System.__properties.__parried = false
                                end)
                                
                            elseif Highlighted == false then
                                FocusConnection:Disconnect()
                            end
                        end)
                        
                        task.delay(3, function()
                            if FocusConnection and FocusConnection.Connected then
                                FocusConnection:Disconnect()
                            end
                        end)
                    end
                end
            end
        end
    end
end)

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(_, root)
    if root.Parent and root.Parent ~= LocalPlayer.Character then
        if not Alive or root.Parent.Parent ~= Alive then
            return
        end
    end
    
    local closest = System.player.get_closest()
    local ball = System.ball.get()
    
    if not ball or not closest then return end
    
    local target_distance = (LocalPlayer.Character.PrimaryPart.Position - closest.PrimaryPart.Position).Magnitude
    local distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
    local direction = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
    local dot = direction:Dot(ball.AssemblyLinearVelocity.Unit)
    
    local curve_detected = System.detection.is_curved()
    
    if target_distance < 15 and distance < 15 and dot > -0.25 then
        if curve_detected then
            System.parry.execute_action()
        end
    end
    
    if System.__properties.__grab_animation then
        System.__properties.__grab_animation:Stop()
    end
end)

ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(function()
    if not Alive or LocalPlayer.Character.Parent ~= Alive then
        return
    end
    
    if System.__properties.__grab_animation then
        System.__properties.__grab_animation:Stop()
    end
end)

ReplicatedStorage.Remotes.ParrySuccessAll.OnClientEvent:Connect(function(a, b)
    local Primary_Part = LocalPlayer.Character.PrimaryPart
    local Ball = System.ball.get()

    if not Ball then
        return
    end

    local Zoomies = Ball:FindFirstChild('zoomies')

    if not Zoomies then
        return
    end

    local Speed = Zoomies.VectorVelocity.Magnitude

    local Distance = (LocalPlayer.Character.PrimaryPart.Position - Ball.Position).Magnitude
    local Velocity = Zoomies.VectorVelocity

    local Ball_Direction = Velocity.Unit

    local Direction = (LocalPlayer.Character.PrimaryPart.Position - Ball.Position).Unit
    local Dot = Direction:Dot(Ball_Direction)

    local Pings = Stats.Network.ServerStatsItem['Data Ping']:GetValue()

    local Speed_Threshold = math.min(Speed / 100, 40)
    local Reach_Time = Distance / Speed - (Pings / 1000)

    local Enough_Speed = Speed > 1
    local Ball_Distance_Threshold = 15 - math.min(Distance / 1000, 15) + Speed_Threshold

    if Enough_Speed and Reach_Time > Pings / 10 then
        Ball_Distance_Threshold = math.max(Ball_Distance_Threshold - 15, 15)
    end

    if b ~= Primary_Part and Distance > Ball_Distance_Threshold then
        System.detection.__ball_properties.__curving = tick()
    end
end)

System.triggerbot = {}

function System.triggerbot.trigger(ball)
    if System.__triggerbot.__is_parrying or System.__triggerbot.__parries > System.__triggerbot.__max_parries then
        return
    end
    
    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and 
       LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape') then
        return
    end
    
    System.__triggerbot.__is_parrying = true
    System.__triggerbot.__parries = System.__triggerbot.__parries + 1
    
    System.animation.play_grab_parry()
    System.parry.execute()
    
    task.delay(System.__triggerbot.__parry_delay, function()
        if System.__triggerbot.__parries > 0 then
            System.__triggerbot.__parries = System.__triggerbot.__parries - 1
        end
    end)
    
    local connection
    connection = ball:GetAttributeChangedSignal('target'):Once(function()
        System.__triggerbot.__is_parrying = false
        if connection then
            connection:Disconnect()
        end
    end)
    
    task.spawn(function()
        local start_time = tick()
        repeat
            RunService.Heartbeat:Wait()
        until (tick() - start_time >= 1 or not System.__triggerbot.__is_parrying)
        
        System.__triggerbot.__is_parrying = false
    end)
end

function System.triggerbot.loop()
    if not System.__triggerbot.__enabled then return end
    
    if LocalPlayer.Character and LocalPlayer.Character.PrimaryPart and 
       LocalPlayer.Character.PrimaryPart:FindFirstChild('SingularityCape') then
        return
    end
    
    local balls = workspace:FindFirstChild('Balls')
    if not balls then return end
    
    for _, ball in pairs(balls:GetChildren()) do
        if ball:IsA('BasePart') and ball:GetAttribute('target') == LocalPlayer.Name then
            System.triggerbot.trigger(ball)
            break
        end
    end
end

function System.triggerbot.enable(enabled)
    System.__triggerbot.__enabled = enabled
    
    if enabled then
        if not System.__properties.__connections.__triggerbot then
            System.__properties.__connections.__triggerbot = RunService.Heartbeat:Connect(System.triggerbot.loop)
        end
    else
        if System.__properties.__connections.__triggerbot then
            System.__properties.__connections.__triggerbot:Disconnect()
            System.__properties.__connections.__triggerbot = nil
        end
        System.__triggerbot.__is_parrying = false
        System.__triggerbot.__parries = 0
    end
end

System.manual_spam = {}

function System.manual_spam.loop(delta)
    if not System.__properties.__manual_spam_enabled then return end
    if not LocalPlayer.Character or LocalPlayer.Character.Parent ~= Alive then return end
    
    System.__properties.__spam_accumulator = System.__properties.__spam_accumulator + delta
    local interval = 1 / System.__properties.__spam_rate
    
    if System.__properties.__spam_accumulator >= interval then
        System.__properties.__spam_accumulator = 0
        
        if getgenv().ManualSpamMode == "Keypress" then
            if PF then PF() end
        else
            System.parry.execute()
            if getgenv().ManualSpamAnimationFix and PF then
                PF()
            end
        end
    end
end

function System.manual_spam.start()
    if System.__properties.__connections.__manual_spam then
        System.__properties.__connections.__manual_spam:Disconnect()
    end
    
    System.__properties.__manual_spam_enabled = true
    System.__properties.__connections.__manual_spam = RunService.Heartbeat:Connect(System.manual_spam.loop)
end

function System.manual_spam.stop()
    System.__properties.__manual_spam_enabled = false
    if System.__properties.__connections.__manual_spam then
        System.__properties.__connections.__manual_spam:Disconnect()
        System.__properties.__connections.__manual_spam = nil
    end
end

System.auto_spam = {}

function System.auto_spam:get_entity_properties()
    System.player.get_closest()
    
    if not Closest_Entity then return false end
    
    local entity_velocity = Closest_Entity.PrimaryPart.Velocity
    local entity_direction = (LocalPlayer.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Unit
    local entity_distance = (LocalPlayer.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude
    
    return {
        Velocity = entity_velocity,
        Direction = entity_direction,
        Distance = entity_distance
    }
end

function System.auto_spam:get_ball_properties()
    local ball = System.ball.get()
    if not ball then return false end
    
    local ball_velocity = Vector3.zero
    local ball_origin = ball
    
    local ball_direction = (LocalPlayer.Character.PrimaryPart.Position - ball_origin.Position).Unit
    local ball_distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
    local ball_dot = ball_direction:Dot(ball_velocity.Unit)
    
    return {
        Velocity = ball_velocity,
        Direction = ball_direction,
        Distance = ball_distance,
        Dot = ball_dot
    }
end

function System.auto_spam.spam_service(self)
    local ball = System.ball.get()
    local entity = System.player.get_closest()
    
    if not ball or not entity or not entity.PrimaryPart then
        return false
    end
    
    local spam_accuracy = 0
    
    local velocity = ball.AssemblyLinearVelocity
    local speed = velocity.Magnitude
    
    local direction = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
    local dot = direction:Dot(velocity.Unit)
    
    local target_position = entity.PrimaryPart.Position
    local target_distance = LocalPlayer:DistanceFromCharacter(target_position)
    
    local maximum_spam_distance = self.Ping + math.min(speed / 6, 255)
    
    if self.Entity_Properties.Distance > maximum_spam_distance then
        return spam_accuracy
    end
    
    if self.Ball_Properties.Distance > maximum_spam_distance then
        return spam_accuracy
    end
    
    if target_distance > maximum_spam_distance then
        return spam_accuracy
    end
    
    local maximum_speed = 5 - math.min(speed / 5, 5)
    local maximum_dot = math.clamp(dot, -1, 0) * maximum_speed
    
    spam_accuracy = maximum_spam_distance - maximum_dot
    
    return spam_accuracy
end

function System.auto_spam.start()
    if System.__properties.__connections.__auto_spam then
        System.__properties.__connections.__auto_spam:Disconnect()
    end
    
    System.__properties.__auto_spam_enabled = true
    System.__properties.__connections.__auto_spam = RunService.PreSimulation:Connect(function()
        local ball = System.ball.get()
        
        if not ball then return end
        
        if System.__properties.__slashesoffury_active then return end
        
        local zoomies = ball:FindFirstChild('zoomies')
        if not zoomies then return end
        
        System.player.get_closest()
        
        local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue()
        local ping_threshold = math.clamp(ping / 10, 1, 16)
        
        local ball_target = ball:GetAttribute('target')
        
        local ball_properties = System.auto_spam:get_ball_properties()
        local entity_properties = System.auto_spam:get_entity_properties()
        
        if not ball_properties or not entity_properties then return end
        
        local spam_accuracy = System.auto_spam.spam_service({
            Ball_Properties = ball_properties,
            Entity_Properties = entity_properties,
            Ping = ping_threshold
        })
        
        local target_position = Closest_Entity.PrimaryPart.Position
        local target_distance = LocalPlayer:DistanceFromCharacter(target_position)
        
        local direction = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit
        local ball_direction = zoomies.VectorVelocity.Unit
        
        local dot = direction:Dot(ball_direction)
        local distance = LocalPlayer:DistanceFromCharacter(ball.Position)
        
        if not ball_target then return end
        if target_distance > spam_accuracy or distance > spam_accuracy then return end
        
        local pulsed = LocalPlayer.Character:GetAttribute('Pulsed')
        if pulsed then return end
        
        if ball_target == LocalPlayer.Name and target_distance > 30 and distance > 30 then return end
        
                    if distance <= spam_accuracy and System.__properties.__parries > System.__properties.__spam_threshold then
            if getgenv().AutoSpamMode == "Keypress" then
                if PF then PF() end
            else
                System.parry.execute()
                if getgenv().AutoSpamAnimationFix and PF then
                    PF()
                end
            end
        end
    end)
end

function System.auto_spam.stop()
    System.__properties.__auto_spam_enabled = false
    if System.__properties.__connections.__auto_spam then
        System.__properties.__connections.__auto_spam:Disconnect()
        System.__properties.__connections.__auto_spam = nil
    end
end

System.autoparry = {}

function System.autoparry.start()
    if System.__properties.__connections.__autoparry then
        System.__properties.__connections.__autoparry:Disconnect()
    end
    
    System.__properties.__connections.__autoparry = RunService.PreSimulation:Connect(function()
        if not System.__properties.__autoparry_enabled or not LocalPlayer.Character or 
           not LocalPlayer.Character.PrimaryPart then
            return
        end
        
        local balls = System.ball.get_all()
        local one_ball = System.ball.get()
        
        local training_ball = nil
        if workspace:FindFirstChild("TrainingBalls") then
            for _, Instance in pairs(workspace.TrainingBalls:GetChildren()) do
                if Instance:GetAttribute("realBall") then
                    training_ball = Instance
                    break
                end
            end
        end

        for _, ball in pairs(balls) do
            if System.__triggerbot.__enabled then return end
            if getgenv().BallVelocityAbove800 then return end
            if not ball then continue end
            
            local zoomies = ball:FindFirstChild('zoomies')
            if not zoomies then continue end
            
            ball:GetAttributeChangedSignal('target'):Once(function()
                System.__properties.__parried = false
            end)
            
            if System.__properties.__parried then continue end
            
            local ball_target = ball:GetAttribute('target')
            local velocity = zoomies.VectorVelocity
            local distance = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
            
            local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 10
            local ping_threshold = math.clamp(ping / 10, 5, 17)
            local speed = velocity.Magnitude
            
            local capped_speed_diff = math.min(math.max(speed - 9.5, 0), 650)
            local speed_divisor = (2.4 + capped_speed_diff * 0.002) * System.__properties.__divisor_multiplier
            local parry_accuracy = ping_threshold + math.max(speed / speed_divisor, 9.5)
            
            local curved = System.detection.is_curved()
            
            if one_ball and one_ball:GetAttribute('target') == LocalPlayer.Name and curved then
                continue
            end
            
            if ball_target == LocalPlayer.Name and distance <= parry_accuracy then
                if getgenv().AutoParryMode == "Keypress" then
                    System.parry.keypress()
                else
                    System.parry.execute_action()
                end
                System.__properties.__parried = true
            end
            
            local last_parrys = tick()
            repeat
                RunService.Stepped:Wait()
            until (tick() - last_parrys) >= 1 or not System.__properties.__parried
            System.__properties.__parried = false
        end

        if training_ball then
            local zoomies = training_ball:FindFirstChild('zoomies')
            if zoomies then
                training_ball:GetAttributeChangedSignal('target'):Once(function()
                    System.__properties.__training_parried = false
                end)
                
                if not System.__properties.__training_parried then
                    local ball_target = training_ball:GetAttribute('target')
                    local velocity = zoomies.VectorVelocity
                    local distance = LocalPlayer:DistanceFromCharacter(training_ball.Position)
                    local speed = velocity.Magnitude
                    
                    local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 10
                    local ping_threshold = math.clamp(ping / 10, 5, 17)
                    
                    local capped_speed_diff = math.min(math.max(speed - 9.5, 0), 650)
                    local speed_divisor = (2.4 + capped_speed_diff * 0.002) * System.__properties.__divisor_multiplier
                    local parry_accuracy = ping_threshold + math.max(speed / speed_divisor, 9.5)
                    
                    if ball_target == LocalPlayer.Name and distance <= parry_accuracy then
                        if getgenv().AutoParryMode == "Keypress" then
                            System.parry.keypress()
                        else
                            System.parry.execute_action()
                        end
                        System.__properties.__training_parried = true
                        
                        local last_parrys = tick()
                        repeat
                            RunService.Stepped:Wait()
                        until (tick() - last_parrys) >= 1 or not System.__properties.__training_parried
                        System.__properties.__training_parried = false
                    end
                end
            end
        end
    end)
end

function System.autoparry.stop()
    if System.__properties.__connections.__autoparry then
        System.__properties.__connections.__autoparry:Disconnect()
        System.__properties.__connections.__autoparry = nil
    end
end

local function create_mobile_button(name, position_y, color)
    local gui = Instance.new('ScreenGui')
    gui.Name = 'Sigma' .. name .. 'Mobile'
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local button = Instance.new('TextButton')
    button.Size = UDim2.new(0, 140, 0, 50)
    button.Position = UDim2.new(0.5, -70, position_y, 0)
    button.BackgroundTransparency = 1
    button.AnchorPoint = Vector2.new(0.5, 0)
    button.Draggable = true
    button.AutoButtonColor = false
    button.ZIndex = 2
    
    local bg = Instance.new('Frame')
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bg.Parent = button
    
    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = bg
    
    local stroke = Instance.new('UIStroke')
    stroke.Color = color
    stroke.Thickness = 1
    stroke.Transparency = 0.3
    stroke.Parent = bg
    
    local text = Instance.new('TextLabel')
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = name
    text.Font = Enum.Font.GothamBold
    text.TextSize = 16
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.ZIndex = 3
    text.Parent = button
    
    button.Parent = gui
    gui.Parent = CoreGui
    
    return {gui = gui, button = button, text = text, bg = bg}
end

local function create_mobile_button(name, position_y, color)
    local gui = Instance.new('ScreenGui')
    gui.Name = 'Sigma' .. name .. 'Mobile'
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local button = Instance.new('TextButton')
    button.Size = UDim2.new(0, 140, 0, 50)
    button.Position = UDim2.new(0.5, -70, position_y, 0)
    button.BackgroundTransparency = 1
    button.AnchorPoint = Vector2.new(0.5, 0)
    button.Draggable = true
    button.AutoButtonColor = false
    button.ZIndex = 2
    
    local bg = Instance.new('Frame')
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bg.Parent = button
    
    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = bg
    
    local stroke = Instance.new('UIStroke')
    stroke.Color = color
    stroke.Thickness = 1
    stroke.Transparency = 0.3
    stroke.Parent = bg
    
    local text = Instance.new('TextLabel')
    text.Size = UDim2.new(1, 0, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = name
    text.Font = Enum.Font.GothamBold
    text.TextSize = 16
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.ZIndex = 3
    text.Parent = button
    
    button.Parent = gui
    gui.Parent = CoreGui
    
    return {gui = gui, button = button, text = text, bg = bg}
end

local function destroy_mobile_gui(gui_data)
    if gui_data and gui_data.gui then
        gui_data.gui:Destroy()
    end
end

-- ────────────────────────────────────────────────────────────────
--  COMBAT / AUTOPARRY / SPAM TAB
-- ────────────────────────────────────────────────────────────────

local CombatTab = Window:Tab({ 
    Title = "Combat", 
    Icon = "solar:sword-bold", 
    IconColor = Color3.fromHex("#FF3B30") })

    local ParrySection = CombatTab:Section({
        Title = "Auto Parry",
    })

ParrySection:Toggle({
    Title = "Auto Parry",
    Default = false,
    Callback = function(value)
        System.__properties.__autoparry_enabled = value
        if value then
            System.autoparry.start()
            if getgenv().AutoParryNotify then
                Library.SendNotification({
                    title = "Auto Parry",
                    text = "ON",
                    duration = 2
                })
            end
        else
            System.autoparry.stop()
            if getgenv().AutoParryNotify then
                Library.SendNotification({
                    title = "Auto Parry",
                    text = "OFF",
                    duration = 2
                })
            end
        end
    end
})

ParrySection:Dropdown({
    Title = "Parry Mode",
    Values = {"Remote", "Keypress"},
    Default = "Remote",
    Callback = function(value)
        getgenv().AutoParryMode = value
    end
})

ParrySection:Dropdown({
    Title = "AutoCurve",
    Values = System.__config.__curve_names,  -- adapte avec ta vraie liste
    Default = "Camera",
    Callback = function(value)
        for i, name in ipairs(System.__config.__curve_names) do
            if name == value then
                System.__properties.__curve_mode = i
                break
            end
        end
    end
})

ParrySection:Slider({
    Title = "Parry Accuracy",
    Value = { Min = 1, Max = 100, Default = 50 },
    Step = 1,
    Callback = function(value)
        System.__properties.__accuracy = value
        update_divisor()
    end
})

ParrySection:Toggle({
    Title = "Play Animation", 
    Default = false, 
    Callback = function(value)
        System.__properties.__play_animation = value
    end
})

ParrySection:Toggle({ 
    Title = "Notify",
    Default = false,
    Callback = function(value)
        getgenv().AutoParryNotify = value
    end 
})

ParrySection:Toggle({ 
    Title = "Cooldown Protection", 
    Default = false, 
    Callback = function(value)
        getgenv().CooldownProtection = value
    end 
})

ParrySection:Toggle({ 
    Title = "Auto Ability", 
    Default = false, 
    Callback = function(value)
        getgenv().AutoAbility = value
    end 
})

local TriggerSection = CombatTab:Section({
    Title = "Trigger Bot",
})

TriggerSection:Toggle({
    Title = "Triggerbot",
    Default = false,
    Callback = function(value)
        if System.__properties.__is_mobile then
            if value then
                if not System.__properties.__mobile_guis.triggerbot then
                    local triggerbot_mobile = create_mobile_button('Trigger', 0.7, Color3.fromRGB(255, 100, 0))
                    System.__properties.__mobile_guis.triggerbot = triggerbot_mobile
                    
                    local touch_start = 0
                    local was_dragged = false
                    
                    triggerbot_mobile.button.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Touch then
                            touch_start = tick()
                            was_dragged = false
                        end
                    end)
                    
                    triggerbot_mobile.button.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Touch then
                            if (tick() - touch_start) > 0.1 then
                                was_dragged = true
                            end
                        end
                    end)
                    
                    triggerbot_mobile.button.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Touch and not was_dragged then
                            System.__properties.__triggerbot_enabled = not System.__properties.__triggerbot_enabled
                            System.triggerbot.enable(System.__properties.__triggerbot_enabled)
                            
                            if System.__properties.__triggerbot_enabled then
                                triggerbot_mobile.text.Text = "ON"
                                triggerbot_mobile.text.TextColor3 = Color3.fromRGB(255, 100, 0)
                            else
                                triggerbot_mobile.text.Text = "Trigger"
                                triggerbot_mobile.text.TextColor3 = Color3.fromRGB(255, 255, 255)
                            end
                            
                            if getgenv().TriggerbotNotify then
                                Library.SendNotification({
                                    title = "Triggerbot",
                                    text = System.__properties.__triggerbot_enabled and "ON" or "OFF",
                                    duration = 2
                                })
                            end
                        end
                    end)
                end
            else
                System.__properties.__triggerbot_enabled = false
                System.triggerbot.enable(false)
                destroy_mobile_gui(System.__properties.__mobile_guis.triggerbot)
                System.__properties.__mobile_guis.triggerbot = nil
            end
        else
            System.__properties.__triggerbot_enabled = value
            System.triggerbot.enable(value)
            
            if getgenv().TriggerbotNotify then
                Library.SendNotification({
                    title = "Triggerbot",
                    text = value and "ON" or "OFF",
                    duration = 2
                })
            end
        end
    end
})

TriggerSection:Toggle({ 
    Title = "Notify", 
    Default = false, 
    Callback = function(value)
        getgenv().TriggerbotNotify = value
    end 
})

local HotkeySection = CombatTab:Section({
    Title = "AutoCurve Hotkey",
})

local function create_curve_selector_mobile()
    local gui = Instance.new('ScreenGui')
    gui.Name = 'SigmaCurveSelectorMobile'
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local main_frame = Instance.new('Frame')
    main_frame.Size = UDim2.new(0, 140, 0, 40)
    main_frame.Position = UDim2.new(0.5, -70, 0.12, 0)
    main_frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    main_frame.BorderSizePixel = 0
    main_frame.AnchorPoint = Vector2.new(0.5, 0)
    main_frame.ZIndex = 5
    main_frame.Parent = gui
    
    local main_corner = Instance.new('UICorner')
    main_corner.CornerRadius = UDim.new(0, 8)
    main_corner.Parent = main_frame
    
    local main_stroke = Instance.new('UIStroke')
    main_stroke.Color = Color3.fromRGB(60, 60, 60)
    main_stroke.Thickness = 1
    main_stroke.Parent = main_frame

    local header = Instance.new('Frame')
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundTransparency = 1
    header.ZIndex = 6
    header.Parent = main_frame
    
    local header_text = Instance.new('TextLabel')
    header_text.Size = UDim2.new(1, -35, 1, 0)
    header_text.Position = UDim2.new(0, 12, 0, 0)
    header_text.BackgroundTransparency = 1
    header_text.Text = "CURVE"
    header_text.Font = Enum.Font.Gotham
    header_text.TextSize = 11
    header_text.TextColor3 = Color3.fromRGB(180, 180, 180)
    header_text.TextXAlignment = Enum.TextXAlignment.Left
    header_text.ZIndex = 7
    header_text.Parent = header

    local toggle_btn = Instance.new('TextButton')
    toggle_btn.Size = UDim2.new(0, 24, 0, 24)
    toggle_btn.Position = UDim2.new(1, -32, 0.5, -12)
    toggle_btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    toggle_btn.Text = "−"
    toggle_btn.Font = Enum.Font.GothamBold
    toggle_btn.TextSize = 14
    toggle_btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    toggle_btn.AutoButtonColor = false
    toggle_btn.ZIndex = 7
    toggle_btn.Parent = header
    
    local toggle_corner = Instance.new('UICorner')
    toggle_corner.CornerRadius = UDim.new(0, 4)
    toggle_corner.Parent = toggle_btn
    
    local toggle_stroke = Instance.new('UIStroke')
    toggle_stroke.Color = Color3.fromRGB(50, 50, 50)
    toggle_stroke.Thickness = 1
    toggle_stroke.Parent = toggle_btn

    local buttons_container = Instance.new('Frame')
    buttons_container.Size = UDim2.new(1, -16, 0, 0)
    buttons_container.Position = UDim2.new(0, 8, 0, 48)
    buttons_container.BackgroundTransparency = 1
    buttons_container.ClipsDescendants = true
    buttons_container.ZIndex = 6
    buttons_container.Parent = main_frame
    
    local list_layout = Instance.new('UIListLayout')
    list_layout.Padding = UDim.new(0, 4)
    list_layout.FillDirection = Enum.FillDirection.Vertical
    list_layout.SortOrder = Enum.SortOrder.LayoutOrder
    list_layout.Parent = buttons_container
    
    local CURVE_TYPES = {
        {name = "Camera"},
        {name = "Random"},
        {name = "Accelerated"},
        {name = "Backwards"},
        {name = "Slow"},
        {name = "High"}
    }
    
    local buttons = {}
    local current_selected = nil
    
    for i, curve_data in ipairs(CURVE_TYPES) do
        local btn_container = Instance.new('Frame')
        btn_container.Size = UDim2.new(1, 0, 0, 32)
        btn_container.BackgroundTransparency = 1
        btn_container.ZIndex = 7
        btn_container.LayoutOrder = i
        btn_container.Parent = buttons_container
        
        local btn = Instance.new('TextButton')
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 8
        btn.Parent = btn_container
        
        local btn_corner = Instance.new('UICorner')
        btn_corner.CornerRadius = UDim.new(0, 6)
        btn_corner.Parent = btn
        
        local btn_stroke = Instance.new('UIStroke')
        btn_stroke.Color = Color3.fromRGB(45, 45, 45)
        btn_stroke.Thickness = 1
        btn_stroke.Parent = btn

        local indicator = Instance.new('Frame')
        indicator.Size = UDim2.new(0, 3, 0, 20)
        indicator.Position = UDim2.new(0, 6, 0.5, -10)
        indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        indicator.BorderSizePixel = 0
        indicator.Visible = false
        indicator.ZIndex = 10
        indicator.Parent = btn
        
        local indicator_corner = Instance.new('UICorner')
        indicator_corner.CornerRadius = UDim.new(1, 0)
        indicator_corner.Parent = indicator
        
        local btn_text = Instance.new('TextLabel')
        btn_text.Size = UDim2.new(1, -20, 1, 0)
        btn_text.Position = UDim2.new(0, 16, 0, 0)
        btn_text.BackgroundTransparency = 1
        btn_text.Text = curve_data.name
        btn_text.Font = Enum.Font.Gotham
        btn_text.TextSize = 11
        btn_text.TextColor3 = Color3.fromRGB(150, 150, 150)
        btn_text.TextXAlignment = Enum.TextXAlignment.Left
        btn_text.ZIndex = 9
        btn_text.Parent = btn
        
        buttons[i] = {
            button = btn, 
            stroke = btn_stroke, 
            text = btn_text,
            indicator = indicator,
            container = btn_container
        }
        
        local touch_start = 0
        local was_dragged = false
        
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                touch_start = tick()
                was_dragged = false
            end
        end)
        
        btn.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                if (tick() - touch_start) > 0.1 then
                    was_dragged = true
                end
            end
        end)
        
        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch and not was_dragged then

                for idx, name in ipairs(System.__config.__curve_names) do
                    if name == curve_data.name then
                        System.__properties.__curve_mode = idx
                        AutoCurveDropdown:update(curve_data.name)
                        break
                    end
                end

                if current_selected then
                    game:GetService("TweenService"):Create(current_selected.button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = Color3.fromRGB(20, 20, 20)
                    }):Play()
                    game:GetService("TweenService"):Create(current_selected.text, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        TextColor3 = Color3.fromRGB(150, 150, 150)
                    }):Play()
                    game:GetService("TweenService"):Create(current_selected.stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        Color = Color3.fromRGB(45, 45, 45)
                    }):Play()
                    current_selected.indicator.Visible = false
                end

                game:GetService("TweenService"):Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                    BackgroundColor3 = Color3.fromRGB(30, 30, 30)
                }):Play()
                game:GetService("TweenService"):Create(btn_text, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
                game:GetService("TweenService"):Create(btn_stroke, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                    Color = Color3.fromRGB(255, 255, 255)
                }):Play()
                indicator.Visible = true
                
                current_selected = buttons[i]
                
                if getgenv().AutoCurveHotkeyNotify then
                    Library.SendNotification({
                        title = "AutoCurve",
                        text = curve_data.name,
                        duration = 2
                    })
                end
            end
        end)
    end

    local is_expanded = true
    local expanded_height = 48 + (#CURVE_TYPES * 32) + ((#CURVE_TYPES - 1) * 4) + 12
    local minimized_height = 40
    
    buttons_container.Size = UDim2.new(1, -16, 0, (#CURVE_TYPES * 32) + ((#CURVE_TYPES - 1) * 4))
    main_frame.Size = UDim2.new(0, 140, 0, expanded_height)
    
    toggle_btn.MouseButton1Click:Connect(function()
        is_expanded = not is_expanded
        toggle_btn.Text = is_expanded and "−" or "+"
        
        game:GetService("TweenService"):Create(main_frame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 140, 0, is_expanded and expanded_height or minimized_height)
        }):Play()
        
        game:GetService("TweenService"):Create(buttons_container, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, -16, 0, is_expanded and (#CURVE_TYPES * 32) + ((#CURVE_TYPES - 1) * 4) or 0)
        }):Play()
    end)

    local drag_start = nil
    local start_pos = nil
    local is_dragging = false
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag_start = input.Position
            start_pos = main_frame.Position
            is_dragging = true
        end
    end)
    
    header.InputChanged:Connect(function(input)
        if is_dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - drag_start
            main_frame.Position = UDim2.new(
                start_pos.X.Scale,
                start_pos.X.Offset + delta.X,
                start_pos.Y.Scale,
                start_pos.Y.Offset + delta.Y
            )
        end
    end)
    
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            is_dragging = false
        end
    end)
    
    gui.Parent = CoreGui
    
    return {gui = gui, main_frame = main_frame, buttons = buttons}
end

local CURVE_TYPES = {
    {key = Enum.KeyCode.One, name = "Camera"},
    {key = Enum.KeyCode.Two, name = "Random"},
    {key = Enum.KeyCode.Three, name = "Accelerated"},
    {key = Enum.KeyCode.Four, name = "Backwards"},
    {key = Enum.KeyCode.Five, name = "Slow"},
    {key = Enum.KeyCode.Six, name = "High"}
}

local function updateCurveType(newType)
    for i, name in ipairs(System.__config.__curve_names) do
        if name == newType then
            System.__properties.__curve_mode = i
            AutoCurveDropdown:update(newType)
            break
        end
    end
    
    if getgenv().AutoCurveHotkeyNotify then
        Library.SendNotification({
            title = "AutoCurve",
            text = newType,
            duration = 2
        })
    end
end

HotkeySection:Toggle({ 
    Title = "AutoCurve Hotkey" .. (System.__properties.__is_mobile and "(Mobile)" or "(PC)"), 
    Default = false, 
    Callback = function(state)
        getgenv().AutoCurveHotkeyEnabled = state
        
        if System.__properties.__is_mobile then
            if state then
                if not System.__properties.__mobile_guis.curve_selector then
                    local curve_selector = create_curve_selector_mobile()
                    System.__properties.__mobile_guis.curve_selector = curve_selector
                end
            else
                destroy_mobile_gui(System.__properties.__mobile_guis.curve_selector)
                System.__properties.__mobile_guis.curve_selector = nil
            end
        end
    end
})

HotkeySection:Toggle({ 
    Title = "Notify", 
    Default = false, 
    Callback = function(value)
        getgenv().AutoCurveHotkeyNotify = value
    end
})

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not getgenv().AutoCurveHotkeyEnabled or System.__properties.__is_mobile then return end
    
    if input.UserInputType == Enum.UserInputType.Keyboard then
        for _, curveData in ipairs(CURVE_TYPES) do
            if input.KeyCode == curveData.key then
                updateCurveType(curveData.name)
                break
            end
        end
    end
end)

local DetectionSection = CombatTab:Section({
    Title = "Detections",
})

DetectionSection:Toggle({
    Title = "Infinity Detection",
    Default = false,
    Callback = function(value)
        System.__config.__detections.__infinity = value
    end
})

DetectionSection:Toggle({
    Title = "Death Slash Detection",
    Default = false,
    Callback = function(value)
        System.__config.__detections.__deathslash = value
    end
})

DetectionSection:Toggle({
    Title = "Time Hole Detection",
    Default = false,
    Callback = function(value)
        System.__config.__detections.__timehole = value
    end
})

DetectionSection:Toggle({
    Title = "Slashes Of Fury Detection",
    Default = false,
    Callback = function(value)
        System.__config.__detections.__slashesoffury = value
    end
})

DetectionSection:Slider({
    Title = "Parry Delay",
    Value = { Min = 0.05, Max = 0.250, Default = 0.05 },
    Step = 0.01,
    Callback = function(value)
        parryDelay = value
    end
})

DetectionSection:Slider({
    Title = "Max Parry Count",
    Value = { Min = 0.05, Max = 0.250, Default = 0.05 },
    Step = 0.01,
    Callback = function(value)
        maxParryCount = value
    end
})

DetectionSection:Toggle({
    Title = "Anti-Phantom [BETA]",
    Default = false,
    Callback = function(value)
        System.__config.__detections.__phantom = value
    end
})

local AutoSpamSection = CombatTab:Section({
    Title = "Auto Spam Parry",
})

AutoSpamSection:Toggle({
    Title = "Auto Spam",
    Default = false,
    Callback = function(value)
        System.__properties.__auto_spam_enabled = value
        if value then
            System.auto_spam.start()
            if getgenv().AutoSpamNotify then
                Library.SendNotification({
                    title = "Auto Spam",
                    text = "ON",
                    duration = 2
                })
            end
        else
            System.auto_spam.stop()
            if getgenv().AutoSpamNotify then
                Library.SendNotification({
                    title = "Auto Spam",
                    text = "OFF",
                    duration = 2
                })
            end
        end
    end
})

AutoSpamSection:Toggle({ 
    Title = "Notify", 
    Default = false, 
    Callback = function(value)
        getgenv().AutoSpamNotify = value
    end 
})

AutoSpamSection:Dropdown({
    Title = "Mode",
    Values = {"Remote", "Keypress"},
    Default = "Remote",
    Callback = function(value)
        getgenv().AutoSpamMode = value
    end
})

AutoSpamSection:Toggle({ 
    Title = "Animation Fix", 
    Default = false, 
    Callback = function(value)
        getgenv().AutoSpamAnimationFix = value
    end
})

AutoSpamSection:Slider({
    Title = "Spam Rate",
    Value = { Min = 1, Max = 5, Default = 2.5 },
    Step = 0.1,
    Callback = function(value)
        System.__properties.__spam_threshold = value
    end
})

local ManualSpamSection = CombatTab:Section({
    Title = "Manual Spam Parry",
})

ManualSpamSection:Toggle({
    Title = "Manual Spam",
    Default = false,
    Callback = function(state)
        if System.__properties.__is_mobile then
            if state then
                if not System.__properties.__mobile_guis.manual_spam then
                    local manual_spam_mobile = create_mobile_button('Spam', 0.8, Color3.fromRGB(255, 255, 255))
                    System.__properties.__mobile_guis.manual_spam = manual_spam_mobile
                    
                    local manual_touch_start = 0
                    local manual_was_dragged = false
                    
                    manual_spam_mobile.button.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Touch then
                            manual_touch_start = tick()
                            manual_was_dragged = false
                        end
                    end)
                    
                    manual_spam_mobile.button.InputChanged:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Touch then
                            if (tick() - manual_touch_start) > 0.1 then
                                manual_was_dragged = true
                            end
                        end
                    end)
                    
                    manual_spam_mobile.button.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Touch and not manual_was_dragged then
                            System.__properties.__manual_spam_enabled = not System.__properties.__manual_spam_enabled
                            
                            if System.__properties.__manual_spam_enabled then
                                System.manual_spam.start()
                                manual_spam_mobile.text.Text = "ON"
                                manual_spam_mobile.text.TextColor3 = Color3.fromRGB(0, 255, 100)
                            else
                                System.manual_spam.stop()
                                manual_spam_mobile.text.Text = "Spam"
                                manual_spam_mobile.text.TextColor3 = Color3.fromRGB(255, 255, 255)
                            end
                            
                            if getgenv().ManualSpamNotify then
                                Library.SendNotification({
                                    title = "ManualSpam",
                                    text = System.__properties.__manual_spam_enabled and "ON" or "OFF",
                                    duration = 2
                                })
                            end
                        end
                    end)
                end
            else
                System.__properties.__manual_spam_enabled = false
                System.manual_spam.stop()
                destroy_mobile_gui(System.__properties.__mobile_guis.manual_spam)
                System.__properties.__mobile_guis.manual_spam = nil
            end
        else
            System.__properties.__manual_spam_enabled = state
            if state then
                System.manual_spam.start()
            else
                System.manual_spam.stop()
            end
            
            if getgenv().ManualSpamNotify then
                Library.SendNotification({
                    title = "Manual Spam",
                    text = state and "ON" or "OFF",
                    duration = 2
                })
            end
        end
    end
})

ManualSpamSection:Toggle({ 
    Title = "Notify", 
    Default = false, 
    Callback = function(value)
        getgenv().ManualSpamNotify = value
    end
})

ManualSpamSection:Dropdown({
    Title = "Mode",
    Values = {"Remote", "Keypress"},
    Default = "Remote",
    Callback = function(value)
        getgenv().ManualSpamMode = value
    end
})

ManualSpamSection:Toggle({ 
    Title = "Animation Fix", 
    Default = false, 
    Callback = function(value)
        getgenv().ManualSpamAnimationFix = value
    end
})

ManualSpamSection:Slider({
    Title = "Spam Rate",
    Value = { Min = 60, Max = 5000, Default = 240 },
    Step = 10,
    Callback = ffunction(value)
        System.__properties.__spam_rate = value
    end
})
