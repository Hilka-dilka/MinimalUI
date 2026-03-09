--[[
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   ███╗   ███╗██╗███╗   ██╗██╗███╗   ███╗ █████╗ ██╗         ║
║   ████╗ ████║██║████╗  ██║██║████╗ ████║██╔══██╗██║         ║
║   ██╔████╔██║██║██╔██╗ ██║██║██╔████╔██║███████║██║         ║
║   ██║╚██╔╝██║██║██║╚██╗██║██║██║╚██╔╝██║██╔══██║██║         ║
║   ██║ ╚═╝ ██║██║██║ ╚████║██║██║ ╚═╝ ██║██║  ██║███████╗   ║
║   ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ║
║                                                              ║
║                 Minimal  ·  UI  ·  v2.0                     ║
║            by Hilka-dilka (Alargon's Scripts)               ║
║                 © 2026  All rights reserved                  ║
║                                                              ║
║   Gradient rule: AccentColor → WHITE (always)               ║
║   Black → Black+White  |  Blue → Blue+White                 ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

  USAGE:
    local MinimalUI = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/Hilka-dilka/MinimalUI/main/MinimalUI.lua"
    ))()

    local Window  = MinimalUI:CreateWindow("My Hub")
    local CombTab = Window:CreateTab("⚔ Combat")
    local AuraSec = CombTab:CreateSection("Aura")

    AuraSec:CreateToggle("Kill Aura", false, function(v) print(v) end)
    AuraSec:CreateSlider("Reach", 5, 50, 15,  function(v) print(v) end)
    AuraSec:CreateButton("Reset",              function()  print("reset") end)
    AuraSec:CreateTextBox("Player","Username...",function(t) print(t) end)
    AuraSec:CreateColorPicker("Theme", Color3.fromRGB(124,58,237), function(c)
        Window:SetTheme(c)
    end)
]]

local MinimalUI = {}

-- ═══════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local Player           = Players.LocalPlayer

-- ═══════════════════════════════════════
-- CONFIG  (updated by SetTheme)
-- ═══════════════════════════════════════
local Config = {
    MainColor      = Color3.fromRGB(19,  19,  31),
    SecondaryColor = Color3.fromRGB(26,  26,  42),
    AccentColor    = Color3.fromRGB(124, 58,  237),
    AccentColor2   = Color3.new(1, 1, 1),   -- ALWAYS white for dark themes
    TextColor      = Color3.fromRGB(228, 228, 231),
    SubTextColor   = Color3.fromRGB(120, 120, 150),
    BorderColor    = Color3.fromRGB(40,  40,  60),
    OnAccentText   = Color3.fromRGB(255, 255, 255),
    Font           = Enum.Font.GothamSemibold,
    SubFont        = Enum.Font.Gotham,
    AnimSpeed      = 0.25,
}

-- ═══════════════════════════════════════
-- THEMED ELEMENT REGISTRY
-- ═══════════════════════════════════════
local themedElements  = {}   -- {role, obj, prop}
local themedGradients = {}   -- UIGradient objects (excluding title)
local tabGradients    = {}   -- {grad, btn} pairs

-- Title shimmer state — we manage it separately so SetTheme can pause it
local titleGradRef     = nil   -- the UIGradient on the title label
local titleShimmerStop = false -- set true to pause shimmer loop during recolour

local function registerThemed(role, obj, prop)
    table.insert(themedElements, {role=role, obj=obj, prop=prop})
end
local function registerGradient(g)
    table.insert(themedGradients, g)
end

-- ═══════════════════════════════════════
-- COLOUR MATH
-- ═══════════════════════════════════════
local function luminance(c)
    return 0.299*c.R + 0.587*c.G + 0.114*c.B
end

-- AccentColor2: dark accent → pure white | light accent → dark shade
local function buildAccent2(color)
    if luminance(color) > 0.60 then
        local h, s, v = color:ToHSV()
        return Color3.fromHSV(h, math.min(1, s*1.5+0.1), math.max(0, v*0.28))
    else
        return Color3.new(1, 1, 1)
    end
end

-- Text colour readable on AccentColor background
local function onAccent(color)
    return luminance(color) > 0.60
        and Color3.fromRGB(26, 26, 46)
        or  Color3.fromRGB(255, 255, 255)
end

-- Build the 5-keypoint shimmer ColorSequence for the title
local function titleSeq(accent, accent2)
    local mid = Color3.new(1, 1, 1)   -- always pure white at centre
    if luminance(accent) > 0.60 then
        -- light theme: use a dark shade at the centre instead
        local h, s, v = accent:ToHSV()
        mid = Color3.fromHSV(h, math.min(1,s*1.8), math.max(0,v*0.2))
    end
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0,    accent),
        ColorSequenceKeypoint.new(0.35, accent2),
        ColorSequenceKeypoint.new(0.50, mid),
        ColorSequenceKeypoint.new(0.65, accent2),
        ColorSequenceKeypoint.new(1,    accent),
    })
end

