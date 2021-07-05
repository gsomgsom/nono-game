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

-- Main Menu State
local Menu = class("MainMenu", Classes.Base)

function Menu:init()
	Classes.Base.init(self)

	local sw, sh = Game.sw, Game.sh
	
	self.logo = settings.theme.graphics.logo
	local logow, logoh = self.logo:getDimensions()
	self.logox = _floor(400 * sw - logow / 2)
	self.logoy = _floor(25 * sh)
	
	local font = Game.fonts.huge
	local advance = _floor(font:getHeight() * 1)
	
	local x, y = _floor(400 * sw), self.logoy + logoh + advance
	
	local newgameButton = Button(x, y, 0, "center")
		:setText("New Game", font)
	newgameButton.onclick = function(uibutton)
		States.MainGame:newGame()
		setState("MainGame")
	end
	
	y = y + advance
	
	local continueButton = Button(x, y, 0, "center")
		:setText("Continue", font)
	continueButton.onclick = function(uibutton)
		if States.MainGame.time then -- if there is an ongoing game
			setState("MainGame")
		end
	end
	continueButton:setEnabled(false)
	
	y = y + advance
	
	local optionsButton = Button(x, y, 0, "center")
		:setText("Options", font)
	optionsButton.onclick = function(uibutton)
		setState("OptionsMenu")
	end
	
	y = _floor(600 * sh) - 2 * advance
	local restartButton = Button(x, y, 0, "center")
		:setText("Restart", font)
	restartButton.onclick = function()
		Game.quit("restart")
	end

	y = y + advance
	local quitButton = Button(x, y, 0, "center")
		:setText("Quit", font)
	quitButton.onclick = function()
		Game.quit()
	end
	
	self.buttons = {newgameButton, continueButton, optionsButton}
	if not Game.web then table.insert(self.buttons, quitButton) end
	
	self.continueButton = continueButton

	return self
end

function Menu:draw()
	local sw, sh = Game.sw, Game.sh
	
	love.graphics.setColor(settings.theme.colors.main)
	love.graphics.draw(self.logo, self.logox, self.logoy)
	
	for n,b in ipairs(self.buttons) do
		b:draw()
	end
end

function Menu:mousemoved(x,y,dx,dy)
	for k, b in ipairs(self.buttons) do
		b:mousemoved(x,y,dx,dy)
	end
end

function Menu:mousepressed(x,y,button)
	for n,b in ipairs(self.buttons) do
		b:mousepressed(x,y,button)
	end
end

function Menu:mousereleased(x,y,button)
	for n,b in ipairs(self.buttons) do
		b:mousereleased(x,y,button)
	end
end

function Menu:textinput(text)
	for n,b in ipairs(self.buttons) do
		b:textinput(text)
	end
end

function Menu:keypressed(key, scancode)
	for n,b in ipairs(self.buttons) do
		b:keypressed(key, scancode)
	end
end

Classes[Menu.name] = Menu

----- MODULE FUNCTION END -----
end --return function(Game)
---------------------------------
