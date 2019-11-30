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


--- The level that also serves as the game's main menu.
function levelgen.menuLevel()
  local level = grid.Grid:new(10, 7)
  
  level:addSpace({{7, 3}, {6, 3}, {6, 4}, {6, 5}, {7, 5}})
  level:addSpace({{9, 3}, {10, 3}, {10, 4}, {10, 5}, {9, 5}})
  
  for col = 6, 10 do
    for row = 1, 7 do
      if not level.spacesGrid[col][row] then
        level:addCellSpace(col, row)
      end
    end
  end
  
  for col = 6, 10 do
    level.spacesGrid[col][7].decorNum = nil
  end
  
  level:mergeCoordinates(6, 1, 7, 1)
  level:mergeCoordinates(9, 1, 10, 1)
  
  level:addSmallText("Play", 134, 4)
  level:addSmallText("Tutorial", 196, 4)
  level:addSmallText("Screen Size", 150, 168)
  level:addBigText("Click to move.", 12, 103)
  level:addSmallText("x1", 126, 148)
  level:addSmallText("x2", 150, 148)
  level:addSmallText("x3", 174, 148)
  level:addSmallText("x4", 198, 148)
  level:addSmallText("x5", 222, 148)
  
  level:refreshAllAdjacent();
  
  return level
end


-- Tutorial intro
function levelgen.tutorialLevel1()
  local level = grid.Grid:new(7, 3)
  
  -- Top row and bottom row
  for i = 3, 5 do
    level:addCellSpace(i, 1)
    level:addCellSpace(i, 3)
  end
  
  -- Middle row
  for i = 1, 7 do
    level:addCellSpace(i, 2)
  end
  
  level:refreshAllAdjacent()
  
  level:addCenteredSmallText("Welcome to the tutorial!", -40)
  level:addCenteredSmallText("Move to the leftmost lillypad to continue.", -30)
  return level
end


-- Noneuclilupads 1
function levelgen.tutorialLevel2()
  local level = grid.Grid:new(9, 3)
  
  -- Middle line
  for i = 1, 3 do
    level:addCellSpace(i, 2)
    level:addCellSpace(9 - i + 1, 2)
  end
  
  -- Left and right single spaces
  level:addCellSpace(3, 1)
  level:addCellSpace(3, 3)
  level:addCellSpace(7, 1)
  level:addCellSpace(7, 3)
  level:addCellSpace(4, 3)
  level:addCellSpace(6, 1)
  
  level:addRect(5, 2, 2, 2)  -- Square
  level:addSpace({{4, 2}, {4, 1}, {5, 1}})  -- L shape
  
  level:refreshAllAdjacent()
  
  level:addCenteredSmallText("Here are some noneuclilypads!", -50)
  level:addCenteredSmallText("These make you exist on every cell at once.", -40)
  level:addCenteredSmallText("Play around a bit, then move to the right.", -30)
  return level
end


-- Noneuclilypads 2
function levelgen.tutorialLevel3()
  local level = grid.Grid:new(9, 5)
  
  -- Top and bottom lines
  level:addHorizLine(3, 1, 5)
  level:addHorizLine(3, 5, 5)
  level:addRect(4, 2, 3, 3)
  level:detach(5, 3)
  
  level:fillGapsWithSpaces()
  
  -- Removes the 2x2 squares of cells at each corner
  local squareX = {1, 8, 8, 1}
  local squareY = {1, 1, 4, 4}
  for i = 1, #squareX do
    for x = squareX[i], squareX[i] + 1 do
      for y = squareY[i], squareY[i] + 1 do
        level:deleteCell(x, y)
      end
    end
  end
  
  level:refreshAllAdjacent()
  
  level:addCenteredSmallText("Some more lillypads to experiment with!", -26)
  return level
end


