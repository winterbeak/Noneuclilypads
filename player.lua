graphics = require("graphics")
bodies = require("bodies")
misc = require("misc")

local player = {}

player.jumpOffsets = {0, 13, 22, 24, 24, 24}
player.idleSpriteSheet = graphics.SpriteSheet:new("frogIdle.png", 1)
player.jumpSpriteSheet = graphics.SpriteSheet:new("frogJump.png", 6)


player.Player = {}

--- Constructor.  Creates a new Player, who is a frog that can jump around.
function player.Player:new(startSpace)
  local newObj = {
    idleAnim = graphics.Animation:new(player.idleSpriteSheet),
    jumpAnim = graphics.Animation:new(player.jumpSpriteSheet),
    
    animation = nil,
    
    body = bodies.WarpBody:new(startSpace),
    
    energy = 0
  }
  newObj.jumpAnim:setFrameLength(3)
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

end


--- Updates the player's animation.  Should be called every frame.
function player.Player:updateAnimation()
  if self.body.moving then
    self.animation:update()
  end
  
  if self.animation.isDone then
    self.jumpAnim:reset()
    self.animation = self.idleAnim
    self.body.moving = false
  end
end


return player