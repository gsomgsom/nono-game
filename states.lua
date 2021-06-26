local _floor, _ceil = math.floor, math.ceil
local _sf = string.format

local Game = require "game"

local settings = Game.settings

local simpleclass = require "simpleclass"
local noop = simpleclass._noop
local class = simpleclass.class

local Button = Game.Button
local Slider = Game.Slider
local Cycler = Game.Cycler
local Typer = Game.Typer

local States = {}

local function setState(state)
	if type(state) == "string" then state = States[state] end
	state:mousemoved(love.mouse.getPosition())
	Game.state = state
end

local stateBase = class("stateBase")
local stateFunctions = {
	"update", "mousemoved", "mousepressed", "mousereleased",
	"draw", "keypressed", "keyreleased", "textinput"
}
for k, v in ipairs(stateFunctions) do stateBase[v] = noop end

-- Main Menu State
local Menu = class("menu", stateBase)

function Menu:init()
	local sw, sh = Game.sw, Game.sh
	
	self.logo = Game.theme.graphics.logo
	local logow, logoh = self.logo:getDimensions()
	self.logox = _floor(400 * sw - logow / 2)
	self.logoy = _floor(25 * sh)
	
	--[[local icons = {
		newgame = love.graphics.newImage("media/2x/star.png"),
		continue = love.graphics.newImage("media/2x/right.png"),
		options = love.graphics.newImage("media/2x/gear.png"),
		restart = love.graphics.newImage("media/2x/power.png"),
		quit = love.graphics.newImage("media/2x/exit.png"),
	}
	local iconscale = 0.6 * sw]]
	
	local font = Game.fonts.huge
	local advance = _floor(font:getHeight() * 1)
	
	local x, y = _floor(400 * sw), self.logoy + logoh + advance
	
	local newgameButton = Button(x, y, 0, "center")
		--:setImage(icons.newgame, iconscale)
		:setText("New Game", font)
	newgameButton.onclick = function(uibutton)
		States.Main:newGame()
		setState("Main")
	end
	
	y = y + advance
	
	local continueButton = Button(x, y, 0, "center")
		--:setImage(icons.continue, iconscale)
		:setText("Continue", font)
	continueButton.onclick = function(uibutton)
		if States.Main.time then -- if there is an ongoing game
			setState("Main")
		end
	end
	continueButton:setEnabled(false)
	
	y = y + advance
	
	local optionsButton = Button(x, y, 0, "center")
		--:setImage(icons.options, iconscale)
		:setText("Options", font)
	optionsButton.onclick = function(uibutton)
		setState("Options")
	end
	
	y = _floor(600 * sh) - 2 * advance
	local restartButton = Button(x, y, 0, "center")
		--:setImage(icons.restart, iconscale)
		:setText("Restart", font)
	restartButton.onclick = function()
		Game.quit("restart")
	end

	y = y + advance
	local quitButton = Button(x, y, 0, "center")
		--:setImage(icons.quit, iconscale)
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
	
	love.graphics.setColor(Game.theme.colors.main)
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

-- Options State
local Options = class("options", stateBase)

function Options:init()
	local font = Game.fonts.default
	local labels = love.graphics.newText(font)
	
	local sw, sh = Game.sw, Game.sh
	
	self.logo = Game.theme.graphics.logo
	local logow, logoh = self.logo:getDimensions()
	self.logox = _floor(400 * sw - logow / 2)
	self.logoy = _floor(25 * sh)
	
	local x, y = _floor(400 * sw + 10), _floor(self.logoy + logoh)
	local limit = _floor(font:getWidth("<99>"))
	local advance = _floor(font:getHeight() * 1)
	
	labels:addf("Theme:", x - 10, "right", 0, y)
	local themeCycler = Cycler(x, y, 0, nil, font):set(Game.themenames, Game.theme.name)
	themeCycler.onclick = function(uibutton, index)
		Game.applyTheme(Game.themenames[index])
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
		for k, v in pairs(Game.theme.music) do
			v:setVolume(settings.musicvol / 10)
		end
	end
	
	y = y + advance
	
	labels:addf("Sounds:", x - 10, "right", 0, y)
	local soundSlider = Slider(x, y, limit, nil, font):set(settings.soundvol, 0, 10)
	soundSlider.onclick = function(uislider, change)
		settings.soundvol = uislider.value
		for k, v in pairs(Game.theme.sounds) do
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
	local color = Game.theme.colors.highlight
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
		setState("Menu")
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
	local colors = Game.theme.colors
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

