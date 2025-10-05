-- freezer_fridges_compat.lua — Minetest Game + Mineclonia compatible
local MODNAME = minetest.get_current_modname()
local MODPATH = minetest.get_modpath(MODNAME)
local C = dofile(MODPATH .. "/compat.lua")

-- =============== UI helpers (portable) ===============
local function hotbar_bg(x, y)
  if default and default.get_hotbar_bg then
    return default.get_hotbar_bg(x, y)                      -- MTG
  elseif rawget(_G, "mcl_formspec") and mcl_formspec.get_hotbar_bg then
    return mcl_formspec.get_hotbar_bg(x, y)                 -- MCL
  else
    return ""
  end
end

local function default_ui_bits()
  local s = {}
  if default and default.gui_bg     then s[#s+1] = default.gui_bg end
  if default and default.gui_bg_img then s[#s+1] = default.gui_bg_img end
  if default and default.gui_slots  then s[#s+1] = default.gui_slots end
  return table.concat(s)
end

local function active_formspec(item_percent)
  -- size + MTG chrome (no-ops in Mineclonia)
  local fs = {
    "formspec_version[4]",
    "size[8,8.5]",
    default_ui_bits(),
    "list[current_name;src;2.5,1;1,1;]",
    "image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[lowpart:" ..
      (item_percent or 0) .. ":gui_furnace_arrow_fg.png^[transformR270]",
    "list[current_name;dst;4.75,0.96;3,2;]",
    "list[current_player;main;0,4.25;8,1;]",
    "list[current_player;main;0,5.5;8,3;8]",
    "listring[current_name;dst]",
    "listring[current_player;main]",
    "listring[current_name;src]",
    "listring[current_player;main]",
    hotbar_bg(0, 4.25),
  }
  return table.concat(fs)
end

local inactive_formspec = (function()
  local fs = {
    "formspec_version[4]",
    "size[8,8.5]",
    default_ui_bits(),
    "list[current_name;src;2.5,1.5;1,1;]",
    "image[3.75,1.5;1,1;gui_furnace_arrow_bg.png^[transformR270]",
    "list[current_name;dst;4.75,0.96;3,2;]",
    "list[current_player;main;0,4.25;8,1;]",
    "list[current_player;main;0,5.5;8,3;8]",
    "listring[current_name;dst]",
    "listring[current_player;main]",
    "listring[current_name;src]",
    "listring[current_player;main]",
    hotbar_bg(0, 4.25),
  }
  return table.concat(fs)
end)()

-- =============== Inventory helpers ===============
local function can_dig(pos, _player)
  local inv = minetest.get_meta(pos):get_inventory()
  return inv:is_empty("dst") and inv:is_empty("src")
end

local function allow_metadata_inventory_put(pos, listname, _index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then
    return 0
  end
  if listname == "src" then
    return stack:get_count()
  end
  return 0
end

local function allow_metadata_inventory_move(pos, _from_list, _from_index, to_list, to_index, _count, player)
  local inv = minetest.get_meta(pos):get_inventory()
  local stack = inv:get_stack(_from_list, _from_index)
  return allow_metadata_inventory_put(pos, to_list, to_index, stack, player)
end

local function allow_metadata_inventory_take(pos, _listname, _index, stack, player)
  if minetest.is_protected(pos, player:get_player_name()) then
    return 0
  end
  return stack:get_count()
end

-- Robust inventory dropper (works even if default.get_inventory_drops is missing)
local function add_inv_drops(pos, lists, drops)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  for _, listname in ipairs(lists) do
    local size = inv:get_size(listname) or 0
    for i = 1, size do
      local st = inv:get_stack(listname, i)
      if not st:is_empty() then
        drops[#drops+1] = st:to_string()
      end
    end
  end
end

-- =============== The freezer logic (top node timer) ===============
local WATER_BUCKETS = C.IS_MCL and {"mcl_buckets:bucket_water"} or {"bucket:bucket_water", "bucket:bucket_river_water"}
local EMPTY_BUCKET  = C.IS_MCL and "mcl_buckets:bucket_empty" or "bucket:bucket_empty"
local ICE_ITEM      = C.IS_MCL and "mcl_core:ice" or "default:ice"

local function freezer_node_timer(pos, _elapsed)
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()

  -- find a water bucket we can consume (first match wins)
  local found
  for _, name in ipairs(WATER_BUCKETS) do
    if inv:contains_item("src", name) then
      found = name
      break
    end
  end

  if found and inv:room_for_item("dst", ICE_ITEM) and inv:room_for_item("dst", EMPTY_BUCKET) then
    inv:remove_item("src", found)
    inv:add_item("dst", ICE_ITEM)
    inv:add_item("dst", EMPTY_BUCKET)
    -- simple progress look
    meta:set_string("formspec", active_formspec(100))
  else
    meta:set_string("formspec", inactive_formspec)
  end

  -- keep ticking while there is still a water bucket present
  if found then
    return true
  end
  return false
end

-- =============== Fridge (bottom) + Freezer (top) nodes ===============
local color1 = (minetest.settings and minetest.settings:get("color1")) or "292421"
local color2 = (minetest.settings and minetest.settings:get("color2")) or "0000FF"
local color3 = (minetest.settings and minetest.settings:get("color3")) or "00FF00"
local color4 = (minetest.settings and minetest.settings:get("color4")) or "F5F5F5"
local color5 = (minetest.settings and minetest.settings:get("color5")) or "FF6103"
local color6 = (minetest.settings and minetest.settings:get("color6")) or "FF0000"
local color7 = (minetest.settings and minetest.settings:get("color7")) or "FFFF00"
local color8 = (minetest.settings and minetest.settings:get("color8")) or "FF69B4"

local fridges_list = {
  {"black",  "Darkened Fridge", color1},
  {"blue",   "Blue Fridge",     color2},
  {"green",  "Green Fridge",    color3},
  {"white",  "White Fridge",    color4},
  {"orange", "Orange Fridge",   color5},
  {"red",    "Red Fridge",      color6},
  {"yellow", "Yellow Fridge",   color7},
  {"pink",   "Pink Fridge",     color8},
}

for _, fridge in ipairs(fridges_list) do
  local colour, fridgedesc, colour_hex = fridge[1], fridge[2], fridge[3]

  -- Bottom (fridge body)
  minetest.register_node("ma_pops_furniture:fridge_"..colour, {
    description = fridgedesc,
    drawtype = "nodebox",
    tiles = {
      "mp_dfridge_top.png^[colorize:#"..colour_hex..":70",
      "mp_dfridge_bottom.png^[colorize:#"..colour_hex..":70",
      "mp_dfridge_right.png^[colorize:#"..colour_hex..":70",
      "mp_dfridge_left.png^[colorize:#"..colour_hex..":70",
      "mp_dfridge_back.png^[colorize:#"..colour_hex..":70",
      "mp_dfridge_front.png^[colorize:#"..colour_hex..":70",
    },
    paramtype  = "light",
    paramtype2 = "facedir",
    stack_max  = 1,
    groups     = C.wood_groups({snappy=1, choppy=2, oddly_breakable_by_hand=2, flammable=3}),
    sounds     = C.sounds.wood(),
    node_box = {
      type  = "fixed",
      fixed = {
        {-0.5, -0.5, -0.3125, 0.5,   0.5,  0.5},
        {-0.5, -0.25,-0.375,  0.5,   0.5, -0.3125},
        {-0.5, -0.5, -0.375,  0.5,  -0.3125,-0.3125},
        { 0.375, 0,  -0.4375, 0.4375,0.5, -0.375},
      }
    },

    after_place_node = function(pos, placer, itemstack)
      local node = minetest.get_node(pos)
      local ptop = {x=pos.x, y=pos.y+1, z=pos.z}
      if minetest.registered_nodes[minetest.get_node(ptop).name]
         and minetest.registered_nodes[minetest.get_node(ptop).name].buildable_to then
        minetest.set_node(ptop, { name = "ma_pops_furniture:fridge_top_"..colour, param2 = node.param2 })
      else
        minetest.remove_node(pos)
        return true
      end
    end,

    on_construct = function(pos)
      -- Optional storage in the bottom (kept from your code)
      local meta = minetest.get_meta(pos)
      local inv  = meta:get_inventory()
      inv:set_size("main",    8*4)
      inv:set_size("storage", 6*4)
      meta:set_string("formspec",
        "formspec_version[4]"..
        "size[9,10]"..
        "bgcolor[#080808BB;true]"..
        "list[current_name;storage;2,1.5;6,4;]"..
        "list[current_player;main;0.5,6.2;8,4;]"
      )
    end,

    on_destruct = function(pos)
      local node     = minetest.get_node(pos)
      local ptop     = {x=pos.x, y=pos.y+1, z=pos.z}
      local aboven   = minetest.get_node(ptop)
      if aboven.name == "ma_pops_furniture:fridge_top_"..colour
         and aboven.param2 == node.param2 then
        minetest.remove_node(ptop)
      end
    end,
  })

  -- Top (freezer with inventory + timer)
  minetest.register_node("ma_pops_furniture:fridge_top_"..colour, {
    description = fridgedesc,
    drawtype = "nodebox",
    tiles = {
      "mp_ufridge_top.png^[colorize:#"..colour_hex..":70",
      "default_wood.png^[colorize:#"..colour_hex..":70",
      "mp_ufridge_right.png^[colorize:#"..colour_hex..":70",
      "mp_ufridge_left.png^[colorize:#"..colour_hex..":70",
      "mp_fridge_back.png^[colorize:#"..colour_hex..":70",
      "mp_ufridge_front.png^[colorize:#"..colour_hex..":70",
    },
    paramtype  = "light",
    paramtype2 = "facedir",
    groups     = C.wood_groups({snappy=1, choppy=2, oddly_breakable_by_hand=2, flammable=3, not_in_creative_inventory=1}),
    sounds     = C.sounds.wood(),
    node_box = {
      type  = "fixed",
      fixed = {
        {-0.5, -0.5, -0.3125, 0.5,   0.5,  0.5},
        {-0.5,  0.3125,-0.375, 0.5,  0.5, -0.3125},
        {-0.5, -0.3125,-0.375, 0.5,  0.25,-0.3125},
        {-0.5, -0.5,  -0.375,  0.5, -0.375,-0.3125},
        { 0.375,-0.25,-0.4375, 0.4375,0.125,-0.375},
      }
    },

    can_dig   = can_dig,
    on_timer  = freezer_node_timer,

    on_construct = function(pos)
      local meta = minetest.get_meta(pos)
      meta:set_string("formspec", inactive_formspec)
      local inv = meta:get_inventory()
      inv:set_size("src", 1)
      inv:set_size("dst", 6)
    end,

    on_metadata_inventory_move = function(pos)
      minetest.get_node_timer(pos):start(1.0)
    end,
    on_metadata_inventory_put = function(pos)
      minetest.get_node_timer(pos):start(1.0)
    end,

    on_blast = function(pos)
      local drops = {}
      add_inv_drops(pos, {"src","dst"}, drops)
      drops[#drops+1] = "ma_pops_furniture:fridge_white" -- fallback item; change if you want a per-color drop
      minetest.remove_node(pos)
      return drops
    end,

    allow_metadata_inventory_put  = allow_metadata_inventory_put,
    allow_metadata_inventory_move = allow_metadata_inventory_move,
    allow_metadata_inventory_take = allow_metadata_inventory_take,
  })
end

-- =============== Craft (ice -> snow blocks), per game ===============
if C.IS_MCL then
  minetest.register_craft({
    output = "mcl_core:snow 3",
    type   = "shapeless",
    recipe = {"mcl_core:ice"}
  })
else
  minetest.register_craft({
    output = "default:snowblock 3",
    type   = "shapeless",
    recipe = {"default:ice"}
  })
end