-- Enemy introduction
function levelgen.tutorialLevel4()
  local level = grid.Grid:new(8, 5)
  
  -- Center line
  for x = 1, 8 do
    level:addCellSpace(x, 3)
  end
  
  -- Top bit
  for x = 2, 4 do
    level:addCellSpace(x, 4)
  end
  
  -- Bottom bit
  for x = 5, 7 do
    level:addCellSpace(x, 2)
  end
  
  level:refreshAllAdjacent()
  
  local rat = entities.Rat:new(level.spacesGrid[8][3])
  rat.body.bugs = {}
  rat.moveTimer = 1
  rat.animation = rat.idleAnim2
  rat.body.moveDirection = "left"
  
  level:addEnemy(rat)
  
  level:addCenteredSmallText("Watch out!  It's an enemy!", -32)
  level:addCenteredSmallText("Try to get past it without getting hurt.", -22)
  return level
end


-- Fleas introduction
function levelgen.tutorialLevel5()
  local level = grid.Grid:new(9, 7)
  
  -- Center line
  for x = 1, 9 do
    level:addCellSpace(x, 4)
  end
  
  -- Middle top and middle bottom lines
  for x = 3, 7 do
    level:addCellSpace(x, 3)
    level:addCellSpace(x, 5)
  end
  
  -- Top and bottom lines
  for x = 4, 6 do
    level:addCellSpace(x, 2)
    level:addCellSpace(x, 6)
  end
  
  level:refreshAllAdjacent()
  
  local rat = entities.Rat:new(level.spacesGrid[5][4])
  rat.body.moveDirection = "right"
  
  level:addEnemy(rat)
  
  level:addCenteredSmallText("You'll need food to survive the winter!", -13)
  level:addCenteredSmallText("Click on an enemy to eat its fleas.", -3)
  level:addCenteredSmallText("Eat all the fleas before continuing the tutorial!", 7)
  return level
end


-- Energy bar intro
function levelgen.tutorialLevel6()
  local level = grid.Grid:new(9, 7)
  
  -- Center line
  for x = 1, 9 do
    level:addCellSpace(x, 4)
  end
  
  -- All the other lines
  for x = 3, 7 do
    level:addCellSpace(x, 2)
    level:addCellSpace(x, 3)
    level:addCellSpace(x, 5)
    level:addCellSpace(x, 6)
  end
  
  level:refreshAllAdjacent()
  
  local rat1 = entities.Rat:new(level.spacesGrid[4][3])
  rat1.moveTimer = 0
  rat1.animation = rat1.idleAnim1
  rat1.body.moveDirection = "left"
  
  local rat2 = entities.Rat:new(level.spacesGrid[6][5])
  rat2.moveTimer = 1
  rat2.animation = rat2.idleAnim2
  rat2.body.moveDirection = "left"
  
  level:addEnemy(rat1)
  level:addEnemy(rat2)
  
  level:addCenteredSmallText("Filling up to the red line guarantees survival!", -13)
  level:addCenteredSmallText("If you're lucky, you can get away with less.", -3)
  level:addCenteredSmallText("Eat at least 4 fleas here before continuing.", 7)
  
  return level
end


-- Enemies using noneuclilypads 1
function levelgen.tutorialLevel7()
  local level = grid.Grid:new(9, 7)
  
  -- Center line
  for x = 1, 9 do
    level:addCellSpace(x, 4)
  end
  
  -- Middle top and middle bottom lines
  for x = 3, 7 do
    level:addCellSpace(x, 3)
    level:addCellSpace(x, 5)
  end
  
  -- Top and bottom lines
  for x = 4, 6 do
    level:addCellSpace(x, 2)
    level:addCellSpace(x, 6)
  end
  
  -- Top noneuclilypad
  level:mergeCoordinates(4, 3, 5, 3)
  level:mergeCoordinates(5, 3, 6, 3)
  
  -- Bottom noneuclilypad
  level:mergeCoordinates(4, 5, 5, 5)
  level:mergeCoordinates(5, 5, 6, 5)
  level:refreshAllAdjacent()
  
  local rat = entities.Rat:new(level.spacesGrid[3][4])
  rat.moveTimer = 1
  rat.animation = rat.idleAnim2
  rat.body.moveDirection = "right"
  
  level:addEnemy(rat)
  
  level:addCenteredSmallText("Enemies can use noneuclilypads too!", -8)
  level:addCenteredSmallText("Eat all the fleas here to continue.", 2)
  
  return level
