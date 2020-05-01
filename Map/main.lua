local perlin = require("perlin")

function love.keypressed (key, unicode)
    if key == "escape" or key == "q" then
        love.event.quit()
    end
end

function math.clamp (min, max, v)
    if v < min then return min end
    if v > max then return max end
    return v
end

-- Gives a precise random decimal number given a minimum and maximum
function math.prandom (min, max)
    return math.random() * (max - min) + min
end

function shuffle (t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

function new_routine (iter, update)
    return coroutine.create(function ()
        iter(update)
    end)
end

function iter_scan (update, start, final, step)
    for y = start, final, step do
        for x = 0, Width - 1 do
            update(x, y)
        end
        if y % 2 == 0 then
            coroutine.yield()
        end
    end
end

function iter_scan_up (update)
    iter_scan(update, Height - 1, 0, -1)
end

function iter_scan_down (update)
    iter_scan(update, 0, Height - 1, 1)
end

function iter_radius (update)
    local ctr = { x = 300, y = 300 }

    -- hashmap to speedup checking of already checked pixels
    local visited = {}
    for x = 0, Width do
        visited[x] = {}
    end

    for radius = 1, 450 do
        for degree = 0, 360, 0.05 do
            local angle = math.rad(degree)
            local x = ctr.x + (math.cos(angle) * radius)
            local y = ctr.y + (math.sin(angle) * radius)
            x = math.clamp(0,  Width - 1, math.floor(x))
            y = math.clamp(0, Height - 1, math.floor(y))
            if not visited[x][y] then
                visited[x][y] = true
                update(x, y)
            end
        end
        coroutine.yield()
    end

    visited = nil
end

function iter_rect (update)
    local ctr = { x = 300, y = 300 }
    for r = 0, 300 do
        for x = math.max(ctr.x - r, 0), math.min(ctr.x + r, Width - 1) do
            update(x, math.max(ctr.y - r, 0))
        end
        for y = math.max(ctr.y - r, 0), math.min(ctr.y + r, Height - 1) do
            update(math.min(ctr.x + r, Width - 1), y)
        end
        for x = math.max(ctr.x - r, 0), math.min(ctr.x + r, Width - 1) do
            update(x, math.min(ctr.y + r, Height - 1))
        end
        for y = math.max(ctr.y - r, 0), math.min(ctr.y + r, Height - 1) do
            update(math.max(ctr.x - r, 0), y)
        end
        coroutine.yield()
    end
end

function iter_random (update)
    local pixels = {}
    for y = 0, Height - 1 do
        for x = 0, Width - 1 do
            table.insert(pixels, {x, y})
        end
    end
    shuffle(pixels)
    for i = 1, #pixels do
        update(pixels[i][1], pixels[i][2])
        if i % (Width * 2) == 0 then
            coroutine.yield()
        end
    end
end

function update_noise (x, y)
    local n = perlin:noise(x*F*(1/64.0), y*F*(1/64.0)) * 1.0 +
              perlin:noise(x*F*(1/32.0), y*F*(1/32.0)) * 0.5 +
              perlin:noise(x*F*(1/16.0), y*F*(1/16.0)) * 0.25 +
              perlin:noise(x*F*(1/8.0),  y*F*(1/8.0))  * 0.125
    n = (n * 0.5) + 0.5
    if x < 0 or x > Width - 1 or y < 0 or y > Height - 1 then
        error("Out of Range (" .. x .. ", " .. y .. ")")
    end
    Pixels:setPixel(x, y, n, n, n, 1)
end

function love.load ()
    math.randomseed(os.time())

	Time = 0
	Width = 600
    Height = 600

    Pixels = love.image.newImageData(Width, Height)
    for x = 0, Width - 1 do
        for y = 0, Height - 1 do
            Pixels:setPixel(x, y, 0, 0, 0, 1)
        end
    end
    Image = love.graphics.newImage(Pixels)

    Iterators = { 
        iter_radius,
        iter_scan_down,
        iter_rect,
        iter_scan_up,
        iter_random
    }
    rtn = nil
end

function love.draw ()
    love.graphics.draw(Image)
end

function love.update (dt)
	Time = Time + dt
    if not rtn or coroutine.status(rtn) == "dead" then
        rtn = new_routine(Iterators[math.random(1, #Iterators)], update_noise)
        F = math.prandom(0.10, 0.99)
    end
    local good, err = coroutine.resume(rtn)
    if not good then print(err) end
    Image = love.graphics.newImage(Pixels)
end
