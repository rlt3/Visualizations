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

	Width = 800
    Height = 600

    -- generate background so shader will shade when drawing
    local data = love.image.newImageData(Width, Height)
    for x = 0, Width - 1 do
        for y = 0, Height - 1 do
            data:setPixel(x, y, 1, 1, 1, 1)
        end
    end
    Background = love.graphics.newImage(data)

    Shader = love.graphics.newShader[[
	//	Classic Perlin 3D Noise 
	//	by Stefan Gustavson
	vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
	vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}
	vec3 fade(vec3 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}

	float noise(vec3 P){
	  vec3 Pi0 = floor(P); // Integer part for indexing
	  vec3 Pi1 = Pi0 + vec3(1.0); // Integer part + 1
	  Pi0 = mod(Pi0, 289.0);
	  Pi1 = mod(Pi1, 289.0);
	  vec3 Pf0 = fract(P); // Fractional part for interpolation
	  vec3 Pf1 = Pf0 - vec3(1.0); // Fractional part - 1.0
	  vec4 ix = vec4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
	  vec4 iy = vec4(Pi0.yy, Pi1.yy);
	  vec4 iz0 = Pi0.zzzz;
	  vec4 iz1 = Pi1.zzzz;

	  vec4 ixy = permute(permute(ix) + iy);
	  vec4 ixy0 = permute(ixy + iz0);
	  vec4 ixy1 = permute(ixy + iz1);

	  vec4 gx0 = ixy0 / 7.0;
	  vec4 gy0 = fract(floor(gx0) / 7.0) - 0.5;
	  gx0 = fract(gx0);
	  vec4 gz0 = vec4(0.5) - abs(gx0) - abs(gy0);
	  vec4 sz0 = step(gz0, vec4(0.0));
	  gx0 -= sz0 * (step(0.0, gx0) - 0.5);
	  gy0 -= sz0 * (step(0.0, gy0) - 0.5);

	  vec4 gx1 = ixy1 / 7.0;
	  vec4 gy1 = fract(floor(gx1) / 7.0) - 0.5;
	  gx1 = fract(gx1);
	  vec4 gz1 = vec4(0.5) - abs(gx1) - abs(gy1);
	  vec4 sz1 = step(gz1, vec4(0.0));
	  gx1 -= sz1 * (step(0.0, gx1) - 0.5);
	  gy1 -= sz1 * (step(0.0, gy1) - 0.5);

	  vec3 g000 = vec3(gx0.x,gy0.x,gz0.x);
	  vec3 g100 = vec3(gx0.y,gy0.y,gz0.y);
	  vec3 g010 = vec3(gx0.z,gy0.z,gz0.z);
	  vec3 g110 = vec3(gx0.w,gy0.w,gz0.w);
	  vec3 g001 = vec3(gx1.x,gy1.x,gz1.x);
	  vec3 g101 = vec3(gx1.y,gy1.y,gz1.y);
	  vec3 g011 = vec3(gx1.z,gy1.z,gz1.z);
	  vec3 g111 = vec3(gx1.w,gy1.w,gz1.w);

	  vec4 norm0 = taylorInvSqrt(vec4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
	  g000 *= norm0.x;
	  g010 *= norm0.y;
	  g100 *= norm0.z;
	  g110 *= norm0.w;
	  vec4 norm1 = taylorInvSqrt(vec4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
	  g001 *= norm1.x;
	  g011 *= norm1.y;
	  g101 *= norm1.z;
	  g111 *= norm1.w;

	  float n000 = dot(g000, Pf0);
	  float n100 = dot(g100, vec3(Pf1.x, Pf0.yz));
	  float n010 = dot(g010, vec3(Pf0.x, Pf1.y, Pf0.z));
	  float n110 = dot(g110, vec3(Pf1.xy, Pf0.z));
	  float n001 = dot(g001, vec3(Pf0.xy, Pf1.z));
	  float n101 = dot(g101, vec3(Pf1.x, Pf0.y, Pf1.z));
	  float n011 = dot(g011, vec3(Pf0.x, Pf1.yz));
	  float n111 = dot(g111, Pf1);

	  vec3 fade_xyz = fade(Pf0);
	  vec4 n_z = mix(vec4(n000, n100, n010, n110), vec4(n001, n101, n011, n111), fade_xyz.z);
	  vec2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
	  float n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x); 
	  return 2.2 * n_xyz;
	}

    uniform Image forest2;
	extern number time;

    #define PI 3.1415926535897932384626433832795
    const vec2 pctr = vec2(400, 300);
    const vec2 tctr = vec2(0.5, 0.5);

    float angle_from_center (vec2 p, vec2 ctr)
    {
        return atan(p.y - ctr.y, p.x - ctr.x);
    }

    // radial alignment for pixel coordinates
    vec2 pt (vec2 p)
    {
        float angle = angle_from_center(p, pctr);
        float dist = distance(p, pctr);
        float a = angle + (0.5 * time);
        return vec2(
            pctr.x + (sin(time) * (pctr.x / 2)) + (cos(a) * dist),
            pctr.y + (cos(time) * (pctr.y / 2)) + (sin(a) * dist)
        );
    }

    // radial alignment for texture coordinates
    vec2 tcpt (vec2 t)
    {
        float angle = angle_from_center(t, tctr);
        float dist = distance(t, tctr);
        dist *= 0.8;
        dist = dist + ((sin(0.5 * time) / 5) * (dist/2));
        return vec2(
            tctr.x + (cos(angle) * dist),
            tctr.y + (sin(angle) * dist)
        );
    }

    float v2 (vec2 px)
    {
        float t = 0.25 * time;
        const float freq = (1 / 256.0);
        return noise(vec3(pt(px) * freq, t));
    }

    vec4 effect (vec4 color, Image tex, vec2 tc, vec2 px)
    {
        const float radius = 0.75;
        const float softness = 0.70;
        const vec2 res = vec2(800, 600);
        vec3 clr = vec3(0);

        // use perlin noise to generate values and scale from [-1,1] to [0,1]
        float n = v2(px);
        float pct = n * 0.5 + 0.5;

        // generate two texture coordinates
        vec2 t1 = tcpt(tc);
        vec2 t2 = tc;
        // then two colors from texture
        vec3 a1 = Texel(forest2, t1).rgb;
        vec3 a2 = Texel(forest2, t2).rgb;
        // mix the two to provide effect with step from noise
        clr = mix(a1, a2, pct);

        // apply a vignette for effect
        vec2 pos = (px.xy / res.xy) - vec2(0.5);
        float len = length(pos);
        float vignette = smoothstep(radius, radius - softness, len);

        return vec4(clr, 1) * vignette;
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
