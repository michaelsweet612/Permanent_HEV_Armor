# Permanent HEV Suit Armor HUD (Garry's Mod Addon)

Keeps the Half-Life 2 / Garry's Mod HEV Suit armor HUD (`CHudBattery` / `HudSuit`) visible on screen displaying **`0`** when your armor drops to zero, matching the Health display.

## How it Works
- **When Armor > 0:** The game's native C++ HUD (`CHudBattery`) handles all numbers (100, 50, etc.), damage effects, red flashes, and animations untouched.
- **When Armor = 0:** The addon maintains the SUIT panel displaying `0` in the exact native font (`HudNumbers`), right-aligned to match the Health 0 column.

## Installation & Structure
Addon path:
`Steam/steamapps/common/GarrysMod/garrysmod/addons/permanent_hev_armor_hud`

Structure:
```
garrysmod/addons/permanent_hev_armor_hud/
  ├── addon.json
  ├── README.md
  └── lua/
        └── autorun/
              ├── sh_permanent_hev_armor.lua
              ├── client/
              │     └── cl_permanent_hev_armor.lua
              └── server/
                    └── sv_permanent_hev_armor.lua
```

## Commands
- **Console:** `hev_armor_status` or `cl_hev_armor_status` (Runs diagnostics and checks status).
- **Chat:** `!hev` or `/hev`

## Console Variables
- `cl_hev_armor_always_visible` (default `1`): Keep the armor HUD visible at `0` armor.
- `cl_hev_armor_require_suit` (default `1`): Only show when the HEV suit is equipped.
- `cl_hev_armor_notify` (default `1`): Show activation message on load/spawn.
- `sv_hev_auto_suit` (default `1`): Ensures players spawn with an HEV suit.
- `sv_hev_spawn_armor` (default `0`): Optional spawn armor amount.
