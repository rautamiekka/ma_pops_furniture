-- grill_full.lua — MTG + Mineclonia compatible grills with cooking, visuals, particles & sound

local MODNAME = minetest.get_current_modname()
local MODPATH = minetest.get_modpath(MODNAME)

-- ========= optional compat glue (uses your compat.lua if present) =========
local C
do
  local ok, ret = pcall(dofile, MODPATH .. "/compat.lua")
  if ok and type(ret) == "table" then C = ret end
end
C = C or {}
C.IS_MCL = C.IS_MCL ~= nil and C.IS_MCL or minetest.get_modpath("mcl_core") ~= nil

local function tex_stone()
  if C.tex_stone then return C.tex_stone() end
  return C.IS_MCL and "mcl_core_stone.png" or "default_stone.png"
end
local function tex_coalblock()
  if C.tex_coalblock then return C.tex_coalblock() end
  return C.IS_MCL and "mcl_core_coalblock.png" or "default_coal_block.png"
end

C.sounds = C.sounds or {}
C.sounds.stone = C.sounds.stone or function()
  if default and default.node_sound_stone_defaults then
    return default.node_sound_stone_defaults()
  elseif mcl_sounds and mcl_sounds.node_sound_stone_defaults then
    return mcl_sounds.node_sound_stone_defaults()
  end
  return {}
end

C.stone_groups = C.stone_groups or function(extra)
  local g = { cracky = 3 }
  for k,v in pairs(extra or {}) do g[k] = v end
  return g
end

-- ========= node ids =========
local NAME_BASE          = "ma_pops_furniture:grill"
local NAME_BASE_ON       = "ma_pops_furniture:grill_on"
local NAME_LIDDED_OFF    = "ma_pops_furniture:grill2"
local NAME_LIDDED_ON     = "ma_pops_furniture:grill2_on"
local NAME_LIDDED_ON_NL  = "ma_pops_furniture:grill2_on_nolight"
local NAME_LID_CLOSED    = "ma_pops_furniture:grill2_top"
local NAME_LID_OPEN      = "ma_pops_furniture:grill2_top_open"

-- ========= helpers =========
local function above(p) return {x=p.x, y=p.y+1, z=p.z} end
local function below(p) return {x=p.x, y=p.y-1, z=p.z} end
local function poshash(p) return minetest.hash_node_position(p) end

-- ========= nodeboxes =========
local grill_nodebox = {
  type = "fixed",
  fixed = {
    {-0.450, -0.5,  -0.450, -0.350, -0.3,  -0.350},
    { 0.450, -0.5,  -0.450,  0.350, -0.3,  -0.350},
    {-0.450, -0.5,   0.450, -0.350, -0.3,   0.350},
    { 0.450, -0.5,   0.450,  0.350, -0.3,   0.350},

    {-0.4,  -0.3,   -0.4,   -0.3,    0.0,  -0.3},
    { 0.4,  -0.3,   -0.4,    0.3,    0.0,  -0.3},
    {-0.4,  -0.3,    0.4,   -0.3,    0.0,   0.3},
    { 0.4,  -0.3,    0.4,    0.3,    0.0,   0.3},

    {-0.4,   0.0,   -0.4,    0.4,    0.2,   0.4},
    {-0.5,   0.190, -0.5,    0.5,    0.4,   0.5},

    {-0.4375,0.4,    0.5,   -0.5,    0.5,  -0.5},
    { 0.4375,0.4,    0.5,    0.5,    0.5,  -0.5},
    {-0.5,   0.4,    0.4375, 0.5,    0.5,   0.5},
    {-0.5,   0.4,   -0.4375, 0.5,    0.5,  -0.5},
  }
}

local top_closed_nodebox = {
  type = "fixed",
  fixed = {
    {-0.4375,-0.375,-0.4375, 0.4375,-0.3125, 0.4375},
    {-0.5,   -0.5,  -0.4375, -0.4375,-0.375, 0.5},
    { 0.4375,-0.5,  -0.5,     0.5,  -0.375, 0.4375},
    {-0.5,   -0.5,  -0.5,     0.4375,-0.375,-0.4375},
    {-0.4375,-0.5,   0.4375,  0.5,  -0.375, 0.5},
  }
}

