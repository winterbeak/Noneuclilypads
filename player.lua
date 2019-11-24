graphics = require("graphics")
bodies = require("bodies")
misc = require("misc")

local player = {}

player.jumpOffsets = {0, 13, 22, 24, 24, 24}
player.idleSpriteSheet = graphics.SpriteSheet:new("frogIdle.png", 1)
player.jumpSpriteSheet = graphics.SpriteSheet:new("frogJump.png", 6)

player.tongueBase = graphics.SpriteSheet:new("frogTongueBase.png", 9)
player.tongueTip = graphics.SpriteSheet:new("frogTongueTip.png", 9)

player.Player = {}

--- Constructor.  Creates a new Player, who is a frog that can jump around.
function player.Player:new(startSpace)
  local newObj = {
    idleAnim = graphics.Animation:new(player.idleSpriteSheet),
    jumpAnim = graphics.Animation:new(player.jumpSpriteSheet),
    
    animation = nil,
    
    body = bodies.WarpBody:new(startSpace),
    
    energy = 0,
    
    eating = false,
    eatSpace = nil,  -- The space that the player is eating bugs from
    eatBody = nil,  -- The body that the player is eating bugs from
    tongueBaseAnim = graphics.Animation:new(player.tongueBase),
    tongueTipAnim = graphics.Animation:new(player.tongueTip),
  }
  newObj.jumpAnim:setFrameLength(3)
  newObj.tongueBaseAnim:setFrameLength(3)
  newObj.tongueTipAnim:setFrameLength(3)
  
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
  
  -- Rotates the sprite based on what direction the player is facing
  rotation = misc.rotationOf(self.body.moveDirection)
  
  -- Sets the amount of forwards shift of the player sprite during the moving animation
  if self.body.moving then
    previousForwardsShift = player.jumpOffsets[self.animation.frame]
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
  if self.body.moving then
    self.animation:update()
    
    if self.animation.isDone then
      self.jumpAnim:reset()
      self.animation = self.idleAnim
      self.body.moving = false
    end
    
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


return player