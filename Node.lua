local Edge = require("Edge")
local Node = {}
Node.__index = Node

local function is_node (t)
    return getmetatable(t) == Node
end

function Node.new (name, x, y, max_packets)
    local t = { 
        name = name,
        x = x,
        y = y,
        edges = {},
        packets = {},
        max_packets = max_packets
    }
    return setmetatable(t, Node)
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
    for k, edge in pairs(self.edges) do
        if edge.to == node then
            return true
        end
    end
    return false
end

-- Add the Edge where the "to" Node's name is the lookup key
function Node:add_edge (from, to)
    self.edges[to.name] = Edge.new(from, to)
end

function Node:update (dt)
    local num_available = self.max_packets - #self.packets
    local i = 1

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

return Node
