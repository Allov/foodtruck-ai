local Scene = require('src.scenes.scene')
local Game = setmetatable({}, Scene)
Game.__index = Game

function Game.new()
    local self = setmetatable({}, Game)
    return self
end

function Game:init()
    self.paused = false
end

function Game:update(dt)
    if self.showingConfirmDialog then
        self:updateConfirmDialog()
        return
    end

    if love.keyboard.wasPressed('escape') then
        self.showingConfirmDialog = true
        return
    end
end

function Game:draw()
    love.graphics.setColor(1, 1, 1, 1)
    if self.paused then
        love.graphics.printf("PAUSED", 0, love.graphics.getHeight()/2, love.graphics.getWidth(), 'center')
    else
        love.graphics.printf("Game Running\nPress ESC to return to menu", 0, love.graphics.getHeight()/2, love.graphics.getWidth(), 'center')
    end
end

return Game
