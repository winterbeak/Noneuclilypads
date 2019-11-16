--- Handles all of the spaces in a particular grid.

local const = require("const")
local misc = require("misc")
local vector = require("vector")
local spaces = require("spaces")
local graphics = require("graphics")

local grid = {}

grid.Grid = {}


--- Constructor.  Creates a new Grid given its width and height.
function grid.Grid:new(width, height)
  newObj = {
    size = vector.Vector:new(width, height),
    width = width,  -- Width of the grid in tiles
    height = height,  -- Height of the grid in tiles
    
    spacesList = {},  -- Set of all unique spaces in the level
    spacesGrid = misc.table2D(width),
    
    decorCountdown = math.random(1, 3)  -- Countdown towards the next space with a decor
  }

  self.__index = self
  return setmetatable(newObj, self)
end


--- Returns true if the coordinates are inside the bounds of the Grid.
function grid.Grid:isInbounds(col, row)
  if 1 <= col and col <= self.width then
    if 1 <= row and row <= self.height then
      return true
    end
  end

  return false
end


--- Returns the space at the given coordinates.
-- If the space is outof bounds, then this simply returns nil.
function grid.Grid:spaceAt(col, row)
  if self:isInbounds(col, row) then
    return self.spacesGrid[col][row]
  end
    
  return nil
end


--- Deletes and recreates the adjacent spaces lists of the given space.
-- The adjacent spaces lists are the four lists that keep track of what spaces
-- are adjacent to the current space.  There is one list for each direction.
function grid.Grid:refreshAdjacent(space)
  local col
  local row
  local adjacentSpace
  
  -- Empties the adjacent spaces lists
  space:emptyAdjacent()

  -- Loops through every cell in the Space
  for colNum, col in pairs(space.cells) do
    for rowNum, _ in pairs(col) do

      -- Check the cell in each of the four directions
      for direction, point in pairs(misc.adjacentPoints(colNum, rowNum)) do
        if self:isInbounds(point.x, point.y) then
          adjacentSpace = self.spacesGrid[point.x][point.y]
          
          -- If there is a Space at that cell that isn't the current Space, add the Space to the set
          if adjacentSpace then
            if adjacentSpace ~= space then
              space.adjacent[direction][adjacentSpace] = true
              table.insert(space.adjacentList, adjacentSpace)
            end
          end
          
        end
      end
      
    end
  end
  
end


--- Deletes and recreates the adjacent spaces lists for all of the spaces in the grid.
-- The adjacent spaces lists are the four lists that keep track of what spaces
-- are adjacent to the current space.  There is one list for each direction.
function grid.Grid:refreshAllAdjacent()
  
  for space, _ in pairs(self.spacesList) do
    self:refreshAdjacent(space)
  end
  
end


--- Adds a single-cell space to the grid at the given coordinates.
-- Make sure to refreshAllAdjacent() at some point after using this function
-- to keep the adjacent lists updated properly.
function grid.Grid:addCellSpace(col, row)
  
  -- Randomly chooses a sprite number that isn't equal to any adjacent sprites
  local space
  local spriteNum
  local directionOffset
  local decorNum
  local equalsAdjacent = true
  local rerolls = 0
  
  self.decorCountdown = self.decorCountdown - 1
  
  while equalsAdjacent do
    equalsAdjacent = false
    
    rerolls = rerolls + 1
    if rerolls > 10 then
      print("Lillypad sprite reroll limit reached!")
      break
    end
    
    spriteNum = math.random(1, spaces.singlePadsSprite.spriteCount)
    
    if self.decorCountdown < 0 then
      -- The decors and lillypad sprites are aligned so that:
      --   any lillypad id of the form 4n works with any decor id of the form 4n
      --   any lillypad id of the form 4n + 1 works with any decor id of the form 4n + 1
      --   any lillypad id of the form 4n + 2 works with any decor id of the form 4n + 2
      --   any lillypad id of the form 4n + 3 works with any decor id of the form 4n + 3
      directionOffset = (spriteNum - 1) % 4
      decorNum = math.random(0, spaces.decorSprite.spriteCount / 4 - 1) * 4 + directionOffset + 1
      
      self.decorCountdown = math.random(1, 3)
    end
    
    -- Checks all adjacent cells
    for direction, point in pairs(misc.adjacentPoints(col, row)) do
      if self:isInbounds(point.x, point.y) then
        space = self.spacesGrid[point.x][point.y]
        
        -- If any adjacent single cell spaces have the same sprite or decor
        if space then
          if space:isSingleCell() then
            if space.spriteNum == spriteNum then
              
              -- Loop from the start, randomly choosing another sprite/decor
              equalsAdjacent = true
              break
              
            elseif decorNum and space.decorNum == decorNum then
              equalsAdjacent = true
              break
              
            end
            
          end
        end
        
      end
    end
    
  end

  -- Creates the space and adds it to the grid
  local newSpace = spaces.Space:new(col, row, spriteNum, decorNum)
  self.spacesGrid[col][row] = newSpace
  self.spacesList[newSpace] = true
