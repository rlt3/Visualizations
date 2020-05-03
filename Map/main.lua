local perlin = require("perlin")
local Queue = require("Queue")

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

-- Updates pixels vertically going up
function iter_scan_up (update)
    iter_scan(update, Height - 1, 0, -1)
end

-- Updates pixels vertically going down
function iter_scan_down (update)
    iter_scan(update, 0, Height - 1, 1)
end

-- Updates pixels in an exapnding circular order from the center
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

-- Updates pixels in an exapnding rectangular order from the center
function iter_rect (update)
    local ctr = { x = 300, y = 300 }

    for r = 0, 300 do
        -- get corners of rectangle subtracting by an extra 1 to keep within
        -- pixel range of [0, Width) and [0, Height)
        local xleft = ctr.x - r
        local xright = ctr.x - 1 + r
        local ytop = ctr.y - r
        local ybot = ctr.y - 1 + r
        -- update the perimeter of the rectangle without the corners
        for x = xleft + 1, xright - 1 do
            update(x, ytop)
        end
        for y = ytop + 1, ybot - 1 do
            update(xright, y)
        end
        for x = xleft + 1, xright - 1 do
            update(x, ybot)
        end
        for y = ytop + 1, ybot - 1 do
            update(xleft, y)
        end
        -- update each individual corner only once
        update(xleft, ytop)
        update(xright, ytop)
        update(xleft, ybot)
        update(xright, ybot)
        coroutine.yield()
    end
end

-- Shuffles all pixels random then updates them in shuffled order
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

-- Sorts pixels lowest-depth first and updates them in sorted order
function iter_depth (update)
    local pixels = {}
    for y = 0, Height - 1 do
        for x = 0, Width - 1 do
            table.insert(pixels, {x, y, v = GetPixel(x, y)})
        end
    end

    table.sort(pixels, function (a, b)
        return a.v < b.v
    end)

    for i = 1, #pixels do
        update(pixels[i][1], pixels[i][2])
        if i % (Width * 2) == 0 then
            coroutine.yield()
        end
    end
end

function noise (x, y)
    local freq = 1 / (Width / 3)
    local amp = 1.5
    local xs = x + (Scale * RandMovement)
    local ys = y + (Scale * RandMovement)
    local n =
        perlin:noise(xs * (freq + (freq)),     ys * (freq + (freq)))     * amp +
        perlin:noise(xs * (freq + (freq * 2)), ys * (freq + (freq * 2))) * amp * 0.5 +
        perlin:noise(xs * (freq + (freq * 4)), ys * (freq + (freq * 4))) * amp * 0.25
    n = (n * 0.5) + 0.5
    SetPixel(x, y, n, n, n, 1)
end

function biome (x, y)
    local n = GetPixel(x, y)
    local h, s, v

    -- trench
    if n < 0.40 then
        h, s, v = rgb2hsv(8, 38, 54)
    -- ocean
    elseif n < 0.54 then
        h, s, v = rgb2hsv(12, 70, 99)
    -- shore
    elseif n < 0.60 then
        h, s, v = rgb2hsv(23, 134, 191)
    -- sand
    elseif n < 0.63 then
        h, s, v = rgb2hsv(189, 175, 83)
    -- grass
    elseif n < 0.73 then
        h, s, v = rgb2hsv(13, 92, 13)
    -- forest
    elseif n < 0.84 then
        h, s, v = rgb2hsv(2, 56, 2)
    -- hill
    elseif n < 0.90 then
        h, s, v = rgb2hsv(148, 142, 96)
    -- mountain
    elseif n < 0.97 then
        h, s, v = rgb2hsv(91, 99, 90)
    -- snowy mountain
    else
        h, s, v = rgb2hsv(173, 181, 172)
    end

    local r, g, b = hsv2rgb(h, s, math.clamp(v, 1, (v * n) + 0.25))
    SetPixel(x, y, r, g, b)
end

function CheckRange (x, y)
    if x < 0 or x > Width - 1 or y < 0 or y > Height - 1 then
        error("Cannot index out of range pixel (" .. x .. ", " .. y .. ")")
    end
    return x, y
end

function GetPixel (x, y)
    CheckRange(x, y)
    local t = Nodes[x][y]
    return t.r, t.g, t.b, t.a
end

function SetPixel (x, y, r, g, b, a)
    CheckRange(x, y)
    local t = Nodes[x][y]
    t.r = r
    t.g = g
    t.b = b
    t.a = a or 1
end

function generate_another ()
    -- Random movement along the x,y axis for perlin noise
    RandMovement = math.prandom(0, Width)
    print(RandMovement)
    rtn = nil
    while Routines:length() > 0 do
        Routines:pop()
    end
    Routines:push(routine(iter_random, noise))
    Routines:push(routine(iter_depth, biome))
end

function love.keypressed (key, unicode)
    if key == "escape" or key == "q" then
        love.event.quit()
    elseif key == "r" then
        generate_another()
    end
end

function love.load ()
    math.randomseed(os.time())

	Time = 0

    Scale = 5
    Width = love.graphics.getWidth() / Scale
    Height = love.graphics.getHeight() / Scale
    Nodes = {}
    for x = 0, Width - 1 do
        Nodes[x] = {}
        for y = 0, Height - 1 do
            Nodes[x][y] = { r = 0, g = 0, b = 0, a = 1 }
        end
    end

    Iterators = { 
        iter_radius,
        iter_scan_down,
        iter_rect,
        iter_scan_up,
        iter_random,
        --iter_depth,
    }

    Routines = Queue.new()
    generate_another()
end

function love.draw ()
    local t = nil
    for x = 0, Width - 1 do
        for y = 0, Height - 1 do
            t = Nodes[x][y]
            love.graphics.setColor(t.r, t.g, t.b, t.a)
            love.graphics.rectangle("fill", x * Scale, y * Scale, Scale, Scale)
        end
    end
end

function love.update (dt)
	Time = Time + dt

    if Routines:length() > 0 then
        if not rtn or coroutine.status(rtn) == "dead" then
            rtn = Routines:pop()
        end
    end

    if rtn then
        if coroutine.status(rtn) == "dead" then
            rtn = nil
        else
            local good, err = coroutine.resume(rtn)
            if not good then
                error("Coroutine: " .. err)
            end
        end
    end
end
