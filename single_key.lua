-- This file manages single key costs
local effort = {
	{ base = -1, 9,6,2,2,3,5,9,}, -- llrmiii
	{ base = -1, 7,2,1,1,1,5,7,}, -- lLRMIii
	{ base = 0,    5,4,4,2,3,7,}, --  lrmiii
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

function sk_effort:effort(pos)
	return self[pos[1]][pos[2]][pos[3]]
end

function sk_effort:finger(pos)
	local row = self[pos[1]][pos[2]]
	local finger = pos[3] + row.base

	if pos[1] == 'right' then
		finger = finger + 4
	end
	return finger
end

return sk_effort