local top_open_nodebox = {
  type = "fixed",
  fixed = {
    {-0.5,   -0.4375, 0.3125, -0.4375, 0.5,    0.4375},
    { 0.4375,-0.5,    0.3125,  0.5,    0.4375, 0.4375},
    {-0.4375, 0.4375, 0.3125,  0.5,    0.5,    0.4375},
    {-0.5,   -0.5,    0.3125,  0.4375,-0.4375, 0.4375},
    {-0.4375,-0.4375, 0.4375,  0.4375, 0.4375, 0.5},
  }
}

-- ========= shared tiles =========
local stone = tex_stone()
local coalb = tex_coalblock()
local T_SIDE    = stone.."^mp_grills.png"
local T_TOP_OFF = coalb.."^mp_grillt.png"
local T_TOP_ON  = coalb.."^mp_grillton.png"

-- ========= lid helpers =========
local function remove_lid_if_any(pos)
  local ptop = above(pos)
  local n = minetest.get_node(ptop).name
  if n == NAME_LID_OPEN or n == NAME_LID_CLOSED then
    minetest.remove_node(ptop)
  end
end

local function place_lid_or_abort(pos, param2)
  local ptop = above(pos)
  local atop = minetest.get_node(ptop)
  local def = minetest.registered_nodes[atop.name]
  if def and def.buildable_to then
    minetest.set_node(ptop, {name = NAME_LID_CLOSED, param2 = param2})
    return true
  end
  minetest.remove_node(pos)
  return false
end

local function rotate_with_lid(pos, node, user, mode, new_param2)
  local ptop = above(pos)
  local lid = minetest.get_node(ptop)
  if lid and (lid.name == NAME_LID_CLOSED or lid.name == NAME_LID_OPEN) then
    minetest.swap_node(ptop, {name = lid.name, param2 = new_param2})
  end
end

local function lid_is_closed(pos)
  return minetest.get_node(above(pos)).name == NAME_LID_CLOSED
end

-- ========= registration: base & lidded grills =========
minetest.register_node(NAME_BASE, {
  description = "Grill",
  drawtype = "nodebox",
  tiles = { T_TOP_OFF, stone, T_SIDE, T_SIDE, T_SIDE, T_SIDE },
  drop = NAME_BASE,
  paramtype = "light",
  paramtype2 = "facedir",
  sounds = C.sounds.stone(),
  groups = C.stone_groups({choppy=2, oddly_breakable_by_hand=2}),
  node_box = grill_nodebox,

  on_rightclick = function(pos, node, player, itemstack, pointed)
    minetest.swap_node(pos, {name = NAME_BASE_ON, param2 = node.param2})
  end,
})

minetest.register_node(NAME_BASE_ON, {
  description = "Grill (on)",
  drawtype = "nodebox",
  tiles = { T_TOP_ON, stone, T_SIDE, T_SIDE, T_SIDE, T_SIDE },
  drop = NAME_BASE,
  paramtype = "light",
  paramtype2 = "facedir",
  light_source = 10,
  sounds = C.sounds.stone(),
  groups = C.stone_groups({choppy=2, oddly_breakable_by_hand=2, not_in_creative_inventory=1}),
  node_box = grill_nodebox,

  on_rightclick = function(pos, node, player, itemstack, pointed)
    minetest.swap_node(pos, {name = NAME_BASE, param2 = node.param2})
  end,
})

minetest.register_node(NAME_LIDDED_OFF, {
  description = "Lidded Grill",
  drawtype = "nodebox",
  tiles = { stone.."^mp_grillt.png", stone, T_SIDE, T_SIDE, T_SIDE, T_SIDE },
  drop = NAME_LIDDED_OFF,
  paramtype = "light",
  paramtype2 = "facedir",
  sounds = C.sounds.stone(),
  groups = C.stone_groups({choppy=2, oddly_breakable_by_hand=2}),
  node_box = grill_nodebox,

  after_place_node = function(pos, placer, itemstack, pointed_thing)
    local node = minetest.get_node(pos)
    place_lid_or_abort(pos, node.param2)
  end,

  on_destruct = function(pos) remove_lid_if_any(pos) end,

  on_rotate = function(pos, node, user, mode, new_param2)
    if new_param2 then rotate_with_lid(pos, node, user, mode, new_param2) end
    return false
  end,

  on_rightclick = function(pos, node, player, itemstack, pointed)
    local ptop = above(pos)
    local lid = minetest.get_node(ptop).name
    if lid == NAME_LID_OPEN then
      minetest.swap_node(pos, {name = NAME_LIDDED_ON, param2 = node.param2})
    elseif lid == NAME_LID_CLOSED then
      minetest.swap_node(pos, {name = NAME_LIDDED_ON_NL, param2 = node.param2})
    end
  end,
})

