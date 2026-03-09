--[[
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   ███╗   ███╗██╗███╗   ██╗██╗███╗   ███╗  █████╗ ██╗        ║
║   ████╗ ████║██║████╗  ██║██║████╗ ████║ ██╔══██╗██║        ║
║   ██╔████╔██║██║██╔██╗ ██║██║██╔████╔██║ ███████║██║        ║
║   ██║╚██╔╝██║██║██║╚██╗██║██║██║╚██╔╝██║ ██╔══██║██║        ║
║   ██║ ╚═╝ ██║██║██║ ╚████║██║██║ ╚═╝ ██║ ██║  ██║███████╗   ║
║   ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝╚═╝     ╚═╝ ╚═╝  ╚═╝╚══════╝   ║
║                                                              ║
║              Minimal  ·  UI  ·  v2.0                        ║
║          by Hilka-dilka (Alargon's Scripts)                  ║
║                  © 2026  All rights reserved                 ║
║                                                              ║
║   GRADIENT RULE:                                             ║
║     any color   → shimmer with WHITE                         ║
║     light color → shimmer with DARK GREY                     ║
╚══════════════════════════════════════════════════════════════╝

    Usage:
    local UI = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/Hilka-dilka/MinimalUI/main/MinimalUI.lua"
    ))()
    local W  = UI:CreateWindow("My Hub")
    local Tab = W:CreateTab("Combat")
    local Sec = Tab:CreateSection("Aura")
    Sec:CreateToggle("Kill Aura", false, function(v) print(v) end)
    Sec:CreateSlider("Reach", 5, 50, 15, function(v) print(v) end)
    Sec:CreateButton("Reset", function() print("reset") end)
    Sec:CreateTextBox("Player", "Username...", function(t) print(t) end)
    Sec:CreateColorPicker("Theme", Color3.fromRGB(124,58,237), function(c)
        W:SetTheme(c)
    end)
]]

local MinimalUI = {}

-- Services
local TS      = game:GetService("TweenService")
local UIS     = game:GetService("UserInputService")
local RS      = game:GetService("RunService")
local Players = game:GetService("Players")
local LP      = Players.LocalPlayer

-- Theme table — all shimmer loops capture T by reference
-- so T.A / T.A2 updated in SetTheme are instantly visible
local T = {
    A  = Color3.fromRGB(124, 58, 237),
    A2 = Color3.new(1, 1, 1),
    ON = Color3.new(1, 1, 1),
}

-- Static config
local C = {
    Main   = Color3.fromRGB(19,  19,  31),
    Sec    = Color3.fromRGB(26,  26,  42),
    Text   = Color3.fromRGB(228, 228, 231),
    Sub    = Color3.fromRGB(120, 120, 150),
    Border = Color3.fromRGB(40,  40,  60),
    Font   = Enum.Font.GothamSemibold,
    SubF   = Enum.Font.Gotham,
    Speed  = 0.25,
}

-- Accent2: ALWAYS white unless colour is very light (all channels > 0.82)
local function calcA2(accent)
    if accent.R > 0.82 and accent.G > 0.82 and accent.B > 0.82 then
        return Color3.fromRGB(25, 25, 38)
    end
    return Color3.new(1, 1, 1)
end

local function calcON(accent)
    if accent.R > 0.82 and accent.G > 0.82 and accent.B > 0.82 then
        return Color3.fromRGB(26, 26, 46)
    end
    return Color3.new(1, 1, 1)
end

-- Shimmer engine
local SFPS = 1/30
local SAMP = 0.75
local SSPD = 0.035

-- Text shimmer: darker accent → light → darker accent (readable on any bg)
-- Uses a darkened version of T.A so text is clearly visible
local function textShimCS()
    local h2, s2, v2 = T.A:ToHSV()
    -- Darken the accent for text: lower value, keep hue/sat
    -- This makes text visibly darker than the gradient background
    local darkA = Color3.fromHSV(h2, math.min(1, s2 * 0.7), math.max(0.15, v2 * 0.45))
    -- Mid point: near-white but slightly tinted with accent hue
    local midCol = Color3.fromHSV(h2, math.min(1, s2 * 0.18), 0.92)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0,   darkA),
        ColorSequenceKeypoint.new(0.5, midCol),
        ColorSequenceKeypoint.new(1,   darkA),
    })
end

-- Background shimmer: full accent → white (for bg gradients on text elements)
local function shimCS()
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0,   T.A),
        ColorSequenceKeypoint.new(0.5, T.A2),
        ColorSequenceKeypoint.new(1,   T.A),
    })
end

local function spawnShim(grad, phase, isText)
    task.spawn(function()
        local t = (phase or 0) + math.random() * math.pi * 2
        while grad and grad.Parent do
            grad.Offset = Vector2.new(SAMP * math.sin(t), 0)
            grad.Color  = isText and textShimCS() or shimCS()
            t = t + SSPD
            task.wait(SFPS)
        end
    end)
end

local function textShim(lbl, phase)
    -- TextColor3 must be white so UIGradient colour shows through pure
    lbl.TextColor3 = Color3.new(1, 1, 1)
    local g = Instance.new("UIGradient")
    g.Color    = textShimCS()
    g.Rotation = 0
    g.Parent   = lbl
    spawnShim(g, phase, true)  -- isText = true → uses textShimCS
    return g
end

-- Static bg gradient registry
local bgGrads = {}

local function bgGrad(parent, rot)
    local g = Instance.new("UIGradient")
    g.Color    = ColorSequence.new(T.A, T.A2)
    g.Rotation = rot or 135
    g.Parent   = parent
    table.insert(bgGrads, g)
    return g
end

-- Flat-colour element registry
local flatElems = {}

local function reg(obj, prop, role)
    table.insert(flatElems, {obj=obj, prop=prop, role=role})
end

-- Toggle state registry
local toggleReg = {}

-- Tab registry
local tabReg = {}

