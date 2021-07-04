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

local Game = {}

Game.web = love.system.getOS() == "Web"
Game.conffile = "nono_config.txt"
Game.minwidth, Game.minheight = 400, 400

Game.newFont = function(px)
	return newFont(getFontPoint(px))
end

local settings = {}
Game.settings = settings

function Game.defaultSettings()
	local ss = Game.getScreenSettings()
	Game.width, Game.height = ss.width, ss.height
	for k, v in pairs(ss) do settings[k] = v end
	
	settings.size = 10
	settings.musicvol = 10
	settings.soundvol = 10
	settings.highlight = false
	
	settings.themename = "Dark"
	Game.themes.setTheme(settings, settings.themename)
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
	require(Game.web and "saveload_web" or "saveload")
	Game.themes = require "themes"
	--Game.applyTheme = function(themename) Game.themes.appleTheme(settings, themename) end
	--Game.setTheme =  function(themename) Game.themes.setTheme(settings, themename) end

	Game.defaultSettings()

	Game.loadConfig()
	
	Game.themes.applyTheme(settings, settings.themename)
	
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
	
	Game.gui = require("gui")(settings.theme, Game.fonts.large)
	
	require("states")
	
	Game.initStates()
	
	local grid = Game.loadedGrid
	if grid then
		Game.getState("MainGame"):newGame(grid.size, grid.seed, grid)
	end

	
end

return Game