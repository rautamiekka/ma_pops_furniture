local S = ma_pops_furniture.intllib

-- Toaster (empty)
minetest.register_node("ma_pops_furniture:toaster", {
    description = S("Toaster"),
    tiles = {
        "mp_toas_top.png",
        "mp_toas_bottom.png",
        "mp_toas_right.png",
        "mp_toas_left.png",
        "mp_toas_back.png",
        "mp_toas_front.png"
    },
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    walkable = false,
    is_ground_content = false,
    groups = { snappy = 3, furniture = 1 },
    sounds = moditems.STONE_SOUNDS,
    node_box = {
        type = "fixed",
        fixed = {
            {-0.375, -0.5,     0.0,   0.375, -0.0625, 0.3125},
            {-0.4375, -0.1875, 0.0625,-0.375, -0.125, 0.25},
        },
    },
})

-- Use bread slice on a toaster to insert it (needs 2 slices)
local function breadslice_on_use(itemstack, user, pointed_thing)
    if not user or not pointed_thing or not pointed_thing.under then
        return minetest.do_item_eat(2, nil, itemstack, user, pointed_thing)
    end

    local pos  = pointed_thing.under
    local node = minetest.get_node(pos)
    local pname = user:get_player_name() or ""

    if node and node.name == "ma_pops_furniture:toaster" then
        if minetest.is_protected(pos, pname) then
            minetest.record_protection_violation(pos, pname)
            return itemstack
        end
        if itemstack:get_count() >= 2 then
            local fdir = node.param2 or 0
            itemstack:take_item(2)
            minetest.swap_node(pos, { name = "ma_pops_furniture:toaster_with_breadslice", param2 = fdir })
            return itemstack
        end
        -- not enough slices → eat instead
        return minetest.do_item_eat(2, nil, itemstack, user, pointed_thing)
    end

    -- not clicking toaster → eat it
    return minetest.do_item_eat(2, nil, itemstack, user, pointed_thing)
end

-- Reuse Farming’s bread slice if available; otherwise register ours
if minetest.registered_items["farming:bread_slice"] then
    minetest.override_item("farming:bread_slice", { on_use = breadslice_on_use })
    minetest.register_alias("ma_pops_furniture:breadslice", "farming:bread_slice")
else
    minetest.register_craftitem("ma_pops_furniture:breadslice", {
        description = S("Slice of Bread"),
        inventory_image = "mp_breadslice.png",
        groups = { flammable = 2 },
        on_use = breadslice_on_use,
    })
end

-- Reuse Farming’s toast if available; otherwise register ours
if minetest.registered_items["farming:toast"] then
    minetest.register_alias("ma_pops_furniture:toast", "farming:toast")
else
    minetest.register_craftitem("ma_pops_furniture:toast", {
        description = S("Toast"),
        inventory_image = "mp_toast.png",
        groups = { flammable = 2 },
        on_use = minetest.item_eat(3),
    })
end

-- Toaster with raw bread inserted
minetest.register_node("ma_pops_furniture:toaster_with_breadslice", {
    description = S("Toaster with Breadslice"),
    tiles = {
        "mp_toas_top_bread.png",
        "mp_toas_bottom.png",
        "mp_toas_right_bread.png",
        "mp_toas_left_bread.png",
        "mp_toas_back_bread.png",
        "mp_toas_front_bread.png"
    },
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    walkable = false,
    is_ground_content = false,
    diggable = false, -- must toast first
    groups = { not_in_creative_inventory = 1, furniture = 1 },
    sounds = moditems.STONE_SOUNDS,
    node_box = {
        type = "fixed",
        fixed = {
            {-0.375, -0.5,    0.0,    0.375, -0.0625, 0.3125},
            {-0.25,  -0.0625, 0.0625, 0.25,   0.0625, 0.125},
            {-0.25,  -0.0625, 0.1875, 0.25,   0.0625, 0.25},
            {-0.4375,-0.1875, 0.0625,-0.375, -0.125, 0.25},
        },
    },
    on_punch = function(pos, node, clicker, itemstack, pointed_thing)
        local fdir = node.param2 or 0
        minetest.swap_node(pos, { name = "ma_pops_furniture:toaster_toasting_breadslice", param2 = fdir })

        -- finish in 6 seconds → becomes toast
        minetest.after(6, function(p)
            local n = minetest.get_node(p)
            if n and n.name == "ma_pops_furniture:toaster_toasting_breadslice" then
                minetest.swap_node(p, { name = "ma_pops_furniture:toaster_with_toast", param2 = (n.param2 or 0) })
            end
        end, pos)

        minetest.sound_play("toaster", { pos = pos, gain = 1.0, max_hear_distance = 8 })
        return itemstack
    end
})

-- Toaster actively toasting (brief animated state)
minetest.register_node("ma_pops_furniture:toaster_toasting_breadslice", {
    description = S("Toaster Toasting Slice of Bread"),
    tiles = {
        "mp_toas_top_bread_on.png",
        "mp_toas_bottom.png",
        "mp_toas_right_bread.png",
        "mp_toas_left_toast_side.png",
        "mp_toas_back_side.png",
        "mp_toas_front_side.png"
    },
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    walkable = false,
    is_ground_content = false,
    diggable = false,
    groups = { not_in_creative_inventory = 1, furniture = 1 },
    sounds = moditems.STONE_SOUNDS,
    node_box = {
        type = "fixed",
        fixed = {
            {-0.375, -0.5,   0.0,    0.375, -0.0625, 0.3125},
            {-0.4375,-0.375, 0.0625,-0.375, -0.3125, 0.25},
        },
    },
})

-- Toast is ready
minetest.register_node("ma_pops_furniture:toaster_with_toast", {
    description = S("Toaster with Toast"),
    tiles = {
        "mp_toas_top_toast.png",
        "mp_toas_bottom.png",
        "mp_toas_right_toast.png",
        "mp_toas_left_toast.png",
        "mp_toas_back_toast.png",
        "mp_toas_front_toast.png"
    },
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    walkable = false,
    is_ground_content = false,
    groups = { snappy = 3, not_in_creative_inventory = 1, furniture = 1 },
    sounds = moditems.STONE_SOUNDS,
    node_box = {
        type = "fixed",
        fixed = {
            {-0.375, -0.5,    0.0,    0.375, -0.0625, 0.3125},
            {-0.25,  -0.0625, 0.0625, 0.25,   0.0625, 0.125},
            {-0.25,  -0.0625, 0.1875, 0.25,   0.0625, 0.25},
            {-0.4375,-0.1875, 0.0625,-0.375, -0.125, 0.25},
        },
    },
    on_punch = function(pos, node, player, pointed_thing)
        local inv = player and player:get_inventory()
        if not inv then return end
        local leftover = inv:add_item("main", "ma_pops_furniture:toast 2")
        if leftover:is_empty() then
            minetest.swap_node(pos, { name = "ma_pops_furniture:toaster", param2 = (node.param2 or 0) })
        end
    end
})

-- Slice of Bread craft (only if we didn't alias to Farming’s)
if not minetest.registered_items["farming:bread_slice"] then
    minetest.register_craft({
        output = "ma_pops_furniture:breadslice 2",
        type = "shapeless",
        recipe = { "farming:bread", "ma_pops_furniture:knife" },
        replacements = { { "ma_pops_furniture:knife", "ma_pops_furniture:knife" } },
    })
end
