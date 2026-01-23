
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

assert(getrawmetatable)
grm = getrawmetatable(game)
setreadonly(grm, false)
old = grm.__namecall
grm.__namecall = newcclosure(function(self, ...)
    local args = {...}
    if tostring(args[1]) == "TeleportDetect" then
        return
    elseif tostring(args[1]) == "CHECKER_1" then
        return
    elseif tostring(args[1]) == "CHECKER" then
        return
    elseif tostring(args[1]) == "GUI_CHECK" then
        return
    elseif tostring(args[1]) == "OneMoreTime" then
        return
    elseif tostring(args[1]) == "checkingSPEED" then
        return
    elseif tostring(args[1]) == "BANREMOTE" then
        return
    elseif tostring(args[1]) == "PERMAIDBAN" then
        return
    elseif tostring(args[1]) == "KICKREMOTE" then
        return
    elseif tostring(args[1]) == "BR_KICKPC" then
        return
    elseif tostring(args[1]) == "BR_KICKMOBILE" then
        return
    end
    return old(self, ...)
end)

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
local old_Omz = CoreGui:FindFirstChild('Omz')

if old_Omz then
    Debris:AddItem(old_Omz, 0)
end

if not isfolder("Omz") then
    makefolder("Omz")
end


local Connections = setmetatable({
    disconnect = function(self, connection)
        if not self[connection] then
            return
        end
    
        self[connection]:Disconnect()
        self[connection] = nil
    end,
    disconnect_all = function(self)
        for _, value in self do
            if typeof(value) == 'function' then
                continue
            end
    
            value:Disconnect()
        end
    end
}, Connections)


local Util = setmetatable({
    map = function(self: any, value: number, in_minimum: number, in_maximum: number, out_minimum: number, out_maximum: number)
        return (value - in_minimum) * (out_maximum - out_minimum) / (in_maximum - in_minimum) + out_minimum
    end,
    viewport_point_to_world = function(self: any, location: any, distance: number)
        local unit_ray = workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)

        return unit_ray.Origin + unit_ray.Direction * distance
    end,
    get_offset = function(self: any)
        local viewport_size_Y = workspace.CurrentCamera.ViewportSize.Y

        return self:map(viewport_size_Y, 0, 2560, 8, 56)
    end
}, Util)


local AcrylicBlur = {}
AcrylicBlur.__index = AcrylicBlur


function AcrylicBlur.new(object: GuiObject)
    local self = setmetatable({
        _object = object,
        _folder = nil,
        _frame = nil,
        _root = nil
    }, AcrylicBlur)

    self:setup()

    return self
end


function AcrylicBlur:create_folder()
    local old_folder = workspace.CurrentCamera:FindFirstChild('AcrylicBlur')

    if old_folder then
        Debris:AddItem(old_folder, 0)
    end

    local folder = Instance.new('Folder')
    folder.Name = 'AcrylicBlur'
    folder.Parent = workspace.CurrentCamera

    self._folder = folder
end


function AcrylicBlur:create_depth_of_fields()
    local depth_of_fields = Lighting:FindFirstChild('AcrylicBlur') or Instance.new('DepthOfFieldEffect')
    depth_of_fields.FarIntensity = 0
    depth_of_fields.FocusDistance = 0.05
    depth_of_fields.InFocusRadius = 0.1
    depth_of_fields.NearIntensity = 1
    depth_of_fields.Name = 'AcrylicBlur'
    depth_of_fields.Parent = Lighting

    for _, object in Lighting:GetChildren() do
        if not object:IsA('DepthOfFieldEffect') then
            continue
        end

        if object == depth_of_fields then
            continue
        end

        Connections[object] = object:GetPropertyChangedSignal('FarIntensity'):Connect(function()
            object.FarIntensity = 0
        end)

        object.FarIntensity = 0
    end
end


function AcrylicBlur:create_frame()
    local frame = Instance.new('Frame')
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Parent = self._object

    self._frame = frame
end


function AcrylicBlur:create_root()
    local part = Instance.new('Part')
    part.Name = 'Root'
    part.Color = Color3.new(0, 0, 0)
    part.Material = Enum.Material.Glass
    part.Size = Vector3.new(1, 1, 0)  -- Use a thin part
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Locked = true
    part.CastShadow = false
    part.Transparency = 0.98
    part.Parent = self._folder

    -- Create a SpecialMesh to simulate the acrylic blur effect
    local specialMesh = Instance.new('SpecialMesh')
    specialMesh.MeshType = Enum.MeshType.Brick  -- Use Brick mesh or another type suitable for the effect
    specialMesh.Offset = Vector3.new(0, 0, -0.000001)  -- Small offset to prevent z-fighting
    specialMesh.Parent = part

    self._root = part  -- Store the part as root
end


function AcrylicBlur:setup()
    self:create_depth_of_fields()
    self:create_folder()
    self:create_root()
    
    self:create_frame()
    self:render(0.001)

    self:check_quality_level()
end


function AcrylicBlur:render(distance: number)
    local positions = {
        top_left = Vector2.new(),
        top_right = Vector2.new(),
        bottom_right = Vector2.new(),
    }

    local function update_positions(size: any, position: any)
        positions.top_left = position
        positions.top_right = position + Vector2.new(size.X, 0)
        positions.bottom_right = position + size
    end

    local function update()
        local top_left = positions.top_left
        local top_right = positions.top_right
        local bottom_right = positions.bottom_right

        local top_left3D = Util:viewport_point_to_world(top_left, distance)
        local top_right3D = Util:viewport_point_to_world(top_right, distance)
        local bottom_right3D = Util:viewport_point_to_world(bottom_right, distance)

        local width = (top_right3D - top_left3D).Magnitude
        local height = (top_right3D - bottom_right3D).Magnitude

        if not self._root then
            return
        end

        self._root.CFrame = CFrame.fromMatrix((top_left3D + bottom_right3D) / 2, workspace.CurrentCamera.CFrame.XVector, workspace.CurrentCamera.CFrame.YVector, workspace.CurrentCamera.CFrame.ZVector)
        self._root.Mesh.Scale = Vector3.new(width, height, 0)
    end

    local function on_change()
        local offset = Util:get_offset()
        local size = self._frame.AbsoluteSize - Vector2.new(offset, offset)
        local position = self._frame.AbsolutePosition + Vector2.new(offset / 2, offset / 2)

        update_positions(size, position)
        task.spawn(update)
    end

    Connections['cframe_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(update)
    Connections['viewport_size_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(update)
    Connections['field_of_view_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('FieldOfView'):Connect(update)

    Connections['frame_absolute_position'] = self._frame:GetPropertyChangedSignal('AbsolutePosition'):Connect(on_change)
    Connections['frame_absolute_size'] = self._frame:GetPropertyChangedSignal('AbsoluteSize'):Connect(on_change)
    
    task.spawn(update)
end


function AcrylicBlur:check_quality_level()
    local game_settings = UserSettings().GameSettings
    local quality_level = game_settings.SavedQualityLevel.Value

    if quality_level < 8 then
        self:change_visiblity(false)
    end

    Connections['quality_level'] = game_settings:GetPropertyChangedSignal('SavedQualityLevel'):Connect(function()
        local game_settings = UserSettings().GameSettings
        local quality_level = game_settings.SavedQualityLevel.Value

        self:change_visiblity(quality_level >= 8)
    end)
end


function AcrylicBlur:change_visiblity(state: boolean)
    self._root.Transparency = state and 0.98 or 1
end


local Config = setmetatable({
    save = function(self: any, file_name: any, config: any)
        local success_save, result = pcall(function()
            local flags = HttpService:JSONEncode(config)
            writefile('Omz/'..file_name..'.json', flags)
        end)
    
        if not success_save then
            warn('failed to save config', result)
        end
    end,
    load = function(self: any, file_name: any, config: any)
        local success_load, result = pcall(function()
            if not isfile('Omz/'..file_name..'.json') then
                self:save(file_name, config)
        
                return
            end
        
            local flags = readfile('Omz/'..file_name..'.json')
        
            if not flags then
                self:save(file_name, config)
        
                return
            end

            return HttpService:JSONDecode(flags)
        end)
    
        if not success_load then
            warn('failed to load config', result)
        end
    
        if not result then
            result = {
                _flags = {},
                _keybinds = {},
                _library = {}
            }
        end
    
        return result
    end
}, Config)


local Library = {
    _config = Config:load(game.GameId),

    _choosing_keybind = false,
    _device = nil,

    _ui_open = true,
    _ui_scale = 1,
    _ui_loaded = false,
    _ui = nil,

    _dragging = false,
    _drag_start = nil,
    _container_position = nil
}
Library.__index = Library


function Library.new()
    local self = setmetatable({
        _loaded = false,
        _tab = 0,
    }, Library)
    
    self:create_ui()

    return self
end

-- Create Notification Container
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "RobloxCoreGuis"
NotificationContainer.Size = UDim2.new(0, 300, 0, 0)  -- Fixed width (300px), dynamic height (Y)
NotificationContainer.Position = UDim2.new(0.8, 0, 0, 10)  -- Right side, offset by 10 from top
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false;
NotificationContainer.Parent = game:GetService("CoreGui").RobloxGui:FindFirstChild("RobloxCoreGuis") or Instance.new("ScreenGui", game:GetService("CoreGui").RobloxGui)
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y

-- UIListLayout to arrange notifications vertically
local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = NotificationContainer

-- Function to create notifications
function Library.SendNotification(settings)
    -- Create the notification frame (this will be managed by UIListLayout)
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 60)  -- Width = 100% of NotificationContainer's width, dynamic height (Y)
    Notification.BackgroundTransparency = 1  -- Outer frame is transparent for layout to work
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.Parent = NotificationContainer  -- Parent it to your NotificationContainer (the parent of the list layout)
    Notification.AutomaticSize = Enum.AutomaticSize.Y  -- Allow this frame to resize based on child height

    -- Add rounded corners to outer frame
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Notification

    -- Create the inner frame for the notification's content
    local InnerFrame = Instance.new("Frame")
    InnerFrame.Size = UDim2.new(1, 0, 0, 60)  -- Start with an initial height, width will adapt
    InnerFrame.Position = UDim2.new(0, 0, 0, 0)  -- Positioned inside the outer notification frame
    InnerFrame.BackgroundColor3 = Color3.fromRGB(32, 38, 51)
    InnerFrame.BackgroundTransparency = 0.1
    InnerFrame.BorderSizePixel = 0
    InnerFrame.Name = "InnerFrame"
    InnerFrame.Parent = Notification
    InnerFrame.AutomaticSize = Enum.AutomaticSize.Y  -- Automatically resize based on its content

    -- Add rounded corners to the inner frame
    local InnerUICorner = Instance.new("UICorner")
    InnerUICorner.CornerRadius = UDim.new(0, 4)
    InnerUICorner.Parent = InnerFrame

    -- Title Label (with automatic size support)
    local Title = Instance.new("TextLabel")
    Title.Text = settings.title or "Notification Title"
    Title.TextColor3 = Color3.fromRGB(210, 210, 210)
    Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Title.TextSize = 14
    Title.Size = UDim2.new(1, -10, 0, 20)  -- Width is 1 (100% of parent width), height is fixed initially
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.TextWrapped = true  -- Enable wrapping
    Title.AutomaticSize = Enum.AutomaticSize.Y  -- Allow the title to resize based on content
    Title.Parent = InnerFrame

    -- Body Text (with automatic size support)
    local Body = Instance.new("TextLabel")
    Body.Text = settings.text or "This is the body of the notification."
    Body.TextColor3 = Color3.fromRGB(180, 180, 180)
    Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Body.TextSize = 12
    Body.Size = UDim2.new(1, -10, 0, 30)  -- Width is 1 (100% of parent width), height is fixed initially
    Body.Position = UDim2.new(0, 5, 0, 25)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextYAlignment = Enum.TextYAlignment.Top
    Body.TextWrapped = true  -- Enable wrapping for long text
    Body.AutomaticSize = Enum.AutomaticSize.Y  -- Allow the body text to resize based on content
    Body.Parent = InnerFrame

    -- Force the size to adjust after the text is fully loaded and wrapped
    task.spawn(function()
        wait(0.1)  -- Allow text wrapping to finish
        -- Adjust inner frame size based on content
        local totalHeight = Title.TextBounds.Y + Body.TextBounds.Y + 10  -- Add padding
        InnerFrame.Size = UDim2.new(1, 0, 0, totalHeight)  -- Resize the inner frame
    end)

    -- Use task.spawn to ensure the notification tweening happens asynchronously
    task.spawn(function()
        -- Tween In the Notification (inner frame)
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 10 + NotificationContainer.Size.Y.Offset)
        })
        tweenIn:Play()

        -- Wait for the duration before tweening out
        local duration = settings.duration or 5  -- Default to 5 seconds if not provided
        wait(duration)

        -- Tween Out the Notification (inner frame) to the right side of the screen
        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 310, 0, 10 + NotificationContainer.Size.Y.Offset)  -- Move to the right off-screen
        })
        tweenOut:Play()

        -- Remove the notification after it is done tweening out
        tweenOut.Completed:Connect(function()
            Notification:Destroy()
        end)
    end)
end

function Library:get_screen_scale()
    local viewport_size_x = workspace.CurrentCamera.ViewportSize.X

    self._ui_scale = viewport_size_x / 1400
end


function Library:get_device()
    local device = 'Unknown'

    if not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
        device = 'PC'
    elseif UserInputService.TouchEnabled then
        device = 'Mobile'
    elseif UserInputService.GamepadEnabled then
        device = 'Console'
    end

    self._device = device
end


function Library:removed(action: any)
    self._ui.AncestryChanged:Once(action)
end


function Library:flag_type(flag: any, flag_type: any)
    if not Library._config._flags[flag] then
        return
    end

    return typeof(Library._config._flags[flag]) == flag_type
end


function Library:remove_table_value(__table: any, table_value: string)
    for index, value in __table do
        if value ~= table_value then
            continue
        end

        table.remove(__table, index)
    end
end


