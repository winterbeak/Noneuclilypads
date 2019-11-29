misc = require("misc")
grid = require("grid")
entities = require("entities")


local levelgen = {}

-- Generates the level used for testing the game.
function levelgen.testingLevel()
  
  local level = grid.Grid:new(7, 7)

  local pointList = {
    {4, 3},
    
    {3, 4},
    {4, 4},
    {5, 4},

    {4, 5},
  }
  level:addSpace(pointList)
  
  level:fillGapsWithSpaces()
  
  level:mergeCoordinates(2, 4, 2, 5)
  level:mergeCoordinates(3, 2, 4, 2)
  level:mergeCoordinates(4, 6, 5, 6)
  level:mergeCoordinates(6, 3, 6, 4)

  level:refreshAllAdjacent()
  level:populate(3)
  
  return level
  
end


--- Generates the level used in recording one of the game's gif.
function levelgen.gifLevel1()
  
  local level = grid.Grid:new(5, 3)

  local pointList = {
    {4, 1},
    {5, 1},
    {3, 1},
    {3, 2},
    {3, 3},
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
    {1, 1},
    {2, 1},
    {3, 1},
    {4, 1},
    {5, 1},
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
    {5, 1},
    {5, 2},
    {5, 3},
    {5, 4},
  }
  level:addSpace(pointList)
  
  pointList = {
    {5, 5},
    {6, 5},
    {6, 4},
  }
  level:addSpace(pointList)
  
  for x = 1, 4 do
    level:addCellSpace(x, 1)
    level:addCellSpace(x, 5)
  end

  level:refreshAllAdjacent()
  
  return level
  
end


--- Randomly chooses whether to add a space at the given coordinates.
-- Numerator and denominator represent the chance that the space is added.
-- Ex. if numerator = 2, denominator = 3, then the chance that a space is added is 2/3.
function chanceAdd(level, numerator, denominator, x, y)
  if math.random(1, denominator) <= numerator then
    level:addCellSpace(x, y)
  end
end


--- The level that the frog lands on to hibernate.
function levelgen.winterLevel()
  local level = grid.Grid:new(5, 5)
  
  -- Center plus
  level:addCellSpace(3, 3)
  level:addCellSpace(2, 3)
  level:addCellSpace(3, 2)
  level:addCellSpace(4, 3)
  level:addCellSpace(3, 4)
  
  -- Corners
  chanceAdd(level, 3, 4, 2, 2)
  chanceAdd(level, 3, 4, 2, 4)
  chanceAdd(level, 3, 4, 4, 2)
  chanceAdd(level, 3, 4, 4, 4)
  
  -- Extended plus
  chanceAdd(level, 1, 4, 1, 3)
  chanceAdd(level, 1, 4, 3, 1)
  chanceAdd(level, 1, 4, 5, 3)
  chanceAdd(level, 1, 4, 3, 5)
  
  level:refreshAllAdjacent()
  
  return level
  
end



function levelgen.windowsill()
  local vertBarThickness = math.random(2, 3)
  local horizBarThickness = math.random(2, 3)
  
  local level = grid.Grid:new(vertBarThickness + 4, horizBarThickness + 4)
  
  -- Top left corner
  level:addSpace({
      {1, 1},
      {1, 2},
      {2, 1}
    })
  
  level:dupeFlipDown()
  level:dupeFlipRight()
  
  level:fillGapsWithSpaces()
  
  level:deleteCell(2, 2)  -- Top left hole
  level:deleteCell(level.width - 1, 2)  -- Top right hole
  level:deleteCell(2, level.height - 1)  -- Bottom left hole
  level:deleteCell(level.width - 1, level.height - 1)  -- Bottom right hole
  
  level:refreshAllAdjacent()
  
  if vertBarThickness == 3 and horizBarThickness == 3 then
    level:populate(4)
  else
    level:populate(3)
  end
  
  return level
end


function levelgen.tinyHuge()
  local level = grid.Grid:new(8, 6)
  
  local left1
  if math.random(1, 2) == 1 then
    left1 = 1
    left2 = 3
  else
    left1 = 3
    left2 = 1
  end
  
  level:addRect(left1, 1, 2, 2)
  level:addRect(left2, 3, 2, 2)
  level:addRect(left1, 5, 2, 2)
  
  -- Variant where the right side is the left side, but copied
  if math.random(1, 2) == 1 then
    level:addRect(left1 + 4, 1, 2, 2)
    level:addRect(left2 + 4, 3, 2, 2)
    level:addRect(left1 + 4, 5, 2, 2)
    
  -- Variant where the level is flipped
  else
    level:dupeFlipRight()
    
  end
  
  level:fillGapsWithSpaces()
  
  level:refreshAllAdjacent()
  level:populate(3)
  
  return level
end


