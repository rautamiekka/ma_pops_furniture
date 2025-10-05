-- chairs_and_tables.lua — Minetest Game + Mineclonia compatible
local MODNAME = minetest.get_current_modname()
local MODPATH = minetest.get_modpath(MODNAME)
local C       = dofile(MODPATH.."/compat.lua")

-- Texture resolver: MTG uses default_*; Mineclonia uses mcl_* names.
local function get_tex(material)
  if not C.IS_MCL then
    return "default_" .. material .. ".png"
  end
  -- Mineclonia mappings
  local plank_map = {
    wood        = "oak",
    acacia_wood = "acacia",
    aspen_wood  = "birch",
    pine_wood   = "spruce",
    junglewood  = "jungle",
  }
  if material == "cobble" then
    return "mcl_core_cobblestone.png"
  end
  local kind = plank_map[material] or "oak"
  return "mcl_core_planks_" .. kind .. ".png"
end

local function groups_for(material, extra)
  if material == "cobble" then
    return C.stone_groups(C.merge_groups(extra, {}))
  end
  return C.wood_groups(C.merge_groups(extra, {flammable = 1}))
end

local function sounds_for(material)
  return (material == "cobble") and C.sounds.stone() or C.sounds.wood()
end

----------------------------------------------------------------------
-- CHAIRS
----------------------------------------------------------------------
local chair_table = { -- name, material
  {'Stone Chair',          'cobble'},
  {'Wood Chair',           'wood'},
  {'Acacia Wood Chair',    'acacia_wood'},
  {'Aspen Wood Chair',     'aspen_wood'},
  {'Pine Wood Chair',      'pine_wood'},
  {'Jungle Wood Chair',    'junglewood'},
}

for i = 1, #chair_table do
  local name, material = chair_table[i][1], chair_table[i][2]

  minetest.register_node("ma_pops_furniture:chair_"..material, {
    description = name,
    drawtype    = "nodebox",
    tiles       = { get_tex(material) },
    groups      = groups_for(material, {choppy = 2, oddly_breakable_by_hand = 2, furniture = 1}),
    paramtype   = "light",
    paramtype2  = "facedir",
    sounds      = sounds_for(material),

    -- keep your sitting helpers
    can_dig = ma_pops_furniture.sit_dig,
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
      ma_pops_furniture.sit(pos, node, clicker, pointed_thing)
      return itemstack
    end,

    node_box = {
      type  = "fixed",
      fixed = {
        {-0.4375, -0.5,  0.3125, -0.3125, -0.0625, 0.4375}, -- leg
        { 0.3125, -0.5,  0.3125,  0.4375, -0.0625, 0.4375}, -- leg
        {-0.4375, -0.5, -0.4375, -0.3125, -0.0625,-0.3125}, -- leg
        { 0.3125, -0.5, -0.4375,  0.4375, -0.0625,-0.3125}, -- leg
        {-0.4375, -0.0625,-0.4375, 0.4375, 0.0625, 0.4375}, -- seat
        {-0.4375,  0.0625, 0.3125, 0.4375, 0.8125, 0.4375}, -- backrest
      }
    }
  })
end

-- Auto-connecting tables (MrCrayfish-style) for MTG + Mineclonia
-- Call this after your table nodes are registered.

local MPF = ma_pops_furniture or {}
MPF._table_dirs = {
  {x= 0, y=0, z= 1, name="S"}, -- +Z
  {x= 1, y=0, z= 0, name="E"}, -- +X
  {x= 0, y=0, z=-1, name="N"}, -- -Z
  {x=-1, y=0, z= 0, name="W"}, -- -X
}

local function table_material_from_name(nodename)
  -- matches ma_pops_furniture:table(_variant)_<material>
  -- variants: "", "2", "c", "center"
  local mat =
    nodename:match("^ma_pops_furniture:table_([%w_]+)$")
    or nodename:match("^ma_pops_furniture:table2_([%w_]+)$")
    or nodename:match("^ma_pops_furniture:table_c_([%w_]+)$")
    or nodename:match("^ma_pops_furniture:table_center_([%w_]+)$")
  return mat
