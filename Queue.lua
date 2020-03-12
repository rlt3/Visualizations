local Queue = {}
Queue.__index = Queue

function Queue.new ()
    return setmetatable({ head = 1, tail = 1 }, Queue)
end

function Queue:push (v)
    self[self.tail] = v
    self.tail = self.tail + 1
end

function Queue:pop ()
    if self:length() == 0 then return nil end
    local v = self[self.head]
    self[self.head] = nil
    self.head = self.head + 1
    return v
end

function Queue:front ()
    if self:length() == 0 then return nil end
    return self[self.head]
end

function Queue:back ()
    if self:length() == 0 then return nil end
    return self[self.tail]
end

function Queue:map (f)
    print(self.head)
    print(self.tail)
    --for i = self.head, self.tail do
    --    f(self[i])
    --end
end

function Queue:length ()
    return self.tail - self.head
end

return Queue
