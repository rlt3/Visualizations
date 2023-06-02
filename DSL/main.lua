local Pipeline = require("Pipeline")
local Effect = require("Effect")

function love.conf (t)
    t.window.title = "Triangles"
    t.window.icon = nil -- Filepath to an image to use as the window's icon (string)
    t.window.width = 800
    t.window.height = 600
    t.console = true
end

function love.keypressed(k)
    if k == 'escape' or k == 'q' then
        love.event.quit()
    end
end

function pointAtDegree (x, y, r, degree)
    -- negative degrees here because we're in upside-down world
    local deg = math.rad(-degree)
    local px = x + (r * math.cos(deg))
    local py = y + (r * math.sin(deg))
    return px, py
end

function circle (x, y, r)
    local pts = {}
    for d = 1, 360 do
        local px,py = pointAtDegree(x, y, r, d)
        table.insert(pts, px)
        table.insert(pts, py)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon("line", pts)
end

function lerp (from, to, t)
    return (1 - t) * from + t * to;
end

function circle_context (x, y)
    local t = 0
    local dt = 0
    local done = false

    return function ()
        while true do
            r = lerp(1, 400, t)
            circle(x, y, r)

            if done == true then
                return
            end

            dt = coroutine.yield("continue")
            t = t + dt

            if t >= 1 then
                t = 1
                done = true
            end
        end
    end
end

local Pipeline = Pipeline.new()

function love.load ()
    Pipeline:spawn(Effect.new("respawn", circle_context, 400, 300))
end

function love.draw ()
    Pipeline:draw()
end

function love.mousepressed (x, y, button)
    if button == 1 then
        Pipeline:spawn(Effect.new("once", circle_context, x, y))
    end
end

function love.update (dt)
    Pipeline:update(dt)
end
