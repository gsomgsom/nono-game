local _floor, _ceil = math.floor, math.ceil

local Game = require "game"

local Button = Game.Button
local Slider = Game.Slider
local Cycler = Game.Cycler

local States = {}

local function dummy() end
local stateFunctions = {
	"update", "mousemoved", "mousepressed", "mousereleased",
	"draw", "keypressed", "keyreleased"
}
local function createState(name)
	local s = {name = name}
	for k, v in ipairs(stateFunctions) do s[v] = dummy end
	return s
end

-- Main Menu State
local Menu = createState("menu")

function Menu:init()
	local sw, sh = Game.sw, Game.sh
	local x, y = _floor(400 * sw), _floor(250 * sh)
	
	local font = Game.fonts.large
	local advance = _floor(font:getHeight() * 1.5)
	
	local newgameButton = Button.create("New Game", x, y, 0)
	newgameButton.onclick = function(uibutton)
		States.Main:newGame()
		Game.setState(States.Main)
	end
	
	y = y + advance
	
	local continueButton = Button.create("Continue", x, y, 0)
	continueButton.onclick = function(uibutton)
		if States.Main.time then
			Game.setState(States.Main)
		end
	end
	continueButton.disabled = true
	
	y = y + advance
	
	local optionsButton = Button.create("Options", x, y, 0)
	optionsButton.onclick = function(uibutton)
		Game.setState(States.Options)
	end
	
	x, y = _floor(400 * sw), _floor(500 * sh)
	local restartButton = Button.create("Restart", x, y, 0)
	restartButton.onclick = function()
		Game.quit("restart")
	end

	y = y + advance
	local quitButton = Button.create("Quit", x, y, 0)
	quitButton.onclick = function()
		Game.quit()
	end
	
	self.buttons = { newgameButton, continueButton, optionsButton, 
		restartButton, quitButton }
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


-- Options State
local Options = createState("options")

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
	local themeCycler = Cycler.create(Game.themenames, x, y, nil, nil, Game.themeindex)
	themeCycler.onclick = function(uibutton, index)
		Game.applyTheme(Game.themes[index])
	end
	
	y = y + advance
	
	labels:addf("Grid Size:", x - 10, "right", 0, y)
	local sizeSlider = Slider.create(Game.size, x, y, limit, 4, 25)
	sizeSlider.onclick = function(uislider, change)
		Game.size = uislider.value
	end
	
	y = y + advance
	
	labels:addf("Music:", x - 10, "right", 0, y)
	local musicSlider = Slider.create(Game.musicvol, x, y, limit, 0, 10)
	musicSlider.onclick = function(uislider, change)
		Game.musicvol = uislider.value
		for k, v in pairs(Game.music) do
			v:setVolume(Game.musicvol / 10)
		end
	end
	
	y = y + advance
	
	labels:addf("Sounds:", x - 10, "right", 0, y)
	local soundSlider = Slider.create(Game.soundvol, x, y, limit, 0, 10)
	soundSlider.onclick = function(uislider, change)
		Game.soundvol = uislider.value
		for k, v in pairs(Game.sounds) do
			v:setVolume(Game.soundvol / 10)
		end
	end
	
	y = y + advance
	
	labels:addf("Highlight:", x - 10, "right", 0, y)
	local hlCycler = Cycler.create({"On", "Off"}, x, y, nil, nil,
		Game.highlight and 1 or 2)
	hlCycler.onclick = function(uibutton, index, value)
		Game.highlight = index == 1
	end
	
	y = y + advance
	
	local fsm = {"Window", "Desktop", "Exclusive"}
	local fsmidx = Game.fullscreen and (Game.fullscreentype == "exclusive" and 3 or 2) or 1
	
	labels:addf("Mode:", x - 10, "right", 0, y)
	local fsmodeCycler = Cycler.create(fsm, x, y, nil, nil, fsmidx)
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
	
	local wwSlider = Slider.create(Game.windowwidth, x, y, limit, 400, dw)
	wwSlider.onclick = function(uislider, change)
		Game.windowwidth = uislider.value
	end
	
	local xw = font:getWidth(" x ")
	labels:addf("x", 2 * limit + xw, "center", x, y)
	
	local whSlider = Slider.create(Game.windowheight, x + limit + xw, y, limit, 300, dh)
	whSlider.onclick = function(uislider, change)
		Game.windowheight = uislider.value
	end

	y = y + advance
	
	labels:addf("Fullscreen Size:", x - 10, "right", 0, y)
	local fssizeCycler = Cycler.create(Game.fsmodenames, x, y, nil, nil, Game.fsindex)
	fssizeCycler.onclick = function(uibutton, index, value)
		Game.fsindex = index
	end

	
	x, y = _floor(400 * sw), _floor(550 * sh)
	
	local backButton = Button.create("Back", x, y, 0)
	backButton.onclick = function(uibutton)
		Game.setState(States.Menu)
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
local Main = createState("main")

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
	
	self.resetButton  = Button.create("Restart", x, y)
	self.resetButton.onclick = function()
		self:clearGrid()
	end
	
	y = y + 50 * sh
	
	self.pauseButton  = Button.create("Pause", x, y)
	self.pauseButton.onclick = function(uibutton, mx, my)
		self.paused = true
		self.resetButton.disabled = true
		self.newgameButton.disabled = true
		for k, b in ipairs(self.buttons) do
			if b == uibutton then self.buttons[k] = self.resumeButton; break end
		end
		self.resumeButton:mousemoved(mx, my)
	end
	
	self.resumeButton  = Button.create("Resume", x, y)
	self.resumeButton.onclick = function(uibutton, mx, my)
		self.paused = false
		self.resetButton.disabled = nil
		self.newgameButton.disabled = nil
		for k, b in ipairs(self.buttons) do
			if b == uibutton then self.buttons[k] = self.pauseButton; break end
		end
		self.pauseButton:mousemoved(mx, my)
	end


	y = 500 * sh
	
	self.newgameButton = Button.create("New", x, y)
	self.newgameButton.onclick = function()
		self:newGame()
	end

	y = y + 50 * sh
	
	self.quitButton    = Button.create("Back", x, y)
	self.quitButton.onclick = function(uibutton)
		Game.setState(States.Menu)
	end

	self.buttons = { self.resetButton, self.pauseButton, self.newgameButton, self.quitButton }
	return self
	
