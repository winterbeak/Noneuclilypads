--- Any useful but unsorted functions that I haven't found a good place to put.

local misc = {}

--- Creates a new 2D table.
function misc.table2D(subTableCount)
  local tempTable = {}
  
  for table = 1, subTableCount do
    tempTable[table] = {}
  end
  
  return tempTable
end


--- Returns a table of the points adjacent to the given coordinate.
-- The table consists of four keys equal to the direction (left, up, right or down),
-- and four values of the form {x = x, y = y}.
function misc.adjacentPoints(x, y)
  return {
    left = {x = x - 1, y = y},
    up = {x = x, y = y - 1},
    right = {x = x + 1, y = y},
    down = {x = x, y = y + 1}
  }
end


--- Returns the string value of a boolean.
function misc.boolString(boolean)
  if boolean then
    return "true"
  end
  return "false"
end


-- Converts a list of booleans into a single integer, by setting trues to 1 and falses to 0.
-- The list of booleans must be numerically indexed.
function misc.toBits(booleanList)
  local bits = 0
  for i = 1, #booleanList do
    if booleanList[i] then
      bits = bit.bor(bits, bit.lshift(1, i - 1))
    end
  end
  return bits
end


--- Returns the amount of key/value pairs in a table.
function misc.length(list)
  local length = 0
  
  for _, _ in pairs(list) do
    length = length + 1
  end
  
  return length
end


--- Randomly returns one of the elements of a set.
-- A set is a list where every key is of the form <key> = true.
-- Returns nil if there are no items in the list.
function misc.randomChoice(list)
  
  local length = misc.length(list)
  
  if length == 0 then
    return nil
  end
  
  local chosenIndex = math.random(1, length)
  local currentIndex = 1
  for value, _ in pairs(list) do
    if currentIndex == chosenIndex then
      return value
    end
    
    currentIndex = currentIndex + 1
  end
  
end


--- Returns the direction that is 90 degrees clockwise to the given direction.
function misc.clockwiseTo(direction)
  if not direction then
    error("Nil passed to clockwiseTo()!")
  end
  
  if direction == "left" then
    return "up"
  elseif direction == "up" then
    return "right"
  elseif direction == "right" then
    return "down"
  elseif direction == "down" then
    return "left"
  else
    error("Invalid direction '" .. direction .. "' passed to clockwiseTo()!")
  end
end


--- Returns the direction that is 180 degrees clockwise to the given direction.
function misc.oppositeOf(direction)
  if not direction then
    error("Nil passed to oppositeOf()!")
  end
  
  if direction == "left" then
    return "right"
  elseif direction == "up" then
    return "down"
  elseif direction == "right" then
    return "left"
  elseif direction == "down" then
    return "up"
  else
    error("Invalid direction '" .. direction .. "' passed to oppositeOf()!")
  end
end


--- Returns the direction that is 90 degrees counterclockwise to the given direction.
function misc.counterClockwiseTo(direction)
  if not direction then
    error("Nil passed to counterClockwiseTo()!")
  end
  
  if direction == "left" then
    return "down"
  elseif direction == "up" then
    return "left"
  elseif direction == "right" then
    return "up"
  elseif direction == "down" then
    return "right"
  else
    error("Invalid direction '" .. direction .. "' counterClockwiseTo()!")
  end
end


--- Returns the angle, in radians, of given direction, given that left is 0 and the
-- angles go counterclockwise.
function misc.rotationOf(direction)
  if not direction then
    error("Nil passed to rotationOf()!")
  end
  
  if direction == "left" then
    return 0
  elseif direction == "up" then
    return math.pi / 2
  elseif direction == "right" then
    return math.pi
  elseif direction == "down" then
    return math.pi / 2 * 3
  else
    error("Invalid direction '" .. direction .. "' passed to rotationOf()!")
  end
end


return misc