function love.conf (t)
    t.window.title = "Tiles"
    t.window.icon = nil -- Filepath to an image to use as the window's icon (string)
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.system = false
    t.modules.audio = false
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

function lerpDegree (t)
    return math.floor(lerp(0, 360, t))
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

function love.load ()
    --love.window.setMode(1080, 1350)
end

local TileSize = 10
local Map = {}
local Tiles = {}
local Neighbors = {}

local n = 1
local nt = 0
local p = nil

function toTileCoords (x, y)
    return x - math.fmod(x, TileSize), y - math.fmod(y, TileSize)
end

function init ()
    local width, height = love.graphics.getDimensions()
    local wlimit, hlimit = width - TileSize, height - TileSize

    for x = 0, width - 1, TileSize do
        Map[x] = {}
        for y = 0, height - 1, TileSize do
            local t = {
                x = x,
                y = y,
                color = { 0, 0, 0, 0 }
            }
            Map[x][y] = t
            table.insert(Tiles, t)
        end
    end

    for i,t in pairs(Tiles) do
        local x, y = t.x, t.y
        local s = TileSize
        local n = {}

        if x > 0 then
            table.insert(n, Map[x - s][y])
        end

        if x < wlimit then
            table.insert(n, Map[x + s][y])
        end

        if y > 0 then
            table.insert(n, Map[x][y - s])
        end

        if y < hlimit then
            table.insert(n, Map[x][y + s])
        end

        if x > 0 and y > 0 then
            table.insert(n, Map[x - s][y - s])
        end

        if x > 0 and y < hlimit then
            table.insert(n, Map[x - s][y + s])
        end

        if x < wlimit and y > 0 then
            table.insert(n, Map[x + s][y - s])
        end

        if x < wlimit and y < hlimit then
            table.insert(n, Map[x + s][y + s])
        end

        if Neighbors[x] == nil then
            Neighbors[x] = {}
        end
        Neighbors[x][y] = n
    end
end

function draw ()
    for i,t in pairs(Tiles) do
        love.graphics.setColor(unpack(t.color))
        love.graphics.rectangle("fill", t.x, t.y, TileSize, TileSize)

    end

    if p ~= nil then
        for i,t in pairs(Neighbors[p.x][p.y]) do
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle("fill", t.x, t.y, TileSize, TileSize)
        end
    end
end

function update (dt)
    --for i,t in pairs(Tiles) do
    --    for i,n in pairs(Neighbors[t.x][t.y]) do
    --    end
    --end
end

function love.load ()
    init()
end

function love.draw ()
    draw()
end

function love.mousepressed (x, y, button)
    x, y = toTileCoords(x, y)
    p = Map[x][y]
end

function love.update (dt)
    update(dt)
end