minetest.register_node(NAME_LIDDED_ON, {
  description = "Lidded Grill (on)",
  drawtype = "nodebox",
  tiles = { stone.."^mp_grillton.png", stone, T_SIDE, T_SIDE, T_SIDE, T_SIDE },
  drop = NAME_LIDDED_OFF,
  paramtype = "light",
  paramtype2 = "facedir",
  light_source = 10,
  sounds = C.sounds.stone(),
  groups = C.stone_groups({choppy=2, oddly_breakable_by_hand=2, not_in_creative_inventory=1}),
  node_box = grill_nodebox,

  on_rightclick = function(pos, node, player, itemstack, pointed)
    minetest.swap_node(pos, {name = NAME_LIDDED_OFF, param2 = node.param2})
  end,

  on_destruct = function(pos) remove_lid_if_any(pos) end,
  on_rotate  = function(pos, node, user, mode, new_param2)
    if new_param2 then rotate_with_lid(pos, node, user, mode, new_param2) end
    return false
  end,
})

minetest.register_node(NAME_LIDDED_ON_NL, {
  description = "Lidded Grill (on, lid closed)",
  drawtype = "nodebox",
  tiles = { stone.."^mp_grillton.png", stone, T_SIDE, T_SIDE, T_SIDE, T_SIDE },
  drop = NAME_LIDDED_OFF,
  paramtype = "light",
  paramtype2 = "facedir",
  sounds = C.sounds.stone(),
  groups = C.stone_groups({choppy=2, oddly_breakable_by_hand=2, not_in_creative_inventory=1}),
  node_box = grill_nodebox,

  on_rightclick = function(pos, node, player, itemstack, pointed)
    minetest.swap_node(pos, {name = NAME_LIDDED_OFF, param2 = node.param2})
  end,

  on_destruct = function(pos) remove_lid_if_any(pos) end,
  on_rotate  = function(pos, node, user, mode, new_param2)
    if new_param2 then rotate_with_lid(pos, node, user, mode, new_param2) end
    return false
  end,
})

minetest.register_node(NAME_LID_CLOSED, {
  description = "Grill Lid",
  drawtype = "nodebox",
  tiles = { stone },
  drop = "",
  paramtype = "light",
  paramtype2 = "facedir",
  sounds = C.sounds.stone(),
  groups = {not_in_creative_inventory = 1},
  node_box = top_closed_nodebox,

  on_rightclick = function(pos, node, player, itemstack, pointed)
    local basepos = below(pos)
    local base = minetest.get_node(basepos)
    if base.name == NAME_LIDDED_ON_NL then
      minetest.swap_node(basepos, {name = NAME_LIDDED_ON, param2 = base.param2})
    end
    minetest.swap_node(pos, {name = NAME_LID_OPEN, param2 = node.param2})
  end,
})

minetest.register_node(NAME_LID_OPEN, {
  description = "Grill Lid (open)",
  drawtype = "nodebox",
  tiles = { stone },
  drop = "",
  paramtype = "light",
  paramtype2 = "facedir",
  sounds = C.sounds.stone(),
  groups = {not_in_creative_inventory = 1},
  node_box = top_open_nodebox,

  on_rightclick = function(pos, node, player, itemstack, pointed)
    local basepos = below(pos)
    local base = minetest.get_node(basepos)
    if base.name == NAME_LIDDED_ON then
      minetest.swap_node(basepos, {name = NAME_LIDDED_ON_NL, param2 = base.param2})
    end
    minetest.swap_node(pos, {name = NAME_LID_CLOSED, param2 = node.param2})
  end,
})