end


--- Adds a multi-cell space to the grid.
-- pointList is a table of tables.  Each subtable be of the form {x=x, y=y}.
-- Using vectors as a point is valid too.
-- Make sure to refreshAllAdjacent() at some point after using this function
-- to keep the adjacent lists updated properly.
function grid.Grid:addSpace(pointList)
  
  local newSpace = spaces.Space:new(pointList[1].x, pointList[1].y)
  
  local col
  local row
  
  local spaceList = {}
  
  -- Creates a list of spaces out of the pointList, to merge with the new space
  for index, point in pairs(pointList) do
    spaceList[index] = spaces.Space:new(point.x, point.y)
    
    -- Also adds the space to the spaces grid
    self.spacesGrid[point.x][point.y] = newSpace
  end
  
  -- Merges the cells of all the spaces with the space list
  newSpace:mergeCellsMultiple(spaceList)
  
  self.spacesList[newSpace] = true

end


--- Fills all the nils in the space grid with 1-cell spaces.
-- Only makes a space in the cell if no space is already there.
function grid.Grid:fillGapsWithSpaces()
  for x = 1, self.width do
    for y = 1, self.height do
      
      if not self.spacesGrid[x][y] then
        self:addCellSpace(x, y)
      end
      
    end
  end
end

--- Merges two Spaces together, given their coordinates.
function grid.Grid:merge(col1, row1, col2, row2)
  local space1 = self.spacesGrid[col1][row1]
  local space2 = self.spacesGrid[col2][row2]
  
  -- Throw an error if you try to merge a space with itself
  if space1 == space2 then
    error("You tried to merge a space to itself!")
  end
  
  -- Add the cells of space2 to space1
  space1:mergeCells(space2)
  
  -- Replace all occurences of space2 in spacesGrid with space1
  for colNum, col in pairs(space2.cells) do
    for rowNum, row in pairs(col) do
      self.spacesGrid[colNum][rowNum] = space1
    end
  end
  
  -- Remove space2 from the list of spaces
  self.spacesList[space2] = nil
end


--- Checks if a space is fully connected, and if not, splits it into multiple spaces.
function grid.Grid:attemptSplit(space)
  
  local connected = misc.table2D(self.width)

  local searchCol
  local searchRow
  
  local startCol
  local startRow
  
  startCol, startRow = space:findACell()

  local toSearch = {{x = startCol, y = startRow}}
  
  while #toSearch > 0 do
    
    searchCol = toSearch[1].x
    searchRow = toSearch[1].y

    -- Mark the currently being searched point as connected
    connected[searchCol][searchRow] = true
    
    -- Check all adjacent points, and if valid, add them to the list of spaces to search
    for direction, point in pairs(misc.adjacentPoints(searchCol, searchRow)) do
      
      if self:isInbounds(point.x, point.y) then  -- Must be inbounds
        if not connected[point.x][point.y] then  -- Must not already been searched
          if self.spacesGrid[point.x][point.y] == space then  -- Must be part of the space
            table.insert(toSearch, point)
          end
        end
      end
      
    end
    
    -- Remove the point that was just searched from the search list
    table.remove(toSearch, 1)
  end

  local allConnected = true
  local pointList = {}
  
  -- Loop through all of the cells in the space
  for colNum, col in pairs(space.cells) do
    for rowNum, _ in pairs(col) do
      
      -- If the cell wasn't searched, then it must be disconnected
      if not connected[colNum][rowNum] then
        
        -- Removes all disconnected cells and adds them to a list of
        -- points, so that they can be made into a new space
        self:deleteCell(colNum, rowNum)  

        table.insert(pointList, {x = colNum, y = rowNum})
        
        allConnected = false

      end
      
    end
  end
  
  if not allConnected then
    -- Make a new space to fill in the removed cells
    self:addSpace(pointList)
    
    -- If the space is a T shape and something detaches the top-middle space, then
    -- the space is now three spaces: the left arm, right arm, and pole of the T.
    -- The possibility of more than two new spaces means that a recursive check
    -- is necessary to truly split the space.
    newSpace = self.spacesGrid[pointList[1].x][pointList[1].y]
    self:attemptSplit(newSpace)
  end
  
