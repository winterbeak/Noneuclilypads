--- A single space that can warp to cover multiple grid cells.
-- Note that spaces cannot work by themselves.  Please do not use any of the
-- below function; only interact with spaces using Grid's commands.

graphics = require("graphics")
const = require("const")
vector = require("vector")
misc = require("misc")

local spaces = {}

spaces.singlePadsSprite = graphics.SpriteSheet:new("singlePads.png", 16)
spaces.singlePadsHighlightSprite = graphics.SpriteSheet:new("singlePadsHighlighted.png", 16)

spaces.multiPadsSprite = graphics.SpriteSheet:new("multiPads.png", 15)
spaces.multiPadsHighlightSprite = graphics.SpriteSheet:new("multiPadsHighlighted.png", 15)

spaces.decorSprite = graphics.SpriteSheet:new("decor.png", 24)
spaces.decorHighlightSprite = graphics.SpriteSheet:new("decorHighlighted.png", 24)
spaces.decorShadowlessSprite = graphics.SpriteSheet:new("decorShadowlessHighlighted.png", 24)

spaces.slugSlime = graphics.SpriteSheet:new("slugSlime.png", 12)
spaces.singlePadsMask = graphics.SpriteSheet:new("singlePadsMask.png", 16)
spaces.multiPadsMask = graphics.SpriteSheet:new("multiPadsMask.png", 15)

spaces.slimeExplosions = graphics.loadMulti("slimeExplosion", 3, ".png", 4)


--- Draws a square, and its shadow if an offset is given.
-- Does not change love's graphics color.
local function drawSquare(size, x, y, shadowOffsetX, shadowOffsetY)
  
  -- Draws shadow
  if shadowOffsetX then
    local previousR, previousG, previousB, previousA = love.graphics.getColor()
    love.graphics.setColor(graphics.COLOR_WATER_SHADOW)
    
    love.graphics.rectangle("fill", x + shadowOffsetX, y + shadowOffsetY, size, size)
    
    love.graphics.setColor(previousR, previousG, previousB, previousA)
  end
  
  -- Draws the pixel itself
  love.graphics.rectangle("fill", x, y, size, size)
  
end


spaces.Space = {}

--- Constructor.  Makes a new Space at the given coordinates.
function spaces.Space:new(col, row, spriteNum, decorNum)
  local newObj = {
    cells = misc.table2D(const.MAX_GRID_W),
    adjacent = {
      left = {},
      up = {},
      right = {},
      down = {}
    },
    adjacentList = {},

    occupiedBy = nil,
    distanceFromPlayer = 0,
    
    spriteNum = spriteNum or 1,
    decorNum = decorNum or nil,
    
    slimed1 = false,
    slimed2 = false,
    slimeRotation1 = 0,
    slimeRotation2 = 0,
    slimeNum1 = 0,
    slimeNum2 = 0,
    
    exploding = false,
    explodingAnim = nil,
  }
  
  newObj.cells[col][row] = true
  
  self.__index = self
  return setmetatable(newObj, self)
end


--- Empties the adjacent spaces list.
function spaces.Space:emptyAdjacent()
  self.adjacent = {
    left = {},
    up = {},
    right = {},
    down = {}
  }
  self.adjacentList = {}
end


--- Adds the cells of another space to this one.
-- Note that the other space is not affected in any way.
function spaces.Space:mergeCells(otherSpace)
  for colNum, col in pairs(otherSpace.cells) do
    for rowNum, _ in pairs(col) do
      self.cells[colNum][rowNum] = true
    end
  end
end


--- Adds the cells of multiple other spaces to this one.
function spaces.Space:mergeCellsMultiple(spaceList)
  for index, otherSpace in pairs(spaceList) do
    for colNum, col in pairs(otherSpace.cells) do
      for rowNum, _ in pairs(col) do
        self.cells[colNum][rowNum] = true
      end
    end
  end
end


--- Returns true if the space is only 1x1.
function spaces.Space:isSingleCell()
  local foundCell = false
  local foundCellInCol
  
  -- For every column
  for colNum, col in pairs(self.cells) do
    
    foundCellInCol = false

    for rowNum, _ in pairs(col) do
      
      -- If a cell was already found in this column then return false
      if foundCellInCol then
        return false
      end
      
      foundCellInCol = true
    end
    
    -- If a cell was found in this column and also another column, return false
    if foundCellInCol and foundCell then
      return false
    end
    
    -- This messed me up for way longer than it should have
    -- Previously it was just foundCell = foundCellInCol, which sometimes
    -- sets foundCell to false even after finding a cell elsewhere
    foundCell = foundCell or foundCellInCol

  end
  
  return true
