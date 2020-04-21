local moonshine = require("moonshine")
local Vector = require("Vector")
local Queue = require("Queue")
local Text = require("Text")

function math.prandom(min, max) return love.math.random() * (max - min) + min end

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

function Satellite.new (curve, miss)
    local t = {
        curve = curve,
        t = 1,
        dir = 1,
        has_approached = false,
        miss = miss
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
    -- prevent extraneous work
    if self.time > 2 then return end

    self.time = self.time + (dt * 0.75)
    self.pos = Vector.lerp(self.orig, self.dest, self.time)

    -- scale the size of the satellite from whichever direction it is coming
    if self.background == 1 then
        self.size = self.size + SCALE
    else
        self.size = self.size - SCALE
    end

    -- never allow the satellite to enter orbit if it misses
    if self.miss then
        return
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

function within_fifteen (degree)
    for i, d in ipairs(Degrees) do
        if math.abs(d - degree) <= 15 then
            return true
        end
    end
    return false
end

function random_orbit (constrain)
    local degree = math.random(1, 360)
    if constrain then
        while within_fifteen(degree) do
            degree = math.random(1, 360)
        end
        table.insert(Degrees, degree)
    end
    local angle_a = math.rad(degree)
    local angle_b = math.rad(degree + 180)
    return Orbit.new(point_on_circle(angle_a), point_on_circle(angle_b))
end

function random_satellite (should_miss)
    local constrain = true
    if should_miss then constrain = false end
    local path = random_orbit(constrain)
    Satellites[SATi] = Satellite.new(path, should_miss)
    SATi = SATi + 1
end

function random_star ()
    local size = math.prandom(2, 3.5)
    local star = {
        x = math.random(1, 800),
        y = math.random(1, 600),
        size = size,
        max = size + 1,
        min = size - 1,
        dir = 1
    }
    return star
end

function love.conf (t)
    t.window.title = "Orbit"
    t.window.icon = nil -- Filepath to an image to use as the window's icon (string)
    t.window.width = 800
    t.window.height = 600
    t.gammacorrect = true
end

function love.load ()
    local seed = os.time()
    math.randomseed(seed)
    print(seed)

    Time = 0

    -- Needed for random satellite generation
    Degrees = {}
    Satellites = {}
    SATi = 1

    TitleMoveDone = false
    StartFlashDone = false
    SunZoomedIn = false
    MissedSatellites = 0
    SatelliteSpawned = false
    OrbitPulseDone = false

    NextSatellite = 0

    -- move the Title and Start up from the bottom to a stopping point
    TitleY = 1000
    TitleYStop = 200

    -- for handling when to start and stop flashing the 'press start' text
    StartToggleTime = 0
    StartToggleStop = 0
    StartFlashTime = 0
    StartFlashColors = {
        {0, 0, 0},
        {255, 255, 255},
    }
    StartFlashIdx = 1

    -- for keeping track of score
    ScoreTally = 0

    hiscore = Text.new("HISCORE: LEROY 1337", -10, 10, 16, "right")
    title = Text.new("Orbit", 0, TitleY, 112)
    start = Text.new("Press Start", 0, 400, 36)
    lose = Text.new("You Lose", 0, 225, 112)
    sad = Text.new(":(", 0, 225, 112)

    start.display = false
    lose.display = false
    sad.display = false

    Pulse = {
        display = false,
        size = 0,
        max = 100,
        draw = function (t)
            if not t.display then return end
            love.graphics.circle("line", 400, 300, t.size)
        end
    }

    Sun = {
        display = false,
        size = 0,
        max = 40,
        draw = function (t)
            if not t.display then return end
            local center = { x = 400, y = 300 }
            local x = center.x - (t.size / 2)
            local y = center.y - (t.size / 2)
            love.graphics.rectangle("fill", x, y, t.size, t.size)
        end
    }

    ShootDir = {
        { x =  1, y =  1 },
        { x = -1, y =  1 },
        { x =  1, y = -1 },
        { x = -1, y = -1 },
    }
    ShootAt = 2.5 -- start shooting at 2.5 seconds
    ShootingStars = {}
    Stars = {}
    for i = 1, 108 do
        table.insert(Stars, random_star())
    end

    scanline_phase = 0
    scanline_freq = 800

    ScreenShader = moonshine(moonshine.effects.dmg)
             .chain(moonshine.effects.chromasep)
             .chain(moonshine.effects.crt)
             .chain(moonshine.effects.scanlines)
             --.chain(moonshine.effects.ripple)
    ScreenShader.dmg.palette = 'green'
    ScreenShader.chromasep.angle = 0
    ScreenShader.chromasep.radius = 2
    ScreenShader.scanlines.thickness = 0.25
    ScreenShader.scanlines.phase = scanline_phase
    ScreenShader.scanlines.frequency = scanline_freq
end

function love.draw ()
    ScreenShader(function()
        for i, star in ipairs(Stars) do
            love.graphics.circle("fill", star.x, star.y, star.size)
        end
        for i, star in ipairs(ShootingStars) do
            love.graphics.circle("fill", star.x, star.y, star.size)
        end
        for i, sat in ipairs(Satellites) do
            sat:draw()
        end
        title:draw()
        start:draw()
        hiscore:draw()
        lose:draw()
        sad:draw()
        Sun:draw()
        Pulse:draw()
    end)
end

function love.update (dt)
    Time = Time + dt
    --ScreenShader.ripple.time = Time

    if not TitleMoveDone then
        local diff = (300 * dt)
        TitleY = TitleY - diff
        if TitleY < TitleYStop then
            TitleY = TitleYStop
            start.display = true
            TitleMoveDone = true
        end
        title.y = TitleY
        StartToggleTime = Time + 2.5
        StartToggleStop = Time + 5
    elseif not StartFlashDone then
        if Time > StartToggleTime then
            start.text = "→ Press Start ←"
            if Time > StartFlashTime then
                StartFlashTime = Time + 0.10
                start.color = StartFlashColors[StartFlashIdx]
                if StartFlashIdx == 1 then
                    StartFlashIdx = 2
                else
                    StartFlashIdx = 1
                end
            end
        end
        if Time > StartToggleStop then
            StartFlashDone = true
        end
    elseif not SunZoomedIn then
        title.display = false
        start.display = false
        hiscore.text = "SCORE: " .. tostring(ScoreTally)
        Sun.display = true
        if Sun.size < Sun.max then
            Sun.size = Sun.size + (25 * dt)
        else
            SunZoomedIn = true
        end
    elseif MissedSatellites < 3 then
        if Time > NextSatellite then
            random_satellite(true)
            NextSatellite = Time + 1.5
            MissedSatellites = MissedSatellites + 1
        end
    elseif not OrbitPulseDone then
        Pulse.display = true
        Pulse.size = Pulse.size + (50 * dt)
        if Pulse.size >= Pulse.max then
            Pulse.size = 0
        end
    end

    scanline_phase = scanline_phase + 0.25
    if math.random(0, 1) > 0 then
        scanline_freq = scanline_freq - 1
    else
        scanline_freq = scanline_freq + 1
    end
    ScreenShader.scanlines.phase = scanline_phase
    ScreenShader.scanlines.frequency = scanline_freq

    for i, star in ipairs(Stars) do
        local diff = star.dir * dt
        if star.size + diff < star.min or star.size + diff > star.max then
            star.dir = -star.dir
        else
            star.size = star.size + diff
        end
    end

    for i, star in ipairs(ShootingStars) do
        local dir = star.dir
        star.x = star.x + (dir.x * (star.speed * dt))
        star.y = star.y + (dir.x * (star.speed * dt))
    end

    if Time > ShootAt then
        ShootAt = ShootAt + 2.5
        local star = random_star()
        star.dir = ShootDir[math.random(1, #ShootDir)]
        star.speed = math.random(75, 125)
        table.insert(ShootingStars, star)
    end

    for i, sat in ipairs(Satellites) do
        sat:update(dt)
    end

    -- I can just replace some update and draw functions (not the main ones)
    -- with the appropriate one for the scene. I can still fill out the main
    -- ones with the appropriate shaders and background stuff and then change
    -- out the scene functions whenever appropriate.
    --if Time > 8 then
    --    love.update = SecondUpdate
    --end
end