end


--- Makes the cell at the given coordinates into a 1x1 Space.
-- This will "break off" one of the cells in a Space.
-- In the case that this splits a Space into multiple parts, then
-- the parts will each become its own individual space.
function grid.Grid:detach(col, row)
  
  local oldSpace = self.spacesGrid[col][row]
  local oldSpaceIsCell = oldSpace:isSingleCell()

  self:deleteCell(col, row)  -- Deletes the space at that location
  self:addCellSpace(col, row)  -- Creates a new space to fill in the gap
  
  -- If the space used to only be a single cell, then after the cell
  -- removal it doesn't exist, so don't check for splits in that case.
  if not oldSpaceIsCell then
    
    -- If the removed cell splits the space, then make it multiple spaces
    self:attemptSplit(oldSpace)

  end
  
  self:addCellSpace(col, row)  -- Adds a new space in the gap created
end


--- Deletes a cell space, replacing it with nil.
-- NOTE: If this splits a space into two parts, this will NOT
-- make them into two separate spaces.
function grid.Grid:deleteCell(col, row)
  
  local space = self.spacesGrid[col][row]
  local spaceIsCell = space:isSingleCell()
  
  -- If the cell is the space's only cell, then remove the space entirely
  if spaceIsCell then
    self.spacesList[space] = nil
    
  -- Otherwise, remove the cell from the space's cell list
  else
    space:removeCell(col, row)

  end
  
  self.spacesGrid[col][row] = nil  -- Remove the cell from the grid
  
end


function grid.Grid:drawDebug(xOffset, yOffset, tileSize)
  local x
  local y
  
  for colNum, col in pairs(self.spacesGrid) do
    for rowNum, space in pairs(col) do
      x = (colNum - 1) * tileSize + xOffset
      y = (rowNum - 1) * tileSize + yOffset
      
      if self:spaceAt(colNum - 1, rowNum) ~= space then
        love.graphics.rectangle("fill", x, y, 2, tileSize)
      end
      if self:spaceAt(colNum, rowNum - 1) ~= space then
        love.graphics.rectangle("fill", x, y, tileSize, 2)
      end
    end
  end
end

return grid


--[[
-- Driver code
testGrid = grid.Grid:new(5, 5)

-- Makes a T-shaped space
-- (5 total cells, 3 wide and 3 tall)
pointList = {
  {x=2, y=2},
  {x=3, y=2},
  {x=4, y=2},
  {x=3, y=3},
  {x=3, y=4},
}
testGrid:addSpace(pointList)

-- Fills the rest of the grid with single-cell spaces
testGrid:fillGapsWithSpaces()

-- Removes the top middle of the T, causing it to detach into a
-- single-cell left arm, a single-cell right arm, and a 2-cell center pole
testGrid:detach(3, 2)

-- Updates the adjacent spaces lists
testGrid:refreshAllAdjacent()

-- Prints out all of the spaces
for y = 1, 5 do
  print(y)
  
  for x = 1, 5 do
    print(testGrid.spacesGrid[x][y])
  end
end


-- Prints the spaces adjacent to [2][2] (the left arm)
for key, value in pairs(testGrid.spacesGrid[2][2].adjacent) do
  for key1, value1 in pairs(value) do
    print(key, key1, value1)
  end
end

print()

-- Prints out the spaces adjacent to [3][3] (the middle bar)
for key, value in pairs(testGrid.spacesGrid[3][3].adjacent) do
  for key1, value1 in pairs(value) do
    print(key, key1, value1)
  end
end
]]
