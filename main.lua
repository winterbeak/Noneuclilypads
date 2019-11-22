-- The main code used to run the game.

local misc = require("misc")
local grid = require("grid")
local bodies = require("bodies")
local spaces = require("spaces")
local graphics = require("graphics")
local levelgen = require("levelgen")

local gridXOffset = 150
local gridYOffset = 50
local pixel = 3
local tileSize = (pixel * spaces.singlePadsSprite.width)
local showFPS = false


--- Changes a few settings for gif recording.
function gifMode()
  love.window.setMode(450, 300)
  pixel = 3
  tileSize = pixel * spaces.singlePadsSprite.width
  gridXOffset = 45
  gridYOffset = 39
end


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


function drawDebugCell(r, g, b, col, row)
  love.graphics.setColor(r, g, b)
  love.graphics.rectangle("fill", xOf(col), yOf(row), tileSize, tileSize)
  love.graphics.setColor(255, 255, 255)
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
  
  -- gifMode()
  
  math.randomseed(os.time())
  
  level = levelgen.testingLevel()
  level:addEnemy(bodies.Rat:new(level.spacesGrid[5][4]))
  level:addEnemy(bodies.Snake:newRandom(level.spacesGrid[7][7]))
  level:addEnemy(bodies.Slug:new(level.spacesGrid[7][1]))
  
  player = bodies.Player:new(level.spacesGrid[1][1])
  
  level:updateDistances(player.body.space)

  lockMovement = false
  
  -- Keeps track of mouse events
  mouseClicked = false
  mouseHeld = false
  mouseReleased = false
  mouseDownPreviousFrame = false
  
  mouseSpace = nil
  
  -- Tracks fps
  totalTime = 0
  totalFrames = 0

end


--- Runs every frame.
function love.update(dt)
  
  -- Draws fps
  if showFPS then
    totalTime = totalTime + dt
    totalFrames = totalFrames + 1
  end
  
  -- Updates mouse events
  updateMouse()
  mouseSpace = spaceAt(level, love.mouse.getX(), love.mouse.getY())
  
  -- Updates player animation
  lockMovement = false -- change later
  player:updateAnimation()
  
  -- Updates enemy animations
  for enemy, _ in pairs(level.enemyList) do
    enemy:updateAnimation()
  end
  
  -- What happens when the mouse is clicked
  if not lockMovement and mouseReleased then
    
    local validMove
    local eatFlies
    
    if player.body.space.adjacentList[mouseSpace] then
      if mouseSpace:isOccupied() then
        if mouseSpace.occupiedBy.flyCount > 0 then
          validMove = true
          eatFlies = true
        else
          validMove = false
          eatFlies = false
        end
      else
        validMove = true
        eatFlies = false
      end
    end
    
    if validMove then
      
      -- Move the player
      if eatFlies then
        mouseSpace.occupiedBy.flyCount = mouseSpace.occupiedBy.flyCount - 1
        player.energy = player.energy + 1
        
      else
        lockMovement = true
        
        for direction, spacesList in pairs(player.body.space.adjacent) do
          if spacesList[mouseSpace] then
            player:moveTo(mouseSpace, direction)
            level:updateDistances(player.body.space)
            break
          end
        end

      end
      
      -- Have all the enemies take their turn
      level:doEnemyTurns(player)
      
    end
    
  end

end


--- Runs every frame.
function love.draw()
  local highlighted
  local playerXOffset = 0
  local playerYOffset = 0
  
  love.graphics.setBackgroundColor(graphics.COLOR_WATER)
  
  -- level:drawDebug(gridXOffset, gridYOffset, tileSize)
  
  for space, _ in pairs(level.spacesList) do
    highlighted = false
    
    if space.occupiedBy == player.body then
      highlighted = true
      
    else
      for adjacentSpace, _ in pairs(space.adjacentList) do
        if adjacentSpace.occupiedBy == player.body then
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
        
        if space == player.body.space then
          playerXOffset = pixel*2
          playerYOffset = pixel*2
        end
        
      -- Otherwise, compress it the normal amount
      else
        space:draw(gridXOffset + pixel, gridYOffset + pixel, pixel, pixel, pixel, highlighted)
        
        if space == player.body.space then
          playerXOffset = pixel
          playerYOffset = pixel
        end
        
      end
      
    -- Otherwise, draws the space normally
    else
      space:draw(gridXOffset, gridYOffset, pixel, pixel*2, pixel*2, highlighted)
    end
    
  end
  
  level:drawDistances(gridXOffset, gridYOffset, tileSize)
  
  player:draw(gridXOffset + playerXOffset, gridYOffset + playerYOffset, pixel, tileSize)
  
  level:drawEnemies(gridXOffset, gridYOffset, pixel, tileSize)
  
  
  -- FPS counter
  if showFPS then
    love.graphics.setColor(graphics.COLOR_BLACK)
    love.graphics.print("" .. (totalFrames / totalTime), 10, 10)
    love.graphics.setColor(graphics.COLOR_WHITE)
  end
  
end
