-- // lala.wtf Enhanced Loader
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local Loader = {}

-- // Better Dragging Logic
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
            TweenService:Create(Frame, TweenInfo.new(0.15, Enum.EasingStyle.Quart), {Position = Position}):Play()
        end
    end)
end

function Loader:Create(info)
    local name = "lala.wtf"
    local callback = info.Callback 
    local savekey = info.SaveKey
    
    -- // Cleanup
    if game.CoreGui:FindFirstChild("LalaLoader") then game.CoreGui.LalaLoader:Destroy() end

    -- // Blur Background
    local Blur = Instance.new("BlurEffect")
    Blur.Name = "LalaBlur"
    Blur.Size = 24
    Blur.Parent = Lighting

    local Login = Instance.new("ScreenGui")
    Login.Name = "LalaLoader"
    Login.Parent = game.CoreGui
    Login.IgnoreGuiInset = true

    -- // Enhanced Snow System
    local SnowContainer = Instance.new("Frame")
    SnowContainer.Size = UDim2.new(1, 0, 1, 0)
    SnowContainer.BackgroundTransparency = 1
    SnowContainer.Parent = Login
    SnowContainer.ZIndex = 1

    local function CreateFlake()
        local size = math.random(2, 4)
        local flake = Instance.new("Frame")
        flake.Size = UDim2.new(0, size, 0, size)
        flake.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        flake.BackgroundTransparency = math.random(3, 6) / 10
        flake.BorderSizePixel = 0
        flake.Position = UDim2.new(math.random(), 0, -0.05, 0)
        flake.Parent = SnowContainer

        local fallSpeed = math.random(15, 40) / 10000
        local swayAmplitude = math.random(1, 3) / 1000
        local swaySpeed = math.random(1, 4)
        local startTime = tick()

        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not flake.Parent then conn:Disconnect() return end
            local elapsed = tick() - startTime
            local sway = math.sin(elapsed * swaySpeed) * swayAmplitude
            flake.Position = flake.Position + UDim2.new(sway, 0, fallSpeed, 0)
            
            if flake.Position.Y.Scale > 1.05 then
                flake:Destroy()
                conn:Disconnect()
            end
        end)
    end

    task.spawn(function()
        while task.wait(0.15) do
            if not Login.Parent then break end
            CreateFlake()
        end
    end)

    -- // Main Menu (Sharper & Higher Contrast)
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Parent = Login
    Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20) -- Slightly lighter for visibility
    Main.BorderColor3 = Color3.fromRGB(60, 60, 60) -- Defined border
    Main.BorderSizePixel = 1
    Main.Position = UDim2.new(0.5, -200, 0.5, -65)
    Main.Size = UDim2.new(0, 400, 0, 130)
    Main.ZIndex = 10

    local Accent = Instance.new("Frame")
    Accent.Size = UDim2.new(1, 0, 0, 1)
    Accent.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    Accent.BorderSizePixel = 0
    Accent.Parent = Main

    local Title = Instance.new("TextLabel")
    Title.Parent = Main
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 12, 0, 10)
    Title.Size = UDim2.new(1, -24, 0, 20)
    Title.Font = Enum.Font.Code
    Title.Text = "LALA.WTF // LOADER"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local InputFrame = Instance.new("Frame")
    InputFrame.Parent = Main
    InputFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    InputFrame.BorderColor3 = Color3.fromRGB(45, 45, 45)
    InputFrame.Position = UDim2.new(0.05, 0, 0.35, 0)
    InputFrame.Size = UDim2.new(0.9, 0, 0, 32)

    local TextBox = Instance.new("TextBox")
    TextBox.Parent = InputFrame
    TextBox.BackgroundTransparency = 1
    TextBox.Size = UDim2.new(1, -10, 1, 0)
    TextBox.Position = UDim2.new(0, 10, 0, 0)
    TextBox.Font = Enum.Font.Code
    TextBox.PlaceholderText = "Paste key here..."
    TextBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    TextBox.Text = ""
    TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextBox.TextSize = 13
    TextBox.TextXAlignment = Enum.TextXAlignment.Left

    local LoadBtn = Instance.new("TextButton")
    LoadBtn.Parent = Main
    LoadBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    LoadBtn.BorderColor3 = Color3.fromRGB(50, 50, 50)
    LoadBtn.Position = UDim2.new(0.05, 0, 0.68, 0)
    LoadBtn.Size = UDim2.new(0.9, 0, 0, 32)
    LoadBtn.Font = Enum.Font.Code
    LoadBtn.Text = "ENTER"
    LoadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    LoadBtn.TextSize = 13
    LoadBtn.AutoButtonColor = false

    -- // Interaction
    LoadBtn.MouseEnter:Connect(function() LoadBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40) end)
    LoadBtn.MouseLeave:Connect(function() LoadBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30) end)

    local function Success()
        if Lighting:FindFirstChild("LalaBlur") then Lighting.LalaBlur:Destroy() end
        Login:Destroy()
    end

    LoadBtn.MouseButton1Click:Connect(function()
        if savekey then
            pcall(function() writefile("lala_key.txt", TextBox.Text) end)
        end
        callback(TextBox.Text, Success)
    end)
    
    -- // Auto-load Key
    if savekey and isfile and isfile("lala_key.txt") then
        TextBox.Text = readfile("lala_key.txt")
    end

    dragify(Main)
end

return Loader
