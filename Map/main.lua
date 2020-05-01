local perlin = require("perlin")

function love.keypressed (key, unicode)
    if key == "escape" or key == "q" then
        love.event.quit()
    end
end

-- Gives a precise random decimal number given a minimum and maximum
function math.prandom (min, max)
    return love.math.random() * (max - min) + min
end

function routine (iter, update)
    return coroutine.create(function ()
        iter(update)
    end)
end

function iter_scan (update)
    for y = 0, Height - 1 do
        for x = 0, Width - 1 do
            update(x, y)
        end
        coroutine.yield()
    end
end

function iter_radius (update)
    local center = { x = 300, y = 300 }

    local in_circle = function (x, y, radius)
        local xc = x - center.x
        local yc = y - center.y
        return ((xc * xc) + (yc * yc)) < (radius * radius)
    end

    local checked = {}
    for x = 0, Width do
        checked[x] = {}
    end

    local check = function (x, y, r)
        if x < 0 or x > Width or y < 0 or y > Height then return end
        if checked[x][y] then return end
        if in_circle(x, y, r) then
            checked[x][y] = true
            update(x, y)
        end
    end

    for r = 1, 600 do
        for x = center.x - r, center.x + r do
            for y = center.y - r, center.y + r do
                check(x, y, r)
            end
        end
        coroutine.yield()
        print(r)
    end
end

function iter_rect (update)
    local center = { x = 300, y = 300 }
    for r = 1, 300 do
        for x = center.x - r, center.x + r do
            update(x, center.y - r)
        end
        for y = center.y - r, center.y + r do
            update(center.x + r, y)
        end
        for x = center.x - r, center.x + r do
            update(x, center.y + r)
        end
        for y = center.y - r, center.y + r do
            update(center.x - r, y)
        end
        coroutine.yield()
    end
end

function shuffle (t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
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
        if i % Width == 0 then
            coroutine.yield()
        end
    end
end

function update_noise (x, y)
    local n = perlin:noise(x*(1/64.0), y*(1/64.0)) * 1.0 +
              perlin:noise(x*(1/32.0), y*(1/32.0)) * 0.5 +
              perlin:noise(x*(1/16.0), y*(1/16.0)) * 0.25 +
              perlin:noise(x*(1/8.0),  y*(1/8.0))  * 0.125
    n = (n * 0.5) + 0.5
    if x < 0 or x > Width or y < 0 or y > Height then
        print(x, y)
    end
    Pixels:setPixel(x, y, n, n, n, 1)
end

function love.load ()
    --love.graphics.setDefaultFilter("nearest", "nearest")

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

    c = routine(iter_radius, update_noise)
    --c = routine(iter_rect, update_noise)
    --c = routine(iter_scan, update_noise)
    --c = routine(iter_random, update_noise)
end

function love.draw ()
    love.graphics.draw(Image)
end

function love.update (dt)
	Time = Time + dt
    if coroutine.status(c) == "dead" then return end
    coroutine.resume(c)
    Image = love.graphics.newImage(Pixels)
end
