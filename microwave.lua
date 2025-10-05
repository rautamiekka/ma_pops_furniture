-- microwave.lua (compat-ready)
-- Original: Wizzerine (microwave), Noodlemire (item_percent)
-- This rewrite removes MTG-only deps and adds cross-game recipe registration.

-- ===== Formspeс =====

local MW_BG = (moditems.BOXART or "") -- compat bg string (may be empty)

local microwave_fs =
    "size[9,9.5]" ..
    MW_BG ..
    "background[0,0;9,4.5;mp_microwave_GUI.png]" ..
    "image_button[6.88,3.45;.85,.84;mp_microwave_start.png;btn_start;start]" ..
    "image[7.05,.05;2,.4;mp_mw_bar.png^[transformR270]" ..
    "list[current_player;main;.5,5;8,1;]" ..
    "list[current_player;main;.5,6.5;8,3;8]" ..
    "list[context;cook_slot;3.3,3;1,1;]" ..
    "label[1.5,0.4;Microwave]"

local function get_active_microwave_fs(item_percent)
    return "size[9,9.5]" ..
        MW_BG ..
        "background[0,0;9,4.5;mp_microwave_GUI.png]" ..
        "image_button[6.88,3.45;.85,.84;mp_microwave_start.png;btn_start;start]" ..
        "image[7.05,.05;2,.4;mp_mw_bar.png^[lowpart:" .. item_percent .. ":mp_mw_bar_on.png^[transformR270]" ..
        "list[current_player;main;.5,5;8,1;]" ..
        "list[current_player;main;.5,6.5;8,3;8]" ..
        "list[context;cook_slot;3.3,3;1,1;]" ..
        "label[1.5,0.4;Microwave]"
end

-- ===== Simple recipe API =====

ma_pops_furniture.microwave = ma_pops_furniture.microwave or {}
local microwave = ma_pops_furniture.microwave
microwave.recipes = microwave.recipes or {}

function microwave.register_recipe(input, output)
    microwave.recipes[input] = output
end

-- ===== Helpers =====

local function update_formspec(progress, goal, meta)
    local formspec
    if progress > 0 and progress <= goal then
        local item_percent = math.floor(progress / goal * 100)
        formspec = get_active_microwave_fs(item_percent)
    else
        formspec = microwave_fs
    end
    meta:set_string("formspec", formspec)
end

local function recalculate(pos)
    local meta  = minetest.get_meta(pos)
    local timer = minetest.get_node_timer(pos)
    local inv   = meta:get_inventory()
    local stack = inv:get_stack("cook_slot", 1)
    local goal  = 3 * stack:get_count()

    local out = microwave.recipes[stack:get_name()]
    if not out then return end

    timer:stop()
    update_formspec(0, goal, meta)
    timer:start(1)
end

local function do_cook_all(pos)
    local meta = minetest.get_meta(pos)
    local inv  = meta:get_inventory()
    local stack = inv:get_stack("cook_slot", 1)

    if stack:is_empty() then return end

    local in_name  = stack:get_name()
    local out_name = microwave.recipes[in_name]
    if not out_name then return end

    local count = stack:get_count()
    inv:set_stack("cook_slot", 1, ItemStack(out_name .. " " .. count))
end

-- ===== Node =====

minetest.register_node("ma_pops_furniture:microwave", {
    description = "Microwave",
    tiles = {"mp_mw_top.png", "mp_mw_bottom.png", "mp_mw_right.png", "mp_mw_left.png", "mp_mw_back.png", "mp_mw_front.png"},
    drawtype   = "nodebox",
    paramtype  = "light",
    paramtype2 = "facedir",
    groups     = { cracky = 2, furniture = 1 },
    sounds     = moditems.STONE_SOUNDS,
	node_box = {
		type = "fixed",
		fixed = {
			{-0.4375, -0.4375, -0.3125, 0.4375, 0.0625, 0.3125},
			{-0.375, -0.5, -0.25, 0.375, -0.4375, 0.25},
		},
	},

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("formspec", microwave_fs)
        meta:set_int("cooking_time", 0)
        local inv = meta:get_inventory()
        inv:set_size("cook_slot", 1)
    end,

    can_dig = function(pos, player)
        local inv = minetest.get_meta(pos):get_inventory()
        return inv:is_empty("cook_slot")
    end,

    on_receive_fields = function(pos, _, fields, sender)
        if fields.quit then return end
        if fields.btn_start then
            recalculate(pos)
        end
    end,

    on_timer = function(pos, elapsed)
        local meta  = minetest.get_meta(pos)
        local inv   = meta:get_inventory()
        local stack = inv:get_stack("cook_slot", 1)

        -- nothing to cook / invalid input
        if stack:is_empty() or not microwave.recipes[stack:get_name()] then
            meta:set_int("cooking_time", 0)
            update_formspec(0, 0, meta)
            return false
        end

        local goal = 3 * stack:get_count()
        local t    = meta:get_int("cooking_time") + 1
        meta:set_int("cooking_time", t)
        update_formspec(t, goal, meta)

        if t <= goal then
            return true -- keep cooking
        else
            do_cook_all(pos)
            meta:set_int("cooking_time", 0)
            update_formspec(0, goal, meta)
            return false
        end
    end,

    -- No MTG dependency here; just collect the slot manually.
    on_blast = function(pos)
        local drops = { "ma_pops_furniture:microwave" }
        local inv = minetest.get_meta(pos):get_inventory()
        local stack = inv:get_stack("cook_slot", 1)
        if not stack:is_empty() then
            table.insert(drops, stack:to_string())
        end
        minetest.remove_node(pos)
        return drops
    end,

    -- Only allow items that have a recipe
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        return microwave.recipes[stack:get_name()] and stack:get_count() or 0
    end,

    -- Lock the slot while cooking
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        return minetest.get_node_timer(pos):is_started() and 0 or stack:get_count()
    end,
})

-- ===== Compat-tolerant recipe registration =====

-- helper: only register recipes for items that actually exist in the running game
local function try_register_pairs(pairs)
    for _, pair in ipairs(pairs) do
        local input, output = pair[0] or pair[1], pair[2]
        -- (Lua arrays are 1-indexed; keeping readable tuple style)
    end
end

local function reg_if_exists(input, output)
    if minetest.registered_items[input] and minetest.registered_items[output] then
        microwave.register_recipe(input, output)
    end
end

-- Common/neutral things
reg_if_exists("default:ice",           "default:water_source")
reg_if_exists("farming:coffee_cup",    "farming:coffee_cup_hot")
reg_if_exists("farming:corn",          "farming:corn_cob")

-- MineClone(-like) names (if present)
reg_if_exists("mcl_mobitems:chicken",      "mcl_mobitems:cooked_chicken")
reg_if_exists("mcl_mobitems:beef",         "mcl_mobitems:steak")
reg_if_exists("mcl_farming:beetroot_soup", "mcl_farming:beetroot_soup") -- example: no-op if you want warm soups later

-- MineTest Game / Mobs Redo names (if present)
reg_if_exists("mobs:meat_raw",         "mobs:meat")
reg_if_exists("mobs:chicken_raw",      "mobs:chicken_cooked")
reg_if_exists("mobs:beef_raw",         "mobs:beef_cooked")
reg_if_exists("mobs_mc:chicken_raw",   "mobs_mc:chicken_cooked")
reg_if_exists("mobs_mc:beef_raw",      "mobs_mc:beef_cooked")

-- Tip: Any other mod can add recipes at load time:
--   ma_pops_furniture.microwave.register_recipe("some:raw", "some:cooked")
