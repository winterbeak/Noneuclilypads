graphics = require("graphics")
bodies = require("bodies")
misc = require("misc")

local slug = {}


slug.Slug = {}

--- Constructor.  Makes a Slug enemy.
-- The Slug is similar to the Rat in that it waits a turn, then moves closer to the player.
-- However, the Slug will add slime to every space it moves off of.  After three moves,
-- instead of moving a fourth time, the Slug will pause to merge all the slimed spaces.
function slug.Slug:new(startSpace)
  local newObj = {
    moveTimer = 0,
    animation = nil,
    
    body = bodies.WarpBody:new(startSpace),
    slimedSpaces = {}
  }
  
  newObj.body.flyCount = 5
  
  self.__index = self
  return setmetatable(newObj, self)
end


--- Makes the slug move.
-- Slugs always move one space closer to the player.
function slug.Slug:move(player)
  local previousSpace = self.body.space
  local closestSpace = self.body.space:closestAdjacent(player)
  
  if closestSpace then
    self.body:moveTo(closestSpace, self.body.space:directionOf(closestSpace))
    table.insert(self.slimedSpaces, previousSpace)
    
  -- If no valid space was found then
  else
    -- Play the "can't move" animation
  end
    
end


--- Merges all of the slug's slimed spaces.
-- If a space is occupied, it will NOT be merged.
function slug.Slug:mergeSlimed(level)
  
  -- Removes any spaces that are occupied
  for i = 1, #self.slimedSpaces do
    if self.slimedSpaces[i] then
      if self.slimedSpaces[i]:isOccupied() then
        table.remove(self.slimedSpaces, i)
      end
    end
  end
  
  -- Merges any remaining spaces
  level:mergeMulti(self.slimedSpaces)
  self.slimedSpaces = {}
  level:refreshAllAdjacent()
end


--- Makes the slug take a turn.
-- Slugs will wait a turn, then move closer to the player.
-- The slug adds slime to every space it moves off of.
-- After three moves, instead of moving a fourth time, the slug will pause
-- to merge all the slimed spaces.
function slug.Slug:takeTurn(level, player)
  self.moveTimer = self.moveTimer + 1
  
  -- On the fourth move, merge all slimed spaces.
  if self.moveTimer == 8 then
    self:mergeSlimed(level)
    self.moveTimer = 0
    
  -- Move every other turn.
  elseif self.moveTimer % 2 == 0 then

    -- If the snail is beside the player, hurt them
    if self.body.space.distanceFromPlayer == 1 then
      
    -- Otherwise, just move normally
    else
      self:move(player)
    end

  end
end
  

--- Draws the slug.
function slug.Slug:draw(gridXOffset, gridYOffset, scale, tileSize)
  love.graphics.setColor(100, 0, 100)
  
  -- Draws the slime
  -- To be moved to spaces:draw, using stencils to draw the path
  for index, space in pairs(self.slimedSpaces) do
    for colNum, col in pairs(space.cells) do
      for rowNum, _ in pairs(col) do
          
        x = gridXOffset + ((colNum - 1) * tileSize) + 20
        y = gridYOffset + ((rowNum - 1) * tileSize) + 20
          
        love.graphics.rectangle("fill", x, y, tileSize - 40, tileSize - 40)

      end
    end
  end
  
  -- Draws the snail
  for colNum, col in pairs(self.body.space.cells) do
    for rowNum, _ in pairs(col) do
        
      x = gridXOffset + ((colNum - 1) * tileSize)
      y = gridYOffset + ((rowNum - 1) * tileSize)
      
      love.graphics.setColor(255, 0, 0)
      love.graphics.rectangle("fill", x, y, tileSize, tileSize)
      love.graphics.setColor(graphics.COLOR_BLACK)
      love.graphics.print("" .. self.body.flyCount, x, y)
      love.graphics.setColor(graphics.COLOR_WHITE)
      
    end
  end
end

--- Updates the slug's animation.  Should be called every frame.
function slug.Slug:updateAnimation()
  
end


return slug