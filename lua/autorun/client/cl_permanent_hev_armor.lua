--[[
    Permanent HEV Suit Armor HUD (CHudBattery Fix)
    Keeps the Half-Life 2 / Garry's Mod HEV Suit armor HUD element permanently visible
    on screen with a native-matched "0" when armor reaches 0.

    When armor > 0, the native C++ CHudBattery handles all drawing, damage effects,
    and animations untouched. This addon ONLY draws when armor is exactly 0.
]]

if SERVER then
    AddCSLuaFile("autorun/client/cl_permanent_hev_armor.lua")
    AddCSLuaFile("autorun/sh_permanent_hev_armor.lua")
    return
end

-- Client ConVars
local cv_enabled = CreateClientConVar(
    "cl_hev_armor_always_visible",
    "1",
    true,
    false,
    "Keep the HEV suit armor HUD visible with '0' when armor is 0 (1 = enabled, 0 = default GMod behavior)"
)
local cv_require_suit = CreateClientConVar(
    "cl_hev_armor_require_suit",
    "1",
    true,
    false,
    "Only show the armor HUD when the player has the HEV suit equipped (1 = require suit, 0 = always show)"
)
local cv_notify = CreateClientConVar(
    "cl_hev_armor_notify",
    "1",
    true,
    false,
    "Show activation & status notifications in chat and on screen (1 = notify on start, 0 = silent)"
)

-- Colors from garrysmod/resource/ClientScheme.res
local COLOR_FG_HUD = Color(255, 220, 0, 220)
local COLOR_BG_HUD = Color(0, 0, 0, 90)

local isCallingShouldDraw = false

-- VGUI proportional scaling (matches CSchemeManager::GetProportionalScaledValue based on 480p height)
local function VGUIScale(val)
    if ScreenScaleH then
        return math.floor(ScreenScaleH(val))
    end
    return math.floor(val * (ScrH() / 480.0))
end

local function VGUIScaleRound(val)
    if ScreenScaleH then
        return math.Round(ScreenScaleH(val))
    end
    return math.Round(val * (ScrH() / 480.0))
end

-- Create proportionally-scaled fonts matching native C++ VGUI sizes exactly
local function CreateHEVFonts()
    local numTall = math.max(16, VGUIScaleRound(32))
    local labelTall = math.max(8, VGUIScaleRound(9))

    -- Crisp, exact native Half-Life 2 numbers without blur or glow
    surface.CreateFont("PermanentHEVArmor_ZeroFont", {
        font = "HalfLife2",
        size = numTall,
        weight = 0,
        antialias = true,
        additive = true
    })

    -- Native-matched SUIT label
    surface.CreateFont("PermanentHEVArmor_SuitFont", {
        font = "Verdana",
        size = labelTall,
        weight = 700,
        antialias = true
    })
end

CreateHEVFonts()
hook.Add("OnScreenSizeChanged", "PermanentHEVArmor_ResizeFonts", CreateHEVFonts)

-- =========================================================================
-- Diagnostics & Status Reporting
-- =========================================================================

local function RunHEVArmorDiagnostics()
    local ply = LocalPlayer()
    if not IsValid(ply) then
        return false, "Player entity is not yet initialized"
    end

    if not cv_enabled:GetBool() then
        return false, "Addon is turned off ('cl_hev_armor_always_visible' is 0). Type 'cl_hev_armor_always_visible 1' in console to activate it"
    end

    local cv_drawhud = GetConVar("cl_drawhud")
    if cv_drawhud and not cv_drawhud:GetBool() then
        return false, "All HUD drawing is turned off ('cl_drawhud' is 0). Type 'cl_drawhud 1' in console"
    end

    if cv_require_suit:GetBool() and not ply:IsSuitEquipped() then
        return false, "HEV Suit is not equipped! Equip an HEV Suit, or type 'cl_hev_armor_require_suit 0' in console to show the HUD without a suit"
    end

    isCallingShouldDraw = true
    local shouldDraw = hook.Run("HUDShouldDraw", "CHudBattery")
    isCallingShouldDraw = false

    if shouldDraw == false then
        return false, "Another addon or gamemode is actively hiding the armor HUD (CHudBattery was blocked by HUDShouldDraw hook)"
    end

    return true, "Your automatic permanent HEV Armor is now activated"
