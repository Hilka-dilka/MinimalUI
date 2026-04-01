    ███╗   ███╗██╗███╗   ██╗██╗███╗   ███╗ █████╗ ██╗                      
    ████╗ ████║██║████╗  ██║██║████╗ ████║██╔══██╗██║                      
    ██╔████╔██║██║██╔██╗ ██║██║██╔████╔██║███████║██║                      
    ██║╚██╔╝██║██║██║╚██╗██║██║██║╚██╔╝██║██╔══██║██║                      
    ██║ ╚═╝ ██║██║██║ ╚████║██║██║ ╚═╝ ██║██║  ██║███████╗                 
    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ 

### MinimalUI — Roblox Lua UI Library


MinimalUI — Minimalist, beautiful and powerful UI library for Roblox Lua scripts

o

## 𝐀𝐥𝐥 𝐔𝐈 𝐄𝐥𝐞𝐦𝐞𝐧𝐭𝐬:
A rich set of components for any script

Toggle (Smooth animated switch)

Slider (Drag with lerp + manual input)

ToggleSlider (Combined toggle + slider with smooth animation)

Button (Gradient button with shimmer)

Dual Button (Two-state toggle button)

TextBox (Text input with placeholder)

Keybind (Key capture with listener)

ColorPicker (Full HSV picker + RGB inputs)

o

# 𝐇𝐨𝐰 𝐭𝐨 𝐔𝐬𝐞:
Five steps and your UI is ready

𝗦𝘁𝗲𝗽 𝟭 — 𝗟𝗼𝗮𝗱 𝘁𝗵𝗲 𝗹𝗶𝗯𝗿𝗮𝗿𝘆

```lua
-- Load via loadstring
local UI = loadstring(game:HttpGet(
"https://raw.githubusercontent.com/Hilka-dilka/MinimalUI/main/MinimalUI.lua"
))()
```

𝗦𝘁𝗲𝗽 𝟮 — 𝗖𝗿𝗲𝗮𝘁𝗲 𝗮 𝘄𝗶𝗻𝗱𝗼𝘄 𝗮𝗻𝗱 𝘁𝗮𝗯𝘀

```lua
local W = UI:CreateWindow("My Hub")
local Tab = W:CreateTab("⚔ Combat")
local Sec = Tab:CreateSection("Aura")
```

𝗦𝘁𝗲𝗽 𝟯 — 𝗔𝗱𝗱 𝗲𝗹𝗲𝗺𝗲𝗻𝘁𝘀
```lua
-- Toggle
Sec:CreateToggle("Kill Aura", false, function(v)
    print(v)
end)

-- Slider
Sec:CreateSlider("Reach", 5, 50, 15, function(v)
    print(v)
end)

-- ToggleSlider
Sec:CreateToggleSlider("Aura Range", 5, 50, 15, false, function(enabled, value)
    print(enabled, value)
end)

-- Button
Sec:CreateButton("Lock Target", function()
    print("clicked")
end)

-- Dual Button
Sec:CreateDualButton("🌑 Dark", "☀️ Light", "left", function(side)
    print(side)
    W:SetMenuTheme(side == "left" and "dark" or "light")
end)

-- TextBox
Sec:CreateTextBox("Player", "Username...", function(t)
    print(t)
end)

-- Keybind
Sec:CreateKeybind("Toggle Menu", Enum.KeyCode.RightControl, function(k)
    print(k.Name)
    W:SetKey(k)
end)

-- ColorPicker
Sec:CreateColorPicker("Theme", Color3.fromRGB(124,58,237), function(c)
    print(c.R, c.G, c.B)
    W:SetTheme(c)
end)
```
𝗦𝘁𝗲𝗽 𝟰 — 𝗔𝗱𝘃𝗮𝗻𝗰𝗲𝗱 𝗳𝗲𝗮𝘁𝘂𝗿𝗲𝘀
```lua
-- Change accent color
W:SetTheme(Color3.fromRGB(16, 185, 129))

-- Change toggle hotkey
W:SetKey(Enum.KeyCode.RightControl)

-- Change menu background
W:SetMenuTheme("light") -- or "dark"
```
𝗦𝘁𝗲𝗽 𝟱 — 𝗔𝗣𝗜 𝗖𝗼𝗻𝘁𝗿𝗼𝗹 (Programmatic Management)

