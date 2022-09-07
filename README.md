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
circle = x2d.entity.new{
  name = 'circle',
  render = function(props, children) end,
  defaults = {
    prop1 = 5,
    prop2 = function(self, args)
      return args.prop1 * 20
    end
  },
  validate = function(self)
    assert(self.prop1 <= 10, 'prop1 cannot exceed 10')
  end
}
entity1 = x2d.entity.circle{ ... } -- override default values
-- entity('circle', {...})
entity.destroy(entity1)
print(entity.tree(entity1))

entity1._id
entity1.children -- skiplist
-- entity instance (if there was a circle entity class)
entity1:add(child1, child2, ...) -- self
entity1:z(newIndex) -- self.z
entity1:remove(child1, child2, ...)
entity1:drawChildren() -- self
entity1:copy(enitity2) -- self (shallow copies non-function properties from entity2 to entity1)
entity1 [<, <=, >, >=] entity2 -- compare z value
entity1 == entity2 -- same instance
print(entity1)

-- entity class
for e, ent in circle:all() do end
circle:count()

-- system
system.new(function(dt) end)

-- skiplist
sl:insert(v)
sl:delete(v)
for i, v in sl:iter() do
sl:visualize()

-- "global"
x2d.getWidth()
x2d.getHeight()
x2d.mousePosition()
```

## example

main.lua

```lua
x2d = require 'xhh2d'
lg = nil

function x2d.load()
  lg = love.graphics

  state.push(x2d.state.start)
end
```

entities/circle.lua

```lua
return {
  name = 'circle',
  render = function(props, children)
    if props.color == 'blue' then
      lg.setColor(0,0,1)
    end
    lg.circle('fill', 0, 0, 20)
    children() -- draw children (optional)
  end,
  defaults = { color='white', x=0, y=0 }
}
```

states/start.lua

```lua
return {
  enter = function(self)
    local random_circle = x2d.entity.circle{ x=50, y=30, color='blue' }
  end,
  update = function(self, dt) end,
  leave = function(self) end
}
```

systems/CircleMover.lua

```lua
return function(dt)
  for c, circ in x2d.entity.circle:all() do
    circ.y = circ.y + dt * circ.dir
  end
end
```
