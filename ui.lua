graphics = require("graphics")

local ui = {}

ui.energyBarAbove = graphics.SpriteSheet:new("energyBarAbove.png", 1)  -- Above juice on the Z axis
ui.energyBarBelow = graphics.SpriteSheet:new("energyBarBelow.png", 1)  -- Below juice on the Z axis
ui.energyPipeIdle = graphics.SpriteSheet:new("energyBarPipeIdle.png", 1)
ui.energyPipePiping = graphics.SpriteSheet:new("energyBarPipePiping.png", 7)
ui.energyTopUp = graphics.SpriteSheet:new("energyTopUp.png", 3)
ui.energyTop = graphics.SpriteSheet:new("energyTop.png", 1)
ui.energyColor = graphics.convertColor({22, 148, 0, 0.7 * 255})

ui.hearts = graphics.SpriteSheet:new("hearts.png", 5)
ui.heartVine = graphics.SpriteSheet:new("heartVine.png", 1)

ui.heartVineX = 0
ui.heartVineY = 0
ui.heartX = {6, 13, 5, 10, 3}
ui.heartY = {24, 40, 56, 72, 88}

ui.energyBarX = 0
ui.energyBarY = 0

ui.energyBarPipeY = 0


--- Updates the size and position of all of the sprites.
-- MUST BE CALLED AT THE START OF THE GAME, OTHERWISE SOME VALUES WILL NOT BE INITIALIZED
function ui.updateScreenSize(scale)
  local energyBarHeight = (ui.energyBarAbove.singleHeight + ui.energyPipeIdle.singleHeight) * scale
  ui.energyBarY = math.floor((love.graphics.getHeight() - energyBarHeight) / 2 - (3 * scale))
  ui.energyBarPipeY =  ui.energyBarY + (scale * 114)
  
  ui.heartVineX = love.graphics.getWidth() - (24 * scale)
  ui.heartVineY = math.floor((love.graphics.getHeight() - (ui.heartVine.singleHeight * scale)) / 2)
  
  ui.heartX = {6, 13, 5, 10, 3}
  ui.heartY = {24, 40, 56, 72, 88}
  for i = 1, #ui.heartX do
    ui.heartX[i] = ui.heartX[i] * scale
    ui.heartY[i] = ui.heartY[i] * scale
  end
  
end


ui.UI = {}

function ui.UI:new(player)
  local newObj = {
    player = player,
    
    pipingEnergy = false,
    energyPipePipingAnim = graphics.Animation:new(ui.energyPipePiping),
    energyPipeIdleAnim = graphics.Animation:new(ui.energyPipeIdle),
    energyPipeAnim = nil,
    
    gainingEnergy = false,
    energyTopUpAnim = graphics.Animation:new(ui.energyTopUp),
    energyTopIdleAnim = graphics.Animation:new(ui.energyTop),
    energyTopAnim = nil,
    
    actualEnergy = player.energy,
    displayEnergy = player.energy
  }
  
  newObj.energyPipeAnim = newObj.energyPipeIdleAnim
  newObj.energyTopAnim = newObj.energyTopIdleAnim

  newObj.energyTopUpAnim:setFrameLength(3)
  newObj.energyPipePipingAnim:setFrameLength(3)
  
  self.__index = self
  return setmetatable(newObj, self)
end


function ui.UI:update()
  
  -- Updates the pipe bulging animation
  if self.pipingEnergy then
    self.energyPipePipingAnim:update()
    
    if self.energyPipePipingAnim.isDone then
      self.pipingEnergy = false
      self.energyPipeAnim = self.energyPipeIdleAnim
      self.displayEnergy = self.actualEnergy
      
      self.gainingEnergy = true
      self.energyTopAnim = self.energyTopUpAnim
      self.energyTopUpAnim:reset()
    end
    
  -- Updates the energy rising animation
  elseif self.gainingEnergy then
    self.energyTopUpAnim:update()
    
    if self.energyTopUpAnim.isDone then
      self.gainingEnergy = false
      self.energyTopAnim = self.energyTopIdleAnim
    end
    
  end
  
  -- If an increase in energy is detected, play the pipe bulging animation
  if self.actualEnergy < player.energy then
    self.pipingEnergy = true
    self.energyPipeAnim = self.energyPipePipingAnim
    self.energyPipePipingAnim:reset()
  
  elseif self.actualEnergy > player.energy then
    self.displayEnergy = player.energy
    
  end
  
  self.actualEnergy = player.energy
end


function ui.UI:draw(scale)
  self.energyPipeAnim:draw(0, ui.energyBarPipeY, scale)
  
  ui.energyBarBelow:draw(1, 0, ui.energyBarY, scale)
  
  
  
  
  
  -- Draws the energy (unless the player doesn't have any energy)
  if self.displayEnergy > 0 then
    
    local energyX = 5 * scale
    local energyY = (ui.energyBarY + 99 * scale) - (self.displayEnergy * scale)
    local rectY = energyY + scale * 8
      
      -- Draws the rest of the energy one pixel lower if the top-up animation is playing
    if self.gainingEnergy then
      rectY = rectY + scale
    end
  
    self.energyTopAnim:draw(energyX, energyY, scale)
    
    love.graphics.setColor(ui.energyColor)
    love.graphics.rectangle("fill", energyX, rectY, scale * 14, self.displayEnergy * scale)
    love.graphics.setColor(graphics.COLOR_WHITE)
  end
  
  ui.energyBarAbove:draw(1, 0, ui.energyBarY, scale)
  
  ui.heartVine:draw(1, ui.heartVineX, ui.heartVineY, scale)
  for i = 1, player.health do
    ui.hearts:draw(i, ui.heartVineX + ui.heartX[i], ui.heartVineY + ui.heartY[i], scale)
  end
end

return ui
