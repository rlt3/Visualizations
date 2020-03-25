local moonshine = require("moonshine")
require("a-star-lua/a-star")
local Vector = require("Vector")
local Queue = require("Queue")

-- Gives a precise random decimal number given a minimum and maximum
function math.prandom(min, max) return love.math.random() * (max - min) + min end

local Network = {}
Network.__index = Network
Network.AllNodes = {}

local Packet = {}
Packet.__index = Packet

local Node = {}
Node.__index = Node

function Node.new (name, x, y, num_packets)
    local t = { 
        name = name,
        x = x,
        y = y,
        pipes_in = {},
        pipes_out = {},
        packets = Queue.new(), -- queue of packets available for doing work
        work = Queue.new(),    -- queue of work (paths) for packets
    }
    for i = 1, num_packets do
        t.packets:push(Packet.new(math.prandom(0.25, 1.5)))
    end
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

-- Add a path for the Node route a packet with when the Node updates
function Node:add_work (path)
    self.work:push(path)
end

function Node:do_work ()
    if self.packets:length() == 0 or self.work:length() == 0 then return end
    local pkt = self.packets:pop()
    local path = self.work:pop()
    pkt:set_path(path)
    self:route(pkt)
end

-- Route a packet to some intermediate destination. If the packet has reached
-- its destination, then add it to the Node's list of available packets
function Node:route (pkt)
    if not pkt.path then
        error("Cannot route packet without path")
    end

    local dest = pkt:get_next_dest()
    -- packet has made it to its destination
    if not dest then
        self.packets:push(pkt)
        return
    end

    local pipe = self.pipes_out[dest.name]
    if not pipe then
        error(self.name .. " does not have pipe out for " .. dest.name)
        return
    end

    pipe:send(pkt)
end

function Node:is_exhausted ()
    return self.work:length() > self.packets:length()
end

function Node:has_max_packets ()
    return self.packets:length() >= 50
end

function Node:has_packets ()
    return self.packets:length() > 0
end

function Node:has_work ()
    return self.work:length() > 0
end

function Node:update (dt)
    local hold_pipe = self:has_max_packets()
    self:receive_packets(dt, hold_pipe)

    --if hold_pipe and self:has_work() then
    --    print(self.name .. " has " .. self.packets:length() .. " and " .. self.work:length() .. " work")
    --end

    if self:has_packets() and self:has_work() then
        self:do_work()
    end
end

-- Receive packets from the input pipes and then attempt to route those packets
function Node:receive_packets (dt, hold_pipe)
    local received = {}
    for k, pipe in pairs(self.pipes_in) do
        local finished = pipe:pump(dt, hold_pipe)
        for i, pkt in ipairs(finished) do
            table.insert(received, pkt)
        end
    end

    for i, pkt in ipairs(received) do
        if self ~= pkt.next_dest then
            error("Poorly routed packet! Expected to be at node " .. pkt.next_dest.name .. " but instead at node " .. self.name)
        end
        self:route(pkt)
    end
end

function Packet.new (speed)
    local t = {
        pos = nil,
        from = nil,
        to = nil,
        time = 0,
        speed = speed,
        path = nil,
        path_index = 1,
        next_dest = nil
    }
    return setmetatable(t, Packet)
end

function Packet:reset ()
    self.path = nil
    self.path_index = 1
    self.next_dest = nil
    self.pos = nil
    self.from = nil
    self.time = 0
end

function Packet:set_path (path)
    self.path = path
    self.path_index = 1
    self.next_dest = nil
end

-- Get the next destination for the packet. If there's no next destination then
-- the packet is at the end of its route and this returns nil. Otherwise it
-- returns a Node
function Packet:get_next_dest ()
    if self.path_index + 1 > #self.path then
        self:reset()
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

