local Assets = require "art"

local function stage()
	local obs = { }

	local function new_block(art, x, y, w, h)
		local f = {
			x = x, y = y, w = w, h = h, xv = 0, yv = 0, fixed = true, art = art
		}
		obs[1 + #obs] = f
	end

	local player = {
		x = 0, y = 0, xv = 0, yv = 0, standing = true, touch = { },
		w = 3, h = 3, facing = 1,
		art = Assets.player
	}


	for x = 1, 50 do
		new_block(Assets.grass, -90 + 8 * x, -15 + math.sqrt((25 * 25) - (x - 25) * (x - 25)), 8, 7)
	end

	--new_block(Assets.grass, -90, 3, 210, 4)
	--new_block(Assets.grass, 10, -4, 8, 4)
	--new_block(Assets.grass, 15, -6, 8, 4)
	--new_block(Assets.grass, 20, -8, 8, 4)
	--new_block(Assets.grass, -90 + 210, 2, 30, 5)

	obs[1 + #obs] = player

	for i = 1, 10 do
		local dude = {
			x = 30 + i * 9, y = 0, xv = 0, yv = 0, standing = true, touch = { },
			w = 6, h = 3, isdude = true,
			art = Assets.dude
		}
		obs[1 + #obs] = dude
	end

	obs.player = player

	return obs
end


return {
	stage = stage
}

