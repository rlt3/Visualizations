local Vector = require("Vector")
local Queue = require("Queue")
local Stack = require("Stack")

local System = {}
System.__index = System

function System.new (transition, seed, startx, starty, angle)
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local start = Vector.new(startx, starty)
    local t = setmetatable({
        width = Width,
        height = Height,
        canvas = love.graphics.newCanvas(Width, Height),
        transition = transition,
        startpos = start,
        startangle = angle,
        pos = start:copy(),
        angle = angle,
        active = nil,
        stack = Stack.new(),
        statei = 1,
        states = seed,
    }, System)
    return t
end

--
-- The system keeps a list of active and completed drawable objects. Active
-- objects are drawn over time. When it has reached its length, it is put into
-- the completed list. When there are no active objects then the completed list
-- is processed as when doing a state transition on a string. These transitions
-- create new active objects and the process starts again
--
function System:update (dt)
    local length = 5
    local speed = 200

    while self.active == nil do
        if not self:step() then
            self:transform()
        end
    end

    local a = self.active.a
    local b = self.active.b
    local dist = Vector.distance(a, b)
    local state = self.active.state

    if dist < length then
        local rad = math.rad(self.active.angle)
        local xdir = math.cos(rad)
        local ydir = math.sin(rad)
        local b2 = Vector.new(b.x + (xdir * speed * dt),
                              b.y + (ydir * speed * dt))
        --if Vector.distance(a, b2) > length then
        --    b.x = b.x + (xdir * length)
        --    b.y = b.y + (ydir * length)
        --    dist = length + 1
        --else
            b.x = b2.x
            b.y = b2.y
        --end
    end

    if dist > length then
        self.pos = b
        self.angle = self.active.angle
        self.canvas:renderTo(function()
            love.graphics.line(a.x, a.y, b.x, b.y)
        end)
        self.active = nil
    end
end

function System:activate ()
    self.active = {
        a = self.pos:copy(),
        b = self.pos:copy(),
        angle = self.angle
    }
end

-- step over each state in the state list
function System:step ()
    while self.statei < #self.states do
        local c = self.states:sub(self.statei, self.statei)
        self.statei = self.statei + 1
        if c == "F" then
            self:activate()
            return true
        elseif c == "X" then
            -- do nothing
        elseif c == "[" then
            self.stack:push(self.angle)
            self.stack:push(self.pos)
        elseif c == "]" then
            self.pos = self.stack:pop()
            self.angle = self.stack:pop()
        elseif c == "-" then
            self.angle = self.angle + 25
        elseif c == "+" then
            self.angle = self.angle - 25
        end
    end
    return false
end

-- transform the current state to the next one
function System:transform ()
    local gen = ""
    for c in self.states:gmatch"." do
        local s = self.transition[c]
        if not s then
            error("No transition found for state `" .. c .. "'")
        end
        gen = gen .. s
    end
    self.statei = 1
    self.states = gen
    self.active = nil
    --self.angle = self.startangle
    --self.pos = self.startpos:copy()
    self.stack = Stack.new()
end

function System:draw ()
    love.graphics.draw(self.canvas)
    local t = self.active
    if t then
        love.graphics.line(t.a.x, t.a.y, t.b.x, t.b.y)
    end
end

return System
