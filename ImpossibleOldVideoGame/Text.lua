local Text = {}
Text.__index = Text

function Text.new (text, x, y, size, alignment, fontname)
    size = size or 24
    fontname = fontname or "Montserrat-SemiBold.ttf"
    font = love.graphics.newFont(fontname, size)
    local t = {
        display = true,
        size = size,
        font = font,
        text = text,
        color = {255, 255, 255},
        x = x,
        y = y,
        alignment = alignment or "center",
    }
    return setmetatable(t, Text)
end

function Text:draw ()
    if not self.display then return end
    love.graphics.setFont(self.font)
    love.graphics.setColor(unpack(self.color))
    love.graphics.printf(self.text, self.x, self.y, 800, self.alignment)
    love.graphics.setColor(1,1,1,1);
end

return Text
