

repeat

    task.wait()

until game:IsLoaded();


local Workspace = game:GetService("Workspace")

local VirtualInputManager = game:GetService("VirtualInputManager")


local RobloxReplicatedStorage = game:GetService('RobloxReplicatedStorage')
local RbxAnalyticsService = game:GetService('RbxAnalyticsService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')
local NetworkClient = game:GetService('NetworkClient')
local TweenService = game:GetService('TweenService')
local VirtualUser = game:GetService('VirtualUser')
local HttpService = game:GetService('HttpService')
local RunService = game:GetService('RunService')
local LogService = game:GetService('LogService')
local Players = game:GetService('Players')
local Debris = game:GetService('Debris')
local Stats = game:GetService('Stats')




local LocalPlayer = Players.LocalPlayer

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local Humanoid = Character:WaitForChild("Humanoid")





local Alive = Workspace:FindFirstChild("Alive")

local Aerodynamic = false

local Aerodynamic_Time = tick()

local Last_Input = UserInputService:GetLastInputType()

local Vector2_Mouse_Location = nil

local Grab_Parry = nil

local Parry_Key = nil

local Remotes = {}

local Parries = 0

local disableParryUntil = 0

local abilityLastUsed = 0

local Connections_Manager = {}

local Animation = {storage = {}, current = nil, track = nil}

local Parried = false

local Closest_Entity = nil

local spectate_Enabled = false

local manualSpamSpeed = 10

local pingBased = true

local autoSpamCoroutine = nil
local targetPlayer = nil
local lastHit = 0
local oldSpeed = 0
local lastPositionDistance = 0
local oldFromTarget = nil
local TargetSelectionMethod = ""

task.spawn(function()

    for _, Value in getgc() do

        if type(Value) == 'function' and islclosure(Value) then

            local Protos = debug.getprotos(Value)

            local Upvalues = debug.getupvalues(Value)

            local Constants = debug.getconstants(Value)

            if #Protos == 4 and #Upvalues == 24 and #Constants >= 102 then

                local c62 = Constants[62]

                local c64 = Constants[64]

                local c65 = Constants[65]

                Remotes[debug.getupvalue(Value, 16)] = c62

                Parry_Key = debug.getupvalue(Value, 17)

                Remotes[debug.getupvalue(Value, 18)] = c64

                Remotes[debug.getupvalue(Value, 19)] = c65

                break

            end

        end

    end

end)



local Key = Parry_Key;

local Auto_Parry = {};

    
local Player = {
    Entity = {
        properties = {
            server_position = Vector3.new(0, 0, 0),
            ping = 0,
            velocity = Vector3.new(0, 0, 0),
            speed = 0,
            is_moving = false,
            sword = nil
        }
    }
}

RunService:BindToRenderStep('server_position_simulation', Enum.RenderPriority.First.Value, function()
    local ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue()

    if not LocalPlayer.Character or not LocalPlayer.Character.PrimaryPart then
        return
    end

    local PrimaryPart = LocalPlayer.Character.PrimaryPart
    local old_position = PrimaryPart.Position

    task.delay(ping / 1000, function()
        Player.Entity.properties.server_position = old_position
    end)
end)

RunService.PreSimulation:Connect(function()
    NetworkClient:SetOutgoingKBPSLimit(math.huge)

    local character = LocalPlayer.Character
    if not character or not character.PrimaryPart then
        return
    end

    local player_properties = Player.Entity.properties
    player_properties.sword = character:GetAttribute('CurrentlyEquippedSword') or "None"
    player_properties.ping = Stats.Network.ServerStatsItem['Data Ping']:GetValue()
    player_properties.velocity = character.PrimaryPart.AssemblyLinearVelocity
    player_properties.speed = player_properties.velocity.Magnitude
    player_properties.is_moving = player_properties.speed > 30
end)
    
Auto_Parry.Parry_Animation = function()

	local Parry_Animation = ReplicatedStorage.Shared.SwordAPI.Collection.Default:FindFirstChild("GrabParry");

	local Current_Sword = LocalPlayer.Character:GetAttribute("CurrentlyEquippedSword");

	if (not Current_Sword or not Parry_Animation) then

		return;

	end

	local Sword_Data = ReplicatedStorage.Shared.ReplicatedInstances.Swords.GetSword:Invoke(Current_Sword);

	if (not Sword_Data or not Sword_Data['AnimationType']) then

		return;

	end

	for _, object in pairs(ReplicatedStorage.Shared.SwordAPI.Collection:GetChildren()) do

		if (object.Name == Sword_Data['AnimationType']) then

			local sword_animation_type = (object:FindFirstChild("GrabParry") and "GrabParry") or "Grab";

			Parry_Animation = object[sword_animation_type];

		end

	end

	Grab_Parry = LocalPlayer.Character.Humanoid.Animator:LoadAnimation(Parry_Animation);

	Grab_Parry:Play();

end;

Auto_Parry.Play_Animation = function(animationName)

	local Animations = Animation.storage[animationName];

	if not Animations then

		return false;

	end

	local Animator = LocalPlayer.Character.Humanoid.Animator;

	if (Animation.track and Animation.track:IsA("AnimationTrack")) then

		Animation.track:Stop();

	end

	Animation.track = Animator:LoadAnimation(Animations);

	if (Animation.track and Animation.track:IsA("AnimationTrack")) then

		Animation.track:Play();

	end

	Animation.current = animationName;

end;

Auto_Parry.Get_Balls = function()

	local Balls = {};

	for _, instance in pairs(Workspace.Balls:GetChildren()) do

		if instance:GetAttribute("realBall") then

			instance.CanCollide = false;

			table.insert(Balls, instance);

		end

	end

	return Balls;

end;

Auto_Parry.Get_Ball = function()

	for _, instance in pairs(Workspace.Balls:GetChildren()) do

		if instance:GetAttribute("realBall") then

			instance.CanCollide = false;

			return instance;

		end

	end

end;



function Auto_Parry.Parry_Data()

	local Camera = workspace.CurrentCamera

	if not Camera then return {0, CFrame.new(), {}, {0, 0}} end



	local ViewportSize = Camera.ViewportSize

	local MouseLocation = (Last_Input == Enum.UserInputType.MouseButton1 or Last_Input == Enum.UserInputType.MouseButton2 or Last_Input == Enum.UserInputType.Keyboard)

		and UserInputService:GetMouseLocation()

		or Vector2.new(ViewportSize.X / 2, ViewportSize.Y / 2)



	local Used = {MouseLocation.X, MouseLocation.Y}



	if TargetSelectionMethod == "ClosestToPlayer" then

		Auto_Parry.Closest_Player()

		local targetPlayer = Closest_Entity

		if targetPlayer and targetPlayer.PrimaryPart then

			Used = targetPlayer.PrimaryPart.Position

		end

	end



	local Alive = workspace.Alive:GetChildren()

	local Events = table.create(#Alive)

	for _, v in ipairs(Alive) do

			Events[tostring(v)] = Camera:WorldToScreenPoint(v.PrimaryPart.Position)

	end



	local pos = Camera.CFrame.Position

	local look = Camera.CFrame.LookVector

	local up = Camera.CFrame.UpVector

	local right = Camera.CFrame.RightVector



	local directions = {

		Backwards = pos - look * 1000,

		Random = Vector3.new(math.random(-3000, 3000), math.random(-3000, 3000), math.random(-3000, 3000)),

		Straight = pos + look * 1000,

		Up = pos + up * 1000,

		Right = pos + right * 1000,

		Left = pos - right * 1000

	}



	local lookTarget = directions[Auto_Parry.Parry_Type] or (pos + look * 1000)

	local DirectionCF = CFrame.new(pos, lookTarget)



	return {0, DirectionCF, Events, Used}

end

local foundFake = false

for _, Args in pairs(Remotes) do

    if Args == "PARRY_HASH_FAKE_1" or Args == "_G" then

        foundFake = true

        break

    end

end

Auto_Parry.Parry = function()

    local Parry_Data = Auto_Parry.Parry_Data()

    for Remote, Args in pairs(Remotes) do

        local Hash

        if foundFake then

            Hash = nil

        else

            Hash = Args

        end

        Remote:FireServer(Hash, Key, Parry_Data[1], Parry_Data[2], Parry_Data[3], Parry_Data[4])

    end

    if Parries > 7 then

        return false

    end

    Parries += 1

    task.delay(0.3, function()

        if Parries > 0 then

            Parries -= 1

        end

    end)

end





local Lerp_Radians = 0;

local Last_Warping = tick();

Auto_Parry.Linear_Interpolation = function(a, b, time_volume)

	return a + ((b - a) * time_volume);

end;

local Previous_Velocity = {};

local Curving = tick();


Auto_Parry.Is_Curved = function()
    local ball = Auto_Parry.Get_Ball()
    if not ball then
        return false
    end
    local zoomies = ball:FindFirstChild("zoomies")
    if not zoomies then
        return false
    end

    local ballProperties = Auto_Parry:Get_Ball_Properties() or {}
    local target = ball:GetAttribute("target")
    local currentTarget = target or (Closest_Entity and Closest_Entity.Name) or nil
    if not currentTarget then
        return false
    end

    -- Initialize ballProperties fields if missing
    ballProperties.Distance = ballProperties.Distance or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer.Character.HumanoidRootPart.Position - ball.Position).Magnitude) or math.huge
    ballProperties.speed = ballProperties.speed or ball.Velocity.Magnitude
    ballProperties.maximum_speed = ballProperties.maximum_speed or ballProperties.speed
    ballProperties.auto_spam = ballProperties.auto_spam or true
    ballProperties.aero_dynamic_time = ballProperties.aero_dynamic_time or 0
    ballProperties.hell_hook_completed = ballProperties.hell_hook_completed or false

    -- Check for specific ball effects
    local targetCharacter = Closest_Entity or (target and game.Players:FindFirstChild(target) and game.Players:FindFirstChild(target).Character)
    if targetCharacter and targetCharacter:IsA("Model") and targetCharacter:FindFirstChild("HumanoidRootPart") then
        if targetCharacter:FindFirstChild("MaxShield") and currentTarget ~= LocalPlayer.Name and ballProperties.Distance < 50 then
            return false
        end
    end

    if ball:FindFirstChild("TimeHole1") and currentTarget ~= LocalPlayer.Name and ballProperties.Distance < 100 then
        ballProperties.auto_spam = false
        return false
    end

    if ball:FindFirstChild("WEMAZOOKIEGO") and currentTarget ~= LocalPlayer.Name and ballProperties.Distance < 100 then
        return false
    end

    if ball:FindFirstChild("At2") and ballProperties.speed <= 0 then
        return true
    end

    if ball:FindFirstChild("AeroDynamicSlashVFX") then
        Debris:AddItem(ball.AeroDynamicSlashVFX, 0)
        ballProperties.auto_spam = false
        ballProperties.aero_dynamic_time = tick()
    end

    -- Check for Tornado effect
    local runTimeTornado = Workspace:FindFirstChild("RunTime") and Workspace.RunTime:FindFirstChild("Tornado")
    if runTimeTornado then
        local tornadoTime = runTimeTornado:GetAttribute("TornadoTime") or 1
        if ballProperties.Distance > 5 and (tick() - ballProperties.aero_dynamic_time) < (tornadoTime + 0.314159) then
            return true
        end
    end
    
    -- if not ballProperties.hell_hook_completed and currentTarget == LocalPlayer.Name and ballProperties.Distance > 10 then
    --     return true
    -- end

    local ballVelocity = zoomies.VectorVelocity
    local ballSpeed = ballVelocity.Magnitude
    local ballDirection = ballVelocity.Unit
    local playerDirection = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and (LocalPlayer.Character.HumanoidRootPart.Position - ball.Position).Unit) or Vector3.new(0, 0, 0)
    local dot = playerDirection:Dot(ballDirection)
    local distance = ballProperties.Distance
    local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()

    local speedThreshold = math.min(ballSpeed / 100, 40)
    local angleThreshold = 40 * math.max(dot, 0)
    local dotThreshold = 0.7 - (ping / 1000)
    local reachTime = distance / math.max(ballProperties.maximum_speed, 1) - (ping / 1000)
    local enoughSpeed = ballProperties.maximum_speed > 100

    local ballDistanceThreshold = (25 - math.min(distance / 1000, 15) + angleThreshold + speedThreshold) * (1 + ping / 1000)

    if enoughSpeed and reachTime > ping / 10 then
        ballDistanceThreshold = math.max(ballDistanceThreshold - 10, 25)
    end

    if distance < ballDistanceThreshold then
        return false
    end

    local accurateDirection = ballDirection
    local directionDifference = (accurateDirection - ballVelocity).Unit
    local accurateDot = playerDirection:Dot(directionDifference)
    local dotDifference = dot - accurateDot

    if dotDifference < dotThreshold then
        return true
    end

    if Lerp_Radians < 0.025 then
        ballProperties.last_curve_position = ball.Position
        Last_Warping = tick()
    end

    if (tick() - Last_Warping) < (reachTime / 1.5) then
        return true
    end

    if dot < dotThreshold then
        return true
    end

    return false
