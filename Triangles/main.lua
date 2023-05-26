function love.conf (t)
    t.window.title = "Triangles"
    t.window.icon = nil -- Filepath to an image to use as the window's icon (string)
    t.window.width = 800
    t.window.height = 600
    t.console = true
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

local degree = 0
local degree_dt = 0

function trail (x, y, r)
    love.graphics.setPointSize(2)
    for d = 0, 360 do
        local px,py = pointAtDegree(x, y, r, d + degree)
        love.graphics.setColor(1, 0.84, 0, lerp(0, 1, math.fmod(d, 360) / 360))
        love.graphics.points(px, py)
    end
end

function love.draw ()
    local x,y = 400,300
    local r = 100

    -- have px,py be the center of another circle, with r radius
    local px,py = pointAtDegree(x, y, r, degree)
    circle(px, py, r)

    -- draw the original circle as a golden trail
    trail(x, y, r, degree)

    -- with px,py as the center of our next circle, we have necessarily given
    -- it an angle, i.e. `degree`. we want the top-most point of our
    -- equilateral triangle (which I call `a`) to be the center of our first
    -- circle. if that's the case, then our equilateral triangle will have its
    -- other 2 points 60 degrees from itself, because 3*60 = 180.
    local bx,by = pointAtDegree(px, py, r, degree - 60)
    local cx,cy = pointAtDegree(px, py, r, degree + 60)

    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon("line", x,y, bx,by, cx,cy)

    -- draw the centers of the circles
    love.graphics.setPointSize(5)
    love.graphics.points(px, py)

    love.graphics.setColor(1, 0, 0)
    love.graphics.points(x, y)
    love.graphics.setColor(0, 1, 0)
    love.graphics.points(bx, by)
    love.graphics.setColor(0, 0, 1)
    love.graphics.points(cx, cy)
end

function lerp (from, to, t)
    return (1 - t) * from + t * to;
end

function love.update (dt)
    degree_dt = degree_dt + (dt / 5)
    if degree_dt >= 1 then
        degree_dt = 0
    end
    degree = math.floor(lerp(0, 360, degree_dt))
end
