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

    --if p ~= nil then
    --    for i,t in pairs(Neighbors[p.x][p.y]) do
    --        love.graphics.setColor(1, 0, 0)
    --        love.graphics.rectangle("fill", t.x, t.y, TileSize, TileSize)
    --    end
    --end
end

function lerpColor (from, to, t)
    local r = (1 - t) * from[1] + t * to[1]
    local g = (1 - t) * from[2] + t * to[2]
    local b = (1 - t) * from[3] + t * to[3]
    return { r, g, b }
end

local primecolor = { 1, 1, 1 }
local color_step = 1
local transitions = {
    { 1, 1, 1 },
    { 1, 1, 1 }, -- white
    { 1, 1, 0 }, -- yellow
    { 1, 0, 0 }, -- red
    { 1, 0, 1 }, -- magenta
    { 0, 1, 0 }, -- green
    { 0, 1, 1 }, -- cyan
    { 0, 0, 1 }, -- blue
    { 0, 0, 0 }, -- black
    { 0, 0, 0 }
}

function transition_color (n, t)
    local from = transitions[n]
    local to = transitions[n + 1]
    return lerpColor(from, to, t)
end

function update (dt)
    --if p == nil then return end

    nt = step(nt, dt * 0.5)
    primecolor = transition_color(color_step, nt)

    if nt == 1 then
        color_step = color_step + 1
        if color_step > #transitions - 1 then
            color_step = 1
        end
    end
end

function love.load ()
    init()
end

function love.draw ()
    love.graphics.setColor(unpack(primecolor))
    local width, height = love.graphics.getDimensions()
    love.graphics.rectangle("fill", 0, 0, width, height)
    --draw()
end

function love.mousepressed (x, y, button)
    x, y = toTileCoords(x, y)
    p = Map[x][y]
    nt = 0
end

function love.update (dt)
    update(dt)
end
