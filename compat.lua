local M = {}

-- Detect Mineclonia by checking for mcl_core
M.IS_MCL = minetest.get_modpath("mcl_core") ~= nil

-- Namespaces / item mapping
if M.IS_MCL then
  -- Core items
  M.items = {
    stick  = "mcl_core:stick",
    planks = "mcl_core:wood",      -- generic wooden planks
    slab   = "mcl_stairs:slab_wood",
    glass  = "mcl_core:glass",
    iron   = "mcl_core:iron_ingot",
    wool   = function(color) return "mcl_wool:" .. color end,
    dye    = function(color) return "mcl_dye:" .. color end,
    bed    = "mcl_beds:bed_white", -- in case you referenced a bed
  }
else
  M.items = {
    stick  = "default:stick",
    planks = "default:wood",
    slab   = "stairs:slab_wood",
    glass  = "default:glass",
    iron   = "default:steel_ingot",
    wool   = function(color) return "wool:" .. color end,
    dye    = function(color) return "dye:" .. color end,
    bed    = "beds:bed",           -- or your target bed item
  }
end

-- Sounds
local function sound_wood()
  if M.IS_MCL and mcl_sounds and mcl_sounds.node_sound_wood_defaults then
    return mcl_sounds.node_sound_wood_defaults()
  end
  return default and default.node_sound_wood_defaults()
      or {footstep={name="default_wood_footstep", gain=0.5}}
end

local function sound_stone()
  if M.IS_MCL and mcl_sounds and mcl_sounds.node_sound_stone_defaults then
    return mcl_sounds.node_sound_stone_defaults()
  end
  return default and default.node_sound_stone_defaults()
      or {footstep={name="default_hard_footstep", gain=0.5}}
end

local function sound_glass()
  if M.IS_MCL and mcl_sounds and mcl_sounds.node_sound_glass_defaults then
    return mcl_sounds.node_sound_glass_defaults()
  end
  return default and default.node_sound_glass_defaults()
      or {footstep={name="default_glass_footstep", gain=0.3}}
end

M.sounds = {
  wood  = sound_wood,
  stone = sound_stone,
  glass = sound_glass,
}

-- Group helpers (keep your original groups, add Mineclonia’s common ones)
function M.merge_groups(base, extra)
  local g = {}
  if base then for k,v in pairs(base) do g[k]=v end end
  if extra then for k,v in pairs(extra) do g[k]=v end end
  return g
end

function M.wood_groups(extra)
  -- keep your existing furniture/building group tags
  local base = {choppy=2, oddly_breakable_by_hand=1, flammable=2, wood=1}
  -- Mineclonia commonly uses handy/axey, but this is optional
  if M.IS_MCL then base.axey = 1 end
  return M.merge_groups(base, extra)
end

function M.stone_groups(extra)
  local base = {cracky=2, stone=1}
  if M.IS_MCL then base.pickaxey = 1 end
  return M.merge_groups(base, extra)
end

function M.glass_groups(extra)
  local base = {cracky=3, oddly_breakable_by_hand=3}
  if M.IS_MCL then base.pickaxey = 1 end
  return M.merge_groups(base, extra)
end

-- Node register wrapper (mainly to inject sounds/groups consistently)
function M.register_furniture_node(name, def)
  local ndef = table.copy(def)
  -- sounds shortcut: "wood"/"stone"/"glass"
  if type(ndef.sounds) == "string" then
    ndef.sounds = (M.sounds[ndef.sounds] and M.sounds[ndef.sounds]()) or nil
  end
  -- ensure selection/collision boxes default to nodebox if drawtype says so
  if ndef.drawtype == "nodebox" and not ndef.node_box then
    ndef.node_box = {type="fixed", fixed = {}}
  end
  minetest.register_node(name, ndef)
end

-- Craft register wrapper: plain minetest.register_craft works fine in both,
-- but we centralize here in case you want game-specific recipes later.
function M.register_craft(def)
  minetest.register_craft(def)
end

return M


-- ========= Texture resolver (MTG <-> Mineclonia compatible) =========
-- Priority: moditems.TEXTURES override  -> take from registered Mineclonia nodes -> MTG fallback file

local function node_tex(nodename, idx)
  local def = minetest.registered_nodes[nodename]
  if not def or not def.tiles then return nil end
  local t = def.tiles[idx or 1]
  if type(t) == "table" then return t.name or t.image end
  return t
end

local TEX_OVERRIDE = (moditems and moditems.TEXTURES) or {}

local function pick_texture(key, candidates, fallback)
  -- 1) explicit override from your compat layer
  if TEX_OVERRIDE[key] then return TEX_OVERRIDE[key] end
  -- 2) probe Mineclonia (or any game) for a node’s tile
  for _, cand in ipairs(candidates or {}) do
    local name, idx = cand[1], cand[2] or 1
    local img = node_tex(name, idx)
    if img then return img end
  end
  -- 3) fallback MTG filename
  return fallback
end

-- Common base textures used across this file
local TEX = {
  -- smooth light-ish “stone” you used coral_skeleton for
  coral = pick_texture("coral", {
    {"mcl_core:smooth_stone", 1},
    {"mcl_core:stone", 1},
    {"mcl_nether:quartz_block", 1},
  }, "default_coral_skeleton.png"),

  stone = pick_texture("stone", {
    {"mcl_core:stone", 1},
  }, "default_stone.png"),

  brick = pick_texture("brick", {
    {"mcl_core:brick_block", 1},
  }, "default_brick.png"),

  coal_block = pick_texture("coal_block", {
    {"mcl_core:coalblock", 1},
  }, "default_coal_block.png"),

  acacia_bark = pick_texture("acacia_bark", {
    {"mcl_core:acacia_log", 1},   -- Mineclonia
    {"mcl_core:tree_acacia", 1},  -- some forks
  }, "default_acacia_tree.png"),

  tree_bark = pick_texture("tree_bark", {
    {"mcl_core:oak_log", 1},
    {"mcl_core:tree", 1},
  }, "default_tree.png"),

  pane_bar = pick_texture("pane_bar", {
    {"mcl_panes:iron_bars", 1},  -- Mineclonia iron bars
  }, "xpanes_bar.png"),

  flame_anim = pick_texture("flame_anim", {
    {"mcl_fire:fire", 1},  -- its animated tile
  }, "fire_basic_flame_animated.png"),
}

-- Wool resolver (works in MTG and Mineclonia)
local function WOOL(color)
  local key = "wool_" .. color
  if TEX_OVERRIDE[key] then return TEX_OVERRIDE[key] end
  -- Mineclonia node tiles
  local img = node_tex("mcl_wool:" .. color, 1)
  if img then return img end
  -- MTG fallback
  return "wool_" .. color .. ".png"
end

-- Expose for use below
local TEX = TEX
local WOOL = WOOL
