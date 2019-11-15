local bodies = {}

bodies.WarpBody = {}

function bodies.WarpBody:new(startSpace)
  newObj = {
    space = startSpace,
    previousSpace = nil,
    moveDirection = "left"
  }
  
  startSpace.occupiedBy = newObj
  
  self.__index = self
  return setmetatable(newObj, self)
end


--- Makes the body move to a given space.
function bodies.WarpBody:moveTo(space, direction)
  self.space.occupiedBy = nil
  space.occupiedBy = self
  
  self.previousSpace = self.space
  self.space = space
  
  self.moveDirection = direction
end

return bodies