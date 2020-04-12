local Vector = require("Vector")

function love.conf (t)
    t.window.title = "Network Flow"
    t.window.icon = nil -- Filepath to an image to use as the window's icon (string)
    t.window.width = 800
    t.window.height = 600
    t.gammacorrect = true
end

function love.load ()
    --love.window.setPosition(0, 0)

end

local Node = {}
Node.__index = Node

-- 'Project' point into in of the four quadrants and choose a random point
-- within the four
function random_dest (x, y)
    return Vector.new(math.random(0, WIDTH), math.random(0, HEIGHT))
    --local x_min, x_max = 0,0
    --local y_min, y_max = 0,0
    --
    --if x < WIDTH / 2 and y < HEIGHT / 2 then
    --    -- top left
    --    x_min = 0
    --    x_max = WIDTH / 2
    --    y_min = 0
    --    y_max = HEIGHT / 2
    --elseif x > WIDTH / 2 and y < HEIGHT / 2 then
    --    -- top right
    --    x_min = WIDTH / 2
    --    x_max = WIDTH
    --    y_min = 0
    --    y_max = HEIGHT / 2
    --elseif x < WIDTH / 2 and y > HEIGHT / 2 then
    --    -- bottom left
    --    x_min = 0
    --    x_max = WIDTH / 2
    --    y_min = HEIGHT / 2
    --    y_max = HEIGHT
    --else
    --    -- bottom right
    --    x_min = WIDTH / 2
    --    x_max = WIDTH
    --    y_min = HEIGHT / 2
    --    y_max = HEIGHT
    --end

    --return Vector.new(math.random(x_min, x_max), math.random(y_min, y_max))
end

function Node.new (x, y)
    return setmetatable({ 
        orig = Vector.new(x, y),
        pos = Vector.new(x, y),
        dest = random_dest(x, y),
        size = 5
    }, Node)
end

function love.load ()
    Nodes = {}
    WIDTH = 800
    HEIGHT = 600
    STRIDE = 25
    TIME = 0
    STATE = 1
    T = 0

    -- Starting from a negative stride gives a 'bleed' for scrolling
    for x = -STRIDE, WIDTH + STRIDE, STRIDE do
        Nodes[x] = {}
        for y = -STRIDE, HEIGHT + STRIDE, STRIDE do
            Nodes[x][y] = Node.new(x, y)
        end
    end
end

function love.draw ()
    for x, col in pairs(Nodes) do
        for y, n in pairs(col) do
            love.graphics.circle("fill", n.pos.x, n.pos.y, n.size)
        end
    end
end

function love.update (dt)
    --local n = Nodes[25 * 3][25 * 3]
    --n.size = n.size + (5 * dt)
    TIME = TIME + dt

    if STATE == 1 then
        for x, col in pairs(Nodes) do
            for y, n in pairs(col) do
                n.pos = Vector.lerp(n.orig, n.dest, T)
            end
        end
        if T >= 1 then
            STATE = 2
            T = 0
        end
    elseif STATE == 2 then
        for x, col in pairs(Nodes) do
            for y, n in pairs(col) do
                n.pos = Vector.lerp(n.dest, n.orig, T)
            end
        end
        if T >= 1 then
            STATE = 3
            T = 0
        end
    elseif STATE == 3 then
        for x, col in pairs(Nodes) do
            for y, n in pairs(col) do
                n.pos = n.orig
            end
        end
        if T >= 1 then
            STATE = 1
            T = 0
        end
    end

    T = T + dt
    if T > 1 then T = 1 end

    --local x_speed = 25 * math.cos(TIME)
    --local y_speed = 25 * math.sin(TIME)
    local x_speed = 50
    local y_speed = 0
    for x, col in pairs(Nodes) do
        for y, n in pairs(col) do
            n.orig.x = n.orig.x + (x_speed * dt)
            n.orig.y = n.orig.y + (y_speed * dt)
            -- wrap the node back to the otherside
            if n.orig.x < -STRIDE then
                n.orig.x = n.orig.x + WIDTH + (STRIDE*2)
            end
            if n.orig.y < -STRIDE then
                n.orig.y = n.orig.y + HEIGHT + (STRIDE*2)
            end
            if n.orig.x > WIDTH + STRIDE then
                n.orig.x = n.orig.x - WIDTH - (STRIDE*2)
            end
            if n.orig.y > HEIGHT + STRIDE then
                n.orig.y = n.orig.y - HEIGHT - (STRIDE*2)
            end
        end
    end
end
