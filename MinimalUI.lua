--[[
    MinimalUI Library v1.0
    Minimalist UI Library for Roblox
    
    GitHub: загрузите этот файл как MinimalUI.lua
]]

local MinimalUI = {}

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- Configuration
local Config = {
    MainColor = Color3.fromRGB(19, 19, 31),
    SecondaryColor = Color3.fromRGB(26, 26, 42),
    AccentColor = Color3.fromRGB(124, 58, 237),
    TextColor = Color3.fromRGB(228, 228, 231),
    SubTextColor = Color3.fromRGB(120, 120, 150),
    BorderColor = Color3.fromRGB(40, 40, 60),
    Font = Enum.Font.GothamSemibold,
    SubFont = Enum.Font.Gotham,
    AnimSpeed = 0.25
}

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
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    if props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function corner(parent, radius)
    return create("UICorner", {
        CornerRadius = radius or UDim.new(0, 8),
        Parent = parent
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

local function makeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
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
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
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
        Name = "MinimalUI",
        Parent = Player.PlayerGui,
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
    stroke(Main)

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
        ZIndex = 0,
        Parent = Main
    })

    -- Title Bar
    local TitleBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        Parent = Main
    })
    makeDraggable(Main, TitleBar)

    create("TextLabel", {
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 82, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "MinimalUI",
        TextColor3 = Config.TextColor,
        TextSize = 15,
        Font = Config.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TitleBar
    })

    create("Frame", {
        Size = UDim2.new(1, -24, 0, 1),
        Position = UDim2.new(0, 12, 1, 0),
        BackgroundColor3 = Config.BorderColor,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Parent = TitleBar
    })

    -- macOS-style traffic light dots
    local DotsFrame = create("Frame", {
        Size = UDim2.new(0, 60, 0, 14),
        Position = UDim2.new(0, 14, 0.5, -7),
        BackgroundTransparency = 1,
        Parent = TitleBar
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
            BackgroundColor3 = color,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = order,
            Parent = DotsFrame
        })
        corner(dot, UDim.new(1, 0))
        return dot
    end

    local CloseDot = makeDot(Color3.fromRGB(255, 95, 87), 1)
    local MinDot = makeDot(Color3.fromRGB(255, 189, 46), 2)
    local MaxDot = makeDot(Color3.fromRGB(40, 200, 64), 3)

    -- Close: destroy GUI
    CloseDot.MouseButton1Click:Connect(function()
        tween(Main, {Size = UDim2.new(0, 580, 0, 0)}, 0.3)
        task.wait(0.3)
        GUI:Destroy()
    end)

    -- Minimize: collapse to title bar
    local minimized = false
    MinDot.MouseButton1Click:Connect(function()
        minimized = not minimized
        tween(Main, {Size = minimized
            and UDim2.new(0, 580, 0, 44)
            or  UDim2.new(0, 580, 0, 400)
        }, 0.3)
    end)

    -- Maximize: expand window
    local maximized = false
    MaxDot.MouseButton1Click:Connect(function()
        maximized = not maximized
        if minimized then
            minimized = false
        end
        tween(Main, {Size = maximized
            and UDim2.new(0, 800, 0, 550)
            or  UDim2.new(0, 580, 0, 400)
        }, 0.35)
    end)

    -- Body
    local Body = create("Frame", {
        Size = UDim2.new(1, 0, 1, -44),
        Position = UDim2.new(0, 0, 0, 44),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = Main
    })

    -- Tab bar (left)
    local TabBar = create("Frame", {
        Size = UDim2.new(0, 140, 1, -12),
        Position = UDim2.new(0, 8, 0, 6),
        BackgroundColor3 = Config.SecondaryColor,
        BackgroundTransparency = 0.3,
        Parent = Body
    })
    corner(TabBar)
    create("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabBar
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = TabBar
    })

    -- Content container
    local ContentBox = create("Frame", {
        Size = UDim2.new(1, -164, 1, -12),
        Position = UDim2.new(0, 156, 0, 6),
        BackgroundTransparency = 1,
        Parent = Body
    })

    -- Toggle key
    local toggleKey = Enum.KeyCode.RightControl
    local visible = true
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == toggleKey then
            visible = not visible
            GUI.Enabled = visible
        end
    end)

    local Window = {}
    Window.Tabs = {}
    Window.GUI = GUI

    function Window:SetKey(key) toggleKey = key end

    -- ═══════════════════════════════════════
    -- TAB
    -- ═══════════════════════════════════════
    function Window:CreateTab(name)
        local Tab = { Sections = {} }

        local TabBtn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Config.AccentColor,
            BackgroundTransparency = 1,
            Text = name,
            TextColor3 = Config.SubTextColor,
            TextSize = 13,
            Font = Config.SubFont,
            Parent = TabBar
        })
        corner(TabBtn, UDim.new(0, 7))

        local Content = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Config.AccentColor,
            BorderSizePixel = 0,
            Visible = false,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = ContentBox
        })
        create("UIListLayout", {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Content
        })

        local function select()
            for _, t in pairs(Window.Tabs) do
                t.Content.Visible = false
                t.Btn.BackgroundTransparency = 1
                t.Btn.TextColor3 = Config.SubTextColor
            end
            Content.Visible = true
            tween(TabBtn, {BackgroundTransparency = 0})
            TabBtn.TextColor3 = Color3.new(1, 1, 1)
        end

        TabBtn.MouseButton1Click:Connect(select)
        if #Window.Tabs == 0 then select() end

        Tab.Btn = TabBtn
        Tab.Content = Content

        -- ═══════════════════════════════════════
        -- SECTION
        -- ═══════════════════════════════════════
        function Tab:CreateSection(sectionName)
            local Section = {}

            local SFrame = create("Frame", {
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Config.SecondaryColor,
                BackgroundTransparency = 0.3,
                Parent = Content
            })
            corner(SFrame, UDim.new(0, 10))
            stroke(SFrame, Config.BorderColor, 1)

            create("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = SFrame
            })
            create("UIPadding", {
                PaddingTop    = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft   = UDim.new(0, 14),
                PaddingRight  = UDim.new(0, 14),
                Parent = SFrame
            })

            -- Section title
            create("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = string.upper(sectionName),
                TextColor3 = Config.AccentColor,
                TextSize = 11,
                Font = Config.Font,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = SFrame
            })
            create("Frame", {
                Size = UDim2.new(1, 0, 0, 1),
                BackgroundColor3 = Config.BorderColor,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Parent = SFrame
            })

            -- ════════ TOGGLE ════════
            function Section:CreateToggle(text, default, callback)
                callback = callback or function() end
                local state = default or false

                local F = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    Parent = SFrame
                })
                create("TextLabel", {
                    Size = UDim2.new(1, -50, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Config.TextColor,
                    TextSize = 13,
                    Font = Config.SubFont,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = F
                })

                local BG = create("Frame", {
                    Size = UDim2.new(0, 38, 0, 20),
                    Position = UDim2.new(1, -38, 0.5, -10),
                    BackgroundColor3 = state
                        and Config.AccentColor
                        or  Config.BorderColor,
                    Parent = F
                })
                corner(BG, UDim.new(1, 0))

                local Circle = create("Frame", {
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = state
                        and UDim2.new(1, -18, 0.5, -8)
                        or  UDim2.new(0, 2, 0.5, -8),
                    BackgroundColor3 = Color3.new(1,1,1),
                    Parent = BG
                })
                corner(Circle, UDim.new(1, 0))

                local Btn = create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = F
                })
                Btn.MouseButton1Click:Connect(function()
                    state = not state
                    tween(BG, {BackgroundColor3 = state
                        and Config.AccentColor
                        or  Config.BorderColor})
                    tween(Circle, {Position = state
                        and UDim2.new(1, -18, 0.5, -8)
                        or  UDim2.new(0, 2, 0.5, -8)})
                    callback(state)
                end)

                local API = {}
                function API:Set(v)
                    state = v
                    tween(BG, {BackgroundColor3 = v
                        and Config.AccentColor
                        or  Config.BorderColor})
                    tween(Circle, {Position = v
                        and UDim2.new(1, -18, 0.5, -8)
                        or  UDim2.new(0, 2, 0.5, -8)})
                    callback(v)
                end
                return API
            end

            -- ════════ SLIDER ════════
            function Section:CreateSlider(text, min, max, default, callback)
                callback = callback or function() end
                local val = default or min

                local F = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 44),
                    BackgroundTransparency = 1,
                    Parent = SFrame
                })
                create("TextLabel", {
                    Size = UDim2.new(1, -45, 0, 18),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Config.TextColor,
                    TextSize = 13,
                    Font = Config.SubFont,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = F
                })
                local VLabel = create("TextLabel", {
                    Size = UDim2.new(0, 45, 0, 18),
                    Position = UDim2.new(1, -45, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(val),
                    TextColor3 = Config.AccentColor,
                    TextSize = 13,
                    Font = Config.Font,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = F
                })
                local Track = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 5),
                    Position = UDim2.new(0, 0, 0, 28),
                    BackgroundColor3 = Config.BorderColor,
                    Parent = F
                })
                corner(Track, UDim.new(1, 0))

                local pct = (val - min) / (max - min)
                local Fill = create("Frame", {
                    Size = UDim2.new(pct, 0, 1, 0),
                    BackgroundColor3 = Config.AccentColor,
                    Parent = Track
                })
                corner(Fill, UDim.new(1, 0))

                local Knob = create("Frame", {
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(pct, -7, 0.5, -7),
                    BackgroundColor3 = Color3.new(1,1,1),
                    ZIndex = 2,
                    Parent = Track
                })
                corner(Knob, UDim.new(1, 0))

                local SlideBtn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 24),
                    Position = UDim2.new(0, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = "",
                    Parent = F
                })

                local sliding = false
                SlideBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = true
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        sliding = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        local p = math.clamp(
                            (inp.Position.X - Track.AbsolutePosition.X)
                            / Track.AbsoluteSize.X, 0, 1)
                        val = math.floor(min + (max - min) * p)
                        VLabel.Text = tostring(val)
                        Fill.Size = UDim2.new(p, 0, 1, 0)
                        Knob.Position = UDim2.new(p, -7, 0.5, -7)
                        callback(val)
                    end
                end)

                local API = {}
                function API:Set(v)
                    val = math.clamp(v, min, max)
                    local p = (val - min) / (max - min)
                    VLabel.Text = tostring(val)
                    tween(Fill, {Size = UDim2.new(p, 0, 1, 0)})
                    tween(Knob, {Position = UDim2.new(p, -7, 0.5, -7)})
                    callback(val)
                end
                return API
            end

            -- ════════ BUTTON ════════
            function Section:CreateButton(text, callback)
                callback = callback or function() end

                local F = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    Parent = SFrame
                })
                local B = create("TextButton", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Config.AccentColor,
                    Text = text,
                    TextColor3 = Color3.new(1,1,1),
                    TextSize = 13,
                    Font = Config.SubFont,
                    Parent = F
                })
                corner(B, UDim.new(0, 7))

                B.MouseButton1Click:Connect(function()
                    tween(B, {BackgroundColor3 =
                        Color3.fromRGB(160, 120, 255)}, 0.1)
                    task.wait(0.1)
                    tween(B, {BackgroundColor3 = Config.AccentColor}, 0.15)
                    callback()
                end)
            end

            -- ════════ TEXTBOX ════════
            function Section:CreateTextBox(text, placeholder, callback)
                callback = callback or function() end

                local F = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    Parent = SFrame
                })
                create("TextLabel", {
                    Size = UDim2.new(0.4, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Config.TextColor,
                    TextSize = 13,
                    Font = Config.SubFont,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = F
                })
                local BoxBG = create("Frame", {
                    Size = UDim2.new(0.55, 0, 0, 28),
                    Position = UDim2.new(0.45, 0, 0.5, -14),
                    BackgroundColor3 = Config.MainColor,
                    Parent = F
                })
                corner(BoxBG, UDim.new(0, 6))
                stroke(BoxBG, Config.BorderColor, 1)

                local Box = create("TextBox", {
                    Size = UDim2.new(1, -12, 1, 0),
                    Position = UDim2.new(0, 6, 0, 0),
                    BackgroundTransparency = 1,
                    Text = "",
                    PlaceholderText = placeholder or "...",
                    PlaceholderColor3 = Config.SubTextColor,
                    TextColor3 = Config.TextColor,
                    TextSize = 12,
                    Font = Config.SubFont,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ClearTextOnFocus = false,
                    Parent = BoxBG
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
                    ClipsDescendants = false,
                    Parent = SFrame
                })
                create("TextLabel", {
                    Size = UDim2.new(1, -40, 0, 32),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Config.TextColor,
                    TextSize = 13,
                    Font = Config.SubFont,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = F
                })
                local Preview = create("TextButton", {
                    Size = UDim2.new(0, 28, 0, 20),
                    Position = UDim2.new(1, -28, 0, 6),
                    BackgroundColor3 = col,
                    Text = "",
                    Parent = F
                })
                corner(Preview, UDim.new(0, 5))
                stroke(Preview, Config.BorderColor, 1)

                -- Picker panel
                local Panel = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, 34),
                    BackgroundColor3 = Config.MainColor,
                    ClipsDescendants = true,
                    Parent = F
                })
                corner(Panel, UDim.new(0, 8))
                stroke(Panel, Config.BorderColor, 1)

                -- SV field
                local Field = create("ImageLabel", {
                    Size = UDim2.new(1, -44, 0, 100),
                    Position = UDim2.new(0, 8, 0, 8),
                    BackgroundColor3 = Color3.fromHSV(h, 1, 1),
                    Image = "rbxassetid://4155801252",
                    Parent = Panel
                })
                corner(Field, UDim.new(0, 4))

                local FieldBtn = create("TextButton", {
                    Size = UDim2.new(1,0,1,0), BackgroundTransparency=1,
                    Text="", Parent = Field
                })

                local SVDot = create("Frame", {
                    Size = UDim2.new(0,10,0,10),
                    Position = UDim2.new(s, -5, 1-v, -5),
                    BackgroundTransparency = 1,
                    Parent = Field
                })
                corner(SVDot, UDim.new(1,0))
                stroke(SVDot, Color3.new(1,1,1), 2)

                -- Hue bar
                local HBar = create("Frame", {
                    Size = UDim2.new(0, 20, 0, 100),
                    Position = UDim2.new(1, -28, 0, 8),
                    Parent = Panel
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
                    }),
                    Rotation = 90,
                    Parent = HBar
                })
                local HBtn = create("TextButton", {
                    Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
                    Text="", Parent=HBar
                })
                local HCur = create("Frame", {
                    Size = UDim2.new(1, 4, 0, 4),
                    Position = UDim2.new(0, -2, h, -2),
                    BackgroundColor3 = Color3.new(1,1,1),
                    Parent = HBar
                })
                corner(HCur, UDim.new(1,0))

                -- RGB inputs
                local RGBRow = create("Frame", {
                    Size = UDim2.new(1, -16, 0, 22),
                    Position = UDim2.new(0, 8, 0, 114),
                    BackgroundTransparency = 1,
                    Parent = Panel
                })

                local function makeInput(lbl, px, v)
                    local c = create("Frame", {
                        Size = UDim2.new(0.3,0,1,0),
                        Position = UDim2.new(px,0,0,0),
                        BackgroundTransparency = 1,
                        Parent = RGBRow
                    })
                    create("TextLabel", {
                        Size=UDim2.new(0,12,1,0),
                        BackgroundTransparency=1,
                        Text=lbl, TextColor3=Config.SubTextColor,
                        TextSize=10, Font=Config.Font,
                        Parent=c
                    })
                    local bg = create("Frame", {
                        Size=UDim2.new(1,-14,1,0),
                        Position=UDim2.new(0,14,0,0),
                        BackgroundColor3=Config.SecondaryColor,
                        Parent=c
                    })
                    corner(bg, UDim.new(0,4))
                    local tb = create("TextBox", {
                        Size=UDim2.new(1,-4,1,0),
                        Position=UDim2.new(0,2,0,0),
                        BackgroundTransparency=1,
                        Text=tostring(v),
                        TextColor3=Config.TextColor,
                        TextSize=10, Font=Config.SubFont,
                        Parent=bg
                    })
                    return tb
                end

                local rr = math.floor(col.R*255)
                local gg = math.floor(col.G*255)
                local bb = math.floor(col.B*255)
                local RI = makeInput("R", 0, rr)
                local GI = makeInput("G", 0.33, gg)
                local BI = makeInput("B", 0.66, bb)

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

                -- SV drag
                local pickSV = false
                FieldBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        pickSV = true
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        pickSV = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if pickSV and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        s = math.clamp((inp.Position.X - Field.AbsolutePosition.X) / Field.AbsoluteSize.X, 0, 1)
                        v = 1 - math.clamp((inp.Position.Y - Field.AbsolutePosition.Y) / Field.AbsoluteSize.Y, 0, 1)
                        refresh()
                    end
                end)

                -- Hue drag
                local pickH = false
                HBtn.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        pickH = true
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        pickH = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if pickH and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        h = math.clamp((inp.Position.Y - HBar.AbsolutePosition.Y) / HBar.AbsoluteSize.Y, 0, 1)
                        refresh()
                    end
                end)

                -- RGB text input
                for _, inp in pairs({RI, GI, BI}) do
                    inp.FocusLost:Connect(function()
                        local rv = math.clamp(tonumber(RI.Text) or 0, 0, 255)
                        local gv = math.clamp(tonumber(GI.Text) or 0, 0, 255)
                        local bv = math.clamp(tonumber(BI.Text) or 0, 0, 255)
                        col = Color3.fromRGB(rv, gv, bv)
                        h, s, v = col:ToHSV()
                        refresh()
                    end)
                end

                -- Toggle panel
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
