local perlin = require("perlin")
local Text = require("Text")

function love.keypressed (key, unicode)
    if key == "escape" or key == "q" then
        love.event.quit()
    elseif key == "r" then
        perlin:seed(shuffle)
        World = generateWorld(World:getWidth(), World:getHeight())
    end
end

function shuffle (t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
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

function HSV (h, s, v)
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

function smoothstep (x, y, a)
    local t = clamp(0.0, 1.0, (a - x) / (y - x))
    return t * t * (3.0 - 2.0 * t);
end

function norm (x, mu, sig1, sig2)
    -- this is a modification made by me. altering sig2 widens the curve such
    -- that this will produce higher values over the curve normally. Since we
    -- aren't using it for statistics but for smoothing, this makes sense
    local sig2 = sig2 or sig1
    return math.exp(-0.5 * ((x-mu) * (x-mu) / (sig2 * sig2))) / (sig1 * 2.50662827463)
end

function noise (x, y, width, height)
    -- put coordinates into [0.5, 0.5] range

    local xs = (x / (width-1)) - 0.5
    local ys = (y / (height-1)) - 0.5

    local n = perlin:noise(xs * 4, ys * 4)
            + perlin:noise(xs * 20, ys * 20) * 0.50
            + perlin:noise(xs * 50, ys * 50) * 0.25

    -- simply clamp n to convert into range [0, 1]
    if (n < 0) then n = 0 end
    -- use normal distribution to input lower maximum edge so that smoothstep
    -- produces higher values on the poles, producing snowy mountains there
    n = smoothstep(0, norm(ys + 0.5, 0.5, 0.30), n)
    -- bring out lower and middle values, keep higher values mostly same
    n = math.pow(n, 0.35)

	return n
end

function biome (n)
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
        h, s, v = rgb2hsv(228, 232, 227)
    end

    return HSV(h, s, clamp(v, 1, (v * n) + 0.25))
end

function generateWorld (width, height)
    local Pixels = love.image.newImageData(width, height)
    for x = 0, width - 1 do
        for y = 0, height - 1 do
            local r, g, b = biome(noise(x, y, width, height))
            Pixels:setPixel(x, y, r, g, b, 1)
        end
    end
    return love.graphics.newImage(Pixels)
end

-- Gives a precise random decimal number given a minimum and maximum
function math.prandom (min, max)
    return love.math.random() * (max - min) + min
end

function flicker ()
    for x = 0, NumX do
        for y = 0, NumY do
            if CurrGen[x][y] > 0 then
                CurrGen[x][y] = CurrGen[x][y] + math.prandom(-0.025, 0.025)
            end
        end
    end
end

function genStars ()
    for x = 0, NumX do
        for y = 0, NumY do
            CurrGen[x][y] = 0
            if math.random(1, 1000) < 101 then
                CurrGen[x][y] = math.prandom(0, 1)
            end
        end
    end
end

function clamp (min, max, val)
    if val < min then return min end
    if val > max then return max end
    return val
end

function point (x, y, angle, d)
    return math.floor(x + (math.cos(angle) * d)),
           math.floor(y + (math.sin(angle) * d))
end

function dest (x, y)
    local dx, dy = x - center.x, y - center.y
    local angle = math.atan2(dy, dx)
    return point(x, y, angle, Dist)
end

function next_generation ()
    local Next = {}

    for x = 0, NumX do
        Next[x] = {}
        for y = 0, NumY do
            Next[x][y] = CurrGen[x][y]
        end
    end

    for x = 0, NumX do
        for y = 0, NumY do
            local taken = Next[x][y] * math.prandom(0, 1.5)

            if Dist > -4 and math.random(1, 10000) < 101 then
                Next[x][y] = 0.8
            else
                Next[x][y] = Next[x][y] - taken
            end

            if Dist < -4.5 then
                Next[x][y] = 0
                goto continue
            end

            local nx, ny = dest(x, y)
            if Next[nx] and Next[nx][ny] then
                Next[nx][ny] = Next[nx][ny] + (0.95 * taken)
            end

            ::continue::
        end
    end

    CurrGen = Next
end

function love.load ()
    math.randomseed(os.time())

    love.window.setPosition(0, 0)

	Width = love.graphics.getWidth()
    Height = love.graphics.getHeight()

    textWarping = Text.new("Activating\nWarp Drive", 0, 250, 128, "center", "Arcadepix Plus.ttf")
    textWarping.display = false

    Background = love.graphics.newImage("forest2.jpg")

    local RaindropSrc = [[
	extern number time;
    extern number zoomf;

    #define PI 3.1415926535897932384626433832795

    // radial zoom for texture coordinates
    vec2 zoom (vec2 t, float factor)
    {
        const vec2 ctr = vec2(0.5, 0.5);
        float angle = atan(t.y - ctr.y, t.x - ctr.x);
        float dist = distance(t, ctr);
        dist *= factor;
        return vec2(
            ctr.x + (cos(angle) * dist),
            ctr.y + (sin(angle) * dist)
        );
    }

	float circle (vec2 pos, float radius, float r)
	{
        // how far the circle will expand
        float range = r;
        // dot product with same vector is square of that vector's magnitude
        float square = dot(pos, pos);
		return smoothstep(0, 2 * radius, square * range);
	}

    vec4 effect (vec4 color, Image tex, vec2 tc, vec2 px)
    {
        // get position based on center of screen in range [0,1]
        vec2 pos = (px.xy / love_ScreenSize.xy) - vec2(0.5);
        // correct for aspect ratio
        pos *= vec2(love_ScreenSize.x / love_ScreenSize.y, 1);

        // wave length is determined over time and restarts over an interval
        float wave = mod(time, 1.0);

        // generate two circles and step between their edges to preserve the
        // inner middle texture over time, altering only the wave
        float inner = circle(pos, wave, 1);
        float outer = circle(pos, wave, 0.75);
        float circle = smoothstep(inner, outer, wave);

        vec4 a1 = Texel(tex, tc);
        vec4 a2 = Texel(tex, zoom(tc, 0.75));
        //vec4 a1 = vec4(1);
        //vec4 a2 = vec4(0, 0, 0, 1);
        return mix(a1, a2, circle);
    }
    ]]
    
    local ZoomSrc = [[
	extern number time;

    #define PI 3.1415926535897932384626433832795

    // radial zoom for texture coordinates
    vec2 zoom (vec2 t, float factor)
    {
        const vec2 ctr = vec2(0.5, 0.5);
        float angle = atan(t.y - ctr.y, t.x - ctr.x);
        float dist = distance(t, ctr);
        dist *= factor;
        return vec2(
            ctr.x + (cos(angle) * dist),
            ctr.y + (sin(angle) * dist)
        );
    }

    vec4 effect (vec4 color, Image tex, vec2 tc, vec2 px)
    {
        return Texel(tex, zoom(tc, clamp(time, 0, 1)));
    }
    ]]

    local SphereSrc = [[
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

    Raindrop = love.graphics.newShader(RaindropSrc)
    Zoom = love.graphics.newShader(ZoomSrc)
    Sphere = love.graphics.newShader(SphereSrc)

    Dist = 5

    TileSize = 5
    Time = 0
    Step = 1 / 60
    Next = Step

    ToggleTime = 0

    NumX = (Width / TileSize)
    NumY = (Height / TileSize)
    NumNodes = NumX + NumY

    center = { x = (NumX / 2), y = (NumY / 2) }

    Inverted = true

    CurrGen = {}
    for x = 0, NumX do
        CurrGen[x] = {}
        for y = 0, NumY do
            CurrGen[x][y] = 0
        end
    end
    genStars()

    State = 1

    Canvas = love.graphics.newCanvas()

    Alpha = 1
    CloseAlpha = 0
    DrawClosing = false

    ActiveShader = nil

    DrawSphere = false
    World = generateWorld(256, 256)
    WorldScale = 0.50

    Sphere:send("lightDir", {1, 0, 1})

    Shaking = false
    ShakePower = 0.75
end

function love.draw ()
    Canvas:renderTo(function()
        love.graphics.clear()
        for x = 0, NumX do
            for y = 0, NumY do
                CurrGen[x][y] = clamp(0, 1, CurrGen[x][y])
                --love.graphics.setColor(HSV(209/360, 1 - CurrGen[x][y], 1))
                local r, g, b
                if Inverted then
                    r, g, b = HSV(0, 0, CurrGen[x][y])
                else
                    r, g, b = HSV(0, 0, 1 - CurrGen[x][y])
                end
                love.graphics.setColor(r, g, b, Alpha)
                love.graphics.rectangle("fill",
                        x * TileSize, y * TileSize, TileSize, TileSize)
            end
        end
    end)

    if Shaking then
        local dx = love.math.random(-ShakePower, ShakePower)
        local dy = love.math.random(-ShakePower, ShakePower)
        love.graphics.translate(dx, dy)
    else
        love.graphics.translate(0, 0)
    end

    love.graphics.setShader(ActiveShader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(Canvas)
    love.graphics.setShader()

    if DrawSphere then
        love.graphics.setShader(Sphere)
        local graphics WorldX = (Width / 2) - ((World:getWidth() * WorldScale) / 2)
        local graphics WorldY = (Height / 2) - ((World:getHeight()  * WorldScale) / 2)
        love.graphics.draw(World, WorldX, WorldY, 0, WorldScale)
        love.graphics.setShader()
    end

    if DrawClosing then
        love.graphics.setColor(0, 0, 0, CloseAlpha)
        love.graphics.rectangle("fill", 0, 0, Width, Height)
    end

    textWarping:draw()
end

function love.update (dt)
	Time = Time + dt

    Alpha = clamp(0, 1, Time)

    if Time >= 4.0 and not ShakeDuring and State == 1 then
        Shaking = true
    end

    if Time >= 2.0 and State == 1 then
        if Time > ToggleTime then
            ToggleTime = Time + 0.25
            textWarping.display = not textWarping.display
        end
    end

    if Time >= 4.5 and State == 1 then
        textWarping.display = false
        ActiveShader = Raindrop
        Raindrop:send("time", clamp(0, 1, 1 - (5.5 - Time)))
    end
    if Time < 5 and State == 1 then
        flicker()
    elseif Time >= 5 and State == 1 then
        Raindrop:send("time", 0)
        ActiveShader = nil
        Inverted = false
        State = 2
    elseif State == 2 then
        Dist = Dist - 0.01
        if Dist < 1 and Dist > 0 then
            Dist = -2
        end
        if Time > Next then
          Next = Time + Step
          next_generation()
        end
        if Dist <= -3.5 then
            ShakePower = clamp(0, 4.5, ShakePower + (2 * dt))
        end
        if Dist <= -4.0 then
            if not Stamp then
                Stamp = Time
            end
            ActiveShader = Raindrop
            Raindrop:send("time", clamp(0, 1, Time - Stamp))
            if Time - Stamp >= 1 then
                Shaking = false
                Stamp = nil
                State = 3
                Inverted = true
                genStars()
                Alpha = 0
                DrawSphere = true
            end
        end
    elseif State == 3 then
        if not Stamp then
            Stamp = Time
        end
        ActiveShader = Zoom
        Sphere:send("time", -(0.10 * Time));
        --WorldScale = clamp(0, 0.75, 0.75 * (Time - Stamp))
        WorldScale = clamp(0, 1, (Time - Stamp))
        Zoom:send("time", Time - Stamp)
        Alpha = clamp(0, 1, Time - Stamp)
        flicker()

        if Time - Stamp >= 5 then
            State = 4
            Stamp = nil
            DrawClosing = true
            ActiveShader = nil
        end
    elseif State == 4 then
        CloseAlpha = clamp(0, 1, CloseAlpha + dt)
        Sphere:send("time", -(0.10 * Time));
        flicker()
    end
end