function Options:textinput(text)
	self.fgInput:textinput(text)
end

function Options:keypressed(k, sc)
	self.fgInput:keypressed(k, sc)
end

-- Main Game State
local Main = class("main", stateBase)

-- 0: empty cell, 1: nonempty cell
-- 0: unmarked, 1: marked full, 2: marked empty

local function gen_gridlist(grid)
	local size = #grid
	local total = 0
	
	local cols = {}
	for x = 1,size do
		local count = 0
		local col = {}
		for y = 1,size do
			if grid[x][y] == 1 then
				count = count + 1
				total = total + 1
			elseif count ~= 0 then
				table.insert(col, count)
				count = 0
			end
		end
		
		if count ~= 0 then
			table.insert(col, count)
		end
		
		col.text = table.concat(col, "\n")
		col.len = #col
		cols[x] = col
	end
	
	
	local rows = {}
	for y = 1,size do
		local count = 0
		local row = {}
		for x = 1,size do
			if grid[x][y] == 1 then
				count = count + 1
			elseif count ~= 0 then
				table.insert(row, count)
				count = 0
			end
		end
		
		if count ~= 0 then
			table.insert(row, count)
		end
		
		row.text = table.concat(row, " ")
		row.len = #row
		rows[y] = row
	end
	
	return rows, cols, total
end

local function gen_grid(size, seed)
	love.math.setRandomSeed(seed)
	local grid = {size = size, seed = seed}
	
	for x = 1, size do
		local col = {}
		for y = 1, size do
			col[y] = love.math.random(1, 3) == 1 and 0 or 1
		end
		grid[x] = col
	end
	
	return grid
end

function Main:clearGrid()
	local size = self.size
	local grid = self.grid
	for x = 1, size do
		for y = 1, size do
			grid[x][y] = 0
		end
	end
	
	self.win = false
	self.time = 0
	local rows, cols = {}, {}
	local srows, scols = self.srows, self.scols
	for i = 1, size do
		rows[i] = {len = 0, check = srows[i].len == 0}
		cols[i] = {len = 0, check = scols[i].len == 0}
	end
	self.rows, self.cols, self.total = rows, cols, 0
end

function Main:init()
	local sw, sh = Game.sw, Game.sh
	
	local icons = {
		newgame = love.graphics.newImage("media/2x/star.png"),
		pause = love.graphics.newImage("media/2x/pause.png"),
		undo = love.graphics.newImage("media/2x/rewind.png"),
		reset = love.graphics.newImage("media/2x/return.png"),
		back = love.graphics.newImage("media/2x/arrowLeft.png"),
	}
	local iconscale = 0.4 * sw
	
	local x, y = 10 * sw, 10 * sh
	
	self.resetButton  = Button(x, y)
		:setImage(icons.reset, iconscale)
		:setText("Reset")
	self.resetButton.onclick = function()
		self:clearGrid()
	end
	
	y = y + 50 * sh
	
	self.pauseButton  = Button(x, y)
		:setImage(icons.pause, iconscale)
		:setText("Pause")
	self.pauseButton.onclick = function(uibutton, mx, my)
		setState("PauseMenu")
	end

	y = y + 50 * sh
	
	self.undoButton  = Button(x, y)
		:setImage(icons.undo, iconscale)
		:setText("Undo")
	self.undoButton.onclick = function(uibutton, mx, my)
		self:undo()
	end

	y = 450 * sh
	
	local seedInput = Typer(x, y, 150 * sw, "left", Game.fonts.small)
	seedInput:set("uninitialized")
	seedInput.ontextinput = function(typer, text)
		if tonumber(text) and #typer.buffer < 10 then return text end
	end
	self.seedInput = seedInput

	y = y + 50 * sh
	
	self.newgameButton = Button(x, y)
		:setImage(icons.newgame, iconscale)
		:setText("New")
	self.newgameButton.onclick = function()
		local seed = tonumber(self.seedInput.buffer)
		if seed == self.grid.seed then seed = nil end
		self:newGame(nil, seed)
	end

	y = y + 50 * sh
	
	self.quitButton    = Button(x, y)
		:setImage(icons.back, iconscale)
		:setText("Back")
	self.quitButton.onclick = function(uibutton)
		setState("Menu")
	end

	self.buttons = {
		self.resetButton, self.pauseButton, self.undoButton,
		seedInput,
		self.newgameButton, self.quitButton
	}
	return self
	
