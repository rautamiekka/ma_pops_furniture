local mpf = {}

-- ------- helpers -------
local function is_creative(name)
  return minetest.is_creative_enabled and minetest.is_creative_enabled(name)
end

-- Detect dye names and return color token (e.g. dye:blue -> "blue")
local function dye_color(name)
  local c = name:match("^dye:(.+)$")
  return c
end

local function can_interact(pos, player)
  return player and not minetest.is_protected(pos, player:get_player_name())
end

-- Auto-insert 1 item from wielded stack into 'storage' if room
local function try_autostash(pos, player, itemstack)
  if itemstack:is_empty() then return false end
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()
  if not inv:room_for_item("storage", ItemStack(itemstack:get_name())) then
    return false
  end
  local put = itemstack:take_item(1)
  inv:add_item("storage", put)
  if not is_creative(player:get_player_name()) then
    player:set_wielded_item(itemstack)
  end
  minetest.sound_play("default_place_node", {pos=pos, gain=0.2}, true)
  return true
end

-- Shared storage formspec (simple, works in MTG & Mineclonia)
function mpf.formspec_storage(w, h, cols, rows)
  w = w or 8; h = h or 9
  cols = cols or 6; rows = rows or 6
  return table.concat({
    "formspec_version[4]size[8,10.5]",
    (moditems.BOXART or ""),
    ("list[current_name;storage;1.5,0.2;%d,%d;]"):format(cols, rows),
    "list[current_player;main;0,6.6;8,4;]"
  })
end

local function setup_storage(pos, cols, rows)
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()
  inv:set_size("storage", (cols or 6) * (rows or 6))
  meta:set_string("formspec", mpf.formspec_storage(8, 10.5, cols, rows))
end

local function can_dig_empty_storage(pos, player)
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()
  return inv:is_empty("storage")
end

-- Generic recolor handler: swap node name suffix (…_<oldcolor>) to (…_<newcolor>)
local function recolor_node_by_suffix(pos, node, new_suffix)
  local base, old = node.name:match("^(.-)_([^_]+)$")
  if not base then return false end
  local target = base .. "_" .. new_suffix
  if not minetest.registered_nodes[target] then return false end
  minetest.swap_node(pos, {name = target, param2 = node.param2})
  minetest.sound_play("wool_place", {pos=pos, gain=0.2}, true)
  return true
end

local function on_rightclick_storage(recolor_on_rightclick)
  return function(pos, node, player, itemstack)
    if not can_interact(pos, player) then return itemstack end
    local ctrl = player:get_player_control() or {}

    -- First: dye recolor (either on punch or right-click, based on flag)
    local color = dye_color(itemstack:get_name())
    if recolor_on_rightclick and color then
      if recolor_node_by_suffix(pos, node, color) then
        if not is_creative(player:get_player_name()) then
          itemstack:take_item(1)
          player:set_wielded_item(itemstack)
        end
        return itemstack
      end
    end

    -- Second: auto-stash any item
    if try_autostash(pos, player, itemstack) then
      return itemstack
    end

    -- Finally: open formspec (empty hand or no space)
    minetest.show_formspec(player:get_player_name(), "ma_pops_furniture:storage",
      minetest.get_meta(pos):get_string("formspec"))
    return itemstack
  end
end

local function on_punch_recolor()
  return function(pos, node, puncher)
    if not can_interact(pos, puncher) then return end
    local wield = puncher:get_wielded_item()
    local color = dye_color(wield:get_name())
    if not color then return end
    if recolor_node_by_suffix(pos, node, color) then
      if not is_creative(puncher:get_player_name()) then
        wield:take_item(1)
        puncher:set_wielded_item(wield)
      end
    end
  end
end

