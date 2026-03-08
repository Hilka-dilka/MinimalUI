--[[
    ███╗   ███╗██╗███╗   ██╗██╗███╗   ███╗ █████╗ ██╗     ██╗   ██╗██╗
    ████╗ ████║██║████╗  ██║██║████╗ ████║██╔══██╗██║     ██║   ██║██║
    ██╔████╔██║██║██╔██╗ ██║██║██╔████╔██║███████║██║     ██║   ██║██║
    ██║╚██╔╝██║██║██║╚██╗██║██║██║╚██╔╝██║██╔══██║██║     ██║   ██║██║
    ██║ ╚═╝ ██║██║██║ ╚████║██║██║ ╚═╝ ██║██║  ██║███████╗╚██████╔╝██║
    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝

    -- Minimal UI  v2.0  -- Фиолетовый градиент. UI без него.
    GitHub: загрузите этот файл как MinimalUI.lua
]]

local MinimalUI = {}

-- Services
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local Players         = game:GetService("Players")
local Player          = Players.LocalPlayer

-- Config (изменяется через SetTheme)
local Config = {
    MainColor      = Color3.fromRGB(19, 19, 31),
    SecondaryColor = Color3.fromRGB(26, 26, 42),
    AccentColor    = Color3.fromRGB(124, 58, 237),
    AccentColor2   = Color3.fromRGB(168, 85, 247),
    TextColor      = Color3.fromRGB(228, 228, 231),
    SubTextColor   = Color3.fromRGB(120, 120, 150),
    BorderColor    = Color3.fromRGB(40, 40, 60),
    OnAccentText   = Color3.fromRGB(255, 255, 255),  -- текст на кнопках/вкладках
    Font           = Enum.Font.GothamSemibold,
    SubFont        = Enum.Font.Gotham,
    AnimSpeed      = 0.25
}

-- Список всех окрашенных элементов для динамической смены темы
local themedElements = {}
local themedGradients = {} -- UIGradient objects that need ColorSequence updates
local titleGradRef    = nil  -- reference to title UIGradient
local tabGradients    = {} -- {gradient, tabBtn} pairs for tab buttons

local function registerThemed(role, obj, prop)
    table.insert(themedElements, {role=role, obj=obj, prop=prop})
end
local function registerGradient(g)
    table.insert(themedGradients, g)
end