end

function Main:newGame(size, seed, grid)
	size = size or settings.size
	seed = seed or _floor(love.math.random(1e10))
	
	self.size = size
	
	
	self.grid = gen_grid(size, seed)
	self.srows, self.scols, self.stotal = gen_gridlist(self.grid)
	self:clearGrid()
	self.history = {}
	
	if grid then
		for i = 1, size do
		for j = 1, size do
			self:setCell(i, j, grid[i][j])
		end
		end
	end
	
	local fonts = Game.fonts
	local sw, sh = Game.sw, Game.sh
	
	self.seedInput:setText(tostring(seed))
	States.Menu.continueButton:setEnabled()
	
	if self.font then self.font:release() end
	local charcells = _ceil(size / 2) + size
	local charcellsize = (595 * sh) / charcells
	local font = Game.newFont(_ceil(charcellsize))

	self.font = font
	self.fonth, self.fontlh = font:getHeight(), font:getLineHeight()
	
	local vmax = _ceil((size / 2) * self.fonth * self.fontlh)
	local hmax = _ceil((size / 2) * font:getWidth("0 "))
	
	local w, h = Game.width, Game.height
	
	self.cellsize = _floor(math.min(640 * sw - hmax, 595 * sh - vmax) / self.size)
	self.gridsize = self.cellsize * size
	
	self.vmax = vmax
	self.hmax = hmax
	
	self.x = _floor((w - self.gridsize - hmax - 150 * sw) / 2 + hmax + 150 * sw)
	self.y = _floor((h - self.gridsize - vmax) / 2 + vmax)
	
	return self
	
end

