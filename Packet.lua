local Vector = require("Vector")

local Packet = {}
Packet.__index = Packet

local function is_packet (t)
    return getmetatable(t) == Packet
end

function Packet.new ()
    local t = { 
        pos = nil,
        from = nil,
        to = nil,
        path = nil,
        path_index = 1,
        time = 0,
        arrived = false,
    }
    return setmetatable(t, Packet)
end

function Packet:draw ()
    love.graphics.rectangle("fill", self.pos.x, self.pos.y, 10, 10)
end

function Packet:set_path (from, dest)
    if self.path ~= nil then
        error("A path already exists for the current Packet")
    end

    local p = from:path_to(dest)
    if not p then
        error("No path found from " .. from.name .. " to " .. dest.name)
    end

    -- must rebuild path using Vectors for the lerp function below
    self.path = {}
    for i, node in ipairs(p) do
        table.insert(self.path, Vector.new(node.x, node.y))
    end

    self.arrived = false
    self.from = self.path[1]
    self.to = self.path[2]
    self.path_index = 2
    self.time = 0
    self.pos = self.from
end

function Packet:pump (dt)
    if arrived then return end

    self.time = self.time + dt
    self.pos = Vector.lerp(self.from, self.to, self.time)

    -- if we are at the end of a node in a path
    if self.time > 1 then
        self.time = 0
        if self.path_index + 1 > #self.path then
            -- if we are at the end of the path entirely
            self.from = nil
            self.to = nil
            self.arrived = true
        else
            -- else we simply need to change to the new edge
            self.from = self.to
            self.path_index = self.path_index + 1
            self.to = self.path[self.path_index]
        end
    end
end

return Packet
