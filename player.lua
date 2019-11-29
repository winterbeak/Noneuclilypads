graphics = require("graphics")
bodies = require("bodies")
misc = require("misc")

local player = {}

player.jumpOffsets = {0, 13, 22, 24, 24, 24}
player.idleSpriteSheet = graphics.SpriteSheet:new("frogIdle.png", 1)
player.jumpSpriteSheet = graphics.SpriteSheet:new("frogJump.png", 6)

player.leapReady1SpriteSheet = graphics.SpriteSheet:new("frogLeapReady1.png", 8)
player.leapReady2SpriteSheet = graphics.SpriteSheet:new("frogLeapReady2.png", 14)
player.leapReady3SpriteSheet = graphics.SpriteSheet:new("frogLeapReady3.png", 14)

player.leapSpriteSheet = graphics.SpriteSheet:new("frogLeap.png", 3)

player.flailSpriteSheet = graphics.SpriteSheet:new("frogFlail.png", 2)

player.leapLandingReadySpriteSheet = graphics.SpriteSheet:new("frogLeapLandingReady.png", 1)
player.leapLandingSpriteSheet = graphics.SpriteSheet:new("frogLeapLanding.png", 6)

player.tongueBase = graphics.SpriteSheet:new("frogTongueBase.png", 9)
player.tongueTip = graphics.SpriteSheet:new("frogTongueTip.png", 9)

player.Player = {}

--- Constructor.  Creates a new Player, who is a frog that can jump around.
function player.Player:new(startSpace)
  local newObj = {
    idleAnim = graphics.Animation:new(player.idleSpriteSheet),
    jumpAnim = graphics.Animation:new(player.jumpSpriteSheet),
    
    leapReady1Anim = graphics.Animation:new(player.leapReady1SpriteSheet),
    leapReady2Anim = graphics.Animation:new(player.leapReady2SpriteSheet),
    leapReady3Anim = graphics.Animation:new(player.leapReady3SpriteSheet),
    readyingLeap = false,
    
    leapAnim = graphics.Animation:new(player.leapSpriteSheet),
    inLeap = false,
    
    flailAnim = graphics.Animation:new(player.flailSpriteSheet),
    flailing = false,
    
    leapLandingReadyAnim = graphics.Animation:new(player.leapLandingReadySpriteSheet),
    leapLandingAnim = graphics.Animation:new(player.leapLandingSpriteSheet),
    landing = false,
    
    animation = nil,
    
    body = bodies.WarpBody:new(startSpace),
    
    energy = 30,
    health = 5,
    
    eating = false,
    eatSpace = nil,  -- The space that the player is eating bugs from
    eatBody = nil,  -- The body that the player is eating bugs from
    tongueBaseAnim = graphics.Animation:new(player.tongueBase),
    tongueTipAnim = graphics.Animation:new(player.tongueTip),
  }
  newObj.jumpAnim:setFrameLength(3)
  newObj.tongueBaseAnim:setFrameLength(3)
  newObj.tongueTipAnim:setFrameLength(3)
  
  newObj.leapReady1Anim:setFrameLength(4)
  newObj.leapReady2Anim:setFrameLength(4)
  newObj.leapReady3Anim:setFrameLength(4)
  
  newObj.leapAnim:setFrameLength(3)
  
  newObj.flailAnim:setFrameLength(2)
  
  newObj.leapLandingAnim:setFrameLength(4)
  
  newObj.animation = newObj.idleAnim
  
  self.__index = self
  return setmetatable(newObj, self)
end


--- Makes the player move to the given space.
function player.Player:moveTo(space, direction)
  self.body:moveTo(space, direction)
  self.animation = self.jumpAnim
end


