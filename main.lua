-- The main code used to run the game.

-- NOTE: There's a glitch with two slugs at once, if they merge the same cells, then multiple cells
-- will be created and they will overlap

movement = require("movement")
misc = require("misc")
grid = require("grid")
entities = require("entities")
spaces = require("spaces")
graphics = require("graphics")
levelgen = require("levelgen")
ui = require("ui")


GAMEPLAY = 0
TAKEOFF_COUNTDOWN = 1
TAKEOFF = 2
CHOOSE_SPACE = 3
WINTER = 4
phase = GAMEPLAY

TURN_DELAY = 24  -- Amount of frames that movement is locked for after a move
turnDelayTimer = 0


takeoffCountdownTimer = 0
takeoffWaitCount = 0
playerTransitionX = 0
playerTransitionY = 0
TAKEOFF_COUNTDOWN_WAIT_LENGTH = 90

TAKEOFF_WAIT_LENGTH = 36
TAKEOFF_LEVEL_DOWN_LENGTH = 45
TAKEOFF_PLAYER_CATCHUP_LENGTH = 55
TAKEOFF_DAYS_UNTIL_LENGTH = 300
TAKEOFF_PLAYER_DOWN_LENGTH = 15

TAKEOFF_WAIT_FRAME = TAKEOFF_WAIT_LENGTH
TAKEOFF_LEVEL_DOWN_FRAME = TAKEOFF_WAIT_FRAME + TAKEOFF_LEVEL_DOWN_LENGTH
TAKEOFF_PLAYER_CATCHUP_FRAME = TAKEOFF_LEVEL_DOWN_FRAME + TAKEOFF_PLAYER_CATCHUP_LENGTH
TAKEOFF_DAYS_UNTIL_FRAME = TAKEOFF_PLAYER_CATCHUP_FRAME + TAKEOFF_DAYS_UNTIL_LENGTH
TAKEOFF_PLAYER_DOWN_FRAME = TAKEOFF_DAYS_UNTIL_FRAME + TAKEOFF_PLAYER_DOWN_LENGTH

TAKEOFF_TEXT_FADE_IN_FRAME = TAKEOFF_PLAYER_CATCHUP_FRAME + 20
TAKEOFF_TEXT_FADE_OUT_FRAME = TAKEOFF_DAYS_UNTIL_FRAME - 90

DAYS_LEFT_COLOR = graphics.convertColor({220, 255, 235})
  
LANDING_WAIT_LENGTH = 30
LANDING_LEVEL_DOWN_LENGTH = 60

LANDING_WAIT_FRAME = LANDING_WAIT_LENGTH
LANDING_LEVEL_DOWN_FRAME = LANDING_WAIT_FRAME + LANDING_LEVEL_DOWN_LENGTH
LAST_LEVEL_MOVEMENT_FRAME = LANDING_LEVEL_DOWN_FRAME

FREEZE_COLOR = graphics.convertColor({43, 253, 253, 75})
iceWall = graphics.SpriteSheet:new("iceWall.png", 1)


gridXOffset = 150
gridYOffset = 50
pixel = 3
tileSize = (pixel * spaces.singlePadsSprite.width)
showFPS = false

daysFont = love.graphics.newFont("m6x11.ttf", 48 * pixel)
winterFont = love.graphics.newFont("m6x11.ttf", 16 * pixel)

lockMovement = false
  
-- Keeps track of mouse events
mouseClicked = false
mouseHeld = false
mouseReleased = false
mouseDownPreviousFrame = false

mouseSpace = nil


daysLeft = 1  -- Days until winter

interface = nil  -- UI
player = nil  -- Player object
level = nil  -- Level grid object


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


