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

    Width = love.graphics.getWidth()
    Height = love.graphics.getHeight()

    math.randomseed(os.time())

    local step = function (sys)
        local str = ""
        for c in sys:gmatch"." do
            if c == "0" then
                str = str .. "1[0]0"
            elseif c == "1" then
                str = str .. "11"
            else
                str = str .. c
            end
        end
        return str
    end

    Dist = Height - 100

    local draw = function (sys)
        -- current pos. also the starting position
        local pos = Vector.new(Width / 2, Height - 100)
        -- current angle. also starting angle
        local angle = -90
        -- collection of all points to draw
        local points = {}
        -- stack of angles and positions to push and pop from
        local stack = Stack.new()

        --table.insert(points, pos.x)
        --table.insert(points, pos.y)

        local calcNext = function (d)
            local rad = math.rad(angle)
            local p1 = pos
            local p2 = Vector.new(p1.x + (math.cos(rad) * d),
                                  p1.y + (math.sin(rad) * d))
            table.insert(points, p1.x)
            table.insert(points, p1.y)
            table.insert(points, p2.x)
            table.insert(points, p2.y)
            pos = p2
        end

        for c in sys:gmatch"." do
            if c == "0" then
                calcNext(Dist / 2)
            elseif c == "1" then
                calcNext(Dist)
            elseif c == "[" then
                stack:push(angle)
                stack:push(pos)
                angle = angle + 45
            elseif c == "]" then
                pos = stack:pop()
                --table.insert(points, pos.x)
                --table.insert(points, pos.y)
                angle = stack:pop()
                angle = angle - 45
            else
                error("Bad value `" .. c .. "'")
            end
        end

        for i = 1, #points, 4 do
            love.graphics.line(points[i], points[i + 1], points[i + 2], points[i + 3])
        end

        --love.graphics.line(points)
    end

    L = System.new("0", step, draw)

    Time = 0
    Next = 0
end

function love.draw ()
    L:draw()
end

function love.update (dt)
	Time = Time + dt

    if Time > Next then
        Next = Next + 0.5
        Dist = Dist - (Dist / 2)
        L:step()
    end
end
