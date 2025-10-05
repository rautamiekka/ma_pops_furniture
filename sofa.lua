-- ==== compat hooks (from compat.lua) =================================
local TEX = (moditems and moditems.TEXTURES) or {}
local SND = (moditems and moditems.SOUNDS) or {}

-- Get a wool texture for a given hue, with MTG fallback.
local function WOOL(hue)
  if TEX.WOOL and TEX.WOOL[hue] then return TEX.WOOL[hue] end
  return "wool_" .. hue .. ".png"
end

local WOOD_SOUNDS = SND.WOOD or moditems.WOOD_SOUNDS
-- =====================================================================

ma_pops_furniture.default_hues = {
  "white","grey","dark_grey","black","violet","blue","cyan",
  "dark_green","green","yellow","orange","red","magenta"
}

local sofa_table = { -- name, color, colorize(hex/intensity)  (colorize kept for future use)
  {'Black','black','black:225'},
  {'Blue','blue','blue:225'},
  {'Brown','brown','brown:225'},
  {'Cyan','cyan','cyan:200'},
  {'Dark Green','dark_green','green:225'},
  {'Dark Grey','dark_grey','black:200'},
  {'Green','green','#32cd32:150'},
  {'Grey','grey','black:100'},
  {'Magenta','magenta','magenta:200'},
  {'Orange','orange','orange:225'},
  {'Pink','pink','pink:225'},
  {'Red','red','red:225'},
  {'Violet','violet','violet:225'},
  {'White','white','white:1'},
  {'Yellow','yellow','yellow:225'},
}

-- dye name -> sofa color map
local dye_to_color = {
  black='black', white='white', grey='grey', dark_grey='dark_grey',
  violet='violet', blue='blue', cyan='cyan', dark_green='dark_green',
  green='green', yellow='yellow', orange='orange', red='red',
  magenta='magenta', pink='pink', brown='brown'
}

-- Determine the color suffix from a sofa node name
local function sofa_color_from_name(nodename)
  return nodename:match("_(%w+)$")
end

-- Build a sofa node name from type suffix ("", "_l", "_m", "_r", "_c") and color
local function sofa_name(type_suffix, color)
  return "ma_pops_furniture:sofa"..type_suffix.."_"..color
end

-- Update a single sofa at `pos` to L/M/R (or base) depending on neighbors, preserving color
local function update_sofa(pos)
  local node = minetest.get_node(pos)
  local color = sofa_color_from_name(node.name)
  if not color then return end

  -- check four cardinal neighbors for *any* sofa (any color / segment)
  local offsets = {
    {x =  1, z =  0, key = "r"},
    {x = -1, z =  0, key = "l"},
    {x =  0, z =  1, key = "s"},
    {x =  0, z = -1, key = "n"},
  }
  local connected = { l=false, r=false }

  for _, off in ipairs(offsets) do
    local p = {x = pos.x + off.x, y = pos.y, z = pos.z + off.z}
    local n = minetest.get_node(p).name
    if n:find("^ma_pops_furniture:sofa") then
      if off.key == "r" then connected.r = true
      elseif off.key == "l" then connected.l = true end
    end
  end

  local suffix = ""
  if connected.l and connected.r then
    suffix = "_m"
  elseif connected.l then
    suffix = "_l"
  elseif connected.r then
    suffix = "_r"
  else
    suffix = "" -- single/base
  end

  local newname = sofa_name(suffix, color)
  if newname ~= node.name and minetest.registered_nodes[newname] then
    minetest.set_node(pos, {name = newname, param2 = node.param2})
  end
end

-- Recolor (if punched with dye) then sit
local function sofa_punch(prefix_suffix, pos, node, clicker)
  local itemname = clicker:get_wielded_item():get_name()
  local dye = itemname:match("^dye:(.+)$")
  if dye and dye_to_color[dye] then
    local new_color = dye_to_color[dye]
    local newname = prefix_suffix .. new_color
    if minetest.registered_nodes[newname] then
      node.name = newname
      minetest.set_node(pos, node)
      -- update neighbors to re-evaluate joins after recolor
      for _, off in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
        update_sofa({x=pos.x+off[1], y=pos.y, z=pos.z+off[2]})
      end
    end
  end
  ma_pops_furniture.sit(pos, node, clicker)
end

-- Common node fields shared by all sofa variants
local common_groups_base  = {cracky=3, oddly_breakable_by_hand=2, flammable=1, furniture=1, fall_damage_add_percent=-80, bouncy=80}
local common_groups_seg   = {cracky=3, oddly_breakable_by_hand=2, flammable=1, not_in_creative_inventory=1, fall_damage_add_percent=-80, bouncy=80}
local common_sound_bouncy = {wood = {name="furn_bouncy", gain=0.8}}

local selection_base = {
  type = "fixed",
  fixed = {
    {-.5, -.5, -.5, .5, 0,  .5},
    {-.5, 0,   .5,  .5, .5, .2},
    {-.65,-.15,-.45,-.45,.3, .25}, -- left arm
    {.65, -.15,-.45, .45,.3, .25}, -- right arm
  },
}
local collision_base = {
  type = "fixed",
  fixed = {
    {-.5, -.5, -.5, .5, 0,  .5},
    {-.5, 0,   .5,  .5, .5, .2},
    {-.65,-.15,-.45,-.45,.3, .25},
    {.65, -.15,-.45, .45,.3, .25},
  },
}
local selection_l = {
  type="fixed", fixed = {
    {-.5, -.5, -.5, .5, 0,  .5},
    {-.5, 0,   .5,  .5, .5, .2},
    {.65, -.15,-.45, .45,.3, .25}, -- right arm only
  }
}
local collision_l = selection_l
local selection_m = { type="fixed", fixed={
  {-.5, -.5, -.5, .5, 0,  .5},
  {-.5, 0,   .5,  .5, .5, .2},
}}
local collision_m = selection_m
local selection_r = {
  type="fixed", fixed = {
    {-.5, -.5, -.5, .5, 0,  .5},
    {-.5, 0,   .5,  .5, .5, .2},
    {-.65,-.15,-.45,-.45,.3, .25}, -- left arm only
  }
}
local collision_r = selection_r
local selection_c = {
  type="fixed", fixed = {
    {-.5, -.5, -.5, .5, 0,  .5},
    {-.5, 0,   .5,  .5, .5, .2},
    {.2,  0,  -.5,  .5, .5, .2}, -- corner side
  }
}
local collision_c = {
  type="fixed", fixed = {
    {-.5, -.5, -.5, .5, 0,  .5},
    {-.5, 0,   .5,  .5, .5, .2},
  }
}