-- ========= cooking engine (1 slot) =========
local DEFAULT_COOK_TIME = 8
local MCL_COOK_MAP = {
  ["mcl_mobitems:beef_raw"]      = "mcl_mobitems:beef_cooked",
  ["mcl_mobitems:porkchop_raw"]  = "mcl_mobitems:porkchop_cooked",
  ["mcl_mobitems:mutton_raw"]    = "mcl_mobitems:mutton_cooked",
  ["mcl_mobitems:chicken"]       = "mcl_mobitems:cooked_chicken",
  ["mcl_mobitems:rabbit_raw"]    = "mcl_mobitems:rabbit_cooked",
  ["mcl_mobitems:fish_raw"]      = "mcl_mobitems:fish_cooked",
  ["mcl_mobitems:salmon_raw"]    = "mcl_mobitems:salmon_cooked",
  ["mcl_farming:potato_item"]    = "mcl_farming:baked_potato",
}

local function get_cook_result(itemstack)
  if itemstack:is_empty() then return nil end
  local res = minetest.get_craft_result({ method = "cooking", width = 1, items = { itemstack }})
  if res and res.item and not res.item:is_empty() then
    local t = (res.time and res.time > 0) and res.time or DEFAULT_COOK_TIME
    return res.item, t
  end
  local cooked = MCL_COOK_MAP[itemstack:get_name()]
  if cooked then return ItemStack(cooked), DEFAULT_COOK_TIME end
  return nil
end

local function is_hot_node(name)
  return (name == NAME_BASE_ON) or (name == NAME_LIDDED_ON) or (name == NAME_LIDDED_ON_NL)
end

local function grill_formspec()
  return table.concat({
    "formspec_version[4]",
    "size[8,6]",
    "label[1,0.4;Food]",
    "list[current_name;food;1,0.9;1,1;]",
    "image[3,0.9;1,1;gui_furnace_arrow_bg.png^[transformR270]",
    "label[5,0.4;Done]",
    "list[current_name;done;5,0.9;1,1;]",
    "list[current_player;main;0,2.7;8,4;]",
  })
end

local function setup_inventory(pos)
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()
  inv:set_size("food", 1)
  inv:set_size("done", 1)
  meta:set_string("formspec", grill_formspec())
  if meta:get_int("cook_time") == 0 then meta:set_int("cook_time", 0) end
  if meta:get_int("cook_tot")  == 0 then meta:set_int("cook_tot", 0) end
  if meta:get_int("sfx_tick")  == 0 then meta:set_int("sfx_tick", 0) end
end

-- ========= visuals: sprite entity =========
local function get_item_image(name)
  local def = minetest.registered_items[name]
  return (def and def.inventory_image ~= "" and def.inventory_image) or "unknown_item.png"
end

minetest.register_entity("ma_pops_furniture:grill_food_ent", {
  initial_properties = {
    physical = false, pointable = false, collide_with_objects = false,
    visual = "sprite", visual_size = {x=0.5, y=0.5},
    textures = {"blank.png"}, spritediv = {x=1,y=1}, static_save = true, glow = 0,
  },
  _item = "", _progress = 0, _basepos = nil,
  on_activate = function(self, staticdata)
    local t = (staticdata and staticdata ~= "" and minetest.deserialize(staticdata)) or {}
    self._item = t.item or ""; self._progress = t.p or 0; self._basepos = t.bp
    if self._item ~= "" then self:_apply_texture() end
  end,
  get_staticdata = function(self)
    return minetest.serialize({item=self._item, p=self._progress, bp=self._basepos})
  end,
  _apply_texture = function(self)
    local img = get_item_image(self._item)
    local tint = math.floor((self._progress or 0) * 80)
    local tex = img .. "^[colorize:#5a2e12:" .. tint
    self.object:set_properties({ textures = {tex} })
  end,
  set_item_and_progress = function(self, itemname, progress, basepos, yaw)
    self._item = itemname or self._item
    self._progress = math.max(0, math.min(1, progress or 0))
    self._basepos = basepos or self._basepos
    self:_apply_texture()
    if yaw then self.object:set_yaw(yaw) end
  end,
})

