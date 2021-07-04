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
local submodules = {}
for i, v in ipairs(files) do
	submodules[i] = require("states_" .. v)
end

----- MODULE FUNCTION START -----
return function(Game)
---------------------------------

Game.setState = function(state)
	state = Game.States[state]
	state:mousemoved(love.mouse.getPosition())
	Game.state = state
end

Game.getState = function(state)
	--if not state then return Game.state end
	return Game.States[state]
end

Game.States = {}
Game.stateClasses = {Base = Base}

for i, v in ipairs(submodules) do
	v(Game)
end

for k, v in pairs(Game.stateClasses) do
	if v ~= Base then
		Game.States[k] = v:new()
	end
end

Game.setState("MainMenu")

----- MODULE FUNCTION END -----
end --return function(Game)
---------------------------------