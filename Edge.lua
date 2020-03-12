local Queue = require("Queue")

local Edge = {}
Edge.__index = Edge

local function is_edge (t)
    return getmetatable(t) == Edge
end

function Edge.new (fromNode, toNode)
    local t = { 
        from = fromNode,
        to = toNode,
        in_wait = Queue.new(),
        in_transit = Queue.new(),
    }
    return setmetatable(t, Edge)
end

function Edge.__eq (lhs, rhs)
    return lhs.pos == rhs.pos
        and lhs.name == rhs.name
        and lhs.edges == rhs.edges
end

function Edge:__tostring ()
    return "Edge at ("..self.x..", "..self.y..")"
end

function Edge:draw ()
    self.in_transit:map(function(packet)
        packet:draw()
    end)
end

function Edge:send (packet)
    --packet:set_path(self.from, self.to)
    print(self.from)
    print(self.to)
    self.in_wait:push(packet)
end

function Edge:pump (dt)
    if self.in_transit:length() == 1 then
        if self.in_wait:length() == 0 then return end
        self.in_transit:push(self.in_wait:pop())
    else
        -- if packets have arrived then remove them from being in transit
        while self.in_transit:front().arrived do
            -- TODO: pop this into the arriving Node's queue or somewhere
            self.in_transit:pop()
        end

        -- if packets are in wait and there has been enough time since last pump
        if self.in_wait:length() > 0 and self.in_transit:back().time > dt * 2 then
            self.in_transit:push(self.in_wait:pop())
        end
    end

    self.in_transit:map(function(packet)
        packet:pump(dt)
    end)
end

return Edge
