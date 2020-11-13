local utf8 = require("utf8")
local Game = require "game"

local _floor = math.floor

local clamp = function(x, a, b)
	if x < a then return a end
	if x > b then return b end
	return x
end

local uiMeta = {__call = function(C, ...)
	return C.create(...)
end}

local function dummy() end
local uiFunctions = {
	"update", "mousemoved", "mousepressed", "mousereleased",
	"draw", "keypressed", "keyreleased", "textinput"
}
local function createUI(name)
	local s = setmetatable({name = name}, uiMeta)
	for k, v in ipairs(uiFunctions) do s[v] = dummy end
	s.colors = Game.colors
	s.font = Game.fonts.large
	s.clicksound = Game.sounds.click
	Game[name] = s
	return s
end



local Button = createUI("Button")
Button.__index = Button

function Button.create(x, y, limit, align)
	local b = {}
	setmetatable(b, Button)
	b.text = "button"
	b.hover = false
	b.selected = false
	x, y = _floor(x), _floor(y)
	b.posx, b.posy = x, y
	b.x, b.y, b.width, b.height = x, y, 10, 10
	b.limit = limit or 0
	b.align = align or "left"

	return b
end

function Button:setText(text, limit, align)
	if limit then self.limit = limit else limit = self.limit end
	if align then self.align = align else align = self.align end
	
	text = type(text) == "string" and text or tostring(text)
	self.text = text
	self.width = self.font:getWidth(text)
	self.height = self.font:getHeight()
	self.y = _floor(self.posy)
	
	if not limit or align == "left" then
		self.x = _floor(self.posx)
		return self
	end
	
	if align == "right" then
		self.x = _floor(self.posx + limit - self.width)
	else
		self.x = _floor(self.posx + (limit - self.width) / 2)
	end
	return self
end

Button.init = Button.setText


function Button:draw()
	local colors = self.colors
	local color
	love.graphics.setFont(self.font)
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
	love.audio.play(self.clicksound)
	return true
end

-----------------------------------------


local Cycler = createUI("Cycler")
Cycler.__index = Cycler

function Cycler.create(x, y, limit, align)
	local c = {}
	setmetatable(c, Cycler)
	c.list = nil
	c.index = 1
	c.button = Button.create(x, y, limit, align)
	c.button.onclick = function(uibutton, x, y, button)
		c.index = c.index % #c.list + 1
		uibutton:setText(c.list[c.index])
		uibutton:mousemoved(x, y)
		local f = c.onclick
		if f then f(c, c.index, uibutton.text) end
	end
	
	return c
end

function Cycler:setList(list, index)
	self.list = list
	self.index = index and clamp(index, 1, #list) or 1
	return self:setIndex(self.index)
end

Cycler.init = Cycler.setList

function Cycler:setIndex(index)
	self.index = clamp(index, 1, #self.list)
	self.button:setText(self.list[self.index])
	return self
end

--[[
function Cycler:setText(text, limit, align)
	for k, v in ipairs(self.list) do
		if v == text then
			self.index = k
			self.button:setText(self.list[k], limit, align)
			return k
		end
	end
end
--]]

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

-----------------------------------------


local Typer = createUI("Typer")
Typer.__index = Typer

function Typer.create(x, y, limit, align)
	local t = {}
	setmetatable(t, Typer)

	--x, y = _floor(x), _floor(y)
	t.button = Button.create(x, y, limit, align)
	t.button.onclick = function(uibutton, x, y, button)
		t.focus = true
	end
	
	return t
end

function Typer:setText(text, limit, align)
	self.buffer = text
	self.button.font = self.font
	self.button:setText(text, limit, align)
	return self
end

Typer.init = Typer.setText

function Typer:draw()
	if not self.focus then
		self.button:draw()
		return
	end
	local b = self.button
	love.graphics.setFont(self.font)
	love.graphics.setColor(self.colors.main)
	love.graphics.print(self.buffer, b.posx, b.posy)
	love.graphics.rectangle("line", b.posx, b.posy, b.limit, b.height)
end

function Typer:mousemoved(x, y, dx, dy)
	self.button:mousemoved(x, y, dx, dy)
end

function Typer:mousepressed(x, y, button)
	self.focus = self.button:mousepressed(x, y, button)
	if self.buffer ~= self.button.text then
		if self.onchange then
			self.onchange(self, self.buffer)
		end
		self:setText(self.buffer)
	end
	return self.focus
end

function Typer:mousereleased(x, y, button)
	self.focus = self.button:mousereleased(x, y, button)
	return self.focus
end

function Typer:textinput(text)
	if not self.focus then return end
	if self.ontextinput then
		local ok = self.ontextinput(self, text)
		if not ok then return end
	end
	self.buffer = self.buffer ..  text
end

function Typer:keypressed(key, scancode)
	if not self.focus then return end
	if key == "backspace" then
		local offset = utf8.offset(self.buffer, -1)
		if offset then
			self.buffer = string.sub(self.buffer, 1, offset - 1)
		end
	end
end

-----------------------------------------


local Slider = createUI("Slider")
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

function Slider.create(x, y, limit, align)
	local s = {}
	setmetatable(s, Slider)
	x, y = _floor(x), _floor(y)
	s.x, s.y = x, y
	s.value = 0
	s.min, s.max, s.step = 0, 10, 1
	s.dec = Button.create(x, y, limit, "left")
	s.inc = Button.create(x, y, limit, "right")
	
	s.dec.onclick = function()
		sliderbuttononclick(s, -1)
	end
	
	s.inc.onclick = function()
		sliderbuttononclick(s, 1)
	end
	
	return s
end

function Slider:setValueRange(value, min, max, step)
	self.value = value
	self.min, self.max, self.step = min, max, step or 1

	if     self.value == self.min then self.dec.disabled = true
	elseif self.value == self.max then self.inc.disabled = true end
	
	self.inc:setText(">")
	self.dec:setText("<")
	
	return self
end

Slider.init = Slider.setValueRange

function Slider:draw()
	self.inc:draw()
	self.dec:draw()
	love.graphics.setFont(self.font)
	love.graphics.setColor(self.colors.text)
	love.graphics.printf(self.value, self.x, self.y, self.dec.limit, "center")
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

