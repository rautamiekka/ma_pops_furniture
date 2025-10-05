-- ===== compat hooks (provided by your compat.lua) =====================
local TEX = (moditems and moditems.TEXTURES) or {}     -- textures
local MAT = (moditems and moditems.MATERIALS) or {}    -- items/materials
local SND = (moditems and moditems.SOUNDS) or {}       -- sound defs

-- sensible fallbacks if compat keys are missing
local function F(key, fallback) return TEX[key] or fallback end
local function M(key, fallback) return MAT[key] or fallback end
local function S(key, fallback) return SND[key] or fallback end

-- common fallbacks (MTG names) used below when compat doesn’t override
local FALLBACK = {
  stone_png   = "default_stone.png",
  wood_png    = "default_wood.png",
  coal_png    = "default_coal_block.png",
  coral_png   = "default_coral_skeleton.png",
  water_anim  = "default_water_source_animated.png",
  leaves      = {
    apple  = "default_leaves.png",
    jungle = "default_jungleleaves.png",
    pine   = "default_pine_needles.png",
    acacia = "default_acacia_leaves.png",
    aspen  = "default_aspen_leaves.png",
  },
  materials = {
    apple_leaves  = "default:leaves",
    jungle_leaves = "default:jungleleaves",
    pine_leaves   = "default:pine_needles",
    acacia_leaves = "default:acacia_leaves",
    aspen_leaves  = "default:aspen_leaves",
  },
}

-- helper: fire node set (MTG & Mineclonia)
local FIRE_NODES = {"fire:basic_flame", "mcl_fire:fire"}

-- =====================================================================
-- Hedge API
-- =====================================================================

function ma_pops_furniture.register_hedge(name, def)
  -- sounds via compat, fallback to default leaves
  def.sounds = def.sounds
      or S("LEAVES", (minetest.global_exists("default") and default.node_sound_leaves_defaults()) or nil)

  minetest.register_node(name, {
    description = def.description or "Hedge",
    drawtype    = "nodebox",
    paramtype   = "light",
    tiles       = {def.texture},
    groups      = def.groups or {snappy=3, flammable=2, leaves=1, hedge=1},
    waving      = 1,
    node_box = {
      type = "connected",
      fixed         = {{-5/16, -0.5, -5/16, 5/16, 5/16, 5/16}},
      connect_left  = {{-0.5, -0.5, -5/16, -5/16, 5/16, 5/16}},
      connect_right = {{ 5/16, -0.5, -5/16,  0.5, 5/16, 5/16}},
      connect_front = {{-5/16, -0.5, -0.5,   5/16, 5/16, -5/16}},
      connect_back  = {{-5/16, -0.5,  5/16,  5/16, 5/16,  0.5}},
    },
    connects_to = {"group:fence", "group:wood", "group:tree", "group:hedge"},
    light_source = def.light_source or 0,
    sounds = def.sounds,

    after_place_node = function(pos)
      local pos_under = {x=pos.x, y=pos.y-1, z=pos.z}
      local pos_above = {x=pos.x, y=pos.y+1, z=pos.z}
      local node_under = string.gsub(minetest.get_node(pos_under).name, "_full$", "")
      local node_above = string.gsub(minetest.get_node(pos_above).name, "_full$", "")

      if minetest.get_item_group(node_under, "hedge") == 1 then
        minetest.swap_node(pos_under, {name = node_under .. "_full"})
      end
      if minetest.get_item_group(node_above, "hedge") == 1 then
        minetest.swap_node(pos, {name = name .. "_full"})
      end
    end,

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
      local pos_under = {x=pos.x, y=pos.y-1, z=pos.z}
      local node_under = string.gsub(minetest.get_node(pos_under).name, "_full$", "")
      if minetest.get_item_group(node_under, "hedge") == 1 and digger and digger:is_player() then
        minetest.swap_node(pos_under, {name = node_under})
      end
    end,
  })

  minetest.register_node(name .. "_full", {
    description = def.description or "Hedge",
    drawtype    = "nodebox",
    paramtype   = "light",
    tiles       = {def.texture},
    groups = def.groups or {
      snappy=3, flammable=2, leaves=1, hedge=1, not_in_creative_inventory=1
    },
    waving = 1,
    node_box = {
      type = "connected",
      fixed         = {{-5/16, -0.5, -5/16, 5/16, 0.5, 5/16}},
      connect_left  = {{-0.5,  -0.5, -5/16, -5/16, 0.5, 5/16}},
      connect_right = {{ 5/16, -0.5, -5/16,  0.5,  0.5, 5/16}},
      connect_front = {{-5/16, -0.5, -0.5,   5/16, 0.5, -5/16}},
      connect_back  = {{-5/16, -0.5,  5/16,  5/16, 0.5,  0.5}},
    },
    connects_to = {"group:fence", "group:wood", "group:tree", "group:hedge"},
    light_source = def.light_source or 0,
    sounds = def.sounds,
    drop = name,

    after_dig_node = function(pos, oldnode, oldmetadata, digger)
      local pos_under = {x=pos.x, y=pos.y-1, z=pos.z}
      local node_under = string.gsub(minetest.get_node(pos_under).name, "_full$", "")
      if minetest.get_item_group(node_under, "hedge") == 1 and digger and digger:is_player() then
        minetest.swap_node(pos_under, {name = node_under})
      end
    end,
  })

  -- craft
  minetest.register_craft({
    output = name .. " 4",
    recipe = {
      {def.material, def.material, def.material},
      {def.material, def.material, def.material},
    }
  })
