local graphics = {}



graphics.scale = 4

--- Converts a color with 0-255 range to a color with 0-1 range.
function graphics.convertColor(colorList)
  actualColor = {}
  for i = 1, #colorList do
    actualColor[i] = colorList[i] / 255
  end
  return actualColor
end

graphics.COLOR_WHITE = graphics.convertColor({255, 255, 255})
graphics.COLOR_BLACK = graphics.convertColor({0, 0, 0})
graphics.COLOR_LILLYPAD = graphics.convertColor({145, 206, 50})
graphics.COLOR_LILLYPAD_SHADOW = graphics.convertColor({94, 153, 0})
graphics.COLOR_LILLYPAD_HIGHLIGHT = graphics.convertColor({221, 221, 39})
graphics.COLOR_LILLYPAD_SHADOW_HIGHLIGHT = graphics.convertColor({176, 176, 37})
graphics.COLOR_WATER = graphics.convertColor({0, 255, 182})
graphics.COLOR_WATER_SHADOW = graphics.convertColor({0, 0, 0, 76})


-- Changes the resampling mode so that pixel art is crisp when resized.
love.graphics.setDefaultFilter("nearest", "nearest")


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


--- Draws the sprite with the given id.
function graphics.SpriteSheet:draw(spriteNum, x, y, scale)
  love.graphics.draw(self.image, self.quads[spriteNum], x, y, 0, scale, scale)
end


--- Randomly picks one of the spritesheet's sprites, and draws it.
function graphics.SpriteSheet:drawRandom(x, y, scale)
  local quad = math.random(1, self.spriteCount)
  love.graphics.draw(self.image, self.quads[quad], x, y, 0, scale, scale)
end


return graphics