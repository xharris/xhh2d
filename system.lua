local M = {}

local lume = require "xhh2d.lume"
M.systems = {}

function M.new(fn)
    assert(type(fn) == 'function', 'System must be a function. Found: '..type(fn))
    lume.push(M.systems, fn)
end

function M.update(dt)
    for _, sys in ipairs(M.systems) do 
        sys(dt)
    end
end

return M 