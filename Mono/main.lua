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

function trail (x, y, r, t)
    love.graphics.setPointSize(2)
    local degree = math.floor(lerp(0, 360, t))
    for d = 0, 360 do
        local px,py = pointAtDegree(x, y, r, d + degree)
        love.graphics.setColor(1, 0.84, 0, lerp(0, 1, math.fmod(d, 360) / 360))
        love.graphics.points(px, py)
    end
    love.graphics.setColor(1, 1, 1)
    love.graphics.points(x, y)
end

local a = 0.00
local b = 0.34
local c = 0.67

function love.draw ()
    local r = 100

    local ax,ay = 350, 300
    local bx,by = 450, 300
    local cx,cy = 400, 214

    trail(ax, ay, r, a)
    trail(bx, by, r, b)
    trail(cx, cy, r, c)

    love.graphics.polygon("line", ax,ay, bx,by, cx,cy)
end

function time (t, dt)
    if t == 1 then
        t = 0
    end
    t = t + dt
    if t >= 1 then
        t = 1
    end
    return t
end

function love.update (dt)
    a = time(a, dt)
    b = time(b, dt)
    c = time(c, dt)
end
