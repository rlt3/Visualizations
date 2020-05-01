local perlin = require("perlin")
local Queue = require("Queue")

function love.keypressed (key, unicode)
    if key == "escape" or key == "q" then
        love.event.quit()
    end
end

function math.clamp (min, max, v)
    if v < min then return min end
    if v > max then return max end
    return v
end

-- Gives a precise random decimal number given a minimum and maximum
function math.prandom (min, max)
    return math.random() * (max - min) + min
end

function shuffle (t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

function hsv2rgb (h, s, v)
	local r, g, b
	local i = math.floor(h * 6);
	local f = h * 6 - i;
	local p = v * (1 - s);
	local q = v * (1 - f * s);
	local t = v * (1 - (1 - f) * s);
	i = i % 6
	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	elseif i == 5 then r, g, b = v, p, q
	end
	return r, g, b
end

function rgb2hsv (r, g, b)
	r, g, b = r / 255, g / 255, b / 255
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local h, s, v
	v = max
	local d = max - min
	if max == 0 then s = 0 else s = d / max end
	if max == min then
		h = 0
	else
		if max == r then
		h = (g - b) / d
		if g < b then h = h + 6 end
		elseif max == g then h = (b - r) / d + 2
		elseif max == b then h = (r - g) / d + 4
		end
		h = h / 6
	end
	return h, s, v
end


function routine (iter, update)
    return coroutine.create(function ()
        iter(update)
    end)
end

function iter_scan (update, start, final, step)
    for y = start, final, step do
        for x = 0, Width - 1 do
            update(x, y)
        end
        if y % 2 == 0 then
            coroutine.yield()
        end
    end
end

function iter_scan_up (update)
    iter_scan(update, Height - 1, 0, -1)
end

function iter_scan_down (update)
    iter_scan(update, 0, Height - 1, 1)
end

function iter_radius (update)
    local ctr = { x = 300, y = 300 }

    -- hashmap to speedup checking of already checked pixels
    local visited = {}
    for x = 0, Width do
        visited[x] = {}
    end

    for radius = 1, 450 do
        for degree = 0, 360, 0.05 do
            local angle = math.rad(degree)
            local x = ctr.x + (math.cos(angle) * radius)
            local y = ctr.y + (math.sin(angle) * radius)
            x = math.clamp(0,  Width - 1, math.floor(x))
            y = math.clamp(0, Height - 1, math.floor(y))
            if not visited[x][y] then
                visited[x][y] = true
                update(x, y)
            end
        end
        coroutine.yield()
    end

    visited = nil
end

function iter_rect (update)
    local ctr = { x = 300, y = 300 }
    for r = 0, 300 do
        local xleft = math.max(ctr.x - r, 0) 
        local xright = math.min(ctr.x + r, Width - 1) 
        local ytop = math.max(ctr.y - r, 0)
        local ybot = math.min(ctr.y + r, Height - 1)
        for x = xleft, xright do
            update(x, ytop)
        end
        for y = ytop, ybot do
            update(xright, y)
        end
        for x = xleft, xright do
            update(x, ybot)
        end
        for y = ytop, ybot do
            update(xleft, y)
        end
        coroutine.yield()
    end
end

function iter_random (update)
    local pixels = {}
    for y = 0, Height - 1 do
        for x = 0, Width - 1 do
            table.insert(pixels, {x, y})
        end
    end
    shuffle(pixels)
    for i = 1, #pixels do
        update(pixels[i][1], pixels[i][2])
        if i % (Width * 2) == 0 then
            coroutine.yield()
        end
    end
end

function noise (x, y)
    local n = perlin:noise(x*F*(1/64.0), y*F*(1/64.0)) * 1.0 +
              perlin:noise(x*F*(1/32.0), y*F*(1/32.0)) * 0.5 +
              perlin:noise(x*F*(1/16.0), y*F*(1/16.0)) * 0.25 +
              perlin:noise(x*F*(1/8.0),  y*F*(1/8.0))  * 0.125
    n = (n * 0.5) + 0.5
    if x < 0 or x > Width - 1 or y < 0 or y > Height - 1 then
        error("Out of Range (" .. x .. ", " .. y .. ")")
    end
    Pixels:setPixel(x, y, n, n, n, 1)
end

function smooth (x, y)
    local n = Pixels:getPixel(x, y)
    local h, s, v

    if n < 0.25 then
        h, s, v = rgb2hsv(19, 55, 112)
    elseif n < 0.40 then
        h, s, v = rgb2hsv(66, 135, 245)
    elseif n < 0.50 then
        h, s, v = rgb2hsv(176, 153, 37)
    elseif n < 0.75 then
        h, s, v = rgb2hsv(29, 153, 33)
    else
        h, s, v = rgb2hsv(140, 33, 14)
    end

    local r, g, b = hsv2rgb(h, s * n, v)
    Pixels:setPixel(x, y, r, g, b)
end

function love.load ()
    math.randomseed(os.time())

	Time = 0
	Width = 600
    Height = 600

    Pixels = love.image.newImageData(Width, Height)
    for x = 0, Width - 1 do
        for y = 0, Height - 1 do
            Pixels:setPixel(x, y, 0, 0, 0, 1)
        end
    end
    Image = love.graphics.newImage(Pixels)

    Iterators = { 
        iter_radius,
        iter_scan_down,
        iter_rect,
        iter_scan_up,
        iter_random
    }

    Routines = Queue.new()
end

function love.draw ()
    love.graphics.draw(Image)
end

function love.update (dt)
	Time = Time + dt
    if Routines:length() == 0 then
        Routines:push(routine(Iterators[math.random(1, #Iterators)], noise))
        Routines:push(routine(Iterators[math.random(1, #Iterators)], smooth))
    end
    if not rtn or coroutine.status(rtn) == "dead" then
        rtn = Routines:pop()
        F = math.prandom(0.10, 0.99)
    end
    --if not rtn then return end
    local good, err = coroutine.resume(rtn)
    if not good then print(err) end
    Image = love.graphics.newImage(Pixels)
end
