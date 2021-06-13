local utf8 = require "utf8"
local Game = require "game"

local simpleclass = require "simpleclass"
local noop = simpleclass._noop
local class = simpleclass.class

local _floor = math.floor

local clamp = function(x, a, b)
	if x < a then return a end
	if x > b then return b end
	return x
end


local theme = Game.theme
-----------------------------------------

local uiMeta = {__call = function(C, ...) return C:new(...) end}
local uiBase = setmetatable(class("uiBase"), uiMeta)
local uiFunctions = {
	"update", "mousemoved", "mousepressed", "mousereleased",
	"draw", "keypressed", "keyreleased", "textinput"
}

for k, v in ipairs(uiFunctions) do uiBase[v] = noop end

uiBase.font = Game.fonts.large

function uiBase:playclick()
	local click = theme.sounds.click
	if click then love.audio.play(click) end
end

-----------------------------------------

local Button = class("Button", uiBase)

function Button:init(x, y, limit, align)
	self.text = "button"
	self.hover = false
	self.selected = false
	x, y = _floor(x), _floor(y)
	self.posx, self.posy = x, y
	self.x, self.y, self.width, self.height = x, y, 10, 10
	self.limit = limit or 0
	self.align = align or "left"
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

Button.set = Button.setText

function Button:draw()
	local colors = theme.colors
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

function Button:_onclick(x, y, mbutton)
	if self.onclick then self.onclick(self, x, y, mbutton) end
	self:playclick()
end

function Button:mousereleased(x, y, button)
	local selected = self.selected
	self.selected = false
	if self.disabled or not selected then return end
	
	if not self.hover then return end
	
	self:_onclick(x, y, button)
	return true
end

-----------------------------------------

local Cycler = class("Cycler", Button)

function Cycler:init(x, y, limit, align)
	Button.init(self, x, y, limit, align)
	self.list = nil
	self.index = 1
end

function Cycler:_onclick(x, y, mbutton)
	self.index = self.index % #self.list + 1
	self:setText(self.list[self.index])
	self:mousemoved(x, y)
	local f = self.onclick
	if f then f(self, self.index, self.text) end
	self:playclick()
end

function Cycler:setIndex(index)
	self.index = clamp(index, 1, #self.list)
	self:setText(self.list[self.index])
	return self
end

function Cycler:setIndexByText(text)
	for k, v in ipairs(self.list) do
		if v == text then return self:setIndex(k) end
	end
end

function Cycler:setList(list, index)
	self.list = list
	if not index then return self:setIndex(1) end
	
	local indexType = type(index)
	if indexType == "number" then return self:setIndex(index) end
	return self:setIndexByText(index) -- a little loose?
end

Cycler.set = Cycler.setList

-----------------------------------------

local Typer = class("Typer", uiBase)

function Typer:init(x, y, limit, align)
	--x, y = _floor(x), _floor(y)
	self.button = Button(x, y, limit, align)
	self.button.onclick = function(uibutton, x, y, button)
		self.focus = true
	end
end

function Typer:setText(text, limit, align)
	self.buffer = text
	self.button.font = self.font
	self.button:setText(text, limit, align)
	return self
end

Typer.set = Typer.setText

function Typer:draw()
	if not self.focus then
		self.button:draw()
		return
	end
	local b = self.button
	love.graphics.setFont(self.font)
	love.graphics.setColor(theme.colors.main)
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

local Slider = class("Slider", uiBase)

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

function Slider:init(x, y, limit, align)
	x, y = _floor(x), _floor(y)
	self.x, self.y = x, y
	self.value = 0
	self.min, self.max, self.step = 0, 10, 1
	self.dec = Button(x, y, limit, "left")
	self.inc = Button(x, y, limit, "right")
	
	self.dec.onclick = function()
		sliderbuttononclick(self, -1)
	end
	
	self.inc.onclick = function()
		sliderbuttononclick(self, 1)
	end
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

Slider.set = Slider.setValueRange

function Slider:draw()
	self.inc:draw()
	self.dec:draw()
	love.graphics.setFont(self.font)
	love.graphics.setColor(theme.colors.text)
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

-----------------------------------------

Game.Button = Button
Game.Cycler = Cycler
Game.Typer = Typer
Game.Slider = Slider

