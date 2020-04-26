local Vector = require("Vector")

function Image (file, x, y, sw, sh)
    local halfWidth = love.graphics.getWidth() / 2
    local halfHeight = love.graphics.getHeight() / 2
    local image = love.graphics.newImage("moon.jpg")
    local size = Vector.new(image:getWidth() * sw, image:getHeight() * sh)
    return {
        image = image,
        scale = { w = sw, h = sh },
        size = size,
        pos = Vector.new(halfWidth - (size.x / 2), halfHeight - (size.y / 2)),
        draw = function (t)
            love.graphics.draw(t.image, t.pos.x, t.pos.y, 0, t.scale.w, t.scale.h)
        end
    }
end

function love.load ()
    Shader = love.graphics.newShader[[
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
        texCoords.x = mod(texCoords.x + time * 0.05, 1);
        vec3 texColor = Texel(tex, texCoords).xyz;  

        if (radius <= 1.0)
            return vec4(vec3(ndotl) * texColor, 1);
        else
            return vec4(0);
    }
    ]]

    Time = 0
    Moon = Image("moon.jpg", 150, 150, 0.25, 0.50)
    love.graphics.setShader(Shader)
end

function love.draw ()
    love.graphics.setShader(Shader)
    Moon:draw()
    love.graphics.setShader()
end

function love.keypressed (key, unicode)
    if key == "escape" or key == "q" then
        love.event.quit()
    end
end

function love.update (dt)
    Time = Time + dt

    -- Mouse to UV coordinates: (-1,-1) at top-left, (1,1) bottom right
    local m = Vector.new(love.mouse.getPosition())
    m.x = (m.x - 300) / 300
    m.y = (m.y - 300) / 300
    local l = { m.x, m.y, 1 - m.x * m.x - m.y * m.y }
    Shader:send("lightDir", l);
    Shader:send("time", Time);
end
