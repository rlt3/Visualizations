require("a-star-lua/a-star")
local Queue = require("Queue")
local Edge = require("Edge")

local Node = {}
Node.__index = Node
Node.all_nodes = {}

local function is_node (t)
    return getmetatable(t) == Node
end

-- Allocate a new Node and add it to the global list of Nodes
function Node.new (name, x, y, max_packets)
    local t = { 
        name = name,
        x = x,
        y = y,
        edges = {},
        packets = Queue.new(),
        max_packets = max_packets or 1
    }
    local n = setmetatable(t, Node)
    table.insert(Node.all_nodes, n)
    return n
end

function Node.__eq (lhs, rhs)
    return lhs.pos == rhs.pos
        and lhs.name == rhs.name
        and lhs.edges == rhs.edges
end

function Node:__tostring ()
    return "Node at ("..self.x..", "..self.y..")"
end

function Node:is_neighbor (node)
    return self.edges[node.name] 
end

-- Add the Edge where the "to" Node's name is the lookup key
function Node:add_edge (to)
    self.edges[to.name] = Edge.new(self, to)
end

function Node:path_to (dest)
    local ignore_cached = true
    return astar.path(self, dest, Node.all_nodes, ignore_cached, Node.is_neighbor)
end

-- "Pump" edges to feed in Packets
function Node:pump (dt)
    local num_available = self.max_packets - #self.packets
    local i = 1

    if num_available <= 0 then
        error("Invalid number of packets left for Node " .. self.name)
    end

    -- pump each edge once while Node can receive packets
    for name, edge in ipairs(self.edges) do
        if num_available == 0 then return end
        local packet = edge:pump(dt)
        if packet then
            table.insert(self.packets, packet)
            num_available = num_available - 1
        end
    end
end

function Node:process ()
    while true do
        local packet = self.packets:pop()
        if not packet then return end
    end
end

return Node
