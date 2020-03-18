require("a-star-lua/a-star")
local Vector = require("Vector")
local Queue = require("Queue")

-- Gives a precise random decimal number given a minimum and maximum
function math.prandom(min, max) return love.math.random() * (max - min) + min end

local Network = {}
Network.__index = Network
Network.AllNodes = {}

local Node = {}
Node.__index = Node

function Node.new (name, x, y)
    local t = { 
        name = name,
        x = x,
        y = y,
        pipes_in = {},
        pipes_out = {},
    }
    t = setmetatable(t, Node)
    table.insert(Network.AllNodes, t)
    return t
end

function Node:__tostring ()
    return "Node '" .. self.name .."' at (".. self.x .. ", " .. self.y .. ")"
end

function Node:draw ()
    for k, pipe in pairs(self.pipes_in) do
        pipe:draw()
    end
    --love.graphics.circle("fill", self.x, self.y, 8)
end

function Node:add_pipe_in (pipe)
    self.pipes_in[pipe.from.name] = pipe
end

function Node:add_pipe_out (pipe)
    self.pipes_out[pipe.to.name] = pipe
end

-- Route a received packet to some intermediate destination
function Node:route (pkt)
    if not pkt.path then
        error("Cannot route packet without path")
    end

    local dest = pkt:get_next_dest()
    -- packet has made it to its destination
    if not dest then
        -- TODO: maybe reset the packet at this point and acquire it
        return
    end

    local pipe = self.pipes_out[dest.name]
    if not pipe then
        error(self.name .. " does not have pipe out for " .. dest.name)
        return
    end

    pipe:send(pkt)
end

function Node:pump (dt)
    local received = {}
    for k, pipe in pairs(self.pipes_in) do
        table.insert(received, pipe:pump(dt))
    end

    for i, pkt in ipairs(received) do
        if self ~= pkt.next_dest then
            error("Poorly routed packet! Expected to be at node " .. pkt.next_dest.name .. " but instead at node " .. self.name)
        end
        self:route(pkt)
    end
end

local Packet = {}
Packet.__index = Packet

function Packet.new (speed, path)
    local t = {
        pos = nil,
        from = nil,
        to = nil,
        time = 0,
        speed = speed,
        path = path,
        path_index = 1,
        next_dest = nil
    }
    return setmetatable(t, Packet)
end

-- Get the next destination for the packet. If there's no next destination then
-- the packet is at the end of its route and this returns nil. Otherwise it
-- returns a Node
function Packet:get_next_dest ()
    if self.path_index + 1 > #self.path then
        self.path = nil
        self.path_index = 1
        self.next_dest = nil
        return nil
    end
    self.path_index = self.path_index + 1
    self.next_dest = self.path[self.path_index]
    return self.next_dest
end

-- Sets the position and time from the 'from' and 'to' parameters which are
-- expected to be Vectors
function Packet:set_position (from, to)
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

function Pipe:can_accept ()
    if self.pipeline:length() == 0 then return true end
    return self.pipeline:back().time > 0
end

-- Input some packet to the pipeline
function Pipe:send (pkt)
    -- TODO: Need to add in a wait list for sending if last packet in queue
    -- has a time = 0
    --if not self:can_accept() then return end
    pkt:set_position(self.from, self.to)
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
    if num_fin > 1 then error("Dropped " .. num_fin - 1 .. " packets!") end

    return available
end

local Edge = {}
Edge.__index = Edge

-- Creates two pipes, one for each direction from A to B and B to A, and then
-- adds those pipes as 'in' and 'out' for each node respectively
function Edge.new (A, B)
    local p1 = Pipe.new(A, B)
    local p2 = Pipe.new(B, A)
    A:add_pipe_out(p1)
    A:add_pipe_in(p2)
    B:add_pipe_out(p2)
    B:add_pipe_in(p1)
end

function Network.draw ()
    for i, node in ipairs(Network.AllNodes) do
        node:draw()
    end
end

function Network.is_neighbor (node, other)
    return node.pipes_out[other.name] ~= nil
end

-- Send a packet from Node m to Node n
function Network.send (m, n)
    local path = astar.path(m, n, Network.AllNodes, true, Network.is_neighbor)
    if not path then
        error("No path from " .. m.name .. " to " .. n.name)
    end
    m:route(Packet.new(math.prandom(0.25, 1.5), path))
end

function love.conf (t)
    t.window.title = "Network Flow"
    t.window.icon = nil -- Filepath to an image to use as the window's icon (string)
    t.window.width = 800
    t.window.height = 600
    t.gammacorrect = true
end

function love.load ()
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

function love.draw ()
    Network.draw()
end

function love.update (dt)
    T = T + 1

    for i, node in ipairs(Network.AllNodes) do
        node:pump(dt)
    end

    if T % 5 then
        local m = math.random(1, #Network.AllNodes)
        local n = m
        while n == m do
            n = math.random(1, #Network.AllNodes)
        end
        local a = Network.AllNodes[m]
        local b = Network.AllNodes[n]
        Network.send(a, b)
    end
end
