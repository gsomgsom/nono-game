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

local function playclick(uiobj)
	local click = (uiobj and uiobj.clicksound) or theme.sounds.click
	if click then love.audio.play(click) end
end

-----------------------------------------

local alignList = {left = "left", center = "center", right = "right"}

local Label = class("Label", uiBase)
Label.font = Game.fonts.large


function Label:init(x, y, limit, align)
	self.nodes = {}
	x, y = _floor(x), _floor(y)
	self.posx, self.posy = x, y
	self.x, self.y = x, y
	self.limit = limit or 0
	self.align = alignList[align] or "left"
end

local function labelDrawImage(node)
	love.graphics.draw(node.image, node.x, node.y, 0, node.sx, node.sy)
end
function Label:insertImage(image, sx, sy, color, pos)
	local node = {}
	node.drawf, node.type = labelDrawImage, "image"
	node.image = image
	node.sx = sx or 1
	node.sy = sy or node.sx
	node.color = color
	table.insert(self.nodes, pos or #self.nodes + 1, node)
	return self
end

local function labelDrawText(node)
	love.graphics.print(node.text, node.font, node.x, node.y, 0, node.sx, node.sy)
end
function Label:insertText(text, font, color, pos)
	local node = {}
	node.drawf, node.type = labelDrawText, "text"
	node.text = text
	node.font = font or self.font
	node.color = color
	table.insert(self.nodes, pos or #self.nodes + 1, node)
	return self
end

local function labelDrawSpace(node) end
function Label:insertSpace(width, height, pos)
	local node = {}
	node.drawf, node.type = labelDrawSpace, "space"
	node.width  = width
	node.height = height or 1
	table.insert(self.nodes, pos or #self.nodes + 1, node)
	return self
end

function Label:refresh()
	local limit, align = self.limit, self.align
	local width, height = 0, 0
	local x, y = self.posx, self.posy
	
	for k, n in ipairs(self.nodes) do
		local nw, nh
		if n.drawf == labelDrawSpace then
			nw, nh = n.width, n.height
		elseif n.drawf == labelDrawText then
			nw, nh = n.font:getWidth(n.text), n.font:getHeight()
			n.width, n.height = nw, nh
		elseif n.drawf == labelDrawImage then
			nw, nh = n.image:getDimensions()
			nw, nh = _floor(nw * n.sx), _floor(nh * n.sy)
			n.width, n.height = nw, nh
		end
		
		if nw and nh then
			n.x, n.y = x, y
			width, height = width + nw, math.max(height, nh)
			x = x + nw
		end
	end
	
	local shiftx = 0
	if not limit or align == "left" then
		shiftx = 0
	elseif align == "right" then
		shiftx = _floor(limit - width)
	else -- center
		shiftx = _floor((limit - width) / 2)
	end

	for k, n in ipairs(self.nodes) do
		if n.drawf then
			n.x = n.x + shiftx
			n.y = _floor(n.y + (height - n.height) / 2)
		end
	end
	self.x, self.y = self.posx + shiftx, self.posy
	self.width, self.height = width, height
end

function Label:draw()
	local r, g, b, a
	for k, v in ipairs(self.nodes) do
		if v.drawf then
			if v.color then
				r, g, b, a = love.graphics.getColor()
				love.graphics.setColor(v.color)
				v:drawf()
				love.graphics.setColor(r,g,b,a)
			else
				v:drawf()
			end
		end
	end
end

-----------------------------------------

local Button = class("Button", Label)

function Button:init(x, y, limit, align, font)
	self.hover = false
	self.selected = false
	if font then self.font = font end
	Label.init(self, x, y, limit, align)
end

function Button:setImage(image, sx, sy, color)
	local imagenode = self.nodes[1]
	if imagenode and imagenode.type == "image" then
		table.remove(self.nodes, 1)
	end
	self:insertImage(image, sx, sy, color, 1)
	self:refresh()
	return self
end

function Button:setText(text, font, color)
	local pos
	for k, n in ipairs(self.nodes) do
		if n.type == "text" then
			pos = k -- must be 1 or 2
			table.remove(self.nodes, pos)
		end
	end
	self:insertText(text, font or self.font, color, pos)
	self:refresh()
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
	
	--love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
	Label.draw(self)
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
	playclick(self)
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

function Cycler:init(x, y, limit, align, font)
	Button.init(self, x, y, limit, align, font)
	self.list = nil
	self.index = 1
end

function Cycler:_onclick(x, y, mbutton)
	self.index = self.index % #self.list + 1
	self:setText(self.list[self.index])
	self:mousemoved(x, y)
	local f = self.onclick
	if f then f(self, self.index, self.text) end
	playclick(self)
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

local Typer = class("Typer", Button)

--function Typer:init(x, y, limit, align, font)
--	Button.init(self, x, y, limit, align, font)
--end

function Typer:setText(text, font, color)
	self.buffer = text
	Button.setText(self, text, font, color)
	return self
end

Typer.set = Typer.setText

function Typer:draw()
	if not self.focus then
		Button.draw(self)
		return
	end
	love.graphics.setFont(self.font)
	love.graphics.setColor(theme.colors.main)
	love.graphics.print(self.buffer, self.posx, self.posy)
	love.graphics.rectangle("line", self.posx, self.posy, self.limit, self.height)
end

--function Typer:mousemoved(x, y, dx, dy)
--	self.button:mousemoved(x, y, dx, dy)
--end

--function Typer:mousepressed(x, y, button)
--	self.focus = Button.mousepressed(self, x, y, button)
--	if self.buffer ~= self.text then
--		if self.onchange then
--			self.onchange(self, self.buffer)
--		end
--		self:setText(self.buffer)
--	end
--	return self.focus
--end

function Typer:_onchange()
	if self.buffer == self.text then return end
	if self.onchange then self.onchange(self, self.buffer) end
	self:setText(self.buffer)
end

function Typer:mousereleased(x, y, button)
	local clicked = Button.mousereleased(self, x, y, button)
	if self.focus and not clicked then
		self:_onchange(); self.focus = false
	else
		self.focus = clicked
	end
	return clicked
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
	elseif key == "return" then
		self:_onchange(); self.focus = false
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

function Slider:init(x, y, limit, align, font)
	x, y = _floor(x), _floor(y)
	self.x, self.y = x, y
	self.value = 0
	self.min, self.max, self.step = 0, 10, 1
	if font then self.font = font end
	self.dec = Button(x, y, limit, "left"  , font)
	self.inc = Button(x, y, limit, "right" , font)
	
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


local ssmdur = 2 -- slow mode duration
local ssmdt = 0.2 -- slow mode delta time
local stime = 5 -- total time for min to max
local sdelay = 0.5 -- start delay

function Slider:update(dt)
	if not self.selectTime then return end
	
	if self.totalTime then
		self.totalTime = self.totalTime + dt
		
		if self.slowmode and love.timer.getTime() - self.selectTime > ssmdur then
			self.slowmode = nil
		end
		local delta = self.slowmode and ssmdt or stime / (self.max - self.min)
		if self.totalTime < delta then return end
		self.totalTime = self.totalTime - delta
		
		
		if self.dec.selected then
			sliderbuttononclick(self, -1)
		end
		
		if self.inc.selected then
			sliderbuttononclick(self,  1)
		end
	elseif love.timer.getTime() - self.selectTime > sdelay then
		self.totalTime = 0
		self.slowmode = true
	end
end

-----------------------------------------

Game.Button = Button
Game.Cycler = Cycler
Game.Typer = Typer
Game.Slider = Slider

