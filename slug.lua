graphics = require("graphics")
bodies = require("bodies")
misc = require("misc")

local slug = {}

slug.jumpOffsets = {0, 0, 5, 21, 24, 24, 24, 24, 24}
slug.idleSpriteSheets = graphics.loadMulti("slugIdle", 4, ".png", 1)
slug.jumpSpriteSheets = graphics.loadMulti("slugJump", 3, ".png", 9)
slug.readySpriteSheets = graphics.loadMulti("slugReady", 3, ".png", 27)
slug.slurpSpriteSheet = graphics.SpriteSheet:new("slugSlurp.png", 7)

slug.Slug = {}

--- Constructor.  Makes a Slug enemy.
-- The Slug is similar to the Rat in that it waits a turn, then moves closer to the player.
-- However, the Slug will add slime to every space it moves off of.  After three moves,
-- instead of moving a fourth time, the Slug will pause to merge all the slimed spaces.
function slug.Slug:new(startSpace)
  local newObj = {
    idleAnims = graphics.multiAnim(slug.idleSpriteSheets),
    jumpAnims = graphics.multiAnim(slug.jumpSpriteSheets),
    readyAnims = graphics.multiAnim(slug.readySpriteSheets),
    slurpAnim = graphics.Animation:new(slug.slurpSpriteSheet),
    
    moveTimer = math.random(0, 1),
    animation = nil,
    
    body = bodies.WarpBody:new(startSpace),
    slimedSpaces = {}
  }
  
  newObj.body.moveDirection = misc.randomDirection()
  
  graphics.setMultiAnimFrameLength(newObj.idleAnims, 3)
  graphics.setMultiAnimFrameLength(newObj.jumpAnims, 3)
  graphics.setMultiAnimFrameLength(newObj.readyAnims, 3)
  newObj.slurpAnim:setFrameLength(3)
  
  if newObj.moveTimer == 0 then
    newObj.animation = newObj.idleAnims[1]
  elseif newObj.moveTimer == 1 then
    newObj.animation = newObj.readyAnims[1]
  end
  
  newObj.body:addFleas(5)
  
  self.__index = self
  return setmetatable(newObj, self)
end


--- Makes the slug move.
-- Slugs always move one space closer to the player.
function slug.Slug:move(player)
  local previousSpace = self.body.space
  local closestSpace = self.body.space:closestAdjacent(player)
  
  if closestSpace then
    self.body:moveTo(closestSpace, self.body.space:directionOf(closestSpace))
    table.insert(self.slimedSpaces, previousSpace)
    
  -- If no valid space was found then
  else
    -- Play the "can't move" animation
  end
    
end


--- Merges all of the slug's slimed spaces.
-- If a space is occupied, it will NOT be merged.
function slug.Slug:mergeSlimed(level)
  
  -- Removes any spaces that are occupied
  for i = 1, #self.slimedSpaces do
    if self.slimedSpaces[i] then
      self.slimedSpaces[i]:removeSlime(true, true)
      self.slimedSpaces[i]:explodeSlime()
      
      if self.slimedSpaces[i]:isOccupied() then
        table.remove(self.slimedSpaces, i)
      end
    end
  end
  
  -- Merges any remaining spaces
  level:mergeMulti(self.slimedSpaces)
  self.slimedSpaces = {}
  level:refreshAllAdjacent()
end


--- Makes the slug take a turn.
-- Slugs will wait a turn, then move closer to the player.
-- The slug adds slime to every space it moves off of.
-- After three moves, instead of moving a fourth time, the slug will pause
-- to merge all the slimed spaces.
function slug.Slug:takeTurn(level, player)
  self.moveTimer = self.moveTimer + 1
  
  -- On the fourth move, merge all slimed spaces.
  if self.moveTimer == 8 then
    self:mergeSlimed(level)
    self.moveTimer = 0
    self.animation = self.slurpAnim
    
  -- Move every other turn.
  elseif self.moveTimer % 2 == 0 then
    
    self.animation = self.jumpAnims[self.moveTimer / 2]

    -- If the snail is beside the player, hurt them
    if self.body:isBesideBody(player.body) then
      player:hurt()
      
    -- Otherwise, just move normally
    else
      self:move(player)
    end
    
  -- Plays the ready animation between turns.
  elseif self.moveTimer ~= 7 then
    self.animation = self.readyAnims[(self.moveTimer + 1) / 2]
    self.animation.frame = 4
  
  end
end
  

--- Draws the slug.
function slug.Slug:draw(gridXOffset, gridYOffset, scale, tileSize)
  
  love.graphics.setColor(1, 1, 1)
  
  local rotation = 0
  local forwardsShift
  local previousForwardsShift
  
  -- Rotates the sprite based on what direction the slug is facing
  rotation = misc.rotationOf(self.body.moveDirection)
  
  -- Sets the amount of forwards shift of the slug sprite during the moving animation
  if self.body.moving then
    previousForwardsShift = slug.jumpOffsets[self.animation.frame]
    forwardsShift = -tileSize / scale + previousForwardsShift
  end
  
  -- Violently shakes as the slug readies its merging
  local shakeX = 0
  local shakeY = 0
  if self.moveTimer == 7 then
    if math.random(1, 4) == 1 then
      shakeX = math.random(-1, 1) * scale
      shakeY = math.random(-1, 1) * scale
    end
  end
  
  -- Draws the slug
  for colNum, col in pairs(self.body.space.cells) do
    for rowNum, _ in pairs(col) do
        
      x = gridXOffset + ((colNum - 1) * tileSize) + shakeX
      y = gridYOffset + ((rowNum - 1) * tileSize) + shakeY
      
      if self.body.moving then
        self.animation:drawShifted(x, y, forwardsShift, 0, scale, rotation)
      else
        self.animation:draw(x, y, scale, rotation)
      end
      
    end
  end
  
  -- Draws the slug on the previous space
  if self.body.moving then
    for colNum, col in pairs(self.body.previousSpace.cells) do
      for rowNum, _ in pairs(col) do
        
        x = gridXOffset + ((colNum - 1) * tileSize)
        y = gridYOffset + ((rowNum - 1) * tileSize)
        
        self.animation:drawShifted(x, y, previousForwardsShift, 0, scale, rotation)
        
      end
    end
  end
  
  self.body:drawBugs(gridXOffset, gridYOffset, scale, tileSize)
  
end

--- Updates the slug's animation.  Should be called every frame.
function slug.Slug:updateAnimation()
  
  -- Jump animation
  if self.body.moving then
    self.animation:update()
    
    -- Adds to the previous space on frame 4
    if self.animation.frame == 4 and self.animation.delayCount == 0 then
      self.body.previousSpace:addSlime(nil, self.body.moveDirection)
      
    -- Adds to the new space on frame 5
    elseif self.animation.frame == 5 and self.animation.delayCount == 0 then
      self.body.space:addSlime(misc.oppositeOf(self.body.moveDirection), nil)
    end
    
  -- Slurp animation
  elseif self.animation == self.slurpAnim then
    self.animation:update()
    
  elseif self.moveTimer % 2 == 1 and self.moveTimer ~= 7 then
    self.animation:update()
    
  end
  
  -- Stop movement/slurping animation
  if self.moveTimer % 2 == 0 then
    if self.animation.isDone then
      self.animation:reset()
      
      self.animation = self.idleAnims[(self.moveTimer / 2) + 1]
      self.body.moving = false
    end
    
  -- Reset ready animation
  elseif self.moveTimer ~= 7 then
    
    if self.animation.isDone then
      self.animation:reset()
    end
    
  end
  
  self.body:updateBugs()
end


return slug