end


--- Removes a cell at the given coordinates.
-- Will throw an error if this cell is the space's only cell.
function spaces.Space:removeCell(col, row)
  if self:isSingleCell() then
    error("You tried to remove a space's only cell!  (The cell is at " .. col .. " " .. row .. ".)")
  end
  
  self.cells[col][row] = nil
end


--- Finds a cell, any cell, that the space contains, and returns its coordinates.
-- Returns two values: the first is the column number, and the second is the row number.
function spaces.Space:findACell()
  for colNum, col in pairs(self.cells) do
    for rowNum, _ in pairs(col) do
      return colNum, rowNum
    end
  end
end


--- Returns whether the space occupies a cell at the given coordinates.
function spaces.Space:isCell(col, row)
  
  -- Returns false if the cell is out of bounds
  if col <= 0 or col > const.MAX_GRID_W then
    return false
  end
  if row <= 0 or row > const.MAX_GRID_H then
    return false
  end
  
  -- Returns whether the thing at the col and row exists
  if self.cells[col][row] then
    return true
  end
  
  return false
  
end



--- Returns whether the space is occupied by something or not.
function spaces.Space:isOccupied()
  if self.occupiedBy then
    return true
  end
  
  return false
end


--- Returns the closest space to the player, that is adjacent to this one.
-- Returns nil if there are no spaces adjacent to this one.
function spaces.Space:closestAdjacent(player)
  local foundSpace = false
  local closestSpace
  
  for space, _ in pairs(self.adjacentList) do
    
    -- Ignore all already occupied spaces
    if not space:isOccupied() then
      
      -- Always prioritize the player's previous space
      if space == player.body.previousSpace then
        return space
        
      -- If this isn't the first space, compare it with the previous closest
      elseif foundSpace then
        if space.distanceFromPlayer < closestSpace.distanceFromPlayer then
          closestSpace = space
        end
      
      -- If this is the first space, it must be the closest
      else
        foundSpace = true
        closestSpace = space
      end
      
    end
    
  end
  
  return closestSpace

end


--- Returns the closest space from the player (and its direction), that isn't in a given direction.
-- Returns nil if there are no valid spaces.
function spaces.Space:closestAdjacentNotDirection(player, restrictedDirection)
  local foundSpace = false
  local closestSpace
  
  for direction, spaceList in pairs(self.adjacent) do
    if direction ~= restrictedDirection then
      for space, _ in pairs(spaceList) do
        
        -- Ignore all already occupied spaces
        if not space:isOccupied() then
          
          -- Always prioritize the player's previous space
          if space == player.body.previousSpace then
            return space, direction
          
          -- If this isn't the first space found, compare it with the previous closest
          elseif foundSpace then
            if space.distanceFromPlayer < closestSpace.distanceFromPlayer then
              closestSpace = space
            end
          
          -- If this is the first space, it must be the closest
          else
            foundSpace = true
            closestSpace = space
          end
        end
      end
    end
  end
  
  return closestSpace, direction
  
end


--- Returns the direction of a space adjacent to this one.
-- If the space is not adjacent, nil is returned.
-- If the space is touching more than one directions, then the priority order
-- is left, up, right, down.
function spaces.Space:directionOf(space)
  for direction, spaceList in pairs(self.adjacent) do
    if spaceList[space] then
      return direction
    end
  end
  
  return nil
end


--- Adds slime to the space.
-- If one of the directions is left as nil, then it will not be changed.
function spaces.Space:addSlime(direction1, direction2)
  if direction1 then
    self.slimed1 = true
    self.slimeRotation1 = misc.rotationOf(direction1)
    self.slimeNum1 = math.random(1, spaces.slugSlime.spriteCount)
  end
  
  if direction2 then
    self.slimed2 = true
    self.slimeRotation2 = misc.rotationOf(direction2)
    self.slimeNum2 = math.random(1, spaces.slugSlime.spriteCount)
  end
end


--- Removes slime from the space.
-- If one of the directions is left as nil, then it will not be changed.
function spaces.Space:removeSlime(direction1, direction2)
  if direction1 then
    self.slimed1 = false
  end
  
  if direction2 then
    self.slimed2 = false
  end
end


