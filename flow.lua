local curl = {
	0, 1, 1, -1,
}

local function flow_red(ff, rf, fs, rs)
	-- Little finger does not flow
	if ff == 1 then
		return
	end

	-- Ring finger flows to middle finger on the
	-- same row or matches the flow of the middle
	-- finger onto the index
	if ff == 2 then
		if fs == 3 then
			if rs == rf then
				return 1
			else
				return
			end
		end
		return flow_red(3, rf, fs, rs)
	end

	-- Middle finger flows onto the index when the index is on the same
	-- row or curled
	if ff == 3 then
		if fs == 4 then
			if rf <= rs then
				return 1
			else
				return
			end
		end
		return
	end

	-- All flows are defined inwards - so the index finger does not flow
	return
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

local function frow(pos)
	local row = kb_layout[pos[1]][pos[2]]
	-- Index cannot flow when extended, so pretend it is different finger
	local finger = clamp(pos[3] + row.base, 1, 5)
	return finger, pos[2]
end

function flow(pf, ps)
	if ps[1] ~= pf[1] then
		return 0
	end

	local ff, rf = frow(pf)
	local fs, rs = frow(ps)

	return flow_red(ff, rf, fs, rs) or -2
end
