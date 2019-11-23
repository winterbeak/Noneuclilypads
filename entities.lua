local player = require("player")
local rat = require("rat")
local snake = require("snake")
local slug = require("slug")

local entities = {}

entities.Player = player.Player
entities.Rat = rat.Rat
entities.Snake = snake.Snake
entities.Slug = slug.Slug

return entities