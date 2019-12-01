local movement = require("movement")

local graphics = {}


graphics.daysFontSmallest = love.graphics.newFont("m6x11.ttf", 48)
graphics.winterFontSmallest = love.graphics.newFont("m6x11.ttf", 16)
graphics.tutorialFontSmallest = love.graphics.newFont("m5x7.ttf", 16)


--- Converts a color with 0-255 range to a color with 0-1 range.
function graphics.convertColor(colorList)
  actualColor = {}
  for i = 1, #colorList do
    actualColor[i] = colorList[i] / 255
  end
  return actualColor
end


--- Changes the alpha of the currently selected color.
function graphics.setAlpha(alpha)
  local r
  local g
  local b
  
  r, g, b = love.graphics.getColor()
  
  love.graphics.setColor(r, g, b, alpha)
end


--- Loads the fonts used for the game.  Must be called whenever resizing the screen.
function graphics.reloadFonts(pixel)
  graphics.daysFont = love.graphics.newFont("m6x11.ttf", 48 * pixel)
  graphics.winterFont = love.graphics.newFont("m6x11.ttf", 16 * pixel)
  graphics.tutorialFont = love.graphics.newFont("m5x7.ttf", 16 * pixel)
end


graphics.COLOR_WHITE = graphics.convertColor({255, 255, 255})
graphics.COLOR_BLACK = graphics.convertColor({0, 0, 0})

graphics.COLOR_LILLYPAD = graphics.convertColor({145, 206, 50})
graphics.COLOR_LILLYPAD_SHADOW = graphics.convertColor({94, 153, 0})
graphics.COLOR_LILLYPAD_OUTLINE = graphics.convertColor({56, 90, 0})

graphics.COLOR_LILLYPAD_HIGHLIGHT = graphics.convertColor({221, 221, 39})
graphics.COLOR_LILLYPAD_SHADOW_HIGHLIGHT = graphics.convertColor({176, 176, 37})
graphics.COLOR_LILLYPAD_OUTLINE_HIGHLIGHT = graphics.convertColor({114, 112, 17})

graphics.COLOR_WATER = graphics.convertColor({1, 255, 182})
graphics.COLOR_WATER_SHADOW = graphics.convertColor({0, 0, 0, 76})
graphics.COLOR_NIGHT_WATER = graphics.convertColor({0, 70, 158})

graphics.TRANSITION_COLOR = graphics.convertColor({0, 38, 74})


-- Changes the resampling mode so that pixel art is crisp when resized.
love.graphics.setDefaultFilter("nearest", "nearest")


--- Some weird shader thing copied off of the Love2D wiki page that allows
-- me to use an image as a stencil.  Transparent values are not drawn on, but everything else is.
graphics.mask_shader = love.graphics.newShader[[
   vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      if (Texel(texture, texture_coords).rgb == vec3(0.0)) {
         // a discarded pixel wont be applied as the stencil.
         discard;
      }
      return vec4(1.0);
   }
]]


graphics.Text = {}

--- An object that stores a string, as well as the pixel coordinates of that string.
function graphics.Text:new(text, pixelX, pixelY)
  local newObj = {
    text = text,
    pixelX = pixelX,
    pixelY = pixelY,
  }
  
  self.__index = self
  return setmetatable(newObj, self)
end


--- Draws the text.
function graphics.Text:draw(font, scale, x, y)
  x = x or (self.pixelX * scale)
  y = y or (self.pixelY * scale)
  love.graphics.setFont(font)
  love.graphics.print(self.text, x, y)
end


graphics.SpriteSheet = {}

--- Constructor.  Creates a new spritesheet.
-- The sprites must all be in one vertical column.
-- "images/" is added to the start of the path automatically.
-- sprites is the number of sprites in the column.
function graphics.SpriteSheet:new(path, spriteCount)
  local image = love.graphics.newImage("images/" .. path)
  local fullHeight = image:getHeight()
  
  local newObj = {
    image = image,
    width = image:getWidth(),
    fullHeight = fullHeight,
    singleHeight = fullHeight / spriteCount,
    
    spriteCount = spriteCount,
    quads = {}
  }
  
  local y
  for i = 1, spriteCount do
    y = (i - 1) * newObj.singleHeight
    newObj.quads[i] = love.graphics.newQuad(0, y, newObj.width, newObj.singleHeight, image:getDimensions())
  end
  
  self.__index = self
  return setmetatable(newObj, self)
end


--- Draws the sprite.
function graphics.SpriteSheet:draw(spriteNum, x, y, scale, rotation)
  
  rotation = rotation or 0
  
  local centerX = self.width / 2
  local centerY = self.singleHeight / 2
  
  x = x + (centerX * scale)
  y = y + (centerY * scale)
  
  love.graphics.draw(self.image, self.quads[spriteNum], x, y, rotation, scale, scale, centerX, centerY)

end


