-- MIT License
-- 
-- Copyright (c) 2021 monolifed
-- 
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
-- 
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local function deepcopy(t, mem)
	if type(t) ~= 'table' then return t end
	if mem[t] then return mem[t] end
	local copy = {}
	mem[t] = copy
	local meta = getmetatable(t)
	for k, v in pairs(t) do
		copy[deepcopy(k, mem)] = deepcopy(v, mem)
	end
	setmetatable(copy, meta)
	return copy
end

local function typeof(class, typename)
	while class do
		if class.name == typename then return true end
		class = class.parent
	end
	return false
end

-- create object with custom init
local function createobject(class, init, ...)
	local object = setmetatable({}, class)
	object.class = class
	init(object, ...)
	return object
end

-- create object with class.init
local function newobject(class, ...) 
	return createobject(class, class.init, ...)
end

local noop = function() end

local base_class = {
	init   = noop,
	typeof = typeof,
	new    = newobject,
	create = createobject,
}
base_class.__index = base_class

-- create new class
local function newclass(name, parent)
	local class = deepcopy(parent or base_class, {})
	class.name   = name
	class.parent = parent
	return class
end

return {
	_deepcopy = deepcopy, _noop = noop,
	base_class = base_class, -- might be useful
	class = newclass, -- only one you need
}
