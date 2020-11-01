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
	save.theme = Game.theme.name
	save.highlight = Game.highlight
	love.filesystem.write(conffile, serpent.dump(save))
end

function Game.quit()
	--Game.saveConfig() called in love.quit
	love.event.push("quit")
end

function Game.loadConfig()
	local saved, ok = love.filesystem.read(conffile)
	if saved then
		ok, saved = serpent.load(saved)
		if not ok then saved = {} end
	else saved = {} end
	
	Game.size     = saved.size or 10
	Game.musicvol = saved.musicvol or 10
	Game.soundvol = saved.soundvol or 10
	Game.highlight = saved.highlight
	
	Game.width, Game.height = saved.width, saved.height
	if not Game.width or not Game.height then
		Game.width, Game.height = love.graphics.getDimensions()
	end
	Game.fullscreen = not not saved.fullscreen
	
	love.window.setMode(Game.width, Game.height, {
		fullscreen = Game.fullscreen,
		fullscreentype = "desktop"
	})
	
	local themename, theme = saved.theme, nil
	for k, v in pairs(Game.themes) do
		if v.name == themename then theme = v; break end
	end
	if not theme then theme = Game.themes[1] end
	Game.applyTheme(theme)
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
	
	-- Resources
	local fonts = {
		default = love.graphics.newFont(24),
		large = love.graphics.newFont(32),
		huge = love.graphics.newFont(72),
		small = love.graphics.newFont(20),
		tiny = love.graphics.newFont(16),
		itsy = love.graphics.newFont(10),
	}
	
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
		},
	}
	
	-- Variables
	Game.fonts = fonts
	
	Game.themes = {theme_dark, theme_light}
	
	Game.loadConfig()
	
	
	Game.sw, Game.sh = Game.width / 800, Game.height / 600

	require("button")
	
	require("states")
	
	Game.setState(Game.States.Menu)
	

	
end

return Game