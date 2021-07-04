local _floor, _ceil = math.floor, math.ceil
local _sf = string.format

local Game = require "game"

local simpleclass = require "simpleclass"
local noop = simpleclass._noop
local class = simpleclass.class

local Base = class("Base")
local stateFunctions = {
	"update", "mousemoved", "mousepressed", "mousereleased",
	"draw", "keypressed", "keyreleased", "textinput"
}
for k, v in ipairs(stateFunctions) do Base[v] = noop end

local files = {"mainmenu", "optionsmenu", "maingame", "pausemenu"}

Game.initStates = function()
	Game.States = {}
	Game.stateClasses = {Base = Base}
	
	for i, v in ipairs(files) do
		local f = require("states_" .. v)
		f(Game)
	end
	
	for k, v in pairs(Game.stateClasses) do
		if v ~= Base then
			Game.States[k] = v:new()
		end
	end
	
	Game.setState("MainMenu")
end

Game.setState = function(state)
	state = Game.States[state]
	state:mousemoved(love.mouse.getPosition())
	Game.state = state
end

Game.getState = function(state)
	--if not state then return Game.state end
	return Game.States[state]
end

Game.resetState = function(state)
	local name = state.class.name
	Game.States[name] = Game.stateClasses[name]:new()
	if Game.state == state then
		Game.setState(name)
	end
end
