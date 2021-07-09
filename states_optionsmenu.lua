local _floor, _ceil = math.floor, math.ceil
local _sf = string.format

local simpleclass = require "simpleclass"
local noop = simpleclass._noop
local class = simpleclass.class

----- MODULE FUNCTION START -----
return function(Game)
---------------------------------

local settings = Game.settings

local Button = Game.gui.Button
local Toggler = Game.gui.Toggler
local Slider = Game.gui.Slider
local Cycler = Game.gui.Cycler
local Typer  = Game.gui.Typer

local States = Game.States
local Classes = Game.stateClasses
local setState = Game.setState

-- Options State
local Options = class("OptionsMenu", Classes.Base)

function Options:init_game(x0, y0, width)
	local font = Game.fonts.huge
	local header = love.graphics.newText(font)
	header:addf("Options (Game)", width, "center", x0, y0)
	
	local x, y = x0 + _floor(width / 2 + 5), y0 + header:getHeight()

	font = Game.fonts.default
	local labels = love.graphics.newText(font)
	local labelw = x - x0 - 5
	local limit = _floor(font:getWidth("<99>"))
	local advance = _floor(font:getHeight() * 1)
	
	labels:addf("Theme:", x - x0 - 5, "right", x0, y)
	local themeCycler = Cycler(x, y, 0, nil, font):set(Game.themeNames, settings.themename)
	themeCycler.onclick = function(uibutton, index, value)
		Game.applyTheme(value)
		Game.gui.theme = settings.theme
	end
	
	y = y + advance
	
	labels:addf("Grid Size:", labelw, "right", x0, y)
	local sizeSlider = Slider(x, y, limit, nil, font):set(settings.size, 4, 25)
	sizeSlider.onclick = function(uislider, change)
		settings.size = uislider.value
	end
	
	y = y + advance
	
	labels:addf("Music:", labelw, "right", x0, y)
	local musicSlider = Slider(x, y, limit, nil, font):set(settings.musicvol, 0, 10)
	musicSlider.onclick = function(uislider, change)
		settings.musicvol = uislider.value
		for k, v in pairs(settings.theme.music) do
			v:setVolume(settings.musicvol / 10)
		end
	end
	
	y = y + advance
	
	labels:addf("Sounds:", labelw, "right", x0, y)
	local soundSlider = Slider(x, y, limit, nil, font):set(settings.soundvol, 0, 10)
	soundSlider.onclick = function(uislider, change)
		settings.soundvol = uislider.value
		for k, v in pairs(settings.theme.sounds) do
			v:setVolume(settings.soundvol / 10)
		end
	end
	
	y = y + advance
	
	labels:addf("Highlight:", labelw, "right", x0, y)
	local hlCycler = Cycler(x, y, 0, nil, font):set({"On", "Off"}, settings.highlight and 1 or 2)
	hlCycler.onclick = function(uibutton, index, value)
		settings.highlight = (index == 1)
	end
	
	self.headers.game = header
	self.labels.game = labels
	self.optionButtons.game = {musicSlider, soundSlider, sizeSlider, themeCycler, hlCycler}
end

function Options:init_video(x0, y0, width)
	local font = Game.fonts.huge
	local header = love.graphics.newText(font)
	header:addf("Options (Video)", width, "center", x0, y0)
	
	local x, y = x0 + _floor(width / 2 + 5), y0 + header:getHeight()
	
	font = Game.fonts.default
	local labels = love.graphics.newText(font)
	local labelw = x - x0 - 5
	local limit = _floor(font:getWidth("<99>"))
	local advance = _floor(font:getHeight() * 1)

	local fsm = {"Window", "Desktop", "Exclusive"}
	local fsmidx = settings.fullscreen and (settings.fullscreentype == "exclusive" and 3 or 2) or 1
	
	labels:addf("Mode:", labelw, "right", x0, y)
	local fsmodeCycler = Cycler(x, y, 0, nil, font):set(fsm, fsmidx)
	fsmodeCycler.onclick = function(uibutton, index, value)
		settings.fullscreentype = nil
		if index == 1 then settings.fullscreen = false return end
		
		settings.fullscreen = true
		if index == 2 then settings.fullscreentype = "desktop" return end
		
		settings.fullscreentype = "exclusive"
	end
	
	y = y + advance
	
	labels:addf("Width:", labelw, "right", x0, y)
	local dw, dh = love.window.getDesktopDimensions()
	limit = font:getWidth("<8888>")
	
	local wwSlider = Slider(x, y, limit, nil, font):set(settings.windowwidth, Game.minwidth, dw)
	wwSlider.onclick = function(uislider, change)
		settings.windowwidth = uislider.value
	end
	
	y = y + advance

	labels:addf("Height:", labelw, "right", x0, y)
	
	local whSlider = Slider(x, y, limit, nil, font):set(settings.windowheight, Game.minheight, dh)
	whSlider.onclick = function(uislider, change)
		settings.windowheight = uislider.value
	end

	y = y + advance
	
	labels:addf("Fullscreen:", labelw, "right", x0, y)
	local fssizeCycler = Cycler(x, y, 0, nil, font):set(settings.fsmodenames, settings.fsname, font)
	fssizeCycler.onclick = function(uibutton, index, value)
		settings.fsname = settings.fsmodenames[index]
	end
	
	self.labels.video = labels
	self.optionButtons.video = {fsmodeCycler, wwSlider, whSlider, fssizeCycler}
	self.headers.video =  header
