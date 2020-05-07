-- Gives a precise random decimal number given a minimum and maximum
function math.prandom (min, max)
    return math.random() * (max - min) + min
end

function love.keypressed (key, unicode)
    if key == "escape" or key == "q" then
        love.event.quit()
    end
end

function CheckRange (x, y)
    if x < 0 or x > Width - 1 or y < 0 or y > Height - 1 then
        error("Cannot index out of range pixel (" .. x .. ", " .. y .. ")")
    end
    return x, y
end

function GetPixel (x, y)
    CheckRange(x, y)
    return unpack(Nodes[x][y])
end

function SetPixel (x, y, r, g, b, a)
    CheckRange(x, y)
    local t = Nodes[x][y]
    t.r = r
    t.g = g
    t.b = b
    t.a = a or 1
end

function love.load ()
    math.randomseed(os.time())

	Time = 0

    Shader = love.graphics.newShader[[
    vec2 getpos (vec2 px)
    {
        // get position based on center of screen in range [0,1]
        vec2 pos = (px.xy / love_ScreenSize.xy) - vec2(0.5);
        // correct for aspect ratio
        pos *= vec2(love_ScreenSize.x / love_ScreenSize.y, 1);
        return pos;
    }

	float circle (vec2 pos, float radius)
	{
        // sets the width between the the two steps, the lower the more `hard'
        // the edge of the circle will appear
        const float smoothness = 0.75;
        // how far the circle will expand
        const float range = 1.0;
        // dot product with same vector is square of that vector's magnitude
        float square = dot(pos, pos);
		return 1.0 - smoothstep(radius - (radius * smoothness),
							    radius + (radius * smoothness),
							    square * range);
	}

    extern float time;
    #define PI 3.1415926535897932384626433832795

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

    vec2 rotate (vec2 t, float factor)
    {
        const vec2 ctr = vec2(0.5, 0.5);
        float angle = atan(t.y - ctr.y, t.x - ctr.x);
        float dist = distance(t, ctr);
        return vec2(
            ctr.x + (cos(angle + factor) * dist),
            ctr.y + (sin(angle + factor) * dist)
        );
    }

    vec4 effect (vec4 color, Image tex, vec2 tc, vec2 px)
    {
        tc = zoom(tc, 0.75);

        vec2 pos = getpos(px);
        float len = circle(pos, 0.75);

        float zoomf = -pow((1.5 * ((sin(time) + 1) / 2)) - 0.75, 2) + 1;
        float rotf = (sin(0.5 * time) / 6) * PI;

        vec2 t1 = tc;
        vec2 t2 = rotate(tc, rotf);
        t2 = zoom(t2, zoomf);
        vec2 tf = mix(t1, t2, len);
        return Texel(tex, tf);
    }
    ]]

    Scale = 10
    Width = love.graphics.getWidth()
    Height = love.graphics.getHeight()

    Color = { 
        r = math.prandom(0, 1),  
        g = math.prandom(0, 1),
        b = math.prandom(0, 1),
        a = 1 
    }

    Nodes = {}
    for x = -Width, Width * 2, Scale * 2 do
        for y = -Height, Height * 2, Scale * 2 do
            table.insert(Nodes, { x = x, y = y })
        end
    end

    --Pixels = love.image.newImageData("image.jpg")
    --Image = love.graphics.newImage(Pixels)
    
    Canvas = love.graphics.newCanvas()

    Canvas:renderTo(function()
        love.graphics.setColor(1, 1, 1, 1)
        for i, n in ipairs(Nodes) do
            love.graphics.rectangle("fill", n.x, n.y, Scale, Scale)
        end
    end)
end

function love.draw ()
    love.graphics.setShader(Shader)
    --love.graphics.draw(Image, -480, -312, 0, 0.75, 0.75)
    --love.graphics.draw(Image, -640, -416)
    love.graphics.draw(Canvas)
end

function love.update (dt)
	Time = Time + dt
    Shader:send("time", Time)

    --if rtn and coroutine.status(rtn) ~= "dead" then
    --    local good, err = coroutine.resume(rtn)
    --    if not good then
    --        error("Coroutine: " .. err)
    --    end
    --    Image = love.graphics.newImage(Pixels)
    --end
end
