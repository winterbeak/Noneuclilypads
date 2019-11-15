-- The main code used to run the game.

local misc = require("misc")
local grid = require("grid")
local bodies = require("bodies")
local spaces = require("spaces")
local graphics = require("graphics")

local gridXOffset = 150
local gridYOffset = 50
local pixel = 4
local tileSize = (pixel * spaces.singlePadsSprite.width)


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
  
  -- Sets the random seed
  math.randomseed(os.time())

  -- Prevents the holding of a key
  love.keyboard.setKeyRepeat(false)
  
  -- Generates level
  level = grid.Grid:new(5, 5)

  local pointList = {
    {x=2, y=1},
    {x=3, y=1},
    {x=3, y=2},
    {x=3, y=3},
    {x=2, y=3},
    {x=4, y=3},
    {x=3, y=4}
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
  
  mouseSpace = nil
end


--- Runs every frame.
function love.update()

  updateMouse()
  mouseSpace = spaceAt(level, love.mouse.getX(), love.mouse.getY())

  if mouseReleased then

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
  local highlighted
  
  love.graphics.setBackgroundColor(graphics.COLOR_WATER)
  
  level:drawDebug(gridXOffset, gridYOffset, tileSize)
  
  for space, _ in pairs(level.spacesList) do
    highlighted = false
    
    if space.occupiedBy == player then
      highlighted = true
      
    else
      for index, adjacentSpace in pairs(space.adjacentList) do
        if adjacentSpace.occupiedBy == player then
          highlighted = true
          break
        end
      end
      
    end
    
    -- "Compresses" a space if the mouse is hovering over it.
    if highlighted and space == mouseSpace then
      
      -- If the mouse is being held, compress it more
      if mouseHeld then
        space:draw(gridXOffset + pixel*2, gridYOffset + pixel*2, pixel, 0, 0, highlighted)
        
      -- Otherwise, compress it the normal amount
      else
        space:draw(gridXOffset + pixel, gridYOffset + pixel, pixel, pixel, pixel, highlighted)
      end
      
    -- Otherwise, draws the space normally
    else
      space:draw(gridXOffset, gridYOffset, pixel, pixel*2, pixel*2, highlighted)
    end
    
  end
  
  for colNum, col in pairs(player.space.cells) do
    for rowNum, _ in pairs(col) do
      drawDebugCell(255, 0, 0, colNum, rowNum)
    end
  end

end
