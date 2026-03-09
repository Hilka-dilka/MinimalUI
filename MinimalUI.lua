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
║   Usage:                                                     ║
║   local UI = loadstring(game:HttpGet(                        ║
║     "https://raw.githubusercontent.com/" ..                  ║
║     "Hilka-dilka/MinimalUI/main/MinimalUI.lua"               ║
║   ))()                                                       ║
║   local W   = UI:CreateWindow("My Hub")                      ║
║   local Tab = W:CreateTab("Combat")                          ║
║   local Sec = Tab:CreateSection("Aura")                      ║
║   Sec:CreateToggle("Kill Aura", false, function(v) end)      ║
║   Sec:CreateSlider("Reach", 5, 50, 15, function(v) end)      ║
║   Sec:CreateButton("Reset", function() end)                  ║
║   Sec:CreateDualButton("A","B","left",function(s) end)       ║
║   Sec:CreateTextBox("Player","...",function(t) end)          ║
║   Sec:CreateKeybind("Key",Enum.KeyCode.F,function(k) end)    ║
║   Sec:CreateColorPicker("Color",Color3.new(1,0,0),cb)        ║
║   W:SetTheme(Color3)        -- accent color + shimmer        ║
║   W:SetMenuTheme("dark")    -- or "light"                    ║
║   W:SetKey(Enum.KeyCode.X)  -- toggle hotkey                 ║
╚══════════════════════════════════════════════════════════════╝
]]

local MinimalUI = {}

-- ─── Services ────────────────────────────────────────────────
local TS  = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS  = game:GetService("RunService")
local LP  = game:GetService("Players").LocalPlayer

-- ─── Accent theme (shared table — closures read T.A / T.A2) ──
local T = {
    A  = Color3.fromRGB(124, 58, 237),
    A2 = Color3.new(1, 1, 1),
    ON = Color3.new(1, 1, 1),
}

-- ─── Menu theme (colours, updated by SetMenuTheme) ───────────
local M = {
    Main   = Color3.fromRGB(19,  19,  31),
    Sec    = Color3.fromRGB(26,  26,  42),
    Text   = Color3.fromRGB(228, 228, 231),
    Sub    = Color3.fromRGB(120, 120, 150),
    Border = Color3.fromRGB(40,  40,  60),
    Font   = Enum.Font.GothamSemibold,
    SubF   = Enum.Font.Gotham,
}

-- ─── Shimmer engine ──────────────────────────────────────────
local SFPS = 1/30
local SAMP = 0.75
local SSPD = 0.035

local function calcA2(c)
    if c.R > 0.82 and c.G > 0.82 and c.B > 0.82 then
        return Color3.fromRGB(25, 25, 38)
    end
    return Color3.new(1, 1, 1)
end

local function calcON(c)
    if c.R > 0.82 and c.G > 0.82 and c.B > 0.82 then
        return Color3.fromRGB(26, 26, 46)
    end
    return Color3.new(1, 1, 1)
end

local function shimCS()
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0,   T.A),
        ColorSequenceKeypoint.new(0.5, T.A2),
        ColorSequenceKeypoint.new(1,   T.A),
    })
end

local function textShimCS()
    local h, s, v = T.A:ToHSV()
    local dark = Color3.fromHSV(h, math.min(1, s * 0.7), math.max(0, v * 0.45))
    local mid  = Color3.fromHSV(h, math.min(1, s * 0.18), 0.92)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0,   dark),
        ColorSequenceKeypoint.new(0.5, mid),
        ColorSequenceKeypoint.new(1,   dark),
    })
end

local function spawnShim(grad, isText, phase)
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
    lbl.TextColor3 = Color3.new(1, 1, 1)
    local g = Instance.new("UIGradient")
    g.Color    = textShimCS()
    g.Rotation = 0
    g.Parent   = lbl
    spawnShim(g, true, phase)
    return g
end

-- ─── Registries (reset per CreateWindow) ─────────────────────
local bgGrads  = {}
local mMain    = {}
local mSec     = {}
local mText    = {}
local mSub     = {}
local mBorder  = {}
local mStroke  = {}
local toggleReg = {}
local tabReg    = {}
local sepReg    = {}

local function bgGrad(parent, rot)
    local g = Instance.new("UIGradient")
    g.Color    = ColorSequence.new(T.A, T.A2)
    g.Rotation = rot or 135
    g.Parent   = parent
    table.insert(bgGrads, g)
    return g
end