end

local function is_table_of_material(node, material)
  if not node or not node.name then return false end
  if not material then return false end
  return table_material_from_name(node.name) == material
end

local function get_facedir_for_dir(dir_name)
  -- facedir: 0 = +Z (S), 1 = +X (E), 2 = -Z (N), 3 = -X (W)
  if dir_name == "S" then return 0 end
  if dir_name == "E" then return 1 end
  if dir_name == "N" then return 2 end
  if dir_name == "W" then return 3 end
  return 0
end

-- Decide shape given neighbors:
-- 0 neighbors: single -> pedestal (table_)
-- 1 neighbor : end piece -> use table2_ (4 legs) oriented away from neighbor so front faces neighbor
-- 2 neighbors:
--   - opposite (straight line) -> center (top-only)
--   - adjacent (corner) -> corner node (table_c_) oriented to that corner
-- 3 neighbors: T -> center (top-only)
-- 4 neighbors: cross -> center (top-only)
local function choose_shape(neigh)
  local count = 0
  for _,hit in pairs(neigh) do if hit then count = count + 1 end end

  if count == 0 then
    return "single", nil
  elseif count == 1 then
    -- find which side is connected; end faces that side
    for k,v in pairs(neigh) do if v then return "end", k end end
  elseif count == 2 then
    -- corner vs straight
    if (neigh.N and neigh.S) or (neigh.E and neigh.W) then
      return "straight", nil
    else
      -- corner: figure which adjacent pair
      if neigh.N and neigh.E then return "corner", "NE" end
      if neigh.E and neigh.S then return "corner", "SE" end
      if neigh.S and neigh.W then return "corner", "SW" end
      if neigh.W and neigh.N then return "corner", "NW" end
    end
  end
  -- 3 or 4 neighbors -> middle/top-only
  return "center", nil
end

