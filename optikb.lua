dofile("kb.lua")
local skb = dofile("single_key.lua")
skb.left:print()
skb.right:print()

local test_file = io.open("holmes.txt", "r")
local test_str = test_file:read("*all")
test_file:close()

local kb = kb:new():layout("qwert" .. "[poiuy" .. "asdfg" ..  "';lkjh" .. "\\zxcvb" .. "/.,mn")
local kb2 = kb:new():layout("vyd,;" .. "]/ulmj" .. "atheb" ..  "=ioncs'" .. "\\pkgwq" .. "z.frx")
local kb3 = kb:new():layout("',.py" .. "/lrcgf" .. "aoeui" ..  "-snthd" .. "\\;qjkx" .. "zvwmb")
local kb4 = kb:new():layout("qwldb" .. "[kyupj" .. "asrtg" ..  "'oienf" .. ";zxcv\\" .. ".,mh/")

print(kb['y'][1])
print(kb['y'][2])
print(kb['y'][3])

local function eval_kb(kb)
	local cost = 0
	-- Single hand record - record of use of single hand
	local shr = {}
	for c in test_str:gmatch"." do
		if kb[c] then
			local pos = kb[c]
			-- Single key effort cost
			effort = skb:effort(pos)
			cost = cost + effort
		end
	end
	return cost
end

print("qwerty; " .. tostring(eval_kb(kb)))
print("whittish; " .. tostring(eval_kb(kb2)))
print("dvorak; " .. tostring(eval_kb(kb3)))
print("solemak; " .. tostring(eval_kb(kb4)))
