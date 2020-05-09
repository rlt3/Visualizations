local Vector = require("Vector")
local Queue = require("Queue")

local System = {}
System.__index = System

function System:activate (startx, starty, angle, kind)
    local a = Vector.new(startx, starty)
    local b = Vector.new(startx, starty)
    self.active:push({ a = a, b = b, angle = angle, kind = kind })
end

function System.new (transition, seed, startx, starty, angle)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local t = setmetatable({
        width = Width,
        height = Height,
        transition = transition,
        canvas = love.graphics.newCanvas(Width, Height),
        active = Queue.new(),
        completed = Queue.new(),
    }, System)
    t:activate(startx, starty, angle, seed)
    return t
end

function System:step (dt)
    for i = 1, self.active:length() do
        local t = self.active:pop()
        local a = t.a
        local b = t.b
        local dist = Vector.distance(a, b)

        if dist >= 40 then
            self.completed:push({a, b})

            --if t.kind == 'f' then
            --    if math.random(0, 1) == 1 then
            --        self:activate(b.x, b.y, t.angle, 'l')
            --    else
            --        self:activate(b.x, b.y, t.angle, 'r')
            --    end
            --elseif t.kind == 'l' then
            --    self:activate(b.x, b.y, t.angle - 90, 'f')
            --elseif t.kind == 'r' then
            --    self:activate(b.x, b.y, t.angle + 90, 'f')
            --end

            --if t.kind == 'x' then
            --    self:activate(b.x, b.y, t.angle, 'x')
            --    self:activate(b.x, b.y, t.angle + 90, 'y')
            --elseif t.kind == 'y' then
            --    self:activate(b.x, b.y, t.angle - 90, 'y')
            --    self:activate(b.x, b.y, t.angle - 180, 'x')
            --end

            --if t.kind == 'A' then
            --    self:activate(b.x, b.y, t.angle, 'C')
            --    self:activate(a.x, a.y, t.angle - 60, 'B')
            --elseif t.kind == 'B' then
            --    self:activate(a.x, a.y, t.angle + 90, 'A')
            --elseif t.kind == 'C' then
            --    self:activate(b.x, b.y, t.angle, 'D')
            --elseif t.kind == 'D' then
            --    self:activate(b.x, b.y, t.angle, 'B')
            --end

            if t.kind == 'bloom' then
                self:activate(a.x, a.y, t.angle + 66,  'petal')
                self:activate(a.x, a.y, t.angle + 122, 'petal')
                self:activate(a.x, a.y, t.angle + 188, 'petal')

                self:activate(b.x, b.y, t.angle + 45,  'stem')
            elseif t.kind == 'stem' then
                self:activate(b.x, b.y, t.angle, 'spread')
            elseif t.kind == 'spread' then
                self:activate(b.x, b.y, t.angle, 'bloom')
            elseif t.kind == 'petal' then
                -- do nothing
            end


            i = i + 1
        else
            local rad = math.rad(t.angle)
            b.x = dt * (b.x + math.cos(rad))
            b.y = dt * (b.y + math.sin(rad))
            self.active:push(t)
        end
    end
end

function System:draw ()
    if self.completed:length() > 0 then
        self.canvas:renderTo(function()
            while self.completed:length() > 0 do
                local t = self.completed:pop()
                love.graphics.line(t[1].x, t[1].y, t[2].x, t[2].y)
            end
        end)
    end
    love.graphics.draw(self.canvas)
    for i = self.active.head, self.active.tail - 1 do
        local t = self.active[i]
        love.graphics.line(t.a.x, t.a.y, t.b.x, t.b.y)
    end
end

return System
