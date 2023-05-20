function love.conf (t)
    t.window.title = "Triangles"
    t.window.icon = nil -- Filepath to an image to use as the window's icon (string)
    t.window.width = 800
    t.window.height = 600
    t.console = true
end

function gold (alpha)
    love.graphics.setColor(1, 0.84, 0, alpha)
end

function white (alpha)
    love.graphics.setColor(1, 1, 1, alpha)
end

function black (alpha)
    love.graphics.setColor(0, 0, 0, alpha)
end

function green (alpha)
    love.graphics.setColor(0, 1, 0, alpha)
end

function red (alpha)
    love.graphics.setColor(1, 0, 0, alpha)
end

function love.keypressed (k)
    if k == 'escape' or k == 'q' then
        love.event.quit()
    end
end

local deg90  = math.pi / 2
local deg60  = math.pi / 3
local deg120 = 2 * deg60
local deg240 = 2 * deg120

local x, y = 400, 300
local r = 100

local degrees = 1
local corners = 1
local max = 36
local time = 0
local step = 0.9

local alpha = 0
local alphadt = 0

function triangles (n)
    local angle = (2 * math.pi) / n

    local coords = {}

    for i = 1,n do
        local ax = x + r * math.cos(i * angle)
        local ay = y + r * math.sin(i * angle)
        love.graphics.line(x,y, ax,ay)
        table.insert(coords, ax)
        table.insert(coords, ay)
    end

    if #coords >= 6 then
        love.graphics.polygon("line", coords)
    end
end

function equilateral (angle)
    local tx,ty = 0, r

    local rx = (tx * math.cos(deg120)) - (ty * math.sin(deg120))
    local ry = (tx * math.sin(deg120)) + (ty * math.cos(deg120))

    local lx = (tx * math.cos(deg240)) - (ty * math.sin(deg240))
    local ly = (tx * math.sin(deg240)) + (ty * math.cos(deg240))

    local coords = { -tx,-ty, -lx,-ly, -rx,-ry }

    love.graphics.push()
    love.graphics.translate(x, y + r)
    love.graphics.rotate(angle)
    love.graphics.polygon("fill", coords)

    love.graphics.pop()
end

local circledt = 0

function circle_draw (alpha)
    local pts = {}

    --  A
    --  |\
    --  | \
    -- C|__\ B


    local deg   = math.rad(-degrees)
    local deg90 = math.rad(-degrees - 90)

    local ax = x + (r * math.cos(deg90))
    local ay = y + (r * math.sin(deg90))
    local bx = x + (r * math.cos(deg))
    local by = y + (r * math.sin(deg))
    local cx,cy = x,y

    for d = degrees + 90, degrees + 360 do
        local rad = math.rad(-d)
        table.insert(pts, cx + (r * math.cos(rad)))
        table.insert(pts, cy + (r * math.sin(rad)))
    end

    red(alpha)
    love.graphics.line(pts)
    green(alpha)
    love.graphics.polygon("line", ax,ay, bx,by, cx,cy)
end

function lerp (from, to, t)
    return (1 - t) * from + t * to;
end

local stepping = true
local stepping_count = 0

function circle_step (dt)
    if not stepping then
        return
    end

    circledt = circledt + (dt / 5)
    if circledt > 1 then
        circledt = 0
    end
    degrees = math.floor(lerp(1, 360, circledt))

    if degrees == 225 then
        stepping_count = stepping_count + 1
        if stepping_count > 4 then
            stepping = false
        end
    end
end

function love.draw ()
    circle_draw(1)
    
    if stepping_count > 1 then
        gold(alpha)
        triangles(corners)

        white(alpha)
        equilateral(0)
    end
end

function love.update (dt)
    circle_step(dt)

    if stepping_count > 1 then
        time = time + dt
        if time > step then
            time = 0
            corners = corners + 1
            if corners > max then
                corners = 1
            end
        end

        alphadt = alphadt + (dt / 5)
        if alphadt > 1 then
            alphadt = 0
        end
        alpha = lerp(0, 1, alphadt)
    end

    --if degrees >= 90 then
    --    degrees = 0
    --else
    --    degrees = degrees + 5*dt
    --end
end
