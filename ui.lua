graphics = require("graphics")

local ui = {}

FADE_IN = 1
FADE_OUT = 2

ui.DEFAULT_FADE_LENGTH = 150

ui.energyBarAbove = graphics.SpriteSheet:new("energyBarAbove.png", 1)  -- Above juice on the Z axis
ui.energyBarBelow = graphics.SpriteSheet:new("energyBarBelow.png", 1)  -- Below juice on the Z axis
ui.energyPipeIdle = graphics.SpriteSheet:new("energyBarPipeIdle.png", 1)
ui.energyPipePiping = graphics.SpriteSheet:new("energyBarPipePiping.png", 7)
ui.energyTop = graphics.SpriteSheet:new("energyTop.png", 1)
ui.energyTopUp = graphics.SpriteSheet:new("energyTopUp.png", 3)
ui.energyTopDown = graphics.SpriteSheet:new("energyTopDown.png", 3)
ui.energyColor = graphics.convertColor({22, 148, 0, 0.7 * 255})

ui.hearts = graphics.loadMulti("heart", 5, ".png", 1)
ui.heartsExplosion = graphics.loadMulti("heartExplosion", 5, ".png", 5)
ui.heartVine = graphics.SpriteSheet:new("heartVine.png", 1)

ui.heartVineX = 0
ui.heartVineY = 0
ui.heartX = {3, 10, 2, 7, 0}
ui.heartY = {22, 38, 54, 70, 86}

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
  
  ui.heartX = {3, 10, 2, 7, 0}
  ui.heartY = {22, 38, 54, 70, 86}
  for i = 1, #ui.heartX do
    ui.heartX[i] = ui.heartX[i] * scale
    ui.heartY[i] = ui.heartY[i] * scale
  end
  
end


ui.Fader = {}

--- Stores the values for fading things in and out.
function ui.Fader:new(minValue, maxValue, length)
  local newObj = {
    value = minValue,
    minValue = minValue,
    maxValue = maxValue,
    fadeLength = length,
    fadeSpeed = (maxValue - minValue) / length,
    fadingUp = false,
    fadingDown = false,
  }
  
  self.__index = self
  return setmetatable(newObj, self)
end


--- Must be called every frame.
function ui.Fader:update()
  if self.fadingUp then
    self.value = self.value + self.fadeSpeed
    
    if self.value >= self.maxValue then
      self.value = self.maxValue
      self.fadingUp = false
    end
  
  elseif self.fadingDown then
    self.value = self.value - self.fadeSpeed
    
    if self.value < self.minValue then
      self.value = self.minValue
      self.fadingDown = false
    end
    
  end
end


--- Starts the fading up to the maximum value.
function ui.Fader:fadeUp()
  self.fadingUp = true
end


--- Starts the fading down to the minimum value.
function ui.Fader:fadeDown()
  self.fadingDown = true
end


--- Sets the fader's value to the given value.
function ui.Fader:setValue(value)
  self.value = value
end


--- Changes how long the fader takes to fade.
function ui.Fader:setLength(length)
  self.length = length
  self.fadeSpeed = (self.maxValue - self.minValue) / length
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
    losingEnergy = false,
    energyTopUpAnim = graphics.Animation:new(ui.energyTopUp),
    energyTopDownAnim = graphics.Animation:new(ui.energyTopDown),
    energyTopIdleAnim = graphics.Animation:new(ui.energyTop),
    energyTopAnim = nil,
    
    lastFrameEnergy = player.energy,
    displayEnergy = player.energy,
    
    heartsIdleAnims = graphics.multiAnim(ui.hearts),
    heartsExplosionAnims = graphics.multiAnim(ui.heartsExplosion),
    heartsExploding = {false, false, false, false, false},
    heartsGone = {false, false, false, false, false},
    
    lastFrameHealth = player.health,
    displayHealth = player.health,
    
    heartVineFader = ui.Fader:new(0, 1, ui.DEFAULT_FADE_LENGTH),
    energyBarFader = ui.Fader:new(0, 1, ui.DEFAULT_FADE_LENGTH),
    
  }
  
  newObj.energyPipeAnim = newObj.energyPipeIdleAnim
  newObj.energyTopAnim = newObj.energyTopIdleAnim

  newObj.energyTopDownAnim:setFrameLength(3)
  newObj.energyTopUpAnim:setFrameLength(3)
  newObj.energyPipePipingAnim:setFrameLength(3)
  
  graphics.setMultiAnimFrameLength(newObj.heartsExplosionAnims, 4)
  
  self.__index = self
  return setmetatable(newObj, self)
end


