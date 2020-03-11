local Vector = {}
Vector.__index = Vector

local function is_vector(t)
    return getmetatable(t) == Vector
end

function Vector.new(x, y)
    return setmetatable({ x = x or 0, y = y or 0 }, Vector)
end

-- operator overloading
function Vector.__add(lhs, rhs)
    assert(is_vector(lhs) and is_vector(rhs), "Type mismatch: Vector expected.")
    return Vector.new(lhs.x + rhs.x, lhs.y + rhs.y)
end

function Vector.__sub(lhs, rhs)
    assert(is_vector(lhs) and is_vector(rhs), "Type mismatch: Vector expected.")
    return Vector.new(lhs.x - rhs.x, lhs.y - rhs.y)
end

function Vector.__mul(lhs, rhs)
    local is_rhs_vector = is_vector(rhs)
    local is_lhs_vector = is_vector(lhs)
    if type(lhs) == "number" and is_rhs_vector then
        return Vector.new(rhs.x * lhs, rhs.y * lhs)
    elseif type(rhs) == "number" and is_lhs_vector then
        return Vector.new(lhs.x * rhs, lhs.y * rhs)
    elseif is_rhs_vector and is_lhs_vector then
        return Vector.new(lhs.x * rhs.x, lhs.y * rhs.y)
    else
        error("Type mismatch: Vector and/or number expected", 2)
    end
end

function Vector.__unm(t)
    assert(is_vector(t), "Type mismatch: Vector expected.")
    return Vector.new(-t.x, -t.y)
end

function Vector:__tostring()
    return "("..self.x..", "..self.y..")"
end

function Vector.__eq(lhs, rhs)
    return lhs.x == rhs.x and lhs.y == rhs.y
end

function Vector.__lt(lhs, rhs)
    return lhs.x < rhs.x or (not (rhs.x < lhs.x) and lhs.y < rhs.y)
end

function Vector.__le(lhs, rhs)
    return lhs.x <= rhs.x or lhs.y <= rhs.y
end


-- actual functions
function Vector:clone()
    return Vector.new(self.x, self.y)
end

function Vector:length()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

function Vector:length_squared()
    return self.x * self.x + self.y * self.y
end

function Vector:is_unit()
    return self:length_squared() == 1
end

function Vector:unpack()
    return self.x, self.y
end

function Vector:normalize()
    local len = self:length()
    if len ~= 0 and len ~= 1 then
        self.x = self.x / len
        self.y = self.y / len
    end
end

function Vector:normalized()
    return self:clone():normalize()
end

function Vector.dot(lhs, rhs)
    assert(is_vector(lhs) and is_vector(rhs), "Type mismatch: Vector expected")
    return lhs.x * rhs.x + lhs.y * rhs.y
end

function Vector.distance(lhs, rhs)
    assert(is_vector(lhs) and is_vector(rhs), "Type mismatch: Vector expected")
    local dx, dy = lhs.x - rhs.x, lhs.y - rhs.y
    return math.sqrt(dx * dx + dy * dy)
end

function Vector.distance_squared(lhs, rhs)
    assert(is_vector(lhs) and is_vector(rhs), "Type mismatch: Vector expected")
    local dx, dy = lhs.x - rhs.x, lhs.y - rhs.y
    return dx * dx + dy * dy
end

function Vector.max(lhs, rhs)
    assert(is_vector(lhs) and is_vector(rhs), "Type mismatch: Vector expected")
    local x = math.max(lhs.x, rhs.x)
    local y = math.max(lhs.y, rhs.y)
    return Vector.new(x, y)
end

function Vector.min(lhs, rhs)
    assert(is_vector(lhs) and is_vector(rhs), "Type mismatch: Vector expected")
    local x = math.min(lhs.x, rhs.x)
    local y = math.min(lhs.y, rhs.y)
    return Vector.new(x, y)
end

function Vector.angle(from, to)
    assert(is_vector(from) and is_vector(to), "Type mismatch: Vector expected")
    return math.acos(Vector.dot(from, to) / (from:length() * to:length()))
end

function Vector.direction(from, to)
    assert(is_vector(from) and is_vector(to), "Type mismatch: Vector expected")
    return math.atan2(to.x - from.x, to.y - from.y)
end

function Vector.lerp(from, to, t)
    assert(is_vector(from) and is_vector(to), "Type mismatch: Vector expected")
    assert(type(t) == "number", "Type mismatch: number expected for t")
    return (1 - t) * from + t * to;
end

return Vector
