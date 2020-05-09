local Vector = require("Vector")
local Queue = require("Queue")

local System = {}
System.__index = System

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
    t:activate(Vector.new(startx, starty), angle, seed)
    return t
end

function System:activate (start, angle, state)
    local a = start:copy()
    local b = start:copy()
    self.active:push({ a = a, b = b, angle = angle, state = state })
end

function System:complete (obj)
    self.completed:push(obj)
end

--
-- The system keeps a list of active and completed drawable objects. Active
-- objects are drawn over time. When it has reached its length, it is put into
-- the completed list. When there are no active objects then the completed list
-- is processed as when doing a state transition on a string. These transitions
-- create new active objects and the process starts again
--
function System:update (dt)
    local size = 50
    local speed = 100

    if self.active:length() == 0 then
        self:step()
    end

    for i = 1, self.active:length() do
        local t = self.active:pop()
        local a = t.a
        local b = t.b
        local dist = Vector.distance(a, b)

        if dist >= size then
            self:complete(t)
            i = i + 1
        else
            local rad = math.rad(t.angle)
            b.x = b.x + (math.cos(rad) * speed * dt)
            b.y = b.y + (math.sin(rad) * speed * dt)
            self.active:push(t)
        end
    end
end

function System:step (dt)
    self.canvas:renderTo(function()
        while self.completed:length() > 0 do
            local t = self.completed:pop()
            local states = self.transition[t.state]

            if not states then
                error("No transition found for state `" .. t.state .. "'")
            end

            for c in states:gmatch"." do
                if c == "0" then
                    self:activate(t.b, t.angle, c)
                elseif c == "1" then
                    --self:activate(t.b, t.angle, c)
                elseif c == "[" then
                    t.angle = t.angle - 45
                elseif c == "]" then
                    t.angle = t.angle + 90
                end
            end

            love.graphics.line(t.a.x, t.a.y, t.b.x, t.b.y)
        end
    end)
end

function System:draw ()
    love.graphics.draw(self.canvas)
    for i = self.active.head, self.active.tail - 1 do
        local t = self.active[i]
        love.graphics.line(t.a.x, t.a.y, t.b.x, t.b.y)
    end
end

return System
