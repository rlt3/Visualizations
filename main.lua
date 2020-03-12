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
        speed = speed,
    }
    return setmetatable(t, Packet)
end

-- Expects 'from' and 'to' to both be Vectors
function Packet:reset (from, to)
    self.from = from
    self.to = to
    self.pos = self.from
    self.time = 0
end

-- Updates the packet and returns it's new 'time'. Packets are updated on a
-- function of time from [0,1] where 0 is 'from' and 1 is 'to'
function Packet:update (dt)
    if self.time >= 1 then return self.time end
    self.time = self.time + dt
    self.pos = Vector.lerp(self.from, self.to, self.time)
    return self.time
end

local Pipe = {}
Pipe.__index = Pipe

function Pipe.new (from, to)
    local t = { 
        from = Vector.new(from.x, from.y),
        to = Vector.new(to.x, to.y),
        pipeline = Queue.new(),
    }
    t.angle = Vector.angle(t.from, t.to)
    return setmetatable(t, Pipe)
end

function Pipe:__tostring ()
    return "Pipe from " .. self.from.name .." to ".. self.to.name
end

function Pipe:draw ()
    self.pipeline:map(function (pkt)
        love.graphics.push()
        love.graphics.translate(pkt.pos.x, pkt.pos.y)
        love.graphics.rotate(self.angle)
        love.graphics.rectangle("fill", -5, -5, 10, 10)
        love.graphics.pop()
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

    local available = nil
    local num_fin = 0

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
            available = pkt
            num_fin = num_fin + 1
        end
        num = num - 1
    end

    -- A sanity check for the Queue and ordering. Should always be 1 at max
    if num_fin > 1 then error("Dropped " .. num_fin - 1 .. " packets!") end

    return available
end

function love.load()
    math.randomseed(os.time())

    A = Node.new("a", 25, 300)
    B = Node.new("b", 775, 300)

    C = Node.new("c", 25, 575)
    D = Node.new("d", 775, 25)

    Pab = Pipe.new(A, B)
    Pcd = Pipe.new(C, D)
    T = 0
end

function love.draw()
    A:draw()
    B:draw()
    C:draw()
    D:draw()

    Pab:draw()
    Pcd:draw()
end

function love.update (dt)
    Pab:pump(dt)
    Pcd:pump(dt)

    T = T + 1
    if T % 2 then
        local r = math.random(1, 100)
        if r < 15 then
            Pab:send(Packet.new(math.prandom(0.25, 1.5)))
        elseif r > 15 and r < 31 then
            Pcd:send(Packet.new(math.prandom(0.25, 1.5)))
        end
    end
end
