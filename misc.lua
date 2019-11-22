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


-- Converts a list of booleans into 
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


return misc