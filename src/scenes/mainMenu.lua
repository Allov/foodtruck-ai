local Scene = require('src.scenes.scene')
local MainMenu = setmetatable({}, Scene)
MainMenu.__index = MainMenu

function MainMenu.new()
    local self = setmetatable({}, MainMenu)
    return self
end

function MainMenu:init()
    self.options = {
        "Start Food Truck Journey",
        "Options",
        "Exit"
    }
    self.selected = 1
end

function MainMenu:update(dt)
    if love.keyboard.wasPressed('up') then
        self.selected = self.selected - 1
        if self.selected < 1 then self.selected = #self.options end
    end
    if love.keyboard.wasPressed('down') then
        self.selected = self.selected + 1
        if self.selected > #self.options then self.selected = 1 end
    end
    if love.keyboard.wasPressed('return') then
        if self.selected == 1 then
            sceneManager:switch('chefSelect')
        elseif self.selected == 3 then
            love.event.quit()
        end
    end
end

function MainMenu:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Food Truck Journey", 0, 100, love.graphics.getWidth(), 'center')
    
    for i, option in ipairs(self.options) do
        if i == self.selected then
            love.graphics.setColor(1, 1, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        love.graphics.printf(option, 0, 200 + i * 40, love.graphics.getWidth(), 'center')
    end
end

return MainMenu
