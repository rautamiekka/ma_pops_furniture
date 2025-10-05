-- nightstands.lua — add right-click autostash
local MODNAME = minetest.get_current_modname()
local MODPATH = minetest.get_modpath(MODNAME)
local C       = dofile(MODPATH.."/compat.lua")

local function nightstand_formspec()
  return "size[9,10]"..
         "bgcolor[#080808BB;true]"..
         "list[current_name;storage;3,1.5;3,3;]"..
         "list[current_player;main;0.5,6.2;8,4;]"
end

-- Ensure storage lists exist (safe to call anytime)
local function ensure_inv(meta)
  local inv = meta:get_inventory()
  if inv:get_size("storage") == 0 then inv:set_size("storage", 3*3) end
  if inv:get_size("main")    == 0 then inv:set_size("main",    8*4) end
  if meta:get_string("formspec") == "" then
    meta:set_string("formspec", nightstand_formspec())
  end
  return inv
end

-- Right-click behavior:
-- - If sneaking or empty hand -> open UI
-- - Else try to insert wielded stack into storage, return leftover to hand
local function on_rightclick_autostash(pos, node, clicker, itemstack)
  if not clicker or not clicker:is_player() then return itemstack end
  local pname = clicker:get_player_name()
  if minetest.is_protected(pos, pname) then
    minetest.record_protection_violation(pos, pname)
    return itemstack
  end

  local ctrl = clicker:get_player_control() or {}
  local empty_hand = (not itemstack) or itemstack:is_empty()

  if ctrl.sneak or empty_hand then
    -- Open inventory UI
    minetest.show_formspec(pname, "ma_pops_furniture:nightstand", nightstand_formspec())
    return itemstack
  end

  -- Auto-stash
  local meta = minetest.get_meta(pos)
  local inv  = ensure_inv(meta)

  -- Try to add entire wielded stack; keep leftovers in hand
  local leftover = inv:add_item("storage", itemstack)
  -- Optional tiny feedback
  if leftover:get_count() < itemstack:get_count() then
    minetest.sound_play("default_place_node_hard", {pos=pos, gain=0.15, max_hear_distance=8}, true)
  end
  return leftover
end

local function get_planks_tex(material)
  if not C.IS_MCL then
    return "default_" .. material .. ".png"
  end
  local map = {
    wood         = "oak",
    acacia_wood  = "acacia",
    aspen_wood   = "birch",
    pine_wood    = "spruce",
    junglewood   = "jungle",
  }
  local mcl_kind = map[material] or "oak"
  return "mcl_core_planks_" .. mcl_kind .. ".png"
end

local night_table = {
  {'Wood Nightstand',        'wood'},
  {'Acacia Wood Nightstand', 'acacia_wood'},
  {'Aspen Wood Nightstand',  'aspen_wood'},
  {'Pine Wood Nightstand',   'pine_wood'},
  {'Jungle Wood Nightstand', 'junglewood'},
}

for i = 1, #night_table do
  local name     = night_table[i][1]
  local material = night_table[i][2]

  minetest.register_node("ma_pops_furniture:nightstand_"..material, {
    description = name,
    drawtype    = "nodebox",
    tiles       = { get_planks_tex(material) },
    groups      = C.wood_groups({ oddly_breakable_by_hand = 2, furniture = 1, flammable = 1 }),
    paramtype   = "light",
    paramtype2  = "facedir",
    sounds      = C.sounds.wood(),

    on_construct = function(pos)
      local meta = minetest.get_meta(pos)
      meta:set_string("formspec", nightstand_formspec())
      ensure_inv(meta)
    end,

    on_rightclick = on_rightclick_autostash,

    can_dig = function(pos, player)
      local inv = ensure_inv(minetest.get_meta(pos))
      return inv:is_empty("storage")
    end,

    node_box = {
      type  = "fixed",
      fixed = {
        {-0.5,   -0.5,   -0.4375,  0.5,   -0.4375,  0.5},
        {-0.5,    0.4375,-0.4375,  0.5,    0.5,     0.5},
        {-0.5,   -0.4375,-0.375,   0.5,    0.4375,  0.5},
        {-0.4375,  0.0625,-0.4375, 0.4375, 0.375,  -0.375},
        {-0.4375, -0.375, -0.4375, 0.4375,-0.0625, -0.375},
        {-0.125,  -0.3125, -0.5,   0.125, -0.125,  -0.4375},
        {-0.125,   0.125,  -0.5,   0.125,  0.3125, -0.4375},
      },
    },
  })
end
