local _floor = math.floor

local clamp = function(x, a, b)
	if x < a then return a end
	if x > b then return b end
	return x
end

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
end

function Button:mousemoved(x, y, dx, dy)
	self.hover = false
	
	if self.disabled then return end
	
	if x > self.x and x < self.x + self.width and
	   y > self.y and y < self.y + self.height then
		self.hover = true
	end
	
end

function Button:mousepressed(x, y, button)
	self.selected = false
	if self.disabled or not self.hover then return end
	self.selected = true
	return true
end

function Button:mousereleased(x, y, button)
	local selected = self.selected
	self.selected = false
	if self.disabled or not selected then return end
	
	if not self.hover then return end
	
	if self.onclick then
		self.onclick(self, x, y, button)
	end
	love.audio.play(Game.sounds.click)
	return true
end

function Button.update() end

Game.Button = Button

-----------------------------------------

local Cycler = {}
Cycler.__index = Cycler

function Cycler.create(list, x, y, width, align, index)
	local c = {}
	setmetatable(c, Cycler)
	c.list = list
	c.index = index and clamp(index, 1, #list) or 1
	c.button = Button.create(list[c.index], x, y, width, align)
	c.button.onclick = function(uibutton, x, y, button)
		c.index = c.index % #c.list + 1
		uibutton:setText(c.list[c.index])
		uibutton:mousemoved(x, y)
		local f = c.onclick
		if f then f(c, c.index, uibutton.text) end
	end
	
	return c
end

function Cycler:setIndex(index)
	self.index = clamp(index, 1, #self.list)
	self.button:setText(self.list[self.index])
end

function Cycler:setText(text)
	for k, v in ipairs(self.list) do
		if v == text then
			self.index = k
			self.button:setText(self.list[k])
			return k
		end
	end
end

function Cycler:draw()
	self.button:draw()
end

function Cycler:mousemoved(x, y, dx, dy)
	self.button:mousemoved(x, y, dx, dy)
end

function Cycler:mousepressed(x, y, button)
	return self.button:mousepressed(x, y, button)
end

function Cycler:mousereleased(x, y, button)
	return self.button:mousereleased(x, y, button)
end

function Cycler.update() end

Game.Cycler = Cycler

-----------------------------------------

local Slider = {}
Slider.__index = Slider

local function sliderbuttononclick(slider, dir)
	slider.dec.disabled, slider.inc.disabled = false, false
	
	local oldvalue, step = slider.value, slider.step
	slider.value = oldvalue + dir * step
	if slider.value <= slider.min then
		slider.value = slider.min
		slider.dec.disabled, slider.dec.selected = true, false
	elseif slider.value >= slider.max then
		slider.value = slider.max
		slider.inc.disabled, slider.inc.selected = true, false
	end
	
	if slider.value == oldvalue then return end -- this should not happen
	
	if slider.onclick then slider.onclick(slider, dir) end
end

function Slider.create(value, x, y, width, min, max, step)
	local slider = {}
	setmetatable(slider, Slider)
	slider.x = x
	slider.y = y
	slider.width = width
	slider.value = value
	slider.min, slider.max, slider.step = min, max, step or 1
	slider.dec = Button.create("<", x, y, width, "left")
	slider.inc = Button.create(">", x, y, width, "right")
	
	if     slider.value == slider.min then slider.dec.disabled = true
	elseif slider.value == slider.max then slider.inc.disabled = true end
	
	slider.dec.onclick = function()
		sliderbuttononclick(slider, -1)
	end
	
	slider.inc.onclick = function()
		sliderbuttononclick(slider, 1)
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
	self.totalTime = nil
	self.selectTime = nil
	
	if self.inc:mousepressed(x, y, button) then
		self.selectTime = love.timer.getTime()
		--return true
	end
	
	if self.dec:mousepressed(x, y, button) then
		self.selectTime = love.timer.getTime()
		--return true
	end
end

function Slider:mousereleased(x, y, button)
	self.selectTime = nil
	if self.totalTime then
		self.totalTime = nil
		self.inc.selected = false
		self.dec.selected = false
		return true
	end
	
	self.inc:mousereleased(x, y, button)
	self.dec:mousereleased(x, y, button)
end

function Slider:update(dt)
	if not self.selectTime then return end
	
	if self.totalTime then
		self.totalTime = self.totalTime + dt
		local delta = 5 / (self.max - self.min)
		if self.totalTime < delta then return end
		self.totalTime = self.totalTime - delta
		
		
		if self.dec.selected then
			sliderbuttononclick(self, -1)
		end
		
		if self.inc.selected then
			sliderbuttononclick(self,  1)
		end
		
		return
	end
	
	if love.timer.getTime() - self.selectTime > 0.5 then
		self.totalTime = 0
	end
end

Game.Slider = Slider