-- ------- colored counters (stone top with colorized coral_skeleton) -------
local colored_defs = {
  {'Black', 'black', 'black:200'},
  {'Blue', 'blue', 'blue:125'},
  {'Brown', 'brown', 'brown:75'},
  {'Cyan', 'cyan', 'cyan:125'},
  {'Dark Green', 'dark_green', 'green:190'},
  {'Green', 'green', '#32cd32:125'},
  {'Magenta', 'magenta', 'magenta:190'},
  {'Orange', 'orange', 'orange:125'},
  {'Pink', 'pink', 'pink:190'},
  {'Red', 'red', 'red:125'},
  {'Violet', 'violet', 'violet:125'},
  {'White', 'white', 'white:125'},
  {'Yellow', 'yellow', 'yellow:125'},
}

for _, def in ipairs(colored_defs) do
  local name, color, hex = def[1], def[2], def[3]

  -- shared groups/sounds/nodeboxes
  local groups = {choppy=2, oddly_breakable_by_hand=2, furniture=1}
  local snds   = moditems.WOOD_SOUNDS

  -- Counter (Vertical Drawers)
  minetest.register_node("ma_pops_furniture:counter_"..color, {
    description = name.." Counter (Vertical Drawers)",
    tiles = {
      "default_coral_skeleton.png^[colorize:"..hex,
      "mp_enc_bottom.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_right.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_left.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_back.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_front.png",
    },
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    sounds = snds,
    groups = groups,
    node_box = {
      type = "fixed",
      fixed = {
        {-0.5,-0.4375,-0.375, 0.5, 0.375, 0.5},
        {-0.4375,-0.375,-0.4375,-0.0625,0.3125,-0.375},
        {0.0625,-0.375,-0.4375, 0.4375,0.3125,-0.375},
        {-0.5,0.375,-0.5, 0.5,0.5,0.5},
        {-0.1875,-0.0625,-0.5,-0.125,0,-0.4375},
        {0.125,-0.0625,-0.5, 0.1875,0,-0.4375},
        {-0.5,-0.5,-0.3125, 0.5,-0.4375,0.5},
      }
    },
    on_construct = function(pos) setup_storage(pos, 6, 6) end,
    can_dig     = can_dig_empty_storage,
    on_rightclick = on_rightclick_storage(true),
    on_punch      = on_punch_recolor(),
  })

  -- Counter (Plain)
  minetest.register_node("ma_pops_furniture:counter2_"..color, {
    description = name.." Counter",
    tiles = {
      "default_coral_skeleton.png^[colorize:"..hex,
      "mp_enc_bottom.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_right.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_left.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_back.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_back.png",
    },
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    sounds = snds,
    groups = groups,
    node_box = {
      type = "fixed",
      fixed = {
        {-0.5,-0.4375,-0.375, 0.5,0.375,0.5},
        {-0.5,0.375,-0.5, 0.5,0.5,0.5},
        {-0.5,-0.5,-0.3125, 0.5,-0.4375,0.5},
      }
    },
    on_rightclick = on_rightclick_storage(true),
    on_punch      = on_punch_recolor(),
  })

  -- Counter (Horizontal Drawers)
  minetest.register_node("ma_pops_furniture:counter3_"..color, {
    description = name.." Counter (Horizontal Drawers)",
    tiles = {
      "default_coral_skeleton.png^[colorize:"..hex,
      "mp_enc_bottom.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_right.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_left.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_back.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_front2.png",
    },
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    sounds = snds,
    groups = groups,
    node_box = {
      type = "fixed",
      fixed = {
        {-0.5,-0.4375,-0.375, 0.5,0.375,0.5},
        {-0.5,0.375,-0.5, 0.5,0.5,0.5},
        {-0.5,-0.5,-0.3125, 0.5,-0.4375,0.5},
        {-0.4375,0,-0.4375, 0.4375,0.3125,-0.375},
        {-0.4375,-0.375,-0.4375, 0.4375,-0.0625,-0.375},
        {-0.1875,0.125,-0.5, 0.1875,0.1875,-0.4375},
        {-0.1875,-0.25,-0.5, 0.1875,-0.1875,-0.4375},
      }
    },
    on_construct = function(pos) setup_storage(pos, 6, 6) end,
    can_dig     = can_dig_empty_storage,
    on_rightclick = on_rightclick_storage(true),
    on_punch      = on_punch_recolor(),
  })

  -- Counter (Corner)
  minetest.register_node("ma_pops_furniture:counter1_"..color, {
    description = name.." Counter (Corner)",
    tiles = {
      "default_coral_skeleton.png^[colorize:"..hex,
      "mp_corn_r_bottom.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_back.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_back.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_back.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_back.png",
    },
    drawtype = "nodebox",
    paramtype = "light",
    sounds = snds,
    groups = groups,
    node_box = { type="fixed", fixed={{0.5,0.5,0.5, -0.5,-0.5,-0.5}} },
    on_rightclick = on_rightclick_storage(true),
    on_punch      = on_punch_recolor(),
  })

  -- Counter (Sink)
  minetest.register_node("ma_pops_furniture:sink_"..color, {
    description = name.." Counter (Sink)",
    tiles = {
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_sink_top.png",
      "mp_enc_bottom.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_right.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_left.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_back.png",
      "default_coral_skeleton.png^[colorize:"..hex.."^mp_enc_front.png",
    },
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    sounds = snds,
    groups = groups,
    node_box = {
      type = "fixed",
      fixed = {
        {-0.5,-0.5,-0.3125, 0.5,-0.4375,0.5},
        {-0.5,-0.4375,-0.375, 0.5,0.375,0.5},
        {-0.5,0.375,-0.5, 0.5,0.5,0.5},
        {-0.4375,-0.375,-0.4375, -0.0625,0.3125,-0.375},
        {0.0625,-0.375,-0.4375, 0.4375,0.3125,-0.375},
        {-0.1875,-0.0625,-0.5, -0.125,0,-0.4375},
        {0.125,-0.0625,-0.5, 0.1875,0,-0.4375},
      }
    },
    on_construct = function(pos) setup_storage(pos, 6, 6) end,
    can_dig     = can_dig_empty_storage,
    on_rightclick = on_rightclick_storage(true),
    on_punch      = on_punch_recolor(),
  })
