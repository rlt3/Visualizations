local Queue = require("Queue")

local Effect = {}
Effect.__index = Effect

function Effect.new (kind, context, ...)
    return setmetatable({
        kind = kind,
        context_func = context,
        context_args = {...}
    }, Effect)
end

function Effect:routine ()
    local f = self.context_func(unpack(self.context_args))
    if type(f) ~= "function" then
        error("Return value of Effect's context function is not a function!")
    end
    return f
end

return Effect
