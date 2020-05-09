local System = require("System")
local Vector = require("Vector")
local Stack = require("Stack")

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

    local transition = {
        ["0"] = "1[0]0",
        ["1"] = "11",
        ["["] = "[",
        ["]"] = "]",
    }

    L = System.new(transition, "0", Width / 2, Height / 2, -90)

    Time = 0
    Next = 0
end

function love.draw ()
    L:draw()
end

function love.update (dt)
	Time = Time + dt

    L:update(dt)

    --if Time > Next then
    --    Next = Next + (1 / 60)
    --    L:step()
    --end
end
