function love.conf (t)
    t.window.title = "Trinity"
    t.window.icon = nil -- Filepath to an image to use as the window's icon (string)
    t.console = true
end

function love.keypressed(k)
    if k == 'escape' or k == 'q' then
        love.event.quit()
    end
end

function lerp (from, to, t)
    return (1 - t) * from + t * to;
end

function distance (x,y, m,n)
    return math.sqrt((m-x)*(m-x) + (n-y)*(n-y))
end

function step (t, dt)
    if t == 1 then
        t = 0
    end
    t = t + dt
    if t >= 1 then
        t = 1
    end
    return t
end

function pointAtDegree (x, y, r, degree)
    -- negative degrees here because we're in upside-down world
    local deg = math.rad(-degree)
    local px = x + (r * math.cos(deg))
    local py = y + (r * math.sin(deg))
    return px, py
end

function circle (x, y, r, kind, black)
    local pts = {}
    for d = 1, 360 do
        local px,py = pointAtDegree(x, y, r, d)
        table.insert(pts, px)
        table.insert(pts, py)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon(kind, pts)
end

function trail (x, y, r, t)
    local degree = math.floor(lerp(0, 360, t))
    for d = 0, 360 do
        local px,py = pointAtDegree(x, y, r, d + degree)
        love.graphics.setColor(1, 0.84, 0, lerp(0, 1, math.fmod(d, 360) / 360))
        love.graphics.points(px, py)
    end
end

function lerpDegree (t)
    return math.floor(lerp(0, 360, t))
end

function equilateral (x, y, r, t)
    love.graphics.setColor(1, 1, 1)

    local degree = 90
    if t ~= nil then
        degree = lerpDegree(t)
    end

    local ax,ay = pointAtDegree(x, y, r, degree)
    local bx,by = pointAtDegree(x, y, r, degree + 120)
    local cx,cy = pointAtDegree(x, y, r, degree + 240)

    love.graphics.polygon("line", ax,ay, bx,by, cx,cy)
    return ax,ay, bx,by, cx,cy
end

function square (x, y, r, t)
    local degree = lerpDegree(t)
    local ax,ay = pointAtDegree(x, y, r, degree)
    local bx,by = pointAtDegree(x, y, r, degree + 90)
    local cx,cy = pointAtDegree(x, y, r, degree + 180)
    local dx,dy = pointAtDegree(x, y, r, degree + 270)

    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon("line", ax,ay, bx,by, cx,cy, dx, dy)
end

local at = 0.01
local bt = 0.34
local ct = 0.67

local tt = 0
local wt = 0

function love.load ()
    love.graphics.setLineWidth(3)
    love.graphics.setPointSize(4)

    love.window.setMode(1080, 1350)
end

function love.draw ()
    local width, height = love.graphics.getDimensions()
    local x, y = width/2, height/2

    local r = 180

    circle(x, y, r * 0.05, "fill")

    love.graphics.push()
    -- rotate entire canvas relative to the center, not (0,0)
    love.graphics.translate(x, y)
    love.graphics.rotate(math.rad(lerpDegree(1 - wt)))
    love.graphics.translate(-x, -y)

    -- measure equilateral points at a certain radius
    local ax,ay, bx,by, cx,cy = equilateral(x, y, r)

    -- using the length of the equilateral's side, we measure the trinity
    local s = distance(ax,ay, bx,by)
    trail(ax, ay, s, at)
    trail(bx, by, s, bt)
    trail(cx, cy, s, ct)

    -- four corners rotate
    square(x, y, r + s, 1 - tt)
    -- draw the circle which encompasses all
    circle(x, y, r + s, "line")

    love.graphics.pop()
end

function love.update (dt)
    at = step(at, dt)
    bt = step(bt, dt)
    ct = step(ct, dt)
    tt = step(tt, dt * 0.10)
    wt = step(wt, dt * 0.05)
end
