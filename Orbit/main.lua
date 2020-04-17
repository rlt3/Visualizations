local Vector = require("Vector")

function love.conf (t)
    t.window.title = "Network Flow"
    t.window.icon = nil -- Filepath to an image to use as the window's icon (string)
    t.window.width = 800
    t.window.height = 600
    t.gammacorrect = true
end

local Satellite = {}
Satellite.__index = Satellite

function Satellite.new (curve)
    return setmetatable({
        curve = curve,
        t = 1,
        dir = 1,
        size = 20
    }, Satellite)
end

function Satellite:update (dt)
    local scale = 0.5
    self.t = self.t + self.dir
    if self.t >= 100 or self.t <= 1 then
        self.dir = -self.dir
    end
    if self.t < 50 then
        scale = scale
    else
        scale = -scale
    end
    self.size = self.size + scale
    if self.size < 1 then self.size = 1 end
end

function Satellite:draw()
    local point = self.curve.points[self.t]
    love.graphics.circle("fill", point.x, point.y, self.size)
end

local Orbit = {}
Orbit.__index = Orbit

-- Simulate the 'orbiting' effect with a bezier curve where the middle two
-- control points, p2 and p3, are very near to p1 and p2 respectively
function Orbit.new (a, b)
    local p1 = a
    local p2 = Vector.new(a.x + 5, a.y)
    local p3 = Vector.new(b.x - 5, b.y)
    local p4 = b

    -- generate a single point on a cubic bezier curve
    local point = function(t)
        local x = math.pow(1-t,3) * p1.x + 3 * t * math.pow(1-t,2) * p2.x + 3 * math.pow(t,2) * (1-t) * p3.x + math.pow(t,3) * p4.x
        local y = math.pow(1-t,3) * p1.y + 3 * t * math.pow(1-t,2) * p2.y + 3 * math.pow(t,2) * (1-t) * p3.y + math.pow(t,3) * p4.y
        return Vector.new(x, y)
    end

    local t = {}
    t.points = {}
    local time = 0.0
    for i = 1, 101 do
        t.points[i] = point(time)
        time = time + 0.01
    end
    return setmetatable(t, Orbit)
end

function Orbit:draw ()
    for i, point in ipairs(self.points) do
        love.graphics.circle("fill", point.x, point.y, 2)
    end
end

function love.load ()
    path = Orbit.new(Vector.new(50, 300), Vector.new(750, 300))
    sat = Satellite.new(path)
end

function love.draw ()
    sat:draw()
    love.graphics.rectangle("fill", 380, 280, 40, 40)
end

function love.update (dt)
    sat:update(dt)
end
