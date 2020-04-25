local Vector = require("Vector")

function love.load ()

    Time = 0

    Shader = love.graphics.newShader[[
    #define M_PI 3.141592653589793238462643383

    extern number time;
    //uniform Image earth;

    //vec3 lightDir = vec3(-0.4, -0.3, 0.5);
    extern vec3 lightDir;

    vec4 effect (vec4 color, Image tex, vec2 tc, vec2 px)
    {
        // map texture coordinates from (0,0)->(1,1) to -1, 1
        vec2 uv = (tc.xy - 0.5) * 2.0;

        float radius = length(uv);
        // a `3D' vector that goes from center of sphere to each pixel
        vec3 normal = vec3(uv.x, uv.y, sqrt(1 - uv.x * uv.x - uv.y * uv.y));
        
        // light direction and its dot product with the normal to produce
        // a lighting coefficient for 'shading'
        vec3 l = normalize(lightDir);
        float ndotl = max(0, dot(normal, l));

        // spherical projection of texture coords onto sphere
        float r = sqrt(uv.x * uv.x + uv.y * uv.y);
        float d = 0;
        if (r > 0)
            d = asin(r) / r;
        vec2 texCoords = vec2((d * uv.x) / (3.0 * M_PI) + 0.5,
                              (d * uv.y) / (1.5 * M_PI) + 0.5);

        texCoords.x = mod(texCoords.x + (0.05 * time), 1);
        vec3 texColor = texture2D(tex, texCoords).rgb;

        if (r <= 1.0)
            return vec4(vec3(ndotl) * texColor, 1);
        else
            return vec4(0);
    }
    ]]

    Moon = love.graphics.newImage("moon.jpg")
    MoonSize = Vector.new(1024 * 0.25, 512 * 0.50)
    MoonPos = Vector.new(150, 150)

    love.graphics.setShader(Shader)
end

function love.draw ()
    love.graphics.setShader(Shader)
    love.graphics.draw(Moon, 150, 150, 0, 0.25, 0.50)
    love.graphics.setShader()
end

function love.keypressed (key, unicode)
    if key == "escape" or key == "q" then
        love.event.quit()
    end
end

function love.update (dt)
    Time = Time + dt

    local mousepos = Vector.new(love.mouse.getPosition())
    local dist = mousepos - MoonPos
    dist.x = math.min(1, dist.x / MoonSize.x)
    dist.y = math.min(1, dist.y / MoonSize.y)
    local lightDir = { dist.x, dist.y, 1 - dist.x * dist.x - dist.y * dist.y }
    Shader:send("lightDir", lightDir);
    Shader:send("time", Time);
end
