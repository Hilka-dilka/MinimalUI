--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║    ███╗   ███╗██╗███╗   ██╗██╗███╗   ███╗ █████╗ ██╗                       ║
║    ████╗ ████║██║████╗  ██║██║████╗ ████║██╔══██╗██║                       ║
║    ██╔████╔██║██║██╔██╗ ██║██║██╔████╔██║███████║██║                       ║
║    ██║╚██╔╝██║██║██║╚██╗██║██║██║╚██╔╝██║██╔══██║██║                       ║
║    ██║ ╚═╝ ██║██║██║ ╚████║██║██║ ╚═╝ ██║██║  ██║███████╗                  ║
║    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝                  ║
║                                                                              ║
║              Minimal  ·  UI                                                  ║
║              v2.0  —  by Hilka-dilka (Alargon's Scripts)                    ║
║                                                                              ║
║    Gradient: выбранный цвет → белый (всегда)                                ║
║    GitHub:   github.com/Hilka-dilka                                         ║
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║   ИСПОЛЬЗОВАНИЕ:                                                             ║
║                                                                              ║
║   local UI = loadstring(game:HttpGet("URL"))()                               ║
║                                                                              ║
║   local Window = UI:CreateWindow("My Hub")                                  ║
║   local Tab    = Window:CreateTab("⚔ Combat")                               ║
║   local Sec    = Tab:CreateSection("Settings")                              ║
║                                                                              ║
║   Sec:CreateToggle("Kill Aura", false, function(v) end)                     ║
║   Sec:CreateSlider("Speed", 0, 100, 16, function(v) end)                    ║
║   Sec:CreateButton("Teleport", function() end)                              ║
║   Sec:CreateTextBox("Player", "Username...", function(t) end)               ║
║   Sec:CreateColorPicker("Theme", Color3.fromRGB(124,58,237), function(c)   ║
║       Window:SetTheme(c)                                                    ║
║   end)                                                                      ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]

local MinimalUI = {}

-- ────────────────────────────────────────
-- Services
-- ────────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local Player           = Players.LocalPlayer

-- ────────────────────────────────────────
-- Config  (изменяется через SetTheme)
-- ────────────────────────────────────────
local Config = {
    MainColor      = Color3.fromRGB(13, 13, 22),
    SecondaryColor = Color3.fromRGB(22, 22, 36),
    AccentColor    = Color3.fromRGB(124, 58, 237),
    AccentColor2   = Color3.new(1, 1, 1),          -- ВСЕГДА белый → градиент = цвет→белый
    TextColor      = Color3.fromRGB(228, 228, 231),
    SubTextColor   = Color3.fromRGB(110, 110, 140),
    BorderColor    = Color3.fromRGB(40,  40,  60),
    OnAccentText   = Color3.fromRGB(255, 255, 255), -- текст поверх градиента
    Font           = Enum.Font.GothamSemibold,
    SubFont        = Enum.Font.Gotham,
    AnimSpeed      = 0.25,
}

-- ────────────────────────────────────────
-- Theme registries
-- ────────────────────────────────────────
local themedElements  = {}   -- { role, obj, prop }
local themedGradients = {}   -- UIGradient objects
local tabGradients    = {}   -- { grad, btn }
local titleGradRef    = nil  -- shimmer UIGradient on title

local function registerThemed(role, obj, prop)
    table.insert(themedElements, { role = role, obj = obj, prop = prop })
end
local function registerGradient(g)
    table.insert(themedGradients, g)
end

-- ════════════════════════════════════════════════════════════
-- SetTheme  —  меняет акцент везде; AccentColor2 ВСЕГДА белый
--              (для светлых цветов — тёмный контраст)
-- ════════════════════════════════════════════════════════════
function MinimalUI:SetTheme(color)
    Config.AccentColor = color

    -- Яркость для определения светлого/тёмного оттенка
    local lum = 0.299*color.R + 0.587*color.G + 0.114*color.B
    local isLight = lum > 0.60

    if isLight then
        -- Светлый цвет: AccentColor2 = тёмная версия того же оттенка
        local h2, s2, v2 = color:ToHSV()
        Config.AccentColor2 = Color3.fromHSV(h2, math.min(1, s2*1.5 + 0.15), math.max(0, v2*0.35))
    else
        -- Тёмный / насыщенный: градиент всегда цвет → БЕЛЫЙ
        Config.AccentColor2 = Color3.new(1, 1, 1)
    end

    local onAccentText = isLight
        and Color3.fromRGB(18, 18, 32)
        or  Color3.fromRGB(255, 255, 255)
    Config.OnAccentText = onAccentText

    local newSeq = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Config.AccentColor),
        ColorSequenceKeypoint.new(1, Config.AccentColor2),
    })

    -- Плоские элементы
    for _, e in pairs(themedElements) do
        if e.obj and e.obj.Parent then
            local target
            if     e.role == "accent2"   then target = Config.AccentColor2
            elseif e.role == "btn-text"  then target = onAccentText
            else                              target = Config.AccentColor
            end
            TweenService:Create(e.obj, TweenInfo.new(0.4), { [e.prop] = target }):Play()
        end
    end

    -- UIGradient — плавный lerp за 0.4 с (12 шагов)
    for _, g in pairs(themedGradients) do
        if g and g.Parent then
            task.spawn(function()
                local kp   = g.Color.Keypoints
                local oldC1 = kp[1].Value
                local oldC2 = kp[#kp].Value
                for i = 1, 12 do
                    local t = i / 12
                    if not (g and g.Parent) then return end
                    g.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, oldC1:Lerp(Config.AccentColor,  t)),
                        ColorSequenceKeypoint.new(1, oldC2:Lerp(Config.AccentColor2, t)),
                    })
                    task.wait(0.4 / 12)
                end
                if g and g.Parent then g.Color = newSeq end
            end)
        end
    end

    -- Кнопки вкладок: текст + включение/выключение градиента
    for _, tg in pairs(tabGradients) do
        if tg.grad and tg.btn and tg.btn.Parent then
            if tg.grad.Enabled then
                TweenService:Create(tg.btn, TweenInfo.new(0.4), { TextColor3 = onAccentText }):Play()
            else
                tg.btn.TextColor3 = Config.SubTextColor
            end
        end
    end

    -- Title shimmer gradient — плавный lerp
    if titleGradRef and titleGradRef.Parent then
        task.spawn(function()
            local kp     = titleGradRef.Color.Keypoints
            local oldC1  = kp[1].Value
            local oldC2  = kp[2].Value
            local oldMid = kp[3].Value
            local newC1  = Config.AccentColor
            local newC2  = Config.AccentColor2
            local newMid = Config.AccentColor2
            for i = 1, 12 do
                local t = i / 12
                if not (titleGradRef and titleGradRef.Parent) then return end
                titleGradRef.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0,    oldC1:Lerp(newC1,  t)),
                    ColorSequenceKeypoint.new(0.35, oldC2:Lerp(newC2,  t)),
                    ColorSequenceKeypoint.new(0.5,  oldMid:Lerp(newMid, t)),
                    ColorSequenceKeypoint.new(0.65, oldC2:Lerp(newC2,  t)),
                    ColorSequenceKeypoint.new(1,    oldC1:Lerp(newC1,  t)),
                })
                task.wait(0.4 / 12)
            end
        end)
    end
