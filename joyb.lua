-- jOyBoX / Venext console — cross-game friendly version
-- Works in Minetest Game and Mineclonia

local console_empty   = "ma_pops_furniture:venext_console"
local console_loaded  = "ma_pops_furniture:jOyBoX_cart"
local cart_item       = "ma_pops_furniture:cartridge_item"

local function is_creative(name)
  return minetest.is_creative_enabled and minetest.is_creative_enabled(name)
end

local function can_interact(pos, player)
  return player and (not minetest.is_protected(pos, player:get_player_name()))
end

local function give_or_drop(player, stack, pos)
  if not player or stack:is_empty() then return end
  local inv = player:get_inventory()
  if inv and inv:room_for_item("main", stack) then
    inv:add_item("main", stack)
  else
    minetest.add_item(pos, stack)
  end
end

-- ============ Cartridge as an item ============
minetest.register_craftitem(cart_item, {
  description = "Game Cartridge",
  inventory_image = "mp_cartridge_item.png", -- add this texture (or reuse mp_cartridge_front.png)
  stack_max = 1,
})

-- Backward compatibility: if any world still has the old “cartridge” node, make it drop the new item.
minetest.register_alias_force("ma_pops_furniture:cartridge", "air")
minetest.register_lbm({
  name = "ma_pops_furniture:cartridge_node_cleanup",
  nodenames = {"ma_pops_furniture:cartridge"},
  action = function(pos, node)
    -- turn legacy node into an item drop
    minetest.remove_node(pos)
    minetest.add_item(pos, ItemStack(cart_item))
  end
})

-- ============ Shared nodebox ============
local console_nodebox = {
  type = "fixed",
  fixed = {
    {-0.4375, -0.5,   -0.4375,  0.4375, -0.1875,  0.4375},
    {-0.375,  -0.1875,-0.375,   0.375,  -0.0625,  0.375},
    { 0.3125, -0.4375,-0.5,     0.375,  -0.375,  -0.4375},
    { 0.1875, -0.4375,-0.5,     0.25,   -0.375,  -0.4375},
  }
}

local console_loaded_nodebox = {
  type = "fixed",
  fixed = {
    {-0.4375, -0.5,   -0.4375,  0.4375, -0.1875,  0.4375},
    {-0.375,  -0.1875,-0.375,   0.375,  -0.0625,  0.375},
    { 0.3125, -0.4375,-0.5,     0.375,  -0.375,  -0.4375},
    { 0.1875, -0.4375,-0.5,     0.25,   -0.375,  -0.4375},
    -- cart “tongue” in slot
    { 0.25,    0.10,  -0.07,   -0.25,   -0.4375,  0.14},
  }
}

-- ============ helpers ============
local function setup_inv(pos)
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()
  inv:set_size("cart", 1)
  -- Simple formspec that shows the cart slot
  meta:set_string("formspec",
    "formspec_version[4]size[8,6]"..
    (moditems.BOXART or "") ..
    "label[3.2,0.4;Cartridge]"..
    "list[current_name;cart;3.5,0.9;1,1;]"..
    "list[current_player;main;0,2.7;8,4;]"
  )
end

local function insert_cart(pos, node, player, itemstack)
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()
  if inv:get_stack("cart",1):is_empty() and itemstack:get_name() == cart_item then
    local put = itemstack:take_item(1)
    inv:set_stack("cart",1, put)
    if not is_creative(player:get_player_name()) then
      player:set_wielded_item(itemstack)
    end
    -- swap to loaded variant (keep facedir)
    minetest.swap_node(pos, {name = console_loaded, param2 = node.param2})
    minetest.sound_play("xdecor_insert", {pos=pos, gain=0.3}, true) -- optional; replace with your sound
    return true
  end
  return false
end

local function eject_cart(pos, node, player)
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()
  local st   = inv:get_stack("cart",1)
  if st:is_empty() then return false end
  inv:set_stack("cart",1, ItemStack(nil))
  give_or_drop(player, st, pos)
  minetest.sound_play("xdecor_eject", {pos=pos, gain=0.3}, true) -- optional
  -- swap back to empty variant (keep facedir)
  minetest.swap_node(pos, {name = console_empty, param2 = node.param2})
  return true
end

local function drop_cart_on_dig(pos, oldnode)
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()
  local st   = inv:get_stack("cart",1)
  if not st:is_empty() then
    minetest.add_item(pos, st)
  end
end

-- ============ Console (empty) ============
minetest.register_node(console_empty, {
  description = "jOyBoX",
  tiles = {
    "mp_venext_top1.png",
    "mp_venext_bottom.png",
    "mp_venext_side.png",
    "mp_venext_side2.png",
    "mp_venext_back.png",
    "mp_venext_front.png",
  },
  groups = {snappy=1, bendy=2, cracky=1},
  sounds = moditems.WOOD_SOUNDS,
  drawtype = "nodebox",
  paramtype = "light",
  paramtype2 = "facedir",
  node_box = console_nodebox,

  on_construct = setup_inv,

  can_dig = function(pos, player)
    local meta = minetest.get_meta(pos)
    local inv  = meta:get_inventory()
    return inv:get_stack("cart",1):is_empty()
  end,

  after_dig_node = function(pos, oldnode, oldmeta, digger)
    -- just in case; can_dig should have prevented, but keep safe
    drop_cart_on_dig(pos, oldnode)
  end,

  on_rightclick = function(pos, node, player, itemstack, pointed)
    if not can_interact(pos, player) then return itemstack end
    -- insert a cart if holding one
    insert_cart(pos, node, player, itemstack)
    return itemstack
  end,
})

-- ============ Console (with cartridge) ============
minetest.register_node(console_loaded, {
  description = "jOyBoX (with cartridge)",
  tiles = {
    "mp_venext_top.png",
    "mp_venext_bottom.png",
    "mp_venext_side.png",
    "mp_venext_side2.png",
    "mp_venext_back.png",
    "mp_venext_front.png",
  },
  groups = {snappy=1, bendy=2, cracky=1, not_in_creative_inventory=1},
  sounds = moditems.WOOD_SOUNDS,
  drawtype = "nodebox",
  paramtype = "light",
  paramtype2 = "facedir",
  drop = console_empty, -- digging always yields the base block (cart drops separately)
  node_box = console_loaded_nodebox,

  on_construct = setup_inv,

  after_dig_node = function(pos, oldnode, oldmeta, digger)
    drop_cart_on_dig(pos, oldnode)
  end,

  on_rightclick = function(pos, node, player, itemstack, pointed)
    if not can_interact(pos, player) then return itemstack end
    local ctrl = player:get_player_control() or {}
    if ctrl and ctrl.sneak then
      -- Sneak + right-click = eject
      eject_cart(pos, node, player)
    else
      -- Normal right-click while already loaded: optional “power on” behavior hook
      -- (Place your UI/game-launch code here if you add a formspec-based mini game.)
      minetest.sound_play("default_cool_lava", {pos=pos, gain=0.1}, true) -- placeholder; remove if undesired
    end
    return itemstack
  end,
})
