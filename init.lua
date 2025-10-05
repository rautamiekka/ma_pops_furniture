-- init.lua (rewritten)
-- Cross-game bootstrap for ma_pops_furniture (Minetest Game + Mineclonia/MineClone)

-- 1) Module table (kept global for legacy access)
ma_pops_furniture = ma_pops_furniture or {}

-- 2) Basic ids/paths
local MODNAME = minetest.get_current_modname()
local MODPATH = minetest.get_modpath(MODNAME)

-- 3) Game detection
local IS_MCL = minetest.get_modpath("mcl_core") ~= nil
ma_pops_furniture.IS_MCL = IS_MCL

-- 4) Translator: prefer MT’s translator, fallback to intllib if present
local S = minetest.get_translator and minetest.get_translator(MODNAME)
if not S then
  -- try intllib.lua inside this mod (classic style)
  local ok, tr = pcall(dofile, MODPATH.."/intllib.lua")
  if ok and type(tr) == "table" and tr[1] then
    S = tr[1] -- S, NS = dofile("intllib.lua")
  else
    -- no translation backend—use identity function
    S = function(s) return s end
  end
end
ma_pops_furniture.S = S

-- 5) moditems shim (unifies item/sounds/boxart across games)
moditems = {}  -- keep global for legacy references
ma_pops_furniture.moditems = moditems

-- Sounds helpers (present in most games/mods)
local function wood_sounds()
  if IS_MCL and mcl_sounds and mcl_sounds.node_sound_wood_defaults then
    return mcl_sounds.node_sound_wood_defaults()
  end
  if default and default.node_sound_wood_defaults then
    return default.node_sound_wood_defaults()
  end
  return {}
end

local function metal_sounds()
  if IS_MCL and mcl_sounds and mcl_sounds.node_sound_metal_defaults then
    return mcl_sounds.node_sound_metal_defaults()
  end
  if default and default.node_sound_metal_defaults then
    return default.node_sound_metal_defaults()
  end
  -- fallback to stone if metal not present
  if default and default.node_sound_stone_defaults then
    return default.node_sound_stone_defaults()
  end
  return {}
end

local function stone_sounds()
  if IS_MCL and mcl_sounds and mcl_sounds.node_sound_stone_defaults then
    return mcl_sounds.node_sound_stone_defaults()
  end
  if default and default.node_sound_stone_defaults then
    return default.node_sound_stone_defaults()
  end
  return {}
end

-- Inventory / formspec background shims
local function inventory_bg_formspec()
  -- Prefer builtin helper if present in game
  if default and default.gui_bg and default.gui_bg_img and default.gui_slots then
    -- You’ll usually concatenate these where needed—here we just return empty to avoid double-adding.
    return ""  -- Use default.gui_* directly in formspec files.
  end
  -- Mineclonia often uses image backgrounds via mcl_inventory helpers.
  -- Provide a neutral listcolors/bg fallback that works anywhere:
  return "bgcolor[#00000000;true]listcolors[#666666;#3b3b3b;#141414;#d9d9d9;#ffffff]"
end

if IS_MCL then
  -- Mineclonia / MineClone
  moditems.IRON_ITEM          = "mcl_core:iron_ingot"
  moditems.COAL_ITEM          = "mcl_core:coalblock"
  moditems.CORAL_SKELETON     = "mcl_nether:quartz_block"  -- no direct coral skeleton; quartz is a solid white-ish block
  moditems.SILVER_SANDSTONE   = "mcl_core:sandstone"       -- closest generic light stone
  moditems.INVENTORY_BG       = inventory_bg_formspec()
  moditems.INFOBOX_CAN        = {}                         -- UI strings differ; keep neutral in code or translate via S()
  moditems.INFOBOX_DUMP       = {}
  moditems.BOXART             = "bgcolor[#d0d0d0;false]listcolors[#9d9d9d;#9d9d9d;#5c5c5c;#000000;#ffffff]"
else
  -- Minetest Game (default)
  moditems.IRON_ITEM          = "default:steel_ingot"
  moditems.COAL_ITEM          = "default:coalblock"
  moditems.CORAL_SKELETON     = "default:coral_skeleton"
  moditems.SILVER_SANDSTONE   = "default:silver_sandstone"
  moditems.INVENTORY_BG       = inventory_bg_formspec()
  moditems.INFOBOX_CAN        = S("Trash Can")
  moditems.INFOBOX_DUMP       = S("Dumpster")
  moditems.BOXART             = ""                         -- MTG formspecs typically use default.gui_* pieces directly
end

-- Expose standard sound tables so nodes can do: sounds = moditems.WOOD_SOUNDS
moditems.WOOD_SOUNDS  = wood_sounds()
moditems.METAL_SOUNDS = metal_sounds()
moditems.STONE_SOUNDS = stone_sounds()

-- 6) (Optional) handy flags on the API
ma_pops_furniture.WOOD_SOUNDS  = moditems.WOOD_SOUNDS
ma_pops_furniture.METAL_SOUNDS = moditems.METAL_SOUNDS
ma_pops_furniture.STONE_SOUNDS = moditems.STONE_SOUNDS

-- 7) Safe loader helpers
local function load_file(relpath, required)
  local path = MODPATH .. "/" .. relpath
  local ok, err = pcall(dofile, path)
  if not ok then
    minetest.log("error", ("[%s] Failed to load %s: %s"):format(MODNAME, relpath, err))
    if required then
      error(("[%s] Required file failed: %s"):format(MODNAME, relpath))
    end
  end
end

local function try_load(relpath)
  -- Only load if the file actually exists (prevents noisy errors for optional pieces)
  local f = io.open(MODPATH .. "/" .. relpath, "r")
  if f then f:close(); load_file(relpath, false) end
end

-- 8) Load compat *first*, then the rest. Mark critical modules as required.
try_load("compat.lua")          -- makes helpers available to modules (optional)

-- Core feature files. If any of these are truly required for the mod to function, use load_file(..., true)
try_load("functions.lua")
try_load("formspecs.lua")

-- Feature sets (keep non-fatal on error so other parts still work)
try_load("abm.lua")
try_load("bathroom.lua")
try_load("bedroom.lua")
try_load("kitchen.lua")
try_load("living_room.lua")
try_load("microwave.lua")
try_load("dining_room.lua")
try_load("outside.lua")
try_load("misc.lua")
try_load("oven.lua")
try_load("joyb.lua")
try_load("stereo.lua")
try_load("sofa.lua")
try_load("tv.lua")
try_load("toys.lua")
try_load("toaster.lua")
try_load("fridge.lua")
try_load("crafts.lua")

-- 9) Final log
minetest.log("action", ("[%s] Loaded (IS_MCL=%s)"):format(MODNAME, tostring(IS_MCL)))
