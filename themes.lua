local graphics = {
	logo = love.graphics.newImage("media/logo.png"),
	mark1 = love.graphics.newImage("media/set.png"),
	mark0 = love.graphics.newImage("media/notset.png")
}

local graphics_n = {
	logo = graphics.logo,
	mark1 = love.graphics.newImage("media/set_n.png"),
	mark0 = love.graphics.newImage("media/notset_n.png")
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
		mark1      = {0.2, 0.2, 0.2},
		mark0      = {0.7, 0.7, 0.7},
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
		mark1      = {0.7, 0.7, 0.7},
		mark0      = {0.25, 0.25, 0.25},
		highlight  = {0.20, 0.19, 0.05},
	},
}

local theme_neon = {
	name = "Neon",
	graphics = graphics_n, music = music, sounds = sounds,
	colors = {
		background = {0.2, 0.1, 0.2},
		main       = {1.0, 0.6, 0.4},
		text       = {0.7, 1.0, 0.7},
		disabled   = {0.3, 0.3, 0.3},
		mark1      = {0.1, 1.0, 0.8},
		mark0      = {0.8, 0.1, 0.5},
		highlight  = {0.3, 0.2, 0.5},
	},
}

local themes = {theme_dark, theme_light, theme_neon}
local themenames = {}
for i, v in ipairs(themes) do
	themenames[i] = v.name
	--themes[v.name] = v
end
themes.names = themenames


local applyTheme = function(settings, theme)
	local music  = theme.music
	local sounds = theme.sounds
	
	for k, v in pairs(music) do
		music[k]:setVolume(settings.musicvol / 10)
	end
	for k, v in pairs(sounds) do
		sounds[k]:setVolume(settings.soundvol / 10)
	end
	
	local currentTheme = settings.theme
	
	if currentTheme ~= theme then
		if currentTheme.music ~= music then
			for k, v in pairs(currentTheme.music) do v:stop() end
		end
		
		if currentTheme.sounds ~= sounds then
			for k, v in pairs(currentTheme.sounds) do v:stop() end
		end
		
		settings.theme = theme
		settings.themename = theme.name
	end
	
	if music.default then
		music.default:setLooping(true)
		love.audio.play(music.default)
	end
	
	love.graphics.setBackgroundColor(theme.colors.background)
end


local findTheme = function(themename)
	for i, v in ipairs(themes) do
		if v.name == themename then return v end
	end
	print("unknown theme", themename)
end

local setThemeByName = function(settings, themename)
	local theme = findTheme(themename)
	if not theme then return end
	settings.theme = theme
	settings.themename = theme.name
end

local applyThemeByName = function(settings, themename)
	local theme = findTheme(themename)
	if not theme then return end
	applyTheme(settings, theme)
end

themes.applyTheme = applyThemeByName
themes.setTheme = setThemeByName

return themes
