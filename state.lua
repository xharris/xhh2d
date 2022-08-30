local lume = require "engine.lume"
local M = {}

M.stack = {}

function M.push(state)
    lume.merge(state, {
        _starting = true,
        _leaving = false,
        enter = nil, 
        update = nil, 
        -- return true to stay in state
        leave = nil, 
    })
    state._starting = true
    state._leaving = false
    lume.push(M.stack, state)
    if state.enter then state:enter() end
    return M
end

function M.pop()
    M.stack[#M.stack]._leaving = true
end

function M.update(dt)
    lume.filter(M.stack, function(state)
        if state.update then state:update(dt) end
        state._starting = false
        if state._leaving then 
            if state.leave then return state:leave() end
            return false
        end
        return true
    end)
end

return M