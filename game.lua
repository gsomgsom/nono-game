local Game = {}

Game.web = love.system.getOS() == "Web"
Game.conffile = "nono_config.txt"
Game.minwidth, Game.minheight = 400, 400
Game.TW, Game.TH = 800, 600 -- target width and height

local settings = {}
Game.settings = settings

function Game.defaultSettings()
	local ss = Game.getScreenSettings()
	Game.width, Game.height = ss.width, ss.height
	Game.sw, Game.sh = Game.width / Game.TW, Game.height / Game.TH
	
	for k, v in pairs(ss) do settings[k] = v end
	
	settings.size = 10
	settings.musicvol = 10
	settings.soundvol = 10
	settings.highlight = false
	
	settings.themename = "Dark"
end

function Game.onQuit() -- default quit even for all states
	Game.saveConfig()
	return false
end

function Game.quit(restart) -- this should trigger love.quit
	if restart then return love.event.quit("restart") end
	love.event.push("quit")
end

function Game.load()
	require(Game.web and "saveload_web" or "saveload")

	Game.defaultSettings()
	Game.loadConfig()
	
	require("themes")(Game)
	Game.applyTheme(settings.themename)
	Game.gui = require("gui")(settings.theme, Game.fonts.large)
	
	require("states")(Game)
	
	local grid = Game.loadedGrid
	if grid then
		Game.getState("MainGame"):newGame(grid.size, grid.seed, grid)
	end

	
end

return Game