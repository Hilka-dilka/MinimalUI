    ███╗   ███╗██╗███╗   ██╗██╗███╗   ███╗ █████╗ ██╗                      
    ████╗ ████║██║████╗  ██║██║████╗ ████║██╔══██╗██║                      
    ██╔████╔██║██║██╔██╗ ██║██║██╔████╔██║███████║██║                      
    ██║╚██╔╝██║██║██║╚██╗██║██║██║╚██╔╝██║██╔══██║██║                      
    ██║ ╚═╝ ██║██║██║ ╚████║██║██║ ╚═╝ ██║██║  ██║███████╗                 
    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ 

### MinimalUI — Roblox Lua UI Library

Hero Section:
MinimalUI
Minimalist, beautiful and powerful UI library for Roblox Lua scripts

-

## 𝐀𝐥𝐥 𝐔𝐈 𝐄𝐥𝐞𝐦𝐞𝐧𝐭𝐬:
A rich set of components for any script

Тoggle (Smooth animated switch)

Slider (Drag with lerp + manual input)

Button (Gradient button with shimmer)

Dual Button (Two-state toggle button)

TextBox (Text input with placeholder)

Keybind (Key capture with listener)

ColorPicker (Full HSV picker + RGB inputs)

Rainbow (Auto-cycling rainbow toggle)

-

# 𝐇𝐨𝐰 𝐭𝐨 𝐔𝐬𝐞:
Four steps and your UI is ready

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
print("Kill Aura:", v)
end)

-- Slider
Sec:CreateSlider("Reach", 5, 50, 15, function(v)
print("Reach:", v)
end)

-- Button
Sec:CreateButton("Lock Target", function()
print("Locked!")
end)

-- TextBox
Sec:CreateTextBox("Player", "Username...", function(t)
print("Player:", t)
end)

-- ColorPicker (changes theme)
Sec:CreateColorPicker("Theme", Color3.fromRGB(124,58,237), function(c)
W:SetTheme(c)
end)

-- Keybind
Sec:CreateKeybind("Toggle Menu", Enum.KeyCode.RightControl, function(k)
W:SetKey(k)
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

-- Dual button (dark/light switch)
Sec:CreateDualButton("🌑 Dark", "☀️ Light", "left", function(side)
W:SetMenuTheme(side == "left" and "dark" or "light")
end)
```
-

© 2026 MinimalUI v2.0 — Minimalist Roblox Lua UI Library
