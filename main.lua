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
        speed = speed or math.prandom(0.25, 1.5),
    }
    return setmetatable(t, Packet)
end

function Packet:reset (from, to) self.from = Vector.new(from.x, from.y)
    self.to = Vector.new(to.x, to.y)
    self.pos = self.from
    self.time = 0
end

-- Updates the packet and returns its 'time'. 0 = start, 1 = end
function Packet:update (dt)
    if self.time >= 1 then return self.time end
    -- use a different speed if passed in
    self.time = self.time + dt
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
    if num == 0 then return nil end

    -- rotate through the queue, updating each packet
    local lead_pkt = nil
    while num > 0 do
        local pkt = self.pipeline:pop()
        local pkt_dt = dt * pkt.speed

        -- if this is the lead packet
        if lead_pkt == nil then goto update end

        -- if this packet will overcome the lead packet then set its delta to
        -- be just behind the lead and set its speed to the lead
        if pkt.time + pkt_dt > lead_pkt.time - dt then
            pkt_dt = (lead_pkt.time - dt) - pkt.time
            pkt.speed = lead_pkt.speed
        end

        ::update::
        if pkt:update(pkt_dt) < 1 then
            self.pipeline:push(pkt)
            lead_pkt = pkt
        else
            -- when packet is at the end (t >= 1) then it is not put back onto
            -- the pipeline and the next packet will become the 'lead' packet
            lead_pkt = nil
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
    if T % 2 and math.random(1, 100) < 15 then
        P:send(Packet.new())
    end
end