end

-- =====================================================================
-- Hedge registrations (use compat textures/materials, fall back to MTG)
-- =====================================================================

ma_pops_furniture.register_hedge("ma_pops_furniture:apple_hedge", {
  description = "Apple Hedge",
  texture     = F("LEAVES_APPLE",  FALLBACK.leaves.apple),
  material    = M("LEAVES_APPLE_ITEM",  FALLBACK.materials.apple_leaves),
})

ma_pops_furniture.register_hedge("ma_pops_furniture:jungle_hedge", {
  description = "Jungle Hedge",
  texture     = F("LEAVES_JUNGLE", FALLBACK.leaves.jungle),
  material    = M("LEAVES_JUNGLE_ITEM", FALLBACK.materials.jungle_leaves),
})

ma_pops_furniture.register_hedge("ma_pops_furniture:pine_hedge", {
  description = "Pine Hedge",
  texture     = F("LEAVES_PINE",   FALLBACK.leaves.pine),
  material    = M("LEAVES_PINE_ITEM",   FALLBACK.materials.pine_leaves),
})

ma_pops_furniture.register_hedge("ma_pops_furniture:acacia_hedge", {
  description = "Acacia Hedge",
  texture     = F("LEAVES_ACACIA", FALLBACK.leaves.acacia),
  material    = M("LEAVES_ACACIA_ITEM", FALLBACK.materials.acacia_leaves),
})

ma_pops_furniture.register_hedge("ma_pops_furniture:aspen_hedge", {
  description = "Aspen Hedge",
  texture     = F("LEAVES_ASPEN",  FALLBACK.leaves.aspen),
  material    = M("LEAVES_ASPEN_ITEM",  FALLBACK.materials.aspen_leaves),
})

-- Optional: alt recipes for external "hedges" mod (leave as-is; harmless if absent)
minetest.register_craft({
  output = "hedges:apple_hedge 4",
  recipe = {
    {"default:bush_leaves","default:bush_leaves","default:bush_leaves"},
    {"default:bush_leaves","default:bush_leaves","default:bush_leaves"},
  }
})
minetest.register_craft({
  output = "hedges:acacia_hedge 4",
  recipe = {
    {"default:acacia_bush_leaves","default:acacia_bush_leaves","default:acacia_bush_leaves"},
    {"default:acacia_bush_leaves","default:acacia_bush_leaves","default:acacia_bush_leaves"},
  }
})

-- =====================================================================
-- Birdbath
-- =====================================================================

minetest.register_node('ma_pops_furniture:birdbath', {
  description = 'Birdbath',
  drawtype    = 'mesh',
  mesh        = 'FM_birdbath.obj',
  tiles = {
    { name = F("STONE", FALLBACK.stone_png) },
    { name = F("WATER_ANIM", FALLBACK.water_anim),
      animation = {type='vertical_frames', aspect_w=16, aspect_h=16, length=2.0} },
  },
  groups     = {cracky=2, oddly_breakable_by_hand=5, furniture=1},
  paramtype  = 'light',
  paramtype2 = 'facedir',
  sounds     = S("STONE", moditems.STONE_SOUNDS),
})