function Library:create_ui()
    local old_Omz = CoreGui:FindFirstChild('Omz')

    if old_Omz then
        Debris:AddItem(old_Omz, 0)
    end

    local Omz = Instance.new('ScreenGui')
    Omz.ResetOnSpawn = false
    Omz.Name = 'Omz'
    Omz.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Omz.Parent = CoreGui
    
    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0.05000000074505806
    Container.BackgroundColor3 = Color3.fromRGB(12, 13, 15)
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = Omz
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Container
    
    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(52, 66, 89)
    UIStroke.Transparency = 0.5
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container
    
    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Size = UDim2.new(0, 698, 0, 479)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handler.Parent = Container
    
    local Tabs = Instance.new('ScrollingFrame')
    Tabs.ScrollBarImageTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.Name = 'Tabs'
    Tabs.Size = UDim2.new(0, 129, 0, 401)
    Tabs.Selectable = false
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.BackgroundTransparency = 1
    Tabs.Position = UDim2.new(0.026097271591424942, 0, 0.1111111119389534, 0)
    Tabs.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler
    
    local UIListLayout = Instance.new('UIListLayout')
    UIListLayout.Padding = UDim.new(0, 4)
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Parent = Tabs
    
    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    ClientName.TextColor3 = Color3.fromRGB(152, 181, 255)
    ClientName.TextTransparency = 0.20000000298023224
    ClientName.Text = 'Omz'
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 31, 0, 13)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0.0560000017285347, 0, 0.054999999701976776, 0)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.BorderSizePixel = 0
    ClientName.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ClientName.TextSize = 13
    ClientName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.Parent = Handler
    
    local UIGradient = Instance.new('UIGradient')
    UIGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 155, 155)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    }
    UIGradient.Parent = ClientName
    
    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0.026000000536441803, 0, 0.13600000739097595, 0)
    Pin.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BorderSizePixel = 0
    Pin.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
    Pin.Parent = Handler
    
    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = Pin
    
    local Icon = Instance.new('ImageLabel')
    Icon.ImageColor3 = Color3.fromRGB(152, 181, 255)
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.Image = 'rbxassetid://107819132007001'
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0.02500000037252903, 0, 0.054999999701976776, 0)
    Icon.Name = 'Icon'
    Icon.Size = UDim2.new(0, 18, 0, 18)
    Icon.BorderSizePixel = 0
    Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Icon.Parent = Handler
    
    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.5
    Divider.Position = UDim2.new(0.23499999940395355, 0, 0, 0)
    Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 479)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Color3.fromRGB(52, 66, 89)
    Divider.Parent = Handler
    
    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler
    
    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.020057305693626404, 0, 0.02922755666077137, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 14
    Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.Parent = Handler
    
    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container    
    
    self._ui = Omz

    local function on_drag(input: InputObject, process: boolean)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            self._dragging = true
            self._drag_start = input.Position
            self._container_position = Container.Position

            Connections['container_input_ended'] = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then
                    return
                end

                Connections:disconnect('container_input_ended')
                self._dragging = false
            end)
        end
    end

    local function update_drag(input: any)
        local delta = input.Position - self._drag_start
        local position = UDim2.new(self._container_position.X.Scale, self._container_position.X.Offset + delta.X, self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)

        TweenService:Create(Container, TweenInfo.new(0.2), {
            Position = position
        }):Play()
    end

    local function drag(input: InputObject, process: boolean)
        if not self._dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began'] = Container.InputBegan:Connect(on_drag)
    Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)

    self:removed(function()
        self._ui = nil
        Connections:disconnect_all()
    end)

    function self:Update1Run(a)
        if a == "nil" then
            Container.BackgroundTransparency = 0.05000000074505806;
        else
            pcall(function()
                Container.BackgroundTransparency = tonumber(a);
            end);
        end;
    end;

    function self:UIVisiblity()
        Omz.Enabled = not Omz.Enabled;
    end;

    function self:change_visiblity(state: boolean)
        if state then
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(698, 479)
            }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            }):Play()
        end
    end
    

    function self:load()
        local content = {}
    
        for _, object in Omz:GetDescendants() do
            if not object:IsA('ImageLabel') then
                continue
            end
    
            table.insert(content, object)
        end
    
        ContentProvider:PreloadAsync(content)
        self:get_device()

        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale
    
            Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
            end)
        end
    
        TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(698, 479)
        }):Play()

        AcrylicBlur.new(Container)
        self._ui_loaded = true
    end

    function self:update_tabs(tab: TextButton)
        for index, object in Tabs:GetChildren() do
            if object.Name ~= 'Tab' then
                continue
            end

            if object == tab then
                if object.BackgroundTransparency ~= 0.5 then
                    local offset = object.LayoutOrder * (0.113 / 1.3)

                    TweenService:Create(Pin, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.fromScale(0.026, 0.135 + offset)
                    }):Play()    

                    TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.5
                    }):Play()

                    TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0.2,
                        TextColor3 = Color3.fromRGB(152, 181, 255)
                    }):Play()

                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(1, 0)
                    }):Play()

                    TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageTransparency = 0.2,
                        ImageColor3 = Color3.fromRGB(152, 181, 255)
                    }):Play()
                end

                continue
            end

            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()
                
                TweenService:Create(object.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0.7,
                    TextColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()

                TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(0, 0)
                }):Play()

                TweenService:Create(object.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageTransparency = 0.8,
                    ImageColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
            end
        end
    end

    function self:update_sections(left_section: ScrollingFrame, right_section: ScrollingFrame)
        for _, object in Sections:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true

                continue
            end

            object.Visible = false
        end
    end

    function self:create_tab(title: string, icon: string)
        local TabManager = {}

        local LayoutOrder = 0;

        local font_params = Instance.new('GetTextBoundsParams')
        font_params.Text = title
        font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        font_params.Size = 13
        font_params.Width = 10000

        local font_size = TextService:GetTextBoundsAsync(font_params)
        local first_tab = not Tabs:FindFirstChild('Tab')

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        Tab.TextColor3 = Color3.fromRGB(0, 0, 0)
        Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = Color3.fromRGB(22, 28, 38)
        Tab.Parent = Tabs
        Tab.LayoutOrder = self._tab
        
        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 5)
        UICorner.Parent = Tab
        
        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.TextTransparency = 0.7 -- 0.800000011920929
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0.2400001734495163, 0, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.BorderSizePixel = 0
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.TextSize = 13
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.Parent = Tab
        
        local UIGradient = Instance.new('UIGradient')
        UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(155, 155, 155)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 58, 58))
        }
        UIGradient.Parent = TextLabel
        
        local Icon = Instance.new('ImageLabel')
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.ImageTransparency = 0.800000011920929
        Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.Position = UDim2.new(0.10000000149011612, 0, 0.5, 0)
        Icon.Name = 'Icon'
        Icon.Image = icon
        Icon.Size = UDim2.new(0, 12, 0, 12)
        Icon.BorderSizePixel = 0
        Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Icon.Parent = Tab

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.Size = UDim2.new(0, 243, 0, 445)
        LeftSection.Selectable = false
        LeftSection.AnchorPoint = Vector2.new(0, 0.5)
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0.2594326436519623, 0, 0.5, 0)
        LeftSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LeftSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        LeftSection.BorderSizePixel = 0
        LeftSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        LeftSection.Visible = false
        LeftSection.Parent = Sections
        
        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = LeftSection
        
        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = LeftSection

        local RightSection = Instance.new('ScrollingFrame')
        RightSection.Name = 'RightSection'
        RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        RightSection.ScrollBarThickness = 0
        RightSection.Size = UDim2.new(0, 243, 0, 445)
        RightSection.Selectable = false
        RightSection.AnchorPoint = Vector2.new(0, 0.5)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0.6290000081062317, 0, 0.5, 0)
        RightSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RightSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        RightSection.BorderSizePixel = 0
        RightSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        RightSection.Visible = false
        RightSection.Parent = Sections
        
        local UIListLayout = Instance.new('UIListLayout')
        UIListLayout.Padding = UDim.new(0, 11)
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout.Parent = RightSection
        
        local UIPadding = Instance.new('UIPadding')
        UIPadding.PaddingTop = UDim.new(0, 1)
        UIPadding.Parent = RightSection

        self._tab += 1

        if first_tab then
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end)

        function TabManager:create_module(settings: any)

            local LayoutOrderModule = 0;

            local ModuleManager = {
                _state = false,
                _size = 0,
                _multiplier = 0
            }

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0.5
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 241, 0, 93)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(22, 28, 38)
            Module.Parent = settings.section

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Module
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 5)
            UICorner.Parent = Module
            
            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(52, 66, 89)
            UIStroke.Transparency = 0.5
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module
            
            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(0, 0, 0)
            Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, 93)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Header.Parent = Module
            
            local Icon = Instance.new('ImageLabel')
            Icon.ImageColor3 = Color3.fromRGB(152, 181, 255)
            Icon.ScaleType = Enum.ScaleType.Fit
            Icon.ImageTransparency = 0.699999988079071
            Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.Image = 'rbxassetid://79095934438045'
            Icon.BackgroundTransparency = 1
            Icon.Position = UDim2.new(0.07100000232458115, 0, 0.8199999928474426, 0)
            Icon.Name = 'Icon'
            Icon.Size = UDim2.new(0, 15, 0, 15)
            Icon.BorderSizePixel = 0
            Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Icon.Parent = Header
            
            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = Color3.fromRGB(152, 181, 255)
            ModuleName.TextTransparency = 0.20000000298023224
            if not settings.rich then
                ModuleName.Text = settings.title or "Skibidi"
            else
                ModuleName.RichText = true
                ModuleName.Text = settings.richtext or "<font color='rgb(255,0,0)'>Omz</font> user"
            end;
            ModuleName.Name = 'ModuleName'
            ModuleName.Size = UDim2.new(0, 205, 0, 13)
            ModuleName.AnchorPoint = Vector2.new(0, 0.5)
            ModuleName.Position = UDim2.new(0.0729999989271164, 0, 0.23999999463558197, 0)
            ModuleName.BackgroundTransparency = 1
            ModuleName.TextXAlignment = Enum.TextXAlignment.Left
            ModuleName.BorderSizePixel = 0
            ModuleName.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ModuleName.TextSize = 13
            ModuleName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ModuleName.Parent = Header
            
            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = Color3.fromRGB(152, 181, 255)
            Description.TextTransparency = 0.699999988079071
            Description.Text = settings.description
            Description.Name = 'Description'
            Description.Size = UDim2.new(0, 205, 0, 13)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.Position = UDim2.new(0.0729999989271164, 0, 0.41999998688697815, 0)
            Description.BackgroundTransparency = 1
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.BorderSizePixel = 0
            Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Description.TextSize = 10
            Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Description.Parent = Header
            
            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0.699999988079071
            Toggle.Position = UDim2.new(0.8199999928474426, 0, 0.7570000290870667, 0)
            Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.Size = UDim2.new(0, 25, 0, 12)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Toggle.Parent = Header
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Toggle
            
            local Circle = Instance.new('Frame')
            Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.BackgroundTransparency = 0.20000000298023224
            Circle.Position = UDim2.new(0, 0, 0.5, 0)
            Circle.Name = 'Circle'
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Color3.fromRGB(66, 80, 115)
            Circle.Parent = Toggle
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(1, 0)
            UICorner.Parent = Circle
            
            local Keybind = Instance.new('Frame')
            Keybind.Name = 'Keybind'
            Keybind.BackgroundTransparency = 0.699999988079071
            Keybind.Position = UDim2.new(0.15000000596046448, 0, 0.7350000143051147, 0)
            Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Keybind.Size = UDim2.new(0, 33, 0, 15)
            Keybind.BorderSizePixel = 0
            Keybind.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
            Keybind.Parent = Header
            
            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 3)
            UICorner.Parent = Keybind
            
            local TextLabel = Instance.new('TextLabel')
            TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            TextLabel.TextColor3 = Color3.fromRGB(209, 222, 255)
            TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
            TextLabel.Text = 'None'
            TextLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            TextLabel.Size = UDim2.new(0, 25, 0, 13)
            TextLabel.BackgroundTransparency = 1
            TextLabel.TextXAlignment = Enum.TextXAlignment.Left
            TextLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
            TextLabel.BorderSizePixel = 0
            TextLabel.TextSize = 10
            TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            TextLabel.Parent = Keybind
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 0.6200000047683716, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(52, 66, 89)
            Divider.Parent = Header
            
            local Divider = Instance.new('Frame')
            Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider.AnchorPoint = Vector2.new(0.5, 0)
            Divider.BackgroundTransparency = 0.5
            Divider.Position = UDim2.new(0.5, 0, 1, 0)
            Divider.Name = 'Divider'
            Divider.Size = UDim2.new(0, 241, 0, 1)
            Divider.BorderSizePixel = 0
            Divider.BackgroundColor3 = Color3.fromRGB(52, 66, 89)
            Divider.Parent = Header
            
            local Options = Instance.new('Frame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 1, 0)
            Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Options.Size = UDim2.new(0, 241, 0, 8)
            Options.BorderSizePixel = 0
            Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Options.Parent = Module

            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, 8)
            UIPadding.Parent = Options

            local UIListLayout = Instance.new('UIListLayout')
            UIListLayout.Padding = UDim.new(0, 5)
            UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout.Parent = Options

            function ModuleManager:change_state(state: boolean)
                self._state = state

                if self._state then
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93 + self._size + self._multiplier)
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(152, 181, 255)
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(152, 181, 255),
                        Position = UDim2.fromScale(0.53, 0.5)
                    }):Play()
                else
                    TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(241, 93)
                    }):Play()

                    TweenService:Create(Toggle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    }):Play()

                    TweenService:Create(Circle, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(66, 80, 115),
                        Position = UDim2.fromScale(0, 0.5)
                    }):Play()
                end

                Library._config._flags[settings.flag] = self._state
                Config:save(game.GameId, Library._config)

                settings.callback(self._state)
            end
            
            function ModuleManager:connect_keybind()
                if not Library._config._keybinds[settings.flag] then
                    return
                end

                Connections[settings.flag..'_keybind'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                    if process then
                        return
                    end
                    
                    if tostring(input.KeyCode) ~= Library._config._keybinds[settings.flag] then
                        return
                    end
                    
                    self:change_state(not self._state)
                end)
            end

            function ModuleManager:scale_keybind(empty: boolean)
                if Library._config._keybinds[settings.flag] and not empty then
                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')

                    local font_params = Instance.new('GetTextBoundsParams')
                    font_params.Text = keybind_string
                    font_params.Font = Font.new('rbxasset://fonts/families/Montserrat.json', Enum.FontWeight.Bold)
                    font_params.Size = 10
                    font_params.Width = 10000
            
                    local font_size = TextService:GetTextBoundsAsync(font_params)
                    
                    Keybind.Size = UDim2.fromOffset(font_size.X + 6, 15)
                    TextLabel.Size = UDim2.fromOffset(font_size.X, 13)
                else
                    Keybind.Size = UDim2.fromOffset(31, 15)
                    TextLabel.Size = UDim2.fromOffset(25, 13)
                end
            end

            if Library:flag_type(settings.flag, 'boolean') then
                ModuleManager._state = true
                settings.callback(ModuleManager._state)

                Toggle.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
                Circle.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
                Circle.Position = UDim2.fromScale(0.53, 0.5)
            end

            if Library._config._keybinds[settings.flag] then
                local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                TextLabel.Text = keybind_string

                ModuleManager:connect_keybind()
                ModuleManager:scale_keybind()
            end

            Connections[settings.flag..'_input_began'] = Header.InputBegan:Connect(function(input: InputObject)
                if Library._choosing_keybind then
                    return
                end

                if input.UserInputType ~= Enum.UserInputType.MouseButton3 then
                    return
                end
                
                Library._choosing_keybind = true
                
                Connections['keybind_choose_start'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
                    if process then
                        return
                    end
                    
                    if input == Enum.UserInputState or input == Enum.UserInputType then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Unknown then
                        return
                    end

                    if input.KeyCode == Enum.KeyCode.Backspace then
                        ModuleManager:scale_keybind(true)

                        Library._config._keybinds[settings.flag] = nil
                        Config:save(game.GameId, Library._config)

                        TextLabel.Text = 'None'
                        
                        if Connections[settings.flag..'_keybind'] then
                            Connections[settings.flag..'_keybind']:Disconnect()
                            Connections[settings.flag..'_keybind'] = nil
                        end

                        Connections['keybind_choose_start']:Disconnect()
                        Connections['keybind_choose_start'] = nil

                        Library._choosing_keybind = false

                        return
                    end
                    
                    Connections['keybind_choose_start']:Disconnect()
                    Connections['keybind_choose_start'] = nil
                    
                    Library._config._keybinds[settings.flag] = tostring(input.KeyCode)
                    Config:save(game.GameId, Library._config)

                    if Connections[settings.flag..'_keybind'] then
                        Connections[settings.flag..'_keybind']:Disconnect()
                        Connections[settings.flag..'_keybind'] = nil
                    end

                    ModuleManager:connect_keybind()
                    ModuleManager:scale_keybind()
                    
                    Library._choosing_keybind = false

                    local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), 'Enum.KeyCode.', '')
                    TextLabel.Text = keybind_string
                end)
            end)

            Header.MouseButton1Click:Connect(function()
                ModuleManager:change_state(not ModuleManager._state)
            end)

            function ModuleManager:create_paragraph(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1;

                local ParagraphManager = {}
                
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += settings.customScale or 70
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
            
                Options.Size = UDim2.fromOffset(241, self._size)
            
                -- Container Frame
                local Paragraph = Instance.new('Frame')
                Paragraph.BackgroundColor3 = Color3.fromRGB(32, 38, 51)
                Paragraph.BackgroundTransparency = 0.1
                Paragraph.Size = UDim2.new(0, 207, 0, 30) -- Initial size, auto-resized later
                Paragraph.BorderSizePixel = 0
                Paragraph.Name = "Paragraph"
                Paragraph.AutomaticSize = Enum.AutomaticSize.Y -- Support auto-resizing height
                Paragraph.Parent = Options
                Paragraph.LayoutOrder = LayoutOrderModule;
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Paragraph
            
                -- Title Label
                local Title = Instance.new('TextLabel')
                Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Title.TextColor3 = Color3.fromRGB(210, 210, 210)
                Title.Text = settings.title or "Title"
                Title.Size = UDim2.new(1, -10, 0, 20)
                Title.Position = UDim2.new(0, 5, 0, 5)
                Title.BackgroundTransparency = 1
                Title.TextXAlignment = Enum.TextXAlignment.Left
                Title.TextYAlignment = Enum.TextYAlignment.Center
                Title.TextSize = 12
                Title.AutomaticSize = Enum.AutomaticSize.XY
                Title.Parent = Paragraph
            
                -- Body Text
                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Color3.fromRGB(180, 180, 180)
                
                if not settings.rich then
                    Body.Text = settings.text or "Skibidi"
                else
                    Body.RichText = true
                    Body.Text = settings.richtext or "<font color='rgb(255,0,0)'>Omz</font> user"
                end
                
                Body.Size = UDim2.new(1, -10, 0, 20)
                Body.Position = UDim2.new(0, 5, 0, 30)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 11
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = Paragraph
            
                -- Hover effect for Paragraph (optional)
                Paragraph.MouseEnter:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(42, 50, 66)
                    }):Play()
                end)
            
                Paragraph.MouseLeave:Connect(function()
                    TweenService:Create(Paragraph, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(32, 38, 51)
                    }):Play()
                end)

                return ParagraphManager
            end

            function ModuleManager:create_text(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
            
                local TextManager = {}
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += settings.customScale or 50 -- Adjust the default height for text elements
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
            
                Options.Size = UDim2.fromOffset(241, self._size)
            
                -- Container Frame
                local TextFrame = Instance.new('Frame')
                TextFrame.BackgroundColor3 = Color3.fromRGB(32, 38, 51)
                TextFrame.BackgroundTransparency = 0.1
                TextFrame.Size = UDim2.new(0, 207, 0, settings.CustomYSize) -- Initial size, auto-resized later
                TextFrame.BorderSizePixel = 0
                TextFrame.Name = "Text"
                TextFrame.AutomaticSize = Enum.AutomaticSize.Y -- Support auto-resizing height
                TextFrame.Parent = Options
                TextFrame.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = TextFrame
            
                -- Body Text
                local Body = Instance.new('TextLabel')
                Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Body.TextColor3 = Color3.fromRGB(180, 180, 180)
            
                if not settings.rich then
                    Body.Text = settings.text or "Skibidi" -- Default text
                else
                    Body.RichText = true
                    Body.Text = settings.richtext or "<font color='rgb(255,0,0)'>Omz</font> user" -- Default rich text
                end
            
                Body.Size = UDim2.new(1, -10, 1, 0)
                Body.Position = UDim2.new(0, 5, 0, 5)
                Body.BackgroundTransparency = 1
                Body.TextXAlignment = Enum.TextXAlignment.Left
                Body.TextYAlignment = Enum.TextYAlignment.Top
                Body.TextSize = 10
                Body.TextWrapped = true
                Body.AutomaticSize = Enum.AutomaticSize.XY
                Body.Parent = TextFrame
            
                -- Hover effect for TextFrame (optional)
                TextFrame.MouseEnter:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(42, 50, 66)
                    }):Play()
                end)
            
                TextFrame.MouseLeave:Connect(function()
                    TweenService:Create(TextFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(32, 38, 51)
                    }):Play()
                end)

                function TextManager:Set(new_settings)
                    if not new_settings.rich then
                        Body.Text = new_settings.text or "Skibidi" -- Default text
                    else
                        Body.RichText = true
                        Body.Text = new_settings.richtext or "<font color='rgb(255,0,0)'>Omz</font> user" -- Default rich text
                    end
                end;
            
                return TextManager
            end
            function ModuleManager:create_textbox(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
            
                local TextboxManager = {
                    _text = ""
                }
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += 32
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
            
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Label = Instance.new('TextLabel')
                Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Label.TextColor3 = Color3.fromRGB(255, 255, 255)
                Label.TextTransparency = 0.2
                Label.Text = settings.title or "Enter text"
                Label.Size = UDim2.new(0, 207, 0, 13)
                Label.AnchorPoint = Vector2.new(0, 0)
                Label.Position = UDim2.new(0, 0, 0, 0)
                Label.BackgroundTransparency = 1
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.BorderSizePixel = 0
                Label.Parent = Options
                Label.TextSize = 10;
                Label.LayoutOrder = LayoutOrderModule
            
                local Textbox = Instance.new('TextBox')
                Textbox.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Textbox.TextColor3 = Color3.fromRGB(255, 255, 255)
                Textbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Textbox.PlaceholderText = settings.placeholder or "Enter text..."
                Textbox.Text = Library._config._flags[settings.flag] or ""
                Textbox.Name = 'Textbox'
                Textbox.Size = UDim2.new(0, 207, 0, 15)
                Textbox.BorderSizePixel = 0
                Textbox.TextSize = 10
                Textbox.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
                Textbox.BackgroundTransparency = 0.9
                Textbox.ClearTextOnFocus = false
                Textbox.Parent = Options
                Textbox.LayoutOrder = LayoutOrderModule
            
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Textbox
            
                function TextboxManager:update_text(text: string)
                    self._text = text
                    Library._config._flags[settings.flag] = self._text
                    Config:save(game.GameId, Library._config)
                    settings.callback(self._text)
                end
            
                if Library:flag_type(settings.flag, 'string') then
                    TextboxManager:update_text(Library._config._flags[settings.flag])
                end
            
                Textbox.FocusLost:Connect(function()
                    TextboxManager:update_text(Textbox.Text)
                end)
            
                return TextboxManager
            end   

            function ModuleManager:create_checkbox(settings: any)
                LayoutOrderModule = LayoutOrderModule + 1
                local CheckboxManager = { _state = false }
            
                if self._size == 0 then
                    self._size = 11
                end
                self._size += 20
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end
                Options.Size = UDim2.fromOffset(241, self._size)
            
                local Checkbox = Instance.new("TextButton")
                Checkbox.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Checkbox.TextColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.Text = ""
                Checkbox.AutoButtonColor = false
                Checkbox.BackgroundTransparency = 1
                Checkbox.Name = "Checkbox"
                Checkbox.Size = UDim2.new(0, 207, 0, 15)
                Checkbox.BorderSizePixel = 0
                Checkbox.TextSize = 14
                Checkbox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Checkbox.Parent = Options
                Checkbox.LayoutOrder = LayoutOrderModule
            
                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Name = "TitleLabel"
                if SelectedLanguage == "th" then
                    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TitleLabel.TextSize = 13
                else
                    TitleLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TitleLabel.TextSize = 11
                end
                TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TitleLabel.TextTransparency = 0.2
                TitleLabel.Text = settings.title or "Skibidi"
                TitleLabel.Size = UDim2.new(0, 142, 0, 13)
                TitleLabel.AnchorPoint = Vector2.new(0, 0.5)
                TitleLabel.Position = UDim2.new(0, 0, 0.5, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.Parent = Checkbox

                local KeybindBox = Instance.new("Frame")
                KeybindBox.Name = "KeybindBox"
                KeybindBox.Size = UDim2.fromOffset(14, 14)
                KeybindBox.Position = UDim2.new(1, -35, 0.5, 0)
                KeybindBox.AnchorPoint = Vector2.new(0, 0.5)
                KeybindBox.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
                KeybindBox.BorderSizePixel = 0
                KeybindBox.Parent = Checkbox
            
                local KeybindCorner = Instance.new("UICorner")
                KeybindCorner.CornerRadius = UDim.new(0, 4)
                KeybindCorner.Parent = KeybindBox
            
                local KeybindLabel = Instance.new("TextLabel")
                KeybindLabel.Name = "KeybindLabel"
                KeybindLabel.Size = UDim2.new(1, 0, 1, 0)
                KeybindLabel.BackgroundTransparency = 1
                KeybindLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
                KeybindLabel.TextScaled = false
                KeybindLabel.TextSize = 10
                KeybindLabel.Font = Enum.Font.SourceSans
                KeybindLabel.Text = Library._config._keybinds[settings.flag] 
                    and string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "") 
                    or "..."
                KeybindLabel.Parent = KeybindBox
            
                local Box = Instance.new("Frame")
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(1, 0.5)
                Box.BackgroundTransparency = 0.9
                Box.Position = UDim2.new(1, 0, 0.5, 0)
                Box.Name = "Box"
                Box.Size = UDim2.new(0, 15, 0, 15)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
                Box.Parent = Checkbox
            
                local BoxCorner = Instance.new("UICorner")
                BoxCorner.CornerRadius = UDim.new(0, 4)
                BoxCorner.Parent = Box
            
                local Fill = Instance.new("Frame")
                Fill.AnchorPoint = Vector2.new(0.5, 0.5)
                Fill.BackgroundTransparency = 0.2
                Fill.Position = UDim2.new(0.5, 0, 0.5, 0)
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.Name = "Fill"
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
                Fill.Parent = Box
            
                local FillCorner = Instance.new("UICorner")
                FillCorner.CornerRadius = UDim.new(0, 3)
                FillCorner.Parent = Fill
            
                function CheckboxManager:change_state(state: boolean)
                    self._state = state
                    if self._state then
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.7
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(9, 9)
                        }):Play()
                    else
                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundTransparency = 0.9
                        }):Play()
                        TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(0, 0)
                        }):Play()
                    end
                    Library._config._flags[settings.flag] = self._state
                    Config:save(game.GameId, Library._config)
                    settings.callback(self._state)
                end
            
                if Library:flag_type(settings.flag, "boolean") then
                    CheckboxManager:change_state(Library._config._flags[settings.flag])
                end
            
                Checkbox.MouseButton1Click:Connect(function()
                    CheckboxManager:change_state(not CheckboxManager._state)
                end)
            
                Checkbox.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseButton3 then return end
                    if Library._choosing_keybind then return end
            
                    Library._choosing_keybind = true
                    local chooseConnection
                    chooseConnection = UserInputService.InputBegan:Connect(function(keyInput, processed)
                        if processed then return end
                        if keyInput.UserInputType ~= Enum.UserInputType.Keyboard then return end
                        if keyInput.KeyCode == Enum.KeyCode.Unknown then return end
            
                        if keyInput.KeyCode == Enum.KeyCode.Backspace then
                            ModuleManager:scale_keybind(true)
                            Library._config._keybinds[settings.flag] = nil
                            Config:save(game.GameId, Library._config)
                            KeybindLabel.Text = "..."
                            if Connections[settings.flag .. "_keybind"] then
                                Connections[settings.flag .. "_keybind"]:Disconnect()
                                Connections[settings.flag .. "_keybind"] = nil
                            end
                            chooseConnection:Disconnect()
                            Library._choosing_keybind = false
                            return
                        end
            
                        chooseConnection:Disconnect()
                        Library._config._keybinds[settings.flag] = tostring(keyInput.KeyCode)
                        Config:save(game.GameId, Library._config)
                        if Connections[settings.flag .. "_keybind"] then
                            Connections[settings.flag .. "_keybind"]:Disconnect()
                            Connections[settings.flag .. "_keybind"] = nil
                        end
                        ModuleManager:connect_keybind()
                        ModuleManager:scale_keybind()
                        Library._choosing_keybind = false
            
                        local keybind_string = string.gsub(tostring(Library._config._keybinds[settings.flag]), "Enum.KeyCode.", "")
                        KeybindLabel.Text = keybind_string
                    end)
                end)
            
                local keyPressConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local storedKey = Library._config._keybinds[settings.flag]
                        if storedKey and tostring(input.KeyCode) == storedKey then
                            CheckboxManager:change_state(not CheckboxManager._state)
                        end
                    end
                end)
                Connections[settings.flag .. "_keypress"] = keyPressConnection
            
                return CheckboxManager
            end

            function ModuleManager:create_divider(settings: any)
                -- Layout order management
                LayoutOrderModule = LayoutOrderModule + 1;
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += 27
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end

                local dividerHeight = 1
                local dividerWidth = 207 -- Adjust this to fit your UI width
            
                -- Create the outer frame to control spacing above and below
                local OuterFrame = Instance.new('Frame')
                OuterFrame.Size = UDim2.new(0, dividerWidth, 0, 20) -- Height here controls spacing above and below
                OuterFrame.BackgroundTransparency = 1 -- Fully invisible
                OuterFrame.Name = 'OuterFrame'
                OuterFrame.Parent = Options
                OuterFrame.LayoutOrder = LayoutOrderModule

                if settings and settings.showtopic then
                    local TextLabel = Instance.new('TextLabel')
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255) -- 154, 182, 255
                    TextLabel.TextTransparency = 0
                    TextLabel.Text = settings.title
                    TextLabel.Size = UDim2.new(0, 153, 0, 13)
                    TextLabel.Position = UDim2.new(0.5, 0, 0.501, 0)
                    TextLabel.BackgroundTransparency = 1
                    TextLabel.TextXAlignment = Enum.TextXAlignment.Center
                    TextLabel.BorderSizePixel = 0
                    TextLabel.AnchorPoint = Vector2.new(0.5,0.5)
                    TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                    TextLabel.TextSize = 11
                    TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    TextLabel.ZIndex = 3;
                    TextLabel.TextStrokeTransparency = 0;
                    TextLabel.Parent = OuterFrame
                end;
                
                if not settings or settings and not settings.disableline then
                    -- Create the inner divider frame that will be placed in the middle of the OuterFrame
                    local Divider = Instance.new('Frame')
                    Divider.Size = UDim2.new(1, 0, 0, dividerHeight)
                    Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- White color
                    Divider.BorderSizePixel = 0
                    Divider.Name = 'Divider'
                    Divider.Parent = OuterFrame
                    Divider.ZIndex = 2;
                    Divider.Position = UDim2.new(0, 0, 0.5, -dividerHeight / 2) -- Center the divider vertically in the OuterFrame
                
                    -- Add a UIGradient to the divider for left and right transparency
                    local Gradient = Instance.new('UIGradient')
                    Gradient.Parent = Divider
                    Gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),  -- Start with white
                        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)), -- Keep it white in the middle
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255, 0))  -- Fade to transparent on the right side
                    })
                    Gradient.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),   
                        NumberSequenceKeypoint.new(0.5, 0),
                        NumberSequenceKeypoint.new(1, 1)
                    })
                    Gradient.Rotation = 0 -- Horizontal gradient (fade from left to right)
                
                    -- Optionally, you can add a corner radius for rounded ends
                    local UICorner = Instance.new('UICorner')
                    UICorner.CornerRadius = UDim.new(0, 2) -- Small corner radius for smooth edges
                    UICorner.Parent = Divider

                end;
            
                return true;
            end
            
            function ModuleManager:create_slider(settings: any)

                LayoutOrderModule = LayoutOrderModule + 1

                local SliderManager = {}

                if self._size == 0 then
                    self._size = 11
                end

                self._size += 27

                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size)
                end

                Options.Size = UDim2.fromOffset(241, self._size)

                local Slider = Instance.new('TextButton')
                Slider.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal);
                Slider.TextSize = 14;
                Slider.TextColor3 = Color3.fromRGB(0, 0, 0)
                Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Text = ''
                Slider.AutoButtonColor = false
                Slider.BackgroundTransparency = 1
                Slider.Name = 'Slider'
                Slider.Size = UDim2.new(0, 207, 0, 22)
                Slider.BorderSizePixel = 0
                Slider.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Slider.Parent = Options
                Slider.LayoutOrder = LayoutOrderModule
                
                local TextLabel = Instance.new('TextLabel')
                if GG.SelectedLanguage == "th" then
                    TextLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 13;
                else
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 11;
                end;
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextTransparency = 0.20000000298023224
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 153, 0, 13)
                TextLabel.Position = UDim2.new(0, 0, 0.05000000074505806, 0)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.Parent = Slider
                
                local Drag = Instance.new('Frame')
                Drag.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Drag.AnchorPoint = Vector2.new(0.5, 1)
                Drag.BackgroundTransparency = 0.8999999761581421
                Drag.Position = UDim2.new(0.5, 0, 0.949999988079071, 0)
                Drag.Name = 'Drag'
                Drag.Size = UDim2.new(0, 207, 0, 4)
                Drag.BorderSizePixel = 0
                Drag.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
                Drag.Parent = Slider
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Drag
                
                local Fill = Instance.new('Frame')
                Fill.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Fill.AnchorPoint = Vector2.new(0, 0.5)
                Fill.BackgroundTransparency = 0.5
                Fill.Position = UDim2.new(0, 0, 0.5, 0)
                Fill.Name = 'Fill'
                Fill.Size = UDim2.new(0, 103, 0, 4)
                Fill.BorderSizePixel = 0
                Fill.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
                Fill.Parent = Drag
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 3)
                UICorner.Parent = Fill
                
                local UIGradient = Instance.new('UIGradient')
                UIGradient.Color = ColorSequence.new{
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(79, 79, 79))
                }
                UIGradient.Parent = Fill
                
                local Circle = Instance.new('Frame')
                Circle.AnchorPoint = Vector2.new(1, 0.5)
                Circle.Name = 'Circle'
                Circle.Position = UDim2.new(1, 0, 0.5, 0)
                Circle.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Circle.Size = UDim2.new(0, 6, 0, 6)
                Circle.BorderSizePixel = 0
                Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Circle.Parent = Fill
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(1, 0)
                UICorner.Parent = Circle
                
                local Value = Instance.new('TextLabel')
                Value.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Value.TextColor3 = Color3.fromRGB(255, 255, 255)
                Value.TextTransparency = 0.20000000298023224
                Value.Text = '50'
                Value.Name = 'Value'
                Value.Size = UDim2.new(0, 42, 0, 13)
                Value.AnchorPoint = Vector2.new(1, 0)
                Value.Position = UDim2.new(1, 0, 0, 0)
                Value.BackgroundTransparency = 1
                Value.TextXAlignment = Enum.TextXAlignment.Right
                Value.BorderSizePixel = 0
                Value.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Value.TextSize = 10
                Value.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Value.Parent = Slider

                function SliderManager:set_percentage(percentage: number)
                    local rounded_number = 0

                    if settings.round_number then
                        rounded_number = math.floor(percentage)
                    else
                        rounded_number = math.floor(percentage * 10) / 10
                    end

                    percentage = (percentage - settings.minimum_value) / (settings.maximum_value - settings.minimum_value)
                    
                    local slider_size = math.clamp(percentage, 0.02, 1) * Drag.Size.X.Offset
                    local number_threshold = math.clamp(rounded_number, settings.minimum_value, settings.maximum_value)
    
                    Library._config._flags[settings.flag] = number_threshold
                    Value.Text = number_threshold
    
                    TweenService:Create(Fill, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.fromOffset(slider_size, Drag.Size.Y.Offset)
                    }):Play()
    
                    settings.callback(number_threshold)
                end

                function SliderManager:update()
                    local mouse_position = (mouse.X - Drag.AbsolutePosition.X) / Drag.Size.X.Offset
                    local percentage = settings.minimum_value + (settings.maximum_value - settings.minimum_value) * mouse_position

                    self:set_percentage(percentage)
                end

                function SliderManager:input()
                    SliderManager:update()
    
                    Connections['slider_drag_'..settings.flag] = mouse.Move:Connect(function()
                        SliderManager:update()
                    end)
                    
                    Connections['slider_input_'..settings.flag] = UserInputService.InputEnded:Connect(function(input: InputObject, process: boolean)
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end
    
                        Connections:disconnect('slider_drag_'..settings.flag)
                        Connections:disconnect('slider_input_'..settings.flag)

                        if not settings.ignoresaved then
                            Config:save(game.GameId, Library._config);
                        end;
                    end)
                end


                if Library:flag_type(settings.flag, 'number') then
                    if not settings.ignoresaved then
                        SliderManager:set_percentage(Library._config._flags[settings.flag]);
                    else
                        SliderManager:set_percentage(settings.value);
                    end;
                else
                    SliderManager:set_percentage(settings.value);
                end;
    
                Slider.MouseButton1Down:Connect(function()
                    SliderManager:input()
                end)

                return SliderManager
            end

            function ModuleManager:create_dropdown(settings: any)

                if not settings.Order then
                    LayoutOrderModule = LayoutOrderModule + 1;
                end;

                local DropdownManager = {
                    _state = false,
                    _size = 0
                }

                if not settings.Order then
                    if self._size == 0 then
                        self._size = 11
                    end

                    self._size += 44
                end;

                if not settings.Order then
                    if ModuleManager._state then
                        Module.Size = UDim2.fromOffset(241, 93 + self._size)
                    end
                    Options.Size = UDim2.fromOffset(241, self._size)
                end

                local Dropdown = Instance.new('TextButton')
                Dropdown.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal)
                Dropdown.TextColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.Text = ''
                Dropdown.AutoButtonColor = false
                Dropdown.BackgroundTransparency = 1
                Dropdown.Name = 'Dropdown'
                Dropdown.Size = UDim2.new(0, 207, 0, 39)
                Dropdown.BorderSizePixel = 0
                Dropdown.TextSize = 14
                Dropdown.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                Dropdown.Parent = Options

                if not settings.Order then
                    Dropdown.LayoutOrder = LayoutOrderModule;
                else
                    Dropdown.LayoutOrder = settings.OrderValue;
                end;

                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {};
                end;
                
                local TextLabel = Instance.new('TextLabel')
                if GG.SelectedLanguage == "th" then
                    TextLabel.FontFace = Font.new("rbxasset://fonts/families/NotoSansThai.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    TextLabel.TextSize = 13;
                else
                    TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                    TextLabel.TextSize = 11;
                end;
                TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.TextTransparency = 0.20000000298023224
                TextLabel.Text = settings.title
                TextLabel.Size = UDim2.new(0, 207, 0, 13)
                TextLabel.BackgroundTransparency = 1
                TextLabel.TextXAlignment = Enum.TextXAlignment.Left
                TextLabel.BorderSizePixel = 0
                TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
                TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                TextLabel.Parent = Dropdown
                
                local Box = Instance.new('Frame')
                Box.ClipsDescendants = true
                Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Box.AnchorPoint = Vector2.new(0.5, 0)
                Box.BackgroundTransparency = 0.8999999761581421
                Box.Position = UDim2.new(0.5, 0, 1.2000000476837158, 0)
                Box.Name = 'Box'
                Box.Size = UDim2.new(0, 207, 0, 22)
                Box.BorderSizePixel = 0
                Box.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
                Box.Parent = TextLabel
                
                local UICorner = Instance.new('UICorner')
                UICorner.CornerRadius = UDim.new(0, 4)
                UICorner.Parent = Box
                
                local Header = Instance.new('Frame')
                Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Header.AnchorPoint = Vector2.new(0.5, 0)
                Header.BackgroundTransparency = 1
                Header.Position = UDim2.new(0.5, 0, 0, 0)
                Header.Name = 'Header'
                Header.Size = UDim2.new(0, 207, 0, 22)
                Header.BorderSizePixel = 0
                Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Header.Parent = Box
                
                local CurrentOption = Instance.new('TextLabel')
                CurrentOption.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                CurrentOption.TextColor3 = Color3.fromRGB(255, 255, 255)
                CurrentOption.TextTransparency = 0.20000000298023224
                CurrentOption.Name = 'CurrentOption'
                CurrentOption.Size = UDim2.new(0, 161, 0, 13)
                CurrentOption.AnchorPoint = Vector2.new(0, 0.5)
                CurrentOption.Position = UDim2.new(0.04999988153576851, 0, 0.5, 0)
                CurrentOption.BackgroundTransparency = 1
                CurrentOption.TextXAlignment = Enum.TextXAlignment.Left
                CurrentOption.BorderSizePixel = 0
                CurrentOption.BorderColor3 = Color3.fromRGB(0, 0, 0)
                CurrentOption.TextSize = 10
                CurrentOption.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                CurrentOption.Parent = Header
                local UIGradient = Instance.new('UIGradient')
                UIGradient.Transparency = NumberSequence.new{
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.704, 0),
                    NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                    NumberSequenceKeypoint.new(1, 1)
                }
                UIGradient.Parent = CurrentOption
                
                local Arrow = Instance.new('ImageLabel')
                Arrow.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Arrow.AnchorPoint = Vector2.new(0, 0.5)
                Arrow.Image = 'rbxassetid://84232453189324'
                Arrow.BackgroundTransparency = 1
                Arrow.Position = UDim2.new(0.9100000262260437, 0, 0.5, 0)
                Arrow.Name = 'Arrow'
                Arrow.Size = UDim2.new(0, 8, 0, 8)
                Arrow.BorderSizePixel = 0
                Arrow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Arrow.Parent = Header
                
                local Options = Instance.new('ScrollingFrame')
                Options.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
                Options.Active = true
                Options.ScrollBarImageTransparency = 1
                Options.AutomaticCanvasSize = Enum.AutomaticSize.XY
                Options.ScrollBarThickness = 0
                Options.Name = 'Options'
                Options.Size = UDim2.new(0, 207, 0, 0)
                Options.BackgroundTransparency = 1
                Options.Position = UDim2.new(0, 0, 1, 0)
                Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
                Options.BorderSizePixel = 0
                Options.CanvasSize = UDim2.new(0, 0, 0.5, 0)
                Options.Parent = Box
                
                local UIListLayout = Instance.new('UIListLayout')
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = Options
                
                local UIPadding = Instance.new('UIPadding')
                UIPadding.PaddingTop = UDim.new(0, -1)
                UIPadding.PaddingLeft = UDim.new(0, 10)
                UIPadding.Parent = Options
                
                local UIListLayout = Instance.new('UIListLayout')
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = Box

                function DropdownManager:update(option: string)
                    -- If multi-dropdown is enabled
                    if settings.multi_dropdown then
                        -- Split the CurrentOption.Text by commas into a table

                        if not Library._config._flags[settings.flag] then
                            Library._config._flags[settings.flag] = {};
                        end;

                        local CurrentTargetValue = nil;
                        
                        if #Library._config._flags[settings.flag] > 0 then

                            CurrentTargetValue = convertTableToString(Library._config._flags[settings.flag]);

                        end;

                        local selected = {}

                        if CurrentTargetValue then
                            for value in string.gmatch(CurrentTargetValue, "([^,]+)") do
                                -- Trim spaces around the option using string.match
                                local trimmedValue = value:match("^%s*(.-)%s*$")  -- Trim leading and trailing spaces
                                
                                -- Exclude any unwanted labels (e.g. "Label")
                                if trimmedValue ~= "Label" then
                                    table.insert(selected, trimmedValue)
                                end
                            end
                        else
                            for value in string.gmatch(CurrentOption.Text, "([^,]+)") do
                                -- Trim spaces around the option using string.match
                                local trimmedValue = value:match("^%s*(.-)%s*$")  -- Trim leading and trailing spaces
                                
                                -- Exclude any unwanted labels (e.g. "Label")
                                if trimmedValue ~= "Label" then
                                    table.insert(selected, trimmedValue)
                                end
                            end
                        end;
                
                        local CurrentTextGet = convertStringToTable(CurrentOption.Text);

                        optionSkibidi = "nil";
                        if typeof(option) ~= 'string' then
                            optionSkibidi = option.Name;
                        else
                            optionSkibidi = option;
                        end;

                        local found = false
                        for i, v in pairs(CurrentTextGet) do
                            if v == optionSkibidi then
                                table.remove(CurrentTextGet, i);
                                break;
                            end
                        end

                        CurrentOption.Text = table.concat(selected, ", ")
                        local OptionsChild = {}
                        -- Update the transparent effect of each option
                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then
                                table.insert(OptionsChild, object.Text)
                                if table.find(selected, object.Text) then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end

                        CurrentTargetValue = convertStringToTable(CurrentOption.Text);

                        for _, v in CurrentTargetValue do
                            if not table.find(OptionsChild, v) and table.find(selected, v) then
                                table.remove(selected, _)
                            end;
                        end;

                        CurrentOption.Text = table.concat(selected, ", ");
                
                        Library._config._flags[settings.flag] = convertStringToTable(CurrentOption.Text);
                    else
                        -- For single dropdown, just set the CurrentOption.Text to the selected option
                        CurrentOption.Text = (typeof(option) == "string" and option) or option.Name
                        for _, object in Options:GetChildren() do
                            if object.Name == "Option" then
                                -- Only update transparency for actual option text buttons
                                if object.Text == CurrentOption.Text then
                                    object.TextTransparency = 0.2
                                else
                                    object.TextTransparency = 0.6
                                end
                            end
                        end
                        Library._config._flags[settings.flag] = option
                    end
                
                    -- Save the configuration state
                    Config:save(game.GameId, Library._config)
                
                    -- Callback with the updated option(s)
                    settings.callback(option)
                end
                
                local CurrentDropSizeState = 0;

                function DropdownManager:unfold_settings()
                    self._state = not self._state

                    if self._state then
                        ModuleManager._multiplier += self._size

                        CurrentDropSizeState = self._size;

                        TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Module.Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 39 + self._size)
                        }):Play()

                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 22 + self._size)
                        }):Play()

                        TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 180
                        }):Play()
                    else
                        ModuleManager._multiplier -= self._size

                        CurrentDropSizeState = 0;

                        TweenService:Create(Module, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, 93 + ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Module.Options, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(241, ModuleManager._size + ModuleManager._multiplier)
                        }):Play()

                        TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 39)
                        }):Play()

                        TweenService:Create(Box, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.fromOffset(207, 22)
                        }):Play()

                        TweenService:Create(Arrow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 0
                        }):Play()
                    end
                end

                if #settings.options > 0 then
                    DropdownManager._size = 3

                    for index, value in settings.options do
                        local Option = Instance.new('TextButton')
                        Option.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        Option.Active = false
                        Option.TextTransparency = 0.6000000238418579
                        Option.AnchorPoint = Vector2.new(0, 0.5)
                        Option.TextSize = 10
                        Option.Size = UDim2.new(0, 186, 0, 16)
                        Option.TextColor3 = Color3.fromRGB(255, 255, 255)
                        Option.BorderColor3 = Color3.fromRGB(0, 0, 0)
                        Option.Text = (typeof(value) == "string" and value) or value.Name;
                        Option.AutoButtonColor = false
                        Option.Name = 'Option'
                        Option.BackgroundTransparency = 1
                        Option.TextXAlignment = Enum.TextXAlignment.Left
                        Option.Selectable = false
                        Option.Position = UDim2.new(0.04999988153576851, 0, 0.34210526943206787, 0)
                        Option.BorderSizePixel = 0
                        Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        Option.Parent = Options
                        
                        local UIGradient = Instance.new('UIGradient')
                        UIGradient.Transparency = NumberSequence.new{
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(0.704, 0),
                            NumberSequenceKeypoint.new(0.872, 0.36250001192092896),
                            NumberSequenceKeypoint.new(1, 1)
                        }
                        UIGradient.Parent = Option

                        Option.MouseButton1Click:Connect(function()
                            if not Library._config._flags[settings.flag] then
                                Library._config._flags[settings.flag] = {};
                            end;

                            if settings.multi_dropdown then
                                if table.find(Library._config._flags[settings.flag], value) then
                                    Library:remove_table_value(Library._config._flags[settings.flag], value)
                                else
                                    table.insert(Library._config._flags[settings.flag], value)
                                end
                            end

                            DropdownManager:update(value)
                        end)
    
                        if index > settings.maximum_options then
                            continue
                        end
    
                        DropdownManager._size += 16
                        Options.Size = UDim2.fromOffset(207, DropdownManager._size)
                    end
                end

                function DropdownManager:New(value)
                    Dropdown:Destroy(true);
                    value.OrderValue = Dropdown.LayoutOrder
                    ModuleManager._multiplier -= CurrentDropSizeState
                    return ModuleManager:create_dropdown(value)
                end;

                if Library:flag_type(settings.flag, 'string') then
                    DropdownManager:update(Library._config._flags[settings.flag])
                else
                    DropdownManager:update(settings.options[1])
                end
    
                Dropdown.MouseButton1Click:Connect(function()
                    DropdownManager:unfold_settings()
                end)

                return DropdownManager
            end

            function ModuleManager:create_feature(settings)

                local checked = false;
                
                LayoutOrderModule = LayoutOrderModule + 1
            
                if self._size == 0 then
                    self._size = 11
                end
            
                self._size += 20
            
                if ModuleManager._state then
                    Module.Size = UDim2.fromOffset(241, 93 + self._size);
                end
            
                Options.Size = UDim2.fromOffset(241, self._size);
            
                local FeatureContainer = Instance.new("Frame")
                FeatureContainer.Size = UDim2.new(0, 207, 0, 16)
                FeatureContainer.BackgroundTransparency = 1
                FeatureContainer.Parent = Options
                FeatureContainer.LayoutOrder = LayoutOrderModule
            
                local UIListLayout = Instance.new("UIListLayout")
                UIListLayout.FillDirection = Enum.FillDirection.Horizontal
                UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                UIListLayout.Parent = FeatureContainer
            
                local FeatureButton = Instance.new("TextButton")
                FeatureButton.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                FeatureButton.TextSize = 11;
                FeatureButton.Size = UDim2.new(1, -35, 0, 16)
                FeatureButton.BackgroundColor3 = Color3.fromRGB(32, 38, 51)
                FeatureButton.TextColor3 = Color3.fromRGB(210, 210, 210)
                FeatureButton.Text = "    " .. settings.title or "    " .. "Feature"
                FeatureButton.AutoButtonColor = false
                FeatureButton.TextXAlignment = Enum.TextXAlignment.Left
                FeatureButton.TextTransparency = 0.2
                FeatureButton.Parent = FeatureContainer
            
                local RightContainer = Instance.new("Frame")
                RightContainer.Size = UDim2.new(0, 45, 0, 16)
                RightContainer.BackgroundTransparency = 1
                RightContainer.Parent = FeatureContainer
            
                local RightLayout = Instance.new("UIListLayout")
                RightLayout.Padding = UDim.new(0.1, 0)
                RightLayout.FillDirection = Enum.FillDirection.Horizontal
                RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
                RightLayout.Parent = RightContainer
            
                local KeybindBox = Instance.new("TextLabel")
                KeybindBox.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal);
                KeybindBox.Size = UDim2.new(0, 15, 0, 15)
                KeybindBox.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
                KeybindBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                KeybindBox.TextSize = 11
                KeybindBox.BackgroundTransparency = 1
                KeybindBox.LayoutOrder = 2;
                KeybindBox.Parent = RightContainer
            
                local KeybindButton = Instance.new("TextButton")
                KeybindButton.Size = UDim2.new(1, 0, 1, 0)
                KeybindButton.BackgroundTransparency = 1
                KeybindButton.TextTransparency = 1
                KeybindButton.Parent = KeybindBox

                local CheckboxCorner = Instance.new("UICorner", KeybindBox)
                CheckboxCorner.CornerRadius = UDim.new(0, 3)

                local UIStroke = Instance.new("UIStroke", KeybindBox)
                UIStroke.Color = Color3.fromRGB(152, 181, 255)
                UIStroke.Thickness = 1
                UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            
                if not Library._config._flags then
                    Library._config._flags = {}
                end
            
                if not Library._config._flags[settings.flag] then
                    Library._config._flags[settings.flag] = {
                        checked = false,
                        BIND = settings.default or "Unknown"
                    }
                end
            
                checked = Library._config._flags[settings.flag].checked
                KeybindBox.Text = Library._config._flags[settings.flag].BIND

                if KeybindBox.Text == "Unknown" then
                    KeybindBox.Text = "...";
                end;

                local UseF_Var = nil;
            
                if not settings.disablecheck then
                    local Checkbox = Instance.new("TextButton")
                    Checkbox.Size = UDim2.new(0, 15, 0, 15)
                    Checkbox.BackgroundColor3 = checked and Color3.fromRGB(152, 181, 255) or Color3.fromRGB(32, 38, 51)
                    Checkbox.Text = ""
                    Checkbox.Parent = RightContainer
                    Checkbox.LayoutOrder = 1;

                    local UIStroke = Instance.new("UIStroke", Checkbox)
                    UIStroke.Color = Color3.fromRGB(152, 181, 255)
                    UIStroke.Thickness = 1
                    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                
                    local CheckboxCorner = Instance.new("UICorner")
                    CheckboxCorner.CornerRadius = UDim.new(0, 3)
                    CheckboxCorner.Parent = Checkbox
            
                    local function toggleState()
                        checked = not checked
                        Checkbox.BackgroundColor3 = checked and Color3.fromRGB(152, 181, 255) or Color3.fromRGB(32, 38, 51)
                        Library._config._flags[settings.flag].checked = checked
                        Config:save(game.GameId, Library._config)
                        if settings.callback then
                            settings.callback(checked)
                        end
                    end

                    UseF_Var = toggleState
                
                    Checkbox.MouseButton1Click:Connect(toggleState)

                else

                    UseF_Var = function()
                        settings.button_callback();
                    end;

                end;
            
                KeybindButton.MouseButton1Click:Connect(function()
                    KeybindBox.Text = "..."
                    local inputConnection
                    inputConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                        if gameProcessed then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            local newKey = input.KeyCode.Name
                            Library._config._flags[settings.flag].BIND = newKey
                            if newKey ~= "Unknown" then
                                KeybindBox.Text = newKey;
                            end;
                            Config:save(game.GameId, Library._config) -- Save new keybind
                            inputConnection:Disconnect()
                        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                            Library._config._flags[settings.flag].BIND = "Unknown"
                            KeybindBox.Text = "..."
                            Config:save(game.GameId, Library._config)
                            inputConnection:Disconnect()
                        end
                    end)
                    Connections["keybind_input_" .. settings.flag] = inputConnection
                end)
            
                local keyPressConnection
                keyPressConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode.Name == Library._config._flags[settings.flag].BIND then
                            UseF_Var();
                        end
                    end
                end)
                Connections["keybind_press_" .. settings.flag] = keyPressConnection
            
                FeatureButton.MouseButton1Click:Connect(function()
                    if settings.button_callback then
                        settings.button_callback()
                    end
                end)

                if not settings.disablecheck then
                    settings.callback(checked);
                end;
            
                return FeatureContainer
            end                    

            return ModuleManager
        end

        return TabManager
    end

    Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input: InputObject, process: boolean)
        if input.KeyCode ~= Enum.KeyCode.Insert then
            return
        end

        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    self._ui.Container.Handler.Minimize.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    return self
