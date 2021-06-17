local serpent = require "serpent"

local clamp = function(x, a, b)
	if x < a then return a end
	if x > b then return b end
	return x
end

local conffile = "nono_config.txt"

local Game = {}
local settings = {}
Game.settings = settings


local _fsmodes, _fsmodenames
local function getScreenSettings()
	local width, height = love.graphics.getDimensions()
	local deskwidth, deskheight = love.window.getDesktopDimensions()
	local fullscreen, fullscreentype = love.window.getFullscreen()
	
	local fsmodes, fsmodenames = _fsmodes, _fsmodenames
	if not fsmodes then
		fsmodes = love.window.getFullscreenModes()
		table.sort(fsmodes, function(a, b) return a.width * a.height < b.width * b.height end)
		fsmodenames = {}
		for k, v in ipairs(fsmodes) do
			fsmodenames[k] = string.format("%ix%i", v.width, v.height)
		end
		_fsmodes, _fsmodenames = fsmodes, fsmodenames
	end
	
	local fsindex = #fsmodenames
	local fsname = fsmodenames[fsindex]
	if fullscreen and fullscreentype == "exclusive" then
		for k, v in ipairs(fsmodes) do
			if v.width == width and v.height == height then
				fsname = fsmodenames[k]
				fsindex = k
				break
			end
		end
	end
	
	return {
		width = width, height = height, windowwidth = width, windowheight = height,
		deskwidth = deskwidth, deskheight = deskheight,
		fullscreen = fullscreen, fullscreentype = fullscreentype,
		fsmodes = fsmodes, fsmodenames = fsmodenames, fsname = fsname, fsindex = fsindex,
	}
end

function Game.applyScreenSettings()
	local t = getScreenSettings()
	
	settings.windowwidth  = clamp(settings.windowwidth,  400, t.deskwidth)
	settings.windowheight = clamp(settings.windowheight, 300, t.deskheight)
	
	settings.fullscreen = (settings.fullscreen == true)
	
	if settings.fullscreentype ~= "exclusive" then
		settings.fullscreentype = "desktop"
	end
	
	local fsname, fsindex = settings.fsname, nil
	for k, v in ipairs(t.fsmodenames) do
		if v == fsname then
			fsname = v
			fsindex = k
			break
		end
	end
	if not fsindex then fsname, fsindex = t.fsname, t.fsindex end
	settings.fsname, settings.fsindex = fsname, fsindex
	
	local setmode = (t.fullscreen ~= settings.fullscreen)
	
	if settings.fullscreen then
		setmode = setmode or (t.fullscreentype ~= settings.fullscreentype)
		
		if settings.fullscreentype == "desktop" then
			settings.width, settings.height = t.deskwidth, t.deskheight
			
		else -- "exclusive"
			local mode = t.fsmodes[fsindex]
			settings.width, settings.height = mode.width, mode.height
			--setmode = setmode or (t.fsname ~= settings.fsname)
		end
	else
		settings.width, settings.height = settings.windowwidth, settings.windowheight
	end
	
	setmode = setmode or (t.width ~= settings.width or t.height ~= settings.height)
	
	if setmode then
		love.window.setMode(settings.width, settings.height, {
			fullscreen = settings.fullscreen,
			fullscreentype = settings.fullscreentype
		})
		t = getScreenSettings()
	
		-- purge any disparity
		Game.width, Game.height = t.width, t.height
		settings.width, settings.height = t.width, t.height
		--for k, v in pairs(t) do settings[k] = v end
	else
		print "nothing new to setmode"
	end

end

function Game.defaultSettings()
	local ss = getScreenSettings()
	Game.width, Game.height = ss.width, ss.height
	for k, v in pairs(ss) do settings[k] = v end
	
	settings.size = 10
	settings.musicvol = 10
	settings.soundvol = 10
	settings.highlight = false
end

function Game.saveConfig()
	local save = {}
	save.size = settings.size
	save.musicvol = settings.musicvol
	save.soundvol = settings.soundvol
	save.theme = Game.theme.name
	save.highlight = settings.highlight
	
	save.windowwidth  = settings.windowwidth
	save.windowheight = settings.windowheight
	save.fullscreen = settings.fullscreen
	save.fullscreentype = settings.fullscreentype
	save.fsname = settings.fsname
	
	local grid = Game.States.Main.grid
	if grid then
		save.grid = love.data.compress("string", "zlib", serpent.dump(grid))
		save.grid = love.data.encode("string", "base64", save.grid)
	end
	--save.grid = serpent.dump(main.grid)
	
	
	love.filesystem.write(conffile, serpent.block(save))
end

function Game.onQuit() -- called in love.quit
	Game.saveConfig()
	return false
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
	
	if save.size then settings.size = save.size end
	if save.musicvol then settings.musicvol = save.musicvol end
	if save.soundvol then settings.soundvol = save.soundvol end
	if save.highlight ~= nil then settings.highlight = save.highlight end
	
	if save.windowwidth and save.windowheight then
		settings.windowwidth  = save.windowwidth
		settings.windowheight = save.windowheight
	end
	if save.fullscreen ~= nil then settings.fullscreen = save.fullscreen end
	if save.fullscreentype then settings.fullscreentype = save.fullscreentype end
	settings.fsname = save.fsname
	
	Game.applyScreenSettings()
	
	Game.setTheme(save.theme)
	


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
	Game.defaultSettings()

	
	require "themes"
	Game.loadConfig()
	
	Game.applyTheme(Game.theme.name)
	
	Game.sw, Game.sh = Game.width / 800, Game.height / 600
	
	local smin = math.min(Game.sw, Game.sh)
	local fonts = {
		huge    = love.graphics.newFont(math.max(8, math.floor(48 * smin))),
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