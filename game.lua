local serpent = require "serpent"

local conffile = "nono_config.txt"

local Game = {}

function Game.setState(state)
	state:mousemoved(love.mouse.getPosition())
	Game.state = state
end

function Game.saveConfig()
	local save = {}
	save.size = Game.size
	save.musicvol = Game.musicvol
	save.soundvol = Game.soundvol
	save.width, save.height = Game.width, Game.height
	save.fullscreen = Game.fullscreen
	save.fullscreentype = Game.fullscreentype
	save.theme = Game.theme.name
	save.highlight = Game.highlight
	love.filesystem.write(conffile, serpent.block(save))
end

function Game.quit()
	--Game.saveConfig() called in love.quit
	love.event.push("quit")
end

function Game.loadConfig()
	local saved, ok = love.filesystem.read(conffile)
	if saved then
		ok, saved = serpent.load(saved)
	end
	
	if not saved then
		return
	end
	
	if saved.size then Game.size = saved.size end
	if saved.musicvol then Game.musicvol = saved.musicvol end
	if saved.soundvol then Game.soundvol = saved.soundvol end
	if saved.highlight ~= nil then Game.highlight = saved.highlight end
	
	local setmode = false
	
	local fs, fstype, width, height = saved.fullscreen, saved.fullscreentype, saved.width, saved.height
	
	if fs ~= nil then
		if Game.fullscreen ~= fs then setmode = true end
		Game.fullscreen = fs
	end
	if fstype then
		if Game.fullscreentype ~= fstype then setmode = true end
		Game.fullscreentype = fstype
	end
	if width and height and (Game.width ~= width or Game.height ~= height) then
		Game.width, Game.height = width, height
		setmode = true
	end

	
	if setmode then
		love.window.setMode(Game.width, Game.height, {
			fullscreen = Game.fullscreen,
			fullscreentype = Game.fullscreentype
		})
		Game.width, Game.height = love.graphics.getDimensions()
		Game.fullscreen, Game.fullscreentype = love.window.getFullscreen()
	end
	
	local theme = saved.theme
	if theme then
		for k, v in pairs(Game.themes) do
			if v.name == theme then Game.theme = v; break end
		end
	end
end

function Game.applyTheme(theme)
	local music  = theme.music
	local sounds = theme.sounds
	
	for k, v in pairs(music) do
		music[k]:setVolume(Game.musicvol/10)
	end
	for k, v in pairs(sounds) do
		sounds[k]:setVolume(Game.soundvol/10)
	end
	
	if Game.music then
		for k, v in pairs(Game.music) do v:stop() end
	end
	
	if Game.sounds then
		for k, v in pairs(Game.sounds) do v:stop() end
	end
	
	Game.music = music
	Game.sounds = sounds
	Game.graphics = theme.graphics
	Game.colors = theme.colors
	
	Game.theme = theme
	
	if music.default then
		music.default:setLooping(true)
		love.audio.play(music.default)
	end
	
	love.graphics.setBackgroundColor(theme.colors.background)
end

function Game.load()
	local graphics = {
		logo = love.graphics.newImage("media/logo.png"),
		set = love.graphics.newImage("media/set.png"),
		notset = love.graphics.newImage("media/notset.png")
	}
	
	local music = {
		--default = love.audio.newSource("media/music.ogg", "stream")
	}
	
	local sounds = {
		click = love.audio.newSource("media/click.ogg", "static"),
		pling = love.audio.newSource("media/pling.ogg", "static")
	}
	
	local theme_light = {
		name = "Light",
		graphics = graphics, music = {}, sounds = sounds,
		colors = {
			background = {0.9, 0.9, 0.9},
			main       = {0.2, 0.7, 0.9},
			text       = {0.3, 0.3, 0.3},
			disabled   = {0.7, 0.7, 0.7},
			set        = {0.2, 0.2, 0.2},
			unset      = {0.7, 0.7, 0.7},
			highlight  = {0.8, 0.8, 0.7},
		},
	}
	
	
	local theme_dark = {
		name = "Dark",
		graphics = graphics, music = music, sounds = sounds,
		colors = {
			background = {0.1, 0.1, 0.1},
			main       = {0.1, 0.3, 0.5},
			text       = {0.7, 0.7, 0.7},
			disabled   = {0.3, 0.3, 0.3},
			set        = {0.7, 0.7, 0.7},
			unset      = {0.2, 0.2, 0.2},
			highlight  = {0.15, 0.15, 0.1},
		},
	}
	
	-- Variables
	Game.themes = {theme_dark, theme_light}
	
	Game.theme = Game.themes[1]
	Game.width, Game.height = love.graphics.getDimensions()
	Game.fullscreen, Game.fullscreentype = love.window.getFullscreen()
	
	Game.size = 10
	Game.musicvol = 10
	Game.soundvol = 10
	Game.highlight = false
	
	Game.loadConfig()
	
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
	
	Game.applyTheme(Game.theme)
	
	
	

	require("button")
	
	require("states")
	
	Game.setState(Game.States.Menu)
	

	
end

return Game