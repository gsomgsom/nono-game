local _floor, _ceil = math.floor, math.ceil

local Game = require "game"

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
	local x, y = _floor(400 * sw), _floor(250 * sh)
	
	local font = Game.fonts.large
	local advance = _floor(font:getHeight() * 1.5)
	
	local newgameButton = Button(x, y, 0, "center"):set("New Game")
	newgameButton.onclick = function(uibutton)
		States.Main:newGame()
		setState("Main")
	end
	
	y = y + advance
	
	local continueButton = Button(x, y, 0, "center"):set("Continue")
	continueButton.onclick = function(uibutton)
		if States.Main.time then -- if there is an ongoing game
			setState("Main")
		end
	end
	continueButton.disabled = true
	
	y = y + advance
	
	local optionsButton = Button(x, y, 0, "center"):set("Options")
	optionsButton.onclick = function(uibutton)
		setState("Options")
	end
	
	x, y = _floor(400 * sw), _floor(500 * sh)
	local restartButton = Button(x, y, 0, "center"):set("Restart")
	restartButton.onclick = function()
		Game.quit("restart")
	end

	y = y + advance
	local quitButton = Button(x, y, 0, "center"):set("Quit")
	quitButton.onclick = function()
		Game.quit()
	end
	
	self.buttons = {
		newgameButton, continueButton, optionsButton,
		restartButton, quitButton
	}
	self.continueButton = continueButton

	self.logo = Game.graphics.logo
	local logow, logoh = self.logo:getDimensions()
	self.logox = _floor(400 * sw - logow / 2)
	self.logoy = _floor(25 * sh)
	
	return self
end

function Menu:draw()
	local sw, sh = Game.sw, Game.sh
	
	love.graphics.setColor(Game.colors.main)
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
	local font = Game.fonts.large
	local labels = love.graphics.newText(font)
	
	local sw, sh = Game.sw, Game.sh
	
	self.logo = Game.graphics.logo
	local logow, logoh = self.logo:getDimensions()
	self.logox = _floor(400 * sw - logow / 2)
	self.logoy = _floor(25 * sh)
	
	local x, y = _floor(400 * sw + 10), _floor(self.logoy + logoh)
	local limit = _floor(font:getWidth("<99>"))
	local advance = _floor(font:getHeight() * 1.1)
	
	labels:addf("Theme:", x - 10, "right", 0, y)
	local themeCycler = Cycler(x, y):set(Game.themenames, Game.themeindex)
	themeCycler.onclick = function(uibutton, index)
		print(uibutton, index)
		Game.applyTheme(Game.themes[index])
	end
	
	y = y + advance
	
	labels:addf("Grid Size:", x - 10, "right", 0, y)
	local sizeSlider = Slider(x, y, limit):set(Game.size, 4, 25)
	sizeSlider.onclick = function(uislider, change)
		Game.size = uislider.value
	end
	
	y = y + advance
	
	labels:addf("Music:", x - 10, "right", 0, y)
	local musicSlider = Slider(x, y, limit):set(Game.musicvol, 0, 10)
	musicSlider.onclick = function(uislider, change)
		Game.musicvol = uislider.value
		for k, v in pairs(Game.music) do
			v:setVolume(Game.musicvol / 10)
		end
	end
	
	y = y + advance
	
	labels:addf("Sounds:", x - 10, "right", 0, y)
	local soundSlider = Slider(x, y, limit):set(Game.soundvol, 0, 10)
	soundSlider.onclick = function(uislider, change)
		Game.soundvol = uislider.value
		for k, v in pairs(Game.sounds) do
			v:setVolume(Game.soundvol / 10)
		end
	end
	
	y = y + advance
	
	labels:addf("Highlight:", x - 10, "right", 0, y)
	local hlCycler = Cycler(x, y):set({"On", "Off"}, Game.highlight and 1 or 2)
	hlCycler.onclick = function(uibutton, index, value)
		Game.highlight = index == 1
	end
	
	y = y + advance
	
	local fsm = {"Window", "Desktop", "Exclusive"}
	local fsmidx = Game.fullscreen and (Game.fullscreentype == "exclusive" and 3 or 2) or 1
	
	labels:addf("Mode:", x - 10, "right", 0, y)
	local fsmodeCycler = Cycler(x, y):set(fsm, fsmidx)
	fsmodeCycler.onclick = function(uibutton, index, value)
		Game.fullscreentype = nil
		if index == 1 then Game.fullscreen = false return end
		
		Game.fullscreen = true
		if index == 2 then Game.fullscreentype = "desktop" return end
		
		Game.fullscreentype = "exclusive"
	end
	

	y = y + advance
	
	labels:addf("Window Size:", x - 10, "right", 0, y)
	local dw, dh = love.window.getDesktopDimensions()
	limit = _floor(font:getWidth("<9999>"))
	
	local wwSlider = Slider(x, y, limit):set(Game.windowwidth, 400, dw)
	wwSlider.onclick = function(uislider, change)
		Game.windowwidth = uislider.value
	end
	
	local xw = font:getWidth(" x ")
	labels:addf("x", 2 * limit + xw, "center", x, y)
	
	local whSlider = Slider(x + limit + xw, y, limit):set(Game.windowheight, 300, dh)
	whSlider.onclick = function(uislider, change)
		Game.windowheight = uislider.value
	end

	y = y + advance
	
	labels:addf("Fullscreen Size:", x - 10, "right", 0, y)
	local fssizeCycler = Cycler(x, y):set(Game.fsmodenames, Game.fsindex)
	fssizeCycler.onclick = function(uibutton, index, value)
		Game.fsindex = index
	end

	
	x, y = _floor(400 * sw), _floor(550 * sh)
	
	local backButton = Button(x, y, 0, "center"):set("Back")
	backButton.onclick = function(uibutton)
		setState("Menu")
	end
	
	self.buttons = {
		musicSlider, soundSlider, sizeSlider, themeCycler, hlCycler, 
		fsmodeCycler, wwSlider, whSlider, fssizeCycler,
		backButton
	}
	self.labels = labels
	
	return self
