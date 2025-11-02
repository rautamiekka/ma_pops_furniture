-- crafts.lua — MTG + Mineclonia compatible
-- Requires compat.lua providing C.register_craft_compat and item mappings.
local MODNAME = minetest.get_current_modname()
local MODPATH = minetest.get_modpath(MODNAME)
local C       = dofile(MODPATH.."/compat.lua")

-- === Basic appliances / fixtures ===
C.register_craft_compat({
  output = 'ma_pops_furniture:smoke_detector',
  recipe = {
    {'default:stone','dye:white','default:stone'},
    {'default:stone','default:copper_ingot','default:stone'},
    {'default:stone','dye:red','default:stone'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:br_tile',
  recipe = {
    {'dye:black','dye:white','dye:black'},
    {'','default:stone_block',''},
    {'dye:black','','dye:black'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:ceiling_lamp',
  recipe = {
    {'', 'default:stone', ''},
    {'default:stone', 'default:meselamp', 'default:stone'},
    {'default:stone', 'default:meselamp', 'default:stone'}
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:outdoor_lamp',
  recipe = {
    {'','',''},
    {'default:stone','default:stone','default:stone'},
    {'default:stone','default:meselamp','default:stone'},
  }
})

-- Bathroom
C.register_craft_compat({
  output = 'ma_pops_furniture:bath_faucet',
  recipe = {
    {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
    {'default:steel_ingot','','bucket:bucket_water'},
    {'default:steel_ingot','',''},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:toilet_paper_roll_dispenser',
  recipe = {
    {'default:stone','default:stone','default:stone'},
    {'default:paper','bucket:bucket_water','default:paper'},
    {'','default:paper',''},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:toilet_close',
  recipe = {
    {'','','default:steel_ingot'},
    {'default:steel_ingot','stairs:slab_wood','default:steel_ingot'},
    {'default:steel_ingot','bucket:bucket_water','default:steel_ingot'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:br_sink',
  recipe = {
    {'default:steel_ingot','','default:steel_ingot'},
    {'','default:steel_ingot',''},
    {'','default:steel_ingot',''},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:mirror_closed',
  recipe = {
    {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
    {'default:glass','default:glass','default:glass'},
    {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:shower_base',
  recipe = {
    {'','',''},
    {'','',''},
    {'default:steel_ingot','bucket:bucket_empty','default:steel_ingot'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:shower_top',
  recipe = {
    {'','default:steel_ingot',''},
    {'default:steel_ingot','bucket:bucket_water','default:steel_ingot'},
    {'default:steel_ingot','','default:steel_ingot'},
  }
})

-- Nightstands (by material)
do
  local night_table = {
    {'wood'},
    {'aspen_wood'},
    {'junglewood'},
    {'acacia_wood'},
    {'pine_wood'},
    {'cobble'}
  }
  for i = 1, #night_table do
    local material = night_table[i][1]
    C.register_craft_compat({
      output = 'ma_pops_furniture:nightstand_'..material,
      recipe = {
        {'default:'..material, 'default:'..material, 'default:'..material},
        {'default:'..material, 'default:chest', 'default:'..material},
        {'default:'..material, 'default:'..material, 'default:'..material}
      }
    })
  end
end

-- Chairs (by material)
do
  local chair = {
    {'wood'},
    {'aspen_wood'},
    {'junglewood'},
    {'acacia_wood'},
    {'pine_wood'},
    {'cobble'}
  }
  for i = 1, #chair do
    local material = chair[i][1]
    C.register_craft_compat({
      output = 'ma_pops_furniture:chair_'..material,
      recipe = {
        {'default:'..material, '', ''},
        {'default:'..material, 'default:'..material, 'default:'..material},
        {'default:'..material, '', 'default:'..material}
      }
    })
  end
end

C.register_craft_compat({
  output = 'ma_pops_furniture:barrel',
  recipe = {
    {'default:wood','default:wood','default:wood'},
    {'default:wood','default:steel_ingot','default:wood'},
    {'default:wood','default:wood','default:wood'},
  }
})

-- Dishwasher
C.register_craft_compat({
  output = 'ma_pops_furniture:dw',
  recipe = {
    {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
    {'default:steel_ingot','bucket:bucket_water','default:steel_ingot'},
    {'default:steel_ingot','default:mese_crystal','default:steel_ingot'},
  }
})

-- Oven + hood
C.register_craft_compat({
  output = 'ma_pops_furniture:oven',
  recipe = {
    {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
    {'default:steel_ingot','default:furnace','default:steel_ingot'},
    {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:oven_overhead',
  recipe = {
    {'default:steel_ingot','default:mese_crystal_fragment','default:steel_ingot'},
    {'','',''},
    {'','',''},
  }
})

-- Small appliances
C.register_craft_compat({
  output = 'ma_pops_furniture:microwave',
  recipe = {
    {'','',''},
    {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
    {'default:steel_ingot','default:furnace','default:steel_ingot'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:coffee_maker',
  recipe = {
    {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
    {'default:steel_ingot','default:copper_ingot','default:steel_ingot'},
    {'','default:glass',''},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:coffee_cup',
  recipe = {
    {'default:glass','dye:blue','default:glass'},
    {'default:glass','dye:blue','default:glass'},
    {'default:glass','default:glass','default:glass'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:toaster',
  recipe = {
    {'','',''},
    {'default:steel_ingot','default:furnace','default:steel_ingot'},
    {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:trash_can',
  recipe = {
    {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
    {'default:steel_ingot','bucket:bucket_lava','default:steel_ingot'},
    {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:kitchen_faucet',
  recipe = {
    {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
    {'default:steel_ingot','','default:steel_ingot'},
    {'default:steel_ingot','',''},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:cutting_board',
  recipe = {
    {'','',''},
    {'','',''},
    {'default:wood','default:wood',''},
  }
})

-- Colored counters (dye + wood group)
do
  local counter_table = {
    {'Black', 'black', 'black:225'},
    {'Blue', 'blue', 'blue:150'},
    {'Brown', 'brown', 'brown:100'},
    {'Cyan', 'cyan', 'cyan:150'},
    {'Dark Green', 'dark_green', 'green:200'},
    --{'Dark Grey', 'dark_grey', 'black:200'},
    {'Green', 'green', '#32cd32:150'},
    --{'Grey', 'grey', 'black:150'},
    {'Magenta', 'magenta', 'magenta:200'},
    {'Orange', 'orange', 'orange:150'},
    {'Pink', 'pink', 'pink:150'},
    {'Red', 'red', 'red:150'},
    {'Violet', 'violet', 'violet:150'},
    {'White', 'white', 'white:150'},
    {'Yellow', 'yellow', 'yellow:150'},
  }
  for i = 1, #counter_table do
    local color = counter_table[i][2]

    C.register_craft_compat({
      output = 'ma_pops_furniture:counter2_'..color,
      recipe = {
        {'group:wood','group:wood','group:wood'},
        {'group:wood','dye:'..color,'group:wood'},
        {'group:wood','group:wood','group:wood'},
      }
    })
    C.register_craft_compat({
      type = "shapeless",
      output = 'ma_pops_furniture:counter1_'..color,
      recipe = {'ma_pops_furniture:counter2_'..color}
    })
    C.register_craft_compat({
      type = "shapeless",
      output = 'ma_pops_furniture:counter3_'..color,
      recipe = {'ma_pops_furniture:counter2_'..color, "default:chest"}
    })
    C.register_craft_compat({
      type = "shapeless",
      output = 'ma_pops_furniture:counter_'..color,
      recipe = {'ma_pops_furniture:counter3_'..color}
    })
    C.register_craft_compat({
      output = 'ma_pops_furniture:upcabinet_'..color,
      recipe = {
        {'group:wood','dye:'..color,'group:wood'},
        {'group:wood','default:chest','group:wood'},
        {'group:wood','group:wood','group:wood'},
      }
    })
    C.register_craft_compat({
      output = 'ma_pops_furniture:upcabinet_corner',
      recipe = {
        {'group:wood','group:wood','group:wood'},
        {'group:wood','group:wood','default:chest'},
        {'group:wood','dye:'..color,''},
      }
    })
    C.register_craft_compat({
      output = 'ma_pops_furniture:sink_'..color,
      recipe = {
        {'ma_pops_furniture:br_sink','ma_pops_furniture:counter_'..color},
      }
    })
  end
end

-- Wood-family counters
do
  local counter_table = {
    {'Wooden', 'wood'},
    {'Acacia', 'acacia_wood'},
    {'Aspen', 'aspen_wood'},
    {'Jungle', 'junglewood'},
    {'Pine', 'pine_wood'},
  }
  for i = 1, #counter_table do
    local material = counter_table[i][2]

    C.register_craft_compat({
      output = 'ma_pops_furniture:counter2_'..material,
      recipe = {
        {'default:'..material,'default:'..material,'default:'..material},
        {'default:'..material, 'ma_pops_furniture:barrel','default:'..material},
        {'default:'..material,'default:'..material,'default:'..material},
      }
    })
    C.register_craft_compat({
      type = "shapeless",
      output = 'ma_pops_furniture:counter3_'..material,
      recipe = {'ma_pops_furniture:counter2_'..material, "ma_pops_furniture:barrel"}
    })
    C.register_craft_compat({
      type = "shapeless",
      output = 'ma_pops_furniture:counter_'..material,
      recipe = {'ma_pops_furniture:counter3_'..material}
    })
    C.register_craft_compat({
      type = "shapeless",
      output = 'ma_pops_furniture:counter1_'..material,
      recipe = {'ma_pops_furniture:counter2_'..material}
    })
    C.register_craft_compat({
      output = 'ma_pops_furniture:upcabinet_'..material,
      recipe = {
        {'default:'..material,'','default:'..material},
        {'default:'..material,'default:chest','default:'..material},
        {'default:'..material,'default:'..material,'default:'..material},
      }
    })
    C.register_craft_compat({
      output = 'ma_pops_furniture:upcabinet_corner',
      recipe = {
        {'default:'..material,'default:'..material,'default:'..material},
        {'default:'..material,'default:'..material,'default:chest'},
        {'default:'..material,'',''},
      }
    })
    C.register_craft_compat({
      output = 'ma_pops_furniture:sink_'..material,
      recipe = {
        {'ma_pops_furniture:br_sink','ma_pops_furniture:counter_'..material},
      }
    })
  end
end

-- Upholstered chair (color variants) + recolors
do
  local chair2_table = {
    'black','blue','brown','cyan','dark_green','dark_grey','green','grey',
    'magenta','orange','pink','red','violet','yellow'
  }
  for _, color in ipairs(chair2_table) do
    C.register_craft_compat({
      output = 'ma_pops_furniture:chair2_'..color,
      recipe = {
        {'wool:'..color, 'wool:'..color, 'wool:'..color},
        {'wool:'..color, 'wool:'..color, 'wool:'..color},
        {'group:wood', '', 'group:wood'},
      }
    })
    C.register_craft_compat({
      output = 'ma_pops_furniture:chair2_'..color,
      recipe = {'ma_pops_furniture:chair2_white', 'dye:'..color},
      type   = "shapeless",
    })
    C.register_craft_compat({
      output = 'ma_pops_furniture:chair2_white',
      recipe = {'ma_pops_furniture:chair2_'..color, 'dye:white'},
      type   = "shapeless",
    })
    for _, tgt in ipairs({'black','blue','brown','cyan','dark_grey','grey','green','magenta','orange','pink','red','violet','yellow'}) do
      C.register_craft_compat({
        output = 'ma_pops_furniture:chair2_'..tgt,
        recipe = {'ma_pops_furniture:chair2_'..color, 'dye:'..tgt},
        type   = "shapeless",
      })
    end
  end
  C.register_craft_compat({
    output = 'ma_pops_furniture:chair2_white',
    recipe = {
      {'wool:white','wool:white','wool:white'},
      {'wool:white','wool:white','wool:white'},
      {'group:wood','','group:wood'},
    }
  })
  -- Fix space in itemstring
  C.register_craft_compat({
    output = 'ma_pops_furniture:chair2_rainbow',
    recipe = {
      {'wool:black', '', ''},
      {'wool:blue', 'wool:yellow', 'wool:pink'},
      {'default:acacia_tree', '', 'default:acacia_tree'},
    }
  })
end

-- Sofas
do
  local sofa_colors = {'black','blue','brown','cyan','dark_green','dark_grey','green','grey','magenta','orange','pink','red','violet','white','yellow'}
  for _, color in ipairs(sofa_colors) do
    C.register_craft_compat({
      output = 'ma_pops_furniture:sofa_'..color,
      recipe = {
        {'', '', ''},
        {'wool:'..color, 'wool:'..color, 'wool:'..color},
        {'wool:'..color, 'wool:'..color, 'wool:'..color},
      }
    })
  end
  local recolor = {'black','blue','brown','cyan','dark_green','dark_grey','green','grey','magenta','orange','pink','red','violet','yellow'}
  for _, color in ipairs(recolor) do
    C.register_craft_compat({
      output = 'ma_pops_furniture:sofa_'..color,
      recipe = {'ma_pops_furniture:sofa_white', 'dye:'..color},
      type   = "shapeless",
    })
  end
end

-- Curtains (fs_*)
do
  local fs_colors = {'black','blue','brown','cyan','dark_green','dark_grey','green','grey','magenta','orange','pink','red','violet','yellow'}
  C.register_craft_compat({
    output = 'ma_pops_furniture:fs_white',
    recipe = {
      {'wool:white','wool:white','wool:white'},
      {'group:wood','','group:wood'},
    }
  })
  for _, color in ipairs(fs_colors) do
    C.register_craft_compat({
      output = 'ma_pops_furniture:fs_'..color,
      recipe = {
        {'wool:'..color,'wool:'..color,'wool:'..color},
        {'group:wood','','group:wood'},
      }
    })
  end
  for _, color in ipairs(fs_colors) do
    C.register_craft_compat({
      output = 'ma_pops_furniture:fs_'..color,
      recipe = {'ma_pops_furniture:fs_white','dye:'..color},
      type   = "shapeless",
    })
  end
  C.register_craft_compat({
    output = 'ma_pops_furniture:fs_rainbow',
    recipe = {
      {'', '', ''},
      {'wool:blue', 'wool:yellow', 'wool:pink'},
      {'default:acacia_tree', '', 'default:acacia_tree'},
    }
  })
end

-- Electronics / media
C.register_craft_compat({
  output = 'ma_pops_furniture:vcr_off',
  recipe = {
    {'','',''},
    {'default:coalblock','default:coalblock','default:coalblock'},
    {'default:coalblock','default:mese_crystal','default:coalblock'},
  }
})

-- Entertainment units (by material)
do
  local unit_table = {
    {'wood'},{'acacia_wood'},{'aspen_wood'},{'pine_wood'},{'junglewood'}
  }
  for i = 1, #unit_table do
    local material = unit_table[i][1]
    C.register_craft_compat({
      output = 'ma_pops_furniture:e_u_'..material,
      recipe = {
        {'default:'..material,'default:'..material,'default:'..material},
        {'default:'..material,'default:chest','default:'..material},
        {'default:'..material,'','default:'..material},
      }
    })
  end
end

-- Misc
C.register_craft_compat({
  output = "ma_pops_furniture:trampoline",
  recipe = {
    {"farming:string", "farming:string", "farming:string"},
    {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
    {"default:steel_ingot", "", "default:steel_ingot"}
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:fireplace',
  recipe = {
    {'default:brick', 'default:brick', 'default:brick'},
    {'default:brick', 'default:furnace', 'default:brick'},
    {'default:brick', 'default:brick', 'default:brick'}
  }
})

-- Lampshades
do
  local lamp_table = {
    {'Black', 'black', 'black:225'},
    {'Blue', 'blue', 'blue:225'},
    {'Brown', 'brown', 'brown:225'},
    {'Cyan', 'cyan', 'cyan:200'},
    {'Dark Green', 'dark_green', 'green:225'},
    {'Dark Grey', 'dark_grey', 'black:200'},
    {'Green', 'green', '#32cd32:150'},
    {'Grey', 'grey', 'black:100'},
    {'Magenta', 'magenta', 'magenta:200'},
    {'Orange', 'orange', 'orange:225'},
    {'Pink', 'pink', 'pink:225'},
    {'Red', 'red', 'red:225'},
    {'Violet', 'violet', 'violet:225'},
    {'White', 'white', 'white:1'},
    {'Yellow', 'yellow', 'yellow:225'},
  }
  for _, v in ipairs(lamp_table) do
    local color = v[2]
    C.register_craft_compat({
      output = 'ma_pops_furniture:lamp_off_'..color,
      recipe = {
        {'wool:white','wool:white','wool:white'},
        {'wool:white','default:torch','wool:white'},
        {'wool:'..color, 'wool:'..color, 'wool:'..color}
      }
    })
  end
end

-- Curtains (window curtains)
do
  local curtain_table = {
    {'Black', 'black', 'black:225'},
    {'Blue', 'blue', 'blue:225'},
    {'Brown', 'brown', 'brown:225'},
    {'Cyan', 'cyan', 'cyan:200'},
    {'Dark Green', 'dark_green', 'green:225'},
    {'Dark Grey', 'dark_grey', 'black:200'},
    {'Green', 'green', '#32cd32:150'},
    {'Grey', 'grey', 'black:100'},
    {'Magenta', 'magenta', 'magenta:200'},
    {'Orange', 'orange', 'orange:225'},
    {'Pink', 'pink', 'pink:225'},
    {'Red', 'red', 'red:225'},
    {'Violet', 'violet', 'violet:225'},
    {'White', 'white', 'white:1'},
    {'Yellow', 'yellow', 'yellow:225'},
  }
  for _, v in ipairs(curtain_table) do
    local color = v[2]
    C.register_craft_compat({
      output = 'ma_pops_furniture:curtains_'..color,
      recipe = {
        {'default:acacia_tree','default:acacia_tree','default:acacia_tree'},
        {'wool:'..color, '', 'wool:'..color},
        {'wool:'..color, '', 'wool:'..color}
      }
    })
    C.register_craft_compat({
      type = "shapeless",
      output = 'ma_pops_furniture:curtains_2_tall_'..color,
      recipe = {'ma_pops_furniture:curtains_'..color, 'ma_pops_furniture:curtains_'..color}
    })
  end
end

C.register_craft_compat({
  output = 'ma_pops_furniture:blinds',
  recipe = {
    {'default:stick', 'default:stick', 'default:stick'},
    {'default:stick', 'dye:white', 'default:stick'},
    {'default:stick', 'default:stick', 'default:stick'}
  }
})

C.register_craft_compat({
  output = "ma_pops_furniture:stereo",
  recipe = {
    {"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
    {"default:steel_ingot", "default:chest", "default:steel_ingot"},
    {"default:stick", "", "default:stick"}
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:tv_off',
  recipe = {
    {'default:tree', 'default:tree', 'default:tree'},
    {'default:tree', 'wool:black', 'default:tree'},
    {'default:tree', 'default:tree', 'default:tree'}
  }
})

-- Coffee table / side table (c_*)
do
  local c_table = {
    {'wood'},{'aspen_wood'},{'junglewood'},{'acacia_wood'},{'pine_wood'},{'cobble'}
  }
  for _, v in ipairs(c_table) do
    local material = v[1]
    C.register_craft_compat({
      output = 'ma_pops_furniture:c_'..material,
      recipe = {
        {'', '', ''},
        {'default:'..material, 'default:'..material, 'default:'..material},
        {'default:'..material, '', 'default:'..material}
      }
    })
  end
end

C.register_craft_compat({
  output = 'ma_pops_furniture:computer',
  recipe = {
    {'default:stone','default:stone','default:stone'},
    {'default:glass','default:mese_crystal','default:stone'},
    {'default:stone','default:copper_lump','default:stone'},
  }
})

-- Tables (slab + sticks)
do
  local materials = {'wood','aspen_wood','junglewood','acacia_wood','pine_wood','cobble'}
  for _, material in ipairs(materials) do
    C.register_craft_compat({
      output = 'ma_pops_furniture:table_' .. material,
      recipe = {
        {'stairs:slab_' .. material, 'stairs:slab_' .. material, 'stairs:slab_' .. material},
        {'', 'default:stick', ''},
        {'', 'default:stick', ''}
      }
    })
  end
  C.register_craft_compat({
    output = 'ma_pops_furniture:table_wood',
    recipe = {
      {'stairs:slab_wood', 'stairs:slab_wood', 'stairs:slab_wood'},
      {'', 'default:stick', ''},
      {'', 'default:stick', ''}
    }
  })
end

-- Hedges
do
  local hedge_table = {'leaves','pine_needles','jungleleaves','acacia_leaves','aspen_leaves'}
  for _, material in ipairs(hedge_table) do
    C.register_craft_compat({
      output = 'ma_pops_furniture:hedge_'..material,
      recipe = {
        {'', '', ''},
        {'default:'..material, 'default:'..material, 'default:'..material},
        {'default:'..material, 'default:'..material, 'default:'..material}
      }
    })
  end
end

-- Garden / outdoor
C.register_craft_compat({
  output = 'ma_pops_furniture:birdbath',
  recipe = {
    {'default:stone','bucket:bucket_water','default:stone'},
    {'','default:stone',''},
    {'default:stone','default:stone','default:stone'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:tile_kitchen',
  recipe = {
    {'default:stone_block','dye:white','default:stone_block'},
    {'dye:black','default:stone_block','dye:black'},
    {'default:stone_block','dye:white','default:stone_block'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:tile_floor_kitchen',
  recipe = {
    {'default:stone_block','ma_pops_furniture:hammer'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:doorbell 4',
  recipe = {
    {'','default:stone',''},
    {'','default:mese_crystal',''},
    {'','',''},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:ac',
  recipe = {
    {'default:coral_skeleton','default:coral_skeleton','default:coral_skeleton'},
    {'default:coral_skeleton','ma_pops_furniture:fan_blade','default:coral_skeleton'},
    {'default:coral_skeleton','default:mese_crystal','default:coral_skeleton'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:fan_off',
  recipe = {
    {'default:coral_skeleton','default:coral_skeleton','default:coral_skeleton'},
    {'default:coral_skeleton','ma_pops_furniture:fan_blade','default:coral_skeleton'},
    {'default:coral_skeleton','default:coral_skeleton','default:coral_skeleton'},
  }
})

-- Parts / tools
minetest.register_craftitem("ma_pops_furniture:fan_blade", {
  description = 'Fan Blade',
  inventory_image = "mp_blade.png",
})

C.register_craft_compat({
  output = 'ma_pops_furniture:fan_blade',
  recipe = {
    {'default:coral_skeleton','','default:coral_skeleton'},
    {'','default:coral_skeleton',''},
    {'default:coral_skeleton','','default:coral_skeleton'},
  }
})

minetest.register_craftitem("ma_pops_furniture:knife", {
  description = 'Knife',
  inventory_image = "mp_knife.png",
})

C.register_craft_compat({
  output = 'ma_pops_furniture:knife',
  recipe = {
    {'default:steel_ingot','',''},
    {'','default:steel_ingot',''},
    {'','','default:stick'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:grill',
  recipe = {
    {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
    {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
    {'default:steel_ingot','','default:steel_ingot'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:fridge_white',
  recipe = {
    {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
    {'default:steel_ingot','default:snow','default:steel_ingot'},
    {'default:steel_ingot','default:steel_ingot','default:steel_ingot'},
  }
})

do
  local fridges_list = {
    {"black", "Darkened Fridge"}, 
    {"blue", "Blue Fridge"},
    {"green", "Green Fridge"}, 
    {"orange", "Orange Fridge"}, 
    {"red", "Red Fridge"}, 
    {"yellow", "Yellow Fridge"}, 
    {"pink", "Pink Fridge"}
  }
  for _, fridge in ipairs(fridges_list) do
    local colour = fridge[1]
    C.register_craft_compat({
      type = "shapeless",
      output = 'ma_pops_furniture:fridge_'..colour,
      recipe = {'ma_pops_furniture:fridge_white', 'dye:'..colour}
    })
  end
end

C.register_craft_compat({
  output = 'ma_pops_furniture:stone_path_1 5',
  recipe = {
    {'default:stone','default:stone'},
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:hammer',
  recipe = {
    {'','default:steel_ingot', ''},
    {'', 'default:stick', 'default:steel_ingot'},
    {'default:stick', '', ''}
  }
})

C.register_craft_compat({
  output = 'ma_pops_furniture:shears',
  recipe = {
    {'','default:steel_ingot', ''},
    {'default:stick', '', 'default:steel_ingot'},
    {'', 'default:stick', ''}
  }
})
