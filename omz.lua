-- KEY SYSTEM V2 UI LIBRARY:
-- UI by mr.xrer | Code by mstudio45

local KeySystemUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MaGiXxScripter0/keysystemv2api/master/ui/xrer_mstudio45.lua"))()
KeySystemUI.New({
    ApplicationName = "WindyHub", -- Your Key System Application Name
    Name = "MeoMeoXHub", -- Your Script name
    Info = "Hello User", -- Info text in the GUI, keep empty for default text.
    DiscordInvite = "", -- Optional.
    AuthType = "clientid" -- Can select verification with ClientId or IP ("clientid" or "ip")
})
repeat task.wait() until KeySystemUI.Finished() or KeySystemUI.Closed
if KeySystemUI.Finished() and KeySystemUI.Closed == false then
    print("Key verified, can load script")
end
		-- main.lua check
			--[[
			local IsRaw = false
			local Range = 1 or 14
			for i, v in next, getconstants(Range) do
				if v == "ТUРLЕ" then
					IsRaw = true
				end
			end
			
			if not IsRaw then
				warn("directly executed")
			end
			--]]
		-- main.lua check
		
		local ArrayField = loadstring(game:HttpGet("https://raw.githubusercontent.com/Hosvile/Refinement/main/MC%3AArrayfield%20Library"))() --Documentation url: https://docs.sirius.menu/community/arrayfield
		
		--Window
		local Window = ArrayField:CreateWindow({
			Name = "MeoMeoX | Blade Ball",
			LoadingTitle = "MeoMeoX | Blade Ball",
			LoadingSubtitle = "by Ghost",
			ConfigurationSaving = {
				Enabled = true,
				FolderName = nil, -- Create a custom folder for your hub/game
				FileName = "MeoMeoX"
			},
			Discord = {
				Enabled = true,
				Invite = "rZKkuzFTsh", -- The Discord invite code, do not include discord.gg/
				RememberJoins = false -- Set this to false to make them join the discord every time they load it up
			},
		})
		
		--Elements
		local Buttons = {}
		local Toggles = {}
		local Dropdowns = {}
		local Inputs = {}
		local Sliders = {}
		local Keybinds = {}
		
		--Services
		local HttpService = game:GetService("HttpService")
		local SocialService = game:GetService("SocialService")
		local StarterGui = game:GetService("StarterGui")
		local RunService = game:GetService("RunService")
		local UserInputService = game:GetService("UserInputService")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Players = game:GetService("Players")
		
		--Scripts
		local VisualCDScript = game.Players.LocalPlayer.PlayerGui.Hotbar.VisualCD
		
		--Remotes
		local ParryRemote
		local ParryButtonRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ParryButtonPress")
		local GetParryAmt = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("getParryAmt")
		local AbilityButtonRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("AbilityButtonPress")
		local Rapture = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlrRaptured")
		local RagingDeflection = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlrRagingDeflectiond")
		local VisualCD = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("VisualCD")
		local VisualBindableCD = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("VisualBindableCD")
		
		local TempSignal
		TempSignal = SocialService.ChildAdded:Connect(function(self)
			if self.Name:match("\n") and self:IsA("RemoteEvent") then
				if not ParryRemote then
					TempSignal:Disconnect(); TempSignal = nil
					
					ParryRemote = self
				end
			end
		end)

		while not ParryRemote do
			task.wait()
		end
		
		--Players
		local LocalPlayer = Players.LocalPlayer
		
		--Input
		local Mouse = LocalPlayer:GetMouse()
		
		--Camera
		local Camera = workspace.CurrentCamera
		
		--Folders
		local Balls = game:GetService("Workspace").Balls
		local PlayerGui = LocalPlayer.PlayerGui
		local Upgrades = LocalPlayer:WaitForChild("Upgrades")
		
		--References
		local Remotes = ReplicatedStorage:WaitForChild("Remotes")
		local Packages = ReplicatedStorage:WaitForChild("Packages")
		
		--Modules
		local Cooldown = Packages:WaitForChild("Cooldown")
		
		--Requires
		local r_Cooldown = require(Cooldown)
		
		--Functions
		
		--[[
		local VisualCDFunction
		
		if getgc and debug and debug.getinfo and getfenv then
			for i, v in pairs(getgc()) do
				if type(v) == "function" and getfenv(v).script == VisualCDScript then
					local name = debug.getinfo(v).name
					if name and name == "visualcd" then
						VisualCDFunction = v
					end
				end
			end
		end
		--]]
		
		--Main
		local Create = {}
		local __Config = {
			DebugMode = false;
			VisualizePath = false;
			SafetyMode = true;
			FastMode = true;
			BeastMode = false;
			AutoParry = true;
			AutoSpamParry = true;
			RageParry = false;
			BlockSpamParry = true;
			BlockMode = "Hold";
			FollowBall = false;
			CurveBall = true;
			FreezeBall = false;
			AimCamera = false;
			AutoMove = false;
			TargetMode = "Last";
			CurvingMode = "Default";
			Random = false;
			Collision = true;
			SpamBind = Enum.KeyCode.V;
			Range = 0.5;
			DirectPoint = 0;
			SpamDistance = 20;
			SpamIteration = 1;
			SpamTimeThreshold = 0.5;
			Debounce = false;
		}
		local Configmt = {__newindex = function(self, key, value)
			--__Config[key] = value
			rawset(self, key, value)
		end}
		local __State = setmetatable({
			DebugMode = false;
			TouchPoints = {};
			VisualizePath = false;
			SafetyMode = true;
			FastMode = true;
			BeastMode = false;
			AutoParry = true;
			AutoSpamParry = true;
			RageParry = false;
			BlockSpamParry = true;
			FollowBall = false;
			CurveBall = true;
			FreezeBall = false;
			AimCamera = false;
			AutoMove = false;
		}, Configmt)
		local __Main = {}
		local __Function = {}
		local __Fire = setmetatable({
			BlockMode = "Hold";
			TargetMode = "Last";
			CurvingMode = "Default";
			Random = false;
		}, Configmt)
		local __Status = {}
		local __Condition = {}
		local __Player = setmetatable({
			Collision = true;
			Ping = 0;
			LastParried = nil;
			SpamBind = Enum.KeyCode.V;
		}, Configmt)
		local __Cam = {}
		local __Ball = setmetatable({
			Velocity = Vector3.new(0, 0, 0);
			LastParried = os.clock();
			IntervalSpawn = 0;
			Range = 0.5;
			DirectPoint = 0;
			SpamDistance = 20;
			SpamIteration = 1;
			SpamTimeThreshold = 0.5;
			ParryCount = 0;
			SpamCount = 0;
			Debounce = false;
			AbilityDebounce = false;
			LastTarget = nil;
			LastTargetParried = false;
			LastSpeed = Vector3.new(0, 0, 0);
		}, Configmt)
		local __Map = {}
		local __Button = {}
		
		local print = print
		local warn = warn
		
		-- Initial
			local OldPrint, OldWarn = print, warn
			DebugMode = function(Value)
				if Value then
					print = OldPrint
					warn = OldWarn
				else
					print = function() end
					warn = function() end
				end
				__Config.DebugMode = Value
			end
			
			-- Load
				if makefolder and isfolder and not isfolder("Infinixity") then
					makefolder("Infinixity")
				end
				
				local path = "Infinixity/BladeBall/"
				
				if isfile and isfile(path .. "config.json") then
					warn("config.json")
					local Config = HttpService:JSONDecode(readfile(path .. "config.json"))
					for Index, Value in pairs(Config) do
						if Value ~= nil then
							if __State[Index] ~= nil and typeof(__State[Index]) ~= "function" then
								__State[Index] = Value
							end
							if __Player[Index] ~= nil and typeof(__Player[Index]) ~= "function" then
								__Player[Index] = Value
							end
							if __Ball[Index] ~= nil and typeof(__Ball[Index]) ~= "function" then
								__Ball[Index] = Value
							end
							if __Fire[Index] ~= nil and typeof(__Fire[Index]) ~= "function" then
								__Fire[Index] = Value
							end
							__Config[Index] = Value
						end
					end
				end
			-- Load
			
			DebugMode(__Config.DebugMode)
			
			function VisualCDFire(Block, Ability, Duration)
				local Ping = game.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000
				
				warn("Block:", Block, "Ability:", Ability, "Duration:", Duration)
				
				if Block and not Duration then
					__Ball.Debounce = false
					print("BlockDebounce false")
				elseif Block and not Ability and Duration then
					__Ball.Debounce = true
					print("BlockDebounce true")
					task.spawn(function()
						local Start = os.clock()
						repeat RunService.PostSimulation:Wait() until os.clock() - Start >= Duration or __Ball.Debounce ~= true
						if os.clock() - Start >= Duration then
							warn("BlockDebounce set to false")
							VisualCDFire(true, nil, nil)
						end
					end)
				elseif Ability and not Duration then
					__Ball.AbilityDebounce = false
					print("AbilityDebounce false")
				elseif Ability and Duration then
					__Ball.AbilityDebounce = true
					print("AbilityDebounce true")
					task.spawn(function()
					local Start = os.clock()
						repeat RunService.PostSimulation:Wait() until os.clock() - Start >= Duration or __Ball.AbilityDebounce ~= true
						if os.clock() - Start >= Duration then
							warn("Abilityebounce set to false")
							VisualCDFire(false, true, nil)
						end
					end)
				end
			end
			
			-- VisualCD.OnClientEvent:Connect(VisualCDFire)
			
			-- VisualBindableCD.Event:Connect(VisualCDFire)
		-- Initial
		
		-- Create
			local DotsFolder = Instance.new("Folder")
			Create.Path = function(self, Ball, Object, Data)
				local DotsFolder = Ball:FindFirstChild("Path")
				if not DotsFolder then
					DotsFolder = Instance.new("Folder")
					DotsFolder.Name = "Path"
					DotsFolder.Parent = Ball
				end
				
				--[[
				for _, Instance in pairs(DotsFolder:GetDescendants()) do
					Instance:Destroy()
				end
				]]
				
				-- Calculate the direction and magnitude of the initial velocity
				local Velocity
				pcall(function()
					Velocity = Velocity or Ball.Velocity
				end)
				if not Velocity then Velocity = __Ball.Velocity end
				local Direction = Velocity.Unit
				local Speed = Velocity.Magnitude
				
				-- Calculate the time of flight using the kinematic equation
				local YOffset = 0 or Object.Position.Y - Ball.Position.Y
				local TimeOfFlight = (Speed + math.sqrt(Speed^2 + 2 * math.abs(YOffset) * 9.81)) / 9.81
				
				-- Calculate the horizontal distance based on the time of flight
				local Distance = (Ball.Position - Object.Position).Magnitude
				local HorizontalDistance = Speed * TimeOfFlight
				
				-- Calculate the number of dots needed based on spacing
				local Dots = HorizontalDistance / Data.Spacing
				local ClampedDots = Distance / Data.Spacing
				
				-- Calculate the time interval between dots
				local TimeInterval = TimeOfFlight / Dots
				
				-- Create the circular dots along the curved path
				for i = 1, ClampedDots do
					-- Calculate the horizontal position at this time interval
					local HorizontalPosition = Direction * (i * Data.Spacing)
				
					-- Calculate the vertical position at this time interval using the kinematic equation
					YOffset = -0.5 * 9.81 * (i * TimeInterval)^2
				
					-- Calculate the total position
					Position = Ball.Position + HorizontalPosition + Vector3.new(0, YOffset, 0)
					
					-- Create a circular dot
					local Dot = DotsFolder:FindFirstChild(("Dot %d"):format(i))
					if Dot then
						Dot.Position = Position
					else
						Dot = Instance.new("Part")
						Dot.Name = ("Dot %d"):format(i)
						Dot.Size = Vector3.new(Data.Radius * 2, Data.Radius * 2, Data.Radius* 2)
						Dot.Shape = Enum.PartType.Ball -- Use the Ball shape for a circle
						Dot.Position = Position
						Dot.Anchored = true
						Dot.CanCollide = false
						Dot.Transparency = ((i+1) / (ClampedDots*1)) + 0.1
						Dot.Material = "Neon"
						Dot.BrickColor = BrickColor.new("Bright red") -- Adjust color as needed
						Dot.Parent = DotsFolder
					end
				end
			end
		-- Create
		
		--__Function
			__Function.RandomString = function(self, Length)
				local Array = {}
				for i = 1, Length do
				Array[i] = string.char(math.random(32, 126))
				end
				return table.concat(Array)
			end
			
			__Function.Random = function(self, Choices)
				local Sum = 0
				for _, Choice in next, Choices do
					Sum = Sum + Choice.Weight
				end
				Sum = math.random(0, Sum)
				for _, Choice in next, Choices do
					Sum = Sum - Choice.Weight
					if Sum <= 0 then
						return Choice.Value
					end
				end
			end
			
			local CharacterAddedFunctions = {}
			__Function.CharacterAdded = function(self, Character, Func, Fire)
				CharacterAddedFunctions[#CharacterAddedFunctions + 1] = Func
				if Fire then Func(Character) end
			end
			
			__Function.CharacterDied = function(self, Character, Func, Fire)
				local Index = #CharacterAddedFunctions + 1
				CharacterAddedFunctions[Index] = function(Character)
					local Humanoid = Character:WaitForChild("Humanoid")
					if Humanoid and Humanoid:IsA("Humanoid") then
						Humanoid.Died:Connect(Func)
					end
				end
				
				if Fire then CharacterAddedFunctions[Index](Character) end
			end
			
			__Function.Fire = function(self, Remote, ...)
				if Remote:IsA("RemoteEvent") then
					Remote:FireServer(...)
				elseif Remote:IsA("BindableEvent") then
					Remote:Fire(...)
				end
			end
		--__Function
		
		--__Fire
			local Prioritize = false
			__Fire.Parry = function(self, Bool)
				if Bool then
					--__Function:Fire(ParryButtonRemote)
				elseif __Player:Ability("Rapture") and not __Ball.AbilityDebounce then
					local args, Object = {}
					args[2] = __Cam:PlayerPoints()
					
					if __Fire.TargetMode == "Nearest to Mouse" then
						Object = __Player:HumanoidRootPart(__Player:Nearest())
					elseif __Fire.TargetMode == "Last Targeted Player" then
						Object = __Player:HumanoidRootPart(__Ball.LastTarget)
					elseif __Fire.TargetMode == "Closest Player" then
						Object = __Player:HumanoidRootPart(__Player:Closest())
					elseif __Fire.TargetMode == "Furthest Player" then
						Object = __Player:HumanoidRootPart(__Player:Furthest())
					elseif __Fire.TargetMode == "Weakest Player" then
						Object = __Player:HumanoidRootPart(__Player:Weakest())
					elseif __Fire.TargetMode == "Strongest Player" then
						Object = __Player:HumanoidRootPart(__Player:Strongest())
					end
					
					if Object then
						WorldToScreenPoint = Camera:WorldToScreenPoint(Object.Position)
						args[3] = {WorldToScreenPoint.X, WorldToScreenPoint.Y}
					end
					
					if not args[3] then
						args[3] = {Mouse.X, Mouse.Y}
					end
					
					if __State.CurveBall then
						args[1] = __Cam:Angle(__Fire.CurvingMode, __Player:HumanoidRootPart(LocalPlayer), Object)
					else
						args[1] = Camera.CFrame
					end
					
					Prioritize = true
					task.spawn(function()
						local Start = os.clock()
						local Humanoid = __Player:Humanoid(LocalPlayer)
						repeat task.wait() until Humanoid and Humanoid.WalkSpeed > 0 or os.clock() - Start >= 1
						if Humanoid and Humanoid.WalkSpeed > 0 or os.clock() - Start >= 1 then
							Prioritize = false
						end
					end)
					
					VisualCDFire(false, true, 35)
					__Function:Fire(Rapture, unpack(args))
				elseif __Player:Ability("Raging Deflection") and not __Ball.AbilityDebounce then
					local args, Object = {}
					args[2] = __Cam:PlayerPoints()
					
					if __Fire.TargetMode == "Nearest to Mouse" then
						Object = __Player:HumanoidRootPart(__Player:Nearest())
					elseif __Fire.TargetMode == "Last Targeted Player" then
						Object = __Player:HumanoidRootPart(__Ball.LastTarget)
					elseif __Fire.TargetMode == "Closest Player" then
						Object = __Player:HumanoidRootPart(__Player:Closest())
					elseif __Fire.TargetMode == "Furthest Player" then
						Object = __Player:HumanoidRootPart(__Player:Furthest())
					elseif __Fire.TargetMode == "Weakest Player" then
						Object = __Player:HumanoidRootPart(__Player:Weakest())
					elseif __Fire.TargetMode == "Strongest Player" then
						Object = __Player:HumanoidRootPart(__Player:Strongest())
					end
					
					if Object then
						WorldToScreenPoint = Camera:WorldToScreenPoint(Object.Position)
						args[3] = {WorldToScreenPoint.X, WorldToScreenPoint.Y}
					end
					
					if not args[3] then
						args[3] = {Mouse.X, Mouse.Y}
					end
					
					if __State.CurveBall then
						args[1] = __Cam:Angle(__Fire.CurvingMode, __Player:HumanoidRootPart(LocalPlayer), Object)
					else
						args[1] = Camera.CFrame
					end
					
					Prioritize = true
					task.spawn(function()
						local Start = os.clock()
						local Humanoid = __Player:Humanoid(LocalPlayer)
						repeat task.wait() until Humanoid and Humanoid.WalkSpeed > 0 or os.clock() - Start >= 1
						if Humanoid and Humanoid.WalkSpeed > 0 or os.clock() - Start >= 1 then
							Prioritize = false
						end
					end)
					
					VisualCDFire(false, true, 35)
					__Function:Fire(RagingDeflection, unpack(args))
				elseif __Fire.TargetMode and not Prioritize then
					local args, Object = {}
					args[1] = 1.5
					args[3] = __Cam:PlayerPoints()
					
					if __Fire.TargetMode == "Nearest to Mouse" then
						Object = __Player:HumanoidRootPart(__Player:Nearest())
					elseif __Fire.TargetMode == "Last Targeted Player" then
						Object = __Player:HumanoidRootPart(__Ball.LastTarget)
					elseif __Fire.TargetMode == "Closest Player" then
						Object = __Player:HumanoidRootPart(__Player:Closest())
					elseif __Fire.TargetMode == "Furthest Player" then
						Object = __Player:HumanoidRootPart(__Player:Furthest())
					elseif __Fire.TargetMode == "Weakest Player" then
						Object = __Player:HumanoidRootPart(__Player:Weakest())
					elseif __Fire.TargetMode == "Strongest Player" then
						Object = __Player:HumanoidRootPart(__Player:Strongest())
					end
					
					if Object then
						WorldToScreenPoint = Camera:WorldToScreenPoint(Object.Position)
						warn("Found Object", __Fire.TargetMode)
						args[4] = {WorldToScreenPoint.X, WorldToScreenPoint.Y}
						warn("WorldToScreenPoint:", WorldToScreenPoint.X, WorldToScreenPoint.Y)
					end
					
					if not args[4] then
						args[4] = {Mouse.X, Mouse.Y}
					end
					
					if __State.CurveBall then
						args[2] = __Cam:Angle(__Fire.CurvingMode, __Player:HumanoidRootPart(LocalPlayer), Object)
					else
						args[2] = Camera.CFrame
					end
					
					VisualCDFire(true, nil, 1.3)
					__Function:Fire(ParryRemote, unpack(args))
				else
					--__Function:Fire(ParryButtonRemote)
				end
			end
		--__Fire
		
		--__Status
			__Status.Standoff = function(self)
				return #workspace.Alive:GetChildren() == 2
			end
		--__Status
		
		--__Condition
			__Condition.Child = function(self, Parent, Child)
				return Parent and Parent:FindFirstChild(Child)
			end
		--__Condition
		
		--__Player
			__Player.Humanoid = function(self, Player)
				local Humanoid = Player and Player:IsA("Player") and Player.Character and Player.Character:FindFirstChildWhichIsA("Humanoid") or Player and Player:IsA("Actor") and Player:FindFirstChildWhichIsA("Humanoid")
				return Humanoid
			end
			
			__Player.HumanoidRootPart = function(self, Player)
				local Humanoid = __Player:Humanoid(Player)
				return Humanoid and Humanoid.RootPart
			end
			
			__Player.Alive = function(self, Player)
				Player = Player or LocalPlayer
				Player = workspace.Alive:FindFirstChild(Player.Name)
				local Humanoid = Player and Player.PrimaryPart and Player:FindFirstChildWhichIsA("Humanoid")
				return Humanoid and (Humanoid.Health > 0 or Humanoid.Parent:FindFirstChild("Highlight"))
			end
			
			__Player.Playing = function(self)
				local Alive = 0
				for _, Player in pairs(workspace.Alive:GetChildren()) do
					Player = Players:FindFirstChild(Player.Name)
					local Humanoid = Player and __Player:Humanoid(Player)
					if Humanoid and Humanoid.Health > 0 then
						Alive = Alive + 1
					end
				end
				return Alive > 0
			end
			
			__Player.Ability = function(self, Name)
				local Ability = LocalPlayer.Character and __Condition:Child(LocalPlayer.Character.Abilities, Name)
				if Ability and Ability.Enabled then
					return true
				end
			end
			
			__Player.Frozen = function(self)
				local Humanoid = __Player:Humanoid(LocalPlayer)
				return Humanoid and Humanoid.WalkSpeed <= 0
			end
			
			local CanCollideSignal
			__Pla