end

function Options:draw()
	local colors = Game.colors
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


-- Main Game State
local Main = class("main", stateBase)

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
	local x, y = 10 * sw, 10 * sh
	
	self.resetButton  = Button(x, y):set("Restart")
	self.resetButton.onclick = function()
		self:clearGrid()
	end
	
	y = y + 50 * sh
	
	self.pauseButton  = Button(x, y):set("Pause")
	self.pauseButton.onclick = function(uibutton, mx, my)
		setState("PauseMenu")
	end

	y = y + 50 * sh
	
	self.undoButton  = Button(x, y):set("Undo")
	self.undoButton.onclick = function(uibutton, mx, my)
		self:undo()
	end

	y = 450 * sh
	
	local seedInput = Typer(x, y, 150 * sw, "left")
	seedInput.font = Game.fonts.small
	seedInput:set("uninitialized")
	seedInput.ontextinput = function(typer, text)
		return tonumber(text) and #typer.buffer < 10
	end
	self.seedInput = seedInput

	y = y + 50 * sh
	
	self.newgameButton = Button(x, y):set("New")
	self.newgameButton.onclick = function()
		local seed = tonumber(self.seedInput.buffer)
		if seed == self.grid.seed then seed = nil end
		self:newGame(nil, seed)
	end

	y = y + 50 * sh
	
	self.quitButton    = Button(x, y):set("Back")
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
	size = size or Game.size
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
	States.Menu.continueButton.disabled = nil
	
	local font
	if size > 16 then
		font = fonts.itsy
	elseif size > 12 then
		font = fonts.tiny
	elseif size > 10 then
		font = fonts.small
	elseif size > 8 then
		font = fonts.default
	else
		font = fonts.large
	end

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
	local colors = Game.colors
	local graphics = Game.graphics
	local fonts = Game.fonts
	local sw, sh = Game.sw, Game.sh
	
	for k, b in ipairs(self.buttons) do b:draw() end

	local size = self.size
	local cs, font = self.cellsize, self.font
	local fonth, fontlh = self.fonth, self.fontlh
	
	local gs = self.gridsize
	local gx, gy = self.x, self.y
	local offset = 0
	
	-- cell highlight
	if Game.highlight and self.cx then
		love.graphics.setLineWidth(1)
		love.graphics.setLineStyle("rough")
		local hlx = self.x + _floor(self.cellsize * (self.cx - 1))
		local hly = self.y + _floor(self.cellsize * (self.cy - 1))
		love.graphics.setColor(colors.highlight)
		love.graphics.rectangle("fill", hlx, gy - self.vmax, cs, gs + self.vmax)
		love.graphics.rectangle("fill", gx - self.hmax, hly, gs + self.hmax, cs)
	end
	
	-- Grid items
	local isx, isy = graphics.set:getDimensions()
	isx, isy = (cs - 1) / isx, (cs - 1) / isy
	for x=1,size do
		for y=1,size do
			local xy = self.grid[x][y]
			local image
			if xy == 1 then
				love.graphics.setColor(colors.set)
				image = graphics.set
			elseif self.grid[x][y] == 2 then
				love.graphics.setColor(colors.unset)
				image = graphics.notset
			end
			if image then
				love.graphics.draw(image, gx+ (x - 1) * cs, gy + (y - 1) * cs, 0, isx, isy)
			end
		end
	end
	
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
	love.graphics.setColor(colors.main)
	love.graphics.setLineWidth(2)
	love.graphics.setLineStyle("rough")
	love.graphics.rectangle("line",gx,gy,gs,gs) -- surrounding rectangle
	love.graphics.setLineWidth(1)
	for i=1,size do
		offset = offset + (gs/size)
		love.graphics.line(gx+offset, gy, gx+offset, gy+gs) -- vertical lines
		love.graphics.line(gx, gy+offset, gx+gs, gy+offset) -- horizontal lines
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
			love.audio.play(Game.sounds.click)
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
		love.audio.play(Game.sounds.click)
		self:setCell(x, y, paint, true)
	end
end


function Main:mousereleased(x, y, button)
	for k, b in ipairs(self.buttons) do b:mousereleased(x, y, button) end
	
	if not self.win and self.changed and self:testSolution() then
		love.audio.play(Game.sounds.pling)
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
	local x, y = _floor(400 * sw), _floor(250 * sh)
	
	local font = Game.fonts.large
	local advance = _floor(font:getHeight() * 1.5)
	
	x, y = _floor(400 * sw), _floor(500 * sh)

	local continueButton = Button(x, y, 0, "center"):set("Continue")
	continueButton.onclick = function()
		if States.Main.time then
			setState("Main")
		end
	end
	
	y = y + advance
	local quitButton = Button(x, y, 0, "center"):set("Quit")
	quitButton.onclick = function()
		Game.quit()
	end
	
	self.buttons = {quitButton, continueButton}

	self.logo = Game.graphics.logo
	local logow, logoh = self.logo:getDimensions()
	self.logox = _floor(400 * sw - logow / 2)
	self.logoy = _floor(25 * sh)
	
	return self
end

function PauseMenu:draw()
	local sw, sh = Game.sw, Game.sh
	
	local colors = Game.colors
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

