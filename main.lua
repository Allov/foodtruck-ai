-- Enable debugging
if arg[#arg] == "vsc_debug" then require("lldebugger").start() end

local game = require('src.main')

function love.load()
    game.load()
end

function love.update(dt)
    game.update(dt)
end

function love.draw()
    game.draw()
end

function love.keypressed(key)
    game.keypressed(key)
end

function love.keyreleased(key)
    game.keyreleased(key)
end

function love.textinput(t)
    game.textinput(t)
end