function drawDaysLeft(x, y)
  local dayString
  
  local winterX
  local winterY
  
  if daysLeft == 1 then
    dayString = " DAY"
  else
    dayString = " DAYS"
  end
  
  winterX = (daysFont:getWidth(daysLeft .. dayString) - winterFont:getWidth("LEFT UNTIL WINTER")) / 2
  winterX = math.floor(winterX) + x
  winterY = y + pixel * 42
  
  love.graphics.setFont(daysFont)
  love.graphics.print(daysLeft .. dayString, x, y)
  love.graphics.setFont(winterFont)
  love.graphics.print("LEFT UNTIL WINTER", winterX, winterY)
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


--- Prevents the player from moving for a certain amount of frames.
function lockInput(frames)
  lockMovement = true
  turnDelayTimer = frames
end


function loadGameplay()
  phase = GAMEPLAY
end


function updateGameplay()

  player:updateAnimation()
  level:updateEnemies()
  level:updateAllSpaces()
  interface:update()
  
  -- Updates the input lock timer
  if turnDelayTimer > 0 then
    turnDelayTimer = turnDelayTimer - 1
    
    if turnDelayTimer <= 0 then
      lockMovement = false
    end
  
  end
  
  
  -- What happens when the mouse is clicked
  if not lockMovement and mouseReleased and mouseSpace then
    
    local validMove
    local eatFlies
    
    -- If you click on the player's space, start the level transition
    if mouseSpace.occupiedBy == player.body then
      loadTakeoffCountdown()
      
    elseif player.body.space.adjacentList[mouseSpace] then
      if mouseSpace:isOccupied() then
        
        if #mouseSpace.occupiedBy.bugs > 0 then
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
      
      lockInput(TURN_DELAY)
      
      -- Eats flies, if the space eaten from was valid
      if eatFlies then
        player:eatBug(mouseSpace)
      
      -- Move the player, if the move was valid
      else

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


