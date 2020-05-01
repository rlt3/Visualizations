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

function new_routine (iter, update)
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
    local ctr = { x = 300, y = 300 }

    local in_circle = function (x, y, radius)
        local xc = x - ctr.x
        local yc = y - ctr.y
        return ((xc * xc) + (yc * yc)) < (radius * radius)
    end

    -- hashmap to speedup checking of already checked pixels
    local checked = {}
    for x = 0, Width do
        checked[x] = {}
    end

    local check = function (x, y, r)
        if checked[x][y] then return end
        if in_circle(x, y, r) then
            checked[x][y] = true
            update(x, y)
        end
    end

    -- repeatedly walks through a subset of the pixel space for every radius
    -- enlargement to see if the pixels are inside the circle. if they are then
    -- they are placed inside the 'checked' table
    for r = 1, 450 do
        -- Can speed this up by not iterating over all pixels again but only
        -- a subset, e.g. a hollowed out rectangle
        for x = math.max(0, ctr.x - r), math.min(Width - 1, ctr.x + r) do
            for y = math.max(0, ctr.y - r), math.min(Height - 1, ctr.y + r) do
                check(x, y, r)
            end
        end
        coroutine.yield()
    end
end

function iter_rect (update)
    local ctr = { x = 300, y = 300 }
    for r = 1, 300 do
        for x = ctr.x - r, ctr.x + r do
            update(x, ctr.y - r)
        end
        for y = ctr.y - r, ctr.y + r do
            update(ctr.x + r, y)
        end
        for x = ctr.x - r, ctr.x + r do
            update(x, ctr.y + r)
        end
        for y = ctr.y - r, ctr.y + r do
            update(ctr.x - r, y)
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

    Iterators = { iter_radius, iter_rect, iter_scan, iter_random }
    rtn = nil
end

function love.draw ()
    love.graphics.draw(Image)
end

function love.update (dt)
	Time = Time + dt
    if not rtn or coroutine.status(rtn) == "dead" then
        rtn = new_routine(Iterators[math.random(1, #Iterators)], update_noise)
    end
    coroutine.resume(rtn)
    Image = love.graphics.newImage(Pixels)
end
