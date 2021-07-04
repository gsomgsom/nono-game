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

-- Pause Menu State
local PauseMenu = class("PauseMenu", Classes.Base)

function PauseMenu:init()
	local sw, sh = Game.sw, Game.sh
	local x, y = _floor(400 * sw), _floor(600 * sh)
	
	local font = Game.fonts.huge
	local advance = _floor(font:getHeight() * 1)
	
	y = y - 2 * advance

	local continueButton = Button(x, y, 0, "center", font):set("Continue")
	continueButton.onclick = function()
		if States.MainGame.time then
			setState("MainGame")
		end
	end
	
	y = y + advance
	local quitButton = Button(x, y, 0, "center", font):set("Quit")
	quitButton.onclick = function()
		Game.quit()
	end
	
	self.buttons = {continueButton}
	if not Game.web then table.insert(self.buttons, quitButton) end

	self.logo = settings.theme.graphics.logo
	local logow, logoh = self.logo:getDimensions()
	self.logox = _floor(400 * sw - logow / 2)
	self.logoy = _floor(25 * sh)
	
	return self
end

function PauseMenu:draw()
	local sw, sh = Game.sw, Game.sh
	
	local colors = settings.theme.colors
	local fonts = Game.fonts
	
	love.graphics.setColor(colors.main)
	love.graphics.draw(self.logo, self.logox, self.logoy)
	
	love.graphics.setColor(colors.text)
	love.graphics.setFont(fonts.huge)
	local x, y, limit = 0, 200 * sh, 800 * sw
	if States.MainGame.win then
		love.graphics.printf(string.format("SOLVED:\n%.1fs", States.MainGame.win),
			x, y, limit, "center")
	else
		love.graphics.printf(string.format("ELAPSED:\n%.1fs", States.MainGame.time),
			x, y, limit, "center")
	end
	
	for n,b in ipairs(self.buttons) do
		b:draw()
	end
end

function PauseMenu:mousemoved(x,y,dx,dy)
	for k, b in ipairs(self.buttons) do
		b:mousemoved(x,y,dx,dy)
	end
end

function PauseMenu:mousepressed(x,y,button)
	for n,b in ipairs(self.buttons) do
		b:mousepressed(x,y,button)
	end
end

function PauseMenu:mousereleased(x,y,button)
	for n,b in ipairs(self.buttons) do
		b:mousereleased(x,y,button)
	end
end

function PauseMenu:textinput(text)
	for n,b in ipairs(self.buttons) do
		b:textinput(text)
	end
end

function PauseMenu:keypressed(key, scancode)
	for n,b in ipairs(self.buttons) do
		b:keypressed(key, scancode)
	end
end

Classes[PauseMenu.name] = PauseMenu

----- MODULE FUNCTION END -----
end --return function(Game)
---------------------------------
