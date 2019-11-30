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

tutorialTransitioning = false
tutorialPhase = 0

iceWallDown = graphics.SpriteSheet:new("iceWallDown.png", 1)
iceWallUp = graphics.SpriteSheet:new("iceWallUp.png", 1)

gridXOffset = 0
gridYOffset = 0
pixel = 3
tileSize = (pixel * spaces.singlePadsSprite.width)
showFPS = false

graphics.reloadFonts(pixel)

lockMovement = false
  
-- Keeps track of mouse events
mouseClicked = false
mouseHeld = false
mouseReleased = false
mouseDownPreviousFrame = false

mouseSpace = nil


daysLeft = 0  -- Days until winter
firstLanding = true
firstLandingTextAlpha = 1
firstLandingTextX = 0
firstLandingTextY = 0
STARTING_DAYS_LEFT = 7  -- How many days left you start with

interface = nil  -- UI
player = nil  -- Player object
level = nil  -- Level grid object

onMenu = true
onTutorial = false

screenTransition = graphics.ScreenTransition:new()
tutorialResetButton = nil

survivedWinter = false
returnToMenuButton = nil
continueButton = nil

returnToMenuTextX = 0
returnToMenuTextY = 0
continueTextX = 0
continueTextY = 0

takeoffFromWinter = false


function debugTutorial(phase)
  onMenu = false
  onTutorial = true
  tutorialPhase = phase - 1
  
  loadTutorialTransition()
end


--- Changes the pixel multiplier of the screen.
function changePixel(value)
  pixel = value
  tileSize = (pixel * spaces.singlePadsSprite.width)
  
  love.window.setMode(267 * pixel, 200 * pixel)
  
  ui.updateScreenSize(pixel)
  
  graphics.reloadFonts(pixel)
  
  -- Centers the level on the screen
  gridXOffset = math.floor((love.graphics.getWidth() - (level.width * tileSize)) / 2)
  gridYOffset = math.floor((love.graphics.getHeight() - (level.height * tileSize)) / 2)
  
  -- Creates a new screen transition to match the size of the screen
  screenTransition = graphics.ScreenTransition:new()
  
end


