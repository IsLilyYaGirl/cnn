local conv = require("conv")

--local field = conv.imageDataToField(love.image.newImageData("dat/field.png"))

local field = {}

for y = 1,64 do
	field[y] = {}
	for x = 1,64 do
		field[y][x] = math.random()
	end
end

--[[
local field = {
	{1,1,1,0,0,0},
	{1,0,1,0,0,0},
	{1,1,1,0,0,0},
	{0,0,0,1,1,1},
	{0,0,0.2,1,0.5,1},
	{0,0,0,1,1,1}
}]]

--[[
local filter = {
	{0,-0.2,-0.2,-0.2,0},
	{-0.2,0.7,1,0.7,-0.2},
	{-0.2,1,-2.5,1,-0.2},
	{-0.2,0.7,1,0.7,-0.2},
	{0,-0.2,-0.2,-0.2,0},
}]]

local filter = {
	{-0.2,1,-0.2},
	{-0.2,1,-0.2},
	{-0.2,1,-0.2},
}

local filter2 = {
	{-0.2,-0.2,-0.2},
	{1,1,1},
	{-0.2,-0.2,-0.2},
}

local t = conv.applyFilter(field, filter)
t = conv.fieldClamp01(t)
for i=1,20 do
	if i % 2 == 0 then
		t = conv.applyFilter(t, filter2)
	else
		t = conv.applyFilter(t, filter)
	end
	t = conv.fieldClamp01(t)
end

--t = conv.combineFields(t, field)

print(conv.lowestHighestField(t))

--[[
for x, s in ipairs(t) do
	print(table.concat(s, " "))
end]]

love.graphics.setDefaultFilter("linear", "nearest")

local _ti = conv.clampFieldToImageData(t)

_ti:encode("png", "convoluteTexture.png")

local fi = love.graphics.newImage(conv.fieldToImageData(field))
local ti = love.graphics.newImage(_ti)

function love.draw()
	love.graphics.scale(4)
	love.graphics.setBackgroundColor(0.5, 0, 0)
	love.graphics.draw(fi)
	love.graphics.draw(ti, #field+1, #field[1]+1)
end