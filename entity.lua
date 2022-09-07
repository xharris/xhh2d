local M = {}
local class = require 'xhh2d.clasp'
local skiplist = require 'xhh2d.skiplist'
local lume = require 'xhh2d.lume'

local lg = love.graphics
local math_floor = math.floor
local function floor(x) 
    return M.round_pixels and math_floor(x + 0.5) or x
end

M.spawner = {}
M.auto_stack = true
M.round_pixels = true

local id = 0
local Instance = class {
    init = function(self, opts)
        opts = opts or {}
        self._id = id
        id = id + 1
        self.children = skiplist()
    end,
    copy = function(self, other)
        local reserved = {'_id', 'children', '_name', 'render'}
        for k, v in pairs(other) do 
            if type(v) ~= 'function' and not lume.find(reserved, k) then 
                if type(v) == 'table' then 
                    self[k] = lume.clone(v)
                else
                    self[k] = v
                end
            end
        end
        return self
    end,
    z = function(self, z)
        if z ~= nil then
            if self.parent and z ~= self._z then 
                self.parent:remove(self)
                self._z = z
                self.parent:add(self)
            end
            return self
        end
        return self._z
    end,
    add = function(self, ...)
        local child
        for c = 1, select('#', ...) do 
            child = select(c, ...)
            if child.parent then 
                child.parent:remove(child)
            end
            child.parent = self
            self.children:insert(child)
        end
        return self
    end,
    remove = function(self, ...)
        local child
        for c = 1, select('#', ...) do 
            child = select(c, ...)
            self.children:delete(child)
        end
    end,
    drawChildren = function(self)
        local child
        for _, child in self.children:ipairs() do 
            if not child._destroyed then
                child:draw()
            end
        end
        return self
    end,
    draw = function(self)
        if self.render then 
            if M.auto_stack then 
                love.graphics.push('all') 

                lg.translate(-floor(self.ox or 0), -floor(self.oy or 0))
                lg.scale(self.sx or 1, self.sy)
                lg.rotate(self.angle or 0)
                lg.translate(floor(self.x or 0), floor(self.y or 0))
                lg.translate(floor(self.ox or 0), floor(self.oy or 0))
            end
            local children = function()
                self:drawChildren()
            end
            -- srt 
            self:render(children)
            if M.auto_stack then love.graphics.pop() end
        end
        return self
    end,
    __ = {
        lt = function(a, b)
            return (a._z or 0) < (b._z or 0)
        end,
        le = function(a, b)
            return (a._z or 0) <= (b._z or 0)
        end,
        tostring = function(self)
            return self._name .. '-' .. self._id
        end,
        eq = function(a, b)
            return a._id == b._id
        end
    }
}

function M.new(opts)
    opts = opts or {}
    assert(opts.name, 'Give this entity spawner a name')
    local spawner = setmetatable({
        instances = skiplist(),
        -- name = opts.name or 'entity',
        _opts = opts,
        all = function(t)
            return t.instances:ipairs()
        end
    }, {
        __call = function(t, args)
            local instance = Instance()
            instance._name = opts.name or 'entity'
            instance.render = opts.render

            args = lume.merge(opts.defaults or {}, args or {})
            for k, v in pairs(args or {}) do 
                if args._id and instance[k] ~= nil then 
                    -- another entity's properties being copied, so ignore error
                else
                    assert(not instance[k], k .. ' is a reserved entity property')
                    if type(v) == 'function' then 
                        instance[k] = v(instance, args)
                    else 
                        instance[k] = v
                    end
                end
            end
            instance._z = args.z or 0
            if opts.validate then 
                opts.validate(instance)
            end
            
            if M._root and instance ~= M._root then 
                M._root:add(instance)
            end
            t.instances:insert(instance)

            return instance
        end
    })
    for k, v in pairs(opts) do 
        if lume.find({'name', 'render', 'defaults'}, k) ~= nil then 
            spawner[k] = v
        end
    end
    M.spawner[opts.name] = spawner
    return spawner
end

local root = M.new{
    render = function(_, children)
        children()
    end, 
    defaults = { _root = true },
    name = 'root'
}
M._root = root()

function M.draw()
    M._root:draw()
end

-- TODO: doesnt work??
function M.destroy(...)
    local instance
    for i = 1, select('#', ...) do 
        instance = select(i, ...)
        if not instance._destroyed then
            _, err = instance.parent.children:delete(instance)
            if err then 
                error(err)
            end
            M.spawner[instance._name].instances:delete(instance)
        end
        instance._destroyed = true
    end
end

function M.tree(node, maxDepth, depth)
    node = node or M._root
    depth = depth or 0
    if maxDepth ~= nil and depth > maxDepth then 
        return ''
    end
    local str = ''
    -- add node props
    for d = 1, depth do 
        str = str .. '|\t'
    end
    str = str .. '{' .. tostring(node)
    
    local props = {}
    if depth > 0 then 
        for k, v in pairs(node) do 
            if k ~= 'children' and (k == '_z' or string.sub(k, 1, 1) ~= '_') and type(v) ~= 'function' then 
                table.insert(props, k..'='..tostring(v))
            end
        end
    end
    if #props > 0 then 
        str = str .. ': '
    end
    str = str .. table.concat(props, ', ') .. '}'
    -- go through children
    for _, child in node.children:ipairs() do
        if child and child._name and child.parent == node then
            str = str .. '\n' .. M.tree(child, maxDepth, depth + 1)
        end
    end
    return str
end 

function M.leaf(node)
    return M.tree(node, 0)
end

return setmetatable({}, {
    __index = M,
    __call = function(_, name, ...)
        assert(M.spawner[name], 'Entity spawner not found: '..tostring(name))
        return M.spawner[name](...)
    end
})