--- Changeds a few settings for gif recording.
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
  
  local daysWidth = graphics.daysFont:getWidth(daysLeft .. dayString)
  local winterWidth = graphics.winterFont:getWidth("LEFT UNTIL WINTER")
  winterX = math.floor((daysWidth - winterWidth) / 2) + x
  winterY = y + pixel * 42
  
  love.graphics.setFont(graphics.daysFont)
  love.graphics.print(daysLeft .. dayString, x, y)
  love.graphics.setFont(graphics.winterFont)
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
  
  
  -- If you're on the menu, check if you land on any of the "button" spaces
  if onMenu and not lockMovement then
    
    -- If you land on the "Play" space, start a game
    if player.body.space == level.spacesGrid[6][1] then
      loadTakeoffCountdown()
      daysLeft = STARTING_DAYS_LEFT + 1
      onMenu = false
      
    -- If you land on the "Tutorial" space, start the tutorial
    elseif player.body.space == level.spacesGrid[9][1] then
      onMenu = false
      onTutorial = true
      loadTutorialTransition()
      
    -- If you land on a screen size space, change the screen size
    else
      for i = 6, 10 do
        if player.body.space == level.spacesGrid[i][7] then
          
          -- Only update the screen size if the chosen size is different
          if (i - 5) ~= pixel then
            changePixel(i - 5)
          end
          
        end
      end
    end
    
  end
  
  
  -- If we're in the tutorial transition
  if tutorialTransitioning then
    
    -- Moves the previous level down
    if tutorialMovePrevious.frame < tutorialMovePrevious.length then
      tutorialMovePrevious.frame = tutorialMovePrevious.frame + 1
      gridYOffset = tutorialMovePrevious:currentValue()
      
      -- If that's done, switch the level
      if tutorialMovePrevious.frame == tutorialMovePrevious.length then
        level = tutorialNextLevel
        gridXOffset = level:centerScreenX(tileSize)
        
        -- Places the player at their starting position
        local startPosition = levelgen.tutorialStartPositions[tutorialPhase]
        player.body:goTo(level.spacesGrid[startPosition[1]][startPosition[2]])
        player.body.moveDirection = levelgen.tutorialStartDirections[tutorialPhase]
        
        -- Removes the reset button
        tutorialResetButton = nil
      end
    
    -- Moves the next level down
    elseif tutorialMoveCurrent.frame < tutorialMoveCurrent.length then
      tutorialMoveCurrent.frame = tutorialMoveCurrent.frame + 1
      gridYOffset = tutorialMoveCurrent:currentValue()
      
      -- If that's done, turn the transition off
      if tutorialMoveCurrent.frame == tutorialMoveCurrent.length then
        tutorialTransitioning = false
      end
      
    end
    
  end
  
  
  -- What happens when the mouse is clicked
  local movementAttempted = mouseReleased and mouseSpace
  local lockedMovement = lockMovement or tutorialTransitioning or screenTransition.activated
  
  if movementAttempted and not lockedMovement then
    
    local validMove
    local eatFlies
    
    -- If you click on the player's space, start the level transition
    if mouseSpace.occupiedBy == player.body then
      if not (onMenu or onTutorial) then
        loadTakeoffCountdown()
      end
      
      
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
  
  
  if onTutorial then
    if not (screenTransition.activated or tutorialTransitioning) then
      if movementAttempted and mouseSpace == tutorialResetButton then
        screenTransition:start()
      
      elseif interface.displayHealth <= 0 then
        screenTransition:start()
        
      end
    
    else
  
      if screenTransition.middleFrame then
        tutorialResetButton = nil
        
        player.health = 5
        player.energy = 0
        
        level = levelgen.tutorialLevelGenerators[tutorialPhase]()
        
        local position = levelgen.tutorialStartPositions[tutorialPhase]
        player.body:goTo(level.spacesGrid[position[1]][position[2]])
        player.body.moveDirection = levelgen.tutorialStartDirections[tutorialPhase]
      end
    end
  end
  
  
  -- Detects tutorial progress conditions
  if onTutorial and not tutorialTransitioning then
    
    -- End of intro
    if tutorialPhase == 1 then
      if player.body.space == level.spacesGrid[1][2] then
        loadTutorialTransition()
      end
    
    -- End of noneuclilypads 1
    elseif tutorialPhase == 2 then
      if player.body.space == level.spacesGrid[9][2] then
        loadTutorialTransition()
      end
    
    -- End of noneuclilypads 2
    elseif tutorialPhase == 3 then
      if player.body.space == level.spacesGrid[1][3] then
        loadTutorialTransition()
        
        -- Fades in the hearts ui
        interface.heartVineFader:setLength(30)
        interface.heartVineFader:fadeUp()
      end
    
    -- End of intro to enemies
    elseif tutorialPhase == 4 then
           
      if player.body.space == level.spacesGrid[8][3] then
        loadTutorialTransition()
        
        -- Fades in the energy bar ui
        interface.energyBarFader:setLength(30)
        interface.energyBarFader:fadeUp()
      
      elseif (not screenTransition.activated) and interface.displayHealth <= 4 then
        screenTransition:start()
        
      end
      
    
    -- End of intro to fleas
    elseif tutorialPhase == 5 then
      if player.body.space == level.spacesGrid[1][4] then
        
        -- Check that the player ate all the fleas
        for rat, _ in pairs(level.enemyList) do
          if #rat.body.bugs == 0 then
            loadTutorialTransition()
            break
          end
        end
        
      end
    
    -- End of fleas 2
    elseif tutorialPhase == 6 then
      if player.body.space == level.spacesGrid[9][4] then
        
        -- Checks that the player ate enough fleas
        local totalFleas = 0
        
        for rat, _ in pairs(level.enemyList) do
          totalFleas = totalFleas + #rat.body.bugs
        end
        
        if totalFleas <= 2 then
          loadTutorialTransition()
        end
      end
      
    -- End of enemies with noneuclilypads 1
    elseif tutorialPhase == 7 then
      if player.body.space == level.spacesGrid[1][4] then
        
        -- Check that the player ate all the fleas
        for rat, _ in pairs(level.enemyList) do
          if #rat.body.bugs == 0 then
            loadTutorialTransition()
            break
          end
        end
        
      end
    
    -- End of enemies with noneuclilypads 2
    elseif tutorialPhase == 8 then
      if player.body.space == level.spacesGrid[9][4] then
        
        -- Checks that the player ate enough fleas
        local totalFleas = 0
        
        for rat, _ in pairs(level.enemyList) do
          totalFleas = totalFleas + #rat.body.bugs
        end
        
        if totalFleas <= 2 then
          loadTutorialTransition()
        end
      end
      
    -- End of last tutorial phase
    elseif tutorialPhase == 9 then
      
      if not lockMovement and mouseReleased and mouseSpace == player.body.space then
        loadTakeoffCountdown()
        
        daysLeft = STARTING_DAYS_LEFT + 1
        onTutorial = false
        tutorialPhase = 0
        
        player:drainEnergy()
      end
      
    end
    
    -- Displays the "reset" button if the player gets trapped
    if not (tutorialTransitioning or tutorialResetButton) and tutorialPhase >= 4 then
      local validMoveExists = false
      for space, _ in pairs(player.body.space.adjacentList) do
        if not space:isOccupied() then
          validMoveExists = true
          break
        end
      end
      
      if not validMoveExists then
        level:addSpace({{4, 7}, {5, 7}, {6, 7}})
        tutorialResetButton = level.spacesGrid[4][7]
        tutorialResetButton.isButton = true
      end
      
    end
    
  end
  
  
  -- Fades out the "Choose a space to land on" text"
  if firstLanding and not (onMenu or onTutorial) then
    firstLandingTextAlpha = firstLandingTextAlpha - 0.02
    
    if firstLandingTextAlpha < 0 then
      firstLandingTextAlpha = 0
      firstLanding = false
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
    
    if space.isButton and mouseSpace == space then
      highlighted = true
      
    elseif space.occupiedBy == player.body then
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
  level:drawTexts(gridXOffset, gridYOffset, pixel)
  level:drawEnemies(gridXOffset, gridYOffset, pixel, tileSize)
  player:draw(gridXOffset + playerXOffset, gridYOffset + playerYOffset, pixel, tileSize)
  
  interface:draw(pixel)
  
  -- Draws the "choose a space to land on" text
  if firstLanding and not (onMenu or onTutorial) then
    local x = firstLandingTextX
    local y = firstLandingTextY + gridYOffset
    
    graphics.setAlpha(firstLandingTextAlpha)
    love.graphics.setFont(graphics.tutorialFont)
    love.graphics.print("Choose a space to land on!", x, y)
  end
  
  if tutorialResetButton then
    love.graphics.setFont(graphics.tutorialFont)
    love.graphics.setColor(graphics.COLOR_WHITE)
    
    love.graphics.print("Reset", gridXOffset + pixel * 94, gridYOffset + pixel * 148)
  end
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
      level:updateDistances(player.body.space)
      level:doEnemyTurns(player)
      player:nextLeapReadyAnim()
    end
    
  end
  