-- =====================================================================
-- Doorbell
-- =====================================================================

minetest.register_node('ma_pops_furniture:doorbell', {
  description = 'Doorbell',
  drawtype    = 'nodebox',
  tiles = {
    "mp_db_top.png", "mp_db_top.png",
    "mp_db_right.png", "mp_db_left.png",
    F("WOOD", FALLBACK.wood_png),
    "mp_db_front.png",
  },
  groups     = {cracky=2, oddly_breakable_by_hand=5, furniture=1},
  paramtype  = 'light',
  paramtype2 = 'facedir',
  sounds     = S("STONE", moditems.STONE_SOUNDS),
  on_rightclick = function(pos, node)
    node.name = "ma_pops_furniture:doorbell_ring"
    minetest.swap_node(pos, node)
    minetest.get_node_timer(pos):start(1.0) -- one second ring
  end,
  node_box = {
    type = "fixed",
    fixed = {
      {-0.125, -0.375, 0.4375, 0.125, -0.125, 0.5},
      {-0.0625,-0.3125, 0.375, 0.0625,-0.1875, 0.4375},
    },
  }
})

minetest.register_node('ma_pops_furniture:doorbell_ring', {
  description = 'Doorbell (ring)',
  drawtype    = 'nodebox',
  tiles = {
    "mp_db_top.png", "mp_db_top.png",
    "mp_db_right.png", "mp_db_left.png",
    F("WOOD", FALLBACK.wood_png),
    "mp_db_front.png",
  },
  groups     = {cracky=2, oddly_breakable_by_hand=5, furniture=1, not_in_creative_inventory=1},
  drop       = 'ma_pops_furniture:doorbell',
  on_timer = function(pos)
    local node = minetest.get_node(pos)
    node.name = "ma_pops_furniture:doorbell"
    minetest.swap_node(pos, node)
  end,
  paramtype  = 'light',
  paramtype2 = 'facedir',
  sounds     = S("STONE", moditems.STONE_SOUNDS),
  node_box = {
    type="fixed",
    fixed = {
      {-0.125, -0.375, 0.4375, 0.125, -0.125, 0.5},
      {-0.0625,-0.3125, 0.375, 0.0625,-0.1875, 0.4375},
    },
  }
})

-- =====================================================================
-- Stone paths (randomized variant on place)
-- =====================================================================

minetest.register_node('ma_pops_furniture:stone_path_1', {
  description = 'Stone Path',
  drawtype    = 'mesh',
  mesh        = 'FM_stone_path_1.obj',
  tiles       = { F("STONE", FALLBACK.stone_png) },
  groups      = {cracky=2, oddly_breakable_by_hand=5, furniture=1},
  paramtype   = 'light',
  paramtype2  = 'facedir',
  sounds      = S("STONE", moditems.STONE_SOUNDS),
  selection_box = { type='fixed', fixed={-.5,-.5,-.5, .5,-.4,.5} },
  collision_box = { type='fixed', fixed={-.5,-.5,-.5, .5,-.4,.5} },
  on_place = function(itemstack, placer, pointed_thing)
    local stack = ItemStack("ma_pops_furniture:stone_path_" .. math.random(1,4))
    local ret = minetest.item_place(stack, placer, pointed_thing)
    return ItemStack("ma_pops_furniture:stone_path_1 " ..
      (itemstack:get_count() - (1 - ret:get_count())))
  end,
})

for i = 2, 4 do
  minetest.register_node('ma_pops_furniture:stone_path_'..i, {
    description  = 'Stone Path',
    drawtype     = 'mesh',
    mesh         = 'FM_stone_path_'..i..'.obj',
    tiles        = { F("STONE", FALLBACK.stone_png) },
    groups       = {cracky=2, oddly_breakable_by_hand=5, furniture=1, not_in_creative_inventory=1},
    paramtype    = 'light',
    paramtype2   = 'facedir',
    sounds       = S("STONE", moditems.STONE_SOUNDS),
    drop         = 'ma_pops_furniture:stone_path_1',
    selection_box = { type='fixed', fixed={-.5,-.5,-.5, .5,-.4,.5} },
    collision_box = { type='fixed', fixed={-.5,-.5,-.5, .5,-.4,.5} },
  })
