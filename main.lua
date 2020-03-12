local Vector = require("Vector")
local Queue = require("Queue")

-- Gives a precise random decimal number given a minimum and maximum
function math.prandom(min, max) return love.math.random() * (max - min) + min end

local Node = {}
Node.__index = Node

function Node.new (name, x, y)
    local t = { 
        name = name,
        x = x,
        y = y,
    }
    return setmetatable(t, Node)
end

function Node:__tostring ()
    return "Node '" .. self.name .."' at (".. self.x .. ", " .. self.y .. ")"
end

function Node:draw ()
    love.graphics.circle("fill", self.x, self.y, 5)
end

local Packet = {}
Packet.__index = Packet

function Packet.new (speed)
    local t = {
        pos = nil,
        from = nil,
        to = nil,
        time = 0,
        speed = speed or math.prandom(1, 3),
    }
    return setmetatable(t, Packet)
end

function Packet:reset (from, to) self.from = Vector.new(from.x, from.y)
    self.to = Vector.new(to.x, to.y)
    self.pos = self.from
    self.time = 0
end

-- Updates the packet and returns its 'time'. 0 = start, 1 = end
function Packet:update (dt, spd)
    if self.time >= 1 then return self.time end
    -- use a different speed if passed in
    local speed = spd or self.speed
    self.time = self.time + (dt * speed)
    self.pos = Vector.lerp(self.from, self.to, self.time)
    return self.time
end

local Pipe = {}
Pipe.__index = Pipe

function Pipe.new (from, to)
    local t = { 
        from = from,
        to = to,
        pipeline = Queue.new(),
    }
    return setmetatable(t, Pipe)
end

function Pipe:__tostring ()
    return "Pipe from " .. self.from.name .." to ".. self.to.name
end

function Pipe:draw ()
    self.pipeline:map(function (pkt)
        love.graphics.rectangle("fill", pkt.pos.x, pkt.pos.y, 10, 10)
    end)
end

-- Input some packet to the pipeline
function Pipe:send (pkt)
    pkt:reset(self.from, self.to)
    self.pipeline:push(pkt)
    -- TODO: Need to add in a wait list for sending if last packet in queue
    -- has a time = 0
end

-- Pump the pipeline. Returns a packet if one is available, otherwise nil
function Pipe:pump (dt)
    local num = self.pipeline:length()
    if num == 0 then return end

    -- rotate through the queue, updating each packet
    local speed = self.pipeline:front().speed
    while num > 0 do
        local pkt = self.pipeline:pop()
        -- use the slowest speed seen thus far to update
        speed = math.min(speed, pkt.speed)
        -- TODO: instead of using the minimal speed seen at this point, we need
        -- to let the faster packets 'catch-up' to the slower ones before
        -- throttling the speed
        if pkt:update(dt, speed) < 1 then
            -- if packet is at the end (> 1) then it vanishes
            self.pipeline:push(pkt)
        end
        num = num - 1
    end
end

function love.load()
    math.randomseed(os.time())

    A = Node.new("a", 25, 300)
    B = Node.new("b", 775, 300)

    P = Pipe.new(A, B)
    
    T = 0
end

function love.draw()
    A:draw()
    B:draw()
    P:draw()
end

function love.update (dt)
    P:pump(dt)
    T = T + 1
    if T % 2 and math.random(1, 100) < 33 then
        P:send(Packet.new())
    end
end
