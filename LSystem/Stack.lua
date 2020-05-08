local Stack = {}
Stack.__index = Stack

function Stack.new ()
    return setmetatable({ top = 0 }, Stack)
end

function Stack:push (v)
    self.top = self.top + 1
    self[self.top] = v
end

function Stack:pop ()
    if self:length() == 0 then
        error("Cannot pop empty stack")
    end
    local v = self[self.top]
    self[self.top] = nil
    self.top = self.top - 1
    return v
end

function Stack:length ()
    return self.top
end

return Stack