end

-- =====================================================================
-- Outdoor lamp (toggle)
-- =====================================================================

minetest.register_node("ma_pops_furniture:outdoor_lamp", {
  description = "Outdoor Lamp",
  tiles = {
    F("STONE", FALLBACK.stone_png),
    F("STONE", FALLBACK.stone_png).."^mp_light_off.png",
    F("STONE", FALLBACK.stone_png),
    F("STONE", FALLBACK.stone_png),
    F("STONE", FALLBACK.stone_png),
    F("STONE", FALLBACK.stone_png),
  },
  drawtype   = "nodebox",
  paramtype  = "light",
  paramtype2 = "facedir",
  sounds     = S("STONE", moditems.STONE_SOUNDS),
  on_rightclick = function (pos, node)
    node.name = "ma_pops_furniture:outdoor_lamp_on"
    minetest.set_node(pos, node)
  end,
  groups = {choppy=2, oddly_breakable_by_hand=2},
  node_box = { type="fixed", fixed={{-0.125, 0.25, -0.125, 0.125, 0.5, 0.125}} },
})

minetest.register_node("ma_pops_furniture:outdoor_lamp_on", {
  description = "Outdoor Lamp On",
  tiles = {
    F("STONE", FALLBACK.stone_png),
    F("STONE", FALLBACK.stone_png).."^mp_light_on.png",
    F("STONE", FALLBACK.stone_png),
    F("STONE", FALLBACK.stone_png),
    F("STONE", FALLBACK.stone_png),
    F("STONE", FALLBACK.stone_png),
  },
  drawtype   = "nodebox",
  paramtype  = "light",
  paramtype2 = "facedir",
  light_source = 14,
  drop       = 'ma_pops_furniture:outdoor_lamp',
  sounds     = S("STONE", moditems.STONE_SOUNDS),
  on_rightclick = function (pos, node)
    node.name = "ma_pops_furniture:outdoor_lamp"
    minetest.set_node(pos, node)
  end,
  groups = {choppy=2, oddly_breakable_by_hand=2, not_in_creative_inventory=1},
  node_box = { type="fixed", fixed={{-0.125, 0.25, -0.125, 0.125, 0.5, 0.125}} },
})

-- =====================================================================
-- Trampoline
-- =====================================================================

minetest.register_node("ma_pops_furniture:trampoline", {
  description = "Trampoline",
  tiles = {
    "mp_trampoline_top.png",
    F("COAL_BLOCK", FALLBACK.coal_png),
    "mp_trampoline_side.png",
  },
  drawtype  = "nodebox",
  paramtype2 = "facedir",
  paramtype  = "light",
  groups    = {cracky=3, oddly_breakable_by_hand=1, fall_damage_add_percent=-80, bouncy=90},
  sounds    = {wood = {name="xdecor_bouncy", gain=0.8}},
  node_box = {
    type = "fixed",
    fixed = {
      {-0.5, -0.3125, -0.5,  0.5, 0,       0.5},
      { 0.1875, -0.5,  0.1875, 0.5, -0.3125, 0.5},
      {-0.5,  -0.5,   0.1875, -0.1875, -0.3125, 0.5},
      {-0.5,  -0.5,  -0.5,    -0.1875, -0.3125, -0.1875},
      { 0.1875, -0.5, -0.5,    0.5,     -0.3125, -0.1875},
    },
  }
})

-- =====================================================================
-- Smoke detector (MTG + Mineclonia, uses compat where possible)
-- =====================================================================

