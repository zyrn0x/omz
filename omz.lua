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

task.spawn(function()
local WindUI = loadstring([[--[=[
     _      ___         ____  ______
    | | /| / (_)__  ___/ / / / /  _/
 
  | |/ |/ / / _ \/ _  / /_/ // /  
    |__/|__/_/_//_/\_,_/\____/___/
    
   
v1.6.64  |  2026-01-23  |  Roblox UI Library for scripts
    
    To view the
source code, see the `src/` folder on the official GitHub repository.
    
   
Author: Footagesus (Footages, .ftgs, oftgs)
    Github:
https://github.com/Footagesus/WindUI
    Discord:
https://discord.gg/ftgs-development-hub-1300692552005189632
    License: MIT
]=]

local a a={cache={}, load=function(b)if not
a.cache[b]then a.cache[b]={c=a[b]()}end return a.cache[b].c end}do function a.a()local
...
...
end
end

function d.SetIconsType(e)
d.IconsType=e
end

local e
function
d.Init(f,g)
d.New=f
d.IconThemeTag=g

e=f
return d
end

function d.Icon(f,g,h)
h=h~=false
local
i,j=parseIconString(f)

local l=i or g or d.IconsType
local m=j

local p=d.Icons[l]

if
p and p.Icons and
p.Icons[m]then
return{
p.Spritesheets[tostring(p.Icons[m].Image)],
p.Icons[m],
}
elseif p and p[m]and
string.find(p[m],"rbxassetid://")then
return h
and{
p[m],
{ImageRectSize=Vector2.new(0,0),ImageRectPosition=Vector2.new(0,0)}
}or p[m]
end
return nil
end

function d.GetIcon(f,g)
return
d.Icon(f,g,false)
end


function d.Icon2(f,g,h)
return d.Icon(f,g,true)
end
...
...
function
d.Image(f)
local g={
Icon=f.Icon or nil,
Type=f.Type,
Colors=f.Colors or{(d.IconThemeTag
or Color3.new(1,1,1)),Color3.new(1,1,1)},
Transparency=f.Transparency
or{0,0},
Size=f.Size or UDim2.new(0,24,0,24),

IconFrame=nil,
}

local h={}
local
i={}

for j,l in next,g.Colors do
h[j]={
ThemeTag=typeof(l)=="string"and
l,
Color=typeof(l)=="Color3"and l,
}
end

for j,l in next,g.Transparency
do
i[j]={
ThemeTag=typeof(l)=="string"and l,
Value=typeof(l)=="number"and l,
}
end


local
j=d.Icon2(g.Icon,g.Type)
local l=typeof(j)=="string"and string.find(j,'rbxassetid://')

if
d.New then
local m=e or d.New



local
p=m("ImageLabel",{
...
...
v.ImageRec
Size=u[2].ImageRectSize
v.ImageRectOffset=u[2].ImageRectPosition
v.Parent=m
end
end

g.IconFrame=m
end


return g
end

return d end function
a.b()

return{


P
rimary="Icon",

White=Color3.new(1,1,1),
Black=Color3.new(0,0,0),

Dialog="Accen
",

Background="Accent",
BackgroundTransparency=0,
Hover="Text",

PanelBackgrou
d="White",
PanelBackgroundTransparency=.95,

WindowBackground="Background",

Wi
dowShadow="Black",


WindowTopbarTitle="Text",
WindowTopbarAuthor="Text",
Windo
TopbarIcon="Icon",
WindowTopbarButtonIcon="Icon",

WindowSearchBarBackground="B
ckground",

TabBackground="Hover",
TabBackgroundHover="Hover",
TabBackgroundHov
rTransparency=.97,
TabBackgroundActive="Hover",
TabBackgroundActiveTransparency
0.93,
TabText="Text",
TabTextTransparency=0.3,
...
...
TabTextTransparencyActive=0,
Tab
itle="Text",
TabIcon="Icon",
TabIconTransparency=0.4,
TabIconTransparencyActive
0.1,
TabBorderTransparency=1,
TabBorderTransparencyActive=0.75,
TabBorder="Whit
",


ElementBackground="Text",
ElementTitle="Text",
ElementDesc="Text",
Element
con="Icon",

PopupBackground="Background",
PopupBackgroundTransparency="Backgro
ndTransparency",
PopupTitle="Text",
PopupContent="Text",
PopupIcon="Icon",

Dia
ogBackground="Background",
DialogBackgroundTransparency="BackgroundTransparency
,
DialogTitle="Text",
DialogContent="Text",
DialogIcon="Icon",

Toggle="Button"

ToggleBar="White",

Checkbox="Primary",
CheckboxIcon="White",
CheckboxBorder="
hite",
CheckboxBorderTransparency=.75,

SliderIcon="Icon",

Slider="Primary",
S
iderThumb="White",
SliderIconFrom="SliderIcon",
SliderIconTo="SliderIcon",

Too
tip=Color3.fromHex"4C4C4C",
TooltipText="White",
...
...
TooltipSecondary="Primary",
To
ltipSecondaryText="White",

SectionExpandIcon="White",
SectionExpandIconTranspa
ency=.4,
SectionBox="White",
SectionBoxTransparency=.95,
SectionBoxBorder="Whit
",
SectionBoxBorderTransparency=.75,
SectionBoxBackground="White",
SectionBoxBa
kgroundTransparency=.95,

SearchBarBorder="White",
SearchBarBorderTransparency=
75,

Notification="Background",
NotificationTitle="Text",
NotificationTitleTran
parency=0,
NotificationContent="Text",
NotificationContentTransparency=.4,
Noti
icationDuration="White",
NotificationDurationTransparency=.95,
NotificationBord
r="White",
NotificationBorderTransparency=.75,

DropdownTabBorder="White",

LabelBackground="White",
LabelBackgroundTransparency=.95,
}end function
a.c()


local b=(cloneref or clonereference or function(b)return b end)

local
d=b(game:GetService"RunService")
local e=b(game:GetService"UserInputService")
local
f=b(game:GetService"TweenService")
...
...
local g=b(game:GetService"LocalizationService")
local
h=b(game:GetService"HttpService")local i=

d.Heartbeat

local
j="https://raw.githubusercontent.com/Footagesus/Icons/main/Main-v2.lua"

local l
if
d:IsStudio()or not writefile then
l=a.load'a'
else
l=loadstring(
game.HttpGetAsync and
game:HttpGetAsync(j)
or h:GetAsync(j)
)()
end

l.SetIconsType"lucide"

local m

local

={
Font="rbxassetid://12187365364",
Localization=nil,
CanDraggable=true,
Theme=
il,
Themes=nil,
Icons=l,
Signals={},
Objects={},
LocalizationObjects={},
FontOb
ects={},
Language=string.match(g.SystemLocaleId,"^[a-z]+"),
Request=http_request or(syn and syn.request)or
request,
DefaultProperties={
ScreenGui={
ResetOnSpaw
=false,
ZIndexBehavior="Sibling",
},
CanvasGroup={
BorderSizePixel=0,
Backgroun
...
...
://117817408534198",

["Shadow-sm"]="rbxassetid://84825982946844",

["Squircle-
L-TR"]="rbxassetid://73569156276236",
["Squircle-BL-BR"]="rbxassetid://93853842
12264",
["Squircle-TL-TR-Outline"]="rbxassetid://136702870075563",
["Squircle-B
-BR-Outline"]="rbxassetid://75035847706564",

["Glass-0.7"]="rbxassetid://79047
52995006",
["Glass-1"]="rbxassetid://97324581055162",
["Glass-1.4"]="rbxassetid://95071123641270",
}
}

function p.Init(r)
m=r
end

function
p.AddSignal(r,u)
local v=r:Connect(u)
table.insert(p.Signals,v)
return v
end

function
p.DisconnectAll()
for r,u in next,p.Signals do
local
v=table.remove(p.Signals,r)
v:Disconnect()
end
end

function p.SafeCallback(r,...)
if not r then
return
end

local
u,v=pcall(r,...)
if not u then
if m and m.Window and m.Window.Debug then local
x,
z=v:find":%d+: "

warn("[ WindUI: DEBUG Mode ] "..v)

return
m:Notify{
Title="DEBUG Mode: Error",
Content=not z and v or
v:sub(z+1),
Duration=8,
}
end
end
end

function p.Gradient(r,u)
if m and m.Gradient then
return
m:Gradient(r,u)
end

local v={}
local x={}

for z,A in next,r do
local B=tonumber(z)
if B
then
B=math.cl
mp(B/100,0,1)
table.insert(v,ColorSequenceKeypoint.new(B,A.Color))
table.insert(x,NumberSequenceKeypoint.new(B,A.Transparency or
0))
end
end
...
...
string.sub(z,1,1)=="#"then
return Color3.fromHex(z)
end

if typeof(z)=="Color3"then
return
z
end

if typeof(z)=="table"and z.Color
and z.Transparency then
return z
end

if typeof(z)=="function"then
return
z()
end

return z
end

local v=getValue(r,u)
if v~=nil then
if typeof(v)=="string"and
string.sub(v,1,1)~="#"then
local x=p.GetThemeProperty(v,u)
if x~=nil
then
return x
end
else
return v
end
end

local x=p.ThemeFallbacks[r]
if x~=nil then
if
typeof(x)=="string"and string.sub(x,1,1)~="#"then
return
p.GetThemeProperty(x,u)
else
return getValue(r,{[r]=x})
end
end

v=getValue(r,p.Themes.Dark)
if v~=nil
...
...
local function ApplyTheme(B)
for
C,F in pairs(B.Properties or{})do
local G=p.GetThemeProperty(F,p.Theme)
if G~=nil
then
if typeof(G)=="Color3"then
local
H=B.Object:FindFirstChild"LibraryGradient"
if H then
H:Destroy()
end

if v then
p.Tween(
B.Object,
x or 0.2,
{[C]=G},
z
or Enum.EasingStyle.Quint,
A or Enum.EasingDirection.Out
):Play()
elseif u
then
p.Tween(B.Object,0.08,{[C]=G}):Play()
else
B.Object[C]=G
end
elseif
typeof(G)=="table"and G.Color and G.Transparency then
B.Object[C]=Color3.new(1,1,1)

local
H=B.Object:FindFirstChild"LibraryGradient"
if not H
then
H=Instance.new"UIGradient

H.Name="LibraryGradient"
H.Parent=B.Object
end

H.Color=G.Color
H.Transparency=G.Transparency
...
...
for J,L in pairs(G)do
if J~="Color"and J~="Transparency"and
H[J]~=nil then
H[J]=L
end
end
elseif typeof(G)=="number"then
if v
then
p.Tween(
B.Object,
x or 0.2,
{[C]=G},
z or Enum.EasingStyle.Quint,
A or
Enum.EasingDirection.Out
):Play()
elseif u
then
p.Tween(B.Object,0.08,{[C]=G}):Play()
else
B.Object[C]=G
end
end
else

local H=B.Object:FindFirstChild"LibraryGradient"
if H
then
H:Destroy()
end
end
end
end

if r then
local B=p.Objects[r]
if B
then
ApplyTheme(B)
end
else
for B,C in pairs(p.Objects)do
ApplyTheme(C)
end
end
end


function
p.
etThemeTag(r,u,v,x,z)
p.AddThemeObject(r,u)
p.UpdateTheme(r,false,true,v,x,z)
...
...
C=#p.LocalizationObjects+1
p.LocalizationObjects[C]={TranslationId=B,Object=x}

p.SetLangForObject(C)
end
end
end

for z,A in next,v
or{}do
A.Parent=x
end

if u and u.ThemeTag then
p.AddThemeObject(x,u.ThemeTag)
end
if u and
u.FontFace then
p.AddFontObject(x)
end
return x
end

function
p.Tween(r,u,v,...)
return f:Create(r,TweenInfo.new(u,...),v)
end

function
p.NewRoundFrame(r,u,v,x,z,A)
local function getImageForType(B)
return p.Shapes[B]
end

local function
getSliceCenterForType(B)
return not
table.find({"Shadow-sm","Glass-0.7","Glass-1","Glass-1.4"},B)and Rect.new(256
,256
,256
,256

)or
Rect.new(512,512,512,512)
end

local B=p.New(z
and"ImageButton"or"ImageLabel",{
...
...
end
end
end)

function
G.Set(H,J)
G.CanDraggable=J
end

return G
end


l.Init(r,"Icon")


function p.SanitizeFilename(v)
local
x=v:match"([^/]+)$"or
v

x=x:gsub("%.[^%w%-_]","_")

if#x>50 then
x=x:sub(1,50)
end

return x
end

function p.Image(v,x,z,A,B,C,F,G)
A=A
or"Temp"
x=p.SanitizeFilename(x)

local
H=r("Frame",{
Size=UDim2.new(0,0,0,0),

ackgroundTransparency=1,
},{
r("ImageLabel",{
Size=UDim2.new(1,0,1,0),
BackgroundTransparency=1,
ScaleType="Crop",
ThemeTag=(p.Icon(v)or F)and{
ImageColor3=C
and(G or"Icon")or nil
}or
nil,
},{
...
...
if not L
then
warn("[ WindUI.Creator ]  '"..identifyexecutor()or"Studio".."' doesnt support the
URL Images. Error: "..M)

H:Destroy()
end
elseif
v==""then
H.Visible=false
else
H.ImageLabel.Image=v
end

return H
end



function p.Color3ToHSB(v)
local
x,z,A=v.R,v.G,v.B
local B=math.max(x,z,A)
local C=math.min(x,z,A)
local F=B-C

local
G=0
if F~=0 then
if B==x then
G=(z-A)/F%6
elseif B==z
then
G=(A-x)/F+2
else
G=(x-z)/F+4
end
G=G*60
else
G=0
end

local H=(B==0)and 0 or(F/B)
local
J=B

return{
h=math.floor(G+0.5),
s=H,
b=J
}
end
...
...
return p end function a.d()

local b={}







function b.New(d,e,f)
local g={
Enabled=e.Enabled or
false,
Translations=e.Translations or{},
Prefix=e.Prefix
or"loc:",
DefaultLanguage=e.DefaultLanguage or"en"
}

f.Localization=g

return g
end



return b end function a.e()
local b=a.load'c'
local d=b.New
local e=b.Tween

local
f={
Size=UD
m2.new(0,300,1,-156),
SizeLower=UDim2.new(0,300,1,-56),
UICorner=18,
UIPadding=14,

Holder=nil,
NotificationIndex=0,
Notifications={}
}

function
f.Init(g)
local h={
Lower=false
}

function h.SetLower(j)
h.Lower=j
h.Frame.Size=j and
f.SizeLower or
f.Size
end

h.Frame=d("Frame",{
Position=UDim2.new(1,-29,0,56),
AnchorP
int=Vector2.new(1,0),
Size=f.Size,
...
...
Size=UDim2.new(0,0,1,0),
ThemeTag={
ImageTransparency="NotificationDurationTransparency",
ImageColor3="NotificationDuration",
},

})

local
p=d("Frame",{
Size=UDim2.new(1,
h.Icon and-28-f.UIPadding or
0,
1,0),
Position=UDim
.new(1,0,0,0),
AnchorPoint=Vector2.new(1,0),
BackgroundTransparency=1,
Automati
Size="Y",
},{
d("UIPadding",{
PaddingTop=UDim.new(0,f.UIPadding),
PaddingLeft=U
im.new(0,f.UIPadding),
PaddingRight=UDim.new(0,f.UIPadding),
PaddingBottom=UDim
new(0,f.UIPadding),
})
})
})

ah.UIElements.Title=am("TextLabel",{
Text=H.Title,
TextSize=20,
FontFace=Fo
t.new(al.Font,Enum.FontWeight.SemiBold),
TextXAlignment="Left",
TextWrapped=true,
RichText=true,
Size=UDim2.new(1,M and-26-J.UIPadding or
0,0,0),
AutomaticSize="Y",
ThemeTag={
TextColor3="Text"
},
BackgroundTransparency=1,
Parent=L
})
if
H.Content
then
am("TextLabel",{
Text=H.Content,
TextSize=18,
TextTransparency=.4,
TextWrapped=true,
RichText=true,
FontFace=Font.new(al.Font,Enum.FontWeight.Medi
m),
TextXAlignment="Left",
...
...
Size=UDim2.new(1,0,0,0),
AutomaticSize="Y",
LayoutOr
er=2,
ThemeTag={
TextColor3="Text"
},
BackgroundTransparency=1,
Parent=J.UIElem
nts.Main
},{
am("UIPadding",{
PaddingLeft=UDim.new(0,H.TextPadding/2),
PaddingR
ght=UDim.new(0,H.TextPadding/2),
PaddingBottom=UDim.new(0,H.TextPadding/2),
})
})
end

local
N=am("UIListLayout",{
Padding=UDim.new(0,6),
FillDirection="Horizontal",
HorizontalAlignment="Right",
})

local
O=am("Frame",{
Size=UDim2.new(1,0,
,40),
AutomaticSize="None",
BackgroundTransparency=1,
Parent=J.UIElements.Main,
LayoutOrder=4,
},{
N,






})


local P={}

for Q,R in next,H.Buttons do
local
S=ap(R.Title,R.Icon,R.Callback,R.Variant,O,J,true)
table.insert(P,S)
end

local
...
...
function
CheckButtonsOverflow()
N.FillDirection=Enum.FillDirection.Horizontal
N
HorizontalAlignment=Enum.HorizontalAlignment.Right
N.VerticalAlignment=Enum.VerticalAlignment.Center
O.AutomaticSize=Enum.AutomaticSize.None

for Q,R in
ipairs
P)do
R.Size=UDim2.new(0,0,1,0)
R.AutomaticSize=Enum.AutomaticSize.X
end

wait()

local Q=N.AbsoluteContentSize.X/at.WindUI.UIScale
local
R=O.AbsoluteSize.X/at.WindUI.UIScale

if Q>R
then
N.FillDirection=Enum.FillDirection.Vertical
N.Horizo
talAlignment=Enum.HorizontalAlignment.Right
N.VerticalAlignment=Enum.VerticalAlignment.Bottom
O.AutomaticSize=Enum.AutomaticSize.Y

for S,T in
ipairs(P)do
T.Size=UDim2.new(1,0,0,40)
T.AutomaticSize=Enum.AutomaticSize.None
end
else
local
S=R-Q
if S>0 then
local T
...
...
local U=math.huge

for V,W in ipairs(P)do
local
X=W.AbsoluteSize.X/at.WindUI.UIScale
if X<U then
U=X
T=W
end
end

if T
then
T.Size=UDim2
new(0,U+S,1,0)
T.AutomaticSize=Enum.AutomaticSize.None
end
end
end
end

al.AddS
gnal(J.UIElements.Main:GetPropertyChangedSignal"AbsoluteSize",CheckButtonsOverflow)
CheckButtonsOverflow()

wait()
J:Open()

return J
end

local
F=false

au:CreateTopbarButton("Close","x",function()
if not F then
if not au.IgnoreAlerts
then
F=true
au:SetToTheCenter()
au:Dialog{

Title="Close Window",
Content="Do you
want to close this window? You will not be able to open it
again.",
Buttons={
{
Title="Cancel",

Callback=function()F=false
end,
Variant="Secondary",
},
{
Title="Close
Window",

Callback=function()
...
...
al.AddSignal(O.MouseButton1Click,function()
if N then return
end

M.new(au.TabModule,au.UIElements.Main,function()

N=false
if au.Resizable
th
n
au.CanResize=true
end

an(az,0.1,{ImageTransparency=1}):Play()
az.Active=fals

end)
an(az,0.1,{ImageTransparency=.65}):Play()
az.Active=true

N=true
au.CanResize=false
end)
end




function au.DisableTopbarButtons(M,N)
for O,P in next,N
do
for Q,R in next,au.TopBarButtons do
if R.Name==P
then
R.Object.Visible=false
end
end
end
end




























return au
end end end

local
aa=game:GetService"RunService"
local
ae={
Window=nil,
Theme=nil,
Creator=a.load'c',
Loc
lizationModule=a.load'd',
NotificationModule=a.load'e',
Themes=nil,
Transparent
false,

TransparencyValue=.15,

UIScale=1,

ConfigManager=nil,
...
...
Version="0.0.0",

Services=a.load'j',

OnThemeChangeFunction=nil,

cloneref=nil,
UIScaleObj=nil,
}


local af=(cloneref or clonereference or function(af)return af
end)

ae.cloneref=af

local ah=af(game:GetService"HttpService")
local
aj=af(game:GetService"Players")
local ak=af(game:GetService"CoreGui")local al=

aj.LocalPlayer or
nil

local am=ah:JSONDecode(a.load'k')
if am then
ae.Version=am.version
end

local
an=a.load'o'local ao=

ae.Services


local ap=ae.Creator

local aq=ap.New local
ar=
ap.Tween


local as=a.load's'


local at=protectgui or(syn and
syn.protect_gui)or function()end

local au=gethui and gethui()or(ak or
game.Players.LocalPlayer:WaitForChild"PlayerGui")

local
av=aq("UIScale",{
Scale=ae.Scale,
})
...
...
ae.UIScal
Obj=av

ae.ScreenGui=aq("ScreenGui",{
Name="WindUI",
Parent=au,
IgnoreGuiInset=
rue,
ScreenInsets="None",
},{

aq("Folder",{
Name="Window"
}),






aq("Folder
,{
Name="KeySystem"
}),
aq("Folder",{
Name="Popups"
}),
aq("Folder",{
Name="Too
Tips"
})
})

ae.NotificationGui=aq("ScreenGui",{
Name="WindUI/Notifications",
P
rent=au,
IgnoreGuiInset=true,
})
ae.DropdownGui=aq("ScreenGui",{
Name="WindUI/D
opdowns",
Parent=au,
IgnoreGuiInset=true,
})
ae.TooltipGui=aq("ScreenGui",{
Nam
="WindUI/Tooltips",
Parent=au,
IgnoreGuiInset=true,
})
at(ae.ScreenGui)
at(ae.NotificationGui)
at(ae.DropdownGui)
at(ae.TooltipGui)

ap.Init(ae)


function
ae.
etParent(aw,ax)
ae.ScreenGui.Parent=ax
...
...
ae.Themes
end
function ae.GetCurrentTheme(ax)
return ae.Theme.Name
end
function
ae.GetTransparency(ax)
return ae.Transparent or false
end
function ae.GetWindowSize(ax)
return
Window.UIElements.Main.Size
end
function ae.Localization(ax,ay)
return
ae.LocalizationModule:New(ay,ap)
end

function ae.SetLanguage(ax,ay)
if ap.Localization
then
return ap.SetLanguage(ay)
end
return false
end

function
ae.ToggleAcrylic(ax,ay)
if ae.Window and ae.Window.AcrylicPaint and ae.Window.AcrylicPaint.Model
then
ae.Window.Acrylic=ay
ae.Window.AcrylicPaint.Model.Transparency=ay and 0.98 or
1
if ay then
as.Enable()
else
as.Disable()
end
end
end


function
ae.Gradient(ax,ay,az)
local aA={}
local aB={}

for b,d in next,ay do
local f=tonumber(b)
if f
then
f=math.clamp(f/100,0,1)
...
...
a.load't'.new(ay)
end


ae.The
es=a.load'u'(ae)

ap.Themes=ae.Themes


ae:SetTheme"Dark"
ae:SetLanguage(ap.Language)


function ae.CreateWindow(ax,ay)
local az=a.load'_'

if not
aa:IsStudio()and writefile then
if not isfolder"WindUI"then
makefolder"WindUI"
end
if
ay.Folder
then
makefolder(ay.Folder)
else
makefolder(ay.Title)
end
end

ay.WindUI=ae
ay.Parent=ae.ScreenGui.Window

if ae.Window then
warn"You cannot create more than
one window"
return
end

local aA=true

local aB=ae.Themes[ay.Theme
or"Dark"]


ap.SetTheme(aB)


local b=gethwid or function()
return
aj.LocalPlayer.UserId
end

local d=b()

if ay.KeySystem then
aA=false

local function
loadKeysystem()
an.new(ay,d,function(f)aA=f end)
end
...
...
next,m.Args do
table.insert(p,l[u])
end

local r=m.New(table.unpack(p))
local
u=r.Verify(g)
if u then
h=true
break
end
end
end

aA=h
if not h then
loadKeysystem()end
else
loadKeysystem()
end
end

repeat task.wait()until aA
end

local
f=az(ay)

ae.Transparent=ay.Transparent
ae.Window=f

if ay.Acrylic
then
as.init()
end













return f
end

return ae]])()

local Window = WindUI:CreateWindow({
    Title = "OMZ Hub",
    --Author = "zyrn0x",
    Folder = "OMZ_Config",
    Icon = "solar:folder-2-bold-duotone",
    OpenButton = {
        Title = "Ouvrir OMZ",
        CornerRadius = UDim.new(1,0),
        Enabled = true,
        Draggable = true,
        Scale = 0.55,
        Color = ColorSequence.new(
            Color3.fromHex("#00ffea"),
            Color3.fromHex("#ff00aa")
        )
    },
    Topbar = { Height = 44, ButtonsType = "Mac" },
})

-- Tags (optionnel)
Window:Tag({ Title = "v1.0 • OMZ", Icon = "github", Color = Color3.fromHex("#1c1c1c"), Border = true })

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
    Callback = function(value)
        System.__properties.__spam_rate = value
    end
})

-- ────────────────────────────────────────────────────────────────
--  VISUAL TAB
-- ────────────────────────────────────────────────────────────────
local __players = cloneref(game:GetService('Players'))
local __localplayer = __players.LocalPlayer

local __flags = {}
local __currentDesc = nil
local __targetUserId = nil
local __persistent_tasks = {} -- index por Character para coroutines/threads de reaplicação

-- Função utilitária para comparar se a descrição aplicada parece OK
-- Não existe comparação perfeita, mas checamos algumas propriedades chave (Shirt/Pants/Graphic)
local function __descriptions_match(a, b)
    if not a or not b then return false end
    -- Compara algumas propriedades comumente usadas
    local keys = {"Shirt", "Pants", "ShirtGraphic", "Head", "Face", "BodyTypeScale", "HeightScale", "WidthScale", "DepthScale", "ProportionScale"}
    for _,k in ipairs(keys) do
        local av = a[k]
        local bv = b[k]
        if (av ~= nil and bv ~= nil) and tostring(av) ~= tostring(bv) then
            return false
        end
    end
    return true
end

-- APLICAÇÃO EXTREMAMENTE FORÇADA – várias estratégias
local function __force_apply_brutal(hum, desc)
    if not hum or not desc then return false end

    -- 0) Tenta aplicar diretamente algumas vezes rápidas
    for _ = 1, 20 do
        pcall(function()
            hum:ApplyDescriptionClientServer(desc)
        end)
        task.wait(0.05)
        local applied = nil
        pcall(function() applied = hum:GetAppliedDescription() end)
        if applied and __descriptions_match(applied, desc) then
            return true
        end
    end

    -- 1) Reset suave e tentar de novo
    pcall(function()
        hum.Description = Instance.new("HumanoidDescription")
    end)
    task.wait(0.1)

    for _ = 1, 20 do
        pcall(function()
            hum:ApplyDescriptionClientServer(desc)
        end)
        task.wait(0.05)
        local applied = nil
        pcall(function() applied = hum:GetAppliedDescription() end)
        if applied and __descriptions_match(applied, desc) then
            return true
        end
    end

    -- 2) Tenta recriar humanoid se houver HumanoidRootPart (substituição forçada)
    local parent = hum.Parent
    local root = parent and parent:FindFirstChild("HumanoidRootPart")
    if root and parent then
        local old = hum
        local success, newHum = pcall(function()
            local nh = Instance.new("Humanoid")
            nh.Name = "Humanoid"
            nh.Parent = parent
            return nh
        end)
        task.wait(0.05)
        if success and newHum then
            -- Destrói o antigo para forçar atualização de character
            pcall(function() old:Destroy() end)
            hum = newHum
            task.wait(0.05)
        end
    end

    -- 3) Última onda de tentativas estendidas
    for _ = 1, 80 do
        pcall(function()
            hum:ApplyDescriptionClientServer(desc)
        end)
        task.wait(0.05)
        local applied = nil
        pcall(function() applied = hum:GetAppliedDescription() end)
        if applied and __descriptions_match(applied, desc) then
            return true
        end
    end

    return false
end

local function __apparence(__name)
    local s, e = pcall(function()
        local __id = __players:GetUserIdFromNameAsync(__name)
        return __players:GetHumanoidDescriptionFromUserId(__id), __id
    end)

    if not s then
        return nil, nil
    end

    return e -- e is actually two return values if successful
end

-- Inicia um loop persistente que reaplica a descrição enquanto o flag estiver ativo
local function __start_persistent_reapply(character, desc)
    if not character or not desc then return end
    local charKey = character
    -- Se já existe tarefa persistente para esse char, não crie outra
    if __persistent_tasks[charKey] then return end

    local stop = false
    __persistent_tasks[charKey] = {
        stop = function() stop = true end
    }

    spawn(function()
        -- procura humanoid (pode demorar)
        local hum = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
        if not hum then
            __persistent_tasks[charKey] = nil
            return
        end

        -- Se o humanoid for substituído, reativa a tentativa (escuta Humanoid.AncestryChanged/Humanoid.Changed)
        local conn
        conn = hum:GetPropertyChangedSignal("Parent"):Connect(function()
            if not hum.Parent then
                -- humanoid removido, finaliza e espera novo humanoid
                if conn then conn:Disconnect() end
            end
        end)

        -- Loop principal: tenta forçar, depois reaplica periodicamente
        while not stop and character.Parent do
            -- aplica brutalmente uma vez
            pcall(function()
                __force_apply_brutal(hum, desc)
            end)

            -- checa se aplicado corretamente
            local applied = nil
            pcall(function() applied = hum:GetAppliedDescription() end)
            if applied and __descriptions_match(applied, desc) then
                -- boa aplicação; aguarda mais tempo antes de verificar novamente
                for i = 1, 40 do
                    if stop or not character.Parent then break end
                    task.wait(0.25)
                end
            else
                -- não aplicou corretamente -> aumentar frequência de tentativas
                for i = 1, 20 do
                    if stop or not character.Parent then break end
                    pcall(function()
                        hum:ApplyDescriptionClientServer(desc)
                    end)
                    task.wait(0.1)
                    pcall(function() applied = hum:GetAppliedDescription() end)
                    if applied and __descriptions_match(applied, desc) then break end
                end
            end

            -- Se humanoid foi destruído e substituído, atualiza referência
            if not hum.Parent or not hum.Parent:IsDescendantOf(game) then
                hum = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
            end
        end

        -- cleanup
        if conn then pcall(function() conn:Disconnect() end) end
        __persistent_tasks[charKey] = nil
    end)
end

local function __stop_all_persistent()
    for k,v in pairs(__persistent_tasks) do
        if v and type(v.stop) == "function" then
            pcall(v.stop)
        end
        __persistent_tasks[k] = nil
    end
end

local function __set(__name, __char)
    if not __name or __name == '' then
        return
    end

    local __hum = __char and __char:WaitForChild('Humanoid', 5)

    if not __hum then
        return
    end

    local success, __desc, __id = pcall(function()
        local id = __players:GetUserIdFromNameAsync(__name)
        local desc = __players:GetHumanoidDescriptionFromUserId(id)
        return desc, id
    end)

    if not success or not __desc then
        warn("Failed to get appearance for: " .. tostring(__name))
        return
    end

    -- Guarda alvo atual
    __currentDesc = __desc
    __targetUserId = __id

    -- LIMPA TUDO localmente (mantendo seu comportamento)
    pcall(function()
        __localplayer:ClearCharacterAppearance()
        __hum.Description = Instance.new("HumanoidDescription")
    end)

    task.wait(0.05)

    -- APLICAÇÃO IMPOSSÍVEL DE FALHAR (tentativa imediata e depois persistente)
    pcall(function()
        __force_apply_brutal(__hum, __desc)
    end)

    -- Inicia reaplicação persistente para cobrir respawn/humanoid reset/substituição
    __start_persistent_reapply(__char, __desc)
end

local VisualTab = Window:Tab({ 
    Title = "Emotes", 
    Icon = "solar:emoji-funny-bold", 
    IconColor = Color3.fromHex("#ECA201") })

local AvatarChangerSection = VisualTab:Section({
    Title = "Avatar Changer",
})

AvatarChangerSection:Toggle({
    Title = "Avatar Changer",
    Default = false,
    Callback = function(val)
        __flags['Skin Changer'] = val

        if val then
            local __char = __localplayer.Character

            if __char and __flags['name'] then
                __set(__flags['name'], __char)
            end

            -- Conectar CharacterAdded para reaplicar sempre no spawn/respawn
            __flags['loop'] = __localplayer.CharacterAdded:Connect(function(char)
                task.wait(0.05)
                if __flags['name'] then
                    __set(__flags['name'], char)
                end
            end)
        else
            -- Desligando: desconectar e tentar restaurar skin local
            if __flags['loop'] then
                __flags['loop']:Disconnect()
                __flags['loop'] = nil

                -- Para tarefas persistentes
                __stop_all_persistent()

                local __char = __localplayer.Character

                if __char then
                    -- Restaura a aparência original do próprio jogador
                    pcall(function()
                        __localplayer:ClearCharacterAppearance()
                        -- tenta reaplicar descrição padrão do usuário
                        local ok, desc = pcall(function()
                            return __players:GetHumanoidDescriptionFromUserId(__localplayer.UserId)
                        end)
                        if ok and desc then
                            local hum = __char:FindFirstChildOfClass("Humanoid") or __char:WaitForChild("Humanoid", 3)
                            if hum then
                                hum:ApplyDescriptionClientServer(desc)
                            end
                        end
                    end)
                end
            end
        end
    end
})

AvatarChangerSection:Input({
    Title = "Username",
    Desc = "Put the username of the avatar you want to change to.",
    Placeholder = "Enter Username...",
    InputIcon = "user",
    Type = "Input",                       
    Callback = function(val: string)
        __flags['name'] = val

        if __flags['Skin Changer'] and val ~= '' then
            local __char = __localplayer.Character
            if __char then
                __set(val, __char)
            end
        end
    end
})

local function create_animation(object, info, value)
    local animation = game:GetService('TweenService'):Create(object, info, value)
    animation:Play()
    task.wait(info.Time)
    animation:Destroy()
end

local animation_system = {
    storage = {},
    current = nil,
    track = nil
}

function animation_system.load_animations()
    local emotes_folder = game:GetService("ReplicatedStorage").Misc.Emotes
    
    for _, animation in pairs(emotes_folder:GetChildren()) do
        if animation:IsA("Animation") and animation:GetAttribute("EmoteName") then
            local emote_name = animation:GetAttribute("EmoteName")
            animation_system.storage[emote_name] = animation
        end
    end
end

function animation_system.get_emotes_list()
    local emotes_list = {}
    
    for emote_name in pairs(animation_system.storage) do
        table.insert(emotes_list, emote_name)
    end
    
    table.sort(emotes_list)
    return emotes_list
end

function animation_system.play(emote_name)
    local animation_data = animation_system.storage[emote_name]
    
    if not animation_data or not LocalPlayer.Character then
        return false
    end
    
    local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not humanoid then
        return false
    end
    
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then
        return false
    end
    
    if animation_system.track then
        animation_system.track:Stop()
        animation_system.track:Destroy()
    end
    
    animation_system.track = animator:LoadAnimation(animation_data)
    animation_system.track:Play()
    animation_system.current = emote_name
    
    return true
end

function animation_system.stop()
    if animation_system.track then
        animation_system.track:Stop()
        animation_system.track:Destroy()
        animation_system.track = nil
    end
    animation_system.current = nil
end

function animation_system.start()
    if not System.__properties.__connections.animations then
        System.__properties.__connections.animations = RunService.Heartbeat:Connect(function()
            if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then
                return
            end
            
            local speed = LocalPlayer.Character.PrimaryPart.AssemblyLinearVelocity.Magnitude
            
            if speed > 30 and getgenv().AutoStop then
                if animation_system.track and animation_system.track.IsPlaying then
                    animation_system.track:Stop()
                end
            else
                if animation_system.current and (not animation_system.track or not animation_system.track.IsPlaying) then
                    animation_system.play(animation_system.current)
                end
            end
        end)
    end
end

function animation_system.cleanup()
    animation_system.stop()
    
    if System.__properties.__connections.animations then
        System.__properties.__connections.animations:Disconnect()
        System.__properties.__connections.animations = nil
    end
end

animation_system.load_animations()
local emotes_data = animation_system.get_emotes_list()
local selected_animation = emotes_data[1]

local EmotesSection = VisualTab:Section({
    Title = "Emotes",
})

EmotesSection:Toggle({
    Title = "Emotes",
    Default = false,
    Callback = function(value)
        getgenv().Animations = value
        
        if value then
            animation_system.start()
            
            if selected_animation then
                animation_system.play(selected_animation)
            end
        else
            animation_system.cleanup()
        end
    end
})

EmotesSection:Toggle({
    Title = "Auto Stop",
    Default = true,
    Callback = function(value)
        getgenv().AutoStop = value
    end
})

local animation_dropdown = EmotesSection:Dropdown({
    Title = "Emote Type",
    Values = emotes_data,
    Default = "None",
    Callback = function(value)
        selected_animation = value
        
        if getgenv().Animations then
            animation_system.play(value)
        end
    end
})

animation_dropdown:Select(selected_animation)

local ability_esp = {
    __config = {
        gui_name = "AbilityESPGui",
        gui_size = UDim2.new(0, 200, 0, 40),
        studs_offset = Vector3.new(0, 3.2, 0),
        text_color = Color3.fromRGB(255, 255, 255),
        stroke_color = Color3.fromRGB(0, 0, 0),
        font = Enum.Font.GothamBold,
        text_size = 14,
        update_rate = 1/30
    },
    
    __state = {
        active = false,
        players = {},
        update_task = nil
    }
}

function ability_esp.create_billboard(player)
    local character = player.Character
    if not character or not character.Parent then 
        return nil
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return nil
    end
    
    local head = character:FindFirstChild("Head")
    if not head then
        return nil
    end
    
    local existing = head:FindFirstChild(ability_esp.__config.gui_name)
    if existing then
        existing:Destroy()
    end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = ability_esp.__config.gui_name
    billboard.Adornee = head
    billboard.Size = ability_esp.__config.gui_size
    billboard.StudsOffset = ability_esp.__config.studs_offset
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = ability_esp.__config.text_color
    label.TextStrokeColor3 = ability_esp.__config.stroke_color
    label.TextStrokeTransparency = 0.5
    label.Font = ability_esp.__config.font
    label.TextSize = ability_esp.__config.text_size
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = billboard
    
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    
    return label, billboard
end

function ability_esp.update_label(player, label)
    if not player or not player.Parent or not label or not label.Parent then
        return false
    end
    
    local character = player.Character
    if not character or not character.Parent or not character:FindFirstChild("Humanoid") then
        return false
    end
    
    if ability_esp.__state.active then
        label.Visible = true
        local ability_name = player:GetAttribute("EquippedAbility")
        label.Text = ability_name and 
            (player.DisplayName .. "  [" .. ability_name .. "]") or 
            player.DisplayName
    else
        label.Visible = false
    end
    
    return true
end

function ability_esp.setup_character(player)
    if not ability_esp.__state.active then
        return
    end
    
    task.wait(0.1)
    
    local character = player.Character
    if not character or not character.Parent or not character:FindFirstChild("Humanoid") then
        return
    end
    
    local label, billboard = ability_esp.create_billboard(player)
    if not label then
        return
    end
    
    if not ability_esp.__state.players[player] then
        ability_esp.__state.players[player] = {}
    end
    
    ability_esp.__state.players[player].label = label
    ability_esp.__state.players[player].billboard = billboard
    ability_esp.__state.players[player].character = character
    
    local char_connection = character.AncestryChanged:Connect(function()
        if not character.Parent then
            if ability_esp.__state.players[player] then
                if ability_esp.__state.players[player].billboard then
                    ability_esp.__state.players[player].billboard:Destroy()
                end
                ability_esp.__state.players[player].label = nil
                ability_esp.__state.players[player].billboard = nil
                ability_esp.__state.players[player].character = nil
            end
        end
    end)
    
    if not System.__properties.__connections.ability_esp then
        System.__properties.__connections.ability_esp = {}
    end
    
    if not System.__properties.__connections.ability_esp[player] then
        System.__properties.__connections.ability_esp[player] = {}
    end
    
    System.__properties.__connections.ability_esp[player].char_removing = char_connection
end

function ability_esp.add_player(player)
    if player == LocalPlayer then
        return
    end
    
    if ability_esp.__state.players[player] then
        ability_esp.remove_player(player)
    end
    
    if not System.__properties.__connections.ability_esp then
        System.__properties.__connections.ability_esp = {}
    end
    
    if not System.__properties.__connections.ability_esp[player] then
        System.__properties.__connections.ability_esp[player] = {}
    end
    
    local char_added_connection = player.CharacterAdded:Connect(function()
        ability_esp.setup_character(player)
    end)
    
    System.__properties.__connections.ability_esp[player].char_added = char_added_connection
    
    if player.Character then
        task.spawn(function()
            ability_esp.setup_character(player)
        end)
    end
end

function ability_esp.remove_player(player)
    if System.__properties.__connections.ability_esp and System.__properties.__connections.ability_esp[player] then
        for _, connection in pairs(System.__properties.__connections.ability_esp[player]) do
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end
        System.__properties.__connections.ability_esp[player] = nil
    end
    
    local player_data = ability_esp.__state.players[player]
    if player_data then
        if player_data.billboard then
            player_data.billboard:Destroy()
        end
        ability_esp.__state.players[player] = nil
    end
end

function ability_esp.update_loop()
    while ability_esp.__state.active do
        task.wait(ability_esp.__config.update_rate)
        
        local players_to_remove = {}
        
        for player, player_data in pairs(ability_esp.__state.players) do
            if not player or not player.Parent then
                table.insert(players_to_remove, player)
                continue
            end
            
            local character = player.Character
            if not character or not character.Parent or not character:FindFirstChild("Humanoid") then
                if player_data.billboard then
                    player_data.billboard:Destroy()
                    player_data.billboard = nil
                    player_data.label = nil
                end
                continue
            end
            
            if not player_data.billboard or not player_data.label then
                local label, billboard = ability_esp.create_billboard(player)
                if label then
                    player_data.label = label
                    player_data.billboard = billboard
                    player_data.character = character
                end
            end
            
            if player_data.label then
                local success = ability_esp.update_label(player, player_data.label)
                if not success then
                    local label, billboard = ability_esp.create_billboard(player)
                    if label then
                        player_data.label = label
                        player_data.billboard = billboard
                        player_data.character = character
                    end
                end
            end
        end
        
        for _, player in ipairs(players_to_remove) do
            if ability_esp.__state.players[player] then
                if ability_esp.__state.players[player].billboard then
                    ability_esp.__state.players[player].billboard:Destroy()
                end
                ability_esp.__state.players[player] = nil
            end
        end
    end
end

function ability_esp.start()
    if ability_esp.__state.active then
        return
    end
    
    ability_esp.__state.active = true
    getgenv().AbilityESP = true
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ability_esp.add_player(player)
        end
    end
    
    if not System.__properties.__connections.ability_esp then
        System.__properties.__connections.ability_esp = {}
    end
    
    System.__properties.__connections.ability_esp.player_added = Players.PlayerAdded:Connect(function(player)
        if ability_esp.__state.active and player ~= LocalPlayer then
            task.wait(1)
            ability_esp.add_player(player)
        end
    end)
    
    ability_esp.__state.update_task = task.spawn(function()
        ability_esp.update_loop()
    end)
end

function ability_esp.stop()
    if not ability_esp.__state.active then
        return
    end
    
    ability_esp.__state.active = false
    getgenv().AbilityESP = false
    
    if ability_esp.__state.update_task then
        task.cancel(ability_esp.__state.update_task)
        ability_esp.__state.update_task = nil
    end
    
    if System.__properties.__connections.ability_esp then
        for player, connections in pairs(System.__properties.__connections.ability_esp) do
            if type(connections) == "table" then
                for _, connection in pairs(connections) do
                    if connection and connection.Connected then
                        connection:Disconnect()
                    end
                end
            elseif connections and connections.Connected then
                connections:Disconnect()
            end
        end
        
        System.__properties.__connections.ability_esp = nil
    end
    
    for player in pairs(ability_esp.__state.players) do
        ability_esp.remove_player(player)
    end
end

function ability_esp.toggle(value)
    if value then
        ability_esp.start()
    else
        ability_esp.stop()
    end
end

local OtherVisualsSection = VisualTab:Section({ 
    Title = "Other Visuals" 
})

local ability_esp = {
    __config = {
        gui_name = "AbilityESPGui",
        gui_size = UDim2.new(0, 200, 0, 40),
        studs_offset = Vector3.new(0, 3.2, 0),
        text_color = Color3.fromRGB(255, 255, 255),
        stroke_color = Color3.fromRGB(0, 0, 0),
        font = Enum.Font.GothamBold,
        text_size = 14,
        update_rate = 1/30
    },
    
    __state = {
        active = false,
        players = {},
        update_task = nil
    }
}

function ability_esp.create_billboard(player)
    local character = player.Character
    if not character or not character.Parent then 
        return nil
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return nil
    end
    
    local head = character:FindFirstChild("Head")
    if not head then
        return nil
    end
    
    local existing = head:FindFirstChild(ability_esp.__config.gui_name)
    if existing then
        existing:Destroy()
    end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = ability_esp.__config.gui_name
    billboard.Adornee = head
    billboard.Size = ability_esp.__config.gui_size
    billboard.StudsOffset = ability_esp.__config.studs_offset
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = ability_esp.__config.text_color
    label.TextStrokeColor3 = ability_esp.__config.stroke_color
    label.TextStrokeTransparency = 0.5
    label.Font = ability_esp.__config.font
    label.TextSize = ability_esp.__config.text_size
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = billboard
    
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    
    return label, billboard
end

function ability_esp.update_label(player, label)
    if not player or not player.Parent or not label or not label.Parent then
        return false
    end
    
    local character = player.Character
    if not character or not character.Parent or not character:FindFirstChild("Humanoid") then
        return false
    end
    
    if ability_esp.__state.active then
        label.Visible = true
        local ability_name = player:GetAttribute("EquippedAbility")
        label.Text = ability_name and 
            (player.DisplayName .. "  [" .. ability_name .. "]") or 
            player.DisplayName
    else
        label.Visible = false
    end
    
    return true
end

function ability_esp.setup_character(player)
    if not ability_esp.__state.active then
        return
    end
    
    task.wait(0.1)
    
    local character = player.Character
    if not character or not character.Parent or not character:FindFirstChild("Humanoid") then
        return
    end
    
    local label, billboard = ability_esp.create_billboard(player)
    if not label then
        return
    end
    
    if not ability_esp.__state.players[player] then
        ability_esp.__state.players[player] = {}
    end
    
    ability_esp.__state.players[player].label = label
    ability_esp.__state.players[player].billboard = billboard
    ability_esp.__state.players[player].character = character
    
    local char_connection = character.AncestryChanged:Connect(function()
        if not character.Parent then
            if ability_esp.__state.players[player] then
                if ability_esp.__state.players[player].billboard then
                    ability_esp.__state.players[player].billboard:Destroy()
                end
                ability_esp.__state.players[player].label = nil
                ability_esp.__state.players[player].billboard = nil
                ability_esp.__state.players[player].character = nil
            end
        end
    end)
    
    if not System.__properties.__connections.ability_esp then
        System.__properties.__connections.ability_esp = {}
    end
    
    if not System.__properties.__connections.ability_esp[player] then
        System.__properties.__connections.ability_esp[player] = {}
    end
    
    System.__properties.__connections.ability_esp[player].char_removing = char_connection
end

function ability_esp.add_player(player)
    if player == LocalPlayer then
        return
    end
    
    if ability_esp.__state.players[player] then
        ability_esp.remove_player(player)
    end
    
    if not System.__properties.__connections.ability_esp then
        System.__properties.__connections.ability_esp = {}
    end
    
    if not System.__properties.__connections.ability_esp[player] then
        System.__properties.__connections.ability_esp[player] = {}
    end
    
    local char_added_connection = player.CharacterAdded:Connect(function()
        ability_esp.setup_character(player)
    end)
    
    System.__properties.__connections.ability_esp[player].char_added = char_added_connection
    
    if player.Character then
        task.spawn(function()
            ability_esp.setup_character(player)
        end)
    end
end

function ability_esp.remove_player(player)
    if System.__properties.__connections.ability_esp and System.__properties.__connections.ability_esp[player] then
        for _, connection in pairs(System.__properties.__connections.ability_esp[player]) do
            if connection and connection.Connected then
                connection:Disconnect()
            end
        end
        System.__properties.__connections.ability_esp[player] = nil
    end
    
    local player_data = ability_esp.__state.players[player]
    if player_data then
        if player_data.billboard then
            player_data.billboard:Destroy()
        end
        ability_esp.__state.players[player] = nil
    end
end

function ability_esp.update_loop()
    while ability_esp.__state.active do
        task.wait(ability_esp.__config.update_rate)
        
        local players_to_remove = {}
        
        for player, player_data in pairs(ability_esp.__state.players) do
            if not player or not player.Parent then
                table.insert(players_to_remove, player)
                continue
            end
            
            local character = player.Character
            if not character or not character.Parent or not character:FindFirstChild("Humanoid") then
                if player_data.billboard then
                    player_data.billboard:Destroy()
                    player_data.billboard = nil
                    player_data.label = nil
                end
                continue
            end
            
            if not player_data.billboard or not player_data.label then
                local label, billboard = ability_esp.create_billboard(player)
                if label then
                    player_data.label = label
                    player_data.billboard = billboard
                    player_data.character = character
                end
            end
            
            if player_data.label then
                local success = ability_esp.update_label(player, player_data.label)
                if not success then
                    local label, billboard = ability_esp.create_billboard(player)
                    if label then
                        player_data.label = label
                        player_data.billboard = billboard
                        player_data.character = character
                    end
                end
            end
        end
        
        for _, player in ipairs(players_to_remove) do
            if ability_esp.__state.players[player] then
                if ability_esp.__state.players[player].billboard then
                    ability_esp.__state.players[player].billboard:Destroy()
                end
                ability_esp.__state.players[player] = nil
            end
        end
    end
end

function ability_esp.start()
    if ability_esp.__state.active then
        return
    end
    
    ability_esp.__state.active = true
    getgenv().AbilityESP = true
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ability_esp.add_player(player)
        end
    end
    
    if not System.__properties.__connections.ability_esp then
        System.__properties.__connections.ability_esp = {}
    end
    
    System.__properties.__connections.ability_esp.player_added = Players.PlayerAdded:Connect(function(player)
        if ability_esp.__state.active and player ~= LocalPlayer then
            task.wait(1)
            ability_esp.add_player(player)
        end
    end)
    
    ability_esp.__state.update_task = task.spawn(function()
        ability_esp.update_loop()
    end)
end

function ability_esp.stop()
    if not ability_esp.__state.active then
        return
    end
    
    ability_esp.__state.active = false
    getgenv().AbilityESP = false
    
    if ability_esp.__state.update_task then
        task.cancel(ability_esp.__state.update_task)
        ability_esp.__state.update_task = nil
    end
    
    if System.__properties.__connections.ability_esp then
        for player, connections in pairs(System.__properties.__connections.ability_esp) do
            if type(connections) == "table" then
                for _, connection in pairs(connections) do
                    if connection and connection.Connected then
                        connection:Disconnect()
                    end
                end
            elseif connections and connections.Connected then
                connections:Disconnect()
            end
        end
        
        System.__properties.__connections.ability_esp = nil
    end
    
    for player in pairs(ability_esp.__state.players) do
        ability_esp.remove_player(player)
    end
end

function ability_esp.toggle(value)
    if value then
        ability_esp.start()
    else
        ability_esp.stop()
    end
end

OtherVisualsSection:Toggle({
    Title = "Ability ESP",
    Default = false,
    Callback = function(value)
        ability_esp.toggle(value)
    end
})

local Connections_Manager = {}

local No_Render = OtherVisualsSection:Toggle({
    Title = "No Render",
    Default = false,
    Callback = function(state)
        LocalPlayer.PlayerScripts.EffectScripts.ClientFX.Disabled = state

        if state then
            Connections_Manager['No Render'] = workspace.Runtime.ChildAdded:Connect(function(Value)
                Debris:AddItem(Value, 0)   -- Debris est probablement game:GetService("Debris")
            end)
        else
            if Connections_Manager['No Render'] then
                Connections_Manager['No Render']:Disconnect()
                Connections_Manager['No Render'] = nil
            end
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
    if tostring(args[4]) ~= LocalPlayer.Name then
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

local SkinChangerSection = VisualTab:Section({
    Title = "Skin Changer"
})

SkinChangerSection:Toggle({
    Title = "Skin Changer",
    Default = false,
    Callback = function(value: boolean)
        getgenv().skinChangerEnabled = value
        if value then
            getgenv().updateSword()
        end
    end
})

-- SkinChangerSection est déjà créé avant (ex: local SkinChangerSection = Tab:Section({ Title = "Skin Changer" }))

-- Checkbox + Textbox pour Change Sword Model
SkinChangerSection:Toggle({
    Title = "Change Sword Model",
    Desc = "Active le changement de modèle d'épée",   -- optionnel
    Value = false,                -- état initial (true = coché au démarrage)
    Flag = "ChangeSwordModel",   -- pour le système de config/save
    Callback = function(value: boolean)
        getgenv().changeSwordModel = value
        if getgenv().skinChangerEnabled then
            getgenv().updateSword()
        end
    end
})

SkinChangerSection:Input({
    Title = "Sword Model Name",
    Desc = "Nom du modèle d'épée à utiliser",
    Placeholder = "Enter Sword Model Name...",
    Value = "",                    -- valeur par défaut (vide au départ)
    Flag = "SwordModelTextbox",
    InputIcon = "sword",             -- icône lucide optionnelle (cherche "sword" sur lucide.dev/icons)
    Callback = function(text: string)
        getgenv().swordModel = text
        if getgenv().skinChangerEnabled and getgenv().changeSwordModel then
            getgenv().updateSword()
        end
    end
})

-- Checkbox + Textbox pour Change Sword Animation
SkinChangerSection:Toggle({
    Title = "Change Sword Animation",
    Value = false,
    Flag = "ChangeSwordAnimation",
    Callback = function(value: boolean)
        getgenv().changeSwordAnimation = value
        if getgenv().skinChangerEnabled then
            getgenv().updateSword()
        end
    end
})

SkinChangerSection:Input({
    Title = "Sword Animation Name",
    Desc = "Nom de l'animation personnalisée",
    Placeholder = "Enter Sword Animation Name...",
    Value = "",
    Flag = "SwordAnimationTextbox",
    InputIcon = "play",
    Callback = function(text: string)
        getgenv().swordAnimations = text   -- note : tu avais swordAnimationS (pluriel)
        if getgenv().skinChangerEnabled and getgenv().changeSwordAnimation then
            getgenv().updateSword()
        end
    end
})

-- Checkbox + Textbox pour Change Sword FX
SkinChangerSection:Toggle({
    Title = "Change Sword FX",
    Value = false,
    Flag = "ChangeSwordFX",
    Callback = function(value: boolean)
        getgenv().changeSwordFX = value
        if getgenv().skinChangerEnabled then
            getgenv().updateSword()
        end
    end
})

SkinChangerSection:Input({
    Title = "Sword FX Name",
    Desc = "Nom de l'effet/particule personnalisé",
    Placeholder = "Enter Sword FX Name...",
    Value = "",
    Flag = "SwordFXTextbox",
    InputIcon = "sparkles",
    Callback = function(text: string)
        getgenv().swordFX = text
        if getgenv().skinChangerEnabled and getgenv().changeSwordFX then
            getgenv().updateSword()
        end
    end
})



-- ────────────────────────────────────────────────────────────────
--  PLAYER TAB
-- ────────────────────────────────────────────────────────────────

local PlayerTab = Window:Tab({ 
    Title = "Player",
    Icon = "solar:eye-bold",
    IconColor = Color3.fromHex("#257AF7") 
})

local FOVSection = PlayerTab:Section({ 
    Title = "FOV Changer" 
})

FOVSection:Toggle({
    Title = "FOV",
    Default = false,
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

FOVSection:Slider({
    Title = "Camera FOV",
    Value = { Min = 50, Max = 120, Default = 70 },
    Step = 1,
    Callback = function(value)
        getgenv().CameraFOV = value
        if getgenv().CameraEnabled then
            game:GetService("Workspace").CurrentCamera.FieldOfView = value
        end
    end
})

local CharacterModifierSection = PlayerTab:Section({ 
    Title = "Character Modifier" 
})

CharacterModifierSection:Toggle({
    Title = 'Character Modifier',
    Flag = 'CharacterModifier',
    Description = 'Changes various character properties',
    Callback = function(value)
        getgenv().CharacterModifierEnabled = value

        if value then
            if not getgenv().CharacterConnection then
                getgenv().OriginalValues = {}
                getgenv().spinAngle = 0
                
                getgenv().CharacterConnection = RunService.Heartbeat:Connect(function()
                    local char = LocalPlayer.Character
                    if not char then return end
                    
                    local humanoid = char:FindFirstChild("Humanoid")
                    local root = char:FindFirstChild("HumanoidRootPart")
                    
                    if humanoid then
                        if not getgenv().OriginalValues.WalkSpeed then
                            getgenv().OriginalValues.WalkSpeed = humanoid.WalkSpeed
                            getgenv().OriginalValues.JumpPower = humanoid.JumpPower
                            getgenv().OriginalValues.JumpHeight = humanoid.JumpHeight
                            getgenv().OriginalValues.HipHeight = humanoid.HipHeight
                            getgenv().OriginalValues.AutoRotate = humanoid.AutoRotate
                        end
                        
                        if getgenv().WalkspeedCheckboxEnabled then
                            humanoid.WalkSpeed = getgenv().CustomWalkSpeed or 36
                        end
                        
                        if getgenv().JumpPowerCheckboxEnabled then
                            if humanoid.UseJumpPower then
                                humanoid.JumpPower = getgenv().CustomJumpPower or 50
                            else
                                humanoid.JumpHeight = getgenv().CustomJumpHeight or 7.2
                            end
                        end
                        
                        if getgenv().HipHeightCheckboxEnabled then
                            humanoid.HipHeight = getgenv().CustomHipHeight or 0
                        end

                        if getgenv().SpinbotCheckboxEnabled and root then
                            humanoid.AutoRotate = false
                            getgenv().spinAngle = (getgenv().spinAngle + (getgenv().CustomSpinSpeed or 5)) % 360
                            root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, math.rad(getgenv().spinAngle), 0)
                        else
                            if getgenv().OriginalValues.AutoRotate ~= nil then
                                humanoid.AutoRotate = getgenv().OriginalValues.AutoRotate
                            end
                        end
                    end
                    
                    if getgenv().GravityCheckboxEnabled and getgenv().CustomGravity then
                        workspace.Gravity = getgenv().CustomGravity
                    end
                end)
            end
        else
            if getgenv().CharacterConnection then
                getgenv().CharacterConnection:Disconnect()
                getgenv().CharacterConnection = nil
                
                local char = LocalPlayer.Character
                if char then
                    local humanoid = char:FindFirstChild("Humanoid")
                    
                    if humanoid and getgenv().OriginalValues then
                        humanoid.WalkSpeed = getgenv().OriginalValues.WalkSpeed or 16
                        if humanoid.UseJumpPower then
                            humanoid.JumpPower = getgenv().OriginalValues.JumpPower or 50
                        else
                            humanoid.JumpHeight = getgenv().OriginalValues.JumpHeight or 7.2
                        end
                        humanoid.HipHeight = getgenv().OriginalValues.HipHeight or 0
                        humanoid.AutoRotate = getgenv().OriginalValues.AutoRotate or true
                    end
                end
                
                workspace.Gravity = 196.2
                
                if getgenv().InfiniteJumpConnection then
                    getgenv().InfiniteJumpConnection:Disconnect()
                    getgenv().InfiniteJumpConnection = nil
                end
                
                getgenv().OriginalValues = nil
                getgenv().spinAngle = nil
            end
        end
    end
})

CharacterModifierSection:Toggle({
    Title = "Infinite Jump",
    Default = false,
    Callback = function(value)
        getgenv().InfiniteJumpCheckboxEnabled = value
        
        if value and getgenv().CharacterModifierEnabled then
            if not getgenv().InfiniteJumpConnection then
                getgenv().InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
                    if getgenv().InfiniteJumpCheckboxEnabled and getgenv().CharacterModifierEnabled then
                        local char = LocalPlayer.Character
                        if char and char:FindFirstChild("Humanoid") then
                            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end
                end)
            end
        else
            if getgenv().InfiniteJumpConnection then
                getgenv().InfiniteJumpConnection:Disconnect()
                getgenv().InfiniteJumpConnection = nil
            end
        end
    end
})

CharacterModifierSection:Toggle({
    Title = "Spin",
    Default = false,
    Callback = function(value)
        getgenv().SpinbotCheckboxEnabled = value
        
        if not value and getgenv().CharacterModifierEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and getgenv().OriginalValues then
                char.Humanoid.AutoRotate = getgenv().OriginalValues.AutoRotate or true
            end
        end
    end
})

CharacterModifierSection:Slider({
    Title = "Spin Speed",
    Value = { Min = 1, Max = 50, Default = 5 },
    Step = 1,
    Callback = function(value)
        getgenv().CustomSpinSpeed = value
    end
})

CharacterModifierSection:Toggle({
    Title = "Walk Speed",
    Default = false,
    Callback = function(value)
        getgenv().WalkspeedCheckboxEnabled = value
        
        if not value and getgenv().CharacterModifierEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and getgenv().OriginalValues then
                char.Humanoid.WalkSpeed = getgenv().OriginalValues.WalkSpeed or 16
            end
        end
    end
})

CharacterModifierSection:Slider({
    Title = "Walk Speed Value",
    Value = { Min = 16, Max = 500, Default = 36 },
    Step = 1,
    Callback = function(value)
        getgenv().CustomWalkSpeed = value
        
        if getgenv().CharacterModifierEnabled and getgenv().WalkspeedCheckboxEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = value
            end
        end
    end
})

CharacterModifierSection:Toggle({
    Title = "Jump Power",
    Default = false,
    Callback = function(value)
        getgenv().JumpPowerCheckboxEnabled = value
        
        if not value and getgenv().CharacterModifierEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and getgenv().OriginalValues then
                local humanoid = char.Humanoid
                if humanoid.UseJumpPower then
                    humanoid.JumpPower = getgenv().OriginalValues.JumpPower or 50
                else
                    humanoid.JumpHeight = getgenv().OriginalValues.JumpHeight or 7.2
                end
            end
        end
    end
})

CharacterModifierSection:Slider({
    Title = "Jump Power Value",
    Value = { Min = 50, Max = 200, Default = 50 },
    Step = 1,
    Callback = function(value)
        getgenv().CustomJumpPower = value
        getgenv().CustomJumpHeight = value * 0.144
        
        if getgenv().CharacterModifierEnabled and getgenv().JumpPowerCheckboxEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                local humanoid = char.Humanoid
                if humanoid.UseJumpPower then
                    humanoid.JumpPower = value
                else
                    humanoid.JumpHeight = value * 0.144
                end
            end
        end
    end
})

CharacterModifierSection:Toggle({
    Title = "Gravity",
    Default = false,
    Callback = function(value)
        getgenv().GravityCheckboxEnabled = value
        
        if not value and getgenv().CharacterModifierEnabled then
            workspace.Gravity = 196.2
        end
    end
})

CharacterModifierSection:Slider({
    Title = "Gravity Value",
    Value = { Min = 0, Max = 400, Default = 196.2 },
    Step = 0.2,
    Callback = function(value)
        getgenv().CustomGravity = value
        
        if getgenv().CharacterModifierEnabled and getgenv().GravityCheckboxEnabled then
            workspace.Gravity = value
        end
    end
})

CharacterModifierSection:Toggle({
    Title = "Hip Height",
    Default = false,
    Callback = function(value)
        getgenv().HipHeightCheckboxEnabled = value
        
        if not value and getgenv().CharacterModifierEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and getgenv().OriginalValues then
                char.Humanoid.HipHeight = getgenv().OriginalValues.HipHeight or 0
            end
        end
    end
})

CharacterModifierSection:Slider({
    Title = "Hip Height Value",
    Value = { Min = -5, Max = 20, Default = 0 },
    Step = 0.1,
    Callback = function(value)
        getgenv().CustomHipHeight = value
        
        if getgenv().CharacterModifierEnabled and getgenv().HipHeightCheckboxEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.HipHeight = value
            end
        end
    end
})

-- ────────────────────────────────────────────────────────────────
--  AUTOFARM TAB
-- ────────────────────────────────────────────────────────────────

local AutoFarmTab = Window:Tab({ 
    Title = "Auto Farm", 
    Icon = "solar:eye-bold", 
    IconColor = Color3.fromHex("#257AF7") 
})

local WKISection = AutoFarmTab:Section({ 
    Title = "Walkable Semi-Immortal" 
})

local WalkableSemiImmortal = {}

local state = {
    enabled = false,
    notify = false,
    heartbeatConnection = nil
}

local desyncData = {
    originalCFrame = nil,
    originalVelocity = nil
}

local cache = {
    character = nil,
    hrp = nil,
    head = nil,
    headOffset = Vector3.new(0, 0, 0),
    aliveFolder = nil
}

local hooks = {
    oldIndex = nil
}

local constants = {
    emptyCFrame = CFrame.new(),
    radius = 25,
    baseHeight = 5,
    riseHeight = 30,
    cycleSpeed = 11.9,
    velocity = Vector3.new(1, 1, 1)
}

local function updateCache()
    local character = LocalPlayer.Character
    if character ~= cache.character then
        cache.character = character
        if character then
            cache.hrp = character.HumanoidRootPart
            cache.head = character.Head
            cache.aliveFolder = workspace.Alive
            if cache.hrp then
                cache.headOffset = Vector3.new(0, cache.hrp.Size.Y * 0.5 + 0.5, 0)
            end
        else
            cache.hrp = nil
            cache.head = nil
        end
    end
end

local function isInAliveFolder()
    return cache.aliveFolder and cache.character and cache.character.Parent == cache.aliveFolder
end

local function calculateOrbitPosition(hrp)
    local angle = math.random(-2147483647, 2147483647) * 1000
    local cycle = math.floor(tick() * constants.cycleSpeed) % 2
    local yOffset = cycle == 0 and 0 or constants.riseHeight
    
    local pos = hrp.Position
    local yBase = pos.Y - hrp.Size.Y * 0.5 + constants.baseHeight + yOffset
    
    return CFrame.new(
        pos.X + math.cos(angle) * constants.radius,
        yBase,
        pos.Z + math.sin(angle) * constants.radius
    )
end

local function performDesync()
    updateCache()
    
    if not state.enabled or not cache.hrp or not isInAliveFolder() then
        return
    end
    
    local hrp = cache.hrp
    desyncData.originalCFrame = hrp.CFrame
    desyncData.originalVelocity = hrp.AssemblyLinearVelocity
    
    hrp.CFrame = calculateOrbitPosition(hrp)
    hrp.AssemblyLinearVelocity = constants.velocity
    
    RunService.RenderStepped:Wait()
    
    hrp.CFrame = desyncData.originalCFrame
    hrp.AssemblyLinearVelocity = desyncData.originalVelocity
end

local function sendNotification(text)
    if state.notify and Library then
        Library.SendNotification({
            title = "Walkable Semi-Immortal",
            text = text
        })
    end
end

function WalkableSemiImmortal.toggle(enabled)
    if state.enabled == enabled then return end
    
    state.enabled = enabled
    getgenv().Walkablesemiimortal = enabled
    
    if enabled then
        if not state.heartbeatConnection then
            state.heartbeatConnection = RunService.Heartbeat:Connect(performDesync)
        end
    else
        if state.heartbeatConnection then
            state.heartbeatConnection:Disconnect()
            state.heartbeatConnection = nil
        end
        desyncData.originalCFrame = nil
        desyncData.originalVelocity = nil
    end
    
    sendNotification(enabled and "ON" or "OFF")
end

function WalkableSemiImmortal.setNotify(enabled)
    state.notify = enabled
    getgenv().WalkablesemiimortalNotify = enabled
end

function WalkableSemiImmortal.setRadius(value)
    constants.radius = value
end

function WalkableSemiImmortal.setHeight(value)
    constants.riseHeight = value
end

LocalPlayer.CharacterRemoving:Connect(function()
    cache.character = nil
    cache.hrp = nil
    cache.head = nil
    cache.aliveFolder = nil
end)

hooks.oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if not state.enabled or checkcaller() or key ~= "CFrame" or not cache.hrp or not isInAliveFolder() then
        return hooks.oldIndex(self, key)
    end
    
    if self == cache.hrp then
        return desyncData.originalCFrame or constants.emptyCFrame
    elseif self == cache.head and desyncData.originalCFrame then
        return desyncData.originalCFrame + cache.headOffset
    end
    
    return hooks.oldIndex(self, key)
end))

WKISection:Toggle({
    Title = "Walkable Semi-Immortal",
    Default = false,
    Callback = WalkableSemiImmortal.toggle
})

WKISection:Toggle({
    Title = "Notify",
    Flag = "WalkableSemi_Imortal_Notify",
    Callback = WalkableSemiImmortal.setNotify
})

WKISection:Slider({
    Title = "Immortal Radius",
    Value = { Min = 0, Max = 100, Default = 25 },
    Step = 1,
    Callback = WalkableSemiImmortal.setRadius
})

WKISection:Slider({
    Title = "Immortal Height",
    Value = { Min = 0, Max = 60, Default = 30 },
    Step = 1,
    Callback = WalkableSemiImmortal.setHeight
})



local AISection = AutoFarmTab:Section({ 
    Title = "AI Play (Experimental)" 
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
    GENERATION_THRESHOLD = 0.25,
    PLAYER_DISTANCE_ENABLED = false,
    MINIMUM_PLAYER_DISTANCE = 15,

    UPDATE_FREQUENCY = 6,
    POSITION_UPDATE_RATE = 0.1,
    BALL_CHECK_RATE = 0.2,
    PLAYER_CHECK_RATE = 0.5
}

AutoPlayModule.ball = nil
AutoPlayModule.lobbyChoice = nil
AutoPlayModule.animationCache = nil
AutoPlayModule.doubleJumped = false
AutoPlayModule.ELAPSED = 0
AutoPlayModule.CONTROL_POINT = nil
AutoPlayModule.LAST_GENERATION = 0
AutoPlayModule.signals = {}
AutoPlayModule.Closest_Entity = nil
AutoPlayModule.frameThrottle = 0

local timeCache = {
    lastPositionUpdate = 0,
    lastBallCheck = 0,
    lastPlayerCheck = 0,
    lastFloorCheck = 0
}

local resultCache = {
    floor = nil,
    lastBallDirection = nil,
    lastPlayerPosition = nil,
    lastRandomPosition = nil,
    ballSpeed = 0
}

local serviceCache = {}
local function getService(name)
    if not serviceCache[name] then
        serviceCache[name] = cloneref and cloneref(game:GetService(name)) or game:GetService(name)
    end
    return serviceCache[name]
end

do
    local getServiceFunction = game.GetService
    
    local function getClonerefPermission()
        local permission = cloneref(getServiceFunction(game, "ReplicatedFirst"))
        return permission
    end
    
    AutoPlayModule.clonerefPermission = getClonerefPermission()
    
    if not AutoPlayModule.clonerefPermission then
        warn("cloneref is not available on your executor!")
    end
    
    function AutoPlayModule.findCachedService(self, name)
        for index, value in pairs(self) do
            if value and value.Name == name then
                return value
            end
        end
        return nil
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
        if not player or not player:IsA("Player") then
            return false
        end
        
        local character = player.Character
        if not character then
            return false
        end
    
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
    
        return rootPart and humanoid and humanoid.Health > 0
    end,
    
    inLobby = function(character)
        return character and character.Parent == AutoPlayModule.customService.Workspace.Dead
    end,
    
    onGround = function(character)
        return character and character.Humanoid.FloorMaterial ~= Enum.Material.Air
    end
}

AutoPlayModule.playerProximity = {
    findClosestPlayer = function()
        local currentTime = tick()
        if currentTime - timeCache.lastPlayerCheck < AutoPlayModule.CONFIG.PLAYER_CHECK_RATE then
            return AutoPlayModule.Closest_Entity
        end
        timeCache.lastPlayerCheck = currentTime
        
        local localPlayer = AutoPlayModule.customService.Players.LocalPlayer
        
        if not AutoPlayModule.playerHelper.isAlive(localPlayer) then
            AutoPlayModule.Closest_Entity = nil
            return nil
        end

        local maxDistance = math.huge
        local foundEntity = nil
        local localPosition = localPlayer.Character.HumanoidRootPart.Position

        local aliveFolder = AutoPlayModule.customService.Workspace:FindFirstChild("Alive")
        local searchFolders = aliveFolder and {aliveFolder} or {}

        if not aliveFolder then
            for _, player in pairs(AutoPlayModule.customService.Players:GetPlayers()) do
                if player ~= localPlayer and player.Character then
                    table.insert(searchFolders, player.Character.Parent)
                end
            end
        end
        
        for _, folder in pairs(searchFolders) do
            if folder then
                for _, entity in pairs(folder:GetChildren()) do
                    if entity ~= localPlayer.Character then
                        local primaryPart = entity:FindFirstChild("HumanoidRootPart")
                        
                        if primaryPart then
                            local distance = (localPosition - primaryPart.Position).Magnitude
                            
                            if distance < maxDistance then
                                maxDistance = distance
                                foundEntity = entity
                            end
                        end
                    end
                end
            end
        end
        
        AutoPlayModule.Closest_Entity = foundEntity
        return foundEntity
    end,
    
    getEntityProperties = function()
        local closestPlayer = AutoPlayModule.playerProximity.findClosestPlayer()
        local localPlayer = AutoPlayModule.customService.Players.LocalPlayer
        
        if not closestPlayer or not localPlayer.Character or not localPlayer.Character.HumanoidRootPart then
            return false
        end
        
        local primaryPart = closestPlayer:FindFirstChild("HumanoidRootPart")
        if not primaryPart then
            return false
        end
        
        local localPosition = localPlayer.Character.HumanoidRootPart.Position
        local entityPosition = primaryPart.Position
        local entityDirection = (localPosition - entityPosition).Unit
        local entityDistance = (localPosition - entityPosition).Magnitude
        
        return {
            Velocity = primaryPart.Velocity,
            Direction = entityDirection,
            Distance = entityDistance,
            Position = entityPosition
        }
    end,
    
    isPlayerTooClose = function()
        if not AutoPlayModule.CONFIG.PLAYER_DISTANCE_ENABLED then
            return false
        end
        
        local entityProps = AutoPlayModule.playerProximity.getEntityProperties()
        return entityProps and entityProps.Distance < AutoPlayModule.CONFIG.MINIMUM_PLAYER_DISTANCE
    end,
    
    getAvoidancePosition = function()
        local entityProps = AutoPlayModule.playerProximity.getEntityProperties()
        local localPlayer = AutoPlayModule.customService.Players.LocalPlayer
        
        if not entityProps or not localPlayer.Character or not localPlayer.Character.HumanoidRootPart then
            return nil
        end
        
        local playerPosition = localPlayer.Character.HumanoidRootPart.Position
        local avoidanceDirection = entityProps.Direction * AutoPlayModule.CONFIG.MINIMUM_PLAYER_DISTANCE * 1.5
        local avoidancePosition = playerPosition + avoidanceDirection

        local floor = AutoPlayModule.map.getFloor()
        if floor then
            avoidancePosition = Vector3.new(avoidancePosition.X, floor.Position.Y + 5, avoidancePosition.Z)
        end
        
        return avoidancePosition
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

    local percentage = math.random(1, 100)
    AutoPlayModule.LAST_GENERATION = tick()

    return limit >= percentage
end

AutoPlayModule.ballUtils = {
    getBall = function()
        local currentTime = tick()
        if currentTime - timeCache.lastBallCheck < AutoPlayModule.CONFIG.BALL_CHECK_RATE then
            return
        end
        timeCache.lastBallCheck = currentTime
        
        local ballsFolder = AutoPlayModule.customService.Workspace:FindFirstChild("Balls")
        if not ballsFolder then
            AutoPlayModule.ball = nil
            return
        end
        
        for _, object in pairs(ballsFolder:GetChildren()) do
            if object:GetAttribute("realBall") then
                AutoPlayModule.ball = object
                return
            end
        end
    
        AutoPlayModule.ball = nil
    end,
    
    getDirection = function()
        if not AutoPlayModule.ball then
            return resultCache.lastBallDirection
        end
        
        local localPlayer = AutoPlayModule.customService.Players.LocalPlayer
        if not localPlayer.Character or not localPlayer.Character.HumanoidRootPart then
            return resultCache.lastBallDirection
        end
    
        local direction = (localPlayer.Character.HumanoidRootPart.Position - AutoPlayModule.ball.Position).Unit
        resultCache.lastBallDirection = direction
        return direction
    end,
    
    getVelocity = function()
        if not AutoPlayModule.ball then
            return
        end
    
        local zoomies = AutoPlayModule.ball:FindFirstChild("zoomies")
        return zoomies and zoomies.VectorVelocity
    end,
    
    getSpeed = function()
        if not AutoPlayModule.ball then
            return resultCache.ballSpeed
        end
        
        local velocity = AutoPlayModule.ballUtils.getVelocity()
        if velocity then
            resultCache.ballSpeed = velocity.Magnitude
        end
        
        return resultCache.ballSpeed
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
    local halfPi = math.pi * 0.5
    local cosTheta = math.cos(theta)
    local sinTheta = math.sin(theta)
    
    local firstCandidate = middle + Vector3.new(
        cosTheta * math.cos(halfPi) - sinTheta * math.sin(halfPi),
        0,
        sinTheta * math.cos(halfPi) + cosTheta * math.sin(halfPi)
    ) * offsetLength

    local secondCandidate = middle + Vector3.new(
        cosTheta * math.cos(-halfPi) - sinTheta * math.sin(-halfPi),
        0,
        sinTheta * math.cos(-halfPi) + cosTheta * math.sin(-halfPi)
    ) * offsetLength

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

    return (firstCandidate - middle):Dot(dotValue) < 0 and firstCandidate or secondCandidate
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

    return AutoPlayModule.quadratic(start, AutoPlayModule.CONTROL_POINT, finish, timeElapsed)
end

AutoPlayModule.map = {
    getFloor = function()
        local currentTime = tick()
        if resultCache.floor and currentTime - timeCache.lastFloorCheck < 5 then
            return resultCache.floor
        end
        timeCache.lastFloorCheck = currentTime
        
        local floor = AutoPlayModule.customService.Workspace:FindFirstChild("FLOOR")
        
        if floor then
            resultCache.floor = floor
            return floor
        end

        local workspace = AutoPlayModule.customService.Workspace
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                local size = part.Size
                if size.X > 50 and size.Z > 50 and part.Position.Y < 5 then
                    resultCache.floor = part
                    return part
                end
            end
        end
        
        return resultCache.floor
    end
}

AutoPlayModule.getRandomPosition = function()
    local currentTime = tick()
    if currentTime - timeCache.lastPositionUpdate < AutoPlayModule.CONFIG.POSITION_UPDATE_RATE then
        return resultCache.lastRandomPosition
    end
    timeCache.lastPositionUpdate = currentTime
    
    local floor = AutoPlayModule.map.getFloor()

    if not floor or not AutoPlayModule.ballUtils.isExisting() then
        return resultCache.lastRandomPosition
    end

    if AutoPlayModule.playerProximity.isPlayerTooClose() then
        local avoidancePosition = AutoPlayModule.playerProximity.getAvoidancePosition()
        if avoidancePosition then
            resultCache.lastRandomPosition = avoidancePosition
            return avoidancePosition
        end
    end

    local ballDirection = AutoPlayModule.ballUtils.getDirection()
    if not ballDirection then
        return resultCache.lastRandomPosition
    end
    
    ballDirection = ballDirection * AutoPlayModule.CONFIG.DIRECTION
    local ballSpeed = AutoPlayModule.ballUtils.getSpeed()

    local speedThreshold = math.min(ballSpeed * 0.1, AutoPlayModule.CONFIG.MULTIPLIER_THRESHOLD)
    local speedMultiplier = AutoPlayModule.CONFIG.DEFAULT_DISTANCE + speedThreshold
    local negativeDirection = ballDirection * speedMultiplier

    local currentTimeScaled = currentTime * 0.83333
    local sine = math.sin(currentTimeScaled) * AutoPlayModule.CONFIG.TRAVERSING
    local cosine = math.cos(currentTimeScaled) * AutoPlayModule.CONFIG.TRAVERSING

    local traversing = Vector3.new(sine, 0, cosine)
    local finalPosition = floor.Position + negativeDirection + traversing

    if AutoPlayModule.CONFIG.PLAYER_DISTANCE_ENABLED then
        local entityProps = AutoPlayModule.playerProximity.getEntityProperties()
        if entityProps and entityProps.Distance < AutoPlayModule.CONFIG.MINIMUM_PLAYER_DISTANCE * 2 then
            local avoidanceOffset = entityProps.Direction * AutoPlayModule.CONFIG.MINIMUM_PLAYER_DISTANCE
            finalPosition = finalPosition + avoidanceOffset
        end
    end

    resultCache.lastRandomPosition = finalPosition
    return finalPosition
end

AutoPlayModule.lobby = {
    isChooserAvailable = function()
        local spawn = AutoPlayModule.customService.Workspace:FindFirstChild("Spawn")
        return spawn and spawn.NewPlayerCounter and spawn.NewPlayerCounter.GUI and 
               spawn.NewPlayerCounter.GUI.SurfaceGui and spawn.NewPlayerCounter.GUI.SurfaceGui.Top and 
               spawn.NewPlayerCounter.GUI.SurfaceGui.Top.Options and 
               spawn.NewPlayerCounter.GUI.SurfaceGui.Top.Options.Visible
    end,
    
    updateChoice = function(choice)
        AutoPlayModule.lobbyChoice = choice
    end,
    
    getMapChoice = function()
        local choice = AutoPlayModule.lobbyChoice or math.random(1, 3)
        local spawn = AutoPlayModule.customService.Workspace:FindFirstChild("Spawn")
        if not spawn or not spawn.NewPlayerCounter or not spawn.NewPlayerCounter.Colliders then
            return nil
        end
        
        return spawn.NewPlayerCounter.Colliders:FindFirstChild(tostring(choice))
    end,
    
    getPadPosition = function()
        if not AutoPlayModule.lobby.isChooserAvailable() then
            AutoPlayModule.lobbyChoice = nil
            return
        end
    
        local choice = AutoPlayModule.lobby.getMapChoice()
        return choice and choice.Position, choice and choice.Name
    end
}

AutoPlayModule.movement = {
    removeCache = function()
        AutoPlayModule.animationCache = nil
    end,
    
    createJumpVelocity = function(player)
        local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local velocity = Instance.new("BodyVelocity")
        velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        velocity.Velocity = Vector3.new(0, 80, 0)
        velocity.Parent = rootPart
    
        AutoPlayModule.customService.Debris:AddItem(velocity, 0.001)
        
        local replicatedStorage = AutoPlayModule.customService.ReplicatedStorage
        local remotes = replicatedStorage:FindFirstChild("Remotes")
        local doubleJump = remotes and remotes:FindFirstChild("DoubleJump")
        if doubleJump then
            doubleJump:FireServer()
        end
    end,
    
    playJumpAnimation = function(player)
        if not AutoPlayModule.animationCache then
            local replicatedStorage = AutoPlayModule.customService.ReplicatedStorage
            local assets = replicatedStorage:FindFirstChild("Assets")
            local tutorial = assets and assets:FindFirstChild("Tutorial")
            local animations = tutorial and tutorial:FindFirstChild("Animations")
            local doubleJumpAnim = animations and animations:FindFirstChild("DoubleJump")
            
            if doubleJumpAnim and player.Character and player.Character.Humanoid and player.Character.Humanoid.Animator then
                AutoPlayModule.animationCache = player.Character.Humanoid.Animator:LoadAnimation(doubleJumpAnim)
            end
        end
    
        if AutoPlayModule.animationCache then
            AutoPlayModule.animationCache:Play()
        end
    end,
    
    doubleJump = function(player)
        if AutoPlayModule.doubleJumped or not player.Character then
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
        if not AutoPlayModule.CONFIG.JUMPING_ENABLED or not player.Character then
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
        if player.Character and player.Character.Humanoid then
            player.Character.Humanoid:MoveTo(playerPosition)
        end
    end,
    
    stop = function(player)
        if player.Character and player.Character.HumanoidRootPart and player.Character.Humanoid then
            player.Character.Humanoid:MoveTo(player.Character.HumanoidRootPart.Position)
        end
    end
}

AutoPlayModule.signal = {
    connect = function(name, connection, Callback)
        if not name then
            name = AutoPlayModule.customService.HttpService:GenerateGUID()
        end
    
        AutoPlayModule.signals[name] = connection:Connect(Callback)
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
            if typeof(connection) == "RBXScriptConnection" then
                connection:Disconnect()
                AutoPlayModule.signals[name] = nil
            end
        end
    end
}

AutoPlayModule.findPath = function(inLobby, delta)
    local localPlayer = AutoPlayModule.customService.Players.LocalPlayer
    if not localPlayer.Character or not localPlayer.Character.HumanoidRootPart then
        return nil
    end
    
    local rootPosition = localPlayer.Character.HumanoidRootPart.Position

    if inLobby then
        local padPosition, padNumber = AutoPlayModule.lobby.getPadPosition()
        local choice = tonumber(padNumber)
        if choice then
            AutoPlayModule.lobby.updateChoice(choice)
            if getgenv().AutoVote then
                local replicatedStorage = AutoPlayModule.customService.ReplicatedStorage
                local packages = replicatedStorage:FindFirstChild("Packages")
                local index = packages and packages:FindFirstChild("_Index")
                local net = index and index:FindFirstChild("sleitnick_net@0.1.0")
                local netFolder = net and net:FindFirstChild("net")
                local updateVotes = netFolder and netFolder:FindFirstChild("RE/UpdateVotes")
                if updateVotes then
                    updateVotes:FireServer("FFA")
                end
            end
        end

        if not padPosition then
            return nil
        end

        return AutoPlayModule.getCurve(rootPosition, padPosition, delta)
    end

    local randomPosition = AutoPlayModule.getRandomPosition()
    if not randomPosition then
        return nil
    end

    return AutoPlayModule.getCurve(rootPosition, randomPosition, delta)
end

AutoPlayModule.followPath = function(delta)
    AutoPlayModule.frameThrottle = AutoPlayModule.frameThrottle + 1

    if AutoPlayModule.frameThrottle % AutoPlayModule.CONFIG.UPDATE_FREQUENCY ~= 0 then
        return
    end

    local localPlayer = AutoPlayModule.customService.Players.LocalPlayer
    if not AutoPlayModule.playerHelper.isAlive(localPlayer) then
        AutoPlayModule.movement.removeCache()
        return
    end

    local inLobby = localPlayer.Character.Parent == AutoPlayModule.customService.Workspace.Dead
    local path = AutoPlayModule.findPath(inLobby, delta * AutoPlayModule.CONFIG.UPDATE_FREQUENCY)

    if not path then
        AutoPlayModule.movement.stop(localPlayer)
        return
    end

    AutoPlayModule.movement.move(localPlayer, path)
    AutoPlayModule.movement.jump(localPlayer)
end

AutoPlayModule.finishThread = function()
    AutoPlayModule.signal.disconnect("auto-play")
    AutoPlayModule.signal.disconnect("synchronize")
    
    local localPlayer = AutoPlayModule.customService.Players.LocalPlayer
    if AutoPlayModule.playerHelper.isAlive(localPlayer) then
        AutoPlayModule.movement.stop(localPlayer)
    end

    for key, _ in pairs(resultCache) do
        resultCache[key] = nil
    end
    for key, _ in pairs(timeCache) do
        timeCache[key] = 0
    end
end

AutoPlayModule.runThread = function()
    AutoPlayModule.signal.connect("auto-play", AutoPlayModule.customService.RunService.PostSimulation, AutoPlayModule.followPath)
    AutoPlayModule.signal.connect("synchronize", AutoPlayModule.customService.RunService.PostSimulation, AutoPlayModule.ballUtils.getBall)
end

AISection:Toggle({
    Title = "AI Auto Play",
    Default = true,
    Callback = function(value)
        if value then
            AutoPlayModule.runThread()
        else
            AutoPlayModule.finishThread()
        end
    end
})

AISection:Toggle({
    Title = "AI Enable Jumping",
    Default = true,
    Callback = function(value)
        AutoPlayModule.CONFIG.JUMPING_ENABLED = value
    end
})

AISection:Toggle({
    Title = "AI Auto Vote",
    Default = false,
    Callback = function(value)
        getgenv().AutoVote = value
    end
})

AISection:Toggle({
    Title = "AI Avoid Players",
    Default = false,
    Callback = function(value)
        AutoPlayModule.CONFIG.PLAYER_DISTANCE_ENABLED = value
    end
})

AISection:Slider({
    Title = "AI Update Frequency",
    Step = 1,
    Value = { 
    Min = 3,
    Max = 20,
    Default = AutoPlayModule.CONFIG.UPDATE_FREQUENCY,
    },
    Callback = function(value)
        AutoPlayModule.CONFIG.UPDATE_FREQUENCY = value
    end
})

AISection:Slider({
    Title = "AI Distance From Ball",
    Step = 1,
    Value = {
    Min = 5,
    Max = 100,
    Default = AutoPlayModule.CONFIG.DEFAULT_DISTANCE,
    },
    Callback = function(value)
        AutoPlayModule.CONFIG.DEFAULT_DISTANCE = value
    end
})

AISection:Slider({
    Title = "AI Distance From Players",
    Step = 1,
    Value = {
    Min = 10,
    Max = 150,
    Default = AutoPlayModule.CONFIG.MINIMUM_PLAYER_DISTANCE,
    },
    Callback = function(value)
        AutoPlayModule.CONFIG.MINIMUM_PLAYER_DISTANCE = value
    end
})

AISection:Slider({
    Title = "AI Speed Multiplier",
    Step = 1,
    Value = {
    Min = 10,
    Max = 200,
    Default = AutoPlayModule.CONFIG.MULTIPLIER_THRESHOLD,
    },
    Callback = function(value)
        AutoPlayModule.CONFIG.MULTIPLIER_THRESHOLD = value
    end
})

AISection:Slider({
    Title = "AI Transversing",
    Step = 1,
    Value = {
    Min = 0,
    Max = 100,
    Default = AutoPlayModule.CONFIG.TRAVERSING,
    },
    Callback = function(value)
        AutoPlayModule.CONFIG.TRAVERSING = value
    end
})

AISection:Slider({
    Title = "AI Direction",
    Step = 0.1,
    Value = {
    Min = -1,
    Max = 1,
    Default = AutoPlayModule.CONFIG.DIRECTION,
    },
    Callback = function(value)
        AutoPlayModule.CONFIG.DIRECTION = value
    end
})

AISection:Slider({
    Title = "AI Offset Factor",
    Step = 0.05,
    Value = {
    Min = 0.1,
    Max = 1,
    Default = AutoPlayModule.CONFIG.OFFSET_FACTOR,
    },
    Callback = function(value)
        AutoPlayModule.CONFIG.OFFSET_FACTOR = value
    end
})

AISection:Slider({
    Title = "AI Movement Duration",
    Step = 0.05,
    Value = {
    Min = 0.1,
    Max = 1,
    Default = AutoPlayModule.CONFIG.MOVEMENT_DURATION,
    },
    Callback = function(value)
        AutoPlayModule.CONFIG.MOVEMENT_DURATION = value
    end
})

AISection:Slider({
    Title = "AI Generation Threshold",
    Step = 0.05,
    Value = {
    Min = 0.1,
    Max = 0.5,
    Default = AutoPlayModule.CONFIG.GENERATION_THRESHOLD,
    },
    Callback = function(value)
        AutoPlayModule.CONFIG.GENERATION_THRESHOLD = value
    end
})

AISection:Slider({
    Title = "AI Jump Chance",
    Step = 1,
    Value = {
    Min = 0,
    Max = 100,
    Default = AutoPlayModule.CONFIG.JUMP_PERCENTAGE,
    },
    Callback = function(value)
        AutoPlayModule.CONFIG.JUMP_PERCENTAGE = value
    end
})

AISection:Slider({
    Title = "AI Double Jump Chance",
    Step = 1,
    Value = {
    Min = 0,
    Max = 100,
    Default = AutoPlayModule.CONFIG.DOUBLE_JUMP_PERCENTAGE,
    },
    Callback = function(value)
        AutoPlayModule.CONFIG.DOUBLE_JUMP_PERCENTAGE = value
    end
})

end)
    if child.Name == 'Balls' then
        System.__properties.__cached_balls = nil
    end

local balls = workspace:FindFirstChild('Balls')
if balls then
    balls.ChildAdded:Connect(function()
        System.__properties.__parried = false
    end)
    
    balls.ChildRemoved:Connect(function()
        System.__properties.__parries = 0
        System.__properties.__parried = false
    end)
end
