local Game = require "game"
local settings = Game.settings

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
	graphics = graphics, music = music, sounds = sounds,
	colors = {
		background = {0.9, 0.9, 0.9},
		main       = {0.2, 0.7, 0.9},
		text       = {0.3, 0.3, 0.3},
		disabled   = {0.7, 0.7, 0.7},
		set        = {0.2, 0.2, 0.2},
		unset      = {0.7, 0.7, 0.7},
		highlight  = {0.9, 0.87, 0.6},
	},
}


local theme_dark = {
	name = "Dark",
	graphics = graphics, music = music, sounds = sounds,
	colors = {
		background = {0.1, 0.1, 0.1},
		main       = {0.2, 0.4, 0.6},
		text       = {0.7, 0.7, 0.7},
		disabled   = {0.3, 0.3, 0.3},
		set        = {0.7, 0.7, 0.7},
		unset      = {0.25, 0.25, 0.25},
		highlight  = {0.18, 0.18, 0.14},
	},
}

local theme_neon = {
	name = "Neon",
	graphics = graphics, music = music, sounds = sounds,
	colors = {
		background = {0.2, 0.1, 0.2},
		main       = {1.0, 0.6, 0.4},
		text       = {0.7, 1.0, 0.7},
		disabled   = {0.3, 0.3, 0.3},
		set        = {0.1, 0.3, 1.0},
		unset      = {0.0, 0.1, 0.3},
		highlight  = {0.35, 0.1, 0.25},
	},
}

local themes = {theme_dark, theme_light, theme_neon}
local currentTheme = {} -- shallow copy of current theme (reference)

local setTheme = function(theme)
	for k, v in pairs(theme) do
		currentTheme[k] = v
	end
end

local applyTheme = function(theme)
	local music  = theme.music
	local sounds = theme.sounds
	
	for k, v in pairs(music) do
		music[k]:setVolume(settings.musicvol / 10)
	end
	for k, v in pairs(sounds) do
		sounds[k]:setVolume(settings.soundvol / 10)
	end
	
	if currentTheme.music ~= music then
		for k, v in pairs(currentTheme.music) do v:stop() end
	end
	
	if currentTheme.sounds ~= sounds then
		for k, v in pairs(currentTheme.sounds) do v:stop() end
	end
	
	setTheme(theme)
	
	if music.default then
		music.default:setLooping(true)
		love.audio.play(music.default)
	end
	
	love.graphics.setBackgroundColor(theme.colors.background)
end


local findTheme = function(themename)
	for k, v in pairs(themes) do
		if v.name == themename then return v end
	end
	print("unknown theme", themename)
end

local setThemeByName = function(themename)
	local theme = findTheme(themename)
	if not theme then return end
	setTheme(theme)
end

local applyThemeByName = function(themename)
	local theme = findTheme(themename)
	if not theme then return end
	applyTheme(theme)
end


setTheme(themes[1]) -- set to first

-- Variables
Game.setTheme = setThemeByName
Game.applyTheme = applyThemeByName
Game.theme = currentTheme

--Game.themes = {theme_dark, theme_light}
--for k, v in ipairs(Game.themes) do Game.themes[v.name] = v end

Game.themenames = {}
for k, v in ipairs(themes) do Game.themenames[k] = v.name end