--- Draws the sprite, except shifted in its box.  Anything outside the box is cropped out.
-- Assumes that the sprite faces leftwards by default.
-- Forward shift is always in front of the sprite.
-- Positive shifts forwards, negative shifts backwards.  Without rotation, positive is left.
-- Sideways shift is always beside the sprite.
-- Positive shifts rightwards relative to the sprite's direction, and negative shifts leftwards.
-- Without rotation, positive is up.
-- The rotation amount MUST be orthogonal to 0; it can only be 0, pi/2, pi, or pi/2*3
function graphics.SpriteSheet:drawShifted(spriteNum, x, y, forwardsShift, sidewaysShift, scale, rotation)
  
  -- If nothing no shift was applied, then just draw the sprite normally
  if shiftX == 0 and shiftY == 0 then
    self:draw(spriteNum, x, y, scale, rotation)
    return
  end
  
  -- If the shift is outside the box, then everything is cropped and there's nothing to draw
  local validForwardShift = forwardsShift >= -self.width and forwardsShift <= self.width
  local validSidewaysShift = sidewaysShift >= -self.singleHeight and sidewaysShift <= self.singleHeight
  if not (validForwardShift and validSidewaysShift) then
    return
  end
  
  local newX
  local newY

  local quadX
  local quadY
  local quadWidth = self.width - math.abs(forwardsShift)
  local quadHeight = self.singleHeight - math.abs(sidewaysShift)

  local centerX = self.width / 2
  local centerY = self.singleHeight / 2
  
  rotation = rotation or 0
  
  -- Centers the sprite so that it can be rotated from its center.
  if rotation == 0 or rotation == math.pi then
    newX = x + (centerX * scale)
    newY = y + (centerY * scale)
    
  -- If the sprite is not square, then a 90 or 270 degree rotation will change
  -- the "width" and "height".  This fixes that.
  else
    newX = x + (centerY * scale)
    newY = y + (centerX * scale)
  end

  -- Shifting backwards means the right side of the sprite gets cropped
  if forwardsShift < 0 then
    quadX = 0
    
    if rotation == 0 then
      newX = newX - (forwardsShift * scale)
    elseif rotation == math.pi / 2 then
      newY = newY - (forwardsShift * scale)
    elseif rotation == math.pi then
      newX = newX + (forwardsShift * scale)
    elseif rotation == math.pi / 2 * 3 then
      newY = newY + (forwardsShift * scale)
    end
    
  -- Shifting forwards means the left side of the sprite gets cropped
  else
    quadX = forwardsShift
    
  end
  
  -- Shifting relatively leftwards means the bottom side of the sprite gets cropped
  if sidewaysShift < 0 then
    quadY = 0
    
    if rotation == 0 then
      newY = newY - (sidewaysShift * scale)
    elseif rotation == math.pi / 2 then
      newX = newX + (sidewaysShift * scale)
    elseif rotation == math.pi then
      newY = newY + (sidewaysShift * scale)
    elseif rotation == math.pi / 2 * 3 then
      newX = newX - (sidewaysShift * scale)
    end
    
  -- Shifting relatively rightwards means the top side of the sprite gets cropped
  else
    quadY = sidewaysShift
  end
  
  quadY = quadY + (self.singleHeight * (spriteNum - 1))

  local quad = love.graphics.newQuad(quadX, quadY, quadWidth, quadHeight, self.width, self.fullHeight)
  
  love.graphics.draw(self.image, quad, newX, newY, rotation, scale, scale, centerX, centerY)

end


--- Draws a sprite, but chopped off at the sides.
-- The x and y coordinates are where the top left of the sprite is drawn.  Note
-- that cropping changes the top left of the sprite.
-- The crops take place BEFORE the scale!
function graphics.SpriteSheet:drawCropped(spriteNum, x, y, leftCrop, upCrop, downCrop, rightCrop, scale)
  
  local quadX = leftCrop
  local quadY = upCrop + ((spriteNum - 1) * self.singleHeight)
  local quadWidth = self.width - leftCrop - rightCrop
  local quadHeight = self.singleHeight - upCrop - downCrop
  
  local quad = love.graphics.newQuad(quadX, quadY, quadWidth, quadHeight, self.width, self.fullHeight)
  
  love.graphics.draw(self.image, quad, x, y, 0, scale, scale)
end


--- Draws a sprite, but chopped off at the sides.
-- The x and y coordinates are where the top left of the original, non-cropped sprite is drawn
-- The crops take place BEFORE the scale!
function graphics.SpriteSheet:drawPartial(spriteNum, x, y, leftCrop, upCrop, downCrop, rightCrop, scale)
  
  local quadX = leftCrop
  local quadY = upCrop + ((spriteNum - 1) * self.singleHeight)
  local quadWidth = self.width - leftCrop - rightCrop
  local quadHeight = self.singleHeight - upCrop - downCrop
  
  x = x + (leftCrop * scale)
  y = y + (upCrop * scale)

  local quad = love.graphics.newQuad(quadX, quadY, quadWidth, quadHeight, self.width, self.fullHeight)
  
  love.graphics.draw(self.image, quad, x, y, 0, scale, scale)
