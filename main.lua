require("a-star-lua/a-star")
local Vector = require("Vector")
local Node = require("Node")
local Edge = require("Edge")
local Packet = require("Packet")

-- Gives a precise random decimal number given a minimum and maximum
function math.prandom(min, max) return love.math.random() * (max - min) + min end

function love.load()
end

function love.draw()
    love.graphics.circle("fill", 300, 300, 5)
end

function love.update (dt)
end