end

-- ------- wood-material counters -------
local wood_defs = {
  {'Wooden', 'wood'},
  {'Acacia', 'acacia_wood'},
  {'Jungle', 'junglewood'},
  {'Pine', 'pine_wood'},
  {'Aspen', 'aspen_wood'},
}

for _, def in ipairs(wood_defs) do
  local name, mat = def[1], def[2]
  local base = "default_"..mat..".png"
  local groups = {choppy=2, oddly_breakable_by_hand=2, furniture=1, flammable=1}
  local snds   = moditems.WOOD_SOUNDS

  minetest.register_node("ma_pops_furniture:counter_"..mat, {
    description = name.." Counter (Vertical Drawers)",
    tiles = {base, "mp_enc_bottom.png", base.."^mp_enc_right.png", base.."^mp_enc_left.png", base.."^mp_enc_back.png", base.."^mp_enc_front.png"},
    drawtype="nodebox", paramtype="light", paramtype2="facedir",
    groups=groups, sounds=snds,
    node_box = { type="fixed", fixed={
      {-0.5,-0.4375,-0.375,0.5,0.375,0.5},
      {-0.4375,-0.375,-0.4375,-0.0625,0.3125,-0.375},
      {0.0625,-0.375,-0.4375,0.4375,0.3125,-0.375},
      {-0.5,0.375,-0.5,0.5,0.5,0.5},
      {-0.1875,-0.0625,-0.5,-0.125,0,-0.4375},
      {0.125,-0.0625,-0.5,0.1875,0,-0.4375},
      {-0.5,-0.5,-0.3125,0.5,-0.4375,0.5},
    }},
    on_construct = function(pos) setup_storage(pos, 6, 6) end,
    can_dig     = can_dig_empty_storage,
    on_rightclick = on_rightclick_storage(false),
  })

  minetest.register_node("ma_pops_furniture:counter2_"..mat, {
    description = name.." Counter",
    tiles = {base,"mp_enc_bottom.png",base.."^mp_enc_right.png",base.."^mp_enc_left.png",base.."^mp_enc_back.png",base.."^mp_enc_back.png"},
    drawtype="nodebox", paramtype="light", paramtype2="facedir",
    groups=groups, sounds=snds,
    node_box = { type="fixed", fixed={
      {-0.5,-0.4375,-0.375,0.5,0.375,0.5},
      {-0.5,0.375,-0.5,0.5,0.5,0.5},
      {-0.5,-0.5,-0.3125,0.5,-0.4375,0.5},
    }},
    on_rightclick = on_rightclick_storage(false),
  })

  minetest.register_node("ma_pops_furniture:counter3_"..mat, {
    description = name.." Counter (Horizontal Drawers)",
    tiles = {base,"mp_enc_bottom.png",base.."^mp_enc_right.png",base.."^mp_enc_left.png",base.."^mp_enc_back.png",base.."^mp_enc_front2.png"},
    drawtype="nodebox", paramtype="light", paramtype2="facedir",
    groups=groups, sounds=snds,
    node_box = { type="fixed", fixed={
      {-0.5,-0.4375,-0.375,0.5,0.375,0.5},
      {-0.5,0.375,-0.5,0.5,0.5,0.5},
      {-0.5,-0.5,-0.3125,0.5,-0.4375,0.5},
      {-0.4375,0,-0.4375,0.4375,0.3125,-0.375},
      {-0.4375,-0.375,-0.4375,0.4375,-0.0625,-0.375},
      {-0.1875,0.125,-0.5,0.1875,0.1875,-0.4375},
      {-0.1875,-0.25,-0.5,0.1875,-0.1875,-0.4375},
    }},
    on_construct = function(pos) setup_storage(pos, 6, 6) end,
    can_dig     = can_dig_empty_storage,
    on_rightclick = on_rightclick_storage(false),
  })

  minetest.register_node("ma_pops_furniture:counter1_"..mat, {
    description = name.." Counter (Corner)",
    tiles = {base,"mp_corn_r_bottom.png",base.."^mp_enc_back.png",base.."^mp_enc_back.png",base.."^mp_enc_back.png",base.."^mp_enc_back.png"},
    drawtype="nodebox", paramtype="light",
    groups=groups, sounds=snds,
    node_box = { type="fixed", fixed={{0.5,0.5,0.5,-0.5,-0.5,-0.5}} },
    on_rightclick = on_rightclick_storage(false),
  })

  minetest.register_node("ma_pops_furniture:sink_"..mat, {
    description = name.." Counter (Sink)",
    tiles = {base.."^mp_sink_top.png","mp_enc_bottom.png",base.."^mp_enc_right.png",base.."^mp_enc_left.png",base.."^mp_enc_back.png",base.."^mp_enc_front.png"},
    drawtype="nodebox", paramtype="light", paramtype2="facedir",
    groups=groups, sounds=snds,
    node_box = { type="fixed", fixed={
      {-0.5,-0.5,-0.3125,0.5,-0.4375,0.5},
      {-0.5,-0.4375,-0.375,0.5,0.375,0.5},
      {-0.5,0.375,-0.5,0.5,0.5,0.5},
      {-0.4375,-0.375,-0.4375,-0.0625,0.3125,-0.375},
      {0.0625,-0.375,-0.4375,0.4375,0.3125,-0.375},
      {-0.1875,-0.0625,-0.5,-0.125,0,-0.4375},
      {0.125,-0.0625,-0.5,0.1875,0,-0.4375},
    }},
    on_construct = function(pos) setup_storage(pos, 6, 6) end,
    can_dig     = can_dig_empty_storage,
    on_rightclick = on_rightclick_storage(false),
  })
