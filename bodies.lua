--- Handles the various entities that exist on the grid.

local graphics = require("graphics")

local bodies = {}

bodies.jumpOffsets = {0, 13, 22, 24, 24, 24}
bodies.playerIdleSpriteSheet = graphics.SpriteSheet:new("frogIdle.png", 1)
bodies.playerJumpSpriteSheet = graphics.SpriteSheet:new("frogJump.png", 6)

bodies.WarpBody = {}

function bodies.WarpBody:new(startSpace)
  local newObj = {
    space = startSpace,
    previousSpace = nil,
    moveDirection = "left",
    
    moving = false,
  }
  
  startSpace.occupiedBy = newObj
  
  self.__index = self
  return setmetatable(newObj, self)
end


--- Makes the body move to a given space.
function bodies.WarpBody:moveTo(space, direction)
  self.space.occupiedBy = nil
  space.occupiedBy = self
  
  self.previousSpace = self.space
  self.space = space
  
  self.moveDirection = direction
  self.moving = true
end


bodies.Player = {}

--- Constructor.  Creates a new Player, who is a frog that can jump around.
function bodies.Player:new(startSpace)
  local newObj = {
    idleAnim = graphics.Animation:new(bodies.playerIdleSpriteSheet),
    jumpAnim = graphics.Animation:new(bodies.playerJumpSpriteSheet),
    
    animation = nil,
    
    body = bodies.WarpBody:new(startSpace),
  }
  newObj.jumpAnim:setFrameLength(3)
  newObj.animation = newObj.idleAnim
  
  self.__index = self
  return setmetatable(newObj, self)
end


--- Makes the player move to the given space.
function bodies.Player:moveTo(space, direction)
  self.body:moveTo(space, direction)
  self.animation = self.jumpAnim
end


function bodies.Player:draw(gridXOffset, gridYOffset, scale, tileSize)
  
  local rotation = 0
  local forwardsShift
  local previousForwardsShift
  
  -- Rotates the sprite based on what direction the player is facing
  if self.body.moveDirection == "up" then
    rotation = math.pi / 2
  elseif self.body.moveDirection == "right" then
    rotation = math.pi
  elseif self.body.moveDirection == "down" then
    rotation = math.pi / 2 * 3
  end
  
  -- Sets the amount of forwards shift of the player sprite during the moving animation
  if self.body.moving then
    previousForwardsShift = bodies.jumpOffsets[self.animation.frame]
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


return bodies