local function ent_offset(pos) return {x=pos.x, y=pos.y + 0.27, z=pos.z} end
local function facedir_yaw(p2) local y={0,math.pi/2,math.pi,math.pi*1.5}; return y[(p2 or 0)%4+1] end
local function find_ent(pos)
  for _,o in ipairs(minetest.get_objects_inside_radius(pos, 0.6)) do
    local e=o:get_luaentity()
    if e and e.name=="ma_pops_furniture:grill_food_ent" then return e end
  end
end
local function ensure_ent(pos, node, name, progress)
  if (node.name == NAME_LIDDED_OFF or node.name == NAME_LIDDED_ON or node.name == NAME_LIDDED_ON_NL) and lid_is_closed(pos) then
    local e=find_ent(pos); if e then e.object:remove() end; return
  end
  local tgt = ent_offset(pos)
  local e = find_ent(pos)
  if not e then
    local obj = minetest.add_entity(tgt, "ma_pops_furniture:grill_food_ent")
    if not obj then return end
    e = obj:get_luaentity()
  else
    e.object:move_to(tgt)
  end
  e:set_item_and_progress(name, progress, pos, facedir_yaw(minetest.get_node(pos).param2))
end
local function remove_ent(pos) local e=find_ent(pos); if e then e.object:remove() end end

-- ========= particles & sounds =========
local function puff_smoke(pos)
  minetest.add_particlespawner({
    amount=4, time=0.2,
    minpos={x=pos.x-0.1,y=pos.y+0.35,z=pos.z-0.1},
    maxpos={x=pos.x+0.1,y=pos.y+0.45,z=pos.z+0.1},
    minvel={x=0,y=0.6,z=0}, maxvel={x=0,y=0.9,z=0},
    minexptime=0.6, maxexptime=1.2, minsize=1.0, maxsize=1.8,
    texture="smoke_puff.png^[opacity:140",
  })
end

local function puff_flame(pos)
  minetest.add_particlespawner({
    amount=2, time=0.1,
    minpos={x=pos.x-0.09,y=pos.y+0.22,z=pos.z-0.09},
    maxpos={x=pos.x+0.09,y=pos.y+0.29,z=pos.z+0.09},
    minvel={x=0,y=0.2,z=0}, maxvel={x=0,y=0.4,z=0},
    minexptime=0.2, maxexptime=0.5, minsize=0.7, maxsize=1.1,
    texture="fire_basic_flame.png^[opacity:120",
    glow=5,
  })
end

local function play_sizzle(pos)
  -- Use a short burst to avoid managing loop handles across save/load
  minetest.sound_play({name="fire_small"}, {pos=pos, gain=0.15, max_hear_distance=10}, true)
end

-- ========= cooking process / inventory rules =========
local function try_insert_food(pos, node, player)
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()
  local wield = player:get_wielded_item()
  if wield:is_empty() then return false end
  if not get_cook_result(wield) then return false end
  if not inv:get_stack("food",1):is_empty() then return false end
  local one = wield:take_item(1)
  inv:set_stack("food",1,one)
  player:set_wielded_item(wield)
  minetest.get_node_timer(pos):start(1.0)
  return true
end

local function on_inv_change_start_timer(pos)
  local t = minetest.get_node_timer(pos)
  if not t:is_started() then t:start(1.0) end
end

local function allow_put(pos, listname, index, stack, player)
  if listname == "food" then
    if get_cook_result(stack) then return 1 end
    return 0
  end
  return 0
end
local function allow_take(pos, listname, index, stack, player) return stack:get_count() end

