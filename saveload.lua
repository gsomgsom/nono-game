local Game = require "game"
local settings = Game.settings

local serpent = require "serpent"

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
	
	
	love.filesystem.write(Game.conffile, serpent.block(save))
end

function Game.loadConfig()
	local save, ok = love.filesystem.read(Game.conffile)
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