local Vector = require("Vector")
local Queue = require("Queue")
local Stack = require("Stack")

local System = {}
System.__index = System

function math.clamp (min, max, v)
    if v < min then return min end
    if v > max then return max end
    return v
end

function str2queue (str)
    local Q = Queue.new()
    for c in str:gmatch"." do
        Q:push(c)
    end
    return Q
end

function hsv2rgb (h, s, v)
	local r, g, b
	local i = math.floor(h * 6);
	local f = h * 6 - i;
	local p = v * (1 - s);
	local q = v * (1 - f * s);
	local t = v * (1 - (1 - f) * s);
	i = i % 6
	if i == 0 then r, g, b = v, t, p
	elseif i == 1 then r, g, b = q, v, p
	elseif i == 2 then r, g, b = p, v, t
	elseif i == 3 then r, g, b = p, q, v
	elseif i == 4 then r, g, b = t, p, v
	elseif i == 5 then r, g, b = v, p, q
	end
	return r, g, b
end

function System.new (init, transition, dispatch)
    local scale = 10
    local width = love.graphics.getWidth() * scale
    local height = love.graphics.getHeight() * scale
    --local start = Vector.new(width * 0.25, height * 0.6)
    local start = Vector.new(width * 0.5, height * 0.75)
    init.position = start
    local t = setmetatable({
        canvas = love.graphics.newCanvas(width, height),

        transition = transition,
        dispatch = dispatch,

        startpos = init.position,
        startangle = init.angle,
        pos = init.position:copy(),
        angle = init.angle,
        seed = init.state,
        hsv = { 0, 0.5, 1 },

        speed = init.speed,
        length = init.length,
        width = init.width,

        stack = Stack.new(),
        states = str2queue(init.state),
        active = nil,

    }, System)

    love.graphics.setLineWidth(t.width)
    love.graphics.setLineStyle("smooth")
    t.canvas:renderTo(function()
        love.graphics.clear(1, 1, 1, 1)
        love.graphics.setLineWidth(t.width)
        love.graphics.setLineStyle("smooth")
    end)

    return t
end

function destination (pos, angle, distance)
    return Vector.new(pos.x + (math.cos(angle) * distance),
                      pos.y + (math.sin(angle) * distance))
end

function floor (vec)
    vec.x = math.floor(vec.x)
    vec.y = math.floor(vec.y)
end

-- Activates a new 'line' to be drawn over time with the current position and
-- angle as values for it.
function System:activate ()
    self.active = {
        start = self.pos:copy(),
        pos   = self.pos:copy(),
        dest  = destination(self.pos, math.rad(self.angle), self.length),
        time  = 0,
    }
    floor(self.active.start)
    floor(self.active.pos)
    floor(self.active.dest)
end

-- Returns whether the system is done with this current state queue.
function System:done ()
    return (self.active == nil and self.states:length() == 0)
end

function System:draw_active ()
    --local r, g, b, a = love.graphics.getColor()
    local n = self.active
    love.graphics.setColor(hsv2rgb(unpack(self.hsv)))
    love.graphics.line(n.start.x, n.start.y, n.pos.x, n.pos.y)
    --love.graphics.setColor(r, g, b, a)
end

-- Update the currently activated 'line'. If there's no active line then
-- process the state queue until one is found. If one isn't found, then return.
function System:update (dt)
    if self:done() then
        return
    end

    if self.active == nil and not self:process() then
        return
    end

    local n = self.active

    if n.time < 1 then
        n.time = n.time + (self.speed * dt)
        if n.time > 1 then
            n.time = 1
        end
        n.pos = Vector.lerp(n.start, n.dest, n.time)
        floor(n.pos)
    else
        self.pos = n.pos
        -- extend the position just to have squared edges
        n.pos = Vector.lerp(n.start, n.dest, 1.1)
        self.canvas:renderTo(function()
            self:draw_active()
        end)
        self.active = nil
    end
end

System.state = {}

function rot_val (val)
    if val < 0 then
        val = 1 - val
    elseif val > 1 then
        val = val - 1
    end
end

function add_hue (hsv, dir)
    hsv[1] = hsv[1] + (dir * (1 / (360 * 2)))
    rot_val(hsv[1])
end

function add_sat (hsv, dir)
    hsv[2] = hsv[2] + (dir * 0.0001)
    rot_val(hsv[2])
end

function System.state.draw (sys)
    add_hue(sys.hsv, 1)
    sys:activate()
    return true
end

function System.state.push (sys)
    sys.stack:push(sys.angle)
    sys.stack:push(sys.pos)
    sys.stack:push(sys.hsv)
end

function System.state.pop (sys)
    sys.hsv = sys.stack:pop()
    sys.pos = sys.stack:pop()
    sys.angle = sys.stack:pop()
end

function System.state.angle (sys, val)
    sys.angle = sys.angle + val
    if val < 0 then
        add_sat(sys.hsv, -1)
    else
        add_sat(sys.hsv, 1)
    end
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
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.canvas)
    --love.graphics.draw(self.canvas, -self.width / 2, -self.height / 2)
    if self.active then
        self:draw_active()
    end
end

-- Collect a list of positions that this system will visit over the course
-- of its animation. If n == 1 then every position is returned, n == 2 then
-- every other, n == 3 then every third, etc.
function System:discrete (n)
    local bacStack = self.stack
    local bacPos = self.pos
    local bacAngle = self.angle


    self.stack = Stack.new()
    self.pos = self.startpos:copy()
    self.angle = self.startangle
    local states = str2queue(self.seed)
    local list = {}

    while states:length() > 0 do
        local c = states:pop()
        local d = self.dispatch[c]

        if d then
            if type(d) == "function" then
                if d(self) then
                    self.pos = destination(self.pos, math.rad(self.angle), self.length)
                    self.active = nil
                    table.insert(list, self.pos:copy())
                end
            elseif type(d) == "table" then
                d[1](self, d[2])
            end
        end
    end

    self.stack = bacStack
    self.pos = bacPos
    self.angle = bacAngle

    local q = Queue.new()
    for i = 1, #list do
        if i % n == 0 then
            q:push(list[i])
        end
    end

    return q
end


return System
