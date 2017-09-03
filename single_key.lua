-- This file manages single key costs
--[[
local effort = {
	{ base = -1, 9,6,2.2,2,3,5,9,}, -- llrmiii
	{ base = -1, 7,2,1.2,1,1,5,7,}, -- lLRMIii
	{ base = 0,    5,5,4,2,3,7,}, --  lrmiii
}
-]]
local effort = {
	{ base = 0, 6,2.2,2,3,5,}, -- lrmii
	{ base = 0, 2.4,1.2,1,1,5,}, -- LRMIi
	{ base = 1,   5,  4,2,3,}, --  rmii
}

-- The leut top row is asymetric, and harder to reach
local left_top_offset = {
	base = 0, 1, 1, 1, 1, -1
}

-- Calculations require that the global kb_layout is set to a valid layout
sk_effort = {
	left = hand:new(),
	right = hand:new(),
}
for _, l in ipairs{'left', 'right'} do
	for i, v in ipairs(kb_layout[l]) do
		offset = v.base - effort[i].base
		local values = {}
		for j=offset+1, offset+v.length do
			values[#values+1] = effort[i][j]
		end
		sk_effort[l]:add_row(v.base, values)
	end
end

for i, v in ipairs(left_top_offset) do
	sk_effort.left[1][i] = sk_effort.left[1][i] + v
end

function sk_effort:effort(pos)
	return self[pos[1]][pos[2]][pos[3]]
end

local function clamp(val, min, max)
	if val < min then
		return min
	elseif val > max then
		return max
	else
		return val
	end
end

function sk_effort:finger(pos)
	local row = self[pos[1]][pos[2]]
	local finger = clamp(pos[3] + row.base, 1, 4)

	-- Fingers are kept in the same order to allow for 
	-- checking inwards rolling rather than direction
	if pos[1] == 'right' then
		finger = finger + 4
	end
	return finger
end

return sk_effort