end

local main = Library.new()

local rage = main:create_tab('Autoparry', 'rbxassetid://76499042599127')
local detectionstab = main:create_tab('Detection', 'rbxassetid://10734951847')
local set = main:create_tab('Spam', 'rbxassetid://10709781460')
local pl = main:create_tab('Player', 'rbxassetid://126017907477623')
local visuals = main:create_tab('Visuals', 'rbxassetid://10723346959')
local misc = main:create_tab('Misc', 'rbxassetid://132243429647479')
local devJV = main:create_tab('Exclusive', 'rbxassetid://10734966248')

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

local autoparry_module = rage:create_module({
    title = 'Auto Parry',
    flag = 'Auto_Parry',
    description = 'Automatically parries ball',
    section = 'left',
    callback = function(value)
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

autoparry_module:create_dropdown({
    title = "Parry Mode",
    flag = "autoparry_mode",
    options = {"Remote", "Keypress"},
    default = "Remote",
    multi_dropdown = false,
    maximum_options = 2,
    callback = function(value)
        getgenv().AutoParryMode = value
    end
})

local AutoCurveDropdown = autoparry_module:create_dropdown({
    title = "AutoCurve",
    flag = "curve_type",
    options = System.__config.__curve_names,
    multi_dropdown = false,
    maximum_options = 6,
    callback = function(value)
        for i, name in ipairs(System.__config.__curve_names) do
            if name == value then
                System.__properties.__curve_mode = i
                break
            end
        end
    end
})

autoparry_module:create_slider({
    title = 'Parry Accuracy',
    flag = 'Parry_Accuracy',
    maximum_value = 100,
    minimum_value = 1,
    value = 50,
    round_number = true,
    callback = function(value)
        System.__properties.__accuracy = value
        update_divisor()
    end
})

autoparry_module:create_checkbox({
    title = "Play Animation",
    flag = "Play_Animation",
    callback = function(value)
        System.__properties.__play_animation = value
    end
})

autoparry_module:create_divider({})

autoparry_module:create_checkbox({
    title = "Notify",
    flag = "Auto_Parry_Notify",
    callback = function(value)
        getgenv().AutoParryNotify = value
    end
})

autoparry_module:create_checkbox({
    title = "Cooldown Protection",
    flag = "CooldownProtection",
    callback = function(value)
        getgenv().CooldownProtection = value
    end
})

autoparry_module:create_checkbox({
    title = "Auto Ability",
    flag = "AutoAbility",
    callback = function(value)
        getgenv().AutoAbility = value
    end
})

local triggerbot_module = rage:create_module({
    title = "Triggerbot",
    description = "Parries instantly if targeted",
    flag = "triggerbot",
    section = 'right',
    callback = function(value)
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

triggerbot_module:create_checkbox({
    title = "Notify",
    flag = "TriggerbotNotify",
    callback = function(value)
        getgenv().TriggerbotNotify = value
    end
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

local hotkeyModule = rage:create_module({
    title = "AutoCurve Hotkey" .. (System.__properties.__is_mobile and "(Mobile)" or "(PC)"),
    description = "Press 1-6 to change curve",
    flag = "autocurve_hotkey",
    section = "left",
    callback = function(state)
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

hotkeyModule:create_checkbox({
    title = "Notify",
    flag = "AutoCurveHotkeyNotify",
    callback = function(value)
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

--[[local AimPlayer = {}

local state = {
    playerNames = {},
    playerMap = {},
    selectedTarget = nil,
    isEnabled = false,
    notificationsEnabled = false,
    silentSelection = false,
    dropdown = nil
}

local config = {
    refreshDelay = 0.5,
    notificationDuration = 3,
    maxOptions = 20
}

local function formatPlayerDisplay(player)
    return string.format("%s (@%s)", player.DisplayName or "Unknown", player.Name or "Unknown")
end

local function sendNotification(title, text)
    if not state.notificationsEnabled then return end
    
    Library.SendNotification({
        title = title,
        text = text,
        duration = config.notificationDuration
    })
end

function AimPlayer.updatePlayerList()
    table.clear(state.playerNames)
    table.clear(state.playerMap)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player:IsDescendantOf(Players) then
            local display = formatPlayerDisplay(player)
            table.insert(state.playerNames, display)
            state.playerMap[display] = player.Name
        end
    end

    if #state.playerNames == 0 then
        table.insert(state.playerNames, "No Players Available")
    end
end

function AimPlayer.refreshDropdown()
    AimPlayer.updatePlayerList()
    
    if state.dropdown and typeof(state.dropdown.set_options) == "function" then
        state.dropdown:set_options(state.playerNames)

        if state.selectedTarget then
            for display, name in pairs(state.playerMap) do
                if name == state.selectedTarget then
                    state.silentSelection = true
                    state.dropdown:update(display)
                    state.silentSelection = false
                    return
                end
            end

            AimPlayer.clearTarget("Selected player is no longer available")
        end
    end
end

function AimPlayer.setTarget(displayString)
    if displayString == "No Players Available" then
        AimPlayer.clearTarget()
        return
    end
    
    local targetName = state.playerMap[displayString]
    if not targetName then return end
    
    state.selectedTarget = targetName
    getgenv().SelectedTarget = targetName
    
    if not state.silentSelection then
        sendNotification("Target Player", "Now targeting: " .. displayString)
    end
end

function AimPlayer.clearTarget(message)
    state.selectedTarget = nil
    getgenv().SelectedTarget = nil
    
    if message then
        sendNotification("Target Player", message)
    end
end

function AimPlayer.toggle(enabled)
    state.isEnabled = enabled
    variables.targetplayer = enabled
    variables.toggles = variables.toggles or {}
    variables.toggles.targetplayer = enabled
    
    sendNotification(
        "Player Aim Notification",
        enabled and "Player Aim has been turned ON" or "Player Aim has been turned OFF"
    )
end

function AimPlayer.setNotifications(enabled)
    state.notificationsEnabled = enabled
    getgenv().TargetPlayerNotify = enabled
end

local function onPlayerAdded()
    task.wait(config.refreshDelay)
    AimPlayer.refreshDropdown()
end

local function onPlayerRemoving(player)
    task.wait(config.refreshDelay)
    
    if state.selectedTarget == player.Name then
        AimPlayer.clearTarget("Selected player left the game")
    end
    
    AimPlayer.refreshDropdown()
end

AimPlayer.updatePlayerList()

local targetModule = rage:create_module({
    title = "Player Aim",
    description = "Target a specific player only",
    flag = "targetplayer",
    section = "left",
    callback = AimPlayer.toggle
})

targetModule:create_checkbox({
    title = "Notify",
    flag = "TargetPlayerNotify",
    callback = AimPlayer.setNotifications
})

state.dropdown = targetModule:create_dropdown({
    title = "Select Target",
    flag = "TargetPlayerName",
    options = state.playerNames,
    multi_dropdown = false,
    maximum_options = config.maxOptions,
    callback = AimPlayer.setTarget
})

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

function AimPlayer.getTarget()
    return state.selectedTarget
end

function AimPlayer.isEnabled()
    return state.isEnabled
end

function AimPlayer.getTargetPlayer()
    if not state.selectedTarget then return nil end
    return Players:FindFirstChild(state.selectedTarget)
end]]

detectionstab:create_module({
    title = 'Infinity Detection',
    flag = 'Infinity',
    description = '',
    section = 'left',
    callback = function(value)
        System.__config.__detections.__infinity = value
    end
})

detectionstab:create_module({
    title = 'Death Slash Detection',
    flag = 'Death_Slash',
    description = '',
    section = 'right',
    callback = function(value)
        System.__config.__detections.__deathslash = value
    end
})

detectionstab:create_module({
    title = 'Time Hole Detection',
    flag = 'Time_Hole',
    description = '',
    section = 'left',
    callback = function(value)
        System.__config.__detections.__timehole = value
    end
})

local slashes_module = detectionstab:create_module({
    title = 'Slashes Of Fury Detection',
    flag = 'Slashes_Of_Fury',
    description = '',
    section = 'right',
    callback = function(value)
        System.__config.__detections.__slashesoffury = value
    end
})

slashes_module:create_slider({
    title = "Parry Delay",
    minimum_value = 0.05,
    maximum_value = 0.250,
    value = 0.05,
    round_number = true,
    flag = "parry_delay",
    callback = function(value)
        parryDelay = value
    end
})

slashes_module:create_slider({
    title = "Max Parry Count",
    minimum_value = 1,
    maximum_value = 36,
    value = 36,
    round_number = true,
    flag = "max_parry_count",
    callback = function(value)
        maxParryCount = value
    end
})

detectionstab:create_module({
    title = 'Anti-Phantom [BETA]',
    flag = 'Anti_Phantom',
    description = '',
    section = 'left',
    callback = function(value)
        System.__config.__detections.__phantom = value
    end
})

local manual_spam_module = set:create_module({
    title = "Manual Spam",
    description = "High-frequency parry spam",
    flag = "manualspam",
    section = "left",
    callback = function(state)
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

manual_spam_module:create_checkbox({
    title = "Notify",
    flag = "ManualSpamNotify",
    callback = function(value)
        getgenv().ManualSpamNotify = value
    end
})

manual_spam_module:create_dropdown({
    title = "Mode",
    flag = "manualspam_mode",
    options = {"Remote", "Keypress"},
    default = "Remote",
    multi_dropdown = false,
    maximum_options = 2,
    callback = function(value)
        getgenv().ManualSpamMode = value
    end
})

manual_spam_module:create_checkbox({
    title = "Animation Fix",
    flag = "ManualSpamAnimationFix",
    callback = function(value)
        getgenv().ManualSpamAnimationFix = value
    end
})

manual_spam_module:create_slider({
    title = 'Spam Rate',
    flag = 'Spam_Rate',
    maximum_value = 5000,
    minimum_value = 60,
    value = 240,
    round_number = true,
    callback = function(value)
        System.__properties.__spam_rate = value
    end
})

local auto_spam_module = set:create_module({
    title = 'Auto Spam',
    flag = 'Auto_Spam_Parry',
    description = 'Automatically spam parries ball',
    section = 'right',
    callback = function(value)
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

auto_spam_module:create_checkbox({
    title = "Notify",
    flag = "Auto_Spam_Notify",
    callback = function(value)
        getgenv().AutoSpamNotify = value
    end
})

auto_spam_module:create_dropdown({
    title = "Mode",
    flag = "autospam_mode",
    options = {"Remote", "Keypress"},
    default = "Remote",
    multi_dropdown = false,
    maximum_options = 2,
    callback = function(value)
        getgenv().AutoSpamMode = value
    end
})

auto_spam_module:create_checkbox({
    title = "Animation Fix",
    flag = "AutoSpamAnimationFix",
    callback = function(value)
        getgenv().AutoSpamAnimationFix = value
    end
})

auto_spam_module:create_slider({
    title = "Parry Threshold",
    flag = "Parry_Threshold",
    maximum_value = 5,
    minimum_value = 1,
    value = 2.5,
    round_number = false,
    callback = function(value)
        System.__properties.__spam_threshold = value
    end
})

-- Versão reforçada do Avatar Changer (mantive o modelo do script e assinaturas)
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

local module = pl:create_module({
    title = 'Avatar Changer',
    flag = 'AvatarChanger',
    description = 'Change your avatar to another player',
    section = 'left',
    callback = function(val)
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

module:create_textbox({
    title = "Target Username",
    placeholder = "Enter Username...",
    flag = "AvatarChangerTextbox",
    callback = function(val: string)
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

local animations_module = pl:create_module({
    title = 'Emotes',
    flag = 'Emotes',
    description = 'Custom Emotes',
    section = 'right',
    callback = function(value)
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

animations_module:create_checkbox({
    title = "Auto Stop",
    flag = "AutoStop",
    callback = function(value)
        getgenv().AutoStop = value
    end
})

local animation_dropdown = animations_module:create_dropdown({
    title = 'Emote Type',
    flag = 'Selected_Animation',
    options = emotes_data,
    multi_dropdown = false,
    maximum_options = 10,
    callback = function(value)
        selected_animation = value
        
        if getgenv().Animations then
            animation_system.play(value)
        end
    end
})

animation_dropdown:update(selected_animation)

local CameraToggle = pl:create_module({
    title = 'FOV',
    flag = 'FOV',
    
    description = 'Changes Camera POV',
    section = 'left',
    
    callback = function(value)
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
    
CameraToggle:create_slider({
    title = 'Camera FOV',
    flag = 'Camera_FOV',
    
    maximum_value = 120,
    minimum_value = 50,
    value = 70,
    
    round_number = true,
    
    callback = function(value)
        getgenv().CameraFOV = value
        if getgenv().CameraEnabled then
            game:GetService("Workspace").CurrentCamera.FieldOfView = value
        end
    end
})

local CharacterModifier = pl:create_module({
    title = 'Character',
    flag = 'CharacterModifier',
    description = 'Changes various character properties',
    section = 'right',

    callback = function(value)
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

CharacterModifier:create_checkbox({
    title = "Infinite Jump",
    flag = "InfiniteJumpCheckbox",
    callback = function(value)
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

CharacterModifier:create_divider({})

CharacterModifier:create_checkbox({
    title = "Spin",
    flag = "SpinbotCheckbox",
    callback = function(value)
        getgenv().SpinbotCheckboxEnabled = value
        
        if not value and getgenv().CharacterModifierEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and getgenv().OriginalValues then
                char.Humanoid.AutoRotate = getgenv().OriginalValues.AutoRotate or true
            end
        end
    end
})

CharacterModifier:create_slider({
    title = 'Spin Speed',
    flag = 'CustomSpinSpeed',
    maximum_value = 50,
    minimum_value = 1,
    value = 5,
    round_number = true,

    callback = function(value)
        getgenv().CustomSpinSpeed = value
    end
})

CharacterModifier:create_divider({})

CharacterModifier:create_checkbox({
    title = "Walk Speed",
    flag = "WalkspeedCheckbox",
    callback = function(value)
        getgenv().WalkspeedCheckboxEnabled = value
        
        if not value and getgenv().CharacterModifierEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and getgenv().OriginalValues then
                char.Humanoid.WalkSpeed = getgenv().OriginalValues.WalkSpeed or 16
            end
        end
    end
})

CharacterModifier:create_slider({
    title = 'Walk Speed Value',
    flag = 'CustomWalkSpeed',
    maximum_value = 500,
    minimum_value = 16,
    value = 36,
    round_number = true,

    callback = function(value)
        getgenv().CustomWalkSpeed = value
        
        if getgenv().CharacterModifierEnabled and getgenv().WalkspeedCheckboxEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = value
            end
        end
    end
})

CharacterModifier:create_divider({})

CharacterModifier:create_checkbox({
    title = "Jump Power",
    flag = "JumpPowerCheckbox",
    callback = function(value)
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

CharacterModifier:create_slider({
    title = 'Jump Power Value',
    flag = 'CustomJumpPower',
    maximum_value = 200,
    minimum_value = 50,
    value = 50,
    round_number = true,

    callback = function(value)
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

CharacterModifier:create_divider({})

CharacterModifier:create_checkbox({
    title = "Gravity",
    flag = "GravityCheckbox",
    callback = function(value)
        getgenv().GravityCheckboxEnabled = value
        
        if not value and getgenv().CharacterModifierEnabled then
            workspace.Gravity = 196.2
        end
    end
})

CharacterModifier:create_slider({
    title = 'Gravity Value',
    flag = 'CustomGravity',
    maximum_value = 400.0,
    minimum_value = 0,
    value = 196.2,
    round_number = true,

    callback = function(value)
        getgenv().CustomGravity = value
        
        if getgenv().CharacterModifierEnabled and getgenv().GravityCheckboxEnabled then
            workspace.Gravity = value
        end
    end
})

CharacterModifier:create_divider({})

CharacterModifier:create_checkbox({
    title = "Hip Height",
    flag = "HipHeightCheckbox",
    callback = function(value)
        getgenv().HipHeightCheckboxEnabled = value
        
        if not value and getgenv().CharacterModifierEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") and getgenv().OriginalValues then
                char.Humanoid.HipHeight = getgenv().OriginalValues.HipHeight or 0
            end
        end
    end
})

CharacterModifier:create_slider({
    title = 'Hip Height Value',
    flag = 'CustomHipHeight',
    maximum_value = 20,
    minimum_value = -5,
    value = 0,
    round_number = true,

    callback = function(value)
        getgenv().CustomHipHeight = value
        
        if getgenv().CharacterModifierEnabled and getgenv().HipHeightCheckboxEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.HipHeight = value
            end
        end
    end
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

visuals:create_module({
    title = 'Ability ESP',
    flag = 'AbilityESP',
    description = 'Displays Player Abilities',
    section = 'left',
    callback = function(value)
        ability_esp.toggle(value)
    end
})

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

local save_folder = workspace:FindFirstChild("OwO") or Instance.new("Folder", workspace)
save_folder.Name = "OwO"

local function load_pos()
    local file = save_folder:FindFirstChild("ball_ui_pos")
    if not file then return nil end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(file.Value)
    end)

    if ok and data and data.x and data.y then
        return UDim2.new(0, data.x, 0, data.y)
    end

    return nil
end

local function save_pos(udim)
    local data = {
        x = udim.X.Offset,
        y = udim.Y.Offset
    }

    local json = HttpService:JSONEncode(data)

    local file = save_folder:FindFirstChild("ball_ui_pos") or Instance.new("StringValue", save_folder)
    file.Name = "ball_ui_pos"
    file.Value = json
end


local ball_velocity = {
    __config = {
        gui_name = "BallStatsGui",
        colors = {
            background = Color3.fromRGB(18, 18, 18),
            container = Color3.fromRGB(28, 28, 28),
            header = Color3.fromRGB(12, 12, 12),
            text_primary = Color3.fromRGB(255, 255, 255),
            text_secondary = Color3.fromRGB(170, 170, 170),
            accent_green = Color3.fromRGB(34, 197, 94),
            accent_orange = Color3.fromRGB(249, 115, 22),
            border = Color3.fromRGB(40, 40, 40)
        }
    },

    __state = {
        active = false,
        gui = nil,
        ball_data = {},
        is_dragging = false
    }
}

function ball_velocity.create_corner(radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    return corner
end

function ball_velocity.create_stroke(thickness, color)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1
    stroke.Color = color or ball_velocity.__config.colors.border
    return stroke
end

function ball_velocity.create_gui()
    local gui = Instance.new("ScreenGui")
    gui.Name = ball_velocity.__config.gui_name
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = LocalPlayer:WaitForChild("CoreGui")

    local main_frame = Instance.new("Frame")
    main_frame.Name = "MainFrame"
    main_frame.Size = UDim2.new(0, 180, 0, 95)
    main_frame.Position = load_pos() or UDim2.new(0, 20, 0, 150)
    main_frame.BackgroundColor3 = ball_velocity.__config.colors.background
    main_frame.BorderSizePixel = 0
    main_frame.Parent = gui

    ball_velocity.create_corner(10).Parent = main_frame
    ball_velocity.create_stroke(1, ball_velocity.__config.colors.border).Parent = main_frame

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 26)
    header.Position = UDim2.new(0, 0, 0, 0)
    header.BackgroundColor3 = ball_velocity.__config.colors.header
    header.BorderSizePixel = 0
    header.Parent = main_frame

    ball_velocity.create_corner(10).Parent = header

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -12, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Ball Stats"
    title.TextColor3 = ball_velocity.__config.colors.text_primary
    title.TextSize = 13
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -18, 1, -34)
    content.Position = UDim2.new(0, 9, 0, 30)
    content.BackgroundTransparency = 1
    content.Parent = main_frame

    local current_label = Instance.new("TextLabel")
    current_label.Name = "CurrentLabel"
    current_label.Size = UDim2.new(1, 0, 0, 14)
    current_label.Position = UDim2.new(0, 0, 0, 2)
    current_label.BackgroundTransparency = 1
    current_label.Text = "Current"
    current_label.TextColor3 = ball_velocity.__config.colors.text_secondary
    current_label.TextSize = 10
    current_label.Font = Enum.Font.Gotham
    current_label.TextXAlignment = Enum.TextXAlignment.Left
    current_label.Parent = content

    local current_value = Instance.new("TextLabel")
    current_value.Name = "CurrentValue"
    current_value.Size = UDim2.new(1, 0, 0, 20)
    current_value.Position = UDim2.new(0, 0, 0, 14)
    current_value.BackgroundTransparency = 1
    current_value.Text = "0.0"
    current_value.TextColor3 = ball_velocity.__config.colors.accent_green
    current_value.TextSize = 16
    current_value.Font = Enum.Font.GothamBold
    current_value.TextXAlignment = Enum.TextXAlignment.Left
    current_value.Parent = content

    local peak_label = Instance.new("TextLabel")
    peak_label.Name = "PeakLabel"
    peak_label.Size = UDim2.new(1, 0, 0, 14)
    peak_label.Position = UDim2.new(0, 0, 0, 36)
    peak_label.BackgroundTransparency = 1
    peak_label.Text = "Peak"
    peak_label.TextColor3 = ball_velocity.__config.colors.text_secondary
    peak_label.TextSize = 10
    peak_label.Font = Enum.Font.Gotham
    peak_label.TextXAlignment = Enum.TextXAlignment.Left
    peak_label.Parent = content

    local peak_value = Instance.new("TextLabel")
    peak_value.Name = "PeakValue"
    peak_value.Size = UDim2.new(1, 0, 0, 20)
    peak_value.Position = UDim2.new(0, 0, 0, 50)
    peak_value.BackgroundTransparency = 1
    peak_value.Text = "0.0"
    peak_value.TextColor3 = ball_velocity.__config.colors.accent_orange
    peak_value.TextSize = 16
    peak_value.Font = Enum.Font.GothamBold
    peak_value.TextXAlignment = Enum.TextXAlignment.Left
    peak_value.Parent = content


    local drag_start, start_pos

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            ball_velocity.__state.is_dragging = true
            drag_start = input.Position
            start_pos = main_frame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if ball_velocity.__state.is_dragging and
            (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then

            local delta = input.Position - drag_start
            local newpos = UDim2.new(
                start_pos.X.Scale, start_pos.X.Offset + delta.X,
                start_pos.Y.Scale, start_pos.Y.Offset + delta.Y
            )

            main_frame.Position = newpos
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            ball_velocity.__state.is_dragging = false
            save_pos(main_frame.Position)
        end
    end)

    return gui, current_value, peak_value
end

function ball_velocity.start()
    if ball_velocity.__state.active then return end

    ball_velocity.__state.active = true
    ball_velocity.__state.ball_data = {}

    local gui, current_value, peak_value = ball_velocity.create_gui()
    ball_velocity.__state.gui = gui

    System.__properties.__connections.ball_velocity =
        RunService.Heartbeat:Connect(function()

            local ball = System.ball.get()

            if not ball then
                current_value.Text = "0.0"
                peak_value.Text = "0.0"
                return
            end

            local zoomies = ball:FindFirstChild("zoomies")
            if not zoomies then
                current_value.Text = "0.0"
                return
            end

            local velocity = zoomies.VectorVelocity.Magnitude

            ball_velocity.__state.ball_data[ball] =
                ball_velocity.__state.ball_data[ball] or 0

            if velocity > ball_velocity.__state.ball_data[ball] then
                ball_velocity.__state.ball_data[ball] = velocity
            end

            current_value.Text = string.format("%.1f", velocity)
            peak_value.Text = string.format("%.1f",
                ball_velocity.__state.ball_data[ball])
        end)
end

function ball_velocity.stop()
    if not ball_velocity.__state.active then return end

    ball_velocity.__state.active = false

    if System.__properties.__connections.ball_velocity then
        System.__properties.__connections.ball_velocity:Disconnect()
        System.__properties.__connections.ball_velocity = nil
    end

    if ball_velocity.__state.gui then
        ball_velocity.__state.gui:Destroy()
        ball_velocity.__state.gui = nil
    end

    ball_velocity.__state.ball_data = {}
end

visuals:create_module({
    title = "Show Ball Velocity",
    description = "",
    flag = "ballvelocity",
    section = "right",
    callback = function(state)
        if state then
            ball_velocity.start()
        else
            ball_velocity.stop()
        end
    end
})

local Connections_Manager = {}

    local No_Render = misc:create_module({
        title = 'No Render',
        flag = 'No_Render',
        description = 'Disables rendering of effects',
        section = 'left',
        
        callback = function(state)
            LocalPlayer.PlayerScripts.EffectScripts.ClientFX.Disabled = state
    
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

    No_Render:change_state(false)

--[[local ParticleSystem = {
    Particles = {},
    MaxParticles = 5000,
    SpawnArea = 500,
    FallSpeed = 25,
    SpawnHeight = 100,
    SpawnRate = 3,
    ParticleColor = Color3.fromRGB(100, 200, 255),
    Enabled = false
}

local ParticleFolder = Instance.new("Folder")
ParticleFolder.Name = "MagicalParticles"
ParticleFolder.Parent = Workspace

local Particles = {}

function Particles.create()
    local particle = Instance.new("Part")
    particle.Name = "MagicalParticle"
    particle.Size = Vector3.new(0.9, 0.9, 0.9)
    particle.Shape = Enum.PartType.Ball
    particle.Material = Enum.Material.Neon
    particle.Color = ParticleSystem.ParticleColor
    particle.CanCollide = false
    particle.Anchored = true
    particle.Transparency = 0
    particle.CastShadow = false
    particle.Parent = ParticleFolder
    
    local light = Instance.new("PointLight")
    light.Brightness = 2.5
    light.Range = 10
    light.Color = ParticleSystem.ParticleColor
    light.Parent = particle
    
    local trail = Instance.new("Trail")
    trail.Lifetime = 0.5
    trail.MinLength = 0.1
    trail.FaceCamera = true
    trail.LightEmission = 0.8
    trail.Color = ColorSequence.new(ParticleSystem.ParticleColor)
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.4),
        NumberSequenceKeypoint.new(1, 1)
    })
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0)
    })
    
    local attachment0 = Instance.new("Attachment")
    attachment0.Parent = particle
    local attachment1 = Instance.new("Attachment")
    attachment1.Parent = particle
    attachment1.Position = Vector3.new(0, -0.6, 0)
    
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    trail.Parent = particle
    
    return particle
end

function Particles.get_player_position()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        return character.HumanoidRootPart.Position
    end
    return Camera.CFrame.Position
end

function Particles.spawn()
    if not ParticleSystem.Enabled then return end
    if #ParticleSystem.Particles >= ParticleSystem.MaxParticles then return end
    
    local player_pos = Particles.get_player_position()
    local random_x = player_pos.X + math.random(-ParticleSystem.SpawnArea, ParticleSystem.SpawnArea)
    local random_z = player_pos.Z + math.random(-ParticleSystem.SpawnArea, ParticleSystem.SpawnArea)
    local spawn_y = player_pos.Y + ParticleSystem.SpawnHeight
    
    local particle = Particles.create()
    particle.Position = Vector3.new(random_x, spawn_y, random_z)
    
    local particle_data = {
        Part = particle,
        Velocity = Vector3.new(
            math.random(-2, 2),
            -ParticleSystem.FallSpeed,
            math.random(-2, 2)
        ),
        RotationSpeed = Vector3.new(
            math.random(-3, 3),
            math.random(-3, 3),
            math.random(-3, 3)
        ),
        FloatAmplitude = math.random(2, 5),
        FloatFrequency = math.random(2, 4),
        TimeAlive = 0
    }
    
    table.insert(ParticleSystem.Particles, particle_data)
end

function Particles.update(delta_time)
    local player_pos = Particles.get_player_position()
    
    for i = #ParticleSystem.Particles, 1, -1 do
        local particle_data = ParticleSystem.Particles[i]
        local particle = particle_data.Part
        
        if not particle or not particle.Parent then
            table.remove(ParticleSystem.Particles, i)
            continue
        end
        
        particle_data.TimeAlive = particle_data.TimeAlive + delta_time
        
        local float_x = math.sin(particle_data.TimeAlive * particle_data.FloatFrequency) * particle_data.FloatAmplitude * delta_time
        local float_z = math.cos(particle_data.TimeAlive * particle_data.FloatFrequency) * particle_data.FloatAmplitude * delta_time
        
        local new_position = particle.Position + Vector3.new(
            particle_data.Velocity.X * delta_time + float_x,
            particle_data.Velocity.Y * delta_time,
            particle_data.Velocity.Z * delta_time + float_z
        )
        
        particle.Position = new_position
        particle.Orientation = particle.Orientation + particle_data.RotationSpeed
        
        local distance_to_player = (new_position - player_pos).Magnitude
        if distance_to_player > ParticleSystem.SpawnArea * 1.5 then
            particle:Destroy()
            table.remove(ParticleSystem.Particles, i)
            continue
        end
        
        if new_position.Y < player_pos.Y - 20 then
            particle:Destroy()
            table.remove(ParticleSystem.Particles, i)
        end
    end
end

function Particles.clear_all()
    for i = #ParticleSystem.Particles, 1, -1 do
        local particle_data = ParticleSystem.Particles[i]
        if particle_data.Part then
            particle_data.Part:Destroy()
        end
        table.remove(ParticleSystem.Particles, i)
    end
end

function Particles.update_colors()
    for _, particle_data in ipairs(ParticleSystem.Particles) do
        local particle = particle_data.Part
        if particle and particle.Parent then
            particle.Color = ParticleSystem.ParticleColor
            local light = particle:FindFirstChildOfClass("PointLight")
            if light then
                light.Color = ParticleSystem.ParticleColor
            end
            local trail = particle:FindFirstChildOfClass("Trail")
            if trail then
                trail.Color = ColorSequence.new(ParticleSystem.ParticleColor)
            end
        end
    end
end

local BallSystem = {}

function BallSystem.get_ball()
    local balls = Workspace:FindFirstChild('Balls')
    if not balls then return nil end
    
    for _, ball in pairs(balls:GetChildren()) do
        if not ball:GetAttribute('realBall') then
            ball.CanCollide = false
            return ball
        end
    end
    return nil
end

local PlasmaTrails = {
    Active = false,
    Enabled = false,
    TrailAttachments = {},
    NumTrails = 8,
    TrailColor = Color3.fromRGB(0, 255, 255)
}

local Plasma = {}

function Plasma.create_trails(ball)
    if PlasmaTrails.Active then return end
    
    PlasmaTrails.Active = true
    PlasmaTrails.TrailAttachments = {}
    
    for i = 1, PlasmaTrails.NumTrails do
        local angle = (i / PlasmaTrails.NumTrails) * math.pi * 2
        local radius = math.random(150, 250) / 100
        local height = math.random(-150, 150) / 100
        
        local offset1 = Vector3.new(
            math.cos(angle) * radius,
            height + math.sin(angle * 3) * 0.8,
            math.sin(angle) * radius
        )
        
        local offset2 = Vector3.new(
            math.cos(angle + math.pi * 0.7) * radius * 1.3,
            -height + math.cos(angle * 2.5) * 0.8,
            math.sin(angle + math.pi * 0.7) * radius * 1.3
        )
        
        local attachment0 = Instance.new("Attachment")
        attachment0.Name = "PlasmaAttachment0_" .. i
        attachment0.Position = offset1
        attachment0.Parent = ball
        
        local attachment1 = Instance.new("Attachment")
        attachment1.Name = "PlasmaAttachment1_" .. i
        attachment1.Position = offset2
        attachment1.Parent = ball
        
        local trail = Instance.new("Trail")
        trail.Name = "PlasmaTrail_" .. i
        trail.Attachment0 = attachment0
        trail.Attachment1 = attachment1
        trail.Lifetime = 0.6
        trail.MinLength = 0
        trail.FaceCamera = true
        trail.LightEmission = 1
        trail.LightInfluence = 0
        trail.Texture = "rbxassetid://5029929719"
        trail.TextureMode = Enum.TextureMode.Stretch
        
        local base_color = PlasmaTrails.TrailColor
        trail.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, base_color),
            ColorSequenceKeypoint.new(0.5, Color3.new(
                math.min(base_color.R * 1.3, 1),
                math.min(base_color.G * 1.3, 1),
                math.min(base_color.B * 1.3, 1)
            )),
            ColorSequenceKeypoint.new(1, base_color)
        })
        
        trail.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(0.3, 0),
            NumberSequenceKeypoint.new(0.7, 0.3),
            NumberSequenceKeypoint.new(1, 1)
        })
        
        trail.WidthScale = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(0.3, 0.25),
            NumberSequenceKeypoint.new(0.7, 0.15),
            NumberSequenceKeypoint.new(1, 0.02)
        })
        
        trail.Parent = ball
        
        table.insert(PlasmaTrails.TrailAttachments, {
            attachment0 = attachment0,
            attachment1 = attachment1,
            trail = trail,
            baseAngle = angle,
            angle = 0,
            speed = math.random(15, 30) / 10,
            spiralSpeed = math.random(25, 45) / 10,
            radiusMultiplier = math.random(80, 130) / 100,
            pulseOffset = math.random() * math.pi * 2,
            baseRadius = radius,
            baseHeight = height,
            chaosSpeed = math.random(10, 20) / 10
        })
    end
end

function Plasma.animate_trails(ball, delta_time)
    if not PlasmaTrails.Active then return end
    
    local time = tick()
    
    for _, trail_data in ipairs(PlasmaTrails.TrailAttachments) do
        trail_data.angle = trail_data.angle + trail_data.speed * delta_time
        
        local spiral_angle = trail_data.angle * trail_data.spiralSpeed
        local pulse = math.sin(time * 4 + trail_data.pulseOffset) * 0.4 + 1
        local twist = math.sin(trail_data.angle * 3) * 0.7
        local chaos = math.sin(time * trail_data.chaosSpeed + trail_data.pulseOffset) * 0.5
        
        local radius1 = trail_data.baseRadius * trail_data.radiusMultiplier * pulse
        local radius2 = trail_data.baseRadius * 1.3 * trail_data.radiusMultiplier * pulse
        
        local spiral_offset1 = Vector3.new(
            math.cos(spiral_angle) * 0.6,
            math.sin(spiral_angle * 2) * 0.6,
            math.sin(spiral_angle) * 0.6
        )
        
        local spiral_offset2 = Vector3.new(
            math.sin(spiral_angle * 1.3) * 0.5,
            math.cos(spiral_angle * 1.7) * 0.5,
            math.cos(spiral_angle * 1.1) * 0.5
        )
        
        trail_data.attachment0.Position = Vector3.new(
            math.cos(trail_data.baseAngle + trail_data.angle) * radius1,
            trail_data.baseHeight + math.sin((trail_data.baseAngle + trail_data.angle) * 3) * 0.8 + twist + chaos,
            math.sin(trail_data.baseAngle + trail_data.angle) * radius1
        ) + spiral_offset1
        
        trail_data.attachment1.Position = Vector3.new(
            math.cos(trail_data.baseAngle + trail_data.angle + math.pi * 0.7) * radius2,
            -trail_data.baseHeight + math.cos((trail_data.baseAngle + trail_data.angle) * 2.5) * 0.8 - twist - chaos,
            math.sin(trail_data.baseAngle + trail_data.angle + math.pi * 0.7) * radius2
        ) + spiral_offset2
        
        local brightness = (math.sin(time * 5 + trail_data.pulseOffset) * 0.4 + 0.6)
        trail_data.trail.LightEmission = brightness
    end
end

function Plasma.cleanup_trails(ball)
    if not ball then return end
    
    for _, obj in pairs(ball:GetChildren()) do
        if obj.Name:match("Plasma") then
            obj:Destroy()
        end
    end
    
    PlasmaTrails.Active = false
    PlasmaTrails.TrailAttachments = {}
end

function Plasma.update_trail_colors(ball)
    if not ball then return end
    
    for _, obj in pairs(ball:GetChildren()) do
        if obj:IsA("Trail") and obj.Name:match("PlasmaTrail") then
            local base_color = PlasmaTrails.TrailColor
            obj.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, base_color),
                ColorSequenceKeypoint.new(0.5, Color3.new(
                    math.min(base_color.R * 1.3, 1),
                    math.min(base_color.G * 1.3, 1),
                    math.min(base_color.B * 1.3, 1)
                )),
                ColorSequenceKeypoint.new(1, base_color)
            })
        end
    end
end

local last_ball = nil
local spawn_timer = 0
local spawn_interval = 0.04

RunService.Heartbeat:Connect(function(delta_time)
    if ParticleSystem.Enabled then
        spawn_timer = spawn_timer + delta_time
        
        if spawn_timer >= spawn_interval then
            for i = 1, ParticleSystem.SpawnRate do
                Particles.spawn()
            end
            spawn_timer = 0
        end
    end
    
    Particles.update(delta_time)
    
    if PlasmaTrails.Enabled then
        local ball = BallSystem.get_ball()
        
        if ball and ball ~= last_ball then
            if last_ball then
                Plasma.cleanup_trails(last_ball)
            end
            Plasma.create_trails(ball)
            last_ball = ball
        elseif not ball and last_ball then
            Plasma.cleanup_trails(last_ball)
            last_ball = nil
        end
        
        if ball and PlasmaTrails.Active then
            Plasma.animate_trails(ball, delta_time)
        end
    else
        if last_ball then
            Plasma.cleanup_trails(last_ball)
            last_ball = nil
        end
    end
end)

local particle_module = visuals:create_module({
    title = 'Rain',
    description = '',
    section = 'left',
    flag = 'particle_rain_module',
    callback = function(state)
        ParticleSystem.Enabled = state
        if not state then
            Particles.clear_all()
        end
    end,
})

particle_module:create_slider({
    title = 'Max Particles',
    flag = 'max_particles',
    maximum_value = 20000,
    minimum_value = 100,
    value = 5000,
    round_number = true,
    callback = function(value)
        ParticleSystem.MaxParticles = value
    end,
})

particle_module:create_slider({
    title = 'Spawn Rate',
    flag = 'spawn_rate',
    maximum_value = 25,
    minimum_value = 1,
    value = 3,
    round_number = true,
    callback = function(value)
        ParticleSystem.SpawnRate = value
    end,
})

particle_module:create_slider({
    title = 'Fall Speed',
    flag = 'fall_speed',
    maximum_value = 150,
    minimum_value = 5,
    value = 25,
    round_number = true,
    callback = function(value)
        ParticleSystem.FallSpeed = value
        for _, particle_data in ipairs(ParticleSystem.Particles) do
            particle_data.Velocity = Vector3.new(
                particle_data.Velocity.X,
                -value,
                particle_data.Velocity.Z
            )
        end
    end,
})

particle_module:create_colorpicker({
    title = 'Particle Color',
    flag = 'particle_color',
    callback = function(color)
        ParticleSystem.ParticleColor = color
        Particles.update_colors()
    end,
})

local plasma_module = visuals:create_module({
    title = 'Ball Trail',
    description = '',
    section = 'right',
    flag = 'plasma_trails_module',
    callback = function(state)
        PlasmaTrails.Enabled = state
        if not state and last_ball then
            Plasma.cleanup_trails(last_ball)
            last_ball = nil
        end
    end,
})

plasma_module:create_slider({
    title = 'Number of Trails',
    flag = 'num_trails',
    maximum_value = 16,
    minimum_value = 2,
    value = 8,
    round_number = true,
    callback = function(value)
        PlasmaTrails.NumTrails = value
        if last_ball then
            Plasma.cleanup_trails(last_ball)
            if PlasmaTrails.Enabled then
                Plasma.create_trails(last_ball)
            end
        end
    end,
})

plasma_module:create_colorpicker({
    title = 'Trail Color',
    flag = 'trail_color',
    callback = function(color)
        PlasmaTrails.TrailColor = color
        if last_ball then
            Plasma.update_trail_colors(last_ball)
        end
    end,
})]]

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

local SkinChanger = misc:create_module({
    title = 'Skin Changer',
    flag = 'SkinChanger',
    description = 'Skin Changer',
    section = 'left',
    callback = function(value: boolean)
        getgenv().skinChangerEnabled = value
        if value then
            getgenv().updateSword()
        end
    end
})


SkinChanger:create_divider({})
SkinChanger:change_state(false)

local changeSwordModelCheckbox = SkinChanger:create_checkbox({
    title = "Change Sword Model",
    flag = "ChangeSwordModel",
    callback = function(value: boolean)
        getgenv().changeSwordModel = value
        if getgenv().skinChangerEnabled then
            getgenv().updateSword()
        end
    end
})

changeSwordModelCheckbox:change_state(true)

local swordModelTextbox = SkinChanger:create_textbox({
    title = "￬ Sword Model Name ￬",
    placeholder = "Enter Sword Model Name...",
    flag = "SwordModelTextbox",
    callback = function(text)
        getgenv().swordModel = text
        if getgenv().skinChangerEnabled and getgenv().changeSwordModel then
            getgenv().updateSword()
        end
    end
})

SkinChanger:create_divider({})

local changeSwordAnimationCheckbox = SkinChanger:create_checkbox({
    title = "Change Sword Animation",
    flag = "ChangeSwordAnimation",
    callback = function(value: boolean)
        getgenv().changeSwordAnimation = value
        if getgenv().skinChangerEnabled then
            getgenv().updateSword()
        end
    end
})

changeSwordAnimationCheckbox:change_state(true)

local swordAnimationTextbox = SkinChanger:create_textbox({
    title = "￬ Sword Animation Name ￬",
    placeholder = "Enter Sword Animation Name...",
    flag = "SwordAnimationTextbox",
    callback = function(text)
        getgenv().swordAnimations = text
        if getgenv().skinChangerEnabled and getgenv().changeSwordAnimation then
            getgenv().updateSword()
        end
    end
})

SkinChanger:create_divider({})

local changeSwordFXCheckbox = SkinChanger:create_checkbox({
    title = "Change Sword FX",
    flag = "ChangeSwordFX",
    callback = function(value: boolean)
        getgenv().changeSwordFX = value
        if getgenv().skinChangerEnabled then
            getgenv().updateSword()
        end
    end
})

changeSwordFXCheckbox:change_state(true)

local swordFXTextbox = SkinChanger:create_textbox({
    title = "￬ Sword FX Name ￬",
    placeholder = "Enter Sword FX Name...",
    flag = "SwordFXTextbox",
    callback = function(text)
        getgenv().swordFX = text
        if getgenv().skinChangerEnabled and getgenv().changeSwordFX then
            getgenv().updateSword()
        end
    end
})

SkinChanger:create_divider({})

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

local AutoPlay = misc:create_module({
    title = 'AI Play',
    flag = 'AI_Play',
    description = 'Automatically Plays',
    section = 'right',
    callback = function(value)
        if value then
            AutoPlayModule.runThread()
        else
            AutoPlayModule.finishThread()
        end
    end
})

AutoPlay:create_checkbox({
    title = "AI Enable Jumping",
    flag = "jumping_enabled",
    callback = function(value)
        AutoPlayModule.CONFIG.JUMPING_ENABLED = value
    end
})

AutoPlay:create_checkbox({
    title = "AI Auto Vote",
    flag = "AutoVote",
    callback = function(value)
        getgenv().AutoVote = value
    end
})

AutoPlay:create_checkbox({
    title = "AI Avoid Players",
    flag = "avoid_players",
    callback = function(value)
        AutoPlayModule.CONFIG.PLAYER_DISTANCE_ENABLED = value
    end
})

AutoPlay:create_divider({})

AutoPlay:create_slider({
    title = 'AI Update Frequency',
    flag = 'update_frequency',
    maximum_value = 20,
    minimum_value = 3,
    value = AutoPlayModule.CONFIG.UPDATE_FREQUENCY,
    round_number = true,
    callback = function(value)
        AutoPlayModule.CONFIG.UPDATE_FREQUENCY = value
    end
})

AutoPlay:create_slider({
    title = 'AI Distance From Ball',
    flag = 'default_distance',
    maximum_value = 100,
    minimum_value = 5,
    value = AutoPlayModule.CONFIG.DEFAULT_DISTANCE,
    round_number = true,
    callback = function(value)
        AutoPlayModule.CONFIG.DEFAULT_DISTANCE = value
    end
})

AutoPlay:create_slider({
    title = 'AI Distance From Players',
    flag = 'player_distance',
    maximum_value = 150,
    minimum_value = 10,
    value = AutoPlayModule.CONFIG.MINIMUM_PLAYER_DISTANCE,
    round_number = true,
    callback = function(value)
        AutoPlayModule.CONFIG.MINIMUM_PLAYER_DISTANCE = value
    end
})

AutoPlay:create_slider({
    title = 'AI Speed Multiplier',
    flag = 'multiplier_threshold',
    maximum_value = 200,
    minimum_value = 10,
    value = AutoPlayModule.CONFIG.MULTIPLIER_THRESHOLD,
    round_number = true,
    callback = function(value)
        AutoPlayModule.CONFIG.MULTIPLIER_THRESHOLD = value
    end
})

AutoPlay:create_slider({
    title = 'AI Transversing',
    flag = 'traversing',
    maximum_value = 100,
    minimum_value = 0,
    value = AutoPlayModule.CONFIG.TRAVERSING,
    round_number = true,
    callback = function(value)
        AutoPlayModule.CONFIG.TRAVERSING = value
    end
})

AutoPlay:create_slider({
    title = 'AI Direction',
    flag = 'Direction',
    maximum_value = 1,
    minimum_value = -1,
    value = AutoPlayModule.CONFIG.DIRECTION,
    round_number = true,
    callback = function(value)
        AutoPlayModule.CONFIG.DIRECTION = value
    end
})

AutoPlay:create_slider({
    title = 'AI Offset Factor',
    flag = 'OffsetFactor',
    maximum_value = 1,
    minimum_value = 0.1,
    value = AutoPlayModule.CONFIG.OFFSET_FACTOR,
    round_number = true,
    callback = function(value)
        AutoPlayModule.CONFIG.OFFSET_FACTOR = value
    end
})

AutoPlay:create_slider({
    title = 'AI Movement Duration',
    flag = 'MovementDuration',
    maximum_value = 1,
    minimum_value = 0.1,
    value = AutoPlayModule.CONFIG.MOVEMENT_DURATION,
    round_number = true,
    callback = function(value)
        AutoPlayModule.CONFIG.MOVEMENT_DURATION = value
    end
})

AutoPlay:create_slider({
    title = 'AI Generation Threshold',
    flag = 'GenerationThreshold',
    maximum_value = 0.5,
    minimum_value = 0.1,
    value = AutoPlayModule.CONFIG.GENERATION_THRESHOLD,
    round_number = true,
    callback = function(value)
        AutoPlayModule.CONFIG.GENERATION_THRESHOLD = value
    end
})

AutoPlay:create_slider({
    title = 'AI Jump Chance',
    flag = 'jump_percentage',
    maximum_value = 100,
    minimum_value = 0,
    value = AutoPlayModule.CONFIG.JUMP_PERCENTAGE,
    round_number = true,
    callback = function(value)
        AutoPlayModule.CONFIG.JUMP_PERCENTAGE = value
    end
})

AutoPlay:create_slider({
    title = 'AI Double Jump Chance',
    flag = 'double_jump_percentage',
    maximum_value = 100,
    minimum_value = 0,
    value = AutoPlayModule.CONFIG.DOUBLE_JUMP_PERCENTAGE,
    round_number = true,
    callback = function(value)
        AutoPlayModule.CONFIG.DOUBLE_JUMP_PERCENTAGE = value
    end
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

local module = devJV:create_module({
    title = "Walkable Semi-Immortal [BLATANT!]",
    description = "",
    flag = "Walkable_Semi_Immortal",
    section = "left",
    callback = WalkableSemiImmortal.toggle
})

module:create_checkbox({
    title = "Notify",
    flag = "WalkableSemi_Imortal_Notify",
    callback = WalkableSemiImmortal.setNotify
})

module:create_slider({
    title = 'Immortal Radius',
    flag = 'Immortal_Radius',
    maximum_value = 100,
    minimum_value = 0,
    value = 25,
    round_number = true,
    callback = WalkableSemiImmortal.setRadius
})

module:create_slider({
    title = 'Immortal Height',
    flag = 'Walkable_Immortal_Radius',
    maximum_value = 60,
    minimum_value = 0,
    value = 30,
    round_number = true,
    callback = WalkableSemiImmortal.setHeight
})

--[[local Invisibilidade = {}

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')
local LocalPlayer = Players.LocalPlayer

local state = {
    enabled = false,
    notify = false,
    heartbeatConnection = nil,
    ballTrackingConnection = nil
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
    invisibleY = -200000,
    velocityThreshold = 800
}

local ballData = {
    peakVelocity = 0,
    currentBall = nil
}

local function updateCache()
    local character = LocalPlayer.Character
    if character ~= cache.character then
        cache.character = character
        if character then
            cache.hrp = character:FindFirstChild("HumanoidRootPart")
            cache.head = character:FindFirstChild("Head")
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

local function trackBallVelocity()
    local ball = System.ball.get()

    if not ball then
        ballData.currentBall = nil
        ballData.peakVelocity = 0
        getgenv().BallPeakVelocity = 0
        getgenv().BallVelocityAbove800 = false
        return
    end

    if ball ~= ballData.currentBall then
        ballData.currentBall = ball
        ballData.peakVelocity = 0
    end

    local zoomies = ball:FindFirstChild("zoomies")
    if not zoomies then
        getgenv().BallPeakVelocity = 0
        getgenv().BallVelocityAbove800 = false
        return
    end

    local velocity = zoomies.VectorVelocity.Magnitude

    if velocity > ballData.peakVelocity then
        ballData.peakVelocity = velocity
    end

    getgenv().BallPeakVelocity = ballData.peakVelocity
    getgenv().BallVelocityAbove800 = ballData.peakVelocity >= constants.velocityThreshold
end

local function shouldApplyDesync()
    return state.enabled and getgenv().BallVelocityAbove800 == true
end

local function performDesync()
    updateCache()
    
    if not shouldApplyDesync() or not cache.hrp or not isInAliveFolder() then
        return
    end
    
    local hrp = cache.hrp
    desyncData.originalCFrame = hrp.CFrame
    desyncData.originalVelocity = hrp.AssemblyLinearVelocity
    
    hrp.CFrame = CFrame.new(
        Vector3.new(hrp.Position.X, constants.invisibleY, hrp.Position.Z),
        hrp.CFrame.LookVector
    )
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    
    hrp.CFrame = hrp.CFrame + Vector3.new(0, 0, 0.1)
    
    RunService.RenderStepped:Wait()
    
    hrp.CFrame = desyncData.originalCFrame
    hrp.AssemblyLinearVelocity = desyncData.originalVelocity
end

local function sendNotification(text)
    if state.notify and Library then
        Library.SendNotification({
            title = "IDK???",
            text = text
        })
    end
end

function Invisibilidade.toggle(enabled)
    if state.enabled == enabled then return end
    
    state.enabled = enabled
    getgenv().IDKEnabled = enabled
    
    if enabled then
        if not state.ballTrackingConnection then
            state.ballTrackingConnection = RunService.Heartbeat:Connect(trackBallVelocity)
        end

        if not state.heartbeatConnection then
            state.heartbeatConnection = RunService.Heartbeat:Connect(performDesync)
        end
    else
        if state.ballTrackingConnection then
            state.ballTrackingConnection:Disconnect()
            state.ballTrackingConnection = nil
        end

        if state.heartbeatConnection then
            state.heartbeatConnection:Disconnect()
            state.heartbeatConnection = nil
        end

        updateCache()
        if cache.hrp and desyncData.originalCFrame then
            cache.hrp.CFrame = desyncData.originalCFrame
            if desyncData.originalVelocity then
                cache.hrp.AssemblyLinearVelocity = desyncData.originalVelocity
            end
        end
        
        desyncData.originalCFrame = nil
        desyncData.originalVelocity = nil

        ballData.peakVelocity = 0
        ballData.currentBall = nil
        getgenv().BallPeakVelocity = 0
        getgenv().BallVelocityAbove800 = false
    end
    
    sendNotification(enabled and "ON" or "OFF")
end

function Invisibilidade.setNotify(enabled)
    state.notify = enabled
    getgenv().IDKNotify = enabled
end

LocalPlayer.CharacterRemoving:Connect(function()
    cache.character = nil
    cache.hrp = nil
    cache.head = nil
    cache.aliveFolder = nil
end)

hooks.oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    if not shouldApplyDesync() or checkcaller() or key ~= "CFrame" or not cache.hrp or not isInAliveFolder() then
        return hooks.oldIndex(self, key)
    end
    
    if self == cache.hrp then
        return desyncData.originalCFrame or constants.emptyCFrame
    elseif self == cache.head and desyncData.originalCFrame then
        return desyncData.originalCFrame + cache.headOffset
    end
    
    return hooks.oldIndex(self, key)
end))

local module = devuwu:create_module({
    title = "Dupe Ball[BLATANT!]",
    description = "",
    flag = "IDK_Toggle",
    section = "right",
    callback = Invisibilidade.toggle
})

module:create_checkbox({
    title = "Notify",
    flag = "IDK_Notify",
    callback = Invisibilidade.setNotify
})

module:create_slider({
    title = 'Velocity Threshold',
    flag = 'dasdada',
    maximum_value = 1500,
    minimum_value = 800,
    value = 800,
    round_number = true,
    callback = function(value)
        constants.velocityThreshold = value
    end
})]]

if not mobile then
    local guiset = main:create_tab('Gui', 'rbxassetid://10734887784')

guiset:create_module({
    title = "GUI Library Visible",
    description = "visibility of GUI library",
    flag = "guilibraryvisible",
    section = "left",
    callback = function(state)
        getgenv().guilibraryVisible = state
    end
})
end

workspace.ChildRemoved:Connect(function(child)
    if child.Name == 'Balls' then
        System.__properties.__cached_balls = nil
    end
end)

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

main:load()

local StarterGui = game:GetService('StarterGui')

StarterGui:SetCore('SendNotification', {
    Title = 'BETA',
    Text = 'This Version is on BETA',
    Icon = 'rbxassetid://123456789',
    Duration = 10,
})