function ui.UI:update()
  
  self.heartVineFader:update()
  self.energyBarFader:update()
  
  -- Updates the pipe bulging animation
  if self.pipingEnergy then
    self.energyPipePipingAnim:update()
    
    if self.energyPipePipingAnim.isDone then
      self.pipingEnergy = false
      self.energyPipeAnim = self.energyPipeIdleAnim
      self.displayEnergy = self.player.energy
      
      self.gainingEnergy = true
      self.energyTopAnim = self.energyTopUpAnim
      self.energyTopUpAnim:reset()
    end
    
  -- Updates the energy rising animation
  elseif self.gainingEnergy or self.losingEnergy then
    self.energyTopAnim:update()
    
    if self.energyTopAnim.isDone then
      self.gainingEnergy = false
      self.losingEnergy = false
      self.energyTopAnim = self.energyTopIdleAnim
    end
    
  end
  
  for i = 1, 5 do
    if self.heartsExploding[i] then
      self.heartsExplosionAnims[i]:update()
      
      if self.heartsExplosionAnims[i].isDone then
        self.heartsExplosionAnims[i]:reset()
        self.heartsGone[i] = true
        self.heartsExploding[i] = false
      end
    end
  end
  
  
  -- If an increase in energy is detected, play the pipe bulging animation
  if self.lastFrameEnergy < self.player.energy then
    self.pipingEnergy = true
    self.energyPipeAnim = self.energyPipePipingAnim
    self.energyPipePipingAnim:reset()
  
  -- If a decrease in energy is detected, play the energy moving down animation
  elseif self.lastFrameEnergy > self.player.energy then
    self.losingEnergy = true
    self.energyTopAnim = self.energyTopDownAnim
    self.energyTopAnim:reset()
    self.displayEnergy = self.player.energy
    
  end
  
  if self.lastFrameHealth > self.player.health then
    for i = self.player.health + 1, self.lastFrameHealth do
      self.heartsExploding[i] = true
    end
    
  elseif self.lastFrameHealth < self.player.health then
    for i = self.lastFrameHealth, self.player.health do
      self.heartsExploding[i] = false
      self.heartsGone[i] = false
    end
  end
  
  self.displayHealth = self.player.health
  self.lastFrameHealth = self.player.health
  self.lastFrameEnergy = self.player.energy

end


function ui.UI:draw(scale)
  
  self:drawEnergyBar(scale)
  self:drawHeartVine(scale)
  
end


function ui.UI:drawEnergyBar(scale)
  graphics.setAlpha(self.energyBarFader.value)
  
  self.energyPipeAnim:draw(0, ui.energyBarPipeY, scale)
  
  ui.energyBarBelow:draw(1, 0, ui.energyBarY, scale)
  
  -- Draws a full energy bar
  if self.displayEnergy > 84 then
    local rectX = 5 * scale
    local rectY = (ui.energyBarY + 99 * scale) - (84 * scale) + (8 * scale)
    
    local height = 84 * scale
    
    love.graphics.setColor(ui.energyColor)
    love.graphics.rectangle("fill", rectX, rectY, scale * 14, height)
    love.graphics.setColor(graphics.COLOR_WHITE)
  
  -- Draws the energy plus the top of the energy (unless the player doesn't have any energy)
  elseif self.displayEnergy > 0 then
    
    local energyX = 5 * scale
    local energyY = (ui.energyBarY + 99 * scale) - (self.displayEnergy * scale)
    local rectY = energyY + scale * 8
      
    -- Draws the rest of the energy one pixel lower if the top of the energy is rising
    if self.gainingEnergy then
      rectY = rectY + scale
      
    -- Draws the top of the energy higher if the energy level is dropping
    elseif self.losingEnergy then
      energyY = energyY - scale
    end
  
    self.energyTopAnim:draw(energyX, energyY, scale)
    
    love.graphics.setColor(ui.energyColor)
    love.graphics.rectangle("fill", energyX, rectY, scale * 14, self.displayEnergy * scale)
    love.graphics.setColor(graphics.COLOR_WHITE)
  end
  
  ui.energyBarAbove:draw(1, 0, ui.energyBarY, scale)
  
end


function ui.UI:drawHeartVine(scale)
  graphics.setAlpha(self.heartVineFader.value)
  
  ui.heartVine:draw(1, ui.heartVineX, ui.heartVineY, scale)
  
  local x
  local y
  for i = 1, 5 do
    x = ui.heartVineX + ui.heartX[i]
    y = ui.heartVineY + ui.heartY[i]
      
    if self.heartsExploding[i] then
      self.heartsExplosionAnims[i]:draw(x, y, scale)
      
    elseif not self.heartsGone[i] then
      self.heartsIdleAnims[i]:draw(x, y, scale)
      
    end
  end
end

return ui
