graphics = require("graphics")
sound = require("sound")
bodies = require("bodies")
misc = require("misc")

local rat = {}

rat.jumpOffsets = {0, 0, 0, 7, 25, 29, 29, 29}

rat.idle1SpriteSheet = graphics.SpriteSheet:new("ratIdle1.png", 1)
rat.idle2SpriteSheet = graphics.SpriteSheet:new("ratIdle2.png", 12)
rat.jumpSpriteSheet = graphics.SpriteSheet:new("ratJump.png", 8)
rat.attackSpriteSheet = graphics.SpriteSheet:new("ratAttack.png", 6)

rat.idleSound = sound.SoundSet:new("ratSqueak", 6, ".ogg", 0.3)
rat.attackSound = sound.SoundSet:new("ratAttack", 4, ".ogg", 0.3)


rat.Rat = {}

--- Constructor.  Makes a rat enemy.
-- This enemy always waits a turn, then moves closer to the player, repeatedly.
function rat.Rat:new(startSpace)
  local newObj = {
    idleAnim1 = graphics.Animation:new(rat.idle1SpriteSheet),
    idleAnim2 = graphics.Animation:new(rat.idle2SpriteSheet),
    jumpAnim = graphics.Animation:new(rat.jumpSpriteSheet),
    attackAnim = graphics.Animation:new(rat.attackSpriteSheet),
    
    attacking = false,
    
    moveTimer = math.random(0, 1),
    animation = nil,
    
    body = bodies.WarpBody:new(startSpace),
    
    soundTimer = math.random(1, 1200),
  }
  
  newObj.body.moveDirection = misc.randomDirection()
  
  newObj.idleAnim2:setFrameLength(6)
  newObj.jumpAnim:setFrameLength(3)
  newObj.attackAnim:setFrameLength(3)
  
  if newObj.moveTimer == 0 then
    newObj.animation = newObj.idleAnim1
  elseif newObj.moveTimer == 1 then
    newObj.animation = newObj.idleAnim2
  end
  
  newObj.body:addFleas(3)
  
  self.__index = self
  return setmetatable(newObj, self)
end


--- Makes the rat move.
-- Rats always move one space closer to the player.
function rat.Rat:move(player)
  local closestSpace = self.body.space:closestAdjacent(player)
  
  if closestSpace then
    self.body:moveTo(closestSpace, self.body.space:directionOf(closestSpace))
    self.animation = self.jumpAnim
    
  -- If no valid space was found then
  else
    -- Play the "can't move" animation
  end
    
end


--- Makes the rat take a turn.
-- Rats always wait one turn, then move one space closer to the player.
function rat.Rat:takeTurn(level, player)
  self.moveTimer = self.moveTimer + 1
  
  if self.moveTimer == 1 then
    self.idleAnim2:reset()
    self.animation = self.idleAnim2

  elseif self.moveTimer == 2 then
    
    -- If the rat is beside the player, hurt them
    if self.body:isBesideBody(player.body) then
      player:hurt()
      self.animation = self.attackAnim
      self.attacking = true
      self.body.moveDirection = self.body.space:directionOf(player.body.space)
      
      rat.attackSound:playRandom()
      
    -- Otherwise, just move normally
    else
      self:move(player)
    end
    
    self.moveTimer = 0
  end
end


--- Draws the rat.
function rat.Rat:draw(gridXOffset, gridYOffset, scale, tileSize)
  
  local rotation = 0
  local forwardsShift
  local previousForwardsShift
  
  -- Rotates the sprite based on what direction the rat is facing
  rotation = misc.rotationOf(self.body.moveDirection)
  
  -- Sets the amount of forwards shift of the rat sprite during the moving animation
  if self.body.moving then
    previousForwardsShift = rat.jumpOffsets[self.animation.frame]
    forwardsShift = -tileSize / scale + previousForwardsShift
  end
  
  -- Draws the body on its current space
  for colNum, col in pairs(self.body.space.cells) do
    for rowNum, _ in pairs(col) do
      
      x = gridXOffset + ((colNum - 1) * tileSize)
      y = gridYOffset + ((rowNum - 1) * tileSize)

      if self.body.moving then
        self.animation:drawShifted(x, y, forwardsShift, 0, scale, rotation)
      else
        self.animation:draw(x, y, scale, rotation)
      end

    end
  end

  -- Draws the body on the previous space
  if self.body.moving then
    for colNum, col in pairs(self.body.previousSpace.cells) do
      for rowNum, _ in pairs(col) do
        
        x = gridXOffset + ((colNum - 1) * tileSize)
        y = gridYOffset + ((rowNum - 1) * tileSize)
        
        self.animation:drawShifted(x, y, previousForwardsShift, 0, scale, rotation)
        
      end
    end
  end
  
  self.body:drawBugs(gridXOffset, gridYOffset, scale, tileSize)

end


--- Updates the rat's animation.  Should be called every frame.
function rat.Rat:updateAnimation()
  
  -- Jump animation
  if self.body.moving then
    self.animation:update()
    
  elseif self.attacking then
    self.animation:update()
    
  -- Second idle animation
  elseif self.moveTimer == 1 then
    self.animation:update()
    
    if self.animation.isDone then
      self.animation:reset()
    end
  end
  
  if self.animation.isDone then
    self.jumpAnim:reset()
    self.attackAnim:reset()
    self.animation = self.idleAnim1
    self.body.moving = false
    self.attacking = false
  end
  
  self.body:updateBugs()
  
  -- Updates the sound timer
  self.soundTimer = self.soundTimer - 1
  if self.soundTimer <= 0 then
    self.soundTimer = math.random(600, 1200)
    rat.idleSound:playRandom()
  end
  
end


return rat