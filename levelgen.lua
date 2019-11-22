local levelgen = {}

local grid = require("grid")
local bodies = require("bodies")


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


return levelgen