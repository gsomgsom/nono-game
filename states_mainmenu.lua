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

function Menu:updateLayout()
	local lineh = 1
	local sw, sh = Game.sw, Game.sh
	
	self.logo = settings.theme.graphics.logo
	local logow, logoh = self.logo:getDimensions()
	self.logox = _floor(400 * sw - logow / 2)
	self.logoy = _floor(25 * sh)
	
	local font = Game.fonts.huge
	local advance = _floor(font:getHeight() * lineh)
	
	local x, y = _floor(400 * sw), self.logoy + logoh + advance
	
	local newgameButton = self.newgameButton
	newgameButton:init(x, y, 0, "center")
	newgameButton:setText("New Game", font)
	
	y = y + advance
	local continueButton = self.continueButton
	continueButton:init(x, y, 0, "center")
	continueButton:setText("Continue", font)
	
	y = y + advance
	local optionsButton = self.optionsButton
	optionsButton:init(x, y, 0, "center")
	optionsButton:setText("Options", font)
	
	y = _floor(600 * sh) - 2 * advance
	local restartButton = self.restartButton
	restartButton:init(x, y, 0, "center")
	restartButton:setText("Restart", font)

	y = y + advance
	local quitButton = self.quitButton
	quitButton:init(x, y, 0, "center")
	quitButton:setText("Quit", font)
end

function Menu:init()
	Classes.Base.init(self)
	
	local newgameButton = Button()
	newgameButton.onclick = function(uibutton)
		States.MainGame:newGame()
		setState("MainGame")
	end
	self.newgameButton = newgameButton
	
	local continueButton = Button()
	continueButton.onclick = function(uibutton)
		if States.MainGame.time then -- if there is an ongoing game
			setState("MainGame")
		end
	end
	continueButton:setEnabled(false)
	self.continueButton = continueButton

	
	local optionsButton = Button()
	optionsButton.onclick = function(uibutton)
		setState("OptionsMenu")
	end
	self.optionsButton = optionsButton
	
	local restartButton = Button()
	restartButton.onclick = function()
		Game.quit("restart")
	end
	self.restartButton = restartButton

	local quitButton = Button()
	quitButton.onclick = function()
		Game.quit()
	end
	self.quitButton = quitButton
	
	self.buttons = {newgameButton, continueButton, optionsButton}
	if not Game.web then table.insert(self.buttons, quitButton) end
	
	self:updateLayout()
	return self
end

function Menu:resize(w, h)
	Game.width, Game.height = w, h
	Game.sw, Game.sh = w / 800, h / 600
	self:updateLayout()
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