end

-- ────────────────────────────────────────
-- Helpers
-- ────────────────────────────────────────
local function tween(obj, props, dur)
    TweenService:Create(obj, TweenInfo.new(
        dur or Config.AnimSpeed,
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out
    ), props):Play()
end

local function create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then inst[k] = v end
    end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end

local function corner(parent, radius)
    return create("UICorner", { CornerRadius = radius or UDim.new(0, 8), Parent = parent })
end

local function stroke(parent, color, thick)
    return create("UIStroke", {
        Color        = color or Config.BorderColor,
        Thickness    = thick or 1,
        Transparency = 0.5,
        Parent       = parent,
    })
end

local function makeGradient(parent, rotation)
    local g = create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.AccentColor),
            ColorSequenceKeypoint.new(1, Config.AccentColor2),
        }),
        Rotation = rotation or 135,
        Parent   = parent,
    })
    registerGradient(g)
    return g
end

-- ────────────────────────────────────────
-- Smooth elastic drag  (lerp-based)
-- ────────────────────────────────────────
local function makeDraggable(frame, handle)
    local dragging  = false
    local dragInput
    local dragStart, startPos
    local targetX, targetY   = frame.Position.X.Offset, frame.Position.Y.Offset
    local currentX, currentY = targetX, targetY
    local LERP = 0.14

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = frame.Position
            targetX   = startPos.X.Offset
            targetY   = startPos.Y.Offset
            currentX  = targetX;  currentY = targetY
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragInput = inp
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if inp == dragInput and dragging then
            local d = inp.Position - dragStart
            targetX = startPos.X.Offset + d.X
            targetY = startPos.Y.Offset + d.Y
        end
    end)

    RunService.RenderStepped:Connect(function()
        if math.abs(targetX - currentX) > 0.1 or math.abs(targetY - currentY) > 0.1 then
            currentX = currentX + (targetX - currentX) * LERP
            currentY = currentY + (targetY - currentY) * LERP
            frame.Position = UDim2.new(
                startPos and startPos.X.Scale or 0.5, currentX,
                startPos and startPos.Y.Scale or 0.5, currentY
            )
        end
    end)
end