-- ═══════════════════════════════════════
-- SetTheme: меняет цвет акцента везде
-- AccentColor2 = слегка сдвинутый в светлую сторону тот же цвет
-- НЕ смешивается с фиолетовым — только варьируется яркость/насыщенность
-- ═══════════════════════════════════════
function MinimalUI:SetTheme(color)
    Config.AccentColor = color
    local h, s, v = color:ToHSV()

    -- Perceived luminance to detect light colours
    local lum = 0.299*color.R + 0.587*color.G + 0.114*color.B
    local isLight = lum > 0.55

    if isLight then
        -- Light colour → AccentColor2 is darker shade of the same hue
        local s2 = math.min(1, s * 1.2 + 0.1)
        local v2 = math.max(0, v * 0.55)
        Config.AccentColor2 = Color3.fromHSV(h, s2, v2)
    else
        -- Dark colour → AccentColor2 is lighter/desaturated (blends toward white)
        local s2 = math.max(0, s * 0.45)
        local v2 = math.min(1, v * 0.75 + 0.30)
        Config.AccentColor2 = Color3.fromHSV(h, s2, v2)
    end

    -- Text colour on gradient backgrounds: dark text for light accents, white for dark
    local onAccentText = isLight
        and Color3.fromRGB(26, 26, 46)   -- темно-синий для светлых цветов
        or  Color3.fromRGB(255, 255, 255) -- белый для тёмных
    Config.OnAccentText = onAccentText

    local newSeq = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Config.AccentColor),
        ColorSequenceKeypoint.new(1, Config.AccentColor2),
    })

    -- Update flat-color elements
    for _, e in pairs(themedElements) do
        if e.obj and e.obj.Parent then
            local targetColor
            if e.role == "accent2" then
                targetColor = Config.AccentColor2
            elseif e.role == "btn-text" then
                targetColor = onAccentText  -- white on dark, dark on light
            else
                targetColor = Config.AccentColor
            end
            TweenService:Create(e.obj, TweenInfo.new(0.4), {
                [e.prop] = targetColor
            }):Play()
        end
    end

    -- Update UIGradient objects with smooth tween via intermediate steps
    for _, g in pairs(themedGradients) do
        if g and g.Parent then
            -- Tween gradient by animating through 8 steps over 0.4s
            task.spawn(function()
                local oldSeq = g.Color
                local oldC1 = oldSeq.Keypoints[1].Value
                local oldC2 = oldSeq.Keypoints[#oldSeq.Keypoints].Value
                local steps = 12
                for i = 1, steps do
                    local t = i / steps
                    local c1 = oldC1:Lerp(Config.AccentColor, t)
                    local c2 = oldC2:Lerp(Config.AccentColor2, t)
                    if g and g.Parent then
                        g.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, c1),
                            ColorSequenceKeypoint.new(1, c2),
                        })
                    end
                    task.wait(0.4 / steps)
                end
                if g and g.Parent then
                    g.Color = newSeq
                end
            end)
        end
    end

    -- Update tab button text + gradient visibility (with smooth tween)
    for _, tg in pairs(tabGradients) do
        if tg.grad and tg.btn and tg.btn.Parent then
            if tg.grad.Enabled then
                -- активная вкладка — текст зависит от яркости цвета
                TweenService:Create(tg.btn, TweenInfo.new(0.4), {
                    TextColor3 = onAccentText
                }):Play()
            else
                -- неактивная — серый
                tg.btn.TextColor3 = Config.SubTextColor
            end
        end
    end

    -- (btn-text updates are handled in the main themedElements loop above)

    -- Update title gradient with smooth tween over 0.4s
    if titleGradRef and titleGradRef.Parent then
        task.spawn(function()
            local oldSeq = titleGradRef.Color
            local oldA = oldSeq.Keypoints[1].Value
            local oldB = oldSeq.Keypoints[#oldSeq.Keypoints].Value
            local steps = 12
            for i = 1, steps do
                local t = i / steps
                local c1 = oldA:Lerp(isLight and Config.AccentColor2 or Config.AccentColor, t)
                local c2 = oldB:Lerp(isLight and Config.AccentColor or Config.AccentColor, t)
                local cMid = Color3.new(1,1,1):Lerp(
                    isLight and Config.AccentColor or Color3.new(1,1,1), t)
                if titleGradRef and titleGradRef.Parent then
                    if isLight then
                        titleGradRef.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0,    c1),
                            ColorSequenceKeypoint.new(0.35, c2),
                            ColorSequenceKeypoint.new(0.65, c1),
                            ColorSequenceKeypoint.new(1,    c2),
                        })
                    else
                        titleGradRef.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0,    c1),
                            ColorSequenceKeypoint.new(0.35, oldA:Lerp(Config.AccentColor2, t)),
                            ColorSequenceKeypoint.new(0.5,  cMid),
                            ColorSequenceKeypoint.new(0.65, oldA:Lerp(Config.AccentColor2, t)),
                            ColorSequenceKeypoint.new(1,    c1),
                        })
                    end
                end
                task.wait(0.4 / steps)
            end
        end)
    end
end

-- Utilities
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
    return create("UICorner", {
        CornerRadius = radius or UDim.new(0, 8), Parent = parent
    })
end

local function stroke(parent, color, thick)
    return create("UIStroke", {
        Color = color or Config.BorderColor,
        Thickness = thick or 1,
        Transparency = 0.5,
        Parent = parent
    })
end

-- Gradient helper (creates UIGradient with two accent colors)
local function makeGradient(parent, rotation)
    local g = create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Config.AccentColor),
            ColorSequenceKeypoint.new(1,   Config.AccentColor2),
        }),
        Rotation = rotation or 135,
        Parent = parent
    })
    registerGradient(g)
    return g
end

-- Smooth elastic dragging with lerp
local function makeDraggable(frame, handle)
    local dragging = false
    local dragInput, dragStart, startPos
    local targetX, targetY = frame.Position.X.Offset, frame.Position.Y.Offset
    local currentX, currentY = targetX, targetY
    local lerpSpeed = 0.14

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            targetX = startPos.X.Offset
            targetY = startPos.Y.Offset
            currentX = targetX; currentY = targetY
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
        local dx = targetX - currentX
        local dy = targetY - currentY
        if math.abs(dx) > 0.1 or math.abs(dy) > 0.1 then
            currentX = currentX + dx * lerpSpeed
            currentY = currentY + dy * lerpSpeed
            frame.Position = UDim2.new(
                startPos and startPos.X.Scale or 0.5, currentX,
                startPos and startPos.Y.Scale or 0.5, currentY
            )
        end
    end)
end

