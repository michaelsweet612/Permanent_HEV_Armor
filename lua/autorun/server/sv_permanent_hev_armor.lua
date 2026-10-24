--[[
    Permanent HEV Suit Armor HUD - Server Autorun
    Provides server-side support to ensure players have the HEV suit equipped,
    and optional spawn armor support.
]]

if SERVER then
    AddCSLuaFile("autorun/client/cl_permanent_hev_armor.lua")
    AddCSLuaFile("autorun/sh_permanent_hev_armor.lua")
end

local cv_auto_suit = CreateConVar(
    "sv_hev_auto_suit",
    "1",
    bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY),
    "Ensure players spawn with the HEV suit equipped so the armor HUD is active (1 = auto equip, 0 = default)"
)

local cv_spawn_armor = CreateConVar(
    "sv_hev_spawn_armor",
    "0",
    bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY),
    "Amount of armor to automatically grant to players on spawn (0 = disabled, e.g. 100)"
)

hook.Add("PlayerSpawn", "PermanentHEVArmor_ServerSpawn", function(ply)
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end

        -- Auto-equip suit so the player always has the HEV suit enabled
        if cv_auto_suit:GetBool() and not ply:IsSuitEquipped() then
            if ply.EquipSuit then
                ply:EquipSuit()
            else
                ply:Give("item_suit")
            end
        end

        -- Optional auto-armor refill on spawn
        local spawnArmor = cv_spawn_armor:GetInt()
        if spawnArmor > 0 then
            ply:SetArmor(spawnArmor)
        end
    end)
end)

MsgC(Color(0, 255, 128), "[Permanent HEV Armor] Server autorun script loaded.\n")
