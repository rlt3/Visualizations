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

function Pipeline:spawn (name, func, ...)
    return name, func, {...}
end

function Pipeline:once (func, ...)
    self.queue:push(coroutine.setup(func, "once", ...))
end

function Pipeline:respawn (func, ...)
    self.queue:push(coroutine.setup(func, "respawn", ...))
end

function Pipeline:draw ()
    while self.queue:length() > 0 do
        local routine = self.queue:pop()
        local s, msg, func = coroutine.resume(routine, self.dt)
        if msg == "continue" then
            self.other:push(routine)
        elseif msg == "respawn" then
            self.other:push(coroutine.setup(func, msg, 400, 300))
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
