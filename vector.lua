--- A simple 2D vector.

local vector = {}

vector.Vector = {}

--- Constructor.  Creates a new vector with the given x and y.
function vector.Vector:new(x, y)
  local newObj = {
    x = x,
    y = y
  }
  
  self.__index = self
  self.__add = function (vector1, vector2)
    return vector.Vector:new(vector1.x + vector2.x, vector1.y + vector2.y)
  end
  
  return setmetatable(newObj, self)
end

return vector
