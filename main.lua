-- The main code used to run the game.

local misc = require("misc")
local grid = require("grid")
local bodies = require("bodies")

local gridXOffset = 150
local gridYOffset = 50
local tileSize = 100


--- Returns the x of the left side of a column.
function xOf(col)
  return (col - 1) * tileSize + gridXOffset
end


--- Returns the y of the top side of a row.
function yOf(row)
  return (row - 1) * tileSize + gridYOffset
end


--- Returns the column on the grid that a given x coordinate is on.
function colAt(x)
  return math.ceil((x - gridXOffset) / tileSize)
end


--- Returns the row on the grid that a given y coordinate is on.
function rowAt(y)
  return math.ceil((y - gridYOffset) / tileSize)
end


--- Returns the space that a given pixel is overtop.  Returns nil if there is no space there.
-- x and y are the pixel's position.
function spaceAt(levelGrid, x, y)
  local col = colAt(x)
  local row = rowAt(y)
  if levelGrid:isInbounds(col, row) then
    return levelGrid.spacesGrid[col][row]
  end
  return nil
end


function updateMouse()
  if love.mouse.isDown(1) then
    if not mouseHeld then
      mouseClicked = true
      mouseHeld = true
    else
      mouseClicked = false
    end
    
  else
    if mouseHeld then
      mouseReleased = true
    else
      mouseReleased = false
    end
      
    mouseHeld = false
    mouseClicked = false
  end
end


--- Runs when the game is started.
function love.load()

  love.keyboard.setKeyRepeat(false)
  
  -- Generates level
  level = grid.Grid:new(5, 5)

  -- Makes an upside down L shaped space
  local pointList = {
    {x=2, y=2},
    {x=3, y=2},
    {x=3, y=3},
    {x=3, y=4},
  }

  level:addSpace(pointList)
  level:fillGapsWithSpaces()
  
  level:merge(3, 5, 4, 5)
  level:deleteCell(5, 5)

  level:refreshAllAdjacent()
  
  

  player = bodies.WarpBody:new(level.spacesGrid[4][4])

  CHOOSE_DIRECTION = 1
  CHOOSE_SPACE = 2
  MOVEMENT = 3

  state = CHOOSE_DIRECTION
  lockMovement = false
  
  mouseClicked = false
  mouseHeld = false
  mouseReleased = false
  mouseDownPreviousFrame = false
end


--- Runs every frame.
function love.update()
  updateMouse()

  if mouseReleased then
    local mouseSpace = spaceAt(level, love.mouse.getX(), love.mouse.getY())
    
    for direction, spaceList in pairs(player.space.adjacent) do
      for space, _ in pairs(spaceList) do
        if (space == mouseSpace) then
          player:moveTo(space)
          break
        end
      end
    end
    
  end
end

function drawDebugCell(r, g, b, col, row)
  love.graphics.setColor(r, g, b)
  love.graphics.rectangle("fill", xOf(col), yOf(row), tileSize, tileSize)
  love.graphics.setColor(255, 255, 255)
end

--- Runs every frame.
function love.draw()
  level:drawDebug(gridXOffset, gridYOffset, tileSize)
  
  for colNum, col in pairs(player.space.cells) do
    for rowNum, _ in pairs(col) do
      drawDebugCell(255, 0, 0, colNum, rowNum)
    end
  end
  
  for index, space in pairs(player.space.adjacentList) do
    for colNum, col in pairs(space.cells) do
      for rowNum, _ in pairs(col) do
        drawDebugCell(255, 255, 0, colNum, rowNum)
      end
    end
  end

end