end

function Main:newGame(size, seed, grid)
	size = size or Game.size
	seed = seed or _floor(love.timer.getTime() * 1e4)
	
	self.size = size
	
	
	self.grid = gen_grid(size, seed)
	self.srows, self.scols, self.stotal = gen_gridlist(self.grid)
	self:clearGrid()
	
	if grid then
		for i = 1, size do
		for j = 1, size do
			self:setCell(i, j, grid[i][j])
		end
		end
	end
	
	local fonts = Game.fonts
	local sw, sh = Game.sw, Game.sh
	
	for k, b in ipairs(self.buttons) do
		if b == self.resumeButton then self.buttons[k] = self.pauseButton end
		b.disabled = nil
	end
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
	
	self.cellsize = _floor(math.min(580 * sw - hmax, 580 * sh - vmax) / self.size)
	self.gridsize = self.cellsize * size
	
	self.vmax = vmax
	self.hmax = hmax
	
	self.x = _floor((w - self.gridsize - hmax) / 2 + hmax)
	self.y = _floor((h - self.gridsize - vmax) / 2 + vmax)
	
	return self
	
end

function Main:draw()
	local colors = Game.colors
	local graphics = Game.graphics
	local fonts = Game.fonts
	local sw, sh = Game.sw, Game.sh
	
	for k, b in ipairs(self.buttons) do b:draw() end
	if self.paused then
		love.graphics.setColor(colors.text)
		love.graphics.setFont(fonts.huge)
		local x, y, limit = 0, 100 * sh, 800 * sw
		if self.win then
			love.graphics.printf(string.format("SOLVED:\n%.1fs", self.win),
				x, y, limit, "center")
		else
			love.graphics.printf(string.format("ELAPSED:\n%.1fs", self.time),
				x, y, limit, "center")
		end
		
		return
	end
	
	local size = self.size
	local cs, font = self.cellsize, self.font
	local fonth, fontlh = self.fonth, self.fontlh
	
	local gs = self.gridsize
	local gx, gy = self.x, self.y
	local offset = 0
	

	-- cell indicator
	if Game.highlight and self.cx then
		love.graphics.setColor(colors.highlight)
		love.graphics.rectangle("fill", self.cx, gy - self.vmax, cs, gs + self.vmax)
		love.graphics.rectangle("fill", gx - self.hmax, self.cy, gs + self.hmax, cs)
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
	--love.graphics.printf(string.format("Seed: %i", self.grid.seed),
	--		10 * sw, 120 * sh, gx, "left")
	love.graphics.printf(string.format("Left: %i", self.stotal - self.total),
			10 * sw, 160 * sh, gx, "left")
	if self.win then
		love.graphics.printf(string.format("Solved in\n%.1fs", self.win),
			10 * sw, 200 * sh, gx, "left")
	end
	
end

function Main:update(dt)
	if self.paused then 
		return
	end
	
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

function Main:setCell(cx, cy, value)
	local grid = self.grid
	local oldvalue = grid[cx][cy]
	grid[cx][cy] = value
	
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

function Main:mousepressed(x, y, button)
	if self.paused then
		for k, b in ipairs(self.buttons) do b:mousepressed(x, y, button) end
		return
	end
	
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
		
		self.paintmode = paint
		if paint then
			love.audio.play(Game.sounds.click)
			self:setCell(x, y, paint)
		end
		return
	end
	
	for k, b in ipairs(self.buttons) do b:mousepressed(x, y, button) end
end

function Main:mousemoved(x, y, dx, dy)
	for k, b in ipairs(self.buttons) do b:mousemoved(x, y, dx, dy) end
	
	local cell
	self.cx, self.cy = nil, nil
	x, y, cell = self:getCellAt(x, y)
	if not x then return end
	
	self.cx = self.x + _floor(self.cellsize * (x - 1))
	self.cy = self.y + _floor(self.cellsize * (y - 1))
	
	local paint = self.paintmode
	if paint and cell ~= paint then
		love.audio.play(Game.sounds.click)
		self:setCell(x, y, paint)
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

States.Main = Main:init()
States.Menu = Menu:init()
States.Options = Options:init()

Game.States = States