-- ═══════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════
function MinimalUI:CreateWindow(title)
    local old = Player.PlayerGui:FindFirstChild("MinimalUI")
    if old then old:Destroy() end

    local GUI = create("ScreenGui", {
        Name = "MinimalUI", Parent = Player.PlayerGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false
    })

    local Main = create("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 580, 0, 400),
        Position = UDim2.new(0.5, -290, 0.5, -200),
        BackgroundColor3 = Config.MainColor,
        Parent = GUI
    })
    corner(Main, UDim.new(0, 12))

    -- Shadow
    create("ImageLabel", {
        Size = UDim2.new(1, 40, 1, 40),
        Position = UDim2.new(0, -20, 0, -20),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = 0.4,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        ZIndex = 0, Parent = Main
    })

    -- Title Bar
    local TitleBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1, Parent = Main
    })
    makeDraggable(Main, TitleBar)

    -- Title with gradient shimmer
    local TitleLabel = create("TextLabel", {
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 82, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "MinimalUI",
        TextColor3 = Config.TextColor,
        TextSize = 15, Font = Config.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TitleBar
    })
    local titleGrad = create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,   Config.AccentColor),
            ColorSequenceKeypoint.new(0.35, Config.AccentColor2),
            ColorSequenceKeypoint.new(0.5, Color3.new(1,1,1)),
            ColorSequenceKeypoint.new(0.65, Config.AccentColor2),
            ColorSequenceKeypoint.new(1,   Config.AccentColor),
        }),
        Parent = TitleLabel
    })
    titleGradRef = titleGrad
    task.spawn(function()
        while TitleLabel.Parent do
            TweenService:Create(titleGrad, TweenInfo.new(
                2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
            ), {Offset = Vector2.new(1, 0)}):Play()
            task.wait(2)
            TweenService:Create(titleGrad, TweenInfo.new(
                2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut
            ), {Offset = Vector2.new(-1, 0)}):Play()
            task.wait(2)
        end
    end)

    create("Frame", {
        Size = UDim2.new(1, -24, 0, 1),
        Position = UDim2.new(0, 12, 1, 0),
        BackgroundColor3 = Config.BorderColor,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0, Parent = TitleBar
    })

    -- macOS traffic light dots
    local DotsFrame = create("Frame", {
        Size = UDim2.new(0, 60, 0, 14),
        Position = UDim2.new(0, 14, 0.5, -7),
        BackgroundTransparency = 1, Parent = TitleBar
    })
    create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 7),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = DotsFrame
    })

    local function makeDot(color, order)
        local dot = create("TextButton", {
            Size = UDim2.new(0, 13, 0, 13),
            BackgroundColor3 = color, Text = "",
            AutoButtonColor = false, LayoutOrder = order, Parent = DotsFrame
        })
        corner(dot, UDim.new(1, 0))
        return dot
    end

    local CloseDot = makeDot(Color3.fromRGB(255, 95, 87), 1)
    local MinDot   = makeDot(Color3.fromRGB(255, 189, 46), 2)
    local MaxDot   = makeDot(Color3.fromRGB(40, 200, 64), 3)

    CloseDot.MouseButton1Click:Connect(function()
        tween(Main, {Size = UDim2.new(0, 580, 0, 0)}, 0.3)
        task.wait(0.3); GUI:Destroy()
    end)

    local minimized = false
    MinDot.MouseButton1Click:Connect(function()
        minimized = not minimized
        tween(Main, {Size = minimized
            and UDim2.new(0, 580, 0, 44)
            or  UDim2.new(0, 580, 0, 400)}, 0.3)
    end)

    local maximized = false
    MaxDot.MouseButton1Click:Connect(function()
        maximized = not maximized
        if minimized then minimized = false end
        tween(Main, {Size = maximized
            and UDim2.new(0, 800, 0, 550)
            or  UDim2.new(0, 580, 0, 400)}, 0.35)
    end)

    local Body = create("Frame", {
        Size = UDim2.new(1, 0, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundTransparency = 1,
        ClipsDescendants = true, Parent = Main
    })

    local TabBar = create("Frame", {
        Size = UDim2.new(0, 140, 1, -12),
        Position = UDim2.new(0, 8, 0, 6),
        BackgroundColor3 = Config.SecondaryColor,
        BackgroundTransparency = 0.3, Parent = Body
    })
    corner(TabBar)
    create("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabBar
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6), Parent = TabBar
    })

    local ContentBox = create("Frame", {
        Size = UDim2.new(1, -164, 1, -12),
        Position = UDim2.new(0, 156, 0, 6),
        BackgroundTransparency = 1, Parent = Body
    })

    local toggleKey = Enum.KeyCode.RightControl
    local visible = true
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == toggleKey then
            visible = not visible; GUI.Enabled = visible
        end
    end)

    local Window = {}
    Window.Tabs = {}; Window.GUI = GUI
    function Window:SetKey(key) toggleKey = key end

    -- Dynamic theme setter accessible from Window
    function Window:SetTheme(color) MinimalUI:SetTheme(color) end

    -- ════════ TAB (smooth fade transition) ════════
    local tabSwitching = false
    local currentTab   = nil

    function Window:CreateTab(name)
        local Tab = { Sections = {} }

        local TabBtn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Config.AccentColor,
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Config.SubTextColor,
            TextSize = 13, Font = Config.SubFont, Parent = TabBar
        })
        corner(TabBtn, UDim.new(0, 7))

        -- Gradient for active tab background (hidden by default, shown when active)
        local tabGrad = create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Config.AccentColor),
                ColorSequenceKeypoint.new(1, Config.AccentColor2),
            }),
            Rotation = 135, Parent = TabBtn,
            Enabled = false, -- скрыт пока вкладка не активна
        })
        table.insert(tabGradients, {grad = tabGrad, btn = TabBtn})
        registerGradient(tabGrad)
        -- Регистрируем кнопку вкладки — при SetTheme цвет фона обновится
        registerThemed("accent", TabBtn, "BackgroundColor3")

        -- Wrapper Frame: обычный Frame, поддерживает Position tween для анимации вкладок
        local Wrapper = create("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Visible = false,
            Parent = ContentBox
        })

        local Content = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Config.AccentColor,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = Wrapper
        })
        registerThemed("accent", Content, "ScrollBarImageColor3")
        create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder, Parent = Content
        })

            local function selectTab()
            if tabSwitching or currentTab == Tab then return end
            tabSwitching = true

            -- Деактивируем все кнопки вкладок (скрываем градиент, серый текст)
            for _, t in pairs(Window.Tabs) do
                t.Btn.BackgroundTransparency = 1
                t.Btn.TextColor3 = Config.SubTextColor  -- серый для неактивных
                -- Скрываем градиент на неактивных вкладках
                for _, tg in pairs(tabGradients) do
                    if tg.btn == t.Btn then tg.grad.Enabled = false end
                end
            end
            -- Активируем выбранную: показываем градиент, текст зависит от яркости темы
            TabBtn.BackgroundTransparency = 0
            TweenService:Create(TabBtn, TweenInfo.new(0.25), {
                TextColor3 = Config.OnAccentText
            }):Play()
            tabGrad.Enabled = true

            -- Скрываем старую вкладку (только Position + TextTransparency — NO BackgroundTransparency на ScrollingFrame/Frame)
            if currentTab and currentTab.Wrapper.Visible then
                local oldW = currentTab.Wrapper
                -- Сдвигаем вверх
                TweenService:Create(oldW, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Position = UDim2.new(0, 0, 0, -8)
                }):Play()
                -- Только TextTransparency — это безопасно для TextLabel и TextButton
                for _, child in ipairs(oldW:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") then
                        TweenService:Create(child, TweenInfo.new(0.12), {TextTransparency = 1}):Play()
                    end
                end
                task.wait(0.15)
                oldW.Visible = false
                oldW.Position = UDim2.new(0, 0, 0, 0)
                -- Восстанавливаем TextTransparency у старой вкладки
                for _, child in ipairs(oldW:GetDescendants()) do
                    if child:IsA("TextLabel") or child:IsA("TextButton") then
                        child.TextTransparency = 0
                    end
                end
            end

            -- Показываем новую вкладку: Position сдвиг + TextTransparency fade
            -- НЕ трогаем BackgroundTransparency — только Position и TextTransparency
            Wrapper.Position = UDim2.new(0, 0, 0, 12)
            Wrapper.Visible = true
            -- Мгновенно скрываем весь текст
            for _, child in ipairs(Wrapper:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    child.TextTransparency = 1
                end
            end
            -- Tween: сдвиг позиции к нулю
            TweenService:Create(Wrapper, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, 0)
            }):Play()
            -- Tween: TextTransparency 1→0 только для TextLabel и TextButton
            for _, child in ipairs(Wrapper:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    TweenService:Create(child,
                        TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                        {TextTransparency = 0}
                    ):Play()
                end
            end
            task.wait(0.3)

            currentTab = Tab
            tabSwitching = false
        end

        TabBtn.MouseButton1Click:Connect(selectTab)
        if #Window.Tabs == 0 then
            Wrapper.Visible = true
            TabBtn.BackgroundTransparency = 0
            TabBtn.TextColor3 = Config.OnAccentText  -- зависит от цвета темы
            tabGrad.Enabled = true -- показываем градиент у первой вкладки
            currentTab = Tab
        end

        Tab.Btn = TabBtn; Tab.Content = Content; Tab.Wrapper = Wrapper

        -- ════════ SECTION ════════
        function Tab:CreateSection(sectionName)
            local Section = {}
            local SFrame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Config.SecondaryColor,
                BackgroundTransparency = 0.3, Parent = Content
            })
            corner(SFrame, UDim.new(0, 10))
            stroke(SFrame, Config.BorderColor, 1)
            create("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder, Parent = SFrame
            })
            create("UIPadding", {
                PaddingTop=UDim.new(0,10), PaddingBottom=UDim.new(0,10),
                PaddingLeft=UDim.new(0,14), PaddingRight=UDim.new(0,14),
                Parent = SFrame
            })

            -- Section title with gradient
            local STitleLbl = create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = string.upper(sectionName),
                TextColor3 = Config.AccentColor,
                TextSize = 11, Font = Config.Font,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SFrame
            })
            registerGradient(create("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Config.AccentColor),
                    ColorSequenceKeypoint.new(1, Config.AccentColor2),
                }), Parent = STitleLbl
            }))
            registerThemed("accent", STitleLbl, "TextColor3")
            create("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Config.BorderColor,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0, Parent = SFrame
            })

            -- ════════ TOGGLE ════════
            function Section:CreateToggle(text, default, callback)
                callback = callback or function() end
                local state = default or false
                local F = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1, Parent = SFrame
                })
                create("TextLabel", {
                    Size = UDim2.new(1, -50, 1, 0),
                    BackgroundTransparency = 1, Text = text,
                    TextColor3 = Config.TextColor, TextSize = 13,
                    Font = Config.SubFont,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = F
                })
                local BG = create("Frame", {
                    Size = UDim2.new(0, 38, 0, 20),
                    Position = UDim2.new(1, -38, 0.5, -10),
                    BackgroundColor3 = state and Config.AccentColor or Config.BorderColor,
                    Parent = F
                })
                corner(BG, UDim.new(1, 0))
                registerThemed("accent", BG, "BackgroundColor3")

                local Circle = create("Frame", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = state
                        and UDim2.new(1, -18, 0.5, -8)
                        or  UDim2.new(0, 2, 0.5, -8),
                    BackgroundColor3 = Color3.new(1,1,1), Parent = BG
                })
                corner(Circle, UDim.new(1, 0))
                local Btn = create("TextButton", {
                    Size = UDim2.new(1,0,1,0),
                    BackgroundTransparency = 1, Text = "", Parent = F
                })
                Btn.MouseButton1Click:Connect(function()
                    state = not state
                    tween(BG, {BackgroundColor3 = state and Config.AccentColor or Config.BorderColor})
                    tween(Circle, {Position = state
                        and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)})
                    callback(state)
                end)
                local API = {}
                function API:Set(v)
                    state = v
                    tween(BG, {BackgroundColor3 = v and Config.AccentColor or Config.BorderColor})
                    tween(Circle, {Position = v
                        and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)})
                    callback(v)
                end
                return API
            end

            -- ════════ SLIDER (smooth lerp) ════════
            function Section:CreateSlider(text, min, max, default, callback)
                callback = callback or function() end
                local val = default or min
                local F = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 44),
                    BackgroundTransparency = 1, Parent = SFrame
                })
                create("TextLabel", {
                    Size = UDim2.new(1, -45, 0, 18),
                    BackgroundTransparency = 1, Text = text,
                    TextColor3 = Config.TextColor, TextSize = 13,
                    Font = Config.SubFont,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = F
                })

                -- Clickable value label with spin arrows
                local SpinHolder = create("Frame", {
                    Size = UDim2.new(0, 70, 0, 20),
                    Position = UDim2.new(1, -70, 0, -1),
                    BackgroundTransparency = 1, Parent = F
                })
                local VBG = create("Frame", {
                    Size = UDim2.new(0, 50, 1, 0),
                    BackgroundColor3 = Config.MainColor,
                    BackgroundTransparency = 1, Parent = SpinHolder
                })
                corner(VBG, UDim.new(0, 5))
                local VGrad = create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Config.AccentColor),
                        ColorSequenceKeypoint.new(1, Config.AccentColor2),
                    }), Parent = VBG
                })
                registerGradient(VGrad)
                local VLabel = create("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(val),
                    TextColor3 = Config.AccentColor,
                    TextSize = 13, Font = Config.Font,
                    TextXAlignment = Enum.TextXAlignment.Center, Parent = VBG
                })
                registerThemed("accent", VLabel, "TextColor3")
                local VInput = create("TextBox", {
                    Size = UDim2.new(1, -4, 1, 0),
                    Position = UDim2.new(0, 2, 0, 0),
                    BackgroundTransparency = 1, Text = "",
                    TextColor3 = Config.TextColor,
                    TextSize = 13, Font = Config.Font,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Visible = false, ClearTextOnFocus = true, Parent = VBG
                })
                local VBtn = create("TextButton", {
                    Size = UDim2.new(1,0,1,0),
                    BackgroundTransparency = 1, Text = "", Parent = VBG
                })

                -- Spin arrows (up/down) — маленькие кнопки без фона
                local ArrowsFrame = create("Frame", {
                    Size = UDim2.new(0, 14, 1, 0),
                    Position = UDim2.new(0, 52, 0, 0),
                    BackgroundTransparency = 1, Parent = SpinHolder
                })
                local ArrowUp = create("TextButton", {
                    Size = UDim2.new(1, 0, 0.5, -1),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "▲", TextColor3 = Config.AccentColor,
                    TextSize = 8, Font = Config.Font, Parent = ArrowsFrame
                })
                registerThemed("accent", ArrowUp, "TextColor3")
                local ArrowDown = create("TextButton", {
                    Size = UDim2.new(1, 0, 0.5, -1),
                    Position = UDim2.new(0, 0, 0.5, 1),
                    BackgroundTransparency = 1,
                    Text = "▼", TextColor3 = Config.AccentColor,
                    TextSize = 8, Font = Config.Font, Parent = ArrowsFrame
                })
                registerThemed("accent", ArrowDown, "TextColor3")

                local step = math.max(1, math.floor((max - min) / 100))
                local targetPct = (val - min)/(max - min)
                local currentPct = targetPct

                VBtn.MouseButton1Click:Connect(function()
                    VLabel.Visible = false; VBtn.Visible = false
                    VInput.Visible = true; VInput.Text = tostring(val)
                    tween(VBG, {BackgroundTransparency = 0}, 0.15)
                    stroke(VBG, Config.AccentColor, 1)
                    VInput:CaptureFocus()
                end)

                local Track = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 5),
                    Position = UDim2.new(0, 0, 0, 28),
                    BackgroundColor3 = Config.BorderColor, Parent = F
                })
                corner(Track, UDim.new(1, 0))

                local pct = targetPct
                local Fill = create("Frame", {
                    Size = UDim2.new(pct, 0, 1, 0),
                    BackgroundColor3 = Config.AccentColor, Parent = Track
                })
                corner(Fill, UDim.new(1, 0))
                registerGradient(create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Config.AccentColor),
                        ColorSequenceKeypoint.new(1, Config.AccentColor2),
                    }), Parent = Fill
                }))
                registerThemed("accent", Fill, "BackgroundColor3")

                local Knob = create("Frame", {
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(pct, -7, 0.5, -7),
                    BackgroundColor3 = Color3.new(1,1,1),
                    ZIndex = 2, Parent = Track
                })
                corner(Knob, UDim.new(1, 0))

                local SlideBtn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 24),
                    Position = UDim2.new(0, 0, 0, 20),
                    BackgroundTransparency = 1, Text = "", Parent = F
                })

                VInput.FocusLost:Connect(function()
                    local num = tonumber(VInput.Text)
                    if num then
                        num = math.clamp(math.floor(num), min, max)
                        val = num
                        local p = (val - min)/(max - min)
                        targetPct = p; currentPct = p
                        local snapInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        TweenService:Create(Fill, snapInfo, {Size = UDim2.new(p,0,1,0)}):Play()
                        TweenService:Create(Knob, snapInfo, {Position = UDim2.new(p,-7,0.5,-7)}):Play()
                        callback(val)
                    end
                    VLabel.Visible = true; VBtn.Visible = true
                    VInput.Visible = false; VLabel.Text = tostring(val)
                    tween(VBG, {BackgroundTransparency = 1}, 0.15)
                    for _, c in pairs(VBG:GetChildren()) do
                        if c:IsA("UIStroke") then c:Destroy() end
                    end
                end)

                -- Spin arrow clicks (после объявления Fill и Knob)
                ArrowUp.MouseButton1Click:Connect(function()
                    val = math.clamp(val + step, min, max)
                    local p = (val - min)/(max - min)
                    targetPct = p; currentPct = p
                    VLabel.Text = tostring(val)
                    local snapInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    TweenService:Create(Fill, snapInfo, {Size = UDim2.new(p,0,1,0)}):Play()
                    TweenService:Create(Knob, snapInfo, {Position = UDim2.new(p,-7,0.5,-7)}):Play()
                    callback(val)
                end)
                ArrowDown.MouseButton1Click:Connect(function()
                    val = math.clamp(val - step, min, max)
                    local p = (val - min)/(max - min)
                    targetPct = p; currentPct = p
                    VLabel.Text = tostring(val)
                    local snapInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                    TweenService:Create(Fill, snapInfo, {Size = UDim2.new(p,0,1,0)}):Play()
                    TweenService:Create(Knob, snapInfo, {Position = UDim2.new(p,-7,0.5,-7)}):Play()
                    callback(val)
                end)

                local sliding = false
                local sliderLerp = 0.18

                SlideBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        tween(Knob, {Size = UDim2.new(0,18,0,18)}, 0.15)
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if (inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch) and sliding then
                        sliding = false; currentPct = targetPct
                        local snapInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        TweenService:Create(Fill, snapInfo, {Size = UDim2.new(targetPct,0,1,0)}):Play()
                        TweenService:Create(Knob, snapInfo, {Position = UDim2.new(targetPct,-7,0.5,-7)}):Play()
                        tween(Knob, {Size = UDim2.new(0,14,0,14)}, 0.2)
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
                        currentPct = currentPct + diff * sliderLerp
                        Fill.Size = UDim2.new(currentPct, 0, 1, 0)
                        Knob.Position = UDim2.new(currentPct, -7, 0.5, -7)
                        val = math.floor(min + (max - min) * currentPct)
                        VLabel.Text = tostring(val); callback(val)
                    end
                end)

                local API = {}
                function API:Set(v)
                    val = math.clamp(v, min, max)
                    local p = (val - min)/(max - min)
                    targetPct = p; currentPct = p
                    VLabel.Text = tostring(val)
                    tween(Fill, {Size = UDim2.new(p,0,1,0)})
                    tween(Knob, {Position = UDim2.new(p,-7,0.5,-7)})
                    callback(val)
                end
                return API
            end

            -- ════════ BUTTON (gradient bg + separate text label) ════════
            function Section:CreateButton(text, callback)
                callback = callback or function() end
                local F = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1, Parent = SFrame
                })
                -- BG Frame carries the gradient — UIGradient does NOT affect TextLabel children
                local BG = create("Frame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Config.AccentColor,
                    Parent = F
                })
                corner(BG, UDim.new(0, 7))
                local btnGrad = create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Config.AccentColor),
                        ColorSequenceKeypoint.new(1, Config.AccentColor2),
                    }), Rotation = 135, Parent = BG
                })
                registerGradient(btnGrad)
                registerThemed("accent", BG, "BackgroundColor3")

                -- Separate TextLabel so UIGradient on BG never touches text color
                local BtnLbl = create("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Config.OnAccentText,
                    TextSize = 13, Font = Config.SubFont,
                    ZIndex = 2, Parent = BG
                })
                registerThemed("btn-text", BtnLbl, "TextColor3")

                -- Invisible button over everything to capture clicks
                local B = create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 3, Parent = BG
                })

                B.MouseButton1Click:Connect(function()
                    -- Flash: lighten briefly then restore gradient
                    local h2,s2,v2 = Config.AccentColor:ToHSV()
                    local flashCol = Color3.fromHSV(h2, math.max(0, s2*0.5), math.min(1, v2*1.3))
                    tween(BG, {BackgroundColor3 = flashCol}, 0.1)
                    task.wait(0.1)
                    tween(BG, {BackgroundColor3 = Config.AccentColor}, 0.2)
                    callback()
                end)
            end

            -- ════════ TEXTBOX ════════
            function Section:CreateTextBox(text, placeholder, callback)
                callback = callback or function() end
                local F = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1, Parent = SFrame
                })
                create("TextLabel", {
                    Size = UDim2.new(0.4, 0, 1, 0),
                    BackgroundTransparency = 1, Text = text,
                    TextColor3 = Config.TextColor, TextSize = 13,
                    Font = Config.SubFont,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = F
                })
                local BoxBG = create("Frame", {
                    Size = UDim2.new(0.55, 0, 0, 28),
                    Position = UDim2.new(0.45, 0, 0.5, -14),
                    BackgroundColor3 = Config.MainColor, Parent = F
                })
                corner(BoxBG, UDim.new(0, 6))
                stroke(BoxBG, Config.BorderColor, 1)
                local Box = create("TextBox", {
                    Size = UDim2.new(1, -12, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    BackgroundTransparency = 1, Text = "",
                    PlaceholderText = placeholder or "...",
                    PlaceholderColor3 = Config.SubTextColor,
                    TextColor3 = Config.TextColor, TextSize = 12,
                    Font = Config.SubFont,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false, Parent = BoxBG
                })
                Box.FocusLost:Connect(function(enter)
                    if enter then callback(Box.Text) end
                end)
                local API = {}
                function API:Set(v) Box.Text = v; callback(v) end
                return API
            end

            -- ════════ COLOR PICKER ════════
            function Section:CreateColorPicker(text, default, callback)
                callback = callback or function() end
                local col = default or Color3.fromRGB(255,0,0)
                local open = false
                local h, s, v = col:ToHSV()
                local F = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    ClipsDescendants = false, Parent = SFrame
                })
                create("TextLabel", {
                    Size = UDim2.new(1, -40, 0, 32),
                    BackgroundTransparency = 1, Text = text,
                    TextColor3 = Config.TextColor, TextSize = 13,
                    Font = Config.SubFont,
                    TextXAlignment = Enum.TextXAlignment.Left, Parent = F
                })
                local Preview = create("TextButton", {
                    Size = UDim2.new(0, 28, 0, 20),
                    Position = UDim2.new(1, -28, 0, 6),
                    BackgroundColor3 = col, Text = "", Parent = F
                })
                corner(Preview, UDim.new(0, 5))
                stroke(Preview, Config.BorderColor, 1)

                local Panel = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, 34),
                    BackgroundColor3 = Config.MainColor,
                    ClipsDescendants = true, Parent = F
                })
                corner(Panel, UDim.new(0, 8))
                stroke(Panel, Config.BorderColor, 1)

                local Field = create("ImageLabel", {
                    Size = UDim2.new(1, -44, 0, 100),
                    Position = UDim2.new(0, 8, 0, 8),
                    BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                    Image = "rbxassetid://4155801252", Parent = Panel
                })
                corner(Field, UDim.new(0, 4))
                local FieldBtn = create("TextButton", {
                    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
                    Text="", Parent = Field
                })
                local SVDot = create("Frame", {
                    Size = UDim2.new(0,10,0,10),
                    Position = UDim2.new(s, -5, 1-v, -5),
                    BackgroundTransparency = 1, Parent = Field
                })
                corner(SVDot, UDim.new(1,0))
                stroke(SVDot, Color3.new(1,1,1), 2)

                local HBar = create("Frame", {
                    Size = UDim2.new(0, 20, 0, 100),
                    Position = UDim2.new(1, -28, 0, 8), Parent = Panel
                })
                corner(HBar, UDim.new(0, 4))
                create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,0,0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
                        ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0,255,255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
                        ColorSequenceKeypoint.new(1,   Color3.fromRGB(255,0,0))
                    }), Rotation = 90, Parent = HBar
                })
                local HBtn = create("TextButton", {
                    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
                    Text="", Parent=HBar
                })
                local HCur = create("Frame", {
                    Size = UDim2.new(1, 4, 0, 4),
                    Position = UDim2.new(0, -2, h, -2),
                    BackgroundColor3 = Color3.new(1,1,1), Parent = HBar
                })
                corner(HCur, UDim.new(1,0))

                local RGBRow = create("Frame", {
                    Size = UDim2.new(1, -16, 0, 22),
                    Position = UDim2.new(0, 8, 0, 114),
                    BackgroundTransparency = 1, Parent = Panel
                })

                local function makeInput(lbl, px, vv)
                    local c = create("Frame", {
                        Size=UDim2.new(0.3,0,1,0),
                        Position=UDim2.new(px,0,0,0),
                        BackgroundTransparency=1, Parent=RGBRow
                    })
                    create("TextLabel", {
                        Size=UDim2.new(0,12,1,0),
                        BackgroundTransparency=1, Text=lbl,
                        TextColor3=Config.SubTextColor, TextSize=10,
                        Font=Config.Font, Parent=c
                    })
                    local bg = create("Frame", {
                        Size=UDim2.new(1,-14,1,0),
                        Position=UDim2.new(0,14,0,0),
                        BackgroundColor3=Config.SecondaryColor, Parent=c
                    })
                    corner(bg, UDim.new(0,4))
                    local tb = create("TextBox", {
                        Size=UDim2.new(1,-4,1,0),
                        Position=UDim2.new(0,2,0,0),
                        BackgroundTransparency=1, Text=tostring(vv),
                        TextColor3=Config.TextColor, TextSize=10,
                        Font=Config.SubFont, Parent=bg
                    })
                    return tb
                end

                local RI = makeInput("R", 0,    math.floor(col.R*255))
                local GI = makeInput("G", 0.33, math.floor(col.G*255))
                local BI = makeInput("B", 0.66, math.floor(col.B*255))

                local function refresh()
                    col = Color3.fromHSV(h, s, v)
                    Preview.BackgroundColor3 = col
                    Field.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                    SVDot.Position = UDim2.new(s, -5, 1-v, -5)
                    HCur.Position = UDim2.new(0, -2, h, -2)
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

                for _, inp in pairs({RI, GI, BI}) do
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
                        tween(F, {Size = UDim2.new(1,0,0,180)})
                        tween(Panel, {Size = UDim2.new(1,0,0,145)})
                    else
                        tween(F, {Size = UDim2.new(1,0,0,32)})
                        tween(Panel, {Size = UDim2.new(1,0,0,0)})
                    end
                end)

                local API = {}
                function API:Set(c)
                    col = c; h,s,v = c:ToHSV(); refresh()
                end
                return API
            end

            return Section
        end

        table.insert(Window.Tabs, Tab)
        return Tab
    end

    return Window
end

return MinimalUI
