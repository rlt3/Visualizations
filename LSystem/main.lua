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

    L = System.new(initial, transition, dispatch)
    L:stepn(6)

    Time = 0
    Next = 0
end

function love.draw ()
    L:draw()
end

function love.update (dt)
	Time = Time + dt
    L:update(dt)

    --if L:done() and Time > Next then
    --    Next = Time + 0.5
    --    L:step()
    --end
end
