--- Handles the various bodies that exist on the grid.

graphics = require("graphics")
misc = require("misc")

local bodies = {}


bodies.Flea = {}

--- Constructor.  Creates a new Flea, which is a bug that likes being on the ground.
function bodies.Flea:new(startSpace)
  local newObj = {
    space = startSpace,
    previousSpace = nil,
    moving = false,
    moveDirection = "left",
    
    xOffset = math.random(5, 19),
    yOffset = math.random(5, 19),
    
    wingX = 0,
    wingY = 0,
    
    targetX = 0,
    targetY = 0,
    
    atTarget = true,
  }
  
  if math.random(1, 2) == 1 then
    newObj.wingX = -1
    newObj.wingY = -1
  else
    newObj.wingX = 1
    newObj.wingY = -1
  end
  
  self.__index = self
  return setmetatable(newObj, self)
end


--- Makes the flea move towards the given x and y.
-- Note that the x and y are measured in scaled pixels.
function bodies.Flea:changeTarget(x, y)
  self.atTarget = false
  self.targetX = x
  self.targetY = y
end


--- Makes the flea's wings randomly move.
function bodies.Flea:moveWings()
  
  -- If the wing is horizontally aligned, move it up or down
  if math.random(1, 2) == 1 then
    self.wingX = -1
    self.wingY = -1
  else
    self.wingX = 1
    self.wingY = -1
  end
  
end


function bodies.Flea:moveTo(space, direction)
  self.previousSpace = self.space
  self.space = space
  self.moving = true
  
  self.targetX = math.random(5, 19)
  self.targetY = math.random(5, 19)
  
  if direction == "left" then
    self.targetX = self.targetX - 24
  elseif direction == "up" then
    self.targetY = self.targetY - 24
  elseif direction == "right" then
    self.targetX = self.targetX + 24
  elseif direction == "left" then
    self.targetY = self.targetY + 24
  end
end



--- Updates the flea.
-- Currently, this makes the flea move towards its target,
-- and sometimes randomly makes it change target.
function bodies.Flea:update()

  -- 1 in 300 chance every frame to change targets
  if self.atTarget then
    
    if math.random(1, 300) == 1 then
      self:changeTarget(math.random(5, 19), math.random(5, 19))
    end
  
  -- Moves towards a target
  else
    self.xOffset = self.xOffset + ((self.targetX - self.xOffset) / 20)
    self.yOffset = self.yOffset + ((self.targetY - self.yOffset) / 20)
    
    self.xOffset = self.xOffset + (math.random(-1, 1) / 5)
    self.yOffset = self.yOffset + (math.random(-1, 1) / 5)
    
    -- Snaps the flea to the target if it is close enough to it
    if math.abs(self.xOffset - self.targetX) < 0.5 then
      if math.abs(self.yOffset - self.targetY) < 0.5 then
        self.xOffset = self.targetX
        self.yOffset = self.targetY
        self.atTarget = true
      end
    end
    
    -- Randomly changes the fly's wings
    if math.random(1, 3) == 1 then
      self:moveWings()
    end
    
  end
end


--- Draws the flea.
function bodies.Flea:draw(gridXOffset, gridYOffset, scale, tileSize)
  local x
  local y
  
  local wingX
  local wingY
  
  for colNum, col in pairs(self.space.cells) do
    for rowNum, _ in pairs(col) do
      
      x = gridXOffset + ((colNum - 1) * tileSize) + (math.floor(self.xOffset) * scale)
      y = gridYOffset + ((rowNum - 1) * tileSize) + (math.floor(self.yOffset) * scale)
      
      -- Draws the corners
      love.graphics.setColor(0.2, 0.2, 0.2, 0.65)

      wingX = x + (self.wingX * scale)
      wingY = y + (self.wingY * scale)
      love.graphics.rectangle("fill", wingX, wingY, scale, scale)
      
      wingX = x - (self.wingX * scale)
      wingY = y - (self.wingY * scale)
      love.graphics.rectangle("fill", wingX, wingY, scale, scale)
      
      -- Draws the plus-shaped black part
      love.graphics.rectangle("fill", x - scale, y, scale, scale)
      love.graphics.rectangle("fill", x, y - scale, scale, scale)
      love.graphics.rectangle("fill", x + scale, y, scale, scale)
      love.graphics.rectangle("fill", x, y + scale, scale, scale)
      
      -- Draws the center white part
      love.graphics.setColor(0.95, 0.95, 0.95)
      love.graphics.rectangle("fill", x, y, scale, scale)

    end
  end
  
  love.graphics.setColor(graphics.COLOR_WHITE)
end



bodies.WarpBody = {}

function bodies.WarpBody:new(startSpace)
  local newObj = {
    space = startSpace,
    previousSpace = nil,
    moveDirection = "left",
    
    moving = false,
    
    bugs = {}
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


--- Adds a certain amount of fleas to the body.
function bodies.WarpBody:addFleas(count)
  for i = 1, count do
    table.insert(self.bugs, bodies.Flea:new(self.space))
  end
end


--- Removes a certain amount of bugs from the body.
function bodies.WarpBody:removeBugs(count)
  for i = 1, count do
    if #self.bugs <= 0 then
      error("Tried to remove more bugs than this body has!")
    end
    
    table.remove(self.bugs)
  end
end


--- Updates all of the body's bugs.
function bodies.WarpBody:updateBugs()
  for i = 1, #self.bugs do
    self.bugs[i]:update()
  end
end


--- Draws all of the body's bugs.
function bodies.WarpBody:drawBugs(gridXOffset, gridYOffset, scale, tileSize)
  for i = 1, #self.bugs do
    self.bugs[i]:draw(gridXOffset, gridYOffset, scale, tileSize)
  end
end


return bodies