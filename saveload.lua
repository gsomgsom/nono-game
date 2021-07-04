local Game = require "game"
local settings = Game.settings

local serpent = require "serpent"

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

local function setMode(width, height, fs, fstype, fsindex, vsync)
	local t = getScreenSettings()
	
	if fs then
		if fstype == "exclusive" then
			local mode = t.fsmodes[fsindex]
			width, height = mode.width, mode.height
		else -- "desktop"
			width, height = t.deskwidth, t.deskheight
		end
	end
	
	local setmode = (t.fullscreen ~= fs)
	setmode = setmode or (fs and t.fullscreentype ~= fstype)
	setmode = setmode or (t.width ~= width or t.height ~= height)
	--setmode = setmode or (t.vsync ~= vsync)
	
	if not setmode then return end
	
	love.window.setMode(width, height, {
		fullscreen = fs,
		fullscreentype = fstype
	})
	return true
end

Game.getScreenSettings = getScreenSettings
--Game.setmode = setmode

function Game.saveConfig()
	local save = {}
	save.size = settings.size
	save.musicvol = settings.musicvol
	save.soundvol = settings.soundvol
	save.theme = settings.themename
	save.highlight = settings.highlight
	
	save.windowwidth  = settings.windowwidth
	save.windowheight = settings.windowheight
	save.fullscreen = settings.fullscreen
	save.fullscreentype = settings.fullscreentype
	save.fsname = settings.fsname
	
	local grid = Game.getState("MainGame").grid
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
	
	Game.themes.setTheme(settings, save.theme)
	


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

local clamp = function(x, a, b)
	if x < a then return a end
	if x > b then return b end
	return x
end

function Game.applyScreenSettings()
	local t = getScreenSettings()
	
	settings.windowwidth  = clamp(settings.windowwidth,  Game.minwidth,  t.deskwidth)
	settings.windowheight = clamp(settings.windowheight, Game.minheight, t.deskheight)
	
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
	settings.fsname = fsname
	
	local newmode = setMode(settings.windowwidth, settings.windowheight,
		settings.fullscreen, settings.fullscreentype, fsindex)
	
	if newmode then
		Game.width, Game.height = love.graphics.getDimensions()
	else
		print("same mode")
	end
end