-- ════════════════════════════════════════════════════════════
--  WINDOW
-- ════════════════════════════════════════════════════════════
function MinimalUI:CreateWindow(title)
    local old = Player.PlayerGui:FindFirstChild("MinimalUI")
    if old then old:Destroy() end

    local GUI = create("ScreenGui", {
        Name              = "MinimalUI",
        Parent            = Player.PlayerGui,
        ZIndexBehavior    = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn      = false,
    })

    local Main = create("Frame", {
        Name             = "Main",
        Size             = UDim2.new(0, 600, 0, 420),
        Position         = UDim2.new(0.5, -300, 0.5, -210),
        BackgroundColor3 = Config.MainColor,
        BorderSizePixel  = 0,
        Parent           = GUI,
    })
    corner(Main, UDim.new(0, 14))

    -- Drop-shadow
    create("ImageLabel", {
        Size              = UDim2.new(1, 60, 1, 60),
        Position          = UDim2.new(0, -30, 0, -30),
        BackgroundTransparency = 1,
        Image             = "rbxassetid://5554236805",
        ImageColor3       = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.35,
        ScaleType         = Enum.ScaleType.Slice,
        SliceCenter       = Rect.new(23, 23, 277, 277),
        ZIndex            = 0,
        Parent            = Main,
    })

    -- ── Title bar ──────────────────────────────────────────
    local TitleBar = create("Frame", {
        Size                 = UDim2.new(1, 0, 0, 46),
        BackgroundTransparency = 1,
        Parent               = Main,
    })
    makeDraggable(Main, TitleBar)

    --  macOS dots
    local DotsFrame = create("Frame", {
        Size                 = UDim2.new(0, 62, 0, 14),
        Position             = UDim2.new(0, 14, 0.5, -7),
        BackgroundTransparency = 1,
        Parent               = TitleBar,
    })
    create("UIListLayout", {
        FillDirection       = Enum.FillDirection.Horizontal,
        Padding             = UDim.new(0, 7),
        VerticalAlignment   = Enum.VerticalAlignment.Center,
        Parent              = DotsFrame,
    })
    local function makeDot(color, order)
        local d = create("TextButton", {
            Size             = UDim2.new(0, 13, 0, 13),
            BackgroundColor3 = color,
            Text             = "",
            AutoButtonColor  = false,
            LayoutOrder      = order,
            Parent           = DotsFrame,
        })
        corner(d, UDim.new(1, 0))
        return d
    end
    local CloseDot = makeDot(Color3.fromRGB(255, 95,  87),  1)
    local MinDot   = makeDot(Color3.fromRGB(255, 189, 46),  2)
    local MaxDot   = makeDot(Color3.fromRGB(40,  200, 64),  3)

    CloseDot.MouseButton1Click:Connect(function()
        tween(Main, { Size = UDim2.new(0, 600, 0, 0) }, 0.3)
        task.wait(0.3); GUI:Destroy()
    end)
    local minimized = false
    MinDot.MouseButton1Click:Connect(function()
        minimized = not minimized
        tween(Main, { Size = minimized
            and UDim2.new(0, 600, 0, 46)
            or  UDim2.new(0, 600, 0, 420) }, 0.3)
    end)
    local maximized = false
    MaxDot.MouseButton1Click:Connect(function()
        maximized = not maximized
        if minimized then minimized = false end
        tween(Main, { Size = maximized
            and UDim2.new(0, 820, 0, 560)
            or  UDim2.new(0, 600, 0, 420) }, 0.35)
    end)

    --  Title label (центр, gradient shimmer)
    local TitleLabel = create("TextLabel", {
        Size                 = UDim2.new(1, 0, 1, 0),
        Position             = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text                 = title or "MinimalUI",
        TextColor3           = Config.AccentColor,
        TextSize             = 15,
        Font                 = Config.Font,
        TextXAlignment       = Enum.TextXAlignment.Center,
        Parent               = TitleBar,
    })
    local titleGrad = create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,    Config.AccentColor),
            ColorSequenceKeypoint.new(0.35, Config.AccentColor2),
            ColorSequenceKeypoint.new(0.5,  Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(0.65, Config.AccentColor2),
            ColorSequenceKeypoint.new(1,    Config.AccentColor),
        }),
        Parent = TitleLabel,
    })
    titleGradRef = titleGrad
    -- shimmer animation
    task.spawn(function()
        while TitleLabel.Parent do
            TweenService:Create(titleGrad,
                TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Offset = Vector2.new(1, 0) }
            ):Play()
            task.wait(2.2)
            TweenService:Create(titleGrad,
                TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                { Offset = Vector2.new(-1, 0) }
            ):Play()
            task.wait(2.2)
        end
    end)

    --  Divider под заголовком
    create("Frame", {
        Size             = UDim2.new(1, -24, 0, 1),
        Position         = UDim2.new(0, 12, 1, -1),
        BackgroundColor3 = Config.BorderColor,
        BackgroundTransparency = 0.55,
        BorderSizePixel  = 0,
        Parent           = TitleBar,
    })

    -- ── Body ───────────────────────────────────────────────
    local Body = create("Frame", {
        Size                 = UDim2.new(1, 0, 1, -46),
        Position             = UDim2.new(0, 0, 0, 46),
        BackgroundTransparency = 1,
        ClipsDescendants     = true,
        Parent               = Main,
    })

    -- Tab sidebar
    local TabBar = create("Frame", {
        Size             = UDim2.new(0, 148, 1, -14),
        Position         = UDim2.new(0, 8,  0, 7),
        BackgroundColor3 = Config.SecondaryColor,
        BackgroundTransparency = 0.25,
        Parent           = Body,
    })
    corner(TabBar, UDim.new(0, 10))
    create("UIListLayout", {
        Padding     = UDim.new(0, 4),
        SortOrder   = Enum.SortOrder.LayoutOrder,
        Parent      = TabBar,
    })
    create("UIPadding", {
        PaddingTop   = UDim.new(0, 7),
        PaddingLeft  = UDim.new(0, 7),
        PaddingRight = UDim.new(0, 7),
        Parent       = TabBar,
    })

    -- Content area
    local ContentBox = create("Frame", {
        Size                 = UDim2.new(1, -174, 1, -14),
        Position             = UDim2.new(0, 164, 0, 7),
        BackgroundTransparency = 1,
        Parent               = Body,
    })

    -- Toggle visibility key
    local toggleKey = Enum.KeyCode.RightControl
    local visible   = true
    UserInputService.InputBegan:Connect(function(inp, gpe)
        if not gpe and inp.KeyCode == toggleKey then
            visible = not visible
            GUI.Enabled = visible
        end
    end)

    -- ── Window object ──────────────────────────────────────
    local Window      = {}
    Window.Tabs       = {}
    Window.GUI        = GUI

    function Window:SetKey(key) toggleKey = key end
    function Window:SetTheme(color) MinimalUI:SetTheme(color) end

    -- ════════ SECTION header helper (shared centre alignment) ════════
    local function makeSectionHeader(parent, sectionName)
        --  центрированный заголовок секции с градиентом
        local wrap = create("Frame", {
            Size                 = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            Parent               = parent,
        })
        local lbl = create("TextLabel", {
            Size                 = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text                 = string.upper(sectionName),
            TextColor3           = Config.AccentColor,
            TextSize             = 11,
            Font                 = Config.Font,
            TextXAlignment       = Enum.TextXAlignment.Center,   -- ← центр
            Parent               = wrap,
        })
        registerGradient(create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Config.AccentColor),
                ColorSequenceKeypoint.new(1, Config.AccentColor2),
            }),
            Parent = lbl,
        }))
        registerThemed("accent", lbl, "TextColor3")

        -- разделитель
        create("Frame", {
            Size             = UDim2.new(1, 0, 0, 1),
            Position         = UDim2.new(0, 0, 1, -1),
            BackgroundColor3 = Config.BorderColor,
            BackgroundTransparency = 0.45,
            BorderSizePixel  = 0,
            Parent           = wrap,
        })
        return wrap
    end

    -- ════════════════════════════════════════════════════════
    --  TAB  (плавный fade-in / fade-out через Position + TextTransparency)
    -- ════════════════════════════════════════════════════════
    local tabSwitching = false
    local currentTab   = nil

    function Window:CreateTab(name)
        local Tab = { Sections = {} }

        -- Кнопка вкладки
        local TabBtn = create("TextButton", {
            Size                 = UDim2.new(1, 0, 0, 34),
            BackgroundColor3     = Config.AccentColor,
            BackgroundTransparency = 1,
            Text                 = name,
            TextColor3           = Config.SubTextColor,
            TextSize             = 13,
            Font                 = Config.SubFont,
            Parent               = TabBar,
        })
        corner(TabBtn, UDim.new(0, 8))

        -- Градиент вкладки (скрыт по умолчанию)
        local tabGrad = create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Config.AccentColor),
                ColorSequenceKeypoint.new(1, Config.AccentColor2),
            }),
            Rotation = 135,
            Enabled  = false,
            Parent   = TabBtn,
        })
        table.insert(tabGradients, { grad = tabGrad, btn = TabBtn })
        registerGradient(tabGrad)
        registerThemed("accent", TabBtn, "BackgroundColor3")

        -- Wrapper (обычный Frame → поддерживает Position tween)
        local Wrapper = create("Frame", {
            Size                 = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ClipsDescendants     = true,
            Visible              = false,
            Parent               = ContentBox,
        })

        -- ScrollingFrame внутри Wrapper
        local Content = create("ScrollingFrame", {
            Size                 = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness   = 3,
            ScrollBarImageColor3 = Config.AccentColor,
            BorderSizePixel      = 0,
            CanvasSize           = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize  = Enum.AutomaticSize.Y,
            Parent               = Wrapper,
        })
        registerThemed("accent", Content, "ScrollBarImageColor3")
        create("UIListLayout", {
            Padding   = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent    = Content,
        })
        create("UIPadding", {
            PaddingBottom = UDim.new(0, 8),
            Parent        = Content,
        })

        -- ── selectTab ──────────────────────────────────────
        local function selectTab()
            if tabSwitching or currentTab == Tab then return end
            tabSwitching = true

            -- Деактивируем все
            for _, t in pairs(Window.Tabs) do
                t.Btn.BackgroundTransparency = 1
                t.Btn.TextColor3 = Config.SubTextColor
                for _, tg in pairs(tabGradients) do
                    if tg.btn == t.Btn then tg.grad.Enabled = false end
                end
            end

            -- Активируем текущую
            TabBtn.BackgroundTransparency = 0
            TweenService:Create(TabBtn,
                TweenInfo.new(0.25), { TextColor3 = Config.OnAccentText }
            ):Play()
            tabGrad.Enabled = true

            -- Скрываем старую вкладку
            if currentTab and currentTab.Wrapper.Visible then
                local oldW = currentTab.Wrapper
                TweenService:Create(oldW,
                    TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    { Position = UDim2.new(0, 0, 0, -10) }
                ):Play()
                for _, child in ipairs(oldW:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") then
                        TweenService:Create(child, TweenInfo.new(0.12), { TextTransparency = 1 }):Play()
                    end
                end
                task.wait(0.16)
                oldW.Visible  = false
                oldW.Position = UDim2.new(0, 0, 0, 0)
                for _, child in ipairs(oldW:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") then
                        child.TextTransparency = 0
                    end
                end
            end

            -- Показываем новую вкладку
            Wrapper.Position = UDim2.new(0, 0, 0, 14)
            Wrapper.Visible  = true
            for _, child in ipairs(Wrapper:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    child.TextTransparency = 1
                end
            end
            TweenService:Create(Wrapper,
                TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                { Position = UDim2.new(0, 0, 0, 0) }
            ):Play()
            for _, child in ipairs(Wrapper:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    TweenService:Create(child,
                        TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                        { TextTransparency = 0 }
                    ):Play()
                end
            end
            task.wait(0.32)
            currentTab   = Tab
            tabSwitching = false
        end

        TabBtn.MouseButton1Click:Connect(selectTab)

        -- Первая вкладка открыта сразу
        if #Window.Tabs == 0 then
            Wrapper.Visible              = true
            TabBtn.BackgroundTransparency = 0
            TabBtn.TextColor3            = Config.OnAccentText
            tabGrad.Enabled              = true
            currentTab                   = Tab
        end

        Tab.Btn     = TabBtn
        Tab.Content = Content
        Tab.Wrapper = Wrapper

        -- ══════════════════════════════════════════════════
        --  SECTION
        -- ══════════════════════════════════════════════════
        function Tab:CreateSection(sectionName)
            local Section = {}

            local SFrame = create("Frame", {
                Size             = UDim2.new(1, -4, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundColor3 = Config.SecondaryColor,
                BackgroundTransparency = 0.25,
                Parent           = Content,
            })
            corner(SFrame, UDim.new(0, 10))
            stroke(SFrame, Config.BorderColor, 1)
            create("UIListLayout", {
                Padding   = UDim.new(0, 3),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent    = SFrame,
            })
            create("UIPadding", {
                PaddingTop    = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft   = UDim.new(0, 14),
                PaddingRight  = UDim.new(0, 14),
                Parent        = SFrame,
            })

            -- Центрированный заголовок секции с градиентом
            makeSectionHeader(SFrame, sectionName)

            -- ════════ TOGGLE ════════
            function Section:CreateToggle(text, default, callback)
                callback = callback or function() end
                local state = default or false
                local F = create("Frame", {
                    Size                 = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    Parent               = SFrame,
                })
                create("TextLabel", {
                    Size                 = UDim2.new(1, -52, 1, 0),
                    BackgroundTransparency = 1,
                    Text                 = text,
                    TextColor3           = Config.TextColor,
                    TextSize             = 13,
                    Font                 = Config.SubFont,
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    Parent               = F,
                })
                local BG = create("Frame", {
                    Size             = UDim2.new(0, 40, 0, 22),
                    Position         = UDim2.new(1, -40, 0.5, -11),
                    BackgroundColor3 = state and Config.AccentColor or Config.BorderColor,
                    Parent           = F,
                })
                corner(BG, UDim.new(1, 0))
                registerThemed("accent", BG, "BackgroundColor3")

                local Circle = create("Frame", {
                    Size             = UDim2.new(0, 17, 0, 17),
                    Position         = state
                        and UDim2.new(1, -19, 0.5, -8.5)
                        or  UDim2.new(0, 2,  0.5, -8.5),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Parent           = BG,
                })
                corner(Circle, UDim.new(1, 0))

                local Btn = create("TextButton", {
                    Size                 = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                 = "",
                    Parent               = F,
                })
                Btn.MouseButton1Click:Connect(function()
                    state = not state
                    tween(BG, { BackgroundColor3 = state and Config.AccentColor or Config.BorderColor })
                    tween(Circle, { Position = state
                        and UDim2.new(1, -19, 0.5, -8.5)
                        or  UDim2.new(0, 2,  0.5, -8.5) })
                    callback(state)
                end)

                local API = {}
                function API:Set(v)
                    state = v
                    tween(BG, { BackgroundColor3 = v and Config.AccentColor or Config.BorderColor })
                    tween(Circle, { Position = v
                        and UDim2.new(1, -19, 0.5, -8.5)
                        or  UDim2.new(0, 2,  0.5, -8.5) })
                    callback(v)
                end
                return API
            end

            -- ════════ SLIDER (smooth lerp + snap on release + spin arrows) ════════
            function Section:CreateSlider(text, min, max, default, callback)
                callback = callback or function() end
                local val = default or min
                local F = create("Frame", {
                    Size                 = UDim2.new(1, 0, 0, 52),
                    BackgroundTransparency = 1,
                    Parent               = SFrame,
                })

                -- Label (лево)
                create("TextLabel", {
                    Size                 = UDim2.new(1, -80, 0, 20),
                    BackgroundTransparency = 1,
                    Text                 = text,
                    TextColor3           = Config.TextColor,
                    TextSize             = 13,
                    Font                 = Config.SubFont,
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    Parent               = F,
                })

                -- ── Spin holder (value + arrows) ──────────────
                local SpinHolder = create("Frame", {
                    Size                 = UDim2.new(0, 74, 0, 22),
                    Position             = UDim2.new(1, -74, 0, -1),
                    BackgroundTransparency = 1,
                    Parent               = F,
                })

                local VBG = create("Frame", {
                    Size                 = UDim2.new(0, 54, 1, 0),
                    BackgroundColor3     = Config.MainColor,
                    BackgroundTransparency = 1,
                    Parent               = SpinHolder,
                })
                corner(VBG, UDim.new(0, 5))

                -- Градиент на VBG (переливающийся)
                local VGrad = create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Config.AccentColor),
                        ColorSequenceKeypoint.new(1, Config.AccentColor2),
                    }),
                    Parent = VBG,
                })
                registerGradient(VGrad)

                local VLabel = create("TextLabel", {
                    Size                 = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                 = tostring(val),
                    TextColor3           = Config.AccentColor,
                    TextSize             = 13,
                    Font                 = Config.Font,
                    TextXAlignment       = Enum.TextXAlignment.Center,
                    Parent               = VBG,
                })
                registerThemed("accent", VLabel, "TextColor3")

                local VInput = create("TextBox", {
                    Size                 = UDim2.new(1, -4, 1, 0),
                    Position             = UDim2.new(0, 2, 0, 0),
                    BackgroundTransparency = 1,
                    Text                 = "",
                    TextColor3           = Color3.new(1, 1, 1),
                    TextSize             = 13,
                    Font                 = Config.Font,
                    TextXAlignment       = Enum.TextXAlignment.Center,
                    Visible              = false,
                    ClearTextOnFocus     = true,
                    Parent               = VBG,
                })
                local VBtn = create("TextButton", {
                    Size                 = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                 = "",
                    Parent               = VBG,
                })

                -- Стрелки ▲ / ▼ (без фона, меняются с темой)
                local ArrowsFrame = create("Frame", {
                    Size                 = UDim2.new(0, 14, 1, 0),
                    Position             = UDim2.new(0, 56, 0, 0),
                    BackgroundTransparency = 1,
                    Parent               = SpinHolder,
                })
                local ArrowUp = create("TextButton", {
                    Size                 = UDim2.new(1, 0, 0.5, -1),
                    BackgroundTransparency = 1,
                    Text                 = "▲",
                    TextColor3           = Config.AccentColor,
                    TextSize             = 8,
                    Font                 = Config.Font,
                    Parent               = ArrowsFrame,
                })
                registerThemed("accent", ArrowUp, "TextColor3")

                local ArrowDown = create("TextButton", {
                    Size                 = UDim2.new(1, 0, 0.5, -1),
                    Position             = UDim2.new(0, 0, 0.5, 1),
                    BackgroundTransparency = 1,
                    Text                 = "▼",
                    TextColor3           = Config.AccentColor,
                    TextSize             = 8,
                    Font                 = Config.Font,
                    Parent               = ArrowsFrame,
                })
                registerThemed("accent", ArrowDown, "TextColor3")

                -- ── Track / Fill / Knob ───────────────────────
                local Track = create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 5),
                    Position         = UDim2.new(0, 0, 0, 34),
                    BackgroundColor3 = Config.BorderColor,
                    Parent           = F,
                })
                corner(Track, UDim.new(1, 0))

                local initPct = (val - min) / (max - min)

                local Fill = create("Frame", {
                    Size             = UDim2.new(initPct, 0, 1, 0),
                    BackgroundColor3 = Config.AccentColor,
                    Parent           = Track,
                })
                corner(Fill, UDim.new(1, 0))
                registerGradient(create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Config.AccentColor),
                        ColorSequenceKeypoint.new(1, Config.AccentColor2),
                    }),
                    Parent = Fill,
                }))
                registerThemed("accent", Fill, "BackgroundColor3")

                local Knob = create("Frame", {
                    Size             = UDim2.new(0, 14, 0, 14),
                    Position         = UDim2.new(initPct, -7, 0.5, -7),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    ZIndex           = 2,
                    Parent           = Track,
                })
                corner(Knob, UDim.new(1, 0))

                local SlideBtn = create("TextButton", {
                    Size                 = UDim2.new(1, 0, 0, 28),
                    Position             = UDim2.new(0, 0, 0, 24),
                    BackgroundTransparency = 1,
                    Text                 = "",
                    Parent               = F,
                })

                -- Ввод значения вручную
                VBtn.MouseButton1Click:Connect(function()
                    VLabel.Visible = false; VBtn.Visible = false
                    VInput.Visible = true
                    VInput.Text    = tostring(val)
                    VInput.TextColor3 = Color3.new(1, 1, 1)
                    tween(VBG, { BackgroundTransparency = 0 }, 0.15)
                    stroke(VBG, Config.AccentColor, 1)
                    VInput:CaptureFocus()
                end)

                VInput.FocusLost:Connect(function()
                    local num = tonumber(VInput.Text)
                    if num then
                        num = math.clamp(math.floor(num), min, max)
                        val = num
                        local p = (val - min) / (max - min)
                        local snap = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        TweenService:Create(Fill, snap, { Size = UDim2.new(p, 0, 1, 0) }):Play()
                        TweenService:Create(Knob, snap, { Position = UDim2.new(p, -7, 0.5, -7) }):Play()
                        callback(val)
                    end
                    VLabel.Visible = true; VBtn.Visible = true
                    VInput.Visible = false
                    VLabel.Text    = tostring(val)
                    tween(VBG, { BackgroundTransparency = 1 }, 0.15)
                    for _, c in pairs(VBG:GetChildren()) do
                        if c:IsA("UIStroke") then c:Destroy() end
                    end
                end)

                -- Стрелки +/- шаг
                local step = math.max(1, math.floor((max - min) / 100))
                local function applyVal(newVal)
                    val = math.clamp(newVal, min, max)
                    local p = (val - min) / (max - min)
                    VLabel.Text = tostring(val)
                    local snap = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    TweenService:Create(Fill, snap, { Size = UDim2.new(p, 0, 1, 0) }):Play()
                    TweenService:Create(Knob, snap, { Position = UDim2.new(p, -7, 0.5, -7) }):Play()
                    callback(val)
                end
                ArrowUp.MouseButton1Click:Connect(function()   applyVal(val + step) end)
                ArrowDown.MouseButton1Click:Connect(function() applyVal(val - step) end)

                -- Smooth lerp drag
                local sliding   = false
                local targetPct = initPct
                local currentPct = initPct
                local SLERP     = 0.18

                SlideBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        tween(Knob, { Size = UDim2.new(0, 18, 0, 18) }, 0.15)
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if sliding and (
                        inp.UserInputType == Enum.UserInputType.MouseButton1
                     or inp.UserInputType == Enum.UserInputType.Touch) then
                        sliding     = false
                        currentPct  = targetPct
                        local snap  = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        TweenService:Create(Fill, snap, { Size = UDim2.new(targetPct, 0, 1, 0) }):Play()
                        TweenService:Create(Knob, snap, { Position = UDim2.new(targetPct, -7, 0.5, -7) }):Play()
                        tween(Knob, { Size = UDim2.new(0, 14, 0, 14) }, 0.2)
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if sliding and (
                        inp.UserInputType == Enum.UserInputType.MouseMovement
                     or inp.UserInputType == Enum.UserInputType.Touch) then
                        targetPct = math.clamp(
                            (inp.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                    end
                end)
                RunService.RenderStepped:Connect(function()
                    if not sliding then return end
                    local diff = targetPct - currentPct
                    if math.abs(diff) > 0.001 then
                        currentPct = currentPct + diff * SLERP
                        Fill.Size  = UDim2.new(currentPct, 0, 1, 0)
                        Knob.Position = UDim2.new(currentPct, -7, 0.5, -7)
                        val = math.floor(min + (max - min) * currentPct)
                        VLabel.Text = tostring(val)
                        callback(val)
                    end
                end)

                local API = {}
                function API:Set(v)
                    val = math.clamp(v, min, max)
                    local p = (val - min) / (max - min)
                    targetPct  = p; currentPct = p
                    VLabel.Text = tostring(val)
                    tween(Fill, { Size = UDim2.new(p, 0, 1, 0) })
                    tween(Knob, { Position = UDim2.new(p, -7, 0.5, -7) })
                    callback(val)
                end
                return API
            end

            -- ════════ BUTTON (gradient BG + отдельный TextLabel) ════════
            function Section:CreateButton(text, callback)
                callback = callback or function() end
                local F = create("Frame", {
                    Size                 = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1,
                    Parent               = SFrame,
                })
                -- BG несёт градиент — UIGradient не трогает дочерние TextLabel
                local BG = create("Frame", {
                    Size             = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Config.AccentColor,
                    Parent           = F,
                })
                corner(BG, UDim.new(0, 8))
                local btnGrad = create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Config.AccentColor),
                        ColorSequenceKeypoint.new(1, Config.AccentColor2),
                    }),
                    Rotation = 135,
                    Parent   = BG,
                })
                registerGradient(btnGrad)
                registerThemed("accent", BG, "BackgroundColor3")

                -- Отдельный TextLabel (ZIndex 2) — цвет текста не зависит от UIGradient фрейма
                local BtnLbl = create("TextLabel", {
                    Size                 = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                 = text,
                    TextColor3           = Config.OnAccentText,
                    TextSize             = 13,
                    Font                 = Config.SubFont,
                    ZIndex               = 2,
                    Parent               = BG,
                })
                registerThemed("btn-text", BtnLbl, "TextColor3")

                -- Невидимая кнопка поверх всего (ZIndex 3)
                local B = create("TextButton", {
                    Size                 = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                 = "",
                    ZIndex               = 3,
                    Parent               = BG,
                })
                B.MouseButton1Click:Connect(function()
                    local h2, s2, v2 = Config.AccentColor:ToHSV()
                    local flash = Color3.fromHSV(h2, math.max(0, s2*0.5), math.min(1, v2*1.3))
                    tween(BG, { BackgroundColor3 = flash }, 0.1)
                    task.wait(0.1)
                    tween(BG, { BackgroundColor3 = Config.AccentColor }, 0.2)
                    callback()
                end)
            end

            -- ════════ TEXTBOX ════════
            function Section:CreateTextBox(text, placeholder, callback)
                callback = callback or function() end
                local F = create("Frame", {
                    Size                 = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    Parent               = SFrame,
                })
                create("TextLabel", {
                    Size                 = UDim2.new(0.42, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                 = text,
                    TextColor3           = Config.TextColor,
                    TextSize             = 13,
                    Font                 = Config.SubFont,
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    Parent               = F,
                })
                local BoxBG = create("Frame", {
                    Size             = UDim2.new(0.55, 0, 0, 28),
                    Position         = UDim2.new(0.45, 0, 0.5, -14),
                    BackgroundColor3 = Config.MainColor,
                    Parent           = F,
                })
                corner(BoxBG, UDim.new(0, 6))
                stroke(BoxBG, Config.BorderColor, 1)

                local Box = create("TextBox", {
                    Size                 = UDim2.new(1, -12, 1, 0),
                    Position             = UDim2.new(0, 6, 0, 0),
                    BackgroundTransparency = 1,
                    Text                 = "",
                    PlaceholderText      = placeholder or "...",
                    PlaceholderColor3    = Config.SubTextColor,
                    TextColor3           = Config.TextColor,
                    TextSize             = 12,
                    Font                 = Config.SubFont,
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    ClearTextOnFocus     = false,
                    Parent               = BoxBG,
                })
                Box.Focused:Connect(function()
                    tween(BoxBG, { BackgroundColor3 = Config.SecondaryColor }, 0.15)
                    stroke(BoxBG, Config.AccentColor, 1)
                end)
                Box.FocusLost:Connect(function(enter)
                    tween(BoxBG, { BackgroundColor3 = Config.MainColor }, 0.15)
                    for _, c in pairs(BoxBG:GetChildren()) do
                        if c:IsA("UIStroke") then c:Destroy() end
                    end
                    stroke(BoxBG, Config.BorderColor, 1)
                    if enter then callback(Box.Text) end
                end)

                local API = {}
                function API:Set(v) Box.Text = v; callback(v) end
                return API
            end

            -- ════════ COLOR PICKER (full HSV) ════════
            function Section:CreateColorPicker(text, default, callback)
                callback = callback or function() end
                local col  = default or Color3.fromRGB(255, 0, 0)
                local open = false
                local h, s, v = col:ToHSV()

                local F = create("Frame", {
                    Size                 = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    ClipsDescendants     = false,
                    Parent               = SFrame,
                })
                create("TextLabel", {
                    Size                 = UDim2.new(1, -42, 1, 0),
                    BackgroundTransparency = 1,
                    Text                 = text,
                    TextColor3           = Config.TextColor,
                    TextSize             = 13,
                    Font                 = Config.SubFont,
                    TextXAlignment       = Enum.TextXAlignment.Left,
                    Parent               = F,
                })
                local Preview = create("TextButton", {
                    Size             = UDim2.new(0, 28, 0, 20),
                    Position         = UDim2.new(1, -28, 0, 7),
                    BackgroundColor3 = col,
                    Text             = "",
                    Parent           = F,
                })
                corner(Preview, UDim.new(0, 5))
                stroke(Preview, Config.BorderColor, 1)

                local Panel = create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 0),
                    Position         = UDim2.new(0, 0, 0, 36),
                    BackgroundColor3 = Config.MainColor,
                    ClipsDescendants = true,
                    Parent           = F,
                })
                corner(Panel, UDim.new(0, 8))
                stroke(Panel, Config.BorderColor, 1)

                -- SV field
                local Field = create("ImageLabel", {
                    Size             = UDim2.new(1, -46, 0, 100),
                    Position         = UDim2.new(0, 8, 0, 8),
                    BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                    Image            = "rbxassetid://4155801252",
                    Parent           = Panel,
                })
                corner(Field, UDim.new(0, 4))
                local FieldBtn = create("TextButton", {
                    Size = UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", Parent=Field,
                })
                local SVDot = create("Frame", {
                    Size     = UDim2.new(0, 10, 0, 10),
                    Position = UDim2.new(s, -5, 1-v, -5),
                    BackgroundTransparency = 1,
                    Parent   = Field,
                })
                corner(SVDot, UDim.new(1, 0))
                stroke(SVDot, Color3.new(1,1,1), 2)

                -- Hue bar
                local HBar = create("Frame", {
                    Size     = UDim2.new(0, 20, 0, 100),
                    Position = UDim2.new(1, -30, 0, 8),
                    Parent   = Panel,
                })
                corner(HBar, UDim.new(0, 4))
                create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 0,   0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,   255, 0)),
                        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,   255, 255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,   0,   255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0,   255)),
                        ColorSequenceKeypoint.new(1,    Color3.fromRGB(255, 0,   0)),
                    }),
                    Rotation = 90,
                    Parent   = HBar,
                })
                local HBtn = create("TextButton", {
                    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", Parent=HBar,
                })
                local HCur = create("Frame", {
                    Size             = UDim2.new(1, 4, 0, 4),
                    Position         = UDim2.new(0, -2, h, -2),
                    BackgroundColor3 = Color3.new(1,1,1),
                    Parent           = HBar,
                })
                corner(HCur, UDim.new(1, 0))

                -- RGB inputs
                local RGBRow = create("Frame", {
                    Size     = UDim2.new(1, -16, 0, 22),
                    Position = UDim2.new(0, 8, 0, 114),
                    BackgroundTransparency = 1,
                    Parent   = Panel,
                })
                local function makeRGBInput(lbl, px, initVal)
                    local c = create("Frame", {
                        Size=UDim2.new(0.32,0,1,0), Position=UDim2.new(px,0,0,0),
                        BackgroundTransparency=1, Parent=RGBRow,
                    })
                    create("TextLabel", {
                        Size=UDim2.new(0,12,1,0), BackgroundTransparency=1, Text=lbl,
                        TextColor3=Config.SubTextColor, TextSize=10, Font=Config.Font, Parent=c,
                    })
                    local bg = create("Frame", {
                        Size=UDim2.new(1,-14,1,0), Position=UDim2.new(0,14,0,0),
                        BackgroundColor3=Config.SecondaryColor, Parent=c,
                    })
                    corner(bg, UDim.new(0,4))
                    local tb = create("TextBox", {
                        Size=UDim2.new(1,-4,1,0), Position=UDim2.new(0,2,0,0),
                        BackgroundTransparency=1, Text=tostring(initVal),
                        TextColor3=Config.TextColor, TextSize=10,
                        Font=Config.SubFont, Parent=bg,
                    })
                    return tb
                end
                local RI = makeRGBInput("R", 0,      math.floor(col.R*255))
                local GI = makeRGBInput("G", 0.34,   math.floor(col.G*255))
                local BI = makeRGBInput("B", 0.67,   math.floor(col.B*255))

                local function refresh()
                    col = Color3.fromHSV(h, s, v)
                    Preview.BackgroundColor3 = col
                    Field.BackgroundColor3   = Color3.fromHSV(h, 1, 1)
                    SVDot.Position = UDim2.new(s, -5, 1-v, -5)
                    HCur.Position  = UDim2.new(0, -2, h, -2)
                    RI.Text = tostring(math.floor(col.R*255))
                    GI.Text = tostring(math.floor(col.G*255))
                    BI.Text = tostring(math.floor(col.B*255))
                    callback(col)
                end

                local pickSV = false
                FieldBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then pickSV = true end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then pickSV = false end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if pickSV and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        s = math.clamp((inp.Position.X - Field.AbsolutePosition.X) / Field.AbsoluteSize.X, 0, 1)
                        v = 1 - math.clamp((inp.Position.Y - Field.AbsolutePosition.Y) / Field.AbsoluteSize.Y, 0, 1)
                        refresh()
                    end
                end)

                local pickH = false
                HBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then pickH = true end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then pickH = false end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if pickH and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        h = math.clamp((inp.Position.Y - HBar.AbsolutePosition.Y) / HBar.AbsoluteSize.Y, 0, 1)
                        refresh()
                    end
                end)

                for _, inp in pairs({ RI, GI, BI }) do
                    inp.FocusLost:Connect(function()
                        local rv = math.clamp(tonumber(RI.Text) or 0, 0, 255)
                        local gv = math.clamp(tonumber(GI.Text) or 0, 0, 255)
                        local bv = math.clamp(tonumber(BI.Text) or 0, 0, 255)
                        col = Color3.fromRGB(rv, gv, bv)
                        h, s, v = col:ToHSV()
                        refresh()
                    end)
                end

                Preview.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        tween(F,     { Size = UDim2.new(1, 0, 0, 188) })
                        tween(Panel, { Size = UDim2.new(1, 0, 0, 148) })
                    else
                        tween(F,     { Size = UDim2.new(1, 0, 0, 34) })
                        tween(Panel, { Size = UDim2.new(1, 0, 0, 0) })
                    end
                end)

                local API = {}
                function API:Set(c)
                    col = c; h, s, v = c:ToHSV(); refresh()
                end
                return API
            end

            return Section
        end -- CreateSection

        table.insert(Window.Tabs, Tab)
        return Tab
    end -- CreateTab

    return Window
end -- CreateWindow

return MinimalUI
