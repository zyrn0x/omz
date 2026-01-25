--[[
    OMZ HUB — THE ULTIMATE BLADE BALL SOLUTION
    Creator: Omz (by Antigravity)
    "Zero Miss. Absolute Science. GOD-MODE."
]]

repeat task.wait() until game:IsLoaded()

-- // SERVICES & GLOBALS
local cloneref = (cloneref or clonereference or function(instance) return instance end)
local Players = cloneref(game:GetService('Players'))
local ReplicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local UserInputService = cloneref(game:GetService('UserInputService'))
local RunService = cloneref(game:GetService('RunService'))
local TweenService = cloneref(game:GetService('TweenService'))
local Stats = cloneref(game:GetService('Stats'))
local Debris = cloneref(game:GetService('Debris'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Lighting = cloneref(game:GetService('Lighting'))

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end

local Alive = workspace:FindFirstChild("Alive") or workspace:WaitForChild("Alive")
local Runtime = workspace.Runtime

-- // SYSTEM STATE
local System = {
    __properties = {
        __autoparry_enabled = false,
        __auto_spam_enabled = false,
        __autoplay_enabled = false,
        __prediction_enabled = true,
        __is_mobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled,
        __accuracy = 100,
        __prediction_ms = 0,
        __spam_rate = 240,
        __curve_mode = 1,
        __ball_history = {},
        __connections = {},
        __fps = 60,
        __tornado_time = tick(),
        __spam_accumulator = 0,
        __phantom_enabled = false,
        __ball_tp_enabled = false,
        __visuals_enabled = false
    },
    __config = {
        __curve_names = {'Camera', 'Random', 'Accelerated', 'Backwards', 'Slow', 'High'},
        __detections = {
            __infinity = true,
            __deathslash = true,
            __slashesoffury = true,
            __timehole = true
        }
    },
    autoparry = {},
    auto_spam = {},
    ball = {},
    physics = {},
    player = {},
    extra = {},
}

-- // CORE UTILS
local function get_ping() return Stats.Network.ServerStatsItem['Data Ping']:GetValue() / 1000 end
local function get_fps() return System.__properties.__fps or 60 end
RunService.Heartbeat:Connect(function(dt) System.__properties.__fps = 1/dt end)

function System.ball.get()
    local b = workspace:FindFirstChild('Balls')
    if not b then return nil end
    for _, ball in pairs(b:GetChildren()) do
        if ball:GetAttribute('realBall') then return ball end
    end
end

function System.ball.get_all()
    local t = {}
    local b = workspace:FindFirstChild('Balls')
    if not b then return t end
    for _, ball in pairs(b:GetChildren()) do
        if ball:GetAttribute('realBall') then table.insert(t, ball) end
    end
    return t
end

function System.player.get_closest()
    local max = math.huge; local closest = nil
    for _, entity in pairs(Alive:GetChildren()) do
        if entity ~= LocalPlayer.Character and entity.PrimaryPart then
            local d = (LocalPlayer.Character.PrimaryPart.Position - entity.PrimaryPart.Position).Magnitude
            if d < max then max = d; closest = entity end
        end
    end
    return closest
end

-- // SCIENCE ENGINE (TTI / CPA / PREDICTION)
function System.physics.analyze(ball)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false, 999 end
    
    local hrp = char.HumanoidRootPart
    local my_pos = hrp.Position
    local zoomies = ball:FindFirstChild('zoomies')
    if not zoomies then return false, 999 end
    
    local velocity = zoomies.VectorVelocity
    local speed = velocity.Magnitude
    if speed < 0.1 then return false, 999 end
    
    local ball_pos = ball.Position
    local to_me = (my_pos - ball_pos)
    local distance = to_me.Magnitude
    
    -- Memory & Curve Check
    local memory = System.__properties.__ball_history[ball]
    if not memory then
        System.__properties.__ball_history[ball] = { velocities = {}, warping = tick() }
        memory = System.__properties.__ball_history[ball]
    end
    table.insert(memory.velocities, velocity)
    if #memory.velocities > 5 then table.remove(memory.velocities, 1) end
    
    if #memory.velocities >= 3 then
        local last_v = memory.velocities[#memory.velocities-1]
        if velocity.Unit:Dot(last_v.Unit) < 0.98 then memory.warping = tick() end
    end
    
    -- CPA (Closest Point of Approach)
    local t = to_me:Dot(velocity) / (speed * speed)
    local closest_point = ball_pos + (velocity * t)
    local cpa_dist = (my_pos - closest_point).Magnitude
    
    local target = ball:GetAttribute("target")
    local is_target = target == LocalPlayer.Name
    
    -- Decision Logic
    local score = 0
    if is_target then score = score + 65 end
    if cpa_dist < 5.2 then score = score + 40 end -- Surgical interception zone
    if (tick() - memory.warping) < 0.15 then score = score + 25 end -- High threat due to curve
    
    local tti = distance / speed
    return score >= 60, tti, speed
end

-- // COMBAT LOOPS
local Last_Ball, Last_Target = nil, nil

function System.autoparry.start()
    if System.__properties.__connections.parry then System.__properties.__connections.parry:Disconnect() end
    System.__properties.__connections.parry = RunService.PreRender:Connect(function(dt)
        if not System.__properties.__autoparry_enabled or not LocalPlayer.Character then return end
        
        local balls = System.ball.get_all()
        local ping, fps = get_ping(), get_fps()
        local acc = System.__properties.__accuracy
        
        -- Master Timing Formula
        local threshold = ping + (1/fps) + 0.02 + ((100 - acc) / 100) * 0.28
        threshold = threshold + (System.__properties.__prediction_ms / 1000)

        for _, ball in pairs(balls) do
            local threat, tti, speed = System.physics.analyze(ball)
            if not threat then continue end
            
            -- Ability Anti-Trap
            if ball:FindFirstChild('AeroDynamicSlashVFX') then System.__properties.__tornado_time = tick() end
            if (tick() - System.__properties.__tornado_time) < 1.2 then continue end
            
            -- Reset Safety
            local target = ball:GetAttribute("target")
            if Last_Ball == ball and target == Last_Target then continue end
            
            -- Speed-Compensated TTI
            local final_thresh = threshold + math.clamp(speed/1500, 0, 0.05)

            if tti <= final_thresh then
                Last_Ball, Last_Target = ball, target
                game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.F, false, game)
            end
        end
        
        for _, ball in pairs(balls) do
            if Last_Ball == ball and ball:GetAttribute("target") ~= Last_Target then
                Last_Ball, Last_Target = nil, nil
            end
        end
    end)
end

function System.auto_spam.start()
    if System.__properties.__connections.spam then System.__properties.__connections.spam:Disconnect() end
    System.__properties.__connections.spam = RunService.PostSimulation:Connect(function(dt)
        if not System.__properties.__auto_spam_enabled then return end
        local ball = System.ball.get(); local entity = System.player.get_closest()
        if not ball or not entity or not entity.PrimaryPart then return end
        
        local dist_b = (LocalPlayer.Character.PrimaryPart.Position - ball.Position).Magnitude
        local dist_e = (LocalPlayer.Character.PrimaryPart.Position - entity.PrimaryPart.Position).Magnitude
        
        local speed = ball:FindFirstChild('zoomies') and ball.zoomies.VectorVelocity.Magnitude or 0
        local thresh = math.clamp(12 + (speed / 20) + (get_ping() * 15), 10, 85)
        thresh = thresh * (0.5 + (System.__properties.__accuracy / 100))

        if dist_b < thresh and dist_e < thresh then
            System.__properties.__spam_accumulator = System.__properties.__spam_accumulator + dt
            if System.__properties.__spam_accumulator >= (1 / System.__properties.__spam_rate) then
                System.__properties.__spam_accumulator = 0
                game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.F, false, game)
            end
        end
    end)
end

-- // ELITE MODS (TP, Phantom, AI)
function System.extra.start_phantom()
    if System.__properties.__connections.phantom then System.__properties.__connections.phantom:Disconnect() end
    System.__properties.__connections.phantom = RunService.Heartbeat:Connect(function()
        if not System.__properties.__phantom_enabled then return end
        local ball = System.ball.get(); local char = LocalPlayer.Character
        if ball and char and ball:GetAttribute("target") == LocalPlayer.Name then
            local dist = (ball.Position - char.PrimaryPart.Position).Magnitude
            if dist < 45 then
                char.Humanoid:Move((char.PrimaryPart.CFrame.RightVector * (math.sin(tick() * 15) * 25)), false)
            end
        end
    end)
end

function System.extra.start_ball_tp()
    if System.__properties.__connections.tp then System.__properties.__connections.tp:Disconnect() end
    System.__properties.__connections.tp = RunService.RenderStepped:Connect(function()
        if not System.__properties.__ball_tp_enabled then return end
        local ball = System.ball.get(); local char = LocalPlayer.Character
        if ball and char and char:FindFirstChild("RootPart") then
            local vel = ball:FindFirstChild('zoomies') and ball.zoomies.VectorVelocity or Vector3.zero
            local offset = Vector3.new(-vel.Z, 0, vel.X).Unit * 12
            char.PrimaryPart.CFrame = CFrame.new(ball.Position + offset + Vector3.new(0, 5, 0), ball.Position)
        end
    end)
end

-- // PATHFINDING (AUTO PLAY)
local PathAI = { last_update = 0 }
function PathAI.get_target()
    local ball = System.ball.get()
    local floor = workspace:FindFirstChild("FLOOR") or (function() for _,v in pairs(workspace:GetDescendants()) do if v:IsA("BasePart") and v.Size.X > 50 and v.Position.Y < 5 then return v end end end)()
    if not ball or not floor then return nil end
    local vel = ball.zoomies.VectorVelocity; local dir = vel.Unit
    local target = floor.Position - (dir * (40 + (vel.Magnitude / 22)))
    return target + (Vector3.new(-dir.Z, 0, dir.X) * 15)
end

RunService.Heartbeat:Connect(function()
    if not System.__properties.__autoplay_enabled then return end
    if tick() - PathAI.last_update < 1/12 then return end
    PathAI.last_update = tick()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Humanoid") then return end
    if char.Parent == workspace:FindFirstChild("Dead") then
        pcall(function() ReplicatedStorage.Packages._Index["sleitnick_net@0.1.0"].net["RE/UpdateVotes"]:FireServer("FFA") end)
        local pads = workspace:FindFirstChild("Spawn") and workspace.Spawn.NewPlayerCounter.Colliders
        if pads then local p = pads:FindFirstChild("1") or pads:GetChildren()[1]; char.Humanoid:MoveTo(p.Position) end
        return
    end
    local pos = PathAI.get_target(); if pos then char.Humanoid:MoveTo(pos) end
end)

-- // UI RECONSTRUCTION (OMZ HUB)
task.defer(function()
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "Omz Hub — GOD-TIER",
    Icon = "solar:star-bold",
    Author = "by Omz",
    Folder = "OmzHub",
    NewElements = true,
})

