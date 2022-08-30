-- xhh 2022, MIT License
-- skiplist.lua - fast linked list
-- -- inserted values must be comparable using < and <=

local function init(self)
	self._head = { next=nil, down=nil, height=1 } -- points to tallest pointer in _column
	self._bottom = self._head
	self.size = 0
end

local function insert(self, v)
	local history = {}
	local cur = self._head
	local done = false
	while cur do
		if not cur.next or cur.next.value > v then 
			-- move down
			history[cur.height] = cur
			cur = cur.down 
		elseif cur.next.value <= v then 
			-- move right
			cur = cur.next
		end
	end

	-- flip [height+1] coins, insertion height is number of heads (node_h)'
	local node_h = 1-- min( self.maxLevel, - floor(log(random()) / log(2) ) )
	local rand = math.random(101) 
	while rand >= 50 and node_h <= self._head.height + 1 do 
		node_h = node_h + 1 
	end

	local down = nil
	for h = 1, node_h do 
		local node
		-- tallest node to the left is root
		if not history[h] then
			node = { next=nil, down=down, height=h, value=v }
			self._head = { next=node, down=self._head, height=h }
		else 
			node = { next=history[h].next, down=down, height=h, value=v }
			history[h].next = node
		end
		down = node
	end
	self.size = self.size + 1
end

local function delete(self, v)
	local cur = self._head 
	local done = false 
	while cur do 
		-- in a column before v and cut ties with it
		if cur.next and cur.next.value == v then 
			cur.next = cur.next.next 
			cur = cur.down
		elseif not cur.next or cur.next.value >= v and cur.down then 
			-- move down
			cur = cur.down
		else
			-- move right
			cur = cur.next
		end
	end
	self.size = self.size - 1
end

local function iter(self)
	local node = self._bottom
	local i = 0
	return function()
		i = i + 1 
		node = node.next 
		if node then return i, node.value end
	end
end

-- print how things are linked, kind of ...
local function visualize(self)
	local node = self._head 
	while node do 
		local node2 = node 
		local str = ''
		while node2 do 
			str = str .. tostring(node2.value) .. ' -> '
			node2 = node2.next 
		end
		print(str .. 'nil')
		node = node.down 
	end
end

return function()
	local new = {
		insert = insert,
		delete = delete,
		ipairs = iter,
		visualize = visualize
	}
	init(new)
	return new
end