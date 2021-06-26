local Game = require "game"
function Game.saveConfig() end
function Game.loadConfig() end


local width, height = love.graphics.getDimensions()
local whstring = string.format("%ix%i", width, height)

local screenSettings =  {
	width = width, height = height, windowwidth = width, windowheight = height,
	deskwidth = width, deskheight = height,
	fullscreen = false, fullscreentype = nil,
	fsmodes = {{width = width, height = height}},
	fsmodenames = {whstring}, 
	fsname = whstring, fsindex = 1,
}

function Game.getScreenSettings()
	return screenSettings
end
