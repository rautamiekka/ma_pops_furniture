-- Allow other mods to extend the playlist
ma_pops_furniture.stereo_songs = ma_pops_furniture.stereo_songs or { "static" }
local songs = ma_pops_furniture.stereo_songs

minetest.register_node("ma_pops_furniture:stereo", {
    description = "Stereo",
    tiles = {
        "mp_radio_top.png",
        "mp_radio_bottom.png",
        "mp_radio_right.png",
        "mp_radio_left.png",
        "mp_radio_back.png",
        "mp_radio_front.png"
    },
    drawtype = "nodebox",
    paramtype = "light",
    paramtype2 = "facedir",
    groups = { choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, furniture = 1 },
    sounds = moditems.WOOD_SOUNDS,

    node_box = {
        type = "fixed",
        fixed = {
            {-0.5,  -0.5,   0.1875,  0.5,  -0.125, 0.5},   -- base
            {-0.25, -0.5,   0.125,   0.25, -0.0625, 0.5},  -- front panel
        }
    },

    -- Toggle playback on right-click
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        local h = meta:get_int("sound_handle") or 0

        if h > 0 then
            -- Stop current sound
            minetest.sound_stop(h)
            meta:set_int("sound_handle", 0)
        else
            -- Play a random track and remember the handle
            if #songs > 0 then
                local track = "radio_" .. songs[math.random(1, #songs)]
                local handle = minetest.sound_play(track, {
                    pos = pos,
                    gain = 0.5,
                    max_hear_distance = 25,
                    loop = true,
                })
                if handle then
                    meta:set_int("sound_handle", handle)
                end
            end
        end
    end,

    -- Ensure we stop audio when the node is removed
    on_destruct = function(pos)
        local meta = minetest.get_meta(pos)
        local h = meta:get_int("sound_handle") or 0
        if h > 0 then
            minetest.sound_stop(h)
            meta:set_int("sound_handle", 0)
        end
    end,
})
