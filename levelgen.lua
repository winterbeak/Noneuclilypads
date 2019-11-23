grid = require("grid")
bodies = require("bodies")

local levelgen = {}


-- Generates the level used for testing the game.
function levelgen.testingLevel()
  
  local level = grid.Grid:new(7, 7)

  local pointList = {
    {x=4, y=3},
    
    {x=3, y=4},
    {x=4, y=4},
    {x=5, y=4},

    {x=4, y=5},
  }
  level:addSpace(pointList)
  
  level:fillGapsWithSpaces()
  
  level:mergeCoordinates(2, 4, 2, 5)
  level:mergeCoordinates(3, 2, 4, 2)
  level:mergeCoordinates(4, 6, 5, 6)
  level:mergeCoordinates(6, 3, 6, 4)

  level:refreshAllAdjacent()
  
  return level
  
end


--- Generates the level used in recording one of the game's gif.
function levelgen.gifLevel1()
  
  local level = grid.Grid:new(5, 3)

  local pointList = {
    {x=4, y=1},
    {x=5, y=1},
    {x=3, y=1},
    {x=3, y=2},
    {x=3, y=3},
  }
  level:addSpace(pointList)
  
  level:fillGapsWithSpaces()
  level:refreshAllAdjacent()
  
  return level
  
end


--- Generates one of the levels used to test snake edge cases.
function levelgen.snakeTest1()
  
  local level = grid.Grid:new(5, 7)

  local pointList = {
    {x=1, y=1},
    {x=2, y=1},
    {x=3, y=1},
    {x=4, y=1},
    {x=5, y=1},
  }
  level:addSpace(pointList)
  
  for y = 2, 7 do
    level:addCellSpace(1, y)
    level:addCellSpace(5, y)
  end

  level:refreshAllAdjacent()
  
  return level
  
end


--- Generates one of the levels used to test snake edge cases.
function levelgen.snakeTest2()
  
  local level = grid.Grid:new(6, 5)

  local pointList = {
    {x=5, y=1},
    {x=5, y=2},
    {x=5, y=3},
    {x=5, y=4},
  }
  level:addSpace(pointList)
  
  pointList = {
    {x=5, y=5},
    {x=6, y=5},
    {x=6, y=4},
  }
  level:addSpace(pointList)
  
  for x = 1, 4 do
    level:addCellSpace(x, 1)
    level:addCellSpace(x, 5)
  end

  level:refreshAllAdjacent()
  
  return level
  
end


return levelgen