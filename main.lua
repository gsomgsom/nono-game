local Game = require "game"

function love.load()
	love.keyboard.setKeyRepeat(true)
end

local draw_loading = function()
	w, h = love.graphics.getDimensions()
	love.graphics.setColor(0,0,0)
	love.graphics.rectangle("fill", 0,0,w,h)
	love.graphics.setColor(1,1,1)
	love.graphics.print("LOADING...", 5, 5)
end

function love.update(dt)
	if love.draw ~= draw_loading then love.draw = draw_loading return end
	Game.load()
	
	function love.draw()
		Game.state:draw()
	end

	function love.update(dt)
		Game.state:update(dt)
	end

	function love.mousepressed(x, y, button)
		Game.state:mousepressed(x,y,button)
	end

	function love.mousereleased(x, y, button)
		Game.state:mousereleased(x,y,button)
	end

	function love.mousemoved(x, y, dx, dy)
		Game.state:mousemoved(x, y, dx, dy)
	end

	function love.keypressed(key)
		Game.state:keypressed(key)
	end

	function love.keyreleased(key)
		Game.state:keyreleased(key)
	end

	function love.textinput(text)
		Game.state:textinput(text)
	end

	function love.quit()
		Game.onQuit()
		return false
	end
	
end
