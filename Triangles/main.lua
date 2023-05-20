function love.conf (t)
    t.window.title = "Triangles"
    t.window.icon = nil -- Filepath to an image to use as the window's icon (string)
    t.window.width = 800
    t.window.height = 600
end

function gold ()
    love.graphics.setColor(1, 0.84, 0)
end

function white ()
    love.graphics.setColor(1, 1, 1)
end

function black ()
    love.graphics.setColor(0, 0, 0)
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

local degrees = 0
local corners = 1
local max = 36
local time = 0
local step = 0.9

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

function love.draw ()
    gold()
    triangles(corners)

    white()
    equilateral(math.rad(-degrees))
end

function love.update (dt)
    time = time + dt
    if time > step then
        time = 0
        corners = corners + 1
        if corners > max then
            corners = 1
        end
    end

    --if degrees >= 90 then
    --    degrees = 0
    --else
    --    degrees = degrees + 5*dt
    --end
end