local function grill_timer(pos, elapsed)
  local node = minetest.get_node(pos)
  local meta = minetest.get_meta(pos)
  local inv  = meta:get_inventory()

  local in_stack  = inv:get_stack("food", 1)
  local out_stack = inv:get_stack("done", 1)

  if not is_hot_node(node.name) then
    meta:set_int("cook_time", 0)
    meta:set_int("cook_tot",  0)
    remove_ent(pos)
    return false
  end

  -- visuals even when idle (lid open)
  if not in_stack:is_empty() and not lid_is_closed(pos) then
    local tot = math.max(1, meta:get_int("cook_tot"))
    local cur = meta:get_int("cook_time")
    ensure_ent(pos, node, in_stack:get_name(), cur / tot)
  end

  -- sound + particles rate-limit
  local sfx_tick = meta:get_int("sfx_tick") + 1
  if sfx_tick >= 5 then -- ~once per 5 timer ticks
    sfx_tick = 0
    if not lid_is_closed(pos) then
      puff_smoke(pos)
      puff_flame(pos)
      play_sizzle(pos)
    end
  end
  meta:set_int("sfx_tick", sfx_tick)

  if in_stack:is_empty() then
    meta:set_int("cook_time", 0)
    meta:set_int("cook_tot",  0)
    return true
  end

  local res_item, need = get_cook_result(in_stack)
  if not res_item then
    return true
  end

  if meta:get_int("cook_tot") == 0 then meta:set_int("cook_tot", need) end
  local tot = meta:get_int("cook_tot")
  local t   = meta:get_int("cook_time") + (elapsed or 1)

  if t >= tot then
    -- move cooked item to output if possible
    if out_stack:is_empty() or (out_stack:get_name() == res_item:get_name() and out_stack:get_free_space() > 0) then
      in_stack:take_item(1); inv:set_stack("food",1,in_stack)
      if out_stack:is_empty() then inv:set_stack("done",1,res_item)
      else out_stack:add_item(res_item); inv:set_stack("done",1,out_stack) end
      remove_ent(pos)
    end
    meta:set_int("cook_time", 0); meta:set_int("cook_tot", 0)
  else
    meta:set_int("cook_time", t)
  end

  return true
end

-- ========= override nodes with cooking/inventory behavior =========
local function patch_grill_node(nodename, is_hot)
  local def = table.copy(minetest.registered_nodes[nodename] or {})
  if not def then return end

  local old_rc = def.on_rightclick
  def.on_rightclick = function(pos, node, player, itemstack, pointed)
    if player and try_insert_food(pos, node, player) then
      ensure_ent(pos, node, minetest.get_meta(pos):get_inventory():get_stack("food",1):get_name(), 0)
      return itemstack
    end
    if old_rc then return old_rc(pos, node, player, itemstack, pointed) end
  end

  local old_construct = def.on_construct
  def.on_construct = function(pos)
    if old_construct then old_construct(pos) end
    setup_inventory(pos)
  end

  local old_destruct = def.on_destruct
  def.on_destruct = function(pos)
    remove_ent(pos)
    if old_destruct then old_destruct(pos) end
  end

  local old_timer = def.on_timer
  if is_hot then
    def.on_timer = function(pos, elapsed)
      local again = grill_timer(pos, elapsed)
      if old_timer then old_timer(pos, elapsed) end
      return again
    end
  else
    -- cold nodes: no cook loop; but keep entity tidy if needed
    def.on_timer = function(pos, elapsed)
      if old_timer then return old_timer(pos, elapsed) end
      return false
    end
  end

  def.on_metadata_inventory_put  = function(pos) on_inv_change_start_timer(pos) end
  def.on_metadata_inventory_move = function(pos) on_inv_change_start_timer(pos) end
  def.allow_metadata_inventory_put  = allow_put
  def.allow_metadata_inventory_take = allow_take

  minetest.override_item(nodename, def)
end

-- apply patches
patch_grill_node(NAME_BASE,         false)
patch_grill_node(NAME_BASE_ON,      true)
patch_grill_node(NAME_LIDDED_OFF,   false)
patch_grill_node(NAME_LIDDED_ON,    true)
patch_grill_node(NAME_LIDDED_ON_NL, true)

-- ========= lid nodes: keep entity in sync on click =========
for _,lidname in ipairs({NAME_LID_CLOSED, NAME_LID_OPEN}) do
  local def = table.copy(minetest.registered_nodes[lidname] or {})
  if def then
    local old_rc = def.on_rightclick
    def.on_rightclick = function(pos, node, player, itemstack, pointed)
      local basepos = below(pos)
      local meta = minetest.get_meta(basepos)
      local inv = meta:get_inventory()
      if inv and not inv:get_stack("food",1):is_empty() then
        -- ensure entity updates visibility when lid toggled
        minetest.get_node_timer(basepos):start(1.0)
      end
      if old_rc then return old_rc(pos, node, player, itemstack, pointed) end
    end
    minetest.override_item(lidname, def)
  end
end
