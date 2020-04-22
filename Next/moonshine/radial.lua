return function(moonshine)
  -- Barrel distortion adapted from Daniel Oaks (see commit cef01b67fd)
  -- Added feather to mask out outside of distorted texture
  local distortionFactor
  local shader = love.graphics.newShader[[
    extern number time;

    float speed = 25;
    float radius = 100;
    vec2 scenter = vec2(400, 300); // screen center
    vec2 tcenter = vec2(0.5, 0.5); // texture center

    // returns a float from [-PI,PI]
    float angle_from_center (vec2 p)
    {
        return atan(p.y - scenter.y, p.x - scenter.x);
    }

    bool point_in_circle (vec2 p)
    {
        float xc = p.x - scenter.x;
        float yc = p.y - scenter.y;
        return pow(xc,2) + pow(yc,2) < pow(radius,2);
    }

    vec4 effect (vec4 color, Image tex, vec2 uv, vec2 px)
    {
        if (!point_in_circle(px))
            return Texel(tex, uv);

        float a = angle_from_center(px);
        a += 25 * time;
        float r = distance(uv, tcenter);
        vec2 p = vec2(tcenter.x + (cos(a) * r), tcenter.y + (sin(a) * r));
        return Texel(tex, p);
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