--- Plays the slime exploding animation on this space.
function spaces.Space:explodeSlime()
  local explosion = spaces.slimeExplosions[math.random(1, #spaces.slimeExplosions)]
  self.exploding = true
  self.explodingAnim = graphics.Animation:new(explosion)
  self.explodingAnim:setFrameLength(3)
end


--- Draws the space.
-- gridX and gridY are the pixel coordinates of the top left of the space's grid.
-- scale is how big to scale the art.
function spaces.Space:draw(gridX, gridY, scale, shadowOffsetX, shadowOffsetY, isSelected)
  local x
  local y
  local decorSheet
  local spriteSheet
  local spriteNum
  local cellSize = spaces.singlePadsSprite.width * scale
  
  -- Draws a single cell space
  if self:isSingleCell() then
    local col, row = self:findACell()
    
    spriteNum = self.spriteNum
    
    -- Changes the spritesheet depending on whether the lillypad is highlighted
    if isSelected then
      spriteSheet = spaces.singlePadsHighlightSprite
      
      if shadowOffsetX == 0 and shadowOffsetY == 0 then
        decorSheet = spaces.decorShadowlessSprite
      else
        decorSheet = spaces.decorHighlightSprite
      end
      
    else
      spriteSheet = spaces.singlePadsSprite
      decorSheet = spaces.decorSprite
      
    end
    
    -- Calculates the position to draw the top left of the sprite
    x = gridX + (cellSize * (col - 1))
    y = gridY + (cellSize * (row - 1))
    
    -- Draws the shadow
    love.graphics.setColor(graphics.COLOR_WATER_SHADOW)
    spriteSheet:draw(spriteNum, x + shadowOffsetX, y + shadowOffsetY, scale)
    
    -- Draws the sprite itself
    love.graphics.setColor(graphics.COLOR_WHITE)
    spriteSheet:draw(spriteNum, x, y, scale)
    
    -- Draws the pad's slime
    if self.slimed1 or self.slimed2 then
      
      -- Stencils the sprite so that it is only drawn on the pad and not in the water
      love.graphics.stencil(function()
          love.graphics.setShader(graphics.mask_shader)
          spaces.singlePadsMask:draw(spriteNum, x, y, scale)
          love.graphics.setShader()
          end,
          
          "replace", 1)
      love.graphics.setStencilTest("greater", 0)
      
      
      if self.slimed1 then
        spaces.slugSlime:draw(self.slimeNum1, x, y, scale, self.slimeRotation1)
      end
      
      if self.slimed2 then
        spaces.slugSlime:draw(self.slimeNum2, x, y, scale, self.slimeRotation2)
      end
      
      love.graphics.setStencilTest()
    end
    
    
    -- Draws the sprite's decor
    if self.decorNum then
      decorSheet:draw(self.decorNum, x, y, scale)
    end
    
    -- If the space has exploding slime, draw it
    if self.exploding then
      self.explodingAnim:draw(x, y, scale)
    end
    
  
  -- Draws a multicell space
  else
    local lillypadColor
    local lillypadShadowColor
    local spriteId
    local left
    local up
    local right
    local down
    local pixel = scale
    
    -- Changes the draw colors and spritesheets, depending on whether the lillypad is highlighted
    if isSelected then
      spriteSheet = spaces.multiPadsHighlightSprite
      lillypadColor = graphics.COLOR_LILLYPAD_HIGHLIGHT
      lillypadShadowColor = graphics.COLOR_LILLYPAD_SHADOW_HIGHLIGHT
      lillypadOutlineColor = graphics.COLOR_LILLYPAD_OUTLINE_HIGHLIGHT
    else
      spriteSheet = spaces.multiPadsSprite
      lillypadColor = graphics.COLOR_LILLYPAD
      lillypadShadowColor = graphics.COLOR_LILLYPAD_SHADOW
      lillypadOutlineColor = graphics.COLOR_LILLYPAD_OUTLINE
    end
    
    -- Loop through every cell in this space
    for colNum, col in pairs(self.cells) do
      for rowNum, _ in pairs(col) do
        
        -- Determines if there is a cell in each direction
        left = self:isCell(colNum - 1, rowNum)
        up = self:isCell(colNum, rowNum - 1)
        right = self:isCell(colNum + 1, rowNum)
        down = self:isCell(colNum, rowNum + 1)
        
        -- Calculates the position to draw the top left of the sprite
        x = gridX + (cellSize * (colNum - 1))
        y = gridY + (cellSize * (rowNum - 1))
        
        -- The spritenum can be represented by a four bit integer.
        -- A bit is 1 if there is a cell in that direction, or 0 otherwise.
        spriteNum = misc.toBits({left, up, right, down})
        
        -- Draws shadow

        love.graphics.setColor(graphics.COLOR_WATER_SHADOW)
        
        local shadowX = x + shadowOffsetX
        local shadowY = y + shadowOffsetY
        local shadowOffsetXPixels = shadowOffsetX / pixel
        local shadowOffsetYPixels = shadowOffsetY / pixel
        local leftCrop = 0
        local upCrop = 0
        local rightCrop = 0
        local downCrop = 0
        
        -- If there's a lillypad below, only draw the right side of the shadow
        if down then
          leftCrop = spaces.singlePadsSprite.width - shadowOffsetXPixels - 2
          
          if self:isCell(colNum + 1, rowNum + 1) then
            downCrop = 2
          end
          
        end
        
        -- If there's a lillypad to the right, only draw the bottom of the shadow
        if right then
          upCrop = spaces.singlePadsSprite.singleHeight - shadowOffsetYPixels - 2
          
          if self:isCell(colNum + 1, rowNum + 1) then
            rightCrop = 2
          end
          
        end
          
        spriteSheet:drawPartial(spriteNum, shadowX, shadowY, leftCrop, upCrop, rightCrop, downCrop, scale)
        
        -- Draws the sprite
        love.graphics.setColor(graphics.COLOR_WHITE)
        spriteSheet:draw(spriteNum, x, y, scale)
        
        -- Draws the pad's slime
        if self.slimed1 or self.slimed2 then
          
          -- Stencils the sprite so that it is only drawn on the pad and not in the water
          love.graphics.stencil(function()
              love.graphics.setShader(graphics.mask_shader)
              spaces.multiPadsMask:draw(spriteNum, x, y, scale)
              love.graphics.setShader()
              end,
              
              "replace", 1)
          love.graphics.setStencilTest("greater", 0)
          
          if self.slimed1 then
            spaces.slugSlime:draw(self.slimeNum1, x, y, scale, self.slimeRotation1)
          end
          
          if self.slimed2 then
            spaces.slugSlime:draw(self.slimeNum2, x, y, scale, self.slimeRotation2)
          end
          
          love.graphics.setStencilTest()
        end

        -- Draws the corner edge cases, pixel by pixel
        -- This is kinda dumb but i don't want to make more functions that pass around
        -- a million different parameters
        
        -- scale in all below cases represents one pixel
        
        shadowOffset = scale*2
        
        love.graphics.setColor(lillypadOutlineColor)

        -- Top left corner
        if left and up then
          if not self:isCell(colNum - 1, rowNum - 1) then
            drawSquare(pixel, x, y)
            drawSquare(pixel, x + pixel, y)
            drawSquare(pixel, x, y + pixel)
          end
        
        elseif left then
          if self:isCell(colNum - 1, rowNum - 1) then
            drawSquare(pixel, x, y + pixel)
            drawSquare(pixel, x + pixel, y + pixel)
            
            love.graphics.setColor(lillypadColor)
            drawSquare(pixel, x, y + pixel*2)
          end
        
        elseif up then
          if self:isCell(colNum - 1, rowNum - 1) then
            drawSquare(pixel, x + pixel, y)
            drawSquare(pixel, x + pixel, y + pixel)
            
            love.graphics.setColor(lillypadColor)
            drawSquare(pixel, x + pixel*2, y)
          end
        end
        
        love.graphics.setColor(lillypadOutlineColor)
        
        -- Top right corner
        if right and up then
          if not self:isCell(colNum + 1, rowNum - 1) then
            drawSquare(pixel, x + cellSize - pixel, y + pixel)
            drawSquare(pixel, x + cellSize - pixel, y)
            drawSquare(pixel, x + cellSize - pixel*2, y)
            
            love.graphics.setColor(lillypadColor)
            drawSquare(pixel, x + cellSize - pixel*3, y)
            drawSquare(pixel, x + cellSize - pixel*2, y + pixel)
          end
        
        elseif right then
          if self:isCell(colNum + 1, rowNum - 1) then
            drawSquare(pixel, x + cellSize - pixel, y + pixel)
            drawSquare(pixel, x + cellSize - pixel*2, y + pixel)
            
            love.graphics.setColor(lillypadColor)
            drawSquare(pixel, x + cellSize - pixel, y + pixel*2)
          end
        
        elseif up then
          if self:isCell(colNum + 1, rowNum - 1) then
            drawSquare(pixel, x + cellSize - pixel*2, y, shadowOffsetX, shadowOffsetY)
            drawSquare(pixel, x + cellSize - pixel*2, y + pixel, shadowOffsetX, shadowOffsetY)
            
            love.graphics.setColor(lillypadShadowColor)
            drawSquare(pixel, x + cellSize - pixel*3, y)
          end
        end
        
        love.graphics.setColor(lillypadOutlineColor)
        
        -- Bottom right corner
        if right and down then
          if not self:isCell(colNum + 1, rowNum + 1) then
            drawSquare(pixel, x + cellSize - pixel*2, y + cellSize - pixel)
            drawSquare(pixel, x + cellSize - pixel, y + cellSize - pixel)
            drawSquare(pixel, x + cellSize - pixel, y + cellSize - pixel*2)
            
            love.graphics.setColor(lillypadShadowColor)
            drawSquare(pixel, x + cellSize - scale, y + cellSize - scale*3)
            drawSquare(pixel, x + cellSize - scale*2, y + cellSize - scale*3)
            drawSquare(pixel, x + cellSize - scale*2, y + cellSize - scale*2)
            drawSquare(pixel, x + cellSize - scale*3, y + cellSize - scale*2)
            drawSquare(pixel, x + cellSize - scale*3, y + cellSize - scale)
            
          end
        
        elseif right then
          if self:isCell(colNum + 1, rowNum + 1) then
            drawSquare(pixel, x + cellSize - scale*2, y + cellSize - scale*2, shadowOffsetX, shadowOffsetY)
            drawSquare(pixel, x + cellSize - scale, y + cellSize - scale*2)
            
            love.graphics.setColor(lillypadColor)
            drawSquare(pixel, x + cellSize - scale, y + cellSize - scale*4)
            
            love.graphics.setColor(lillypadShadowColor)
            drawSquare(pixel, x + cellSize - scale, y + cellSize - scale*3)
          end
        
        elseif down then
          if self:isCell(colNum + 1, rowNum + 1) then
            drawSquare(pixel, x + cellSize - scale*2, y + cellSize - scale*2, shadowOffsetX, shadowOffsetY)
            drawSquare(pixel, x + cellSize - scale*2, y + cellSize - scale)
            
            love.graphics.setColor(lillypadColor)
            drawSquare(pixel, x + cellSize - scale*4, y + cellSize - scale)
            
            love.graphics.setColor(lillypadShadowColor)
            drawSquare(pixel, x + cellSize - scale*3, y + cellSize - scale)
          end
        end
        
        love.graphics.setColor(lillypadOutlineColor)
        
        -- Bottom left corner
        if left and down then
          if not self:isCell(colNum - 1, rowNum + 1) then
            drawSquare(pixel, x, y + cellSize - pixel*2)
            drawSquare(pixel, x, y + cellSize - pixel)
            drawSquare(pixel, x + pixel, y + cellSize - pixel)
            
            love.graphics.setColor(lillypadShadowColor)
            drawSquare(pixel, x, y + cellSize - pixel*3)
            drawSquare(pixel, x + pixel, y + cellSize - pixel*2)
            
          end
        
        elseif left then
          if self:isCell(colNum - 1, rowNum + 1) then
            drawSquare(pixel, x, y + cellSize - pixel*2, shadowOffsetX, shadowOffsetY)
            drawSquare(pixel, x + pixel, y + cellSize - pixel*2, shadowOffsetX, shadowOffsetY)
            
            love.graphics.setColor(lillypadShadowColor)
            drawSquare(pixel, x, y + cellSize - pixel*3)
          end
        
        elseif down then
          if self:isCell(colNum - 1, rowNum + 1) then
            drawSquare(pixel, x + pixel, y + cellSize - pixel*2)
            drawSquare(pixel, x + pixel, y + cellSize - pixel)
            
            love.graphics.setColor(lillypadColor)
            drawSquare(pixel, x + pixel*2, y + cellSize - pixel)
          end
        end
        
        love.graphics.setColor(graphics.COLOR_WHITE)
        
        -- If the space has exploding slime, draw it
        if self.exploding then
          self.explodingAnim:draw(x, y, scale)
        end
        
      end
    end
  end
  
end


--- Updates the space.
function spaces.Space:update()
  if self.exploding then
    self.explodingAnim:update()
    
    if self.explodingAnim.isDone then
      self.exploding = false
      self.explodingAnim = nil
    end
    
  end
end


--- Prints the coordinates of all the cells this space covers.
function spaces.Space:printCells()
  for colNum, col in pairs(self.cells) do
    for rowNum, _ in pairs(col) do
      print(colNum, rowNum)
    end
  end
  
  print()
end


return spaces
