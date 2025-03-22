local Scene = require('src.scenes.scene')
local ChefSelect = setmetatable({}, Scene)
ChefSelect.__index = ChefSelect

function ChefSelect.new()
    local self = setmetatable({}, ChefSelect)
    return self
end

function ChefSelect:loadChefs()
    -- Return a list of predefined chefs with their specialties
    return {
        {
            name = "Chef Antonio",
            specialty = "Italian Cuisine",
            description = "Master of pasta and traditional Italian dishes"
        },
        {
            name = "Chef Mei",
            specialty = "Asian Fusion",
            description = "Expert in combining Eastern and Western flavors"
        },
        {
            name = "Chef Pierre",
            specialty = "French Cuisine",
            description = "Classically trained in French cooking techniques"
        },
        {
            name = "Chef Sofia",
            specialty = "Street Food",
            description = "Specializes in creative street food innovations"
        }
    }
end

function ChefSelect:init()
    -- Initialize existing chef selection state
    self.chefs = self:loadChefs()
    self.selected = 1
    
    -- Initialize confirmation dialog
    self:initConfirmDialog()
end

function ChefSelect:update(dt)
    if self.showingConfirmDialog then
        self:updateConfirmDialog()
        return
    end

    if love.keyboard.wasPressed('escape') then
        self.showingConfirmDialog = true
        return
    end

    if love.keyboard.wasPressed('up') then
        self.selected = self.selected - 1
        if self.selected < 1 then self.selected = #self.chefs end
    end
    if love.keyboard.wasPressed('down') then
        self.selected = self.selected + 1
        if self.selected > #self.chefs then self.selected = 1 end
    end
    if love.keyboard.wasPressed('return') then
        gameState.selectedChef = self.chefs[self.selected]
        local provinceMap = sceneManager.scenes['provinceMap']
        provinceMap:setSeed(gameState.mapSeed)
        sceneManager:switch('provinceMap')
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

    -- Draw confirmation dialog if active
    if self.showingConfirmDialog then
        self:drawConfirmDialog()
    end
end

return ChefSelect