end

function Options:init()
	Classes.Base.init(self)
	
	local extended = true --not Game.web
	
	local sw, sh = Game.sw, Game.sh
	
	local font = Game.fonts.large
	
	--local headerx, headery = _floor(10 * sw + font:getWidth("Mmmmm")), _floor(5 * sh)
	local headerx, headery = _floor(10 * sw), _floor(5 * sh)
	local headerh = Game.fonts.huge:getHeight()
	
	local advance = _floor(font:getHeight() * 1)
	local x, y
	
	local gameButton, videoButton, restartButton
	if extended then
		x, y = _floor(5 * sw), headery + headerh
		
		gameButton = Toggler(x, y, 0, nil, font):setText("Game")
		gameButton.onclick = function(uibutton, a, b)
			self.currentButtons = self.optionButtons.game
			self.currentLabels = self.labels.game
			self.currentHeader = self.headers.game
		end
		
		y = y + advance
		
		videoButton = Toggler(x, y, 0, nil, font):setText("Video")
		videoButton.onclick = function(uibutton, a, b)
			self.currentButtons = self.optionButtons.video
			self.currentLabels = self.labels.video
			self.currentHeader = self.headers.video
		end
	
		local togglegroup = {gameButton, videoButton}
		gameButton.group = togglegroup
		videoButton.group = togglegroup
				
		--x = _floor(400 * sw)
		y = _floor(600 * sh) - 2 * advance
		
		restartButton = Button(x, y, 0, "left"):set("Restart", font)
		restartButton.onclick = function(uibutton)
			Game.quit("restart")
		end
	end
	
	x, y = _floor(5 * sw), _floor(600 * sh) - advance
	local backButton = Button(x, y, 0, "left"):set("Back", font)
	backButton.onclick = function(uibutton)
		setState("MainMenu")
	end
	
	self.labels = {}
	self.headers = {}
	self.optionButtons = {}
	
	x, y = headerx, headery
	self:init_game(x, y, 800 * sw)
	
	if extended then
		self.buttons = {gameButton, videoButton, backButton, restartButton}
		self:init_video(x, y, 800 * sw)
		table.insert(self.buttons, restartButton)
	else
		self.buttons = {backButton}
	end
	
	gameButton.on = true
	self.currentButtons = self.optionButtons.game
	self.currentLabels = self.labels.game
	self.currentHeader = self.headers.game

	return self
end

function Options:draw()
	local colors = settings.theme.colors
	local sw, sh = Game.sw, Game.sh
	love.graphics.setColor(colors.main)
	love.graphics.draw(self.currentHeader)
	
	love.graphics.setColor(colors.text)
	love.graphics.draw(self.currentLabels)
	
	for n,b in ipairs(self.buttons) do
		b:draw()
	end
	for n,b in ipairs(self.currentButtons) do
		b:draw()
	end
end

function Options:mousemoved(x, y, dx, dy)
	for k, b in ipairs(self.buttons) do
		b:mousemoved(x, y, dx, dy)
	end
	for k, b in ipairs(self.currentButtons) do
		b:mousemoved(x, y, dx, dy)
	end
end

function Options:mousepressed(x,y,button)
	for k, b in ipairs(self.buttons) do
		b:mousepressed(x,y,button)
	end
	for k, b in ipairs(self.currentButtons) do
		b:mousepressed(x,y,button)
	end
end

function Options:mousereleased(x, y, button)
	for k, b in ipairs(self.buttons) do
		b:mousereleased(x, y, button)
	end
	for k, b in ipairs(self.currentButtons) do
		b:mousereleased(x, y, button)
	end
end

function Options:update(dt)
	for k, b in ipairs(self.buttons) do
		b:update(dt)
	end
	for k, b in ipairs(self.currentButtons) do
		b:update(dt)
	end
end

--[[
function Options:textinput(text)
	self.fgInput:textinput(text)
end

function Options:keypressed(k, sc)
	self.fgInput:keypressed(k, sc)
end
]]

Classes[Options.name] = Options

----- MODULE FUNCTION END -----
end --return function(Game)
---------------------------------
