local FONTSCALE = 1.44497 -- VenrynSans

local getFontHeight = function(pt)
	return math.floor(FONTSCALE * pt + 0.5)
end

local getFontPoint = function(px)
	return math.floor(px / FONTSCALE + 0.5)
end

local newFont = function(pt)
	return love.graphics.newFont("media/VenrynSans-Regular.ttf", math.max(8, pt))
end

local clamp = function(x, a, b)
	if x < a then return a end
	if x > b then return b end
	return x
end

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


local Game = {}

Game.web = love.system.getOS() == "Web"
Game.conffile = "nono_config.txt"
local MINWIDTH, MINHEIGHT = 400, 400
Game.minwidth, Game.minheight = MINWIDTH, MINHEIGHT

Game.newFont = function(px)
	return newFont(getFontPoint(px))
end

local settings = {}
Game.settings = settings

function Game.applyScreenSettings()
	local t = getScreenSettings()
	
	settings.windowwidth  = clamp(settings.windowwidth,  MINWIDTH, t.deskwidth)
	settings.windowheight = clamp(settings.windowheight, MINHEIGHT, t.deskheight)
	
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

function Game.defaultSettings()
	local ss = getScreenSettings()
	Game.width, Game.height = ss.width, ss.height
	for k, v in pairs(ss) do settings[k] = v end
	
	settings.size = 10
	settings.musicvol = 10
	settings.soundvol = 10
	settings.highlight = false
end

function Game.onQuit() -- called in love.quit
	Game.saveConfig()
	return false
end

function Game.quit(restart)
	if restart then return love.event.quit("restart") end
	
	love.event.push("quit")
end

function Game.load()
	Game.defaultSettings()

	require(Game.web and "saveload_web" or "saveload")
	require "themes"
	Game.loadConfig()
	
	Game.applyTheme(Game.theme.name)
	
	Game.sw, Game.sh = Game.width / 800, Game.height / 600
	
	local smin = Game.sh --math.min(Game.sw, Game.sh)
	local fonts = {
		huge    = newFont(getFontPoint(60 * smin)),
		large   = newFont(getFontPoint(45 * smin)),
		default = newFont(getFontPoint(38 * smin)),
		small   = newFont(getFontPoint(28 * smin)),
		tiny    = newFont(getFontPoint(22 * smin)),
		itsy    = newFont(getFontPoint(16 * smin)),
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