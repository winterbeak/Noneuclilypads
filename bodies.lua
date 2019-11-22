--- Handles the various entities that exist on the grid.

local graphics = require("graphics")
local misc = require("misc")

local bodies = {}

local SNAKE_LENGTH = 5

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
    
    flyCount = 0
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
    
    energy = 0
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


bodies.Rat = {}

--- Constructor.  Makes a rat enemy.
-- This enemy always waits a turn, then moves closer to the player, repeatedly.
function bodies.Rat:new(startSpace)
  local newObj = {
    moveTimer = 0,
    animation = nil,
    
    body = bodies.WarpBody:new(startSpace),
  }
  
  newObj.body.flyCount = 3
  
  self.__index = self
  return setmetatable(newObj, self)
end


--- Makes the rat move.
-- Rats always move one space closer to the player.
function bodies.Rat:move(player)
  local closestSpace = self.body.space:closestAdjacent(player)
  
  if closestSpace then
    self.body:moveTo(closestSpace, self.body.space:directionOf(closestSpace))
    
  -- If no valid space was found then
  else
    -- Play the "can't move" animation
  end
    
end


--- Makes the rat take a turn.
-- Rats always wait one turn, then move one space closer to the player.
function bodies.Rat:takeTurn(level, player)
  self.moveTimer = self.moveTimer + 1
  if self.moveTimer == 2 then
    
    -- If the rat is beside the player, hurt them
    if self.body.space.distanceFromPlayer == 1 then
      
    -- Otherwise, just move normally
    else
      self:move(player)
    end
    
    self.moveTimer = 0
  end
end


--- Draws the rat.
function bodies.Rat:draw(gridXOffset, gridYOffset, scale, tileSize)
  for colNum, col in pairs(self.body.space.cells) do
    for rowNum, _ in pairs(col) do
      
      x = gridXOffset + ((colNum - 1) * tileSize)
      y = gridYOffset + ((rowNum - 1) * tileSize)
      
      love.graphics.rectangle("fill", x, y, tileSize, tileSize)
      love.graphics.setColor(graphics.COLOR_BLACK)
      love.graphics.print("" .. self.body.flyCount, x, y)
      love.graphics.setColor(graphics.COLOR_WHITE)
    end
  end
end


bodies.Snake = {}

--- Constructor.  Makes a snake enemy.
-- The snake enemy consists of 5 segments.
-- The enemy always waits two turns, then moves closer to the player.
function bodies.Snake:new(spaceList)
  local newObj = {
    moveTimer = 0,
    animation = nil,
    
    bodyList = {}
  }
  
  for i = 1, SNAKE_LENGTH do
    newObj.bodyList[i] = bodies.WarpBody:new(spaceList[i])
    newObj.bodyList[i].flyCount = 1
  end
  
  self.__index = self
  return setmetatable(newObj, self)
end


