local _floor, _ceil = math.floor, math.ceil
local _sf = string.format

local simpleclass = require "simpleclass"
local noop = simpleclass._noop
local class = simpleclass.class

local Base = class("Base")
local stateCallbacks = {
	"update", "mousemoved", "mousepressed", "mousereleased",
	"draw", "keypressed", "keyreleased", "textinput",
	"quit"
}
for k, v in ipairs(stateCallbacks) do Base[v] = noop end

function Base:init()
	local connector = {}
	for i, cbname in ipairs(stateCallbacks) do
		connector[cbname] = function(...)
			return self[cbname](self, ...)
		end
	end
	self.connector = connector
end

function Base:connect()
	local connector = self.connector
	for cbname, cb in pairs(connector) do
		love[cbname] = cb
	end
	self:mousemoved(love.mouse.getPosition())
end

local files = {"mainmenu", "optionsmenu", "maingame", "pausemenu"}
local submodules = {}
for i, v in ipairs(files) do
	submodules[i] = require("states_" .. v)
end

----- MODULE FUNCTION START -----
return function(Game)
---------------------------------

Base.quit = function() return Game.onQuit() end

Game.setState = function(state)
	state = Game.States[state]
	state:connect()
	Game.state = state -- not used however it will be hard to tell the state without it
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