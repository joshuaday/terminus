local ffi = require "ffi"

local faces = {
	{1, 0, x = 1, y = 0, name = "right", index = 1},
	{-1, 0, x = -1, y = 0, name = "left", index = 2},
	{0, 1, x = 0, y = 1, name = "down", index = 3},
	{0, -1, x = 0, y = -1, name = "up", index = 4}
}

for i = 1, 4 do
	faces[faces[i].name] = faces[i]
end

local BODY = { } -- used to mark a mob with its body


ffi.cdef[[
	struct boxes_lua_edge {
		// l: x coordinate of left edge at beginning of frame
		// r: x coordinate of right edge at beginning of frame
		// y1: y coordinate at beginning of frame
		// y2: y coordinate at end of frame

		// min: lowest x coordinate touched during frame
		// max: highest x coordinate touched during frame
		
		// xv, yv: distance traversed in frame

		int facing;
		double l, r, y1, min, max, delta_sideways, delta_forward, y2;

		double end_time; //0 .. 1, time until a collision occurs (1 if no collision)
		
		struct boxes_lua_edge *prev, *next;
	};
]]

local lua_edge = ffi.typeof "struct boxes_lua_edge"

local bodies = { } -- unsorted, indexed by the object they're based on

local hlines = { first = lua_edge(0), last = lua_edge(0) }
local vlines = { first = lua_edge(0), last = lua_edge(0) }

hlines.first.next, hlines.last.prev = hlines.last, hlines.first
vlines.first.next, vlines.last.prev = vlines.last, vlines.first



local function insert_after(after, edge)
	local before = after.next
	
	while true do
		-- is this a good place to be inserted?
		-- (i.e., is it either (a) after us or (b) the very last edge?)
		if before.y1 < edge.y1 and before.facing ~= 0 then
			-- no, so let's keep tripping through the list
			after, before = before, before.next
		else
			-- yes!  insert it here!
			after.next, before.prev = edge, edge
			edge.next, edge.prev = before, after
			
			return edge
		end
	end
end

local function insert_near(search, edge) 
	local after, before = search, search.next
	-- just like the normal insertion process but we search left first

	while true do
		-- is this a good place to be inserted?
		-- (i.e., is it either (a) after us or (b) the very last edge?)
		if after.y1 > edge.y1 and after.facing ~= 0 then
			-- no, so let's keep tripping through the list
			after, before = after.prev, after.prev
		else
			-- yes!  insert it after this point
			return insert_after(after, edge)
		end
	end
end

local function debug_dump_edges(edge)
	while true do
		print (edge.y1)

		edge = edge.next

		if edge.facing == 0 then
			break
		end
	end
end

local function two_lines(a, b)
	-- a is a line that faces down and b is a line that faces up
	-- both are of type boxes_lua_edge

	-- do they cross each other vertically?
	-- (note that this can be moved off into a list sorted by y position!)
	if (a.y1 < b.y1 and a.y2 > b.y2) then
		-- do they overlap each other horizontally during that time?
		if (a.min < b.max and b.min < a.max) then
			-- at what exact moment (on a scale of 0..1) do they cross each other?
			local t = (a.y1 - b.y1) / (b.delta_forward - a.delta_forward) 
			-- and at that exact moment, are they in fact intersecting each other?
			-- (doesn't really matter right now) -- todo: add this test

			-- great!  we have a collision to put in our sequence of collisions for this round
			
			if t >= 0 and t < 1 then
				return true, t, a.y1 + t * a.delta_forward
			end
		else
			return true
		end
	else
		return false
	end
end


local function embody_mob(mob)
	local top = lua_edge(-1, mob.x, mob.x + mob.w, mob.y)
	local bottom = lua_edge(1, mob.x, mob.x + mob.w, mob.y + mob.h)

	local left = lua_edge(-1, mob.y, mob.y + mob.h, mob.x)
	local right = lua_edge(1, mob.y, mob.y + mob.h, mob.x + mob.w)
	
	insert_after(hlines.first, top)
	insert_after(top, bottom)

	insert_after(vlines.first, left)
	insert_after(left, right)

	return {
		left = left, top = top, bottom = bottom, right = right
	}
end

local function attach(mob)
	if mob[BODY] then
		return mob[BODY]
	else
		local body = embody_mob(mob)
		bodies[mob] = body
		mob[BODY] = body
		return body
	end
end

local function advance( )
	local function complete_edge(edge)
		-- note that we DO NOT EVER move y1 EXCEPT AFTER TESTING FOR COLLISIONS
		edge.y2 = edge.y1 + edge.delta_forward
		edge.min = edge.l + math.min(0, edge.delta_sideways)
		edge.max = edge.r + math.max(0, edge.delta_sideways)

		edge.end_time = 1.0
	end

	for mob, body in pairs(bodies) do
		complete_edge(body.left)
		complete_edge(body.right)
		complete_edge(body.top)
		complete_edge(body.bottom)
	end
	
	-- now bubble them!  the idea is that we only need to compare neighbors
	-- against neighbors they could have touched; if they don't swap positions, we're ok
	
	-- individual segments will bubble up and down, based on their direction and facing
	-- (the first thing we do with them, though, is find out how long they move during
	--  the frame and whether they end up linked with anything.  In this first loop,
	--  NOTHING MOVES.)

	local compare, compare_to, next_pair

	compare = hlines.first.next
	while true do
		-- 

		compare_to = compare.next
		-- 
		while compare_to.facing ~= 0 do
			if compare_to.facing ~= compare.facing then
				local crossed, t, y = two_lines(compare, compare_to)

				if t ~= nil then
					-- can't cross this one
				end
			end
			compare_to = compare_to.next
		end

		compare = compare.next
		if compare.facing == 0 then
			break
		end
	end

	-- update objects!
	for mob, rect in pairs(bodies) do
		mob.x = rect.left.y2
		mob.y = rect.top.y2
	end
end

return {
	attach = attach,
	advance = advance
}