end

-- ------- generic nodes (unchanged geometry, improved storage/handlers) -------

minetest.register_node("ma_pops_furniture:upcabinet_corner", {
  description = "Upper Cabinets (corner)",
  tiles = {"mp_grif_sides.png","mp_grif_sides.png","mp_grif_sides.png","mp_grif_sides.png","mp_grif_sides.png","mp_grif_sides.png"},
  drawtype="nodebox", paramtype="light", paramtype2="facedir",
  groups={choppy=2, oddly_breakable_by_hand=2, furniture=1},
  node_box = { type="fixed", fixed={{-0.5,-0.3125,-0.5, 0.5,0.5,0.5}} },
  on_construct = function(pos) setup_storage(pos, 3, 3) end,
  can_dig     = can_dig_empty_storage,
  on_rightclick = on_rightclick_storage(false),
})

minetest.register_node("ma_pops_furniture:dw", {
  description= "Dishwasher",
  tiles = {"mp_dw_top.png","mp_dw_bottom.png","mp_dw_left.png","mp_dw_right.png","mp_dw_back.png","mp_dw_front.png"},
  drawtype="nodebox", paramtype="light", paramtype2="facedir",
  groups={choppy=2, oddly_breakable_by_hand=2, furniture=1},
  node_box = { type="fixed", fixed={
    {-0.4375,-0.5,-0.4375, 0.4375,-0.4375,0.4375},
    {-0.5,-0.4375,-0.4375, 0.5,0.5,0.5},
    {-0.5,0.3125,-0.5, 0.5,0.5,-0.4375},
    {-0.4375,-0.4375,-0.5, 0.4375,0.25,0.5},
  }},
  on_rightclick = on_rightclick_storage(false),
})

