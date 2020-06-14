local conv = {}

local function deepCopy(o)
	if type(o) ~= "table" then return o end
	local t = {}
	for k, v in pairs(o) do
		t[k] = deepCopy(v)
	end
	return t
end

local function clamp01(mn, mx, v)
	return (v - mn) / (mx - mn)
end

function conv.applyFilter(field, filter)
	local t = {}
	if (#filter % 2) ~= 1 then error("hey this filter aint odd size") end
	if (#filter[1] % 2) ~= 1 then error("hey this filter aint odd size") end
	local xo, yo = #filter[1]/2+0.5, #filter/2+0.5
	for y, s in ipairs(field) do
		t[y] = {}
		for x, v in ipairs(s) do
			local n = 0
			local _xo, _yo = x-xo, y-yo
			for _y, i in ipairs(filter) do
				for _x, p in ipairs(i) do
					local val = 0
					if field[_y+_yo] == nil then
						val = 0
					elseif field[_y+_yo][_x+_xo] == nil then
						val = 0
					else
						val = field[_y+_yo][_x+_xo]*p
					end
					n = n + val
				end
			end
			t[y][x] = n
		end
	end
	return t
end

function conv.lowestHighestField(field)
	local lo, hi = 0, 0
	for y, s in ipairs(field) do
		for x, v in ipairs(s) do
			if v < lo then lo = v elseif v > hi then hi = v end
		end
	end
	return lo, hi
end

function conv.fieldToImageData(field)
	local i = love.image.newImageData(#field, #field[1])
	for y, s in ipairs(field) do
		for x, v in ipairs(s) do
			i:setPixel(x-1, y-1, v, v, v)
		end
	end
	return i
end

function conv.clampFieldToImageData(field)
	local i = love.image.newImageData(#field, #field[1])
	local lo, hi = conv.lowestHighestField(field)
	for y, s in ipairs(field) do
		for x, v in ipairs(s) do
			local val = clamp01(lo, hi, v)
			i:setPixel(x-1, y-1, val, val, val)
		end
	end
	return i
end

function conv.imageDataToField(img)
	local f = {}
	for y=0,img:getHeight()-1 do
		f[y+1] = {}
		for x=0,img:getWidth()-1 do
			local r, g, b = img:getPixel(x, y)
			f[y+1][x+1] = (r + g + b) / 3
		end
	end
	return f
end

function conv.splitImageData(img)
	local r, g, b = love.image.newImageData(img:getWidth(), img:getHeight()), love.image.newImageData(img:getWidth(), img:getHeight()), love.image.newImageData(img:getWidth(), img:getHeight())
	for x=0,img:getWidth()-1 do
		for y=0,img:getHeight()-1 do
			local pr, pg, pb = img:getPixel(x, y)
			r:setPixel(x, y, pr, pr, pr)
			g:setPixel(x, y, pg, pg, pg)
			b:setPixel(x, y, pb, pb, pb)
		end
	end
	return r, g, b
end

function conv.combineImageData(r, g, b)
	local img = love.image.newImageData(r:getWidth(), r:getHeight())
	for x=0,r:getWidth()-1 do
		for y=0,r:getHeight()-1 do
			local rp, gp, bp = {r:getPixel(x, y)}, {g:getPixel(x, y)}, {b:getPixel(x, y)}
			local rv, gv, bv = (rp[1] + rp[2] + rp[3]) / 3, (gp[1] + gp[2] + gp[3]) / 3, (bp[1] + bp[2] + bp[3]) / 3
			img:setPixel(x, y, rv, gv, bv)
		end
	end
	return img
end

function conv.fieldClamp01(field)
	local f = {}
	local lo, hi = conv.lowestHighestField(field)
	for y, s in ipairs(field) do
		f[y] = {}
		for x, v in ipairs(s) do
			f[y][x] = clamp01(lo, hi, v)
		end
	end
	return f
end

function conv.combineFields(...)
	local args = {...}
	if #args == 0 then error("hey yo this function needs arguments") end
	local f = {}
	for y, s in ipairs(args[1]) do
		f[y] = {}
		for x, v in ipairs(s) do
			local v = {}
			local n = 0
			for i, _v in ipairs(args) do
				n = n + _v[y][x]
			end
			f[y][x] = n / #args
		end
	end
	return f
end

return conv