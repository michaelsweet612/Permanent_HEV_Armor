--[[
    Permanent HEV Suit Armor HUD - Shared Autorun
    Ensures client scripts are properly sent over the network to connecting players.
]]

if SERVER then
    AddCSLuaFile("autorun/client/cl_permanent_hev_armor.lua")
    AddCSLuaFile("autorun/sh_permanent_hev_armor.lua")
end