-- ═══════════════════════════════════════
-- SET THEME  (public, smooth 0.45 s)
-- ═══════════════════════════════════════
function MinimalUI:SetTheme(color)
    Config.AccentColor  = color
    Config.AccentColor2 = buildAccent2(color)
    Config.OnAccentText = onAccent(color)

    local accent  = Config.AccentColor
    local accent2 = Config.AccentColor2
    local onTxt   = Config.OnAccentText
    local STEPS   = 14
    local DUR     = 0.45

    local newSeq2 = ColorSequence.new({
        ColorSequenceKeypoint.new(0, accent),
        ColorSequenceKeypoint.new(1, accent2),
    })

    -- 1. Flat-colour elements
    for _, e in pairs(themedElements) do
        if e.obj and e.obj.Parent then
            local target
            if     e.role == "accent2"  then target = accent2
            elseif e.role == "btn-text" then target = onTxt
            else                             target = accent
            end
            TweenService:Create(e.obj, TweenInfo.new(DUR), { [e.prop] = target }):Play()
        end
    end

    -- 2. Non-title UIGradients — smooth lerp
    for _, g in pairs(themedGradients) do
        if g and g.Parent then
            task.spawn(function()
                local kp  = g.Color.Keypoints
                local c1s = kp[1].Value
                local c2s = kp[#kp].Value
                for i = 1, STEPS do
                    local t = i / STEPS
                    if g and g.Parent then
                        g.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, c1s:Lerp(accent,  t)),
                            ColorSequenceKeypoint.new(1, c2s:Lerp(accent2, t)),
                        })
                    end
                    task.wait(DUR / STEPS)
                end
                if g and g.Parent then g.Color = newSeq2 end
            end)
        end
    end

    -- 3. Tab button text colours
    for _, tg in pairs(tabGradients) do
        if tg.grad and tg.btn and tg.btn.Parent then
            if tg.grad.Enabled then
                TweenService:Create(tg.btn, TweenInfo.new(DUR), {
                    TextColor3 = onTxt
                }):Play()
            else
                tg.btn.TextColor3 = Config.SubTextColor
            end
        end
    end

    -- 4. Title gradient — pause shimmer, lerp colours, restart shimmer
    if titleGradRef and titleGradRef.Parent then
        task.spawn(function()
            -- Pause the shimmer ping-pong loop
            titleShimmerStop = true
            task.wait(0.05) -- give the loop one frame to notice

            local targetSeq = titleSeq(accent, accent2)
            local tKP       = targetSeq.Keypoints

            -- Read current keypoints
            local cur = titleGradRef.Color.Keypoints
            -- Ensure we have 5 keypoints to lerp (pad if needed)
            local function getKP(i)
                if cur[i] then return cur[i].Value end
                return cur[#cur].Value
            end
            local s0 = getKP(1)
            local s1 = getKP(2)
            local s2 = getKP(3)
            local s3 = getKP(4)
            local s4 = getKP(5)

            for i = 1, STEPS do
                local t = i / STEPS
                if titleGradRef and titleGradRef.Parent then
                    titleGradRef.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0,    s0:Lerp(tKP[1].Value, t)),
                        ColorSequenceKeypoint.new(0.35, s1:Lerp(tKP[2].Value, t)),
                        ColorSequenceKeypoint.new(0.50, s2:Lerp(tKP[3].Value, t)),
                        ColorSequenceKeypoint.new(0.65, s3:Lerp(tKP[4].Value, t)),
                        ColorSequenceKeypoint.new(1,    s4:Lerp(tKP[5].Value, t)),
                    })
                end
                task.wait(DUR / STEPS)
            end
            if titleGradRef and titleGradRef.Parent then
                titleGradRef.Color = targetSeq
            end

            -- Resume shimmer
            titleShimmerStop = false
        end)
    end
end

