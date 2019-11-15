--- A single space that can warp to cover multiple grid cells.
-- Note that spaces cannot work by themselves.  Please do not use any of the
-- below function; only interact with spaces using Grid's commands.

local graphics = require("graphics")
local const = require("const")
local vector = require("vector")
local misc = require("misc")

local spaces = {}

spaces.singlePadsSprite = graphics.SpriteSheet:new("singlePads.png", 16)
spaces.multiPadsSprite = graphics.SpriteSheet:new("multiPads.png", 15)

spaces.Space = {}

--- Constructor.  Makes a new Space at the given coordinates.
function spaces.Space:new(col, row, spriteNum)
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
    
    spriteNum = spriteNum or 0
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
    
    foundCell = foundCellInCol

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


--- Draws the space.
-- gridX and gridY are the pixel coordinates of the top left of the space's grid.
-- scale is how big to scale the art.
function spaces.Space:draw(gridX, gridY, scale)
  local x
  local y
  local cellSize = spaces.singlePadsSprite.width * scale
  
  -- Draws a single cell space
  if self:isSingleCell() then
    local col, row = self:findACell()
    
    x = gridX + (cellSize * (col - 1))
    y = gridY + (cellSize * (row - 1))

    spaces.singlePadsSprite:draw(self.spriteNum, x, y, scale)
    
  -- Draws a multicell space
  else
    local spriteId
    local left
    local up
    local right
    local down
    
    for colNum, col in pairs(self.cells) do
      for rowNum, _ in pairs(col) do
        
        left = self:isCell(colNum - 1, rowNum)
        up = self:isCell(colNum, rowNum - 1)
        right = self:isCell(colNum + 1, rowNum)
        down = self:isCell(colNum, rowNum + 1)
        
        x = gridX + (cellSize * (colNum - 1))
        y = gridY + (cellSize * (rowNum - 1))
        
        -- The spritenum can be represented by a four bit integer.
        -- A bit is 1 if there is a cell in that direction, or 0 otherwise.
        spriteNum = misc.toBits({left, up, right, down})

        spaces.multiPadsSprite:draw(spriteNum, x, y, scale)
        
        -- Draws the corner edge cases, pixel by pixel
        -- This is kinda dumb but i don't want to make more functions that pass around
        -- a million different parameters
        
        -- scale in all below cases represents one pixel
        
        graphics.setColor(graphics.COLOR_BLACK)

        -- Top left corner
        if left and up then
          if not self:isCell(colNum - 1, rowNum - 1) then
            love.graphics.rectangle("fill", x, y, scale*2, scale)
            love.graphics.rectangle("fill", x, y + scale, scale, scale)
          end
        
        elseif left then
          if self:isCell(colNum - 1, rowNum - 1) then
            love.graphics.rectangle("fill", x, y + scale, scale*2, scale)
            graphics.setColor(graphics.COLOR_LILLYPAD)
            love.graphics.rectangle("fill", x, y + scale*2, scale, scale)
          end
        
        elseif up then
          if self:isCell(colNum - 1, rowNum - 1) then
            love.graphics.rectangle("fill", x + scale, y, scale, scale*2)
            graphics.setColor(graphics.COLOR_LILLYPAD)
            love.graphics.rectangle("fill", x + scale*2, y, scale, scale)
          end
        end
        
        graphics.setColor(graphics.COLOR_BLACK)
        
        -- Top right corner
        if right and up then
          if not self:isCell(colNum + 1, rowNum - 1) then
            love.graphics.rectangle("fill", x + cellSize - scale*2, y, scale*2, scale)
            love.graphics.rectangle("fill", x + cellSize - scale, y + scale, scale, scale)
            graphics.setColor(graphics.COLOR_LILLYPAD_SHADOW)
            love.graphics.rectangle("fill", x + cellSize - scale*3, y, scale, scale)
            love.graphics.rectangle("fill", x + cellSize - scale*2, y + scale, scale, scale)
          end
        
        elseif right then
          if self:isCell(colNum + 1, rowNum - 1) then
            love.graphics.rectangle("fill", x + cellSize - scale*2, y + scale, scale*2, scale)
            graphics.setColor(graphics.COLOR_LILLYPAD)
            love.graphics.rectangle("fill", x + cellSize - scale, y + scale*2, scale, scale)
          end
        
        elseif up then
          if self:isCell(colNum + 1, rowNum - 1) then
            love.graphics.rectangle("fill", x + cellSize - scale*2, y, scale, scale*2)
            graphics.setColor(graphics.COLOR_LILLYPAD_SHADOW)
            love.graphics.rectangle("fill", x + cellSize - scale*3, y, scale, scale)
          end
        end
        
        graphics.setColor(graphics.COLOR_BLACK)
        
        -- Bottom right corner
        if right and down then
          if not self:isCell(colNum + 1, rowNum + 1) then
            love.graphics.rectangle("fill", x + cellSize - scale*2, y + cellSize - scale, scale*2, scale)
            love.graphics.rectangle("fill", x + cellSize - scale, y + cellSize - scale*2, scale, scale)
            graphics.setColor(graphics.COLOR_LILLYPAD_SHADOW)
            love.graphics.rectangle("fill", x + cellSize - scale*2, y + cellSize - scale*3, scale*2, scale)
            love.graphics.rectangle("fill", x + cellSize - scale*2, y + cellSize - scale*2, scale, scale)
            love.graphics.rectangle("fill", x + cellSize - scale*3, y + cellSize - scale*2, scale, scale*2)
            
          end
        
        elseif right then
          if self:isCell(colNum + 1, rowNum + 1) then
            love.graphics.rectangle("fill", x + cellSize - scale*2, y + cellSize - scale*2, scale*2, scale)
            graphics.setColor(graphics.COLOR_LILLYPAD)
            love.graphics.rectangle("fill", x + cellSize - scale, y + cellSize - scale*4, scale, scale)
            graphics.setColor(graphics.COLOR_LILLYPAD_SHADOW)
            love.graphics.rectangle("fill", x + cellSize - scale, y + cellSize - scale*3, scale, scale)
          end
        
        elseif down then
          if self:isCell(colNum + 1, rowNum + 1) then
            love.graphics.rectangle("fill", x + cellSize - scale*2, y + cellSize - scale*2, scale, scale*2)
            graphics.setColor(graphics.COLOR_LILLYPAD)
            love.graphics.rectangle("fill", x + cellSize - scale*4, y + cellSize - scale, scale, scale)
            graphics.setColor(graphics.COLOR_LILLYPAD_SHADOW)
            love.graphics.rectangle("fill", x + cellSize - scale*3, y + cellSize - scale, scale, scale)
          end
        end
        
        graphics.setColor(graphics.COLOR_BLACK)
        
        -- Bottom left corner
        if left and down then
          if not self:isCell(colNum - 1, rowNum + 1) then
            love.graphics.rectangle("fill", x, y + cellSize - scale, scale*2, scale)
            love.graphics.rectangle("fill", x, y + cellSize - scale*2, scale, scale)
            graphics.setColor(graphics.COLOR_LILLYPAD_SHADOW)
            love.graphics.rectangle("fill", x, y + cellSize - scale*3, scale, scale)
            love.graphics.rectangle("fill", x + scale, y + cellSize - scale*2, scale, scale*2)
            
          end
        
        elseif left then
          if self:isCell(colNum - 1, rowNum + 1) then
            love.graphics.rectangle("fill", x, y + cellSize - scale*2, scale*2, scale)
            graphics.setColor(graphics.COLOR_LILLYPAD_SHADOW)
            love.graphics.rectangle("fill", x, y + cellSize - scale*3, scale, scale)
          end
        
        elseif down then
          if self:isCell(colNum - 1, rowNum + 1) then
            love.graphics.rectangle("fill", x + scale, y + cellSize - scale*2, scale, scale*2)
            graphics.setColor(graphics.COLOR_LILLYPAD)
            love.graphics.rectangle("fill", x + scale*2, y + cellSize - scale, scale, scale)
          end
        end
        
        love.graphics.setColor(graphics.COLOR_WHITE)
        
      end
    end
  end
  
end

return spaces