end


-- Enemies using noneuclilypads 2
function levelgen.tutorialLevel8()
  local level = grid.Grid:new(9, 7)
  
  -- Center line
  for x = 1, 9 do
    level:addCellSpace(x, 4)
  end
  
  -- All other lines
  for x = 3, 7 do
    level:addCellSpace(x, 2)
    level:addCellSpace(x, 3)
    level:addCellSpace(x, 5)
    level:addCellSpace(x, 6)
  end
  
  level:mergeCoordinates(5, 3, 5, 4)
  level:mergeCoordinates(5, 4, 5, 5)
  
  level:refreshAllAdjacent()
  
  -- Top left rat
  local rat1 = entities.Rat:new(level.spacesGrid[4][3])
  rat1.moveTimer = 0
  rat1.animation = rat1.idleAnim1
  rat1.body.moveDirection = "left"
  
  -- Bottom right rat
  local rat2 = entities.Rat:new(level.spacesGrid[6][5])
  rat2.moveTimer = 1
  rat2.animation = rat2.idleAnim2
  rat2.body.moveDirection = "left"
  
  level:addEnemy(rat1)
  level:addEnemy(rat2)
  
  level:addCenteredSmallText("Eat four fleas to continue.", -3)
  
  return level
end


-- Jumping between levels
function levelgen.tutorialLevel9()
  local level = grid.Grid:new(9, 5)
  
  -- Center line
  for x = 3, 9 do
    level:addCellSpace(x, 3)
  end
  
  -- Middle top and middle bottom lines
  for x = 4, 6 do
    level:addCellSpace(x, 2)
    level:addCellSpace(x, 4)
  end
  
  level:addCellSpace(5, 1)
  level:addCellSpace(5, 5)
  
  level:addSpace({{3, 2}, {3, 1}, {4, 1}})  -- Top left corner
  level:addSpace({{7, 2}, {7, 1}, {6, 1}})  -- Top right corner
  level:addSpace({{7, 4}, {7, 5}, {6, 5}})  -- Bottom right corner
  level:addSpace({{3, 4}, {3, 5}, {4, 5}})  -- Bottom left corner

  level:refreshAllAdjacent()
  
  level:addCenteredSmallText("One last thing!", -37)
  level:addCenteredSmallText("To jump between islands, you must click yourself.", -27)
  level:addCenteredSmallText("This takes 3 turns to charge, so be careful!", -17)
  
  level:addCenteredSmallText("This is the end of the tutorial.", 122)
  level:addCenteredSmallText("Once you're ready, jump to the next island.", 132)
  level:addCenteredSmallText("Good luck!", 142)
  
  return level
end

levelgen.tutorialLevelGenerators = {
  levelgen.tutorialLevel1,
  levelgen.tutorialLevel2,
  levelgen.tutorialLevel3,
  levelgen.tutorialLevel4,
  levelgen.tutorialLevel5,
  levelgen.tutorialLevel6,
  levelgen.tutorialLevel7,
  levelgen.tutorialLevel8,
  levelgen.tutorialLevel9,
}

levelgen.tutorialStartPositions = {
  {7, 2},  -- 1
  {1, 2},  -- 2
  {9, 3},  -- 3
  {1, 3},  -- 4
  {9, 4},  -- 5
  {1, 4},  -- 6
  {9, 4},  -- 7
  {1, 4},  -- 8
  {9, 3},  -- 9
}

levelgen.tutorialStartDirections = {
  "left",
  "right",
  "left",
  "right",
  "left",
  "right",
  "left",
  "right",
  "left"
}


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