-- ─── Helpers ─────────────────────────────────────────────────
local function tw(obj, props, dur, style, dir)
    TS:Create(obj, TweenInfo.new(
        dur   or 0.25,
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
    return make("UICorner", {CornerRadius = r or UDim.new(0, 8), Parent = p})
end

local function mkStroke(p, col, th, tr)
    local s = make("UIStroke", {
        Color = col or M.Border,
        Thickness = th or 1,
        Transparency = tr or 0.5,
        Parent = p,
    })
    table.insert(mStroke, s)
    return s
end

-- thin separator line between elements
local function mkSep(parent)
    local s = make("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = M.Border,
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        Parent = parent,
    })
    table.insert(mBorder, s)
    return s
end

-- ─── Draggable ───────────────────────────────────────────────
local function draggable(frame, handle)
    local drag = false
    local di, ds, sp
    local tx, ty, cx, cy = 0, 0, 0, 0
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = inp.Position; sp = frame.Position
            tx = sp.X.Offset; ty = sp.Y.Offset
            cx = tx; cy = ty
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then drag = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then di = inp end
    end)
    UIS.InputChanged:Connect(function(inp)
        if inp == di and drag then
            local d = inp.Position - ds
            tx = sp.X.Offset + d.X; ty = sp.Y.Offset + d.Y
        end
    end)
    RS.RenderStepped:Connect(function()
        local dx = tx - cx; local dy = ty - cy
        if math.abs(dx) > 0.1 or math.abs(dy) > 0.1 then
            cx = cx + dx * 0.14; cy = cy + dy * 0.14
            frame.Position = UDim2.new(sp and sp.X.Scale or 0.5, cx, sp and sp.Y.Scale or 0.5, cy)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  SetTheme
-- ═══════════════════════════════════════════════════════════════
function MinimalUI:SetTheme(color)
    T.A  = color
    T.A2 = calcA2(color)
    T.ON = calcON(color)
    local seq = ColorSequence.new(T.A, T.A2)
    for _, g in ipairs(bgGrads) do
        if g and g.Parent then g.Color = seq end
    end
    for _, t in ipairs(toggleReg) do
        if t.bg and t.bg.Parent and t.stateRef.v then
            tw(t.bg, {BackgroundColor3 = T.A}, 0.35)
        end
    end
    local tabSeq = ColorSequence.new(T.A, T.A2)
    for _, t in ipairs(tabReg) do
        if t.grad and t.grad.Parent then
            t.grad.Color = tabSeq
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  CreateWindow
-- ═══════════════════════════════════════════════════════════════
function MinimalUI:CreateWindow(title)
    T.A = Color3.fromRGB(124, 58, 237)
    T.A2 = Color3.new(1, 1, 1)
    T.ON = Color3.new(1, 1, 1)
    bgGrads = {}; mMain = {}; mSec = {}; mText = {}
    mSub = {}; mBorder = {}; mStroke = {}
    toggleReg = {}; tabReg = {}; sepReg = {}

    local old = LP.PlayerGui:FindFirstChild("MinimalUI")
    if old then old:Destroy() end

    local GUI = make("ScreenGui", {
        Name = "MinimalUI", Parent = LP.PlayerGui,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
    })

    local Main = make("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 580, 0, 400),
        Position = UDim2.new(0.5, -290, 0.5, -200),
        BackgroundColor3 = M.Main,
        Parent = GUI,
    })
    corner(Main, UDim.new(0, 12))
    table.insert(mMain, Main)

    local TBar = make("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Parent = Main,
    })
    draggable(Main, TBar)

    local TLbl = make("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = title or "MinimalUI",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 15, Font = M.Font,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = TBar,
    })
    textShim(TLbl, 0)

    make("Frame", {
        Size = UDim2.new(1, -24, 0, 1),
        Position = UDim2.new(0, 12, 1, 0),
        BackgroundColor3 = M.Border,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Parent = TBar,
    })

    -- macOS dots
    local DotsF = make("Frame", {
        Size = UDim2.new(0, 60, 0, 14),
        Position = UDim2.new(0, 14, 0.5, -7),
        BackgroundTransparency = 1,
        Parent = TBar,
    })
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 7),
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = DotsF,
    })
    local function dot(col, ord)
        local d = make("TextButton", {
            Size = UDim2.new(0, 13, 0, 13),
            BackgroundColor3 = col,
            Text = "", AutoButtonColor = false,
            LayoutOrder = ord, Parent = DotsF,
        })
        corner(d, UDim.new(1, 0))
        return d
    end
    local DotC = dot(Color3.fromRGB(255, 95,  87),  1)
    local DotM = dot(Color3.fromRGB(255, 189, 46),  2)
    local DotX = dot(Color3.fromRGB(40,  200, 64),  3)

    DotC.MouseButton1Click:Connect(function()
        tw(Main, {Size = UDim2.new(0, 580, 0, 0)}, 0.3)
        task.wait(0.3); GUI:Destroy()
    end)
    local minimized = false
    DotM.MouseButton1Click:Connect(function()
        minimized = not minimized
        tw(Main, {Size = minimized and UDim2.new(0, 580, 0, 44) or UDim2.new(0, 580, 0, 400)}, 0.3)
    end)
    local maximized = false
    DotX.MouseButton1Click:Connect(function()
        maximized = not maximized
        if minimized then minimized = false end
        tw(Main, {Size = maximized and UDim2.new(0, 800, 0, 550) or UDim2.new(0, 580, 0, 400)}, 0.35)
    end)

    local Body = make("Frame", {
        Size = UDim2.new(1, 0, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = Main,
    })

    local TabBar = make("Frame", {
        Size = UDim2.new(0, 140, 1, -12),
        Position = UDim2.new(0, 8, 0, 6),
        BackgroundColor3 = M.Sec,
        BackgroundTransparency = 0.3,
        Parent = Body,
    })
    corner(TabBar)
    table.insert(mSec, TabBar)
    make("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabBar,
    })
    make("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = TabBar,
    })

    local ContentBox = make("Frame", {
        Size = UDim2.new(1, -164, 1, -12),
        Position = UDim2.new(0, 156, 0, 6),
        BackgroundTransparency = 1,
        Parent = Body,
    })

    local visKey = Enum.KeyCode.RightControl
    local visible = true
    UIS.InputBegan:Connect(function(inp, gpe)
        if not gpe and inp.KeyCode == visKey then
            visible = not visible; GUI.Enabled = visible
        end
    end)

    local Window = {Tabs = {}, GUI = GUI}
    function Window:SetKey(k) visKey = k end
    function Window:SetTheme(color) MinimalUI:SetTheme(color) end

    -- ── SetMenuTheme ──────────────────────────────────────────
    function Window:SetMenuTheme(theme)
        local dark = theme ~= "light"
        local newMain   = dark and Color3.fromRGB(19, 19, 31)   or Color3.fromRGB(240, 240, 245)
        local newSec    = dark and Color3.fromRGB(26, 26, 42)   or Color3.fromRGB(215, 215, 228)
        local newText   = dark and Color3.fromRGB(228, 228, 231) or Color3.fromRGB(20, 20, 40)
        local newSub    = dark and Color3.fromRGB(120, 120, 150) or Color3.fromRGB(90, 90, 120)
        local newBorder = dark and Color3.fromRGB(40, 40, 60)   or Color3.fromRGB(170, 170, 195)

        M.Main   = newMain
        M.Sec    = newSec
        M.Text   = newText
        M.Sub    = newSub
        M.Border = newBorder

        for _, o in ipairs(mMain)   do if o and o.Parent then tw(o, {BackgroundColor3 = newMain},   0.35) end end
        for _, o in ipairs(mSec)    do if o and o.Parent then tw(o, {BackgroundColor3 = newSec},    0.35) end end
        for _, o in ipairs(mText)   do if o and o.Parent then tw(o, {TextColor3 = newText},         0.35) end end
        for _, o in ipairs(mSub)    do if o and o.Parent then tw(o, {TextColor3 = newSub},          0.35) end end
        for _, o in ipairs(mBorder) do if o and o.Parent then tw(o, {BackgroundColor3 = newBorder}, 0.35) end end
        for _, o in ipairs(mStroke) do if o and o.Parent then tw(o, {Color = newBorder},            0.35) end end

        for _, t in ipairs(toggleReg) do
            if t.bg and t.bg.Parent and not t.stateRef.v then
                tw(t.bg, {BackgroundColor3 = newBorder}, 0.35)
            end
        end
    end

    -- ── Tab switching ─────────────────────────────────────────
    local switching = false
    local curTab    = nil

    function Window:CreateTab(name)
        local Tab = {Sections = {}}

        local TBtn = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Parent = TabBar,
        })
        corner(TBtn, UDim.new(0, 7))

        local TGrad = make("UIGradient", {
            Color = ColorSequence.new(T.A, T.A2),
            Rotation = 135,
            Enabled = false,
            Parent = TBtn,
        })
        table.insert(bgGrads, TGrad)

        local TLblBtn = make("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = M.Sub,
            TextSize = 13, Font = M.SubF,
            ZIndex = 2,
            Parent = TBtn,
        })
        table.insert(mSub, TLblBtn)

        local TLblGrad = make("UIGradient", {
            Color = shimCS(),
            Enabled = false,
            Parent = TLblBtn,
        })
        spawnShim(TLblGrad, true)

        local tabEntry = {grad = TGrad, lbl = TLblBtn, isActive = false}
        table.insert(tabReg, tabEntry)

        local Wrapper = make("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ClipsDescendants = true,
            Visible = false,
            Parent = ContentBox,
        })
        local Scroll = make("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = T.A,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = Wrapper,
        })
        make("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Scroll,
        })
        make("UIPadding", {
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
            Parent = Scroll,
        })

        local function activate()
            if switching or curTab == Tab then return end
            switching = true

            for _, t in ipairs(Window.Tabs) do
                t.Btn.BackgroundTransparency = 1
                t.TGrad.Enabled   = false
                t.LblGrad.Enabled = false
                t.Lbl.TextColor3  = M.Sub
                for _, te in ipairs(tabReg) do
                    if te.lbl == t.Lbl then te.isActive = false end
                end
            end

            TBtn.BackgroundTransparency = 0
            TGrad.Enabled    = true
            TGrad.Color      = ColorSequence.new(T.A, T.A2)
            TLblGrad.Enabled = true
            TLblBtn.TextColor3 = Color3.new(1, 1, 1)
            tabEntry.isActive  = true

            if curTab and curTab.Wrapper.Visible then
                local ow = curTab.Wrapper
                tw(ow, {Position = UDim2.new(0, 0, 0, -8)}, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
                for _, d in ipairs(ow:GetDescendants()) do
                    if d:IsA("TextLabel") or d:IsA("TextButton") then
                        tw(d, {TextTransparency = 1}, 0.12)
                    end
                end
                task.wait(0.16)
                ow.Visible  = false
                ow.Position = UDim2.new(0, 0, 0, 0)
                for _, d in ipairs(ow:GetDescendants()) do
                    if d:IsA("TextLabel") or d:IsA("TextButton") then
                        d.TextTransparency = 0
                    end
                end
            end

            Wrapper.Position = UDim2.new(0, 0, 0, 12)
            Wrapper.Visible  = true
            for _, d in ipairs(Wrapper:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") then
                    d.TextTransparency = 1
                end
            end
            tw(Wrapper, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            for _, d in ipairs(Wrapper:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") then
                    tw(d, {TextTransparency = 0}, 0.3)
                end
            end
            task.wait(0.3)
            curTab    = Tab
            switching = false
        end

        TBtn.MouseButton1Click:Connect(activate)

        if #Window.Tabs == 0 then
            Wrapper.Visible = true
            TBtn.BackgroundTransparency = 0
            TGrad.Enabled    = true
            TGrad.Color      = ColorSequence.new(T.A, T.A2)
            TLblGrad.Enabled = true
            TLblBtn.TextColor3 = Color3.new(1, 1, 1)
            tabEntry.isActive  = true
            curTab = Tab
        end

        Tab.Btn     = TBtn
        Tab.TGrad   = TGrad
        Tab.Lbl     = TLblBtn
        Tab.LblGrad = TLblGrad
        Tab.Wrapper = Wrapper
        Tab.Scroll  = Scroll

        -- ── CreateSection ─────────────────────────────────────
        function Tab:CreateSection(secName)
            local Section  = {}
            local elemCount = 0
            local lastElementType = nil

            local SFrame = make("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = M.Sec,
                BackgroundTransparency = 0.3,
                Parent = Scroll,
            })
            corner(SFrame, UDim.new(0, 10))
            mkStroke(SFrame, M.Border, 1, 0.5)
            table.insert(mSec, SFrame)

            make("UIListLayout", {
                Padding = UDim.new(0, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = SFrame,
            })

            local HeaderBtn = make("TextButton", {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundTransparency = 1,
                Text = "",
                LayoutOrder = 1,
                AutoButtonColor = false,
                Parent = SFrame,
            })

            local Arrow = make("TextLabel", {
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -24, 0, 0),
                BackgroundTransparency = 1,
                Text = "▾",
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 14, Font = M.Font,
                Parent = HeaderBtn,
            })
            textShim(Arrow)

            local STitle = make("TextLabel", {
                Size = UDim2.new(1, -28, 1, 0),
                Position = UDim2.new(0, 4, 0, 0),
                BackgroundTransparency = 1,
                Text = string.upper(secName),
                TextColor3 = Color3.new(1, 1, 1),
                TextSize = 11, Font = M.Font,
                TextXAlignment = Enum.TextXAlignment.Center,
                Parent = HeaderBtn,
            })
            textShim(STitle)

            local Sep = make("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = M.Border,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                LayoutOrder = 2,
                Parent = SFrame,
            })
            table.insert(mBorder, Sep)

            local Items = make("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                LayoutOrder = 3,
                Parent = SFrame,
            })
            make("UIListLayout", {
                Padding = UDim.new(0, 0),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = Items,
            })
            make("UIPadding", {
                PaddingTop    = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft   = UDim.new(0, 10),
                PaddingRight  = UDim.new(0, 10),
                Parent = Items,
            })

            -- collapse/expand
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
                            tw(d, {TextTransparency = 1}, 0.15)
                        end
                    end
                    task.wait(0.15)
                    Items.AutomaticSize = Enum.AutomaticSize.None
                    Items.Size = UDim2.new(1, 0, 0, naturalH)
                    Sep.Visible = false
                    tw(Items, {Size = UDim2.new(1, 0, 0, 0)}, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                    task.wait(0.26)
                    Items.Visible = false
                    Arrow.Text   = "▸"
                    collapsed    = true
                else
                    Items.Visible = true
                    Items.Size    = UDim2.new(1, 0, 0, 0)
                    Items.AutomaticSize = Enum.AutomaticSize.None
                    Sep.Visible = true
                    for _, d in ipairs(Items:GetDescendants()) do
                        if d:IsA("TextLabel") or d:IsA("TextButton") then
                            d.TextTransparency = 1
                        end
                    end
                    tw(Items, {Size = UDim2.new(1, 0, 0, naturalH)}, 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                    task.wait(0.28)
                    Items.AutomaticSize = Enum.AutomaticSize.Y
                    for _, d in ipairs(Items:GetDescendants()) do
                        if d:IsA("TextLabel") or d:IsA("TextButton") then
                            tw(d, {TextTransparency = 0}, 0.2)
                        end
                    end
                    Arrow.Text = "▾"
                    collapsed  = false
                end
                collapsing = false
            end)



local function addSep(currentElementType)
    elemCount = elemCount + 1
    if elemCount > 1 then
        -- Стандартные отступы для всех элементов
        local topMargin = 4    -- отступ ОТ предыдущего элемента ДО верхнего разделителя
        local bottomMargin = 4 -- отступ ОТ текущего элемента ДО нижнего разделителя
        
        -- ЕСЛИ ЭТО СЛАЙДЕР - настраиваем его личные отступы
        if currentElementType == "slider" then
            topMargin = 4     -- отступ ОТ предыдущего элемента ДО верхнего разделителя
            bottomMargin = 8  -- отступ ОТ слайдера ДО нижнего разделителя
        end
        
        -- Отступ ОТ предыдущего элемента ДО верхнего разделителя
        local spacingTop = make("Frame", {
            Size = UDim2.new(1, 0, 0, topMargin),
            BackgroundTransparency = 1,
            Parent = Items,
        })
        
        -- Верхний разделитель
        mkSep(Items)
        
        -- ЗДЕСЬ БУДЕТ СОЗДАВАТЬСЯ САМ ЭЛЕМЕНТ
        
        -- Отступ ОТ элемента ДО нижнего разделителя
        local spacingBottom = make("Frame", {
            Size = UDim2.new(1, 0, 0, bottomMargin),
            BackgroundTransparency = 1,
            Parent = Items,
        })
    end
end

            -- ── TOGGLE ───────────────────────────────────────
            function Section:CreateToggle(text, default, callback)
                callback = callback or function() end
                local stateRef = {v = default or false}
                addSep("toggle")

                local F = make("Frame", {
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1,
                    Parent = Items,
                })
                local Lbl = make("TextLabel", {
                    Size = UDim2.new(1, -50, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = M.Text,
                    TextSize = 13, Font = M.SubF,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = F,
                })
                table.insert(mText, Lbl)

                local BG = make("Frame", {
                    Size = UDim2.new(0, 38, 0, 20),
                    Position = UDim2.new(1, -38, 0.5, -10),
                    BackgroundColor3 = stateRef.v and T.A or M.Border,
                    Parent = F,
                })
                corner(BG, UDim.new(1, 0))
                table.insert(toggleReg, {bg = BG, stateRef = stateRef})

                local Circle = make("Frame", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = stateRef.v
                        and UDim2.new(1, -18, 0.5, -8)
                        or  UDim2.new(0, 2, 0.5, -8),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Parent = BG,
                })
                corner(Circle, UDim.new(1, 0))

                local Btn = make("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = F,
                })
                Btn.MouseButton1Click:Connect(function()
                    stateRef.v = not stateRef.v
                    tw(BG, {BackgroundColor3 = stateRef.v and T.A or M.Border})
                    tw(Circle, {Position = stateRef.v
                        and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
                    callback(stateRef.v)
                end)

                local API = {}
                function API:Set(val)
                    stateRef.v = val
                    tw(BG, {BackgroundColor3 = val and T.A or M.Border})
                    tw(Circle, {Position = val
                        and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
                    callback(val)
                end
                return API
            end

            -- ── SLIDER ───────────────────────────────────────
            function Section:CreateSlider(text, min, max, default, callback)
                callback = callback or function() end
                local val = math.clamp(default or min, min, max)
                local pct = (val - min) / (max - min)
                addSep("slider")

                local F = make("Frame", {
                    Size = UDim2.new(1, 0, 0, 52),
                    BackgroundTransparency = 1,
                    Parent = Items,
                })

                local TopRow = make("Frame", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Parent = F,
                })
                local Lbl = make("TextLabel", {
                    Size = UDim2.new(1, -76, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = M.Text,
                    TextSize = 13, Font = M.SubF,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = TopRow,
                })
                table.insert(mText, Lbl)

                local ValHolder = make("Frame", {
                    Size = UDim2.new(0, 72, 1, 0),
                    Position = UDim2.new(1, -72, 0, 0),
                    BackgroundTransparency = 1,
                    Parent = TopRow,
                })

                local VBG = make("Frame", {
                    Size = UDim2.new(0, 56, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Parent = ValHolder,
                })
                corner(VBG, UDim.new(0, 5))
                bgGrad(VBG, 135)
                mkStroke(VBG, M.Border, 1, 0.45)
                table.insert(mMain, VBG)

                local VLbl = make("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(val),
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 13, Font = M.Font,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 2,
                    Parent = VBG,
                })
                textShim(VLbl)

                local VInput = make("TextBox", {
                    Size = UDim2.new(1, -4, 1, 0),
                    Position = UDim2.new(0, 2, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    TextColor3 = M.Text,
                    TextSize = 13, Font = M.Font,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Visible = false,
                    ClearTextOnFocus = true,
                    ZIndex = 3,
                    Parent = VBG,
                })
                local VBtn = make("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 4,
                    Parent = VBG,
                })

                -- Arrow up
                local ArrUpLbl = make("TextLabel", {
                    Size = UDim2.new(0, 14, 0.5, -1),
                    Position = UDim2.new(0, 58, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "▲",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 8, Font = M.Font,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Parent = ValHolder,
                })
                textShim(ArrUpLbl)
                local ArrUp = make("TextButton", {
                    Size = UDim2.new(0, 14, 0.5, -1),
                    Position = UDim2.new(0, 58, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 2,
                    Parent = ValHolder,
                })

                -- Arrow down
                local ArrDnLbl = make("TextLabel", {
                    Size = UDim2.new(0, 14, 0.5, -1),
                    Position = UDim2.new(0, 58, 0.5, 1),
                    BackgroundTransparency = 1,
                    Text = "▼",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 8, Font = M.Font,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Parent = ValHolder,
                })
                textShim(ArrDnLbl)
                local ArrDn = make("TextButton", {
                    Size = UDim2.new(0, 14, 0.5, -1),
                    Position = UDim2.new(0, 58, 0.5, 1),
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 2,
                    Parent = ValHolder,
                })

                local Track = make("Frame", {
                    Size = UDim2.new(1, 0, 0, 5),
                    Position = UDim2.new(0, 0, 0, 30),
                    BackgroundColor3 = M.Border,
                    Parent = F,
                })
                corner(Track, UDim.new(1, 0))
                table.insert(mBorder, Track)

                local Fill = make("Frame", {
                    Size = UDim2.new(pct, 0, 1, 0),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Parent = Track,
                })
                corner(Fill, UDim.new(1, 0))
                bgGrad(Fill, 0)

                local Knob = make("Frame", {
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(pct, -7, 0.5, -7),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    ZIndex = 2,
                    Parent = Track,
                })
                corner(Knob, UDim.new(1, 0))

                local SlideBtn = make("TextButton", {
                    Size = UDim2.new(1, 0, 0, 24),
                    Position = UDim2.new(0, 0, 0, 24),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = F,
                })

                local function updateSlider(newPct, snap)
                    pct = math.clamp(newPct, 0, 1)
                    val = math.floor(min + (max - min) * pct)
                    VLbl.Text = tostring(val)
                    if snap then
                        local si = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        TS:Create(Fill, si, {Size = UDim2.new(pct, 0, 1, 0)}):Play()
                        TS:Create(Knob, si, {Position = UDim2.new(pct, -7, 0.5, -7)}):Play()
                    else
                        Fill.Size     = UDim2.new(pct, 0, 1, 0)
                        Knob.Position = UDim2.new(pct, -7, 0.5, -7)
                    end
                    callback(val)
                end

                VBtn.MouseButton1Click:Connect(function()
                    VLbl.Visible = false; VBtn.Visible = false
                    VInput.Visible = true; VInput.Text = tostring(val)
                    VInput:CaptureFocus()
                end)
                VInput.FocusLost:Connect(function()
                    local n = tonumber(VInput.Text)
                    if n then
                        updateSlider((math.clamp(math.floor(n), min, max) - min) / (max - min), true)
                    end
                    VLbl.Visible = true; VBtn.Visible = true; VInput.Visible = false
                end)

                ArrUp.MouseButton1Click:Connect(function()
                    updateSlider((math.clamp(val + 1, min, max) - min) / (max - min), true)
                end)
                ArrDn.MouseButton1Click:Connect(function()
                    updateSlider((math.clamp(val - 1, min, max) - min) / (max - min), true)
                end)

                local sliding = false
                local tgPct   = pct
                local curPct  = pct

                SlideBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        tw(Knob, {Size = UDim2.new(0, 18, 0, 18)}, 0.15)
                    end
                end)
                UIS.InputEnded:Connect(function(inp)
                    if (inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch) and sliding then
                        sliding = false; curPct = tgPct
                        local si = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        TS:Create(Fill, si, {Size = UDim2.new(tgPct, 0, 1, 0)}):Play()
                        TS:Create(Knob, si, {Position = UDim2.new(tgPct, -7, 0.5, -7)}):Play()
                        tw(Knob, {Size = UDim2.new(0, 14, 0, 14)}, 0.2)
                    end
                end)
                UIS.InputChanged:Connect(function(inp)
                    if sliding and (inp.UserInputType == Enum.UserInputType.MouseMovement
                    or inp.UserInputType == Enum.UserInputType.Touch) then
                        tgPct = math.clamp(
                            (inp.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                    end
                end)
                RS.RenderStepped:Connect(function()
                    if not sliding then return end
                    local d = tgPct - curPct
                    if math.abs(d) > 0.001 then
                        curPct = curPct + d * 0.18
                        Fill.Size     = UDim2.new(curPct, 0, 1, 0)
                        Knob.Position = UDim2.new(curPct, -7, 0.5, -7)
                        val = math.floor(min + (max - min) * curPct)
                        VLbl.Text = tostring(val)
                        callback(val)
                    end
                end)

                local API = {}
                function API:Set(v)
                    val = math.clamp(v, min, max)
                    pct = (val - min) / (max - min)
                    tgPct = pct; curPct = pct
                    VLbl.Text = tostring(val)
                    tw(Fill, {Size = UDim2.new(pct, 0, 1, 0)})
                    tw(Knob, {Position = UDim2.new(pct, -7, 0.5, -7)})
                    callback(val)
                end
                return API
            end

            -- ── BUTTON ───────────────────────────────────────
            function Section:CreateButton(text, callback)
                callback = callback or function() end
                addSep('button')

                local F = make("Frame", {
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1,
                    Parent = Items,
                })
                local BG = make("Frame", {
                    Size = UDim2.new(1, 0, 0, 30),
                    Position = UDim2.new(0, 0, 0.5, -15),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Parent = F,
                })
                corner(BG, UDim.new(0, 7))
                bgGrad(BG, 135)
                mkStroke(BG, M.Border, 1, 0.45)

                local BLbl = make("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 13, Font = M.SubF,
                    ZIndex = 2,
                    Parent = BG,
                })
                textShim(BLbl)

                local Btn = make("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 3,
                    Parent = BG,
                })
                Btn.MouseButton1Click:Connect(function()
                    tw(BG, {BackgroundTransparency = 0.4}, 0.1)
                    task.wait(0.12)
                    tw(BG, {BackgroundTransparency = 0}, 0.2)
                    callback()
                end)
            end

            -- ── DUAL BUTTON ───────────────────────────────────
            function Section:CreateDualButton(leftText, rightText, default, callback)
                callback = callback or function() end
                local active = default or "left"
                addSep()

                local F = make("Frame", {
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1,
                    Parent = Items,
                })

                local LBG = make("Frame", {
                    Size = UDim2.new(0.5, -3, 0, 30),
                    Position = UDim2.new(0, 0, 0.5, -15),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Parent = F,
                })
                corner(LBG, UDim.new(0, 7))
                mkStroke(LBG, M.Border, 1, 0.45)

                local LGrad = Instance.new("UIGradient")
                LGrad.Color    = ColorSequence.new(T.A, T.A2)
                LGrad.Rotation = 135
                LGrad.Enabled  = active == "left"
                LGrad.Parent   = LBG
                table.insert(bgGrads, LGrad)

                local LLbl = make("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = leftText,
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 13, Font = M.SubF,
                    ZIndex = 2,
                    Parent = LBG,
                })
                local LLblGrad = Instance.new("UIGradient")
                LLblGrad.Color   = textShimCS()
                LLblGrad.Enabled = active == "left"
                LLblGrad.Parent  = LLbl
                spawnShim(LLblGrad, true)

                local LBtn = make("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 3,
                    Parent = LBG,
                })

                local RBG = make("Frame", {
                    Size = UDim2.new(0.5, -3, 0, 30),
                    Position = UDim2.new(0.5, 3, 0.5, -15),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Parent = F,
                })
                corner(RBG, UDim.new(0, 7))
                mkStroke(RBG, M.Border, 1, 0.45)

                local RGrad = Instance.new("UIGradient")
                RGrad.Color    = ColorSequence.new(T.A, T.A2)
                RGrad.Rotation = 135
                RGrad.Enabled  = active == "right"
                RGrad.Parent   = RBG
                table.insert(bgGrads, RGrad)

                local RLbl = make("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = rightText,
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 13, Font = M.SubF,
                    ZIndex = 2,
                    Parent = RBG,
                })
                local RLblGrad = Instance.new("UIGradient")
                RLblGrad.Color   = textShimCS()
                RLblGrad.Enabled = active == "right"
                RLblGrad.Parent  = RLbl
                spawnShim(RLblGrad, true)

                local RBtn = make("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 3,
                    Parent = RBG,
                })

                -- set initial inactive side
                if active == "left" then
                    RBG.BackgroundColor3 = M.Sec
                    RLbl.TextColor3      = M.Sub
                    table.insert(mSec, RBG)
                    table.insert(mSub, RLbl)
                else
                    LBG.BackgroundColor3 = M.Sec
                    LLbl.TextColor3      = M.Sub
                    table.insert(mSec, LBG)
                    table.insert(mSub, LLbl)
                end

                local function setActive(side)
                    active = side
                    if side == "left" then
                        -- activate left
                        LGrad.Enabled    = true
                        LLblGrad.Enabled = true
                        LBG.BackgroundColor3 = Color3.new(1, 1, 1)
                        LLbl.TextColor3      = Color3.new(1, 1, 1)
                        -- remove RBG from mSec if present
                        for i, o in ipairs(mSec) do
                            if o == RBG then table.remove(mSec, i); break end
                        end
                        for i, o in ipairs(mSub) do
                            if o == RLbl then table.remove(mSub, i); break end
                        end
                        -- deactivate right
                        RGrad.Enabled    = false
                        RLblGrad.Enabled = false
                        tw(RBG,  {BackgroundColor3 = M.Sec}, 0.25)
                        tw(RLbl, {TextColor3 = M.Sub},       0.25)
                        table.insert(mSec, RBG)
                        table.insert(mSub, RLbl)
                    else
                        -- activate right
                        RGrad.Enabled    = true
                        RLblGrad.Enabled = true
                        RBG.BackgroundColor3 = Color3.new(1, 1, 1)
                        RLbl.TextColor3      = Color3.new(1, 1, 1)
                        -- remove LBG from mSec if present
                        for i, o in ipairs(mSec) do
                            if o == LBG then table.remove(mSec, i); break end
                        end
                        for i, o in ipairs(mSub) do
                            if o == LLbl then table.remove(mSub, i); break end
                        end
                        -- deactivate left
                        LGrad.Enabled    = false
                        LLblGrad.Enabled = false
                        tw(LBG,  {BackgroundColor3 = M.Sec}, 0.25)
                        tw(LLbl, {TextColor3 = M.Sub},       0.25)
                        table.insert(mSec, LBG)
                        table.insert(mSub, LLbl)
                    end
                    callback(side)
                end

                LBtn.MouseButton1Click:Connect(function()
                    if active ~= "left" then setActive("left") end
                end)
                RBtn.MouseButton1Click:Connect(function()
                    if active ~= "right" then setActive("right") end
                end)

                local API = {}
                function API:Set(side) setActive(side) end
                return API
            end

            -- ── TEXTBOX ──────────────────────────────────────
            function Section:CreateTextBox(text, placeholder, callback)
                callback = callback or function() end
                addSep()

                local F = make("Frame", {
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1,
                    Parent = Items,
                })
                local Lbl = make("TextLabel", {
                    Size = UDim2.new(0.38, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = M.Text,
                    TextSize = 13, Font = M.SubF,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = F,
                })
                table.insert(mText, Lbl)

                local BoxBG = make("Frame", {
                    Size = UDim2.new(0.62, 0, 0, 26),
                    Position = UDim2.new(0.38, 0, 0.5, -13),
                    BackgroundColor3 = M.Main,
                    Parent = F,
                })
                corner(BoxBG, UDim.new(0, 6))
                mkStroke(BoxBG, M.Border, 1, 0.4)
                table.insert(mMain, BoxBG)

                local Box = make("TextBox", {
                    Size = UDim2.new(1, -12, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    PlaceholderText = placeholder or "...",
                    PlaceholderColor3 = M.Sub,
                    TextColor3 = M.Text,
                    TextSize = 12, Font = M.SubF,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                    Parent = BoxBG,
                })
                table.insert(mText, Box)

                Box.Focused:Connect(function()
                    tw(BoxBG, {BackgroundColor3 = M.Sec}, 0.15)
                end)
                Box.FocusLost:Connect(function(enter)
                    tw(BoxBG, {BackgroundColor3 = M.Main}, 0.15)
                    if enter then callback(Box.Text) end
                end)

                local API = {}
                function API:Set(v) Box.Text = v end
                return API
            end

            -- ── KEYBIND ──────────────────────────────────────
            function Section:CreateKeybind(text, defaultKey, callback)
                callback  = callback or function() end
                local key = defaultKey or Enum.KeyCode.F
                local listening = false
                addSep()

                local F = make("Frame", {
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1,
                    Parent = Items,
                })
                local Lbl = make("TextLabel", {
                    Size = UDim2.new(0.5, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = M.Text,
                    TextSize = 13, Font = M.SubF,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = F,
                })
                table.insert(mText, Lbl)

                local KBG = make("Frame", {
                    Size = UDim2.new(0.5, 0, 0, 28),
                    Position = UDim2.new(0.5, 0, 0.5, -14),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Parent = F,
                })
                corner(KBG, UDim.new(0, 7))
                bgGrad(KBG, 135)
                mkStroke(KBG, M.Border, 1, 0.45)

                local KLbl = make("TextLabel", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "[" .. key.Name .. "]",
                    TextColor3 = Color3.new(1, 1, 1),
                    TextSize = 12, Font = M.Font,
                    ZIndex = 2,
                    Parent = KBG,
                })
                textShim(KLbl)

                local KBtn = make("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 3,
                    Parent = KBG,
                })

                local blinkConn = nil
                local function stopBlink()
                    if blinkConn then blinkConn:Disconnect(); blinkConn = nil end
                    KBG.BackgroundTransparency = 0
                end
                local function startBlink()
                    local t = 0
                    blinkConn = RS.Heartbeat:Connect(function(dt)
                        t = t + dt
                        KBG.BackgroundTransparency = 0.3 + 0.3 * math.sin(t * 6)
                    end)
                end

                KBtn.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening = true
                    KLbl.Text = "Press any key..."
                    startBlink()
                    local conn
                    conn = UIS.InputBegan:Connect(function(inp, gpe)
                        if gpe then return end
                        if inp.UserInputType == Enum.UserInputType.Keyboard then
                            if inp.KeyCode == Enum.KeyCode.Escape then
                                KLbl.Text = "[" .. key.Name .. "]"
                            else
                                key = inp.KeyCode
                                KLbl.Text = "[" .. key.Name .. "]"
                                callback(key)
                            end
                            stopBlink()
                            listening = false
                            conn:Disconnect()
                        end
                    end)
                end)

                local API = {}
                function API:Set(k)
                    key = k
                    KLbl.Text = "[" .. key.Name .. "]"
                    callback(key)
                end
                return API
            end

            -- ── COLOR PICKER ─────────────────────────────────
            function Section:CreateColorPicker(text, default, callback)
                callback = callback or function() end
                local col = default or Color3.fromRGB(255, 0, 0)
                local open = false
                local h, s, v = col:ToHSV()
                addSep()

                local F = make("Frame", {
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1,
                    ClipsDescendants = false,
                    Parent = Items,
                })
                local Lbl = make("TextLabel", {
                    Size = UDim2.new(1, -40, 0, 36),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = M.Text,
                    TextSize = 13, Font = M.SubF,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = F,
                })
                table.insert(mText, Lbl)

                local Preview = make("TextButton", {
                    Size = UDim2.new(0, 28, 0, 20),
                    Position = UDim2.new(1, -28, 0, 8),
                    BackgroundColor3 = col,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = F,
                })
                corner(Preview, UDim.new(0, 5))
                mkStroke(Preview, M.Border, 1, 0.4)

                local Panel = make("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, 38),
                    BackgroundColor3 = M.Main,
                    ClipsDescendants = true,
                    Parent = F,
                })
                corner(Panel, UDim.new(0, 8))
                mkStroke(Panel, M.Border, 1, 0.4)
                table.insert(mMain, Panel)

                local Field = make("ImageLabel", {
                    Size = UDim2.new(1, -44, 0, 100),
                    Position = UDim2.new(0, 8, 0, 8),
                    BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                    Image = "rbxassetid://4155801252",
                    Parent = Panel,
                })
                corner(Field, UDim.new(0, 4))
                local FBtn = make("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = Field,
                })
                local SVDot = make("Frame", {
                    Size = UDim2.new(0, 10, 0, 10),
                    Position = UDim2.new(s, -5, 1 - v, -5),
                    BackgroundTransparency = 1,
                    Parent = Field,
                })
                corner(SVDot, UDim.new(1, 0))
                make("UIStroke", {Color = Color3.new(1,1,1), Thickness = 2, Parent = SVDot})

                local HBar = make("Frame", {
                    Size = UDim2.new(0, 20, 0, 100),
                    Position = UDim2.new(1, -28, 0, 8),
                    Parent = Panel,
                })
                corner(HBar, UDim.new(0, 4))
                make("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 0,   0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,   255, 0)),
                        ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0,   255, 255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,   0,   255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0,   255)),
                        ColorSequenceKeypoint.new(1,    Color3.fromRGB(255, 0,   0)),
                    }),
                    Rotation = 90,
                    Parent = HBar,
                })
                local HBtn = make("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = HBar,
                })
                local HCur = make("Frame", {
                    Size = UDim2.new(1, 4, 0, 4),
                    Position = UDim2.new(0, -2, h, -2),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Parent = HBar,
                })
                corner(HCur, UDim.new(1, 0))

                local RGBRow = make("Frame", {
                    Size = UDim2.new(1, -16, 0, 22),
                    Position = UDim2.new(0, 8, 0, 114),
                    BackgroundTransparency = 1,
                    Parent = Panel,
                })

                local function mkInp(lbl2, px, vv)
                    local cc = make("Frame", {
                        Size = UDim2.new(0.27, 0, 1, 0),
                        Position = UDim2.new(px, 0, 0, 0),
                        BackgroundTransparency = 1,
                        Parent = RGBRow,
                    })
                    make("TextLabel", {
                        Size = UDim2.new(0, 12, 1, 0),
                        BackgroundTransparency = 1,
                        Text = lbl2,
                        TextColor3 = M.Sub,
                        TextSize = 10, Font = M.Font,
                        Parent = cc,
                    })
                    local bg2 = make("Frame", {
                        Size = UDim2.new(1, -14, 1, 0),
                        Position = UDim2.new(0, 14, 0, 0),
                        BackgroundColor3 = M.Sec,
                        Parent = cc,
                    })
                    corner(bg2, UDim.new(0, 4))
                    table.insert(mSec, bg2)
                    local tb = make("TextBox", {
                        Size = UDim2.new(1, -4, 1, 0),
                        Position = UDim2.new(0, 2, 0, 0),
                        BackgroundTransparency = 1,
                        Text = tostring(vv),
                        TextColor3 = M.Text,
                        TextSize = 10, Font = M.SubF,
                        Parent = bg2,
                    })
                    table.insert(mText, tb)
                    return tb
                end

                local RI = mkInp("R", 0,    math.floor(col.R * 255))
                local GI = mkInp("G", 0.27, math.floor(col.G * 255))
                local BI = mkInp("B", 0.54, math.floor(col.B * 255))

                -- Rainbow toggle
                local RBHolder = make("Frame", {
                    Size = UDim2.new(0, 38, 1, 0),
                    Position = UDim2.new(1, -38, 0, 0),
                    BackgroundTransparency = 1,
                    Parent = RGBRow,
                })
                make("TextLabel", {
                    Size = UDim2.new(1, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    Text = "RGB",
                    TextColor3 = M.Sub,
                    TextSize = 8, Font = M.Font,
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Parent = RBHolder,
                })
                local RBTrack = make("Frame", {
                    Size = UDim2.new(0, 28, 0, 14),
                    Position = UDim2.new(0.5, -14, 1, -14),
                    BackgroundColor3 = M.Border,
                    Parent = RBHolder,
                })
                corner(RBTrack, UDim.new(1, 0))
                table.insert(mBorder, RBTrack)

                local RBCircle = make("Frame", {
                    Size = UDim2.new(0, 10, 0, 10),
                    Position = UDim2.new(0, 2, 0.5, -5),
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Parent = RBTrack,
                })
                corner(RBCircle, UDim.new(1, 0))

                make("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 0,   0)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,   255, 0)),
                        ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0,   255, 255)),
                        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,   0,   255)),
                        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0,   255)),
                        ColorSequenceKeypoint.new(1,    Color3.fromRGB(255, 0,   0)),
                    }),
                    Enabled = false,
                    Parent = RBTrack,
                })
                local RBBtn = make("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    ZIndex = 2,
                    Parent = RBTrack,
                })

                local rainbow = false
                local rbConn  = nil
                local rbHue   = 0

                local function setRainbow(state)
                    rainbow = state
                    local rbGrad = RBTrack:FindFirstChildOfClass("UIGradient")
                    if state then
                        if rbGrad then rbGrad.Enabled = true end
                        tw(RBCircle, {Position = UDim2.new(1, -12, 0.5, -5)}, 0.2)
                        rbConn = RS.RenderStepped:Connect(function(dt)
                            rbHue = (rbHue + dt * 0.35) % 1
                            local rc = Color3.fromHSV(rbHue, 1, 1)
                            col = rc; h = rbHue; s = 1; v = 1
                            Field.BackgroundColor3   = Color3.fromHSV(rbHue, 1, 1)
                            SVDot.Position           = UDim2.new(1, -5, 0, -5)
                            HCur.Position            = UDim2.new(0, -2, rbHue, -2)
                            Preview.BackgroundColor3 = rc
                            RI.Text = tostring(math.floor(rc.R * 255))
                            GI.Text = tostring(math.floor(rc.G * 255))
                            BI.Text = tostring(math.floor(rc.B * 255))
                            callback(rc)
                        end)
                    else
                        if rbConn then rbConn:Disconnect(); rbConn = nil end
                        if rbGrad then rbGrad.Enabled = false end
                        tw(RBCircle, {Position = UDim2.new(0, 2, 0.5, -5)}, 0.2)
                        tw(RBTrack,  {BackgroundColor3 = M.Border}, 0.2)
                    end
                end

                RBBtn.MouseButton1Click:Connect(function()
                    setRainbow(not rainbow)
                end)

                local function refresh()
                    if rainbow then return end
                    col = Color3.fromHSV(h, s, v)
                    Preview.BackgroundColor3 = col
                    Field.BackgroundColor3   = Color3.fromHSV(h, 1, 1)
                    SVDot.Position = UDim2.new(s, -5, 1 - v, -5)
                    HCur.Position  = UDim2.new(0, -2, h, -2)
                    RI.Text = tostring(math.floor(col.R * 255))
                    GI.Text = tostring(math.floor(col.G * 255))
                    BI.Text = tostring(math.floor(col.B * 255))
                    callback(col)
                end

                local pSV, pH = false, false
                FBtn.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then pSV = true end
                end)
                HBtn.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then pH = true end
                end)
                UIS.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        pSV = false; pH = false
                    end
                end)
                UIS.InputChanged:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseMovement then
                        if pSV then
                            s = math.clamp((i.Position.X - Field.AbsolutePosition.X) / Field.AbsoluteSize.X, 0, 1)
                            v = 1 - math.clamp((i.Position.Y - Field.AbsolutePosition.Y) / Field.AbsoluteSize.Y, 0, 1)
                            refresh()
                        elseif pH then
                            h = math.clamp((i.Position.Y - HBar.AbsolutePosition.Y) / HBar.AbsoluteSize.Y, 0, 1)
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

                Preview.MouseButton1Click:Connect(function()
                    open = not open
                    if open then
                        tw(F,     {Size = UDim2.new(1, 0, 0, 195)})
                        tw(Panel, {Size = UDim2.new(1, 0, 0, 150)})
                    else
                        tw(F,     {Size = UDim2.new(1, 0, 0, 36)})
                        tw(Panel, {Size = UDim2.new(1, 0, 0, 0)})
                    end
                end)

                local API = {}
                function API:Set(c)
                    setRainbow(false)
                    col = c; h, s, v = c:ToHSV(); refresh()
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
