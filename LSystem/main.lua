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
    end
end

function love.load ()
    --love.window.setPosition(0, 0)
    --love.graphics.setBlendMode("replace")

    Width = love.graphics.getWidth()
    Height = love.graphics.getHeight()

    math.randomseed(os.time())

    local initial = {
        state = "X",
        position = Vector.new(150, Height),
        angle = -60,
        speed = 2000,
        length = 2.5,
        width = 2.5,
    }

    local transition = {
        ["X"] = "F+[[X]-X]-F[-FX]+X",
        ["F"] = "FF",
    }

    local dispatch = {
        ["X"] = nil,
        ["F"] = System.state.draw,
        ["["] = System.state.push,
        ["]"] = System.state.pop,
        ["-"] = { System.state.angle, 25  },
        ["+"] = { System.state.angle, -25 },
    }

    Fern = System.new(initial, transition, dispatch)
    Fern:stepn(6)

    local init2 = {
        state = "FX",
        position = Vector.new(Width / 2, Height / 2),
        angle = 90,
        speed = 25,
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
    Cam.scale = 0.25

    Time = 0
    Next = 0
end

function love.draw ()
    Cam:set()
    --Fern:draw()
    Curve:draw()
    Cam:unset()
end

once = false

function love.update (dt)
	Time = Time + dt

    --Fern:update(dt)
    Curve:update(dt)

    if not once and Curve.active then
        once = true
        local x, y = Curve.active.pos.x, Curve.active.pos.y
        Cam:moveTo(x, y)
    end
    --Cam.scale = Cam.scale - (0.10 * dt)

    --Curve.speed = Curve.speed + (1 * dt)
    --Cam.target.screenY = Cam.target.screenY - (5 * dt)
    --Cam.target.screenX = Cam.target.screenX - (10 * dt)

    --if L:done() and Time > Next then
    --    Next = Time + 0.5
    --    L:step()
    --end
end