--- Constructor.  Makes a snake enemy, with random spaces spreading out from a starting location.
-- Returns nil if a valid snake could not be generated.
function bodies.Snake:newRandom(startSpace)
  local spaceList
  
  local checkSpace
  local isValidSpace = false
  
  local fullRerolls = 0
  local snakeIsValid = false
  local spaceRerolls
  local spaceFound = false
  
  local adjacentLength
  
  -- Loops until a valid snake is returned
  while true do
    
    -- If 25 full-snake rerolls occur, then a valid snake could not be generated.
    if fullRerolls > 25 then
      print("Could not generate a snake here!")
      return nil
    else
      -- The snake is valid, until proven otherwise
      snakeIsValid = true
      fullRerolls = fullRerolls + 1
    end
    
    -- Generates all the body sections (except the first, since that's the startSpace)
    spaceList = {startSpace}
    for i = 2, SNAKE_LENGTH do
      
      -- Loops until a valid space for the next part of the snake is found
      spaceRerolls = 0
      isValidSpace = false
      while not isValidSpace do
        
        -- If 25 rerolls occur, then the snake probably trapped itself during generation.
        if spaceRerolls > 25 then
          spaceFound = false
          break
        else
          -- The space is valid, until proven otherwise
          isValidSpace = true
          spaceFound = true
          spaceRerolls = spaceRerolls + 1
        end
        
        -- Randomly chooses one of the adjacent spaces
        checkSpace = misc.randomChoice(spaceList[i - 1].adjacentList)
        
        -- If there are no adjacent spaces, randomChoice returns nil
        if not checkSpace then
          isValidSpace = false
          
        else
        
          -- Checks if anything is on the space
          if checkSpace:isOccupied() then
            isValidSpace = false
          end
          
          -- Checks if the space is the same as a previous space
          for j = 1, i - 1 do
            if checkSpace == spaceList[j] then
              isValidSpace = false
              break
            end
          end
          
        end
        
      end
      
      -- If one of the spaces could not be found, reroll the whole snake
      if not spaceFound then
        snakeIsValid = false
        break
        
      -- Otherwise, set this space as the next space in the list
      else
        spaceList[i] = checkSpace
        
      end
      
    end
    
    -- Return the snake if all the spaces were generated validly.
    if snakeIsValid then
      return self:new(spaceList)
    end
    
    -- Otherwise, go back to the start of the while loop and reroll the entire snake.
    
  end
end


--- Makes the snake move.
-- The head of the snake always moves one step closer to the player.
-- The rest of the parts follow the part before it.
function bodies.Snake:move(player)
  local closestSpace = self.bodyList[1].space:closestAdjacent(player)
  local direction
  local previousSpace
  local nextSpace = closestSpace
  
  if closestSpace then
    
    -- For each snake part, move to the next space.
    -- The next space for the head is the closest adjacent space to the player.
    -- The next space for all the other parts is the original space of the previous part.
    for index, body in pairs(self.bodyList) do
      previousSpace = body.space
      direction = previousSpace:directionOf(nextSpace)
      body:moveTo(nextSpace, direction)
      nextSpace = previousSpace
    end
    
  -- If no valid space was found then
  else
    -- Play the "can't move" animation
  end
    
end


--- Makes the snake take a turn.
-- Snakes always wait two turns, then move closer to the player.
function bodies.Snake:takeTurn(level, player)
  self.moveTimer = self.moveTimer + 1
  if self.moveTimer == 3 then
    
    -- If the snake is beside the player, hurt them
    if self.bodyList[1].space.distanceFromPlayer == 1 then
      
    -- Otherwise, just move normally
    else
      self:move(player)
    end
    
    self.moveTimer = 0
  end
end
  

--- Draws the snake.
function bodies.Snake:draw(gridXOffset, gridYOffset, scale, tileSize)
  local color
  
  for index, body in pairs(self.bodyList) do
    for colNum, col in pairs(body.space.cells) do
      for rowNum, _ in pairs(col) do
        
        x = gridXOffset + ((colNum - 1) * tileSize)
        y = gridYOffset + ((rowNum - 1) * tileSize)
        
        color = {1 - (index * 0.1), 1 - (index * 0.1), 0}
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", x, y, tileSize, tileSize)
        love.graphics.setColor(graphics.COLOR_BLACK)
        love.graphics.print("" .. body.flyCount, x, y)
        love.graphics.setColor(graphics.COLOR_WHITE)
        
      end
    end
  end
end


bodies.Snail = {}

--- Constructor.  Makes a snail enemy.
-- The snail is similar to the Rat in that it waits a turn, then moves closer to the player.
-- However, the snail will add slime to every space it moves off of.  After three moves,
-- instead of moving a fourth time, the snail will pause to merge all the slimed spaces.
function bodies.Snail:new(startSpace)
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


--- Makes the snail move.
-- Snails always move one space closer to the player.
function bodies.Snail:move(player)
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


--- Merges all of the snail's slimed spaces.
-- If a space is occupied, it will NOT be merged.
function bodies.Snail:mergeSlimed(level)
  
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


--- Makes the snail take a turn.
-- Smails will wait a turn, the move closer to the player.
-- The snail adds slime to every space it moves off of.
-- After three moves, instead of moving a fourth time, the snail will pause
-- to merge all the slimed spaces.
function bodies.Snail:takeTurn(level, player)
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
  

--- Draws the snake.
function bodies.Snail:draw(gridXOffset, gridYOffset, scale, tileSize)
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


return bodies