local serpent = require "serpent"

local clamp = function(x, a, b)
	if x < a then return a end
	if x > b then return b end
	return x
end

local conffile = "nono_config.txt"

local Game = {}

function Game.saveConfig()
	local save = {}
	save.size = Game.size
	save.musicvol = Game.musicvol
	save.soundvol = Game.soundvol
	save.theme = Game.theme.name
	save.highlight = Game.highlight
	
	save.windowwidth  = Game.windowwidth
	save.windowheight = Game.windowheight
	save.fullscreen = Game.fullscreen
	save.fullscreentype = Game.fullscreentype
	save.fsindex = Game.fsindex
	
	local grid = Game.States.Main.grid
	if grid then
		save.grid = love.data.compress("string", "zlib", serpent.dump(grid))
		save.grid = love.data.encode("string", "base64", save.grid)
	end
	--save.grid = serpent.dump(main.grid)
	
	
	love.filesystem.write(conffile, serpent.block(save))
end

function Game.quit(restart)
	if restart then return love.event.quit("restart") end
	
	love.event.push("quit")
end

function Game.loadConfig()
	local save, ok = love.filesystem.read(conffile)
	if save then
		ok, save = serpent.load(save)
	end
	
	if not save then
		return
	end
	
	if save.size then Game.size = save.size end
	if save.musicvol then Game.musicvol = save.musicvol end
	if save.soundvol then Game.soundvol = save.soundvol end
	if save.highlight ~= nil then Game.highlight = save.highlight end
	
	Game.setTheme(save.theme)
	
	local maxwidth, maxheight = love.window.getDesktopDimensions()
	
	if save.windowwidth and save.windowheight then
		Game.windowwidth  = clamp(save.windowwidth,  400, maxwidth)
		Game.windowheight = clamp(save.windowheight, 300, maxheight)
	end
	if save.fsindex then
		Game.fsindex = clamp(save.fsindex, 1, #Game.fsmodes)
	end
	if save.fullscreen ~= nil then Game.fullscreen = save.fullscreen end
	if save.fullscreentype then Game.fullscreentype = save.fullscreentype end
	
	local w, h = love.graphics.getDimensions()
	local fs, fstype = love.window.getFullscreen()
	local setmode = false
	
	if Game.fullscreen then
		if not fs then setmode = true end
		
		if Game.fullscreentype == "desktop" then
			Game.width, Game.height = maxwidth, maxheight
			if fstype ~= "desktop" then setmode = true  end
		else
			local mode = Game.fsmodes[Game.fsindex]
			Game.width, Game.height = mode.width, mode.height
			if fstype == "desktop" then setmode = true end
		end
	else
		if fs then setmode = true end
		
		Game.width, Game.height = Game.windowwidth, Game.windowheight
	end
	
	if w ~= Game.width or h ~= Game.height then setmode = true end
	
	if setmode then
		--print(("setting mode: %ix%i, %s %s"):
		--	format(Game.width, Game.height, Game.fullscreen, Game.fullscreentype))
		
		love.window.setMode(Game.width, Game.height, {
			fullscreen = Game.fullscreen,
			fullscreentype = Game.fullscreentype
		})
		Game.width, Game.height = love.graphics.getDimensions()
		Game.fullscreen, Game.fullscreentype = love.window.getFullscreen()
	else
		--print "not setting mode"
	end

	if not save.grid then return end
	
	local grid = love.data.decode("string", "base64", save.grid)
	local grid = love.data.decompress("string", "zlib", grid)
	ok, grid = serpent.load(grid)
	if ok and grid then
		--print(grid.seed, grid.size)
		Game.loadedGrid = grid
	else
		print("error loading", ok, grid)
	end
end


function Game.load()
	Game.width, Game.height = love.graphics.getDimensions()
	Game.fullscreen, Game.fullscreentype = love.window.getFullscreen()
	
	local fsmodes = love.window.getFullscreenModes()
	table.sort(fsmodes, function(a, b) return a.width * a.height < b.width * b.height end)
	local fsmodenames = {}
	for k, v in ipairs(fsmodes) do
		fsmodenames[k] = string.format("%ix%i", v.width, v.height)
	end
	Game.fsmodes, Game.fsmodenames = fsmodes, fsmodenames
	
	Game.fsindex = 1
	Game.windowwidth, Game.windowheight = Game.width, Game.height
	if Game.fullscreen and Game.fullscreentype == "exclusive" then
		for k, v in ipairs(fsmodes) do
			if v.width == Game.width and v.height == Game.height then
				Game.fsindex = k
			end
		end
	end
	
	Game.size = 10
	Game.musicvol = 10
	Game.soundvol = 10
	Game.highlight = false
	
	require "themes"
	Game.loadConfig()
	
	Game.applyTheme(Game.theme.name)
	
	Game.sw, Game.sh = Game.width / 800, Game.height / 600
	
	local smin = math.min(Game.sw, Game.sh)
	local fonts = {
		huge    = love.graphics.newFont(math.max(8, math.floor(72 * smin))),
		large   = love.graphics.newFont(math.max(8, math.floor(32 * smin))),
		default = love.graphics.newFont(math.max(8, math.floor(24 * smin))),
		small   = love.graphics.newFont(math.max(8, math.floor(20 * smin))),
		tiny    = love.graphics.newFont(math.max(8, math.floor(16 * smin))),
		itsy    = love.graphics.newFont(math.max(8, math.floor(10 * smin))),
	}
	
	Game.fonts = fonts
	
	require("gui")
	require("states")
	
	Game.setState("Menu")
	
	local grid = Game.loadedGrid
	if grid then
		Game.States.Main:newGame(grid.size, grid.seed, grid)
	end

	
end

return Game