function drawGameplay()
  local highlighted
  local playerXOffset = 0
  local playerYOffset = 0
  
  -- level:drawDebug(gridXOffset, gridYOffset, tileSize)
  
  for space, _ in pairs(level.spacesList) do
    highlighted = false
    
    if space.occupiedBy == player.body then
      highlighted = true
      
    elseif not (space:isOccupied() and (#space.occupiedBy.bugs <= 0)) then
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
  
  -- level:drawDistances(gridXOffset, gridYOffset, tileSize)
  level:drawEnemies(gridXOffset, gridYOffset, pixel, tileSize)
  player:draw(gridXOffset + playerXOffset, gridYOffset + playerYOffset, pixel, tileSize)
  interface:draw(pixel)
  
end


function loadTakeoffCountdown()
  phase = TAKEOFF_COUNTDOWN
  takeoffCountdownTimer = 0
  takeoffWaitCount = 0
  
  player.body.moveDirection = "up"
  player.readyingLeap = true
  player:nextLeapReadyAnim()
  

end


function updateTakeoffCountdown()
  player:updateAnimation()
  level:updateEnemies()
  level:updateAllSpaces()
  interface:update()
  
  takeoffCountdownTimer = takeoffCountdownTimer + 1
  
  if takeoffCountdownTimer == TAKEOFF_COUNTDOWN_WAIT_LENGTH then
    takeoffCountdownTimer = 0
    takeoffWaitCount = takeoffWaitCount + 1
    
    if takeoffWaitCount == 3 then
      loadTakeoff()
    else
      level:doEnemyTurns(player)
      player:nextLeapReadyAnim()
    end
    
  end
  
end


function drawTakeoffCountdown()
  for space, _ in pairs(level.spacesList) do
    space:draw(gridXOffset, gridYOffset, pixel, pixel*2, pixel*2, highlighted)
  end
  
  level:drawEnemies(gridXOffset, gridYOffset, pixel, tileSize)
  player:draw(gridXOffset, gridYOffset, pixel, tileSize)
  interface:draw(pixel)
end


function loadTakeoff()
  phase = TAKEOFF
  takeoffFrame = 0
  playerTransitionX = gridXOffset
  playerTransitionY = gridYOffset

  local first = gridYOffset
  local last = love.graphics.getHeight()
  local length = TAKEOFF_LEVEL_DOWN_LENGTH
  levelDownMovement = movement.Sine:newFadeIn(first, last, length)
  
  player.animation = player.leapAnim
  player.readyingLeap = false
  player.inLeap = true
  
  daysLeft = daysLeft - 1
  daysLeftAlpha = 0
  daysLeftY = pixel * 54
  
  TAKEOFF_LEFT = 1
  TAKEOFF_RIGHT = 2
  takeoffVariant = math.random(1, 2)
end


function updateTakeoff()
  
  player:updateAnimation()
  
  takeoffFrame = takeoffFrame + 1
  
  -- Gives the player a new single-celled space so that only one copy is drawn
  if player.leapAnim and player.animation.frame == 3 and player.animation.delayCount == 0 then 
    local col, row = player.body.space:randomCell()
    player.body.space = spaces.Space:new(col, row, 1, 1)
    
  -- Sets the player's space to the top left of the grid so that we can draw them at certain locations
  elseif takeoffFrame == TAKEOFF_LEVEL_DOWN_FRAME then
    player.body.space = spaces.Space:new(1, 1, 1, 1)
    
    if takeoffVariant == TAKEOFF_LEFT then
      playerTransitionX = pixel * 50
    elseif takeoffVariant == TAKEOFF_RIGHT then
      playerTransitionX = pixel * 196
    end
    
    playerTransitionY = -pixel * 270
    
  end
  
  if takeoffFrame < TAKEOFF_WAIT_FRAME then
    level:updateEnemies()
    if player.animation ~= player.leapAnim or player.animation.frame >= 3 then
      playerTransitionY = playerTransitionY - (pixel * 10)
    end
    
  elseif takeoffFrame < TAKEOFF_LEVEL_DOWN_FRAME then
    level:updateEnemies()
    gridYOffset = levelDownMovement:valueAt(takeoffFrame - TAKEOFF_WAIT_FRAME)
    
  elseif takeoffFrame < TAKEOFF_PLAYER_CATCHUP_FRAME then
    playerTransitionY = playerTransitionY + (pixel * 5)
    
  elseif takeoffFrame < TAKEOFF_DAYS_UNTIL_FRAME then
    playerTransitionY = playerTransitionY + (pixel / 2)
    daysLeftY = daysLeftY + (pixel / 8)
    
    -- Fades in text
    if takeoffFrame >= TAKEOFF_TEXT_FADE_IN_FRAME and takeoffFrame < TAKEOFF_TEXT_FADE_OUT_FRAME then
      if daysLeftAlpha < 1 then
        daysLeftAlpha = daysLeftAlpha + 0.012
        
        if daysLeftAlpha > 1 then
          daysLeftAlpha = 1
        end
      end
    
    -- Fades out text
    elseif takeoffFrame >= TAKEOFF_TEXT_FADE_OUT_FRAME then
      if daysLeftAlpha > 0 then
        daysLeftAlpha = daysLeftAlpha - 0.012
        
        if daysLeftAlpha < 0 then
          daysLeftAlpha = 0
        end
      end
      
    end
    
  elseif takeoffFrame < TAKEOFF_PLAYER_DOWN_FRAME then
    playerTransitionY = playerTransitionY + (pixel * 5)
    
  else
    if daysLeft > 0 then
      loadChooseSpace()
    else
      loadWinter()
    end
  end
  
end


function drawTakeoff()
  local playerX = playerTransitionX
  local playerY = playerTransitionY
  
  if takeoffFrame < TAKEOFF_LEVEL_DOWN_FRAME then
    for space, _ in pairs(level.spacesList) do
      space:draw(gridXOffset, gridYOffset, pixel, pixel*2, pixel*2, highlighted)
    end
    
    level:drawEnemies(gridXOffset, gridYOffset, pixel, tileSize)
    
  elseif takeoffFrame < TAKEOFF_PLAYER_DOWN_FRAME then
    
    if math.random(1, 4) == 1 then
      playerX = playerX + math.random(-2, -2)
      playerY = playerY + math.random(-2, -2)
    end
  end
  
  player:draw(playerX, playerY, pixel, tileSize)
  interface:draw(pixel)
  
  -- Draws the days left text
  if takeoffFrame >= TAKEOFF_LEVEL_DOWN_FRAME and takeoffFrame < TAKEOFF_PLAYER_DOWN_FRAME then
    
    local textColor = {}
    for i = 1, 3 do
      textColor[i] = DAYS_LEFT_COLOR[i]
    end
    textColor[4] = daysLeftAlpha
    love.graphics.setColor(textColor)
    
    -- Variant where the player is on the left and the text is on the right
    if takeoffVariant == TAKEOFF_LEFT then
      drawDaysLeft(pixel * 100, math.floor(daysLeftY))
      
    -- Variant where the player is on the right and the text is on the left
    elseif takeoffVariant == TAKEOFF_RIGHT then
      drawDaysLeft(pixel * 58, math.floor(daysLeftY))
    end
    
    love.graphics.setColor(graphics.COLOR_WHITE)
  end
  
end


function loadChooseSpace()
  phase = CHOOSE_SPACE
  
  level = levelgen.randomLevel()
  
  local first = -love.graphics.getHeight()
  local last = math.floor((love.graphics.getHeight() - (level.height * tileSize)) / 2)
  local length = LANDING_LEVEL_DOWN_LENGTH
  
  levelDownMovement = movement.Sine:newFadeOut(first, last, length)
  
  movementFrame = 0
  
  gridXOffset = math.floor((love.graphics.getWidth() - (level.width * tileSize)) / 2)
  gridYOffset = first
  
  spaceChosen = false
  
  playerLandingSpace = nil
  playerMovement = nil
  player.flailing = false
end


function updateChooseSpace()
  player:updateAnimation()
  level:updateEnemies()
  level:updateAllSpaces()
  interface:update()
  
  
  if movementFrame < LAST_LEVEL_MOVEMENT_FRAME then
    movementFrame = movementFrame + 1
    
    if movementFrame < LANDING_WAIT_FRAME then
      
    elseif movementFrame < LANDING_LEVEL_DOWN_FRAME then
      gridYOffset = levelDownMovement:valueAt(movementFrame - LANDING_WAIT_FRAME)
    else
      gridYOffset = levelDownMovement.last
    end
  end
  
  -- If the player is landing on the island
  if playerMovement then
    if playerMovement.frame < playerMovement.length then
      playerMovement.frame = playerMovement.frame + 1
      
      playerTransitionY = playerMovement:valueAt(playerMovement.frame)
      
      -- On the fourth last frame of the player's movement, swap their space to the landing space
      if playerMovement.frame == playerMovement.length - 3 then
        player.body.space = playerLandingSpace
      
      -- On the last frame, switch to the landing animation
      elseif playerMovement.frame == playerMovement.length then
        playerLandingSpace.occupiedBy = player.body
        player.animation = player.leapLandingAnim
        player.landing = true
        lockInput(TURN_DELAY)
        
        level:doEnemyTurns(player)
        loadGameplay()
      end
    end
  
  -- Otherwise, check for the mouse clicking on a space to land on
  elseif not (movementFrame < LAST_LEVEL_MOVEMENT_FRAME) and mouseReleased and mouseSpace then
    
    if not mouseSpace:isOccupied() then
      playerLandingSpace = mouseSpace
      
      local col
      local row
      col, row = playerLandingSpace:randomCell()
      player.body.space = spaces.Space:new(col, row, 1, 1)
      spaceChosen = true
      
      local first = love.graphics.getHeight()
      local last = gridYOffset
      
      playerMovement = movement.Linear:new(first, last, 20)
      
      player.animation = player.leapLandingAnim
      
      playerTransitionX = gridXOffset
      
    end
    
  end
end


function drawChooseSpace()
  local highlighted

  for space, _ in pairs(level.spacesList) do
    if space == mouseSpace and not space:isOccupied() then
      highlighted = true
    else
      highlighted = false
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

  level:drawEnemies(gridXOffset, gridYOffset, pixel, tileSize)
  player:draw(playerTransitionX, playerTransitionY, pixel, tileSize)
  interface:draw(pixel)
end


function loadWinter()
  phase = WINTER
  
  level = levelgen.winterLevel()
  
  local first = -love.graphics.getHeight()
  local last = math.floor((love.graphics.getHeight() - (level.height * tileSize)) / 2)
  local length = LANDING_LEVEL_DOWN_LENGTH
  
  levelDownMovement = movement.Sine:newFadeOut(first, last, length)
  
  movementFrame = 0
  
  gridXOffset = math.floor((love.graphics.getWidth() - (level.width * tileSize)) / 2)
  gridYOffset = first
  
  playerLandingSpace = nil
  playerMovement = nil
  player.flailing = false
  
  winterFrame = 0  -- Starts after the frog lands
  winterFreezeY = -pixel * 10
  
  WINTER_START_WAIT_LENGTH = 30
  WINTER_FREEZE_LENGTH = 30
  
  -- Energy decreases once every 9 frames, so the minimum energy requirement is
  -- 360 / 9 = 40 and the maximum is 450 / 9 = 50.
  winterFrozenLength = math.random(360, 450)
  WINTER_UNFREEZE_LENGTH = 30
  
  WINTER_START_WAIT_FRAME = WINTER_START_WAIT_LENGTH
  WINTER_FREEZE_FRAME = WINTER_START_WAIT_FRAME + WINTER_FREEZE_LENGTH
  winterFrozenFrame = WINTER_FREEZE_FRAME + winterFrozenLength
  winterUnfreezeFrame = winterFrozenFrame + WINTER_UNFREEZE_LENGTH
end


function updateWinter()
  player:updateAnimation()
  level:updateAllSpaces()
  interface:update()
  
  if movementFrame < LAST_LEVEL_MOVEMENT_FRAME then
    movementFrame = movementFrame + 1
    
    if movementFrame < LANDING_WAIT_FRAME then
      
    elseif movementFrame < LANDING_LEVEL_DOWN_FRAME then
      gridYOffset = levelDownMovement:valueAt(movementFrame - LANDING_WAIT_FRAME)
    else
      gridYOffset = levelDownMovement.last
    end
  end
  
  if playerMovement then
    
    -- If the player is landing on the island
    if playerMovement.frame < playerMovement.length then
      playerMovement.frame = playerMovement.frame + 1
      
      playerTransitionY = playerMovement:valueAt(playerMovement.frame)
      
      -- On the fourth last frame of the player's movement, swap their space to the landing space
      if playerMovement.frame == playerMovement.length - 3 then
        player.body.space = playerLandingSpace
      
      -- On the last frame, switch to the landing animation
      elseif playerMovement.frame == playerMovement.length then
        playerLandingSpace.occupiedBy = player.body
        player.animation = player.leapLandingAnim
        player.landing = true
        playerTransitionX = gridXOffset
        playerTransitionY = gridYOffset
      end
    
    -- Every frame after landing, this increases
    else
      winterFrame = winterFrame + 1
      
    end
  
  -- Otherwise, once the level has moved up, prepare the player for landing
  elseif not (movementFrame < LAST_LEVEL_MOVEMENT_FRAME) then
    
    playerLandingSpace = level.spacesGrid[3][3]
    
    local col
    local row
    col, row = playerLandingSpace:randomCell()
    player.body.space = spaces.Space:new(col, row, 1, 1)
    spaceChosen = true
    
    local first = love.graphics.getHeight()
    local last = gridYOffset
    
    playerMovement = movement.Linear:new(first, last, 20)
    
    player.animation = player.leapLandingAnim
    
    playerTransitionX = gridXOffset
    
  end
  
  if winterFrame < WINTER_START_WAIT_FRAME then
    
  elseif winterFrame < WINTER_FREEZE_FRAME then
    winterFreezeY = winterFreezeY + 30
  elseif winterFrame < winterFrozenFrame then
    
    -- Every nine frame, subtract one energy from the player
    if winterFrame % 9 == 1 and player.energy > 0 then
      player.energy = player.energy - 1
      
    end
  
  elseif winterFrame < winterUnfreezeFrame then
    winterFreezeY = winterFreezeY - 30
  end
end


function drawWinter()
  for space, _ in pairs(level.spacesList) do
    space:draw(gridXOffset, gridYOffset, pixel, pixel*2, pixel*2, highlighted)
  end
  
  player:draw(playerTransitionX, playerTransitionY, pixel, tileSize)
  interface:draw(pixel)
  
  -- Draws the icy sheet that covers the screen
  if winterFreezeY > 0 then
    love.graphics.setColor(FREEZE_COLOR)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), winterFreezeY)
    love.graphics.setColor(graphics.COLOR_WHITE)
    iceWall:draw(1, 0, winterFreezeY, pixel)
  end
  
  love.graphics.print("" .. winterFrame, 0, 0)
  love.graphics.print("" .. player.energy, 0, 100)