end

local hasAnnouncedSuccess = false
local lastAnnouncedProblem = nil

local function AnnounceHEVArmorStatus(force)
    if not force and not cv_notify:GetBool() then return end

    local ok, reason = RunHEVArmorDiagnostics()

    if ok then
        if not force and hasAnnouncedSuccess and lastAnnouncedProblem == nil then
            return
        end

        hasAnnouncedSuccess = true
        lastAnnouncedProblem = nil

        -- 1. In-game Chat Box message
        chat.AddText(
            Color(255, 170, 0), "[HEV Armor] ",
            Color(80, 255, 80), "Your automatic permanent HEV Armor is now activated"
        )

        -- 2. On-screen Notification Box
        if notification and notification.AddLegacy then
            notification.AddLegacy("Your automatic permanent HEV Armor is now activated", NOTIFY_GENERIC, 5)
        end

        -- 3. Sound effect
        surface.PlaySound("buttons/button14.wav")

        -- 4. Console log
        MsgC(Color(255, 170, 0), "[Permanent HEV Armor] ", Color(80, 255, 80), "Your automatic permanent HEV Armor is now activated\n")
    else
        if not force and lastAnnouncedProblem == reason then
            return
        end

        hasAnnouncedSuccess = false
        lastAnnouncedProblem = reason

        -- 1. In-game Chat Box message
        chat.AddText(
            Color(255, 170, 0), "[HEV Armor] ",
            Color(255, 70, 70), "There's a problem: ",
            Color(255, 220, 220), reason
        )

        -- 2. On-screen Notification Box
        if notification and notification.AddLegacy then
            notification.AddLegacy("HEV Armor problem: " .. reason, NOTIFY_ERROR, 8)
        end

        -- 3. Sound effect
        surface.PlaySound("buttons/button10.wav")

        -- 4. Console log
        MsgC(Color(255, 170, 0), "[Permanent HEV Armor] ", Color(255, 70, 70), "PROBLEM: " .. reason .. "\n")
    end
end

-- Console command for status testing
concommand.Add("hev_armor_status", function()
    AnnounceHEVArmorStatus(true)
end)

concommand.Add("cl_hev_armor_status", function()
    AnnounceHEVArmorStatus(true)
end)

-- Chat command support (!hev or /hev)
hook.Add("OnPlayerChat", "PermanentHEVArmor_ChatCommand", function(ply, text)
    if ply == LocalPlayer() then
        local cmd = string.Trim(string.lower(text))
        if cmd == "!hev" or cmd == "/hev" or cmd == "!armor" then
            AnnounceHEVArmorStatus(true)
            return true
        end
    end
end)

-- ConVar adjustment callbacks
cvars.AddChangeCallback("cl_hev_armor_always_visible", function(_, _, _)
    timer.Simple(0.1, function() AnnounceHEVArmorStatus(true) end)
end, "PermanentHEVArmor_ToggleNotify")

cvars.AddChangeCallback("cl_hev_armor_require_suit", function(_, _, _)
    timer.Simple(0.1, function() AnnounceHEVArmorStatus(true) end)
end, "PermanentHEVArmor_SuitNotify")

-- Startup check trigger
local startupCheckStarted = false
local function TriggerStartupCheck()
    if startupCheckStarted then return end
    startupCheckStarted = true

    timer.Simple(2.0, function()
        AnnounceHEVArmorStatus(false)
    end)
end

hook.Add("InitPostEntity", "PermanentHEVArmor_InitPostEntity", function()
    TriggerStartupCheck()
end)

if IsValid(LocalPlayer()) then
    TriggerStartupCheck()