minetest.register_node("ma_pops_furniture:oven_overhead", {
  description= "Oven Overhead",
  tiles = {"mp_camp_top.png","mp_camp_bottom.png","mp_camp_left.png","mp_camp_right.png","mp_camp_back.png","mp_camp_front.png"},
  drawtype="nodebox", paramtype="light", paramtype2="facedir",
  groups={choppy=2, oddly_breakable_by_hand=2, furniture=1},
  node_box = { type="fixed", fixed={
    {-0.4375,0.4375,-0.4375, 0.4375,0.5,0.4375},
    {-0.5,0.25,-0.5, 0.5,0.4375,0.5},
  }},
})

minetest.register_node("ma_pops_furniture:microwave", {
  description = "Microwave",
  tiles = {"mp_mw_top.png","mp_mw_bottom.png","mp_mw_right.png","mp_mw_left.png","mp_mw_back.png","mp_mw_front.png"},
  drawtype="nodebox", paramtype="light", paramtype2="facedir",
  groups={choppy=2, oddly_breakable_by_hand=2, furniture=1},
  node_box = { type="fixed", fixed={
    {-0.4375,-0.4375,-0.3125, 0.4375,0.0625,0.3125},
    {-0.375,-0.5,-0.25, 0.375,-0.4375,0.25},
  }},
})

minetest.register_node("ma_pops_furniture:coffee_maker", {
  description = "Coffee Maker",
  tiles = {"mp_cof_top.png","mp_cof_bottom.png","mp_cof_right.png","mp_cof_left.png","mp_cof_back.png","mp_cof_front.png"},
  drawtype="nodebox", paramtype="light", paramtype2="facedir",
  groups={choppy=2, oddly_breakable_by_hand=2, furniture=1},
  node_box = { type="fixed", fixed={
    {-0.4375,-0.5,-0.0625, 0,-0.4375,0.4375},
    {-0.4375,-0.5,0.3125, 0,0.1875,0.4375},
    {-0.4375,-0.0625,0, 0,0.25,0.4375},
    {-0.375,-0.4375,0, -0.0625,-0.125,0.25},
    {-0.25,-0.375,-0.125, -0.1875,-0.1875,0.0625},
  }},
})

minetest.register_node("ma_pops_furniture:coffee_cup", {
  description = "Coffee Cup",
  tiles = {"mp_cof_top.png","mp_cof_top.png","mp_cof_right.png","mp_cof_left.png","mp_cof_back.png","mp_cof_front.png"},
  drawtype="nodebox", paramtype="light", paramtype2="facedir",
  groups={choppy=2, oddly_breakable_by_hand=2, furniture=1},
  node_box = { type="fixed", fixed={
    {-0.375,-0.5,0, -0.0625,-0.1875,0.3125},
    {-0.25,-0.3125,-0.125, -0.1875,-0.25,0},
    {-0.25,-0.4375,-0.125, -0.1875,-0.375,0},
    {-0.25,-0.375,-0.125, -0.1875,-0.3125,-0.0625},
  }},
})

