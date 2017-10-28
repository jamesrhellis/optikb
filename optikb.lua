dofile("kb.lua")
local skb = dofile("single_key.lua")
dofile("flow.lua")
print("KB: " .. kb_layout.name)
print("Left Hand:")
skb.left:print()
print("Right Hand:")
skb.right:print()

math.randomseed(os.time())

local function stat(str)
	local single = {}
	local bigrams = {}
	local trigrams = {}
	for i=1,str:len() do
		local si = str:sub(i, i)
		single[si] = (single[si] or 0) + 1

		local bi = str:sub(i, i + 1)
		if bi:len() == 2 then
			bigrams[bi] = (bigrams[bi] or 0) + 1
		end
		--[[
		local tri = str:sub(i, i + 2)
		if tri:len() == 3 then
		trigrams[tri] = (trigrams[tri] or 0) + 1
		end
		--]]
	end
	--[[
	single.total = str:len() - 1
	bigrams.total = str:len() - 2
	trigrams.total = str:len() - 3
	--]]
	return {single = single, bigrams = bigrams--[[, trigrams = trigrams]]}
end

local test_file = io.open("holmes.txt", "r")
local stats = stat(test_file:read("*all"):lower())
test_file:close()

local kb   = {
	kb:new('qwerty')  :layout("qwert" .. "[poiuy" .. "asdfg" ..  "';lkjh" .. "\\zxcvb" .. "/.,mn"),
	kb:new('whittish'):layout("vyd,;" .. "]/ulmj" .. "atheb" ..  "'ioncs" .. "\\pkgwq" .. "z.frx"),
	kb:new('dvorak')  :layout("',.py" .. "/lrcgf" .. "aoeui" ..  "[snthd" .. "\\;qjkx" .. "zvwmb"),
	kb:new('solemak') :layout("qwldb" .. "kyupj" .. "asrtg" ..  "oienf" .. "zxcv" .. ".,mh"),
}

local function print_kb(kb)
	local pkb = {
		left = {{},{},{}},
		right = {{},{},{}},
	}
	for key, pos in pairs(kb) do
		if type(pos) == 'table' and key ~= 'swappable' then
			pkb[pos[1]][pos[2]][pos[3]] = key
		end
	end
	for _, l in ipairs{'left', 'right'} do
		pkb[l] = hand:new():add_row(kb_layout[l][1].base, pkb[l][1])
		                   :add_row(kb_layout[l][2].base, pkb[l][2])
				   :add_row(kb_layout[l][3].base, pkb[l][3])
	end
	if kb.name then
		print("KB: " .. kb.name)
	end
	print("Left Hand:")
	pkb.left:print()
	print("Right Hand:")
	pkb.right:print()
end

local function evalkb(kb, stats, prt)
	local sk_cost = 0
	local fingers = {0,0,0,0,0,0,0,0}
	-- Single key cost costs
	for char, v in pairs(stats.single) do
		local pos = kb[char]
		if pos then
			local cost = skb:effort(pos) * v
			sk_cost = sk_cost + cost

			-- Finger use tracking
			local finger = skb:finger(pos)
			fingers[finger] = fingers[finger] + v
		end
	end
	local sf_cost = 0
	local fl_red = 0
	-- Bigram cost
	for bi, v in pairs(stats.bigrams) do
		local first = kb[bi:sub(1,1)]
		local sec = kb[bi:sub(2,2)]

		if first and sec then
			-- Same finger use cost
			local ff = skb:finger(first)
			local fs = skb:finger(sec)
			if ff == fs then
				-- Cost is based on distance moved
				-- Vertical distance squared + 1
				-- Or flat cost of 2 if horizontal (can never move more than 1)
				if first[2] ~= sec[2] then
					sf_cost = sf_cost + (math.pow(math.abs(first[2] - sec[2]), 2) + 1) * v
				else
					sf_cost = sf_cost + 2 * v
				end
			-- Check that the fingers are on the same hand
			elseif (ff <= 4 and fs <= 4) or (ff > 4 and fs > 4) then
				local ef = skb:effort(first)
				local es = skb:effort(sec)

				fl_red = fl_red + (flow(first,sec) * v)

			end
		end
	end
	local cost = sk_cost + sf_cost - fl_red

	if prt then
		print("******************************")
		print(kb.name .. ";    \t" .. tostring(cost))
		print("Single key efforts cost; " .. tostring(sk_cost))
		print("Same finger cost; " .. tostring(sf_cost))
		print("Flow cost reduction; " .. tostring(fl_red))
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
	evalkb(kb, stats, true)
end
--]]

local best_kb = kb[4]:clone()
--
-- Start with solemak as a base
local best_cost = evalkb(best_kb, stats)

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
		local swap, with = iter_kb:rswap()
		local cost = evalkb(iter_kb, stats)

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
			evalkb(best_kb, stats, true)
			print_kb(best_kb)
			print("")
		end

		iter_temp = iter_temp * temp_factor
		io.write("\r")
	end
end
--]]
