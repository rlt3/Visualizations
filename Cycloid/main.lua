function love.keypressed (key, unicode)
    if key == "escape" or key == "q" then
        love.event.quit()
    elseif key == "=" then
        speed = speed + 5
    elseif key == "-" then
        speed = speed - 5
    end
end

function rgb2hsv (r, g, b)
	r, g, b = r / 255, g / 255, b / 255
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local h, s, v
	v = max
	local d = max - min
	if max == 0 then s = 0 else s = d / max end
	if max == min then
		h = 0
	else
		if max == r then
		h = (g - b) / d
		if g < b then h = h + 6 end
		elseif max == g then h = (b - r) / d + 2
		elseif max == b then h = (r - g) / d + 4
		end
		h = h / 6
	end
	return h, s, v
end

function hsv2rgb (h, s, v)
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

function rot_val (val)
    if val < 0 then
        val = 1 - val
    elseif val > 1 then
        val = val - 1
    end
end

function add_hue (dir)
    hsv[1] = hsv[1] + (dir * (1 / (360 * 2)))
    rot_val(hsv[1])
end

function add_sat (dir)
    hsv[2] = hsv[2] + (dir * 0.0001)
    rot_val(hsv[2])
end

function love.load ()
    hsv = { 0, 0.5, 1 }
    size = 5
    angle = 0
    dist = 100
    speed = 50
    center = { x = love.graphics.getWidth() / 2, y = love.graphics.getHeight() / 2 }
    canvas = love.graphics.newCanvas()
end

-- 1 or 0 over time
function square (t)
    return math.pow(-1, math.floor(2 * t))
end

function triangle (t, phase)
    local period = (t + phase) / math.pi
    return 2 * math.abs(2 * (period - math.floor(period + 0.5))) - 1
end

function sawtooth (t, phase)
    --return ((t + phase) % 2) - 1
    phase = phase * (math.pi / 2)
    return (((t + phase) % math.pi) / (math.pi / 2)) - 1
end

function epitrochoid (t)
    local num_petals = 7
    local smoothness = 0.75
    local R = dist
    local r = dist / num_petals
    local d = r * smoothness
    return center.x + (((R + r) * math.cos(t)) - (d * math.cos(((R + r) / r) * t))),
           center.y + (((R + r) * math.sin(t)) - (d * math.sin(((R + r) / r) * t)))
end

function epicycloid (t, k)
    local r = dist / k
    return center.x + (r * (k + 1) * math.cos(t)) - (r * math.cos((k + 1) * t)),
           center.y + (r * (k + 1) * math.sin(t)) - (r * math.sin((k + 1) * t))
end

function love.update (dt)
    angle = angle + (speed * dt)
    local t = math.rad(angle)

    --x = center.x + (math.cos(t) * dist)
    --y = center.y + (math.sin(t) * dist)

    --x = center.x + (triangle(t, 0) * dist)
    --y = center.y + (triangle(t, 1) * dist)

    --x = center.x + (sawtooth(t, 0) * dist)
    --y = center.y + (sawtooth(t, 1) * dist)

    --x = center.x + (dist * (t - math.sin(t)))
    --y = center.y + (dist * (1 - math.cos(t)))

    --x, y = epicycloid(t, 36 / 5)
    x, y = epicycloid(t, 31 / 15)

    add_hue(1)
    canvas:renderTo(function()
        love.graphics.setColor(hsv2rgb(unpack(hsv)))
        love.graphics.circle("fill", x, y, size)
    end)
end

function love.draw ()
    love.graphics.draw(canvas)
end
