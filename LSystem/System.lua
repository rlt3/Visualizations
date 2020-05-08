local System = {}
System.__index = System

function System.new (seed, stepf, drawf)
    return setmetatable({ sys = seed, stepf = stepf, drawf = drawf}, System)
end

function System:step ()
    self.sys = self.stepf(self.sys)
end

function System:draw ()
    self.drawf(self.sys)
end

return System
