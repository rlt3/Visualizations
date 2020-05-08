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
    vec2 getpos (vec2 px, vec2 epicenter)
    {
        // get position based on center of screen in range [0,1]
        vec2 pos = (px.xy / love_ScreenSize.xy) - epicenter;
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

	vec3 hsv2rgb(vec3 c)
	{
		vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
		vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
		return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
	}

    vec4 effect (vec4 color, Image tex, vec2 tc, vec2 px)
    {
        //float texzoom = (cos(0.75 * time) + 6) / 12;
        float texzoom = (cos(0.75 * time) + 10) / 20;
        tc = zoom(tc, texzoom);

        //vec2 epicenter = vec2((cos(0.50 * time) + 3) / 6, 0.5);
        //vec2 epicenter = vec2((cos(time) + 3) / 6, 0.5);
        vec2 epicenter = vec2((cos(0.5 * time) + 3) / 6, 
                              (sin(0.5 * time) + 3) / 6);
        float size = 0.5 + ((cos(0.25 * time) + 1) / 6);
        float len = circle(getpos(px, epicenter), size);

        float zoomf = (sin(0.5 * time) + 5.5) / 6;
        float rotf = (cos(0.5 * time) / 9) * (PI / 2);

        float pct = (zoomf - 0.917) / 0.166;

        vec2 t1 = tc;
        vec2 t2 = zoom(tc, zoomf);
        t2 = rotate(t2, rotf);
        vec2 tf = mix(t1, t2, len);

        vec3 hsv = vec3(1.25 / 360.0, 0.89, 1);
        hsv.y = mix(0.89, 0.98, len * zoomf);
        vec3 rgb = hsv2rgb(hsv);
        return Texel(tex, tf) * vec4(rgb, 1);
    }
    ]]

    Scale = 10
    Width = love.graphics.getWidth()
    Height = love.graphics.getHeight()

    Pixels = love.image.newImageData(1, 1)
    Pixels:setPixel(0, 0, 1, 1, 1, 1)
    Image = love.graphics.newImage(Pixels)
    
    Nodes = {}
    for x = 0, Width, Scale * 2 do
        for y = Scale / 2, Height, Scale * 2 do
            table.insert(Nodes, { x = x, y = y })
        end
    end

    Batch = love.graphics.newSpriteBatch(Image, #Nodes)
    Quad = love.graphics.newQuad(0, 0, Scale, Scale, 1, 1)

    Batch:clear()
    for i, n in ipairs(Nodes) do
        Batch:add(Quad, n.x, n.y)
    end

    Canvas = love.graphics.newCanvas(Width, Height)
    Pos = 0
end

function love.draw ()
    Canvas:renderTo(function()
        love.graphics.clear()
        love.graphics.draw(Batch)
    end)

    love.graphics.setShader(Shader)
    love.graphics.draw(Canvas)
    love.graphics.setShader()
end

function love.update (dt)
	Time = Time + dt
    Shader:send("time", Time)

    local speed = 200 * ((math.sin(0.5 * Time)) / 2)

    Batch:clear()
    for i, n in ipairs(Nodes) do
        n.x = n.x + (speed * dt)
        if n.x > Width then
            n.x = n.x - Width
        elseif n.x < 0 then
            n.x = n.x + Width
        end
        Batch:add(Quad, n.x, n.y)
    end
    Batch:flush()
end