local function pick_node_and_param2(material, shape, orient)
  -- Node ids you already have:
  -- table_       : pedestal (single)
  -- table2_      : 4 legs (we'll use as END)
  -- table_c_     : CORNER
  -- table_center_: center/top-only (straight/T/cross)
  if shape == "single" then
    return "ma_pops_furniture:table_"..material, nil
  elseif shape == "end" then
    -- Face the neighbor (so the "end" looks natural). We'll just orient the node.
    local param2 = get_facedir_for_dir(orient)
    return "ma_pops_furniture:table2_"..material, param2
  elseif shape == "corner" then
    -- Use facedir so the corner’s leg sits at the inside.
    -- For corners, map:
    -- NE -> face East   (1)
    -- SE -> face South  (0)
    -- SW -> face West   (3)
    -- NW -> face North  (2)
    local map = { NE=1, SE=0, SW=3, NW=2 }
    return "ma_pops_furniture:table_c_"..material, map[orient] or 0
  elseif shape == "straight" or shape == "center" then
    -- Top-only so long runs, T’s, and crosses look continuous
    return "ma_pops_furniture:table_center_"..material, nil
  end
  return "ma_pops_furniture:table_"..material, nil
end

function MPF.update_table_connections(pos)
  local node = minetest.get_node_or_nil(pos)
  if not node then return end
  local material = table_material_from_name(node.name)
  if not material then return end

  -- probe neighbors
  local neigh = {N=false,E=false,S=false,W=false}
  local pN = vector.add(pos, {x=0,y=0,z=-1})
  local pE = vector.add(pos, {x=1,y=0,z=0})
  local pS = vector.add(pos, {x=0,y=0,z=1})
  local pW = vector.add(pos, {x=-1,y=0,z=0})

  neigh.N = is_table_of_material(minetest.get_node_or_nil(pN), material)
  neigh.E = is_table_of_material(minetest.get_node_or_nil(pE), material)
  neigh.S = is_table_of_material(minetest.get_node_or_nil(pS), material)
  neigh.W = is_table_of_material(minetest.get_node_or_nil(pW), material)

  local shape, orient = choose_shape(neigh)
  local newname, newparam2 = pick_node_and_param2(material, shape, orient)

  if newname and (newname ~= node.name or (newparam2 and newparam2 ~= node.param2)) then
    minetest.swap_node(pos, {name = newname, param2 = newparam2 or node.param2})
  end
end

-- Update this node and its neighbors when anything changes
local function bump_self_and_neighbors(pos)
  MPF.update_table_connections(pos)
  for _,d in ipairs(MPF._table_dirs) do
    local np = vector.add(pos, d)
    MPF.update_table_connections(np)
  end
end

-- Hook into existing tables
local function hook_autoconnect_for(material)
  local ids = {
    "ma_pops_furniture:table_"..material,
    "ma_pops_furniture:table2_"..material,
    "ma_pops_furniture:table_c_"..material,
    "ma_pops_furniture:table_center_"..material,
  }
  for _,id in ipairs(ids) do
    local def = minetest.registered_nodes[id]
    if def then
      -- wrap existing callbacks (if present)
      local old_construct   = def.on_construct
      local old_destruct    = def.on_destruct
      local old_after_place = def.after_place_node
      local old_after_dig   = def.after_dig_node
      local old_punch       = def.on_punch

      def.on_construct = function(pos)
        if old_construct then old_construct(pos) end
        bump_self_and_neighbors(pos)
      end

      def.after_place_node = function(pos, placer, itemstack, pointed_thing)
        if old_after_place then old_after_place(pos, placer, itemstack, pointed_thing) end
        bump_self_and_neighbors(pos)
      end

      def.after_dig_node = function(pos, oldnode, oldmeta, digger)
        if old_after_dig then old_after_dig(pos, oldnode, oldmeta, digger) end
        -- after_dig happens when the table is gone; still update neighbors
        for _,d in ipairs(MPF._table_dirs) do
          local np = vector.add(pos, d)
          MPF.update_table_connections(np)
        end
      end

      def.on_punch = function(pos, node, puncher, pointed_thing)
        if old_punch then old_punch(pos, node, puncher, pointed_thing) end
        bump_self_and_neighbors(pos)
      end

      -- Minetest 5.0+: neighbor change hook
      def.on_neighbor_change = function(pos, neighbor_pos)
        bump_self_and_neighbors(pos)
      end

      minetest.override_item(id, def)
    end
  end
end

-- Register hooks for all table materials you use
local table_materials = {"cobble","wood","acacia_wood","aspen_wood","pine_wood","junglewood"}
for _,mat in ipairs(table_materials) do
  hook_autoconnect_for(mat)
end

-- Optional: LBM to normalize pre-existing worlds
minetest.register_lbm({
  name = "ma_pops_furniture:refresh_tables",
  nodenames = {
    "ma_pops_furniture:table_cobble",
    "ma_pops_furniture:table_wood",
    "ma_pops_furniture:table_acacia_wood",
    "ma_pops_furniture:table_aspen_wood",
    "ma_pops_furniture:table_pine_wood",
    "ma_pops_furniture:table_junglewood",
    "ma_pops_furniture:table2_cobble",
    "ma_pops_furniture:table2_wood",
    "ma_pops_furniture:table2_acacia_wood",
    "ma_pops_furniture:table2_aspen_wood",
    "ma_pops_furniture:table2_pine_wood",
    "ma_pops_furniture:table2_junglewood",
    "ma_pops_furniture:table_c_cobble",
    "ma_pops_furniture:table_c_wood",
    "ma_pops_furniture:table_c_acacia_wood",
    "ma_pops_furniture:table_c_aspen_wood",
    "ma_pops_furniture:table_c_pine_wood",
    "ma_pops_furniture:table_c_junglewood",
    "ma_pops_furniture:table_center_cobble",
    "ma_pops_furniture:table_center_wood",
    "ma_pops_furniture:table_center_acacia_wood",
    "ma_pops_furniture:table_center_aspen_wood",
    "ma_pops_furniture:table_center_pine_wood",
    "ma_pops_furniture:table_center_junglewood",
  },
  run_at_every_load = false,
  action = function(pos, node)
    MPF.update_table_connections(pos)
  end
})