function levelgen.screenWrap()
  local level = grid.Grid:new(math.random(7, 9), math.random(6, 7))
  
  local pointList = {}
  
  -- Left points
  for y = 2, level.height do
    table.insert(pointList, {1, y})
  end
  
  -- Top points
  for x = 1, level.width do
    table.insert(pointList, {x, 1})
  end
  
  -- Right points
  for y = 2, level.height do
    table.insert(pointList, {level.width, y})
  end
  
  -- Bottom points
  for x = 1, level.width do
    table.insert(pointList, {x, level.height})
  end
  
  level:addSpace(pointList)
  level:fillGapsWithSpaces()
  
  level:refreshAllAdjacent()
  
  if level.width * level.height > 50 then
    level:populate(4)
  else
    level:populate(3)
  end
  
  return level
end


-- This level feels a little cramped.
function levelgen.tiltedBridges()
  local level = grid.Grid:new(9, 7)
  local leftX
  local leftY
  local rightX
  local rightY
  local bridgeX
  local bridgeY = 2
  local xStep
  
  if math.random(1, 2) == 1 then
    leftX = 1
    rightX = 6
    
    leftY = 1
    rightY = 2
    
    bridgeX = 3
    
    xStep = 1
    
    level:addCellSpace(1, 3)
    level:addCellSpace(2, 5)
    level:addCellSpace(8, 3)
    level:addCellSpace(9, 5)
  else
    leftX = 3
    rightX = 8
    
    leftY = 2
    rightY = 1
    
    bridgeX = 5
    
    xStep = -1
    
    level:addCellSpace(2, 3)
    level:addCellSpace(1, 5)
    level:addCellSpace(9, 3)
    level:addCellSpace(8, 5)
  end
  
  for i = 1, 3 do
    level:addCellSpace(leftX, leftY)
    level:addCellSpace(leftX + 1, leftY)
    level:addCellSpace(leftX, leftY + 1)
    level:addCellSpace(leftX + 1, leftY + 1)
    
    level:addCellSpace(rightX, rightY)
    level:addCellSpace(rightX + 1, rightY)
    level:addCellSpace(rightX, rightY + 1)
    level:addCellSpace(rightX + 1, rightY + 1)
    
    level:addHorizLine(bridgeX, bridgeY, 3, 1)
    
    leftX = leftX + xStep
    rightX = rightX + xStep
    
    leftY = leftY + 2
    rightY = rightY + 2
    
    bridgeX = bridgeX + xStep
    bridgeY = bridgeY + 2
  end
  
  level:refreshAllAdjacent()
  level:populate(3)
  
  return level
  
end


function levelgen.tetris()
  local level = grid.Grid:new(9, 7)
  
  level:addSpace({{1, 2}, {1, 1}, {2, 1}, {3, 1}})  -- Top left L
  level:addRect(2, 2, 2, 2)  -- Top left O
  level:addSpace({{1, 3}, {1, 4}, {2, 4}, {2, 5}})  -- Left S
  level:addSpace({{1, 5}, {1, 6}, {2, 6}, {3, 6}})  -- Bottom left J
  
  level:addSpace({{4, 1}, {5, 1}, {6, 1}, {5, 2}})  -- Top T
  level:addSpace({{4, 2}, {4, 3}, {4, 4}, {3, 4}})  -- Middle J
  level:addSpace({{6, 2}, {6, 3}, {5, 3}, {5, 4}})  -- Middle Z
  level:addHorizLine(3, 5, 4)  -- The only I
  level:addRect(4, 6, 2, 2)  -- Bottom O
  
  level:addSpace({{7, 1}, {8, 1}, {9, 1}, {9, 2}})  -- Top right J
  level:addSpace({{7, 2}, {8, 2}, {8, 3}, {9, 3}})  -- Top right Z
  level:addSpace({{6, 4}, {7, 4}, {8, 4}, {7, 3}})  -- Middle right T
  level:addSpace({{6, 6}, {7, 6}, {7, 5}, {8, 5}})  -- Bottom right S
  level:addSpace({{8, 6}, {9, 6}, {9, 5}, {9, 4}})  -- Bottom right J
  
  level:refreshAllAdjacent()
  level:populate(2)
  
  return level
end


function levelgen.butterfly()
  local level = grid.Grid:new(7, math.random(5, 7))
  local variant = math.random(1, 2)
  
  level:addVertLine(4, 1, level.height)
  
  -- This one is harder so it gets less enemies
  if variant == 1 then
    level:addVertLine(2, 2, level.height - 2)
    level:addVertLine(6, 2, level.height - 2)
    
  -- This one is easier so it gets more enemies
  elseif variant == 2 then
    level:addVertLine(2, 3, level.height - 4)
    level:addVertLine(6, 3, level.height - 4)
  end
  
  level:fillGapsWithSpaces()
  level:refreshAllAdjacent()
  
  if variant == 1 then
    level:populate(2)
  elseif variant == 2 then
    level:populate(3)
  end
  
  return level
end


