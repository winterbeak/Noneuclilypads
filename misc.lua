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

return misc