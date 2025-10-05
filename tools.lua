local USES = 200 -- how many times you can use the tool before it breaks
local creative_enabled = minetest.settings:get_bool("creative_mode")

-- helper: apply tool wear unless in creative
local function apply_wear(stack)
    if not creative_enabled then
        stack:add_wear(65535 / (USES - 1))
    end
    return stack
end

-- ===== Hammer =====
-- Cycles sofa variants in this order:
--   sofa_<color> -> sofa_r_<color> -> sofa_m_<color> -> sofa_l_<color> -> sofa_c_<color> -> sofa_<color>
-- Works for any <color> in your registry.
minetest.register_tool("ma_pops_furniture:hammer", {
    description = "Hammer",
    inventory_image = "mp_hammer.png",

    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type ~= "node" then return end

        local pos  = pointed_thing.under
        local node = minetest.get_node(pos)
        local name = node.name or ""

        -- Patterns to detect variant + color
        -- Try most specific first to avoid partial matches
        local prefix = "ma_pops_furniture:"
        local fdir   = node.param2 or 0

        -- Detect which sofa we hit and its color
        local variant, color

        -- r/m/l/c variants
        variant, color = name:match("^ma_pops_furniture:sofa_(r)_(.+)$")
        if not color then variant, color = name:match("^ma_pops_furniture:sofa_(m)_(.+)$") end
        if not color then variant, color = name:match("^ma_pops_furniture:sofa_(l)_(.+)$") end
        if not color then variant, color = name:match("^ma_pops_furniture:sofa_(c)_(.+)$") end
        -- plain variant
        if not color then color = name:match("^ma_pops_furniture:sofa_(.+)$") end

        if color then
            -- compute next name in cycle
            local next_name
            if variant == "r" then
                next_name = prefix .. "sofa_m_" .. color
            elseif variant == "m" then
                next_name = prefix .. "sofa_l_" .. color
            elseif variant == "l" then
                next_name = prefix .. "sofa_c_" .. color
            elseif variant == "c" then
                next_name = prefix .. "sofa_" .. color
            else
                next_name = prefix .. "sofa_r_" .. color
            end

            if minetest.registered_nodes[next_name] then
                minetest.swap_node(pos, { name = next_name, param2 = fdir })
            end

            return apply_wear(itemstack)
        end

        -- not a sofa node → no action/ no wear
        return itemstack
    end,

    -- Rotate facedir (right-click with tool in hand)
    on_place = function(itemstack, user, pointed_thing)
        if pointed_thing.type ~= "node" then return end

        local pos  = pointed_thing.under
        local nd   = minetest.get_node(pos)
        local para = nd.param2 or 0
        local next_para = (para + 1) % 4

        minetest.swap_node(pos, { name = nd.name, param2 = next_para })
        return apply_wear(itemstack)
    end,
})

-- ===== Shears =====
-- Toggles hedge blocks between base and _full forms for the hedges
-- registered by ma_pops_furniture.register_hedge in your misc.lua earlier.
local HEDGE_BASES = {
    "ma_pops_furniture:apple_hedge",
    "ma_pops_furniture:jungle_hedge",
    "ma_pops_furniture:pine_hedge",
    "ma_pops_furniture:acacia_hedge",
    "ma_pops_furniture:aspen_hedge",
}

-- build a quick lookup for fast checks
local hedge_lookup = {}
for _, base in ipairs(HEDGE_BASES) do
    hedge_lookup[base] = true
    hedge_lookup[base .. "_full"] = true
end

minetest.register_tool("ma_pops_furniture:shears", {
    description = "Shears",
    inventory_image  = "mp_shears.png",

    on_use = function(itemstack, user, pointed_thing)
        if pointed_thing.type ~= "node" then return end

        local pos  = pointed_thing.under
        local node = minetest.get_node(pos)
        local name = node.name or ""
        local fdir = node.param2 or 0

        if not hedge_lookup[name] then
            -- not a known hedge → no action/no wear
            return itemstack
        end

        local next_name
        if name:sub(-5) == "_full" then
            next_name = name:sub(1, -6) -- strip "_full"
        else
            next_name = name .. "_full"
        end

        if minetest.registered_nodes[next_name] then
            minetest.swap_node(pos, { name = next_name, param2 = fdir })
        end

        return apply_wear(itemstack)
    end,

    -- Rotate facedir (right-click with tool in hand)
    on_place = function(itemstack, user, pointed_thing)
        if pointed_thing.type ~= "node" then return end

        local pos  = pointed_thing.under
        local nd   = minetest.get_node(pos)
        local para = nd.param2 or 0
        local next_para = (para + 1) % 4

        minetest.swap_node(pos, { name = nd.name, param2 = next_para })
        return apply_wear(itemstack)
    end,
})
