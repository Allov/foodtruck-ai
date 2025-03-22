local Scene = require('src.scenes.scene')
local ChefSelect = setmetatable({}, Scene)
ChefSelect.__index = ChefSelect

function ChefSelect.new()
    local self = setmetatable({}, ChefSelect)
    return self
end

function ChefSelect:init()
    self.chefs = {
        {name = "Classic Chef", specialty = "French Cuisine"},
        {name = "Street Food Vendor", specialty = "Fast Cooking"},
        {name = "Fusion Master", specialty = "Mixed Cuisine"}
    }
    self.selected = 1
end

function ChefSelect:update(dt)
    if love.keyboard.wasPressed('up') then
        self.selected = self.selected - 1
        if self.selected < 1 then self.selected = #self.chefs end
    end
    if love.keyboard.wasPressed('down') then
        self.selected = self.selected + 1
        if self.selected > #self.chefs then self.selected = 1 end
    end
    if love.keyboard.wasPressed('return') then
        -- Store selected chef and move to map
        gameState.selectedChef = self.chefs[self.selected]
        sceneManager:switch('provinceMap')
    end
    if love.keyboard.wasPressed('escape') then
        sceneManager:switch('mainMenu')
    end
end

function ChefSelect:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Select Your Chef", 0, 50, love.graphics.getWidth(), 'center')
    
    for i, chef in ipairs(self.chefs) do
        if i == self.selected then
            love.graphics.setColor(1, 1, 0, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        love.graphics.printf(
            chef.name .. "\n" .. chef.specialty,
            0, 150 + i * 60,
            love.graphics.getWidth(),
            'center'
        )
    end
end

return ChefSelect
