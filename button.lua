local _floor = math.floor

local Game = require "game"

local Button = {}
Button.__index = Button

function Button.create(text, x, y, max, align)
	local b = {}
	setmetatable(b, Button)
	b.hover = false -- whether the mouse is hovering over the button
	b.click = false -- whether the mouse has been clicked on the button
	b.posx = x
	b.posy = y
	b.max = max
	b.align = align
	b:setText(text)
	
	return b
end

function Button:setText(text)
	text = type(text) == "string" and text or tostring(text)
	self.text = text
	self.width = Game.fonts.large:getWidth(text)
	self.height = Game.fonts.large:getHeight()
	self.y = _floor(self.posy)
	
	local max, align = self.max, self.align
	if not max or align == "left" then
		self.x = _floor(self.posx)
		return
	end
	
	if align == "right" then
		self.x = _floor(self.posx + max - self.width)
	else
		self.x = _floor(self.posx + (max - self.width) / 2)
	end
end

function Button:draw()
	local colors = Game.colors
	local color
	love.graphics.setFont(Game.fonts.large)
	if self.disabled then color = colors.disabled
	elseif self.hover or self.selected then color = colors.main
	else color = colors.text end
	love.graphics.setColor(color)
	love.graphics.print(self.text, self.x, self.y)
	--if self.max then
	--	love.graphics.rectangle("line", self.posx, self.posy, self.max, self.height)
	--end
	--love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
end

function Button:mousemoved(x, y, dx, dy)
	self.hover = false
	
	if self.disabled then return end
	
	if x > self.x
		and x < self.x + self.width
		and y > self.y
		and y < self.y + self.height then
		self.hover = true
	end
	
end

function Button:mousepressed(x, y, button)
	if self.disabled or not self.hover then return end
	
	love.audio.play(Game.sounds.click)
	self.selected = true
end

function Button:mousereleased(x, y, button)
	if self.disabled or not self.selected then return end
	self.selected = false
	if not self.hover then return end
	
	if self.onclick then
		self.onclick(self, x, y, button)
	end
	return true
end

Game.Button = Button

-----------------------------------------

local clamp = function(x, a, b)
	if x < a then return a end
	if x > b then return b end
	return x
end

local Slider = {}
Slider.__index = Slider

function Slider.create(value, x, y, width, min, max)
	local slider = {}
	setmetatable(slider, Slider)
	slider.x = x
	slider.y = y
	slider.width = width
	slider.value = value
	slider.min, slider.max = min, max
	slider.dec = Button.create("<", x, y, width, "left")
	slider.inc = Button.create(">", x, y, width, "right")
	
	if min and max then
		slider.dec.onclick = function()
			slider.value = clamp(slider.value - 1, slider.min, slider.max)
		end
		
		slider.inc.onclick = function()
			slider.value = clamp(slider.value + 1, slider.min, slider.max)
		end
	end
	return slider
end

function Slider:draw()
	self.inc:draw()
	self.dec:draw()
	love.graphics.setFont(Game.fonts.large)
	love.graphics.setColor(Game.colors.text)
	love.graphics.printf(self.value, self.x, self.y, self.width, "center")
end

function Slider:mousemoved(x, y, dx, dy)
	self.inc:mousemoved(x, y, dx, dy)
	self.dec:mousemoved(x, y, dx, dy)
end

function Slider:mousepressed(x, y, button)
	self.inc:mousepressed(x, y, button)	
	self.dec:mousepressed(x, y, button)
end

function Slider:mousereleased(x, y, button)
	local f = self.onclick
	
	if self.inc:mousereleased(x, y, button) then
		if f then f(self, 1) end
		return true
	end
	
	if self.dec:mousereleased(x, y, button) then
		if f then f(self, -1) end
		return true
	end
end

Game.Slider = Slider