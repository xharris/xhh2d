## api

```lua

-- state
obj = {
  enter = function(self) end,
  update = function(self, dt) end,
  leave = function(self) end
}
state.push(obj)
state.pop()

-- entity
circle = entity.new{
  render = function(props, children) end,
  defaults = {},
  name = 'circle'
}
entity1 = circle{ ... } -- override default values
entity.destroy(entity1)
print(entity.tree(entity1))

-- entity instance (if there was a circle entity class)
entity1:add(child1, child2, ...) -- self
entity1:z(newIndex) -- self.z
entity1:remove(child1, child2, ...)
entity1:drawChildren() -- self
entity1 [<, <=, >, >=] entity2 -- compare z value
entity1 == entity2 -- same instance
print(entity1)

-- entity class
for e, ent in circle:all() do end

-- system
system.new(function(dt) end)
```

## example

main.lua

```lua
g = require 'engine'
lg = nil

function g.load()
  lg = love.graphics

  state.push(start)
end
```

entities/circle.lua

```lua
return {
  render = function(props, children)
    if props.color == 'blue' then
      lg.setColor(0,0,1)
    end
    lg.circle('fill', 0, 0, 20)
    children() -- draw children (optional)
  end,
  defaults = { color='white', x=0, y=0 },
  name = 'circle' -- optional
}
```

states/start.lua

```lua
return {
  enter = function(self)
    local random_circle = circle{ x=50, y=30, color='blue' }
  end,
  update = function(self, dt) end,
  leave = function(self) end
}
```

systems/CircleMover.lua

```lua
return function(dt)
  for c, circ in circle:all() do
    circ.y = circ.y + dt * circ.dir
  end
end
```
