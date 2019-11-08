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

--- A grid of vectors used as the keys for pseudo-2D tables.
-- These keys serve as the basis for 2D vector table implementation.
-- Normally, the following code:
--
-- table2D[{value1, value2}] = true
-- print(table2D[{value1, value2}])
--
-- prints nil because a table literal {} always creates a new table.
-- Thus, the index table for the first line of code is actually a
-- different table from the second line.
--
-- However, if a reference is used instead, then it will be the same table.
-- The following:
-- 
-- reference = {value1, value2}
-- table2D[reference] = true
-- print(table2D[reference])
--
-- prints true.
--
-- This grid of vectors basically stores one reference for each possible
-- x, y coordinate, for use as keys.
local MAX_X_KEY = 16
local MAX_Y_KEY = 16
local keyGrid = {}

-- Creates a vector for each x, y pair
for x = 1, MAX_X_KEY do
  keyGrid[x] = {}
  
  for y = 1, MAX_Y_KEY do
    keyGrid[x][y] = vector.Vector:new(x, y)
  end
  
end

--- Returns the vector key at the given x, y coordinates.
local function getKey(x, y)
  if (x < 1 or x > MAX_X_KEY) and (y < 1 or y > MAX_Y_KEY) then
    error("The x key (" .. x .. ") and the y key (" .. y .. ") were both outside the valid key range!")
  end
  
  if (x < 1 or x > MAX_X_KEY) then
    error("The x key (" .. x .. ") was outside the valid key range!")
  end
  
  if (y < 1 or y > MAX_Y_KEY) then
    error("The y key (" .. y .. ") was outside the valid key range!")
  end
  
  return keyGrid[x][y]
end

--- A pseudo 2D array that accepts vectors or {x, y} tables as a key.
vector.VectorTable = {}

function vector.VectorTable:new()
  local newObj = {}
  
  -- Overrides the index function, translating the given key into the
  -- corresponding vector in the vector grid.
  self.__index = function(table, key)
    
    -- Handles the use of {x, y} tables as keys
    if key[1] and key[2] then
      return self[getKey(key[1], key[2])]
    
    -- Handles the use of vectors as keys
    elseif key.x and key.y then
      return self[getKey(key.x, key.y)]
    
    -- Error message in case the key isn't valid
    else
      error("An invalid key was used as an index!")

    end
  end
  
  -- Overrides the newindex function, translating the given key into the
  -- corresponding vector in the vector grid.
  self.__newindex = function(table, key, value)
    
    -- Handles the use of {x, y} tables as keys
    if key[1] then
      self[getKey(key[1], key[2])] = value
    
    -- Handles the use of vectors as keys
    elseif key.x then
      self[getKey(key.x, key.y)] = value
      
    -- Error message in case the key isn't valid
    else
      error("An invalid key was used as an index!")

    end
  end
  
  return setmetatable(newObj, self)
end
