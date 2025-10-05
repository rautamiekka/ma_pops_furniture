-- Fireplace ABM (Minetest Game + Mineclonia compatible)
minetest.register_abm({
  nodenames = { "ma_pops_furniture:fireplace", "ma_pops_furniture:fireplace_on" },
  interval = 1.0,
  chance   = 1,
  action = function(pos, node)
    local meta = minetest.get_meta(pos)
    local inv  = meta:get_inventory()

    -- Ensure numeric meta defaults
    if meta:get_string("fuel_totaltime") == "" then meta:set_float("fuel_totaltime", 0.0) end
    if meta:get_string("fuel_time")      == "" then meta:set_float("fuel_time",      0.0) end

    local fuel_time  = meta:get_float("fuel_time")
    local fuel_total = meta:get_float("fuel_totaltime")

    -- Still burning?
    if fuel_total > 0 and fuel_time < fuel_total then
      fuel_time = fuel_time + 0.25
      meta:set_float("fuel_time", fuel_time)

      local percent = math.floor((fuel_time / fuel_total) * 100)
      meta:set_string("infotext", "Fireplace active: " .. percent .. "%")

      if node.name ~= "ma_pops_furniture:fireplace_on" then
        minetest.swap_node(pos, { name = "ma_pops_furniture:fireplace_on", param2 = node.param2 })
      end

      -- Keep your existing formspec
      if ma_pops_furniture and ma_pops_furniture.fireplace_formspec then
        meta:set_string("formspec", ma_pops_furniture.fireplace_formspec)
      end

      -- Gentle fire sound (works in both games if the sound exists)
      minetest.sound_play("fire_small", {
        pos = pos,
        gain = 0.07,
        max_hear_distance = 8,
      }, true)

      return
    end

    -- Not burning or ran out: try to fetch new fuel
    local fuel = { time = 0 }
    local fuellist = inv and inv:get_list("fuel")

    if fuellist and #fuellist > 0 then
      -- Works in Minetest Game and Mineclonia as long as fuels are registered
      local result = minetest.get_craft_result({ method = "fuel", width = 1, items = fuellist })
      if result and result.time then
        fuel.time = result.time
      end
    end

    -- No (valid) fuel present
    if (fuel.time or 0) <= 0 then
      if node.name == "ma_pops_furniture:fireplace_on" then
        meta:set_string("infotext", "Put more wood in the fireplace!")
        minetest.swap_node(pos, { name = "ma_pops_furniture:fireplace", param2 = node.param2 })
        if ma_pops_furniture and ma_pops_furniture.fireplace_formspec then
          meta:set_string("formspec", ma_pops_furniture.fireplace_formspec)
        end
        -- Optional cooldown timer (as in your original)
        minetest.get_node_timer(pos):start(190)
      end
      return
    end

    -- Start new burn
    meta:set_float("fuel_totaltime", fuel.time)
    meta:set_float("fuel_time", 0.0)

    local stack = inv:get_stack("fuel", 1)
    stack:take_item(1)
    inv:set_stack("fuel", 1, stack)
  end,
})
