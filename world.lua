local assets = require "art"

local player = {
	x = 0, y = 0, xv = 0, yv = 0, standing = true, touch = { },
	w = 5, h = 3, facing = 1,
	art = assets.player
}

local dude = {
	x = 30, y = 0, xv = 0, yv = 0, standing = true, touch = { },
	w = 6, h = 3,
	art = assets.dude
}

local cloud = {
	x = 25, y = -2, z = .5, xv = 0, yv = 0, standing = true, touch = { },
	art = assets.cloud
}

local sun = {
	x = 22, y = -1.0, z = .3, xv = 0, yv = 0, standing = true, touch = { },
	art = assets.sun

}

local floor = {
	x = -90, y = 3, fixed = true, touch = { },
	w = 210, h = 4, xv = 0, yv = 0,
	art = assets.grass
}

local floor2 = {
	x = floor.x + floor.w, y = 2, fixed = true, touch = { },
	w = 30, h = 5, xv = 0, yv = 0,
	art = assets.grass
	
}

local camera = {
	track = player, x = 0, y = -20
}

local obs = {
	player, dude, floor, floor2
}

local sky = {
	sun, cloud
}


local termw, termh

local function drawart(term, x, y, art)
	for i = 1, #art do
		term.at(x, y + i - 1).print(art[i])
	end
end

local function drawtexture(term, x, y, art, w, h)
	local tw, th = #art[1], #art

	local x1, x2 = x, x + w - 1
	local y1, y2 = y, y + h - 1

	if x1 < 0 then x1 = 0 end
	if y1 < 0 then y1 = 0 end
	if x2 >= termw then x2 = termw - 1 end
	if y2 >= termh then y2 = termh - 1 end

	for cy = y1, y2 do
		local i = 1 + ((cy - y) % th)
		for cx = x1, x2 do
			local c = string.byte(art[i], 1 + ((cx - x) % tw))
			if c > 32 then term.at(cx, cy).put(c) end
		end
	end
end


local function draw(term, beeping)
	termw, termh = term.getsize() -- todo : cache this

	-- track the camera
	camera.x = termw * -.5 + player.x
	camera.y = termh * -.5

	for i = 1, #sky do
		local ob = sky[i]
		local px, py = math.floor(ob.x) - math.floor(ob.z * camera.x), math.floor(ob.y) - math.floor(ob.z * camera.y)
		
		local art = ob.art
		term.fg(art.fg or 15).bg(art.bg or 0)
		drawart(term, px, py, art)
	end

	for i = 1, #obs do
		local ob = obs[i]
		local px, py = math.floor(ob.x) - math.floor(camera.x), math.floor(ob.y) - math.floor(camera.y)
		
		local art = ob.art
		if art.left ~= nil then
			art = ob.facing == 1 and art.right or art.left
		end
		term.fg(art.fg or 15).bg(art.bg or 0)
		drawtexture(term, px, py, art, ob.w, ob.h)
	end
end

local function friction(v, dv)
	local sign = 1
	if v < 0 then 
		sign = -1
		v = -v
	end

	if v < dv then
		return 0
	else
		return sign * (v - dv)
	end
end

local function collide( )
	for i = 1, #obs do
		for j = i + 1, #obs do
			local o1, o2 = obs[i], obs[j]

			if 
				(o1.y + o1.h >= o2.y) and (o2.y + o2.h >= o1.y) and
				(o1.x + o1.w >= o2.x) and (o2.x + o2.w >= o1.x) then

				-- standing only first
				if o1.y + o1.h < o2.y + o2.h then
					o1.y = o2.y - o1.h
					o1.yv = o2.yv
					o1.standing = true
				else
					o2.y = o1.y - o2.h
					o2.yv = o1.yv
					o2.standing = true
				end
			end
		end
	end
end

local function advance( )
	for i = 1, #obs do
		local ob = obs[i]
		ob.standing = false
	end
	

	for i = 1, #obs do
		local ob = obs[i]

		if not ob.fixed then
			ob.x = ob.x + ob.xv
			ob.y = ob.y + ob.yv
			
			ob.xv = friction(ob.xv, .005)
			ob.yv = ob.yv + .025
		end
	end

	collide( )

	if dude.standing and math.random(20) == 1 then
		dude.yv = -.5
	end
end

local function feed(dx, dy)
	if dx == 0 and dy == 0 then
		player.xv = 0
	end

	if dx ~= 0 then
		if player.xv < 0 and dx > 0 or player.xv > 0 and dx < 0 then
			player.xv = 0
		else
			player.xv = .5 * dx
			player.facing = dx
		end
	end

	if dy ~= 0 then
		if player.standing then
			player.yv = .5 * dy
		end
	end
end


return {
	draw = draw,
	advance = advance,
	feed = feed
}

