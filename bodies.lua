--- Handles the various bodies that exist on the grid.

graphics = require("graphics")
misc = require("misc")

local bodies = {}

bodies.WarpBody = {}

function bodies.WarpBody:new(startSpace)
  local newObj = {
    space = startSpace,
    previousSpace = nil,
    moveDirection = "left",
    
    moving = false,
    
    flyCount = 0
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
  self.moving = true
end


return bodies