end


--- Runs when the game is started.
function love.load()
  math.randomseed(os.time())
  
  love.window.setMode(267 * pixel, 200 * pixel)
  
  -- gifMode()
  
  love.graphics.setBackgroundColor(graphics.COLOR_WATER)
  
  level = levelgen.randomLevel()
  
  -- Centers the level on the screen
  gridXOffset = math.floor((love.graphics.getWidth() - (level.width * tileSize)) / 2)
  gridYOffset = math.floor((love.graphics.getHeight() - (level.height * tileSize)) / 2)
  
  --level:addEnemy(entities.Rat:new(level.spacesGrid[5][4]))
  --level:addEnemy(entities.Snake:newRandom(level.spacesGrid[5][5]))
  --level:addEnemy(entities.Snake:newRandom(level.spacesGrid[6][7]))
  --level:addEnemy(entities.Slug:new(level.spacesGrid[7][1]))
  
  local startSpace
  while true do
    space = misc.randomChoice(level.spacesList)
    
    if not space:isOccupied() then
      player = entities.Player:new(space)
      break
    end
    
  end
  
  interface = ui.UI:new(player)
  ui.updateScreenSize(pixel)
  
  level:updateDistances(player.body.space)
  
  -- Tracks fps
  totalTime = 0
  totalFrames = 0

