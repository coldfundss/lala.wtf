-- // lala.wtf Loader Library
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local Loader = {}

local function dragify(Frame)
    local dragToggle, dragInput, dragStart, startPos
    Frame.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragToggle = true
            dragStart = input.Position
            startPos = Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)
    Frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragToggle then
            local Delta = input.Position - dragStart
            local Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
            TweenService:Create(Frame, TweenInfo.new(0.15), {Position = Position}):Play()
        end
    end)
end

function Loader:Create(info)
    local name = "lala.wtf"
    local image = info.ImageID
    local savekey = info.SaveKey
    local callback = info.Callback 
    
    -- // Cleanup & Setup
    if game.CoreGui:FindFirstChild("LalaLoader") then game.CoreGui.LalaLoader:Destroy() end
    if not isfile then -- Mocking for Studio testing if needed
        getgenv().isfile = function() return false end
        getgenv().writefile = function() end
        getgenv().readfile = function() return "" end
    end

    -- // Blur Effect
    local Blur = Instance.new("BlurEffect")
    Blur.Size = 20
    Blur.Parent = Lighting

    local Login = Instance.new("ScreenGui")
    Login.Name = "LalaLoader"
    Login.Parent = game.CoreGui

    -- // Snow System
    local SnowContainer = Instance.new("Frame")
    SnowContainer.Size = UDim2.new(1, 0, 1, 0)
    SnowContainer.BackgroundTransparency = 1
    SnowContainer.Parent = Login

    local function CreateFlake()
        local flake = Instance.new("Frame")
        flake.Size = UDim2.new(0, 2, 0, 2)
        flake.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        flake.BackgroundTransparency = 0.5
        flake.BorderSizePixel = 0
        flake.Position = UDim2.new(math.random(), 0, -0.1, 0)
        flake.Parent = SnowContainer

        local fallSpeed = math.random(2, 5)
        local drift = math.random(-100, 100) / 1000

        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not flake.Parent then conn:Disconnect() return end
            flake.Position = flake.Position + UDim2.new(drift, 0, 0, fallSpeed)
            if flake.Position.Y.Offset > SnowContainer.AbsoluteSize.Y + 10 then
                flake:Destroy()
                conn:Disconnect()
            end
        end)
    end

    task.spawn(function()
        while task.wait(0.1) do
            if not Login.Parent then break end
            CreateFlake()
        end
    end)

    -- // Main UI (No UICorners)
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = Login
    Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Main.BorderColor3 = Color3.fromRGB(45, 45, 45)
    Main.BorderSizePixel = 1
    Main.Position = UDim2.new(0.5, -223, 0.5, -56)
    Main.Size = UDim2.new(0, 447, 0, 130)
    Main.ZIndex = 5

    local AccentBar = Instance.new("Frame")
    AccentBar.Size = UDim2.new(1, 0, 0, 2)
    AccentBar.BackgroundColor3 = Color3.fromRGB(80, 120, 255) -- Subtle Blue Accent
    AccentBar.BorderSizePixel = 0
    AccentBar.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Parent = Main
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 10, 0, 10)
    Title.Size = UDim2.new(0, 200, 0, 20)
    Title.Font = Enum.Font.Code
    Title.Text = "LALA.WTF // PREMIER"
    Title.TextColor3 = Color3.fromRGB(200, 200, 200)
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local AuthKeyFrame = Instance.new("Frame")
    AuthKeyFrame.Name = "AuthKey"
    AuthKeyFrame.Parent = Main
    AuthKeyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    AuthKeyFrame.BorderColor3 = Color3.fromRGB(35, 35, 35)
    AuthKeyFrame.Position = UDim2.new(0.05, 0, 0.4, 0)
    AuthKeyFrame.Size = UDim2.new(0.9, 0, 0, 30)

    local TextBox = Instance.new("TextBox")
    TextBox.Parent = AuthKeyFrame
    TextBox.BackgroundTransparency = 1
    TextBox.Size = UDim2.new(1, -10, 1, 0)
    TextBox.Position = UDim2.new(0, 10, 0, 0)
    TextBox.Font = Enum.Font.Code
    TextBox.PlaceholderText = "Enter Access Key..."
    TextBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
    TextBox.Text = ""
    TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextBox.TextSize = 14
    TextBox.TextXAlignment = Enum.TextXAlignment.Left

    local Load = Instance.new("TextButton")
    Load.Name = "Load"
    Load.Parent = Main
    Load.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Load.BorderColor3 = Color3.fromRGB(45, 45, 45)
    Load.Position = UDim2.new(0.05, 0, 0.7, 0)
    Load.Size = UDim2.new(0.9, 0, 0, 30)
    Load.Font = Enum.Font.Code
    Load.Text = "AUTHENTICATE"
    Load.TextColor3 = Color3.fromRGB(255, 255, 255)
    Load.TextSize = 13
    Load.AutoButtonColor = false

    -- // Button Hover Effects
    Load.MouseEnter:Connect(function() Load.BackgroundColor3 = Color3.fromRGB(35, 35, 35) end)
    Load.MouseLeave:Connect(function() Load.BackgroundColor3 = Color3.fromRGB(25, 25, 25) end)

    -- // Functions
    local function Success()
        Blur:Destroy()
        Login:Destroy()
    end

    Load.MouseButton1Click:Connect(function()
        if savekey then
            pcall(function() writefile(name..".key", TextBox.Text) end)
        end
        -- Run callback; we assume the developer calls Loader:Destroy in their callback
        task.spawn(callback, TextBox.Text, Success)
    end)
    
    if savekey and isfile(name..".key") then
        TextBox.Text = readfile(name..".key")
    end

    dragify(Main)
end

function Loader:Destroy()
    if game.CoreGui:FindFirstChild("LalaLoader") then
        game.CoreGui.LalaLoader:Destroy()
    end
    if Lighting:FindFirstChild("Blur") then
        Lighting.Blur:Destroy()
    end
end

return Loader