-- Register all sofa variants per color
for _, sofa in ipairs(sofa_table) do
  local name, color = sofa[1], sofa[2]

  -- base
  minetest.register_node("ma_pops_furniture:sofa_"..color, {
    description = name.." Sofa",
    drawtype   = "mesh",
    mesh       = "FM_sofa.obj",
    tiles      = { WOOL(color) },
    groups     = table.copy(common_groups_base),
    paramtype  = "light",
    paramtype2 = "facedir",
    sounds     = common_sound_bouncy,
    can_dig    = ma_pops_furniture.sit_dig,
    on_rightclick = function(pos, node, clicker, itemstack, pt)
      pos.y = pos.y + 0
      ma_pops_furniture.sit(pos, node, clicker, pt)
      return itemstack
    end,
    selection_box = selection_base,
    collision_box = collision_base,
    after_place_node = function(pos)
      update_sofa(pos)
      for _, off in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do
        update_sofa({x=pos.x+off[1], y=pos.y, z=pos.z+off[2]})
      end
    end,
    on_punch = function(pos, node, clicker)
      sofa_punch("ma_pops_furniture:sofa_", pos, node, clicker)
    end
  })

  -- left end
  minetest.register_node("ma_pops_furniture:sofa_l_"..color, {
    description = name.." Sofa",
    drawtype   = "mesh",
    mesh       = "FM_sofa_l.obj",
    tiles      = { WOOL(color) },
    groups     = table.copy(common_groups_seg),
    drop       = "ma_pops_furniture:sofa_"..color,
    paramtype  = "light",
    paramtype2 = "facedir",
    can_dig    = ma_pops_furniture.sit_dig,
    on_rightclick = function(pos, node, clicker, itemstack, pt)
      pos.y = pos.y + 0
      ma_pops_furniture.sit(pos, node, clicker, pt)
      return itemstack
    end,
    sounds = common_sound_bouncy,
    selection_box = selection_l,
    collision_box = collision_l,
    on_punch = function(pos, node, clicker)
      sofa_punch("ma_pops_furniture:sofa_l_", pos, node, clicker)
    end
  })

  -- middle
  minetest.register_node("ma_pops_furniture:sofa_m_"..color, {
    description = name.." Sofa",
    drawtype   = "mesh",
    mesh       = "FM_sofa_m.obj",
    tiles      = { WOOL(color) },
    groups     = table.copy(common_groups_seg),
    drop       = "ma_pops_furniture:sofa_"..color,
    paramtype  = "light",
    paramtype2 = "facedir",
    sounds     = common_sound_bouncy,
    can_dig    = ma_pops_furniture.sit_dig,
    on_rightclick = function(pos, node, clicker, itemstack, pt)
      pos.y = pos.y + 0
      ma_pops_furniture.sit(pos, node, clicker, pt)
      return itemstack
    end,
    selection_box = selection_m,
    collision_box = collision_m,
    on_punch = function(pos, node, clicker)
      sofa_punch("ma_pops_furniture:sofa_m_", pos, node, clicker)
    end
  })

  -- right end
  minetest.register_node("ma_pops_furniture:sofa_r_"..color, {
    description = name.." Sofa",
    drawtype   = "mesh",
    mesh       = "FM_sofa_r.obj",
    tiles      = { WOOL(color) },
    groups     = table.copy(common_groups_seg),
    drop       = "ma_pops_furniture:sofa_"..color,
    paramtype  = "light",
    paramtype2 = "facedir",
    sounds     = common_sound_bouncy,
    can_dig    = ma_pops_furniture.sit_dig,
    on_rightclick = function(pos, node, clicker, itemstack, pt)
      pos.y = pos.y + 0
      ma_pops_furniture.sit(pos, node, clicker, pt)
      return itemstack
    end,
    selection_box = selection_r,
    collision_box = collision_r,
    on_punch = function(pos, node, clicker)
      sofa_punch("ma_pops_furniture:sofa_r_", pos, node, clicker)
    end
  })

  -- corner
  minetest.register_node("ma_pops_furniture:sofa_c_"..color, {
    description = name.." Sofa",
    drawtype   = "mesh",
    mesh       = "FM_sofa_c.obj",
    tiles      = { WOOL(color) },
    groups     = table.copy(common_groups_seg),
    drop       = "ma_pops_furniture:sofa_"..color,
    paramtype  = "light",
    paramtype2 = "facedir",
    sounds     = common_sound_bouncy,
    can_dig    = ma_pops_furniture.sit_dig,
    on_rightclick = function(pos, node, clicker, itemstack, pt)
      pos.y = pos.y + 0
      ma_pops_furniture.sit(pos, node, clicker, pt)
      return itemstack
    end,
    selection_box = selection_c,
    collision_box = collision_c,
    on_punch = function(pos, node, clicker)
      sofa_punch("ma_pops_furniture:sofa_c_", pos, node, clicker)
    end
  })
end