function Main:draw()
	local colors = Game.theme.colors
	local graphics = Game.theme.graphics
	local fonts = Game.fonts
	local sw, sh = Game.sw, Game.sh
	
	for k, b in ipairs(self.buttons) do b:draw() end

	local size = self.size
	local cs, font = self.cellsize, self.font
	local fonth, fontlh = self.fonth, self.fontlh
	
	local gs = self.gridsize
	local gx, gy = self.x, self.y
	
	-- cell highlight
	local csm1 = cs - 1 -- width/height of image
	if settings.highlight and self.cx then
		local hlx = self.x + _floor(self.cellsize * (self.cx - 1))
		local hly = self.y + _floor(self.cellsize * (self.cy - 1))
		love.graphics.setColor(colors.highlight)
		love.graphics.rectangle("fill", hlx, gy - self.vmax, csm1, gs + self.vmax)
		love.graphics.rectangle("fill", gx - self.hmax, hly, gs + self.hmax, csm1)
	end
	
	-- Grid items
	local image = graphics.mark1
	local isx, isy = image:getDimensions()
	isx, isy = csm1 / isx, csm1 / isy
	love.graphics.setColor(colors.mark1)
	for x = 1, size do for y = 1, size do
		if self.grid[x][y] == 1 then
			love.graphics.draw(image, gx + (x - 1) * cs, gy + (y - 1) * cs, 0, isx, isy)
		end
	end end
	
	image = graphics.mark0
	isx, isy = image:getDimensions()
	isx, isy = csm1 / isx, csm1 / isy
	love.graphics.setColor(colors.mark0)
	for x = 1, size do for y = 1, size do
		if self.grid[x][y] == 2 then
			love.graphics.draw(image, gx + (x - 1) * cs, gy + (y - 1) * cs, 0, isx, isy)
		end
	end end
	
	-- text
	love.graphics.setFont(font)
	
	local a = cs - _floor((cs - fonth) / 2) - 1
	for i=1,size do
		love.graphics.setColor(colors[self.cols[i].check and "main" or "text"])
		love.graphics.printf(self.scols[i].text,
					gx+(cs*i)-cs,
					gy-(self.scols[i].len * fonth * fontlh),
					cs, "center")
		love.graphics.setColor(colors[self.rows[i].check and "main" or "text"])
		love.graphics.printf(self.srows[i].text, 0, gy+(cs*i) - a, gx - 5, "right")
	end
	
	-- grid lines
	local gsm1 = gs - 1 -- width/height of image row/column
	love.graphics.setColor(colors.main)
	-- frame
	love.graphics.rectangle("fill", gx - 2,    gy, 2, gsm1)
	love.graphics.rectangle("fill", gx + gsm1, gy, 2, gsm1)
	love.graphics.rectangle("fill", gx - 2, gy - 2,    gsm1 + 4, 2)
	love.graphics.rectangle("fill", gx - 2, gy + gsm1, gsm1 + 4, 2)
	
	local offset = 0
	for i = 1, size - 1 do
		offset = offset + cs
		love.graphics.rectangle("fill", gx + offset - 1, gy, 1, gsm1) -- vertical lines
		love.graphics.rectangle("fill", gx, gy + offset - 1, gsm1, 1) -- horizontal lines
	end
	
	love.graphics.setFont(fonts.default)
	love.graphics.setColor(colors.text)
	local x, y, advance = _floor(10 * sw), _floor(160 * sh), _floor(40 * sh)
	love.graphics.printf(string.format("Left: %i", self.stotal - self.total),
			x, y, gx, "left")
	if self.win then
		y = y + advance
		love.graphics.printf(string.format("Solved in\n%.1fs", self.win),
			x, y, gx, "left")
	end
	
	y = _floor(420 * sh)
	love.graphics.print("Seed:", x, y)
	
end

function Main:textinput(text)
	self.seedInput:textinput(text)
end

function Main:keypressed(k, sc)
	self.seedInput:keypressed(k, sc)
end

function Main:update(dt)
	self.time = self.time + dt
end

function Main:getCellAt(x, y)
	local cs = self.cellsize

	local gs = self.gridsize
	local gx, gy = self.x, self.y

	x = x - gx
	y = y - gy
	
	if x > 0 and x < gs and y > 0 and y < gs then
		x, y = _ceil(x / cs), _ceil(y / cs)
		return x, y, self.grid[x][y]
	end
end

