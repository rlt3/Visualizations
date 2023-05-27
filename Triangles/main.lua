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

function pyramid (x, y, r, degree)
    -- angle of apex is a 3 twelves of a rotation (36 degrees).
    -- two base angles are 6 twelves of a rotation (72 degrees).
    -- from the given angle, we can rotate 12 twelves (144) in either direction
    -- to achieve the construction.
    local ax,ay = pointAtDegree(x, y, r, degree)
    local bx,by = pointAtDegree(x, y, r, degree + 144)
    local cx,cy = pointAtDegree(x, y, r, degree - 144)
    love.graphics.polygon("line", ax,ay, bx,by, cx,cy)
end

function love.draw ()
    local x,y = 400,300
    local r = 100

    circle(x, y, r)

    pyramid(x, y, r, degree)
    -- we just add 72 degrees, (2/5)pi, to each apex
    pyramid(x, y, r, degree + 72)
    pyramid(x, y, r, degree + 144)
    pyramid(x, y, r, degree + 216)
    pyramid(x, y, r, degree + 288)

    -- 36deg  = pi / 5
    -- 18deg  = pi / 10
    -- 72deg  = (2/5) pi
    -- 144deg = (4/5) pi
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
