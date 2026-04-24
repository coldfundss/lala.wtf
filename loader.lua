--[[
    lala.wtf UI Library
    Full rewrite with:
      - Device detection (Mobile / PC / Console)
      - Full touch support on Sliders (drag + tap value label to type)
      - Full touch support on ColorPicker (sat + hue touch drag)
      - Toggle UI + Lock UI side buttons (opt-in via MobileSupport flag in Window options)
      - Typewriter effect on menu title (opt-in via Typewriter = true in Window options)
      - All controller keycodes registered
      - Slider Set() properly moves the accent bar
      - Dragging works on mobile and PC
]]

local Library = {}
do
    Library = {
        Open       = true,
        Accent     = Color3.fromRGB(76, 162, 252),
        Pages      = {},
        Sections   = {},
        Flags      = {},
        UnNamedFlags  = 0,
        ThemeObjects  = {},
        Instances     = {},
        Holder        = nil,
        PageHolder    = nil,
        Gradient      = nil,
        UIGradient    = nil,
        Connections   = {},
        UIFont        = Font.fromEnum(Enum.Font.GothamBold),
        FontSize      = 12,
        -- Device info (set during Window creation)
        IsMobile  = false,
        IsConsole = false,
        IsPC      = false,
        -- Internal side-button refs (set when MobileSupport = true)
        _ToggleBtn = nil,
        _LockBtn   = nil,
        _UILocked  = false,
        Keys = {
            -- Keyboard modifiers
            [Enum.KeyCode.LeftShift]       = "LS",
            [Enum.KeyCode.RightShift]      = "RS",
            [Enum.KeyCode.LeftControl]     = "LC",
            [Enum.KeyCode.RightControl]    = "RC",
            [Enum.KeyCode.LeftAlt]         = "LA",
            [Enum.KeyCode.RightAlt]        = "RA",
            [Enum.KeyCode.CapsLock]        = "CAPS",
            -- Numbers
            [Enum.KeyCode.One]   = "1", [Enum.KeyCode.Two]   = "2",
            [Enum.KeyCode.Three] = "3", [Enum.KeyCode.Four]  = "4",
            [Enum.KeyCode.Five]  = "5", [Enum.KeyCode.Six]   = "6",
            [Enum.KeyCode.Seven] = "7", [Enum.KeyCode.Eight] = "8",
            [Enum.KeyCode.Nine]  = "9", [Enum.KeyCode.Zero]  = "0",
            -- Numpad
            [Enum.KeyCode.KeypadOne]   = "Num1", [Enum.KeyCode.KeypadTwo]   = "Num2",
            [Enum.KeyCode.KeypadThree] = "Num3", [Enum.KeyCode.KeypadFour]  = "Num4",
            [Enum.KeyCode.KeypadFive]  = "Num5", [Enum.KeyCode.KeypadSix]   = "Num6",
            [Enum.KeyCode.KeypadSeven] = "Num7", [Enum.KeyCode.KeypadEight] = "Num8",
            [Enum.KeyCode.KeypadNine]  = "Num9", [Enum.KeyCode.KeypadZero]  = "Num0",
            -- Symbols
            [Enum.KeyCode.Minus]           = "-",
            [Enum.KeyCode.Equals]          = "=",
            [Enum.KeyCode.Tilde]           = "~",
            [Enum.KeyCode.LeftBracket]     = "[",
            [Enum.KeyCode.RightBracket]    = "]",
            [Enum.KeyCode.RightParenthesis]= ")",
            [Enum.KeyCode.LeftParenthesis] = "(",
            [Enum.KeyCode.Semicolon]       = ";",
            [Enum.KeyCode.Quote]           = "'",
            [Enum.KeyCode.BackSlash]       = "\\",
            [Enum.KeyCode.Comma]           = ",",
            [Enum.KeyCode.Period]          = ".",
            [Enum.KeyCode.Slash]           = "/",
            [Enum.KeyCode.Asterisk]        = "*",
            [Enum.KeyCode.Plus]            = "+",
            [Enum.KeyCode.Backquote]       = "`",
            -- Mouse
            [Enum.UserInputType.MouseButton1] = "MB1",
            [Enum.UserInputType.MouseButton2] = "MB2",
            [Enum.UserInputType.MouseButton3] = "MB3",
            -- Controller
            [Enum.KeyCode.ButtonA]      = "A",
            [Enum.KeyCode.ButtonB]      = "B",
            [Enum.KeyCode.ButtonX]      = "X",
            [Enum.KeyCode.ButtonY]      = "Y",
            [Enum.KeyCode.ButtonL1]     = "LB",
            [Enum.KeyCode.ButtonR1]     = "RB",
            [Enum.KeyCode.ButtonL2]     = "LT",
            [Enum.KeyCode.ButtonR2]     = "RT",
            [Enum.KeyCode.ButtonL3]     = "LS",
            [Enum.KeyCode.ButtonR3]     = "RS",
            [Enum.KeyCode.ButtonSelect] = "Back",
            [Enum.KeyCode.ButtonStart]  = "Start",
            [Enum.KeyCode.DPadUp]       = "D↑",
            [Enum.KeyCode.DPadDown]     = "D↓",
            [Enum.KeyCode.DPadLeft]     = "D←",
            [Enum.KeyCode.DPadRight]    = "D→",
        },
    }

    -- Internal flag tables
    local Flags     = {}
    local Dropdowns = {}
    local Pickers   = {}

    Library.__index          = Library
    Library.Pages.__index    = Library.Pages
    Library.Sections.__index = Library.Sections

    local UIS = game:GetService("UserInputService")
    local RS  = game:GetService("RunService")
    local TS  = game:GetService("TweenService")
    local LP  = game:GetService("Players").LocalPlayer
    local Mouse = LP:GetMouse()

    -- ────────────────────────────────────────────────────────────
    -- Device detection helper
    -- ────────────────────────────────────────────────────────────
    local function DetectDevice()
        if UIS.TouchEnabled and not UIS.KeyboardEnabled then
            return "Mobile"
        elseif UIS.GamepadEnabled and not UIS.KeyboardEnabled then
            return "Console"
        else
            return "PC"
        end
    end

    -- ────────────────────────────────────────────────────────────
    -- Misc helpers
    -- ────────────────────────────────────────────────────────────
    function Library:Connection(Signal, Callback)
        return Signal:Connect(Callback)
    end
    function Library:Disconnect(Con) Con:Disconnect() end
    function Library:Round(Number, Float)
        return Float * math.floor(Number / Float + 0.5)
    end
    function Library.NextFlag()
        Library.UnNamedFlags += 1
        return string.format("%.14g", Library.UnNamedFlags)
    end
    function Library:RGBA(r, g, b, alpha)
        return Color3.fromRGB(r, g, b)
    end
    function Library:IsMouseOverFrame(Frame)
        local AbsPos  = Frame.AbsolutePosition
        local AbsSize = Frame.AbsoluteSize
        return Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
           and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y
    end

    -- ────────────────────────────────────────────────────────────
    -- Config helpers (unchanged)
    -- ────────────────────────────────────────────────────────────
    function Library:GetConfig()
        local Config = ""
        for Index, Value in pairs(self.Flags) do
            if Index ~= "ConfigConfig_List" and Index ~= "ConfigConfig_Load" and Index ~= "ConfigConfig_Save" then
                local Value2 = Value
                local Final  = ""
                if typeof(Value2) == "Color3" then
                    local h, s, v = Value2:ToHSV()
                    Final = ("rgb(%s,%s,%s,%s)"):format(h, s, v, 1)
                elseif typeof(Value2) == "table" and Value2.Color and Value2.Transparency then
                    local h, s, v = Value2.Color:ToHSV()
                    Final = ("rgb(%s,%s,%s,%s)"):format(h, s, v, Value2.Transparency)
                elseif typeof(Value2) == "table" and Value.Mode then
                    local Vals = Value.current
                    Final = ("key(%s,%s,%s)"):format(Vals[1] or "nil", Vals[2] or "nil", Value.Mode)
                elseif Value2 ~= nil then
                    if typeof(Value2) == "boolean" then
                        Value2 = ("bool(%s)"):format(tostring(Value2))
                    elseif typeof(Value2) == "table" then
                        local New = "table("
                        for _, V3 in pairs(Value2) do New = New .. V3 .. "," end
                        if New:sub(#New) == "," then New = New:sub(0, #New - 1) end
                        Value2 = New .. ")"
                    elseif typeof(Value2) == "string" then
                        Value2 = ("string(%s)"):format(Value2)
                    elseif typeof(Value2) == "number" then
                        Value2 = ("number(%s)"):format(Value2)
                    end
                    Final = Value2
                end
                Config = Config .. Index .. ": " .. tostring(Final) .. "\n"
            end
        end
        return Config
    end

    function Library:LoadConfig(Config)
        local Table  = string.split(Config, "\n")
        local Table2 = {}
        for _, Value in pairs(Table) do
            local T3 = string.split(Value, ":")
            if T3[1] ~= "ConfigConfig_List" and #T3 >= 2 then
                local v = T3[2]:sub(2)
                if     v:sub(1,3) == "rgb"   then v = string.split(v:sub(5,#v-1), ",")
                elseif v:sub(1,3) == "key"   then
                    local T4 = string.split(v:sub(5,#v-1), ",")
                    if T4[1] == "nil" then T4[1] = nil end
                    if T4[2] == "nil" then T4[2] = nil end
                    v = T4
                elseif v:sub(1,4) == "bool"  then v = v:sub(6,#v-1) == "true"
                elseif v:sub(1,5) == "table" then v = string.split(v:sub(7,#v-1), ",")
                elseif v:sub(1,6) == "string" then v = v:sub(8,#v-1)
                elseif v:sub(1,6) == "number" then v = tonumber(v:sub(8,#v-1))
                end
                Table2[T3[1]] = v
            end
        end
        for i, v in pairs(Table2) do
            if Flags[i] then
                if typeof(Flags[i]) == "table" then Flags[i]:Set(v)
                else Flags[i](v) end
            end
        end
    end

    -- ────────────────────────────────────────────────────────────
    -- SetOpen  (unchanged logic)
    -- ────────────────────────────────────────────────────────────
    function Library:SetOpen(bool)
        if typeof(bool) ~= "boolean" then return end
        Library.Open = bool
        if bool then Library.Holder.Visible = true end
        for _, v in next, Library.Instances do
            if v:IsA("Frame") or v:IsA("TextButton") then
                if v.BackgroundTransparency ~= 1 then
                    task.spawn(function()
                        local t = TS:Create(v, TweenInfo.new(0.25, Enum.EasingStyle.Linear,
                            bool and Enum.EasingDirection.Out or Enum.EasingDirection.In),
                            {BackgroundTransparency = bool and 0 or 0.95})
                        t.Completed:Connect(function()
                            if not bool then Library.Holder.Visible = false end
                        end)
                        t:Play()
                    end)
                end
            elseif v:IsA("TextLabel") or v:IsA("TextBox") then
                if v.TextTransparency ~= 1 and v.BackgroundTransparency == 1 then
                    task.spawn(function()
                        TS:Create(v, TweenInfo.new(0.25, Enum.EasingStyle.Linear,
                            bool and Enum.EasingDirection.Out or Enum.EasingDirection.In),
                            {TextTransparency = bool and 0 or 0.95}):Play()
                    end)
                end
            elseif v:IsA("UIStroke") then
                task.spawn(function()
                    TS:Create(v, TweenInfo.new(0.25, Enum.EasingStyle.Linear,
                        bool and Enum.EasingDirection.Out or Enum.EasingDirection.In),
                        {Transparency = bool and 0 or 0.95}):Play()
                end)
            elseif v:IsA("ImageButton") then
                task.spawn(function()
                    TS:Create(v, TweenInfo.new(0.25, Enum.EasingStyle.Linear,
                        bool and Enum.EasingDirection.Out or Enum.EasingDirection.In),
                        {ImageTransparency = bool and 0 or 0.95, BackgroundTransparency = bool and 0 or 0.95}):Play()
                end)
            end
        end
        task.spawn(function()
            TS:Create(Library.PageHolder, TweenInfo.new(0.25, Enum.EasingStyle.Quad,
                bool and Enum.EasingDirection.Out or Enum.EasingDirection.In),
                {Position = bool and UDim2.new(0,60,0,0) or UDim2.new(0,0,0,0)}):Play()
            if bool then task.wait(0.05) end
            TS:Create(Library.Gradient, TweenInfo.new(0.25, Enum.EasingStyle.Quad,
                bool and Enum.EasingDirection.Out or Enum.EasingDirection.In),
                {Position = bool and UDim2.new(0.5,0,0,2) or UDim2.new(1,0,0,2)}):Play()
            TS:Create(Library.Gradient, TweenInfo.new(0.25, Enum.EasingStyle.Quad,
                bool and Enum.EasingDirection.Out or Enum.EasingDirection.In),
                {Size = bool and UDim2.new(0.5,0,0,1) or UDim2.new(0,0,0,1)}):Play()
        end)
    end

    function Library:ChangeAccent(Color)
        Library.Accent = Color
        for _, theme in next, Library.ThemeObjects do
            if theme:IsA("Frame") or theme:IsA("TextButton") then
                theme.BackgroundColor3 = Color
            elseif theme:IsA("TextLabel") then
                theme.TextColor3 = Color
            end
        end
        Library.UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color),
            ColorSequenceKeypoint.new(1, Color3.new(0.0431,0.0431,0.0431))
        }
    end

    -- ────────────────────────────────────────────────────────────
    -- Side button factory  (used by Window when MobileSupport=true)
    -- ────────────────────────────────────────────────────────────
    local function MakeSideBtn(parent, label, ypos)
        local Wrap = Instance.new("Frame", parent)
        Wrap.Size             = UDim2.new(0,56,0,19)
        Wrap.Position         = UDim2.new(0,4,0,ypos)
        Wrap.BackgroundColor3 = Color3.fromRGB(8,8,8)
        Wrap.BorderSizePixel  = 0
        Wrap.ZIndex           = 999
        Instance.new("UICorner", Wrap).CornerRadius = UDim.new(0,2)
        local ws = Instance.new("UIStroke", Wrap)
        ws.Color = Color3.fromRGB(28,28,28); ws.Thickness = 1

        local Inn = Instance.new("Frame", Wrap)
        Inn.Size             = UDim2.new(1,-2,1,-2)
        Inn.Position         = UDim2.new(0,1,0,1)
        Inn.BackgroundColor3 = Color3.fromRGB(11,11,11)
        Inn.BorderSizePixel  = 0
        Inn.ZIndex           = 999
        Instance.new("UICorner", Inn).CornerRadius = UDim.new(0,2)

        local Bar = Instance.new("Frame", Inn)
        Bar.Size             = UDim2.new(1,0,0,1)
        Bar.BackgroundColor3 = Library.Accent
        Bar.BorderSizePixel  = 0
        Bar.ZIndex           = 1000

        local Btn = Instance.new("TextButton", Inn)
        Btn.Size               = UDim2.new(1,0,1,0)
        Btn.BackgroundTransparency = 1
        Btn.Text               = label
        Btn.TextColor3         = Color3.fromRGB(78,78,78)
        Btn.TextSize           = 10
        Btn.FontFace           = Library.UIFont
        Btn.ZIndex             = 1001
        Btn.AutoButtonColor    = false

        Btn.MouseEnter:Connect(function()
            TS:Create(Btn, TweenInfo.new(0.12), {TextColor3 = Color3.fromRGB(220,220,220)}):Play()
            TS:Create(Inn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(17,17,17)}):Play()
        end)
        Btn.MouseLeave:Connect(function()
            TS:Create(Btn, TweenInfo.new(0.12), {TextColor3 = Color3.fromRGB(78,78,78)}):Play()
            TS:Create(Inn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(11,11,11)}):Play()
        end)

        return Btn, Bar, Wrap, Inn
    end

    -- ────────────────────────────────────────────────────────────
    -- Typewriter effect
    -- ────────────────────────────────────────────────────────────
    local function StartTypewriter(label, text)
        task.spawn(function()
            while true do
                for i = 1, #text do
                    label.Text = text:sub(1, i)
                    task.wait(0.09)
                end
                task.wait(0.7)
                for i = #text, 0, -1 do
                    label.Text = text:sub(1, i)
                    task.wait(0.05)
                end
                task.wait(0.2)
            end
        end)
    end

    -- ────────────────────────────────────────────────────────────
    -- ColorPicker  (with touch support)
    -- ────────────────────────────────────────────────────────────
    function Library:NewPicker(default, defaultalpha, parent, count, flag, callback)
        local Icon   = Instance.new("TextButton", parent)
        local Grad   = Instance.new("UIGradient", Icon)
        local Window = Instance.new("Frame", Icon)
        local Sat    = Instance.new("ImageButton", Window)
        local Hue    = Instance.new("ImageButton", Window)

        table.insert(Library.Instances, Icon)
        table.insert(Library.Instances, Window)
        table.insert(Library.Instances, Sat)
        table.insert(Library.Instances, Hue)
        table.insert(Pickers, Window)

        Icon.Name             = "Icon"
        Icon.Position         = UDim2.new(1, -30 - (count*15) - (count*6), 0, 4)
        Icon.Size             = UDim2.new(0,15,0,6)
        Icon.BackgroundColor3 = default
        Icon.BorderColor3     = Color3.new(0,0,0)
        Icon.AutoButtonColor  = false
        Icon.Text             = ""

        Grad.Color    = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.new(0.78,0.749,0.8)),
            ColorSequenceKeypoint.new(1, Color3.new(1,1,1))
        }
        Grad.Rotation = -90

        Window.Name             = "Window"
        Window.Position         = UDim2.new(0,-120,0,10)
        Window.Size             = UDim2.new(0,150,0,133)
        Window.BackgroundColor3 = Color3.new(0.0431,0.0431,0.0431)
        Window.BorderColor3     = Color3.new(0.1098,0.1098,0.1098)
        Window.ZIndex           = 1220
        Window.Visible          = false

        Sat.Name             = "Sat"
        Sat.Position         = UDim2.new(0,5,0,5)
        Sat.Size             = UDim2.new(0,123,0,123)
        Sat.BackgroundColor3 = default
        Sat.BorderColor3     = Color3.new(0.1098,0.1098,0.1098)
        Sat.Image            = "http://www.roblox.com/asset/?id=13882904626"
        Sat.AutoButtonColor  = false
        Sat.ZIndex           = 1220

        Hue.Name             = "Hue"
        Hue.Position         = UDim2.new(1,-15,0,5)
        Hue.Size             = UDim2.new(0,10,0,123)
        Hue.BackgroundColor3 = Color3.new(1,1,1)
        Hue.BorderColor3     = Color3.new(0.1098,0.1098,0.1098)
        Hue.Image            = "http://www.roblox.com/asset/?id=13882976736"
        Hue.ZIndex           = 1220
        Hue.AutoButtonColor  = false

        -- State
        local hue, sat, val   = default:ToHSV()
        local alpha           = defaultalpha
        local curhuesizey     = hue

        local function set(color, a, nopos, setcolor)
            if type(color) == "table" then
                a     = color[4]
                color = Color3.fromHSV(color[1], color[2], color[3])
            end
            if type(color) == "string" then color = Color3.fromHex(color) end

            local oldH, oldA = hue, alpha
            hue, sat, val = color:ToHSV()
            alpha = a or 1
            local hsv = Color3.fromHSV(hue, sat, val)

            Icon.BackgroundColor3 = hsv
            if not nopos and setcolor then
                Sat.BackgroundColor3 = Color3.fromHSV(hue,1,1)
            end
            if flag then
                Library.Flags[flag] = Library:RGBA(hsv.R*255, hsv.G*255, hsv.B*255, alpha)
            end
            callback(Library:RGBA(hsv.R*255, hsv.G*255, hsv.B*255, alpha))
        end

        Flags[flag] = set
        set(default, defaultalpha)
        curhuesizey = hue

        -- Sat drag (mouse)
        local slidingSat = false
        local function updateSat(pos, doSet)
            local sx = math.clamp((pos.X - Sat.AbsolutePosition.X) / Sat.AbsoluteSize.X, 0, 1)
            local sy = 1 - math.clamp((pos.Y - Sat.AbsolutePosition.Y) / Sat.AbsoluteSize.Y, 0, 1)
            if doSet then set(Color3.fromHSV(curhuesizey, sx, sy), alpha, true, false) end
        end

        Sat.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                slidingSat = true
                updateSat(i.Position, true)
            end
        end)
        Sat.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                slidingSat = false
                updateSat(i.Position, true)
            end
        end)

        -- Hue drag (mouse)
        local slidingHue = false
        local function updateHue(pos, doSet)
            local sy = 1 - math.clamp((pos.Y - Hue.AbsolutePosition.Y) / Hue.AbsoluteSize.Y, 0, 1)
            Sat.BackgroundColor3 = Color3.fromHSV(sy,1,1)
            curhuesizey = sy
            if doSet then set(Color3.fromHSV(sy, sat, val), alpha, true, true) end
        end

        Hue.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                slidingHue = true
                updateHue(i.Position, true)
            end
        end)
        Hue.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                slidingHue = false
                updateHue(i.Position, true)
            end
        end)

        -- Shared move handler (mouse + touch)
        Library:Connection(UIS.InputChanged, function(i)
            local isMove = i.UserInputType == Enum.UserInputType.MouseMovement
                        or i.UserInputType == Enum.UserInputType.Touch
            if not isMove then return end
            if slidingHue then updateHue(i.Position, true) end
            if slidingSat then updateSat(i.Position, true) end
        end)

        Icon.MouseButton1Click:Connect(function()
            Window.Visible = not Window.Visible
            slidingHue = false; slidingSat = false
        end)

        Library:Connection(UIS.InputBegan, function(i)
            if Window.Visible and (i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch) then
                if not Library:IsMouseOverFrame(Window) and not Library:IsMouseOverFrame(Icon) then
                    Window.Visible = false
                end
            end
        end)

        local colorpickertypes = {}
        function colorpickertypes:Set(color, a) set(color, a, false, true) end
        return colorpickertypes, Window
    end

    -- ────────────────────────────────────────────────────────────
    -- Library functions
    -- ────────────────────────────────────────────────────────────
    local Pages    = Library.Pages
    local Sections = Library.Sections

    -- ── Window ──────────────────────────────────────────────────
    function Library:Window(Options)
        local device = DetectDevice()
        Library.IsMobile  = device == "Mobile"
        Library.IsConsole = device == "Console"
        Library.IsPC      = device == "PC"

        local useMobile  = Options.MobileSupport ~= false  -- default true
        local useTypo    = Options.Typewriter    ~= false  -- default true
        local menuName   = Options.Name or "lala.wtf"

        local Base = {
            Pages    = {},
            Sections = {},
            Elements = {},
            Dragging = { false, UDim2.new(0,0,0,0) },
            Title    = menuName,
        }

        -- Instances
        local ScreenGui   = Instance.new("ScreenGui",
            game:GetService("RunService"):IsStudio()
                and LP.PlayerGui or game.CoreGui)
        local Main        = Instance.new("Frame",      ScreenGui)
        local Inline      = Instance.new("Frame",      Main)
        local Middle      = Instance.new("Frame",      Inline)
        local Line        = Instance.new("Frame",      Middle)
        local Line2       = Instance.new("Frame",      Middle)
        local GradFrame   = Instance.new("Frame",      Middle)
        local UIGrad      = Instance.new("UIGradient", GradFrame)
        local Top         = Instance.new("TextButton", Inline)
        local TitleLabel  = Instance.new("TextLabel",  Top)
        local Bottom      = Instance.new("Frame",      Inline)
        local SectionsFr  = Instance.new("Frame",      Middle)
        local PagesHolder = Instance.new("Frame",      Top)
        local UIListL     = Instance.new("UIListLayout",PagesHolder)
        local VersionLbl  = Instance.new("TextLabel",  Bottom)
        local corner1     = Instance.new("UICorner",   Main)
        local corner2     = Instance.new("UICorner",   Inline)
        local stroke1     = Instance.new("UIStroke",   Main)
        local stroke2     = Instance.new("UIStroke",   Inline)

        for _, v in ipairs({Main,Inline,Middle,Line,Line2,GradFrame,TitleLabel,SectionsFr,VersionLbl}) do
            table.insert(Library.Instances, v)
        end
        table.insert(Library.ThemeObjects, TitleLabel)
        table.insert(Library.ThemeObjects, VersionLbl)

        ScreenGui.DisplayOrder = 2

        Main.Name             = "Main"
        Main.Position         = UDim2.new(0.5,0,0.5,0)
        Main.Size             = UDim2.new(0,580,0,260)
        Main.BackgroundColor3 = Color3.new(0.1098,0.1098,0.1098)
        Main.AnchorPoint      = Vector2.new(0.5,0.5)
        Library.Holder        = Main

        Inline.Name             = "Inline"
        Inline.Position         = UDim2.new(0,2,0,2)
        Inline.Size             = UDim2.new(1,-4,1,-4)
        Inline.BackgroundColor3 = Color3.new(0.0314,0.0314,0.0314)

        Middle.Name             = "Middle"
        Middle.Position         = UDim2.new(0,-1,0,22)
        Middle.Size             = UDim2.new(1,2,1,-44)
        Middle.BackgroundColor3 = Color3.new(0.0431,0.0431,0.0431)
        Middle.BorderMode       = Enum.BorderMode.Inset

        Line.Name             = "Line"
        Line.Position         = UDim2.new(0,-1,0,0)
        Line.Size             = UDim2.new(1,2,0,1)
        Line.BackgroundColor3 = Color3.new(0.1098,0.1098,0.1098)
        Line.BorderSizePixel  = 0

        Line2.Name             = "Line2"
        Line2.Position         = UDim2.new(0,-1,1,-1)
        Line2.Size             = UDim2.new(1,2,0,1)
        Line2.BackgroundColor3 = Color3.new(0.1098,0.1098,0.1098)
        Line2.BorderSizePixel  = 0

        GradFrame.Name             = "Gradient"
        GradFrame.Position         = UDim2.new(0.5,0,0,2)
        GradFrame.Size             = UDim2.new(0.5,0,0,1)
        GradFrame.BackgroundColor3 = Color3.new(1,1,1)
        GradFrame.BorderSizePixel  = 0
        Library.Gradient   = GradFrame

        UIGrad.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Library.Accent),
            ColorSequenceKeypoint.new(1, Color3.new(0.0431,0.0431,0.0431))
        }
        UIGrad.Rotation    = 180
        Library.UIGradient = UIGrad

        Top.Name                 = "Top"
        Top.Size                 = UDim2.new(1,0,0,22)
        Top.BackgroundTransparency = 1
        Top.AutoButtonColor      = false
        Top.Text                 = ""

        TitleLabel.Name                 = "Title"
        TitleLabel.Position             = UDim2.new(0,4,0,0)
        TitleLabel.Size                 = UDim2.new(1,-4,1,0)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Text                 = menuName
        TitleLabel.TextColor3           = Library.Accent
        TitleLabel.FontFace             = Library.UIFont
        TitleLabel.TextSize             = Library.FontSize
        TitleLabel.TextXAlignment       = Enum.TextXAlignment.Left
        TitleLabel.RichText             = true

        Bottom.Name                 = "Bottom"
        Bottom.Position             = UDim2.new(0,0,1,-22)
        Bottom.Size                 = UDim2.new(1,0,0,22)
        Bottom.BackgroundTransparency = 1

        SectionsFr.Name             = "Sections"
        SectionsFr.Position         = UDim2.new(0,10,0,13)
        SectionsFr.Size             = UDim2.new(0,110,1,-26)
        SectionsFr.BackgroundColor3 = Color3.new(0.0314,0.0314,0.0314)
        SectionsFr.BorderColor3     = Color3.new(0.1098,0.1098,0.1098)

        PagesHolder.Name                 = "Pages"
        PagesHolder.Position             = UDim2.new(0,60,0,0)
        PagesHolder.Size                 = UDim2.new(1,-60,1,0)
        PagesHolder.BackgroundTransparency = 1
        PagesHolder.ZIndex               = 52
        Library.PageHolder               = PagesHolder
        UIListL.FillDirection            = Enum.FillDirection.Horizontal
        UIListL.SortOrder                = Enum.SortOrder.LayoutOrder
        UIListL.Padding                  = UDim.new(0,6)

        VersionLbl.Name                 = "version"
        VersionLbl.Position             = UDim2.new(0,4,0,0)
        VersionLbl.Size                 = UDim2.new(1,-4,1,0)
        VersionLbl.BackgroundTransparency = 1
        VersionLbl.Text                 = '<font color="#4e4e4e">version: </font> live'
        VersionLbl.TextColor3           = Library.Accent
        VersionLbl.FontFace             = Library.UIFont
        VersionLbl.TextSize             = Library.FontSize
        VersionLbl.TextXAlignment       = Enum.TextXAlignment.Left
        VersionLbl.RichText             = true

        corner1.CornerRadius = UDim.new(0,2)
        corner2.CornerRadius = UDim.new(0,2)

        -- Typewriter
        if useTypo then
            StartTypewriter(TitleLabel, menuName)
        end

        -- ── Dragging ─────────────────────────────────────────────
        -- We store the drag state in Base.Dragging so the Lock button can cancel it.

        -- PC drag
        Library:Connection(Top.MouseButton1Down, function()
            if Library._UILocked then return end
            local loc = UIS:GetMouseLocation()
            Base.Dragging[1] = true
            Base.Dragging[2] = UDim2.new(0, loc.X - Main.AbsolutePosition.X,
                                          0, loc.Y - Main.AbsolutePosition.Y)
        end)
        Library:Connection(Top.MouseButton1Up, function()
            Base.Dragging[1] = false
        end)
        Library:Connection(UIS.InputChanged, function(i)
            if Library._UILocked then Base.Dragging[1] = false return end
            local loc = UIS:GetMouseLocation()
            if i.UserInputType == Enum.UserInputType.MouseMovement and Base.Dragging[1] then
                Main.Position = UDim2.new(
                    0, loc.X - Base.Dragging[2].X.Offset + Main.Size.X.Offset * Main.AnchorPoint.X,
                    0, loc.Y - Base.Dragging[2].Y.Offset + Main.Size.Y.Offset * Main.AnchorPoint.Y)
            end
        end)

        -- Touch drag on TopBar
        Top.InputBegan:Connect(function(i)
            if Library._UILocked then return end
            if i.UserInputType == Enum.UserInputType.Touch then
                Base.Dragging[1] = true
                Base.Dragging[2] = UDim2.new(
                    0, i.Position.X - Main.AbsolutePosition.X,
                    0, i.Position.Y - Main.AbsolutePosition.Y)
            end
        end)
        Top.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch then
                Base.Dragging[1] = false
            end
        end)
        Library:Connection(UIS.InputChanged, function(i)
            if Library._UILocked then Base.Dragging[1] = false return end
            if i.UserInputType == Enum.UserInputType.Touch and Base.Dragging[1] then
                Main.Position = UDim2.new(
                    0, i.Position.X - Base.Dragging[2].X.Offset + Main.Size.X.Offset * Main.AnchorPoint.X,
                    0, i.Position.Y - Base.Dragging[2].Y.Offset + Main.Size.Y.Offset * Main.AnchorPoint.Y)
            end
        end)

        -- Mobile size clamp
        if Library.IsMobile then
            local VP = workspace.CurrentCamera.ViewportSize
            Main.Size     = UDim2.new(0, math.min(580, VP.X - 8), 0, 260)
            Main.Position = UDim2.new(0.5,0,0.5,0)
        end

        -- ── Side buttons (Toggle / Lock) ─────────────────────────
        if useMobile then
            local VP = workspace.CurrentCamera.ViewportSize

            local TBtn, TBar, TWrap, TInn = MakeSideBtn(ScreenGui, "Toggle UI", 48)
            local LBtn, LBar, LWrap, LInn = MakeSideBtn(ScreenGui, "Lock UI",   71)

            Library._ToggleBtn = TBtn
            Library._LockBtn   = LBtn

            -- Draggable side panel
            do
                local on, st, sy = false, nil, nil
                local function startDrag(pos)
                    local a  = TWrap.AbsolutePosition
                    local b  = LWrap.AbsolutePosition
                    local h  = (b.Y + LWrap.AbsoluteSize.Y) - a.Y
                    if pos.X >= a.X-6 and pos.X <= a.X + TWrap.AbsoluteSize.X + 6
                    and pos.Y >= a.Y-6 and pos.Y <= a.Y + h + 6 then
                        on = true; st = pos
                        sy = TWrap.Position.Y.Offset
                    end
                end
                local function moveDrag(pos)
                    if not on then return end
                    local ny = math.clamp(sy + (pos.Y - st.Y), 0, VP.Y - 95)
                    TWrap.Position = UDim2.new(0,4,0,ny)
                    LWrap.Position = UDim2.new(0,4,0,ny+23)
                end
                UIS.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.Touch
                    or i.UserInputType == Enum.UserInputType.MouseButton1 then
                        startDrag(i.Position)
                    end
                end)
                UIS.InputChanged:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.Touch
                    or i.UserInputType == Enum.UserInputType.MouseMovement then
                        moveDrag(i.Position)
                    end
                end)
                UIS.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.Touch
                    or i.UserInputType == Enum.UserInputType.MouseButton1 then
                        on = false
                    end
                end)
            end

            TBtn.MouseButton1Click:Connect(function()
                Library:SetOpen(not Library.Open)
            end)

            LBtn.MouseButton1Click:Connect(function()
                Library._UILocked = not Library._UILocked
                Base.Dragging[1]  = false
                if Library._UILocked then
                    LBtn.TextColor3 = Color3.fromRGB(255,70,70)
                    LBar.BackgroundColor3 = Color3.fromRGB(255,70,70)
                else
                    LBtn.TextColor3 = Color3.fromRGB(78,78,78)
                    LBar.BackgroundColor3 = Library.Accent
                end
            end)
        end

        -- ── Default keybinds ─────────────────────────────────────
        Library:Connection(UIS.InputBegan, function(i, gpe)
            if gpe or Library._UILocked then return end
            if i.KeyCode == Enum.KeyCode.RightShift
            or i.KeyCode == Enum.KeyCode.ButtonSelect then
                Library:SetOpen(not Library.Open)
            end
        end)

        Base.Elements = {
            Main          = Main,
            Title         = TitleLabel,
            Middle        = Middle,
            PageHolder    = PagesHolder,
            SectionHolder = SectionsFr,
        }
        return setmetatable(Base, Library)
    end

    -- ── Page ────────────────────────────────────────────────────
    function Library:Page(Options)
        local Page = {
            Window   = self,
            Open     = false,
            Sections = {},
            Elements = {},
            Title    = Options.Name or "page",
        }

        local Holder       = Instance.new("TextButton", Page.Window.Elements.PageHolder)
        local Button       = Instance.new("Frame",      Holder)
        local TopLine      = Instance.new("Frame",      Button)
        local Line         = Instance.new("Frame",      Button)
        local Left         = Instance.new("Frame",      Button)
        local Right        = Instance.new("Frame",      Button)
        local Black        = Instance.new("Frame",      Button)
        local Black2       = Instance.new("Frame",      Button)
        local Title        = Instance.new("TextLabel",  Holder)
        local PageSections = Instance.new("Frame",      Page.Window.Elements.SectionHolder)
        local UIListL      = Instance.new("UIListLayout", PageSections)
        local SectionHolder= Instance.new("Frame",      Page.Window.Elements.Middle)

        for _, v in ipairs({Button,TopLine,Line,Title,Left,Right,Black,Black2}) do
            table.insert(Library.Instances, v)
        end
        table.insert(Library.ThemeObjects, TopLine)
        table.insert(Library.ThemeObjects, Left)
        table.insert(Library.ThemeObjects, Right)

        Holder.Name                 = "Page"
        Holder.Size                 = UDim2.new(0,50,1,0)
        Holder.BackgroundTransparency = 1
        Holder.Text                 = ""
        Holder.AutoButtonColor      = false
        Holder.Font                 = Enum.Font.SourceSans
        Holder.TextSize             = 14
        Holder.ZIndex               = 53

        Button.Name             = "Button"
        Button.Position         = UDim2.new(0,0,0,3)
        Button.Size             = UDim2.new(1,0,1,-2)
        Button.BackgroundColor3 = Color3.new(0.0431,0.0431,0.0431)
        Button.BorderColor3     = Color3.new(0.1098,0.1098,0.1098)
        Button.ZIndex           = 53
        Button.Visible          = false

        TopLine.Name             = "TopLine"
        TopLine.Position         = UDim2.new(0,3,0,0)
        TopLine.Size             = UDim2.new(1,-5,0,1)
        TopLine.BackgroundColor3 = Library.Accent
        TopLine.BorderSizePixel  = 0
        TopLine.ZIndex           = 53

        Line.Name             = "Line"
        Line.Position         = UDim2.new(0,0,1,0)
        Line.Size             = UDim2.new(1,0,0,1)
        Line.BackgroundColor3 = Color3.new(0.0431,0.0431,0.0431)
        Line.BorderSizePixel  = 0
        Line.ZIndex           = 53

        Left.Name             = "Left"
        Left.Position         = UDim2.new(0,-1,0,2)
        Left.Size             = UDim2.new(0,5,0,1)
        Left.BackgroundColor3 = Library.Accent
        Left.BorderSizePixel  = 0
        Left.Rotation         = -45
        Left.ZIndex           = 53

        Right.Name             = "Right"
        Right.Position         = UDim2.new(1,-4,0,2)
        Right.Size             = UDim2.new(0,5,0,1)
        Right.BackgroundColor3 = Library.Accent
        Right.BorderSizePixel  = 0
        Right.Rotation         = 45
        Right.ZIndex           = 53

        Black.Name             = "Black"
        Black.Position         = UDim2.new(0,-5,0,-2)
        Black.Size             = UDim2.new(0,7,0,6)
        Black.BackgroundColor3 = Color3.new(0.0314,0.0314,0.0314)
        Black.BorderSizePixel  = 0
        Black.Rotation         = -45
        Black.ZIndex           = 55

        Black2.Name             = "Black2"
        Black2.Position         = UDim2.new(1,-2,0,-2)
        Black2.Size             = UDim2.new(0,7,0,6)
        Black2.BackgroundColor3 = Color3.new(0.0314,0.0314,0.0314)
        Black2.BorderSizePixel  = 0
        Black2.Rotation         = 45
        Black2.ZIndex           = 55

        Title.Name                 = "Title"
        Title.Position             = UDim2.new(0,0,0,2)
        Title.Size                 = UDim2.new(1,0,1,-2)
        Title.BackgroundTransparency = 1
        Title.Text                 = Page.Title
        Title.TextColor3           = Color3.fromRGB(78,78,78)
        Title.FontFace             = Library.UIFont
        Title.TextSize             = Library.FontSize
        Title.ZIndex               = 53
        Title.RichText             = true

        PageSections.Name                 = "PageSections"
        PageSections.Position             = UDim2.new(0,8,0,10)
        PageSections.Size                 = UDim2.new(1,-16,1,-20)
        PageSections.BackgroundTransparency = 1
        PageSections.Visible              = false
        UIListL.SortOrder                 = Enum.SortOrder.LayoutOrder
        UIListL.Padding                   = UDim.new(0,3)

        SectionHolder.Name                 = "SectionHolder"
        SectionHolder.Position             = UDim2.new(0,133,0,13)
        SectionHolder.Size                 = UDim2.new(1,-144,1,-26)
        SectionHolder.BackgroundTransparency = 1
        SectionHolder.ZIndex               = 53
        SectionHolder.Visible              = false

        function Page:Turn(bool)
            Page.Open          = bool
            PageSections.Visible = bool
            Button.Visible     = bool
            if bool then
                table.insert(Library.ThemeObjects, Title)
                Title.TextColor3 = Library.Accent
            else
                local idx = table.find(Library.ThemeObjects, Title)
                if idx then table.remove(Library.ThemeObjects, idx) end
                Title.TextColor3 = Color3.fromRGB(78,78,78)
            end
            SectionHolder.Visible = bool
        end

        Holder.MouseButton1Click:Connect(function()
            if not Page.Open then
                Page:Turn(true)
                for _, other in pairs(Page.Window.Pages) do
                    if other.Open and other ~= Page then other:Turn(false) end
                end
            end
        end)

        if #Page.Window.Pages == 0 then Page:Turn(true) end

        task.defer(function()
            Holder.Size = UDim2.new(0, Title.TextBounds.X + 16, 1, 0)
        end)

        Page.Elements = { ButtonHolder = PageSections, RealHold = SectionHolder }
        Page.Window.Pages[#Page.Window.Pages + 1] = Page
        return setmetatable(Page, Library.Pages)
    end

    -- ── Section ─────────────────────────────────────────────────
    function Pages:Section(Options)
        local Section = {
            Window    = self.Window,
            Page      = self,
            Open      = false,
            Elements  = {},
            Title     = Options.Name       or "section",
            LeftName  = Options.LeftTitle  or "left",
            RightName = Options.RightTitle or "right",
        }

        local Button        = Instance.new("TextButton", Section.Page.Elements.ButtonHolder)
        local Accent        = Instance.new("Frame",      Button)
        local Frame         = Instance.new("Frame",      Button)
        local UIGradient    = Instance.new("UIGradient", Frame)
        local Title         = Instance.new("TextLabel",  Frame)
        local NewSection    = Instance.new("Frame",      Section.Page.Elements.RealHold)
        local Left          = Instance.new("Frame",      NewSection)
        local Bar           = Instance.new("Frame",      Left)
        local GradL         = Instance.new("UIGradient", Bar)
        local GradLineL     = Instance.new("Frame",      Bar)
        local UIGrad3       = Instance.new("UIGradient", GradLineL)
        local LeftTitle     = Instance.new("TextLabel",  Bar)
        local Right         = Instance.new("Frame",      NewSection)
        local Bar2          = Instance.new("Frame",      Right)
        local GradR         = Instance.new("UIGradient", Bar2)
        local GradLineR     = Instance.new("Frame",      Bar2)
        local UIGrad2       = Instance.new("UIGradient", GradLineR)
        local RightTitle    = Instance.new("TextLabel",  Bar2)
        local LeftContent   = Instance.new("Frame",      Left)
        local LeftList      = Instance.new("UIListLayout", LeftContent)
        local RightContent  = Instance.new("Frame",      Right)
        local RightList     = Instance.new("UIListLayout", RightContent)

        for _, v in ipairs({Accent,Frame,Title,Left,Bar,GradLineL,LeftTitle,Right,Bar2,GradLineR,RightTitle}) do
            table.insert(Library.Instances, v)
        end
        table.insert(Library.ThemeObjects, Accent)

        local gradSeq = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.new(0.78,0.749,0.8)),
            ColorSequenceKeypoint.new(1, Color3.new(1,1,1))
        }
        local midSeq = ColorSequence.new{
            ColorSequenceKeypoint.new(0,    Color3.new(0.1098,0.1098,0.1098)),
            ColorSequenceKeypoint.new(0.483,Color3.new(0.0431,0.0431,0.0431)),
            ColorSequenceKeypoint.new(1,    Color3.new(0.1098,0.1098,0.1098))
        }

        Button.Name                 = "Button"
        Button.Size                 = UDim2.new(1,0,0,22)
        Button.BackgroundTransparency = 1
        Button.AutoButtonColor      = false
        Button.Text                 = ""
        Button.ZIndex               = 54

        Accent.Name             = "Accent"
        Accent.Size             = UDim2.new(0,1,1,0)
        Accent.BackgroundColor3 = Library.Accent
        Accent.BorderSizePixel  = 0
        Accent.ZIndex           = 54
        Accent.BackgroundTransparency = 0.5

        Frame.Position         = UDim2.new(0,1,0,0)
        Frame.Size             = UDim2.new(1,-2,1,0)
        Frame.BackgroundColor3 = Color3.new(0.149,0.149,0.149)
        Frame.BorderSizePixel  = 0
        Frame.ZIndex           = 54
        UIGradient.Color       = ColorSequence.new{
            ColorSequenceKeypoint.new(0,Color3.new(0.741,0.741,0.741)),
            ColorSequenceKeypoint.new(1,Color3.new(0.204,0.204,0.204))
        }
        UIGradient.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0,0.5,0),
            NumberSequenceKeypoint.new(1,0.5,0)
        }

        Title.Name                 = "Title"
        Title.Position             = UDim2.new(0,4,0,0)
        Title.Size                 = UDim2.new(1,-4,0,20)
        Title.BackgroundTransparency = 1
        Title.Text                 = Options.Name
        Title.TextColor3           = Color3.fromRGB(78,78,78)
        Title.FontFace             = Library.UIFont
        Title.TextSize             = Library.FontSize
        Title.ZIndex               = 54
        Title.TextXAlignment       = Enum.TextXAlignment.Left

        NewSection.Name                 = "NewSection"
        NewSection.Size                 = UDim2.new(1,0,1,0)
        NewSection.BackgroundTransparency = 1
        NewSection.Visible              = false

        Left.Name             = "Left"
        Left.Position         = UDim2.new(0,2,0,0)
        Left.Size             = UDim2.new(0.5,-10,1,0)
        Left.BackgroundColor3 = Color3.new(0.0314,0.0314,0.0314)
        Left.BorderColor3     = Color3.new(0.1098,0.1098,0.1098)

        Bar.Name             = "Bar"
        Bar.Size             = UDim2.new(1,0,0,20)
        Bar.BackgroundColor3 = Color3.new(0.0431,0.0431,0.0431)
        Bar.BorderColor3     = Color3.new(0.1098,0.1098,0.1098)
        GradL.Color          = gradSeq; GradL.Rotation = -90
        GradLineL.Position   = UDim2.new(0,0,1,0)
        GradLineL.Size       = UDim2.new(1,0,0,1)
        GradLineL.BackgroundColor3 = Color3.new(1,1,1)
        GradLineL.BorderSizePixel  = 0
        UIGrad3.Color        = midSeq

        LeftTitle.Name             = "LeftTitle"
        LeftTitle.Position         = UDim2.new(0,4,0,0)
        LeftTitle.Size             = UDim2.new(1,-4,1,0)
        LeftTitle.BackgroundTransparency = 1
        LeftTitle.Text             = Section.LeftName
        LeftTitle.TextColor3       = Color3.new(0.3059,0.3059,0.3059)
        LeftTitle.FontFace         = Library.UIFont
        LeftTitle.TextSize         = Library.FontSize
        LeftTitle.TextXAlignment   = Enum.TextXAlignment.Left

        Right.Name             = "Right"
        Right.Position         = UDim2.new(0.5,8,0,0)
        Right.Size             = UDim2.new(0.5,-10,1,0)
        Right.BackgroundColor3 = Color3.new(0.0314,0.0314,0.0314)
        Right.BorderColor3     = Color3.new(0.1098,0.1098,0.1098)

        Bar2.Name             = "Bar2"
        Bar2.Size             = UDim2.new(1,0,0,20)
        Bar2.BackgroundColor3 = Color3.new(0.0431,0.0431,0.0431)
        Bar2.BorderColor3     = Color3.new(0.1098,0.1098,0.1098)
        GradR.Color           = gradSeq; GradR.Rotation = -90
        GradLineR.Position    = UDim2.new(0,0,1,0)
        GradLineR.Size        = UDim2.new(1,0,0,1)
        GradLineR.BackgroundColor3 = Color3.new(1,1,1)
        GradLineR.BorderSizePixel  = 0
        UIGrad2.Color         = midSeq

        RightTitle.Name             = "RightTitle"
        RightTitle.Position         = UDim2.new(0,4,0,0)
        RightTitle.Size             = UDim2.new(1,-4,1,0)
        RightTitle.BackgroundTransparency = 1
        RightTitle.Text             = Section.RightName
        RightTitle.TextColor3       = Color3.new(0.3059,0.3059,0.3059)
        RightTitle.FontFace         = Library.UIFont
        RightTitle.TextSize         = Library.FontSize
        RightTitle.TextXAlignment   = Enum.TextXAlignment.Left

        LeftContent.Name                 = "LeftContent"
        LeftContent.Position             = UDim2.new(0,10,0,30)
        LeftContent.Size                 = UDim2.new(1,-20,1,-40)
        LeftContent.BackgroundTransparency = 1
        LeftList.SortOrder               = Enum.SortOrder.LayoutOrder
        LeftList.Padding                 = UDim.new(0,4)

        RightContent.Name                 = "RightConnect"
        RightContent.Position             = UDim2.new(0,10,0,30)
        RightContent.Size                 = UDim2.new(1,-20,1,-40)
        RightContent.BackgroundTransparency = 1
        RightList.SortOrder               = Enum.SortOrder.LayoutOrder
        RightList.Padding                 = UDim.new(0,4)

        function Section:Turn(bool)
            Section.Open    = bool
            NewSection.Visible = bool
            if bool then
                table.insert(Library.ThemeObjects, Title)
                Title.TextColor3 = Library.Accent
            else
                local idx = table.find(Library.ThemeObjects, Title)
                if idx then table.remove(Library.ThemeObjects, idx) end
                Title.TextColor3 = Color3.fromRGB(78,78,78)
            end
            Accent.BackgroundTransparency = bool and 0 or 0.5
        end

        Button.MouseButton1Click:Connect(function()
            if not Section.Open then
                Section:Turn(true)
                for _, other in pairs(Section.Page.Sections) do
                    if other.Open and other ~= Section then other:Turn(false) end
                end
            end
        end)

        if #Section.Page.Sections == 0 then Section:Turn(true) end

        Section.Elements = { Left = LeftContent, Right = RightContent }
        Section.Page.Sections[#Section.Page.Sections + 1] = Section
        return setmetatable(Section, Library.Sections)
    end

    -- ── Toggle ──────────────────────────────────────────────────
    function Sections:Toggle(Options)
        local Properties = Options or {}
        local Toggle = {
            Window      = self.Window,
            Page        = self.Page,
            Section     = self,
            State       = Properties.default or Properties.Default or Properties.def or false,
            Callback    = Properties.callback or Properties.Callback or function() end,
            Flag        = Properties.flag or Properties.Flag or Library.NextFlag(),
            Toggled     = false,
            Colorpickers= 0,
        }

        local side   = Options.Side == "Right" and Toggle.Section.Elements.Right or Toggle.Section.Elements.Left
        local Holder = Instance.new("TextButton", side)
        local Frame  = Instance.new("Frame",      Holder)
        local AccentF= Instance.new("Frame",      Frame)
        local Grad   = Instance.new("UIGradient", AccentF)
        local TLabel = Instance.new("TextLabel",  Holder)

        table.insert(Library.Instances, Frame)
        table.insert(Library.Instances, AccentF)
        table.insert(Library.Instances, TLabel)
        table.insert(Library.ThemeObjects, AccentF)

        Holder.Name                 = "Toggle"
        Holder.Size                 = UDim2.new(1,0,0,10)
        Holder.BackgroundTransparency = 1
        Holder.Text                 = ""
        Holder.AutoButtonColor      = false
        Holder.Font                 = Enum.Font.SourceSans
        Holder.TextSize             = 14

        Frame.Position         = UDim2.new(0,0,0,3)
        Frame.Size             = UDim2.new(0,6,0,6)
        Frame.BackgroundColor3 = Color3.new(0.0784,0.0784,0.0784)
        Frame.BorderColor3     = Color3.new(0,0,0)

        AccentF.Name             = "Accent"
        AccentF.Size             = UDim2.new(1,0,1,0)
        AccentF.BackgroundColor3 = Library.Accent
        AccentF.BorderSizePixel  = 0
        AccentF.Visible          = false
        Grad.Color    = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(0.78,0.749,0.8)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}
        Grad.Rotation = -90

        TLabel.Position             = UDim2.new(0,15,0,0)
        TLabel.Size                 = UDim2.new(1,0,1,0)
        TLabel.BackgroundTransparency = 1
        TLabel.TextColor3           = Color3.new(0.3059,0.3059,0.3059)
        TLabel.FontFace             = Library.UIFont
        TLabel.TextSize             = Library.FontSize
        TLabel.ZIndex               = 105
        TLabel.TextXAlignment       = Enum.TextXAlignment.Left
        TLabel.Text                 = Options.Name or "toggle"

        local function SetState()
            Toggle.Toggled = not Toggle.Toggled
            AccentF.Visible  = Toggle.Toggled
            TLabel.TextColor3 = Toggle.Toggled and Color3.fromRGB(255,255,255) or Color3.new(0.3059,0.3059,0.3059)
            Library.Flags[Toggle.Flag] = Toggle.Toggled
            Toggle.Callback(Toggle.Toggled)
        end

        -- Keybind sub-element
        function Toggle:Keybind(Opts)
            local P = Opts or {}
            local KB = {
                Mode       = P.mode or P.Mode or "Toggle",
                Callback   = P.callback or P.Callback or function() end,
                Flag       = P.flag or P.Flag or Library.NextFlag(),
                Binding    = nil,
                Connection = nil,
            }
            local Key, State = nil, false
            local Cycle = KB.Mode=="Hold" and 1 or KB.Mode=="Toggle" and 2 or 3

            local KHolder = Instance.new("TextButton", Holder)
            local Value   = Instance.new("TextLabel",  Holder)
            local ModeL   = Instance.new("TextLabel",  Holder)
            table.insert(Library.Instances, Value)
            table.insert(Library.Instances, ModeL)

            KHolder.Name = "Holder"; KHolder.Size=UDim2.new(0,40,0,10)
            KHolder.BackgroundTransparency=1; KHolder.Text=""
            KHolder.AutoButtonColor=false; KHolder.Font=Enum.Font.SourceSans
            KHolder.TextSize=14; KHolder.Position=UDim2.new(1,-45,0,0)

            Value.Name="Value"; Value.Position=UDim2.new(0,15,0,0)
            Value.Size=UDim2.new(1,-30,1,0); Value.BackgroundTransparency=1
            Value.Text="[-]"; Value.TextColor3=Color3.new(0.3059,0.3059,0.3059)
            Value.FontFace=Library.UIFont; Value.TextSize=Library.FontSize
            Value.ZIndex=105; Value.TextXAlignment=Enum.TextXAlignment.Right

            ModeL.Name="Mode"; ModeL.Position=UDim2.new(0,TLabel.TextBounds.X+20,0,0)
            ModeL.Size=UDim2.new(1,-30,1,0); ModeL.BackgroundTransparency=1
            ModeL.Text=KB.Mode=="Hold" and "[H]" or KB.Mode=="Toggle" and "[T]" or "[A]"
            ModeL.TextColor3=Color3.new(1,1,1); ModeL.FontFace=Library.UIFont
            ModeL.TextSize=Library.FontSize; ModeL.ZIndex=105
            ModeL.TextXAlignment=Enum.TextXAlignment.Left

            local function set(newkey)
                if string.find(tostring(newkey),"Enum") then
                    if KB.Connection then KB.Connection:Disconnect() end
                    if tostring(newkey):find("Enum.KeyCode.") then
                        newkey = Enum.KeyCode[tostring(newkey):gsub("Enum.KeyCode.","")]
                    elseif tostring(newkey):find("Enum.UserInputType.") then
                        newkey = Enum.UserInputType[tostring(newkey):gsub("Enum.UserInputType.","")]
                    end
                    if newkey == Enum.KeyCode.Backspace then
                        Key=nil; Value.Text="[-]"
                    elseif newkey then
                        Key=newkey
                        Value.Text="[".. (Library.Keys[newkey] or tostring(newkey):gsub("Enum.KeyCode.","")) .."]"
                    end
                    Library.Flags[KB.Flag.."_KEY"] = newkey
                elseif table.find({"Always","Toggle","Hold"}, newkey) then
                    KB.Mode = newkey
                    ModeL.Text = KB.Mode=="Hold" and "[H]" or KB.Mode=="Toggle" and "[T]" or "[A]"
                    Cycle = KB.Mode=="Hold" and 1 or KB.Mode=="Toggle" and 2 or 3
                    if KB.Mode=="Always" then State=true; Library.Flags[KB.Flag]=true; KB.Callback(true) end
                    Library.Flags[KB.Flag.."_KEY STATE"] = newkey
                else
                    State=newkey; Library.Flags[KB.Flag]=newkey; KB.Callback(newkey)
                end
            end

            set(P.state or P.State or P.default or P.Default)
            set(KB.Mode)

            KHolder.MouseButton1Click:Connect(function()
                if KB.Binding then return end
                Value.Text = "[-]"
                KB.Binding = Library:Connection(UIS.InputBegan, function(i, gpe)
                    set(i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode or i.UserInputType)
                    Library:Disconnect(KB.Binding); task.wait(); KB.Binding=nil
                end)
            end)
            Library:Connection(UIS.InputBegan, function(i)
                if (i.KeyCode==Key or i.UserInputType==Key) and not KB.Binding then
                    if KB.Mode=="Hold" then
                        Library.Flags[KB.Flag]=true
                        KB.Connection=Library:Connection(RS.RenderStepped, function() KB.Callback(true) end)
                    elseif KB.Mode=="Toggle" then
                        State=not State; Library.Flags[KB.Flag]=State; KB.Callback(State)
                    end
                end
            end)
            Library:Connection(UIS.InputEnded, function(i)
                if KB.Mode=="Hold" and (i.KeyCode==Key or i.UserInputType==Key) and KB.Connection then
                    KB.Connection:Disconnect(); Library.Flags[KB.Flag]=false; KB.Callback(false)
                end
            end)
            Holder.MouseButton2Click:Connect(function()
                Cycle+=1; if Cycle>3 then Cycle=1 end
                set(Cycle==1 and "Hold" or Cycle==2 and "Toggle" or "Always")
            end)
            Library.Flags[KB.Flag.."_KEY"]=P.state; Library.Flags[KB.Flag.."_KEY STATE"]=KB.Mode
            Flags[KB.Flag]=set; Flags[KB.Flag.."_KEY"]=set; Flags[KB.Flag.."_KEY STATE"]=set
            function KB:Set(k) set(k) end
            task.defer(function() ModeL.Position=UDim2.new(0,TLabel.TextBounds.X+20,0,0) end)
            return KB
        end

        -- Colorpicker sub-element
        function Toggle:Colorpicker(Props)
            local P = Props or {}
            Toggle.Colorpickers += 1
            local cp, _ = Library:NewPicker(
                P.default or P.Default or Color3.fromRGB(255,0,0),
                P.alpha or P.Alpha or 1,
                Holder, Toggle.Colorpickers-1,
                P.flag or P.Flag or Library.NextFlag(),
                P.callback or P.Callback or function() end)
            local ret = {}
            function ret:Set(c) cp:Set(c) end
            return ret
        end

        function Toggle.Set(bool)
            bool = type(bool)=="boolean" and bool or false
            if Toggle.Toggled ~= bool then SetState() end
        end
        Toggle.Set(Toggle.State)
        Library.Flags[Toggle.Flag] = Toggle.State
        Flags[Toggle.Flag] = Toggle.Set

        Library:Connection(Holder.MouseButton1Click, SetState)
        return Toggle
    end

    -- ── Slider ──────────────────────────────────────────────────
    function Sections:Slider(Options)
        local P = Options or {}
        local Slider = {
            Window   = self.Window,
            Page     = self.Page,
            Section  = self,
            Name     = P.Name or P.name or P.Title or nil,
            Min      = P.min or P.Min or 0,
            Max      = P.max or P.Max or 100,
            State    = P.default or P.Default or P.def or 10,
            Sub      = P.suffix or P.Suffix or P.prefix or P.Prefix or "",
            Decimals = P.decimals or P.Decimals or 1,
            Callback = P.callback or P.Callback or function() end,
            Flag     = P.flag or P.Flag or Library.NextFlag(),
        }
        local TextValue = "[value]" .. Slider.Sub

        local side   = P.Side=="Right" and Slider.Section.Elements.Right or Slider.Section.Elements.Left
        local Holder = Instance.new("Frame",      side)
        local Frame  = Instance.new("TextButton", Holder)
        local AccBar = Instance.new("TextButton", Frame)
        local Grad2  = Instance.new("UIGradient", AccBar)
        local Grad   = Instance.new("UIGradient", Frame)
        local TitleL = Instance.new("TextLabel",  Holder)
        local PlusBtn= Instance.new("TextButton", Holder)
        local MinBtn = Instance.new("TextButton", Holder)
        local ValueL = Instance.new("TextLabel",  Slider.Name and Holder or Frame)
        local TypeBox= Instance.new("TextBox",    Frame)  -- inline type-to-set textbox

        TitleL.Visible = not not Slider.Name

        for _, v in ipairs({Frame,AccBar,TitleL,PlusBtn,MinBtn,ValueL,TypeBox}) do
            table.insert(Library.Instances, v)
        end
        table.insert(Library.ThemeObjects, AccBar)

        Holder.Name                 = "Slider"
        Holder.Size                 = Slider.Name and UDim2.new(1,0,0,25) or UDim2.new(1,0,0,10)
        Holder.BackgroundTransparency = 1

        Frame.Position         = Slider.Name and UDim2.new(0,15,0,16) or UDim2.new(0,15,0,3)
        Frame.Size             = UDim2.new(1,-30,0,6)
        Frame.BackgroundColor3 = Color3.new(0.0784,0.0784,0.0784)
        Frame.BorderColor3     = Color3.new(0,0,0)
        Frame.AutoButtonColor  = false
        Frame.Text             = ""

        AccBar.Name             = "Accent"
        AccBar.Size             = UDim2.new(0,0,1,0)
        AccBar.BackgroundColor3 = Library.Accent
        AccBar.BorderSizePixel  = 0
        AccBar.AutoButtonColor  = false
        AccBar.Text             = ""
        Grad2.Color    = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(0.78,0.749,0.8)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}
        Grad2.Rotation = -90
        Grad.Color     = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(0.78,0.749,0.8)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}
        Grad.Rotation  = -90

        if Slider.Name then
            TitleL.Name             = "Title"
            TitleL.Position         = UDim2.new(0,15,0,0)
            TitleL.Size             = UDim2.new(1,0,0,10)
            TitleL.BackgroundTransparency = 1
            TitleL.TextColor3       = Color3.new(0.3059,0.3059,0.3059)
            TitleL.FontFace         = Library.UIFont
            TitleL.TextSize         = Library.FontSize
            TitleL.ZIndex           = 105
            TitleL.TextXAlignment   = Enum.TextXAlignment.Left
            TitleL.Text             = Slider.Name
        end

        PlusBtn.Name               = "plus"
        PlusBtn.Position           = Slider.Name and UDim2.new(1,-7,0,13) or UDim2.new(1,-7,0,0)
        PlusBtn.Size               = UDim2.new(0,8,0,8)
        PlusBtn.BackgroundTransparency=1; PlusBtn.BorderSizePixel=0
        PlusBtn.Text               = "+"
        PlusBtn.TextColor3         = Color3.new(0.3059,0.3059,0.3059)
        PlusBtn.FontFace           = Library.UIFont; PlusBtn.TextSize=Library.FontSize

        MinBtn.Name                = "minus"
        MinBtn.Position            = Slider.Name and UDim2.new(0,-1,0,13) or UDim2.new(0,-1,0,0)
        MinBtn.Size                = UDim2.new(0,8,0,8)
        MinBtn.BackgroundTransparency=1; MinBtn.BorderSizePixel=0
        MinBtn.Text                = "-"
        MinBtn.TextColor3          = Color3.new(0.3059,0.3059,0.3059)
        MinBtn.FontFace            = Library.UIFont; MinBtn.TextSize=Library.FontSize

        ValueL.Name                 = "Value"
        ValueL.Position             = Slider.Name and UDim2.new(0,15,0,0) or UDim2.new(0,0,0,-1)
        ValueL.Size                 = Slider.Name and UDim2.new(1,-30,0,10) or UDim2.new(1,0,1,0)
        ValueL.BackgroundTransparency=1
        ValueL.Text                 = "0"
        ValueL.TextColor3           = Color3.new(0.3059,0.3059,0.3059)
        ValueL.FontFace             = Library.UIFont; ValueL.TextSize=Library.FontSize
        ValueL.ZIndex               = 105
        ValueL.TextXAlignment       = Slider.Name and Enum.TextXAlignment.Right or Enum.TextXAlignment.Center

        -- Inline TextBox for typing a value (hidden until focused)
        TypeBox.Name                 = "TypeBox"
        TypeBox.Size                 = UDim2.new(1,0,1,0)
        TypeBox.BackgroundTransparency=1
        TypeBox.Text                 = ""
        TypeBox.TextColor3           = Color3.fromRGB(255,255,255)
        TypeBox.FontFace             = Library.UIFont
        TypeBox.TextSize             = Library.FontSize
        TypeBox.PlaceholderText      = "type value..."
        TypeBox.PlaceholderColor3    = Color3.fromRGB(100,100,100)
        TypeBox.ClearTextOnFocus     = true
        TypeBox.ZIndex               = 200
        TypeBox.Visible              = false
        TypeBox.TextXAlignment       = Enum.TextXAlignment.Center

        -- ── Set logic ──
        local Sliding = false
        local Val     = Slider.State

        local function Set(value)
            value = math.clamp(Library:Round(value, Slider.Decimals), Slider.Min, Slider.Max)
            Val   = value

            local isMin = value == Slider.Min
            ValueL.TextColor3 = isMin and Color3.new(0.3059,0.3059,0.3059) or Color3.fromRGB(255,255,255)
            if Slider.Name then
                TitleL.TextColor3 = isMin and Color3.new(0.3059,0.3059,0.3059) or Color3.fromRGB(255,255,255)
            end

            ValueL.Text = TextValue:gsub("%[value%]", string.format("%.14g", value))

            local pct = (value - Slider.Min) / (Slider.Max - Slider.Min)
            AccBar.Size = UDim2.new(pct, 0, 1, 0)

            Library.Flags[Slider.Flag] = value
            Slider.Callback(value)
        end

        local function Slide(pos)
            local pct   = (pos.X - Frame.AbsolutePosition.X) / Frame.AbsoluteSize.X
            local value = ((Slider.Max - Slider.Min) * pct) + Slider.Min
            Set(value)
        end

        -- TypeBox: hide ValueL while editing, show when done
        TypeBox.Focused:Connect(function()
            ValueL.Visible  = false
            TypeBox.Visible = true
            TypeBox.Text    = string.format("%.14g", Val)
            TypeBox:CaptureFocus()
        end)
        TypeBox.FocusLost:Connect(function(enter)
            local n = tonumber(TypeBox.Text)
            if n then Set(n) end
            TypeBox.Visible  = false
            ValueL.Visible   = true
            TypeBox.Text     = ""
        end)

        -- Tap value label to start typing (mobile + PC)
        ValueL.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.Touch
            or i.UserInputType == Enum.UserInputType.MouseButton1 then
                if not Sliding then
                    TypeBox.Visible = true
                    ValueL.Visible  = false
                    TypeBox.Text    = string.format("%.14g", Val)
                    TypeBox:CaptureFocus()
                end
            end
        end)

        -- Drag on Frame (mouse)
        Library:Connection(Frame.InputBegan, function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then
                Sliding = true; Slide(i.Position)
            end
            if i.UserInputType == Enum.UserInputType.Touch then
                Sliding = true; Slide(i.Position)
            end
        end)
        Library:Connection(Frame.InputEnded, function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                Sliding = false
            end
        end)
        Library:Connection(AccBar.InputBegan, function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                Sliding = true; Slide(i.Position)
            end
        end)
        Library:Connection(AccBar.InputEnded, function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
                Sliding = false
            end
        end)
        Library:Connection(UIS.InputChanged, function(i)
            if not Sliding then return end
            if i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch then
                Slide(i.Position)
            end
        end)

        Library:Connection(PlusBtn.MouseButton1Click,  function() Set(Val + Slider.Decimals) end)
        Library:Connection(MinBtn.MouseButton1Click,   function() Set(Val - Slider.Decimals) end)

        Set(Slider.State)

        function Slider:Set(v) Set(v) end
        Flags[Slider.Flag] = Set
        return Slider
    end

    -- ── List (Dropdown) ─────────────────────────────────────────
    function Sections:List(Options)
        local P = Options or {}
        local Dropdown = {
            Window      = self.Window,
            Page        = self.Page,
            Section     = self,
            Open        = false,
            Name        = P.Name or P.name or nil,
            Options     = P.options or P.Options or {"1","2","3"},
            State       = P.default or P.Default or P.def or nil,
            Callback    = P.callback or P.Callback or function() end,
            Flag        = P.flag or P.Flag or Library.NextFlag(),
            OptionInsts = {},
        }

        local side    = P.Side=="Right" and Dropdown.Section.Elements.Right or Dropdown.Section.Elements.Left
        local Holder  = Instance.new("Frame",      side)
        local Frame   = Instance.new("TextButton", Holder)
        local Grad    = Instance.new("UIGradient", Frame)
        local ValueL  = Instance.new("TextLabel",  Frame)
        local Icon    = Instance.new("TextLabel",  Frame)
        local Content = Instance.new("Frame",      Frame)
        local Grad2   = Instance.new("UIGradient", Content)
        local ListL   = Instance.new("UIListLayout",Content)
        local Title   = Instance.new("TextLabel",  Holder)

        table.insert(Library.Instances, Frame)
        table.insert(Library.Instances, ValueL)
        table.insert(Library.Instances, Icon)
        table.insert(Library.Instances, Content)
        table.insert(Library.Instances, Title)
        table.insert(Dropdowns, Content)

        local gradSeq = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(0.78,0.749,0.8)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}

        Holder.Name = "Holder"; Holder.Size=UDim2.new(1,0,0,34); Holder.BackgroundTransparency=1
        Frame.Position=UDim2.new(0,15,0,16); Frame.Size=UDim2.new(1,-30,0,15)
        Frame.BackgroundColor3=Color3.new(0.0784,0.0784,0.0784); Frame.BorderColor3=Color3.new(0,0,0)
        Frame.Text=""; Frame.AutoButtonColor=false
        Grad.Name="Gradient"; Grad.Color=gradSeq; Grad.Rotation=-90
        ValueL.Name="Value"; ValueL.Position=UDim2.new(0,2,0,0); ValueL.Size=UDim2.new(1,-10,1,0)
        ValueL.BackgroundTransparency=1; ValueL.Text=""; ValueL.TextColor3=Color3.new(0.3059,0.3059,0.3059)
        ValueL.FontFace=Library.UIFont; ValueL.TextSize=Library.FontSize; ValueL.ZIndex=105
        ValueL.TextXAlignment=Enum.TextXAlignment.Left; ValueL.ClipsDescendants=true
        Icon.Name="Icon"; Icon.Position=UDim2.new(0,-4,0,0); Icon.Size=UDim2.new(1,0,1,0)
        Icon.BackgroundTransparency=1; Icon.Text="-"; Icon.TextColor3=Color3.new(0.3059,0.3059,0.3059)
        Icon.FontFace=Library.UIFont; Icon.TextSize=Library.FontSize; Icon.ZIndex=105
        Icon.TextXAlignment=Enum.TextXAlignment.Right
        Content.Name="Content"; Content.Position=UDim2.new(0,0,0,18); Content.Size=UDim2.new(1,0,0,0)
        Content.BackgroundColor3=Color3.new(0.0784,0.0784,0.0784); Content.BorderColor3=Color3.new(0,0,0)
        Content.Visible=false; Content.ZIndex=110; Content.AutomaticSize=Enum.AutomaticSize.Y
        Grad2.Name="Gradient2"; Grad2.Color=gradSeq; Grad2.Rotation=-90
        ListL.SortOrder=Enum.SortOrder.LayoutOrder
        Title.Name="Title"; Title.Position=UDim2.new(0,15,0,0); Title.Size=UDim2.new(1,0,0,10)
        Title.BackgroundTransparency=1; Title.TextColor3=Color3.new(0.3059,0.3059,0.3059)
        Title.FontFace=Library.UIFont; Title.TextSize=Library.FontSize; Title.ZIndex=105
        Title.TextXAlignment=Enum.TextXAlignment.Left; Title.Text=Dropdown.Name or ""

        Library:Connection(Frame.MouseButton1Click, function() Content.Visible=not Content.Visible end)
        Library:Connection(UIS.InputBegan, function(i)
            if Content.Visible and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) then
                if not Library:IsMouseOverFrame(Content) and not Library:IsMouseOverFrame(Holder) then
                    Content.Visible=false
                end
            end
        end)

        local function handleclick(option, btn, txt)
            btn.MouseButton1Click:Connect(function()
                for opt, tbl in next, Dropdown.OptionInsts do
                    if opt ~= option then tbl.text.TextColor3=Color3.new(0.3059,0.3059,0.3059) end
                end
                ValueL.Text=option; txt.TextColor3=Color3.fromRGB(255,255,255)
                Library.Flags[Dropdown.Flag]=option; Dropdown.Callback(option)
            end)
        end

        local function createoptions(tbl)
            for _, opt in next, tbl do
                Dropdown.OptionInsts[opt]={}
                local Opt  = Instance.new("TextButton", Content)
                local OLbl = Instance.new("TextLabel",  Opt)
                Opt.Name="Option"; Opt.Size=UDim2.new(1,0,0,15); Opt.BackgroundTransparency=1
                Opt.BorderSizePixel=0; Opt.Text=""; Opt.AutoButtonColor=false
                Opt.Font=Enum.Font.SourceSans; Opt.TextSize=14; Opt.ZIndex=111
                Dropdown.OptionInsts[opt].button=Opt
                OLbl.Name="OptionName"; OLbl.Position=UDim2.new(0,2,0,0); OLbl.Size=UDim2.new(1,0,1,0)
                OLbl.BackgroundTransparency=1; OLbl.Text=opt
                OLbl.TextColor3=Color3.new(0.3059,0.3059,0.3059)
                OLbl.FontFace=Library.UIFont; OLbl.TextSize=Library.FontSize
                OLbl.TextXAlignment=Enum.TextXAlignment.Left; OLbl.ZIndex=111
                Dropdown.OptionInsts[opt].text=OLbl
                handleclick(opt, Opt, OLbl)
            end
        end
        createoptions(Dropdown.Options)

        function Dropdown:Set(option)
            for opt, tbl in next, Dropdown.OptionInsts do
                tbl.text.TextColor3=Color3.new(0.3059,0.3059,0.3059)
            end
            if table.find(Dropdown.Options, option) then
                ValueL.Text=option
                Dropdown.OptionInsts[option].text.TextColor3=Color3.fromRGB(255,255,255)
                Library.Flags[Dropdown.Flag]=option; Dropdown.Callback(option)
            else
                ValueL.Text=""; Library.Flags[Dropdown.Flag]=nil; Dropdown.Callback(nil)
            end
        end
        function Dropdown:Refresh(tbl)
            for _,opt in next, Dropdown.OptionInsts do pcall(function() opt.button:Destroy() end) end
            table.clear(Dropdown.OptionInsts)
            createoptions(tbl)
            Library.Flags[Dropdown.Flag]=nil; Dropdown.Callback(nil)
        end

        Flags[Dropdown.Flag]=Dropdown
        Dropdown:Set(Dropdown.State)
        return Dropdown
    end

    -- ── Keybind ─────────────────────────────────────────────────
    function Sections:Keybind(Options)
        local P = Options or {}
        local KB = {
            Section    = self,
            Name       = P.Name or P.name or "Keybind",
            Mode       = P.mode or P.Mode or "Toggle",
            Callback   = P.callback or P.Callback or function() end,
            Flag       = P.flag or P.Flag or Library.NextFlag(),
            Binding    = nil,
            Connection = nil,
        }
        local Key, State = nil, false
        local Cycle = KB.Mode=="Hold" and 1 or KB.Mode=="Toggle" and 2 or 3

        local side   = P.Side=="Right" and KB.Section.Elements.Right or KB.Section.Elements.Left
        local Holder = Instance.new("TextButton", side)
        local TitleL = Instance.new("TextLabel",  Holder)
        local ValueL = Instance.new("TextLabel",  Holder)
        local ModeL  = Instance.new("TextLabel",  Holder)
        table.insert(Library.Instances, TitleL)
        table.insert(Library.Instances, ValueL)
        table.insert(Library.Instances, ModeL)

        Holder.Name="Holder"; Holder.Size=UDim2.new(1,0,0,10); Holder.BackgroundTransparency=1
        Holder.Text=""; Holder.AutoButtonColor=false; Holder.Font=Enum.Font.SourceSans; Holder.TextSize=14
        TitleL.Name="Title"; TitleL.Position=UDim2.new(0,15,0,-1); TitleL.Size=UDim2.new(1,-30,1,0)
        TitleL.BackgroundTransparency=1; TitleL.TextColor3=Color3.new(0.3059,0.3059,0.3059)
        TitleL.FontFace=Library.UIFont; TitleL.TextSize=Library.FontSize; TitleL.ZIndex=105
        TitleL.TextXAlignment=Enum.TextXAlignment.Left; TitleL.Text=KB.Name
        ValueL.Name="Value"; ValueL.Position=UDim2.new(0,15,0,-1); ValueL.Size=UDim2.new(1,-30,1,0)
        ValueL.BackgroundTransparency=1; ValueL.Text="[-]"; ValueL.TextColor3=Color3.new(0.3059,0.3059,0.3059)
        ValueL.FontFace=Library.UIFont; ValueL.TextSize=Library.FontSize; ValueL.ZIndex=105
        ValueL.TextXAlignment=Enum.TextXAlignment.Right
        ModeL.Name="Mode"; ModeL.Position=UDim2.new(0,TitleL.TextBounds.X+20,0,-1); ModeL.Size=UDim2.new(1,-30,1,0)
        ModeL.BackgroundTransparency=1; ModeL.Text=KB.Mode=="Hold" and "[H]" or KB.Mode=="Toggle" and "[T]" or "[A]"
        ModeL.TextColor3=Color3.new(1,1,1); ModeL.FontFace=Library.UIFont; ModeL.TextSize=Library.FontSize
        ModeL.ZIndex=105; ModeL.TextXAlignment=Enum.TextXAlignment.Left

        local function set(newkey)
            if string.find(tostring(newkey),"Enum") then
                if KB.Connection then KB.Connection:Disconnect(); Library.Flags[KB.Flag]=false; KB.Callback(false) end
                if tostring(newkey):find("Enum.KeyCode.") then
                    newkey=Enum.KeyCode[tostring(newkey):gsub("Enum.KeyCode.","")]
                elseif tostring(newkey):find("Enum.UserInputType.") then
                    newkey=Enum.UserInputType[tostring(newkey):gsub("Enum.UserInputType.","")]
                end
                if newkey==Enum.KeyCode.Backspace then Key=nil; ValueL.Text="[-]"
                elseif newkey then
                    Key=newkey
                    ValueL.Text="[".. (Library.Keys[newkey] or tostring(newkey):gsub("Enum.KeyCode.","")) .."]"
                end
                Library.Flags[KB.Flag.."_KEY"]=newkey
            elseif table.find({"Always","Toggle","Hold"}, newkey) then
                KB.Mode=newkey
                ModeL.Text=KB.Mode=="Hold" and "[H]" or KB.Mode=="Toggle" and "[T]" or "[A]"
                Cycle=KB.Mode=="Hold" and 1 or KB.Mode=="Toggle" and 2 or 3
                if KB.Mode=="Always" then State=true; Library.Flags[KB.Flag]=true; KB.Callback(true) end
                Library.Flags[KB.Flag.."_KEY STATE"]=newkey
            else
                State=newkey; Library.Flags[KB.Flag]=newkey; KB.Callback(newkey)
            end
        end

        set(P.default or P.Default or P.state or P.State)
        set(KB.Mode)

        Holder.MouseButton1Click:Connect(function()
            if KB.Binding then return end
            ValueL.Text="[-]"
            KB.Binding=Library:Connection(UIS.InputBegan, function(i, gpe)
                set(i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode or i.UserInputType)
                Library:Disconnect(KB.Binding); task.wait(); KB.Binding=nil
            end)
        end)
        Library:Connection(UIS.InputBegan, function(i)
            if (i.KeyCode==Key or i.UserInputType==Key) and not KB.Binding then
                if KB.Mode=="Hold" then
                    Library.Flags[KB.Flag]=true
                    KB.Connection=Library:Connection(RS.RenderStepped, function() KB.Callback(true) end)
                elseif KB.Mode=="Toggle" then
                    State=not State; Library.Flags[KB.Flag]=State; KB.Callback(State)
                end
            end
        end)
        Library:Connection(UIS.InputEnded, function(i)
            if KB.Mode=="Hold" and (i.KeyCode==Key or i.UserInputType==Key) and KB.Connection then
                KB.Connection:Disconnect(); Library.Flags[KB.Flag]=false; KB.Callback(false)
            end
        end)
        Holder.MouseButton2Click:Connect(function()
            Cycle+=1; if Cycle>3 then Cycle=1 end
            set(Cycle==1 and "Hold" or Cycle==2 and "Toggle" or "Always")
        end)

        Library.Flags[KB.Flag.."_KEY"]=P.state; Library.Flags[KB.Flag.."_KEY STATE"]=KB.Mode
        Flags[KB.Flag]=set; Flags[KB.Flag.."_KEY"]=set; Flags[KB.Flag.."_KEY STATE"]=set
        function KB:Set(k) set(k) end
        task.defer(function() ModeL.Position=UDim2.new(0,TitleL.TextBounds.X+20,0,-1) end)
        return KB
    end

    -- ── Textbox ─────────────────────────────────────────────────
    function Sections:Textbox(Options)
        local P = Options or {}
        local Textbox = {
            Window      = self.Window,
            Page        = self.Page,
            Section     = self,
            Placeholder = P.placeholder or P.Placeholder or "",
            State       = P.default or P.Default or P.def or "",
            Callback    = P.callback or P.Callback or function() end,
            Flag        = P.flag or P.Flag or Library.NextFlag(),
        }

        local side      = P.Side=="Right" and Textbox.Section.Elements.Right or Textbox.Section.Elements.Left
        local Holder    = Instance.new("Frame",   side)
        local TextFrame = Instance.new("Frame",   Holder)
        local Grad      = Instance.new("UIGradient", TextFrame)
        local TBox      = Instance.new("TextBox", TextFrame)

        table.insert(Library.Instances, TextFrame)
        table.insert(Library.Instances, TBox)

        Holder.Name="Holder"; Holder.Size=UDim2.new(1,0,0,15); Holder.BackgroundTransparency=1
        TextFrame.Name="TextFrame"; TextFrame.Position=UDim2.new(0,15,0,0); TextFrame.Size=UDim2.new(1,-30,1,0)
        TextFrame.BackgroundColor3=Color3.new(0.0784,0.0784,0.0784); TextFrame.BorderColor3=Color3.new(0,0,0)
        Grad.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(0.78,0.749,0.8)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}
        Grad.Rotation=-90
        TBox.Size=UDim2.new(1,0,1,0); TBox.BackgroundTransparency=1; TBox.BorderSizePixel=0
        TBox.Text=Textbox.State; TBox.TextColor3=Color3.new(0.3059,0.3059,0.3059)
        TBox.FontFace=Library.UIFont; TBox.TextSize=Library.FontSize
        TBox.PlaceholderText=Textbox.Placeholder; TBox.PlaceholderColor3=Color3.new(0.3059,0.3059,0.3059)
        TBox.ClearTextOnFocus=false; TBox.TextWrapped=true

        TBox.FocusLost:Connect(function()
            Textbox.Callback(TBox.Text); Library.Flags[Textbox.Flag]=TBox.Text
        end)
        local function set(str) TBox.Text=str; Library.Flags[Textbox.Flag]=str; Textbox.Callback(str) end
        Flags[Textbox.Flag]=set
        return Textbox
    end

    -- ── Button ──────────────────────────────────────────────────
    function Sections:Button(Options)
        local P = Options or {}
        local Button = {
            Window   = self.Window,
            Page     = self.Page,
            Section  = self,
            Name     = P.Name or P.name or P.Title or "button",
            Callback = P.callback or P.Callback or function() end,
        }

        local side      = P.Side=="Right" and Button.Section.Elements.Right or Button.Section.Elements.Left
        local Holder    = Instance.new("Frame",      side)
        local TextFrame = Instance.new("Frame",      Holder)
        local Grad      = Instance.new("UIGradient", TextFrame)
        local TBtn      = Instance.new("TextButton", TextFrame)

        table.insert(Library.Instances, TextFrame)
        table.insert(Library.Instances, TBtn)

        Holder.Name="Holder"; Holder.Size=UDim2.new(1,0,0,15); Holder.BackgroundTransparency=1
        TextFrame.Name="TextFrame"; TextFrame.Position=UDim2.new(0,15,0,0); TextFrame.Size=UDim2.new(1,-30,1,0)
        TextFrame.BackgroundColor3=Color3.new(0.0784,0.0784,0.0784); TextFrame.BorderColor3=Color3.new(0,0,0)
        Grad.Color=ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(0.78,0.749,0.8)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}
        Grad.Rotation=-90
        TBtn.Name="textbutton"; TBtn.Size=UDim2.new(1,0,1,0); TBtn.BackgroundTransparency=1
        TBtn.BorderSizePixel=0; TBtn.Text=Button.Name
        TBtn.TextColor3=Color3.new(0.3059,0.3059,0.3059); TBtn.FontFace=Library.UIFont; TBtn.TextSize=Library.FontSize
        TBtn.MouseButton1Click:Connect(function() Button.Callback() end)
        TBtn.MouseButton1Down:Connect(function() TBtn.TextColor3=Color3.fromRGB(255,255,255) end)
        TBtn.MouseButton1Up:Connect(function()   TBtn.TextColor3=Color3.new(0.3059,0.3059,0.3059) end)

        return Button
    end

    -- ── Colorpicker (section-level) ─────────────────────────────
    function Sections:Colorpicker(Options)
        local P = Options or {}
        local CP = {
            Window   = self.Window,
            Page     = self.Page,
            Section  = self,
            Name     = P.Name or P.name or "Color",
            State    = P.default or P.Default or Color3.fromRGB(255,0,0),
            Alpha    = P.alpha or P.Alpha or 1,
            Callback = P.callback or P.Callback or function() end,
            Flag     = P.flag or P.Flag or Library.NextFlag(),
            Colorpickers = 0,
        }

        local side  = P.Side=="Right" and CP.Section.Elements.Right or CP.Section.Elements.Left
        local Color = Instance.new("TextButton", side)
        local TLbl  = Instance.new("TextLabel",  Color)
        table.insert(Library.Instances, TLbl)

        Color.Name="Color"; Color.Size=UDim2.new(1,0,0,10); Color.BackgroundTransparency=1
        Color.Text=""; Color.AutoButtonColor=false; Color.Font=Enum.Font.SourceSans; Color.TextSize=14
        TLbl.Position=UDim2.new(0,15,0,0); TLbl.Size=UDim2.new(1,0,1,0); TLbl.BackgroundTransparency=1
        TLbl.TextColor3=Color3.new(0.3059,0.3059,0.3059); TLbl.FontFace=Library.UIFont
        TLbl.TextSize=Library.FontSize; TLbl.ZIndex=105; TLbl.TextXAlignment=Enum.TextXAlignment.Left
        TLbl.Text=CP.Name

        CP.Colorpickers += 1
        local cp, _ = Library:NewPicker(CP.State, CP.Alpha, Color, CP.Colorpickers-1, CP.Flag, CP.Callback)
        function CP:Set(c) cp:Set(c) end
        return CP
    end

    -- ── Multibox ────────────────────────────────────────────────
    function Sections:Multibox(Options)
        local P = Options or {}
        local Dropdown = {
            Window      = self.Window,
            Page        = self.Page,
            Section     = self,
            Options     = P.options or P.Options or {"1","2","3"},
            State       = P.default or P.Default or nil,
            Max         = P.max or P.Max or 1,
            Callback    = P.callback or P.Callback or function() end,
            Flag        = P.flag or P.Flag or Library.NextFlag(),
            OptionInsts = {},
        }

        local side    = P.Side=="Right" and Dropdown.Section.Elements.Right or Dropdown.Section.Elements.Left
        local Holder  = Instance.new("Frame",      side)
        local Frame   = Instance.new("TextButton", Holder)
        local Grad    = Instance.new("UIGradient", Frame)
        local ValueL  = Instance.new("TextLabel",  Frame)
        local Icon    = Instance.new("TextLabel",  Frame)
        local Content = Instance.new("Frame",      Frame)
        local Grad2   = Instance.new("UIGradient", Content)
        local ListL   = Instance.new("UIListLayout",Content)
        local Title   = Instance.new("TextLabel",  Holder)

        table.insert(Library.Instances,Frame); table.insert(Library.Instances,ValueL)
        table.insert(Library.Instances,Icon);  table.insert(Library.Instances,Content)
        table.insert(Library.Instances,Title); table.insert(Dropdowns,Content)

        local gradSeq = ColorSequence.new{ColorSequenceKeypoint.new(0,Color3.new(0.78,0.749,0.8)),ColorSequenceKeypoint.new(1,Color3.new(1,1,1))}
        Holder.Name="Holder"; Holder.Size=UDim2.new(1,0,0,34); Holder.BackgroundTransparency=1
        Frame.Position=UDim2.new(0,15,0,16); Frame.Size=UDim2.new(1,-30,0,15)
        Frame.BackgroundColor3=Color3.new(0.0784,0.0784,0.0784); Frame.Text=""; Frame.AutoButtonColor=false
        Grad.Color=gradSeq; Grad.Rotation=-90
        ValueL.Name="Value"; ValueL.Position=UDim2.new(0,2,0,0); ValueL.Size=UDim2.new(1,-10,1,0)
        ValueL.BackgroundTransparency=1; ValueL.Text=""; ValueL.TextColor3=Color3.new(0.3059,0.3059,0.3059)
        ValueL.FontFace=Library.UIFont; ValueL.TextSize=Library.FontSize; ValueL.ZIndex=105
        ValueL.TextXAlignment=Enum.TextXAlignment.Left; ValueL.ClipsDescendants=true
        ValueL.TextTruncate=Enum.TextTruncate.SplitWord
        Icon.Name="Icon"; Icon.Position=UDim2.new(0,-4,0,0); Icon.Size=UDim2.new(1,0,1,0)
        Icon.BackgroundTransparency=1; Icon.Text="-"; Icon.TextColor3=Color3.new(0.3059,0.3059,0.3059)
        Icon.FontFace=Library.UIFont; Icon.TextSize=Library.FontSize; Icon.ZIndex=105
        Icon.TextXAlignment=Enum.TextXAlignment.Right
        Content.Name="Content"; Content.Position=UDim2.new(0,0,0,18); Content.Size=UDim2.new(1,0,0,0)
        Content.BackgroundColor3=Color3.new(0.0784,0.0784,0.0784); Content.Visible=false
        Content.ZIndex=110; Content.AutomaticSize=Enum.AutomaticSize.Y
        Grad2.Color=gradSeq; Grad2.Rotation=-90
        ListL.SortOrder=Enum.SortOrder.LayoutOrder
        Title.Name="Title"; Title.Position=UDim2.new(0,15,0,0); Title.Size=UDim2.new(1,0,0,10)
        Title.BackgroundTransparency=1; Title.TextColor3=Color3.new(0.3059,0.3059,0.3059)
        Title.FontFace=Library.UIFont; Title.TextSize=Library.FontSize; Title.ZIndex=105
        Title.TextXAlignment=Enum.TextXAlignment.Left; Title.Text=P.name or P.Name or ""

        Library:Connection(Frame.MouseButton1Click, function() Content.Visible=not Content.Visible end)
        Library:Connection(UIS.InputBegan, function(i)
            if Content.Visible and (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) then
                if not Library:IsMouseOverFrame(Content) and not Library:IsMouseOverFrame(Holder) then
                    Content.Visible=false
                end
            end
        end)

        local chosen = {}

        local function updateDisplay()
            local t={}; for _,v in next, chosen do table.insert(t,v) end
            ValueL.Text=#chosen==0 and "" or table.concat(t,", ")
        end

        local function handleclick(option, btn, txt)
            btn.MouseButton1Click:Connect(function()
                local idx=table.find(chosen,option)
                if idx then
                    table.remove(chosen,idx); txt.TextColor3=Color3.new(0.3059,0.3059,0.3059)
                else
                    if #chosen==Dropdown.Max then
                        Dropdown.OptionInsts[chosen[1]].text.TextColor3=Color3.new(0.3059,0.3059,0.3059)
                        table.remove(chosen,1)
                    end
                    table.insert(chosen,option); txt.TextColor3=Color3.fromRGB(255,255,255)
                end
                updateDisplay()
                Library.Flags[Dropdown.Flag]=chosen; Dropdown.Callback(chosen)
            end)
        end

        local function createoptions(tbl)
            for _, opt in next, tbl do
                Dropdown.OptionInsts[opt]={}
                local Opt=Instance.new("TextButton",Content); local OLbl=Instance.new("TextLabel",Opt)
                Opt.Name="Option"; Opt.Size=UDim2.new(1,0,0,15); Opt.BackgroundTransparency=1
                Opt.BorderSizePixel=0; Opt.Text=""; Opt.AutoButtonColor=false
                Opt.Font=Enum.Font.SourceSans; Opt.TextSize=14; Opt.ZIndex=111
                Dropdown.OptionInsts[opt].button=Opt
                OLbl.Position=UDim2.new(0,2,0,0); OLbl.Size=UDim2.new(1,0,1,0)
                OLbl.BackgroundTransparency=1; OLbl.Text=opt
                OLbl.TextColor3=Color3.new(0.3059,0.3059,0.3059); OLbl.FontFace=Library.UIFont
                OLbl.TextSize=Library.FontSize; OLbl.TextXAlignment=Enum.TextXAlignment.Left; OLbl.ZIndex=111
                Dropdown.OptionInsts[opt].text=OLbl
                handleclick(opt,Opt,OLbl)
            end
        end
        createoptions(Dropdown.Options)

        local function set(option)
            table.clear(chosen)
            for opt,tbl in next, Dropdown.OptionInsts do tbl.text.TextColor3=Color3.new(0.3059,0.3059,0.3059) end
            option=type(option)=="table" and option or {}
            for _,opt in next, option do
                if table.find(Dropdown.Options,opt) and #chosen<Dropdown.Max then
                    table.insert(chosen,opt); Dropdown.OptionInsts[opt].text.TextColor3=Color3.fromRGB(255,255,255)
                end
            end
            updateDisplay()
            Library.Flags[Dropdown.Flag]=chosen; Dropdown.Callback(chosen)
        end

        function Dropdown:Set(opt) set(opt) end
        function Dropdown:Refresh(tbl)
            for _,opt in next, Dropdown.OptionInsts do pcall(function() opt.button:Destroy() end) end
            table.clear(Dropdown.OptionInsts); createoptions(tbl)
            table.clear(chosen); Library.Flags[Dropdown.Flag]=chosen; Dropdown.Callback(chosen)
        end

        Flags[Dropdown.Flag]=set
        Dropdown:Set(Dropdown.State)
        return Dropdown
    end
end

return Library