end


function drawTakeoffCountdown()
  for space, _ in pairs(level.spacesList) do
    space:draw(gridXOffset, gridYOffset, pixel, pixel*2, pixel*2, highlighted)
  end
  
  level:drawTexts(gridXOffset, gridYOffset, pixel)
  
  -- Draws the winter text on the winter level
  if takeoffFromWinter then
    drawWinterText()
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
  local last = love.graphics.getHeight() + pixel * 40
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
  
  -- Resets fade length to defaults
  interface.heartVineFader:setLength(ui.DEFAULT_FADE_LENGTH)
  interface.energyBarFader:setLength(ui.DEFAULT_FADE_LENGTH)
  
end


function updateTakeoff()
  
  player:updateAnimation()
  interface:update()
  
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
  
  -- Fades in the UI (if it isn't already faded in already) when the days left text starts fading in
  elseif takeoffFrame == TAKEOFF_TEXT_FADE_IN_FRAME then
    interface.heartVineFader:fadeUp()
    interface.energyBarFader:fadeUp()
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
    
    level:drawTexts(gridXOffset, gridYOffset, pixel)
    
    -- Draws the winter text on the winter level if the winter level is still on screen
    if takeoffFromWinter then
      drawWinterText()
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
  
  level = levelgen.winterLevel()
  level = levelgen.randomLevel()
  
  local first = -love.graphics.getHeight()
  local last = level:centerScreenY(tileSize)
  local length = LANDING_LEVEL_DOWN_LENGTH
  
  levelDownMovement = movement.Sine:newFadeOut(first, last, length)
  
  movementFrame = 0
  
  gridXOffset = math.floor((love.graphics.getWidth() - (level.width * tileSize)) / 2)
  gridYOffset = first
  
  spaceChosen = false
  
  playerLandingSpace = nil
  playerMovement = nil
  player.flailing = false
  
  -- Initiates the choose a space text if it's the player's first ever time landing
  if firstLanding then
    local textWidth = graphics.tutorialFont:getWidth("Choose a space to land on!")
    local screenWidth = love.graphics.getWidth()
    firstLandingTextX = math.floor((screenWidth - textWidth) / 2)
    
    if level.height <= 7 then
      local textHeight = graphics.tutorialFont:getHeight()
      local levelTop = level:centerScreenY(tileSize)
      firstLandingTextY = math.floor((levelTop - textHeight) / 2) - levelTop
    else
      firstLandingTextY = pixel * 4
    end
    
  end
  
  -- After the takeoff is done, then the takeoff stops being from winter.
  takeoffFromWinter = false
  
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
        
        level:updateDistances(player.body.space)
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
  
  level:drawTexts(gridXOffset, gridYOffset, pixel)
  level:drawEnemies(gridXOffset, gridYOffset, pixel, tileSize)
  player:draw(playerTransitionX, playerTransitionY, pixel, tileSize)
  interface:draw(pixel)
  
  -- Draws the "choose a space to land on" text
  if firstLanding then
    local x = firstLandingTextX
    local y = firstLandingTextY + gridYOffset
    
    graphics.setAlpha(firstLandingTextAlpha)
    love.graphics.setFont(graphics.tutorialFont)
    love.graphics.print("Choose a space to land on!", x, y)
  end
  
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
  winterFreezeDownY = -pixel * 24
  winterFreezeUpY = -pixel * 24
  
  WINTER_START_WAIT_LENGTH = 30
  WINTER_FREEZE_LENGTH = 30
  
  -- Energy decreases once every 9 frames, so the minimum energy requirement is
  -- 360 / 9 = 40 and the maximum is 441 / 9 = 49.
  winterFrozenLength = math.random(360, 441)
  WINTER_UNFREEZE_LENGTH = 30
  WINTER_RESULTS_LENGTH = 120
  WINTER_BUTTONS_LENGTH = 150
  
  WINTER_START_WAIT_FRAME = WINTER_START_WAIT_LENGTH
  WINTER_FREEZE_FRAME = WINTER_START_WAIT_FRAME + WINTER_FREEZE_LENGTH
  winterFrozenFrame = WINTER_FREEZE_FRAME + winterFrozenLength
  winterUnfreezeFrame = winterFrozenFrame + WINTER_UNFREEZE_LENGTH
  winterResultsFrame = winterUnfreezeFrame + WINTER_RESULTS_LENGTH
  winterButtonsFrame = winterResultsFrame + WINTER_BUTTONS_LENGTH
end


function updateWinter()
  player:updateAnimation()
  level:updateAllSpaces()
  interface:update()
  
  -- Level moving down onto the screen
  if movementFrame < LAST_LEVEL_MOVEMENT_FRAME then
    movementFrame = movementFrame + 1
    
    if movementFrame < LANDING_WAIT_FRAME then
      
    elseif movementFrame < LANDING_LEVEL_DOWN_FRAME then
      gridYOffset = levelDownMovement:valueAt(movementFrame - LANDING_WAIT_FRAME)
    else
      gridYOffset = levelDownMovement.last
    end
  end
  
  -- Player landing on the island
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
    
    playerLandingSpace = level.spacesGrid[4][4]
    
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
  
  -- Stuff during the winter
  if winterFrame < WINTER_START_WAIT_FRAME then
  
  -- When the ice sheet comes down
  elseif winterFrame < WINTER_FREEZE_FRAME then
    winterFreezeDownY = winterFreezeDownY + 30
    
  -- During the frozen time
  elseif winterFrame < winterFrozenFrame then
    
    -- Every nine frame, subtract one energy from the player
    if winterFrame % 9 == 1 and player.energy > 0 then
      player.energy = player.energy - 1
      
    end
  
  -- When the ice shset goes back up
  elseif winterFrame < winterUnfreezeFrame then
    winterFreezeUpY = winterFreezeUpY + 30
  
  -- Frame when the buttons appear
  elseif winterFrame == winterButtonsFrame then
    if player.energy <= 0 then
      level:addSpace({{3, 7}, {4, 7}, {5, 7}})
      returnToMenuButton = level.spacesGrid[3][7]
      returnToMenuButton.isButton = true
      
      returnToMenuTextX = 58 * pixel
      returnToMenuTextY = 148 * pixel
      
    else
      level:addSpace({{1, 7}, {2, 7}, {3, 7}})
      returnToMenuButton = level.spacesGrid[2][7]
      returnToMenuButton.isButton = true
      
      returnToMenuTextX = 9 * pixel
      returnToMenuTextY = 148 * pixel
      
      level:addSpace({{5, 7}, {6, 7}, {7, 7}})
      continueButton = level.spacesGrid[5][7]
      continueButton.isButton = true
      
      continueTextX = 111 * pixel
      continueTextY = 148 * pixel
    end
  end
  
  -- If the screen transition has not been activated, allow clicking on buttons
  if not screenTransition.activated then
    
    -- If the return to menu button is clicked
    if mouseReleased and mouseSpace then
      if mouseSpace == returnToMenuButton then
        screenTransition:start()
    
      -- If the continue button is clicked
      elseif mouseSpace == continueButton then
        loadTakeoffCountdown()
        takeoffFromWinter = true
        daysLeft = STARTING_DAYS_LEFT + 1
        
        returnToMenuButton = nil
        continueButton = nil
      end
      
    end
      
  -- If the screen transition is on its middle frame, switch to the main menu
  elseif screenTransition.activated and screenTransition.middleFrame then
    onMenu = true
    level = levelgen.menuLevel()
    
    gridXOffset = level:centerScreenX(tileSize)
    gridYOffset = level:centerScreenY(tileSize)
    
    player.body:goTo(level.spacesGrid[8][4])
    player.energy = 0
    player.health = 5
    
    returnToMenuButton = nil
    continueButton = nil
    
    interface.heartVineFader:setValue(0)
    interface.energyBarFader:setValue(0)
    
    loadGameplay()
  end

end


function drawWinter()
  for space, _ in pairs(level.spacesList) do
    highlighted = false
    
    if space.isButton and mouseSpace == space then
      highlighted = true
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
  
  player:draw(playerTransitionX, playerTransitionY, pixel, tileSize)
  interface:draw(pixel)
  
  -- Draws the icy sheet that covers the screen
  if winterFreezeDownY > 0 and winterFreezeUpY < love.graphics.getHeight() then
    local rectY = winterFreezeUpY + (iceWallUp.singleHeight * pixel)
    local height = winterFreezeDownY - rectY
    
    love.graphics.setColor(FREEZE_COLOR)
    love.graphics.rectangle("fill", 0, rectY, love.graphics.getWidth(), height)
    
    love.graphics.setColor(graphics.COLOR_WHITE)
    iceWallDown:draw(1, 0, winterFreezeDownY, pixel)
    iceWallUp:draw(1, 0, winterFreezeUpY, pixel)
  end
  
  drawWinterText()
  
  -- love.graphics.print("" .. winterFrame, 0, 0)
  -- love.graphics.print("" .. player.energy, 0, 100)
end


function drawWinterText()
  love.graphics.setColor(graphics.COLOR_WHITE)
  love.graphics.setFont(graphics.winterFont)
  
  if winterFrame >= winterResultsFrame then
    
    if player.energy > 0 then
      love.graphics.print("YOU SURVIVED THE WINTER!", pixel * 56, gridYOffset + pixel * 4)
    else
      love.graphics.print("YOU DIDN'T SURVIVE THE WINTER", pixel * 40, gridYOffset + pixel * 4)
    end
    
  end
  
  love.graphics.setFont(graphics.tutorialFont)
  if returnToMenuButton then
    love.graphics.print("Main Menu", returnToMenuTextX + gridXOffset, returnToMenuTextY + gridYOffset)
  end
  if continueButton then
    love.graphics.print("Continue", continueTextX + gridXOffset, continueTextY + gridYOffset)
  end
end


function loadTutorialTransition()
  tutorialTransitioning = true
  tutorialPhase = tutorialPhase + 1
  
  tutorialNextLevel = levelgen.tutorialLevelGenerators[tutorialPhase]()
  
  local first = gridYOffset
  local last = love.graphics.getHeight() + pixel * 50
  tutorialMovePrevious = movement.Sine:newFadeIn(first, last, 45)
  
  first = -love.graphics.getHeight() - pixel * 50
  last = tutorialNextLevel:centerScreenY(tileSize)
  tutorialMoveCurrent = movement.Sine:newFadeOut(first, last, 70)
end



--- Runs when the game is started.
function love.load()
  math.randomseed(os.time())
  
  love.window.setMode(267 * pixel, 200 * pixel)
  
  -- gifMode()
  
  love.graphics.setBackgroundColor(graphics.COLOR_WATER)
  
  level = levelgen.menuLevel()
  -- level = levelgen.randomLevel()
  
  player = entities.Player:new(level.spacesGrid[8][4])
  
  interface = ui.UI:new(player)
  ui.updateScreenSize(pixel)
  
  --level:addEnemy(entities.Rat:new(level.spacesGrid[5][4]))
  --level:addEnemy(entities.Snake:newRandom(level.spacesGrid[5][5]))
  --level:addEnemy(entities.Snake:newRandom(level.spacesGrid[6][7]))
  --level:addEnemy(entities.Slug:new(level.spacesGrid[7][1]))
  -- level:updateDistances(player.body.space)
  
  -- Centers the level on the screen
  gridXOffset = level:centerScreenX(tileSize)
  gridYOffset = level:centerScreenY(tileSize)
  
  -- Tracks fps
  totalTime = 0
  totalFrames = 0
  
  -- Starts the game on the winter phase
  -- onMenu = false
  -- loadWinter()
  
  -- Starts the game with the tutorial on the given phase
  -- debugTutorial(5)
end


--- Runs every frame.
function love.update(dt)
  screenTransition:update()
  
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
  
  love.graphics.setColor(graphics.COLOR_WHITE)
  
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
  
  screenTransition:draw()
  
  -- FPS counter
  if showFPS then
    love.graphics.setColor(graphics.COLOR_BLACK)
    love.graphics.print("" .. (totalFrames / totalTime), 10, 10)
    love.graphics.setColor(graphics.COLOR_WHITE)
  end
  
end
