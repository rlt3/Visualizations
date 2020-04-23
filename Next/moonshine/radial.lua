return function(moonshine)
  local shader = love.graphics.newShader[[
    extern number time;

    //float speed = 0.25;
    float speed = 1;
    float radius = 250;
    vec2 scenter = vec2(400, 300); // screen center
    vec2 tcenter = vec2(0.5, 0.5); // texture center

    // returns a float from [-PI,PI]
    float angle_from_center (vec2 p)
    {
        return atan(p.y - scenter.y, p.x - scenter.x);
    }

    bool point_in_circle (vec2 p)
    {
        float r = (cos(time * 0.5) * 250) + radius;
        float xc = p.x - scenter.x;
        float yc = p.y - scenter.y;
        return pow(xc,2) + pow(yc,2) < pow(r, 2);
    }

    vec4 effect (vec4 color, Image tex, vec2 uv, vec2 px)
    {
        //if (!point_in_circle(px))
        //    return Texel(tex, uv);

        int g = int(point_in_circle(px));
        int b = int(!point_in_circle(px));

        float a = angle_from_center(px);
        a += speed * time;
        float t = clamp(time, 0, 5);
        float r = smoothstep(0, 8, distance(uv, tcenter));

        float v = (sin(time) + 1) * 25;
        float w = clamp(time, 0, 5);

        vec2 p = vec2(uv.x + (cos(a) * g * v * r) + (sin(a) * b * w * r), 
                      uv.y + (sin(a) * g * v * r) + (cos(a) * b * w * r));
        return Texel(tex, p);

        //float a = angle_from_center(px);
        //a += speed * time;
        //float t = clamp(time, 0, 5);
        //float r = smoothstep(0, 12, distance(uv, tcenter));
        //vec2 p = vec2(uv.x + (cos(a) * t * r), uv.y + (sin(a) * t * r));
        //return Texel(tex, p);
    }
  ]]

  local setters = {}

  setters.time = function(v) shader:send("time", v) end

  local defaults = {
      time = 0.1,
  }

  return moonshine.Effect{
    name = "radial",
    shader = shader,
    setters = setters,
    defaults = defaults
  }
end

