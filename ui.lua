graphics = require("graphics")

local ui = {}

ui.energyBarAbove = graphics.SpriteSheet:new("energyBarAbove.png", 1)  -- Above juice on the Z axis
ui.energyBarBelow = graphics.SpriteSheet:new("energyBarBelow.png", 1)  -- Below juice on the Z axis

ui.energyTop = graphics.SpriteSheet:new("energyTop.png", 1)
ui.energyColor = graphics.convertColor({22, 148, 0, 0.7 * 255})

ui.hearts = graphics.SpriteSheet:new("hearts.png", 5)
ui.heartVine = graphics.SpriteSheet:new("heartVine.png", 1)

ui.heartX = {6, 13, 5, 10, 3}
ui.heartY = {24, 40, 56, 72, 88}


ui.UI = {}

function ui.UI:new(player)
  local newObj = {
    player = player
  }
  
  self.__index = self
  return setmetatable(newObj, self)
end


function ui.UI:draw(scale)
  local topY = (love.graphics.getHeight() - (ui.energyBarAbove.fullHeight * scale)) / 2
  
  ui.energyBarBelow:draw(1, 0, topY, scale)
  
  local energyX = 5 * scale
  local energyY = (topY + 99 * scale) - (self.player.energy * scale)
  ui.energyTop:draw(1, energyX, energyY, scale)
  love.graphics.setColor(ui.energyColor)
  love.graphics.rectangle("fill", energyX, energyY + scale * 8, scale * 14, player.energy * scale)
  love.graphics.setColor(graphics.COLOR_WHITE)
  
  ui.energyBarAbove:draw(1, 0, topY, scale)
  
  local heartVineX = love.graphics.getWidth() - 24 * scale

  ui.heartVine:draw(1, heartVineX, topY, scale)
  for i = 1, player.health do
    ui.hearts:draw(i, heartVineX + (ui.heartX[i] * scale), topY + (ui.heartY[i] * scale), scale)
  end
end

return ui
