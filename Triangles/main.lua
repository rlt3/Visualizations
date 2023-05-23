function love.conf (t)
    t.window.title = "Triangles"
    t.window.icon = nil -- Filepath to an image to use as the window's icon (string)
    t.window.width = 800
    t.window.height = 600
    t.console = true
end

function gold ()
    love.graphics.setColor(1, 0.84, 0)
end

function white (alpha)
    love.graphics.setColor(1, 1, 1, alpha or 1)
end

function black ()
    love.graphics.setColor(0, 0, 0)
end

function green ()
    love.graphics.setColor(0, 1, 0)
end

function red ()
    love.graphics.setColor(1, 0, 0)
end

function pointAtDegree (x, y, r, degree)
    -- negative degrees here because we're in upside-down world
    local deg = math.rad(-degree)
    local px = x + (r * math.cos(deg))
    local py = y + (r * math.sin(deg))
    return px, py
end

function lerp (from, to, t)
    return (1 - t) * from + t * to;
end

local x, y = 400, 300
local r = 200
local step = 1

local equi_degrees = 0
local equi_dt = 0

function equilateral (degree)
    local ax,ay = pointAtDegree(x, y, r, degree)
    local bx,by = pointAtDegree(x, y, r, degree + 120)
    local cx,cy = pointAtDegree(x, y, r, degree + 240)
    love.graphics.polygon("fill", ax,ay, bx,by, cx,cy)
end

function equilateral_update (dt)
    equi_dt = equi_dt + (dt / 8)
    if equi_dt >= 1 then
        step = step + 1
        equi_dt = 0
    else
        equi_degrees = math.floor(lerp(0, 360, equi_dt))
    end
end

function circle ()
    local pts = {}
    for d = 1, 360 do
        local px,py = pointAtDegree(x, y, r, d)
        love.graphics.line(x,y, px,py)
        table.insert(pts, px)
        table.insert(pts, py)
    end
    --love.graphics.polygon("line", pts)
end

function lines (numlines)
    local angle = 360 / numlines
    gold()
    love.graphics.setLineWidth(4)
    for n = 1, numlines do
        local px,py = pointAtDegree(x, y, r, n * angle)
        love.graphics.line(x,y, px,py)
    end
    love.graphics.setLineWidth(1)
end

function shapes (numlines)
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

local slowness = 8

function shapes_update (dt)
    local ending = false

    equi_dt = equi_dt + (dt / slowness)

    if equi_dt >= 1 then
        step = step + 1
        equi_dt = 1
    end

    equi_degrees = math.floor(lerp(1, 360, equi_dt))

    if equi_degrees <= 16 then
        slowness = 256
    elseif equi_degrees <= 32 then
        slowness = 16
    else
        slowness = 8
    end
end

function pyramid_create (dt)
    equi_dt = equi_dt + (dt / 4)
    if equi_dt >= 1 then
        step = step + 1
        equi_dt = 1
    end
    r = math.floor(lerp(200, 100, equi_dt))
end

local pyramid_alpha = 1
local pyramid_dt = 0
local pyramid_negr = 0

function pyramid_beam ()
    white(pyramid_alpha)
    equilateral(90)

    gold()
    love.graphics.push()
    love.graphics.translate(0, -r + pyramid_negr)
    love.graphics.setLineWidth(4)
    shapes(equi_degrees)
    love.graphics.pop()
end

function pyramid_update (dt)
    if step == 4 then
        pyramid_dt = pyramid_dt + dt
        if pyramid_dt >= 1 then
            equi_degrees = equi_degrees + 1
            if equi_degrees > 9 then
                step = step + 1
            end
            pyramid_dt = 0
        end
    else
        pyramid_dt = pyramid_dt + (dt / 8)
        if pyramid_dt >= 1 then
            pyramid_dt = 1
        end
        pyramid_alpha = lerp(1, 0, pyramid_dt)
        equi_degrees = math.floor(lerp(9, 360, pyramid_dt))
        r = math.floor(lerp(100, 200, pyramid_dt))
        pyramid_negr = math.floor(lerp(0, 200, pyramid_dt))
    end
end

function love.draw ()
    if step == 1 then
        lines(360 - equi_degrees)
        black()
        equilateral(equi_degrees)
    elseif step == 2 then
        white()
        equilateral(equi_degrees)
    elseif step == 3 then
        white()
        equilateral(90)
    else
        pyramid_beam()
    end
end

function love.update (dt)
    if step == 1 then
        equilateral_update(dt)
    elseif step == 2 then
        equilateral_update(dt)
        if equi_degrees == 90 then
            step = step + 1
            equi_dt = 0
        end
    elseif step == 3 then
        pyramid_create(dt)
        equi_degrees = 1
    else
        pyramid_update(dt)
    end
end