-- Pump the pipeline. Returns a list of packets that have passed through or
-- finished the pipe. The `hold_pipe` evaluates to True then pump will not
-- return any packets and will instead hold 'finished' packets inside the pipe
-- but update all other packets.
function Pipe:pump (dt, hold_pipe)
    local finished = {}
    local num = self.pipeline:length()
    if num == 0 then return finished end

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
        if pkt:update(pkt_dt) < 1 or (hold_pipe and pkt.time >= 1) then
            self.pipeline:push(pkt)
            lead_pkt = pkt
        else
            -- when packet is at the end (t >= 1) then it is not put back onto
            -- the pipeline and the next packet will become the 'lead' packet
            lead_pkt = nil
            table.insert(finished, pkt)
        end
        ::continue::
        num = num - 1
    end

    return finished
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

function Network.random_node ()
    return Network.AllNodes[math.random(1, #Network.AllNodes)]
end

function Network.is_neighbor (node, other)
    return node.pipes_out[other.name] ~= nil
end

function Network.get_path (m, n)
    local path = astar.path(m, n, Network.AllNodes, true, Network.is_neighbor)
    if not path then
        error("No path from " .. m.name .. " to " .. n.name)
    end
    return path
end

-- Add work for the Network to do
function Network.add_work (m, n)
    local path = Network.get_path(m, n)
    m:add_work(path)
end

-- Add more packets into the network
function Network.add_packet (m, n)
    local path = Network.get_path(m, n)
    local pkt = Packet.new(math.prandom(0.25, 1.5))
    pkt:set_path(path)
    m:route(pkt)
end

function Network.two_random_nodes ()
    local a = Network.random_node()
    local b = Network.random_node()
    while not a == b and not a:is_exhausted() do
        a = Network.random_node()
    end
    return a, b
end

function love.conf (t)
    t.window.title = "Network Flow"
    t.window.icon = nil -- Filepath to an image to use as the window's icon (string)
    t.window.width = 800
    t.window.height = 600
    t.gammacorrect = true
end

function love.load ()
    effect = moonshine(moonshine.effects.glow)
    effect.glow.strength = 5

    math.randomseed(os.time())

    love.window.setPosition(0, 0)

    local max = { x = love.graphics.getWidth(), y = love.graphics.getHeight() }
    local center = { x = max.x / 2, y = max.y / 2 }
    local s = 3.5 -- a scaling factor

    local a = Node.new("a", center.x + (s * 25), center.y + (s * 55), 10)
    local b = Node.new("b", center.x - (s * 25), center.y + (s * 55), 10)
    local c = Node.new("c", center.x + (s * 25), center.y + (s * 5),  10)
    local d = Node.new("d", center.x - (s * 25), center.y + (s * 5),  10)
    local e = Node.new("e", center.x + (s * 60), center.y - (s * 10), 10)
    local f = Node.new("f", center.x + (s *  8), center.y - (s * 30), 10)
    local g = Node.new("g", center.x - (s * 60), center.y - (s * 25), 10)
    local h = Node.new("h", center.x + (s * 43), center.y - (s * 45), 10)
    local i = Node.new("i", center.x - (s * 25), center.y - (s * 60), 10)

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
    Pwork = 50
    Ppacket = 1
    DIR = 1
end

function love.draw ()
    effect(function()
        Network.draw()
    end)
end

function love.update (dt)
    T = T + 1

    for i, node in ipairs(Network.AllNodes) do
        node:update(dt)
    end

    if T % 5 then
        -- Route existing packets
        if Pwork >= math.random(1, 100) then
            Network.add_work(Network.two_random_nodes())
        end
        -- But also gradually add more and more packets into system over time
        if Ppacket >= math.random(1, 100) then
            Network.add_packet(Network.two_random_nodes())
            if DIR == 1 and Ppacket < 100  then Ppacket = Ppacket + 1; end
            --if DIR == 1 and Ppacket == 100 then DIR = 0;   end
            --if DIR == 0 and Ppacket > 1    then Ppacket = Ppacket - 1; end
        end
    end
end
