
local MinimalUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Hilka-dilka/MinimalUI/refs/heads/main/MinimalUI.lua"
))()


local Window = MinimalUI:CreateWindow("My Script Hub")

-- ═══ TAB: Combat ═══
local CombatTab = Window:CreateTab("⚔ Combat")

local AuraSection = CombatTab:CreateSection("Aura")

AuraSection:CreateToggle("Kill Aura", false, function(enabled)
    print("Kill Aura:", enabled)
end)

AuraSection:CreateSlider("Reach Distance", 5, 50, 15, function(value)
    print("Reach:", value)
end)

AuraSection:CreateButton("Lock Target", function()
    print("Target locked!")
end)

local TargetSection = CombatTab:CreateSection("Target")

TargetSection:CreateTextBox("Player", "Username...", function(text)
    print("Target player:", text)
end)

-- ═══ TAB: Movement ═══
local MoveTab = Window:CreateTab("🏃 Movement")

local SpeedSection = MoveTab:CreateSection("Speed")

SpeedSection:CreateToggle("Speed Hack", false, function(v)
    if v then
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 100
    else
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)

SpeedSection:CreateSlider("Walk Speed", 16, 500, 50, function(v)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
end)

local JumpSection = MoveTab:CreateSection("Jump")

JumpSection:CreateSlider("Jump Power", 50, 500, 100, function(v)
    game.Players.LocalPlayer.Character.Humanoid.JumpPower = v
end)

JumpSection:CreateToggle("Infinite Jump", false, function(v)
    print("Infinite Jump:", v)
end)


local SettingsTab = Window:CreateTab("⚙ Settings")
local ThemeSection = SettingsTab:CreateSection("Theme")


ThemeSection:CreateColorPicker(
    "Accent Color",
    Color3.fromRGB(124, 58, 237),  
    function(color)

        Window:SetTheme(color)
    end
)

-- Быстрые пресеты цветов
ThemeSection:CreateButton("🟣 Purple (default)", function()
    Window:SetTheme(Color3.fromRGB(124, 58, 237))
end)

ThemeSection:CreateButton("🔵 Blue", function()
    Window:SetTheme(Color3.fromRGB(37, 99, 235))
end)

ThemeSection:CreateButton("🟢 Green", function()
    Window:SetTheme(Color3.fromRGB(16, 185, 129))
end)

ThemeSection:CreateButton("🔴 Red", function()
    Window:SetTheme(Color3.fromRGB(239, 68, 68))
end)

ThemeSection:CreateButton("🟠 Orange", function()
    Window:SetTheme(Color3.fromRGB(245, 158, 11))
end)

local GenSection = SettingsTab:CreateSection("General")

GenSection:CreateTextBox("Toggle Key", "RightControl", function(v)
    print("Key:", v)
end)

GenSection:CreateButton("Destroy GUI", function()
    Window.GUI:Destroy()
end)

-- Hotkey toggle: RightControl
Window:SetKey(Enum.KeyCode.RightControl)
