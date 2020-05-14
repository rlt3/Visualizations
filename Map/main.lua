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

function norm (x, mu, sig1, sig2)
    -- this is a modification made by me. altering sig2 widens the curve such
    -- that this will produce higher values over the curve normally. Since we
    -- aren't using it for statistics but for smoothing, this makes sense
    local sig2 = sig2 or sig1
    return math.exp(-0.5 * ((x-mu) * (x-mu) / (sig2 * sig2))) / (sig1 * 2.50662827463)
end

function smoothstep (x, y, a)
    local t = math.clamp(0.0, 1.0, (a - x) / (y - x))
    return t * t * (3.0 - 2.0 * t);
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
	return { h, s, v }
end

local Color = {
    ["trench"]   = rgb2hsv(24, 74, 115),
    ["ocean"]    = rgb2hsv(44, 107, 158),
    ["shore"]    = rgb2hsv(64, 147, 214),
    ["ice"]      = rgb2hsv(224, 224, 224),
    ["tundra"]   = rgb2hsv(255, 250, 242),
    ["grass"]    = rgb2hsv(13, 92, 13),
    ["sand"]     = rgb2hsv(189, 175, 83),
    ["forest"]   = rgb2hsv(2, 56, 2),
    ["hill"]     = rgb2hsv(171, 166, 157),
    ["glacier"]  = rgb2hsv(192, 237, 236),
    ["clay"]     = rgb2hsv(145, 109, 77),
    ["stone"]    = rgb2hsv(107, 110, 106)
}

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
    iter_scan(update, Height - 1, 0, -1, dt)
end

-- Updates pixels vertically going down
function iter_scan_down (update)
    iter_scan(update, 0, Height - 1, 1, dt)
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

function should_yield (count, dt)
    count = count + 1
    local todo = NumNodes * (1/5) * dt
    if count >= todo then
        count = 0
        dt = coroutine.yield()
    end
    return count, dt
end

function pixels2table ()
    local t = {}
    for x = 0, Width - 1 do
        for y = 0, Height - 1 do
            local r, g, b = GetPixel(x, y)
            table.insert(t, { x = x, y = y, r = r, g = g, b = b })
        end
    end
    return t
end

-- Shuffles all pixels random then updates them in shuffled order
function iter_random (update)
    local pixels = pixels2table()
    shuffle(pixels)

    local count = 0
    local dt = 0
    for i = 1, #pixels do
        update(pixels[i].x, pixels[i].y)
        count, dt = should_yield(count, dt)
    end
end

-- Sorts pixels lowest-depth first and updates them in sorted order
function iter_depth (update)
    local pixels = pixels2table()
    table.sort(pixels, function (a, b)
        return a.r < b.r
    end)

    local count = 0
    local dt = 0
    for i = 1, #pixels do
        update(pixels[i].x, pixels[i].y)
        count, dt = should_yield(count, dt)
    end
end

-- return temperature over y-axis from [0,1] range
function getTemp (y)
    return (math.sin(6 * y - 1.5) / 2) + 0.5
end

function sphereCoords (x, y)
    local ux, uy = x / (Width-1), y / (Height-1)
	local nx = math.cos(ux * 2 * math.pi) * math.cos(uy * math.pi - math.pi / 2)
	local ny = math.sin(uy * math.pi - math.pi/2)
	local nz = math.sin(ux * 2 * math.pi) * math.cos(uy * math.pi - math.pi / 2)
    return nx, ny, nz
end

function noise (x, y)
    local ux, uy, uz = sphereCoords(x, y)

    local elevation =
              perlin:noise(ux * 4,  uy * 4,  uz * 4 ) * 1.00
            + perlin:noise(ux * 8,  uy * 8,  uz * 8) * 0.75
            + perlin:noise(ux * 16, uy * 16, uz * 16) * 0.50

    elevation = math.clamp(-1, 1, elevation)
    elevation = (elevation * 0.5) + 0.5

    -- generate temperature which is based on latitude
    temperature = getTemp(y / (Height - 1))

    --SetPixel(x, y, elevation, temperature, 0, 1)
    SetPixel(x, y, elevation, elevation, elevation, 1)
end

function biome (x, y)
    local elevation, temp = GetPixel(x, y)
    local bx = temp * BiomeWidth
    local by = elevation * BiomeHeight
    local r, g, b = BiomeLookup:getPixel(bx, by)
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
    -- Lookup in table rather than query image data for values
    local t = Nodes[x][y]
    return t.r, t.g, t.b, t.a
