local player = require("player")
local rat = require("rat")
local snake = require("snake")
local slug = require("slug")

local entities = {}

entities.Player = player.Player
entities.Rat = rat.Rat
entities.Snake = snake.Snake
entities.Slug = slug.Slug

entities.enemyList = {
  entities.Rat,
  entities.Snake,
  entities.Slug
}


--- Returns a randomly generated new enemy.
function entities.randomEnemy(startSpace)
  local entityNum = math.random(1, #entities.enemyList)
  
  if entities.enemyList[entityNum] == entities.Snake then
    return entities.Snake:newRandom(startSpace)
  else
    return entities.enemyList[entityNum]:new(startSpace)
  end

end


return entities