-- ma_pops_furniture/misc.lua
-- Uses compat.lua (moditems.TEXTURES / moditems.WOOL) for game-agnostic textures

-- Shortcuts to texture helpers with safe fallbacks (in case compat is partial)
local T = (moditems and moditems.TEXTURES) or {}
local function tex(name, fallback) return T[name] or fallback end
local WOOL = (moditems and moditems.WOOL) or function(color) return "wool_"..color..".png" end

-- Helper: (re)start node timer
local function tick(pos, interval) minetest.get_node_timer(pos):start(interval or 1.0) end

-- Common dye → color map (reused)
local DYE_TO_COLOR = {
  ['dye:black']='black',['dye:white']='white',['dye:grey']='grey',['dye:dark_grey']='dark_grey',
  ['dye:violet']='violet',['dye:blue']='blue',['dye:cyan']='cyan',['dye:dark_green']='dark_green',
  ['dye:green']='green',['dye:yellow']='yellow',['dye:orange']='orange',['dye:red']='red',
  ['dye:magenta']='magenta',['dye:pink']='pink',['dye:brown']='brown',
}

---------------------------------------------------------------------
-- Smoke detector (add Mineclonia fire support + minor cleanups)
---------------------------------------------------------------------

minetest.register_node("ma_pops_furniture:smoke_detector", {
  description = "Smoke Detector",
  tiles = { "mp_t.png","mp_b.png","mp_si.png","mp_si.png","mp_si.png","mp_si.png" },
  groups = {cracky = 3, oddly_breakable_by_hand = 3},
  on_timer = function(pos, elapsed)
    if minetest.find_node_near(pos, 20, {"fire:basic_flame","mcl_fire:fire"}, false) then
      local node = minetest.get_node(pos)
      node.name = "ma_pops_furniture:smoke_detector_on"
      minetest.swap_node(pos, node)
      tick(pos, 0.0)
    else
      tick(pos, 10.0) -- poll every 10s when idle
    end
  end,
  after_place_node = function(pos) tick(pos, 0.0) end,
  drawtype = "nodebox",
  node_box = {
    type = "fixed",
    fixed = {
      {-0.375, 0.375, -0.375, 0.375, 0.5, 0.375},
      {-0.3125, 0.3125, -0.3125, 0.3125, 0.375, 0.3125},
    }
  }
})

minetest.register_node("ma_pops_furniture:smoke_detector_on", {
  description = "Smoke Detector",
  tiles = { "mp_t.png","mp_b.png","mp_si.png","mp_si.png","mp_si.png","mp_si.png" },
  on_destruct = function(pos)
    local meta = minetest.get_meta(pos)
    local t = meta and meta:to_table()
    if t and t.fields and t.fields.sound_handle then
      minetest.sound_stop(t.fields.sound_handle)
      t.fields.sound_handle = nil
      meta:from_table(t)
    end
  end,
  on_rightclick = function(pos)
    local meta = minetest.get_meta(pos)
    local t = meta and meta:to_table()
    if t and t.fields and t.fields.sound_handle then
      minetest.sound_stop(t.fields.sound_handle)
      t.fields.sound_handle = nil
      meta:from_table(t)
      tick(pos, 3.0) -- snooze a moment
    end
  end,
  drop = 'ma_pops_furniture:smoke_detector',
  groups = {cracky = 3, oddly_breakable_by_hand = 3, not_in_creative_inventory=1},
  on_timer = function(pos, elapsed)
    if minetest.find_node_near(pos, 20, {"fire:basic_flame","mcl_fire:fire"}, false) then
      -- ensure looping alarm is playing
      local meta = minetest.get_meta(pos)
      local t = meta:to_table() or {fields={}}
      if not t.fields.sound_handle then
        t.fields.sound_handle = minetest.sound_play("mp_smoke_detector", {
          pos = pos, gain = 2.1, max_hear_distance = 96, loop = true
        })
        meta:from_table(t)
      end
      tick(pos, 1.0)
    else
      -- stop alarm, revert to off variant
      local meta = minetest.get_meta(pos)
      local t = meta and meta:to_table()
      if t and t.fields and t.fields.sound_handle then
        minetest.sound_stop(t.fields.sound_handle)
        t.fields.sound_handle = nil
        meta:from_table(t)
      end
      local node = minetest.get_node(pos)
      node.name = "ma_pops_furniture:sm
