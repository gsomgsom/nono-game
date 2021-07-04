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
local Slider = Game.gui.Slider
local Cycler = Game.gui.Cycler
local Typer  = Game.gui.Typer

local States = Game.States
local Classes = Game.stateClasses
local setState = Game.setState

-- Options State
local Options = class("OptionsMenu", Classes.Base)

function Options:init()
	local font = Game.fonts.default
	local labels = love.graphics.newText(font)
	
	local sw, sh = Game.sw, Game.sh
	
	self.logo = settings.theme.graphics.logo
	local logow, logoh = self.logo:getDimensions()
	self.logox = _floor(400 * sw - logow / 2)
	self.logoy = _floor(25 * sh)
	
	local x, y = _floor(400 * sw + 10), _floor(self.logoy + logoh)
	local limit = _floor(font:getWidth("<99>"))
	local advance = _floor(font:getHeight() * 1)
	
	labels:addf("Theme:", x - 10, "right", 0, y)
	local themeCycler = Cycler(x, y, 0, nil, font):set(Game.themes.names, settings.themename)
	themeCycler.onclick = function(uibutton, index, value)
		Game.themes.applyTheme(settings, value)
		Game.gui.theme = settings.theme
	end
	
	y = y + advance
	
	labels:addf("Grid Size:", x - 10, "right", 0, y)
	local sizeSlider = Slider(x, y, limit, nil, font):set(settings.size, 4, 25)
	sizeSlider.onclick = function(uislider, change)
		settings.size = uislider.value
	end
	
	y = y + advance
	
	labels:addf("Music:", x - 10, "right", 0, y)
	local musicSlider = Slider(x, y, limit, nil, font):set(settings.musicvol, 0, 10)
	musicSlider.onclick = function(uislider, change)
		settings.musicvol = uislider.value
		for k, v in pairs(settings.theme.music) do
			v:setVolume(settings.musicvol / 10)
		end
	end
	
	y = y + advance
	
	labels:addf("Sounds:", x - 10, "right", 0, y)
	local soundSlider = Slider(x, y, limit, nil, font):set(settings.soundvol, 0, 10)
	soundSlider.onclick = function(uislider, change)
		settings.soundvol = uislider.value
		for k, v in pairs(settings.theme.sounds) do
			v:setVolume(settings.soundvol / 10)
		end
	end
	
	y = y + advance
	
	labels:addf("Highlight:", x - 10, "right", 0, y)
	local hlCycler = Cycler(x, y, 0, nil, font):set({"On", "Off"}, settings.highlight and 1 or 2)
	hlCycler.onclick = function(uibutton, index, value)
		settings.highlight = (index == 1)
	end
	
	y = y + advance
	
	local fsm = {"Window", "Desktop", "Exclusive"}
	local fsmidx = settings.fullscreen and (settings.fullscreentype == "exclusive" and 3 or 2) or 1
	
	labels:addf("Mode:", x - 10, "right", 0, y)
	local fsmodeCycler = Cycler(x, y, 0, nil, font):set(fsm, fsmidx)
	fsmodeCycler.onclick = function(uibutton, index, value)
		settings.fullscreentype = nil
		if index == 1 then settings.fullscreen = false return end
		
		settings.fullscreen = true
		if index == 2 then settings.fullscreentype = "desktop" return end
		
		settings.fullscreentype = "exclusive"
	end
	

	y = y + advance
	
	labels:addf("Window Size:", x - 10, "right", 0, y)
	local dw, dh = love.window.getDesktopDimensions()
	limit = _floor(font:getWidth(_sf("<%s>", math.max(dw, dh))))
	
	local wwSlider = Slider(x, y, limit, nil, font):set(settings.windowwidth, Game.minwidth, dw)
	wwSlider.onclick = function(uislider, change)
		settings.windowwidth = uislider.value
	end
	
	local xw = font:getWidth(" x ")
	labels:addf("x", 2 * limit + xw, "center", x, y)
	
	local whSlider = Slider(x + limit + xw, y, limit, nil, font):set(settings.windowheight, Game.minheight, dh)
	whSlider.onclick = function(uislider, change)
		settings.windowheight = uislider.value
	end

	y = y + advance
	
	labels:addf("Fullscreen Size:", x - 10, "right", 0, y)
	local fssizeCycler = Cycler(x, y, 0, nil, font):set(settings.fsmodenames, settings.fsname, font)
	fssizeCycler.onclick = function(uibutton, index, value)
		settings.fsname = settings.fsmodenames[index]
	end

	--[[
	y = y + advance
	local color = settings.theme.colors.highlight
	local fgInput = Typer(x, y, font:getWidth("AAAAAA"), nil, font)
	fgInput:setText("FF0000")
	fgInput.color = color
	fgInput.ontextinput = function(typer, text)
		if tonumber(text, 16) and #typer.buffer < 6 then
			return text:upper()
		end
	end
	
	fgInput.onchange = function(typer, buffer, prevtext)
		local r, g, b
		local bufferlen = #buffer
		if bufferlen == 6 then
			r,g,b = buffer:match("(%x%x)(%x%x)(%x%x)")
			if r then 
				if not typer.color then typer.color = {} end
				typer.color[1] = tonumber(r, 16) / 255
				typer.color[2] = tonumber(g, 16) / 255
				typer.color[3] = tonumber(b, 16) / 255
				if not typer.bgcolor then typer.bgcolor = {} end
				typer.bgcolor[1] = 1 - typer.color[1]
				typer.bgcolor[2] = 1 - typer.color[2]
				typer.bgcolor[3] = 1 - typer.color[3]
				return buffer
			end
		end
		return prevtext
	end
	self.fgInput = fgInput
	]]
	
	font = Game.fonts.large
	advance = _floor(font:getHeight() * 1)
	y = _floor(600 * sh) - 2 * advance
	
	local restartButton = Button(x, y, 0, "center"):set("Restart", font)
	restartButton.onclick = function(uibutton)
		Game.quit("restart")
	end
	
	y = y + advance
	
	local backButton = Button(x, y, 0, "center"):set("Back", font)
	backButton.onclick = function(uibutton)
		setState("MainMenu")
	end
		
	self.buttons = {
		musicSlider, soundSlider, sizeSlider, themeCycler, hlCycler, 
		fsmodeCycler, wwSlider, whSlider, fssizeCycler, --fgInput,
		backButton
	}
	
	if Game.web then
		fsmodeCycler:setEnabled(false); fssizeCycler:setEnabled(false)
		wwSlider:setEnabled(false); whSlider:setEnabled(false)
	else
		table.insert(self.buttons, restartButton)
	end
	
	self.labels = labels
	
	return self
end

function Options:draw()
	local colors = settings.theme.colors
	local sw, sh = Game.sw, Game.sh
	love.graphics.setColor(colors.main)
	love.graphics.draw(self.logo, self.logox, self.logoy)
	
	love.graphics.setColor(colors.text)
	love.graphics.draw(self.labels)
	
	for n,b in ipairs(self.buttons) do
		b:draw()
	end

end

function Options:mousemoved(x, y, dx, dy)
	for k, b in ipairs(self.buttons) do
		b:mousemoved(x, y, dx, dy)
	end
end

function Options:mousepressed(x,y,button)
	for k, b in ipairs(self.buttons) do
		b:mousepressed(x,y,button)
	end
end

function Options:mousereleased(x, y, button)
	for k, b in ipairs(self.buttons) do
		b:mousereleased(x, y, button)
	end
end

function Options:update(dt)
	for k, b in ipairs(self.buttons) do
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
