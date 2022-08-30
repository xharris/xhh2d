local M = {}

local lume = require "xhh2d.lume"
local push = require 'xhh2d.push'
M.entity = require 'xhh2d.entity'
M.state = require 'xhh2d.state'
local system = require 'xhh2d.system'

M.lume = lume
M.push = push
entity = M.entity 
state = M.state

local function iterFiles(dir, fn)
    local info 
    for _, file in ipairs(love.filesystem.getDirectoryItems(dir:gsub('%.', '/'))) do
        info = love.filesystem.getInfo(dir:gsub('%.', '/')..'/'..file)
        if info then 
            if info.type == 'directory' then 
                iterFiles(dir..'.'..file, fn)
            elseif info.type == 'file' then
                fn(file:gsub("%.lua", ""), dir..'.'..file:gsub("%.lua", ""), fn)
            end
        end
    end
end

function M.init(opts)
    M._seed = os.time()
    math.randomseed(M._seed)

    opts = lume.merge({
        global_modules = false,
        path_entity = 'entities',
        path_state = 'states',
        path_system = 'systems'
    }, opts or {})

    M.state = {}
    M.entity = {}
    M.system = {}

    -- entities 
    iterFiles(opts.path_entity, function(file, path)
        local r = require(path)
        M.entity[file] = entity.new(r)
        -- imports[path] = M.entity[file]
        if opts.global_modules then 
            _G[file] = M.entity[file]
        end
    end)

    -- states 
    iterFiles(opts.path_state, function(file, path)
        local r = require(path)
        M.state[file] = r
        -- imports[path] = M.state[file]
        if opts.global_modules then 
            _G[file] = M.state[file]
        end
    end)

    -- systems
    iterFiles(opts.path_system, function(file, path)
        local r = require(path)
        M.system[file] = system.new(r)
        -- imports[path] = M.state[file]
        if opts.global_modules then 
            _G[file] = M.system[file]
        end
    end)
end

local time = 0
function M.update(dt)
    time = time + dt 
    state.update(dt)
    system.update(dt)
end

function M.render()
    entity.draw()
end

M.debug = {}

-- markdown utility
local function header(t)
    local h1 = ''
    local h2 = ''
    for h, header in pairs(t) do 
        h1 = h1 .. '| '..header..' '
        h2 = h2 .. '| --- '
    end
    print(h1 .. '|\n' .. h2 .. '|')
end
local function row(t)
    local row = ''
    for c, col in pairs(t) do 
        row = row .. '| '
        if type(col) == 'table' then 
            local str_t = {}
            for k, v in pairs(col) do 
                table.insert(str_t, k .. '=' .. tostring(v))
            end
            row = row .. '{ ' .. table.concat(str_t, ', ') .. ' }'
        else 
            row = row .. tostring(col)
        end
        row = row .. ' '
    end
    print(row .. '|')
end
local function code(fn)
    print('```')
    fn()
    print('```')
end

function M.debug.markdown(no_print)
    local output = ''
    local out = function(...)
        for i = 1, select('#', ...) do 
            output = output .. tostring(select(i, ...))
        end
        output = output .. '\n'
    end
    local old_print = print
    print = out 
    out('# INFO')
    code(function()
        out('seed = '..tostring(M._seed))
        out('entity.auto_stack = '..tostring(entity.auto_stack))
        out('game time = '..tostring(time))
        out('systems = '..tostring(#system.systems))
    end)

    out()
    out('# STATE')
    header{'name', 'stack index', 'starting', 'leaving', 'callbacks'}
    for name, st in pairs(M.state) do 
        local idx = lume.find(state.stack, st)
        local callbacks = {}
        if st.enter then table.insert(callbacks, 'enter') end
        if st.update then table.insert(callbacks, 'update') end
        if st.leave then table.insert(callbacks, 'leave') end
        row{name, idx, st._starting, st._leaving, table.concat(callbacks, ',')}
    end

    out()
    out('# ENTITY')
    header{'name', 'count', 'render fn', 'defaults'}
    for filename, ent in pairs(M.entity) do 
        row{ent._opts.name, ent.instances.size, ent._opts.render ~= nil, ent._opts.defaults}
    end
    
    out()
    out('# ENTITY TREE')
    code(function()
        out(entity.tree())
    end)

    print = old_print
    if not no_print then print(output) end
    return output
end

-- local old_err = love.errorhandler 
-- function love.errorhandler(msg) 
--     local debugstr = M.debug.markdown()
--     local f = io.open('error.md')
--     io.write(debugstr, 'w+')
--     io.close(f)
--     return old_err(msg)
-- end

local w, h = love.window.getMode()
push:setupScreen(w, h, w, h, {
    fullscreen = love.window.getFullscreen(), 
    resizable = true,
    highdpi = true,
    canvas = true
})
function love.load()
    -- love.graphics.setDefaultFilter("nearest", "nearest")
    M.init()
    local callbacks = {'keypressed', 'keyreleased'}
    for _, name in ipairs(callbacks) do 
        love[name] = function(...)
            if M[name] then 
                M[name](...)
            end
        end
    end
    if M.load then 
        M.load()
    end
end

function love.update(dt)
    M.update(dt)
    if M.update then 
        M.update(dt)
    end
end 

-- resolution scaling stuff
function M.getWidth()
    return push:getWidth()
end
function M.getHeight()
    return push:getHeight()
end
function M.mousePosition()
    return push:toGame(love.mouse.getPosition())
end

function love.draw()
    push:start()
    if M.draw then 
        M.draw(M.render)
    else 
        M.render()
    end
    push:finish()
end

function love.resize(w, h)
    if M.resize then M.resize(w, h) end 
    push:resize(w, h)
end

function love.quit(...)
    if M.quit then 
        return M.quit(...)
    end
end


return M 