minetest.register_node("ma_pops_furniture:toaster", {
  description = "Toaster",
  tiles = {"mp_toas_top.png","mp_toas_bottom.png","mp_toas_right.png","mp_toas_left.png","mp_toas_back.png","mp_toas_front.png"},
  drawtype="nodebox", paramtype="light", paramtype2="facedir",
  groups={choppy=2, oddly_breakable_by_hand=2, furniture=1},
  node_box = { type="fixed", fixed={
    {-0.375,-0.5,0, 0.375,-0.0625,0.3125},
    {-0.4375,-0.1875,0.0625, -0.375,-0.125,0.25},
  }},
})

minetest.register_node("ma_pops_furniture:faucet_kitchen", {
  description = "Kitchen Faucet",
  tiles = {"mp_grif_top.png","mp_grif_sides.png","mp_grif_sides.png","mp_grif_sides.png","mp_grif_sides.png","mp_grif_sides.png"},
  drawtype="nodebox", paramtype="light", paramtype2="facedir",
  groups={choppy=2, oddly_breakable_by_hand=2, furniture=1},
  node_box = { type="fixed", fixed={
    {-0.0625,-0.5,0.375, 0.0625,-0.1875,0.4375},
    {-0.0625,-0.1875,0.0625, 0.0625,-0.125,0.4375},
    {-0.0625,-0.25,0.0625, 0.0625,-0.1875,0.125},
    {0.125,-0.5,0.3125, 0.25,-0.375,0.4375},
    {-0.25,-0.5,0.3125, -0.125,-0.375,0.4375},
  }},
})

minetest.register_node("ma_pops_furniture:tile_kitchen", {
  description = "White Kitchen Tile",
  tiles = {"mp_kitchen_tile.png"},
  paramtype="light", paramtype2="facedir",
  groups={cracky=2, oddly_breakable_by_hand=2},
})

minetest.register_node("ma_pops_furniture:tile_floor_kitchen", {
  description = "Checker Kitchen Floor Tile",
  tiles = {"mp_kitchen_floor_tile.png"},
  paramtype="light", paramtype2="facedir",
  groups={cracky=2, oddly_breakable_by_hand=2},
})

-- Trash Can with simple “trashlist” inventory and Empty button (unchanged behavior)
minetest.register_node("ma_pops_furniture:trash_can", {
  description = "Trash Can",
  drawtype = "nodebox",
  tiles = {"default_steel_block.png"},
  groups = {cracky=2, oddly_breakable_by_hand=2, furniture=1},
  paramtype = "light",
  paramtype2 = "facedir",
  sounds = moditems.WOOD_SOUNDS,
  node_box = {
    type="fixed",
    fixed = {
      {-0.375,-0.5,-0.375, 0.375,0.375,0.375},
      {-0.4375,0.375,-0.4375, 0.4375,0.4375,0.4375},
      {-0.125,0.4375,-0.3125, 0.125,0.5,0.3125},
    }
  },
  on_construct = function(pos)
    local meta = minetest.get_meta(pos)
    meta:set_string("formspec",
      "formspec_version[4]size[8,9]"..
      "button[0,0;2,1;empty;Empty Trash]"..
      "list[context;trashlist;3,1;2,3;]"..
      "list[current_player;main;0,5;8,4;]"
    )
    meta:set_string("infotext","Trash Can")
    local inv = meta:get_inventory()
    inv:set_size("main", 8*4)
    inv:set_size("trashlist", 2*3)
  end,
  can_dig = function(pos, player)
    local inv = minetest.get_meta(pos):get_inventory()
    return inv:is_empty("trashlist") and inv:is_empty("main")
  end,
  on_receive_fields = function(pos, formname, fields, sender)
    if fields.empty then
      local meta = minetest.get_meta(pos)
      local inv  = meta:get_inventory()
      inv:set_list("trashlist", {})
      minetest.sound_play("trash", {to_player=sender:get_player_name(), gain=1.0})
      minetest.log("action", ("%s empties trash can at %s"):format(sender:get_player_name(), minetest.pos_to_string(pos)))
    end
  end,
})
