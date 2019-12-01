graphics = require("graphics")
sound = require("sound")
movement = require("movement")

local transition = {}

transitionWhoosh = sound.SoundSet:new("screenTransition", 1, ".ogg", 1)


transition.ScreenTransition = {}

function transition.ScreenTransition:new()
  local newObj = {
    activated = false,
    fullyCovering = false,
    middleFrame = false,
    
    bottomY = 0,
    topY = 0,
    
    waitFrame = 0,
    waitLength = 60,
    
    bottomMovement = movement.Sine:newFadeOut(0, love.graphics.getHeight(), 30),
    topMovement = movement.Sine:newFadeOut(0, love.graphics.getHeight(), 30)
  }
  
  self.__index = self
  return setmetatable(newObj, self)
end


function transition.ScreenTransition:start()
  self.bottomMovement.frame = 0
  self.topMovement.frame = 0
  self.waitFrame = 0
  self.activated = true
  
  transitionWhoosh:playRandom()
end


function transition.ScreenTransition:update()
  if self.activated then
    if self.bottomMovement.frame < self.bottomMovement.length then
      self.bottomMovement.frame = self.bottomMovement.frame + 1
      self.fullyCovering = false
    
    elseif self.waitFrame < self.waitLength then
      self.waitFrame = self.waitFrame + 1
      self.fullyCovering = true
      
      if self.waitFrame == math.floor(self.waitLength / 2) then
        self.middleFrame = true
      else
        self.middleFrame = false
      end
      
    elseif self.topMovement.frame < self.topMovement.length then
      self.topMovement.frame = self.topMovement.frame + 1
      self.fullyCovering = false
    
    else
      self.activated = false
      
    end
    
    if self.topMovement.frame == 1 then
      transitionWhoosh:playRandom()
    end
    
  end
end


function transition.ScreenTransition:draw()
  love.graphics.setColor(graphics.TRANSITION_COLOR)
  
  local y = self.topMovement:currentValue()
  local width = love.graphics.getWidth()
  local height = self.bottomMovement:currentValue() - y
  
  love.graphics.rectangle("fill", 0, y, width, height)
end


return transition