end

Auto_Parry.Closest_Player = function()

	local Max_Distance = math.huge;

	Closest_Entity = nil;

	for _, Entity in pairs(Workspace.Alive:GetChildren()) do

		if ((tostring(Entity) ~= tostring(LocalPlayer)) and Entity.PrimaryPart) then

			local Distance = LocalPlayer:DistanceFromCharacter(Entity.PrimaryPart.Position);

			if (Distance < Max_Distance) then

				Max_Distance = Distance;

				Closest_Entity = Entity;

			end

		end

	end

	return Closest_Entity;

end;

Auto_Parry.Get_Entity_Properties = function(self)

	Auto_Parry.Closest_Player();

	if not Closest_Entity then

		return false;

	end

	local Entity_Velocity = Closest_Entity.PrimaryPart.Velocity;

	local Entity_Direction = (LocalPlayer.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Unit;

	local Entity_Distance = (LocalPlayer.Character.PrimaryPart.Position - Closest_Entity.PrimaryPart.Position).Magnitude;

	return {Velocity=Entity_Velocity,Direction=Entity_Direction,Distance=Entity_Distance};

end;

Auto_Parry.Get_Ball_Properties = function(self)

	local ball = Auto_Parry.Get_Ball();

	if not ball then

		return false;

	end

	local character = LocalPlayer.Character;

	if (not character or not character.PrimaryPart) then

		return false;

	end

	local ballVelocity = ball.AssemblyLinearVelocity;

	local ballDirection = (character.PrimaryPart.Position - ball.Position).Unit;

	local ballDistance = (character.PrimaryPart.Position - ball.Position).Magnitude;

	local ballDot = ballDirection:Dot(ballVelocity.Unit);

	return {Velocity=ballVelocity,Direction=ballDirection,Distance=ballDistance,Dot=ballDot};

end;

Auto_Parry.Spam_Service = function(self)

	local ball = Auto_Parry.Get_Ball();

	if not ball then

		return false;

	end

	Auto_Parry.Closest_Player();

	local spamDelay = 0;

	local spamAccuracy = 100;

	if not self.Spam_Sensitivity then

		self.Spam_Sensitivity = 50;

	end

	if not self.Ping_Based_Spam then

		self.Ping_Based_Spam = false;

	end

	local velocity = ball.AssemblyLinearVelocity;

	local speed = velocity.Magnitude;

	local direction = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Unit;

	local dot = direction:Dot(velocity.Unit);

	local targetPosition = Closest_Entity.PrimaryPart.Position;

	local targetDistance = LocalPlayer:DistanceFromCharacter(targetPosition);

	local maximumSpamDistance = self.Ping + math.min(speed / 6.5, 95);

	maximumSpamDistance = maximumSpamDistance * self.Spam_Sensitivity;

	if self.Ping_Based_Spam then

		maximumSpamDistance = maximumSpamDistance + self.Ping;

	end

	if ((self.Entity_Properties.Distance > maximumSpamDistance) or (self.Ball_Properties.Distance > maximumSpamDistance) or (targetDistance > maximumSpamDistance)) then

		return spamAccuracy;

	end

	local maximumSpeed = 5 - math.min(speed / 5, 5);

	local maximumDot = math.clamp(dot, -1, 0) * maximumSpeed;

	spamAccuracy = maximumSpamDistance - maximumDot;

	task.wait(spamDelay);

	return spamAccuracy;

end;



local visualizerEnabled = false

-- Spam Visualizer
local spamVisualizer = Instance.new("Part")
spamVisualizer.Name = "SpamVisualizer"
spamVisualizer.Shape = Enum.PartType.Ball
spamVisualizer.Anchored = true
spamVisualizer.CanCollide = false
spamVisualizer.Material = Enum.Material.ForceField
spamVisualizer.Transparency = 0.5
spamVisualizer.Parent = Workspace
spamVisualizer.Size = Vector3.zero

-- Parry Visualizer
local parryVisualizer = Instance.new("Part")
parryVisualizer.Name = "ParryVisualizer"
parryVisualizer.Shape = Enum.PartType.Ball
parryVisualizer.Anchored = true
parryVisualizer.CanCollide = false
parryVisualizer.Material = Enum.Material.ForceField
parryVisualizer.Transparency = 0.5
parryVisualizer.Parent = Workspace
parryVisualizer.Size = Vector3.zero

-- Player Text Label (above head)
local playerBillboard = Instance.new("BillboardGui")
playerBillboard.Name = "PlayerRangeLabel"
playerBillboard.AlwaysOnTop = true
playerBillboard.Size = UDim2.new(4, 0, 1, 0)
playerBillboard.StudsOffset = Vector3.new(0, 3, 0) -- 3 studs above head
playerBillboard.Enabled = false
local playerText = Instance.new("TextLabel")
playerText.Size = UDim2.new(1, 0, 1, 0)
playerText.BackgroundTransparency = 1
playerText.TextColor3 = Color3.fromRGB(255, 255, 255)
playerText.TextStrokeTransparency = 0.5
playerText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
playerText.Font = Enum.Font.SourceSansBold
playerText.TextSize = 16
playerText.Text = "Spam: 0, Parry: 0"
playerText.Parent = playerBillboard

-- Ball Text Label (near ball)
local ballBillboard = Instance.new("BillboardGui")
ballBillboard.Name = "BallDistanceLabel"
ballBillboard.AlwaysOnTop = true
ballBillboard.Size = UDim2.new(3, 0, 1, 0)
ballBillboard.StudsOffset = Vector3.new(0, 2, 0) -- 2 studs above ball
ballBillboard.Enabled = false
local ballText = Instance.new("TextLabel")
ballText.Size = UDim2.new(1, 0, 1, 0)
ballText.BackgroundTransparency = 1
ballText.TextColor3 = Color3.fromRGB(255, 255, 0)
ballText.TextStrokeTransparency = 0.5
ballText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
ballText.Font = Enum.Font.SourceSansBold
ballText.TextSize = 14
ballText.Text = "Dist: 0"
ballText.Parent = ballBillboard

local function calculate_visualizer_radius(ball, defaultDivisor)
    if not ball or not ball:FindFirstChild("zoomies") then        
        return 15
    end
    local velocity = ball:FindFirstChild("zoomies").VectorVelocity
    if not velocity then        
        return 15
    end
    local radius = math.clamp((velocity.Magnitude / defaultDivisor) + 10, 15, 200)   
    return radius
end

local function toggle_visualizer(state)
    visualizerEnabled = state
    if not state then
        spamVisualizer.Size = Vector3.zero
        parryVisualizer.Size = Vector3.zero
        playerBillboard.Enabled = false
        ballBillboard.Enabled = false
        print("Visualizer disabled")
    else
        print("Visualizer enabled")
    end
end

-- Visualizer update (spheres on RenderStepped)
RunService.RenderStepped:Connect(function()
    if not visualizerEnabled then
        spamVisualizer.Size = Vector3.zero
        parryVisualizer.Size = Vector3.zero
        return
    end

    local char = LocalPlayer.Character
    if not char then
        char = LocalPlayer.CharacterAdded:Wait()
    end
    local primaryPart = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
    local ball = Auto_Parry.Get_Ball()

    if not primaryPart or not ball or not ball:FindFirstChild("zoomies") then
        spamVisualizer.Size = Vector3.zero
        parryVisualizer.Size = Vector3.zero       
        return
    end

    -- Get ball and player data
    local targetPlayer = Closest_Entity
    local playerDistance = LocalPlayer:DistanceFromCharacter(ball.Position)
    local targetDistance = targetPlayer and targetPlayer:IsA("Model") and targetPlayer:FindFirstChild("HumanoidRootPart") and LocalPlayer:DistanceFromCharacter(targetPlayer.HumanoidRootPart.Position) or math.huge
    local ballSpeed = ball:FindFirstChild("zoomies").VectorVelocity.Magnitude
    local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    local ping_threshold = math.clamp(ping / 8, 6, 25)

    -- Ball properties
    local ball_properties = Auto_Parry:Get_Ball_Properties() or {}
    ball_properties.speed = ball_properties.speed or ballSpeed
    ball_properties.maximum_speed = ball_properties.maximum_speed or ballSpeed
    ball_properties.distance = ball_properties.distance or playerDistance

    -- Calculate ranges
    local spamAccuracy = ball_properties.maximum_speed / 7.2 + ping_threshold
    local spamRange = ping_threshold * 1.5 + ball_properties.speed / 2
    local parryRange = ping_threshold * 1.5 + ball_properties.speed / 2
    local parryAccuracy = ball_properties.maximum_speed / 8 + ping_threshold * 1.2

    -- Fallback radii
    if not spamRange then
        spamRange = calculate_visualizer_radius(ball, 2.4)        
    end
    if not parryRange then
        parryRange = calculate_visualizer_radius(ball, 2.4)        
    end

    -- Spam condition
    local isSpamActive = false
    if targetPlayer and targetPlayer:IsA("Model") and targetPlayer:FindFirstChild("HumanoidRootPart") then
        local params = {
            speed = ball_properties.speed,
            spam_accuracy = spamAccuracy,
            parries = Parries,
            ball_speed = ball_properties.speed,
            range = spamRange,
            last_hit = lastHit,
            ball_distance = playerDistance,
            maximum_speed = ball_properties.maximum_speed,
            old_speed = oldSpeed or ballSpeed,
            entity_distance = targetDistance,
            last_position_distance = lastPositionDistance or playerDistance
        }
        local spamState = Parries >= 2 and targetDistance >= 5 and targetDistance <= 15
        local currentTarget = ball:GetAttribute("target")
        local oldFromTarget = oldFromTarget or currentTarget
        if (spamState and ballSpeed > 60 and
           ((currentTarget ~= LocalPlayer.Name and oldFromTarget == LocalPlayer.Name) or playerDistance <= spamRange)) or
           (targetDistance >= 5 and targetDistance <= 15 and
            currentTarget == LocalPlayer.Name and
            oldFromTarget and oldFromTarget ~= LocalPlayer.Name and
            ballSpeed > 60) then
            isSpamActive = true
        end
    end

    
    local isParryActive = Parried or (ball:GetAttribute("target") == tostring(LocalPlayer) and playerDistance <= parryAccuracy)
    
    spamVisualizer.Size = Vector3.new(spamRange * 2, spamRange * 2, spamRange * 2)
    spamVisualizer.CFrame = primaryPart.CFrame
    spamVisualizer.Color = isSpamActive and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(0, 0, 255)
    spamVisualizer.Transparency = isSpamActive and 0.3 or 0.5
    
    parryVisualizer.Size = Vector3.new(parryRange * 2, parryRange * 2, parryRange * 2)
    parryVisualizer.CFrame = primaryPart.CFrame * CFrame.new(0, 0.5, 0)
    parryVisualizer.Color = isParryActive and Color3.fromRGB(255, 165, 0) or Color3.fromRGB(255, 0, 0)
    parryVisualizer.Transparency = isParryActive and 0.3 or 0.5
    
    playerBillboard.Parent = primaryPart
    ballBillboard.Parent = ball
end)

coroutine.wrap(function()
    while true do
        if visualizerEnabled then
            local char = LocalPlayer.Character
            local primaryPart = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
            local ball = Auto_Parry.Get_Ball()

            if primaryPart and ball and ball:FindFirstChild("zoomies") then
                local playerDistance = LocalPlayer:DistanceFromCharacter(ball.Position)
                local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                local ping_threshold = math.clamp(ping / 8, 6, 25)
                local ball_properties = Auto_Parry:Get_Ball_Properties() or {}
                ball_properties.speed = ball_properties.speed or ball:FindFirstChild("zoomies").VectorVelocity.Magnitude
                ball_properties.maximum_speed = ball_properties.maximum_speed or ball_properties.speed
                local spamRange = ping_threshold * 1.5 + ball_properties.speed / 2
                local parryRange = ping_threshold * 1.5 + ball_properties.speed / 2
                if ping > 300 then
                    spamRange = math.max(spamRange, 20)
                    parryRange = math.max(parryRange, 20)
                end
                spamRange = spamRange or calculate_visualizer_radius(ball, 2.4)
                parryRange = parryRange or calculate_visualizer_radius(ball, 2.4)

                -- Update labels
                playerBillboard.Enabled = true
                playerText.Text = string.format("Spam: %.1f, Parry: %.1f", spamRange, parryRange)
                ballBillboard.Enabled = true
                ballText.Text = string.format("Dist: %.1f", playerDistance)                
            else
                playerBillboard.Enabled = false
                ballBillboard.Enabled = false
            end
        else
            playerBillboard.Enabled = false
            ballBillboard.Enabled = false
        end
        task.wait(0.5)
    end
end)()

local Sound_Effect = true

local sound_effect_type = "DC_15X"

local CustomId = "" -- Should be set to just the numeric ID, like "1234567890"



local sound_assets = {

    DC_15X = 'rbxassetid://936447863',

    Neverlose = 'rbxassetid://8679627751',

    Minecraft = 'rbxassetid://8766809464',

    MinecraftHit2 = 'rbxassetid://8458185621',

    TeamfortressBonk = 'rbxassetid://8255306220',

    TeamfortressBell = 'rbxassetid://2868331684',

    Custom = 'empty'

}



local function PlaySound()

    if not Sound_Effect then return end



    local sound_id

    if CustomId ~= "" and sound_effect_type == "Custom" then

        sound_id = "rbxassetid://" .. CustomId

    else

        sound_id = sound_assets[sound_effect_type]

    end



    if not sound_id then return end



    local sound = Instance.new("Sound")

    sound.SoundId = sound_id

    sound.Volume = 1

    sound.PlayOnRemove = true

    sound.Parent = workspace

    sound:Destroy() -- Triggers the sound due to PlayOnRemove = true

end



task.defer(function()

    game.ReplicatedStorage.Remotes.ParrySuccess.OnClientEvent:Connect(PlaySound)

end)

function ManualSpam()



    if MauaulSpam then

        MauaulSpam:Destroy()

        MauaulSpam = nil

        return

    end





    MauaulSpam = Instance.new("ScreenGui")

    MauaulSpam.Name = "MauaulSpam"

    MauaulSpam.Parent = game:GetService("CoreGui") or game.Players.LocalPlayer:WaitForChild("PlayerGui")

    MauaulSpam.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    MauaulSpam.ResetOnSpawn = false





    local Main = Instance.new("Frame")

    Main.Name = "Main"

    Main.Parent = MauaulSpam

    Main.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

    Main.BorderColor3 = Color3.fromRGB(0, 0, 0)

    Main.BorderSizePixel = 0

    Main.Position = UDim2.new(0.41414836, 0, 0.404336721, 0)

    Main.Size = UDim2.new(0.227479532, 0, 0.191326529, 0)



    local UICorner = Instance.new("UICorner")

    UICorner.Parent = Main





    local IndercantorBlahblah = Instance.new("Frame")

    IndercantorBlahblah.Name = "IndercantorBlahblah"

    IndercantorBlahblah.Parent = Main

    IndercantorBlahblah.BackgroundColor3 = Color3.fromRGB(255, 0, 0)

    IndercantorBlahblah.BorderColor3 = Color3.fromRGB(0, 0, 0)

    IndercantorBlahblah.BorderSizePixel = 0

    IndercantorBlahblah.Position = UDim2.new(0.0280000009, 0, 0.0733333305, 0)

    IndercantorBlahblah.Size = UDim2.new(0.0719999969, 0, 0.119999997, 0)



    local UICorner_2 = Instance.new("UICorner")

    UICorner_2.CornerRadius = UDim.new(1, 0)

    UICorner_2.Parent = IndercantorBlahblah



    local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")

    UIAspectRatioConstraint.Parent = IndercantorBlahblah





    local PC = Instance.new("TextLabel")

    PC.Name = "PC"

    PC.Parent = Main

    PC.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

    PC.BackgroundTransparency = 1

    PC.BorderColor3 = Color3.fromRGB(0, 0, 0)

    PC.BorderSizePixel = 0

    PC.Position = UDim2.new(0.547999978, 0, 0.826666653, 0)

    PC.Size = UDim2.new(0.451999992, 0, 0.173333332, 0)

    PC.Font = Enum.Font.Unknown

    PC.Text = "PC: E to spam"

    PC.TextColor3 = Color3.fromRGB(57, 57, 57)

    PC.TextScaled = true

    PC.TextSize = 16

    PC.TextWrapped = true



    local UITextSizeConstraint = Instance.new("UITextSizeConstraint")

    UITextSizeConstraint.Parent = PC

    UITextSizeConstraint.MaxTextSize = 16



    local UIAspectRatioConstraint_2 = Instance.new("UIAspectRatioConstraint")

    UIAspectRatioConstraint_2.Parent = PC

    UIAspectRatioConstraint_2.AspectRatio = 4.346





    local IndercanotTextBlah = Instance.new("TextButton")

    IndercanotTextBlah.Name = "IndercanotTextBlah"

    IndercanotTextBlah.Parent = Main

    IndercanotTextBlah.Active = false

    IndercanotTextBlah.BackgroundColor3 = Color3.fromRGB(255, 255, 255)

    IndercanotTextBlah.BackgroundTransparency = 1

    IndercanotTextBlah.BorderColor3 = Color3.fromRGB(0, 0, 0)

    IndercanotTextBlah.BorderSizePixel = 0

    IndercanotTextBlah.Position = UDim2.new(0.164000005, 0, 0.326666653, 0)

    IndercanotTextBlah.Selectable = false

    IndercanotTextBlah.Size = UDim2.new(0.667999983, 0, 0.346666664, 0)

    IndercanotTextBlah.Font = Enum.Font.GothamBold

    IndercanotTextBlah.Text = "Spam"

    IndercanotTextBlah.TextColor3 = Color3.fromRGB(255, 255, 255)

    IndercanotTextBlah.TextScaled = true

    IndercanotTextBlah.TextSize = 24

    IndercanotTextBlah.TextWrapped = true



    local UIGradient = Instance.new("UIGradient")

    UIGradient.Color = ColorSequence.new({

        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),

        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 0, 4)),

        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))

    })

    UIGradient.Parent = IndercanotTextBlah



    local UITextSizeConstraint_2 = Instance.new("UITextSizeConstraint")

    UITextSizeConstraint_2.Parent = IndercanotTextBlah

    UITextSizeConstraint_2.MaxTextSize = 52



    local UIAspectRatioConstraint_3 = Instance.new("UIAspectRatioConstraint")

    UIAspectRatioConstraint_3.Parent = IndercanotTextBlah

    UIAspectRatioConstraint_3.AspectRatio = 3.212



    local UIAspectRatioConstraint_4 = Instance.new("UIAspectRatioConstraint")

    UIAspectRatioConstraint_4.Parent = Main

    UIAspectRatioConstraint_4.AspectRatio = 1.667





    local spamConnection

    local toggleManualSpam = false

    local RunService = game:GetService("RunService")

    local UserInputService = game:GetService("UserInputService")



    local function toggleSpam()

        toggleManualSpam = not toggleManualSpam



        if spamConnection then

            spamConnection:Disconnect()

            spamConnection = nil

        end



        if toggleManualSpam then

            spamConnection = RunService.PreSimulation:Connect(function()

                for _ = 1, manualSpamSpeed do

                    if not toggleManualSpam then

                        break

                    end

                    local success, err = pcall(function()

                        Auto_Parry.Parry()

                    end)

                    if not success then

                        warn("Error in Auto_Parry.Parry:", err)

                    end

                    task.wait()

                end

            end)

        end

    end





    local button = IndercanotTextBlah

    local UIGredient = button.UIGradient

    local NeedToChange = IndercantorBlahblah