-- Utilities
local function tw(obj, props, dur, style, dir)
    TS:Create(obj, TweenInfo.new(
        dur   or C.Speed,
        style or Enum.EasingStyle.Quart,
        dir   or Enum.EasingDirection.Out
    ), props):Play()
end

local function make(class, props)
    local i = Instance.new(class)
    for k, v in pairs(props) do
        if k ~= "Parent" then i[k] = v end
    end
    if props.Parent then i.Parent = props.Parent end
    return i
end

local function corner(p, r)
    return make("UICorner", {CornerRadius = r or UDim.new(0,8), Parent=p})
end

local function stroke(p, col, th)
    return make("UIStroke", {
        Color=col or C.Border, Thickness=th or 1,
        Transparency=0.5, Parent=p
    })
end

-- Draggable with lerp
local function draggable(frame, handle)
    local drag = false
    local dragIn, dragStart, startPos
    local tgX, tgY, curX, curY = 0, 0, 0, 0
    local LERP = 0.14

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            drag      = true
            dragStart = inp.Position
            startPos  = frame.Position
            tgX = startPos.X.Offset; tgY = startPos.Y.Offset
            curX = tgX; curY = tgY
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    drag = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragIn = inp
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if inp == dragIn and drag then
            local d = inp.Position - dragStart
            tgX = startPos.X.Offset + d.X
            tgY = startPos.Y.Offset + d.Y
        end
    end)
    RS.RenderStepped:Connect(function()
        local dx = tgX - curX
        local dy = tgY - curY
        if math.abs(dx) > 0.1 or math.abs(dy) > 0.1 then
            curX = curX + dx * LERP
            curY = curY + dy * LERP
            frame.Position = UDim2.new(
                startPos and startPos.X.Scale or 0.5, curX,
                startPos and startPos.Y.Scale or 0.5, curY
            )
        end
    end)
end

-- SetTheme
function MinimalUI:SetTheme(color)
    T.A  = color
    T.A2 = calcA2(color)
    T.ON = calcON(color)

    local bgSeq = ColorSequence.new(T.A, T.A2)
    for _, g in ipairs(bgGrads) do
        if g and g.Parent then g.Color = bgSeq end
    end

    for _, e in ipairs(flatElems) do
        if e.obj and e.obj.Parent then
            local col
            if     e.role == "accent" then col = T.A
            elseif e.role == "on"     then col = T.ON
            elseif e.role == "sub"    then col = C.Sub
            end
            if col then tw(e.obj, {[e.prop] = col}, 0.35) end
        end
    end

    for _, t in ipairs(toggleReg) do
        if t.bg and t.bg.Parent then
            tw(t.bg, {BackgroundColor3 = t.stateRef.v and T.A or C.Border}, 0.35)
        end
    end

    local tabSeq = ColorSequence.new(T.A, T.A2)
    for _, t in ipairs(tabReg) do
        if t.grad and t.grad.Parent then
            t.grad.Color = tabSeq
        end
        if t.lbl and t.lbl.Parent then
            t.lbl.TextColor3 = t.isActive and Color3.new(1,1,1) or C.Sub
        end
    end
end

