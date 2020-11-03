local serpent = require "serpent"

local clamp = function(x, a, b)
	if x < a then return a end
	if x > b then return b end
	return x
end

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
	save.theme = Game.theme.name
	save.highlight = Game.highlight
	
	save.windowwidth  = Game.windowwidth
	save.windowheight = Game.windowheight
	save.fullscreen = Game.fullscreen
	save.fullscreentype = Game.fullscreentype
	
	--if Game.fsindex > #Game.fsmodes or Game.fsindex < 1 then
	--	Game.fsindex  = 1
	--end
	save.fsindex = Game.fsindex
	
	love.filesystem.write(conffile, serpent.block(save))
end

function Game.quit()
	--Game.saveConfig() called in love.quit
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
	
	local theme = save.theme
	if theme then
		for k, v in pairs(Game.themes) do
			if v.name == theme then
				Game.theme = v
				Game.themeindex = k
				break
			end
		end
	end
	
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
	Game.themenames = {}
	for k, v in ipairs(Game.themes) do Game.themenames[k] = v.name end
	Game.themeindex = 1
	Game.theme = Game.themes[Game.themeindex]
	
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