local green_Color = {

    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 128)),

    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(128, 0, 128)),

    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 128))

}



    local red_Color = {

        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),

        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 0, 0)),

        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))

    }



    local current_Color = red_Color

    local target_Color = green_Color

    local is_Green = false

    local transition = false

    local transition_Time = 1

    local start_Time



    local function startColorTransition()

        transition = true

        start_Time = tick()

    end



    RunService.Heartbeat:Connect(function()

        if transition then

            local elapsed = tick() - start_Time

            local alpha = math.clamp(elapsed / transition_Time, 0, 1)

            local new_Color = {}



            for i = 1, #current_Color do

                local start_Color = current_Color[i].Value

                local end_Color = target_Color[i].Value

                new_Color[i] = ColorSequenceKeypoint.new(current_Color[i].Time, start_Color:Lerp(end_Color, alpha))

            end



            UIGredient.Color = ColorSequence.new(new_Color)



            if alpha >= 1 then

                transition = false

                current_Color, target_Color = target_Color, current_Color

            end

        end

    end)



    local function toggleColor()

        if not transition then

            is_Green = not is_Green



            if is_Green then

                target_Color = green_Color

                NeedToChange.BackgroundColor3 = Color3.new(0, 1, 0)

                toggleSpam()

            else

                target_Color = red_Color

                NeedToChange.BackgroundColor3 = Color3.new(1, 0, 0)

                toggleSpam()

            end



            startColorTransition()

        end

    end



    button.MouseButton1Click:Connect(toggleColor)





    local keyConnection

    keyConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)

        if gameProcessed then return end

        if input.KeyCode == Enum.KeyCode.E then

            toggleColor()

        end

    end)





    MauaulSpam.Destroying:Connect(function()

        if keyConnection then

            keyConnection:Disconnect()

        end

        if spamConnection then

            spamConnection:Disconnect()

        end

    end)





    local gui = Main

    local dragging

    local dragInput

    local dragStart

    local startPos



    local function update(input)

        local delta = input.Position - dragStart

        local newPosition = UDim2.new(

            startPos.X.Scale,

            startPos.X.Offset + delta.X,

            startPos.Y.Scale,

            startPos.Y.Offset + delta.Y

        )



        local TweenService = game:GetService("TweenService")

        local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        local tween = TweenService:Create(gui, tweenInfo, {Position = newPosition})

        tween:Play()

    end



    gui.InputBegan:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseButton1 or

           input.UserInputType == Enum.UserInputType.Touch then

            dragging = true

            dragStart = input.Position

            startPos = gui.Position



            input.Changed:Connect(function()

                if input.UserInputState == Enum.UserInputState.End then

                    dragging = false

                end

            end)

        end

    end)



    gui.InputChanged:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.MouseMovement or

           input.UserInputType == Enum.UserInputType.Touch then

            dragInput = input

        end

    end)



    UserInputService.InputChanged:Connect(function(input)

        if dragging and input == dragInput then

            update(input)

        end

    end)

end



local ScreenGui = Instance.new("ScreenGui")

local ImageButton = Instance.new("ImageButton")

local UICorner = Instance.new("UICorner")





ScreenGui.Parent = game.CoreGui

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling





ImageButton.Parent = ScreenGui

ImageButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

ImageButton.BorderSizePixel = 0

ImageButton.Position = UDim2.new(0.120833337, 0, 0.0952890813, 0)

ImageButton.Size = UDim2.new(0, 50, 0, 50)

ImageButton.Image = "rbxassetid://105822895597231"

ImageButton.Draggable = true





UICorner.Parent = ImageButton





ImageButton.MouseButton1Click:Connect(function()

    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)

end)



local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/CodeE4X-dev/Library/refs/heads/main/FluentRemake.lua"))();
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Blade Ball - VicoXStar",
    SubTitle = "by CodeE4X, Rudert",
    TabWidth = 160,
    Size = UDim2.fromOffset(470, 470),
    Acrylic = false,
    Theme = "DarkPurple",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Options = Fluent.Options

local Tabs = {
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    Home = Window:AddTab({Title = "Home", Icon = "home"}),
    Main = Window:AddTab({Title = "Main", Icon = "swords"}),
    Visual = Window:AddTab({Title = "Visuals", Icon = "eye"}),
    AI = Window:AddTab({Title = "Ai Play", Icon = "bot"}),
    Far = Window:AddTab({Title = "Auto Farm", Icon = "leaf"}),
    Misc = Window:AddTab({Title = "Players", Icon = "box"}),
}

Window:SelectTab(1)