function levelgen.present()
  local level
  local variant = math.random(1, 2)
  
  if variant == 1 then
    level = grid.Grid:new(9, 7)
    level:addVertLine(5, 1, 2)
    level:addVertLine(5, 6, 2)
    level:addHorizLine(1, 4, 3)
    level:addHorizLine(7, 4, 3)
    level:addRect(4, 3, 3, 3)
    
  elseif variant == 2 then
    level = grid.Grid:new(7, 7)
    level:addVertLine(4, 1, 2)
    level:addVertLine(4, 6, 2)
    level:addHorizLine(1, 4, 2)
    level:addHorizLine(6, 4, 2)
    level:addRect(3, 3, 3, 3)
    
  end
  
  level:fillGapsWithSpaces()
  level:refreshAllAdjacent()
  
  if variant == 1 then
    level:populate(4)
  elseif variant == 2 then
    level:populate(3)
  end
  
  return level
end


function levelgen.plus()
  local width = 5 + (math.random(0, 2) * 2)
  local height = 5 + (math.random(0, 1) * 2)
  
  local level = grid.Grid:new(width, height)
  
  -- If the level is tiny, the center is kept split
  if width * height < 36 then
    level:addVertLine(math.ceil(width / 2), 1, math.floor(height / 2))
    level:addVertLine(math.ceil(width / 2), math.ceil(height / 2) + 1, math.floor(height / 2))
    level:addHorizLine(1, math.ceil(height / 2), math.floor(width / 2))
    level:addHorizLine(math.ceil(width / 2) + 1, math.ceil(height / 2), math.floor(width / 2))
  
  -- Full vertical line
  elseif math.random(1, 2) == 1 then
    level:addVertLine(math.ceil(width / 2), 1, height)
    level:addHorizLine(1, math.ceil(height / 2), math.floor(width / 2))
    level:addHorizLine(math.ceil(width / 2) + 1, math.ceil(height / 2), math.floor(width / 2))
    
  -- Full horizontal line
  else
    level:addHorizLine(1, math.ceil(height / 2), width)
    level:addVertLine(math.ceil(width / 2), 1, math.floor(height / 2))
    level:addVertLine(math.ceil(width / 2), math.ceil(height / 2) + 1, math.floor(height / 2))
  end
  
  level:fillGapsWithSpaces()
  
  level:refreshAllAdjacent()
  
  -- Deletes the corners, unless the level is tiny
  if width * height >= 36 then
    level:deleteCell(1, 1)
    level:deleteCell(width, 1)
    level:deleteCell(1, height)
    level:deleteCell(width, height)
  end
  
  if width * height < 36 then
    level:populate(2)
  elseif width * height < 50 then
    level:populate(3)
  else
    level:populate(4)
  end
  
  return level
end


function levelgen.onion()
  local level = grid.Grid:new(8, 8)
  
  level:addCellSpace(4, 4)
  level:addSpace({{4, 3}, {3, 3}, {3, 4}})
  level:addSpace({{4, 2}, {3, 2}, {2, 2}, {2, 3}, {2, 4}})
  level:addSpace({{4, 1}, {3, 1}, {2, 1}, {1, 1}, {1, 2}, {1, 3}, {1, 4}})
  
  level:dupeFlipRight()
  level:dupeFlipDown()
  
  level:refreshAllAdjacent()
  level:populate(2)
  
  return level
end


function levelgen.sandwich()
  local level = grid.Grid:new(7, 6)
  
  for x = 1, 3 do
    for y = 1, 6, 6 / x do
      level:addVertLine(x, y, 6 / x)
      level:addVertLine(7 - x + 1, y, 6 / x)
    end
  end
  
  level:fillGapsWithSpaces()
  level:refreshAllAdjacent()
  level:populate(2)
  
  return level
end


function levelgen.bricks()
  local width = 9
  local height = 7
  local level = grid.Grid:new(width, height)
  
  local startX = math.random(1, 2)
  local variant = math.random(1, 2)
  
  for y = 1, height do
    for x = startX, width - 1, 2 do
      level:addHorizLine(x, y, 2)
    end
    
    if startX == 1 then
      startX = 2
    else
      startX = 1
    end
  end
  
  
  -- Fills in the holes at the ends, consequently making it easier.
  if variant == 1 then
    level:fillGapsWithSpaces()
  end
  
  level:refreshAllAdjacent()
  
  if variant == 1 then
    level:populate(3)
  elseif variant == 2 then
    level:populate(2)
  end
  
  
  return level
end



local generators = {
  levelgen.testingLevel,
  levelgen.windowsill,
  levelgen.tinyHuge,
  levelgen.screenWrap,
  levelgen.tiltedBridges,  -- questionable
  levelgen.tetris,  -- questionable
  levelgen.butterfly,
  levelgen.present,
  levelgen.plus,
  levelgen.onion,
  levelgen.sandwich,
  levelgen.bricks,
}


--- Chooses a random level and generates it.
-- If you want to make a random level, please use makeRandomLevel() instead.
function levelgen.randomLevel()
  -- local level = levelgen.bricks()
  local level = generators[math.random(1, #generators)]()
  
  return level
end


return levelgen