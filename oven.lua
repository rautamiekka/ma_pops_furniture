-- ===== compat hooks (provided by your compat.lua) =====================
local TEX = (moditems and moditems.TEXTURES) or {}
local MAT = (moditems and moditems.MATERIALS) or {}
local SND = (moditems and moditems.SOUNDS) or {}

local function F(key, fallback) return TEX[key] or fallback end
local function M(key, fallback) return MAT[key] or fallback end
local function S(key, fallback) return SND[key] or fallback end

-- sensible MTG fallbacks
local FALLBACK = {
  fire_bg = "default_furnace_fire_bg.png",
  fire_fg = "default_furnace_fire_fg.png",
}
-- =====================================================================

local oven_fs =
  "size[8,7]"
  .."image[3.5,1.5;1,1;"..F("FURNACE_FIRE_BG", FALLBACK.fire_bg).."]"
  .."list[current_player;main;0,3;8,4;]"
  .."list[context;input;2,1.5;1,1;]"
  .."list[context;output;5,1.5;1,1;]"
  .."label[3,0.5;Oven]"
  .."label[1.5,1;Uncooked Food]"
  .."label[4.5,1;Cooked Food]"

local function get_active_oven_fs(item_percent)
  return "size[8,7]"
    .."image[3.5,1.5;1,1;"..F("FURNACE_FIRE_BG", FALLBACK.fire_bg).."^[lowpart:"
    ..(item_percent)..":"..F("FURNACE_FIRE_FG", FALLBACK.fire_fg).."]"
    .."list[current_player;main;0,3;8,4;]"
    .."list[context;input;2,1.5;1,1;]"
    .."list[context;output;5,1.5;1,1;]"
    .."label[3,0.5;Oven]"
    .."label[1.5,1;Uncooked Food]"
    .."label[4.5,1;Cooked Food]"
end

-- API
ma_pops_furniture.oven = {}
local oven = ma_pops_furniture.oven
oven.recipes = {}
function oven.register_recipe(input, output) oven.recipes[input] = output end

local function update_formspec(progress, goal, meta)
  local formspec
  if progress > 0 and progress <= goal then
    local item_percent = math.floor(progress / goal * 100)
    formspec = get_active_oven_fs(item_percent)
  else
    formspec = oven_fs
  end
  meta:set_string("formspec", formspec)
end

local function recalculate(pos)
  local meta, timer = minetest.get_meta(pos), minetest.get_node_timer(pos)
  local inv = meta:get_inventory()
  local stack = inv:get_stack("input", 1)
  if not oven.recipes[stack:get_name()] then return end
  timer:stop()
  update_formspec(0, 3, meta)
  timer:start(1)
end

local function do_cook_single(pos)
  local meta = minetest.get_meta(pos)
  local inv = meta:get_inventory()
  local food_uncooked = inv:get_stack("input", 1)
  if food_uncooked:is_empty() then return end
  food_uncooked:set_count(1)

  if not oven.recipes[food_uncooked:get_name()] then
    minetest.get_node_timer(pos):stop()
    update_formspec(0, 3, meta)
  else
    inv:remove_item("input", food_uncooked)
    local cooked = oven.recipes[food_uncooked:get_name()]
    inv:add_item("output", cooked)
  end
end

