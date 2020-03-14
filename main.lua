local Vector = require("Vector")
local Queue = require("Queue")

-- Gives a precise random decimal number given a minimum and maximum
function math.prandom(min, max) return love.math.random() * (max - min) + min end

local Network = {}
Network.__index = Network
Network.AllNodes = {}

function Network.draw ()
    for i, node in ipairs(Network.AllNodes) do
        node:draw()
    end
end

local Node = {}
Node.__index = Node

function Node.new (name, x, y)
    local t = { 
        name = name,
        x = x,
        y = y,
        pipes = {},
    }
    t = setmetatable(t, Node)
    table.insert(Network.AllNodes, t)
    return t
end

function Node:__tostring ()
    return "Node '" .. self.name .."' at (".. self.x .. ", " .. self.y .. ")"
end

function Node:draw ()
    --love.graphics.circle("fill", self.x, self.y, 8)
    for k, pipe in pairs(self.pipes) do
        pipe:draw()
    end
end

function Node:add_pipe (pipe)
    self.pipes[pipe.to.name] = pipe
end

function Node:send (pkt)
    for k, pipe in pairs(self.pipes) do
        pipe:send(pkt:clone())
    end
end

function Node:pump (dt)
    for k, pipe in pairs(self.pipes) do
        pipe:pump(dt)
    end
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

function Packet:clone ()
    return Packet.new(self.speed)
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
    t.from.name = from.name
    t.to.name = to.name
    return setmetatable(t, Pipe)
end

function Pipe:__tostring ()
    return "Pipe from " .. self.from.name .." to ".. self.to.name
end

function Pipe.draw_packet (pkt, angle)
    local s = 4 -- simple scaling factor
    love.graphics.push()
    love.graphics.translate(pkt.pos.x, pkt.pos.y)
    love.graphics.rotate(angle)
    love.graphics.polygon("fill", 0,-1,  1*s,-1,  1*s,-2*s,  0,-2*s)
    love.graphics.pop()
end

function Pipe:draw ()
    self.pipeline:map(function (pkt)
        Pipe.draw_packet(pkt, self.angle)
    end)
end

-- Input some packet to the pipeline
function Pipe:send (pkt)
    -- TODO: Need to add in a wait list for sending if last packet in queue
    -- has a time = 0
    pkt:reset(self.from, self.to)
    self.pipeline:push(pkt)
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
    --if num_fin > 1 then error("Dropped " .. num_fin - 1 .. " packets!") end

    return available
end

local Edge = {}
Edge.__index = Edge

-- Doesn't have to be its own object, rather it can simply be a function which
-- inserts each 'side' of an pipe (A to B and B to A) into their respective
-- Nodes. This way the logic of 'receive' and 'send' make sense referentially.
function Edge.new (A, B)
    A:add_pipe(Pipe.new(A, B))
    B:add_pipe(Pipe.new(B, A))
end

function love.load()
    math.randomseed(os.time())

    local max = { x = love.graphics.getWidth(), y = love.graphics.getHeight() }
    local center = { x = max.x / 2, y = max.y / 2 }
    local s = 3.5 -- a scaling factor

    local a = Node.new("a", center.x + (s * 25), center.y + (s * 55))
    local b = Node.new("b", center.x - (s * 25), center.y + (s * 55))
    local c = Node.new("c", center.x + (s * 25), center.y + (s * 5))
    local d = Node.new("d", center.x - (s * 25), center.y + (s * 5))
    local e = Node.new("e", center.x + (s * 60), center.y - (s * 10))
    local f = Node.new("f", center.x + (s *  8), center.y - (s * 30))
    local g = Node.new("g", center.x - (s * 60), center.y - (s * 25))
    local h = Node.new("h", center.x + (s * 43), center.y - (s * 45))
    local i = Node.new("i", center.x - (s * 25), center.y - (s * 60))

    Edge.new(a, b)
    Edge.new(a, c)
    Edge.new(b, d)
    Edge.new(c, d)
    Edge.new(d, f)
    Edge.new(d, g)
    Edge.new(e, c)
    Edge.new(e, h)
    Edge.new(f, c)
    Edge.new(f, h)
    Edge.new(f, i)
    Edge.new(g, i)

    T = 0
end

function love.draw()
    Network.draw()
end

function love.update (dt)
    T = T + 1

    for i, node in ipairs(Network.AllNodes) do
        node:pump(dt)
    end

    if T % 2 then
        local r = math.random(1, 100)
        if r < 50 then
            local i = math.random(1, #Network.AllNodes)
            Network.AllNodes[i]:send(Packet.new(math.prandom(0.25, 1.5)))
        end
    end
end
