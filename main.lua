local Game = require "game"

function love.load()
	love.keyboard.setKeyRepeat(true)
end

local draw_loading = function()
	local w, h = love.graphics.getDimensions()
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", 0, 0, w, h)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("LOADING...", 5, 5)
end

function love.update(dt)
	if love.draw ~= draw_loading then love.draw = draw_loading return end
	Game.load()
end