minetest.register_node("ma_pops_furniture:smoke_detector", {
  description = "Smoke Detector",
  tiles = {
    F("CORAL", FALLBACK.coral_png), -- top
    F("CORAL", FALLBACK.coral_png), -- bottom
    F("CORAL", FALLBACK.coral_png),
    F("CORAL", FALLBACK.coral_png),
    F("CORAL", FALLBACK.coral_png),
    F("CORAL", FALLBACK.coral_png),
  },
  groups = {cracky=3, oddly_breakable_by_hand=3},
  on_timer = function(pos)
    if minetest.find_node_near(pos, 20, FIRE_NODES, false) then
      local node = minetest.get_node(pos)
      node.name = "ma_pops_furniture:smoke_detector_on"
      minetest.swap_node(pos, node)
      minetest.get_node_timer(pos):start(0.0)
    else
      minetest.get_node_timer(pos):start(10.0)
    end
  end,
  after_place_node = function(pos)
    minetest.get_node_timer(pos):start(0.0)
  end,
  drawtype = "nodebox",
  node_box = {
    type = "fixed",
    fixed = {
      {-0.375, 0.375, -0.375, 0.375, 0.5,   0.375},
      {-0.3125,0.3125,-0.3125,0.3125,0.375, 0.3125},
    }
  }
})

minetest.register_node("ma_pops_furniture:smoke_detector_on", {
  description = "Smoke Detector",
  tiles = {
    F("CORAL", FALLBACK.coral_png),
    F("CORAL", FALLBACK.coral_png),
    F("CORAL", FALLBACK.coral_png),
    F("CORAL", FALLBACK.coral_png),
    F("CORAL", FALLBACK.coral_png),
    F("CORAL", FALLBACK.coral_png),
  },
  drop   = 'ma_pops_furniture:smoke_detector',
  groups = {cracky=3, oddly_breakable_by_hand=3, not_in_creative_inventory=1},

  on_destruct = function(pos)
    local meta = minetest.get_meta(pos)
    if not meta then return end
    local t = meta:to_table()
    if t and t.fields and t.fields.sound_handle then
      minetest.sound_stop(t.fields.sound_handle)
      t.fields.sound_handle = nil
      meta:from_table(t)
    end
  end,

  on_rightclick = function(pos)
    local meta = minetest.get_meta(pos)
    if not meta then return end
    local t = meta:to_table()
    if t and t.fields and t.fields.sound_handle then
      minetest.sound_stop(t.fields.sound_handle)
      t.fields.sound_handle = nil
      minetest.get_node_timer(pos):start(3.0)
      meta:from_table(t)
    end
  end,

  on_timer = function(pos)
    if minetest.find_node_near(pos, 20, FIRE_NODES, false) then
      local meta = minetest.get_meta(pos)
      local t = (meta and meta:to_table()) or {fields={}}
      if not (t.fields and t.fields.sound_handle) then
        local handle = minetest.sound_play("mp_smoke_detector", {
          pos = pos, gain = 2.1, max_hear_distance = 96, loop = true
        })
        t.fields = t.fields or {}
        t.fields.sound_handle = handle
        meta:from_table(t)
      end
      minetest.get_node_timer(pos):start(1.0)
    else
      local meta = minetest.get_meta(pos)
      local t = meta and meta:to_table()
      if t and t.fields and t.fields.sound_handle then
        minetest.sound_stop(t.fields.sound_handle)
        t.fields.sound_handle = nil
        meta:from_table(t)
      end
      local node = minetest.get_node(pos)
      node.name = "ma_pops_furniture:smoke_detector"
      minetest.swap_node(pos, node)
      minetest.get_node_timer(pos):start(0.0)
    end
  end,

  drawtype   = "nodebox",
  paramtype  = "light",
  light_source = 3, -- small glow (replace undefined `light`)
  node_box = {
    type = "fixed",
    fixed = {
      {-0.375, 0.375, -0.375, 0.375, 0.5,   0.375},
      {-0.3125,0.3125,-0.3125,0.3125,0.375, 0.3125},
    }
  }
})

minetest.register_lbm({
  label = "Normalize smoke detector-on nodes",
  name  = "ma_pops_furniture:replace_smoke_detector_on",
  nodenames = {"ma_pops_furniture:smoke_detector_on"},
  run_at_every_load = true,
  action = function(pos, node)
    node.name = "ma_pops_furniture:smoke_detector"
    minetest.swap_node(pos, node)
    minetest.get_node_timer(pos):start(0.0)
  end
})
