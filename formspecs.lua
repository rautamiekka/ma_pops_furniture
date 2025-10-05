-- Cross-game fireplace formspec (MTG + Mineclonia)
-- Safe to paste anywhere before you use ma_pops_furniture.fireplace_formspec

local function has(mod) return minetest.get_modpath(mod) ~= nil end

-- Pick a brick texture that exists in the current game
local function brick_tex()
  if has("mcl_core") then
    return "mcl_core_bricks.png"      -- Mineclonia
  else
    return "default_brick.png"        -- Minetest Game
  end
end

-- Hotbar background provider
local function hotbar_bg(x, y)
  if default and default.get_hotbar_bg then
    return default.get_hotbar_bg(x, y)          -- MTG
  elseif rawget(_G, "mcl_formspec") and mcl_formspec.get_hotbar_bg then
    return mcl_formspec.get_hotbar_bg(x, y)     -- Mineclonia
  else
    return ""                                   -- fallback: no hotbar overlay
  end
end

-- Optional MTG “default” UI bits, if present
local function default_ui_bits()
  local s = {}
  if default and default.gui_bg       then s[#s+1] = default.gui_bg end
  if default and default.gui_bg_img   then s[#s+1] = default.gui_bg_img end
  if default and default.gui_slots    then s[#s+1] = default.gui_slots end
  return table.concat(s)
end

-- Build the formspec
local function fireplace_formspec()
  local w, h = 8, 6
  local fs = {
    "formspec_version[4]",
    ("size[%d,%d]"):format(w, h),

    -- MTG visuals if available (no-ops in MCL)
    default_ui_bits(),

    -- Fix: background uses x,y;w,h order (the original had them swapped)
    ("background[0,0;%d,%d;%s;true]"):format(w, h, brick_tex()),

    -- Fuel slot (1×1) at top-left-ish; nudge down a bit for nicer spacing
    "list[current_name;fuel;1,0.5;1,1;]",

    -- Player inventory (8×4)
    "list[current_player;main;0,2.6;8,4;]",

    -- Hotbar overlay (works in both games where supported)
    hotbar_bg(0, 2.6),
  }
  return table.concat(fs)
end

ma_pops_furniture.fireplace_formspec = fireplace_formspec()


ma_pops_furniture.fireplace_formspec =
	'size[8,6]'..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	'background[8,6;0,0;default_brick.png;true]'..
	'list[current_name;fuel;1,0;1,1;]'..
	'list[current_player;main;0,2.5;8,4;]'
	default.get_hotbar_bg(0,4.85)