local Vector = require("Vector")
local Edge = {}
Edge.__index = Edge

local function is_edge (t)
    return getmetatable(t) == Edge
end

function Edge.new (from, to)
    local t = { 
        from = from,
        to = to,
        -- lists of Packets waiting to be pumped and in transit
        in_wait = {},
        in_transit = {},
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

function Edge:pump (dt)
end

return Edge