-- Simplified theme list to avoid errors
local ThemeNames = {    
    "Dark",
    "Darker",
    "Light",
    "Aqua",
    "Amethyst",
    "Rose",
    "Golden",
    "DarkPurple",
    "Dark Halloween",
    "Light Halloween",
    "Dark Typewriter",
    "Jungle",
    "Midnight",
    "Neon Glow",
    "Neon Green",
    "Neon Pink",
    "Sunrise",
    "Galaxy",
    "Pastel",
    "Crimson",
    "Sunset",
    "Oceanic",
    "Minimalist",
    "Cyberpunk"
}

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("BladeBallScript")
SaveManager:SetFolder("BladeBallScript/BladeBall")

do    
    SaveManager:BuildConfigSection(Tabs.Settings)

    -- Theme Dropdown with robust error handling
    local ThemeDropdown = Tabs.Settings:AddDropdown("ThemeDropdown", {
        Title = "Select Theme",
        Values = ThemeNames,
        Multi = false,
        Default = "Dark",
        Callback = function(Value)
            local success, err = pcall(function()
                Fluent:SetTheme(Value)
            end)
            if success then
                Fluent:Notify({
                    Title = "Theme Changed",
                    Content = "Applied theme: " .. Value,
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "Theme Error",
                    Content = "Failed to apply theme: " .. Value,
                    Duration = 5
                })
                warn("Theme error:", err)
            end
        end
    })

    ThemeDropdown:OnChanged(function(Value)
        print("Theme changed to:", Value)
    end)
    
    local ColorPicker = Tabs.Settings:AddColorpicker("AccentColor", {
        Title = "Accent Color",
        Description = "Change the UI accent color",
        Default = Color3.fromRGB(96, 205, 255),
        Callback = function(Value)
            local success, err = pcall(function()
                Fluent:SetAccentColor(Value)
            end)
            if success then
                Fluent:Notify({
                    Title = "Accent Color Changed",
                    Content = "Applied new accent color",
                    Duration = 3
                })
            else
                Fluent:Notify({
                    Title = "Color Error",
                    Content = "Failed to apply color",
                    Duration = 5
                })
                warn("Color error:", err)
            end
        end
    })

    ColorPicker:OnChanged(function()
        print("Accent color changed to:", ColorPicker.Value)
    end)
    
    InterfaceManager:BuildInterfaceSection(Tabs.Settings)
end

local Section = Tabs.Home:AddSection("Info")
Tabs.Home:AddButton({
    Title = "Copy Our Discord For New Update",
    Description = "Copy Into Your Clipboard",
    Callback = function()
        setclipboard('https://discord.gg/M37wF7R9')
        Fluent:Notify({
            Title = "Heyya Buddy!",
            Content = "...",
            SubContent = "",
            Duration = 10
        })
    end
})

local Section = Tabs.Home:AddSection("Credits")
Tabs.Home:AddParagraph({
    Title = "CodeE4X, Rudert, Flesspe",
    Content = "- some feature and improve parry, Yeah its is. ",
})

Tabs.Home:AddParagraph({
    Title = "BB",
    Content = "-Ap One Target\n-Manual Spam\n-Some UI Colors\n-Anti Curve\n-and other that i forgot",
})

Tabs.Home:AddParagraph({
    Title = "Isa - Rudert",
    Content = "-Remote Not Compatible in The Script(Fixing)\n-Ai Models\n-Auto Farm Method",
})

Tabs.Home:AddParagraph({
    Title = "Clxty(dead) - Rudert",
    Content = "-Remotes Update\n-Auto_Parry.Parry Function, I Update To Sialan",
})

Tabs.Home:AddParagraph({
    Title = "Unknow",
    Content = "-PC Tester\n-Needed",
})

Tabs.Home:AddParagraph({
    Title = "Unknown",
    Content = "-Mobile Tester\n-Needed",
})

local Section = Tabs.Home:AddSection("Changelog")
Tabs.Home:AddParagraph({
    Title = " Update",
    Content = "- AutoParry\n-AutoSpam\n-All Feature (Improved)",
})

Tabs.Home:AddParagraph({
    Title = "Version",
    Content = "-V.PreRelease",
})


local function AutoParryFunction()
    local connection = RunService.PreSimulation:Connect(function()
        local One_Ball = Auto_Parry.Get_Ball()
        local Balls = Auto_Parry.Get_Balls()
        if (not Balls or (#Balls == 0)) then
            return
        end
        for _, Ball in pairs(Balls) do
            if not Ball then
                return
            end
            local Zoomies = Ball:FindFirstChild("zoomies")
            if not Zoomies then
                return
            end
            Ball:GetAttributeChangedSignal("target"):Once(function()
                Parried = false
            end)
            if Parried then
                return
            end
            local Ball_Target = Ball:GetAttribute("target")
            local One_Target = One_Ball and One_Ball:GetAttribute("target")
            local Velocity = Zoomies.VectorVelocity
            local character = LocalPlayer.Character
            if (not character or not character.PrimaryPart) then
                return
            end
            local Distance = (character.PrimaryPart.Position - Ball.Position).Magnitude
            local Speed = Velocity.Magnitude
            local Ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
            local ping_threshold = math.clamp(Ping / 10, 10, 16)
            local parryRange = ping_threshold + Speed / 3
            local parryAccuracy = Speed / 8 + ping_threshold * 1.2
            local Curved = Auto_Parry.Is_Curved()
            if ((Ball_Target == tostring(LocalPlayer)) and Aerodynamic) then
                local Elapsed_Tornado = tick() - Aerodynamic_Time
                if (Elapsed_Tornado > 0.6) then
                    Aerodynamic_Time = tick()
                    Aerodynamic = false
                end
                return
            end
            if ((One_Target == tostring(LocalPlayer)) and Curved) then
                return
            end
            if (Ball_Target == tostring(LocalPlayer)) and (Distance <= parryRange) and (Distance <= parryAccuracy) then
                Auto_Parry.Parry()
                Parried = true
                Parries = Parries + 1
            end
            local Last_Parrys = tick()
            while (tick() - Last_Parrys) < 1 do
                if not Parried then
                    break
                end
                task.wait()
            end
            Parried = false
        end
    end)
    return connection
end

local function AutoSpamFunction()
    local autoSpamCoroutine = coroutine.create(function(signal)
        while (signal ~= "stop") do
            local ball = Auto_Parry.Get_Ball()
            if ball and ball:IsDescendantOf(workspace) then
                local zoomies = ball:FindFirstChild("zoomies")
                if zoomies then
                    Auto_Parry.Closest_Player()
                    targetPlayer = Closest_Entity

                    if targetPlayer and targetPlayer:IsA("Model") and targetPlayer:FindFirstChild("HumanoidRootPart") then
                        local player_properties = Player.Entity.properties
                        local playerDistance = (player_properties.server_position - ball.Position).Magnitude
                        local targetPosition = targetPlayer.HumanoidRootPart.Position
                        local targetDistance = (player_properties.server_position - targetPosition).Magnitude
                        local ballVelocity = ball.Velocity.Magnitude
                        local ballSpeed = math.max(ballVelocity, 0)
                        local ping = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() / 10
                        local distanceThreshold = 18 + (ping / 80)
                        local ballProperties = Auto_Parry:Get_Ball_Properties() or {}
                        local entityProperties = Auto_Parry:Get_Entity_Properties() or {}

                        ballProperties.speed = ballProperties.speed or ballSpeed
                        ballProperties.maximum_speed = ballProperties.maximum_speed or ballSpeed
                        ballProperties.Distance = ballProperties.Distance or playerDistance
                        ballProperties.parries = ballProperties.parries or Parries
                        ballProperties.last_hit = ballProperties.last_hit or lastHit
                        ballProperties.old_speed = ballProperties.old_speed or oldSpeed
                        ballProperties.auto_spam = ballProperties.auto_spam or false

                        local ping_threshold = math.clamp(ping / 10, 10, 16)
                        local spamAccuracy = ballProperties.maximum_speed / 7.2 + ping_threshold
                        local range = ping_threshold + ballProperties.speed / math.pi

                        if LocalPlayer:GetAttribute("EquippedSword") == "Titan Blade" then
                            range = range + 2
                        end

                        local currentTarget = ball:GetAttribute("target")
                        if currentTarget and currentTarget ~= LocalPlayer.Name then
                            oldFromTarget = currentTarget
                        end

                        if ball:FindFirstChild("AeroDynamicSlashVFX") then
                            Debris:AddItem(ball.AeroDynamicSlashVFX, 0)
                            ballProperties.auto_spam = false
                            ballProperties.aero_dynamic_time = tick()
                        end

                        local function is_spam(params)
                            if not targetPlayer then
                                return false
                            end

                            local speed = params.speed or ballSpeed
                            local spam_accuracy = params.spam_accuracy or spamAccuracy
                            local parries = params.parries or Parries
                            local ball_speed = params.ball_speed or ballSpeed
                            local range = params.range or range
                            local last_hit = params.last_hit or lastHit
                            local ball_distance = params.ball_distance or playerDistance
                            local maximum_speed = params.maximum_speed or ballProperties.maximum_speed
                            local old_speed = params.old_speed or oldSpeed
                            local entity_distance = params.entity_distance or targetDistance
                            local last_position_distance = params.last_position_distance or lastPositionDistance

                            if Parries < 3 and currentTarget == oldFromTarget then
                                return false
                            end
                           
                           if ((ball_distance <= 15) or (entity_distance <= 11)) and (Parries < 1) then
                                 Parries = 0
                                 return false                                                     
                            end

                            local reachTime = ball_distance / math.max(maximum_speed, 1) - (ping / 1000)

                            if (tick() - last_hit) > 0.8 and entity_distance > distanceThreshold and Parries < 3 then
                                Parries = 1
                                return false
                            end

                            if Lerp_Radians > 0.028 then
                                if parries > 3 then
                                    Parries = 1
                                end
                                return false
                            end
                            
                            if Lerp_Radians > 0.018 then
                                if parries > 2 then
                                    Parries = 1
                                end
                                return false
                            end


                            if (tick() - Last_Warping) < (reachTime / 1.3) and entity_distance > distanceThreshold and parries < 4 then
                                if Parries > 3 then
                                    Parries = 1
                                end
                                return false
                            end

                            if math.abs(ball_speed - old_speed) < 5.2 and entity_distance > distanceThreshold and ball_speed < 60 and Parries < 3 then
                                if Parries > 3 then
                                    Parries = 0
                                end
                                return false
                            end

                            if ball_speed < 10 then
                                Parries = 1
                                return false
                            end

                            if maximum_speed < ball_speed and entity_distance > distanceThreshold then
                                Parries = 1
                                return false
                            end

                            if entity_distance > range and entity_distance > distanceThreshold then
                                if Parries > 2 then
                                    Parries = 1
                                end
                                return false
                            end

                            if ball_distance > range and entity_distance > distanceThreshold then
                                if Parries > 2 then
                                    Parries = 2
                                end
                                return false
                            end

                            if last_position_distance > spam_accuracy and entity_distance > distanceThreshold then
                                if Parries > 4 then
                                    Parries = 2
                                end
                                return false
                            end

                            if ball_distance > spam_accuracy and ball_distance > distanceThreshold then
                                if Parries > 3 then
                                    Parries = 2
                                end
                                return false
                            end

                            if entity_distance > spam_accuracy and entity_distance > (distanceThreshold - math.pi) then
                                if Parries > 3 then
                                    Parries = 2
                                end
                                return false
                            end

                            return true
                        end

                        lastPositionDistance = playerDistance
                        ballProperties.old_speed = ballSpeed
                        oldSpeed = ballSpeed

                        local auto_spam = false
                        if currentTarget == LocalPlayer.Name then
                            auto_spam = is_spam({
                                speed = ballProperties.speed,
                                spam_accuracy = spamAccuracy,
                                Parries = Parries,
                                ball_speed = ballProperties.speed,
                                range = range,
                                last_hit = lastHit,
                                ball_distance = playerDistance,
                                maximum_speed = ballProperties.maximum_speed,
                                old_speed = oldSpeed,
                                entity_distance = targetDistance,
                                last_position_distance = lastPositionDistance
                            })
                        end

                        
                        if auto_spam and (zoomies.Parent == ball) and playerDistance <= Distance and targetDistance <= Distance then                                                        
                            Auto_Parry.Parry()
                            Parries = Parries + 1
                            lastHit = tick()
                        else
                            local waitTime = 0
                            repeat
                                task.wait(0.1)
                                waitTime = waitTime + 0.1
                                ball = Auto_Parry.Get_Ball()
                            until (ball and ball:IsDescendantOf(workspace) and (ball.Position.Magnitude > 1)) or (waitTime >= 2.5)
                        end
                    end
                end
            end
            task.wait(0.005)
        end
    end)
    coroutine.resume(autoSpamCoroutine)
    return autoSpamCoroutine
end

local AutoParry = Tabs.Main:AddToggle("AutoParry", {Title = "Auto Parry (Improved)", Default = true})
AutoParry:OnChanged(function(v)
    if v then
        Connections_Manager["Auto Parry"] = AutoParryFunction()
    elseif Connections_Manager["Auto Parry"] then
        Connections_Manager["Auto Parry"]:Disconnect()
        Connections_Manager["Auto Parry"] = nil
    end
end)

local AutoSpam = Tabs.Main:AddToggle("AutoSpam", {Title = "Auto Spam (Update V1)", Default = true})

AutoSpam:OnChanged(function(v)
    if v then
        if autoSpamCoroutine then
            coroutine.resume(autoSpamCoroutine, "stop")
            autoSpamCoroutine = nil
        end
        autoSpamCoroutine = AutoSpamFunction()
    elseif autoSpamCoroutine then
        coroutine.resume(autoSpamCoroutine, "stop")
        autoSpamCoroutine = nil
    end
end)

ManualSpam()
local Toggle = Tabs.Main:AddToggle("MyToggle",
{
    Title = "Manual Spam",
    Description = "Backup For Auto Spam - i do not recommend it bcs high ping",
    Default = false,
    Callback = function()
        ManualSpam()
    end
})
local Toggle = Tabs.Main:AddToggle("MyToggle",
{
    Title = "Ping Based (Removed Into Parry PingBased)",
    Description = "Soon",
    Default = true,
    Callback = function(state)
        pingBased = state
        Auto_Parry.Ping_Based_Spam = state
    end
})

local Dropdown = Tabs.Main:AddDropdown("Dropdown", {
    Title = "Parry Direction/Curve ",
    Description = "Selection Curve to Your Parry (Method Update-1)",
    Values = {"Random", "Backwards", "Straight", "Up", "Right", "Left"},
    Multi = false,
    Default = 3,
    Callback = function(selected)
        Auto_Parry.Parry_Type = selected
    end
})

local SpamSensitivitySlider = Tabs.Main:AddSlider("SpamSensitivity", {
    Title = "Spam Sensitivity",
    Description = "Adjust spam responsiveness, Adjust to 60-70 if Want to be fast",
    Default = 50,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        Auto_Parry.Spam_Sensitivity = Value
    end
})
local nigra = Tabs.Main:AddSlider("bru", {
    Title = "Spam Speed",
    Description = "How fast the speed of manual spam",
    Default = 5,
    Min = 1,
    Max = 20,
    Rounding = 1,
    Callback = function(Value)
        manualSpamSpeed = Value
    end
})
Auto_Parry.Parry_Type = "Default"

local TargetMethodDropdown = Tabs.Main:AddDropdown("TargetMethod", {
    Title = "Target Selection",
    Values = {"ClosestToPlayer", "ClosestToCursor", "Random"},
    Default = 2,
    Multi = false,
    Callback = function(Value)
        TargetSelectionMethod = Value
        CurrentTarget = nil
    end
})
local Section = Tabs.Visual:AddSection("Hit Sound")

local Toaggle = Tabs.Visual:AddToggle("MyaToggle",
{
    Title = "Hit Sound",
    Description = "Play A Sound When U Parry",
    Default = false,
    Callback = function(state)
        Sound_Effect = state
    end
})
local AIaMethodDropdown = Tabs.Visual:AddDropdown("SoundType", {
    Title = "Sound Type",
    Description = "Selecy A Sound To Play",
    Values = {'DC_15X','Neverlose','Minecraft','MinecraftHit2','TeamfortressBonk','TeamfortressBell',"Custom"},
    Default = 1,
    Multi = false,
    Callback = function(Value)
        sound_effect_type = Value
    end
})
Tabs.Visual:AddInput("CustomSoundId", {
    Title = "Custom Sound ID",
    Description = "Play A Custom Sound (Put Sound Type On Custom)",
    Default = CustomId,
    PlaceholderText = "Input Id Only",
    Numeric = true,
    Finished = false,
    Callback = function(text)
        CustomId = text
    end,
    Visible = sound_effect_type == "Custom"
})
local Section = Tabs.Visual:AddSection("Visuals")

local Toggle = Tabs.Visual:AddToggle("MyToggle",
{
    Title = "Visualizer (V1)",
    Description = "Update As well As Good One. ",
    Default = false,
    Callback = function(state)
        visualizerEnabled = state
    end
})

local Section = Tabs.Visual:AddSection("Ball Visuals")
task.defer(function()
    RunService.RenderStepped:Connect(function()
        if spectate_Enabled then
            local self = Auto_Parry.Get_Ball()
            if not self then
                return
            end
            workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame:Lerp(CFrame.new(workspace.CurrentCamera.CFrame.Position, self.Position), 1.5)
        end
    end)
end)

Tabs.Visual:AddToggle("LookToBallToggle", {
    Title = "Look To Ball",
    Description = "Camera always looks at the ball",
    Default = LookToBall,
    Callback = function(state)
        spectate_Enabled = state
    end
})

local function updateBallTrail(ball)
    if not ball then return end
    local trail = ball:FindFirstChild("DarkTrail") or Instance.new("Trail")
    trail.Name = "DarkTrail"
    trail.Parent = ball
    trail.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(75, 0, 130)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(47, 0, 150)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 139))
    })
    trail.LightEmission = 0.1
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    trail.Lifetime = 0.5
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2),
        NumberSequenceKeypoint.new(1, 0)
    })
    trail.Enabled = true
