function love.keypressed (key, unicode)
    if key == "escape" or key == "q" then
        love.event.quit()
    end
end

-- Gives a precise random decimal number given a minimum and maximum
function math.prandom (min, max)
    return love.math.random() * (max - min) + min
end

function love.load ()
    love.window.setPosition(0, 0)

	Width = love.graphics.getWidth()
    Height = love.graphics.getHeight()

    -- generate background so shader will shade when drawing
    local data = love.image.newImageData(Width, Height)
    for x = 0, Width - 1 do
        for y = 0, Height - 1 do
            data:setPixel(x, y, 1, 1, 1, 1)
        end
    end
    Background = love.graphics.newImage(data)

    Shader = love.graphics.newShader[[
    uniform Image forest2;
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

	float circle (vec2 pos, float radius, float r)
	{
        // sets the width between the the two steps, the lower the more `hard'
        // the edge of the circle will appear
        const float smoothness = 1.0;
        // how far the circle will expand
        float range = r;
        // dot product with same vector is square of that vector's magnitude
        float square = dot(pos, pos);
		return 1.0 - smoothstep(radius - (radius * smoothness),
							    radius + (radius * smoothness),
							    square * range);
	}

    vec4 effect (vec4 color, Image tex, vec2 tc, vec2 px)
    {
        // get position based on center of screen in range [0,1]
        vec2 pos = (px.xy / love_ScreenSize.xy) - vec2(0.5);
        // correct for aspect ratio
        pos *= vec2(love_ScreenSize.x / love_ScreenSize.y, 1);

        float gate = smoothstep(0, 5, time);

        // start from a time in the future and step 'backwards' to 0
        float maxt = 25.0;
        float t = maxt - (maxt * smoothstep(0, maxt, 2.5 * time));
        t *= gate;

        // the number of waves is determined by cosine over time
        float waves = cos(length(pos * t * 4)) + 1.0;
        float len = circle(pos, waves, 1);

        vec2 t1 = tc;
        vec2 t2 = zoom(tc, 0.95);

        vec4 a1 = Texel(forest2, t1);
        vec4 a2 = Texel(forest2, t2);

        return mix(a1, a2, len);
    }
    ]]
    love.graphics.setShader(Shader)
    Shader:send("forest2", love.graphics.newImage("forest2.jpg"))
	Time = 0
end

function love.draw ()
    love.graphics.draw(Background)
end

function love.update (dt)
	Time = Time + dt
    Shader:send("time", Time)
end