-- CreateWindow
function MinimalUI:CreateWindow(title)
    T.A  = Color3.fromRGB(124, 58, 237)
    T.A2 = Color3.new(1, 1, 1)
    T.ON = Color3.new(1, 1, 1)
    bgGrads   = {}
    flatElems = {}
    toggleReg = {}
    tabReg    = {}

    local old = LP.PlayerGui:FindFirstChild("MinimalUI")
    if old then old:Destroy() end

    local GUI = make("ScreenGui", {
        Name="MinimalUI", Parent=LP.PlayerGui,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn=false,
    })

    local Main = make("Frame", {
        Name="Main",
        Size=UDim2.new(0,580,0,400),
        Position=UDim2.new(0.5,-290,0.5,-200),
        BackgroundColor3=C.Main,
        Parent=GUI,
    })
    corner(Main, UDim.new(0,12))

    local TBar = make("Frame", {
        Size=UDim2.new(1,0,0,44),
        BackgroundTransparency=1,
        Parent=Main,
    })
    draggable(Main, TBar)

    local TitleLbl = make("TextLabel", {
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text=title or "MinimalUI",
        TextColor3=Color3.new(1,1,1),
        TextSize=15, Font=C.Font,
        TextXAlignment=Enum.TextXAlignment.Center,
        Parent=TBar,
    })
    textShim(TitleLbl, 0)

    make("Frame", {
        Size=UDim2.new(1,-24,0,1),
        Position=UDim2.new(0,12,1,0),
        BackgroundColor3=C.Border,
        BackgroundTransparency=0.6,
        BorderSizePixel=0,
        Parent=TBar,
    })

    local DotsF = make("Frame", {
        Size=UDim2.new(0,60,0,14),
        Position=UDim2.new(0,14,0.5,-7),
        BackgroundTransparency=1,
        Parent=TBar,
    })
    make("UIListLayout", {
        FillDirection=Enum.FillDirection.Horizontal,
        Padding=UDim.new(0,7),
        VerticalAlignment=Enum.VerticalAlignment.Center,
        Parent=DotsF,
    })

    local function dot(col, ord)
        local d = make("TextButton", {
            Size=UDim2.new(0,13,0,13),
            BackgroundColor3=col, Text="",
            AutoButtonColor=false, LayoutOrder=ord,
            Parent=DotsF,
        })
        corner(d, UDim.new(1,0))
        return d
    end

    local DotC = dot(Color3.fromRGB(255,95,87),  1)
    local DotM = dot(Color3.fromRGB(255,189,46), 2)
    local DotX = dot(Color3.fromRGB(40,200,64),  3)

    DotC.MouseButton1Click:Connect(function()
        tw(Main, {Size=UDim2.new(0,580,0,0)}, 0.3)
        task.wait(0.3)
        GUI:Destroy()
    end)

    local minimized = false
    DotM.MouseButton1Click:Connect(function()
        minimized = not minimized
        tw(Main, {Size = minimized
            and UDim2.new(0,580,0,44)
            or  UDim2.new(0,580,0,400)}, 0.3)
    end)

    local maximized = false
    DotX.MouseButton1Click:Connect(function()
        maximized = not maximized
        if minimized then minimized = false end
        tw(Main, {Size = maximized
            and UDim2.new(0,800,0,550)
            or  UDim2.new(0,580,0,400)}, 0.35)
    end)

    local Body = make("Frame", {
        Size=UDim2.new(1,0,1,-44),
        Position=UDim2.new(0,0,0,44),
        BackgroundTransparency=1,
        ClipsDescendants=true,
        Parent=Main,
    })

    local TabBar = make("Frame", {
        Size=UDim2.new(0,140,1,-12),
        Position=UDim2.new(0,8,0,6),
        BackgroundColor3=C.Sec,
        BackgroundTransparency=0.3,
        Parent=Body,
    })
    corner(TabBar)
    make("UIListLayout", {
        Padding=UDim.new(0,3),
        SortOrder=Enum.SortOrder.LayoutOrder,
        Parent=TabBar,
    })
    make("UIPadding", {
        PaddingTop=UDim.new(0,6),
        PaddingLeft=UDim.new(0,6),
        PaddingRight=UDim.new(0,6),
        Parent=TabBar,
    })

    local ContentBox = make("Frame", {
        Size=UDim2.new(1,-164,1,-12),
        Position=UDim2.new(0,156,0,6),
        BackgroundTransparency=1,
        Parent=Body,
    })

    local visKey = Enum.KeyCode.RightControl
    local visible = true
    UIS.InputBegan:Connect(function(inp, gpe)
        if not gpe and inp.KeyCode == visKey then
            visible = not visible
            GUI.Enabled = visible
        end
    end)

    local Window = {Tabs={}, GUI=GUI}
    function Window:SetKey(k) visKey = k end
    function Window:SetTheme(color) MinimalUI:SetTheme(color) end

    local switching = false
    local curTab    = nil

    function Window:CreateTab(name)
        local Tab = {Sections={}}

        local TBtn = make("TextButton", {
            Size=UDim2.new(1,0,0,32),
            BackgroundColor3=Color3.new(1,1,1),
            BackgroundTransparency=1,
            Text="",
            AutoButtonColor=false,
            Parent=TabBar,
        })
        corner(TBtn, UDim.new(0,7))

        local TGrad = make("UIGradient", {
            Color=ColorSequence.new(T.A, T.A2),
            Rotation=135,
            Enabled=false,
            Parent=TBtn,
        })
        table.insert(bgGrads, TGrad)

        local TLbl = make("TextLabel", {
            Size=UDim2.new(1,0,1,0),
            BackgroundTransparency=1,
            Text=name,
            TextColor3=C.Sub,
            TextSize=13, Font=C.SubF,
            ZIndex=2,
            Parent=TBtn,
        })

        local TLblGrad = make("UIGradient", {
            Color=shimCS(),
            Enabled=false,
            Parent=TLbl,
        })
        spawnShim(TLblGrad)

        local tabEntry = {grad=TGrad, lbl=TLbl, isActive=false}
        table.insert(tabReg, tabEntry)

        local Wrapper = make("Frame", {
            Size=UDim2.new(1,0,1,0),
            BackgroundTransparency=1,
            ClipsDescendants=true,
            Visible=false,
            Parent=ContentBox,
        })

        local Scroll = make("ScrollingFrame", {
            Size=UDim2.new(1,0,1,0),
            BackgroundTransparency=1,
            ScrollBarThickness=3,
            ScrollBarImageColor3=T.A,
            BorderSizePixel=0,
            CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            Parent=Wrapper,
        })
        reg(Scroll, "ScrollBarImageColor3", "accent")

        make("UIListLayout", {
            Padding=UDim.new(0,8),
            SortOrder=Enum.SortOrder.LayoutOrder,
            Parent=Scroll,
        })
        make("UIPadding", {
            PaddingTop=UDim.new(0,4),
            PaddingBottom=UDim.new(0,4),
            PaddingLeft=UDim.new(0,4),
            PaddingRight=UDim.new(0,4),
            Parent=Scroll,
        })

        local function activate()
            if switching or curTab == Tab then return end
            switching = true

            for _, t in ipairs(Window.Tabs) do
                t.Btn.BackgroundTransparency = 1
                t.TGrad.Enabled   = false
                t.LblGrad.Enabled = false
                t.Lbl.TextColor3  = C.Sub
                for _, te in ipairs(tabReg) do
                    if te.lbl == t.Lbl then te.isActive = false end
                end
            end

            TBtn.BackgroundTransparency = 0
            TGrad.Enabled   = true
            TGrad.Color     = ColorSequence.new(T.A, T.A2)
            TLblGrad.Enabled = true
            TLbl.TextColor3  = Color3.new(1,1,1)
            tabEntry.isActive = true

            if curTab and curTab.Wrapper.Visible then
                local ow = curTab.Wrapper
                tw(ow, {Position=UDim2.new(0,0,0,-8)}, 0.15,
                    Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                for _, d in ipairs(ow:GetDescendants()) do
                    if d:IsA("TextLabel") or d:IsA("TextButton") then
                        tw(d, {TextTransparency=1}, 0.12)
                    end
                end
                task.wait(0.16)
                ow.Visible  = false
                ow.Position = UDim2.new(0,0,0,0)
                for _, d in ipairs(ow:GetDescendants()) do
                    if d:IsA("TextLabel") or d:IsA("TextButton") then
                        d.TextTransparency = 0
                    end
                end
            end

            Wrapper.Position = UDim2.new(0,0,0,12)
            Wrapper.Visible  = true
            for _, d in ipairs(Wrapper:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") then
                    d.TextTransparency = 1
                end
            end
            tw(Wrapper, {Position=UDim2.new(0,0,0,0)}, 0.3,
                Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            for _, d in ipairs(Wrapper:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") then
                    tw(d, {TextTransparency=0}, 0.3)
                end
            end
            task.wait(0.3)
            curTab    = Tab
            switching = false
        end

        TBtn.MouseButton1Click:Connect(activate)

        if #Window.Tabs == 0 then
            Wrapper.Visible             = true
            TBtn.BackgroundTransparency = 0
            TGrad.Enabled               = true
            TGrad.Color                 = ColorSequence.new(T.A, T.A2)
            TLblGrad.Enabled            = true
            TLbl.TextColor3             = Color3.new(1,1,1)
            tabEntry.isActive           = true
            curTab                      = Tab
        end

        Tab.Btn     = TBtn
        Tab.TGrad   = TGrad
        Tab.Lbl     = TLbl
        Tab.LblGrad = TLblGrad
        Tab.Wrapper = Wrapper
        Tab.Scroll  = Scroll

        function Tab:CreateSection(secName)
            local Section = {}

            local SFrame = make("Frame", {
                Size=UDim2.new(1,0,0,0),
                AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundColor3=C.Sec,
                BackgroundTransparency=0.3,
                Parent=Scroll,
            })
            corner(SFrame, UDim.new(0,10))
            stroke(SFrame, C.Border, 1)

            make("UIListLayout", {
                Padding=UDim.new(0,0),
                SortOrder=Enum.SortOrder.LayoutOrder,
                Parent=SFrame,
            })

            local HeaderBtn = make("TextButton", {
                Size=UDim2.new(1,0,0,30),
                BackgroundTransparency=1,
                Text="", LayoutOrder=1,
                AutoButtonColor=false,
                Parent=SFrame,
            })

            local Arrow = make("TextLabel", {
                Size=UDim2.new(0,20,1,0),
                Position=UDim2.new(1,-24,0,0),
                BackgroundTransparency=1,
                Text="▾",
                TextColor3=Color3.new(1,1,1),
                TextSize=14, Font=C.Font,
                Parent=HeaderBtn,
            })
            textShim(Arrow)

            local STitle = make("TextLabel", {
                Size=UDim2.new(1,-28,1,0),
                Position=UDim2.new(0,4,0,0),
                BackgroundTransparency=1,
                Text=string.upper(secName),
                TextColor3=Color3.new(1,1,1),
                TextSize=11, Font=C.Font,
                TextXAlignment=Enum.TextXAlignment.Center,
                Parent=HeaderBtn,
            })
            textShim(STitle)

            local Sep = make("Frame", {
                Size=UDim2.new(1,0,0,1),
                BackgroundColor3=C.Border,
                BackgroundTransparency=0.5,
                BorderSizePixel=0,
                LayoutOrder=2,
                Parent=SFrame,
            })

            local Items = make("Frame", {
                Size=UDim2.new(1,0,0,0),
                AutomaticSize=Enum.AutomaticSize.Y,
                BackgroundTransparency=1,
                LayoutOrder=3,
                Parent=SFrame,
            })
            make("UIListLayout", {
                Padding=UDim.new(0,2),
                SortOrder=Enum.SortOrder.LayoutOrder,
                Parent=Items,
            })
            make("UIPadding", {
                PaddingTop=UDim.new(0,6),
                PaddingBottom=UDim.new(0,8),
                PaddingLeft=UDim.new(0,10),
                PaddingRight=UDim.new(0,10),
                Parent=Items,
            })

            local collapsed  = false
            local collapsing = false
            local naturalH   = 0

            HeaderBtn.MouseButton1Click:Connect(function()
                if collapsing then return end
                collapsing = true
                if not collapsed then
                    naturalH = Items.AbsoluteSize.Y
                    for _, d in ipairs(Items:GetDescendants()) do
                        if d:IsA("TextLabel") or d:IsA("TextButton") then
                            tw(d, {TextTransparency=1}, 0.15)
                        end
                    end
                    task.wait(0.15)
                    Items.AutomaticSize = Enum.AutomaticSize.None
                    Items.Size = UDim2.new(1,0,0,naturalH)
                    Sep.Visible = false
                    tw(Items, {Size=UDim2.new(1,0,0,0)}, 0.25,
                        Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                    task.wait(0.26)
                    Items.Visible = false
                    Arrow.Text = "▸"
                    collapsed = true
                else
                    Items.Visible = true
                    Items.Size = UDim2.new(1,0,0,0)
                    Items.AutomaticSize = Enum.AutomaticSize.None
                    Sep.Visible = true
                    for _, d in ipairs(Items:GetDescendants()) do
                        if d:IsA("TextLabel") or d:IsA("TextButton") then
                            d.TextTransparency = 1
                        end
                    end
                    tw(Items, {Size=UDim2.new(1,0,0,naturalH)}, 0.28,
                        Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                    task.wait(0.28)
                    Items.AutomaticSize = Enum.AutomaticSize.Y
                    for _, d in ipairs(Items:GetDescendants()) do
                        if d:IsA("TextLabel") or d:IsA("TextButton") then
                            tw(d, {TextTransparency=0}, 0.2)
                        end
                    end
                    Arrow.Text = "▾"
                    collapsed = false
                end
                collapsing = false
            end)

            -- TOGGLE
            function Section:CreateToggle(text, default, callback)
                callback = callback or function() end
                local stateRef = {v = default or false}

                local F = make("Frame", {
                    Size=UDim2.new(1,0,0,32),
                    BackgroundTransparency=1,
                    Parent=Items,
                })
                make("TextLabel", {
                    Size=UDim2.new(1,-50,1,0),
                    BackgroundTransparency=1,
                    Text=text, TextColor3=C.Text,
                    TextSize=13, Font=C.SubF,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    Parent=F,
                })
                local BG = make("Frame", {
                    Size=UDim2.new(0,38,0,20),
                    Position=UDim2.new(1,-38,0.5,-10),
                    BackgroundColor3 = stateRef.v and T.A or C.Border,
                    Parent=F,
                })
                corner(BG, UDim.new(1,0))
                table.insert(toggleReg, {bg=BG, stateRef=stateRef})

                local Circle = make("Frame", {
                    Size=UDim2.new(0,16,0,16),
                    Position = stateRef.v
                        and UDim2.new(1,-18,0.5,-8)
                        or  UDim2.new(0,2,0.5,-8),
                    BackgroundColor3=Color3.new(1,1,1),
                    Parent=BG,
                })
                corner(Circle, UDim.new(1,0))

                local Btn = make("TextButton", {
                    Size=UDim2.new(1,0,1,0),
                    BackgroundTransparency=1,
                    Text="", Parent=F,
                })
                Btn.MouseButton1Click:Connect(function()
                    stateRef.v = not stateRef.v
                    tw(BG,     {BackgroundColor3 = stateRef.v and T.A or C.Border})
                    tw(Circle, {Position = stateRef.v
                        and UDim2.new(1,-18,0.5,-8)
                        or  UDim2.new(0,2,0.5,-8)})
                    callback(stateRef.v)
                end)

                local API = {}
                function API:Set(val)
                    stateRef.v = val
                    tw(BG,     {BackgroundColor3 = val and T.A or C.Border})
                    tw(Circle, {Position = val
                        and UDim2.new(1,-18,0.5,-8)
                        or  UDim2.new(0,2,0.5,-8)})
                    callback(val)
                end
                return API
            end

            -- SLIDER
            function Section:CreateSlider(text, min, max, default, callback)
                callback = callback or function() end
                local val = math.clamp(default or min, min, max)
                local pct = (val - min) / (max - min)

                local F = make("Frame", {
                    Size=UDim2.new(1,0,0,48),
                    BackgroundTransparency=1,
                    Parent=Items,
                })

                local TopRow = make("Frame", {
                    Size=UDim2.new(1,0,0,20),
                    BackgroundTransparency=1,
                    Parent=F,
                })

                make("TextLabel", {
                    Size=UDim2.new(1,-76,1,0),
                    BackgroundTransparency=1,
                    Text=text, TextColor3=C.Text,
                    TextSize=13, Font=C.SubF,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    Parent=TopRow,
                })

                local ValHolder = make("Frame", {
                    Size=UDim2.new(0,72,1,0),
                    Position=UDim2.new(1,-72,0,0),
                    BackgroundTransparency=1,
                    Parent=TopRow,
                })

                local VBG = make("Frame", {
                    Size=UDim2.new(0,56,1,0),
                    Position=UDim2.new(0,0,0,0),
                    BackgroundColor3=Color3.new(1,1,1),
                    Parent=ValHolder,
                })
                corner(VBG, UDim.new(0,5))
                bgGrad(VBG, 135)

                local VLbl = make("TextLabel", {
                    Size=UDim2.new(1,0,1,0),
                    BackgroundTransparency=1,
                    Text=tostring(val),
                    TextColor3=Color3.new(1,1,1),
                    TextSize=13, Font=C.Font,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    ZIndex=2,
                    Parent=VBG,
                })
                textShim(VLbl)

                local VInput = make("TextBox", {
                    Size=UDim2.new(1,-4,1,0),
                    Position=UDim2.new(0,2,0,0),
                    BackgroundTransparency=1,
                    Text="", TextColor3=C.Text,
                    TextSize=13, Font=C.Font,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Visible=false, ClearTextOnFocus=true,
                    ZIndex=3, Parent=VBG,
                })
                local VBtn = make("TextButton", {
                    Size=UDim2.new(1,0,1,0),
                    BackgroundTransparency=1,
                    Text="", ZIndex=4,
                    Parent=VBG,
                })

                local ArrUpLbl = make("TextLabel", {
                    Size=UDim2.new(0,14,0.5,-1),
                    Position=UDim2.new(0,58,0,0),
                    BackgroundTransparency=1,
                    Text="▲",
                    TextColor3=Color3.new(1,1,1),
                    TextSize=8, Font=C.Font,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Parent=ValHolder,
                })
                textShim(ArrUpLbl)

                local ArrUp = make("TextButton", {
                    Size=UDim2.new(0,14,0.5,-1),
                    Position=UDim2.new(0,58,0,0),
                    BackgroundTransparency=1,
                    Text="", AutoButtonColor=false,
                    ZIndex=2, Parent=ValHolder,
                })

                local ArrDnLbl = make("TextLabel", {
                    Size=UDim2.new(0,14,0.5,-1),
                    Position=UDim2.new(0,58,0.5,1),
                    BackgroundTransparency=1,
                    Text="▼",
                    TextColor3=Color3.new(1,1,1),
                    TextSize=8, Font=C.Font,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Parent=ValHolder,
                })
                textShim(ArrDnLbl)

                local ArrDn = make("TextButton", {
                    Size=UDim2.new(0,14,0.5,-1),
                    Position=UDim2.new(0,58,0.5,1),
                    BackgroundTransparency=1,
                    Text="", AutoButtonColor=false,
                    ZIndex=2, Parent=ValHolder,
                })

                local Track = make("Frame", {
                    Size=UDim2.new(1,0,0,5),
                    Position=UDim2.new(0,0,0,28),
                    BackgroundColor3=C.Border,
                    Parent=F,
                })
                corner(Track, UDim.new(1,0))

                local Fill = make("Frame", {
                    Size=UDim2.new(pct,0,1,0),
                    BackgroundColor3=Color3.new(1,1,1),
                    Parent=Track,
                })
                corner(Fill, UDim.new(1,0))
                bgGrad(Fill, 0)

                local Knob = make("Frame", {
                    Size=UDim2.new(0,14,0,14),
                    Position=UDim2.new(pct,-7,0.5,-7),
                    BackgroundColor3=Color3.new(1,1,1),
                    ZIndex=2, Parent=Track,
                })
                corner(Knob, UDim.new(1,0))

                local SlideBtn = make("TextButton", {
                    Size=UDim2.new(1,0,0,24),
                    Position=UDim2.new(0,0,0,20),
                    BackgroundTransparency=1,
                    Text="", Parent=F,
                })

                local function updateSlider(newPct, snap)
                    pct = math.clamp(newPct, 0, 1)
                    val = math.floor(min + (max - min) * pct)
                    VLbl.Text = tostring(val)
                    if snap then
                        local si = TweenInfo.new(0.25,
                            Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        TS:Create(Fill, si, {Size=UDim2.new(pct,0,1,0)}):Play()
                        TS:Create(Knob, si, {Position=UDim2.new(pct,-7,0.5,-7)}):Play()
                    else
                        Fill.Size     = UDim2.new(pct,0,1,0)
                        Knob.Position = UDim2.new(pct,-7,0.5,-7)
                    end
                    callback(val)
                end

                VBtn.MouseButton1Click:Connect(function()
                    VLbl.Visible=false; VBtn.Visible=false
                    VInput.Visible=true; VInput.Text=tostring(val)
                    VInput:CaptureFocus()
                end)
                VInput.FocusLost:Connect(function()
                    local n = tonumber(VInput.Text)
                    if n then
                        updateSlider(
                            (math.clamp(math.floor(n), min, max) - min) / (max - min),
                            true)
                    end
                    VLbl.Visible=true; VBtn.Visible=true; VInput.Visible=false
                end)

                ArrUp.MouseButton1Click:Connect(function()
                    updateSlider(
                        (math.clamp(val+1, min, max) - min) / (max - min), true)
                end)
                ArrDn.MouseButton1Click:Connect(function()
                    updateSlider(
                        (math.clamp(val-1, min, max) - min) / (max - min), true)
                end)

                local sliding = false
                local tgPct   = pct
                local curPct  = pct
                local LERP    = 0.18

                SlideBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        tw(Knob, {Size=UDim2.new(0,18,0,18)}, 0.15)
                    end
                end)
                UIS.InputEnded:Connect(function(inp)
                    if (inp.UserInputType == Enum.UserInputType.MouseButton1
                    or  inp.UserInputType == Enum.UserInputType.Touch)
                    and sliding then
                        sliding = false
                        curPct  = tgPct
                        local si = TweenInfo.new(0.3,
                            Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        TS:Create(Fill, si, {Size=UDim2.new(tgPct,0,1,0)}):Play()
                        TS:Create(Knob, si, {Position=UDim2.new(tgPct,-7,0.5,-7)}):Play()
                        tw(Knob, {Size=UDim2.new(0,14,0,14)}, 0.2)
                    end
                end)
                UIS.InputChanged:Connect(function(inp)
                    if sliding
                    and (inp.UserInputType == Enum.UserInputType.MouseMovement
                    or   inp.UserInputType == Enum.UserInputType.Touch) then
                        tgPct = math.clamp(
                            (inp.Position.X - Track.AbsolutePosition.X)
                            / Track.AbsoluteSize.X, 0, 1)
                    end
                end)
                RS.RenderStepped:Connect(function()
                    if not sliding then return end
                    local d = tgPct - curPct
                    if math.abs(d) > 0.001 then
                        curPct = curPct + d * LERP
                        Fill.Size     = UDim2.new(curPct,0,1,0)
                        Knob.Position = UDim2.new(curPct,-7,0.5,-7)
                        val = math.floor(min + (max-min)*curPct)
                        VLbl.Text = tostring(val)
                        callback(val)
                    end
                end)

                local API = {}
                function API:Set(vv)
                    val   = math.clamp(vv, min, max)
                    pct   = (val-min)/(max-min)
                    tgPct = pct; curPct = pct
                    VLbl.Text = tostring(val)
                    tw(Fill, {Size=UDim2.new(pct,0,1,0)})
                    tw(Knob, {Position=UDim2.new(pct,-7,0.5,-7)})
                    callback(val)
                end
                return API
            end

            -- BUTTON
            function Section:CreateButton(text, callback)
                callback = callback or function() end

                local F = make("Frame", {
                    Size=UDim2.new(1,0,0,34),
                    BackgroundTransparency=1,
                    Parent=Items,
                })
                local BG = make("Frame", {
                    Size=UDim2.new(1,0,1,0),
                    BackgroundColor3=Color3.new(1,1,1),
                    Parent=F,
                })
                corner(BG, UDim.new(0,7))
                bgGrad(BG, 135)

                local BLbl = make("TextLabel", {
                    Size=UDim2.new(1,0,1,0),
                    BackgroundTransparency=1,
                    Text=text,
                    TextColor3=Color3.new(1,1,1),
                    TextSize=13, Font=C.SubF,
                    ZIndex=2, Parent=BG,
                })
                textShim(BLbl)

                local Btn = make("TextButton", {
                    Size=UDim2.new(1,0,1,0),
                    BackgroundTransparency=1,
                    Text="", ZIndex=3,
                    Parent=BG,
                })
                Btn.MouseButton1Click:Connect(function()
                    tw(BG, {BackgroundTransparency=0.4}, 0.1)
                    task.wait(0.12)
                    tw(BG, {BackgroundTransparency=0}, 0.2)
                    callback()
                end)
            end

            -- TEXTBOX
            function Section:CreateTextBox(text, placeholder, callback)
                callback = callback or function() end

                local F = make("Frame", {
                    Size=UDim2.new(1,0,0,32),
                    BackgroundTransparency=1,
                    Parent=Items,
                })
                make("TextLabel", {
                    Size=UDim2.new(0.38,0,1,0),
                    BackgroundTransparency=1,
                    Text=text, TextColor3=C.Text,
                    TextSize=13, Font=C.SubF,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    Parent=F,
                })
                local BoxBG = make("Frame", {
                    Size=UDim2.new(0.62,0,0,26),
                    Position=UDim2.new(0.38,0,0.5,-13),
                    BackgroundColor3=C.Main,
                    Parent=F,
                })
                corner(BoxBG, UDim.new(0,6))
                stroke(BoxBG, C.Border, 1)

                local Box = make("TextBox", {
                    Size=UDim2.new(1,-12,1,0),
                    Position=UDim2.new(0,6,0,0),
                    BackgroundTransparency=1,
                    Text="",
                    PlaceholderText=placeholder or "...",
                    PlaceholderColor3=C.Sub,
                    TextColor3=C.Text,
                    TextSize=12, Font=C.SubF,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    ClearTextOnFocus=false,
                    Parent=BoxBG,
                })
                Box.Focused:Connect(function()
                    tw(BoxBG, {BackgroundColor3=C.Sec}, 0.15)
                end)
                Box.FocusLost:Connect(function(enter)
                    tw(BoxBG, {BackgroundColor3=C.Main}, 0.15)
                    if enter then callback(Box.Text) end
                end)

                local API = {}
                function API:Set(vv) Box.Text = vv end
                return API
            end

            -- COLOR PICKER
            function Section:CreateColorPicker(text, default, callback)
                callback = callback or function() end
                local col   = default or Color3.fromRGB(255,0,0)
                local open  = false
                local h, s, v = col:ToHSV()

                local F = make("Frame", {
                    Size=UDim2.new(1,0,0,32),
                    BackgroundTransparency=1,
                    ClipsDescendants=false,
                    Parent=Items,
                })
                make("TextLabel", {
                    Size=UDim2.new(1,-40,0,32),
                    BackgroundTransparency=1,
                    Text=text, TextColor3=C.Text,
                    TextSize=13, Font=C.SubF,
                    TextXAlignment=Enum.TextXAlignment.Left,
                    Parent=F,
                })
                local Preview = make("TextButton", {
                    Size=UDim2.new(0,28,0,20),
                    Position=UDim2.new(1,-28,0,6),
                    BackgroundColor3=col,
                    Text="", AutoButtonColor=false,
                    Parent=F,
                })
                corner(Preview, UDim.new(0,5))
                stroke(Preview, C.Border, 1)

                local Panel = make("Frame", {
                    Size=UDim2.new(1,0,0,0),
                    Position=UDim2.new(0,0,0,34),
                    BackgroundColor3=C.Main,
                    ClipsDescendants=true,
                    Parent=F,
                })
                corner(Panel, UDim.new(0,8))
                stroke(Panel, C.Border, 1)

                local Field = make("ImageLabel", {
                    Size=UDim2.new(1,-44,0,100),
                    Position=UDim2.new(0,8,0,8),
                    BackgroundColor3=Color3.fromHSV(h,1,1),
                    Image="rbxassetid://4155801252",
                    Parent=Panel,
                })
                corner(Field, UDim.new(0,4))
                local FBtn = make("TextButton", {
                    Size=UDim2.new(1,0,1,0),
                    BackgroundTransparency=1, Text="",
                    Parent=Field,
                })
                local SVDot = make("Frame", {
                    Size=UDim2.new(0,10,0,10),
                    Position=UDim2.new(s,-5,1-v,-5),
                    BackgroundTransparency=1,
                    Parent=Field,
                })
                corner(SVDot, UDim.new(1,0))
                stroke(SVDot, Color3.new(1,1,1), 2)

                local HBar = make("Frame", {
                    Size=UDim2.new(0,20,0,100),
                    Position=UDim2.new(1,-28,0,8),
                    Parent=Panel,
                })
                corner(HBar, UDim.new(0,4))
                make("UIGradient", {
                    Color=ColorSequence.new({
                        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,0,0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
                        ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0,255,255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
                        ColorSequenceKeypoint.new(1,    Color3.fromRGB(255,0,0)),
                    }),
                    Rotation=90, Parent=HBar,
                })
                local HBtn = make("TextButton", {
                    Size=UDim2.new(1,0,1,0),
                    BackgroundTransparency=1, Text="",
                    Parent=HBar,
                })
                local HCur = make("Frame", {
                    Size=UDim2.new(1,4,0,4),
                    Position=UDim2.new(0,-2,h,-2),
                    BackgroundColor3=Color3.new(1,1,1),
                    Parent=HBar,
                })
                corner(HCur, UDim.new(1,0))

                local RGBRow = make("Frame", {
                    Size=UDim2.new(1,-16,0,22),
                    Position=UDim2.new(0,8,0,114),
                    BackgroundTransparency=1,
                    Parent=Panel,
                })

                local function mkInp(lbl, px, vv)
                    local cc = make("Frame", {
                        Size=UDim2.new(0.27,0,1,0),
                        Position=UDim2.new(px,0,0,0),
                        BackgroundTransparency=1,
                        Parent=RGBRow,
                    })
                    make("TextLabel", {
                        Size=UDim2.new(0,12,1,0),
                        BackgroundTransparency=1,
                        Text=lbl, TextColor3=C.Sub,
                        TextSize=10, Font=C.Font,
                        Parent=cc,
                    })
                    local bg2 = make("Frame", {
                        Size=UDim2.new(1,-14,1,0),
                        Position=UDim2.new(0,14,0,0),
                        BackgroundColor3=C.Sec,
                        Parent=cc,
                    })
                    corner(bg2, UDim.new(0,4))
                    local tb = make("TextBox", {
                        Size=UDim2.new(1,-4,1,0),
                        Position=UDim2.new(0,2,0,0),
                        BackgroundTransparency=1,
                        Text=tostring(vv),
                        TextColor3=C.Text,
                        TextSize=10, Font=C.SubF,
                        Parent=bg2,
                    })
                    return tb
                end

                local RI = mkInp("R", 0,    math.floor(col.R*255))
                local GI = mkInp("G", 0.27, math.floor(col.G*255))
                local BI = mkInp("B", 0.54, math.floor(col.B*255))

                -- Rainbow toggle
                local RBHolder = make("Frame", {
                    Size=UDim2.new(0,38,1,0),
                    Position=UDim2.new(1,-38,0,0),
                    BackgroundTransparency=1,
                    Parent=RGBRow,
                })
                make("TextLabel", {
                    Size=UDim2.new(1,0,0.5,0),
                    BackgroundTransparency=1,
                    Text="RGB", TextColor3=C.Sub,
                    TextSize=8, Font=C.Font,
                    TextXAlignment=Enum.TextXAlignment.Center,
                    Parent=RBHolder,
                })
                local RBTrack = make("Frame", {
                    Size=UDim2.new(0,28,0,14),
                    Position=UDim2.new(0.5,-14,1,-14),
                    BackgroundColor3=C.Border,
                    Parent=RBHolder,
                })
                corner(RBTrack, UDim.new(1,0))
                local RBCircle = make("Frame", {
                    Size=UDim2.new(0,10,0,10),
                    Position=UDim2.new(0,2,0.5,-5),
                    BackgroundColor3=Color3.new(1,1,1),
                    Parent=RBTrack,
                })
                corner(RBCircle, UDim.new(1,0))
                local RBGrad = make("UIGradient", {
                    Color=ColorSequence.new({
                        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,0,0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
                        ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0,255,255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
                        ColorSequenceKeypoint.new(1,    Color3.fromRGB(255,0,0)),
                    }),
                    Rotation=0, Enabled=false,
                    Parent=RBTrack,
                })
                local RBBtn = make("TextButton", {
                    Size=UDim2.new(1,0,1,0),
                    BackgroundTransparency=1,
                    Text="", ZIndex=2,
                    Parent=RBTrack,
                })

                local rainbow = false
                local rbConn  = nil
                local rbHue   = 0

                local function setRainbow(state)
                    rainbow = state
                    if state then
                        RBGrad.Enabled = true
                        tw(RBCircle, {Position=UDim2.new(1,-12,0.5,-5)}, 0.2)
                        rbConn = RS.RenderStepped:Connect(function(dt)
                            rbHue = (rbHue + dt * 0.35) % 1
                            local rc = Color3.fromHSV(rbHue, 1, 1)
                            col = rc; h = rbHue; s = 1; v = 1
                            Field.BackgroundColor3   = rc
                            SVDot.Position           = UDim2.new(1,-5,0,-5)
                            HCur.Position            = UDim2.new(0,-2,rbHue,-2)
                            Preview.BackgroundColor3 = rc
                            RI.Text = tostring(math.floor(rc.R*255))
                            GI.Text = tostring(math.floor(rc.G*255))
                            BI.Text = tostring(math.floor(rc.B*255))
                            callback(rc)
                        end)
                    else
                        if rbConn then rbConn:Disconnect(); rbConn = nil end
                        RBGrad.Enabled = false
                        tw(RBCircle, {Position=UDim2.new(0,2,0.5,-5)}, 0.2)
                        tw(RBTrack,  {BackgroundColor3=C.Border}, 0.2)
                    end
                end

                RBBtn.MouseButton1Click:Connect(function()
                    setRainbow(not rainbow)
                end)

                local function refresh()
                    if rainbow then return end
                    col = Color3.fromHSV(h, s, v)
                    Preview.BackgroundColor3 = col
                    Field.BackgroundColor3   = Color3.fromHSV(h,1,1)
                    SVDot.Position = UDim2.new(s,-5,1-v,-5)
                    HCur.Position  = UDim2.new(0,-2,h,-2)
                    RI.Text = tostring(math.floor(col.R*255))
                    GI.Text = tostring(math.floor(col.G*255))
                    BI.Text = tostring(math.floor(col.B*255))
                    callback(col)
                end

                local pSV, pH = false, false
                FBtn.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then pSV=true end
                end)
                HBtn.InputBegan:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then pH=true end
                end)
                UIS.InputEnded:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseButton1 then
                        pSV=false; pH=false
                    end
                end)
                UIS.InputChanged:Connect(function(i)
                    if i.UserInputType==Enum.UserInputType.MouseMovement then
                        if pSV then
                            s = math.clamp(
                                (i.Position.X-Field.AbsolutePosition.X)/Field.AbsoluteSize.X,0,1)
                            v = 1-math.clamp(
                                (i.Position.Y-Field.AbsolutePosition.Y)/Field.AbsoluteSize.Y,0,1)
                            refresh()
                        elseif pH then
                            h = math.clamp(
                                (i.Position.Y-HBar.AbsolutePosition.Y)/HBar.AbsoluteSize.Y,0,1)
                            refresh()
                        end
                    end
                end)

                for _, inp in ipairs({RI, GI, BI}) do
                    inp.FocusLost:Connect(function()
                        local r2 = math.clamp(tonumber(RI.Text) or 0, 0, 255)
                        local g2 = math.clamp(tonumber(GI.Text) or 0, 0, 255)
                        local b2 = math.clamp(tonumber(BI.Text) or 0, 0, 255)
                        col = Color3.fromRGB(r2, g2, b2)
                        h, s, v = col:ToHSV()
                        refresh()
                    end)
                end

                -- Closing panel does NOT stop rainbow
                Preview.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        tw(F,     {Size=UDim2.new(1,0,0,190)})
                        tw(Panel, {Size=UDim2.new(1,0,0,155)})
                    else
                        -- rainbow keeps running even when panel is hidden
                        tw(F,     {Size=UDim2.new(1,0,0,32)})
                        tw(Panel, {Size=UDim2.new(1,0,0,0)})
                    end
                end)

                local API = {}
                function API:Set(c)
                    setRainbow(false)
                    col=c; h,s,v=c:ToHSV(); refresh()
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