end

local ballProcessingConnection = RunService.Heartbeat:Connect(function()
    local ball = Auto_Parry.Get_Ball()
    if ball and not ball:FindFirstChild("DarkTrail") then
        updateBallTrail(ball)
    end
end)

Tabs.Visual:AddToggle("DarkTrailToggle", {
    Title = "Ball Trails (Not Working)",
    Default = false,
    Callback = function(state)
        for _, ball in pairs(workspace.Balls:GetChildren()) do
            if state then
                updateBallTrail(ball)
            else
                local trail = ball:FindFirstChild("DarkTrail")
                if trail then trail:Destroy() end
            end
        end
    end
})

local originalLightingSettings = {}
local originalPartsSettings = {}

local function optimize(state)
    if state then
        local light = game:GetService("Lighting")
        originalLightingSettings = {
            GlobalShadows = light.GlobalShadows,
            FogEnd = light.FogEnd,
            Brightness = light.Brightness,
            OutdoorAmbient = light.OutdoorAmbient,
            EnvironmentDiffuseScale = light.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = light.EnvironmentSpecularScale,
            ShadowSoftness = light.ShadowSoftness,
            ShadowMapFormat = light.ShadowMapFormat,
            ReflectionEnabled = light.ReflectionEnabled
        }
        local render = game:GetService("RenderSettings")
        render.QualityLevel = 1
        light.GlobalShadows = false
        light.FogEnd = 100000
        light.Brightness = 1
        light.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        light.EnvironmentDiffuseScale = 0
        light.EnvironmentSpecularScale = 0
        light.ShadowSoftness = 0
        light.ShadowMapFormat = Enum.ShadowMapFormat.NoShadows
        light.ReflectionEnabled = false
        for _, obj in pairs(light:GetChildren()) do
            if obj:IsA("Atmosphere") or obj:IsA("Sky") or obj:IsA("Clouds") then
                obj:Destroy()
            end
        end
        if game.Workspace:FindFirstChildOfClass("Terrain") then
            local terrain = game.Workspace:FindFirstChildOfClass("Terrain")
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
            terrain.Decorations = false
            terrain.TreesRequireWaterForGrowth = false
            terrain.TreesMaxCount = 0
        end
        for _, obj in pairs(game:GetDescendants()) do
            if obj:IsA("Explosion") or
               obj:IsA("Fire") or
               obj:IsA("Smoke") or
               obj:IsA("Sparkles") or
               obj:IsA("Trail") or
               obj:IsA("ParticleEmitter") or
               obj:IsA("Beam") or
               obj:IsA("PostEffect") then
                obj:Destroy()
            elseif obj:IsA("Texture") or
                   obj:IsA("Decal") or
                   obj:IsA("SurfaceAppearance") then
                obj:Destroy()
            elseif obj:IsA("BasePart") then
                obj.Material = Enum.Material.Plastic
                obj.Reflectance = 0
                obj.Color = Color3.new(0.5, 0.5, 0.5)
                if obj:IsA("MeshPart") then
                    pcall(function() obj.TextureID = "" end)
                    pcall(function() obj.LevelOfDetail = Enum.MeshLevelOfDetail.Low end)
                end
            end
        end
        game:GetService("RunService").RenderStepped:Connect(function()
            for _, v in pairs(game:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") then
                    v.Enabled = false
                end
            end
        end)
    else
        local light = game:GetService("Lighting")
        for setting, value in pairs(originalLightingSettings) do
            pcall(function()
                light[setting] = value
            end)
        end
        local render = game:GetService("RenderSettings")
        render.QualityLevel = 21
        print("⚠️ Some settings may require game rejoin to fully restore")
    end
end

local Toggle = Tabs.Visual:AddToggle("MegaLagReducer", {
    Title = "Ultra Anti-Lag (Extreme)",
    Description = "Extreme performance mode - removes textures, simplifies materials, and disables all non-essential rendering",
    Default = false,
    Callback = function(state)
        optimize(state)
    end
})

local AntiBan = Tabs.Visual:AddToggle("AntiBan", {
    Title = "Anti Ban (Improved)",
    Description = "Hides script and disables on Wiggity staff detection",
    Default = false,
    Callback = function(state)
        if state then
            print("Anti Ban enabled: Asset obfuscation and Wiggity staff detection active")
            local function randomizeName(obj)
                local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
                local newName = ""
                for _ = 1, 10 do
                    newName = newName .. chars:sub(math.random(1, #chars), math.random(1, #chars))
                end
                obj.Name = newName
            end
            local guiElements = {ManualSpam, playerBillboard, ballBillboard}
            for _, gui in ipairs(guiElements) do
                if gui then
                    randomizeName(gui)
                end
            end
            local coreGui = game:GetService("CoreGui")
            local dummyFolder = Instance.new("Folder")
            randomizeName(dummyFolder)
            dummyFolder.Parent = coreGui
            for _, gui in ipairs(guiElements) do
                if gui then
                    gui.Parent = dummyFolder
                end
            end
            local originalGetUpvalues = debug.getupvalues or function() return {} end
            debug.getupvalues = function(func)
                if tostring(func):lower():find("anticheat") or tostring(func):lower():find("security") then
                    return {}
                end
                return originalGetUpvalues(func)
            end
            local originalGetConstants = debug.getconstants or function() return {} end
            debug.getconstants = function(func)
                if tostring(func):lower():find("anticheat") or tostring(func):lower():find("security") then
                    return {}
                end
                return originalGetConstants(func)
            end
            local networkSent = 0
            local maxNetworkPerSecond = 1000
            local lastNetworkCheck = tick()
            local originalFireServer = Instance.new("RemoteEvent").FireServer
            for remote, _ in pairs(Remotes) do
                if typeof(remote) == "Instance" and remote:IsA("RemoteEvent") then
                    remote.FireServer = function(self, ...)
                        if AntiBan.Value then
                            if tick() - lastNetworkCheck >= 1 then
                                networkSent = 0
                                lastNetworkCheck = tick()
                            end
                            if networkSent >= maxNetworkPerSecond then
                                print("Anti Ban: Network limit reached, delaying remote")
                                task.wait(0.1)
                            end
                            networkSent = networkSent + 10
                        end
                        return originalFireServer(self, ...)
                    end
                end
            end
            local wiggityGroupId = 12836673
            local minStaffRank = 14
            local knownStaff = {"Chunch"}
            local function isWiggityStaff(player)
                if table.find(knownStaff, player.Name) then
                    print("Anti Ban: Staff detected via username (" .. player.Name .. ")")
                    return true
                end
                local success, rank = pcall(function()
                    return player:GetRankInGroup(wiggityGroupId)
                end)
                if success and rank >= minStaffRank then
                    print("Anti Ban: Staff detected via group rank (" .. player.Name .. ", Rank: " .. rank .. ")")
                    return true
                end
                if player:GetAttribute("IsAdmin") or player:GetAttribute("Moderator") or player:GetAttribute("Staff") then
                    print("Anti Ban: Staff detected via attribute (" .. player.Name .. ")")
                    return true
                end
                return false
            end
            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer and isWiggityStaff(player) then
                    print("Anti Ban: Wiggity staff detected (" .. player.Name .. "), disabling script")
                    if AutoParry.Value then
                        AutoParry:SetValue(false)
                    end
                    if AutoSpam.Value then
                        AutoSpam:SetValue(false)
                    end
                    if visualizerEnabled then
                        visualizerEnabled = false
                    end
                    for _, gui in ipairs(guiElements) do
                        if gui then
                            pcall(function() gui:Destroy() end)
                        end
                    end
                    if dummyFolder then
                        pcall(function() dummyFolder:Destroy() end)
                        dummyFolder = nil
                    end
                    game.Players.LocalPlayer:Kick("Wiggity staff detected, exiting for safety")
                    return
                end
            end
            local playerAddedConnection
            playerAddedConnection = game.Players.PlayerAdded:Connect(function(player)
                if AntiBan.Value and player ~= game.Players.LocalPlayer and isWiggityStaff(player) then
                    print("Anti Ban: Wiggity staff detected (" .. player.Name .. "), disabling script")
                    if AutoParry.Value then
                        AutoParry:SetValue(false)
                    end
                    if AutoSpam.Value then
                        AutoSpam:SetValue(false)
                    end
                    if visualizerEnabled then
                        visualizerEnabled = false
                    end
                    for _, gui in ipairs(guiElements) do
                        if gui then
                            pcall(function() gui:Destroy() end)
                        end
                    end
                    if dummyFolder then
                        pcall(function() dummyFolder:Destroy() end)
                        dummyFolder = nil
                    end
                    playerAddedConnection:Disconnect()
                    game.Players.LocalPlayer:Kick("Wiggity staff detected, exiting for safety")
                end
            end)
            local chatConnection
            chatConnection = game.Players.LocalPlayer.Chatted:Connect(function(message)
                if AntiBan.Value and message:lower():find("!ban") or message:lower():find("!kick") or message:lower():find("!admin") or message:lower():find("!mod") then
                    print("Anti Ban: Possible staff command detected, disabling script")
                    if AutoParry.Value then
                        AutoParry:SetValue(false)
                    end
                    if AutoSpam.Value then
                        AutoSpam:SetValue(false)
                    end
                    if visualizerEnabled then
                        visualizerEnabled = false
                    end
                    for _, gui in ipairs(guiElements) do
                        if gui then
                            pcall(function() gui:Destroy() end)
                        end
                    end
                    if dummyFolder then
                        pcall(function() dummyFolder:Destroy() end)
                        dummyFolder = nil
                    end
                    chatConnection:Disconnect()
                    game.Players.LocalPlayer:Kick("Staff command detected, exiting for safety")
                end
            end)
            local cleanupConnection
            cleanupConnection = game:GetService("RunService").Heartbeat:Connect(function()
                if not AntiBan.Value then
                    cleanupConnection:Disconnect()
                    return
                end
                for _, obj in pairs(coreGui:GetChildren()) do
                    if obj:IsA("Folder") and obj ~= dummyFolder then
                        pcall(function() obj:Destroy() end)
                    end
                end
            end)
        else
            print("Anti Ban disabled")
            debug.getupvalues = originalGetUpvalues or debug.getupvalues
            debug.getconstants = originalGetConstants or debug.getconstants
            for remote, _ in pairs(Remotes) do
                if typeof(remote) == "Instance" and remote:IsA("RemoteEvent") then
                    remote.FireServer = originalFireServer
                end
            end
            if dummyFolder then
                pcall(function() dummyFolder:Destroy() end)
                dummyFolder = nil
            end
        end
    end
})

Tabs.Visual:AddButton({
    Title = "Rejoin",
    Description = "",
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game:GetService("Players").LocalPlayer)
    end
})
Tabs.Visual:AddButton({
    Title = "Teleport To Mobile Server",
    Description = "",
    Callback = function()
        TeleportToServer(game.Players.LocalPlayer, 15509350986)
    end
})
Tabs.Visual:AddButton({
    Title = "Teleport To PC Server",
    Description = "",
    Callback = function()
        TeleportToServer(game.Players.LocalPlayer, 14732610803)
    end
})
Tabs.Visual:AddButton({
    Title = "Teleport To VC Server",
    Description = "",
    Callback = function()
        TeleportToServer(game.Players.LocalPlayer, 15131065025)
    end
})

local Section = Tabs.AI:AddSection("AI Play Settings")
local AIPlaying = false
local AICoroutine = nil
local AITarget = nil
local AICurrentMethod = "AdvancedPro"
local AIStuckCheck = {
    lastPosition = Vector3.new(),
    checkTime = 0,
    stuckDuration = 0
}
local AICooldowns = {
    jump = 0,
    dash = 0,
    targetSwitch = 0,
    action = 0
}

local LocalPlayer = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")

local function getValidPlayers()
    local players = {}
    local myPosition = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character.PrimaryPart).Position

    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local primaryPart = player.Character:FindFirstChild("HumanoidRootPart") or player.Character.PrimaryPart
            if primaryPart and primaryPart.Position then
                if myPosition then
                    local direction = (primaryPart.Position - myPosition).Unit
                    local viewVector = (LocalPlayer.Character:GetPrimaryPartCFrame().LookVector).Unit
                    if direction:Dot(viewVector) > math.cos(math.rad(60)) then
                        table.insert(players, {
                            Player = player,
                            Character = player.Character,
                            PrimaryPart = primaryPart,
                            LastPosition = primaryPart.Position,
                            Velocity = primaryPart.AssemblyLinearVelocity
                        })
                    end
                end
            end
        end
    end
    return players
end

local function getSafeBall()
    local success, ball = pcall(function()
        return Auto_Parry and Auto_Parry.Get_Ball()
    end)
    return success and ball or nil
end

local function predictPosition(currentPos, velocity, time)
    return currentPos + (velocity * time)
end

local function isStuck(currentPos)
    if (currentPos - AIStuckCheck.lastPosition).Magnitude < 1.5 then
        AIStuckCheck.stuckDuration += 1
    else
        AIStuckCheck.stuckDuration = 0
    end
    AIStuckCheck.lastPosition = currentPos
    return AIStuckCheck.stuckDuration > 8
end

local function moveToPosition(character, targetPos, aggressive)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local primaryPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
    if not humanoid or not primaryPart then return end

    local direction = (targetPos - primaryPart.Position).Unit
    local distance = (targetPos - primaryPart.Position).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {character}

    local raycastResult = workspace:Raycast(
        primaryPart.Position,
        direction * 8,
        raycastParams
    )

    if raycastResult and raycastResult.Instance then
        if AICooldowns.jump <= 0 and humanoid.FloorMaterial ~= Enum.Material.Air then
            humanoid.Jump = true
            AICooldowns.jump = 0.6 + math.random() * 0.3
        end
    end

    if isStuck(primaryPart.Position) then
        humanoid.Jump = true
        if AICooldowns.dash <= 0 then
            humanoid:MoveTo(primaryPart.Position + (Vector3.new(math.random(-1,1), 0, math.random(-1,1)) * 15))
            AICooldowns.dash = 2 + math.random()
        end
    end

    if aggressive then
        humanoid:MoveTo(targetPos + (direction * 2))
    else
        humanoid:MoveTo(targetPos)
    end
end

local AIMethods = {
    AdvancedPro = function(character)
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local primaryPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        if not humanoid or not primaryPart then return end

        local ball = getSafeBall()
        local validPlayers = getValidPlayers()
        local target = nil

        if ball and (math.random() > 0.4 or #validPlayers == 0) then
            local predictionTime = 0.5 + math.random() * 0.3
            target = {
                Position = predictPosition(ball.Position, ball.Velocity, predictionTime),
                Type = "Ball"
            }
        elseif #validPlayers > 0 then
            if AICooldowns.targetSwitch <= 0 or not AITarget then
                AITarget = validPlayers[math.random(math.max(1, #validPlayers - 2), #validPlayers)]
                AICooldowns.targetSwitch = 2 + math.random() * 2
            end

            if AITarget and AITarget.PrimaryPart then
                local predictionTime = 0.4 + math.random() * 0.2
                target = {
                    Position = predictPosition(AITarget.PrimaryPart.Position, AITarget.Velocity, predictionTime),
                    Type = "Player"
                }
            end
        end

        if target then
            local idealDistance = math.random(8, 15)
            local toTarget = (target.Position - primaryPart.Position)
            local moveToPos = target.Position - (toTarget.Unit * idealDistance)

            local shouldJump = (primaryPart.Position - target.Position).Magnitude < 15
                and (target.Position.Y > primaryPart.Position.Y + 1.5)
                and humanoid.FloorMaterial ~= Enum.Material.Air
                and AICooldowns.jump <= 0

            if shouldJump then
                humanoid.Jump = true
                AICooldowns.jump = 0.8 + math.random() * 0.4
            end

            moveToPosition(character, moveToPos, true)
        else
            local wanderPos = primaryPart.Position + Vector3.new(math.random(-25,25), 0, math.random(-25,25))
            moveToPosition(character, wanderPos, false)
        end
    end,

    BallChaser = function(character)
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local primaryPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        if not humanoid or not primaryPart then return end

        for k, v in pairs(AICooldowns) do
            if v > 0 then AICooldowns[k] = v - 0.1 end
        end

        local ball = getSafeBall()
        if ball then
            local predictedPos = predictPosition(ball.Position, ball.Velocity, 0.5)
            local distance = (predictedPos - primaryPart.Position).Magnitude
            local timeToReach = distance / humanoid.WalkSpeed
            local moveToPos = predictPosition(ball.Position, ball.Velocity, timeToReach * 0.7)

            if (ball.Position - primaryPart.Position).Unit:Dot(ball.Velocity.Unit) > 0.7 then
                moveToPos = ball.Position
            end

            moveToPosition(character, moveToPos, true)

            if distance < 12 and AICooldowns.jump <= 0 then
                humanoid.Jump = true
                AICooldowns.jump = 0.5 + math.random() * 0.3
            end

            if distance > 15 and AICooldowns.dash <= 0 and math.random() > 0.6 then
                humanoid:MoveTo(moveToPos)
                AICooldowns.dash = 2 + math.random()
            end
        else
            AIMethods.AdvancedPro(character)
        end
    end,

    AggressiveHunter = function(character)
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local primaryPart = character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
        if not humanoid or not primaryPart then return end

        for k, v in pairs(AICooldowns) do
            if v > 0 then AICooldowns[k] = v - 0.1 end
        end

        local validPlayers = getValidPlayers()
        if #validPlayers > 0 then
            local closestPlayer = nil
            local closestDistance = math.huge

            for _, player in ipairs(validPlayers) do
                local distance = (primaryPart.Position - player.PrimaryPart.Position).Magnitude
                if distance < closestDistance then
                    closestDistance = distance
                    closestPlayer = player
                end
            end

            if closestPlayer then
                local predictedPos = predictPosition(
                    closestPlayer.PrimaryPart.Position,
                    closestPlayer.Velocity,
                    0.4
                )
                local flankDirection = (primaryPart.Position - predictedPos).Unit:Cross(Vector3.new(0, 1, 0))
                if math.random() > 0.5 then flankDirection = -flankDirection end
                local flankDistance = math.random(4, 10)
                local moveToPos = predictedPos + (flankDirection * flankDistance)

                if closestPlayer.PrimaryPart.Position.Y > primaryPart.Position.Y + 3 then
                    moveToPos = moveToPos + Vector3.new(0, 3, 0)
                end

                moveToPosition(character, moveToPos, true)

                if closestDistance < 15 and AICooldowns.jump <= 0 then
                    humanoid.Jump = math.random() > 0.2
                    AICooldowns.jump = 0.3 + math.random() * 0.2
                end

                if closestDistance > 10 and AICooldowns.dash <= 0 and math.random() > 0.5 then
                    humanoid:MoveTo(predictedPos)
                    AICooldowns.dash = 2 + math.random()
                end
            end
        else
            local wanderPos = primaryPart.Position + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20))
            moveToPosition(character, wanderPos, false)
        end
    end
}

local function runAI()
    local lastUpdate = os.clock()
    while AIPlaying do
        local character = LocalPlayer.Character
        if character then
            local deltaTime = os.clock() - lastUpdate
            lastUpdate = os.clock()
            for k, v in pairs(AICooldowns) do
                AICooldowns[k] = math.max(0, v - deltaTime)
            end
            local success, err = pcall(function()
                if AIMethods[AICurrentMethod] then
                    AIMethods[AICurrentMethod](character)
                end
            end)
            if not success then
                warn("AI Error:", err)
                AICurrentMethod = "AdvancedPro"
            end
        end
        task.wait(0.1 + math.random() * 0.15)
    end
end

local AIToggle = Tabs.AI:AddToggle("AIToggle", {
    Title = "AI Play",
    Default = false,
    Callback = function(state)
        AIPlaying = state
        if AIPlaying then
            if AICoroutine then
                task.cancel(AICoroutine)
            end
            AICoroutine = task.spawn(runAI)
        elseif AICoroutine then
            task.cancel(AICoroutine)
            AICoroutine = nil
        end
    end
})

local AIMethodDropdown = Tabs.AI:AddDropdown("AIMethod", {
    Title = "AI Behavior",
    Values = {"AdvancedNoob", "AdvancedPro", "BallChaser", "AggressiveHunter"},
    Default = "AdvancedPro",
    Multi = false,
    Callback = function(Value)
        AICurrentMethod = Value
        AITarget = nil
    end
})

local AIMovementSpeed = Tabs.AI:AddSlider("AIMovementSpeed", {
    Title = "Movement Speed",
    Description = "How fast the AI moves",
    Default = 32,
    Min = 10,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = Value
            end
        end
    end
})

local AIAggressiveness = Tabs.AI:AddSlider("AIAggressiveness", {
    Title = "Aggressiveness",
    Description = "How aggressive the AI is",
    Default = 70,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        if Value > 80 then
            AICooldowns.jump = AICooldowns.jump * 0.7
            AICooldowns.dash = AICooldowns.dash * 0.7
        elseif Value < 30 then
            AICooldowns.jump = AICooldowns.jump * 1.3
            AICooldowns.dash = AICooldowns.dash * 1.3
        end
    end
})

local AIJumpFrequency = Tabs.AI:AddSlider("AIJumpFrequency", {
    Title = "Jump Frequency",
    Description = "How often the AI jumps",
    Default = 60,
    Min = 10,
    Max = 100,
    Rounding = 0,
    Callback = function(Value)
        local baseCooldown = (100 - Value) / 50
        AICooldowns.jump = math.max(0.3, baseCooldown)
    end
})

if LocalPlayer.Character then
    local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = 40
    end
end

local Section = Tabs.Far:AddSection("Farm Settings")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AutoFarm = false
local AutoFarmType = "UnderBall"
local AutoFarmOrbit = 5
local AutoFarmHeight = 10
local AutoFarmRadius = 10
local AutoFarmConnection = nil
local AutoFarmComplexity = 1

local function get_ball()
    local balls = workspace:FindFirstChild("Balls")
    return balls and balls:FindFirstChildWhichIsA("Part", true) or nil
end

local function get_humanoid_root_part(player)
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function autofarm()
    local player = Players.LocalPlayer
    local ball = get_ball()
    local rootPart = get_humanoid_root_part(player)

    if not ball or not rootPart then return end

    local position = ball.Position
    local angle = tick() * math.pi * 2 / (AutoFarmOrbit / 5)
    local time = tick()

    if AutoFarmType == "UnderBall" then
        rootPart.CFrame = CFrame.new(position - Vector3.new(0, AutoFarmHeight, 0))
    elseif AutoFarmType == "X Orbit" then
        rootPart.CFrame = CFrame.new(position + Vector3.new(
            math.cos(angle) * AutoFarmRadius,
            0,
            math.sin(angle) * AutoFarmRadius
        ))
    elseif AutoFarmType == "Y Orbit" then
        rootPart.CFrame = CFrame.new(position + Vector3.new(
            0,
            math.sin(angle) * AutoFarmRadius,
            math.cos(angle) * AutoFarmRadius
        ))
    elseif AutoFarmType == "Z Orbit" then
        rootPart.CFrame = CFrame.new(position + Vector3.new(
            math.cos(angle) * AutoFarmRadius,
            math.sin(angle) * AutoFarmRadius,
            0
        ))
    elseif AutoFarmType == "Helix" then
        rootPart.CFrame = CFrame.new(position + Vector3.new(
            math.cos(angle) * AutoFarmRadius,
            math.sin(time * AutoFarmComplexity) * AutoFarmHeight,
            math.sin(angle) * AutoFarmRadius
        ))
    elseif AutoFarmType == "Figure8" then
        rootPart.CFrame = CFrame.new(position + Vector3.new(
            math.cos(angle) * AutoFarmRadius,
            0,
            math.sin(2 * angle) * (AutoFarmRadius / 2)
        ))
    elseif AutoFarmType == "Spiral" then
        local spiralRadius = AutoFarmRadius * (1 + math.sin(time * 0.5))
        rootPart.CFrame = CFrame.new(position + Vector3.new(
            math.cos(angle) * spiralRadius,
            time % AutoFarmHeight,
            math.sin(angle) * spiralRadius
        ))
    elseif AutoFarmType == "Random Orbit" then
        rootPart.CFrame = CFrame.new(position + Vector3.new(
            math.noise(time) * AutoFarmRadius,
            math.noise(time + 10) * AutoFarmHeight,
            math.noise(time + 20) * AutoFarmRadius
        ))
    end
end

local function startAutoFarm()
    if AutoFarmConnection then
        AutoFarmConnection:Disconnect()
        AutoFarmConnection = nil
    end

    AutoFarmConnection = RunService.Heartbeat:Connect(function()
        if AutoFarm then
            local success, err = pcall(autofarm)
            if not success then
                warn("AutoFarm Error:", err)
            end
        end
    end)
end

Tabs.Far:AddToggle("AutoFarmToggle", {
    Title = "Auto Farm",
    Description = "Automatically farms balls and slaps the ball (requires Auto Parry)",
    Default = AutoFarm,
    Callback = function(state)
        AutoFarm = state
        if AutoFarm then
            startAutoFarm()
        elseif AutoFarmConnection then
            AutoFarmConnection:Disconnect()
            AutoFarmConnection = nil
        end
    end
})

Tabs.Far:AddDropdown("AutoFarmMode", {
    Title = "Farming Mode",
    Description = "Select farming Mode",
    Values = {"UnderBall", "X Orbit", "Y Orbit", "Z Orbit", "Helix", "Figure8", "Spiral", "Random Orbit"},
    Default = AutoFarmType,
    Callback = function(value)
        AutoFarmType = value
    end
})

Tabs.Far:AddSlider("ComplexitySlider", {
    Title = "Pattern Complexity",
    Description = "Adjust movement complexity for advanced patterns",
    Default = AutoFarmComplexity,
    Min = 1,
    Max = 5,
    Rounding = 1,
    Callback = function(value)
        AutoFarmComplexity = value
    end
})

Tabs.Far:AddSlider("OrbitSpeedSlider", {
    Title = "Orbit Speed",
    Description = "Adjust orbit rotation speed",
    Default = AutoFarmOrbit,
    Min = 1,
    Max = 10,
    Rounding = 1,
    Callback = function(value)
        AutoFarmOrbit = value
    end
})

Tabs.Far:AddSlider("HeightSlider", {
    Title = "UnderBall Height",
    Description = "Adjust height below ball",
    Default = AutoFarmHeight,
    Min = 5,
    Max = 30,
    Rounding = 1,
    Callback = function(value)
        AutoFarmHeight = value
    end
})

Tabs.Far:AddSlider("RadiusSlider", {
    Title = "Orbit Radius",
    Description = "Adjust distance from ball",
    Default = AutoFarmRadius,
    Min = 5,
    Max = 30,
    Rounding = 1,
    Callback = function(value)
        AutoFarmRadius = value
    end
})

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local WS = game:GetService("Workspace")

local FlyEnabled = false
local FlySpeed = 50
local NoclipEnabled = false
local BhopEnabled = false
local AutoJumpEnabled = false
local AntiAFKEnabled = false
local AutoSprintEnabled = false

local connections = {}

Tabs.Misc:AddSlider("WalkSpeed", {
    Title = "Walk Speed",
    Description = "Adjust movement speed",
    Default = 32,
    Min = 0,
    Max = 200,
    Rounding = 0,
    Callback = function(value)
        game.Players.LocalPlayer.Character:WaitForChild("Humanoid").WalkSpeed = value
    end
})

Tabs.Misc:AddSlider("JumpPower", {
    Title = "Jump Power",
    Description = "Adjust jump height",
    Default = 50,
    Min = 0,
    Max = 200,
    Rounding = 0,
    Callback = function(value)
        game.Players.LocalPlayer.Character:WaitForChild("Humanoid").JumpPower = value
    end
})

Tabs.Misc:AddSlider("FOV", {
    Title = "Field of View",
    Description = "Change camera FOV",
    Default = 70,
    Min = 30,
    Max = 120,
    Rounding = 0,
    Callback = function(value)
        Camera.FieldOfView = value
    end
})

Tabs.Misc:AddSlider("Gravity", {
    Title = "Gravity",
    Description = "Adjust world gravity",
    Default = 196.2,
    Min = 0,
    Max = 500,
    Rounding = 1,
    Callback = function(value)
        WS.Gravity = value
    end
})

Tabs.Misc:AddToggle("Bhop", {
    Title = "Bunny Hop/BHOP",
    Description = "Auto jump when touching ground",
    Default = false,
    Callback = function(state)
        BhopEnabled = state
        if state then
            connections.Bhop = Humanoid.StateChanged:Connect(function(_, newState)
                if newState == Enum.HumanoidStateType.Landed then
                    Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            if connections.Bhop then
                connections.Bhop:Disconnect()
            end
        end
    end
})

Tabs.Misc:AddToggle("Fly", {
    Title = "Fly",
    Description = "flight controls (WASD + Space/Shift)",
    Default = false,
    Callback = function(state)
        FlyEnabled = state
        if state then
            local flyVelocity = Vector3.new(0, 0, 0)
            connections.Fly = RunService.Stepped:Connect(function()
                if Character and FlyEnabled then
                    local root = Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        local camera = workspace.CurrentCamera
                        local direction = Vector3.new()
                        if UIS:IsKeyDown(Enum.KeyCode.W) then
                            direction += camera.CFrame.LookVector
                        end
                        if UIS:IsKeyDown(Enum.KeyCode.S) then
                            direction -= camera.CFrame.LookVector
                        end
                        if UIS:IsKeyDown(Enum.KeyCode.D) then
                            direction += camera.CFrame.RightVector
                        end
                        if UIS:IsKeyDown(Enum.KeyCode.A) then
                            direction -= camera.CFrame.RightVector
                        end
                        if UIS:IsKeyDown(Enum.KeyCode.Space) then
                            direction += Vector3.new(0, 1, 0)
                        end
                        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
                            direction -= Vector3.new(0, 1, 0)
                        end
                        direction = direction.Unit * FlySpeed
                        flyVelocity = flyVelocity:Lerp(direction, 0.1)
                        root.Velocity = flyVelocity
                        Humanoid:ChangeState(Enum.HumanoidStateType.Flying)
                    end
                end
            end)
        else
            if connections.Fly then
                connections.Fly:Disconnect()
                Humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end
})

Tabs.Misc:AddToggle("AntiAFK", {
    Title = "Anti-AFK",
    Description = "Prevent being kicked for idling",
    Default = false,
    Callback = function(state)
        AntiAFKEnabled = state
        if state then
            connections.AntiAFK = RunService.Heartbeat:Connect(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                task.wait(1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
            end)
        else
            if connections.AntiAFK then
                connections.AntiAFK:Disconnect()
            end
        end
    end
})

-- Notify Script Loaded
Fluent:Notify({
    Title = "StarX-VicoX Loaded",
    Content = "The script has been loaded successfully.",
    Duration = 8
})

SaveManager:LoadAutoloadConfig()

local function a(b)b.ImageRectOffset=Vector2.new(0,0)b.ImageRectSize=Vector2.new(0,0)end;local c=game:GetService("CoreGui")local d=game:GetService("Players")local e=d.LocalPlayer.PlayerGui;local f=c.TopBarApp.TopBarApp;local g=c.RobloxGui;local h=g.SettingsClippingShield.SettingsShield;local i=h.MenuContainer.HubBar.HubBarContainer;local j=g.SettingsClippingShield.SettingsShield.MenuContainer.PageViewClipper.PageView.PageViewInnerFrame;local k=f.UnibarLeftFrame.UnibarMenu["2"]["3"]:FindFirstChild("chat")local l=f.UnibarLeftFrame.UnibarMenu["2"]["3"].nine_dot.IntegrationIconFrame.IntegrationIcon.Overflow;local m=f.UnibarLeftFrame.UnibarMenu["2"]["3"].nine_dot.IntegrationIconFrame.IntegrationIcon.Close;local n=f.MenuIconHolder.TriggerPoint:GetChildren()[2].ScalingIcon;local o=i.GameSettingsTab.TabLabel.Icon;local p=i.PlayersTab.TabLabel.Icon;local q=i.HelpTab.TabLabel.Icon;local r=i.ReportAbuseTab.TabLabel.Icon;local s=i.CapturesTab.TabLabel.Icon;local t=c:FindFirstChild("PlayerList")local u=f.MenuIconHolder.TriggerPoint:FindFirstChild("BadgeOver12")local v=g:FindFirstChild("EmotesMenu")l.Image="rbxassetid://98028586888500"m.Image="rbxassetid://94533309564837"n.Image="rbxassetid://105822895597231"o.Image="rbxassetid://98893548614397"p.Image="rbxassetid://76913423615046"q.Image="rbxassetid://95611432162764"r.Image="rbxassetid://78743340755719"s.Image="rbxassetid://121273610000891"if t then print("[Debug] playerList?")local w=t:FindFirstChild("Children")and t.Children:FindFirstChild("OffsetFrame")local x=t:FindFirstChild("Children")and t.Children:FindFirstChild("BodyBackground")local y;if w then y=w:FindFirstChild("PlayerScrollList")and w.PlayerScrollList:FindFirstChild("SizeOffsetFrame")and w.PlayerScrollList.SizeOffsetFrame:FindFirstChild("TopRoundedRect")and w.PlayerScrollList.SizeOffsetFrame.TopRoundedRect:FindFirstChild("DismissIconFrame")and w.PlayerScrollList.SizeOffsetFrame.TopRoundedRect.DismissIconFrame:FindFirstChild("DismissButton")end;local z;if x then z=x:FindFirstChild("CloseButton")end;local A=y or z;if A and A:FindFirstChild("imageLabel")then A.imageLabel.Image="rbxassetid://127559608608093"a(A.imageLabel)end end;if u then print("[Debug] checkVNG: Ok")f.MenuIconHolder.TriggerPoint:GetChildren()[3]:Destroy()game:GetService("StarterGui"):SetCore("SendNotification",{Title="Roblox VNG",Text="Phiên bản này sẽ có lỗi xảy ra.",Icon="rbxassetid://127559608608093",Duration=10})else warn("[Debug] checkVNG: Fail")end;if v then print("[Debug] checkEmote: Ok")local B=g.EmotesMenu.Children.Main.EmotesWheel.Back.Background.BackgroundImage;local C=g.EmotesMenu.Children.Main.EmotesWheel.Back.Background.Selection.SelectionEffect.SelectedLine;local D=g.EmotesMenu.Children.Main.EmotesWheel.Back.Background.BackgroundGradient.SelectionGradient.SelectedGradient;a(B)C.Image="rbxassetid://98781576372898"D.Image="rbxassetid://135889668421234"B.Image="rbxassetid://78361502496826"else warn("[Debug] checkEmote: Fail")end;if k then local E=f.UnibarLeftFrame.UnibarMenu["2"]["3"].chat.IntegrationIconFrame.IntegrationIcon;E.Image="rbxassetid://98655444538470"a(E)local F=f.UnibarLeftFrame.UnibarMenu["2"]["3"].chat.IconHitArea_chat;F.MouseButton1Click:Connect(function()local G=c:FindFirstChild("ExperienceChat")if G and G.appLayout.chatInputBar.Visible then E.Image="rbxassetid://98655444538470"E.Size=UDim2.new(0,36,0,36)else E.Image="rbxassetid://136828899568378"E.Size=UDim2.new(0,25,0,25)end end)task.spawn(function()while task.wait(0.25)do a(E)local H=j:FindFirstChild("LeaveGamePage")local I=j:FindFirstChild("ResetCharacter")local J=h.MenuContainer.BottomButtonFrame:FindFirstChild("LeaveGameButtonButton")local K=g:FindFirstChild("Container")local L=j:FindFirstChild("Page")local M=c.ExperienceChat;local N=g:FindFirstChild("Backpack")if N then for O,P in ipairs(N:GetDescendants())do if P:IsA("Frame")and P.Name=="Edge"then P.BackgroundColor3=Color3.fromRGB(170,0,255)end end end;if J then J.Border.Color=Color3.fromRGB(170,0,255)end;if H then local Q=j.LeaveGamePage.LeaveGameText.LeaveButtonContainer;Q.DontLeaveGameButton.Border.Color=Color3.fromRGB(170,0,255)Q.LeaveGameButton.Border.Color=Color3.fromRGB(170,0,255)end;if I then local R=j.ResetCharacter.ResetCharacterText.ResetButtonContainer;R.ResetCharacterButton.Border.Color=Color3.fromRGB(170,0,255)R.DontResetCharacterButton.Border.Color=Color3.fromRGB(170,0,255)end;if K then K.MainContainer.CloseButton.Image="rbxassetid://127559608608093"for O,P in ipairs(K:GetDescendants())do if P:IsA("ImageLabel")and P.Name=="Corner"then P.ImageColor3=Color3.new(0,0,0)elseif P:IsA("ImageLabel")and P.Name=="EquippedFrame"then P.ImageColor3=Color3.fromRGB(170,0,255)end end end;if L then for O,P in ipairs(L:GetDescendants())do if P:IsA("ImageLabel")then if P.Name=="LeftButton"or P.Name=="RightButton"then local S=false;local T=P.Parent;while T do if T.Name=="Background TransparencyFrame"or T.Name=="VolumeFrame"or T.Name=="Graphics QualityFrame"then S=true;break end;T=T.Parent end;if S then if P.Name=="LeftButton"then P.Image="rbxassetid://95487778398461"elseif P.Name=="RightButton"then P.Image="rbxassetid://94389312748073"end else if P.Name=="LeftButton"then P.Image="rbxassetid://74211155409818"elseif P.Name=="RightButton"then P.Image="rbxassetid://97458155273489"end end elseif P.Name=="DropDownImage"then P.Image="rbxassetid://123809289003397"end end end end;if M then local U=M:FindFirstChild("appLayout")and M.appLayout:FindFirstChild("chatWindow")if U then local V=U:FindFirstChild("TopBanner")local W=V and V:FindFirstChild("DotMenu")local X=W and W:FindFirstChild("imageLabel")if X then X.Image="rbxassetid://71408354786707"X.Size=UDim2.new(0,30,0,30)a(X)end end end;local Y=c:FindFirstChild("TopBarApp")and c.TopBarApp:FindFirstChild("TopBarApp")and f:FindFirstChild("UnibarLeftFrame")and c.TopBarApp.TopBarApp.UnibarLeftFrame:FindFirstChild("UnibarMenu")and f.UnibarLeftFrame.UnibarMenu:FindFirstChild("SubMenuHost")if Y and Y:FindFirstChild("nine_dot")then for O,P in ipairs(Y.nine_dot:GetDescendants())do if P:IsA("ImageLabel")and P.Name=="IntegrationIcon"and not P:GetAttribute("ColorChanging")then P:SetAttribute("ColorChanging",true)local Z=game:GetService("TweenService")task.spawn(function()while P and P.Parent do local _=Z:Create(P,TweenInfo.new(0.3,Enum.EasingStyle.Linear),{ImageColor3=Color3.fromRGB(200,100,255)})_:Play()_.Completed:Wait()local a0=Z:Create(P,TweenInfo.new(0.3,Enum.EasingStyle.Linear),{ImageColor3=Color3.fromRGB(170,0,255)})a0:Play()a0.Completed:Wait()end end)end end end end end)end;a(l)a(m)a(n)a(o)a(p)a(q)a(r)a(s)local a1=0;local a2=1;local function a3()for O,a4 in ipairs(game:GetService("CoreGui"):GetDescendants())do if a4:IsA("ScrollingFrame")then if a4.ScrollBarImageColor3~=Color3.fromRGB(170,0,255)then a4.ScrollBarImageColor3=Color3.fromRGB(170,0,255)end end end end;game:GetService("CoreGui").DescendantAdded:Connect(function(a5)local a6=tick()if a6-a1>=a2 then a1=a6;a3()end end)a3()task.spawn(function()while task.wait(0.4)do local a7=j:FindFirstChild("Players")local a8=h.MenuContainer:FindFirstChild("BottomButtonFrame")local a9=h.MenuContainer:FindFirstChild("HubBar")if a7 then for O,P in ipairs(a7:GetDescendants())do if P:IsA("ImageLabel")then if P.Name=="InspectButtonImageLabel"then P.Image="rbxassetid://86129874560283"P.ScaleType=Enum.ScaleType.Stretch;P.ImageRectOffset=Vector2.new(0,0)P.ImageRectSize=Vector2.new(0,0)elseif P.Name=="BlockButtonImageLabel"then P.Image="rbxassetid://80743984746858"P.ScaleType=Enum.ScaleType.Stretch;P.ImageRectOffset=Vector2.new(0,0)P.ImageRectSize=Vector2.new(0,0)elseif P.Name=="ReportPlayerImageLabel"then P.Image="rbxassetid://103113148000709"P.ScaleType=Enum.ScaleType.Stretch;P.ImageRectOffset=Vector2.new(0,0)P.ImageRectSize=Vector2.new(0,0)end elseif P:IsA("ImageButton")then if P.Name=="Inspect"or P.Name=="BlockButton"or P.Name=="ReportPlayer"then P.BackgroundTransparency=1;P.ImageTransparency=1 end end;if P:IsA("UIStroke")and P.Name=="Border"then P.Color=Color3.fromRGB(170,0,255)end;if P:IsA("TextLabel")then if P.Name=="NameLabel"or P.Name=="DisplayNameLabel"or P.Name=="TextLabel"then P.TextColor3=Color3.fromRGB(150,0,200)end end end end;if a8 then for O,P in ipairs(a8:GetDescendants())do if P:IsA("UIStroke")and P.Name=="Border"then P.Color=Color3.fromRGB(170,0,255)end end end;if a9 then for O,P in ipairs(a9:GetDescendants())do if P.Name=="TabSelection"then P.BackgroundColor3=Color3.fromRGB(170,0,255)end end end end end)task.spawn(function()while wait(0.1)do local aa=c:FindFirstChild("GameInvite")if aa then local ab=aa:FindFirstChild("GameInviteModal")if ab then local ac=ab:FindFirstChild("ModalWindowContainer")local ad=ac and ac:FindFirstChild("GameInviteModalContainer")local ae=ad and ad:FindFirstChild("GameInviteContent")local af=ae and ae:FindFirstChild("TitleContainer")local ag=af and af:FindFirstChild("GameInviteTitle")local ah=ag and ag:FindFirstChild("LeftActionContainer")local ai=ah and ah:FindFirstChild("CloseButton")if ai then ai.Image="rbxassetid://94533309564837"a(ai)end;local aj=ag and ag:FindFirstChild("RightActionContainer")if aj then local ak=aj:FindFirstChild("SearchButton")if ak then ak.Image="rbxassetid://109233224447276"a(ak)end;local al=aj:FindFirstChild("ShareGameInviteLink")if al then al.ImageColor3=Color3.fromRGB(170,0,255)end end;local am=ae and ae:FindFirstChild("FriendsList")local an=am and am:FindFirstChild("MainCanvas")if an then for O,P in ipairs(an:GetDescendants())do if P.Name=="Button"then P.ImageColor3=Color3.fromRGB(170,0,255)elseif P.Name=="Text"then P.TextColor3=Color3.fromRGB(170,0,255)local ao=g:FindFirstChild("Backpack")and g.Backpack:FindFirstChild("Hotbar")if ao then for O,ap in ipairs(ao:GetDescendants())do if ap.Name=="Edge"then ap.BackgroundColor3=Color3.fromRGB(170,0,255)end end end end end end end end end end)local aq=game.Players.LocalPlayer:GetMouse()local ar="rbxassetid://113818324753294"local function as(at)for O,P in pairs(at:GetDescendants())do if P:IsA("ImageButton")or P:IsA("TextButton")then P.MouseEnter:Connect(function()aq.Icon=ar end)P.MouseLeave:Connect(function()aq.Icon=ar end)end end end;game.Players.LocalPlayer.PlayerGui.ChildAdded:Connect(function(a5)as(a5)end)as(e)as(c)

print('[!] Loading Succesful!')
