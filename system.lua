local M = {}

local lume = require "engine.lume"
M.systems = {}

function M.new(fn)
    lume.push(M.systems, fn)
end

function M.update(dt)
    for _, system in ipairs(M.systems) do 
        system(dt)
    end
end

return M 