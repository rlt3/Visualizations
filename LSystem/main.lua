local Camera = require("Camera")
local System = require("System")
local Vector = require("Vector")

-- Gives a precise random decimal number given a minimum and maximum
function math.prandom (min, max)
    return math.random() * (max - min) + min
end

function love.keypressed (key, unicode)
    if key == "escape" or key == "q" then
        love.event.quit()
    elseif key == "e" then
        --Curve.speed = Curve.speed * (0.9)
        Cam.scale = Cam.scale * 1.1
    elseif key == "d" then
        --Curve.speed = Curve.speed * (1.1)
        Cam.scale = Cam.scale * 0.9
    end
end

function love.load ()
    --love.window.setPosition(0, 0)
    --love.graphics.setBlendMode("replace")

    Width = love.graphics.getWidth()
    Height = love.graphics.getHeight()

    math.randomseed(os.time())

    --local initial = {
    --    state = "X",
    --    position = Vector.new(150, Height),
    --    angle = -60,
    --    speed = 2000,
    --    length = 2.5,
    --    width = 2.5,
    --}

    --local transition = {
    --    ["X"] = "F+[[X]-X]-F[-FX]+X",
    --    ["F"] = "FF",
    --}

    --local dispatch = {
    --    ["X"] = nil,
    --    ["F"] = System.state.draw,
    --    ["["] = System.state.push,
    --    ["]"] = System.state.pop,
    --    ["-"] = { System.state.angle, 25  },
    --    ["+"] = { System.state.angle, -25 },
    --}

    --Fern = System.new(initial, transition, dispatch)
    --Fern:stepn(6)

    --local init3 = {
    --    state = "FCL",
    --    position = Vector.new(0, 0),
    --    angle = 192,
    --    speed = 200,
    --    length = 50,
    --    width = 10,
    --}

    --local trans3 = {
    --    ["F"] = "CLFLF",
    --    ["C"] = "+F-F-F",
    --    ["L"] = "[]L-FFCCF",
    --}

    --local dispatch3 = {
    --    ["F"] = System.state.draw,
    --    ["["] = System.state.push,
    --    ["]"] = System.state.pop,
    --    ["-"] = { System.state.angle, 192 },
    --    ["+"] = { System.state.angle, -192 },
    --}

    --Sharp = System.new(init3, trans3, dispatch3)
    --Sharp:stepn(5)

    local init2 = {
        state = "FX",
        position = Vector.new(0, 0),
        angle = 90,
        speed = 5,
        length = 50,
        width = 10,
    }

    local trans2 = {
        ["X"] = "X+YF+",
        ["Y"] = "-FX-Y",
    }

    local dispatch2 = {
        ["F"] = System.state.draw,
        ["-"] = { System.state.angle, 90 },
        ["+"] = { System.state.angle, -90 },
    }

    Curve = System.new(init2, trans2, dispatch2)
    Curve:stepn(12)

    Cam = Camera:new(Width / 2, Height / 2)
    Cam.scale = 2

    --setupBezier()
    setupShift()
end

function setupShift ()
    Time = 0
    T = 0
    Scale = 16
    Positions = Curve:discrete(Scale)
    Pos = Curve.pos
    NumPositions = Positions:length()
    doWait = false
    TWait = 0

    State = 0
end

function mix (x, y, a)
    return x * (1 - a) + y * a
end

function updateShift (dt)
    local speed = ((Curve.speed / (Scale / 2))  * dt)
    Time = Time + dt

    if doWait then
        if Time < Timeout then
            return
        else
            doWait = false
        end
    end

    T = T + speed

    if T > 1 then
        T = T - 1
        Pos = Positions:pop()
        doWait = true
        Timeout = Time + 2
        print(Positions:length())
    end

    if Positions:length() > 0 then
        local pos = Vector.lerp(Pos, Positions:front(), T)
        Cam:moveTo(pos.x, pos.y)

        if State == 1 then
            Cam.scale = 2 - mix(0, 0.25, T)
            Curve.speed = 5 + mix(0, 1, T)
        end
    end

    if State == 0 and Positions:length() < NumPositions * 0.97 then
        State = 1
    end
end

function setupBezier ()
    T = 0
    Scale = 16
    Positions = Curve:discrete(Scale)
    Positions:pushfront(Curve.pos)
    nextBezier()
    NumPositions = Positions:length()
end

function nextBezier ()
    local p1 = Positions:pop()
    local c  = Positions:pop()
    local p2 = Positions:front()
    Bezier = love.math.newBezierCurve(p1.x, p1.y, c.x, c.y, p2.x, p2.y)
end

function updateBezier (dt)
    local speed = ((Curve.speed / (Scale * 2))  * dt)
    T = T + speed
    if T > 1 then
        T = T - 1
        nextBezier()
    end
    if Positions:length() > 0 then
        Cam:moveTo(Bezier:evaluate(T))
    end
    if Positions:length() < NumPositions * 0.75 then
        Cam.scale = Cam.scale - (speed / Scale)
        Curve.speed = Curve.speed * (speed)
    end
end

function love.draw ()
    Cam:set()
    Curve:draw()
    Cam:unset()
end

once = false

function love.update (dt)
    Curve:update(dt)

    --updateBezier(dt)
    updateShift(dt)
end
