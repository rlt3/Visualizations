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

function love.draw ()
    local size = 25
    for x = 0, 800, size do
        for y = 0, 600, size do
            love.graphics.circle("fill", x, y, 5)
        end
    end
end

function love.update (dt)
end