-- ═══════════════════════════════════════
-- UTILITIES
-- ═══════════════════════════════════════
local function tween(obj, props, dur, style, dir)
    TweenService:Create(obj, TweenInfo.new(
        dur   or Config.AnimSpeed,
        style or Enum.EasingStyle.Quart,
        dir   or Enum.EasingDirection.Out
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

-- Creates a 2-stop UIGradient (accent→white) and registers it for SetTheme
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

-- ═══════════════════════════════════════
-- SMOOTH ELASTIC DRAG
-- ═══════════════════════════════════════
local function makeDraggable(frame, handle)
    local dragging  = false
    local dragInput, dragStart, startPos
    local targetX, targetY   = 0, 0
    local currentX, currentY = 0, 0
    local lerpSpeed   = 0.14
    local initialized = false

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
            if not initialized then
                targetX  = startPos.X.Offset
                targetY  = startPos.Y.Offset
                currentX = targetX
                currentY = targetY
                initialized = true
            end
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            targetX = startPos.X.Offset + delta.X
            targetY = startPos.Y.Offset + delta.Y
        end
    end)

    RunService.RenderStepped:Connect(function()
        if not initialized then return end
        local dx = targetX - currentX
        local dy = targetY - currentY
        if math.abs(dx) > 0.1 or math.abs(dy) > 0.1 then
            currentX = currentX + dx * lerpSpeed
            currentY = currentY + dy * lerpSpeed
            frame.Position = UDim2.new(
                startPos.X.Scale, currentX,
                startPos.Y.Scale, currentY
            )
        end
    end)
end

-- ═══════════════════════════════════════
-- CREATE WINDOW
-- ═══════════════════════════════════════
function MinimalUI:CreateWindow(title)
    local old = Player.PlayerGui:FindFirstChild("MinimalUI")
    if old then old:Destroy() end

    local GUI = create("ScreenGui", {
        Name           = "MinimalUI",
        Parent         = Player.PlayerGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn   = false,
    })

    local Main = create("Frame", {
        Name             = "Main",
        Size             = UDim2.new(0, 580, 0, 400),
        Position         = UDim2.new(0.5, -290, 0.5, -200),
        BackgroundColor3 = Config.MainColor,
        Parent           = GUI,
    })
    corner(Main, UDim.new(0, 12))

    -- Drop shadow
    create("ImageLabel", {
        Size              = UDim2.new(1, 40, 1, 40),
        Position          = UDim2.new(0, -20, 0, -20),
        BackgroundTransparency = 1,
        Image             = "rbxassetid://5554236805",
        ImageColor3       = Color3.new(0, 0, 0),
        ImageTransparency = 0.45,
        ScaleType         = Enum.ScaleType.Slice,
        SliceCenter       = Rect.new(23, 23, 277, 277),
        ZIndex            = 0,
        Parent            = Main,
    })

    -- ────────── TITLE BAR ──────────
    local TitleBar = create("Frame", {
        Size                   = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Parent                 = Main,
    })
    makeDraggable(Main, TitleBar)

    -- Separator line
    create("Frame", {
        Size             = UDim2.new(1, -24, 0, 1),
        Position         = UDim2.new(0, 12, 1, -1),
        BackgroundColor3 = Config.BorderColor,
        BackgroundTransparency = 0.6,
        BorderSizePixel  = 0,
        Parent           = TitleBar,
    })

    -- Title label — centred, gradient shimmer applied via UIGradient offset animation
    local TitleLabel = create("TextLabel", {
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = title or "MinimalUI",
        TextColor3             = Config.TextColor,
        TextSize               = 15,
        Font                   = Config.Font,
        TextXAlignment         = Enum.TextXAlignment.Center,
        Parent                 = TitleBar,
    })

    -- Title UIGradient — 5 keypoints: accent → accent2 → white → accent2 → accent
    local initTitleSeq = titleSeq(Config.AccentColor, Config.AccentColor2)
    local titleGrad = create("UIGradient", {
        Color  = initTitleSeq,
        Parent = TitleLabel,
    })
    titleGradRef = titleGrad  -- store module-level reference for SetTheme

    -- Shimmer ping-pong loop (pauses when SetTheme is running)
    task.spawn(function()
        while TitleLabel.Parent do
            if not titleShimmerStop then
                TweenService:Create(titleGrad,
                    TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    { Offset = Vector2.new(0.8, 0) }
                ):Play()
                task.wait(2.2)
            else
                task.wait(0.05)
            end
            if not titleShimmerStop then
                TweenService:Create(titleGrad,
                    TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    { Offset = Vector2.new(-0.8, 0) }
                ):Play()
                task.wait(2.2)
            else
                task.wait(0.05)
            end
        end
    end)

    -- ────────── macOS TRAFFIC LIGHTS ──────────
    local DotsFrame = create("Frame", {
        Size                   = UDim2.new(0, 60, 0, 14),
        Position               = UDim2.new(0, 14, 0.5, -7),
        BackgroundTransparency = 1,
        Parent                 = TitleBar,
    })
    create("UIListLayout", {
        FillDirection     = Enum.FillDirection.Horizontal,
        Padding           = UDim.new(0, 7),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent            = DotsFrame,
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

    local CloseDot = makeDot(Color3.fromRGB(255, 95,  87), 1)
    local MinDot   = makeDot(Color3.fromRGB(255, 189, 46), 2)
    local MaxDot   = makeDot(Color3.fromRGB(40,  200, 64), 3)

    CloseDot.MouseButton1Click:Connect(function()
        tween(Main, { Size = UDim2.new(0, 580, 0, 0) }, 0.3)
        task.wait(0.32); GUI:Destroy()
    end)

    local minimized = false
    MinDot.MouseButton1Click:Connect(function()
        minimized = not minimized
        tween(Main, {
            Size = minimized and UDim2.new(0,580,0,44) or UDim2.new(0,580,0,400)
        }, 0.3)
    end)

    local maximized = false
    MaxDot.MouseButton1Click:Connect(function()
        maximized = not maximized
        if minimized then minimized = false end
        tween(Main, {
            Size = maximized and UDim2.new(0,800,0,550) or UDim2.new(0,580,0,400)
        }, 0.35)
    end)

    -- ────────── BODY ──────────
    local Body = create("Frame", {
        Size                   = UDim2.new(1, 0, 1, -44),
        Position               = UDim2.new(0, 0, 0, 44),
        BackgroundTransparency = 1,
        ClipsDescendants       = true,
        Parent                 = Main,
    })

    local TabBar = create("Frame", {
        Size             = UDim2.new(0, 140, 1, -12),
        Position         = UDim2.new(0, 8, 0, 6),
        BackgroundColor3 = Config.SecondaryColor,
        BackgroundTransparency = 0.3,
        Parent           = Body,
    })
    corner(TabBar)
    create("UIListLayout", {
        Padding   = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent    = TabBar,
    })
    create("UIPadding", {
        PaddingTop   = UDim.new(0, 6),
        PaddingLeft  = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent       = TabBar,
    })

    local ContentBox = create("Frame", {
        Size                   = UDim2.new(1, -164, 1, -12),
        Position               = UDim2.new(0, 156, 0, 6),
        BackgroundTransparency = 1,
        Parent                 = Body,
    })

    -- Toggle visibility
    local toggleKey = Enum.KeyCode.RightControl
    local visible   = true
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == toggleKey then
            visible = not visible
            GUI.Enabled = visible
        end
    end)

    -- ────────── WINDOW OBJECT ──────────
    local Window = { Tabs = {}, GUI = GUI }
    function Window:SetKey(key)  toggleKey = key end
    function Window:SetTheme(c)  MinimalUI:SetTheme(c) end

    -- ────────── TAB SWITCHING ──────────
    local tabSwitching = false
    local currentTab   = nil

    function Window:CreateTab(name)
        local Tab = { Sections = {} }

        local TabBtn = create("TextButton", {
            Size                   = UDim2.new(1, 0, 0, 32),
            BackgroundColor3       = Config.AccentColor,
            BackgroundTransparency = 1,
            Text                   = name,
            TextColor3             = Config.SubTextColor,
            TextSize               = 13,
            Font                   = Config.SubFont,
            Parent                 = TabBar,
        })
        corner(TabBtn, UDim.new(0, 7))

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

        local Wrapper = create("Frame", {
            Size                   = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ClipsDescendants       = true,
            Visible                = false,
            Parent                 = ContentBox,
        })

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
            PaddingTop    = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft   = UDim.new(0, 4),
            PaddingRight  = UDim.new(0, 4),
            Parent        = Content,
        })

        local function selectTab()
            if tabSwitching or currentTab == Tab then return end
            tabSwitching = true

            for _, t in pairs(Window.Tabs) do
                t.Btn.BackgroundTransparency = 1
                t.Btn.TextColor3 = Config.SubTextColor
                for _, tg in pairs(tabGradients) do
                    if tg.btn == t.Btn then tg.grad.Enabled = false end
                end
            end

            TabBtn.BackgroundTransparency = 0
            tabGrad.Enabled = true
            TweenService:Create(TabBtn, TweenInfo.new(0.25), {
                TextColor3 = Config.OnAccentText
            }):Play()

            if currentTab and currentTab.Wrapper.Visible then
                local oldW = currentTab.Wrapper
                TweenService:Create(oldW,
                    TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    { Position = UDim2.new(0, 0, 0, -8) }
                ):Play()
                for _, child in ipairs(oldW:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") then
                        TweenService:Create(child, TweenInfo.new(0.12),
                            { TextTransparency = 1 }):Play()
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

            Wrapper.Position = UDim2.new(0, 0, 0, 12)
            Wrapper.Visible  = true
            for _, child in ipairs(Wrapper:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    child.TextTransparency = 1
                end
            end
            TweenService:Create(Wrapper,
                TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                { Position = UDim2.new(0, 0, 0, 0) }
            ):Play()
            for _, child in ipairs(Wrapper:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    TweenService:Create(child,
                        TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                        { TextTransparency = 0 }):Play()
                end
            end
            task.wait(0.32)
            currentTab   = Tab
            tabSwitching = false
        end

        TabBtn.MouseButton1Click:Connect(selectTab)

        if #Window.Tabs == 0 then
            Wrapper.Visible               = true
            TabBtn.BackgroundTransparency = 0
            TabBtn.TextColor3             = Config.OnAccentText
            tabGrad.Enabled               = true
            currentTab                    = Tab
        end

        Tab.Btn     = TabBtn
        Tab.Content = Content
        Tab.Wrapper = Wrapper

        -- ══════════════════════════════════════════
        -- CREATE SECTION
        -- ══════════════════════════════════════════
        function Tab:CreateSection(sectionName)
            local Section = {}

            local SFrame = create("Frame", {
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BackgroundColor3 = Config.SecondaryColor,
                BackgroundTransparency = 0.3,
                Parent           = Content,
            })
            corner(SFrame, UDim.new(0, 10))
            stroke(SFrame, Config.BorderColor, 1)
            create("UIListLayout", {
                Padding   = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent    = SFrame,
            })
            create("UIPadding", {
                PaddingTop    = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft   = UDim.new(0, 14),
                PaddingRight  = UDim.new(0, 14),
                Parent        = SFrame,
            })

            -- Section header: centred, gradient, separator
            local STitle = create("TextLabel", {
                Size                   = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text                   = string.upper(sectionName),
                TextColor3             = Config.AccentColor,
                TextSize               = 11,
                Font                   = Config.Font,
                TextXAlignment         = Enum.TextXAlignment.Center,
                Parent                 = SFrame,
            })
            makeGradient(STitle, 90)
            registerThemed("accent", STitle, "TextColor3")

            create("Frame", {
                Size             = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Config.BorderColor,
                BackgroundTransparency = 0.5,
                BorderSizePixel  = 0,
                Parent           = SFrame,
            })

            -- ────────── TOGGLE ──────────
            function Section:CreateToggle(text, default, callback)
                callback = callback or function() end
                local state = default or false

                local F = create("Frame", {
                    Size                   = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    Parent                 = SFrame,
                })
                create("TextLabel", {
                    Size                   = UDim2.new(1, -50, 1, 0),
                    BackgroundTransparency = 1,
                    Text                   = text,
                    TextColor3             = Config.TextColor,
                    TextSize               = 13,
                    Font                   = Config.SubFont,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    Parent                 = F,
                })

                local BG = create("Frame", {
                    Size             = UDim2.new(0, 38, 0, 20),
                    Position         = UDim2.new(1, -38, 0.5, -10),
                    BackgroundColor3 = state and Config.AccentColor or Config.BorderColor,
                    Parent           = F,
                })
                corner(BG, UDim.new(1, 0))
                registerThemed("accent", BG, "BackgroundColor3")

                local Circle = create("Frame", {
                    Size             = UDim2.new(0, 16, 0, 16),
                    Position         = state
                        and UDim2.new(1, -18, 0.5, -8)
                        or  UDim2.new(0,   2, 0.5, -8),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Parent           = BG,
                })
                corner(Circle, UDim.new(1, 0))

                local Btn = create("TextButton", {
                    Size                   = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                   = "",
                    Parent                 = F,
                })
                Btn.MouseButton1Click:Connect(function()
                    state = not state
                    tween(BG, { BackgroundColor3 = state and Config.AccentColor or Config.BorderColor })
                    tween(Circle, { Position = state
                        and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8) })
                    callback(state)
                end)

                local API = {}
                function API:Set(v)
                    state = v
                    tween(BG, { BackgroundColor3 = v and Config.AccentColor or Config.BorderColor })
                    tween(Circle, { Position = v
                        and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8) })
                    callback(v)
                end
                return API
            end

            -- ────────── SLIDER (elastic lerp) ──────────
            function Section:CreateSlider(text, min, max, default, callback)
                callback = callback or function() end
                local val        = math.clamp(default or min, min, max)
                local targetPct  = (val - min) / (max - min)
                local currentPct = targetPct

                local F = create("Frame", {
                    Size                   = UDim2.new(1, 0, 0, 52),
                    BackgroundTransparency = 1,
                    Parent                 = SFrame,
                })

                create("TextLabel", {
                    Size                   = UDim2.new(1, -80, 0, 18),
                    BackgroundTransparency = 1,
                    Text                   = text,
                    TextColor3             = Config.TextColor,
                    TextSize               = 13,
                    Font                   = Config.SubFont,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    Parent                 = F,
                })

                local SpinHolder = create("Frame", {
                    Size                   = UDim2.new(0, 72, 0, 20),
                    Position               = UDim2.new(1, -72, 0, -1),
                    BackgroundTransparency = 1,
                    Parent                 = F,
                })

                local VBG = create("Frame", {
                    Size                   = UDim2.new(0, 50, 1, 0),
                    BackgroundColor3       = Config.MainColor,
                    BackgroundTransparency = 1,
                    Parent                 = SpinHolder,
                })
                corner(VBG, UDim.new(0, 5))
                makeGradient(VBG, 90)

                local VLabel = create("TextLabel", {
                    Size                   = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                   = tostring(val),
                    TextColor3             = Config.AccentColor,
                    TextSize               = 13,
                    Font                   = Config.Font,
                    TextXAlignment         = Enum.TextXAlignment.Center,
                    Parent                 = VBG,
                })
                registerThemed("accent", VLabel, "TextColor3")

                local VInput = create("TextBox", {
                    Size                   = UDim2.new(1, -4, 1, 0),
                    Position               = UDim2.new(0, 2, 0, 0),
                    BackgroundTransparency = 1,
                    Text                   = "",
                    TextColor3             = Config.TextColor,
                    TextSize               = 13,
                    Font                   = Config.Font,
                    TextXAlignment         = Enum.TextXAlignment.Center,
                    Visible                = false,
                    ClearTextOnFocus       = true,
                    Parent                 = VBG,
                })

                local VBtn = create("TextButton", {
                    Size                   = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                   = "",
                    Parent                 = VBG,
                })

                -- Spin arrows ▲ / ▼
                local ArrowsFrame = create("Frame", {
                    Size                   = UDim2.new(0, 14, 1, 0),
                    Position               = UDim2.new(0, 52, 0, 0),
                    BackgroundTransparency = 1,
                    Parent                 = SpinHolder,
                })
                local ArrowUp = create("TextButton", {
                    Size                   = UDim2.new(1, 0, 0.5, -1),
                    BackgroundTransparency = 1,
                    Text                   = "▲",
                    TextColor3             = Config.AccentColor,
                    TextSize               = 8,
                    Font                   = Config.Font,
                    Parent                 = ArrowsFrame,
                })
                registerThemed("accent", ArrowUp, "TextColor3")

                local ArrowDown = create("TextButton", {
                    Size                   = UDim2.new(1, 0, 0.5, -1),
                    Position               = UDim2.new(0, 0, 0.5, 1),
                    BackgroundTransparency = 1,
                    Text                   = "▼",
                    TextColor3             = Config.AccentColor,
                    TextSize               = 8,
                    Font                   = Config.Font,
                    Parent                 = ArrowsFrame,
                })
                registerThemed("accent", ArrowDown, "TextColor3")

                local Track = create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 5),
                    Position         = UDim2.new(0, 0, 0, 30),
                    BackgroundColor3 = Config.BorderColor,
                    Parent           = F,
                })
                corner(Track, UDim.new(1, 0))

                local Fill = create("Frame", {
                    Size             = UDim2.new(targetPct, 0, 1, 0),
                    BackgroundColor3 = Config.AccentColor,
                    Parent           = Track,
                })
                corner(Fill, UDim.new(1, 0))
                makeGradient(Fill, 90)
                registerThemed("accent", Fill, "BackgroundColor3")

                local Knob = create("Frame", {
                    Size             = UDim2.new(0, 14, 0, 14),
                    Position         = UDim2.new(targetPct, -7, 0.5, -7),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    ZIndex           = 2,
                    Parent           = Track,
                })
                corner(Knob, UDim.new(1, 0))

                local SlideBtn = create("TextButton", {
                    Size                   = UDim2.new(1, 0, 0, 24),
                    Position               = UDim2.new(0, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text                   = "",
                    Parent                 = F,
                })

                local step = math.max(1, math.floor((max - min) / 100))

                VBtn.MouseButton1Click:Connect(function()
                    VLabel.Visible = false
                    VBtn.Visible   = false
                    VInput.Visible = true
                    VInput.Text    = tostring(val)
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
                        targetPct = p; currentPct = p
                        local snap = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        TweenService:Create(Fill, snap, { Size     = UDim2.new(p, 0, 1, 0) }):Play()
                        TweenService:Create(Knob, snap, { Position = UDim2.new(p, -7, 0.5, -7) }):Play()
                        callback(val)
                    end
                    VLabel.Text    = tostring(val)
                    VLabel.Visible = true
                    VBtn.Visible   = true
                    VInput.Visible = false
                    tween(VBG, { BackgroundTransparency = 1 }, 0.15)
                    for _, c in ipairs(VBG:GetChildren()) do
                        if c:IsA("UIStroke") then c:Destroy() end
                    end
                end)

                local function applyVal()
                    local p = (val - min) / (max - min)
                    targetPct = p; currentPct = p
                    VLabel.Text = tostring(val)
                    local snap = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    TweenService:Create(Fill, snap, { Size     = UDim2.new(p, 0, 1, 0) }):Play()
                    TweenService:Create(Knob, snap, { Position = UDim2.new(p, -7, 0.5, -7) }):Play()
                    callback(val)
                end

                ArrowUp.MouseButton1Click:Connect(function()
                    val = math.clamp(val + step, min, max); applyVal()
                end)
                ArrowDown.MouseButton1Click:Connect(function()
                    val = math.clamp(val - step, min, max); applyVal()
                end)

                local sliding    = false
                local sliderLerp = 0.18

                SlideBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        tween(Knob, { Size = UDim2.new(0,18,0,18) }, 0.15)
                    end
                end)

                UserInputService.InputEnded:Connect(function(inp)
                    if sliding and (inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch) then
                        sliding    = false
                        currentPct = targetPct
                        local snap = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        TweenService:Create(Fill, snap, { Size     = UDim2.new(targetPct, 0, 1, 0) }):Play()
                        TweenService:Create(Knob, snap, { Position = UDim2.new(targetPct,-7,0.5,-7) }):Play()
                        tween(Knob, { Size = UDim2.new(0,14,0,14) }, 0.2)
                    end
                end)

                UserInputService.InputChanged:Connect(function(inp)
                    if sliding and (inp.UserInputType == Enum.UserInputType.MouseMovement
                    or inp.UserInputType == Enum.UserInputType.Touch) then
                        targetPct = math.clamp(
                            (inp.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                    end
                end)

                RunService.RenderStepped:Connect(function()
                    if not sliding then return end
                    local diff = targetPct - currentPct
                    if math.abs(diff) > 0.001 then
                        currentPct    = currentPct + diff * sliderLerp
                        Fill.Size     = UDim2.new(currentPct, 0, 1, 0)
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
                    targetPct = p; currentPct = p
                    VLabel.Text = tostring(val)
                    tween(Fill, { Size     = UDim2.new(p, 0, 1, 0) })
                    tween(Knob, { Position = UDim2.new(p, -7, 0.5, -7) })
                    callback(val)
                end
                return API
            end

            -- ────────── BUTTON ──────────
            function Section:CreateButton(text, callback)
                callback = callback or function() end

                local F = create("Frame", {
                    Size                   = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    Parent                 = SFrame,
                })

                local BG = create("Frame", {
                    Size             = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Config.AccentColor,
                    Parent           = F,
                })
                corner(BG, UDim.new(0, 7))
                makeGradient(BG, 135)
                registerThemed("accent", BG, "BackgroundColor3")

                -- Separate TextLabel so UIGradient never affects text colour
                local BtnLbl = create("TextLabel", {
                    Size                   = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                   = text,
                    TextColor3             = Config.OnAccentText,
                    TextSize               = 13,
                    Font                   = Config.SubFont,
                    ZIndex                 = 2,
                    Parent                 = BG,
                })
                registerThemed("btn-text", BtnLbl, "TextColor3")

                local B = create("TextButton", {
                    Size                   = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                   = "",
                    ZIndex                 = 3,
                    Parent                 = BG,
                })
                B.MouseButton1Click:Connect(function()
                    local h2, s2, v2 = Config.AccentColor:ToHSV()
                    local flash = Color3.fromHSV(h2, math.max(0,s2*0.5), math.min(1,v2*1.3))
                    tween(BG, { BackgroundColor3 = flash }, 0.1)
                    task.wait(0.12)
                    tween(BG, { BackgroundColor3 = Config.AccentColor }, 0.2)
                    callback()
                end)
            end

            -- ────────── TEXTBOX ──────────
            function Section:CreateTextBox(text, placeholder, callback)
                callback = callback or function() end

                local F = create("Frame", {
                    Size                   = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    Parent                 = SFrame,
                })
                create("TextLabel", {
                    Size                   = UDim2.new(0.42, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                   = text,
                    TextColor3             = Config.TextColor,
                    TextSize               = 13,
                    Font                   = Config.SubFont,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    Parent                 = F,
                })

                local BoxBG = create("Frame", {
                    Size             = UDim2.new(0.54, 0, 0, 26),
                    Position         = UDim2.new(0.46, 0, 0.5, -13),
                    BackgroundColor3 = Config.MainColor,
                    Parent           = F,
                })
                corner(BoxBG, UDim.new(0, 6))
                local bStroke = stroke(BoxBG, Config.BorderColor, 1)

                local Box = create("TextBox", {
                    Size                   = UDim2.new(1, -12, 1, 0),
                    Position               = UDim2.new(0, 6, 0, 0),
                    BackgroundTransparency = 1,
                    Text                   = "",
                    PlaceholderText        = placeholder or "...",
                    PlaceholderColor3      = Config.SubTextColor,
                    TextColor3             = Config.TextColor,
                    TextSize               = 12,
                    Font                   = Config.SubFont,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ClearTextOnFocus       = false,
                    Parent                 = BoxBG,
                })
                Box.Focused:Connect(function()
                    tween(bStroke, { Color = Config.AccentColor }, 0.2)
                end)
                Box.FocusLost:Connect(function(enter)
                    tween(bStroke, { Color = Config.BorderColor }, 0.2)
                    if enter then callback(Box.Text) end
                end)

                local API = {}
                function API:Set(v) Box.Text = v; callback(v) end
                return API
            end

            -- ────────── COLOR PICKER ──────────
            function Section:CreateColorPicker(text, default, callback)
                callback = callback or function() end
                local col  = default or Color3.fromRGB(255, 0, 0)
                local open = false
                local h, s, v = col:ToHSV()

                local F = create("Frame", {
                    Size                   = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    ClipsDescendants       = false,
                    Parent                 = SFrame,
                })
                create("TextLabel", {
                    Size                   = UDim2.new(1, -40, 0, 32),
                    BackgroundTransparency = 1,
                    Text                   = text,
                    TextColor3             = Config.TextColor,
                    TextSize               = 13,
                    Font                   = Config.SubFont,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    Parent                 = F,
                })

                local Preview = create("TextButton", {
                    Size             = UDim2.new(0, 28, 0, 20),
                    Position         = UDim2.new(1, -28, 0, 6),
                    BackgroundColor3 = col,
                    Text             = "",
                    Parent           = F,
                })
                corner(Preview, UDim.new(0, 5))
                stroke(Preview, Config.BorderColor, 1)

                local Panel = create("Frame", {
                    Size             = UDim2.new(1, 0, 0, 0),
                    Position         = UDim2.new(0, 0, 0, 34),
                    BackgroundColor3 = Config.MainColor,
                    ClipsDescendants = true,
                    Parent           = F,
                })
                corner(Panel, UDim.new(0, 8))
                stroke(Panel, Config.BorderColor, 1)

                local Field = create("ImageLabel", {
                    Size             = UDim2.new(1, -44, 0, 100),
                    Position         = UDim2.new(0, 8, 0, 8),
                    BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                    Image            = "rbxassetid://4155801252",
                    Parent           = Panel,
                })
                corner(Field, UDim.new(0, 4))

                local FieldBtn = create("TextButton", {
                    Size                   = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                   = "",
                    Parent                 = Field,
                })
                local SVDot = create("Frame", {
                    Size                   = UDim2.new(0, 10, 0, 10),
                    Position               = UDim2.new(s, -5, 1-v, -5),
                    BackgroundTransparency = 1,
                    Parent                 = Field,
                })
                corner(SVDot, UDim.new(1, 0))
                stroke(SVDot, Color3.new(1,1,1), 2)

                local HBar = create("Frame", {
                    Size     = UDim2.new(0, 20, 0, 100),
                    Position = UDim2.new(1, -28, 0, 8),
                    Parent   = Panel,
                })
                corner(HBar, UDim.new(0, 4))
                create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,   0,   0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255,   0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(  0, 255,   0)),
                        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(  0, 255, 255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(  0,   0, 255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,   0, 255)),
                        ColorSequenceKeypoint.new(1,    Color3.fromRGB(255,   0,   0)),
                    }),
                    Rotation = 90,
                    Parent   = HBar,
                })

                local HBtn = create("TextButton", {
                    Size                   = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text                   = "",
                    Parent                 = HBar,
                })
                local HCur = create("Frame", {
                    Size             = UDim2.new(1, 4, 0, 4),
                    Position         = UDim2.new(0, -2, h, -2),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Parent           = HBar,
                })
                corner(HCur, UDim.new(1, 0))

                local RGBRow = create("Frame", {
                    Size                   = UDim2.new(1, -16, 0, 22),
                    Position               = UDim2.new(0, 8, 0, 114),
                    BackgroundTransparency = 1,
                    Parent                 = Panel,
                })

                local function makeRGB(lbl, xPos, initVal)
                    local cF = create("Frame", {
                        Size                   = UDim2.new(0.3, 0, 1, 0),
                        Position               = UDim2.new(xPos, 0, 0, 0),
                        BackgroundTransparency = 1,
                        Parent                 = RGBRow,
                    })
                    create("TextLabel", {
                        Size                   = UDim2.new(0, 12, 1, 0),
                        BackgroundTransparency = 1,
                        Text                   = lbl,
                        TextColor3             = Config.SubTextColor,
                        TextSize               = 10,
                        Font                   = Config.Font,
                        Parent                 = cF,
                    })
                    local bg = create("Frame", {
                        Size             = UDim2.new(1, -14, 1, 0),
                        Position         = UDim2.new(0, 14, 0, 0),
                        BackgroundColor3 = Config.SecondaryColor,
                        Parent           = cF,
                    })
                    corner(bg, UDim.new(0, 4))
                    local tb = create("TextBox", {
                        Size                   = UDim2.new(1, -4, 1, 0),
                        Position               = UDim2.new(0, 2, 0, 0),
                        BackgroundTransparency = 1,
                        Text                   = tostring(initVal),
                        TextColor3             = Config.TextColor,
                        TextSize               = 10,
                        Font                   = Config.SubFont,
                        TextXAlignment         = Enum.TextXAlignment.Center,
                        Parent                 = bg,
                    })
                    return tb
                end

                local RI = makeRGB("R", 0,    math.floor(col.R*255))
                local GI = makeRGB("G", 0.33, math.floor(col.G*255))
                local BI = makeRGB("B", 0.66, math.floor(col.B*255))

                local function refresh()
                    col = Color3.fromHSV(h, s, v)
                    Preview.BackgroundColor3 = col
                    Field.BackgroundColor3   = Color3.fromHSV(h, 1, 1)
                    SVDot.Position           = UDim2.new(s, -5, 1-v, -5)
                    HCur.Position            = UDim2.new(0, -2, h, -2)
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
                        s = math.clamp((inp.Position.X - Field.AbsolutePosition.X)/Field.AbsoluteSize.X, 0, 1)
                        v = 1 - math.clamp((inp.Position.Y - Field.AbsolutePosition.Y)/Field.AbsoluteSize.Y, 0, 1)
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
                        h = math.clamp(
                            (inp.Position.Y - HBar.AbsolutePosition.Y)/HBar.AbsoluteSize.Y, 0, 1)
                        refresh()
                    end
                end)

                for _, inp in pairs({ RI, GI, BI }) do
                    inp.FocusLost:Connect(function()
                        local rv = math.clamp(tonumber(RI.Text) or 0, 0, 255)
                        local gv = math.clamp(tonumber(GI.Text) or 0, 0, 255)
                        local bv = math.clamp(tonumber(BI.Text) or 0, 0, 255)
                        col = Color3.fromRGB(rv, gv, bv)
                        h, s, v = col:ToHSV(); refresh()
                    end)
                end

                Preview.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        tween(F,     { Size = UDim2.new(1,0,0,180) })
                        tween(Panel, { Size = UDim2.new(1,0,0,145) })
                    else
                        tween(F,     { Size = UDim2.new(1,0,0,32) })
                        tween(Panel, { Size = UDim2.new(1,0,0,0)  })
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
