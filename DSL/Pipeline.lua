local Queue = require("Queue")

local Pipeline = {}
Pipeline.__index = Pipeline

function coroutine.setup (func, kind, ...)
    local routine = coroutine.create(func)
    local s, msg = coroutine.resume(routine, kind, ...)
    if msg ~= "ready" then
        error("Coroutine isn't ready after setup: " .. msg)
    end
    return routine
end

function Pipeline.new ()
    return setmetatable({
        queue = Queue.new(),
        other = Queue.new(),
        dt = 0
    }, Pipeline)
end

function Pipeline:spawn (effect)
    local routine = coroutine.create(function ()
        local routine = effect:routine()
        routine(dt)
        return effect.kind, effect
    end)
    self.queue:push(routine)
end

function Pipeline:draw ()
    while self.queue:length() > 0 do
        local routine = self.queue:pop()
        local s, msg, effect = coroutine.resume(routine, self.dt)
        if msg == "continue" then
            self.other:push(routine)
        elseif msg == "respawn" then
            self:spawn(effect)
        end
    end

    local q = self.queue
    self.queue = self.other
    self.other = q
end

function Pipeline:update (dt)
    self.dt = dt
end

return Pipeline
