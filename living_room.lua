-- Fireplace (off)
minetest.register_node("ma_pops_furniture:fireplace", {
    description = "Fireplace",
    drawtype = "mesh",
    mesh = "FM_fireplace_off.obj",
    tiles = {
        { name = "default_brick.png" },
        { name = "xpanes_bar.png" },
    },
    groups = { cracky = 2, oddly_breakable_by_hand = 6, furniture = 1 },
    paramtype = "light",
    paramtype2 = "facedir",
    sounds = moditems.STONE_SOUNDS,
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv  = meta:get_inventory()
        inv:set_size("fuel", 1)
        inv:set_size("main", 8 * 4)
        meta:set_string("formspec", ma_pops_furniture.fireplace_formspec)
        meta:set_string("infotext", "Fireplace")
    end,
    can_dig = function(pos, player)
        local inv = minetest.get_meta(pos):get_inventory()
        return inv:is_empty("fuel")
    end,
})

-- Fireplace (on)
minetest.register_node("ma_pops_furniture:fireplace_on", {
    description = "Fireplace",
    drawtype = "mesh",
    mesh = "FM_fireplace_on.obj",
    tiles = {
        { name = "default_brick.png" },
        { name = "xpanes_bar.png" },
        { name = "default_tree.png" },
        { name = "fire_basic_flame_animated.png",
          animation = { type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 1 } },
    },
    groups = { cracky = 2, oddly_breakable_by_hand = 3, furniture = 1, not_in_creative_inventory = 1 },
    light_source = 14,
    paramtype = "light",
    paramtype2 = "facedir",
    drops = "ma_pops_furniture:fireplace",
    sounds = moditems.STONE_SOUNDS,
    can_dig = function(pos, player)
        local inv = minetest.get_meta(pos):get_inventory()
        return inv:is_empty("fuel")
    end,
})

-----------------------------------------------------------------------
-- Coffee tables / End tables (materials use your mod textures)
-----------------------------------------------------------------------
local c_table = {
    { "Stone Coffee Table",  "cobble"     },
    { "Wood Coffee Table",   "wood"       },
    { "Acacia Wood Coffee Table", "acacia_wood" },
    { "Aspen Wood Coffee Table",  "aspen_wood"  },
    { "Pine Wood Coffee Table",   "pine_wood"   },
    { "Jungle Wood Coffee Table", "junglewood"  },
}

for _, def in ipairs(c_table) do
    local name, material = def[1], def[2]

    minetest.register_node("ma_pops_furniture:c_" .. material, {
        description = name,
        drawtype    = "nodebox",
        tiles       = { "default_" .. material .. ".png" },
        groups      = { choppy = 2, oddly_breakable_by_hand = 2, furniture = 1, flammable = 1 },
        paramtype   = "light",
        paramtype2  = "facedir",
        sounds      = moditems.WOOD_SOUNDS,
        -- convert to end table if the player right-clicks while holding the same table node
        on_rightclick = function(pos, node, player, itemstack, pointed_thing)
            if itemstack and itemstack:get_name() == "ma_pops_furniture:c_" .. material then
                node.name = "ma_pops_furniture:end_table_" .. material
                minetest.set_node(pos, node)
            end
        end,
        node_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, -0.4,  0.0, -0.4},
                {-0.5, -0.5,  0.5, -0.4,  0.0,  0.4},
                { 0.5, -0.5, -0.5,  0.4,  0.0, -0.4},
                { 0.5, -0.5,  0.5,  0.4,  0.0,  0.4},
                { 0.5,  0.1,  0.5, -0.5,  0.0, -0.5},
                { 0.5, -0.3,  0.5, -0.5, -0.4, -0.5},
            },
        },
    })
end

local end_table = {
    { "Stone End Table",  "cobble"     },
    { "Wood End Table",   "wood"       },
    { "Acacia Wood End Table", "acacia_wood" },
    { "Aspen Wood End Table",  "aspen_wood"  },
    { "Pine Wood End Table",   "pine_wood"   },
    { "Jungle Wood End Table", "junglewood"  },
}

for _, def in ipairs(end_table) do
    local name, material = def[1], def[2]

    minetest.register_node("ma_pops_furniture:end_table_" .. material, {
        description = name,
        drawtype    = "nodebox",
        tiles       = { "default_" .. material .. ".png" },
        groups      = { choppy = 2, oddly_breakable_by_hand = 2, furniture = 1, flammable = 1 },
        paramtype   = "light",
        paramtype2  = "facedir",
        sounds      = moditems.WOOD_SOUNDS,
        node_box = {
            type = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, -0.4,  0.5, -0.4},
                {-0.5, -0.5,  0.5, -0.4,  0.5,  0.4},
                { 0.5, -0.5, -0.5,  0.4,  0.5, -0.4},
                { 0.5, -0.5,  0.5,  0.4,  0.5,  0.4},
                { 0.5,  0.4,  0.5, -0.5,  0.5, -0.5},
                { 0.5, -0.3,  0.5, -0.5, -0.2, -0.5},
            },
        },
    })
