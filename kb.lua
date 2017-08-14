hand = {}
hand.__index = hand

-- base is the offset of the row from the little finger
-- qwerty (iso 105) is -2 on the right hand, 0 on the left
function hand:add_row(base, values)
	values.base = base
	self[#self + 1] = values
	return self
end

function hand:print()
	for i, row in ipairs(self) do
		io.write(i .. "; ")
		for i=row.base,-3,-1 do
			io.write(" ")
		end
		for i, key in ipairs(row) do
			io.write(key)
		end
		io.write("\t")
		for k, v in pairs(row) do
			if type(k) ~= 'number' then
				io.write(tostring(k) .. " = " .. tostring(v))
			end
		end
		io.write("\n")
	end
end

function hand:new()
	return setmetatable({}, hand)
end
-- The keyboard is a table of key {hand, row, index} pairs
kb = {}
kb.__index = kb

function kb:new(name)
	local t = setmetatable({}, kb)
	t.name = name
	for r=1,3 do
		for _, hand in ipairs{'left', 'right'} do
			local row = kb_layout[hand][r]
			for i=1,row.length do
				t[#t + 1] = {hand, r, i}
			end
		end
	end
	return t
end

function kb:layout(str)
	self.str = str
	for c in str:gmatch"." do
		self[c] = table.remove(self, 1)
	end
	return self
end

function kb:swap(a, b)
	local temp = self[a]
	self[a] = self[b]
	self[b] = temp
end

-- Shallow clone as all contained structures are constant
function kb:clone()
	local new = setmetatable({}, kb)
	for k, v in pairs(self) do
		new[k] = self[k]
	end
	return new
end

-- Predefined layouts used for calculating costs
-- Number rows are not included in analysis as 
-- most symbols are not common, so should be optimised by hand

-- iso 105 right shifted to rest right index on qwerty k
-- middle keys (qwerty yh) are ignored as they are too sub-optimal
-- and are equidistant to both hands
iso105_right = {
	name = "Iso 105 (rightshifted)",
	left = {
		-- Number row { base = -2, length = 7},
		-- Letter rows
		{ base = 0, length = 5 },
		{ base = 0, length = 5 },
		{ base = 0, length = 6 },
	},
	right = {
		-- Number row { base = 0, length = 6},
		-- Letter rows
		{ base = -1, length = 6 },
		{ base = -1, length = 6 },
		{ base = 1, length = 5 },
	}
}

kb_layout = iso105_right
