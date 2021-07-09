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


local function CalculateFontHeight(filename)
	local totalRatioH = 0
	local startPt, endPt = 8, 144
	local count = (endPt - startPt + 1)
	for i = startPt, endPt do
		local font = love.graphics.newFont(filename, i)
		totalRatioH = totalRatioH + font:getHeight() / i
		font:release()
	end
	return totalRatioH / count
end

--print(CalculateFontHeight("media/Jost-500-Medium.otf"))
--print(CalculateFontHeight("media/VenrynSans-Regular.ttf"))