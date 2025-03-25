local Scene = require('src.scenes.scene')
local EncounterTester = setmetatable({}, Scene)
EncounterTester.__index = EncounterTester

function EncounterTester.new()
    local self = setmetatable({}, Scene)
    return setmetatable(self, EncounterTester)
end

function EncounterTester:init()
    self:resetState()

    -- Get encounter types from Encounter scene
    self.encounterTypes = {
        "card_battle",
        "beneficial",
        "negative",
        "market",
        "lore"
    }

    -- Get chefs list
    local ChefSelect = require('src.scenes.chefSelect')
    local chefSelector = ChefSelect.new()
    self.chefs = chefSelector:loadChefs()
end

-- Add this new method to reset the state
function EncounterTester:resetState()
    self.state = {
        step = 1,  -- 1: select encounter type, 2: select chef
        selected = 1
    }
end

-- Add this new method to handle scene entry
function EncounterTester:enter()
    self:resetState()
end

function EncounterTester:update(dt)
    if love.keyboard.wasPressed('escape') then
        sceneManager:switch('debugMenu')
        return
    end

    if love.keyboard.wasPressed('up') then
        self.state.selected = self.state.selected - 1
        if self.state.selected < 1 then
            self.state.selected = #(self.state.step == 1 and self.encounterTypes or self.chefs)
        end
    end
    if love.keyboard.wasPressed('down') then
        self.state.selected = self.state.selected + 1
        if self.state.selected > #(self.state.step == 1 and self.encounterTypes or self.chefs) then
            self.state.selected = 1
        end
    end
    if love.keyboard.wasPressed('return') then
        if self.state.step == 1 then
            -- Store selected encounter type and move to chef selection
            gameState.currentEncounter = self.encounterTypes[self.state.selected]
            self.state.step = 2
            self.state.selected = 1
        else
            -- Create proper Chef instance when selecting chef
            local selectedChefData = self.chefs[self.state.selected]
            local Chef = require('src.entities.chef')
            local chef = Chef.new({
                name = selectedChefData.name,
                specialty = selectedChefData.specialty,
                description = selectedChefData.description,
                rating = selectedChefData.rating
            })
            gameState.selectedChef = chef
            -- Set previous scene for return after encounter
            gameState.previousScene = 'debugMenu'
            sceneManager:switch('encounter')
        end
    end
end

function EncounterTester:draw()
    love.graphics.setColor(1, 1, 1, 1)

    if self.state.step == 1 then
        love.graphics.printf("Select Encounter Type", 0, 100, love.graphics.getWidth(), 'center')

        for i, encounterType in ipairs(self.encounterTypes) do
            if i == self.state.selected then
                love.graphics.setColor(1, 1, 0, 1)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            love.graphics.printf(encounterType, 0, 200 + i * 40, love.graphics.getWidth(), 'center')
        end
    else
        love.graphics.printf("Select Chef", 0, 100, love.graphics.getWidth(), 'center')

        for i, chef in ipairs(self.chefs) do
            if i == self.state.selected then
                love.graphics.setColor(1, 1, 0, 1)
            else
                love.graphics.setColor(1, 1, 1, 1)
            end
            love.graphics.printf(
                chef.name .. "\n" .. chef.specialty,
                0, 200 + i * 40,
                love.graphics.getWidth(),
                'center'
            )
        end
    end
end

return EncounterTester