-- safe inventory-drops helper (works w/ or w/o MTG's default lib)
local function add_inv_drops_safe(pos, listname, drops)
  local meta = minetest.get_meta(pos)
  if not meta then return end
  local inv = meta:get_inventory()
  if not inv or not inv:get_list(listname) then return end
  for i, stack in ipairs(inv:get_list(listname)) do
    if not stack:is_empty() then
      table.insert(drops, stack:to_string())
    end
  end
end

minetest.register_node("ma_pops_furniture:oven", {
  description = "Oven",
  tiles = {
    "mp_oven_top.png",
    "mp_oven_bottom.png",
    "mp_oven_right.png",
    "mp_oven_left.png",
    "mp_oven_back.png",
    "mp_oven_front.png"
  },
  paramtype2 = "facedir",
  groups = {cracky = 2, tubedevice = 1, tubedevice_receiver = 1},
  legacy_facedir_simple = true,
  is_ground_content = false,
  sounds = S("STONE", moditems.STONE_SOUNDS),
  drawtype = "nodebox",
  node_box = {
    type = "fixed",
    fixed = {
      {-0.5, 0.3125, -0.5, 0.5, 0.5, 0.5},
      {-0.5, -0.5, -0.375, 0.5, 0.3125, 0.5},
      {-0.4375, -0.4375, -0.4375, 0.4375, 0.25, -0.375},
      {-0.375, 0.125, -0.5, 0.375, 0.1875, -0.375},
    },
  },

  can_dig = function(pos, player)
    local meta = minetest.get_meta(pos)
    local inv = meta and meta:get_inventory()
    return inv and inv:is_empty("input") and inv:is_empty("output")
  end,

  on_timer = function(pos, elapsed)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local stack = inv:get_stack("input", 1)
    local cooking_time = meta:get_int("cooking_time") or 0
    cooking_time = cooking_time + 1

    if cooking_time % 3 == 0 then
      do_cook_single(pos)
    end

    update_formspec(cooking_time % 3, 3, meta)
    meta:set_int("cooking_time", cooking_time)

    if not stack:is_empty() and oven.recipes[stack:get_name()] then
      return true
    else
      meta:set_int("cooking_time", 0)
      update_formspec(0, 3, meta)
      return false
    end
  end,

  on_metadata_inventory_put  = recalculate,
  on_metadata_inventory_take = recalculate,

  on_construct = function(pos)
    local meta = minetest.get_meta(pos)
    meta:set_string("formspec", oven_fs)
    local inv = meta:get_inventory()
    inv:set_size("input", 1)
    inv:set_size("output", 1)
  end,

  on_blast = function(pos)
    local drops = {}
    -- prefer MTG helper if available
    if default and default.get_inventory_drops then
      default.get_inventory_drops(pos, "input", drops)
      default.get_inventory_drops(pos, "output", drops)
    else
      add_inv_drops_safe(pos, "input", drops)
      add_inv_drops_safe(pos, "output", drops)
    end
    table.insert(drops, "ma_pops_furniture:oven")
    minetest.remove_node(pos)
    return drops
  end,

  allow_metadata_inventory_put = function(pos, list, index, stack, player)
    return oven.recipes[stack:get_name()] and stack:get_count() or 0
  end,
})

-- ===========================
-- Recipe Registration (compat)
-- ===========================
-- use compat item keys if provided; otherwise register sensible defaults.
local ICE          = M("ICE_ITEM",          "default:ice")               -- Mineclonia: "mcl_core:ice"
local WATER_SRC    = M("WATER_SOURCE_ITEM", "default:water_source")      -- Mineclonia often lacks source items; harmless if absent
local RAW_CHICKEN  = M("MEAT_CHICKEN_RAW",  "mobs_mc:chicken_raw")
local COOK_CHICKEN = M("MEAT_CHICKEN_COOK", "test:chicken_cooked")
local RAW_BEEF     = M("MEAT_BEEF_RAW",     "mobs_mc:beef_raw")
local COOK_BEEF    = M("MEAT_BEEF_COOK",    "test:beef_cooked")
local COFFEE_CUP   = M("COFFEE_CUP",        "farming:coffee_cup")
local COFFEE_HOT   = M("COFFEE_CUP_HOT",    "farming:coffee_cup_hot")

-- Register only if target items exist or we assume MTG fallback:
local function reg_if_known(inp, outp)
  if minetest.registered_items[inp] and (minetest.registered_items[outp] or outp:find("%s")) then
    oven.register_recipe(inp, outp)
  else
    -- still register; harmless if the input never appears
    oven.register_recipe(inp, outp)
  end
end

reg_if_known(ICE, WATER_SRC)
reg_if_known(RAW_CHICKEN, COOK_CHICKEN)
reg_if_known(RAW_BEEF, COOK_BEEF)
reg_if_known(COFFEE_CUP, COFFEE_HOT)
-- add more via oven.register_recipe("<input>", "<output>")
