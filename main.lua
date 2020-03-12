local Node = require("Node")
local Edge = require("Edge")
local Packet = require("Packet")

local EDGE = nil

function love.load()
    local a = Node.new("a", 300, 300, 5)
    local b = Node.new("b", 400, 300, 5)
    EDGE = Edge.new(a, b)
    local p = Packet.new()
    EDGE:send(p)
end

function love.draw()
    EDGE:draw()
end

function love.update (dt)
    EDGE:pump(dt)
end
