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

function System:step ()
    for i = 1, self.active:length() do
        local t = self.active:pop()
        local a = t.a
        local b = t.b
        local dist = Vector.distance(a, b)

        if dist >= 10 then
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

            if t.kind == '0' then
                self:activate(b.x, b.y, t.angle, '1')
            elseif t.kind == '1' then
                self:activate(b.x, b.y, t.angle, '2')
            elseif t.kind == '2' then
                self:activate(b.x, b.y, t.angle - 45, '0')
                self:activate(b.x, b.y, t.angle + 45, '0')
            end

            i = i + 1
        else
            local rad = math.rad(t.angle)
            b.x = b.x + math.cos(rad)
            b.y = b.y + math.sin(rad)
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
    for i = 1, self.active:length() do
        local t = self.active:pop()
        love.graphics.line(t.a.x, t.a.y, t.b.x, t.b.y)
        self.active:push(t)
    end
end

return System
