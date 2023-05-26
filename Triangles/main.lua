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

function shape (x, y, r, numlines)
    local angle = 360 / numlines
    local pts = {}
    for n = 1, numlines do
        local px,py = pointAtDegree(x, y, r, n * angle)
        love.graphics.line(x,y, px,py)
        table.insert(pts, px)
        table.insert(pts, py)
    end

    if #pts >= 6 then
        love.graphics.polygon("line", pts)
    end
end

function regular_shapes ()
    --shape(100, 100, 50, 1)
    --shape(300, 100, 50, 2)
    --shape(500, 100, 50, 3)
    --shape(700, 100, 50, 4)

    --shape(100, 300, 50, 5)
    --shape(300, 300, 50, 6)
    --shape(500, 300, 50, 7)
    --shape(700, 300, 50, 8)

    --shape(100, 500, 50, 9)
    --shape(300, 500, 50, 10)
    --shape(500, 500, 50, 11)
    --shape(700, 500, 50, 12)

    shape(100, 100, 75, 1)
    shape(400, 100, 75, 2)
    shape(700, 100, 75, 3)

    shape(100, 300, 75, 4)
    shape(400, 300, 75, 5)
    shape(700, 300, 75, 6)

    shape(100, 500, 75, 7)
    shape(400, 500, 75, 8)
    shape(700, 500, 75, 9)
end

function circle (x, y, r)
    local pts = {}
    for d = 1, 360 do
        local px,py = pointAtDegree(x, y, r, d)
        table.insert(pts, px)
        table.insert(pts, py)
    end
    love.graphics.polygon("line", pts)
end

local degree = 0
local degree_dt = 0

function love.draw ()
    local x,y = 400,300
    local r = 100

    -- draw a circle at x,y of radius r
    circle(x, y, r)

    -- have px,py be the center of another circle, with r radius
    local px,py = pointAtDegree(x, y, r, degree)
    circle(px, py, r)

    -- draw the centers of these circles
    love.graphics.setPointSize(5)
    love.graphics.points(x, y)
    love.graphics.points(px, py)

    -- with px,py as the center of our next circle, we have necessarily given
    -- it an angle, i.e. `degree`. we want the top-most point of our
    -- equilateral triangle (which I call `a`) to be the center of our first
    -- circle. if that's the case, then our equilateral triangle will have its
    -- other 2 points 60 degrees from itself, because 3*60 = 180.
    local bx,by = pointAtDegree(px, py, r, degree - 60)
    local cx,cy = pointAtDegree(px, py, r, degree + 60)

    love.graphics.polygon("line", x,y, bx,by, cx,cy)
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
