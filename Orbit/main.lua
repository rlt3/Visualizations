local moonshine = require("moonshine")
local Vector = require("Vector")
local Queue = require("Queue")
local Text = require("Text")

function math.prandom(min, max) return love.math.random() * (max - min) + min end

function love.conf (t)
    t.window.title = "Network Flow"
    t.window.icon = nil -- Filepath to an image to use as the window's icon (string)
    t.window.width = 800
    t.window.height = 600
    t.gammacorrect = true
end

function random_star ()
    local size = math.prandom(2, 3.5)
    local star = {
        x = math.random(1, 800),
        y = math.random(1, 600),
        size = size,
        max = size + 1,
        min = size - 1,
        dir = 1
    }
    return star
end

function love.load ()
    local seed = os.time()
    math.randomseed(seed)
    print(seed)

    Time = 0

    TitleMoveDone = false
    StartFlashDone = false

    -- move the Title and Start up from the bottom to a stopping point
    TitleY = 1000
    TitleYStop = 200
    StartY = 1200
    StartYStop = 400

    -- for handling when to start and stop flashing the 'press start' text
    StartToggleTime = 0
    StartToggleStop = 0
    StartFlashTime = 0
    StartFlashColors = {
        {0, 0, 0},
        {255, 255, 255},
    }
    StartFlashIdx = 1

    -- for keeping track of score
    ScoreTally = 0

    hiscore = Text.new("HISCORE: LEROY 1337", -10, 10, 16, "right")
    title = Text.new("Orbit", 0, TitleY, 112)
    start = Text.new("Press Start", 0, StartY, 36)
    lose = Text.new("You Lose", 0, 225, 112)
    sad = Text.new(":(", 0, 225, 112)

    ShootDir = {
        { x =  1, y =  1 },
        { x = -1, y =  1 },
        { x =  1, y = -1 },
        { x = -1, y = -1 },
    }
    ShootAt = 2.5 -- start shooting at 2.5 seconds
    ShootingStars = {}
    Stars = {}
    for i = 1, 72 do
        table.insert(Stars, random_star())
    end

    scanline_phase = 0
    scanline_freq = 800

    ScreenShader = moonshine(moonshine.effects.dmg)
             .chain(moonshine.effects.chromasep)
             .chain(moonshine.effects.crt)
             .chain(moonshine.effects.scanlines)
    ScreenShader.dmg.palette = 'green'
    ScreenShader.chromasep.angle = 0
    ScreenShader.chromasep.radius = 2
    ScreenShader.scanlines.thickness = 0.25
    ScreenShader.scanlines.phase = scanline_phase
    ScreenShader.scanlines.frequency = scanline_freq
end

function love.draw ()
    ScreenShader(function()
        for i, star in ipairs(Stars) do
            love.graphics.circle("fill", star.x, star.y, star.size)
        end
        for i, star in ipairs(ShootingStars) do
            love.graphics.circle("fill", star.x, star.y, star.size)
        end
        title:draw()
        start:draw()
        hiscore:draw()
        --lose:draw()
        --sad:draw()
    end)
end

function love.update (dt)
    Time = Time + dt

    if not TitleMoveDone then
        local diff = (300 * dt)
        TitleY = TitleY - diff
        StartY = StartY - diff
        if TitleY < TitleYStop then
            TitleY = TitleYStop
            StartY = StartYStop
            TitleMoveDone = true
        end
        title.y = TitleY
        start.y = StartY
        StartToggleTime = Time + 2.5
        StartToggleStop = Time + 5
    elseif not StartFlashDone then
        if Time > StartToggleTime then
            start.text = "→ Press Start ←"
            if Time > StartFlashTime then
                StartFlashTime = Time + 0.10
                start.color = StartFlashColors[StartFlashIdx]
                if StartFlashIdx == 1 then
                    StartFlashIdx = 2
                else
                    StartFlashIdx = 1
                end
            end
        end
        if Time > StartToggleStop then
            StartFlashDone = true
        end
    else
        title.display = false
        start.display = false
        hiscore.text = "SCORE: " .. tostring(ScoreTally)
    end

    scanline_phase = scanline_phase + 0.25
    if math.random(0, 1) > 0 then
        scanline_freq = scanline_freq - 1
    else
        scanline_freq = scanline_freq + 1
    end
    ScreenShader.scanlines.phase = scanline_phase
    ScreenShader.scanlines.frequency = scanline_freq

    for i, star in ipairs(Stars) do
        local diff = star.dir * dt
        if star.size + diff < star.min or star.size + diff > star.max then
            star.dir = -star.dir
        else
            star.size = star.size + diff
        end
    end

    for i, star in ipairs(ShootingStars) do
        local dir = star.dir
        star.x = star.x + (dir.x * (star.speed * dt))
        star.y = star.y + (dir.x * (star.speed * dt))
    end

    if Time > ShootAt then
        ShootAt = ShootAt + 2.5
        local star = random_star()
        star.dir = ShootDir[math.random(1, #ShootDir)]
        star.speed = math.random(75, 125)
        table.insert(ShootingStars, star)
    end

    -- I can just replace some update and draw functions (not the main ones)
    -- with the appropriate one for the scene. I can still fill out the main
    -- ones with the appropriate shaders and background stuff and then change
    -- out the scene functions whenever appropriate.
    --if Time > 8 then
    --    love.update = SecondUpdate
    --end
end