API (Application Programming Interface) allows you to control UI elements from your code without clicking them. Each element returns an API object that you can use to change its state programmatically.

```lua
-- Toggle API
local toggle = Sec:CreateToggle("Kill Aura", false, function(v)
    print(v)
end)
toggle:Set(true)   -- Turn on
toggle:Set(false)  -- Turn off

-- Slider API
local slider = Sec:CreateSlider("Range", 5, 50, 15, function(v)
    print(v)
end)
slider:Set(30)     -- Set value to 30

-- ToggleSlider API
local aura = Sec:CreateToggleSlider("Aura Range", 5, 50, 15, false, function(enabled, value)
    print(enabled, value)
end)
aura:SetEnabled(true)        -- Turn on
aura:SetEnabled(false)       -- Turn off
aura:SetValue(25)            -- Set slider value
local state = aura:IsEnabled()  -- Check if enabled (returns true/false)
local range = aura:GetValue()   -- Get current value (returns number)

-- Dual Button API
local dual = Sec:CreateDualButton("Dark", "Light", "left", function(side)
    print(side)
end)
dual:Set("right")    -- Switch to right button

-- TextBox API
local textbox = Sec:CreateTextBox("Player", "Username...", function(text)
    print(text)
end)
textbox:Set("Player123")  -- Set text programmatically

-- Keybind API
local keybind = Sec:CreateKeybind("Menu Key", Enum.KeyCode.RightControl, function(key)
    print(key.Name)
end)
keybind:Set(Enum.KeyCode.X)  -- Change keybind

-- ColorPicker API
local color = Sec:CreateColorPicker("Theme", Color3.fromRGB(124,58,237), function(c)
    print(c.R, c.G, c.B)
end)
color:Set(Color3.fromRGB(255, 100, 50))  -- Change color
```

o

# 𝐖𝐡𝐲 𝐔𝐬𝐞 𝐀𝐏𝐈?
Load and save settings — Save user preferences and restore them on script restart
Create hotkeys — Bind keyboard keys to toggle elements
Synchronize multiple elements — Control several elements with one action
Automate actions — Trigger UI changes based on game events
Reset values — Return elements to default state with one function call

𝐂𝐨𝐦𝐩𝐥𝐞𝐭𝐞 𝐄𝐱𝐚𝐦𝐩𝐥𝐞:
```lua
-- Create element and store API
local aura = Sec:CreateToggleSlider("Aura Range", 5, 50, 15, false, function(enabled, value)
    if enabled then
        startAura(value)  -- Start aura with range
    else
        stopAura()        -- Stop aura
    end
end)

-- Load saved settings
local saved = {enabled = true, range = 30}
aura:SetEnabled(saved.enabled)
aura:SetValue(saved.range)

-- Hotkey to toggle (press R)
UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.R then
        aura:SetEnabled(not aura:IsEnabled())
    end
end)

-- Console commands (type in F9)
-- aura:SetEnabled(false)   -- Turn off
-- aura:SetValue(40)        -- Set range to 40
-- print(aura:GetValue())   -- Print current range
```

o

## 𝐐𝐮𝐢𝐜𝐤 𝐑𝐞𝐟𝐞𝐫𝐞𝐧𝐜𝐞

| Element | Creation | Callback | API Methods |
|---------|----------|----------|-------------|
| **Toggle** | `CreateToggle(text, default, cb)` | `(state)` | `:Set(bool)` |
| **Slider** | `CreateSlider(text, min, max, default, cb)` | `(value)` | `:Set(num)` |
| **ToggleSlider** | `CreateToggleSlider(text, min, max, default, toggleDefault, cb)` | `(enabled, value)` | `:SetEnabled(bool)`, `:SetValue(num)`, `:IsEnabled()`, `:GetValue()` |
| **Button** | `CreateButton(text, cb)` | `()` | `-` |
| **Dual Button** | `CreateDualButton(left, right, default, cb)` | `(side)` | `:Set(side)` |
| **TextBox** | `CreateTextBox(text, placeholder, cb)` | `(text)` | `:Set(str)` |
| **Keybind** | `CreateKeybind(text, defaultKey, cb)` | `(key)` | `:Set(key)` |
| **ColorPicker** | `CreateColorPicker(text, defaultColor, cb)` | `(color)` | `:Set(color)` |

o

© 2026 MinimalUI v2.1 — Minimalist Roblox Lua UI Library
