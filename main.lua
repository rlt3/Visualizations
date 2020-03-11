require("a-star-lua/a-star")
local vector = require("vector")

-- Holds all Nodes which are defined below
local AllNodes = {
    -- utility function for a* to determine if a neighbor is valid
    is_neighbor = function (node, neighbor) 
        for i = 1, #node.neighbors do
            if node.neighbors[i] == neighbor then
                return true
            end
        end
        return false
    end,
    -- utility function to create a Node, insert it, and then return it
    insert = function (self, name, x, y)
        local n = Node(name, x, y)
        table.insert(self, n)
        return n
    end,
    random = function (self)
        return self[math.random(1, #self)]
    end
}

-- Holds all Packets which are sent between Nodes
local AllPackets = {
    -- utility function to create a Packet, insert it, and then return it
    insert = function(self, start)
        local p = Packet(start)
        table.insert(self, p)
        return p
    end
}

function Node (name, x, y)
    local t = {
        name = name,
        x = x,
        y = y,
        neighbors = {},
        packets = {},
        draw = function (self)
            love.graphics.circle("fill", self.x, self.y, 5)
        end,
        add_neighbors = function (self, others)
            for i = 1, #others do
                if self ~= others[i] then
                    table.insert(self.neighbors, others[i])
                end
            end
        end,
        add_packet = function (self, packet)
            table.insert(self.packets, packet)
        end,
        send_packets = function (self)
        end
  }
  return t
end

function Packet (startNode)
    local t = {
        pos = startNode,
        traveling = false,
        dest = nil, -- holds final destination Node
        path = nil,
        path_index = 1,
        from = nil,
        to = nil,
        time = 0,

        draw = function (self)
            love.graphics.rectangle("fill", self.pos.x, self.pos.y, 10, 10)
        end,

        set_destination = function (self, dest)
            if self.pos == dest then
                return
            end

            local ignore_cached = true
            local p = astar.path(self.pos, dest, AllNodes, ignore_cached, AllNodes.is_neighbor)
            if not p then
                error("No path found...")
            end

            self.traveling = true
            self.path = {}
            self.dest = dest
            for i, node in ipairs(p) do
                table.insert(self.path, vector.new(node.x, node.y))
            end
        end,

        update = function (self, dt)
            -- if there's no path to be traveled, choose a random one
            if self.traveling == false then
                self:set_destination(AllNodes:random())
                return
            end

            -- if we're beginning a path to travel
            if self.from == nil and self.traveling == true then
                self.from = self.path[1]
                self.to = self.path[2]
                self.path_index = 2
                self.time = 0
            end

            -- if we are at the end of a node in a path
            if self.time > 1 then
                self.time = 0
                -- if we are at the end of the path entirely
                if self.path_index + 1 > #self.path then
                    self.from = nil
                    self.to = nil
                    self.traveling = false
                    self.pos = self.dest
                    return
                end
                self.from = self.to
                self.path_index = self.path_index + 1
                self.to = self.path[self.path_index]
            end

            self.time = self.time + dt
            self.pos = vector.lerp(self.from, self.to, self.time)
        end
  }
  return t
end

function create_pythagorean_network ()
    local max = { x = love.graphics.getWidth(), y = love.graphics.getHeight() }
    local center = { x = max.x / 2, y = max.y / 2 }

    -- a scaling factor
    local s = 2.5

    local a = AllNodes:insert("a", center.x + (s * 25), center.y + (s * 55))
    local b = AllNodes:insert("b", center.x - (s * 25), center.y + (s * 55))
    local c = AllNodes:insert("c", center.x + (s * 25), center.y + (s * 5))
    local d = AllNodes:insert("d", center.x - (s * 25), center.y + (s * 5))
    local e = AllNodes:insert("e", center.x + (s * 60), center.y - (s * 10))
    local f = AllNodes:insert("f", center.x + (s *  8), center.y - (s * 30))
    local g = AllNodes:insert("g", center.x - (s * 60), center.y - (s * 25))
    local h = AllNodes:insert("h", center.x + (s * 43), center.y - (s * 45))
    local i = AllNodes:insert("i", center.x - (s * 25), center.y - (s * 60))

    a:add_neighbors({b, c})
    b:add_neighbors({a, d})
    c:add_neighbors({a, d, e, f})
    d:add_neighbors({b, c, f, g})
    e:add_neighbors({c, h})
    f:add_neighbors({c, d, h, i})
    g:add_neighbors({d, i})
    h:add_neighbors({e, f})
    i:add_neighbors({f, g})
end

function love.load ()
    math.randomseed(os.time())
    love.window.setMode(800, 600, { msaa = 16, centered = true })
    create_pythagorean_network()
    for i = 1, 100 do
        AllPackets:insert(AllNodes:random())
    end
end

function love.draw()
    --for i, node in ipairs(AllNodes) do
    --    node:draw()
    --end
    for i, packet in ipairs(AllPackets) do
        packet:draw()
    end
end

function love.update (dt)
    for i, packet in ipairs(AllPackets) do
        packet:update(dt)
    end
end