end

-----------------------------------------------------------------------
-- Entertainment units
-----------------------------------------------------------------------
local unit_table = {
    { "Wood Entertainment Unit",        "wood"       },
    { "Acacia Wood Entertainment Unit", "acacia_wood"},
    { "Aspen Wood Entertainment Unit",  "aspen_wood" },
    { "Pine Wood Entertainment Unit",   "pine_wood"  },
    { "Jungle Wood Entertainment Unit", "junglewood" },
}

for _, def in ipairs(unit_table) do
    local name, material = def[1], def[2]

    minetest.register_node("ma_pops_furniture:e_u_" .. material, {
        description = name,
        tiles       = { "default_" .. material .. ".png" },
        drawtype    = "nodebox",
        paramtype   = "light",
        paramtype2  = "facedir",
        sounds      = moditems.WOOD_SOUNDS,
        groups      = { choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, furniture = 1 },
        on_construct = function(pos)
            local meta = minetest.get_meta(pos)
            local inv  = meta:get_inventory()
            inv:set_size("main", 8 * 4)
            inv:set_size("storage", 3 * 3)
            meta:set_string("formspec",
                "size[9,10]" ..
                (moditems.FS_BG or "") ..
                "list[current_name;storage;3,1.5;3,3;]" ..
                "list[current_player;main;0.5,6.5;8,4;]"
            )
        end,
        can_dig = function(pos, player)
            local inv = minetest.get_meta(pos):get_inventory()
            return inv:is_empty("storage") and inv:is_empty("storage1")
        end,
        node_box = {
            type  = "fixed",
            fixed = {
                {-0.5, -0.5, -0.5, -0.4,  0.5,  0.5},
                { 0.5, -0.5, -0.5,  0.4,  0.5,  0.5},
                {-0.5,  0.4, -0.5,  0.5,  0.5,  0.5},
                {-0.5, -0.05, -0.5,  0.5,  0.05,  0.5},
                {-0.5, -0.5,  0.5,  0.5,  0.5,  0.4},
            },
        },
    })
end

-----------------------------------------------------------------------
-- VCR
-----------------------------------------------------------------------
minetest.register_node("ma_pops_furniture:vcr_on", {
    description = "VCR",
    tiles = {
        "default_coal_block.png",
        "default_coal_block.png",
        "default_coal_block.png",
        "default_coal_block.png",
        "default_coal_block.png",
        "default_coal_block.png^mp_vcr_on.png",
    },
    drawtype   = "nodebox",
    paramtype  = "light",
    paramtype2 = "facedir",
    drop       = "ma_pops_furniture:vcr_off",
    sounds     = moditems.WOOD_SOUNDS,
    groups     = { choppy = 2, oddly_breakable_by_hand = 2, not_in_creative_inventory = 1, furniture = 1 },
    node_box   = {
        type  = "fixed",
        fixed = {
            {-0.375, -0.5,  -0.25,  0.375, -0.4375, 0.25},
            {-0.4375, -0.4375, -0.3125, 0.4375, -0.25, 0.3125},
        },
    },
    on_rightclick = function(pos, node, puncher)
        node.name = "ma_pops_furniture:vcr_off"
        minetest.set_node(pos, node)
    end,
})

minetest.register_node("ma_pops_furniture:vcr_off", {
    description = "VCR",
    tiles = {
        "default_coal_block.png",
        "default_coal_block.png",
        "default_coal_block.png",
        "default_coal_block.png",
        "default_coal_block.png",
        "default_coal_block.png^mp_vcr_off.png",
    },
    drawtype   = "nodebox",
    paramtype  = "light",
    paramtype2 = "facedir",
    drop       = "ma_pops_furniture:vcr_off",
    sounds     = moditems.WOOD_SOUNDS,
    groups     = { choppy = 2, oddly_breakable_by_hand = 2, furniture = 1 },
    node_box   = {
        type  = "fixed",
        fixed = {
            {-0.375, -0.5,  -0.25,  0.375, -0.4375, 0.25},
            {-0.4375, -0.4375, -0.3125, 0.4375, -0.25, 0.3125},
        },
    },
    on_rightclick = function(pos, node, puncher)
        node.name = "ma_pops_furniture:vcr_on"
        minetest.set_node(pos, node)
    end,
})

