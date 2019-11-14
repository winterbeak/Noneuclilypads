--- A single space that can warp to cover multiple grid cells.
-- Note that spaces cannot work by themselves.  Please do not use any of the
-- below function; only interact with spaces using Grid's commands.

local graphics = require("graphics")
local const = require("const")
local vector = require("vector")
local misc = require("misc")

local spaces = {}

spaces.singlePadsSprite = graphics.SpriteSheet:new("singlePads.png", 16)

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


--- Draws the space.
-- gridX and gridY are the pixel coordinates of the top left of the space's grid.
-- scale is how big to scale the art.
function spaces.Space:draw(gridX, gridY, scale)
  local x
  local y
  
  if self:isSingleCell() then
    local col, row = self:findACell()
    local cellSize = spaces.singlePadsSprite.width * scale

    x = gridX + (cellSize * (col - 1))
    y = gridY + (cellSize * (row - 1))

    spaces.singlePadsSprite:draw(self.spriteNum, x, y, scale)
  end
end

return spaces
