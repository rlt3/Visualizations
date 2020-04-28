function love.keypressed (key, unicode)
    if key == "escape" or key == "q" then
        love.event.quit()
    end
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

-- Gives a precise random decimal number given a minimum and maximum
function math.prandom(min, max)
    return love.math.random() * (max - min) + min
end

function love.load ()
    math.randomseed(os.time())

    TileSize = 5
	Width = 600
    Height = 600

    Time = 0
    Step = 1 / 30
    Next = Step

    NumX = (Width / TileSize)
    NumY = (Height / TileSize)
    NumNodes = NumX + NumY

    CurrGen = {}
    for x = 0, NumX do
        CurrGen[x] = {}
        for y = 0, NumY do
            CurrGen[x][y] = 0
        end
    end

    Sphere = love.graphics.newShader[[
    #define PI 3.141592653589793238462643383

    extern number time;
    extern vec3 lightDir;

    vec4 effect (vec4 color, Image tex, vec2 tc, vec2 px)
    {
        vec2 uv = (tc.xy - 0.5) * 2.0;
        float radius = length(uv);

        // a `3D' vector that goes from center of sphere to each pixel.
        // we just 'solve for z' in formula of circle: x^2 + y^2 + z^2 = 1
        vec3 normal = vec3(uv.x, uv.y, sqrt(1 - uv.x * uv.x - uv.y * uv.y));
        
        // light direction and its dot product with the normal to produce
        // a lighting coefficient for 'shading'
        vec3 light = normalize(lightDir);
        float diffuse = max(0, dot(normal, light));

        // map UV normal onto sphere 
        vec2 texCoords = vec2(0.5 + (atan(normal.z, normal.x) / (2 * PI)),
                              0.5 - (asin(normal.y) / PI));
        texCoords.x = mod(texCoords.x + time * 0.10, 1);
        vec3 texColor = Texel(tex, texCoords).xyz;  

        if (radius <= 1.0)
            return vec4(vec3(diffuse) * texColor, 1);
        else
            return Texel(tex, tc);
            //return vec4(0);
    }
    ]]

    Sphere:send("lightDir", {-1, -1, 1});
    Sphere:send("time", 0);
end
	
function love.draw()
    if not Image then return end

    --love.graphics.setShader(Sphere)
    love.graphics.draw(Image)
    --love.graphics.setShader()

    --for x = 0, NumX do
    --    for y = 0, NumY do
    --        CurrGen[x][y] = clamp(0, 1, CurrGen[x][y])
    --        love.graphics.setColor(HSV(209/360, 1 - CurrGen[x][y], 0.93))
    --        love.graphics.rectangle("fill",
    --                x * TileSize, y * TileSize, TileSize, TileSize)
    --    end
    --end
end

function love.update (dt)
    Time = Time + dt
    --Sphere:send("time", Time);

    if Time > Next then
        Next = Time + Step
        next_generation()
    end
end

function clamp (min, max, val)
    if val < min then return min end
    if val > max then return max end
    return val
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

            if math.random(1, 10000) < 11 then
                Next[x][y] = 0.8
            else
                Next[x][y] = Next[x][y] - taken
            end

            local split = math.prandom(0.0, 1.0)
            if x > 0 then
                Next[x - 1][y] = Next[x - 1][y] + (0.95 * taken * split)
            end
            if y > 0 then
                Next[x][y - 1] = Next[x][y - 1] + (0.95 * taken * (1 - split))
            end

            ::continue::
        end
    end

    local data = love.image.newImageData(Width, Height)
    for x = 0, NumX - 1 do
        for y = 0, NumY - 1 do
            CurrGen[x][y] = clamp(0, 1, CurrGen[x][y])
            local r, g, b = HSV(209/360, 1 - CurrGen[x][y], 0.93)
            for i = 0, 4 do
                local xr = (x * 5) + i
                for j = 0, 4 do
                    local yr = (y * 5) + j
                    data:setPixel(xr, yr, r, g, b, 1)
                end
            end
        end
    end
    Image = love.graphics.newImage(data)

    CurrGen = Next
end
