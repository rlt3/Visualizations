local Vector = require("Vector")
local Queue = require("Queue")
local Stack = require("Stack")

local System = {}
System.__index = System

function str2queue (str)
    local Q = Queue.new()
    for c in str:gmatch"." do
        Q:push(c)
    end
    return Q
end

function System.new (initial, transition, dispatch)
    local t = setmetatable({
        canvas = love.graphics.newCanvas(Width, Height),

        transition = transition,
        dispatch = dispatch,

        startpos = initial.position,
        startangle = initial.angle,
        pos = initial.position:copy(),
        angle = initial.angle,
        seed = initial.state,

        stack = Stack.new(),
        states = str2queue(initial.state),
        active = nil,
    }, System)
    return t
end

-- Activates a new 'line' to be drawn over time with the current position and
-- angle as values for it.
function System:activate ()
    self.active = {
        a = self.pos:copy(),
        b = self.pos:copy(),
        angle = self.angle
    }
end

-- Returns whether the system is done with this current state queue.
function System:done ()
    return (self.active == nil and self.states:length() == 0)
end

-- Update the currently activated 'line'. If there's no active line then
-- process the state queue until one is found. If one isn't found, then return.
function System:update (dt)
    local length = 2.5
    local speed = 500

    if self:done() then
        return
    end

    if self.active == nil and not self:process() then
        return
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
        if Vector.distance(a, b2) > length then
            b.x = b.x + (xdir * length)
            b.y = b.y + (ydir * length)
            dist = length + 1
        else
            b.x = b2.x
            b.y = b2.y
        end
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

System.state = {}

function System.state.draw (sys)
    sys:activate()
    return true
end

function System.state.push (sys)
    sys.stack:push(sys.angle)
    sys.stack:push(sys.pos)
end

function System.state.pop (sys)
    sys.pos = sys.stack:pop()
    sys.angle = sys.stack:pop()
end

function System.state.angle (sys, val)
    sys.angle = sys.angle + val
end

-- Process each state in the state queue via the dispatch table. The dispatch
-- table's values should either be a function or a table with two values, a
-- function and a value passed into that function. Those functions must be the
-- above function.
function System:process ()
    while self.states:length() > 0 do
        local c = self.states:pop()
        local d = self.dispatch[c]

        if d then
            if type(d) == "function" then
                if d(self) then
                    return true
                end
            elseif type(d) == "table" then
                d[1](self, d[2])
            end
        end
    end

    return false
end

-- Step the system, transforming each state
function System:step ()
    local generated = ""
    for c in self.seed:gmatch"." do
        local s = self.transition[c]
        if s then
            generated = generated .. s
        else
            generated = generated .. c
        end
    end
    self.seed = generated
    self.states = str2queue(self.seed)
    self.active = nil
    self.pos = self.startpos:copy()
    self.angle = self.startangle
    --self.canvas:renderTo(function()
    --    love.graphics.clear()
    --end)
end

-- Step the system n number of times
function System:stepn (n)
    for i = 1, n do
        self:step()
    end
end

function System:draw ()
    love.graphics.draw(self.canvas)
    local t = self.active
    if t then
        love.graphics.line(t.a.x, t.a.y, t.b.x, t.b.y)
    end
end

return System
