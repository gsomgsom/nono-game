local loadMedia = function()
	-- Media used by themes
	local media = {}
	media.logo    = love.graphics.newImage("media/logo.png")
	media.mark1   = love.graphics.newImage("media/set.png")
	media.mark0   = love.graphics.newImage("media/notset.png")
	media.mark1_n = love.graphics.newImage("media/set_n.png")
	media.mark0_n = love.graphics.newImage("media/notset_n.png")

	media.click = love.audio.newSource("media/click.ogg", "static")
	media.pling = love.audio.newSource("media/pling.ogg", "static")
	return media
end

local loadThemes = function(media)
	local graphics = {logo = media.logo, mark1 = media.mark1, mark0 = media.mark0}

	local graphics_n = {logo = media.logo, mark1 = media.mark1_n, mark0 = media.mark0_n}

	local music = {}

	local sounds = {click = media.click, pling = media.pling}

	-- themes
	local themes = {}

	themes[#themes + 1] = {
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


	themes[#themes + 1] = {
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

	themes[#themes + 1] = {
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

	return themes
end

local applyTheme = function(settings, theme)
	local music  = theme.music
	local sounds = theme.sounds
	
	for k, v in pairs(music) do
		music[k]:setVolume(settings.musicvol / 10)
	end
	for k, v in pairs(sounds) do
		sounds[k]:setVolume(settings.soundvol / 10)
	end
	
	local prevtheme = settings.theme
	
	if prevtheme and prevtheme ~= theme then
		if prevtheme.music ~= music then
			for k, v in pairs(prevtheme.music) do v:stop() end
		end
		
		if prevtheme.sounds ~= sounds then
			for k, v in pairs(prevtheme.sounds) do v:stop() end
		end
	end
	
	settings.theme = theme
	settings.themename = theme.name
	
	if music.default then
		music.default:setLooping(true)
		love.audio.play(music.default)
	end
	
	love.graphics.setBackgroundColor(theme.colors.background)
end


local findTheme = function(themes, themename)
	for i, v in ipairs(themes) do
		if v.name == themename then return v end
	end
	print("unknown theme", themename)
end

local applyThemeByName = function(settings, themes, themename)
	local theme = findTheme(themes, themename)
	if not theme then
		if not settings.theme then theme = themes[1]
		else return end
	end
	applyTheme(settings, theme)
end

local loadIcons = function()
	-- Icons used by options menu
	local icons = {}
	icons.newgame = love.graphics.newImage("media/2x/star.png")
	icons.pause   = love.graphics.newImage("media/2x/pause.png")
	icons.undo    = love.graphics.newImage("media/2x/rewind.png")
	icons.reset   = love.graphics.newImage("media/2x/return.png")
	icons.back    = love.graphics.newImage("media/2x/arrowLeft.png")
	return icons
end

-- Fonts
--local FONTFILE  = "media/VenrynSans-Regular.ttf"
local FONTFILE  = "media/Jost-500-Medium.otf"
local FONTSCALE = 1.44497 -- for VenrynSans/Jost

local newFont = function(pixelheight)
	local pointsize = math.floor(pixelheight / FONTSCALE + 0.5)
	return love.graphics.newFont(FONTFILE, math.max(8, pointsize))
end

local function loadFonts(scale)
	local fonts = {
		huge    = newFont(64 * scale),
		large   = newFont(56 * scale),
		default = newFont(48 * scale),
		small   = newFont(32 * scale),
		tiny    = newFont(24 * scale),
		itsy    = newFont(16 * scale),
	}
	return fonts
end

-- Game integration
return function(Game)
	Game.media = loadMedia()
	Game.themes = loadThemes(Game.media)
	Game.themeNames = {}
	for i, v in ipairs(Game.themes) do
		Game.themeNames[i] = v.name
	end
	Game.applyTheme = function(themename)
		applyThemeByName(Game.settings, Game.themes, themename)
	end

	Game.icons = loadIcons()

	Game.fonts = loadFonts(Game.sh)
	Game.newFont = newFont
end
