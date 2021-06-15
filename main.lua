local Game = require "game"

function love.load()
	love.keyboard.setKeyRepeat(true)
	Game.load()
end

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