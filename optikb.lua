dofile("kb.lua")
local skb = dofile("single_key.lua")
print("KB: " .. kb_layout.name)
print("Left Hand:")
skb.left:print()
print("Right Hand:")
skb.right:print()

local test_file = io.open("holmes.txt", "r")
local test_str = test_file:read("*all"):lower()
test_file:close()

local function stat(str)
	local bigrams = {}
	local trigrams = {}
	for i=1,str:len() do
		local bi = str:sub(i, i + 2)
		local tri = str:sub(i, i + 3)
		if bi:len() == 2 then
			bigrams[bi] = (bigrams[bi] or 0) + 1
		end
		if tri:len() == 3 then
			trigrams[tri] = (trigrams[tri] or 0) + 1
		end
	end
	bigrams.total = str:len() - 2
	trigrams.total = str:len() - 3
	return {bigrams = bigrams, trigrams = trigrams}
end
		
local kb   = {
	kb:new('qwerty')  :layout("qwert" .. "[poiuy" .. "asdfg" ..  "';lkjh" .. "\\zxcvb" .. "/.,mn"),
	kb:new('whittish'):layout("vyd,;" .. "]/ulmj" .. "atheb" ..  "'ioncs" .. "\\pkgwq" .. "z.frx"),
	kb:new('dvorak')  :layout("',.py" .. "/lrcgf" .. "aoeui" ..  "[snthd" .. "\\;qjkx" .. "zvwmb"),
	kb:new('solemak') :layout("qwldb" .. "[kyupj" .. "asrtg" ..  "'oienf" .. ";zxcv\\" .. ".,mh/"),
}

local function print_kb(kb)
	local pkb = {
		left = {{},{},{}},
		right = {{},{},{}},
	}
	for key, pos in pairs(kb) do
		if type(pos) == 'table' then
			pkb[pos[1]][pos[2]][pos[3]] = key
		end
	end
	for _, l in ipairs{'left', 'right'} do
		pkb[l] = hand:new():add_row(kb_layout[l][1].base, pkb[l][1]):add_row(kb_layout[l][2].base, pkb[l][2]):add_row(kb_layout[l][3].base, pkb[l][3])
	end
	if kb.name then
		print("KB: " .. kb.name)
	end
	print("Left Hand:")
	pkb.left:print()
	print("Right Hand:")
	pkb.right:print()
end

local function eval_kb(kb, pr)
	-- Long running stats
	-- Finger use recording
	local fingers  = {0,0,0,0,0,0,0,0,}

	-- Short running stats
	local c_hand
	-- Single key costs
	local sk_cost = 0
	-- Same finger cost
	local sf_cost = 0
	local run_fingers = {} -- Table of fingers and the position they were last in

	-- Run information
	local run_cost = 0
	-- Run length cost
	local rl_cost = 0
	local run_hand
	local run_length = 0
	-- Roll effort reduction
	local re_reduc = 0
	local dr_cost = 0
	local last_pos
	local old_run_dir
	for c in test_str:gmatch"." do
		if kb[c] then
			local pos = kb[c]
			-- Single key effort cost - penalises difficult to reach keys
			local effort = skb:effort(pos)
			sk_cost = sk_cost + effort

			-- Finger use tracking
			local finger = skb:finger(pos)
			fingers[finger] = fingers[finger] + 1

			-- Reset run values if changing hand
			if pos[1] ~= run_hand then
				-- Run length cost - penalises same hand runs which are too long
				if run_length ~= 0 then
					local effort = (run_length > 2) and (run_length - 2) or 0
					rl_cost = rl_cost + effort
				end

				-- Reset run values
				run_hand = pos[1]
				run_length = 0
				run_fingers = {}
				-- Reset roll values
				last_finger = nil
				last_pos = nil
				last_run_dir = nil
			end
			run_length = run_length + 1

			-- Same finger use cost - penalises use of the same finger in a run
			if run_fingers[finger] then
				-- Cost is based on how far the finger has to
				-- move from its previous pos
				local old_pos = run_fingers[finger]
				local effort = math.abs(pos[2] - old_pos[2]) + math.abs(pos[3] - old_pos[3])
				-- Effort is doubled to counter the lack of flow penalisation
				sf_cost = sf_cost + (effort * 2)
			end

			-- Roll effort reduction
			if run_length > 1  and last_finger ~= finger then
				-- A roll is a transition from any key with effort 1-3 to another on the same hand (different finger)
				-- The direction is also factored in with a small penalty for rolling in the wrong direction
				-- a change in roll direction also enouters a penalty

				-- Base flow reduction
				local flow = 5 - (skb:effort(last_pos) + effort)
				re_reduc = re_reduc + flow

				-- Directional penalties
				local run_dir
				if finger > last_finger then
					run_dir = 'in'
				else
					run_dir = 'out'
				end

				-- Increase effort if there is a switch in roll direction
				if last_run_dir and run_dir ~= last_run_dir then
					dr_cost = dr_cost + 3
				end

				if run_dir == 'in' then
					-- Reduce effort on an inward roll
					dr_cost = dr_cost - 1
				end
				last_run_dir = run_dir
			end
			run_fingers[finger] = pos
			last_pos = pos
			last_finger = finger
		elseif c == ' ' then
			run_hand = nil
		end
	end

	local cost = sk_cost + sf_cost + rl_cost + dr_cost - re_reduc
	if pr then
		print("******************************")
		print(kb.name .. ";    \t" .. tostring(cost))
		print("Single key efforts cost; " .. tostring(sk_cost))
		print("Same finger cost; " .. tostring(sf_cost))
		print("Run length cost; " .. tostring(rl_cost))
		print("Roll effort reduction; " .. tostring(re_reduc))
		print("Directional cost; " .. tostring(dr_cost))
		io.write("finger use; ")
		io.write("left; ")
		for i=1,4 do
			io.write(" " .. tostring(fingers[i]) .. ", ")
		end
		io.write("right; ")
		for i=8,5,-1 do
			io.write(" " .. tostring(fingers[i]) .. ", ")
		end
		print("")
	end
	return cost
end

--[[
for _, kb in ipairs(kb) do
	eval_kb(kb, true)
end
--]]

-- Start with solemak as a base
local best_kb = kb[4]:clone()
local best_cost = eval_kb(best_kb)

local temp_factor = 0.99885
local start_temp = best_cost

print_kb(best_kb)

-- Outer loop determines the number of iterations
for iter=1,10 do
	local iter_kb = best_kb:clone()
	local iter_cost = best_cost

	local iter_temp = start_temp
	for i=1,10000 do
		io.write(tostring(i) .. " of iter; " .. tostring(iter) .. " with temp; " ..  tostring(iter_temp))
		io.flush()
		iter_kb:rswap()
		local cost = eval_kb(iter_kb)

		if cost > iter_cost then
			local diff = cost - iter_cost
			if math.random() > math.exp(-diff / iter_temp) then
				iter_kb:swap(swap, with)
				cost = iter_cost
			end
		end
		iter_cost = cost

		if iter_cost < best_cost then
			best_kb = iter_kb:clone()
			best_cost = iter_cost

			-- Print new best kb out
			eval_kb(best_kb, true)
			print_kb(best_kb)
			print("")
		end

		iter_temp = iter_temp * temp_factor
		io.write("\r")
	end
	eval_kb(best_kb, true)
	print_kb(best_kb)
end