end

function SetPixel (x, y, r, g, b, a)
    CheckRange(x, y)
    a = a or 1
    -- Keep a copy for the entire pixel block for quick lookups
    local t = Nodes[x][y]
    t.r = r
    t.g = g
    t.b = b
    t.a = a
    for i = x * Scale, x * Scale + Scale - 1 do
        for j = y * Scale, y * Scale + Scale - 1 do
            Pixels:setPixel(i, j, r, g, b, a)
        end
    end
end

function generate_another ()
    rtn = nil
    perlin:seed(shuffle)
    while Routines:length() > 0 do
        Routines:pop()
    end
    Routines:push(routine(iter_random, noise))
    --Routines:push(routine(iter_depth, biome))
end

function love.keypressed (key, unicode)
    if key == "escape" or key == "q" then
        love.event.quit()
    elseif key == "r" then
        generate_another()
    elseif key == "s" then
        if CurrShader then
            CurrShader = nil
        else
            CurrShader = Sphere
        end
    end
end

function love.load ()
    math.randomseed(os.time())

    Sphere = love.graphics.newShader[[
    #define PI 3.141592653589793238462643383

    extern number time;
    extern vec3 lightDir;

    vec4 effect (vec4 color, Image tex, vec2 tc, vec2 px)
    {
        // map texture coordinates onto UV. from (0,0)->(1,1) to -1, 1
        vec2 uv = (tc.xy - 0.5) * 2.0;
        float radius = length(uv);

        // a `3D' vector that goes from center of sphere to each pixel.
        // we just 'solve for z' in formula of circle: x^2 + y^2 + z^2 = 1
        vec3 normal = vec3(uv.x, uv.y, sqrt(1 - uv.x * uv.x - uv.y * uv.y));
        
        // light direction and its dot product with the normal to produce
        // a lighting coefficient for 'shading'
        vec3 l = normalize(lightDir);
        float ndotl = max(0, dot(normal, l));

        // map UV normal onto sphere 
        vec2 texCoords = vec2(0.5 + (atan(normal.z, normal.x) / (2 * PI)),
                              0.5 - (asin(normal.y) / PI));
        texCoords.x = mod(texCoords.x + time * 0.10, 1);
        vec3 texColor = Texel(tex, texCoords).xyz;  

        if (radius <= 1.0)
            return vec4(vec3(ndotl) * texColor, 1);
        else
            return vec4(0);
    }
    ]]
    Sphere:send("lightDir", {0, 0, 1});

    CurrShader = nil

	Time = 0

    Scale = 5
    Width = love.graphics.getHeight() / Scale
    Height = Width
    --Width = love.graphics.getWidth() / Scale
    --Height = love.graphics.getHeight() / Scale
    NumNodes = Width * Height
    Nodes = {}

    for x = 0, Width - 1 do
        Nodes[x] = {}
        for y = 0, Height - 1 do
            Nodes[x][y] = { r = 0, g = 0, b = 0, a = 0 }
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

    --BiomeLookup = love.image.newImageData("biome.png")
    BiomeLookup = love.image.newImageData("biome-block.png")
    BiomeWidth = 255
    BiomeHeight = 255

    Routines = Queue.new()
    generate_another()

    --Pixels = love.image.newImageData(love.graphics.getWidth(), love.graphics.getHeight())
    Pixels = love.image.newImageData(love.graphics.getHeight(), love.graphics.getHeight())
    Terrain = love.graphics.newImage(Pixels)
    X = (love.graphics.getWidth() / 2) - (Terrain:getWidth()   / 2)
    Y = (love.graphics.getHeight() / 2) - (Terrain:getHeight() / 2)
end

function love.draw ()
    love.graphics.setShader(CurrShader)
    love.graphics.draw(Terrain, X, Y)
end

function love.update (dt)
	Time = Time + dt

    Sphere:send("time", Time);

    if Routines:length() > 0 then
        if not rtn or coroutine.status(rtn) == "dead" then
            rtn = Routines:pop()
        end
    end

    if rtn then
        if coroutine.status(rtn) == "dead" then
            rtn = nil
        else
            local good, err = coroutine.resume(rtn, dt)
            if not good then
                error("Coroutine: " .. err)
            end
            Terrain = love.graphics.newImage(Pixels)
        end
    end
end
