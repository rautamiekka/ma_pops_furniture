-- mpf_helpers.lua — portable helpers for MTG + Mineclonia
local MPF = ma_pops_furniture
MPF._attached = MPF._attached or {}  -- tracks seated players

-- ---------- small helpers ----------
local function top_face(pointed_thing)
	if not pointed_thing or not pointed_thing.above or not pointed_thing.under then return false end
	return (pointed_thing.above.y or 0) > (pointed_thing.under.y or 0)
end

local function set_pos_safe(player, pos)
	if player.set_pos then
		player:set_pos(pos)
	else
		player:setpos(pos) -- very old engines
	end
end

local function set_look_horizontal_safe(player, yaw)
	-- 5.x API
	if player.set_look_horizontal then
		player:set_look_horizontal(yaw)
	elseif player.set_look_yaw then
		player:set_look_yaw(yaw) -- legacy
	end
end

local function set_eye_offset_safe(player, first, third)
	if player.set_eye_offset then
		player:set_eye_offset(first, third or {x=0,y=0,z=0})
	end
end

local function set_physics_locked(player, locked) -- lock/unlock movement
	if player.set_physics_override then
		if type(player.set_physics_override) == "function" then
			-- table form is modern
			local val = locked and 0 or 1
			player:set_physics_override({speed = val, jump = val, gravity = 1})
		end
	end
end

-- Try both MTG's default and the common player_api/mcl variants
local function set_anim(player, anim, speed)
	speed = speed or 30
	if default and default.player_set_animation then
		default.player_set_animation(player, anim, speed)
	elseif player_api and player_api.set_animation then
		player_api.set_animation(player, anim)
	elseif mcl_player and mcl_player.player_set_animation then
		mcl_player.player_set_animation(player, anim)
	end
end

-- ---------- Sitting ----------
function MPF.sit(pos, node, clicker, pointed_thing)
	-- Only allow clicks on the top face
	if not top_face(pointed_thing) then return end

	local pname = clicker:get_player_name()
	if not pname or pname == "" then return end

	-- prevent double-occupancy
	for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 0.1)) do
		if obj:is_player() and obj:get_player_name() ~= pname then
			return
		end
	end

	local vel = clicker:get_player_velocity and clicker:get_player_velocity() or {x=0,y=0,z=0}
	local ctrl = clicker:get_player_control and clicker:get_player_control() or {}

	local is_attached = MPF._attached[pname] == true
	local facedir = (node and node.param2) or 0

	-- stand up
	if is_attached then
		local p = vector.new(pos)
		p.y = p.y - 0.5
		set_pos_safe(clicker, p)
		set_eye_offset_safe(clicker, {x=0, y=0, z=0}, {x=0, y=0, z=0})
		set_physics_locked(clicker, false)
		MPF._attached[pname] = false
		set_anim(clicker, "stand", 30)
		return
	end

	-- sit down: require no sneak, no motion, and a cardinal rotation (<=3)
	if (facedir <= 3) and not ctrl.sneak and (vel.x == 0 and vel.y == 0 and vel.z == 0) then
		-- adjust camera/physics and place player
		set_eye_offset_safe(clicker, {x=0, y=-7, z=2}, {x=0, y=0, z=0})
		set_physics_locked(clicker, true)
		set_pos_safe(clicker, pos)
		MPF._attached[pname] = true
		set_anim(clicker, "sit", 30)

		-- orient camera like original
		-- facedir -> yaw mapping in radians (Z+, X+, Z-, X-)
		local yaw_by_param2 = {3.15, 7.9, 6.28, 4.75}
		local yaw = yaw_by_param2[facedir+1] or 0
		set_look_horizontal_safe(clicker, yaw)
	end
end

function MPF.sit_dig(pos, digger)
	for _, player in ipairs(minetest.get_objects_inside_radius(pos, 0.1)) do
		if player:is_player() and MPF._attached[player:get_player_name()] then
			return false
		end
	end
	return true
end

-- ---------- Window stack operator (unchanged logic, minor tidy) ----------
function MPF.window_operate(pos, old_node_state_name, new_node_state_name)
	local offsets   = {-1,1,-2,2,-3,3}
	local stop_up, stop_down = false, false

	for _, v in ipairs(offsets) do
		local p = {x=pos.x, y=pos.y+v, z=pos.z}
		local node = minetest.get_node_or_nil(p)
		if node and node.name == old_node_state_name
		   and ((v > 0 and not stop_up) or (v < 0 and not stop_down)) then
			minetest.swap_node(p, {name=new_node_state_name, param2=node.param2})
		elseif v > 0 and not stop_up then
			stop_up = true
		elseif v < 0 and not stop_down then
			stop_down = true
		end
	end
end
