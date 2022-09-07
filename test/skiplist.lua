local sl = require 'xhh2d.skiplist'
local cls = require 'xhh2d.clasp'

local expect = test.expect

local object = cls{
  init = function(self, value)
    self.value = value or 0
  end,
  __ = {
    lt = function(a, b)
      return a.value < b.value
    end,
    le = function(a, b)
      return a.value <= b.value
    end
  }
}

test.describe('skiplist', function()
  local list 

  test.before(function()
    list = sl()  
  end)

  test.it('add an item', function()
    list:insert(1)
    list:insert(2)
    list:insert(3)

    expect(list.size).to.equal(3)
  end)

  test.it('remove an item', function()
    list:insert(1)
    list:insert(2)
    list:insert(3)
    list:delete(3)

    expect(list.size).to.equal(2)
  end)

  test.it('iterate items', function()
    list:insert(1)
    list:insert(2)
    list:insert(3)

    local e = 1
    for i, item in list:ipairs() do 
      expect(item).to.equal(e)
      e = e + 1 
    end 

    list:delete(2)
    e = {1, 3}
    for i, item in list:ipairs() do 
      expect(item).to.equal(e[i])
    end 
  end)

  test.it('iterate while deleting', function()
    local e = {1,2,4}
    for item = 1, 5 do 
      list:insert(item)
    end

    for i, item in list:ipairs() do 
      if item >= 2 then -- deletes 3 and 5
        list:delete(item + 1)
      end
      expect(item).to.equal(e[i])
    end 
  end)

  test.it('reorder items', function()
    local objs = {}
    local o = 1
    local size = 20
    for i = 0, size * 2 do 
      table.insert(objs, object(i))
      list:insert(objs[o])
      o = o + 1
    end

    o = 1
    for i = -size, size do 
      list:delete(objs[o])
      objs[o].value = i
      list:insert(objs[o])
      o = o + 1
    end

    for i, item in list:ipairs() do 
      expect(i - size - 1).to.equal(item.value)
    end
  end)
end)