function player.Player:draw(gridXOffset, gridYOffset, scale, tileSize)
  
  local rotation = 0
  local forwardsShift
  local previousForwardsShift
  
  local xShake = 0
  local yShake = 0
  
  -- Rotates the sprite based on what direction the player is facing
  rotation = misc.rotationOf(self.body.moveDirection)
  
  -- Sets the amount of forwards shift of the player sprite during the moving animation
  if self.body.moving then
    previousForwardsShift = player.jumpOffsets[self.animation.frame]
    forwardsShift = -tileSize / scale + previousForwardsShift
  end
  
  -- Shakes the player during the third phase of preparing to leap between islands
  if self.readyingLeap then
    if self.animation == self.leapReady2Anim then
      if math.random(1, 14) == 1 then
        xShake = math.random(-1, 1) * scale
        yShake = math.random(-1, 1) * scale
      end
    
    elseif self.animation == self.leapReady3Anim and self.animation.frame >= 9 then
      if math.random(1, 2) == 1 then
        xShake = math.random(-1, 1) * scale
        yShake = math.random(-1, 1) * scale
      end
    end
  end
  
  -- Draws the body on its current space
  for colNum, col in pairs(self.body.space.cells) do
    for rowNum, _ in pairs(col) do
      
      x = gridXOffset + ((colNum - 1) * tileSize) + xShake
      y = gridYOffset + ((rowNum - 1) * tileSize) + yShake

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
  
  -- Draws the tip of the tongue on the eating space
  if self.eating then
    for colNum, col in pairs(self.eatSpace.cells) do
      for rowNum, _ in pairs(col) do
        
        x = gridXOffset + ((colNum - 1) * tileSize)
        y = gridYOffset + ((rowNum - 1) * tileSize)

        self.tongueTipAnim:draw(x, y, scale, rotation)

      end
    end
  end

end


--- Updates the player's animation.  Should be called every frame.
function player.Player:updateAnimation()
  
  -- Animation for jumping between lillypads
  if self.body.moving then
    self.animation:update()
    
    if self.animation.isDone then
      self.jumpAnim:reset()
      self.animation = self.idleAnim
      self.body.moving = false
    end
  
  -- Animation for eating a fly
  elseif self.eating then
    self.tongueBaseAnim:update()
    self.tongueTipAnim:update()
    
    if self.tongueBaseAnim.frame == 3 and self.tongueBaseAnim.delayCount == 0 then
      self.eatBody:removeBugs(1)
    end
    
    if self.animation.isDone then
      self.tongueBaseAnim:reset()
      self.tongueTipAnim:reset()
      
      self.energy = self.energy + 1
      self.animation = self.idleAnim
      self.eating = false
    end
    
  -- Animation for getting ready to leap between islands
  elseif self.readyingLeap then
    if not self.animation.isDone then
      self.animation:update()
    end
  
  -- Animation for starting taking the leap between islands
  elseif self.inLeap then

    self.leapAnim:update()
    if self.leapAnim.isDone then
      self.leapAnim:reset()
      
      self.flailing = true
      self.inLeap = false
      self.animation = self.flailAnim
    end
  
  -- Animation for during the leap between islands
  elseif self.flailing then
    self.flailAnim:update()
    if self.flailAnim.isDone then
      self.flailAnim:reset()
    end
  
  -- Animation for landing after the leap between islands
  elseif self.landing then
    self.leapLandingAnim:update()
    if self.leapLandingAnim.isDone then
      self.leapLandingAnim:reset()
      self.animation = self.idleAnim
      self.landing = false
    end
  end
  
end


--- Makes the player eat a bug from a given space.
function player.Player:eatBug(space)
  if not space:isOccupied() then
    error("The player tried to eat bugs from a space without an enemy!")
  end
  if #space.occupiedBy.bugs <= 0 then
    error("The player tried to eat bugs from a body without any bugs!")
  end
  
  local direction = self.body.space:directionOf(space)
  if not direction then
    error("The player tried to eat a bug from a space that is not adjacent to the player's space!")
  end
  
  self.eating = true
  self.eatSpace = space
  self.eatBody = space.occupiedBy
  self.body.moveDirection = direction
  self.animation = self.tongueBaseAnim
end


--- Hurts the player.
function player.Player:hurt()
  self.health = self.health - 1
end


--- Makes the player go into the next ready leaping animation.
function player.Player:nextLeapReadyAnim()
  
  if self.animation == self.leapReady1Anim then
    self.animation = self.leapReady2Anim
  elseif self.animation == self.leapReady2Anim then
    self.animation = self.leapReady3Anim
  else
    self.animation = self.leapReady1Anim
  end
  self.animation:reset()
  
end


return player