function Main:setCell(cx, cy, value, log)
	local grid = self.grid
	local oldvalue = grid[cx][cy]
	grid[cx][cy] = value
	
	if log and oldvalue ~= value then
		table.insert(self.history[#self.history], {x=cx, y=cy, value=oldvalue})
	end
	
	if     oldvalue + value == 1 then -- 0 --> 1
		self.total = self.total  + (value - oldvalue)
	elseif oldvalue + value == 3 then -- 2 --> 1
		self.total = self.total  + (oldvalue - value)
	else -- nothing changes otherwise
		return
	end
	
	self.win = false
	self.changed = true
	
	local srow, scol = self.srows[cy], self.scols[cx]
	
	local len, count
	
	-- row check
	count = 0
	local row = {len = 0, check = false}
	for x = 1, self.size do
		if grid[x][cy] == 1 then
			count = count + 1
		elseif count ~= 0 then
			table.insert(row, count)
			count = 0
		end
	end
	if count ~= 0 then
		table.insert(row, count)
	end
	
	len = #row
	row.len = len
	self.rows[cy] = row
	if srow.len == len then
		local check = true
		for i = 1, len do
			if row[i] ~= srow[i] then check = false break end
		end
		row.check = check
	end
	
	-- column check
	count = 0
	local col = {len = 0, check = false}
	for y = 1, self.size do
		if grid[cx][y] == 1 then
			count = count + 1
		elseif count ~= 0 then
			table.insert(col, count)
			count = 0
		end
	end
	if count ~= 0 then
		table.insert(col, count)
	end
	
	len = #col
	col.len = len
	self.cols[cx] = col
	if scol.len == len then
		local check = true
		for i = 1, len do
			if col[i] ~= scol[i] then check = false break end
		end
		col.check = check
	end
end

function Main:undo()
	local undo = table.remove(self.history)
	
	if not undo then return end
	
	for k, v in ipairs(undo) do
		self:setCell(v.x, v.y, v.value)
	end
end

function Main:mousepressed(x, y, button)
	local size = self.size
	
	self.paintmode = nil
	self.changed = false
	
	local cell
	x, y, cell = self:getCellAt(x, y)
	if x then
		local paint
		if button == 1 then
			paint = cell == 1 and 0 or 1
		elseif button == 2 then
			paint = cell == 2 and 0 or 2
		end
		
		table.insert(self.history, {})
		
		self.paintmode = paint
		if paint then
			love.audio.play(Game.theme.sounds.click)
			self:setCell(x, y, paint, true)
		end
		--return
	end
	
	for k, b in ipairs(self.buttons) do b:mousepressed(x, y, button) end
end

function Main:mousemoved(x, y, dx, dy)
	for k, b in ipairs(self.buttons) do b:mousemoved(x, y, dx, dy) end
	
	local cell
	self.cx, self.cy = nil, nil
	x, y, cell = self:getCellAt(x, y)
	if not x then return end
	
	self.cx = x
	self.cy = y
	
	local paint = self.paintmode
	if paint and cell ~= paint then
		love.audio.play(Game.theme.sounds.click)
		self:setCell(x, y, paint, true)
	end
end


function Main:mousereleased(x, y, button)
	for k, b in ipairs(self.buttons) do b:mousereleased(x, y, button) end
	
	if not self.win and self.changed and self:testSolution() then
		love.audio.play(Game.theme.sounds.pling)
		self.win = self.time
	end

	self.paintmode=nil
	self.changed = false
end

function Main:testSolution()
	local rows, cols = self.rows, self.cols
	local srows, scols = self.srows, self.scols
	local size = self.size
	for i = 1, size do
		if not rows[i].check then return false end
		if not cols[i].check then return false end
	end
	return true
end

-- Pause Menu State
local PauseMenu = class("pausemenu", stateBase)

function PauseMenu:init()
	local sw, sh = Game.sw, Game.sh
	local x, y = _floor(400 * sw), _floor(600 * sh)
	
	local font = Game.fonts.huge
	local advance = _floor(font:getHeight() * 1)
	
	y = y - 2 * advance

	local continueButton = Button(x, y, 0, "center", font):set("Continue")
	continueButton.onclick = function()
		if States.Main.time then
			setState("Main")
		end
	end
	
	y = y + advance
	local quitButton = Button(x, y, 0, "center", font):set("Quit")
	quitButton.onclick = function()
		Game.quit()
	end
	
	self.buttons = {continueButton}
	if not Game.web then table.insert(self.buttons, quitButton) end

	self.logo = Game.theme.graphics.logo
	local logow, logoh = self.logo:getDimensions()
	self.logox = _floor(400 * sw - logow / 2)
	self.logoy = _floor(25 * sh)
	
	return self
end

function PauseMenu:draw()
	local sw, sh = Game.sw, Game.sh
	
	local colors = Game.theme.colors
	local fonts = Game.fonts
	
	love.graphics.setColor(colors.main)
	love.graphics.draw(self.logo, self.logox, self.logoy)
	
	love.graphics.setColor(colors.text)
	love.graphics.setFont(fonts.huge)
	local x, y, limit = 0, 200 * sh, 800 * sw
	if States.Main.win then
		love.graphics.printf(string.format("SOLVED:\n%.1fs", States.Main.win),
			x, y, limit, "center")
	else
		love.graphics.printf(string.format("ELAPSED:\n%.1fs", States.Main.time),
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

States.Main = Main:new()
States.Menu = Menu:new()
States.Options = Options:new()
States.PauseMenu = PauseMenu:new()

Game.States = States
Game.setState = setState