-----------------------------------------------------------------------
-- Chair2 + Footstool (compat-aware dye recolor)
-----------------------------------------------------------------------
local COLOR_LIST = {
    "black","blue","brown","cyan","dark_green","dark_grey",
    "green","grey","magenta","orange","pink","red","violet","white","yellow"
}

-- helper: recolor node based on wielded dye (uses compat dye resolver)
local function recolor_with_dye(pos, node, player, basename)
    local wield = player and player:get_wielded_item()
    if not (wield and not wield:is_empty()) then return end
    local wield_name = wield:get_name()
    for _, c in ipairs(COLOR_LIST) do
        local dye_name = moditems.dye and moditems.dye(c)
        if dye_name and wield_name == dye_name then
            node.name = basename .. c
            minetest.set_node(pos, node)
            return true
        end
    end
    return false
end

-- Chair2
for _, color in ipairs(COLOR_LIST) do
    -- original mask overlays
    local cb = "^([combine:16x16:0,0=mp_cb.png^[mask:mp_mask.png)"
    local cf = "^([combine:16x16:0,0=mp_cf.png^[mask:mp_mask.png)"

    minetest.register_node("ma_pops_furniture:chair2_" .. color, {
        description = (color:gsub("^%l", string.upper):gsub("_(%l)", function(a) return " "..a:upper() end)) .. " Chair",
        tiles = {
            "wool_" .. color .. ".png",
            "wool_" .. color .. ".png" .. cb,
            "wool_" .. color .. ".png" .. cf,
            "wool_" .. color .. ".png" .. cf,
            "wool_" .. color .. ".png" .. cf,
            "wool_" .. color .. ".png" .. cf,
        },
        drawtype   = "nodebox",
        paramtype  = "light",
        paramtype2 = "facedir",
        groups     = { choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, furniture = 1, fall_damage_add_percent = -80, bouncy = 80 },
        sounds     = moditems.WOOD_SOUNDS or { wood = { name = "furn_bouncy", gain = 0.8 } },
        can_dig    = ma_pops_furniture.sit_dig,
        on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
            -- try recolor first; if not holding dye, treat as sit
            if not recolor_with_dye(pos, node, clicker, "ma_pops_furniture:chair2_") then
                ma_pops_furniture.sit(pos, node, clicker, pointed_thing)
            end
            return itemstack
        end,
        on_punch = function(pos, node, clicker)
            recolor_with_dye(pos, node, clicker, "ma_pops_furniture:chair2_")
        end,
        node_box = {
            type  = "fixed",
            fixed = {
                {-0.4, -0.5, -0.4, -0.3, -0.4, -0.3},
                {-0.4, -0.5,  0.4, -0.3, -0.4,  0.3},
                { 0.4, -0.5,  0.4,  0.3, -0.4,  0.3},
                { 0.4, -0.5, -0.4,  0.3, -0.4, -0.3},
                {-0.450, -0.4, -0.450, 0.450, 0.1, 0.450},
                {-0.5,    0.1, -0.5,  -0.3,  0.3, 0.0},
                { 0.5,    0.1, -0.5,   0.3,  0.3, 0.0},
                { 0.450,  0.1,  0.0,  -0.450, 0.5, 0.450},
            },
        },
    })
end

-- Footstools
for _, color in ipairs(COLOR_LIST) do
    minetest.register_node("ma_pops_furniture:fs_" .. color, {
        description = (color:gsub("^%l", string.upper):gsub("_(%l)", function(a) return " "..a:upper() end)) .. " Footstool",
        tiles = {
            "wool_" .. color .. ".png",
            "wool_" .. color .. ".png^mp_cb.png",
            "wool_" .. color .. ".png^mp_cf.png",
            "wool_" .. color .. ".png^mp_cf.png",
            "wool_" .. color .. ".png^mp_cf.png",
            "wool_" .. color .. ".png^mp_cf.png",
        },
        drawtype   = "nodebox",
        paramtype  = "light",
        groups     = { choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, furniture = 1 },
        sounds     = moditems.WOOD_SOUNDS,
        on_punch = function(pos, node, clicker)
            recolor_with_dye(pos, node, clicker, "ma_pops_furniture:fs_")
        end,
        node_box = {
            type  = "fixed",
            fixed = {
                {-0.4, -0.5, -0.4, -0.3, -0.4, -0.3},
                {-0.4, -0.5,  0.4, -0.3, -0.4,  0.3},
                { 0.4, -0.5,  0.4,  0.3, -0.4,  0.3},
                { 0.4, -0.5, -0.4,  0.3, -0.4, -0.3},
                {-0.450, -0.4, -0.450, 0.450, -0.1, 0.450},
            },
        },
    })
end
