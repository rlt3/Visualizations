-- camera.love
-- stolen from: https://love2d.org/forums/viewtopic.php?t=80560
local Camera = {}
Camera.__index = Camera

function Camera:new(x, y, sx, sy)
    -- Create a new camera with (x,y) positioned on the screen at (sx,sy) or centered if sx/sy are not given
    local camera = setmetatable({scale=1, _scale=1, shake=0}, self)
    camera:moveTo(x,y,sx,sy)
    return camera
end

function Camera:moveTo(x,y,sx,sy)
    -- Move the camera so that (x,y) is positioned on the screen at (sx,sy) or centered if sx/sy are not given
    sx = sx or .5*love.graphics.getWidth()
    sy = sy or .5*love.graphics.getHeight()
    self._x, self._y = x-sx/self._scale, y-sy/self._scale
    self.target = {
        screenX=sx, screenY=sy,
        prevScreenX=sx, prevScreenY=sy,
    }
end

function Camera:getWorldPos(screenX, screenY)
    -- Return the position of the screen coordinates in world coordinates.
    return self._x + screenX / self._scale, self._y + screenY / self._scale
end

function Camera:getScreenPos(worldX, worldY)
    -- Return the position of the world coordinates in screen coordinates.
    return (worldX - self._x) * self._scale, (worldY - self._y) * self._scale
end

function Camera:getMidpoint()
    -- Return the world coordinates of the center of the screen. Do not access/modify camera._x or camera._y directly.
    return self:getWorldPos(.5*love.graphics.getWidth(), .5*love.graphics.getHeight())
end

function Camera:set()
    -- Call this function once before drawing all the objects in the world.
    local prevX, prevY = self:getWorldPos(self.target.prevScreenX, self.target.prevScreenY)
    self.target.prevScreenX, self.target.prevScreenY = self.target.screenX, self.target.screenY
    self._scale = self.scale
    local x, y = self:getWorldPos(self.target.screenX, self.target.screenY)
    self._x, self._y = self._x - (x - prevX), self._y - (y - prevY)

    love.graphics.push()
    love.graphics.translate(self.target.screenX, self.target.screenY)
    love.graphics.scale(self._scale, self._scale)
    love.graphics.translate(-prevX, -prevY)
    love.graphics.translate(love.math.randomNormal(self.shake), love.math.randomNormal(self.shake))
end

function Camera:unset()
    -- Call this function once after drawing all the objects in the world.
    love.graphics.pop()
end

return Camera