Window:Tag({ Title = "COMMERCIAL RELEASE", Icon = "zap", Color = Color3.fromRGB(255, 0, 100), Border = true })

local Main = Window:Tab({ Title = "Combat", Icon = "solar:shield-bold" })
local Elite = Window:Tab({ Title = "Elite AI", Icon = "solar:star-bold" })
local Visual = Window:Tab({ Title = "Visuals", Icon = "solar:eye-bold" })

local PSec = Main:Section({ Title = "Auto Parry" })
PSec:Toggle({ Title = "Scientific Auto Parry", Default = false, Callback = function(v) System.__properties.__autoparry_enabled = v; if v then System.autoparry.start() end end })
PSec:Slider({ Title = "Accuracy (100 = Final Moment)", Value = { Min = 1, Max = 100, Default = 100 }, Callback = function(v) System.__properties.__accuracy = v end })
PSec:Slider({ Title = "Prediction Offset", Value = { Min = -50, Max = 150, Default = 0 }, Callback = function(v) System.__properties.__prediction_ms = v end })

local SSec = Main:Section({ Title = "Auto Spam" })
SSec:Toggle({ Title = "Rage Auto Spam", Default = false, Callback = function(v) System.__properties.__auto_spam_enabled = v; if v then System.auto_spam.start() end end })
SSec:Slider({ Title = "Spam TPS", Value = { Min = 10, Max = 500, Default = 240 }, Callback = function(v) System.__properties.__spam_rate = v end })

local AESec = Elite:Section({ Title = "Auto Play" })
AESec:Toggle({ Title = "GOD-MODE Auto Play", Default = false, Callback = function(v) System.__properties.__autoplay_enabled = v end })
AESec:Toggle({ Title = "Phantom Evasion", Default = false, Callback = function(v) System.__properties.__phantom_enabled = v; if v then System.extra.start_phantom() end end })
AESec:Toggle({ Title = "Ball TP", Default = false, Callback = function(v) System.__properties.__ball_tp_enabled = v; if v then System.extra.start_ball_tp() end end })

local VSec = Visual:Section({ Title = "Effects" })
VSec:Toggle({ Title = "Elite Trails & Glow", Default = false, Callback = function(v) System.__properties.__visuals_enabled = v end })
VSec:Button({ Title = "FPS Boost (Kill Textures)", Callback = function() for _,v in pairs(workspace:GetDescendants()) do if v:IsA("Texture") or v:IsA("Decal") then v:Destroy() end end end })

WindUI:Notify({ Title = "Omz Hub Ready", Content = "Loaded. Master Scientfic Logic Active.", Duration = 5 })
end)