end


--- Randomly picks one of the spritesheet's sprites, and draws it.
function graphics.SpriteSheet:drawRandom(x, y, scale, rotation)
  rotation = rotation or 0
  local quad = math.random(1, self.spriteCount)
  love.graphics.draw(self.image, self.quads[quad], x, y, rotation, scale, scale)
end


--- Returns a list of spritesheets, each loaded from the same file name except the number
-- is different.
function graphics.loadMulti(pathStart, sheetCount, pathEnd, spriteCount)
  local list = {}
  for i = 1, sheetCount do
    list[i] = graphics.SpriteSheet:new(pathStart .. i .. pathEnd, spriteCount)
  end
  return list
end


graphics.Animation = {}

--- Constructor.  Creates a new instance of an animation.
-- This class keeps track of the current frame of an animation.
-- The animation graphics are a SpriteSheet.
function graphics.Animation:new(spriteSheet)
  if not spriteSheet then
    error("nil was passed as an animation's spritesheet!")
  end
  
  local newObj = {
    spriteSheet = spriteSheet,
    
    frame = 1,
    onLastFrame = false,
    isDone = false,
    
    hasFrameLengths = false,
    frameLengths = {},
    delayCount = 0,
  }
  
  self.__index = self
  return setmetatable(newObj, self)
end


--- Sets how long each frame appears on the screen for.
-- This function gives each frame the same length.
-- A frame of length 1 appears on screen for 1 in-game frame.
function graphics.Animation:setFrameLength(length)
  
  self.hasFrameLengths = true
  
  for i = 1, self.spriteSheet.spriteCount do
    self.frameLengths[i] = length
  end
  
end


--- Sets how long each frame appears on the screen for.
-- This function lets you specify the lengths of each individual frame.
-- A frame of length 1 appears on screen for 1 in-game frame.
-- lengthList must have the same amount of numbers as the animation has frames.
function graphics.Animation:setFrameLengths(lengthList)
  
  self.hasFrameLengths = true
  
  -- There must be one length per frame.  Raises an error otherwise.
  if #lengthList ~= self.spriteSheet.spriteCount then
    error("The length of frameCountList does not match the amount of frames!")
  end
  
  -- Sets the delays.
  for i = 1, self.spriteSheet.spriteCount do
    self.frameLengths[i] = lengthList[i]
  end
end


--- Makes the animation go to the next frame.
-- Does not apply delays between frames.
-- Sets the onLastFrame flag once the animation reaches its last frame.
function graphics.Animation:nextFrame()
  
  -- Don't update anything if the animation is done
  if not self.isDone then
    
    if self.onLastFrame then
      self.isDone = true
      
    else
      self.frame = self.frame + 1
      
      -- If you increment to after the final frame, set the animation to done
      if self.frame == self.spriteSheet.spriteCount then
        self.onLastFrame = true
      end
    end
    
  end
end


--- Resets the animation to the first frame.
function graphics.Animation:reset()
  self.frame = 1
  self.delayCount = 0
  self.onLastFrame = false
  self.isDone = false
end


--- Updates the animation, including delaying the proper amount of time between frames.
function graphics.Animation:update()
  
  -- If the animation hasn't ended yet
  if not self.isDone then
    
    -- If the animation has frame lengths, delay before switching to the next frame
    if self.hasFrameLengths then
      self.delayCount = self.delayCount + 1
      
      if self.delayCount >= self.frameLengths[self.frame] then
        self:nextFrame()
        self.delayCount = 0
      end
    
    -- Otherwise, each frame defaults to length 1, so just switch it immediately each frame
    else
      self:nextFrame()
    end
  end
end


--- Draws the current frame of the animation.
function graphics.Animation:draw(x, y, scale, rotation)
  self.spriteSheet:draw(self.frame, x, y, scale, rotation)
end


--- Draws the current frame, except shifted in its box.  Anything outside the box is cropped out.
function graphics.Animation:drawShifted(x, y, xOffset, yOffset, scale, rotation)
  self.spriteSheet:drawShifted(self.frame, x, y, xOffset, yOffset, scale, rotation)
end


--- Returns a list of animations, one for each spritesheet in a numerically indexed list.
function graphics.multiAnim(multiSpriteSheetList)
  local list = {}
  for i = 1, #multiSpriteSheetList do
    list[i] = graphics.Animation:new(multiSpriteSheetList[i])
  end
  
  return list
end


--- Sets the frame length of a numerically indexed list of animations.
function graphics.setMultiAnimFrameLength(multiAnim, length)
  for i = 1, #multiAnim do
    multiAnim[i]:setFrameLength(length)
  end
end


--- Updates a numerically indexed list of animations.
function graphics.updateMultiAnim(multiAnim)
  for i = 1, #multiAnim do
    multiAnim[i]:update()
  end
end


--- Resets a numerically indexed list of animations.
function graphics.resetMultiAnim(multiAnim)
  for i = 1, #multiAnim do
    multiAnim[i]:reset()
  end
end


return graphics