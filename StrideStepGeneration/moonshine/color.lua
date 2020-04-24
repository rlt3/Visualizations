return function(moonshine)
  local shader = love.graphics.newShader[[
    #define PI 3.1415926535897932384626433832795
    extern float time;

    float speed = 1;
    float radius = 100;
    vec2 scenter = vec2(400, 300); // screen center
    vec2 tcenter = vec2(0.5, 0.5); // texture center

    // returns a float from [-PI,PI]
    // returns a float from [0, 360]
    float angle_from_center (vec2 p)
    {
        scenter.y += sin(time) * 150;
        scenter.x += cos(time) * 150;

        //return atan(p.y - scenter.y, p.x - scenter.x);
        return degrees(atan(p.y - scenter.y, p.x - scenter.x)) + 180;
    }

    bool point_in_circle (vec2 p)
    {
        float xc = p.x - scenter.x;
        float yc = p.y - scenter.y;
        return pow(xc,2) + pow(yc,2) < pow(radius,2);
    }

	vec3 hsv2rgb(vec3 c)
	{
		vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
		vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
		return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
	}

    vec4 effect (vec4 color, Image tex, vec2 uv, vec2 px)
    {
        //float hue = (angle_from_center(px) + (time * 15)) / 360;
        float hue = 0.05 * time;
        //float sat = clamp(sin(time) + 1, 0, 0.8);
        float sat = 1;
        float val = 1;
        if (time < 1)
            val = smoothstep(0, 1, time / 1);
        if (time > 19)
            val = 1 - smoothstep(0, 1, (time - 19) / 1);
		vec3 hsv = vec3(hue,sat,val);
		vec3 rgb = hsv2rgb(hsv);
        return Texel(tex, uv) * vec4(rgb, 1);
    }
  ]]

  local setters = {}

  setters.time = function(v) shader:send("time", v) end

  local defaults = {
      time = 0.1,
  }

  return moonshine.Effect{
    name = "color",
    shader = shader,
    setters = setters,
    defaults = defaults
  }
end