end


--- Runs every frame.
function love.update(dt)
  
  -- Updates fps
  if showFPS then
    totalTime = totalTime + dt
    totalFrames = totalFrames + 1
  end
  
  -- Updates mouse events
  updateMouse()
  mouseSpace = spaceAt(level, love.mouse.getX(), love.mouse.getY())
  
  if phase == GAMEPLAY then
    updateGameplay()
  elseif phase == TAKEOFF_COUNTDOWN then
    updateTakeoffCountdown()
  elseif phase == TAKEOFF then
    updateTakeoff()
  elseif phase == CHOOSE_SPACE then
    updateChooseSpace()
  elseif phase == WINTER then
    updateWinter()
  end

end


--- Runs every frame.
function love.draw()
  
  if phase == GAMEPLAY then
    drawGameplay()
  elseif phase == TAKEOFF_COUNTDOWN then
    drawTakeoffCountdown()
  elseif phase == TAKEOFF then
    drawTakeoff()
  elseif phase == CHOOSE_SPACE then
    drawChooseSpace()
  elseif phase == WINTER then
    drawWinter()
  end
  
  -- FPS counter
  if showFPS then
    love.graphics.setColor(graphics.COLOR_BLACK)
    love.graphics.print("" .. (totalFrames / totalTime), 10, 10)
    love.graphics.setColor(graphics.COLOR_WHITE)
  end
  
end