end

-- =========================================================================
-- HUD Drawing Logic
-- =========================================================================

local function CanDrawBatteryHUD(ply)
    if not IsValid(ply) or not ply:Alive() then return false end

    local cv_drawhud = GetConVar("cl_drawhud")
    if cv_drawhud and not cv_drawhud:GetBool() then return false end

    if cv_require_suit:GetBool() and not ply:IsSuitEquipped() then
        return false
    end

    isCallingShouldDraw = true
    local shouldDraw = hook.Run("HUDShouldDraw", "CHudBattery")
    isCallingShouldDraw = false

    if shouldDraw == false then
        return false
    end

    return true
end

-- When armor > 0, let the native C++ CHudBattery draw everything natively (damage flash, animations, numbers).
-- When armor is 0, suppress the native C++ panel so it doesn't fade to invisible, allowing our clean "0" to stay visible.
hook.Add("HUDShouldDraw", "PermanentHEVArmor_HideDefault", function(name)
    if isCallingShouldDraw then return end
    if name ~= "CHudBattery" then return end
    if not cv_enabled:GetBool() then return end

    local ply = LocalPlayer()
    if IsValid(ply) and ply:Armor() > 0 then
        -- Native C++ CHudBattery handles all positive armor! Do NOT hide!
        return
    end

    -- Only suppress native when armor <= 0
    return false
end)

-- Render the native-matched "0" SUIT panel ONLY when armor is 0
hook.Add("HUDPaint", "PermanentHEVArmor_Draw", function()
    if not startupCheckStarted and IsValid(LocalPlayer()) then
        TriggerStartupCheck()
    end

    if not cv_enabled:GetBool() then return end

    local ply = LocalPlayer()
    if not CanDrawBatteryHUD(ply) then return end

    -- DO NOT DRAW ANYTHING when armor > 0!
    -- The native C++ engine handles all numbers above 0 untouched.
    if ply:Armor() > 0 then return end

    -- Layout coordinates from scripts/HudLayout.res ("HudSuit"):
    -- xpos = 140, ypos = 432, wide = 108, tall = 36
    -- text_xpos = 8, text_ypos = 20, digit_xpos = 50, digit_ypos = 2
    local x = VGUIScale(140)
    local y = VGUIScale(432)
    local w = VGUIScale(108)
    local h = VGUIScale(36)
    local cornerRadius = math.max(4, math.Round(VGUIScale(4)))

    local textX = x + VGUIScale(8)
    local textY = y + VGUIScale(20)
    local digitX = x + VGUIScale(50)
    local digitY = y + VGUIScale(2)

    -- 1. Background box (PaintBackgroundType 2)
    draw.RoundedBox(cornerRadius, x, y, w, h, COLOR_BG_HUD)

    -- 2. Localized "SUIT" text label in native HudDefault font
    local suitLabel = language.GetPhrase("Valve_Hud_SUIT")
    if not suitLabel or suitLabel == "" or suitLabel == "Valve_Hud_SUIT" then
        suitLabel = "SUIT"
    end
    suitLabel = string.upper(suitLabel)

    surface.SetFont("PermanentHEVArmor_SuitFont")
    surface.SetTextColor(COLOR_FG_HUD.r, COLOR_FG_HUD.g, COLOR_FG_HUD.b, COLOR_FG_HUD.a)
    surface.SetTextPos(textX, textY)
    surface.DrawText(suitLabel)

    -- 3. Native-sized and naturally-positioned "0" (digit_xpos = 50, digit_ypos = 2)
    -- Crisp, standard Half-Life 2 yellow text without artificial blur/glow
    surface.SetFont("PermanentHEVArmor_ZeroFont")
    surface.SetTextColor(COLOR_FG_HUD.r, COLOR_FG_HUD.g, COLOR_FG_HUD.b, COLOR_FG_HUD.a)
    surface.SetTextPos(digitX, digitY)
    surface.DrawText("0")
end)
