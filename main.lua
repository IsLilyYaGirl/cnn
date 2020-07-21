local conv = require("conv")

love.graphics.setDefaultFilter("linear", "nearest")

local function deepCopy(o)
	if type(o) ~= "table" then return o end
	local t = {}
	for k, v in pairs(o) do
		t[k] = deepCopy(v)
	end
	return t
end

local field = {}

for y = 1,16 do
	field[y] = {}
	for x = 1,16 do
		field[y][x] = math.random()
	end
end

local inames = love.filesystem.getDirectoryItems("dat")
local tfields = {}
local timgs = {}

for i, v in ipairs(inames) do
	local r, g, b, a = conv.splitImageDataAlpha(love.image.newImageData("dat/" .. v))
	if r:getWidth() ~= 16 then error("bruh wrong size in " .. v) end
	if r:getHeight() ~= 16 then error("bruh wrong size in " .. v) end
	tfields[i] = {conv.imageDataToField(r), conv.imageDataToField(g), conv.imageDataToField(b), conv.imageDataToField(a)}
	timgs[i] = love.graphics.newImage(love.image.newImageData("dat/" .. v))
end

local nets = {}

for i=1,100 do
	nets[i] = {m = {conv.randomFilterMap(16), conv.randomFilterMap(16), conv.randomFilterMap(16), conv.randomFilterMap(12)}, loss = 0, ll = 1}
end

local gen = 1

for i, v in ipairs(nets) do
	v.i = {conv.fieldClamp01(conv.performMap(field, v.m[1])), conv.fieldClamp01(conv.performMap(field, v.m[2])), conv.fieldClamp01(conv.performMap(field, v.m[3])), conv.fieldClamp01(conv.performMap(field, v.m[4]))}
	local lsum = 9999999999999999999
	for ii, vv in ipairs(tfields) do
		if math.min(conv.loss(vv[1], v.i[1]) + conv.loss(vv[2], v.i[2]) + conv.loss(vv[3], v.i[3]) + conv.loss(vv[4], v.i[4])) < lsum then
			v.ll = ii
		end
		lsum = math.min(conv.loss(vv[1], v.i[1]) + conv.loss(vv[2], v.i[2]) + conv.loss(vv[3], v.i[3]) + conv.loss(vv[4], v.i[4]))
	end
	v.loss = lsum --/ #tfields
	v.img = love.graphics.newImage(conv.clampFieldRGBAToImageData(v.i[1], v.i[2], v.i[3], v.i[4]))
end

function netsort(a, b)
	return a.loss < b.loss
end

table.sort(nets, netsort)

love.window.setFullscreen(true)

function love.update()
	for y = 1,16 do
		field[y] = {}
		for x = 1,16 do
			field[y][x] = math.random()
		end
	end
	for i = #nets/2, #nets do
		nets[i] = deepCopy(nets[(i-(#nets/2))+1])
		nets[i].m[1] = conv.mutateMap(nets[i].m[1], -0.3, 0.3)
		nets[i].m[2] = conv.mutateMap(nets[i].m[2], -0.3, 0.3)
		nets[i].m[3] = conv.mutateMap(nets[i].m[3], -0.3, 0.3)
		nets[i].m[4] = conv.mutateMap(nets[i].m[4], -0.3, 0.3)
	end
	for i, v in ipairs(nets) do
		v.i = {conv.fieldClamp01(conv.performMap(field, v.m[1])), conv.fieldClamp01(conv.performMap(field, v.m[2])), conv.fieldClamp01(conv.performMap(field, v.m[3])), conv.fieldClamp01(conv.performMap(field, v.m[4]))}
		local lsum = 9999999999999999999
		for ii, vv in ipairs(tfields) do
			if math.min(conv.loss(vv[1], v.i[1]) + conv.loss(vv[2], v.i[2]) + conv.loss(vv[3], v.i[3]) + conv.loss(vv[4], v.i[4])) < lsum then
				v.ll = ii
			end
			lsum = math.min(conv.loss(vv[1], v.i[1]) + conv.loss(vv[2], v.i[2]) + conv.loss(vv[3], v.i[3]) + conv.loss(vv[4], v.i[4]))
		end
		v.loss = lsum --/ #tfields
		if gen % 10 == 0 then
			v.img = love.graphics.newImage(conv.clampFieldRGBAToImageData(v.i[1], v.i[2], v.i[3], v.i[4]))
		end
	end
	table.sort(nets, netsort)
	gen = gen + 1
end

function love.draw()
	love.graphics.setBackgroundColor(0.5, 0, 0)
	love.graphics.print("Generation " .. gen)
	for i, v in ipairs(timgs) do
		love.graphics.draw(v, ((i-1)*16)%1920, math.floor((i-1)/120)*16+16)
	end
	for i, v in ipairs(nets) do
		love.graphics.draw(v.img, ((i-1)*16)%1920, math.floor((i-1)/120)*16+(math.floor((#timgs-1)/120)*16+48))
		love.graphics.draw(timgs[v.ll], ((i-1)*16)%1920, math.floor((i-1)/120)*16+(math.floor((#timgs-1)/120)*16+64))
	end
end