-- BoyGame (compat-ready)

local tex      = (ma_pops_furniture and ma_pops_furniture.tex) or function(t) return t end
local moditems = (ma_pops_furniture and ma_pops_furniture.moditems) or {}

minetest.register_node("ma_pops_furniture:boy_game", {
    description = "BoyGame",
    drawtype    = "nodebox",
    paramtype   = "light",
    paramtype2  = "facedir",
    groups      = {choppy = 1, oddly_breakable_by_hand = 1, furniture = 1},
    sounds      = moditems.STONE_SOUNDS,

    tiles = {
        tex("default_silver_sandstone.png") .. "^mp_boygame.png",
        tex("default_silver_sandstone.png") .. "^mp_boygame_back.png^[transformR180]",
        tex("default_silver_sandstone.png") .. "^mp_boygame_right.png",
        tex("default_silver_sandstone.png") .. "^mp_boygame_left.png",
        tex("default_silver_sandstone.png") .. "^mp_boygame_top.png",
        tex("default_silver_sandstone.png") .. "^mp_boygame_front.png",
    },

    node_box = {
        type  = "fixed",
        fixed = {
            {-0.3125, -0.5, -0.4375, 0.3125, -0.3125, 0.4375},
        }
    }
})
