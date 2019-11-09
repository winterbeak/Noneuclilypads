--- A single space that can warp to cover multiple grid cells.
-- Note that spaces cannot work by themselves.  Please do not use any of the
-- below function; only interact with spaces using Grid's commands.

local const = require("const")
local vector = require("vector")
local misc = require("misc")

local spaces = {}

spaces.Space = {}

--- Constructor.  Makes a new Space at the given coordinates.
function spaces.Space:new(col, row)
  local newObj = {
    cells = misc.table2D(const.MAX_GRID_W),
    adjacent = {
      left = {},
      up = {},
      right = {},
      down = {}
    },
    
    leftMost = col,
    rightmost = col,
    topMost = row,
    bottomMost = row,
    maxWidth = 1,
    maxHeight = 1,
    occupiedBy = nil
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
end


--- Updates the bounds of the space.
-- This includes the leftmost, topmost, rightmost, and bottommost cells
-- as well as the width and height of the space.
function spaces.Space:updateBounds()
  local leftMost = const.MAX_GRID_W + 1
  local rightMost = -1
  local topMost = const.MAX_GRID_H + 1
  local bottomMost = -1
  
  -- Loops through all the cells in the grid to find the maximums
  for colNum, col in pairs(self.cells) do
    for rowNum, _ in pairs(col) do

      if colNum < leftMost then
        leftMost = colNum
      end
      if colNum > rightMost then
        rightMost = colNum
      end
      if rowNum < topMost then
        topMost = rowNum
      end
      if rowNum > bottomMost then
        bottomMost = rowNum
      end
    end
  end
  
  self.leftMost = leftMost
  self.rightMost = rightMost
  self.topMost = topMost
  self.bottomMost = bottomMost
  
  -- Calculate the new width and height
  self.width = rightMost - leftMost + 1
  self.height = bottomMost - topMost + 1
  
end


--- Adds the cells of another space to this one.
-- Note that the other space is not affected in any way.
function spaces.Space:mergeCells(otherSpace)
  for colNum, col in pairs(otherSpace.cells) do
    for rowNum, _ in pairs(col) do
      self.cells[colNum][rowNum] = true
    end
  end
  
  self:updateBounds()
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
  
  self:updateBounds()
end


--- Returns true if the space is only 1x1.
function spaces.Space:isSingleCell()
  if self.width == 1 and self.height == 1 then
    return true
  end
  
  return false
end


--- Removes a cell at the given coordinates.
-- Will throw an error if this cell is the space's only cell.
function spaces.Space:removeCell(col, row)
  if self:isSingleCell() then
    error("You tried to remove a space's only cell!  (The cell is at " .. col .. " " .. row .. ".)")
  end
  
  self.cells[col][row] = nil
  self:updateBounds()
end

--- Finds a cell, any cell, that the space contains, and returns its coordinates.
-- Returns two values: the first is the column number, and the second is the row number.
function spaces.Space:findACell()
  for colNum, col in pairs(self.cells) do
    for rowNum, row in pairs(col) do
      return colNum, rowNum
    end
  end
end

return spaces
