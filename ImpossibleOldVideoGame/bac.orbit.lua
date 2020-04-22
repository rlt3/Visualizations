local Vector = require("Vector")
local moonshine = require("moonshine")

function love.conf (t)
    t.window.title = "Network Flow"
    t.window.icon = nil -- Filepath to an image to use as the window's icon (string)
    t.window.width = 800
    t.window.height = 600
    t.gammacorrect = true
end

local Orbit = {}
Orbit.__index = Orbit

-- Simulate the 'orbiting' effect with a cubic bezier curve where the middle
-- two control points are equal to the start and end respectively. This creates
-- a nice, rhytmic motion
function Orbit.new (a, b, angle)
    local p1 = a
    local p2 = a
    local p3 = b
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

local Satellite = {}
Satellite.__index = Satellite

function Satellite.new (curve)
    local t = {
        curve = curve,
        t = 1,
        dir = 1,
        has_approached = false,
    }
    -- get the angle of the bezier curve and then project a point along that
    -- along which is outside the viewport so the satellite approaches from
    -- outside
    local a = curve.points[1]
    local b = curve.points[100]

    -- swap the two end points if the satellite is coming from the background
    -- rather than the foreground
    local background = math.random(0, 1)
    if background == 1 then
        a, b = b, a
        t.size = math.random(5, 20)
    else
        t.size = math.random(20, 35)
    end

    local angle = Vector.angle(b, a)
    local dist = Vector.distance(a, b)
    local pos = point_on_circle(angle, dist)

    t.pos = pos
    t.orig = pos
    t.dest = b
    t.time = 0
    t.speedfactor = 1
    t.background = background

    return setmetatable(t, Satellite)
end

local SCALE = 0.25

function Satellite:approach (dt)
    self.time = self.time + (dt * 0.75)
    self.pos = Vector.lerp(self.orig, self.dest, self.time)

    -- scale the size of the satellite from whichever direction it is coming
    if self.background == 1 then
        self.size = self.size + SCALE
    else
        self.size = self.size - SCALE
    end

    -- If the satellite it close to its dest this it is caught in orbit
    if self.time >= 0.8 then
        -- find the closest point on the bezier curve that corresponds to the
        -- current position of the satellite
        local min = 1000
        local min_point = 100
        for i, point in ipairs(self.curve.points) do
            local d = Vector.distance(self.pos, point)
            if d < min then
                min = d
                min_point = i
            end
        end
        -- and then update it's 't' to that closest point
        self.has_approached = true
        self.t = min_point
        if self.background == 1 then
            self.dir = -self.dir
        end
    end
end

-- Simply increment which point, 't', to draw along the bezier curve. Scale the
-- size of the satellite up and down depending on which direction we're going
-- along the curve
function Satellite:orbit ()
    local scale = SCALE
    self.t = self.t + self.dir
    if self.t >= 100 or self.t <= 1 then
        self.dir = -self.dir
    end
    if self.t < 50 then
        scale = SCALE
    else
        scale = -SCALE
    end
    self.size = self.size + scale
    if self.size < 5 then self.size = 5 end
    if self.size > 35 then self.size = 35 end
end

function Satellite:update (dt)
    if self.has_approached then
        self:orbit(dt)
    else
        self:approach(dt)
    end
end

function Satellite:draw()
    if self.has_approached then
        local point = self.curve.points[self.t]
        love.graphics.circle("fill", point.x, point.y, self.size)
    else
        love.graphics.circle("fill", self.pos.x, self.pos.y, self.size)
    end
end

function point_on_circle (radians, radius)
    local center = Vector.new(400, 300)
    local r = radius or 300
    local x = center.x + (math.cos(radians) * r)
    local y = center.y + (math.sin(radians) * r)
    return Vector.new(x, y)
end

Degrees = {}
Satellites = {}
SATi = 1

function within_fifteen (degree)
    for i, d in ipairs(Degrees) do
        if math.abs(d - degree) <= 15 then
            return true
        end
    end
    return false
end

function random_orbit ()
    local degree = math.random(1, 360)
    while within_fifteen(degree) do
        degree = math.random(1, 360)
    end
    table.insert(Degrees, degree)
    local angle_a = math.rad(degree)
    local angle_b = math.rad(degree + 180)
    return Orbit.new(point_on_circle(angle_a), point_on_circle(angle_b))
end

function random_satellite ()
    local path = random_orbit()
    Satellites[SATi] = Satellite.new(path)
    SATi = SATi + 1
end

IsAbberation = false
AbberationTime = 0
angle = 0
radius = 2
phase = 0
freq = 800
width = 2

function love.load ()
    local seed = os.time()
    math.randomseed(seed)
    print(seed)
    random_satellite()

    titleFont = love.graphics.newFont("Montserrat-SemiBold.ttf", 96)
    startFont = love.graphics.newFont("Montserrat-SemiBold.ttf", 32)

    effect = moonshine(moonshine.effects.pixelate)
             .chain(moonshine.effects.chromasep)
             .chain(moonshine.effects.dmg)
             .chain(moonshine.effects.scanlines)
    effect.pixelate.size = {5,5}
    effect.pixelate.feedback = 0
    effect.chromasep.angle = angle
    effect.chromasep.radius = radius
    effect.dmg.palette = 'dark_yellow'
    effect.scanlines.thickness = 0.5
    effect.scanlines.phase = phase
    effect.scanlines.frequency = freq
    effect.scanlines.width = width
    --effect.glow.strength = 5
end

function love.draw ()
    effect(function()
        for i, sat in ipairs(Satellites) do
            sat:draw()
        end
        love.graphics.rectangle("fill", 380, 280, 40, 40)
    end)
end

T = 0
Cooldown = 5

function love.update (dt)
    T = T + dt
    if T > Cooldown then
        if SATi < 7 and math.random(1, 100) < 5 then
            Cooldown = T + 5
            random_satellite()
        end
    end

    if IsAbberation then
        AbberationTime = AbberationTime + dt
        if AbberationTime < 1 then
            radius = radius + 0.05
            phase = phase + 0.5
            if math.random(0, 1) > 0 then
                freq = freq - 1
                width = width - 1
            else
                freq = freq + 1
                width = width + 1
            end
        else
            IsAbberation = false
            radius = 2
            phase = 0
            freq = 800
            width = 2
        end
        effect.chromasep.radius = radius
        effect.scanlines.phase = phase
        effect.scanlines.frequency = freq
    end
    if not IsAbberation and math.random(1, 100) < 5 then
        IsAbberation = true
        AbberationTime = 0
    end

    for i, sat in ipairs(Satellites) do
        sat:update(dt)
    end
end
